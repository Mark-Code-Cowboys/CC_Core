/// On-device document capture with automatic edge cropping, deskew, and
/// shadow cleanup, in front of OCR. Nothing leaves the phone. Screens
/// fall back to a plain camera/gallery picker when [isSupported] is
/// false or [scan] throws. Extracted from Table Encore.
abstract class DocumentScanService {
  /// Whether a scanner implementation exists on this platform.
  bool get isSupported;

  /// Launches the scanner UI for a single page. Returns the captured
  /// image's transient file path, or null if the user cancelled.
  Future<String?> scan();

  /// Launches the scanner UI for up to [pageLimit] pages (the shoebox
  /// flow: shoot a stack of pages in one session). Returns the captured
  /// images' transient file paths; empty if the user cancelled.
  Future<List<String>> scanAll({int pageLimit = 20});

  /// Releases platform resources.
  void dispose() {}
}

/// Default for platforms (and tests) without a scanner implementation.
class UnsupportedDocumentScanService implements DocumentScanService {
  /// Const so it can be a provider default.
  const UnsupportedDocumentScanService();

  @override
  bool get isSupported => false;

  @override
  Future<String?> scan() async => null;

  @override
  Future<List<String>> scanAll({int pageLimit = 20}) async => const [];

  @override
  void dispose() {}
}
