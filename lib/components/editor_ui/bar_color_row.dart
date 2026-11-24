import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:badnotes/components/editor_ui/color_panel.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/extensions/color_extensions.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/tools/highlighter.dart';
import 'package:badnotes/data/tools/pen.dart';
import 'package:badnotes/data/tools/pencil.dart';
import 'package:badnotes/data/tools/shape_pen.dart';
import 'package:badnotes/data/tools/tape.dart';

/// Each tool's own colors in the floating bar, kept in [stows.barColors].
abstract final class BarColors {
  static const lightBlue = Color(0xFF7FB2F0);
  static const lightYellow = Color(0xFFFFE066);

  /// The highlighter's: light yellow and pink in place of black and white,
  /// which make no highlight.
  static const highlighterDefaults = [
    lightYellow,
    Color(0xFFFFA8C5),
    lightBlue,
    Color(0xFFB9A3F2),
    Color(0xFF7DD3C7),
  ];

  /// A new install's colors, for the pens and the highlighter alike: black,
  /// white, light blue, light violet, light teal.
  static const defaults = [
    Color(0xFF000000),
    Color(0xFFFFFFFF),
    lightBlue,
    Color(0xFFB9A3F2),
    Color(0xFF7DD3C7),
  ];

  /// The row [pen]'s colors are in: the four pens share one.
  static String keyOf(Pen pen) => switch (pen) {
    Tape() => 'tape',
    Highlighter() => 'highlighter',
    Pencil() => 'pencil',
    ShapePen() => 'shapes',
    _ => 'pen',
  };

  /// The colors in [key]'s row, filled with [seed] the first time.
  static List<Color> of(String key, {List<Color> seed = const []}) {
    if (!stows.barColors.value.contains('$key:')) _write(key, seed);
    return [
      for (final s in stows.barColors.value)
        if (s.startsWith('$key:'))
          if (int.tryParse(s.substring(key.length + 1)) case final v?) Color(v),
    ];
  }

  static void set(String key, List<Color> colors) => _write(key, colors);

  /// Puts [to] in [from]'s place in [key]'s row (or at the end if [from]
  /// isn't there).
  static void replace(String key, Color from, Color to) {
    final argb = from.withValues(alpha: 1).toARGB32();
    final colors = of(key);
    final at = colors.indexWhere((c) => c.toARGB32() == argb);
    if (at < 0) return add(key, to);
    colors[at] = to.withValues(alpha: 1);
    _write(key, colors);
  }

  /// Adds [color] at the end of [key]'s row, unless it's there already.
  static void add(String key, Color color) {
    final colors = of(key);
    final argb = color.withValues(alpha: 1).toARGB32();
    if (colors.any((c) => c.toARGB32() == argb)) return;
    _write(key, [...colors, Color(argb)]);
  }

  static void _write(String key, List<Color> colors) {
    final seen = <int>{};
    stows.barColors.value = [
      for (final s in stows.barColors.value)
        if (!s.startsWith('$key:')) s,
      '$key:',
      for (final c in colors)
        if (seen.add(c.withValues(alpha: 1).toARGB32()))
          '$key:${c.withValues(alpha: 1).toARGB32()}',
    ];
  }
}

/// A tool's colors in the bar, which scroll when there are more than fit.
/// Held, a color lifts: dragged, it moves to another place in the row; let
/// go where it was, it asks whether to remove it.
class BarColorRow extends StatefulWidget {
  const BarColorRow({
    super.key,
    required this.colors,
    required this.current,
    required this.axis,
    required this.invert,
    required this.pick,
    required this.onReorder,
    required this.openPanel,
  });

  final List<Color> colors;

  /// The tool's color now, ringed.
  final Color current;
  final Axis axis;

  /// Whether ink shows inverted, as in dark mode.
  final bool invert;
  final ValueChanged<Color> pick;

  /// The row after a color was moved or removed.
  final ValueChanged<List<Color>> onReorder;

  /// The ringed color was tapped again: its panel opens from [dot].
  /// The chosen dot was tapped again: opens the colors to change it.
  final void Function(BuildContext dot, Color color) openPanel;

  @override
  State<BarColorRow> createState() => _BarColorRowState();
}

class _BarColorRowState extends State<BarColorRow> {
  /// The color held, by its place in [BarColorRow.colors].
  int? _held;

  /// How far it's been dragged along the row.
  var _offset = 0.0;
  var _moved = false;

  /// A [BnColorDot] and its padding.
  static const _slot = 30.0;

  bool get _vertical => widget.axis == Axis.vertical;

  int get _target => (_held! + (_offset / _slot).round()).clamp(
    0,
    widget.colors.length - 1,
  );

  List<Color> get _order {
    final list = [...widget.colors];
    final held = _held;
    if (held != null) list.insert(_target, list.removeAt(held));
    return list;
  }

  void _lift(int index) {
    HapticFeedback.mediumImpact();
    setState(() {
      _held = index;
      _offset = 0;
      _moved = false;
    });
  }

  void _drag(Offset fromOrigin) {
    final before = _target;
    setState(() {
      _offset = _vertical ? fromOrigin.dy : fromOrigin.dx;
      if (_offset.abs() > 8) _moved = true;
    });
    if (_target != before) HapticFeedback.selectionClick();
  }

  Future<void> _drop(BuildContext dot) async {
    final order = _order;
    final held = _held;
    final moved = _moved;
    setState(() => _held = null);
    if (held == null) return;
    if (moved) {
      widget.onReorder(order);
    } else if (await askRemoveColor(dot) && mounted) {
      widget.onReorder([...widget.colors]..removeAt(held));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    // ponytail: a fixed share of the screen; measure the bar's free room if
    // this crowds the other tools or leaves space unused
    final room = ((_vertical ? screen.height : screen.width) * 0.4).clamp(
      _slot * 3,
      _slot * 10,
    );
    final order = _order;
    final held = _held;
    final target = held == null ? null : _target;
    return ConstrainedBox(
      constraints: _vertical
          ? BoxConstraints(maxHeight: room)
          : BoxConstraints(maxWidth: room),
      // ponytail: no scrolling while a color is dragged past the edge; add
      // auto-scroll if rows get long enough to need it
      child: SingleChildScrollView(
        scrollDirection: widget.axis,
        child: Flex(
          direction: widget.axis,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, color) in order.indexed)
              _dot(
                color,
                index: held == null ? i : widget.colors.indexOf(color),
                lifted: i == target,
                shift: i == target ? _offset - (target! - held!) * _slot : 0,
              ),
          ],
        ),
      ),
    );
  }

  Widget _dot(
    Color color, {
    required int index,
    required bool lifted,
    required double shift,
  }) {
    final chosen =
        (color.toARGB32() & 0xFFFFFF) ==
        (widget.current.toARGB32() & 0xFFFFFF);
    return Builder(
      key: ValueKey(color.toARGB32()),
      builder: (dot) => RawGestureDetector(
        gestures: {
          // quicker than the bar's own hold (280 ms), which moves the bar
          LongPressGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
                () => LongPressGestureRecognizer(
                  duration: const Duration(milliseconds: 230),
                ),
                (r) => r
                  ..onLongPressStart = ((_) => _lift(index))
                  ..onLongPressMoveUpdate = ((d) => _drag(d.offsetFromOrigin))
                  ..onLongPressEnd = ((_) => _drop(dot))
                  ..onLongPressCancel = (() => setState(() => _held = null)),
              ),
        },
        child: Transform.translate(
          offset: _vertical ? Offset(0, shift) : Offset(shift, 0),
          child: AnimatedScale(
            scale: lifted ? 1.3 : 1,
            duration: const Duration(milliseconds: 120),
            child: BnColorDot(
              color: color.withInversion(widget.invert),
              selected: chosen,
              onTap: chosen
                  ? () => widget.openPanel(dot, color)
                  : () => widget.pick(color),
            ),
          ),
        ),
      ),
    );
  }
}
