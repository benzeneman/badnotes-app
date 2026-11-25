import 'package:badnotes/components/onboarding/tour_engine.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/theming/badnotes_tokens.dart';
import 'package:badnotes/components/ui/bn_icons.dart';
import 'package:badnotes/data/tools/tape_pattern.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// The heart, labelled: blue for deoxygenated blood (venae cavae, right
// side, pulmonary artery), red for oxygenated (pulmonary veins, left side,
// aorta)
// ---------------------------------------------------------------------------

const _muscle = Color(0xFFF4B6B6), _muscleLine = Color(0xFFA61E4D);
const _blue = Color(0xFF4C6EF5), _blueLine = Color(0xFF364FC7);
const _blueBlood = Color(0xFF91A7FF);
const _red = Color(0xFFE03131), _redLine = Color(0xFFA51111);
const _redBlood = Color(0xFFFF8787);

const _heartSvg =
    'M195 150 C 160 160 150 200 158 240 C 168 290 220 330 275 352 '
    'C 330 320 372 270 372 215 C 372 180 352 152 320 148 '
    'C 290 145 270 150 255 152 C 235 150 215 146 195 150 Z';
const _raSvg =
    'M175 165 C 165 185 168 220 185 235 C 205 245 232 238 240 222 '
    'C 248 200 240 172 222 162 C 205 155 185 157 175 165 Z';
const _rvSvg =
    'M185 245 C 192 275 225 315 268 335 C 268 300 262 268 258 240 '
    'C 240 250 210 252 185 245 Z';
const _laSvg =
    'M270 168 C 268 190 282 210 305 214 C 330 216 352 200 352 182 '
    'C 352 165 335 156 312 157 C 295 158 278 160 270 168 Z';
const _lvSvg =
    'M266 228 C 272 268 276 305 280 334 C 318 310 350 270 356 225 '
    'C 340 232 318 236 298 232 C 286 230 276 228 266 228 Z';
const _svcSvg = 'M180 72 L204 72 L206 168 L182 172 Z';
const _ivcSvg =
    'M164 206 C 152 240 148 272 152 300 L174 300 '
    'C 172 272 174 244 184 226 Z';
const _aortaSvg =
    'M248 165 C 246 130 250 100 275 88 C 300 76 330 84 340 105 '
    'C 345 118 345 135 342 150 L 322 150 C 324 135 324 120 318 110 '
    'C 310 98 292 98 282 106 C 272 116 270 138 272 165 Z';
const _branchesSvg = [
  'M262 92 L258 52 L270 52 L274 88 Z',
  'M286 84 L286 46 L298 46 L298 83 Z',
  'M310 86 L316 50 L328 52 L320 90 Z',
];
const _pulmonarySvg =
    'M282 168 C 284 150 292 138 304 132 L 384 126 L 386 144 '
    'L 312 150 C 304 154 300 160 300 168 Z';
const _veinsSvg = [
  'M350 172 L394 166 L394 178 L351 184 Z',
  'M350 194 L394 194 L394 206 L348 204 Z',
];

List<Drawn> _part(String d, Color fill, Color line) => [
  InkFill(d, color: fill),
  InkLine(d, pen: Pen.fountain, color: line, width: 1.8),
];

/// The labels the tape goes over.
final _taped = <InkText>[];

final heartInks = () {
  List<Drawn> tag(String text, Offset at, Offset target, Color c, {bool tape = false}) {
    final l = label(text, at, target, c);
    if (tape) _taped.add(l.last as InkText);
    return l;
  }

  return <Drawn>[
    ..._part(_heartSvg, _muscle, _muscleLine),
    ..._part(_svcSvg, _blue, _blueLine),
    ..._part(_ivcSvg, _blue, _blueLine),
    ..._part(_raSvg, _blueBlood, _blueLine),
    ..._part(_rvSvg, _blueBlood, _blueLine),
    ..._part(_laSvg, _redBlood, _redLine),
    ..._part(_lvSvg, _redBlood, _redLine),
    ..._part(_aortaSvg, _red, _redLine),
    for (final b in _branchesSvg) ..._part(b, _red, _redLine),
    ..._part(_pulmonarySvg, _blue, _blueLine),
    for (final v in _veinsSvg) ..._part(v, _red, _redLine),
    // the way the blood goes
    InkLine(arrowSvg(const Offset(206, 196), const Offset(214, 262), head: 7),
        pen: Pen.fineliner, color: Colors.white, width: 1.8),
    InkLine(arrowSvg(const Offset(310, 190), const Offset(300, 266), head: 7),
        pen: Pen.fineliner, color: Colors.white, width: 1.8),
    ...tag('Superior vena cava', const Offset(22, 76), const Offset(186, 104), _blueLine, tape: true),
    ...tag('Right atrium', const Offset(22, 184), const Offset(196, 200), _blueLine, tape: true),
    ...tag('Inferior vena cava', const Offset(22, 272), const Offset(160, 282), _blueLine),
    ...tag('Right ventricle', const Offset(22, 330), const Offset(222, 290), _blueLine, tape: true),
    ...tag('Aorta', const Offset(372, 64), const Offset(340, 100), _redLine, tape: true),
    ...tag('Pulmonary artery', const Offset(404, 106), const Offset(378, 135), _blueLine),
    ...tag('Pulmonary veins', const Offset(420, 176), const Offset(396, 188), _redLine),
    ...tag('Left atrium', const Offset(420, 232), const Offset(325, 205), _redLine, tape: true),
    ...tag('Left ventricle', const Offset(420, 292), const Offset(322, 282), _redLine, tape: true),
  ];
}();

// ---------------------------------------------------------------------------
// Tape quiz
// ---------------------------------------------------------------------------

const _tapeColor = Color(0xFFFFB74D);

final _tapedRects = () {
  if (heartInks.isEmpty) return <Rect>[];
  return [for (final l in _taped) l.rectOf(l.text).inflate(5)];
}();
final _stripes = <Rect, Path>{};

/// A strip of tape over [r], laid [laid] of the way along and lifted
/// [peeked], as the editor draws tape (stripes and all).
void _drawTape(Canvas canvas, Rect r, double laid, double peeked, double fade) {
  if (laid <= 0 || fade <= 0) return;
  final rect = Rect.fromLTWH(r.left, r.top, r.width * laid, r.height);
  final covered = 1 - peeked;
  canvas.drawRect(
    rect.shift(const Offset(1.5, 2.5)),
    Paint()..color = Color.fromRGBO(0, 0, 0, 0.12 * covered * fade),
  );
  canvas.drawRect(
    rect,
    Paint()
      ..color = Color.lerp(_tapeColor, _tapeColor.withValues(alpha: 0.18), peeked)!
          .withValues(alpha: (1 - 0.82 * peeked) * fade),
  );
  if (covered <= 0) return;
  final stripes = _stripes.putIfAbsent(
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
    stripes,
    Paint()..color = Color.fromRGBO(255, 255, 255, 0.35 * covered * fade),
  );
  canvas.restore();
}

/// A close-up on taped label [i] and what it points at.
Rect _near(int i) => Rect.fromCenter(
  center: _tapedRects[i].center,
  width: 400,
  height: 250,
);

final _tapeCam = () {
  final all = boundsOf(heartInks);
  return Cam([
    (0.0, all),
    (0.4, all),
    (0.46, _near(2)),
    (0.56, _near(2)),
    (0.62, _near(3)),
    (0.7, _near(5)),
    (0.76, _near(5)),
    (0.84, all),
  ]);
}();

final tapeScene = TourScene(
  duration: const Duration(milliseconds: 12600),
  done: 0.88,
  inks: heartInks,
  cam: _tapeCam,
  build: (context, t) {
    final colors = BadNotesColors.of(context);
    final fade = loopFade(t);
    final rects = _tapedRects;
    final laid = [
      for (var i = 0; i < rects.length; i++)
        span(t, 0.06 + 0.055 * i, 0.1 + 0.055 * i, Curves.easeInOut),
    ];
    // taps on the right ventricle, the aorta, the left ventricle
    const taps = {2: 0.46, 3: 0.6, 5: 0.74};
    return inkPage(
      context,
      t: t,
      inks: heartInks,
      fade: fade,
      toolbar: const MiniToolbar(
        pen: null,
        color: _tapeColor,
        palette: [_tapeColor, Color(0xFFFF8A65), Color(0xFFEF5350), Color(0xFFEC407A)],
        tape: true,
        docked: 1,
      ),
      cam: _tapeCam,
      over: (canvas) {
        for (var i = 0; i < rects.length; i++) {
          final tap = taps[i];
          final peek = tap == null ? 0.0 : span(t, tap + 0.02, tap + 0.06);
          _drawTape(canvas, rects[i], laid[i], peek, fade);
          final layingNow = laid[i] > 0 && laid[i] < 1;
          if (layingNow) {
            drawStylus(
              canvas,
              Offset(rects[i].left + rects[i].width * laid[i], rects[i].center.dy),
              _tapeColor,
            );
          }
          if (tap != null) {
            drawTap(canvas, rects[i].center, span(t, tap, tap + 0.08, Curves.easeOut), colors.accent);
          }
        }
      },
    );
  },
);

// ---------------------------------------------------------------------------
// Dark pages and the toolbar: floating, docked
// ---------------------------------------------------------------------------

final _themes = <Brightness, ThemeData>{};
ThemeData _theme(Brightness b) => _themes.putIfAbsent(b, () => BadNotesTheme.create(b));

/// The light/dark switch in the header.
const _toggle = Offset(585, headerH / 2);

/// Where the page shows in the dark mode scene: under the header and the
/// band the floating toolbar hovers in, so the toolbar never covers ink.
const _darkView = Rect.fromLTRB(0, headerH + 52, 640, 400);

class _CircleClip extends CustomClipper<Path> {
  new(this.radius);

  final double radius;

  @override
  Path getClip(Size size) =>
      Path()..addOval(Rect.fromCircle(center: _toggle, radius: radius));

  @override
  bool shouldReclip(_CircleClip old) => old.radius != radius;
}

Widget _editor(BuildContext context, double t, double docked, bool dark) {
  final colors = BadNotesColors.of(context);
  final scheme = ColorScheme.of(context);
  return Stack(
    fit: StackFit.expand,
    children: [
      CustomPaint(
        painter: InkPainter(
          t: 1,
          inks: heartInks,
          dots: scheme.primary,
          view: _darkView,
          dark: dark,
          stylus: false,
        ),
      ),
      Positioned(
        left: 0,
        right: 0,
        top: 0,
        height: headerH,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border(bottom: BorderSide(color: colors.hairline)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 10),
              Icon(BnIcons.back, size: 20, color: colors.text2),
              const SizedBox(width: 4),
              Text('Heart anatomy', style: BnType.title.copyWith(color: colors.text)),
              const Spacer(),
              Icon(BnIcons.search, size: 17, color: colors.text2),
              const SizedBox(width: 16),
              Icon(
                dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                size: 18,
                color: colors.text2,
              ),
              const SizedBox(width: 16),
              Icon(BnIcons.more, size: 18, color: colors.text2),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ),
      // floating just under the header, over empty paper; docked, in the
      // header between the title and the icons
      Positioned(
        top: headerH + 6 - (headerH + 6 - 3) * docked,
        left: 50 * docked,
        right: 0,
        child: Center(
          child: Transform.scale(
            scale: 1 - 0.1 * docked,
            child: MiniToolbar(
              pen: Pen.fountain,
              color: const Color(0xFFE03131),
              palette: const [
                inkDark,
                Color(0xFFE03131),
                Color(0xFF4C6EF5),
                Color(0xFF2F9E44),
                Color(0xFFF59F00),
              ],
              docked: docked,
            ),
          ),
        ),
      ),
    ],
  );
}

final darkScene = TourScene(
  duration: const Duration(milliseconds: 12600),
  done: 0.98,
  inks: heartInks,
  view: _darkView,
  build: (context, t) {
    final docked = span(t, 0.1, 0.24) - span(t, 0.7, 0.82);
    final wipe = span(t, 0.38, 0.58) - span(t, 0.86, 0.97);
    Widget editor(Brightness b) => Theme(
      data: _theme(b),
      child: Builder(
        builder: (context) => _editor(context, t, docked, b == Brightness.dark),
      ),
    );
    final tap = span(t, 0.33, 0.41, Curves.easeOut);
    return Stack(
      fit: StackFit.expand,
      children: [
        if (wipe < 1) editor(Brightness.light),
        if (wipe > 0)
          ClipPath(clipper: _CircleClip(760 * wipe), child: editor(Brightness.dark)),
        if (tap > 0 && tap < 1)
          CustomPaint(
            painter: TapPainter(_toggle, tap, BadNotesColors.of(context).accent),
          ),
      ],
    );
  },
);
