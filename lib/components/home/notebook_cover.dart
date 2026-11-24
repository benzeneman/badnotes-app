import 'package:badnotes/components/home/cover_designs.dart';
import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/theming/frozen_picture.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:flutter/material.dart';

/// Notebook covers. A note's cover is stored next to it in `<note>.cover`:
/// a [CoverDesign.id]. No file = show the first page instead.
/// Whether the notebook's name is written on it is in `<note>.covername`
/// (`1` or `0`); no file = the design's own default ([CoverDesign.label]).
abstract class NotebookCovers {
  static CoverDesign? read(String notePath) {
    final f = FileManager.getFile('$notePath.cover');
    if (!f.existsSync()) return null;
    return CoverDesign.fromId(f.readAsStringSync().trim());
  }

  /// Whether the name goes on the cover; null for the design's default.
  static bool? showsName(String notePath) {
    final f = FileManager.getFile('$notePath.covername');
    if (!f.existsSync()) return null;
    return f.readAsStringSync().trim() != '0';
  }

  static Future<void> write(
    String notePath,
    CoverDesign? design, {
    bool? showName,
  }) async {
    final f = FileManager.getFile('$notePath.cover');
    final name = FileManager.getFile('$notePath.covername');
    if (design == null) {
      if (f.existsSync()) await f.delete();
    } else {
      await f.writeAsString(design.id);
    }
    if (design == null || showName == null) {
      if (name.existsSync()) await name.delete();
    } else {
      await name.writeAsString(showName ? '1' : '0');
    }
    // ignore: invalid_use_of_visible_for_testing_member
    FileManager.broadcastFileWrite(.write, notePath);
  }
}

/// Whether [design]'s art is dark, so text on it should be light.
bool coverIsDark(CoverDesign design) {
  if (design.section == 'Dark') return true;
  if (const {'d:ocean', 'd:forest', 'd:leather'}.contains(design.id)) {
    return true;
  }
  if (design.section == 'Solid colors') {
    final argb = int.tryParse(design.id, radix: 16);
    return argb != null && Color(argb).computeLuminance() < 0.3;
  }
  return false;
}

/// Covers whose art is busy enough that the name needs a pill behind it.
const _busyCovers = {'d:botanical', 'd:grid', 'd:linen', 'd:linen2'};

/// The cover's art, filling its box, with the notebook's name at the bottom
/// left for designs that show a label. The frame (spine, rounding, shadow)
/// is up to the caller, e.g. [BnCoverFrame].
class NotebookCover extends StatelessWidget {
  const new({
    super.key,
    required this.design,
    required this.title,
    this.showTitle,
  });

  final CoverDesign design;
  final String title;

  /// Whether [title] is written on the cover; null for the design's default.
  final bool? showTitle;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Drawn once into a picture: some covers have blurred glows, and
        // drawn afresh on every frame, the covers on the home screen made
        // opening the New menu and the new notebook dialog stutter.
        FrozenPicture(
          cacheKey: ('cover', design.id),
          child: CustomPaint(painter: _CoverPainter(design)),
        ),
        if ((showTitle ?? design.label) && title.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final dark = coverIsDark(design);
              // art not made for a name gets a pill behind it
              final busy =
                  !design.label || _busyCovers.contains(design.id);
              final text = Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: (w * 0.09).clamp(8.0, 13.0),
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: dark
                      ? const Color(0xCCFFFFFF)
                      : const Color(0xBF1C1C1E),
                ),
              );
              return Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    w * 0.136,
                    0,
                    w * 0.08,
                    w * 0.09,
                  ),
                  child: busy
                      ? DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xEBFFFFFF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: w * 0.05,
                              vertical: w * 0.03,
                            ),
                            child: text,
                          ),
                        )
                      : text,
                ),
              );
            },
          ),
      ],
    );
  }
}

class _CoverPainter extends CustomPainter {
  const new(this.design);

  final CoverDesign design;

  @override
  void paint(Canvas canvas, Size size) => design.paint(canvas, size);

  @override
  bool shouldRepaint(_CoverPainter old) => old.design != design;
}

/// The cover picker's sections, in the design's order (N28).
const coverSectionOrder = [
  'Solid colors',
  'Simple',
  'Colorful',
  'Patterns',
  'Dark',
];

Map<String, List<CoverDesign>> _orderedSections() {
  final sections = CoverDesign.sections;
  return {
    for (final name in coverSectionOrder)
      if (sections[name] case final designs?) name: designs,
    for (final MapEntry(:key, :value) in sections.entries)
      if (!coverSectionOrder.contains(key)) key: value,
  };
}

/// Every cover, by section, in rows that fill the width. The
/// [selected] one has a ring.
class CoverPicker extends StatelessWidget {
  const new({
    super.key,
    required this.selected,
    required this.onSelected,
    this.title = '',
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
    this.only,
    this.showTitle,
  });

  final CoverDesign? selected;
  final ValueChanged<CoverDesign> onSelected;
  final String title;
  final EdgeInsets padding;

  /// Whether the covers show [title]; null for each design's default.
  final bool? showTitle;

  /// Shows only this section.
  final String? only;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final sections = _orderedSections();
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: .start,
        children: [
          for (final MapEntry(key: section, value: designs) in sections.entries)
            if (only == null || only == section) ...[
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 8),
                child: Text(
                  section,
                  style: BnType.caption.copyWith(
                    color: colors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  // rows that fill the width (design N26): small swatches
                  // for the solid colors, 88-wide covers for the rest
                  final solid = section == 'Solid colors';
                  final gap = solid ? 8.0 : 12.0;
                  final minWidth = solid ? 40.0 : 88.0;
                  final width = constraints.maxWidth;
                  final columns = ((width + gap) / (minWidth + gap))
                      .floor()
                      .clamp(1, solid ? 6 : 8);
                  final tile = ((width - gap * (columns - 1)) / columns)
                      .floorToDouble();
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final design in designs)
                        CoverTile(
                          design: design,
                          title: solid ? '' : title,
                          showTitle: showTitle,
                          showName: !solid,
                          width: tile,
                          selected: design == selected,
                          onTap: () => onSelected(design),
                        ),
                    ],
                  );
                },
              ),
            ],
        ],
      ),
    );
  }
}

/// One cover to choose (88 × 118), with its name under it.
class CoverTile extends StatelessWidget {
  const new({
    super.key,
    required this.design,
    required this.selected,
    required this.onTap,
    this.title = '',
    this.showTitle,
    this.showName = true,
    this.width = 88,
  });

  final CoverDesign design;
  final bool selected;
  final VoidCallback onTap;
  final String title;

  /// Whether [title] is written on the cover; null for the design's default.
  final bool? showTitle;
  final bool showName;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: '${design.name} cover',
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: BnMotion.fast,
                curve: BnMotion.curve,
                width: width,
                height: width * 118 / 88,
                decoration: BoxDecoration(
                  // The soft shadows use even corners: the GPU draws those
                  // directly, but blurred the tile's uneven corners afresh
                  // for every tile on every frame (raster ~25 ms while the
                  // cover library was open). The ring keeps the tile's shape.
                  borderRadius: selected ? _tileRadius : _shadowRadius,
                  boxShadow: selected
                      ? [
                          BoxShadow(color: colors.surface, spreadRadius: 2),
                          BoxShadow(color: colors.accent, spreadRadius: 4),
                        ]
                      : const [
                          BoxShadow(
                            color: Color(0x0F000000),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 14,
                            offset: Offset(0, 6),
                          ),
                        ],
                ),
                child: ClipRRect(
                  borderRadius: _tileRadius,
                  child: FrozenPicture(
                    cacheKey: ('cover', design, title, showTitle),
                    child: NotebookCover(
                      design: design,
                      title: title,
                      showTitle: showTitle,
                    ),
                  ),
                ),
              ),
              if (showName) ...[
                const SizedBox(height: 6),
                Text(
                  design.name,
                  maxLines: 1,
                  overflow: .ellipsis,
                  style: BnType.micro.copyWith(
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? colors.accentStrong : colors.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static const _shadowRadius = BorderRadius.all(Radius.circular(6));

  static const _tileRadius = BorderRadius.only(
    topLeft: Radius.circular(3),
    bottomLeft: Radius.circular(3),
    topRight: Radius.circular(9),
    bottomRight: Radius.circular(9),
  );
}

/// What [showCoverLibrary] chose: a cover, or none (the first page shows).
typedef CoverChoice = ({CoverDesign? design, bool? showName});

/// The cover library (design N28; [compact] is the side sheet of N26): every
/// cover by section, a preview, "No cover", and "Apply cover". Returns null
/// when closed without choosing.
Future<CoverChoice?> showCoverLibrary(
  BuildContext context, {
  required CoverDesign? current,
  String title = '',
  bool? showName,
  bool? compact,
}) {
  final narrow = compact ?? MediaQuery.sizeOf(context).width < 1000;
  return showAppleDialog<CoverChoice>(
    context: context,
    builder: (context) =>
        _CoverLibrary(
          current: current,
          title: title,
          showName: showName,
          compact: narrow,
        ),
  );
}

class _CoverLibrary extends StatefulWidget {
  const new({
    required this.current,
    required this.title,
    required this.showName,
    required this.compact,
  });

  final CoverDesign? current;
  final String title;
  final bool? showName;
  final bool compact;

  @override
  State<_CoverLibrary> createState() => _CoverLibraryState();
}

class _CoverLibraryState extends State<_CoverLibrary> {
  late CoverDesign? _chosen = widget.current;
  String? _only;

  /// Name on the cover; null until changed here: each design's default.
  late bool? _showName = widget.showName;
  bool get _namesShown => _showName ?? _chosen?.label ?? true;

  void _apply() => Navigator.pop<CoverChoice>(context, (
    design: _chosen,
    showName: _showName,
  ));
  void _none() =>
      Navigator.pop<CoverChoice>(context, (design: null, showName: null));

  Widget _nameToggle() => BnToggleRow(
    label: 'Show notebook name',
    value: _namesShown,
    onChanged: (show) => setState(() => _showName = show),
  );

  Widget _preview(double width) {
    final colors = BadNotesColors.of(context);
    final design = _chosen;
    return SizedBox(
      width: width,
      height: width * 214 / 160,
      child: DecoratedBox(
        // even corners for the shadow: the GPU draws those directly
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          boxShadow: [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
            BoxShadow(
              color: Color(0x24000000),
              blurRadius: 40,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BnRadius.cover,
          child: design == null
              ? ColoredBox(
                  color: colors.surface,
                  child: Center(
                    child: Text(
                      'First page',
                      style: BnType.caption.copyWith(color: colors.muted),
                    ),
                  ),
                )
              : NotebookCover(
                  design: design,
                  title: widget.title,
                  showTitle: _showName,
                ),
        ),
      ),
    );
  }

  Widget _filters() {
    // only the sections that have covers
    final chips = <String?>[null, ..._orderedSections().keys];
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final section in chips)
          BnChip(
            label: section ?? 'All',
            selected: section == _only,
            onTap: () => setState(() => _only = section),
          ),
      ],
    );
  }

  Widget _picker(EdgeInsets padding) => SingleChildScrollView(
    padding: const EdgeInsets.only(bottom: 20),
    child: CoverPicker(
      selected: _chosen,
      title: widget.title,
      only: _only,
      showTitle: _showName,
      padding: padding,
      onSelected: (design) => setState(() => _chosen = design),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final titleStyle = BnType.section.copyWith(
      color: colors.text,
      letterSpacing: -0.1,
    );
    if (widget.compact) return _compact(colors, titleStyle);
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 36, 40, 30),
      child: BnPopover(
        padding: EdgeInsets.zero,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(BnRadius.popover - 1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(26, 22, 26, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'Notebook cover',
                              style: titleStyle.copyWith(fontSize: 18),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Align(
                              alignment: Alignment.topRight,
                              child: _filters(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _picker(
                        const EdgeInsets.symmetric(horizontal: 26),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 290,
                color: colors.previewBg,
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text('Preview', style: titleStyle)),
                        BnIconButton(
                          icon: BnIcons.close,
                          size: 30,
                          iconSize: 16,
                          tooltip: 'Close',
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 26),
                      child: Center(child: _preview(160)),
                    ),
                    _nameToggle(),
                    const SizedBox(height: 8),
                    BnButton(
                      label: 'No cover (show first page)',
                      expand: true,
                      onPressed: _none,
                    ),
                    const Spacer(),
                    BnButton.primary(
                      label: 'Apply cover',
                      expand: true,
                      onPressed: _chosen == null ? null : _apply,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A sheet down the right side (N26).
  Widget _compact(BadNotesColors colors, TextStyle titleStyle) {
    final width = MediaQuery.sizeOf(context).width.clamp(0.0, 400.0);
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: BnPopover(
          width: width,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                child: Row(
                  children: [
                    Expanded(child: Text('Change cover', style: titleStyle)),
                    BnIconButton(
                      icon: BnIcons.close,
                      size: 30,
                      iconSize: 16,
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Container(
                  height: 240,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.previewBg,
                    borderRadius: BorderRadius.circular(BnRadius.popover),
                  ),
                  child: _preview(140),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: _nameToggle(),
              ),
              Expanded(
                child: _picker(const EdgeInsets.symmetric(horizontal: 20)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: BnButton(
                  label: 'No cover (show first page)',
                  expand: true,
                  onPressed: _none,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Row(
                  spacing: 8,
                  children: [
                    Expanded(
                      child: BnButton(
                        label: 'Cancel',
                        expand: true,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Expanded(
                      child: BnButton.primary(
                        label: 'Apply',
                        expand: true,
                        onPressed: _chosen == null ? null : _apply,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Footer button on the home screen to set the cover of selected notes.
class CoverNoteButton extends StatelessWidget {
  const new({
    super.key,
    required this.selectedFiles,
    required this.unselectNotes,
  });

  final List<String> selectedFiles;
  final VoidCallback unselectNotes;

  /// What pressing this button does, for elsewhere to offer as well.
  Future<void> open(BuildContext context) async {
    final current = selectedFiles.length == 1
        ? NotebookCovers.read(selectedFiles.first)
        : null;
    final title = selectedFiles.length == 1
        ? selectedFiles.first.substring(
            selectedFiles.first.lastIndexOf('/') + 1,
          )
        : '';
    final choice = await showCoverLibrary(
      context,
      current: current,
      title: title,
      showName: selectedFiles.length == 1
          ? NotebookCovers.showsName(selectedFiles.first)
          : null,
    );
    if (choice == null) return;
    for (final path in selectedFiles) {
      await NotebookCovers.write(
        path,
        choice.design,
        showName: choice.showName,
      );
    }
    unselectNotes();
  }

  @override
  Widget build(BuildContext context) {
    return BnIconButton(
      tooltip: 'Cover',
      icon: BnIcons.notebook,
      onPressed: () => open(context),
    );
  }
}
