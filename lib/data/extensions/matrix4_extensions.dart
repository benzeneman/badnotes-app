import 'package:vector_math/vector_math_64.dart';

extension Matrix4Extensions on Matrix4 {
  /// The zoom of a transform that only moves and zooms evenly (no turning or
  /// stretching): its first entry. Cheap, unlike working out the real scale.
  double get approxScale => entry(0, 0);
}
