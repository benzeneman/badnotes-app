import 'package:badnotes/components/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/data/flavor_config.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/routes.dart';
import 'package:badnotes/main.dart';
import 'package:badnotes/pages/home/browse.dart';
import 'package:badnotes/pages/home/home.dart';
import 'utils/test_mock_channel_handlers.dart';

void main() {
  group('Home subpage transition', () {
    for (final brightness in Brightness.values)
      testWidgets(brightness.name, (tester) async {
        FlavorConfig.setup();
        setupMockPathProvider();
        FileManager.init(shouldWatchRootDirectory: false);
        BrowsePage.overrideChildren = DirectoryChildren([], []);
        stows.layoutSize.value = .phone;

        final router = GoRouter(
          initialLocation: App.initialLocation,
          routes: [
            GoRoute(
              path: RoutePaths.home,
              builder: (context, state) => HomePage(
                subpage:
                    state.pathParameters['subpage'] ?? HomePage.recentSubpage,
                path: state.uri.queryParameters['path'],
              ),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          MaterialApp.router(
            title: 'BadNotes',
            routeInformationProvider: router.routeInformationProvider,
            routeInformationParser: router.routeInformationParser,
            routerDelegate: router.routerDelegate,
          ),
        );

        // the settings are in the account button's menu, not in the dock
        await tester.tap(find.byTooltip('Settings'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        await tester.tap(find.widgetWithText(BnMenuRow, 'Settings'));
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        expect(
          [find.bySemanticsLabel('Recent'), find.text('Logged out')],
          [findsWidgets, findsOneWidget],
        );
      });
  });
}
