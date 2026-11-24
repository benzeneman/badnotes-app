import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:record/record.dart';
import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';

/// One audio recording attached to a note, with the time (ms from the start
/// of the recording) at which each stroke was written.
class AudioRecording {
  AudioRecording(
    this.fileName,
    this.durationMs,
    this.marks, [
    this.starts = const {},
    this.times = const {},
    this.createdAtMs = 0,
  ]);

  /// The audio file next to the note, or empty when only the writing was
  /// recorded (design: Record with audio off).
  final String fileName;
  final int durationMs;

  /// When it was recorded, ms since the epoch; 0 if not known.
  final int createdAtMs;

  bool get hasAudio => fileName.isNotEmpty;

  /// Stroke key (see [AudioNotes.strokeKey]) -> ms into the recording when
  /// the stroke was finished.
  final Map<String, int> marks;

  /// Stroke key -> ms when the pen went down for it, so playback can draw
  /// it at the speed it was written. Missing in older recordings.
  final Map<String, int> starts;

  /// Stroke key -> when each of its points was drawn, in ms from its start:
  /// every movement of the pen, so it's written again just as it was.
  /// Missing in older recordings.
  final Map<String, List<int>> times;

  /// How much of the stroke with [key] was drawn [ms] into the recording,
  /// from 0 to 1, given it has [points] points.
  double partAt(String key, int points, int ms) {
    final start = startOf(key);
    final end = marks[key] ?? start;
    if (ms >= end) return 1;
    if (ms < start) return 0;
    final t = times[key];
    if (t != null && t.length == points && points > 1) {
      // the last point drawn by then
      var lo = 0, hi = t.length - 1;
      while (lo < hi) {
        final mid = (lo + hi + 1) >> 1;
        if (start + t[mid] <= ms) {
          lo = mid;
        } else {
          hi = mid - 1;
        }
      }
      return (lo + 1) / points;
    }
    return end <= start ? 1 : (ms - start) / (end - start);
  }

  /// How long a stroke from before [starts] were kept is drawn for, ending
  /// when it was finished.
  static const _guessedMs = 450;

  /// When the stroke with [key] was started, in ms.
  int startOf(String key) {
    final end = marks[key] ?? 0;
    return starts[key] ?? (end - _guessedMs).clamp(0, end);
  }

  Map<String, dynamic> toJson() => {
    'file': fileName,
    'durationMs': durationMs,
    'marks': marks,
    if (starts.isNotEmpty) 'starts': starts,
    if (times.isNotEmpty) 'times': times,
    if (createdAtMs != 0) 'at': createdAtMs,
  };

  static AudioRecording fromJson(Map<String, dynamic> j) => AudioRecording(
    j['file'] as String,
    j['durationMs'] as int,
    (j['marks'] as Map).map((k, v) => MapEntry(k as String, v as int)),
    (j['starts'] as Map? ?? const {}).map(
      (k, v) => MapEntry(k as String, v as int),
    ),
    (j['times'] as Map? ?? const {}).map(
      (k, v) => MapEntry(k as String, [for (final t in v as List) t as int]),
    ),
    j['at'] as int? ?? 0,
  );
}

/// Records audio while you write and plays it back from any stroke
/// (Notability/GoodNotes-style audio sync).
///
/// Files live next to the note: `<note>.audio.json` and `<note>.recN.m4a`.
// ponytail: strokes are matched by page + first point, so strokes moved after
// recording lose their sync. Store an id inside the stroke if that matters.
class AudioNotes extends ChangeNotifier {
  AudioNotes(this.notePath) {
    _load();
    _subscriptions.addAll([
      player.onPositionChanged.listen((at) {
        if (!_playingAudio) return;
        position.value = at;
        _follow();
      }),
      player.onPlayerStateChanged.listen((state) {
        if (!_playingAudio) return;
        playing.value = state == PlayerState.playing;
        // paused, the ink stays where the voice is; over, it all shows
        if (state == PlayerState.completed || state == PlayerState.stopped) {
          playbackAt.value = null;
        }
      }),
    ]);
  }

  // ---- playing: the audio, or a clock for a recording without audio ----

  /// Where the recording being played is.
  final position = ValueNotifier(Duration.zero);

  /// Whether it's playing now (not paused or over).
  final playing = ValueNotifier(false);

  /// How fast it plays: 0.5 to 2.
  double get speed => _speed;
  double _speed = 1;

  bool get _playingAudio {
    final index = playingIndex;
    return index != null &&
        index < recordings.length &&
        recordings[index].hasAudio;
  }

  Timer? _clock;
  DateTime _clockFrom = DateTime.now();
  Duration _clockBase = Duration.zero;

  void _follow() {
    final index = playingIndex;
    if (index == null || index >= recordings.length) return;
    playbackAt.value = (recording: index, ms: position.value.inMilliseconds);
  }

  void _startClock() {
    _clock?.cancel();
    _clockFrom = DateTime.now();
    _clockBase = position.value;
    playing.value = true;
    _clock = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final index = playingIndex;
      if (index == null) return _stopClock();
      final total = Duration(milliseconds: recordings[index].durationMs);
      final now = _clockBase + DateTime.now().difference(_clockFrom) * _speed;
      if (now >= total) {
        position.value = total;
        _stopClock();
        playbackAt.value = null;
        return;
      }
      position.value = now;
      _follow();
    });
  }

  void _stopClock() {
    _clock?.cancel();
    _clock = null;
    playing.value = false;
  }

  Future<void> pause() async {
    if (_playingAudio) return player.pause();
    _stopClock();
  }

  Future<void> resume() async {
    final index = playingIndex;
    if (index == null) return;
    // over: from the start again
    if (playbackAt.value == null) {
      return play(index);
    }
    if (_playingAudio) return player.resume();
    _startClock();
  }

  Future<void> seek(Duration to) async {
    final index = playingIndex;
    if (index == null) return;
    final total = recordings[index].durationMs;
    final at = Duration(milliseconds: to.inMilliseconds.clamp(0, total));
    position.value = at;
    _follow();
    if (_playingAudio) return player.seek(at);
    if (_clock != null) _startClock();
  }

  Future<void> setSpeed(double speed) async {
    _speed = speed;
    if (_playingAudio) await player.setPlaybackRate(speed);
    if (_clock != null) _startClock();
    notifyListeners();
  }

  final _subscriptions = <StreamSubscription<Object?>>[];

  /// Where a recording being played is (which one, and ms into it), or null:
  /// the ink written during it follows the voice, each stroke showing once
  /// the voice reaches the moment it was written, as in GoodNotes.
  final playbackAt = ValueNotifier<({int recording, int ms})?>(null);

  /// Which of [strokes] show at [at]: those written by then in that
  /// recording, and all those not written during it.
  Set<Stroke> shownAt(List<Stroke> strokes, ({int recording, int ms}) at) =>
      strokesShownAt(strokes, recordings[at.recording].marks, at.ms);

  /// Which of [strokes] show [ms] into a recording with [marks].
  static Set<Stroke> strokesShownAt(
    List<Stroke> strokes,
    Map<String, int> marks,
    int ms,
  ) => {
    for (final stroke in strokes)
      if (stroke.points.isEmpty || (marks[strokeKey(stroke)] ?? -1) <= ms)
        stroke,
  };

  String notePath;
  final log = Logger('AudioNotes');
  final _recorder = AudioRecorder();
  final player = AudioPlayer();

  final recordings = <AudioRecording>[];
  bool get isRecording => _recordingStart != null;
  DateTime? _recordingStart;
  String? _recordingFile;

  /// When the recording going now began, for its timer.
  DateTime? get recordingSince => _recordingStart;

  /// How the recording going now takes its sound: by [_recorder] (the
  /// microphone), by [DeviceAudio] (the device's sound, with the mic too
  /// if asked), or none (only the writing).
  _Source _source = _Source.none;
  bool get recordsAudio => _source != _Source.none;
  final _pendingMarks = <Stroke, int>{};
  final _pendingStarts = <Stroke, int>{};
  final _pendingTimes = <Stroke, List<int>>{};

  /// When each point of the stroke being written was drawn, in ms.
  final _pointTimes = <int>[];

  /// When the pen went down for the stroke being written, in ms.
  int? _strokeStart;

  /// Index into [recordings] of the one loaded in [player], if any.
  int? playingIndex;

  String get _indexPath => '$notePath.audio.json';
  String _absolute(String fileName) {
    final dir = notePath.substring(0, notePath.lastIndexOf('/') + 1);
    return FileManager.getFile('$dir$fileName').path;
  }

  static String strokeKey(Stroke s) {
    final p = s.points.first;
    return '${s.pageIndex}:${p.x.toStringAsFixed(1)},${p.y.toStringAsFixed(1)}';
  }

  Future<void> _load() async {
    try {
      final file = FileManager.getFile(_indexPath);
      if (!file.existsSync()) return;
      final list = jsonDecode(await file.readAsString()) as List;
      recordings
        ..clear()
        ..addAll(list.map((j) => AudioRecording.fromJson(j)));
      notifyListeners();
    } catch (e) {
      log.warning('Could not read audio index', e);
    }
  }

  Future<void> _save() async {
    final file = FileManager.getFile(_indexPath);
    await file.writeAsString(
      jsonEncode([for (final r in recordings) r.toJson()]),
    );
  }

  /// Starts recording the writing and, if [audio], sound: the [mic], the
  /// [device]'s own sound, or both. Returns why it couldn't, or null.
  Future<String?> startRecording({
    bool audio = true,
    bool mic = true,
    bool device = false,
  }) async {
    if (isRecording) return null;
    await stopPlayback();
    _pendingMarks.clear();
    _pendingStarts.clear();
    _pendingTimes.clear();
    if (!audio || (!mic && !device)) {
      _source = _Source.none;
      _recordingFile = '';
      _recordingStart = DateTime.now();
      notifyListeners();
      return null;
    }
    if (mic && !await _recorder.hasPermission()) {
      return 'The microphone permission is needed to record sound';
    }
    final name = notePath.substring(notePath.lastIndexOf('/') + 1);
    var n = recordings.length + 1;
    while (FileManager.getFile(
      '${notePath.substring(0, notePath.lastIndexOf('/') + 1)}$name.rec$n.m4a',
    ).existsSync()) {
      n++;
    }
    _recordingFile = '$name.rec$n.m4a';
    if (device) {
      final started = await DeviceAudio.start(
        _absolute(_recordingFile!),
        mic: mic,
      );
      if (started != null) {
        _recordingFile = null;
        return started;
      }
      _source = _Source.device;
      _recordingStart = DateTime.now();
      notifyListeners();
      return null;
    }
    _source = _Source.mic;
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        // camcorder is a "privacy sensitive" source on Android 10+, so we
        // keep the mic even while a screen recorder is running
        androidConfig: AndroidRecordConfig(
          audioSource: AndroidAudioSource.camcorder,
        ),
      ),
      path: _absolute(_recordingFile!),
    );
    _recordingStart = DateTime.now();
    notifyListeners();
    return null;
  }

  /// True if the mic delivers only silence, e.g. another app holds it.
  Future<bool> isSilent() async {
    if (!isRecording || _source != _Source.mic) return false;
    final amp = await _recorder.getAmplitude();
    return amp.max <= -100 || amp.current <= -100;
  }

  Future<void> stopRecording() async {
    if (!isRecording) return;
    switch (_source) {
      case _Source.mic:
        await _recorder.stop();
      case _Source.device:
        await DeviceAudio.stop();
      case _Source.none:
        break;
    }
    _source = _Source.none;
    final duration = DateTime.now().difference(_recordingStart!);
    final marks = <String, int>{
      for (final e in _pendingMarks.entries)
        if (e.key.points.isNotEmpty) strokeKey(e.key): e.value,
    };
    final starts = <String, int>{
      for (final e in _pendingStarts.entries)
        if (!e.key.isEmpty) strokeKey(e.key): e.value,
    };
    final times = <String, List<int>>{
      for (final e in _pendingTimes.entries)
        if (!e.key.isEmpty) strokeKey(e.key): e.value,
    };
    recordings.add(
      AudioRecording(
        _recordingFile!,
        duration.inMilliseconds,
        marks,
        starts,
        times,
        _recordingStart!.millisecondsSinceEpoch,
      ),
    );
    _pendingStarts.clear();
    _pendingTimes.clear();
    _recordingStart = null;
    _recordingFile = null;
    _pendingMarks.clear();
    notifyListeners();
    await _save();
  }

  /// Call when the pen goes down, so the stroke's start is known.
  void onStrokeStarted() {
    if (!isRecording) return;
    _strokeStart = DateTime.now().difference(_recordingStart!).inMilliseconds;
    _pointTimes
      ..clear()
      ..add(0);
  }

  /// Call as the pen moves, so every point's time is kept.
  void onPointAdded() {
    final start = _strokeStart;
    if (!isRecording || start == null) return;
    _pointTimes.add(
      DateTime.now().difference(_recordingStart!).inMilliseconds - start,
    );
  }

  /// Call when a stroke is finished so it can be synced to the audio.
  void onStrokeAdded(Stroke stroke) {
    if (!isRecording) return;
    final now = DateTime.now().difference(_recordingStart!).inMilliseconds;
    _pendingMarks[stroke] = now;
    _pendingStarts[stroke] = (_strokeStart ?? now).clamp(0, now);
    // as many times as points; a stroke snapped to a shape has other points
    if (_pointTimes.length == stroke.length) {
      _pendingTimes[stroke] = List.of(_pointTimes);
    }
    _pointTimes.clear();
    _strokeStart = null;
  }

  /// The strokes being written at [at]: each with how much of it is drawn
  /// by then, from 0 to 1.
  List<(Stroke, double)> writingAt(
    List<Stroke> strokes,
    ({int recording, int ms}) at,
  ) {
    final recording = recordings[at.recording];
    return [
      for (final stroke in strokes)
        if (!stroke.isEmpty)
          if (recording.marks[strokeKey(stroke)] case final end?
              when end > at.ms)
            if (recording.startOf(strokeKey(stroke)) case final start
                when start <= at.ms)
              (
                stroke,
                recording.partAt(strokeKey(stroke), stroke.length, at.ms),
              ),
    ];
  }

  /// Stops playing: the ink shows as it is again.
  Future<void> stopPlayback() async {
    _stopClock();
    if (_playingAudio) await player.stop();
    playingIndex = null;
    playing.value = false;
    position.value = Duration.zero;
    playbackAt.value = null;
    notifyListeners();
  }

  Future<void> play(int index, [Duration from = Duration.zero]) async {
    _stopClock();
    if (_playingAudio && playingIndex != index) await player.stop();
    playingIndex = index;
    position.value = from;
    notifyListeners();
    _follow();
    if (recordings[index].hasAudio) {
      await player.play(
        DeviceFileSource(_absolute(recordings[index].fileName)),
        position: from,
      );
      await player.setPlaybackRate(_speed);
    } else {
      _startClock();
    }
  }

  /// Plays from the earliest moment any of [strokes] was written.
  /// Returns false if none of them were written during a recording.
  Future<bool> playFrom(List<Stroke> strokes) async {
    for (var i = recordings.length - 1; i >= 0; i--) {
      int? earliest;
      for (final s in strokes) {
        if (s.points.isEmpty) continue;
        final t = recordings[i].marks[strokeKey(s)];
        if (t != null && (earliest == null || t < earliest)) earliest = t;
      }
      if (earliest != null) {
        // start a moment early so the first word isn't cut off
        final from = Duration(
          milliseconds: (earliest - 1500).clamp(0, 1 << 31),
        );
        await play(i, from);
        return true;
      }
    }
    return false;
  }

  Future<void> deleteRecording(int index) async {
    if (playingIndex == index) {
      await player.stop();
      playingIndex = null;
      playbackAt.value = null;
    }
    final r = recordings.removeAt(index);
    try {
      await FileManager.getFile(
        '${notePath.substring(0, notePath.lastIndexOf('/') + 1)}${r.fileName}',
      ).delete();
    } catch (_) {}
    notifyListeners();
    await _save();
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _stopClock();
    playbackAt.dispose();
    position.dispose();
    playing.dispose();
    if (isRecording) unawaited(stopRecording());
    _recorder.dispose();
    player.dispose();
    super.dispose();
  }
}

/// Bottom sheet listing a note's recordings with play/pause and a seek bar.
Future<void> showRecordingsSheet(BuildContext context, AudioNotes audio) {
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (context) => ListenableBuilder(
      listenable: audio,
      builder: (context, _) {
        if (audio.recordings.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Text(
              'No recordings yet. Tap the mic to record while you write.',
              textAlign: TextAlign.center,
            ),
          );
        }
        return ListView(
          shrinkWrap: true,
          children: [
            for (var i = 0; i < audio.recordings.length; i++)
              _RecordingTile(audio: audio, index: i),
            const SizedBox(height: 16),
          ],
        );
      },
    ),
  );
}

class _RecordingTile extends StatelessWidget {
  const _RecordingTile({required this.audio, required this.index});
  final AudioNotes audio;
  final int index;

  static String _fmt(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final r = audio.recordings[index];
    final total = Duration(milliseconds: r.durationMs);
    final isCurrent = audio.playingIndex == index;
    return StreamBuilder<PlayerState>(
      stream: audio.player.onPlayerStateChanged,
      initialData: audio.player.state,
      builder: (context, stateSnap) {
        final playing = isCurrent && stateSnap.data == PlayerState.playing;
        return Column(
          children: [
            ListTile(
              leading: IconButton.filledTonal(
                icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                onPressed: () {
                  if (playing) {
                    audio.player.pause();
                  } else if (isCurrent &&
                      stateSnap.data == PlayerState.paused) {
                    audio.player.resume();
                  } else {
                    audio.play(index);
                  }
                },
              ),
              title: Text('Recording ${index + 1}'),
              subtitle: Text(
                '${_fmt(total)} · ${r.marks.length} synced strokes',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Delete recording',
                onPressed: () => audio.deleteRecording(index),
              ),
            ),
            if (isCurrent)
              StreamBuilder<Duration>(
                stream: audio.player.onPositionChanged,
                builder: (context, posSnap) {
                  final pos = posSnap.data ?? Duration.zero;
                  final max = total.inMilliseconds.toDouble().clamp(
                    1.0,
                    double.infinity,
                  );
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(_fmt(pos)),
                        Expanded(
                          child: Slider(
                            value: pos.inMilliseconds.toDouble().clamp(0, max),
                            max: max,
                            onChanged: (v) => audio.player.seek(
                              Duration(milliseconds: v.round()),
                            ),
                          ),
                        ),
                        Text(_fmt(total)),
                      ],
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

/// The note's recordings, with a Record button under them: for the Audio
/// tab of the pages sidebar.
class RecordingsList extends StatelessWidget {
  const RecordingsList({
    super.key,
    required this.audio,
    required this.toggleRecording,
  });

  final AudioNotes audio;
  final VoidCallback toggleRecording;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    return ListenableBuilder(
      listenable: audio,
      builder: (context, _) => Column(
        children: [
          Expanded(
            child: audio.recordings.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No recordings yet. Record while you write, then play '
                        'it back with the ink.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView(
                    children: [
                      for (var i = 0; i < audio.recordings.length; i++)
                        _RecordingTile(audio: audio, index: i),
                    ],
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: audio.isRecording
                      ? colorScheme.error
                      : const Color(0xFF3896E1),
                ),
                onPressed: toggleRecording,
                icon: Icon(audio.isRecording ? Icons.stop : Icons.mic_none),
                label: Text(audio.isRecording ? 'Stop' : 'Record'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _Source { none, mic, device }

/// The device's own sound (and the microphone with it), recorded on
/// Android 10 and later by the app's own code: the screen-capture
/// permission is asked for each time.
abstract final class DeviceAudio {
  static const _channel = MethodChannel('badnotes/device_audio');

  /// Starts recording to [path] (AAC in .m4a); null if it started, else why
  /// it didn't.
  static Future<String?> start(String path, {required bool mic}) async {
    try {
      final ok = await _channel.invokeMethod<bool>('start', {
        'path': path,
        'mic': mic,
      });
      return ok ?? false
          ? null
          : 'Recording the device\'s sound wasn\'t allowed';
    } on MissingPluginException {
      return 'Recording the device\'s sound needs Android 10 or later';
    } on PlatformException catch (e) {
      return e.message ?? 'Could not record the device\'s sound';
    }
  }

  static Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stop');
    } on MissingPluginException {
      // never started
    }
  }
}
