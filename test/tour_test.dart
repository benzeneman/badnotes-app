import 'package:badnotes/components/onboarding/tour.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/data/flavor_config.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    FlavorConfig.setup();
    stows.tourSeen.value = false;
  });

  /// A page with a button that opens the tour, [size] big.
  Future<void> pumpHome(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: BadNotesTheme.create(Brightness.light),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showFeatureTour(context),
                child: const Text('Open tour'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open tour'));
    // the demos loop for ever, so no pumpAndSettle
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(FeatureTour), findsOneWidget);
  }

  for (final (name, size) in [
    ('tablet', const Size(1280, 800)),
    ('phone', const Size(400, 860)),
  ]) {
    testWidgets('Next goes through every page and closes ($name)', (
      tester,
    ) async {
      await pumpHome(tester, size);
      expect(stows.tourSeen.value, isTrue);
      var pages = 1;
      while (find.text('Next').evaluate().isNotEmpty) {
        await tester.tap(find.text('Next'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        // a few frames into the demo
        await tester.pump(const Duration(seconds: 2));
        pages++;
      }
      expect(pages, 12);
      expect(find.text('Skip'), findsNothing);
      await tester.tap(find.text('Get started'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(FeatureTour), findsNothing);
    });
  }

  testWidgets('Skip closes the tour and marks it seen', (tester) async {
    await pumpHome(tester, const Size(1280, 800));
    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(FeatureTour), findsNothing);
    expect(stows.tourSeen.value, isTrue);
  });

  testWidgets('Swiping moves between pages', (tester) async {
    await pumpHome(tester, const Size(1280, 800));
    expect(find.text('WELCOME'), findsOneWidget);
    await tester.fling(
      find.byType(FeatureTour),
      const Offset(-300, 0),
      1000,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('LASSO'), findsOneWidget);
  });
}
