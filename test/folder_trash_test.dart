import 'dart:convert';

import 'package:badnotes/components/home/trash.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/data/flavor_config.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_mock_channel_handlers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupMockPathProvider();
  FlavorConfig.setup();

  setUpAll(FileManager.init);

  test('a deleted folder\'s notes wait in Trash and come back', () async {
    const folder = '/folder_trash_test';
    for (final note in ['$folder/a', '$folder/inner/b']) {
      await FileManager.writeFile(
        '$note.sbn2',
        utf8.encode(note),
        awaitWrite: true,
      );
    }

    final moved = await Trash.moveFolderToTrash(folder);

    expect(FileManager.isDirectory(folder), isFalse);
    expect(
      moved.map((e) => e.originalPath),
      unorderedEquals(['$folder/a', '$folder/inner/b']),
    );
    for (final entry in moved) {
      expect(Trash.entries.value, contains(entry));
      expect(FileManager.doesFileExist('${entry.trashPath}.sbn2'), isTrue);
    }

    // restoring brings the note back into its (re-made) folder
    final inner = moved.firstWhere((e) => e.originalPath.endsWith('/b'));
    final back = await Trash.restore(inner);
    expect(back, '$folder/inner/b');
    final bytes = await FileManager.readFile('$back.sbn2');
    expect(utf8.decode(bytes!), '$folder/inner/b');

    await FileManager.deleteDirectory(folder);
    for (final entry in moved) {
      if (entry != inner) await Trash.deleteForever(entry);
    }
  });
}
