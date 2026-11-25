import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:badnotes/components/home/trash.dart';
import 'package:badnotes/components/ui/covered_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:badnotes/components/navbar/responsive_navbar.dart';
import 'package:badnotes/components/onboarding/tour.dart';
import 'package:badnotes/components/settings/update_manager.dart';
import 'package:badnotes/components/theming/dynamic_material_app.dart';
import 'package:badnotes/pages/home/browse.dart';
import 'package:badnotes/pages/home/favorites.dart';
import 'package:badnotes/pages/home/recent_notes.dart';
import 'package:badnotes/pages/home/settings.dart';
import 'package:badnotes/pages/home/trash_page.dart';
import 'package:badnotes/pages/home/whiteboard.dart';

/// The main screen: one of the home sections, picked by [subpage], sitting
/// inside the tab bar.
class HomePage extends StatefulWidget {
  const new({super.key, required this.subpage, required this.path});

  /// Which section is showing; one of the `...Subpage` names below.
  final String subpage;

  /// The folder open in the Documents section, if any.
  final String? path;

  static const recentSubpage = 'recent';
  static const browseSubpage = 'browse';
  static const favoritesSubpage = 'favorites';
  static const whiteboardSubpage = 'whiteboard';
  static const settingsSubpage = 'settings';

  /// Reached from the profile menu and from storage settings; it has no tab.
  static const trashSubpage = 'trash';

  /// The sections that do have a tab, in tab order.
  static const List<String> subpages = [
    browseSubpage,
    recentSubpage,
    favoritesSubpage,
    whiteboardSubpage,
    settingsSubpage,
  ];

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Old trash is cleared at most once while the app is running.
  static var _trashCleared = false;
  Timer? _trashTimer;

  @override
  void initState() {
    DynamicMaterialApp.addFullscreenListener(_rebuild);
    super.initState();

    // context is only usable once initState has returned
    scheduleMicrotask(() {
      if (mounted) UpdateManager.showUpdateDialog(context);
    });
    // the feature tour, once after a fresh install, when the desk is up
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted) maybeShowFeatureTour(context);
    });

    if (!_trashCleared) {
      _trashTimer = Timer(const Duration(seconds: 5), () {
        _trashCleared = true;
        Trash.purgeOld();
      });
    }
  }

  @override
  void dispose() {
    DynamicMaterialApp.removeFullscreenListener(_rebuild);
    _trashTimer?.cancel();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Widget _section() => switch (widget.subpage) {
    HomePage.browseSubpage => BrowsePage(path: widget.path),
    HomePage.favoritesSubpage => const FavoritesPage(),
    HomePage.whiteboardSubpage => const WhiteboardsPage(),
    HomePage.settingsSubpage => const SettingsPage(),
    HomePage.trashSubpage => const TrashPage(),
    _ => const RecentPage(),
  };

  /// Sections cross-fade briefly. Scaling them as well made the switch
  /// stutter on slow phones, since both are painted during the change.
  Widget _fadingSection() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: KeyedSubtree(key: ValueKey(widget.subpage), child: _section()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _fadingSection();
    final whiteboardFullscreen =
        widget.subpage == HomePage.whiteboardSubpage &&
        DynamicMaterialApp.isFullscreen;
    // a fullscreen whiteboard gets the whole screen, without tabs
    if (whiteboardFullscreen) return content;
    return CoveredSnapshot(
      child: ResponsiveNavbar(
        selectedIndex: HomePage.subpages.indexOf(widget.subpage),
        body: content,
      ),
    );
  }
}
