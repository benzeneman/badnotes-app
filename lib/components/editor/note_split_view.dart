import 'dart:math';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/data/editor/page.dart';

/// Which side of a canvas of [size] a tab dropped at [point] opens on. The top
/// and bottom take only the outer parts, as side by side is the common choice.
AxisDirection splitSideAt(Offset point, Size size) {
  if (point.dy < size.height * 0.2) return .up;
  if (point.dy > size.height * 0.8) return .down;
  return point.dx < size.width / 2 ? .left : .right;
}

/// [main] with [pane] beside it, if any, and a bar between them. Dragging the
/// bar shows where it goes and resizes on letting go, as laying out two whole
/// notes on every move of the finger can't keep up. Tapping it offers to switch
/// the two around.
///
/// The same widgets with or without [pane], so [main] keeps its state when one
/// opens.
class ResizableSplit extends StatefulWidget {
  const ResizableSplit({
    super.key,
    required this.axis,
    required this.main,
    this.pane,
    this.paneFirst = false,
    required this.onSwitch,
    required this.onFlip,
    required this.onClose,
  });

  /// [Axis.horizontal] is side by side.
  final Axis axis;
  final Widget main;
  final Widget? pane;

  /// Whether [pane] goes left of or above [main], not after it.
  final bool paneFirst;
  final VoidCallback onSwitch;
  final VoidCallback onFlip;
  final VoidCallback onClose;

  @override
  State<ResizableSplit> createState() => _ResizableSplitState();
}

class _ResizableSplitState extends State<ResizableSplit> {
  static const _barThickness = 20.0;
  static const _minShare = 0.2;

  /// How much of the room [ResizableSplit.main] gets.
  var _share = 0.5;

  /// The same, while the bar is being dragged.
  final _dragged = ValueNotifier<double?>(null);

  @override
  void dispose() {
    _dragged.dispose();
    super.dispose();
  }

  bool get _horizontal => widget.axis == .horizontal;

  void _showMenu(Offset at) => showAppleMenu(
    context,
    anchor: at & Size.zero,
    entries: [
      AppleMenuItem(
        _horizontal ? 'Switch left and right' : 'Switch top and bottom',
        icon: Icons.swap_horiz,
        onTap: widget.onSwitch,
      ),
      AppleMenuItem(
        _horizontal ? 'Top and bottom' : 'Side by side',
        icon: _horizontal
            ? Icons.horizontal_split_outlined
            : Icons.vertical_split_outlined,
        onTap: widget.onFlip,
      ),
      const AppleMenuDivider(),
      AppleMenuItem(
        'Close split view',
        icon: Icons.close,
        destructive: true,
        onTap: widget.onClose,
      ),
    ],
  );

  Widget _buildBar(BuildContext context, double length) {
    final colorScheme = ColorScheme.of(context);
    return GestureDetector(
      key: const ValueKey('bar'),
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) => _showMenu(details.globalPosition),
      onPanStart: (_) => _dragged.value = _share,
      onPanUpdate: (details) {
        final moved = _horizontal ? details.delta.dx : details.delta.dy;
        final grown = widget.paneFirst ? -moved : moved;
        _dragged.value = ((_dragged.value ?? _share) + grown / length).clamp(
          _minShare,
          1 - _minShare,
        );
      },
      onPanEnd: (_) {
        final share = _dragged.value;
        _dragged.value = null;
        if (share != null) setState(() => _share = share);
      },
      onPanCancel: () => _dragged.value = null,
      child: Container(
        width: _horizontal ? _barThickness : null,
        height: _horizontal ? null : _barThickness,
        color: colorScheme.surfaceContainerHighest,
        alignment: .center,
        child: RotatedBox(
          quarterTurns: _horizontal ? 1 : 0,
          child: Icon(
            Icons.drag_handle,
            size: _barThickness,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mainFlex = (_share * 1000).round();
    final colorScheme = ColorScheme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final length = _horizontal
            ? constraints.maxWidth
            : constraints.maxHeight;
        final mainPart = Expanded(
          key: const ValueKey('main'),
          flex: mainFlex,
          child: widget.main,
        );
        final panePart = widget.pane == null
            ? null
            : Expanded(
                key: const ValueKey('pane'),
                flex: 1000 - mainFlex,
                child: widget.pane!,
              );
        final bar = _buildBar(context, length);
        return Stack(
          children: [
            Flex(
              direction: widget.axis,
              crossAxisAlignment: .stretch,
              children: [
                if (panePart != null && widget.paneFirst) ...[panePart, bar],
                mainPart,
                if (panePart != null && !widget.paneFirst) ...[bar, panePart],
              ],
            ),
            ValueListenableBuilder(
              valueListenable: _dragged,
              builder: (context, share, _) {
                if (share == null) return const SizedBox.shrink();
                final at = (widget.paneFirst ? 1 - share : share) * length;
                return Positioned(
                  left: _horizontal ? at - 2 : 0,
                  top: _horizontal ? 0 : at - 2,
                  width: _horizontal ? 4 : constraints.maxWidth,
                  height: _horizontal ? constraints.maxHeight : 4,
                  child: IgnorePointer(
                    child: ColoredBox(color: colorScheme.primary),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

/// [main] next to or above a second, independently scrolled view of a note.
/// Fingers scroll that view. A stylus writes on it if [onDrawStart] is given.
/// ponytail: zoom buttons rather than a pinch, add one if the buttons feel slow.
class NoteSplitView extends StatefulWidget {
  const NoteSplitView({
    super.key,
    required this.axis,
    required this.main,
    this.paneFirst = false,
    required this.title,
    required this.pages,
    required this.canvasBuilder,
    required this.updatePointerData,
    required this.onDrawStart,
    required this.onDrawUpdate,
    required this.onDrawEnd,
    required this.onSwitch,
    required this.onFlip,
    required this.onClose,
  });

  /// [Axis.horizontal] is side by side.
  final Axis axis;
  final Widget main;

  /// Whether the second view goes left of or above [main], not after it.
  final bool paneFirst;
  final String title;
  final List<EditorPage> pages;

  /// Builds a page at its full size, without any scaling.
  final Widget Function(int pageIndex, double zoom) canvasBuilder;
  final void Function(PointerDeviceKind kind, double? pressure)
  updatePointerData;

  /// Null when the view can't be written on. Points are in page coordinates.
  final void Function(int pageIndex, Offset point)? onDrawStart;
  final ValueChanged<Offset> onDrawUpdate;
  final VoidCallback onDrawEnd;
  final VoidCallback onSwitch;
  final VoidCallback onFlip;
  final VoidCallback onClose;

  @override
  State<NoteSplitView> createState() => _NoteSplitViewState();
}

class _NoteSplitViewState extends State<NoteSplitView> {
  static const _zoomStep = 1.25;
  static const _maxZoom = 4.0;

  var _zoom = 1.0;
  var _drawing = false;

  @override
  Widget build(BuildContext context) => ResizableSplit(
    axis: widget.axis,
    main: widget.main,
    paneFirst: widget.paneFirst,
    onSwitch: widget.onSwitch,
    onFlip: widget.onFlip,
    onClose: widget.onClose,
    pane: ColoredBox(
      color: ColorScheme.of(context).surfaceContainerLow,
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          _buildBar(context),
          Expanded(child: _buildPages()),
        ],
      ),
    ),
  );

  Widget _buildBar(BuildContext context) {
    return Material(
      color: ColorScheme.of(context).surfaceContainerHighest,
      child: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.title,
              maxLines: 1,
              overflow: .ellipsis,
              style: TextTheme.of(context).labelMedium,
            ),
          ),
          IconButton(
            tooltip: 'Zoom out',
            visualDensity: .compact,
            icon: const Icon(Icons.remove, size: 20),
            onPressed: _zoom > 1
                ? () => setState(() => _zoom = max(_zoom / _zoomStep, 1))
                : null,
          ),
          IconButton(
            tooltip: 'Zoom in',
            visualDensity: .compact,
            icon: const Icon(Icons.add, size: 20),
            onPressed: _zoom < _maxZoom
                ? () => setState(() => _zoom = min(_zoom * _zoomStep, _maxZoom))
                : null,
          ),
          IconButton(
            tooltip: 'Close split view',
            visualDensity: .compact,
            icon: const Icon(Icons.close, size: 20),
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildPages() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth * _zoom;
        return ScrollConfiguration(
          // a stylus writes here, it doesn't scroll
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
            },
          ),
          child: SingleChildScrollView(
            scrollDirection: .horizontal,
            child: SizedBox(
              width: width,
              height: constraints.maxHeight,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: widget.pages.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildPage(i, width),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static bool _isStylus(PointerEvent event) =>
      event.kind == PointerDeviceKind.stylus ||
      event.kind == PointerDeviceKind.invertedStylus;

  void _sendPressure(PointerEvent event) {
    widget.updatePointerData(
      event.kind,
      event.pressureMin != event.pressureMax
          ? (event.pressure - event.pressureMin) /
                (event.pressureMax - event.pressureMin)
          : null,
    );
  }

  Widget _buildPage(int pageIndex, double width) {
    final page = widget.pages[pageIndex];
    final zoom = width / page.size.width;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) {
        final onDrawStart = widget.onDrawStart;
        if (onDrawStart == null || !_isStylus(event) || _drawing) return;
        _drawing = true;
        _sendPressure(event);
        onDrawStart(pageIndex, event.localPosition / zoom);
      },
      onPointerMove: (event) {
        if (!_drawing || !_isStylus(event)) return;
        _sendPressure(event);
        widget.onDrawUpdate(event.localPosition / zoom);
      },
      onPointerUp: (event) => _endDrawing(event),
      onPointerCancel: (event) => _endDrawing(event),
      child: IgnorePointer(
        child: SizedBox(
          width: width,
          height: page.size.height * zoom,
          child: FittedBox(
            fit: .fill,
            child: SizedBox.fromSize(
              size: page.size,
              child: widget.canvasBuilder(pageIndex, zoom),
            ),
          ),
        ),
      ),
    );
  }

  void _endDrawing(PointerEvent event) {
    if (!_drawing || !_isStylus(event)) return;
    _drawing = false;
    widget.updatePointerData(event.kind, null);
    widget.onDrawEnd();
  }
}
