import 'package:image_picker/image_picker.dart';

import 'document_scan_service.dart';

/// The capture preamble every import flow shares: the document scanner
/// (auto-crop/deskew) where supported, otherwise the photo picker —
/// multi-select for a batch, single gallery pick when [pageLimit] is 1.
/// Returns the captured image paths; empty when the user backed out or
/// the scanner threw. Extracted from three identical call sites
/// (shoebox, notebook, receipt). Any paywall gate stays app-side.
Future<List<String>> captureDocumentPages(
  DocumentScanService scanner, {
  required int pageLimit,
  ImagePicker? picker,
}) async {
  if (scanner.isSupported) {
    try {
      return await scanner.scanAll(pageLimit: pageLimit);
    } on Exception {
      return const [];
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
