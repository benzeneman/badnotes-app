import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:badnotes/components/canvas/_canvas_painter.dart';
import 'package:badnotes/components/canvas/_ink_cache.dart';
import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:badnotes/data/editor/page.dart';
import 'package:sbn/has_size.dart';
import 'package:sbn/tool_id.dart';

Stroke _line(ToolId tool, Color color, List<Offset> points) =>
    Stroke(
        color: color,
        pressureEnabled: false,
        options: StrokeOptions(
          size: tool == .highlighter ? 40 : 4,
          isComplete: true,
        ),
        pageIndex: 0,
        page: const HasSize(Size(1000, 1400)),
        toolId: tool,
      )
      ..nib2 = true
      ..addPoints(points);

CanvasPainter _painter(EditorPage page, InkCache cache) => CanvasPainter(
  strokes: page.strokes,
  laserStrokes: const [],
  currentStroke: null,
  currentSelection: null,
  primaryColor: Colors.blue,
  page: page,
  showPageIndicator: false,
  pageIndex: 0,
  totalPages: 1,
  currentScale: 1,
  defaultTextStyle: const TextStyle(),
  paintOverlays: false,
  inkCache: cache,
  pixelScale: 0.5,
);

Future<Uint8List> _pixels(EditorPage page, InkCache cache) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(0.5);
  canvas.drawColor(Colors.white, BlendMode.src);
  _painter(page, cache).paint(canvas, page.size);
  final image = await recorder.endRecording().toImage(500, 700);
  final bytes = await image.toByteData();
  image.dispose();
  return bytes!.buffer.asUint8List();
}

/// How many pixels differ by more than [tolerance] in any channel.
int _differing(Uint8List a, Uint8List b, {int tolerance = 12}) {
  var count = 0;
  for (int i = 0; i < a.length; i += 4) {
    for (int c = 0; c < 4; c++) {
      if ((a[i + c] - b[i + c]).abs() > tolerance) {
        count++;
        break;
      }
    }
  }
  return count;
}

void main() {
  testWidgets('precise eraser on highlighters: cleared over the image, and '
      'baked, look the same as drawing it all again', (tester) async {
    await tester.runAsync(() async {
      final page = EditorPage();
      final yellow = Colors.yellow.withAlpha(120);
      final pink = Colors.pink.withAlpha(110);
      final strokes = [
        _line(.fountainPen, Colors.black, [
          for (int i = 0; i <= 20; i++) Offset(100.0 + i * 40, 300),
        ]),
        for (int row = 0; row < 3; row++)
          _line(.highlighter, row.isEven ? yellow : pink, [
            for (int i = 0; i <= 20; i++)
              Offset(80.0 + i * 42, 280.0 + row * 25),
          ]),
        _line(.fountainPen, Colors.blue, [
          for (int i = 0; i <= 20; i++) Offset(100.0 + i * 40, 340),
        ]),
      ];
      strokes.forEach(page.insertStroke);
      page.sortStrokes();

      final cache = InkCache();
      // the images are made
      await _pixels(page, cache);

      // the eraser goes down through all the highlighters, move by move, on
      // copies of them, as the eraser does
      final copies = <Stroke, Stroke>{};
      for (int move = 0; move < 30; move++) {
        final at = Offset(300 + move * 8.0, 200 + move * 9.0);
        for (int i = 0; i < page.strokes.length; i++) {
          final stroke = page.strokes[i];
          if (stroke.toolId != .highlighter) continue;
          final copy = copies[stroke] ?? stroke.copy();
          copies[copy] = copy;
          copy.addHole(at, 18);
          page.strokes[i] = copy;
        }
        if (move == 10 || move == 29) {
          final fast = await _pixels(page, cache);
          final whole = await _pixels(page, InkCache());
          expect(
            _differing(fast, whole),
            lessThan(60),
            reason: 'cleared over the image, move $move',
          );
        }
      }

      // the holes go into the image in the background
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await _pixels(page, cache);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final baked = await _pixels(page, cache);
      final whole = await _pixels(page, InkCache());
      expect(_differing(baked, whole), lessThan(60), reason: 'baked');

      // and something was erased at all
      final before = EditorPage();
      strokes.forEach(before.insertStroke);
      before.sortStrokes();
      expect(
        _differing(baked, await _pixels(before, InkCache())),
        greaterThan(500),
      );
      cache.dispose();
    });
  });

  testWidgets('holes cut while the image is being made in the background '
      'all show', (tester) async {
    await tester.runAsync(() async {
      final page = EditorPage();
      for (int row = 0; row < 4; row++) {
        page.insertStroke(
          _line(.highlighter, Colors.purple.withAlpha(90), [
            for (int i = 0; i <= 20; i++)
              Offset(80.0 + i * 42, 200.0 + row * 30 + (i.isEven ? 0 : 200)),
          ]),
        );
      }
      final cache = InkCache();
      await _pixels(page, cache);
      // the eraser goes slowly, a move every 15 ms, painting each time:
      // the holes go into the image in the background meanwhile
      final copies = <Stroke>{};
      for (int move = 0; move < 80; move++) {
        final at = Offset(150 + move * 8.0, 250 + 120 * sin(move / 6));
        for (int i = 0; i < page.strokes.length; i++) {
          final stroke = page.strokes[i];
          final copy = copies.contains(stroke)
              ? stroke
              : (stroke.copy()..drawOrder = stroke.drawOrder);
          copies.add(copy);
          copy.addHole(at, 14);
          page.strokes[i] = copy;
        }
        await _pixels(page, cache);
        await Future<void>.delayed(const Duration(milliseconds: 15));
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await _pixels(page, cache);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      final shown = await _pixels(page, cache);
      final whole = await _pixels(page, InkCache());
      // a hole left uncut is the highlighters' full colour; the edge of a
      // hole cleared once instead of once per highlighter is a little off
      // (specks where two highlighters' edges cross a hole's edge: 28)
      expect(_differing(shown, whole, tolerance: 60), lessThan(45));
      expect(_differing(shown, whole), lessThan(600));
      cache.dispose();
    });
  });
}
