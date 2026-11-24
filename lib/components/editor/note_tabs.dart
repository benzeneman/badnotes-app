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
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
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
            builder: (context, active, _) => ListView(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              children: [
                for (final (i, path) in tabs.indexed)
                  Padding(
                    // a hairline between two tabs neither of which is open
                    padding: const EdgeInsets.only(right: 1),
                    child: LongPressDraggable<String>(
                      data: path,
                      delay: const Duration(milliseconds: 250),
                      dragAnchorStrategy: pointerDragAnchorStrategy,
                      feedback: Transform.translate(
                        offset: const Offset(-40, -16),
                        child: Material(
                          elevation: 6,
                          borderRadius: BorderRadius.circular(BnRadius.chip),
                          color: colors.surface,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Text(
                              p.basename(path),
                              style: BnType.body.copyWith(color: colors.text),
                            ),
                          ),
                        ),
                      ),
                      child: _Tab(
                        path: path,
                        title: path == active ? activeTitle : null,
                        active: path == active,
                        divider:
                            path != active &&
                            i + 1 < tabs.length &&
                            tabs[i + 1] != active,
                        onTap: () =>
                            NoteTabActions.switchTo(path, beforeSwitching),
                        onClose: () => NoteTabActions.close(
                          context,
                          path,
                          beforeSwitching,
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(bottom: joinDepth),
                  child: Center(
                    child: BnIconButton(
                      icon: BnIcons.add,
                      size: 34,
                      iconSize: 16,
                      tooltip: 'Open another note',
                      color: colors.muted,
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// How far below the bar a tab reaches: to the header's bottom edge, over
  /// its hairline (the header is 64 high with 12 above and below its row).
  static const joinDepth = 14.0;
}

/// One open note in the strip: its cover and name, ✕ when open or hovered.
class _Tab extends StatefulWidget {
  const _Tab({
    required this.path,
    required this.active,
    required this.onTap,
    required this.onClose,
    this.divider = false,
    this.title,
  });

  /// A hairline on its right, between it and the next tab.
  final bool divider;

  final String path;

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
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: BnMotion.fast,
          curve: BnMotion.curve,
          height: NoteTabsBar.height + NoteTabsBar.joinDepth,
          constraints: const BoxConstraints(minWidth: 90, maxWidth: 220),
          padding: EdgeInsets.only(
            left: 12,
            right: 4,
            bottom: NoteTabsBar.joinDepth,
          ),
          decoration: BoxDecoration(
            color: active
                ? colors.surface
                : _hovered
                ? colors.sunken.withValues(alpha: 0.6)
                : colors.surface.withValues(alpha: 0),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            border: active
                ? Border(
                    top: BorderSide(color: colors.hairline),
                    left: BorderSide(color: colors.hairline),
                    right: BorderSide(color: colors.hairline),
                  )
                : widget.divider
                ? Border(
                    right: BorderSide(
                      color: colors.hairline.withValues(alpha: 0.9),
                    ),
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              NoteMark(widget.path, width: 12),
              Flexible(
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
              Opacity(
                opacity: active || _hovered ? 1 : 0,
                child: BnIconButton(
                  icon: BnIcons.close,
                  size: 24,
                  iconSize: 13,
                  radius: 6,
                  tooltip: 'Close tab',
                  color: colors.muted,
                  onPressed: widget.onClose,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
