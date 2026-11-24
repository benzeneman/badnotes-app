import 'dart:io';

import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/ui/bn_home_dialogs.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/i18n/strings.g.dart';
import 'package:badnotes/pages/editor/editor.dart';
import 'package:flutter/material.dart';

/// An icon button that asks for a new name for the note at [existingPath]
/// and renames it.
class RenameNoteButton extends StatelessWidget {
  const new({
    super.key,
    required this.existingPath,
    required this.unselectNotes,
  });

  /// The note's path without the file extension.
  final String existingPath;

  /// Called after the dialog closes from a successful save.
  final void Function() unselectNotes;

  /// Shows the rename dialog. Menus call this directly so they behave the
  /// same as the button.
  Future<void> open(BuildContext context) async {
    showAppleDialog(
      context: context,
      builder: (_) => _NoteRenameDialog(
        existingPath: existingPath,
        unselectNotes: unselectNotes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BnIconButton(
      icon: BnIcons.rename,
      tooltip: t.home.renameNote.renameNote,
      onPressed: () => open(context),
    );
  }
}

class _NoteRenameDialog extends StatefulWidget {
  const new({required this.existingPath, required this.unselectNotes});

  final String existingPath;
  final void Function() unselectNotes;

  @override
  State<_NoteRenameDialog> createState() => _NoteRenameDialogState();
}

class _NoteRenameDialogState extends State<_NoteRenameDialog> {
  final _form = GlobalKey<FormState>();
  late final String _folder;
  late final String _currentName;
  late final TextEditingController _input;

  @override
  void initState() {
    super.initState();
    final path = widget.existingPath;
    final cut = path.lastIndexOf('/') + 1;
    _folder = path.substring(0, cut); // keeps the trailing '/'
    _currentName = path.substring(cut);
    _input = TextEditingController(text: _currentName)
      ..selection = TextSelection(
        baseOffset: 0,
        extentOffset: _currentName.length,
      );
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  String? _check(String? name) {
    if (name == null) return t.home.renameNote.noteNameEmpty;
    final problem = FileManager.validateFilename(name);
    if (problem != null) return problem;
    final taken = name != _currentName && File(_folder + name).existsSync();
    return taken ? t.home.renameNote.noteNameExists : null;
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final wanted = _input.text;
    if (wanted != _currentName) {
      await FileManager.moveFile(
        widget.existingPath + Editor.extension,
        wanted + Editor.extension,
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    widget.unselectNotes();
  }

  @override
  Widget build(BuildContext context) {
    final strings = t.home.renameNote;
    return BnRenameForm(
      formKey: _form,
      title: strings.renameNote,
      label: strings.noteName,
      controller: _input,
      validator: _check,
      saveLabel: strings.rename,
      onSave: _submit,
      cancelLabel: t.common.cancel,
    );
  }
}
