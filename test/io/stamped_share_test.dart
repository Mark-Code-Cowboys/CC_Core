import 'dart:io';

import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('writes the date-stamped file and hands it to the share sheet',
      () async {
    final share = FakeShareLauncher();
    final temp = await Directory.systemTemp.createTemp('cc-stamp');
    addTearDown(() => temp.delete(recursive: true));

    final csv = await shareStampedFile(
      share: share,
      tempDir: () async => temp,
      baseName: 'freshpot-beans',
      extension: 'csv',
      mimeType: 'text/csv',
      shareText: 'Fresh Pot notes',
      text: 'a,b\n1,2\n',
      now: DateTime(2026, 9, 5),
    );
    expect(csv.path, endsWith('freshpot-beans-2026-09-05.csv'));
    expect(await csv.readAsString(), 'a,b\n1,2\n');
    expect(share.sharedFiles, [csv.path]);

    final zip = await shareStampedFile(
      share: share,
      tempDir: () async => temp,
      baseName: 'freshpot-backup',
      extension: 'zip',
      mimeType: 'application/zip',
      shareText: 'Fresh Pot backup',
      bytes: [1, 2, 3],
      now: DateTime(2026, 9, 5),
    );
    expect(await zip.readAsBytes(), [1, 2, 3]);
  });

  test('exactly one payload, asserted', () {
    expect(
        () => shareStampedFile(
              share: FakeShareLauncher(),
              tempDir: () async => Directory.systemTemp,
              baseName: 'x',
              extension: 'csv',
              mimeType: 'text/csv',
              shareText: 'x',
            ),
        throwsA(isA<AssertionError>()));
  });
}
