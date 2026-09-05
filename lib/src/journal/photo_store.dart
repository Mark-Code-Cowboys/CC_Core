import 'dart:io';

import 'package:image_picker/image_picker.dart';

/// Where a photo comes from.
enum PhotoSource {
  /// The device camera.
  camera,

  /// The photo library.
  gallery,
}

/// The slice of photo storage the data layer needs: deleting a stored
/// file when its row goes away. Kept separate so repositories don't
/// depend on the picker plugin. Extracted from Table Encore.
abstract class PhotoFileStore {
  /// Deletes the stored file for [photoPath]; missing files are fine.
  Future<void> discard(String photoPath);
}

/// Captures/picks photos and owns their files. Journal photo rows hold
/// only the file name; the service maps it to a file under the app's
/// photos directory, so paths stay valid if the OS relocates the app
/// container (iOS does this between updates). Extracted from Table
/// Encore with the file-name prefix injected.
abstract class PhotoService implements PhotoFileStore {
  /// Lets the user take or choose a photo and copies it into permanent
  /// app storage. Returns the stored photoPath value, or null if the
  /// user cancelled.
  Future<String?> acquire(PhotoSource source);

  /// Like [acquire] but nothing is copied: returns the picker's own
  /// transient file path (or null). For one-shot uses like OCR.
  Future<String?> acquireTransient(PhotoSource source);

  /// Absolute file for a stored photoPath value.
  File fileFor(String photoPath);

  /// Writes [bytes] as the stored file for [photoPath] (backup restore).
  Future<void> importBytes(String photoPath, List<int> bytes);
}

/// The real store over image_picker and an app documents subdirectory.
class ImagePickerPhotoService implements PhotoService {
  /// Creates the service storing files in [photosDir] (create it in
  /// main()), named `<filePrefix>_<millis><ext>`.
  ImagePickerPhotoService(this._photosDir, {this.filePrefix = 'photo'});

  final Directory _photosDir;

  /// File-name prefix ("dish", "round").
  final String filePrefix;

  final _picker = ImagePicker();

  Future<XFile?> _pick(PhotoSource source) {
    return _picker.pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );
  }

  @override
  Future<String?> acquireTransient(PhotoSource source) async =>
      (await _pick(source))?.path;

  @override
  Future<String?> acquire(PhotoSource source) async {
    final picked = await _pick(source);
    if (picked == null) return null;

    final dot = picked.name.lastIndexOf('.');
    final extension = dot == -1 ? '.jpg' : picked.name.substring(dot);
    final name =
        '${filePrefix}_${DateTime.now().millisecondsSinceEpoch}$extension';
    await picked.saveTo('${_photosDir.path}/$name');
    return name;
  }

  @override
  File fileFor(String photoPath) => File('${_photosDir.path}/$photoPath');

  @override
  Future<void> importBytes(String photoPath, List<int> bytes) async {
    await fileFor(photoPath).writeAsBytes(bytes, flush: true);
  }

  @override
  Future<void> discard(String photoPath) async {
    final file = fileFor(photoPath);
    if (file.existsSync()) await file.delete();
  }
}

/// Test fake: records discards, stores bytes in memory, serves files
/// from a temp mapping.
class FakePhotoFileStore implements PhotoFileStore {
  /// Paths passed to [discard].
  final discarded = <String>[];

  @override
  Future<void> discard(String photoPath) async {
    discarded.add(photoPath);
  }
}
