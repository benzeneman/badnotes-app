import 'package:perfect_freehand/perfect_freehand.dart';

/// BadNotes's own starting values for perfect_freehand's stroke options.
extension StrokeOptionsExtension on StrokeOptions {
  /// Puts the app-wide defaults in place. Called at start-up and before
  /// reading a note, so options missing from a file fall back to these.
  static void setDefaults() {
    // the line itself
    StrokeOptions.defaultSize = 10;
    StrokeOptions.defaultThinning = 0.5;
    StrokeOptions.defaultSmoothing = 0;
    StrokeOptions.defaultStreamline = 0.5;
    StrokeOptions.defaultSimulatePressure = true;

    // its two ends: a round cap, no taper
    StrokeEndOptions.defaultCap = true;
    StrokeEndOptions.defaultTaperEnabled = false;
  }
}
