import 'package:flutter/material.dart';
import 'package:badnotes/data/prefs.dart';

/// The colours that come ready to pick. A picked colour that's one of
/// them isn't added to the recent colours when
/// [Stows.recentColorsDontSavePresets] is on.
abstract final class PresetColors {
  /// Whether [color] is one of the ready colours (the greys only, when
  /// greyscale is preferred).
  static bool contains(Color color) =>
      (stows.preferGreyscale.value ? _greys : _colours).any(
        (preset) => preset == color,
      );

  static final _colours = <Color>[
    Colors.black,
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.cyan,
    Colors.blue,
    Colors.purple,
    Colors.pink,
    Colors.white,
    // pastels
    const Color.fromRGBO(255, 173, 173, 1),
    const Color.fromRGBO(255, 214, 165, 1),
    const Color.fromRGBO(253, 255, 182, 1),
    const Color.fromRGBO(202, 255, 191, 1),
    const Color.fromRGBO(155, 246, 255, 1),
    const Color.fromRGBO(160, 196, 255, 1),
    const Color.fromRGBO(189, 178, 255, 1),
    const Color.fromRGBO(255, 198, 255, 1),
  ];

  static final _greys = <Color>[
    Colors.black,
    Colors.grey[800] ?? Colors.black54,
    Colors.grey,
    Colors.grey[200] ?? Colors.black12,
    Colors.white,
  ];
}
