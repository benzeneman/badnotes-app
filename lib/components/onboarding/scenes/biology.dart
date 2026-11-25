import 'dart:math';

import 'package:badnotes/components/onboarding/tour_engine.dart';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// DNA replication: a double helix with coloured base pairs
// ---------------------------------------------------------------------------

// Strands: two colours. Bases by the usual convention: adenine green,
// thymine red, guanine amber, cytosine blue.
const _strand1 = Color(0xFF364FC7), _strand2 = Color(0xFFC2255C);
const _bases = {
  'A': Color(0xFF2FB344),
  'T': Color(0xFFF03E3E),
  'G': Color(0xFFF59F00),
  'C': Color(0xFF1C7ED6),
};
const _pairOf = {'A': 'T', 'T': 'A', 'G': 'C', 'C': 'G'};

const _midY = 246.0, _amp = 50.0, _wave = 176.0, _x0 = 66.0, _x1 = 586.0;
double _phase(double x) => 2 * pi * (x - _x0) / _wave;
double _y1(double x) => _midY + _amp * sin(_phase(x));
double _y2(double x) => _midY - _amp * sin(_phase(x));

final _dnaInks = () {
  // strand 1 left to right, strand 2 back the other way (antiparallel)
  final s1 = InkLine(
    plotSvg(_y1, _x0, _x1, step: 6),
    pen: Pen.brush,
    color: _strand1,
    width: 4.2,
  );
  final s2Points = [
    for (var x = _x1; x >= _x0 - 0.1; x -= 6) Offset(x, _y2(x)),
  ];
  final s2 = InkLine(
    smoothSvg(s2Points),
    pen: Pen.brush,
    color: _strand2,
    width: 4.2,
  );

  // base pairs, each half in its base's colour, a gap for the H-bonds
  const sequence = 'ATGCGTACCTAGGCATTGACGTCAGTTACGGATC';
  final rungs = <InkLine>[];
  var k = 0;
  for (var x = _x0 + 8; x < _x1 - 4; x += 13) {
    final half = (_y1(x) - _midY).abs();
    if (half < 12) continue;
    final top = min(_y1(x), _y2(x)), bottom = max(_y1(x), _y2(x));
    final base = sequence[k++ % sequence.length];
    String v(double a, double b) =>
        'M${x.toStringAsFixed(1)} ${a.toStringAsFixed(1)} '
        'L${x.toStringAsFixed(1)} ${b.toStringAsFixed(1)}';
    rungs
      ..add(
        InkLine(
          v(top + 5, _midY - 1.6),
          pen: Pen.ballpoint,
          color: _bases[base]!,
          width: 3.4,
        ),
      )
      ..add(
        InkLine(
          v(_midY + 1.6, bottom - 5),
          pen: Pen.ballpoint,
          color: _bases[_pairOf[base]]!,
          width: 3.4,
        ),
      );
  }

  final dna = InkText(
    'DNA',
    at: const Offset(34, 54),
    color: const Color(0xFFE03E52),
    size: 46,
    font: 'Kalam',
    weight: FontWeight.w700,
    pen: Pen.fountain,
  );
  final repl = InkText(
    'Replication',
    at: const Offset(136, 64),
    color: const Color(0xFF1E3A8A),
    size: 36,
    font: 'Kalam',
    weight: FontWeight.w700,
    pen: Pen.fountain,
  );
  final mark = repl.rectOf('Replication');
  final highlight = InkLine(
    'M${mark.left - 2} ${mark.bottom - 12} L${mark.right + 4} ${mark.bottom - 14}',
    pen: Pen.highlighter,
    color: const Color(0xFFFFD43B),
    width: 17,
  );

  // a base pair and the backbone, pointed at
  final pairX = rungs[rungs.length - 9].tipAt(0).dx;
  final ends = <Drawn>[
    InkText("5'", at: const Offset(40, 214), color: _strand1, size: 22, font: 'Caveat'),
    InkText("3'", at: const Offset(40, 254), color: _strand2, size: 22, font: 'Caveat'),
    InkText("3'", at: const Offset(596, 214), color: _strand1, size: 22, font: 'Caveat'),
    InkText("5'", at: const Offset(596, 254), color: _strand2, size: 22, font: 'Caveat'),
  ];
  final notes = <Drawn>[
    ...label(
      'base pair',
      const Offset(470, 128),
      Offset(pairX, _midY - 14),
      const Color(0xFFF59F00),
      size: 18,
    ),
    ...label(
      'sugar-phosphate backbone',
      const Offset(392, 322),
      Offset(368, _y2(368) + 5),
      _strand2,
      size: 17,
    ),
  ];
  // the pairing rule, letters in their own colours
  Drawn letter(String s, double x, double y) => InkText(
    s,
    at: Offset(x, y),
    color: _bases[s] ?? const Color(0xFF495057),
    size: 24,
    font: 'Kalam',
    weight: FontWeight.w700,
  );
  final legend = <Drawn>[
    letter('A', 44, 318),
    InkText('=', at: const Offset(66, 320), color: const Color(0xFF495057), size: 22),
    letter('T', 84, 318),
    InkText('2 H-bonds', at: const Offset(110, 324), color: const Color(0xFF6B7280), size: 15),
    letter('G', 44, 350),
    InkText('=', at: const Offset(66, 352), color: const Color(0xFF495057), size: 22),
    letter('C', 84, 350),
    InkText('3 H-bonds', at: const Offset(110, 356), color: const Color(0xFF6B7280), size: 15),
  ];

  return <Drawn>[
    ...lay(0.05, 0.21, [s1]),
    ...lay(0.215, 0.35, [s2]),
    ...lay(0.36, 0.55, rungs, gap: 4),
    ...lay(0.57, 0.69, [dna, repl], gap: 30),
    ...lay(0.695, 0.735, [highlight]),
    ...lay(0.745, 0.91, [...ends, ...notes, ...legend], gap: 18),
  ];
}();

const _dnaCam = Cam([
  (0.0, Offset(150, 246), 1.55),
  (0.05, Offset(160, 246), 1.55),
  (0.21, Offset(480, 246), 1.55),
  (0.35, Offset(170, 246), 1.45),
  (0.55, Offset(420, 240), 1.2),
  (0.6, Offset(320, 200), 1),
  (0.9, Offset(320, 200), 1.03),
]);

final dnaScene = TourScene(
  duration: const Duration(milliseconds: 9500),
  rest: 0.92,
  build: (context, t) =>
      inkPage(context, t: t, inks: _dnaInks, cam: _dnaCam),
);

// ---------------------------------------------------------------------------
// The neuron: dendrites, soma, nucleus, myelinated axon, terminals
// ---------------------------------------------------------------------------

const _nerve = Color(0xFF1971C2);
const _somaFill = Color(0xFFA5D8FF);
const _nucleus = Color(0xFF9775FA), _nucleusLine = Color(0xFF6741D9);
const _myelin = Color(0xFFFFC078), _myelinLine = Color(0xFFE8590C);
const _knob = Color(0xFFF783AC);

const _axonSvg = 'M226 232 C 300 224 380 246 520 236';

final _neuronInks = () {
  InkLine dendrite(String d, [double w = 2.6]) =>
      InkLine(d, pen: Pen.fountain, color: _nerve, width: w);
  final dendrites = [
    dendrite('M162 202 C 140 180 120 168 96 150'),
    dendrite('M120 168 C 112 150 110 135 112 116', 2.1),
    dendrite('M96 150 C 82 146 70 140 58 126', 1.8),
    dendrite('M96 150 C 86 160 72 162 58 166', 1.8),
    dendrite('M150 222 C 126 222 104 226 80 232'),
    dendrite('M104 226 C 92 214 80 206 64 202', 1.9),
    dendrite('M80 232 C 70 240 60 248 48 252', 1.8),
    dendrite('M160 252 C 140 272 124 290 108 312'),
    dendrite('M124 290 C 108 290 94 296 80 302', 1.9),
    dendrite('M108 312 C 104 326 100 338 92 352', 1.8),
    dendrite('M182 194 C 176 170 172 150 176 124'),
    dendrite('M176 150 C 190 138 196 126 200 112', 1.9),
    dendrite('M198 262 C 202 285 198 305 188 326'),
    dendrite('M199 290 C 212 300 220 314 222 330', 1.8),
  ];
  const somaSvg =
      'M160 200 C 172 186 196 184 210 196 C 224 206 230 222 226 238 '
      'C 222 254 204 264 186 262 C 166 260 150 248 148 230 '
      'C 146 218 150 208 160 200 Z';
  final soma = [
    InkFill(somaSvg, color: _somaFill),
    InkLine(somaSvg, pen: Pen.fountain, color: _nerve, width: 2.4),
    InkFill(circleSvg(const Offset(188, 226), 12.5), color: _nucleus),
    InkLine(
      circleSvg(const Offset(188, 226), 12.5),
      pen: Pen.fineliner,
      color: _nucleusLine,
      width: 1.6,
    ),
    InkFill(circleSvg(const Offset(191, 223), 3.6), color: _nucleusLine),
  ];
  final axon = InkLine(_axonSvg, pen: Pen.brush, color: _nerve, width: 3.2);

  // the sheath: capsules on the axon, gaps between them (nodes of Ranvier)
  final along = axon.points();
  double axonY(double x) =>
      along.reduce((a, b) => (a.dx - x).abs() < (b.dx - x).abs() ? a : b).dy;
  final myelin = <Drawn>[];
  for (final x in [262.0, 312.0, 362.0, 412.0, 462.0]) {
    final y = axonY(x);
    final d =
        'M${x - 12} ${y - 8.5} L${x + 12} ${y - 8.5} '
        'A8.5 8.5 0 0 1 ${x + 12} ${y + 8.5} L${x - 12} ${y + 8.5} '
        'A8.5 8.5 0 0 1 ${x - 12} ${y - 8.5} Z';
    myelin
      ..add(InkFill(d, color: _myelin))
      ..add(InkLine(d, pen: Pen.fineliner, color: _myelinLine, width: 1.6));
  }

  final terminals = <Drawn>[
    InkLine('M520 236 C 545 230 560 214 575 200', color: _nerve, width: 2.3),
    InkLine('M520 236 C 548 236 566 238 588 240', color: _nerve, width: 2.3),
    InkLine('M520 236 C 545 244 558 262 572 276', color: _nerve, width: 2.3),
    InkFill(circleSvg(const Offset(577, 198), 6), color: _knob),
    InkFill(circleSvg(const Offset(591, 240), 6), color: _knob),
    InkFill(circleSvg(const Offset(574, 279), 6), color: _knob),
  ];

  final labels = <Drawn>[
    ...label('Dendrites', const Offset(28, 86), const Offset(108, 138), _nerve, size: 18),
    ...label('Nucleus', const Offset(246, 160), const Offset(196, 220), _nucleusLine, size: 18),
    ...label('Soma', const Offset(240, 286), const Offset(214, 252), _nerve, size: 18),
    ...label('Myelin sheath', const Offset(318, 178), const Offset(362, 222), _myelinLine, size: 18),
    ...label('Axon', const Offset(300, 270), const Offset(337, 240), _nerve, size: 18),
    ...label('Node of Ranvier', const Offset(400, 296), const Offset(437, 241), _myelinLine, size: 17),
    ...label('Axon terminals', const Offset(500, 318), const Offset(572, 286), const Color(0xFFD6336C), size: 17),
  ];

  final heading = InkText(
    'Neuron',
    at: const Offset(452, 60),
    color: _nerve,
    size: 40,
    font: 'Kalam',
    weight: FontWeight.w700,
    pen: Pen.fountain,
  );
  final r = heading.rectOf('Neuron');
  final mark = InkLine(
    'M${r.left} ${r.bottom - 11} L${r.right + 4} ${r.bottom - 13}',
    pen: Pen.highlighter,
    color: const Color(0xFFFCC2D7),
    width: 16,
  );
  final sub = InkText(
    'nerve cell',
    at: const Offset(466, 106),
    color: const Color(0xFF6B7280),
    size: 22,
    font: 'Caveat',
  );

  return <Drawn>[
    ...lay(0.04, 0.2, dendrites, gap: 10),
    ...lay(0.2, 0.3, soma, gap: 10),
    ...lay(0.3, 0.355, [axon]),
    ...lay(0.36, 0.49, myelin, gap: 6),
    ...lay(0.5, 0.58, terminals, gap: 8),
    ...lay(0.6, 0.83, labels, gap: 14),
    ...lay(0.84, 0.885, [heading]),
    ...lay(0.888, 0.91, [mark]),
    ...lay(0.912, 0.93, [sub]),
  ];
}();

const _neuronCam = Cam([
  (0.0, Offset(150, 226), 1.6),
  (0.2, Offset(170, 226), 1.6),
  (0.3, Offset(230, 230), 1.5),
  (0.49, Offset(440, 236), 1.45),
  (0.58, Offset(500, 240), 1.35),
  (0.62, Offset(320, 200), 1),
]);

final neuronScene = TourScene(
  duration: const Duration(milliseconds: 10500),
  rest: 0.95,
  build: (context, t) => inkPage(
    context,
    t: t,
    inks: _neuronInks,
    cam: _neuronCam,
    fade: loopFade(t, out: 0.955),
  ),
);
