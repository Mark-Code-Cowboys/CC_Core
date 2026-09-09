import 'dart:io';

import 'document_scan_service.dart';
import 'mlkit_document_scan_service.dart';
import 'visionkit_document_scan_service.dart';

/// The document scanner for the running platform: ML Kit on Android,
/// VisionKit on iOS, the unsupported stub elsewhere (screens then fall
/// back to the camera/gallery picker). For an app's main() wiring.
DocumentScanService platformDocumentScanService() {
  if (Platform.isAndroid) return MlKitDocumentScanService();
  if (Platform.isIOS) return const VisionKitDocumentScanService();
  return const UnsupportedDocumentScanService();
}
