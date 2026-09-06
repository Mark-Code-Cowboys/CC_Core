import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../journal/photo_store.dart';
import 'backup_archive.dart';

/// The restore flow every app repeated: pick a .zip, confirm the
/// replace in the app's own words, read the archive, hand the export
/// data to the app's [restore], put the photo files back, report.
/// Extracted when four apps carried it near-verbatim.
///
/// [restore] owns everything app-shaped — restoreFromExportData and
/// any tally raise. Restoring is never gated; callers wire this into
/// free-tier screens too. [pickFile] is injectable for tests only.
Future<void> runRestoreFlow(
  BuildContext context, {
  required String confirmBody,
  required Future<void> Function(BackupContents contents) restore,
  required PhotoService photoStore,
  Future<XFile?> Function()? pickFile,
}) async {
  final picked = await (pickFile ?? _pickZip)();
  if (picked == null || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Restore this backup?'),
      content: Text(confirmBody),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Restore')),
      ],
    ),
  );
  if (confirmed != true) return;

  try {
    // XFile's own reader: works with Android content URIs, and lets
    // tests inject XFile.fromData with no disk IO.
    final contents = readBackupArchive(await picked.readAsBytes());
    await restore(contents);
    // Photo files ride along in the archive; put them back in the store.
    for (final entry in contents.media.entries) {
      await photoStore.importBytes(entry.key, entry.value);
    }
    messenger
        .showSnackBar(const SnackBar(content: Text('Backup restored.')));
  } on InvalidBackupException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  } on Exception catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Restore failed: $e')));
  }
}

Future<XFile?> _pickZip() {
  const typeGroup = XTypeGroup(label: 'Backup', extensions: ['zip']);
  return openFile(acceptedTypeGroups: const [typeGroup]);
}
