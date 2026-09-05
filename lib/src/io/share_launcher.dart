/// Hands content to the platform share sheet. Abstract and plugin-free
/// so widget tests stay plugin-free; apps wrap share_plus (see Table
/// Encore's `SharePlusLauncher`). Extracted from Table Encore.
abstract class ShareLauncher {
  /// Shares the file at [path].
  Future<void> shareFile(String path, {String? mimeType, String? text});

  /// Shares [text], optionally with image attachments.
  Future<void> shareText(String text, {List<String> imagePaths = const []});
}

/// Records calls for tests.
class FakeShareLauncher implements ShareLauncher {
  /// Paths passed to [shareFile].
  final sharedFiles = <String>[];

  /// Texts passed to [shareText].
  final sharedTexts = <String>[];

  @override
  Future<void> shareFile(String path, {String? mimeType, String? text}) async {
    sharedFiles.add(path);
  }

  @override
  Future<void> shareText(String text,
      {List<String> imagePaths = const []}) async {
    sharedTexts.add(text);
  }
}
