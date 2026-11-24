import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/theming/badnotes_tokens.dart';
import 'package:flutter/material.dart';

/// A white card with a hairline border and the faintest shadow.
class BnCard extends StatelessWidget {
  const new({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = BnRadius.card,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color ?? colors.surface,
        border: Border.all(color: colors.hairline),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: BnShadows.card,
      ),
      // Clipped only when the contents reach the edges: padded, they keep
      // clear of the corners, and a rounded clip cost the GPU two extra
      // passes over the card on every frame it scrolled.
      child: padding == EdgeInsets.zero
          ? ClipRRect(
              borderRadius: BorderRadius.circular(radius - 1),
              child: child,
            )
          : Padding(padding: padding, child: child),
    );
  }
}

/// A floating panel: radius 18, the popover shadow, 16 px padding.
class BnPopover extends StatelessWidget {
  const new({
    super.key,
    required this.child,
    this.width,
    this.padding = const EdgeInsets.all(16),
    this.shadow = BnShadows.popover,
  });

  final Widget child;
  final double? width;
  final EdgeInsetsGeometry padding;

  /// [BnShadows.panel] for a popover with a list that scrolls: the GPU
  /// blurs the shadow again on every frame of the scroll.
  final List<BoxShadow> shadow;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return RepaintBoundary(
      child: Container(
        width: width,
        padding: padding,
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.hairline),
          borderRadius: const BorderRadius.all(
            Radius.circular(BnRadius.popover),
          ),
          boxShadow: shadow,
        ),
        // its own layer: a scroll inside repaints only the content
        child: RepaintBoundary(
          child: Material(type: MaterialType.transparency, child: child),
        ),
      ),
    );
  }
}

/// A popover's title (15/600) with an optional caption or trailing text.
class BnPopoverHeader extends StatelessWidget {
  const new({
    super.key,
    required this.title,
    this.caption,
    this.trailing,
    this.onBack,
  });

  final String title;

  /// Under the title, in muted 12.
  final String? caption;

  /// At the right: a short muted label or a button.
  final Widget? trailing;

  /// Shows a back chevron before the title, for nested pages.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Row(
      children: [
        if (onBack != null) ...[
          BnIconButton(
            icon: Icons.chevron_left_rounded,
            size: 28,
            iconSize: 20,
            onPressed: onBack,
          ),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: BnType.section.copyWith(
                  color: colors.text,
                  letterSpacing: -0.1,
                ),
              ),
              if (caption != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    caption!,
                    style: BnType.caption.copyWith(color: colors.muted),
                  ),
                ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// The light well a preview sits in, inside a popover.
class BnPreviewWell extends StatelessWidget {
  const new({super.key, required this.child, this.height = 80});

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: BadNotesColors.of(context).previewBg,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: child,
    );
  }
}

/// A 1 px line between rows, in the card's divider colour.
class BnDivider extends StatelessWidget {
  const new({super.key, this.indent = 0, this.vertical = 10});

  final double indent;

  /// Space above and below.
  final double vertical;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(indent, vertical, 0, vertical),
      child: SizedBox(
        height: 1,
        width: double.infinity,
        child: ColoredBox(color: BadNotesColors.of(context).divider),
      ),
    );
  }
}

/// A short upright line between groups in a bar.
class BnBarDivider extends StatelessWidget {
  const new({super.key, this.height = 18, this.vertical = false});

  final double height;

  /// In a bar that runs top to bottom: a short flat line instead.
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final color = BadNotesColors.of(context).hairline;
    return Padding(
      padding: vertical
          ? const EdgeInsets.symmetric(vertical: 6)
          : const EdgeInsets.symmetric(horizontal: 6),
      child: SizedBox(
        width: vertical ? height : 1,
        height: vertical ? 1 : height,
        child: ColoredBox(color: color),
      ),
    );
  }
}

/// A square icon button: transparent until pressed or [selected].
class BnIconButton extends StatelessWidget {
  const new({
    super.key,
    required this.icon,
    required this.onPressed,
    this.size = 38,
    this.iconSize = 20,
    this.radius = BnRadius.control,
    this.selected = false,
    this.color,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size, iconSize, radius;
  final bool selected;
  final Color? color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final enabled = onPressed != null;
    final button = Material(
      color: selected ? colors.accentTint : Colors.transparent,
      borderRadius: BorderRadius.circular(radius),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox.square(
          dimension: size,
          child: Icon(
            icon,
            size: iconSize,
            color: !enabled
                ? colors.disabled
                : selected
                ? colors.accent
                : color ?? colors.text2,
          ),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip, child: button);
  }
}
