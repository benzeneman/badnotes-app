import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/tools/pen.dart';
import 'package:badnotes/i18n/strings.g.dart';

/// A thin pen that follows stylus pressure. Its colour and
/// opacity come from the last ones the user picked.
class Pencil extends Pen {
  static const pencilIcon = FontAwesomeIcons.pencil;

  /// The pencil the editor draws with right now.
  static var currentPencil = Pencil();

  new()
    : super(
        name: t.editor.pens.pencil,
        icon: pencilIcon,
        toolId: .pencil,
        sizeMin: 1,
        sizeMax: 15,
        sizeStep: 1,
        pressureEnabled: true,
        options: stows.lastPencilOptions.value,
        color: Color(stows.lastPencilColor.value)
            .withAlpha(stows.pencilAlpha.value),
      );
}
