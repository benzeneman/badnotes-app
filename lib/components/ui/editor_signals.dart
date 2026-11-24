import 'dart:async';

import 'package:badnotes/data/prefs.dart';
import 'package:flutter/foundation.dart';

/// What the editor's chrome listens to without rebuilding the editor.
abstract final class EditorSignals {
  /// True while a stroke is being drawn (pen down to a moment after pen up),
  /// for the tool dock's "Hide while writing".
  static final drawing = ValueNotifier(false);

  static Timer? _afterLift;

  /// A stroke starts.
  static void penDown() {
    _afterLift?.cancel();
    drawing.value = true;
  }

  /// A stroke ends: the dock comes back 300 ms later, unless another starts.
  static void penUp() {
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
