import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';

class _ThrowingScanner extends FakeDocumentScanService {
  _ThrowingScanner() : super(const []);

  @override
  Future<List<String>> scanAll({int pageLimit = 20}) async =>
      throw Exception('camera permission denied');
}

void main() {
  test('uses the scanner when supported, honoring the page limit', () async {
    final paths = await captureDocumentPages(
      FakeDocumentScanService(['a.jpg', 'b.jpg']),
      pageLimit: 20,
    );
    expect(paths, ['a.jpg', 'b.jpg']);
  });

  test('backing out is an empty capture', () async {
    expect(
      await captureDocumentPages(
        FakeDocumentScanService(const []),
        pageLimit: 20,
      ),
      isEmpty,
    );
  });

  test(
    'a failing scanner throws a DocumentCaptureException with its message',
    () async {
      expect(
        () => captureDocumentPages(_ThrowingScanner(), pageLimit: 20),
        throwsA(
          predicate(
            (e) =>
                e is DocumentCaptureException &&
                e.message == 'camera permission denied',
          ),
        ),
      );
    },
  );
}
