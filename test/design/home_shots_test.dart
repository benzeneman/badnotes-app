@Tags(['design'])
library;

import 'dart:io';

import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/theming/dynamic_material_app.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/data/flavor_config.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/routes.dart';
import 'package:badnotes/i18n/strings.g.dart';
import 'package:badnotes/pages/home/browse.dart';
import 'package:badnotes/pages/home/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../utils/test_mock_channel_handlers.dart';
import 'design_shot.dart';

/// The home screens next to their mockups (design M_Home, M_Portrait, N02,
/// N03, N15–N19, N22, N24), with notebooks and folders like the mockups'.
void main() {
  late Directory docs;

  setUp(() async {
    FlavorConfig.setup();
    setupMockPathProvider();
    BrowsePage.overrideChildren = null;
    docs = Directory.systemTemp.createTempSync('badnotes-home-shots');
    await FileManager.init(
      documentsDirectory: docs.path,
      shouldWatchRootDirectory: false,
    );
  });

  tearDown(() {
    stows.favoriteNotes.value = [];
    stows.recentFiles.value = [];
    docs.deleteSync(recursive: true);
  });

  final now = DateTime.now();

  /// A note at [path] with a solid [cover], last edited [ago].
  void note(String path, {int? cover, Duration ago = Duration.zero}) {
    final file = File('${docs.path}$path.sbn2')..createSync(recursive: true);
    file.writeAsBytesSync(const [0]);
    file.setLastModifiedSync(now.subtract(ago));
    if (cover != null) {
      File('${docs.path}$path.cover').writeAsStringSync(
        cover.toRadixString(16),
      );
    }
  }

  void folder(String path, {String color = 'lavender', String? icon, int notes = 0, List<int> covers = const []}) {
    Directory('${docs.path}$path').createSync(recursive: true);
    File('${docs.path}$path/.style.json').writeAsStringSync(
      '{"color":"$color"${icon == null ? '' : ',"icon":"$icon"'}}',
    );
    for (int i = 0; i < notes; i++) {
      note(
        '$path/Note ${i + 1}',
        cover: i < covers.length ? covers[i] : null,
        ago: Duration(hours: i + 1),
      );
    }
  }

  void desk({bool manyFolders = false}) {
    folder('/College', icon: 'cap', notes: 12, covers: [0xFFE8E1FB, 0xFF2B2B30]);
    folder('/Personal', color: 'peach', icon: 'heart', notes: 7, covers: [0xFFFFFFFF, 0xFFFBE3DA]);
    folder('/Work', color: 'mint', icon: 'work', notes: 9, covers: [0xFFF7ECCF, 0xFFFFFFFF]);
    folder('/test', color: 'sand', icon: 'flask', notes: 2, covers: [0xFFFFFFFF]);
    if (manyFolders) {
      folder('/Exams 2026', color: 'sky', icon: 'book', notes: 4);
      folder('/Recipes', color: 'rose', icon: 'leaf', notes: 3);
      folder('/Coaching', icon: 'calc', notes: 6);
      folder('/Travel', color: 'mint', icon: 'plane', notes: 2);
      folder('/Ideas', color: 'peach', icon: 'star', notes: 5);
    }
    note('/Physics — Class 12', cover: 0xFFE8E1FB, ago: const Duration(minutes: 2));
    note('/Maths Formula Book', cover: 0xFF2B2B30, ago: const Duration(minutes: 30));
    note('/Daily Journal', cover: 0xFFFBE3DA, ago: const Duration(days: 1));
    note('/Hindi Vyakaran', cover: 0xFFDCEFE9, ago: const Duration(days: 2));
    note('/Project Ideas', cover: 0xFFF7ECCF, ago: const Duration(days: 3));
    note('/26-11-21 Untitled', ago: const Duration(minutes: 5));
    stows.favoriteNotes.value = ['/Maths Formula Book', '/College', '/Daily Journal'];
    stows.recentFiles.value = [
      for (final n in [
        '26-11-21 Untitled',
        'Physics — Class 12',
        'Maths Formula Book',
        'Daily Journal',
        'Hindi Vyakaran',
      ])
        '/$n.sbn2',
    ];
  }

  Future<void> shot(
    WidgetTester tester,
    String name, {
    String subpage = HomePage.browseSubpage,
    String? path,
    Size size = tabletLandscape,
    String? mockup,
    Future<void> Function(WidgetTester tester)? setUp,
  }) async {
    await designShot(
      tester,
      name,
      _HomeApp(subpage: subpage, path: path),
      size: size,
      mockup: mockup ?? name,
      setUp: (tester) async {
        // the folder listing and covers are read from disk
        for (int i = 0; i < 12; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 120)),
          );
          await tester.pump(const Duration(milliseconds: 100));
        }
        if (setUp != null) await setUp(tester);
      },
    );
  }

  testWidgets('desk', (tester) async {
    desk();
    await shot(tester, 'M_Home');
    expect(find.text('Folders'), findsWidgets);
    expect(find.text('College'), findsWidgets);
    expect(find.text('Physics — Class 12'), findsWidgets);
  });

  testWidgets('desk, portrait', (tester) async {
    desk();
    await shot(tester, 'M_Portrait', size: tabletPortrait);
  });

  testWidgets('inside a folder', (tester) async {
    desk();
    await shot(tester, 'N15_FolderOpen', path: '/College');
    expect(find.text('Add here'), findsOneWidget);
  });

  testWidgets('empty desk', (tester) async {
    await shot(tester, 'N22_Empty');
    expect(find.text('Your desk is empty'), findsOneWidget);
  });

  testWidgets('recent', (tester) async {
    desk();
    await shot(tester, 'N16_Recent', subpage: HomePage.recentSubpage);
    expect(find.text('Today'), findsWidgets);
  });

  testWidgets('favorites', (tester) async {
    desk();
    await shot(tester, 'N17_Starred', subpage: HomePage.favoritesSubpage);
    expect(find.text('Maths Formula Book'), findsWidgets);
    expect(find.text('College'), findsWidgets);
  });

  testWidgets('all folders', (tester) async {
    desk(manyFolders: true);
    await shot(
      tester,
      'N19_AllFolders',
      setUp: (tester) async {
        await tester.tap(find.text('See all'));
        await tester.pump(const Duration(milliseconds: 300));
      },
    );
    expect(find.text('All folders'), findsOneWidget);
  });

  testWidgets('a notebook held down', (tester) async {
    desk();
    await shot(
      tester,
      'N02_NotebookHold',
      setUp: (tester) async {
        await tester.longPress(
          find.ancestor(
            of: find.text('Physics — Class 12'),
            matching: find.byType(Column),
          ).first,
        );
        await tester.pump(const Duration(milliseconds: 300));
      },
    );
    expect(find.text('Export as PDF'), findsOneWidget);
  });

  testWidgets('a folder held down', (tester) async {
    desk();
    await shot(
      tester,
      'N03_FolderHold',
      setUp: (tester) async {
        await tester.longPress(find.text('College'));
        await tester.pump(const Duration(milliseconds: 300));
      },
    );
    expect(find.text('Folder color'), findsOneWidget);
  });

  testWidgets('several notebooks picked', (tester) async {
    desk();
    await shot(
      tester,
      'N24_Select',
      setUp: (tester) async {
        Future<void> pick(String name) async {
          await tester.longPress(
            find.ancestor(of: find.text(name), matching: find.byType(Column)).first,
          );
          await tester.pump(const Duration(milliseconds: 300));
        }

        await pick('Physics — Class 12');
        await tester.tap(find.text('Select'));
        await tester.pump(const Duration(milliseconds: 300));
        for (final name in ['Maths Formula Book', 'Hindi Vyakaran']) {
          await tester.tap(find.text(name).first);
          await tester.pump(const Duration(milliseconds: 100));
        }
      },
    );
    expect(find.text('3 selected'), findsOneWidget);
  });
}

class _HomeApp extends StatelessWidget {
  const _HomeApp({required this.subpage, this.path});

  final String subpage;
  final String? path;

  @override
  Widget build(BuildContext context) {
    final theme = BadNotesTheme.create(designBrightness);
    final router = GoRouter(
      initialLocation: subpage == HomePage.browseSubpage
          ? HomeRoutes.browseFilePath(path ?? '')
          : '${RoutePaths.prefixOfHome}/$subpage',
      routes: [
        GoRoute(
          path: RoutePaths.home,
          builder: (context, state) => HomePage(
            subpage: state.pathParameters['subpage'] ?? HomePage.recentSubpage,
            path: state.uri.queryParameters['path'],
          ),
        ),
      ],
    );
    return TranslationProvider(
      child: ExplicitlyThemedApp(
        title: 'BadNotes',
        router: router,
        themeMode: designDark ? ThemeMode.dark : ThemeMode.light,
        theme: theme,
        darkTheme: theme,
      ),
    );
  }
}
