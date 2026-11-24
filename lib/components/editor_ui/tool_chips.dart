import 'package:badnotes/components/editor_ui/editor_ui_colors.dart';
import 'package:flutter/material.dart';

/// Wraps [child] so the whole of its box reacts to taps, not just the
/// painted parts.
Widget _tapArea({
  required VoidCallback? onTap,
  VoidCallback? onLongPress,
  required Widget child,
}) => GestureDetector(
  behavior: HitTestBehavior.opaque,
  onTap: onTap,
  onLongPress: onLongPress,
  child: child,
);

/// One tool in a floating tool bar. The tool in use sits on a filled chip
/// ([selectedColor], teal unless told otherwise), and shows a small ⌄ when
/// [hasSettings] says a second tap opens its options. A null [onTap] greys
/// the tool out.
class ToolChip extends StatelessWidget {
  const new({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.selected = false,
    this.hasSettings = false,
    this.selectedColor = EditorUi.chosenTool,
  });

  final Widget icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool selected;
  final bool hasSettings;
  final Color selectedColor;

  Color _iconColor(BuildContext context) {
    if (onTap == null) return EditorUi.of(context).iconDim;
    // the teal chip always takes a white icon, even in light mode
    if (selected && selectedColor == EditorUi.chosenTool) return Colors.white;
    return EditorUi.of(context).icon;
  }

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        icon,
        if (selected && hasSettings) const Icon(Icons.expand_more, size: 14),
      ],
    );
    return Tooltip(
      message: tooltip,
      child: _tapArea(
        onTap: onTap,
        child: Container(
          height: 36,
          constraints: const BoxConstraints(minWidth: 40),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: selected ? selectedColor : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconTheme(
            data: IconThemeData(color: _iconColor(context), size: 21),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// A pen size to pick, drawn as a short bar that grows with [thickness].
class SizeChip extends StatelessWidget {
  const new({
    super.key,
    required this.thickness,
    required this.selected,
    required this.onTap,
    required this.tooltip,
  });

  /// How thick the size is, from 0 (finest) to 1 (thickest).
  final double thickness;
  final bool selected;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final ui = EditorUi.of(context);
    final barHeight = 1.5 + thickness.clamp(0.0, 1.0) * 7;
    return Tooltip(
      message: tooltip,
      child: _tapArea(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? ui.chosenChip : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Container(
            width: 18,
            height: barHeight,
            decoration: BoxDecoration(
              color: ui.icon,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      ),
    );
  }
}

/// A round colour swatch. When [selected] it gets a ring around it, and with
/// [showChevron] also a ⌄ (dark or light to suit the colour) for its
/// options.
class ColorDot extends StatelessWidget {
  const new({
    super.key,
    required this.color,
    required this.selected,
    required this.onTap,
    this.onLongPress,
    this.size = 22,
    this.showChevron = false,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  /// The swatch's diameter, without the ring.
  final double size;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final ui = EditorUi.of(context);
    final opaque = color.withValues(alpha: 1);
    final isLightColor = opaque.computeLuminance() > 0.6;
    final outer = size + (selected ? 8 : 0);

    final swatch = DecoratedBox(
      decoration: BoxDecoration(
        color: opaque,
        shape: BoxShape.circle,
        border: Border.all(
          color: ui.iconDim.withValues(alpha: 0.5),
          width: 0.8,
        ),
      ),
      child: selected && showChevron
          ? Icon(
              Icons.expand_more,
              size: 12,
              color: isLightColor ? Colors.black87 : Colors.white,
            )
          : null,
    );

    return _tapArea(
      onTap: onTap,
      onLongPress: onLongPress,
      child: SizedBox.square(
        dimension: size + 14,
        child: Center(
          child: Container(
            width: outer,
            height: outer,
            padding: EdgeInsets.all(selected ? 3 : 0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? ui.chosenChip : null,
            ),
            child: swatch,
          ),
        ),
      ),
    );
  }
}

/// A plus in a circle, after the swatches, for picking any other colour.
class AddColorDot extends StatelessWidget {
  const new({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(
      Icons.add_circle_outline,
      size: 24,
      color: EditorUi.of(context).icon,
    );
    return Tooltip(
      message: 'More colors',
      child: InkResponse(
        onTap: onTap,
        radius: 20,
        child: SizedBox.square(dimension: 36, child: icon),
      ),
    );
  }
}

/// A thin separator between groups of a tool bar, running across the bar's
/// [axis].
class BarDivider extends StatelessWidget {
  const new({super.key, required this.axis});

  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final across = axis == Axis.horizontal;
    return Padding(
      padding: const EdgeInsets.all(6),
      child: SizedBox(
        width: across ? 1 : 22,
        height: across ? 22 : 1,
        child: ColoredBox(color: EditorUi.of(context).cardDivider),
      ),
    );
  }
}
