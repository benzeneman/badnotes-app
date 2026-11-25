import 'dart:math';

import 'package:badnotes/components/onboarding/tour_engine.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Shapes: a free-body diagram drawn rough, held, and snapped clean
// ---------------------------------------------------------------------------

const _slate = Color(0xFF495057);
const _block = Color(0xFF1C7ED6), _blockFill = Color(0xFFD0EBFF);
const _weight = Color(0xFFE03131);
const _normal = Color(0xFF2F9E44);
const _friction = Color(0xFFF76707);
const _angle = Color(0xFF7048E8);
const _hold = Color(0xFF4C6EF5);

/// The loop time being painted (shapes snap on the clock, not on their
/// own progress).
double _now = 0;

/// A shape drawn by hand, held still, then snapped to its clean form,
/// point for point.
class _Snap extends Drawn {
  new(
    String rough,
    String clean, {
    required Color color,
    required double a,
    required this.written,
    required this.held,
    required double b,
    this.fill,
  }) : rough = svgPath(rough),
       clean = svgPath(clean),
       super(Pen.shape, color) {
    this.a = a;
    this.b = b;
  }

  final Path rough, clean;
  final double written, held;
  final Color? fill;

  late final _roughMetric = rough.computeMetrics().first;
  late final _from = _sample(rough), _to = _sample(clean);

  static List<Offset> _sample(Path path) {
    final m = path.computeMetrics().first;
    const n = 220;
    return [
      for (var i = 0; i <= n; i++)
        m.getTangentForOffset(m.length * i / n)!.position,
    ];
  }

  @override
  double get cost => 0;

  @override
  double progress(double t) => t <= a
      ? 0
      : t >= written
      ? 1
      : Curves.easeInOutSine.transform((t - a) / (written - a));

  @override
  void paint(Canvas canvas, double p, double fade, bool dark) {
    if (p <= 0 || fade <= 0) return;
    final c = pageInk(color, dark);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = c.withValues(alpha: fade);
    final t = _now;
    if (t >= b) {
      if (fill case final f?) {
        final k = span(t, b, b + 0.04);
        canvas.drawPath(
          clean,
          Paint()..color = pageInk(f, dark).withValues(alpha: k * fade),
        );
      }
      canvas.drawPath(clean, line..strokeWidth = 3);
      return;
    }
    if (t < held) {
      line.strokeWidth = 2.6;
      canvas.drawPath(
        _roughMetric.extractPath(0, _roughMetric.length * p),
        line,
      );
      if (t >= written) {
        // the hold: a ring filling round the pen
        final k = span(t, written, held, Curves.linear);
        final end = tipAt(1);
        canvas.drawArc(
          Rect.fromCircle(center: end, radius: 15),
          -pi / 2,
          2 * pi * k,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round
            ..color = pageInk(_hold, dark).withValues(alpha: 0.85 * fade),
        );
      }
      return;
    }
    final k = Curves.easeOutBack.transform(((t - held) / (b - held)).clamp(0, 1));
    final path = Path()..moveTo(_from[0].dx, _from[0].dy);
    for (var i = 1; i < _from.length; i++) {
      final q = Offset.lerp(_from[i], _to[i], k)!;
      path.lineTo(q.dx, q.dy);
    }
    canvas.drawPath(path, line..strokeWidth = 2.6 + 0.4 * k.clamp(0, 1));
  }

  @override
  Offset tipAt(double p) => _roughMetric
      .getTangentForOffset(_roughMetric.length * p.clamp(0, 1))!
      .position;
}

/// [points] as a hand would draw them: corners a little off, edges a
/// little bowed, the end overshooting the start.
String _rough(List<Offset> points, {required int seed, double wobble = 5}) {
  final r = Random(seed);
  double j() => (r.nextDouble() * 2 - 1) * wobble;
  final out = <Offset>[];
  for (var i = 0; i < points.length; i++) {
    final a = points[i], b = points[(i + 1) % points.length];
    final n = Offset(-(b - a).dy, (b - a).dx) / (b - a).distance;
    out
      ..add(a + Offset(j() * 0.5, j() * 0.5))
      ..add(Offset.lerp(a, b, 0.35)! + n * j())
      ..add(Offset.lerp(a, b, 0.7)! + n * j());
  }
  out.add(points.first + Offset(wobble * 0.8, wobble * 1.4));
  return smoothSvg(out);
}

String _p(Offset o) => '${o.dx.toStringAsFixed(1)} ${o.dy.toStringAsFixed(1)}';

/// A clean polygon as path data, closed.
String _poly(List<Offset> points) =>
    'M${_p(points.first)} ${[for (final q in points.skip(1)) 'L${_p(q)}'].join(' ')} Z';

/// An arrow as one continuous stroke (shaft, then the head), so it can
/// morph point for point.
String _arrowOne(Offset a, Offset b, {double head = 12}) {
  final d = (b - a) / (b - a).distance;
  final n = Offset(-d.dy, d.dx);
  return 'M${_p(a)} L${_p(b)} L${_p(b - d * head + n * head * 0.6)} '
      'L${_p(b)} L${_p(b - d * head - n * head * 0.6)}';
}

String _arrowRough(Offset a, Offset b, {required int seed}) {
  final r = Random(seed);
  final d = (b - a) / (b - a).distance;
  final n = Offset(-d.dy, d.dx);
  final shaft = smoothSvg([
    a,
    Offset.lerp(a, b, 0.4)! + n * (r.nextDouble() * 6 - 3),
    Offset.lerp(a, b, 0.75)! + n * (r.nextDouble() * 6 - 3),
    b + n * 2,
  ]);
  return '$shaft L${_p(b - d * 14 + n * 9)} L${_p(b + n * 1.5)} '
      'L${_p(b - d * 13 - n * 8)}';
}

/// θ, drawn: the font has no Greek.
InkLine _theta(Offset c, Color color, {double h = 9}) => InkLine(
  'M${c.dx} ${c.dy - h} C ${c.dx + h * 0.8} ${c.dy - h} ${c.dx + h * 0.8} ${c.dy + h} '
  '${c.dx} ${c.dy + h} C ${c.dx - h * 0.8} ${c.dy + h} ${c.dx - h * 0.8} ${c.dy - h} '
  '${c.dx} ${c.dy - h} M${c.dx - h * 0.55} ${c.dy} L${c.dx + h * 0.55} ${c.dy}',
  pen: Pen.ballpoint,
  color: color,
  width: 2,
);

// the ramp: right angle bottom left, θ at the bottom right
const _rampA = Offset(80, 150), _rampB = Offset(80, 340), _rampC = Offset(560, 340);
final _u = (_rampC - _rampA) / (_rampC - _rampA).distance; // down the slope
final _n = Offset(_u.dy, -_u.dx); // out of the slope
final _base = _rampA + _u * 250;
final _corners = [
  _base - _u * 46,
  _base + _u * 46,
  _base + _u * 46 + _n * 62,
  _base - _u * 46 + _n * 62,
];
final _g = _base + _n * 31;

final _ramp = _Snap(
  _rough([_rampA, _rampB, _rampC], seed: 3, wobble: 7),
  _poly([_rampA, _rampB, _rampC]),
  color: _slate,
  a: 0.04,
  written: 0.13,
  held: 0.17,
  b: 0.21,
);
final _box = _Snap(
  _rough(_corners, seed: 11, wobble: 4),
  _poly(_corners),
  color: _block,
  a: 0.24,
  written: 0.31,
  held: 0.35,
  b: 0.39,
  fill: _blockFill,
);
final _mg = _Snap(
  _arrowRough(_g, _g + const Offset(0, 98), seed: 5),
  _arrowOne(_g, _g + const Offset(0, 98)),
  color: _weight,
  a: 0.44,
  written: 0.49,
  held: 0.53,
  b: 0.565,
);

final _physicsInks = () {
  final arrows = [
    InkLine(arrowSvg(_g, _g + _n * 92), pen: Pen.shape, color: _normal, width: 3),
    InkLine(arrowSvg(_g, _g - _u * 92), pen: Pen.shape, color: _friction, width: 3),
  ];
  final alpha = atan2(_rampC.dy - _rampA.dy, _rampC.dx - _rampA.dx);
  final arcEnd = _rampC + Offset(cos(pi + alpha), sin(pi + alpha)) * 56;
  final thetaAt = _rampC + Offset(cos(pi + alpha / 2), sin(pi + alpha / 2)) * 78;
  Drawn force(String s, Offset at, Color c) =>
      InkText(s, at: at, color: c, size: 24, font: 'Kalam', weight: FontWeight.w700);
  final labels = <Drawn>[
    force('mg', _g + const Offset(10, 72), _weight),
    force('N', _g + _n * 92 + const Offset(8, -14), _normal),
    force('f', _g - _u * 92 + const Offset(-20, -30), _friction),
    InkLine(
      'M${_p(_rampC - const Offset(56, 0))} A56 56 0 0 1 ${_p(arcEnd)}',
      pen: Pen.fineliner,
      color: _angle,
      width: 2,
    ),
    _theta(thetaAt, _angle, h: 8),
  ];

  final title = InkText(
    'Inclined plane',
    at: const Offset(22, 58),
    color: const Color(0xFF343A40),
    size: 28,
    font: 'Kalam',
    weight: FontWeight.w700,
    pen: Pen.fountain,
  );
  final fma = InkText(
    'F = ma',
    at: const Offset(440, 62),
    color: const Color(0xFF1E3A8A),
    size: 32,
    font: 'Kalam',
    weight: FontWeight.w700,
    pen: Pen.fountain,
  );
  final r = fma.rectOf('F = ma');
  final mark = InkLine(
    'M${r.left - 3} ${r.bottom - 12} L${r.right + 5} ${r.bottom - 13}',
    pen: Pen.highlighter,
    color: const Color(0xFF8CE99A),
    width: 17,
  );
  const lineAt = 446.0;
  final l1 = InkText('f = μN', at: const Offset(lineAt, 112), size: 21);
  final l2 = InkText('N = mg cos', at: const Offset(lineAt, 142), size: 21);
  final l3a = InkText('mg sin', at: const Offset(lineAt, 172), size: 21);
  final l3b = InkText(
    '− f = ma',
    at: Offset(lineAt + l3a.box.width + 18, 172),
    size: 21,
  );
  final work = <Drawn>[
    l1,
    l2,
    _theta(Offset(lineAt + l2.box.width + 9, 142 + l2.box.height * 0.52), inkDark, h: 6.5),
    l3a,
    _theta(Offset(lineAt + l3a.box.width + 9, 172 + l3a.box.height * 0.52), inkDark, h: 6.5),
    l3b,
  ];

  return <Drawn>[
    _ramp,
    _box,
    _mg,
    ...lay(0.585, 0.65, arrows, gap: 20),
    ...lay(0.655, 0.76, labels, gap: 16),
    ...lay(0.77, 0.81, [title]),
    ...lay(0.815, 0.85, [fma]),
    ...lay(0.852, 0.866, [mark]),
    ...lay(0.87, 0.92, work, gap: 12),
  ];
}();

final _physicsCam = Cam([
  (0.0, const Offset(320, 245), 1.18),
  (0.21, const Offset(320, 245), 1.18),
  (0.24, _base + _n * 30, 1.6),
  (0.4, _base + _n * 30, 1.6),
  (0.44, _g + const Offset(0, 50), 1.5),
  (0.57, _g + const Offset(0, 40), 1.4),
  (0.66, const Offset(320, 200), 1),
  (0.77, const Offset(320, 200), 1),
  (0.86, const Offset(470, 140), 1.25),
  (0.925, const Offset(470, 140), 1.25),
  (0.95, const Offset(320, 200), 1),
]);

final physicsScene = TourScene(
  duration: const Duration(milliseconds: 10500),
  rest: 0.95,
  build: (context, t) {
    _now = t;
    return inkPage(
      context,
      t: t,
      inks: _physicsInks,
      cam: _physicsCam,
      fade: loopFade(t, out: 0.95),
    );
  },
);
