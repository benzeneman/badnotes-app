import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/pages/editor/editor.dart';

/// Notes and folders the user starred, by path.
///
/// A folder is kept with a trailing slash (`/Physics/`), a notebook without
/// (`/Physics`), so a folder and a notebook with the same name are starred
/// apart.
abstract class Favorites {
  /// The key a starred folder at [path] is kept under.
  static String folderKey(String path) => path.endsWith('/') ? path : '$path/';

  static bool contains(String path) => stows.favoriteNotes.value.contains(path);
  static bool containsFolder(String path) => contains(folderKey(path));

  static void toggle(String path) {
    final favorites = [...stows.favoriteNotes.value];
    if (!favorites.remove(path)) favorites.insert(0, path);
    stows.favoriteNotes.value = favorites;
  }

  static void toggleFolder(String path) => toggle(folderKey(path));

  static void rename(String from, String to) {
    if (!contains(from)) return;
    stows.favoriteNotes.value = [
      for (final path in stows.favoriteNotes.value) path == from ? to : path,
    ];
  }

  /// Moves the star of the folder at [from], and of any starred folder
  /// inside it, over to [to]. Notes inside follow their own files.
  static void renameFolder(String from, String to) {
    final fromKey = folderKey(from), toKey = folderKey(to);
    bool inside(String star) => star.endsWith('/') && star.startsWith(fromKey);
    if (!stows.favoriteNotes.value.any(inside)) return;
    stows.favoriteNotes.value = [
      for (final path in stows.favoriteNotes.value)
        inside(path) ? toKey + path.substring(fromKey.length) : path,
    ];
  }

  /// Forgets the star of the folder at [path] and of any folder inside it.
  static void removeFolder(String path) {
    final key = folderKey(path);
    bool inside(String star) => star.endsWith('/') && star.startsWith(key);
    if (!stows.favoriteNotes.value.any(inside)) return;
    stows.favoriteNotes.value = [
      for (final path in stows.favoriteNotes.value)
        if (!inside(path)) path,
    ];
  }

  static void remove(String path) {
    if (!contains(path)) return;
    stows.favoriteNotes.value = [...stows.favoriteNotes.value]..remove(path);
  }

  /// Older versions starred folders without the slash, sharing keys with
  /// notebooks of the same name. Moves each such star that is only a folder
  /// over to its folder key; one that is also a notebook stays the
  /// notebook's.
  static Future<void> upgradeFolderStars() async {
    await stows.favoriteNotes.waitUntilRead();
    final old = stows.favoriteNotes.value;
    final upgraded = [
      for (final path in old)
        !path.endsWith('/') &&
                FileManager.isDirectory(path) &&
                !FileManager.doesFileExist(path + Editor.extension) &&
                !FileManager.doesFileExist(path + Editor.extensionOldJson)
            ? folderKey(path)
            : path,
    ];
    for (var i = 0; i < old.length; i++) {
      if (old[i] == upgraded[i]) continue;
      stows.favoriteNotes.value = upgraded;
      return;
    }
  }
}
