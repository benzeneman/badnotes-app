/// The settings' pieces in the "Minimal" design (N21, N31, N32): a labelled
/// card of rows, rows with a toggle, a segmented choice or a drop-down chip,
/// the side menu of a wide settings page and the page frame of a narrow one.
library;

import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/theming/badnotes_tokens.dart';
import 'package:badnotes/components/ui/bn_controls.dart';
import 'package:badnotes/components/ui/bn_overlays.dart';
import 'package:badnotes/components/ui/bn_rows.dart';
import 'package:badnotes/components/ui/bn_surfaces.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:stow/stow.dart';

/// A small label (12/600, muted) over a [BnCard] whose children are
/// separated by divider lines.
class BnSettingsGroup extends StatelessWidget {
  const new({super.key, this.label, required this.children, this.footer});

  final String? label;

  /// Under the card, in muted 12.
  final String? footer;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 18, 0, 8),
            child: Text(
              label!,
              style: BnType.caption.copyWith(
                color: colors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          const SizedBox(height: 12),
        BnCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, child) in children.indexed) ...[
                if (i > 0)
                  ColoredBox(
                    color: colors.divider,
                    child: const SizedBox(height: 1, width: double.infinity),
                  ),
                child,
              ],
            ],
          ),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
            child: Text(
              footer!,
              style: BnType.caption.copyWith(color: colors.muted, height: 1.45),
            ),
          ),
      ],
    );
  }
}

/// A row of settings: an optional icon, the title (13/500) and a muted
/// description, and something at the right. At least 60 px tall.
class BnSettingsRow extends StatelessWidget {
  const new({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.value,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.chevron = false,
    this.titleStyle,
    this.minHeight = 60,
  });

  final String title;
  final String? subtitle;

  /// A 16 px line icon before the title.
  final IconData? icon;

  /// In place of [icon], e.g. a picture.
  final Widget? leading;

  /// A short muted text at the right, for what's chosen now.
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap, onLongPress;

  /// A ">" at the right: the row opens a page.
  final bool chevron;

  /// Changes to the title's style, e.g. 14/600 for an account.
  final TextStyle? titleStyle;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      hoverColor: colors.rowHover,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 14)],
              if (icon != null) ...[
                Icon(icon, size: 16, color: colors.text2),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: BnType.body
                          .copyWith(color: colors.text)
                          .merge(titleStyle),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          subtitle!,
                          style: BnType.caption.copyWith(
                            color: colors.muted,
                            height: 1.35,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (value != null)
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    value!,
                    style: BnType.body.copyWith(
                      color: colors.muted,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              if (trailing != null) ...[const SizedBox(width: 12), trailing!],
              if (chevron) ...[
                const SizedBox(width: 8),
                Icon(LucideIcons.chevronRight, size: 16, color: colors.faint),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A [BnSettingsRow] with a [BnToggle] for [pref]. The whole row toggles.
class BnPrefSwitchRow extends StatelessWidget {
  const new({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.pref,
    this.allow,
    this.trailingBadge,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Stow<dynamic, bool, dynamic> pref;

  /// Asked before [pref] changes; false keeps it as it is.
  final Future<bool> Function(BuildContext context, bool to)? allow;

  /// Shown before the toggle, e.g. a Pro lock.
  final Widget? trailingBadge;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: pref,
    builder: (context, value, _) {
      Future<void> set(bool to) async {
        final check = allow;
        if (check != null && !await check(context, to)) return;
        pref.value = to;
      }

      final toggle = BnToggle(value: value, onChanged: set);
      return Semantics(
        toggled: value,
        child: BnSettingsRow(
          title: title,
          subtitle: subtitle,
          icon: icon,
          onTap: () => set(!value),
          trailing: trailingBadge == null
              ? toggle
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 8,
                  children: [trailingBadge!, toggle],
                ),
        ),
      );
    },
  );
}

/// A [BnSettingsRow] with a [BnSegmented] choice between [options] for
/// [pref]: at the right when there's room, otherwise under the text.
class BnPrefSegmentRow<T extends Object> extends StatelessWidget {
  const new({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.pref,
    required this.options,
    this.afterChange,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Stow<dynamic, T, dynamic> pref;
  final Map<T, String> options;
  final ValueChanged<T>? afterChange;

  void _choose(T chosen) {
    if (chosen == pref.value) return;
    HapticFeedback.selectionClick();
    pref.value = chosen;
    afterChange?.call(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final segmented = ValueListenableBuilder(
      valueListenable: pref,
      builder: (context, value, _) => BnSegmented<T>(
        expand: false,
        segments: [
          for (final MapEntry(key: option, value: label) in options.entries)
            BnSegment(option, label),
        ],
        selected: value,
        onChanged: _choose,
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        // about 90 px a choice, and some room left for the title
        final wide = constraints.maxWidth >= 300 + options.length * 90;
        if (wide) {
          return BnSettingsRow(
            title: title,
            subtitle: subtitle,
            icon: icon,
            trailing: segmented,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            BnSettingsRow(
              title: title,
              subtitle: subtitle,
              icon: icon,
              minHeight: 0,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: segmented,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A [BnSettingsRow] with a drop-down chip ("Eraser ˅") for [pref], which
/// opens a small menu of [options].
class BnPrefChoiceRow<T extends Object> extends StatelessWidget {
  const new({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.pref,
    required this.options,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Stow<dynamic, T, dynamic> pref;
  final Map<T, String> options;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: pref,
    builder: (context, value, _) => Builder(
      builder: (rowContext) => BnSettingsRow(
        title: title,
        subtitle: subtitle,
        icon: icon,
        onTap: () => _open(rowContext),
        trailing: Builder(
          builder: (chipContext) => BnDropdownChip(
            label: options[value] ?? '$value',
            onTap: () => _open(chipContext),
          ),
        ),
      ),
    ),
  );

  void _open(BuildContext anchor) => showBnPopover<void>(
    anchor: anchor,
    width: 220,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final MapEntry(key: option, value: label) in options.entries)
          BnMenuRow(
            label: label,
            selected: option == pref.value,
            trailing: option == pref.value
                ? Icon(
                    LucideIcons.check,
                    size: 16,
                    color: BadNotesColors.of(context).accent,
                  )
                : null,
            onTap: () {
              HapticFeedback.selectionClick();
              pref.value = option;
              Navigator.of(context).pop();
            },
          ),
      ],
    ),
  );
}

/// A 30 px chip with a hairline and a down chevron after its label.
class BnDropdownChip extends StatelessWidget {
  const new({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(BnRadius.chip)),
        side: BorderSide(color: colors.hairline),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(BnRadius.chip)),
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: BnType.caption.copyWith(color: colors.text2)),
              const SizedBox(width: 6),
              Icon(LucideIcons.chevronDown, size: 14, color: colors.text2),
            ],
          ),
        ),
      ),
    );
  }
}

/// A 36 px rounded square holding an icon or a picture, before a row's
/// title (an account, a cloud).
class BnSettingsTile extends StatelessWidget {
  const new({
    super.key,
    this.icon,
    this.child,
    this.round = false,
    this.color,
    this.iconColor,
  });

  final IconData? icon;

  /// In place of [icon], e.g. a profile picture.
  final Widget? child;

  /// A circle instead of a rounded square.
  final bool round;
  final Color? color, iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(round ? 18 : 10),
      child: Container(
        width: 36,
        height: 36,
        color: color ?? colors.sunkenSoft,
        alignment: Alignment.center,
        child: child ?? Icon(icon, size: 18, color: iconColor ?? colors.text2),
      ),
    );
  }
}

/// One entry of the side menu of a wide settings page: 40 px, tinted when
/// chosen.
class BnSettingsNavItem extends StatelessWidget {
  const new({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          hoverColor: colors.rowHover,
          borderRadius: const BorderRadius.all(
            Radius.circular(BnRadius.control),
          ),
          child: AnimatedContainer(
            duration: BnMotion.fast,
            curve: BnMotion.curve,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: selected
                  ? colors.accentTint
                  : colors.accentTint.withValues(alpha: 0),
              borderRadius: const BorderRadius.all(
                Radius.circular(BnRadius.control),
              ),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BnType.body.copyWith(
                color: selected ? colors.accentStrong : colors.text,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The title of one part of the settings (18/600), with an optional muted
/// line under it.
class BnSettingsPaneTitle extends StatelessWidget {
  const new(this.title, {super.key, this.caption});

  final String title;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: BnType.section.copyWith(
            fontSize: 18,
            color: colors.text,
            letterSpacing: -0.2,
          ),
        ),
        if (caption != null)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              caption!,
              style: BnType.caption.copyWith(color: colors.muted),
            ),
          ),
      ],
    );
  }
}

/// The bar at the top of a settings page: a back button with the previous
/// page's name, and an optional title in the middle.
class BnSettingsTopBar extends StatelessWidget {
  const new({
    super.key,
    this.backLabel,
    this.onBack,
    this.backTooltip,
    this.title,
    this.height = 56,
    this.trailing,
  });

  final String? backLabel, backTooltip, title;

  /// Null hides the back button.
  final VoidCallback? onBack;
  final double height;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    Widget? back;
    if (onBack != null) {
      back = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onBack,
          borderRadius: const BorderRadius.all(
            Radius.circular(BnRadius.control),
          ),
          child: SizedBox(
            height: 38,
            child: Padding(
              padding: EdgeInsets.only(
                left: 6,
                right: backLabel == null ? 6 : 12,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.chevronLeft, size: 20, color: colors.text2),
                  if (backLabel != null) ...[
                    const SizedBox(width: 4),
                    Text(
                      backLabel!,
                      style: BnType.body.copyWith(color: colors.text2),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
      if (backTooltip != null) {
        back = Tooltip(message: backTooltip, child: back);
      }
    }
    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 120),
              child: Text(
                title!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BnType.title.copyWith(color: colors.text),
              ),
            ),
          Row(children: [?back, const Spacer(), ?trailing]),
        ],
      ),
    );
  }
}

/// A narrow settings page pushed from the main one: the back bar, a large
/// title, then [children] in a column no wider than 720 px.
class BnSettingsScaffold extends StatelessWidget {
  const new({
    super.key,
    required this.title,
    this.caption,
    this.previousTitle,
    required this.children,
  });

  final String title;
  final String? caption;
  final String? previousTitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final media = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: colors.desk,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final margin = bnSettingsMargin(constraints.maxWidth);
            final side = constraints.maxWidth > 720 + 2 * margin
                ? (constraints.maxWidth - 720) / 2
                : margin;
            return ListView(
              padding: EdgeInsets.fromLTRB(
                side,
                0,
                side,
                media.padding.bottom + 32,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: BnSettingsTopBar(
                    backLabel: previousTitle,
                    onBack: () => Navigator.of(context).maybePop(),
                    backTooltip: MaterialLocalizations.of(context)
                        .backButtonTooltip,
                  ),
                ),
                const SizedBox(height: 8),
                Text(title, style: BnType.display.copyWith(color: colors.text)),
                if (caption != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      caption!,
                      style: BnType.caption.copyWith(color: colors.muted),
                    ),
                  ),
                const SizedBox(height: 6),
                ...children,
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The side margin of a settings page [width] wide: 40 on a landscape
/// tablet, 28 on a portrait one, 16 on a phone.
double bnSettingsMargin(double width) => width >= 1000
    ? BnSpace.marginLandscape
    : width >= 600
    ? BnSpace.marginPortrait
    : 16;

/// A dialog in the popover style for settings, whose [content] can change
/// (e.g. a picker that enables its button once something is chosen). The
/// buttons are built by the caller, so they can be disabled.
Future<T?> showBnSettingsDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  double width = 420,
}) {
  final colors = BadNotesColors.of(context);
  final themes = InheritedTheme.capture(
    from: context,
    to: Navigator.of(context, rootNavigator: true).context,
  );
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: colors.scrim,
    transitionDuration: BnMotion.normal,
    pageBuilder: (context, _, _) => themes.wrap(
      BnAboveKeyboard(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: width),
                child: Builder(builder: builder),
              ),
            ),
          ),
        ),
      ),
    ),
    transitionBuilder: (context, animation, _, child) =>
        bnPopIn(context, animation, child),
  );
}

/// The card of a [showBnSettingsDialog]: a title, the content (scrolls when
/// long), and the [actions] at the bottom right.
class BnDialogCard extends StatelessWidget {
  const new({
    super.key,
    required this.title,
    required this.content,
    this.actions = const [],
    this.leading,
  });

  final String title;
  final Widget content;
  final List<Widget> actions;

  /// Above the title, e.g. the app's icon.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return BnPopover(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (leading != null) ...[leading!, const SizedBox(height: 12)],
          Text(title, style: BnType.title.copyWith(color: colors.text)),
          const SizedBox(height: 10),
          Flexible(
            child: SingleChildScrollView(
              child: DefaultTextStyle.merge(
                style: BnType.body.copyWith(
                  color: colors.text2,
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                ),
                child: content,
              ),
            ),
          ),
          if (actions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: actions,
              ),
            ),
        ],
      ),
    );
  }
}

/// A thin progress line: hairline track, accent fill. [value] null means
/// "still working" (moving).
class BnProgressLine extends StatelessWidget {
  const new({super.key, required this.value, this.height = 2});

  final double? value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: value == null
            ? LinearProgressIndicator(
                minHeight: height,
                color: colors.accent,
                backgroundColor: colors.hairline,
              )
            : TweenAnimationBuilder<double>(
                tween: Tween(end: value!.clamp(0, 1)),
                duration: BnMotion.normal,
                curve: BnMotion.curve,
                builder: (context, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: height,
                  color: colors.accent,
                  backgroundColor: colors.hairline,
                ),
              ),
      ),
    );
  }
}
