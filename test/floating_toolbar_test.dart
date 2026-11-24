import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:badnotes/components/editor_ui/floating_toolbar.dart';
import 'package:badnotes/data/flavor_config.dart';
import 'package:badnotes/data/prefs.dart';

void main() {
  setUp(() {
    FlavorConfig.setup();
    stows.floatingToolbarEdge.value = ToolbarEdge.top.index;
    stows.floatingToolbarAlong.value = 0.3;
  });

  Future<void> pumpBar(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1340);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: FloatingToolbar(
                  builder: (context, axis) => Flex(
                    direction: axis,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final icon in [
                        Icons.brush,
                        Icons.create,
                        Icons.circle,
                      ])
                        IconButton(onPressed: () {}, icon: Icon(icon)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('held, the whole bar follows; a ghost only near an edge', (
    tester,
  ) async {
    await pumpBar(tester);
    final ghost = find.byKey(const ValueKey('toolbar-ghost'));
    final start = tester.getCenter(find.byIcon(Icons.create));
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 400)); // long press
    await gesture.moveTo(const Offset(400, 600));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.brush), findsOneWidget, reason: 'the whole bar');
    expect(
      (tester.getCenter(find.byIcon(Icons.create)) - const Offset(400, 600))
          .distance,
      lessThan(60),
      reason: 'under the finger',
    );
    expect(ghost, findsNothing, reason: 'far from every edge');

    // most of the way to the right, but not close: still no ghost
    await gesture.moveTo(const Offset(650, 600));
    await tester.pumpAndSettle();
    expect(ghost, findsNothing, reason: '150 px from the edge');

    // close to the right edge: the ghost shows where it'll land
    await gesture.moveTo(const Offset(760, 600));
    await tester.pumpAndSettle();
    expect(ghost, findsOneWidget);

    // a shaking finger at the border doesn't flicker
    for (final x in [700.0, 760.0, 690.0, 770.0]) {
      await gesture.moveTo(Offset(x, 600));
      await tester.pump(const Duration(milliseconds: 16));
      expect(ghost, findsOneWidget);
    }

    // let go: the bar is there, upright
    await gesture.up();
    await tester.pumpAndSettle();
    expect(stows.floatingToolbarEdge.value, ToolbarEdge.right.index);
    final brush = tester.getCenter(find.byIcon(Icons.brush));
    final circle = tester.getCenter(find.byIcon(Icons.circle));
    expect(
      (brush.dx - circle.dx).abs(),
      lessThan(4),
      reason: 'laid out upright',
    );
  });

  testWidgets('no grip: only the buttons', (tester) async {
    await pumpBar(tester);
    // the old grip was a 4 by 18 rounded bar before the buttons
    final grips = tester
        .widgetList<Container>(find.byType(Container))
        .where(
          (c) =>
              c.constraints?.maxWidth == 4 ||
              (c.decoration is BoxDecoration &&
                  (c.decoration! as BoxDecoration).borderRadius ==
                      BorderRadius.circular(2)),
        );
    expect(grips, isEmpty);
  });

  testWidgets('at the top it goes as far right as the margin', (tester) async {
    stows.floatingToolbarAlong.value = 1;
    await pumpBar(tester);
    final bar = tester.getRect(find.byType(Material).last);
    // clear of the floating undo/redo pill at the top right (114 px with
    // its gap), but as far right as that allows
    expect(bar.right, lessThanOrEqualTo(800 - 114));
    expect(bar.right, greaterThan(800 - 114 - 40));
  });
}
