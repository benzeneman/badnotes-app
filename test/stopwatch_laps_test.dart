import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:badnotes/components/editor/canvas_tools_overlay.dart';

void main() {
  test('laps keep the focus time at each lap, and reset clears them', () {
    var now = DateTime(2026);
    final watch = StudyStopwatch(clock: () => now);
    now = now.add(const Duration(seconds: 90));
    watch.lap();
    watch.onBreak = true;
    now = now.add(const Duration(minutes: 5));
    watch.onBreak = false;
    now = now.add(const Duration(seconds: 30));
    watch.lap();
    expect(watch.laps, const [Duration(seconds: 90), Duration(minutes: 2)]);
    watch.reset();
    expect(watch.laps, isEmpty);
  });

  widgetTests();
}

/// A page with a timer's chip on it, opened from a first page, the way the
/// editor is opened from the home screen.
class _TimerPage extends StatefulWidget {
  const _TimerPage();

  @override
  State<_TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<_TimerPage> {
  var _shown = true;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: _shown
          ? CountdownChip(
              setup: const TimerSetup(Duration(minutes: 5)),
              onFinished: () {},
              onClose: () => setState(() => _shown = false),
            )
          : const Text('timer closed'),
    ),
  );
}

void widgetTests() {
  testWidgets('stopping the timer closes only its card, not the note', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const _TimerPage()),
              ),
              child: const Text('open note'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open note'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CountdownChip));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Stop'));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('timer closed'), findsOneWidget);
    expect(find.text('Stop'), findsNothing);
  });
}
