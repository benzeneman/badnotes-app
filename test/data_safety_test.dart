import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:badnotes/components/canvas/_asset_cache.dart';
import 'package:badnotes/components/canvas/image/editor_image.dart';
import 'package:badnotes/data/backup.dart';
import 'package:badnotes/data/editor/editor_core_info.dart';
import 'package:badnotes/data/editor/page.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/data/flavor_config.dart';

/// Ways a note's files could be lost or left behind.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlavorConfig.setup();

  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('data_safety'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('a save cut short leaves no .part behind', () async {
    final old = File('${dir.path}/note.sbn2.123.part')..writeAsStringSync('x');
    old.setLastModifiedSync(DateTime.now().subtract(const Duration(hours: 1)));
    // a save may be writing this one right now
    final fresh = File('${dir.path}/note.sbn2.456.part')
      ..writeAsStringSync('x');
    final note = File('${dir.path}/note.sbn2')..writeAsStringSync('x');

    FileManager.documentsDirectory = dir.path;
    await FileManager.removeLeftoverParts();

    expect(old.existsSync(), isFalse);
    expect(fresh.existsSync(), isTrue);
    expect(note.existsSync(), isTrue);
  });

  test('a name too long to save is refused', () {
    expect(FileManager.validateFilename('a' * 200), isNull);
    expect(FileManager.validateFilename('a' * 201), isNotNull);
    // bytes, not letters: each of these is three
    expect(FileManager.validateFilename('नोट' * 30), isNotNull);
  });

  test('a backup has the notes, not half saves or hidden files', () {
    File('${dir.path}/notes/a.sbn2')
      ..createSync(recursive: true)
      ..writeAsStringSync('note');
    File('${dir.path}/notes/a.sbn2.1.part').writeAsStringSync('half');
    File('${dir.path}/.hidden').writeAsStringSync('no');

    final zipPath =
        '${Directory.systemTemp.path}/'
        'backup_${DateTime.now().microsecondsSinceEpoch}.zip';
    addTearDown(() => File(zipPath).deleteSync());
    Backup.zipFolder(dir.path, zipPath);

    final zip = ZipDecoder().decodeBytes(File(zipPath).readAsBytesSync());
    expect(
      [
        for (final f in zip)
          if (f.isFile) f.name,
      ],
      ['notes/a.sbn2'],
    );
  });

  test('a renamed note\'s pictures are read from their new place', () {
    final assets = EditorCoreInfo(filePath: '').assetCache;
    final png = PngEditorImage(
      id: 0,
      extension: '.png',
      imageProvider: FileImage(File('/docs/old.sbn2.0')),
      pageIndex: 0,
      pageSize: EditorPage.defaultSize,
      onMoveImage: null,
      onDeleteImage: null,
      onMiscChange: null,
      assetCache: assets,
    );
    final svg = SvgEditorImage(
      id: 1,
      svgString: null,
      svgFile: File('/docs/old.sbn2.1'),
      pageIndex: 0,
      pageSize: EditorPage.defaultSize,
      onMoveImage: null,
      onDeleteImage: null,
      onMiscChange: null,
      assetCache: assets,
    );
    final pdf = PdfEditorImage(
      id: 2,
      pdfBytes: Uint8List(0),
      pdfFile: File('/picked/elsewhere.pdf'),
      pdfPage: 0,
      pageIndex: 0,
      pageSize: EditorPage.defaultSize,
      naturalSize: const Size(100, 140),
      onMoveImage: null,
      onDeleteImage: null,
      onMiscChange: null,
      assetCache: assets,
    );

    File? renamed(File file) => file.path.startsWith('/docs/old.sbn2.')
        ? File(file.path.replaceFirst('/docs/old', '/docs/new'))
        : null;
    for (final image in <EditorImage>[png, svg, pdf]) {
      image.moveFile(renamed);
    }
    expect((png.imageProvider as FileImage).file.path, '/docs/new.sbn2.0');
    final saved = OrderedAssetCache();
    svg.toJson(saved);
    expect(saved.fileAt(0)!.path, '/docs/new.sbn2.1');
    // a file from elsewhere is left where it is until it's saved here
    expect(pdf.pdfFile!.path, '/picked/elsewhere.pdf');

    pdf.moveFile(
      (file) => file.path == '/picked/elsewhere.pdf'
          ? File('/docs/new.sbn2.2')
          : null,
    );
    expect(pdf.pdfFile!.path, '/docs/new.sbn2.2');
  });
}
