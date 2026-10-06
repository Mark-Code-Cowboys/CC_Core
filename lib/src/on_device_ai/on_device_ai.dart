/// on_device_ai module of cc_core: the phone's own language model
/// (Gemini Nano / Apple Foundation Models) behind one seam, and the
/// line-labeling pattern for sorting OCR text without letting the
/// model invent any. Dart side + fakes; the native halves are
/// reference code in doc/on_device_ai.md.
library;

export 'line_labeler.dart';
export 'text_model.dart';
