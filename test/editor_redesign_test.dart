import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:badnotes/components/canvas/shape_style.dart';
import 'package:badnotes/components/editor/sticky_note_dialog.dart';
import 'package:badnotes/data/flavor_config.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/tools/eraser.dart';
import 'package:badnotes/data/tools/pen.dart';
import 'package:badnotes/data/tools/select.dart';
import 'package:sbn/has_size.dart';
import 'package:sbn/tool_id.dart';

Stroke _line(ToolId tool, double y) => Stroke(
  color: Colors.black,
  pressureEnabled: false,
  options: StrokeOptions(size: 2, isComplete: true),
  pageIndex: 0,
  page: const HasSize(Size(500, 500)),
  toolId: tool,
)..addPoints([Offset(0, y), Offset(400, y), Offset(400, y)]);

void main() {
  setUp(FlavorConfig.setup);

  test('eraser filter leaves the kinds of ink switched off', () {
    stows.eraserFilter.value = ['pen', 'tape'];
    Eraser.type = EraserType.stroke;
    final pen = _line(.fountainPen, 50);
    final highlight = _line(.highlighter, 50);
    final strokes = [pen, highlight];
    Eraser().erase(strokes, const Offset(200, 0), const Offset(200, 100), 1);
    expect(strokes, [highlight]);
    stows.eraserFilter.value = ['pen', 'pencil', 'highlighter', 'tape'];
  });

  test('lasso groups', () {
    expect(Select.groupOf(_line(.ballpointPen, 0)), 'handwriting');
    expect(Select.groupOf(_line(.tape, 0)), 'tape');
    final shape = _line(.shapePen, 0);
    expect(Select.groupOf(shape), 'shapes');
    shape.shapeStyle = const ShapeStyle(arrowEnd: ShapeArrow.filled);
    expect(Select.groupOf(shape), 'arrows');
  });

  test('older two-size saves read as three sizes', () {
    final saved = Pen.parseSizeSlots('fountainPen:1.5:4.0:1', 'fountainPen')!;
    expect(saved.$1, [1.5, 4.0]);
    final three = Pen.parseSizeSlots('fountainPen:1:2:3:2', 'fountainPen')!;
    expect(three.$1, [1, 2, 3]);
    expect(three.$2, 2);
  });

  test('a sticky note without its text: the paper only, as big', () {
    const note = StickyNoteResult('Exam on Monday\nrevise ch 3', Color(0xFFFFF176));
    final blank = stickyNoteToSvg(note, withText: false);
    expect(blank, isNot(contains('<text')));
    expect(stickyNoteToSvg(note), contains('<text'));
    // still the note, with its text kept, so it reads back the same
    expect(stickyNoteFromSvg(blank)!.text, note.text);
    // a longer text grows the paper typed over
    final longer = note.copyWith(text: List.filled(20, 'line').join('\n'));
    expect(
      stickyNoteSize(longer).height,
      greaterThan(stickyNoteSize(note).height),
    );
    final area = note.textArea;
    expect(area.top, note.style.textTop);
    expect(area.width, lessThan(stickyNoteSize(note).width));
  });

  test('text box format survives the SVG', () {
    const note = StickyNoteResult(
      'Hello',
      null,
      font: 'Caveat',
      fontSize: 30,
      maxWidth: 300,
      textColor: Color(0xFFFF0000),
      bold: true,
      italic: true,
      align: TextAlign.center,
    );
    final svg = stickyNoteToSvg(note);
    expect(svg, contains('font-weight="bold"'));
    expect(svg, contains('text-anchor="middle"'));
    final back = stickyNoteFromSvg(svg)!;
    expect(back.textColor, const Color(0xFFFF0000));
    expect(back.bold && back.italic, isTrue);
    expect(back.align, TextAlign.center);
  });

  test('shape style json round trip', () {
    const style = ShapeStyle(
      fill: Color(0x33FF0000),
      line: ShapeLine.dashed,
      rounded: false,
      arrowStart: ShapeArrow.open,
    );
    final back = ShapeStyle.fromJson(style.toJson())!;
    expect(back.fill, style.fill);
    expect(back.line, ShapeLine.dashed);
    expect(back.rounded, isFalse);
    expect(back.arrowStart, ShapeArrow.open);
  });
}
