import 'dart:math' as math;

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'ocr_types.dart';
import 'text_recognition_service.dart';

/// ML Kit's bundled Latin text recognizer — on-device, no network.
/// Extracted from Table Encore's `MlKitReceiptOcrService`.
class MlKitTextRecognitionService implements TextRecognitionService {
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  @override
  Future<List<OcrLine>> recognize(String imagePath) async {
    final result =
        await _recognizer.processImage(InputImage.fromFilePath(imagePath));
    return [
      for (final block in result.blocks)
        for (final line in block.lines)
          OcrLine(
            line.text,
            left: line.boundingBox.left,
            top: line.boundingBox.top,
            height: line.boundingBox.height,
            width: line.boundingBox.width,
            angle: _baselineAngle(line.cornerPoints),
          ),
    ];
  }

  @override
  void dispose() {
    _recognizer.close();
  }
}

/// Tilt of the line's top edge from its first two corner points
/// (top-left, then top-right, in reading order). Computed here rather
/// than taken from the plugin's `angle` field because iOS reports that
/// as null while both platforms supply corner points.
double? _baselineAngle(List<math.Point<int>> corners) {
  if (corners.length < 2) return null;
  final dx = corners[1].x - corners[0].x;
  final dy = corners[1].y - corners[0].y;
  if (dx <= 0) return null;
  return math.atan2(dy, dx);
}
