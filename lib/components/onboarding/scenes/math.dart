import 'dart:math';

import 'package:badnotes/components/editor_ui/selection_action_bar.dart';
import 'package:badnotes/components/onboarding/tour_engine.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

// ---------------------------------------------------------------------------
// Lasso: a sine/cosine graph and a worked integral; the integral is
// lassoed, moved, resized and recoloured
// ---------------------------------------------------------------------------

const _axis = Color(0xFF868E96);
const _sin = Color(0xFF1C7ED6), _cos = Color(0xFFE03131);
const _shade = Color(0x8CA5D8FF);
const _recolor = Color(0xFF4263EB);

const _ox = 70.0, _oy = 240.0, _ys = 75.0;
const _xs = 300 / (2 * pi);
double _sinY(double x) => _oy - _ys * sin((x - _ox) / _xs);
double _cosY(double x) => _oy - _ys * cos((x - _ox) / _xs);

void _noop() {}

final _graph = () {
  final axes = [
    InkLine(arrowSvg(const Offset(50, _oy), const Offset(402, _oy), head: 9),
        pen: Pen.shape, color: _axis, width: 2),
    InkLine(arrowSvg(const Offset(_ox, 352), const Offset(_ox, 110), head: 9),
        pen: Pen.shape, color: _axis, width: 2),
  ];
  final ticks = <Drawn>[
    for (var k = 1; k <= 4; k++)
      InkLine('M${_ox + 75 * k} ${_oy - 4} L${_ox + 75 * k} ${_oy + 4}',
          pen: Pen.fineliner, color: _axis, width: 1.6),
    InkLine('M${_ox - 4} 165 L${_ox + 4} 165 M${_ox - 4} 315 L${_ox + 4} 315',
        pen: Pen.fineliner, color: _axis, width: 1.6),
    for (final (i, s) in ['π/2', 'π', '3π/2', '2π'].indexed)
      InkText(s, at: Offset(_ox + 75 * (i + 1) - (s.length * 3.5), _oy + 6),
          color: const Color(0xFF6B7280), size: 15),
    InkText('1', at: const Offset(52, 155), color: const Color(0xFF6B7280), size: 15),
    InkText('−1', at: const Offset(44, 305), color: const Color(0xFF6B7280), size: 15),
  ];
  final curves = [
    InkLine(plotSvg(_sinY, _ox, 370, step: 5), pen: Pen.fountain, color: _sin, width: 2.6),
    InkLine(plotSvg(_cosY, _ox, 370, step: 5), pen: Pen.fountain, color: _cos, width: 2.6),
  ];
  final shade = InkFill(
    '${plotSvg(_sinY, _ox, 220, step: 5)} L220 $_oy L$_ox $_oy Z',
    color: _shade,
  );
  final names = <Drawn>[
    InkText('sin x', at: const Offset(152, 128), color: _sin, size: 24,
        font: 'Kalam', weight: FontWeight.w700),
    InkText('cos x', at: const Offset(292, 140), color: _cos, size: 24,
        font: 'Kalam', weight: FontWeight.w700),
  ];
  return <Drawn>[
    ...lay(0.03, 0.09, axes, gap: 30),
    ...lay(0.095, 0.15, ticks, gap: 4),
    ...lay(0.15, 0.24, [curves[0]]),
    ...lay(0.245, 0.33, [curves[1]]),
    ...lay(0.335, 0.37, [shade]),
    ...lay(0.375, 0.41, names, gap: 20),
  ];
}();

/// The worked integral in [ink].
List<Drawn> _integral(Color ink) => [
  InkText('∫', at: const Offset(432, 106), color: ink, size: 48),
  InkText('π', at: const Offset(452, 106), color: ink, size: 16),
  InkText('0', at: const Offset(444, 152), color: ink, size: 16),
  InkText('sin x dx', at: const Offset(468, 124), color: ink, size: 27),
  InkText('= −cos π + cos 0', at: const Offset(442, 182), color: ink, size: 23),
  InkText('= 1 + 1 = 2', at: const Offset(442, 220), color: ink, size: 25),
];

final _work = lay(0.42, 0.55, _integral(inkDark), gap: 10);
final _workBlue = _integral(_recolor);
final _answer = () {
  final r = (_work.last as InkText).rectOf('= 2');
  return InkLine(
    'M${r.left - 2} ${r.center.dy + 3} L${r.right + 4} ${r.center.dy + 2}',
    pen: Pen.highlighter,
    color: const Color(0xFF69DB7C),
    width: 20,
  );
}();
final _highlight = lay(0.555, 0.575, [_answer]);

final _picked = () {
  var r = (_work.first as InkText).rectOf('∫');
  for (final d in _work) {
    final text = d as InkText;
    r = r.expandToInclude(text.rectOf(text.text));
  }
  return r.inflate(12);
}();

/// The lasso, drawn round the integral, [k] of the way.
final _loop = () {
  final c = _picked.center;
  final rx = _picked.width / 2 + 20, ry = _picked.height / 2 + 18;
  const n = 26;
  return [
    for (var i = 0; i <= n; i++)
      () {
        final a = -pi * 0.6 + 2.12 * pi * i / n;
        final wob = 1 + 0.035 * sin(i * 1.7);
        return c + Offset(cos(a) * rx * wob, sin(a) * ry * wob);
      }(),
  ];
}();
final _loopPath = svgPath(smoothSvg(_loop));
final _loopMetric = _loopPath.computeMetrics().first;

final _inks = <Drawn>[..._graph, ..._work, ..._highlight];

const _cam = Cam([
  (0.0, Offset(220, 236), 1.35),
  (0.33, Offset(220, 236), 1.35),
  (0.42, Offset(520, 175), 1.35),
  (0.56, Offset(520, 175), 1.35),
  (0.6, Offset(320, 200), 1),
]);

final lassoScene = TourScene(
  duration: const Duration(milliseconds: 10000),
  rest: 0.93,
  build: (context, t) {
    final colors = BadNotesColors.of(context);
    final accent = colors.accent;
    final drawn = span(t, 0.6, 0.68, Curves.easeInOut);
    final selected = t >= 0.68;
    final move = span(t, 0.72, 0.79);
    final grow = 1 + 0.1 * span(t, 0.8, 0.86);
    final recolor = span(t, 0.88, 0.91);
    final shift = const Offset(-14, 46) * move;
    // scaled about the top left: the handle dragged is the bottom right
    final origin = _picked.topLeft + shift;
    final box = Rect.fromLTWH(
      origin.dx,
      origin.dy,
      _picked.width * grow,
      _picked.height * grow,
    );
    final fade = loopFade(t, out: 0.95);
    final dark = pagesDark(context);

    void paintPicked(Canvas canvas) {
      if (!selected) return;
      canvas.save();
      canvas.translate(origin.dx, origin.dy);
      canvas.scale(grow);
      canvas.translate(-_picked.left, -_picked.top);
      if (move > 0 && move < 1 || grow > 1 && grow < 1.1) {
        // lifted while it moves
        canvas.drawRRect(
          RRect.fromRectAndRadius(_picked.inflate(2), const Radius.circular(8)),
          Paint()..color = const Color(0x0F000000),
        );
      }
      _answer.paint(canvas, 1, fade, dark);
      for (final d in _work) {
        d.paint(canvas, 1, fade * (1 - recolor), dark);
      }
      for (final d in _workBlue) {
        d.paint(canvas, 1, fade * recolor, dark);
      }
      canvas.restore();
    }

    void paintLasso(Canvas canvas) {
      if (drawn <= 0 || fade <= 0) return;
      final shiftLoop = Offset(origin.dx - _picked.left, origin.dy - _picked.top);
      if (!selected) {
        final part = _loopMetric.extractPath(0, _loopMetric.length * drawn);
        canvas.drawPath(
          part,
          Paint()
            ..color = accent.withValues(alpha: fade)
            ..strokeWidth = 1.8
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round,
        );
        final tip = _loopMetric
            .getTangentForOffset(_loopMetric.length * drawn)!
            .position;
        drawStylus(canvas, tip, accent, opacity: fade);
        return;
      }
      final path = _loopPath.shift(shiftLoop);
      canvas.drawPath(path, Paint()..color = accent.withValues(alpha: 0.06 * fade));
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white.withValues(alpha: fade)
          ..strokeWidth = 2.6
          ..style = PaintingStyle.stroke,
      );
      canvas.drawPath(
        dashPath(
          path,
          dashArray: CircularIntervalList([6.0, 5.0]),
          dashOffset: DashOffset.absolute((1 - (t * 9) % 1) * 11),
        ),
        Paint()
          ..color = accent.withValues(alpha: fade)
          ..strokeWidth = 1.6
          ..style = PaintingStyle.stroke,
      );
      final ring = Paint()
        ..color = accent.withValues(alpha: fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3;
      canvas.drawRect(box, ring);
      final white = Paint()..color = Colors.white.withValues(alpha: fade);
      for (final h in [box.topLeft, box.topRight, box.bottomLeft, box.bottomRight]) {
        canvas.drawCircle(h, 5.5, white);
        canvas.drawCircle(h, 5.5, ring);
      }
      // the finger dragging, then the corner being pulled, then a tap
      final dragging = span(t, 0.7, 0.72) - span(t, 0.79, 0.8);
      if (dragging > 0) drawStylus(canvas, box.center, accent, opacity: dragging * fade);
      final resizing = span(t, 0.795, 0.8) - span(t, 0.86, 0.87);
      if (resizing > 0) {
        canvas.drawCircle(box.bottomRight, 14,
            Paint()..color = accent.withValues(alpha: 0.2 * resizing * fade));
        drawStylus(canvas, box.bottomRight, accent, opacity: resizing * fade);
      }
    }

    return inkPage(
      context,
      t: t,
      inks: selected ? _graph : _inks,
      cam: _cam,
      fade: fade,
      over: (canvas) {
        paintPicked(canvas);
        paintLasso(canvas);
      },
      toolbar: t < 0.585
          ? null
          : const MiniToolbar(
              pen: null,
              color: inkDark,
              palette: [inkDark, _sin, _cos, _recolor, Color(0xFF2F9E44)],
              lasso: true,
            ),
      overlays: [
        if (selected)
          Positioned.fill(
            child: Opacity(
              opacity: span(t, 0.69, 0.72) * fade,
              child: SelectionActionBar(
                bounds: () => box.inflate(10),
                repositioned: const AlwaysStoppedAnimation(0),
                color: Color.lerp(inkDark, _recolor, recolor),
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
    );
  },
);
