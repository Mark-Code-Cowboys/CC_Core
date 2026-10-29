/// Sorting OCR'd lines with the on-device model as a LABELING task:
/// the model sees the lines numbered and answers one label per line
/// from an alphabet the app defines, plus an optional reading. The
/// app then builds its record from the ORIGINAL lines — the model can
/// reorganise, never invent text, which keeps the scan module's
/// transcription guardrail intact. Extracted from Trace Elements'
/// recipe-card import; any notebook/card/receipt page sorts the same
/// way.
library;

import 'text_model.dart';

/// One label the model may answer with: a single letter and what it
/// means.
class LineLabelSpec {
  /// A label [code] (one upper-case letter) and its [description].
  const LineLabelSpec(this.code, this.description, {this.allowReading = false});

  /// One upper-case letter.
  final String code;

  /// What the label means, as shown to the model.
  final String description;

  /// Whether the model may append `=> reading` to this label (a
  /// cleaned-up version of the line, e.g. OCR fixes).
  final bool allowReading;
}

/// An input line with the label the model gave it.
class LabeledLine {
  /// A line with its label.
  const LabeledLine(this.text, this.code, {this.reading});

  /// The original OCR line, untouched.
  final String text;

  /// The label code, or [LineLabeler.otherCode] when unlabeled.
  final String code;

  /// The model's reading of the line when the label allows one.
  final String? reading;
}

/// Every input line, labeled, in order.
class LabeledLines {
  /// All lines in order.
  const LabeledLines(this.lines);

  /// One entry per input line, in order.
  final List<LabeledLine> lines;

  /// Lines carrying [code].
  Iterable<LabeledLine> withCode(String code) =>
      lines.where((l) => l.code == code);
}

/// Numbered, trimmed, non-empty lines from OCR text.
List<String> numberedLines(String text) => text
    .replaceAll('\r', '')
    .split('\n')
    .map((l) => l.trim())
    .where((l) => l.isNotEmpty)
    .toList();

/// Runs the labeling task for one kind of page.
class LineLabeler {
  /// A labeler for one kind of page. [otherCode] must be in [labels].
  LineLabeler({
    required this.model,
    required this.task,
    required this.labels,
    this.readingInstructions = '',
    this.otherCode = 'X',
  }) : assert(labels.every((l) => RegExp(r'^[A-Z]$').hasMatch(l.code)));

  /// The phone model that answers.
  final OnDeviceTextModel model;

  /// One phrase on what the page is ("the lines of a scanned recipe
  /// card").
  final String task;

  /// The label alphabet, in the order shown to the model.
  final List<LineLabelSpec> labels;

  /// What a reading may do, when any label allows one.
  final String readingInstructions;

  /// The label for "anything else"; must be in [labels].
  final String otherCode;

  /// The prompt for [lines]: the task, the alphabet, the numbered lines.
  String buildPrompt(List<String> lines) {
    final b = StringBuffer()
      ..writeln('You are sorting $task. The text came from OCR and may')
      ..writeln('contain misreads. For EVERY numbered line below, answer')
      ..writeln('with exactly one line of the form')
      ..writeln('  <number>: <LABEL>')
      ..writeln('where LABEL is one of');
    for (final l in labels) {
      b.writeln('  ${l.code}  ${l.description}');
    }
    if (labels.any((l) => l.allowReading)) {
      final codes = labels.where((l) => l.allowReading).map((l) => l.code);
      b.writeln(
        'For ${codes.join('/')} lines you MAY add a reading after " => ":',
      );
      if (readingInstructions.isNotEmpty) b.writeln(readingInstructions);
      b.writeln('Do not add content that is not there.');
    }
    b
      ..writeln('Output only the numbered answers, nothing else.')
      ..writeln()
      ..writeln('LINES');
    for (var i = 0; i < lines.length; i++) {
      b.writeln('${i + 1}: ${lines[i]}');
    }
    return b.toString();
  }

  /// Parses an answer against [lines]. Lines the model skipped get
  /// [otherCode]; out-of-range numbers, unknown codes and junk are
  /// ignored.
  LabeledLines parse(String answer, List<String> lines) {
    final known = {for (final l in labels) l.code: l};
    final codes = List<String>.filled(lines.length, otherCode);
    final readings = List<String?>.filled(lines.length, null);
    final re = RegExp(
      r'^\s*(\d{1,3})\s*[:.)-]\s*([A-Za-z])\b\s*(?:=>\s*(.+?))?\s*$',
    );
    for (final raw in answer.replaceAll('\r', '').split('\n')) {
      final line = raw.replaceAll(RegExp(r'^[`*\s]+|[`*\s]+$'), '');
      final m = re.firstMatch(line);
      if (m == null) continue;
      final n = int.parse(m.group(1)!) - 1;
      if (n < 0 || n >= lines.length) continue;
      final code = m.group(2)!.toUpperCase();
      final spec = known[code];
      if (spec == null) continue;
      codes[n] = code;
      // Gemini Nano sometimes chains readings ("I => 1 lb => 1 pound
      // bulk pork sausage"); the last one is the whole line.
      final r = m.group(3)?.split('=>').last.trim();
      if (spec.allowReading && r != null && r.isNotEmpty) readings[n] = r;
    }
    return LabeledLines([
      for (var i = 0; i < lines.length; i++)
        LabeledLine(lines[i], codes[i], reading: readings[i]),
    ]);
  }

  /// Worth using: at least one line carries [requiredCode] and most
  /// lines got a label.
  bool isUsable(LabeledLines labeled, {required String requiredCode}) =>
      labeled.lines.any((l) => l.code == requiredCode) &&
      labeled.lines.where((l) => l.code != otherCode).length * 2 >=
          labeled.lines.length;

  /// Runs the model over [text]; null when the model is unavailable,
  /// failed, or its answer is unusable.
  Future<LabeledLines?> label(
    String text, {
    required String requiredCode,
  }) async {
    final lines = numberedLines(text);
    if (lines.isEmpty) return null;
    if (!await model.isAvailable()) return null;
    final String? answer;
    try {
      answer = await model.generate(buildPrompt(lines));
    } on OnDeviceModelException {
      return null;
    }
    if (answer == null || answer.trim().isEmpty) return null;
    final labeled = parse(answer, lines);
    return isUsable(labeled, requiredCode: requiredCode) ? labeled : null;
  }
}
