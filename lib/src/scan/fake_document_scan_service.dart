import 'document_scan_service.dart';

/// Canned capture for tests: always supported, returns [paths].
class FakeDocumentScanService implements DocumentScanService {
  /// Creates the fake returning [paths] from capture calls.
  FakeDocumentScanService(this.paths);

  /// The image paths a capture session "shoots".
  final List<String> paths;

  @override
  bool get isSupported => true;

  @override
  Future<String?> scan() async => paths.isEmpty ? null : paths.first;

  @override
  Future<List<String>> scanAll({int pageLimit = 20}) async =>
      paths.take(pageLimit).toList();

  @override
  void dispose() {}
}
