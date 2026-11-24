import 'package:badnotes/components/home/pin_board.dart';
import 'package:badnotes/components/home/quick_board.dart';
import 'package:badnotes/components/home/quick_composer.dart';
import 'package:badnotes/components/home/quick_ink.dart';
import 'package:badnotes/data/flavor_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

BoardItem _note(String id, Rect box) => BoardItem(
  id: id,
  photo: null,
  text: 'Note $id',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  box: box,
);

/// The zoom of the (only) pinch-zoomed view on screen.
double _zoom(WidgetTester tester) => tester
    .widget<Transform>(find.byKey(const ValueKey('pinch-zoom-transform')))
    .transform
    .getMaxScaleOnAxis();

/// Two fingers at [a] and [b] that move apart by [spread] each.
Future<void> _pinch(
  WidgetTester tester,
  Offset a,
  Offset b, {
  Offset spread = const Offset(160, 60),
  Future<void> Function(TestGesture first)? betweenFingers,
}) async {
  final first = await tester.startGesture(a, pointer: 1);
  await tester.pump();
  await betweenFingers?.call(first);
  final second = await tester.startGesture(b, pointer: 2);
  await tester.pump();
  for (var i = 0; i < 10; i++) {
    await first.moveBy(-spread / 10);
    await second.moveBy(spread / 10);
    await tester.pump(const Duration(milliseconds: 16));
  }
  await first.up();
  await second.up();
  await tester.pump();
}

void main() {
  setUp(FlavorConfig.setup);

  testWidgets('two fingers zoom the full board, also starting on a note', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PinBoard(
            items: [
              _note('a', const Rect.fromLTWH(40, 40, 420, 360)),
              _note('b', const Rect.fromLTWH(520, 40, 420, 360)),
            ],
            openNote: (_, _) => fail('a pinch is not a tap'),
            openPhoto: (_, _) => fail('a pinch is not a tap'),
            minHeight: 800,
            zoomable: true,
          ),
        ),
      ),
    );
    expect(_zoom(tester), closeTo(1, 0.001));

    // the first finger on note "a" (on screen at 48..552, 48..480)
    final onNote = tester.getCenter(find.text('Note a'));
    await _pinch(tester, onNote, onNote + const Offset(300, 120));
    expect(_zoom(tester), greaterThan(1.2));
  });

  testWidgets('a pinch on the composer pad zooms and writes nothing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => showQuickComposer(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('New quick note'), findsOneWidget);
    expect(_zoom(tester), closeTo(1, 0.001));

    final pad = tester.getCenter(find.byType(QuickInkPad));
    await _pinch(
      tester,
      pad - const Offset(80, 0),
      pad + const Offset(80, 0),
      // the first finger starts writing before the second lands
      betweenFingers: (first) async {
        for (var i = 0; i < 3; i++) {
          await first.moveBy(const Offset(8, 4));
          await tester.pump(const Duration(milliseconds: 16));
        }
      },
    );
    expect(_zoom(tester), greaterThan(1.2));
    expect(tester.widget<QuickInkPad>(find.byType(QuickInkPad)).ink, isEmpty);
  });
}
