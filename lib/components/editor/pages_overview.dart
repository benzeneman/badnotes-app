import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:badnotes/components/canvas/canvas_preview.dart';
import 'package:badnotes/components/home/documents_widgets.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/data/editor/editor_core_info.dart';
import 'package:badnotes/data/editor/page.dart';
import 'package:badnotes/components/ui/ui.dart';

/// Every page of a note at a glance. Tapping one goes there, and selecting
/// pages lets them be copied, moved, cleared or deleted.
Future<void> showPagesOverview(
  BuildContext context, {
  required EditorCoreInfo coreInfo,
  required int currentPageIndex,
  required ValueChanged<int> goToPage,
  required Future<Object?> Function(int) insertPageAfter,
  required ValueChanged<int> duplicatePage,
  required ValueChanged<int> clearPage,
  required ValueChanged<int> deletePage,
  required VoidCallback redrawAndSave,
  required ValueChanged<List<EditorPage>> setPageOrder,
  required ValueChanged<EditorPage> restorePage,
  required ValueChanged<EditorPage> deletePageForever,
}) => showAppleDialog<void>(
  context: context,
  builder: (context) => _PagesOverview(
    coreInfo: coreInfo,
    currentPageIndex: currentPageIndex,
    goToPage: goToPage,
    insertPageAfter: insertPageAfter,
    duplicatePage: duplicatePage,
    clearPage: clearPage,
    deletePage: deletePage,
    redrawAndSave: redrawAndSave,
    setPageOrder: setPageOrder,
    restorePage: restorePage,
    deletePageForever: deletePageForever,
  ),
);

class _PagesOverview extends StatefulWidget {
  const _PagesOverview({
    required this.coreInfo,
    required this.currentPageIndex,
    required this.goToPage,
    required this.insertPageAfter,
    required this.duplicatePage,
    required this.clearPage,
    required this.deletePage,
    required this.redrawAndSave,
    required this.setPageOrder,
    required this.restorePage,
    required this.deletePageForever,
  });

  final EditorCoreInfo coreInfo;
  final int currentPageIndex;
  final ValueChanged<int> goToPage;
  final Future<Object?> Function(int) insertPageAfter;
  final ValueChanged<int> duplicatePage;
  final ValueChanged<int> clearPage;
  final ValueChanged<int> deletePage;
  final VoidCallback redrawAndSave;
  final ValueChanged<List<EditorPage>> setPageOrder;
  final ValueChanged<EditorPage> restorePage;
  final ValueChanged<EditorPage> deletePageForever;

  @override
  State<_PagesOverview> createState() => _PagesOverviewState();
}

class _PagesOverviewState extends State<_PagesOverview> {
  /// Pages, bookmarks or trash.
  var _tab = 0;
  bool get _bookmarksOnly => _tab == 1;
  bool get _inTrash => _tab == 2;
  var _selecting = false;
  final _selected = <int>{};

  List<int> get _shown => [
    for (int i = 0; i < widget.coreInfo.pages.length; i++)
      if (!_bookmarksOnly || widget.coreInfo.pages[i].bookmarked) i,
  ];

  /// Highest first, so doing one doesn't shift the others.
  List<int> get _selectedDescending =>
      _selected.toList()..sort((a, b) => b.compareTo(a));

  void _finishSelecting() => setState(() {
    _selecting = false;
    _selected.clear();
  });

  void _forEachSelected(ValueChanged<int> action) {
    _selectedDescending.forEach(action);
    _finishSelecting();
  }

  Future<void> _moveSelected() async {
    final total = widget.coreInfo.pages.length;
    var typed = '';
    final target = await showAppleDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move to page'),
        content: TextField(
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: '1 - $total'),
          onChanged: (value) => typed = value,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, int.tryParse(typed)),
            child: const Text('Move'),
          ),
        ],
      ),
    );
    if (target == null || !mounted) return;

    final pages = widget.coreInfo.pages.toList();
    final ascending = _selected.toList()..sort();
    final moving = [for (final i in ascending) pages[i]];
    for (final i in ascending.reversed) {
      pages.removeAt(i);
    }
    pages.insertAll((target - 1).clamp(0, pages.length), moving);
    widget.setPageOrder(pages);
    _finishSelecting();
  }

  /// Puts the page at [from] where the page at [to] is.
  void _movePage(int from, int to) {
    final pages = widget.coreInfo.pages.toList();
    HapticFeedback.selectionClick();
    pages.insert(to, pages.removeAt(from));
    widget.setPageOrder(pages);
    setState(() {});
  }

  Widget _buildTrash() {
    final trash = widget.coreInfo.trash;
    if (trash.isEmpty) {
      return Center(
        child: Text(
          'Pages you remove wait here',
          style: TextTheme.of(context).bodySmall,
        ),
      );
    }
    final view = widget.coreInfo.copyWith(pages: trash);
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 170,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.58,
      ),
      itemCount: trash.length,
      itemBuilder: (context, i) => RepaintBoundary(
        child: Column(
          key: ValueKey(trash[i]),
          children: [
            Expanded(
              child: IgnorePointer(
                child: Center(
                  child: FittedBox(
                    child: CanvasPreview(
                      pageIndex: i,
                      height: null,
                      coreInfo: view,
                    ),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: .spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    widget.restorePage(trash[i]);
                    setState(() {});
                  },
                  child: const Text('Put back'),
                ),
                IconButton(
                  tooltip: 'Delete for good',
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  onPressed: () async {
                    final page = trash[i];
                    final ok = await showAppleDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete this page for good?'),
                        content: const Text("This can't be undone."),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (ok != true || !mounted) return;
                    widget.deletePageForever(page);
                    setState(() {});
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _action(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    final enabled = _selected.isNotEmpty;
    final tint = enabled
        ? (color ?? ColorScheme.of(context).primary)
        : ColorScheme.of(context).onSurfaceVariant;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Icon(icon, color: tint),
              const SizedBox(height: 3),
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
  Widget build(BuildContext context) {
    final shown = _shown;
    final primary = ColorScheme.of(context).primary;
    return Dialog(
      insetPadding: const EdgeInsets.all(12),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: .centerLeft,
                      child: TextButton(
                        onPressed: _selecting
                            ? () => setState(() {
                                _selected.addAll(_shown);
                              })
                            : () => Navigator.pop(context),
                        child: Text(_selecting ? 'Select all' : 'Close'),
                      ),
                    ),
                  ),
                  if (_selecting)
                    Text(
                      '${_selected.length} selected',
                      style: TextTheme.of(context).titleSmall,
                    )
                  else
                    SlidingSegments<int>(
                      width: 76,
                      segments: const {0: 'Pages', 1: 'Saved', 2: 'Trash'},
                      selected: _tab,
                      onChanged: (value) => setState(() => _tab = value),
                    ),
                  Expanded(
                    child: Align(
                      alignment: .centerRight,
                      child: TextButton(
                        onPressed: _inTrash
                            ? null
                            : _selecting
                            ? _finishSelecting
                            : () => setState(() => _selecting = true),
                        child: Text(_selecting ? 'Done' : 'Select'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSize(
              duration: BnMotion.normal,
              curve: BnMotion.curve,
              child: _selecting
                  ? Row(
                      children: [
                        _action(Icons.copy_outlined, 'Copy', () {
                          _forEachSelected(widget.duplicatePage);
                        }),
                        _action(Icons.drive_file_move_outline, 'Move', _moveSelected),
                        _action(Icons.cleaning_services_outlined, 'Clear', () {
                          _forEachSelected(widget.clearPage);
                        }),
                        _action(Icons.delete_outline, 'Trash', () {
                          _forEachSelected(widget.deletePage);
                        }, color: Colors.red),
                      ],
                    )
                  : const SizedBox(width: double.infinity),
            ),
            const Divider(),
            Expanded(
              child: _inTrash
                  ? _buildTrash()
                  : shown.isEmpty
                  ? Center(
                      child: Text(
                        'No bookmarked pages',
                        style: TextTheme.of(context).bodySmall,
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 170,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.62,
                          ),
                      itemCount: shown.length + 1,
                      itemBuilder: (context, i) {
                        if (i == shown.length) {
                          return Pressable(
                            onTap: () async {
                              await widget.insertPageAfter(
                                widget.coreInfo.pages.length - 1,
                              );
                              if (mounted) setState(() {});
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 26),
                              child: DashedRect(
                                child: Center(
                                  child: Icon(Icons.add, color: primary),
                                ),
                              ),
                            ),
                          );
                        }
                        final index = shown[i];
                        Widget cell({VoidCallback? onLongPress}) => _PageCell(
                          key: ValueKey(widget.coreInfo.pages[index]),
                          coreInfo: widget.coreInfo,
                          pageIndex: index,
                          isCurrent: index == widget.currentPageIndex,
                          selected: _selected.contains(index),
                          onToggleBookmark: () {
                            final page = widget.coreInfo.pages[index];
                            setState(() => page.bookmarked = !page.bookmarked);
                            widget.redrawAndSave();
                          },
                          onLongPress: onLongPress,
                          onTap: () {
                            if (_selecting) {
                              setState(() {
                                if (!_selected.remove(index)) {
                                  _selected.add(index);
                                }
                              });
                            } else {
                              Navigator.pop(context);
                              widget.goToPage(index);
                            }
                          },
                        );
                        if (_selecting || _bookmarksOnly) {
                          return RepaintBoundary(
                            child: cell(
                              onLongPress: () => setState(() {
                                _selecting = true;
                                _selected.add(index);
                              }),
                            ),
                          );
                        }
                        // hold to pick a page up, and drop it on another to move
                        // it there. Let go anywhere else and it's selected.
                        return RepaintBoundary(
                          child: DragTarget<int>(
                            onWillAcceptWithDetails: (details) =>
                                details.data != index,
                            onAcceptWithDetails: (details) =>
                                _movePage(details.data, index),
                            builder: (context, candidates, _) => LayoutBuilder(
                              builder: (context, constraints) => AnimatedScale(
                                scale: candidates.isEmpty ? 1 : 0.92,
                                duration: BnMotion.fast,
                                curve: BnMotion.curve,
                                child: LongPressDraggable<int>(
                                  data: index,
                                  delay: const Duration(milliseconds: 280),
                                  onDragStarted: HapticFeedback.mediumImpact,
                                  onDragEnd: (details) {
                                    if (details.wasAccepted || !mounted) return;
                                    setState(() {
                                      _selecting = true;
                                      _selected.add(index);
                                    });
                                  },
                                  feedback: Material(
                                    type: MaterialType.transparency,
                                    child: Transform.scale(
                                      scale: 1.06,
                                      child: SizedBox.fromSize(
                                        size: constraints.biggest,
                                        child: cell(),
                                      ),
                                    ),
                                  ),
                                  childWhenDragging: Opacity(
                                    opacity: 0.3,
                                    child: cell(),
                                  ),
                                  child: cell(),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageCell extends StatelessWidget {
  const _PageCell({
    super.key,
    required this.coreInfo,
    required this.pageIndex,
    required this.isCurrent,
    required this.selected,
    required this.onToggleBookmark,
    this.onLongPress,
    required this.onTap,
  });

  final EditorCoreInfo coreInfo;
  final int pageIndex;
  final bool isCurrent;
  final bool selected;
  final VoidCallback onToggleBookmark;
  final VoidCallback? onLongPress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final bookmarked = coreInfo.pages[pageIndex].bookmarked;
    return Column(
      children: [
        Expanded(
          child: Pressable(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Center(
              child: AnimatedContainer(
                duration: BnMotion.fast,
                curve: BnMotion.curve,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: selected || isCurrent
                        ? colorScheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                  // a hard 1px edge: a blurred one on every page was blurred
                  // again on each frame of a scroll or a selection
                  boxShadow: [
                    BoxShadow(
                      color: BadNotesColors.of(context).pageShadow,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                // pages draw their own content: they don't take taps here
                child: IgnorePointer(
                  child: FittedBox(
                    child: CanvasPreview(
                      pageIndex: pageIndex,
                      height: null,
                      coreInfo: coreInfo,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 26,
          child: Row(
            children: [
              Text(
                '${pageIndex + 1}',
                style: TextTheme.of(context).labelMedium,
              ),
              const Spacer(),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onToggleBookmark,
                child: Padding(
                  padding: const EdgeInsets.only(left: 12, top: 4),
                  child: Icon(
                    bookmarked ? Icons.bookmark : Icons.bookmark_border,
                    size: 18,
                    color: bookmarked
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
