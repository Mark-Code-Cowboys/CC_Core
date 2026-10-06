import 'package:image_picker/image_picker.dart';

import 'document_scan_service.dart';

/// The document camera could not be used: a denied permission, no
/// camera, missing Play services. Distinct from the user backing out,
/// which is an empty capture. Carries the plugin's message so the
/// app can show a recovery hint ("allow camera access in Settings, or
/// pick a photo").
class DocumentCaptureException implements Exception {
  /// The plugin's own message, prefix stripped.
  const DocumentCaptureException(this.message);

  /// What went wrong, for the recovery hint.
  final String message;

  @override
  String toString() => message;
}

/// The capture preamble every import flow shares: the document scanner
/// (auto-crop/deskew) where supported, otherwise the photo picker —
/// multi-select for a batch, single gallery pick when [pageLimit] is 1.
/// Returns the captured image paths; empty when the user backed out.
/// Throws [DocumentCaptureException] when the scanner itself failed
/// (0.25.0: it used to return empty, which hid denied permissions as
/// cancels in every consumer). Any paywall gate stays app-side.
Future<List<String>> captureDocumentPages(
  DocumentScanService scanner, {
  required int pageLimit,
  ImagePicker? picker,
}) async {
  if (scanner.isSupported) {
    try {
      return await scanner.scanAll(pageLimit: pageLimit);
    } on Exception catch (e) {
      throw DocumentCaptureException(
        e.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''),
      );
    }
  }
  final fallback = picker ?? ImagePicker();
  if (pageLimit == 1) {
    final image = await fallback.pickImage(source: ImageSource.gallery);
    return image == null ? const [] : [image.path];
  }
  final picked = await fallback.pickMultiImage(limit: pageLimit);
  return [for (final image in picked) image.path];
}
