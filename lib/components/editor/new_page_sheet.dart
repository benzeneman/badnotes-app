import 'package:flutter/material.dart';
import 'package:badnotes/components/canvas/canvas_background_preview.dart';
import 'package:badnotes/components/canvas/inner_canvas.dart';
import 'package:badnotes/components/editor/save_template_sheet.dart';
import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/theming/badnotes_tokens.dart';
import 'package:badnotes/components/theming/frozen_picture.dart';
import 'package:badnotes/components/toolbar/ink_dial.dart';
import 'package:badnotes/data/editor/editor_core_info.dart';
import 'package:badnotes/data/editor/page.dart';
import 'package:badnotes/data/my_templates.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:sbn/canvas_background_pattern.dart';

/// What a new page looks like.
class PageTemplate {
  const PageTemplate({
    required this.size,
    this.pattern,
    this.color,
    this.lineHeight,
  });

  /// A page just like [page].
  factory PageTemplate.sameAs(EditorPage? page) => PageTemplate(
    size: page?.size ?? EditorPage.defaultSize,
    pattern: page?.backgroundPattern,
    color: page?.backgroundColor,
    lineHeight: page?.lineHeight,
  );

  final Size size;
  final CanvasBackgroundPattern? pattern;
  final Color? color;

  /// The spacing of its lines or squares. null = the note-wide spacing.
  final int? lineHeight;

  /// Portrait sizes. The A sizes keep their real proportions to each other,
  /// with A4 as wide as a default page.
  static const sizes = <String, Size>{
    'A3': Size(1414, 2000),
    'A4': Size(1000, 1414),
    'A5': Size(707, 1000),
    'A6': Size(500, 707),
    'Letter': Size(1000, 1294),
    'Legal': Size(1000, 1647),
    'Tabloid': Size(1294, 2000),
    'Square': Size(1000, 1000),
    'Phone': Size(562, 1000),
    '16:9': Size(1000, 1778),
  };

  static const colors = <String, Color>{
    'White': Color(0xFFFFFFFF),
    'Ivory': Color(0xFFFFFCEE),
    'Black': Color(0xFF121212),
    'Peach': Color(0xFFFFE0B2),
    'Pink': Color(0xFFF8BBD0),
    'Lavender': Color(0xFFE1BEE7),
    'Sky': Color(0xFFBBDEFB),
    'Mint': Color(0xFFC8E6C9),
    'Grey': Color(0xFFE0E0E0),
    'Navy': Color(0xFF1A237E),
    'Chalkboard': Color(0xFF1B5E20),
  };
}

/// One kind of paper to choose from.
class PaperKind {
  const PaperKind(this.name, this.pattern, [this.lineHeight]);

  final String name;
  final CanvasBackgroundPattern pattern;
  final int? lineHeight;

  static const essentials = [
    PaperKind('Plain', .none),
    PaperKind('Dot grid', .dots),
    PaperKind('Graph', .grid),
    PaperKind('Tight lines', .lined, 30),
    PaperKind('Open lines', .lined, 55),
    PaperKind('Fine graph', .grid, 25),
    PaperKind('Big graph', .grid, 70),
    PaperKind('Fine dots', .dots, 25),
    PaperKind('Big dots', .dots, 70),
  ];
  static const writing = [
    PaperKind('Study notes', .cornell),
    PaperKind('Left margin', .collegeLtr),
    PaperKind('Right margin', .collegeRtl),
    PaperKind('Double margin', .legal),
    PaperKind('Two columns', .twoColumns),
    PaperKind('Wide left', .wideLeft),
    PaperKind('Wide right', .wideRight),
    PaperKind('Three columns', .threeColumns),
  ];
  static const planner = [
    PaperKind('To-do list', .todos, 48),
    PaperKind('Month grid', .month),
    PaperKind('Week planner', .week),
    PaperKind('Day planner', .day, 44),
  ];
  static const music = [
    PaperKind('Sheet music', .staffs),
    PaperKind('Guitar tabs', .tablature),
  ];

  static const sections = {
    'Essentials': essentials,
    'Writing papers': writing,
    'Planner': planner,
    'Music': music,
  };

  static const all = [...essentials, ...writing, ...planner, ...music];
}

enum PagePosition { before, after, last }

enum NewPageSource { image, photo, scan, import }

/// What the user chose for a new page: a [template], or a [source] for a page
/// holding an image.
class NewPageChoice {
  const NewPageChoice(this.position, {this.template, this.source, this.mine});

  final PagePosition position;
  final PageTemplate? template;
  final NewPageSource? source;

  /// One of the user's own templates, to copy in with what's on it
  /// ([template] is then its paper). Never set when changing a template.
  final MyTemplate? mine;
}

/// Everything about a new page on one panel: where it goes, its paper, size and
/// color. Null means no page after all.
///
/// With [note] and [pageIndex], "Mine" offers "From this page". With
/// [changing], it's Change template: only the paper, no place or images.
Future<NewPageChoice?> showNewPageSheet(
  BuildContext context, {
  required EditorPage? current,
  required int noteLineHeight,
  required int noteLineThickness,
  required Color? noteColor,
  PagePosition position = PagePosition.after,
  EditorCoreInfo? note,
  int? pageIndex,
  bool changing = false,
}) => showAppleDialog<NewPageChoice>(
  // a popup in the middle, faded and grown in (only opacity and scale
  // animate, over a plain dim: no blur), not a sheet from the bottom
  context: context,
  builder: (context) => _NewPagePanel(
    current: current,
    noteLineHeight: noteLineHeight,
    noteLineThickness: noteLineThickness,
    noteColor: noteColor,
    position: position,
    note: note,
    pageIndex: pageIndex,
    changing: changing,
  ),
);

class _NewPagePanel extends StatefulWidget {
  const _NewPagePanel({
    required this.current,
    required this.noteLineHeight,
    required this.noteLineThickness,
    required this.noteColor,
    required this.position,
    required this.note,
    required this.pageIndex,
    required this.changing,
  });

  final EditorPage? current;
  final int noteLineHeight, noteLineThickness;
  final Color? noteColor;
  final PagePosition position;
  final EditorCoreInfo? note;
  final int? pageIndex;
  final bool changing;

  @override
  State<_NewPagePanel> createState() => _NewPagePanelState();
}

class _NewPagePanelState extends State<_NewPagePanel> {
  late var _position = widget.position;

  /// The paper picked; null = the same as the current page, so adding
  /// straight away adds the same page again.
  PaperKind? _paper;

  /// The section of papers shown.
  var _section = PaperKind.sections.keys.first;

  /// Papers, Mine, or From image/PDF.
  var _tab = 0;
  String? _sizeName;
  var _landscape = false;
  String? _colorName;

  late final _same = PageTemplate.sameAs(widget.current);

  /// One of the user's own templates, picked under Mine: it wins over the
  /// paper, size and color below.
  MyTemplate? _mine;

  Size get _size {
    final name = _sizeName;
    if (name == null) {
      return _landscape == (_same.size.width > _same.size.height)
          ? _same.size
          : _same.size.flipped;
    }
    final size = PageTemplate.sizes[name]!;
    return _landscape ? size.flipped : size;
  }

  Color? get _color {
    final name = _colorName;
    return name == null ? _same.color : PageTemplate.colors[name];
  }

  PageTemplate get _template =>
      _mine?.paper ??
      PageTemplate(
        size: _size,
        pattern: _paper == null ? _same.pattern : _paper!.pattern,
        color: _color,
        lineHeight: _paper == null ? _same.lineHeight : _paper!.lineHeight,
      );

  @override
  void initState() {
    super.initState();
    _landscape = _same.size.width > _same.size.height;
  }

  void _addImage(NewPageSource source) =>
      Navigator.pop(context, NewPageChoice(_position, source: source));

  /// Where the new page goes: a segment with little pages, the new one lit.
  Widget _where(PagePosition position, String label, List<bool> pages) {
    final ink = InkPalette.of(context);
    final chosen = position == _position;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _position = position),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: chosen ? ink.desk : Colors.transparent,
            boxShadow: chosen ? BnShadows.card : null,
          ),
          child: Column(
            spacing: 4,
            children: [
              Row(
                mainAxisAlignment: .center,
                spacing: 2,
                children: [
                  for (final isNew in pages)
                    Container(
                      width: 8,
                      height: 11,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(1.5),
                        color: isNew
                            ? ink.accent
                            : ink.muted.withValues(alpha: 0.35),
                      ),
                    ),
                ],
              ),
              Text(
                label,
                style: TextStyle(
                  color: chosen ? ink.accent : ink.text,
                  fontSize: 12,
                  fontWeight: chosen ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// [paper] on a sheet of the chosen size and color. Drawn once into a
  /// picture and kept, so opening the popup again or scrolling the grid
  /// doesn't paint every pattern afresh.
  Widget _sheetOf(PaperKind? paper) {
    final invert =
        Theme.brightnessOf(context) == .dark &&
        stows.editorAutoInvert.value &&
        (_color ?? widget.noteColor) == null;
    final color =
        _color ?? widget.noteColor ?? InnerCanvas.defaultBackgroundColor;
    final pattern = paper?.pattern ?? _same.pattern ?? .none;
    final lineHeight =
        (paper == null ? _same.lineHeight : paper.lineHeight) ??
        widget.noteLineHeight;
    return FrozenPicture(
      cacheKey: (
        'new page',
        pattern,
        lineHeight,
        widget.noteLineThickness,
        color,
        invert,
        _size,
      ),
      child: FittedBox(
        child: CanvasBackgroundPreview(
          selected: false,
          // as the page will look in this theme: a picked color is kept
          invert: invert,
          backgroundColor: color,
          backgroundPattern: pattern,
          backgroundImage: null,
          pageSize: _size,
          lineHeight: lineHeight,
          lineThickness: widget.noteLineThickness,
        ),
      ),
    );
  }

  /// A paper to pick in the grid, with its name under it.
  Widget _paperTile(PaperKind? paper) {
    final ink = InkPalette.of(context);
    final chosen = _mine == null && paper == _paper;
    final aspect = _size.width / _size.height;
    return GestureDetector(
      onTap: () => setState(() {
        _paper = paper;
        _mine = null;
      }),
      child: Column(
        spacing: 4,
        children: [
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: aspect,
                child: DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: chosen
                          ? ink.accent
                          : ink.muted.withValues(alpha: 0.25),
                      width: chosen ? 2.5 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: _sheetOf(paper),
                  ),
                ),
              ),
            ),
          ),
          Text(
            paper?.name ?? 'Same as this page',
            maxLines: 1,
            overflow: .ellipsis,
            style: TextStyle(
              color: chosen ? ink.accent : ink.muted,
              fontSize: 11,
              fontWeight: chosen ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool on, VoidCallback onTap, {IconData? icon}) =>
      InkPill(label: label, icon: icon, on: on, onTap: onTap);

  Widget _label(String text) => Text(
    text.toUpperCase(),
    style: TextStyle(
      color: InkPalette.of(context).muted,
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
    ),
  );

  Widget _colors({double dot = 24, int? count}) {
    final ink = InkPalette.of(context);
    final entries = PageTemplate.colors.entries.toList();
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        for (final MapEntry(key: name, value: color)
            in count == null ? entries : entries.take(count))
          Semantics(
            button: true,
            selected: name == _colorName,
            label: name,
            child: GestureDetector(
              onTap: () => setState(() {
                _colorName = name;
                _mine = null;
              }),
              child: Container(
                width: dot,
                height: dot,
                decoration: BoxDecoration(
                  color: color,
                  shape: .circle,
                  border: Border.all(
                    color: name == _colorName
                        ? ink.accent
                        : ink.muted.withValues(alpha: 0.3),
                    width: name == _colorName ? 3 : 1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _sizes({bool all = true}) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      _chip(
        _landscape ? 'Wide' : 'Tall',
        _landscape,
        () => setState(() {
          _landscape = !_landscape;
          _mine = null;
        }),
        icon: Icons.screen_rotation_alt,
      ),
      for (final name
          in all
              ? PageTemplate.sizes.keys
              : const ['A4', 'A5', 'Letter', 'Square'])
        _chip(
          name,
          name == _sizeName,
          () => setState(() {
            _sizeName = name;
            _mine = null;
          }),
        ),
    ],
  );

  Widget _whereRow() => Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: InkPalette.of(context).raised,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      spacing: 2,
      children: [
        _where(.before, 'Before', const [false, true, false]),
        _where(.after, 'Next', const [false, false, true]),
        _where(.last, 'At the end', const [false, false, false, true]),
      ],
    ),
  );

  /// The big sheet showing what will be added.
  Widget _preview(double width) {
    final ink = InkPalette.of(context);
    final aspect = _size.width / _size.height;
    final height = width / aspect;
    return Column(
      spacing: 8,
      children: [
        SizedBox(
          width: aspect >= 1 ? width : height.clamp(0, width) * aspect,
          height: aspect >= 1 ? width / aspect : height.clamp(0, width),
          child: DecoratedBox(
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: ink.muted.withValues(alpha: 0.25)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: _sheetOf(_paper),
            ),
          ),
        ),
        Text(
          _mine?.name ??
              [
                _paper?.name ?? 'Same as this page',
                ?_sizeName,
                _landscape ? 'Wide' : 'Tall',
              ].join(' · '),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ink.text,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _tabs() {
    final ink = InkPalette.of(context);
    final names = ['Papers', 'Mine', if (!widget.changing) 'From image / PDF'];
    return Row(
      spacing: 4,
      children: [
        for (final (i, name) in names.indexed)
          GestureDetector(
            onTap: () => setState(() => _tab = i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: i == _tab ? ink.accent : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                name,
                style: TextStyle(
                  color: i == _tab ? ink.text : ink.muted,
                  fontSize: 13,
                  fontWeight: i == _tab ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// The papers of one section in a grid. Only the tiles in view are built.
  Widget _papers(int columns) {
    final papers = <PaperKind?>[
      if (_section == PaperKind.sections.keys.first) null,
      ...PaperKind.sections[_section]!,
    ];
    return Column(
      crossAxisAlignment: .stretch,
      spacing: 10,
      children: [
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: .horizontal,
            children: [
              for (final name in PaperKind.sections.keys)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _chip(
                    name == 'Writing papers' ? 'Writing' : name,
                    name == _section,
                    () => setState(() => _section = name),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 12,
              crossAxisSpacing: 10,
              childAspectRatio: 0.62,
            ),
            itemCount: papers.length,
            itemBuilder: (context, i) => _paperTile(papers[i]),
          ),
        ),
      ],
    );
  }

  static const _sourceTiles = [
    (
      Icons.image_outlined,
      'Image',
      'A page with an image',
      NewPageSource.image,
    ),
    (
      Icons.photo_camera_outlined,
      'Photo',
      'A page with a new photo',
      NewPageSource.photo,
    ),
    (
      Icons.document_scanner_outlined,
      'Scan',
      'Scan a document into pages',
      NewPageSource.scan,
    ),
    (
      Icons.picture_as_pdf_outlined,
      'PDF',
      'Bring in a PDF',
      NewPageSource.import,
    ),
  ];

  Widget _sources() {
    final ink = InkPalette.of(context);
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.4,
      children: [
        for (final (icon, label, hint, source) in _sourceTiles)
          GestureDetector(
            onTap: () => _addImage(source),
            child: Container(
              decoration: BoxDecoration(
                color: ink.raised,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                spacing: 10,
                children: [
                  Icon(icon, color: ink.accent),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: .start,
                      mainAxisAlignment: .center,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: ink.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          hint,
                          maxLines: 2,
                          overflow: .ellipsis,
                          style: TextStyle(color: ink.muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _tabBody(int columns) => switch (_tab) {
    0 => _papers(columns),
    1 => Align(
      alignment: Alignment.topLeft,
      child: MyTemplatesRail(
        selected: _mine?.name,
        onPick: (mine) => setState(() => _mine = mine),
        note: widget.note,
        pageIndex: widget.pageIndex,
        tileWidth: 72,
      ),
    ),
    _ => _sources(),
  };

  Widget _footer() {
    final ink = InkPalette.of(context);
    return Row(
      spacing: 6,
      children: [
        if (!widget.changing)
          for (final (icon, _, hint, source) in _sourceTiles)
            IconButton(
              tooltip: hint,
              style: IconButton.styleFrom(backgroundColor: ink.raised),
              icon: Icon(icon, color: ink.text, size: 20),
              onPressed: () => _addImage(source),
            ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: TextStyle(color: ink.text)),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: ink.accent,
            foregroundColor: ink.onAccent,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          ),
          icon: Icon(
            widget.changing
                ? Icons.wallpaper_outlined
                : Icons.note_add_outlined,
          ),
          label: Text(widget.changing ? 'Change template' : 'Add page'),
          onPressed: () => Navigator.pop(
            context,
            NewPageChoice(
              _position,
              template: _template,
              mine: widget.changing ? null : _mine,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ink = InkPalette.of(context);
    final screen = MediaQuery.sizeOf(context);
    final width = (screen.width - 32).clamp(280.0, 820.0);
    final height = (screen.height - 48).clamp(360.0, 620.0);
    final wide = width >= 640;
    final title = widget.changing ? 'Change template' : 'Add page';

    final options = <Widget>[
      _label('Colour'),
      _colors(),
      _label('Size'),
      _sizes(),
      if (!widget.changing) ...[_label('Where'), _whereRow()],
    ];

    final Widget body = wide
        ? Row(
            crossAxisAlignment: .start,
            spacing: 20,
            children: [
              SizedBox(
                width: 236,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: .stretch,
                    spacing: 10,
                    children: [
                      Center(child: _preview(150)),
                      const SizedBox(height: 2),
                      ...options,
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: .stretch,
                  spacing: 10,
                  children: [
                    _tabs(),
                    Expanded(child: _tabBody(5)),
                  ],
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: .stretch,
            spacing: 10,
            children: [
              Row(
                crossAxisAlignment: .start,
                spacing: 12,
                children: [
                  _preview(80),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: .stretch,
                      spacing: 8,
                      children: [
                        _colors(dot: 20, count: 8),
                        _sizes(all: false),
                      ],
                    ),
                  ),
                ],
              ),
              if (!widget.changing) _whereRow(),
              _tabs(),
              Expanded(child: _tabBody(3)),
            ],
          );

    return Center(
      child: Material(
        color: ink.desk,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: ink.muted.withValues(alpha: 0.2)),
        ),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: width,
          height: height,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Column(
              crossAxisAlignment: .stretch,
              spacing: 10,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: ink.text,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      style: IconButton.styleFrom(backgroundColor: ink.raised),
                      icon: Icon(Icons.close, size: 18, color: ink.muted),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Expanded(child: body),
                Divider(height: 1, color: ink.muted.withValues(alpha: 0.2)),
                _footer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
