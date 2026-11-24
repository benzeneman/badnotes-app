import 'dart:math';

import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:badnotes/components/editor/note_tabs.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/pages/editor/editor.dart';

/// When a note's tape quiz is next due, going further apart the better it goes,
/// so what's been learned gets revised just before it would be forgotten.
class RevisionEntry {
  const RevisionEntry(this.path, this.due, this.days);

  /// The next wait after a quiz with [firstTry] of [total] known at once.
  @visibleForTesting
  static int nextDays(int previousDays, int firstTry, int total) {
    final share = total == 0 ? 0.0 : firstTry / total;
    final days = share >= 0.9
        ? max(previousDays * 2.5, 3.0)
        : share >= 0.6
        ? max(previousDays * 1.5, 2.0)
        : 1.0;
    return days.round().clamp(1, 60);
  }

  /// A saved [entry], or null if it can't be read.
  @visibleForTesting
  static RevisionEntry? parse(String entry) {
    final parts = entry.split('|');
    if (parts.length < 3) return null;
    final due = int.tryParse(parts[0]);
    final days = int.tryParse(parts[1]);
    if (due == null || days == null) return null;
    return RevisionEntry(
      parts.sublist(2).join('|'),
      DateTime.fromMillisecondsSinceEpoch(due),
      days,
    );
  }

  final String path;
  final DateTime due;
  final int days;

  @override
  String toString() => '${due.millisecondsSinceEpoch}|$days|$path';
}

abstract class RevisionPlan {
  static List<RevisionEntry> get _all => [
    for (final entry in stows.revisionPlan.value)
      ?RevisionEntry.parse(entry),
  ];

  /// Plans the next revision of the note at [path] after a quiz, and returns
  /// how many days away it is.
  static int quizDone(String path, int firstTry, int total) {
    final all = _all;
    final previous = all.where((entry) => entry.path == path).firstOrNull;
    final days = RevisionEntry.nextDays(previous?.days ?? 0, firstTry, total);
    stows.revisionPlan.value = [
      for (final entry in all)
        if (entry.path != path) entry.toString(),
      RevisionEntry(
        path,
        DateTime.now().add(Duration(days: days)),
        days,
      ).toString(),
    ];
    return days;
  }

  /// Notes due by now that still exist.
  // ponytail: goes by path, so renaming a note loses its plan. Keep the plan in
  // the note itself if that happens a lot.
  static List<RevisionEntry> get due {
    final now = DateTime.now();
    return [
      for (final entry in _all)
        if (!entry.due.isAfter(now) &&
            FileManager.doesFileExist(entry.path + Editor.extension))
          entry,
    ];
  }
}

/// A reminder above the recent notes of what's due for revision. Takes no room
/// when nothing is.
class RevisionDueCard extends StatelessWidget {
  const RevisionDueCard({super.key});

  void _open(BuildContext context, String path) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => TabbedEditor(path: path)),
    );
  }

  void _showNotes(BuildContext context, List<RevisionEntry> due) {
    showBnSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(8),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: Text(
                'Due for revision',
                style: BnType.section.copyWith(
                  color: BadNotesColors.of(context).text,
                ),
              ),
            ),
            for (final entry in due)
              BnMenuRow(
                icon: BnIcons.notebook,
                label: p.basename(entry.path),
                trailingText: 'Open it, then ⋯, Tape quiz',
                onTap: () {
                  Navigator.pop(context);
                  _open(context, entry.path);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: stows.revisionPlan,
      builder: (context, _) {
        final due = RevisionPlan.due;
        if (due.isEmpty) return const SizedBox.shrink();
        final colors = BadNotesColors.of(context);
        final count = due.length;
        final names = due.map((e) => p.basename(e.path)).join(' · ');
        void start() => count == 1
            ? _open(context, due.first.path)
            : _showNotes(context, due);
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Material(
            color: colors.accentTint,
            shape: RoundedRectangleBorder(
              borderRadius: const BorderRadius.all(
                Radius.circular(BnRadius.card),
              ),
              side: BorderSide(color: colors.accentTintBorder),
            ),
            child: InkWell(
              onTap: start,
              borderRadius: const BorderRadius.all(
                Radius.circular(BnRadius.card),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(BnRadius.control),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: BnPathIcon(
                        BnToolIcons.tape,
                        size: 18,
                        color: colors.accent,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            count == 1
                                ? 'A note is due for revision'
                                : '$count notes are due for revision',
                            style: BnType.bodyLarge.copyWith(
                              color: colors.text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$names — tape quiz',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: BnType.caption.copyWith(
                              color: colors.accentStrong,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    BnButton.primary(label: 'Start quiz', onPressed: start),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
