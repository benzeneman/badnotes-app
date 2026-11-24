import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:badnotes/components/editor/canvas_tools_overlay.dart';

void main() {
  test('a stroke near an edge follows that edge', () {
    final ruler = Ruler(const Offset(100, 100));
    const half = Ruler.thickness / 2;

    // just below the ruler
    final below = Offset(300, 100 + half + 10);
    expect(ruler.edgeNear(below), 1);
    expect(ruler.project(below, 1), Offset(300, 100 + half));

    // just above the ruler
    final above = Offset(0, 100 - half - 10);
    expect(ruler.edgeNear(above), -1);
    expect(ruler.project(above, -1), Offset(0, 100 - half));

    // on the ruler, or too far away
    expect(ruler.edgeNear(const Offset(100, 100)), isNull);
    expect(ruler.edgeNear(Offset(100, 100 + half + Ruler.snapReach + 1)), isNull);
  });

  test('angle sticks to 45 degree steps', () {
    final ruler = Ruler(Offset.zero);
    ruler.move(Offset.zero, pi / 180);
    expect(ruler.angle, 0);
    ruler.move(Offset.zero, 5 * pi / 180);
    expect(ruler.angle, closeTo(6 * pi / 180, 1e-9));
    ruler.move(Offset.zero, 39 * pi / 180);
    expect(ruler.angle, closeTo(pi / 4, 1e-9));
  });
}
