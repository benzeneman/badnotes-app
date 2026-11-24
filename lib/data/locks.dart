import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/data/is_this_a_test.dart';
import 'package:badnotes/data/nextcloud/badnotes_syncer.dart';
import 'package:badnotes/pages/editor/editor.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:stow_plain/stow_plain.dart';

enum LockKind { note, folder }

/// A password lock on a notebook or a folder. The password itself is never
/// kept: only a salted PBKDF2-HMAC-SHA256 of it.
@immutable
class LockEntry {
  const new({
    required this.kind,
    required this.salt,
    required this.hash,
    required this.updatedAt,
    this.hint = '',
    this.iterations = defaultIterations,
    this.removedAt,
  });

  static const defaultIterations = 20000;

  final LockKind kind;

  /// Base64.
  final String salt, hash;
  final String hint;
  final int iterations;

  /// Milliseconds since epoch.
  final int updatedAt;

  /// Set when the lock was taken off: kept so a sync doesn't bring it back.
  final int? removedAt;

  bool get removed => removedAt != null;

  /// When this entry last changed; the newest wins in [LockBook.merge].
  int get stamp => removedAt ?? updatedAt;

  LockEntry removedNow(int now) => LockEntry(
    kind: kind,
    salt: '',
    hash: '',
    updatedAt: updatedAt,
    removedAt: now,
  );

  LockEntry movedNow(int now) => LockEntry(
    kind: kind,
    salt: salt,
    hash: hash,
    hint: hint,
    iterations: iterations,
    updatedAt: now,
  );

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    if (!removed) ...{
      'salt': salt,
      'hash': hash,
      'hint': hint,
      'it': iterations,
    },
    'updatedAt': updatedAt,
    'removedAt': ?removedAt,
  };

  static LockEntry? fromJson(Object? json) {
    if (json is! Map) return null;
    final kind = LockKind.values.asNameMap()[json['kind']];
    final updatedAt = json['updatedAt'];
    if (kind == null || updatedAt is! int) return null;
    final removedAt = json['removedAt'];
    return LockEntry(
      kind: kind,
      salt: json['salt'] is String ? json['salt'] as String : '',
      hash: json['hash'] is String ? json['hash'] as String : '',
      hint: json['hint'] is String ? json['hint'] as String : '',
      iterations: json['it'] is int ? json['it'] as int : defaultIterations,
      updatedAt: updatedAt,
      removedAt: removedAt is int ? removedAt : null,
    );
  }

  /// PBKDF2-HMAC-SHA256 (RFC 8018), [length] ≤ 32 bytes.
  static List<int> pbkdf2(
    List<int> password,
    List<int> salt,
    int iterations, [
    int length = 32,
  ]) {
    final hmac = Hmac(sha256, password);
    var u = hmac.convert([...salt, 0, 0, 0, 1]).bytes;
    final out = List<int>.of(u);
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < out.length; j++) {
        out[j] ^= u[j];
      }
    }
    return out.sublist(0, length);
  }

  /// A new lock with [password]; hashed off the main thread.
  static Future<LockEntry> create(
    LockKind kind,
    String password, {
    String hint = '',
    int iterations = defaultIterations,
    int? now,
  }) async {
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final hash = await Isolate.run(
      () => pbkdf2(utf8.encode(password), salt, iterations),
    );
    return LockEntry(
      kind: kind,
      salt: base64Encode(salt),
      hash: base64Encode(hash),
      hint: hint,
      iterations: iterations,
      updatedAt: now ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Whether [password] opens this lock; hashed off the main thread.
  Future<bool> verify(String password) async {
    if (removed) return false;
    final salt = base64Decode(this.salt), iterations = this.iterations;
    final hash = await Isolate.run(
      () => pbkdf2(utf8.encode(password), salt, iterations),
    );
    final expected = base64Decode(this.hash);
    if (hash.length != expected.length) return false;
    var diff = 0;
    for (var i = 0; i < hash.length; i++) {
      diff |= hash[i] ^ expected[i];
    }
    return diff == 0;
  }
}

/// Every lock by path (a notebook without its extension, e.g. `/Uni/Maths`,
/// or a folder, e.g. `/Uni`), removed ones included. Pure: no files.
@immutable
class LockBook {
  const new([this.entries = const {}]);

  final Map<String, LockEntry> entries;

  /// The live lock on exactly [path].
  LockEntry? lockOf(String path) {
    final entry = entries[path];
    return entry == null || entry.removed ? null : entry;
  }

  bool isLocked(String path) => lockOf(path) != null;

  /// [path]'s folders, nearest first, without `/`.
  static Iterable<String> ancestors(String path) sync* {
    var dir = p.posix.dirname(path);
    while (dir != '/' && dir != '.' && dir.isNotEmpty) {
      yield dir;
      dir = p.posix.dirname(dir);
    }
  }

  /// The nearest locked folder around [path].
  String? lockingAncestor(String path) {
    for (final dir in ancestors(path)) {
      if (isLocked(dir)) return dir;
    }
    return null;
  }

  /// The outermost lock on [path] or its folders that isn't [unlocked]:
  /// what has to be opened first. Null when nothing is in the way.
  String? lockToOpen(String path, Set<String> unlocked) {
    String? found;
    for (final candidate in [path, ...ancestors(path)]) {
      if (isLocked(candidate) && !unlocked.contains(candidate)) {
        found = candidate;
      }
    }
    return found;
  }

  bool needsUnlock(String path, Set<String> unlocked) =>
      lockToOpen(path, unlocked) != null;

  LockBook withEntry(String path, LockEntry entry) =>
      LockBook({...entries, path: entry});

  /// Locks on [from] and inside it follow it to [to]; the old paths keep a
  /// removed entry so another device's sync doesn't put them back.
  LockBook moved(String from, String to, int now) {
    if (from == to) return this;
    final next = {...entries};
    var changed = false;
    for (final MapEntry(:key, :value) in entries.entries) {
      if (value.removed) continue;
      if (key != from && !key.startsWith('$from/')) continue;
      next[key] = value.removedNow(now);
      next[to + key.substring(from.length)] = value.movedNow(now);
      changed = true;
    }
    return changed ? LockBook(next) : this;
  }

  /// Takes off the locks on [path] and, with [inside], everything in it.
  LockBook removed(String path, int now, {bool inside = false}) {
    final next = {...entries};
    var changed = false;
    for (final MapEntry(:key, :value) in entries.entries) {
      if (value.removed) continue;
      if (key != path && !(inside && key.startsWith('$path/'))) continue;
      next[key] = value.removedNow(now);
      changed = true;
    }
    return changed ? LockBook(next) : this;
  }

  /// Per path, the newest change wins (a removal included).
  // ponytail: removed entries are kept forever; they're tiny. Prune old ones
  // if the file ever gets big.
  static LockBook merge(LockBook a, LockBook b) {
    final out = {...a.entries};
    for (final MapEntry(:key, :value) in b.entries.entries) {
      final mine = out[key];
      if (mine == null || value.stamp > mine.stamp) out[key] = value;
    }
    return LockBook(out);
  }

  /// Whether both have the same change for every path.
  bool sameAs(LockBook other) =>
      entries.length == other.entries.length &&
      entries.entries.every(
        (e) => other.entries[e.key]?.stamp == e.value.stamp,
      );

  Map<String, dynamic> toJson() => {
    for (final MapEntry(:key, :value) in entries.entries) key: value.toJson(),
  };

  static LockBook fromJson(Object? json) => LockBook({
    if (json is Map)
      for (final MapEntry(:key, :value) in json.entries)
        if (key is String) key: ?LockEntry.fromJson(value),
  });
}

/// The locks, kept in `/.locks.json` beside the notes so they sync, and
/// which of them are open in this session.
abstract final class NoteLocks {
  static const _file = '/.locks.json';

  /// How long the app can be away before everything locks again.
  static const relockAfter = Duration(seconds: 60);

  static final book = ValueNotifier(const LockBook());

  /// Opened since the app started (memory only).
  static final unlocked = ValueNotifier<Set<String>>(const {});

  /// Both of the above, for widgets that show locks.
  static final changes = Listenable.merge([book, unlocked]);

  /// Paths this device opens with a fingerprint too (not synced).
  static final biometric = PlainStow<List<String>>(
    'lockBiometricPaths',
    <String>[],
    volatile: isThisATest,
  );

  static Future<void>? _loading;
  static StreamSubscription<FileOperation>? _changes;
  static Future<void> _saving = Future.value();
  static AppLifecycleListener? _lifecycle;
  static DateTime? _awaySince;

  /// Reads the locks and starts relocking when the app is left. Once.
  static void init() {
    _lifecycle ??= AppLifecycleListener(
      onHide: () => _awaySince ??= DateTime.now(),
      onShow: () {
        final since = _awaySince;
        _awaySince = null;
        if (since != null && DateTime.now().difference(since) >= relockAfter) {
          relockAll();
        }
      },
      onDetach: relockAll,
    );
    unawaited(load());
  }

  static Future<void> load() => _loading ??= _read();

  static Future<void> _read() async {
    // another device changed the locks
    _changes ??= FileManager.fileWriteStream.stream.listen((event) {
      if (event.filePath == _file) unawaited(_read());
    });
    if (!FileManager.doesFileExist(_file)) return;
    final bytes = await FileManager.readFile(_file, retries: 0);
    if (bytes == null) return;
    final LockBook disk;
    try {
      disk = LockBook.fromJson(jsonDecode(utf8.decode(bytes)));
    } on FormatException {
      return; // a broken file: keep what we have
    }
    final merged = LockBook.merge(book.value, disk);
    book.value = merged;
    // the file lacks changes made here: put them back
    if (!merged.sameAs(disk)) await _save(merged);
  }

  static Future<void> _save(LockBook b) {
    final bytes = utf8.encode(jsonEncode(b.toJson()));
    return _saving = _saving.then((_) async {
      await FileManager.writeFile(_file, bytes, quietly: true, awaitWrite: true);
      await syncer.uploader.enqueueRel(_file);
    });
  }

  static Future<void> _update(LockBook Function(LockBook) change) async {
    await load();
    final before = book.value;
    final after = change(before);
    if (identical(after, before)) return;
    book.value = after;
    await _save(after);
  }

  static int get _now => DateTime.now().millisecondsSinceEpoch;

  static bool isLocked(String path) => book.value.isLocked(path);
  static String? lockingAncestor(String path) =>
      book.value.lockingAncestor(path);
  static bool needsUnlock(String path) =>
      book.value.needsUnlock(path, unlocked.value);
  static String? lockToOpen(String path) =>
      book.value.lockToOpen(path, unlocked.value);

  /// Whether [path] has a lock, or is in a locked folder, open or not:
  /// such notes stay out of search and previews.
  static bool isProtected(String path) =>
      isLocked(path) || lockingAncestor(path) != null;

  static void unlock(String path) =>
      unlocked.value = {...unlocked.value, path};

  static void relockAll() {
    if (unlocked.value.isNotEmpty) unlocked.value = const {};
  }

  static void relock(String path) =>
      unlocked.value = {...unlocked.value}..remove(path);

  /// Locks [path] with [password] (or changes its password).
  static Future<void> setLock(
    String path,
    LockKind kind,
    String password, {
    String hint = '',
  }) async {
    final entry = await LockEntry.create(kind, password, hint: hint);
    await _update((b) => b.withEntry(path, entry));
    // the page as it was left, shown while a note opens: not any more
    if (kind == .note) {
      final picture = FileManager.getFile('$path.open.png');
      if (picture.existsSync()) await picture.delete();
    }
  }

  static Future<void> removeLock(String path) async {
    await _update((b) => b.removed(path, _now));
    relock(path);
    setBiometric(path, false);
  }

  static Future<bool> verify(String path, String password) async =>
      await book.value.lockOf(path)?.verify(password) ?? false;

  static bool usesBiometric(String path) =>
      biometric.value.contains(path);

  static void setBiometric(String path, bool on) {
    final list = biometric.value;
    if (list.contains(path) == on) return;
    biometric.value = on
        ? [...list, path]
        : [
            for (final x in list)
              if (x != path) x,
          ];
  }

  static String? _noteKey(String path) {
    for (final ext in [Editor.extension, Editor.extensionOldJson]) {
      if (path.endsWith(ext)) return path.substring(0, path.length - ext.length);
    }
    return null;
  }

  /// For [FileManager]'s rename hook: a note file moved (or to the trash).
  static void renameFile(String from, String to) {
    final a = _noteKey(from), b = _noteKey(to);
    if (a == null || b == null) return;
    move(a, b);
  }

  /// For [FileManager]'s delete hook: a note file is gone for good.
  static void forgetFile(String path) {
    final key = _noteKey(path);
    if (key == null || !isLocked(key)) return;
    // saving a note also "deletes" its old `.sbn` twin: the note is still here
    for (final ext in [Editor.extension, Editor.extensionOldJson]) {
      if (FileManager.doesFileExist('$key$ext')) return;
    }
    unawaited(_update((b) => b.removed(key, _now)));
  }

  /// A notebook or folder moved: its locks (and those inside) follow.
  static void move(String from, String to) {
    final b = book.value;
    if (!b.entries.keys.any((k) => k == from || k.startsWith('$from/'))) {
      return;
    }
    unawaited(_update((b) => b.moved(from, to, _now)));
    if (unlocked.value.contains(from)) {
      unlocked.value = {...unlocked.value}
        ..remove(from)
        ..add(to);
    }
    if (usesBiometric(from)) {
      setBiometric(from, false);
      setBiometric(to, true);
    }
  }

  /// A folder was deleted: its locks and those inside go.
  static void forgetFolder(String path) {
    if (!book.value.entries.keys.any((k) => k == path || k.startsWith('$path/'))) {
      return;
    }
    unawaited(_update((b) => b.removed(path, _now, inside: true)));
  }
}
