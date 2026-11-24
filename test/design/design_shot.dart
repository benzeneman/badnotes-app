import 'dart:io';
import 'dart:ui' as ui;

import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_screenshot/golden_screenshot.dart';
import 'package:image/image.dart' as img;

/// The landscape tablet the mockups are drawn for, in logical pixels.
const tabletLandscape = Size(1280, 800);
const tabletPortrait = Size(800, 1280);

/// Whether the screenshots are taken in dark mode (`DESIGN_DARK=true`).
final designDark = Platform.environment['DESIGN_DARK'] == 'true';

/// The brightness the screenshots are taken in.
Brightness get designBrightness =>
    designDark ? Brightness.dark : Brightness.light;

/// The app themed as it runs, around [home], for a design screenshot.
Widget designApp(Widget home, {Brightness? brightness}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: BadNotesTheme.create(brightness ?? designBrightness),
  home: home,
);

/// Shows [app] at [size] with the app's real fonts and soft shadows, and,
/// when the `OUT` environment variable names a folder, saves
/// `OUT/app/<name>.png`. When `MOCKUPS` names the folder of the rendered
/// mockups (design-shots.yml) and it has `<mockup>.png`, also saves
/// `OUT/compare/<name>.png`: the mockup on the left, the app on the right.
///
/// [setUp] runs after the first frame, e.g. to open a dialog.
Future<void> designShot(
  WidgetTester tester,
  String name,
  Widget app, {
  Size size = tabletLandscape,
  String? mockup,
  Future<void> Function(WidgetTester tester)? setUp,
}) async {
  await loadAppFonts();
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  debugDisableShadows = false;
  try {
    await tester.pumpWidget(
      RepaintBoundary(key: const Key('design-shot'), child: app),
    );
    await tester.pump(const Duration(milliseconds: 50));
    if (setUp != null) await setUp(tester);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));
    await _save(tester, name, mockup ?? name);
  } finally {
    debugDisableShadows = true;
  }
}

/// Saves what a [designShot] shows now as `OUT/app/<name>.png`, for a
/// test that takes more than one picture.
Future<void> saveDesignShot(WidgetTester tester, String name) =>
    _save(tester, name, name);

Future<void> _save(WidgetTester tester, String name, String mockup) async {
  final out = Platform.environment['OUT'];
  if (out == null) return;
  final boundary = tester.renderObject(
    find.byKey(const Key('design-shot')),
  ) as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final png = (await image.toByteData(format: ui.ImageByteFormat.png))!.buffer
        .asUint8List();
    image.dispose();
    Directory('$out/app').createSync(recursive: true);
    File('$out/app/$name.png').writeAsBytesSync(png);

    final mockups = Platform.environment['MOCKUPS'];
    final mockupFile = File('$mockups/$mockup.png');
    if (mockups == null || !mockupFile.existsSync()) return;
    final left = img.decodePng(mockupFile.readAsBytesSync())!;
    final right = img.decodePng(png)!;
    final sheet = img.Image(
      width: left.width + right.width + 16,
      height: left.height > right.height ? left.height : right.height,
    );
    img.fill(sheet, color: img.ColorRgb8(255, 0, 255));
    img.compositeImage(sheet, left);
    img.compositeImage(sheet, right, dstX: left.width + 16);
    Directory('$out/compare').createSync(recursive: true);
    File('$out/compare/$name.png').writeAsBytesSync(img.encodePng(sheet));
  });
}
