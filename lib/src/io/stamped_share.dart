import 'dart:io';

import 'share_launcher.dart';

/// "2026-09-05" — the fleet's export-file date stamp.
String dateStamp(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

/// The tail every app's ExportService repeated: write the payload to a
/// date-stamped temp file and hand it to the share sheet. The per-app
/// queries that build [text]/[bytes] stay domain; this owns naming,
/// writing, and sharing. Extracted when four apps carried it verbatim.
///
/// Exactly one of [text] or [bytes]. Returns the written file (mainly
/// for tests).
Future<File> shareStampedFile({
  required ShareLauncher share,
  required Future<Directory> Function() tempDir,
  required String baseName,
  required String extension,
  required String mimeType,
  required String shareText,
  String? text,
  List<int>? bytes,
  DateTime? now,
}) async {
  assert((text == null) != (bytes == null),
      'Exactly one of text or bytes');
  final stamp = dateStamp(now ?? DateTime.now());
  final file =
      File('${(await tempDir()).path}/$baseName-$stamp.$extension');
  if (text != null) {
    await file.writeAsString(text);
  } else {
    await file.writeAsBytes(bytes!);
  }
  await share.shareFile(file.path,
      mimeType: mimeType, text: '$shareText ($stamp)');
  return file;
}
