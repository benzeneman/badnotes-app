import 'dart:convert';
import 'dart:io';

import 'package:abstract_sync/abstract_sync.dart';
import 'package:collection/collection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/data/nextcloud/errors.dart';
import 'package:badnotes/data/nextcloud/remote_store.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/pro/pro.dart';
import 'package:badnotes/i18n/strings.g.dart';
import 'package:badnotes/pages/editor/editor.dart';
import 'package:worker_manager/worker_manager.dart';

/// The app's one sync engine: it moves files between this device and the
/// user's cloud store.
final syncer =
    Syncer<BadNotesSyncInterface, BadNotesSyncFile, File, RemoteFile>(
      const BadNotesSyncInterface(),
      failureTimeout: const Duration(seconds: 4),
    );

/// How BadNotes plugs into the generic sync engine: which files changed on
/// each side, and how a file is encrypted on the way up and decrypted on the
/// way down.
///
/// In the cloud every file sits flat in [FileManager.remoteRootDirectory],
/// named after its encrypted local path plus [encExtension]; only the
/// encryption config keeps a plain name.
class const BadNotesSyncInterface()
    extends AbstractSyncInterface<BadNotesSyncFile, File, RemoteFile> {
  static final log = Logger('BadNotesSyncInterface');

  /// The encrypted file extension used in the cloud.
  static const encExtension = '.sbe';

  /// The suffix of a note's thumbnail, e.g. `note.sbn2.p`.
  static const previewExtension = '.p';

  /// Cloud files that are never synced. Each starts with a slash so a
  /// path can be matched with `endsWith`.
  static const _ignoredFiles = <String>['/Readme.md'];

  // ---------------------------------------------------------------------
  // Identity
  // ---------------------------------------------------------------------

  @override
  bool areRemoteFilesEqual(RemoteFile a, RemoteFile b) => a.path == b.path;

  @override
  bool areLocalFilesEqual(File a, File b) => a.path == b.path;

  // ---------------------------------------------------------------------
  // Finding what changed
  // ---------------------------------------------------------------------

  @override
  Future<List<BadNotesSyncFile>> findLocalChanges() async {
    if (!await canSyncNow()) return const [];
    // thumbnails hold off until Wi-Fi unless mobile data is allowed for them
    final previewsAllowed = await canSyncPreviewsNow();

    // give findRemoteChanges a moment to fill in remoteFiles
    for (var attempt = 0; attempt < 10 && remoteFiles.isEmpty; attempt++) {
      await Future.delayed(const Duration(milliseconds: 200));
    }

    final toUpload = <BadNotesSyncFile>[];
    final everything = FileManager.getRootDirectory().list(recursive: true);
    await for (final entity in everything) {
      if (entity is! File) continue;
      if (!previewsAllowed && entity.path.endsWith(previewExtension)) continue;
      // half a save, cut short by a kill: not a note to upload
      if (entity.path.endsWith('.part')) continue;

      final syncFile = await getSyncFileFromLocalFile(entity);
      final winner = await getBestFile(
        syncFile,
        onLocalFileNotFound: .local,
        onEqualFiles: .remote,
      );
      // when the cloud copy wins there is nothing to upload
      if (winner == .local) toUpload.add(syncFile);
    }
    return toUpload;
  }

  @override
  Future<List<BadNotesSyncFile>> findRemoteChanges() async {
    if (store == null) return const [];
    if (!await canSyncNow()) return const [];

    remoteFiles = await findRemoteFiles();
    if (remoteFiles.isEmpty) return const [];

    undecryptable.clear();
    final candidates = await Future.wait(remoteFiles.map(_remoteChangeOf));
    // files that can't be opened with this device's key would otherwise
    // just never appear, so say so
    if (undecryptable.isNotEmpty) {
      SyncStatus.error.value = CloudCannotDecrypt(undecryptable.length);
    }
    final toDownload = candidates.nonNulls.toList();
    _putPreviewsBeforeTheirNotes(toDownload);
    return toDownload;
  }

  /// The cloud files whose names the last look could not decrypt (locked
  /// with another key). Emptied files (deletions) aren't counted.
  static final undecryptable = <String>[];

  /// Empties every file in [undecryptable], which no device here can open,
  /// so they stop being reported. Returns how many were cleared.
  static Future<int> clearUndecryptable() async {
    final store = BadNotesSyncInterface.store;
    if (store == null) return 0;
    final paths = [...undecryptable];
    var cleared = 0;
    for (final path in paths) {
      try {
        await store.put(Uint8List(0), path);
        cleared++;
      } catch (e, st) {
        log.warning('Could not clear $path: $e', e, st);
      }
    }
    undecryptable.clear();
    if (SyncStatus.error.value is CloudCannotDecrypt) {
      SyncStatus.error.value = null;
    }
    syncer.downloader.refresh();
    return cleared;
  }

  /// The file to download for [remoteFile], or null when the local copy is
  /// as new, or when both sides have already deleted it.
  Future<BadNotesSyncFile?> _remoteChangeOf(RemoteFile remoteFile) async {
    final BadNotesSyncFile syncFile;
    try {
      syncFile = await getSyncFileFromRemoteFile(remoteFile);
    } catch (e, st) {
      log.warning('Failed to get sync file from remote file: $e', e, st);
      if (!remoteFile.path.endsWith(RemoteStore.configFileName) &&
          (remoteFile.size ?? 1) > 0) {
        undecryptable.add(remoteFile.path);
      }
      return null;
    }

    final winner = await getBestFile(
      syncFile,
      onLocalFileNotFound: .remote,
      onEqualFiles: .local,
    );
    if (winner == .local) return null;
    // an open note's cloud version, already kept beside it
    final path = syncFile.relativeLocalPath;
    if (_keptFromCloud.containsKey(path) &&
        _keptFromCloud[path] == syncFile.remoteFile?.lastModified &&
        _openNoteOf(path) != null) {
      return null;
    }

    // the cloud copy is newer, or there is no local copy
    final deletedThere = syncFile.remoteFile!.size! <= 0;
    final deletedHere = stows.fileSyncAlreadyDeleted.value.contains(
      syncFile.relativeLocalPath,
    );
    if (deletedThere && deletedHere) return null;
    return syncFile;
  }

  /// Moves each thumbnail (`note.sbn2.p`) to just before its note
  /// (`note.sbn2`), so the home screen gets the new picture first.
  static void _putPreviewsBeforeTheirNotes(List<BadNotesSyncFile> files) {
    final previews = [
      for (final file in files)
        if (file.localFile.path.endsWith('.p')) file,
    ];
    for (final preview in previews) {
      final previewPath = preview.localFile.path;
      final notePath = previewPath.substring(0, previewPath.length - 2);
      final from = files.indexOf(preview);
      final noteAt = files.indexWhere(
        (file) => file.localFile.path == notePath,
      );
      if (from < 0 || noteAt < 0) continue;

      files.removeAt(from);
      // removing it shifted the note up by one if the preview was before it
      files.insert(from >= noteAt ? noteAt : noteAt - 1, preview);
    }
  }

  // ---------------------------------------------------------------------
  // Pairing local and cloud files
  // ---------------------------------------------------------------------

  @override
  Future<BadNotesSyncFile> getSyncFileFromLocalFile(File localFile) async {
    // relative to the documents folder, always with forward slashes
    final relativePath = localFile.path
        .substring(FileManager.documentsDirectory.length)
        .replaceAll(Platform.pathSeparator, '/');
    assert(relativePath.startsWith('/'));

    final encryptedName = await encryptPath(store, relativePath);
    final remotePath =
        '${FileManager.remoteRootDirectory}/$encryptedName$encExtension';

    return BadNotesSyncFile(
      remoteFile: await getRemoteFile(remotePath),
      remotePath: remotePath,
      localFile: localFile,
    );
  }

  @override
  Future<BadNotesSyncFile> getSyncFileFromRemoteFile(
    RemoteFile remoteFile,
  ) async {
    final relativeLocalPath = await decryptPath(store!, remoteFile.path);
    if (relativeLocalPath == null) {
      throw Exception('Decryption failed for ${remoteFile.path}');
    }
    return BadNotesSyncFile(
      remoteFile: remoteFile,
      localFile: FileManager.getFile(relativeLocalPath),
    );
  }

  // ---------------------------------------------------------------------
  // Downloading
  // ---------------------------------------------------------------------

  @override
  Future<Uint8List> downloadRemoteFile(BadNotesSyncFile file) async {
    if (file.localFile.path.endsWith(RemoteStore.configFileName)) {
      await _reloadEncryptionConfig();
      return Uint8List(0);
    }
    // a size of zero marks a deletion; writeLocalFile deals with it
    if (file.remoteFile?.size == 0) return Uint8List(0);

    final store = _loggedInStore('download file');
    return await store.get(file.remotePath);
  }

  /// The encryption config changed in the cloud. If its password no longer
  /// matches the one saved here, the user is logged out of encryption.
  static Future<void> _reloadEncryptionConfig() async {
    try {
      await BadNotesSyncInterface.store?.loadEncryptionKey(
        generateKeyIfMissing: false,
      );
    } on EncLoginFailure {
      stows.encPassword.value = '';
      stows.key.value = '';
      stows.iv.value = '';
    }
  }

  @override
  Future<void> writeLocalFile(
    BadNotesSyncFile file,
    // ignore: avoid_renaming_method_parameters
    Uint8List encryptedBytes, {
    @visibleForTesting bool awaitWrite = false,
  }) async {
    // the config was already dealt with while downloading
    if (file.localFile.path == RemoteStore.configFileName) return;

    final path = file.relativeLocalPath;
    // A note open in an editor isn't written over: the editor's next save
    // put what it had back over it, and the other device's work was gone
    // everywhere. Its cloud version is kept beside it instead.
    final open = _openNoteOf(path);
    if (open != null && encryptedBytes.isEmpty) return; // once it's closed

    if (encryptedBytes.isEmpty) {
      await _keepConflictCopy(file, Uint8List(0));
      // deleted in the cloud, so delete it here too
      _recordSynced(path, null);
      await FileManager.deleteFile(path, alsoUpload: false, keepVersions: true);
      stows.fileSyncAlreadyDeleted.value.add(path);
      stows.fileSyncAlreadyDeleted.notifyListeners();
      _announceCover(path);
      return;
    }

    final store = _loggedInStore('decrypt file');
    final plain = await _decryptContents(
      encryptedBytes,
      encrypter: store.encrypter,
      iv: _savedIv(),
      asBase64Text: file.localFile.path.endsWith(Editor.extensionOldJson),
    );
    assert(
      plain.isNotEmpty,
      'Decrypted data is empty but encryptedBytes.length is ${encryptedBytes.length}',
    );
    if (open == null) await _keepConflictCopy(file, plain);

    final cloudTime = file.remoteFile?.lastModified;
    if (open != null) {
      final suffix = path.substring(open.length + Editor.extension.length);
      // a name of its own, picked once: never written over another note,
      // and later cloud changes go to the same copy
      final copy = _cloudCopies[open] ??=
          await FileManager.suffixFilePathToMakeItUnique(
            '$open (from cloud)${Editor.extension}',
          );
      if (suffix.isEmpty && !_keptFromCloud.containsKey(path)) {
        log.info('$path is open; keeping the cloud version as $copy');
        SyncStatus.conflicts.value = [
          ...SyncStatus.conflicts.value,
          (
            note: _nameOf(open),
            copy: _nameOf(
              copy.substring(0, copy.length - Editor.extension.length),
            ),
          ),
        ];
      }
      await FileManager.writeFile(
        '$copy$suffix',
        plain,
        awaitWrite: awaitWrite,
      );
      _keptFromCloud[path] = cloudTime;
      return;
    }
    await FileManager.writeFile(
      path,
      plain,
      awaitWrite: awaitWrite,
      alsoUpload: false,
      // match the cloud copy's modified time
      lastModified: cloudTime,
    );
    _recordSynced(path, cloudTime);
    _announceCover(path);
  }

  /// The note (its path without the extension) [path] is, or is a picture
  /// or thumbnail of, if that note is open in an editor now.
  static String? _openNoteOf(String path) {
    final match = _noteFile.firstMatch(path);
    if (match == null) return null;
    final note = match[1]!;
    return Editor.isOpen(note) ? note : null;
  }

  static final _noteFile = RegExp(r'^(.*)\.sbn2(?:\.(?:\d+|p))?$');

  /// Cloud versions of open notes' files already kept beside them, with
  /// the cloud's time for each: not downloaded again while it's the same.
  static final _keptFromCloud = <String, DateTime?>{};

  /// For each open note whose cloud version is kept beside it, that copy's
  /// path (with the extension).
  static final _cloudCopies = <String, String>{};

  /// A notebook's cover (`note.cover`, `note.covername`) came from the
  /// cloud: tell its card, which listens for the note's own path.
  static void _announceCover(String path) {
    for (final suffix in const ['.cover', '.covername']) {
      if (path.endsWith(suffix)) {
        // ignore: invalid_use_of_visible_for_testing_member
        FileManager.broadcastFileWrite(
          .write,
          path.substring(0, path.length - suffix.length),
        );
      }
    }
  }

  // ---------------------------------------------------------------------
  // Uploading
  // ---------------------------------------------------------------------

  @override
  Future<Uint8List> readLocalFile(BadNotesSyncFile file) async {
    final exists = file.localFile.existsSync();
    // the time of what's read, taken before reading: see uploadRemoteFile
    if (exists)
      _readAt[file.relativeLocalPath] = _localModifiedOrNow(file.localFile);
    final plain = exists ? await file.localFile.readAsBytes() : Uint8List(0);
    // empty means deleted; uploadRemoteFile sends it as such
    if (plain.isEmpty) return plain;

    final store = _loggedInStore('encrypt file');
    return _encryptContents(
      plain,
      encrypter: store.encrypter,
      iv: _savedIv(),
      asBase64Text: file.localFile.path.endsWith(Editor.extensionOldJson),
    );
  }

  @override
  Future<void> uploadRemoteFile(
    BadNotesSyncFile file,
    // ignore: avoid_renaming_method_parameters
    Uint8List encryptedBytes,
  ) async {
    // The time of the bytes being sent. The file's time after the upload
    // was that of a save made meanwhile, so the cloud copy looked as new as
    // it, and that save was never uploaded.
    final readAt = _readAt.remove(file.relativeLocalPath);
    var lastModified = readAt ?? _localModifiedOrNow(file.localFile);
    final resyncFrom = stows.fileSyncResyncEverythingDate.value;
    if (lastModified.isBefore(resyncFrom)) lastModified = resyncFrom;

    final store = _loggedInStore('upload file');
    final path = file.relativeLocalPath;
    try {
      await store.put(
        encryptedBytes,
        file.remotePath,
        lastModified: lastModified,
      );
    } catch (e) {
      SyncStatus._uploadFailed(path, e);
      rethrow;
    }
    SyncStatus._uploaded(path);
    _recordSynced(
      path,
      file.localFile.existsSync()
          ? readAt ?? file.localFile.lastModifiedSync()
          : null,
    );
  }

  /// When each file being uploaded was last modified as it was read.
  static final _readAt = <String, DateTime>{};

  static DateTime _localModifiedOrNow(File file) {
    try {
      return file.lastModifiedSync();
    } on FileSystemException {
      return DateTime.now();
    }
  }

  // ---------------------------------------------------------------------
  // Encryption of file contents
  // ---------------------------------------------------------------------

  static IV _savedIv() => IV.fromBase64(stows.iv.value);

  /// Old JSON notes travel as base64 text; everything else as raw bytes.
  static Future<Uint8List> _encryptContents(
    Uint8List plain, {
    required Encrypter encrypter,
    required IV iv,
    required bool asBase64Text,
  }) => workerManager.execute<Uint8List>(
    asBase64Text
        ? () async {
            final text = utf8.decode(plain);
            return utf8.encode(encrypter.encrypt(text, iv: iv).base64);
          }
        : () async => encrypter.encryptBytes(plain, iv: iv).bytes,
    priority: WorkPriority.highRegular,
  );

  /// The reverse of [_encryptContents].
  static Future<Uint8List> _decryptContents(
    Uint8List encrypted, {
    required Encrypter encrypter,
    required IV iv,
    required bool asBase64Text,
  }) => workerManager.execute<Uint8List>(
    asBase64Text
        ? () async {
            final text = utf8.decode(encrypted.cast<int>());
            return utf8.encode(encrypter.decrypt64(text, iv: iv));
          }
        : () async => Uint8List.fromList(
            encrypter.decryptBytes(Encrypted(encrypted), iv: iv),
          ),
    priority: WorkPriority.highRegular,
  );

  // ---------------------------------------------------------------------
  // Conflicts
  // ---------------------------------------------------------------------

  /// For each local path, its modified time (ms) as of its last sync;
  /// stored in [stows.fileSyncLastSynced].
  static Map<String, int>? _lastSyncedCache;
  static Map<String, int> get _lastSynced =>
      _lastSyncedCache ??= _loadLastSynced();

  static Map<String, int> _loadLastSynced() {
    try {
      return (jsonDecode(stows.fileSyncLastSynced.value) as Map)
          .cast<String, int>();
    } catch (_) {
      return <String, int>{};
    }
  }

  static void _recordSynced(String relativePath, DateTime? lastModified) {
    if (lastModified != null) {
      _lastSynced[relativePath] = lastModified.millisecondsSinceEpoch;
    } else {
      _lastSynced.remove(relativePath);
    }
    stows.fileSyncLastSynced.value = jsonEncode(_lastSynced);
  }

  /// True when the local file has been changed since its last sync. A file
  /// this device has no sync record for counts as changed unless it's the
  /// same as [cloud].
  static bool _hasUnsyncedEdits(BadNotesSyncFile file, Uint8List cloud) {
    if (!file.localFile.existsSync()) return false;
    final syncedAt = _lastSynced[file.relativeLocalPath];
    // Never synced from here (the first sync on this device, or after
    // logging in again): edited here unless it's just what the cloud has.
    // Taken as not edited, a newer cloud copy replaced work done here.
    if (syncedAt == null) {
      return !listEquals(file.localFile.readAsBytesSync(), cloud);
    }
    final modifiedAt = file.localFile.lastModifiedSync().millisecondsSinceEpoch;
    return (modifiedAt - syncedAt).abs() > 1000;
  }

  /// When a cloud change is about to overwrite or delete a note that was
  /// also edited on this device, first saves this device's version next to
  /// it as "Name (conflict)", so neither side's work is lost.
  /// The last part of a note path, as shown on its card.
  static String _nameOf(String path) => path.substring(path.lastIndexOf('/') + 1);

  static Future<void> _keepConflictCopy(
    BadNotesSyncFile file,
    Uint8List cloud,
  ) async {
    final path = file.relativeLocalPath;
    final extension = [
      Editor.extension,
      Editor.extensionOldJson,
    ].firstWhereOrNull(path.endsWith);
    if (extension == null || !_hasUnsyncedEdits(file, cloud)) return;

    final stem = path.substring(0, path.length - extension.length);
    final copyPath = await FileManager.suffixFilePathToMakeItUnique(
      '$stem (this device)$extension',
    );
    log.info('Both devices edited $path, keeping ours as $copyPath');
    SyncStatus.conflicts.value = [
      ...SyncStatus.conflicts.value,
      (
        note: _nameOf(stem),
        copy: _nameOf(copyPath.substring(0, copyPath.length - extension.length)),
      ),
    ];

    // ponytail: the thumbnail and pictures are copied as they are at this
    // moment, so ones that already came down from the cloud are what the
    // copy gets. Copy them before downloading starts if that ever matters.
    final suffixes = [
      '',
      previewExtension,
      for (var i = 0; FileManager.doesFileExist('$path.$i'); i++) '.$i',
    ];
    for (final suffix in suffixes) {
      final original = FileManager.getFile('$path$suffix');
      if (!original.existsSync()) continue;
      await FileManager.writeFile(
        '$copyPath$suffix',
        await original.readAsBytes(),
        awaitWrite: true,
      );
    }
  }

  // ---------------------------------------------------------------------
  // The cloud store and the network
  // ---------------------------------------------------------------------

  static RemoteStore? _store;
  static String? _storeKey;

  /// The cloud store (Google Drive or OneDrive) of whoever is logged in,
  /// made again whenever the login, provider or user changes.
  static RemoteStore? get store {
    final key =
        '${stows.loggedIn} ${stows.syncProvider.value} ${stows.username.value}';
    if (key != _storeKey) {
      _storeKey = key;
      _store = RemoteStore.fromSavedDetails();
    }
    return _store;
  }

  /// [store], or an error saying what couldn't be done while logged out.
  static RemoteStore _loggedInStore(String action) {
    final store = BadNotesSyncInterface.store;
    if (store == null) {
      throw Exception('Tried to $action without being logged in');
    }
    return store;
  }

  /// False on mobile data when the user syncs on Wi-Fi only.
  static Future<bool> canSyncNow() async =>
      !stows.syncOnlyOnWifi.value || await isOnWifi();

  /// Whether thumbnails may sync right now.
  static Future<bool> canSyncPreviewsNow() async =>
      stows.syncPreviewsOnMobileData.value || await isOnWifi();

  /// On Wi-Fi or ethernet: connections that normally cost nothing. Platforms
  /// that can't tell count as yes.
  static Future<bool> isOnWifi() async {
    try {
      final kinds = await Connectivity().checkConnectivity();
      return kinds.contains(ConnectivityResult.wifi) ||
          kinds.contains(ConnectivityResult.ethernet);
    } catch (_) {
      return true;
    }
  }

  /// The files last listed in the cloud, kept so that
  /// [getSyncFileFromLocalFile] needn't ask about each file.
  ///
  /// Filled by [findRemoteFiles]; empty or out of date if that hasn't run
  /// lately.
  static var remoteFiles = <RemoteFile>{};

  /// Lists the cloud folder. A missing folder gets the encryption config
  /// uploaded again and then every note; errors are noted in [SyncStatus].
  static Future<Set<RemoteFile>> findRemoteFiles() async {
    final store = BadNotesSyncInterface.store;
    if (store == null) return {};

    try {
      final files = await store.list();
      stows.lastSyncedMs.value = DateTime.now().millisecondsSinceEpoch;
      // an upload that failed keeps its error until it goes through
      if (SyncStatus.failedUploads.value.isEmpty) SyncStatus.error.value = null;
      return files;
    } on RemoteNotFound catch (e, st) {
      log.info('findRemoteFiles: App folder is new, uploading config', e, st);
      await store
          .getConfig()
          .then((config) => store.generateConfig(config: config))
          .then((config) => store.setConfig(config));
      syncer.uploader.refresh();
      return {};
    } on SocketException catch (e, st) {
      log.warning('findRemoteFiles: Network error: $e', e, st);
      SyncStatus.error.value = e;
      return {};
    } catch (e, st) {
      log.severe('findRemoteFiles: Unknown error: $e', e, st);
      SyncStatus.error.value = e;
      if (kDebugMode) rethrow;
      return {};
    }
  }

  // ---------------------------------------------------------------------
  // Encrypted file names
  // ---------------------------------------------------------------------

  /// Local path → encrypted name, e.g. `/folder/note.sbn2` → a hex string.
  /// Filled by [encryptPath] and [decryptPath] only.
  static final _encryptMap = <String, String>{};

  /// Encrypted name → local path; the mirror of [_encryptMap].
  static final _decryptMap = <String, String>{};

  static void _remember(String path, String encryptedName) {
    _encryptMap[path] = encryptedName;
    _decryptMap[encryptedName] = path;
  }

  /// The cloud file name (without [encExtension]) for local [path].
  static Future<String> encryptPath(RemoteStore? store, String path) async {
    final known = _encryptMap[path];
    if (known != null) return known;

    if (store == null) {
      throw Exception('Tried to encrypt path without being logged in');
    }
    final encrypter = store.encrypter;
    final iv = _savedIv();
    final encryptedName = await workerManager.execute(
      () => encrypter.encrypt(path, iv: iv).base16,
      priority: WorkPriority.veryHigh,
    );

    _remember(path, encryptedName);
    return encryptedName;
  }

  /// The local path for cloud file [path], or null for files that aren't
  /// synced. The encryption config maps to its own plain name.
  static Future<String?> decryptPath(RemoteStore? store, String path) async {
    if (_ignoredFiles.any(path.endsWith)) return null;

    if (path.endsWith(RemoteStore.configPath) && !path.endsWith(encExtension)) {
      return '/${RemoteStore.configFileName}';
    }
    if (!path.endsWith(encExtension)) {
      log.info('remote file not in recognised encrypted format: $path');
      return null;
    }

    final encryptedName = path.substring(
      path.lastIndexOf('/') + 1,
      path.length - encExtension.length,
    );
    final known = _decryptMap[encryptedName];
    if (known != null) return known;

    if (store == null) {
      throw Exception('Tried to decrypt path without being logged in');
    }
    final encrypter = store.encrypter;
    final iv = _savedIv();
    var decrypted = await workerManager.execute(
      () => encrypter.decrypt16(encryptedName, iv: iv),
      priority: WorkPriority.veryHigh,
    );

    // some files were once imported as `null/...` instead of `/...`
    if (decrypted.startsWith('null/')) {
      decrypted = decrypted.substring('null'.length);
    }

    _remember(decrypted, encryptedName);
    return decrypted;
  }

  // ---------------------------------------------------------------------
  // Choosing between the two copies
  // ---------------------------------------------------------------------

  /// Decides whether the local or the cloud copy of [file] should win.
  ///
  /// Gives [onLocalFileNotFound] when there's no local copy, and
  /// [onEqualFiles] when both were modified within half a second of each
  /// other. A cloud copy that is missing, or older than the last "resync
  /// everything", loses; otherwise the newer copy wins.
  static Future<BestFile> getBestFile(
    BadNotesSyncFile file, {
    required BestFile onLocalFileNotFound,
    required BestFile onEqualFiles,
    bool preferCache = true,
  }) async {
    // either a new cloud file or one deleted here
    if (!file.localFile.existsSync()) return onLocalFileNotFound;

    file.remoteFile = await _getRemoteFileStatic(
      file.remotePath,
      preferCache: preferCache,
    );
    final remoteTime = file.remoteFile?.lastModified;
    if (remoteTime == null) return .local;
    if (remoteTime.isBefore(stows.fileSyncResyncEverythingDate.value)) {
      return .local;
    }

    final localTime = file.localFile.lastModifiedSync();
    if (remoteTime.difference(localTime).abs() <
        const Duration(milliseconds: 500)) {
      return onEqualFiles;
    }
    return remoteTime.isAfter(localTime) ? .remote : .local;
  }

  Future<RemoteFile?> getRemoteFile(
    String remotePath, {
    bool preferCache = true,
  }) => _getRemoteFileStatic(remotePath, preferCache: preferCache);

  /// Looks [remotePath] up in [remoteFiles] first (if [preferCache]), else
  /// asks the store and refreshes the cached entry.
  static Future<RemoteFile?> _getRemoteFileStatic(
    String remotePath, {
    bool preferCache = true,
  }) async {
    final cached = remoteFiles.firstWhereOrNull(
      (remoteFile) => remoteFile.path == remotePath,
    );
    if (preferCache && cached != null) return cached;

    final fresh = await _statRemoteFile(remotePath);
    if (fresh == null) return cached;
    remoteFiles
      ..remove(cached)
      ..add(fresh);
    return fresh;
  }

  static Future<RemoteFile?> _statRemoteFile(String remotePath) async {
    try {
      return await BadNotesSyncInterface.store?.stat(remotePath);
    } catch (e, st) {
      log.fine('Remote file not found for $remotePath: $e', e, st);
      return null;
    }
  }
}

/// A local file paired with where it lives in the cloud.
class BadNotesSyncFile extends AbstractSyncFile<File, RemoteFile> {
  /// The local path relative to the documents folder, starting with `/`.
  late final relativeLocalPath = localFile.path.substring(
    FileManager.documentsDirectory.length,
  );

  late String remotePath;

  /// [remotePath] defaults to [remoteFile]'s path; one of them is needed.
  new({required super.remoteFile, String? remotePath, required super.localFile})
    : assert(
        remotePath != null || remoteFile != null,
        'At least one of remotePath or remoteFile must be provided',
      ) {
    this.remotePath = remotePath ?? remoteFile!.path;
  }

  /// The sync file for the local file at [relativeFilePath].
  static Future<BadNotesSyncFile> relative(String relativeFilePath) =>
      const BadNotesSyncInterface().getSyncFileFromLocalFile(
        FileManager.getFile(relativeFilePath),
      );

  @override
  String toString() =>
      'BadNotesSyncFile(local: $relativeLocalPath, remote: $remotePath)';

  /// Two sync files are the same when their local files are.
  @override
  bool operator ==(Object other) =>
      other is BadNotesSyncFile && other.localFile.path == localFile.path;

  @override
  int get hashCode => localFile.path.hashCode;
}

extension BadNotesSyncerComponent on SyncerComponent {
  /// Queues the file at [relativeFilePath] (relative to the documents
  /// folder), unless logged out or the network rules say to wait. Returns
  /// whether it was queued.
  Future<bool> enqueueRel(String relativeFilePath) async {
    if (!stows.loggedIn) return false;
    // the free version uploads when the cloud button is pressed
    if (!Pro.autoSync) return false;
    if (!await BadNotesSyncInterface.canSyncNow()) return false;
    // a held-back thumbnail is picked up by uploader.refresh() on Wi-Fi
    final isPreview = relativeFilePath.endsWith(
      BadNotesSyncInterface.previewExtension,
    );
    if (isPreview && !await BadNotesSyncInterface.canSyncPreviewsNow()) {
      return false;
    }

    return enqueue(syncFile: await BadNotesSyncFile.relative(relativeFilePath));
  }
}

enum BestFile { local, remote }

/// One line about syncing, such as "Last synced 5 min ago · 3 files waiting
/// to sync".
String describeSyncStatus() {
  final lastSyncedMs = stows.lastSyncedMs.value;
  final lastSynced = lastSyncedMs == 0
      ? t.profile.notSyncedYet
      : t.profile.lastSynced(time: _howLongAgo(lastSyncedMs));

  final pending = syncer.uploader.numPending + syncer.downloader.numPending;
  return pending == 0
      ? lastSynced
      : '$lastSynced · ${t.profile.filesWaiting(n: pending)}';
}

String _howLongAgo(int ms) {
  final date = DateTime.fromMillisecondsSinceEpoch(ms);
  final ago = DateTime.now().difference(date);
  if (ago.inMinutes < 1) return t.profile.justNow;
  if (ago.inHours < 1) return t.profile.minutesAgo(n: ago.inMinutes);
  if (ago.inDays < 1) return t.profile.hoursAgo(n: ago.inHours);
  return '${date.day}/${date.month}/${date.year}';
}

/// The sync state shown on the home screen: notes not yet in the cloud and
/// the most recent problem.
abstract final class SyncStatus {
  /// Local paths whose upload failed and will be retried. The uploader drops
  /// them from its queue until then.
  static final failedUploads = ValueNotifier<Set<String>>(const {});

  /// The most recent error, cleared once syncing works again.
  static final error = ValueNotifier<Object?>(null);

  /// Notes changed on this device and in the cloud at once this session:
  /// the cloud version took the name, this device's was kept as [copy].
  static final conflicts =
      ValueNotifier<List<({String note, String copy})>>(const []);

  static void _uploadFailed(String path, Object error) {
    failedUploads.value = {...failedUploads.value, path};
    SyncStatus.error.value = error;
  }

  static void _uploaded(String path) {
    final failed = failedUploads.value;
    if (failed.contains(path)) failedUploads.value = {...failed}..remove(path);
    if (failedUploads.value.isEmpty) error.value = null;
  }

  /// Local paths still on their way to the cloud.
  static Iterable<String> get waiting sync* {
    for (final file in syncer.uploader.pending) {
      yield file.relativeLocalPath;
    }
    yield* failedUploads.value;
  }

  /// Whether anything of the note at [notePath] (given without extension) is
  /// still waiting to upload, or, with [folder], anything inside the folder
  /// at [notePath].
  static bool isUnsynced(String notePath, {bool folder = false}) {
    if (!stows.loggedIn) return false;
    // a note's own files share its name: the note, thumbnail, assets,
    // cover, recordings and so on
    final prefix = folder ? '$notePath/' : '$notePath.';
    return waiting.any((path) => path.startsWith(prefix));
  }
}
