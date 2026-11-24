import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:perfect_freehand/perfect_freehand.dart';
import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:sbn/has_size.dart';
import 'package:sbn/tool_id.dart';

/// A fountain pen line at [sharpness] (tip sharpness, 0 to 1) and
/// [sensitivity] (pressure sensitivity, 0 to 1): the pen pressed lightly
/// then harder along it, written slowly then fast then slowly.
Stroke _line(double sharpness, double sensitivity, Offset at) {
  final stroke =
      Stroke(
          color: Colors.black,
          pressureEnabled: true,
          options: StrokeOptions(
            size: 5,
            thinning: sharpness * 0.9,
            isComplete: true,
          ),
          pageIndex: 0,
          page: const HasSize(Size(1200, 800)),
          toolId: ToolId.fountainPen,
        )
        ..nib2 = true
        ..speedInk = true;
  var x = 0.0;
  for (var i = 0; i <= 120; i++) {
    // slow, fast, slow
    final t = i / 120;
    x += t < 0.3 || t > 0.7 ? 1.2 : 9.0;
    final raw = 0.1 + 0.9 * t;
    // as [Pen] spreads it by the pressure sensitivity setting
    final pressure = (0.5 + (raw - 0.5) * sensitivity * 2).clamp(0.0, 1.0);
    stroke.addPoint(at + Offset(x * 0.75, 40 * sin(i / 9)), pressure);
  }
  return stroke;
}

void main() {
  testWidgets('fountain pen: tip sharpness by pressure sensitivity', (
    tester,
  ) async {
    const sharp = [0.0, 0.5, 1.0], sensitive = [0.0, 0.4, 1.0];
    final widths = <String, (double, double)>{};
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..drawColor(Colors.white, BlendMode.src);
    final paint = Paint()..color = Colors.black;
    for (final (r, s) in sharp.indexed) {
      for (final (c, p) in sensitive.indexed) {
        final stroke = _line(s, p, Offset(30 + c * 390.0, 90 + r * 230.0));
        canvas.drawPath(stroke.highQualityPath, paint);
        final nib = stroke.nibPressures;
        widths['sharp ${s * 100}% pressure ${p * 100}%'] = (
          nib.reduce(min),
          nib.reduce(max),
        );
      }
    }
    final image = await tester.runAsync(
      () => recorder.endRecording().toImage(1200, 720),
    );
    final out = Platform.environment['INK_PNG'];
    if (out != null) {
      final png = await tester.runAsync(
        () => image!.toByteData(format: ui.ImageByteFormat.png),
      );
      File('$out/pen-matrix.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    }
    image!.dispose();
    for (final entry in widths.entries) {
      // ignore: avoid_print
      print(
        '${entry.key}: nib ${entry.value.$1.toStringAsFixed(2)}'
        ' to ${entry.value.$2.toStringAsFixed(2)}',
      );
    }
    // pressure sensitivity must change the width, more as it goes up
    double range(double s, double p) {
      final w = widths['sharp ${s * 100}% pressure ${p * 100}%']!;
      return w.$2 - w.$1;
    }

    expect(range(0, 1), greaterThan(range(0, 0.4)));
    expect(range(0, 0.4), greaterThan(range(0, 0) + 0.05));
    // and still at full tip sharpness: the speed doesn't swallow it
    expect(range(1, 1), greaterThan(range(1, 0) + 0.2));
    expect(range(1, 0.4), greaterThan(range(1, 0) + 0.05));
    // tip sharpness thins the fast middle
    expect(range(1, 0), greaterThan(range(0, 0) + 0.1));
    // never a hairline
    for (final w in widths.values) {
      expect(w.$1, greaterThan(0.14));
    }
  });
}
