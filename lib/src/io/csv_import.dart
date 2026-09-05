/// A parsed CSV file: the header row (empty when the file was empty)
/// and every following row, unpadded — short rows stay short, so
/// mappers must use [rowCell].
class CsvDocument {
  /// Creates the document.
  const CsvDocument({required this.header, required this.rows});

  /// The first row of the file.
  final List<String> header;

  /// Every row after the header.
  final List<List<String>> rows;

  /// [row]'s cell under header column [column], or null when the row is
  /// shorter than that or the cell is blank.
  String? rowCell(List<String> row, int column) {
    if (column < 0 || column >= row.length) return null;
    final cell = row[column].trim();
    return cell.isEmpty ? null : cell;
  }
}

/// Parses RFC 4180 CSV: quoted fields, `""` escapes, commas and line
/// breaks inside quotes, CRLF or LF row endings. The first row becomes
/// the header. For the import-mapper flows ("spreadsheet keepers"), so
/// it is forgiving: a trailing newline or short rows are fine, and a
/// stray quote starts a quoted run rather than throwing.
CsvDocument parseCsv(String text) {
  final rows = <List<String>>[];
  var row = <String>[];
  final cell = StringBuffer();
  var inQuotes = false;
  var i = 0;

  void endCell() {
    row.add(cell.toString());
    cell.clear();
  }

  void endRow() {
    endCell();
    rows.add(row);
    row = <String>[];
  }

  while (i < text.length) {
    final c = text[i];
    if (inQuotes) {
      if (c == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        cell.write(c);
      }
    } else if (c == '"') {
      inQuotes = true;
    } else if (c == ',') {
      endCell();
    } else if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') {
      endRow();
      i++;
    } else if (c == '\n' || c == '\r') {
      endRow();
    } else {
      cell.write(c);
    }
    i++;
  }
  // Flush the last cell unless the file ended cleanly on a newline.
  if (cell.isNotEmpty || row.isNotEmpty) endRow();

  if (rows.isEmpty) return const CsvDocument(header: [], rows: []);
  return CsvDocument(header: rows.first, rows: rows.sublist(1));
}
