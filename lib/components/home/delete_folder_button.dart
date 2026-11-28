import 'package:badnotes/components/home/delete_note_button.dart';
import 'package:badnotes/components/home/desk.dart';
import 'package:badnotes/components/home/trash.dart';
import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/ui/bn_home_dialogs.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/i18n/strings.g.dart';
import 'package:flutter/material.dart';

/// A trash button that asks before deleting the folder [folderName].
///
/// A folder with notes in it is only deleted once the user ticks that the
/// notes go too; they go to Trash, not for good.
class DeleteFolderButton extends StatelessWidget {
  const new({
    super.key,
    required this.folderName,
    required this.deleteFolder,
    required this.isFolderEmpty,
    this.folderPath,
  });

  final String folderName;
  final Future<void> Function(String) deleteFolder;
  final Future<bool> Function(String) isFolderEmpty;

  /// e.g. `/College`: when known, the dialog says how many notes go.
  final String? folderPath;

  /// Shows the confirmation, exactly as a tap on the button does, so menus
  /// can offer the same action.
  Future<void> open(BuildContext context) => showAppleDialog<void>(
    context: context,
    builder: (_) => _ConfirmFolderDeletion(
      folderName: folderName,
      folderPath: folderPath,
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
    required this.folderPath,
    required this.deleteFolder,
    required this.isFolderEmpty,
  });

  final String folderName;
  final String? folderPath;
  final Future<void> Function(String) deleteFolder;
  final Future<bool> Function(String) isFolderEmpty;

  @override
  State<_ConfirmFolderDeletion> createState() => _ConfirmFolderDeletionState();
}

class _ConfirmFolderDeletionState extends State<_ConfirmFolderDeletion> {
  /// Assumed to have notes until [_lookInside] finds otherwise.
  var _empty = false;

  /// How many notes are inside, at any depth, when the folder's path is known.
  int? _notes;

  /// Whether the user agreed that the notes inside go as well.
  var _notesToo = false;

  bool get _canDelete => _empty || _notesToo;

  @override
  void initState() {
    super.initState();
    _lookInside();
  }

  Future<void> _lookInside() async {
    if (widget.folderPath case final path?) {
      _notes = (await Trash.notesIn(path)).length;
      _empty = _notes == 0;
    } else {
      _empty = await widget.isFolderEmpty(widget.folderName);
    }
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

  String get _explanation {
    if (_empty) return 'The folder is empty.';
    final notes = switch (_notes) {
      null => 'notes',
      1 => 'note',
      final n => '$n notes',
    };
    return 'The folder and its $notes go to Trash. You can bring them back '
        'in the next 30 days.';
  }

  @override
  Widget build(BuildContext context) => ArtConfirmDialog(
    art: const TrashArt(item: FolderGlyph(width: 84)),
    title: '${t.home.deleteFolder.deleteName(f: '“${widget.folderName}”')}?',
    text: _explanation,
    actionLabel: t.home.deleteFolder.delete,
    enabled: _canDelete,
    onAction: _confirm,
    extra: _empty
        ? null
        : BnConfirmRow(
            label: t.home.deleteFolder.alsoDeleteContents,
            value: _notesToo,
            onChanged: (value) => setState(() => _notesToo = value),
          ),
  );
}
