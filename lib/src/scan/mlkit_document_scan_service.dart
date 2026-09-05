import 'dart:io';

import 'package:flutter/services.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

import 'document_scan_service.dart';

/// ML Kit's document scanner. Android-only: the scanner ships via Google
/// Play services and processes images on-device. Extracted from Table
/// Encore, with multi-page capture added for the batch import flow.
class MlKitDocumentScanService implements DocumentScanService {
  DocumentScanner? _scanner;

  DocumentScanner _open(int pageLimit) {
    _scanner?.close();
    return _scanner = DocumentScanner(
      options: DocumentScannerOptions(
        pageLimit: pageLimit,
        isGalleryImport: true,
        mode: ScannerMode.full,
      ),
    );
  }

  @override
  bool get isSupported => Platform.isAndroid;

  @override
  Future<String?> scan() async {
    final images = await _scanPages(1);
    return images.isEmpty ? null : images.first;
  }

  @override
  Future<List<String>> scanAll({int pageLimit = 20}) =>
      _scanPages(pageLimit);

  Future<List<String>> _scanPages(int pageLimit) async {
    try {
      final result = await _open(pageLimit).scanDocument();
      return result.images ?? const [];
    } on PlatformException catch (e) {
      // The plugin reports backing out of the scanner as an error.
      if ((e.message ?? '').toLowerCase().contains('cancelled')) {
        return const [];
      }
      rethrow;
    }
  }

  @override
  void dispose() {
    _scanner?.close();
  }
}
