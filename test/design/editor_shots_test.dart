@Tags(['design'])
library;

import 'dart:io';

import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/data/flavor_config.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/pages/editor/editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_mock_channel_handlers.dart';
import 'design_shot.dart';
import 'package:badnotes/components/ui/bn_tool_panels.dart';
import 'package:badnotes/components/ui/ui.dart';

/// The editor's chrome and panels next to their mockups (design M_Editor,
/// M_EditorTop and the T screens).
void main() {
  late Directory docs;

  setUp(() async {
    FlavorConfig.setup();
    setupMockPathProvider();
    setupMockPrinting();
    setupMockWindowManager();
    stows.editorFingerDrawing.value = false;
    docs = Directory.systemTemp.createTempSync('badnotes-editor-shots');
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
          ? Future.value(const StandardMethodCodec().encodeSuccessEnvelope(null))
          : null;
    };
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding
            .instance
            .defaultBinaryMessenger
            .allMessagesHandler =
        null;
    docs.deleteSync(recursive: true);
  });

  Future<EditorState> shot(
    WidgetTester tester,
    String name, {
    String? mockup,
    Future<void> Function(WidgetTester tester, EditorState editor)? setUp,
  }) async {
    late EditorState editor;
    await designShot(
      tester,
      name,
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: BadNotesTheme.create(designBrightness),
        home: Editor(path: '/Physics — Class 12'),
      ),
      mockup: mockup ?? name,
      setUp: (tester) async {
        for (int i = 0; i < 4; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await tester.pump(const Duration(milliseconds: 100));
        }
        editor = tester.state<EditorState>(find.byType(Editor));
        if (setUp != null) await setUp(tester, editor);
      },
    );
    editor.cancelAutosaveAndMarkSaved();
    return editor;
  }

  testWidgets('editor, tool dock at the bottom', (tester) async {
    stows.floatingToolbarEdge.value = -1;
    await shot(tester, 'M_Editor');
    expect(find.bySemanticsLabel('Insert'), findsOneWidget);
  });

  testWidgets('editor, tools docked in the bar', (tester) async {
    stows.toolbarDocked.value = true;
    addTearDown(() => stows.toolbarDocked.value = false);
    await shot(tester, 'M_EditorDocked', mockup: 'M_Editor');
  });

  testWidgets('editor, tool dock moved to the top', (tester) async {
    stows.floatingToolbarEdge.value = 0;
    addTearDown(() => stows.floatingToolbarEdge.value = -1);
    await shot(tester, 'M_EditorTop');
  });

  testWidgets('insert', (tester) async {
    stows.floatingToolbarEdge.value = -1;
    await shot(
      tester,
      'T11_Insert',
      setUp: (tester, _) async {
        await tester.tap(find.bySemanticsLabel('Insert'));
        await tester.pump(const Duration(milliseconds: 400));
      },
    );
    expect(find.text('Sticky note'), findsOneWidget);
  });

  testWidgets('customize toolbar', (tester) async {
    stows.floatingToolbarEdge.value = -1;
    await shot(
      tester,
      'T19_Customize',
      setUp: (tester, _) async {
        await tester.tap(find.bySemanticsLabel('Insert'));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.tap(find.text('Customize toolbar'));
        await tester.pump(const Duration(milliseconds: 500));
      },
    );
    expect(find.text('More tools'), findsOneWidget);
  });

  /// Picks [tool] in the dock, then taps the sub-bar's first pill to open
  /// the tool's panel.
  Future<void> openTool(WidgetTester tester, String tool) async {
    await tester.tap(find.bySemanticsLabel(tool).first);
    await tester.pump(const Duration(milliseconds: 300));
    final pill = find.byType(BnToolPill);
    if (pill.evaluate().isNotEmpty) {
      await tester.tap(pill.first);
      await tester.pump(const Duration(milliseconds: 400));
    }
  }

  for (final (mockup, tool) in const [
    ('T03_Highlighter', 'Highlighter'),
    ('T04_Pencil', 'Pencil'),
    ('T05_SmartShapes', 'Draw shapes'),
    ('T06_Tape', 'Tape'),
    ('T08_Laser', 'Laser'),
    ('T09_Shapes', 'Shapes'),
    ('T10_Eraser', 'Eraser'),
    ('T24_Lasso', 'Lasso'),
  ]) {
    testWidgets('tool panel: $tool', (tester) async {
      stows.floatingToolbarEdge.value = -1;
      await shot(
        tester,
        mockup,
        setUp: (tester, _) => openTool(tester, tool),
      );
    });
  }

  testWidgets('pen settings', (tester) async {
    stows.floatingToolbarEdge.value = -1;
    await shot(
      tester,
      'T02_PenSettings',
      setUp: (tester, _) async {
        await openTool(tester, 'Pen');
        final more = find.text('Pen settings');
        if (more.evaluate().isNotEmpty) {
          await tester.tap(more.first);
          await tester.pump(const Duration(milliseconds: 400));
        }
      },
    );
  });

  testWidgets('colours', (tester) async {
    stows.floatingToolbarEdge.value = -1;
    await shot(
      tester,
      'T07_Colors',
      setUp: (tester, _) async {
        await tester.tap(find.byType(BnMoreColorsDot).first);
        await tester.pump(const Duration(milliseconds: 400));
      },
    );
  });

  /// Taps the button with [tooltip], then waits for what it opens.
  Future<void> tapTooltip(WidgetTester tester, String tooltip) async {
    await tester.tap(find.byTooltip(tooltip).first);
    await tester.pump(const Duration(milliseconds: 400));
  }

  /// Opens Insert, then the row or tile called [label].
  Future<void> fromInsert(WidgetTester tester, String label) async {
    await tester.tap(find.bySemanticsLabel('Insert').first);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text(label).first);
    await tester.pump(const Duration(milliseconds: 500));
  }

  for (final (mockup, open) in <(String, Future<void> Function(WidgetTester))>[
    ('T20_More', (t) => tapTooltip(t, 'More')),
    ('T23_PageOverview', (t) => tapTooltip(t, 'Pages')),
    ('T22_AddPage', (t) => fromInsert(t, 'Add page')),
    ('T21_Export', (t) => tapTooltip(t, 'Share and export')),
    ('T38_FindInNote', (t) => tapTooltip(t, 'Search')),
    ('T18_Timer', (t) => fromInsert(t, 'Timer & stopwatch')),
    ('T24_Recordings', (t) => fromInsert(t, 'Recordings')),
    ('T17_Ruler', (t) => fromInsert(t, 'Ruler')),
    ('T16_ZoomWindow', (t) => fromInsert(t, 'Zoom window')),
    ('T12_Stickers', (t) => fromInsert(t, 'Sticker')),
  ]) {
    testWidgets('editor: $mockup', (tester) async {
      stows.floatingToolbarEdge.value = -1;
      await shot(tester, mockup, setUp: (tester, _) => open(tester));
    });
  }
}
