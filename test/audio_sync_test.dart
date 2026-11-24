import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:badnotes/components/editor/audio_notes.dart';
import 'package:sbn/has_size.dart';
import 'package:sbn/tool_id.dart';

Stroke _at(double y) => Stroke(
  color: Colors.black,
  pressureEnabled: false,
  options: StrokeOptions(size: 3, isComplete: true),
  pageIndex: 0,
  page: const HasSize(Size(1000, 1400)),
  toolId: ToolId.fountainPen,
)..addPoints([Offset(10, y), Offset(200, y)]);

void main() {
  test('playing a recording, the ink written in it shows as the voice '
      'reaches it; ink from before shows all along', () {
    final before = _at(10);
    final first = _at(100), second = _at(200), third = _at(300);
    final strokes = [before, first, second, third];
    final marks = {
      AudioNotes.strokeKey(first): 1000,
      AudioNotes.strokeKey(second): 5000,
      AudioNotes.strokeKey(third): 9000,
    };
    expect(AudioNotes.strokesShownAt(strokes, marks, 0), {before});
    expect(AudioNotes.strokesShownAt(strokes, marks, 5000), {
      before,
      first,
      second,
    });
    expect(AudioNotes.strokesShownAt(strokes, marks, 20000), strokes.toSet());
  });
}
