import 'dart:isolate';
import 'dart:async';
import 'dart:convert';

import 'package:archive/archive_io.dart';
import 'package:bson/bson.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:badnotes/components/canvas/_asset_cache.dart';
import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:badnotes/data/editor/page.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/data/flavor_config.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/tools/stroke_properties.dart';
import 'package:badnotes/pages/editor/editor.dart';
import 'package:sbn/canvas_background_pattern.dart';
import 'package:sbn/has_size.dart';
import 'package:sbn/read_only_reason.dart';
import 'package:worker_manager/worker_manager.dart';

/// A note as a whole: its pages (and trashed pages), its paper, and where
/// it was left open. Read from and saved to the note file.
class EditorCoreInfo {
  static final log = Logger('EditorCoreInfo');

  /// The note file format this app writes. Raise it when older apps could
  /// no longer read a note properly; a note from a newer format opens
  /// read-only.
  ///
  /// What each format added:
  /// | 19 | pictures in their own files next to the note; `.sba` archives |
  /// | 18 | pencil |
  /// | 17 | PDF pages as pictures |
  /// | 16 | shape pen |
  /// | 15 | guitar-tab paper |
  /// | 14 | picture bytes as BSON binary |
  /// | 13 | points as BSON binary |
  /// | 12 | no pressure kept when there is none |
  /// | 11 | pictures' files kept once for the whole note |
  /// | 10 | old colour-inverting removed |
  /// | 9 | [Stroke.offset] |
  /// | 8 | strokes and pictures kept in their pages |
  /// | 7 | a picture as the page background |
  /// | 6 | typed (Quill) text |
  /// | 5 | pictures' file extensions |
  /// | 4 | [EditorPage.size] |
  /// | 3 | a size for each page |
  /// | 2 | width and height in the note |
  /// | 1 | the format version in the note |
  static const sbnVersion = 19;

  /// The reason why the note is read-only,
  /// or `null` if the note is editable.
  ReadOnlyReason? readOnlyReason;

  /// Whether the note is read-only.
  /// See [readOnlyReason] for the reason.
  bool get readOnly => readOnlyReason != null || locked;

  /// Pages taken out of the note, which can be put back or removed for good.
  /// They stay in the note's file until then.
  var trash = <EditorPage>[];

  /// Locked by the user against accidental changes. Saved with the note.
  var locked = false;

  String filePath;

  /// The file name without its parent directories.
  String get fileName => p.basename(filePath);

  AssetCache assetCache;
  int nextImageId;
  Color? backgroundColor;
  CanvasBackgroundPattern backgroundPattern;
  int lineHeight;
  int lineThickness;
  List<EditorPage> pages;

  /// Stores the current page index so that it can be restored when the file is reloaded.
  int? initialPageIndex;

  static final placeholder =
      EditorCoreInfo._(
        filePath: '',
        readOnlyReason: .placeholder,
        nextImageId: 0,
        backgroundColor: null,
        backgroundPattern: .none,
        lineHeight: stows.lastLineHeight.value,
        lineThickness: stows.lastLineThickness.value,
        pages: [],
        initialPageIndex: null,
        assetCache: null,
      ).._migrateOldStrokesAndImages(
        fileVersion: sbnVersion,
        strokesJson: null,
        imagesJson: null,
        inlineAssets: null,
        onlyFirstPage: true,
      );

  bool get isEmpty => pages.every((EditorPage page) => page.isEmpty);
  bool get isNotEmpty => !isEmpty;

  @visibleForTesting
  new({required this.filePath, this.readOnlyReason})
    : nextImageId = 0,
      backgroundPattern = stows.lastBackgroundPattern.value,
      lineHeight = stows.lastLineHeight.value,
      lineThickness = stows.lastLineThickness.value,
      pages = [],
      assetCache = AssetCache();

  new _({
    required this.filePath,
    required this.readOnlyReason,
    required this.nextImageId,
    this.backgroundColor,
    required this.backgroundPattern,
    required this.lineHeight,
    required this.lineThickness,
    required this.pages,
    required this.initialPageIndex,
    required AssetCache? assetCache,
  }) : assetCache = assetCache ?? AssetCache() {
    _handleEmptyImageIds();
  }

  factory fromJson(
    Map<String, dynamic> json, {
    required String filePath,
    required bool onlyFirstPage,
  }) {
    ReadOnlyReason? readOnlyReason;
    final fileVersion = json['v'] as int? ?? 0;
    if (fileVersion > sbnVersion) {
      readOnlyReason ??= .versionTooNew;
      log.warning(
        'File version $fileVersion is newer than supported $sbnVersion. '
        'Note may be read incorrectly or incompletely.',
      );
    }

    // pictures kept inside the note itself, from before format 19
    final inlineAssets = (json['a'] as List?)?.map(_inlineAsset).toList();
    final backgroundColor = _colorFrom(json['b']);

    final assetCache = AssetCache();

    return EditorCoreInfo._(
        filePath: filePath,
        readOnlyReason: readOnlyReason,
        nextImageId: json['ni'] as int? ?? 0,
        backgroundColor: backgroundColor,
        backgroundPattern: CanvasBackgroundPattern.fromName(
          json['p'] as String?,
        ),
        lineHeight: json['l'] as int? ?? stows.lastLineHeight.value,
        lineThickness: json['lt'] as int? ?? stows.lastLineThickness.value,
        pages: _parsePagesJson(
          json['z'] as List?,
          inlineAssets: inlineAssets,
          readOnlyReason: readOnlyReason,
          onlyFirstPage: onlyFirstPage,
          fileVersion: fileVersion,
          sbnPath: filePath,
          assetCache: assetCache,
        ),
        initialPageIndex: json['c'] as int?,
        assetCache: assetCache,
      )
      ..locked = json['lock'] == true
      ..trash = onlyFirstPage
          ? <EditorPage>[]
          : _parsePagesJson(
              json['tr'] as List?,
              inlineAssets: inlineAssets,
              readOnlyReason: readOnlyReason,
              onlyFirstPage: false,
              fileVersion: fileVersion,
              sbnPath: filePath,
              assetCache: assetCache,
            )
      .._migrateOldStrokesAndImages(
        fileVersion: fileVersion,
        strokesJson: json['s'] as List?,
        imagesJson: json['i'] as List?,
        inlineAssets: inlineAssets,
        fallbackPageSize: json['w'] != null && json['h'] != null
            ? Size(json['w'] as double, json['h'] as double)
            : null,
        onlyFirstPage: onlyFirstPage,
      )
      .._sortStrokes();
  }

  /// One picture's bytes as an older note kept them: base64 text, bytes,
  /// a list of numbers or BSON binary.
  static Uint8List _inlineAsset(dynamic asset) => switch (asset) {
    final String base64 => base64Decode(base64),
    final Uint8List bytes => bytes,
    final List<dynamic> numbers => Uint8List.fromList(numbers.cast<int>()),
    final BsonBinary binary => binary.byteList,
    _ => () {
      log.severe('Invalid asset type: ${asset.runtimeType}');
      return Uint8List(0);
    }(),
  };

  /// The note's paper colour, kept as a 32-bit number (or none).
  static Color? _colorFrom(dynamic value) => switch (value) {
    null => null,
    final int argb => Color(argb),
    final Int64 argb => Color(argb.toInt()),
    _ => throw Exception('Invalid color value: (${value.runtimeType}) $value'),
  };

  /// The oldest notes: just a list of strokes.
  new fromOldJson(
    List<dynamic> json, {
    required this.filePath,
    required bool onlyFirstPage,
  }) : nextImageId = 0,
       backgroundPattern = .none,
       lineHeight = stows.lastLineHeight.value,
       lineThickness = stows.lastLineThickness.value,
       pages = [],
       assetCache = AssetCache() {
    _migrateOldStrokesAndImages(
      fileVersion: 0,
      strokesJson: json,
      imagesJson: null,
      inlineAssets: null,
      onlyFirstPage: onlyFirstPage,
    );
    _sortStrokes();
  }

  /// The pages in [pages] (only the first if [onlyFirstPage]). The oldest
  /// notes kept just each page's `[width, height]`.
  static List<EditorPage> _parsePagesJson(
    List<dynamic>? pages, {
    required List<Uint8List>? inlineAssets,
    required ReadOnlyReason? readOnlyReason,
    required bool onlyFirstPage,
    required int fileVersion,
    required String sbnPath,
    required AssetCache assetCache,
  }) {
    if (pages == null || pages.isEmpty) return [];
    final wanted = onlyFirstPage ? pages.take(1) : pages;
    if (pages.first is List) {
      return [
        for (final size in wanted)
          EditorPage(width: size[0] as double?, height: size[1] as double?),
      ];
    }
    return [
      for (final page in wanted)
        EditorPage.fromJson(
          page as Map<String, dynamic>,
          inlineAssets: inlineAssets,
          readOnly: readOnlyReason != null,
          fileVersion: fileVersion,
          sbnPath: sbnPath,
          assetCache: assetCache,
        ),
    ];
  }

  void _handleEmptyImageIds() {
    for (final page in pages) {
      for (final image in page.images) {
        if (image.id == -1) image.id = nextImageId++;
      }
    }
  }

  /// Brings notes from older formats up to date:
  /// - before format 8, strokes and pictures were kept for the whole note
  ///   ([strokesJson], [imagesJson]): each goes onto its page, adding pages
  ///   as needed;
  /// - before format 12, points very close together were kept: they're
  ///   thinned out.
  ///
  /// And makes sure there's a page, with an empty one at the end.
  void _migrateOldStrokesAndImages({
    required int fileVersion,
    required List<dynamic>? strokesJson,
    required List<dynamic>? imagesJson,
    required List<Uint8List>? inlineAssets,
    Size? fallbackPageSize,
    required bool onlyFirstPage,
  }) {
    /// Page [index], adding pages up to it if the note has fewer.
    EditorPage pageAt(int index) {
      while (pages.length <= index) {
        pages.add(EditorPage(size: fallbackPageSize));
      }
      return pages[index];
    }

    if (strokesJson != null) {
      for (final stroke in EditorPage.parseStrokesJson(
        strokesJson,
        page: HasSize(fallbackPageSize ?? EditorPage.defaultSize),
        onlyFirstPage: onlyFirstPage,
        fileVersion: fileVersion,
      )) {
        assert(!onlyFirstPage || stroke.pageIndex == 0);
        pageAt(stroke.pageIndex).insertStroke(stroke);
      }
    }

    if (imagesJson != null) {
      for (final image in EditorPage.parseImagesJson(
        imagesJson,
        inlineAssets: inlineAssets,
        isThumbnail: readOnlyReason != null,
        onlyFirstPage: onlyFirstPage,
        sbnPath: filePath,
        assetCache: assetCache,
      )) {
        assert(!onlyFirstPage || image.pageIndex == 0);
        pageAt(image.pageIndex).images.add(image);
      }
    }

    // always a page, and room to write at the end
    final needsPage =
        pages.isEmpty || (pages.last.isNotEmpty && !onlyFirstPage);
    if (needsPage) pages.add(EditorPage(size: fallbackPageSize));

    if (fileVersion < 12) {
      for (final page in pages) {
        for (final stroke in page.strokes) {
          stroke.optimisePoints();
        }
      }
    }
  }

  void _sortStrokes() {
    for (final page in pages) {
      page.sortStrokes();
    }
  }

  static Future<EditorCoreInfo> loadFromFilePath(
    String path, {
    bool onlyFirstPage = false,
  }) async {
    final first = await _loadOnce(path, onlyFirstPage: onlyFirstPage);
    if (first.readOnlyReason != .corrupted) return first;
    // maybe still being saved by the editor that just closed it: once more
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return _loadOnce(path, onlyFirstPage: onlyFirstPage);
  }

  /// Reads the note at [path] (its `.sbn2`, or the old `.sbn` JSON), or a
  /// new empty note if there's neither.
  static Future<EditorCoreInfo> _loadOnce(
    String path, {
    required bool onlyFirstPage,
  }) async {
    final bsonBytes = await FileManager.readFile(path + Editor.extension);
    String? jsonString;
    if (bsonBytes == null) {
      final old = await FileManager.readFile(path + Editor.extensionOldJson);
      if (old == null) return EditorCoreInfo(filePath: path);
      jsonString = utf8.decode(old);
    }
    return loadFromFileContents(
      jsonString: jsonString,
      bsonBytes: bsonBytes,
      path: path,
      onlyFirstPage: onlyFirstPage,
    );
  }

  /// Works out what drawing the strokes needs that can be sent between
  /// isolates, so the first paint doesn't have to.
  void prepareForDrawing() {
    for (final page in pages) {
      for (final stroke in page.strokes) {
        stroke.prepareForDrawing();
      }
    }
  }

  /// Notes bigger than this are read on a worker isolate.
  static const _isolateThreshold = 16 * 1024;

  @visibleForTesting
  static Future<EditorCoreInfo> loadFromFileContents({
    String? jsonString,
    Uint8List? bsonBytes,
    required String path,
    required bool onlyFirstPage,
    bool alwaysUseIsolate = false,
  }) async {
    EditorCoreInfo coreInfo;
    try {
      EditorCoreInfo isolate() => EditorCoreInfo._loadFromFileIsolate(
        jsonString,
        bsonBytes,
        path,
        onlyFirstPage,
      );

      final length = jsonString?.length ?? bsonBytes!.length;
      // Off the main thread for all but tiny notes: even a 60 KB note took
      // 40-80 ms to read there on a desktop, more on a phone, which stalled
      // the note's opening animation.
      if (alwaysUseIsolate || length > _isolateThreshold) {
        final documentsDirectory = FileManager.documentsDirectory;
        coreInfo = await workerManager.execute(
          () async {
            // a worker isolate starts with nothing set up: the build's
            // flavour, the documents folder and the pen defaults again
            FlavorConfig.setupFromEnvironment();
            await FileManager.init(
              documentsDirectory: documentsDirectory,
              shouldWatchRootDirectory: false,
            );
            StrokeOptionsExtension.setDefaults();
            // the outlines too: drawing the first page worked them out on
            // the main thread, 20-40 ms for a full page
            return isolate()..prepareForDrawing();
          },
          // less important than [WorkPriority.immediately]
          priority: WorkPriority.veryHigh,
        );
      } else {
        // if the file is small, just run it on the main thread
        coreInfo = isolate();
      }
    } catch (e, st) {
      log.severe('Failed to load file: $e', e, st);
      if (kDebugMode) {
        rethrow;
      } else {
        coreInfo = EditorCoreInfo(filePath: path, readOnlyReason: .corrupted);
      }
    }

    return coreInfo;
  }

  /// Decodes the file's contents (BSON, or the old JSON) into a note. The
  /// oldest notes are a bare list of strokes.
  factory _loadFromFileIsolate(
    String? jsonString,
    Uint8List? bsonBytes,
    String path,
    bool onlyFirstPage,
  ) {
    final dynamic json;
    try {
      json = switch ((bsonBytes, jsonString)) {
        (final Uint8List bytes, _) => BsonCodec.deserialize(
          BsonBinary.from(bytes),
        ),
        (null, final String text) => jsonDecode(text),
        (null, null) => throw ArgumentError(
          'Both bsonBytes and jsonString are null',
        ),
      };
    } catch (e, st) {
      log.severe('Failed to parse file: $e', e, st);
      rethrow;
    }
    return switch (json) {
      null => throw Exception('Failed to parse json'),
      final List<dynamic> strokes => EditorCoreInfo.fromOldJson(
        strokes,
        filePath: path,
        onlyFirstPage: onlyFirstPage,
      ),
      _ => EditorCoreInfo.fromJson(
        json as Map<String, dynamic>,
        filePath: path,
        onlyFirstPage: onlyFirstPage,
      ),
    };
  }

  /// The note as a map for the file, and the pictures' files to save next
  /// to it (the pages add them as they go).
  (Map<String, dynamic> json, OrderedAssetCache) toJson() {
    final assets = OrderedAssetCache();

    final json = {
      'v': sbnVersion,
      'ni': nextImageId,
      'b': backgroundColor?.toARGB32(),
      'p': backgroundPattern.name,
      'l': lineHeight,
      'lt': lineThickness,
      'z': pages.map((EditorPage page) => page.toJson(assets)).toList(),
      'c': initialPageIndex,
      if (locked) 'lock': true,
      if (trash.isNotEmpty)
        'tr': trash.map((EditorPage page) => page.toJson(assets)).toList(),
    };

    return (json, assets);
  }

  /// The note as one `.sba` file to share: a zip holding the note as
  /// `main.sbn2` and its pictures as `main.sbn2.0`, `main.sbn2.1` and so on.
  /// Saves [currentPageIndex] as the page to open at, if given.
  Future<List<int>> saveToSba({required int? currentPageIndex}) async {
    final (bson, assets) = saveToBinary(currentPageIndex: currentPageIndex);
    const name = 'main${Editor.extension}';
    final archive = Archive()..addFile(ArchiveFile(name, bson.length, bson));
    final files = await Future.wait([
      for (var i = 0; i < assets.length; i++) assets.getBytes(i),
    ]);
    for (final (i, bytes) in files.indexed) {
      archive.addFile(ArchiveFile('$name.$i', bytes.length, bytes));
    }
    return ZipEncoder().encode(archive);
  }

  /// The note as BSON bytes, and the pictures' files to save next to it.
  (Uint8List bson, OrderedAssetCache assets) saveToBinary({
    required int? currentPageIndex,
  }) {
    initialPageIndex = currentPageIndex ?? initialPageIndex;
    final (json, assets) = toJson();
    final bson = BsonCodec.serialize(json);
    return (bson.byteList, assets);
  }

  /// As [saveToBinary], but a big note's bytes are put together on another
  /// isolate: that took a few hundred ms on the main thread for a note of
  /// dozens of full pages, which showed as a hitch on every autosave.
  Future<(Uint8List bson, OrderedAssetCache assets)> saveToBinaryAsync({
    required int? currentPageIndex,
  }) async {
    initialPageIndex = currentPageIndex ?? initialPageIndex;
    final (json, assets) = toJson();
    var strokes = 0;
    for (final page in pages) {
      strokes += page.strokes.length;
    }
    if (strokes < _isolateStrokes) {
      return (BsonCodec.serialize(json).byteList, assets);
    }
    return (await Isolate.run(_serializer(json)), assets);
  }

  /// A closure holding only [json], to send to another isolate.
  static Uint8List Function() _serializer(Map<String, dynamic> json) =>
      () => BsonCodec.serialize(json).byteList;

  /// Notes with more strokes than this are saved through an isolate.
  static const _isolateStrokes = 1500;

  void dispose() {
    for (final page in pages) {
      page.dispose();
    }
    for (final page in trash) {
      page.dispose();
    }
    assetCache.dispose();
  }

  EditorCoreInfo copyWith({
    String? filePath,
    ReadOnlyReason? readOnlyReason,
    int? nextImageId,
    Color? backgroundColor,
    CanvasBackgroundPattern? backgroundPattern,
    int? lineHeight,
    int? lineThickness,
    List<EditorPage>? pages,
  }) {
    return EditorCoreInfo._(
        filePath: filePath ?? this.filePath,
        readOnlyReason: readOnlyReason ?? this.readOnlyReason,
        nextImageId: nextImageId ?? this.nextImageId,
        backgroundColor: backgroundColor ?? this.backgroundColor,
        backgroundPattern: backgroundPattern ?? this.backgroundPattern,
        lineHeight: lineHeight ?? this.lineHeight,
        lineThickness: lineThickness ?? this.lineThickness,
        pages: pages ?? this.pages,
        initialPageIndex: initialPageIndex,
        assetCache: assetCache,
      )
      ..locked = locked
      ..trash = trash;
  }
}
