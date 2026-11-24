/// The ruling or grid drawn behind a page's ink.
///
/// Notes and settings store a pattern by its [name] (and some places by its
/// position in [values]), so never rename, reorder or remove an entry: only
/// append new ones at the end.
enum CanvasBackgroundPattern(
  /// The text written into note files and settings for this pattern.
  /// It is an identifier, not a label; show the localized name to users.
  final String name, {

  /// True when the pattern draws right up to the page border, so the painter
  /// has to clip it to the page rectangle.
  final bool requiresClipping = false,
}) {
  /// A plain page.
  none(''),

  /// Ruled lines plus a margin line on the left side.
  collegeLtr('college'),

  /// Ruled lines plus a margin line on the right side, for right-to-left text.
  collegeRtl('college-rtl'),

  /// Ruled lines with no margin line.
  lined('lined'),

  /// Squared paper.
  grid('grid', requiresClipping: true),

  /// Dotted paper: a dot where each pair of grid lines would cross.
  dots('dots', requiresClipping: true),

  /// Five-line music staves.
  staffs('staffs'),

  /// Six-line guitar tablature staves.
  tablature('tablature'),

  /// The Cornell note-taking layout.
  cornell('cornell'),

  /// Ruled lines split into two columns of equal width.
  twoColumns('two-columns'),

  /// Ruled lines split into a wide left column and a narrow right one.
  wideLeft('wide-left'),

  /// Ruled lines split into a narrow left column and a wide right one.
  wideRight('wide-right'),

  /// Ruled lines split into three columns of equal width.
  threeColumns('three-columns'),

  /// Ruled lines with two margin lines, like a legal pad.
  legal('legal'),

  /// A checklist: a row of tick boxes down the page.
  todos('todos'),

  /// A monthly calendar of five rows by seven day columns.
  month('month'),

  /// A weekly planner: six day boxes in two columns of three, a wide box for
  /// Sunday, and in each box a date line followed by writing lines.
  week('week'),

  /// A daily planner: an hour column next to writing lines, one line per
  /// half hour.
  day('day');

  /// Looks up the pattern whose [name] equals [name].
  ///
  /// A missing or unknown name gives [none], so old or damaged notes still
  /// open.
  static CanvasBackgroundPattern fromName(String? name) {
    for (final candidate in values) {
      if (candidate.name == name) return candidate;
    }
    return none;
  }
}
