import 'package:badnotes/components/onboarding/tour_engine.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/theming/badnotes_tokens.dart';
import 'package:badnotes/components/ui/bn_icons.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Handwriting search: the lobes of the brain, then "cortex" found in the
// handwritten notes
// ---------------------------------------------------------------------------

// each lobe its own pastel, outlined in grey, folds in a deeper shade
const _frontal = (Color(0xFFA5D8FF), Color(0xFF1C7ED6));
const _parietal = (Color(0xFFFFEC99), Color(0xFFE67700));
const _temporal = (Color(0xFFB2F2BB), Color(0xFF2B8A3E));
const _occipital = (Color(0xFFFCC2D7), Color(0xFFC2255C));
const _cerebellum = (Color(0xFFD0BFFF), Color(0xFF6741D9));
const _stem = (Color(0xFFDEE2E6), Color(0xFF495057));
const _outline = Color(0xFF5C5F66);

const _frontalSvg =
    'M240 83 C 190 80 130 92 100 128 C 78 155 74 195 88 214 '
    'C 100 226 112 230 122 228 C 150 220 180 214 205 212 '
    'C 214 185 222 160 226 140 C 230 118 236 98 240 83 Z';
const _parietalSvg =
    'M240 83 C 286 82 326 96 348 124 C 338 150 326 176 318 200 '
    'C 300 200 285 200 270 200 C 248 204 226 208 205 212 '
    'C 214 185 222 160 226 140 C 230 118 236 98 240 83 Z';
const _occipitalSvg =
    'M348 124 C 364 142 374 166 372 188 C 370 208 362 222 350 232 '
    'C 336 228 326 216 318 200 C 326 176 338 150 348 124 Z';
const _temporalSvg =
    'M122 228 C 150 220 180 214 205 212 C 226 208 248 204 270 200 '
    'L 318 200 C 326 216 336 228 350 232 C 340 246 322 254 300 262 '
    'C 266 274 220 278 180 272 C 150 268 128 256 118 244 '
    'C 114 236 116 230 122 228 Z';
const _stemSvg =
    'M256 268 C 262 296 264 324 260 352 C 270 357 282 357 290 352 '
    'C 286 326 286 300 290 282 C 280 276 268 271 256 268 Z';
const _cerebellumSvg =
    'M300 262 C 322 254 340 246 350 232 C 368 240 378 256 372 274 '
    'C 364 294 336 304 310 298 C 292 294 284 280 290 268 '
    'C 293 265 296 263 300 262 Z';

const _query = 'cortex';

final _heading = InkText(
  'The Brain',
  at: const Offset(22, 50),
  color: const Color(0xFF5F3DC4),
  size: 30,
  font: 'Kalam',
  weight: FontWeight.w700,
  pen: Pen.fountain,
);

final _notes = [
  InkText('Cortex = outer grey matter', at: const Offset(418, 150), size: 19),
  InkText('· motor cortex - frontal', at: const Offset(424, 180), size: 17),
  InkText('· visual cortex - occipital', at: const Offset(424, 206), size: 17),
  InkText('· auditory cortex - temporal', at: const Offset(424, 232), size: 17),
];

/// Where each match is on the page.
final _matches = [
  for (final n in _notes)
    (n.text.contains('Cortex') ? n.rectOf('Cortex') : n.rectOf(_query))
        .inflate(2),
];

final _inks = () {
  List<Drawn> lobe(String d, (Color, Color) c) => [
    InkFill(d, color: c.$1),
    InkLine(d, pen: Pen.fountain, color: _outline, width: 1.7),
  ];
  InkLine fold(String d, Color c) =>
      InkLine(d, pen: Pen.fineliner, color: c, width: 1.3);
  final r = _heading.rectOf('The Brain');
  return <Drawn>[
    ...lay(0.03, 0.34, [
      ...lobe(_frontalSvg, _frontal),
      ...lobe(_parietalSvg, _parietal),
      ...lobe(_occipitalSvg, _occipital),
      ...lobe(_temporalSvg, _temporal),
      ...lobe(_stemSvg, _stem),
      ...lobe(_cerebellumSvg, _cerebellum),
    ], gap: 10),
    ...lay(0.345, 0.42, [
      fold('M118 128 C 136 140 150 130 168 146', _frontal.$2),
      fold('M100 168 C 124 160 142 178 170 172', _frontal.$2),
      fold('M110 200 C 130 192 150 204 178 196', _frontal.$2),
      fold('M182 100 C 192 120 186 140 200 160', _frontal.$2),
      fold('M262 104 C 276 122 296 112 316 130', _parietal.$2),
      fold('M248 160 C 270 150 290 168 318 160', _parietal.$2),
      fold('M342 150 C 352 166 348 186 358 204', _occipital.$2),
      fold('M146 244 C 184 236 226 248 270 236', _temporal.$2),
      fold('M170 262 C 206 256 240 264 290 252', _temporal.$2),
      fold('M302 270 C 322 262 344 262 362 268', _cerebellum.$2),
      fold('M300 282 C 322 276 346 278 366 284', _cerebellum.$2),
      fold('M306 294 C 326 290 346 292 360 296', _cerebellum.$2),
    ], gap: 4),
    ...lay(0.425, 0.58, [
      ...label('Frontal lobe', const Offset(22, 100), const Offset(122, 150), _frontal.$2),
      ...label('Parietal lobe', const Offset(330, 58), const Offset(290, 120), _parietal.$2),
      ...label('Occipital lobe', const Offset(388, 112), const Offset(356, 178), _occipital.$2),
      ...label('Temporal lobe', const Offset(92, 298), const Offset(190, 258), _temporal.$2),
      ...label('Cerebellum', const Offset(386, 300), const Offset(344, 282), _cerebellum.$2),
      ...label('Brain stem', const Offset(168, 350), const Offset(270, 330), _stem.$2),
    ], gap: 12),
    ...lay(0.585, 0.61, [_heading]),
    ...lay(0.612, 0.625, [
      InkLine(
        'M${r.left} ${r.bottom - 10} L${r.right + 4} ${r.bottom - 12}',
        pen: Pen.highlighter,
        color: const Color(0xFFE5DBFF),
        width: 15,
      ),
    ]),
    ...lay(0.63, 0.71, _notes, gap: 10),
  ];
}();

const _cam = Cam([
  (0.0, Offset(210, 200), 1.25),
  (0.34, Offset(230, 215), 1.25),
  (0.43, Offset(320, 200), 1),
  (0.79, Offset(320, 200), 1),
  (0.85, Offset(500, 196), 1.45),
  (0.94, Offset(510, 196), 1.45),
  (0.97, Offset(320, 200), 1),
]);

final searchScene = TourScene(
  duration: const Duration(milliseconds: 10000),
  rest: 0.83,
  build: (context, t) {
    final typed = (_query.length * span(t, 0.72, 0.78, Curves.linear)).floor();
    final found = span(t, 0.79, 0.83);
    final current = t < 0.86 ? 0 : (t < 0.9 ? 1 : 2);
    final searching = t >= 0.715;
    return inkPage(
      context,
      t: t,
      inks: _inks,
      cam: _cam,
      fade: loopFade(t, out: 0.95),
      under: (canvas) {
        if (found <= 0) return;
        // as the editor marks matches: amber, the current one stronger
        for (var i = 0; i < _matches.length; i++) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(_matches[i], const Radius.circular(3)),
            Paint()
              ..color = const Color(0xFFFFC107).withValues(
                alpha: (i == current ? 0.7 : 0.4) * found,
              ),
          );
        }
      },
      toolbar: searching
          ? _SearchBar(
              text: _query.substring(0, typed),
              caret: (t * 14).floor().isEven || typed < _query.length,
              found: found > 0 ? current + 1 : 0,
              total: _matches.length,
            )
          : null,
    );
  },
);

class _SearchBar extends StatelessWidget {
  const new({
    required this.text,
    required this.caret,
    required this.found,
    required this.total,
  });

  final String text;
  final bool caret;
  final int found, total;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Container(
      width: 300,
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.hairline),
        borderRadius: const BorderRadius.all(Radius.circular(BnRadius.dock)),
        boxShadow: BnShadows.floating,
      ),
      child: Row(
        children: [
          Icon(BnIcons.search, size: 16, color: colors.muted),
          const SizedBox(width: 8),
          if (text.isEmpty)
            Text('Search this note', style: BnType.body.copyWith(color: colors.faint))
          else
            Text(text, style: BnType.bodyLarge.copyWith(color: colors.text)),
          if (caret && text.isNotEmpty)
            Container(
              width: 1.5,
              height: 16,
              margin: const EdgeInsets.only(left: 1),
              color: colors.accent,
            ),
          const Spacer(),
          if (found > 0) ...[
            Text(
              '$found of $total',
              style: BnType.caption.copyWith(color: colors.muted),
            ),
            const SizedBox(width: 8),
            Icon(BnIcons.up, size: 16, color: colors.text2),
            const SizedBox(width: 4),
            Icon(BnIcons.down, size: 16, color: colors.text2),
          ],
        ],
      ),
    );
  }
}
