@Tags(['design'])
library;

import 'dart:io';
import 'dart:math';

import 'package:badnotes/components/canvas/image/editor_image.dart';
import 'package:badnotes/components/canvas/inner_canvas.dart';
import 'package:badnotes/components/editor/sticky_note_dialog.dart';
import 'package:badnotes/components/editor/text_box_overlay.dart';
import 'package:badnotes/components/editor_ui/color_panel.dart';
import 'package:badnotes/components/editor_ui/text_format_bar.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/data/editor/page.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/data/flavor_config.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/tools/_tool.dart';
import 'package:badnotes/data/tools/highlighter.dart';
import 'package:badnotes/data/tools/laser_pointer.dart';
import 'package:badnotes/data/tools/pen.dart';
import 'package:badnotes/data/tools/pencil.dart';
import 'package:badnotes/data/tools/select.dart';
import 'package:badnotes/data/tools/shape_pen.dart';
import 'package:badnotes/data/tools/tape.dart';
import 'package:badnotes/data/tools/tape_pattern.dart';
import 'package:badnotes/pages/editor/editor.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfrx/pdfrx.dart' show Pdfrx;

import '../utils/test_mock_channel_handlers.dart';
import 'design_shot.dart';

/// Every writing tool in every colour, on a white page and a black one, in
/// the theme of the run (`DESIGN_DARK`): pens, pencil, highlighter, shapes
/// with and without fill, text in each font and colour, the laser, the lasso,
/// tape, and a PDF written on. Pictures only, to look at: `ink_*.png`.
void main() {
  late Directory docs;

  setUp(() async {
    FlavorConfig.setup();
    setupMockPathProvider();
    setupMockPrinting();
    setupMockWindowManager();
    stows.editorFingerDrawing.value = false;
    stows.editorAutoInvert.value = true;
    docs = Directory.systemTemp.createTempSync('badnotes-ink-check');
    await FileManager.init(
      documentsDirectory: docs.path,
      shouldWatchRootDirectory: false,
    );
    // no audio recorder or player on the test machine
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
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding
            .instance
            .defaultBinaryMessenger
            .allMessagesHandler =
        null;
    stows.editorAutoInvert.value = true;
    docs.deleteSync(recursive: true);
  });

  const long = Timeout(Duration(minutes: 5));

  testWidgets('pens in every colour', timeout: long, (tester) async {
    await _check(tester, 'pens', (s) async {
      final pens = [
        Pen.currentBallpointPen,
        Pen.currentPen,
        Pen.currentBrushPen,
        Pen.currentCalligraphyPen,
      ];
      for (final (row, pen) in pens.indexed) {
        await s.colourRow(pen, 16 + row * 62.0);
      }
      // the default colour, written as words
      for (final (row, pen) in pens.indexed) {
        pen.color = Colors.black; // shown white on a dark page
        s.tool = pen;
        await s.draw(_cursive(Offset(20, 280 + row * 34.0), 340, row));
      }
    });
  });

  testWidgets('pencil and highlighter in every colour', timeout: long, (
    tester,
  ) async {
    await _check(tester, 'pencil_highlighter', (s) async {
      await s.colourRow(Pencil.currentPencil, 16);
      // words, then every highlighter colour over them
      s.tool = Pen.currentBallpointPen..color = Colors.black;
      for (int row = 0; row < 4; row++) {
        await s.draw(_cursive(Offset(20, 100 + row * 34.0), 340, row + 7));
      }
      final highlighter = Highlighter.currentHighlighter..options.size = 18;
      s.tool = highlighter;
      for (final (i, colour) in ColorPanel.defaultPresets.indexed) {
        highlighter.color = colour.withAlpha(stows.highlighterAlpha.value);
        final row = i ~/ 8, column = i % 8;
        final x = 20 + column * 43.0, y = 106 + row * 34.0;
        await s.draw([Offset(x, y), Offset(x + 38, y + 1)]);
      }
      // a highlighter row on its own, and words written over it
      for (final (i, colour) in ColorPanel.defaultPresets.indexed) {
        highlighter.color = colour.withAlpha(stows.highlighterAlpha.value);
        final x = 12 + i * 13.0;
        await s.draw([Offset(x, 270), Offset(x + 3, 330)]);
      }
      s.tool = Pen.currentBallpointPen..color = Colors.black;
      await s.draw(_cursive(const Offset(20, 300), 340, 21));
      highlighter.options.size = 30;
    });
  });

  testWidgets('shapes in colour, with and without fill', timeout: long, (
    tester,
  ) async {
    await _check(tester, 'shapes', (s) async {
      const kinds = [
        ShapeKind.rectangle,
        ShapeKind.ellipse,
        ShapeKind.triangle,
        ShapeKind.pentagon,
        ShapeKind.star,
        ShapeKind.heart,
        ShapeKind.arrow,
        ShapeKind.line,
      ];
      const colours = [
        Color(0xFFF14B4B),
        Color(0xFFFF8A2B),
        Color(0xFFFFC21A),
        Color(0xFF3CC85A),
        Color(0xFF3E8EF7),
        Color(0xFFAB6CF2),
        Color(0xFF000000),
        Color(0xFFFFFFFF),
      ];
      final pen = ShapePen.currentShapePen;
      s.tool = pen;
      for (final (row, fill) in [false, true, true].indexed) {
        stows.shapeFill.value = fill;
        for (final (i, kind) in kinds.indexed) {
          ShapePen.kind = kind;
          // the last row: the colours the other way round
          pen.color = colours[row == 2 ? colours.length - 1 - i : i];
          final x = 12 + (i % 4) * 96.0, y = 20 + (row * 2 + i ~/ 4) * 88.0;
          await s.draw([
            Offset(x, y),
            Offset(x + 40, y + 30),
            Offset(x + 80, y + 70),
          ]);
        }
      }
      stows.shapeFill.value = false;
      ShapePen.kind = .auto;
    });
  });

  testWidgets('text in every font and colour', timeout: long, (tester) async {
    await _check(tester, 'text', (s) async {
      final boxes = <(StickyNoteResult, Offset)>[];
      // the usual ink, then each font in a colour
      final fonts = [...textMainFonts.values, ...textBoxFonts.keys];
      for (final (i, font) in fonts.indexed) {
        boxes.add((
          StickyNoteResult(
            '${textFontName(font)}: the quick brown fox 123',
            null,
            font: font,
            fontSize: 22,
            maxWidth: 900,
            textColor: i == 0
                ? null
                : textColorPresets[i % textColorPresets.length],
            bold: i == 1,
            italic: i == 2,
          ),
          Offset(16, 12 + i * 26.0),
        ));
      }
      // every text colour
      for (final (i, colour) in textColorPresets.indexed) {
        boxes.add((
          StickyNoteResult(
            'Aa',
            null,
            font: 'AtkinsonHyperlegibleNext',
            fontSize: 26,
            maxWidth: 200,
            textColor: colour,
            bold: true,
          ),
          Offset(16 + (i % 8) * 46.0, 400 + (i ~/ 8) * 34.0),
        ));
      }
      await s.addText(boxes);
      // ink over text, and highlighter over it
      s.tool = Pen.currentBallpointPen..color = const Color(0xFF3E8EF7);
      await s.draw([const Offset(16, 485), const Offset(380, 482)]);
    });
  });

  testWidgets('laser in every colour, line and dot', timeout: long, (
    tester,
  ) async {
    await _check(
      tester,
      'laser',
      (s) async {
        stows.laserHoldMillis.value = 60000;
        final laser = LaserPointer.currentLaserPointer..dotMode = false;
        s.tool = laser;
        const colours = [
          Colors.red,
          Colors.orange,
          Colors.yellow,
          Colors.green,
          Colors.blue,
          Colors.purple,
        ];
        for (final (i, colour) in colours.indexed) {
          laser.color = colour;
          await s.draw(_cursive(Offset(20, 30 + i * 50.0), 340, i + 3));
        }
        // the dot, held down
        laser
          ..dotMode = true
          ..color = Colors.red;
        await s.draw([
          const Offset(200, 380),
          const Offset(240, 400),
        ], lift: false);
      },
      after: (s) async {
        await s.lift();
        LaserPointer.currentLaserPointer.dotMode = false;
        // the lines' fade, timed when they were drawn, then the fade itself
        await s.tester.pump(const Duration(seconds: 61));
        await s.tester.pump(const Duration(seconds: 1));
        stows.laserHoldMillis.value = 300;
      },
    );
  });

  testWidgets('lasso and tape over ink and text', timeout: long, (
    tester,
  ) async {
    await _check(tester, 'lasso_tape', (s) async {
      // answers, covered by tape
      s.tool = Pen.currentBallpointPen..color = Colors.black;
      for (int row = 0; row < 3; row++) {
        await s.draw(_cursive(Offset(20, 40 + row * 34.0), 340, row));
      }
      s.tool = Highlighter.currentHighlighter
        ..options.size = 18
        ..color = Colors.yellow.withAlpha(stows.highlighterAlpha.value);
      await s.draw([const Offset(20, 76), const Offset(250, 77)]);
      await s.addText([
        (
          const StickyNoteResult(
            'Answer: F = m · a',
            null,
            font: 'AtkinsonHyperlegibleNext',
            fontSize: 24,
            maxWidth: 900,
          ),
          const Offset(20, 130),
        ),
      ]);
      final tape = Tape.currentTape;
      s.tool = tape;
      for (final (i, pattern) in TapePattern.values.take(3).indexed) {
        Tape.pattern = pattern;
        tape.color = Tape.colors[i * 4];
        await s.draw([Offset(14, 40 + i * 50.0), Offset(380, 42 + i * 50.0)]);
      }
      // written on the tape: hidden when it is peeked under
      s.tool = Pen.currentBallpointPen..color = const Color(0xFF2A55B8);
      // a tick and an underline: tight loops over ink read as a scribble,
      // which rubs out what it goes over
      await s.draw([
        const Offset(40, 38),
        const Offset(48, 46),
        const Offset(66, 30),
      ]);
      await s.draw([const Offset(80, 46), const Offset(180, 45)]);
      await s.addText([
        (
          const StickyNoteResult(
            'on the tape',
            null,
            font: 'Caveat',
            fontSize: 24,
            maxWidth: 400,
            textColor: Color(0xFFB3261E),
          ),
          const Offset(220, 85),
        ),
      ]);
      await s.save('covered');

      // a tap with the tape peeks under the first one
      s.tool = tape;
      await s.draw([const Offset(300, 41), const Offset(300.5, 41)]);
      await s.save('peeked');
      await s.draw([const Offset(300, 41), const Offset(300.5, 41)]);

      // the lasso around the lower part
      s.tool = Pen.currentPen..color = const Color(0xFF1E7D32);
      for (int row = 0; row < 3; row++) {
        await s.draw(_cursive(Offset(30, 260 + row * 34.0), 300, row + 4));
      }
      s.tool = Select.currentSelect;
      await s.draw([
        for (int i = 0; i <= 40; i++)
          const Offset(190, 300) +
              Offset(cos(i / 40 * 2 * pi) * 180, sin(i / 40 * 2 * pi) * 70),
      ]);
    });
  });

  testWidgets('a PDF written on, inverted and not', timeout: long, (
    tester,
  ) async {
    // the PDF library, downloaded by design-shots.yml
    Pdfrx.pdfiumModulePath ??= Platform.environment['PDFIUM_PATH'];
    final file = File('${docs.path}/sample.pdf');
    final document = pw.Document()
      ..addPage(
        pw.Page(
          pageFormat: pdf.PdfPageFormat.a4,
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Chapter 5: Laws of Motion',
                style: pw.TextStyle(
                  fontSize: 26,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              for (int i = 0; i < 8; i++)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Text(
                    'A body stays at rest or keeps moving in a straight line '
                    'unless a force acts on it. Line ${i + 1}.',
                    style: const pw.TextStyle(fontSize: 13),
                  ),
                ),
              pw.SizedBox(height: 12),
              pw.Row(
                children: [
                  for (final colour in [
                    pdf.PdfColors.red,
                    pdf.PdfColors.green,
                    pdf.PdfColors.blue,
                    pdf.PdfColors.black,
                    pdf.PdfColors.yellow,
                  ])
                    pw.Container(
                      width: 60,
                      height: 40,
                      margin: const pw.EdgeInsets.only(right: 12),
                      color: colour,
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    await tester.runAsync(() async => file.writeAsBytes(await document.save()));

    await _check(
      tester,
      'pdf',
      (s) async {
        await tester.runAsync(() => s.editor.importPdfFromFilePath(file.path));
        for (int i = 0; i < 12; i++) await s.settle();
        // written on: words, a highlighter over the PDF's text, a shape, text
        s.tool = Highlighter.currentHighlighter
          ..options.size = 16
          ..color = Colors.yellow.withAlpha(stows.highlighterAlpha.value);
        await s.draw([const Offset(28, 54), const Offset(330, 55)]);
        s.tool = Pen.currentBallpointPen..color = const Color(0xFFF14B4B);
        await s.draw(_cursive(const Offset(40, 200), 300, 2));
        s.tool = Pen.currentPen..color = Colors.black;
        await s.draw(_cursive(const Offset(40, 232), 300, 3));
        s.tool = ShapePen.currentShapePen..color = const Color(0xFF3E8EF7);
        ShapePen.kind = .ellipse;
        await s.draw([const Offset(20, 25), const Offset(200, 45)]);
        ShapePen.kind = .auto;
        await s.addText([
          (
            const StickyNoteResult(
              'Remember this!',
              null,
              font: 'Caveat',
              fontSize: 28,
              maxWidth: 600,
              textColor: Color(0xFF6B3BB0),
            ),
            const Offset(220, 260),
          ),
        ]);
      },
      after: (s) async {
        // the PDF's own dark mode (the moon in its bar)
        final background = s.page.backgroundImage;
        if (background is PdfEditorImage) {
          background.darkMode = true;
          s.page.redrawStrokes();
          s.editor.setState(() {});
          for (int i = 0; i < 6; i++) await s.settle();
          await s.save('pdf_dark');
          background.darkMode = false;
        }
      },
    );
  });
}

/// Opens a new note, runs [write] on its first page, then saves a picture
/// of it on each paper: `ink_<name>_<paper>.png`.
Future<void> _check(
  WidgetTester tester,
  String name,
  Future<void> Function(_Ink s) write, {
  Future<void> Function(_Ink s)? after,
}) async {
  late _Ink s;
  await designShot(
    tester,
    'ink_${name}_end',
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: BadNotesTheme.create(designBrightness),
      home: Editor(path: '/Ink check $name'),
    ),
    size: tabletPortrait,
    setUp: (tester) async {
      for (int i = 0; i < 4; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      s = _Ink(tester, tester.state<EditorState>(find.byType(Editor)), name);
      await write(s);
      await s.settle();
      await s.papers();
      if (after != null) await after(s);
    },
  );
  s.editor.cancelAutosaveAndMarkSaved();
  // pictures are let go of from memory 5 s after they're gone, and laser
  // lines fade a minute after they were drawn
  s.editor.setState(() {
    for (final page in s.editor.coreInfo.pages) {
      page.images.clear();
    }
  });
  await tester.pump();
  await tester.pump(const Duration(seconds: 62));
  await tester.pump(const Duration(seconds: 6));
  // the editor closed, and what it lets go of later (a PDF's document)
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(minutes: 2));
}

class _Ink {
  _Ink(this.tester, this.editor, this.name);

  final WidgetTester tester;
  final EditorState editor;
  final String name;
  var _time = Duration.zero;
  TestGesture? _down;

  bool get dark => designDark;
  EditorPage get page => editor.coreInfo.pages.first;

  set tool(Tool tool) => editor.currentTool = tool;

  /// The checks are laid out on a page 400 wide: [p] there on the page.
  Offset toPage(Offset p) => p * (page.size.width / 400);

  Offset toScreen(Offset p) {
    final rect = tester.getRect(find.byType(InnerCanvas).first);
    return rect.topLeft + p * (rect.width / 400);
  }

  /// A stylus through [points], 240 samples a second, a frame every 4.
  Future<void> draw(List<Offset> points, {bool lift = true}) async {
    final line = _along(points, 4);
    final gesture = await tester.createGesture(kind: PointerDeviceKind.stylus);
    _down = gesture;
    await gesture.down(toScreen(line.first), timeStamp: _time);
    for (final (i, p) in line.skip(1).indexed) {
      _time += const Duration(microseconds: 4167);
      await gesture.moveTo(toScreen(p), timeStamp: _time);
      if (i % 4 == 3) await tester.pump(const Duration(milliseconds: 16));
    }
    if (lift) await this.lift();
  }

  Future<void> lift() async {
    await _down?.up(timeStamp: _time);
    _down = null;
    _time += const Duration(milliseconds: 300);
    await tester.pump(const Duration(milliseconds: 16));
  }

  /// A short squiggle in each of the colour panel's colours, in a row.
  Future<void> colourRow(Tool pen, double y) async {
    tool = pen;
    for (final (i, colour) in ColorPanel.defaultPresets.indexed) {
      (pen as Pen).color = colour;
      final x = 10 + i * 13.0;
      await draw([
        Offset(x, y),
        Offset(x + 4, y + 40),
        Offset(x + 8, y + 2),
        Offset(x + 10, y + 42),
      ]);
    }
  }

  /// Text boxes, as the text tool makes them, at points on the page.
  Future<void> addText(List<(StickyNoteResult, Offset)> boxes) async {
    final images = <EditorImage>[
      for (final (note, at) in boxes)
        SvgEditorImage(
          id: editor.coreInfo.nextImageId++,
          assetCache: editor.coreInfo.assetCache,
          svgString: stickyNoteToSvg(note),
          svgFile: null,
          pageIndex: 0,
          pageSize: page.size,
          naturalSize: stickyNoteSize(note),
          onMoveImage: null,
          onDeleteImage: null,
          onMiscChange: null,
        )..dstRect = toPage(at) & stickyNoteSize(note),
    ];
    editor.setState(
      () => page.putImagesInFront(images, layer: page.activeLayer),
    );
    for (int i = 0; i < 6; i++) await settle();
  }

  Future<void> settle() async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 80)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  Future<void> save(String what) async {
    await settle();
    await saveDesignShot(tester, 'ink_${name}_$what');
  }

  /// Pictures on each paper: in light mode a white and a black page; in
  /// dark mode the page turned dark, a white page picked, and no turning.
  Future<void> papers() async {
    final papers = dark
        ? <String, VoidCallback>{
            'dark_auto': () {},
            'dark_white_page': () => page.backgroundColor = Colors.white,
            'dark_invert_off': () => stows.editorAutoInvert.value = false,
          }
        : <String, VoidCallback>{
            'light_white': () {},
            'light_black_page': () => page.backgroundColor = Colors.black,
          };
    final before = page.backgroundColor;
    for (final MapEntry(key: paper, value: apply) in papers.entries) {
      apply();
      page.redrawStrokes();
      editor.setState(() {});
      for (int i = 0; i < 3; i++) await settle();
      await save(paper);
      page.backgroundColor = before;
      stows.editorAutoInvert.value = true;
    }
    page.redrawStrokes();
    editor.setState(() {});
    await settle();
  }
}

/// Points about [step] apart along [points].
List<Offset> _along(List<Offset> points, double step) {
  final out = <Offset>[points.first];
  for (int i = 1; i < points.length; i++) {
    final a = points[i - 1], b = points[i];
    final n = max(1, ((b - a).distance / step).ceil());
    for (int k = 1; k <= n; k++) {
      out.add(Offset.lerp(a, b, k / n)!);
    }
  }
  return out;
}

/// Joined-up "handwriting" [width] wide, starting at [from].
List<Offset> _cursive(Offset from, double width, int seed) {
  final random = Random(seed);
  final out = <Offset>[];
  for (double x = 0; x <= width; x += 1.5) {
    final loop = x / 9;
    out.add(
      from +
          Offset(
            x + sin(loop * 2 * pi) * 3,
            -cos(loop * 2 * pi) * (6 + random.nextDouble() * 4) + 8,
          ),
    );
  }
  return out;
}
