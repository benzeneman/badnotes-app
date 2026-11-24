import 'package:badnotes/components/home/cover_designs.dart';
import 'package:badnotes/components/home/notebook_cover.dart';
import 'package:badnotes/components/theming/frozen_picture.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a cover is drawn once into a picture, with its label', (
    tester,
  ) async {
    final design = CoverDesign.all.firstWhere((d) => d.label);
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 140,
            child: NotebookCover(design: design, title: 'Maths'),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Maths'), findsOneWidget);
    expect(find.byType(FrozenPicture), findsOneWidget);
    // after the first frame it's the picture that's shown
    expect(find.byType(RawImage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
