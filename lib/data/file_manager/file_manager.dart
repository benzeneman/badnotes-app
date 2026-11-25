import 'dart:async';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:badnotes/components/home/note_tags.dart';
import 'package:badnotes/components/home/sort_button.dart';
import 'package:badnotes/data/locks.dart';
import 'package:badnotes/data/favorites.dart';
import 'package:badnotes/data/file_manager/note_versions.dart';
import 'package:badnotes/data/nextcloud/badnotes_syncer.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/i18n/strings.g.dart';
import 'package:badnotes/pages/editor/editor.dart';
import 'package:collection/collection.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:share_plus/share_plus.dart';

/// Reads and writes the user's notes.
///
/// Every path given to these functions is relative to the notes folder
/// ([documentsDirectory]) and starts with a `/`, on every platform. A note is
/// stored as `<name>.sbn2` (or `<name>.sbn` in the old JSON format), with its
/// pictures beside it as `<name>.sbn2.0`, `<name>.sbn2.1`, … and its
/// thumbnail as `<name>.sbn2.p`.
class FileManager {
  new _();

  static final log = Logger('FileManager');

  /// The notes folder's name inside the app's documents directory.
  static const appRootDirectoryPrefix = 'BadNotes';

  /// What that folder was called before the app was renamed. Must stay as
  /// it is: it is a real folder on people's devices.
  static const _previousRootDirectory = 'Saber';

  /// The notes folder in the cloud. It keeps its old name so notes already
  /// uploaded are still found.
  static const remoteRootDirectory = 'Saber';

  /// The absolute path of the notes folder. Not final, because an isolate
  /// can run [init] more than once; in practice it never changes.
  static late String documentsDirectory;

  /// Tells listeners (the home screen, mostly) when a file is written or
  /// deleted. Paths come without their note extension.
  static final fileWriteStream = StreamController<FileOperation>.broadcast();

  /// The longest [stows.recentFiles] gets.
  static const maxRecentlyAccessedFiles = 30;

  /// Matches a note's pictures and thumbnail by their file name, e.g.
  /// `mynote.sbn2.1` or `mynote.sbn2.p`.
  static final assetFileRegex = RegExp(r'\.sbn2?\.[\dp]+$');

  /// Normalises [path] the way the platform's [File] does.
  static String _clean(String path) => File(path).path;

  /// [path] without its trailing [suffix], which it must end with.
  static String _cut(String path, String suffix) =>
      path.substring(0, path.length - suffix.length);

  /// [path] without its `.sbn2`/`.sbn`, or null when it has neither.
  static String? _noteBase(String path) {
    if (path.endsWith(Editor.extension)) return _cut(path, Editor.extension);
    if (path.endsWith(Editor.extensionOldJson)) {
      return _cut(path, Editor.extensionOldJson);
    }
    return null;
  }

  /// The old JSON note that a `.sbn2` note at [notePath] replaces.
  static String _oldJsonSibling(String notePath) =>
      '${_cut(notePath, Editor.extension)}${Editor.extensionOldJson}';

  // -----------------------------------------------------------------------
  // Setting up the notes folder
  // -----------------------------------------------------------------------

  /// Points [documentsDirectory] at the notes folder and, unless told not
  /// to, starts watching it for changes.
  static Future<void> init({
    String? documentsDirectory,
    bool shouldWatchRootDirectory = true,
  }) async {
    FileManager.documentsDirectory =
        documentsDirectory ?? await getDocumentsDirectory();
    if (shouldWatchRootDirectory) unawaited(watchRootDirectory());
  }

  /// The folder the user chose, or else the default one.
  static Future<String> getDocumentsDirectory() async =>
      stows.customDataDir.value ?? await getDefaultDocumentsDirectory();

  /// `<app documents>/BadNotes`. Someone updating from the old app name has
  /// their `Saber` folder renamed to it, as long as nothing is in the way.
  static Future<String> getDefaultDocumentsDirectory() async {
    final parent = (await getApplicationDocumentsDirectory()).path;
    final current = '$parent/$appRootDirectoryPrefix';
    final previous = '$parent/$_previousRootDirectory';
    try {
      final shouldMove =
          stows.customDataDir.value != previous &&
          Directory(previous).existsSync() &&
          !Directory(current).existsSync();
      if (shouldMove) Directory(previous).renameSync(current);
    } on FileSystemException catch (e) {
      log.severe('Could not move the notes folder to its new name: $e');
    }
    return current;
  }

  /// Moves everything to the folder now chosen in the settings. Nothing is
  /// moved if both the old and the new folder already have files in them.
  static Future<void> migrateDataDir() async {
    final from = Directory(documentsDirectory);
    final to = Directory(await getDocumentsDirectory());
    if (from.path == to.path) return;
    log.info('Migrating data directory from $from to $to');

    bool isEmpty(Directory dir) =>
        dir.existsSync() ? dir.listSync().isEmpty : true;
    late final fromEmpty = isEmpty(from);
    late final toEmpty = isEmpty(to);

    if (!fromEmpty && !toEmpty) {
      log.severe('New and old data directory aren\'t empty, can\'t migrate');
      return;
    }

    documentsDirectory = to.path;
    if (fromEmpty) {
      log.fine('Old data directory is empty or missing, nothing to migrate');
      return;
    }
    await moveDirContents(oldDir: from, newDir: to);
    await from.delete(recursive: true);
  }

  /// Moves every file under [oldDir] to the same place under [newDir],
  /// copying and deleting when a plain rename can't cross devices.
  static Future<void> moveDirContents({
    required Directory oldDir,
    required Directory newDir,
  }) async {
    await newDir.create(recursive: true);

    await for (final entity in oldDir.list(recursive: true)) {
      final target = p.join(
        newDir.path,
        p.relative(entity.path, from: oldDir.path),
      );

      if (entity is Directory) {
        await Directory(target).create(recursive: true);
      } else if (entity is File) {
        await entity.parent.create(recursive: true);
        try {
          await entity.rename(target);
        } on FileSystemException catch (e) {
          // EXDEV: e.g. Android's private storage to shared storage
          const crossDevice = 18;
          if (e.osError?.errorCode != crossDevice) rethrow;
          await entity.copy(target);
          await entity.delete();
        }
      }
    }
  }

  /// Passes changes made to the notes folder from outside the app on to
  /// [fileWriteStream]. iOS can't watch folders, so there it only makes
  /// sure the folder exists.
  @visibleForTesting
  static Future<void> watchRootDirectory() async {
    final root = Directory(documentsDirectory);
    await root.create(recursive: true);
    if (Platform.isIOS) return;

    root.watch(recursive: true).listen((event) {
      final FileOperationType type = switch (event.type) {
        FileSystemEvent.delete => .delete,
        FileSystemEvent.create ||
        FileSystemEvent.modify ||
        FileSystemEvent.move => .write,
        _ =>
          kDebugMode
              ? throw UnimplementedError(
                  'Unhandled FileSystemEvent type: ${event.type}',
                )
              : .write,
      };
      // the event's path may be absolute or relative: make it relative
      final relative = event.path
          .replaceAll('\\', '/')
          .replaceFirst(documentsDirectory, '');
      broadcastFileWrite(type, relative);
    });
  }

  /// Adds [path] (minus any note extension) to [fileWriteStream], if anyone
  /// is listening.
  @visibleForTesting
  static void broadcastFileWrite(FileOperationType type, String path) async {
    if (!fileWriteStream.hasListener) return;
    fileWriteStream.add(FileOperation(type, _noteBase(path) ?? path));
  }

  // -----------------------------------------------------------------------
  // File names
  // -----------------------------------------------------------------------

  /// Names no platform allows for a file or folder, each with the message
  /// shown when a name breaks the rule. They're tested on the name only.
  static List<(String, RegExp)> _getForbiddenFilenamePatterns() => [
    (
      t.home.renameNote.noteNameForbiddenCharacters,
      RegExp(r'[<>:"/\\|?*\x00-\x1F]'),
    ),
    (
      t.home.renameNote.noteNameReserved,
      RegExp(
        r'^((con|prn|aux|nul|com[1-9]|lpt[1-9])(\..*)?)|\.+$',
        caseSensitive: false,
      ),
    ),
  ];

  /// Why [filename] can't be used, or null when it's fine.
  static String? validateFilename(String filename) {
    if (filename.isEmpty) return t.home.renameNote.noteNameEmpty;
    for (final (message, pattern) in _getForbiddenFilenamePatterns()) {
      if (pattern.hasMatch(filename)) return message;
    }
    return null;
  }

  /// A free path for a new note in [parentPath], named after today's date.
  static Future<String> newFilePath([String parentPath = '/']) async {
    assert(parentPath.endsWith('/'));
    final today = DateFormat('yy-MM-dd').format(DateTime.now());
    return await suffixFilePathToMakeItUnique(
      '$parentPath$today ${t.editor.untitled}',
    );
  }

  /// Adds " (2)", " (3)", … to [filePath] until no note has that name.
  ///
  /// When [currentPath] is the note being renamed (with its extension), its
  /// own name counts as free, so "/Untitled (2)" renamed to "/Untitled"
  /// stays "/Untitled (2)" rather than becoming "/Untitled (3)".
  ///
  /// If [filePath] had an extension, the result ends with
  /// [intendedExtension] (by default, the same extension); otherwise it has
  /// none.
  static Future<String> suffixFilePathToMakeItUnique(
    String filePath, {
    String? intendedExtension,
    String? currentPath,
  }) async {
    final String base;
    final bool hadExtension;
    if (filePath.endsWith(Editor.extension)) {
      base = _cut(filePath, Editor.extension);
      hadExtension = true;
      intendedExtension ??= Editor.extension;
    } else if (filePath.endsWith(Editor.extensionOldJson)) {
      base = _cut(filePath, Editor.extensionOldJson);
      hadExtension = true;
      intendedExtension ??= Editor.extensionOldJson;
    } else {
      base = filePath;
      hadExtension = false;
      intendedExtension ??= Editor.extension;
    }

    bool isFree(String candidate) =>
        !doesFileExist(candidate + Editor.extension) &&
            !doesFileExist(candidate + Editor.extensionOldJson) ||
        candidate + Editor.extension == currentPath ||
        candidate + Editor.extensionOldJson == currentPath;

    var candidate = base;
    for (var n = 2; !isFree(candidate); n++) {
      candidate = '$base ($n)';
    }
    return candidate + (hadExtension ? intendedExtension : '');
  }

  // -----------------------------------------------------------------------
  // Reading and writing
  // -----------------------------------------------------------------------

  /// When true, [getFile] takes paths as they are instead of inside
  /// [documentsDirectory]. For tests whose files live elsewhere.
  @visibleForTesting
  static var shouldUseRawFilePath = false;

  /// The [File] at [filePath] inside the notes folder.
  static File getFile(String filePath) {
    if (shouldUseRawFilePath) return File(filePath);
    assert(
      filePath.startsWith('/'),
      'Expected filePath to start with a slash, got $filePath',
    );
    return File(documentsDirectory + filePath);
  }

  static Directory getRootDirectory() => Directory(documentsDirectory);

  /// The bytes of the file at [filePath], or null if it is missing or
  /// empty. An empty read is tried again up to [retries] times, 100 ms
  /// apart, in case something else had the file open.
  static Future<Uint8List?> readFile(String filePath, {int retries = 3}) async {
    filePath = _clean(filePath);

    final file = getFile(filePath);
    if (!file.existsSync()) return null;

    final bytes = await file.readAsBytes();
    if (bytes.isNotEmpty) return bytes;
    if (retries <= 0) return null;

    await Future.delayed(const Duration(milliseconds: 100));
    return readFile(filePath, retries: retries - 1);
  }

  /// Saves [toWrite] at [filePath], creating its folder if needed.
  ///
  /// A `.sbn2` note is first written to `<path>.part` and then renamed over
  /// the note, so it is never seen half written (say, when a note is closed
  /// and opened again straight away). Saving one also deletes any old
  /// `.sbn` copy of it.
  ///
  /// [lastModified], if given, becomes the file's modified time, so a
  /// downloaded file has the same time here as in the cloud.
  ///
  /// [quietly] is for autosaves while a note is open: the file isn't moved
  /// up the recent list, announced, or queued for upload, as doing that on
  /// every save kept the main thread busy. [announceWrite] does all of it
  /// later, when the note is left or the app goes to the background.
  ///
  /// Returns before the write is done unless [awaitWrite] is true.
  static Future<void> writeFile(
    String filePath,
    List<int> toWrite, {
    bool awaitWrite = false,
    bool alsoUpload = true,
    bool quietly = false,
    DateTime? lastModified,
  }) async {
    filePath = _clean(filePath);
    log.fine('Writing to $filePath');

    if (!quietly) await _saveFileAsRecentlyAccessed(filePath);

    final file = getFile(filePath);
    await _createFileDirectory(filePath);
    final isNote = filePath.endsWith(Editor.extension);

    Future<File> save() async {
      if (!isNote) return file.writeAsBytes(toWrite);
      final part = File('${file.path}.part');
      await part.writeAsBytes(toWrite, flush: true);
      return part.rename(file.path);
    }

    Future<void> deleteOldJson() => getFile(_oldJsonSibling(filePath))
        .delete()
        // it usually isn't there
        .catchError((_) => File(''), test: (e) => e is PathNotFoundException);

    final written =
        Future.wait([
          save().then((saved) async {
            if (lastModified != null) await saved.setLastModified(lastModified);
          }),
          if (isNote) deleteOldJson(),
        ]).then((_) {
          if (!quietly) {
            broadcastFileWrite(FileOperationType.write, filePath);
            if (alsoUpload) syncer.uploader.enqueueRel(filePath);
          }
          if (isNote) _removeReferences(_oldJsonSibling(filePath));
        });

    if (awaitWrite) await written;
  }

  /// Does for a file saved with `quietly: true` what [writeFile] skipped:
  /// puts it top of the recent list, tells listeners, and queues the upload.
  static void announceWrite(String filePath) {
    filePath = _clean(filePath);
    unawaited(_saveFileAsRecentlyAccessed(filePath));
    broadcastFileWrite(FileOperationType.write, filePath);
    syncer.uploader.enqueueRel(filePath);
  }

  static Future<void> createFolder(String folderPath) async {
    folderPath = _clean(folderPath);
    await Directory(documentsDirectory + folderPath).create(recursive: true);
  }

  /// Creates the folders above [filePath] that don't exist yet.
  static Future _createFileDirectory(String filePath) async {
    assert(filePath.contains('/'), 'filePath must be a path, not a file name');
    final parent = filePath.substring(0, filePath.lastIndexOf('/'));
    await Directory(documentsDirectory + parent).create(recursive: true);
  }

  // -----------------------------------------------------------------------
  // Exporting and importing
  // -----------------------------------------------------------------------

  /// Hands [bytes] to the user as [fileName]: into the gallery for an image
  /// on a phone (unless [share]), through the share sheet for anything else
  /// on a phone, and with a save dialog on desktop.
  ///
  /// Returns false when an image couldn't go into the gallery.
  static Future<bool> exportFile(
    String fileName,
    Uint8List bytes, {
    bool isImage = false,
    bool share = false,
    required BuildContext context,
  }) async {
    final onPhone = Platform.isAndroid || Platform.isIOS;
    if (!onPhone) {
      await FilePicker.saveFile(
        fileName: fileName,
        initialDirectory: (await getDownloadsDirectory())?.path,
        bytes: bytes,
      );
      return true;
    }

    if (isImage && !share) {
      if (!await _requestPhotosPermission()) return false;
      final result = await SaverGallery.saveImage(
        Uint8List.fromList(bytes),
        fileName: fileName,
        albumPath: 'BadNotes',
        skipIfExists: true,
      );
      return result.isSuccess;
    }

    final tempFile = File('${(await getTemporaryDirectory()).path}/$fileName');
    await tempFile.writeAsBytes(bytes);
    final files = [XFile(tempFile.path)];
    if (Platform.isIOS || Platform.isMacOS) {
      if (!context.mounted) return false;
      // iOS only shows the share sheet when told where it comes from
      final box = context.findRenderObject() as RenderBox;
      await SharePlus.instance.share(
        ShareParams(
          files: files,
          sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } else {
      await SharePlus.instance.share(ShareParams(files: files));
    }
    await tempFile.delete();
    return true;
  }

  /// Asks for the permission needed to add a picture to the gallery.
  static Future<bool> _requestPhotosPermission() async {
    if (Platform.isIOS) {
      return await Permission.photosAddOnly.request().isGranted;
    }
    if (!Platform.isAndroid) return true;

    final info = await DeviceInfoPlugin().androidInfo;
    final permission = info.version.sdkInt > 33
        ? Permission.photos
        : Permission.storage;
    return await permission.request().isGranted;
  }

  /// Copies the note at [path] (`.sbn2`, `.sbn`, or a `.sba` archive with
  /// its pictures) into [parentDir], which starts and ends with `/`.
  ///
  /// [extension] starts with a dot; when missing it is taken from [path].
  ///
  /// Returns where the note went, without its extension, or null if an
  /// archive held no note.
  static Future<String?> importFile(
    String path,
    String? parentDir, {
    String? extension,
    bool awaitWrite = true,
  }) async {
    assert(
      parentDir == null || parentDir.startsWith('/') && parentDir.endsWith('/'),
    );
    if (extension == null) {
      extension = '.${path.split('.').last}';
      assert(extension.length > 1);
    } else {
      assert(extension.startsWith('.'));
    }

    final nameWithExtension = path.split(RegExp(r'[\\/]')).last;
    final name = nameWithExtension.substring(
      0,
      nameWithExtension.lastIndexOf('.'),
    );
    final destination = '${parentDir ?? '/'}$name';

    if (extension.toLowerCase() != '.sba') {
      final bytes = await File(path).readAsBytes();
      final lowerExtension = extension.toLowerCase();
      final importedPath = await suffixFilePathToMakeItUnique(
        destination,
        intendedExtension: lowerExtension,
      );
      await writeFile(
        importedPath + lowerExtension,
        bytes,
        awaitWrite: awaitWrite,
      );
      return importedPath;
    }

    final archive = ZipDecoder().decodeStream(InputFileStream(path));
    final note = archive.files.cast<ArchiveFile?>().firstWhere((entry) {
      final lower = entry!.name.toLowerCase();
      return lower.endsWith('sbn') || lower.endsWith('sbn2');
    }, orElse: () => null);
    if (note == null) {
      log.severe('Failed to find main note in sba: $path');
      return null;
    }

    Uint8List contentOf(ArchiveFile entry) {
      final output = OutputMemoryStream();
      entry.writeContent(output);
      return output.getBytes();
    }

    final noteExtension = '.${note.name.split('.').last}'.toLowerCase();
    final importedPath = await suffixFilePathToMakeItUnique(
      destination,
      intendedExtension: noteExtension,
    );
    final writes = <Future>[
      writeFile(
        importedPath + noteExtension,
        contentOf(note),
        awaitWrite: awaitWrite,
      ),
    ];

    // the note's pictures are the entries named "<anything>.<number>"
    for (final entry in archive.files) {
      if (!entry.isFile || entry == note) continue;
      final assetNumber = int.tryParse(entry.name.split('.').last);
      if (assetNumber == null || assetNumber < 0) continue;
      writes.add(
        writeFile(
          '$importedPath$noteExtension.$assetNumber',
          contentOf(entry),
          awaitWrite: awaitWrite,
        ),
      );
    }

    await Future.wait(writes);
    return importedPath;
  }

  // -----------------------------------------------------------------------
  // Moving and deleting
  // -----------------------------------------------------------------------

  /// The numbered pictures of the file at [path] (`.0`, `.1`, … up to the
  /// first gap), as their suffixes.
  static List<int> _numberedAssets(String path) => [
    for (var n = 0; getFile('$path.$n').existsSync(); n++) n,
  ];

  /// Moves [fromPath] to [toPath] and returns where it ended up.
  ///
  /// A bare file name for [toPath] keeps the file in its folder. If
  /// something is already at [toPath], a number is added to the name, unless
  /// [replaceExistingFile] is true and [toPath] isn't a reserved name, in
  /// which case the existing file is overwritten.
  ///
  /// With [alsoMoveAssets], the note's pictures, thumbnail, and BadNotes'
  /// own files beside it (see [_badNotesSidecars]) go with it.
  static Future<String> moveFile(
    String fromPath,
    String toPath, {
    bool replaceExistingFile = false,
    bool alsoMoveAssets = true,
  }) async {
    fromPath = _clean(fromPath);
    toPath = _clean(toPath);

    if (!toPath.contains('/')) {
      final folder = fromPath.substring(0, fromPath.lastIndexOf('/') + 1);
      toPath = folder + toPath;
    }
    if (!replaceExistingFile || Editor.isReservedPath(toPath)) {
      toPath = await suffixFilePathToMakeItUnique(
        toPath,
        currentPath: fromPath,
      );
    }
    if (fromPath == toPath) return toPath;

    final fromFile = getFile(fromPath);
    await _createFileDirectory(toPath);
    if (fromFile.existsSync()) {
      await fromFile.rename(getFile(toPath).path);
    } else {
      log.warning('Tried to move non-existent file from $fromPath to $toPath');
    }

    syncer.uploader.enqueueRel(fromPath);
    syncer.uploader.enqueueRel(toPath);
    _renameReferences(fromPath, toPath);

    // the note's saved versions move with it
    if (fromPath.endsWith(Editor.extension) &&
        toPath.endsWith(Editor.extension)) {
      unawaited(
        NoteVersions.move(
          _cut(fromPath, Editor.extension),
          _cut(toPath, Editor.extension),
        ),
      );
    }
    broadcastFileWrite(FileOperationType.delete, fromPath);
    broadcastFileWrite(FileOperationType.write, toPath);

    if (alsoMoveAssets && !assetFileRegex.hasMatch(fromPath)) {
      final suffixes = [
        for (final n in _numberedAssets(fromPath)) '$n',
        if (getFile('$fromPath.p').existsSync()) 'p',
      ];
      await Future.wait([
        for (final suffix in suffixes)
          moveFile(
            '$fromPath.$suffix',
            '$toPath.$suffix',
            replaceExistingFile: replaceExistingFile,
          ),
      ]);
    }
    if (alsoMoveAssets) await _moveBadNotesSidecars(fromPath, toPath);

    return toPath;
  }

  /// The extra files BadNotes keeps beside a `.sbn2` note: its audio index
  /// (`.audio.json`), recognised text (`.ocr.txt`, `.ocr.json`), cover
  /// (`.cover`, `.covername`), the page as it was left, shown while the note opens
  /// (`.open.png`), and its recordings (`<name>.recN.m4a`).
  static List<File> _badNotesSidecars(String notePathWithExt) {
    if (!notePathWithExt.endsWith(Editor.extension)) return const [];
    final base = _cut(notePathWithExt, Editor.extension);
    final cut = base.lastIndexOf('/') + 1;
    final name = base.substring(cut);
    final folder = Directory(documentsDirectory + base.substring(0, cut));

    const suffixes = [
      '.audio.json',
      '.ocr.txt',
      '.ocr.json',
      '.cover',
      '.covername',
      '.open.png',
    ];
    return [
      for (final suffix in suffixes)
        if (getFile('$base$suffix').existsSync()) getFile('$base$suffix'),
      if (folder.existsSync())
        for (final file in folder.listSync().whereType<File>())
          if (file.uri.pathSegments.last.startsWith('$name.rec') &&
              file.path.endsWith('.m4a'))
            file,
    ];
  }

  /// Takes a note's [_badNotesSidecars] along when it moves. The index files
  /// are renamed after the note; recordings keep their names (the audio
  /// index refers to them) and only change folder.
  static Future<void> _moveBadNotesSidecars(String from, String to) async {
    if (!to.endsWith(Editor.extension)) return;
    final oldBase = _cut(from, Editor.extension);
    final newBase = _cut(to, Editor.extension);
    final oldName = oldBase.substring(oldBase.lastIndexOf('/') + 1);
    final newFolder = newBase.substring(0, newBase.lastIndexOf('/') + 1);

    for (final file in _badNotesSidecars(from)) {
      final fileName = file.uri.pathSegments.last;
      final newPath = fileName.endsWith('.m4a')
          ? '$newFolder$fileName'
          : '$newBase${fileName.substring(oldName.length)}';
      try {
        await file.rename(getFile(newPath).path);
      } catch (e) {
        log.warning('Could not move $fileName with its note', e);
      }
    }
  }

  /// Deletes [filePath] and, with [alsoDeleteAssets], everything that
  /// belongs to it: BadNotes' extra files, saved versions, numbered pictures
  /// and the thumbnail. Does nothing when the file isn't there.
  static Future deleteFile(
    String filePath, {
    bool alsoUpload = true,
    bool alsoDeleteAssets = true,
  }) async {
    filePath = _clean(filePath);

    final file = getFile(filePath);
    if (!file.existsSync()) return;

    if (alsoDeleteAssets) {
      for (final sidecar in _badNotesSidecars(filePath)) {
        try {
          await sidecar.delete();
        } catch (_) {}
      }
    }
    await file.delete();

    if (alsoUpload) syncer.uploader.enqueueRel(filePath);
    _removeReferences(filePath);
    if (alsoDeleteAssets && filePath.endsWith(Editor.extension)) {
      unawaited(NoteVersions.forget(_cut(filePath, Editor.extension)));
    }
    broadcastFileWrite(FileOperationType.delete, filePath);

    if (alsoDeleteAssets && !assetFileRegex.hasMatch(filePath)) {
      final assetNumbers = _numberedAssets(filePath);
      final hasThumbnail = getFile('$filePath.p').existsSync();
      await Future.wait([
        for (final n in assetNumbers)
          deleteFile('$filePath.$n', alsoDeleteAssets: false),
        if (hasThumbnail) deleteFile('$filePath.p', alsoDeleteAssets: false),
      ]);
    }
  }

  /// Deletes the note's pictures numbered [numAssets] and up, which it no
  /// longer uses.
  static Future removeUnusedAssets(
    String filePath, {
    required int numAssets,
  }) async {
    final deletions = <Future>[];
    for (var n = numAssets; getFile('$filePath.$n').existsSync(); n++) {
      deletions.add(deleteFile('$filePath.$n'));
    }
    await Future.wait(deletions);
  }

  /// Renames the folder at [directoryPath] to [newName] (a name, not a
  /// path), and lets everything that refers to its files know.
  static Future renameDirectory(String directoryPath, String newName) async {
    directoryPath = _clean(directoryPath);

    final directory = Directory(documentsDirectory + directoryPath);
    if (!directory.existsSync()) return;

    // every file inside, relative to the folder
    final children = <String>[];
    await for (final entity in directory.list(recursive: true)) {
      if (entity is File) {
        children.add(entity.path.substring(directory.path.length));
      }
    }

    final parent = directoryPath.substring(
      0,
      directoryPath.lastIndexOf('/') + 1,
    );
    final newPath = parent + newName;
    await directory.rename(documentsDirectory + newPath);
    NoteLocks.move(directoryPath, newPath);

    for (final child in children) {
      _renameReferences(directoryPath + child, newPath + child);
      broadcastFileWrite(FileOperationType.delete, directoryPath + child);
      broadcastFileWrite(FileOperationType.write, newPath + child);
    }
  }

  /// Deletes the folder at [directoryPath]. When [recursive], each file in
  /// it goes through [deleteFile] first, so the cloud and the lists hear of
  /// it.
  static Future deleteDirectory(
    String directoryPath, [
    bool recursive = true,
  ]) async {
    directoryPath = _clean(directoryPath);

    final directory = Directory(documentsDirectory + directoryPath);
    if (!directory.existsSync()) return;

    if (recursive) {
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          await deleteFile(entity.path.substring(documentsDirectory.length));
        }
      }
    }
    await directory.delete(recursive: recursive);
    NoteLocks.forgetFolder(directoryPath);
  }

  // -----------------------------------------------------------------------
  // Listing
  // -----------------------------------------------------------------------

  /// What is directly inside [directory]: its visible subfolders, and its
  /// notes sorted by [sortMetric].
  ///
  /// Notes are listed without their extension unless [includeExtensions].
  /// [includeAssets] (which needs [includeExtensions], to tell notes and
  /// pictures apart) also lists pictures, thumbnails and other files; the
  /// syncer uses that.
  ///
  /// Returns null when the folder doesn't exist.
  static Future<DirectoryChildren?> getChildrenOfDirectory(
    String directory, {
    bool includeExtensions = false,
    bool includeAssets = false,
    SortMetric sortMetric = .nameAToZ,
  }) async {
    assert(
      !includeAssets || includeExtensions,
      'includeAssets can\'t be true without includeExtensions',
    );

    directory = _clean(directory);
    if (!directory.endsWith('/')) directory += '/';

    final dir = Directory(documentsDirectory + directory);
    if (!dir.existsSync()) return null;

    /// What [entity] is listed as, relative to the notes folder, or null to
    /// leave it out.
    String? listedAs(FileSystemEntity entity) {
      final path = entity.path.substring(documentsDirectory.length);

      // folders starting with a dot (.trash, .templates) stay hidden
      if (entity is Directory) {
        return p.basename(entity.path).startsWith('.') ? null : path;
      }
      if (Editor.isReservedPath(path)) return null;

      final base = _noteBase(path);
      if (!includeExtensions) return base;
      if (!includeAssets && base == null) return null;
      return path;
    }

    final names = await dir
        .list()
        .map(listedAs)
        .where((path) => path != null)
        .map((path) => path!.substring(directory.length))
        .toList();

    final List<String> directories = [], files = [];
    for (final name in names) {
      if (FileManager.isDirectory(directory + name) &&
          !directories.contains(name)) {
        directories.add(name);
      } else if (includeAssets || !assetFileRegex.hasMatch(name)) {
        files.add(name);
      }
    }

    DateTime modified(String name) =>
        lastModified(directory + name + Editor.extension);
    switch (sortMetric) {
      case .nameAToZ:
        directories.sort();
        files.sort();
      case .nameZToA:
        directories.sort((a, b) => -a.compareTo(b));
        files.sort((a, b) => -a.compareTo(b));
      case .lastModifiedNewToOld:
        directories.sort();
        files.sortByCompare(modified, (a, b) => -a.compareTo(b));
      case .lastModifiedOldToNew:
        directories.sort();
        files.sortBy(modified);
    }

    return DirectoryChildren(directories, files);
  }

  /// Every file under the notes folder, at any depth. The flags work as in
  /// [getChildrenOfDirectory].
  static Future<List<String>> getAllFiles({
    bool includeExtensions = false,
    bool includeAssets = false,
  }) async {
    final found = <String>[];
    final toVisit = <String>['/'];

    while (toVisit.isNotEmpty) {
      final folder = toVisit.removeLast();
      final children = await getChildrenOfDirectory(
        folder,
        includeExtensions: includeExtensions,
        includeAssets: includeAssets,
      );
      if (children == null) continue;

      found.addAll(children.files.map((file) => '$folder$file'));
      toVisit.addAll(children.directories.map((sub) => '$folder$sub/'));
    }

    return found;
  }

  /// The recently opened notes, newest first and without extensions.
  /// Notes deleted outside the app are dropped from the list on the way.
  static Future<List<String>> getRecentlyAccessed() async {
    if (!stows.recentFiles.loaded) await stows.recentFiles.waitUntilRead();
    for (final file in stows.recentFiles.value.toList()) {
      if (!doesFileExist(file)) _removeReferences(file);
    }
    return stows.recentFiles.value
        .map((path) => _noteBase(path) ?? path)
        .where((path) => !Editor.isReservedPath(path))
        .toList();
  }

  /// Whether a folder exists at [filePath].
  static bool isDirectory(String filePath) {
    filePath = _clean(filePath);
    return Directory(documentsDirectory + filePath).existsSync();
  }

  static bool doesFileExist(String filePath) {
    filePath = _clean(filePath);
    return getFile(filePath).existsSync();
  }

  /// When [filePath] was last changed, or the start of 2023 if it's missing.
  static DateTime lastModified(String filePath) {
    filePath = _clean(filePath);
    final file = getFile(filePath);
    return file.existsSync() ? file.lastModifiedSync() : DateTime(2023);
  }

  // -----------------------------------------------------------------------
  // Favourites, tags and the recent list
  // -----------------------------------------------------------------------

  /// Follows a file to its new path in the favourites, tags and recent list.
  static Future _renameReferences(String fromPath, String toPath) async {
    Favorites.rename(fromPath, toPath);
    // stars are kept without the extension
    if (fromPath.endsWith(Editor.extension) &&
        toPath.endsWith(Editor.extension)) {
      Favorites.rename(
        _cut(fromPath, Editor.extension),
        _cut(toPath, Editor.extension),
      );
    }
    NoteTags.rename(fromPath, toPath);
    NoteLocks.renameFile(fromPath, toPath);

    final recent = stows.recentFiles.value;
    var renamed = false;
    for (var i = 0; i < recent.length; i++) {
      if (recent[i] != fromPath) continue;
      if (renamed) {
        recent.removeAt(i);
      } else {
        recent[i] = toPath;
        renamed = true;
      }
    }
    stows.recentFiles.notifyListeners();
  }

  /// Forgets a deleted file in the favourites, tags and recent list.
  static Future _removeReferences(String filePath) async {
    Favorites.remove(filePath);
    NoteTags.forget(filePath);
    NoteLocks.forgetFile(filePath);

    final recent = stows.recentFiles.value;
    for (var i = 0; i < recent.length; i++) {
      if (recent[i] == filePath) recent.removeAt(i);
    }
    stows.recentFiles.notifyListeners();
  }

  /// Puts [filePath] first in the recent list (pictures aside), keeping the
  /// list to [maxRecentlyAccessedFiles].
  static Future _saveFileAsRecentlyAccessed(String filePath) async {
    if (assetFileRegex.hasMatch(filePath)) return;

    final recent = stows.recentFiles.value
      ..remove(filePath)
      ..insert(0, filePath);
    if (recent.length > maxRecentlyAccessedFiles) recent.removeLast();
    stows.recentFiles.notifyListeners();
  }
}

/// The folders and files directly inside a folder.
class DirectoryChildren {
  new(this.directories, this.files);

  final List<String> directories;
  final List<String> files;

  bool onlyOneChild() => directories.length + files.length <= 1;

  bool get isEmpty => directories.isEmpty && files.isEmpty;
  bool get isNotEmpty => !isEmpty;
}

enum FileOperationType { write, delete }

/// A file that was written or deleted, as sent on
/// [FileManager.fileWriteStream].
class FileOperation {
  const new(this.type, this.filePath);

  final FileOperationType type;
  final String filePath;

  /// Whether this is a note's picture or thumbnail, which doesn't change
  /// which notes and folders there are.
  bool get isNoteAsset => filePath.contains('${Editor.extension}.');
}
