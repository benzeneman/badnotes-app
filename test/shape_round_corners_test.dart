import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:badnotes/components/canvas/shape_style.dart';

/// [corners] joined by straight sides with a point every 4 units, as the
/// shape pen makes them; and where the corners are among those points.
(List<Offset>, List<int>) _sides(List<Offset> corners) {
  final points = [corners.first];
  final indices = [0];
  for (int i = 1; i < corners.length; i++) {
    final side = corners[i] - corners[i - 1];
    final steps = (side.distance / 4).ceil();
    for (int s = 1; s <= steps; s++) {
      points.add(corners[i - 1] + side * (s / steps));
    }
    indices.add(points.length - 1);
  }
  return (points, indices);
}

double _length(Path path) =>
    path.computeMetrics().fold(0.0, (sum, m) => sum + m.length);

void main() {
  test('a rounded square has round corners and keeps its sides', () {
    final (points, corners) = _sides(const [
      Offset.zero,
      Offset(100, 0),
      Offset(100, 100),
      Offset(0, 100),
      Offset.zero,
    ]);
    // a closed line's last point is its first: not a corner of its own
    corners.removeLast();
    final round = ShapeStyle.roundCorners(points, corners, 12, closed: true);
    final sharp = ShapeStyle.roundCorners(points, corners, 0, closed: true);
    expect(sharp.contains(const Offset(1, 1)), isTrue);
    expect(round.contains(const Offset(1, 1)), isFalse);
    expect(round.contains(const Offset(99, 99)), isFalse);
    expect(round.contains(const Offset(50, 1)), isTrue);
    expect(round.contains(const Offset(50, 50)), isTrue);
    expect(_length(round), lessThan(_length(sharp)));
    expect(_length(round), greaterThan(_length(sharp) - 4 * 12));
  });

  test('an open line keeps its ends; a right angle is rounded', () {
    final (points, corners) = _sides(const [
      Offset.zero,
      Offset(100, 0),
      Offset(100, 100),
    ]);
    final path = ShapeStyle.roundCorners(points, corners, 12, closed: false);
    final metrics = path.computeMetrics().toList();
    expect(metrics, hasLength(1));
    final line = metrics.single;
    expect(line.getTangentForOffset(0)!.position, Offset.zero);
    final end = line.getTangentForOffset(line.length)!.position;
    expect((end - const Offset(100, 100)).distance, lessThan(0.01));
    expect(line.length, lessThan(200));
    expect(line.length, greaterThan(200 - 2 * 12));
  });

  test('a sharp tip is cut back less than a right angle', () {
    // there and almost straight back, like an arrowhead's side
    final (points, corners) = _sides(const [
      Offset.zero,
      Offset(100, 0),
      Offset(0, 20),
    ]);
    final path = ShapeStyle.roundCorners(points, corners, 12, closed: false);
    final full = 100 + (const Offset(100, 0) - const Offset(0, 20)).distance;
    expect(_length(path), greaterThan(full - 6));
  });

  test('box corners: none unless rounded, never more than fits', () {
    const box = Rect.fromLTWH(0, 0, 200, 10);
    expect(const ShapeStyle(rounded: false).boxCornerRadius(2, box), 0);
    expect(ShapeStyle.plain.boxCornerRadius(2, box), 4.5);
    expect(
      ShapeStyle.plain.boxCornerRadius(2, const Rect.fromLTWH(0, 0, 200, 200)),
      ShapeStyle.cornerRadius(2),
    );
  });
}
