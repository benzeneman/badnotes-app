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
          size: tool == .highlighter ? 30 : 3,
          isComplete: true,
        ),
        pageIndex: 0,
        page: const HasSize(Size(1000, 1400)),
        toolId: tool,
      )
      ..nib2 = true
      ..addPoints(points);

/// The part of the page at (200, 250), 100 wide and 70 tall (or [part]),
/// painted at [zoom] pixels per page unit.
Future<Uint8List> _pixels(
  EditorPage page,
  InkCache? cache,
  double zoom, {
  Rect part = const Rect.fromLTWH(200, 250, 100, 70),
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)
    ..scale(zoom)
    ..translate(-part.left, -part.top);
  canvas.drawColor(Colors.white, BlendMode.src);
  CanvasPainter(
    strokes: page.strokes,
    laserStrokes: const [],
    currentStroke: null,
    currentSelection: null,
    primaryColor: Colors.blue,
    page: page,
    showPageIndicator: false,
    pageIndex: 0,
    totalPages: 1,
    currentScale: zoom,
    defaultTextStyle: const TextStyle(),
    paintOverlays: false,
    inkCache: cache,
    pixelScale: zoom,
  ).paint(canvas, page.size);
  final image = await recorder.endRecording().toImage(
    (part.width * zoom).round(),
    (part.height * zoom).round(),
  );
  final bytes = await image.toByteData();
  image.dispose();
  return bytes!.buffer.asUint8List();
}

/// How many pixels differ by more than [tolerance] in any channel.
int _differing(Uint8List a, Uint8List b, {int tolerance = 24}) {
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
  // edges compared at different sizes: see [Stroke.inkAsTriangles]
  setUp(() => Stroke.inkAsTriangles = false);
  tearDown(() => Stroke.inkAsTriangles = true);
  testWidgets('zoomed in a lot while pinching, the ink is made sharp in the '
      'background, not left stretched', (tester) async {
    await tester.runAsync(() async {
      final page = EditorPage();
      for (int row = 0; row < 4; row++) {
        page.insertStroke(
          _line(.fountainPen, Colors.black, [
            for (int i = 0; i <= 30; i++)
              Offset(150.0 + i * 8, 260.0 + row * 12 + (i.isEven ? 0 : 6)),
          ]),
        );
      }
      page.insertStroke(
        _line(.highlighter, Colors.yellow.withAlpha(120), [
          const Offset(180, 280),
          const Offset(320, 290),
        ]),
      );
      final cache = InkCache()..follow(page.visibleArea);
      // the part of the page _pixels shows
      page.visibleArea.value = const Rect.fromLTWH(200, 250, 100, 70);
      await _pixels(page, cache, 1);

      // the fingers start zooming: in to 2x. The ink on screen is drawn as
      // it is, not the image made at 1x stretched (blurry) meanwhile.
      InkCache.markMoving();
      final first = await _pixels(page, cache, 2);
      // every stroke drawn as it is
      final sharp = await _pixels(page, null, 2);
      expect(
        _differing(first, sharp),
        lessThan(30),
        reason: 'sharp from the first frame of the zoom',
      );
      // tiles, made a little bigger than shown, smooth edges a little
      // differently, but nothing like a stretched image
      const blurry = 600;

      // a moment later, still pinching
      await Future<void>.delayed(const Duration(milliseconds: 60));
      InkCache.markMoving();
      final later = await _pixels(page, cache, 2);
      expect(InkCache.moving.value, isTrue);
      expect(
        _differing(later, sharp),
        lessThan(blurry ~/ 10),
        reason: 'sharp while still zooming ($blurry stretched)',
      );

      // the fingers lift: the whole page is made at 2x in the background, and
      // it all stays sharp meanwhile and after
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(InkCache.moving.value, isFalse);
      for (int i = 0; i < 4; i++) {
        final shown = await _pixels(page, cache, 2);
        expect(_differing(shown, sharp), lessThan(blurry ~/ 10));
        await Future<void>.delayed(const Duration(milliseconds: 60));
      }
      cache.dispose();
    });
  });

  testWidgets('zoomed far out while pinching, the ink stays and is made '
      'smaller in the background', (tester) async {
    await tester.runAsync(() async {
      final page = EditorPage();
      for (int row = 0; row < 4; row++) {
        page.insertStroke(
          _line(.fountainPen, Colors.black, [
            for (int i = 0; i <= 30; i++)
              Offset(150.0 + i * 8, 260.0 + row * 12 + (i.isEven ? 0 : 6)),
          ]),
        );
      }
      page.insertStroke(
        _line(.highlighter, Colors.yellow.withAlpha(120), [
          const Offset(180, 280),
          const Offset(320, 290),
        ]),
      );
      final cache = InkCache();
      await _pixels(page, cache, 2);
      final want = await _pixels(page, null, 0.5);
      for (int i = 0; i < 6; i++) {
        InkCache.markMoving();
        final shown = await _pixels(page, cache, 0.5);
        expect(
          _differing(shown, want),
          lessThan(want.length ~/ 4 ~/ 20),
          reason: 'frame $i of the pinch',
        );
        await Future<void>.delayed(const Duration(milliseconds: 40));
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
      cache.dispose();
    });
  });

  testWidgets('zoomed in too far for an image of the whole page, the part on '
      'screen is made sharp in the background while pinching', (tester) async {
    await tester.runAsync(() async {
      final page = EditorPage();
      for (int row = 0; row < 4; row++) {
        page.insertStroke(
          _line(.fountainPen, Colors.black, [
            for (int i = 0; i <= 30; i++)
              Offset(150.0 + i * 8, 260.0 + row * 12 + (i.isEven ? 0 : 6)),
          ]),
        );
      }
      page.insertStroke(
        _line(.highlighter, Colors.yellow.withAlpha(120), [
          const Offset(180, 280),
          const Offset(320, 290),
        ]),
      );
      final cache = InkCache()..follow(page.visibleArea);
      // the part of the page _pixels shows
      page.visibleArea.value = const Rect.fromLTWH(200, 250, 100, 70);
      const zoom = 8.0;
      expect(cache.canHold(page.size, zoom), isFalse);
      await _pixels(page, cache, 1);

      InkCache.markMoving();
      final first = await _pixels(page, cache, zoom);
      final sharp = await _pixels(page, null, zoom);
      expect(
        _differing(first, sharp),
        lessThan(30),
        reason: 'sharp from the first frame of the zoom',
      );
      const blurry = 1000;

      await Future<void>.delayed(const Duration(milliseconds: 100));
      InkCache.markMoving();
      final later = await _pixels(page, cache, zoom);
      expect(InkCache.moving.value, isTrue);
      expect(
        _differing(later, sharp),
        lessThan(blurry ~/ 10),
        reason: 'sharp while still zooming ($blurry soft)',
      );

      // scrolled along: the new part is made too
      page.visibleArea.value = const Rect.fromLTWH(330, 250, 100, 70);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      cache.dispose();
    });
  });

  testWidgets('zoomed in, many tiles: they meet without seams, are made a '
      'few at a time, and new ink shows', (tester) async {
    await tester.runAsync(() async {
      final page = EditorPage();
      for (int row = 0; row < 10; row++) {
        page.insertStroke(
          _line(.fountainPen, Colors.black, [
            for (int i = 0; i <= 60; i++)
              Offset(60.0 + i * 9, 80.0 + row * 30 + (i.isEven ? 0 : 9)),
          ]),
        );
      }
      for (int row = 0; row < 3; row++) {
        page.insertStroke(
          _line(.highlighter, Colors.yellow.withAlpha(120), [
            Offset(50, 100.0 + row * 90),
            Offset(600, 120.0 + row * 90),
          ]),
        );
      }
      const part = Rect.fromLTWH(40, 60, 600, 360);
      final cache = InkCache()..follow(page.visibleArea);
      page.visibleArea.value = part;
      await _pixels(page, cache, 1, part: part);

      // zoomed in to 3x and held there: every tile made, a few at a time
      const zoom = 3.0;
      var shown = await _pixels(page, cache, zoom, part: part);
      for (int i = 0; i < 40; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        shown = await _pixels(page, cache, zoom, part: part);
      }
      final sharp = await _pixels(page, null, zoom, part: part);
      final pixels = sharp.length ~/ 4;
      // made a little bigger than shown, so edges are smoothed a little
      // differently, but nothing more
      expect(_differing(shown, sharp, tolerance: 90), 0);
      expect(_differing(shown, sharp), lessThan(pixels ~/ 100));

      // a new line across several tiles shows at once, and sharp soon
      page.insertStroke(
        _line(.fountainPen, Colors.red, [
          const Offset(60, 400),
          const Offset(620, 70),
        ]),
      );
      final withLine = await _pixels(page, null, zoom, part: part);
      shown = await _pixels(page, cache, zoom, part: part);
      expect(
        _differing(shown, withLine, tolerance: 90),
        0,
        reason: 'the new line shows on the very next paint, and nothing blurs',
      );
      for (int i = 0; i < 40; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        shown = await _pixels(page, cache, zoom, part: part);
      }
      expect(_differing(shown, withLine, tolerance: 90), 0);

      // erased across some tiles: right away as it is, and sharp after
      final erased = page.strokes[3].eraseAlong(
        const Offset(200, 50),
        const Offset(220, 400),
        12,
      )!;
      page.strokes
        ..removeAt(3)
        ..insertAll(3, erased);
      final afterErasing = await _pixels(page, null, zoom, part: part);
      shown = await _pixels(page, cache, zoom, part: part);
      expect(_differing(shown, afterErasing, tolerance: 90), 0);
      for (int i = 0; i < 40; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        shown = await _pixels(page, cache, zoom, part: part);
      }
      // a speck or two where the cut edge is smoothed a little differently
      expect(_differing(shown, afterErasing, tolerance: 90), lessThan(10));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      cache.dispose();
    });
  });
}
