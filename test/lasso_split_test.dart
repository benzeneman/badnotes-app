import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:badnotes/data/tools/select.dart';
import 'package:sbn/has_size.dart';
import 'package:sbn/tool_id.dart';

Stroke _line(ToolId tool) =>
    Stroke(
        color: Colors.yellow,
        pressureEnabled: false,
        options: StrokeOptions(size: 40, isComplete: true),
        pageIndex: 0,
        page: const HasSize(Size(1000, 1400)),
        toolId: tool,
      )
      ..addPoints([for (double x = 0; x <= 400; x += 10) Offset(x, 100)]);

void main() {
  // a lasso round the middle of the line, from x 150 to 250
  const lasso = [
    Offset(150, 60),
    Offset(250, 60),
    Offset(250, 140),
    Offset(150, 140),
  ];

  test('a highlighter the eraser cut is split at the lasso', () {
    final cut = _line(.highlighter)..holes = [(center: const Offset(140, 100), radius: 30)];
    final pieces = Select.splitAtLasso(cut, lasso);
    expect(pieces, isNotNull);
    final (inside, outside) = pieces!;
    // each shows only its side
    expect(inside.showsAt(const Offset(200, 100)), isTrue);
    expect(inside.showsAt(const Offset(350, 100)), isFalse);
    expect(outside.showsAt(const Offset(350, 100)), isTrue);
    expect(outside.showsAt(const Offset(200, 100)), isFalse);
    // turned, the clip turns with the piece
    inside.transform(const Offset(200, 100), 1, 3.14159265);
    expect(inside.showsAt(const Offset(200, 100)), isTrue);
    // saved and read back, it stays split
    final back = Stroke.fromJson(
      inside.toJson(),
      fileVersion: 999,
      pageIndex: 0,
      page: const HasSize(Size(1000, 1400)),
    );
    expect(back.clips.single.inside, isTrue);
    expect(back.clips.single.polygon.length, 4);
  });

  test('a highlighter not erased, or a pen, is picked whole', () {
    expect(Select.splitAtLasso(_line(.highlighter), lasso), isNull);
    final pen = _line(.ballpointPen)..holes = [(center: const Offset(140, 100), radius: 30)];
    expect(Select.splitAtLasso(pen, lasso), isNull);
  });
}
