import 'dart:ui';

import 'package:badnotes/data/my_templates.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sbn/canvas_background_pattern.dart';

void main() {
  final page = <String, dynamic>{
    'w': 1000.0,
    'h': 1414.0,
    's': [
      {'p': 'points', 'i': 3},
    ],
    'i': [
      {'a': 0, 'i': 3},
    ],
    'q': [
      {'insert': 'Mon\n'},
    ],
    'fav': true,
  };

  group('templatePageJson', () {
    test('keeps the content, on the first page, with the note paper', () {
      final json = MyTemplates.templatePageJson(
        page,
        keepContent: true,
        notePattern: CanvasBackgroundPattern.lined,
        noteLineHeight: 40,
        noteColor: const Color(0xFFFFFCEE),
      );
      expect(json['fav'], isNull);
      expect((json['s'] as List).single['i'], 0);
      expect((json['i'] as List).single['i'], 0);
      expect((json['i'] as List).single['a'], 0);
      expect(json['q'], isNotNull);
      expect(json['bp'], CanvasBackgroundPattern.lined.name);
      expect(json['lh'], 40);
      expect(json['bc'], 0xFFFFFCEE);
      expect(MyTemplates.hasContent(json), isTrue);
      // the note's page is left alone
      expect((page['s'] as List).single['i'], 3);
    });

    test('only the paper', () {
      final json = MyTemplates.templatePageJson(
        {...page, 'bp': 'grid', 'lh': 25},
        keepContent: false,
        notePattern: CanvasBackgroundPattern.lined,
        noteLineHeight: 40,
        noteColor: null,
      );
      expect(json.keys, unorderedEquals(['w', 'h', 'bp', 'lh']));
      expect(json['bp'], 'grid');
      expect(json['lh'], 25);
      expect(MyTemplates.hasContent(json), isFalse);
    });
  });

  test('paperOf reads the page, then the note, and Int64 colours', () {
    final paper = MyTemplates.paperOf(
      {'w': 707, 'h': 1000, 'bc': Int64(0xFF121212)},
      {'p': 'dots', 'l': 30},
    );
    expect(paper.size, const Size(707, 1000));
    expect(paper.pattern, CanvasBackgroundPattern.dots);
    expect(paper.color, const Color(0xFF121212));
    expect(paper.lineHeight, 30);
  });

  test('cleanName', () {
    expect(MyTemplates.cleanName(' Weekly/planner '), 'Weekly-planner');
    expect(MyTemplates.cleanName('..hidden'), 'hidden');
    expect(MyTemplates.cleanName('   '), 'My template');
  });
}
