import 'dart:math';

import 'package:badnotes/components/onboarding/tour_engine.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/theming/badnotes_tokens.dart';
import 'package:badnotes/components/ui/bn_controls.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Recording: the nitration of benzene replays in time with the audio, then
// in Spotlight
// ---------------------------------------------------------------------------

const _bond = Color(0xFF343A40);
const _double = Color(0xFF1C7ED6);
const _oxygen = Color(0xFFE03131); // CPK red
const _nitric = Color(0xFFC92A2A);
const _catalyst = Color(0xFF7048E8);
const _arrow = Color(0xFF2F9E44);
const _water = Color(0xFF1971C2);
const _title = Color(0xFF0C8599);

List<Offset> _hex(Offset c, double r) => [
  for (var k = 0; k < 6; k++)
    c + Offset(cos(-pi / 2 + k * pi / 3), sin(-pi / 2 + k * pi / 3)) * r,
];

String _p(Offset o) => '${o.dx.toStringAsFixed(1)} ${o.dy.toStringAsFixed(1)}';

/// A benzene ring: the hexagon in one stroke, then the three double bonds
/// inside it.
List<Drawn> _benzene(Offset c, double r) {
  final v = _hex(c, r);
  final inner = [for (final q in v) c + (q - c) * 0.76];
  return [
    InkLine(
      'M${_p(v[0])} ${[for (final q in v.skip(1)) 'L${_p(q)}'].join(' ')} Z',
      pen: Pen.fountain,
      color: _bond,
      width: 2.3,
    ),
    for (final i in [0, 2, 4])
      InkLine(
        'M${_p(Offset.lerp(inner[i], inner[i + 1], 0.14)!)} '
        'L${_p(Offset.lerp(inner[i], inner[i + 1], 0.86)!)}',
        pen: Pen.ballpoint,
        color: _double,
        width: 2.4,
      ),
  ];
}

final _inks = () {
  final heading = InkText(
    'Nitration of benzene',
    at: const Offset(30, 56),
    color: _title,
    size: 30,
    font: 'Kalam',
    weight: FontWeight.w700,
    pen: Pen.fountain,
  );
  final hr = heading.rectOf(heading.text);
  Drawn chem(String s, Offset at, Color c, {double size = 30}) =>
      InkText(s, at: at, color: c, size: size, font: 'Caveat', weight: FontWeight.w700);
  const product = Offset(474, 232);
  return lay(0.0, 0.97, <Drawn>[
    heading,
    InkLine(
      'M${hr.left} ${hr.bottom - 10} L${hr.right + 4} ${hr.bottom - 12}',
      pen: Pen.highlighter,
      color: const Color(0xFF99E9F2),
      width: 16,
    ),
    ..._benzene(const Offset(118, 222), 46),
    chem('+', const Offset(180, 200), _bond),
    chem('HNO₃', const Offset(204, 202), _nitric),
    InkLine(arrowSvg(const Offset(298, 224), const Offset(392, 224), head: 11),
        pen: Pen.shape, color: _arrow, width: 2.6),
    chem('H₂SO₄', const Offset(310, 182), _catalyst, size: 24),
    chem('50 °C', const Offset(318, 230), const Color(0xFF6B7280), size: 22),
    ..._benzene(product, 46),
    InkLine('M${_p(product - const Offset(0, 46))} L${_p(product - const Offset(0, 74))}',
        pen: Pen.ballpoint, color: _bond, width: 2.4),
    chem('NO₂', product + const Offset(-22, -112), _oxygen),
    chem('+ H₂O', const Offset(532, 214), _water, size: 28),
    InkText('Electrophilic substitution', at: const Offset(64, 300), size: 20),
    InkLine('M64 330 C 140 326 220 332 290 327',
        pen: Pen.fineliner, color: _title, width: 1.6),
  ], gap: 30);
}();

String _clock(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

final recordingScene = TourScene(
  duration: const Duration(milliseconds: 11000),
  rest: 0.46,
  build: (context, t) {
    final colors = BadNotesColors.of(context);
    final scheme = ColorScheme.of(context);
    final dark = pagesDark(context);
    final spotlight = t >= 0.5;
    // the ink's own clock: once through as it was written, once in Spotlight
    final inkT = spotlight
        ? span(t, 0.53, 0.93, Curves.linear)
        : span(t, 0.02, 0.46, Curves.linear);
    final played = spotlight ? span(t, 0.53, 0.93, Curves.linear) : inkT;
    final fade = min(loopFade(t, out: 0.95), 1 - span(t, 0.47, 0.5) + span(t, 0.5, 0.53));
    final recent = [
      for (final d in _inks)
        if (d.a <= inkT && d.b >= inkT - 0.06) d,
    ];
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
          painter: spotlight
              ? InkPainter(
                  t: 1,
                  inks: _inks,
                  dots: scheme.primary,
                  dark: dark,
                  fade: 0.14 * fade,
                  stylus: false,
                )
              : InkPainter(t: inkT, inks: _inks, dots: scheme.primary, dark: dark, fade: fade),
        ),
        if (spotlight)
          CustomPaint(
            painter: InkPainter(
              t: inkT,
              inks: recent,
              dots: scheme.primary,
              dark: dark,
              fade: fade,
              drawPaper: false,
            ),
          ),
        Positioned(
          top: 10,
          left: 0,
          right: 0,
          child: Center(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(BnRadius.control)),
                boxShadow: BnShadows.floating,
              ),
              child: SizedBox(
                width: 280,
                child: BnSegmented<String>(
                  segments: const [
                    BnSegment('reveal', 'Real-time reveal'),
                    BnSegment('spotlight', 'Spotlight'),
                  ],
                  selected: spotlight ? 'spotlight' : 'reveal',
                  height: 32,
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 90,
          right: 90,
          bottom: 14,
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.hairline),
              borderRadius: const BorderRadius.all(Radius.circular(BnRadius.popover)),
              boxShadow: BnShadows.floating,
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: colors.text, shape: BoxShape.circle),
                  child: Icon(Icons.pause_rounded, color: colors.surface, size: 19),
                ),
                const SizedBox(width: 10),
                Text(
                  _clock((played * 94).round()),
                  style: BnType.caption.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CustomPaint(
                    size: const Size.fromHeight(30),
                    painter: _Wave(played, colors.accent, colors.hairline),
                  ),
                ),
                const SizedBox(width: 10),
                Text(_clock(94), style: BnType.caption.copyWith(color: colors.muted)),
              ],
            ),
          ),
        ),
      ],
    );
  },
);

/// The recording's waveform, played up to [k].
class _Wave extends CustomPainter {
  new(this.k, this.played, this.rest);

  final double k;
  final Color played, rest;

  @override
  void paint(Canvas canvas, Size size) {
    const n = 64;
    final w = size.width / n;
    final on = Paint()
      ..color = played
      ..strokeWidth = max(1.5, w * 0.55)
      ..strokeCap = StrokeCap.round;
    final off = Paint()
      ..color = rest
      ..strokeWidth = on.strokeWidth
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < n; i++) {
      final a = 0.25 +
          0.75 * (0.5 + 0.5 * sin(i * 0.9) * cos(i * 0.37)).abs() *
              (0.6 + 0.4 * sin(i * 0.21 + 1));
      final h = size.height * a * 0.9;
      final x = w * (i + 0.5);
      canvas.drawLine(
        Offset(x, size.height / 2 - h / 2),
        Offset(x, size.height / 2 + h / 2),
        i / n <= k ? on : off,
      );
    }
  }

  @override
  bool shouldRepaint(_Wave old) => old.k != k || old.played != played;
}
