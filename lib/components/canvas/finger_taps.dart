import 'package:flutter/gestures.dart';

/// Spots quick taps with two or three fingers at once, for undo and redo as
/// in other notes apps. Fed every pointer event on the canvas.
///
/// A tap counts when every finger lifts within [maxDuration] of the first one
/// touching down, none moved more than [slop], and no stylus was involved.
class FingerTaps {
  FingerTaps({required this.onTwoFingerTap, required this.onThreeFingerTap});

  final void Function() onTwoFingerTap;
  final void Function() onThreeFingerTap;

  static const maxDuration = Duration(milliseconds: 280);
  static const slop = 20.0;

  final _down = <int, Offset>{};
  var _most = 0;
  var _spoilt = false;
  Duration? _start;

  void handle(PointerEvent event) {
    if (event.kind != PointerDeviceKind.touch) {
      if (event is PointerDownEvent) _spoilt = true;
      return;
    }
    switch (event) {
      case PointerDownEvent():
        if (_down.isEmpty) {
          _start = event.timeStamp;
          _most = 0;
          _spoilt = false;
        }
        _down[event.pointer] = event.position;
        if (_down.length > _most) _most = _down.length;
      case PointerMoveEvent():
        final from = _down[event.pointer];
        if (from != null && (event.position - from).distance > slop) {
          _spoilt = true;
        }
      case PointerUpEvent() || PointerCancelEvent():
        if (_down.remove(event.pointer) == null) return;
        if (event is PointerCancelEvent) _spoilt = true;
        if (_down.isNotEmpty) return;
        final start = _start;
        final quick =
            start != null && event.timeStamp - start <= maxDuration;
        if (!_spoilt && quick) {
          if (_most == 2) onTwoFingerTap();
          if (_most == 3) onThreeFingerTap();
        }
      default:
        break;
    }
  }
}
