import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// One backup = one zip: the app's export JSON plus every referenced
/// media file. Pure data in/out — no IO here. Extracted from Table
/// Encore with the entry names parameterized (its backups keep working
/// via `jsonEntry: 'journal.json'`, `mediaPrefix: 'photos/'`).
Uint8List buildBackupArchive({
  required Map<String, Object?> exportData,
  Map<String, List<int>> media = const {},
  String jsonEntry = 'export.json',
  String mediaPrefix = 'media/',
}) {
  final archive = Archive()
    ..add(ArchiveFile.string(jsonEntry, jsonEncode(exportData)));
  media.forEach((name, bytes) {
    archive.add(ArchiveFile.bytes('$mediaPrefix$name', bytes));
  });
  return ZipEncoder().encodeBytes(archive);
}

/// What [readBackupArchive] found in the zip.
class BackupContents {
  /// Creates the contents.
  const BackupContents({required this.exportData, required this.media});

  /// The decoded export JSON.
  final Map<String, Object?> exportData;

  /// media file name -> file bytes.
  final Map<String, List<int>> media;
}

/// Thrown when bytes are not a readable backup of this app.
class InvalidBackupException implements Exception {
  /// Creates the exception with a human-readable reason.
  const InvalidBackupException(this.message);

  /// Why the backup was rejected.
  final String message;

  @override
  String toString() => 'InvalidBackupException: $message';
}

/// Reads a backup produced by [buildBackupArchive]. Media names with
/// path separators or `..` are dropped — archive entries are untrusted.
BackupContents readBackupArchive(
  List<int> bytes, {
  String jsonEntry = 'export.json',
  String mediaPrefix = 'media/',
}) {
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } on Object {
    throw const InvalidBackupException('Not a zip archive');
  }

  Map<String, Object?>? exportData;
  final media = <String, List<int>>{};
  for (final file in archive.files) {
    if (!file.isFile) continue;
    if (file.name == jsonEntry) {
      final decoded = jsonDecode(utf8.decode(file.content));
      if (decoded is! Map<String, dynamic>) {
        throw InvalidBackupException('$jsonEntry is not an object');
      }
      exportData = decoded;
    } else if (file.name.startsWith(mediaPrefix)) {
      final name = file.name.substring(mediaPrefix.length);
      if (name.isNotEmpty && !name.contains('/') && !name.contains('..')) {
        media[name] = file.content;
      }
    }
  }
  if (exportData == null) {
    throw InvalidBackupException('No $jsonEntry in archive');
  }
  return BackupContents(exportData: exportData, media: media);
}
