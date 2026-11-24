#!/usr/bin/env dart
// Sets the app's version everywhere it is written down.
//
//   dart scripts/bump_version.dart --patch          1.37.1 -> 1.37.2
//   dart scripts/bump_version.dart --minor          1.37.1 -> 1.38.0
//   dart scripts/bump_version.dart --major          1.37.1 -> 2.0.0
//   dart scripts/bump_version.dart --custom 1.40.0  (or a build number)
//
// --fail-on-changes only checks: it exits with 10 if a file would change.
// --quiet prints only problems.

import 'dart:io';

import 'package:args/args.dart';
import 'package:badnotes/data/badnotes_version.dart';
import 'package:badnotes/data/version.dart' as current;

/// Put in a new changelog until real notes are written.
const placeholderNotes = 'Release_notes_will_be_added_here';

/// The exit codes, as the version test expects them.
abstract final class Exit {
  static const ok = 0;
  static const noVersion = 1;
  static const wouldChange = 10;
}

late final bool checkOnly;
late final bool quiet;

void say(String message) {
  if (!quiet) print(message);
}

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addFlag('major', negatable: false)
    ..addFlag('minor', negatable: false)
    ..addFlag('patch', negatable: false)
    ..addOption('custom', help: 'a version like 1.40.0, or a build number')
    ..addFlag('fail-on-changes', negatable: false)
    ..addFlag('quiet', negatable: false)
    ..addFlag('help', abbr: 'h', negatable: false);
  final options = parser.parse(args);
  if (options.flag('help')) {
    print(parser.usage);
    exit(Exit.ok);
  }
  checkOnly = options.flag('fail-on-changes');
  quiet = options.flag('quiet');

  final now = BadNotesVersion.fromName(current.buildName);
  final custom = options.option('custom');
  final BadNotesVersion next;
  if (custom != null) {
    final number = int.tryParse(custom);
    next = number != null
        ? BadNotesVersion.fromNumber(number)
        : BadNotesVersion.fromName(custom);
  } else if (options.flag('major')) {
    next = now.bumpMajor();
  } else if (options.flag('minor')) {
    next = now.bumpMinor();
  } else if (options.flag('patch')) {
    next = now.bumpPatch();
  } else {
    print('Say which version: --major, --minor, --patch or --custom.');
    exit(Exit.noVersion);
  }
  say('Version $now -> ${next.buildName} (${next.buildNumber})');

  await rewrite('lib/data/version.dart', {
    RegExp(r'buildNumber = .+;'): 'buildNumber = ${next.buildNumber};',
    RegExp(r'buildName = .+;'): "buildName = '${next.buildName}';",
    RegExp(r'buildYear = .+;'): 'buildYear = ${DateTime.now().year};',
  });
  await rewrite('pubspec.yaml', {
    RegExp(r'^version: .+', multiLine: true):
        'version: ${next.buildName}+${next.buildNumber}',
  });
  await rewrite('windows/runner/Runner.rc', {
    RegExp(r'#define VERSION_AS_NUMBER .+'):
        '#define VERSION_AS_NUMBER ${next.buildNameWithCommas},0',
    RegExp(r'#define VERSION_AS_STRING .+'):
        '#define VERSION_AS_STRING "${next.buildName}.0"',
  });

  // what's new in this version, shown in the update dialog
  final notes = File('metadata/en-US/changelogs/${next.buildNumber}.txt');
  if (!notes.existsSync()) {
    if (checkOnly) {
      print('Missing: ${notes.path}');
      exit(Exit.wouldChange);
    }
    await notes.create(recursive: true);
    await notes.writeAsString('• $placeholderNotes\n');
    say('Wrote ${notes.path}: replace the placeholder with the real notes');
  }
}

/// Applies [changes] to the file at [path], if it exists. With
/// --fail-on-changes, exits instead of writing when something would change.
Future<void> rewrite(String path, Map<RegExp, String> changes) async {
  final file = File(path);
  if (!file.existsSync()) return;
  final before = await file.readAsString();
  var after = before;
  changes.forEach((pattern, replacement) {
    after = after.replaceAll(pattern, replacement);
  });
  if (after == before) return;
  if (checkOnly) {
    print('Would change: $path');
    exit(Exit.wouldChange);
  }
  await file.writeAsString(after);
  say('Updated $path');
}
