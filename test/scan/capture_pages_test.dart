import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';

class _ThrowingScanner extends FakeDocumentScanService {
  _ThrowingScanner() : super(const []);

  @override
  Future<List<String>> scanAll({int pageLimit = 20}) async =>
      throw Exception('scanner crashed');
}

void main() {
  test('uses the scanner when supported, honoring the page limit',
      () async {
    final paths = await captureDocumentPages(
        FakeDocumentScanService(['a.jpg', 'b.jpg']),
        pageLimit: 20);
    expect(paths, ['a.jpg', 'b.jpg']);
  });

  test('a throwing scanner yields an empty capture, not a crash',
      () async {
    expect(
        await captureDocumentPages(_ThrowingScanner(), pageLimit: 20),
        isEmpty);
  });
}
