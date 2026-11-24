import 'dart:io';

import 'package:android_file_picker/android_file_picker.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/bn_settings.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/data/nextcloud/badnotes_syncer.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/i18n/strings.g.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sbn/font_fallbacks.dart';

/// True when nothing is stored at [path]: the folder is missing or has no
/// entries in it.
bool _holdsNothing(String path) {
  final folder = Directory(path);
  if (!folder.existsSync()) return true;
  return folder.listSync().isEmpty;
}

/// A settings row showing where notes are stored. Tapping it opens a
/// [DirectorySelector] to move them somewhere else.
class SettingsDirectorySelector extends StatelessWidget {
  const new({
    super.key,
    required this.title,
    required this.icon,
    this.afterChange,
    this.isUnsupported = true,
  });

  final String title;
  final IconData icon;
  final ValueChanged<Color?>? afterChange;
  final bool isUnsupported;

  /// Opens the folder chooser. A new folder only has to be empty when the
  /// current one already holds something.
  void onPressed(BuildContext context) async {
    final current = FileManager.documentsDirectory;
    final currentHasFiles = !_holdsNothing(current);
    await showBnSettingsDialog<void>(
      context: context,
      builder: (context) => DirectorySelector(
        title: title,
        initialDirectory: FileManager.documentsDirectory,
        mustBeEmpty: currentHasFiles,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: stows.customDataDir,
      builder: (context, _, _) => BnSettingsRow(
        title: title,
        subtitle: FileManager.documentsDirectory,
        chevron: true,
        onTap: () => onPressed(context),
      ),
    );
  }
}

/// A dialog for choosing the folder notes are kept in.
///
/// Confirming is blocked while [mustBeEmpty] is set and the chosen folder
/// has files, or while [mustBeDoneSyncing] is set and sync still has work
/// queued.
class DirectorySelector extends StatefulWidget {
  const new({
    super.key,
    required this.title,
    required this.initialDirectory,
    this.mustBeEmpty = true,
    this.mustBeDoneSyncing = true,
  });

  final String title;
  final String initialDirectory;
  final bool mustBeEmpty;
  final bool mustBeDoneSyncing;

  @override
  State<DirectorySelector> createState() => _DirectorySelectorState();
}

class _DirectorySelectorState extends State<DirectorySelector> {
  late String _chosen = widget.initialDirectory;
  var _chosenIsEmpty = true;

  static const _androidPickerOptions = FilePickerAndroidOptions(
    safOptions: .new(
      grant: .lifetime,
      accessMode: .readWrite,
      persistGrant: true,
    ),
  );

  void _choose(String path) {
    _chosen = path;
    _chosenIsEmpty = _holdsNothing(path);
    if (mounted) setState(() {});
  }

  Future<void> _browse() async {
    final picked = await FilePicker.getDirectoryPath(
      dialogTitle: widget.title,
      initialDirectory: _chosen,
      androidOptions: defaultTargetPlatform == .android
          ? _androidPickerOptions
          : const .new(),
    );
    if (picked == null || picked == _chosen) return;
    _choose(picked);
  }

  Future<void> _resetToDefault() async {
    _choose(await FileManager.getDefaultDocumentsDirectory());
  }

  void _confirm() {
    stows.customDataDir.value = _chosen;
    context.pop();
  }

  bool get _syncBusy =>
      syncer.uploader.numPending > 0 || syncer.downloader.numPending > 0;

  Widget _pathField(BadNotesColors colors) {
    Widget action(IconData icon, VoidCallback onPressed) =>
        BnIconButton(icon: icon, iconSize: 18, size: 34, onPressed: onPressed);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: colors.sunkenSoft,
        borderRadius: const BorderRadius.all(Radius.circular(BnRadius.control)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _chosen,
              style: TextStyle(
                fontSize: 13,
                color: colors.text,
                fontFamily: 'FiraMono',
                fontFamilyFallback: badnotesMonoFontFallbacks,
              ),
            ),
          ),
          action(BnIcons.folder, _browse),
          if (stows.customDataDir.value != null)
            action(BnIcons.undo, _resetToDefault),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final warning = BnType.caption.copyWith(color: colors.danger, height: 1.45);
    final strings = t.settings.customDataDir;

    final notEmpty = widget.mustBeEmpty && !_chosenIsEmpty;
    final stillSyncing = widget.mustBeDoneSyncing && _syncBusy;
    final blocked = notEmpty || stillSyncing;

    return BnDialogCard(
      title: widget.title,
      content: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        spacing: 10,
        children: [
          Text(strings.unsupported, style: warning),
          _pathField(colors),
          if (notEmpty) Text(strings.mustBeEmpty, style: warning),
          if (stillSyncing) Text(strings.mustBeDoneSyncing, style: warning),
        ],
      ),
      actions: [
        BnButton(label: strings.cancel, onPressed: () => context.pop()),
        BnButton.primary(
          label: strings.select,
          onPressed: blocked ? null : _confirm,
        ),
      ],
    );
  }
}
