import 'dart:math' as math;

import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:flutter/material.dart';

/// Opens a long-press menu: the page dims, the pressed item ([lifted], drawn
/// over its own place [anchor]) lifts with an accent ring, and [menu] opens
/// beside it. Tapping outside closes it.
Future<T?> showLiftedMenu<T>(
  BuildContext context, {
  required Rect anchor,
  required WidgetBuilder menu,
  Widget? lifted,
  double width = 300,
  double tilt = -3,
  double raise = 150,
}) {
  return Navigator.of(context).push<T>(
    PageRouteBuilder<T>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: const Color(0x7A16161A),
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: BnMotion.normal,
      reverseTransitionDuration: BnMotion.fast,
      pageBuilder: (context, animation, _) => _LiftedMenu(
        anchor: anchor,
        lifted: lifted,
        menu: Builder(builder: menu),
        width: width,
        tilt: tilt,
        raise: raise,
        animation: animation,
      ),
    ),
  );
}

class _LiftedMenu extends StatelessWidget {
  const _LiftedMenu({
    required this.anchor,
    required this.lifted,
    required this.menu,
    required this.width,
    required this.tilt,
    required this.raise,
    required this.animation,
  });

  final Rect anchor;
  final Widget? lifted;
  final Widget menu;
  final double width, tilt;

  /// How far above the item's top the menu starts.
  final double raise;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final size = MediaQuery.sizeOf(context);
    final still = MediaQuery.disableAnimationsOf(context);
    final curved = CurvedAnimation(parent: animation, curve: BnMotion.curve);
    const gap = 28.0, margin = 12.0;
    final right = anchor.right + gap + width <= size.width - margin;
    final left = right
        ? anchor.right + gap
        : math.max(margin, anchor.left - gap - width);

    return Stack(
      children: [
        if (lifted != null)
          Positioned.fromRect(
            rect: anchor,
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: curved,
                builder: (context, child) => Transform.rotate(
                  angle: (still ? 1 : curved.value) * tilt * math.pi / 180,
                  child: Transform.scale(
                    scale: 1 + (still ? 1 : curved.value) * 0.04,
                    child: child,
                  ),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    boxShadow: [
                      BoxShadow(color: colors.accent, spreadRadius: 3),
                      const BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 48,
                        offset: Offset(0, 24),
                      ),
                    ],
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: lifted,
                  ),
                ),
              ),
            ),
          ),
        CustomSingleChildLayout(
          delegate: _MenuLayout(anchor, left, margin, raise),
          child: bnPopIn(
            context,
            animation,
            alignment: right ? Alignment.centerLeft : Alignment.centerRight,
            SizedBox(
              width: width,
              child: Material(
                color: colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(22)),
                  side: BorderSide(color: colors.hairline),
                ),
                elevation: 0,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(22)),
                    boxShadow: BnShadows.floating,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: SingleChildScrollView(child: menu),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuLayout extends SingleChildLayoutDelegate {
  _MenuLayout(this.anchor, this.left, this.margin, this.raise);

  final Rect anchor;
  final double left, margin, raise;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(maxHeight: constraints.maxHeight - margin * 2);

  @override
  Offset getPositionForChild(Size size, Size child) {
    // level with the item's top, or as high as needed to fit
    final double top = (anchor.top - raise)
        .clamp(margin, math.max(margin, size.height - child.height - margin))
        .toDouble();
    return Offset(left, top);
  }

  @override
  bool shouldRelayout(_MenuLayout old) =>
      old.anchor != anchor || old.left != left;
}

/// One of the square quick actions along the top of a long-press menu.
class MenuQuickAction extends StatelessWidget {
  const new({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// e.g. already starred.
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final fg = active ? colors.accentStrong : colors.text;
    return Expanded(
      child: Material(
        color: active ? colors.accentTint : colors.sunkenSoft,
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        child: InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          child: SizedBox(
            height: 64,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: fg),
                const SizedBox(height: 5),
                Text(
                  label,
                  maxLines: 1,
                  style: BnType.micro.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A 44 px row of a long-press menu (a little larger than [BnMenuRow]).
class MenuRow extends StatelessWidget {
  const new({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final fg = destructive ? colors.danger : colors.text;
    return InkWell(
      onTap: onTap,
      hoverColor: colors.rowHover,
      borderRadius: const BorderRadius.all(Radius.circular(BnRadius.control)),
      child: SizedBox(
        height: 44,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: destructive ? colors.danger : colors.text2),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BnType.bodyLarge.copyWith(color: fg),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

/// Closes the menu, then runs [action] from the page underneath.
VoidCallback closeThen(BuildContext menuContext, VoidCallback action) => () {
  Navigator.of(menuContext).pop();
  action();
};
