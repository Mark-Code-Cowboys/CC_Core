import 'dart:typed_data';

/// The cloud account a backup service is attached to.
class CloudAccount {
  /// Creates an account whose [displayName] is what the UI shows — an
  /// email for Google Drive, a device-level label for iCloud (Apple
  /// never exposes the Apple ID to apps).
  const CloudAccount({required this.displayName});

  /// What to show the user: "mark@example.com", "iCloud on this iPhone".
  final String displayName;
}

/// Metadata of the one backup a service keeps.
class BackupInfo {
  /// Creates the descriptor for a stored backup.
  const BackupInfo({required this.modified, required this.sizeBytes});

  /// When the backup was last written, in local time.
  final DateTime modified;

  /// Size of the archive in bytes.
  final int sizeBytes;
}

/// The cloud could not be reached, is misconfigured, or refused: the
/// [message] is user-facing (empty means "use the app's generic copy").
class CloudUnavailableException implements Exception {
  /// Creates the exception with an optional user-facing [message].
  const CloudUnavailableException([this.message = '']);

  /// User-facing explanation, or empty for the app's generic wording.
  final String message;

  @override
  String toString() => 'CloudUnavailableException: $message';
}

/// One backup slot in the *user's own* cloud storage — Google Drive's
/// app-data folder, the app's iCloud container. No Code Cowboys
/// servers: bytes go from the phone to the user's cloud and nowhere
/// else. Abstract so app screens stay plugin-free in widget tests.
abstract class CloudBackupService {
  /// Human name for copy: "Google Drive", "iCloud".
  String get providerName;

  /// Whether the user signs in from inside the app (Google) or the OS
  /// account is used as-is (iCloud). Screens hide the sign-in button
  /// and the sign-out action when this is false.
  bool get requiresSignIn;

  /// The account already attached, or null. Must never throw — screens
  /// call it on every open; misconfiguration surfaces from [signIn].
  Future<CloudAccount?> currentAccount();

  /// Interactive sign-in; null when the user backs out. For services
  /// without an in-app sign-in this re-checks availability and throws
  /// [CloudUnavailableException] with instructions when it's off.
  Future<CloudAccount?> signIn();

  /// Detaches the account. A no-op where [requiresSignIn] is false.
  Future<void> signOut();

  /// Metadata of the existing backup, or null when there is none.
  Future<BackupInfo?> latestBackup();

  /// Uploads [bytes] as the (single) backup, replacing any previous one.
  Future<void> upload(Uint8List bytes);

  /// Downloads the backup, or null when there is none.
  Future<Uint8List?> download();

  /// Releases clients/streams. Default does nothing.
  void dispose() {}
}
