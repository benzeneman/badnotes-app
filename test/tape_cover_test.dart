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

Future<ByteData> _paint(EditorPage page, InkCache? cache) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
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
    currentScale: 1,
    defaultTextStyle: const TextStyle(),
    paintOverlays: false,
    inkCache: cache,
    pixelScale: 1,
  ).paint(canvas, page.size);
  final image = await recorder.endRecording().toImage(500, 500);
  final bytes = (await image.toByteData())!;
  image.dispose();
  return bytes;
}

Color _at(ByteData bytes, Offset p) {
  final i = (p.dy.round() * 500 + p.dx.round()) * 4;
  return Color.fromARGB(
    bytes.getUint8(i + 3),
    bytes.getUint8(i),
    bytes.getUint8(i + 1),
    bytes.getUint8(i + 2),
  );
}

bool _near(Color a, Color b) =>
    (a.r - b.r).abs() < 0.08 &&
    (a.g - b.g).abs() < 0.08 &&
    (a.b - b.b).abs() < 0.08;

void main() {
  testWidgets('tape covers ink and highlighter under it; writing on it is '
      'on it; peeking hides the writing and shows what is under', (
    tester,
  ) async {
    await tester.runAsync(() async {
      const tapeColor = Color(0xFF2E7D32);
      final page = EditorPage();
      // a word, highlighted, and ink written over the highlighter
      final word = _line(
        .fountainPen,
        Colors.black,
        const Offset(100, 200),
        const Offset(400, 200),
        8,
      );
      final marker = _line(
        .highlighter,
        Colors.yellow.withAlpha(140),
        const Offset(100, 230),
        const Offset(400, 230),
        30,
      );
      final over = _line(
        .fountainPen,
        Colors.red,
        const Offset(100, 232),
        const Offset(400, 232),
        8,
      );
      // as the tape tool makes it: not marked as keeping its order
      final tape = _line(
        .tape,
        tapeColor,
        const Offset(80, 215),
        const Offset(420, 215),
        70,
      )..nib2 = false;
      // written on the tape afterwards
      final note = _line(
        .fountainPen,
        Colors.blue,
        const Offset(150, 210),
        const Offset(350, 210),
        8,
      );
      for (final stroke in [word, marker, over, tape, note]) {
        page.insertStroke(stroke);
      }

      for (final cache in [null, InkCache()]) {
        var shown = await _paint(page, cache);
        final what = cache == null ? 'drawn' : 'from images';
        // the word, the highlighter and the ink over it are covered
        for (final p in const [Offset(300, 200), Offset(300, 230)]) {
          expect(
            _near(_at(shown, p), tapeColor),
            isTrue,
            reason: '$what: covered at $p, was ${_at(shown, p)}',
          );
        }
        // the note written on it shows, over it
        expect(
          _near(_at(shown, const Offset(250, 210)), Colors.blue),
          isTrue,
          reason: '$what: the note on the tape',
        );

        tape.tapeRevealed = true;
        shown = await _paint(page, cache);
        // peeking: the word shows, the note doesn't
        // (under the tape, faint now)
        expect(
          _at(shown, const Offset(300, 200)).computeLuminance(),
          lessThan(0.1),
          reason: '$what: the word, peeking',
        );
        final note2 = _at(shown, const Offset(250, 210));
        expect(
          _near(note2, Colors.blue),
          isFalse,
          reason: '$what: the note is hidden while peeking',
        );
        tape.tapeRevealed = false;
        cache?.dispose();
      }
    });
  });

  test('what is written on a tape, and what is under it', () {
    Stroke pen(Offset a, Offset b) =>
        _line(.ballpointPen, Colors.black, a, b, 3);
    final under = pen(const Offset(0, 50), const Offset(200, 50));
    final tape = _line(
      .tape,
      Colors.green,
      const Offset(0, 50),
      const Offset(200, 50),
      40,
    );
    final on = pen(const Offset(20, 45), const Offset(180, 55));
    final away = pen(const Offset(0, 300), const Offset(200, 300));
    final (tapes, onTape) = CanvasPainter.tapesOf([under, tape, on, away]);
    expect(tapes, [tape]);
    expect(onTape[tape], [on]);
  });
}
