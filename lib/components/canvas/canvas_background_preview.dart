import 'package:flutter/material.dart';
import 'package:badnotes/components/canvas/_canvas_background_painter.dart';
import 'package:badnotes/components/canvas/canvas_image.dart';
import 'package:badnotes/components/canvas/image/editor_image.dart';
import 'package:badnotes/components/canvas/inner_canvas.dart';
import 'package:badnotes/data/extensions/color_extensions.dart';
import 'package:sbn/canvas_background_pattern.dart';

class CanvasBackgroundPreview extends StatelessWidget {
  const CanvasBackgroundPreview({
    super.key,
    required this.selected,
    required this.invert,
    required this.backgroundColor,
    required this.backgroundPattern,
    required this.backgroundImage,
    this.overrideBoxFit,
    required this.pageSize,
    required this.lineHeight,
    required this.lineThickness,
  });

  final bool selected;
  final bool invert;
  final Color? backgroundColor;
  final CanvasBackgroundPattern backgroundPattern;
  final EditorImage? backgroundImage;
  final BoxFit? overrideBoxFit;
  final Size pageSize;
  final int lineHeight;
  final int lineThickness;

  static const double fixedWidth = 150;

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.of(context);
    final hasImage = backgroundImage != null;
    // coloured when picked, grey and faint otherwise
    Color tint(Color color, double fadedAlpha) => color
        .withSaturation(selected ? 1 : 0)
        .withValues(alpha: selected ? 1 : fadedAlpha);
    final previewSize = Size(
      fixedWidth,
      fixedWidth * pageSize.height / pageSize.width,
    );
    const corner = BorderRadius.all(Radius.circular(8));

    final paper = FittedBox(
      child: CustomPaint(
        size: pageSize / 2,
        painter: CanvasBackgroundPainter(
          invert: invert,
          // a picture hides the colour and the pattern under it
          backgroundColor: hasImage
              ? Colors.white
              : backgroundColor ?? InnerCanvas.defaultBackgroundColor,
          backgroundPattern: hasImage
              ? CanvasBackgroundPattern.none
              : backgroundPattern,
          lineHeight: lineHeight,
          lineThickness: lineThickness,
          primaryColor: tint(scheme.primary, 0.5),
          secondaryColor: tint(scheme.secondary, 0.5),
          preview: true,
        ),
      ),
    );

    // a Container, not a DecoratedBox: the ring takes its width from the
    // inside, so the preview stays [fixedWidth] wide
    return Container(
      width: previewSize.width,
      height: previewSize.height,
      decoration: BoxDecoration(
        border: Border.all(color: tint(scheme.primary, 0.1), width: 2),
        borderRadius: corner,
      ),
      child: ClipRRect(
        borderRadius: corner,
        child: Stack(
          children: [
            paper,
            if (hasImage)
              CanvasImage(
                filePath: '',
                image: backgroundImage!,
                overrideBoxFit: overrideBoxFit,
                pageSize: previewSize,
                setAsBackground: null,
                isBackground: true,
                readOnly: true,
              ),
          ],
        ),
      ),
    );
  }
}
