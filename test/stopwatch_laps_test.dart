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
}
