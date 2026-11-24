import 'package:badnotes/components/home/delete_folder_button.dart';
import 'package:badnotes/components/home/new_folder_dialog.dart';
import 'package:badnotes/components/home/rename_folder_button.dart';
import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/bn_home_dialogs.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/i18n/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

/// A sliver listing the folders in one place (design N14): a row to go up
/// a level (except at the top), one row per folder, then a "New folder"
/// row. Long-pressing or right-clicking a folder offers rename and delete.
class GridFolders extends StatelessWidget {
  const new({
    super.key,
    required this.isAtRoot,
    required this.onTap,
    required this.crossAxisCount,
    required this.createFolder,
    required this.renameFolder,
    required this.isFolderEmpty,
    required this.deleteFolder,
    required this.doesFolderExist,
    required this.folders,
  });

  final bool isAtRoot;

  /// Called with a folder's name, or with `..` to go up.
  final Function(String) onTap;

  /// How many rows sit side by side; 1 or less gives a plain list.
  final int crossAxisCount;

  final void Function(String) createFolder;
  final bool Function(String) doesFolderExist;
  final Future<void> Function(String oldName, String newName) renameFolder;
  final Future<bool> Function(String) isFolderEmpty;
  final Future<void> Function(String) deleteFolder;

  final List<String> folders;

  @override
  Widget build(BuildContext context) {
    final upRows = isAtRoot ? 0 : 1;
    final rowCount = upRows + folders.length + 1;

    Widget buildRow(BuildContext context, int index) {
      final _RowKind kind = index < upRows
          ? .up
          : index == rowCount - 1
          ? .create
          : .folder;
      return _FolderRow(
        kind: kind,
        folderName: kind == .folder ? folders[index - upRows] : null,
        createFolder: createFolder,
        doesFolderExist: doesFolderExist,
        renameFolder: renameFolder,
        isFolderEmpty: isFolderEmpty,
        deleteFolder: deleteFolder,
        onTap: onTap,
      );
    }

    if (crossAxisCount > 1) {
      return SliverAlignedGrid.count(
        itemCount: rowCount,
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        itemBuilder: buildRow,
      );
    }
    return SliverList.separated(
      itemCount: rowCount,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: buildRow,
    );
  }
}

/// What a row of [GridFolders] stands for.
enum _RowKind { up, create, folder }

class _FolderRow extends StatelessWidget {
  const new({
    required this.kind,
    required this.folderName,
    required this.createFolder,
    required this.doesFolderExist,
    required this.renameFolder,
    required this.isFolderEmpty,
    required this.deleteFolder,
    required this.onTap,
  }) : assert(
         (folderName == null) ^ (kind == .folder),
         'Real folders must specify a folder name',
       );

  final _RowKind kind;

  /// Set only for [_RowKind.folder].
  final String? folderName;
  final void Function(String) createFolder;
  final bool Function(String) doesFolderExist;
  final Future<void> Function(String oldName, String newName) renameFolder;
  final Future<bool> Function(String) isFolderEmpty;
  final Future<void> Function(String) deleteFolder;
  final Function(String) onTap;

  bool get _isFolder => kind == .folder;

  void _activate(BuildContext context) {
    switch (kind) {
      case .create:
        showAppleDialog(
          context: context,
          builder: (context) => NewFolderDialog(
            createFolder: createFolder,
            doesFolderExist: doesFolderExist,
          ),
        );
      case .up:
        onTap('..');
      case .folder:
        onTap(folderName!);
    }
  }

  /// The rename / delete menu for a folder row.
  void _openMenu(BuildContext context) {
    final name = folderName!;
    final rename = RenameFolderButton(
      folderName: name,
      doesFolderExist: doesFolderExist,
      renameFolder: (newName) => renameFolder(name, newName),
    );
    final delete = DeleteFolderButton(
      folderName: name,
      deleteFolder: deleteFolder,
      isFolderEmpty: isFolderEmpty,
    );
    showAppleMenu(
      context,
      anchor: rectOf(context),
      entries: [
        AppleMenuItem(
          t.home.renameFolder.renameFolder,
          icon: BnIcons.rename,
          onTap: () => rename.open(context),
        ),
        AppleMenuItem(
          t.home.deleteFolder.deleteFolder,
          icon: BnIcons.trash,
          destructive: true,
          onTap: () => delete.open(context),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final (Widget icon, String label) = switch (kind) {
      .up => (
        SizedBox(
          width: 34,
          child: Icon(BnIcons.back, size: 18, color: colors.text2),
        ),
        t.home.backFolder,
      ),
      .create => (
        BnDashedBox(
          width: 34,
          height: 28,
          child: Icon(BnIcons.add, size: 14, color: colors.text2),
        ),
        t.home.newFolder.newFolder,
      ),
      .folder => (
        BnFolderGlyph(color: BnFolderColor.lavender.back),
        folderName!,
      ),
    };
    final menu = _isFolder ? () => _openMenu(context) : null;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        hoverColor: colors.rowHover,
        onTap: () => _activate(context),
        onLongPress: menu,
        onSecondaryTap: menu,
        child: Container(
          height: _isFolder ? 56 : 52,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            spacing: 14,
            children: [
              icon,
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BnType.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _isFolder ? colors.text : colors.text2,
                  ),
                ),
              ),
              if (_isFolder)
                Icon(BnIcons.forward, size: 16, color: colors.faint),
            ],
          ),
        ),
      ),
    );
  }
}
