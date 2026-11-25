import 'package:badnotes/data/favorites.dart';
import 'package:badnotes/data/flavor_config.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FlavorConfig.setup();
  test('a folder and a notebook with the same name are starred apart', () {
    stows.favoriteNotes.value = [];

    Favorites.toggleFolder('/Physics'); // the folder
    Favorites.toggle('/Physics'); // a notebook on the desk, same name
    expect(Favorites.containsFolder('/Physics'), isTrue);
    expect(Favorites.contains('/Physics'), isTrue);

    Favorites.toggle('/Physics');
    expect(Favorites.contains('/Physics'), isFalse);
    expect(Favorites.containsFolder('/Physics'), isTrue);

    Favorites.toggle('/Physics');
    Favorites.toggleFolder('/Physics');
    expect(Favorites.containsFolder('/Physics'), isFalse);
    expect(Favorites.contains('/Physics'), isTrue);

    // renaming the folder leaves the notebook's star alone
    Favorites.toggleFolder('/Physics');
    Favorites.renameFolder('/Physics', '/Science');
    expect(Favorites.containsFolder('/Science'), isTrue);
    expect(Favorites.containsFolder('/Physics'), isFalse);
    expect(Favorites.contains('/Physics'), isTrue);
  });
}
