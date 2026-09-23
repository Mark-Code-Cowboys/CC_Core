import 'dart:io';

import 'cunning_document_scan_service.dart';
import 'document_scan_service.dart';

/// The document scanner for the running platform: the platform document
/// camera on Android and iOS, the unsupported stub elsewhere (screens
/// then fall back to the camera/gallery picker). For an app's main()
/// wiring.
DocumentScanService platformDocumentScanService() {
  if (Platform.isAndroid || Platform.isIOS) {
    return const CunningDocumentScanService();
  }
  return const UnsupportedDocumentScanService();
}
