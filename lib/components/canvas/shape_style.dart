import 'dart:math' as math;
import 'dart:ui';

import 'package:fixnum/fixnum.dart';

/// How a shape's outline is drawn.
enum ShapeLine { none, solid, dashed, dotted }

/// What's at one end of a line.
enum ShapeArrow { none, open, filled }

/// Fill, outline and arrowheads of a shape. Plain values, so it can be saved
/// and copied. Strokes without one are drawn as they always were: a solid
/// outline, no fill.
class ShapeStyle {
  const ShapeStyle({
    this.fill,
    this.line = ShapeLine.solid,
    this.rounded = true,
    this.arrowStart = ShapeArrow.none,
    this.arrowEnd = ShapeArrow.none,
  });

  /// The inside's color with its opacity, or null for none.
  final Color? fill;
  final ShapeLine line;
  final bool rounded;
  final ShapeArrow arrowStart, arrowEnd;

  static const plain = ShapeStyle();

  /// How round a rounded shape's right-angled corners are, for a pen of
  /// [size]: wide enough to see at any pen size.
  static double cornerRadius(double size) => math.max(size * 3, 12.0);

  /// How round the corners of a [box] drawn with a pen of [size] are.
  double boxCornerRadius(double size, Rect box) => rounded
      ? math.min(cornerRadius(size), box.shortestSide * 0.45)
      : 0;

  /// [points] as straight lines with each of [corners] (indices into
  /// [points]) rounded off. A right angle is cut back [radius] each way;
  /// sharper corners less (an arrow's tip stays a tip), and never past
  /// half way to the next corner. A [closed] line's last point is its first.
  static Path roundCorners(
    List<Offset> points,
    List<int> corners,
    double radius, {
    required bool closed,
  }) {
    final n = closed ? points.length - 1 : points.length;
    final inner = [
      for (final c in corners)
        if (c >= 0 && c < n && (closed || (c > 0 && c < n - 1))) c,
    ];
    if (n < 3 || radius <= 0 || inner.isEmpty) {
      return Path()..addPolygon(points, false);
    }
    int wrap(int i) => closed ? (i % n + n) % n : i;
    // from corner [c], [d] along the line towards [step]: where it gets to,
    // and the last point passed (c if none)
    (Offset, int) walk(int c, int step, double d) {
      var j = c;
      for (var guard = 0; guard < n; guard++) {
        final k = wrap(j + step);
        if (k < 0 || k >= n) break;
        final gap = (points[k] - points[j]).distance;
        if (gap >= d) {
          final t = gap == 0 ? 0.0 : d / gap;
          return (Offset.lerp(points[j], points[k], t)!, j);
        }
        d -= gap;
        j = k;
      }
      return (points[j], j);
    }

    // each corner: the curve's start, the last point kept before it, the
    // curve's end and the last point it skips
    final cuts = <(Offset, int, Offset, int)?>[];
    for (final (i, c) in inner.indexed) {
      final prev = i > 0 ? inner[i - 1] : (closed ? inner.last : 0);
      final next = i < inner.length - 1
          ? inner[i + 1]
          : (closed ? inner.first : n - 1);
      final into = points[wrap(c - 1)] - points[c];
      final out = points[wrap(c + 1)] - points[c];
      var d = 0.0;
      if (into.distance > 0 && out.distance > 0) {
        var angle = (into.direction - out.direction).abs() % (2 * math.pi);
        angle = math.min(angle, 2 * math.pi - angle);
        d = math.min(
          math.min(radius, radius * math.tan(angle / 2)),
          0.45 *
              math.min(
                (points[c] - points[prev]).distance,
                (points[c] - points[next]).distance,
              ),
        );
      }
      if (d < 0.5) {
        cuts.add(null);
        continue;
      }
      final (a, before) = walk(c, -1, d);
      final (b, after) = walk(c, 1, d);
      cuts.add((a, wrap(before - 1), b, after));
    }

    final path = Path();
    var i = 0;
    // lines to the points from i up to [to], then round corner [k]
    void upTo(int to, int k) {
      for (
        var guard = 0;
        i != wrap(to + 1) && guard < n && (closed || i < n);
        guard++
      ) {
        path.lineTo(points[i].dx, points[i].dy);
        i = wrap(i + 1);
      }
      final c = points[inner[k]];
      if (cuts[k] case (final a, _, final b, final skipped)?) {
        path
          ..lineTo(a.dx, a.dy)
          ..quadraticBezierTo(c.dx, c.dy, b.dx, b.dy);
        i = wrap(skipped + 1);
      } else {
        path.lineTo(c.dx, c.dy);
        i = wrap(inner[k] + 1);
      }
    }

    if (!closed) {
      path.moveTo(points[0].dx, points[0].dy);
      i = 1;
      for (final (k, c) in inner.indexed) {
        upTo(cuts[k]?.$2 ?? c - 1, k);
      }
      for (; i < n; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      return path;
    }
    // closed: start just past the first corner, end by rounding it
    final first = cuts[0];
    final start = first?.$3 ?? points[inner[0]];
    path.moveTo(start.dx, start.dy);
    i = wrap((first?.$4 ?? inner[0]) + 1);
    for (var k = 1; k <= inner.length; k++) {
      final kk = k % inner.length;
      final cut = cuts[kk];
      upTo(cut?.$2 ?? wrap(inner[kk] - 1), kk);
    }
    return path..close();
  }

  bool get isPlain =>
      fill == null &&
      line == ShapeLine.solid &&
      rounded &&
      arrowStart == ShapeArrow.none &&
      arrowEnd == ShapeArrow.none;

  ShapeStyle copyWith({
    Color? Function()? fill,
    ShapeLine? line,
    bool? rounded,
    ShapeArrow? arrowStart,
    ShapeArrow? arrowEnd,
  }) => ShapeStyle(
    fill: fill == null ? this.fill : fill(),
    line: line ?? this.line,
    rounded: rounded ?? this.rounded,
    arrowStart: arrowStart ?? this.arrowStart,
    arrowEnd: arrowEnd ?? this.arrowEnd,
  );

  Map<String, dynamic> toJson() => {
    if (fill != null) 'f': fill!.toARGB32(),
    if (line != ShapeLine.solid) 'l': line.index,
    if (!rounded) 'r': false,
    if (arrowStart != ShapeArrow.none) 'as': arrowStart.index,
    if (arrowEnd != ShapeArrow.none) 'ae': arrowEnd.index,
  };

  static int? _int(Object? value) => switch (value) {
    final int v => v,
    final Int64 v => v.toInt(),
    _ => null,
  };

  static ShapeStyle? fromJson(Object? json) {
    if (json is! Map) return null;
    T pick<T extends Enum>(List<T> values, Object? v, T fallback) {
      final i = _int(v);
      return i != null && i >= 0 && i < values.length ? values[i] : fallback;
    }

    final fill = _int(json['f']);
    return ShapeStyle(
      fill: fill == null ? null : Color(fill),
      line: pick(ShapeLine.values, json['l'], ShapeLine.solid),
      rounded: json['r'] != false,
      arrowStart: pick(ShapeArrow.values, json['as'], ShapeArrow.none),
      arrowEnd: pick(ShapeArrow.values, json['ae'], ShapeArrow.none),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ShapeStyle &&
      other.fill == fill &&
      other.line == line &&
      other.rounded == rounded &&
      other.arrowStart == arrowStart &&
      other.arrowEnd == arrowEnd;

  @override
  int get hashCode => Object.hash(fill, line, rounded, arrowStart, arrowEnd);
}
