import 'package:badnotes/components/ui/bn_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:badnotes/components/theming/dynamic_material_app.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/data/flavor_config.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/routes.dart';
import 'package:badnotes/i18n/strings.g.dart';
import 'package:badnotes/pages/home/browse.dart';
import 'package:badnotes/pages/home/home.dart';

import 'utils/test_mock_channel_handlers.dart';

void main() {
  group('Browse page folder navigation', () {
    setUp(() {
      FlavorConfig.setup();
      setupMockPathProvider();
      FileManager.init(shouldWatchRootDirectory: false);
      BrowsePage.overrideChildren = DirectoryChildren(
        const ['subfolder1', 'subfolder2'],
        const ['file1', 'file2', 'file3'],
      );
    });
    testWidgets('No back folder at root', (tester) async {
      await tester.pumpWidget(const _BrowseApp());
      await tester.pump();
      expect(find.byIcon(BnIcons.back), findsNothing);
    });
    testWidgets('Back folder present in subfolder', (tester) async {
      await tester.pumpWidget(const _BrowseApp(path: '/helloworld'));
      await tester.pump();
      expect(find.byIcon(BnIcons.back), findsOneWidget);
    });
    testWidgets('Navigate back to root', (tester) async {
      await tester.pumpWidget(const _BrowseApp(path: '/helloworld'));
      await tester.pump();
      await tester.tap(find.byIcon(BnIcons.back));
      await tester.pump();
      expect(find.byIcon(BnIcons.back), findsNothing);
    });
    testWidgets('Navigate back twice to root', (tester) async {
      await tester.pumpWidget(const _BrowseApp(path: '/helloworld'));
      await tester.pump();
      await tester.tap(find.text('subfolder1'));
      await tester.pump();
      expect(find.byIcon(BnIcons.back), findsOneWidget);
      await tester.tap(find.byIcon(BnIcons.back));
      await tester.pump();
      expect(find.byIcon(BnIcons.back), findsOneWidget);
      await tester.tap(find.byIcon(BnIcons.back));
      await tester.pump();
      expect(find.byIcon(BnIcons.back), findsNothing);
    });
  });
}

class _BrowseApp extends StatelessWidget {
  const new({this.path});
  final String? path;
  @override
  Widget build(BuildContext context) {
    final theme = BadNotesTheme.create(.light);
    final router = GoRouter(
      initialLocation: HomeRoutes.browseFilePath(path ?? ''),
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
        themeMode: ThemeMode.light,
        theme: theme,
        darkTheme: theme,
      ),
    );
  }
}
