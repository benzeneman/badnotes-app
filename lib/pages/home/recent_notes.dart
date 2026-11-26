import 'dart:async';

import 'package:badnotes/components/home/desk.dart';
import 'package:badnotes/components/home/folder_info.dart';
import 'package:badnotes/components/home/home_actions.dart';
import 'package:badnotes/components/home/home_shell.dart';
import 'package:badnotes/components/home/new_note_button.dart';
import 'package:badnotes/components/home/note_facts.dart';
import 'package:badnotes/components/home/page_tile.dart';
import 'package:badnotes/components/home/preview_card.dart';
import 'package:badnotes/components/home/revision_plan.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/data/locks.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/routes.dart';
import 'package:badnotes/pages/editor/editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';

class const RecentPage({super.key}) extends StatefulHookWidget {
  @override
  State<RecentPage> createState() => _RecentPageState();
}

class _RecentPageState extends State<RecentPage> {
  final List<String> filePaths = [];
  var failed = false;

  final ValueNotifier<List<String>> selectedFiles = ValueNotifier([]);

  final log = Logger('RecentPage');

  /// Mitigates a bug where files got imported starting with `null/` instead of `/`.
  ///
  /// This caused them to be written to `Documents/BadNotesnull/...` instead of `Documents/BadNotes/...`.
  void moveIncorrectlyImportedFiles() async {
    for (final filePath in stows.recentFiles.value) {
      if (filePath.startsWith('/')) continue;

      final String newFilePath;
      if (filePath.startsWith('null/')) {
        newFilePath = await FileManager.suffixFilePathToMakeItUnique(
          filePath.substring('null'.length),
        );
      } else {
        newFilePath = await FileManager.suffixFilePathToMakeItUnique(
          '/$filePath',
        );
      }

      log.warning(
        'Found incorrectly imported file at `$filePath`; moving to `$newFilePath`',
      );
      await FileManager.moveFile(filePath, newFilePath);
    }
  }

  @override
  void initState() {
    findRecentlyAccessedNotes();
    fileWriteSubscription = FileManager.fileWriteStream.stream.listen(
      fileWriteListener,
    );
    selectedFiles.addListener(_onSelection);

    super.initState();
    moveIncorrectlyImportedFiles();
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
    if (event.isNoteAsset) return;
    // once after a save's several writes, not once for each
    _refreshTimer?.cancel();
    _refreshTimer = Timer(
      const Duration(milliseconds: 250),
      () => findRecentlyAccessedNotes(fromFileListener: true),
    );
  }

  void _setState() => setState(() {});

  /// The dock makes way for the selection bar, as on the other tabs.
  void _onSelection() {
    HomeChrome.selecting.value = selectedFiles.value.isNotEmpty;
    _setState();
  }

  var _period = _Period.all;

  /// When each note was last changed, read once per refresh.
  final _edited = <String, DateTime>{};

  Future findRecentlyAccessedNotes({bool fromFileListener = false}) async {
    if (!mounted) return;

    if (fromFileListener) {
      // don't refresh if we're not on the home page
      final location = GoRouterState.of(context).uri.toString();
      if (!location.startsWith(RoutePaths.prefixOfHome)) return;
    }

    final children = await FileManager.getRecentlyAccessed();
    filePaths.clear();
    _edited.clear();
    if (children.isEmpty) {
      failed = true;
    } else {
      failed = false;
      for (final path in children) {
        // helper files like a folder's .style.json aren't notes
        if (!isVisiblePath(path)) continue;
        filePaths.add(path);
        _edited[path] = FileManager.lastModified(path + Editor.extension);
      }
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    useListenable(stows.homeLayout);
    final facts = useValueListenable(NoteFactsCache.facts);
    HomeChrome.newMenu.value = const NewDocumentMenu();
    final colors = BadNotesColors.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // newest first, grouped by day
    final shown = [
      for (final path in filePaths)
        if (_period.includes(_edited[path]!, now)) path,
    ]..sort((a, b) => _edited[b]!.compareTo(_edited[a]!));
    final groups = <String, List<String>>{};
    for (final path in shown) {
      final edited = _edited[path]!;
      final days = today
          .difference(DateTime(edited.year, edited.month, edited.day))
          .inDays;
      final group = switch (days) {
        <= 0 => 'Today',
        1 => 'Yesterday',
        < 7 => 'Earlier this week',
        < 31 => 'Earlier this month',
        _ => 'Older',
      };
      (groups[group] ??= []).add(path);
    }

    return HomePageFrame(
      title: 'Recent',
      caption: 'Everything you opened or edited lately',
      trailing: BnSegmented(
        expand: !HomeChrome.isWide(context),
        segments: [for (final p in _Period.values) BnSegment(p, p.label)],
        selected: _period,
        onChanged: (p) => setState(() => _period = p),
      ),
      selectedFiles: selectedFiles,
      selectable: shown,
      slivers: _withPagesCard(context, shown, [
        const SliverToBoxAdapter(child: RevisionDueCard()),
        if (shown.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Text(
                failed || filePaths.isEmpty
                    ? 'Notebooks you open will show here.'
                    : 'Nothing in this period.',
                textAlign: TextAlign.center,
                style: BnType.body.copyWith(color: colors.muted),
              ),
            ),
          ),
        for (final MapEntry(key: group, value: paths) in groups.entries) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 14, 0, 8),
              child: Text(
                group,
                style: BnType.caption.copyWith(
                  color: colors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          DecoratedSliver(
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.hairline),
              borderRadius: const BorderRadius.all(
                Radius.circular(BnRadius.card),
              ),
              boxShadow: BnShadows.card,
            ),
            sliver: SliverList.separated(
              itemCount: paths.length,
              separatorBuilder: (_, _) =>
                  SizedBox(height: 1, child: ColoredBox(color: colors.divider)),
              itemBuilder: (context, i) =>
                  _row(context, paths[i], today, facts[paths[i]]),
            ),
          ),
        ],
      ]),
    );
  }

  /// [main] with "Pages you were on" beside it on a wide screen: the pages
  /// the latest notes were left on.
  List<Widget> _withPagesCard(
    BuildContext context,
    List<String> shown,
    List<Widget> main,
  ) {
    if (!HomeChrome.isWide(context)) return main;
    return [
      SliverCrossAxisGroup(
        slivers: [
          SliverCrossAxisExpanded(
            flex: 1,
            sliver: SliverMainAxisGroup(slivers: main),
          ),
          SliverConstrainedCrossAxis(
            maxExtent: 332,
            sliver: SliverPadding(
              padding: const EdgeInsets.only(left: 32),
              sliver: SliverToBoxAdapter(child: _PagesYouWereOn(shown)),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _row(
    BuildContext context,
    String path,
    DateTime today,
    NoteFacts? facts,
  ) {
    final edited = _edited[path]!;
    final days = today
        .difference(DateTime(edited.year, edited.month, edited.day))
        .inDays;
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final when = switch (days) {
      <= 0 => homeTime(edited),
      1 => 'yesterday ${homeTime(edited)}',
      < 7 => weekdays[edited.weekday - 1],
      _ => homeShortDate(edited),
    };
    return RepaintBoundary(
      child: PreviewCard(
        filePath: path,
        asRow: true,
        selected: selectedFiles.value.contains(path),
        isAnythingSelected: selectedFiles.value.isNotEmpty,
        toggleSelection: (file, selected) {
          selectedFiles.value = selected
              ? [...selectedFiles.value, file]
              : ([...selectedFiles.value]..remove(file));
        },
        // the whole row opens the note; where it lives is a quiet label,
        // and ⋯ has the rest (design 8)
        rowCaption: [
          'Edited $when',
          if (facts != null && !facts.board) 'page ${facts.lastPage + 1}',
          _whereLabel(noteFolder(path)),
        ].join(' · '),
      ),
    );
  }
}

/// Which recent notes to show.
enum _Period {
  today('Today'),
  week('This week'),
  month('This month'),
  all('All');

  const _Period(this.label);

  final String label;

  bool includes(DateTime edited, DateTime now) => switch (this) {
    today =>
      edited.year == now.year &&
          edited.month == now.month &&
          edited.day == now.day,
    week => now.difference(edited).inDays < 7,
    month => now.difference(edited).inDays < 31,
    all => true,
  };
}

/// Where a note lives, for its caption: `/College/` → "College".
String _whereLabel(String folder) {
  if (folder == '/') return 'On the desk';
  final path = folder.substring(0, folder.length - 1);
  return path.substring(path.lastIndexOf('/') + 1);
}

class _PagesYouWereOn extends HookWidget {
  const _PagesYouWereOn(this.notes);

  final List<String> notes;

  @override
  Widget build(BuildContext context) {
    useEffect(() {
      NoteFactsCache.scan();
      return null;
    }, const []);
    final facts = useValueListenable(NoteFactsCache.facts);
    // a locked note's pages (or one in a locked folder) aren't shown
    useValueListenable(NoteLocks.book);
    final colors = BadNotesColors.of(context);
    final pages = [
      for (final path in notes)
        if (facts[path] case final f?
            when !f.board && !NoteLocks.isProtected(path))
          (path, f.lastPage),
    ].take(4).toList();
    if (pages.isEmpty) return const SizedBox();
    return BnCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pages you were on',
            style: BnType.section.copyWith(color: colors.text),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 14,
            crossAxisSpacing: 12,
            childAspectRatio: 0.78,
            children: [
              for (final (path, page) in pages)
                PageTile(
                  path: path,
                  page: page,
                  label: PageTile.short(path, page),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
