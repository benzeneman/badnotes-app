import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/theming/badnotes_tokens.dart';
import 'package:badnotes/components/ui/bn_icons.dart';
import 'package:badnotes/components/ui/bn_surfaces.dart';
import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

/// One tab of the [BnHomeDock].
class BnDockTab {
  const new(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// The home screen's floating pill: tabs, a line, and the accent "New".
///
/// Flat colour instead of a blur: nothing to redraw while the page scrolls
/// under it.
class BnHomeDock extends StatelessWidget {
  const new({
    super.key,
    required this.tabs,
    required this.selected,
    required this.onSelect,
    required this.newLabel,
    required this.onNew,
    this.compact = false,
    this.newKey,
  });

  final List<BnDockTab> tabs;
  final int selected;
  final ValueChanged<int> onSelect;
  final String newLabel;
  final VoidCallback onNew;

  /// Icons only, except the first tab and "New" (portrait, phones).
  final bool compact;

  /// For anchoring the "New" menu.
  final Key? newKey;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.96),
          border: Border.all(color: colors.hairline),
          borderRadius: const BorderRadius.all(Radius.circular(BnRadius.pill)),
          boxShadow: BnShadows.floating,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < tabs.length; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              _DockButton(
                label: tabs[i].label,
                icon: tabs[i].icon,
                showLabel: !compact || i == 0,
                selected: i == selected,
                onTap: () => onSelect(i),
              ),
            ],
            const BnBarDivider(height: 22),
            _DockButton(
              key: newKey,
              label: newLabel,
              icon: BnIcons.add,
              showLabel: true,
              filled: true,
              onTap: onNew,
            ),
          ],
        ),
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  const new({
    super.key,
    required this.label,
    required this.icon,
    required this.showLabel,
    required this.onTap,
    this.selected = false,
    this.filled = false,
  });

  final String label;
  final IconData icon;
  final bool showLabel, selected, filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final bg = filled
        ? colors.accent
        : selected
        ? colors.accentTint
        : colors.surface.withValues(alpha: 0);
    final fg = filled
        ? Colors.white
        : selected
        ? colors.accentStrong
        : colors.text2;
    return Semantics(
      label: label,
      selected: selected,
      button: true,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: BnMotion.fast,
          curve: BnMotion.curve,
          height: 44,
          padding: EdgeInsets.symmetric(
            horizontal: showLabel ? (filled ? 18 : 16) : 13,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.all(
              Radius.circular(BnRadius.pill),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: filled ? 16 : 18, color: fg),
              if (showLabel) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: BnType.body.copyWith(
                    color: fg,
                    fontWeight: selected || filled
                        ? FontWeight.w600
                        : FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// The editor's floating tool bar: white, radius 16, hairline border and
/// the floating shadow. Lays its [children] out in a row, or a column when
/// [vertical].
class BnToolDock extends StatelessWidget {
  const new({super.key, required this.children, this.vertical = false});

  final List<Widget> children;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: colors.surface.withValues(alpha: 0.97),
          border: Border.all(color: colors.hairline),
          borderRadius: const BorderRadius.all(Radius.circular(BnRadius.dock)),
          boxShadow: BnShadows.floating,
        ),
        child: Flex(
          direction: vertical ? Axis.vertical : Axis.horizontal,
          mainAxisSize: MainAxisSize.min,
          spacing: 2,
          children: children,
        ),
      ),
    );
  }
}

/// A 42 px tool of the [BnToolDock]; chosen = tinted with an accent icon.
class BnToolButton extends StatelessWidget {
  const new({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.path,
    this.dashed = false,
    this.selected = false,
    this.filled = false,
    this.onLongPress,
    this.size = 42,
    this.inkColor,
    this.centerDot,
  }) : assert(icon != null || path != null);

  /// A pen's ink colour, shown as a short bar under the icon.
  final Color? inkColor;

  /// A filled dot in the middle of the icon (the laser's red).
  final Color? centerDot;

  final String label;
  final IconData? icon;

  /// 24×24 path data, in place of [icon] (see [BnToolIcons]).
  final String? path;
  final bool dashed;
  final bool selected;

  /// The accent square ("Insert").
  final bool filled;
  final VoidCallback? onTap, onLongPress;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final fg = filled
        ? Colors.white
        : selected
        ? colors.accent
        : colors.text2;
    final bg = filled
        ? (selected ? colors.highlightText : colors.accent)
        : selected
        ? colors.accentTint
        : colors.accentTint.withValues(alpha: 0);
    return Tooltip(
      message: label,
      waitDuration: const Duration(milliseconds: 600),
      child: Semantics(
        label: label,
        selected: selected,
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          onLongPress: onLongPress,
          child: AnimatedContainer(
            duration: BnMotion.fast,
            curve: BnMotion.curve,
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.all(
                Radius.circular(BnRadius.tool),
              ),
            ),
            child: _glyph(fg, colors),
          ),
        ),
      ),
    );
  }
}

extension on BnToolButton {
  Widget _glyph(Color fg, BadNotesColors colors) {
    final iconSize = inkColor != null ? 19.0 : 21.0;
    Widget glyph = path != null
        ? BnPathIcon(path!, size: iconSize, color: fg, dashed: dashed)
        : Icon(icon, size: iconSize, color: fg);
    if (centerDot != null) {
      glyph = Stack(
        alignment: Alignment.center,
        children: [
          glyph,
          Container(
            width: iconSize * 0.3,
            height: iconSize * 0.3,
            decoration: BoxDecoration(color: centerDot, shape: BoxShape.circle),
          ),
        ],
      );
    }
    if (inkColor == null) return glyph;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        glyph,
        const SizedBox(height: 3),
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: inkColor,
            borderRadius: const BorderRadius.all(Radius.circular(2)),
            // a white or black ink still shows on the bar
            border: Border.all(color: colors.hairline, width: 0.5),
          ),
        ),
      ],
    );
  }
}

/// Six dots to drag the tool dock by: 2×3 in a row dock, 3×2 in a column.
class BnDragHandle extends StatelessWidget {
  const new({super.key, this.vertical = false});

  final bool vertical;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: vertical ? 42 : 22,
      height: vertical ? 22 : 42,
      child: CustomPaint(
        painter: _HandlePainter(BadNotesColors.of(context).handle, vertical),
      ),
    );
  }
}

class _HandlePainter extends CustomPainter {
  const new(this.color, this.vertical);

  final Color color;
  final bool vertical;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final center = size.center(Offset.zero);
    for (int a = -1; a <= 1; a++) {
      for (final b in const [-1, 1]) {
        final (dx, dy) = vertical ? (a * 5.0, b * 2.5) : (b * 2.5, a * 5.0);
        canvas.drawCircle(center + Offset(dx, dy), 1.4, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_HandlePainter old) =>
      old.color != color || old.vertical != vertical;
}

/// The options row of the current tool: white, radius 14, 5 px padding.
class BnSubBar extends StatelessWidget {
  const new({super.key, required this.children, this.vertical = false});

  final List<Widget> children;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.hairline),
          borderRadius: const BorderRadius.all(Radius.circular(BnRadius.card)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Flex(
          direction: vertical ? Axis.vertical : Axis.horizontal,
          mainAxisSize: MainAxisSize.min,
          spacing: 2,
          children: children,
        ),
      ),
    );
  }
}

/// The tinted pill at the start of the sub-bar naming the tool's variant
/// ("Fountain ⌄").
class BnVariantPill extends StatelessWidget {
  const new({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: colors.accentTint,
          borderRadius: const BorderRadius.all(Radius.circular(9)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: BnType.caption.copyWith(
                color: colors.accentStrong,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Icon(BnIcons.down, size: 14, color: colors.accentStrong),
          ],
        ),
      ),
    );
  }
}

/// One of the sub-bar's three sizes: a short line [thickness] thick.
class BnSizeButton extends StatelessWidget {
  const new({
    super.key,
    required this.thickness,
    required this.selected,
    required this.onTap,
    this.color,
    this.label,
  });

  final double thickness;
  final bool selected;
  final VoidCallback onTap;

  /// The line's colour, e.g. the pen's; defaults to text.
  final Color? color;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Semantics(
      label: label,
      selected: selected,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: BnMotion.fast,
          curve: BnMotion.curve,
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? colors.sunkenSoft
                : colors.sunkenSoft.withValues(alpha: 0),
            borderRadius: const BorderRadius.all(
              Radius.circular(BnRadius.chip),
            ),
          ),
          child: Container(
            width: 14,
            height: thickness,
            decoration: BoxDecoration(
              color: color ?? colors.text,
              borderRadius: BorderRadius.circular(thickness / 2 + 1),
            ),
          ),
        ),
      ),
    );
  }
}

/// A 22 px colour swatch; chosen = a white ring and an accent ring.
class BnColorDot extends StatelessWidget {
  const new({
    super.key,
    required this.color,
    required this.selected,
    required this.onTap,
    this.onLongPress,
    this.size = 22,
    this.label,
  });

  final Color color;
  final bool selected;
  final VoidCallback? onTap, onLongPress;
  final double size;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    // a swatch close to the bar's own colour (white on white, black on
    // dark) needs an edge
    final pale =
        (color.computeLuminance() - colors.surface.computeLuminance()).abs() <
        0.12;
    return Semantics(
      label: label,
      selected: selected,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: AnimatedContainer(
            duration: BnMotion.fast,
            curve: BnMotion.curve,
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: pale ? Border.all(color: colors.hairline) : null,
              boxShadow: selected
                  ? [
                      BoxShadow(color: colors.surface, spreadRadius: 2),
                      BoxShadow(color: colors.accent, spreadRadius: 3.5),
                    ]
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// The rainbow swatch that opens the full colour panel.
class BnMoreColorsDot extends StatelessWidget {
  const new({super.key, required this.onTap, this.size = 22});

  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [
                BnColors.inkRed,
                Color(0xFFF2C94C),
                BnColors.inkGreen,
                BnColors.inkBlue,
                BnColors.accent,
                BnColors.inkRed,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A dashed outline that marks where the dragged tool dock can dock.
class BnDropHint extends StatelessWidget {
  const new({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return CustomPaint(
      painter: const _DashedRectPainter(Color(0xFFCFCEC8)),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        child: Text(label, style: BnType.caption.copyWith(color: colors.faint)),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  const new(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(0.75),
      const Radius.circular(BnRadius.control),
    );
    canvas.drawPath(
      dashPath(Path()..addRRect(rect), dashArray: CircularIntervalList([5, 4])),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_DashedRectPainter old) => old.color != color;
}
