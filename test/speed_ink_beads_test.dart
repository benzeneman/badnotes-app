import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:sbn/has_size.dart';
import 'package:sbn/tool_id.dart';

void main() {
  // Beads: at full tip sharpness the width followed the pen's speed from one
  // sample to the next, so a turn where the pen slowed swelled into a knob.
  test('at full tip sharpness the width changes gently along the line', () {
    final stroke =
        Stroke(
            color: Colors.black,
            pressureEnabled: false,
            options: StrokeOptions(size: 5, thinning: 0.9, isComplete: true),
            pageIndex: 0,
            page: const HasSize(Size(1000, 1000)),
            toolId: ToolId.fountainPen,
          )
          ..nib2 = true
          ..speedInk = true;
    // fast strokes with a slow turn between them, like handwriting
    var x = 100.0;
    for (var round = 0; round < 6; round++) {
      for (var i = 0; i < 12; i++) {
        stroke.addPoint(Offset(x += 6, 300.0 + round));
      }
      for (var i = 0; i < 6; i++) {
        stroke.addPoint(Offset(x += 0.3, 300.0 + round));
      }
    }
    final widths = stroke.nibPressures;
    for (var i = 1; i < widths.length; i++) {
      expect(
        (widths[i] - widths[i - 1]).abs(),
        lessThan(0.06),
        reason: 'point $i: ${widths[i - 1]} to ${widths[i]}',
      );
    }
    // never a hairline
    expect(widths.reduce((a, b) => a < b ? a : b), greaterThan(0.18));
  });
}
