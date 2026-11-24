import 'package:badnotes/components/home/note_tags.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tags: add, remove, rename, delete, carry on rename', () {
    var b = const TagBook()
        .add('/Physics', 'physics')
        .add('/Physics', 'exam')
        .add('/Maths', 'Exam') // same tag, other case
        .add('/Maths', ' ');
    expect(b.tags, ['physics', 'exam']);
    expect(b.tagsOf('/Maths'), ['exam']);
    expect(b.colors['physics'], TagBook.palette[0]);
    expect(b.colors['exam'], TagBook.palette[1]);
    expect(identical(b.add('/Physics', 'exam'), b), isTrue);

    expect(b.suggestions('/Maths'), ['physics']);
    expect(b.count('exam'), 2);

    b = b.remove('/Maths', 'exam');
    expect(b.notes.containsKey('/Maths'), isFalse);
    expect(b.tags, contains('exam')); // the tag stays

    // renaming into an existing tag merges them
    b = b.add('/Maths', 'test').renameTag('test', 'exam');
    expect(b.tags, ['physics', 'exam']);
    expect(b.tagsOf('/Maths'), ['exam']);
    b = b.renameTag('physics', 'phys');
    expect(b.tagsOf('/Physics'), ['phys', 'exam']);
    expect(b.colors['phys'], TagBook.palette[0]);

    b = b.moveNote('/Physics', '/College/Physics');
    expect(b.tagsOf('/Physics'), isEmpty);
    expect(b.tagsOf('/College/Physics'), ['phys', 'exam']);
    expect(identical(b.moveNote('/Nope', '/Other'), b), isTrue);

    b = b.deleteTag('exam');
    expect(b.tags, ['phys']);
    expect(b.notes.containsKey('/Maths'), isFalse);
    expect(b.forget('/College/Physics').notes, isEmpty);

    final again = TagBook.fromJson(b.toJson());
    expect(again.colors, b.colors);
    expect(again.notes, b.notes);
    expect(TagBook.fromJson('junk').tags, isEmpty);
  });
}
