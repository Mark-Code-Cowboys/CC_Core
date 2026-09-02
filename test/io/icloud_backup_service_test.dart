import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_core/cc_core.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_test/flutter_test.dart';

/// Scripted stand-in for the icloud_storage plugin: one container in
/// memory, with knobs for whether iCloud is on, whether progress
/// streams ever end, and whether transfers actually land.
class _FakeICloudFiles implements ICloudFiles {
  bool available = true;
  bool endUploadStream = true;
  bool endDownloadStream = true;
  bool markUploaded = true;
  bool writeDownload = true;

  final entries = <ICloudEntry>[];
  Uint8List? content;
  String? lastDestination;
  final _controllers = <StreamController<double>>[];

  void closeAll() {
    for (final c in _controllers) {
      if (!c.isClosed) c.close();
    }
  }

  StreamController<double> _progress(bool end) {
    final c = StreamController<double>();
    _controllers.add(c);
    if (end) {
      c
        ..add(100)
        ..close();
    }
    return c;
  }

  @override
  Future<List<ICloudEntry>> gather(String containerId) async {
    if (!available) {
      throw PlatformException(code: ICloudFiles.containerUnavailable);
    }
    return List.of(entries);
  }

  @override
  Future<void> upload({
    required String containerId,
    required String filePath,
    required String destinationRelativePath,
    required void Function(Stream<double>) onProgress,
  }) async {
    if (!available) {
      throw PlatformException(code: ICloudFiles.containerUnavailable);
    }
    content = await File(filePath).readAsBytes();
    entries
      ..removeWhere((e) => e.relativePath == destinationRelativePath)
      ..add(ICloudEntry(
        relativePath: destinationRelativePath,
        sizeInBytes: content!.length,
        modified: DateTime(2026, 9, 2, 9),
        isUploaded: markUploaded,
      ));
    onProgress(_progress(endUploadStream).stream);
  }

  @override
  Future<void> download({
    required String containerId,
    required String relativePath,
    required String destinationFilePath,
    required void Function(Stream<double>) onProgress,
  }) async {
    if (!available) {
      throw PlatformException(code: ICloudFiles.containerUnavailable);
    }
    lastDestination = destinationFilePath;
    if (writeDownload) await File(destinationFilePath).writeAsBytes(content!);
    onProgress(_progress(endDownloadStream).stream);
  }

  @override
  Future<void> delete({
    required String containerId,
    required String relativePath,
  }) async {
    entries.removeWhere((e) => e.relativePath == relativePath);
  }
}

void main() {
  late Directory tmp;
  late _FakeICloudFiles files;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('cc_icloud_test');
    files = _FakeICloudFiles();
  });

  tearDown(() async {
    files.closeAll();
    await tmp.delete(recursive: true);
  });

  ICloudBackupService service({
    Duration syncTimeout = const Duration(seconds: 5),
  }) =>
      ICloudBackupService(
        containerId: 'iCloud.com.example.app',
        fileName: 'app-backup.zip',
        files: files,
        tempDir: tmp,
        syncTimeout: syncTimeout,
        pollInterval: const Duration(milliseconds: 5),
      );

  test('provider metadata: no in-app sign-in', () {
    final s = service();
    expect(s.providerName, 'iCloud');
    expect(s.requiresSignIn, isFalse);
  });

  test('currentAccount is the device label when iCloud is on, else null',
      () async {
    expect((await service().currentAccount())?.displayName,
        ICloudBackupService.accountLabel);

    files.available = false;
    expect(await service().currentAccount(), isNull);
  });

  test('signIn re-checks and explains how to turn iCloud on', () async {
    expect((await service().signIn())?.displayName,
        ICloudBackupService.accountLabel);

    files.available = false;
    await expectLater(
      service().signIn(),
      throwsA(isA<CloudUnavailableException>()
          .having((e) => e.message, 'message', contains('Settings'))),
    );
  });

  test('latestBackup is null without a file and maps the entry with one',
      () async {
    expect(await service().latestBackup(), isNull);

    files.entries.add(ICloudEntry(
      relativePath: 'app-backup.zip',
      sizeInBytes: 512,
      modified: DateTime(2026, 8, 17, 12),
      isUploaded: true,
    ));
    final info = await service().latestBackup();
    expect(info!.sizeBytes, 512);
    expect(info.modified, DateTime(2026, 8, 17, 12));

    // Other files in the container are not the backup.
    files.entries
      ..clear()
      ..add(ICloudEntry(
        relativePath: 'Documents/other.txt',
        sizeInBytes: 1,
        modified: DateTime(2026),
        isUploaded: true,
      ));
    expect(await service().latestBackup(), isNull);
  });

  test('upload stages the bytes at the container root and cleans up',
      () async {
    await service().upload(Uint8List.fromList([1, 2, 3]));

    expect(files.content, [1, 2, 3]);
    expect(files.entries.single.relativePath, 'app-backup.zip');
    expect(tmp.listSync(), isEmpty, reason: 'staging file removed');
  });

  test('upload settles by polling when the progress stream never ends',
      () async {
    files.endUploadStream = false;

    await service().upload(Uint8List.fromList([1]));

    expect(files.entries.single.isUploaded, isTrue);
  });

  test('upload that outlasts the sync timeout is not an error', () async {
    files
      ..endUploadStream = false
      ..markUploaded = false;

    await service(syncTimeout: const Duration(milliseconds: 30))
        .upload(Uint8List.fromList([1]));

    expect(files.content, [1]);
    expect(tmp.listSync(), isEmpty);
  });

  test('upload reports iCloud being off', () async {
    files.available = false;
    await expectLater(service().upload(Uint8List(0)),
        throwsA(isA<CloudUnavailableException>()));
  });

  test('download returns null with no backup, bytes with one', () async {
    expect(await service().download(), isNull);

    await service().upload(Uint8List.fromList([4, 5, 6]));
    expect(await service().download(), [4, 5, 6]);
    expect(files.lastDestination, startsWith(tmp.path));
    expect(tmp.listSync(), isEmpty, reason: 'staging file removed');
  });

  test('download settles by polling once the full file has landed',
      () async {
    await service().upload(Uint8List.fromList([4, 5, 6]));
    files.endDownloadStream = false;

    expect(await service().download(), [4, 5, 6]);
  });

  test('download that never lands throws', () async {
    await service().upload(Uint8List.fromList([4]));
    files
      ..endDownloadStream = false
      ..writeDownload = false;

    await expectLater(
      service(syncTimeout: const Duration(milliseconds: 30)).download(),
      throwsA(isA<CloudUnavailableException>()
          .having((e) => e.message, 'message', contains('downloading'))),
    );
  });
}
