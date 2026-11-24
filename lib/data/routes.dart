import 'package:flutter/material.dart';
import 'package:path_to_regexp/path_to_regexp.dart';
import 'package:badnotes/i18n/strings.g.dart';
import 'package:badnotes/pages/home/home.dart';

/// The URL paths of the app's screens, plus helpers that build links to the
/// editor. Only a namespace; never instantiated.
abstract class RoutePaths {
  /// Everything under the home screen starts with this.
  static const prefixOfHome = '/home';

  /// A home section; `:subpage` is one of the [HomePage] subpage names.
  static const home = '$prefixOfHome/:subpage';
  static const edit = '/edit';
  static const login = '/login';
  static const logs = '/logs';

  /// The editor, opened on the note at [filePath].
  static String editFilePath(String filePath) =>
      _editorWith({'path': filePath});

  /// The editor, creating the note at [filePath] from the PDF at [pdfPath].
  static String editImportPdf(String filePath, String pdfPath) =>
      _editorWith({'path': filePath, 'pdfPath': pdfPath});

  static String _editorWith(Map<String, String> query) {
    final pairs = query.entries.map(
      (e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}',
    );
    return '$edit?${pairs.join('&')}';
  }
}

/// The home tabs, in the order the tab bar shows them.
abstract class HomeRoutes {
  static final PathFunction _sectionPath = pathToFunction(RoutePaths.home);

  /// The Documents tab, showing the folder [filePath]; the root folder (or
  /// none) gives the plain tab link.
  static String browseFilePath(String? filePath) {
    final tab = routes.first.path;
    final isRoot = filePath == null || filePath.isEmpty || filePath == '/';
    if (isRoot) return tab;
    return '$tab?path=${Uri.encodeQueryComponent(filePath)}';
  }

  /// Built fresh on each read so the translated labels follow the language.
  static List<HomeRoute> get routes => [
    for (final (subpage, destination) in _tabs())
      HomeRoute._(_sectionPath({'subpage': subpage}), destination: destination),
  ];

  static List<(String, NavigationDestination)> _tabs() => [
    (
      HomePage.browseSubpage,
      const NavigationDestination(
        label: 'Documents',
        icon: Icon(Icons.grid_view_outlined),
        selectedIcon: Icon(Icons.grid_view_rounded),
      ),
    ),
    (
      HomePage.recentSubpage,
      const NavigationDestination(
        label: 'Recent',
        icon: Icon(Icons.schedule_outlined),
        selectedIcon: Icon(Icons.schedule),
      ),
    ),
    (
      HomePage.favoritesSubpage,
      const NavigationDestination(
        label: 'Favorites',
        icon: Icon(Icons.star_outline_rounded),
        selectedIcon: Icon(Icons.star_rounded),
      ),
    ),
    (
      HomePage.whiteboardSubpage,
      NavigationDestination(
        label: t.home.tabs.whiteboard,
        icon: const Icon(Icons.draw_outlined),
        selectedIcon: const Icon(Icons.draw),
      ),
    ),
    (
      HomePage.settingsSubpage,
      NavigationDestination(
        label: t.home.tabs.settings,
        icon: const Icon(Icons.settings_outlined),
        selectedIcon: const Icon(Icons.settings),
      ),
    ),
  ];
}

/// One home tab: where it leads and how it looks in the tab bar.
class HomeRoute {
  const new _(this.path, {required this.destination});

  final String path;
  final NavigationDestination destination;
}
