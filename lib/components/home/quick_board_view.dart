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
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';

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
        if (!strip) ...[
          _HeaderButton(
            icon: Icons.open_in_full,
            tooltip: 'Open the board full screen',
            onTap: () => showPinBoardFull(context),
          ),
          const SizedBox(width: 6),
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
    AppleMenuItem('Tidy up', icon: Icons.grid_view, onTap: QuickBoard.tidy),
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

Future<void> _confirmUnpinAll(BuildContext context) async {
  final count = QuickBoard.items.value.length;
  final sure = await showBnDialog<bool>(
    context: context,
    title: 'Unpin everything?',
    message:
        'All $count notes and photos come off the board. This can\'t be undone.',
    actions: const [
      BnDialogAction('Keep them', value: false),
      BnDialogAction('Unpin all', value: true, destructive: true),
    ],
  );
  if (sure ?? false) QuickBoard.removeAll();
}

/// The board full screen, for more room.
Future<void> showPinBoardFull(BuildContext context) =>
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          final colors = BadNotesColors.of(context);
          return Scaffold(
            backgroundColor: colors.surface,
            appBar: AppBar(
              backgroundColor: colors.surface,
              surfaceTintColor: Colors.transparent,
              titleSpacing: 4,
              title: ValueListenableBuilder(
                valueListenable: QuickBoard.items,
                builder: (context, items, _) => Column(
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
                      '${items.length} pinned',
                      style: BnType.caption.copyWith(color: colors.muted),
                    ),
                  ],
                ),
              ),
              actions: [
                Builder(
                  builder: (context) => BnButton(
                    label: 'Tidy up',
                    icon: Icons.grid_view,
                    height: 38,
                    onPressed: () => _boardMenu(context),
                  ),
                ),
                const SizedBox(width: 8),
                Builder(
                  builder: (context) => BnButton.primary(
                    label: 'Note',
                    icon: BnIcons.add,
                    height: 38,
                    onPressed: () => showQuickComposer(context),
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
            body: ValueListenableBuilder(
              valueListenable: QuickBoard.items,
              builder: (context, items, _) => PinBoard(
                items: items,
                openNote: showQuickNote,
                openPhoto: showQuickPhoto,
                minHeight: MediaQuery.sizeOf(context).height,
                zoomable: true,
              ),
            ),
          );
        },
      ),
    );

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

/// Writes a new quick note, or changes [editing] (design N06).
Future<void> showQuickComposer(BuildContext context, {BoardItem? editing}) =>
    showBnPopover<void>(
      anchor: context,
      width: 380,
      builder: (context) => _Composer(editing: editing),
    );

class _Composer extends StatefulWidget {
  const _Composer({this.editing});

  final BoardItem? editing;

  @override
  State<_Composer> createState() => _ComposerState();
}

class _ComposerState extends State<_Composer> {
  late var _color = widget.editing?.color ?? 0;
  late var _checklist = widget.editing?.checklist.isNotEmpty ?? false;

  /// Written with a pen at first; a note that was only typed opens to type.
  late var _tool =
      widget.editing != null &&
          widget.editing!.ink.isEmpty &&
          (widget.editing!.text.isNotEmpty ||
              widget.editing!.checklist.isNotEmpty)
      ? QuickTool.text
      : QuickTool.fountain;
  late final _ink = [...?widget.editing?.ink];

  /// The ink before each change, for undo: a line written or rubbed out.
  final _undo = <List<BoardStroke>>[];

  void _change(VoidCallback change) => setState(() {
    _undo.add(List.of(_ink));
    change();
  });
  var _penColor = _penColors.first;
  var _highlighterColor = _highlighterColors.first;
  final _focus = FocusNode();

  static const _penColors = [
    Color(0xFF1C1C1E),
    Color(0xFF2A55B8),
    Color(0xFFD13A3A),
  ];
  static const _highlighterColors = [
    Color(0xFFFFD233),
    Color(0xFF7ED957),
    Color(0xFFFF8FC8),
  ];

  void _pick(QuickTool tool) {
    setState(() => _tool = tool);
    if (tool == QuickTool.text) {
      _focus.requestFocus();
    } else {
      _focus.unfocus();
    }
  }

  late final _text = TextEditingController(
    text: widget.editing == null
        ? ''
        : [
            if (widget.editing!.text.isNotEmpty) widget.editing!.text,
            for (final c in widget.editing!.checklist) c.text,
          ].join('\n'),
  );

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _pin() {
    final lines = _text.text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    Navigator.of(context).pop();
    if (lines.isEmpty && _ink.isEmpty) return;
    final old = widget.editing?.checklist ?? const <BoardCheck>[];
    // with a checklist, the first line is the title and the rest are items
    final text = lines.isEmpty
        ? ''
        : _checklist
        ? lines.first
        : lines.join('\n');
    final checks = _checklist && lines.isNotEmpty
        ? [
            for (final line in lines.skip(1))
              BoardCheck(line, done: old.any((c) => c.text == line && c.done)),
          ]
        : const <BoardCheck>[];
    if (widget.editing case final item?) {
      QuickBoard.update(
        item.copyWith(
          text: text,
          checklist: checks,
          ink: List.of(_ink),
          color: _color,
        ),
      );
    } else {
      QuickBoard.addNote(
        text: text,
        checklist: checks,
        ink: List.of(_ink),
        color: _color,
      );
    }
  }

  Future<void> _photo() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    if (mounted) Navigator.of(context).pop();
    await QuickBoard.addPhoto(await picked.readAsBytes());
  }

  /// Pens, highlighter and typing, their colours, and undo.
  Widget _inkBar(BadNotesColors colors) {
    final dots = switch (_tool) {
      QuickTool.text || QuickTool.eraser => const <Color>[],
      QuickTool.highlighter => _highlighterColors,
      _ => _penColors,
    };
    final current = _tool == QuickTool.highlighter
        ? _highlighterColor
        : _penColor;
    return Row(
      children: [
        for (final (tool, tip, icon) in const [
          (QuickTool.fountain, 'Fountain pen', BnToolIcons.pen),
          (QuickTool.ball, 'Ballpoint pen', BnToolIcons.pencil),
          (QuickTool.highlighter, 'Highlighter', BnToolIcons.highlighter),
          (QuickTool.eraser, 'Eraser', BnToolIcons.eraser),
          (QuickTool.text, 'Type', null),
        ])
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _InkTool(
              tooltip: tip,
              selected: _tool == tool,
              onTap: () => _pick(tool),
              child: icon == null
                  ? Icon(BnIcons.text, size: 18, color: colors.text)
                  : BnPathIcon(icon, size: 18, color: colors.text),
            ),
          ),
        if (dots.isNotEmpty) ...[
          const SizedBox(width: 6),
          for (final dot in dots)
            BnColorDot(
              color: dot,
              size: 20,
              selected: dot == current,
              onTap: () => setState(() {
                if (_tool == QuickTool.highlighter) {
                  _highlighterColor = dot;
                } else {
                  _penColor = dot;
                }
              }),
            ),
        ],
        const Spacer(),
        _InkTool(
          tooltip: 'Undo',
          onTap: _undo.isEmpty
              ? null
              : () => setState(() {
                  _ink
                    ..clear()
                    ..addAll(_undo.removeLast());
                }),
          child: Icon(
            BnIcons.undo,
            size: 18,
            color: _undo.isEmpty ? colors.faint : colors.text,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.editing == null ? 'New quick note' : 'Quick note',
                style: BnType.title.copyWith(color: colors.text),
              ),
            ),
            for (final (i, paper) in BoardItem.colors.indexed)
              BnColorDot(
                color: paper,
                size: 24,
                selected: i == _color,
                onTap: () => setState(() => _color = i),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 190,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: BoardItem.colors[_color],
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                // typed only with the text tool: a pen writes over it
                child: IgnorePointer(
                  ignoring: _tool != QuickTool.text,
                  child: TextField(
                    controller: _text,
                    autofocus: _tool == QuickTool.text,
                    focusNode: _focus,
                    maxLines: null,
                    expands: true,
                    cursorColor: BnColors.text,
                    style: const TextStyle(
                      fontFamily: _hand,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                      color: BnColors.text,
                    ),
                    decoration: InputDecoration(
                      filled: false,
                      isCollapsed: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: _ink.isNotEmpty
                          ? null
                          : _checklist
                          ? 'Title, then one item a line'
                          : 'Write something…',
                      hintStyle: const TextStyle(
                        fontFamily: _hand,
                        fontSize: 24,
                        color: Color(0x661C1C1E),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: QuickInkPad(
                  ink: _ink,
                  tool: _tool,
                  color: _tool == QuickTool.highlighter
                      ? _highlighterColor
                      : _penColor,
                  onStroke: (stroke) => _change(() => _ink.add(stroke)),
                  onErase: (hit) =>
                      _change(() => _ink.removeWhere(hit.contains)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _inkBar(colors),
        const SizedBox(height: 14),
        Row(
          spacing: 8,
          children: [
            _ComposerTool(
              icon: BnIcons.listChecks,
              tooltip: 'Checklist',
              selected: _checklist,
              onTap: () => setState(() => _checklist = !_checklist),
            ),
            if (widget.editing == null)
              _ComposerTool(
                icon: BnIcons.camera,
                tooltip: 'Pin a photo',
                onTap: _photo,
              ),
            const Spacer(),
            Material(
              color: colors.accentTint,
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: _pin,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(BnIcons.pin, size: 16, color: colors.accentStrong),
                      const SizedBox(width: 8),
                      Text(
                        widget.editing == null ? 'Pin to board' : 'Save',
                        style: BnType.bodyLarge.copyWith(
                          color: colors.accentStrong,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// One of the quick note's writing tools.
class _InkTool extends StatelessWidget {
  const _InkTool({
    required this.tooltip,
    required this.onTap,
    required this.child,
    this.selected = false,
  });

  final String tooltip;
  final VoidCallback? onTap;
  final Widget child;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: selected ? colors.accentTint : Colors.transparent,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          onTap: onTap,
          child: SizedBox.square(dimension: 36, child: Center(child: child)),
        ),
      ),
    );
  }
}

class _ComposerTool extends StatelessWidget {
  const _ComposerTool({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) => BnIconButton(
    icon: icon,
    tooltip: tooltip,
    size: 40,
    selected: selected,
    onPressed: onTap,
  );
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
            child: Transform.rotate(
              angle: -2 * math.pi / 180,
              child: Stack(
                children: [
                  _bigPaper(item, side),
                  if (item.ink.isNotEmpty)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(painter: BoardInkPainter(item.ink)),
                      ),
                    ),
                ],
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
          blurRadius: 40,
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
            child: Image(
              image: FileImage(FileManager.getFile(item.photo!)),
              fit: BoxFit.contain,
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
