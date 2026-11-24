import 'dart:typed_data';
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
        options: StrokeOptions(size: size, isComplete: true),
        pageIndex: 0,
        page: const HasSize(Size(1000, 1400)),
        toolId: tool,
      )
      ..nib2 = true
      ..addPoints([for (int i = 0; i <= 20; i++) Offset.lerp(a, b, i / 20)!]);

/// A text box (stored as an SVG picture) at [rect].
SvgEditorImage _textBox(Rect rect) {
  final core = EditorCoreInfo(filePath: '');
  return SvgEditorImage(
    id: rect.hashCode,
    svgString: '<svg height="40" width="200"></svg>',
    svgFile: null,
    pageIndex: 0,
    pageSize: EditorPage.defaultSize,
    onMoveImage: null,
    onDeleteImage: null,
    onMiscChange: null,
    assetCache: core.assetCache,
  )..dstRect = rect;
}

/// What a painter shows: the ink under the pictures ([onFront] false), over
/// them (true), or the page with no pictures (null).
Future<ByteData> _paint(EditorPage page, {bool? onFront}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
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
    pixelScale: 1,
    onFrontImages: onFront,
  ).paint(canvas, page.size);
  final image = await recorder.endRecording().toImage(500, 500);
  final bytes = (await image.toByteData())!;
  image.dispose();
  return bytes;
}

int _alphaAt(ByteData bytes, Offset p) =>
    bytes.getUint8((p.dy.round() * 500 + p.dx.round()) * 4 + 3);

void main() {
  setUp(FlavorConfig.setup);

  test('highlighter keeps the order it was drawn in with a text box', () {
    final page = EditorPage();
    final before = _line(
      .highlighter,
      Colors.yellow,
      const Offset(80, 120),
      const Offset(420, 120),
      30,
    );
    page.insertStroke(before);
    // a text box written over the highlighter: over it
    page.putImagesInFront([
      _textBox(const Rect.fromLTWH(100, 100, 200, 40)),
    ], layer: 0);
    expect(page.isOnFrontImage(before), isFalse, reason: 'under the text');

    // highlighter drawn over the text afterwards, sticking out past it
    final after = _line(
      .highlighter,
      Colors.yellow,
      const Offset(80, 120),
      const Offset(420, 120),
      30,
    );
    after.onFrontImage = page.drawsOverFrontImages(after);
    page.insertStroke(after);
    expect(page.isOnFrontImage(after), isTrue, reason: 'over the text');

    // and a text box put over that again covers it
    page.putImagesInFront([
      _textBox(const Rect.fromLTWH(150, 100, 200, 40)),
    ], layer: 0);
    expect(page.isOnFrontImage(after), isFalse, reason: 'under the new text');
  });

  test('a text box put on a tape is on it, and hidden while peeking', () {
    final page = EditorPage();
    final tape = _line(
      .tape,
      Colors.green,
      const Offset(50, 300),
      const Offset(450, 300),
      60,
    );
    // text before the tape: under it, so the tape covers it
    final under = _textBox(const Rect.fromLTWH(100, 360, 200, 40));
    page.putImagesInFront([under], layer: 0);
    page.insertStroke(tape);
    final on = _textBox(const Rect.fromLTWH(100, 280, 200, 40));
    page.putImagesInFront([on], layer: 0);

    expect(under.onTape, isFalse);
    expect(on.onTape, isTrue);
    expect(page.isUnderPeek(on), isFalse);
    tape.tapeRevealed = true;
    expect(page.isUnderPeek(on), isTrue, reason: 'peeking hides it');
    expect(page.isUnderPeek(under), isFalse);
  });

  testWidgets('with text boxes on the page, the tape is drawn over them', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final page = EditorPage();
      page.putImagesInFront([
        _textBox(const Rect.fromLTWH(100, 280, 200, 40)),
      ], layer: 0);
      page.insertStroke(
        _line(
          .tape,
          Colors.green,
          const Offset(50, 300),
          const Offset(450, 300),
          60,
        ),
      );
      const middle = Offset(200, 300);
      // the painter under the pictures leaves the tape out...
      expect(_alphaAt(await _paint(page, onFront: false), middle), 0);
      // ...and the one over them draws it, covering the text box
      expect(
        _alphaAt(await _paint(page, onFront: true), middle),
        greaterThan(200),
      );
    });
  });
}
