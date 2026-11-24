import 'dart:math' show pi;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/theming/adaptive_icon.dart';
import 'package:badnotes/i18n/strings.g.dart';

class SelectionBar extends StatelessWidget {
  final VoidCallback duplicateSelection;
  final VoidCallback deleteSelection;
  final void Function({double scale, double angle}) transformSelection;
  final VoidCallback playFromSelection;
  final VoidCallback convertSelectionToText;
  final VoidCallback copyToOtherNote;

  /// Moves the selection to the front (true) or back.
  final ValueChanged<bool> reorderSelection;

  /// Changes the words of a selected sticky note or text box.
  final VoidCallback editSelectionText;

  /// Only when the selection is one shape.
  final VoidCallback? changeShape;

  const new({
    super.key,
    required this.duplicateSelection,
    required this.deleteSelection,
    required this.transformSelection,
    required this.playFromSelection,
    required this.convertSelectionToText,
    required this.copyToOtherNote,
    required this.reorderSelection,
    required this.editSelectionText,
    required this.changeShape,
  });

  Widget _button(
    BuildContext context,
    String tooltip,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return IconButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: ColorScheme.of(context).secondary,
        backgroundColor: Colors.transparent,
        shape: const CircleBorder(),
      ),
      tooltip: tooltip,
      icon: Icon(icon),
    );
  }

  Future<void> _showResizeDialog(BuildContext context) async {
    var percent = 100.0;
    final apply = await showAppleDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Resize to ${percent.round()}%'),
          content: Slider(
            value: percent,
            min: 25,
            max: 300,
            divisions: 55,
            label: '${percent.round()}%',
            onChanged: (value) => setDialogState(() => percent = value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Resize'),
            ),
          ],
        ),
      ),
    );
    if (apply == true && percent != 100) {
      transformSelection(scale: percent / 100);
    }
  }

  Widget _moreMenu(BuildContext context) => Builder(
    builder: (context) => IconButton(
      tooltip: 'More',
      icon: Icon(Icons.more_horiz, color: ColorScheme.of(context).secondary),
      onPressed: () => showAppleMenu(
        context,
        anchor: rectOf(context),
        entries: [
          AppleMenuItem(
            'Edit text',
            icon: Icons.edit_note,
            onTap: editSelectionText,
          ),
          AppleMenuItem(
            'Bring to front',
            icon: Icons.flip_to_front,
            onTap: () => reorderSelection(true),
          ),
          AppleMenuItem(
            'Send to back',
            icon: Icons.flip_to_back,
            onTap: () => reorderSelection(false),
          ),
          AppleMenuItem(
            'Resize',
            icon: Icons.aspect_ratio,
            onTap: () => _showResizeDialog(context),
          ),
          AppleMenuItem(
            'Convert to text',
            icon: Icons.text_snippet_outlined,
            onTap: convertSelectionToText,
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
      mainAxisSize: .min,
      children: [
        _moreMenu(context),
        if (changeShape != null)
          _button(context, 'Change shape', Icons.category_outlined, changeShape!),
        _button(context, 'Copy to another note', Icons.drive_file_move_outline,
            copyToOtherNote),
        _button(context, 'Play audio from here', Icons.play_circle_outline,
            playFromSelection),
        _button(context, 'Shrink', Icons.zoom_out,
            () => transformSelection(scale: 1 / 1.1)),
        _button(context, 'Enlarge', Icons.zoom_in,
            () => transformSelection(scale: 1.1)),
        _button(context, 'Rotate left', Icons.rotate_left,
            () => transformSelection(angle: -pi / 2)),
        _button(context, 'Rotate right', Icons.rotate_right,
            () => transformSelection(angle: pi / 2)),
        IconButton(
          onPressed: duplicateSelection,
          style: TextButton.styleFrom(
            foregroundColor: ColorScheme.of(context).secondary,
            backgroundColor: Colors.transparent,
            shape: const CircleBorder(),
          ),
          tooltip: t.editor.selectionBar.duplicate,
          icon: const AdaptiveIcon(
            icon: Icons.content_copy,
            cupertinoIcon: CupertinoIcons.doc_on_clipboard,
          ),
        ),
        IconButton(
          onPressed: deleteSelection,
          style: TextButton.styleFrom(
            foregroundColor: ColorScheme.of(context).secondary,
            backgroundColor: Colors.transparent,
            shape: const CircleBorder(),
          ),
          tooltip: t.editor.selectionBar.delete,
          icon: const AdaptiveIcon(
            icon: Icons.delete,
            cupertinoIcon: CupertinoIcons.delete,
          ),
        ),
      ],
      ),
    );
  }
}
