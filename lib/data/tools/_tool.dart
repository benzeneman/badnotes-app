import 'package:flutter/foundation.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:sbn/tool_id.dart';

/// Anything the editor can have selected: a pen, the eraser, the lasso,
/// and so on.
abstract class Tool {
  @protected
  @visibleForTesting
  const new();

  /// Which tool this is. Remembered in [stows.lastTool] so the editor opens
  /// with the tool used last.
  ToolId get toolId;

  /// Typing on the page instead of drawing.
  static const Tool textEditing = _TypingTool();
}

class const _TypingTool() extends Tool {
  @override
  ToolId get toolId => .textEditing;
}
