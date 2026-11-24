import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:sbn/has_size.dart';
import 'package:sbn/tool_id.dart';

Stroke _line() => Stroke(
  color: Colors.black,
  pressureEnabled: false,
  options: StrokeOptions(size: 4, isComplete: true),
  pageIndex: 0,
  page: const HasSize(Size(1000, 1400)),
  toolId: ToolId.ballpointPen,
)..addPoints(const [Offset(10, 10), Offset(50, 60), Offset(90, 20)]);

List<String> _bytes(Map<String, dynamic> json) => [
  for (final point in json['p'] as List) point.toString(),
];

void main() {
  group('A save encodes only strokes that changed', () {
    test('an unchanged stroke gives back the same bytes', () {
      final stroke = _line();
      final first = stroke.toJson()['p'];
      final second = stroke.toJson()['p'];
      expect(identical(first, second), isTrue);
    });

    test('a moved stroke is encoded again', () {
      final stroke = _line();
      final before = _bytes(stroke.toJson());
      stroke.shift(const Offset(5, 7));
      final after = stroke.toJson();
      expect(_bytes(after), isNot(before));
      expect(identical(after['p'], stroke.toJson()['p']), isTrue);
    });

    test('a stroke with more points is encoded again', () {
      final stroke = _line();
      final before = (stroke.toJson()['p'] as List).length;
      stroke.addPoint(const Offset(120, 40));
      expect((stroke.toJson()['p'] as List).length, before + 1);
    });
  });
}
