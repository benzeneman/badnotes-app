import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:badnotes/components/canvas/_ink_cache.dart';
import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart'
    as mlkit;
import 'package:logging/logging.dart';
import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:badnotes/components/canvas/image/editor_image.dart';
import 'package:badnotes/data/editor/editor_core_info.dart';
import 'package:badnotes/data/editor/page.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/pages/editor/editor.dart';

/// A line of handwriting as it was read: the likeliest readings, best first,
/// and where it is on its page.
class OcrLine {
  const OcrLine(this.texts, this.rect);

  final List<String> texts;
  final Rect rect;

  Map<String, dynamic> toJson() => {
    't': texts,
    'r': [rect.left, rect.top, rect.right, rect.bottom],
  };

  /// Null too for a line read only as junk, see [dropJunkWords].
  static OcrLine? fromJson(Object? json) {
    if (json case {'t': final List t, 'r': [num l, num tp, num r, num b]}) {
      final texts = [
        for (final x in t)
          if (dropJunkWords('$x') case final words when words.isNotEmpty)
            words,
      ];
      if (texts.isEmpty) return null;
      return OcrLine(
        texts,
        Rect.fromLTRB(l.toDouble(), tp.toDouble(), r.toDouble(), b.toDouble()),
      );
    }
    return null;
  }
}

/// What's written on a page, for search: its handwriting line by line, its
/// typed text and the text of its PDF. [key] tells whether the page changed
/// since it was read.
class OcrPage {
  const OcrPage({
    required this.key,
    this.lines = const [],
    this.typed = '',
    this.pdf = '',
  });

  final String key;
  final List<OcrLine> lines;
  final String typed, pdf;

  /// The best reading of each line, one line each: what's shown.
  String get handwriting => [
    for (final line in lines)
      if (line.texts.isNotEmpty) line.texts.first,
  ].join('\n');

  /// The page's words as shown: its handwriting, typed text and PDF text.
  String get previewText => [
    handwriting,
    typed,
    pdf,
  ].where((t) => t.trim().isNotEmpty).join('\n');

  /// Every reading of every line too, to search: a word ML Kit wasn't sure
  /// of is still found by its second or third reading.
  String get searchText => [
    for (final line in lines) line.texts.join('  '),
    typed,
    pdf,
  ].where((t) => t.trim().isNotEmpty).join('\n');

  /// The handwritten lines with [query] in any reading.
  List<Rect> find(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return [
      for (final line in lines)
        if (line.texts.any((t) => matchesQuery(t, q))) line.rect,
    ];
  }

  Map<String, dynamic> toJson() => {
    'k': key,
    if (lines.isNotEmpty) 'h': [for (final l in lines) l.toJson()],
    if (typed.isNotEmpty) 'x': typed,
    if (pdf.isNotEmpty) 'p': pdf,
  };

  static OcrPage fromJson(Object? json) {
    if (json is! Map) return const OcrPage(key: '');
    return OcrPage(
      key: '${json['k'] ?? ''}',
      lines: [
        for (final l in (json['h'] as List?) ?? const []) ?OcrLine.fromJson(l),
      ],
      typed: '${json['x'] ?? ''}',
      pdf: '${json['p'] ?? ''}',
    );
  }
}

/// [text] without its words of one letter or none: what a zig-zag, a line
/// or a dot is read as. Real words are kept. Used on the saved index only,
/// not the lasso's reading, where "I" and "a" are words.
String dropJunkWords(String text) => text
    .split(RegExp(r'\s+'))
    .where((w) => _letter.allMatches(w).length > 1)
    .join(' ');

final _letter = RegExp(r'[\p{L}\p{M}\p{N}]', unicode: true);

/// Whether [text] has [query] in it, allowing for a misread letter: each
/// word of the query (4 letters or more) can be one letter off a word of
/// the text. [query] is lower case.
bool matchesQuery(String text, String query) {
  final lower = text.toLowerCase();
  if (lower.contains(query)) return true;
  final words = query.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
  final textWords = lower.split(RegExp(r'[^\p{L}\p{M}\p{N}]+', unicode: true));
  return words.every(
    (w) =>
        lower.contains(w) ||
        (w.length >= 4 &&
            textWords.any((t) => (t.length - w.length).abs() <= 1 && _oneOff(t, w))),
  );
}

/// Whether [a] and [b] differ by at most one letter added, dropped or
/// changed.
bool _oneOff(String a, String b) {
  if (a == b) return true;
  if (a.length < b.length) (a, b) = (b, a);
  if (a.length - b.length > 1) return false;
  var i = 0, j = 0, edits = 0;
  while (i < a.length && j < b.length) {
    if (a[i] == b[j]) {
      i++;
      j++;
      continue;
    }
    if (++edits > 1) return false;
    if (a.length == b.length) j++;
    i++;
  }
  return edits + (a.length - i) <= 1;
}

/// Handwriting -> text with Google ML Kit Digital Ink (on-device; the
/// language model is downloaded once, ~20 MB, then it works offline).
///
/// Notes are read in the background, one line at a time, and only the pages
/// that changed; it waits while the pen is down so writing never stutters.
abstract class HandwritingOcr {
  static final log = Logger('HandwritingOcr');

  /// What handwriting can be read as. To add one, add its BCP-47 code here
  /// (any that ML Kit Digital Ink has a model for).
  static const languages = {'en': 'English', 'hi': 'हिन्दी'};

  /// The languages the user writes in. Never empty.
  static List<String> get chosenLanguages {
    final chosen = stows.handwritingLanguages.value
        .split(',')
        .where(languages.containsKey)
        .toList();
    return chosen.isEmpty ? const ['en'] : chosen;
  }

  static final _recognizers = <String, mlkit.DigitalInkRecognizer>{};

  /// What's happening with the language models, for search to show, or
  /// null when they're there.
  static final modelStatus = ValueNotifier<String?>(null);

  static Future<bool> ensureModel(String language) async {
    final manager = mlkit.DigitalInkRecognizerModelManager();
    if (await manager.isModelDownloaded(language)) return true;
    final name = languages[language] ?? language;
    modelStatus.value = 'Downloading the $name handwriting model…';
    // on mobile data too: ML Kit waited for Wi-Fi by default, so on data
    // nothing was ever read
    final ok = await manager.downloadModel(language, isWifiRequired: false);
    modelStatus.value = ok
        ? null
        : 'The $name handwriting model could not be downloaded. '
              'Connect to the internet once.';
    return ok;
  }

  /// Whether [s] is likely writing: a pen's or pencil's, not a shape,
  /// highlighter or tape. Size says nothing: a big cursive word in one
  /// stroke was taken for a drawing and never read.
  static bool isWriting(Stroke s) =>
      s.points.length > 1 &&
      switch (s.toolId) {
        .fountainPen ||
        .ballpointPen ||
        .brushPen ||
        .calligraphyPen ||
        .pencil => true,
        _ => false,
      };

  /// One recognition at a time, app wide: the indexer and the lasso share
  /// the recognizers.
  static Future<void> _busy = Future.value();

  static Future<T> _serial<T>(Future<T> Function() work) {
    final result = _busy.then((_) => work());
    _busy = result.then((_) {}, onError: (_) {});
    return result;
  }

  /// Reads [strokes] in every chosen language, the likeliest reading first.
  /// ML Kit can't detect the language by itself. Its scores come from different
  /// models so they only suggest an order: the user can pick another reading.
  /// Throws only if no language could be read, e.g. offline the first time.
  static Future<Map<String, String>> recognize(List<Stroke> strokes) async {
    final readings = <(String, String, double)>[];
    Object? failure;
    final lines = groupIntoLines(strokes.where(isWriting).toList());
    for (final language in chosenLanguages) {
      try {
        final read = await _readLines(lines, language);
        readings.add((
          language,
          [for (final l in read) ?l.$1.firstOrNull].join('\n'),
          read.fold(0.0, (sum, l) => sum + l.$2),
        ));
      } catch (e) {
        log.warning('Could not read handwriting as $language', e);
        failure = e;
      }
    }
    if (readings.isEmpty && failure != null) throw failure;
    readings.sort((a, b) => a.$3.compareTo(b.$3));
    return {for (final (language, text, _) in readings) language: text};
  }

  /// Each of [lines] read in [language]: up to three readings, best first,
  /// and how unlikely the best is (lower is likelier). The line before is
  /// given as context, which ML Kit reads words better with.
  static Future<List<(List<String>, double)>> _readLines(
    List<List<Stroke>> lines,
    String language, {
    double width = 0,
  }) async {
    if (lines.isEmpty) return const [];
    if (!await ensureModel(language)) {
      throw Exception('Handwriting model could not be downloaded');
    }
    final recognizer = _recognizers[language] ??= mlkit.DigitalInkRecognizer(
      languageCode: language,
    );
    final out = <(List<String>, double)>[];
    var before = '';
    for (final line in lines) {
      // never while the pen is down: writing comes first
      while (InkCache.penDown) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
      }
      final box = _boundsOf(line);
      final ink = mlkit.Ink();
      var t = 0;
      ink.strokes = [
        for (final s in line)
          mlkit.Stroke()
            ..points = [
              // ML Kit wants increasing timestamps; real ones aren't stored
              for (final p in s.points)
                mlkit.StrokePoint(x: p.x, y: p.y, t: t += 10),
            ],
      ];
      final candidates = await _serial(
        () => recognizer.recognize(
          ink,
          context: mlkit.DigitalInkRecognitionContext(
            preContext: before.length > 20
                ? before.substring(before.length - 20)
                : before,
            writingArea: mlkit.WritingArea(
              width: max(width, box.width),
              height: max(box.height, 1),
            ),
          ),
        ),
      );
      // a stray dot or dash read as "\" or "_" is no word: left out, and
      // readings that differ only in capitals are kept once
      final seen = <String>{};
      final texts = [
        for (final c in candidates.take(3))
          if (_hasWord.hasMatch(c.text) && seen.add(c.text.toLowerCase()))
            c.text,
      ];
      // one entry for every line, empty or not, so they match up by order
      out.add((texts, candidates.firstOrNull?.score ?? 0.0));
      if (texts.isNotEmpty) before = '$before ${texts.first}';
    }
    return out;
  }

  static final _hasWord = RegExp(r'[\p{L}\p{N}]', unicode: true);

  static Rect _boundsOf(List<Stroke> strokes) =>
      strokes.map((s) => s.bounds).reduce((a, b) => a.expandToInclude(b));

  /// Groups strokes into lines of writing by vertical overlap,
  /// each line sorted left to right.
  static List<List<Stroke>> groupIntoLines(List<Stroke> strokes) {
    Rect bounds(Stroke s) {
      var minX = double.infinity, minY = double.infinity;
      var maxX = -double.infinity, maxY = -double.infinity;
      for (final p in s.points) {
        minX = min(minX, p.x);
        maxX = max(maxX, p.x);
        minY = min(minY, p.y);
        maxY = max(maxY, p.y);
      }
      return Rect.fromLTRB(minX, minY, maxX, maxY);
    }

    final items = [for (final s in strokes) (s, bounds(s))]
      ..sort((a, b) => a.$2.center.dy.compareTo(b.$2.center.dy));

    final lines = <(List<(Stroke, Rect)>, double top, double bottom)>[];
    for (final item in items) {
      final r = item.$2;
      final i = lines.indexWhere((l) {
        final overlap = min(l.$3, r.bottom) - max(l.$2, r.top);
        return overlap > 0.5 * min(l.$3 - l.$2, r.height).clamp(1, 1e9);
      });
      if (i == -1) {
        lines.add(([item], r.top, r.bottom));
      } else {
        final l = lines[i];
        lines[i] = ([...l.$1, item], min(l.$2, r.top), max(l.$3, r.bottom));
      }
    }
    lines.sort((a, b) => a.$2.compareTo(b.$2));
    return [
      for (final l in lines)
        [
          for (final it in l.$1
            ..sort((a, b) => a.$2.left.compareTo(b.$2.left)))
            it.$1,
        ],
    ];
  }

  static String _indexPath(String notePath) => '$notePath.ocr.json';

  /// The note's pages as they were last read, or none.
  static List<OcrPage> readPages(String notePath) {
    final f = FileManager.getFile(_indexPath(notePath));
    if (!f.existsSync()) return const [];
    return parseIndex(f.readAsStringSync());
  }

  static List<OcrPage> parseIndex(String json) {
    try {
      return [
        for (final p in (jsonDecode(json) as Map)['pages'] as List)
          OcrPage.fromJson(p),
      ];
    } catch (_) {
      return const [];
    }
  }

  /// A page's fingerprint: its writing and the languages it's read in.
  /// Changes when a stroke is added, removed or moved.
  static String _keyOf(EditorPage page) {
    var points = 0, sum = 0.0;
    var count = 0;
    for (final s in page.strokes) {
      if (!isWriting(s)) continue;
      count++;
      points += s.points.length;
      final first = s.points.first;
      sum += first.x * 3 + first.y * 7 + s.points.last.x;
    }
    return '${chosenLanguages.join(',')}:$count:$points:${sum.round()}';
  }

  /// Notes being read now, so the same one isn't read twice at once.
  static final _indexing = <String>{};

  /// Reads the note's pages that changed since it was last read, and saves
  /// what's written on them. Typed text is always taken afresh.
  static Future<void> indexNote(String notePath, List<EditorPage> pages) async {
    if (!_indexing.add(notePath)) return;
    try {
      final old = readPages(notePath);
      // read now: a closing note's pages are let go of while this runs
      final typedTexts = [
        for (final page in pages)
          page.quill.controller.document.toPlainText().trim(),
      ];
      final keys = [for (final page in pages) _keyOf(page)];
      final writing = [
        for (final page in pages) page.strokes.where(isWriting).toList(),
      ];
      final out = <OcrPage>[];
      for (final (i, page) in pages.indexed) {
        final key = keys[i];
        final before = i < old.length ? old[i] : null;
        final typed = typedTexts[i];
        if (before != null && before.key == key) {
          out.add(OcrPage(key: key, lines: before.lines, typed: typed, pdf: before.pdf));
          continue;
        }
        final lines = groupIntoLines(writing[i]);
        final read = <OcrLine>[];
        var readAny = false;
        for (final language in chosenLanguages) {
          // one language's model missing (not downloaded yet) doesn't stop
          // the others
          final List<(List<String>, double)> readings;
          try {
            readings = await _readLines(lines, language, width: page.size.width);
          } catch (e) {
            log.warning('Could not read $notePath as $language', e);
            continue;
          }
          readAny = true;
          for (final (j, (texts, _)) in readings.indexed) {
            if (texts.isEmpty) continue;
            final rect = _boundsOf(lines[j]);
            final same = read.indexWhere((l) => l.rect == rect);
            if (same >= 0) {
              read[same] = OcrLine([...read[same].texts, ...texts], rect);
            } else {
              read.add(OcrLine(texts, rect));
            }
          }
        }
        out.add(OcrPage(
          // not read (no model yet): no key, so it's read again next time
          key: readAny || lines.isEmpty ? key : '',
          lines: read,
          typed: typed,
          pdf: before?.pdf ?? await _pdfText(page),
        ));
      }
      // kept on this device only: it's made again from the note anywhere
      await FileManager.getFile(_indexPath(notePath)).writeAsString(
        jsonEncode({'v': 1, 'pages': [for (final p in out) p.toJson()]}),
      );
      written.value++;
    } catch (e) {
      log.warning('Could not index $notePath', e);
    } finally {
      _indexing.remove(notePath);
    }
  }

  static Future<String> _pdfText(EditorPage page) async {
    final texts = <String>[];
    for (final pdf in [?page.backgroundImage, ...page.images]) {
      if (pdf is! PdfEditorImage) continue;
      try {
        texts.add(await pdf.loadText());
      } catch (_) {}
    }
    return texts.join(' ');
  }

  /// Ticks when a note's index is saved, so search reads it again.
  static final written = ValueNotifier(0);

  /// How many notes the background reading has gone through, of how many;
  /// null when it isn't running.
  static final progress = ValueNotifier<(int, int)?>(null);

  static var _backfilling = false;

  /// Reads every note whose writing hasn't been read since it last changed,
  /// one at a time, in the background. Stops quietly if the model can't be
  /// had (offline the first time): it tries again next time.
  static Future<void> backfill() async {
    if (_backfilling) return;
    _backfilling = true;
    try {
      for (final language in chosenLanguages) {
        if (!await ensureModel(language)) return;
      }
      final notes = [
        for (final f in await FileManager.getAllFiles())
          if (!f.contains('/.')) f,
      ];
      for (final (i, path) in notes.indexed) {
        progress.value = (i, notes.length);
        final note = FileManager.getFile('$path${Editor.extension}');
        final index = FileManager.getFile(_indexPath(path));
        if (!note.existsSync()) continue;
        if (index.existsSync() &&
            !index.lastModifiedSync().isBefore(note.lastModifiedSync()) &&
            // pages that couldn't be read (no model then) have no key
            readPages(path).every((page) => page.key.isNotEmpty)) {
          continue;
        }
        try {
          final info = await EditorCoreInfo.loadFromFilePath(path);
          await indexNote(path, info.pages);
          info.dispose();
        } catch (e) {
          log.warning('Could not read $path for search', e);
        }
        // a breath between notes
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    } catch (e) {
      log.warning('Background handwriting reading stopped', e);
    } finally {
      progress.value = null;
      _backfilling = false;
    }
  }
}

/// Lets the user choose which languages they write in. Returns whether the
/// choice changed.
Future<bool> showHandwritingLanguages(BuildContext context) async {
  final before = HandwritingOcr.chosenLanguages.toSet();
  final chosen = before.toSet();
  final ok = await showAppleDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Handwriting languages'),
        content: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          spacing: 12,
          children: [
            Wrap(
              spacing: 8,
              children: [
                for (final MapEntry(key: code, value: name)
                    in HandwritingOcr.languages.entries)
                  FilterChip(
                    label: Text(name),
                    selected: chosen.contains(code),
                    onSelected: (on) => setDialogState(() {
                      if (on) {
                        chosen.add(code);
                      } else if (chosen.length > 1) {
                        chosen.remove(code);
                      }
                    }),
                  ),
              ],
            ),
            Text(
              'Each language downloads once, about 20 MB. '
              'More languages make reading slower.',
              style: TextTheme.of(context).bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('OK'),
          ),
        ],
      ),
    ),
  );
  if (ok != true || chosen.length == before.length && chosen.containsAll(before)) {
    return false;
  }
  stows.handwritingLanguages.value = chosen.join(',');
  return true;
}

