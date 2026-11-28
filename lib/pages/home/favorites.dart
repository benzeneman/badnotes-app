import 'dart:async';

import 'package:badnotes/components/home/desk.dart';
import 'package:badnotes/components/home/documents_grid.dart';
import 'package:badnotes/components/home/folder_info.dart';
import 'package:badnotes/components/home/home_shell.dart';
import 'package:badnotes/components/home/new_note_button.dart';
import 'package:badnotes/components/home/note_facts.dart';
import 'package:badnotes/components/home/page_tile.dart';
import 'package:badnotes/components/home/preview_card.dart';
import 'package:badnotes/components/home/trash.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/routes.dart';
import 'package:badnotes/pages/editor/editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

/// What the favorites show.
enum _Show {
  all('All'),
  notebooks('Notebooks'),
  folders('Folders'),
  pages('Pages');

  const _Show(this.label);

  final String label;
}

/// Starred notebooks and folders (design N17).
class const FavoritesPage({super.key}) extends StatefulHookWidget {
  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final selectedFiles = ValueNotifier<List<String>>([]);
  StreamSubscription? _fileWrites;
  var _show = _Show.all;

  /// Bumped on each note written or deleted, to check the stars again.
  var _writes = 0;

  void _setState() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    selectedFiles.addListener(_onSelection);
    _fileWrites = FileManager.fileWriteStream.stream.listen((event) {
      if (event.isNoteAsset) return;
      _writes++;
      _setState();
    });
  }

  void _onSelection() {
    HomeChrome.selecting.value = selectedFiles.value.isNotEmpty;
    _setState();
  }

  @override
  void dispose() {
    selectedFiles.removeListener(_onSelection);
    HomeChrome.selecting.value = false;
    _fileWrites?.cancel();
    super.dispose();
  }

  void _toggle(String file, bool selected) {
    selectedFiles.value = selected
        ? [...selectedFiles.value, file]
        : ([...selectedFiles.value]..remove(file));
  }

  @override
  Widget build(BuildContext context) {
    useListenable(stows.homeLayout);
    useListenable(stows.homeCoverSize);
    HomeChrome.newMenu.value = const NewDocumentMenu();
    final favorites = useValueListenable(stows.favoriteNotes);
    useEffect(() {
      NoteFactsCache.scan();
      return null;
    }, const []);
    final facts = useValueListenable(NoteFactsCache.facts);
    final bookmarked = [
      if (_show == .all || _show == .pages)
        for (final MapEntry(key: path, value: f) in facts.entries)
          for (final page in f.bookmarks) (path, page),
    ];
    // checked on changes, not on every build (a selection, say)
    final starred = useMemoized(
      () => [
        for (final path in favorites)
          // a starred note moved to the trash keeps its star, re-pointed
          // into the hidden trash folder
          if (isVisiblePath(path) &&
              FileManager.getFile(path + Editor.extension).existsSync())
            path,
      ],
      [favorites, _writes],
    );
    final files = [
      if (_show == .all || _show == .notebooks) ...starred,
    ];
    final folders = [
      if (_show == .all || _show == .folders)
        for (final key in favorites)
          if (key.endsWith('/') && FileManager.isDirectory(key))
            key.substring(0, key.length - 1),
    ];
    final folderActions = FolderActions(
      onTap: (name) {},
      doesFolderExist: (_) => false,
      rename: (_, _) async {},
      isEmpty: (_) async => true,
      delete: (_) async {},
    );

    return HomePageFrame(
      title: 'Favorites',
      caption: 'Your favourite notebooks, folders and bookmarked pages',
      trailing: BnSegmented(
        expand: !HomeChrome.isWide(context),
        segments: [for (final s in _Show.values) BnSegment(s, s.label)],
        selected: _show,
        onChanged: (s) => setState(() => _show = s),
      ),
      selectedFiles: selectedFiles,
      selectable: files,
      slivers: [
        if (files.isEmpty && folders.isEmpty && bookmarked.isEmpty)
          SliverToBoxAdapter(
            child: _show == .all
                ? const _NoFavorites()
                : Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Text(
                      'Nothing here for this filter.',
                      textAlign: TextAlign.center,
                      style: BnType.body.copyWith(
                        color: BadNotesColors.of(context).muted,
                      ),
                    ),
                  ),
          )
        else if (files.isNotEmpty || folders.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: BnSectionHeader(
              title: switch (_show) {
                .notebooks => 'Notebooks',
                .folders => 'Folders',
                _ => 'Notebooks & folders',
              },
            ),
          ),
          if (stows.homeLayout.value == .list && files.isNotEmpty) ...[
            if (folders.isNotEmpty) _folderGrid(folders, folderActions),
            if (folders.isNotEmpty)
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            DocumentGrid(files: files, selectedFiles: selectedFiles),
          ] else
            SliverLayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.crossAxisExtent;
                const gap = 18.0;
                final minWidth = DocumentGrid.minCoverWidth(
                  stows.homeCoverSize.value,
                  wide: HomeChrome.isWide(context),
                );
                final columns = ((width + gap) / (minWidth + gap))
                    .floor()
                    .clamp(2, 10);
                final tileWidth = (width - gap * (columns - 1)) / columns;
                final tileHeight = tileWidth * 4 / 3 + 10 + 40;
                return SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: gap,
                    mainAxisSpacing: 22,
                    mainAxisExtent: tileHeight,
                  ),
                  itemCount: folders.length + files.length,
                  itemBuilder: (context, i) {
                    if (i < folders.length) {
                      // level with the covers' bottom, under the titles
                      return Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 44),
                          child: _favoriteFolder(context, folders[i], folderActions),
                        ),
                      );
                    }
                    final file = files[i - folders.length];
                    return RepaintBoundary(
                      child: PreviewCard(
                        filePath: file,
                        toggleSelection: _toggle,
                        selected: selectedFiles.value.contains(file),
                        isAnythingSelected: selectedFiles.value.isNotEmpty,
                      ),
                    );
                  },
                );
              },
            ),
        ],
        if (bookmarked.isNotEmpty) ...[
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
          const SliverToBoxAdapter(
            child: BnSectionHeader(title: 'Bookmarked pages'),
          ),
          SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 160,
              mainAxisSpacing: 22,
              crossAxisSpacing: 18,
              childAspectRatio: 0.78,
            ),
            itemCount: bookmarked.length,
            itemBuilder: (context, i) {
              final (path, page) = bookmarked[i];
              return PageTile(
                path: path,
                page: page,
                bookmark: true,
                label: '${p.basename(path)} · page ${page + 1}',
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _folderGrid(List<String> folders, FolderActions actions) =>
      SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 240,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          mainAxisExtent: 104,
        ),
        itemCount: folders.length,
        itemBuilder: (context, i) =>
            _favoriteFolder(context, folders[i], actions),
      );

  Widget _favoriteFolder(
    BuildContext context,
    String path,
    FolderActions actions,
  ) {
    final name = p.basename(path);
    return DeskFolderTile(
      key: ValueKey(path),
      name: name,
      path: path,
      actions: FolderActions(
        onTap: (_) => context.go(HomeRoutes.browseFilePath(path)),
        doesFolderExist: (n) =>
            FileManager.isDirectory(p.join(p.dirname(path), n)),
        rename: (_, newName) async {
          await FileManager.renameDirectory(path, newName);
        },
        isEmpty: (_) async {
          final children = await FileManager.getChildrenOfDirectory(path);
          return children?.isEmpty ?? true;
        },
        delete: (_) => Trash.moveFolderToTrash(path),
      ),
    );
  }
}

class const _NoFavorites() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colors.accentTint,
              shape: BoxShape.circle,
            ),
            child: Icon(BnIcons.favorites, size: 24, color: colors.accent),
          ),
          const SizedBox(height: 16),
          Text(
            'Nothing starred yet',
            style: BnType.title.copyWith(color: colors.text),
          ),
          const SizedBox(height: 6),
          Text(
            'Long-press a notebook or folder and tap Star to keep it here.',
            textAlign: TextAlign.center,
            style: BnType.body.copyWith(
              color: colors.muted,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
