import 'package:badnotes/components/editor/handwriting_ocr.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('search finds words with a misread letter', () {
    expect(matchesQuery('Photosynthesis needs light', 'light'), isTrue);
    expect(matchesQuery('the recive button', 'receive'), isTrue);
    expect(matchesQuery('chlorophyl makes it green', 'chlorophyll'), isTrue);
    expect(matchesQuery('mitochondria', 'mitochondria'), isTrue);
    // short words must be exact: "cat" is not "car"
    expect(matchesQuery('a car', 'cat'), isFalse);
    expect(matchesQuery('nothing here', 'energy'), isFalse);
    // every word of the query has to be there
    expect(matchesQuery('cell wall and membrane', 'wall membrane'), isTrue);
    expect(matchesQuery('cell wall', 'wall nucleus'), isFalse);
    expect(matchesQuery('पानी का चक्र', 'चक्र'), isTrue);
  });

  test('an index round-trips', () {
    const page = OcrPage(
      key: 'en:2:40:100',
      lines: [OcrLine(['hello', 'helo'], Rect.fromLTRB(1, 2, 3, 4))],
      typed: 'typed words',
    );
    final back = OcrPage.fromJson(page.toJson());
    expect(back.key, page.key);
    expect(back.lines.single.texts, ['hello', 'helo']);
    expect(back.lines.single.rect, const Rect.fromLTRB(1, 2, 3, 4));
    expect(back.find('helo'), [const Rect.fromLTRB(1, 2, 3, 4)]);
    expect(back.searchText, contains('typed words'));
    // shown once, the best reading; searched by every reading
    expect(back.handwriting, 'hello');
    expect(back.searchText, contains('helo'));
  });
}
