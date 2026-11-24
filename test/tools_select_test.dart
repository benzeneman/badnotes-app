import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:badnotes/components/canvas/_asset_cache.dart';
import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:badnotes/components/canvas/image/editor_image.dart';
import 'package:badnotes/data/flavor_config.dart';
import 'package:badnotes/data/tools/select.dart';
import 'package:sbn/has_size.dart';

void main() {
  setUp(FlavorConfig.setup);

  group('Select tool', () {
    test('selects the right strokes', () async {
      final select = Select.currentSelect;
      final options = StrokeOptions(size: 9);

      // Drag gesture in a 10x10 square shape, on page 0
      select.onDragStart(Offset.zero, 0);
      select.onDragUpdate(const Offset(0, 10));
      select.onDragUpdate(const Offset(10, 10));
      select.onDragUpdate(const Offset(10, 0));

      expect(
        select.selectResult.pageIndex,
        0,
        reason: 'The page index should be 0',
      );

      const page = HasSize(Size(100, 100));

      final strokes = <Stroke>[
        // index 0 is inside
        Stroke(
          color: Stroke.defaultColor,
          pressureEnabled: Stroke.defaultPressureEnabled,
          options: options,
          pageIndex: 0,
          page: page,
          toolId: .fountainPen,
        )..addPoint(const Offset(5, 5)),
        // index > 0 is outside
        Stroke(
          color: Stroke.defaultColor,
          pressureEnabled: Stroke.defaultPressureEnabled,
          options: options,
          pageIndex: 0,
          page: page,
          toolId: .fountainPen,
        )..addPoint(const Offset(12, 12)),
        Stroke(
          color: Stroke.defaultColor,
          pressureEnabled: Stroke.defaultPressureEnabled,
          options: options,
          pageIndex: 0,
          page: page,
          toolId: .fountainPen,
        )..addPoint(const Offset(15, 15)),
      ];

      select.onDragEnd(strokes, const []);

      expect(
        select.selectResult.strokes,
        hasLength(1),
        reason: 'Only one stroke should be selected',
      );
      expect(
        select.selectResult.strokes.first,
        strokes[0],
        reason: 'The first stroke should be selected',
      );
      expect(
        select.selectResult.images,
        isEmpty,
        reason: 'No images should be selected',
      );
    });

    test('selects a line that only crosses the lasso', () {
      expect(
        Select.lineTouches(Path()..addRect(const Rect.fromLTWH(40, 40, 20, 20)), const [
          Offset(0, 50),
          Offset(100, 50),
        ]),
        isTrue,
      );
      expect(
        Select.lineTouches(Path()..addRect(const Rect.fromLTWH(40, 40, 20, 20)), const [
          Offset(0, 90),
          Offset(100, 90),
        ]),
        isFalse,
      );
    });

    test('selects a thick stroke whose outline pokes out of the lasso', () {
      final select = Select.currentSelect;
      select.onDragStart(Offset.zero, 0);
      select.onDragUpdate(const Offset(0, 100));
      select.onDragUpdate(const Offset(100, 100));
      select.onDragUpdate(const Offset(100, 0));

      final thick = Stroke(
        color: Stroke.defaultColor,
        pressureEnabled: false,
        options: StrokeOptions(size: 50, isComplete: true),
        pageIndex: 0,
        page: const HasSize(Size(200, 200)),
        toolId: .highlighter,
      )..addPoints(const [Offset(10, 90), Offset(50, 90), Offset(90, 90)]);

      select.onDragEnd([thick], const []);
      expect(select.selectResult.strokes, [thick]);
    });

    test('scribble detection and prediction', () {
      Stroke line(List<Offset> points) => Stroke(
        color: Stroke.defaultColor,
        pressureEnabled: false,
        options: StrokeOptions(size: 5),
        pageIndex: 0,
        page: const HasSize(Size(500, 500)),
        toolId: .ballpointPen,
      )..addPoints(points);

      final straight = [for (int x = 0; x < 200; x += 10) Offset(x + 0.0, 50)];
      final zigzag = [
        for (int pass = 0; pass < 8; pass++)
          for (int i = 0; i <= 10; i++)
            Offset(pass.isEven ? i * 10.0 : 100 - i * 10.0, pass * 2.0),
      ];
      // "www": sharp turns, but it moves across the page as it goes
      final www = [
        for (int i = 0; i < 24; i++)
          Offset(i * 8.0, i % 4 < 2 ? (i % 4) * 16.0 : (4 - i % 4) * 16.0),
      ];

      expect(line(straight).isScribble, isFalse);
      expect(line(zigzag).isScribble, isTrue);
      expect(line(www).isScribble, isFalse);

      // a fast segment crossing a long line, with no point near it
      final crossed = line(const [Offset(0, 50), Offset(200, 50), Offset(200, 50)]);
      expect(crossed.touchedBy(const Offset(100, 0), const Offset(100, 100), 1), isTrue);

      final predicting = line(straight)..predictNextPoint();
      expect(predicting.highQualityPolygon, isNotEmpty);
    });

    test('selects the right images', () async {
      final select = Select.currentSelect;

      // Drag gesture in a 10x10 square shape, on page 0
      select.onDragStart(Offset.zero, 0);
      select.onDragUpdate(const Offset(0, 10));
      select.onDragUpdate(const Offset(10, 10));
      select.onDragUpdate(const Offset(10, 0));

      expect(
        select.selectResult.pageIndex,
        0,
        reason: 'The page index should be 0',
      );

      final List<EditorImage> images = [
        // index 0 is inside (100% in the selection)
        TestImage(dstRect: const .fromLTWH(0, 0, 10, 10)),
        // index 1 is inside (> 70% in the selection)
        TestImage(dstRect: const .fromLTWH(0, 0, 10 / 0.75, 10 / 0.75)),
        // index 2 is partly in too: touching the lasso's area is enough
        TestImage(dstRect: const .fromLTWH(0, 0, 10 / 0.6, 10 / 0.6)),
      ];

      select.onDragEnd(const [], images);

      expect(
        select.selectResult.images,
        hasLength(3),
        reason: 'All images touching the area should be selected',
      );
      expect(
        select.selectResult.images,
        contains(images[0]),
        reason: 'The first image should be selected',
      );
      expect(
        select.selectResult.images,
        contains(images[1]),
        reason: 'The second image should be selected',
      );
      expect(
        select.selectResult.strokes,
        isEmpty,
        reason: 'No strokes should be selected',
      );
    });

    group('getDominantStrokeColor', () {
      test('not done selecting', () {
        final select = Select.currentSelect;
        select.unselect();
        expect(select.getDominantStrokeColor(), isNull);
      });

      test('with no selected strokes', () {
        final select = Select.currentSelect;
        select.selectResult = SelectResult(
          pageIndex: 0,
          strokes: const [],
          images: const [],
          path: Path(),
          pageIndexStart: 0,
        );
        expect(select.getDominantStrokeColor(), isNull);
      });

      test('with selected strokes', () {
        final select = Select.currentSelect;
        select.selectResult = SelectResult(
          pageIndex: 0,
          strokes: [
            _strokeWithColor(Colors.red),
            _strokeWithColor(Colors.blue),
            _strokeWithColor(Colors.blue),
            _strokeWithColor(Colors.blue),
            _strokeWithColor(Colors.red),
          ],
          images: const [],
          path: Path(),
          pageIndexStart: 0,
        );
        select.doneSelecting = true;
        expect(select.getDominantStrokeColor(), Colors.blue);
      });
    });
  });
}

// ignore: missing_override_of_must_be_overridden
class TestImage extends PngEditorImage {
  static final _assetCache = AssetCache();

  new({required super.dstRect})
    : super(
        id: -1,
        extension: '.png',
        imageProvider: MemoryImage(Uint8List(0)),
        pageIndex: 0,
        pageSize: const Size(100, 100),
        onMoveImage: null,
        onDeleteImage: null,
        onMiscChange: null,
        assetCache: _assetCache,
      );

  @override
  Future<void> firstLoad() async {
    // do nothing
  }
}

Stroke _strokeWithColor(Color color) {
  return Stroke(
    color: color,
    pressureEnabled: false,
    options: StrokeOptions(),
    pageIndex: 0,
    page: const HasSize(Size.zero),
    toolId: .fountainPen,
  );
}
