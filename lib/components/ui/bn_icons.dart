import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_drawing/path_drawing.dart';

/// The app's icons: one line style everywhere (Lucide, round caps and joins).
abstract final class BnIcons {
  // home
  static const desk = LucideIcons.house;
  static const recent = LucideIcons.clock;
  static const favorites = LucideIcons.star;
  static const whiteboard = LucideIcons.pencil;
  static const add = LucideIcons.plus;
  static const search = LucideIcons.search;
  static const synced = LucideIcons.cloudCheck;
  static const cloud = LucideIcons.cloud;
  static const cloudOff = LucideIcons.cloudOff;
  static const folder = LucideIcons.folder;
  static const folderPlus = LucideIcons.folderPlus;
  static const folderOpen = LucideIcons.folderOpen;
  static const file = LucideIcons.fileText;
  static const selectCircle = LucideIcons.circleCheck;
  static const palette = LucideIcons.palette;
  static const open = LucideIcons.bookOpen;
  static const listChecks = LucideIcons.listChecks;
  static const camera = LucideIcons.camera;
  static const notebook = LucideIcons.notebook;
  static const photo = LucideIcons.image;
  static const trash = LucideIcons.trash2;
  static const settings = LucideIcons.settings;
  static const help = LucideIcons.circleQuestionMark;
  static const sort = LucideIcons.arrowUpDown;
  static const grid = LucideIcons.layoutGrid;
  static const list = LucideIcons.list;
  static const user = LucideIcons.user;

  // actions
  static const back = LucideIcons.chevronLeft;
  static const forward = LucideIcons.chevronRight;
  static const down = LucideIcons.chevronDown;
  static const up = LucideIcons.chevronUp;
  static const close = LucideIcons.x;
  static const check = LucideIcons.check;
  static const more = LucideIcons.ellipsis;
  static const share = LucideIcons.share;
  static const copy = LucideIcons.copy;
  static const rename = LucideIcons.pencilLine;
  static const move = LucideIcons.folderInput;
  static const export = LucideIcons.upload;
  static const download = LucideIcons.download;
  static const undo = LucideIcons.undo2;
  static const redo = LucideIcons.redo2;
  static const minus = LucideIcons.minus;
  static const lock = LucideIcons.lock;
  static const pin = LucideIcons.pin;
  static const bell = LucideIcons.bell;
  static const restore = LucideIcons.rotateCcw;

  // editor
  static const pages = LucideIcons.columns2;
  static const addPage = LucideIcons.filePlus;
  static const hand = LucideIcons.hand;
  static const handOff = LucideIcons.handMetal;
  static const insert = LucideIcons.plus;
  static const timer = LucideIcons.timer;
  static const ruler = LucideIcons.ruler;
  static const zoomWindow = LucideIcons.zoomIn;
  static const mic = LucideIcons.mic;
  static const text = LucideIcons.type;
  static const sticky = LucideIcons.stickyNote;
  static const sticker = LucideIcons.sticker;
  static const layers = LucideIcons.layers;
}

/// The editor's tools, drawn from the design's own 24×24 paths.
abstract final class BnToolIcons {
  // Option B (design 11): one grey outline style, each tool its own shape;
  // the pens show their ink colour as a bar under them (see BnToolButton).
  static const lasso =
      'M12 4.5c4.4 0 8 2.7 8 6s-3.6 6-8 6c-1.4 0-2.7-.3-3.8-.8'
      'M4 10.5c0-3 3.6-6 8-6M5.6 16.4L4 20l3.8-1';
  static const pen = fountain;
  static const fountain =
      'M14.5 3.5l6 6-9.5 9.5H5v-6zM5 19l4.2-4.2'
      'M9.2 13.5a1.3 1.3 0 1 0 2.6 0a1.3 1.3 0 1 0-2.6 0';
  static const ballpoint =
      'M17 3.5l3.5 3.5L8 19.5 3.5 20.5 4.5 16zM14.5 6l3.5 3.5';
  static const brush =
      'M19.5 3.5c.9.9.4 2.8-1.6 4.8L12.5 13.7l-2.2-2.2 5.4-5.4'
      'c2-2 3.9-2.5 3.8-2.6zM10.3 11.5l2.2 2.2c-.4 3.6-3 6-6.8 6 0-3.8 1.9-6.9 4.6-8.2';
  static const calligraphy =
      'M15 3l6 6-8 8-6 1 1-6zM7 18l-3 3M11.5 10.5l2 2';
  static const highlighter = 'M14 4l6 6-7.5 7.5h-6v-6zM6.5 17.5L4 20h6';
  static const pencil = 'M16 4l4 4L8 20H4v-4zM4 16l4 4M13.5 6.5l4 4';
  static const drawShapes = 'M3 14c2.2-6 4.6 6 7 0M13.5 6.5l7 1.2-1.4 8.6-7-1.2z';
  static const tape = 'M3 9.5l17-3 1 5.5-17 3zM9 8.5l1 5.5M15 7.4l1 5.5';
  static const shapes =
      'M3.5 10h10v10h-10zM20.5 8.5a5 5 0 1 1-10 0a5 5 0 1 1 10 0';
  static const eraser =
      'M8.5 19.5L3.5 14.5 13.5 4.5l6 6-9 9zM8.5 9.5l6 6M8.5 19.5H20';

  /// A ring; the dock puts a red dot in it.
  static const laser = 'M5 12a7 7 0 1 0 14 0a7 7 0 1 0-14 0';
  static const logo = 'M5 19l3.5-1L19 7.5 16.5 5 6 15.5z';
}

/// A folder's icon, stored by [key] in its style file.
class BnFolderIcon {
  const new(this.key, this.label, this.path);

  final String key, label;

  /// 24×24 path data.
  final String path;

  static const all = [
    BnFolderIcon(
      'book',
      'Book',
      'M4 5a2 2 0 0 1 2-2h13v16H6a2 2 0 0 0-2 2zM4 19V5M8 7h7',
    ),
    BnFolderIcon(
      'flask',
      'Science',
      'M9 3h6M10 3v6l-5 9a2 2 0 0 0 2 3h10a2 2 0 0 0 2-3l-5-9V3M7.5 15h9',
    ),
    BnFolderIcon(
      'calc',
      'Maths',
      'M6 3h12v18H6zM9 7h6M9 12h.01M12 12h.01M15 12h.01M9 16h.01M12 16h.01M15 16h.01',
    ),
    BnFolderIcon('work', 'Work', 'M3 8h18v11H3zM9 8V5h6v3M3 13h18'),
    BnFolderIcon(
      'heart',
      'Heart',
      'M12 20s-8-5-8-11a4.5 4.5 0 0 1 8-2.5A4.5 4.5 0 0 1 20 9c0 6-8 11-8 11z',
    ),
    BnFolderIcon('plane', 'Travel', 'M2 13l20-8-6 16-4-6-6-2zM12 15l4-4'),
    BnFolderIcon(
      'music',
      'Music',
      'M9 18V5l11-2v13M9 18a3 3 0 1 1-6 0a3 3 0 1 1 6 0M20 16a3 3 0 1 1-6 0a3 3 0 1 1 6 0',
    ),
    BnFolderIcon('code', 'Code', 'M8 7l-5 5 5 5M16 7l5 5-5 5M14 4l-4 16'),
    BnFolderIcon(
      'palette',
      'Art',
      'M12 3a9 9 0 1 0 0 18c1.5 0 2-1 2-2s-1-2 0-3 2 0 3 0a4 4 0 0 0 4-4c0-5-4-9-9-9zM7.5 11h.01M10 7h.01M15 7h.01',
    ),
    BnFolderIcon(
      'cap',
      'Study',
      'M2 9l10-5 10 5-10 5zM6 11v5c3 2 9 2 12 0v-5M22 9v6',
    ),
    BnFolderIcon('pen', 'Writing', 'M4 20l1-5L16 4l4 4L9 19zM14 6l4 4'),
    BnFolderIcon(
      'star',
      'Star',
      'M12 4l2.5 5.2 5.5.8-4 3.9.9 5.6L12 16.9 7.1 19.5l.9-5.6-4-3.9 5.5-.8z',
    ),
    BnFolderIcon(
      'home',
      'Home',
      'M4 11l8-7 8 7v9a1 1 0 0 1-1 1h-4v-6h-6v6H5a1 1 0 0 1-1-1z',
    ),
    BnFolderIcon(
      'camera',
      'Photos',
      'M4 8h3l2-3h6l2 3h3v11H4zM8.5 13a3.5 3.5 0 1 0 7 0a3.5 3.5 0 1 0-7 0',
    ),
    BnFolderIcon(
      'leaf',
      'Nature',
      'M5 19c0-9 6-14 15-14 0 9-5 15-14 15zM5 19l8-8',
    ),
    BnFolderIcon(
      'globe',
      'World',
      'M12 3a9 9 0 1 0 0 18a9 9 0 1 0 0-18M3 12h18M12 3c3 3 3 15 0 18M12 3c-3 3-3 15 0 18',
    ),
  ];

  /// The icon stored as [key], or null for none or an unknown key.
  static BnFolderIcon? fromKey(String? key) {
    if (key == null) return null;
    for (final icon in all) {
      if (icon.key == key) return icon;
    }
    return null;
  }
}

/// A line icon drawn from 24×24 SVG path data, in the same style as
/// [BnIcons]: round caps and joins, [strokeWidth] on the 24 grid.
class BnPathIcon extends StatelessWidget {
  const new(
    this.path, {
    super.key,
    this.size = 20,
    this.color,
    this.strokeWidth = 1.8,
    this.dashed = false,
  });

  final String path;
  final double size;

  /// Defaults to the surrounding [IconTheme]'s colour.
  final Color? color;
  final double strokeWidth;

  /// Drawn in short dashes (the lasso).
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? IconTheme.of(context).color!;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _PathIconPainter(path, color, strokeWidth, dashed),
      ),
    );
  }
}

class _PathIconPainter extends CustomPainter {
  new(this.data, this.color, this.strokeWidth, this.dashed);

  final String data;
  final Color color;
  final double strokeWidth;
  final bool dashed;

  /// Parsed once per path for the whole app.
  static final _paths = <String, Path>{};
  static final _dashedPaths = <String, Path>{};

  Path get _path {
    final plain = _paths[data] ??= parseSvgPathData(data);
    if (!dashed) return plain;
    return _dashedPaths[data] ??= dashPath(
      plain,
      dashArray: CircularIntervalList([2.5, 2.5]),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 24;
    canvas.scale(scale);
    canvas.drawPath(
      _path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_PathIconPainter old) =>
      old.data != data ||
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.dashed != dashed;
}
