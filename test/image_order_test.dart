import 'dart:ui' as ui;

import 'package:badnotes/components/canvas/_canvas_painter.dart';
import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:badnotes/components/canvas/image/editor_image.dart';
import 'package:badnotes/data/editor/editor_core_info.dart';
import 'package:badnotes/data/editor/page.dart';
import 'package:badnotes/data/flavor_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:sbn/has_size.dart';
import 'package:sbn/tool_id.dart';

Stroke _line(ToolId tool, Color color, Offset a, Offset b, double size) =>
    Stroke(
        color: color,
        pressureEnabled: false,
        options: StrokeOptions(size: size, isComplete: true, thinning: 0),
        pageIndex: 0,
        page: const HasSize(Size(1000, 1400)),
        toolId: tool,
      )
      ..nib2 = true
      ..addPoints([for (int i = 0; i <= 20; i++) Offset.lerp(a, b, i / 20)!]);

/// A text box (stored as an SVG picture) at [rect].
SvgEditorImage _box(Rect rect) => SvgEditorImage(
  id: rect.hashCode,
  svgString: '<svg height="40" width="200"></svg>',
  svgFile: null,
  pageIndex: 0,
  pageSize: EditorPage.defaultSize,
  onMoveImage: null,
  onDeleteImage: null,
  onMiscChange: null,
  assetCache: EditorCoreInfo(filePath: '').assetCache,
)..dstRect = rect;

/// Writes [stroke] on [page] now, as the editor does.
void _write(EditorPage page, Stroke stroke) {
  stroke
    ..onFrontImage = page.drawsOverFrontImages(stroke)
    ..afterImage = page.latestFrontOrder(stroke.layer);
  page.insertStroke(stroke);
}

/// The tier of each stroke, with the page's pictures in the order put on.
int _tier(EditorPage page, Stroke stroke) => page.tierOf(
  stroke,
  EditorPage.inOrder(page.images.where((i) => i.inFront)),
);

const _yellow = Color(0xC8FFD233);

void main() {
  setUp(FlavorConfig.setup);

  test('text box, highlighter on it, text box over that: each over the one '
      'before', () {
    final page = EditorPage();
    final box1 = _box(const Rect.fromLTWH(100, 100, 300, 80));
    page.putImagesInFront([box1], layer: 0);
    // inside the first box
    final hl = _line(.highlighter, _yellow, const Offset(130, 140), const Offset(370, 140), 30);
    _write(page, hl);
    final box2 = _box(const Rect.fromLTWH(200, 120, 300, 80));
    page.putImagesInFront([box2], layer: 0);
    // over box 1 (gap 1), under box 2 (gap 2 would be over it)
    expect(_tier(page, hl), 1);
  });

  test('a highlighter bigger than the text box: over it, and under the '
      'next one', () {
    final page = EditorPage();
    page.putImagesInFront([_box(const Rect.fromLTWH(100, 100, 300, 80))], layer: 0);
    final hl = _line(.highlighter, _yellow, const Offset(50, 140), const Offset(500, 140), 30);
    _write(page, hl);
    page.putImagesInFront([_box(const Rect.fromLTWH(200, 120, 300, 80))], layer: 0);
    expect(_tier(page, hl), 1, reason: 'still over the first text box');
  });

  test('highlighter, text box, pen, highlighter, text box: in order', () {
    final page = EditorPage();
    final hl1 = _line(.highlighter, _yellow, const Offset(50, 140), const Offset(500, 140), 30);
    _write(page, hl1);
    page.putImagesInFront([_box(const Rect.fromLTWH(100, 100, 300, 80))], layer: 0);
    final pen = _line(.fountainPen, Colors.blue, const Offset(50, 150), const Offset(500, 150), 4);
    _write(page, pen);
    final hl2 = _line(.highlighter, _yellow, const Offset(50, 160), const Offset(500, 160), 30);
    _write(page, hl2);
    page.putImagesInFront([_box(const Rect.fromLTWH(150, 110, 300, 80))], layer: 0);
    expect(_tier(page, hl1), 0, reason: 'under both boxes');
    expect(_tier(page, pen), 1, reason: 'over the first box');
    expect(_tier(page, hl2), 1, reason: 'over the first box, under the second');
  });

  test('writing away from the pictures stays in the first gap', () {
    final page = EditorPage();
    page.putImagesInFront([_box(const Rect.fromLTWH(100, 100, 300, 80))], layer: 0);
    final far = _line(.fountainPen, Colors.blue, const Offset(50, 900), const Offset(500, 900), 4);
    _write(page, far);
    expect(_tier(page, far), 0);
  });

  test('a note from before the order was kept looks as it did', () {
    final page = EditorPage();
    final box = _box(const Rect.fromLTWH(100, 100, 300, 80));
    final under = _line(.fountainPen, Colors.blue, const Offset(130, 140), const Offset(370, 140), 4)
      ..onFrontImage = false;
    final over = _line(.fountainPen, Colors.blue, const Offset(130, 150), const Offset(370, 150), 4)
      ..onFrontImage = true;
    page.strokes.addAll([under, over]);
    // saved before: in front, no order, writing without afterImage
    box
      ..inFront = true
      ..order = 0;
    page.images.add(box);
    expect(_tier(page, under), 0);
    expect(_tier(page, over), 1);
  });

  test('the order is saved', () {
    final stroke = _line(.fountainPen, Colors.blue, Offset.zero, const Offset(10, 0), 4)
      ..afterImage = 1234;
    final loaded = Stroke.fromJson(
      stroke.toJson(),
      fileVersion: 19,
      pageIndex: 0,
      page: const HasSize(Size(1000, 1400)),
    );
    expect(loaded.afterImage, 1234);
    expect(stroke.copy().afterImage, 1234);
  });

  testWidgets('painted: box 1, highlighter on it, box 2 over that', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final page = EditorPage();
      final box1 = _box(const Rect.fromLTWH(100, 100, 300, 80));
      page.putImagesInFront([box1], layer: 0);
      final hl = _line(.highlighter, _yellow, const Offset(130, 140), const Offset(370, 140), 30);
      _write(page, hl);
      final box2 = _box(const Rect.fromLTWH(200, 120, 300, 80));
      page.putImagesInFront([box2], layer: 0);
      final front = EditorPage.inOrder(page.images.where((i) => i.inFront));

      // as the page is built: the ink of each gap, each picture (here a
      // plain colour) over the gap before it
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)..scale(0.5);
      canvas.drawColor(Colors.white, BlendMode.src);
      const boxColours = [Color(0xFF9CC7F0), Color(0xFFB6E0B0)];
      for (int tier = 0; tier <= front.length; tier++) {
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
          currentScale: 1,
          defaultTextStyle: const TextStyle(),
          paintOverlays: false,
          tier: tier,
          frontImages: front,
          topTier: tier == front.length,
        ).paint(canvas, page.size);
        if (tier < front.length) {
          canvas.drawRect(front[tier].dstRect, Paint()..color = boxColours[tier]);
        }
      }
      final image = await recorder.endRecording().toImage(500, 700);
      final bytes = (await image.toByteData())!;
      image.dispose();
      Color at(Offset p) {
        final i = ((p.dy / 2).round() * 500 + (p.dx / 2).round()) * 4;
        return Color.fromARGB(
          bytes.getUint8(i + 3),
          bytes.getUint8(i),
          bytes.getUint8(i + 1),
          bytes.getUint8(i + 2),
        );
      }

      // on box 1 alone: the highlighter shows over it (yellowish)
      final onBox1 = at(const Offset(150, 140));
      expect((onBox1.b * 255).round(), lessThan(150), reason: 'over box 1: $onBox1');
      // where box 2 covers it: box 2's plain green, no yellow
      final onBox2 = at(const Offset(300, 140));
      expect(onBox2, const Color(0xFFB6E0B0), reason: 'under box 2: $onBox2');
    });
  });
}
