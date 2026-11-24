import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:badnotes/components/canvas/shape_style.dart';
import 'package:sbn/has_size.dart';

/// Reads the saved `c` colour of a shape: an int, a BSON Int64, or nothing at
/// all (then the stroke default).
Color _savedColor(Object? raw) => switch (raw) {
  final int argb => Color(argb),
  final Int64 argb => Color(argb.toInt()),
  null => Stroke.defaultColor,
  _ => throw Exception('Invalid color value: (${raw.runtimeType}) $raw'),
};

/// An axis-aligned box drawn with the shape pen.
///
/// Unlike freehand ink it keeps no points: the box itself, [rect], is the
/// whole shape, and it is saved under the keys `rl`, `rt`, `rw` and `rh`.
class RectangleStroke extends Stroke {
  /// The box, in page coordinates.
  Rect rect;

  new({
    required super.color,
    required super.pressureEnabled,
    required super.options,
    required super.pageIndex,
    required super.page,
    required super.toolId,
    required this.rect,
  }) {
    // a box is finished the moment it exists
    options.isComplete = true;
  }

  factory fromJson(
    Map<String, dynamic> json, {
    required int fileVersion,
    required int pageIndex,
    required HasSize page,
  }) {
    assert(json['shape'] == 'rect');
    assert(json['i'] == pageIndex || json['i'] == null);

    final box = Rect.fromLTWH(
      json['rl'] ?? 0,
      json['rt'] ?? 0,
      json['rw'] ?? 0,
      json['rh'] ?? 0,
    );
    final stroke = RectangleStroke(
      color: _savedColor(json['c']),
      pressureEnabled: json['pe'] ?? Stroke.defaultPressureEnabled,
      options: StrokeOptions.fromJson(json),
      pageIndex: pageIndex,
      page: page,
      toolId: .parsePenType(json['ty'], fallback: .shapePen),
      rect: box,
    );
    stroke.shapeStyle = ShapeStyle.fromJson(json['ss']);
    stroke.holes = Stroke.holesFromJson(json['eh']);
    stroke.onFrontImage = json['of'] as bool?;
    return stroke;
  }

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'shape': 'rect',
      'i': pageIndex,
      'rl': rect.left,
      'rt': rect.top,
      'rw': rect.width,
      'rh': rect.height,
      'pe': pressureEnabled,
      'c': color.toARGB32(),
    };
    final style = shapeStyle;
    if (style != null) json['ss'] = style.toJson();
    if (holes.isNotEmpty) json['eh'] = holesJson;
    if (onFrontImage != null) json['of'] = onFrontImage;
    json.addAll(options.toJson());
    return json;
  }

  @override
  bool get isEmpty => rect.isEmpty;

  /// How many outline points a full-quality box has (16 on each side).
  @override
  int get length => 64;

  /// The outline of the box as points, walked from the top-left corner down
  /// the left edge, then along the bottom, up the right and back along the
  /// top. Every edge gets the same share of [length], divided by the
  /// quality's N.
  @override
  List<Offset> getPolygon({required StrokeQuality quality}) {
    final perEdge = length / 4 ~/ quality.N;
    final left = rect.left, top = rect.top;
    final right = rect.right, bottom = rect.bottom;
    final width = rect.width, height = rect.height;
    return [
      for (var i = 0; i < perEdge; ++i)
        Offset(left, top + height * i / perEdge),
      for (var i = 0; i < perEdge; ++i)
        Offset(left + width * i / perEdge, bottom),
      for (var i = 0; i < perEdge; ++i)
        Offset(right, bottom - height * i / perEdge),
      for (var i = 0; i < perEdge; ++i)
        Offset(right - width * i / perEdge, top),
    ];
  }

  /// The box is drawn straight from [rect]; the polygon is not needed.
  @override
  Path getPath(List<Offset> polygon, {bool smooth = true}) =>
      Path()..addRect(rect);

  @override
  @Deprecated('Cannot add points to a rectangle stroke.')
  void addPoint(Offset point, [double? pressure]) =>
      throw UnsupportedError('Cannot add points to a rectangle stroke.');

  @override
  @Deprecated('Cannot pop points from a rectangle stroke.')
  void popFirstPoint() =>
      throw UnsupportedError('Cannot pop points from a rectangle stroke.');

  /// Nothing to thin out: a box has no points.
  @override
  void optimisePoints({double thresholdMultiplier = 0}) {}

  @override
  String toSvgPath() {
    final l = rect.left, t = rect.top, r = rect.right, b = rect.bottom;
    return 'M$l,$t L$r,$t L$r,$b L$l,$b Z';
  }

  @override
  double get maxY => rect.bottom;

  /// Moves both corners. The result is exact for quarter turns, which are
  /// the only rotations the selection bar offers.
  @override
  void transform(Offset center, double scale, double angle) {
    rect = Rect.fromPoints(
      Stroke.transformPoint(rect.topLeft, center, scale, angle),
      Stroke.transformPoint(rect.bottomRight, center, scale, angle),
    );
    super.transform(center, scale, angle);
  }

  @override
  void mapRect(Rect from, Rect to) {
    rect = Rect.fromPoints(
      Stroke.mapPoint(rect.topLeft, from, to),
      Stroke.mapPoint(rect.bottomRight, from, to),
    );
    super.mapRect(from, to);
  }

  @override
  void shift(Offset offset) {
    rect = rect.shift(offset);
    super.shift(offset);
  }

  @override
  void reshapeLike(Stroke other) {
    if (other is RectangleStroke) rect = other.rect;
    super.reshapeLike(other);
  }

  @override
  @Deprecated('We already know the shape is a rectangle.')
  bool isStraightLine([int minLength = 0]) => false;

  @override
  RectangleStroke copy() {
    final twin = RectangleStroke(
      color: color,
      pressureEnabled: pressureEnabled,
      options: options.copyWith(),
      pageIndex: pageIndex,
      page: page,
      toolId: toolId,
      rect: rect,
    );
    twin.layer = layer;
    twin.holes = holes;
    twin.onFrontImage = onFrontImage;
    twin.shapeStyle = shapeStyle;
    return twin;
  }
}
