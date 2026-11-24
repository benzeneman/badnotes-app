import 'dart:typed_data';

import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:flutter/foundation.dart';

/// What was copied from one note, to paste into another: the system clipboard
/// can't hold ink, and a note's own objects go away with its tab.
class NoteClipboard {
  static var strokes = <Stroke>[];
  static var images = <({Uint8List bytes, String extension})>[];

  static bool get hasContent => strokes.isNotEmpty || images.isNotEmpty;

  /// Whether the "copied, Paste" pill shows (design 16): from a copy until
  /// it's pasted or closed, in whichever note is open.
  static final offered = ValueNotifier(false);

  /// What the pill says was copied.
  static String get summary {
    final parts = [
      if (strokes.isNotEmpty)
        '${strokes.length} stroke${strokes.length == 1 ? '' : 's'}',
      if (images.isNotEmpty)
        '${images.length} picture${images.length == 1 ? '' : 's'}',
    ];
    return '${parts.join(' and ')} copied';
  }
}
