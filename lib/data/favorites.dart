import 'package:badnotes/data/prefs.dart';

/// Notes the user starred, by path.
abstract class Favorites {
  static bool contains(String path) => stows.favoriteNotes.value.contains(path);

  static void toggle(String path) {
    final favorites = [...stows.favoriteNotes.value];
    if (!favorites.remove(path)) favorites.insert(0, path);
    stows.favoriteNotes.value = favorites;
  }

  static void rename(String from, String to) {
    if (!contains(from)) return;
    stows.favoriteNotes.value = [
      for (final path in stows.favoriteNotes.value) path == from ? to : path,
    ];
  }

  static void remove(String path) {
    if (!contains(path)) return;
    stows.favoriteNotes.value = [...stows.favoriteNotes.value]..remove(path);
  }
}
