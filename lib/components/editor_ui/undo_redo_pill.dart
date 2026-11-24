import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:badnotes/components/editor_ui/editor_ui_colors.dart';

/// Undo and redo, floating at the top right of the page.
class UndoRedoPill extends StatelessWidget {
  const UndoRedoPill({
    super.key,
    required this.undo,
    required this.redo,
    required this.canUndo,
    required this.canRedo,
  });

  final VoidCallback undo, redo;
  final bool canUndo, canRedo;

  @override
  Widget build(BuildContext context) {
    Widget button(IconData icon, String tip, bool enabled, VoidCallback onTap) =>
        IconButton(
          tooltip: tip,
          onPressed: enabled ? onTap : null,
          visualDensity: VisualDensity.compact,
          color: EditorUi.of(context).icon,
          disabledColor: EditorUi.of(context).iconDim.withValues(alpha: 0.6),
          icon: Icon(icon, size: 22),
        );
    return RepaintBoundary(
      child: Material(
        color: EditorUi.of(context).bar,
        borderRadius: BorderRadius.circular(EditorUi.barRadius),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            button(Symbols.undo, 'Undo', canUndo, undo),
            button(Symbols.redo, 'Redo', canRedo, redo),
          ],
        ),
      ),
    );
  }
}
