import 'dart:async';
import 'dart:convert';

import 'package:badnotes/components/home/home_actions.dart';
import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/ui/bn_icons.dart';
import 'package:badnotes/data/favorites.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/pages/editor/editor.dart';
import 'package:flutter/material.dart';

/// A note in the trash: where it is, where it was, and when it went.
class TrashEntry {
  const new({
    required this.trashPath,
    required this.originalPath,
    required this.deletedAt,
  });

  /// e.g. `/.trash/1763740000000 Physics`, without the extension.
  final String trashPath;

  /// e.g. `/College/Physics`.
  final String originalPath;
  final DateTime deletedAt;

  String get name => noteName(originalPath);

  /// When it's deleted for good.
  DateTime get expires => deletedAt.add(Trash.keptFor);

  Map<String, dynamic> toJson() => {
    'trashPath': trashPath,
    'originalPath': originalPath,
    'deletedAt': deletedAt.millisecondsSinceEpoch,
  };

  static TrashEntry? fromJson(Object? json) {
    if (json is! Map) return null;
    final trash = json['trashPath'], original = json['originalPath'];
    final at = json['deletedAt'];
    if (trash is! String || original is! String || at is! int) return null;
    return TrashEntry(
      trashPath: trash,
      originalPath: original,
      deletedAt: DateTime.fromMillisecondsSinceEpoch(at),
    );
  }
}

/// Deleted notes, kept for [keptFor] in `/.trash/` (design §7.3, N20). The
/// note moves there with its pictures, cover and recordings, and the list
/// of what's there is `/.trash/index.json`; both sync like notes.
abstract final class Trash {
  static const dir = '/.trash';
  static const _index = '$dir/index.json';
  static const keptFor = Duration(days: 30);

  /// What's in the trash, newest first; empty until read.
  static final entries = ValueNotifier<List<TrashEntry>>(const []);
  static var _loaded = false;

  /// Reads the trash's list, once.
  static Future<List<TrashEntry>> load() async {
    if (_loaded) return entries.value;
    _loaded = true;
    if (!FileManager.doesFileExist(_index)) return entries.value;
    final bytes = await FileManager.readFile(_index, retries: 0);
    if (bytes == null) return entries.value;
    try {
      final list = jsonDecode(utf8.decode(bytes)) as List;
      entries.value = [
        for (final item in list)
          ?TrashEntry.fromJson(item),
      ]..sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
    } on FormatException {
      // a broken list: what's in the folder stays, and is cleaned up later
    }
    return entries.value;
  }

  static Future<void> _save() => FileManager.writeFile(
    _index,
    utf8.encode(jsonEncode([for (final e in entries.value) e.toJson()])),
  );

  static String _extensionOf(String path) =>
      FileManager.doesFileExist(path + Editor.extensionOldJson)
      ? Editor.extensionOldJson
      : Editor.extension;

  /// Moves the notes at [paths] to the trash. The screen updates at once;
  /// the files move right after.
  static Future<List<TrashEntry>> moveToTrash(List<String> paths) async {
    await load();
    final now = DateTime.now();
    final moved = <TrashEntry>[];
    for (final path in paths) {
      final extension = _extensionOf(path);
      final target = await FileManager.moveFile(
        path + extension,
        '$dir/${now.millisecondsSinceEpoch} ${noteName(path)}$extension',
      );
      Favorites.remove(path);
      moved.add(
        TrashEntry(
          trashPath: target.substring(0, target.length - extension.length),
          originalPath: path,
          deletedAt: now,
        ),
      );
    }
    entries.value = [...moved, ...entries.value];
    await _save();
    return moved;
  }

  /// The notes in [folder] (e.g. `/College`) and its subfolders, without
  /// extensions.
  static Future<List<String>> notesIn(String folder) async {
    final children = await FileManager.getChildrenOfDirectory(folder);
    if (children == null) return [];
    return [
      for (final file in children.files) '$folder/$file',
      for (final sub in children.directories) ...await notesIn('$folder/$sub'),
    ];
  }

  /// Moves every note in [folder] to the trash, then removes the folder.
  /// Restoring a note brings its folder back.
  static Future<List<TrashEntry>> moveFolderToTrash(String folder) async {
    final moved = await moveToTrash(await notesIn(folder));
    // a note that didn't move keeps its folder
    if ((await notesIn(folder)).isEmpty) {
      await FileManager.deleteDirectory(folder);
    }
    return moved;
  }

  /// Puts [entry] back where it was (beside it, if that name is taken now).
  static Future<String> restore(TrashEntry entry) async {
    final extension = _extensionOf(entry.trashPath);
    final target = await FileManager.suffixFilePathToMakeItUnique(
      entry.originalPath,
      intendedExtension: extension,
    );
    await FileManager.moveFile(
      entry.trashPath + extension,
      target + extension,
    );
    entries.value = [...entries.value]..remove(entry);
    await _save();
    return target;
  }

  /// Deletes [entry] for good.
  static Future<void> deleteForever(TrashEntry entry) async {
    entries.value = [...entries.value]..remove(entry);
    await FileManager.deleteFile(entry.trashPath + _extensionOf(entry.trashPath));
    await _save();
  }

  /// Deletes everything in the trash for good.
  static Future<void> empty() async {
    final all = entries.value;
    entries.value = const [];
    for (final entry in all) {
      await FileManager.deleteFile(
        entry.trashPath + _extensionOf(entry.trashPath),
      );
    }
    await _save();
  }

  /// Deletes for good what's been in the trash longer than [keptFor]; run
  /// in the background when the app starts.
  static Future<void> purgeOld() async {
    await load();
    final now = DateTime.now();
    final old = entries.value.where((e) => now.isAfter(e.expires)).toList();
    if (old.isEmpty) return;
    for (final entry in old) {
      await FileManager.deleteFile(
        entry.trashPath + _extensionOf(entry.trashPath),
      );
    }
    entries.value = [
      for (final e in entries.value)
        if (!old.contains(e)) e,
    ];
    await _save();
  }
}

/// Moves [paths] to the trash and shows "Moved to Trash · Undo" for 5 s.
/// Take [overlay] (`Overlay.maybeOf(context, rootOverlay: true)`) before
/// closing a dialog: its context is gone after.
Future<void> moveToTrashWithUndo(
  OverlayState? overlay,
  List<String> paths,
) async {
  final moved = await Trash.moveToTrash(paths);
  if (moved.isEmpty) return;
  showBannerOn(
    overlay,
    moved.length == 1
        ? 'Moved to Trash'
        : '${moved.length} notes moved to Trash',
    subtitle: 'Kept for 30 days',
    kind: BannerKind.error,
    icon: BnIcons.trash,
    actionLabel: 'Undo',
    onAction: () {
      for (final entry in moved) {
        unawaited(Trash.restore(entry));
      }
    },
  );
}
