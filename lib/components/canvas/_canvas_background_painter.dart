import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:badnotes/data/extensions/color_extensions.dart';
import 'package:sbn/canvas_background_pattern.dart';

/// Paints a page's paper: its colour, then its ruling (lines, grid, dots,
/// staves...) on top in the theme's colours.
class CanvasBackgroundPainter extends CustomPainter {
  const new({
    required this.invert,
    required this.backgroundColor,
    this.backgroundPattern = .none,
    required this.lineHeight,
    required this.lineThickness,
    this.primaryColor = Colors.blue,
    this.secondaryColor = Colors.red,
    this.preview = false,
  });

  /// Whether the paper colour is turned dark, as for a dark page.
  final bool invert;

  /// The paper colour, before [invert] is applied.
  final Color backgroundColor;

  /// Which ruling goes on the paper.
  final CanvasBackgroundPattern backgroundPattern;

  /// The gap between two ruled lines, in page units; most patterns are
  /// measured in it.
  final int lineHeight;

  /// How thick the ruling is drawn, in page units.
  final int lineThickness;

  /// The main ruling's colour, and the one for margins and other accents.
  final Color primaryColor, secondaryColor;

  /// Draws the ruling stronger, for the small samples in the pattern picker.
  final bool preview;

  @override
  void paint(Canvas canvas, Size size) {
    final canvasRect = Offset.zero & size;
    final paint = Paint();

    paint.color = backgroundColor.withInversion(invert);
    canvas.drawRect(canvasRect, paint);

    paint.strokeWidth = lineThickness.toDouble();

    if (backgroundPattern.requiresClipping) {
      canvas.save();
      canvas.clipRect(canvasRect);
    }

    // One draw call per color and kind: drawing each dot and line on its
    // own was thousands of calls a page, on every frame of a scroll.
    final batches = _batchesFor(backgroundPattern, size, lineHeight);
    for (final batch in batches) {
      paint
        ..color = (batch.secondary ? secondaryColor : primaryColor).withValues(
          alpha: preview ? 0.5 : 0.2,
        )
        ..strokeCap = batch.lines ? StrokeCap.butt : StrokeCap.round
        ..strokeWidth = batch.lines
            ? lineThickness.toDouble()
            : lineThickness * 8 / 3;
      canvas.drawRawPoints(
        batch.lines ? ui.PointMode.lines : ui.PointMode.points,
        batch.points,
        paint,
      );
    }

    if (backgroundPattern.requiresClipping) {
      canvas.restore();
    }
  }

  static final _batches =
      <(CanvasBackgroundPattern, Size, int), List<_Batch>>{};

  /// The pattern's dots and lines, made once for each page size.
  static List<_Batch> _batchesFor(
    CanvasBackgroundPattern pattern,
    Size size,
    int lineHeight,
  ) {
    if (_batches.length > 24) _batches.clear();
    return _batches.putIfAbsent((pattern, size, lineHeight), () {
      final lists = <(bool, bool), List<double>>{};
      for (final element in getPatternElements(
        pattern: pattern,
        size: size,
        lineHeight: lineHeight,
      )) {
        final list = lists.putIfAbsent((
          element.secondaryColor,
          element.isLine,
        ), () => []);
        list.addAll([element.start.dx, element.start.dy]);
        if (element.isLine) list.addAll([element.end.dx, element.end.dy]);
      }
      return [
        for (final MapEntry(key: (secondary, lines), :value) in lists.entries)
          _Batch(secondary, lines, Float32List.fromList(value)),
      ];
    });
  }

  @override
  bool shouldRepaint(CanvasBackgroundPainter oldDelegate) =>
      oldDelegate.invert != invert ||
      oldDelegate.backgroundColor != backgroundColor ||
      oldDelegate.backgroundPattern != backgroundPattern ||
      oldDelegate.lineHeight != lineHeight ||
      oldDelegate.lineThickness != lineThickness ||
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.secondaryColor != secondaryColor;

  static Iterable<PatternElement> getPatternElements({
    required CanvasBackgroundPattern pattern,
    required Size size,
    required int lineHeight,
  }) sync* {
    Iterable<PatternElement> lines() sync* {
      for (double y = lineHeight * 2; y < size.height; y += lineHeight) {
        yield PatternElement(Offset(0, y), Offset(size.width, y), isLine: true);
      }
    }

    // an accent line from top to bottom at [x]
    PatternElement uprightAt(double x) => PatternElement(
      Offset(x, 0),
      Offset(x, size.height),
      isLine: true,
      secondaryColor: true,
    );

    // the same, at a share of the page's width
    PatternElement upright(double share) => uprightAt(size.width * share);

    switch (pattern) {
      case .none:
        return;
      case .twoColumns:
        yield* lines();
        yield upright(0.5);
        return;
      case .wideLeft:
        yield* lines();
        yield upright(0.68);
        return;
      case .wideRight:
        yield* lines();
        yield upright(0.32);
        return;
      case .threeColumns:
        yield* lines();
        yield upright(1 / 3);
        yield upright(2 / 3);
        return;
      case .legal:
        yield* lines();
        yield upright(0.1);
        yield upright(0.115);
        return;
      case .todos:
        yield* lines();
        // a box on each line, with room to write beside it
        final side = lineHeight * 0.55;
        final left = lineHeight * 0.6;
        for (double y = lineHeight * 2; y < size.height; y += lineHeight) {
          final top = y - side - lineHeight * 0.15;
          final corners = Rect.fromLTWH(left, top, side, side);
          yield PatternElement(
            corners.topLeft,
            corners.topRight,
            isLine: true,
            secondaryColor: true,
          );
          yield PatternElement(
            corners.topRight,
            corners.bottomRight,
            isLine: true,
            secondaryColor: true,
          );
          yield PatternElement(
            corners.bottomRight,
            corners.bottomLeft,
            isLine: true,
            secondaryColor: true,
          );
          yield PatternElement(
            corners.bottomLeft,
            corners.topLeft,
            isLine: true,
            secondaryColor: true,
          );
        }
        return;
      case .month:
        final top = size.height * 0.1;
        for (var i = 0; i <= 5; i++) {
          final y = top + (size.height - top) * i / 5;
          yield PatternElement(
            Offset(0, y),
            Offset(size.width, y),
            isLine: true,
          );
        }
        for (var i = 1; i < 7; i++) {
          final x = size.width * i / 7;
          yield PatternElement(
            Offset(x, top),
            Offset(x, size.height),
            isLine: true,
          );
        }
        return;
      case .week:
        // four equal rows: three of two days, then the last day across
        // two lines' room at the top, as every page has
        final top = max(size.height * 0.06, lineHeight * 2.0);
        double rowY(int k) => top + (size.height - top) * k / 4;
        for (var k = 0; k < 4; k++) {
          yield PatternElement(
            Offset(0, rowY(k)),
            Offset(size.width, rowY(k)),
            isLine: true,
          );
          // a faint line under each day's name
          final under = rowY(k) + lineHeight * 1.2;
          yield PatternElement(
            Offset(0, under),
            Offset(size.width, under),
            isLine: true,
            secondaryColor: true,
          );
        }
        yield PatternElement(
          Offset(size.width / 2, top),
          Offset(size.width / 2, rowY(3)),
          isLine: true,
        );
        return;
      case .day:
        // a heading, then a line each half hour with the hours marked
        final top = lineHeight * 3.0;
        final hourColumn = size.width * 0.14;
        var i = 0;
        for (double y = top; y < size.height; y += lineHeight, i++) {
          yield PatternElement(
            Offset(i.isEven ? 0 : hourColumn, y),
            Offset(size.width, y),
            isLine: true,
            secondaryColor: i.isOdd,
          );
        }
        yield upright(0.14);
        return;
      case .collegeLtr:
      case .collegeRtl:
      case .lined:
        yield* lines();
        // a college page's margin, two lines in from the side it is on
        if (pattern == .collegeLtr) {
          yield uprightAt(lineHeight * 2.0);
        } else if (pattern == .collegeRtl) {
          yield uprightAt(size.width - lineHeight * 2);
        }
      case .grid:
        yield* lines();
        // the columns start where the first row does
        final gridTop = lineHeight * 2.0;
        for (double x = 0; x < size.width; x += lineHeight) {
          yield PatternElement(
            Offset(x, gridTop),
            Offset(x, size.height),
            isLine: true,
          );
        }
      case .dots:
        // a dot wherever a grid's lines would cross, edges included
        for (double y = lineHeight * 2; y <= size.height; y += lineHeight) {
          for (double x = 0; x <= size.width; x += lineHeight) {
            final dot = Offset(x, y);
            yield PatternElement(dot, dot, isLine: false);
          }
        }
      case .staffs:
      case .tablature:
        // music staves have five lines, guitar tabs six
        final gaps = pattern == .staffs ? 4 : 5;
        final staffHeight = lineHeight * gaps;
        final spaceBetween = lineHeight * 3;
        final left = lineHeight.toDouble();
        final right = size.width - lineHeight;

        for (
          double top = spaceBetween.toDouble() - lineHeight;
          top + staffHeight < size.height;
          top += staffHeight + spaceBetween
        ) {
          for (int k = 0; k <= gaps; k++) {
            final y = top + lineHeight * k;
            yield PatternElement(
              Offset(left, y),
              Offset(right, y),
              isLine: true,
            );
          }
          // closed off at both ends
          final bottom = top + staffHeight;
          yield PatternElement(
            Offset(left, top),
            Offset(left, bottom),
            isLine: true,
          );
          yield PatternElement(
            Offset(right, top),
            Offset(right, bottom),
            isLine: true,
          );
        }
      case .cornell:
        final left = lineHeight.toDouble();
        final right = size.width - lineHeight;
        final middle = size.width / 2;

        // the top line, split in two: name on the left, date on the right
        final headY = lineHeight * 2.0;
        yield PatternElement(
          Offset(left, headY),
          Offset(middle - lineHeight / 2, headY),
          isLine: true,
        );
        yield PatternElement(
          Offset(middle + lineHeight / 2, headY),
          Offset(right, headY),
          isLine: true,
        );
        // a full line under them for the title
        final titleY = lineHeight * 3.0;
        yield PatternElement(
          Offset(left, titleY),
          Offset(right, titleY),
          isLine: true,
        );

        // the notes area: right of the cues column (the left 35%) and above
        // the summary (the bottom 30%)
        final cuesEdge = size.width * 0.35;
        final summaryTop = size.height * 0.7;
        for (double y = lineHeight * 5; y < summaryTop; y += lineHeight) {
          yield PatternElement(
            Offset(cuesEdge, y),
            Offset(right, y),
            isLine: true,
          );
        }
    }
  }
}

/// One mark of a page's ruling: a line from [start] to [end], or a dot at
/// [start].
class PatternElement {
  final Offset start, end;

  /// False for a dot.
  final bool isLine;

  /// Drawn in the accent colour, as margins are.
  final bool secondaryColor;

  const new(
    this.start,
    this.end, {
    this.isLine = true,
    this.secondaryColor = false,
  });
}

class _Batch {
  const _Batch(this.secondary, this.lines, this.points);
  final bool secondary, lines;
  final Float32List points;
}
