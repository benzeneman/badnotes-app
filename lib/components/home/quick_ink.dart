import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

/// What a quick note is written with.
enum QuickTool { fountain, ball, highlighter, text, eraser }

/// One line written on a quick note. Points are kept as fractions of the
/// note's width, so the note looks the same small on the board and big.
class BoardStroke {
  const new({required this.tool, required this.color, required this.points});

  /// [QuickTool.fountain], [QuickTool.ball] or [QuickTool.highlighter].
  final QuickTool tool;
  final Color color;

  /// x, y (fractions of the width) and pressure, three numbers a point.
  final List<double> points;

  /// The width of the line, as a fraction of the note's width.
  double get size => switch (tool) {
    QuickTool.highlighter => 0.05,
    QuickTool.fountain => 0.011,
    _ => 0.008,
  };

  Map<String, dynamic> toJson() => {
    't': tool.name,
    'c': color.toARGB32(),
    'p': [for (final v in points) (v * 10000).round() / 10000],
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
    );
  }
}

/// Draws [ink] on a note [width] wide: highlighters first, under the pens.
class BoardInkPainter extends CustomPainter {
  new(this.ink, {this.live}) : _count = ink.length;

  final List<BoardStroke> ink;

  /// How many lines [ink] had: the list grows and shrinks in place.
  final int _count;

  /// The line being written, drawn last.
  final BoardStroke? live;

  @override
  void paint(Canvas canvas, Size size) {
    final all = [...ink, ?live];
    for (final highlighters in [true, false]) {
      for (final stroke in all) {
        if ((stroke.tool == QuickTool.highlighter) != highlighters) continue;
        _draw(canvas, size.width, stroke);
      }
    }
  }

  static void _draw(Canvas canvas, double width, BoardStroke stroke) {
    final p = stroke.points;
    final size = stroke.size * width;
    if (stroke.tool == QuickTool.highlighter) {
      final path = Path()..moveTo(p[0] * width, p[1] * width);
      for (int i = 3; i < p.length; i += 3) {
        path.lineTo(p[i] * width, p[i + 1] * width);
      }
      if (p.length == 3) path.lineTo(p[0] * width + 0.1, p[1] * width);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = size
          ..color = stroke.color.withValues(alpha: 0.4)
          ..blendMode = BlendMode.multiply,
      );
      return;
    }
    final outline = getStroke(
      [
        for (int i = 0; i < p.length; i += 3)
          PointVector(p[i] * width, p[i + 1] * width, p[i + 2]),
      ],
      options: StrokeOptions(
        size: size,
        thinning: stroke.tool == QuickTool.fountain ? 0.6 : 0.1,
        smoothing: 0.5,
        streamline: 0.4,
        simulatePressure: false,
        isComplete: true,
      ),
    );
    if (outline.isEmpty) return;
    canvas.drawPath(
      Path()..addPolygon(outline, true),
      Paint()..color = stroke.color,
    );
  }

  @override
  bool shouldRepaint(BoardInkPainter old) =>
      old.ink != ink ||
      old._count != _count ||
      old.live != live ||
      live != null;
}

/// Where a quick note is written on with [tool] in [color]: a finger or a
/// pen draws, and [onStroke] gets each finished line.
class QuickInkPad extends StatefulWidget {
  const new({
    super.key,
    required this.ink,
    required this.tool,
    required this.color,
    required this.onStroke,
    this.onErase,
  });

  final List<BoardStroke> ink;
  final QuickTool tool;
  final Color color;
  final ValueChanged<BoardStroke> onStroke;

  /// With the eraser: the lines it touched, to take off.
  final ValueChanged<List<BoardStroke>>? onErase;

  @override
  State<QuickInkPad> createState() => _QuickInkPadState();
}

class _QuickInkPadState extends State<QuickInkPad> {
  List<double>? _points;
  int? _pointer;

  bool get _writing => widget.tool != QuickTool.text;

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
  Offset? _eraser;

  /// The eraser's reach, as a fraction of the note's width.
  static const _reach = 0.035;

  void _erase(Offset at) {
    final hit = [
      for (final stroke in widget.ink)
        if (_touches(stroke, at)) stroke,
    ];
    if (hit.isNotEmpty) widget.onErase?.call(hit);
  }

  static bool _touches(BoardStroke stroke, Offset at) {
    final p = stroke.points;
    final reach = _reach + stroke.size / 2;
    for (int i = 0; i < p.length; i += 3) {
      if ((Offset(p[i], p[i + 1]) - at).distance <= reach) return true;
    }
    return false;
  }

  BoardStroke? get _live => _points == null || _points!.isEmpty
      ? null
      : BoardStroke(tool: widget.tool, color: widget.color, points: _points!);

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final paint = CustomPaint(
        size: Size.infinite,
        painter: BoardInkPainter(widget.ink, live: _live),
      );
      if (!_writing) return IgnorePointer(child: paint);
      if (widget.tool == QuickTool.eraser) {
        void at(PointerEvent event) {
          final p = event.localPosition / width;
          setState(() => _eraser = p);
          _erase(p);
        }

        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: at,
          onPointerMove: at,
          onPointerUp: (_) => setState(() => _eraser = null),
          onPointerCancel: (_) => setState(() => _eraser = null),
          child: Stack(
            children: [
              Positioned.fill(child: paint),
              // a ring where the eraser is
              if (_eraser case final e?)
                Positioned(
                  left: (e.dx - _reach) * width,
                  top: (e.dy - _reach) * width,
                  child: IgnorePointer(
                    child: Container(
                      width: _reach * 2 * width,
                      height: _reach * 2 * width,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0x55FFFFFF),
                        border: Border.all(color: const Color(0xFF333333), width: 1.5),
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
          if (_pointer != null) return;
          _pointer = event.pointer;
          setState(() {
            _points = [];
            _add(event, width);
          });
        },
        onPointerMove: (event) {
          if (event.pointer != _pointer) return;
          setState(() => _add(event, width));
        },
        onPointerUp: (event) {
          if (event.pointer != _pointer) return;
          final stroke = _live;
          setState(() {
            _points = null;
            _pointer = null;
          });
          if (stroke != null) widget.onStroke(stroke);
        },
        onPointerCancel: (event) {
          if (event.pointer != _pointer) return;
          setState(() {
            _points = null;
            _pointer = null;
          });
        },
        child: paint,
      );
    },
  );
}
