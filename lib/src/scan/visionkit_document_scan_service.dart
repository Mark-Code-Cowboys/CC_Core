import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';

import 'document_scan_service.dart';

/// Apple's VisionKit document camera — automatic edge detection,
/// perspective correction, on-device — behind the same seam as the
/// ML Kit scanner. iOS-only. Added when a TestFlight tester's tilted
/// receipt photos (iPhones had only the plain picker) split names
/// from prices. Backing out of the camera returns nothing; a denied
/// camera permission throws, and callers fall back to the picker.
class VisionKitDocumentScanService implements DocumentScanService {
  /// Const so it can be a provider default.
  const VisionKitDocumentScanService();

  @override
  bool get isSupported => Platform.isIOS;

  @override
  Future<String?> scan() async {
    final images = await scanAll(pageLimit: 1);
    return images.isEmpty ? null : images.first;
  }

  @override
  Future<List<String>> scanAll({int pageLimit = 20}) async {
    final images = await CunningDocumentScanner.getPictures(
      noOfPages: pageLimit,
      // Camera or an existing photo, chosen from a system sheet — the
      // same choice the ML Kit scanner offers via isGalleryImport.
      scannerSource: ScannerSource.cameraAndGallery,
      iosScannerOptions: IosScannerOptions(
        imageFormat: IosImageFormat.jpg,
        jpgCompressionQuality: 0.92,
      ),
    );
    return images ?? const [];
  }

  @override
  void dispose() {}
}
