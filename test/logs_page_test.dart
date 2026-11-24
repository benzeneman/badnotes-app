import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:badnotes/i18n/strings.g.dart';
import 'package:badnotes/pages/logs.dart';

Widget _page() => const MaterialApp(home: LogsPage());

void main() {
  setUp(logsHistory.clear);

  testWidgets('says so when there is nothing logged', (tester) async {
    await tester.pumpWidget(_page());
    expect(find.text(t.logs.noLogs), findsOneWidget);
  });

  testWidgets('shows the newest record first', (tester) async {
    logsHistory
      ..add(LogRecord(Level.INFO, 'first thing', 'Test'))
      ..add(LogRecord(Level.SEVERE, 'second thing', 'Test'));
    await tester.pumpWidget(_page());
    expect(find.text(t.logs.noLogs), findsNothing);
    final first = tester.getTopLeft(find.text('first thing')).dy;
    final second = tester.getTopLeft(find.text('second thing')).dy;
    expect(second, lessThan(first));
  });

  testWidgets('paused, new records wait; resumed, they show', (tester) async {
    logsHistory.add(LogRecord(Level.INFO, 'before', 'Test'));
    await tester.pumpWidget(_page());
    await tester.tap(find.byIcon(Icons.pause));
    await tester.pump();
    logsHistory.add(LogRecord(Level.INFO, 'while paused', 'Test'));
    await tester.pump();
    expect(find.text('while paused'), findsNothing);
    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    expect(find.text('while paused'), findsOneWidget);
  });

  test('copies as text with level, time, message and error', () {
    logsHistory.add(
      LogRecord(Level.WARNING, 'careful', 'Test', StateError('boom')),
    );
    final text = logsHistory.asText();
    expect(text, contains('WARNING at'));
    expect(text, contains('careful'));
    expect(text, contains('boom'));
  });
}
