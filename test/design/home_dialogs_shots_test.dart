@Tags(['design'])
library;

// Screenshots of the home screen's dialogs, menus and pickers next to their
// mockups (design N01, N04, N05, N07, N09, N11, N14, N25, N26, N28).
//
//   OUT=build/design-out/home_dialogs MOCKUPS=build/design-mockups \
//     flutter test test/design/home_dialogs_shots_test.dart
import 'package:badnotes/components/home/cloud_status.dart';
import 'package:badnotes/components/home/cover_designs.dart';
import 'package:badnotes/components/home/delete_note_button.dart';
import 'package:badnotes/components/home/document_studio.dart';
import 'package:badnotes/components/home/home_layout_button.dart';
import 'package:badnotes/components/home/move_note_button.dart';
import 'package:badnotes/components/home/new_folder_dialog.dart';
import 'package:badnotes/components/home/new_note_button.dart';
import 'package:badnotes/components/home/notebook_cover.dart';
import 'package:badnotes/components/home/rename_note_button.dart';
import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/data/flavor_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_mock_channel_handlers.dart';
import 'design_shot.dart';

const _note = '/Physics — Class 12';

/// A plain desk with anchors where the mockups' buttons are.
class _Desk extends StatelessWidget {
  const new();

  static final newKey = GlobalKey(), sortKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BnColors.desk,
      body: Stack(
        children: [
          Positioned(
            left: 822,
            top: 727,
            child: SizedBox(key: newKey, width: 120, height: 44),
          ),
          Positioned(
            left: 846,
            top: 338,
            child: SizedBox(key: sortKey, width: 90, height: 36),
          ),
          const Positioned(left: 1160, top: 28, child: CloudStatusButton()),
        ],
      ),
    );
  }
}

Future<void> _open(
  WidgetTester tester,
  Future<void> Function(BuildContext context) open,
) async {
  final context = tester.element(find.byType(_Desk));
  // not awaited: it finishes when the dialog closes
  open(context);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  FlavorConfig.setup();
  setupMockPathProvider();

  setUp(() async {
    await FileManager.init(shouldWatchRootDirectory: false);
  });

  testWidgets('N01 Create', (tester) async {
    await designShot(
      tester,
      'N01_Create',
      designApp(const _Desk()),
      setUp: (tester) => _open(tester, (context) {
        final anchor = rectOf(_Desk.newKey.currentContext!);
        return NewDocumentMenu(
          createFolder: (_) {},
          doesFolderExist: (_) => false,
        ).show(context, anchor);
      }),
    );
    expect(find.text('Create something'), findsOneWidget);
  });

  testWidgets('N04 New notebook', (tester) async {
    await designShot(
      tester,
      'N04_NewNotebook',
      designApp(const _Desk()),
      setUp: (tester) async {
        await _open(
          tester,
          (context) => showDocumentStudio(context, whiteboard: false),
        );
        await tester.enterText(find.byType(TextField).first, 'Chemistry Notes');
      },
    );
    expect(find.text('New notebook'), findsOneWidget);
  });

  testWidgets('N04 New notebook from a template', (tester) async {
    await designShot(
      tester,
      'N04_NewNotebook_template',
      designApp(const _Desk()),
      mockup: 'N04_NewNotebook',
      setUp: (tester) => _open(
        tester,
        (context) => showDocumentStudio(
          context,
          whiteboard: false,
          template: DocumentTemplate.lectureNotes,
        ),
      ),
    );
    expect(find.text('Lecture notes'), findsOneWidget);
  });

  testWidgets('N04 New whiteboard', (tester) async {
    await designShot(
      tester,
      'N04_NewWhiteboard',
      designApp(const _Desk()),
      mockup: 'N04_NewNotebook',
      setUp: (tester) => _open(
        tester,
        (context) => showDocumentStudio(context, whiteboard: true),
      ),
    );
    expect(find.text('New whiteboard'), findsOneWidget);
  });

  testWidgets('N05 New folder', (tester) async {
    BnFolderColor? chosen;
    await designShot(
      tester,
      'N05_NewFolder',
      designApp(const _Desk()),
      setUp: (tester) async {
        await _open(
          tester,
          (context) => showAppleDialog<void>(
            context: context,
            builder: (_) => NewFolderDialog(
              createFolder: (_) {},
              doesFolderExist: (_) => false,
              onColor: (color) => chosen = color,
            ),
          ),
        );
        await tester.enterText(find.byType(TextField), 'Exams 2026');
        await tester.tap(find.bySemanticsLabel('sky'));
        await tester.pump();
      },
    );
    await tester.tap(find.text('Create'));
    await tester.pump();
    expect(chosen, BnFolderColor.sky);
  });

  testWidgets('N07 Delete', (tester) async {
    await designShot(
      tester,
      'N07_Delete',
      designApp(const _Desk()),
      setUp: (tester) => _open(tester, (context) async {
        showBanner(
          context,
          'Moved to Trash',
          actionLabel: 'Undo',
          duration: const Duration(seconds: 1),
        );
        await DeleteNoteButton(
          filesToDelete: const [_note],
          unselectNotes: () {},
        ).open(context);
      }),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(find.textContaining('Physics'), findsOneWidget);
  });

  testWidgets('N09 Sync', (tester) async {
    await designShot(
      tester,
      'N09_Sync',
      designApp(const _Desk()),
      setUp: (tester) async {
        await tester.tap(find.byType(CloudStatusButton));
        await tester.pump();
      },
    );
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('N11 Sort', (tester) async {
    await designShot(
      tester,
      'N11_Sort',
      designApp(const _Desk()),
      setUp: (tester) => _open(
        tester,
        (context) => showViewOptions(
          context,
          anchor: rectOf(_Desk.sortKey.currentContext!),
          sort: [
            const AppleMenuItem('Last Modified', checked: true),
            const AppleMenuItem('Name'),
          ],
        ),
      ),
    );
    expect(find.text('Cover size'), findsOneWidget);
  });

  testWidgets('N14 Move to', (tester) async {
    await tester.runAsync(() async {
      for (final folder in ['College', 'Personal', 'Work', 'test']) {
        await FileManager.createFolder('/$folder');
      }
    });
    await designShot(
      tester,
      'N14_MoveTo',
      designApp(const _Desk()),
      setUp: (tester) async {
        await _open(
          tester,
          (context) => MoveNoteButton(
            filesToMove: const [_note],
            unselectNotes: () {},
          ).open(context),
        );
        // let the folders be listed
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)),
        );
        await tester.pump();
      },
    );
    expect(find.text('Move to…'), findsOneWidget);
  });

  testWidgets('N25 Rename', (tester) async {
    await designShot(
      tester,
      'N25_Rename',
      designApp(const _Desk()),
      setUp: (tester) => _open(
        tester,
        (context) => RenameNoteButton(
          existingPath: _note,
          unselectNotes: () {},
        ).open(context),
      ),
    );
    expect(find.text('Rename note'), findsWidgets);
  });

  testWidgets('N26 Cover', (tester) async {
    await designShot(
      tester,
      'N26_Cover',
      designApp(const _Desk()),
      setUp: (tester) => _open(
        tester,
        (context) => showCoverLibrary(
          context,
          current: CoverDesign.solid(CoverDesign.pastelColors.first),
          title: 'Physics',
          compact: true,
        ),
      ),
    );
    expect(find.text('Change cover'), findsOneWidget);
  });

  testWidgets('N28 Cover library', (tester) async {
    await designShot(
      tester,
      'N28_CoverLibrary',
      designApp(const _Desk()),
      setUp: (tester) => _open(
        tester,
        (context) => showCoverLibrary(
          context,
          current: CoverDesign.fromId('d:bloom'),
          title: 'Physics — Class 12',
        ),
      ),
    );
    expect(find.text('Apply cover'), findsOneWidget);
  });
}
