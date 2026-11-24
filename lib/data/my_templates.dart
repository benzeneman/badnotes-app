import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:badnotes/components/canvas/_asset_cache.dart';
import 'package:badnotes/components/editor/new_page_sheet.dart';
import 'package:badnotes/data/editor/editor_core_info.dart';
import 'package:badnotes/data/editor/editor_exporter.dart';
import 'package:badnotes/data/editor/page.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/data/nextcloud/badnotes_syncer.dart';
import 'package:badnotes/pages/editor/editor.dart';
import 'package:bson/bson.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/widgets.dart';
import 'package:sbn/canvas_background_pattern.dart';

/// A page the user saved to start new pages and notebooks from (design N4).
class MyTemplate {
  const new({
    required this.name,
    required this.paper,
    required this.hasContent,
    this.isDefault = false,
    this.thumbnail,
  });

  final String name;

  /// Its size, pattern, colour and line spacing.
  final PageTemplate paper;

  /// Whether it has ink, pictures or text on it, or is only paper.
  final bool hasContent;

  /// The one new notebooks start from.
  final bool isDefault;

  /// A small PNG of the page, if it's been drawn.
  final Uint8List? thumbnail;

  /// e.g. `/.templates/Weekly planner`, without the extension.
  String get path => '${MyTemplates.dir}/$name';
}

/// The user's own templates: each a one-page note file with its pictures
/// inside it, and a `.p` thumbnail beside it, in [dir]. They sync like notes
/// (the syncer sends everything under the notes folder); the home screen
/// doesn't list them as long as it skips folders starting with a dot.
abstract final class MyTemplates {
  static const dir = '/.templates';

  /// Holds the name of the default template.
  static const _defaultFile = '$dir/default.txt';

  /// The templates, by name.
  static Future<List<MyTemplate>> list() async {
    final folder = FileManager.getFile(dir);
    final directory = Directory(folder.path);
    if (!directory.existsSync()) return const [];
    final defaultName = await _defaultName();
    final templates = <MyTemplate>[];
    for (final file in directory.listSync().whereType<File>()) {
      final fileName = file.uri.pathSegments.last;
      if (!fileName.endsWith(Editor.extension)) continue;
      final name = fileName.substring(
        0,
        fileName.length - Editor.extension.length,
      );
      try {
        final json = _decode(await file.readAsBytes());
        final page = (json['z'] as List).first as Map<String, dynamic>;
        final thumb = File('${file.path}.p');
        templates.add(
          MyTemplate(
            name: name,
            paper: paperOf(page, json),
            hasContent: hasContent(page),
            isDefault: name == defaultName,
            thumbnail: thumb.existsSync() ? await thumb.readAsBytes() : null,
          ),
        );
      } catch (_) {
        // half-synced or broken: left out until it reads
      }
    }
    templates.sort((a, b) => a.name.compareTo(b.name));
    return templates;
  }

  /// Saves page [pageIndex] of [note] as a template called [name] (or
  /// "[name] (2)" if that's taken). Without [keepContent], only its paper.
  static Future<MyTemplate> save({
    required EditorCoreInfo note,
    required int pageIndex,
    required String name,
    required bool keepContent,
  }) async {
    final page = note.pages[pageIndex];
    final assets = OrderedAssetCache();
    final pageJson = templatePageJson(
      page.toJson(assets),
      keepContent: keepContent,
      notePattern: note.backgroundPattern,
      noteLineHeight: note.lineHeight,
      noteColor: note.backgroundColor,
    );
    final pictures = [
      if (keepContent)
        for (var i = 0; i < assets.length; ++i)
          BsonBinary.from(await assets.getBytes(i)),
    ];
    final bson = BsonCodec.serialize(<String, dynamic>{
      'v': EditorCoreInfo.sbnVersion,
      'ni': note.nextImageId,
      'b': note.backgroundColor?.toARGB32(),
      'p': note.backgroundPattern.name,
      'l': note.lineHeight,
      'lt': note.lineThickness,
      'z': [pageJson],
      // the pictures go inside the file, so a template is one file
      if (pictures.isNotEmpty) 'a': pictures,
    }).byteList;

    final path = await FileManager.suffixFilePathToMakeItUnique(
      '$dir/${cleanName(name)}',
    );
    await _write(path + Editor.extension, bson);
    final template = MyTemplate(
      name: path.substring(dir.length + 1),
      paper: paperOf(pageJson, const {}),
      hasContent: hasContent(pageJson),
    );
    try {
      await _drawThumbnail(template);
    } catch (_) {
      // no picture: the gallery shows its paper instead
    }
    return template;
  }

  /// Renames [template]; returns it under its new name.
  static Future<MyTemplate> rename(MyTemplate template, String name) async {
    final wasDefault = (await _defaultName()) == template.name;
    final moved = await FileManager.moveFile(
      template.path + Editor.extension,
      '$dir/${cleanName(name)}${Editor.extension}',
    );
    final newName = moved.substring(
      dir.length + 1,
      moved.length - Editor.extension.length,
    );
    if (wasDefault) await _write(_defaultFile, utf8.encode(newName));
    return MyTemplate(
      name: newName,
      paper: template.paper,
      hasContent: template.hasContent,
      isDefault: wasDefault,
      thumbnail: template.thumbnail,
    );
  }

  /// Deletes [template] and its thumbnail.
  static Future<void> delete(MyTemplate template) async {
    if ((await _defaultName()) == template.name) await setDefault(null);
    await FileManager.deleteFile(template.path + Editor.extension);
  }

  /// The template new notebooks start from, if one was chosen.
  static Future<MyTemplate?> defaultTemplate() async {
    final name = await _defaultName();
    if (name == null) return null;
    for (final template in await list()) {
      if (template.name == name) return template;
    }
    return null;
  }

  /// Makes [template] the default, or none when null.
  static Future<void> setDefault(MyTemplate? template) async {
    if (template == null) {
      await FileManager.deleteFile(_defaultFile);
    } else {
      await _write(_defaultFile, utf8.encode(template.name));
    }
  }

  /// A fresh copy of [template]'s page for [into], with its own picture ids
  /// and its pictures held in memory until [into] is saved.
  static Future<EditorPage> loadPage(
    MyTemplate template, {
    required EditorCoreInfo into,
  }) async {
    final bytes = await FileManager.readFile(
      template.path + Editor.extension,
      retries: 0,
    );
    if (bytes == null) {
      final paper = template.paper;
      return EditorPage(size: paper.size)
        ..backgroundPattern = paper.pattern
        ..lineHeight = paper.lineHeight
        ..backgroundColor = paper.color;
    }
    final json = _decode(bytes);
    final page = EditorPage.fromJson(
      (json['z'] as List).first as Map<String, dynamic>,
      inlineAssets: [
        for (final asset in (json['a'] as List?) ?? const []) _bytesOf(asset),
      ],
      readOnly: false,
      fileVersion: json['v'] as int? ?? EditorCoreInfo.sbnVersion,
      sbnPath: into.filePath,
      assetCache: into.assetCache,
    );
    for (final image in [?page.backgroundImage, ...page.images]) {
      image.id = into.nextImageId++;
    }
    return page;
  }

  /// Writes [template] as the note at [notePath] (without the extension):
  /// a new notebook whose first page is the template's.
  static Future<void> writeAsNote(MyTemplate template, String notePath) async {
    final bytes = await FileManager.readFile(
      template.path + Editor.extension,
      retries: 0,
    );
    if (bytes == null) return;
    await FileManager.writeFile(
      notePath + Editor.extension,
      bytes,
      awaitWrite: true,
    );
    if (template.thumbnail case final thumbnail?) {
      await FileManager.writeFile(
        '$notePath${Editor.extension}.p',
        thumbnail,
        awaitWrite: true,
      );
    }
  }

  // --- the pure parts --------------------------------------------------------

  /// A name that's fine as a file name: no slashes or other forbidden
  /// characters, never empty.
  static String cleanName(String name) {
    final clean = name
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '-')
        .trim()
        .replaceAll(RegExp(r'^\.+'), '');
    return clean.isEmpty ? 'My template' : clean;
  }

  /// [pageJson] (an [EditorPage.toJson]) made into a template's page: the
  /// note's paper written onto it, so it looks the same in any note, its
  /// bookmark dropped, and with only its paper unless [keepContent].
  static Map<String, dynamic> templatePageJson(
    Map<String, dynamic> pageJson, {
    required bool keepContent,
    required CanvasBackgroundPattern notePattern,
    required int noteLineHeight,
    required Color? noteColor,
  }) {
    final json = {...pageJson}..remove('fav');
    if (!keepContent) {
      for (final key in const ['s', 'i', 'q', 'b', 'la', 'lac']) {
        json.remove(key);
      }
    }
    // ink and pictures name their page: in a template, it's the first
    for (final key in const ['s', 'i']) {
      if (json[key] case final List items) {
        json[key] = [
          for (final item in items) {...(item as Map<String, dynamic>), 'i': 0},
        ];
      }
    }
    if (json['b'] case final Map<String, dynamic> background) {
      json['b'] = {...background, 'i': 0};
    }
    json['bp'] ??= notePattern.name;
    json['lh'] ??= noteLineHeight;
    if (noteColor != null) json['bc'] ??= noteColor.toARGB32();
    return json;
  }

  /// Whether a template's [pageJson] has anything on it besides paper.
  static bool hasContent(Map<String, dynamic> pageJson) =>
      const ['s', 'i', 'q', 'b'].any(pageJson.containsKey);

  /// The paper of a template's [pageJson], falling back to its [noteJson].
  static PageTemplate paperOf(
    Map<String, dynamic> pageJson,
    Map<String, dynamic> noteJson,
  ) {
    int? asInt(Object? value) => switch (value) {
      final int value => value,
      final Int64 value => value.toInt(),
      _ => null,
    };
    final pattern = pageJson['bp'] ?? noteJson['p'];
    final color = asInt(pageJson['bc'] ?? noteJson['b']);
    return PageTemplate(
      size: Size(
        (pageJson['w'] as num?)?.toDouble() ?? EditorPage.defaultWidth,
        (pageJson['h'] as num?)?.toDouble() ?? EditorPage.defaultHeight,
      ),
      pattern: pattern is String
          ? CanvasBackgroundPattern.fromName(pattern)
          : null,
      color: color == null ? null : Color(color),
      lineHeight: asInt(pageJson['lh'] ?? noteJson['l']),
    );
  }

  // --- files -----------------------------------------------------------------

  static Map<String, dynamic> _decode(List<int> bytes) =>
      BsonCodec.deserialize(BsonBinary.from(bytes));

  static Uint8List _bytesOf(Object? asset) => switch (asset) {
    final BsonBinary binary => binary.byteList,
    final Uint8List bytes => bytes,
    final List<dynamic> bytes => Uint8List.fromList(bytes.cast<int>()),
    _ => Uint8List(0),
  };

  static Future<String?> _defaultName() async {
    if (!FileManager.doesFileExist(_defaultFile)) return null;
    final bytes = await FileManager.readFile(_defaultFile, retries: 0);
    return bytes == null ? null : utf8.decode(bytes).trim();
  }

  /// Writes without adding it to the recent notes, and queues it for sync.
  static Future<void> _write(String path, List<int> bytes) async {
    await FileManager.writeFile(path, bytes, awaitWrite: true, quietly: true);
    unawaited(syncer.uploader.enqueueRel(path));
  }

  /// Draws [template]'s page into its `.p` thumbnail, from the saved file.
  static Future<void> _drawThumbnail(MyTemplate template) async {
    final note = await EditorCoreInfo.loadFromFilePath(template.path);
    try {
      if (note.pages.isEmpty) return;
      final size = note.pages.first.size;
      final image = await EditorExporter.screenshotPage(
        coreInfo: note,
        pageIndex: 0,
        rasterizeAllStrokes: true,
        targetSize: Size(240, 240 * size.height / size.width),
        pixelRatio: 1,
      );
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (png == null) return;
      await _write(
        '${template.path}${Editor.extension}.p',
        png.buffer.asUint8List(),
      );
    } finally {
      note.dispose();
    }
  }
}
