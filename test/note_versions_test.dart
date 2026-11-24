import 'package:badnotes/data/file_manager/note_versions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 24, 15);

  group('toDrop', () {
    test('keeps everything from the last 24 h', () {
      final times = [
        for (var h = 0; h < 24; h++) now.subtract(Duration(hours: h)),
      ];
      expect(NoteVersions.toDrop(times, now), isEmpty);
    });

    test('keeps the newest of each day for a week', () {
      final morning = DateTime(2026, 11, 21, 9);
      final evening = DateTime(2026, 11, 21, 21);
      final otherDay = DateTime(2026, 11, 20, 12);
      expect(
        NoteVersions.toDrop([morning, evening, otherDay], now),
        [morning],
      );
    });

    test('keeps one a week up to 30 days, none older', () {
      final a = now.subtract(const Duration(days: 8));
      final b = now.subtract(const Duration(days: 9));
      final c = now.subtract(const Duration(days: 15));
      final old = now.subtract(const Duration(days: 31));
      expect(NoteVersions.toDrop([old, c, b, a], now), unorderedEquals([b, old]));
    });
  });

  group('shouldSkip', () {
    final newest = now.subtract(const Duration(minutes: 1));
    test('skips a recent version of an unchanged note', () {
      expect(
        NoteVersions.shouldSkip(
          newest: newest,
          noteModified: newest.subtract(const Duration(seconds: 5)),
          now: now,
        ),
        isTrue,
      );
    });
    test('keeps when the note changed', () {
      expect(
        NoteVersions.shouldSkip(newest: newest, noteModified: now, now: now),
        isFalse,
      );
    });
    test('keeps when the newest is old or missing', () {
      final old = now.subtract(const Duration(minutes: 3));
      expect(
        NoteVersions.shouldSkip(newest: old, noteModified: old, now: now),
        isFalse,
      );
      expect(
        NoteVersions.shouldSkip(newest: null, noteModified: now, now: now),
        isFalse,
      );
    });
  });

  test('versionLabel', () {
    expect(versionLabel(DateTime(2026, 11, 24, 14, 10), now), 'Today 2:10 pm');
    expect(
      versionLabel(DateTime(2026, 11, 23, 21, 5), now),
      'Yesterday 9:05 pm',
    );
    expect(versionLabel(DateTime(2026, 11, 16, 10), now), 'Mon 16 Nov');
  });
}
