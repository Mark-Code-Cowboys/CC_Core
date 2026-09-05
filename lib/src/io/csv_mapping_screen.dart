import 'package:flutter/material.dart';

import 'csv_import.dart';

/// One app field a CSV column can feed, for [CsvMappingScreen].
class CsvField {
  /// Creates the field descriptor.
  const CsvField(
    this.key, {
    required this.label,
    this.isRequired = false,
    this.guessTiers = const [],
  });

  /// Stable key the mapping is returned under.
  final String key;

  /// Picker label ("Course name (required)").
  final String label;

  /// Whether import stays disabled until this field has a column.
  final bool isRequired;

  /// Header-word tiers for [guessCsvMapping], tried in order: the first
  /// tier with a matching column wins ([['course','club'],['name']]).
  final List<List<String>> guessTiers;
}

/// Guesses which column feeds which field from header wording — the
/// user adjusts on the mapping screen. Case-insensitive substring
/// match, per-field tiers via [CsvField.guessTiers].
Map<String, int?> guessCsvMapping(List<String> header, List<CsvField> fields) {
  int? find(List<String> words) {
    for (var i = 0; i < header.length; i++) {
      final h = header[i].toLowerCase();
      if (words.any(h.contains)) return i;
    }
    return null;
  }

  return {
    for (final field in fields)
      field.key: field.guessTiers
          .map(find)
          .firstWhere((i) => i != null, orElse: () => null),
  };
}

/// Pushes the column-mapping screen as a fullscreen dialog.
Future<void> showCsvMappingScreen(
  BuildContext context, {
  required CsvDocument doc,
  required List<CsvField> fields,
  required String title,
  String? footnote,
  required Future<String> Function(Map<String, int?> mapping) onImport,
}) {
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => CsvMappingScreen(
        doc: doc,
        fields: fields,
        title: title,
        footnote: footnote,
        onImport: onImport,
      ),
    ),
  );
}

/// The generic column mapper for the "spreadsheet keeper" import flows:
/// one dropdown per app field over the file's header columns, guesses
/// prefilled, and an import button enabled once every required field
/// has a column. Extracted from Course Ledger when Hitch Post became
/// the second app to need one.
class CsvMappingScreen extends StatefulWidget {
  /// Creates the screen; prefer [showCsvMappingScreen].
  const CsvMappingScreen({
    super.key,
    required this.doc,
    required this.fields,
    required this.title,
    this.footnote,
    required this.onImport,
  });

  /// The parsed file being imported.
  final CsvDocument doc;

  /// The app fields on offer, in display order.
  final List<CsvField> fields;

  /// App bar title ("Import spreadsheet").
  final String title;

  /// Fine print under the pickers ("Rows without a name are skipped.").
  final String? footnote;

  /// Runs the import with the chosen columns (field key -> column
  /// index, null = unmapped). The returned summary is shown as a
  /// snackbar and the screen pops.
  final Future<String> Function(Map<String, int?> mapping) onImport;

  @override
  State<CsvMappingScreen> createState() => _CsvMappingScreenState();
}

class _CsvMappingScreenState extends State<CsvMappingScreen> {
  late final Map<String, int?> _mapping =
      guessCsvMapping(widget.doc.header, widget.fields);
  var _importing = false;

  bool get _ready =>
      widget.fields.every((f) => !f.isRequired || _mapping[f.key] != null);

  Future<void> _import() async {
    if (_importing) return;
    setState(() => _importing = true);
    final messenger = ScaffoldMessenger.of(context);
    final summary = await widget.onImport(Map.unmodifiable(_mapping));
    messenger.showSnackBar(SnackBar(content: Text(summary)));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rowWord = widget.doc.rows.length == 1 ? 'row' : 'rows';
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${widget.doc.rows.length} $rowWord found. Match your '
              'columns:'),
          const SizedBox(height: 16),
          for (final field in widget.fields)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<int?>(
                initialValue: _mapping[field.key],
                decoration: InputDecoration(labelText: field.label),
                items: [
                  const DropdownMenuItem(value: null, child: Text('—')),
                  for (var i = 0; i < widget.doc.header.length; i++)
                    DropdownMenuItem(
                        value: i, child: Text(widget.doc.header[i])),
                ],
                onChanged: (i) => setState(() => _mapping[field.key] = i),
              ),
            ),
          if (widget.footnote != null) ...[
            const SizedBox(height: 8),
            Text(
              widget.footnote!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: !_ready || _importing ? null : _import,
            icon: const Icon(Icons.download_done),
            label: Text(_importing ? 'Importing…' : 'Import'),
          ),
        ],
      ),
    );
  }
}
