import 'dart:math';
import 'dart:ui';

/// What a hand-drawn line turned out to be.
class RecognizedShape {
  const RecognizedShape(this.name, this.points, {this.center, this.radius});

  /// e.g. `line`, `arrow`, `polyline`, `circle`, `ellipse`, `rectangle`,
  /// `square`, `triangle`, `star`, `polygon5`.
  final String name;

  /// The corners to join with straight lines. Empty for a circle.
  final List<Offset> points;

  final Offset? center;
  final double? radius;
}

/// Works from the geometry of the line: first the corners, then whichever of
/// a straight-sided shape or an ellipse follows the line better.
///
/// Thresholds tuned on simulated shaky hand drawings of each shape.
RecognizedShape? recognizeShape(List<Offset> raw) {
  final line = <Offset>[];
  for (final p in raw) {
    if (p.isFinite && (line.isEmpty || p != line.last)) line.add(p);
  }
  if (line.length < 3) return null;

  final size = _bounds(line).longestSide;
  if (size == 0) return null;
  final gap = (line.first - line.last).distance;
  final length = _length(line);
  // How far round the line goes: a loop turns a whole turn, a U half of
  // one. Ends close together aren't enough: a U whose ends came in towards
  // each other was closed into an oval.
  final turning = _turning(line).abs();
  // (ends that meet close it whatever: a corner where the pen started and
  // stopped isn't counted in the turning)
  final closed =
      gap < 0.1 * size ||
      (gap < max(0.2 * size, 0.12 * length) && turning > 250 * pi / 180);
  if (closed) return _recognizeClosed(line);
  // drawn about 85% of the way round, it's meant to be the whole shape:
  // a smooth loop past 290°, one with corners past 220°
  if (gap < 0.5 * size) {
    final corners = _corners(line, closed: false).length - 2;
    if (turning > 290 * pi / 180 ||
        (corners >= 3 && turning > 220 * pi / 180)) {
      final whole = _recognizeClosed(line);
      if (whole != null) return whole;
    }
  }
  // a loop left open: drawn up to about 80% of the way round, it's meant to
  // be the whole shape. The gap is then a quarter of the line or less, and
  // the line goes right round (a "U" or a "C" with a bigger gap doesn't)
  if (length >= 2 * size && gap <= 0.28 * length) {
    final circle = _circleFromArc(line);
    if (circle != null) return circle;
    // a polygon only when the pen was going along its last side: a "U" or a
    // "V" that ends at a corner is just that, however deep
    if (_endsAlongLastSide(line)) {
      final whole = _recognizeClosed(line);
      if (whole != null) return whole;
    }
  }
  return _recognizeOpen(line, gap);
}

/// How far [line] turns from start to end, in radians, left positive:
/// about 2π for a loop, π for a U.
///
/// The first and last bit of the line are left out: a hook where the pen
/// landed or lifted turned it back on itself, and a U counted as turning
/// anywhere from 70° to 225°.
double _turning(List<Offset> line) {
  final pts = _resample(line, 64);
  var total = 0.0;
  for (int i = 4; i < pts.length - 4; i += 2) {
    total += _wrapAngle(
      (pts[i + 2] - pts[i]).direction - (pts[i] - pts[i - 2]).direction,
    );
  }
  return total;
}

/// Whether [line] ends partway along the side that would close it: after
/// its last corner it heads for the start and is at least a bit of the way
/// there, so the shape is a polygon with its last side unfinished.
bool _endsAlongLastSide(List<Offset> line) {
  final v = _corners(line, closed: false);
  if (v.length < 4) return false;
  final corner = v[v.length - 2], end = v.last, start = v.first;
  final side = start - corner;
  final reach = side.distance;
  if (reach == 0) return false;
  final along = end - corner;
  final progress = (along.dx * side.dx + along.dy * side.dy) / reach;
  final off = ((along.dx * side.dy - along.dy * side.dx) / reach).abs();
  return progress >= 0.12 * reach && progress < reach && off <= 0.12 * reach;
}

/// A circle that most of [line] lies on, found by least squares: the center
/// and radius that the points are nearest to, with the arc reaching round
/// at least 70% of the way.
RecognizedShape? _circleFromArc(List<Offset> line) {
  final pts = _resample(line, 96);
  final fit = _fitCircle(pts);
  if (fit == null) return null;
  final (center, radius, error) = fit;
  if (error > 0.07) return null;
  final angles = [
    for (final p in pts) atan2(p.dy - center.dy, p.dx - center.dx),
  ];
  angles.sort();
  var widest = 2 * pi - (angles.last - angles.first);
  for (int i = 1; i < angles.length; i++) {
    widest = max(widest, angles[i] - angles[i - 1]);
  }
  if (widest > 2 * pi * 0.3) return null;
  return RecognizedShape('circle', const [], center: center, radius: radius);
}

/// The circle [pts] lie nearest to, by least squares, and how far they are
/// from it on average, as a part of its radius.
(Offset, double, double)? _fitCircle(List<Offset> pts) {
  final m = _centroid(pts);
  var suu = 0.0, svv = 0.0, suv = 0.0, suuu = 0.0, svvv = 0.0;
  var suvv = 0.0, svuu = 0.0;
  for (final p in pts) {
    final u = p.dx - m.dx, v = p.dy - m.dy;
    suu += u * u;
    svv += v * v;
    suv += u * v;
    suuu += u * u * u;
    svvv += v * v * v;
    suvv += u * v * v;
    svuu += v * u * u;
  }
  final det = suu * svv - suv * suv;
  if (det.abs() < 1e-9) return null;
  final b1 = 0.5 * (suuu + suvv), b2 = 0.5 * (svvv + svuu);
  final uc = (b1 * svv - b2 * suv) / det;
  final vc = (suu * b2 - suv * b1) / det;
  final center = Offset(m.dx + uc, m.dy + vc);
  final radius = sqrt(uc * uc + vc * vc + (suu + svv) / pts.length);
  if (!radius.isFinite || radius <= 0) return null;
  var error = 0.0;
  for (final p in pts) {
    error += ((p - center).distance - radius).abs();
  }
  return (center, radius, error / pts.length / radius);
}

/// Part of a circle, from where the pen went down to where it lifted, if
/// [line] follows one closely and bends far enough to be meant as a curve.
RecognizedShape? _arc(List<Offset> line) {
  final pts = _resample(line, 64);
  final fit = _fitCircle(pts);
  if (fit == null) return null;
  final (center, radius, error) = fit;
  if (error > 0.045) return null;
  // nearly straight: a circle that big is no use
  if (radius > 4 * _bounds(pts).longestSide) return null;
  final start = (pts.first - center).direction;
  var sweep = 0.0, previous = start;
  for (final p in pts.skip(1)) {
    final angle = (p - center).direction;
    sweep += _wrapAngle(angle - previous);
    previous = angle;
  }
  if (sweep.abs() < 25 * pi / 180 || sweep.abs() > 320 * pi / 180) {
    return null;
  }
  final steps = max(8, (sweep.abs() / (pi / 36)).ceil());
  return RecognizedShape('arc', [
    for (int i = 0; i <= steps; i++)
      center + Offset.fromDirection(start + sweep * i / steps, radius),
  ]);
}

/// Part of an oval, if [line] follows one: an arch taller or wider than a
/// circle's. Only circles' arcs were found, so a tall arch was left as it
/// was drawn, smoothed but wobbly.
///
/// The oval is the one whose equation the points come nearest to solving
/// (Halir and Flusser's direct least squares, which only ever gives an
/// ellipse), then kept only if the line is close to it all along and
/// bends one way only.
RecognizedShape? _ovalArc(List<Offset> line) {
  final pts = _resample(line, 64);
  final bounds = _bounds(pts);
  final size = bounds.longestSide;
  if (size == 0) return null;
  // bends one way only: no S or wave
  var left = 0, right = 0;
  for (int i = 4; i < pts.length - 4; i += 2) {
    final turn = _wrapAngle(
      (pts[i + 4] - pts[i]).direction - (pts[i] - pts[i - 4]).direction,
    );
    if (turn > 0.03) left++;
    if (turn < -0.03) right++;
  }
  if (min(left, right) > 2) return null;

  final c = bounds.center, k = 1 / size;
  final q = [for (final p in pts) (p - c) * k];
  final e = _fitEllipse(q);
  if (e == null) return null;
  var (center, a, b, angle) = e;
  center = c + center / k;
  a /= k;
  b /= k;
  // nearly straight, or far bigger than the line: no use
  if (max(a, b) > 3 * size || min(a, b) < 0.08 * size) return null;
  final cs = cos(angle), sn = sin(angle);
  double param(Offset p) {
    final d = p - center;
    final x = d.dx * cs + d.dy * sn, y = -d.dx * sn + d.dy * cs;
    return atan2(y / b, x / a);
  }

  var error = 0.0;
  for (final p in pts) {
    final d = p - center;
    final x = d.dx * cs + d.dy * sn, y = -d.dx * sn + d.dy * cs;
    error += (sqrt(x * x / (a * a) + y * y / (b * b)) - 1).abs();
  }
  if (error / pts.length > 0.05) return null;

  final start = param(pts.first);
  var sweep = 0.0, previous = start;
  for (final p in pts.skip(1)) {
    final t = param(p);
    sweep += _wrapAngle(t - previous);
    previous = t;
  }
  if (sweep.abs() < 40 * pi / 180 || sweep.abs() > 320 * pi / 180) {
    return null;
  }
  final steps = max(16, (sweep.abs() / (pi / 48)).ceil());
  return RecognizedShape('arc', [
    for (int i = 0; i <= steps; i++)
      () {
        final t = start + sweep * i / steps;
        final x = a * cos(t), y = b * sin(t);
        return center + Offset(x * cs - y * sn, x * sn + y * cs);
      }(),
  ]);
}

/// The ellipse nearest [p] (scaled to about a unit), as its center, its
/// two half axes and the angle of the first: Halir and Flusser's direct
/// least squares fit. Null if the points don't make one.
(Offset, double, double, double)? _fitEllipse(List<Offset> p) {
  // scatter matrices of [x², xy, y²] and [x, y, 1]
  final s1 = List.generate(3, (_) => List.filled(3, 0.0));
  final s2 = List.generate(3, (_) => List.filled(3, 0.0));
  final s3 = List.generate(3, (_) => List.filled(3, 0.0));
  for (final o in p) {
    final d1 = [o.dx * o.dx, o.dx * o.dy, o.dy * o.dy];
    final d2 = [o.dx, o.dy, 1.0];
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        s1[i][j] += d1[i] * d1[j];
        s2[i][j] += d1[i] * d2[j];
        s3[i][j] += d2[i] * d2[j];
      }
    }
  }
  final s3i = _inverse3(s3);
  if (s3i == null) return null;
  // T = -S3⁻¹ S2ᵀ, M = S1 + S2 T
  final t = List.generate(
    3,
    (i) => List.generate(3, (j) {
      var sum = 0.0;
      for (int k = 0; k < 3; k++) {
        sum -= s3i[i][k] * s2[j][k];
      }
      return sum;
    }),
  );
  final m = List.generate(
    3,
    (i) => List.generate(3, (j) {
      var sum = s1[i][j];
      for (int k = 0; k < 3; k++) {
        sum += s2[i][k] * t[k][j];
      }
      return sum;
    }),
  );
  // C1⁻¹ M
  final n = [
    [m[2][0] / 2, m[2][1] / 2, m[2][2] / 2],
    [-m[1][0], -m[1][1], -m[1][2]],
    [m[0][0] / 2, m[0][1] / 2, m[0][2] / 2],
  ];
  for (final value in _eigenvalues3(n)) {
    final v = _nullVector3([
      for (int i = 0; i < 3; i++)
        [for (int j = 0; j < 3; j++) n[i][j] - (i == j ? value : 0)],
    ]);
    if (v == null) continue;
    if (4 * v[0] * v[2] - v[1] * v[1] <= 0) continue;
    final rest = [
      for (int i = 0; i < 3; i++)
        t[i][0] * v[0] + t[i][1] * v[1] + t[i][2] * v[2],
    ];
    final e = _ellipseOfConic(v[0], v[1], v[2], rest[0], rest[1], rest[2]);
    if (e != null) return e;
  }
  return null;
}

/// Center, half axes and angle of the ellipse ax² + bxy + cy² + dx + ey + f = 0.
(Offset, double, double, double)? _ellipseOfConic(
  double a,
  double b,
  double c,
  double d,
  double e,
  double f,
) {
  final den = b * b - 4 * a * c;
  if (den >= 0) return null;
  final x0 = (2 * c * d - b * e) / den, y0 = (2 * a * e - b * d) / den;
  final angle = 0.5 * atan2(-b, c - a);
  final cs = cos(angle), sn = sin(angle);
  // the conic turned to its axes, through its center
  final a2 = a * cs * cs + b * cs * sn + c * sn * sn;
  final c2 = a * sn * sn - b * cs * sn + c * cs * cs;
  final f2 = a * x0 * x0 + b * x0 * y0 + c * y0 * y0 + d * x0 + e * y0 + f;
  if (a2 == 0 || c2 == 0) return null;
  final ax = -f2 / a2, ay = -f2 / c2;
  if (ax <= 0 || ay <= 0) return null;
  return (Offset(x0, y0), sqrt(ax), sqrt(ay), angle);
}

List<List<double>>? _inverse3(List<List<double>> m) {
  final a = m[0][0], b = m[0][1], c = m[0][2];
  final d = m[1][0], e = m[1][1], f = m[1][2];
  final g = m[2][0], h = m[2][1], i = m[2][2];
  final det = a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g);
  if (det.abs() < 1e-12) return null;
  return [
    [(e * i - f * h) / det, (c * h - b * i) / det, (b * f - c * e) / det],
    [(f * g - d * i) / det, (a * i - c * g) / det, (c * d - a * f) / det],
    [(d * h - e * g) / det, (b * g - a * h) / det, (a * e - b * d) / det],
  ];
}

/// The real eigenvalues of a 3 by 3 matrix, from its characteristic cubic.
List<double> _eigenvalues3(List<List<double>> m) {
  final tr = m[0][0] + m[1][1] + m[2][2];
  final minors =
      m[0][0] * m[1][1] -
      m[0][1] * m[1][0] +
      m[0][0] * m[2][2] -
      m[0][2] * m[2][0] +
      m[1][1] * m[2][2] -
      m[1][2] * m[2][1];
  final det =
      m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) -
      m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0]) +
      m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]);
  // λ³ - tr λ² + minors λ - det = 0, as t³ + pt + q with λ = t + tr/3
  final p = minors - tr * tr / 3;
  final q = -2 * tr * tr * tr / 27 + tr * minors / 3 - det;
  final shift = tr / 3;
  final disc = q * q / 4 + p * p * p / 27;
  if (disc > 1e-18) {
    final u = _cbrt(-q / 2 + sqrt(disc)), v = _cbrt(-q / 2 - sqrt(disc));
    return [u + v + shift];
  }
  if (p.abs() < 1e-18) return [shift];
  final r = sqrt(-p / 3);
  final phi = acos((3 * q / (2 * p) * sqrt(-3 / p)).clamp(-1.0, 1.0)) / 3;
  return [
    for (int k = 0; k < 3; k++) 2 * r * cos(phi - 2 * pi * k / 3) + shift,
  ];
}

double _cbrt(double x) =>
    x < 0 ? -pow(-x, 1 / 3).toDouble() : pow(x, 1 / 3).toDouble();

/// A vector the 3 by 3 matrix [m] sends to nothing, from the cross product
/// of its two most independent rows.
List<double>? _nullVector3(List<List<double>> m) {
  List<double> cross(List<double> u, List<double> v) => [
    u[1] * v[2] - u[2] * v[1],
    u[2] * v[0] - u[0] * v[2],
    u[0] * v[1] - u[1] * v[0],
  ];
  List<double>? best;
  var bestNorm = 0.0;
  for (final (i, j) in [(0, 1), (0, 2), (1, 2)]) {
    final v = cross(m[i], m[j]);
    final norm = v[0] * v[0] + v[1] * v[1] + v[2] * v[2];
    if (norm > bestNorm) {
      bestNorm = norm;
      best = v;
    }
  }
  return bestNorm > 1e-24 ? best : null;
}

RecognizedShape? _recognizeOpen(List<Offset> line, double gap) {
  final bend = line.map((p) => _distanceToSegment(p, line.first, line.last));
  if (bend.reduce(max) < 0.08 * gap) return _straightLine(line);

  final v = _corners(line, closed: false);
  if (v.length >= 4 && v.length <= 6) {
    final arrow = _arrow(v);
    if (arrow != null) return arrow;
  }
  // square corners, drawn a little round: an L or a three-sided bracket
  final square = _squareCornered(line, _mergeRoundCorners(v));
  if (square != null) return square;
  // two straight arms and a bottom between them, round at the corners
  final u = _uShape(line);
  if (u != null) return u;
  // Along a circle: an arc. Joining its corners with straight lines drew it
  // as a row of short pieces. A line with real corners doesn't fit a circle.
  final arc = _arc(line) ?? _ovalArc(line);
  if (arc != null) return arc;
  if (v.length == 2) return _straightLine(line);
  // A U, an S or a wave bends all along, not at corners: straight lines
  // between its corners drew a U as four sides of a box.
  final curve = _smoothCurve(line, v);
  if (curve != null) return curve;
  if (v.length > 8) return null; // handwriting: leave it as ink

  final snapped = [v.first];
  for (final p in v.skip(1)) {
    snapped.add(_snapToAxis(snapped.last, p));
  }
  return RecognizedShape('polyline', snapped);
}

/// [v] with each corner a hand rounded off, taken by [_corners] as two
/// close together with a short side between, made one corner where the
/// sides on either side meet. A three-sided bracket came out with four.
List<Offset> _mergeRoundCorners(List<Offset> v) {
  final out = [...v];
  var changed = true;
  while (changed && out.length >= 4) {
    changed = false;
    for (int i = 1; i + 2 < out.length; i++) {
      final short = (out[i + 1] - out[i]).distance;
      final before = (out[i] - out[i - 1]).distance;
      final after = (out[i + 2] - out[i + 1]).distance;
      if (short > 0.3 * min(before, after)) continue;
      final meet = _lineIntersection(
        out[i - 1],
        out[i],
        out[i + 1],
        out[i + 2],
      );
      if (meet == null || (meet - out[i]).distance > 2 * short + 1) continue;
      out.replaceRange(i, i + 2, [meet]);
      changed = true;
      break;
    }
  }
  return out;
}

/// Where the line through [a] and [b] meets the one through [c] and [d].
Offset? _lineIntersection(Offset a, Offset b, Offset c, Offset d) {
  final r = b - a, s = d - c;
  final den = r.dx * s.dy - r.dy * s.dx;
  if (den.abs() < 1e-9) return null;
  final t = ((c.dx - a.dx) * s.dy - (c.dy - a.dy) * s.dx) / den;
  return a + r * t;
}

/// An L (two sides) or a bracket (three, like ⊔ or [) whose corners are
/// about square and whose sides are about straight, drawn exactly so:
/// square corners, a bracket's arms parallel and, if nearly so, as long as
/// each other, and level or upright when it was nearly.
RecognizedShape? _squareCornered(List<Offset> line, List<Offset> v) {
  if (v.length != 3 && v.length != 4) return null;
  const tolerance = 25 * pi / 180;
  final turns = <double>[];
  for (int i = 1; i < v.length - 1; i++) {
    final turn = _wrapAngle(
      (v[i + 1] - v[i]).direction - (v[i] - v[i - 1]).direction,
    );
    if ((turn.abs() - pi / 2).abs() > tolerance) return null;
    turns.add(turn);
  }
  // a bracket turns the same way at both corners (a Z doesn't)
  if (turns.length == 2 && turns[0].sign != turns[1].sign) return null;
  // the sides are straight: the line keeps close to them all along
  final size = _bounds(line).longestSide;
  for (final p in _resample(line, 48)) {
    var nearest = double.infinity;
    for (int i = 0; i + 1 < v.length; i++) {
      nearest = min(nearest, _distanceToSegment(p, v[i], v[i + 1]));
    }
    if (nearest > 0.07 * size) return null;
  }
  if (v.length == 3) {
    final turn = turns.first.sign * pi / 2;
    // the corner, and the two sides at a right angle from it
    final corner = v[1];
    var first = (v[0] - corner).direction;
    first = _snapAngle(first);
    return RecognizedShape('polyline', [
      corner + Offset.fromDirection(first, (v[0] - corner).distance),
      corner,
      corner +
          Offset.fromDirection(first + pi + turn, (v[2] - corner).distance),
    ]);
  }
  // a bracket: the base, then both arms square to it on the same side
  final base = _snapAngle((v[2] - v[1]).direction);
  final baseLength = (v[2] - v[1]).distance;
  final start = v[1];
  final end = start + Offset.fromDirection(base, baseLength);
  var arm1 = (v[0] - v[1]).distance, arm2 = (v[3] - v[2]).distance;
  if (min(arm1, arm2) > 0.8 * max(arm1, arm2)) arm1 = arm2 = (arm1 + arm2) / 2;
  // square to the base, on the side the arms were drawn
  final drawn = (v[0] - v[1]) + (v[3] - v[2]);
  final side = Offset.fromDirection(base + pi / 2);
  final out =
      base + (side.dx * drawn.dx + side.dy * drawn.dy >= 0 ? pi / 2 : -pi / 2);
  return RecognizedShape('bracket', [
    start + Offset.fromDirection(out, arm1),
    start,
    end,
    end + Offset.fromDirection(out, arm2),
  ]);
}

/// A U: two straight arms side by side and a bottom between them, the
/// corners as round as they were drawn, drawn evenly: the arms parallel
/// (upright or level if nearly), the bottom straight and square to them,
/// both corners alike. Nearly square corners make it a bracket ⊔.
///
/// A U drawn with round corners came out as a bracket, a row of crooked
/// straight lines, a wobbly curve or an arc, depending on how round its
/// corners were and how far its arms leaned: no two alike.
RecognizedShape? _uShape(List<Offset> line) {
  final turning = _turning(line).abs() * 180 / pi;
  if (turning < 140 || turning > 220) return null;
  final pts = _resample(line, 96);
  final size = _bounds(pts).longestSide;
  // which way it opens, from the middle of the line to between its ends
  // (from its lowest point, a flat bottom's corner made it look tilted);
  // level or upright if nearly
  final centroid = _centroid(pts);
  var opens = ((pts.first + pts.last) / 2 - centroid).direction;
  final quarter = (opens / (pi / 2)).round() * (pi / 2);
  if ((opens - quarter).abs() < 12 * pi / 180) opens = quarter;
  final up = Offset.fromDirection(opens);
  final across = Offset.fromDirection(opens + pi / 2);
  // the middle of the bottom: of the lower half, the point halfway across
  double along(Offset p, Offset d) =>
      (p - centroid).dx * d.dx + (p - centroid).dy * d.dy;
  final midX = (along(pts.first, across) + along(pts.last, across)) / 2;
  var bottom = -1;
  for (int i = 0; i < pts.length; i++) {
    if (along(pts[i], up) > 0) continue;
    if (bottom < 0 ||
        (along(pts[i], across) - midX).abs() <
            (along(pts[bottom], across) - midX).abs()) {
      bottom = i;
    }
  }
  if (bottom < 8 || bottom > pts.length - 9) return null;
  final origin = pts[bottom];
  double yOf(Offset p) => (p - origin).dx * up.dx + (p - origin).dy * up.dy;
  double xOf(Offset p) =>
      (p - origin).dx * across.dx + (p - origin).dy * across.dy;
  final ys = [for (final p in pts) yOf(p)];
  final xs = [for (final p in pts) xOf(p)];

  // each arm: the upper part of each side, straight and about upright
  ({double x, double top, double a, double b})? arm(
    Iterable<int> indices,
    double top,
  ) {
    final xsArm = <double>[], ysArm = <double>[];
    for (final i in indices) {
      if (ys[i] >= 0.45 * top) {
        xsArm.add(xs[i]);
        ysArm.add(ys[i]);
      }
    }
    if (xsArm.length < 5) return null;
    // x = a + b y, by least squares
    final n = xsArm.length;
    final my = ysArm.reduce((a, b) => a + b) / n;
    final mx = xsArm.reduce((a, b) => a + b) / n;
    var syy = 0.0, sxy = 0.0;
    for (int i = 0; i < n; i++) {
      syy += (ysArm[i] - my) * (ysArm[i] - my);
      sxy += (ysArm[i] - my) * (xsArm[i] - mx);
    }
    if (syy == 0) return null;
    final b = sxy / syy;
    if (b.abs() > tan(20 * pi / 180)) return null;
    for (int i = 0; i < n; i++) {
      final off = xsArm[i] - (mx + b * (ysArm[i] - my));
      if (off.abs() > 0.022 * size + 1.5) return null;
    }
    return (x: mx, top: top, a: mx - b * my, b: b);
  }

  // (leaving out a hook where the pen landed or lifted)
  const hook = 3;
  final topA = ys[hook], topB = ys[ys.length - 1 - hook];
  final height = max(topA, topB);
  if (min(topA, topB) < 0.35 * height) return null;
  final armA = arm([for (int i = hook; i < bottom; i++) i], topA);
  final armB = arm([for (int i = bottom; i < pts.length - hook; i++) i], topB);
  if (armA == null || armB == null) return null;
  final width = (armB.x - armA.x).abs();
  if (width < 0.2 * size) return null;
  final toB = (armB.x - armA.x).sign;
  // the bottom, level: the middle part of it
  final middle = [
    for (int i = 0; i < pts.length; i++)
      if ((xs[i] - (armA.x + armB.x) / 2).abs() < 0.2 * width) ys[i],
  ]..sort();
  if (middle.isEmpty) return null;
  final base = middle[middle.length ~/ 2];

  var heightA = topA - base, heightB = topB - base;
  if (min(heightA, heightB) > 0.85 * max(heightA, heightB)) {
    heightA = heightB = (heightA + heightB) / 2;
  }
  Offset at(double x, double y) => origin + up * (y + base) + across * x;
  List<Offset> ideal(double radius) {
    if (radius < 0.15 * width) {
      return [
        at(armA.x, heightA),
        at(armA.x, 0),
        at(armB.x, 0),
        at(armB.x, heightB),
      ];
    }
    return [
      at(armA.x, heightA),
      // round the corner at A, then at B, a point every 7.5°
      for (int i = 0; i <= 12; i++)
        at(
          armA.x + toB * radius * (1 - cos(i / 12 * (pi / 2))),
          radius * (1 - sin(i / 12 * (pi / 2))),
        ),
      for (int i = 0; i <= 12; i++)
        at(
          armB.x - toB * radius * (1 - sin(i / 12 * (pi / 2))),
          radius * (1 - cos(i / 12 * (pi / 2))),
        ),
      at(armB.x, heightB),
    ];
  }

  // how far the line is from [shape]: on average, and at most
  (double, double) error(List<Offset> shape) {
    var total = 0.0, worst = 0.0;
    for (final p in pts) {
      var nearest = double.infinity;
      for (int i = 0; i + 1 < shape.length; i++) {
        nearest = min(nearest, _distanceToSegment(p, shape[i], shape[i + 1]));
      }
      total += nearest;
      worst = max(worst, nearest);
    }
    return (total / pts.length, worst);
  }

  // as round at the corners as it was drawn: the roundness it's nearest to
  var radius = 0.0;
  var best = double.infinity;
  for (int k = 0; k <= 12; k++) {
    final r = width / 2 * k / 12;
    final (mean, _) = error(ideal(r));
    if (mean < best) {
      best = mean;
      radius = r;
    }
  }
  if (radius > 0.42 * width) radius = width / 2;
  // straight arms, not a round bottom with a little more drawn on: an arc
  if (min(heightA, heightB) - radius < 0.3 * max(heightA, heightB)) {
    return null;
  }
  final shape = ideal(radius);
  final (mean, worst) = error(shape);
  // (an arm drawn leaning is stood upright: its tip moves the most)
  if (worst > 0.18 * size || mean > 0.04 * size) return null;
  return RecognizedShape(radius < 0.15 * width ? 'bracket' : 'u', shape);
}

/// [angle] made level or upright if it's within 10° of one.
double _snapAngle(double angle) {
  final quarter = (angle / (pi / 2)).round() * (pi / 2);
  return (angle - quarter).abs() < 10 * pi / 180 ? quarter : angle;
}

/// A line that turns gradually where [v] puts its corners, drawn as an
/// even curve; null if it turns sharply at any of them.
RecognizedShape? _smoothCurve(List<Offset> line, List<Offset> v) {
  if (v.length < 3 || v.length > 12) return null;
  final pts = _resample(line, 64);
  const reach = 3;
  for (int c = 1; c < v.length - 1; c++) {
    final corner = (v[c + 1] - v[c]).direction - (v[c] - v[c - 1]).direction;
    final bend = _wrapAngle(corner).abs();
    if (bend < 20 * pi / 180) continue;
    var at = 0;
    for (int i = 1; i < pts.length; i++) {
      if ((pts[i] - v[c]).distance < (pts[at] - v[c]).distance) at = i;
    }
    // how much the line itself turns right there
    var sharpest = 0.0;
    for (
      int i = max(reach, at - 2);
      i <= min(pts.length - 1 - reach, at + 2);
      i++
    ) {
      final turn = _wrapAngle(
        (pts[i + reach] - pts[i]).direction -
            (pts[i] - pts[i - reach]).direction,
      ).abs();
      sharpest = max(sharpest, turn);
    }
    if (sharpest > 0.8 * bend) return null;
  }
  // tremor smoothed away, both ends kept where they were drawn
  var smooth = pts;
  for (int pass = 0; pass < 3; pass++) {
    smooth = [
      smooth.first,
      for (int i = 1; i < smooth.length - 1; i++)
        (smooth[i - 1] + smooth[i] * 2 + smooth[i + 1]) / 4,
      smooth.last,
    ];
  }
  return RecognizedShape('curve', smooth);
}

RecognizedShape _straightLine(List<Offset> line) =>
    RecognizedShape('line', [line.first, _snapToAxis(line.first, line.last)]);

/// A long shaft, then a head that comes back to the tip of the shaft.
RecognizedShape? _arrow(List<Offset> v) {
  final shaft = (v[1] - v[0]).distance;
  final barb1 = (v[2] - v[1]).distance;
  final barb2 = (v[3] - v[2]).distance;
  if (shaft <= 2 * max(barb1, barb2)) return null;
  if (!v.skip(3).any((p) => (p - v[1]).distance < 0.3 * shaft)) return null;

  final start = v[0];
  final tip = _snapToAxis(start, v[1]);
  final direction = (start - tip).direction;
  final head = min(barb1, 0.5 * shaft);
  const spread = 28 * pi / 180;
  return RecognizedShape('arrow', [
    start,
    tip,
    tip + Offset.fromDirection(direction + spread, head),
    tip,
    tip + Offset.fromDirection(direction - spread, head),
  ]);
}

/// A closed line always becomes one of the usual shapes, whichever follows it
/// best, however shaky: a circle or oval, a square or rectangle, a diamond or
/// a triangle. Never an odd polygon.
RecognizedShape? _recognizeClosed(List<Offset> line) {
  final outline = _resample([...line, line.first], 96);
  final ellipse = _Ellipse.fit(outline);
  final meanRadius = (ellipse.a + ellipse.b) / 2;
  if (meanRadius <= 0) return null;
  final v = _corners(line, closed: true);
  // Stars and hearts by where the line turns sharply: counting corners
  // missed the tips of a quick star, uneven as a hand draws it, and it
  // became an oval.
  final loop = _loopOf(line);
  final byTurns = _starByTurns(loop) ?? _heartByTurns(loop);
  if (byTurns != null) return byTurns;

  final candidates = <(RecognizedShape, double)>[];
  void consider(RecognizedShape? shape) {
    if (shape == null) return;
    // A square stood on its corner is a diamond: the same shape, but the
    // diamond is what was meant, with its corners straight up and across.
    if (shape.name == 'square') {
      final edge = shape.points[1] - shape.points[0];
      final tilt = _wrapAngle(edge.direction * 4).abs() / 4;
      if (tilt > 30 * pi / 180) return;
    }
    final corners = shape.points.isEmpty
        ? _circlePoints(shape.center!, shape.radius!)
        : shape.points.sublist(0, shape.points.length - 1);
    candidates.add((shape, _polygonError(outline, corners) / meanRadius));
  }

  consider(ellipse.toShape());
  // level, and along the drawing's own axis, which can be anything for a
  // shape as wide as it's tall
  for (final box in [_box(outline, 0), _box(outline, ellipse.angle)]) {
    consider(_boxShape(box));
    consider(_diamond(box));
  }
  if (v.length == 3) {
    consider(_closedPolygon(v));
  } else if (v.length == 4) {
    // a triangle with one corner on a nearly straight side
    consider(_rectangle(v));
    // slanted sides, as OneNote's ink to shape keeps them
    consider(_slantedQuad(v));
  }
  final triangle = _triangle(outline);
  if (triangle != null) consider(triangle);
  // pentagons, hexagons and stars: corners evenly round the middle. The
  // corners are also found where the line turns sharply: a hand's uneven
  // pentagon had a corner too few or many by distance alone, and became a
  // circle.
  final peaks = [for (final p in _turnPeaks(loop, 35 * pi / 180)) p.at];
  final regular =
      _regularPolygon(v) ?? _regularPolygon(peaks) ?? _starOutline(v);
  consider(regular);

  candidates.sort((a, b) => a.$2.compareTo(b.$2));
  final best = candidates.first;
  // a smooth loop is a circle or oval unless the corners clearly fit better
  final round = candidates.firstWhere(
    (c) => c.$1.name == 'circle' || c.$1.name == 'ellipse',
  );
  if (v.length > 6 && round.$2 < best.$2 * 1.6 && best.$1 != regular) {
    return round.$1;
  }
  return best.$1;
}

/// [line] as a loop of evenly spaced points, the first not repeated at the
/// end. A pen that went on a little past where it started is cut back there.
List<Offset> _loopOf(List<Offset> line) {
  var end = line.length - 1;
  var nearest = double.infinity;
  for (int i = (line.length * 0.7).floor(); i < line.length; i++) {
    final d = (line[i] - line.first).distanceSquared;
    if (d < nearest) {
      nearest = d;
      end = i;
    }
  }
  final trimmed = line.sublist(0, end + 1);
  final points = _resample([...trimmed, trimmed.first], 120);
  while (points.length > 3 && (points.last - points.first).distance < 1e-6) {
    points.removeLast();
  }
  return points;
}

/// How far [loop] turns at each point, over a few points either side so a
/// shaky hand doesn't count, signed.
List<double> _turns(List<Offset> loop) {
  const w = 3;
  final n = loop.length;
  return [
    for (int i = 0; i < n; i++)
      _wrapAngle(
        (loop[(i + w) % n] - loop[i]).direction -
            (loop[i] - loop[(i - w + n) % n]).direction,
      ),
  ];
}

/// Where [loop] turns sharply: the sharpest point of each bend, over
/// [least] radians.
List<({Offset at, double turn, int index})> _turnPeaks(
  List<Offset> loop,
  double least,
) {
  final turns = _turns(loop);
  final n = loop.length;
  const apart = 4;
  final peaks = <({Offset at, double turn, int index})>[];
  for (int i = 0; i < n; i++) {
    final t = turns[i].abs();
    if (t < least) continue;
    var sharpest = true;
    for (int j = 1; j <= apart && sharpest; j++) {
      final before = turns[(i - j + n) % n].abs();
      final after = turns[(i + j) % n].abs();
      // ties go to the first of them
      if (before >= t || after > t) sharpest = false;
    }
    if (sharpest) peaks.add((at: loop[i], turn: turns[i], index: i));
  }
  return peaks;
}

/// [peaks] less one where the pen started and stopped, if there's one more
/// than [wanted]: a little hook as the pen lands or lifts isn't a corner.
List<({Offset at, double turn, int index})> _withoutJoin(
  List<({Offset at, double turn, int index})> peaks,
  int wanted,
  int length,
) {
  if (peaks.length != wanted + 1) return peaks;
  const near = 4;
  final join = peaks.where((p) => p.index <= near || p.index >= length - near);
  if (join.length != 1) return peaks;
  return [
    for (final p in peaks)
      if (!identical(p, join.single)) p,
  ];
}

/// Five sharp tips evenly round a middle: a star, drawn through its five
/// points with crossing lines, or round its outline in and out.
/// A star stopped short, so one tip was never drawn: the four that were
/// sit where four of a star's five do, round the middle of the line.
/// Joined up as a closed shape, a quick star that stopped short became a
/// triangle.
RecognizedShape? _starOfFourTips(
  List<Offset> loop,
  List<({Offset at, double turn, int index})> tips,
) {
  final sign = tips.first.turn.sign;
  if (tips.any((t) => t.turn.sign != sign && t.turn.abs() < 150 * pi / 180)) {
    return null;
  }
  // a star's tips are a fifth of the way round from each other, so the
  // middle is where four of them agree on that best
  final centroid = _centroid(loop);
  final size = _bounds(loop).longestSide;
  const step = 2 * pi / 5;
  ({Offset center, double outer, double start, double error})? best;
  for (int gx = -4; gx <= 4; gx++) {
    for (int gy = -4; gy <= 4; gy++) {
      final center = centroid + Offset(gx.toDouble(), gy.toDouble()) * (size * 0.025);
      final radii = [for (final t in tips) (t.at - center).distance];
      final outer = radii.reduce((a, b) => a + b) / 4;
      if (outer <= 0) continue;
      final angles = [for (final t in tips) (t.at - center).direction];
      // where the first slot is, then how far each tip is from its slot
      var sx = 0.0, sy = 0.0;
      for (final a in angles) {
        sx += cos(a * 5);
        sy += sin(a * 5);
      }
      final start = _upright([atan2(sy, sx) / 5], 5);
      var error = 0.0;
      final slots = <int>{};
      for (int i = 0; i < 4; i++) {
        final k = ((angles[i] - start) / step).round() % 5;
        slots.add(k);
        error +=
            _wrapAngle(angles[i] - start - k * step).abs() +
            (radii[i] - outer).abs() / outer;
      }
      if (slots.length != 4) continue;
      if (best == null || error < best.error) {
        best = (center: center, outer: outer, start: start, error: error);
      }
    }
  }
  if (best == null || best.error > 4 * 0.3) return null;
  final corners = [
    for (int i = 0; i < 5; i++)
      best.center + Offset.fromDirection(best.start + i * 2 * step, best.outer),
  ];
  return RecognizedShape('star', [...corners, corners.first]);
}

RecognizedShape? _starByTurns(List<Offset> loop) {
  if (loop.length < 30) return null;
  final peaks = _turnPeaks(loop, 35 * pi / 180);
  final tips = _withoutJoin(
    [
      for (final p in peaks)
        if (p.turn.abs() > 95 * pi / 180) p,
    ],
    5,
    loop.length,
  );
  if (tips.length == 4) return _starOfFourTips(loop, tips);
  if (tips.length != 5) return null;
  // A turn of nearly half a circle can come out either way round: the way
  // the line goes round is taken from the least sharp tip.
  final sign = tips
      .reduce((a, b) => a.turn.abs() < b.turn.abs() ? a : b)
      .turn
      .sign;
  if (tips.any((t) => t.turn.sign != sign && t.turn.abs() < 150 * pi / 180)) {
    return null;
  }
  final center = _centroid([for (final t in tips) t.at]);
  final radii = [for (final t in tips) (t.at - center).distance];
  final outer = radii.reduce((a, b) => a + b) / 5;
  if (outer <= 0 || radii.any((r) => (r - outer).abs() > 0.4 * outer)) {
    return null;
  }
  final angles = [for (final t in tips) (t.at - center).direction]..sort();
  for (int i = 0; i < 5; i++) {
    final gap = i < 4
        ? angles[i + 1] - angles[i]
        : angles[0] + 2 * pi - angles[4];
    if ((gap - 2 * pi / 5).abs() > 28 * pi / 180) return null;
  }
  const step = 2 * pi / 5;
  final start = _upright([for (int i = 0; i < 5; i++) angles[i] - i * step], 5);
  final inward = [
    for (final p in peaks)
      if (p.turn.sign != sign && !tips.contains(p)) (p.at - center).distance,
  ];
  if (inward.length >= 3) {
    // round the outline: tips and the corners in between
    final inner = inward.reduce((a, b) => a + b) / inward.length;
    if (inner > 0.75 * outer) return null;
    final corners = [
      for (int i = 0; i < 10; i++)
        center +
            Offset.fromDirection(
              start + i * step / 2,
              i.isEven ? outer : inner,
            ),
    ];
    return RecognizedShape('star', [...corners, corners.first]);
  }
  // through the tips, every other one
  final corners = [
    for (int i = 0; i < 5; i++)
      center + Offset.fromDirection(start + i * 2 * step, outer),
  ];
  return RecognizedShape('star', [...corners, corners.first]);
}

/// A loop with one sharp dip inwards and a point opposite it, round
/// elsewhere: a heart, made even about the line from the dip to the point.
RecognizedShape? _heartByTurns(List<Offset> loop) {
  if (loop.length < 30) return null;
  final turns = _turns(loop);
  final total = turns.reduce((a, b) => a + b);
  if (total.abs() < pi) return null; // crosses itself
  final way = total.sign;
  // The two sharp turns: the dip, nearer the middle, and the point. A turn
  // of nearly half a circle can come out either way round, so the dip is
  // found by where it is; it must turn against the loop unless it's that
  // sharp.
  final sharp = _withoutJoin(_turnPeaks(loop, 55 * pi / 180), 2, loop.length);
  if (sharp.length != 2) return null;
  final middle = _centroid(loop);
  final (
    dipPeak,
    tipPeak,
  ) = (sharp[0].at - middle).distance < (sharp[1].at - middle).distance
      ? (sharp[0], sharp[1])
      : (sharp[1], sharp[0]);
  bool against(double turn) => turn.sign != way || turn.abs() > 150 * pi / 180;
  bool along(double turn) => turn.sign == way || turn.abs() > 150 * pi / 180;
  if (!against(dipPeak.turn) || !along(tipPeak.turn)) return null;
  final dip = dipPeak.at, tip = tipPeak.at;
  final length = (tip - dip).distance;
  if (length <= 0) return null;
  final down = (tip - dip) / length;
  final across = Offset(-down.dy, down.dx);
  var top = 0.0, left = 0.0, right = 0.0;
  for (final p in loop) {
    final d = p - dip;
    top = min(top, d.dx * down.dx + d.dy * down.dy);
    final side = d.dx * across.dx + d.dy * across.dy;
    left = min(left, side);
    right = max(right, side);
  }
  final width = right - left;
  // lobes on both sides of the line from the dip to the point
  if (min(-left, right) < 0.25 * width) return null;
  if (width < 0.5 * length || width > 2.2 * length) return null;
  if (-top > 0.8 * length) return null;
  // the usual heart curve: its dip at y 5 and point at y -17, 16 either side
  final centre = (left + right) / 2;
  final heart = [
    for (int i = 0; i <= 64; i++)
      () {
        final t = i / 64 * 2 * pi;
        final x = 16 * pow(sin(t), 3);
        final y = 13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t);
        final along = (5 - y) / 22 * length;
        final side = centre + x / 16 * width / 2;
        return dip + down * along + across * side;
      }(),
  ];
  return RecognizedShape('heart', heart);
}

/// Five or six corners about evenly spread round a circle, stood upright.
/// Five corners joined by crossing lines make a star.
RecognizedShape? _regularPolygon(List<Offset> v) {
  final k = v.length;
  if (k != 5 && k != 6) return null;
  final center = _centroid(v);
  final radii = [for (final p in v) (p - center).distance];
  final radius = radii.reduce((a, b) => a + b) / k;
  if (radius <= 0 || radii.any((r) => (r - radius).abs() > 0.22 * radius)) {
    return null;
  }
  final angles = [for (final p in v) (p - center).direction];
  final steps = [
    for (int i = 0; i < k; i++) _wrapAngle(angles[(i + 1) % k] - angles[i]),
  ];
  final meanStep = steps.reduce((a, b) => a + b) / k;
  final isStar = k == 5 && meanStep.abs() > 1.8;
  final step = meanStep.sign * (isStar ? 2 : 1) * 2 * pi / k;
  if (steps.any((s) => _wrapAngle(s - step).abs() > 0.35 * step.abs())) {
    return null;
  }
  final start = _upright([for (int i = 0; i < k; i++) angles[i] - i * step], k);
  final corners = [
    for (int i = 0; i < k; i++)
      center + Offset.fromDirection(start + i * step, radius),
  ];
  return RecognizedShape(isStar ? 'star' : (k == 5 ? 'pentagon' : 'hexagon'), [
    ...corners,
    corners.first,
  ]);
}

/// A star drawn round its outline: ten corners, every other one in close
/// to the middle.
RecognizedShape? _starOutline(List<Offset> v) {
  if (v.length != 10) return null;
  final center = _centroid(v);
  final radii = [for (final p in v) (p - center).distance];
  final first = [for (int i = 0; i < 10; i += 2) radii[i]];
  final second = [for (int i = 1; i < 10; i += 2) radii[i]];
  final a = first.reduce((x, y) => x + y) / 5;
  final b = second.reduce((x, y) => x + y) / 5;
  final outer = max(a, b), inner = min(a, b);
  if (inner > 0.75 * outer || inner < 0.15 * outer) return null;
  final outerFirst = a > b;
  final angles = [for (final p in v) (p - center).direction];
  final meanStep =
      [
        for (int i = 0; i < 10; i++)
          _wrapAngle(angles[(i + 1) % 10] - angles[i]),
      ].reduce((x, y) => x + y) /
      10;
  final step = meanStep.sign * pi / 5;
  final tips = [
    for (int i = outerFirst ? 0 : 1; i < 10; i += 2) angles[i] - i * step,
  ];
  final start = _upright(tips, 5) - (outerFirst ? 0 : step);
  final corners = [
    for (int i = 0; i < 10; i++)
      center +
          Offset.fromDirection(
            start + i * step,
            (i.isEven == outerFirst) ? outer : inner,
          ),
  ];
  return RecognizedShape('star', [...corners, corners.first]);
}

/// The mean of [starts], turned to stand on a point or a flat side if it's
/// nearly so, for a shape with [corners] corners.
double _upright(List<double> starts, int corners) {
  var sumX = 0.0, sumY = 0.0;
  for (final a in starts) {
    sumX += cos(a);
    sumY += sin(a);
  }
  final angle = atan2(sumY, sumX);
  final period = 2 * pi / corners;
  for (final target in [-pi / 2, -pi / 2 + period / 2]) {
    final off = _wrapAngle((angle - target) * corners) / corners;
    if (off.abs() < 15 * pi / 180) return angle - off;
  }
  return angle;
}

List<Offset> _circlePoints(Offset center, double radius) => [
  for (int i = 0; i < 48; i++)
    center + Offset.fromDirection(i / 48 * 2 * pi, radius),
];

/// The box around [points], turned by [angle] (from their spread), or level
/// if nearly so: its center, half sizes and angle.
({Offset center, double w, double h, double angle}) _box(
  List<Offset> points,
  double angle,
) {
  // the box's sides follow the drawing's own axis, a quarter turn at most
  var tilt = _wrapAngle(angle * 4) / 4;
  if (tilt.abs() < 10 * pi / 180) tilt = 0;
  final c = cos(tilt), s = sin(tilt);
  var minU = double.infinity, maxU = -double.infinity;
  var minV = double.infinity, maxV = -double.infinity;
  for (final p in points) {
    final u = p.dx * c + p.dy * s, w = -p.dx * s + p.dy * c;
    minU = min(minU, u);
    maxU = max(maxU, u);
    minV = min(minV, w);
    maxV = max(maxV, w);
  }
  final cu = (minU + maxU) / 2, cv = (minV + maxV) / 2;
  return (
    center: Offset(cu * c - cv * s, cu * s + cv * c),
    w: (maxU - minU) / 2,
    h: (maxV - minV) / 2,
    angle: tilt,
  );
}

RecognizedShape _boxShape(
  ({Offset center, double w, double h, double angle}) box,
) {
  var w = box.w, h = box.h;
  final isSquare = min(w, h) / max(w, h) > 0.88;
  if (isSquare) w = h = (w + h) / 2;
  final u = Offset.fromDirection(box.angle, w);
  final v = Offset.fromDirection(box.angle + pi / 2, h);
  final c = box.center;
  final corners = [c - u - v, c + u - v, c + u + v, c - u + v];
  return RecognizedShape(isSquare ? 'square' : 'rectangle', [
    ...corners,
    corners.first,
  ]);
}

/// A rhombus with its corners at the middles of the box's sides.
RecognizedShape _diamond(
  ({Offset center, double w, double h, double angle}) box,
) {
  final u = Offset.fromDirection(box.angle, box.w);
  final v = Offset.fromDirection(box.angle + pi / 2, box.h);
  final c = box.center;
  final corners = [c - v, c + u, c + v, c - u];
  return RecognizedShape('diamond', [...corners, corners.first]);
}

/// The triangle of the three points of [outline] spread widest apart.
RecognizedShape? _triangle(List<Offset> outline) {
  if (outline.length < 6) return null;
  // the two points furthest apart, then the one furthest from their line
  var a = outline.first, b = outline.first;
  var widest = 0.0;
  for (final p in outline) {
    for (final q in outline) {
      final d = (p - q).distanceSquared;
      if (d > widest) {
        widest = d;
        a = p;
        b = q;
      }
    }
  }
  var c = outline.first;
  var furthest = 0.0;
  for (final p in outline) {
    final d = _distanceToSegment(p, a, b);
    if (d > furthest) {
      furthest = d;
      c = p;
    }
  }
  if (furthest < sqrt(widest) * 0.25) return null;
  return RecognizedShape('triangle', [a, b, c, a]);
}

RecognizedShape _closedPolygon(List<Offset> v) =>
    RecognizedShape(_polygonName(v.length), [...v, v.first]);

String _polygonName(int corners) =>
    corners == 3 ? 'triangle' : 'polygon$corners';

/// Four corners that aren't all square: a parallelogram when both pairs of
/// opposite sides are nearly parallel, a trapezoid when one pair is, made
/// exactly so. Null for a rectangle, or four corners with nothing parallel.
RecognizedShape? _slantedQuad(List<Offset> v) {
  if (v.length != 4) return null;
  // all four sides about the same, corners up, down, left and right: that's
  // a diamond, which [_diamond] draws straight. As a parallelogram it came
  // out leaning.
  final sides = [for (int i = 0; i < 4; i++) (v[(i + 1) % 4] - v[i]).distance];
  if (sides.reduce(min) > 0.8 * sides.reduce(max)) {
    final d1 = v[2] - v[0], d2 = v[3] - v[1];
    double offAxis(Offset d) => _wrapAngle(d.direction * 2).abs() / 2;
    double fromAxis(Offset d) => min(offAxis(d), pi / 2 - offAxis(d));
    if (fromAxis(d1) < 15 * pi / 180 && fromAxis(d2) < 15 * pi / 180) {
      return null;
    }
  }
  const square = 18 * pi / 180, parallel = 10 * pi / 180;
  var allSquare = true;
  for (int i = 0; i < 4; i++) {
    final turn = _turnAngle(v[i], v[(i + 1) % 4], v[(i + 2) % 4]).abs();
    if ((turn - pi / 2).abs() > square) allSquare = false;
  }
  if (allSquare) return null;
  bool isParallel(Offset a, Offset b) =>
      _wrapAngle((a.direction - b.direction) * 2).abs() / 2 < parallel;
  final first = isParallel(v[1] - v[0], v[3] - v[2]);
  final second = isParallel(v[2] - v[1], v[0] - v[3]);
  if (first && second) {
    // the middle and the two sides from the first corner, averaged
    final center = _centroid(v);
    final side1 = ((v[1] - v[0]) + (v[2] - v[3])) / 2;
    final side2 = ((v[3] - v[0]) + (v[2] - v[1])) / 2;
    final a = center - (side1 + side2) / 2;
    return RecognizedShape('parallelogram', [
      a,
      a + side1,
      a + side1 + side2,
      a + side2,
      a,
    ]);
  }
  if (!first && !second) return null;
  // the parallel pair along one direction, each about its own middle
  final (p0, p1, q0, q1) = first
      ? (v[0], v[1], v[2], v[3])
      : (v[1], v[2], v[3], v[0]);
  final along = (p1 - p0) - (q1 - q0); // q runs the other way
  var direction = along.direction;
  // level when nearly so
  final level = _wrapAngle(direction * 2).abs() / 2;
  if (level < 6 * pi / 180) direction = (direction.abs() < pi / 2) ? 0 : pi;
  final unit = Offset.fromDirection(direction);
  Offset half(Offset a, Offset b, double sign) {
    final length = (b - a).distance / 2;
    return unit * (length * sign);
  }

  final pm = (p0 + p1) / 2, qm = (q0 + q1) / 2;
  final points = [
    pm - half(p0, p1, 1),
    pm + half(p0, p1, 1),
    qm - half(q0, q1, -1),
    qm + half(q0, q1, -1),
  ];
  // back to the order the corners were drawn in
  final ordered = first ? points : [points[3], points[0], points[1], points[2]];
  return RecognizedShape('trapezoid', [...ordered, ordered.first]);
}

/// Four corners of about 90 degrees: straight on the page if it's nearly so,
/// and with equal sides if it's nearly a square.
RecognizedShape? _rectangle(List<Offset> v) {
  if (v.length != 4) return null;
  const tolerance = 18 * pi / 180;
  for (int i = 0; i < 4; i++) {
    final turn = _turnAngle(v[i], v[(i + 1) % 4], v[(i + 2) % 4]).abs();
    if ((turn - pi / 2).abs() > tolerance) return null;
  }

  // edges pointing along either axis of the rectangle all agree modulo 90
  var sumX = 0.0, sumY = 0.0;
  for (int i = 0; i < 4; i++) {
    final direction = (v[(i + 1) % 4] - v[i]).direction * 4;
    sumX += cos(direction);
    sumY += sin(direction);
  }
  var tilt = atan2(sumY, sumX) / 4;
  if (tilt.abs() < 8 * pi / 180) tilt = 0;

  final firstEdge = (v[1] - v[0]).direction;
  final angle = tilt + ((firstEdge - tilt) / (pi / 2)).round() * pi / 2;
  var width = ((v[1] - v[0]).distance + (v[3] - v[2]).distance) / 2;
  var height = ((v[2] - v[1]).distance + (v[0] - v[3]).distance) / 2;
  final isSquare = min(width, height) / max(width, height) > 0.9;
  if (isSquare) width = height = (width + height) / 2;

  final center = _centroid(v);
  final u = Offset.fromDirection(angle, width / 2);
  final w = Offset.fromDirection(angle + pi / 2, height / 2);
  final corners = [
    center - u - w,
    center + u - w,
    center + u + w,
    center - u + w,
  ];
  return RecognizedShape(isSquare ? 'square' : 'rectangle', [
    ...corners,
    corners.first,
  ]);
}

class _Ellipse {
  _Ellipse(this.center, this.a, this.b, this.angle, this.error);

  /// Sizes the ellipse from how the points spread along their two main axes.
  factory _Ellipse.fit(List<Offset> points) {
    final center = _centroid(points);
    var xx = 0.0, yy = 0.0, xy = 0.0;
    for (final p in points) {
      final d = p - center;
      xx += d.dx * d.dx;
      yy += d.dy * d.dy;
      xy += d.dx * d.dy;
    }
    final angle = 0.5 * atan2(2 * xy, xx - yy);
    final c = cos(angle), s = sin(angle);
    var uu = 0.0, vv = 0.0;
    final along = <Offset>[];
    for (final p in points) {
      final d = p - center;
      final q = Offset(d.dx * c + d.dy * s, -d.dx * s + d.dy * c);
      along.add(q);
      uu += q.dx * q.dx;
      vv += q.dy * q.dy;
    }
    final a = sqrt(2 * uu / points.length), b = sqrt(2 * vv / points.length);
    if (a < 1e-6 || b < 1e-6) return _Ellipse(center, a, b, angle, 9);
    var error = 0.0;
    for (final q in along) {
      error += (Offset(q.dx / a, q.dy / b).distance - 1).abs();
    }
    return _Ellipse(center, a, b, angle, error / points.length);
  }

  final Offset center;
  final double a, b, angle, error;

  RecognizedShape toShape() {
    if (min(a, b) / max(a, b) > 0.85) {
      return RecognizedShape(
        'circle',
        const [],
        center: center,
        radius: (a + b) / 2,
      );
    }
    final c = cos(angle), s = sin(angle);
    const steps = 96;
    return RecognizedShape('ellipse', [
      for (int i = 0; i <= steps; i++)
        () {
          final t = i / steps * 2 * pi;
          final x = a * cos(t), y = b * sin(t);
          return center + Offset(x * c - y * s, x * s + y * c);
        }(),
    ]);
  }
}

List<Offset> _corners(List<Offset> line, {required bool closed}) {
  final points = _resample(line, 96);
  final size = _bounds(points).longestSide;
  final epsilon = size * 0.06;
  final List<Offset> corners;
  if (closed) {
    // split at the far side, so where the pen started isn't taken for a corner
    var far = 0;
    for (int i = 0; i < points.length; i++) {
      if ((points[i] - points[0]).distance >
          (points[far] - points[0]).distance) {
        far = i;
      }
    }
    final there = _simplify(points.sublist(0, far + 1), epsilon);
    final back = _simplify([...points.sublist(far), points[0]], epsilon);
    corners = [
      ...there.sublist(0, there.length - 1),
      ...back.sublist(0, back.length - 1),
    ];
  } else {
    corners = _simplify(points, epsilon);
  }

  final minSide = size * 0.08;
  final merged = <Offset>[];
  for (final p in corners) {
    if (merged.isEmpty || (p - merged.last).distance >= minSide) merged.add(p);
  }
  if (!closed) return merged;

  while (merged.length > 2 && (merged.first - merged.last).distance < minSide) {
    merged.removeLast();
  }
  // corners on a nearly straight side
  const straight = 20 * pi / 180;
  var changed = true;
  while (changed && merged.length > 3) {
    changed = false;
    for (int i = 0; i < merged.length; i++) {
      final before = merged[(i - 1 + merged.length) % merged.length];
      final after = merged[(i + 1) % merged.length];
      if (_turnAngle(before, merged[i], after).abs() < straight) {
        merged.removeAt(i);
        changed = true;
        break;
      }
    }
  }
  return merged;
}

/// Ramer-Douglas-Peucker.
List<Offset> _simplify(List<Offset> points, double epsilon) {
  final keep = List.filled(points.length, false);
  keep[0] = keep[points.length - 1] = true;
  final stack = <(int, int)>[(0, points.length - 1)];
  while (stack.isNotEmpty) {
    final (start, end) = stack.removeLast();
    var farthest = -1;
    var farthestDistance = epsilon;
    for (int i = start + 1; i < end; i++) {
      final d = _distanceToSegment(points[i], points[start], points[end]);
      if (d > farthestDistance) {
        farthestDistance = d;
        farthest = i;
      }
    }
    if (farthest >= 0) {
      keep[farthest] = true;
      stack
        ..add((start, farthest))
        ..add((farthest, end));
    }
  }
  return [
    for (int i = 0; i < points.length; i++)
      if (keep[i]) points[i],
  ];
}

/// About [count] points evenly spaced along [line].
List<Offset> _resample(List<Offset> line, int count) {
  final step = _length(line) / count;
  if (step == 0) return line;
  final out = [line.first];
  var previous = line.first;
  var travelled = 0.0;
  for (final next in line.skip(1)) {
    var from = previous;
    var d = (next - from).distance;
    while (travelled + d >= step && d > 0) {
      from = from + (next - from) * ((step - travelled) / d);
      out.add(from);
      travelled = 0;
      d = (next - from).distance;
    }
    travelled += d;
    previous = next;
  }
  if (out.last != line.last) out.add(line.last);
  return out;
}

double _polygonError(List<Offset> points, List<Offset> corners) {
  var total = 0.0;
  for (final p in points) {
    var nearest = double.infinity;
    for (int i = 0; i < corners.length; i++) {
      nearest = min(
        nearest,
        _distanceToSegment(p, corners[i], corners[(i + 1) % corners.length]),
      );
    }
    total += nearest;
  }
  return total / points.length;
}

Offset _snapToAxis(Offset from, Offset to) {
  final d = to - from;
  const snap = 6 * pi / 180;
  final angle = atan2(d.dy.abs(), d.dx.abs());
  if (angle < snap) return Offset(to.dx, from.dy);
  if (angle > pi / 2 - snap) return Offset(from.dx, to.dy);
  return to;
}

/// How far the line turns at [b], in radians.
double _turnAngle(Offset a, Offset b, Offset c) {
  final u = b - a, w = c - b;
  return atan2(u.dx * w.dy - u.dy * w.dx, u.dx * w.dx + u.dy * w.dy);
}

double _wrapAngle(double angle) => atan2(sin(angle), cos(angle));

double _length(List<Offset> line) {
  var total = 0.0;
  for (int i = 1; i < line.length; i++) {
    total += (line[i] - line[i - 1]).distance;
  }
  return total;
}

Offset _centroid(List<Offset> points) {
  var sum = Offset.zero;
  for (final p in points) sum += p;
  return sum / points.length.toDouble();
}

Rect _bounds(List<Offset> points) {
  var left = points.first.dx, right = left;
  var top = points.first.dy, bottom = top;
  for (final p in points) {
    left = min(left, p.dx);
    right = max(right, p.dx);
    top = min(top, p.dy);
    bottom = max(bottom, p.dy);
  }
  return Rect.fromLTRB(left, top, right, bottom);
}

double _distanceToSegment(Offset p, Offset a, Offset b) {
  final ab = b - a;
  final len2 = ab.distanceSquared;
  if (len2 == 0) return (p - a).distance;
  final t = (((p - a).dx * ab.dx + (p - a).dy * ab.dy) / len2).clamp(0.0, 1.0);
  return (p - (a + ab * t)).distance;
}

/// For tests: how far [line] turns and its corners.
String debugShapeInfo(List<Offset> line) =>
    'turn ${(_turning(line) * 180 / pi).toStringAsFixed(0)} corners ${_corners(line, closed: false).length} size ${_bounds(line).longestSide.toStringAsFixed(0)} len ${_length(line).toStringAsFixed(0)}';
