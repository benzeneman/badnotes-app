import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/ui/bn_home_dialogs.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/i18n/strings.g.dart';
import 'package:flutter/material.dart';

/// An icon button that asks for a new name for [folderName] and hands it
/// to [renameFolder].
class RenameFolderButton extends StatelessWidget {
  const new({
    super.key,
    required this.folderName,
    required this.doesFolderExist,
    required this.renameFolder,
  });

  final String folderName;

  /// Tells whether a sibling folder with the given name is already there.
  final bool Function(String) doesFolderExist;

  /// Does the actual rename once the new name has passed the checks.
  final Future<void> Function(String newName) renameFolder;

  /// Shows the rename dialog. Menus call this directly so they behave the
  /// same as the button.
  Future<void> open(BuildContext context) async {
    showAppleDialog(
      context: context,
      builder: (_) => _FolderRenameDialog(button: this),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BnIconButton(
      icon: BnIcons.rename,
      tooltip: t.home.renameFolder.renameFolder,
      onPressed: () => open(context),
    );
  }
}

class _FolderRenameDialog extends StatefulWidget {
  const new({required this.button});

  /// The button that opened this dialog, for its name and callbacks.
  final RenameFolderButton button;

  @override
  State<_FolderRenameDialog> createState() => _FolderRenameDialogState();
}

class _FolderRenameDialogState extends State<_FolderRenameDialog> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _input;

  String get _currentName => widget.button.folderName;

  @override
  void initState() {
    super.initState();
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
    final strings = t.home.renameFolder;
    if (name == null || name.isEmpty) return strings.folderNameEmpty;
    if (name.contains(RegExp(r'[/\\]'))) return strings.folderNameContainsSlash;
    final taken = name != _currentName && widget.button.doesFolderExist(name);
    return taken ? strings.folderNameExists : null;
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    final wanted = _input.text;
    if (wanted != _currentName) await widget.button.renameFolder(wanted);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final strings = t.home.renameFolder;
    return BnRenameForm(
      formKey: _form,
      title: strings.renameFolder,
      label: strings.folderName,
      controller: _input,
      validator: _check,
      saveLabel: strings.rename,
      onSave: _submit,
      cancelLabel: t.common.cancel,
    );
  }
}
