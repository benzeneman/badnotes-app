import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:badnotes/components/editor/handwriting_ocr.dart';
import 'package:badnotes/components/editor/note_search_panel.dart';

void main() {
  test('Drawings read as single letters are left out, words kept', () {
    expect(dropJunkWords("'s S e l o t Karan"), 'Karan');
    expect(dropJunkWords('Hi Karan!'), 'Hi Karan!');
    expect(dropJunkWords('\\ _ - ~'), '');
    expect(dropJunkWords('पानी का चक्र'), 'पानी का चक्र');
  });

  test('A saved line of only junk is dropped when read back', () {
    final junk = OcrLine(['l', 'I'], Rect.fromLTRB(0, 0, 5, 20)).toJson();
    expect(OcrLine.fromJson(junk), isNull);
  });

  test('A handwriting hit knows its line and roughly its word', () {
    final hits = searchNote([
      OcrPage(
        key: '',
        lines: [OcrLine(['Hi Karan!'], Rect.fromLTRB(0, 0, 90, 20))],
        typed: 'meeting with Karan on Monday',
      ),
    ], 'karan');
    expect(hits.map((h) => h.source), ['Handwriting', 'Text']);
    expect(hits.first.bounds, Rect.fromLTRB(0, 0, 90, 20));
    expect(hits.first.word!.left, closeTo(30, 0.01));
    expect(hits.first.word!.right, closeTo(80, 0.01));
    expect(hits.last.bounds, isNull);
  });
}
