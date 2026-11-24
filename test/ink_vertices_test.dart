import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:sbn/has_size.dart';
import 'package:sbn/tool_id.dart';

Stroke _line(ToolId tool, {bool pressure = false, int points = 120}) =>
    Stroke(
      color: Colors.black,
      pressureEnabled: pressure,
      options: StrokeOptions(size: 6, isComplete: true),
      pageIndex: 0,
      page: const HasSize(Size(400, 400)),
      toolId: tool,
    )..addPoints([
      for (var i = 0; i < points; i++)
        Offset(
          40 + i * 312 / points,
          200 + 80 * sin(i * 10 / points) + (i > points / 2 ? 30 : 0),
        ),
    ]);

/// How many pixels [draw] inks on a 400x400 image.
Future<int> _inked(void Function(Canvas canvas) draw) async {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  final image = await recorder.endRecording().toImage(400, 400);
  final bytes = (await image.toByteData())!;
  image.dispose();
  var inked = 0;
  for (var i = 3; i < bytes.lengthInBytes; i += 4) {
    if (bytes.getUint8(i) > 127) inked++;
  }
  return inked;
}

void main() {
  group('Ink as triangles', () {
    test('the pens, not the highlighter, pencil or calligraphy pen', () {
      expect(_line(ToolId.ballpointPen).inkVertices, isNotNull);
      // handwriting in fountain or brush pen is its outline; only a very
      // long line is triangles
      expect(_line(ToolId.fountainPen).inkVertices, isNull);
      expect(_line(ToolId.brushPen).inkVertices, isNull);
      expect(_line(ToolId.fountainPen, points: 2200).inkVertices, isNotNull);
      expect(_line(ToolId.brushPen, points: 2200).inkVertices, isNotNull);
      expect(_line(ToolId.highlighter).inkVertices, isNull);
      expect(_line(ToolId.pencil).inkVertices, isNull);
      expect(_line(ToolId.calligraphyPen).inkVertices, isNull);
    });

    test('kept until the stroke changes', () {
      final stroke = _line(ToolId.ballpointPen);
      final first = stroke.inkVertices;
      expect(identical(first, stroke.inkVertices), isTrue);
      stroke.shift(const Offset(5, 0));
      expect(identical(first, stroke.inkVertices), isFalse);
    });

    for (final tool in [
      ToolId.ballpointPen,
      ToolId.fountainPen,
      ToolId.brushPen,
    ])
      testWidgets('covers about what the outline did: ${tool.name}', (
        tester,
      ) async {
        final stroke = _line(tool, points: 2200)..nib2 = true;
        final paint = Paint()..color = Colors.black;
        final (fromPath, fromTriangles) = await tester.runAsync(
          () async => (
            await _inked((c) => c.drawPath(stroke.highQualityPath, paint)),
            await _inked(
              (c) =>
                  c.drawVertices(stroke.inkVertices!, BlendMode.srcOver, paint),
            ),
          ),
        ) as (int, int);
        expect(fromPath, greaterThan(500));
        expect(
          (fromTriangles - fromPath).abs() / fromPath,
          lessThan(0.1),
          reason: 'path $fromPath px, triangles $fromTriangles px',
        );
      });

    test('a ballpoint\'s stabilization shows', () {
      Stroke jittery(double stabilization) =>
          Stroke(
              color: Colors.black,
              pressureEnabled: false,
              options: StrokeOptions(
                size: 3,
                streamline: stabilization,
                isComplete: true,
              ),
              pageIndex: 0,
              page: const HasSize(Size(400, 400)),
              toolId: ToolId.ballpointPen,
            )
            ..nib2 = true
            ..steadyLine = true
            ..addPoints([
              for (var i = 0; i < 200; i++)
                Offset(40 + i * 0.8, 200 + (i.isEven ? 2.5 : -2.5)),
            ]);
      // how far the line strays in the middle (the ends are where the
      // pen was either way)
      double shake(Stroke stroke) => stroke.highQualityPolygon
          .where((p) => p.dx > 90 && p.dx < 150)
          .map((p) => (p.dy - 200).abs())
          .fold(0.0, (a, b) => a > b ? a : b);
      // the shake smoothed away at 95%, kept at 0%
      expect(shake(jittery(0)), greaterThan(shake(jittery(0.95)) + 0.5));
    });

    test('the pens\' stabilization grows with its setting (steady2)', () {
      Stroke jittery(double stabilization, {required bool steady2}) =>
          Stroke(
              color: Colors.black,
              pressureEnabled: false,
              options: StrokeOptions(
                size: 5,
                streamline: stabilization,
                isComplete: true,
              ),
              pageIndex: 0,
              page: const HasSize(Size(400, 400)),
              toolId: ToolId.ballpointPen,
            )
            ..nib2 = true
            ..steadyLine = true
            ..steady2 = steady2
            ..addPoints([
              // a hand shaking 4 units either way while writing a line
              for (var i = 0; i < 200; i++)
                Offset(40 + i * 1.5, 200 + (i.isEven ? 4 : -4)),
            ]);
      double shake(Stroke stroke) => stroke.highQualityPolygon
          .where((p) => p.dx > 120 && p.dx < 260)
          .map((p) => (p.dy - 200).abs())
          .fold(0.0, (a, b) => a > b ? a : b);

      final none = shake(jittery(0, steady2: true));
      final some = shake(jittery(0.4, steady2: true));
      final full = shake(jittery(1, steady2: true));
      final oldFull = shake(jittery(1, steady2: false));
      // 0% keeps the shake; 40% already takes a clear part of it; 100%
      // takes much more than the old, two-pen-widths leash did
      expect(none, greaterThan(some + 1), reason: '0%: $none, 40%: $some');
      expect(some, greaterThan(full), reason: '40%: $some, 100%: $full');
      expect(full, lessThan(oldFull * 0.8), reason: 'new $full, old $oldFull');
      // and old strokes keep their look: steady2 off is the old line
      expect(
        shake(jittery(0.4, steady2: false)),
        isNot(closeTo(some, 1e-6)),
      );
    });

    testWidgets('a piece the eraser leaves keeps the ink it had', (
      tester,
    ) async {
      final stroke =
          Stroke(
              color: Colors.black,
              pressureEnabled: false,
              options: StrokeOptions(size: 4, isComplete: true),
              pageIndex: 0,
              page: const HasSize(Size(400, 400)),
              toolId: ToolId.fountainPen,
            )
            ..nib2 = true
            ..addPoints([
              // each piece left still long enough for triangles
              for (var i = 0; i < 4600; i++)
                Offset(20 + i * 0.078, 200 + 60 * sin(i / 230)),
            ]);
      // drawn once, as it is on the page before the eraser comes
      expect(stroke.inkVertices, isNotNull);
      final pieces = stroke.eraseAlong(
        const Offset(200, 100),
        const Offset(200, 300),
        6,
      )!;
      expect(pieces, hasLength(2));
      final paint = Paint()..color = Colors.black;
      for (final piece in pieces) {
        final fresh = piece.copy();
        expect(piece.inkVertices, isNotNull);
        expect(piece.inkFromCut, isTrue);
        final (reused, whole) = await tester.runAsync(
          () async => (
            await _inked(
              (c) =>
                  c.drawVertices(piece.inkVertices!, BlendMode.srcOver, paint),
            ),
            await _inked(
              (c) =>
                  c.drawVertices(fresh.inkVertices!, BlendMode.srcOver, paint),
            ),
          ),
        ) as (int, int);
        expect(whole, greaterThan(300));
        expect(
          (reused - whole).abs() / whole,
          lessThan(0.05),
          reason: 'kept $reused px, worked out again $whole px',
        );
      }
    });

    // Beads: a fountain pen line drawn as triangles came out thicker in
    // places than its outline, round dots at its bends. The triangles are
    // the outline's own now: nearly every pixel the same.
    for (final complete in [true, false])
      testWidgets('a fountain pen line is its outline, no beads '
          '(${complete ? 'finished' : 'being written'})', (tester) async {
        final stroke =
            Stroke(
                color: Colors.black,
                pressureEnabled: false,
                options: StrokeOptions(size: 5, isComplete: complete),
                pageIndex: 0,
                page: const HasSize(Size(400, 400)),
                toolId: ToolId.fountainPen,
              )
              ..nib2 = true
              ..speedInk = true
              ..addPoints([
                // loops and a sharp turn, like handwriting
                // (long enough to be drawn as triangles)
                for (var i = 0; i < 2200; i++)
                  Offset(
                    60 + i * 0.116 + 25 * sin(i / 82),
                    200 +
                        50 * cos(i / 124) +
                        (i > 1375 ? (i - 1375) * 0.087 : 0),
                  ),
              ]);
        final paint = Paint()..color = Colors.black;
        Future<Uint8List> pixels(void Function(Canvas c) draw) async {
          final recorder = ui.PictureRecorder();
          draw(Canvas(recorder)..scale(2));
          final image = await recorder.endRecording().toImage(800, 800);
          final bytes = (await image.toByteData())!.buffer.asUint8List();
          image.dispose();
          return bytes;
        }

        final (outline, triangles) = await tester.runAsync(
          () async => (
            await pixels((c) => c.drawPath(stroke.highQualityPath, paint)),
            await pixels(
              (c) =>
                  c.drawVertices(stroke.inkVertices!, BlendMode.srcOver, paint),
            ),
          ),
        ) as (Uint8List, Uint8List);
        var inked = 0, differ = 0;
        for (var i = 3; i < outline.length; i += 4) {
          final a = outline[i] > 127, b = triangles[i] > 127;
          if (a) inked++;
          if (a != b) differ++;
        }
        expect(inked, greaterThan(1000));
        expect(
          differ / inked,
          lessThan(0.06),
          reason: '$differ of $inked pixels differ',
        );
      });

    // Beads at sharp turns: the pen library's round turns, filled as one
    // outline, cancel out and come to a point; as triangles they were round
    // knobs. Checked a small square at a time, so one knob shows.
    for (final complete in [true, false])
      testWidgets('sharp turns come to a point, no knobs '
          '(${complete ? 'finished' : 'being written'})', (tester) async {
        final stroke =
            Stroke(
                color: Colors.black,
                pressureEnabled: false,
                options: StrokeOptions(size: 5, isComplete: complete),
                pageIndex: 0,
                page: const HasSize(Size(400, 400)),
                toolId: ToolId.fountainPen,
              )
              ..nib2 = true
              ..speedInk = true
              ..addPoints([
                // up and down like l l l: the line doubles back at each top
                // (long enough to be drawn as triangles)
                for (var i = 0; i < 2200; i++)
                  Offset(
                    40 + i * 0.145,
                    200 + 90 * (1 - 2 * (((i / 275) % 2) - 1).abs()),
                  ),
              ]);
        final paint = Paint()..color = Colors.black;
        Future<(Uint8List, ui.Image)> draw(void Function(Canvas c) how) async {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder)
            ..drawColor(Colors.white, BlendMode.src)
            ..scale(2);
          how(canvas);
          final image = await recorder.endRecording().toImage(800, 800);
          final bytes = (await image.toByteData())!.buffer.asUint8List();
          return (bytes, image);
        }

        await tester.runAsync(() async {
          final (outline, outlineImage) = await draw(
            (c) => c.drawPath(stroke.highQualityPath, paint),
          );
          final (triangles, trianglesImage) = await draw(
            (c) =>
                c.drawVertices(stroke.inkVertices!, BlendMode.srcOver, paint),
          );
          final out = Platform.environment['INK_PNG'];
          if (out != null) {
            final name = complete ? 'finished' : 'writing';
            for (final (image, kind) in [
              (outlineImage, 'outline'),
              (trianglesImage, 'triangles'),
            ]) {
              final png = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              File('$out/$name-$kind.png')
                ..createSync(recursive: true)
                ..writeAsBytesSync(png!.buffer.asUint8List());
            }
          }
          outlineImage.dispose();
          trianglesImage.dispose();

          bool inked(Uint8List b, int i) => b[i] < 128; // red, on white
          var worst = 0, worstAt = '';
          for (var by = 0; by < 800; by += 16) {
            for (var bx = 0; bx < 800; bx += 16) {
              var differ = 0;
              for (var y = by; y < by + 16; y++) {
                for (var x = bx; x < bx + 16; x++) {
                  final i = (y * 800 + x) * 4;
                  if (inked(outline, i) != inked(triangles, i)) differ++;
                }
              }
              if (differ > worst) (worst, worstAt) = (differ, '($bx, $by)');
            }
          }
          expect(
            worst,
            lessThan(16 * 16 ~/ 5),
            reason: '$worst of 256 pixels differ in the square at $worstAt',
          );
        });
      });
    // Beads along a long line: drawn in pieces (zoomed in, or while being
    // written), each piece began at full width and thinned again. The
    // pieces together are the line drawn whole.
    testWidgets('a long fountain pen line in pieces is the line, no beads', (
      tester,
    ) async {
      final stroke =
          Stroke(
              color: Colors.black,
              pressureEnabled: false,
              options: StrokeOptions(size: 5, thinning: 1, isComplete: true),
              pageIndex: 0,
              page: const HasSize(Size(400, 400)),
              toolId: ToolId.fountainPen,
            )
            ..nib2 = true
            ..speedInk = true
            ..addPoints([
              // quick handwriting loops: fast enough to thin
              for (var i = 0; i < 700; i++)
                Offset(30 + i * 0.48 + 22 * sin(i / 9), 200 + 70 * cos(i / 13)),
            ]);
      final pieces = stroke.areaPieces!;
      expect(pieces.length, greaterThan(3));
      final paint = Paint()..color = Colors.black;
      Future<(Uint8List, ui.Image)> draw(void Function(Canvas c) how) async {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder)
          ..drawColor(Colors.white, BlendMode.src)
          ..scale(2);
        how(canvas);
        final image = await recorder.endRecording().toImage(800, 800);
        final bytes = (await image.toByteData())!.buffer.asUint8List();
        return (bytes, image);
      }

      await tester.runAsync(() async {
        final (whole, wholeImage) = await draw(
          (c) => c.drawPath(stroke.highQualityPath, paint),
        );
        final (pieced, piecedImage) = await draw((c) {
          for (final piece in pieces) {
            c.drawPath(piece.path, paint);
          }
        });
        final out = Platform.environment['INK_PNG'];
        if (out != null) {
          for (final (image, kind) in [
            (wholeImage, 'whole'),
            (piecedImage, 'pieces'),
          ]) {
            final png = await image.toByteData(format: ui.ImageByteFormat.png);
            File('$out/long-$kind.png')
              ..createSync(recursive: true)
              ..writeAsBytesSync(png!.buffer.asUint8List());
          }
        }
        wholeImage.dispose();
        piecedImage.dispose();
        var worst = 0, worstAt = '';
        for (var by = 0; by < 800; by += 16) {
          for (var bx = 0; bx < 800; bx += 16) {
            var differ = 0;
            for (var y = by; y < by + 16; y++) {
              for (var x = bx; x < bx + 16; x++) {
                final i = (y * 800 + x) * 4;
                if ((whole[i] < 128) != (pieced[i] < 128)) differ++;
              }
            }
            if (differ > worst) (worst, worstAt) = (differ, '($bx, $by)');
          }
        }
        expect(
          worst,
          lessThan(16 * 16 ~/ 8),
          reason: '$worst of 256 pixels differ in the square at $worstAt',
        );
      });
    });

    test('a quick line starts at the width it moves off at, no blob', () {
      final stroke =
          Stroke(
              color: Colors.black,
              pressureEnabled: false,
              options: StrokeOptions(size: 5, thinning: 1, isComplete: true),
              pageIndex: 0,
              page: const HasSize(Size(400, 400)),
              toolId: ToolId.fountainPen,
            )
            ..nib2 = true
            ..speedInk = true
            ..addPoints([
              for (var i = 0; i < 60; i++) Offset(40 + i * 7.0, 200),
            ]);
      final widths = stroke.nibPressures;
      expect(widths.first, closeTo(widths[30], 0.02));
    });
  });
}
