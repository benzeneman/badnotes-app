import 'package:badnotes/components/canvas/palm_rejection.dart';
import 'package:badnotes/components/editor_ui/option_previews.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/theming/badnotes_tokens.dart';
import 'package:badnotes/components/ui/bn_controls.dart';
import 'package:badnotes/components/ui/bn_settings.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/tools/pressure_curve.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Pressure (0 to 1) as the device reports it, or null for a pointer without
/// pressure: the same reading the canvas makes.
double? _pressureOf(PointerEvent event) => event.pressureMin == event.pressureMax
    ? null
    : ((event.pressure - event.pressureMin) /
              (event.pressureMax - event.pressureMin))
          .clamp(0.0, 1.0);

/// Takes the pointer at once, so the settings page doesn't scroll while
/// dragging or writing in [child].
Widget _ownsDrags({required Widget child}) => RawGestureDetector(
  gestures: {
    EagerGestureRecognizer:
        GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
      EagerGestureRecognizer.new,
      (_) {},
    ),
  },
  child: child,
);

/// The pressure curve every pen's stylus pressure goes through, with a box to
/// try it, and the lightest touch that draws.
class PressureCurveSettings extends StatelessWidget {
  const new({super.key});

  static const _labels = {
    'light': 'Light',
    'normal': 'Normal',
    'firm': 'Firm',
    'custom': 'Custom',
  };

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return BnSettingsGroup(
      label: 'Pen pressure',
      footer:
          'Light: a soft touch already gives a thick line. Firm: press to get '
          'one. Custom: drag the point on the curve. Each pen keeps its own '
          '"how much pressure shows".',
      children: [
        ListenableBuilder(
          listenable: Listenable.merge([
            stows.pressureCurve,
            stows.pressureCurveX,
            stows.pressureCurveY,
            stows.pressureThreshold,
          ]),
          builder: (context, _) {
            final preset = stows.pressureCurve.value;
            final threshold = stows.pressureThreshold.value;
            return Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  BnSegmented<String>(
                    segments: [
                      for (final MapEntry(:key, :value) in _labels.entries)
                        BnSegment(key, value),
                    ],
                    selected: _labels.containsKey(preset) ? preset : 'normal',
                    onChanged: (value) => stows.pressureCurve.value = value,
                  ),
                  const SizedBox(height: 12),
                  // a line from a light touch to pressing hard, as it is now
                  const PressurePreview(),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CurveGraph(
                        gamma: PressureCurve.gamma,
                        point: preset == 'custom'
                            ? Offset(
                                stows.pressureCurveX.value,
                                stows.pressureCurveY.value,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Try it here:',
                              style: BnType.caption.copyWith(
                                color: colors.muted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const _TryBox(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  BnSlider(
                    label: 'Lightest touch that draws',
                    valueLabel: '${(threshold * 100).round()}%',
                    value: threshold,
                    max: 0.2,
                    divisions: 20,
                    onChanged: (value) =>
                        stows.pressureThreshold.value = value,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// The curve, pressing harder to the right and thicker upwards; dragging it
/// makes it a custom curve through the finger.
class _CurveGraph extends StatelessWidget {
  const new({required this.gamma, required this.point});

  final double gamma;

  /// The custom curve's point, if it's custom.
  final Offset? point;

  static const size = Size(170, 150);

  void _drag(Offset local) {
    stows.pressureCurveX.value = (local.dx / size.width).clamp(0.05, 0.95);
    stows.pressureCurveY.value = (1 - local.dy / size.height).clamp(
      0.05,
      0.95,
    );
    stows.pressureCurve.value = 'custom';
  }

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return _ownsDrags(
      child: Listener(
        onPointerDown: (event) => _drag(event.localPosition),
        onPointerMove: (event) => _drag(event.localPosition),
        child: Container(
          decoration: BoxDecoration(
            color: colors.sunkenSoft,
            border: Border.all(color: colors.hairline),
            borderRadius: BorderRadius.circular(10),
          ),
          child: CustomPaint(
            size: size,
            painter: _CurvePainter(
              gamma: gamma,
              point: point,
              line: colors.accent,
              axis: colors.hairline,
              knob: colors.surface,
            ),
          ),
        ),
      ),
    );
  }
}

class _CurvePainter extends CustomPainter {
  const new({
    required this.gamma,
    required this.point,
    required this.line,
    required this.axis,
    required this.knob,
  });

  final double gamma;
  final Offset? point;
  final Color line, axis, knob;

  @override
  void paint(Canvas canvas, Size size) {
    Offset at(double x, double y) =>
        Offset(x * size.width, (1 - y) * size.height);
    canvas.drawLine(at(0, 0), at(1, 1), Paint()..color = axis);
    final path = Path()..moveTo(0, size.height);
    for (var i = 1; i <= 40; i++) {
      final x = i / 40;
      final p = at(x, PressureCurve.apply(x, gamma));
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    if (point case final point?) {
      final center = at(point.dx, point.dy);
      canvas.drawCircle(center, 7, Paint()..color = knob);
      canvas.drawCircle(
        center,
        7,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  @override
  bool shouldRepaint(_CurvePainter old) =>
      old.gamma != gamma || old.point != point || old.line != line;
}

/// A box to write in with the curve and lightest touch as they are now.
class _TryBox extends StatefulWidget {
  const new();

  @override
  State<_TryBox> createState() => _TryBoxState();
}

class _TryBoxState extends State<_TryBox> {
  /// Points with their pressure after the curve (null: none), the line
  /// broken where a null point is.
  final _points = <(Offset, double?)?>[];

  void _add(PointerEvent event) {
    final pressure = _pressureOf(event);
    if (PressureCurve.tooLight(pressure)) {
      if (_points.isNotEmpty && _points.last != null) _points.add(null);
    } else {
      _points.add((event.localPosition, PressureCurve.adjust(pressure)));
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return _ownsDrags(
      child: Listener(
        onPointerDown: (event) {
          _points.clear();
          _add(event);
        },
        onPointerMove: _add,
        child: Container(
          height: 120,
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            border: Border.all(color: colors.hairline),
            borderRadius: BorderRadius.circular(10),
          ),
          child: CustomPaint(
            size: Size.infinite,
            painter: _InkPainter(List.of(_points), colors.text),
          ),
        ),
      ),
    );
  }
}

class _InkPainter extends CustomPainter {
  const new(this.points, this.color);

  final List<(Offset, double?)?> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round;
    for (var i = 1; i < points.length; i++) {
      final (a, b) = (points[i - 1], points[i]);
      if (a == null || b == null) continue;
      paint.strokeWidth = 1 + 9 * (b.$2 ?? 0.4);
      canvas.drawLine(a.$1, b.$1, paint);
    }
  }

  @override
  bool shouldRepaint(_InkPainter old) => true;
}

/// How touches are told from the hand resting while writing.
class PalmRejectionSettings extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => BnSettingsGroup(
    label: 'Palm rejection',
    footer: 'Test: rest your hand and write; touches ignored show as grey '
        'dots for 2 s.',
    children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(18, 14, 18, 14),
        child: PalmPreview(),
      ),
      BnPrefSwitchRow(
        title: 'Ignore my hand while the pen is near',
        pref: stows.palmRejection,
      ),
      BnPrefSegmentRow<int>(
        title: 'How long after lifting the pen',
        pref: stows.palmAfterLiftMs,
        options: const {200: 'Short', 400: 'Normal', 800: 'Long'},
      ),
      BnPrefSegmentRow<bool>(
        title: 'Writing hand',
        subtitle: 'Touches where that hand rests are ignored for longer',
        pref: stows.leftHanded,
        options: const {true: 'Left', false: 'Right'},
      ),
      BnPrefSwitchRow(
        title: 'Ignore big touches (a palm) even with no pen',
        subtitle: 'Only on screens that say how big a touch is',
        pref: stows.palmIgnoreBigTouches,
      ),
      BnPrefSwitchRow(
        title: 'Two fingers still zoom and scroll',
        pref: stows.palmTwoFingersZoom,
      ),
      ValueListenableBuilder(
        valueListenable: PalmRejection.showIgnored,
        builder: (context, value, _) => BnSettingsRow(
          title: 'Show ignored touches',
          subtitle: 'Until the app closes',
          onTap: () => PalmRejection.showIgnored.value = !value,
          trailing: BnToggle(
            value: value,
            onChanged: (v) => PalmRejection.showIgnored.value = v,
          ),
        ),
      ),
    ],
  );
}
