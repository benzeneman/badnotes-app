import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/bn_home_dialogs.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/i18n/strings.g.dart';
import 'package:flutter/material.dart';

/// A trash button that asks before deleting the folder [folderName].
///
/// A folder with notes in it is only deleted once the user ticks that the
/// notes go too.
class DeleteFolderButton extends StatelessWidget {
  const new({
    super.key,
    required this.folderName,
    required this.deleteFolder,
    required this.isFolderEmpty,
  });

  final String folderName;
  final Future<void> Function(String) deleteFolder;
  final Future<bool> Function(String) isFolderEmpty;

  /// Shows the confirmation, exactly as a tap on the button does, so menus
  /// can offer the same action.
  Future<void> open(BuildContext context) => showAppleDialog(
    context: context,
    builder: (_) => _ConfirmFolderDeletion(
      folderName: folderName,
      deleteFolder: deleteFolder,
      isFolderEmpty: isFolderEmpty,
    ),
  );

  @override
  Widget build(BuildContext context) => BnIconButton(
    tooltip: t.home.deleteFolder.deleteFolder,
    icon: BnIcons.trash,
    onPressed: () => open(context),
  );
}

class _ConfirmFolderDeletion extends StatefulWidget {
  const new({
    required this.folderName,
    required this.deleteFolder,
    required this.isFolderEmpty,
  });

  final String folderName;
  final Future<void> Function(String) deleteFolder;
  final Future<bool> Function(String) isFolderEmpty;

  @override
  State<_ConfirmFolderDeletion> createState() => _ConfirmFolderDeletionState();
}

class _ConfirmFolderDeletionState extends State<_ConfirmFolderDeletion> {
  /// Assumed to have notes until [_lookInside] finds otherwise.
  var _empty = false;

  /// Whether the user agreed that the notes inside go as well.
  var _notesToo = false;

  bool get _canDelete => _empty || _notesToo;

  @override
  void initState() {
    super.initState();
    _lookInside();
  }

  Future<void> _lookInside() async {
    _empty = await widget.isFolderEmpty(widget.folderName);
    if (_empty) _notesToo = false;
    if (mounted) setState(() {});
  }

  /// While the delete runs, so a second tap doesn't delete again and then
  /// close the page under the dialog.
  var _deleting = false;

  Future<void> _confirm() async {
    if (_deleting) return;
    _deleting = true;
    await widget.deleteFolder(widget.folderName);
    if (mounted) Navigator.of(context).pop();
  }

  String get _explanation => _empty
      ? "The folder is empty. It is deleted for good; this can't be undone."
      : "The folder and the notes in it are deleted for good. This can't be "
            'undone.';

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
            _DangerBadge(colors: colors),
            const SizedBox(height: 18),
            Text(
              '${t.home.deleteFolder.deleteName(f: '“${widget.folderName}”')}?',
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
            if (!_empty) ...[
              const SizedBox(height: 16),
              BnConfirmRow(
                label: t.home.deleteFolder.alsoDeleteContents,
                value: _notesToo,
                onChanged: (value) => setState(() => _notesToo = value),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              spacing: 10,
              children: [
                Expanded(
                  child: BnPillButton(
                    label: t.common.cancel,
                    height: 50,
                    expand: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Expanded(
                  child: BnPillButton(
                    label: t.home.deleteFolder.delete,
                    kind: BnPillKind.danger,
                    height: 50,
                    expand: true,
                    onPressed: _canDelete ? _confirm : null,
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

/// A round trash badge tinted with the danger colour.
class _DangerBadge extends StatelessWidget {
  const new({required this.colors});

  final BadNotesColors colors;

  @override
  Widget build(BuildContext context) => Container(
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
}
