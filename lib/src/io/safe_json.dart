import '../text/html_text.dart';

/// Field readers for a JSON document that came from *another* phone or
/// a file someone sent: length caps, finite non-negative numbers,
/// http(s)-only URLs, markup stripped, script-like content refused.
/// Every failure is a [SafeJsonException] with a user-facing message
/// naming the field. Lifted from Trace Elements' recipe-file import;
/// backup archives and any shared document have the same threat model.

class SafeJsonException implements Exception {
  /// Creates the exception with a user-facing [message].
  const SafeJsonException(this.message);

  /// What to tell the user.
  final String message;

  @override
  String toString() => message;
}

/// Markup that smuggles behaviour rather than formatting.
final safeJsonHostilePattern = RegExp(
  r'<\s*(script|iframe|object|embed|style|svg|img|link|meta)\b'
  r'|javascript\s*:|on\w+\s*=',
  caseSensitive: false,
);

/// A string field: null when absent or blank after cleaning. Numbers
/// are accepted and stringified. Over [max] characters, or carrying
/// script-like content, it throws. Plain tags are stripped and
/// entities decoded.
String? readSafeText(Object? value, String field, {int max = 500}) {
  if (value == null) return null;
  if (value is! String) {
    if (value is num) return value.toString();
    throw SafeJsonException('The "$field" field in this file is malformed.');
  }
  if (value.length > max) {
    throw SafeJsonException('The "$field" field in this file is too long.');
  }
  if (safeJsonHostilePattern.hasMatch(value)) {
    throw const SafeJsonException(
      'This file contains script content and was not opened.',
    );
  }
  final cleaned = stripHtmlInline(value);
  return cleaned.isEmpty ? null : cleaned;
}

/// A finite number within [min]..[max]; null when absent.
double? readSafeNumber(
  Object? value,
  String field, {
  required double max,
  double min = 0,
}) {
  if (value == null) return null;
  if (value is! num || !value.isFinite || value < min || value > max) {
    throw SafeJsonException(
      'The "$field" field in this file is not a valid number.',
    );
  }
  return value.toDouble();
}

/// An http(s) URL as text; null when absent.
String? readSafeHttpUrl(Object? value, String field, {int max = 2000}) {
  final s = readSafeText(value, field, max: max);
  if (s == null) return null;
  final uri = Uri.tryParse(s);
  if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
    throw const SafeJsonException('This file contains an invalid web address.');
  }
  return s;
}

/// A file name safe to write under an app directory: the last path
/// segment with anything but letters, digits, dot, dash and underscore
/// replaced. Never empty.
String safeFileName(String ref, {String fallback = 'file'}) {
  final base = ref
      .split(RegExp(r'[/\\]'))
      .last
      .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  return base.isEmpty || base == '.' || base == '..' ? fallback : base;
}
