import 'package:badnotes/components/home/home_shell.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/routes.dart';
import 'package:badnotes/pages/home/home.dart';
import 'package:badnotes/pages/home/whiteboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:path_to_regexp/path_to_regexp.dart';
import 'package:stow_codecs/stow_codecs.dart';

/// The frame around the home pages: the page itself, with the floating dock
/// of tabs (and its New button) over the bottom of it.
class ResponsiveNavbar extends HookWidget {
  const new({super.key, required this.body, this.selectedIndex = 0});

  /// The home page on screen.
  final Widget body;

  /// Its index in [HomeRoutes.routes]; negative for a page that isn't a tab
  /// (such as the trash).
  final int selectedIndex;

  /// The dock's tabs, in the same order as [HomeRoutes.routes]. Settings
  /// isn't among them: it opens from the avatar.
  static const tabs = [
    BnDockTab('Desk', BnIcons.desk),
    BnDockTab('Recent', BnIcons.recent),
    BnDockTab('Favorites', BnIcons.favorites),
    BnDockTab('Whiteboard', BnIcons.whiteboard),
  ];

  /// Space between the dock and the bottom safe area.
  static const _dockLift = 22.0;

  /// Goes to the tab at [index]. Leaving the whiteboard waits until it has
  /// been saved: an unsaved board is saved first and the tap is dropped.
  void onDestinationSelected(BuildContext context, int index) {
    if (index == selectedIndex) return;
    final routes = HomeRoutes.routes;
    if (selectedIndex >= 0 && _leavingUnsavedWhiteboard(routes)) return;
    context.go(routes[index].path);
  }

  /// Whether the current tab is the whiteboard and it isn't safe to leave
  /// yet. Kicks off the save if one is waiting.
  bool _leavingUnsavedWhiteboard(List<HomeRoute> routes) {
    final whiteboardPath = pathToFunction(RoutePaths.home)({
      'subpage': HomePage.whiteboardSubpage,
    });
    if (routes[selectedIndex].path != whiteboardPath) return false;

    switch (Whiteboard.savingState) {
      case null:
      case .saved:
        return false;
      case .waitingToSave:
        Whiteboard.triggerSave();
        return true;
      case .saving:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    useListenable(stows.locale); // the dock's labels follow the language
    // no dock while the keyboard is up or notes are being selected
    final selecting = useValueListenable(HomeChrome.selecting);
    final media = MediaQuery.of(context);
    final showDock = media.viewInsets.bottom == 0 && !selecting;
    final dockRoom = HomeChrome.bottomRoom(context);

    // The page is told the dock is part of its bottom safe area, so it can
    // scroll under the dock and still end above it.
    final page = MediaQuery(
      data: media.copyWith(
        padding: media.padding.copyWith(
          bottom: showDock ? dockRoom : media.padding.bottom,
        ),
      ),
      child: body,
    );

    return ColoredBox(
      color: BadNotesColors.of(context).desk,
      child: Stack(
        fit: StackFit.expand,
        children: [
          page,
          if (showDock)
            Positioned(
              left: 0,
              right: 0,
              bottom: media.padding.bottom + _dockLift,
              child: Center(
                child: Material(
                  type: MaterialType.transparency,
                  child: Builder(
                    builder: (context) => BnHomeDock(
                      tabs: tabs,
                      selected: selectedIndex < tabs.length
                          ? selectedIndex
                          : -1,
                      onSelect: (i) => onDestinationSelected(context, i),
                      compact: media.size.width < 900,
                      newLabel: 'New',
                      onNew: () => _openNewMenu(context),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Shows the current page's New menu, anchored under the right-hand end
  /// of the dock where the New button is.
  void _openNewMenu(BuildContext dockContext) {
    final dock = dockContext.findRenderObject()! as RenderBox;
    final topLeft = dock.localToGlobal(Offset(dock.size.width - 100, 0));
    HomeChrome.newMenu.value.show(dockContext, topLeft & const Size(100, 1));
  }
}

/// The sidebar shown instead of the dock on wide screens, and whether it is
/// open.
abstract final class HomeSidebar {
  /// The narrowest screen that gets a sidebar.
  static const fromWidth = 1000.0;
  static const width = 280.0;

  static final open = ValueNotifier(true);
}

/// How the app lays itself out: by screen size, or as a phone or tablet
/// whatever the size. Saved by index, so the order must stay.
enum LayoutSize {
  auto,
  phone,
  tablet;

  static const codec = EnumCodec(values);
}
