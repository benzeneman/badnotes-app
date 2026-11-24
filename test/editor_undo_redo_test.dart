import 'package:badnotes/components/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_screenshot/golden_screenshot.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/data/flavor_config.dart';
import 'package:badnotes/i18n/strings.g.dart';
import 'package:badnotes/pages/editor/editor.dart';

import 'utils/test_mock_channel_handlers.dart';

void main() {
  testGoldens('Editor: undo/redo buttons interaction test', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();

    setupMockPathProvider();
    setupMockPrinting();

    FlavorConfig.setup();
    await tester.runAsync(FileManager.init);

    await tester.pumpWidget(
      TranslationProvider(
        child: ScreenshotApp(
          device: GoldenScreenshotDevices.androidPhone.device,
          home: Editor(),
        ),
      ),
    );

    final editorState = tester.state<EditorState>(find.byType(Editor));
    expect(
      editorState.coreInfo.readOnly,
      isFalse,
      reason: 'New file should not be read-only',
    );
    addTearDown(editorState.cancelAutosaveAndMarkSaved);

    // undo and redo are in the header
    await tester.pump();
    BnIconButton getUndoBtn() => tester.widget<BnIconButton>(
      find.ancestor(
        of: find.byIcon(BnIcons.undo),
        matching: find.byType(BnIconButton),
      ),
    );
    BnIconButton getRedoBtn() => tester.widget<BnIconButton>(
      find.ancestor(
        of: find.byIcon(BnIcons.redo),
        matching: find.byType(BnIconButton),
      ),
    );

    expect(
      [getUndoBtn().onPressed, getRedoBtn().onPressed],
      [isNull, isNull],
      reason: 'Undo/redo buttons should be disabled initially',
    );

    await drawOnEditor(tester);
    await tester.pump();
    expect(editorState.coreInfo.pages.first.strokes, hasLength(1));
    expect(
      [getUndoBtn().onPressed, getRedoBtn().onPressed],
      [isNotNull, isNull],
      reason: 'Undo button should be enabled after first draw',
    );

    // undo
    await tester.ensureVisible(find.byIcon(BnIcons.undo));
    await tester.pump();
    await tester.tap(find.byIcon(BnIcons.undo));
    await tester.pump();
    expect(editorState.coreInfo.pages.first.strokes, hasLength(0));
    expect(
      [getUndoBtn().onPressed, getRedoBtn().onPressed],
      [isNull, isNotNull],
      reason: 'Undo button should be disabled after undo',
    );

    // redo
    await tester.ensureVisible(find.byIcon(BnIcons.redo));
    await tester.pump();
    await tester.tap(find.byIcon(BnIcons.redo));
    await tester.pump();
    expect(editorState.coreInfo.pages.first.strokes, hasLength(1));
    expect(
      [getUndoBtn().onPressed, getRedoBtn().onPressed],
      [isNotNull, isNull],
      reason: 'Undo button should be enabled after redo',
    );

    // undo, then draw again
    await tester.ensureVisible(find.byIcon(BnIcons.undo));
    await tester.pump();
    await tester.tap(find.byIcon(BnIcons.undo));
    await tester.pump();
    expect(editorState.coreInfo.pages.first.strokes, hasLength(0));
    await drawOnEditor(tester);
    await tester.pump();
    expect(editorState.coreInfo.pages.first.strokes, hasLength(1));
    expect(
      [getUndoBtn().onPressed, getRedoBtn().onPressed],
      [isNotNull, isNull],
      reason: 'Undo button should be enabled after undo and draw',
    );
  });
}

Future drawOnEditor(WidgetTester tester) => tester.timedDrag(
  find.byType(Editor),
  const Offset(50, 0),
  const Duration(milliseconds: 100),
);
