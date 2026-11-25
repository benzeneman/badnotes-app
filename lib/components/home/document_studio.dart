import 'package:badnotes/components/pro/paywall.dart';
import 'package:badnotes/data/pro/pro.dart';
import 'package:badnotes/components/canvas/canvas_background_preview.dart';
import 'package:badnotes/components/editor/board_kits.dart';
import 'package:badnotes/components/editor/board_paper.dart';
import 'package:badnotes/components/editor/handwriting_ocr.dart';
import 'package:badnotes/components/editor/new_page_sheet.dart';
import 'package:badnotes/components/editor/save_template_sheet.dart';
import 'package:badnotes/components/home/cover_designs.dart';
import 'package:badnotes/components/home/notebook_cover.dart';
import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/theming/frozen_picture.dart';
import 'package:badnotes/components/ui/bn_home_dialogs.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/editor/note_start.dart';
import 'package:badnotes/data/my_templates.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:file_picker/file_picker.dart';
import 'package:badnotes/components/ui/covered_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sbn/canvas_background_pattern.dart';

/// What the studio made.
class NewDocument {
  const new({
    required this.name,
    required this.start,
    this.cover,
    this.pdfPath,
    this.mine,
  });

  final String name;
  final NoteStart start;
  final CoverDesign? cover;

  /// One of the user's own templates to make the first page from: write it
  /// with [MyTemplates.writeAsNote] before opening. [start] has its paper.
  final MyTemplate? mine;

  /// A PDF to open as the notebook's pages.
  final String? pdfPath;
}

/// A ready-made start for a notebook, as the empty desk offers (design N22).
enum DocumentTemplate {
  /// The "Study notes" paper (Cornell layout).
  lectureNotes('Lecture notes', 'Study notes', null),

  /// The "Day planner" paper.
  dailyPlanner('Daily planner', 'Day planner', null),

  /// "Plain" paper in "Ivory".
  sketchbook('Sketchbook', 'Plain', 'Ivory');

  const new(this.title, this.paperName, this.colorName);

  /// The name the notebook starts with.
  final String title;

  /// A [PaperKind.name].
  final String paperName;

  /// A [PageTemplate.colors] key, or null to keep the default.
  final String? colorName;

  PaperKind get paper => PaperKind.all.firstWhere((p) => p.name == paperName);
}

/// Sets up a new notebook or whiteboard on one screen (design N04): a live
/// preview on the left, the choices on the right.
Future<NewDocument?> showDocumentStudio(
  BuildContext context, {
  required bool whiteboard,
  DocumentTemplate? template,
}) => showAppleDialog<NewDocument>(
  context: context,
  builder: (context) =>
      _DocumentStudio(whiteboard: whiteboard, template: template),
);

class _DocumentStudio extends StatefulWidget {
  const new({required this.whiteboard, this.template});

  final bool whiteboard;
  final DocumentTemplate? template;

  @override
  State<_DocumentStudio> createState() => _DocumentStudioState();
}

class _DocumentStudioState extends State<_DocumentStudio> {
  final _name = TextEditingController();
  var _hasCover = true;
  CoverDesign _cover = Pro.has
      ? CoverDesign.standard
      : ProLimits.freeDefaultCover;

  // a notebook
  PaperKind _paper = PaperKind.essentials.first;
  var _paperSection = PaperKind.sections.keys.first;

  /// One of the user's own templates, under Mine: it wins over the paper,
  /// size and colour.
  MyTemplate? _mine;
  static const _mineSection = 'Mine';
  var _sizeName = 'A4';
  var _landscape = false;
  var _colorName = 'Ivory';

  // a whiteboard
  BoardPaper _boardPaper = BoardPaper.all[1];
  var _boardColorName = 'White';
  BoardKit? _kit;

  /// A file brought in with an Import tile, and which row it belongs to.
  String? _importedPath;
  String? _importedName;
  String? _importedRow;

  bool get _whiteboard => widget.whiteboard;

  /// The covers offered in a row; the rest are in the cover library.
  static final _proCovers = [
    CoverDesign.standard,
    ...CoverDesign.all.where((c) => c != CoverDesign.standard).take(8),
  ];

  /// In the free version the free covers come first.
  static List<CoverDesign> get _quickCovers => Pro.has
      ? _proCovers
      : [
          for (final id in ProLimits.freeCovers) CoverDesign.fromId(id)!,
          ..._proCovers.take(5),
        ];

  @override
  void initState() {
    super.initState();
    if (widget.template case final template?) {
      _name.text = template.title;
      _paper = template.paper;
      _paperSection = PaperKind.sections.entries
          .firstWhere((section) => section.value.contains(_paper))
          .key;
      if (template.colorName != null) _colorName = template.colorName!;
    } else if (!_whiteboard) {
      // a notebook starts from the default template, if one was chosen
      MyTemplates.defaultTemplate().then((mine) {
        if (mine == null || !mounted) return;
        setState(() {
          _mine = mine;
          _paperSection = _mineSection;
        });
      });
    }
  }

  Size get _size {
    final size = PageTemplate.sizes[_sizeName]!;
    return _landscape ? size.flipped : size;
  }

  Color get _color => PageTemplate.colors[_colorName]!;
  Color get _boardColor => BoardPaper.colors[_boardColorName]!;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _create() {
    final name = _name.text.trim().replaceAll('/', '-');
    final imported = _importedPath;
    final isPdf = imported?.toLowerCase().endsWith('.pdf') ?? false;
    Navigator.pop<NewDocument>(
      context,
      _whiteboard
          ? NewDocument(
              name: name,
              // shows on the home screen, as a board has no one first page
              cover: _cover,
              start: NoteStart(
                board: true,
                pattern: _boardPaper.pattern,
                lineHeight: _boardPaper.spacing,
                color: _boardColor,
                layoutSvg: _kit?.svg,
                imagePath: imported,
              ),
            )
          : NewDocument(
              name: name,
              cover: _hasCover ? _cover : null,
              pdfPath: isPdf ? imported : null,
              mine: _importedRow == null ? _mine : null,
              start: switch (_importedRow == null ? _mine?.paper : null) {
                final paper? => NoteStart(
                  size: paper.size,
                  pattern: paper.pattern,
                  color: paper.color,
                  lineHeight: paper.lineHeight,
                ),
                null => NoteStart(
                  size: _size,
                  pattern: _paper.pattern,
                  color: _color,
                  lineHeight: _paper.lineHeight,
                  imagePath: isPdf ? null : imported,
                ),
              },
            ),
    );
  }

  Future<void> _import(String row) async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: [
        'png',
        'jpg',
        'jpeg',
        'webp',
        if (!_whiteboard) 'pdf',
      ],
    );
    final path = file?.path;
    if (file == null || path == null || !mounted) return;
    setState(() {
      _importedPath = path;
      _importedName = file.name;
      _importedRow = row;
      _kit = null;
    });
  }

  void _clearImport() {
    _importedPath = null;
    _importedName = null;
    _importedRow = null;
  }

  Future<void> _moreCovers() async {
    final choice = await showCoverLibrary(
      context,
      current: _hasCover ? _cover : null,
      title: _name.text.trim(),
    );
    if (choice == null || !mounted) return;
    setState(() {
      if (choice.design case final design?) {
        _cover = design;
        _hasCover = true;
      } else {
        _hasCover = false;
      }
    });
  }

  Widget _paperSample(
    Size size,
    CanvasBackgroundPattern pattern,
    Color color,
    int? lineHeight,
  ) => FrozenPicture(
    cacheKey: (
      'paper',
      size,
      pattern,
      color,
      lineHeight ?? stows.lastLineHeight.value,
      stows.lastLineThickness.value,
    ),
    child: FittedBox(
      fit: BoxFit.cover,
      child: CanvasBackgroundPreview(
        selected: false,
        invert: false,
        backgroundColor: color,
        backgroundPattern: pattern,
        backgroundImage: null,
        pageSize: size,
        lineHeight: lineHeight ?? stows.lastLineHeight.value,
        lineThickness: stows.lastLineThickness.value,
      ),
    ),
  );

  // --- the live preview ----------------------------------------------------

  String get _summary {
    if (_whiteboard) {
      return '${_kit?.name ?? _importedName ?? _boardPaper.name} · '
          '$_boardColorName';
    }
    if (_importedRow == null && _mine != null) return _mine!.name;
    final paper = _importedRow == null
        ? '${_paper.name} paper'
        : (_importedName ?? 'Imported');
    return '$paper · $_sizeName · ${_landscape ? 'Landscape' : 'Portrait'}';
  }

  Widget _livePreview() {
    final colors = BadNotesColors.of(context);
    final hairline = Border.all(color: colors.hairline);
    final Widget art;
    if (_whiteboard) {
      art = Container(
        width: 250,
        height: 170,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          border: hairline,
          borderRadius: BorderRadius.circular(14),
          boxShadow: _previewShadow,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: BoardPaperPainter(
                pattern: _boardPaper.pattern,
                spacing: _boardPaper.spacing,
                color: _boardColor,
                invert: false,
              ),
            ),
            if (_kit case final kit?)
              Padding(
                padding: const EdgeInsets.all(14),
                child: FrozenPicture(
                  cacheKey: ('kit', kit.name),
                  child: SvgPicture.string(kit.svg),
                ),
              ),
          ],
        ),
      );
    } else {
      final mine = _importedRow == null ? _mine : null;
      final paper = switch (mine) {
        MyTemplate(thumbnail: final png?) => Image.memory(
          png,
          // decoded at the size shown, not the thumbnail's full size
          cacheWidth: (200 * MediaQuery.devicePixelRatioOf(context)).round(),
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
        MyTemplate(paper: final look) => _paperSample(
          look.size,
          look.pattern ?? .none,
          look.color ?? _color,
          look.lineHeight,
        ),
        null => _paperSample(_size, _paper.pattern, _color, _paper.lineHeight),
      };
      art = SizedBox(
        width: 230,
        height: 282,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // the paper peeking out from behind the cover
            Positioned(
              left: 28,
              top: 10,
              width: 192,
              height: 262,
              // the rounded clip drawn once, then only the still picture
              // is turned (a turned clip is redrawn on every frame)
              child: Transform.rotate(
                angle: 0.105,
                child: FrozenPicture(
                  cacheKey: (
                    'paper behind',
                    mine?.thumbnail ?? mine?.paper ?? _paper,
                    _size,
                    _color,
                    colors.hairline,
                    stows.lastLineHeight.value,
                    stows.lastLineThickness.value,
                  ),
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      border: hairline,
                      borderRadius: BnRadius.cover,
                    ),
                    child: paper,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              width: 200,
              height: 272,
              child: AnimatedSwitcher(
                duration: BnMotion.fast,
                // The shadow on even corners of its own: the GPU draws
                // that directly, but blurred the cover's uneven corners
                // afresh on every frame the dialog was open.
                child: DecoratedBox(
                  key: ValueKey((_hasCover, _cover.id)),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    boxShadow: _previewShadow,
                  ),
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      border: hairline,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        bottomLeft: Radius.circular(6),
                        topRight: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: _hasCover
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              ListenableBuilder(
                                listenable: _name,
                                builder: (context, _) => NotebookCover(
                                  design: _cover,
                                  title: _name.text.trim(),
                                ),
                              ),
                              const Positioned(
                                left: 0,
                                top: 0,
                                bottom: 0,
                                width: 16,
                                child: ColoredBox(color: Color(0x2916161A)),
                              ),
                            ],
                          )
                        : paper,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    // its own layer: the options scrolling beside or above it don't
    // repaint it
    return RepaintBoundary(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 26,
        children: [
          Text(
            'LIVE PREVIEW',
            style: BnType.micro.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: colors.accent,
            ),
          ),
          art,
          Text(
            _summary,
            textAlign: TextAlign.center,
            style: BnType.body.copyWith(
              color: colors.muted,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  /// One tight shadow: a wide blur is redrawn by the GPU on every frame
  /// the dialog scrolls.
  static const _previewShadow = [
    BoxShadow(color: Color(0x24000000), blurRadius: 8, offset: Offset(0, 4)),
  ];

  // --- the choices ----------------------------------------------------------

  /// The round-ended choice chip of the studio.
  Widget _chip(
    String label,
    bool selected,
    VoidCallback onTap, {
    Widget? leading,
    IconData? trailingIcon,
  }) {
    final colors = BadNotesColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: BnMotion.fast,
          curve: BnMotion.curve,
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: ShapeDecoration(
            color: selected ? colors.accentTint : colors.surface,
            shape: StadiumBorder(side: BorderSide(color: colors.hairline)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              ?leading,
              Text(
                label,
                style: BnType.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: selected ? colors.accentStrong : colors.text2,
                ),
              ),
              if (trailingIcon != null)
                Icon(trailingIcon, size: 14, color: colors.text2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String label, Widget child) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [BnFieldLabel(label, bottom: 8), child],
  );

  /// A ring of white then accent round [child] when [selected].
  BoxDecoration _ring(bool selected, BorderRadius radius) {
    final colors = BadNotesColors.of(context);
    return BoxDecoration(
      borderRadius: radius,
      border: Border.all(color: colors.hairline),
      boxShadow: selected
          ? [
              BoxShadow(color: colors.surface, spreadRadius: 2),
              BoxShadow(color: colors.accent, spreadRadius: 4),
            ]
          : null,
    );
  }

  static const _coverRadius = BorderRadius.only(
    topLeft: Radius.circular(4),
    bottomLeft: Radius.circular(4),
    topRight: Radius.circular(10),
    bottomRight: Radius.circular(10),
  );

  Widget _coverRow() {
    final colors = BadNotesColors.of(context);
    final inRow = _quickCovers.contains(_cover);
    final covers = [if (!inRow) _cover, ..._quickCovers];
    Widget tile({
      required Widget child,
      required bool selected,
      required VoidCallback onTap,
      required String label,
    }) => Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        // a hard-edged clip: the hairline hides its corners, and an
        // antialiased one per tile was redrawn on every frame
        child: Container(
          width: 52,
          height: 70,
          clipBehavior: Clip.hardEdge,
          decoration: _ring(selected, _coverRadius),
          child: child,
        ),
      ),
    );
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final design in covers)
          tile(
            label: '${design.name} cover',
            selected: _hasCover && design == _cover,
            onTap: () async {
              if (!ProLimits.isFreeCover(design) &&
                  !await Pro.require(context, ProFeature.covers)) {
                return;
              }
              if (!mounted) return;
              setState(() {
                _cover = design;
                _hasCover = true;
              });
            },
            // its art is a still picture already
            child: ProLimits.isFreeCover(design) || Pro.has
                ? NotebookCover(design: design, title: '')
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      NotebookCover(design: design, title: ''),
                      const Positioned(
                        top: 3,
                        right: 3,
                        child: ProBadge(size: 9),
                      ),
                    ],
                  ),
          ),
        tile(
          label: 'No cover',
          selected: !_hasCover,
          onTap: () => setState(() => _hasCover = false),
          child: ColoredBox(
            color: colors.surface,
            child: Center(
              child: Text(
                'None',
                style: BnType.micro.copyWith(color: colors.muted),
              ),
            ),
          ),
        ),
        Tooltip(
          message: 'More covers',
          child: GestureDetector(
            onTap: _moreCovers,
            child: BnDashedBox(
              width: 52,
              height: 70,
              radius: _coverRadius,
              child: Icon(BnIcons.grid, size: 20, color: colors.text2),
            ),
          ),
        ),
      ],
    );
  }

  /// A paper to choose: its sample and name.
  Widget _paperTile({
    required String name,
    required bool selected,
    required VoidCallback onTap,
    required Widget sample,
  }) {
    final colors = BadNotesColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 80,
          child: Column(
            spacing: 6,
            children: [
              Container(
                width: 72,
                height: 94,
                clipBehavior: Clip.hardEdge,
                decoration: _ring(selected, BorderRadius.circular(6)),
                child: sample,
              ),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BnType.caption.copyWith(
                  color: colors.text,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _importTile(String row) {
    final colors = BadNotesColors.of(context);
    final chosen = _importedRow == row;
    return GestureDetector(
      onTap: () => _import(row),
      child: SizedBox(
        width: 80,
        child: Column(
          spacing: 6,
          children: [
            AnimatedContainer(
              duration: BnMotion.fast,
              decoration: _ring(chosen, BorderRadius.circular(6)),
              child: BnDashedBox(
                width: 72,
                height: 94,
                child: Icon(
                  chosen ? BnIcons.check : BnIcons.download,
                  size: 20,
                  color: colors.text2,
                ),
              ),
            ),
            Text(
              chosen ? (_importedName ?? 'Import') : 'Import',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: BnType.caption.copyWith(
                color: colors.text,
                fontWeight: chosen ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rail(List<Widget> children, double height) => SizedBox(
    height: height,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      itemCount: children.length,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (_, i) => children[i],
    ),
  );

  Widget _papers() {
    final papers = PaperKind.sections[_paperSection] ?? const <PaperKind>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final section in [_mineSection, ...PaperKind.sections.keys])
              BnChip(
                label: section,
                selected: section == _paperSection,
                onTap: () => setState(() => _paperSection = section),
              ),
          ],
        ),
        if (_paperSection == _mineSection)
          MyTemplatesRail(
            selected: _importedRow == null ? _mine?.name : null,
            onPick: (mine) => setState(() {
              _clearImport();
              _mine = mine;
            }),
          )
        else
          _rail([
            for (final paper in papers)
              _paperTile(
                name: paper.name,
                selected:
                    _importedRow == null && _mine == null && paper == _paper,
                onTap: () => setState(() {
                  _clearImport();
                  _mine = null;
                  _paper = paper;
                }),
                sample: _paperSample(
                  _size,
                  paper.pattern,
                  _color,
                  paper.lineHeight,
                ),
              ),
            _importTile(_paperSection),
          ], 128),
      ],
    );
  }

  Widget _swatches(
    Map<String, Color> choices,
    String selected,
    ValueChanged<String> onChanged,
  ) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      for (final MapEntry(key: name, value: color) in choices.entries)
        Tooltip(
          message: name,
          child: BnSwatchDot(
            color: color,
            size: 26,
            label: name,
            selected: name == selected,
            onTap: () => onChanged(name),
          ),
        ),
    ],
  );

  static const _mainSizes = ['A4', 'A5', 'Letter'];

  Widget _sizes() {
    final others = [
      for (final name in PageTemplate.sizes.keys)
        if (!_mainSizes.contains(name)) name,
    ];
    final other = !_mainSizes.contains(_sizeName);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final name in _mainSizes)
          _chip(
            name,
            name == _sizeName,
            () => setState(() => _sizeName = name),
          ),
        Builder(
          builder: (context) => _chip(
            other ? _sizeName : 'More',
            other,
            trailingIcon: BnIcons.down,
            () => showAppleMenu(
              context,
              anchor: rectOf(context),
              entries: [
                for (final name in others)
                  AppleMenuItem(
                    name,
                    checked: name == _sizeName,
                    onTap: () => setState(() => _sizeName = name),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _language() {
    final colors = BadNotesColors.of(context);
    return _chip(
      HandwritingOcr.chosenLanguages
          .map((code) => code.toUpperCase())
          .join(', '),
      false,
      leading: Icon(BnIcons.text, size: 14, color: colors.text2),
      trailingIcon: BnIcons.down,
      () async {
        await showHandwritingLanguages(context);
        if (mounted) setState(() {});
      },
    );
  }

  List<Widget> _notebookChoices() => [
    _section('Cover', _coverRow()),
    _section('Paper', _papers()),
    Wrap(
      spacing: 28,
      runSpacing: 18,
      children: [
        _section('Size', _sizes()),
        _section(
          'Orientation',
          Wrap(
            spacing: 6,
            children: [
              _chip(
                'Portrait',
                !_landscape,
                () => setState(() => _landscape = false),
              ),
              _chip(
                'Landscape',
                _landscape,
                () => setState(() => _landscape = true),
              ),
            ],
          ),
        ),
        _section('Handwriting language', _language()),
      ],
    ),
    _section(
      'Paper color',
      _swatches(
        PageTemplate.colors,
        _colorName,
        (name) => setState(() => _colorName = name),
      ),
    ),
  ];

  Widget _kitTile(BoardKit kit) {
    final chosen = kit == _kit;
    return _paperTile(
      name: kit.name,
      selected: chosen,
      onTap: () => setState(() {
        _clearImport();
        _kit = chosen ? null : kit;
      }),
      sample: ColoredBox(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: FrozenPicture(
            cacheKey: ('kit', kit.name),
            child: SvgPicture.string(kit.svg),
          ),
        ),
      ),
    );
  }

  List<Widget> _whiteboardChoices() => [
    _section(
      'Background',
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final paper in BoardPaper.all)
            _chip(
              paper.name,
              paper == _boardPaper,
              () => setState(() => _boardPaper = paper),
            ),
        ],
      ),
    ),
    _section(
      'Color',
      _swatches(
        BoardPaper.colors,
        _boardColorName,
        (name) => setState(() => _boardColorName = name),
      ),
    ),
    _section(
      'Handwriting language',
      Align(alignment: Alignment.centerLeft, child: _language()),
    ),
    for (final MapEntry(key: row, value: kits) in BoardKit.sections.entries)
      _section(
        row,
        _rail([for (final kit in kits) _kitTile(kit), _importTile(row)], 128),
      ),
  ];

  Widget _options(bool wide) {
    final title = _whiteboard ? 'New whiteboard' : 'New notebook';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(wide ? 30 : 20, 26, wide ? 30 : 20, 0),
          child: BnDialogTitle(
            title: title,
            size: 28,
            onClose: () => Navigator.pop(context),
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(wide ? 30 : 20, 18, wide ? 30 : 20, 8),
            children: [
              if (!wide) ...[
                Center(child: FittedBox(child: _livePreview())),
                const SizedBox(height: 18),
              ],
              for (final child in [
                _section(
                  'Name',
                  BnTextInput(
                    controller: _name,
                    hint: _whiteboard
                        ? 'Untitled whiteboard'
                        : 'Untitled notebook',
                    onSubmitted: (_) => _create(),
                  ),
                ),
                ...(_whiteboard ? _whiteboardChoices() : _notebookChoices()),
              ]) ...[child, const SizedBox(height: 18)],
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            wide ? 30 : 20,
            8,
            wide ? 30 : 20,
            22 + (wide ? 0 : MediaQuery.paddingOf(context).bottom),
          ),
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 10,
            runSpacing: 10,
            children: [
              BnPillButton(
                label: 'Cancel',
                onPressed: () => Navigator.pop(context),
              ),
              BnPillButton(
                label: _whiteboard ? 'Create whiteboard' : 'Create notebook',
                icon: BnIcons.add,
                kind: BnPillKind.tint,
                onPressed: _create,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final screen = MediaQuery.sizeOf(context);
    // a card over the home screen, not the whole screen, where there's room
    final wide = screen.width >= 760 && screen.height >= 560;

    Widget card = Material(
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: wide
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: BorderSide(color: colors.hairline),
            )
          : const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 330,
                  color: colors.sunkenSoft,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(16),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: _livePreview(),
                  ),
                ),
                Expanded(child: _options(true)),
              ],
            )
          : _options(false),
    );
    // a still picture while the cover library is open over it
    card = CoveredSnapshot(child: card);

    if (!wide) {
      return Padding(padding: const EdgeInsets.only(top: 10), child: card);
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: screen.width - 48 < 960 ? screen.width - 48 : 960,
          height: screen.height * 0.92 < 632 ? screen.height * 0.92 : 632,
          child: card,
        ),
      ),
    );
  }
}
