import 'dart:async';

import 'package:badnotes/components/home/cloud_status.dart';
import 'package:badnotes/components/home/desk.dart';
import 'package:badnotes/components/home/document_studio.dart';
import 'package:badnotes/components/home/home_layout_button.dart';
import 'package:badnotes/components/home/documents_grid.dart';
import 'package:badnotes/components/home/folder_info.dart';
import 'package:badnotes/components/home/home_actions.dart';
import 'package:badnotes/components/home/note_facts.dart';
import 'package:badnotes/components/home/note_tags.dart';
import 'package:badnotes/components/home/home_shell.dart';
import 'package:badnotes/components/home/new_note_button.dart';
import 'package:badnotes/components/home/photos_view.dart';
import 'package:badnotes/components/home/quick_board_view.dart';
import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/favorites.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/routes.dart';
import 'package:badnotes/i18n/strings.g.dart';
import 'package:badnotes/pages/editor/editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

/// What the desk shows.
enum DeskFilter {
  all('All'),
  notebooks('Notebooks'),
  folders('Folders'),
  photos('Photos'),
  favorites('Favorites');

  const DeskFilter(this.label);

  final String label;
}

/// How "All folders" is sorted.
enum _FolderSort {
  name('Name'),
  recent('Recent'),
  size('Size');

  const _FolderSort(this.label);

  final String label;
}

/// The desk (design M_Home) and, inside a folder, the folder (N15).
class BrowsePage extends StatefulHookWidget {
  const new({super.key, String? path}) : initialPath = path;

  final String? initialPath;

  @visibleForTesting
  static DirectoryChildren? overrideChildren;

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  DirectoryChildren? children;

  String? path;

  final ValueNotifier<List<String>> selectedFiles = ValueNotifier([]);

  var _filter = DeskFilter.all;

  /// Only notes with this tag (N6), or all.
  String? _tag;

  /// Showing every folder (N19) instead of the desk.
  var _allFolders = false;
  var _folderSort = _FolderSort.name;

  @override
  void initState() {
    path = widget.initialPath;

    findChildrenOfPath();
    fileWriteSubscription = FileManager.fileWriteStream.stream.listen(
      fileWriteListener,
    );
    selectedFiles.addListener(_onSelection);

    super.initState();
  }

  @override
  void dispose() {
    selectedFiles.removeListener(_onSelection);
    HomeChrome.selecting.value = false;
    fileWriteSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  StreamSubscription? fileWriteSubscription;
  Timer? _refreshTimer;
  void fileWriteListener(FileOperation event) {
    if (!event.filePath.startsWith(path ?? '/')) return;
    if (event.isNoteAsset) return;
    // One save writes several files: list the folder once, after them all,
    // instead of once for each.
    _refreshTimer?.cancel();
    _refreshTimer = Timer(
      const Duration(milliseconds: 250),
      () => findChildrenOfPath(fromFileListener: true),
    );
  }

  void _onSelection() {
    HomeChrome.selecting.value = selectedFiles.value.isNotEmpty;
    setState(() {});
  }

  Future findChildrenOfPath({bool fromFileListener = false}) async {
    if (!mounted) return;

    if (fromFileListener) {
      // don't refresh if we're not on the home page
      final location = GoRouterState.of(context).uri.toString();
      if (!location.startsWith(RoutePaths.prefixOfHome)) return;
    }

    children =
        BrowsePage.overrideChildren ??
        await FileManager.getChildrenOfDirectory(
          path ?? '/',
          sortMetric: stows.browseSortMetric.value,
        );
    // right after installing, the notes folder may not exist yet: that's
    // an empty desk (the welcome), not one still loading
    if (children == null && (path == null || path == '/')) {
      children = DirectoryChildren([], []);
    }

    if (mounted) setState(() {});
  }

  void onDirectoryTap(String folder) {
    selectedFiles.value = [];
    _allFolders = false;
    if (folder == '..') {
      path = p.dirname(path ?? '/');
      if (path == '/') path = null;
    } else {
      path = p.join(path ?? '/', folder);
    }
    context.go(HomeRoutes.browseFilePath(path ?? '/'));
    findChildrenOfPath();
  }

  void onPathComponentTap(String? newPath) {
    selectedFiles.value = [];
    _allFolders = false;
    if (newPath == null || newPath.isEmpty || newPath == '/') {
      newPath = null;
    }
    path = newPath;
    context.go(HomeRoutes.browseFilePath(path ?? '/'));
    findChildrenOfPath();
  }

  bool _doesFolderExist(String folderName) =>
      children?.directories.contains(folderName) ?? false;

  Future<void> createFolder(String folderName) async {
    final folderPath = '${path ?? ''}/$folderName';
    await FileManager.createFolder(folderPath);
    findChildrenOfPath();
  }

  void _setSort(bool byName) {
    final current = stows.browseSortMetric.value;
    final isName = current == .nameAToZ || current == .nameZToA;
    // choosing the current one again flips its direction
    stows.browseSortMetric.value = switch ((byName, isName)) {
      (true, false) => .nameAToZ,
      (true, true) => current == .nameAToZ ? .nameZToA : .nameAToZ,
      (false, true) => .lastModifiedNewToOld,
      (false, false) =>
        current == .lastModifiedNewToOld
            ? .lastModifiedOldToNew
            : .lastModifiedNewToOld,
    };
  }

  late final folderActions = FolderActions(
    onTap: onDirectoryTap,
    doesFolderExist: _doesFolderExist,
    rename: (String oldName, String newName) async {
      final oldPath = '${path ?? ''}/$oldName';
      await FileManager.renameDirectory(oldPath, newName);
      findChildrenOfPath();
    },
    isEmpty: (String folderName) async {
      final folderPath = '${path ?? ''}/$folderName';
      final children = await FileManager.getChildrenOfDirectory(folderPath);
      return children?.isEmpty ?? true;
    },
    delete: (String folderName) async {
      final folderPath = '${path ?? ''}/$folderName';
      await FileManager.deleteDirectory(folderPath);
      findChildrenOfPath();
    },
  );

  /// The actions for the folder that's open, from its parent's view.
  FolderActions get _openFolderActions {
    final parent = p.dirname(path!);
    return FolderActions(
      onTap: (_) {},
      doesFolderExist: (name) =>
          FileManager.isDirectory(p.join(parent, name)),
      rename: (oldName, newName) async {
        await FileManager.renameDirectory(path!, newName);
        onPathComponentTap(p.join(parent, newName));
      },
      isEmpty: (_) async {
        final children = await FileManager.getChildrenOfDirectory(path!);
        return children?.isEmpty ?? true;
      },
      delete: (_) async {
        await FileManager.deleteDirectory(path!);
        onPathComponentTap(parent);
      },
    );
  }

  List<String> get _visibleFiles => [
    for (final file in children?.files ?? const <String>[])
      if (!isHiddenName(file)) '${path ?? ''}/$file',
  ];

  List<String> get _visibleFolders => [
    for (final folder in children?.directories ?? const <String>[])
      if (!isHiddenName(folder)) folder,
  ];

  @override
  Widget build(BuildContext context) {
    useListenable(stows.homeLayout);
    useListenable(stows.homeCoverSize);
    final favorites = useValueListenable(stows.favoriteNotes);
    useEffect(() {
      NoteFactsCache.scan();
      return null;
    }, const []);
    final facts = useValueListenable(NoteFactsCache.facts);
    final tags = useValueListenable(NoteTags.book);
    useEffect(() {
      unawaited(NoteTags.load());
      return null;
    }, const []);
    // a deleted or renamed tag shows everything again
    final tag = tags.colors.containsKey(_tag) ? _tag : null;
    useOnListenableChange(stows.browseSortMetric, findChildrenOfPath);
    final colors = BadNotesColors.of(context);
    final isAtRoot = path == null || path!.isEmpty;
    final margin = HomeChrome.margin(context);
    final menu = NewDocumentMenu(
      path: path,
      createFolder: createFolder,
      doesFolderExist: _doesFolderExist,
    );
    HomeChrome.newMenu.value = menu;
    final selecting = selectedFiles.value.isNotEmpty;

    var files = _visibleFiles;
    var folders = _visibleFolders;
    if (_filter == .favorites) {
      files = [
        for (final file in files)
          if (favorites.contains(file)) file,
      ];
      folders = [
        for (final folder in folders)
          if (favorites.contains('${path ?? ''}/$folder')) folder,
      ];
    }
    if (tag != null) {
      files = [
        for (final file in files)
          if (tags.has(file, tag)) file,
      ];
    }
    if (_allFolders) folders = _sortedFolders(folders);
    final showFolders =
        _filter != .notebooks &&
        (folders.isNotEmpty || (isAtRoot && _filter != .favorites));
    final showNotebooks = _filter != .folders && !_allFolders;
    final empty =
        isAtRoot &&
        children != null &&
        _visibleFiles.isEmpty &&
        _visibleFolders.isEmpty;

    // back from "All folders" goes to the desk, not out of the app
    return PopScope(
      canPop: !_allFolders,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _allFolders = false);
      },
      child: Scaffold(
      backgroundColor: colors.desk,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  margin,
                  MediaQuery.paddingOf(context).top + (selecting ? 14 : 26),
                  margin,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  child: selecting
                      ? SelectionTopBar(
                          count: selectedFiles.value.length,
                          onCancel: () => selectedFiles.value = [],
                          onSelectAll: () => selectedFiles.value = files,
                        )
                      : const HomeHeader(),
                ),
              ),
              if (selecting)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: SizedBox(
                      height: 1,
                      child: ColoredBox(color: colors.hairline),
                    ),
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(margin, 0, margin, 0),
                sliver: SliverToBoxAdapter(
                  child: empty
                      ? const SizedBox()
                      : _title(context, isAtRoot, files, folders),
                ),
              ),
              if (empty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: margin),
                    child: EmptyDesk(
                      onCreate: () => menu.newNotebook(context),
                      onImport: () => menu.importDocument(context),
                      onTemplate: (i) => menu.newNotebook(
                        context,
                        template: DocumentTemplate.values[i],
                      ),
                    ),
                  ),
                )
              else if (children != null && _filter == .photos)
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: margin),
                  sliver: const PhotosGrid(),
                )
              else if (children != null)
                ..._sections(
                  context,
                  folders: folders,
                  // inside a folder, PDFs have a section of their own
                  files: isAtRoot
                      ? files
                      : [
                          for (final f in files)
                            if (!(facts[f]?.pdf ?? false)) f,
                        ],
                  pdfs: isAtRoot
                      ? const []
                      : [
                          for (final f in files)
                            if (facts[f]?.pdf ?? false) (f, facts[f]!.pages),
                        ],
                  isAtRoot: isAtRoot,
                  margin: margin,
                  menu: menu,
                  showFolders: showFolders,
                  showNotebooks: showNotebooks,
                ),
              SliverToBoxAdapter(
                child: SizedBox(height: HomeChrome.bottomRoom(context)),
              ),
            ],
          ),
          const SyncErrorBanner(),
          if (selecting)
            Positioned(
              left: 12,
              right: 12,
              bottom: MediaQuery.paddingOf(context).bottom + 18,
              child: Center(
                child: NotebookSelectionBar(selectedFiles: selectedFiles),
              ),
            ),
        ],
      ),
      ),
    );
  }

  List<String> _sortedFolders(List<String> folders) {
    final sorted = [...folders];
    FolderInfo? info(String f) => FolderInfos.of('${path ?? ''}/$f').value;
    switch (_folderSort) {
      case .name:
        sorted.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      case .recent:
        sorted.sort(
          (a, b) => (info(b)?.modified ?? DateTime(0)).compareTo(
            info(a)?.modified ?? DateTime(0),
          ),
        );
      case .size:
        sorted.sort((a, b) => (info(b)?.items ?? 0).compareTo(info(a)?.items ?? 0));
    }
    return sorted;
  }

  Widget _title(
    BuildContext context,
    bool isAtRoot,
    List<String> files,
    List<String> folders,
  ) {
    final colors = BadNotesColors.of(context);
    final phone = !HomeChrome.isWide(context);
    if (_allFolders) {
      final items = [
        for (final f in folders)
          FolderInfos.of('${path ?? ''}/$f').value?.items ?? 0,
      ].fold(0, (a, b) => a + b);
      return Padding(
        padding: const EdgeInsets.only(top: 30, bottom: 24),
        child: HomeTitle(
          leading: BnIconButton(
            icon: BnIcons.back,
            tooltip: 'Back',
            onPressed: () => setState(() => _allFolders = false),
          ),
          title: 'All folders',
          caption:
              '${folders.length} folder${folders.length == 1 ? '' : 's'}'
              ' · $items items',
          trailing: BnSegmented(
            expand: phone,
            segments: [
              for (final s in _FolderSort.values) BnSegment(s, s.label),
            ],
            selected: _folderSort,
            onChanged: (s) => setState(() => _folderSort = s),
          ),
        ),
      );
    }
    if (isAtRoot) {
      final newest = files.isEmpty
          ? null
          : files
                .map((f) => FileManager.lastModified(f + Editor.extension))
                .reduce((a, b) => a.isAfter(b) ? a : b);
      return Padding(
        padding: const EdgeInsets.only(top: 30, bottom: 26),
        child: HomeTitle(
          title: homeGreeting(),
          caption: _filter == .photos
              ? 'Photos from your notes and your board'
              : [
                  '${files.length} notebook${files.length == 1 ? '' : 's'}',
                  '${folders.length} folder${folders.length == 1 ? '' : 's'}',
                  if (newest != null) 'last edited ${homeAgo(newest)}',
                ].join(' · '),
          trailing: _filters(phone),
        ),
      );
    }

    // inside a folder: the way back, then the folder
    final parts = path!.split('/').where((s) => s.isNotEmpty).toList();
    final folderPath = path!;
    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              GestureDetector(
                onTap: () => onDirectoryTap('..'),
                child: Icon(BnIcons.back, size: 16, color: colors.accent),
              ),
              const SizedBox(width: 6),
              _crumb('Desk', () => onPathComponentTap(null), colors),
              for (int i = 0; i < parts.length; i++) ...[
                Text(
                  '  /  ',
                  style: BnType.body.copyWith(color: colors.faint),
                ),
                if (i == parts.length - 1)
                  Text(
                    parts[i],
                    style: BnType.body.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  _crumb(
                    parts[i],
                    () => onPathComponentTap('/${parts.take(i + 1).join('/')}'),
                    colors,
                  ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          HookBuilder(
            builder: (context) {
              final style = useValueListenable(FolderStyles.of(folderPath));
              final info = useValueListenable(FolderInfos.of(folderPath));
              final starred = useValueListenable(
                stows.favoriteNotes,
              ).contains(folderPath);
              return HomeTitle(
                leading: FolderGlyph(color: style.color),
                title: parts.last,
                caption: info == null
                    ? null
                    : [
                        info.summary,
                        if (info.modified != null)
                          'updated ${homeMeta(info.modified!).toLowerCase()}',
                      ].join(' · '),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [
                    BnButton(
                      label: starred ? 'Starred' : 'Star',
                      icon: starred ? Icons.star_rounded : BnIcons.favorites,
                      onPressed: () => Favorites.toggle(folderPath),
                    ),
                    Builder(
                      builder: (context) => BnButton.primary(
                        label: 'Add here',
                        icon: BnIcons.add,
                        onPressed: () => HomeChrome.newMenu.value.show(
                          context,
                          globalRect(context),
                        ),
                      ),
                    ),
                    Builder(
                      builder: (context) => _OutlinedIconButton(
                        icon: BnIcons.more,
                        tooltip: 'More',
                        onPressed: () => showFolderMenu(
                          context,
                          name: parts.last,
                          path: folderPath,
                          actions: _openFolderActions,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _crumb(String label, VoidCallback onTap, BadNotesColors colors) =>
      GestureDetector(
        onTap: onTap,
        child: Text(
          label,
          style: BnType.body.copyWith(
            color: colors.accent,
            fontWeight: FontWeight.w500,
          ),
        ),
      );

  Widget _filters(bool phone) => BnSegmented(
    expand: phone,
    segments: [for (final f in DeskFilter.values) BnSegment(f, f.label)],
    selected: _filter,
    onChanged: (f) => setState(() => _filter = f),
  );

  /// The folders and notebooks, with the quick notes board beside them on
  /// the desk (design M_Home), or across the top on narrower screens.
  List<Widget> _sections(
    BuildContext context, {
    required List<String> folders,
    required List<String> files,
    List<(String, int)> pdfs = const [],
    required bool isAtRoot,
    required double margin,
    required NewDocumentMenu menu,
    required bool showFolders,
    required bool showNotebooks,
  }) {
    final board = isAtRoot && !_allFolders && _filter == .all;
    final wide = HomeChrome.isWide(context);
    final right = board && wide ? 0.0 : margin;
    final main = [
      if (showFolders) _foldersSection(context, folders, isAtRoot, margin, right),
      if (showNotebooks)
        _notebooksSection(context, files, isAtRoot, margin, right, menu),
      if (showNotebooks && pdfs.isNotEmpty)
        SliverPadding(
          padding: EdgeInsets.fromLTRB(margin, 32, right, 0),
          sliver: SliverMainAxisGroup(
            slivers: [
              const SliverToBoxAdapter(child: BnSectionHeader(title: 'PDFs')),
              SliverGrid.builder(
                gridDelegate:
                    const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 420,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 60,
                    ),
                itemCount: pdfs.length,
                itemBuilder: (context, i) => _PdfCard(
                  path: pdfs[i].$1,
                  pages: pdfs[i].$2,
                ),
              ),
            ],
          ),
        ),
    ];
    if (!board) return main;
    if (!wide) {
      return [
        SliverPadding(
          padding: EdgeInsets.fromLTRB(margin, 0, margin, 28),
          sliver: const SliverToBoxAdapter(child: QuickNotesCard(strip: true)),
        ),
        ...main,
      ];
    }
    return [
      SliverCrossAxisGroup(
        slivers: [
          SliverCrossAxisExpanded(
            flex: 1,
            sliver: SliverMainAxisGroup(slivers: main),
          ),
          SliverConstrainedCrossAxis(
            maxExtent: 300 + 32 + margin,
            sliver: SliverPadding(
              padding: EdgeInsets.only(left: 32, right: margin),
              sliver: const SliverToBoxAdapter(child: QuickNotesCard()),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _foldersSection(
    BuildContext context,
    List<String> folders,
    bool isAtRoot,
    double margin,
    double right,
  ) {
    final onDesk = isAtRoot && !_allFolders && _filter != .folders;
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(margin, 0, right, 28),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          final columns = width >= 560 ? 5 : (width >= 380 ? 3 : 2);
          const gap = 16.0;
          // on the desk, one row and "See all"
          final shown = onDesk && folders.length > columns - 1
              ? folders.take(columns - 1).toList()
              : folders;
          final withNew = _filter != .favorites;
          final count = shown.length + (withNew ? 1 : 0);
          return SliverMainAxisGroup(
            slivers: [
              if (!_allFolders)
                SliverToBoxAdapter(
                  child: BnSectionHeader(
                    title: 'Folders',
                    action: onDesk && folders.isNotEmpty ? 'See all' : null,
                    onAction: () => setState(() => _allFolders = true),
                  ),
                ),
              SliverGrid.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: gap,
                  mainAxisSpacing: gap + 12,
                  mainAxisExtent: 104,
                ),
                itemCount: count,
                itemBuilder: (context, i) {
                  if (i == shown.length) {
                    return BnNewFolderTile(
                      label: t.home.newFolder.newFolder,
                      onTap: () => HomeChrome.newMenu.value.newFolder(context),
                    );
                  }
                  return DeskFolderTile(
                    key: ValueKey(shown[i]),
                    name: shown[i],
                    path: '${path ?? ''}/${shown[i]}',
                    actions: folderActions,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _notebooksSection(
    BuildContext context,
    List<String> files,
    bool isAtRoot,
    double margin,
    double right,
    NewDocumentMenu menu,
  ) {
    final sort = stows.browseSortMetric.value;
    final byName = sort == .nameAToZ || sort == .nameZToA;
    final colors = BadNotesColors.of(context);
    final header = BnSectionHeader(
      title: 'Notebooks',
      trailing: Builder(
        builder: (context) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showViewMenu(context, files),
          child: Row(
            children: [
              Text(
                byName ? 'Name' : 'Recent',
                style: BnType.caption.copyWith(
                  color: const Color(0xFF55555A),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(BnIcons.down, size: 14, color: colors.muted),
            ],
          ),
        ),
      ),
    );
    return SliverPadding(
      padding: EdgeInsets.only(left: margin, right: right),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(child: header),
          SliverToBoxAdapter(
            child: TagFilterRow(
              selected: _tag,
              onSelected: (tag) => setState(() => _tag = tag),
            ),
          ),
          DocumentGrid(
            files: files,
            selectedFiles: selectedFiles,
            onNew: isAtRoot ? null : () => menu.newNotebook(context),
          ),
        ],
      ),
    );
  }

  void _showViewMenu(BuildContext context, List<String> files) {
    final sort = stows.browseSortMetric.value;
    showViewOptions(
      context,
      anchor: rectOf(context),
      leading: [
        AppleMenuItem(
          'Select All',
          icon: BnIcons.selectCircle,
          onTap: () => selectedFiles.value = files,
        ),
      ],
      sort: [
        AppleMenuItem(
          'Last Modified',
          icon: sort == .lastModifiedOldToNew
              ? Icons.arrow_upward
              : Icons.arrow_downward,
          checked: sort != .nameAToZ && sort != .nameZToA,
          onTap: () => _setSort(false),
        ),
        AppleMenuItem(
          'Name',
          icon: sort == .nameZToA ? Icons.arrow_upward : Icons.arrow_downward,
          checked: sort == .nameAToZ || sort == .nameZToA,
          onTap: () => _setSort(true),
        ),
      ],
    );
  }


}

/// A 40 px white square button with a hairline, like the folder's "⋯".
class _OutlinedIconButton extends StatelessWidget {
  const _OutlinedIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(BnRadius.control)),
          side: BorderSide(color: colors.hairline),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: const BorderRadius.all(Radius.circular(BnRadius.control)),
          child: SizedBox.square(
            dimension: 40,
            child: Icon(icon, size: 18, color: colors.text2),
          ),
        ),
      ),
    );
  }
}


/// A PDF in a folder (design N15): a small PDF cover, its name and pages.
class _PdfCard extends StatelessWidget {
  const _PdfCard({required this.path, required this.pages});

  final String path;
  final int pages;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(BnRadius.card)),
        side: BorderSide(color: colors.hairline),
      ),
      child: InkWell(
        onTap: () => openNote(context, path),
        borderRadius: const BorderRadius.all(Radius.circular(BnRadius.card)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 40,
                alignment: Alignment.bottomCenter,
                padding: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: BnColors.blush,
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                ),
                child: Text(
                  'PDF',
                  style: BnType.micro.copyWith(
                    fontSize: 8,
                    color: BnColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      noteName(path),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BnType.body.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      pages == 1 ? '1 page' : '$pages pages',
                      style: BnType.caption.copyWith(color: colors.muted),
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
