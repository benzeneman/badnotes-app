import 'dart:math' as math;

import 'package:badnotes/components/home/board_background.dart';
import 'package:badnotes/components/home/quick_board.dart';
import 'package:badnotes/components/home/quick_ink.dart';
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
  const PinBoard({
    super.key,
    required this.items,
    required this.openNote,
    required this.openPhoto,
    this.minHeight = 400,
    this.zoomable = false,
  });

  final List<BoardItem> items;
  final void Function(BuildContext context, BoardItem item) openNote;
  final void Function(BuildContext context, BoardItem item) openPhoto;

  /// The board is at least this tall on screen.
  final double minHeight;

  /// Pinch to zoom, pan every way, and a zoom pill (the full-screen board).
  /// Off on the desk, where the board scrolls up and down.
  final bool zoomable;

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

  @override
  void dispose() {
    _view.dispose();
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
  void _fit(Size viewport, double boardHeight) {
    final s = math.min(1.0, viewport.height / boardHeight);
    _view.value = Matrix4.identity()
      ..translateByDouble((viewport.width - viewport.width * s) / 2, 0, 0, 1)
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
    HapticFeedback.mediumImpact();
    setState(() => _selected = item.id);
    // picked up: to the front
    if (item.z < QuickBoard.topZ) {
      QuickBoard.update(item.copyWith(z: QuickBoard.topZ + 1));
    }
  }

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
        final board = GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _selected = null),
          // zoomable: double-tap empty board for 200%, again for 100%
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
          child: SizedBox(
            height: height,
            child: Stack(
              key: _stackKey,
              clipBehavior: Clip.none,
              children: [
                // the board's own background (design 7)
                const Positioned.fill(child: BoardBackground()),
                for (final item in items) _item_(context, item, scale),
                if (selected?.box != null)
                  ..._handles(
                    context,
                    items.firstWhere((i) => i.id == selected!.id),
                    scale,
                  ),
              ],
            ),
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
        return Stack(
          children: [
            InteractiveViewer(
              transformationController: _view,
              constrained: false,
              minScale: _minZoom,
              maxScale: _maxZoom,
              // a picked-up item moves and pinches, not the board
              panEnabled: selected == null,
              scaleEnabled: selected == null,
              child: SizedBox(width: constraints.maxWidth, child: board),
            ),
            Positioned(
              right: 16,
              bottom: 16 + MediaQuery.paddingOf(context).bottom,
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
                fit: () => _fit(viewport, height),
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
    final card = _PinnedCard(item: item, scale: scale);
    return Positioned(
      key: ValueKey(item.id),
      left: box.left * scale,
      top: box.top * scale,
      width: box.width * scale,
      height: box.height * scale,
      child: Transform.rotate(
        angle: item.angle,
        child: picked
            ? GestureDetector(
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
              )
            : GestureDetector(
                onTap: () => _open(context, item),
                onLongPress: () => _select(item),
                child: card,
              ),
      ),
    );
  }

  void _open(BuildContext context, BoardItem item) => item.isPhoto
      ? widget.openPhoto(context, item)
      : widget.openNote(context, item);

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
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (_) => _startBox = item.box,
            onPanUpdate: onDrag,
            child: SizedBox.square(
              dimension: dot,
              child: Center(child: child),
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
          child: _ItemBar(
            item: item,
            onDone: () => setState(() => _selected = null),
          ),
        ),
      ),
    ];
  }
}

/// A note or photo as pinned: its frame and look, and a pin or tape.
class _PinnedCard extends StatelessWidget {
  const _PinnedCard({required this.item, required this.scale});

  final BoardItem item;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final body = item.isPhoto ? _photo() : _note();
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            shape: item.isPhoto && item.shape == 2
                ? BoxShape.circle
                : BoxShape.rectangle,
            borderRadius: item.isPhoto && item.shape == 2
                ? null
                : BorderRadius.circular(_radius()),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: body,
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
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: Alignment(-0.35, -0.35),
                    colors: [Color(0xFFFF8A80), Color(0xFFD93A2B)],
                  ),
                  boxShadow: [
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
                    color: const Color(0xFFFFD678).withValues(alpha: 0.72),
                    boxShadow: const [
                      BoxShadow(color: Color(0x22000000), blurRadius: 2),
                    ],
                  ),
                ),
              ),
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
    if (!item.isPhoto) return 4;
    return switch (item.shape) {
      0 => 0,
      _ => item.corners * side / 2,
    };
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
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
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
    final image = Image(
      image: ResizeImage(
        FileImage(FileManager.getFile(item.photo!)),
        width: 900,
        allowUpscaling: false,
      ),
      fit: BoxFit.fill,
      gaplessPlayback: true,
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
                width: 900,
                allowUpscaling: false,
              ),
              fit: BoxFit.cover,
              gaplessPlayback: true,
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

/// The picked-up item's bar (design 2): crop and frame for a photo, what's
/// on top of it, front and back, and unpin. One row of fixed buttons:
/// before, each button stretched to the full width and the bar became a
/// long list down the board.
class _ItemBar extends StatelessWidget {
  const _ItemBar({required this.item, required this.onDone});

  final BoardItem item;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    void set(BoardItem Function(BoardItem) change) =>
        QuickBoard.update(change(item));

    Widget button(
      String tip,
      Widget icon,
      VoidCallback onTap, {
      bool on = false,
      String? label,
    }) => Tooltip(
      message: tip,
      child: Material(
        color: on ? colors.accentTint : Colors.transparent,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          onTap: onTap,
          child: SizedBox(
            height: 40,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: label == null ? 11 : 12,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  icon,
                  if (label != null) ...[
                    const SizedBox(width: 7),
                    Text(
                      label,
                      style: BnType.body.copyWith(color: colors.text),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
    Widget divider() => Container(
      width: 1,
      height: 26,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: colors.hairline,
    );
    Widget caption(String text) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(text, style: BnType.micro.copyWith(color: colors.muted)),
    );
    Widget frame({double radius = 0, bool circle = false, bool on = false}) =>
        Container(
          width: 17,
          height: 17,
          decoration: BoxDecoration(
            shape: circle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: circle ? null : BorderRadius.circular(radius),
            border: Border.all(
              color: on ? colors.accentStrong : colors.text2,
              width: 1.8,
            ),
          ),
        );
    Icon icon(IconData data, {bool on = false, Color? color}) => Icon(
      data,
      size: 18,
      color: color ?? (on ? colors.accentStrong : colors.text2),
    );

    return Material(
      color: colors.surface,
      elevation: 8,
      shadowColor: Colors.black38,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: colors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.isPhoto) ...[
                button(
                  'Crop',
                  icon(Icons.crop),
                  () => showPhotoCrop(context, item),
                  label: 'Crop',
                ),
                divider(),
                caption('Frame'),
                button(
                  'Square frame',
                  frame(on: item.shape == 0),
                  () => set((i) => i.copyWith(shape: 0)),
                  on: item.shape == 0,
                ),
                button(
                  'Rounded frame',
                  frame(radius: 5, on: item.shape == 1),
                  () => set((i) => i.copyWith(shape: 1)),
                  on: item.shape == 1,
                ),
                button(
                  'Circle frame',
                  frame(circle: true, on: item.shape == 2),
                  () => set(_toCircle),
                  on: item.shape == 2,
                ),
                if (item.shape == 1)
                  SizedBox(
                    width: 100,
                    child: Slider(
                      value: item.corners,
                      onChanged: (v) => set((i) => i.copyWith(corners: v)),
                    ),
                  ),
                divider(),
              ],
              caption('On top'),
              button(
                'Nothing on top',
                icon(Icons.block, on: item.deco == 0),
                () => set((i) => i.copyWith(deco: 0)),
                on: item.deco == 0,
              ),
              button(
                'A pin',
                icon(Icons.push_pin_outlined, on: item.deco == 1),
                () => set((i) => i.copyWith(deco: 1)),
                on: item.deco == 1,
              ),
              button(
                'A strip of tape',
                icon(Icons.horizontal_rule_rounded, on: item.deco == 2),
                () => set((i) => i.copyWith(deco: 2)),
                on: item.deco == 2,
              ),
              divider(),
              button(
                'Bring to front',
                icon(Icons.flip_to_front),
                () => set((i) => i.copyWith(z: QuickBoard.topZ + 1)),
              ),
              button('Send to back', icon(Icons.flip_to_back), () {
                final bottom = QuickBoard.items.value.fold(
                  0,
                  (m, i) => math.min(m, i.z),
                );
                set((i) => i.copyWith(z: bottom - 1));
              }),
              divider(),
              button(
                item.isPhoto ? 'Unpin the photo' : 'Unpin the note',
                icon(Icons.delete_outline, color: colors.danger),
                () {
                  onDone();
                  QuickBoard.remove(item);
                },
              ),
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
  const _CropPage({required this.item, required this.aspect});

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
  const _CropShade(this.keep);

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
  const _ZoomPill({
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
        color: colors.surface,
        borderRadius: const BorderRadius.all(Radius.circular(99)),
        border: Border.all(color: colors.hairline),
        boxShadow: BnShadows.card,
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
                  tooltip: 'Zoom out',
                  onPressed: zoom > _PinBoardState._minZoom + 0.01
                      ? zoomOut
                      : null,
                ),
                GestureDetector(
                  onTap: actualSize,
                  child: SizedBox(
                    width: 52,
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
                  tooltip: 'Zoom in',
                  onPressed: zoom < _PinBoardState._maxZoom - 0.01
                      ? zoomIn
                      : null,
                ),
                BnIconButton(
                  icon: Icons.fit_screen,
                  size: 34,
                  iconSize: 18,
                  tooltip: 'Fit the board',
                  onPressed: fit,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
