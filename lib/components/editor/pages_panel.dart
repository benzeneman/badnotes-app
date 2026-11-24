import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:badnotes/components/canvas/canvas_preview.dart';
import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/theming/badnotes_tokens.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/editor/editor_core_info.dart';

/// Every page of the note, in place of the note itself: tapping a page goes to
/// it and closes the panel.
class PagesPanel extends StatefulWidget {
  const PagesPanel({
    super.key,
    required this.coreInfo,
    required this.currentPage,
    this.revision,
    required this.goToPage,
    required this.toggleBookmark,
    required this.copyPages,
    required this.rotatePages,
    required this.exportPages,
    required this.trashPages,
    required this.openFullView,
    this.onClose,
    this.addPage,
    this.audio,
    this.showAudio = false,
    this.exportPick,
    this.onExportPickEnd,
  });

  /// Set (e.g. "PDF") when Share & Export's "Choose…" opened the panel: it
  /// opens picking pages, and its one button exports them in that format.
  final String? exportPick;

  /// Picking pages for [exportPick] ended, exported or not.
  final VoidCallback? onExportPickEnd;

  /// Opens on the Audio tab, as Recordings in the Insert menu does.
  final bool showAudio;

  /// Adds a page at the end, from the + after the last page.
  final VoidCallback? addPage;

  /// What's in the Audio tab, when the note can have recordings.
  final Widget? audio;

  final EditorCoreInfo coreInfo;
  final int currentPage;

  /// Ticks a moment after the writing changes: the pages are drawn again
  /// then. The thumbnail showed a line while it was being written, then
  /// lost it once the pen lifted.
  final ValueListenable<int>? revision;
  final ValueChanged<int> goToPage;
  final ValueChanged<int> toggleBookmark;

  /// These get page indices, highest first, so doing one doesn't shift the rest.
  final ValueChanged<List<int>> copyPages;
  final ValueChanged<List<int>> rotatePages;
  final ValueChanged<List<int>> exportPages;
  final ValueChanged<List<int>> trashPages;
  final VoidCallback openFullView;

  /// Closes the panel; none beside the note, where the Pages button does.
  final VoidCallback? onClose;

  /// The pages to show out of [bookmarked], one flag for each page.
  @visibleForTesting
  static List<int> shownPages(
    List<bool> bookmarked, {
    required bool onlySaved,
  }) => [
    for (int i = 0; i < bookmarked.length; i++)
      if (!onlySaved || bookmarked[i]) i,
  ];

  @override
  State<PagesPanel> createState() => _PagesPanelState();
}

class _PagesPanelState extends State<PagesPanel> {
  final _scroll = ScrollController();
  var _bookmarksOnly = false;

  /// Pages, Outline (the bookmarked pages, by name) or Audio.
  late var _tab = widget.showAudio && widget.audio != null ? 2 : 0;
  late var _selecting = widget.exportPick != null;
  final _selected = <int>{};

  List<int> get _shown => PagesPanel.shownPages([
    for (final page in widget.coreInfo.pages) page.bookmarked,
  ], onlySaved: _bookmarksOnly);

  List<int> get _selectedDescending =>
      _selected.toList()..sort((a, b) => b.compareTo(a));

  void _finishSelecting() {
    setState(() {
      _selecting = false;
      _selected.clear();
    });
    if (widget.exportPick != null) widget.onExportPickEnd?.call();
  }

  void _onSelected(ValueChanged<List<int>> action) {
    final pages = _selectedDescending;
    // first: an export picked from Share & Export reads its format then
    if (pages.isNotEmpty) action(pages);
    _finishSelecting();
  }

  @override
  void dispose() {
    widget.revision?.removeListener(_changed);
    _scroll.dispose();
    super.dispose();
  }

  /// A page's menu (design 21), from holding it.
  List<AppleMenuEntry> _pageActions(List<int> Function() pages, {int? one}) => [
    AppleMenuItem(
      'Duplicate',
      icon: Icons.copy_outlined,
      onTap: () => widget.copyPages(pages()),
    ),
    if (one != null)
      AppleMenuItem(
        widget.coreInfo.pages[one].bookmarked ? 'Remove bookmark' : 'Bookmark',
        icon: widget.coreInfo.pages[one].bookmarked
            ? Icons.bookmark_remove_outlined
            : Icons.bookmark_add_outlined,
        onTap: () => setState(() => widget.toggleBookmark(one)),
      ),
    AppleMenuItem(
      'Rotate',
      icon: Icons.rotate_right,
      onTap: () => widget.rotatePages(pages()),
    ),
    AppleMenuItem(
      'Export page',
      icon: Icons.ios_share,
      onTap: () => widget.exportPages(pages()),
    ),
    const AppleMenuDivider(),
    AppleMenuItem(
      'Delete',
      icon: Icons.delete_outline,
      destructive: true,
      onTap: () => widget.trashPages(pages()),
    ),
  ];

  Widget _buildHeader() {
    final colors = BadNotesColors.of(context);
    if (_selecting && widget.exportPick != null) {
      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pick pages for ${widget.exportPick}',
                  style: BnType.title.copyWith(color: colors.text),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_selected.length} selected · tap pages to pick',
                  style: BnType.caption.copyWith(color: colors.muted),
                ),
              ],
            ),
          ),
          BnButton(
            kind: BnButtonKind.quiet,
            height: 34,
            label: 'All',
            onPressed: () => setState(() => _selected.addAll(_shown)),
          ),
          BnButton(
            kind: BnButtonKind.quiet,
            height: 34,
            label: 'Cancel',
            onPressed: _finishSelecting,
          ),
        ],
      );
    }
    if (_selecting) {
      return Row(
        children: [
          BnButton(
            kind: BnButtonKind.quiet,
            height: 34,
            label: 'All',
            onPressed: () => setState(() => _selected.addAll(_shown)),
          ),
          Expanded(
            child: Text(
              '${_selected.length} selected',
              textAlign: TextAlign.center,
              style: BnType.title.copyWith(color: colors.text),
            ),
          ),
          BnButton(
            kind: BnButtonKind.quiet,
            height: 34,
            label: 'Done',
            onPressed: _finishSelecting,
          ),
        ],
      );
    }
    final count = widget.coreInfo.pages.length;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pages', style: BnType.title.copyWith(color: colors.text)),
              const SizedBox(height: 2),
              Text(
                '$count ${count == 1 ? 'page' : 'pages'} · on page '
                '${widget.currentPage + 1}',
                style: BnType.caption.copyWith(color: colors.muted),
              ),
            ],
          ),
        ),
        // in sight: it was only in the ⋯ menu, and people didn't find it
        BnButton(
          kind: BnButtonKind.quiet,
          height: 32,
          label: 'Select',
          onPressed: () => setState(() => _selecting = true),
        ),
        Builder(
          builder: (context) => BnIconButton(
            icon: Icons.more_horiz,
            size: 32,
            iconSize: 18,
            tooltip: 'Page options',
            color: colors.text2,
            onPressed: () => showAppleMenu(
              context,
              anchor: rectOf(context),
              entries: [
                AppleMenuItem(
                  'Open full view',
                  icon: Icons.open_in_full,
                  onTap: widget.openFullView,
                ),
              ],
            ),
          ),
        ),
        if (widget.onClose != null)
          BnIconButton(
            icon: BnIcons.close,
            size: 32,
            iconSize: 16,
            tooltip: 'Close',
            color: colors.text2,
            onPressed: widget.onClose,
          ),
      ],
    );
  }

  Widget _buildCell(int index) {
    final colors = BadNotesColors.of(context);
    final page = widget.coreInfo.pages[index];
    final picked = _selected.contains(index);
    final current = !_selecting && index == widget.currentPage;
    final ringed = picked || current;
    return RepaintBoundary(
      child: Builder(
        key: ValueKey(page),
        builder: (context) {
          void menu() {
            if (_selecting) return;
            showAppleMenu(
              context,
              anchor: rectOf(context),
              entries: _pageActions(() => [index], one: index),
            );
          }

          return Column(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_selecting) {
                      setState(() {
                        if (!_selected.remove(index)) _selected.add(index);
                      });
                    } else {
                      widget.goToPage(index);
                    }
                  },
                  onLongPress: menu,
                  onSecondaryTap: menu,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // A plain border instead of a blurred shadow, and the
                      // ink kept as an image the size of the thumbnail:
                      // scrolling through many pages redrew every stroke.
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: ringed ? colors.accent : colors.hairline,
                            width: ringed ? 2 : 1,
                          ),
                        ),
                        padding: EdgeInsets.all(ringed ? 1 : 2),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: IgnorePointer(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final pageSize = page.size;
                                final fit = [
                                  if (constraints.maxWidth.isFinite)
                                    constraints.maxWidth / pageSize.width,
                                  if (constraints.maxHeight.isFinite)
                                    constraints.maxHeight / pageSize.height,
                                ].fold(1.0, (a, b) => a < b ? a : b);
                                return FittedBox(
                                  child: CanvasPreview(
                                    // drawn again from the page as it is now
                                    key: ValueKey((
                                      page.strokes.length,
                                      page.images.length,
                                      widget.revision?.value,
                                    )),
                                    pageIndex: index,
                                    height: null,
                                    coreInfo: widget.coreInfo,
                                    pixelScale:
                                        fit *
                                        MediaQuery.devicePixelRatioOf(context),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      if (_selecting)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Icon(
                            picked
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 22,
                            color: picked ? colors.accent : colors.muted,
                          ),
                        )
                      else if (page.bookmarked)
                        // a ribbon on the page's corner
                        Positioned(
                          top: 0,
                          right: 12,
                          child: Semantics(
                            label: 'Bookmarked',
                            child: CustomPaint(
                              size: const Size(12, 16),
                              painter: _Ribbon(colors.accent),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 18,
                child: Text(
                  '${index + 1}',
                  style: BnType.caption.copyWith(
                    color: current ? colors.accentStrong : colors.muted,
                    fontWeight: current ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Under the last page: a slim button to add one. A tile the size of a
  /// page looked out of place.
  Widget _buildAddTile() {
    final colors = BadNotesColors.of(context);
    return Material(
      color: colors.accentTint,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: widget.addPage,
        child: SizedBox(
          height: 42,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 6,
            children: [
              Icon(Icons.add, size: 18, color: colors.accentStrong),
              Text(
                'Add page',
                style: BnType.body.copyWith(
                  color: colors.accentStrong,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onTap) {
    final enabled = _selected.isNotEmpty;
    final colorScheme = ColorScheme.of(context);
    final tint = enabled ? colorScheme.primary : colorScheme.onSurfaceVariant;
    return Expanded(
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            spacing: 2,
            children: [
              Icon(icon, size: 20, color: tint),
              Text(
                label,
                style: TextTheme.of(context).labelSmall?.copyWith(color: tint),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    widget.revision?.addListener(_changed);
  }

  @override
  void didUpdateWidget(PagesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Choose… again while the panel is open
    if (widget.exportPick != null && oldWidget.exportPick != widget.exportPick) {
      _selecting = true;
      _selected.clear();
    }
    if (oldWidget.revision != widget.revision) {
      oldWidget.revision?.removeListener(_changed);
      widget.revision?.addListener(_changed);
    }
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final colors = BadNotesColors.of(context);
    final shown = _shown;
    _selected.removeWhere((i) => i >= widget.coreInfo.pages.length);
    return Material(
      color: colors.surface,
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          // below the status bar: the panel goes up to the top of the
          // screen, and its title was under the clock
          SafeArea(
            bottom: false,
            right: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 10, 12),
              child: _buildHeader(),
            ),
          ),
          if (!_selecting)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              // words, not icons; Bookmarked is the filter
              child: BnSegmented<int>(
                height: 34,
                segments: [
                  const BnSegment(0, 'Pages'),
                  // short enough to show whole beside the others
                  const BnSegment(1, 'Marked'),
                  if (widget.audio != null) const BnSegment(2, 'Audio'),
                ],
                selected: _tab,
                onChanged: (tab) => setState(() {
                  _tab = tab;
                  _bookmarksOnly = tab == 1;
                }),
              ),
            ),
          if (_tab == 2 && !_selecting)
            Expanded(child: widget.audio!)
          else
            Expanded(
              child: shown.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Hold a page and choose Bookmark to see it here',
                          textAlign: TextAlign.center,
                          style: BnType.caption.copyWith(color: colors.muted),
                        ),
                      ),
                    )
                  // the bar at the side can be dragged, for long notes
                  : Scrollbar(
                      controller: _scroll,
                      thumbVisibility: true,
                      interactive: true,
                      thickness: 6,
                      radius: const Radius.circular(3),
                      child: CustomScrollView(
                        controller: _scroll,
                        // rows a little way off are built before they show
                        cacheExtent: 600,
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 18, 12),
                            // two columns in the sidebar, more on a wide one
                            sliver: SliverGrid.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 170,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 14,
                                    childAspectRatio: 0.66,
                                  ),
                              itemCount: shown.length,
                              itemBuilder: (context, i) => _buildCell(shown[i]),
                            ),
                          ),
                          if (widget.addPage != null &&
                              !_selecting &&
                              !_bookmarksOnly)
                            SliverPadding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 18, 16),
                              sliver: SliverToBoxAdapter(
                                child: _buildAddTile(),
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
          if (_selecting && widget.exportPick != null)
            Material(
              color: colorScheme.surface,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: BnButton.primary(
                    label: _selected.isEmpty
                        ? 'Pick pages to export'
                        : 'Export ${_selected.length} '
                              '${_selected.length == 1 ? 'page' : 'pages'} '
                              'as ${widget.exportPick}',
                    expand: true,
                    onPressed: _selected.isEmpty
                        ? null
                        : () => _onSelected(widget.exportPages),
                  ),
                ),
              ),
            )
          else if (_selecting)
            Material(
              color: colorScheme.surface,
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    _action(
                      Icons.copy_outlined,
                      'Copy',
                      () => _onSelected(widget.copyPages),
                    ),
                    _action(
                      Icons.rotate_right,
                      'Rotate',
                      () => _onSelected(widget.rotatePages),
                    ),
                    _action(
                      Icons.ios_share,
                      'Export',
                      () => _onSelected(widget.exportPages),
                    ),
                    Expanded(
                      child: Builder(
                        builder: (context) {
                          final enabled = _selected.isNotEmpty;
                          final tint = enabled
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant;
                          return InkWell(
                            onTap: enabled
                                ? () => showAppleMenu(
                                    context,
                                    anchor: rectOf(context),
                                    entries: [
                                      AppleMenuItem(
                                        'Move to trash',
                                        icon: Icons.delete_outline,
                                        destructive: true,
                                        onTap: () =>
                                            _onSelected(widget.trashPages),
                                      ),
                                    ],
                                  )
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                spacing: 2,
                                children: [
                                  Icon(Icons.more_horiz, size: 20, color: tint),
                                  Text(
                                    'More',
                                    style: TextTheme.of(context).labelSmall
                                        ?.copyWith(color: tint),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A bookmark ribbon on a page's corner.
class _Ribbon extends CustomPainter {
  const _Ribbon(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
    Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width / 2, size.height * 0.72)
      ..lineTo(0, size.height)
      ..close(),
    Paint()..color = color,
  );

  @override
  bool shouldRepaint(_Ribbon oldDelegate) => color != oldDelegate.color;
}
