import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:badnotes/components/editor/handwriting_ocr.dart';
import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/theming/badnotes_tokens.dart';
import 'package:badnotes/components/ui/bn_controls.dart';
import 'package:badnotes/data/editor/page.dart';

/// One place a search term was found.
class const SearchHit({
  required final int pageIndex,
  required final String source,
  required final String snippet,
  required final int matchStart,
  required final int matchLength,

  /// On the page: the handwritten line it was read from. Null for typed and
  /// pdf text.
  final Rect? bounds,

  /// The matched words' part of [bounds].
  final Rect? word,
});

/// Finds every case-insensitive match of [query] in [pages], where each page
/// maps a source (like "PDF") to its text. Line breaks count as spaces, so a
/// phrase split over two lines of a pdf is still found.
List<SearchHit> findInPages(List<Map<String, String>> pages, String query) {
  const maxHits = 200, before = 30, after = 50;
  final q = query.trim().replaceAll(RegExp(r'\s+'), ' ');
  final hits = <SearchHit>[];
  if (q.isEmpty) return hits;
  final pattern = RegExp(RegExp.escape(q), caseSensitive: false);
  for (final (pageIndex, sources) in pages.indexed) {
    for (final MapEntry(key: source, value: text) in sources.entries) {
      final flat = text.replaceAll(RegExp(r'\s+'), ' ');
      for (final match in pattern.allMatches(flat)) {
        if (hits.length == maxHits) return hits;
        final start = max(0, match.start - before);
        hits.add(
          SearchHit(
            pageIndex: pageIndex,
            source: source,
            snippet: flat.substring(start, min(flat.length, match.end + after)),
            matchStart: match.start - start,
            matchLength: match.end - match.start,
          ),
        );
      }
    }
  }
  return hits;
}

/// Every match of [query] in [pages], page by page: each handwritten line
/// with it in any reading (with where the line is), then typed and pdf text.
List<SearchHit> searchNote(List<OcrPage> pages, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];
  final texts = findInPages([
    for (final page in pages) {'Text': page.typed, 'PDF': page.pdf},
  ], query);
  return [
    for (final (i, page) in pages.indexed) ...[
      for (final line in page.lines) ?_handwritingHit(i, line, q),
      for (final hit in texts)
        if (hit.pageIndex == i) hit,
    ],
  ];
}

SearchHit? _handwritingHit(int pageIndex, OcrLine line, String q) {
  for (final read in line.texts) {
    if (read.isEmpty || !matchesQuery(read, q)) continue;
    // matched with a misread letter: the whole line
    var at = read.toLowerCase().indexOf(q);
    final length = at < 0 ? read.length : q.length;
    if (at < 0) at = 0;
    // ponytail: the word's place guessed from its letters' share of the
    // line; per-word stroke bounds in the index if it's visibly off
    final r = line.rect;
    return SearchHit(
      pageIndex: pageIndex,
      source: 'Handwriting',
      snippet: read,
      matchStart: at,
      matchLength: length,
      bounds: r,
      word: Rect.fromLTRB(
        r.left + r.width * at / read.length,
        r.top,
        r.left + r.width * (at + length) / read.length,
        r.bottom,
      ),
    );
  }
  return null;
}

/// Right-hand panel that searches the open note's typed text, handwriting and
/// pdf text, and goes to its results.
class NoteSearchPanel extends StatefulWidget {
  const new({
    super.key,
    required this.texts,
    required this.pages,
    required this.showHit,
    required this.chooseLanguages,
  });

  /// Each page's text. Can give newer text more than once.
  final Stream<List<OcrPage>> Function() texts;

  /// The note's pages, to show handwriting results' ink.
  final List<EditorPage> pages;

  /// Goes to a result, and marks [query] on its page where it can.
  final void Function(SearchHit hit, String query) showHit;

  /// Lets the user change the handwriting languages. Then the texts are read
  /// again.
  final Future<void> Function() chooseLanguages;

  @override
  State<NoteSearchPanel> createState() => _NoteSearchPanelState();
}

class _NoteSearchPanelState extends State<NoteSearchPanel> {
  late var _texts = widget.texts();
  var _query = '';

  /// The source shown, or null for all.
  String? _kind;
  var _selected = 0;

  static const _chips = {
    'Handwriting': 'Handwriting',
    'Text': 'Typed',
    'PDF': 'PDF',
  };

  void _go(List<SearchHit> hits, int i, {bool close = false}) {
    // Dart's % never gives a negative: up from the first goes to the last
    setState(() => _selected = i % hits.length);
    // on a phone the panel covers the page
    if (close && MediaQuery.sizeOf(context).width < 700) Navigator.pop(context);
    widget.showHit(hits[_selected], _query);
  }

  Future<void> _chooseLanguages() async {
    await widget.chooseLanguages();
    if (mounted) setState(() => _texts = widget.texts());
  }

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Drawer(
      width: 340,
      backgroundColor: colors.surface,
      child: SafeArea(
        child: StreamBuilder(
          stream: _texts,
          builder: (context, snapshot) {
            final all = searchNote(snapshot.data ?? const [], _query);
            final counts = <String, int>{};
            for (final hit in all) {
              counts[hit.source] = (counts[hit.source] ?? 0) + 1;
            }
            final hits = [
              for (final hit in all)
                if (_kind == null || hit.source == _kind) hit,
            ];
            final selected = min(_selected, max(hits.length - 1, 0));
            final pageCount = {for (final hit in hits) hit.pageIndex}.length;
            final loading = snapshot.connectionState != ConnectionState.done;
            return Column(
              crossAxisAlignment: .stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 4, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoSearchTextField(
                          autofocus: true,
                          placeholder: 'Search this note and its PDF',
                          onChanged: (query) => setState(() {
                            _query = query;
                            _kind = null;
                            _selected = 0;
                          }),
                        ),
                      ),
                      Builder(
                        builder: (context) => IconButton(
                          tooltip: 'More',
                          icon: const Icon(Icons.more_horiz),
                          onPressed: () => showAppleMenu(
                            context,
                            anchor: rectOf(context),
                            entries: [
                              AppleMenuItem(
                                'Handwriting languages',
                                icon: Icons.translate,
                                onTap: _chooseLanguages,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (loading) const LinearProgressIndicator(minHeight: 2),
                if (all.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        BnChip(
                          label: 'All ${all.length}',
                          selected: _kind == null,
                          onTap: () => setState(() {
                            _kind = null;
                            _selected = 0;
                          }),
                        ),
                        for (final MapEntry(key: source, value: label)
                            in _chips.entries)
                          if (counts[source] case final n?)
                            BnChip(
                              label: '$label $n',
                              selected: _kind == source,
                              onTap: () => setState(() {
                                _kind = source;
                                _selected = 0;
                              }),
                            ),
                      ],
                    ),
                  ),
                if (hits.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                    child: Text(
                      '${hits.length} result${hits.length == 1 ? '' : 's'} · '
                      '$pageCount page${pageCount == 1 ? '' : 's'}',
                      style: BnType.caption.copyWith(color: colors.muted),
                    ),
                  ),
                Expanded(
                  child: hits.isEmpty
                      ? Center(
                          child: Text(
                            _query.trim().isEmpty
                                ? 'Type a word to search'
                                : loading
                                ? 'Searching…'
                                : 'No results',
                            style: BnType.caption.copyWith(color: colors.muted),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          children: [
                            for (final (i, hit) in hits.indexed) ...[
                              if (i == 0 ||
                                  hits[i - 1].pageIndex != hit.pageIndex)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 12,
                                    bottom: 6,
                                  ),
                                  child: Text(
                                    'PAGE ${hit.pageIndex + 1}',
                                    style: BnType.micro.copyWith(
                                      color: colors.muted,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                              _ResultCard(
                                hit: hit,
                                page: hit.pageIndex < widget.pages.length
                                    ? widget.pages[hit.pageIndex]
                                    : null,
                                selected: i == selected,
                                onTap: () => _go(hits, i, close: true),
                              ),
                            ],
                          ],
                        ),
                ),
                if (hits.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                    child: Row(
                      spacing: 8,
                      children: [
                        IconButton.outlined(
                          tooltip: 'Previous',
                          iconSize: 18,
                          icon: const Icon(Icons.arrow_upward),
                          onPressed: () => _go(hits, selected - 1),
                        ),
                        IconButton.outlined(
                          tooltip: 'Next',
                          iconSize: 18,
                          icon: const Icon(Icons.arrow_downward),
                          onPressed: () => _go(hits, selected + 1),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${selected + 1} of ${hits.length}',
                          style: BnType.caption.copyWith(color: colors.text2),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A result: a picture of where it was found, and what and where.
class _ResultCard extends StatelessWidget {
  const new({
    required this.hit,
    required this.page,
    required this.selected,
    required this.onTap,
  });

  final SearchHit hit;
  final EditorPage? page;
  final bool selected;
  final VoidCallback onTap;

  static const _previewSize = Size(120, 54);
  static const _mark = Color(0xFFFFE9A8);

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final end = hit.matchStart + hit.matchLength;
    final handwriting = hit.source == 'Handwriting';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? colors.accentTint : colors.surface,
        clipBehavior: .antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BnRadius.card),
          side: BorderSide(
            color: selected ? colors.accent : colors.hairline,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Container(
                  width: _previewSize.width,
                  height: _previewSize.height,
                  clipBehavior: .antiAlias,
                  decoration: BoxDecoration(
                    // ink is drawn for paper, so paper even in dark mode
                    color: handwriting ? Colors.white : colors.sunkenSoft,
                    border: Border.all(color: colors.hairline),
                    borderRadius: BorderRadius.circular(BnRadius.chip),
                  ),
                  child: _preview(colors, end),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    spacing: 2,
                    children: [
                      Text(
                        handwriting
                            ? hit.snippet
                            : hit.snippet.substring(hit.matchStart, end),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: BnType.body.copyWith(
                          color: colors.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        switch (hit.source) {
                          'Text' => 'Typed text',
                          final source => source,
                        },
                        style: BnType.micro.copyWith(color: colors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _preview(BadNotesColors colors, int end) {
    if ((page, hit.bounds, hit.word) case (
      final ink?,
      final line?,
      final word?,
    )) {
      final height = max(line.height * 1.3, 1.0);
      final width = max(
        word.width + line.height,
        height * _previewSize.width / _previewSize.height,
      );
      final crop = Rect.fromCenter(
        center: Offset(word.center.dx, line.center.dy),
        width: width,
        height: width * _previewSize.height / _previewSize.width,
      );
      return CustomPaint(
        painter: _InkPreview(
          strokes: [
            for (final s in ink.strokes)
              if (HandwritingOcr.isWriting(s) && s.bounds.overlaps(crop)) s,
          ],
          crop: crop,
          word: word,
          mark: _mark,
        ),
      );
    }
    final before = hit.snippet.substring(0, hit.matchStart);
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Text.rich(
        TextSpan(
          style: BnType.caption.copyWith(color: colors.text2, height: 1.3),
          children: [
            TextSpan(
              text:
                  '…${before.substring(max(0, before.length - 12))}',
            ),
            TextSpan(
              text: hit.snippet.substring(hit.matchStart, end),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                backgroundColor: _mark,
              ),
            ),
            TextSpan(text: '${hit.snippet.substring(end)}…'),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// The ink around a handwriting result, scaled to fit, with the matched
/// words marked behind it.
class _InkPreview extends CustomPainter {
  new({
    required this.strokes,
    required this.crop,
    required this.word,
    required this.mark,
  });

  final List<Stroke> strokes;
  final Rect crop, word;
  final Color mark;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = min(size.width / crop.width, size.height / crop.height);
    canvas
      ..translate(size.width / 2, size.height / 2)
      ..scale(scale)
      ..translate(-crop.center.dx, -crop.center.dy);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        word.inflate(word.height * 0.08),
        Radius.circular(word.height * 0.12),
      ),
      Paint()..color = mark,
    );
    for (final s in strokes) {
      canvas.drawPath(s.highQualityPath, Paint()..color = s.color);
    }
  }

  @override
  bool shouldRepaint(_InkPreview old) =>
      old.crop != crop ||
      old.word != word ||
      old.strokes.length != strokes.length;
}
