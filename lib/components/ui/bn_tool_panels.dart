import 'dart:math';

import 'package:badnotes/components/canvas/shape_style.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/theming/badnotes_tokens.dart';
import 'package:badnotes/components/ui/bn_icons.dart';
import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

/// The editor's tool and panel icons, from the design's own 24×24 paths.
abstract final class BnToolPaths {
  // pens
  static const fountain = 'M12 3l5 8-5 7-5-7zM12 11v3M8 21h8';
  static const ball = 'M17 3l4 4L8 20l-5 1 1-5zM14 6l4 4';
  static const brush =
      'M20 3c-4 3-8 7-10 10l2 2c3-2 7-6 10-10zM9 14c-3 0-5 2-5 6 3 0 6-2 6-5';
  static const calligraphy = 'M5 19l4-12h6l4 12zM9 7l3-4 3 4M12 11v4';

  // eraser, laser, lasso
  static const precision =
      'M4 20L16 8M14 4l1 2 2 1-2 1-1 2-1-2-2-1 2-1zM19 11l.5 1 1 .5-1 .5-.5 1-.5-1-1-.5 1-.5z';
  static const wholeStroke = 'M4 16c3-8 6 4 9-4s5 2 7-2';
  static const laserLine = 'M4 16c3-8 6 4 9-4s5 2 7-2';
  static const rectangleLasso = 'M4 4h16v16H4z';
  static const tune =
      'M4 7h10M18 7h2M4 17h4M12 17h8M14 7a2 2 0 1 0 4 0a2 2 0 1 0-4 0M8 17a2 2 0 1 0 4 0a2 2 0 1 0-4 0';

  // shapes
  static const line = 'M5 19L19 5';
  static const arrow = 'M5 19L19 5M10 5h9v9';
  static const elbow = 'M5 19V9h12M13 5l4 4-4 4';
  static const rectangle = 'M4 6h16v12H4z';
  static const ellipse = 'M12 4a8 8 0 1 0 0 16a8 8 0 1 0 0-16';
  static const triangle = 'M12 4l9 16H3z';
  static const pentagon = 'M12 3l9 6.5-3.5 11h-11L3 9.5z';
  static const hexagon = 'M7 4h10l5 8-5 8H7l-5-8z';
  static const star =
      'M12 4l2.5 5.2 5.5.8-4 3.9.9 5.6L12 16.9 7.1 19.5l.9-5.6-4-3.9 5.5-.8z';
  static const heart =
      'M12 20s-8-5-8-11a4.5 4.5 0 0 1 8-2.5A4.5 4.5 0 0 1 20 9c0 6-8 11-8 11z';
  static const autoShape = 'M3 15c2-5 4 5 6 0M13 8h7v7h-7z';

  // selection
  static const cut = 'M6 9a3 3 0 1 0 0-.1M6 18a3 3 0 1 0 0-.1M8.5 8L20 18M8.5 16L20 6';
  static const copy = 'M8 8h12v12H8zM16 8V4H4v12h4';
  static const duplicate = 'M12 5v14M5 12h14';
  static const palette =
      'M12 3a9 9 0 1 0 0 18c1.5 0 2-1 2-2s-1-2 0-3 2 0 3 0a4 4 0 0 0 4-4c0-5-4-9-9-9zM7.5 11h.01M10 7h.01M15 7h.01';
  static const resize = 'M14 4h6v6M10 20H4v-6M20 4l-7 7M4 20l7-7';
  static const toText = 'M4 6h7M7.5 6v8M14 10h6M17 10v8M3 20l3-3 3 3';
  static const screenshot =
      'M4 8V4h4M16 4h4v4M20 16v4h-4M8 20H4v-4M9 12a3 3 0 1 0 6 0a3 3 0 1 0-6 0';
  static const share = 'M12 15V3M7 8l5-5 5 5M5 13v7h14v-7';
  static const trash = 'M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3';
  static const more =
      'M5 12h.01M12 12h.01M19 12h.01';

  // text
  static const bold = 'M7 4h6a4 4 0 0 1 0 8H7zM7 12h7a4 4 0 0 1 0 8H7z';
  static const alignLeft = 'M4 6h16M4 10h10M4 14h16M4 18h10';
  static const alignCenter = 'M4 6h16M7 10h10M4 14h16M7 18h10';
  static const alignRight = 'M4 6h16M10 10h10M4 14h16M10 18h10';
  static const list = 'M9 6h11M9 12h11M9 18h11M4 6h.01M4 12h.01M4 18h.01';
  static const numbers = 'M10 6h10M10 12h10M10 18h10M4 4h1v4M4 10h2l-2 3h2M4 16h2v4H4M4 18h2';
  static const fill =
      'M5 11l7-7 7 7-7 7zM19 15c0 2 2 3 2 4.5a2 2 0 0 1-4 0c0-1.5 2-2.5 2-4.5M3 22h18';
  static const pin = 'M12 3a4 4 0 0 0-4 4c0 3 4 6 4 6s4-3 4-6a4 4 0 0 0-4-4zM12 13v8';

  // insert
  static const photo = 'M3 5h18v14H3zM8 10a1.5 1.5 0 1 0 0-.1M21 16l-5-5-9 8';
  static const camera =
      'M4 8h3l2-3h6l2 3h3v11H4zM8.5 13a3.5 3.5 0 1 0 7 0a3.5 3.5 0 1 0-7 0';
  static const sticker =
      'M4 4h16v10l-6 6H4zM14 20v-6h6M9 10h.01M15 10h.01M9 14c1.5 1 3.5 1 5 0';
  static const stickyNote = 'M4 4h16v11l-5 5H4zM15 20v-5h5';
  static const textBox = 'M5 6V4h14v2M12 4v16M9 20h6';
  static const voice = 'M9 4a3 3 0 0 1 6 0v7a3 3 0 0 1-6 0zM5 11a7 7 0 0 0 14 0M12 18v3';
  static const pdf = 'M6 3h8l4 4v14H6zM14 3v4h4M9 13h6M9 17h4';
  static const link =
      'M10 14a4 4 0 0 0 5.6 0l3-3a4 4 0 0 0-5.6-5.6l-1 1M14 10a4 4 0 0 0-5.6 0l-3 3a4 4 0 0 0 5.6 5.6l1-1';
}

// ---------------------------------------------------------------------------
// Sub-bar pieces (design §3: radius 14, 5 px padding, 30 px buttons)
// ---------------------------------------------------------------------------

/// The tinted pill naming the tool's variant ("Fountain ⌃"), with an
/// optional icon before it. Unchosen, it is a plain borderless chip.
class BnToolPill extends StatelessWidget {
  const new({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.path,
    this.selected = true,
    this.chevron = true,
    this.up = true,
    this.tooltip,
    this.textStyle,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  /// 24×24 path data, in place of [icon].
  final String? path;
  final bool selected;
  final bool chevron;

  /// The chevron points up: its panel opens above (the bar at the bottom).
  final bool up;
  final String? tooltip;

  /// In place of the 12/600 label, e.g. the font's own family.
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final fg = selected ? colors.accentStrong : colors.text2;
    final pill = Semantics(
      button: true,
      selected: selected,
      label: tooltip ?? label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: BnMotion.fast,
          curve: BnMotion.curve,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: selected
                ? colors.accentTint
                : colors.accentTint.withValues(alpha: 0),
            borderRadius: const BorderRadius.all(Radius.circular(9)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (path != null)
                BnPathIcon(path!, size: 18, strokeWidth: 2, color: fg)
              else if (icon != null)
                Icon(icon, size: 17, color: fg),
              if (path != null || icon != null) const SizedBox(width: 6),
              Text(
                label,
                maxLines: 1,
                style: (textStyle ?? BnType.caption).copyWith(
                  color: fg,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (chevron) ...[
                const SizedBox(width: 6),
                Icon(up ? BnIcons.up : BnIcons.down, size: 13, color: fg),
              ],
            ],
          ),
        ),
      ),
    );
    if (tooltip == null) return pill;
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 600),
      child: pill,
    );
  }
}

/// A 30 px square button of the sub-bar. Chosen, it sits on a soft grey
/// square, or on the accent tint with [tinted] (a chosen shape).
class BnSubButton extends StatelessWidget {
  const new({
    super.key,
    required this.onTap,
    this.child,
    this.icon,
    this.path,
    this.selected = false,
    this.tinted = false,
    this.tooltip,
    this.size = 30,
    this.iconSize = 19,
    this.onLongPress,
  });

  final VoidCallback? onTap, onLongPress;
  final Widget? child;
  final IconData? icon;

  /// 24×24 path data, in place of [icon].
  final String? path;
  final bool selected, tinted;
  final String? tooltip;
  final double size, iconSize;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final on = selected && tinted;
    final fg = onTap == null
        ? colors.disabled
        : on
        ? colors.accentStrong
        : colors.text2;
    final bg = !selected
        ? colors.sunkenSoft.withValues(alpha: 0)
        : tinted
        ? colors.accentTint
        : colors.sunkenSoft;
    final button = Semantics(
      button: true,
      selected: selected,
      label: tooltip,
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
              Radius.circular(BnRadius.chip),
            ),
          ),
          child: IconTheme(
            data: IconThemeData(color: fg, size: iconSize),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: fg),
              child:
                  child ??
                  (path != null
                      ? BnPathIcon(
                          path!,
                          size: iconSize,
                          strokeWidth: 2,
                          color: fg,
                        )
                      : Icon(icon, size: iconSize, color: fg)),
            ),
          ),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 600),
      child: button,
    );
  }
}

/// How a size of the sub-bar is drawn.
enum BnSizeMark {
  /// A short line: pens.
  line,

  /// A wide flat bar: highlighter and tape.
  bar,

  /// A dot: pencil and shapes.
  dot,

  /// A ring: the eraser.
  ring,
}

/// One of a tool's sizes in the sub-bar, as a mark that grows with [extent].
class BnToolSize extends StatelessWidget {
  const new({
    super.key,
    required this.mark,
    required this.extent,
    required this.selected,
    required this.onTap,
    this.color,
    this.tooltip,
    this.line = ShapeLine.solid,
  });

  final BnSizeMark mark;

  /// A pen's line: a [BnSizeMark.line] shows dashed or dotted to match.
  final ShapeLine line;

  /// From 0 (the smallest) to 1 (the largest).
  final double extent;
  final bool selected;
  final VoidCallback onTap;

  /// The mark's colour; the text colour by default.
  final Color? color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final t = extent.clamp(0.0, 1.0);
    final ink = color ?? colors.text;
    final Widget markWidget = switch (mark) {
      BnSizeMark.line when line == ShapeLine.dashed => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              width: 4,
              height: 2 + 4 * t,
              decoration: BoxDecoration(
                color: ink,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
        ],
      ),
      BnSizeMark.line when line == ShapeLine.dotted => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              width: 2.5 + 2.5 * t,
              height: 2.5 + 2.5 * t,
              decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
            ),
        ],
      ),
      BnSizeMark.line => Container(
        width: 14,
        height: 2 + 4 * t,
        decoration: BoxDecoration(
          color: ink,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      BnSizeMark.bar => Container(
        width: 18,
        height: 3 + 9 * t,
        decoration: BoxDecoration(
          color: ink,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      BnSizeMark.dot => Container(
        width: 5 + 9 * t,
        height: 5 + 9 * t,
        decoration: BoxDecoration(color: ink, shape: BoxShape.circle),
      ),
      BnSizeMark.ring => Container(
        width: 10 + 16 * t,
        height: 10 + 16 * t,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ink, width: 2),
        ),
      ),
    };
    return BnSubButton(
      tooltip: tooltip,
      selected: selected,
      onTap: onTap,
      child: markWidget,
    );
  }
}

/// The dashed circle with a plus that opens all the colours.
class BnAddColorDot extends StatelessWidget {
  const new({super.key, required this.onTap, this.size = 22, this.tooltip});

  final VoidCallback onTap;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Tooltip(
      message: tooltip ?? 'More colors',
      waitDuration: const Duration(milliseconds: 600),
      child: Semantics(
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: CustomPaint(
              painter: BnDashedCirclePainter(colors.disabled),
              child: SizedBox.square(
                dimension: size,
                child: Icon(
                  BnIcons.add,
                  size: size * 0.62,
                  color: colors.text2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A 1.5 px dashed circle filling the size it's given.
class BnDashedCirclePainter extends CustomPainter {
  const new(this.color, {this.strokeWidth = 1.5});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final r = rect.shortestSide / 2;
    // about a 3 px dash and gap all round
    final count = max(8, (2 * pi * r / 6).round());
    final step = 2 * pi / count;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    for (var i = 0; i < count; i++) {
      canvas.drawArc(rect, i * step, step / 2, false, paint);
    }
  }

  @override
  bool shouldRepaint(BnDashedCirclePainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

/// A saved pen in the sub-bar: a small dot in its colour, as big as its
/// size, ringed when the pen in use matches it.
class BnPresetDot extends StatelessWidget {
  const new({
    super.key,
    required this.color,
    required this.extent,
    required this.selected,
    required this.onTap,
    this.onLongPress,
    this.tooltip,
  });

  final Color color;

  /// From 0 (fine) to 1 (broad).
  final double extent;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final d = 8 + 8 * extent.clamp(0.0, 1.0);
    final pale =
        (color.computeLuminance() - colors.surface.computeLuminance()).abs() <
        0.12;
    return Tooltip(
      message: tooltip ?? 'Saved pen (hold to remove)',
      waitDuration: const Duration(milliseconds: 600),
      child: Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          onLongPress: onLongPress,
          child: SizedBox(
            width: 24,
            height: 30,
            child: Center(
              child: AnimatedContainer(
                duration: BnMotion.fast,
                curve: BnMotion.curve,
                width: d,
                height: d,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: pale ? Border.all(color: colors.hairline) : null,
                  boxShadow: selected
                      ? [
                          BoxShadow(color: colors.surface, spreadRadius: 1.5),
                          BoxShadow(color: colors.accent, spreadRadius: 3),
                        ]
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A short muted label inside the sub-bar, e.g. "Pick up".
class BnSubLabel extends StatelessWidget {
  const new(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: Text(
      text,
      style: BnType.caption.copyWith(
        color: BadNotesColors.of(context).muted,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Panel pieces (design §3: popover radius 18, 16 px padding)
// ---------------------------------------------------------------------------

/// One choice of [BnTypeCards].
typedef BnTypeChoice<T> = ({T value, Widget icon, String label});

/// Cards to choose one of, each an icon over its label; the chosen one on
/// the accent tint (pen types, eraser types, laser modes).
class BnTypeCards<T> extends StatelessWidget {
  const new({
    super.key,
    required this.choices,
    required this.value,
    required this.onChanged,
    this.gap = 4,
    this.height = 64,
  });

  final List<BnTypeChoice<T>> choices;
  final T value;
  final ValueChanged<T> onChanged;
  final double gap, height;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Row(
      children: [
        for (final (i, choice) in choices.indexed) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(
            child: Semantics(
              button: true,
              selected: choice.value == value,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(choice.value),
                child: AnimatedContainer(
                  duration: BnMotion.fast,
                  curve: BnMotion.curve,
                  height: height,
                  decoration: BoxDecoration(
                    color: choice.value == value
                        ? colors.accentTint
                        : colors.accentTint.withValues(alpha: 0),
                    borderRadius: const BorderRadius.all(
                      Radius.circular(BnRadius.tool),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconTheme(
                        data: IconThemeData(
                          color: choice.value == value
                              ? colors.accentStrong
                              : colors.text2,
                          size: 20,
                        ),
                        child: choice.icon,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        choice.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: BnType.caption.copyWith(
                          color: choice.value == value
                              ? colors.accentStrong
                              : colors.text2,
                          fontWeight: choice.value == value
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A label over a group in a panel (12/500 muted), with an optional
/// trailing widget.
class BnPanelLabel extends StatelessWidget {
  const new(this.text, {super.key, this.trailing, this.top = 14});

  final String text;
  final Widget? trailing;
  final double top;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: BnType.caption.copyWith(
                color: colors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// A muted note under a row of a panel.
class BnPanelCaption extends StatelessWidget {
  const new(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: BnType.caption.copyWith(
        color: BadNotesColors.of(context).muted,
        height: 1.45,
      ),
    ),
  );
}

/// A small accent link at the right of a panel's title or label, such as
/// "Deselect all".
class BnPanelLink extends StatelessWidget {
  const new({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          label,
          style: BnType.caption.copyWith(
            color: BadNotesColors.of(context).accent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ),
  );
}

/// A swatch of a panel's colour grid: a circle filling its cell, ringed
/// when chosen.
class BnSwatch extends StatelessWidget {
  const new({
    super.key,
    required this.color,
    required this.selected,
    required this.onTap,
    this.onLongPress,
    this.size = 36,
    this.label,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final double size;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final pale =
        (color.computeLuminance() - colors.surface.computeLuminance()).abs() <
        0.12;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
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
    );
  }
}

/// The dashed "+" of a panel's colour grid.
class BnAddSwatch extends StatelessWidget {
  const new({super.key, required this.onTap, this.size = 36, this.tooltip});

  final VoidCallback onTap;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Tooltip(
      message: tooltip ?? 'Add color',
      waitDuration: const Duration(milliseconds: 600),
      child: Semantics(
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: CustomPaint(
            painter: BnDashedCirclePainter(colors.disabled),
            child: SizedBox.square(
              dimension: size,
              child: Icon(BnIcons.add, size: 16, color: colors.text2),
            ),
          ),
        ),
      ),
    );
  }
}

/// A rounded rectangle drawn in dashes, e.g. a rectangle lasso icon.
class BnDashedRRectPainter extends CustomPainter {
  const new(this.color, {this.radius = 4, this.strokeWidth = 1.5});

  final Color color;
  final double radius, strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(strokeWidth / 2),
      Radius.circular(radius),
    );
    canvas.drawPath(
      dashPath(Path()..addRRect(rect), dashArray: CircularIntervalList([3, 3])),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  bool shouldRepaint(BnDashedRRectPainter old) =>
      old.color != color || old.radius != radius;
}
