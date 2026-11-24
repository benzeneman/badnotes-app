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

const _page = Size(1000, 1400);

Stroke _line(ToolId tool, Color color, Offset a, Offset b) =>
    Stroke(
        color: color,
        pressureEnabled: false,
        options: StrokeOptions(
          size: tool == .highlighter ? 60 : 10,
          isComplete: true,
          thinning: 0,
        ),
        pageIndex: 0,
        page: const HasSize(_page),
        toolId: tool,
      )
      ..nib2 = true
      ..addPoints([
        for (int i = 0; i <= 20; i++) Offset.lerp(a, b, i / 20)!,
      ]);

const _blue = Color(0xFF0000FF);
final _yellow = const Color(0xFFFFD233).withAlpha(210);
final _green = const Color(0xFF7ED957).withAlpha(210);
final _pink = const Color(0xFFFF8FC8).withAlpha(210);

/// Blue pen lines across, highlighters down, taking turns, each over the
/// last: pen 1, highlighter 1, pen 2, highlighter 2, pen 3, highlighter 3.
List<Stroke> _staircase() => [
  _line(.fountainPen, _blue, const Offset(60, 200), const Offset(640, 200)),
  _line(.highlighter, _yellow, const Offset(150, 100), const Offset(150, 700)),
  _line(.fountainPen, _blue, const Offset(60, 350), const Offset(640, 350)),
  _line(.highlighter, _green, const Offset(300, 100), const Offset(300, 700)),
  _line(.fountainPen, _blue, const Offset(60, 500), const Offset(640, 500)),
  _line(.highlighter, _pink, const Offset(450, 100), const Offset(450, 700)),
];

CanvasPainter _painter(
  EditorPage page,
  InkCache? cache, {
  double pixelScale = 0.5,
  double zoom = 1,
}) => CanvasPainter(
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
  pixelScale: cache == null ? null : pixelScale,
);

/// The page drawn at half size: its pixels, and how wide it is.
Future<(Uint8List, int)> _pixels(
  EditorPage page,
  InkCache? cache, {
  double pixelScale = 0.5,
  double zoom = 1,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..scale(0.5);
  canvas.drawColor(Colors.white, BlendMode.src);
  _painter(page, cache, pixelScale: pixelScale, zoom: zoom).paint(canvas, page.size);
  final image = await recorder.endRecording().toImage(500, 700);
  final bytes = await image.toByteData();
  image.dispose();
  return (bytes!.buffer.asUint8List(), 500);
}

/// The colour at [at] on the page.
Color _at((Uint8List, int) pixels, Offset at) {
  final (bytes, width) = pixels;
  final i = ((at.dy / 2).round() * width + (at.dx / 2).round()) * 4;
  return Color.fromARGB(bytes[i + 3], bytes[i], bytes[i + 1], bytes[i + 2]);
}

/// Pen [n] (1 to 3) where it crosses highlighter [m]: blue if the pen is on
/// top, tinted if the highlighter is.
void _expectOrder((Uint8List, int) pixels, String how) {
  const pens = [200.0, 350.0, 500.0];
  const highlighters = [150.0, 300.0, 450.0];
  for (int pen = 0; pen < 3; pen++) {
    for (int hl = 0; hl < 3; hl++) {
      final c = _at(pixels, Offset(highlighters[hl], pens[pen]));
      final penOnTop = pen > hl; // drawn after that highlighter
      final blue = (c.b * 255).round(), red = (c.r * 255).round();
      if (penOnTop) {
        expect(
          blue > 200 && red < 90,
          isTrue,
          reason: '$how: pen ${pen + 1} over highlighter ${hl + 1}, got $c',
        );
      } else {
        expect(
          blue < 180 || red > 120,
          isTrue,
          reason: '$how: highlighter ${hl + 1} over pen ${pen + 1}, got $c',
        );
      }
    }
  }
}

EditorPage _pageOf(List<Stroke> strokes) {
  final page = EditorPage();
  strokes.forEach(page.insertStroke);
  page.sortStrokes();
  return page;
}

void main() {
  test('pen and highlighter taking turns make a layer each', () {
    final s = _staircase();
    final bands = CanvasPainter.inkBands(s, _page);
    expect(bands.length, 6);
    for (int i = 0; i < 6; i++) {
      expect(bands[i], [s[i]], reason: 'layer $i');
    }
  });

  test('shape, highlighter, shape, highlighter: each over the one before', () {
    final shape1 = _line(.shapePen, _blue, const Offset(100, 100), const Offset(300, 100));
    final hl1 = _line(.highlighter, _yellow, const Offset(90, 100), const Offset(310, 100));
    final shape2 = _line(.shapePen, _blue, const Offset(100, 120), const Offset(300, 120));
    final hl2 = _line(.highlighter, _green, const Offset(90, 120), const Offset(310, 120));
    final bands = CanvasPainter.inkBands([shape1, hl1, shape2, hl2], _page);
    // the second shape stays over the first highlighter, under the second
    expect(bands, [
      [shape1],
      [hl1],
      [shape2],
      [hl2],
    ]);
  });

  test('highlighters over each other share a layer (no darker overlap)', () {
    final pen = _line(.fountainPen, _blue, const Offset(100, 100), const Offset(300, 100));
    final a = _line(.highlighter, _yellow, const Offset(90, 100), const Offset(310, 100));
    final b = _line(.highlighter, _green, const Offset(90, 110), const Offset(310, 110));
    expect(CanvasPainter.inkBands([pen, a, b], _page), [
      [pen],
      [a, b],
    ]);
  });

  test('strokes that don\'t touch stay in the first layers', () {
    final strokes = [
      for (int i = 0; i < 10; i++) ...[
        _line(.fountainPen, _blue, Offset(50, 60.0 + i * 120), Offset(300, 60.0 + i * 120)),
        _line(.highlighter, _yellow, Offset(40, 60.0 + i * 120), Offset(310, 60.0 + i * 120)),
      ],
    ];
    expect(CanvasPainter.inkBands(strokes, _page).length, 2);
  });

  test('a page of 2000 strokes and 200 highlighters: layers in under 20 ms', () {
    var seed = 7;
    double next() => (seed = (seed * 1103515245 + 12345) & 0x7fffffff) / 0x7fffffff;
    final strokes = [
      for (int i = 0; i < 2200; i++)
        () {
          final a = Offset(next() * 900, next() * 1300);
          final b = a + Offset(next() * 80, next() * 30);
          return _line(i % 11 == 0 ? .highlighter : .ballpointPen, _blue, a, b);
        }(),
    ];
    // the strokes' bounds are kept on them, as they are on a page
    CanvasPainter.inkBands(strokes, _page);
    final watch = Stopwatch()..start();
    const runs = 5;
    for (int i = 0; i < runs; i++) {
      CanvasPainter.inkBands(strokes, _page);
    }
    expect(watch.elapsedMilliseconds / runs, lessThan(20));
  });

  testWidgets('drawn: each pen line over the highlighters before it and '
      'under the ones after, with and without the image cache', (tester) async {
    await tester.runAsync(() async {
      final page = _pageOf(_staircase());
      _expectOrder(await _pixels(page, null), 'drawn directly');
      final cache = InkCache();
      // the first paint makes the images, the next draws from them
      _expectOrder(await _pixels(page, cache), 'first paint');
      await Future<void>.delayed(const Duration(milliseconds: 200));
      _expectOrder(await _pixels(page, cache), 'from the images');

      // written as it happens: each stroke added to a page already drawn
      final live = EditorPage();
      final liveCache = InkCache();
      for (final stroke in _staircase()) {
        live.insertStroke(stroke);
        live.sortStrokes();
        await _pixels(live, liveCache);
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
      _expectOrder(await _pixels(live, liveCache), 'stroke by stroke');
      cache.dispose();
      liveCache.dispose();
    });
  });

  testWidgets('drawn zoomed in, from tiles: the same order', (tester) async {
    await tester.runAsync(() async {
      final page = _pageOf(_staircase());
      // zoomed in far: too big for an image of the whole page, so the part
      // on screen comes from tiles made in the background
      page.visibleArea.value = const Rect.fromLTWH(0, 0, 700, 700);
      final cache = InkCache();
      (Uint8List, int)? last;
      for (int i = 0; i < 20; i++) {
        last = await _pixels(page, cache, pixelScale: 8, zoom: 4);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      _expectOrder(last!, 'from tiles');
      cache.dispose();
    });
  });
}
