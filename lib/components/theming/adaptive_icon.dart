import 'package:flutter/material.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';

/// An [Icon] that swaps to [cupertinoIcon] on Apple platforms, when one is
/// given, and shows [icon] everywhere else.
class const AdaptiveIcon({
  super.key,
  required final IconData icon,
  required final IconData? cupertinoIcon,
  final double? size,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final onApple = Theme.of(context).platform.isCupertino;
    final shown = onApple ? (cupertinoIcon ?? icon) : icon;
    return Icon(shown, size: size);
  }
}
