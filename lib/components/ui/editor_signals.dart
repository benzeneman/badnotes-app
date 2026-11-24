import 'dart:async';

import 'package:badnotes/data/prefs.dart';
import 'package:flutter/foundation.dart';

/// What the editor's chrome listens to without rebuilding the editor.
abstract final class EditorSignals {
  /// True while a stroke is being drawn (pen down to a moment after pen up),
  /// for the tool dock's "Hide while writing".
  static final drawing = ValueNotifier(false);

  /// How many popovers are open. While one is, an open note shows a still
  /// picture of its pages instead of drawing them on every frame of the
  /// popover's animation and scrolling.
  static final covered = ValueNotifier(0);

  static Timer? _afterLift;

  /// A stroke starts.
  static void penDown() {
    _afterLift?.cancel();
    drawing.value = true;
  }

  /// When the last stroke ended.
  static var lastLift = DateTime.fromMillisecondsSinceEpoch(0);

  /// A stroke ends: the dock comes back 300 ms later, unless another starts.
  static void penUp() {
    lastLift = DateTime.now();
    _afterLift?.cancel();
    // only the dock's "Hide while writing" waits for it
    if (!stows.toolbarAutoHide.value) {
      drawing.value = false;
      return;
    }
    _afterLift = Timer(
      const Duration(milliseconds: 300),
      () => drawing.value = false,
    );
  }
}
