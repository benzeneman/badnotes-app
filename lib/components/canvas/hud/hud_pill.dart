import 'package:flutter/material.dart';

/// The soft, half see-through rounded plate the buttons and read-outs that
/// float over the canvas sit on.
class HudPill extends StatelessWidget {
  const HudPill({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final plate = DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(padding: const EdgeInsets.all(5), child: child),
    );
    return onTap == null
        ? plate
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: plate,
          );
  }
}
