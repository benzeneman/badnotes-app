import 'dart:typed_data';
import 'dart:ui' show Offset;

import 'package:bson/bson.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

/// How a single ink point is stored in a note file, and a small helper for
/// moving one.
///
/// In the current format a point is one BSON binary blob of 32-bit
/// floats: x, then y, then the pen pressure if there was any (so 8 or 12
/// bytes).
extension PointExtensions on PointVector {
  /// Reads a point from the very old format, where it was a map with `x`,
  /// `y` and `p` (pressure) keys. [offset] is added to the position.
  @Deprecated(
    'Use fromBsonBinary instead; fromJson is only for backward compatibility',
  )
  static Point fromJson({
    required Map<String, dynamic> json,
    Offset offset = .zero,
  }) {
    final x = json['x'] + offset.dx;
    final y = json['y'] + offset.dy;
    return Point(x, y, json['p']);
  }

  /// Reads a point from its binary blob, see the format above, and moves it
  /// by [offset].
  static PointVector fromBsonBinary({
    required BsonBinary json,
    Offset offset = .zero,
  }) {
    final floats = json.byteList.buffer.asFloat32List();
    final hasPressure = floats.length != 2;
    return PointVector(
      floats[0] + offset.dx,
      floats[1] + offset.dy,
      hasPressure ? floats[2] : null,
    );
  }

  /// Packs this point into its binary blob, see the format above.
  BsonBinary toBsonBinary() {
    final p = pressure;
    final floats = Float32List(p == null ? 2 : 3)
      ..[0] = x
      ..[1] = y;
    if (p != null) floats[2] = p;
    return BsonBinary.from(floats.buffer.asUint8List());
  }

  /// This point moved by [offset], with the same pressure.
  PointVector operator +(Offset offset) =>
      PointVector(x + offset.dx, y + offset.dy, pressure);
}
