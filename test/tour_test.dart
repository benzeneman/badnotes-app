import 'package:badnotes/components/onboarding/tour.dart';
import 'package:badnotes/components/onboarding/tour_engine.dart';
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
    // the scenes loop for ever, so no pumpAndSettle
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(FeatureTour), findsOneWidget);
  }

  for (final (name, size) in [
    ('tablet', const Size(1280, 800)),
    ('phone', const Size(390, 844)),
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
        // a few moments into the scene
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 1500));
        }
        pages++;
      }
      expect(pages, 9);
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

  testWidgets('A tap beside the card does nothing', (tester) async {
    await pumpHome(tester, const Size(1280, 800));
    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(FeatureTour), findsOneWidget);
  });

  testWidgets('Swiping moves between pages', (tester) async {
    await pumpHome(tester, const Size(1280, 800));
    expect(find.text('WELCOME'), findsOneWidget);
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text('PENS'), findsOneWidget);
    expect(find.text('2 / 9'), findsOneWidget);
  });

  /// The scene time of the stage that is playing (or of one that isn't).
  double timeOf(WidgetTester tester, {bool playing = true}) => tester
      .state<TourStageState>(
        find
            .byWidgetPredicate((w) => w is TourStage && w.playing == playing)
            .first,
      )
      .time;

  testWidgets('Next starts the new page from its first frame', (tester) async {
    await pumpHome(tester, const Size(1280, 800));
    await tester.pump(const Duration(milliseconds: 3000));
    final outgoing = timeOf(tester);
    expect(outgoing, greaterThan(0.1));
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(find.text('2 / 9'), findsOneWidget);
    // the page coming in is at the start, the one going out where it was
    expect(timeOf(tester), lessThan(0.01));
    expect(timeOf(tester, playing: false), closeTo(outgoing, 0.001));
  });

  testWidgets('Back starts the page from its first frame', (tester) async {
    await pumpHome(tester, const Size(1280, 800));
    await tester.tap(find.text('Next'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 3000));
    await tester.tap(find.text('Back'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(find.text('1 / 9'), findsOneWidget);
    expect(timeOf(tester), lessThan(0.01));
  });

  testWidgets('A page dragged in shows its first frame', (tester) async {
    await pumpHome(tester, const Size(1280, 800));
    await tester.pump(const Duration(milliseconds: 3000));
    final g = await tester.startGesture(tester.getCenter(find.byType(PageView)));
    await g.moveBy(const Offset(-30, 0));
    await g.moveBy(const Offset(-120, 0));
    await tester.pump();
    // partly in, not playing yet: at t = 0
    expect(timeOf(tester, playing: false), 0);
    await g.moveBy(const Offset(-500, 0));
    await g.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(find.text('2 / 9'), findsOneWidget);
    expect(timeOf(tester), lessThan(0.01));
  });

  testWidgets('Every page ends whole and readable', (tester) async {
    await pumpHome(tester, const Size(1280, 800));
    final scale = tester.getSize(find.byType(TourStage).first).width / stageSize.width;
    for (final scene in tourScenes) {
      if (scene.inks.isEmpty) continue;
      final cam = scene.cam ?? fitAll(scene.inks);
      final m = cam.matrix(scene.done, scene.view);
      final zoom = cam.at(scene.done, scene.view).$2;
      final view = scene.view.inflate(0.5);
      for (final d in scene.inks) {
        final r = MatrixUtils.transformRect(m, d.bounds);
        expect(
          r.left >= view.left && r.top >= view.top &&
              r.right <= view.right && r.bottom <= view.bottom,
          isTrue,
          reason: '$d at $r is outside $view',
        );
        if (d is InkText) {
          expect(d.size * zoom * scale, greaterThanOrEqualTo(14), reason: d.text);
        }
      }
    }
  });
}
