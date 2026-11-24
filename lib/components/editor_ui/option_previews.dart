import 'dart:math' as math;

import 'package:badnotes/components/canvas/shape_style.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/theming/badnotes_tokens.dart';
import 'package:badnotes/data/extensions/color_extensions.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/tools/eraser.dart';
import 'package:badnotes/data/tools/pressure_curve.dart';
import 'package:badnotes/data/tools/tape.dart';
import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

// Small previews that play in settings panels, showing what an option does.
// They look and move like the Record panel's [PlaybackPreview]: the same
// paper, ink and "hello", written over most of a 3.2 s loop and then held,
// with one controller each that stops with the panel (its ticker is muted
// when the route is covered, and disposed with it).

/// A handwritten "hello" in a 100 by 44 box: the word every preview writes.
final previewWord = Path()
  ..moveTo(8, 34)
  ..cubicTo(14, 10, 22, 6, 18, 20)
  ..cubicTo(15, 32, 14, 38, 18, 34)
  ..cubicTo(22, 24, 30, 22, 30, 34)
  ..cubicTo(34, 26, 44, 24, 42, 30)
  ..cubicTo(38, 36, 46, 38, 52, 32)
  ..cubicTo(60, 14, 62, 6, 58, 20)
  ..cubicTo(55, 34, 60, 38, 66, 32)
  ..cubicTo(74, 14, 76, 6, 72, 20)
  ..cubicTo(69, 34, 74, 38, 80, 32)
  ..cubicTo(84, 24, 94, 26, 90, 34)
  ..cubicTo(86, 40, 80, 32, 86, 28);

const _paper = Color(0xFFFFFDF6);
const _ink = Color(0xFF1C1C1E);

/// A line of ink, as [PlaybackPreview] writes it.
Paint _pen([Color color = _ink, double width = 2.4]) => Paint()
  ..color = color
  ..style = PaintingStyle.stroke
  ..strokeWidth = width
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

/// 0 until [t] reaches [from], 1 from [to] on, and in between in step.
double _span(double t, double from, double to) =>
    ((t - from) / (to - from)).clamp(0.0, 1.0);

/// The first [t] (0 to 1) of [path], as if being written.
Path _written(Path path, double t) {
  final out = Path();
  final metrics = path.computeMetrics().toList();
  var left = t * metrics.fold(0.0, (sum, m) => sum + m.length);
  for (final m in metrics) {
    if (left <= 0) break;
    out.addPath(m.extractPath(0, math.min(left, m.length)), Offset.zero);
    left -= m.length;
  }
  return out;
}

/// Where the pen is after writing [t] of a one-line [path].
Offset _tip(Path path, double t) {
  final m = path.computeMetrics().first;
  return m.getTangentForOffset(m.length * t)?.position ?? Offset.zero;
}

/// How tall every preview is: each fills the width it's given, so they all
/// line up wherever they sit.
const previewHeight = 96.0;

/// One preview: [painter] on [PlaybackPreview]'s paper (unless not [paper]),
/// the whole width and [previewHeight] tall, looping every 3.2 s; still at
/// [still] when the system asks for less motion.
class _Looping extends StatefulWidget {
  const new({
    required this.painter,
    this.still = 0.75,
    this.paper = true,
  });

  final CustomPainter Function(Animation<double> clock, BuildContext context)
  painter;
  final double still;
  final bool paper;

  @override
  State<_Looping> createState() => _LoopingState();
}

class _LoopingState extends State<_Looping>
    with SingleTickerProviderStateMixin {
  late final _clock = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    if (MediaQuery.disableAnimationsOf(context)) {
      _clock
        ..stop()
        ..value = widget.still;
    } else if (!_clock.isAnimating) {
      _clock.repeat();
    }
    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        height: previewHeight,
        clipBehavior: widget.paper ? Clip.antiAlias : Clip.none,
        decoration: widget.paper
            ? BoxDecoration(
                color: _paper,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.hairline),
              )
            : null,
        child: CustomPaint(painter: widget.painter(_clock, context)),
      ),
    );
  }
}

/// Repaints with the clock and with [prefs], so a change shows at once.
abstract class _Painter extends CustomPainter {
  _Painter(this.clock, [List<Listenable> prefs = const []])
    : super(repaint: Listenable.merge([clock, ...prefs]));

  final Animation<double> clock;

  double get t => clock.value;

  /// Moves the canvas so a [width] by [height] drawing sits in the middle.
  void center(Canvas canvas, Size size, double width, double height) =>
      canvas.translate((size.width - width) / 2, (size.height - height) / 2);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ---- 3. pressure curve ----

/// A line written from a light touch to pressing hard, through the pressure
/// curve as it's set now.
class PressurePreview extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => _Looping(
    still: 1,
    painter: (clock, _) => _PressurePainter(clock),
  );
}

class _PressurePainter extends _Painter {
  _PressurePainter(Animation<double> clock)
    : super(clock, [
        stows.pressureCurve,
        stows.pressureCurveX,
        stows.pressureCurveY,
      ]);

  @override
  void paint(Canvas canvas, Size size) {
    final drawn = _span(t, 0, 0.7);
    if (drawn == 0) return;
    final gamma = PressureCurve.gamma;
    final width = size.width - 36;
    const steps = 60;
    PointVector at(double x) => PointVector(
      18 + x * width,
      size.height / 2 + 9 * math.sin(x * math.pi * 3),
      PressureCurve.apply(x, gamma),
    );
    final points = [
      for (var i = 0; i <= (steps * drawn).ceil(); i++)
        at(math.min(i / steps, drawn)),
    ];
    final outline = getStroke(
      points,
      options: StrokeOptions(
        size: 9,
        thinning: 0.9,
        smoothing: 0.5,
        streamline: 0.4,
        simulatePressure: false,
        isComplete: drawn == 1,
      ),
    );
    if (outline.isEmpty) return;
    canvas.drawPath(Path()..addPolygon(outline, true), Paint()..color = _ink);
  }
}

// ---- 4. lasso: what it picks ----

/// Handwriting, a photo, a shape, a text box and a sticky note; the lasso
/// goes round them and what it would pick up shows picked.
class LassoPreview extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => _Looping(
    still: 0.8,
    painter: (clock, context) =>
        _LassoPainter(clock, Theme.of(context).colorScheme.primary),
  );
}

class _LassoPainter extends _Painter {
  _LassoPainter(Animation<double> clock, this.primary)
    : super(clock, [stows.lassoFilter]);

  final Color primary;

  static final _loop = parseSvgPathData(
    'M120 3c64-2 116 12 116 44s-52 46-116 46S4 80 4 48 54 3 126 5',
  );
  static const _photo = Rect.fromLTWH(104, 12, 44, 30);
  static const _shape = Rect.fromLTWH(160, 18, 34, 24);
  static const _sticky = Rect.fromLTWH(120, 50, 30, 28);
  static final _text = TextPainter(
    text: const TextSpan(
      text: 'Typed',
      style: TextStyle(color: _ink, fontSize: 13),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  static const _textAt = Offset(52, 54);

  @override
  void paint(Canvas canvas, Size size) {
    center(canvas, size, 240, 96);
    final chosen = stows.lassoFilter.value;
    final done = t > 0.45;
    // picked: a soft blue edge behind it, as on the page
    final halo = _pen(primary.withValues(alpha: 0.22), 7);
    bool picked(String group) => done && chosen.contains(group);

    // handwriting
    canvas.save();
    canvas.translate(44, 12);
    canvas.scale(0.55);
    if (picked('handwriting')) {
      canvas.drawPath(previewWord, halo..strokeWidth = 3.6 + 7 / 0.55);
      halo.strokeWidth = 7;
    }
    canvas.drawPath(previewWord, _pen(_ink, 3.6));
    canvas.restore();

    // a photo
    final photo = RRect.fromRectAndRadius(_photo, const Radius.circular(3));
    if (picked('images')) canvas.drawRRect(photo, halo);
    canvas.save();
    canvas.clipRRect(photo);
    canvas.drawRect(_photo, Paint()..color = const Color(0xFFB9D3F2));
    canvas.drawPath(
      Path()
        ..moveTo(_photo.left, _photo.bottom)
        ..lineTo(_photo.left + 14, _photo.top + 14)
        ..lineTo(_photo.left + 24, _photo.top + 24)
        ..lineTo(_photo.left + 32, _photo.top + 16)
        ..lineTo(_photo.right, _photo.bottom)
        ..close(),
      Paint()..color = const Color(0x8C2B5C9E),
    );
    canvas.drawCircle(
      Offset(_photo.right - 9, _photo.top + 8),
      4,
      Paint()..color = Colors.white,
    );
    canvas.restore();

    // a shape, as draw & hold snaps it
    final shape = RRect.fromRectAndRadius(_shape, const Radius.circular(4));
    if (picked('shapes')) canvas.drawRRect(shape, halo);
    canvas.drawRRect(
      shape,
      Paint()..color = BnColors.inkBlue.withValues(alpha: 0.15),
    );
    canvas.drawRRect(shape, _pen(BnColors.inkBlue, 2));

    // a text box
    final box = (_textAt & _text.size).inflate(3);
    if (picked('textBoxes')) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(box, const Radius.circular(3)),
        halo,
      );
    }
    _text.paint(canvas, _textAt);

    // a sticky note
    final sticky = RRect.fromRectAndRadius(_sticky, const Radius.circular(2));
    if (picked('stickyNotes')) canvas.drawRRect(sticky, halo);
    canvas.drawRRect(sticky, Paint()..color = BnColors.noteButter);
    final lines = _pen(_ink.withValues(alpha: 0.35), 1.4);
    for (final y in [10.0, 16.0]) {
      canvas.drawLine(
        Offset(_sticky.left + 6, _sticky.top + y),
        Offset(_sticky.right - 6, _sticky.top + y),
        lines,
      );
    }

    // the lasso: solid while it's drawn, then marching ants
    if (!done) {
      final drawn = _span(t, 0.05, 0.42);
      if (drawn > 0) {
        canvas.drawPath(
          _written(_loop, drawn),
          Paint()
            ..color = primary
            ..strokeWidth = 1.6
            ..style = PaintingStyle.stroke,
        );
      }
      return;
    }
    _marchingAnts(canvas, _loop, primary, t);
  }
}

/// A lasso's loop once it has picked: a faint fill and marching ants, as on
/// the page.
void _marchingAnts(Canvas canvas, Path loop, Color primary, double t) {
  canvas.drawPath(loop, Paint()..color = primary.withValues(alpha: 0.08));
  canvas.drawPath(
    loop,
    Paint()
      ..color = Colors.white
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke,
  );
  const dash = 6.0, gap = 5.0;
  final phase = (t * 4) % 1;
  canvas.drawPath(
    dashPath(
      loop,
      dashArray: CircularIntervalList([dash, gap]),
      dashOffset: DashOffset.absolute((1 - phase) * (dash + gap)),
    ),
    Paint()
      ..color = primary
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke,
  );
}

// ---- 5. palm rejection ----

/// A hand resting while the pen writes; where it touches shows as grey dots,
/// ignored. On the side of the writing hand.
class PalmPreview extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => _Looping(
    still: 0.5,
    painter: (clock, _) => _PalmPainter(clock),
  );
}

class _PalmPainter extends _Painter {
  _PalmPainter(Animation<double> clock) : super(clock, [stows.leftHanded]);

  @override
  void paint(Canvas canvas, Size size) {
    final left = stows.leftHanded.value;
    final side = left ? -1.0 : 1.0;
    // the word on the far side from the hand, so the hand fits
    final at = Offset(
      size.width / 2 + (left ? -10 : -80),
      (size.height - 84) / 2 + 12,
    );
    const scale = 0.7;
    final written = _span(t, 0.08, 0.65);
    final down = t > 0.04 && t < 0.78;

    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.scale(scale);
    if (written > 0) {
      canvas.drawPath(_written(previewWord, written), _pen(_ink, 2.4 / scale));
    }
    canvas.restore();

    final fade = 1 - _span(t, 0.78, 0.9);
    if (fade == 0) return;
    final tip = at + _tip(previewWord, math.max(written, 0.001)) * scale;
    final palm = tip + Offset(side * 46, 32);
    // the pen, held by the hand
    canvas.drawLine(
      tip,
      tip + Offset(side * 26, -24),
      _pen(BnColors.text2.withValues(alpha: fade), 3),
    );
    canvas.save();
    canvas.translate(palm.dx, palm.dy);
    canvas.rotate(side * -0.35);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: 74, height: 40),
      Paint()..color = const Color(0xFFF2C2B1).withValues(alpha: 0.6 * fade),
    );
    canvas.restore();
    if (!down) return;
    // where it touches: ignored, as the test mode shows them
    final dot = Paint()..color = Colors.grey.withValues(alpha: 0.6 * fade);
    for (final o in const [Offset(-16, 4), Offset(0, 8), Offset(16, 2)]) {
      canvas.drawCircle(palm + Offset(o.dx * side, o.dy), 3.5, dot);
    }
  }
}

// ---- 6. eraser type ----

/// The eraser going down through a word: Precision takes only what it
/// touches; Whole stroke takes the whole line. The line under it stays.
class EraserPreview extends StatelessWidget {
  const new(this.type, {super.key});

  final EraserType type;

  @override
  Widget build(BuildContext context) => _Looping(
    still: 0.6,
    painter: (clock, _) => _EraserPainter(clock, type),
  );
}

/// What the eraser and scribble previews write: the word, and a line under
/// it.
final _underline = Path()
  ..moveTo(10, 47)
  ..cubicTo(36, 45, 64, 46, 92, 46);

class _EraserPainter extends _Painter {
  _EraserPainter(super.clock, this.type);

  final EraserType type;

  static const _radius = 7.0, _x = 44.0;

  @override
  void paint(Canvas canvas, Size size) {
    center(canvas, size, 100, 52);
    final back = _span(t, 0.85, 1);
    if (back > 0) {
      final ink = _pen(_ink.withValues(alpha: back));
      canvas.drawPath(previewWord, ink);
      canvas.drawPath(_underline, _pen());
      return;
    }
    final pass = _span(t, 0.15, 0.5);
    final from = const Offset(_x, -8), to = Offset(_x, -8 + 44 * pass);
    canvas.drawPath(_underline, _pen());
    if (type == EraserType.stroke) {
      // gone as soon as the eraser touches it
      final gone = _span(to.dy, 16, 22);
      if (gone < 1) {
        canvas.drawPath(previewWord, _pen(_ink.withValues(alpha: 1 - gone)));
      }
    } else {
      canvas.saveLayer(const Rect.fromLTWH(-10, -10, 120, 52), Paint());
      canvas.drawPath(previewWord, _pen());
      if (pass > 0) {
        canvas.drawLine(
          from,
          to,
          Paint()
            ..blendMode = BlendMode.clear
            ..strokeWidth = _radius * 2
            ..strokeCap = StrokeCap.round,
        );
      }
      canvas.restore();
    }
    if (t < 0.1 || t > 0.62) return;
    // the eraser's ring, as on the page
    canvas.drawCircle(to, _radius, Paint()..color = const Color(0x55FFFFFF));
    canvas.drawCircle(to, _radius, _pen(Colors.white, 2));
    canvas.drawCircle(to, _radius + 1.8, _pen(const Color(0xFF202124), 1.4));
  }
}

// ---- 7. scribble to erase ----

/// A word, a zig-zag over it, and both are gone.
class ScribblePreview extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => _Looping(
    still: 0.45,
    painter: (clock, _) => _ScribblePainter(clock),
  );
}

class _ScribblePainter extends _Painter {
  _ScribblePainter(super.clock);

  static final _zigzag = Path()
    ..addPolygon([
      for (var i = 0; i <= 14; i++) Offset(8 + i * 6.0, i.isEven ? 10 : 38),
    ], false);

  @override
  void paint(Canvas canvas, Size size) {
    center(canvas, size, 100, 52);
    final back = _span(t, 0.85, 1);
    if (back > 0) {
      canvas.drawPath(previewWord, _pen(_ink.withValues(alpha: back)));
      return;
    }
    final gone = _span(t, 0.55, 0.68);
    if (gone == 1) return;
    canvas.drawPath(previewWord, _pen(_ink.withValues(alpha: 1 - gone)));
    final drawn = _span(t, 0.12, 0.5);
    if (drawn > 0) {
      canvas.drawPath(
        _written(_zigzag, drawn),
        _pen(BnColors.inkBlue.withValues(alpha: 1 - gone)),
      );
    }
  }
}

// ---- 8. laser: dot or line ----

/// The laser along a curve: a dot that follows the pen, or a line that
/// fades after it lifts, in the laser's colour.
class LaserPreview extends StatelessWidget {
  const new({
    super.key,
    required this.dot,
    required this.color,
    required this.glow,
  });

  final bool dot, glow;
  final Color color;

  @override
  Widget build(BuildContext context) => _Looping(
    still: 0.55,
    painter: (clock, _) => _LaserPainter(clock, dot, color, glow),
  );
}

class _LaserPainter extends _Painter {
  _LaserPainter(super.clock, this.dot, this.color, this.glow);

  final bool dot, glow;
  final Color color;

  static final _path = parseSvgPathData(
    'M16 44c20-30 40-30 56-8s36 22 54 0 36-26 58-10',
  );

  @override
  void paint(Canvas canvas, Size size) {
    center(canvas, size, 200, 64);
    final drawn = _span(t, 0.05, 0.55);
    if (drawn == 0) return;
    if (dot) {
      // the dot goes with the pen
      if (t > 0.6) return;
      const radius = 5.0;
      final tip = _tip(_path, drawn);
      canvas.drawCircle(
        tip,
        radius,
        Paint()
          ..color = color
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, radius * 0.6),
      );
      canvas.drawCircle(
        tip,
        radius * 0.45,
        Paint()..color = const Color(0xDDffffff),
      );
      return;
    }
    final opacity = 1 - _span(t, 0.65, 0.85);
    if (opacity == 0) return;
    final path = _written(_path, drawn);
    const line = 5.0;
    final paint = _pen(color, line);
    for (final (width, alpha) in [
      if (glow) ...const [(4.2, 0.05), (3.0, 0.08), (2.1, 0.13)],
      (1.45, 0.22),
    ]) {
      canvas.drawPath(
        path,
        paint
          ..color = color.withValues(alpha: alpha * opacity)
          ..strokeWidth = line * width,
      );
    }
    canvas.drawPath(
      path,
      paint
        ..color = color.withValues(alpha: opacity)
        ..strokeWidth = line * 0.75,
    );
    canvas.drawPath(
      path,
      paint
        ..color = Colors.white.withValues(alpha: 0.85 * opacity)
        ..strokeWidth = line * 0.28,
    );
  }
}

// ---- 9. scrolling direction ----

/// Pages going by top to bottom, or side by side.
class ScrollPreview extends StatelessWidget {
  const new({super.key, required this.horizontal});

  final bool horizontal;

  @override
  Widget build(BuildContext context) => _Looping(
    still: 0.5,
    paper: false,
    painter: (clock, context) => _ScrollPainter(
      clock,
      horizontal,
      BadNotesColors.of(context).desk,
      BadNotesColors.of(context).hairline,
    ),
  );
}

class _ScrollPainter extends _Painter {
  _ScrollPainter(super.clock, this.horizontal, this.desk, this.hairline);

  final bool horizontal;
  final Color desk, hairline;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(10),
    );
    canvas.clipRRect(frame);
    canvas.drawRRect(frame, Paint()..color = desk);
    final page = horizontal ? const Size(48, 64) : const Size(58, 76);
    const gap = 8.0;
    final step = (horizontal ? page.width : page.height) + gap;
    final moved = Curves.easeInOut.transform(_span(t, 0.2, 0.8)) * step;
    final edge = _pen(hairline, 1);
    final lines = _pen(hairline, 1);
    for (var i = -1; i < 4; i++) {
      final along = i * step - moved;
      final topLeft = horizontal
          ? Offset(16 + along, (size.height - page.height) / 2)
          : Offset((size.width - page.width) / 2, 6 + along);
      final rect = topLeft & page;
      final paper = RRect.fromRectAndRadius(rect, const Radius.circular(2));
      canvas.drawRRect(paper, Paint()..color = _paper);
      canvas.drawRRect(paper, edge);
      for (var y = rect.top + 26; y < rect.bottom - 4; y += 8) {
        canvas.drawLine(
          Offset(rect.left + 5, y),
          Offset(rect.right - 5, y),
          lines,
        );
      }
      canvas.save();
      canvas.translate(rect.left + 4, rect.top + 4);
      canvas.scale(0.4);
      canvas.drawPath(previewWord, _pen(_ink, 3.5));
      canvas.restore();
    }
  }
}

// ---- 10. draw & hold: the snap ----

/// A rough circle (or rectangle) drawn by the pen; the pen holds still, a
/// ring pulses under it, and the line snaps to the neat shape.
class SnapPreview extends StatelessWidget {
  const new circle({super.key}) : _circle = true;
  const new rectangle({super.key}) : _circle = false;

  final bool _circle;

  @override
  Widget build(BuildContext context) => _Looping(
    still: 0.8,
    painter: (clock, context) =>
        _SnapPainter(clock, _circle, Theme.of(context).colorScheme.primary),
  );
}

class _SnapPainter extends _Painter {
  _SnapPainter(Animation<double> clock, this.circle, this.primary)
    : super(clock, [stows.shapeFill]);

  final bool circle;
  final Color primary;

  static final _roughCircle = parseSvgPathData(
    'M37 6c18-2 31 9 30 24s-17 26-33 24S5 42 7 27 20 7 39 8',
  );
  static final _roughRect = parseSvgPathData(
    'M8 10c20-3 44-2 64 1 2 14 1 30-1 44-20 2-42 1-62-1-2-14-1-30-1-44',
  );

  @override
  void paint(Canvas canvas, Size size) {
    center(canvas, size, circle ? 74 : 80, circle ? 60 : 64);
    final ink = circle ? _ink : BnColors.inkBlue;
    final rough = circle ? _roughCircle : _roughRect;
    final drawn = _span(t, 0.05, 0.42);
    final snapped = _span(t, 0.62, 0.7);
    final fade = 1 - _span(t, 0.9, 1);
    if (drawn == 0 || fade == 0) return;
    if (snapped < 1) {
      canvas.drawPath(
        _written(rough, drawn),
        _pen(ink.withValues(alpha: 1 - snapped)),
      );
    }
    if (t < 0.62) {
      // the pen, then held still: a ring pulses out from it
      final tip = _tip(rough, drawn);
      canvas.drawCircle(tip, 3, Paint()..color = primary);
      final pulse = _span(t, 0.44, 0.6);
      if (pulse > 0 && pulse < 1) {
        canvas.drawCircle(
          tip,
          4 + 10 * pulse,
          _pen(primary.withValues(alpha: 1 - pulse), 2),
        );
      }
    }
    if (snapped == 0) return;
    final alpha = snapped * fade;
    final stroke = _pen(ink.withValues(alpha: alpha));
    final fill = stows.shapeFill.value
        ? (Paint()..color = ink.withValues(alpha: 0.15 * alpha))
        : null;
    if (circle) {
      const middle = Offset(37, 30);
      if (fill != null) canvas.drawCircle(middle, 25, fill);
      canvas.drawCircle(middle, 25, stroke);
    } else {
      final shape = RRect.fromRectAndRadius(
        const Rect.fromLTWH(8, 10, 64, 44),
        const Radius.circular(4),
      );
      if (fill != null) canvas.drawRRect(shape, fill);
      canvas.drawRRect(shape, stroke);
    }
  }
}

// ---- 11. circle to lasso ----

/// A loop drawn round a word with the pen, which then picks the word as the
/// lasso does.
class CircleLassoPreview extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => _Looping(
    still: 0.75,
    painter: (clock, context) =>
        _CircleLassoPainter(clock, Theme.of(context).colorScheme.primary),
  );
}

class _CircleLassoPainter extends _Painter {
  _CircleLassoPainter(super.clock, this.primary);

  final Color primary;

  static final _loop = parseSvgPathData(
    'M80 9c36 0 64 13 64 31s-28 31-64 31S16 58 16 40 46 9 86 11',
  );

  @override
  void paint(Canvas canvas, Size size) {
    center(canvas, size, 160, 80);
    final picked = t > 0.5 && t < 0.92;
    const scale = 0.8;
    canvas.save();
    canvas.translate(40, 22);
    canvas.scale(scale);
    if (picked) {
      // picked: a soft blue edge behind it, as on the page
      canvas.drawPath(
        previewWord,
        _pen(primary.withValues(alpha: 0.22), 2.4 / scale + 7 / scale),
      );
    }
    canvas.drawPath(previewWord, _pen(_ink, 2.4 / scale));
    canvas.restore();
    if (picked) {
      _marchingAnts(canvas, _loop, primary, t);
      return;
    }
    final drawn = _span(t, 0.08, 0.45);
    if (drawn > 0 && t < 0.92) {
      canvas.drawPath(_written(_loop, drawn), _pen());
    }
  }
}

// ---- 12. tape ----

/// A line of words covered by a strip of tape in the tape's colour and
/// pattern; a tap peeks under it, and it covers again.
class TapePreview extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => _Looping(
    still: 0.4,
    painter: (clock, context) =>
        _TapePainter(clock, Theme.of(context).colorScheme.primary),
  );
}

class _TapePainter extends _Painter {
  _TapePainter(Animation<double> clock, this.primary)
    : super(clock, [stows.tapeColor, stows.tapePattern, stows.tapeDoodle]);

  final Color primary;

  static const _width = 24.0, _y = 30.0, _from = 10.0, _to = 130.0;
  static final _line = Path()
    ..moveTo(_from, _y)
    ..lineTo(_to, _y);
  static const _tapAt = Offset(70, _y);

  @override
  void paint(Canvas canvas, Size size) {
    center(canvas, size, 140, 60);
    canvas.save();
    canvas.translate(20, 8);
    canvas.drawPath(previewWord, _pen());
    canvas.restore();

    final laid = _span(t, 0.08, 0.3);
    final gone = _span(t, 0.92, 1);
    if (laid == 0 || gone == 1) return;
    final peeked = t > 0.52 && t < 0.8;
    final rect = Rect.fromLTRB(
      _from,
      _y - _width / 2,
      _from + (_to - _from) * laid,
      _y + _width / 2,
    );
    if (gone > 0) {
      canvas.saveLayer(
        null,
        Paint()..color = Color.fromRGBO(0, 0, 0, 1 - gone),
      );
    }
    // drawn as the page draws tape (see _drawTapeStroke)
    final color = Tape.currentTape.color;
    if (peeked) {
      canvas.drawRect(rect, Paint()..color = color.withValues(alpha: 0.2));
    } else {
      // lifted off the page: a soft shadow, then a darker edge all around
      canvas.drawRect(
        rect.shift(const Offset(1.5, 3)).inflate(1),
        Paint()
          ..color = const Color(0x55000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
      canvas.drawRect(
        rect.inflate(1.5),
        Paint()..color = Color.lerp(color, Colors.black, 0.4)!,
      );
      canvas.drawRect(rect, Paint()..color = color);
      // stamped along the whole strip, so they don't slide as it's laid
      canvas.save();
      canvas.clipRect(rect);
      canvas.drawPath(
        Tape.pattern.stamps(_line, _width, doodle: Tape.doodle),
        Paint()
          ..color = color.computeLuminance() > 0.55
              ? const Color(0x33000000)
              : const Color(0x88FFFFFF),
      );
      canvas.restore();
    }
    if (gone > 0) canvas.restore();

    // the tap that peeks
    final tap = _span(t, 0.46, 0.6);
    if (tap > 0 && tap < 1) {
      canvas.drawCircle(
        _tapAt,
        6,
        Paint()..color = primary.withValues(alpha: 0.35 * (1 - tap)),
      );
      canvas.drawCircle(
        _tapAt,
        6 + 12 * tap,
        _pen(primary.withValues(alpha: 1 - tap), 2),
      );
    }
  }
}

// ---- 13. ink in dark mode ----

/// The app turning dark and back. With the option on, the page turns dark
/// too and its ink light, by the same inversion the page uses; off, the
/// page and its ink stay as they are.
class DarkInkPreview extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => _Looping(
    still: 0.6,
    painter: (clock, _) => _DarkInkPainter(clock),
  );
}

class _DarkInkPainter extends _Painter {
  _DarkInkPainter(Animation<double> clock)
    : super(clock, [stows.editorAutoInvert]);

  @override
  void paint(Canvas canvas, Size size) {
    // light for 1.2 s, 250 ms across to dark, dark for 1.2 s, and back:
    // a wipe, so nothing passes through grey on the way
    final across = Curves.easeInOut.transform(_span(t, 0.375, 0.453));
    final back = Curves.easeInOut.transform(_span(t, 0.828, 0.906));
    final frame = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(10),
    );
    canvas.clipRRect(frame);
    _scene(canvas, size, dark: false);
    // the dark part sweeps in from the left, and out the same way
    final from = size.width * back, to = size.width * across;
    if (to <= from) return;
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(from, 0, to, size.height));
    _scene(canvas, size, dark: true);
    canvas.restore();
  }

  void _scene(Canvas canvas, Size size, {required bool dark}) {
    final invert = dark && stows.editorAutoInvert.value;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = dark ? BnColors.deskDark : BnColors.desk,
    );
    final sheet = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: 150,
      height: size.height - 20,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(sheet, const Radius.circular(3)),
      Paint()..color = _paper.withInversion(invert),
    );
    canvas.save();
    canvas.translate(sheet.left + 14, sheet.top + 8);
    canvas.drawPath(previewWord, _pen(_ink.withInversion(invert)));
    canvas.drawPath(
      Path()
        ..moveTo(96, 34)
        ..cubicTo(104, 22, 112, 22, 116, 30),
      _pen(BnColors.inkBlue.withInversion(invert)),
    );
    canvas.drawPath(_underline, _pen(BnColors.inkRed.withInversion(invert)));
    canvas.restore();
  }
}

// ---- 14. a shape's stroke ----

/// [path] as the page draws a shape (see [CanvasPainter.paintShape]): its
/// fill when [closed], its line in [style] and its arrowheads.
void paintStyledPath(
  Canvas canvas,
  Path path,
  ShapeStyle style,
  Color color,
  double width, {
  bool closed = false,
}) {
  if (style.fill case final fill? when closed) {
    canvas.drawPath(path, Paint()..color = fill);
  }
  final line = Paint()
    ..style = PaintingStyle.stroke
    ..color = color
    ..strokeWidth = width
    ..strokeCap = style.rounded ? StrokeCap.round : StrokeCap.butt
    ..strokeJoin = style.rounded ? StrokeJoin.round : StrokeJoin.miter;
  switch (style.line) {
    case ShapeLine.none:
      return;
    case ShapeLine.solid:
      canvas.drawPath(path, line);
    case ShapeLine.dashed:
      canvas.drawPath(
        dashPath(
          path,
          dashArray: CircularIntervalList([width * 4, width * 2.5]),
        ),
        line,
      );
    case ShapeLine.dotted:
      canvas.drawPath(
        dashPath(path, dashArray: CircularIntervalList([0.01, width * 2])),
        line..strokeCap = StrokeCap.round,
      );
  }
  if (closed) return;
  final metrics = path.computeMetrics().toList();
  if (metrics.isEmpty) return;
  final reach = math.max(width * 3.5, 10.0);
  void head(ShapeArrow arrow, Offset? tip, Offset? from) {
    if (arrow == ShapeArrow.none) return;
    if (tip == null || from == null || tip == from) return;
    final unit = (tip - from) / (tip - from).distance;
    final normal = Offset(-unit.dy, unit.dx);
    final back = tip - unit * reach;
    final left = back + normal * reach * 0.55;
    final right = back - normal * reach * 0.55;
    final mark = Path()
      ..moveTo(left.dx, left.dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(right.dx, right.dy);
    if (arrow == ShapeArrow.filled) {
      canvas.drawPath(mark..close(), Paint()..color = color);
    } else {
      canvas.drawPath(
        mark,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  final first = metrics.first, last = metrics.last;
  head(
    style.arrowStart,
    first.getTangentForOffset(0)?.position,
    first.getTangentForOffset(math.min(reach, first.length))?.position,
  );
  head(
    style.arrowEnd,
    last.getTangentForOffset(last.length)?.position,
    last.getTangentForOffset(math.max(last.length - reach, 0))?.position,
  );
}

/// A shape and a line in [style], [color] and [width], as they'll be drawn:
/// the fill and corners on the shape, the arrowheads on the line.
class ShapeStylePreview extends StatelessWidget {
  const new({
    super.key,
    required this.style,
    required this.color,
    required this.width,
  });

  final ShapeStyle style;
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    height: previewHeight,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: _paper,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: BadNotesColors.of(context).hairline),
    ),
    child: CustomPaint(painter: _ShapeStylePainter(style, color, width)),
  );
}

class _ShapeStylePainter extends CustomPainter {
  _ShapeStylePainter(this.style, this.color, this.width);

  final ShapeStyle style;
  final Color color;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    // thick enough to see, thin enough to fit
    final w = width.clamp(1.5, 8.0);
    final middle = size.center(Offset.zero);
    final box = Rect.fromCenter(
      center: middle - const Offset(60, 0),
      width: 84,
      height: 56,
    );
    paintStyledPath(
      canvas,
      Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            box,
            Radius.circular(style.rounded ? w * 2 : 0),
          ),
        ),
      style,
      color,
      w,
      closed: true,
    );
    paintStyledPath(
      canvas,
      Path()
        ..moveTo(middle.dx + 14, middle.dy + 20)
        ..quadraticBezierTo(
          middle.dx + 50,
          middle.dy - 34,
          middle.dx + 104,
          middle.dy - 6,
        ),
      style,
      color,
      w,
    );
  }

  @override
  bool shouldRepaint(_ShapeStylePainter old) =>
      old.style != style || old.color != color || old.width != width;
}
