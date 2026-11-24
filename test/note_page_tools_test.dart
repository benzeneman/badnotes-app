import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:badnotes/components/canvas/_asset_cache.dart';
import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:badnotes/components/canvas/image/editor_image.dart';
import 'package:badnotes/data/editor/editor_history.dart';
import 'package:badnotes/components/canvas/canvas_gesture_detector.dart';
import 'package:badnotes/components/editor/canvas_tools_overlay.dart';
import 'package:badnotes/components/editor/board_kits.dart';
import 'package:badnotes/components/editor/board_paper.dart';
import 'package:badnotes/components/canvas/_canvas_background_painter.dart';
import 'package:badnotes/components/editor/new_page_sheet.dart';
import 'package:badnotes/data/editor/note_start.dart';
import 'package:sbn/canvas_background_pattern.dart';
import 'package:badnotes/components/home/revision_plan.dart';
import 'package:badnotes/components/editor/note_search_panel.dart';
import 'package:badnotes/components/editor/pages_panel.dart';
import 'package:badnotes/components/editor/note_split_view.dart';
import 'package:badnotes/components/editor/page_pins.dart';
import 'package:badnotes/components/editor/sticky_note_dialog.dart';
import 'package:badnotes/components/editor/tape_quiz.dart';
import 'package:badnotes/components/editor/screenshot_overlay.dart';
import 'package:badnotes/data/editor/page.dart';
import 'package:badnotes/data/flavor_config.dart';
import 'package:badnotes/data/tools/pen.dart';
import 'package:sbn/tool_id.dart';

void main() {
  group('Page rotation', () {
    const size = Size(1000, 1400);

    Offset turn(Offset p, {required bool clockwise}) => Stroke.transformPoint(
      p,
      EditorPage.rotationPivot(size, clockwise: clockwise),
      1,
      clockwise ? pi / 2 : -pi / 2,
    );

    void expectNear(Offset a, Offset b) {
      expect(a.dx, closeTo(b.dx, 1e-6));
      expect(a.dy, closeTo(b.dy, 1e-6));
    }

    test('clockwise lands on the flipped page', () {
      expectNear(turn(Offset.zero, clockwise: true), const Offset(1400, 0));
      expectNear(
        turn(const Offset(1000, 1400), clockwise: true),
        const Offset(0, 1000),
      );
    });

    test('anticlockwise lands on the flipped page', () {
      expectNear(turn(Offset.zero, clockwise: false), const Offset(0, 1000));
      expectNear(
        turn(const Offset(1000, 1400), clockwise: false),
        const Offset(1400, 0),
      );
    });
  });

  group('Search', () {
    final pages = [
      {'Text': 'nothing here', 'PDF': ''},
      {'Text': '', 'PDF': 'The Photo\nSynthesis cycle and photo synthesis'},
    ];

    test('finds every match across line breaks, ignoring case', () {
      final hits = findInPages(pages, 'photo synthesis');
      expect(hits.length, 2);
      expect(hits.first.pageIndex, 1);
      expect(hits.first.source, 'PDF');
      final match = hits.first.snippet.substring(
        hits.first.matchStart,
        hits.first.matchStart + hits.first.matchLength,
      );
      expect(match, 'Photo Synthesis');
    });

    test('a blank query or missing word finds nothing', () {
      expect(findInPages(pages, '   '), isEmpty);
      expect(findInPages(pages, 'mitochondria'), isEmpty);
    });
  });

  test('Pencil grain stays put as the stroke grows', () {
    Stroke stroke(int points) => Stroke(
      color: Colors.black,
      pressureEnabled: false,
      options: .new(size: 4),
      pageIndex: 0,
      page: EditorPage(),
      toolId: .pencil,
    )..addPoints([for (var i = 0; i < points; i++) Offset(i * 10.0, 50)]);

    final short = stroke(5).pencilGrain, long = stroke(10).pencilGrain;
    expect(short, isNotEmpty);
    expect(long.length, greaterThan(short.length));
    // grains belong to the paper: away from the tip, the same ones are there
    Set<(double, double)> grains(List<double> list) => {
      for (var i = 0; i < list.length; i += 2)
        if (list[i] < 30) (list[i], list[i + 1]),
    };
    expect(grains(long), grains(short));
  });

  group('Screenshot frame', () {
    const bounds = Size(400, 600);
    const frame = Rect.fromLTWH(100, 100, 200, 200);

    test('moving stays inside the screen', () {
      expect(
        ScreenshotFrame.drag(frame, .move, const Offset(-500, 50), bounds),
        const Rect.fromLTWH(0, 150, 200, 200),
      );
    });

    test('a corner resizes around the opposite corner', () {
      expect(
        ScreenshotFrame.drag(frame, .topLeft, const Offset(-50, 20), bounds),
        const Rect.fromLTRB(50, 120, 300, 300),
      );
    });

    test('never smaller than the minimum, never off screen', () {
      final tiny = ScreenshotFrame.drag(
        frame,
        .bottomRight,
        const Offset(-1000, -1000),
        bounds,
      );
      expect(tiny.size, const Size.square(ScreenshotFrame.minSide));
      expect(tiny.topLeft, frame.topLeft);
      final huge = ScreenshotFrame.drag(
        frame,
        .bottomRight,
        const Offset(1000, 1000),
        bounds,
      );
      expect(huge, const Rect.fromLTRB(100, 100, 400, 600));
    });

    test('keeps the chosen shape', () {
      final wide = ScreenshotFrame.drag(
        frame,
        .bottomRight,
        Offset.zero,
        bounds,
        ratio: 2,
      );
      expect(wide.width / wide.height, closeTo(2, 1e-9));
      final tall = ScreenshotFrame.drag(
        frame,
        .bottomRight,
        const Offset(1000, 0),
        bounds,
        ratio: 0.1,
      );
      expect(tall.bottom, lessThanOrEqualTo(bounds.height));
      expect(tall.width / tall.height, closeTo(0.1, 1e-9));
    });

    test('grabs corners first, then the inside, nothing outside', () {
      expect(ScreenshotFrame.handleAt(frame, frame.topRight), isNotNull);
      expect(
        ScreenshotFrame.handleAt(frame, frame.bottomLeft),
        ScreenshotHandle.bottomLeft,
      );
      expect(
        ScreenshotFrame.handleAt(frame, frame.center),
        ScreenshotHandle.move,
      );
      expect(ScreenshotFrame.handleAt(frame, const Offset(1, 1)), isNull);
    });
  });

  group('Reordering', () {
    Stroke stroke(ToolId toolId) => Stroke(
      color: Colors.black,
      pressureEnabled: false,
      options: .new(),
      pageIndex: 0,
      page: EditorPage(),
      toolId: toolId,
    );

    test('moves the chosen ink, keeping highlighters underneath', () {
      final highlight = stroke(.highlighter);
      final a = stroke(.fountainPen), b = stroke(.pencil), c = stroke(.tape);
      final page = EditorPage(strokes: [highlight, a, b, c]);

      page.reorder([a], const [], toFront: true);
      expect(page.strokes, [highlight, b, c, a]);

      page.reorder([c, a], const [], toFront: false);
      expect(page.strokes, [highlight, c, a, b]);

      page.reorder([highlight], const [], toFront: true);
      expect(page.strokes.first, highlight);
    });
  });

  group('Pins', () {
    test('only safe addresses can be opened', () {
      expect(parseLink('example.com').toString(), 'https://example.com');
      expect(parseLink('http://a.io/b?c=1').toString(), 'http://a.io/b?c=1');
      expect(parseLink('mailto:a@b.c'), isNotNull);
      expect(parseLink('javascript:alert(1)'), isNull);
      expect(parseLink('file:///etc/passwd'), isNull);
      expect(parseLink('intent://x'), isNull);
      expect(parseLink('   '), isNull);
    });

    test('survive being saved as an SVG', () {
      const pin = PagePin(.link, 'a <b> "c"', url: 'https://x.io');
      final back = pinFromSvg(pinToSvg(pin))!;
      expect(back.kind, PinKind.link);
      expect(back.text, pin.text);
      expect(back.url, pin.url);
      expect(pinFromSvg('<svg></svg>'), isNull);
    });
  });

  test('A text box keeps its font and size when saved', () {
    const note = StickyNoteResult(
      'hello',
      null,
      font: 'Caveat',
      fontSize: 36,
      maxWidth: 500,
    );
    final svg = stickyNoteToSvg(note);
    expect(svg, contains('font-family="Caveat"'));
    final back = stickyNoteFromSvg(svg)!;
    expect(back.font, 'Caveat');
    expect(back.fontSize, 36);
    expect(back.maxWidth, 500);
    expect(back.color, isNull);
  });

  group('Fountain pen pressure', () {
    Stroke pen({required bool pressure}) => Stroke(
      color: Colors.black,
      pressureEnabled: pressure,
      options: .new(size: 4),
      pageIndex: 0,
      page: EditorPage(),
      toolId: .fountainPen,
    );

    test('one width without a pressure-sensitive pen', () {
      final stroke = pen(pressure: true);
      for (var i = 0; i < 20; i++) stroke.addPoint(Offset(i * i * 2.0, 0));
      expect(stroke.nibPressures.toSet(), {0.5});
    });

    test('jumpy readings come out smooth, and stay inside 0.25 to 1', () {
      final stroke = pen(pressure: true);
      for (var i = 0; i < 40; i++) {
        stroke.addPoint(Offset(i.toDouble(), 0), i.isEven ? 0.2 : 0.6);
      }
      final pressures = stroke.nibPressures;
      for (var i = 1; i < pressures.length; i++) {
        expect((pressures[i] - pressures[i - 1]).abs(), lessThan(0.15));
      }
      expect(pressures.every((p) => p >= 0.25 && p <= 1), isTrue);
    });

    test('with speed ink, moving fast draws thinner', () {
      final stroke = pen(pressure: false)..speedInk = true;
      for (var i = 0; i < 30; i++) stroke.addPoint(Offset(i * 1.0, 0));
      for (var i = 0; i < 30; i++) stroke.addPoint(Offset(30 + i * 25.0, 0));
      final pressures = stroke.nibPressures;
      expect(pressures.last, lessThan(pressures[25]));
      // saved and loaded, it keeps drawing the same way
      final json = stroke.toJson();
      expect(json['sv'], isTrue);
      expect(stroke.copy().speedInk, isTrue);
    });

    test('pressing harder gives more', () {
      final stroke = pen(pressure: true);
      for (var i = 0; i < 40; i++) {
        stroke.addPoint(Offset(i.toDouble(), 0), i < 20 ? 0.1 : 0.9);
      }
      expect(stroke.nibPressures.last, greaterThan(stroke.nibPressures[15]));
    });
  });

  group('Calligraphy pen', () {
    Stroke drawn(Offset direction) {
      final stroke = Stroke(
        color: Colors.black,
        pressureEnabled: false,
        options: StrokeOptions(size: 10),
        pageIndex: 0,
        page: EditorPage(),
        toolId: .calligraphyPen,
      );
      for (var i = 0; i < 30; i++) {
        stroke.addPoint(const Offset(300, 300) + direction * i.toDouble() * 4);
      }
      return stroke;
    }

    double thickness(Stroke stroke, Offset across) {
      final reach = [
        for (final p in stroke.highQualityPolygon)
          p.dx * across.dx + p.dy * across.dy,
      ];
      return reach.reduce(max) - reach.reduce(min);
    }

    test('is thick across the nib and thin along it', () {
      final unit = sqrt1_2;
      final wide = drawn(Offset(unit, unit));
      final thin = drawn(Offset(unit, -unit));
      expect(thickness(wide, Offset(unit, -unit)), closeTo(10, 1.5));
      expect(thickness(thin, Offset(unit, unit)), closeTo(1.2, 0.5));
    });
  });

  group('Layers', () {
    Stroke on(int layer) => Stroke(
      color: Colors.black,
      pressureEnabled: false,
      options: StrokeOptions(size: 3),
      pageIndex: 0,
      page: EditorPage(),
      toolId: .fountainPen,
    )
      ..layer = layer
      ..addPoint(const Offset(10, 10))
      ..addPoint(const Offset(20, 20));

    test('ink on a higher layer stays above, also after moving it', () {
      final page = EditorPage()..addLayer();
      final top = on(page.activeLayer), bottom = on(0);
      page
        ..insertStroke(top)
        ..insertStroke(bottom);
      expect(page.strokes, [bottom, top]);
      page.moveLayer(1, 0);
      expect(page.strokes, [top, bottom]);
    });

    test('new ink never goes on a hidden layer', () {
      final page = EditorPage()..addLayer();
      final hidden = page.layers.last;
      expect(page.canDisableLayer(hidden), isTrue);
      hidden.visible = false;
      page.updateActiveLayer();
      expect(page.activeLayer, page.layers.first.id);
      expect(page.canDisableLayer(page.layers.first), isFalse);
    });

    test('deleting a layer hands back its ink, undo keeps it reachable', () {
      final page = EditorPage()..addLayer();
      final gone = on(page.activeLayer);
      page.insertStroke(gone);
      final removed = page.removeLayer(gone.layer);
      expect(removed.strokes, [gone]);
      expect(page.strokes, isEmpty);
      expect(page.isLayerEditable(gone.layer), isTrue);
      expect(page.isLayerVisible(gone.layer), isTrue);
      expect(page.removeLayer(page.layers.single.id).strokes, isEmpty);
      expect(page.layers, hasLength(1));
    });

    test('layers are saved with the page', () {
      final page = EditorPage()..addLayer();
      page.layers.last.locked = true;
      page.insertStroke(on(page.layers.last.id));
      final loaded = EditorPage.fromJson(
        page.toJson(OrderedAssetCache()),
        inlineAssets: null,
        readOnly: false,
        fileVersion: 19,
        sbnPath: '',
        assetCache: AssetCache(),
      );
      expect(loaded.layers.map((l) => l.locked), [false, true]);
      expect(loaded.strokes.single.layer, page.layers.last.id);
    });
  });

  group('Stopwatch', () {
    test('keeps break time out of focus time', () {
      var now = DateTime(2026);
      final watch = StudyStopwatch(clock: () => now);
      now = now.add(const Duration(minutes: 10));
      watch.onBreak = true;
      now = now.add(const Duration(minutes: 3));
      watch.onBreak = false;
      now = now.add(const Duration(minutes: 1));
      expect(watch.focus, const Duration(minutes: 11));
      expect(watch.breakTime, const Duration(minutes: 3));
    });

    test('counts nothing while paused', () {
      var now = DateTime(2026);
      final watch = StudyStopwatch(clock: () => now);
      now = now.add(const Duration(minutes: 1));
      watch.pauseOrResume();
      now = now.add(const Duration(hours: 1));
      watch.pauseOrResume();
      now = now.add(const Duration(minutes: 1));
      expect(watch.focus, const Duration(minutes: 2));
    });
  });

  group('Tape line', () {
    double sharpestTurn(List<Offset> line) {
      var sharpest = 0.0;
      for (int i = 1; i < line.length - 1; i++) {
        final a = (line[i] - line[i - 1]).direction;
        final b = (line[i + 1] - line[i]).direction;
        sharpest = max(sharpest, atan2(sin(b - a), cos(b - a)).abs());
      }
      return sharpest;
    }

    final shaky = [
      for (var i = 0; i < 200; i++)
        Offset(100 + i * 2.0, 200 + (i.isEven ? 3.0 : -3.0)),
    ];

    test('takes out the wobble of the hand and keeps the ends', () {
      final smooth = Stroke.smoothTapeLine(shaky, 24);
      expect(sharpestTurn(smooth), lessThan(sharpestTurn(shaky) / 3));
      expect(smooth.first, shaky.first);
      expect(smooth.last, shaky.last);
    });

    test('a part already drawn stays put as the line grows', () {
      final before = Stroke.smoothTapeLine(shaky.sublist(0, 150), 24);
      final after = Stroke.smoothTapeLine(shaky, 24);
      for (var i = 0; i < before.length - 8; i++) {
        expect((before[i] - after[i]).distance, lessThan(1e-6));
      }
    });
  });

  group('Dropping a tab', () {
    const size = Size(1000, 800);
    test('opens on the side it landed', () {
      expect(splitSideAt(const Offset(100, 400), size), AxisDirection.left);
      expect(splitSideAt(const Offset(900, 400), size), AxisDirection.right);
      expect(splitSideAt(const Offset(900, 40), size), AxisDirection.up);
      expect(splitSideAt(const Offset(100, 780), size), AxisDirection.down);
    });
  });

  group('Fountain pen ink', () {
    test("doesn't change when the pen lifts", () {
      final stroke = Stroke(
        color: Colors.black,
        pressureEnabled: false,
        options: StrokeOptions(size: 3, isComplete: false),
        pageIndex: 0,
        page: EditorPage(),
        toolId: .fountainPen,
      );
      for (var i = 0; i < 60; i++) {
        stroke.addPoint(Offset(100 + i * 2.0, 100));
      }
      final writing = stroke.highQualityPolygon.toList();
      stroke
        ..options.isComplete = true
        ..markPolygonNeedsUpdating();
      expect(stroke.highQualityPolygon, writing);
    });
  });

  group('Highlighter', () {
    test('keeps to level or upright lines', () {
      const start = Offset(100, 100);
      expect(Pen.snapToAxis(start, const Offset(300, 120)), const Offset(300, 100));
      expect(Pen.snapToAxis(start, const Offset(90, 40)), const Offset(100, 40));
    });
  });

  group('Tape quiz', () {
    test('asks again what was not known, at the end', () {
      final quiz = TapeQuiz(['a', 'b']);
      expect(quiz.current, 'a');
      quiz.answer(knewIt: false);
      expect(quiz.current, 'b');
      quiz.answer(knewIt: true);
      expect(quiz.current, 'a');
      quiz.answer(knewIt: true);
      expect(quiz.finished, isTrue);
      expect(quiz.firstTry, 1);
    });
  });

  group('New pages', () {
    test('same as this page copies its look', () {
      final page = EditorPage(size: const Size(707, 1000))
        ..backgroundColor = const Color(0xFFFFF8E1)
        ..lineHeight = 30;
      final same = PageTemplate.sameAs(page);
      expect(same.size, page.size);
      expect(same.color, page.backgroundColor);
      expect(same.lineHeight, 30);
    });

    test('a page keeps its color when saved', () {
      final page = EditorPage()..backgroundColor = const Color(0xFFF8BBD0);
      final loaded = EditorPage.fromJson(
        page.toJson(OrderedAssetCache()),
        inlineAssets: null,
        readOnly: false,
        fileVersion: 19,
        sbnPath: '',
        assetCache: AssetCache(),
      );
      expect(loaded.backgroundColor, page.backgroundColor);
    });
  });

  group('Size dots', () {
    test('read what was saved for this pen only', () {
      final saved = Pen.parseSizeSlots('fountainPen:1.5:4.0:1', 'fountainPen')!;
      expect(saved.$1, [1.5, 4.0]);
      expect(saved.$2, 1);
      expect(Pen.parseSizeSlots('pencil:1.5:4.0:1', 'fountainPen'), isNull);
      expect(Pen.parseSizeSlots('fountainPen:bad', 'fountainPen'), isNull);
    });
  });

  group('Search in a pdf', () {
    test('boxes go around each line of the match', () {
      final lines = PdfEditorImage.mergeIntoLines(const [
        Rect.fromLTRB(0, 0, 10, 10),
        Rect.fromLTRB(10, 0, 20, 10),
        Rect.fromLTRB(0, 20, 10, 30),
        Rect.zero,
      ]);
      expect(lines, const [
        Rect.fromLTRB(0, 0, 20, 10),
        Rect.fromLTRB(0, 20, 10, 30),
      ]);
    });
  });

  group('Page history', () {
    test('a new order undoes back to the old one', () {
      final a = EditorPage(), b = EditorPage();
      final change = HistoricPageOrder(before: [a, b], after: [b, a]);
      expect(change.reverse().before, [b, a]);
      expect(change.reverse().after, [a, b]);
    });
  });

  group('Layers and images', () {
    test('content of a deleted layer is drawn on the bottom one', () {
      final page = EditorPage()..addLayer();
      expect(page.hasSeveralLayers, isTrue);
      expect(page.drawnOnLayer(page.layers.last.id), page.layers.last.id);
      expect(page.drawnOnLayer(99), page.layers.first.id);
    });
  });

  group('Revision plan', () {
    test('waits longer the better a quiz went', () {
      expect(RevisionEntry.nextDays(0, 2, 10), 1);
      expect(RevisionEntry.nextDays(0, 7, 10), 2);
      expect(RevisionEntry.nextDays(0, 10, 10), 3);
      expect(RevisionEntry.nextDays(4, 10, 10), 10);
      expect(RevisionEntry.nextDays(40, 10, 10), 60);
      expect(RevisionEntry.nextDays(10, 1, 10), 1);
    });

    test('reads back what it saved, also with odd note names', () {
      final entry = RevisionEntry('/a|b', DateTime(2026, 11, 5), 3);
      final read = RevisionEntry.parse(entry.toString())!;
      expect(read.path, '/a|b');
      expect(read.due, entry.due);
      expect(read.days, 3);
      expect(RevisionEntry.parse('nonsense'), isNull);
    });
  });

  group('Ready-made layouts', () {
    test('each one is a drawing with a name', () {
      expect(BoardKit.all, isNotEmpty);
      for (final kit in BoardKit.all) {
        expect(kit.name, isNotEmpty);
        expect(kit.svg, startsWith('<svg'));
        expect(kit.svg, endsWith('</svg>'));
      }
    });
  });

  group('Whiteboard', () {
    test('a sheet of the board size is a board, a page is not', () {
      expect(EditorPage().isBoard, isFalse);
      expect(
        EditorPage(size: const Size.square(EditorPage.boardSide)).isBoard,
        isTrue,
      );
    });

    test('its marks thin out instead of crowding when zoomed out', () {
      expect(BoardPaperPainter.gapOnScreen(40, 1), 40);
      expect(BoardPaperPainter.gapOnScreen(40, 2), 80);
      expect(BoardPaperPainter.gapOnScreen(20, 0.1), greaterThanOrEqualTo(12));
    });
  });

  group('Full Page Focus', () {
    setUp(FlavorConfig.setup);

    test('fits a whole tall page on a wide screen, in the middle', () {
      final view = CanvasGestureDetector.fitPage(
        pageIndex: 0,
        pages: [EditorPage(size: const Size(1000, 1000))],
        viewport: const Size(1000, 500),
      );
      expect(view.getMaxScaleOnAxis(), closeTo(0.5, 1e-9));
      expect(view.getTranslation().x, closeTo(250, 1e-9));
    });
  });

  group('Pages panel', () {
    test('shows all pages, or only the bookmarked ones', () {
      const flags = [false, true, false, true];
      expect(PagesPanel.shownPages(flags, onlySaved: false), [0, 1, 2, 3]);
      expect(PagesPanel.shownPages(flags, onlySaved: true), [1, 3]);
    });
  });

  group('New documents', () {
    test('a start is handed over once', () {
      NoteStart.set('/a', const NoteStart(board: true));
      expect(NoteStart.take('/a')?.board, isTrue);
      expect(NoteStart.take('/a'), isNull);
    });

    test('every paper section draws something, except plain paper', () {
      for (final paper in PaperKind.all) {
        final marks = CanvasBackgroundPainter.getPatternElements(
          pattern: paper.pattern,
          size: const Size(1000, 1400),
          lineHeight: paper.lineHeight ?? 40,
        );
        expect(marks.isEmpty, paper.pattern == CanvasBackgroundPattern.none);
      }
    });

    test('a month has seven days across and five weeks down', () {
      final marks = CanvasBackgroundPainter.getPatternElements(
        pattern: .month,
        size: const Size(700, 1000),
        lineHeight: 40,
      ).toList();
      expect(marks.length, 6 + 6);
    });

    test('every layout is in a section', () {
      final named = {
        for (final kits in BoardKit.sections.values)
          for (final kit in kits) kit.name,
      };
      expect(named, {for (final kit in BoardKit.all) kit.name});
    });
  });
}
