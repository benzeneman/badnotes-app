import 'dart:ui';

import 'package:fixnum/fixnum.dart';

/// How a shape's outline is drawn.
enum ShapeLine { none, solid, dashed, dotted }

/// What's at one end of a line.
enum ShapeArrow { none, open, filled }

/// Fill, outline and arrowheads of a shape. Plain values, so it can be saved
/// and copied. Strokes without one are drawn as they always were: a solid
/// outline, no fill.
class ShapeStyle {
  const ShapeStyle({
    this.fill,
    this.line = ShapeLine.solid,
    this.rounded = true,
    this.arrowStart = ShapeArrow.none,
    this.arrowEnd = ShapeArrow.none,
  });

  /// The inside's color with its opacity, or null for none.
  final Color? fill;
  final ShapeLine line;
  final bool rounded;
  final ShapeArrow arrowStart, arrowEnd;

  static const plain = ShapeStyle();

  bool get isPlain =>
      fill == null &&
      line == ShapeLine.solid &&
      rounded &&
      arrowStart == ShapeArrow.none &&
      arrowEnd == ShapeArrow.none;

  ShapeStyle copyWith({
    Color? Function()? fill,
    ShapeLine? line,
    bool? rounded,
    ShapeArrow? arrowStart,
    ShapeArrow? arrowEnd,
  }) => ShapeStyle(
    fill: fill == null ? this.fill : fill(),
    line: line ?? this.line,
    rounded: rounded ?? this.rounded,
    arrowStart: arrowStart ?? this.arrowStart,
    arrowEnd: arrowEnd ?? this.arrowEnd,
  );

  Map<String, dynamic> toJson() => {
    if (fill != null) 'f': fill!.toARGB32(),
    if (line != ShapeLine.solid) 'l': line.index,
    if (!rounded) 'r': false,
    if (arrowStart != ShapeArrow.none) 'as': arrowStart.index,
    if (arrowEnd != ShapeArrow.none) 'ae': arrowEnd.index,
  };

  static int? _int(Object? value) => switch (value) {
    final int v => v,
    final Int64 v => v.toInt(),
    _ => null,
  };

  static ShapeStyle? fromJson(Object? json) {
    if (json is! Map) return null;
    T pick<T extends Enum>(List<T> values, Object? v, T fallback) {
      final i = _int(v);
      return i != null && i >= 0 && i < values.length ? values[i] : fallback;
    }

    final fill = _int(json['f']);
    return ShapeStyle(
      fill: fill == null ? null : Color(fill),
      line: pick(ShapeLine.values, json['l'], ShapeLine.solid),
      rounded: json['r'] != false,
      arrowStart: pick(ShapeArrow.values, json['as'], ShapeArrow.none),
      arrowEnd: pick(ShapeArrow.values, json['ae'], ShapeArrow.none),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ShapeStyle &&
      other.fill == fill &&
      other.line == line &&
      other.rounded == rounded &&
      other.arrowStart == arrowStart &&
      other.arrowEnd == arrowEnd;

  @override
  int get hashCode => Object.hash(fill, line, rounded, arrowStart, arrowEnd);
}
