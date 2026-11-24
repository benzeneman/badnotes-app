@Tags(['design'])
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_screenshot/golden_screenshot.dart';

/// Every shared widget of the "Minimal" design on one screen. Run with
/// `OUT=folder` to also save a picture of it in light and dark.
class _Gallery extends StatefulWidget {
  const new();

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  var tab = 0;
  var tool = 1;
  var size = 1;
  var color = 0;
  var segment = 'all';
  var toggle = true;
  var slider = 0.42;

  static const _inks = [
    BnColors.inkBlack,
    BnColors.inkBlue,
    BnColors.inkRed,
    BnColors.inkGreen,
  ];

  static const _tools = [
    ('Lasso', BnToolIcons.lasso),
    ('Pen', BnToolIcons.pen),
    ('Highlighter', BnToolIcons.highlighter),
    ('Pencil', BnToolIcons.pencil),
    ('Draw shapes', BnToolIcons.drawShapes),
    ('Tape', BnToolIcons.tape),
    ('Shapes', BnToolIcons.shapes),
    ('Eraser', BnToolIcons.eraser),
    ('Laser', BnToolIcons.laser),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Scaffold(
      backgroundColor: colors.desk,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(40, 26, 40, 0),
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good afternoon',
                        style: BnType.display.copyWith(color: colors.text),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '6 notebooks · 4 folders',
                        style: BnType.body.copyWith(
                          color: colors.muted,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 16),
                      BnSegmented(
                        expand: false,
                        segments: const [
                          BnSegment('all', 'All'),
                          BnSegment('notebooks', 'Notebooks'),
                          BnSegment('folders', 'Folders'),
                          BnSegment('photos', 'Photos'),
                        ],
                        selected: segment,
                        onChanged: (v) => setState(() => segment = v),
                      ),
                      const SizedBox(height: 20),
                      const BnSectionHeader(
                        title: 'Folders',
                        action: 'See all',
                      ),
                      SizedBox(
                        width: 560,
                        child: Row(
                          children: [
                            Expanded(
                              child: BnFolderTile(
                                name: 'College',
                                count: '12 items',
                                icon: BnFolderIcon.fromKey('cap'),
                                peeks: const [
                                  BnColors.lavender,
                                  BnColors.charcoal,
                                ],
                                onTap: () {},
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: BnFolderTile(
                                name: 'Personal',
                                count: '7 items',
                                color: BnFolderColor.peach,
                                icon: BnFolderIcon.fromKey('heart'),
                                peeks: const [Colors.white, BnColors.blush],
                                selected: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: BnFolderTile(
                                name: 'test',
                                count: '2 items',
                                color: BnFolderColor.sand,
                                peeks: [Colors.white],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: BnNewFolderTile(
                                label: 'New folder',
                                onTap: () {},
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: 560,
                        height: 230,
                        child: Row(
                          children: [
                            for (final (title, bg, dark) in const [
                              ('Physics', BnColors.lavender, false),
                              ('Maths', BnColors.charcoal, true),
                              ('Journal', BnColors.blush, false),
                              ('Untitled', Colors.white, false),
                            ]) ...[
                              Expanded(
                                child: BnNotebookTile(
                                  cover: BnCoverFrame(
                                    label: title,
                                    dark: dark,
                                    favorite: title == 'Maths',
                                    outlined: bg == Colors.white,
                                    selected: title == 'Journal',
                                    child: ColoredBox(color: bg),
                                  ),
                                  title: '$title notes',
                                  meta: 'Today',
                                ),
                              ),
                              const SizedBox(width: 18),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: 420,
                        child: BnCard(
                          child: Column(
                            children: [
                              BnListRow(
                                title: 'Physics — Class 12',
                                caption: 'College · Today',
                                leading: const SizedBox(
                                  width: 30,
                                  height: 40,
                                  child: BnCoverFrame(
                                    child: ColoredBox(color: BnColors.mint),
                                  ),
                                ),
                                trailing: BnIconButton(
                                  icon: BnIcons.more,
                                  onPressed: () {},
                                ),
                              ),
                              const BnListRow(
                                title: 'Daily Journal',
                                caption: 'Yesterday',
                                divider: false,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 32),
                SizedBox(
                  width: 320,
                  child: Column(
                    children: [
                      BnPopover(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const BnPopoverHeader(
                              title: 'Pen',
                              trailing: Text('Fountain'),
                            ),
                            const SizedBox(height: 12),
                            const BnPreviewWell(height: 60, child: Text('~~~')),
                            const SizedBox(height: 14),
                            BnSlider(
                              label: 'Tip sharpness',
                              valueLabel: '${(slider * 100).round()}%',
                              value: slider,
                              onChanged: (v) => setState(() => slider = v),
                            ),
                            const SizedBox(height: 8),
                            BnToggleRow(
                              label: 'Reduce latency',
                              description: 'Draws ahead of the pen.',
                              value: toggle,
                              onChanged: (v) => setState(() => toggle = v),
                            ),
                            const BnDivider(),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                BnChip(
                                  label: 'Lined',
                                  selected: true,
                                  onTap: () {},
                                ),
                                BnChip(label: 'Grid', onTap: () {}),
                                BnChip(
                                  label: 'Dots',
                                  icon: BnIcons.grid,
                                  onTap: () {},
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: BnButton(
                                    label: 'Cancel',
                                    expand: true,
                                    onPressed: () {},
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: BnButton.primary(
                                    label: 'Apply',
                                    expand: true,
                                    onPressed: () {},
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      BnPopover(
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            BnMenuRow(
                              label: 'Rename',
                              icon: BnIcons.rename,
                              onTap: () {},
                            ),
                            BnMenuRow(
                              label: 'Move to…',
                              icon: BnIcons.move,
                              selected: true,
                              onTap: () {},
                            ),
                            BnMenuRow(
                              label: 'Trash',
                              icon: BnIcons.trash,
                              trailingText: '3',
                              onTap: () {},
                            ),
                            BnMenuRow(
                              label: 'Delete',
                              icon: BnIcons.trash,
                              destructive: true,
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 150,
              child: Center(
                child: BnSubBar(
                  children: [
                    BnVariantPill(label: 'Fountain', onTap: () {}),
                    const BnBarDivider(),
                    for (final (i, t) in const [2.0, 3.5, 6.0].indexed)
                      BnSizeButton(
                        thickness: t,
                        selected: size == i,
                        onTap: () => setState(() => size = i),
                      ),
                    const BnBarDivider(),
                    for (final (i, c) in _inks.indexed)
                      BnColorDot(
                        color: c,
                        selected: color == i,
                        onTap: () => setState(() => color = i),
                      ),
                    BnMoreColorsDot(onTap: () {}),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 90,
              child: Center(
                child: BnToolDock(
                  children: [
                    const BnDragHandle(),
                    for (final (i, (label, path)) in _tools.indexed)
                      BnToolButton(
                        label: label,
                        path: path,
                        dashed: i == 0,
                        selected: tool == i,
                        onTap: () => setState(() => tool = i),
                      ),
                    const BnBarDivider(height: 22),
                    BnToolButton(
                      label: 'Insert',
                      icon: BnIcons.insert,
                      filled: true,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 22,
              child: Center(
                child: BnHomeDock(
                  tabs: const [
                    BnDockTab('Desk', BnIcons.desk),
                    BnDockTab('Recent', BnIcons.recent),
                    BnDockTab('Favorites', BnIcons.favorites),
                    BnDockTab('Whiteboard', BnIcons.whiteboard),
                  ],
                  selected: tab,
                  onSelect: (i) => setState(() => tab = i),
                  newLabel: 'New',
                  onNew: () {},
                ),
              ),
            ),
            const Positioned(
              right: 0,
              bottom: 32,
              child: BnDropHint(label: 'Drop here to dock at the top'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _save(WidgetTester tester, String name) async {
  final out = Platform.environment['OUT'];
  if (out == null) return;
  final boundary = tester.renderObject(
    find.byKey(const Key('gallery')),
  ) as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory(out).createSync(recursive: true);
    File('$out/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('the shared widgets draw and respond '
        '(${brightness.name})', (tester) async {
      await loadAppFonts();
      // real soft shadows in the saved picture
      debugDisableShadows = false;
      tester.view
        ..physicalSize = const Size(1280, 800)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: BadNotesTheme.create(brightness),
          home: const RepaintBoundary(key: Key('gallery'), child: _Gallery()),
        ),
      );
      await tester.pumpAndSettle();

      // a tap on a tool, a size and a tab chooses it
      await tester.tap(find.bySemanticsLabel('Eraser'));
      await tester.tap(find.bySemanticsLabel('Recent'));
      await tester.pumpAndSettle();
      final state = tester.state<_GalleryState>(find.byType(_Gallery));
      expect(state.tool, 7);
      expect(state.tab, 1);

      // the toggle and the segmented control
      await tester.tap(find.byType(BnToggle));
      await tester.tap(find.text('Folders').first);
      await tester.pumpAndSettle();
      expect(state.toggle, isFalse);
      expect(state.segment, 'folders');

      expect(tester.takeException(), isNull);
      await _save(tester, 'ui_gallery_${brightness.name}');
      debugDisableShadows = true;
    });
  }

  testWidgets('a popover opens next to its button and closes outside', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1280, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: BadNotesTheme.create(.light),
        home: Scaffold(
          body: Align(
            alignment: const Alignment(0, 0.9),
            child: Builder(
              builder: (context) => BnButton(
                label: 'Open',
                onPressed: () => showBnPopover<void>(
                  anchor: context,
                  builder: (_) => const Text('Inside'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Inside'), findsOneWidget);
    // near the bottom: it opens above the button
    expect(
      tester.getBottomLeft(find.byType(BnPopover)).dy,
      lessThan(tester.getTopLeft(find.text('Open')).dy),
    );

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(find.text('Inside'), findsNothing);
  });

  testWidgets('a dialog returns the value of the pressed button', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: BadNotesTheme.create(.light),
        home: Builder(
          builder: (context) => Center(
            child: BnButton(
              label: 'Delete',
              onPressed: () async => result = await showBnDialog<bool>(
                context: context,
                title: 'Delete notebook?',
                message: 'It moves to Trash.',
                actions: const [
                  BnDialogAction('Cancel', value: false),
                  BnDialogAction('Delete', value: true, destructive: true),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete notebook?'), findsOneWidget);
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}
