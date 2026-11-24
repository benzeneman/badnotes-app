import 'dart:convert';

import 'package:badnotes/data/locks.dart';
import 'package:flutter_test/flutter_test.dart';

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

LockEntry _entry(int updatedAt, {int? removedAt, LockKind kind = .note}) =>
    LockEntry(
      kind: kind,
      salt: 'c2FsdA==',
      hash: 'aGFzaA==',
      updatedAt: updatedAt,
      removedAt: removedAt,
    );

void main() {
  test('pbkdf2 matches RFC 7914', () {
    final out = LockEntry.pbkdf2(utf8.encode('passwd'), utf8.encode('salt'), 1);
    expect(
      _hex(out),
      '55ac046e56e3089fec1691c22544b605f94185216dde0465e68b9d57c20dacbc',
    );
  });

  test('create and verify', () async {
    final entry = await LockEntry.create(.note, 'secret', iterations: 50);
    expect(await entry.verify('secret'), isTrue);
    expect(await entry.verify('Secret'), isFalse);
    final back = LockEntry.fromJson(jsonDecode(jsonEncode(entry.toJson())))!;
    expect(await back.verify('secret'), isTrue);
  });

  test('merge: newest wins, removals stick', () {
    final a = LockBook({
      '/a': _entry(10),
      '/b': _entry(10, removedAt: 30),
      '/c': _entry(50),
    });
    final b = LockBook({
      '/a': _entry(20),
      '/b': _entry(25),
      '/d': _entry(5),
    });
    final m = LockBook.merge(a, b);
    expect(m.entries['/a']!.updatedAt, 20);
    expect(m.isLocked('/b'), isFalse); // removed at 30, newer than 25
    expect(m.isLocked('/c'), isTrue);
    expect(m.isLocked('/d'), isTrue);
    expect(LockBook.merge(b, a).sameAs(m), isTrue);
  });

  test('ancestors, unlocking and moving', () {
    final book = LockBook({
      '/Uni': _entry(1, kind: .folder),
      '/Uni/Maths/exam': _entry(1),
    });
    expect(book.lockingAncestor('/Uni/Maths/notes'), '/Uni');
    expect(book.lockingAncestor('/Other/x'), isNull);
    expect(book.needsUnlock('/Uni/Maths/notes', {}), isTrue);
    expect(book.needsUnlock('/Uni/Maths/notes', {'/Uni'}), isFalse);
    // its own lock still asks inside an open folder
    expect(book.lockToOpen('/Uni/Maths/exam', {}), '/Uni');
    expect(book.lockToOpen('/Uni/Maths/exam', {'/Uni'}), '/Uni/Maths/exam');

    final moved = book.moved('/Uni', '/School', 99);
    expect(moved.isLocked('/School'), isTrue);
    expect(moved.isLocked('/School/Maths/exam'), isTrue);
    expect(moved.isLocked('/Uni'), isFalse);
    expect(moved.entries['/Uni']!.removed, isTrue);
  });
}
