import 'package:badnotes/components/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:badnotes/components/editor/note_split_view.dart';
import 'package:badnotes/components/home/cover_designs.dart';
import 'package:badnotes/components/home/notebook_cover.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/pages/editor/editor.dart';

/// Another note open beside the main one, to read and write on.
class NoteSplit {
  const NoteSplit(this.path, this.axis, {this.paneFirst = false});

  final String path;
  final Axis axis;

  /// Whether it goes left of or above the main note.
  final bool paneFirst;
}

/// The notes open as tabs, for as long as the app is running.
class NoteTabs {
  /// The note beside the main one. Stays until the user closes it, also while
  /// switching tabs or leaving to pick another note.
  static final split = ValueNotifier<NoteSplit?>(null);

  /// A second view of the main note, which also stays when switching tabs.
  static ({Axis axis, bool paneFirst})? ownView;

  /// Saves the note beside the main one, before its editor goes away.
  static Future<void> Function()? savePane;

  static Future<void> openBeside(NoteSplit next) async {
    await savePane?.call();
    if (!paths.value.contains(next.path)) {
      paths.value = [...paths.value, next.path];
    }
    split.value = next;
  }

  static Future<void> closePane() async {
    await savePane?.call();
    split.value = null;
  }

  static final paths = ValueNotifier<List<String>>(const []);
  static final active = ValueNotifier<String?>(null);

  /// A note for [TabbedEditor] to switch to.
  static final requested = ValueNotifier<String?>(null);

  static void open(String path) {
    if (!paths.value.contains(path)) paths.value = [...paths.value, path];
    active.value = path;
  }

  static void rename(String from, String to) {
    paths.value = [for (final path in paths.value) path == from ? to : path];
    if (active.value == from) active.value = to;
    final beside = split.value;
    if (beside != null && beside.path == from) {
      split.value = NoteSplit(to, beside.axis, paneFirst: beside.paneFirst);
    }
  }
}

/// The editor of the current tab. Switching tabs swaps the editor here, so it
/// works the same however the editor's page was opened.
class TabbedEditor extends StatefulWidget {
  const TabbedEditor({super.key, this.path, this.pdfPath});

  final String? path;
  final String? pdfPath;

  @override
  State<TabbedEditor> createState() => _TabbedEditorState();
}

class _TabbedEditorState extends State<TabbedEditor> {
  late String? _path = widget.path;
  late String? _pdfPath = widget.pdfPath;
  var _switches = 0;

  var _paneKey = GlobalKey<EditorState>();
  String? _panePath;

  Future<void> _savePane() async => await _paneKey.currentState?.saveToFile();

  Future<void> _onRequest() async {
    final path = NoteTabs.requested.value;
    if (path == null || !(ModalRoute.of(context)?.isCurrent ?? true)) return;
    NoteTabs.requested.value = null;
    // a note can't be open twice: the two swap places
    final beside = NoteTabs.split.value;
    final main = NoteTabs.active.value ?? _path;
    if (beside != null && beside.path == path && main != null) {
      await _savePane();
      if (!mounted) return;
      NoteTabs.split.value = NoteSplit(
        main,
        beside.axis,
        paneFirst: beside.paneFirst,
      );
    }
    setState(() {
      _path = path;
      _pdfPath = null;
      _switches++;
    });
  }

  @override
  void initState() {
    super.initState();
    NoteTabs.requested.addListener(_onRequest);
    NoteTabs.savePane = _savePane;
  }

  @override
  void dispose() {
    NoteTabs.requested.removeListener(_onRequest);
    if (NoteTabs.savePane == _savePane) NoteTabs.savePane = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: NoteTabs.split,
    builder: (context, split, _) {
      if (split?.path != _panePath) {
        _panePath = split?.path;
        _paneKey = GlobalKey<EditorState>();
      }
      return ResizableSplit(
        axis: split?.axis ?? Axis.horizontal,
        paneFirst: split?.paneFirst ?? false,
        // another tab: the note fades over the last one instead of the
        // page going blank while it loads
        main: AnimatedSwitcher(
          duration: BnMotion.normal,
          switchInCurve: BnMotion.curve,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (current, previous) =>
              Stack(fit: StackFit.expand, children: [...previous, ?current]),
          child: Editor(
            key: ValueKey(_switches),
            path: _path,
            pdfPath: _pdfPath,
          ),
        ),
        pane: split == null
            ? null
            : Editor(
                key: _paneKey,
                path: split.path,
                customTitle: p.basename(split.path),
                onClosePane: NoteTabs.closePane,
              ),
        onSwitch: () {
          if (split == null) return;
          NoteTabs.split.value = NoteSplit(
            split.path,
            split.axis,
            paneFirst: !split.paneFirst,
          );
        },
        onFlip: () {
          if (split == null) return;
          NoteTabs.split.value = NoteSplit(
            split.path,
            split.axis == Axis.horizontal ? Axis.vertical : Axis.horizontal,
            paneFirst: split.paneFirst,
          );
        },
        onClose: NoteTabs.closePane,
      );
    },
  );
}

/// Switching and closing open notes, for the tab strip and the switcher.
abstract final class NoteTabActions {
  static Future<void> switchTo(
    String path,
    Future<void> Function() beforeSwitching,
  ) async {
    if (path == NoteTabs.active.value) return;
    await beforeSwitching();
    NoteTabs.requested.value = path;
  }

  static Future<void> close(
    BuildContext context,
    String path,
    Future<void> Function() beforeSwitching,
  ) async {
    final tabs = NoteTabs.paths.value;
    final isActive = path == NoteTabs.active.value;
    final index = tabs.indexOf(path);
    final remaining = [...tabs]..remove(path);
    if (path == NoteTabs.split.value?.path) await NoteTabs.closePane();
    if (!isActive) {
      NoteTabs.paths.value = remaining;
    } else if (remaining.isEmpty) {
      NoteTabs.paths.value = remaining;
      if (context.mounted) await Navigator.maybePop(context);
    } else {
      await switchTo(
        remaining[index.clamp(0, remaining.length - 1)],
        beforeSwitching,
      );
      NoteTabs.paths.value = remaining;
    }
  }

  /// The open note before or after this one, by [step].
  static Future<void> step(int step, Future<void> Function() beforeSwitching) {
    final tabs = NoteTabs.paths.value;
    final at = tabs.indexOf(NoteTabs.active.value ?? '');
    if (at < 0 || tabs.length < 2) return Future.value();
    return switchTo(tabs[(at + step) % tabs.length], beforeSwitching);
  }
}

/// A note's cover, small, as a mark beside its name; a plain page if it has
/// none.
class NoteMark extends StatelessWidget {
  const NoteMark(this.path, {super.key, this.width = 14});

  final String path;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final cover = _coverOf(path);
    return Container(
      width: width,
      height: width * 1.3,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: colors.hairline),
      ),
      child: cover == null ? null : NotebookCover(design: cover, title: ''),
    );
  }
}

/// [path]'s cover; none for a note not saved anywhere yet (no path).
CoverDesign? _coverOf(String path) =>
    path.startsWith('/') ? NotebookCovers.read(path) : null;

/// The open notes as tabs in the header on a tablet, the open one shaded,
/// with + to open another. Always shown, one note open too.
class NoteTabsBar extends StatelessWidget {
  const NoteTabsBar({
    super.key,
    required this.beforeSwitching,
    this.activeTitle,
  });

  static const height = 38.0;

  /// In the open note's tab instead of its name: the field to rename it.
  final Widget? activeTitle;

  /// Saves the current note, so its tab shows the latest when coming back.
  final Future<void> Function() beforeSwitching;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    // The tabs reach down to the header's bottom edge (design 23, joined
    // tabs): the open one is white and runs into the page, like a browser's.
    return SizedBox(
      height: height,
      child: OverflowBox(
        alignment: Alignment.topLeft,
        maxHeight: height + joinDepth,
        minHeight: height + joinDepth,
        child: ValueListenableBuilder(
          valueListenable: NoteTabs.paths,
          builder: (context, tabs, _) => ValueListenableBuilder(
            valueListenable: NoteTabs.active,
            builder: (context, active, _) => LayoutBuilder(
              builder: (context, constraints) {
                // all the same width, like a browser's: narrower as more
                // open, scrolling past that
                final room =
                    constraints.maxWidth - _feet * 2 - _plusWidth - tabs.length;
                final width = tabs.isEmpty
                    ? _maxWidth
                    : (room / tabs.length).clamp(_minWidth, _maxWidth);
                return ListView(
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  // room for the open tab's feet at either end
                  padding: const EdgeInsets.symmetric(horizontal: _feet),
                  children: [
                    for (final (i, path) in tabs.indexed)
                      _draggableTab(
                        context,
                        tabs: tabs,
                        index: i,
                        path: path,
                        active: active,
                        width: width,
                      ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: joinDepth),
                      child: Center(
                        child: BnIconButton(
                          icon: BnIcons.add,
                          size: _plusWidth,
                          iconSize: 16,
                          tooltip: 'Open another note',
                          color: colors.text2,
                          onPressed: () => Navigator.maybePop(context),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  static const _minWidth = 120.0, _maxWidth = 230.0, _plusWidth = 34.0;

  /// How far the open tab's curved feet reach either side of it.
  static const _feet = _TabPainter.radius;

  /// A tab that can be held and dragged: along the strip it moves there,
  /// the others making room as it passes them; onto the page it opens
  /// beside the note (see the editor's drop target).
  Widget _draggableTab(
    BuildContext context, {
    required List<String> tabs,
    required int index,
    required String path,
    required String? active,
    required double width,
  }) {
    Widget tab({bool lifted = false}) => _Tab(
      path: path,
      width: width,
      title: path == active && !lifted ? activeTitle : null,
      active: path == active,
      lifted: lifted,
      divider:
          path != active &&
          index + 1 < tabs.length &&
          tabs[index + 1] != active,
      onTap: () => NoteTabActions.switchTo(path, beforeSwitching),
      onClose: () => NoteTabActions.close(context, path, beforeSwitching),
    );
    return LongPressDraggable<String>(
      // keyed: the tab being dragged keeps its drag as the strip reorders
      key: ValueKey(path),
      data: path,
      delay: const Duration(milliseconds: 250),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Transform.translate(
        offset: Offset(-width / 2, -height / 2),
        child: tab(lifted: true),
      ),
      childWhenDragging: _TabGap(width: width),
      child: DragTarget<String>(
        onWillAcceptWithDetails: (d) =>
            d.data != path && NoteTabs.paths.value.contains(d.data),
        // moved as soon as it's over another tab, not on letting go
        onMove: (d) {
          final now = NoteTabs.paths.value;
          if (d.data == path || !now.contains(d.data)) return;
          final to = now.indexOf(path);
          NoteTabs.paths.value = [...now.where((t) => t != d.data)]
            ..insert(to, d.data);
        },
        builder: (context, _, _) => tab(),
      ),
    );
  }

  /// How far below the bar a tab reaches: to the header's bottom edge, over
  /// its hairline (the header is 64 high with 12 above and below its row).
  static const joinDepth = 14.0;
}

/// One open note in the strip: its cover, its name and ✕. The open one is
/// white, its top corners round and its foot curving out into the bar
/// under it, like a browser's tab.
class _Tab extends StatefulWidget {
  const new({
    required this.path,
    required this.width,
    required this.active,
    required this.onTap,
    required this.onClose,
    this.divider = false,
    this.lifted = false,
    this.title,
  });

  /// A short line on its right, between it and the next tab.
  final bool divider;

  /// Picked up and being dragged.
  final bool lifted;

  final String path;
  final double width;

  /// Instead of the note's name, e.g. a field to rename it.
  final Widget? title;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final active = widget.active;
    final row = Row(
      spacing: 8,
      children: [
        NoteMark(widget.path, width: 12),
        Expanded(
          child:
              widget.title ??
              Text(
                p.basename(widget.path),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BnType.body.copyWith(
                  color: active ? colors.text : colors.text2,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
        ),
        BnIconButton(
          icon: BnIcons.close,
          size: 24,
          iconSize: 13,
          radius: 12,
          tooltip: 'Close tab',
          color: active ? colors.text2 : colors.muted,
          onPressed: widget.onClose,
        ),
      ],
    );
    if (widget.lifted) {
      // picked up: a card under the finger
      return Material(
        elevation: 8,
        color: colors.surface,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: Container(
          width: widget.width,
          height: NoteTabsBar.height,
          padding: const EdgeInsets.only(left: 14, right: 6),
          child: row,
        ),
      );
    }
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: CustomPaint(
          painter: _TabPainter(
            active: active,
            hovered: _hovered,
            divider: widget.divider,
            fill: colors.surface,
            hover: colors.surface.withValues(alpha: 0.55),
            line: colors.hairline,
          ),
          child: SizedBox(
            width: widget.width,
            height: NoteTabsBar.height + NoteTabsBar.joinDepth,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 14,
                right: 6,
                bottom: NoteTabsBar.joinDepth,
              ),
              child: row,
            ),
          ),
        ),
      ),
    );
  }
}

/// A dragged tab's place in the strip while it's away.
class _TabGap extends StatelessWidget {
  const new({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: NoteTabsBar.height + NoteTabsBar.joinDepth,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, NoteTabsBar.joinDepth + 2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: BadNotesColors.of(context).surface.withValues(alpha: 0.4),
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
      ),
    ),
  );
}

/// A tab's background. The open tab's outline goes up from a foot curving
/// out on the left, over its round top and down to a foot on the right,
/// joining the bar under it; below the strip it's hidden by that bar.
class _TabPainter extends CustomPainter {
  const new({
    required this.active,
    required this.hovered,
    required this.divider,
    required this.fill,
    required this.hover,
    required this.line,
  });

  static const radius = 10.0;

  final bool active, hovered, divider;
  final Color fill, hover, line;

  @override
  void paint(Canvas canvas, Size size) {
    const r = radius;
    final w = size.width;
    const b = NoteTabsBar.height;
    if (active) {
      final outline = Path()
        ..moveTo(-r, b)
        ..arcToPoint(
          const Offset(0, b - r),
          radius: const Radius.circular(r),
          clockwise: false,
        )
        ..lineTo(0, r)
        ..arcToPoint(const Offset(r, 0), radius: const Radius.circular(r))
        ..lineTo(w - r, 0)
        ..arcToPoint(Offset(w, r), radius: const Radius.circular(r))
        ..lineTo(w, b - r)
        ..arcToPoint(
          Offset(w + r, b),
          radius: const Radius.circular(r),
          clockwise: false,
        );
      final body = Path.from(outline)
        ..lineTo(w + r, size.height)
        ..lineTo(-r, size.height)
        ..close();
      canvas
        ..drawPath(body, Paint()..color = fill)
        ..drawPath(
          outline,
          Paint()
            ..style = PaintingStyle.stroke
            ..color = line,
        );
      return;
    }
    if (hovered) {
      canvas.drawRRect(
        RRect.fromLTRBR(2, 5, w - 2, b - 3, const Radius.circular(8)),
        Paint()..color = hover,
      );
    }
    if (divider) {
      canvas.drawLine(
        Offset(w - 0.5, b / 2 - 8),
        Offset(w - 0.5, b / 2 + 8),
        Paint()..color = line,
      );
    }
  }

  @override
  bool shouldRepaint(_TabPainter old) =>
      old.active != active ||
      old.hovered != hovered ||
      old.divider != divider ||
      old.fill != fill ||
      old.hover != hover ||
      old.line != line;
}

/// The note's name on a phone: its cover, the name (to rename it), ⌄ and
/// how many notes are open. Tapped, it shows the open notes; swiped, it
/// steps to the next or last one.
class NoteTitlePill extends StatelessWidget {
  const NoteTitlePill({
    super.key,
    required this.path,
    required this.name,
    required this.beforeSwitching,
  });

  final String path;

  /// The field to rename the note.
  final Widget name;
  final Future<void> Function() beforeSwitching;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return ValueListenableBuilder(
      valueListenable: NoteTabs.paths,
      builder: (context, tabs, _) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => showNoteSwitcher(context, beforeSwitching),
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v.abs() < 300) return;
          NoteTabActions.step(v < 0 ? 1 : -1, beforeSwitching);
        },
        child: Container(
          height: 38,
          padding: const EdgeInsets.only(left: 10, right: 6),
          constraints: const BoxConstraints(maxWidth: 320),
          decoration: BoxDecoration(
            color: colors.sunken,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              NoteMark(path),
              Flexible(child: name),
              Icon(BnIcons.down, size: 14, color: colors.muted),
              if (tabs.length > 1)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.accent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${tabs.length}',
                    style: BnType.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The open notes as cards with their first page, to switch to or close;
/// + opens another.
Future<void> showNoteSwitcher(
  BuildContext context,
  Future<void> Function() beforeSwitching,
) {
  final colors = BadNotesColors.of(context);
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: colors.surface,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        child: ValueListenableBuilder(
          valueListenable: NoteTabs.paths,
          builder: (context, tabs, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Open notes',
                      style: BnType.title.copyWith(color: colors.text),
                    ),
                  ),
                  BnIconButton(
                    icon: BnIcons.add,
                    tooltip: 'Open another note',
                    color: colors.text2,
                    onPressed: () {
                      Navigator.pop(sheet);
                      Navigator.maybePop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 176,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final path in tabs)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: _NoteCard(
                          path: path,
                          active: path == NoteTabs.active.value,
                          onTap: () {
                            Navigator.pop(sheet);
                            NoteTabActions.switchTo(path, beforeSwitching);
                          },
                          onClose: () {
                            if (tabs.length == 1) Navigator.pop(sheet);
                            NoteTabActions.close(
                              context,
                              path,
                              beforeSwitching,
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// An open note in the switcher: its first page (or cover) and its name.
/// Swiped up, or ✕, it closes.
class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.path,
    required this.active,
    required this.onTap,
    required this.onClose,
  });

  final String path;
  final bool active;
  final VoidCallback onTap, onClose;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final cover = _coverOf(path);
    final page = path.startsWith('/')
        ? FileManager.getFile('$path${Editor.extension}.p')
        : null;
    return GestureDetector(
      onTap: onTap,
      onVerticalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) < -300) onClose();
      },
      child: SizedBox(
        width: 108,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 136,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: active ? colors.accent : colors.hairline,
                  width: active ? 2 : 1,
                ),
              ),
              child: cover != null
                  ? NotebookCover(
                      design: cover,
                      title: p.basename(path),
                      showTitle: path.startsWith('/')
                          ? NotebookCovers.showsName(path)
                          : null,
                    )
                  : page != null && page.existsSync()
                  ? Image.file(
                      page,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            Row(
              spacing: 6,
              children: [
                NoteMark(path, width: 9),
                Expanded(
                  child: Text(
                    p.basename(path),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BnType.caption.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onClose,
                  child: Icon(BnIcons.close, size: 14, color: colors.muted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
