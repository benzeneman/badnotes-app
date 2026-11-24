import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Pictures put into notes lately, newest first, to put in again from the
/// Images panel. Kept as files in the app's own folder: at most [_kept] of
/// them, each up to [_largest] bytes.
abstract final class RecentImages {
  static const _kept = 24;
  static const _largest = 6 * 1024 * 1024;
  static const _extensions = {'.png', '.jpg', '.jpeg', '.webp', '.gif', '.bmp'};

  static Future<Directory> _folder() async {
    final support = await getApplicationSupportDirectory();
    return Directory('${support.path}/recent_images').create(recursive: true);
  }

  /// The recent pictures, newest first.
  static Future<List<File>> list() async {
    try {
      final folder = await _folder();
      final files = [
        for (final entity in folder.listSync())
          if (entity is File) entity,
      ];
      files.sort((a, b) => b.path.compareTo(a.path));
      return files;
    } catch (_) {
      return const [];
    }
  }

  /// Keeps [bytes] (a picture of [extension]) as the newest recent one.
  static Future<void> add(Uint8List bytes, String extension) async {
    final ext = extension.toLowerCase();
    if (!_extensions.contains(ext) || bytes.length > _largest) return;
    try {
      final folder = await _folder();
      final files = await list();
      // the same picture again only moves to the front
      for (final file in files) {
        if (file.lengthSync() == bytes.length) {
          final old = await file.readAsBytes();
          if (_same(old, bytes)) await file.delete();
        }
      }
      final name = DateTime.now().microsecondsSinceEpoch
          .toString()
          .padLeft(20, '0');
      await File('${folder.path}/$name$ext').writeAsBytes(bytes);
      final now = await list();
      for (final file in now.skip(_kept)) {
        await file.delete();
      }
    } catch (_) {
      // only a convenience: putting the picture in still worked
    }
  }

  static bool _same(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i += 97) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
