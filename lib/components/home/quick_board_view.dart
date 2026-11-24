import 'dart:math' as math;

import 'package:badnotes/components/home/board_background.dart';
import 'package:badnotes/components/home/home_shell.dart';
import 'package:badnotes/components/home/pin_board.dart';
import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/home/quick_board.dart';
import 'package:badnotes/components/home/quick_ink.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/components/ui/covered_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:badnotes/components/home/quick_composer.dart';

export 'package:badnotes/components/home/quick_composer.dart'
    show showQuickComposer;

const _hand = 'Caveat';

/// The quick notes card on the desk (design M_Home), or a strip across it
/// on narrower screens (M_Portrait).
class QuickNotesCard extends HookWidget {
  const new({super.key, this.strip = false, this.height = 500});

  final bool strip;
  final double height;

  @override
  Widget build(BuildContext context) {
    useEffect(() {
      QuickBoard.load();
      return null;
    }, const []);
    final items = useValueListenable(QuickBoard.items);
    final colors = BadNotesColors.of(context);
    final header = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick notes',
                style: BnType.section.copyWith(color: colors.text),
              ),
              if (items.isNotEmpty)
                Text(
                  '${items.length} pinned',
                  style: BnType.micro.copyWith(color: colors.muted),
                ),
            ],
          ),
        ),
        _HeaderButton(
          icon: Icons.open_in_full,
          tooltip: 'Open the board full screen',
          onTap: () => showPinBoardFull(context),
        ),
        const SizedBox(width: 6),
        if (!strip) ...[
          Builder(
            builder: (context) => _HeaderButton(
              icon: BnIcons.more,
              tooltip: 'Board',
              onTap: () => _boardMenu(context),
            ),
          ),
          const SizedBox(width: 6),
        ],
        Builder(
          builder: (context) =>
              _AddNoteButton(onTap: () => showQuickComposer(context)),
        ),
      ],
    );
    final empty = Text(
      'Pin anything here for quick access',
      textAlign: TextAlign.center,
      style: BnType.caption.copyWith(color: colors.muted),
    );

    if (strip) {
      return BnCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            const SizedBox(height: 12),
            SizedBox(
              height: 120,
              child: items.isEmpty
                  ? Center(child: empty)
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, i) => SizedBox(
                        width: 150,
                        child: _BoardTile(item: items[i], index: i),
                      ),
                    ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: height,
      child: BnCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            const SizedBox(height: 12),
            // the notes and photos pinned anywhere, any size and angle
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: PinBoard(
                        items: items,
                        openNote: showQuickNote,
                        openPhoto: showQuickPhoto,
                        minHeight: height - 80,
                      ),
                    ),
                    if (items.isEmpty)
                      Positioned(left: 0, right: 0, bottom: 14, child: empty),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small round button in the board's header.
class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          side: BorderSide(color: colors.hairline),
        ),
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          onTap: onTap,
          child: SizedBox.square(
            dimension: 34,
            child: Icon(icon, size: 16, color: colors.text2),
          ),
        ),
      ),
    );
  }
}

/// "+ Note": a new quick note.
class _AddNoteButton extends StatelessWidget {
  const _AddNoteButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Semantics(
      button: true,
      label: 'New quick note',
      child: Material(
        color: colors.accent,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          onTap: onTap,
          child: SizedBox(
            height: 34,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(BnIcons.add, size: 15, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Note',
                    style: BnType.body.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The board's menu (design 4): tidy up, its background, unpin all.
void _boardMenu(BuildContext context) => showAppleMenu(
  context,
  anchor: rectOf(context),
  entries: [
    AppleMenuItem(
      'Tidy up',
      icon: Icons.grid_view,
      onTap: () => _tidy(context),
    ),
    if (QuickBoard.untidy != null)
      AppleMenuItem(
        'Undo tidy up',
        icon: BnIcons.undo,
        onTap: QuickBoard.undoTidy,
      ),
    AppleMenuItem(
      'Background…',
      icon: Icons.wallpaper,
      onTap: () => showBoardBackground(context),
    ),
    if (QuickBoard.items.value.isNotEmpty)
      AppleMenuItem(
        'Unpin everything',
        icon: Icons.delete_outline,
        destructive: true,
        onTap: () => _confirmUnpinAll(context),
      ),
  ],
);

/// Takes everything off, with a moment to undo it.
void _confirmUnpinAll(BuildContext context) {
  final removed = QuickBoard.removeAll();
  showBanner(
    context,
    'Unpinned ${removed.length} ${removed.length == 1 ? 'item' : 'items'}',
    actionLabel: 'Undo',
    onAction: () => QuickBoard.restore(removed),
    duration: const Duration(seconds: 6),
  );
}

/// Tidies the board, with a moment to undo it.
void _tidy(BuildContext context) {
  QuickBoard.tidy();
  showBanner(
    context,
    'Tidied up',
    actionLabel: 'Undo',
    onAction: QuickBoard.undoTidy,
    duration: const Duration(seconds: 5),
  );
}

/// The board full screen, for more room: search, label filters, its
/// background, tidy up and a new note along the top.
Future<void> showPinBoardFull(BuildContext context) =>
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const _FullBoard()));

class _FullBoard extends StatefulWidget {
  const new();

  @override
  State<_FullBoard> createState() => _FullBoardState();
}

class _FullBoardState extends State<_FullBoard> {
  final _search = TextEditingController();
  var _query = '';

  /// The label chip chosen: null for all, [_due] for the ones with a date.
  String? _filter;
  static const _due = '\u0000due';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _matches(BoardItem item) {
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty &&
        ![
          item.text,
          for (final c in item.checklist) c.text,
          ...item.labels,
        ].any((t) => t.toLowerCase().contains(q))) {
      return false;
    }
    return switch (_filter) {
      null => true,
      _due => item.due != null,
      final label => item.labels.contains(label),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 760;
    // a still picture under the composer and other dialogs
    return CoveredSnapshot(
      child: Scaffold(
        backgroundColor: colors.surface,
        body: ValueListenableBuilder(
          valueListenable: QuickBoard.items,
          builder: (context, items, _) {
            final due = items.where((i) => i.dueNow).length;
            final labels = QuickBoard.labels;
            if (_filter != null &&
                _filter != _due &&
                !labels.contains(_filter)) {
              _filter = null;
            }
            final filtering = _query.trim().isNotEmpty || _filter != null;
            final search = SizedBox(
              height: 38,
              width: wide ? 260 : double.infinity,
              child: TextField(
                controller: _search,
                onChanged: (q) => setState(() => _query = q),
                style: BnType.body.copyWith(color: colors.text),
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: colors.sunkenSoft,
                  hintText: 'Search the board',
                  prefixIcon: Icon(
                    BnIcons.search,
                    size: 16,
                    color: colors.muted,
                  ),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          icon: Icon(
                            BnIcons.close,
                            size: 14,
                            color: colors.muted,
                          ),
                          onPressed: () => setState(() {
                            _search.clear();
                            _query = '';
                          }),
                        ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(BnRadius.control),
                    ),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            );
            final chips = SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: 6,
                children: [
                  BnChip(
                    label: 'All',
                    selected: _filter == null,
                    onTap: () => setState(() => _filter = null),
                  ),
                  for (final label in labels)
                    BnChip(
                      label: label,
                      icon: Icons.label_outline,
                      selected: _filter == label,
                      onTap: () => setState(
                        () => _filter = _filter == label ? null : label,
                      ),
                    ),
                  BnChip(
                    label: 'Due',
                    icon: Icons.alarm,
                    selected: _filter == _due,
                    onTap: () =>
                        setState(() => _filter = _filter == _due ? null : _due),
                  ),
                ],
              ),
            );
            final actions = [
              Builder(
                builder: (context) => wide
                    ? BnButton(
                        label: 'Board',
                        icon: Icons.wallpaper,
                        height: 38,
                        onPressed: () => showBoardBackground(context),
                      )
                    : BnIconButton(
                        icon: Icons.wallpaper,
                        tooltip: 'Board background',
                        onPressed: () => showBoardBackground(context),
                      ),
              ),
              if (wide)
                BnButton(
                  label: 'Tidy up',
                  icon: Icons.grid_view,
                  height: 38,
                  onPressed: () => _tidy(context),
                )
              else
                BnIconButton(
                  icon: Icons.grid_view,
                  tooltip: 'Tidy up',
                  onPressed: () => _tidy(context),
                ),
              Builder(
                builder: (context) => BnIconButton(
                  icon: BnIcons.more,
                  tooltip: 'More',
                  onPressed: () => _boardMenu(context),
                ),
              ),
              Builder(
                builder: (context) => BnButton.primary(
                  label: 'Note',
                  icon: BnIcons.add,
                  height: 38,
                  onPressed: () => showQuickComposer(context),
                ),
              ),
            ];
            final bar = Material(
              color: colors.surface,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 6, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 8,
                    children: [
                      Row(
                        spacing: 8,
                        children: [
                          const BackButton(),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Quick notes',
                                  style: BnType.title.copyWith(
                                    color: colors.text,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${items.length} pinned · $due due today',
                                  style: BnType.caption.copyWith(
                                    color: colors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (wide) search,
                          ...actions,
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: wide
                            ? chips
                            : Column(spacing: 8, children: [search, chips]),
                      ),
                    ],
                  ),
                ),
              ),
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                bar,
                Divider(height: 1, color: colors.hairline),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, c) => PinBoard(
                      items: items,
                      openNote: showQuickNote,
                      openPhoto: showQuickPhoto,
                      minHeight: c.maxHeight,
                      zoomable: true,
                      matches: filtering ? _matches : null,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A note or photo on the board; drag one onto another to reorder.
class _BoardTile extends StatelessWidget {
  const _BoardTile({required this.item, required this.index});

  final BoardItem item;
  final int index;

  @override
  Widget build(BuildContext context) {
    final tile = RepaintBoundary(
      child: item.isPhoto ? _PhotoTile(item: item) : _NoteTile(item: item),
    );
    return DragTarget<int>(
      onWillAcceptWithDetails: (d) => d.data != index,
      onAcceptWithDetails: (d) => QuickBoard.reorder(d.data, index),
      builder: (context, _, _) => LongPressDraggable<int>(
        data: index,
        feedback: SizedBox(
          width: 130,
          height: 104,
          child: Material(type: MaterialType.transparency, child: tile),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: tile),
        child: GestureDetector(
          onTap: () => item.isPhoto
              ? showQuickPhoto(context, item)
              : showQuickNote(context, item),
          child: tile,
        ),
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({required this.item});

  final BoardItem item;

  @override
  Widget build(BuildContext context) {
    final lines = [
      if (item.text.isNotEmpty) item.text,
      for (final c in item.checklist) '${c.done ? '☑' : '☐'} ${c.text}',
    ].join('\n');
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: item.paper,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              lines,
              maxLines: 4,
              overflow: TextOverflow.fade,
              style: const TextStyle(
                fontFamily: _hand,
                fontSize: 19,
                fontWeight: FontWeight.w700,
                height: 1.05,
                color: BnColors.text,
              ),
            ),
          ),
          if (item.ink.isNotEmpty)
            CustomPaint(painter: BoardInkPainter(item.ink)),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.item});

  final BoardItem item;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      child: Image(
        image: ResizeImage(
          FileImage(FileManager.getFile(item.photo!)),
          width: 320,
          allowUpscaling: false,
        ),
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, _, _) =>
            ColoredBox(color: BadNotesColors.of(context).sunkenSoft),
      ),
    );
  }
}

/// A quick note, big (design N12): tick its list, change its colour, edit
/// or unpin it.
Future<void> showQuickNote(BuildContext context, BoardItem item) =>
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: true,
        barrierColor: const Color(0x8C16161A),
        barrierLabel: 'Close',
        transitionDuration: BnMotion.normal,
        pageBuilder: (context, animation, _) =>
            bnPopIn(context, animation, _BigNote(id: item.id)),
      ),
    );

class _BigNote extends HookWidget {
  const _BigNote({required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    final items = useValueListenable(QuickBoard.items);
    final item = items.where((i) => i.id == id).firstOrNull;
    if (item == null) return const SizedBox();
    final size = MediaQuery.sizeOf(context);
    final side = math.min(480.0, math.min(size.width - 48, size.height - 220));
    return Stack(
      children: [
        Positioned(
          top: 30,
          right: 36,
          child: _RoundButton(
            icon: BnIcons.close,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 120),
            child: InteractiveViewer(
              // pinch to read it closer
              maxScale: 4,
              clipBehavior: Clip.none,
              child: Transform.rotate(
                angle: -2 * math.pi / 180,
                child: Stack(
                  children: [
                    _bigPaper(item, side),
                    if (item.ink.isNotEmpty)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: RepaintBoundary(
                            child: CustomPaint(
                              painter: BoardInkPainter(item.ink),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 150,
          child: Center(child: _bigBar(context, item)),
        ),
      ],
    );
  }

  Widget _bigPaper(BoardItem item, double side) => Container(
    width: side,
    height: side * 0.94,
    padding: EdgeInsets.fromLTRB(side * 0.1, side * 0.12, 30, 24),
    decoration: BoxDecoration(
      color: item.paper,
      boxShadow: const [
        BoxShadow(
          color: Color(0x40000000),
          blurRadius: 16,
          offset: Offset(0, 20),
        ),
      ],
    ),
    child: Material(
      type: MaterialType.transparency,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.text.isNotEmpty)
                    Text(
                      item.text,
                      style: const TextStyle(
                        fontFamily: _hand,
                        fontSize: 46,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                        color: BnColors.text,
                      ),
                    ),
                  const SizedBox(height: 16),
                  for (final (i, check) in item.checklist.indexed)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => QuickBoard.update(
                        item.copyWith(
                          checklist: [...item.checklist]
                            ..[i] = check.copyWith(done: !check.done),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: check.done
                                    ? BnColors.text
                                    : Colors.transparent,
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(5),
                                ),
                                border: Border.all(
                                  color: BnColors.text,
                                  width: 2,
                                ),
                              ),
                              child: check.done
                                  ? const Icon(
                                      BnIcons.check,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Flexible(
                              child: Text(
                                check.text,
                                style: TextStyle(
                                  fontFamily: _hand,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                  color: check.done
                                      ? BnColors.muted
                                      : BnColors.text,
                                  decoration: check.done
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Text(
            'Pinned ${homeShortDate(item.createdAt)}',
            style: BnType.caption.copyWith(
              color: BnColors.text2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _bigBar(BuildContext context, BoardItem item) => _DarkBar(
    children: [
      Builder(
        builder: (bar) => _DarkAction(
          icon: BnIcons.rename,
          label: 'Edit',
          onTap: () => showQuickComposer(bar, editing: item),
        ),
      ),
      for (final (i, paper) in BoardItem.colors.indexed)
        GestureDetector(
          onTap: () => QuickBoard.update(item.copyWith(color: i)),
          child: Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: paper,
              shape: BoxShape.circle,
              border: Border.all(
                color: i == item.color ? Colors.white : Colors.transparent,
                width: 2,
              ),
            ),
          ),
        ),
      _DarkAction(
        icon: BnIcons.pin,
        label: 'Unpin',
        onTap: () {
          showBanner(
            context,
            'Note unpinned',
            actionLabel: 'Undo',
            onAction: () => QuickBoard.restore([item]),
            duration: const Duration(seconds: 5),
          );
          Navigator.of(context).pop();
          QuickBoard.remove(item);
        },
      ),
    ],
  );
}

/// A pinned photo, big (design N13), with the others before and after it.
Future<void> showQuickPhoto(BuildContext context, BoardItem item) =>
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: true,
        barrierColor: const Color(0xE6121214),
        barrierLabel: 'Close',
        transitionDuration: BnMotion.normal,
        pageBuilder: (context, animation, _) =>
            bnPopIn(context, animation, _BigPhoto(first: item.id)),
      ),
    );

class _BigPhoto extends HookWidget {
  const _BigPhoto({required this.first});

  final String first;

  @override
  Widget build(BuildContext context) {
    final items = useValueListenable(QuickBoard.items);
    final photos = items.where((i) => i.isPhoto).toList();
    final shown = useState(first);
    final index = photos.indexWhere((p) => p.id == shown.value);
    if (index < 0) return const SizedBox();
    final item = photos[index];
    void go(int by) => shown.value = photos[(index + by) % photos.length].id;
    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(90, 80, 90, 140),
            child: InteractiveViewer(
              key: ValueKey(item.id),
              maxScale: 5,
              child: Image(
                image: ResizeImage(
                  FileImage(FileManager.getFile(item.photo!)),
                  width: 2400,
                  allowUpscaling: false,
                ),
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
        Positioned(
          top: 30,
          right: 36,
          child: _RoundButton(
            icon: BnIcons.close,
            onTap: () => Navigator.of(context).pop(),
          ),
        ),
        if (photos.length > 1) ...[
          Positioned(
            left: 24,
            top: 0,
            bottom: 0,
            child: Center(
              child: _RoundButton(icon: BnIcons.back, onTap: () => go(-1)),
            ),
          ),
          Positioned(
            right: 24,
            top: 0,
            bottom: 0,
            child: Center(
              child: _RoundButton(icon: BnIcons.forward, onTap: () => go(1)),
            ),
          ),
        ],
        Positioned(
          left: 16,
          right: 16,
          bottom: 40,
          child: Center(
            child: _DarkBar(
              children: [
                _DarkAction(
                  icon: BnIcons.share,
                  label: 'Share / save',
                  onTap: () async {
                    final bytes = await FileManager.readFile(item.photo!);
                    if (bytes == null || !context.mounted) return;
                    await FileManager.exportFile(
                      'Quick photo ${item.id}.jpg',
                      bytes,
                      isImage: true,
                      context: context,
                    );
                  },
                ),
                _DarkAction(
                  icon: BnIcons.trash,
                  label: 'Delete',
                  danger: true,
                  onTap: () {
                    showBanner(
                      context,
                      'Photo unpinned',
                      actionLabel: 'Undo',
                      onAction: () => QuickBoard.restore([item]),
                      duration: const Duration(seconds: 5),
                    );
                    if (photos.length == 1) Navigator.of(context).pop();
                    if (photos.length > 1) go(1);
                    QuickBoard.remove(item);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: const CircleBorder(),
    elevation: 2,
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox.square(
        dimension: 48,
        child: Icon(icon, size: 22, color: BnColors.text),
      ),
    ),
  );
}

class _DarkBar extends StatelessWidget {
  const _DarkBar({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFF1F1F22),
      borderRadius: const BorderRadius.all(Radius.circular(BnRadius.pill)),
      border: Border.all(color: const Color(0x1AFFFFFF)),
    ),
    child: Material(
      type: MaterialType.transparency,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: children,
      ),
    ),
  );
}

class _DarkAction extends StatelessWidget {
  const _DarkAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFFF7A6E) : Colors.white;
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(Radius.circular(BnRadius.pill)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: BnType.body.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
