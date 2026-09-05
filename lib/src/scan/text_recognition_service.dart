import 'ocr_types.dart';

/// On-device text recognition for one captured image. The real
/// implementation wraps ML Kit's bundled Latin model — no network,
/// ships in the app binary. Extracted from Table Encore's
/// `ReceiptOcrService`, renamed: nothing in it was receipt-specific.
abstract class TextRecognitionService {
  /// Recognizes text in the image at [imagePath].
  Future<List<OcrLine>> recognize(String imagePath);

  /// Releases platform resources.
  void dispose() {}
}

/// Canned recognition for tests: returns [linesByPath] entries by exact
/// path, falling back to [fallback].
class FakeTextRecognitionService implements TextRecognitionService {
  /// Creates the fake.
  FakeTextRecognitionService({
    this.linesByPath = const {},
    this.fallback = const [],
  });

  /// Lines returned for a specific image path.
  final Map<String, List<OcrLine>> linesByPath;

  /// Lines returned for any path not in [linesByPath].
  final List<OcrLine> fallback;

  /// Every path recognized, for assertions.
  final recognizedPaths = <String>[];

  @override
  Future<List<OcrLine>> recognize(String imagePath) async {
    recognizedPaths.add(imagePath);
    return linesByPath[imagePath] ?? fallback;
  }

  @override
  void dispose() {}
}
