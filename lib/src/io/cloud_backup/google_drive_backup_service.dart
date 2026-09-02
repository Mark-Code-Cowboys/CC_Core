import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import 'cloud_backup_service.dart';

/// Per-app Google Drive settings. Client IDs are public and ship in
/// every build; the OAuth clients themselves are created in Google
/// Cloud Console (package name + SHA-1 of the upload key AND the Play
/// App Signing key on Android; an iOS client whose reversed ID is a
/// CFBundleURLSchemes entry on iOS).
class GoogleDriveConfig {
  /// Creates the Drive settings for one app.
  const GoogleDriveConfig({
    required this.serverClientId,
    this.iosClientId = '',
    this.fileName = 'backup.zip',
    this.setupHint = '',
  });

  /// The **Web application** OAuth client ID — NOT the Android client.
  /// google_sign_in 7.x on Android needs it as `serverClientId`; with
  /// it empty every sign-in fails before the account picker appears.
  final String serverClientId;

  /// The **iOS** OAuth client ID, passed as `clientId` on iOS. Its
  /// reversed form ("com.googleusercontent.apps.…") must also be a
  /// CFBundleURLSchemes entry or the browser can never redirect back.
  final String iosClientId;

  /// Name of the single backup file in the app-data folder.
  final String fileName;

  /// Appended to the misconfiguration error, e.g. a docs pointer.
  final String setupHint;
}

/// Bearer headers for Drive REST calls; the test seam around sign-in.
typedef AuthHeaders = Future<Map<String, String>> Function();

/// Google Drive implementation using the `drive.appdata` scope: a
/// hidden, app-private folder in the *user's* Drive. The app can only
/// see its own backup file there — nothing else in their Drive — and
/// the developer sees nothing at all.
class GoogleDriveBackupService implements CloudBackupService {
  /// Creates the service. [client] and [authHeaders] are test seams:
  /// with [authHeaders] set the google_sign_in plugin is never touched.
  GoogleDriveBackupService(
    this.config, {
    http.Client? client,
    @visibleForTesting AuthHeaders? authHeaders,
  })  : _http = client ?? http.Client(),
        _authHeaders = authHeaders; // ignore: prefer_initializing_formals

  static const _scope = 'https://www.googleapis.com/auth/drive.appdata';
  static const _api = 'https://www.googleapis.com/drive/v3';
  static const _uploadApi = 'https://www.googleapis.com/upload/drive/v3';

  /// The app's client IDs and file name.
  final GoogleDriveConfig config;

  final http.Client _http;
  final AuthHeaders? _authHeaders;
  var _initialized = false;

  @override
  String get providerName => 'Google Drive';

  @override
  bool get requiresSignIn => true;

  Future<GoogleSignIn> _signIn() async {
    final missingIos = Platform.isIOS && config.iosClientId.isEmpty;
    if (config.serverClientId.isEmpty || missingIos) {
      throw CloudUnavailableException(
          'Drive sign-in is not configured yet: create the '
          '${missingIos ? 'iOS' : 'Web'} OAuth client in Google Cloud '
          'Console and set GoogleDriveConfig.'
          '${missingIos ? 'iosClientId' : 'serverClientId'}.'
          '${config.setupHint.isEmpty ? '' : ' ${config.setupHint}'}');
    }
    final signIn = GoogleSignIn.instance;
    if (!_initialized) {
      await signIn.initialize(
        clientId: config.iosClientId.isEmpty ? null : config.iosClientId,
        serverClientId: config.serverClientId,
      );
      _initialized = true;
    }
    return signIn;
  }

  @override
  Future<CloudAccount?> currentAccount() async {
    if (_authHeaders != null) {
      return const CloudAccount(displayName: 'test@example.com');
    }
    try {
      final signIn = await _signIn();
      final account = await signIn.attemptLightweightAuthentication();
      return account == null
          ? null
          : CloudAccount(displayName: account.email);
    } on CloudUnavailableException {
      return null;
    } on GoogleSignInException {
      return null;
    }
  }

  @override
  Future<CloudAccount?> signIn() async {
    final signIn = await _signIn();
    try {
      final account = await signIn.authenticate(scopeHint: const [_scope]);
      return CloudAccount(displayName: account.email);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null; // user backed out of the sign-in flow
      }
      throw CloudUnavailableException('Google sign-in failed '
          '(${e.code.name}): ${e.description ?? 'no details'}');
    }
  }

  @override
  Future<void> signOut() async => (await _signIn()).signOut();

  Future<Map<String, String>> _headers() async {
    if (_authHeaders != null) return _authHeaders();
    final signIn = await _signIn();
    final account = await signIn.attemptLightweightAuthentication();
    if (account == null) {
      throw const CloudUnavailableException('Not signed in');
    }
    final authz = await account.authorizationClient
            .authorizationForScopes(const [_scope]) ??
        await account.authorizationClient.authorizeScopes(const [_scope]);
    return {'Authorization': 'Bearer ${authz.accessToken}'};
  }

  Future<Map<String, dynamic>?> _findBackup(
      Map<String, String> headers) async {
    final response = await _http.get(
      Uri.parse('$_api/files?spaces=appDataFolder'
          "&q=name='${config.fileName}'"
          '&fields=files(id,modifiedTime,size)'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw CloudUnavailableException('Drive list failed '
          '(${response.statusCode})');
    }
    final files =
        (jsonDecode(response.body) as Map<String, dynamic>)['files'] as List;
    return files.isEmpty ? null : files.first as Map<String, dynamic>;
  }

  @override
  Future<BackupInfo?> latestBackup() async {
    final file = await _findBackup(await _headers());
    if (file == null) return null;
    return BackupInfo(
      modified: DateTime.parse(file['modifiedTime'] as String).toLocal(),
      sizeBytes: int.tryParse(file['size'] as String? ?? '') ?? 0,
    );
  }

  @override
  Future<void> upload(Uint8List bytes) async {
    final headers = await _headers();
    final existing = await _findBackup(headers);

    final http.Response response;
    if (existing == null) {
      // Multipart create: metadata (name + appDataFolder parent) + bytes.
      const boundary = 'cc_core_backup_boundary';
      final metadata = jsonEncode(
          {'name': config.fileName, 'parents': const ['appDataFolder']});
      final body = BytesBuilder()
        ..add(utf8.encode('--$boundary\r\n'
            'Content-Type: application/json; charset=UTF-8\r\n\r\n'
            '$metadata\r\n'
            '--$boundary\r\n'
            'Content-Type: application/zip\r\n\r\n'))
        ..add(bytes)
        ..add(utf8.encode('\r\n--$boundary--'));
      response = await _http.post(
        Uri.parse('$_uploadApi/files?uploadType=multipart'),
        headers: {
          ...headers,
          'Content-Type': 'multipart/related; boundary=$boundary',
        },
        body: body.takeBytes(),
      );
    } else {
      response = await _http.patch(
        Uri.parse('$_uploadApi/files/${existing['id']}?uploadType=media'),
        headers: {...headers, 'Content-Type': 'application/zip'},
        body: bytes,
      );
    }
    if (response.statusCode != 200) {
      throw CloudUnavailableException('Drive upload failed '
          '(${response.statusCode})');
    }
  }

  @override
  Future<Uint8List?> download() async {
    final headers = await _headers();
    final existing = await _findBackup(headers);
    if (existing == null) return null;
    final response = await _http.get(
      Uri.parse('$_api/files/${existing['id']}?alt=media'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw CloudUnavailableException('Drive download failed '
          '(${response.statusCode})');
    }
    return response.bodyBytes;
  }

  @override
  void dispose() => _http.close();
}
