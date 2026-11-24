import 'package:badnotes/components/editor_ui/bar_color_row.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/tools/pen.dart';
import 'package:badnotes/i18n/strings.g.dart';

/// A wide see-through marker. It ignores pen pressure and starts out light
/// yellow, at the opacity the user picked in [stows.highlighterAlpha].
class Highlighter extends Pen {
  /// Opacity a new install starts with: 102 of 255, about 40%.
  static const alpha = 102;

  static const highlighterIcon = FontAwesomeIcons.highlighter;

  /// The highlighter the editor draws with right now.
  static var currentHighlighter = Highlighter();

  new()
    : super(
        name: t.editor.pens.highlighter,
        icon: highlighterIcon,
        toolId: .highlighter,
        sizeMin: 1,
        sizeMax: 100,
        sizeStep: 1,
        pressureEnabled: false,
        options: stows.lastHighlighterOptions.value,
        color: BarColors.lightYellow.withAlpha(stows.highlighterAlpha.value),
      ) {
    _smoothOldDefault();
  }

  /// Older installs saved a streamline of exactly 0.5, the old default.
  /// That value is lifted once to 0.8 for a smoother line; the slider can
  /// still bring it back down.
  void _smoothOldDefault() {
    if (options.streamline == 0.5) options.streamline = 0.8;
  }
}
