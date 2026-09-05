import 'package:cc_core/cc_core.dart';
import 'package:flutter_test/flutter_test.dart';

class _ThrowingRecognizer extends FakeTextRecognitionService {
  _ThrowingRecognizer({required this.throwOn, super.linesByPath});

  final Set<String> throwOn;

  @override
  Future<List<OcrLine>> recognize(String imagePath) {
    if (throwOn.contains(imagePath)) throw Exception('unreadable');
    return super.recognize(imagePath);
  }
}

void main() {
  test('parses every readable page in capture order', () async {
    final recognizer = FakeTextRecognitionService(linesByPath: {
      'a.jpg': const [OcrLine('Alpha', left: 0, top: 0, height: 10)],
      'b.jpg': const [OcrLine('Beta', left: 0, top: 0, height: 10)],
    });

    final result = await batchTranscribe<String>(
      imagePaths: ['a.jpg', 'b.jpg'],
      recognizer: recognizer,
      parse: (lines) => lines.first.text,
    );

    expect(result.items.map((i) => i.value), ['Alpha', 'Beta']);
    expect(result.items.map((i) => i.imagePath), ['a.jpg', 'b.jpg']);
    expect(result.items.every((i) => i.kept), isTrue);
    expect(result.failedCount, 0);
  });

  test('counts unreadable pages and skips unparseable ones silently',
      () async {
    final recognizer = _ThrowingRecognizer(
      throwOn: {'broken.jpg'},
      linesByPath: {
        'good.jpg': const [OcrLine('Card', left: 0, top: 0, height: 10)],
        'blank.jpg': const [],
      },
    );

    final result = await batchTranscribe<String>(
      imagePaths: ['broken.jpg', 'good.jpg', 'blank.jpg'],
      recognizer: recognizer,
      parse: (lines) => lines.isEmpty ? null : lines.first.text,
    );

    expect(result.items.single.value, 'Card');
    expect(result.failedCount, 1);
  });
}
