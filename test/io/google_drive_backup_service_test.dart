import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Drive REST layer over a scripted http client; sign-in is bypassed
/// through the authHeaders seam.
void main() {
  const config = GoogleDriveConfig(
    serverClientId: 'web-id',
    fileName: 'app-backup.zip',
  );
  const found = {
    'files': [
      {'id': 'f1', 'modifiedTime': '2026-08-17T12:00:00.000Z', 'size': '2048'},
    ],
  };
  const none = {'files': <Object>[]};

  final requests = <http.Request>[];

  GoogleDriveBackupService service(
    Future<http.Response> Function(http.Request) handler,
  ) {
    requests.clear();
    return GoogleDriveBackupService(
      config,
      client: MockClient((r) {
        requests.add(r);
        return handler(r);
      }),
      authHeaders: () async => {'Authorization': 'Bearer tok'},
    );
  }

  http.Response json(Object body) => http.Response(jsonEncode(body), 200);

  test('exposes provider metadata and the seam account', () async {
    final s = service((_) async => json(none));
    expect(s.providerName, 'Google Drive');
    expect(s.requiresSignIn, isTrue);
    expect((await s.currentAccount())?.displayName, 'test@example.com');
  });

  test(
    'latestBackup is null without a file and maps metadata with one',
    () async {
      expect(await service((_) async => json(none)).latestBackup(), isNull);

      final info = await service((_) async => json(found)).latestBackup();
      expect(info!.sizeBytes, 2048);
      expect(info.modified.toUtc(), DateTime.utc(2026, 8, 17, 12));
      final list = requests.single;
      expect(list.url.queryParameters['spaces'], 'appDataFolder');
      expect(list.url.queryParameters['q'], "name='app-backup.zip'");
      expect(list.headers['Authorization'], 'Bearer tok');
    },
  );

  test('upload creates via multipart when no backup exists', () async {
    final s = service(
      (r) async => r.method == 'POST' ? http.Response('{}', 200) : json(none),
    );

    await s.upload(Uint8List.fromList([1, 2, 3]));

    final post = requests.last;
    expect(post.method, 'POST');
    expect(post.url.path, '/upload/drive/v3/files');
    expect(post.url.queryParameters['uploadType'], 'multipart');
    expect(post.headers['Content-Type'], startsWith('multipart/related'));
    final body = utf8.decode(post.bodyBytes, allowMalformed: true);
    expect(body, contains('"name":"app-backup.zip"'));
    expect(body, contains('"parents":["appDataFolder"]'));
    expect(post.bodyBytes, containsAllInOrder([1, 2, 3]));
  });

  test('upload patches the existing file in place', () async {
    final s = service(
      (r) async => r.method == 'PATCH' ? http.Response('{}', 200) : json(found),
    );

    await s.upload(Uint8List.fromList([9]));

    final patch = requests.last;
    expect(patch.method, 'PATCH');
    expect(patch.url.path, '/upload/drive/v3/files/f1');
    expect(patch.url.queryParameters['uploadType'], 'media');
    expect(patch.headers['Content-Type'], 'application/zip');
    expect(patch.bodyBytes, [9]);
  });

  test('download returns the bytes, or null with no backup', () async {
    expect(await service((_) async => json(none)).download(), isNull);

    final s = service(
      (r) async => r.url.queryParameters['alt'] == 'media'
          ? http.Response.bytes([7, 8], 200)
          : json(found),
    );
    expect(await s.download(), [7, 8]);
    expect(requests.last.url.path, '/drive/v3/files/f1');
  });

  test('non-200 answers surface as CloudUnavailableException', () async {
    final s = service((_) async => http.Response('nope', 503));
    await expectLater(
      s.latestBackup(),
      throwsA(isA<CloudUnavailableException>()),
    );
    await expectLater(
      s.upload(Uint8List(0)),
      throwsA(isA<CloudUnavailableException>()),
    );
  });

  group('remembered account', () {
    test('currentAccount falls back to the stored email when sign-in '
        'is unavailable', () async {
      final store = InMemoryKeyValueStore();
      await store.setString(
        GoogleDriveBackupService.accountKey,
        'mark@example.com',
      );
      // Blank serverClientId: _signIn throws before touching the plugin.
      final s = GoogleDriveBackupService(
        const GoogleDriveConfig(serverClientId: ''),
        store: store,
      );
      expect((await s.currentAccount())?.displayName, 'mark@example.com');
    });

    test('currentAccount is null with nothing remembered', () async {
      final s = GoogleDriveBackupService(
        const GoogleDriveConfig(serverClientId: ''),
        store: InMemoryKeyValueStore(),
      );
      expect(await s.currentAccount(), isNull);
    });

    test('CloudSignInRequiredException is a CloudUnavailableException', () {
      expect(
        const CloudSignInRequiredException('x'),
        isA<CloudUnavailableException>(),
      );
    });
  });
}
