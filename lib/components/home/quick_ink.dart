import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

/// What a quick note is written with.
enum QuickTool { fountain, ball, highlighter, text, eraser }

/// One line written on a quick note. Points are kept as fractions of the
/// note's width, so the note looks the same small on the board and big.
class BoardStroke {
  const new({
    required this.tool,
    required this.color,
    required this.points,
    this.width,
  });

  /// [QuickTool.fountain], [QuickTool.ball] or [QuickTool.highlighter].
  final QuickTool tool;
  final Color color;

  /// x, y (fractions of the width) and pressure, three numbers a point.
  final List<double> points;

  /// The width of the line chosen when it was written, as a fraction of
  /// the note's width; null for the tool's own width (older notes).
  final double? width;

  /// The tool's own width, as a fraction of the note's width.
  static double defaultSize(QuickTool tool) => switch (tool) {
    QuickTool.highlighter => 0.05,
    QuickTool.fountain => 0.011,
    _ => 0.008,
  };

  /// The width of the line, as a fraction of the note's width.
  double get size => width ?? defaultSize(tool);

  Map<String, dynamic> toJson() => {
    't': tool.name,
    'c': color.toARGB32(),
    'p': [for (final v in points) (v * 10000).round() / 10000],
    if (width case final w?) 'w': (w * 100000).round() / 100000,
  };

  static BoardStroke? fromJson(Object? json) {
    if (json is! Map) return null;
    final tool = QuickTool.values
        .where(
          (t) =>
              t.name == json['t'] &&
              t != QuickTool.text &&
              t != QuickTool.eraser,
        )
        .firstOrNull;
    final points = json['p'];
    if (tool == null || points is! List || points.length < 3) return null;
    return BoardStroke(
      tool: tool,
      color: Color(json['c'] as int? ?? 0xFF1C1C1E),
      points: [for (final v in points) (v as num).toDouble()],
      width: (json['w'] as num?)?.toDouble(),
    );
  }

  /// Each finished line's outline, made once per note width: working it
  /// out (perfect_freehand) on every paint made zooming the board slow.
  static final _outlines = Expando<(double, Path)>();

  /// This line as a filled path (pens) or a centre line (highlighter), on
  /// a note [width] wide. Cached for [width].
  Path pathFor(double width) {
    final cached = _outlines[this];
    if (cached != null && cached.$1 == width) return cached.$2;
    final path = _makePath(width);
    _outlines[this] = (width, path);
    return path;
  }

  Path _makePath(double width) {
    final p = points;
    if (tool == QuickTool.highlighter) {
      final path = Path()..moveTo(p[0] * width, p[1] * width);
      for (int i = 3; i < p.length; i += 3) {
        path.lineTo(p[i] * width, p[i + 1] * width);
      }
      if (p.length == 3) path.lineTo(p[0] * width + 0.1, p[1] * width);
      return path;
    }
    final outline = getStroke(
      [
        for (int i = 0; i < p.length; i += 3)
          PointVector(p[i] * width, p[i + 1] * width, p[i + 2]),
      ],
      options: StrokeOptions(
        size: size * width,
        thinning: tool == QuickTool.fountain ? 0.6 : 0.1,
        smoothing: 0.5,
        streamline: 0.4,
        simulatePressure: false,
        isComplete: true,
      ),
    );
    return Path()..addPolygon(outline, true);
  }

  /// Draws this line on a note [width] wide.
  void paint(Canvas canvas, double width, {bool cache = true}) {
    final path = cache ? pathFor(width) : _makePath(width);
    if (tool == QuickTool.highlighter) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = size * width
          ..color = color.withValues(alpha: 0.4)
          ..blendMode = BlendMode.multiply,
      );
    } else {
      canvas.drawPath(path, Paint()..color = color);
    }
  }
}

/// Draws [ink] on a note as wide as the canvas: highlighters first, under
/// the pens. Give it a new list when the ink changes: it repaints only then.
class BoardInkPainter extends CustomPainter {
  const new(this.ink);

  final List<BoardStroke> ink;

  @override
  void paint(Canvas canvas, Size size) {
    for (final highlighters in [true, false]) {
      for (final stroke in ink) {
        if ((stroke.tool == QuickTool.highlighter) != highlighters) continue;
        stroke.paint(canvas, size.width);
      }
    }
  }

  @override
  bool shouldRepaint(BoardInkPainter old) => !identical(old.ink, ink);
}

/// The line being written, repainted on each move without a rebuild.
class _LiveInk extends ChangeNotifier {
  BoardStroke? stroke;

  void set(BoardStroke? s) {
    stroke = s;
    notifyListeners();
  }
}

class _LivePainter extends CustomPainter {
  new(this.live) : super(repaint: live);

  final _LiveInk live;

  @override
  void paint(Canvas canvas, Size size) =>
      live.stroke?.paint(canvas, size.width, cache: false);

  @override
  bool shouldRepaint(_LivePainter old) => old.live != live;
}

/// Where a quick note is written on with [tool] in [color]: a finger or a
/// pen draws, and [onStroke] gets each finished line. A second finger
/// takes back the line the first one started (it's a pinch, not writing).
class QuickInkPad extends StatefulWidget {
  const new({
    super.key,
    required this.ink,
    required this.tool,
    required this.color,
    required this.onStroke,
    this.onErase,
    this.size,
  });

  /// The finished lines. Pass a new list when they change.
  final List<BoardStroke> ink;
  final QuickTool tool;
  final Color color;
  final ValueChanged<BoardStroke> onStroke;

  /// The width new lines get, as a fraction of the width; null for the
  /// tool's own.
  final double? size;

  /// With the eraser: the lines it touched, to take off.
  final ValueChanged<List<BoardStroke>>? onErase;

  @override
  State<QuickInkPad> createState() => _QuickInkPadState();
}

class _QuickInkPadState extends State<QuickInkPad> {
  final _live = _LiveInk();
  List<double>? _points;
  int? _pointer;
  PointerDeviceKind? _kind;

  /// Fingers on the pad now; two or more is a pinch.
  final _touches = <int>{};

  /// Set by a second finger: nothing is written until all are lifted.
  var _blocked = false;

  bool get _writing => widget.tool != QuickTool.text;

  @override
  void dispose() {
    _live.dispose();
    _eraser.dispose();
    super.dispose();
  }

  void _add(PointerEvent event, double width) {
    final pressure = event.kind == PointerDeviceKind.stylus
        ? event.pressure.clamp(0.05, 1.0)
        : 0.5;
    _points!.addAll([
      event.localPosition.dx / width,
      event.localPosition.dy / width,
      pressure,
    ]);
  }

  /// Where the eraser is, as a fraction of the width.
  final _eraser = ValueNotifier<Offset?>(null);

  /// The eraser's reach, as a fraction of the note's width.
  static const _reach = 0.035;

  void _erase(Offset at) {
    final hit = [
      for (final stroke in widget.ink)
        if (_touchesStroke(stroke, at)) stroke,
    ];
    if (hit.isNotEmpty) widget.onErase?.call(hit);
  }

  static bool _touchesStroke(BoardStroke stroke, Offset at) {
    final p = stroke.points;
    final reach = _reach + stroke.size / 2;
    for (int i = 0; i < p.length; i += 3) {
      if ((Offset(p[i], p[i + 1]) - at).distance <= reach) return true;
    }
    return false;
  }

  /// The line being written; [done] gives it its own copy of the points.
  BoardStroke? _stroke({bool done = false}) =>
      _points == null || _points!.isEmpty
      ? null
      : BoardStroke(
          tool: widget.tool,
          color: widget.color,
          points: done ? List.of(_points!) : _points!,
          width: widget.size,
        );

  /// Keeps count of fingers; a second one cancels the line being written.
  void _down(PointerDownEvent event) {
    if (event.kind != PointerDeviceKind.touch) return;
    _touches.add(event.pointer);
    if (_touches.length < 2) return;
    _blocked = true;
    if (_pointer != null && _kind == PointerDeviceKind.touch) _cancel();
    _eraser.value = null;
  }

  void _up(PointerEvent event) {
    _touches.remove(event.pointer);
    if (_touches.isEmpty) _blocked = false;
  }

  void _cancel() {
    _points = null;
    _pointer = null;
    _live.set(null);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      // finished lines repaint only when the list changes; the live line
      // repaints on its own layer as the pen moves
      final paint = Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: CustomPaint(painter: BoardInkPainter(widget.ink)),
          ),
          CustomPaint(painter: _LivePainter(_live)),
        ],
      );
      if (!_writing) return IgnorePointer(child: paint);
      if (widget.tool == QuickTool.eraser) {
        void at(PointerEvent event) {
          if (_blocked) return;
          final p = event.localPosition / width;
          _eraser.value = p;
          _erase(p);
        }

        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (e) {
            _down(e);
            at(e);
          },
          onPointerMove: at,
          onPointerUp: (e) {
            _up(e);
            _eraser.value = null;
          },
          onPointerCancel: (e) {
            _up(e);
            _eraser.value = null;
          },
          child: Stack(
            children: [
              Positioned.fill(child: paint),
              // a ring where the eraser is
              ValueListenableBuilder(
                valueListenable: _eraser,
                builder: (context, e, _) => e == null
                    ? const SizedBox()
                    : Positioned(
                        left: (e.dx - _reach) * width,
                        top: (e.dy - _reach) * width,
                        child: IgnorePointer(
                          child: Container(
                            width: _reach * 2 * width,
                            height: _reach * 2 * width,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0x55FFFFFF),
                              border: Border.all(
                                color: const Color(0xFF333333),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      }
      return Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (event) {
          _down(event);
          if (_pointer != null || _blocked) return;
          _pointer = event.pointer;
          _kind = event.kind;
          _points = [];
          _add(event, width);
          _live.set(_stroke());
        },
        onPointerMove: (event) {
          if (event.pointer != _pointer || _points == null) return;
          _add(event, width);
          _live.set(_stroke());
        },
        onPointerUp: (event) {
          _up(event);
          if (event.pointer != _pointer) return;
          final stroke = _stroke(done: true);
          _cancel();
          if (stroke != null) widget.onStroke(stroke);
        },
        onPointerCancel: (event) {
          _up(event);
          if (event.pointer == _pointer) _cancel();
        },
        child: paint,
      );
    },
  );
}
