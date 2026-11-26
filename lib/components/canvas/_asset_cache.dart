import 'dart:convert';
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:logging/logging.dart';
import 'package:badnotes/components/canvas/image/editor_image.dart';
import 'package:badnotes/components/canvas/image/pdf_document_cache.dart';
import 'package:badnotes/data/list_eq.dart';

/// The pictures' files (PDFs, SVG text) a note has read from disk, kept
/// while a picture that uses them is on screen; Flutter's image cache does
/// this for bitmaps. One for each open note ([EditorCoreInfo]).
class AssetCache {
  final log = Logger('AssetCache');

  final pdfDocumentCache = PdfDocumentCache();

  /// What was read, by file path.
  final Map<String, Object> _read = {};

  /// The pictures on screen that use each file, by file path.
  final Map<String, Set<EditorImage>> _usedBy = {};

  /// False while the note is being saved, so nothing it needs is let go.
  var allowRemovingAssets = true;

  /// Keeps [value], read from [file], for [image], which is on screen. Safe
  /// to call again; does nothing without a [file].
  void addImage<T extends Object>(EditorImage image, File? file, T value) {
    if (file == null) return;
    (_usedBy[file.path] ??= {}).add(image);
    _read[file.path] = value;
  }

  /// What was read from [file], or null.
  T? get<T extends Object>(File file) => _read[file.path] as T?;

  /// [image] is off screen: lets go of every file no other picture on
  /// screen uses (not only the first, or the rest stayed in memory until the
  /// note closed). Safe to call again. Returns whether anything was let go.
  bool removeImage(EditorImage image) {
    if (!allowRemovingAssets) return false;
    final unused = [
      for (final MapEntry(key: path, value: users) in _usedBy.entries)
        if ((users..remove(image)).isEmpty) path,
    ];
    for (final path in unused) {
      _usedBy.remove(path);
      _read.remove(path);
    }
    return unused.isNotEmpty;
  }

  void dispose() {
    _usedBy.clear();
    _read.clear();
    pdfDocumentCache.dispose();
  }
}

/// The files, bytes and texts a note's pictures are saved from, each kept
/// once and numbered in the order it was first added: the number is what the
/// note stores (its `a` key) and the suffix of the asset file.
class OrderedAssetCache {
  final log = Logger('OrderedAssetCache');

  final List<Object> _items = [];

  /// The number of [item] (or of the first item [same] says is equal),
  /// adding it at the end if it isn't there yet.
  int _numberOf(Object item, bool Function(Object other) same) {
    var at = _items.indexOf(item);
    if (at == -1) at = _items.indexWhere(same);
    if (at != -1) return at;
    _items.add(item);
    return _items.length - 1;
  }

  /// The number of [file], added if new.
  int addFile(File file) =>
      _numberOf(file, (other) => other is File && other.path == file.path);

  /// The number of [bytes], added if new.
  int addBytes(List<int> bytes) =>
      _numberOf(bytes, (other) => other is List<int> && listEq(bytes, other));

  /// The number of [string], added if new.
  int addString(String string) => _numberOf(string, (other) => other == string);

  /// The number of [image]'s bytes or file, added if new.
  int addImage(ImageProvider image) => switch (image) {
    final MemoryImage memory => addBytes(memory.bytes),
    final FileImage file => addFile(file.file),
    _ => throw ArgumentError.value(
      image,
      'image',
      'Unsupported ImageProvider type',
    ),
  };

  /// The file the item at [index] is read from, if it is one.
  File? fileAt(int index) => switch (_items[index]) {
    final File file => file,
    _ => null,
  };

  /// Whether the item at [index] is the file at [path], which then needs no
  /// writing: saving read every asset and wrote it back over itself.
  bool isFileAt(int index, String path) {
    final item = _items[index];
    return item is File && item.path == path;
  }

  /// The number of (distinct) items.
  int get length => _items.length;
  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;

  /// The item at [index], as bytes.
  Future<List<int>> getBytes(int index) async => switch (_items[index]) {
    final List<int> bytes => bytes,
    final File file => file.readAsBytes(),
    final String text => utf8.encode(text),
    final other => throw Exception(
      'OrderedAssetCache.getBytes: unknown type ${other.runtimeType}',
    ),
  };
}
