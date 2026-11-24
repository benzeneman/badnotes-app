import 'package:flutter/material.dart';

/// Shows [child] with its brightness turned over (dark becomes light), keeping
/// its colours' hues, when [invert] is true.
class InvertWidget extends StatelessWidget {
  const InvertWidget({super.key, this.invert = true, required this.child});

  final bool invert;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      invert ? ColorFiltered(colorFilter: _filter, child: child) : child;

  /// How much red, green and blue each add to brightness (Rec. 709 luma).
  static const lumaR = 0.2126;
  static const lumaG = 0.7152;
  static const lumaB = 0.0722;

  /// Each colour channel loses twice the pixel's brightness and gains full
  /// white: the brightness flips, the differences between channels stay.
  static final _filter = ColorFilter.matrix([
    for (var row = 0; row < 3; row++) ...[
      for (final (column, luma) in const [lumaR, lumaG, lumaB].indexed)
        (row == column ? 1 : 0) - 2 * luma,
      0,
      255,
    ],
    ...[0, 0, 0, 1, 0],
  ]);
}
