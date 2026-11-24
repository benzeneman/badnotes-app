import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:badnotes/components/home/quick_ink.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// One line of a quick note's checklist.
class BoardCheck {
  const new(this.text, {this.done = false});

  final String text;
  final bool done;

  BoardCheck copyWith({String? text, bool? done}) =>
      BoardCheck(text ?? this.text, done: done ?? this.done);

  Map<String, dynamic> toJson() => {'text': text, 'done': done};

  static BoardCheck? fromJson(Object? json) => json is Map
      ? BoardCheck(json['text'] as String? ?? '', done: json['done'] == true)
      : null;
}

/// A sticky note or a pinned photo on the home screen's board (design §7.2).
class BoardItem {
  const new({
    required this.id,
    required this.photo,
    this.text = '',
    this.checklist = const [],
    this.ink = const [],
    this.color = 0,
    required this.createdAt,
    required this.updatedAt,
    this.order = 0,
    this.box,
    this.angle = 0,
    this.z = 0,
    this.deco = 0,
    this.shape = 1,
    this.corners = 0.12,
    this.crop = const Rect.fromLTRB(0, 0, 1, 1),
    this.aspect = 0,
  });

  /// Where it is on the board, in units of a board 1000 wide; null until
  /// it has a place (it gets the first free one).
  final Rect? box;

  /// How far it's turned, in radians.
  final double angle;

  /// Drawn over the ones with a lower [z].
  final int z;

  /// 0 nothing on it, 1 a pin, 2 a strip of tape.
  final int deco;

  /// A photo's frame: 0 square, 1 rounded, 2 circle.
  final int shape;

  /// How round a rounded photo's corners are, 0 to 1.
  final double corners;

  /// The part of the photo shown, as fractions of it.
  final Rect crop;

  /// The photo's width over its height; 0 if not known yet.
  final double aspect;

  final String id;

  /// The photo's file, e.g. `/.board/1763740000000.jpg`; null for a note.
  final String? photo;
  final String text;
  final List<BoardCheck> checklist;

  /// What was written on the note by hand.
  final List<BoardStroke> ink;

  /// An index into [BoardItem.colors].
  final int color;
  final DateTime createdAt, updatedAt;
  final int order;

  bool get isPhoto => photo != null;

  /// The notes' colours: butter, peach, sky, lilac, mint.
  static const colors = [
    BnColors.noteButter,
    BnColors.notePeach,
    BnColors.noteSky,
    BnColors.noteLilac,
    BnColors.noteMint,
  ];

  Color get paper => colors[color.clamp(0, colors.length - 1)];

  BoardItem copyWith({
    String? text,
    List<BoardCheck>? checklist,
    List<BoardStroke>? ink,
    int? color,
    int? order,
    Rect? Function()? box,
    double? angle,
    int? z,
    int? deco,
    int? shape,
    double? corners,
    Rect? crop,
    double? aspect,
  }) => BoardItem(
    id: id,
    photo: photo,
    text: text ?? this.text,
    checklist: checklist ?? this.checklist,
    ink: ink ?? this.ink,
    color: color ?? this.color,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
    order: order ?? this.order,
    box: box == null ? this.box : box(),
    angle: angle ?? this.angle,
    z: z ?? this.z,
    deco: deco ?? this.deco,
    shape: shape ?? this.shape,
    corners: corners ?? this.corners,
    crop: crop ?? this.crop,
    aspect: aspect ?? this.aspect,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': isPhoto ? 'photo' : 'note',
    'text': text,
    'checklist': [for (final c in checklist) c.toJson()],
    if (ink.isNotEmpty) 'ink': [for (final s in ink) s.toJson()],
    'color': color,
    'photo': ?photo,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
    'order': order,
    if (box case final b?) 'b': [b.left, b.top, b.width, b.height],
    if (angle != 0) 'a': angle,
    if (z != 0) 'z': z,
    if (deco != 0) 'd': deco,
    if (shape != 1) 's': shape,
    if (corners != 0.12) 'cr': corners,
    if (crop != const Rect.fromLTRB(0, 0, 1, 1))
      'cp': [crop.left, crop.top, crop.right, crop.bottom],
    if (aspect != 0) 'ar': aspect,
  };

  static BoardItem? fromJson(Object? json) {
    if (json is! Map || json['id'] is! String) return null;
    DateTime at(Object? ms) =>
        DateTime.fromMillisecondsSinceEpoch(ms is int ? ms : 0);
    return BoardItem(
      id: json['id'] as String,
      photo: json['type'] == 'photo' ? json['photo'] as String? : null,
      text: json['text'] as String? ?? '',
      checklist: [
        for (final c in (json['checklist'] as List? ?? const []))
          ?BoardCheck.fromJson(c),
      ],
      ink: [
        for (final s in (json['ink'] as List? ?? const []))
          ?BoardStroke.fromJson(s),
      ],
      color: json['color'] as int? ?? 0,
      createdAt: at(json['createdAt']),
      updatedAt: at(json['updatedAt']),
      order: json['order'] as int? ?? 0,
      box: switch (json['b']) {
        [num l, num t, num w, num h] => Rect.fromLTWH(
          l.toDouble(),
          t.toDouble(),
          w.toDouble(),
          h.toDouble(),
        ),
        _ => null,
      },
      angle: (json['a'] as num?)?.toDouble() ?? 0,
      z: json['z'] as int? ?? 0,
      deco: json['d'] as int? ?? 0,
      shape: json['s'] as int? ?? 1,
      corners: (json['cr'] as num?)?.toDouble() ?? 0.12,
      crop: switch (json['cp']) {
        [num l, num t, num r, num b] => Rect.fromLTRB(
          l.toDouble(),
          t.toDouble(),
          r.toDouble(),
          b.toDouble(),
        ),
        _ => const Rect.fromLTRB(0, 0, 1, 1),
      },
      aspect: (json['ar'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// The quick notes board: `/.board/board.json` and the photos beside it,
/// written through the file manager so they sync. Shown at once, saved a
/// moment later; another device's changes are merged by id, newest wins.
abstract final class QuickBoard {
  static const dir = '/.board';
  static const _file = '$dir/board.json';

  static final items = ValueNotifier<List<BoardItem>>(const []);
  static var _loaded = false;
  static StreamSubscription<FileOperation>? _changes;
  static Timer? _saveTimer;

  /// Items deleted here, so a merge doesn't bring them back.
  static final _deleted = <String>{};

  static Future<void> load() async {
    _changes ??= FileManager.fileWriteStream.stream.listen((event) {
      // written by a sync from another device: merge it in
      if (event.filePath == _file && _saveTimer == null) unawaited(_read());
    });
    if (_loaded) return;
    _loaded = true;
    await _read();
  }

  static Future<void> _read() async {
    if (!FileManager.doesFileExist(_file)) return;
    final bytes = await FileManager.readFile(_file, retries: 0);
    if (bytes == null) return;
    List<BoardItem> theirs;
    try {
      theirs = [
        for (final item in jsonDecode(utf8.decode(bytes)) as List)
          ?BoardItem.fromJson(item),
      ];
    } on FormatException {
      return;
    }
    final merged = {for (final item in items.value) item.id: item};
    for (final item in theirs) {
      if (_deleted.contains(item.id)) continue;
      final mine = merged[item.id];
      if (mine == null || item.updatedAt.isAfter(mine.updatedAt)) {
        merged[item.id] = item;
      }
    }
    items.value = merged.values.toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  static void _saveSoon() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), () async {
      _saveTimer = null;
      await FileManager.writeFile(
        _file,
        utf8.encode(jsonEncode([for (final i in items.value) i.toJson()])),
      );
    });
  }

  static String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  /// Pins a new note at the start of the board.
  static BoardItem addNote({
    String text = '',
    List<BoardCheck> checklist = const [],
    List<BoardStroke> ink = const [],
    int color = 0,
  }) {
    final now = DateTime.now();
    final item = BoardItem(
      id: _newId(),
      photo: null,
      text: text,
      checklist: checklist,
      ink: ink,
      color: color,
      createdAt: now,
      updatedAt: now,
      order: _firstOrder(),
      z: topZ + 1,
    );
    items.value = [item, ...items.value];
    _saveSoon();
    return item;
  }

  /// The highest [BoardItem.z] on the board.
  static int get topZ =>
      items.value.fold(0, (top, item) => item.z > top ? item.z : top);

  /// The places before the last "Tidy up", to put back.
  static Map<String, (Rect?, double)>? untidy;

  /// Puts everything back into neat rows: each gets the first free place
  /// again, upright. [untidy] keeps where they were.
  static void tidy() {
    untidy = {for (final i in items.value) i.id: (i.box, i.angle)};
    items.value = [
      for (final i in items.value) i.copyWith(box: () => null, angle: 0),
    ];
    _saveSoon();
  }

  static void undoTidy() {
    final before = untidy;
    if (before == null) return;
    untidy = null;
    items.value = [
      for (final i in items.value)
        if (before[i.id] case (final box, final angle))
          i.copyWith(box: () => box, angle: angle)
        else
          i,
    ];
    _saveSoon();
  }

  static int _firstOrder() => items.value.isEmpty
      ? 0
      : items.value.map((i) => i.order).reduce((a, b) => a < b ? a : b) - 1;

  /// Pins a photo: made at most 1600 px and saved as a JPEG, off the UI
  /// thread.
  static Future<BoardItem?> addPhoto(Uint8List bytes) async {
    final jpeg = await Isolate.run(() => _shrink(bytes));
    if (jpeg == null) return null;
    final id = _newId();
    final path = '$dir/$id.jpg';
    await FileManager.writeFile(path, jpeg, awaitWrite: true);
    final now = DateTime.now();
    final item = BoardItem(
      id: id,
      photo: path,
      createdAt: now,
      updatedAt: now,
      order: _firstOrder(),
      z: topZ + 1,
    );
    items.value = [item, ...items.value];
    _saveSoon();
    return item;
  }

  static Uint8List? _shrink(Uint8List bytes) {
    final image = img.decodeImage(bytes);
    if (image == null) return null;
    final side = image.width > image.height ? image.width : image.height;
    final small = side <= 1600
        ? image
        : img.copyResize(
            image,
            width: image.width >= image.height ? 1600 : null,
            height: image.height > image.width ? 1600 : null,
          );
    return img.encodeJpg(small, quality: 85);
  }

  static void update(BoardItem item) {
    items.value = [for (final i in items.value) i.id == item.id ? item : i];
    _saveSoon();
  }

  /// The board's own background photo (design 7).
  static const backgroundFile = '$dir/background.jpg';

  /// Bumped when [backgroundFile] changes, to show the new one.
  static final backgroundChanged = ValueNotifier(0);

  /// Makes [bytes] the board's background photo; false if it isn't one.
  static Future<bool> setBackgroundPhoto(Uint8List bytes) async {
    final jpeg = await Isolate.run(() => _shrink(bytes));
    if (jpeg == null) return false;
    await FileManager.writeFile(backgroundFile, jpeg, awaitWrite: true);
    await FileImage(FileManager.getFile(backgroundFile)).evict();
    backgroundChanged.value++;
    return true;
  }

  /// Takes everything off the board.
  static void removeAll() {
    for (final item in List.of(items.value)) {
      remove(item);
    }
  }

  /// Takes [item] off the board (and deletes its photo).
  static void remove(BoardItem item) {
    _deleted.add(item.id);
    items.value = [...items.value]..removeWhere((i) => i.id == item.id);
    if (item.photo case final photo?) {
      unawaited(FileManager.deleteFile(photo));
    }
    _saveSoon();
  }

  /// Moves the item at [from] to [to], for dragging.
  static void reorder(int from, int to) {
    final list = [...items.value];
    final item = list.removeAt(from);
    list.insert(to.clamp(0, list.length), item);
    items.value = [
      for (final (i, item) in list.indexed) item.copyWith(order: i),
    ];
    _saveSoon();
  }
}
