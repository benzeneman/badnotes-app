import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/theming/badnotes_tokens.dart';
import 'package:flutter/material.dart';

/// A 40 px row of a menu: icon, label, optional trailing text or widget.
class BnMenuRow extends StatelessWidget {
  const new({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.leading,
    this.trailing,
    this.trailingText,
    this.destructive = false,
    this.selected = false,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  /// In place of [icon].
  final Widget? leading;
  final Widget? trailing;

  /// A short muted text at the right, e.g. a count or a shortcut.
  final String? trailingText;
  final bool destructive;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final fg = destructive
        ? colors.danger
        : selected
        ? colors.accentStrong
        : onTap == null
        ? colors.disabled
        : colors.text;
    final iconColor = destructive
        ? colors.danger
        : selected
        ? colors.accent
        : colors.text2;
    return Material(
      color: selected ? colors.accentTint : Colors.transparent,
      borderRadius: const BorderRadius.all(Radius.circular(BnRadius.control)),
      child: InkWell(
        onTap: onTap,
        hoverColor: colors.rowHover,
        borderRadius: const BorderRadius.all(Radius.circular(BnRadius.control)),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 12)],
              if (icon != null) ...[
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BnType.body.copyWith(color: fg),
                ),
              ),
              if (trailingText != null)
                Text(
                  trailingText!,
                  style: BnType.caption.copyWith(color: colors.muted),
                ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// A 64 px row inside a card: a leading picture, title and caption, and a
/// trailing widget. Rows in a card are separated by [BnListRow.divided].
class BnListRow extends StatelessWidget {
  const new({
    super.key,
    required this.title,
    this.caption,
    this.leading,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.height = 64,
    this.divider = true,
  });

  final String title;
  final String? caption;
  final Widget? leading, trailing;
  final VoidCallback? onTap, onLongPress;
  final double height;

  /// A line under the row (leave it off for the last one).
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      hoverColor: colors.rowHover,
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: divider
            ? BoxDecoration(
                border: Border(bottom: BorderSide(color: colors.divider)),
              )
            : null,
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 14)],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BnType.body.copyWith(
                      color: colors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (caption != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        caption!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BnType.caption.copyWith(color: colors.muted),
                      ),
                    ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// A section's title (15/600) with an optional link at the right.
class BnSectionHeader extends StatelessWidget {
  const new({
    super.key,
    required this.title,
    this.action,
    this.onAction,
    this.trailing,
  });

  final String title;

  /// The link's text, e.g. "See all".
  final String? action;
  final VoidCallback? onAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: BnType.section.copyWith(color: colors.text),
            ),
          ),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                action!,
                style: BnType.caption.copyWith(
                  color: colors.accent,
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
