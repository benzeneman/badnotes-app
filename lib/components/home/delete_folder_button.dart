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
  Future<void> open(BuildContext context) => showBnDialog<void>(
    context: context,
    title: '${t.home.deleteFolder.deleteName(f: '“$folderName”')}?',
    width: 420,
    // its own buttons: Delete waits for the tick and for the delete itself
    content: _ConfirmFolderDeletion(
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _explanation,
          style: BnType.body.copyWith(
            color: colors.muted,
            fontWeight: FontWeight.w400,
            height: 1.45,
          ),
        ),
        if (!_empty) ...[
          const SizedBox(height: 14),
          BnConfirmRow(
            label: t.home.deleteFolder.alsoDeleteContents,
            value: _notesToo,
            onChanged: (value) => setState(() => _notesToo = value),
          ),
        ],
        const SizedBox(height: 20),
        Wrap(
          alignment: WrapAlignment.end,
          spacing: 8,
          runSpacing: 8,
          children: [
            BnButton(
              label: t.common.cancel,
              onPressed: () => Navigator.of(context).pop(),
            ),
            BnButton.destructive(
              label: t.home.deleteFolder.delete,
              onPressed: _canDelete ? _confirm : null,
            ),
          ],
        ),
      ],
    );
  }
}
