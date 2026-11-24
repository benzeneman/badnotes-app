import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:badnotes/components/canvas/palm_rejection.dart';
import 'package:badnotes/data/flavor_config.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/tools/pressure_curve.dart';

void main() {
  setUpAll(FlavorConfig.setup);

  group('PressureCurve', () {
    final gammas = {
      'light': PressureCurve.gammaOf('light', 0.5, 0.5),
      'normal': PressureCurve.gammaOf('normal', 0.5, 0.5),
      'firm': PressureCurve.gammaOf('firm', 0.5, 0.5),
      'custom low': PressureCurve.gammaOf('custom', 0.7, 0.2),
      'custom high': PressureCurve.gammaOf('custom', 0.2, 0.8),
    };

    test('goes through both ends and only rises', () {
      for (final MapEntry(:key, value: gamma) in gammas.entries) {
        expect(PressureCurve.apply(0, gamma), 0, reason: key);
        expect(PressureCurve.apply(1, gamma), closeTo(1, 1e-9), reason: key);
        var last = -1.0;
        for (var i = 0; i <= 100; i++) {
          final y = PressureCurve.apply(i / 100, gamma);
          expect(y, greaterThanOrEqualTo(last), reason: key);
          expect(y, inInclusiveRange(0, 1), reason: key);
          last = y;
        }
      }
    });

    test('presets: normal unchanged, light thicker, firm thinner', () {
      expect(PressureCurve.apply(0.3, gammas['normal']!), 0.3);
      expect(PressureCurve.apply(0.3, gammas['light']!), greaterThan(0.3));
      expect(PressureCurve.apply(0.3, gammas['firm']!), lessThan(0.3));
    });

    test('a custom curve goes through its point', () {
      final gamma = PressureCurve.gammaThrough(0.3, 0.7);
      expect(PressureCurve.apply(0.3, gamma), closeTo(0.7, 1e-9));
    });

    test('out of range pressure is clamped', () {
      expect(PressureCurve.apply(1.4, 1.6), 1);
      expect(PressureCurve.apply(-0.2, 0.6), 0);
    });

    test('lightest touch: none by default, never for a pen without '
        'pressure', () {
      expect(PressureCurve.tooLight(0.01), isFalse);
      stows.pressureThreshold.value = 0.05;
      expect(PressureCurve.tooLight(0.01), isTrue);
      expect(PressureCurve.tooLight(0.2), isFalse);
      expect(PressureCurve.tooLight(null), isFalse);
      stows.pressureThreshold.value = 0;
    });
  });

  group('PalmRejection', () {
    setUp(PalmRejection.reset);

    PointerEvent stylusUp(Duration at, Offset where) => PointerUpEvent(
      timeStamp: at,
      pointer: 1,
      kind: PointerDeviceKind.stylus,
      position: where,
    );
    PointerEvent touch(Duration at, Offset where, {int pointer = 2}) =>
        PointerDownEvent(
          timeStamp: at,
          pointer: pointer,
          kind: PointerDeviceKind.touch,
          position: where,
        );

    test('how long after the pen lifts follows the setting', () {
      PalmRejection.track(stylusUp(Duration.zero, Offset.zero));
      const far = Offset(-500, -500);
      const at = Duration(milliseconds: 600);
      expect(PalmRejection.rejects(touch(at, far)), isFalse);
      PalmRejection.reset();
      stows.palmAfterLiftMs.value = 800;
      PalmRejection.track(stylusUp(Duration.zero, Offset.zero));
      expect(PalmRejection.rejects(touch(at, far, pointer: 3)), isTrue);
      stows.palmAfterLiftMs.value = 400;
    });

    test('off: touches are never ignored for the pen', () {
      stows.palmRejection.value = false;
      PalmRejection.track(stylusUp(Duration.zero, Offset.zero));
      expect(
        PalmRejection.rejects(touch(const Duration(milliseconds: 10), Offset.zero)),
        isFalse,
      );
      stows.palmRejection.value = true;
    });

    test('the writing hand rests below the pen on its side', () {
      const pen = Offset(500, 500);
      expect(
        PalmRejection.inHandZone(const Offset(650, 650), pen, leftHanded: false),
        isTrue,
      );
      expect(
        PalmRejection.inHandZone(const Offset(350, 650), pen, leftHanded: false),
        isFalse,
      );
      expect(
        PalmRejection.inHandZone(const Offset(350, 650), pen, leftHanded: true),
        isTrue,
      );
      expect(
        PalmRejection.inHandZone(const Offset(650, 200), pen, leftHanded: false),
        isFalse,
      );
    });

    test('a touch where the hand rests is ignored only just after a lift', () {
      PalmRejection.track(stylusUp(Duration.zero, const Offset(500, 500)));
      expect(
        PalmRejection.rejects(
          touch(const Duration(milliseconds: 300), const Offset(650, 650)),
        ),
        isTrue,
      );
      const at = Duration(milliseconds: 1000);
      expect(
        PalmRejection.rejects(touch(at, const Offset(650, 650), pointer: 5)),
        isFalse,
      );
      expect(
        PalmRejection.rejects(touch(at, const Offset(100, 100), pointer: 3)),
        isFalse,
      );
    });

    test('big touches are ignored only when asked', () {
      final palm = PointerDownEvent(
        pointer: 4,
        kind: PointerDeviceKind.touch,
        radiusMajor: 40,
      );
      expect(PalmRejection.rejects(palm), isFalse);
      PalmRejection.reset();
      stows.palmIgnoreBigTouches.value = true;
      expect(PalmRejection.rejects(palm), isTrue);
      stows.palmIgnoreBigTouches.value = false;
    });
  });
}
