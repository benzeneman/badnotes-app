import 'dart:async';

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:badnotes/components/canvas/shape_style.dart';
import 'package:badnotes/components/editor_ui/bar_color_row.dart';
import 'package:badnotes/components/editor_ui/color_panel.dart';
import 'package:badnotes/components/editor_ui/floating_toolbar.dart';
import 'package:badnotes/components/editor_ui/option_previews.dart';
import 'package:badnotes/components/editor/text_box_overlay.dart';
import 'package:badnotes/components/editor_ui/text_format_bar.dart';
import 'package:badnotes/components/editor_ui/tool_panel.dart';
import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/toolbar/pen_modal.dart';
import 'package:badnotes/components/ui/bn_tool_panels.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/tools/_tool.dart';
import 'package:badnotes/data/tools/eraser.dart';
import 'package:badnotes/data/tools/highlighter.dart';
import 'package:badnotes/data/tools/laser_pointer.dart';
import 'package:badnotes/data/tools/pen.dart';
import 'package:badnotes/data/tools/pencil.dart';
import 'package:badnotes/data/tools/select.dart';
import 'package:badnotes/data/tools/shape_pen.dart';
import 'package:badnotes/data/tools/tape.dart';
import 'package:badnotes/data/tools/tape_pattern.dart';
import 'package:sbn/tool_id.dart';

typedef _PenKind = ({Pen pen, IconData icon, String name});

/// The options bar of the tool in use, floating over the page: the writing
/// tools with their sizes and colors, the shapes, the eraser, the laser or
/// the lasso. Tapping the chosen option again opens its settings.
///
/// It's a [ToolSubBar] in a [FloatingToolbar], so it can be dragged to any
/// edge.
class ToolFloatingBar extends StatelessWidget {
  const new({
    super.key,
    required this.currentTool,
    required this.setTool,
    required this.setColor,
    required this.invert,
    required this.clearPage,
    required this.removeAllTape,
    this.writingTools = true,
    this.dock,
  });

  final Tool currentTool;
  final ValueChanged<Tool> setTool;
  final ValueChanged<Color> setColor;

  /// The tool dock's contents along an axis. With it, the dock and the tool's
  /// sub-bar float together: the sub-bar on the page's side of the dock, and
  /// the writing tools are in the dock.
  final Widget Function(Axis axis)? dock;

  /// Whether ink shows inverted on the page, as in dark mode.
  final bool invert;
  final VoidCallback clearPage;
  final VoidCallback removeAllTape;

  /// Whether the writing tools (pen, highlighter, pencil, draw shapes and
  /// tape) are buttons in the bar. Leave it on unless the tool dock has
  /// them; without them the pen's kind is a pill that opens its panel.
  final bool writingTools;

  /// The pens behind the one pen chip.
  static List<_PenKind> get penKinds => [
    (pen: Pen.currentPen, icon: Symbols.stylus_fountain_pen, name: 'Fountain'),
    (pen: Pen.currentBallpointPen, icon: Symbols.ink_pen, name: 'Ball'),
    (pen: Pen.currentBrushPen, icon: Symbols.brush, name: 'Brush'),
    (
      pen: Pen.currentCalligraphyPen,
      icon: Symbols.history_edu,
      name: 'Calligraphy',
    ),
  ];

  /// The design's line icon of a writing tool, as 24×24 path data.
  static String pathOf(Pen pen) => switch (pen.toolId) {
    ToolId.fountainPen => BnToolIcons.fountain,
    ToolId.ballpointPen => BnToolIcons.ballpoint,
    ToolId.brushPen => BnToolIcons.brush,
    ToolId.calligraphyPen => BnToolIcons.calligraphy,
    ToolId.highlighter => BnToolIcons.highlighter,
    ToolId.pencil => BnToolIcons.pencil,
    ToolId.shapePen => BnToolIcons.drawShapes,
    ToolId.tape => BnToolIcons.tape,
    _ => BnToolPaths.fountain,
  };

  /// The writing tool last used, which the pen button in the top bar picks.
  static Pen lastWritingTool = Pen.currentPen;

  /// The shape last drawn with the shapes button.
  static ShapeKind lastShapeKind = ShapeKind.rectangle;

  /// Whether [tool] is one of the writing bar's tools.
  static bool isWritingTool(Tool tool) =>
      tool is Pen && (tool is! ShapePen || ShapePen.kind == ShapeKind.auto);

  /// Saves the options of [pen], which are edited in place.
  static void saveOptions(Pen pen) {
    switch (pen.toolId) {
      case ToolId.fountainPen:
        stows.lastFountainPenOptions.notifyListeners();
      case ToolId.ballpointPen:
        stows.lastBallpointPenOptions.notifyListeners();
      case ToolId.brushPen:
        stows.lastBrushPenOptions.notifyListeners();
      case ToolId.calligraphyPen:
        stows.lastCalligraphyPenOptions.notifyListeners();
      case ToolId.highlighter:
        stows.lastHighlighterOptions.notifyListeners();
      case ToolId.pencil:
        stows.lastPencilOptions.notifyListeners();
      case ToolId.shapePen:
        stows.lastShapePenOptions.notifyListeners();
      default:
    }
  }

  /// Whether [tool] has a bar at all.
  static bool hasBar(Tool tool) =>
      tool == Tool.textEditing ||
      tool is Eraser ||
      tool is LaserPointer ||
      tool is Select ||
      tool is Pen;

  @override
  Widget build(BuildContext context) {
    if (dock != null) return _withDock(context, dock!);
    if (!hasBar(currentTool)) return const SizedBox.shrink();
    // phones start with the bar at the bottom, in reach of the thumb
    final defaultEdge = MediaQuery.sizeOf(context).width < 600
        ? ToolbarEdge.bottom
        : ToolbarEdge.top;
    // read as the bar is laid out, after a drag to another edge too
    ToolbarEdge edge() => stows.floatingToolbarEdge.value < 0
        ? defaultEdge
        : FloatingToolbar.savedEdge;
    return FloatingToolbar(
      defaultEdge: defaultEdge,
      builder: (context, axis) => ToolSubBar(
        currentTool: currentTool,
        setTool: setTool,
        setColor: setColor,
        invert: invert,
        clearPage: clearPage,
        removeAllTape: removeAllTape,
        axis: axis,
        framed: false,
        writingTools: writingTools,
        opensUp: edge() == ToolbarEdge.bottom,
      ),
    );
  }
}

extension on ToolFloatingBar {
  /// The tool dock with the sub-bar beside it, in one floating bar that
  /// lives at the top on a tablet, the bottom on a phone, unless moved
  /// (design M_Editor, M_EditorTop).
  Widget _withDock(BuildContext context, Widget Function(Axis axis) dock) {
    return FloatingToolbar(
      defaultEdge: MediaQuery.sizeOf(context).width < 600
          ? ToolbarEdge.bottom
          : ToolbarEdge.top,
      framed: false,
      builder: (context, axis) {
        final edge = FloatingToolbar.edgeOf(context);
        final vertical = axis == Axis.vertical;
        final subBar = ToolFloatingBar.hasBar(currentTool)
            ? ToolSubBar(
                currentTool: currentTool,
                setTool: setTool,
                setColor: setColor,
                invert: invert,
                clearPage: clearPage,
                removeAllTape: removeAllTape,
                axis: axis,
                writingTools: false,
                opensUp: edge == ToolbarEdge.bottom,
              )
            : null;
        final bar = Flex(
          direction: vertical ? Axis.horizontal : Axis.vertical,
          mainAxisSize: MainAxisSize.min,
          // the sub-bar on the page's side of the dock
          verticalDirection: edge == ToolbarEdge.bottom
              ? VerticalDirection.up
              : VerticalDirection.down,
          textDirection: edge == ToolbarEdge.right
              ? TextDirection.rtl
              : TextDirection.ltr,
          children: [
            BnToolDock(vertical: vertical, children: [dock(axis)]),
            if (subBar != null) ...[const SizedBox.square(dimension: 8), subBar],
          ],
        );
        // "Hide while writing": out of the way while a stroke is drawn
        return ValueListenableBuilder(
          valueListenable: stows.toolbarAutoHide,
          builder: (context, autoHide, _) => !autoHide
              ? bar
              : ValueListenableBuilder(
                  valueListenable: EditorSignals.drawing,
                  builder: (context, drawing, _) => IgnorePointer(
                    ignoring: drawing,
                    child: AnimatedOpacity(
                      opacity: drawing ? 0 : 1,
                      duration: drawing
                          ? const Duration(milliseconds: 120)
                          : BnMotion.normal,
                      child: bar,
                    ),
                  ),
                ),
        );
      },
    );
  }
}

/// The sub-bar of the tool in use (design §3): a variant pill, its sizes,
/// colors and more. On its own it draws its white frame; in a
/// [FloatingToolbar], which draws one, pass `framed: false`.
class ToolSubBar extends StatefulWidget {
  const new({
    super.key,
    required this.currentTool,
    required this.setTool,
    required this.setColor,
    required this.invert,
    required this.clearPage,
    required this.removeAllTape,
    this.axis = Axis.horizontal,
    this.framed = true,
    this.writingTools = true,
    this.opensUp = true,
  });

  final Tool currentTool;
  final ValueChanged<Tool> setTool;
  final ValueChanged<Color> setColor;
  final bool invert;
  final VoidCallback clearPage;
  final VoidCallback removeAllTape;
  final Axis axis;
  final bool framed;

  /// See [ToolFloatingBar.writingTools].
  final bool writingTools;

  /// Whether its panels open above it (the bar at the bottom): the pills'
  /// chevrons point that way.
  final bool opensUp;

  @override
  State<ToolSubBar> createState() => _ToolSubBarState();
}

class _ToolSubBarState extends State<ToolSubBar> {
  Tool get tool => widget.currentTool;
  Axis get axis => widget.axis;
  bool get _vertical => axis == Axis.vertical;

  _PenKind get _penKind {
    final kinds = ToolFloatingBar.penKinds;
    for (final kind in kinds) {
      if (kind.pen == tool) return kind;
    }
    for (final kind in kinds) {
      if (kind.pen == ToolFloatingBar.lastWritingTool) return kind;
    }
    return kinds.first;
  }

  void _open(BuildContext chip, PanelPage page) =>
      showToolPanel(chip, anchor: rectOf(chip), page: page).whenComplete(() {
        if (tool is Pen) ToolFloatingBar.saveOptions(tool as Pen);
        if (mounted) setState(() {});
      });

  void _choose(Tool next) {
    if (next is Pen && ToolFloatingBar.isWritingTool(next)) {
      ToolFloatingBar.lastWritingTool = next;
    }
    widget.setTool(next);
  }

  Widget get _divider => BnBarDivider(vertical: _vertical);

  /// A tool option that's picked by [pick], or opens [settings] once it's
  /// picked: a pill with its name, or a square on a bar that runs down.
  Widget _pill({
    required String label,
    required bool selected,
    required VoidCallback pick,
    String? path,
    String? tooltip,
    PanelPage Function()? settings,
    bool dashed = false,
    bool dot = false,
  }) => Builder(
    builder: (chip) {
      Widget dotted(Widget child) => !dot
          ? child
          : Stack(
              clipBehavior: Clip.none,
              children: [
                child,
                const Positioned(top: 2, right: 2, child: _FilterDot()),
              ],
            );
      void onTap() {
        if (selected && settings != null) {
          _open(chip, settings());
        } else {
          pick();
        }
      }

      if (_vertical) {
        return dotted(BnSubButton(
          tooltip: tooltip ?? label,
          selected: selected,
          tinted: true,
          onTap: onTap,
          child: BnPathIcon(
            path ?? BnToolPaths.fountain,
            size: 19,
            strokeWidth: 2,
            dashed: dashed,
            color: selected
                ? BadNotesColors.of(context).accentStrong
                : BadNotesColors.of(context).text2,
          ),
        ));
      }
      return dotted(BnToolPill(
        label: label,
        path: path,
        tooltip: tooltip,
        selected: selected,
        chevron: selected && settings != null,
        up: widget.opensUp,
        onTap: onTap,
      ));
    },
  );

  /// A square tool button that picks [pick], or opens [settings] once it's
  /// picked.
  Widget _toolButton({
    required String path,
    required String tooltip,
    required bool selected,
    required VoidCallback pick,
    PanelPage Function()? settings,
  }) => Builder(
    builder: (chip) => BnSubButton(
      path: path,
      tooltip: tooltip,
      selected: selected,
      tinted: true,
      onTap: () {
        if (selected && settings != null) {
          _open(chip, settings());
        } else {
          pick();
        }
      },
    ),
  );

  Widget _bar(List<Widget> children) {
    if (widget.framed) return BnSubBar(vertical: _vertical, children: children);
    return RepaintBoundary(
      child: Flex(
        direction: axis,
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = tool;
    if (t == Tool.textEditing) return _bar(_textItems());
    if (t is Eraser) return _bar(_eraserItems());
    if (t is LaserPointer) return _bar(_laserItems());
    if (t is Select) return _bar(_lassoItems());
    if (t is ShapePen && ShapePen.kind != ShapeKind.auto) {
      return _bar(_shapesItems());
    }
    if (t is Pen) return _bar(_writingItems(t));
    return const SizedBox.shrink();
  }

  // ---- text ----

  List<Widget> _textItems() => [
    TextFormatBar(
      axis: axis,
      format: TextBoxOverlay.lastFormat,
      onChanged: (f) => setState(() => TextBoxOverlay.lastFormat = f),
    ),
    _divider,
    _vertical
        ? BnSubButton(
            path: BnToolPaths.pin,
            tooltip: 'Pin Text Tool',
            selected: stows.pinTextTool.value,
            onTap: () => setState(
              () => stows.pinTextTool.value = !stows.pinTextTool.value,
            ),
          )
        : BnToolPill(
            label: 'Pin text tool',
            tooltip: 'Pin Text Tool',
            path: BnToolPaths.pin,
            chevron: false,
            selected: stows.pinTextTool.value,
            onTap: () => setState(
              () => stows.pinTextTool.value = !stows.pinTextTool.value,
            ),
          ),
  ];

  // ---- writing tools ----

  List<Widget> _writingItems(Pen pen) {
    final kind = _penKind;
    final drawShape = pen is ShapePen;
    final isPenKind = ToolFloatingBar.penKinds.any((k) => k.pen == pen);
    return [
      if (widget.writingTools) ...[
        _toolButton(
          path: ToolFloatingBar.pathOf(kind.pen),
          tooltip: '${kind.name} pen',
          selected: kind.pen == pen,
          pick: () => _choose(kind.pen),
          settings: () => _penPage(kind.pen),
        ),
        _toolButton(
          path: BnToolIcons.highlighter,
          tooltip: 'Highlighter',
          selected: pen is Highlighter,
          pick: () => _choose(Highlighter.currentHighlighter),
          settings: _highlighterPage,
        ),
        _toolButton(
          path: BnToolIcons.pencil,
          tooltip: 'Pencil',
          selected: pen is Pencil,
          pick: () => _choose(Pencil.currentPencil),
          settings: _pencilPage,
        ),
        _toolButton(
          path: BnToolIcons.drawShapes,
          tooltip: 'Draw shapes',
          selected: drawShape,
          pick: () {
            ShapePen.kind = ShapeKind.auto;
            _choose(ShapePen.currentShapePen);
          },
          settings: _drawShapePage,
        ),
        _toolButton(
          path: BnToolIcons.tape,
          tooltip: 'Tape',
          selected: pen is Tape,
          pick: () => _choose(Tape.currentTape),
          settings: _tapePage,
        ),
      ] else if (isPenKind)
        _pill(
          label: kind.name,
          path: _vertical ? ToolFloatingBar.pathOf(kind.pen) : null,
          tooltip: '${kind.name} pen',
          selected: true,
          pick: () => _choose(kind.pen),
          settings: () => _penPage(kind.pen),
        )
      else
        _pill(
          label: switch (pen) {
            Highlighter() => 'Highlighter',
            Pencil() => 'Pencil',
            ShapePen() => 'Draw shapes',
            Tape() => 'Tape',
            _ => pen.name,
          },
          path: ToolFloatingBar.pathOf(pen),
          selected: true,
          pick: () {},
          settings: switch (pen) {
            Highlighter() => _highlighterPage,
            Pencil() => _pencilPage,
            ShapePen() => _drawShapePage,
            Tape() => _tapePage,
            _ => null,
          },
        ),
      _divider,
      ..._sizes(pen),
      _divider,
      ..._colors(pen),
    ];
  }

  static BnSizeMark _markOf(Pen pen) => switch (pen) {
    Highlighter() || Tape() => BnSizeMark.bar,
    Pencil() || ShapePen() => BnSizeMark.dot,
    _ => BnSizeMark.line,
  };

  List<Widget> _sizes(Pen pen) {
    final slots = pen.sizeSlots;
    final chosen = pen.chosenSizeSlot;
    // against the pen's whole range, so changing one size leaves the
    // others' marks as they were
    final range = pen.sizeMax - pen.sizeMin;
    final mark = _markOf(pen);
    return [
      for (final (slot, size) in slots.indexed)
        Builder(
          builder: (chip) => BnToolSize(
            tooltip: 'Size ${size.toStringAsFixed(1)}',
            mark: mark,
            line: pen.inkLineOf(slot),
            extent: range <= 0 ? 0.5 : (size - pen.sizeMin) / range,
            selected: slot == chosen,
            onTap: () {
              if (slot == chosen) {
                _open(chip, _sizePage(pen));
              } else {
                setState(() => pen.chooseSizeSlot(slot));
                ToolFloatingBar.saveOptions(pen);
              }
            },
          ),
        ),
    ];
  }

  /// The size of the chosen slot, which the bar shows as it changes; and
  /// for the pens, its line.
  PanelPage _sizePage(Pen pen) => PanelPage(
    title: 'Size',
    width: 300,
    builder: (context, setPanelState) {
      void update(VoidCallback change) {
        setPanelState(change);
        // the bar under the panel too, live
        if (mounted) setState(() {});
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PanelSliderRow(
            title: 'Thickness',
            value: pen.options.size,
            min: pen.sizeMin,
            max: pen.sizeMax,
            valueText: pen.options.size.toStringAsFixed(1),
            onChanged: (v) => update(() => pen.setSize(v)),
          ),
          if (pen.hasInkLine) ...[
            const PanelSection('Stroke style', top: 14),
            PanelSegmented(
              labels: const ['Solid', 'Dashed', 'Dotted'],
              index: switch (pen.inkLine) {
                ShapeLine.dashed => 1,
                ShapeLine.dotted => 2,
                _ => 0,
              },
              onChanged: (i) => update(
                () => pen.inkLine = const [
                  ShapeLine.solid,
                  ShapeLine.dashed,
                  ShapeLine.dotted,
                ][i],
              ),
            ),
          ],
        ],
      );
    },
  );

  /// The tool's own row of colors, then a + that opens all of them. A
  /// preset picked there joins the end of the row.
  List<Widget> _colors(Pen pen) {
    final key = BarColors.keyOf(pen);
    final current = pen.color.withValues(alpha: 1);
    final saved = BarColors.of(
      key,
      // the first time: what the bar showed before rows of its own
      seed: pen is Tape
          ? Tape.defaultColors
          : pen is Highlighter
          ? BarColors.highlighterDefaults
          : BarColors.defaults,
    );
    // a dot being changed shows its new color at once, before it's saved
    final live = _liveSlot;
    final colors = live == null
        ? saved
        : [
            for (final c in saved)
              c.toARGB32() == live.from.withValues(alpha: 1).toARGB32()
                  ? live.to
                  : c,
          ];
    void pick(Color color) {
      if (pen is Tape) {
        pen.color = color;
        stows.tapeColor.value = color.toARGB32();
        setState(() {});
      } else {
        widget.setColor(color);
      }
    }

    // the + : a color chosen joins the end of the row
    void open(BuildContext dot) => _openColors(dot, pen, (color) {
      BarColors.add(key, color);
      pick(color);
    });

    // a dot of the row, tapped again: the color chosen takes its place,
    // live as it's chosen on the grid or wheel. The row is saved a moment
    // after the last change, not on every step of a drag round the wheel.
    void change(BuildContext dot, Color slot) {
      Timer? save;
      Color? latest;
      void commit() {
        save?.cancel();
        final to = latest;
        if (to == null) return;
        latest = null;
        BarColors.replace(key, slot, to);
        slot = to;
        if (mounted) setState(() => _liveSlot = null);
      }

      _openColors(dot, pen, (color) {
        pick(color);
        latest = color;
        setState(() => _liveSlot = (from: slot, to: color.withValues(alpha: 1)));
        save?.cancel();
        save = Timer(const Duration(milliseconds: 250), commit);
      }, replacing: true, onClosed: commit);
    }

    return [
      BarColorRow(
        colors: colors,
        current: current,
        axis: axis,
        invert: widget.invert,
        pick: pick,
        onReorder: (next) => setState(() => BarColors.set(key, next)),
        openPanel: change,
      ),
      Builder(builder: (dot) => BnAddColorDot(onTap: () => open(dot))),
    ];
  }

  /// The bar dot being changed in the color panel, and its color so far.
  ({Color from, Color to})? _liveSlot;

  void _openColors(
    BuildContext anchor,
    Pen pen,
    ValueChanged<Color> pick, {
    bool replacing = false,
    VoidCallback? onClosed,
  }) {
    final shapes = pen is ShapePen;
    ColorPanel.show(
      anchor,
      anchor: rectOf(anchor),
      title: replacing ? 'Change color' : 'Color',
      color: pen.color.withValues(alpha: 1),
      presets: pen is Tape ? Tape.colors : ColorPanel.defaultPresets,
      onChanged: pick,
      replacing: replacing,
      fill: shapes
          ? (
              on: stows.shapeFill.value,
              opacity: stows.shapeFillOpacity.value,
              setOn: (on) => stows.shapeFill.value = on,
              setOpacity: (v) => stows.shapeFillOpacity.value = v,
            )
          : null,
    ).whenComplete(() {
      onClosed?.call();
      if (mounted) setState(() {});
    });
  }

  /// The pen's line in a light well, as it draws now.
  Widget _preview(Pen pen) => ClipRRect(
    borderRadius: const BorderRadius.all(Radius.circular(12)),
    child: SizedBox(
      height: 76,
      child: CustomPaint(
        painter: PenSamplePainter(
          pen,
          paper: widget.invert ? BnColors.previewBgDark : BnColors.previewBg,
          invert: widget.invert,
        ),
      ),
    ),
  );

  PanelPage _penPage(Pen first) {
    var pen = first;
    // the kind's name in the title row, which the page below changes
    final name = ValueNotifier(_nameOf(first));
    return PanelPage(
      title: 'Pen',
      width: 320,
      trailing: (context) => ValueListenableBuilder(
        valueListenable: name,
        builder: (context, name, _) => Text(
          name,
          style: BnType.caption.copyWith(
            color: BadNotesColors.of(context).muted,
          ),
        ),
      ),
      builder: (context, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _preview(pen),
          const SizedBox(height: 10),
          PanelChoiceCards<Pen>(
            choices: [
              for (final kind in ToolFloatingBar.penKinds)
                (
                  value: kind.pen,
                  icon: BnPathIcon(ToolFloatingBar.pathOf(kind.pen)),
                  label: kind.name,
                ),
            ],
            value: pen,
            onChanged: (next) => setState(() {
              pen = next;
              name.value = _nameOf(next);
              _choose(next);
            }),
          ),
          if (pen.toolId != ToolId.ballpointPen)
            PanelSliderRow(
            divisions: 5,
              title: 'Tip sharpness',
              value: pen.options.thinning.clamp(0.0, 0.9) / 0.9,
              onChanged: (v) => setState(() => pen.options.thinning = v * 0.9),
            ),
          if (pen.toolId == ToolId.fountainPen)
            PanelSliderRow(
            divisions: 5,
              title: 'Pressure sensitivity',
              value: pen.pressureEnabled
                  ? stows.fountainPressureAmount.value
                  : 0,
              onChanged: (v) => setState(() {
                stows.fountainPressureAmount.value = v;
                pen.pressureEnabled = v > 0;
                stows.fountainPenPressure.value = v > 0;
              }),
            ),
          PanelSliderRow(
            divisions: 5,
            title: 'Stabilization',
            value: pen.options.streamline.clamp(0.0, 0.95) / 0.95,
            onChanged: (v) =>
                setState(() => pen.options.streamline = v * 0.95),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 14, bottom: 4),
            child: SizedBox(
              height: 1,
              child: _Rule(),
            ),
          ),
          PanelNavRow(
            title: 'Pen settings',
            onTap: () => ToolPanel.push(context, _penSettingsPage()),
          ),
        ],
      ),
    );
  }

  String _nameOf(Pen pen) => ToolFloatingBar.penKinds
      .firstWhere((k) => k.pen == pen, orElse: () => _penKind)
      .name;

  PanelPage _penSettingsPage() => PanelPage(
    title: 'Pen settings',
    width: 340,
    builder: (context, setState) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PanelSwitchRow(
          title: 'Reduce latency',
          description: 'Ink appears faster under the pen tip.',
          value: stows.penReduceLatency.value,
          onChanged: (v) => setState(() => stows.penReduceLatency.value = v),
        ),
        PanelNavRow(
          title: 'Draw & hold',
          trailing: stows.penDrawAndHold.value ? 'On' : 'Off',
          onTap: () => ToolPanel.push(context, _drawAndHoldPage()),
        ),
        PanelNavRow(
          title: 'Scribble to erase',
          trailing: _scribbleOn ? 'On' : 'Off',
          onTap: () => ToolPanel.push(context, _scribblePage()),
        ),
        PanelNavRow(
          title: 'Circle to lasso',
          trailing: stows.circleToLasso.value ? 'On' : 'Off',
          onTap: () => ToolPanel.push(context, _circleToLassoPage()),
        ),
      ],
    ),
  );

  /// On only when every pen scribbles to erase: on when just the fountain
  /// pen did, the other pens didn't, and nothing said so.
  bool get _scribbleOn =>
      stows.penScribbleToErase.value && stows.fountainScribbleToErase.value;

  PanelPage _scribblePage() => PanelPage(
    title: 'Scribble to erase',
    width: 340,
    builder: (context, setState) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ScribblePreview(),
        PanelSwitchRow(
          title: 'Scribble to erase',
          value: _scribbleOn,
          onChanged: (v) => setState(() {
            stows.penScribbleToErase.value = v;
            stows.fountainScribbleToErase.value = v;
          }),
        ),
        PanelSwitchRow(
          title: 'Erase shapes & highlighter too',
          description:
              'Scribble over handwriting with any pen or the pencil to '
              'erase it.',
          value: stows.scribbleErasesAll.value,
          onChanged: (v) =>
              setState(() => stows.scribbleErasesAll.value = v),
        ),
      ],
    ),
  );

  PanelPage _circleToLassoPage() => PanelPage(
    title: 'Circle to lasso',
    width: 340,
    builder: (context, setState) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CircleLassoPreview(),
        PanelSwitchRow(
          title: 'Circle to lasso',
          description: 'Draw a loop around anything to select and move it.',
          value: stows.circleToLasso.value,
          onChanged: (v) => setState(() => stows.circleToLasso.value = v),
        ),
        PanelSwitchRow(
          title: 'Select partly circled ink',
          description:
              'Also pick strokes that stick out a little from the loop.',
          value: stows.lassoPartly.value,
          onChanged: (v) => setState(() => stows.lassoPartly.value = v),
        ),
      ],
    ),
  );

  PanelPage _drawAndHoldPage() => PanelPage(
    title: 'Draw & hold',
    width: 340,
    builder: (context, setState) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SnapPreview.circle(),
        PanelSwitchRow(
          title: 'Draw & hold',
          description:
              'Hold the pen still at the end of a stroke and it snaps into '
              'a neat shape.',
          value: stows.penDrawAndHold.value,
          onChanged: (v) => setState(() => stows.penDrawAndHold.value = v),
        ),
        const PanelSection('Advanced'),
        PanelSwitchRow(
          title: 'Fill color',
          value: stows.shapeFill.value,
          onChanged: (v) => setState(() => stows.shapeFill.value = v),
        ),
      ],
    ),
  );

  PanelPage _highlighterPage() {
    final pen = Highlighter.currentHighlighter;
    return PanelPage(
      title: 'Highlighter',
      width: 340,
      builder: (context, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _preview(pen),
          PanelSliderRow(
            divisions: 5,
            title: 'Opacity',
            value: stows.highlighterAlpha.value / 255,
            onChanged: (v) => setState(() {
              final alpha = (max(v, 0.1) * 255).round();
              stows.highlighterAlpha.value = alpha;
              pen.color = pen.color.withAlpha(alpha);
            }),
          ),
          PanelSliderRow(
            divisions: 5,
            title: 'Stabilization',
            value: pen.options.streamline.clamp(0.0, 0.95) / 0.95,
            onChanged: (v) =>
                setState(() => pen.options.streamline = v * 0.95),
          ),
          const BnDivider(),
          PanelSwitchRow(
            title: 'Straight line',
            value: stows.highlighterStraight.value,
            onChanged: (v) =>
                setState(() => stows.highlighterStraight.value = v),
          ),
          PanelSwitchRow(
            title: 'Only level or upright',
            description:
                'Locks the stroke to 0° or 90°: clean underlines every time.',
            value: stows.highlighterAxisLock.value,
            onChanged: (v) =>
                setState(() => stows.highlighterAxisLock.value = v),
          ),
        ],
      ),
    );
  }

  PanelPage _pencilPage() {
    final pen = Pencil.currentPencil;
    return PanelPage(
      title: 'Pencil',
      caption: 'Grainy and soft, for sketches',
      width: 320,
      builder: (context, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _preview(pen),
          PanelSliderRow(
            divisions: 5,
            title: 'Strength',
            value: stows.pencilAlpha.value / 255,
            onChanged: (v) => setState(() {
              final alpha = (max(v, 0.1) * 255).round();
              stows.pencilAlpha.value = alpha;
              pen.color = pen.color.withAlpha(alpha);
            }),
          ),
          const BnDivider(),
          PanelSwitchRow(
            title: 'Faster ink',
            description: 'Draws a quick preview first, then the full texture.',
            value: stows.penReduceLatency.value,
            onChanged: (v) => setState(() => stows.penReduceLatency.value = v),
          ),
        ],
      ),
    );
  }

  PanelPage _drawShapePage() => PanelPage(
    title: 'Draw shapes',
    caption: 'Sketch roughly and it becomes a clean shape',
    width: 340,
    builder: (context, setState) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SnapPreview.rectangle(),
        const BnDivider(),
        PanelSwitchRow(
          title: 'Fill shapes',
          value: stows.shapeFill.value,
          onChanged: (v) => setState(() => stows.shapeFill.value = v),
        ),
        PanelNavRow(
          title: 'Stroke settings',
          onTap: () => ToolPanel.push(context, _toolStrokePage()),
        ),
      ],
    ),
  );

  PanelPage _tapePage() {
    // the rest of the patterns, after "More patterns"
    var all = false;
    return PanelPage(
      title: 'Tape',
      caption: 'Cover answers, tap the tape to peek',
      width: 330,
      builder: (context, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // words covered, a tap to peek, covered again: as it's set now
          const TapePreview(),
          PanelSwitchRow(
            title: 'Straight tape',
            value: stows.tapeStraight.value,
            onChanged: (v) => setState(() => stows.tapeStraight.value = v),
          ),
          const PanelSection('Pattern', top: 8),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 92 / 40,
            padding: const EdgeInsets.all(4),
            children: [
              for (final pattern in TapePattern.values)
                if (pattern != TapePattern.custom &&
                    (all ||
                        Tape.defaultPatterns.contains(pattern) ||
                        // the one in use stays, wherever it's from
                        Tape.pattern == pattern))
                  _TapeTile(
                    pattern: pattern,
                    color: Tape.currentTape.color,
                    selected: Tape.pattern == pattern,
                    onTap: () => setState(() => Tape.pattern = pattern),
                  ),
              // the user's own, held to remove
              for (final doodle in stows.tapeDoodles.value)
                Builder(
                  builder: (tile) => _TapeTile(
                    pattern: TapePattern.custom,
                    doodle: doodle,
                    color: Tape.currentTape.color,
                    selected:
                        Tape.pattern == TapePattern.custom &&
                        stows.tapeDoodle.value == doodle,
                    onTap: () => setState(() {
                      Tape.pattern = TapePattern.custom;
                      stows.tapeDoodle.value = doodle;
                    }),
                    onLongPress: () async {
                      if (!await askRemoveColor(tile, label: 'Remove pattern')) {
                        return;
                      }
                      setState(() {
                        stows.tapeDoodles.value = [
                          for (final d in stows.tapeDoodles.value)
                            if (d != doodle) d,
                        ];
                        if (stows.tapeDoodle.value == doodle) {
                          stows.tapeDoodle.value = '';
                          if (Tape.pattern == TapePattern.custom) {
                            Tape.pattern = TapePattern.stripes;
                          }
                        }
                      });
                    },
                  ),
                ),
              Tooltip(
                message: 'Draw your own pattern',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => ToolPanel.push(
                    context,
                    PanelPage(
                      title: 'Your pattern',
                      caption: 'Draw what the tape repeats',
                      width: 330,
                      builder: (context, _) => _DoodlePad(
                        color: Tape.currentTape.color,
                        onSave: (doodle) {
                          stows.tapeDoodles.value = [
                            ...stows.tapeDoodles.value,
                            doodle,
                          ];
                          stows.tapeDoodle.value = doodle;
                          Tape.pattern = TapePattern.custom;
                          // back to the patterns, the new one chosen
                          ToolPanel.pop(context);
                        },
                      ),
                    ),
                  ),
                  child: CustomPaint(
                    painter: BnDashedCirclePainter(
                      BadNotesColors.of(context).disabled,
                    ),
                    child: Center(
                      child: Icon(
                        BnIcons.add,
                        size: 18,
                        color: BadNotesColors.of(context).text2,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          PanelNavRow(
            title: all ? 'Fewer patterns' : 'More patterns',
            chevron: false,
            onTap: () => setState(() => all = !all),
          ),
          const BnDivider(),
          PanelNavRow(
            title: 'Remove all tape on page',
            icon: BnIcons.trash,
            destructive: true,
            chevron: false,
            onTap: () {
              Navigator.pop(context);
              widget.removeAllTape();
            },
          ),
        ],
      ),
    );
  }

  // ---- shapes ----

  static String _shapePath(ShapeKind kind) => switch (kind) {
    ShapeKind.auto => BnToolPaths.autoShape,
    ShapeKind.line => BnToolPaths.line,
    ShapeKind.arrow => BnToolPaths.arrow,
    ShapeKind.elbow => BnToolPaths.elbow,
    ShapeKind.rectangle => BnToolPaths.rectangle,
    ShapeKind.ellipse => BnToolPaths.ellipse,
    ShapeKind.triangle => BnToolPaths.triangle,
    ShapeKind.pentagon => BnToolPaths.pentagon,
    ShapeKind.hexagon => BnToolPaths.hexagon,
    ShapeKind.star => BnToolPaths.star,
    ShapeKind.heart => BnToolPaths.heart,
  };

  List<Widget> _shapesItems() {
    final pen = ShapePen.currentShapePen;
    return [
      for (final kind in ShapeKind.values)
        if (kind != ShapeKind.auto)
          BnSubButton(
            path: _shapePath(kind),
            tooltip: kind.label,
            selected: ShapePen.kind == kind,
            tinted: true,
            onTap: () => setState(() {
              ShapePen.kind = kind;
              ToolFloatingBar.lastShapeKind = kind;
            }),
          ),
      _divider,
      Builder(
        builder: (chip) => BnSubButton(
          path: BnToolPaths.tune,
          iconSize: 18,
          tooltip: 'Stroke settings',
          selected: true,
          onTap: () => _open(chip, _toolStrokePage()),
        ),
      ),
      ..._colors(pen),
    ];
  }

  PanelPage _toolStrokePage() {
    final pen = ShapePen.currentShapePen;
    return shapeStrokePage(
      style: () => ShapePen.defaultStyle(pen.color),
      setStyle: (style) {
        stows.shapeLine.value = style.line.index;
        stows.shapeRounded.value = style.rounded;
        stows.shapeArrowStart.value = style.arrowStart.index;
        stows.shapeArrowEnd.value = style.arrowEnd.index;
      },
      width: () => pen.options.size,
      setWidth: pen.setSize,
      minWidth: pen.sizeMin,
      maxWidth: pen.sizeMax,
      color: pen.color,
    );
  }

  // ---- eraser ----

  static String _eraserPath(EraserType type) => switch (type) {
    EraserType.precision => BnToolPaths.precision,
    EraserType.stroke => BnToolPaths.wholeStroke,
  };

  static String _eraserName(EraserType type) => switch (type) {
    EraserType.precision => 'Precision',
    EraserType.stroke => 'Whole stroke',
  };

  List<Widget> _eraserItems() {
    final type = Eraser.type;
    return [
      _pill(
        label: _eraserName(type),
        path: _eraserPath(type),
        tooltip: 'Eraser type',
        selected: true,
        pick: () {},
        settings: _eraserTypePage,
      ),
      Builder(
        builder: (chip) => BnSubButton(
          path: BnToolPaths.tune,
          iconSize: 18,
          tooltip: 'Eraser settings',
          selected: true,
          onTap: () => _open(chip, _eraserSettingsPage()),
        ),
      ),
      _divider,
      for (final (i, size) in Eraser.sizes.indexed)
        BnToolSize(
          tooltip: const ['Small', 'Medium', 'Large'][i.clamp(0, 2)],
          mark: BnSizeMark.ring,
          extent: Eraser.sizes.length < 2 ? 0.5 : i / (Eraser.sizes.length - 1),
          selected: Eraser.screenRadius == size,
          onTap: () => setState(() => Eraser.screenRadius = size),
        ),
    ];
  }

  PanelPage _eraserTypePage() => PanelPage(
    title: 'Eraser type',
    width: 330,
    builder: (context, setState) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EraserPreview(Eraser.type),
        const SizedBox(height: 10),
        PanelChoiceCards<EraserType>(
          gap: 8,
          choices: [
            for (final type in EraserType.values)
              (
                value: type,
                icon: BnPathIcon(_eraserPath(type), strokeWidth: 2),
                label: _eraserName(type),
              ),
          ],
          value: Eraser.type,
          onChanged: (v) {
            setState(() => Eraser.type = v);
            this.setState(() {});
          },
        ),
        const SizedBox(height: 10),
        BnPanelCaption(Eraser.type.description),
      ],
    ),
  );

  PanelPage _eraserSettingsPage() {
    const groups = ['pen', 'pencil', 'highlighter', 'tape'];
    return PanelPage(
      title: 'Erase only',
      width: 330,
      // the link and the switches both follow the saved filter
      trailing: (context) => ValueListenableBuilder(
        valueListenable: stows.eraserFilter,
        builder: (context, chosen, _) {
          final all = groups.every(chosen.contains);
          return BnPanelLink(
            label: all ? 'Deselect all' : 'Select all',
            onTap: () => stows.eraserFilter.value = all ? <String>[] : groups,
          );
        },
      ),
      builder: (context, setState) => ValueListenableBuilder(
        valueListenable: stows.eraserFilter,
        builder: (context, chosen, _) {
          Widget filter(String group, String title) => PanelSwitchRow(
            title: title,
            value: chosen.contains(group),
            onChanged: (on) => stows.eraserFilter.value = [
              for (final g in stows.eraserFilter.value)
                if (g != group) g,
              if (on) group,
            ],
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              filter('pen', 'Pen'),
              filter('pencil', 'Pencil'),
              filter('highlighter', 'Highlighter'),
              filter('tape', 'Tape'),
              const BnDivider(vertical: 6),
              PanelSwitchRow(
                title: 'Back to last tool after erasing',
                value: stows.disableEraserAfterUse.value,
                onChanged: (v) =>
                    setState(() => stows.disableEraserAfterUse.value = v),
              ),
              PanelNavRow(
                title: 'Clear page',
                icon: BnIcons.trash,
                destructive: true,
                chevron: false,
                onTap: () {
                  Navigator.pop(context);
                  widget.clearPage();
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // ---- laser ----

  static const _laserColors = <Color>[
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple,
  ];

  static const _holdTimes = [300, 1000, 3000, 5000];

  PanelPage _laserPage() {
    final laser = LaserPointer.currentLaserPointer;
    return PanelPage(
      title: 'Laser',
      caption: 'For presenting: leaves no ink behind',
      width: 330,
      builder: (context, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LaserPreview(
            dot: laser.dotMode,
            color: laser.color,
            glow: laser.glow,
          ),
          const SizedBox(height: 10),
          PanelChoiceCards<bool>(
            gap: 8,
            choices: [
              (
                value: false,
                icon: const BnPathIcon(BnToolPaths.laserLine, strokeWidth: 2),
                label: 'Line laser',
              ),
              (
                value: true,
                icon: _LaserDot(color: laser.color, size: 14),
                label: 'Dot pointer',
              ),
            ],
            value: laser.dotMode,
            onChanged: (dot) {
              setState(() => laser.dotMode = dot);
              this.setState(() {});
            },
          ),
          const PanelSection('Line stays for'),
          PanelSegmented(
            labels: const ['0.3 s', '1 s', '3 s', '5 s'],
            index: max(_holdTimes.indexOf(laser.holdMillis), 0),
            onChanged: (i) => setState(() => laser.holdMillis = _holdTimes[i]),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 14, bottom: 4),
            child: SizedBox(height: 1, child: _Rule()),
          ),
          BnToggleRow(
            label: 'Glow effect',
            value: laser.glow,
            onChanged: (on) => setState(() => laser.glow = on),
          ),
        ],
      ),
    );
  }

  List<Widget> _laserItems() {
    final laser = LaserPointer.currentLaserPointer;
    return [
      _pill(
        label: laser.dotMode ? 'Dot pointer' : 'Line laser',
        path: BnToolPaths.laserLine,
        tooltip: 'Line',
        selected: !laser.dotMode,
        pick: () => setState(() => laser.dotMode = false),
        settings: _laserPage,
      ),
      _divider,
      for (final color in _laserColors)
        BnColorDot(
          color: color,
          selected: laser.color.toARGB32() == color.toARGB32(),
          onTap: () => widget.setColor(color),
        ),
    ];
  }

  // ---- lasso ----

  void _toggleLassoGroup(String group, bool on) {
    stows.lassoFilter.value = [
      for (final g in stows.lassoFilter.value)
        if (g != group) g,
      if (on) group,
    ];
  }

  List<Widget> _lassoItems() {
    // some kinds won't be picked up: a dot on the lasso says so
    // by name, so an old saved list (other names, repeats) doesn't show it
    final dot = const [
      'handwriting',
      'images',
      'shapes',
      'arrows',
      'textBoxes',
      'tape',
      'stickyNotes',
    ].any((group) => !stows.lassoFilter.value.contains(group));
    return [
      _pill(
        label: 'Freeform',
        path: BnToolIcons.lasso,
        dashed: true,
        tooltip: 'Freehand lasso',
        selected: !Select.rectangleMode,
        pick: () => setState(() => Select.rectangleMode = false),
        settings: _lassoPage,
        dot: dot,
      ),
      _pill(
        label: 'Rectangle',
        path: BnToolPaths.rectangleLasso,
        tooltip: 'Rectangular lasso',
        selected: Select.rectangleMode,
        pick: () => setState(() => Select.rectangleMode = true),
        settings: _lassoPage,
        dot: dot,
      ),
    ];
  }

  PanelPage _lassoPage() => PanelPage(
    title: 'Lasso',
    width: 340,
    builder: (context, setState) {
      Widget include(String group, String title) => PanelSwitchRow(
        title: title,
        value: stows.lassoFilter.value.contains(group),
        onChanged: (on) {
          setState(() => _toggleLassoGroup(group, on));
          this.setState(() {}); // the dot on the bar
        },
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // what a loop picks up, from the switches below as they are now
          const LassoPreview(),
          const SizedBox(height: 10),
          PanelChoiceCards<bool>(
            gap: 8,
            choices: const [
              (
                value: false,
                icon: BnPathIcon(BnToolIcons.lasso, dashed: true),
                label: 'Freeform',
              ),
              (
                value: true,
                icon: BnPathIcon(BnToolPaths.rectangleLasso, dashed: true),
                label: 'Rectangle',
              ),
            ],
            value: Select.rectangleMode,
            onChanged: (v) {
              setState(() => Select.rectangleMode = v);
              this.setState(() {});
            },
          ),
          const PanelSection('Included in selection'),
          include('handwriting', 'Handwriting'),
          include('images', 'Images'),
          include('shapes', 'Shapes'),
          include('arrows', 'Arrows'),
          include('textBoxes', 'Text boxes'),
          include('tape', 'Tape'),
          include('stickyNotes', 'Sticky notes'),
        ],
      );
    },
  );
}

/// How the sub-bar ends: all the colours as a rainbow (pens), a dashed
/// plus (the other tools), or nothing (shapes).

/// On the lasso when some kinds of things won't be picked up.
class _FilterDot extends StatelessWidget {
  const _FilterDot();

  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(
      color: const Color(0xFFE8710A),
      shape: BoxShape.circle,
      border: Border.all(color: BadNotesColors.of(context).surface, width: 1.5),
    ),
  );
}

/// A 1 px line in the divider colour, as wide as it can be.
class _Rule extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: BadNotesColors.of(context).divider);
}

/// The laser's dot, glowing in its colour.
class _LaserDot extends StatelessWidget {
  const new({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: color, blurRadius: size * 0.7)],
    ),
  );
}

/// One tape design to pick, drawn in the tape's colour.
class _TapeTile extends StatelessWidget {
  const new({
    required this.pattern,
    required this.color,
    required this.selected,
    required this.onTap,
    this.onLongPress,
    this.doodle,
  });

  final TapePattern pattern;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  /// What a [TapePattern.custom] tile prints.
  final String? doodle;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '${pattern.name} tape',
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: AnimatedContainer(
          duration: BnMotion.fast,
          curve: BnMotion.curve,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(6)),
            boxShadow: selected
                ? [
                    BoxShadow(color: colors.surface, spreadRadius: 2),
                    BoxShadow(color: colors.accent, spreadRadius: 4),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(6)),
            child: CustomPaint(
              painter: TapeSamplePainter(color, pattern, doodle: doodle),
            ),
          ),
        ),
      ),
    );
  }
}

/// A square to draw a tape's own pattern in, and the tape it makes.
class _DoodlePad extends StatefulWidget {
  const _DoodlePad({required this.color, required this.onSave});

  final Color color;
  final ValueChanged<String> onSave;

  @override
  State<_DoodlePad> createState() => _DoodlePadState();
}

class _DoodlePadState extends State<_DoodlePad> {
  final _lines = <List<Offset>>[];

  /// The pad's points from -0.5 to 0.5 across, as the tape keeps them.
  Offset _unit(Offset local, double side) => Offset(
    (local.dx / side - 0.5).clamp(-0.5, 0.5),
    (local.dy / side - 0.5).clamp(-0.5, 0.5),
  );

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final doodle = TapePattern.encodeDoodle(_lines);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final side = min(constraints.maxWidth, 220.0);
              return GestureDetector(
                onPanStart: (d) => setState(
                  () => _lines.add([_unit(d.localPosition, side)]),
                ),
                onPanUpdate: (d) {
                  // a point only every so often: hundreds made the tape lag
                  final p = _unit(d.localPosition, side);
                  if ((p - _lines.last.last).distance < 0.015) return;
                  setState(() => _lines.last.add(p));
                },
                child: Container(
                  width: side,
                  height: side,
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.hairline),
                  ),
                  child: CustomPaint(painter: _DoodlePainter(_lines, widget.color)),
                ),
              );
            },
          ),
        ),
        // the tape it makes
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 40,
            child: CustomPaint(
              painter: TapeSamplePainter(
                widget.color,
                TapePattern.custom,
                doodle: doodle,
              ),
            ),
          ),
        ),
        Row(
          spacing: 8,
          children: [
            TextButton(
              onPressed: _lines.isEmpty
                  ? null
                  : () => setState(() => _lines.removeLast()),
              child: const Text('Undo'),
            ),
            TextButton(
              onPressed: _lines.isEmpty ? null : () => setState(_lines.clear),
              child: const Text('Clear'),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _lines.isEmpty
                  ? null
                  : () {
                      widget.onSave(doodle);
                      setState(_lines.clear);
                    },
              child: const Text('Save pattern'),
            ),
          ],
        ),
      ],
    );
  }
}

class _DoodlePainter extends CustomPainter {
  _DoodlePainter(this.lines, this.color);

  final List<List<Offset>> lines;

  /// The tape's.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.09 * 0.85
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color.computeLuminance() > 0.55
          ? const Color(0x66000000)
          : const Color(0xCCFFFFFF);
    for (final line in lines) {
      final points = [
        for (final p in line)
          Offset((p.dx + 0.5) * size.width, (p.dy + 0.5) * size.height),
      ];
      if (points.length == 1) {
        canvas.drawCircle(points.first, paint.strokeWidth / 2, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
        continue;
      }
      canvas.drawPath(Path()..addPolygon(points, false), paint);
    }
  }

  @override
  bool shouldRepaint(_DoodlePainter old) => true;
}

/// Line style, width, corners and arrowheads of a shape: of the shape tool,
/// or of the selected shapes. Each choice shows what it draws, and the
/// preview on top all of them together, in [color].
PanelPage shapeStrokePage({
  required ShapeStyle Function() style,
  required ValueChanged<ShapeStyle> setStyle,
  required double Function() width,
  required ValueChanged<double> setWidth,
  required double minWidth,
  required double maxWidth,
  Color color = const Color(0xFF1C1C1E),
}) => PanelPage(
  title: 'Stroke settings',
  width: 340,
  builder: (context, setState) {
    final s = style();
    void update(ShapeStyle next) => setState(() => setStyle(next));
    const lines = {
      ShapeLine.none: 'None',
      ShapeLine.solid: 'Solid',
      ShapeLine.dashed: 'Dashed',
      ShapeLine.dotted: 'Dotted',
    };
    const arrows = {
      ShapeArrow.none: 'None',
      ShapeArrow.open: 'Open',
      ShapeArrow.filled: 'Filled',
    };
    Widget arrowTiles(ShapeArrow value, bool start) => BnTypeCards<ShapeArrow>(
      height: 52,
      choices: [
        for (final MapEntry(key: arrow, value: label) in arrows.entries)
          (
            value: arrow,
            icon: _StrokeSample(
              start
                  ? ShapeStyle(arrowStart: arrow)
                  : ShapeStyle(arrowEnd: arrow),
            ),
            label: label,
          ),
      ],
      value: value,
      onChanged: (arrow) => update(
        start ? s.copyWith(arrowStart: arrow) : s.copyWith(arrowEnd: arrow),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // all of it together, as it will be drawn
        ShapeStylePreview(style: s, color: color, width: width()),
        const PanelSection('Line'),
        BnTypeCards<ShapeLine>(
          height: 52,
          choices: [
            for (final MapEntry(key: line, value: label) in lines.entries)
              (
                value: line,
                icon: _StrokeSample(ShapeStyle(line: line)),
                label: label,
              ),
          ],
          value: s.line,
          onChanged: (line) => update(s.copyWith(line: line)),
        ),
        PanelSliderRow(
          title: 'Width',
          value: width(),
          min: minWidth,
          max: maxWidth,
          valueText: width().toStringAsFixed(1),
          onChanged: (v) => setState(() => setWidth(v)),
        ),
        PanelSwitchRow(
          title: 'Rounded corners',
          value: s.rounded,
          onChanged: (v) => update(s.copyWith(rounded: v)),
        ),
        const PanelSection('Start arrow', top: 6),
        arrowTiles(s.arrowStart, true),
        const PanelSection('End arrow'),
        arrowTiles(s.arrowEnd, false),
      ],
    );
  },
);

/// A short line drawn in [style], in the tile's icon colour.
class _StrokeSample extends StatelessWidget {
  const new(this.style);

  final ShapeStyle style;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 44,
    height: 18,
    child: CustomPaint(
      painter: _StrokeSamplePainter(
        style,
        IconTheme.of(context).color ?? BadNotesColors.of(context).text2,
      ),
    ),
  );
}

class _StrokeSamplePainter extends CustomPainter {
  _StrokeSamplePainter(this.style, this.color);

  final ShapeStyle style;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final line = Path()
      ..moveTo(3, y)
      ..lineTo(size.width - 3, y);
    if (style.line == ShapeLine.none) {
      // no line: just where it would be, faintly
      canvas.drawPath(
        line,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = color.withValues(alpha: 0.25),
      );
      return;
    }
    paintStyledPath(canvas, line, style, color, 2);
  }

  @override
  bool shouldRepaint(_StrokeSamplePainter old) =>
      old.style != style || old.color != color;
}
