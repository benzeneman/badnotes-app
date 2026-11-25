import 'dart:async';
import 'dart:io';

import 'package:badnotes/data/pro/pro.dart';
import 'package:badnotes/components/editor/audio_notes.dart';
import 'package:badnotes/components/editor_ui/option_previews.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:flutter/material.dart';

/// What a new recording takes, as chosen.
typedef RecordingChoice = ({bool audio, bool mic, bool device});

/// Before recording (the toolbar's Record): sound on or off, and from the
/// microphone, the device's own sound, or both. Null if cancelled.
Future<RecordingChoice?> showRecordingOptions(BuildContext context) =>
    showGeneralDialog<RecordingChoice>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close',
      barrierColor: BadNotesColors.of(context).scrim,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, _, _) => const _RecordingOptions(),
      transitionBuilder: (context, animation, _, child) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: 0.96, end: 1.0).animate(animation),
          child: child,
        ),
      ),
    );

class _RecordingOptions extends StatefulWidget {
  const _RecordingOptions();

  @override
  State<_RecordingOptions> createState() => _RecordingOptionsState();
}

class _RecordingOptionsState extends State<_RecordingOptions> {
  var _audio = stows.recordAudio.value;
  var _mic = stows.recordMic.value;
  var _device = stows.recordDevice.value;

  /// The device's sound can be recorded on Android 10 and later only.
  static bool get _deviceAvailable => Platform.isAndroid;

  void _start() {
    // at least one source when sound is on
    if (_audio && !_mic && !_device) _mic = true;
    stows.recordAudio.value = _audio;
    stows.recordMic.value = _mic;
    stows.recordDevice.value = _device;
    Navigator.of(context).pop((audio: _audio, mic: _mic, device: _device));
  }

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    Widget source(
      String title,
      String caption,
      IconData icon,
      bool value,
      ValueChanged<bool>? onChanged,
    ) => Opacity(
      opacity: onChanged == null ? 0.45 : 1,
      child: Material(
        color: value && onChanged != null
            ? colors.accentTint
            : colors.sunkenSoft,
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          onTap: onChanged == null ? null : () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, size: 20, color: colors.text2),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: BnType.body.copyWith(
                          color: colors.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        caption,
                        style: BnType.micro.copyWith(color: colors.muted),
                      ),
                    ],
                  ),
                ),
                Checkbox(
                  value: value,
                  onChanged: onChanged == null
                      ? null
                      : (v) => onChanged(v ?? false),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Center(
      child: Material(
        color: colors.surface,
        borderRadius: const BorderRadius.all(Radius.circular(22)),
        child: SizedBox(
          width: 380,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 12,
              children: [
                Text(
                  'New recording',
                  style: BnType.title.copyWith(
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Everything you write is recorded, to play back later.',
                  style: BnType.caption.copyWith(color: colors.muted),
                ),
                BnToggleRow(
                  label: 'Record sound',
                  description: _audio
                      ? 'Choose where the sound comes from'
                      : 'Only the writing is recorded',
                  value: _audio,
                  onChanged: (v) => setState(() => _audio = v),
                ),
                source(
                  'Microphone',
                  'Your voice and the room',
                  Icons.mic_none,
                  _mic,
                  _audio ? (v) => setState(() => _mic = v) : null,
                ),
                source(
                  'Device audio',
                  _deviceAvailable
                      ? 'What plays on the tablet: a video, a lecture'
                      : 'Only on Android',
                  Icons.speaker_outlined,
                  _device,
                  _audio && _deviceAvailable
                      ? (v) => setState(() => _device = v)
                      : null,
                ),
                const SizedBox(height: 4),
                Row(
                  spacing: 10,
                  children: [
                    Expanded(
                      child: BnButton(
                        label: 'Cancel',
                        expand: true,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    Expanded(
                      child: BnButton.primary(
                        label: 'Start recording',
                        icon: Icons.fiber_manual_record,
                        expand: true,
                        onPressed: _start,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// While recording, at the top right under undo and redo: a red stop
/// button, the time, and what's being recorded.
class RecordingPill extends StatefulWidget {
  const RecordingPill({super.key, required this.audio, required this.onStop});

  final AudioNotes audio;
  final VoidCallback onStop;

  @override
  State<RecordingPill> createState() => _RecordingPillState();
}

class _RecordingPillState extends State<RecordingPill> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && widget.audio.isRecording) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return ListenableBuilder(
      listenable: widget.audio,
      builder: (context, _) {
        final since = widget.audio.recordingSince;
        if (since == null) return const SizedBox.shrink();
        final time = DateTime.now().difference(since);
        final text =
            '${time.inMinutes.toString().padLeft(2, '0')}:'
            '${(time.inSeconds % 60).toString().padLeft(2, '0')}';
        return Material(
          color: colors.surface,
          elevation: 6,
          shadowColor: Colors.black26,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Tooltip(
                  message: 'Stop recording',
                  child: InkWell(
                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                    onTap: widget.onStop,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE5483B),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      child: Center(
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.all(Radius.circular(3)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  text,
                  style: BnType.bodyLarge.copyWith(
                    color: const Color(0xFFE5483B),
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 10),
                Container(width: 1, height: 22, color: colors.hairline),
                const SizedBox(width: 10),
                Icon(
                  widget.audio.recordsAudio ? Icons.mic_none : Icons.gesture,
                  size: 20,
                  color: colors.text2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The Audio tab of the pages sidebar (design 22): the note's recordings as
/// Audio Clip 1, 2…; tapped, one opens in place with a seek bar marked
/// where you wrote, play, speed. Under them how the notes play back, each
/// way shown by a small preview that plays on its own; New recording last.
class RecordingsPanel extends StatefulWidget {
  const RecordingsPanel({super.key, required this.audio, required this.record});

  final AudioNotes audio;

  /// Starts a recording (asking what to record), or stops the one going.
  final VoidCallback record;

  @override
  State<RecordingsPanel> createState() => _RecordingsPanelState();
}

class _RecordingsPanelState extends State<RecordingsPanel> {
  int? _open;

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// "Today, 14:20", "Yesterday, 18:02" or "21 Nov, 09:15".
  static String _when(int ms) {
    if (ms == 0) return '';
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    final now = DateTime.now();
    final days = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(d.year, d.month, d.day)).inDays;
    final day = days == 0
        ? 'Today'
        : days == 1
        ? 'Yesterday'
        : '${d.day} ${_months[d.month - 1]}'
              '${d.year == now.year ? '' : ' ${d.year}'}';
    String two(int v) => v.toString().padLeft(2, '0');
    return '$day, ${two(d.hour)}:${two(d.minute)}';
  }

  static String _time(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final audio = widget.audio;
    final colors = BadNotesColors.of(context);
    return ListenableBuilder(
      listenable: audio,
      builder: (context, _) {
        final open = _open != null && _open! < audio.recordings.length
            ? _open
            : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                children: [
                  if (audio.recordings.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 24, 12, 24),
                      child: Text(
                        'No recordings yet. Record while you write, then play '
                        'it back with the writing.',
                        textAlign: TextAlign.center,
                        style: BnType.body.copyWith(color: colors.muted),
                      ),
                    ),
                  for (final (i, r) in audio.recordings.indexed) ...[
                    _row(context, i, r, open == i),
                    if (open == i) _player(context, i),
                  ],
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                    child: Text(
                      'Notes playback',
                      style: BnType.caption.copyWith(
                        color: colors.text2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ..._modes(context),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: _recordButton(context),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _row(BuildContext context, int i, AudioRecording r, bool open) {
    final colors = BadNotesColors.of(context);
    return Material(
      color: open ? colors.accentTint : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => _open = open ? null : i),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            spacing: 12,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: open ? colors.accent : colors.sunken,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  size: 20,
                  color: open ? Colors.white : colors.text2,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Audio Clip ${i + 1}',
                      style: BnType.body.copyWith(
                        color: colors.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        _when(r.createdAtMs),
                        _time(Duration(milliseconds: r.durationMs)),
                      ].where((s) => s.isNotEmpty).join(' · '),
                      style: BnType.caption.copyWith(color: colors.muted),
                    ),
                  ],
                ),
              ),
              if (!r.hasAudio)
                Text(
                  'Writing only',
                  style: BnType.micro.copyWith(color: colors.faint),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _player(BuildContext context, int index) {
    final audio = widget.audio;
    final colors = BadNotesColors.of(context);
    final r = audio.recordings[index];
    final total = Duration(milliseconds: r.durationMs);
    final current = audio.playingIndex == index;
    final max = total.inMilliseconds.toDouble().clamp(1.0, double.infinity);
    // where writing finished, as parts of the clip: marks on the bar
    final marks = [
      for (final ms in r.marks.values)
        if (ms >= 0 && ms <= max) ms / max,
    ];
    void seek(Duration to) => current ? audio.seek(to) : audio.play(index, to);

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ValueListenableBuilder(
            valueListenable: audio.position,
            builder: (context, position, _) {
              final at = current ? position : Duration.zero;
              return Column(
                children: [
                  SizedBox(
                    height: 30,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: CustomPaint(
                              painter: _Marks(marks, colors.accentTintBorder),
                            ),
                          ),
                        ),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 5,
                            activeTrackColor: colors.accent,
                            inactiveTrackColor: colors.sunken.withValues(
                              alpha: 0.6,
                            ),
                            thumbColor: Colors.white,
                            overlayShape: SliderComponentShape.noOverlay,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 8,
                              elevation: 2,
                            ),
                          ),
                          child: Slider(
                            value: at.inMilliseconds.toDouble().clamp(0, max),
                            max: max,
                            onChanged: (v) =>
                                seek(Duration(milliseconds: v.round())),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Text(
                          _time(at),
                          style: BnType.micro.copyWith(color: colors.muted),
                        ),
                        Expanded(
                          child: Text(
                            marks.isEmpty ? '' : 'marks: where you wrote',
                            textAlign: TextAlign.center,
                            style: BnType.micro.copyWith(color: colors.faint),
                          ),
                        ),
                        Text(
                          _time(total),
                          style: BnType.micro.copyWith(color: colors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder(
            valueListenable: audio.playing,
            builder: (context, playing, _) {
              final isPlaying = current && playing;
              Widget skip(String label, int seconds) => TextButton(
                onPressed: current
                    ? () => audio.seek(
                        audio.position.value + Duration(seconds: seconds),
                      )
                    : null,
                style: TextButton.styleFrom(foregroundColor: colors.text2),
                child: Text(
                  label,
                  style: BnType.caption.copyWith(fontWeight: FontWeight.w600),
                ),
              );
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 14,
                children: [
                  skip('↺ 10', -10),
                  Semantics(
                    button: true,
                    label: isPlaying ? 'Pause' : 'Play',
                    child: Material(
                      color: colors.text,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          if (isPlaying) {
                            audio.pause();
                          } else if (current) {
                            audio.resume();
                          } else {
                            audio.play(index);
                          }
                        },
                        child: SizedBox.square(
                          dimension: 48,
                          child: Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: colors.surface,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ),
                  skip('10 ↻', 10),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            spacing: 10,
            children: [
              Text(
                'Speed',
                style: BnType.caption.copyWith(color: colors.muted),
              ),
              Expanded(
                child: BnSegmented<double>(
                  segments: const [
                    BnSegment(0.5, '0.5×'),
                    BnSegment(1.0, '1×'),
                    BnSegment(1.5, '1.5×'),
                    BnSegment(2.0, '2×'),
                  ],
                  selected: audio.speed,
                  height: 32,
                  onChanged: audio.setSpeed,
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () async {
                setState(() => _open = null);
                await audio.deleteRecording(index);
              },
              style: TextButton.styleFrom(foregroundColor: colors.danger),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(
                'Delete clip',
                style: BnType.caption.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The three ways notes play back, each with a preview that plays.
  List<Widget> _modes(BuildContext context) {
    final audio = widget.audio;
    final colors = BadNotesColors.of(context);
    Widget mode(
      String key,
      String title,
      String caption,
    ) => ValueListenableBuilder(
      valueListenable: stows.playbackMode,
      builder: (context, value, _) {
        // the free version only plays back as it is
        final selected = Pro.has ? value == key : key == 'static';
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: selected ? colors.accentTint : colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              side: BorderSide(
                color: selected ? colors.accent : colors.hairline,
                width: selected ? 2 : 1,
              ),
            ),
            child: InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(14)),
              onTap: () async {
                if (key != 'static' &&
                    !await Pro.require(context, ProFeature.playback)) {
                  return;
                }
                stows.playbackMode.value = key;
                // shows the change at once
                final at = audio.playbackAt.value;
                if (at != null) {
                  audio.playbackAt.value = (recording: at.recording, ms: at.ms);
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  spacing: 10,
                  children: [
                    PlaybackPreview(mode: key),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: BnType.body.copyWith(
                              color: colors.text,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            caption,
                            style: BnType.micro.copyWith(color: colors.text2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    return [
      mode(
        'spotlight',
        'Spotlight',
        'The page shows faded; what you wrote at this moment turns dark.',
      ),
      mode(
        'reveal',
        'Real-time reveal',
        'The page starts empty; each line writes itself as you wrote it.',
      ),
      mode('static', 'Static', 'The ink stays as it is; only the sound plays.'),
    ];
  }

  Widget _recordButton(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final recording = widget.audio.isRecording;
    return Material(
      color: recording ? colors.danger : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: recording ? colors.danger : colors.hairline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.record,
        child: SizedBox(
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 8,
            children: [
              Container(
                width: recording ? 10 : 10,
                height: 10,
                decoration: BoxDecoration(
                  color: recording ? Colors.white : const Color(0xFFE5484D),
                  shape: recording ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius: recording ? BorderRadius.circular(2) : null,
                ),
              ),
              Text(
                recording ? 'Stop recording' : 'New recording',
                style: BnType.body.copyWith(
                  color: recording ? Colors.white : colors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small ticks on the seek bar where writing happened.
class _Marks extends CustomPainter {
  const _Marks(this.marks, this.color);

  final List<double> marks;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final mid = size.height / 2;
    for (final m in marks) {
      final x = m * size.width;
      canvas.drawLine(Offset(x, mid - 8), Offset(x, mid + 8), paint);
    }
  }

  @override
  bool shouldRepaint(_Marks oldDelegate) =>
      oldDelegate.marks.length != marks.length || oldDelegate.color != color;
}

/// A small window showing how notes play back in [mode] ("spotlight",
/// "reveal" or "static"): a handwritten word written over and over, with
/// the playhead moving under it.
class PlaybackPreview extends StatefulWidget {
  const PlaybackPreview({super.key, required this.mode});

  final String mode;

  @override
  State<PlaybackPreview> createState() => _PlaybackPreviewState();
}

class _PlaybackPreviewState extends State<PlaybackPreview>
    with SingleTickerProviderStateMixin {
  late final _clock = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    // still, written out, when the system asks for less motion
    if (MediaQuery.disableAnimationsOf(context)) {
      _clock
        ..stop()
        ..value = 0.75;
    } else if (!_clock.isAnimating) {
      _clock.repeat();
    }
    return RepaintBoundary(
      child: Container(
        width: 104,
        height: 62,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.hairline),
        ),
        child: CustomPaint(
          painter: _PreviewPainter(
            mode: widget.mode,
            clock: _clock,
            accent: colors.accent,
            track: colors.hairline,
          ),
        ),
      ),
    );
  }
}

class _PreviewPainter extends CustomPainter {
  _PreviewPainter({
    required this.mode,
    required this.clock,
    required this.accent,
    required this.track,
  }) : super(repaint: clock);

  final String mode;
  final Animation<double> clock;
  final Color accent, track;

  static final _word = previewWord;

  @override
  void paint(Canvas canvas, Size size) {
    // written over the first 70% of the loop, then held
    final t = (clock.value / 0.7).clamp(0.0, 1.0);
    final ink = Paint()
      ..color = const Color(0xFF1C1C1E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.save();
    canvas.translate((size.width - 100) / 2, 4);
    if (mode == 'static') {
      canvas.drawPath(_word, ink);
    } else {
      if (mode == 'spotlight') {
        canvas.drawPath(
          _word,
          Paint()
            ..color = const Color(0x2E1C1C1E)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }
      for (final metric in _word.computeMetrics()) {
        canvas.drawPath(metric.extractPath(0, metric.length * t), ink);
      }
    }
    canvas.restore();
    // the playhead under it
    final y = size.height - 8;
    final left = size.width * 0.1, right = size.width * 0.9;
    canvas.drawLine(
      Offset(left, y),
      Offset(right, y),
      Paint()
        ..color = track
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(left + (right - left) * t, y),
      4,
      Paint()..color = accent,
    );
  }

  @override
  bool shouldRepaint(_PreviewPainter oldDelegate) =>
      oldDelegate.mode != mode || oldDelegate.accent != accent;
}
