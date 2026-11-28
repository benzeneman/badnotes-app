import 'package:badnotes/components/theming/theme_reveal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the circle reaches the farthest corner', () {
    const size = Size(300, 400);
    expect(RevealPainter.reach(Offset.zero, size), 500);
    expect(RevealPainter.reach(const Offset(150, 200), size), 250);
  });

  Widget app(Brightness brightness, {bool reduceMotion = false}) => MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: ThemeReveal(
      brightness: brightness,
      builder: (context, shown) => ColoredBox(
        color: shown == Brightness.dark ? Colors.black : Colors.white,
        child: Text(shown.name, textDirection: TextDirection.ltr),
      ),
    ),
  );

  bool revealing(WidgetTester tester) => tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .any((paint) => paint.foregroundPainter is RevealPainter);

  testWidgets('the new theme shows under the old picture, then alone', (
    tester,
  ) async {
    await tester.pumpWidget(app(Brightness.light));
    await tester.pumpWidget(app(Brightness.dark));
    // the old theme is pictured after this frame
    expect(find.text('light'), findsOneWidget);
    await tester.pump();
    expect(find.text('dark'), findsOneWidget);
    expect(revealing(tester), isTrue);
    await tester.pump(ThemeReveal.duration + const Duration(milliseconds: 50));
    await tester.pump();
    expect(revealing(tester), isFalse);
  });

  testWidgets('reduce motion: switched at once', (tester) async {
    await tester.pumpWidget(app(Brightness.light, reduceMotion: true));
    await tester.pumpWidget(app(Brightness.dark, reduceMotion: true));
    expect(find.text('dark'), findsOneWidget);
    expect(revealing(tester), isFalse);
  });
}
