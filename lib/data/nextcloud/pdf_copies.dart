import 'dart:async';
import 'dart:collection';

import 'package:logging/logging.dart';
import 'package:badnotes/data/editor/editor_core_info.dart';
import 'package:badnotes/data/editor/editor_exporter.dart';
import 'package:badnotes/data/nextcloud/badnotes_syncer.dart';
import 'package:badnotes/data/nextcloud/remote_store.dart';
import 'package:badnotes/data/prefs.dart';

/// Keeps a PDF of each changed note in Google Drive, like other notes apps
/// do, so it can be opened and shared from Drive. The notes themselves stay
/// synced as encrypted .sbn2 files, which only BadNotes can open.
///
/// Notes are done one at a time, a few seconds after their editor closes, so
/// drawing the pages doesn't hold up whatever comes next.
abstract final class PdfCopies {
  static final log = Logger('PdfCopies');
  static final _queue = LinkedHashSet<String>();
  static var _running = false;

  /// Queues [notePath] (without its extension) for a fresh PDF copy.
  static void noteChanged(String notePath) {
    if (!stows.drivePdfCopies.value) return;
    if (BadNotesSyncInterface.store is! GoogleDriveStore) return;
    _queue
      ..remove(notePath)
      ..add(notePath);
    if (!_running) unawaited(_run());
  }

  static Future<void> _run() async {
    _running = true;
    try {
      while (_queue.isNotEmpty) {
        await Future<void>.delayed(const Duration(seconds: 4));
        final path = _queue.first;
        _queue.remove(path);
        try {
          await _upload(path);
        } catch (e, st) {
          log.warning('Could not save a PDF copy of $path', e, st);
        }
      }
    } finally {
      _running = false;
    }
  }

  static Future<void> _upload(String notePath) async {
    if (!await BadNotesSyncInterface.canSyncNow()) return;
    final store = BadNotesSyncInterface.store;
    if (store == null) return;
    final coreInfo = await EditorCoreInfo.loadFromFilePath(notePath);
    try {
      if (coreInfo.readOnlyReason == .corrupted || coreInfo.isEmpty) return;
      final pdf = await EditorExporter.generatePdf(coreInfo);
      await store.putReadable(await pdf.save(), pdfName(notePath));
    } finally {
      coreInfo.dispose();
    }
  }

  /// The PDF's name in Drive: its folders, then its name, as "Uni - Maths.pdf".
  static String pdfName(String notePath) {
    final parts = notePath.split('/').where((part) => part.isNotEmpty);
    return '${parts.join(' - ')}.pdf';
  }
}
