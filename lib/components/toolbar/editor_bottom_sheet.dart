import 'package:badnotes/components/canvas/canvas_background_preview.dart';
import 'package:badnotes/components/canvas/canvas_image_dialog.dart';
import 'package:badnotes/components/canvas/image/editor_image.dart';
import 'package:badnotes/components/canvas/inner_canvas.dart';
import 'package:badnotes/components/editor_ui/tool_panel.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/editor/editor_core_info.dart';
import 'package:badnotes/data/editor/page.dart';
import 'package:badnotes/data/extensions/list_extensions.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/i18n/extensions/box_fit_localized.dart';
import 'package:badnotes/i18n/extensions/canvas_background_pattern_localized.dart';
import 'package:badnotes/i18n/strings.g.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:sbn/canvas_background_pattern.dart';

/// The page template sheet from the editor's menu: which paper the page has,
/// its line spacing and thickness, the background picture's fit, adding
/// photos or a PDF, and clearing pages.
class EditorBottomSheet extends StatefulWidget {
  const new({
    super.key,
    required this.invert,
    required this.coreInfo,
    required this.currentPageIndex,
    required this.setBackgroundPattern,
    required this.setLineHeight,
    required this.setLineThickness,
    required this.removeBackgroundImage,
    required this.redrawImage,
    required this.clearPage,
    required this.clearAllPages,
    required this.redrawAndSave,
    required this.pickPhotos,
    required this.importPdf,
    required this.canRasterPdf,
    required this.getIsWatchingServer,
    required this.setIsWatchingServer,
    this.mine,
  });

  final bool invert;
  final EditorCoreInfo coreInfo;

  /// The page on screen, or null when there isn't one.
  final int? currentPageIndex;

  final void Function(CanvasBackgroundPattern, {required bool allPages})
  setBackgroundPattern;
  final void Function(int) setLineHeight;
  final void Function(int) setLineThickness;

  final VoidCallback removeBackgroundImage;
  final VoidCallback redrawImage;
  final VoidCallback redrawAndSave;
  final VoidCallback clearPage;
  final VoidCallback clearAllPages;

  /// Resolves to how many photos were added.
  final Future<int> Function() pickPhotos;

  /// Resolves to whether a PDF was added.
  final Future<bool> Function() importPdf;
  final bool canRasterPdf;

  final bool Function() getIsWatchingServer;
  final void Function(bool) setIsWatchingServer;

  /// The user's own templates, listed below the papers. Choosing one sets
  /// the page's paper.
  final Widget? mine;

  @override
  State<EditorBottomSheet> createState() => _EditorBottomSheetState();
}

class _EditorBottomSheetState extends State<EditorBottomSheet> {
  /// Whether a new paper goes on every page rather than just this one.
  /// Remembered while the app runs.
  static var _allPages = true;

  /// The ways a background picture can fill the page.
  static const _imageFits = <BoxFit>[.fill, .cover, .contain];

  /// The papers offered up front; the others wait behind "More papers".
  static const _commonPatterns = <CanvasBackgroundPattern>[
    .none,
    .collegeLtr,
    .lined,
    .grid,
    .dots,
  ];
  var _showAllPatterns = false;

  EditorCoreInfo get _info => widget.coreInfo;

  /// Closes the sheet when [done] says something was added or changed.
  void _closeIf(bool done) {
    if (done && context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final page = _info.pages.getOrNull(widget.currentPageIndex ?? -1);
    final backgroundImage = page?.backgroundImage;
    final current = page?.backgroundPattern ?? _info.backgroundPattern;

    Widget preview(CanvasBackgroundPattern pattern, {BoxFit? fit}) =>
        CanvasBackgroundPreview(
          selected: false,
          invert: widget.invert,
          backgroundColor:
              _info.backgroundColor ?? InnerCanvas.defaultBackgroundColor,
          backgroundPattern: pattern,
          backgroundImage: fit == null ? null : backgroundImage,
          overrideBoxFit: fit,
          pageSize: page?.size ?? EditorPage.defaultSize,
          lineHeight: _info.lineHeight,
          lineThickness: _info.lineThickness,
        );

    return ScrollConfiguration(
      // let every pointer, a mouse included, drag the list
      behavior: ScrollConfiguration.of(context)
          .copyWith(dragDevices: PointerDeviceKind.values.toSet()),
      child: ListView(
        shrinkWrap: true,
        padding: const .fromLTRB(18, 16, 18, 18),
        children: [
          Text(
            'Page template',
            style: BnType.section.copyWith(
              color: BadNotesColors.of(context).text,
              fontWeight: FontWeight.w700,
            ),
          ),
          ..._scopeChoice(),
          ..._papers(current, preview),
          if (widget.mine case final mine?) ...[
            const _SectionLabel('My templates'),
            mine,
          ],
          ..._lineSliders(),
          if (backgroundImage != null)
            ..._backgroundImageControls(backgroundImage, current, preview),
          ..._addButtons(),
          if (stows.loggedIn) ..._watchServerToggle(),
          ..._clearButtons(),
        ],
      ),
    );
  }

  /// "This page" or "All pages".
  List<Widget> _scopeChoice() {
    final index = widget.currentPageIndex;
    final count = _info.pages.length;
    return [
      const _SectionLabel('Change'),
      BnSegmented<bool>(
        segments: [
          BnSegment(
            false,
            index == null ? 'This page' : 'This page (p. ${index + 1})',
          ),
          BnSegment(true, count == 1 ? 'All pages' : 'All $count pages'),
        ],
        selected: _allPages,
        height: 36,
        onChanged: (all) => setState(() => _allPages = all),
      ),
    ];
  }

  List<Widget> _papers(
    CanvasBackgroundPattern current,
    Widget Function(CanvasBackgroundPattern) preview,
  ) => [
    const _SectionLabel('Paper'),
    Wrap(
      spacing: 10,
      runSpacing: 12,
      children: [
        for (final pattern
            in _showAllPatterns
                ? CanvasBackgroundPattern.values
                : _commonPatterns)
          _TemplateTile(
            preview: preview(pattern),
            label: pattern == .none ? 'Blank' : pattern.localizedName,
            selected: current == pattern,
            onTap: () => setState(() {
              widget.setBackgroundPattern(pattern, allPages: _allPages);
            }),
          ),
      ],
    ),
    // a row like the tape panel's "More patterns": as plain text it didn't
    // look like something to tap
    PanelNavRow(
      title: _showAllPatterns ? 'Fewer papers' : 'More papers',
      trailing: _showAllPatterns ? null : 'Music, Cornell, and others',
      chevron: false,
      onTap: () => setState(() => _showAllPatterns = !_showAllPatterns),
    ),
  ];

  List<Widget> _lineSliders() => [
    const SizedBox(height: 8),
    BnSlider(
      label: 'Line spacing',
      valueLabel: _info.lineHeight.toString(),
      value: _info.lineHeight.toDouble(),
      min: 20,
      max: 100,
      divisions: 8,
      onChanged: (value) => setState(() {
        widget.setLineHeight(value.toInt());
      }),
    ),
    const SizedBox(height: 10),
    BnSlider(
      label: 'Line thickness',
      valueLabel: _info.lineThickness.toString(),
      value: _info.lineThickness.toDouble(),
      min: 1,
      max: 5,
      divisions: 4,
      onChanged: (value) => setState(() {
        widget.setLineThickness(value.toInt());
      }),
    ),
  ];

  List<Widget> _backgroundImageControls(
    EditorImage backgroundImage,
    CanvasBackgroundPattern current,
    Widget Function(CanvasBackgroundPattern, {BoxFit? fit}) preview,
  ) => [
    _SectionLabel(t.editor.menu.backgroundImageFit),
    Wrap(
      spacing: 10,
      children: [
        for (final fit in _imageFits)
          _TemplateTile(
            preview: preview(current, fit: fit),
            label: fit.localizedName,
            selected: backgroundImage.backgroundFit == fit,
            onTap: () => setState(() {
              backgroundImage.backgroundFit = fit;
              widget.redrawAndSave();
            }),
          ),
      ],
    ),
    const SizedBox(height: 12),
    CanvasImageDialog(
      filePath: _info.filePath,
      image: backgroundImage,
      redrawImage: () => setState(() {
        widget.redrawImage();
      }),
      isBackground: true,
      toggleAsBackground: widget.removeBackgroundImage,
      singleRow: true,
    ),
  ];

  List<Widget> _addButtons() => [
    const _SectionLabel('Add to the page'),
    Row(
      spacing: 8,
      children: [
        Expanded(
          child: BnButton(
            label: 'Photos',
            icon: BnIcons.photo,
            expand: true,
            onPressed: () async => _closeIf(await widget.pickPhotos() > 0),
          ),
        ),
        if (widget.canRasterPdf)
          Expanded(
            child: BnButton(
              label: 'A PDF',
              icon: BnIcons.file,
              expand: true,
              onPressed: () async => _closeIf(await widget.importPdf()),
            ),
          ),
      ],
    ),
  ];

  List<Widget> _watchServerToggle() => [
    const SizedBox(height: 8),
    StatefulBuilder(
      builder: (context, setState) {
        final watching = widget.getIsWatchingServer();
        return BnToggleRow(
          label: t.editor.menu.watchServer,
          description: watching ? t.editor.menu.watchServerReadOnly : null,
          value: watching,
          onChanged: (value) => setState(() {
            widget.setIsWatchingServer(value);
          }),
        );
      },
    ),
  ];

  List<Widget> _clearButtons() {
    VoidCallback? clearThen(VoidCallback clear) => _info.isNotEmpty
        ? () {
            clear();
            Navigator.pop(context);
          }
        : null;

    return [
      Padding(
        padding: const .only(top: 16, bottom: 12),
        child: Divider(height: 1, color: BadNotesColors.of(context).divider),
      ),
      Row(
        spacing: 8,
        children: [
          Expanded(
            child: BnButton(
              label: 'Clear this page',
              kind: BnButtonKind.destructive,
              expand: true,
              onPressed: clearThen(widget.clearPage),
            ),
          ),
          Expanded(
            child: BnButton(
              label: 'Clear all pages',
              kind: BnButtonKind.destructive,
              expand: true,
              onPressed: clearThen(widget.clearAllPages),
            ),
          ),
        ],
      ),
    ];
  }
}

/// A small heading between the sheet's groups.
class _SectionLabel extends StatelessWidget {
  const new(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const .only(top: 16, bottom: 8),
    child: Text(
      title,
      style: BnType.caption.copyWith(
        color: BadNotesColors.of(context).muted,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

/// A choice shown as a little page: a [preview] in a rounded frame, which
/// gets an accent border when [selected], with a [label] under it.
class _TemplateTile extends StatelessWidget {
  const new({
    required this.preview,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Widget preview;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final frame = BoxDecoration(
      borderRadius: const .all(.circular(7)),
      border: Border.all(
        color: selected ? colors.accent : colors.hairline,
        width: selected ? 2 : 1,
      ),
      boxShadow: selected
          ? [BoxShadow(color: colors.accentTintBorder, spreadRadius: 3)]
          : null,
    );
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: .min,
          children: [
            AnimatedContainer(
              duration: BnMotion.fast,
              curve: BnMotion.curve,
              width: 66,
              height: 86,
              decoration: frame,
              clipBehavior: .antiAlias,
              child: FittedBox(fit: .cover, child: preview),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: .ellipsis,
              style: BnType.micro.copyWith(
                color: selected ? colors.accentStrong : colors.text2,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
