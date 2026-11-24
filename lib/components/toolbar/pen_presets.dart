import 'package:badnotes/components/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/tools/highlighter.dart';
import 'package:badnotes/data/tools/pen.dart';
import 'package:badnotes/data/tools/pencil.dart';
import 'package:sbn/tool_id.dart';

/// A saved pen: its kind, color and size, to pick again with one tap.
class PenPreset {
  const PenPreset(this.toolId, this.color, this.size);

  final ToolId toolId;
  final Color color;
  final double size;

  static const max = 8;

  String encode() => '${toolId.id}|${color.toARGB32()}|$size';

  static PenPreset? decode(String entry) {
    final parts = entry.split('|');
    if (parts.length != 3) return null;
    final color = int.tryParse(parts[1]);
    final size = double.tryParse(parts[2]);
    if (color == null || size == null) return null;
    final toolId = ToolId.parsePenType(parts[0], fallback: .fountainPen);
    if (penFor(toolId) == null) return null;
    return PenPreset(toolId, Color(color), size);
  }

  static List<PenPreset> get saved => [
    for (final entry in stows.penPresets.value) ?decode(entry),
  ];

  /// The pen a preset of [toolId] uses.
  static Pen? penFor(ToolId toolId) => switch (toolId) {
    .fountainPen => Pen.currentPen,
    .ballpointPen => Pen.currentBallpointPen,
    .calligraphyPen => Pen.currentCalligraphyPen,
    .brushPen => Pen.currentBrushPen,
    .pencil => Pencil.currentPencil,
    .highlighter => Highlighter.currentHighlighter,
    _ => null,
  };

  static PenPreset of(Pen pen) =>
      PenPreset(pen.toolId, pen.color, pen.options.size);

  /// Sets the pen up as saved and returns it.
  Pen apply() {
    final pen = penFor(toolId)!;
    pen.color = color;
    pen.setSize(size.clamp(pen.sizeMin, pen.sizeMax));
    return pen;
  }

  bool matches(Pen pen) =>
      pen.toolId == toolId &&
      pen.color.toARGB32() == color.toARGB32() &&
      (pen.options.size - size).abs() < 0.01;

  static void add(Pen pen) {
    final entry = of(pen).encode();
    final list = [
      for (final e in stows.penPresets.value)
        if (e != entry) e,
      entry,
    ];
    stows.penPresets.value = list.length > max
        ? list.sublist(list.length - max)
        : list;
  }

  static void remove(PenPreset preset) {
    final entry = preset.encode();
    stows.penPresets.value = [
      for (final e in stows.penPresets.value)
        if (e != entry) e,
    ];
  }
}

/// The saved pens as dots in their color and size, a tap away. The plus saves
/// the pen as it is now; a long press on a dot removes it.
/// The saved pens as small dots in the pen's sub-bar, before its colours
/// (design §7.10), and a button to save the current pen.
class PenPresetsBar extends StatelessWidget {
  const PenPresetsBar({
    super.key,
    required this.currentPen,
    required this.axis,
    required this.choose,
    this.after,
  });

  final Pen? currentPen;
  final Axis axis;
  final ValueChanged<Pen> choose;

  /// Shown after the presets when there's anything to show, e.g. a divider.
  final Widget? after;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: stows.penPresets,
      builder: (context, _, _) {
        final presets = PenPreset.saved;
        final pen = currentPen;
        final canSave = pen != null && PenPreset.penFor(pen.toolId) != null;
        if (presets.isEmpty && !canSave) return const SizedBox.shrink();
        return Flex(
          direction: axis,
          mainAxisSize: .min,
          spacing: 2,
          children: [
            for (final preset in presets)
              Tooltip(
                message: 'Saved pen (hold to remove)',
                child: BnColorDot(
                  color: preset.color.withValues(alpha: 1),
                  size: (8 + preset.size * 0.8).clamp(10, 18),
                  selected: pen != null && preset.matches(pen),
                  onTap: () => choose(preset.apply()),
                  onLongPress: () => PenPreset.remove(preset),
                ),
              ),
            if (canSave)
              BnIconButton(
                icon: Icons.bookmark_add_outlined,
                size: 30,
                iconSize: 17,
                tooltip: 'Save this pen',
                onPressed: presets.any((p) => p.matches(pen))
                    ? null
                    : () => PenPreset.add(pen),
              ),
            ?after,
          ],
        );
      },
    );
  }
}
