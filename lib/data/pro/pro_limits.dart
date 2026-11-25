import 'package:badnotes/components/home/cover_designs.dart';

/// What BadNotes Pro unlocks, and how far the free version goes. Every
/// limit lives here, so changing one is a one-line edit.
abstract final class ProLimits {
  /// Notebooks (not whiteboards, not notes made from a PDF). Trash and
  /// folders don't count.
  static const notebooks = 5;

  /// Whiteboards made by the user; the Quick whiteboard doesn't count.
  static const whiteboards = 1;

  /// Notes made from a PDF.
  static const pdfs = 5;

  /// The biggest PDF the free version brings in: both must hold.
  static const pdfPages = 30;
  static const pdfBytes = 10 * 1024 * 1024;

  /// Colours in each tool's row in the bar, and own colours in the colour
  /// panel.
  static const colors = 8;

  /// The covers free notebooks can have: the first four plain colours.
  static final freeCovers = {
    for (final color in CoverDesign.solidColors.take(4))
      CoverDesign.solid(color).id,
  };

  static bool isFreeCover(CoverDesign? design) =>
      design == null || freeCovers.contains(design.id);

  /// The cover a new notebook starts with in the free version.
  static CoverDesign get freeDefaultCover =>
      CoverDesign.solid(CoverDesign.solidColors.first);
}

/// What the paywall says was reached, and what [Pro.require] checks.
enum ProFeature {
  notebooks('You\'ve used your ${ProLimits.notebooks} free notebooks'),
  whiteboards('You\'ve used your free whiteboard'),
  pdfs('You\'ve used your ${ProLimits.pdfs} free PDFs'),
  bigPdf(
    'Free PDFs can have up to ${ProLimits.pdfPages} pages and '
    '${ProLimits.pdfBytes ~/ (1024 * 1024)} MB',
  ),
  colors('You\'ve used your ${ProLimits.colors} free colours'),
  covers('This cover is part of BadNotes Pro'),
  autoSync('Automatic sync is part of BadNotes Pro'),
  versions('Version history is part of BadNotes Pro'),
  noteLock('Locking notes is part of BadNotes Pro'),
  templates('Saving your own templates is part of BadNotes Pro'),
  customTape('Your own tape patterns are part of BadNotes Pro'),
  playback('Real-time reveal and Spotlight are part of BadNotes Pro'),
  fonts('Your own fonts are part of BadNotes Pro'),
  upgrade('Get everything in BadNotes');

  const ProFeature(this.reason);

  /// The line at the top of the paywall.
  final String reason;
}
