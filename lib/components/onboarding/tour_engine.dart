import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:badnotes/components/canvas/_canvas_background_painter.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/theming/badnotes_tokens.dart';
import 'package:badnotes/components/ui/bn_docks.dart';
import 'package:badnotes/components/ui/bn_icons.dart';
import 'package:badnotes/data/extensions/color_extensions.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:sbn/canvas_background_pattern.dart';

/// The size every scene is drawn at; the stage scales it to fit.
const stageSize = Size(640, 400);

/// 0 before [a], 1 after [b], eased in between.
double span(
  double t,
  double a,
  double b, [
  Curve curve = Curves.easeInOutCubic,
]) => curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

/// What a line is drawn with. Each has its own look, as in the editor.
enum Pen {
  /// Variable width from the nib's angle, tapered ends: headings, outlines.
  fountain,

  /// Even and firm: labels, small strokes.
  ballpoint,

  /// Thin and even: leader lines, annotations.
  fineliner,

  /// Swells and tapers: big organic strokes and fills.
  brush,

  /// Translucent, chisel tip, multiplied over the ink.
  highlighter,

  /// The shape pen's clean, even line.
  shape,
}

/// [c] as a dark page shows it (the editor's inversion).
Color pageInk(Color c, bool dark) => dark ? c.withInversion() : c;

/// Whether pages show dark, as the editor shows them in dark mode.
bool pagesDark(BuildContext context) =>
    Theme.brightnessOf(context) == Brightness.dark &&
    stows.editorAutoInvert.value;

/// The ink colour for text and labels.
const inkDark = Color(0xFF1F2430);

/// A hand-authored SVG path, moved to [at] and scaled by [scale].
Path svgPath(String d, {Offset at = Offset.zero, double scale = 1}) {
  final path = parseSvgPathData(d);
  if (at == Offset.zero && scale == 1) return path;
  return path.transform(
    Float64List.fromList([
      scale, 0, 0, 0, //
      0, scale, 0, 0,
      0, 0, 1, 0,
      at.dx, at.dy, 0, 1,
    ]),
  );
}

/// An arrow from [a] to [b] as path data: the shaft, then the head.
String arrowSvg(Offset a, Offset b, {double head = 11}) {
  final d = (b - a) / (b - a).distance;
  final n = Offset(-d.dy, d.dx);
  final h1 = b - d * head + n * head * 0.62;
  final h2 = b - d * head - n * head * 0.62;
  String p(Offset o) => '${o.dx.toStringAsFixed(1)} ${o.dy.toStringAsFixed(1)}';
  return 'M${p(a)} L${p(b)} M${p(h1)} L${p(b)} L${p(h2)}';
}

/// Something written on the page over part of the loop.
abstract class Drawn {
  new(this.pen, this.color);

  final Pen pen;
  final Color color;

  /// When it's written, as fractions of the loop. Equal: always there.
  double a = 0, b = 0;

  /// How long it takes to write, in stage units at the scene's pace.
  double get cost;

  /// Fills under lines, lines, then highlighters over them.
  int get layer => pen == Pen.highlighter ? 2 : 1;

  /// How much is written at [t], eased per stroke.
  double progress(double t) {
    if (t >= b) return 1;
    if (t <= a) return 0;
    return Curves.easeInOutSine.transform((t - a) / (b - a));
  }

  void paint(Canvas canvas, double p, double fade, bool dark);

  /// Where the pen is when [p] is written.
  Offset tipAt(double p);
}

/// Lays [items] one after the other between [from] and [to] at an even
/// pace: each gets time for its [Drawn.cost], plus [gap] units between.
List<T> lay<T extends Drawn>(
  double from,
  double to,
  List<T> items, {
  double gap = 24,
}) {
  final total = items.fold<double>(0, (s, d) => s + d.cost + gap) - gap;
  var at = from;
  for (final d in items) {
    final len = (to - from) * d.cost / total;
    d.a = at;
    d.b = at + len;
    at += len + (to - from) * gap / total;
  }
  return items;
}

class _Contour {
  new(this.metric, this.points, this.pressure, this.from);

  final ui.PathMetric metric;
  final List<Offset> points;
  final List<double> pressure;

  /// Where along the whole line this part starts.
  final double from;

  double get length => metric.length;
}

/// A line along a hand-authored path, written on at an even speed with
/// [pen]'s look. Points are resampled every 1.2 units so the outline is
/// perfectly smooth.
class InkLine extends Drawn {
  new(
    String svg, {
    Pen pen = Pen.fountain,
    required Color color,
    this.width = 3,
    Offset at = Offset.zero,
    double scale = 1,
  }) : path = svgPath(svg, at: at, scale: scale),
       super(pen, color);

  new path(
    this.path, {
    Pen pen = Pen.fountain,
    required Color color,
    this.width = 3,
  }) : super(pen, color);

  final Path path;
  final double width;

  late final List<_Contour> _contours = () {
    final out = <_Contour>[];
    var from = 0.0;
    for (final m in path.computeMetrics()) {
      final n = max(2, (m.length / 1.2).ceil());
      final pts = <Offset>[];
      final angles = <double>[];
      for (var i = 0; i <= n; i++) {
        final tan = m.getTangentForOffset(m.length * i / n)!;
        pts.add(tan.position);
        angles.add(atan2(tan.vector.dy, tan.vector.dx));
      }
      out.add(_Contour(m, pts, _pressures(pts, angles, m.length), from));
      from += m.length;
    }
    return out;
  }();

  List<double> _pressures(List<Offset> pts, List<double> angles, double len) {
    final n = pts.length;
    switch (pen) {
      case Pen.fountain:
        // a nib held at 45°: thin going up-right, full going down-right
        final raw = [
          for (final a in angles) 0.28 + 0.72 * sin(a - -pi / 4).abs(),
        ];
        return [
          for (var i = 0; i < n; i++)
            () {
              var s = 0.0, k = 0;
              for (var j = max(0, i - 4); j <= min(n - 1, i + 4); j++) {
                s += raw[j];
                k++;
              }
              return s / k;
            }(),
        ];
      case Pen.brush:
        return [
          for (var i = 0; i < n; i++)
            0.3 +
                0.7 *
                    min(
                      1.0,
                      min(i / (n * 0.18 + 1), (n - 1 - i) / (n * 0.22 + 1)),
                    ),
        ];
      default:
        return List.filled(n, 0.5);
    }
  }

  @override
  double get cost => _contours.fold(0.0, (s, c) => s + c.length);

  bool get _stroked =>
      pen == Pen.fineliner || pen == Pen.shape || pen == Pen.highlighter;

  StrokeOptions _options(bool complete) => switch (pen) {
    Pen.fountain => StrokeOptions(
      size: width * 1.3,
      thinning: 0.7,
      smoothing: 0.62,
      streamline: 0.12,
      simulatePressure: false,
      start: StrokeEndOptions.start(customTaper: width * 3),
      end: StrokeEndOptions.end(customTaper: width * 4),
      isComplete: complete,
    ),
    Pen.brush => StrokeOptions(
      size: width * 1.2,
      thinning: 0.55,
      smoothing: 0.7,
      streamline: 0.1,
      simulatePressure: false,
      start: StrokeEndOptions.start(customTaper: width * 5),
      end: StrokeEndOptions.end(customTaper: width * 6),
      isComplete: complete,
    ),
    _ => StrokeOptions(
      size: width,
      thinning: 0.06,
      smoothing: 0.5,
      streamline: 0.1,
      simulatePressure: false,
      isComplete: complete,
    ),
  };

  Path _outline(_Contour c, int count, bool complete) {
    final pts = [
      for (var i = 0; i < count; i++)
        PointVector(c.points[i].dx, c.points[i].dy, c.pressure[i]),
    ];
    return Path()..addPolygon(getStroke(pts, options: _options(complete)), true);
  }

  late final List<Path> _full = [
    for (final c in _contours)
      if (_stroked)
        c.metric.extractPath(0, c.length)
      else
        _outline(c, c.points.length, true),
  ];

  Paint _paint(double fade, bool dark) {
    final paint = Paint()..isAntiAlias = true;
    final c = pen == Pen.highlighter ? color : pageInk(color, dark);
    if (pen == Pen.highlighter) {
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.square
        ..strokeJoin = StrokeJoin.bevel
        ..color = c.withValues(alpha: (dark ? 0.32 : 0.45) * fade)
        ..blendMode = dark ? BlendMode.screen : BlendMode.multiply;
    } else if (_stroked) {
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = c.withValues(alpha: c.a * fade);
    } else {
      paint.color = c.withValues(alpha: c.a * fade);
    }
    return paint;
  }

  @override
  void paint(Canvas canvas, double p, double fade, bool dark) {
    if (p <= 0 || fade <= 0) return;
    final paint = _paint(fade, dark);
    final upTo = p * cost;
    for (var i = 0; i < _contours.length; i++) {
      final c = _contours[i];
      if (upTo <= c.from) break;
      final left = upTo - c.from;
      if (left >= c.length) {
        canvas.drawPath(_full[i], paint);
      } else if (_stroked) {
        canvas.drawPath(c.metric.extractPath(0, left), paint);
      } else {
        final n = (left / c.length * (c.points.length - 1)).round() + 1;
        if (n >= 2) canvas.drawPath(_outline(c, n, false), paint);
      }
    }
  }

  @override
  Offset tipAt(double p) {
    final upTo = p * cost;
    for (final c in _contours) {
      if (upTo <= c.from + c.length) {
        return c.metric
            .getTangentForOffset((upTo - c.from).clamp(0, c.length))!
            .position;
      }
    }
    return _contours.last.points.last;
  }

  /// Evenly spaced points along the line (its first part), [step] apart.
  List<Offset> points() => _contours.first.points;
}

/// A closed region filled by a brush sweeping across it, left to right.
class InkFill extends Drawn {
  new(
    String svg, {
    required Color color,
    Offset at = Offset.zero,
    double scale = 1,
  }) : path = svgPath(svg, at: at, scale: scale),
       super(Pen.brush, color);

  final Path path;
  late final Rect bounds = path.getBounds();

  @override
  int get layer => 0;

  @override
  double get cost => bounds.width * 0.7 + 20;

  @override
  void paint(Canvas canvas, double p, double fade, bool dark) {
    if (p <= 0 || fade <= 0) return;
    final c = pageInk(color, dark);
    final paint = Paint()..color = c.withValues(alpha: c.a * fade);
    if (p >= 1) {
      canvas.drawPath(path, paint);
      return;
    }
    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(
        bounds.left - 1,
        bounds.top - 1,
        bounds.left + bounds.width * p,
        bounds.bottom + 1,
      ),
    );
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  Offset tipAt(double p) => Offset(
    bounds.left + bounds.width * p,
    bounds.top + bounds.height * (0.5 + 0.34 * sin(p * pi * 7)),
  );
}

/// Handwritten words in a handwriting font, revealed left to right behind
/// a soft edge as if written.
class InkText extends Drawn {
  new(
    this.text, {
    required this.at,
    Color color = inkDark,
    this.size = 18,
    this.font = 'PatrickHand',
    this.weight = FontWeight.w400,
    this.angle = 0,
    Pen pen = Pen.ballpoint,
  }) : super(pen, color);

  final String text;
  final Offset at;
  final double size;
  final String font;
  final FontWeight weight;
  final double angle;

  TextStyle _style(Paint? foreground, Color c) => TextStyle(
    fontFamily: font,
    fontSize: size,
    fontWeight: weight,
    height: 1.1,
    color: foreground == null ? c : null,
    foreground: foreground,
  );

  final _solid = <Object, TextPainter>{};

  TextPainter _layout(TextStyle style) => TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();

  late final TextPainter _metrics = _layout(_style(null, color));

  Size get box => _metrics.size;

  /// Where [part] of the text is on the page.
  Rect rectOf(String part) {
    final i = text.indexOf(part);
    if (i < 0) return Rect.zero;
    final boxes = _metrics.getBoxesForSelection(
      TextSelection(baseOffset: i, extentOffset: i + part.length),
    );
    var r = boxes.first.toRect();
    for (final b in boxes.skip(1)) {
      r = r.expandToInclude(b.toRect());
    }
    return r.shift(at);
  }

  @override
  double get cost => box.width * 1.25 + 10;

  @override
  void paint(Canvas canvas, double p, double fade, bool dark) {
    if (p <= 0 || fade <= 0) return;
    final c = pageInk(color, dark);
    canvas.save();
    canvas.translate(at.dx, at.dy);
    if (angle != 0) canvas.rotate(angle);
    if (p >= 1 && fade >= 1) {
      _solid
          .putIfAbsent(dark, () => _layout(_style(null, c)))
          .paint(canvas, Offset.zero);
    } else {
      // a soft edge moving across: ink up to it, nothing past it
      final w = box.width;
      const feather = 16.0;
      final edge = p * (w + feather);
      final shown = c.withValues(alpha: c.a * fade);
      final none = shown.withValues(alpha: 0);
      final s1 = ((edge - feather) / w).clamp(0.0, 1.0);
      final s2 = (edge / w).clamp(s1, 1.0);
      final shader = ui.Gradient.linear(
        Offset.zero,
        Offset(w, 0),
        [shown, shown, none, none],
        [0, s1, s2, 1],
      );
      _layout(_style(Paint()..shader = shader, c)).paint(canvas, Offset.zero);
    }
    canvas.restore();
  }

  @override
  Offset tipAt(double p) {
    final local = Offset(box.width * p, box.height * 0.62);
    if (angle == 0) return at + local;
    return at +
        Offset(
          local.dx * cos(angle) - local.dy * sin(angle),
          local.dx * sin(angle) + local.dy * cos(angle),
        );
  }
}

/// Camera moves: (time, centre, zoom) keys, eased from one to the next.
class Cam {
  const new(this.keys);

  final List<(double, Offset, double)> keys;

  static const still = Cam([(0, Offset(320, 200), 1)]);

  (Offset, double) at(double t) {
    if (t <= keys.first.$1 || keys.length == 1) return (keys.first.$2, keys.first.$3);
    for (var i = 0; i < keys.length - 1; i++) {
      final (t0, c0, z0) = keys[i];
      final (t1, c1, z1) = keys[i + 1];
      if (t <= t1) {
        final k = span(t, t0, t1);
        return (Offset.lerp(c0, c1, k)!, z0 + (z1 - z0) * k);
      }
    }
    return (keys.last.$2, keys.last.$3);
  }

  /// The camera's transform at [t]: zoomed about its centre, kept on the
  /// page.
  Matrix4 matrix(double t) {
    final (c, z) = at(t);
    final hw = stageSize.width / 2 / z, hh = stageSize.height / 2 / z;
    final cx = z <= 1 ? c.dx : c.dx.clamp(hw, stageSize.width - hw);
    final cy = z <= 1 ? c.dy : c.dy.clamp(hh, stageSize.height - hh);
    return Matrix4.identity()
      ..translateByDouble(stageSize.width / 2, stageSize.height / 2, 0, 1)
      ..scaleByDouble(z, z, 1, 1)
      ..translateByDouble(-cx, -cy, 0, 1);
  }
}

final _papers = <(bool, Color), ui.Picture>{};

/// The editor's dotted paper for the whole stage, recorded once.
ui.Picture paper(bool dark, Color dots) => _papers.putIfAbsent((dark, dots), () {
  final recorder = ui.PictureRecorder();
  CanvasBackgroundPainter(
    invert: dark,
    backgroundColor: Colors.white,
    backgroundPattern: CanvasBackgroundPattern.dots,
    lineHeight: 24,
    lineThickness: 1,
    primaryColor: dots,
    secondaryColor: dots,
  ).paint(Canvas(recorder), stageSize);
  return recorder.endRecording();
});

/// The ink in use at [t]: the line being written, or the next one about
/// to be, so the toolbar switches just before the pen moves.
Drawn? activeInk(List<Drawn> inks, double t) {
  Drawn? best;
  for (final d in inks) {
    if (d.a == d.b) continue;
    if (d.a - 0.03 <= t && (best == null || d.a >= best.a)) best = d;
  }
  return best;
}

/// Where the pen is at [t] and its colour: on the line being written, or
/// gliding between two lines.
(Offset, Color)? penAt(List<Drawn> inks, double t) {
  Drawn? prev, next;
  for (final d in inks) {
    if (d.a == d.b) continue;
    if (t >= d.a && t < d.b) return (d.tipAt(d.progress(t)), d.color);
    if (d.b <= t && (prev == null || d.b > prev.b)) prev = d;
    if (d.a > t && (next == null || d.a < next.a)) next = d;
  }
  if (prev != null && next != null && next.a - prev.b < 0.06) {
    final k = Curves.easeInOut.transform((t - prev.b) / (next.a - prev.b));
    return (Offset.lerp(prev.tipAt(1), next.tipAt(0), k)!, next.color);
  }
  return null;
}

/// A stylus resting on [tip], its nib in [ink].
void drawStylus(Canvas canvas, Offset tip, Color ink, {double opacity = 1}) {
  if (opacity <= 0) return;
  canvas.save();
  canvas.translate(tip.dx, tip.dy);
  // shadow first, then the pen, pointing up and to the right
  for (final shadow in [true, false]) {
    canvas.save();
    if (shadow) canvas.translate(7, 9);
    canvas.rotate(-pi / 3.4);
    final body = Paint()
      ..color = shadow
          ? Color.fromRGBO(0, 0, 0, 0.13 * opacity)
          : Color.fromRGBO(42, 43, 50, opacity);
    final nib = Path()
      ..moveTo(0, 0)
      ..lineTo(11, -3.6)
      ..lineTo(11, 3.6)
      ..close();
    canvas.drawPath(
      nib,
      shadow ? body : (Paint()..color = const Color(0xFFD9D9DE).withValues(alpha: opacity)),
    );
    canvas.drawRRect(
      RRect.fromLTRBR(11, -4.4, 58, 4.4, const Radius.circular(3)),
      body,
    );
    if (!shadow) {
      canvas.drawCircle(Offset.zero, 1.8, Paint()..color = ink.withValues(alpha: opacity));
      canvas.drawRect(
        const Rect.fromLTWH(13, -4.4, 4, 8.8),
        Paint()..color = ink.withValues(alpha: opacity),
      );
      canvas.drawLine(
        const Offset(20, -2.2),
        const Offset(54, -2.2),
        Paint()
          ..color = Color.fromRGBO(255, 255, 255, 0.22 * opacity)
          ..strokeWidth = 1.2,
      );
    }
    canvas.restore();
  }
  canvas.restore();
}

/// A tap: a ring growing and fading at [at], [k] of the way through.
void drawTap(Canvas canvas, Offset at, double k, Color color) {
  if (k <= 0 || k >= 1) return;
  canvas.drawCircle(
    at,
    10 + 18 * k,
    Paint()
      ..color = color.withValues(alpha: 0.5 * (1 - k))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5,
  );
  canvas.drawCircle(
    at,
    11,
    Paint()..color = color.withValues(alpha: 0.18 * (1 - k)),
  );
}

/// Fades the ink in at the start of a loop and out before it restarts.
double loopFade(double t, {double out = 0.93}) =>
    min(span(t, 0, 0.035), 1 - span(t, out, 0.985));

/// Paints a page: the paper, [inks] up to [t] through the camera, then
/// [over] in page units and the stylus on top.
class InkPainter extends CustomPainter {
  new({
    required this.t,
    required this.inks,
    required this.dots,
    this.cam = Cam.still,
    this.dark = false,
    this.fade = 1,
    this.under,
    this.over,
    this.stylus = true,
    this.clip,
    this.drawPaper = true,
  });

  final double t, fade;
  final List<Drawn> inks;
  final Color dots;
  final Cam cam;
  final bool dark, stylus, drawPaper;
  final void Function(Canvas canvas)? under, over;

  /// Paints only inside this (the dark mode wipe).
  final Path? clip;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (clip != null) canvas.clipPath(clip!);
    // the camera only for the page; the stylus is placed after it
    canvas.save();
    final m = cam.matrix(t);
    canvas.transform(m.storage);
    if (drawPaper) canvas.drawPicture(paper(dark, dots));
    under?.call(canvas);
    for (var layer = 0; layer <= 2; layer++) {
      for (final d in inks) {
        if (d.layer != layer) continue;
        d.paint(canvas, d.progress(t), fade, dark);
      }
    }
    over?.call(canvas);
    canvas.restore();
    if (stylus && fade > 0) {
      final pen = penAt(inks, t);
      if (pen != null) {
        final p = MatrixUtils.transformPoint(m, pen.$1);
        drawStylus(canvas, p, pageInk(pen.$2, dark), opacity: fade);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(InkPainter old) => true;
}

/// A scene: what plays on the stage for one page of the tour.
class TourScene {
  const new({
    required this.duration,
    required this.build,
    this.rest = 0.8,
  });

  final Duration duration;

  /// The frame shown while it isn't playing (and with animations off).
  final double rest;
  final Widget Function(BuildContext context, double t) build;
}

/// Plays [scene] over and over while [playing], on a layer of its own.
class TourStage extends StatefulWidget {
  const new({super.key, required this.scene, required this.playing});

  final TourScene scene;
  final bool playing;

  @override
  State<TourStage> createState() => _TourStageState();
}

class _TourStageState extends State<TourStage>
    with SingleTickerProviderStateMixin {
  late final _clock = AnimationController(
    vsync: this,
    duration: widget.scene.duration,
  );

  void _sync() {
    final still = MediaQuery.disableAnimationsOf(context);
    if (widget.playing && !still) {
      if (!_clock.isAnimating) _clock.repeat();
    } else {
      _clock
        ..stop()
        ..value = widget.scene.rest;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(TourStage old) {
    super.didUpdateWidget(old);
    if (old.playing != widget.playing) {
      if (widget.playing) _clock.value = 0;
      _sync();
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
        size: stageSize,
        child: AnimatedBuilder(
          animation: _clock,
          builder: (context, _) => widget.scene.build(context, _clock.value),
        ),
      ),
    ),
  );
}

/// The colours a scene's toolbar offers: its inks' first few.
List<Color> paletteOf(List<Drawn> inks, {int count = 6}) {
  final out = <Color>[];
  for (final d in inks) {
    if (d.pen == Pen.highlighter || d is InkFill) continue;
    if (!out.contains(d.color)) out.add(d.color);
    if (out.length == count) break;
  }
  return out;
}

/// A compact copy of the editor's floating toolbar, showing [pen] and
/// [color] picked from [palette].
class MiniToolbar extends StatelessWidget {
  const new({
    super.key,
    required this.pen,
    required this.color,
    required this.palette,
    this.lasso = false,
    this.tape = false,
    this.docked = 0,
  });

  final Pen? pen;
  final Color color;
  final List<Color> palette;
  final bool lasso, tape;

  /// 0 floating, 1 docked in the header (no frame of its own).
  final double docked;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final frame = 1 - docked;
    final mapped = switch (pen) {
      Pen.fineliner => Pen.ballpoint,
      final p => p,
    };
    final hl = pen == Pen.highlighter ? color : const Color(0xFFFFD54F);
    Widget tool(String path, String label, bool on, {Color? ink, bool dashed = false}) =>
        BnToolButton(
          label: label,
          path: path,
          size: 32,
          dashed: dashed,
          selected: on,
          inkColor: ink,
          onTap: null,
        );
    final penOn = !lasso && !tape;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.97 * frame),
        border: Border.all(color: colors.hairline.withValues(alpha: frame)),
        borderRadius: const BorderRadius.all(Radius.circular(BnRadius.dock)),
        boxShadow: BoxShadow.lerpList(BnShadows.floating, const [], docked),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 1,
        children: [
          tool(BnToolIcons.lasso, 'Lasso', lasso, dashed: true),
          tool(
            BnToolIcons.fountain,
            'Fountain pen',
            penOn && mapped == Pen.fountain,
            ink: mapped == Pen.fountain ? color : inkDark,
          ),
          tool(
            BnToolIcons.ballpoint,
            'Ballpoint',
            penOn && mapped == Pen.ballpoint,
            ink: mapped == Pen.ballpoint ? color : inkDark,
          ),
          tool(
            BnToolIcons.brush,
            'Brush',
            penOn && mapped == Pen.brush,
            ink: mapped == Pen.brush ? color : const Color(0xFF3B82F6),
          ),
          tool(BnToolIcons.highlighter, 'Highlighter', penOn && mapped == Pen.highlighter, ink: hl),
          tool(BnToolIcons.drawShapes, 'Draw shapes', penOn && mapped == Pen.shape),
          tool(BnToolIcons.tape, 'Tape', tape),
          Container(
            width: 1,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            color: colors.hairline,
          ),
          for (final c in palette)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.5),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: 20,
                height: 20,
                padding: EdgeInsets.all(c == color && penOn ? 2.5 : 0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: c == color && penOn ? c : colors.hairline.withValues(alpha: 0),
                    width: 2,
                  ),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                ),
              ),
            ),
          const SizedBox(width: 3),
        ],
      ),
    );
  }
}

/// A page scene: paper, ink and camera, with [overlays] (screen-space
/// UI) on top and the toolbar at the top centre.
Widget inkPage(
  BuildContext context, {
  required double t,
  required List<Drawn> inks,
  Cam cam = Cam.still,
  bool? dark,
  double? fade,
  void Function(Canvas canvas)? under,
  void Function(Canvas canvas)? over,
  Widget? toolbar,
  bool autoToolbar = true,
  List<Widget> overlays = const [],
}) {
  final scheme = ColorScheme.of(context);
  Widget? bar = toolbar;
  if (bar == null && autoToolbar) {
    final now = activeInk(inks, t);
    bar = MiniToolbar(
      pen: now?.pen ?? Pen.fountain,
      color: now?.color ?? inkDark,
      palette: paletteOf(inks),
    );
  }
  return Stack(
    fit: StackFit.expand,
    children: [
      CustomPaint(
        painter: InkPainter(
          t: t,
          inks: inks,
          dots: scheme.primary,
          cam: cam,
          dark: dark ?? pagesDark(context),
          fade: fade ?? loopFade(t),
          under: under,
          over: over,
        ),
      ),
      if (bar != null)
        Positioned(
          top: 10,
          left: 0,
          right: 0,
          child: Center(child: bar),
        ),
      ...overlays,
    ],
  );
}

/// A label in dark ink with a thin leader line in [color] ending in a dot
/// on [target]. The line leaves from whichever end of the label faces it.
List<Drawn> label(
  String text,
  Offset at,
  Offset target,
  Color color, {
  double size = 16,
  String font = 'PatrickHand',
  Color ink = inkDark,
}) {
  final words = InkText(text, at: at, color: ink, size: size, font: font);
  final box = words.box;
  final fromLeft = target.dx < at.dx + box.width / 2;
  final start = Offset(
    fromLeft ? at.dx - 5 : at.dx + box.width + 5,
    at.dy + box.height * 0.55,
  );
  String p(Offset o) => '${o.dx.toStringAsFixed(1)} ${o.dy.toStringAsFixed(1)}';
  final leader = InkLine(
    'M${p(start)} L${p(target)} '
    'M${p(target - const Offset(1, 0))} A1 1 0 1 0 ${p(target + const Offset(1, 0))} '
    'A1 1 0 1 0 ${p(target - const Offset(1, 0))}',
    pen: Pen.fineliner,
    color: color,
    width: 1.4,
  );
  return [leader, words];
}

/// A smooth curve through [points] (Catmull-Rom as cubic Béziers), as
/// path data.
String smoothSvg(List<Offset> points, {bool closed = false}) {
  String p(Offset o) => '${o.dx.toStringAsFixed(1)} ${o.dy.toStringAsFixed(1)}';
  final n = points.length;
  Offset at(int i) => closed
      ? points[(i % n + n) % n]
      : points[i.clamp(0, n - 1)];
  final b = StringBuffer('M${p(points.first)}');
  for (var i = 0; i < (closed ? n : n - 1); i++) {
    final p0 = at(i - 1), p1 = at(i), p2 = at(i + 1), p3 = at(i + 2);
    final c1 = p1 + (p2 - p0) / 6;
    final c2 = p2 - (p3 - p1) / 6;
    b.write(' C${p(c1)} ${p(c2)} ${p(p2)}');
  }
  if (closed) b.write(' Z');
  return b.toString();
}

/// A curve y = f(x) from [x0] to [x1] as path data, sampled every
/// [step] and smoothed.
String plotSvg(double Function(double x) f, double x0, double x1, {double step = 8}) {
  final n = ((x1 - x0) / step).ceil();
  return smoothSvg([
    for (var i = 0; i <= n; i++)
      Offset(x0 + (x1 - x0) * i / n, f(x0 + (x1 - x0) * i / n)),
  ]);
}

/// A circle as path data.
String circleSvg(Offset c, double r) =>
    'M${c.dx - r} ${c.dy} A$r $r 0 1 0 ${c.dx + r} ${c.dy} '
    'A$r $r 0 1 0 ${c.dx - r} ${c.dy} Z';
