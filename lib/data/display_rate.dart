import 'dart:io';
import 'dart:ui';

import 'package:badnotes/data/lag_recorder.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

/// Holds a fast panel (90 Hz and up) at 60 Hz outside the editor when the
/// GPU can't keep up with it.
///
/// A perfetto trace of a Moto Pad 60 Neo (Mali, 2560x1600 at 90 Hz) showed
/// 12-20 ms of GPU work a frame on the home screen and its dialogs: frames
/// came at 45 one moment and 90 the next, which looks like a stutter. At an
/// even 60 they don't. The editor keeps the full rate, for the pen.
abstract final class DisplayRate {
  static const _channel = MethodChannel('badnotes/display');

  /// How many editors are open: while any is, the full rate.
  static var _editors = 0;

  /// Measured too slow for the panel: stays so until the app restarts.
  static var _slow = false;
  static final _rasters = <int>[];

  static void init() {
    if (!Platform.isAndroid) return;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
  }

  static void editorOpened() {
    _editors++;
    _apply();
  }

  static void editorClosed() {
    if (_editors > 0) _editors--;
    _apply();
  }

  static void _onTimings(List<FrameTiming> timings) {
    if (_slow || _editors > 0) return;
    final hz =
        PlatformDispatcher.instance.views.firstOrNull?.display.refreshRate;
    if (hz == null || hz < 75) return;
    for (final t in timings) {
      _rasters.add(t.rasterDuration.inMicroseconds);
    }
    // ponytail: one verdict from the first 120 busy frames, a rolling
    // window if a device turns out to swing between the two
    if (_rasters.length < 120) return;
    _rasters.sort();
    final median = _rasters[_rasters.length ~/ 2];
    _rasters.clear();
    if (median > 0.85 * 1e6 / hz) {
      _slow = true;
      LagRecorder.note('display 60 Hz', {
        'panelHz': hz,
        'rasterMedianUs': median,
      });
      _apply();
    }
  }

  static void _apply() {
    if (!Platform.isAndroid) return;
    final hz = _slow && _editors == 0 ? 60.0 : 0.0;
    _channel.invokeMethod<void>('setRate', {'hz': hz}).ignore();
  }
}
