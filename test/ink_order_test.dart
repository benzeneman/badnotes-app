import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:badnotes/components/canvas/_canvas_painter.dart';
import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:badnotes/data/editor/page.dart';
import 'package:sbn/has_size.dart';
import 'package:sbn/tool_id.dart';

Stroke _line(ToolId tool, Offset a, Offset b) =>
    Stroke(
        color: Colors.black,
        pressureEnabled: false,
        options: StrokeOptions(
          size: tool == .highlighter ? 20 : 2,
          isComplete: true,
        ),
        pageIndex: 0,
        page: const HasSize(Size(1000, 1400)),
        toolId: tool,
      )
      ..nib2 = true
      ..addPoints([a, b]);

void main() {
  test('ink written after a highlighter goes over it, before it under', () {
    final first = _line(
      .fountainPen,
      const Offset(100, 100),
      const Offset(400, 100),
    );
    final marker = _line(
      .highlighter,
      const Offset(90, 100),
      const Offset(410, 100),
    );
    final second = _line(
      .fountainPen,
      const Offset(100, 110),
      const Offset(400, 110),
    );
    final far = _line(
      .fountainPen,
      const Offset(100, 900),
      const Offset(400, 900),
    );
    final bands = CanvasPainter.inkBands([
      first,
      far,
      marker,
      second,
    ], const Size(1000, 1400));
    // far away from any highlighter: with the first ink
    expect(bands[0], [first, far]);
    expect(bands[1], [marker]);
    expect(bands[2], [second]);
  });

  test('with no highlighter, all ink is in one image', () {
    final a = _line(.fountainPen, const Offset(0, 0), const Offset(10, 0));
    final b = _line(.ballpointPen, const Offset(0, 5), const Offset(10, 5));
    final bands = CanvasPainter.inkBands([a, b], const Size(100, 100));
    expect(bands, [
      [a, b],
    ]);
  });

  test('ink from before strokes kept their order stays under', () {
    final old = _line(
      .fountainPen,
      const Offset(100, 100),
      const Offset(400, 100),
    )..nib2 = false;
    final marker = _line(
      .highlighter,
      const Offset(90, 100),
      const Offset(410, 100),
    )..nib2 = false;
    final bands = CanvasPainter.inkBands([
      marker,
      old,
    ], const Size(1000, 1400));
    expect(bands[0], [old]);
    expect(bands[1], [marker]);
  });

  test('a newer highlighter stays after an older one, whatever its colour', () {
    final page = EditorPage();
    final yellow = _line(.highlighter, Offset.zero, const Offset(10, 0))
      ..color = Colors.yellow.withAlpha(100);
    final pen = _line(.fountainPen, Offset.zero, const Offset(10, 0));
    final red = _line(.highlighter, Offset.zero, const Offset(10, 0))
      ..color = Colors.red.withAlpha(100);
    page.insertStroke(yellow);
    page.insertStroke(pen);
    page.insertStroke(red);
    page.sortStrokes();
    expect(page.strokes, [yellow, pen, red]);
  });

  test('undoing an erase puts a highlighter back in its place, not on top', () {
    final page = EditorPage();
    final yellow = _line(.highlighter, Offset.zero, const Offset(10, 0))
      ..color = Colors.yellow.withAlpha(100);
    final purple = _line(.highlighter, Offset.zero, const Offset(10, 0))
      ..color = Colors.purple.withAlpha(100);
    final blue = _line(.highlighter, Offset.zero, const Offset(10, 0))
      ..color = Colors.blue.withAlpha(100);
    for (final s in [yellow, purple, blue]) {
      page.insertStroke(s);
    }
    // the eraser cuts the purple: a copy with holes in its place
    final cut = purple.copy()..drawOrder = purple.drawOrder;
    cut.addHole(const Offset(5, 0), 3);
    page.strokes[1] = cut;
    // undo: the copy goes, the purple comes back
    page.strokes.remove(cut);
    page.insertStroke(purple);
    expect(page.strokes, [yellow, purple, blue]);
    // redo
    page.strokes.remove(purple);
    page.insertStroke(cut);
    expect(page.strokes, [yellow, cut, blue]);
    page.sortStrokes();
    expect(page.strokes, [yellow, cut, blue]);
  });

  test('a copy pasted or duplicated goes on top', () {
    final page = EditorPage();
    final a = _line(.highlighter, Offset.zero, const Offset(10, 0));
    final b = _line(.highlighter, Offset.zero, const Offset(10, 0));
    page.insertStroke(a);
    page.insertStroke(b);
    final pasted = a.copy();
    page.insertStroke(pasted);
    page.sortStrokes();
    expect(page.strokes, [a, b, pasted]);
  });
}
