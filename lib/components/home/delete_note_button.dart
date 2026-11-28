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
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    Navigator.of(context).pop();
    unselectNotes();
    await moveToTrashWithUndo(overlay, filesToDelete);
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
  Widget build(BuildContext context) => ArtConfirmDialog(
    art: const TrashArt(),
    title: _title,
    text: _explanation,
    actionLabel: 'Move to Trash',
    onAction: () => _toss(context),
  );
}

/// A confirmation with artwork over a big title (design N07): the style of
/// every delete. Open it with [showAppleDialog]; the cancel button closes it.
class ArtConfirmDialog extends StatelessWidget {
  const new({
    super.key,
    required this.art,
    required this.title,
    required this.text,
    this.cancelLabel = 'Keep it',
    required this.actionLabel,
    required this.onAction,
    this.extra,
    this.enabled = true,
  });

  final Widget art;
  final String title, text, cancelLabel, actionLabel;
  final VoidCallback onAction;

  /// Shown under [text], e.g. a tick to agree to.
  final Widget? extra;

  /// Whether the action can be taken yet.
  final bool enabled;

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
            art,
            const SizedBox(height: 18),
            Text(
              title,
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
              text,
              textAlign: TextAlign.center,
              style: BnType.bodyLarge.copyWith(
                fontWeight: FontWeight.w400,
                height: 1.5,
                color: colors.muted,
              ),
            ),
            if (extra != null) ...[const SizedBox(height: 16), extra!],
            const SizedBox(height: 20),
            Row(
              spacing: 10,
              children: [
                Expanded(
                  child: BnPillButton(
                    label: cancelLabel,
                    height: 50,
                    expand: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Expanded(
                  child: BnPillButton(
                    label: actionLabel,
                    kind: BnPillKind.danger,
                    height: 50,
                    expand: true,
                    onPressed: enabled ? onAction : null,
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

/// Artwork: [item] (a notebook unless given) leaning back with a red bin in
/// front of it.
class TrashArt extends StatelessWidget {
  const new({super.key, this.item});

  /// e.g. a folder, or [TrashArt.notebooks] for several things.
  final Widget? item;

  static const _spine = Radius.circular(4);
  static const _edge = Radius.circular(10);

  /// A notebook as the art draws it, [scale] times its size.
  static Widget notebook(BuildContext context, {double scale = 1}) =>
      Container(
        width: 74 * scale,
        height: 100 * scale,
        decoration: BoxDecoration(
          color: BnColors.lavender,
          border: Border.all(color: BadNotesColors.of(context).hairline),
          borderRadius: BorderRadius.only(
            topLeft: _spine * scale,
            bottomLeft: _spine * scale,
            topRight: _edge * scale,
            bottomRight: _edge * scale,
          ),
        ),
      );

  /// A few smaller notebooks fanned out, for several things at once.
  static Widget notebooks(BuildContext context) => SizedBox(
    width: 90,
    height: 100,
    child: Stack(
      children: [
        for (final (x, y, turn) in const [(0.0, 12.0, -0.2), (24.0, 0.0, 0.1)])
          Positioned(
            left: x,
            top: y,
            child: Transform.rotate(
              angle: turn,
              child: notebook(context, scale: 0.75),
            ),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
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
            child: Transform.rotate(
              angle: -0.21,
              child: item ?? notebook(context),
            ),
          ),
          Positioned(right: 6, bottom: 0, child: bin),
        ],
      ),
    );
  }
}
