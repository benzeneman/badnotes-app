import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

/// Finds where the app lags on a real device, without a cable: frame
/// timings, how long the editor's own work took, and hangs, sent to
/// [url] every little while. Only timings and tool names are sent, never
/// what's in a note.
///
/// Only in a build made with `--dart-define=LAG_REPORT_URL=...`; otherwise
/// [enabled] is false and all of this is left out of the app.
abstract final class LagRecorder {
  static const url = String.fromEnvironment('LAG_REPORT_URL');
  static const enabled = url != '';

  /// What the user is doing now, e.g. 'ballpointPen', 'eraser precision',
  /// 'zoom'. Set by the editor.
  static var action = 'idle';

  /// The page shown and what's open over it (a dialog, a menu), e.g.
  /// '/home/recent + dialog', kept up by [observer].
  static var screen = '';

  /// Keeps [screen] up to date; given to the app's router.
  static final observer = _ScreenObserver();

  /// Where the app is, from the router: set by main.
  static String Function() location = () => '';

  /// [action], with the screen when nothing in particular is being done.
  static String get _doing => action == 'idle' ? 'idle @ $screen' : action;

  /// Strokes on the page being drawn on, and in the whole note.
  static var pageStrokes = 0;
  static var noteStrokes = 0;

  static final _session = DateTime.now().millisecondsSinceEpoch.toRadixString(
    36,
  );
  static final _clock = Stopwatch();
  static final _spans = <String, _Span>{};
  static final _events = <Map<String, Object?>>[];
  static final _stats = <String, _Stats>{};
  static var _sent = 0;
  static Timer? _actionTimer;

  static void start() {
    if (!enabled) return;
    _clock.start();
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    _watchForHangs();
    Timer.periodic(const Duration(seconds: 15), (_) => _send());
    _event('start', {
      'os': Platform.operatingSystemVersion,
      'screen': _screen(),
    });
  }

  /// Sets [action] for what's happening now; after [lasts] it goes back to
  /// idle, unless something else was set since.
  static void doing(String what, {Duration? lasts}) {
    if (!enabled) return;
    action = what;
    _actionTimer?.cancel();
    if (lasts != null) {
      _actionTimer = Timer(lasts, () => action = 'idle');
    }
  }

  /// The last step passed (see [step]), sent to the hang watchdog at once.
  static String _step = '';
  static SendPort? _toWatchdog;
  static bool _shown = true;

  /// Marks a step of work that might hold up the main thread: if the app
  /// hangs, the "stuck now" report names the last step reached.
  static void step(String what) {
    if (!enabled) return;
    _step = what;
    _toWatchdog?.send((action, pageStrokes, noteStrokes, _shown, what));
  }

  /// Times [run] as [name], counted with the frame it happens in.
  static T span<T>(String name, T Function() run) {
    if (!enabled) return run();
    final watch = Stopwatch()..start();
    try {
      return run();
    } finally {
      addSpan(name, watch.elapsedMicroseconds);
    }
  }

  static void addSpan(String name, int micros) {
    if (!enabled) return;
    (_spans[name] ??= _Span()).add(micros);
  }

  /// Something worth knowing happened, e.g. a note opened, with how long it
  /// took.
  static void note(String kind, Map<String, Object?> data) {
    if (!enabled) return;
    _event(kind, data);
  }

  static const _record = MethodChannel('badnotes/record');

  /// Starts a screen recording, after Android asks the user.
  /// Returns whether it started.
  static Future<bool> startRecording() async {
    try {
      final started = await _record.invokeMethod<bool>('start') ?? false;
      if (started) _event('recording started', {});
      return started;
    } catch (_) {
      return false;
    }
  }

  /// Stops the recording and uploads it next to the reports; [progress]
  /// gets how much is sent, 0 to 1. Returns whether it got there.
  static Future<bool> stopRecording(void Function(double) progress) async {
    String? path;
    try {
      path = await _record.invokeMethod<String>('stop');
    } catch (_) {}
    _event('recording stopped', {});
    _send();
    if (path == null) return false;
    final file = File(path);
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final length = await file.length();
      final uri = Uri.parse(url.replaceFirst('/lag/', '/video/'))
          .replace(queryParameters: {'session': _session});
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType('video', 'mp4');
      request.contentLength = length;
      var sent = 0;
      await request.addStream(
        file.openRead().map((chunk) {
          sent += chunk.length;
          progress(sent / length);
          return chunk;
        }),
      );
      final response = await request.close().timeout(
        const Duration(seconds: 60),
      );
      await response.drain<void>();
      return response.statusCode < 300;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
      try {
        await file.delete();
      } catch (_) {}
    }
  }

  /// The user felt a lag just now.
  static void mark() {
    _event('felt lag', {'spans': _topSpans()});
    _send();
  }

  static void _onTimings(List<FrameTiming> timings) {
    final spans = _topSpans();
    _spans.clear();
    for (final t in timings) {
      final build = t.buildDuration.inMicroseconds / 1000;
      final raster = t.rasterDuration.inMicroseconds / 1000;
      final total = t.totalSpan.inMicroseconds / 1000;
      (_stats[_doing] ??= _Stats()).add(build, raster);
      if (build > 20 || raster > 20) {
        _event('slow frame', {
          'build': build.toStringAsFixed(1),
          'raster': raster.toStringAsFixed(1),
          'total': total.toStringAsFixed(1),
          'spans': spans,
        });
      }
    }
  }

  static Map<String, String> _topSpans() {
    final sorted = _spans.entries.toList()
      ..sort((a, b) => b.value.micros.compareTo(a.value.micros));
    return {
      for (final e in sorted.take(8))
        e.key:
            '${e.value.count}x ${(e.value.micros / 1000).toStringAsFixed(1)}ms'
            ' (worst ${(e.value.worst / 1000).toStringAsFixed(1)})',
    };
  }

  static void _event(String kind, Map<String, Object?> data) {
    if (_events.length >= 400) _events.removeAt(0);
    _events.add({
      'at': (_clock.elapsedMilliseconds / 1000).toStringAsFixed(2),
      'kind': kind,
      'action': action,
      'screen': screen,
      'pageStrokes': pageStrokes,
      'noteStrokes': noteStrokes,
      ...data,
    });
  }

  /// A timer on the main thread, and another isolate watching it: a late
  /// tick is a hang, and a long one is sent from the other isolate while
  /// the main thread is still stuck, in case the app is closed for it.
  static void _watchForHangs() {
    final port = ReceivePort();
    Isolate.spawn(_watchdog, (port.sendPort, url, _session));
    port.listen((message) {
      if (message is SendPort) _toWatchdog = message;
    });
    var last = _clock.elapsedMilliseconds;
    // In the background Android can stop the app for a while: that's not a
    // hang, though it looked like one of 20 s when the app came back.
    AppLifecycleListener(
      onShow: () {
        _shown = true;
        last = _clock.elapsedMilliseconds;
      },
      onHide: () => _shown = false,
    );
    Timer.periodic(const Duration(milliseconds: 100), (_) {
      final now = _clock.elapsedMilliseconds;
      final gap = now - last;
      last = now;
      _toWatchdog?.send((action, pageStrokes, noteStrokes, _shown, _step));
      if (gap > 700 && _shown) {
        _event('hang', {'ms': gap, 'spans': _topSpans()});
        if (gap > 2000) _send();
      }
    });
  }

  static Future<void> _watchdog((SendPort, String, String) args) async {
    final (toMain, url, session) = args;
    final port = ReceivePort();
    toMain.send(port.sendPort);
    var lastSeen = DateTime.now();
    (String, int, int, bool, String)? last;
    var reported = false;
    port.listen((message) {
      lastSeen = DateTime.now();
      last = message as (String, int, int, bool, String);
      reported = false;
    });
    Timer.periodic(const Duration(milliseconds: 500), (_) {
      final stuck = DateTime.now().difference(lastSeen).inMilliseconds;
      if (stuck < 3000 || reported) return;
      reported = true;
      final (action, page, note, shown, step) = last ?? ('?', 0, 0, true, '');
      // stopped in the background, not stuck
      if (!shown) return;
      _post(url, {
        'session': session,
        'events': [
          {
            'kind': 'stuck now',
            'ms': stuck,
            'action': action,
            'step': step,
            'pageStrokes': page,
            'noteStrokes': note,
          },
        ],
      });
    });
  }

  static Map<String, Object?> _screen() {
    final view = PlatformDispatcher.instance.views.firstOrNull;
    if (view == null) return {};
    return {
      'size':
          '${view.physicalSize.width.round()}x${view.physicalSize.height.round()}',
      'ratio': view.devicePixelRatio,
      'hz': view.display.refreshRate.round(),
    };
  }

  static Future<void> _send() async {
    if (_events.isEmpty && _stats.isEmpty) return;
    final events = List.of(_events);
    _events.clear();
    final stats = {for (final e in _stats.entries) e.key: e.value.toJson()};
    _stats.clear();
    final ok = await _post(url, {
      'session': _session,
      'part': _sent++,
      'events': events,
      'frames': stats,
    });
    if (!ok && _events.length < 300) _events.insertAll(0, events);
  }

  static Future<bool> _post(String url, Map<String, Object?> body) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.postUrl(Uri.parse(url));
      request.headers.contentType = ContentType.json;
      request.add(utf8.encode(jsonEncode(body)));
      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );
      await response.drain<void>();
      return response.statusCode < 300;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  /// [app] with a small button to press when it lags.
  static Widget wrap(Widget app) {
    if (!enabled) return app;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          app,
          const Positioned(right: 6, top: 160, child: _LagButton()),
          const Positioned(right: 6, top: 200, child: _RecordButton()),
        ],
      ),
    );
  }
}

class _Span {
  var count = 0, micros = 0, worst = 0;
  void add(int us) {
    count++;
    micros += us;
    worst = math.max(worst, us);
  }
}

class _Stats {
  var frames = 0, slow = 0;
  final _build = <double>[], _raster = <double>[];
  void add(double build, double raster) {
    frames++;
    if (build > 16.7 || raster > 16.7) slow++;
    if (_build.length < 2000) {
      _build.add(build);
      _raster.add(raster);
    }
  }

  Map<String, Object?> toJson() {
    String pct(List<double> v, double p) {
      if (v.isEmpty) return '-';
      final s = List.of(v)..sort();
      return s[((s.length - 1) * p).round()].toStringAsFixed(1);
    }

    return {
      'frames': frames,
      'slow': slow,
      'build p50/p95/max':
          '${pct(_build, .5)}/${pct(_build, .95)}/${pct(_build, 1)}',
      'raster p50/p95/max':
          '${pct(_raster, .5)}/${pct(_raster, .95)}/${pct(_raster, 1)}',
    };
  }
}

class _LagButton extends StatefulWidget {
  const _LagButton();

  @override
  State<_LagButton> createState() => _LagButtonState();
}

class _LagButtonState extends State<_LagButton> {
  var _flash = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        LagRecorder.mark();
        setState(() => _flash = true);
        Timer(const Duration(milliseconds: 600), () {
          if (mounted) setState(() => _flash = false);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: (_flash ? Colors.green : Colors.red).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          _flash ? 'Sent' : 'Lag!',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

/// Starts a screen recording, and stops and uploads it: some lag only
/// shows in a video.
class _RecordButton extends StatefulWidget {
  const _RecordButton();

  @override
  State<_RecordButton> createState() => _RecordButtonState();
}

enum _Recording { off, starting, on, sending, sent, failed }

class _RecordButtonState extends State<_RecordButton> {
  var _state = _Recording.off;
  var _sent = 0.0;
  final _since = Stopwatch();
  Timer? _tick;

  Future<void> _tap() async {
    switch (_state) {
      case .off || .sent || .failed:
        setState(() => _state = .starting);
        final started = await LagRecorder.startRecording();
        if (!mounted) return;
        setState(() => _state = started ? .on : .off);
        if (started) {
          _since
            ..reset()
            ..start();
          _tick = Timer.periodic(
            const Duration(seconds: 1),
            (_) => setState(() {}),
          );
        }
      case .on:
        _tick?.cancel();
        _since.stop();
        setState(() {
          _state = .sending;
          _sent = 0;
        });
        final ok = await LagRecorder.stopRecording((sent) {
          if (mounted && (sent - _sent >= 0.01 || sent == 1)) {
            setState(() => _sent = sent);
          }
        });
        if (!mounted) return;
        setState(() => _state = ok ? .sent : .failed);
      case .starting || .sending:
        break;
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seconds = _since.elapsed.inSeconds;
    final (label, color) = switch (_state) {
      .off => ('Record', Colors.blueGrey),
      .starting => ('...', Colors.blueGrey),
      .on => (
        'Stop ${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
        Colors.red,
      ),
      .sending => ('Sending ${(_sent * 100).round()}%', Colors.orange),
      .sent => ('Video sent', Colors.green),
      .failed => ('Not sent', Colors.brown),
    };
    return GestureDetector(
      onTap: _tap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

/// Follows the routes pushed and popped, for [LagRecorder.screen].
class _ScreenObserver extends NavigatorObserver {
  final _over = <Route<dynamic>>[];

  void _update() {
    final names = [
      for (final route in _over)
        switch (route) {
          PopupRoute() when route.runtimeType.toString().contains('Dialog') =>
            'dialog',
          PopupRoute() => 'popup',
          _ => (route.settings.name ?? 'page').split('?').first,
        },
    ];
    final location = LagRecorder.location();
    LagRecorder.screen = [location, ...names].join(' + ');
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // pages pushed over the first (the editor) count too: the router's
    // location stayed the home screen's
    if (route is! PageRoute || previousRoute != null) _over.add(route);
    // the router's location changes just after a page is pushed
    scheduleMicrotask(_update);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _over.remove(route);
    scheduleMicrotask(_update);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _over.remove(route);
    scheduleMicrotask(_update);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) _over.remove(oldRoute);
    if (newRoute != null && newRoute is! PageRoute) _over.add(newRoute);
    scheduleMicrotask(_update);
  }
}

/// What the pointers of a stroke said about pressure, as the device gave
/// it: for the lag report, to tell whether the pen sends any.
abstract final class PointerPressureLog {
  static var _rawLow = double.infinity, _rawHigh = -1.0;
  static double? _min, _max;
  static String? _kind;
  static var _count = 0;

  static void see(PointerEvent event) {
    if (!LagRecorder.enabled) return;
    _count++;
    _kind = event.kind.name;
    _min = event.pressureMin;
    _max = event.pressureMax;
    _rawLow = math.min(_rawLow, event.pressure);
    _rawHigh = math.max(_rawHigh, event.pressure);
  }

  /// The stroke's numbers, then forgets them.
  static Map<String, Object?> take() {
    final out = {
      'pointer': _kind,
      'events': _count,
      'raw low': _rawLow.isFinite ? _rawLow : null,
      'raw high': _rawHigh >= 0 ? _rawHigh : null,
      'range': _min == null ? null : '$_min-$_max',
    };
    _rawLow = double.infinity;
    _rawHigh = -1;
    _min = _max = _kind = null;
    _count = 0;
    return out;
  }
}
