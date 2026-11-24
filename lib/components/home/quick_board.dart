import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:badnotes/components/home/quick_ink.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/data/prefs.dart';
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
    this.labels = const [],
    this.due,
    this.link,
    this.decoColor,
    this.noteShape = 0,
  });

  /// The note's labels, for the board's filter chips.
  final List<String> labels;

  /// When it's due, shown on the card (red from that day on).
  final DateTime? due;

  /// A notebook it links to, by its path.
  final String? link;

  /// The pin's, tape's or clip's colour (ARGB); null for its own.
  final int? decoColor;

  /// A note's paper: 0 square, 1 rounded, 2 torn edge, 3 index card.
  final int noteShape;

  /// Due today or before.
  bool get dueNow {
    final d = due;
    if (d == null) return false;
    final now = DateTime.now();
    return d.isBefore(DateTime(now.year, now.month, now.day + 1));
  }

  /// Where it is on the board, in units of a board 1000 wide; null until
  /// it has a place (it gets the first free one).
  final Rect? box;

  /// How far it's turned, in radians.
  final double angle;

  /// Drawn over the ones with a lower [z].
  final int z;

  /// 0 nothing on it, 1 a pin, 2 a strip of tape, 3 a paper clip.
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

  /// The notes' colours: butter, peach, sky, lilac, mint, then white,
  /// rose and sand. Older app versions clamp an index they don't know.
  static const colors = [
    BnColors.noteButter,
    BnColors.notePeach,
    BnColors.noteSky,
    BnColors.noteLilac,
    BnColors.noteMint,
    Color(0xFFFFFFFF),
    Color(0xFFF8DDE6),
    Color(0xFFF7ECCF),
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
    List<String>? labels,
    DateTime? Function()? due,
    String? Function()? link,
    int? Function()? decoColor,
    int? noteShape,
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
    labels: labels ?? this.labels,
    due: due == null ? this.due : due(),
    link: link == null ? this.link : link(),
    decoColor: decoColor == null ? this.decoColor : decoColor(),
    noteShape: noteShape ?? this.noteShape,
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
    if (labels.isNotEmpty) 'lb': labels,
    if (due case final d?) 'due': d.millisecondsSinceEpoch,
    'ln': ?link,
    'dc': ?decoColor,
    if (noteShape != 0) 'ns': noteShape,
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
      labels: [
        for (final l in (json['lb'] as List? ?? const []))
          if (l is String) l,
      ],
      due: json['due'] is int
          ? DateTime.fromMillisecondsSinceEpoch(json['due'] as int)
          : null,
      link: json['ln'] as String?,
      decoColor: json['dc'] as int?,
      noteShape: json['ns'] as int? ?? 0,
    );
  }
}

/// The quick notes board: `/.board/board.json` and the photos beside it,
/// written through the file manager so they sync. Shown at once, saved a
/// moment later; another device's changes are merged by id, newest wins.
abstract final class QuickBoard {
  static const dir = '/.board';
  static const _file = '$dir/board.json';

  /// The board's look (pattern, colour, photo fade), synced like the
  /// board; the prefs keep a copy for this device.
  static const _settingsFile = '$dir/settings.json';

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
      if (event.filePath == _settingsFile && !_writingSettings) {
        unawaited(_readSettings());
      }
    });
    if (_loaded) return;
    _loaded = true;
    await _readSettings();
    for (final s in [
      stows.boardPattern,
      stows.boardColor,
      stows.boardPhotoFade,
    ]) {
      s.addListener(_saveSettingsSoon);
    }
    await _read();
  }

  static var _applyingSettings = false, _writingSettings = false;
  static Timer? _settingsTimer;

  static Future<void> _readSettings() async {
    if (!FileManager.doesFileExist(_settingsFile)) return;
    final bytes = await FileManager.readFile(_settingsFile, retries: 0);
    if (bytes == null) return;
    try {
      final json = jsonDecode(utf8.decode(bytes));
      if (json is! Map) return;
      _applyingSettings = true;
      if (json['pattern'] case final String p) stows.boardPattern.value = p;
      if (json['color'] case final int c) stows.boardColor.value = c;
      if (json['fade'] case final num f) {
        stows.boardPhotoFade.value = f.toDouble();
      }
    } on FormatException {
      return;
    } finally {
      _applyingSettings = false;
    }
  }

  static void _saveSettingsSoon() {
    if (_applyingSettings) return;
    _settingsTimer?.cancel();
    _settingsTimer = Timer(const Duration(milliseconds: 600), () async {
      _writingSettings = true;
      try {
        await FileManager.writeFile(
          _settingsFile,
          utf8.encode(
            jsonEncode({
              'pattern': stows.boardPattern.value,
              'color': stows.boardColor.value,
              'fade': stows.boardPhotoFade.value,
            }),
          ),
          awaitWrite: true,
        );
      } finally {
        _writingSettings = false;
      }
    });
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

  /// Takes everything off the board; gives what was on it, for [restore].
  static List<BoardItem> removeAll() {
    final all = List.of(items.value);
    for (final item in all) {
      remove(item);
    }
    return all;
  }

  /// Photos of unpinned items, deleted once undo is no longer offered.
  static final _photoDeletes = <String, Timer>{};

  /// How long an unpinned photo's file is kept, for undo.
  static const undoWindow = Duration(seconds: 8);

  /// Takes [item] off the board; its photo is deleted after [undoWindow]
  /// unless [restore] puts it back.
  // ponytail: a photo unpinned just before the app closes stays on disk;
  // sweep /.board for files no item points to if that ever matters.
  static void remove(BoardItem item) {
    _deleted.add(item.id);
    items.value = [...items.value]..removeWhere((i) => i.id == item.id);
    if (item.photo case final photo?) {
      _photoDeletes[item.id]?.cancel();
      _photoDeletes[item.id] = Timer(undoWindow, () {
        _photoDeletes.remove(item.id);
        unawaited(FileManager.deleteFile(photo));
      });
    }
    _saveSoon();
  }

  /// Puts unpinned [removed] items back, as they were.
  static void restore(List<BoardItem> removed) {
    final back = [
      for (final item in removed)
        if (!items.value.any((i) => i.id == item.id)) item,
    ];
    for (final item in back) {
      _deleted.remove(item.id);
      _photoDeletes.remove(item.id)?.cancel();
    }
    items.value = [...items.value, ...back]
      ..sort((a, b) => a.order.compareTo(b.order));
    _saveSoon();
  }

  /// Every label used on the board, A to Z.
  static List<String> get labels =>
      {for (final i in items.value) ...i.labels}.toList()..sort();

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
