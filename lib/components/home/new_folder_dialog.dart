import 'package:badnotes/components/home/folder_info.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/bn_home_dialogs.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/i18n/strings.g.dart';
import 'package:flutter/material.dart';

/// Lets the user name a new folder and pick its colour (design N05), with a
/// live preview of how it will look.
class NewFolderDialog extends StatefulWidget {
  const new({
    super.key,
    required this.createFolder,
    required this.doesFolderExist,
    this.onColor,
  });

  final void Function(String) createFolder;
  final bool Function(String) doesFolderExist;

  /// Receives the picked colour right after [createFolder] runs; storing it
  /// is the caller's job.
  final ValueChanged<FolderStyle>? onColor;

  @override
  State<NewFolderDialog> createState() => _NewFolderDialogState();
}

class _NewFolderDialogState extends State<NewFolderDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  var _style = const FolderStyle();

  /// Leading and trailing spaces never become part of a folder's name.
  static String _tidy(String name) => name.trim();

  /// Rejects names that are empty, contain a slash or already exist.
  String? _check(String? typed) {
    if (typed == null || typed.isEmpty) return t.home.newFolder.folderNameEmpty;
    final name = _tidy(typed);
    if (name.contains('/') || name.contains('\\')) {
      return t.home.newFolder.folderNameContainsSlash;
    }
    if (widget.doesFolderExist(name)) return t.home.newFolder.folderNameExists;
    return null;
  }

  void _submit() {
    if (!_form.currentState!.validate()) return;
    widget.createFolder(_tidy(_name.text));
    widget.onColor?.call(_style);
    Navigator.of(context).pop();
  }

  void _close() => Navigator.of(context).pop();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = t.home.newFolder.newFolder;
    return BnDialogCard(
      child: Form(
        key: _form,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BnDialogTitle(title: placeholder, onClose: _close),
              const SizedBox(height: 20),
              ListenableBuilder(
                listenable: _name,
                builder: (context, _) {
                  final typed = _name.text.trim();
                  return _FolderPreview(
                    color: _style.shades,
                    name: typed.isEmpty ? placeholder : typed,
                  );
                },
              ),
              const SizedBox(height: 20),
              BnFieldLabel(t.home.newFolder.folderName),
              BnTextInput(
                controller: _name,
                autofocus: true,
                hint: placeholder,
                validator: _check,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 20),
              const BnFieldLabel('Color', bottom: 10),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final option in BnFolderColor.values)
                    BnSwatchDot(
                      color: option.back,
                      label: option.name,
                      selected: _style.custom == null && option == _style.color,
                      onTap: () => setState(
                        () => _style = _style.copyWith(color: option),
                      ),
                    ),
                  if (_style.custom case final custom?)
                    BnSwatchDot(
                      color: Color(custom),
                      label: 'custom',
                      selected: true,
                      onTap: () {},
                    ),
                  FolderColorPlus(
                    size: 32,
                    current: _style.custom == null ? null : Color(_style.custom!),
                    onChanged: (c) => setState(
                      () => _style = _style.copyWith(custom: c.toARGB32()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 10,
                runSpacing: 10,
                children: [
                  BnPillButton(label: t.common.cancel, onPressed: _close),
                  BnPillButton(
                    label: t.home.newFolder.create,
                    kind: BnPillKind.tint,
                    onPressed: _submit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A slightly tilted mock-up of the folder being made, on a pale backdrop.
class _FolderPreview extends StatelessWidget {
  const new({required this.color, required this.name});

  final BnFolderShades color;
  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final side = BorderSide(color: colors.hairline);

    final tab = Container(
      width: 72,
      height: 16,
      decoration: BoxDecoration(
        color: color.back,
        border: Border(top: side, left: side, right: side),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
    );

    final body = Container(
      height: 100,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: color.back,
        border: Border.fromBorderSide(side),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        boxShadow: BnShadows.floating,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '0 items',
            style: BnType.micro.copyWith(
              fontWeight: FontWeight.w600,
              color: BnColors.text,
            ),
          ),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: BnColors.text,
            ),
          ),
        ],
      ),
    );

    return Container(
      height: 150,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.previewBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Transform.rotate(
        angle: -0.052,
        child: AnimatedContainer(
          duration: BnMotion.fast,
          width: 190,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [tab, body],
          ),
        ),
      ),
    );
  }
}
