import 'package:badnotes/components/canvas/shape_style.dart';
import 'package:badnotes/components/editor_ui/option_previews.dart';
import 'package:badnotes/data/flavor_config.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/tools/eraser.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(FlavorConfig.setup);

  final previews = <String, Widget Function()>{
    'pressure': () => const PressurePreview(),
    'lasso': () => const LassoPreview(),
    'palm': () => const PalmPreview(),
    'eraser precision': () => const EraserPreview(EraserType.precision),
    'eraser stroke': () => const EraserPreview(EraserType.stroke),
    'scribble': () => const ScribblePreview(),
    'laser line': () =>
        const LaserPreview(dot: false, color: Colors.red, glow: true),
    'laser dot': () =>
        const LaserPreview(dot: true, color: Colors.red, glow: false),
    'scroll vertical': () => const ScrollPreview(horizontal: false),
    'scroll horizontal': () => const ScrollPreview(horizontal: true),
    'tape': () => const TapePreview(),
    'snap circle': () => const SnapPreview.circle(),
    'snap rectangle': () => const SnapPreview.rectangle(),
    'circle to lasso': () => const CircleLassoPreview(),
    'dark ink': () => const DarkInkPreview(),
    for (final line in ShapeLine.values)
      'shape stroke ${line.name}': () => ShapeStylePreview(
        style: ShapeStyle(
          line: line,
          fill: const Color(0x332B4ACB),
          arrowStart: ShapeArrow.open,
          arrowEnd: ShapeArrow.filled,
        ),
        color: const Color(0xFF2B4ACB),
        width: 3,
      ),
  };

  for (final MapEntry(:key, :value) in previews.entries) {
    testWidgets('$key plays a whole loop', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: SizedBox(width: 260, child: value())),
          ),
        ),
      );
      // through every phase of the 3.2 s loop, and round again
      for (var i = 0; i < 24; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('previews follow their settings while playing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              PressurePreview(),
              LassoPreview(),
              PalmPreview(),
              TapePreview(),
              SnapPreview.circle(),
              DarkInkPreview(),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1600));
    stows.pressureCurve.value = 'firm';
    stows.lassoFilter.value = ['handwriting'];
    stows.leftHanded.value = !stows.leftHanded.value;
    stows.tapePattern.value = 'dots';
    stows.tapeColor.value = 0xFF42A5F5;
    stows.shapeFill.value = !stows.shapeFill.value;
    stows.editorAutoInvert.value = !stows.editorAutoInvert.value;
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 1600));
    expect(tester.takeException(), isNull);
  });

  testWidgets('still when the system asks for less motion', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: LassoPreview()),
        ),
      ),
    );
    // nothing scheduled: settles at once
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
