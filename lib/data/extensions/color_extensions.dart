import 'dart:math';

import 'package:flutter/material.dart';

extension ColorExtensions on Color {
  /// This colour with its lightness turned over (light grey becomes dark
  /// grey) when [invert] is true; hue and saturation stay.
  ///
  /// Lightness here is the middle of the brightest and dimmest channel, so
  /// the channels all move by `1 - 2 × lightness`. [InvertWidget] flips luma
  /// instead, which turns a yellow highlighter brown.
  Color withInversion([bool invert = true]) {
    if (!invert) return this;
    final brightest = max(r, max(g, b));
    final dimmest = min(r, min(g, b));
    final shift = 1.0 - brightest - dimmest;
    return Color.from(
      alpha: a,
      red: r + shift,
      green: g + shift,
      blue: b + shift,
      colorSpace: colorSpace,
    );
  }

  /// This colour with its saturation multiplied by [saturationMultiplier].
  Color withSaturation(double saturationMultiplier) {
    final hsl = HSLColor.fromColor(this);
    return hsl.withSaturation(hsl.saturation * saturationMultiplier).toColor();
  }
}
