import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:badnotes/components/canvas/finger_taps.dart';

void main() {
  late int twos;
  late FingerTaps taps;
  setUp(() {
    twos = 0;
    taps = FingerTaps(onTwoFingerTap: () => twos++, onThreeFingerTap: () {});
  });

  PointerEvent down(int pointer, {PointerDeviceKind kind = .touch}) =>
      PointerDownEvent(pointer: pointer, kind: kind, timeStamp: .zero);
  PointerEvent up(int pointer, {PointerDeviceKind kind = .touch}) =>
      PointerUpEvent(
        pointer: pointer,
        kind: kind,
        timeStamp: const Duration(milliseconds: 100),
      );

  test('two fingers tapped is a tap', () {
    for (final e in [down(1), down(2), up(1), up(2)]) {
      taps.handle(e);
    }
    expect(twos, 1);
  });

  test('a palm resting while the pen writes is not', () {
    taps.handle(down(9, kind: .stylus));
    for (final e in [down(1), down(2), up(1), up(2)]) {
      taps.handle(e);
    }
    taps.handle(up(9, kind: .stylus));
    expect(twos, 0);

    // the pen lifted: taps count again
    for (final e in [down(1), down(2), up(1), up(2)]) {
      taps.handle(e);
    }
    expect(twos, 1);
  });

  test('a touch the palm check threw out spoils the tap, then is let go', () {
    taps
      ..handle(down(1))
      ..handle(down(2))
      ..ignore(up(2))
      ..handle(up(1));
    expect(twos, 0);

    for (final e in [down(3), down(4), up(3), up(4)]) {
      taps.handle(e);
    }
    expect(twos, 1);
  });
}
