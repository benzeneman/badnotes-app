import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:badnotes/components/home/folder_info.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/pages/editor/editor.dart';
import 'package:bson/bson.dart';
import 'package:flutter/foundation.dart';

/// What the home screen shows about a note without opening it: read from
/// the note's file off the UI thread, and kept until the note changes.
@immutable
class NoteFacts {
  const new({
    required this.pages,
    required this.board,
    required this.bookmarks,
    required this.lastPage,
    required this.pdf,
  });

  final int pages;

  /// A whiteboard (one endless sheet) instead of pages.
  final bool board;

  /// The pages bookmarked in the editor, from 0.
  final List<int> bookmarks;

  /// The page the note was left on, from 0.
  final int lastPage;

  /// Made from a PDF (its pages are a PDF's).
  final bool pdf;

  static const _boardSide = 200000.0;

  /// The facts in a note file's [bytes]; null if they can't be read.
  static NoteFacts? read(Uint8List bytes) {
    try {
      final json = BsonCodec.deserialize(BsonBinary.from(bytes));
      final pages = json['z'];
      if (pages is! List) return null;
      final bookmarks = <int>[];
      var board = false, pdf = false;
      for (final (i, page) in pages.indexed) {
        if (page is! Map) continue;
        if (page['fav'] == true) bookmarks.add(i);
        if (i == 0 && (page['w'] as num? ?? 0) >= _boardSide) board = true;
        if (page['b'] case final Map background
            when background['e'] == '.pdf') {
          pdf = true;
        }
      }
      return NoteFacts(
        pages: pages.length,
        board: board,
        bookmarks: bookmarks,
        lastPage: (json['c'] as int? ?? 0).clamp(0, pages.length),
        pdf: pdf,
      );
    } catch (_) {
      return null;
    }
  }
}

/// [NoteFacts] for every note, by path; read in the background, all at
/// once the first time, then only the notes that change.
abstract final class NoteFactsCache {
  static final facts = ValueNotifier<Map<String, NoteFacts>>(const {});
  static final _read = <String, DateTime>{};
  static Future<void>? _scanning;
  static StreamSubscription<FileOperation>? _changes;
  static Timer? _rescan;

  /// Reads the notes not read yet or changed since; call when a screen that
  /// needs the facts opens.
  static Future<void> scan() {
    _changes ??= FileManager.fileWriteStream.stream.listen((event) {
      if (event.isNoteAsset) return;
      _rescan?.cancel();
      _rescan = Timer(const Duration(seconds: 1), () => unawaited(scan()));
    });
    return _scanning ??= _scan().whenComplete(() => _scanning = null);
  }

  static Future<void> _scan() async {
    final paths = [
      for (final f in await FileManager.getAllFiles())
        if (isVisiblePath(f)) f,
    ];
    final root = FileManager.documentsDirectory;
    final extension = Editor.extension;
    final known = Map.of(_read);
    final found = await Isolate.run(() {
      final out = <String, (DateTime, NoteFacts?)>{};
      for (final path in paths) {
        final file = File('$root$path$extension');
        if (!file.existsSync()) continue;
        final modified = file.lastModifiedSync();
        if (known[path] == modified) continue;
        out[path] = (modified, NoteFacts.read(file.readAsBytesSync()));
      }
      return out;
    });
    final next = {
      for (final MapEntry(:key, :value) in facts.value.entries)
        if (paths.contains(key)) key: value,
    };
    for (final MapEntry(key: path, value: (modified, read)) in found.entries) {
      _read[path] = modified;
      if (read != null) next[path] = read;
    }
    _read.removeWhere((path, _) => !paths.contains(path));
    facts.value = next;
  }
}
