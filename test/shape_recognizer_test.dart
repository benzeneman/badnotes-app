import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:badnotes/data/tools/shape_recognizer.dart';

/// A shaky hand tracing the sides between [corners].
List<Offset> _drawn(List<Offset> corners, {int seed = 1, double shake = 3}) {
  final random = Random(seed);
  final points = <Offset>[];
  for (int i = 1; i < corners.length; i++) {
    for (int k = 0; k < 20; k++) {
      final p = Offset.lerp(corners[i - 1], corners[i], k / 20)!;
      points.add(
        p + Offset(random.nextDouble() * shake, random.nextDouble() * shake),
      );
    }
  }
  return points..add(corners.last);
}

List<Offset> _regular(int corners, {double start = -pi / 2, int skip = 1}) => [
  for (int i = 0; i <= corners; i++)
    const Offset(200, 200) +
        Offset.fromDirection(start + i * skip * 2 * pi / corners, 150),
];

void main() {
  void expectShape(List<Offset> corners, String name) {
    for (int seed = 0; seed < 10; seed++) {
      expect(recognizeShape(_drawn(corners, seed: seed))?.name, name);
    }
  }

  test('line', () => expectShape(const [Offset.zero, Offset(300, 90)], 'line'));
  test('arrow', () {
    expectShape(const [
      Offset.zero,
      Offset(300, 0),
      Offset(240, 40),
      Offset(300, 0),
      Offset(240, -40),
    ], 'arrow');
  });
  test('corner', () {
    expectShape(const [
      Offset.zero,
      Offset(0, 300),
      Offset(200, 300),
    ], 'polyline');
  });
  test('circle', () => expectShape(_regular(48), 'circle'));
  test('triangle', () => expectShape(_regular(3), 'triangle'));
  test('square', () {
    expectShape(const [
      Offset.zero,
      Offset(300, 0),
      Offset(300, 300),
      Offset(0, 300),
      Offset.zero,
    ], 'square');
  });
  test('rectangle', () {
    expectShape(const [
      Offset.zero,
      Offset(300, 0),
      Offset(300, 150),
      Offset(0, 150),
      Offset.zero,
    ], 'rectangle');
  });
  test('diamond', () {
    expectShape(const [
      Offset(150, 0),
      Offset(300, 200),
      Offset(150, 400),
      Offset(0, 200),
      Offset(150, 0),
    ], 'diamond');
  });
  test('oval', () {
    expectShape([
      for (int i = 0; i <= 48; i++)
        Offset(
          200 + 180 * cos(i / 48 * 2 * pi),
          200 + 80 * sin(i / 48 * 2 * pi),
        ),
    ], 'ellipse');
  });
  test('pentagon', () => expectShape(_regular(5), 'pentagon'));
  test('hexagon', () => expectShape(_regular(6), 'hexagon'));
  test('star', () => expectShape(_regular(5, skip: 2), 'star'));
  test('star drawn round its outline', () {
    expectShape([
      for (int i = 0; i <= 10; i++)
        const Offset(200, 200) +
            Offset.fromDirection(-pi / 2 + i * pi / 5, i.isEven ? 150 : 60),
    ], 'star');
  });
  test('a wobbly circle stays a circle', () {
    expectShape(_regular(48), 'circle');
  });
  test('arc', () {
    for (final sweep in [60, 120, 200]) {
      final arc = [
        for (int i = 0; i <= 12; i++)
          const Offset(200, 200) +
              Offset.fromDirection(pi + i / 12 * sweep * pi / 180, 150),
      ];
      final shape = recognizeShape(_drawn(arc, shake: 2));
      expect(shape?.name, 'arc', reason: '$sweep degrees');
      // smooth: many short steps, not a few long pieces
      expect(shape!.points.length, greaterThan(8));
    }
  });
  test('a quick diamond with few points', () {
    final points = [
      for (final (x, y) in [
        (700, 200),
        (748, 252),
        (790, 300),
        (743, 351),
        (700, 400),
        (652, 348),
        (612, 300),
        (658, 247),
        (698, 203),
      ])
        Offset(x.toDouble(), y.toDouble()),
    ];
    expect(recognizeShape(points)?.name, 'diamond');
  });
  test('a U is a curve, not a box', () {
    // straight sides and a round bottom: not one circle
    final u = [
      const Offset(100, 0),
      const Offset(100, 200),
      for (int i = 1; i < 12; i++)
        const Offset(200, 200) + Offset.fromDirection(pi - i / 12 * pi, 100),
      const Offset(300, 200),
      const Offset(300, 0),
    ];
    for (int seed = 0; seed < 10; seed++) {
      final shape = recognizeShape(_drawn(u, seed: seed, shake: 2));
      expect(shape?.name, anyOf('u', 'curve', 'arc'), reason: 'seed $seed');
    }
  });
  test('a U with round corners and a leaning arm: upright parallel arms', () {
    // as drawn in the video: corners rounded off, the right arm leaning out
    final u = [
      const Offset(100, 0),
      const Offset(100, 150),
      for (int i = 1; i < 6; i++)
        const Offset(130, 150) +
            Offset.fromDirection(pi - i / 6 * pi / 2, 30) +
            const Offset(0, 0),
      const Offset(130, 180),
      const Offset(220, 180),
      for (int i = 1; i < 6; i++)
        const Offset(220, 150) +
            Offset.fromDirection(pi / 2 - i / 6 * pi / 2, 30),
      const Offset(250, 150),
      const Offset(262, 0),
    ];
    for (int seed = 0; seed < 10; seed++) {
      final shape = recognizeShape(_drawn(u, seed: seed, shake: 2));
      expect(shape?.name, 'u', reason: 'seed $seed');
      final p = shape!.points;
      // both arms upright
      expect((p.first.dx - p[1].dx).abs(), lessThan(1), reason: 'seed $seed');
      expect(
        (p.last.dx - p[p.length - 2].dx).abs(),
        lessThan(1),
        reason: 'seed $seed',
      );
    }
  });
  test('a wave is a curve', () {
    final wave = [
      for (int i = 0; i <= 24; i++) Offset(i * 15.0, 60 * sin(i / 24 * 2 * pi)),
    ];
    expect(recognizeShape(_drawn(wave, shake: 2))?.name, 'curve');
  });
  test('a zigzag keeps its corners', () {
    expectShape(const [
      Offset.zero,
      Offset(100, 200),
      Offset(200, 0),
      Offset(300, 200),
    ], 'polyline');
  });
  test('parallelogram', () {
    expectShape(const [
      Offset(100, 0),
      Offset(400, 0),
      Offset(300, 200),
      Offset(0, 200),
      Offset(100, 0),
    ], 'parallelogram');
  });
  test('trapezoid', () {
    expectShape(const [
      Offset(100, 0),
      Offset(300, 0),
      Offset(400, 200),
      Offset(0, 200),
      Offset(100, 0),
    ], 'trapezoid');
  });
  group('drawn quickly by hand', () {
    // rounded corners, uneven arms, a tilt, and the pen going on past where
    // it started
    List<Offset> rounded(List<Offset> corners, int seed, {double shake = 8}) {
      final random = Random(seed);
      var points = _drawn(corners, seed: seed, shake: shake);
      points.add(
        corners.last +
            Offset(random.nextDouble() * 15, random.nextDouble() * 15),
      );
      for (int k = 0; k < 1 + seed % 3; k++) {
        points = [
          points.first,
          for (int i = 0; i < points.length - 1; i++) ...[
            Offset.lerp(points[i], points[i + 1], 0.25)!,
            Offset.lerp(points[i], points[i + 1], 0.75)!,
          ],
          points.last,
        ];
      }
      return points;
    }

    List<Offset> uneven(List<Offset> corners, int seed) {
      const c = Offset(200, 200);
      final random = Random(seed * 7);
      final tilt = (random.nextDouble() - 0.5) * 0.5;
      final out = [
        for (final p in corners)
          c +
              Offset.fromDirection(
                (p - c).direction + tilt,
                (p - c).distance * (0.75 + random.nextDouble() * 0.5),
              ),
      ];
      return out
        ..add(Offset.lerp(out[0], out[1], 0.15 + random.nextDouble() * 0.2)!);
    }

    test('a star through its points is a star, not an oval', () {
      for (int seed = 0; seed < 24; seed++) {
        final shape = recognizeShape(
          rounded(uneven(_regular(5, skip: 2), seed), seed),
        );
        expect(shape?.name, 'star', reason: 'seed $seed');
      }
    });
    test('a star round its outline is a star', () {
      final outline = [
        for (int i = 0; i <= 10; i++)
          const Offset(200, 200) +
              Offset.fromDirection(-pi / 2 + i * pi / 5, i.isEven ? 150 : 60),
      ];
      for (int seed = 0; seed < 24; seed++) {
        final shape = recognizeShape(rounded(uneven(outline, seed), seed));
        expect(shape?.name, 'star', reason: 'seed $seed');
      }
    });
    test('a heart is a heart', () {
      var hearts = 0;
      for (int seed = 0; seed < 24; seed++) {
        final random = Random(seed);
        final tilt = (random.nextDouble() - 0.5) * 0.6;
        final squash = 0.8 + random.nextDouble() * 0.4;
        var heart = [
          for (int i = 0; i <= 60; i++)
            () {
              final t = i / 60 * 2 * pi;
              final p =
                  Offset(
                    16 * pow(sin(t), 3).toDouble(),
                    -(13 * cos(t) -
                        5 * cos(2 * t) -
                        2 * cos(3 * t) -
                        cos(4 * t)),
                  ) *
                  8;
              return const Offset(200, 200) +
                  Offset.fromDirection(
                    p.direction + tilt,
                    p.distance,
                  ).scale(squash, 1);
            }(),
        ];
        // started anywhere round it
        final start = random.nextInt(heart.length - 1);
        heart = [...heart.sublist(start), ...heart.sublist(1, start + 1)];
        final points = [
          for (int i = 0; i < heart.length; i += 2) heart[i],
          heart.last,
        ];
        if (recognizeShape(rounded(points, seed, shake: 6))?.name == 'heart')
          hearts++;
      }
      expect(hearts, greaterThanOrEqualTo(22));
    });
    test('wobbly ovals stay ovals', () {
      for (int seed = 0; seed < 24; seed++) {
        final random = Random(seed);
        final a = 100 + random.nextDouble() * 80,
            b = 100 + random.nextDouble() * 80;
        final oval = [
          for (int i = 0; i <= 20; i++)
            Offset(
              200 + cos(i / 20 * 2 * pi) * a,
              200 + sin(i / 20 * 2 * pi) * b,
            ),
        ];
        expect(
          recognizeShape(rounded(oval, seed))?.name,
          anyOf('circle', 'ellipse'),
          reason: 'seed $seed',
        );
      }
    });
  });
}
