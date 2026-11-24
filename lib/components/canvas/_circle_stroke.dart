import 'dart:math';

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

/// A round shape from the shape pen, kept as just a [center] and a [radius]
/// (saved as `cx`, `cy` and `r`) instead of a list of points.
class CircleStroke extends Stroke {
  /// The middle of the circle, in page coordinates.
  Offset center;

  /// Distance from [center] to the edge.
  double radius;

  new({
    required super.color,
    required super.pressureEnabled,
    required super.options,
    required super.pageIndex,
    required super.page,
    required super.toolId,
    required this.center,
    required this.radius,
  }) {
    // a circle is finished the moment it exists
    options.isComplete = true;
  }

  factory fromJson(
    Map<String, dynamic> json, {
    required int fileVersion,
    required int pageIndex,
    required HasSize page,
  }) {
    assert(json['shape'] == 'circle');
    assert(json['i'] == pageIndex || json['i'] == null);

    final stroke = CircleStroke(
      color: _savedColor(json['c']),
      pressureEnabled: json['pe'] ?? Stroke.defaultPressureEnabled,
      options: StrokeOptions.fromJson(json),
      pageIndex: pageIndex,
      page: page,
      toolId: .parsePenType(json['ty'], fallback: .shapePen),
      center: Offset(json['cx'] ?? 0, json['cy'] ?? 0),
      radius: json['r'] ?? 0,
    );
    stroke.shapeStyle = ShapeStyle.fromJson(json['ss']);
    stroke.holes = Stroke.holesFromJson(json['eh']);
    stroke.onFrontImage = json['of'] as bool?;
    return stroke;
  }

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'shape': 'circle',
      'i': pageIndex,
      'cx': center.dx,
      'cy': center.dy,
      'r': radius,
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
  bool get isEmpty => radius <= 0;

  /// How many outline points a full-quality circle has.
  @override
  int get length => 24;

  /// Evenly spaced points round the edge, starting at angle 0 (to the right
  /// of [center]) and going the positive way. There are 24 divided by the
  /// quality's N of them.
  @override
  List<Offset> getPolygon({required StrokeQuality quality}) {
    final count = 24 ~/ quality.N;
    return List.generate(count, (i) {
      final angle = i / count * 2 * pi;
      return Offset(
        cos(angle) * radius + center.dx,
        sin(angle) * radius + center.dy,
      );
    });
  }

  /// The circle is drawn straight from [center] and [radius]; the polygon is
  /// not needed.
  @override
  Path getPath(List<Offset> polygon, {bool smooth = true}) =>
      Path()..addOval(Rect.fromCircle(center: center, radius: radius));

  @override
  @Deprecated('Cannot add points to a circle stroke.')
  void addPoint(Offset point, [double? pressure]) =>
      throw UnsupportedError('Cannot add points to a circle stroke.');

  @override
  @Deprecated('Cannot pop points from a circle stroke.')
  void popFirstPoint() =>
      throw UnsupportedError('Cannot pop points from a circle stroke.');

  /// Nothing to thin out: a circle has no points.
  @override
  void optimisePoints({double thresholdMultiplier = 0}) {}

  /// Two half-circle arcs, starting from the leftmost point.
  @override
  String toSvgPath() {
    final r = radius;
    final arc = 'a$r,$r 0 1,0';
    return 'M${center.dx},${center.dy} m${-r},0 $arc ${r * 2},0 $arc ${-r * 2},0';
  }

  @override
  double get maxY => center.dy + radius;

  @override
  void transform(Offset center, double scale, double angle) {
    this.center = Stroke.transformPoint(this.center, center, scale, angle);
    radius *= scale;
    super.transform(center, scale, angle);
  }

  /// Stretching a circle keeps it round: the radius grows by the average of
  /// the horizontal and vertical stretch.
  @override
  void mapRect(Rect from, Rect to) {
    center = Stroke.mapPoint(center, from, to);
    final stretchX = from.width == 0 ? 1 : to.width / from.width;
    final stretchY = from.height == 0 ? 1 : to.height / from.height;
    radius *= (stretchX + stretchY) / 2;
    super.mapRect(from, to);
  }

  @override
  void shift(Offset offset) {
    center += offset;
    super.shift(offset);
  }

  @override
  void reshapeLike(Stroke other) {
    if (other is CircleStroke) {
      center = other.center;
      radius = other.radius;
    }
    super.reshapeLike(other);
  }

  @override
  @Deprecated('We already know the shape is a circle.')
  bool isStraightLine([int minLength = 0]) => false;

  @override
  CircleStroke copy() {
    final twin = CircleStroke(
      color: color,
      pressureEnabled: pressureEnabled,
      options: options.copyWith(),
      pageIndex: pageIndex,
      page: page,
      toolId: toolId,
      center: center,
      radius: radius,
    );
    twin.layer = layer;
    twin.holes = holes;
    twin.onFrontImage = onFrontImage;
    twin.shapeStyle = shapeStyle;
    return twin;
  }
}
