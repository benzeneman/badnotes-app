import 'package:flutter/material.dart';
import 'package:badnotes/components/canvas/hud/hud_pill.dart';

/// A button over the canvas that switches a gesture lock on and off.
///
/// Give it an [icon] (it cross-fades when the icon changes) or a [child] of
/// its own, which then looks after its own animation. If both are given,
/// [child] wins.
class CanvasGestureLockBtn extends StatelessWidget {
  const CanvasGestureLockBtn({
    super.key,
    required this.lock,
    required this.setLock,
    required this.tooltip,
    this.icon,
    this.child,
  }) : assert(icon != null || child != null);

  final bool lock;
  final ValueChanged<bool> setLock;
  final String tooltip;
  final IconData? icon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final inkColor = Theme.of(context).colorScheme.onSurface;
    return HudPill(
      onTap: () => setLock(!lock),
      child: Tooltip(
        message: tooltip,
        child:
            child ??
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(icon, key: ValueKey(icon), color: inkColor),
            ),
      ),
    );
  }
}
