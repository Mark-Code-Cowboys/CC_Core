import 'package:share_plus/share_plus.dart';

import 'share_launcher.dart';

/// The real share sheet, wrapping share_plus — every CC app was
/// carrying this identical wrapper, so the impl (and the dep) moved
/// into core. Tests use [FakeShareLauncher] instead.
class SharePlusLauncher implements ShareLauncher {
  @override
  Future<void> shareFile(String path, {String? mimeType, String? text}) async {
    await SharePlus.instance.share(ShareParams(
      files: [XFile(path, mimeType: mimeType)],
      text: text,
    ));
  }

  @override
  Future<void> shareText(String text,
      {List<String> imagePaths = const []}) async {
    await SharePlus.instance.share(ShareParams(
      text: text,
      files: imagePaths.isEmpty
          ? null
          : [for (final p in imagePaths) XFile(p, mimeType: 'image/jpeg')],
    ));
  }
}
