import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:badnotes/components/canvas/image/editor_image.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/i18n/strings.g.dart';

/// What can be done with a picture on the page: save it to the device, make
/// it (or stop it being) the page's background, or delete it.
class CanvasImageDialog extends StatefulWidget {
  const CanvasImageDialog({
    super.key,
    required this.filePath,
    required this.image,
    required this.redrawImage,
    required this.isBackground,
    required this.toggleAsBackground,
    this.singleRow = false,
  });

  final String filePath;
  final EditorImage image;
  final VoidCallback redrawImage;

  final bool isBackground;
  final VoidCallback? toggleAsBackground;

  /// All the choices side by side instead of two to a row.
  final bool singleRow;

  @override
  State<CanvasImageDialog> createState() => _CanvasImageDialogState();
}

class _CanvasImageDialogState extends State<CanvasImageDialog> {
  /// The picture's file as it was put in: a PDF's own pages, an SVG's text, a
  /// photo's bytes.
  static Future<Uint8List?> _bytesOf(EditorImage image) async =>
      switch (image) {
        final PdfEditorImage pdf =>
          pdf.pdfBytes ?? await pdf.pdfFile?.readAsBytes(),
        _ => await image.fileBytes(),
      };

  /// A file name made from the note's path (letters and digits only) and the
  /// picture's id, so two pictures never get the same one.
  String get _saveName {
    final note = widget.filePath.replaceAll(RegExp(r'[^a-zA-Z\d]'), '_');
    return 'image$note${widget.image.id}${widget.image.extension}';
  }

  Future<void> _save() async {
    final bytes = await _bytesOf(widget.image);
    if (!mounted) return;
    if (bytes != null) {
      FileManager.exportFile(_saveName, bytes, isImage: true, context: context);
    }
    Navigator.of(context).pop();
  }

  void _toggleBackground() {
    widget.toggleAsBackground?.call();
    Navigator.of(context).pop();
  }

  void _delete() {
    widget.image.onDeleteImage?.call(widget.image);
    widget.redrawImage();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final choices = [
      _Choice(
        icon: Icons.download,
        title: t.editor.imageOptions.download,
        onTap: _save,
      ),
      _Choice(
        icon: Icons.wallpaper,
        title: widget.isBackground
            ? t.editor.imageOptions.removeAsBackground
            : t.editor.imageOptions.setAsBackground,
        onTap: _toggleBackground,
      ),
      _Choice(
        icon: Icons.delete,
        title: t.editor.imageOptions.delete,
        onTap: _delete,
      ),
    ];
    final perRow = widget.singleRow ? choices.length : 2;
    final grid = GridView.count(
      crossAxisCount: perRow,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      shrinkWrap: true,
      children: choices,
    );
    // Cupertino dialogs measure their content differently: give the grid a
    // shape of its own there, a width elsewhere
    return Theme.of(context).platform.isCupertino
        ? AspectRatio(
            aspectRatio: widget.singleRow ? choices.length.toDouble() : 2,
            child: grid,
          )
        : SizedBox(width: 250, child: grid);
  }
}

class _Choice extends StatelessWidget {
  const _Choice({required this.icon, required this.title, required this.onTap});

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Column(
            children: [
              Expanded(child: Icon(icon)),
              Text(title, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
