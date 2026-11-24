import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/theming/badnotes_tokens.dart';
import 'package:badnotes/components/ui/bn_icons.dart';
import 'package:badnotes/components/ui/bn_overlays.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stow/stow.dart';

/// Where [context]'s widget is on the screen.
Rect rectOf(BuildContext context) {
  final box = context.findRenderObject()! as RenderBox;
  return box.localToGlobal(Offset.zero) & box.size;
}

/// One line of a menu from [showAppleMenu].
sealed class AppleMenuEntry {
  const new();
}

/// A line between groups of items.
class AppleMenuDivider extends AppleMenuEntry {
  const new();
}

class AppleMenuItem extends AppleMenuEntry {
  const new(
    this.label, {
    this.icon,
    this.onTap,
    this.children,
    this.enabled = true,
    this.checked = false,
    this.destructive = false,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  /// Opens these in the same popup instead, with a way back.
  final List<AppleMenuEntry>? children;
  final bool enabled, checked, destructive;
}

/// The popover look every menu and panel shares: white, a hairline, radius
/// 18 and the popover shadow (design/DESIGN.md §2–3).
BoxDecoration popoverDecoration(BuildContext context) {
  final colors = BadNotesColors.of(context);
  return BoxDecoration(
    color: colors.surface,
    border: Border.all(color: colors.hairline),
    borderRadius: const BorderRadius.all(Radius.circular(BnRadius.popover)),
    boxShadow: BnShadows.popover,
  );
}

/// A popover-styled surface for [child], clipped to the round corners.
class _PopoverSurface extends StatelessWidget {
  const new({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: popoverDecoration(context),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(
          Radius.circular(BnRadius.popover - 1),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: child,
        ),
      ),
    );
  }
}

/// A small popup next to [anchor], growing out of it. Long lists are better off
/// split up with [AppleMenuItem.children] than scrolled through.
Future<void> showAppleMenu(
  BuildContext context, {
  required Rect anchor,
  required List<AppleMenuEntry> entries,
}) {
  HapticFeedback.selectionClick();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: BadNotesColors.of(context).scrim,
    transitionDuration: BnMotion.fast,
    pageBuilder: (context, animation, _) => _AppleMenuLayout(
      anchor: anchor,
      animation: animation,
      entries: entries,
    ),
    transitionBuilder: (_, _, _, child) => child,
  );
}

/// A dialog that grows into place instead of only fading in, over the scrim.
Future<T?> showAppleDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Color? barrierColor,
}) {
  final themes = InheritedTheme.capture(
    from: context,
    to: Navigator.of(context, rootNavigator: true).context,
  );
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: barrierColor ?? BadNotesColors.of(context).scrim,
    transitionDuration: BnMotion.normal,
    pageBuilder: (context, animation, _) => _Grow(
      animation: animation,
      alignment: Alignment.center,
      child: themes.wrap(
        BnAboveKeyboard(child: SafeArea(child: Builder(builder: builder))),
      ),
    ),
    transitionBuilder: (_, _, _, child) => child,
  );
}

/// A short message in a dark pill near the bottom, with an optional action
/// (e.g. "Undo"). Goes by itself, or swiped away.
void showBanner(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 3),
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  _Banner.current?.remove();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _Banner(
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
      onGone: () {
        if (_Banner.current == entry) _Banner.current = null;
        if (entry.mounted) entry.remove();
      },
    ),
  );
  _Banner.current = entry;
  overlay.insert(entry);
}

class _Banner extends StatefulWidget {
  const new({
    required this.message,
    required this.actionLabel,
    required this.onAction,
    required this.duration,
    required this.onGone,
  });

  static OverlayEntry? current;

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
  final VoidCallback onGone;

  @override
  State<_Banner> createState() => _BannerState();
}

class _BannerState extends State<_Banner> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: BnMotion.normal,
    reverseDuration: BnMotion.fast,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
    Future<void>.delayed(widget.duration, _leave);
  }

  Future<void> _leave() async {
    if (!mounted) return;
    await _controller.reverse();
    if (mounted) widget.onGone();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final animation = CurvedAnimation(
      parent: _controller,
      curve: BnMotion.curve,
      reverseCurve: Curves.easeInCubic,
    );
    final hasAction = widget.actionLabel != null;
    return Positioned(
      // above the home dock and the editor's tool dock
      bottom: MediaQuery.paddingOf(context).bottom + 110,
      left: 16,
      right: 16,
      child: Center(
        child: FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.4),
              end: Offset.zero,
            ).animate(animation),
            child: GestureDetector(
              onVerticalDragEnd: (_) => _leave(),
              child: Semantics(
                liveRegion: true,
                child: Material(
                  color: colors.text,
                  shape: const StadiumBorder(),
                  elevation: 0,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                      boxShadow: BnShadows.floating,
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        hasAction ? 10 : 12,
                        hasAction ? 10 : 20,
                        hasAction ? 10 : 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 16,
                        children: [
                          Flexible(
                            child: Text(
                              widget.message,
                              style: BnType.bodyLarge.copyWith(
                                color: colors.surface,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                          if (hasAction)
                            Material(
                              color: colors.accent,
                              shape: const StadiumBorder(),
                              child: InkWell(
                                customBorder: const StadiumBorder(),
                                onTap: () {
                                  widget.onAction?.call();
                                  _leave();
                                },
                                child: Container(
                                  height: 36,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    widget.actionLabel!,
                                    style: BnType.body.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A larger popup coming out of the top right corner, for a whole panel of
/// controls that was too much for a sheet over the whole screen.
Future<void> showApplePopover(
  BuildContext context, {
  required WidgetBuilder builder,
  double width = 380,
}) {
  HapticFeedback.selectionClick();
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: BadNotesColors.of(context).scrim,
    transitionDuration: BnMotion.normal,
    pageBuilder: (context, animation, _) {
      final size = MediaQuery.sizeOf(context);
      final padding = MediaQuery.paddingOf(context);
      return Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: EdgeInsets.only(top: padding.top + 52, right: 8, left: 8),
          child: _Grow(
            animation: animation,
            alignment: Alignment.topRight,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: width,
                maxHeight: size.height * 0.72,
              ),
              child: _PopoverSurface(child: Builder(builder: builder)),
            ),
          ),
        ),
      );
    },
    transitionBuilder: (_, _, _, child) => child,
  );
}

/// A panel of [width] growing out of [anchor], below it if there's room, like
/// a bigger [showAppleMenu] for more than a list of choices.
Future<T?> showAnchoredPanel<T>(
  BuildContext context, {
  required Rect anchor,
  required WidgetBuilder builder,
  double width = 420,
}) {
  HapticFeedback.selectionClick();
  final themes = InheritedTheme.capture(
    from: context,
    to: Navigator.of(context, rootNavigator: true).context,
  );
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: BadNotesColors.of(context).scrim,
    transitionDuration: BnMotion.normal,
    pageBuilder: (context, animation, _) {
      const gap = 10.0, margin = 8.0;
      final screen = MediaQuery.sizeOf(context);
      final padding = MediaQuery.paddingOf(context);
      final w = width.clamp(0.0, screen.width - 2 * margin);
      final fromRight = anchor.center.dx > screen.width / 2;
      final left = (fromRight ? anchor.right - w : anchor.left).clamp(
        margin,
        screen.width - w - margin,
      );
      final spaceBelow = screen.height - padding.bottom - anchor.bottom;
      final spaceAbove = anchor.top - padding.top;
      final down = spaceBelow >= spaceAbove;
      final room = (down ? spaceBelow : spaceAbove) - gap - margin;
      return Stack(
        children: [
          Positioned(
            left: left,
            width: w,
            top: down ? anchor.bottom + gap : null,
            bottom: down ? null : screen.height - anchor.top + gap,
            child: _Grow(
              animation: animation,
              alignment: Alignment(fromRight ? 1 : -1, down ? -1 : 1),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: room),
                child: themes.wrap(
                  _PopoverSurface(child: Builder(builder: builder)),
                ),
              ),
            ),
          ),
        ],
      );
    },
    transitionBuilder: (_, _, _, child) => child,
  );
}

/// Fades in and grows from 0.96, 150–200 ms, no overshoot; nothing with
/// "reduce motion".
class _Grow extends StatelessWidget {
  const new({
    required this.animation,
    required this.alignment,
    required this.child,
  });

  final Animation<double> animation;
  final Alignment alignment;
  final Widget child;

  static final _scale = Tween(begin: BnMotion.popoverStartScale, end: 1.0);

  @override
  Widget build(BuildContext context) {
    // drawn once, then only moved and faded while it grows
    final boundary = RepaintBoundary(child: child);
    if (MediaQuery.disableAnimationsOf(context)) return boundary;
    final curved = CurvedAnimation(
      parent: animation,
      curve: BnMotion.curve,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: _scale.animate(curved),
        alignment: alignment,
        child: boundary,
      ),
    );
  }
}

class _AppleMenuLayout extends StatelessWidget {
  const new({
    required this.anchor,
    required this.animation,
    required this.entries,
  });

  static const _width = 264.0, _gap = 8.0, _margin = 8.0;

  final Rect anchor;
  final Animation<double> animation;
  final List<AppleMenuEntry> entries;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final width = _width.clamp(0.0, screen.width - 2 * _margin);
    final fromRight = anchor.center.dx > screen.width / 2;
    final left = (fromRight ? anchor.right - width : anchor.left).clamp(
      _margin,
      screen.width - width - _margin,
    );
    final spaceBelow = screen.height - padding.bottom - anchor.bottom;
    final spaceAbove = anchor.top - padding.top;
    final down = spaceBelow >= spaceAbove;
    final room = (down ? spaceBelow : spaceAbove) - _gap - _margin;
    return Stack(
      children: [
        Positioned(
          left: left,
          width: width,
          top: down ? anchor.bottom + _gap : null,
          bottom: down ? null : screen.height - anchor.top + _gap,
          child: _Grow(
            animation: animation,
            alignment: Alignment(fromRight ? 1 : -1, down ? -1 : 1),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: room),
              child: _AppleMenuPanel(entries: entries),
            ),
          ),
        ),
      ],
    );
  }
}

class _AppleMenuPanel extends StatefulWidget {
  const new({required this.entries});

  final List<AppleMenuEntry> entries;

  @override
  State<_AppleMenuPanel> createState() => _AppleMenuPanelState();
}

class _AppleMenuPanelState extends State<_AppleMenuPanel> {
  /// The items that opened the current list, outermost first.
  final _path = <AppleMenuItem>[];
  var _forward = true;

  void _open(AppleMenuItem item) => setState(() {
    _forward = true;
    _path.add(item);
  });

  void _back() => setState(() {
    _forward = false;
    _path.removeLast();
  });

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final entries = _path.isEmpty ? widget.entries : _path.last.children!;
    return _PopoverSurface(
      child: AnimatedSize(
        duration: BnMotion.normal,
        curve: BnMotion.curve,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: BnMotion.normal,
          transitionBuilder: (child, animation) {
            final isNew = child.key == ValueKey(_path.length);
            final from = (isNew == _forward) ? 0.25 : -0.25;
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(
                  begin: Offset(from, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.topCenter,
            children: [...previous, ?current],
          ),
          child: SingleChildScrollView(
            key: ValueKey(_path.length),
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_path.isNotEmpty) ...[
                  _row(
                    context,
                    AppleMenuItem(_path.last.label),
                    leading: Icon(BnIcons.back, size: 16, color: colors.accent),
                    bold: true,
                    onTap: _back,
                  ),
                  const _MenuDivider(),
                ],
                for (final entry in entries)
                  switch (entry) {
                    AppleMenuDivider() => const _MenuDivider(),
                    final AppleMenuItem item => _row(
                      context,
                      item,
                      onTap: item.children != null
                          ? () => _open(item)
                          : () {
                              Navigator.pop(context);
                              item.onTap?.call();
                            },
                    ),
                  },
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// A 40 px row: icon, label, then a tick or a chevron at the end.
  Widget _row(
    BuildContext context,
    AppleMenuItem item, {
    required VoidCallback onTap,
    Widget? leading,
    bool bold = false,
  }) {
    final colors = BadNotesColors.of(context);
    final color = !item.enabled
        ? colors.disabled
        : item.destructive
        ? colors.danger
        : colors.text;
    final iconColor = !item.enabled
        ? colors.disabled
        : item.destructive
        ? colors.danger
        : colors.text2;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: item.enabled ? onTap : null,
        hoverColor: colors.rowHover,
        borderRadius: const BorderRadius.all(
          Radius.circular(BnRadius.control),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              spacing: 12,
              children: [
                ?leading,
                if (leading == null && item.icon != null)
                  Icon(item.icon, size: 16, color: iconColor),
                Expanded(
                  child: Text(
                    item.label,
                    style: BnType.body.copyWith(
                      color: color,
                      fontWeight: bold || item.checked
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
                if (item.checked)
                  Icon(BnIcons.check, size: 16, color: colors.accent),
                if (item.children != null)
                  Icon(BnIcons.forward, size: 15, color: colors.faint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
    child: SizedBox(
      height: 1,
      child: ColoredBox(color: BadNotesColors.of(context).divider),
    ),
  );
}


/// Rows on one rounded card with thin lines between them, under a small title.
class GroupedSection extends StatelessWidget {
  const GroupedSection({
    super.key,
    this.header,
    this.footer,
    required this.children,
  });

  final String? header, footer;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final small = TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
              child: Text(header!.toUpperCase(), style: small),
            ),
          Material(
            color: colorScheme.surface,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, child) in children.indexed) ...[
                  if (i > 0)
                    Divider(
                      height: 0.5,
                      thickness: 0.5,
                      indent: 62,
                      color: colorScheme.outlineVariant,
                    ),
                  child,
                ],
              ],
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
              child: Text(footer!, style: small),
            ),
        ],
      ),
    );
  }
}

/// A line of settings: a colored icon, its title, and something on the right.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.chevron = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;

  /// A short text on the right, for what's currently chosen.
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            spacing: 14,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color.lerp(color, Colors.white, 0.12)!, color],
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: SizedBox.square(
                  dimension: 32,
                  child: Icon(icon, size: 18, color: Colors.white),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16)),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (value != null)
                Text(
                  value!,
                  style: TextStyle(
                    fontSize: 15,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ?trailing,
              if (chevron)
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 15,
                  color: colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A [SettingsRow] with a switch for [pref]. The whole row can be tapped.
class PrefSwitchRow extends StatelessWidget {
  const PrefSwitchRow({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    required this.pref,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final Stow<dynamic, bool, dynamic> pref;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: pref,
    builder: (context, value, _) => SettingsRow(
      icon: icon,
      color: color,
      title: title,
      subtitle: subtitle,
      onTap: () => pref.value = !value,
      trailing: CupertinoSwitch(
        value: value,
        activeTrackColor: ColorScheme.of(context).primary,
        onChanged: (v) => pref.value = v,
      ),
    ),
  );
}

/// A [SettingsRow] above a sliding choice between [options] for [pref].
class PrefSegmentRow<T extends Object> extends StatelessWidget {
  const PrefSegmentRow({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    required this.pref,
    required this.options,
    this.afterChange,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final Stow<dynamic, T, dynamic> pref;
  final Map<T, String> options;
  final ValueChanged<T>? afterChange;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SettingsRow(icon: icon, color: color, title: title, subtitle: subtitle),
      Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: ValueListenableBuilder(
          valueListenable: pref,
          builder: (context, value, _) => CupertinoSlidingSegmentedControl<T>(
            groupValue: value,
            children: {
              for (final MapEntry(key: option, value: label)
                  in options.entries)
                option: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(label, style: const TextStyle(fontSize: 13)),
                ),
            },
            onValueChanged: (chosen) {
              if (chosen == null) return;
              HapticFeedback.selectionClick();
              pref.value = chosen;
              afterChange?.call(chosen);
            },
          ),
        ),
      ),
    ],
  );
}

/// A page of settings with a large title that shrinks into the bar on scrolling.
class SettingsPageScaffold extends StatelessWidget {
  const SettingsPageScaffold({
    super.key,
    required this.title,
    this.previousTitle,
    required this.children,
  });

  final String title;
  final String? previousTitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).scaffoldBackgroundColor;
    return Scaffold(
      backgroundColor: background,
      body: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text(title),
            previousPageTitle: previousTitle,
            backgroundColor: background,
            border: null,
            transitionBetweenRoutes: false,
          ),
          SliverSafeArea(
            top: false,
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) {
                // centred, and not stretched too wide to read
                final width = constraints.crossAxisExtent;
                final side = width > 720 ? (width - 720) / 2 : 0.0;
                return SliverPadding(
                  padding: EdgeInsets.fromLTRB(side, 8, side, 0),
                  sliver: SliverList.list(children: children),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
