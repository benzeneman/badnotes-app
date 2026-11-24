import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/bn_home_dialogs.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/i18n/strings.g.dart';
import 'package:badnotes/components/home/trash.dart';
import 'package:flutter/material.dart';

/// A trash button for the notes in [filesToDelete]; it asks first.
class DeleteNoteButton extends StatelessWidget {
  const new({
    super.key,
    required this.filesToDelete,
    required this.unselectNotes,
  });

  final List<String> filesToDelete;
  final void Function() unselectNotes;

  /// Shows the confirmation, exactly as a tap on the button does, so menus
  /// can offer the same action.
  Future<void> open(BuildContext context) => showAppleDialog(
    context: context,
    builder: (_) => _ConfirmNoteDeletion(
      filesToDelete: filesToDelete,
      unselectNotes: unselectNotes,
    ),
  );

  @override
  Widget build(BuildContext context) => BnIconButton(
    tooltip: t.home.deleteNote,
    icon: BnIcons.trash,
    onPressed: () => open(context),
  );
}

/// Confirms sending notes to the trash (design N07). Afterwards "Undo" can
/// take it back for 5 seconds, and the trash holds the notes for 30 days.
class _ConfirmNoteDeletion extends StatelessWidget {
  const new({required this.filesToDelete, required this.unselectNotes});

  final List<String> filesToDelete;
  final void Function() unselectNotes;

  Future<void> _toss(BuildContext context) async {
    // grabbed before closing, while this context still has one
    final messenger = ScaffoldMessenger.maybeOf(context);
    Navigator.of(context).pop();
    unselectNotes();
    await moveToTrashWithUndo(messenger, filesToDelete);
  }

  String get _title {
    final count = filesToDelete.length;
    if (count >= 5) return 'Toss $count notes?';
    final names = filesToDelete
        .map((path) => path.substring(path.lastIndexOf('/') + 1))
        .join(', ');
    return 'Toss “$names”?';
  }

  String get _explanation => filesToDelete.length == 1
      ? 'It goes to Trash with all its pages. You can bring it back anytime '
            'in the next 30 days.'
      : 'They go to Trash with all their pages. You can bring them back '
            'anytime in the next 30 days.';

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return BnDialogCard(
      width: 440,
      padding: const EdgeInsets.all(28),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _NotebookIntoBin(),
            const SizedBox(height: 18),
            Text(
              _title,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.4,
                height: 1.2,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _explanation,
              textAlign: TextAlign.center,
              style: BnType.bodyLarge.copyWith(
                fontWeight: FontWeight.w400,
                height: 1.5,
                color: colors.muted,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              spacing: 10,
              children: [
                Expanded(
                  child: BnPillButton(
                    label: 'Keep it',
                    height: 50,
                    expand: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Expanded(
                  child: BnPillButton(
                    label: 'Move to Trash',
                    kind: BnPillKind.danger,
                    height: 50,
                    expand: true,
                    onPressed: () => _toss(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Artwork: a notebook leaning back with a red bin in front of it.
class _NotebookIntoBin extends StatelessWidget {
  const new();

  static const _spine = Radius.circular(4);
  static const _edge = Radius.circular(10);

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final notebook = Container(
      width: 74,
      height: 100,
      decoration: BoxDecoration(
        color: BnColors.lavender,
        border: Border.all(color: colors.hairline),
        borderRadius: const BorderRadius.only(
          topLeft: _spine,
          bottomLeft: _spine,
          topRight: _edge,
          bottomRight: _edge,
        ),
      ),
    );
    final bin = Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          colors.danger.withValues(alpha: 0.14),
          colors.surface,
        ),
        shape: BoxShape.circle,
        border: Border.all(color: colors.hairline),
      ),
      child: Icon(BnIcons.trash, size: 24, color: colors.danger),
    );
    return SizedBox(
      width: 120,
      height: 110,
      child: Stack(
        children: [
          Positioned(
            left: 22,
            top: 0,
            child: Transform.rotate(angle: -0.21, child: notebook),
          ),
          Positioned(right: 6, bottom: 0, child: bin),
        ],
      ),
    );
  }
}
