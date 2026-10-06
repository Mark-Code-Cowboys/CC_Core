import 'dart:io';

import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('photo_adopt'));
  tearDown(() => tmp.deleteSync(recursive: true));

  test('adopt copies a temp file in, names it, deletes the source', () async {
    final service = ImagePickerPhotoService(
      Directory('${tmp.path}/photos')..createSync(),
      filePrefix: 'scan',
    );
    final src = File('${tmp.path}/cap1.PNG')..writeAsBytesSync([1, 2, 3]);
    final name = await service.adopt(src.path, prefix: 'scan');
    expect(name, matches(RegExp(r'^scan_\d+_\d{3}\.png$')));
    expect(service.fileFor(name).readAsBytesSync(), [1, 2, 3]);
    expect(src.existsSync(), isFalse);
    final second = await service.adoptBytes([9], prefix: 'scan');
    expect(second, isNot(name));
    expect(
      service.filesFor([name, second]).every((f) => f.existsSync()),
      isTrue,
    );
    await service.discardAll([name, second, 'missing.jpg']);
    expect(service.fileFor(name).existsSync(), isFalse);
  });
}
