import 'package:badnotes/components/home/grid_folders.dart';
import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/bn_home_dialogs.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/i18n/strings.g.dart';
import 'package:badnotes/pages/editor/editor.dart';
import 'package:flutter/material.dart';

/// A button that opens a folder browser for moving the notes in
/// [filesToMove] (paths without their extension).
class MoveNoteButton extends StatelessWidget {
  const new({
    super.key,
    required this.filesToMove,
    required this.unselectNotes,
  });

  final List<String> filesToMove;
  final void Function() unselectNotes;

  /// Shows the folder browser, exactly as a tap on the button does, so menus
  /// can offer the same action. Returns without waiting for it to close.
  Future<void> open(BuildContext context) async {
    showAppleDialog(
      context: context,
      builder: (_) => _MoveNotesDialog(
        filesToMove: filesToMove,
        unselectNotes: unselectNotes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => BnIconButton(
    tooltip: t.home.moveNote.moveNote,
    icon: BnIcons.move,
    onPressed: () => open(context),
  );
}

class _MoveNotesDialog extends StatefulWidget {
  const new({required this.filesToMove, required this.unselectNotes});

  final List<String> filesToMove;
  final void Function() unselectNotes;

  @override
  State<_MoveNotesDialog> createState() => _MoveNotesDialogState();
}

class _MoveNotesDialogState extends State<_MoveNotesDialog> {
  List<String> get _sources => widget.filesToMove;

  /// Each note's file name, without its folder.
  late final List<String> _names = [
    for (final path in _sources) path.substring(path.lastIndexOf('/') + 1),
  ];

  /// Each note's folder, ending in a slash.
  late final List<String> _homes = [
    for (final path in _sources) path.substring(0, path.lastIndexOf('/') + 1),
  ];

  /// For each note, whether it is stored in the old JSON format
  /// ([Editor.extensionOldJson]). All false until [_detectOldFormats].
  late List<bool> _isOldFormat = [for (final _ in _sources) false];

  String _extensionOf(int i) =>
      _isOldFormat[i] ? Editor.extensionOldJson : Editor.extension;

  Future<void> _detectOldFormats() async {
    _isOldFormat = [
      for (final path in _sources)
        FileManager.doesFileExist('$path${Editor.extensionOldJson}'),
    ];
  }

  late String _folder;

  /// The folder being browsed, which is where the notes will go. Changing
  /// it reloads [_contents].
  String get _destination => _folder;
  set _destination(String folder) {
    _folder = folder;
    _contents = null;
    _reload();
  }

  /// What is inside [_destination], once loaded.
  DirectoryChildren? _contents;

  /// The name each note gets in [_destination]: its own name, unless that
  /// is taken, in which case a free variant that is also listed in
  /// [_renamed].
  List<String> _targetNames = [];

  /// Just the names that had to change to avoid a clash.
  List<String> _renamed = [];

  Future<void> _reload() async {
    _contents = await FileManager.getChildrenOfDirectory(_destination);

    _targetNames = [];
    _renamed = [];
    for (var i = 0; i < _sources.length; i++) {
      final extension = _extensionOf(i);
      final freePath = await FileManager.suffixFilePathToMakeItUnique(
        '$_destination${_names[i]}',
        intendedExtension: extension,
        currentPath: '${_sources[i]}$extension',
      );
      final target = freePath.substring(freePath.lastIndexOf('/') + 1);
      _targetNames.add(target);
      if (target != _names[i]) _renamed.add(target);
    }

    if (mounted) setState(() {});
  }

  /// The folder most of the notes are in now.
  String _mostSharedHome() {
    final tally = <String, int>{};
    for (final home in _homes) {
      tally.update(home, (n) => n + 1, ifAbsent: () => 1);
    }
    return tally.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  @override
  void initState() {
    _destination = _mostSharedHome();
    if (!_destination.startsWith('/')) _destination = '/$_destination';
    super.initState();

    _detectOldFormats().then((_) => _reload());
  }

  /// [_destination]'s own name, or "Desk" at the top.
  String get _destinationName {
    final path = _destination.endsWith('/')
        ? _destination.substring(0, _destination.length - 1)
        : _destination;
    final name = path.substring(path.lastIndexOf('/') + 1);
    return name.isEmpty ? 'Desk' : name;
  }

  /// Goes into [folder], or up a level for `..`.
  void _enter(String folder) {
    setState(() {
      _destination = folder == '..'
          ? _destination.substring(
              0,
              _destination.lastIndexOf('/', _destination.length - 2) + 1,
            )
          : '$_destination$folder/';
    });
  }

  Future<void> _makeFolder(String name) async {
    await FileManager.createFolder('$_destination/$name');
    _reload();
  }

  Future<void> _renameFolder(String oldName, String newName) async {
    await FileManager.renameDirectory('$_destination$oldName', newName);
    _reload();
  }

  Future<bool> _isFolderEmpty(String name) async {
    final inside = await FileManager.getChildrenOfDirectory(
      '$_destination$name',
    );
    return inside?.isEmpty ?? true;
  }

  Future<void> _deleteFolder(String name) async {
    await FileManager.deleteDirectory('$_destination$name');
    _reload();
  }

  Future<void> _moveAll() async {
    for (var i = 0; i < _sources.length; i++) {
      final extension = _extensionOf(i);
      await FileManager.moveFile(
        '${_sources[i]}$extension',
        '$_destination${_targetNames[i]}$extension',
      );
    }
    widget.unselectNotes();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final atTop = _destination == '/';
    final alreadyHere = _homes.every(
      (home) => (home.startsWith('/') ? home : '/$home') == _destination,
    );
    final caption = BnType.caption.copyWith(color: colors.muted);

    return BnDialogCard(
      width: 460,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            subtitle: _names.length < 5
                ? _names.join(', ')
                : t.home.moveNote.moveNotes(n: _names.length),
          ),
          const SizedBox(height: 14),
          _DestinationCard(
            title: atTop ? 'Desk (no folder)' : _destinationName,
            subtitle: alreadyHere ? 'Currently here' : _destination,
            atTop: atTop,
          ),
          const SizedBox(height: 4),
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: CustomScrollView(
                shrinkWrap: true,
                slivers: [
                  GridFolders(
                    isAtRoot: atTop,
                    crossAxisCount: 1,
                    onTap: _enter,
                    createFolder: _makeFolder,
                    doesFolderExist: (name) =>
                        _contents?.directories.contains(name) ?? false,
                    renameFolder: _renameFolder,
                    isFolderEmpty: _isFolderEmpty,
                    deleteFolder: _deleteFolder,
                    folders: [...?_contents?.directories],
                  ),
                ],
              ),
            ),
          ),
          if (_renamed.isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._renameNotice(caption),
          ],
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 10,
            runSpacing: 10,
            children: [
              BnPillButton(
                label: t.common.cancel,
                onPressed: () => Navigator.of(context).pop(),
              ),
              BnPillButton(
                label: atTop
                    ? t.home.moveNote.move
                    : '${t.home.moveNote.move} · $_destinationName',
                kind: BnPillKind.tint,
                onPressed: _moveAll,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Tells the user which notes get new names: each one when there are a
  /// few, just how many otherwise.
  List<Widget> _renameNotice(TextStyle style) {
    if (_renamed.length == 1) {
      return [
        Text(t.home.moveNote.renamedTo(newName: _renamed.single), style: style),
      ];
    }
    if (_renamed.length < 5) {
      return [
        Text(t.home.moveNote.multipleRenamedTo, style: style),
        Text(_renamed.join(', '), style: style),
      ];
    }
    return [
      Text(t.home.moveNote.numberRenamedTo(n: _renamed.length), style: style),
    ];
  }
}

/// A tilted notebook beside "Move to…" and what is being moved.
class _Header extends StatelessWidget {
  const new({required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Row(
      spacing: 14,
      children: [
        Transform.rotate(
          angle: -0.1,
          child: Container(
            width: 44,
            height: 60,
            decoration: BoxDecoration(
              color: BnColors.lavender,
              border: Border.all(color: colors.hairline),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(3),
                bottomLeft: Radius.circular(3),
                topRight: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Move to…',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: colors.text,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: BnType.body.copyWith(
                  color: colors.muted,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The outlined card showing the folder the notes will go to.
class _DestinationCard extends StatelessWidget {
  const new({required this.title, required this.subtitle, required this.atTop});

  final String title;
  final String subtitle;
  final bool atTop;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.accent, width: 1.5),
      ),
      child: Row(
        spacing: 14,
        children: [
          BnFolderGlyph(
            color: atTop ? colors.surface : BnFolderColor.lavender.back,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BnType.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.text,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BnType.micro.copyWith(
                    color: colors.muted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const BnCheckBadge(size: 24),
        ],
      ),
    );
  }
}
