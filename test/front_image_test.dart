import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:badnotes/data/editor/page.dart';
import 'package:sbn/has_size.dart';

Stroke _line(Offset a, Offset b) => Stroke(
  color: Colors.black,
  pressureEnabled: false,
  options: StrokeOptions(size: 2, isComplete: true),
  pageIndex: 0,
  page: const HasSize(Size(500, 500)),
  toolId: .fountainPen,
)..addPoints([a, b]);

void main() {
  test('whether a stroke is on a picture is saved, and copied', () {
    for (final on in [true, false, null]) {
      final stroke = _line(const Offset(10, 10), const Offset(50, 10))
        ..onFrontImage = on;
      final loaded = Stroke.fromJson(
        stroke.toJson(),
        fileVersion: 19,
        pageIndex: 0,
        page: const HasSize(Size(500, 500)),
      );
      expect(loaded.onFrontImage, on);
      expect(stroke.copy().onFrontImage, on);
    }
  });

  test('writing a picture is put over stays under it', () {
    final page = EditorPage();
    final stroke = _line(const Offset(100, 100), const Offset(150, 100));
    page.strokes.add(stroke);
    page.putImagesInFront([], layer: 0);
    expect(stroke.onFrontImage, isFalse);
    expect(page.isOnFrontImage(stroke), isFalse);
  });
}
