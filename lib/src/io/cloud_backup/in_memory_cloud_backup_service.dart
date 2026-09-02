import 'dart:typed_data';

import 'cloud_backup_service.dart';

/// Plugin-free [CloudBackupService] for widget and unit tests: one
/// backup slot in memory, sign-in always succeeds, and every upload is
/// counted for assertions.
class InMemoryCloudBackupService implements CloudBackupService {
  /// Creates the fake, optionally already attached to [account] and
  /// holding [stored] as its backup.
  InMemoryCloudBackupService({
    CloudAccount? account,
    this.stored,
    this.providerName = 'Test Cloud',
    this.requiresSignIn = true,
    this.signInAs = const CloudAccount(displayName: 'mark@example.com'),
  }) : _account = account; // ignore: prefer_initializing_formals

  @override
  final String providerName;

  @override
  final bool requiresSignIn;

  /// The account [signIn] attaches.
  final CloudAccount signInAs;

  CloudAccount? _account;

  /// The bytes of the stored backup, or null when there is none.
  Uint8List? stored;

  /// Reported as the backup's modified time.
  DateTime storedAt = DateTime(2026, 8, 17, 12);

  /// How many uploads have happened.
  int uploads = 0;

  @override
  Future<CloudAccount?> currentAccount() async => _account;

  @override
  Future<CloudAccount?> signIn() async => _account = signInAs;

  @override
  Future<void> signOut() async => _account = null;

  @override
  Future<BackupInfo?> latestBackup() async => stored == null
      ? null
      : BackupInfo(modified: storedAt, sizeBytes: stored!.length);

  @override
  Future<void> upload(Uint8List bytes) async {
    stored = bytes;
    uploads++;
  }

  @override
  Future<Uint8List?> download() async => stored;

  @override
  void dispose() {}
}
