import 'dart:math';

import 'package:badnotes/components/onboarding/tour_engine.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/theming/badnotes_tokens.dart';
import 'package:badnotes/components/ui/bn_controls.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Recording: the nitration of benzene plays back in Real-time reveal, then
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

/// The ink's own clock is one playback: it is laid out for that long.
const _playMs = 6400;

final _inks = paced(_playMs, () {
  final heading = InkText(
    'Nitration of benzene',
    at: const Offset(28, 56),
    color: _title,
    size: 32,
    font: 'Kalam',
    weight: FontWeight.w700,
    pen: Pen.fountain,
  );
  final hr = heading.rectOf(heading.text);
  Drawn chem(String s, Offset at, Color c, {double size = 34}) =>
      InkText(s, at: at, color: c, size: size, font: 'Caveat', weight: FontWeight.w700);
  const reactant = Offset(108, 214), product = Offset(474, 222);
  return lay(0.0, 0.97, <Drawn>[
    heading,
    InkLine(
      'M${hr.left} ${hr.bottom - 10} L${hr.right + 4} ${hr.bottom - 12}',
      pen: Pen.highlighter,
      color: const Color(0xFF99E9F2),
      width: 17,
    ),
    ..._benzene(reactant, 54),
    chem('+', const Offset(176, 190), _bond),
    chem('HNO₃', const Offset(200, 192), _nitric),
    InkLine(arrowSvg(const Offset(300, 216), const Offset(398, 216), head: 12),
        pen: Pen.shape, color: _arrow, width: 2.8),
    chem('H₂SO₄', const Offset(310, 170), _catalyst, size: 27),
    chem('50 °C', const Offset(318, 224), const Color(0xFF6B7280), size: 25),
    ..._benzene(product, 54),
    InkLine('M${_p(product - const Offset(0, 54))} L${_p(product - const Offset(0, 84))}',
        pen: Pen.ballpoint, color: _bond, width: 2.6),
    chem('NO₂', product + const Offset(-25, -124), _oxygen),
    chem('+ H₂O', const Offset(536, 204), _water, size: 31),
    InkText('Electrophilic substitution', at: const Offset(60, 300), size: 23),
    InkLine('M60 334 C 150 330 240 336 322 331',
        pen: Pen.fineliner, color: _title, width: 1.8),
  ], gap: 30);
});

String _clock(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';

/// The playback bar's strip at the bottom of the stage.
const _footerH = 58.0;
const _view = Rect.fromLTRB(0, headerH, 640, 400 - _footerH);

/// Where the Spotlight segment of the mode switch is on the stage.
const _spotlightAt = Offset(390, headerH / 2);

// The timeline: once in Real-time reveal (the page starts empty and the
// lines write themselves with the sound), a tap on Spotlight, then once in
// Spotlight (the whole page faint, each line turning to full ink when the
// sound reaches it, and staying).
const _reveal = (0.02, 0.42), _tap = 0.445, _switch = 0.47, _dim = (0.47, 0.51);
const _spot = (0.53, 0.93);

final recordingScene = TourScene(
  duration: const Duration(milliseconds: 16000),
  done: 0.95,
  inks: _inks,
  view: _view,
  build: (context, t) {
    final colors = BadNotesColors.of(context);
    final scheme = ColorScheme.of(context);
    final dark = pagesDark(context);
    final spotlight = t >= _switch;
    final played = spotlight
        ? span(t, _spot.$1, _spot.$2, Curves.linear)
        : span(t, _reveal.$1, _reveal.$2, Curves.linear);
    final cam = fitAll(_inks);
    final painter = !spotlight
        ? InkPainter(
            t: played,
            inks: _inks,
            dots: scheme.primary,
            cam: cam,
            view: _view,
            dark: dark,
            fade: loopFade(t),
            stylus: false,
          )
        : t < _dim.$2
        // switching: the written page fades down to its faint ghost
        ? InkPainter(
            t: 1,
            inks: _inks,
            dots: scheme.primary,
            cam: cam,
            view: _view,
            dark: dark,
            fade: 1 - 0.75 * span(t, _dim.$1, _dim.$2),
            stylus: false,
          )
        : InkPainter(
            t: played,
            inks: _inks,
            dots: scheme.primary,
            cam: cam,
            view: _view,
            dark: dark,
            spotlight: 0.25,
          );
    final mode = spotlight ? 'Spotlight' : 'Real-time reveal';
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: painter),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: StageHeader(
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
        if (t > _tap && t < _tap + 0.05)
          CustomPaint(
            painter: TapPainter(
              _spotlightAt,
              span(t, _tap, _tap + 0.05, Curves.easeOut),
              colors.accent,
            ),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: _footerH,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(top: BorderSide(color: colors.hairline)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(color: colors.text, shape: BoxShape.circle),
                    child: Icon(Icons.pause_rounded, color: colors.surface, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _clock((played * 94).round()),
                    style: BnType.body.copyWith(
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
                  Text(_clock(94), style: BnType.body.copyWith(color: colors.muted)),
                  const SizedBox(width: 12),
                  // the mode playing, as a chip
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: (spotlight ? colors.accent : colors.text2).withValues(alpha: 0.12),
                      borderRadius: const BorderRadius.all(Radius.circular(BnRadius.control)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          spotlight ? Icons.highlight_rounded : Icons.play_arrow_rounded,
                          size: 16,
                          color: spotlight ? colors.accent : colors.text2,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          mode,
                          style: BnType.caption.copyWith(
                            color: spotlight ? colors.accent : colors.text2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
