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
          ),
    ];
  }

  @override
  void dispose() {
    _recognizer.close();
  }
}
