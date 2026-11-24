import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:badnotes/components/canvas/canvas_gesture_detector.dart';
import 'package:badnotes/components/canvas/canvas_preview.dart';
import 'package:badnotes/components/theming/adaptive_icon.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/data/editor/editor_core_info.dart';
import 'package:badnotes/i18n/strings.g.dart';

/// A list of every page in the note, each with a thumbnail and buttons to
/// add, copy, clear or remove it. Pages can be dragged by their handle to
/// change their order, and tapping a page jumps the canvas to it.
///
/// The editor also keeps one of these around just to reach the page
/// callbacks it was given.
class const EditorPageManager({
  super.key,
  required final EditorCoreInfo coreInfo,
  required final int? currentPageIndex,
  required final VoidCallback redrawAndSave,
  required final void Function(int) insertPageAfter,
  required final void Function(int) duplicatePage,
  required final void Function(int) clearPage,
  required final void Function(int) deletePage,
  required final TransformationController transformationController,
}) extends StatefulWidget {
  @override
  State<EditorPageManager> createState() => _PageListState();
}

class _PageListState extends State<EditorPageManager> {
  void _goTo(int index) => CanvasGestureDetector.scrollToPage(
    pageIndex: index,
    pages: widget.coreInfo.pages,
    screenWidth: MediaQuery.sizeOf(context).width,
    transformationController: widget.transformationController,
  );

  /// Runs [change] on page [index], then shows page [thenShow].
  VoidCallback _changeThenShow(
    void Function(int) change,
    int index,
    int thenShow,
  ) =>
      () => setState(() {
        change(index);
        _goTo(thenShow);
      });

  /// Moves a page and renumbers everything on every page to match.
  void _move(int from, int to) {
    if (from == to) return;
    final pages = widget.coreInfo.pages;
    final moved = pages.removeAt(from);
    pages.insert(to, moved);
    for (var i = 0; i < pages.length; i++) {
      pages[i].updatePageIndex(i);
    }
    widget.redrawAndSave();
  }

  @override
  Widget build(BuildContext context) {
    final apple = Theme.of(context).platform.isCupertino;
    return SizedBox(
      width: apple ? null : 300,
      height: apple ? 600 : null,
      child: ReorderableListView.builder(
        buildDefaultDragHandles: false,
        itemCount: widget.coreInfo.pages.length,
        itemBuilder: (context, index) => _pageTile(index, apple),
        onReorderItem: _move,
      ),
    );
  }

  Widget _pageTile(int index, bool apple) {
    final pages = widget.coreInfo.pages;
    final total = pages.length;
    // The blank page kept at the end can't be cleared or deleted.
    final lockedBlank = index == total - 1 && pages[index].isEmpty;

    final header = Row(
      mainAxisAlignment: .spaceAround,
      children: [
        Text('${index + 1} / $total'),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: apple ? 100 : 150,
            maxHeight: 250,
          ),
          child: FittedBox(
            child: CanvasPreview(
              pageIndex: index,
              height: null,
              coreInfo: widget.coreInfo,
            ),
          ),
        ),
        MouseRegion(
          cursor: SystemMouseCursors.resizeUpDown,
          child: ReorderableDragStartListener(
            index: index,
            child: const Padding(
              padding: .all(8),
              child: Icon(Icons.drag_handle),
            ),
          ),
        ),
      ],
    );

    final buttons = Row(
      mainAxisAlignment: .center,
      children: [
        IconButton(
          tooltip: t.editor.menu.insertPage,
          icon: const AdaptiveIcon(
            icon: Icons.insert_page_break,
            cupertinoIcon: CupertinoIcons.add,
          ),
          onPressed: _changeThenShow(widget.insertPageAfter, index, index + 1),
        ),
        IconButton(
          tooltip: t.editor.menu.duplicatePage,
          icon: const AdaptiveIcon(
            icon: Icons.content_copy,
            cupertinoIcon: CupertinoIcons.doc_on_clipboard,
          ),
          onPressed: _changeThenShow(widget.duplicatePage, index, index + 1),
        ),
        IconButton(
          tooltip: t.editor.menu.clearPage(page: index + 1, totalPages: total),
          icon: const Icon(Icons.cleaning_services),
          onPressed: lockedBlank
              ? null
              : _changeThenShow(widget.clearPage, index, index),
        ),
        IconButton(
          tooltip: t.editor.menu.deletePage,
          icon: const AdaptiveIcon(
            icon: Icons.delete,
            cupertinoIcon: CupertinoIcons.delete,
          ),
          onPressed: lockedBlank
              ? null
              : _changeThenShow(widget.deletePage, index, index),
        ),
      ],
    );

    return InkWell(
      key: ValueKey(index),
      onTap: () => _goTo(index),
      child: Padding(
        padding: const .all(8),
        child: Column(children: [header, buttons]),
      ),
    );
  }
}
