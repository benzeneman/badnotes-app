import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:meta/meta.dart';
import 'package:logging/logging.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/data/nextcloud/badnotes_syncer.dart';
import 'package:badnotes/data/nextcloud/remote_store.dart';
import 'package:badnotes/data/prefs.dart';

/// A whole library in one zip file: every note with its pictures, recordings,
/// covers and folders. Made and unpacked on another isolate, so a big library
/// doesn't freeze the app.
abstract final class Backup {
  static final log = Logger('Backup');

  /// The name of the backup kept in Google Drive. Drive keeps older versions
  /// of a file it's replaced, so this one name is enough.
  static const driveName = 'BadNotes backup.zip';

  /// How often the automatic backup to Google Drive runs.
  static const autoInterval = Duration(days: 7);

  /// A file name for a backup made now, like "BadNotes backup 2026-11-16.zip".
  static String fileName([DateTime? now]) {
    final date = (now ?? DateTime.now()).toIso8601String().substring(0, 10);
    return 'BadNotes backup $date.zip';
  }

  /// Zips everything in the notes folder.
  ///
  /// The zip is put together in a file, one note at a time: made in memory,
  /// a big library took two or three times its size there, and the app
  /// could run out of memory (on every launch, as the backup was still due).
  static Future<Uint8List> create() async {
    final root = FileManager.documentsDirectory;
    final temp = Directory.systemTemp.createTempSync('backup');
    try {
      final zipPath = '${temp.path}/backup.zip';
      await Isolate.run(() => zipFolder(root, zipPath));
      return await File(zipPath).readAsBytes();
    } finally {
      temp.deleteSync(recursive: true);
    }
  }

  /// Zips everything in [root] into a new file at [zipPath].
  @visibleForTesting
  static void zipFolder(String root, String zipPath) {
    final zip = ZipFileEncoder()..create(zipPath);
    try {
      final dir = Directory(root);
      if (!dir.existsSync()) return;
      for (final entity in dir.listSync(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        final relative = entity.path.substring(root.length + 1);
        // other apps' and the system's hidden files
        if (relative.split(Platform.pathSeparator).any((p) => p.startsWith('.'))) {
          continue;
        }
        // half a save, left by a kill mid-write
        if (relative.endsWith('.part')) continue;
        zip.addFileSync(entity, relative.replaceAll(r'\', '/'));
      }
    } finally {
      zip.closeSync();
    }
  }

  /// Puts back the files in the backup [zip] that are missing. Files already
  /// there are left as they are, so a restore never loses newer work.
  /// Returns how many files were restored.
  static Future<int> restore(Uint8List zip) async {
    final root = FileManager.documentsDirectory;
    final restored = await Isolate.run(() => unzipInto(zip, root));
    if (restored > 0) {
      // the home screen lists the notes again
      FileManager.fileWriteStream.add(const FileOperation(.write, '/'));
    }
    return restored;
  }

  @visibleForTesting
  static int unzipInto(Uint8List zip, String root) {
    final archive = ZipDecoder().decodeBytes(zip);
    final rootDir = Directory(root).absolute.path;
    var restored = 0;
    for (final entry in archive) {
      if (!entry.isFile) continue;
      final file = File('$rootDir/${entry.name}').absolute;
      // nothing may be written outside the notes folder
      if (!file.path.startsWith('$rootDir/') || entry.name.contains('..')) {
        continue;
      }
      if (file.existsSync()) continue;
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(entry.readBytes() ?? const []);
      restored++;
    }
    return restored;
  }

  /// Backs up to Google Drive if it's on, logged in and a week has passed.
  static Future<void> autoBackupIfDue() async {
    if (!stows.autoDriveBackup.value) return;
    final store = BadNotesSyncInterface.store;
    if (store is! GoogleDriveStore) return;
    final last = DateTime.fromMillisecondsSinceEpoch(
      stows.lastDriveBackup.value,
    );
    if (DateTime.now().difference(last) < autoInterval) return;
    // a backup that never finished (the app closed or ran out of memory
    // under it) is tried again the next day, not on every launch
    final tried = DateTime.fromMillisecondsSinceEpoch(
      stows.lastDriveBackupTry.value,
    );
    if (DateTime.now().difference(tried) < const Duration(days: 1)) return;
    stows.lastDriveBackupTry.value = DateTime.now().millisecondsSinceEpoch;
    await backUpToDrive();
  }

  /// Uploads a backup to Google Drive now. Returns whether it did.
  static Future<bool> backUpToDrive() async {
    final store = BadNotesSyncInterface.store;
    if (store == null) return false;
    if (!await BadNotesSyncInterface.canSyncNow()) return false;
    try {
      final zip = await create();
      final ok = await store.putReadable(
        zip,
        driveName,
        mimeType: 'application/zip',
        folder: GoogleDriveStore.backupFolderName,
      );
      if (ok) stows.lastDriveBackup.value = DateTime.now().millisecondsSinceEpoch;
      return ok;
    } catch (e, st) {
      log.warning('Backing up to Google Drive failed', e, st);
      return false;
    }
  }
}
