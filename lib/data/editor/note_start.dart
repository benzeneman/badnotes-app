import 'dart:ui';

import 'package:badnotes/components/editor/new_page_sheet.dart';
import 'package:sbn/canvas_background_pattern.dart';

/// How a new note should begin, handed over to its editor when it opens.
class NoteStart {
  const NoteStart({
    this.board = false,
    this.size,
    this.pattern,
    this.color,
    this.lineHeight,
    this.layoutSvg,
    this.imagePath,
    this.source,
  });

  /// A whiteboard instead of pages.
  final bool board;
  final Size? size;
  final CanvasBackgroundPattern? pattern;
  final Color? color;
  final int? lineHeight;

  /// A ready-made layout to put in the middle of a whiteboard.
  final String? layoutSvg;

  /// An image file to use as the first page, or to put on a whiteboard.
  final String? imagePath;

  /// Asks for an image when the note opens: leaving empty-handed leaves no note.
  final NewPageSource? source;

  static final _pending = <String, NoteStart>{};

  static void set(String path, NoteStart start) => _pending[path] = start;

  /// The start for the note at [path], once.
  static NoteStart? take(String path) => _pending.remove(path);
}
