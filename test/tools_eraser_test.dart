import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:badnotes/data/editor/editor_history.dart';
import 'package:badnotes/data/flavor_config.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/tools/eraser.dart';
import 'package:sbn/has_size.dart';

Stroke _line(Offset a, Offset b) => Stroke(
  color: Stroke.defaultColor,
  pressureEnabled: false,
  options: StrokeOptions(size: 1, isComplete: true),
  pageIndex: 0,
  page: const HasSize(Size(500, 500)),
  toolId: .fountainPen,
)..addPoints([a, b, b]);

void main() {
  setUp(FlavorConfig.setup);

  test('stroke eraser removes touched strokes whole', () {
    Eraser.type = EraserType.stroke;
    final hit = _line(const Offset(0, 50), const Offset(400, 50));
    final far = _line(const Offset(0, 300), const Offset(400, 300));
    final strokes = [hit, far];
    // eraser crosses the middle of the long line, far from its points
    Eraser().erase(strokes, const Offset(200, 0), const Offset(200, 100), 1);
    expect(strokes, [far]);
    expect(Eraser().onDragEnd(), isNull); // new eraser, nothing recorded
  });

  test('precise eraser cuts a stroke in two', () {
    Eraser.type = EraserType.precision;
    final eraser = Eraser();
    final strokes = [_line(const Offset(0, 50), const Offset(400, 50))];
    eraser.erase(strokes, const Offset(200, 0), const Offset(200, 100), 1);
    expect(strokes.length, 2);
    final change = eraser.onDragEnd();
    expect(change, isA<HistoricReplace>());
  });

  group('Highlighter', () {
    Stroke filled() =>
        Stroke(
          color: Colors.yellow.withAlpha(100),
          pressureEnabled: false,
          options: StrokeOptions(size: 20, streamline: 0.8, isComplete: true),
          pageIndex: 0,
          page: const HasSize(Size(500, 500)),
          toolId: .highlighter,
        )..addPoints([
          // back and forth, filling a box
          for (int i = 0; i < 6; i++) ...[
            Offset(i.isEven ? 0 : 200, 10 + i * 16.0),
            Offset(i.isEven ? 200 : 0, 18 + i * 16.0),
          ],
        ]);

    test('stretched taller, it widens by as much', () {
      expect(filled().stretchAcross(1, 2), closeTo(2, 0.05));
      expect(filled().stretchAcross(2, 1), closeTo(1, 0.05));
    });

    test('the precise eraser rubs out every one under it at once', () {
      Eraser.type = EraserType.precision;
      // the same highlighter, over itself four times
      final strokes = [filled(), filled(), filled(), filled()];
      final eraser = Eraser();
      eraser.erase(strokes, const Offset(100, -10), const Offset(100, 120), 1);
      expect(strokes, hasLength(4)); // still whole strokes, as one layer
      for (final stroke in strokes) {
        expect(stroke.holes, isNotEmpty);
        // a straight line of holes down the eraser's way
        for (final hole in stroke.holes) {
          expect(hole.center.dx, closeTo(100, 0.01));
        }
      }
      expect(eraser.onDragEnd(), isA<HistoricReplace>());
    });

    test('the stroke eraser takes it whole', () {
      Eraser.type = EraserType.stroke;
      final strokes = [filled()];
      Eraser().erase(
        strokes,
        const Offset(100, -10),
        const Offset(100, 120),
        1,
      );
      expect(strokes, isEmpty);
    });

    test('old holes are drawn clipped to what they leave', () {
      final stroke = filled()
        ..holes = [(center: const Offset(100, 20), radius: 3.0)];
      final area = stroke.bounds.inflate(stroke.options.size + 2);
      final kept = stroke.keptRegion(area)!;
      expect(kept.contains(const Offset(100, 20)), isFalse);
      expect(kept.contains(area.topLeft + const Offset(1, 1)), isTrue);
      // worked out once, and a copy (as the eraser makes) reuses it
      expect(identical(stroke.keptRegion(area), kept), isTrue);
      expect(identical(stroke.copy().keptRegion(area), kept), isTrue);
    });

    test('old holes across a pen stroke become cuts when loaded', () {
      final stroke = Stroke(
        color: Colors.black,
        pressureEnabled: false,
        options: StrokeOptions(size: 20, isComplete: true),
        pageIndex: 0,
        page: const HasSize(Size(500, 500)),
        toolId: .fountainPen,
      )..addPoints([const Offset(0, 50), const Offset(200, 50)]);
      stroke.holes = [
        // an old standard eraser cut, straight down the middle
        for (double y = 0; y <= 110; y += 4)
          (center: Offset(100, y), radius: 13.0),
        // and a small precision hole elsewhere
        (center: const Offset(20, 10), radius: 3.0),
      ];
      final pieces = stroke.withoutWideHoles();
      expect(pieces.length, greaterThan(1));
      for (final piece in pieces) {
        expect(piece.holes, hasLength(1)); // only the small one is left
        for (final p in piece.centerPoints) {
          expect((p.dx - 100).abs(), greaterThan(12));
        }
      }
    });

    test('a stroke without wide holes stays as it is', () {
      final stroke = filled()
        ..holes = [(center: const Offset(20, 10), radius: 3.0)];
      expect(stroke.withoutWideHoles().single, same(stroke));
      // and highlighter keeps its holes: they're drawn into its layer
      final rubbed = filled()
        ..holes = [(center: const Offset(100, 20), radius: 30.0)];
      expect(rubbed.withoutWideHoles().single, same(rubbed));
      final plain = filled();
      expect(plain.withoutWideHoles().single, same(plain));
    });

    test('a saved standard eraser is the precise one now', () {
      stows.eraserType.value = 1;
      expect(Eraser.type, EraserType.precision);
      stows.eraserType.value = 2;
      expect(Eraser.type, EraserType.stroke);
      Eraser.type = EraserType.precision;
      expect(stows.eraserType.value, 0);
    });

    test('the eraser filter without highlighter leaves it alone', () {
      final filter = stows.eraserFilter.value;
      addTearDown(() => stows.eraserFilter.value = filter);
      stows.eraserFilter.value = ['pen', 'pencil', 'tape'];
      for (final type in EraserType.values) {
        Eraser.type = type;
        final marker = filled();
        final strokes = [marker];
        Eraser().erase(
          strokes,
          const Offset(100, -10),
          const Offset(100, 120),
          1,
        );
        expect(strokes, [marker], reason: '$type');
        expect(marker.holes, isEmpty, reason: '$type');
      }
    });
  });
}
