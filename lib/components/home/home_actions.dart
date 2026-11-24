import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:archive/archive_io.dart';
import 'package:badnotes/components/canvas/inner_canvas.dart';
import 'package:badnotes/components/editor/export_progress.dart';
import 'package:badnotes/components/editor/share_export_card.dart';
import 'package:badnotes/components/editor/note_tabs.dart';
import 'package:badnotes/components/home/notebook_cover.dart';
import 'package:badnotes/data/routes.dart';
import 'package:badnotes/data/editor/editor_core_info.dart';
import 'package:badnotes/data/editor/editor_exporter.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:printing/printing.dart';
import 'package:path/path.dart' as p;

/// The name of the note at [path], e.g. `Physics` for `/College/Physics`.
String noteName(String path) => path.substring(path.lastIndexOf('/') + 1);

/// The folder the note at [path] is in, e.g. `/College/` (with slashes).
String noteFolder(String path) => path.substring(0, path.lastIndexOf('/') + 1);

/// Makes a copy of each note in [paths] next to it ("Physics copy"), with its
/// pictures and cover. Returns the copies' paths.
Future<List<String>> duplicateNotes(List<String> paths) async {
  final copies = <String>[];
  final temp = await Directory.systemTemp.createTemp('badnotes-copy');
  try {
    for (final path in paths) {
      final note = await EditorCoreInfo.loadFromFilePath(path);
      final sba = await note.saveToSba(currentPageIndex: null);
      final file = File(p.join(temp.path, '${noteName(path)} copy.sba'));
      await file.writeAsBytes(sba);
      final copy = await FileManager.importFile(file.path, noteFolder(path));
      if (copy == null) continue;
      final cover = NotebookCovers.read(path);
      if (cover != null) {
        await NotebookCovers.write(
          copy,
          cover,
          showName: NotebookCovers.showsName(path),
        );
      }
      copies.add(copy);
    }
  } finally {
    await temp.delete(recursive: true);
  }
  return copies;
}

/// Share & Export, as inside a note, for notes on the desk: PDF, PNG or a
/// BadNotes file, with or without the paper; print, save or share.
Future<void> showNotesShareCard(
  BuildContext context,
  List<String> paths, {
  Rect? anchor,
}) async {
  if (paths.isEmpty) return;
  int? pageCount;
  if (paths.length == 1) {
    pageCount = (await EditorCoreInfo.loadFromFilePath(paths.single))
        .pages
        .length;
  }
  if (!context.mounted) return;
  final size = MediaQuery.sizeOf(context);
  await showShareExportCard(
    context,
    anchor:
        anchor ?? Rect.fromCenter(center: size.center(Offset.zero), width: 0, height: 0),
    pageCount: pageCount,
    allowThisPage: false,
    canPrint: paths.length == 1,
    presentModes: const {},
    onPresent: (_) {},
    onExport: (format, _, withPaper, action) => exportNotes(
      context,
      paths,
      format: format,
      withPaper: withPaper,
      action: action,
    ),
  );
}

/// Exports the notes in [paths] as [format]: one file for one note (a PNG
/// for a one-page note) and a zip for more, then prints, saves or shares it.
Future<void> exportNotes(
  BuildContext context,
  List<String> paths, {
  ExportFormat format = ExportFormat.pdf,
  bool withPaper = true,
  ExportAction action = ExportAction.share,
}) => ExportProgress.run(context, 'Exporting…', () async {
  InnerCanvas.exportWithoutPaper = !withPaper;
  try {
    // printing is always a PDF
    final asPdf = format == ExportFormat.pdf || action == ExportAction.print;
    final files = <ArchiveFile>[];
    for (final (n, path) in paths.indexed) {
      final note = await EditorCoreInfo.loadFromFilePath(path);
      if (!context.mounted) return;
      final name = noteName(note.filePath);
      final of = paths.length > 1 ? ' (${n + 1} of ${paths.length})' : '';
      if (asPdf) {
        final document = await EditorExporter.generatePdf(
          note,
          context,
          (done, total) => ExportProgress.pages('Making PDF$of…', done, total),
        );
        ExportProgress.step('Finishing the PDF$of…');
        final bytes = await document.save();
        files.add(ArchiveFile('$name.pdf', bytes.length, bytes));
      } else if (format == ExportFormat.png) {
        final total = note.pages.length;
        for (var i = 0; i < total; i++) {
          ExportProgress.pages('Making PNGs$of…', i, total);
          final longest = note.pages[i].size.longestSide;
          final shot = await EditorExporter.screenshotPage(
            coreInfo: note,
            pageIndex: i,
            rasterizeAllStrokes: true,
            pixelRatio: math.min(1.0, 3000.0 / longest),
          );
          final png = await shot.toByteData(format: ui.ImageByteFormat.png);
          shot.dispose();
          final bytes = png!.buffer.asUint8List();
          files.add(ArchiveFile('${name}_page_${i + 1}.png', bytes.length, bytes));
        }
      } else {
        ExportProgress.step('Packing $name$of…');
        final bytes = Uint8List.fromList(
          await note.saveToSba(currentPageIndex: null),
        );
        files.add(ArchiveFile('$name.sba', bytes.length, bytes));
      }
    }
    if (!context.mounted || files.isEmpty) return;
    if (action == ExportAction.print) {
      final only = files.first;
      await Printing.layoutPdf(
        name: only.name,
        onLayout: (_) async => only.content,
      );
      return;
    }
    final share = action == ExportAction.share;
    if (files.length == 1) {
      final only = files.single;
      final ok = await FileManager.exportFile(
        only.name,
        only.content,
        isImage: only.name.endsWith('.png'),
        share: share,
        context: context,
      );
      if (only.name.endsWith('.png') && !share && context.mounted) {
        if (Platform.isAndroid || Platform.isIOS) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(
              content: Text(
                ok ? 'Saved to Photos' : 'Allow photos access to save the PNG',
              ),
            ),
          );
        }
      }
      return;
    }
    ExportProgress.step('Zipping…');
    final archive = Archive();
    files.forEach(archive.addFile);
    final zipName = paths.length == 1
        ? '${noteName(paths.single)} (PNG).zip'
        : '${files.first.name}.zip';
    await FileManager.exportFile(
      zipName,
      Uint8List.fromList(ZipEncoder().encode(archive)),
      share: share,
      context: context,
    );
  } catch (e, st) {
    Logger('exportNotes').severe('Export failed', e, st);
    if (context.mounted) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Could not export')),
      );
    }
  } finally {
    InnerCanvas.exportWithoutPaper = false;
  }
});

/// A note's size on disk with its pictures, e.g. "3.2 MB".
String noteSizeLabel(String path) {
  var bytes = 0;
  try {
    final main = FileManager.getFile('$path.sbn2');
    final dir = main.parent;
    final base = p.basename(main.path);
    for (final entity in dir.listSync()) {
      if (entity is File && p.basename(entity.path).startsWith(base)) {
        bytes += entity.lengthSync();
      }
    }
  } on FileSystemException {
    return '';
  }
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
  return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
}

/// Opens the note at [path] in the editor.
Future<void> openNote(BuildContext context, String path) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: RoutePaths.editFilePath(path)),
        builder: (context) => TabbedEditor(path: path),
      ),
    );
