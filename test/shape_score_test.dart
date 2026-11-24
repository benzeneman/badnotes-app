// How often each shape drawn by hand is recognized as what was meant:
// 20 hand-drawn variants of each, shaky, at different speeds, a little
// turned, closed shapes sometimes left 10-15% short. Prints a table and
// keeps a floor under each shape's score.
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/material.dart' show Colors;

import 'package:flutter_test/flutter_test.dart';
import 'package:badnotes/data/tools/shape_recognizer.dart';

typedef _Case = ({
  String name,
  Set<String> expect,
  List<Offset> Function(Random r) path,
  bool closed,
  double floor,
});

List<Offset> _ellipse(
  Offset c,
  double rx,
  double ry,
  double from,
  double to, [
  double tilt = 0,
]) => [
  for (int i = 0; i <= 72; i++)
    () {
      final t = from + (to - from) * i / 72;
      final x = rx * cos(t), y = ry * sin(t);
      return c +
          Offset(x * cos(tilt) - y * sin(tilt), x * sin(tilt) + y * cos(tilt));
    }(),
];

List<Offset> _round(List<Offset> corners, double r) {
  // corners joined by straight sides, each corner rounded over [r]
  final out = <Offset>[corners.first];
  for (int i = 1; i < corners.length - 1; i++) {
    final a = corners[i - 1], b = corners[i], c = corners[i + 1];
    final ab = (b - a) / (b - a).distance, bc = (c - b) / (c - b).distance;
    final rr = min(r, min((b - a).distance, (c - b).distance) / 3);
    final p = b - ab * rr, q = b + bc * rr;
    for (int k = 0; k <= 6; k++) {
      final t = k / 6;
      out.add(Offset.lerp(Offset.lerp(p, b, t)!, Offset.lerp(b, q, t)!, t)!);
    }
  }
  out.add(corners.last);
  return out;
}

/// [shape] as a hand draws it: turned a little, sampled at an uneven
/// speed, with tremor; a closed one starts anywhere and may stop short.
List<Offset> _byHand(List<Offset> shape, Random r, {required bool closed}) {
  // evenly along it, so cutting it short goes by length, not corners
  var pts = <Offset>[shape.first];
  for (int i = 1; i < shape.length; i++) {
    final a = shape[i - 1], b = shape[i];
    final n = max(1, ((b - a).distance / 4).ceil());
    for (int k = 1; k <= n; k++) {
      pts.add(Offset.lerp(a, b, k / n)!);
    }
  }
  if (closed) {
    // start somewhere along it, and maybe stop 10-15% short
    final start = r.nextInt(pts.length);
    pts = [...pts.sublist(start), ...pts.sublist(1, start + 1)];
    if (r.nextDouble() < 0.4) {
      pts = pts.sublist(
        0,
        (pts.length * (0.85 + r.nextDouble() * 0.05)).round(),
      );
    }
  }
  final turn = (r.nextDouble() - 0.5) * 0.2;
  final c = pts.reduce((a, b) => a + b) / pts.length.toDouble();
  final tremor = 0.6 + r.nextDouble() * 1.6;
  final out = <Offset>[];
  for (int i = 0; i < pts.length - 1; i++) {
    final a = pts[i], b = pts[i + 1];
    final step = 1.5 + r.nextDouble() * 4;
    final n = max(1, ((b - a).distance / step).ceil());
    for (int k = 0; k < n; k++) {
      final p = Offset.lerp(a, b, k / n)! - c;
      out.add(
        c +
            Offset(
              p.dx * cos(turn) - p.dy * sin(turn),
              p.dx * sin(turn) + p.dy * cos(turn),
            ) +
            Offset(
              (r.nextDouble() - .5) * tremor,
              (r.nextDouble() - .5) * tremor,
            ),
      );
    }
  }
  out.add(pts.last);
  return out;
}

List<Offset> _regular(int n, double radius, {double start = -pi / 2}) => [
  for (int i = 0; i <= n; i++)
    Offset(150, 150) + Offset.fromDirection(start + 2 * pi * i / n, radius),
];

final _cases = <_Case>[
  // open
  (
    name: 'line',
    expect: {'line'},
    closed: false,
    floor: 0.9,
    path: (r) => [const Offset(0, 0), Offset(200, 30 + r.nextDouble() * 60)],
  ),
  (
    name: 'arrow',
    expect: {'arrow'},
    closed: false,
    floor: 0.8,
    path: (r) => [
      const Offset(0, 100),
      const Offset(220, 100),
      const Offset(185, 75),
      const Offset(220, 100),
      const Offset(185, 125),
    ],
  ),
  (
    name: 'arc, half circle',
    expect: {'arc'},
    closed: false,
    floor: 0.85,
    path: (r) => _ellipse(const Offset(150, 150), 80, 80, pi, 2 * pi),
  ),
  (
    // tall, with sides nearly straight: drawn as a U too
    name: 'arc, tall',
    expect: {'arc', 'u'},
    closed: false,
    floor: 0.8,
    path: (r) => _ellipse(const Offset(150, 150), 45, 100, pi, 2 * pi),
  ),
  (
    name: 'arc, wide',
    expect: {'arc'},
    closed: false,
    floor: 0.8,
    path: (r) => _ellipse(const Offset(150, 150), 110, 50, pi, 2 * pi),
  ),
  (
    // tall, with sides nearly straight: drawn as a U too
    name: 'arc, narrow',
    expect: {'arc', 'u'},
    closed: false,
    floor: 0.7,
    path: (r) => _ellipse(const Offset(150, 150), 28, 90, pi, 2 * pi),
  ),
  (
    name: 'arc, quarter',
    expect: {'arc'},
    closed: false,
    floor: 0.7,
    path: (r) => _ellipse(const Offset(50, 250), 160, 120, -pi / 2, 0),
  ),
  (
    name: 'U',
    expect: {'arc'},
    closed: false,
    floor: 0.8,
    path: (r) => _ellipse(const Offset(150, 100), 70, 90, 0, pi),
  ),
  (
    name: 'U, ends coming in',
    expect: {'arc'},
    closed: false,
    floor: 0.7,
    path: (r) => _ellipse(const Offset(150, 100), 70, 70, -0.6, pi + 0.6),
  ),
  (
    name: 'bracket ⊔, sharp',
    expect: {'bracket'},
    closed: false,
    floor: 0.8,
    path: (r) => [
      const Offset(0, 0),
      const Offset(5, 160),
      const Offset(200, 155),
      const Offset(205, 0),
    ],
  ),
  (
    name: 'bracket ⊔, rounded',
    expect: {'bracket'},
    closed: false,
    floor: 0.8,
    path: (r) => _round([
      const Offset(0, 0),
      const Offset(5, 160),
      const Offset(200, 155),
      const Offset(205, 0),
    ], 18),
  ),
  (
    name: 'bracket [, rounded',
    expect: {'bracket'},
    closed: false,
    floor: 0.8,
    path: (r) => _round([
      const Offset(150, 0),
      const Offset(0, 5),
      const Offset(5, 200),
      const Offset(150, 195),
    ], 16),
  ),
  (
    name: 'U, round corners',
    expect: {'u', 'bracket'},
    closed: false,
    floor: 0.85,
    path: (r) {
      final lean = (r.nextDouble() - 0.3) * 20;
      return _round([
        Offset(-lean * r.nextDouble(), 0),
        const Offset(0, 140),
        const Offset(150, 140),
        Offset(150 + lean, 0),
      ], 20 + r.nextDouble() * 30);
    },
  ),
  (
    name: 'L',
    expect: {'polyline'},
    closed: false,
    floor: 0.8,
    path: (r) => _round([
      const Offset(0, 0),
      const Offset(5, 180),
      const Offset(160, 175),
    ], 10),
  ),
  (
    name: 'zigzag',
    expect: {'polyline'},
    closed: false,
    floor: 0.7,
    path: (r) => [
      for (int i = 0; i <= 4; i++) Offset(i * 50.0, i.isEven ? 0 : 90),
    ],
  ),
  (
    name: 'wave',
    expect: {'curve'},
    closed: false,
    floor: 0.7,
    path: (r) => [
      for (int i = 0; i <= 80; i++) Offset(i * 3.0, 50 * sin(i / 80 * 4 * pi)),
    ],
  ),
  // closed
  (
    name: 'circle',
    expect: {'circle'},
    closed: true,
    floor: 0.9,
    path: (r) => _ellipse(const Offset(150, 150), 90, 90, 0, 2 * pi),
  ),
  (
    name: 'ellipse',
    expect: {'ellipse'},
    closed: true,
    floor: 0.85,
    path: (r) => _ellipse(const Offset(150, 150), 120, 60, 0, 2 * pi),
  ),
  (
    name: 'square',
    expect: {'square', 'rectangle'},
    closed: true,
    floor: 0.85,
    path: (r) => _round([
      const Offset(0, 0),
      const Offset(180, 0),
      const Offset(180, 180),
      const Offset(0, 180),
      const Offset(0, 0),
    ], 8),
  ),
  (
    name: 'rectangle',
    expect: {'rectangle'},
    closed: true,
    floor: 0.85,
    path: (r) => _round([
      const Offset(0, 0),
      const Offset(260, 0),
      const Offset(260, 140),
      const Offset(0, 140),
      const Offset(0, 0),
    ], 8),
  ),
  (
    name: 'triangle',
    expect: {'triangle'},
    closed: true,
    floor: 0.85,
    path: (r) => [
      const Offset(120, 0),
      const Offset(240, 200),
      const Offset(0, 200),
      const Offset(120, 0),
    ],
  ),
  (
    name: 'right triangle',
    expect: {'triangle'},
    closed: true,
    floor: 0.8,
    path: (r) => [
      const Offset(0, 0),
      const Offset(0, 200),
      const Offset(220, 200),
      const Offset(0, 0),
    ],
  ),
  (
    name: 'diamond',
    expect: {'diamond'},
    closed: true,
    floor: 0.8,
    path: (r) => [
      const Offset(120, 0),
      const Offset(220, 150),
      const Offset(120, 300),
      const Offset(20, 150),
      const Offset(120, 0),
    ],
  ),
  (
    name: 'pentagon',
    expect: {'pentagon'},
    closed: true,
    floor: 0.7,
    path: (r) => _regular(5, 110),
  ),
  (
    name: 'hexagon',
    expect: {'hexagon'},
    closed: true,
    floor: 0.7,
    path: (r) => _regular(6, 110, start: 0),
  ),
  (
    name: 'star',
    expect: {'star'},
    closed: true,
    floor: 0.75,
    path: (r) => [
      for (int i = 0; i <= 5; i++)
        Offset(150, 150) + Offset.fromDirection(-pi / 2 + i * 4 * pi / 5, 120),
    ],
  ),
  (
    // drawn fast: tips uneven, angles off, the end crossing past the start
    name: 'star, sloppy',
    expect: {'star'},
    closed: false,
    floor: 0.6,
    path: (r) {
      final tips = [
        for (int i = 0; i <= 5; i++)
          Offset(150, 150) +
              Offset.fromDirection(
                -pi / 2 + i * 4 * pi / 5 + (r.nextDouble() - 0.5) * 0.35,
                95 + r.nextDouble() * 40,
              ),
      ];
      final over = 0.1 + r.nextDouble() * 0.15;
      return [...tips, Offset.lerp(tips[5], tips[1], over)!];
    },
  ),
  (
    name: 'star, sloppy, closed',
    expect: {'star'},
    closed: true,
    floor: 0.6,
    path: (r) => [
      for (int i = 0; i <= 5; i++)
        Offset(150, 150) +
            Offset.fromDirection(
              -pi / 2 + (i % 5) * 4 * pi / 5 + (r.nextDouble() - 0.5) * 0.35,
              95 + r.nextDouble() * 40,
            ),
    ]..last = Offset(150, 150) + Offset.fromDirection(-pi / 2, 120),
  ),
  (
    name: 'heart',
    expect: {'heart'},
    closed: true,
    floor: 0.6,
    path: (r) => [
      for (int i = 0; i <= 80; i++)
        () {
          final t = i / 80 * 2 * pi;
          return const Offset(150, 150) +
              Offset(
                    16 * pow(sin(t), 3).toDouble(),
                    -(13 * cos(t) -
                        5 * cos(2 * t) -
                        2 * cos(3 * t) -
                        cos(4 * t)),
                  ) *
                  7;
        }(),
    ],
  ),
  (
    name: 'parallelogram',
    expect: {'parallelogram'},
    closed: true,
    floor: 0.7,
    path: (r) => [
      const Offset(60, 0),
      const Offset(280, 0),
      const Offset(220, 140),
      const Offset(0, 140),
      const Offset(60, 0),
    ],
  ),
  (
    name: 'trapezoid',
    expect: {'trapezoid'},
    closed: true,
    floor: 0.7,
    path: (r) => [
      const Offset(70, 0),
      const Offset(200, 0),
      const Offset(270, 140),
      const Offset(0, 140),
      const Offset(70, 0),
    ],
  ),
];

void main() {
  test('shapes drawn by hand are recognized as meant', () {
    final lines = <String>[];
    final low = <String>[];
    var total = 0, right = 0;
    for (final c in _cases) {
      final got = <String, int>{};
      var ok = 0;
      for (int seed = 0; seed < 20; seed++) {
        final r = Random(seed * 31 + c.name.length);
        final drawn = _byHand(c.path(r), r, closed: c.closed);
        final name = recognizeShape(drawn)?.name ?? 'ink';
        got[name] = (got[name] ?? 0) + 1;
        if (c.expect.contains(name)) {
          ok++;
        } else if (const String.fromEnvironment('DEBUG') == c.name ||
            (const bool.fromEnvironment('DEBUGALL'))) {
          final gap = (drawn.first - drawn.last).distance;
          // ignore: avoid_print
          print(
            '  miss ${c.name} seed $seed -> $name gap ${gap.toStringAsFixed(0)} n ${drawn.length} ${debugShapeInfo(drawn)}',
          );
        }
      }
      total += 20;
      right += ok;
      lines.add(
        '${c.name.padRight(22)} ${(ok * 5).toString().padLeft(3)}%  $got',
      );
      if (ok / 20 < c.floor) low.add(c.name);
    }
    // ignore: avoid_print
    print(
      '${lines.join('\n')}\nALL ${(right * 100 / total).toStringAsFixed(1)}%',
    );
    expect(low, isEmpty, reason: 'shapes below their floor');
  });

  test('picture of each, drawn and recognized', () async {
    final out = const String.fromEnvironment('SHAPES_PNG');
    if (out.isEmpty) return;
    const cell = 170.0, perRow = 7;
    final rows = (_cases.length / perRow).ceil();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawColor(Colors.white, BlendMode.src);
    for (final (i, c) in _cases.indexed) {
      final r = Random(3 * 31 + c.name.length);
      final drawn = _byHand(c.path(r), r, closed: c.closed);
      final shape = recognizeShape(drawn);
      final all = [...drawn, ...?shape?.points];
      var box = Rect.fromPoints(all.first, all.first);
      for (final p in all) {
        box = box.expandToInclude(Rect.fromPoints(p, p));
      }
      final scale = (cell - 30) / box.longestSide;
      Offset at(Offset p) =>
          Offset((i % perRow) * cell + 15, (i ~/ perRow) * cell + 15) +
          (p - box.topLeft) * scale;
      final pen = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawPoints(ui.PointMode.polygon, [
        for (final p in drawn) at(p),
      ], pen..color = Colors.grey);
      if (shape != null) {
        if (shape.center != null) {
          canvas.drawCircle(
            at(shape.center!),
            shape.radius! * scale,
            pen
              ..color = Colors.blue
              ..strokeWidth = 2,
          );
        } else {
          canvas.drawPoints(
            ui.PointMode.polygon,
            [for (final p in shape.points) at(p)],
            pen
              ..color = Colors.blue
              ..strokeWidth = 2,
          );
        }
      }
      final ok = c.expect.contains(shape?.name ?? 'ink');
      canvas.drawCircle(
        Offset((i % perRow) * cell + 8, (i ~/ perRow) * cell + 8),
        5,
        Paint()..color = ok ? Colors.green : Colors.red,
      );
    }
    final image = await recorder.endRecording().toImage(
      (cell * perRow).round(),
      (cell * rows).round(),
    );
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    File(out).writeAsBytesSync(png!.buffer.asUint8List());
  });
}
