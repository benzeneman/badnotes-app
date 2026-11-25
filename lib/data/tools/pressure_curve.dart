import 'dart:math' as math;

import 'package:badnotes/data/prefs.dart';

/// The one curve stylus pressure goes through before any pen uses it, and the
/// lightest touch that draws.
abstract final class PressureCurve {
  static const presets = ['light', 'normal', 'firm', 'custom'];

  /// Light: a soft touch already gives a thick line. Firm: press to get one.
  static const lightGamma = 0.6, firmGamma = 1.6;

  /// The gamma whose curve p^gamma goes through ([x], [y]): smooth, rising,
  /// and through (0, 0) and (1, 1).
  static double gammaThrough(double x, double y) {
    final px = x.clamp(0.05, 0.95), py = y.clamp(0.05, 0.95);
    return math.log(py) / math.log(px);
  }

  static double gammaOf(String preset, double x, double y) => switch (preset) {
    'light' => lightGamma,
    'firm' => firmGamma,
    'custom' => gammaThrough(x, y),
    _ => 1.0,
  };

  /// [pressure] (0 to 1) through the curve of gamma [gamma].
  static double apply(double pressure, double gamma) {
    final p = pressure.clamp(0.0, 1.0);
    return gamma == 1 ? p : math.pow(p, gamma).toDouble();
  }

  /// The saved curve's gamma.
  static double get gamma => gammaOf(
    stows.pressureCurve.value,
    stows.pressureCurveX.value,
    stows.pressureCurveY.value,
  );

  /// [pressure] through the saved curve, starting from the lightest touch
  /// that draws: that touch is 0, so a line starts from nothing instead of
  /// jumping in at the threshold's width. Normal with no threshold leaves it
  /// exactly as it was.
  static double? adjust(double? pressure) {
    if (pressure == null) return null;
    return adjustWith(pressure, gamma, stows.pressureThreshold.value);
  }

  /// [pressure] from [threshold] (as 0) to 1 through the curve of [gamma].
  static double adjustWith(double pressure, double gamma, double threshold) {
    if (threshold > 0 && threshold < 1) {
      pressure = (pressure - threshold) / (1 - threshold);
    }
    return gamma == 1 && threshold <= 0 ? pressure : apply(pressure, gamma);
  }

  /// Whether [pressure] is too light to draw. A pen with no pressure always
  /// draws.
  static bool tooLight(double? pressure) =>
      pressure != null && pressure < stows.pressureThreshold.value;
}
