import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:sbn/has_size.dart';
import 'package:sbn/tool_id.dart';

/// A scribble of [n] points going round and round.
Stroke _scribble(int n, {ToolId tool = ToolId.fountainPen}) =>
    Stroke(
      color: Colors.black,
      pressureEnabled: false,
      options: StrokeOptions(size: 4, isComplete: true),
      pageIndex: 0,
      page: const HasSize(Size(1000, 1400)),
      toolId: tool,
    )..addPoints([
      for (var i = 0; i < n; i++)
        Offset(500 + 300 * cos(i / 9) + i * 0.2, 600 + 200 * sin(i / 7)),
    ]);

void main() {
  group('A big stroke is drawn into tiles in pieces', () {
    test('a small stroke stays whole', () {
      expect(_scribble(100).areaPieces, isNull);
    });

    test('the pieces cover the whole stroke', () {
      final stroke = _scribble(1000);
      final pieces = stroke.areaPieces!;
      expect(pieces.length, greaterThan(5));
      final whole = stroke.highQualityPath.getBounds();
      final covered = pieces
          .map((piece) => piece.area)
          .reduce((a, b) => a.expandToInclude(b));
      // steadied afresh in each piece: within a pen's width of the whole
      expect((covered.left - whole.left).abs(), lessThan(4));
      expect((covered.top - whole.top).abs(), lessThan(4));
      expect((covered.right - whole.right).abs(), lessThan(4));
      expect((covered.bottom - whole.bottom).abs(), lessThan(4));
    });

    test('kept until the stroke changes', () {
      final stroke = _scribble(500);
      final first = stroke.areaPieces;
      expect(identical(first, stroke.areaPieces), isTrue);
      stroke.shift(const Offset(10, 0));
      expect(identical(first, stroke.areaPieces), isFalse);
    });

    test('a highlighter or pencil stays whole', () {
      expect(_scribble(1000, tool: ToolId.highlighter).areaPieces, isNull);
      expect(_scribble(1000, tool: ToolId.pencil).areaPieces, isNull);
    });
  });
}
