import 'dart:math' as math;

import 'package:badnotes/components/home/pinch_zoom.dart';
import 'package:badnotes/components/home/quick_board.dart';
import 'package:badnotes/components/home/quick_ink.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/components/editor_ui/bar_color_row.dart';
import 'package:badnotes/components/editor_ui/color_panel.dart';
import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/ui/bn_tool_panels.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

const _hand = 'Caveat';

/// Writes a new quick note, or changes [editing]: a big pad, a centred
/// dialog on wide screens and a page of its own on phones.
Future<void> showQuickComposer(BuildContext context, {BoardItem? editing}) {
  final size = MediaQuery.sizeOf(context);
  final composer = QuickComposer(editing: editing);
  if (size.shortestSide < 600) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          backgroundColor: BadNotesColors.of(context).surface,
          body: SafeArea(child: composer),
        ),
      ),
    );
  }
  final colors = BadNotesColors.of(context);
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: colors.scrim,
    transitionDuration: BnMotion.normal,
    pageBuilder: (context, _, _) {
      // about 150 at the sides, 50 above and 40 below on a 1200 wide tablet
      final s = MediaQuery.sizeOf(context);
      final pad = MediaQuery.paddingOf(context);
      return Padding(
        padding: EdgeInsets.fromLTRB(
          s.width * 0.125,
          math.max(pad.top + 12, s.height * 0.06),
          s.width * 0.125,
          math.max(pad.bottom + 12, s.height * 0.05),
        ),
        child: Material(
          color: colors.surface,
          clipBehavior: Clip.antiAlias,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(BnRadius.popover)),
          ),
          elevation: 12,
          child: composer,
        ),
      );
    },
  );
}

/// The quick note pad: header, paper to write on (pinch to zoom), and a
/// dock of tools, colours, width and paper.
class QuickComposer extends StatefulWidget {
  const new({super.key, this.editing});

  final BoardItem? editing;

  @override
  State<QuickComposer> createState() => _QuickComposerState();
}

class _QuickComposerState extends State<QuickComposer> {
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

  /// The finished lines; a new list on each change, so the pad repaints
  /// them only then.
  late var _ink = List<BoardStroke>.unmodifiable([...?widget.editing?.ink]);

  /// The ink before and after each change, for undo and redo.
  final _undo = <List<BoardStroke>>[], _redo = <List<BoardStroke>>[];

  void _setInk(List<BoardStroke> ink) => setState(() {
    _undo.add(_ink);
    _redo.clear();
    _ink = List.unmodifiable(ink);
  });

  var _penColor = _penColors.first;
  var _highlighterColor = _highlighterColors.first;

  /// Each pen's width, as a fraction of the note's width.
  final _sizes = {
    for (final t in [QuickTool.fountain, QuickTool.ball, QuickTool.highlighter])
      t: BoardStroke.defaultSize(t),
  };

  final _focus = FocusNode();
  final _view = TransformationController();

  static const _penColors = [
    Color(0xFF1C1C1E),
    Color(0xFF2A55B8),
    Color(0xFFD13A3A),
    Color(0xFF2F9E77),
    Color(0xFF7C4DCC),
    Color(0xFFE07B1A),
  ];
  static const _highlighterColors = [
    Color(0xFFFFD233),
    Color(0xFF7ED957),
    Color(0xFFFF8FC8),
    Color(0xFF6EC6FF),
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
    _view.dispose();
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

  Future<void> _photo(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked == null) return;
    if (mounted) Navigator.of(context).pop();
    await QuickBoard.addPhoto(await picked.readAsBytes());
  }

  bool get _isPen => _sizes.containsKey(_tool);

  Color get _current =>
      _tool == QuickTool.highlighter ? _highlighterColor : _penColor;

  set _current(Color c) => setState(() {
    if (_tool == QuickTool.highlighter) {
      _highlighterColor = c;
    } else {
      _penColor = c;
    }
  });

  /// The quick pad's own rows in the editor's bar colors.
  String get _rowKey =>
      _tool == QuickTool.highlighter ? 'quickhighlighter' : 'quickpen';

  List<Color> get _row => BarColors.of(
    _rowKey,
    seed: _tool == QuickTool.highlighter ? _highlighterColors : _penColors,
  );

  /// The editor's color panel (presets, grid, wheel): [replacing] the
  /// ringed dot of the row, or adding a color at its end.
  void _openColors(BuildContext anchor, {Color? replacing}) {
    var slot = replacing;
    ColorPanel.show(
      anchor,
      anchor: rectOf(anchor),
      title: replacing != null ? 'Change color' : 'Color',
      color: _current,
      presets: _tool == QuickTool.highlighter
          ? BarColors.highlighterDefaults
          : ColorPanel.defaultPresets,
      replacing: replacing != null,
      onChanged: (color) {
        final from = slot;
        if (from == null) {
          BarColors.add(_rowKey, color);
        } else {
          BarColors.replace(_rowKey, from, color);
          slot = color;
        }
        _current = color;
      },
    ).whenComplete(() {
      if (mounted) setState(() {});
    });
  }

  void _fit() => _view.value = Matrix4.identity();

  Widget _header(BadNotesColors colors) => Padding(
    padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
    child: Row(
      children: [
        BnIconButton(
          icon: BnIcons.close,
          tooltip: 'Close',
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            widget.editing == null ? 'New quick note' : 'Edit quick note',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: BnType.title.copyWith(color: colors.text),
          ),
        ),
        BnIconButton(
          icon: BnIcons.undo,
          tooltip: 'Undo',
          onPressed: _undo.isEmpty
              ? null
              : () => setState(() {
                  _redo.add(_ink);
                  _ink = _undo.removeLast();
                }),
        ),
        BnIconButton(
          icon: BnIcons.redo,
          tooltip: 'Redo',
          onPressed: _redo.isEmpty
              ? null
              : () => setState(() {
                  _undo.add(_ink);
                  _ink = _redo.removeLast();
                }),
        ),
        const SizedBox(width: 8),
        BnButton.primary(
          label: widget.editing == null ? 'Pin' : 'Save',
          icon: BnIcons.pin,
          onPressed: _pin,
        ),
      ],
    ),
  );

  Widget _paper(BadNotesColors colors) => LayoutBuilder(
    builder: (context, c) {
      // the note's own shape (420 × 360 on the board), as big as fits
      const aspect = 420 / 360;
      final room = Size(c.maxWidth - 48, c.maxHeight - 48);
      final w = math.min(room.width, room.height * aspect);
      final paper = Size(w, w / aspect);
      final font = w * 0.06;
      final writing = Container(
        width: paper.width,
        height: paper.height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: BoardItem.colors[_color.clamp(0, BoardItem.colors.length - 1)],
          borderRadius: const BorderRadius.all(Radius.circular(4)),
          boxShadow: BnShadows.card,
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(w * 0.05),
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
                  style: TextStyle(
                    fontFamily: _hand,
                    fontSize: font,
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
                    hintStyle: TextStyle(
                      fontFamily: _hand,
                      fontSize: font,
                      color: const Color(0x661C1C1E),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: QuickInkPad(
                ink: _ink,
                tool: _tool,
                color: _current,
                size: _sizes[_tool],
                onStroke: (stroke) => _setInk([..._ink, stroke]),
                onErase: (hit) =>
                    _setInk([..._ink.where((s) => !hit.contains(s))]),
              ),
            ),
          ],
        ),
      );
      return Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: colors.sunkenSoft,
              child: PinchZoom(
                view: _view,
                minScale: 0.5,
                maxScale: 4,
                content: c.biggest,
                child: Stack(
                  children: [
                    // a double tap beside the paper fits it again
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onDoubleTap: _fit,
                      ),
                    ),
                    Center(child: writing),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: ListenableBuilder(
              listenable: _view,
              builder: (context, _) {
                final zoom = (_view.value.getMaxScaleOnAxis() * 100).round();
                return Tooltip(
                  message: 'Fit',
                  child: GestureDetector(
                    onTap: _fit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(BnRadius.pill),
                        ),
                        border: Border.all(color: colors.hairline),
                      ),
                      child: Text(
                        '$zoom%',
                        style: BnType.micro.copyWith(color: colors.text2),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    },
  );

  Widget _dock(BadNotesColors colors) {
    Widget tool(QuickTool t, String tip, Widget icon) => _DockTool(
      tooltip: tip,
      selected: _tool == t,
      onTap: () => _pick(t),
      child: icon,
    );
    Widget divider() => Container(
      width: 1,
      height: 26,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: colors.hairline,
    );
    final sizeRange = _isPen
        ? (
            BoardStroke.defaultSize(_tool) * 0.4,
            BoardStroke.defaultSize(_tool) * 3,
          )
        : null;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.hairline)),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 6,
        children: [
          tool(
            QuickTool.fountain,
            'Fountain pen',
            BnPathIcon(BnToolIcons.pen, size: 18, color: colors.text),
          ),
          tool(
            QuickTool.ball,
            'Ballpoint pen',
            BnPathIcon(BnToolIcons.pencil, size: 18, color: colors.text),
          ),
          tool(
            QuickTool.highlighter,
            'Highlighter',
            BnPathIcon(BnToolIcons.highlighter, size: 18, color: colors.text),
          ),
          tool(
            QuickTool.eraser,
            'Eraser',
            BnPathIcon(BnToolIcons.eraser, size: 18, color: colors.text),
          ),
          tool(
            QuickTool.text,
            'Type',
            Icon(BnIcons.text, size: 18, color: colors.text),
          ),
          _DockTool(
            tooltip: 'Checklist',
            selected: _checklist,
            onTap: () => setState(() => _checklist = !_checklist),
            child: Icon(BnIcons.listChecks, size: 18, color: colors.text),
          ),
          if (widget.editing == null) ...[
            _DockTool(
              tooltip: 'Pin a photo from the camera',
              onTap: () => _photo(ImageSource.camera),
              child: Icon(BnIcons.camera, size: 18, color: colors.text),
            ),
            _DockTool(
              tooltip: 'Pin a photo from the gallery',
              onTap: () => _photo(ImageSource.gallery),
              child: Icon(BnIcons.photo, size: 18, color: colors.text),
            ),
          ],
          if (_isPen) ...[
            divider(),
            BarColorRow(
              colors: _row,
              current: _current,
              axis: Axis.horizontal,
              invert: false,
              pick: (color) => _current = color,
              onReorder: (next) =>
                  setState(() => BarColors.set(_rowKey, next)),
              openPanel: (dot, color) => _openColors(dot, replacing: color),
            ),
            Builder(
              builder: (dot) => BnAddColorDot(onTap: () => _openColors(dot)),
            ),
          ],
          if (sizeRange case (final lo, final hi)) ...[
            divider(),
            Icon(Icons.line_weight, size: 16, color: colors.muted),
            SizedBox(
              width: 140,
              child: Slider(
                value: _sizes[_tool]!.clamp(lo, hi),
                min: lo,
                max: hi,
                onChanged: (v) => setState(() => _sizes[_tool] = v),
              ),
            ),
          ],
          divider(),
          for (final (i, paper) in BoardItem.colors.indexed)
            BnColorDot(
              color: paper,
              size: 22,
              label: 'Paper colour',
              selected: i == _color,
              onTap: () => setState(() => _color = i),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(colors),
        Divider(height: 1, color: colors.hairline),
        Expanded(child: _paper(colors)),
        _dock(colors),
      ],
    );
  }
}

/// One of the dock's tools.
class _DockTool extends StatelessWidget {
  const new({
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
    return Padding(
      padding: const EdgeInsets.only(right: 2),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: selected ? colors.accentTint : Colors.transparent,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          child: InkWell(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            onTap: onTap,
            child: SizedBox.square(dimension: 40, child: Center(child: child)),
          ),
        ),
      ),
    );
  }
}
