import 'package:flutter/material.dart';

extension ListExtensions<T> on List<T> {
  /// The item at [index], or null if there's none there.
  T? getOrNull(int index) => index >= 0 && index < length ? this[index] : null;
}

extension OffsetListExtensions on List<Offset> {
  /// Moves every point by [offset], in place.
  void shift(Offset offset) {
    for (final (i, point) in indexed) {
      this[i] = point + offset;
    }
  }
}
