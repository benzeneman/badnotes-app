import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:flutter/material.dart';

enum ExportFormat { pdf, png, badNotes }

enum ExportPages { thisPage, all, chosen }

enum ExportAction { print, save, share }

enum PresentMode { everythingLive, inkOnly, fullPageFocus }

/// Shows a [ShareExportCard] growing out of [anchor]. It closes before any
/// callback runs.
Future<void> showShareExportCard(
  BuildContext context, {
  required Rect anchor,
  int? pageCount,
  required void Function(
    ExportFormat format,
    ExportPages pages,
    bool withPaper,
    ExportAction action,
  )
  onExport,
  required void Function(PresentMode mode) onPresent,
  void Function(ExportFormat format, bool withPaper)? onChoosePages,
  Set<ExportFormat> formats = const {
    ExportFormat.pdf,
    ExportFormat.png,
    ExportFormat.badNotes,
  },
  bool allowThisPage = true,
  bool canPrint = true,
  Set<PresentMode> presentModes = const {
    PresentMode.everythingLive,
    PresentMode.inkOnly,
    PresentMode.fullPageFocus,
  },
}) {
  return showAnchoredPanel<void>(
    context,
    anchor: anchor,
    width: 380,
    builder: (context) {
      void Function() close(void Function() then) => () {
        Navigator.pop(context);
        then();
      };
      return ShareExportCard(
        pageCount: pageCount,
        formats: formats,
        allowThisPage: allowThisPage,
        canPrint: canPrint,
        presentModes: presentModes,
        onExport: (format, pages, withPaper, action) =>
            close(() => onExport(format, pages, withPaper, action))(),
        onPresent: (mode) => close(() => onPresent(mode))(),
        onChoosePages: onChoosePages == null
            ? null
            : (format, withPaper) =>
                  close(() => onChoosePages(format, withPaper))(),
      );
    },
  );
}

/// Pick a format and which pages, then print, save or share them; or start
/// presenting. Only callbacks: the caller does the work.
class ShareExportCard extends StatefulWidget {
  const new({
    super.key,
    this.pageCount,
    required this.onExport,
    required this.onPresent,
    this.onChoosePages,
    this.formats = const {
      ExportFormat.pdf,
      ExportFormat.png,
      ExportFormat.badNotes,
    },
    this.allowThisPage = true,
    this.canPrint = true,
    this.presentModes = const {
      PresentMode.everythingLive,
      PresentMode.inkOnly,
      PresentMode.fullPageFocus,
    },
  });

  /// Shown as "All 12"; null (several notes) shows "All pages".
  final int? pageCount;
  final void Function(
    ExportFormat format,
    ExportPages pages,
    bool withPaper,
    ExportAction action,
  )
  onExport;
  final void Function(PresentMode mode) onPresent;

  /// Shows "Choose…" in the pages; tapping it calls this with the format
  /// and paper picked so far, and the pages are picked elsewhere.
  final void Function(ExportFormat format, bool withPaper)? onChoosePages;

  /// The formats offered, e.g. no PDF on a whiteboard.
  final Set<ExportFormat> formats;

  /// Whether "This page" is offered.
  final bool allowThisPage;
  final bool canPrint;
  final Set<PresentMode> presentModes;

  @override
  State<ShareExportCard> createState() => _ShareExportCardState();
}

class _ShareExportCardState extends State<ShareExportCard> {
  late var format = ExportFormat.values.firstWhere(
    widget.formats.contains,
    orElse: () => ExportFormat.png,
  );
  late var pages = widget.allowThisPage ? ExportPages.thisPage : ExportPages.all;
  var withPaper = true;

  void export(ExportAction action) =>
      widget.onExport(format, pages, withPaper, action);

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(
        text.toUpperCase(),
        style: BnType.micro.copyWith(color: colors.muted, letterSpacing: 0.6),
      ),
    );
    Widget tiles<T>(
      List<(T, IconData, String)> items, {
      T? selected,
      required ValueChanged<T> onTap,
    }) => Row(
      children: [
        for (final (i, (value, icon, text)) in items.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _Tile(
              icon: icon,
              label: text,
              selected: value == selected,
              onTap: () => onTap(value),
            ),
          ),
        ],
      ],
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: .stretch,
        mainAxisSize: .min,
        children: [
          Text(
            'Share and Export',
            style: BnType.title.copyWith(color: colors.text),
          ),
          if (widget.formats.isNotEmpty) ...[
            label('Format'),
            tiles<ExportFormat>(
              [
                if (widget.formats.contains(ExportFormat.pdf))
                  (ExportFormat.pdf, Icons.picture_as_pdf_outlined, 'PDF'),
                if (widget.formats.contains(ExportFormat.png))
                  (ExportFormat.png, Icons.image_outlined, 'Image (PNG)'),
                if (widget.formats.contains(ExportFormat.badNotes))
                  (
                    ExportFormat.badNotes,
                    Icons.description_outlined,
                    'BadNotes file',
                  ),
              ],
              selected: format,
              onTap: (v) => setState(() {
                format = v;
                if (v == ExportFormat.badNotes && pages == ExportPages.chosen) {
                  pages = ExportPages.all;
                }
              }),
            ),
            label('Pages'),
            BnSegmented<ExportPages>(
              segments: [
                if (widget.allowThisPage)
                  const BnSegment(ExportPages.thisPage, 'This page'),
                BnSegment(
                  ExportPages.all,
                  widget.pageCount == null ? 'All pages' : 'All ${widget.pageCount}',
                ),
                // a BadNotes file is always the whole note
                if (widget.onChoosePages != null &&
                    format != ExportFormat.badNotes)
                  const BnSegment(ExportPages.chosen, 'Choose…'),
              ],
              selected: pages,
              onChanged: (v) {
                setState(() => pages = v);
                if (v == ExportPages.chosen) {
                  widget.onChoosePages?.call(format, withPaper);
                }
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Include page paper (lines, colour)',
                    style: BnType.body.copyWith(color: colors.text),
                  ),
                ),
                BnToggle(
                  value: withPaper,
                  onChanged: (v) => setState(() => withPaper = v),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                if (widget.canPrint) ...[
                  BnButton(
                    label: 'Print',
                    icon: Icons.print_outlined,
                    onPressed: () => export(.print),
                  ),
                  const SizedBox(width: 8),
                ],
                BnButton(
                  label: 'Save',
                  icon: Icons.save_alt,
                  onPressed: () => export(.save),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: BnButton.primary(
                    label: 'Share',
                    icon: Icons.ios_share,
                    expand: true,
                    onPressed: () => export(.share),
                  ),
                ),
              ],
            ),
          ],
          if (widget.presentModes.isNotEmpty) ...[
            label('Present'),
            tiles<PresentMode>(
              [
                if (widget.presentModes.contains(PresentMode.everythingLive))
                  (
                    PresentMode.everythingLive,
                    Icons.cast_outlined,
                    'Everything live',
                  ),
                if (widget.presentModes.contains(PresentMode.inkOnly))
                  (PresentMode.inkOnly, Icons.draw_outlined, 'Ink only'),
                if (widget.presentModes.contains(PresentMode.fullPageFocus))
                  (
                    PresentMode.fullPageFocus,
                    Icons.fullscreen,
                    'Full page focus',
                  ),
              ],
              onTap: widget.onPresent,
            ),
          ],
        ],
      ),
    );
  }
}

/// A rounded choice with an icon over a label; accent ringed when [selected].
class _Tile extends StatelessWidget {
  const new({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    const radius = BorderRadius.all(Radius.circular(BnRadius.card));
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? colors.accentTint : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? colors.accent : colors.hairline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Column(
              mainAxisSize: .min,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: selected ? colors.accent : colors.text2,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: BnType.caption.copyWith(color: colors.text),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
