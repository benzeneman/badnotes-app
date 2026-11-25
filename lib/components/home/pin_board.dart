import 'dart:math' as math;

import 'package:badnotes/components/home/board_background.dart';
import 'package:badnotes/components/home/pinch_zoom.dart';
import 'package:badnotes/components/home/quick_board.dart';
import 'package:badnotes/components/home/quick_ink.dart';
import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The quick notes as a cork board: each note and photo where it was put,
/// at its size and angle. Tap one to open it; hold it to pick it up, then
/// drag, pinch and twist it, or use its handles and bar.
///
/// Laid out on a board 1000 units wide, so it looks the same in the desk's
/// panel and full screen.
class PinBoard extends StatefulWidget {
  const new({
    super.key,
    required this.items,
    required this.openNote,
    required this.openPhoto,
    this.minHeight = 400,
    this.zoomable = false,
    this.matches,
  });

  final List<BoardItem> items;
  final void Function(BuildContext context, BoardItem item) openNote;
  final void Function(BuildContext context, BoardItem item) openPhoto;

  /// The board is at least this tall on screen.
  final double minHeight;

  /// Pinch to zoom, pan every way, a zoom pill and a map (the full-screen
  /// board). Off on the desk, where the board scrolls up and down.
  final bool zoomable;

  /// What a search or filter shows; the rest is dimmed. Null shows all.
  final bool Function(BoardItem item)? matches;

  static const width = 1000.0;

  /// The first free place for a [size] box on a board holding [taken].
  static Rect freeSpot(Size size, List<Rect> taken) {
    const margin = 24.0, step = 40.0;
    for (var y = margin; ; y += step) {
      for (var x = margin; x + size.width <= width - margin; x += step) {
        final spot = Offset(x, y) & size;
        if (!taken.any((t) => t.inflate(12).overlaps(spot))) return spot;
      }
    }
  }

  /// A new item's size on the board.
  static Size sizeOf(BoardItem item) {
    if (!item.isPhoto) return const Size(420, 360);
    final aspect = item.aspect > 0 ? item.aspect : 4 / 3;
    return Size(440, 440 / aspect);
  }

  @override
  State<PinBoard> createState() => _PinBoardState();
}

class _PinBoardState extends State<PinBoard> {
  String? _selected;

  /// The board's stack, to find where a finger is on it.
  final _stackKey = GlobalKey();

  /// What a pinch or twist started from.
  Rect? _startBox;
  double _startAngle = 0;

  /// Items given a place in this build, saved once it's drawn.
  final _placed = <BoardItem>[];

  /// The zoom and pan of a [PinBoard.zoomable] board. Only how it is
  /// looked at: nothing of it is saved.
  final _view = TransformationController();
  static const _minZoom = 0.5, _maxZoom = 3.0;

  /// Whether the gesture going on has panned or zoomed the board.
  final _moved = ValueNotifier(false);

  /// Pointers that went down on the picked-up item or its handles: those
  /// move the item, not the board.
  final _claimed = <int>{};

  @override
  void dispose() {
    _view.dispose();
    _moved.dispose();
    super.dispose();
  }

  /// Zooms to [zoom], keeping [focus] (a point on the screen) still.
  void _zoomTo(double zoom, Offset focus) {
    final current = _view.value;
    final f = zoom.clamp(_minZoom, _maxZoom) / current.getMaxScaleOnAxis();
    _view.value = Matrix4.identity()
      ..translateByDouble(focus.dx, focus.dy, 0, 1)
      ..scaleByDouble(f, f, 1, 1)
      ..translateByDouble(-focus.dx, -focus.dy, 0, 1)
      ..multiply(current);
  }

  /// The whole board on the screen, or full width if it's short.
  void _fit(Size viewport, Size board) {
    final s = math
        .min(viewport.width / board.width, viewport.height / board.height)
        .clamp(_minZoom, 1.0);
    _view.value = Matrix4.identity()
      ..translateByDouble((viewport.width - board.width * s) / 2, 0, 0, 1)
      ..scaleByDouble(s, s, 1, 1);
  }

  Offset? _doubleTapAt;

  /// Every item with a place: the ones without one get the first free spot.
  List<BoardItem> _withPlaces() {
    final taken = [
      for (final i in widget.items)
        if (i.box case final b?) b,
    ];
    _placed.clear();
    final out = <BoardItem>[];
    for (final item in widget.items) {
      if (item.box != null) {
        out.add(item);
        continue;
      }
      final spot = PinBoard.freeSpot(PinBoard.sizeOf(item), taken);
      taken.add(spot);
      final placed = item.copyWith(box: () => spot);
      _placed.add(placed);
      out.add(placed);
    }
    if (_placed.isNotEmpty) {
      final save = List.of(_placed);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final item in save) {
          QuickBoard.update(item);
        }
      });
    }
    return out..sort((a, b) => a.z.compareTo(b.z));
  }

  BoardItem? _item(String id) =>
      widget.items.where((i) => i.id == id).firstOrNull;

  void _change(String id, BoardItem Function(BoardItem) change) {
    final item = _item(id);
    if (item != null) QuickBoard.update(change(item));
  }

  void _select(BoardItem item) {
    if (_moved.value) return;
    HapticFeedback.mediumImpact();
    setState(() => _selected = item.id);
    // picked up: to the front
    if (item.z < QuickBoard.topZ) {
      QuickBoard.update(item.copyWith(z: QuickBoard.topZ + 1));
    }
  }

  /// [child]'s pointers move the picked-up item, not the board.
  Widget _claim(Widget child) => !widget.zoomable
      ? child
      : Listener(onPointerDown: (e) => _claimed.add(e.pointer), child: child);

  @override
  Widget build(BuildContext context) {
    final items = _withPlaces();
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = constraints.maxWidth / PinBoard.width;
        final bottom = items.fold<double>(
          0,
          (b, i) => math.max(b, i.box!.bottom + 120),
        );
        final height = math.max(widget.minHeight, bottom * scale);
        final selected = _selected == null ? null : _item(_selected!);
        final board = SizedBox(
          width: constraints.maxWidth,
          height: height,
          child: Stack(
            key: _stackKey,
            clipBehavior: Clip.none,
            children: [
              // the board's own background (design 7); a tap on it puts the
              // picked-up item down, a double tap zooms
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _selected = null),
                  onDoubleTapDown: widget.zoomable
                      ? (d) => _doubleTapAt = MatrixUtils.transformPoint(
                          _view.value,
                          d.localPosition,
                        )
                      : null,
                  onDoubleTap: widget.zoomable
                      ? () => _zoomTo(
                          _view.value.getMaxScaleOnAxis() > 1.5 ? 1 : 2,
                          _doubleTapAt ?? Offset.zero,
                        )
                      : null,
                  child: const BoardBackground(),
                ),
              ),
              for (final item in items) _item_(context, item, scale),
              if (selected?.box != null)
                ..._handles(
                  context,
                  items.firstWhere((i) => i.id == selected!.id),
                  scale,
                ),
            ],
          ),
        );
        if (!widget.zoomable) {
          return SingleChildScrollView(
            // a picked-up item moves with the finger, not the board
            physics: selected != null
                ? const NeverScrollableScrollPhysics()
                : null,
            child: board,
          );
        }
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        final boardSize = Size(constraints.maxWidth, height);
        final pad = MediaQuery.paddingOf(context).bottom;
        return Stack(
          children: [
            Positioned.fill(
              child: PinchZoom(
                view: _view,
                minScale: _minZoom,
                maxScale: _maxZoom,
                panWithOneFinger: true,
                content: boardSize,
                moved: _moved,
                ignore: _claimed.remove,
                child: board,
              ),
            ),
            Positioned(
              left: 16,
              bottom: 16 + pad,
              child: _MiniMap(
                items: items,
                view: _view,
                viewport: viewport,
                board: boardSize,
                scale: scale,
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16 + pad,
              child: _ZoomPill(
                view: _view,
                zoomOut: () => _zoomTo(
                  _view.value.getMaxScaleOnAxis() / 1.25,
                  viewport.center(Offset.zero),
                ),
                zoomIn: () => _zoomTo(
                  _view.value.getMaxScaleOnAxis() * 1.25,
                  viewport.center(Offset.zero),
                ),
                actualSize: () => _view.value = Matrix4.identity(),
                fit: () => _fit(viewport, boardSize),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _item_(BuildContext context, BoardItem item, double scale) {
    final box = item.box!;
    final picked = item.id == _selected;
    final shown = widget.matches?.call(item) ?? true;
    // its own layer: zooming or moving another note doesn't draw it again
    Widget card = RepaintBoundary(
      child: _PinnedCard(item: item, scale: scale),
    );
    if (!shown) {
      card = IgnorePointer(child: Opacity(opacity: 0.2, child: card));
    }
    return Positioned(
      key: ValueKey(item.id),
      left: box.left * scale,
      top: box.top * scale,
      width: box.width * scale,
      height: box.height * scale,
      child: Transform.rotate(
        angle: item.angle,
        child: picked
            ? _claim(
                GestureDetector(
                  // one finger drags, two pinch and twist
                  onScaleStart: (_) {
                    _startBox = item.box;
                    _startAngle = item.angle;
                  },
                  onScaleUpdate: (d) {
                    final start = _startBox;
                    if (start == null) return;
                    final current = _item(item.id)?.box ?? start;
                    final moved = current.center + d.focalPointDelta / scale;
                    var size = start.size;
                    if (d.pointerCount > 1) {
                      size = start.size * d.scale.clamp(0.3, 4.0);
                    }
                    _change(
                      item.id,
                      (i) => i.copyWith(
                        box: () => Rect.fromCenter(
                          center: moved,
                          width: size.width,
                          height: size.height,
                        ),
                        angle: d.pointerCount > 1
                            ? _snap(_startAngle + d.rotation)
                            : i.angle,
                      ),
                    );
                  },
                  onTap: () => _open(context, item),
                  child: card,
                ),
              )
            : GestureDetector(
                onTap: () => _open(context, item),
                onLongPress: () => _select(item),
                child: card,
              ),
      ),
    );
  }

  void _open(BuildContext context, BoardItem item) {
    // the end of a pinch that began on it
    if (_moved.value) return;
    item.isPhoto
        ? widget.openPhoto(context, item)
        : widget.openNote(context, item);
  }

  /// Upright when close to it.
  static double _snap(double angle) {
    final a = math.atan2(math.sin(angle), math.cos(angle));
    return a.abs() < 4 * math.pi / 180 ? 0 : a;
  }

  /// The picked-up item's corner and turn handles, and its bar.
  List<Widget> _handles(BuildContext context, BoardItem item, double scale) {
    final box = item.box!;
    final center = box.center * scale;
    final half = Offset(box.width, box.height) * scale / 2;
    Offset turned(Offset local) {
      final c = math.cos(item.angle), s = math.sin(item.angle);
      return center +
          Offset(local.dx * c - local.dy * s, local.dx * s + local.dy * c);
    }

    final corner = turned(Offset(half.dx + 6, half.dy + 6));
    final knob = turned(Offset(0, -half.dy - 34));
    const dot = 26.0;
    final colors = BadNotesColors.of(context);
    Widget handle(Offset at, Widget child, GestureDragUpdateCallback onDrag) =>
        Positioned(
          left: at.dx - dot / 2,
          top: at.dy - dot / 2,
          child: _claim(
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (_) => _startBox = item.box,
              onPanUpdate: onDrag,
              child: SizedBox.square(
                dimension: dot,
                child: Center(child: child),
              ),
            ),
          ),
        );

    // the bar under the item, level
    final aabbBottom = [
      for (final p in [
        Offset(-half.dx, -half.dy),
        Offset(half.dx, -half.dy),
        Offset(half.dx, half.dy),
        Offset(-half.dx, half.dy),
      ])
        turned(p).dy,
    ].reduce(math.max);

    return [
      handle(
        corner,
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: colors.accent, width: 2),
          ),
        ),
        (d) {
          // grows from its top-left corner, along its own turned sides
          final c = math.cos(-item.angle), s = math.sin(-item.angle);
          final delta =
              Offset(
                d.delta.dx * c - d.delta.dy * s,
                d.delta.dx * s + d.delta.dy * c,
              ) /
              scale;
          _change(item.id, (i) {
            final b = i.box!;
            var w = math.max(80.0, b.width + delta.dx);
            var h = math.max(60.0, b.height + delta.dy);
            if (i.isPhoto) h = w * b.height / b.width; // keeps its shape
            return i.copyWith(box: () => Rect.fromLTWH(b.left, b.top, w, h));
          });
        },
      ),
      handle(
        knob,
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: colors.accent,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
        (d) {
          final box =
              _stackKey.currentContext?.findRenderObject() as RenderBox?;
          if (box == null) return;
          final p = box.globalToLocal(d.globalPosition);
          final angle = (p - center).direction + math.pi / 2;
          _change(item.id, (i) => i.copyWith(angle: _snap(angle)));
        },
      ),
      Positioned(
        left: 0,
        right: 0,
        top: aabbBottom + 14,
        child: Center(
          child: _claim(
            _ItemBar(
              item: item,
              onDone: () => setState(() => _selected = null),
            ),
          ),
        ),
      ),
    ];
  }
}

/// A note or photo as pinned: its frame and look, a pin, tape or clip, and
/// its due date, labels and linked notebook.
class _PinnedCard extends StatelessWidget {
  const new({required this.item, required this.scale});

  final BoardItem item;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final body = item.isPhoto ? _photo() : _note();
    final round = item.isPhoto && item.shape == 2;
    final torn = !item.isPhoto && item.noteShape == 2;
    final shadow = BoxShadow(
      color: const Color(0x33000000),
      blurRadius: 10 * _deco,
      offset: Offset(0, 4 * _deco),
    );
    final dc = item.decoColor == null ? null : Color(item.decoColor!);
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        if (torn)
          // a shadow that follows the torn edge
          PhysicalShape(
            clipper: const _TornEdge(),
            clipBehavior: Clip.antiAlias,
            color: item.paper,
            elevation: 3,
            shadowColor: Colors.black54,
            child: body,
          )
        else
          DecoratedBox(
            decoration: BoxDecoration(
              shape: round ? BoxShape.circle : BoxShape.rectangle,
              borderRadius: round ? null : BorderRadius.circular(_radius()),
              boxShadow: [shadow],
            ),
            child: body,
          ),
        if (_chips(context) case final chips?)
          Positioned(
            left: 10 * _deco,
            right: 10 * _deco,
            bottom: (torn ? 18 : 10) * _deco,
            child: chips,
          ),
        if (item.deco == 1)
          Positioned(
            top: -7 * _deco,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 16 * _deco,
                height: 16 * _deco,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: const Alignment(-0.35, -0.35),
                    colors: dc == null
                        ? const [Color(0xFFFF8A80), Color(0xFFD93A2B)]
                        : [Color.lerp(dc, Colors.white, 0.45)!, dc],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x55000000),
                      blurRadius: 3,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (item.deco == 2)
          Positioned(
            top: -11 * _deco,
            left: 0,
            right: 0,
            child: Center(
              child: Transform.rotate(
                angle: -0.07,
                child: Container(
                  width: 78 * _deco,
                  height: 22 * _deco,
                  decoration: BoxDecoration(
                    color: (dc ?? const Color(0xFFFFD678)).withValues(
                      alpha: 0.72,
                    ),
                    boxShadow: const [
                      BoxShadow(color: Color(0x22000000), blurRadius: 2),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (item.deco == 3)
          Positioned(
            top: -16 * _deco,
            left: 22 * _deco,
            width: 18 * _deco,
            height: 48 * _deco,
            child: CustomPaint(
              painter: PaperClipPainter(dc ?? const Color(0xFF8E959E)),
            ),
          ),
      ],
    );
  }

  /// How big a pin or tape is: in step with the board, so on the desk's
  /// small board it isn't as big as the note it's on.
  double get _deco => scale.clamp(0.35, 1.5);

  double _radius() {
    final side = math.min(item.box!.width, item.box!.height) * scale;
    if (!item.isPhoto) return item.noteShape == 1 ? 18 * scale : 4;
    return switch (item.shape) {
      0 => 0,
      _ => item.corners * side / 2,
    };
  }

  /// Due date and labels, small along the bottom.
  Widget? _chips(BuildContext context) {
    final due = item.due;
    if (due == null && item.labels.isEmpty) return null;
    final font = (20 * scale).clamp(8.0, 14.0);
    Widget chip(String text, {Color? bg, Color? fg, VoidCallback? onTap}) {
      final c = Container(
        padding: EdgeInsets.symmetric(horizontal: font * 0.6, vertical: 2),
        decoration: BoxDecoration(
          color: bg ?? const Color(0x14000000),
          borderRadius: const BorderRadius.all(Radius.circular(99)),
        ),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: font,
            fontWeight: FontWeight.w600,
            color: fg ?? BnColors.text2,
          ),
        ),
      );
      return onTap == null ? c : GestureDetector(onTap: onTap, child: c);
    }

    return Wrap(
      spacing: 4,
      runSpacing: 3,
      children: [
        if (due != null)
          chip(
            'Due ${dueLabel(due)}',
            bg: item.dueNow ? BnColors.danger : null,
            fg: item.dueNow ? Colors.white : null,
          ),
        for (final l in item.labels) chip('#$l'),
      ],
    );
  }

  Widget _note() {
    final lines = [
      if (item.text.isNotEmpty) item.text,
      for (final c in item.checklist) '${c.done ? '☑' : '☐'} ${c.text}',
    ].join('\n');
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: item.paper,
        borderRadius: item.noteShape == 2
            ? null
            : BorderRadius.circular(_radius()),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (item.noteShape == 3) const CustomPaint(painter: _IndexLines()),
          Padding(
            padding: EdgeInsets.all(28 * scale),
            child: Text(
              lines,
              overflow: TextOverflow.fade,
              style: TextStyle(
                fontFamily: 'Caveat',
                fontSize: 46 * scale,
                fontWeight: FontWeight.w700,
                height: 1.05,
                color: BnColors.text,
              ),
            ),
          ),
          if (item.ink.isNotEmpty)
            CustomPaint(painter: BoardInkPainter(item.ink)),
        ],
      ),
    );
  }

  Widget _photo() {
    // decoded no bigger than it's shown (at 2x for zooming in), not at the
    // photo's full size
    final decode = (item.box!.width * scale * 2).clamp(200.0, 900.0).round();
    final image = Image(
      image: ResizeImage(
        FileImage(FileManager.getFile(item.photo!)),
        width: decode,
        allowUpscaling: false,
      ),
      fit: BoxFit.fill,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (context, _, _) =>
          const ColoredBox(color: Color(0xFFDDDDDD)),
    );
    final crop = item.crop;
    // not cropped, or its shape not known yet: fill the frame
    final shown = crop == const Rect.fromLTRB(0, 0, 1, 1) || item.aspect == 0
        ? SizedBox.expand(
            child: Image(
              image: ResizeImage(
                FileImage(FileManager.getFile(item.photo!)),
                width: decode,
                allowUpscaling: false,
              ),
              fit: BoxFit.cover,
              gaplessPlayback: true,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, _, _) =>
                  const ColoredBox(color: Color(0xFFDDDDDD)),
            ),
          )
        : LayoutBuilder(
            builder: (context, c) {
              final fullW = c.maxWidth / crop.width;
              final fullH = c.maxHeight / crop.height;
              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    left: -crop.left * fullW,
                    top: -crop.top * fullH,
                    width: fullW,
                    height: fullH,
                    child: image,
                  ),
                ],
              );
            },
          );
    return item.shape == 2
        ? ClipOval(child: shown)
        : ClipRRect(
            borderRadius: BorderRadius.circular(_radius()),
            child: shown,
          );
  }
}

/// "Today 18:00", "Tomorrow 9:00" or "12 Mar 9:00".
String dueLabel(DateTime due) {
  final now = DateTime.now();
  final day = DateTime(due.year, due.month, due.day);
  final today = DateTime(now.year, now.month, now.day);
  final time = '${due.hour}:${due.minute.toString().padLeft(2, '0')}';
  final days = day.difference(today).inDays;
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return switch (days) {
    0 => 'Today $time',
    1 => 'Tomorrow $time',
    -1 => 'Yesterday $time',
    _ => '${due.day} ${months[due.month - 1]} $time',
  };
}

/// A note's bottom edge torn off a pad.
class _TornEdge extends CustomClipper<Path> {
  const new();

  @override
  Path getClip(Size size) {
    final tooth = size.width / 18;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - tooth);
    var down = true;
    for (var x = size.width; x > 0; x -= tooth / 2) {
      path.lineTo(
        math.max(0, x - tooth / 2),
        size.height - (down ? 0 : tooth * 0.7),
      );
      down = !down;
    }
    return path..close();
  }

  @override
  bool shouldReclip(_TornEdge old) => false;
}

/// An index card's lines: a red one at the top, blue ones under it.
class _IndexLines extends CustomPainter {
  const new();

  @override
  void paint(Canvas canvas, Size size) {
    final gap = size.height / 9;
    final blue = Paint()
      ..color = const Color(0x553B7DD8)
      ..strokeWidth = math.max(0.6, size.width / 500);
    for (var y = gap * 2; y < size.height - 2; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), blue);
    }
    canvas.drawLine(
      Offset(0, gap * 1.4),
      Offset(size.width, gap * 1.4),
      blue..color = const Color(0x99E05050),
    );
  }

  @override
  bool shouldRepaint(_IndexLines old) => false;
}

/// A paper clip, upright, filling its box.
class PaperClipPainter extends CustomPainter {
  const new(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.13
      ..strokeCap = StrokeCap.round;
    final r = w / 2 - stroke.strokeWidth / 2;
    // the wire: down the right, round the bottom, up the left, round the
    // top, and down the middle
    final path = Path()
      ..moveTo(w / 2 + r, h * 0.3)
      ..lineTo(w / 2 + r, h - r)
      ..arcToPoint(Offset(w / 2 - r, h - r), radius: Radius.circular(r))
      ..lineTo(w / 2 - r, r)
      ..arcToPoint(
        Offset(w / 2 + r * 0.55, r),
        radius: Radius.circular(r * 0.78),
      )
      ..lineTo(w / 2 + r * 0.55, h * 0.72)
      ..arcToPoint(
        Offset(w / 2 - r * 0.25, h * 0.72),
        radius: Radius.circular(r * 0.4),
      )
      ..lineTo(w / 2 - r * 0.25, h * 0.25);
    canvas.drawPath(
      path.shift(const Offset(0, 1.5)),
      Paint()
        ..color = const Color(0x33000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke.strokeWidth,
    );
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(PaperClipPainter old) => old.color != color;
}

/// The colours a pin, tape or clip can be.
const decoColors = <Color>[
  Color(0xFFD93A2B),
  Color(0xFFFFD678),
  Color(0xFF2B4ACB),
  Color(0xFF2F9E77),
  Color(0xFF8E959E),
  Color(0xFF1C1C1E),
];

/// The picked-up item's bar (dark pill): colour, pin style, shape, remind,
/// label, link, front and back, unpin. A photo has crop and frame in
/// place of colour and shape.
class _ItemBar extends StatelessWidget {
  const new({required this.item, required this.onDone});

  final BoardItem item;
  final VoidCallback onDone;

  static void _set(String id, BoardItem Function(BoardItem) change) {
    final now = QuickBoard.items.value.where((i) => i.id == id).firstOrNull;
    if (now != null) QuickBoard.update(change(now));
  }

  /// A popover under [anchor] that shows the item as it changes.
  void _panel(
    BuildContext anchor,
    Widget Function(BuildContext context, BoardItem item) builder,
  ) => showBnPopover<void>(
    anchor: anchor,
    width: 300,
    builder: (context) => ValueListenableBuilder(
      valueListenable: QuickBoard.items,
      builder: (context, items, _) {
        final now = items.where((i) => i.id == item.id).firstOrNull;
        return now == null ? const SizedBox() : builder(context, now);
      },
    ),
  );

  Widget _title(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Text(
      text,
      style: BnType.caption.copyWith(
        color: BadNotesColors.of(context).muted,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  void _colour(BuildContext anchor) => _panel(
    anchor,
    (context, now) => Wrap(
      children: [
        for (final (i, paper) in BoardItem.colors.indexed)
          BnColorDot(
            color: paper,
            size: 26,
            selected: i == now.color,
            onTap: () => _set(now.id, (n) => n.copyWith(color: i)),
          ),
      ],
    ),
  );

  void _pinStyle(BuildContext anchor) => _panel(
    anchor,
    (context, now) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(context, 'On top'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final (d, label) in const [
              (0, 'None'),
              (1, 'Pin'),
              (2, 'Tape'),
              (3, 'Clip'),
            ])
              BnChip(
                label: label,
                selected: now.deco == d,
                onTap: () => _set(now.id, (n) => n.copyWith(deco: d)),
              ),
          ],
        ),
        if (now.deco != 0) ...[
          _title(context, 'Colour'),
          Wrap(
            children: [
              for (final c in decoColors)
                BnColorDot(
                  color: c,
                  size: 24,
                  selected: now.decoColor == c.toARGB32(),
                  onTap: () => _set(
                    now.id,
                    (n) => n.copyWith(decoColor: () => c.toARGB32()),
                  ),
                ),
            ],
          ),
        ],
      ],
    ),
  );

  void _shape(BuildContext anchor) => _panel(
    anchor,
    (context, now) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(context, 'Shape'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: now.isPhoto
              ? [
                  for (final (s, label) in const [
                    (0, 'Square'),
                    (1, 'Rounded'),
                    (2, 'Circle'),
                  ])
                    BnChip(
                      label: label,
                      selected: now.shape == s,
                      onTap: () => _set(
                        now.id,
                        (n) => s == 2 ? _toCircle(n) : n.copyWith(shape: s),
                      ),
                    ),
                ]
              : [
                  for (final (s, label) in const [
                    (0, 'Square'),
                    (1, 'Rounded'),
                    (2, 'Torn edge'),
                    (3, 'Index card'),
                  ])
                    BnChip(
                      label: label,
                      selected: now.noteShape == s,
                      onTap: () =>
                          _set(now.id, (n) => n.copyWith(noteShape: s)),
                    ),
                ],
        ),
        if (now.isPhoto && now.shape == 1)
          Slider(
            value: now.corners,
            onChanged: (v) => _set(now.id, (n) => n.copyWith(corners: v)),
          ),
      ],
    ),
  );

  void _remind(BuildContext anchor) {
    final now = DateTime.now();
    void due(DateTime? at) => _set(item.id, (n) => n.copyWith(due: () => at));
    showAppleMenu(
      anchor,
      anchor: rectOf(anchor),
      entries: [
        AppleMenuItem(
          'Today evening',
          icon: Icons.wb_twilight,
          onTap: () => due(DateTime(now.year, now.month, now.day, 18)),
        ),
        AppleMenuItem(
          'Tomorrow 9 AM',
          icon: Icons.wb_sunny_outlined,
          onTap: () => due(DateTime(now.year, now.month, now.day + 1, 9)),
        ),
        AppleMenuItem(
          'Pick a date…',
          icon: Icons.event,
          onTap: () async {
            final day = await showDatePicker(
              context: anchor,
              initialDate: item.due ?? now,
              firstDate: DateTime(now.year - 1),
              lastDate: DateTime(now.year + 10),
            );
            if (day == null || !anchor.mounted) return;
            final time = await showTimePicker(
              context: anchor,
              initialTime: const TimeOfDay(hour: 9, minute: 0),
            );
            if (time == null) return;
            due(DateTime(day.year, day.month, day.day, time.hour, time.minute));
          },
        ),
        if (item.due != null)
          AppleMenuItem(
            'No reminder',
            icon: Icons.alarm_off,
            onTap: () => due(null),
          ),
      ],
    );
  }

  void _label(BuildContext anchor) {
    void toggle(String label) => _set(
      item.id,
      (n) => n.copyWith(
        labels: n.labels.contains(label)
            ? [...n.labels.where((l) => l != label)]
            : [...n.labels, label],
      ),
    );
    showAppleMenu(
      anchor,
      anchor: rectOf(anchor),
      entries: [
        for (final label in QuickBoard.labels)
          AppleMenuItem(
            label,
            checked: item.labels.contains(label),
            onTap: () => toggle(label),
          ),
        AppleMenuItem(
          'New label…',
          icon: BnIcons.add,
          onTap: () async {
            final field = TextEditingController();
            final ok = await showBnDialog<bool>(
              context: anchor,
              title: 'New label',
              content: TextField(
                controller: field,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'e.g. Work'),
              ),
              actions: const [
                BnDialogAction('Cancel', value: false),
                BnDialogAction('Add', value: true),
              ],
            );
            final label = field.text.trim();
            field.dispose();
            if ((ok ?? false) && label.isNotEmpty) {
              _set(
                item.id,
                (n) => n.labels.contains(label)
                    ? n
                    : n.copyWith(labels: [...n.labels, label]),
              );
            }
          },
        ),
      ],
    );
  }

  void _unpin(BuildContext context) {
    onDone();
    QuickBoard.remove(item);
    showBanner(
      context,
      item.isPhoto ? 'Photo unpinned' : 'Note unpinned',
      actionLabel: 'Undo',
      onAction: () => QuickBoard.restore([item]),
      duration: const Duration(seconds: 5),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget action(
      IconData icon,
      String label,
      void Function(BuildContext anchor) onTap, {
      bool danger = false,
      Widget? leading,
    }) {
      final color = danger ? const Color(0xFFFF7A6E) : Colors.white;
      return Builder(
        builder: (anchor) => Tooltip(
          message: label,
          child: InkWell(
            onTap: () => onTap(anchor),
            borderRadius: const BorderRadius.all(
              Radius.circular(BnRadius.pill),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  leading ?? Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: BnType.body.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      constraints: const BoxConstraints(maxWidth: 760),
      decoration: BoxDecoration(
        color: const Color(0xFF1F1F22),
        borderRadius: const BorderRadius.all(Radius.circular(BnRadius.pill)),
        border: Border.all(color: const Color(0x1AFFFFFF)),
        boxShadow: BnShadows.floating,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.isPhoto)
                action(Icons.crop, 'Crop', (a) => showPhotoCrop(a, item))
              else
                action(
                  Icons.circle,
                  'Colour',
                  _colour,
                  leading: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: item.paper,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              action(Icons.push_pin_outlined, 'Pin style', _pinStyle),
              action(Icons.crop_square, 'Shape', _shape),
              action(Icons.alarm, 'Remind', _remind),
              action(Icons.label_outline, 'Label', _label),
              action(
                Icons.flip_to_front,
                'Front',
                (_) => _set(item.id, (i) => i.copyWith(z: QuickBoard.topZ + 1)),
              ),
              action(Icons.flip_to_back, 'Back', (_) {
                final bottom = QuickBoard.items.value.fold(
                  0,
                  (m, i) => math.min(m, i.z),
                );
                _set(item.id, (i) => i.copyWith(z: bottom - 1));
              }),
              action(BnIcons.trash, 'Unpin', _unpin, danger: true),
            ],
          ),
        ),
      ),
    );
  }

  /// A round frame: the middle square of what's shown, in a square box.
  static BoardItem _toCircle(BoardItem i) {
    final box = i.box!;
    final side = math.min(box.width, box.height);
    var crop = i.crop;
    if (i.aspect > 0) {
      // the crop's size in the photo's own proportions
      final w = crop.width * i.aspect, h = crop.height;
      final s = math.min(w, h);
      crop = Rect.fromCenter(
        center: crop.center,
        width: s / i.aspect,
        height: s,
      );
    }
    return i.copyWith(
      shape: 2,
      crop: crop,
      box: () => Rect.fromCenter(center: box.center, width: side, height: side),
    );
  }
}

/// A small map of the whole board in a corner: the notes as coloured
/// boxes and what's on the screen as a frame. Tap or drag on it to go there.
class _MiniMap extends StatelessWidget {
  const new({
    required this.items,
    required this.view,
    required this.viewport,
    required this.board,
    required this.scale,
  });

  final List<BoardItem> items;
  final TransformationController view;
  final Size viewport, board;

  /// Board units to the board's pixels.
  final double scale;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final k = math.min(150 / board.width, 110 / board.height);
    final size = board * k;
    void jump(Offset at) {
      final s = view.value.getMaxScaleOnAxis();
      final point = at / k;
      final c = viewport.center(Offset.zero);
      view.value = Matrix4.identity()
        ..translateByDouble(c.dx - point.dx * s, c.dy - point.dy * s, 0, 1)
        ..scaleByDouble(s, s, 1, 1);
    }

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.92),
        borderRadius: const BorderRadius.all(Radius.circular(BnRadius.tool)),
        border: Border.all(color: colors.hairline),
        boxShadow: BnShadows.floating,
      ),
      child: GestureDetector(
        onTapDown: (d) => jump(d.localPosition),
        onPanUpdate: (d) => jump(d.localPosition),
        child: CustomPaint(
          size: size,
          painter: _MapPainter(
            items: items,
            view: view,
            viewport: viewport,
            k: k,
            scale: scale,
            frame: colors.accent,
            ground: colors.sunkenSoft,
          ),
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  new({
    required this.items,
    required this.view,
    required this.viewport,
    required this.k,
    required this.scale,
    required this.frame,
    required this.ground,
  }) : super(repaint: view);

  final List<BoardItem> items;
  final TransformationController view;
  final Size viewport;
  final double k, scale;
  final Color frame, ground;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(4)),
      Paint()..color = ground,
    );
    for (final item in items) {
      final b = item.box;
      if (b == null) continue;
      final r = Rect.fromLTWH(
        b.left * scale * k,
        b.top * scale * k,
        b.width * scale * k,
        b.height * scale * k,
      );
      canvas.drawRect(
        r,
        Paint()
          ..color = item.isPhoto ? const Color(0xFFB9BCC4) : item.paper
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        r,
        Paint()
          ..color = const Color(0x33000000)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6,
      );
    }
    // what's on the screen, in the board's pixels
    final inverse = Matrix4.tryInvert(view.value);
    if (inverse == null) return;
    final shown = MatrixUtils.transformRect(inverse, Offset.zero & viewport);
    canvas.drawRect(
      Rect.fromLTRB(
        shown.left * k,
        shown.top * k,
        shown.right * k,
        shown.bottom * k,
      ).intersect(Offset.zero & size),
      Paint()
        ..color = frame
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_MapPainter old) =>
      old.items != items || old.viewport != viewport || old.k != k;
}

/// The photo with a frame to crop it by its corners; Done keeps it. The
/// whole photo stays, so it can be cropped again.
Future<void> showPhotoCrop(BuildContext context, BoardItem item) async {
  final file = FileManager.getFile(item.photo!);
  final decoded = await decodeImageFromList(await file.readAsBytes());
  final aspect = decoded.width / decoded.height;
  decoded.dispose();
  if (!context.mounted) return;
  await showGeneralDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    pageBuilder: (context, _, _) => _CropPage(item: item, aspect: aspect),
  );
}

class _CropPage extends StatefulWidget {
  const new({required this.item, required this.aspect});

  final BoardItem item;
  final double aspect;

  @override
  State<_CropPage> createState() => _CropPageState();
}

class _CropPageState extends State<_CropPage> {
  late var _crop = widget.item.crop;

  void _done() {
    final item = widget.item;
    final box = item.box!;
    // the frame takes the crop's shape, as wide as it was
    final shape = (_crop.width * widget.aspect) / _crop.height;
    final w = box.width;
    QuickBoard.update(
      item.copyWith(
        crop: _crop,
        aspect: widget.aspect,
        shape: item.shape == 2 ? 1 : item.shape,
        box: () => Rect.fromLTWH(box.left, box.top, w, w / shape),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Center(
                child: AspectRatio(
                  aspectRatio: widget.aspect,
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final size = c.biggest;
                      final r = Rect.fromLTRB(
                        _crop.left * size.width,
                        _crop.top * size.height,
                        _crop.right * size.width,
                        _crop.bottom * size.height,
                      );
                      Widget corner(Alignment a) {
                        final at = a.withinRect(r);
                        return Positioned(
                          left: at.dx - 18,
                          top: at.dy - 18,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanUpdate: (d) => setState(() {
                              final dx = d.delta.dx / size.width;
                              final dy = d.delta.dy / size.height;
                              var l = _crop.left,
                                  t = _crop.top,
                                  rr = _crop.right,
                                  b = _crop.bottom;
                              if (a.x < 0) l = (l + dx).clamp(0.0, rr - 0.08);
                              if (a.x > 0) rr = (rr + dx).clamp(l + 0.08, 1.0);
                              if (a.y < 0) t = (t + dy).clamp(0.0, b - 0.08);
                              if (a.y > 0) b = (b + dy).clamp(t + 0.08, 1.0);
                              _crop = Rect.fromLTRB(l, t, rr, b);
                            }),
                            child: Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.black54),
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: Image.file(
                              FileManager.getFile(widget.item.photo!),
                              fit: BoxFit.fill,
                            ),
                          ),
                          // dim what's cut away
                          Positioned.fill(
                            child: CustomPaint(painter: _CropShade(r)),
                          ),
                          // drag inside the frame to move it
                          Positioned.fromRect(
                            rect: r,
                            child: GestureDetector(
                              onPanUpdate: (d) => setState(() {
                                final dx = d.delta.dx / size.width;
                                final dy = d.delta.dy / size.height;
                                final w = _crop.width, h = _crop.height;
                                final l = (_crop.left + dx).clamp(0.0, 1 - w);
                                final t = (_crop.top + dy).clamp(0.0, 1 - h);
                                _crop = Rect.fromLTWH(l, t, w, h);
                              }),
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          for (final a in const [
                            Alignment.topLeft,
                            Alignment.topRight,
                            Alignment.bottomLeft,
                            Alignment.bottomRight,
                          ])
                            corner(a),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 16,
              children: [
                TextButton(
                  onPressed: () =>
                      setState(() => _crop = const Rect.fromLTRB(0, 0, 1, 1)),
                  child: const Text(
                    'Reset',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                FilledButton(onPressed: _done, child: const Text('Done')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CropShade extends CustomPainter {
  const new(this.keep);

  final Rect keep;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRect(keep),
      ),
      Paint()..color = const Color(0x99000000),
    );
  }

  @override
  bool shouldRepaint(_CropShade old) => old.keep != keep;
}

/// − 100% + Fit, in a corner of the zoomable board. The percentage resets
/// to 100% (the board as wide as the screen).
class _ZoomPill extends StatelessWidget {
  const new({
    required this.view,
    required this.zoomOut,
    required this.zoomIn,
    required this.actualSize,
    required this.fit,
  });

  final TransformationController view;
  final VoidCallback zoomOut, zoomIn, actualSize, fit;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.all(Radius.circular(BnRadius.pill)),
        border: Border.all(color: colors.hairline),
        boxShadow: BnShadows.floating,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: ListenableBuilder(
          listenable: view,
          builder: (context, _) {
            final zoom = view.value.getMaxScaleOnAxis();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                BnIconButton(
                  icon: Icons.remove,
                  size: 34,
                  iconSize: 18,
                  radius: BnRadius.pill,
                  tooltip: 'Zoom out',
                  onPressed: zoom > _PinBoardState._minZoom + 0.01
                      ? zoomOut
                      : null,
                ),
                GestureDetector(
                  onTap: actualSize,
                  child: SizedBox(
                    width: 50,
                    child: Text(
                      '${(zoom * 100).round()}%',
                      textAlign: TextAlign.center,
                      style: BnType.caption.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
                BnIconButton(
                  icon: Icons.add,
                  size: 34,
                  iconSize: 18,
                  radius: BnRadius.pill,
                  tooltip: 'Zoom in',
                  onPressed: zoom < _PinBoardState._maxZoom - 0.01
                      ? zoomIn
                      : null,
                ),
                Container(
                  width: 1,
                  height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: colors.hairline,
                ),
                TextButton(
                  onPressed: fit,
                  style: TextButton.styleFrom(
                    foregroundColor: colors.text,
                    minimumSize: const Size(44, 34),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    'Fit',
                    style: BnType.caption.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
