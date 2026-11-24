import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/components/home/note_facts.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/pages/editor/editor.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

/// An earlier state of a note, kept by [NoteVersions].
@immutable
class NoteVersion {
  const new({
    required this.notePath,
    required this.file,
    required this.time,
    required this.pages,
    required this.thumbnail,
  });

  /// The note's path, without extension, e.g. `/College/Physics`.
  final String notePath;

  /// The version as a BadNotes archive (.sba).
  final File file;
  final DateTime time;
  final int pages;

  /// A picture of the first page, if the note had one.
  final File? thumbnail;
}

/// Earlier states of notes, kept on this device only.
///
/// They live in the app's support folder (`<support>/note_versions/`), not
/// under [FileManager.documentsDirectory]: home lists notes and the syncer
/// uploads files only from that tree, so neither sees versions.
/// Each note has a folder named after its encoded path holding
/// `<ms since epoch>_<pages>.sba` and `<ms since epoch>.png`.
abstract final class NoteVersions {
  static final log = Logger('NoteVersions');

  @visibleForTesting
  static String? rootOverride;

  static String? _root;

  static Future<String> _rootPath() async {
    if (_root case final root?) return root;
    final root =
        rootOverride ??
        '${(await getApplicationSupportDirectory()).path}/note_versions';
    return _root = root;
  }

  /// Whether versions are kept (Settings › Version history).
  static bool get enabled => stows.keepVersions.value;
  static set enabled(bool value) => stows.keepVersions.value = value;

  static Future<Directory> _dirOf(String notePath) async =>
      Directory('${await _rootPath()}/${Uri.encodeComponent(notePath)}');

  static final _versionName = RegExp(r'^(\d+)_(\d+)\.sba$');

  /// The versions of the note at [notePath], newest first.
  static Future<List<NoteVersion>> list(String notePath) async {
    final dir = await _dirOf(notePath);
    if (!dir.existsSync()) return const [];
    final versions = <NoteVersion>[];
    for (final entity in dir.listSync()) {
      if (entity is! File) continue;
      final match = _versionName.firstMatch(entity.uri.pathSegments.last);
      if (match == null) continue;
      final ms = match.group(1)!;
      final thumbnail = File('${dir.path}/$ms.png');
      versions.add(
        NoteVersion(
          notePath: notePath,
          file: entity,
          time: DateTime.fromMillisecondsSinceEpoch(int.parse(ms)),
          pages: int.parse(match.group(2)!),
          thumbnail: thumbnail.existsSync() ? thumbnail : null,
        ),
      );
    }
    versions.sort((a, b) => b.time.compareTo(a.time));
    return versions;
  }

  /// Keeps the note at [notePath] (without extension) as it is saved now.
  /// Call after the note is written. [force] keeps one even when [enabled]
  /// is off.
  static Future<void> keep(String notePath, {bool force = false}) async {
    try {
      await _rootPath();
      if (!enabled && !force) return;
      final base = '$notePath${Editor.extension}';
      final main = FileManager.getFile(base);
      if (!main.existsSync()) return;

      final versions = await list(notePath);
      final now = DateTime.now();
      if (shouldSkip(
        newest: versions.firstOrNull?.time,
        noteModified: main.lastModifiedSync(),
        now: now,
      )) {
        return;
      }

      final bytes = await main.readAsBytes();
      final assets = <Uint8List>[];
      for (var i = 0; ; i++) {
        final asset = FileManager.getFile('$base.$i');
        if (!asset.existsSync()) break;
        assets.add(await asset.readAsBytes());
      }
      final (sba, pages) = await Isolate.run(() => _pack(bytes, assets));

      final dir = await (await _dirOf(notePath)).create(recursive: true);
      final ms = now.millisecondsSinceEpoch;
      await File('${dir.path}/${ms}_$pages.sba').writeAsBytes(sba);
      final preview = FileManager.getFile('$base.p');
      if (preview.existsSync()) await preview.copy('${dir.path}/$ms.png');

      final drop = toDrop([for (final v in versions) v.time], now).toSet();
      for (final v in versions) {
        if (!drop.contains(v.time)) continue;
        await v.file.delete();
        await v.thumbnail?.delete();
      }
    } catch (e, st) {
      log.warning('Could not keep a version of $notePath', e, st);
    }
  }

  /// Puts [version] back as its note, after keeping the note's current
  /// state as a version. The note must not be open for editing meanwhile.
  static Future<void> restore(NoteVersion version) async {
    // read first: keeping the current state prunes older versions
    final archive = ZipDecoder().decodeBytes(await version.file.readAsBytes());
    final thumbnail = await version.thumbnail?.readAsBytes();
    await keep(version.notePath, force: true);

    final base = '${version.notePath}${Editor.extension}';
    var assets = 0;
    for (final file in archive.files) {
      if (!file.isFile) continue;
      if (file.name == 'main${Editor.extension}') {
        await FileManager.writeFile(base, file.content, awaitWrite: true);
      } else if (int.tryParse(file.name.split('.').last) case final i?) {
        await FileManager.writeFile('$base.$i', file.content, awaitWrite: true);
        if (i >= assets) assets = i + 1;
      }
    }
    await FileManager.removeUnusedAssets(base, numAssets: assets);
    if (thumbnail != null) {
      await FileManager.writeFile('$base.p', thumbnail, awaitWrite: true);
    }
  }

  /// Makes a new note from [version] next to its note, named e.g.
  /// "Physics (version 2.10 pm)", and returns its path (without extension).
  static Future<String?> openAsCopy(NoteVersion version) async {
    final notePath = version.notePath;
    final slash = notePath.lastIndexOf('/');
    // '.' not ':': [FileManager.validateFilename] forbids ':'
    final clock = versionClock(version.time).replaceAll(':', '.');
    final name = '${notePath.substring(slash + 1)} (version $clock)';
    final temp = await Directory.systemTemp.createTemp('badnotes-version');
    try {
      final sba = await version.file.copy('${temp.path}/$name.sba');
      final copy = await FileManager.importFile(
        sba.path,
        notePath.substring(0, slash + 1),
      );
      if (copy != null && version.thumbnail != null) {
        await FileManager.writeFile(
          '$copy${Editor.extension}.p',
          await version.thumbnail!.readAsBytes(),
        );
      }
      return copy;
    } finally {
      await temp.delete(recursive: true);
    }
  }

  /// Moves a note's versions with it; call when a note is renamed or moved.
  static Future<void> move(String fromNotePath, String toNotePath) async {
    // never stops a rename: at worst the history stays under the old name
    try {
      final from = await _dirOf(fromNotePath);
      if (!from.existsSync()) return;
      final to = await _dirOf(toNotePath);
      if (to.existsSync()) await to.delete(recursive: true);
      await from.rename(to.path);
    } catch (e) {
      log.fine('Versions not moved: $e');
    }
  }

  /// Deletes a note's versions; call when the note is deleted.
  static Future<void> forget(String notePath) async {
    try {
      final dir = await _dirOf(notePath);
      if (dir.existsSync()) await dir.delete(recursive: true);
    } catch (e) {
      log.fine('Versions not deleted: $e');
    }
  }

  /// The space all versions take, in bytes.
  static Future<int> totalBytes() async {
    final root = Directory(await _rootPath());
    if (!root.existsSync()) return 0;
    var bytes = 0;
    await for (final entity in root.list(recursive: true)) {
      if (entity is File) bytes += await entity.length();
    }
    return bytes;
  }

  /// Whether to skip keeping a version: the newest is under 2 minutes old
  /// and the note hasn't changed since.
  @visibleForTesting
  static bool shouldSkip({
    required DateTime? newest,
    required DateTime noteModified,
    required DateTime now,
  }) =>
      newest != null &&
      now.difference(newest) < const Duration(minutes: 2) &&
      !noteModified.isAfter(newest);

  /// Of the versions kept at [times], those to delete: all from the last
  /// 24 h stay, then the newest of each day for 7 days, the newest of each
  /// week for 30 days; older ones go.
  @visibleForTesting
  static List<DateTime> toDrop(List<DateTime> times, DateTime now) {
    final newestFirst = [...times]..sort((a, b) => b.compareTo(a));
    final buckets = <String>{};
    final drop = <DateTime>[];
    for (final time in newestFirst) {
      final age = now.difference(time);
      if (age < const Duration(days: 1)) continue;
      final String bucket;
      if (age < const Duration(days: 7)) {
        bucket = 'day ${time.year}-${time.month}-${time.day}';
      } else if (age < const Duration(days: 30)) {
        bucket = 'week ${age.inDays ~/ 7}';
      } else {
        drop.add(time);
        continue;
      }
      if (!buckets.add(bucket)) drop.add(time);
    }
    return drop;
  }
}

/// Zips a note's file and assets the way [EditorCoreInfo.saveToSba] does,
/// and counts its pages. Run on another isolate.
(List<int>, int) _pack(Uint8List main, List<Uint8List> assets) {
  const name = 'main${Editor.extension}';
  final archive = Archive()..addFile(ArchiveFile(name, main.length, main));
  for (final (i, asset) in assets.indexed) {
    archive.addFile(ArchiveFile('$name.$i', asset.length, asset));
  }
  return (ZipEncoder().encode(archive), NoteFacts.read(main)?.pages ?? 0);
}

/// e.g. "2:10 pm".
String versionClock(DateTime time) =>
    DateFormat('h:mm a').format(time).toLowerCase();

/// "Today 2:10 pm", "Yesterday 9:05 pm" or "Mon 18 Nov".
String versionLabel(DateTime time, DateTime now) {
  final days =
      (DateTime(now.year, now.month, now.day)
                  .difference(DateTime(time.year, time.month, time.day))
                  .inHours /
              24)
          .round();
  return switch (days) {
    0 => 'Today ${versionClock(time)}',
    1 => 'Yesterday ${versionClock(time)}',
    _ => DateFormat('EEE d MMM').format(time),
  };
}
