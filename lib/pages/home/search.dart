import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:badnotes/components/editor/handwriting_ocr.dart';
import 'package:badnotes/components/home/folder_info.dart';
import 'package:badnotes/components/home/home_actions.dart';
import 'package:badnotes/components/home/home_shell.dart';
import 'package:badnotes/components/home/quick_board.dart';
import 'package:badnotes/components/home/quick_board_view.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/locks.dart';
import 'package:badnotes/data/editor/editor_core_info.dart';
import 'package:badnotes/data/editor/editor_exporter.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/pages/editor/editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// A note's name and its recognized handwriting, page by page.
class SearchDoc {
  const new(
    this.path,
    this.pages,
    this.modified, {
    this.shown = const [],
    this.ocr = const [],
  });

  final String path;

  /// Each page's words to search, every reading of the handwriting.
  final List<String> pages;

  /// Each page's words as shown, the best reading only.
  final List<String> shown;

  /// Each page's read handwriting with where each line is, to ring a match
  /// on the page's picture.
  final List<OcrPage> ocr;
  final DateTime modified;

  String get name => noteName(path);
}

/// Every note's name and handwriting, read off the UI thread the first time
/// search opens, and again after notes change (design §7.4).
abstract final class SearchIndex {
  static Future<List<SearchDoc>>? _docs;
  static StreamSubscription<FileOperation>? _changes;

  static Future<List<SearchDoc>> get docs {
    _changes ??= FileManager.fileWriteStream.stream.listen((event) {
      // a note or its handwriting changed: read again next time
      if (!event.isNoteAsset) _docs = null;
    });
    if (!_listening) {
      _listening = true;
      HandwritingOcr.written.addListener(() => _docs = null);
    }
    return _docs ??= _build();
  }

  static var _listening = false;

  static Future<List<SearchDoc>> _build() async {
    final files = [
      for (final f in await FileManager.getAllFiles())
        if (isVisiblePath(f)) f,
    ];
    final root = FileManager.documentsDirectory;
    final extension = Editor.extension;
    return Isolate.run(() {
      final docs = <SearchDoc>[];
      for (final path in files) {
        // each page's handwriting, typed text and PDF text; older notes
        // only had their handwriting, in a text file
        final index = File('$root$path.ocr.json');
        final old = File('$root$path.ocr.txt');
        final read = index.existsSync()
            ? HandwritingOcr.parseIndex(index.readAsStringSync())
            : const <OcrPage>[];
        final pages = index.existsSync()
            ? [for (final page in read) page.searchText]
            : old.existsSync()
            ? old.readAsStringSync().split('\n\n')
            : const <String>[];
        final note = File('$root$path$extension');
        docs.add(
          SearchDoc(
            path,
            pages,
            note.existsSync() ? note.lastModifiedSync() : DateTime(0),
            shown: [for (final page in read) page.previewText],
            ocr: read,
          ),
        );
      }
      return docs;
    });
  }
}

/// Opens the search across all notes (design N08).
void openHomeSearch(BuildContext context) {
  showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close search',
    barrierColor: BadNotesColors.of(context).scrim,
    transitionDuration: BnMotion.normal,
    // on phones the keyboard covers the lower half: the results end above it
    pageBuilder: (context, _, _) =>
        const BnAboveKeyboard(child: _SearchPanel()),
    transitionBuilder: (context, animation, _, child) =>
        bnPopIn(context, animation, child, alignment: Alignment.topCenter),
  );
}

enum _Kind { all, handwriting, notebooks, pins }

class _SearchPanel extends HookWidget {
  const _SearchPanel();

  static void _remember(String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    stows.recentSearches.value = [
      q,
      for (final r in stows.recentSearches.value)
        if (r.toLowerCase() != q.toLowerCase()) r,
    ].take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final controller = useTextEditingController();
    final query = useState('');
    final kind = useState(_Kind.all);
    // read again when a note's writing has just been read, search open or not
    final written = useValueListenable(HandwritingOcr.written);
    final docs = useFuture(useMemoized(() => SearchIndex.docs, [written]));
    useEffect(() {
      QuickBoard.load();
      return null;
    }, const []);
    final board = useValueListenable(QuickBoard.items);
    final recent = useValueListenable(stows.recentSearches);
    // typing settles for a moment before searching
    final searched = useState('');
    useEffect(() {
      final timer = Timer(
        const Duration(milliseconds: 150),
        () => searched.value = query.value.trim().toLowerCase(),
      );
      return timer.cancel;
    }, [query.value]);

    final q = searched.value;
    final pages = <(SearchDoc, int, String, List<Rect>)>[];
    final notebooks = <SearchDoc>[];
    if (q.isNotEmpty) {
      for (final doc in docs.data ?? const <SearchDoc>[]) {
        // locked notebooks, and those in locked folders, stay out of search
        if (NoteLocks.isProtected(doc.path)) continue;
        if (doc.name.toLowerCase().contains(q)) notebooks.add(doc);
        for (final (i, text) in doc.pages.indexed) {
          // a misread letter in the handwriting still matches
          if (matchesQuery(text, q)) {
            final ocr = i < doc.ocr.length ? doc.ocr[i] : null;
            pages.add((doc, i, _matchedLine(ocr, doc, i, q), ocr?.find(q) ?? const []));
          }
        }
      }
      pages.sort((a, b) => b.$1.modified.compareTo(a.$1.modified));
    }
    final pins = q.isEmpty
        ? const <BoardItem>[]
        : [
            for (final item in board)
              if ([
                item.text,
                for (final c in item.checklist) c.text,
                ...item.labels,
              ].any((t) => t.toLowerCase().contains(q)))
                item,
          ];
    final total = pages.length + notebooks.length + pins.length;

    void open(String path, {int? page}) {
      _remember(query.value);
      if (page != null) {
        Editor.openAtPage[path] = page;
        Editor.searchOnOpen[path] = query.value.trim();
      }
      Navigator.of(context).pop();
      openNote(context, path);
    }

    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= 760;
    final show = kind.value;

    Widget section(String title) => Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: BnType.micro.copyWith(
          color: colors.muted,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );

    final results = q.isEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: ValueListenableBuilder(
              valueListenable: HandwritingOcr.progress,
              builder: (context, progress, _) => Text(
                [
                  docs.hasData
                      ? 'Type to search names, handwriting and text'
                      : 'Reading your notes…',
                  if (progress case (final done, final all))
                    'Reading handwriting in the background: $done of $all notes',
                  ?HandwritingOcr.modelStatus.value,
                ].join('\n'),
                textAlign: TextAlign.center,
                style: BnType.body.copyWith(color: colors.muted),
              ),
            ),
          )
        : total == 0
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Text(
              [
                'Nothing found for “${query.value.trim()}”',
                ?HandwritingOcr.modelStatus.value,
              ].join('\n\n'),
              textAlign: TextAlign.center,
              style: BnType.body.copyWith(color: colors.muted),
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (pages.isNotEmpty &&
                  (show == _Kind.all || show == _Kind.handwriting)) ...[
                section('In handwriting'),
                for (final (doc, page, line, rects) in pages.take(12))
                  _PageHit(
                    doc: doc,
                    page: page,
                    line: line,
                    rects: rects,
                    query: q,
                    onTap: () => open(doc.path, page: page),
                  ),
                const SizedBox(height: 18),
              ],
              if (notebooks.isNotEmpty &&
                  (show == _Kind.all || show == _Kind.notebooks)) ...[
                section('Notebooks'),
                for (final doc in notebooks.take(20))
                  BnMenuRow(
                    icon: BnIcons.notebook,
                    label: doc.path.substring(1),
                    trailingText: homeMeta(doc.modified),
                    onTap: () => open(doc.path),
                  ),
                const SizedBox(height: 18),
              ],
              if (pins.isNotEmpty &&
                  (show == _Kind.all || show == _Kind.pins)) ...[
                section('Quick notes'),
                for (final item in pins)
                  BnMenuRow(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: item.paper,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(6),
                        ),
                      ),
                    ),
                    label: item.text.isEmpty
                        ? item.checklist.firstOrNull?.text ?? ''
                        : item.text,
                    trailingText: 'Pinned ${homeShortDate(item.createdAt)}',
                    onTap: () {
                      _remember(query.value);
                      Navigator.of(context).pop();
                      showQuickNote(context, item);
                    },
                  ),
              ],
            ],
          );

    final side = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (recent.isNotEmpty) ...[
          section('Recent searches'),
          for (final r in recent)
            BnMenuRow(
              icon: BnIcons.recent,
              label: r,
              onTap: () {
                controller.text = r;
                query.value = r;
              },
            ),
          const SizedBox(height: 14),
        ],
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.sunkenSoft,
            borderRadius: const BorderRadius.all(Radius.circular(14)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'tip',
                style: TextStyle(
                  fontFamily: 'Caveat',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Search reads your handwriting too. Notes are read once '
                "they're saved.",
                style: BnType.caption.copyWith(
                  color: colors.text2,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 24, 16, 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 842,
            maxHeight: size.height - 80,
          ),
          child: BnPopover(
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 16, 14),
                  child: Row(
                    children: [
                      Icon(BnIcons.search, size: 22, color: colors.text),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          autofocus: true,
                          onChanged: (v) => query.value = v,
                          onSubmitted: _remember,
                          style: BnType.title.copyWith(
                            color: colors.text,
                            fontSize: 26,
                          ),
                          decoration: InputDecoration(
                            filled: false,
                            isCollapsed: true,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            hintText: 'Search notes, handwriting, quick notes',
                            hintStyle: BnType.title.copyWith(
                              color: colors.faint,
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      Material(
                        color: colors.sunkenSoft,
                        shape: const StadiumBorder(),
                        child: InkWell(
                          customBorder: const StadiumBorder(),
                          onTap: () => Navigator.of(context).pop(),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            child: Text(
                              'Cancel',
                              style: BnType.body.copyWith(
                                color: colors.text,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 1, child: ColoredBox(color: colors.divider)),
                if (q.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 4),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final (k, label, n) in [
                          (_Kind.all, 'All', total),
                          (_Kind.handwriting, 'Handwriting', pages.length),
                          (_Kind.notebooks, 'Notebooks', notebooks.length),
                          (_Kind.pins, 'Quick notes', pins.length),
                        ])
                          // nothing there: faint, so the ones with results stand out
                          Opacity(
                            opacity: n == 0 && show != k ? 0.45 : 1,
                            child: BnChip(
                              label: '$label · $n',
                              selected: show == k,
                              onTap: () => kind.value = k,
                            ),
                          ),
                      ],
                    ),
                  ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: results),
                              const SizedBox(width: 20),
                              SizedBox(
                                width: 210,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 20),
                                  child: side,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [results, const SizedBox(height: 20), side],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The line that matched on page [index] of [doc]: the best reading of a
/// handwritten line with [q] in any reading, else a line of its typed or
/// PDF text. Only that line: the lines round it were the reader's guesses
/// at scribbles nearby ("mes", "li"), shown as if they'd been written.
String _matchedLine(OcrPage? ocr, SearchDoc doc, int index, String q) {
  for (final line in ocr?.lines ?? const <OcrLine>[]) {
    if (line.texts.any((t) => matchesQuery(t, q))) return line.texts.first;
  }
  final shown = index < doc.shown.length ? doc.shown[index] : '';
  for (final line in shown.split('\n')) {
    if (matchesQuery(line, q)) return line.trim();
  }
  return '';
}

typedef _Shot = ({ui.Image image, double pageWidth});

/// A small picture of a page, drawn from the note the first time it's
/// shown and kept. One page is drawn at a time, after the results show.
abstract final class _PageShots {
  static final _shots = <String, Future<_Shot?>>{};
  static Future<void> _queue = Future.value();

  static Future<_Shot?> of(SearchDoc doc, int page) {
    final key = '${doc.path}#$page#${doc.modified.millisecondsSinceEpoch}';
    if (_shots.length > 40) _shots.remove(_shots.keys.first);
    return _shots[key] ??= _draw(doc.path, page);
  }

  static Future<_Shot?> _draw(String path, int page) {
    final done = Completer<_Shot?>();
    _queue = _queue.then((_) async {
      try {
        final note = await EditorCoreInfo.loadFromFilePath(path);
        if (page >= note.pages.length) return done.complete(null);
        final width = note.pages[page].size.width;
        final image = await EditorExporter.screenshotPage(
          coreInfo: note,
          pageIndex: page,
          rasterizeAllStrokes: true,
          pixelRatio: 180 / width,
        );
        done.complete((image: image, pageWidth: width));
      } catch (_) {
        done.complete(null);
      }
    });
    return done.future;
  }
}

/// A page the words were found on, as a row: the page's picture with the
/// match ringed, the note and when it was edited, the line that matched
/// with the words highlighted, and its page.
class _PageHit extends StatelessWidget {
  const _PageHit({
    required this.doc,
    required this.page,
    required this.line,
    required this.rects,
    required this.query,
    required this.onTap,
  });

  final SearchDoc doc;
  final int page;
  final String line, query;
  final List<Rect> rects;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    List<TextSpan> marked(String text) {
      final lower = text.toLowerCase();
      final spans = <TextSpan>[];
      var from = 0;
      while (query.isNotEmpty) {
        final i = lower.indexOf(query, from);
        if (i < 0) break;
        spans
          ..add(TextSpan(text: text.substring(from, i)))
          ..add(
            TextSpan(
              text: text.substring(i, i + query.length),
              style: TextStyle(
                backgroundColor: colors.accentSoft,
                color: colors.accentStrong,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        from = i + query.length;
      }
      spans.add(TextSpan(text: text.substring(from)));
      return spans;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            spacing: 14,
            children: [
              SizedBox(
                width: 58,
                height: 78,
                child: DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(5)),
                    border: Border.all(color: colors.hairline),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(5)),
                    child: ColoredBox(
                      color: Colors.white,
                      child: FutureBuilder(
                        future: _PageShots.of(doc, page),
                        builder: (context, shot) => shot.data == null
                            ? const SizedBox.expand()
                            : CustomPaint(
                                painter: _ShotPainter(shot.data!, rects),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BnType.body.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      homeMeta(doc.modified),
                      style: BnType.caption.copyWith(color: colors.muted),
                    ),
                    if (line.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text.rich(
                        TextSpan(
                          style: BnType.caption.copyWith(color: colors.text2),
                          children: [
                            const TextSpan(text: '“'),
                            ...marked(line),
                            const TextSpan(text: '”'),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.accentTint,
                  borderRadius: const BorderRadius.all(Radius.circular(99)),
                ),
                child: Text(
                  'Page ${page + 1} ›',
                  style: BnType.caption.copyWith(color: colors.accentStrong),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The page's picture fitted in its box, top first, with the found lines
/// ringed. The lines' rects are in the page's own units.
class _ShotPainter extends CustomPainter {
  const _ShotPainter(this.shot, this.rects);

  final _Shot shot;
  final List<Rect> rects;

  @override
  void paint(Canvas canvas, Size size) {
    final image = shot.image;
    final scale = size.width / image.width;
    canvas.drawImageRect(
      image,
      Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
      Offset.zero & Size(size.width, image.height * scale),
      Paint()..filterQuality = FilterQuality.medium,
    );
    final unit = size.width / shot.pageWidth;
    final ring = Paint()
      ..color = const Color(0x992D3260)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final fill = Paint()..color = const Color(0x2E2D3260);
    for (final r in rects) {
      final box = Rect.fromLTRB(
        r.left * unit,
        r.top * unit,
        r.right * unit,
        r.bottom * unit,
      ).inflate(2);
      final rounded = RRect.fromRectAndRadius(box, const Radius.circular(3));
      canvas
        ..drawRRect(rounded, fill)
        ..drawRRect(rounded, ring);
    }
  }

  @override
  bool shouldRepaint(_ShotPainter old) =>
      old.shot != shot || old.rects != rects;
}
