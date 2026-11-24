import 'package:flutter_test/flutter_test.dart';
import 'package:badnotes/components/canvas/_stroke.dart';

void main() {
  test('fast lines are thinner, slow ones a little wider', () {
    final still = Stroke.speedFactor(0);
    final slow = Stroke.speedFactor(2);
    final fast = Stroke.speedFactor(20);
    final faster = Stroke.speedFactor(80);
    expect(still, greaterThan(1));
    expect(slow, lessThan(still));
    expect(fast, lessThan(slow));
    expect(faster, lessThan(fast));
    // levels off instead of vanishing
    expect(Stroke.speedFactor(10000), greaterThan(0.2));
    expect(Stroke.speedFactor(double.nan), 1);
  });

  test('cubic fit continues a cubic exactly', () {
    double f(double t) => 2 - 3 * t + 0.5 * t * t + 0.1 * t * t * t;
    final values = [for (int i = 0; i < 8; i++) f(i.toDouble())];
    expect(Stroke.fitCubicAhead(values, 2), closeTo(f(9), 1e-6));
    expect(Stroke.fitCubicAhead([1, 2, 3], 1), isNull);
  });
}
