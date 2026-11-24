import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:badnotes/data/prefs.dart';

/// Ignores the hand resting on the screen while writing with a stylus.
///
/// A palm touching down during a stroke used to join the gesture: the stroke
/// jumped to between the pen and the palm, or turned into a zoom, and the
/// palm's missing pressure made the line go thin. While a stylus is on the
/// screen, hovering over it, or was lifted moments ago, touches are left out.
/// How long, and more, is in the settings ([stows.palmRejection] and on).
abstract final class PalmRejection {
  /// How long after the stylus lifts touches are still ignored: the side of
  /// the hand often lands or lifts just after the pen does.
  static Duration get afterLift =>
      Duration(milliseconds: stows.palmAfterLiftMs.value);

  /// How long after the stylus lifts touches where the writing hand rests
  /// ([inHandZone]) are still ignored: no longer than elsewhere (the user
  /// found longer got in the way of scrolling with a finger).
  static const afterLiftNearHand = Duration(milliseconds: 400);

  /// A touch this big (radius, logical pixels) is a palm, not a finger.
  static const bigTouchRadius = 25.0;

  static final _stylusDown = <int>{};
  static Duration? _lastStylusEvent;
  static Offset? _lastStylusPosition;

  /// Touches down now that weren't ignored, by pointer.
  static final _touchesDown = <int>{};

  /// Touches found to be a palm by their size, ignored until they lift.
  static final _bigTouches = <int>{};

  /// Test mode, for this session: [ignoredTouches] collects the touches
  /// ignored, to show where they were.
  static final showIgnored = ValueNotifier(false);

  /// Where touches were ignored (global positions) in the last 2 seconds,
  /// while [showIgnored] is on.
  static final ignoredTouches = ValueNotifier<List<Offset>>(const []);

  static bool isStylus(PointerEvent event) =>
      event.kind == PointerDeviceKind.stylus ||
      event.kind == PointerDeviceKind.invertedStylus;

  /// Notes where the stylus is. Call with every pointer event on the canvas,
  /// hovering included.
  static void track(PointerEvent event) {
    if (event.kind == PointerDeviceKind.touch &&
        (event is PointerUpEvent || event is PointerCancelEvent)) {
      _touchesDown.remove(event.pointer);
      // a palm's lift is ignored too: [rejects] forgets it then
      if (event is PointerCancelEvent) _bigTouches.remove(event.pointer);
    }
    if (!isStylus(event)) return;
    if (event is PointerDownEvent) {
      _stylusDown.add(event.pointer);
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      _stylusDown.remove(event.pointer);
    }
    _lastStylusEvent = event.timeStamp;
    _lastStylusPosition = event.position;
  }

  /// Whether [event] is a touch that should be ignored.
  static bool rejects(PointerEvent event) {
    if (event.kind != PointerDeviceKind.touch) return false;
    final rejected = _rejects(event);
    if (!rejected && event is PointerDownEvent) {
      _touchesDown.add(event.pointer);
    }
    return rejected;
  }

  static bool _rejects(PointerEvent event) {
    // a finger already down that wasn't ignored: this one is likely the
    // second finger of a pinch, which the hand and size checks leave alone
    final pinching =
        stows.palmTwoFingersZoom.value &&
        _touchesDown.any((pointer) => pointer != event.pointer);
    if (_bigTouches.contains(event.pointer)) {
      if (event is PointerUpEvent) _bigTouches.remove(event.pointer);
      return true;
    }
    if (!pinching && stows.palmIgnoreBigTouches.value && isBig(event)) {
      _bigTouches.add(event.pointer);
      return true;
    }

    if (!stows.palmRejection.value) return false;
    final last = _lastStylusEvent;
    if (last == null) return false;
    final since = event.timeStamp - last;
    // a clock going backwards (as in tests) doesn't count as recent
    if (since < Duration.zero) return false;
    // A stylus held still still sends moves. Nothing for this long means its
    // lift was missed, which mustn't leave fingers ignored for good.
    if (since > _stuck) _stylusDown.clear();
    if (_stylusDown.isNotEmpty || since < afterLift) return true;
    final pen = _lastStylusPosition;
    return !pinching &&
        since < afterLiftNearHand &&
        pen != null &&
        inHandZone(event.position, pen, leftHanded: stows.leftHanded.value);
  }

  static const _stuck = Duration(seconds: 5);

  /// Whether [touch] is where the writing hand rests for a pen at [pen]: on
  /// the hand's side of it and below, within a hand's reach.
  // ponytail: a fixed box in logical pixels, not scaled to the screen or
  // the hand; tune the numbers if palms land outside it.
  static bool inHandZone(Offset touch, Offset pen, {required bool leftHanded}) {
    final across = leftHanded ? pen.dx - touch.dx : touch.dx - pen.dx;
    final down = touch.dy - pen.dy;
    return across > -40 && across < 350 && down > -80 && down < 350;
  }

  /// Whether [event] is a palm by its size, when the device says how big
  /// touches are.
  static bool isBig(PointerEvent event) => event.radiusMajor > bigTouchRadius;

  /// Shows [event] in [ignoredTouches] for 2 seconds, in test mode. Call
  /// once per ignored touch.
  static void noteIgnored(PointerEvent event) {
    if (!showIgnored.value || event is! PointerDownEvent) return;
    final position = event.position;
    ignoredTouches.value = [...ignoredTouches.value, position];
    Timer(const Duration(seconds: 2), () {
      ignoredTouches.value = [
        for (final p in ignoredTouches.value)
          if (!identical(p, position)) p,
      ];
    });
  }

  /// Forgets the stylus, for tests.
  static void reset() {
    _stylusDown.clear();
    _touchesDown.clear();
    _bigTouches.clear();
    _lastStylusEvent = null;
    _lastStylusPosition = null;
  }
}

/// A [ScaleGestureRecognizer] that doesn't take part in [PalmRejection]'s
/// rejected touches, so a palm can't turn a stroke into a zoom or move it.
class PalmRejectingScaleGestureRecognizer extends ScaleGestureRecognizer {
  new({super.debugOwner});

  @override
  bool isPointerAllowed(PointerDownEvent event) =>
      !PalmRejection.rejects(event) && super.isPointerAllowed(event);
}
