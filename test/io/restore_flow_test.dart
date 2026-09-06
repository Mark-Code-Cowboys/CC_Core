import 'dart:io';

import 'package:cc_core/cc_core.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingPhotoService implements PhotoService {
  final imported = <String, List<int>>{};

  @override
  Future<String?> acquire(PhotoSource source) async => null;
  @override
  Future<String?> acquireTransient(PhotoSource source) async => null;
  @override
  File fileFor(String photoPath) => File('/x/$photoPath');
  @override
  Future<void> discard(String photoPath) async {}
  @override
  Future<void> importBytes(String photoPath, List<int> bytes) async {
    imported[photoPath] = bytes;
  }
}

void main() {
  // In-memory zip: XFile.fromData keeps the widget-test zone free of
  // real file IO (which never completes there).
  final zipBytes = buildBackupArchive(
    exportData: {'app': 'TestApp', 'format': 1},
    media: {
      'photo-1.jpg': [9, 8, 7],
    },
  );
  XFile fakeZip() => XFile.fromData(zipBytes, path: 'backup.zip');

  Widget host({
    required Future<void> Function(BackupContents) restore,
    required PhotoService store,
    Future<XFile?> Function()? pick,
  }) =>
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => runRestoreFlow(
                  context,
                  confirmBody: 'Everything is replaced.',
                  restore: restore,
                  photoStore: store,
                  pickFile: pick ?? () async => fakeZip(),
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );

  testWidgets('pick -> confirm -> restore -> media -> snackbar',
      (tester) async {
    Map<String, Object?>? received;
    final store = _RecordingPhotoService();
    await tester.pumpWidget(host(
      restore: (contents) async => received = contents.exportData,
      store: store,
    ));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    expect(find.text('Everything is replaced.'), findsOneWidget);
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();

    expect(received!['app'], 'TestApp');
    expect(store.imported['photo-1.jpg'], [9, 8, 7]);
    expect(find.text('Backup restored.'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5)); // drain snackbar
  });

  testWidgets('cancel restores nothing', (tester) async {
    var called = false;
    await tester.pumpWidget(host(
      restore: (_) async => called = true,
      store: _RecordingPhotoService(),
    ));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(called, isFalse);
  });

  testWidgets("the app's rejection reads back as its own words",
      (tester) async {
    await tester.pumpWidget(host(
      restore: (_) async =>
          throw const InvalidBackupException('Unrecognized export format'),
      store: _RecordingPhotoService(),
    ));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore'));
    await tester.pumpAndSettle();
    expect(find.text('Unrecognized export format'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });
}
