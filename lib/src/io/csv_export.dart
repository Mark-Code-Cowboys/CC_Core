/// Encodes rows as RFC 4180 CSV — the inverse of `parseCsv`. Cells are
/// quoted only when they contain commas, quotes, or line breaks; null
/// cells become empty. Rows end with `\r\n` per the RFC so the files
/// open cleanly in every spreadsheet app.
String buildCsv(List<List<Object?>> rows) {
  final buffer = StringBuffer();
  for (final row in rows) {
    buffer
      ..writeAll(row.map(_encodeCell), ',')
      ..write('\r\n');
  }
  return buffer.toString();
}

String _encodeCell(Object? cell) {
  final text = cell?.toString() ?? '';
  if (text.contains(',') ||
      text.contains('"') ||
      text.contains('\n') ||
      text.contains('\r')) {
    return '"${text.replaceAll('"', '""')}"';
  }
  return text;
}
