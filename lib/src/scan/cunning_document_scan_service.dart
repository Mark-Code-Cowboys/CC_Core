import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';

import 'document_scan_service.dart';

/// The platform document camera — automatic edge detection, perspective
/// correction, on-device — behind the [DocumentScanService] seam, via
/// cunning_document_scanner: Apple VisionKit on iOS, Google ML Kit
/// (with the plugin's own cropper when Play services are missing) on
/// Android.
///
/// One plugin for both platforms on purpose. 0.22.0 paired this
/// plugin (iOS) with google_mlkit_document_scanner (Android), and both
/// register an Android activity-result listener on the same request
/// code (0x362738). Flutter hands every result to every listener, so
/// when the Google plugin's scan came back, this plugin moved the page
/// image into its own storage and the path the Google plugin returned
/// pointed at nothing: every Android scan failed with 'Couldn't read
/// that image'. Reproduced on the Pixel 7 emulator (API 36) from a
/// Table Encore receipt; fixed by having only one scanner plugin in the
/// app.
///
/// Backing out of the camera returns nothing; a denied camera
/// permission throws, and callers fall back to the picker.
class CunningDocumentScanService implements DocumentScanService {
  /// Const so it can be a provider default.
  const CunningDocumentScanService();

  @override
  bool get isSupported => Platform.isAndroid || Platform.isIOS;

  @override
  Future<String?> scan() async {
    final images = await scanAll(pageLimit: 1);
    return images.isEmpty ? null : images.first;
  }

  @override
  Future<List<String>> scanAll({int pageLimit = 20}) async {
    final images = await CunningDocumentScanner.getPictures(
      noOfPages: pageLimit,
      // Camera or an existing photo, chosen from a system sheet.
      scannerSource: ScannerSource.cameraAndGallery,
      // Full: capture, crop, filters — what the ML Kit service offered.
      androidScannerMode: AndroidScannerMode.full,
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

/// 0.22.0 name for the iOS-only version of [CunningDocumentScanService].
@Deprecated('Use CunningDocumentScanService; it covers Android too')
typedef VisionKitDocumentScanService = CunningDocumentScanService;
