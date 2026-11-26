import 'package:bson/bson.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:badnotes/data/editor/editor_core_info.dart';
import 'package:badnotes/data/editor/page.dart';
import 'package:badnotes/data/extensions/json_int.dart';
import 'package:badnotes/data/flavor_config.dart';
import 'package:badnotes/data/tools/pen.dart';

/// A picture's order is a timestamp in microseconds: past 31 bits, BSON
/// gives it back as an Int64, and reading it `as int` made the note open as
/// corrupted.
void main() {
  setUp(FlavorConfig.setup);

  final big = DateTime(2026, 11, 26).microsecondsSinceEpoch;

  Map<String, dynamic> throughBson(Map<String, dynamic> json) =>
      BsonCodec.deserialize(BsonCodec.serialize(json));

  test('a big number reads back from BSON', () {
    expect(jsonInt(throughBson({'io': big})['io']), big);
    expect(jsonInt(throughBson({'n': 3})['n']), 3);
    expect(jsonInt(null), isNull);
  });

  test('ink drawn after a picture reads back', () {
    final pen = Pen.fountainPen();
    final page = EditorPage();
    pen.onDragStart(const Offset(10, 10), page, 0, null);
    pen.onDragUpdate(const Offset(40, 30), null);
    final stroke = pen.onDragEnd()!..afterImage = big;
    final back = Stroke.fromJson(
      throughBson(stroke.toJson()),
      fileVersion: EditorCoreInfo.sbnVersion,
      pageIndex: 0,
      page: page,
    );
    expect(back.afterImage, big);
  });
}
