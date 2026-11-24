import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';

enum ScreenshotHandle { topLeft, topRight, bottomLeft, bottomRight, move }

/// The maths of dragging the screenshot's frame around.
abstract class ScreenshotFrame {
  static const minSide = 48.0;
  static const _handleReach = 32.0;

  /// What a drag starting at [point] takes hold of, if anything.
  static ScreenshotHandle? handleAt(Rect frame, Offset point) {
    final corners = {
      ScreenshotHandle.topLeft: frame.topLeft,
      ScreenshotHandle.topRight: frame.topRight,
      ScreenshotHandle.bottomLeft: frame.bottomLeft,
      ScreenshotHandle.bottomRight: frame.bottomRight,
    };
    for (final MapEntry(key: handle, value: corner) in corners.entries) {
      if ((corner - point).distance <= _handleReach) return handle;
    }
    return frame.contains(point) ? ScreenshotHandle.move : null;
  }

  /// [frame] after dragging [handle] by [delta], kept inside [bounds].
  /// A non-null [ratio] (width / height) is kept while resizing.
  static Rect drag(
    Rect frame,
    ScreenshotHandle handle,
    Offset delta,
    Size bounds, {
    double? ratio,
  }) {
    if (handle == .move) {
      return frame.shift(
        Offset(
          delta.dx.clamp(-frame.left, bounds.width - frame.right),
          delta.dy.clamp(-frame.top, bounds.height - frame.bottom),
        ),
      );
    }

    final dragsRight = handle == .topRight || handle == .bottomRight;
    final dragsDown = handle == .bottomLeft || handle == .bottomRight;
    final anchor = Offset(
      dragsRight ? frame.left : frame.right,
      dragsDown ? frame.top : frame.bottom,
    );
    final corner =
        Offset(
          dragsRight ? frame.right : frame.left,
          dragsDown ? frame.bottom : frame.top,
        ) +
        delta;

    final maxWidth = dragsRight ? bounds.width - anchor.dx : anchor.dx;
    final maxHeight = dragsDown ? bounds.height - anchor.dy : anchor.dy;
    var width = (dragsRight ? corner.dx - anchor.dx : anchor.dx - corner.dx)
        .clamp(min(minSide, maxWidth), maxWidth)
        .toDouble();
    var height = (dragsDown ? corner.dy - anchor.dy : anchor.dy - corner.dy)
        .clamp(min(minSide, maxHeight), maxHeight)
        .toDouble();
    if (ratio != null) {
      height = width / ratio;
      if (height > maxHeight) {
        height = maxHeight;
        width = height * ratio;
      }
    }
    return Rect.fromPoints(
      anchor,
      anchor +
          Offset(dragsRight ? width : -width, dragsDown ? height : -height),
    );
  }
}

/// Lets the user frame part of the canvas on screen and save or share it.
/// Ink is redrawn at the chosen quality, so it stays sharp at any of them.
class ScreenshotOverlay extends StatefulWidget {
  const new({
    super.key,
    required this.boundaryKey,
    required this.fileName,
    required this.onClose,
    this.initialGlobal,
    this.onPin,
  });

  /// Where the frame starts, on the screen: a lasso's selection (design 12).
  final Rect? initialGlobal;

  /// Pins the picture to the quick notes board, if given.
  final Future<void> Function(Uint8List png)? onPin;

  /// The [RepaintBoundary] around what gets captured, filling this overlay's
  /// parent from the same top left corner.
  final GlobalKey boundaryKey;
  final String fileName;
  final VoidCallback onClose;

  @override
  State<ScreenshotOverlay> createState() => _ScreenshotOverlayState();
}

class _ScreenshotOverlayState extends State<ScreenshotOverlay> {
  static const _ratios = <String, double?>{
    'Free': null,
    '1:1': 1,
    '4:3': 4 / 3,
    '3:4': 3 / 4,
    '16:9': 16 / 9,
    '9:16': 9 / 16,
  };
  static const _qualities = <String, double>{'Normal': 1, 'High': 2, 'Best': 3};

  /// Many phones' graphics chips can't make a bigger image.
  static const _maxImageSide = 4096.0;

  Size _bounds = .zero;
  Rect _frame = .zero;
  ScreenshotHandle? _dragging;

  /// Where a new frame is being dragged out from, outside the current one.
  Offset? _newFrameFrom;
  Rect _frameBeforeDrag = .zero;
  String _ratio = 'Free';
  String _quality = 'High';
  var _busy = false;

  @override
  void initState() {
    super.initState();
    final start = widget.initialGlobal;
    if (start == null) return;
    // after the first layout, when this overlay knows where it is
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = context.findRenderObject();
      if (!mounted || box is! RenderBox || !box.hasSize) return;
      final local = Rect.fromPoints(
        box.globalToLocal(start.topLeft),
        box.globalToLocal(start.bottomRight),
      ).inflate(12).intersect(Offset.zero & _bounds);
      if (local.shortestSide < ScreenshotFrame.minSide) return;
      setState(() => _frame = local);
    });
  }

  Future<void> _pin() async {
    setState(() => _busy = true);
    var message = 'Pinned to your quick notes';
    try {
      final bytes = await _capture();
      await widget.onPin!(bytes);
    } catch (e) {
      message = 'Could not pin the screenshot';
    }
    if (mounted) {
      showBanner(context, message);
      widget.onClose();
    }
  }

  Rect _withRatio(Rect frame) => ScreenshotFrame.drag(
    frame,
    .bottomRight,
    .zero,
    _bounds,
    ratio: _ratios[_ratio],
  );

  Future<Uint8List> _capture() async {
    final boundary =
        widget.boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    // Only the framed part is drawn: drawing the whole canvas at high quality
    // and cropping it was what ran out of memory and failed on phones.
    final pixelRatio = min(
      MediaQuery.devicePixelRatioOf(context) * _qualities[_quality]!,
      _maxImageSide / _frame.longestSide,
    );
    final background = Theme.of(context).scaffoldBackgroundColor;
    // ignore: invalid_use_of_protected_member
    final layer = boundary.layer! as OffsetLayer;
    final shot = await layer.toImage(_frame, pixelRatio: pixelRatio);
    try {
      // The canvas is see-through around its pages, which galleries show as
      // black. Behind it goes the color it has on screen.
      final recorder = ui.PictureRecorder();
      Canvas(recorder)
        ..drawColor(background, BlendMode.src)
        ..drawImage(shot, Offset.zero, Paint());
      final picture = recorder.endRecording();
      final flat = await picture.toImage(shot.width, shot.height);
      picture.dispose();
      final bytes = await flat.toByteData(format: .png);
      flat.dispose();
      return bytes!.buffer.asUint8List();
    } finally {
      shot.dispose();
    }
  }

  Future<void> _finish({required bool share}) async {
    setState(() => _busy = true);
    String? message;
    try {
      final bytes = await _capture();
      if (!mounted) return;
      final done = await FileManager.exportFile(
        widget.fileName,
        bytes,
        isImage: !share,
        context: context,
      );
      if (!share) {
        message = done ? 'Screenshot saved' : 'Could not save the screenshot';
      }
    } catch (e) {
      message = 'Could not take the screenshot';
    }
    if (message != null) {
      if (mounted) showBanner(context, message);
    }
    if (mounted) widget.onClose();
  }

  Widget _choices(
    String label,
    Iterable<String> options,
    String selected,
    ValueChanged<String> onSelected,
  ) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      spacing: 6,
      children: [
        Text(label),
        for (final option in options)
          ChoiceChip(
            label: Text(option),
            selected: option == selected,
            onSelected: (_) => onSelected(option),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bounds = constraints.biggest;
              if (bounds != _bounds) {
                // first layout, or the screen turned
                _bounds = bounds;
                _frame = _withRatio(
                  (Offset.zero & bounds).deflate(bounds.shortestSide * 0.1),
                );
              }
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                // from where the finger touched, not from where it was once
                // recognized as a drag: that could already be off a corner
                dragStartBehavior: .down,
                // any tap, on the frame or off it, is a change of mind
                onTap: _busy ? null : widget.onClose,
                onPanStart: (details) {
                  _dragging = ScreenshotFrame.handleAt(
                    _frame,
                    details.localPosition,
                  );
                  _newFrameFrom = _dragging == null
                      ? details.localPosition
                      : null;
                  _frameBeforeDrag = _frame;
                },
                onPanUpdate: (details) {
                  final from = _newFrameFrom;
                  if (from != null && !_busy && _ratios[_ratio] == null) {
                    final to = details.localPosition;
                    setState(() {
                      _frame = Rect.fromPoints(
                        from,
                        Offset(
                          to.dx.clamp(0.0, bounds.width),
                          to.dy.clamp(0.0, bounds.height),
                        ),
                      );
                    });
                    return;
                  }
                  final dragging = _dragging;
                  if (dragging == null || _busy) return;
                  setState(() {
                    _frame = ScreenshotFrame.drag(
                      _frame,
                      dragging,
                      details.delta,
                      bounds,
                      ratio: _ratios[_ratio],
                    );
                  });
                },
                onPanEnd: (_) {
                  _dragging = null;
                  _newFrameFrom = null;
                  if (_frame.shortestSide < ScreenshotFrame.minSide) {
                    setState(() => _frame = _frameBeforeDrag);
                  }
                },
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _FramePainter(_frame, colorScheme.primary),
                ),
              );
            },
          ),
        ),
        Material(
          color: colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: .min,
              spacing: 4,
              children: [
                _choices('Shape', _ratios.keys, _ratio, (ratio) {
                  setState(() {
                    _ratio = ratio;
                    _frame = _withRatio(_frame);
                  });
                }),
                _choices(
                  'Quality',
                  _qualities.keys,
                  _quality,
                  (quality) => setState(() => _quality = quality),
                ),
                Row(
                  mainAxisAlignment: .end,
                  spacing: 8,
                  children: [
                    if (_busy)
                      const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    TextButton(
                      onPressed: _busy ? null : widget.onClose,
                      child: const Text('Cancel'),
                    ),
                    if (widget.onPin != null)
                      OutlinedButton(
                        onPressed: _busy ? null : _pin,
                        child: const Text('Pin to board'),
                      ),
                    OutlinedButton(
                      onPressed: _busy ? null : () => _finish(share: true),
                      child: const Text('Share'),
                    ),
                    FilledButton(
                      onPressed: _busy ? null : () => _finish(share: false),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FramePainter extends CustomPainter {
  const _FramePainter(this.frame, this.color);

  final Rect frame;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..fillType = .evenOdd
        ..addRect(Offset.zero & size)
        ..addRect(frame),
      Paint()..color = const Color(0x88000000),
    );
    canvas.drawRect(
      frame,
      Paint()
        ..color = color
        ..style = .stroke
        ..strokeWidth = 2,
    );
    for (final corner in [
      frame.topLeft,
      frame.topRight,
      frame.bottomLeft,
      frame.bottomRight,
    ]) {
      canvas.drawCircle(corner, 9, Paint()..color = Colors.white);
      canvas.drawCircle(corner, 6, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_FramePainter oldDelegate) =>
      frame != oldDelegate.frame || color != oldDelegate.color;
}
