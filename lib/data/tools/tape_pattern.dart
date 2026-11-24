import 'dart:math';

import 'package:flutter/material.dart';

/// The designs printed along a tape. Stamped along the tape's center line, so
/// they follow a freehand tape around its curves.
enum TapePattern {
  plain,
  stripes,
  dots,
  chevrons,
  checks,
  hearts,
  stars,
  waves,
  zigzag,
  plaid,
  polka,
  flowers,
  moons,
  triangles,
  washi,
  grid,
  confetti,

  /// The user's own doodle, kept on each stroke (see [parseDoodle]).
  custom;

  /// A doodle as its lines, each a list of points from -0.5 to 0.5 across
  /// a square. Saved as "x,y x,y;x,y x,y".
  static List<List<Offset>> parseDoodle(String? doodle) => [
    for (final line in (doodle ?? '').split(';'))
      [
        for (final point in line.trim().split(' '))
          if (point.split(',') case [final xs, final ys])
            if ((double.tryParse(xs), double.tryParse(ys)) case (
              final x?,
              final y?,
            ))
              Offset(x, y),
      ],
  ]..removeWhere((line) => line.isEmpty);

  static String encodeDoodle(List<List<Offset>> lines) => [
    for (final line in lines)
      [
        for (final p in line)
          '${p.dx.toStringAsFixed(3)},${p.dy.toStringAsFixed(3)}',
      ].join(' '),
  ].join(';');

  double _spacing(double width) => switch (this) {
    .plain => width,
    .stripes => width * 0.7,
    .dots => width * 0.55,
    .chevrons => width * 0.6,
    .checks => width * 0.5,
    .hearts => width * 0.95,
    .stars => width * 0.95,
    .waves => width * 0.8,
    .zigzag => width * 0.5,
    .plaid => width,
    .polka => width * 0.75,
    .flowers => width * 1.05,
    .moons => width * 0.95,
    .triangles => width * 0.6,
    .washi => width,
    .grid => width / 3,
    .confetti => width * 0.4,
    .custom => width * 1.1,
  };

  /// How far a stamp reaches along the tape from its middle.
  double _reach(double width, double spacing) => switch (this) {
    .plain => 0,
    .stripes => spacing * 0.25 + width * 0.25,
    .dots => width * 0.12,
    .chevrons => spacing * 0.52,
    .checks => spacing / 2,
    .hearts => width * 0.26,
    .stars => width * 0.3,
    .waves || .zigzag || .plaid || .washi || .grid => spacing / 2,
    .polka => width * 0.2,
    .flowers => width * 0.32,
    .moons => width * 0.26,
    .triangles => spacing * 0.42,
    .confetti => width * 0.1,
    .custom => width * 0.45,
  };

  /// All the stamps along [line] on a tape of [width], as one path to fill.
  /// Whole stamps only, evenly centered: one past the tape's end would stick
  /// out of it.
  /// A doodle's stamp for a tape 1 wide, made once and kept: building it
  /// afresh for every stamp of every frame (a band and two rounds for each
  /// bit of each line) is what made a tape with a doodle lag.
  static final _doodleStamps = <String, Path>{};

  static Path _doodleStamp(String doodle) => _doodleStamps[doodle] ??= () {
    // points closer than this are one: a finger's doodle has hundreds
    const near = 0.02;
    final lines = [
      for (final line in parseDoodle(doodle))
        [
          for (final (i, p) in line.indexed)
            if (i == 0 ||
                i == line.length - 1 ||
                (p - line[i - 1]).distance >= near)
              p,
        ],
    ];
    final unit = Path();
    TapePattern.custom._stamp(unit, Offset.zero, const Offset(1, 0), 1, 1.1, 0, lines);
    return unit;
  }();

  Path stamps(Path line, double width, {String? doodle}) {
    const lines = <List<Offset>>[];
    final unit = this == .custom && doodle != null && doodle.isNotEmpty
        ? _doodleStamp(doodle)
        : null;
    final out = Path();
    if (this == .custom && unit == null) return out;
    if (this == .plain) return out;
    final spacing = _spacing(width);
    for (final metric in line.computeMetrics()) {
      final reach = _reach(width, spacing);
      final room = metric.length - 2 * reach;
      if (room < 0) continue;
      final extra = room % spacing;
      var index = 0;
      for (
        var at = reach + extra / 2;
        at <= metric.length - reach;
        at += spacing
      ) {
        final tangent = metric.getTangentForOffset(at);
        if (tangent != null && unit != null) {
          // the doodle's stamp, turned along the tape and sized to it
          final v = tangent.vector;
          out.addPath(
            unit,
            Offset.zero,
            matrix4: (Matrix4.identity()
                  ..translateByDouble(
                    tangent.position.dx,
                    tangent.position.dy,
                    0,
                    1,
                  )
                  ..rotateZ(atan2(v.dy, v.dx))
                  ..scaleByDouble(width, width, 1, 1))
                .storage,
          );
        } else if (tangent != null) {
          _stamp(
            out,
            tangent.position,
            tangent.vector,
            width,
            spacing,
            index,
            lines,
          );
        }
        index++;
      }
    }
    return out;
  }

  void _stamp(
    Path out,
    Offset position,
    Offset along,
    double width,
    double spacing,
    int index,
    List<List<Offset>> doodle,
  ) {
    final across = Offset(-along.dy, along.dx);
    Offset at(double a, double b) => position + along * a + across * b;
    final half = width / 2;
    // all turned one way, so where they overlap they add up, not cancel
    void polygon(List<Offset> points) {
      var area = 0.0;
      for (var i = 0; i < points.length; i++) {
        final p = points[i], q = points[(i + 1) % points.length];
        area += p.dx * q.dy - q.dx * p.dy;
      }
      out.addPolygon(area < 0 ? points.reversed.toList() : points, true);
    }

    void circle(double a, double b, double r) => polygon([
      for (var i = 0; i < 14; i++)
        at(a + r * cos(i * pi / 7), b + r * sin(i * pi / 7)),
    ]);

    /// A band of [thick] from (a1, b1) to (a2, b2), round at the ends.
    void band(double a1, double b1, double a2, double b2, double thick) {
      final d = Offset(a2 - a1, b2 - b1);
      if (d.distance == 0) return circle(a1, b1, thick / 2);
      final n = Offset(-d.dy, d.dx) / d.distance * (thick / 2);
      polygon([
        at(a1 + n.dx, b1 + n.dy),
        at(a2 + n.dx, b2 + n.dy),
        at(a2 - n.dx, b2 - n.dy),
        at(a1 - n.dx, b1 - n.dy),
      ]);
      circle(a1, b1, thick / 2);
      circle(a2, b2, thick / 2);
    }

    switch (this) {
      case .plain:
        break;
      case .stripes:
        final band = spacing * 0.25;
        polygon([
          at(-band - half * 0.5, half),
          at(band - half * 0.5, half),
          at(band + half * 0.5, -half),
          at(-band + half * 0.5, -half),
        ]);
      case .dots:
        final b = (index.isEven ? 1 : -1) * width * 0.22;
        out.addOval(Rect.fromCircle(center: at(0, b), radius: width * 0.12));
      case .chevrons:
        final thick = spacing * 0.22;
        final tip = spacing * 0.3;
        polygon([
          at(-tip - thick, -half),
          at(tip - thick, 0),
          at(-tip - thick, half),
          at(-tip + thick, half),
          at(tip + thick, 0),
          at(-tip + thick, -half),
        ]);
      case .checks:
        final s = spacing / 2;
        for (final row in const [-1.5, -0.5, 0.5]) {
          final cell = (row * 2 + index).round().isEven;
          if (!cell) continue;
          final top = row * width / 3;
          polygon([
            at(-s, top),
            at(s, top),
            at(s, top + width / 3),
            at(-s, top + width / 3),
          ]);
        }
      case .hearts:
        final r = width * 0.26;
        out.moveTo(at(-r, 0).dx, at(-r, 0).dy);
        void curve(Offset a, Offset b, Offset c) =>
            out.cubicTo(a.dx, a.dy, b.dx, b.dy, c.dx, c.dy);
        // the point of the heart faces across the tape
        curve(at(-r, -r * 0.9), at(-r * 0.1, -r), at(0, -r * 0.35));
        curve(at(r * 0.1, -r), at(r, -r * 0.9), at(r, 0));
        curve(at(r, r * 0.55), at(r * 0.25, r * 0.9), at(0, r * 1.15));
        curve(at(-r * 0.25, r * 0.9), at(-r, r * 0.55), at(-r, 0));
        out.close();
      case .stars:
        final outer = width * 0.3;
        polygon([
          for (var i = 0; i < 10; i++)
            () {
              final radius = i.isEven ? outer : outer * 0.45;
              final angle = -pi / 2 + i * pi / 5;
              return at(radius * cos(angle), radius * sin(angle));
            }(),
        ]);
      case .waves:
        // half a wave each, one up and one down, joined into a ribbon
        final s = spacing / 2;
        final up = index.isEven ? 1.0 : -1.0;
        for (var i = 0; i < 6; i++) {
          final a1 = -s + i * spacing / 6, a2 = -s + (i + 1) * spacing / 6;
          double b(double a) => up * sin((a + s) / spacing * pi) * width * 0.18;
          band(a1, b(a1), a2, b(a2), width * 0.09);
        }
      case .zigzag:
        final s = spacing / 2;
        final b = width * 0.2 * (index.isEven ? 1 : -1);
        band(-s, -b, s, b, width * 0.09);
      case .plaid:
        final s = spacing / 2;
        polygon([at(-s, -half * 0.15), at(s, -half * 0.15), at(s, half * 0.15), at(-s, half * 0.15)]);
        polygon([at(-s * 0.15, -half), at(s * 0.15, -half), at(s * 0.15, half), at(-s * 0.15, half)]);
        for (final b in const [-0.6, 0.6]) {
          polygon([at(-s, half * (b - 0.04)), at(s, half * (b - 0.04)), at(s, half * (b + 0.04)), at(-s, half * (b + 0.04))]);
        }
      case .polka:
        circle(0, (index.isEven ? -1 : 1) * width * 0.18, width * 0.17);
      case .flowers:
        final r = width * 0.11;
        for (var i = 0; i < 5; i++) {
          final angle = i * 2 * pi / 5 + index;
          circle(cos(angle) * r * 1.6, sin(angle) * r * 1.6, r);
        }
      case .moons:
        // a crescent: a round, with a bite out of it, as one outline
        final r = width * 0.24;
        polygon([
          for (var i = 0; i <= 16; i++)
            () {
              final angle = -pi / 2 + i * pi / 16;
              return at(r * cos(angle), r * sin(angle));
            }(),
          for (var i = 16; i >= 0; i--)
            () {
              final angle = -pi / 2 + i * pi / 16;
              return at(r * 0.45 * cos(angle), r * sin(angle));
            }(),
        ]);
      case .triangles:
        final s = spacing * 0.42;
        final flip = index.isEven ? 1.0 : -1.0;
        polygon([at(-s, half * 0.55 * flip), at(s, half * 0.55 * flip), at(0, -half * 0.55 * flip)]);
      case .washi:
        final s = spacing / 2;
        for (final b in const [-0.62, -0.45, 0.45, 0.62]) {
          polygon([at(-s, half * (b - 0.05)), at(s, half * (b - 0.05)), at(s, half * (b + 0.05)), at(-s, half * (b + 0.05))]);
        }
      case .grid:
        final s = spacing / 2;
        polygon([at(-s * 0.12, -half), at(s * 0.12, -half), at(s * 0.12, half), at(-s * 0.12, half)]);
        for (final b in const [-1 / 3, 1 / 3]) {
          polygon([at(-s, half * b - s * 0.12), at(s, half * b - s * 0.12), at(s, half * b + s * 0.12), at(-s, half * b + s * 0.12)]);
        }
      case .confetti:
        // scattered, but the same on every redraw: picked by the index
        final b = ((index * 37) % 7 / 6 - 0.5) * width * 0.6;
        final tilt = index * 1.3;
        final r = width * 0.07;
        polygon([
          for (final (x, y) in const [(-1.0, -0.4), (1.0, -0.4), (1.0, 0.4), (-1.0, 0.4)])
            at(r * (x * cos(tilt) - y * sin(tilt)), b + r * (x * sin(tilt) + y * cos(tilt))),
        ]);
      case .custom:
        final scale = width * 0.85;
        for (final line in doodle) {
          if (line.length == 1) circle(line.first.dx * scale, line.first.dy * scale, width * 0.045);
          for (var i = 0; i + 1 < line.length; i++) {
            band(
              line[i].dx * scale,
              line[i].dy * scale,
              line[i + 1].dx * scale,
              line[i + 1].dy * scale,
              width * 0.09,
            );
          }
        }
    }
  }
}
