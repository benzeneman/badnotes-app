/// Real use of the editor, as a hand would: fast, not precise, with every
/// writing tool, the erasers, the lasso and the shape pen, on a page already
/// full of writing. Pictures of each step go to `build/scenarios`, and how
/// long things took is printed, to compare builds.
///
/// Run with `flutter test --tags scenario test/scenarios_test.dart`.
@Tags(['scenario'])
library;

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:sbn/tool_id.dart';
import 'package:badnotes/components/canvas/_canvas_painter.dart';
import 'package:badnotes/components/canvas/_ink_cache.dart';
import 'package:badnotes/components/canvas/_circle_stroke.dart';
import 'package:badnotes/components/canvas/shape_style.dart';
import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:badnotes/components/canvas/image/editor_image.dart';
import 'package:badnotes/components/editor/sticky_note_dialog.dart';
import 'package:badnotes/components/editor/text_box_overlay.dart';
import 'package:badnotes/components/editor_ui/option_previews.dart';
import 'package:badnotes/components/editor_ui/selection_action_bar.dart';
import 'package:badnotes/components/canvas/inner_canvas.dart';
import 'package:badnotes/components/canvas/interactive_canvas.dart';
import 'package:badnotes/data/editor/page.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/data/flavor_config.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/tools/_tool.dart';
import 'package:badnotes/data/tools/eraser.dart';
import 'package:badnotes/data/tools/highlighter.dart';
import 'package:badnotes/data/tools/pen.dart';
import 'package:badnotes/data/tools/pencil.dart';
import 'package:badnotes/data/tools/select.dart';
import 'package:badnotes/data/tools/shape_pen.dart';
import 'package:badnotes/data/tools/shape_recognizer.dart';
import 'package:badnotes/pages/editor/editor.dart';

import 'utils/test_mock_channel_handlers.dart';

final _out = Directory('build/scenarios');
final _shotKey = GlobalKey();
final _timings = <String>[];

void main() {
  setUpAll(() {
    FlavorConfig.setup();
    FileManager.documentsDirectory =
        '$tmpDir/scenarios/${FileManager.appRootDirectoryPrefix}';
    _out.createSync(recursive: true);
  });
  tearDownAll(() {
    File('${_out.path}/timings.txt').writeAsStringSync(_timings.join('\n'));
    // ignore: avoid_print
    print(_timings.join('\n'));
  });

  testWidgets('every pen at 0%, 50% and 100% stabilization', (tester) async {
    final s = await _Session.open(tester, 'pens');
    final pens = <(String, Pen)>[
      ('ballpoint', Pen.currentBallpointPen),
      ('fountain', Pen.currentPen),
      ('pencil', Pencil.currentPencil),
      ('highlighter', Highlighter.currentHighlighter),
    ];
    var y = 40.0;
    for (final (_, pen) in pens) {
      for (final stability in [0.0, 0.5, 1.0]) {
        pen.options.streamline = stability * 0.95;
        s.tool = pen;
        await s.draw(_cursive(Offset(30, y), width: 330, seed: y.toInt()));
        y += 40;
      }
      y += 8;
    }
    await s.shot('pens_stabilization');
  });

  testWidgets('fast curves: where the line ends', (tester) async {
    final s = await _Session.open(tester, 'curves');
    for (final (i, latency) in [true, false].indexed) {
      stows.penReduceLatency.value = latency;
      s.tool = Pen.currentBallpointPen..options.streamline = 0;
      final spiral = _spiral(Offset(105 + i * 195.0, 200), 75);
      // mid-stroke: the line with its predicted tip
      await s.draw(spiral, speed: 1400, lift: false);
      await s.shot('fast_curve_mid_latency_$latency');
      await s.lift();
      await s.shot('fast_curve_done_latency_$latency');
    }
    stows.penReduceLatency.value = true;
  });

  testWidgets('highlighter: fill, erase, undo', (tester) async {
    final s = await _Session.open(tester, 'highlighter');
    final highlighter = Highlighter.currentHighlighter
      ..options.size = 70
      ..color = Colors.yellow.withAlpha(100);
    s.tool = highlighter;
    // one stroke back and forth filling a box, and separate strokes beside it
    await s.draw(_zigzag(const Rect.fromLTWH(30, 80, 160, 220), rows: 9));
    for (int i = 0; i < 8; i++) {
      await s.draw(
        _wobbly(Offset(220, 85 + i * 26.0), Offset(380, 90 + i * 26.0), i),
      );
    }
    await s.shot('highlighter_filled');
    final before = s.page.strokes.length;

    Eraser.type = EraserType.precision;
    s.tool = Eraser();
    await s.draw(_wobbly(const Offset(20, 190), const Offset(390, 210), 3));
    await s.shot('highlighter_standard_eraser');
    // one the eraser went all along is gone, but none is cut into pieces
    expect(
      s.page.strokes.length,
      lessThanOrEqualTo(before),
      reason: 'a highlighter stays one stroke when the standard eraser cuts it',
    );

    Eraser.type = EraserType.precision;
    await s.draw(_wobbly(const Offset(60, 120), const Offset(350, 130), 4));
    await s.shot('highlighter_precision_eraser');

    s.editor.undo();
    s.editor.undo();
    await tester.pump();
    await s.shot('highlighter_undone');
    expect(s.page.strokes.length, before);
    expect(s.page.strokes.every((stroke) => stroke.holes.isEmpty), isTrue);
  });

  testWidgets('lasso: stretch, scale, rotate, move and undo', (tester) async {
    final s = await _Session.open(tester, 'lasso');
    s.tool = Highlighter.currentHighlighter
      ..options.size = 28
      ..color = Colors.yellow.withAlpha(100);
    for (int i = 0; i < 6; i++) {
      await s.draw(
        _wobbly(Offset(60, 120 + i * 22.0), Offset(220, 122 + i * 22.0), i),
      );
    }
    s.tool = Pen.currentBallpointPen;
    await s.draw(_cursive(const Offset(60, 270), width: 170, seed: 2));
    final original = _snapshot(s.page);

    s.tool = Select.currentSelect;
    await s.draw(_loop(const Rect.fromLTWH(30, 90, 230, 230)), speed: 900);
    expect(Select.currentSelect.selectResult.strokes, isNotEmpty);
    await s.shot('lasso_selected');

    Future<void> dragHandle(SelectHandle handle, Offset by) async {
      // the box hugs what's picked (and is level here)
      final at = Select.boxHandles(Select.currentSelect.box)[handle]!;
      await s.draw([at, at + by * 0.5, at + by], speed: 1200, onPage: true);
    }

    await dragHandle(.bottom, const Offset(0, 300));
    await s.shot('lasso_stretched_taller');
    final taller = _snapshot(s.page);
    expect(taller, isNot(original), reason: 'the bottom handle stretched it');
    await dragHandle(.right, const Offset(250, 0));
    await s.shot('lasso_stretched_wider');
    final wider = _snapshot(s.page);
    expect(wider, isNot(taller), reason: 'the right handle stretched it');

    s.editor.undo();
    await tester.pump();
    expect(_snapshot(s.page), taller, reason: 'undoing the second stretch');
    s.editor.undo();
    await tester.pump();
    await s.shot('lasso_stretch_undone');
    expect(_snapshot(s.page), original, reason: 'undoing both stretches');
    s.editor.redo();
    s.editor.redo();
    await tester.pump();
    expect(_snapshot(s.page), wider, reason: 'redoing both stretches');
    s.editor.undo();
    s.editor.undo();
    await tester.pump();

    s.tool = Select.currentSelect;
    await s.draw(_loop(const Rect.fromLTWH(30, 90, 230, 230)), speed: 900);
    final bounds = Select.currentSelect.selectResult.path.getBounds();
    // move it by dragging the middle
    await s.draw([
      bounds.center,
      bounds.center + const Offset(100, 150),
    ], onPage: true);
    await s.shot('lasso_moved');
    s.editor.undo();
    await tester.pump();
    expect(_snapshot(s.page), original, reason: 'undoing a move');
    await s.shot('lasso_move_undone');
  });

  testWidgets('shapes drawn by hand, fast', (tester) async {
    final s = await _Session.open(tester, 'shapes');
    stows.shapeRecognitionDelay.value = 300;
    ShapePen.debounceDuration = const Duration(milliseconds: 300);
    ShapePen.kind = .auto;
    s.tool = ShapePen.currentShapePen;
    Offset at(int i) => Offset(70 + (i % 3) * 130.0, 70 + (i ~/ 3) * 125.0);
    final shapes = <String, List<Offset>>{
      'line': [at(0) - const Offset(50, 20), at(0) + const Offset(50, 25)],
      'arrow': _arrow(at(1) - const Offset(50, 0), at(1) + const Offset(50, 0)),
      'circle': _polygon(at(2), 48, 40),
      'triangle': _polygon(at(3), 50, 3),
      'square': _polygon(at(4), 55, 4, start: -pi / 4),
      'diamond': _polygon(at(5), 50, 4),
      'pentagon': _polygon(at(6), 50, 5),
      'hexagon': _polygon(at(7), 50, 6),
      'star': _polygon(at(8), 52, 5, skip: 2),
      'arc': [
        for (int i = 0; i <= 20; i++)
          at(9) + Offset.fromDirection(pi + i / 20 * pi, 50),
      ],
      'heart': _heart(at(10), 3.2),
      'star outline': [
        for (int i = 0; i <= 10; i++)
          at(11) +
              Offset.fromDirection(-pi / 2 + i * pi / 5, i.isEven ? 55 : 22),
      ],
    };
    final found = <String, String?>{};
    for (final MapEntry(key: name, value: corners) in shapes.entries) {
      final count = s.page.strokes.length;
      final drawn = _shaky(corners, name.length * 31);
      await s.draw(drawn, speed: 700, hold: true);
      final added = s.page.strokes.skip(count).toList();
      found[name] = added.isEmpty
          ? null
          : added.last.toolId != .shapePen
          ? 'ink'
          : recognizeShape([
                  for (final p in _along(drawn, 700 / 240)) s.toPage(p),
                ])?.name ??
                'snapped';
    }
    await s.shot('shapes');
    _timings.add('shapes recognized: $found');
    for (final name in shapes.keys) {
      final expected = name == 'circle'
          ? {'circle', 'ellipse'}
          : {name.split(' ').first};
      expect(expected, contains(found[name]), reason: 'drew a $name');
    }
  });

  testWidgets('a full notebook page: writing, highlighting, erasing', (
    tester,
  ) async {
    final s = await _Session.open(tester, 'heavy');
    s.tool = Pen.currentBallpointPen;
    await s.timed('write a word on an empty page', () async {
      await s.draw(_cursive(const Offset(40, 250), width: 200, seed: 9));
    });
    s.editor.undo();
    // a page already full of writing
    final random = Random(7);
    // about as dense as a page of a real notebook: ~600 words
    for (double y = 30; y < 545; y += 15) {
      for (double x = 20; x < 360; x += 18 + random.nextDouble() * 14) {
        s.page.insertStroke(
          Stroke(
            color: Colors.black,
            pressureEnabled: false,
            options: Pen.currentBallpointPen.options.copyWith(isComplete: true),
            pageIndex: 0,
            page: s.page,
            toolId: .ballpointPen,
          )..addPoints([
            for (final p in _cursive(
              Offset(x, y),
              width: 12 + random.nextDouble() * 12,
              seed: random.nextInt(1 << 20),
            ))
              s.toPage(p),
          ]),
        );
      }
    }
    s.page.redrawStrokes();
    await tester.pump();
    _timings.add('heavy page: ${s.page.strokes.length} strokes');

    s.tool = Pen.currentBallpointPen;
    await s.timed('write a word on a full page', () async {
      await s.draw(_cursive(const Offset(40, 250), width: 200, seed: 9));
    });

    s.tool = Highlighter.currentHighlighter
      ..options.size = 22
      ..color = Colors.yellow.withAlpha(100);
    await s.timed('60 highlighter strokes over one spot', () async {
      for (int i = 0; i < 60; i++) {
        await s.draw(
          _wobbly(const Offset(40, 330), const Offset(330, 334), i),
          speed: 1500,
        );
      }
    });
    await s.shot('heavy_highlighted');

    Eraser.type = EraserType.precision;
    s.tool = Eraser();
    await s.timed('standard eraser across the page', () async {
      await s.draw(_zigzag(const Rect.fromLTWH(30, 300, 330, 120), rows: 4));
    });
    await s.shot('heavy_erased');
  });

  testWidgets('100 big strokes and highlighters: pen, every eraser, lasso', (
    tester,
  ) async {
    final s = await _Session.open(tester, 'big');
    final random = Random(3);
    Stroke make(ToolId tool, double size, List<Offset> points) => Stroke(
      color: tool == .highlighter ? Colors.yellow.withAlpha(100) : Colors.black,
      pressureEnabled: tool != .highlighter,
      options: Pen.currentBallpointPen.options.copyWith(
        size: size,
        isComplete: true,
      ),
      pageIndex: 0,
      page: s.page,
      toolId: tool,
    )..addPoints([for (final p in points) s.toPage(p)]);
    for (int i = 0; i < 100; i++) {
      final y = 20.0 + i * 5.2;
      s.page.insertStroke(
        make(.ballpointPen, 6 + random.nextDouble() * 6, [
          for (final p in _cursive(Offset(15, y), width: 360, seed: i))
            p + Offset(0, random.nextDouble()),
        ]),
      );
    }
    for (int i = 0; i < 30; i++) {
      s.page.insertStroke(
        make(
          .highlighter,
          22,
          _wobbly(Offset(15, 30.0 + i * 17), Offset(385, 32.0 + i * 17), i),
        ),
      );
    }
    s.page.redrawStrokes();
    await tester.pump();
    _timings.add('big page: ${s.page.strokes.length} strokes');

    s.tool = Pen.currentBallpointPen;
    await s.timed('big page: 10 words', () async {
      for (int i = 0; i < 10; i++) {
        await s.draw(_cursive(Offset(30, 100.0 + i * 30), width: 150, seed: i));
      }
    });
    s.tool = Highlighter.currentHighlighter
      ..options.size = 22
      ..color = Colors.yellow.withAlpha(100);
    await s.timed('big page: 10 highlighter strokes', () async {
      for (int i = 0; i < 10; i++) {
        await s.draw(
          _wobbly(Offset(30, 60.0 + i * 40), Offset(360, 62.0 + i * 40), i),
        );
      }
    });
    for (final type in EraserType.values) {
      Eraser.type = type;
      s.tool = Eraser();
      await s.timed('big page: ${type.name} eraser, fast', () async {
        await s.draw(
          _zigzag(const Rect.fromLTWH(20, 60 + 0.0, 360, 400), rows: 6),
          speed: 2500,
        );
      });
      s.editor.undo();
      await tester.pump();
      await s.timed('big page: ${type.name} eraser, a few words', () async {
        await s.draw(
          _zigzag(const Rect.fromLTWH(40, 200, 120, 40), rows: 4),
          speed: 1500,
        );
      });
      s.editor.undo();
      await tester.pump();
    }
    s.tool = Select.currentSelect;
    await s.timed('big page: lasso around half the page', () async {
      await s.draw(_loop(const Rect.fromLTWH(10, 20, 380, 260)), speed: 1500);
    });
    _timings.add(
      'lasso picked ${Select.currentSelect.selectResult.strokes.length}',
    );
    await s.timed('big page: lasso drag', () async {
      final bounds = Select.currentSelect.selectResult.path.getBounds();
      await s.draw(
        [
          bounds.center,
          bounds.center + const Offset(80, 60),
          bounds.center + const Offset(20, 120),
        ],
        onPage: true,
        speed: 1200,
      );
    });
    await s.shot('big_after');
  });

  testWidgets('30 full pages: scroll, zoom, 60 highlighters on one spot', (
    tester,
  ) async {
    final s = await _Session.open(tester, 'notebook');
    final random = Random(5);
    s.editor.createPage(29);
    for (int p = 0; p < 30; p++) {
      final page = s.editor.coreInfo.pages[p];
      Offset at(Offset o) => o * (page.size.width / 400);
      for (int k = 0; k < 500; k++) {
        final y = 25 + (k ~/ 18) * 19.0, x = 15 + (k % 18) * 21.0;
        page.insertStroke(
          Stroke(
            color: Colors.black,
            pressureEnabled: false,
            options: Pen.currentBallpointPen.options.copyWith(isComplete: true),
            pageIndex: p,
            page: page,
            toolId: .ballpointPen,
          )..addPoints([
            for (final q in _cursive(
              Offset(x, y),
              width: 16,
              seed: random.nextInt(1 << 20),
            ))
              at(q),
          ]),
        );
      }
      for (int k = 0; k < 20; k++) {
        page.insertStroke(
          Stroke(
            color: Colors.yellow.withAlpha(100),
            pressureEnabled: false,
            options: Pen.currentBallpointPen.options.copyWith(
              size: 22,
              isComplete: true,
            ),
            pageIndex: p,
            page: page,
            toolId: .highlighter,
          )..addPoints([
            for (final q in _wobbly(
              Offset(15, 30.0 + k * 26),
              Offset(385, 32.0 + k * 26),
              k,
            ))
              at(q),
          ]),
        );
      }
      page.redrawStrokes();
    }
    s.editor.setState(() {});
    await tester.pump();
    _timings.add('notebook: 30 pages of ${s.page.strokes.length} strokes');
    s.tool = Highlighter.currentHighlighter
      ..options.size = 22
      ..color = Colors.yellow.withAlpha(100);
    await s.timed('notebook: 60 highlighters on one spot', () async {
      for (int i = 0; i < 60; i++) {
        await s.draw(
          _wobbly(const Offset(40, 300), const Offset(330, 304), i),
          speed: 1500,
        );
      }
    });

    for (final type in EraserType.values) {
      Eraser.type = type;
      s.tool = Eraser();
      await s.timed('notebook: ${type.name} eraser, fast', () async {
        await s.draw(
          _zigzag(const Rect.fromLTWH(20, 60, 360, 400), rows: 6),
          speed: 2500,
        );
      });
      s.editor.undo();
      await tester.pump();
    }
    final screen = tester.getRect(find.byType(Editor));
    Future<void> fingers(
      List<Offset> from,
      Offset by, {
      double spread = 0,
    }) async {
      final gestures = [
        for (final _ in from)
          await tester.createGesture(kind: PointerDeviceKind.touch),
      ];
      for (final (i, g) in gestures.indexed) {
        await g.down(from[i]);
      }
      for (int step = 0; step < 30; step++) {
        for (final (i, g) in gestures.indexed) {
          final away = i == 0 ? -spread : spread;
          await g.moveBy(by / 30 + Offset(0, away / 30));
        }
        final frame = Stopwatch()..start();
        await tester.pump(const Duration(milliseconds: 16));
        s.frameMicros.add(frame.elapsedMicroseconds);
      }
      for (final g in gestures) {
        await g.up();
      }
      await tester.pump(const Duration(milliseconds: 16));
    }

    await s.timed('notebook: scroll down 8 flicks', () async {
      for (int i = 0; i < 8; i++) {
        await fingers([
          screen.center + const Offset(0, 300),
        ], const Offset(0, -900));
      }
    });
    await s.timed('notebook: pinch zoom in and out', () async {
      for (int i = 0; i < 3; i++) {
        await fingers(
          [
            screen.center - const Offset(0, 80),
            screen.center + const Offset(0, 80),
          ],
          Offset.zero,
          spread: 250,
        );
        await fingers(
          [
            screen.center - const Offset(0, 330),
            screen.center + const Offset(0, 330),
          ],
          Offset.zero,
          spread: -250,
        );
      }
    });
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await s.shot('notebook_after_zoom');
    // the zoom's settling timers
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('a picture put over writing covers it', (tester) async {
    final s = await _Session.open(tester, 'picture');
    // a shape, some words and highlighter over them, on the left half and
    // on the right half of the page
    s.tool = Pen.currentBallpointPen;
    for (final x in [40.0, 220.0]) {
      await s.draw([
        Offset(x, 80),
        Offset(x + 140, 80),
        Offset(x + 140, 200),
        Offset(x, 200),
        Offset(x, 80),
      ]);
      for (int i = 0; i < 3; i++) {
        await s.draw(
          _cursive(Offset(x + 15, 110 + i * 30.0), width: 110, seed: i),
        );
      }
    }
    s.tool = Highlighter.currentHighlighter
      ..options.size = 22
      ..color = Colors.yellow.withAlpha(100);
    for (final x in [40.0, 220.0]) {
      await s.draw([Offset(x + 10, 140), Offset(x + 130, 142)]);
    }
    await tester.pump(const Duration(seconds: 1));
    await s.shot('before_pictures');

    // a white picture over the left one, a grey one over the right one
    final pictures = <EditorImage>[];
    for (final (i, color) in [Colors.white, Colors.grey].indexed) {
      final bytes = (await tester.runAsync(() => _plainPng(color)))!;
      pictures.add(
        PngEditorImage(
            id: i,
            extension: '.png',
            imageProvider: MemoryImage(bytes),
            pageIndex: 0,
            pageSize: s.page.size,
            onMoveImage: null,
            onDeleteImage: null,
            onMiscChange: null,
            assetCache: s.editor.coreInfo.assetCache,
          )
          ..dstRect = Rect.fromPoints(
            s.toPage(Offset(i == 0 ? 25 : 205, 65)),
            s.toPage(Offset(i == 0 ? 195 : 375, 215)),
          ),
      );
    }
    s.editor.setState(
      () => s.page.putImagesInFront(pictures, layer: s.page.activeLayer),
    );
    for (int i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    await s.shot('after_pictures');
    // nothing written before the pictures shows over them
    for (final stroke in s.page.strokes) {
      expect(s.page.isOnFrontImage(stroke), isFalse);
    }

    // writing on a picture afterwards goes over it
    s.tool = Pen.currentBallpointPen;
    await s.draw(_cursive(const Offset(60, 170), width: 100, seed: 9));
    await tester.pump(const Duration(seconds: 1));
    await s.shot('written_on_picture');
    expect(s.page.isOnFrontImage(s.page.strokes.last), isTrue);
    // the pictures off the page, and the 5 s until they're let go of from
    // memory, before the test ends
    s.editor.setState(s.page.images.clear);
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('pen and highlighter in turn: six layers, shapes, on a picture', (
    tester,
  ) async {
    final s = await _Session.open(tester, 'layers');
    final pen = Pen.currentBallpointPen..color = const Color(0xFF2A55B8);
    final marker = Highlighter.currentHighlighter..options.size = 30;
    const markers = [Color(0xFFFFD233), Color(0xFF7ED957), Color(0xFFFF8FC8)];

    // pen across, highlighter down, three times, each over the last
    Future<void> staircase(double left, double top) async {
      for (int i = 0; i < 3; i++) {
        s.tool = pen;
        await s.draw([
          Offset(left, top + 20 + i * 35.0),
          Offset(left + 150, top + 20 + i * 35.0),
        ]);
        s.tool = marker..color = markers[i].withAlpha(150);
        await s.draw([
          Offset(left + 25 + i * 45.0, top),
          Offset(left + 25 + i * 45.0, top + 120),
        ]);
      }
    }

    await staircase(30, 40);
    await tester.pump(const Duration(seconds: 1));
    await s.shot('1_six_layers');
    expect(
      CanvasPainter.inkBands(s.page.strokes, s.page.size).length,
      6,
      reason: 'pen and highlighter three times over each other: six layers',
    );

    // shape, highlighter, shape, highlighter
    ShapePen.kind = ShapeKind.rectangle;
    s.tool = ShapePen.currentShapePen..color = Colors.black;
    await s.draw([const Offset(220, 50), const Offset(320, 110)]);
    s.tool = marker..color = markers[0].withAlpha(150);
    await s.draw([const Offset(210, 80), const Offset(340, 80)]);
    s.tool = ShapePen.currentShapePen..color = Colors.red;
    await s.draw([const Offset(250, 70), const Offset(350, 140)]);
    s.tool = marker..color = markers[1].withAlpha(150);
    await s.draw([const Offset(240, 120), const Offset(370, 120)]);
    await tester.pump(const Duration(seconds: 1));
    await s.shot('2_shapes');

    // the same on a picture put on the page
    final bytes = (await tester.runAsync(() => _plainPng(Colors.white)))!;
    final picture =
        PngEditorImage(
            id: 0,
            extension: '.png',
            imageProvider: MemoryImage(bytes),
            pageIndex: 0,
            pageSize: s.page.size,
            onMoveImage: null,
            onDeleteImage: null,
            onMiscChange: null,
            assetCache: s.editor.coreInfo.assetCache,
          )
          ..dstRect = Rect.fromPoints(
            s.toPage(const Offset(20, 210)),
            s.toPage(const Offset(220, 390)),
          );
    s.editor.setState(
      () => s.page.putImagesInFront([picture], layer: s.page.activeLayer),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await staircase(40, 240);
    for (int i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    await s.shot('3_on_a_picture');

    // a typed text box put over a highlighter, and a highlighter drawn
    // over a text box afterwards (wider than it): the later one on top
    s.tool = marker..color = markers[0].withAlpha(150);
    await s.draw([const Offset(240, 250), const Offset(380, 250)]);
    final under = s.page.strokes.last;
    final box = SvgEditorImage(
      id: 1,
      assetCache: s.editor.coreInfo.assetCache,
      svgString: stickyNoteToSvg(const StickyNoteResult('Typed over it', null)),
      svgFile: null,
      pageIndex: 0,
      pageSize: s.page.size,
      onMoveImage: null,
      onDeleteImage: null,
      onMiscChange: null,
    )..dstRect = Rect.fromPoints(
        s.toPage(const Offset(250, 235)),
        s.toPage(const Offset(370, 270)),
      );
    s.editor.setState(
      () => s.page.putImagesInFront([box], layer: s.page.activeLayer),
    );
    await tester.pump(const Duration(milliseconds: 300));
    s.tool = marker..color = markers[2].withAlpha(150);
    await s.draw([const Offset(230, 262), const Offset(390, 262)]);
    final over = s.page.strokes.last;
    for (int i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    await s.shot('4_text_box');
    expect(
      s.page.isOnFrontImage(under),
      isFalse,
      reason: 'the highlighter from before the text box is under it',
    );
    expect(
      s.page.isOnFrontImage(over),
      isTrue,
      reason: 'the highlighter drawn after the text box is over it',
    );

    // sticky note, highlighter on it (inside it), a second sticky note
    // over that: the second covers the highlighter, the first stays under it
    SvgEditorImage note(Color color, Offset a, Offset b, int id) =>
        SvgEditorImage(
          id: id,
          assetCache: s.editor.coreInfo.assetCache,
          svgString: stickyNoteToSvg(StickyNoteResult('note', color)),
          svgFile: null,
          pageIndex: 0,
          pageSize: s.page.size,
          onMoveImage: null,
          onDeleteImage: null,
          onMiscChange: null,
        )..dstRect = Rect.fromPoints(s.toPage(a), s.toPage(b));
    s.editor.setState(
      () => s.page.putImagesInFront([
        note(const Color(0xFFCDE7FF), const Offset(240, 300), const Offset(360, 380), 2),
      ], layer: s.page.activeLayer),
    );
    await tester.pump(const Duration(milliseconds: 300));
    s.tool = marker..color = markers[0].withAlpha(150);
    await s.draw([const Offset(255, 340), const Offset(345, 340)]);
    final onFirst = s.page.strokes.last;
    s.editor.setState(
      () => s.page.putImagesInFront([
        note(const Color(0xFFFFD9C7), const Offset(300, 320), const Offset(390, 400), 3),
      ], layer: s.page.activeLayer),
    );
    for (int i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    await s.shot('5_notes');
    final front = EditorPage.inOrder(s.page.images.where((i) => i.inFront));
    final second = front.last;
    expect(
      s.page.tierOf(onFirst, front),
      lessThanOrEqualTo(front.indexOf(second)),
      reason: 'the second note covers the highlighter',
    );
    expect(
      s.page.tierOf(onFirst, front),
      greaterThan(front.indexWhere((i) => i.id == 2)),
      reason: 'the highlighter is over the first note',
    );

    // the pictures off the page, and the 5 s until they're let go of from
    // memory, before the test ends
    s.editor.setState(s.page.images.clear);
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('sticky note: pen dots, hold to pick, double tap to type', (
    tester,
  ) async {
    final s = await _Session.open(tester, 'sticky_touch');
    s.tool = Pen.fountainPen();
    const note = StickyNoteResult('Hi', Color(0xFFFFF176));
    final image = SvgEditorImage(
      id: 7,
      assetCache: s.editor.coreInfo.assetCache,
      svgString: stickyNoteToSvg(note),
      svgFile: null,
      pageIndex: 0,
      pageSize: s.page.size,
      onMoveImage: null,
      onDeleteImage: null,
      onMiscChange: null,
    )..dstRect = Rect.fromLTWH(
        s.toPage(const Offset(80, 100)).dx,
        s.toPage(const Offset(80, 100)).dy,
        260,
        260,
      );
    s.editor.setState(
      () => s.page.putImagesInFront([image], layer: s.page.activeLayer),
    );
    await tester.pump(const Duration(milliseconds: 300));
    final middle = image.dstRect.center / (s.page.size.width / 400);

    // the stem of an i, a pause, then its dot: the dot stays, nothing picked
    await s.draw([middle, middle + const Offset(0, 30)]);
    await tester.pump(const Duration(seconds: 2));
    final before = s.page.strokes.length;
    await s.draw([
      middle + const Offset(0, -15),
      middle + const Offset(0.5, -14.5),
    ]);
    await tester.pump(const Duration(milliseconds: 100));
    expect(s.page.strokes.length, before + 1, reason: 'the dot is kept');
    expect(s.editor.currentTool, isNot(isA<Select>()), reason: 'pen tap');
    await s.shot('1_dot_kept');

    // a finger's tap: nothing
    await tester.tapAt(s.toScreen(s.toPage(middle + const Offset(40, 40))));
    await tester.pump(const Duration(milliseconds: 100));
    expect(s.editor.currentTool, isNot(isA<Select>()), reason: 'finger tap');

    // the pen held still on it: picked, with no dot left
    await s.draw([
      middle + const Offset(50, 0),
      middle + const Offset(50.5, 0.5),
    ], lift: false);
    await tester.pump(const Duration(milliseconds: 500));
    await s.lift();
    await tester.pump(const Duration(milliseconds: 100));
    expect(s.page.strokes.length, before + 1, reason: 'no dot from the hold');
    expect(s.editor.currentTool, isA<Select>());
    expect(Select.currentSelect.singleImage, image, reason: 'held: picked');
    await s.shot('2_held_picked');

    // the bar right under the box's rotate handle, not under the loop
    final bar = tester.getRect(
      find
          .descendant(
            of: find.byType(SelectionActionBar),
            matching: find.byType(Material),
          )
          .first,
    );
    final boxBottom = s.toScreen(
      Offset(0, Select.currentSelect.box.bottom),
    ).dy;
    expect(bar.top - boxBottom, inInclusiveRange(40, 90), reason: '$bar');

    // a finger's double tap: typed right on the note
    s.editor.setState(Select.currentSelect.unselect);
    s.tool = Pen.fountainPen();
    await tester.pump();
    final at = s.toScreen(s.toPage(middle));
    await tester.tapAt(at);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tapAt(at);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(NoteTextOverlay), findsOneWidget);
    expect(find.byType(Dialog), findsNothing, reason: 'no sheet over it');
    await tester.enterText(
      find.descendant(
        of: find.byType(NoteTextOverlay),
        matching: find.byType(TextField),
      ),
      'Exam on Monday\nrevise ch 3\nbring pens\nand the ruler',
    );
    await tester.pump(const Duration(milliseconds: 100));
    await s.shot('3_typing_on_it');
    await tester.tap(find.byTooltip('Done'));
    for (int i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(NoteTextOverlay), findsNothing);
    final bytes = await tester.runAsync(image.fileBytes);
    expect(
      stickyNoteFromSvg(utf8.decode(bytes!))!.text,
      'Exam on Monday\nrevise ch 3\nbring pens\nand the ruler',
    );
    await s.shot('4_typed');

    s.editor.setState(s.page.images.clear);
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('redesign tour on a tablet: bar, insert, share, layers, timer', (
    tester,
  ) async {
    final s = await _Session.open(
      tester,
      'tour',
      size: const Size(2560, 1600),
    );
    Future<void> settle() async {
      for (int i = 0; i < 4; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 150));
      }
    }

    Future<void> close() async {
      await tester.state<NavigatorState>(find.byType(Navigator).last).maybePop();
      await settle();
    }

    Future<void> insert(String row, String name) async {
      await tester.tap(find.bySemanticsLabel('Insert').first);
      await settle();
      if (name == '2_insert') await s.shot(name);
      final target = find.text(row);
      if (target.evaluate().isEmpty) {
        await close();
        return;
      }
      await tester.tap(target.first);
      await settle();
      if (name != '2_insert') await s.shot(name);
    }

    s.tool = Pen.fountainPen();
    await s.draw([const Offset(60, 80), const Offset(200, 90)]);
    await settle();
    await s.shot('1_floating_bar');

    stows.toolbarDocked.value = true;
    addTearDown(() => stows.toolbarDocked.value = false);
    s.editor.setState(() {});
    await settle();
    await s.shot('1_docked_bar');

    await insert('__none__', '2_insert');
    await insert('Timer & stopwatch', '3_timer');
    await close();
    await insert('Ruler', '4_ruler');
    await insert('Ruler', '4_ruler_off');
    await insert('Zoom window', '5_zoom_window');
    await insert('Zoom window', '5_zoom_off');
    await insert('Recordings', '6_recordings');

    await tester.tap(find.byTooltip('Share and export').first);
    await settle();
    await s.shot('7_share');
    await close();

    await tester.tap(find.byTooltip('More').first);
    await settle();
    await s.shot('8_more');
    final layers = find.text('Layers');
    if (layers.evaluate().isNotEmpty) {
      await tester.tap(layers.first);
      await settle();
      await s.shot('9_layers');
    }
    await close();
  });

  testWidgets('a note closed and opened again at once is read whole', (
    tester,
  ) async {
    Editor.waitForClosing = true;
    addTearDown(() => Editor.waitForClosing = false);
    final s = await _Session.open(tester, 'reopen');
    s.tool = Pen.fountainPen();
    // a note big enough to be read on a worker, as real ones are
    for (int i = 0; i < 40; i++) {
      await s.draw([Offset(40, 40.0 + i * 12), Offset(360, 44.0 + i * 12)]);
    }
    final strokes = s.page.strokes.length;
    // closed: its last save starts as it goes; opened again straight away
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpWidget(
      RepaintBoundary(
        key: _shotKey,
        child: MaterialApp(home: Editor(path: '/scenario-reopen')),
      ),
    );
    for (int i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    final again = tester.state<EditorState>(find.byType(Editor));
    expect(again.coreInfo.readOnlyReason, isNull, reason: 'not "corrupted"');
    expect(again.coreInfo.pages.first.strokes.length, strokes);
    again.cancelAutosaveAndMarkSaved();
  });

  testWidgets('option previews, at four moments of their loop', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 1300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final previews = <String, Widget>{
      'Pressure curve': const PressurePreview(),
      'Lasso picks': const LassoPreview(),
      'Palm rejection': const PalmPreview(),
      'Eraser: precision': const EraserPreview(EraserType.precision),
      'Eraser: whole stroke': const EraserPreview(EraserType.stroke),
      'Scribble to erase': const ScribblePreview(),
      'Laser: dot': const LaserPreview(dot: true, color: Colors.red, glow: false),
      'Laser: line': const LaserPreview(dot: false, color: Colors.red, glow: true),
      'Scroll: vertical': const ScrollPreview(horizontal: false),
      'Scroll: horizontal': const ScrollPreview(horizontal: true),
      'Tape': const TapePreview(),
      'Draw & hold: circle': const SnapPreview.circle(),
      'Draw shapes: rectangle': const SnapPreview.rectangle(),
      'Circle to lasso': const CircleLassoPreview(),
      'Ink in dark mode': const DarkInkPreview(),
      'Shape stroke': const ShapeStylePreview(
        style: ShapeStyle(
          line: ShapeLine.dashed,
          fill: Color(0x332B4ACB),
          arrowEnd: ShapeArrow.filled,
        ),
        color: Color(0xFF2B4ACB),
        width: 3,
      ),
    };
    await tester.pumpWidget(
      RepaintBoundary(
        key: _shotKey,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: const Color(0xFFF2F1EC),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final MapEntry(:key, :value) in previews.entries)
                    SizedBox(
                      width: 270,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 6,
                        children: [Text(key), value],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    for (final (i, ms) in const [600, 800, 800, 800].indexed) {
      await tester.pump(Duration(milliseconds: ms));
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(_shotKey),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        File('${_out.path}/previews_${i + 1}.png')
            .writeAsBytesSync(png!.buffer.asUint8List());
      });
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('pen, highlighter, pen: order, erasing, undo and redo', (
    tester,
  ) async {
    final s = await _Session.open(tester, 'phpen');
    void noHang() => expect(
      s.frameMicros.isEmpty ? 0 : s.frameMicros.reduce(max),
      lessThan(700000),
      reason: 'a frame took long enough to look like a hang',
    );
    s.tool = Pen.currentPen;
    await s.timed('php: words', () async {
      for (int i = 0; i < 3; i++) {
        await s.draw(_cursive(Offset(40, 100 + i * 30.0), width: 300, seed: i));
      }
    });
    noHang();
    final words = s.page.strokes.toList();
    s.tool = Highlighter.currentHighlighter
      ..options.size = 22
      ..color = Colors.yellow.withAlpha(100);
    await s.timed('php: highlighter over the words', () async {
      for (int i = 0; i < 3; i++) {
        await s.draw([Offset(35, 95 + i * 30.0), Offset(355, 97 + i * 30.0)]);
      }
    });
    noHang();
    final markers = s.page.strokes
        .where((x) => x.toolId == .highlighter)
        .toList();
    s.tool = Pen.currentPen;
    await s.timed('php: words written over the highlighter', () async {
      await s.draw(_cursive(const Offset(40, 160), width: 300, seed: 7));
    });
    noHang();
    final after = s.page.strokes.last;
    await tester.pump(const Duration(seconds: 1));
    await s.shot('1_written');
    final bands = CanvasPainter.inkBands(s.page.strokes, s.page.size);
    expect(bands[0], containsAll(words), reason: 'words before it go under it');
    expect(bands[2], contains(after), reason: 'words after it go over it');

    // the precise eraser straight down through all of it
    Eraser.type = EraserType.precision;
    s.tool = Eraser();
    final before = s.page.strokes.length;
    await s.timed('php: precise eraser through pen and highlighter', () async {
      await s.draw([const Offset(200, 60), const Offset(200, 200)]);
    });
    noHang();
    await tester.pump(const Duration(seconds: 1));
    await s.shot('2_erased');
    for (final marker in s.page.strokes.where(
      (x) => x.toolId == .highlighter,
    )) {
      expect(marker.holes, isNotEmpty, reason: 'every highlighter is cut');
    }
    expect(
      s.page.strokes.where((x) => x.toolId != .highlighter).length,
      greaterThan(before - markers.length),
      reason: 'pens are cut into pieces',
    );

    s.editor.undo();
    await tester.pump(const Duration(seconds: 1));
    expect(s.page.strokes.length, before, reason: 'undo brings them back');
    expect(
      s.page.strokes
          .where((x) => x.toolId == .highlighter)
          .every((x) => x.holes.isEmpty),
      isTrue,
      reason: 'undo takes the holes out',
    );
    s.editor.redo();
    await tester.pump(const Duration(seconds: 1));
    expect(
      s.page.strokes
          .where((x) => x.toolId == .highlighter)
          .every((x) => x.holes.isNotEmpty),
      isTrue,
      reason: 'redo cuts them again',
    );
    await s.shot('3_redone');

    // the stroke eraser that only takes highlighter
    final filter = stows.eraserFilter.value;
    addTearDown(() => stows.eraserFilter.value = filter);
    stows.eraserFilter.value = ['highlighter'];
    Eraser.type = EraserType.stroke;
    final pens = s.page.strokes.where((x) => x.toolId != .highlighter).length;
    await s.draw([const Offset(60, 60), const Offset(340, 220)]);
    await tester.pump(const Duration(seconds: 1));
    expect(s.page.strokes.where((x) => x.toolId == .highlighter), isEmpty);
    expect(
      s.page.strokes.where((x) => x.toolId != .highlighter).length,
      pens,
      reason: 'only highlighter was taken',
    );
    await s.shot('4_highlighter_only');
    Eraser.type = EraserType.precision;
  });

  testWidgets('two layers: pen, highlighter and eraser on each', (
    tester,
  ) async {
    final s = await _Session.open(tester, 'layers');
    void noHang() => expect(
      s.frameMicros.isEmpty ? 0 : s.frameMicros.reduce(max),
      lessThan(700000),
    );
    final bottom = s.page.activeLayer;
    s.tool = Pen.currentPen;
    for (int i = 0; i < 3; i++) {
      await s.draw(_cursive(Offset(40, 100 + i * 30.0), width: 300, seed: i));
    }
    s.tool = Highlighter.currentHighlighter
      ..options.size = 22
      ..color = Colors.yellow.withAlpha(100);
    await s.draw([const Offset(35, 125), const Offset(355, 127)]);

    // a second layer on top
    s.editor.setState(s.page.addLayer);
    final top = s.page.activeLayer;
    expect(top, isNot(bottom));
    s.tool = Highlighter.currentHighlighter
      ..color = Colors.lightBlue.withAlpha(100);
    await s.draw([const Offset(35, 95), const Offset(355, 97)]);
    s.tool = Pen.currentPen;
    await s.draw(_cursive(const Offset(40, 190), width: 300, seed: 5));
    await tester.pump(const Duration(seconds: 1));
    await s.shot('1_two_layers');
    expect(s.page.strokes.where((x) => x.layer == top).length, 2);

    // top layer locked: the eraser works on the bottom one only
    s.editor.setState(() {
      s.page.layers.firstWhere((l) => l.id == top).locked = true;
      s.page.updateActiveLayer();
    });
    final topBefore = s.page.strokes.where((x) => x.layer == top).toList();
    Eraser.type = EraserType.precision;
    s.tool = Eraser();
    await s.timed('layers: precise eraser, top layer locked', () async {
      await s.draw([const Offset(120, 60), const Offset(120, 220)]);
      await s.draw([const Offset(260, 60), const Offset(260, 220)]);
    });
    noHang();
    await tester.pump(const Duration(seconds: 1));
    await s.shot('2_bottom_erased');
    final topAfter = s.page.strokes.where((x) => x.layer == top).toList();
    expect(topAfter.length, topBefore.length, reason: 'locked layer untouched');
    expect(topAfter.every((x) => x.holes.isEmpty), isTrue);
    expect(
      s.page.strokes
          .where((x) => x.layer == bottom && x.toolId == .highlighter)
          .single
          .holes,
      isNotEmpty,
      reason: 'bottom layer highlighter cut',
    );

    // bottom hidden and top unlocked: now only the top is erased
    s.editor.setState(() {
      s.page.layers.firstWhere((l) => l.id == top).locked = false;
      s.page.layers.firstWhere((l) => l.id == bottom).visible = false;
      s.page.updateActiveLayer();
    });
    final bottomBefore = s.page.strokes.where((x) => x.layer == bottom).length;
    await s.timed('layers: precise eraser, bottom layer hidden', () async {
      await s.draw([const Offset(190, 60), const Offset(190, 220)]);
    });
    noHang();
    await tester.pump(const Duration(seconds: 1));
    await s.shot('3_top_erased_bottom_hidden');
    expect(
      s.page.strokes.where((x) => x.layer == bottom).length,
      bottomBefore,
      reason: 'hidden layer untouched',
    );
    expect(
      s.page.strokes
          .where((x) => x.layer == top && x.toolId == .highlighter)
          .single
          .holes,
      isNotEmpty,
    );
    s.editor.setState(() {
      s.page.layers.firstWhere((l) => l.id == bottom).visible = true;
    });
    await tester.pump(const Duration(seconds: 1));
    await s.shot('4_both_shown');
  });

  testWidgets('a page full of pen and highlighter in turn, erased and zoomed', (
    tester,
  ) async {
    final s = await _Session.open(tester, 'mixed');
    void noHang() => expect(
      s.frameMicros.isEmpty ? 0 : s.frameMicros.reduce(max),
      lessThan(700000),
    );
    await s.timed('mixed: 200 strokes, pen and highlighter in turn', () async {
      for (int i = 0; i < 200; i++) {
        final y = 40 + (i % 50) * 10.0;
        if (i.isEven) {
          s.tool = Pen.currentPen;
          await s.draw(
            _cursive(Offset(30, y), width: 320, seed: i),
            speed: 2500,
          );
        } else {
          s.tool = Highlighter.currentHighlighter
            ..options.size = 18
            ..color = (i % 4 == 1 ? Colors.yellow : Colors.pink).withAlpha(100);
          await s.draw([Offset(25, y - 4), Offset(360, y - 2)], speed: 2500);
        }
      }
    });
    noHang();
    Eraser.type = EraserType.precision;
    s.tool = Eraser();
    await s.timed('mixed: precise eraser, 10 lines through it all', () async {
      for (int i = 0; i < 10; i++) {
        await s.draw([Offset(30 + i * 34.0, 20), Offset(40 + i * 34.0, 540)]);
      }
    });
    noHang();
    await tester.pump(const Duration(seconds: 1));
    await s.shot('erased');
  });

  testWidgets('many highlighters on one spot, written over, then zoomed', (
    tester,
  ) async {
    final s = await _Session.open(tester, 'stacked');
    s.tool = Highlighter.currentHighlighter
      ..options.size = 22
      ..color = Colors.yellow.withAlpha(100);
    await s.timed('stacked: 120 highlighters', () async {
      for (int i = 0; i < 120; i++) {
        await s.draw(
          _wobbly(
            Offset(40, 200 + (i % 6) * 4.0),
            Offset(330, 204 + (i % 6) * 4.0),
            i,
          ),
          speed: 2000,
        );
      }
    });
    s.tool = Pen.currentBallpointPen;
    await s.timed('stacked: 60 words over them', () async {
      for (int i = 0; i < 60; i++) {
        await s.draw(
          _cursive(
            Offset(40 + (i % 6) * 50.0, 195 + (i ~/ 6) * 4.0),
            width: 45,
            seed: i,
          ),
          speed: 2500,
        );
      }
    });
    final screen = tester.getRect(find.byType(Editor));
    Future<void> pinch(double spread) async {
      final a = await tester.createGesture(kind: PointerDeviceKind.touch);
      final b = await tester.createGesture(kind: PointerDeviceKind.touch);
      final gap = spread > 0 ? 80.0 : 330.0;
      await a.down(screen.center - Offset(0, gap));
      await b.down(screen.center + Offset(0, gap));
      for (int step = 0; step < 30; step++) {
        await a.moveBy(Offset(0, -spread / 30));
        await b.moveBy(Offset(0, spread / 30));
        final frame = Stopwatch()..start();
        await tester.pump(const Duration(milliseconds: 16));
        s.frameMicros.add(frame.elapsedMicroseconds);
      }
      await a.up();
      await b.up();
      final frame = Stopwatch()..start();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 16));
      s.frameMicros.add(frame.elapsedMicroseconds);
    }

    await s.timed('stacked: zoom in and out 4 times', () async {
      for (int i = 0; i < 4; i++) {
        await pinch(250);
        await pinch(-250);
      }
    });
    await tester.pump(const Duration(seconds: 1));
    await s.shot('stacked_after_zoom');
    // the precise eraser back and forth across all of them, again and again
    Eraser.type = EraserType.precision;
    s.tool = Eraser();
    await s.timed('stacked: precise eraser over all 120, 12 times', () async {
      for (int i = 0; i < 12; i++) {
        await s.draw(
          _wobbly(Offset(60 + i * 20.0, 150), Offset(70 + i * 20.0, 260), i),
          speed: 1200,
        );
      }
    });
    await tester.pump(const Duration(seconds: 1));
    await s.shot('stacked_after_erasing');
  });

  _penGestures();
  _zoomFeel();
  _heavyNote();
}

/// Pinch zoom the way a hand does it: at a corner of the page, in, out past
/// the whole page and back. The point of the page that was under the
/// fingers should stay under them, and a page smaller than the screen ends
/// up in the middle. What happened goes to build/scenarios/zoom.txt.
/// Scrolling and zooming a note of many full pages: how long each frame
/// takes to make, and whether the page jumps under the fingers.
void _heavyNote() {
  testWidgets('heavy note: scroll and zoom through 30 full pages', (
    tester,
  ) async {
    final left = File('$tmpDir/badnotes-test-docs/BadNotes/scenario-heavy.sbn2');
    if (left.existsSync()) left.deleteSync();
    final s = await _Session.open(tester, 'heavy');
    final editor = s.editor;
    const pages = 30;
    for (int p = 0; p < pages; p++) {
      editor.createPage(p);
      final page = editor.coreInfo.pages[p];
      final scale = page.size.width / 400;
      Stroke line(ToolId tool, Color color, List<Offset> points, double size) =>
          Stroke(
              color: color,
              pressureEnabled: false,
              options: StrokeOptions(size: size, isComplete: true),
              pageIndex: p,
              page: page,
              toolId: tool,
            )
            ..nib2 = true
            ..addPoints([for (final point in points) point * scale]);
      // a page of cursive writing, 3 words to a line, and a few highlights
      if (const bool.fromEnvironment('HEAVY_EMPTY')) continue;
      for (int row = 0; row < 40; row++) {
        for (int word = 0; word < 3; word++) {
          page.insertStroke(
            line(
              .fountainPen,
              Colors.black,
              _cursive(
                Offset(20 + word * 125.0, 20 + row * 13.0),
                width: 110,
                seed: p * 1000 + row * 3 + word,
              ),
              2.5,
            ),
          );
        }
      }
      for (int h = 0; h < 6; h++) {
        page.insertStroke(
          line(
            .highlighter,
            Colors.yellow.withAlpha(110),
            [Offset(20, 30 + h * 80.0), Offset(380, 32 + h * 80.0)],
            24,
          ),
        );
      }
    }
    // ignore: invalid_use_of_protected_member
    editor.setState(() {});
    tester.view.physicalSize = const Size(2560, 1600);
    tester.view.devicePixelRatio = 2;
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    final viewer = tester.getRect(find.byType(InteractiveCanvasViewer));
    final controller = tester
        .widget<InteractiveCanvasViewer>(find.byType(InteractiveCanvasViewer))
        .transformationController!;
    String stats(String what, List<int> micros) {
      micros.sort();
      final p50 = micros[micros.length ~/ 2] / 1000;
      final p95 = micros[(micros.length * 0.95).floor().clamp(0, micros.length - 1)] / 1000;
      return '$what: ${micros.length} frames, p50 ${p50.toStringAsFixed(1)} '
          'ms, p95 ${p95.toStringAsFixed(1)} ms, max '
          '${(micros.last / 1000).toStringAsFixed(1)} ms';
    }

    // a finger dragging the pages up, then a fling
    final scroll = <int>[];
    final finger = await tester.createGesture(kind: PointerDeviceKind.touch);
    await finger.down(viewer.center + const Offset(0, 250));
    for (int i = 0; i < 40; i++) {
      await finger.moveBy(const Offset(0, -24));
      final frame = Stopwatch()..start();
      await tester.pump(const Duration(milliseconds: 11));
      scroll.add(frame.elapsedMicroseconds);
    }
    await finger.up();
    final fling = <int>[];
    for (int i = 0; i < 90; i++) {
      final frame = Stopwatch()..start();
      await tester.pump(const Duration(milliseconds: 11));
      fling.add(frame.elapsedMicroseconds);
    }
    final scrolledTo = -controller.value.getTranslation().y;

    // two fingers zooming in on the page in view, and out again
    final zoom = <int>[];
    var jump = 0.0;
    Future<void> pinch(double from, double to) async {
      final at = viewer.center;
      final a = await tester.createGesture(kind: PointerDeviceKind.touch);
      final b = await tester.createGesture(kind: PointerDeviceKind.touch);
      const dir = Offset(0.8, 0.6);
      await a.down(at - dir * (from / 2));
      await b.down(at + dir * (from / 2));
      await tester.pump(const Duration(milliseconds: 11));
      Offset? under;
      for (int step = 1; step <= 30; step++) {
        final gap = from + (to - from) * step / 30;
        final prev = from + (to - from) * (step - 1) / 30;
        await a.moveBy(-dir * ((gap - prev) / 2));
        await b.moveBy(dir * ((gap - prev) / 2));
        final frame = Stopwatch()..start();
        await tester.pump(const Duration(milliseconds: 11));
        zoom.add(frame.elapsedMicroseconds);
        if (step >= 4) {
          under ??= controller.toScene(at - viewer.topLeft);
          final now =
              MatrixUtils.transformPoint(controller.value, under) +
              viewer.topLeft;
          jump = max(jump, (now - at).distance);
        }
      }
      await a.up();
      await b.up();
      for (int i = 0; i < 40; i++) {
        final frame = Stopwatch()..start();
        await tester.pump(const Duration(milliseconds: 11));
        zoom.add(frame.elapsedMicroseconds);
      }
    }

    await pinch(200, 600);
    await pinch(600, 200);
    await s.shot('after');
    _timings
      ..add(stats('heavy scroll (finger)', scroll))
      ..add(stats('heavy fling', fling))
      ..add('heavy: scrolled ${scrolledTo.toStringAsFixed(0)} px')
      ..add(stats('heavy pinch', zoom))
      ..add(
        'heavy pinch: page point drifted from the fingers by up to '
        '${jump.toStringAsFixed(0)} px',
      );
    await tester.pump(const Duration(seconds: 6));
    expect(scrolledTo, greaterThan(800), reason: 'it scrolled');
    expect(jump, lessThan(40), reason: 'the page stays under the fingers');
  });
}

void _zoomFeel() {
  testWidgets('zoom: pinch at a corner, in and out', (tester) async {
    // a note left by an earlier run would open where it was zoomed to
    final left = File('$tmpDir/badnotes-test-docs/BadNotes/scenario-zoom.sbn2');
    if (left.existsSync()) left.deleteSync();
    final s = await _Session.open(tester, 'zoom');
    s.tool = Pen.currentBallpointPen;
    for (int i = 0; i < 6; i++) {
      await s.draw(_cursive(Offset(30, 40 + i * 70.0), width: 330, seed: i));
    }
    expect(s.page.strokes, hasLength(6));
    // the tablet in the video, sideways
    tester.view.physicalSize = const Size(2560, 1600);
    tester.view.devicePixelRatio = 2;
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    final lines = <String>[];
    final controller = tester
        .widget<InteractiveCanvasViewer>(find.byType(InteractiveCanvasViewer))
        .transformationController!;
    final viewer = tester.getRect(find.byType(InteractiveCanvasViewer));
    Offset toScene(Offset screen) =>
        controller.toScene(screen - viewer.topLeft);
    Offset toScreen(Offset scene) =>
        MatrixUtils.transformPoint(controller.value, scene) + viewer.topLeft;

    /// Two fingers around [at], [from] apart to [to] apart, in [steps]
    /// moves a frame each. Returns how far (screen pixels) the page point
    /// that started under the fingers got from them: the most, and at the
    /// end, and the biggest jump of the page in one frame beyond what the
    /// fingers moved.
    Future<String> pinch(
      String what,
      Offset at,
      double from,
      double to, {
      int steps = 30,
    }) async {
      final a = await tester.createGesture(kind: PointerDeviceKind.touch);
      final b = await tester.createGesture(kind: PointerDeviceKind.touch);
      const dir = Offset(0.8, 0.6);
      await a.down(at - dir * (from / 2));
      await b.down(at + dir * (from / 2));
      await tester.pump(const Duration(milliseconds: 16));
      Offset? under;
      var worst = 0.0;
      var drift = 0.0;
      var jump = 0.0;
      Offset? lastTopLeft;
      final scale0 = controller.value.getMaxScaleOnAxis();
      for (int step = 1; step <= steps; step++) {
        final gap = from + (to - from) * step / steps;
        final prevGap = from + (to - from) * (step - 1) / steps;
        await a.moveBy(-dir * ((gap - prevGap) / 2));
        await b.moveBy(dir * ((gap - prevGap) / 2));
        await tester.pump(const Duration(milliseconds: 16));
        // the gesture starts zooming after a few moves: from then on
        under ??= step >= 4 ? toScene(at) : null;
        if (under != null) {
          drift = (toScreen(under) - at).distance;
          worst = max(worst, drift);
        }
        final topLeft = toScreen(Offset.zero);
        if (lastTopLeft != null && under != null) {
          // where the page's corner would be if it only scaled about the
          // fingers
          final scale = controller.value.getMaxScaleOnAxis();
          final expected = at + (lastTopLeft - at) * (gap / prevGap);
          jump = max(jump, (topLeft - expected).distance);
          if (scale.isNaN) break;
        }
        lastTopLeft = topLeft;
      }
      final scale1 = controller.value.getMaxScaleOnAxis();
      await s.shot('${what}_held');
      await a.up();
      await b.up();
      await tester.pump(const Duration(milliseconds: 16));
      for (int i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pump(const Duration(milliseconds: 400));
      await s.shot('${what}_after');
      final page = tester.getRect(find.byType(InnerCanvas).first);
      final line =
          '$what: zoom ${scale0.toStringAsFixed(2)} -> '
          '${scale1.toStringAsFixed(2)} (after letting go '
          '${controller.value.getMaxScaleOnAxis().toStringAsFixed(2)}), '
          'page point left the fingers by up to ${worst.toStringAsFixed(0)} '
          'px (${drift.toStringAsFixed(0)} at the end), biggest jump '
          '${jump.toStringAsFixed(0)} px; page left/right gap after '
          '${(page.left - viewer.left).toStringAsFixed(0)}/'
          '${(viewer.right - page.right).toStringAsFixed(0)}';
      lines.add(line);
      return line;
    }

    // fingers 0.8:0.6 apart, the farthest 120 px each side of the middle
    if (const bool.fromEnvironment('DUMP_LAYERS')) {
      s.tool = Highlighter.currentHighlighter
        ..options.size = 40
        ..color = Colors.yellow.withAlpha(100);
      await s.draw(_zigzag(const Rect.fromLTWH(30, 80, 160, 220), rows: 9));
      await tester.pump(const Duration(seconds: 1));
      final a = await tester.createGesture(kind: PointerDeviceKind.touch);
      final b = await tester.createGesture(kind: PointerDeviceKind.touch);
      await a.down(viewer.center - const Offset(40, 0));
      await b.down(viewer.center + const Offset(40, 0));
      for (int i = 0; i < 10; i++) {
        await a.moveBy(const Offset(-8, 0));
        await b.moveBy(const Offset(8, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      // ignore: avoid_print
      print('LAYERS\n${tester.layers.first.toStringDeep()}');
      await a.up();
      await b.up();
      await tester.pump(const Duration(seconds: 6));
      return;
    }
    final corner = viewer.topRight + const Offset(-130, 220);
    await s.shot('start');
    await pinch('in_at_top_right', corner, 80, 240);
    await pinch('out_at_top_right', corner, 240, 30, steps: 40);
    await pinch('in_from_small_at_right', corner, 40, 200);
    await pinch('out_again_at_top_right', corner, 240, 40, steps: 40);
    final bottomLeft = viewer.bottomLeft + const Offset(130, -220);
    await pinch('in_at_bottom_left', bottomLeft, 80, 240);
    await pinch('out_at_bottom_left', bottomLeft, 240, 30, steps: 40);
    // deep: too far in for an image of the whole page
    Offset writing() => s.toScreen(s.toPage(const Offset(120, 244)));
    await pinch('deep_in', writing(), 40, 240);
    await pinch('deep_in_more', writing(), 60, 240);
    await pinch('deep_out', writing(), 240, 60);
    // a pinch where one finger lifts a moment before the other, still
    // moving a little: the page doesn't go on sliding after
    {
      final at = viewer.center;
      final a = await tester.createGesture(kind: PointerDeviceKind.touch);
      final b = await tester.createGesture(kind: PointerDeviceKind.touch);
      await a.down(at - const Offset(60, 0));
      await b.down(at + const Offset(60, 0));
      for (int i = 0; i < 20; i++) {
        await a.moveBy(const Offset(-4, 0));
        await b.moveBy(const Offset(4, 0));
        await tester.pump(const Duration(milliseconds: 8));
      }
      await a.up();
      for (int i = 0; i < 4; i++) {
        await b.moveBy(const Offset(14, 6));
        await tester.pump(const Duration(milliseconds: 8));
      }
      await b.up();
      await tester.pump(const Duration(milliseconds: 16));
      final lifted = controller.value.getTranslation();
      for (int i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      final slid = (controller.value.getTranslation() - lifted).length;
      lines.add('slid after the fingers lifted: ${slid.toStringAsFixed(0)} px');
      // ignore: avoid_print
      print(
        'ZOOM slid after the fingers lifted: ${slid.toStringAsFixed(0)} px',
      );
      expect(slid, lessThan(2));
    }

    // held still, zoomed in: once the tiles are made, no more are
    for (int i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    final made = InkCache.tilesMade;
    for (int i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    // ignore: avoid_print
    print(
      'ZOOM tiles made while still: ${InkCache.tilesMade - made} '
      '(before: $made)',
    );
    File('${_out.path}/zoom.txt').writeAsStringSync(lines.join('\n'));
    // ignore: avoid_print
    print(lines.map((line) => 'ZOOM $line').join('\n'));
    // the zoom level shown fades after 5 s
    await tester.pump(const Duration(seconds: 6));
  });
}

/// The Pen Gestures and Draw and Hold settings, each tried the way a hand
/// would use it, alone and together. What happened goes to
/// build/scenarios/pen_gestures.txt, with a picture of each.
void _penGestures() {
  final results = <String>[];
  void note(String line) => results.add(line);

  // the app's own defaults, as a new user has them
  void defaults() {
    for (final stow in [
      stows.fountainScribbleToErase,
      stows.penScribbleToErase,
      stows.scribbleErasesAll,
      stows.circleToLasso,
      stows.lassoPartly,
      stows.penDrawAndHold,
      stows.shapeFill,
      stows.autoStraightenLines,
    ]) {
      stow.value = stow.defaultValue;
    }
    stows.shapeRecognitionDelay.value = 500;
    ShapePen.debounceDuration = const Duration(milliseconds: 500);
    ShapePen.kind = .auto;
  }

  tearDownAll(() {
    defaults();
    File('${_out.path}/pen_gestures.txt').writeAsStringSync(results.join('\n'));
    // ignore: avoid_print
    print(results.map((line) => 'GESTURE $line').join('\n'));
  });

  /// A word, written at a hand's pace.
  Future<Stroke> word(_Session s, Tool pen, Offset at, {int seed = 1}) async {
    s.tool = pen;
    await s.draw(_cursive(at, width: 120, seed: seed), speed: 700);
    return s.page.strokes.last;
  }

  /// A quick scribble back and forth over [box], as when rubbing out.
  List<Offset> scribble(Rect box) => _zigzag(box, rows: 7);

  String kinds(EditorPage page) =>
      page.strokes.map((stroke) => stroke.toolId.name).join(', ');

  testWidgets('pen gestures: scribble to erase, with each pen', (tester) async {
    defaults();
    final s = await _Session.open(tester, 'gesture_scribble_pens');
    final pens = <String, Tool>{
      'fountain': Pen.currentPen,
      'ballpoint': Pen.currentBallpointPen,
      'brush': Pen.currentBrushPen,
      'calligraphy': Pen.currentCalligraphyPen,
      'pencil': Pencil.currentPencil,
    };
    for (final setting in ['defaults', 'switch on']) {
      if (setting == 'switch on') {
        // what the Pen Gestures switch does
        stows.penScribbleToErase.value = true;
        stows.fountainScribbleToErase.value = true;
      }
      var y = setting == 'defaults' ? 70.0 : 330.0;
      for (final MapEntry(key: name, value: pen) in pens.entries) {
        final written = await word(s, pen, Offset(40, y), seed: y.toInt());
        final before = s.page.strokes.length;
        await s.draw(scribble(Rect.fromLTWH(35, y - 22, 140, 26)), speed: 1500);
        final erased = !s.page.strokes.contains(written);
        final kept = s.page.strokes.length - before;
        note(
          'scribble [$setting] $name: word '
          '${erased ? 'ERASED' : 'kept'}, scribble '
          '${kept > 0 ? 'left as ink' : 'gone'}',
        );
        y += 48;
      }
    }
    await s.shot('scribble_each_pen');
  });

  testWidgets('pen gestures: scribble over shapes, highlighter, paper', (
    tester,
  ) async {
    defaults();
    final s = await _Session.open(tester, 'gesture_scribble_kinds');
    final pen = Pen.currentPen;
    for (final all in [true, false]) {
      stows.scribbleErasesAll.value = all;
      final y = all ? 60.0 : 300.0;
      // a shape, a highlight and a word side by side
      s.tool = ShapePen.currentShapePen;
      await s.draw(
        _shaky(_polygon(Offset(70, y + 40), 40, 4, start: -pi / 4), 3),
        speed: 700,
        hold: true,
      );
      final shape = s.page.strokes.last;
      s.tool = Highlighter.currentHighlighter
        ..options.size = 28
        ..color = Colors.yellow.withAlpha(100);
      await s.draw(
        _wobbly(Offset(140, y + 40), Offset(250, y + 42), 2),
        speed: 900,
      );
      final mark = s.page.strokes.last;
      final written = await word(s, pen, Offset(270, y + 50));
      s.tool = pen;
      // each rubbed out on its own, then all three in one big scribble
      await s.draw(scribble(Rect.fromLTWH(35, y + 5, 75, 75)), speed: 1600);
      await s.draw(scribble(Rect.fromLTWH(140, y + 30, 110, 22)), speed: 1600);
      note(
        'scribble on each [Erase Shapes and Highlighter '
        '${all ? 'on' : 'off'}]: shape '
        '${s.page.strokes.contains(shape) ? 'kept' : 'ERASED'}, highlighter '
        '${s.page.strokes.contains(mark) ? 'kept' : 'ERASED'}',
      );
      await s.draw(scribble(Rect.fromLTWH(25, y + 10, 360, 60)), speed: 1600);
      note(
        'one big scribble over all three [Erase Shapes and Highlighter '
        '${all ? 'on' : 'off'}]: shape '
        '${s.page.strokes.contains(shape) ? 'kept' : 'ERASED'}, highlighter '
        '${s.page.strokes.contains(mark) ? 'kept' : 'ERASED'}, word '
        '${s.page.strokes.contains(written) ? 'kept' : 'ERASED'}',
      );
    }
    await s.shot('scribble_kinds');

    // on empty paper: a scribble stays a scribble
    stows.scribbleErasesAll.value = true;
    final before = s.page.strokes.length;
    s.tool = pen;
    await s.draw(scribble(const Rect.fromLTWH(40, 470, 120, 40)), speed: 1600);
    note(
      'scribble on empty paper: '
      '${s.page.strokes.length > before ? 'kept as ink' : 'GONE'}',
    );

    // undo brings what was erased back, in its place
    final page = s.page;
    final word2 = await word(s, pen, const Offset(220, 500));
    final order = List.of(page.strokes);
    await s.draw(scribble(const Rect.fromLTWH(215, 478, 140, 26)), speed: 1600);
    final erased = !page.strokes.contains(word2);
    s.editor.undo();
    await tester.pump();
    note(
      'scribble erase then undo: word ${erased ? 'erased' : 'NOT erased'}, '
      'after undo ${page.strokes.contains(word2) ? 'back' : 'MISSING'}'
      '${_sameOrder(order, page.strokes) ? ', same order' : ', ORDER CHANGED'}',
    );
    await s.shot('scribble_kinds_after');
  });

  testWidgets('pen gestures: scribble that is really writing or shading', (
    tester,
  ) async {
    defaults();
    final s = await _Session.open(tester, 'gesture_scribble_writing');
    final pen = Pen.currentPen;

    // "www" or "mmm" written just below a word, touching it
    final written = await word(s, pen, const Offset(40, 80));
    s.tool = pen;
    await s.draw([
      for (int i = 0; i <= 6; i++) Offset(45 + i * 12.0, i.isEven ? 72 : 96),
    ], speed: 600);
    note(
      'writing "www" across a word: word '
      '${s.page.strokes.contains(written) ? 'kept' : 'ERASED'}',
    );

    // a zigzag drawn on purpose under a title, crossing its descenders
    final title = await word(s, pen, const Offset(40, 170), seed: 4);
    s.tool = pen;
    await s.draw([
      for (int i = 0; i <= 10; i++) Offset(40 + i * 12.0, i.isEven ? 168 : 178),
    ], speed: 800);
    note(
      'zigzag underline touching a word: word '
      '${s.page.strokes.contains(title) ? 'kept' : 'ERASED'}',
    );

    // shading inside a box drawn with the shape pen, up to its sides
    s.tool = ShapePen.currentShapePen;
    await s.draw(
      _shaky(_polygon(const Offset(110, 330), 70, 4, start: -pi / 4), 5),
      speed: 700,
      hold: true,
    );
    final box = s.page.strokes.last;
    s.tool = Pen.currentBallpointPen;
    stows.penScribbleToErase.value = true;
    await s.draw([
      for (int i = 0; i <= 12; i++) Offset(62 + (i % 2) * 96.0, 282 + i * 8.0),
    ], speed: 1400);
    note(
      'shading a shape-pen box to its sides (ballpoint, scribble on): box '
      '${s.page.strokes.contains(box) ? 'kept' : 'ERASED'}',
    );
    // words written inside a box drawn with the shape pen
    s.tool = ShapePen.currentShapePen;
    await s.draw(
      _shaky(const [
        Offset(40, 430),
        Offset(380, 430),
        Offset(380, 540),
        Offset(40, 540),
        Offset(40, 430),
      ], 6),
      speed: 700,
      hold: true,
    );
    final frame = s.page.strokes.last;
    await word(s, pen, const Offset(60, 480), seed: 21);
    await word(s, pen, const Offset(200, 480), seed: 22);
    s.tool = pen;
    await s.draw([
      for (int i = 0; i <= 8; i++) Offset(70 + i * 14.0, i.isEven ? 500 : 520),
    ], speed: 700);
    note(
      'writing words and a "wwww" inside a shape-pen box: box '
      '${s.page.strokes.contains(frame) ? 'kept' : 'ERASED'}',
    );

    // crossing out a wrong word with a few quick lines, not a full scribble
    final wrong = await word(s, pen, const Offset(230, 330), seed: 7);
    s.tool = pen;
    await s.draw([
      const Offset(225, 318),
      const Offset(360, 312),
      const Offset(228, 326),
      const Offset(358, 322),
    ], speed: 1300);
    note(
      'crossing out a word with two quick lines: word '
      '${s.page.strokes.contains(wrong) ? 'kept' : 'ERASED'}',
    );
    await s.shot('scribble_writing');
  });

  testWidgets('pen gestures: circle to lasso', (tester) async {
    defaults();
    final s = await _Session.open(tester, 'gesture_lasso');
    final pen = Pen.currentPen;
    String state() {
      final select = Select.currentSelect;
      final selecting = s.editor.currentTool is Select && select.doneSelecting;
      return selecting
          ? 'SELECTED ${select.selectResult.strokes.length} stroke(s)'
          : 'left as ink';
    }

    Future<void> reset() async {
      s.tool = pen;
      await tester.pump();
    }

    for (final on in [false, true]) {
      stows.circleToLasso.value = on;
      final y = on ? 330.0 : 70.0;
      await word(s, pen, Offset(60, y));
      await word(s, pen, Offset(200, y), seed: 5);
      // a loop round the first word, closed
      final count = s.page.strokes.length;
      s.tool = pen;
      await s.draw(_loop(Rect.fromLTWH(45, y - 40, 150, 60)), speed: 900);
      note(
        'loop round a word [Circle to Lasso ${on ? 'on' : 'off'}]: '
        '${state()}, strokes ${count}->${s.page.strokes.length}',
      );
      await s.shot('lasso_${on ? 'on' : 'off'}');
      await reset();
    }

    stows.circleToLasso.value = true;
    // round nothing
    var count = s.page.strokes.length;
    s.tool = pen;
    await s.draw(_loop(const Rect.fromLTWH(60, 160, 120, 70)), speed: 900);
    note(
      'loop round empty paper: ${state()}, strokes $count->${s.page.strokes.length}',
    );
    await reset();

    // round half a word
    count = s.page.strokes.length;
    s.tool = pen;
    await s.draw(_loop(const Rect.fromLTWH(180, 290, 70, 60)), speed: 900);
    note(
      'loop round half of a word: ${state()}, strokes $count->${s.page.strokes.length}',
    );
    await reset();

    // left a little open, as hands do
    count = s.page.strokes.length;
    s.tool = pen;
    final open = _loop(const Rect.fromLTWH(185, 290, 150, 60));
    await s.draw(open.sublist(0, (open.length * 0.85).round()), speed: 900);
    note(
      'loop round a word, 15% open: ${state()}, strokes $count->${s.page.strokes.length}',
    );
    await reset();

    // the letter O written round a dot
    s.tool = pen;
    await s.draw([const Offset(300, 450), const Offset(301, 451)], speed: 200);
    count = s.page.strokes.length;
    await s.draw(_loop(const Rect.fromLTWH(285, 430, 32, 42)), speed: 700);
    note(
      'writing a big "O" round a dot: ${state()}, strokes $count->${s.page.strokes.length}',
    );
    await reset();

    // round most of a word, its last letters sticking out
    await word(s, pen, const Offset(60, 520), seed: 11);
    count = s.page.strokes.length;
    s.tool = pen;
    await s.draw(_loop(const Rect.fromLTWH(45, 480, 120, 60)), speed: 900);
    note(
      'loop round most of a word (end sticking out): ${state()}, strokes '
      '$count->${s.page.strokes.length}',
    );
    await reset();

    // a loop meant as ink, kept with the button that comes up
    await word(s, pen, const Offset(230, 520), seed: 12);
    count = s.page.strokes.length;
    s.tool = pen;
    await s.draw(_loop(const Rect.fromLTWH(215, 480, 150, 60)), speed: 900);
    final selected = state();
    final button = find.text('Keep as ink');
    if (button.evaluate().isEmpty) {
      note('"Keep as ink" after a loop selects ($selected): NO BUTTON');
    } else {
      // once it has slid in
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(button);
      await tester.pump();
      note(
        '"Keep as ink" after a loop selects ($selected): tapped, now '
        '${state()}, strokes $count->${s.page.strokes.length}',
      );
    }
    await tester.pump(const Duration(seconds: 4));
    await reset();

    // with the highlighter
    count = s.page.strokes.length;
    s.tool = Highlighter.currentHighlighter..options.size = 20;
    await s.draw(_loop(const Rect.fromLTWH(185, 290, 150, 60)), speed: 900);
    note(
      'highlighter loop round a word: ${state()}, strokes $count->${s.page.strokes.length}',
    );
    await s.shot('lasso_cases');
    // the banners go
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('pen gestures: draw and hold', (tester) async {
    defaults();
    final s = await _Session.open(tester, 'gesture_hold');
    final pen = Pen.currentBallpointPen;
    String last() {
      final stroke = s.page.strokes.last;
      // a highlighter snaps to a line along its own evenly spaced points
      final points = stroke.centerPoints;
      final straight =
          stroke.toolId == .highlighter &&
          points.length > 2 &&
          points.every(
            (p) =>
                Stroke.sqrDistanceToSegment(p, points.first, points.last) <
                0.01,
          );
      return stroke.toolId == .shapePen ||
              stroke.shapeStyle != null ||
              stroke is CircleStroke ||
              straight
          ? 'SNAPPED to a shape'
          : 'left as ink';
    }

    for (final on in [false, true]) {
      stows.penDrawAndHold.value = on;
      final y = on ? 190.0 : 60.0;
      s.tool = pen;
      await s.draw(
        _shaky(_polygon(Offset(80, y + 40), 45, 4, start: -pi / 4), 2),
        speed: 700,
        hold: true,
      );
      note(
        'rectangle drawn and held [Draw and Hold ${on ? 'on' : 'off'}]: ${last()}',
      );
      s.tool = pen;
      await s.draw(_polygon(Offset(220, y + 40), 45, 3), speed: 700);
      note('triangle drawn, lifted at once [${on ? 'on' : 'off'}]: ${last()}');
    }

    stows.penDrawAndHold.value = true;
    stows.shapeFill.value = true;
    s.tool = pen;
    await s.draw(
      _loop(const Rect.fromLTWH(290, 200, 80, 80)),
      speed: 700,
      hold: true,
    );
    final filled = s.page.strokes.last.shapeStyle?.fill != null;
    note(
      'circle held, Fill Color on: ${last()}, ${filled ? 'filled' : 'NOT filled'}',
    );
    stows.shapeFill.value = false;

    // a word, the pen resting at its end while thinking
    await s.draw(
      _cursive(const Offset(40, 360), width: 130, seed: 9),
      speed: 700,
      hold: true,
    );
    note('word with the pen resting at its end [on]: ${last()}');

    // a pause in the middle of a word, then writing on
    s.tool = pen;
    final first = _cursive(const Offset(200, 360), width: 60, seed: 2);
    final rest = [
      for (final p in _cursive(const Offset(260, 360), width: 60, seed: 3)) p,
    ];
    await s.draw(first, speed: 700, lift: false);
    await tester.pump(ShapePen.debounceDuration * 1.5);
    final down = s._down!;
    for (final p in _along([first.last, ...rest], 700 / 240)) {
      s._time += const Duration(microseconds: 4167);
      await down.moveTo(s.toScreen(s.toPage(p)), timeStamp: s._time);
    }
    await s.lift();
    note('pause mid-word, then writing on [on]: ${last()}');

    // held with a hand's tremor, not perfectly still
    s.tool = pen;
    final square = _shaky(
      _polygon(const Offset(90, 480), 40, 4, start: -pi / 4),
      8,
    );
    await s.draw(square, speed: 700, lift: false);
    final random = Random(4);
    for (int i = 0; i < 40; i++) {
      s._time += const Duration(milliseconds: 20);
      await s._down!.moveTo(
        s.toScreen(
          s.toPage(square.last) +
              Offset(
                random.nextDouble() * 3 - 1.5,
                random.nextDouble() * 3 - 1.5,
              ),
        ),
        timeStamp: s._time,
      );
      await tester.pump(const Duration(milliseconds: 20));
    }
    await s.lift();
    note('square held with a slight tremor [on]: ${last()}');

    // held until it snaps, then the pen goes on: the shape grows and turns
    s.tool = pen;
    final small = _shaky(
      _polygon(const Offset(300, 380), 30, 4, start: -pi / 4),
      9,
    );
    await s.draw(small, speed: 700, lift: false, hold: true);
    final snapped = s.page.strokes.length;
    final heldShape = Pen.currentStroke;
    final sizeAtSnap = heldShape?.bounds.longestSide ?? 0;
    for (final p in _along([
      small.last,
      small.last + const Offset(25, 25),
    ], 2)) {
      s._time += const Duration(microseconds: 4167);
      await s._down!.moveTo(s.toScreen(s.toPage(p)), timeStamp: s._time);
      await tester.pump(const Duration(milliseconds: 8));
    }
    await s.lift();
    final grown = s.page.strokes.last.bounds.longestSide;
    note(
      'held to snap, then pen moved on [on]: ${last()}, size '
      '${sizeAtSnap.toStringAsFixed(0)} -> ${grown.toStringAsFixed(0)}'
      '${grown > sizeAtSnap * 1.15 ? ' (GREW with the pen)' : ' (did not follow the pen)'}'
      '${s.page.strokes.length == snapped + 1 ? '' : ''}',
    );

    // a straight line held, with the highlighter
    s.tool = Highlighter.currentHighlighter..options.size = 20;
    await s.draw(
      _wobbly(const Offset(200, 470), const Offset(360, 478), 6),
      speed: 700,
      hold: true,
    );
    note('highlighter line held [on]: ${last()}');
    await s.shot('hold');
    // the banners go
    await tester.pump(const Duration(seconds: 6));
  });

  testWidgets('pen gestures: draw and hold with the other gestures', (
    tester,
  ) async {
    defaults();
    stows.penDrawAndHold.value = true;
    stows.circleToLasso.value = true;
    stows.penScribbleToErase.value = true;
    final s = await _Session.open(tester, 'gesture_overlap');
    final pen = Pen.currentBallpointPen;

    // scribbling out a word and pausing before lifting
    final written = await word(s, pen, const Offset(40, 80));
    s.tool = pen;
    await s.draw(
      scribble(const Rect.fromLTWH(35, 58, 140, 26)),
      speed: 1500,
      hold: true,
    );
    final lastStroke = s.page.strokes.lastOrNull;
    note(
      'scribble over a word, pen held at the end [hold+scribble on]: word '
      '${s.page.strokes.contains(written) ? 'KEPT' : 'erased'}, scribble '
      '${lastStroke == null || identical(lastStroke, written)
          ? 'gone'
          : lastStroke.toolId == .shapePen || lastStroke.shapeStyle != null
          ? 'SNAPPED to a shape'
          : 'left as ink'}',
    );

    // circling a word and pausing before lifting
    await word(s, pen, const Offset(60, 200));
    s.tool = pen;
    final count = s.page.strokes.length;
    await s.draw(
      _loop(const Rect.fromLTWH(45, 160, 150, 60)),
      speed: 900,
      hold: true,
    );
    final selecting =
        s.editor.currentTool is Select && Select.currentSelect.doneSelecting;
    note(
      'loop round a word, pen held at the end [hold+lasso on]: '
      '${selecting ? 'selected' : 'not selected'}, strokes $count->${s.page.strokes.length}, '
      'last ${s.page.strokes.last.toolId.name}',
    );
    s.tool = pen;
    await tester.pump();

    // a quick loop round a word, lifted at once
    await word(s, pen, const Offset(60, 330), seed: 3);
    await s.draw(_loop(const Rect.fromLTWH(45, 290, 150, 60)), speed: 900);
    final selected2 =
        s.editor.currentTool is Select && Select.currentSelect.doneSelecting;
    note(
      'quick loop round a word, lifted at once [hold+lasso on]: ${selected2 ? 'selected' : 'NOT selected'}',
    );
    await s.shot('overlap');
    // the banners go
    await tester.pump(const Duration(seconds: 6));
    note('strokes on the page: ${kinds(s.page)}');
  });
}

bool _sameOrder(List<Stroke> a, List<Stroke> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (!identical(a[i], b[i])) return false;
  }
  return true;
}

/// A plain picture of [color], as a PNG.
Future<Uint8List> _plainPng(Color color) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawColor(color, BlendMode.src);
  final image = await recorder.endRecording().toImage(40, 40);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  return png!.buffer.asUint8List();
}

/// One editor, with the pen held like a stylus.
class _Session {
  _Session(this.tester, this.editor, this.name);

  final WidgetTester tester;
  final EditorState editor;
  final String name;
  var _time = Duration.zero;
  TestGesture? _down;

  static Future<_Session> open(
    WidgetTester tester,
    String name, {
    Size size = const Size(1080, 2400),
  }) async {
    setupMockPathProvider();
    setupMockPrinting();
    setupMockWindowManager();
    // No audio recorder or player on the test machine, and each player has
    // its own channel: those answer with nothing.
    TestDefaultBinaryMessengerBinding
        .instance
        .defaultBinaryMessenger
        .allMessagesHandler = (channel, handler, message) {
      if (handler != null) return handler(message);
      final audio =
          channel.startsWith('xyz.luan/audioplayers') ||
          channel.startsWith('com.llfbandit.record');
      return audio
          ? Future.value(
              const StandardMethodCodec().encodeSuccessEnvelope(null),
            )
          : null;
    };
    addTearDown(
      () =>
          TestDefaultBinaryMessengerBinding
                  .instance
                  .defaultBinaryMessenger
                  .allMessagesHandler =
              null,
    );
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    stows.editorFingerDrawing.value = false;
    await tester.runAsync(FileManager.init);
    await tester.pumpWidget(
      RepaintBoundary(
        key: _shotKey,
        child: MaterialApp(home: Editor(path: '/scenario-$name')),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    final editor = tester.state<EditorState>(find.byType(Editor));
    addTearDown(editor.cancelAutosaveAndMarkSaved);
    return _Session(tester, editor, name);
  }

  EditorPage get page => editor.coreInfo.pages.first;

  set tool(Tool tool) {
    editor.currentTool = tool;
  }

  /// The scenarios are laid out on a page 400 wide and 560 tall: [p] there
  /// on the real page.
  Offset toPage(Offset p) => p * (page.size.width / 400);

  /// Screen position of [p] on the first page.
  Offset toScreen(Offset p) {
    final rect = tester.getRect(find.byType(InnerCanvas).first);
    return rect.topLeft + p * (rect.width / page.size.width);
  }

  /// Draws through [points] (on the page) at [speed] page units a second,
  /// sampled 240 times a second like a phone's stylus, with a frame every
  /// 4 samples. With [hold], the pen stays still at the end before lifting.
  Future<void> draw(
    List<Offset> points, {
    double speed = 1100,
    bool hold = false,
    bool lift = true,
    bool onPage = false,
  }) async {
    final scale = onPage ? 1.0 : page.size.width / 400;
    final line = [for (final p in _along(points, speed / 240)) p * scale];
    final gesture = await tester.createGesture(kind: PointerDeviceKind.stylus);
    _down = gesture;
    await gesture.down(toScreen(line.first), timeStamp: _time);
    for (final (i, p) in line.skip(1).indexed) {
      _time += const Duration(microseconds: 4167);
      await gesture.moveTo(toScreen(p), timeStamp: _time);
      if (i % 4 == 3) {
        final frame = Stopwatch()..start();
        await tester.pump(const Duration(milliseconds: 16));
        frameMicros.add(frame.elapsedMicroseconds);
      }
    }
    if (hold) {
      await tester.pump(ShapePen.debounceDuration * 1.5);
    }
    if (lift) {
      final watch = Stopwatch()..start();
      await this.lift();
      liftMicros.add(watch.elapsedMicroseconds);
    }
  }

  /// How long each frame while drawing, and each lift, took to make.
  final frameMicros = <int>[];
  final liftMicros = <int>[];

  Future<void> lift() async {
    await _down?.up(timeStamp: _time);
    _down = null;
    await tester.pump(const Duration(milliseconds: 16));
  }

  Future<void> shot(String what) async {
    await tester.pump();
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_shotKey),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.5);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('${_out.path}/${name}_$what.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  Future<void> timed(String what, Future<void> Function() run) async {
    frameMicros.clear();
    liftMicros.clear();
    final watch = Stopwatch()..start();
    await run();
    String ms(List<int> micros) => micros.isEmpty
        ? '-'
        : '${(micros.reduce((a, b) => a + b) / micros.length / 1000).toStringAsFixed(1)}'
              '/${(micros.reduce(max) / 1000).toStringAsFixed(1)}';
    _timings.add(
      '$what: ${watch.elapsedMilliseconds} ms '
      '(frame avg/max ${ms(frameMicros)} ms, lift avg/max ${ms(liftMicros)} ms)',
    );
  }
}

/// Points [step] apart along [points], with a little hand tremor.
List<Offset> _along(List<Offset> points, double step) {
  final random = Random(points.length);
  final out = <Offset>[points.first];
  for (int i = 1; i < points.length; i++) {
    final a = points[i - 1], b = points[i];
    final n = max(1, ((b - a).distance / step).ceil());
    for (int k = 1; k <= n; k++) {
      final jitter = Offset(
        (random.nextDouble() - 0.5) * 0.8,
        (random.nextDouble() - 0.5) * 0.8,
      );
      out.add(Offset.lerp(a, b, k / n)! + jitter);
    }
  }
  return out;
}

/// Joined-up handwriting: loops going along, as a word.
List<Offset> _cursive(Offset from, {required double width, int seed = 0}) {
  final random = Random(seed);
  final loops = max(2, (width / 14).round());
  final out = <Offset>[];
  for (int i = 0; i <= loops * 16; i++) {
    final t = i / 16;
    final size = 7 + 3 * sin(seed + t * 1.3);
    out.add(
      from +
          Offset(
            t * width / loops - size * 0.6 * sin(t * 2 * pi),
            -size * (1 - cos(t * 2 * pi)) * (0.6 + 0.4 * random.nextDouble()),
          ),
    );
  }
  return out;
}

/// Back and forth across [box], as when filling it with one stroke.
List<Offset> _zigzag(Rect box, {required int rows}) => [
  for (int i = 0; i < rows; i++) ...[
    Offset(i.isEven ? box.left : box.right, box.top + i * box.height / rows),
    Offset(
      i.isEven ? box.right : box.left,
      box.top + (i + 0.5) * box.height / rows,
    ),
  ],
];

List<Offset> _wobbly(Offset a, Offset b, int seed) {
  final random = Random(seed);
  return [
    for (int i = 0; i <= 10; i++)
      Offset.lerp(a, b, i / 10)! + Offset(0, (random.nextDouble() - 0.5) * 5),
  ];
}

/// The usual heart curve round [center], [scale] page units a step.
List<Offset> _heart(Offset center, double scale) => [
  for (int i = 0; i <= 32; i++)
    () {
      final t = i / 32 * 2 * pi;
      return center +
          Offset(
                16 * pow(sin(t), 3).toDouble(),
                -(13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t)),
              ) *
              scale;
    }(),
];

List<Offset> _spiral(Offset center, double radius) => [
  for (int i = 0; i <= 80; i++)
    center + Offset.fromDirection(i / 80 * 3.5 * pi, radius * (0.3 + i / 110)),
];

List<Offset> _loop(Rect box) => [
  for (int i = 0; i <= 40; i++)
    box.center +
        Offset(
          cos(i / 40 * 2 * pi) * box.width / 2,
          sin(i / 40 * 2 * pi) * box.height / 2,
        ),
];

List<Offset> _polygon(
  Offset center,
  double radius,
  int corners, {
  double start = -pi / 2,
  int skip = 1,
}) => [
  for (int i = 0; i <= corners; i++)
    center + Offset.fromDirection(start + i * skip * 2 * pi / corners, radius),
];

List<Offset> _arrow(Offset from, Offset to) => [
  from,
  to,
  to + const Offset(-30, -18),
  to,
  to + const Offset(-30, 18),
];

/// [corners] traced the way a quick hand does: sides a little bowed, corners
/// a little rounded.
List<Offset> _shaky(List<Offset> corners, int seed) {
  final random = Random(seed);
  final out = <Offset>[];
  for (int i = 1; i < corners.length; i++) {
    final a = corners[i - 1], b = corners[i];
    final normal = Offset(-(b - a).dy, (b - a).dx) / max((b - a).distance, 1);
    final bow = (random.nextDouble() - 0.5) * 0.08 * (b - a).distance;
    for (int k = 0; k < 8; k++) {
      final t = k / 8;
      out.add(Offset.lerp(a, b, t)! + normal * bow * sin(t * pi));
    }
  }
  return out..add(corners.last);
}

/// Every stroke's points, width and holes, to compare before and after.
List<String> _snapshot(EditorPage page) => [
  for (final stroke in page.strokes)
    '${stroke.toolId} ${stroke.options.size.toStringAsFixed(2)} '
        '${stroke.holes.length} '
        '${[for (final p in stroke.centerPoints) '${p.dx.toStringAsFixed(1)},${p.dy.toStringAsFixed(1)}'].join(' ')}',
];
