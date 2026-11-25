import 'package:badnotes/data/pro/pro.dart';
import 'package:badnotes/components/editor/boards_panel.dart';
import 'package:badnotes/components/home/delete_note_button.dart';
import 'package:badnotes/components/home/desk.dart';
import 'package:badnotes/components/home/rename_note_button.dart';
import 'package:badnotes/components/home/trash.dart';
import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/home/home_actions.dart';
import 'package:badnotes/components/home/home_shell.dart';
import 'package:badnotes/components/home/new_note_button.dart';
import 'package:badnotes/components/home/note_facts.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:badnotes/components/canvas/save_indicator.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/i18n/strings.g.dart';
import 'package:badnotes/pages/editor/editor.dart';

class const Whiteboard({super.key}) extends StatelessWidget {
  static const filePath = '/_whiteboard';

  static bool needsToAutoClearWhiteboard =
      stows.autoClearWhiteboardOnExit.value;

  static final _whiteboardKey = GlobalKey<EditorState>(
    debugLabel: 'whiteboard',
  );

  static SavingState? get savingState =>
      _whiteboardKey.currentState?.savingState.value;
  static void triggerSave() {
    final editorState = _whiteboardKey.currentState;
    if (editorState == null) return;
    assert(editorState.savingState.value == .waitingToSave);
    editorState.saveToFile();
    editorState.snackBarNeedsToSaveBeforeExiting();
  }

  @override
  Widget build(BuildContext context) {
    return Editor(
      key: _whiteboardKey,
      path: filePath,
      customTitle: t.home.titles.whiteboard,
      board: true,
    );
  }
}

/// Asks before clearing the Quick whiteboard (design F7); on Clear it goes
/// to the Trash with Undo. Whether it was cleared.
Future<bool> confirmClearQuickBoard(BuildContext context) async {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  final clear = await showBnDialog<bool>(
    context: context,
    title: 'Clear the Quick whiteboard?',
    message:
        'Everything on it goes to the Trash for 30 days; the board starts '
        'empty.',
    actions: const [
      BnDialogAction('Cancel', value: false),
      BnDialogAction('Clear', value: true, primary: true, destructive: true),
    ],
  );
  if (clear != true) return false;
  await moveToTrashWithUndo(overlay, [Whiteboard.filePath]);
  return true;
}

/// The Whiteboard tab (design N18): every whiteboard, the quick one first.
class WhiteboardsPage extends HookWidget {
  const new({super.key});

  static const _quick = Whiteboard.filePath;

  void _openQuick(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (context) => const Whiteboard()),
  );

  @override
  Widget build(BuildContext context) {
    useEffect(() {
      NoteFactsCache.scan();
      return null;
    }, const []);
    final facts = useValueListenable(NoteFactsCache.facts);
    final menu = HomeChrome.newMenu.value = const NewDocumentMenu();
    final boards = [
      for (final MapEntry(key: path, value: f) in facts.entries)
        if (f.board && path != _quick) path,
    ]..sort(
        (a, b) => FileManager.lastModified(b + Editor.extension)
            .compareTo(FileManager.lastModified(a + Editor.extension)),
      );
    return HomePageFrame(
      title: 'Whiteboards',
      caption: 'Endless canvases for brainstorming, mind maps and sketches',
      trailing: Builder(
        builder: (context) => BnButton.primary(
          label: 'New whiteboard',
          icon: BnIcons.add,
          onPressed: () => menu.newWhiteboard(context),
        ),
      ),
      slivers: [
        SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 420,
            mainAxisSpacing: 26,
            crossAxisSpacing: 24,
            mainAxisExtent: 250,
          ),
          delegate: SliverChildListDelegate([
            _BoardCard(
              path: _quick,
              title: t.home.titles.whiteboard,
              onTap: () => _openQuick(context),
            ),
            for (final path in boards)
              _BoardCard(
                path: path,
                title: noteName(path),
                onTap: () => openNote(context, path),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 200,
                  child: BnNewFolderTile(
                    label: 'Blank whiteboard',
                    height: 200,
                    onTap: () => menu.newWhiteboard(context),
                  ),
                ),
              ],
            ),
          ]),
        ),
      ],
    );
  }
}

class _BoardCard extends StatelessWidget {
  const _BoardCard({
    required this.path,
    required this.title,
    required this.onTap,
  });

  final String path, title;
  final VoidCallback onTap;

  bool get _quick => path == Whiteboard.filePath;

  /// Rename, duplicate or delete the board; the quick one is only cleared.
  void _menu(BuildContext context, Rect anchor) => showAppleMenu(
    context,
    anchor: anchor,
    entries: _quick
        ? [
            AppleMenuItem(
              'Clear board',
              icon: Icons.delete_sweep_outlined,
              destructive: true,
              onTap: () => confirmClearQuickBoard(context),
            ),
          ]
        : [
            AppleMenuItem(
              'Rename',
              icon: Icons.drive_file_rename_outline,
              onTap: () => RenameNoteButton(
                existingPath: path,
                unselectNotes: () {},
              ).open(context),
            ),
            AppleMenuItem(
              'Duplicate',
              icon: Icons.copy_outlined,
              onTap: () async {
                if (await Pro.mayDuplicate(context, [path])) {
                  await duplicateNotes([path]);
                }
              },
            ),
            AppleMenuItem(
              'Delete',
              icon: Icons.delete_outline,
              destructive: true,
              onTap: () => DeleteNoteButton(
                filesToDelete: [path],
                unselectNotes: () {},
              ).open(context),
            ),
          ],
  );

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final edited = FileManager.lastModified(path + Editor.extension);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: () => _menu(context, rectOf(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              fit: StackFit.expand,
              children: [
                BoardThumb(path: path),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Builder(
                    builder: (context) => Material(
                      color: colors.surface,
                      elevation: 2,
                      shape: const StadiumBorder(),
                      child: BnIconButton(
                        icon: Icons.more_horiz,
                        size: 32,
                        iconSize: 18,
                        tooltip: 'Whiteboard options',
                        color: colors.text2,
                        onPressed: () => _menu(context, rectOf(context)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: BnType.body.copyWith(
              color: colors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'Edited ${homeMeta(edited).toLowerCase()}',
            style: BnType.caption.copyWith(color: colors.muted),
          ),
        ],
      ),
    );
  }
}
