import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/data/flavor_config.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/tools/eraser.dart';
import 'package:badnotes/data/tools/pen.dart';
import 'package:badnotes/pages/editor/editor.dart';

import 'utils/test_mock_channel_handlers.dart';

void main() {
  group('disableEraserAfterUse', () {
    for (final disableEraserAfterUse in const [true, false]) {
      testWidgets('$disableEraserAfterUse', (tester) async {
        FlavorConfig.setup();
        FileManager.documentsDirectory =
            '$tmpDir/disableEraserAfterUse/'
            '${FileManager.appRootDirectoryPrefix}';
        stows.disableEraserAfterUse.value = disableEraserAfterUse;

        await tester.pumpWidget(MaterialApp(home: Editor()));
        final state = tester.state<EditorState>(find.byType(Editor));
        addTearDown(state.cancelAutosaveAndMarkSaved);

        state.currentTool = Eraser();
        state.dragPageIndex = 0;
        state.onDrawEnd(.new());
        await tester.pump();

        if (disableEraserAfterUse) {
          expect(state.currentTool, isA<Pen>());
        } else {
          expect(state.currentTool, isA<Eraser>());
        }
      });
    }
  });
}
