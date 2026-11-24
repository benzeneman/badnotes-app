import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:badnotes/components/canvas/hud/canvas_gesture_lock_btn.dart';
import 'package:badnotes/components/canvas/hud/canvas_zoom_indicator.dart';
import 'package:badnotes/data/extensions/matrix4_extensions.dart';
import 'package:badnotes/i18n/strings.g.dart';

/// How long the overlay stays up after the page last moved.
const _visibleFor = Duration(seconds: 5);

/// How long the overlay takes to appear or disappear.
const _fadeTime = Duration(milliseconds: 200);

/// Small floating controls on top of the canvas: the zoom lock, the
/// straight-line pan lock and the zoom level.
///
/// They pop up whenever the page is panned or zoomed and quietly fade away
/// once the page has been still for a few seconds. While faded they let
/// touches fall through to the canvas.
class const CanvasHud({
  super.key,
  required final TransformationController transformationController,
  required final bool zoomLock,
  required final ValueChanged<bool> setZoomLock,
  required final VoidCallback? resetZoom,
  required final bool singleFingerPanLock,
  required final ValueChanged<bool> setSingleFingerPanLock,
  required final bool axisAlignedPanLock,
  required final ValueChanged<bool> setAxisAlignedPanLock,
}) extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final shown = useState(false);
    final fadeOut = useRef<Timer?>(null);
    useEffect(
      () =>
          () => fadeOut.value?.cancel(),
      const [],
    );

    useOnListenableChange(transformationController, () {
      shown.value = true;
      fadeOut.value?.cancel();
      fadeOut.value = Timer(_visibleFor, () => shown.value = false);
    });

    return IgnorePointer(
      ignoring: !shown.value,
      child: AnimatedOpacity(
        opacity: shown.value ? 1 : 0,
        duration: _fadeTime,
        child: Stack(
          children: [_zoomLockButton(), _straightPanButton(), _zoomLevel()],
        ),
      ),
    );
  }

  Widget _zoomLockButton() => Positioned(
    left: 5,
    top: 5,
    child: CanvasGestureLockBtn(
      lock: zoomLock,
      setLock: setZoomLock,
      icon: zoomLock ? Icons.lock : Icons.lock_open,
      tooltip: zoomLock ? t.editor.hud.unlockZoom : t.editor.hud.lockZoom,
    ),
  );

  /// Sits just under the zoom lock. The hand icon tilts while panning is
  /// free and stands upright once panning sticks to one axis.
  Widget _straightPanButton() => Positioned(
    left: 5,
    top: 45,
    child: CanvasGestureLockBtn(
      lock: axisAlignedPanLock,
      setLock: setAxisAlignedPanLock,
      tooltip: axisAlignedPanLock
          ? t.editor.hud.unlockAxisAlignedPan
          : t.editor.hud.lockAxisAlignedPan,
      child: AnimatedRotation(
        turns: axisAlignedPanLock ? 0 : 1 / 8,
        duration: _fadeTime,
        child: const Icon(Symbols.drag_pan),
      ),
    ),
  );

  Widget _zoomLevel() => Positioned(
    right: 5,
    top: 5,
    child: AnimatedBuilder(
      animation: transformationController,
      builder: (context, _) => CanvasZoomIndicator(
        scale: transformationController.value.approxScale,
        resetZoom: resetZoom,
      ),
    ),
  );
}
