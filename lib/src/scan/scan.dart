/// scan module of cc_core: on-device photo transcription — document
/// capture, OCR, and the plugin-free types parsers build on.
///
/// GUARDRAIL: everything in this module is read-only *transcription*.
/// Parsers turn recognized text into an app's fields and the user
/// confirms every value before anything is saved; nothing here (or in
/// any confirm/review UI built on it) may suggest, correct, or flag
/// values the camera didn't see.
library;

export 'document_scan_service.dart';
export 'fake_document_scan_service.dart';
export 'mlkit_document_scan_service.dart';
export 'mlkit_text_recognition_service.dart';
export 'ocr_types.dart';
export 'text_recognition_service.dart';
