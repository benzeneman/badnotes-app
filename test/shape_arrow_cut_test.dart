import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:badnotes/components/canvas/shape_style.dart';
import 'package:sbn/has_size.dart';

const _arrows = ShapeStyle(arrowStart: .open, arrowEnd: .filled);

/// A shape through [corners], with points along its sides as the shape pen
/// makes them.
Stroke _shape(List<Offset> corners) {
  final points = <Offset>[corners.first];
  for (int i = 1; i < corners.length; i++) {
    for (int k = 1; k <= 10; k++) {
      points.add(Offset.lerp(corners[i - 1], corners[i], k / 10)!);
    }
  }
  return Stroke(
      color: Colors.black,
      pressureEnabled: false,
      options: StrokeOptions(size: 3, isComplete: true),
      pageIndex: 0,
      page: const HasSize(Size(1000, 1400)),
      toolId: .shapePen,
    )
    ..shapeStyle = _arrows
    ..addPoints(points);
}

void main() {
  test('cut in the middle, each piece keeps only its own arrowhead', () {
    final line = _shape([const Offset(100, 100), const Offset(400, 100)]);
    final pieces = line.eraseAlong(
      const Offset(250, 80),
      const Offset(250, 120),
      6,
    )!;
    expect(pieces, hasLength(2));
    expect(pieces.first.shapeStyle!.arrowStart, ShapeArrow.open);
    expect(pieces.first.shapeStyle!.arrowEnd, ShapeArrow.none);
    expect(pieces.last.shapeStyle!.arrowStart, ShapeArrow.none);
    expect(pieces.last.shapeStyle!.arrowEnd, ShapeArrow.filled);
    // cut again: the piece with no arrowhead gets none
    final again = pieces.first.eraseAlong(
      const Offset(170, 80),
      const Offset(170, 120),
      6,
    )!;
    expect(again, hasLength(2));
    expect(again.first.shapeStyle!.arrowStart, ShapeArrow.open);
    expect(
      again.last.shapeStyle?.arrowStart ?? ShapeArrow.none,
      ShapeArrow.none,
    );
    expect(again.last.shapeStyle?.arrowEnd ?? ShapeArrow.none, ShapeArrow.none);
  });

  test('the end erased: its arrowhead goes with it, none at the cut', () {
    final line = _shape([const Offset(100, 100), const Offset(400, 100)]);
    final pieces = line.eraseAlong(
      const Offset(395, 80),
      const Offset(395, 120),
      10,
    )!;
    expect(pieces, hasLength(1));
    expect(pieces.single.shapeStyle!.arrowStart, ShapeArrow.open);
    expect(pieces.single.shapeStyle!.arrowEnd, ShapeArrow.none);
  });

  test('a rectangle cut open is one line, with no arrowheads', () {
    final box = _shape(const [
      Offset(100, 100),
      Offset(300, 100),
      Offset(300, 250),
      Offset(100, 250),
      Offset(100, 100),
    ]);
    expect(box.isClosedShape, isTrue);
    final pieces = box.eraseAlong(
      const Offset(200, 80),
      const Offset(200, 120),
      6,
    )!;
    expect(pieces, hasLength(1), reason: 'joined where it was started');
    final style = pieces.single.shapeStyle;
    expect(style?.arrowStart ?? ShapeArrow.none, ShapeArrow.none);
    expect(style?.arrowEnd ?? ShapeArrow.none, ShapeArrow.none);
    // it goes all the way round, from one side of the cut to the other
    final points = pieces.single.points;
    expect(points.first.x, greaterThan(200));
    expect(points.last.x, lessThan(200));
    expect(points.first.y, 100);
  });
}
