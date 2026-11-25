import 'dart:async';

import 'package:badnotes/data/my_templates.dart';
import 'package:badnotes/components/editor/new_page_sheet.dart';
import 'package:badnotes/components/home/cloud_status.dart';
import 'package:badnotes/components/home/document_studio.dart';
import 'package:badnotes/components/home/home_layout_button.dart';
import 'package:badnotes/components/home/folder_info.dart';
import 'package:badnotes/components/home/new_folder_dialog.dart';
import 'package:badnotes/components/home/quick_board_view.dart';
import 'package:badnotes/components/home/notebook_cover.dart';
import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/editor/note_start.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/routes.dart';
import 'package:badnotes/i18n/strings.g.dart';
import 'package:badnotes/pages/editor/editor.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// What the home screen shows.
enum HomeFilter {
  all('All'),
  documents('Documents'),
  folders('Folders');

  const HomeFilter(this.label);

  final String label;
}

/// What the New button offers. [createFolder] is null where there are no
/// folders, like the recent documents.
class NewDocumentMenu {
  const NewDocumentMenu({this.path, this.createFolder, this.doesFolderExist});

  final String? path;
  final void Function(String)? createFolder;
  final bool Function(String)? doesFolderExist;

  /// Opens the New panel ("Create something", design N01) by [anchor].
  Future<void> show(BuildContext context, Rect anchor) {
    void newFolder() => this.newFolder(context);
    return showAnchoredPanel<void>(
      context,
      anchor: anchor,
      width: 380,
      builder: (panel) {
        final colors = BadNotesColors.of(panel);
        // the panel goes first, then what was chosen opens from the page
        void Function() pick(void Function() action) => () {
          Navigator.pop(panel);
          action();
        };
        final tiles = [
          _NewTile(
            icon: BnIcons.notebook,
            label: 'Notebook',
            caption: 'Pick a cover & paper',
            color: BnColors.accentTint,
            onTap: pick(() => newNotebook(context)),
          ),
          _NewTile(
            icon: BnIcons.sticky,
            label: 'Quick note',
            caption: 'Pins to your board',
            color: BnColors.noteButter,
            onTap: pick(() => showQuickComposer(context)),
          ),
          _NewTile(
              icon: BnIcons.folder,
              label: 'Folder',
              caption: 'Group your notebooks',
              color: const Color(0xFFECE7FB),
              onTap: pick(newFolder),
            ),
          _NewTile(
            icon: BnIcons.whiteboard,
            label: 'Whiteboard',
            caption: 'Endless canvas',
            color: BnFolderColor.sky.front,
            onTap: pick(() => newWhiteboard(context)),
          ),
        ];
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: .stretch,
            mainAxisSize: .min,
            children: [
              Text(
                'Create something',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: colors.text,
                ),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < tiles.length; i += 2) ...[
                if (i > 0) const SizedBox(height: 10),
                Row(
                  spacing: 10,
                  children: [
                    Expanded(child: tiles[i]),
                    Expanded(
                      child: i + 1 < tiles.length
                          ? tiles[i + 1]
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ],
              Container(
                height: 1.5,
                margin: const EdgeInsets.fromLTRB(0, 12, 0, 6),
                color: colors.divider,
              ),
              _NewRow(
                icon: BnIcons.file,
                label: 'Import PDF',
                caption: 'Or a notebook file',
                onTap: pick(() => importDocument(context)),
              ),
              _NewRow(
                icon: BnIcons.photo,
                label: 'Import image',
                caption: 'A notebook starting with a picture',
                onTap: pick(() => _newFrom(context, .image)),
              ),
              _NewRow(
                icon: LucideIcons.camera,
                label: 'Take photo',
                caption: 'With the camera',
                onTap: pick(() => _newFrom(context, .photo)),
              ),
              _NewRow(
                icon: LucideIcons.scanLine,
                label: 'Scan documents',
                caption: 'Board, notes, documents',
                onTap: pick(() => _newFrom(context, .scan)),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Asks for a new folder's name and colour, and makes it.
  Future<void> newFolder(BuildContext context) {
    String? created;
    return showAppleDialog<void>(
      context: context,
      builder: (context) => NewFolderDialog(
        createFolder: (name) {
          created = name;
          // from a page that isn't a folder (Recent, Favorites...): at the top
          final make = createFolder;
          if (make != null) {
            make(name);
          } else {
            unawaited(FileManager.createFolder('/$name'));
          }
        },
        doesFolderExist:
            doesFolderExist ??
            (name) => FileManager.isDirectory('/$name'),
        onColor: (style) {
          if (created == null || style == const FolderStyle()) return;
          FolderStyles.save('${path ?? ''}/$created', style);
        },
      ),
    );
  }

  /// Opens the document studio for a new notebook, pre-filled with
  /// [template] if given, and then the notebook.
  Future<void> newNotebook(
    BuildContext context, {
    DocumentTemplate? template,
  }) => _newDocument(context, whiteboard: false, template: template);

  /// Opens the document studio for a new whiteboard, and then the board.
  Future<void> newWhiteboard(BuildContext context) =>
      _newDocument(context, whiteboard: true);

  /// Picks a PDF or a notebook file and opens it.
  Future<void> importDocument(BuildContext context) => _import(context);

  Future<String> _pathFor(String name) {
    final folder = path ?? '';
    return name.isEmpty
        ? FileManager.newFilePath('$folder/')
        : FileManager.suffixFilePathToMakeItUnique('$folder/$name');
  }

  Future<void> _newDocument(
    BuildContext context, {
    required bool whiteboard,
    DocumentTemplate? template,
  }) async {
    // taken now: the New button that opened this can be rebuilt away while
    // the studio is up (the keyboard hides the dock), and then nothing
    // opened (design check, 22 Nov)
    final router = GoRouter.of(context);
    final document = await showDocumentStudio(
      context,
      whiteboard: whiteboard,
      template: template,
    );
    if (document == null) return;
    final filePath = await _pathFor(document.name);
    // from one of my templates: its page, with what's on it
    if (document.mine case final mine?) {
      await MyTemplates.writeAsNote(mine, filePath);
    }
    if (!whiteboard && document.start.pattern != null) {
      stows.lastBackgroundPattern.value = document.start.pattern!;
    }
    if (document.cover != null) {
      await NotebookCovers.write(filePath, document.cover);
    }
    final pdf = document.pdfPath;
    // a PDF brings its own pages
    if (pdf == null) NoteStart.set(filePath, document.start);
    unawaited(
      router.push(
        pdf == null
            ? RoutePaths.editFilePath(filePath)
            : RoutePaths.editImportPdf(filePath, pdf),
      ),
    );
  }

  /// A new notebook that asks for its pages as it opens.
  Future<void> _newFrom(BuildContext context, NewPageSource source) async {
    final router = GoRouter.of(context);
    final filePath = await _pathFor('');
    NoteStart.set(filePath, NoteStart(source: source));
    unawaited(router.push(RoutePaths.editFilePath(filePath)));
  }

  Future<void> _import(BuildContext context) async {
    final router = GoRouter.of(context);
    final file = await FilePicker.pickFile(type: FileType.any);
    final filePath = file?.path;
    if (file == null || filePath == null) return;
    final lower = filePath.toLowerCase();

    if (lower.endsWith('.sbn') ||
        lower.endsWith('.sbn2') ||
        lower.endsWith('.sba')) {
      final imported = await FileManager.importFile(filePath, '${path ?? ''}/');
      if (imported != null) {
        unawaited(router.push(RoutePaths.editFilePath(imported)));
      }
    } else if (lower.endsWith('.pdf')) {
      if (!Editor.canRasterPdf) return;
      final name = file.name.substring(0, file.name.length - '.pdf'.length);
      final sbnFilePath = await FileManager.suffixFilePathToMakeItUnique(
        '${path ?? ''}/$name',
      );
      unawaited(router.push(RoutePaths.editImportPdf(sbnFilePath, filePath)));
    } else if (context.mounted) {
      showBanner(context, t.home.invalidFormat);
    }
  }
}

/// The row above the documents: what to show on the left; what to add, how to
/// show it and how syncing is going on the right.
class HomeBar extends StatelessWidget {
  const HomeBar({
    super.key,
    required this.filter,
    required this.onFilter,
    required this.menu,
    this.viewLeading = const [],
    this.viewTrailing = const [],
  });

  final HomeFilter filter;
  final ValueChanged<HomeFilter> onFilter;
  final NewDocumentMenu menu;

  /// Extra choices in the grid button's menu, see [ViewOptionsButton].
  final List<AppleMenuEntry> viewLeading, viewTrailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 600;
    return Padding(
      padding: EdgeInsets.fromLTRB(wide ? 14 : 4, 6, wide ? 16 : 4, 0),
      child: Row(
        spacing: 4,
        children: [
          Builder(
            builder: (context) => TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSurface,
                // the app's font: a bare TextStyle had no family, and the
                // button showed in the phone's own font
                textStyle: TextTheme.of(context).labelLarge
                    ?.copyWith(fontSize: 16),
              ),
              icon: const Icon(Icons.filter_list, size: 22),
              label: Text(filter.label),
              onPressed: () => showAppleMenu(
                context,
                anchor: rectOf(context),
                entries: [
                  for (final choice in HomeFilter.values)
                    AppleMenuItem(
                      choice.label,
                      checked: choice == filter,
                      onTap: () => onFilter(choice),
                    ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Builder(
            builder: (context) => FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: const StadiumBorder(),
                minimumSize: const Size(0, 42),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                textStyle: TextTheme.of(context).labelLarge
                    ?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              icon: const Icon(Icons.add, size: 22),
              label: const Text('New'),
              onPressed: () => menu.show(context, rectOf(context)),
            ),
          ),
          const SizedBox(width: 4),
          ViewOptionsButton(leading: viewLeading, trailing: viewTrailing),
          Container(width: 1, height: 26, color: colorScheme.outlineVariant),
          const CloudStatusButton(),
        ],
      ),
    );
  }
}

/// A big tinted choice in the New panel's grid.
class _NewTile extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.caption,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label, caption;

  /// A pastel: artwork, the same in light and dark.
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 92,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: .start,
            mainAxisAlignment: .spaceBetween,
            children: [
              Icon(icon, size: 22, color: BnColors.text),
              Column(
                crossAxisAlignment: .start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: BnColors.text,
                    ),
                  ),
                  Text(
                    caption,
                    maxLines: 1,
                    overflow: .ellipsis,
                    style: const TextStyle(fontSize: 11, color: BnColors.text2),
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

/// A row of the New panel: an icon in a soft square, a label and a caption.
class _NewRow extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.caption,
    required this.onTap,
  });

  final IconData icon;
  final String label, caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        hoverColor: colors.rowHover,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            spacing: 12,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colors.sunkenSoft,
                  borderRadius: BorderRadius.circular(BnRadius.control),
                ),
                child: Icon(icon, size: 18, color: colors.text),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  mainAxisAlignment: .center,
                  children: [
                    Text(
                      label,
                      style: BnType.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.text,
                      ),
                    ),
                    Text(
                      caption,
                      style: BnType.micro.copyWith(
                        fontWeight: FontWeight.w400,
                        color: colors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
