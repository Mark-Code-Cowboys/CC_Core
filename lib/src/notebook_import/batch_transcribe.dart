import '../scan/ocr_types.dart';
import '../scan/text_recognition_service.dart';

/// One page of a batch scan under review: the captured image, the
/// parsed value (mutable — the user edits it on the review screen), and
/// whether it is still checked for the bulk insert.
class BatchScanItem<T> {
  /// Creates a reviewed page.
  BatchScanItem({required this.imagePath, required this.value, this.kept = true});

  /// Transient path of the captured page image.
  final String imagePath;

  /// The parsed fields, as transcribed — edited in place during review.
  T value;

  /// Whether this page is included in the bulk insert.
  bool kept;
}

/// The pages that survived OCR plus how many failed outright, so the
/// review screen can say "18 cards read, 2 unreadable".
class BatchTranscription<T> {
  /// Creates the result.
  const BatchTranscription(this.items, {required this.failedCount});

  /// One item per readable page, in capture order.
  final List<BatchScanItem<T>> items;

  /// Pages whose OCR threw — unreadable images, not empty ones.
  final int failedCount;
}

/// OCRs every captured page and hands each to the app's [parse]. A page
/// whose recognition throws is skipped and counted; a page that parses
/// to null (nothing usable on it) is skipped silently. Transcription
/// only: [parse] must report what the camera saw, never invent values.
Future<BatchTranscription<T>> batchTranscribe<T>({
  required List<String> imagePaths,
  required TextRecognitionService recognizer,
  required T? Function(List<OcrLine> lines) parse,
}) async {
  final items = <BatchScanItem<T>>[];
  var failed = 0;
  for (final path in imagePaths) {
    final List<OcrLine> lines;
    try {
      lines = await recognizer.recognize(path);
    } on Exception {
      failed++;
      continue;
    }
    final value = parse(lines);
    if (value == null) continue;
    items.add(BatchScanItem(imagePath: path, value: value));
  }
  return BatchTranscription(items, failedCount: failed);
}
