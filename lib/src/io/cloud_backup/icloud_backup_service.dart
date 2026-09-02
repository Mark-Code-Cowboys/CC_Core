import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show PlatformException;
import 'package:icloud_storage/icloud_storage.dart';

import 'cloud_backup_service.dart';

/// One file in the app's iCloud container, as much of the plugin's
/// metadata as the backup service needs.
class ICloudEntry {
  /// Creates an entry.
  const ICloudEntry({
    required this.relativePath,
    required this.sizeInBytes,
    required this.modified,
    required this.isUploaded,
  });

  /// Path relative to the container root ("backup.zip" for a root file).
  final String relativePath;

  /// Size in bytes.
  final int sizeInBytes;

  /// Content change date (local time).
  final DateTime modified;

  /// True once iCloud has finished syncing the file up.
  final bool isUploaded;
}

/// Seam over the `icloud_storage` plugin so [ICloudBackupService] is
/// unit-testable. [PluginICloudFiles] is the real one.
abstract class ICloudFiles {
  /// Lists every file in the container. Throws [PlatformException]
  /// with code [ICloudFiles.containerUnavailable] when iCloud is off.
  Future<List<ICloudEntry>> gather(String containerId);

  /// Copies [filePath] into the container at [destinationRelativePath]
  /// (overwriting) and returns once the copy is placed; the actual sync
  /// is reported on [onProgress] (0–100, then done).
  Future<void> upload({
    required String containerId,
    required String filePath,
    required String destinationRelativePath,
    required void Function(Stream<double>) onProgress,
  });

  /// Fetches [relativePath] from iCloud and writes it to
  /// [destinationFilePath] when the transfer completes; [onProgress]
  /// reports it (0–100, then done).
  Future<void> download({
    required String containerId,
    required String relativePath,
    required String destinationFilePath,
    required void Function(Stream<double>) onProgress,
  });

  /// Removes a file; throws [PlatformException] with code
  /// [ICloudFiles.fileNotFound] when there is none.
  Future<void> delete({
    required String containerId,
    required String relativePath,
  });

  /// Plugin error code: invalid container id, user not signed in to
  /// iCloud, or iCloud Drive disabled for the app.
  static const containerUnavailable = 'E_CTR';

  /// Plugin error code for a missing file.
  static const fileNotFound = 'E_FNF';
}

/// [ICloudFiles] backed by the `icloud_storage` plugin.
class PluginICloudFiles implements ICloudFiles {
  /// Creates the plugin adapter.
  const PluginICloudFiles();

  @override
  Future<List<ICloudEntry>> gather(String containerId) async {
    final files = await ICloudStorage.gather(containerId: containerId);
    return [
      for (final f in files)
        ICloudEntry(
          relativePath: f.relativePath,
          sizeInBytes: f.sizeInBytes,
          modified: f.contentChangeDate.toLocal(),
          isUploaded: f.isUploaded,
        ),
    ];
  }

  @override
  Future<void> upload({
    required String containerId,
    required String filePath,
    required String destinationRelativePath,
    required void Function(Stream<double>) onProgress,
  }) =>
      ICloudStorage.upload(
        containerId: containerId,
        filePath: filePath,
        destinationRelativePath: destinationRelativePath,
        onProgress: onProgress,
      );

  @override
  Future<void> download({
    required String containerId,
    required String relativePath,
    required String destinationFilePath,
    required void Function(Stream<double>) onProgress,
  }) =>
      ICloudStorage.download(
        containerId: containerId,
        relativePath: relativePath,
        destinationFilePath: destinationFilePath,
        onProgress: onProgress,
      );

  @override
  Future<void> delete({
    required String containerId,
    required String relativePath,
  }) =>
      ICloudStorage.delete(containerId: containerId, relativePath: relativePath);
}

/// iCloud implementation: the backup lives at the root of the app's
/// own iCloud container, which the Files app does not show (only a
/// `Documents/` subfolder would be), mirroring Drive's hidden app-data
/// folder. Uses the device's Apple ID — there is no in-app sign-in,
/// and Apple never exposes the account's email.
///
/// Setup: an iCloud container (`iCloud.<bundle id>`) on the App ID in
/// the Apple Developer portal, the iCloud capability with "iCloud
/// Documents" in the app's entitlements, and a regenerated provisioning
/// profile. iOS only — construct it behind a platform check.
class ICloudBackupService implements CloudBackupService {
  /// Creates the service for [containerId] (e.g.
  /// `iCloud.com.example.app`). [files], [tempDir], [syncTimeout] and
  /// [pollInterval] are test seams.
  ICloudBackupService({
    required this.containerId,
    this.fileName = 'backup.zip',
    ICloudFiles files = const PluginICloudFiles(),
    Directory? tempDir,
    this.syncTimeout = const Duration(seconds: 90),
    this.pollInterval = const Duration(seconds: 1),
  })  : _files = files, // ignore: prefer_initializing_formals
        _tempDir = tempDir ?? Directory.systemTemp;

  /// The iCloud container identifier from the Apple Developer portal.
  final String containerId;

  /// Name of the single backup file at the container root.
  final String fileName;

  /// How long to wait for iCloud to finish a transfer. An upload that
  /// outlasts it is still safe (the file sits in the container and
  /// syncs in the background); a download that does throws.
  final Duration syncTimeout;

  /// How often to re-check iCloud metadata while waiting on a transfer.
  final Duration pollInterval;

  final ICloudFiles _files;
  final Directory _tempDir;

  /// Shown as the attached "account", since the Apple ID is not
  /// readable by apps.
  static const accountLabel = 'iCloud on this device';

  @override
  String get providerName => 'iCloud';

  @override
  bool get requiresSignIn => false;

  Future<ICloudEntry?> _find() async {
    final entries = await _files.gather(containerId);
    for (final e in entries) {
      if (e.relativePath == fileName) return e;
    }
    return null;
  }

  CloudUnavailableException _wrap(PlatformException e) =>
      CloudUnavailableException(switch (e.code) {
        ICloudFiles.containerUnavailable => 'iCloud Drive is turned off '
            'for this app. In Settings, sign in to iCloud and allow '
            'iCloud Drive, then try again.',
        _ => 'iCloud error (${e.code}): ${e.message ?? 'no details'}',
      });

  @override
  Future<CloudAccount?> currentAccount() async {
    try {
      await _files.gather(containerId);
      return const CloudAccount(displayName: accountLabel);
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<CloudAccount?> signIn() async {
    // Nothing to sign in to — re-check availability and explain if off.
    try {
      await _files.gather(containerId);
      return const CloudAccount(displayName: accountLabel);
    } on PlatformException catch (e) {
      throw _wrap(e);
    }
  }

  @override
  Future<void> signOut() async {}

  @override
  void dispose() {}

  @override
  Future<BackupInfo?> latestBackup() async {
    try {
      final entry = await _find();
      if (entry == null) return null;
      return BackupInfo(
          modified: entry.modified, sizeBytes: entry.sizeInBytes);
    } on PlatformException catch (e) {
      throw _wrap(e);
    }
  }

  File _staging(String suffix) =>
      File('${_tempDir.path}/cc_icloud_$suffix-$fileName');

  /// Completes when the plugin's progress stream finishes, or when
  /// [settled] first reports true (polled), whichever comes first.
  /// Throws [TimeoutException] after [syncTimeout] and rethrows a
  /// stream error as [CloudUnavailableException].
  Future<void> _awaitTransfer(
    Future<void> streamDone,
    Future<bool> Function() settled,
  ) async {
    final result = Completer<void>();
    void finish([Object? error]) {
      if (result.isCompleted) return;
      if (error == null) {
        result.complete();
      } else {
        result.completeError(error);
      }
    }

    unawaited(streamDone.then((_) => finish(), onError: finish));
    unawaited(() async {
      while (!result.isCompleted) {
        try {
          if (await settled()) return finish();
        } on Object {
          // Metadata hiccups while syncing are normal; keep waiting.
        }
        await Future<void>.delayed(pollInterval);
      }
    }());
    try {
      await result.future.timeout(syncTimeout);
    } on TimeoutException {
      finish(); // stop the poller
      rethrow;
    } on PlatformException catch (e) {
      throw _wrap(e);
    } on Object catch (e) {
      throw CloudUnavailableException('iCloud transfer failed: $e');
    }
  }

  @override
  Future<void> upload(Uint8List bytes) async {
    final staging = _staging('upload');
    await staging.writeAsBytes(bytes, flush: true);
    final done = Completer<void>();
    try {
      await _files.upload(
        containerId: containerId,
        filePath: staging.path,
        destinationRelativePath: fileName,
        onProgress: (stream) => stream.listen(
          null,
          onDone: () => done.isCompleted ? null : done.complete(),
          onError: (Object e) =>
              done.isCompleted ? null : done.completeError(e),
          cancelOnError: true,
        ),
      );
      // The plugin only ends the stream when its metadata query reports
      // 100 %, which a small file can beat; the poll catches that.
      await _awaitTransfer(
        done.future,
        () async => (await _find())?.isUploaded ?? false,
      );
    } on TimeoutException {
      // The file is in the container; iCloud finishes syncing it in the
      // background (and latestBackup already lists it). Not a failure.
    } on PlatformException catch (e) {
      throw _wrap(e);
    } finally {
      if (staging.existsSync()) await staging.delete();
    }
  }

  @override
  Future<Uint8List?> download() async {
    final ICloudEntry? entry;
    try {
      entry = await _find();
    } on PlatformException catch (e) {
      throw _wrap(e);
    }
    if (entry == null) return null;

    final staging = _staging('download');
    if (staging.existsSync()) await staging.delete();
    final done = Completer<void>();
    try {
      await _files.download(
        containerId: containerId,
        relativePath: fileName,
        destinationFilePath: staging.path,
        onProgress: (stream) => stream.listen(
          null,
          onDone: () => done.isCompleted ? null : done.complete(),
          onError: (Object e) =>
              done.isCompleted ? null : done.completeError(e),
          cancelOnError: true,
        ),
      );
      // The plugin writes the destination only after the transfer
      // completes, so a fully-sized file is as good as the done event.
      await _awaitTransfer(
        done.future,
        () async =>
            staging.existsSync() && staging.lengthSync() == entry!.sizeInBytes,
      );
      return await staging.readAsBytes();
    } on TimeoutException {
      throw const CloudUnavailableException(
          "iCloud hasn't finished downloading the backup — check your "
          'connection and try again.');
    } on PlatformException catch (e) {
      throw _wrap(e);
    } finally {
      if (staging.existsSync()) await staging.delete();
    }
  }
}
