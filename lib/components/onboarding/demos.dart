// The feature tour's live demos: real ink (written by hand, see
// tour_ink.dart), drawn with the app's own renderers and widgets, playing
// on a loop. Each is laid out on a 640 × 480 stage that is scaled to fit.
import 'dart:math';

import 'package:badnotes/components/canvas/_canvas_background_painter.dart';
import 'package:badnotes/components/editor_ui/editor_ui_colors.dart';
import 'package:badnotes/components/editor_ui/selection_action_bar.dart';
import 'package:badnotes/components/home/pin_board.dart';
import 'package:badnotes/components/home/quick_board.dart';
import 'package:badnotes/components/home/quick_ink.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/theming/badnotes_tokens.dart';
import 'package:badnotes/components/ui/bn_controls.dart';
import 'package:badnotes/components/ui/bn_docks.dart';
import 'package:badnotes/components/ui/bn_icons.dart';
import 'package:badnotes/components/ui/bn_logo.dart';
import 'package:badnotes/components/ui/bn_surfaces.dart';
import 'package:badnotes/data/extensions/color_extensions.dart';
import 'package:badnotes/data/file_manager/note_versions.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/tools/tape_pattern.dart';
import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:sbn/canvas_background_pattern.dart';

part 'tour_ink.dart';

/// Handwriting from a real note: strokes of x, y and pressure (three numbers
/// a point) in page units, from the top left of [size].
class TourInk {
  const new(
    this.size,
    this.strokes, {
    this.marks = const [],
    this.words = const [],
  });

  final Size size;
  final List<List<double>> strokes;

  /// Highlighter lines, as x, y, pressure too.
  final List<List<double>> marks;

  /// Where some words are, for the demos to point at.
  final List<Rect> words;

  static final _points = Expando<int>();

  /// How many points all the strokes have.
  int get points =>
      _points[this] ??= strokes.fold<int>(0, (n, s) => n + s.length ~/ 3);

  static final _outlines = <(TourInk, double), List<BoardStroke>>{};

  /// The strokes as the quick notes' pen draws them, [pen] units wide. Their
  /// outlines are worked out once.
  List<BoardStroke> strokesFor(double pen) => _outlines.putIfAbsent(
    (this, pen),
    () => [
      for (final s in strokes)
        BoardStroke(
          tool: QuickTool.fountain,
          color: BnColors.inkBlack,
          points: s,
          width: pen,
        ),
    ],
  );

  /// The pen's place (in page units) when [progress] of the ink is written,
  /// or null before the start and after the end.
  Offset? tipAt(double progress) {
    if (progress <= 0 || progress >= 1) return null;
    var left = (progress * points).round();
    for (final s in strokes) {
      final n = s.length ~/ 3;
      if (left <= n) {
        final i = (max(left, 1) - 1) * 3;
        return Offset(s[i], s[i + 1]);
      }
      left -= n;
    }
    return null;
  }
}

/// The stage every demo is laid out on.
const _stage = Size(640, 480);

/// 0 before [a], 1 after [b], eased in between.
double _span(
  double t,
  double a,
  double b, [
  Curve curve = Curves.easeInOutCubic,
]) => curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

void _noop() {}

/// Whether pages show dark, as the editor shows them in dark mode.
bool _pagesDark(BuildContext context) =>
    Theme.brightnessOf(context) == Brightness.dark &&
    stows.editorAutoInvert.value;

Color _inkColor(double dark) =>
    Color.lerp(BnColors.inkBlack, BnColors.inkBlack.withInversion(), dark)!;

/// Plays [builder] over and over, one loop every [duration], on a stage of
/// its own layer. With animations turned off it holds still at [rest].
class _Loop extends StatefulWidget {
  const new({required this.duration, required this.builder, this.rest = 0.6});

  final Duration duration;
  final double rest;
  final Widget Function(BuildContext context, double t) builder;

  @override
  State<_Loop> createState() => _LoopState();
}

class _LoopState extends State<_Loop> with SingleTickerProviderStateMixin {
  late final _clock = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  bool? _still;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final still = MediaQuery.disableAnimationsOf(context);
    if (still == _still) return;
    _still = still;
    if (still) {
      _clock
        ..stop()
        ..value = widget.rest;
    } else {
      _clock.repeat();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: FittedBox(
      child: SizedBox.fromSize(
        size: _stage,
        child: AnimatedBuilder(
          animation: _clock,
          builder: (context, _) => widget.builder(context, _clock.value),
        ),
      ),
    ),
  );
}

/// Fades in at the start of a loop and out at its end.
Widget _fading(double t, Widget child, {double out = 0.94}) {
  final opacity = min(_span(t, 0, 0.04), 1 - _span(t, out, 0.995));
  return Opacity(opacity: opacity, child: child);
}

/// Zooms into [focus] by [zoom], like a camera moving in.
Widget _camera(double zoom, Alignment focus, Widget child) =>
    Transform.scale(scale: zoom, alignment: focus, child: child);

/// The point [p] of the stage as an [Alignment].
Alignment _focusOn(Offset p) =>
    Alignment(p.dx / _stage.width * 2 - 1, p.dy / _stage.height * 2 - 1);

// ---------------------------------------------------------------------------
// Paper and ink
// ---------------------------------------------------------------------------

/// Ink written by hand, [progress] of it so far.
class _Ink {
  const new(
    this.ink, {
    this.at = Offset.zero,
    this.scale = 1,
    this.progress = 1,
    this.color,
    this.ghost,
    this.where,
    this.pen = 2.6,
  });

  final TourInk ink;

  /// Where the ink's top left goes on the page, and how big it is.
  final Offset at;
  final double scale;
  final double progress;

  /// Null for the page's ink colour.
  final Color? color;

  /// The whole of the ink faintly in this colour under what's written.
  final Color? ghost;

  /// Which strokes, by index; null for all.
  final bool Function(int i)? where;
  final double pen;

  Offset? get tip {
    final p = ink.tipAt(progress);
    return p == null ? null : at + p * scale;
  }

  void paint(Canvas canvas, Color pageInk) {
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.scale(scale);
    if (ink.marks.isNotEmpty && progress >= 1 && where == null) {
      final mark = Paint()
        ..color = const Color(0x59FFC94D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      for (final m in ink.marks) {
        final path = Path()..moveTo(m[0], m[1]);
        for (var i = 3; i < m.length; i += 3) {
          path.lineTo(m[i], m[i + 1]);
        }
        canvas.drawPath(path, mark);
      }
    }
    final all = ink.strokesFor(pen);
    final paint = Paint();
    bool shown(int i) => where?.call(i) ?? true;
    if (ghost case final ghost?) {
      paint.color = ghost;
      for (var i = 0; i < all.length; i++) {
        if (shown(i)) canvas.drawPath(all[i].pathFor(1), paint);
      }
    }
    paint.color = color ?? pageInk;
    var left = (progress * ink.points).round();
    for (var i = 0; i < all.length && left > 0; i++) {
      final n = ink.strokes[i].length ~/ 3;
      if (shown(i)) {
        if (left >= n) {
          canvas.drawPath(all[i].pathFor(1), paint);
        } else {
          final partial = BoardStroke(
            tool: QuickTool.fountain,
            color: paint.color,
            points: ink.strokes[i].sublist(0, left * 3),
            width: pen,
          );
          canvas.drawPath(partial.pathFor(1), paint);
        }
      }
      left -= n;
    }
    canvas.restore();
  }
}

class _PagePainter extends CustomPainter {
  new(this.inks, this.inkColor, this.extra);

  final List<_Ink> inks;
  final Color inkColor;
  final void Function(Canvas canvas)? extra;

  @override
  void paint(Canvas canvas, Size size) {
    for (final ink in inks) {
      ink.paint(canvas, inkColor);
    }
    extra?.call(canvas);
  }

  @override
  bool shouldRepaint(_PagePainter old) => true;
}

/// A ruled page at [rect] of the stage, as the editor draws one (its
/// [CanvasBackgroundPainter]), with [inks] on it. [dark] runs from a white
/// page (0) to a dark one (1).
Widget _page(
  BuildContext context,
  Rect rect, {
  double? dark,
  List<_Ink> inks = const [],
  void Function(Canvas canvas)? extra,
  List<Widget> children = const [],
}) {
  final colors = BadNotesColors.of(context);
  final scheme = ColorScheme.of(context);
  final d = dark ?? (_pagesDark(context) ? 1.0 : 0.0);
  const radius = BorderRadius.all(Radius.circular(6));
  return Positioned.fromRect(
    rect: rect,
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: colors.hairline),
        boxShadow: BnShadows.cover,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: CustomPaint(
          painter: CanvasBackgroundPainter(
            invert: false,
            backgroundColor: Color.lerp(Colors.white, Colors.black, d)!,
            backgroundPattern: CanvasBackgroundPattern.lined,
            lineHeight: 26,
            lineThickness: 2,
            primaryColor: scheme.primary,
            secondaryColor: scheme.secondary,
          ),
          foregroundPainter: _PagePainter(inks, _inkColor(d), extra),
          child: Stack(children: children),
        ),
      ),
    ),
  );
}

/// The stage's backdrop: the editor's desk.
Widget _desk(BuildContext context, List<Widget> children) => ColoredBox(
  color: EditorUi.of(context).desk,
  child: Stack(
    fit: StackFit.expand,
    clipBehavior: Clip.none,
    children: children,
  ),
);

/// The pen's tip while it writes.
void _drawTip(Canvas canvas, Offset? tip, Color color) {
  if (tip == null) return;
  canvas.drawCircle(tip, 3.2, Paint()..color = color);
}

/// A line through [points], [width] wide.
void _polyline(Canvas canvas, List<Offset> points, Paint paint) {
  if (points.length < 2) return;
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  for (final p in points.skip(1)) {
    path.lineTo(p.dx, p.dy);
  }
  canvas.drawPath(path, paint);
}

// ---------------------------------------------------------------------------
// 1. Welcome: a page writing itself
// ---------------------------------------------------------------------------

Widget welcomeDemo() => _Loop(
  duration: const Duration(milliseconds: 6500),
  rest: 0.85,
  builder: (context, t) {
    final ink = _Ink(
      _topology,
      at: const Offset(70, 110),
      scale: 1.45,
      progress: _span(t, 0.06, 0.78, Curves.linear),
      pen: 2.4,
    );
    final colors = BadNotesColors.of(context);
    return _desk(context, [
      _camera(
        1 + 0.05 * _span(t, 0, 1, Curves.easeOutCubic),
        _focusOn(const Offset(320, 230)),
        _fading(
          t,
          Stack(
            children: [
              _page(
                context,
                const Rect.fromLTWH(40, 28, 560, 452),
                inks: [ink],
                extra: (canvas) => _drawTip(canvas, ink.tip, colors.accent),
              ),
            ],
          ),
        ),
      ),
    ]);
  },
);

// ---------------------------------------------------------------------------
// 2. Lasso: loop round, lift, move, resize, recolor
// ---------------------------------------------------------------------------

/// A hand-drawn loop around [r], [progress] of the way round.
List<Offset> _lassoLoop(Rect r, double progress) {
  final c = r.center;
  final rx = r.width / 2 + 22, ry = r.height / 2 + 18;
  const steps = 72;
  final n = (steps * progress).round();
  return [
    for (var i = 0; i <= n; i++)
      () {
        final a = -2.4 + i / steps * 2 * pi * 1.04;
        final wobble = 1 + 0.04 * sin(3 * a + 0.7) + 0.02 * sin(8 * a);
        return c + Offset(cos(a) * rx * wobble, sin(a) * ry * wobble);
      }(),
  ];
}

Widget lassoDemo() => _Loop(
  duration: const Duration(milliseconds: 7000),
  rest: 0.86,
  builder: (context, t) {
    final colors = BadNotesColors.of(context);
    const pageRect = Rect.fromLTWH(24, 20, 592, 460);
    const at = Offset(30, 70), scale = 0.92;
    final word = _goldenEq.words.first;
    final picked = Rect.fromLTRB(
      at.dx + word.left * scale,
      at.dy + word.top * scale,
      at.dx + word.right * scale,
      at.dy + word.bottom * scale,
    );
    // moved, then made bigger by a corner, then recolored
    final move = _span(t, 0.44, 0.6);
    final grow = 1 + 0.25 * _span(t, 0.62, 0.74);
    final recolor = _span(t, 0.78, 0.84);
    final shift = const Offset(150, 150) * move;
    final box = Rect.fromCenter(
      center: picked.center + shift,
      width: picked.width * grow,
      height: picked.height * grow,
    ).inflate(8 * grow);
    final drawn = _span(t, 0.06, 0.3, Curves.easeInOut);
    final done = t >= 0.3;
    final loop = _lassoLoop(picked, done ? 1 : drawn);
    final loopShift = shift;
    final pageDark = _pagesDark(context) ? 1.0 : 0.0;
    final ink = _inkColor(pageDark);
    final pickedColor = Color.lerp(
      ink,
      BnColors.inkBlue.withInversion(pageDark > 0.5),
      recolor,
    )!;
    // the picked strokes scale about their own centre
    final pickedAt = picked.center + shift + (at - picked.center) * grow;
    final page = Offset(pageRect.left, pageRect.top);
    final barShown = _span(t, 0.33, 0.4);
    final zoom = 1 + 0.14 * _span(t, 0.04, 0.3) - 0.14 * _span(t, 0.36, 0.48);
    return _desk(context, [
      _camera(
        zoom,
        _focusOn(picked.center + page),
        _fading(
          t,
          Stack(
            children: [
              _page(
                context,
                pageRect,
                inks: [
                  _Ink(_goldenEq, at: at, scale: scale, where: (i) => i >= 6),
                  const _Ink(_goldenProof, at: Offset(300, 200), scale: 0.62),
                  _Ink(
                    _goldenEq,
                    at: pickedAt,
                    scale: scale * grow,
                    where: (i) => i < 6,
                    color: pickedColor,
                  ),
                ],
                extra: (canvas) {
                  final accent = colors.accent;
                  final path = Path();
                  if (loop.isNotEmpty) {
                    path.moveTo(
                      loop.first.dx + loopShift.dx,
                      loop.first.dy + loopShift.dy,
                    );
                    for (final p in loop.skip(1)) {
                      path.lineTo(p.dx + loopShift.dx, p.dy + loopShift.dy);
                    }
                  }
                  if (!done) {
                    canvas.drawPath(
                      path,
                      Paint()
                        ..color = accent
                        ..strokeWidth = 1.6
                        ..style = PaintingStyle.stroke,
                    );
                    if (loop.isNotEmpty) _drawTip(canvas, loop.last, accent);
                    return;
                  }
                  path.close();
                  // as the editor draws a selection: a faint tint, marching
                  // ants, then the box with its handles
                  canvas.drawPath(
                    path,
                    Paint()..color = accent.withValues(alpha: 0.08),
                  );
                  canvas.drawPath(
                    path,
                    Paint()
                      ..color = Colors.white
                      ..strokeWidth = 2.4
                      ..style = PaintingStyle.stroke,
                  );
                  canvas.drawPath(
                    dashPath(
                      path,
                      dashArray: CircularIntervalList([6.0, 5.0]),
                      dashOffset: DashOffset.absolute((1 - (t * 9) % 1) * 11),
                    ),
                    Paint()
                      ..color = accent
                      ..strokeWidth = 1.6
                      ..style = PaintingStyle.stroke,
                  );
                  final boxIn = box;
                  canvas.drawRect(
                    boxIn,
                    Paint()
                      ..color = accent
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 1.2,
                  );
                  final rotate = Offset(boxIn.center.dx, boxIn.bottom + 26);
                  canvas.drawLine(
                    Offset(boxIn.center.dx, boxIn.bottom),
                    rotate,
                    Paint()
                      ..color = accent
                      ..strokeWidth = 1.4,
                  );
                  final white = Paint()..color = Colors.white;
                  final ring = Paint()
                    ..color = accent
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 1.4;
                  for (final h in [
                    boxIn.topLeft,
                    boxIn.topRight,
                    boxIn.bottomLeft,
                    boxIn.bottomRight,
                    rotate,
                  ]) {
                    canvas.drawCircle(h, 5, white);
                    canvas.drawCircle(h, 5, ring);
                  }
                  // the finger on the corner while it resizes
                  final resizing = _span(t, 0.6, 0.62) - _span(t, 0.75, 0.77);
                  if (resizing > 0) {
                    canvas.drawCircle(
                      boxIn.bottomRight,
                      13,
                      Paint()
                        ..color = accent.withValues(alpha: 0.22 * resizing),
                    );
                  }
                },
              ),
              if (barShown > 0)
                Positioned.fill(
                  child: Opacity(
                    opacity: barShown,
                    child: SelectionActionBar(
                      bounds: () => box.shift(page),
                      repositioned: const AlwaysStoppedAnimation(0),
                      color: pickedColor,
                      onColor: (_) {},
                      onStroke: null,
                      onEditShape: null,
                      editingShape: false,
                      onResize: null,
                      cut: _noop,
                      copy: _noop,
                      duplicate: _noop,
                      delete: _noop,
                      front: _noop,
                      back: _noop,
                      moreEntries: () => const [],
                      screenshot: _noop,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ]);
  },
);

// ---------------------------------------------------------------------------
// 3. Shapes: rough, held, snapped
// ---------------------------------------------------------------------------

/// A shape drawn by hand ([rough]) and the clean one it snaps to, point for
/// point.
typedef _Shape = ({List<Offset> rough, List<Offset> clean});

final _shapes = () {
  _Shape circle(Offset c, double r) {
    const n = 70;
    final rough = <Offset>[], clean = <Offset>[];
    for (var i = 0; i <= n; i++) {
      final a = -2.3 + i / n * 2 * pi * 1.05;
      final k = 1 + 0.06 * sin(3 * a + 1) + 0.03 * sin(7 * a);
      rough.add(c + Offset(cos(a) * r * k * 1.07, sin(a) * r * k * 0.93));
      clean.add(c + Offset(cos(a) * r, sin(a) * r));
    }
    return (rough: rough, clean: clean);
  }

  _Shape box(Rect r) {
    final corners = [r.topLeft, r.topRight, r.bottomRight, r.bottomLeft];
    const n = 88;
    final rough = <Offset>[], clean = <Offset>[];
    for (var i = 0; i <= n; i++) {
      final u = 0.04 + i / n * 4.04;
      final side = u.floor() % 4;
      final f = u - u.floor();
      final a = corners[side], b = corners[(side + 1) % 4];
      final p = Offset.lerp(a, b, f)!;
      final along = (b - a) / (b - a).distance;
      final normal = Offset(-along.dy, along.dx);
      // a slight bow along each side and softer corners
      final bow = sin(pi * f) * (side.isEven ? 5 : -4) + 1.6 * sin(u * 11);
      final soft = f < 0.08
          ? along * (0.08 - f) * 40
          : f > 0.92
          ? -along * (f - 0.92) * 40
          : Offset.zero;
      rough.add(p + normal * bow + soft);
      clean.add(p);
    }
    return (rough: rough, clean: clean);
  }

  _Shape arrow(Offset a, Offset b) {
    final along = (b - a) / (b - a).distance;
    final normal = Offset(-along.dy, along.dx);
    Offset head(double turn) =>
        Offset(
          along.dx * cos(turn) - along.dy * sin(turn),
          along.dx * sin(turn) + along.dy * cos(turn),
        ) *
        -20;
    final rough = [a], clean = [a];
    void segment(Offset from, Offset to, int n, double sag) {
      for (var i = 1; i <= n; i++) {
        final f = i / n;
        final p = Offset.lerp(from, to, f)!;
        clean.add(p);
        rough.add(p + normal * (sin(pi * f) * sag + 0.12 * sag * sin(f * 17)));
      }
    }

    segment(a, b, 36, 9);
    segment(b, b + head(0.5), 8, 1.5);
    segment(b + head(0.5), b, 8, -1.2);
    segment(b, b + head(-0.5), 8, 1.2);
    return (rough: rough, clean: clean);
  }

  return [
    circle(const Offset(170, 300), 70),
    box(const Rect.fromLTRB(370, 236, 550, 366)),
    arrow(const Offset(256, 304), const Offset(358, 300)),
  ];
}();

Widget shapesDemo() => _Loop(
  duration: const Duration(milliseconds: 8000),
  rest: 0.92,
  builder: (context, t) {
    final colors = BadNotesColors.of(context);
    final pageDark = _pagesDark(context) ? 1.0 : 0.0;
    final ink = _inkColor(pageDark);
    // each shape: drawn, held still, snapped
    const times = [
      (0.04, 0.2, 0.27, 0.31),
      (0.34, 0.5, 0.57, 0.61),
      (0.64, 0.74, 0.8, 0.84),
    ];
    return _desk(context, [
      _fading(
        t,
        Stack(
          children: [
            _page(
              context,
              const Rect.fromLTWH(24, 20, 592, 460),
              inks: [const _Ink(_topology, at: Offset(36, 26), scale: 0.62)],
              extra: (canvas) {
                final line = Paint()
                  ..color = ink
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 3
                  ..strokeCap = StrokeCap.round
                  ..strokeJoin = StrokeJoin.round;
                for (var s = 0; s < _shapes.length; s++) {
                  final (start, drawn, held, snapped) = times[s];
                  if (t < start) break;
                  final shape = _shapes[s];
                  final d = _span(t, start, drawn, Curves.easeInOut);
                  final snap = _span(t, held, snapped, Curves.easeOutBack);
                  final n = max(2, (shape.rough.length * d).round());
                  final points = [
                    for (var i = 0; i < n; i++)
                      Offset.lerp(shape.rough[i], shape.clean[i], snap)!,
                  ];
                  _polyline(canvas, points, line);
                  // the pen held still: a ring grows round its tip
                  if (t >= drawn && t < snapped) {
                    final h = _span(t, drawn, held, Curves.easeOut);
                    canvas.drawCircle(
                      points.last,
                      7 + 11 * h,
                      Paint()
                        ..color = colors.accent.withValues(alpha: 0.6 * (1 - h))
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 2,
                    );
                  }
                  if (t < held) _drawTip(canvas, points.last, colors.accent);
                }
              },
            ),
          ],
        ),
      ),
    ]);
  },
);

// ---------------------------------------------------------------------------
// 4. Handwriting search
// ---------------------------------------------------------------------------

Widget searchDemo() => _Loop(
  duration: const Duration(milliseconds: 8000),
  rest: 0.62,
  builder: (context, t) {
    final colors = BadNotesColors.of(context);
    const pageRect = Rect.fromLTWH(20, 20, 392, 460);
    const metricAt = Offset(16, 40), metricScale = 0.38;
    const query = 'metric';
    final typed = (query.length * _span(t, 0.08, 0.3, Curves.linear)).floor();
    final found = _span(t, 0.33, 0.4);
    final marks = _span(t, 0.38, 0.46);
    final chosen = _span(t, 0.5, 0.56);
    final words = [
      for (final w in _metric.words)
        Rect.fromLTRB(
          metricAt.dx + w.left * metricScale,
          metricAt.dy + w.top * metricScale,
          metricAt.dx + w.right * metricScale,
          metricAt.dy + w.bottom * metricScale,
        ).inflate(2),
    ];
    final zoom = 1 + 0.22 * _span(t, 0.54, 0.7) - 0.22 * _span(t, 0.84, 0.93);
    final caretOn = (t * 16).floor().isEven || typed < query.length;

    Widget result(String before, String match, String after, bool on) =>
        Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
          decoration: BoxDecoration(
            color: Color.lerp(
              colors.surface.withValues(alpha: 0),
              colors.accentTint,
              on ? chosen : 0,
            ),
            borderRadius: const BorderRadius.all(
              Radius.circular(BnRadius.control),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Text(
                'Handwriting · Page 1',
                style: BnType.micro.copyWith(color: colors.muted),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: before),
                    TextSpan(
                      text: match,
                      style: TextStyle(
                        backgroundColor: colors.accentSoft,
                        color: colors.highlightText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(text: after),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BnType.body.copyWith(color: colors.text),
              ),
            ],
          ),
        );

    return _desk(context, [
      _camera(
        zoom,
        _focusOn(words.first.center + pageRect.topLeft),
        _fading(
          t,
          Stack(
            children: [
              _page(
                context,
                pageRect,
                inks: [
                  const _Ink(_metric, at: metricAt, scale: metricScale),
                  const _Ink(_axioms, at: Offset(16, 170), scale: 0.4),
                ],
                extra: (canvas) {
                  if (marks <= 0) return;
                  // as the editor marks a match on the page
                  final fill = Paint()
                    ..color = const Color(0xFFFFC107)
                        .withValues(alpha: 0.45 * marks);
                  for (final w in words) {
                    canvas.drawRRect(
                      RRect.fromRectAndRadius(w, const Radius.circular(3)),
                      fill,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
      Positioned(
        left: 424,
        top: 20,
        right: 16,
        child: _fading(
          t,
          BnPopover(
            padding: const EdgeInsets.all(10),
            shadow: BnShadows.panel,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: colors.sunken,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(BnRadius.control),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(BnIcons.search, size: 16, color: colors.muted),
                      const SizedBox(width: 8),
                      if (typed == 0)
                        Expanded(
                          child: Text(
                            'Search this note',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: BnType.body.copyWith(color: colors.faint),
                          ),
                        )
                      else
                        Text(
                          query.substring(0, typed),
                          style: BnType.body.copyWith(color: colors.text),
                        ),
                      if (caretOn && typed > 0)
                        Container(
                          width: 1.5,
                          height: 16,
                          margin: const EdgeInsets.only(left: 1),
                          color: colors.accent,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Opacity(
                  opacity: found,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 4,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10, bottom: 2),
                        child: Text(
                          '2 results',
                          style: BnType.caption.copyWith(
                            color: colors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      result('', 'Metric', ' Spaces', true),
                      result('A ', 'metric', ' space (X, d) is', false),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ]);
  },
);

// ---------------------------------------------------------------------------
// 5. Recording: real-time reveal, then spotlight
// ---------------------------------------------------------------------------

Widget recordingDemo() => _Loop(
  duration: const Duration(milliseconds: 10000),
  rest: 0.8,
  builder: (context, t) {
    final colors = BadNotesColors.of(context);
    final spotlight = t >= 0.5;
    final progress = spotlight
        ? _span(t, 0.53, 0.93, Curves.linear)
        : _span(t, 0.03, 0.46, Curves.linear);
    final pageDark = _pagesDark(context) ? 1.0 : 0.0;
    final ink = _Ink(
      _goldenProof,
      at: const Offset(175, 66),
      scale: 0.85,
      progress: progress,
      ghost: spotlight ? _inkColor(pageDark).withValues(alpha: 0.16) : null,
    );
    final seconds = (t * 135).round();
    String clock(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
    return _desk(context, [
      _fading(
        t,
        Stack(
          children: [
            _page(
              context,
              const Rect.fromLTWH(40, 20, 560, 460),
              inks: [ink],
              extra: (canvas) => _drawTip(canvas, ink.tip, colors.accent),
            ),
            Positioned(
              top: 34,
              left: 0,
              right: 0,
              child: Center(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.circular(BnRadius.control),
                    ),
                    boxShadow: BnShadows.floating,
                  ),
                  child: SizedBox(
                    width: 300,
                    child: BnSegmented<String>(
                      segments: const [
                        BnSegment('reveal', 'Real-time reveal'),
                        BnSegment('spotlight', 'Spotlight'),
                      ],
                      selected: spotlight ? 'spotlight' : 'reveal',
                      height: 34,
                      onChanged: (_) {},
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 110,
              right: 110,
              bottom: 26,
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border.all(color: colors.hairline),
                  borderRadius: const BorderRadius.all(
                    Radius.circular(BnRadius.popover),
                  ),
                  boxShadow: BnShadows.floating,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: colors.text,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.pause_rounded,
                        color: colors.surface,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      clock(seconds),
                      style: BnType.caption.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, c) => Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: colors.sunken,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            Container(
                              height: 4,
                              width: c.maxWidth * t,
                              decoration: BoxDecoration(
                                color: colors.accent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            Positioned(
                              left: c.maxWidth * t - 6,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: colors.accent,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: colors.surface,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      clock(135),
                      style: BnType.caption.copyWith(color: colors.muted),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        out: 0.96,
      ),
    ]);
  },
);

// ---------------------------------------------------------------------------
// 6. Tape and dark pages
// ---------------------------------------------------------------------------

final _tapeStamps = <Rect, Path>{};

/// A strip of tape over [r], laid [laid] of the way along, and [peeked]
/// lifted, as the editor draws tape.
void _drawTape(Canvas canvas, Rect r, double laid, double peeked) {
  if (laid <= 0) return;
  const color = Color(0xFFFFB74D);
  final rect = Rect.fromLTWH(r.left, r.top, r.width * laid, r.height);
  final covered = 1 - peeked;
  if (covered > 0) {
    canvas.drawRect(
      rect.shift(const Offset(1.5, 3)).inflate(1),
      Paint()
        ..color = Color.fromRGBO(0, 0, 0, 0.33 * covered)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawRect(
      rect.inflate(1.5),
      Paint()
        ..color = Color.lerp(
          color,
          Colors.black,
          0.4,
        )!.withValues(alpha: covered),
    );
  }
  canvas.drawRect(
    rect,
    Paint()..color = Color.lerp(color, color.withValues(alpha: 0.2), peeked)!,
  );
  if (covered <= 0) return;
  final stamps = _tapeStamps.putIfAbsent(
    r,
    () => TapePattern.stripes.stamps(
      Path()
        ..moveTo(r.left, r.center.dy)
        ..lineTo(r.right, r.center.dy),
      r.height,
    ),
  );
  canvas.save();
  canvas.clipRect(rect);
  canvas.drawPath(
    stamps,
    Paint()..color = const Color(0x33000000).withValues(alpha: 0.2 * covered),
  );
  canvas.restore();
}

Widget tapeDemo() => _Loop(
  duration: const Duration(milliseconds: 9000),
  rest: 0.55,
  builder: (context, t) {
    final colors = BadNotesColors.of(context);
    const at = Offset(20, 130), scale = 0.6;
    final tapes = [
      for (final w in _axioms.words)
        Rect.fromLTRB(
          at.dx + w.left * scale,
          at.dy + w.top * scale,
          at.dx + w.right * scale,
          at.dy + w.bottom * scale,
        ).inflate(7),
    ];
    final laid = [_span(t, 0.06, 0.16), _span(t, 0.16, 0.26)];
    final taps = [0.36, 0.5];
    final peeked = [for (final tap in taps) _span(t, tap + 0.02, tap + 0.06)];
    final start = _pagesDark(context) ? 1.0 : 0.0;
    final dark = (start - _span(t, 0.62, 0.74)).abs();
    return _desk(context, [
      _fading(
        t,
        Stack(
          children: [
            _page(
              context,
              const Rect.fromLTWH(24, 20, 592, 460),
              dark: dark,
              inks: [const _Ink(_axioms, at: at, scale: scale)],
              extra: (canvas) {
                for (var i = 0; i < tapes.length; i++) {
                  _drawTape(canvas, tapes[i], laid[i], peeked[i]);
                  final tap = _span(t, taps[i], taps[i] + 0.08, Curves.easeOut);
                  if (tap > 0 && tap < 1) {
                    canvas.drawCircle(
                      tapes[i].center,
                      8 + 16 * tap,
                      Paint()
                        ..color = colors.accent.withValues(alpha: 1 - tap)
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 2,
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    ]);
  },
);

// ---------------------------------------------------------------------------
// 7. Tabs and split view
// ---------------------------------------------------------------------------

Widget _tab(
  BuildContext context,
  String name, {
  required bool active,
  required Color mark,
  double lift = 0,
}) {
  final colors = BadNotesColors.of(context);
  return Container(
    height: 38,
    constraints: const BoxConstraints(minWidth: 90, maxWidth: 220),
    padding: const EdgeInsets.only(left: 12, right: 10),
    decoration: BoxDecoration(
      color: active || lift > 0 ? colors.surface : null,
      borderRadius: lift > 0
          ? const BorderRadius.all(Radius.circular(10))
          : const BorderRadius.vertical(top: Radius.circular(10)),
      border: active
          ? Border(
              top: BorderSide(color: colors.hairline),
              left: BorderSide(color: colors.hairline),
              right: BorderSide(color: colors.hairline),
            )
          : lift > 0
          ? Border.all(color: colors.hairline)
          : null,
      boxShadow: lift > 0 ? BnShadows.floating : null,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        Container(
          width: 10,
          height: 13,
          decoration: BoxDecoration(
            color: mark,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(1.5),
              right: Radius.circular(3),
            ),
          ),
        ),
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: BnType.body.copyWith(
              color: active ? colors.text : colors.text2,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
        if (active) Icon(BnIcons.close, size: 13, color: colors.muted),
      ],
    ),
  );
}

Widget splitDemo() => _Loop(
  duration: const Duration(milliseconds: 8000),
  rest: 0.8,
  builder: (context, t) {
    final colors = BadNotesColors.of(context);
    final scheme = ColorScheme.of(context);
    final ui = EditorUi.of(context);
    final lift = _span(t, 0.1, 0.16) - _span(t, 0.4, 0.44);
    final drag = _span(t, 0.16, 0.4);
    final zone = _span(t, 0.24, 0.32) - _span(t, 0.42, 0.48);
    final split = _span(t, 0.42, 0.6);
    const tabB = Offset(190, 4);
    const dropAt = Offset(420, 240);
    // the dragged tab follows a gentle curve down to the page
    final dragged =
        Offset.lerp(tabB, dropAt, drag)! + Offset(0, -40 * sin(pi * drag));
    const single = Rect.fromLTWH(150, 54, 340, 440);
    final left = Rect.lerp(
      single,
      const Rect.fromLTWH(14, 54, 296, 440),
      split,
    )!;
    final right = Rect.lerp(
      const Rect.fromLTWH(640, 54, 296, 440),
      const Rect.fromLTWH(330, 54, 296, 440),
      split,
    )!;
    return _fading(
      t,
      ColoredBox(
        color: ui.tabStrip,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(top: 38, child: ColoredBox(color: ui.desk)),
            Positioned(
              top: 37,
              left: 0,
              right: 0,
              child: Container(height: 1, color: colors.hairline),
            ),
            _page(
              context,
              left,
              inks: const [_Ink(_topology, at: Offset(22, 40), scale: 0.8)],
            ),
            if (split > 0)
              _page(
                context,
                right,
                inks: [
                  const _Ink(_metric, at: Offset(10, 40), scale: 0.3),
                  const _Ink(_axioms, at: Offset(10, 150), scale: 0.3),
                ],
              ),
            if (split > 0)
              Positioned(
                left: 316 + (1 - split) * 324,
                top: 54,
                bottom: 0,
                width: 8,
                child: Opacity(
                  opacity: split,
                  child: ColoredBox(
                    color: scheme.surfaceContainerHighest,
                    child: Center(
                      child: Container(
                        width: 4,
                        height: 28,
                        decoration: BoxDecoration(
                          color: scheme.onSurfaceVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (zone > 0)
              Positioned(
                left: 324,
                top: 58,
                right: 10,
                bottom: 10,
                child: Opacity(
                  opacity: zone,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.accent.withValues(alpha: 0.12),
                      border: Border.all(color: colors.accent, width: 2),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(BnRadius.card),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 8,
              top: 4,
              child: _tab(
                context,
                'Topology week 1',
                active: true,
                mark: BnFolderColor.lavender.back,
              ),
            ),
            Positioned(
              left: dragged.dx,
              top: dragged.dy,
              child: Transform.scale(
                scale: 1 + 0.06 * lift,
                child: _tab(
                  context,
                  'Metric Spaces',
                  active: false,
                  mark: BnFolderColor.mint.back,
                  lift: lift,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  },
);

// ---------------------------------------------------------------------------
// 8. Toolbar floating or docked, light or dark
// ---------------------------------------------------------------------------

final _themes = <Brightness, ThemeData>{};
ThemeData _theme(Brightness b) =>
    _themes.putIfAbsent(b, () => BadNotesTheme.create(b));

/// The editor with its tools floating ([docked] 0) or in the header (1).
Widget _editor(BuildContext context, double docked) {
  final colors = BadNotesColors.of(context);
  final ui = EditorUi.of(context);
  final frame = 1 - docked;
  final tools = [
    const BnToolButton(
      label: 'Lasso',
      path: BnToolIcons.lasso,
      dashed: true,
      onTap: null,
    ),
    BnToolButton(
      label: 'Pen',
      path: BnToolIcons.fountain,
      selected: true,
      inkColor: _inkColor(_pagesDark(context) ? 1 : 0),
      onTap: null,
    ),
    const BnToolButton(
      label: 'Highlighter',
      path: BnToolIcons.highlighter,
      inkColor: Color(0xFFFFD54F),
      onTap: null,
    ),
    const BnToolButton(
      label: 'Draw shapes',
      path: BnToolIcons.drawShapes,
      onTap: null,
    ),
    const BnToolButton(label: 'Tape', path: BnToolIcons.tape, onTap: null),
    const BnToolButton(label: 'Eraser', path: BnToolIcons.eraser, onTap: null),
    const BnToolButton(
      label: 'Laser',
      path: BnToolIcons.laser,
      centerDot: Color(0xFFF44336),
      onTap: null,
    ),
  ];
  return ColoredBox(
    color: ui.desk,
    child: Stack(
      children: [
        _page(
          context,
          const Rect.fromLTWH(110, 72, 420, 440),
          inks: const [
            _Ink(_goldenEq, at: Offset(18, 70), scale: 0.62),
            _Ink(_goldenProof, at: Offset(70, 150), scale: 0.62),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 58,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: ui.topBar,
              border: Border(bottom: BorderSide(color: colors.hairline)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(BnIcons.back, size: 22, color: ui.topBarIcon),
                const SizedBox(width: 4),
                Text(
                  'Golden ratio',
                  style: BnType.title.copyWith(color: colors.text),
                ),
                const Spacer(),
                Icon(BnIcons.search, size: 20, color: ui.topBarIcon),
                const SizedBox(width: 18),
                Icon(BnIcons.more, size: 20, color: ui.topBarIcon),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ),
        Positioned(
          top: 84 - 81 * docked,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.97 * frame),
                border: Border.all(
                  color: colors.hairline.withValues(alpha: frame),
                ),
                borderRadius: const BorderRadius.all(
                  Radius.circular(BnRadius.dock),
                ),
                boxShadow: BoxShadow.lerpList(
                  BnShadows.floating,
                  const [],
                  docked,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 2,
                children: tools,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _CircleClip extends CustomClipper<Path> {
  new(this.center, this.radius);

  final Offset center;
  final double radius;

  @override
  Path getClip(Size size) =>
      Path()..addOval(Rect.fromCircle(center: center, radius: radius));

  @override
  bool shouldReclip(_CircleClip old) =>
      old.radius != radius || old.center != center;
}

Widget toolbarDemo() => _Loop(
  duration: const Duration(milliseconds: 9000),
  rest: 0.4,
  builder: (context, t) {
    final docked = _span(t, 0.18, 0.34);
    final reveal = _span(t, 0.5, 0.68, Curves.easeInOutCubic);
    final now = Theme.brightnessOf(context);
    final other = now == Brightness.light ? Brightness.dark : Brightness.light;
    const from = Offset(640, 0);
    Widget editorIn(Brightness b) => Theme(
      data: _theme(b),
      child: Builder(builder: (context) => _editor(context, docked)),
    );
    return _fading(
      t,
      Stack(
        children: [
          if (reveal < 1) Positioned.fill(child: editorIn(now)),
          if (reveal > 0)
            Positioned.fill(
              child: ClipPath(
                clipper: _CircleClip(from, 820 * reveal),
                child: editorIn(other),
              ),
            ),
        ],
      ),
    );
  },
);

// ---------------------------------------------------------------------------
// 9. Present: the laser, and going live
// ---------------------------------------------------------------------------

final _laserPath = () {
  final points = <Offset>[];
  // round "Find r = a/c", then a quick underline
  const c = Offset(470, 150);
  for (var i = 0; i <= 60; i++) {
    final a = 2.6 + i / 60 * 2 * pi * 1.08;
    final k = 1 + 0.05 * sin(2 * a);
    points.add(c + Offset(cos(a) * 150 * k, sin(a) * 56 * k));
  }
  for (var i = 0; i <= 16; i++) {
    final f = i / 16;
    points.add(
      Offset.lerp(const Offset(560, 200), const Offset(330, 212), f)! +
          Offset(0, sin(pi * f) * 6),
    );
  }
  return points;
}();

Widget presentDemo() => _Loop(
  duration: const Duration(milliseconds: 8000),
  rest: 0.85,
  builder: (context, t) {
    final colors = BadNotesColors.of(context);
    final drawn = _span(t, 0.06, 0.38, Curves.easeInOut);
    final gone = _span(t, 0.48, 0.6);
    final panel = _span(t, 0.6, 0.7, Curves.easeOutCubic);
    final chosen = _span(t, 0.76, 0.8);
    const laserColor = Color(0xFFF44336);

    Widget tile(IconData icon, String label, double on) => Expanded(
      child: Container(
        height: 74,
        decoration: BoxDecoration(
          color: Color.lerp(colors.surface, colors.accentTint, on),
          border: Border.all(
            color: Color.lerp(colors.hairline, colors.accent, on)!,
            width: 1 + on,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(BnRadius.tool)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 6,
          children: [
            Icon(
              icon,
              size: 22,
              color: Color.lerp(colors.text2, colors.accent, on),
            ),
            Text(
              label,
              style: BnType.caption.copyWith(
                color: colors.text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );

    return _desk(context, [
      _fading(
        t,
        Stack(
          children: [
            _page(
              context,
              const Rect.fromLTWH(24, 20, 592, 460),
              inks: const [
                _Ink(_goldenEq, at: Offset(16, 100), scale: 0.92),
                _Ink(_goldenProof, at: Offset(150, 230), scale: 0.5),
              ],
              extra: (canvas) {
                final n = (_laserPath.length * drawn).round();
                if (n < 2 || gone >= 1) return;
                final opacity = 1 - gone;
                final path = Path()
                  ..moveTo(_laserPath.first.dx - 24, _laserPath.first.dy - 20);
                for (final p in _laserPath.take(n).skip(1)) {
                  path.lineTo(p.dx - 24, p.dy - 20);
                }
                // as the editor draws the laser: a soft glow in bands, the
                // line, and a white core
                const size = 6.0;
                final paint = Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeCap = StrokeCap.round
                  ..strokeJoin = StrokeJoin.round;
                for (final (width, alpha) in const [
                  (4.2, 0.05),
                  (3.0, 0.08),
                  (2.1, 0.13),
                  (1.45, 0.22),
                ]) {
                  canvas.drawPath(
                    path,
                    paint
                      ..color = laserColor.withValues(alpha: alpha * opacity)
                      ..strokeWidth = size * width,
                  );
                }
                canvas.drawPath(
                  path,
                  paint
                    ..color = laserColor.withValues(alpha: opacity)
                    ..strokeWidth = size * 0.75,
                );
                canvas.drawPath(
                  path,
                  paint
                    ..color = Colors.white.withValues(alpha: 0.85 * opacity)
                    ..strokeWidth = size * 0.28,
                );
              },
            ),
            if (panel > 0)
              Positioned(
                left: 120,
                right: 120,
                bottom: 24 - 30 * (1 - panel),
                child: Opacity(
                  opacity: panel,
                  child: BnPopover(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Present',
                          style: BnType.caption.copyWith(
                            color: colors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          spacing: 8,
                          children: [
                            tile(Icons.cast_outlined, 'Everything live', 0),
                            tile(Icons.draw_outlined, 'Ink only', chosen),
                            tile(Icons.fullscreen, 'Full page focus', 0),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ]);
  },
);

// ---------------------------------------------------------------------------
// 10. Pin board: the desk's real board
// ---------------------------------------------------------------------------

final _boardInk = () {
  // "Topology" and its braces, on a note 320 units wide
  const k = 0.82, ox = 26.0, oy = 70.0, w = 320.0;
  return [
    for (final s in _topology.strokes)
      BoardStroke(
        tool: QuickTool.fountain,
        color: BnColors.inkBlack,
        points: [
          for (var i = 0; i < s.length; i += 3) ...[
            (s[i] * k + ox) / w,
            (s[i + 1] * k + oy) / w,
            s[i + 2],
          ],
        ],
        width: 2.6 / w,
      ),
  ];
}();

final _boardDay = DateTime(2026);

List<BoardItem> _boardItems(double t) {
  BoardItem note(
    String id,
    Rect box, {
    String text = '',
    int color = 0,
    double angle = 0,
    int deco = 1,
    int shape = 0,
    int z = 0,
    List<BoardStroke> ink = const [],
    List<String> labels = const [],
    int? decoColor,
  }) => BoardItem(
    id: id,
    photo: null,
    text: text,
    color: color,
    box: box,
    angle: angle,
    deco: deco,
    noteShape: shape,
    z: z,
    ink: ink,
    labels: labels,
    decoColor: decoColor,
    createdAt: _boardDay,
    updatedAt: _boardDay,
  );

  // the last note is picked up and put down in its place
  final move = _span(t, 0.18, 0.5);
  const from = Rect.fromLTWH(520, 340, 330, 260);
  const to = Rect.fromLTWH(140, 400, 330, 260);
  return [
    note(
      'a',
      const Rect.fromLTWH(40, 40, 300, 280),
      text: 'Revise metric spaces before Friday',
      angle: -0.035,
      labels: const ['exam'],
    ),
    note(
      'b',
      const Rect.fromLTWH(370, 56, 320, 270),
      color: 5,
      shape: 3,
      angle: 0.025,
      deco: 2,
      ink: _boardInk,
    ),
    note(
      'c',
      const Rect.fromLTWH(720, 36, 250, 290),
      text: 'Ask about the tape quiz',
      color: 2,
      shape: 2,
      angle: 0.04,
      deco: 3,
    ),
    note(
      'd',
      Rect.lerp(from, to, move)!,
      text: 'Golden ratio\nr = (1 + √5) / 2',
      color: 3,
      shape: 1,
      angle: 0.16 - 0.19 * move,
      z: 5,
      decoColor: 0xFF2B4ACB,
    ),
  ];
}

Widget pinBoardDemo() => _Loop(
  duration: const Duration(milliseconds: 8000),
  rest: 0.9,
  builder: (context, t) => _fading(
    t,
    _camera(
      1.04 - 0.04 * _span(t, 0, 1, Curves.easeOut),
      Alignment.center,
      IgnorePointer(
        child: PinBoard(
          items: _boardItems(t),
          openNote: (_, _) {},
          openPhoto: (_, _) {},
          minHeight: _stage.height,
        ),
      ),
    ),
  ),
);

// ---------------------------------------------------------------------------
// 11. Version history
// ---------------------------------------------------------------------------

Widget versionsDemo() => _Loop(
  duration: const Duration(milliseconds: 9000),
  rest: 0.6,
  builder: (context, t) {
    final colors = BadNotesColors.of(context);
    // from now back to the oldest version, a step at a time
    const kept = [1.0, 0.72, 0.46, 0.22];
    final now = DateTime.now();
    final times = [
      now.subtract(const Duration(minutes: 12)),
      now.subtract(const Duration(hours: 2, minutes: 5)),
      now.subtract(const Duration(days: 1, hours: 3)),
      now.subtract(const Duration(days: 4)),
    ];
    final selected =
        _span(t, 0.22, 0.28) + _span(t, 0.42, 0.48) + _span(t, 0.62, 0.68);
    final step = selected.floor();
    final f = selected - step;
    final shown = step >= 3
        ? kept[3]
        : kept[step] + (kept[step + 1] - kept[step]) * f;

    Widget row(int i) {
      final on = (1 - (selected - i).abs()).clamp(0.0, 1.0);
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color.lerp(
            colors.accentTint.withValues(alpha: 0),
            colors.accentTint,
            on,
          ),
          border: Border.all(
            color: colors.accent.withValues(alpha: on),
            width: 1.5,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(BnRadius.card)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 56,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border.all(color: colors.hairline),
                borderRadius: const BorderRadius.all(Radius.circular(4)),
              ),
              child: Stack(
                children: [
                  _page(
                    context,
                    const Rect.fromLTWH(-1, -1, 44, 56),
                    inks: [
                      _Ink(
                        _goldenProof,
                        at: const Offset(4, 6),
                        scale: 0.095,
                        progress: kept[i],
                        pen: 9,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    versionLabel(times[i], now),
                    style: BnType.body.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '1 page',
                    style: BnType.caption.copyWith(color: colors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return _desk(context, [
      _fading(
        t,
        Stack(
          children: [
            _page(
              context,
              const Rect.fromLTWH(20, 20, 290, 460),
              inks: [
                _Ink(
                  _goldenProof,
                  at: const Offset(14, 40),
                  scale: 0.68,
                  progress: shown,
                ),
              ],
            ),
            Positioned(
              left: 326,
              right: 16,
              top: 20,
              child: BnPopover(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text.rich(
                      const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Version history',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          TextSpan(text: ' · Golden ratio'),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BnType.bodyLarge.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kept automatically while you work',
                      style: BnType.caption.copyWith(color: colors.muted),
                    ),
                    const SizedBox(height: 10),
                    for (var i = 0; i < 4; i++) ...[
                      row(i),
                      const SizedBox(height: 4),
                    ],
                    const SizedBox(height: 6),
                    const Row(
                      spacing: 8,
                      children: [
                        Expanded(
                          child: BnButton(
                            label: 'Open as a copy',
                            onPressed: _noop,
                            expand: true,
                          ),
                        ),
                        Expanded(
                          child: BnButton.primary(
                            label: 'Restore',
                            onPressed: _noop,
                            expand: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ]);
  },
);

// ---------------------------------------------------------------------------
// 12. Get started
// ---------------------------------------------------------------------------

Widget startDemo() => _Loop(
  duration: const Duration(milliseconds: 3200),
  rest: 0.3,
  builder: (context, t) {
    final colors = BadNotesColors.of(context);
    final scheme = ColorScheme.of(context);
    // a ring that keeps going out from the New button
    final ring = _span(t, 0.1, 0.8, Curves.easeOut);
    return ColoredBox(
      color: colors.desk,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BnLogo(size: 104),
            const SizedBox(height: 22),
            Text(
              'BadNotes',
              style: BnType.display.copyWith(color: colors.text),
            ),
            const SizedBox(height: 40),
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 104 + 40 * ring,
                  height: 42 + 40 * ring,
                  decoration: ShapeDecoration(
                    shape: StadiumBorder(
                      side: BorderSide(
                        color: scheme.primary.withValues(
                          alpha: 0.5 * (1 - ring),
                        ),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: ShapeDecoration(
                    color: scheme.primary,
                    shape: const StadiumBorder(),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 8,
                    children: [
                      Icon(Icons.add, size: 22, color: scheme.onPrimary),
                      Text(
                        'New',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  },
);
