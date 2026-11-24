import 'package:flutter/material.dart';
import 'package:badnotes/components/canvas/hud/hud_pill.dart';

/// The zoom level over the canvas, as a percentage. Tapping it puts the zoom
/// back ([resetZoom]).
class CanvasZoomIndicator extends StatelessWidget {
  const CanvasZoomIndicator({
    super.key,
    required this.scale,
    required this.resetZoom,
  });

  final double scale;
  final VoidCallback? resetZoom;

  @override
  Widget build(BuildContext context) {
    final percent = (scale * 100).round();
    return HudPill(
      onTap: resetZoom,
      child: Text(
        '$percent%',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }
}
