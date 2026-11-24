import 'package:badnotes/components/home/cloud_status.dart';
import 'package:badnotes/components/home/new_note_button.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/routes.dart';
import 'package:badnotes/pages/home/search.dart';
import 'package:badnotes/components/home/trash.dart';
import 'package:badnotes/components/settings/app_info.dart';
import 'package:badnotes/pages/home/home.dart';
import 'package:badnotes/pages/home/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';

/// What the home tabs share: the "New" button's menu for the page that is
/// showing, and the page's sizes.
abstract final class HomeChrome {
  /// The New menu for the page on screen; pages set it for their folder.
  static final newMenu = ValueNotifier(const NewDocumentMenu());

  /// Notebooks are being picked: the selection bar takes the dock's place.
  static final selecting = ValueNotifier(false);

  /// Tablet in landscape and wider: the full layout of the mockups.
  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 1100;

  /// A phone: one column.
  static bool isPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;

  /// The space between the screen's sides and the content.
  static double margin(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) return BnSpace.marginLandscape;
    if (width >= 600) return BnSpace.marginPortrait;
    return 16;
  }

  /// Room to leave under the content for the floating dock.
  static double bottomRoom(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom + 22 + 58 + 24;
}

/// The top of every home tab: the logo, search, sync status and account.
class HomeHeader extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final wide = HomeChrome.isWide(context);
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          const _Logo(),
          const SizedBox(width: 10),
          Text(
            'BadNotes',
            style: BnType.title.copyWith(
              color: colors.text,
              letterSpacing: -0.3,
            ),
          ),
          if (wide) ...[
            const Spacer(),
            const Flexible(flex: 0, child: _SearchField()),
            const Spacer(),
          ] else
            const Spacer(),
          if (!wide)
            BnIconButton(
              icon: BnIcons.search,
              size: 40,
              radius: 12,
              tooltip: 'Search',
              onPressed: () => openHomeSearch(context),
            ),
          const SizedBox(width: 6),
          const CloudStatusButton(),
          const SizedBox(width: 6),
          const HomeAvatar(),
        ],
      ),
    );
  }
}

class const _Logo() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const BnLogo(size: 30);
}

/// The search box on wide screens; it opens the search page.
class const _SearchField() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Semantics(
      button: true,
      label: 'Search',
      child: GestureDetector(
        onTap: () => openHomeSearch(context),
        child: Container(
          width: 420,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: colors.sunken,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
          child: Row(
            children: [
              Icon(BnIcons.search, size: 16, color: colors.muted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Search notes, handwriting, photos',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BnType.body.copyWith(
                    color: colors.muted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The account's initial in a soft circle; opens the profile menu.
class HomeAvatar extends HookWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final username = useValueListenable(stows.username).trim();
    final signedIn = stows.loggedIn && username.isNotEmpty;
    return Tooltip(
      message: signedIn ? username : 'Settings',
      child: GestureDetector(
        onTap: () => openProfileMenu(context),
        child: BnAvatar(
          size: 34,
          username: username,
          signedIn: signedIn,
          textStyle: BnType.body.copyWith(
            color: colors.accentStrong,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Opens the profile menu under the avatar (design N10): the account,
/// the theme, shortcuts into the settings, the trash and the version.
void openProfileMenu(BuildContext context) {
  Trash.load();
  showBnPopover<void>(
    anchor: context,
    width: 324,
    builder: (menu) => _ProfileMenu(home: context, menu: menu),
  );
}

class _ProfileMenu extends HookWidget {
  const _ProfileMenu({required this.home, required this.menu});

  final BuildContext home, menu;

  void _settings([String? part]) {
    Navigator.of(menu).pop();
    SettingsPage.openPart = part;
    home.go(HomeRoutes.routes.last.path);
  }

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final username = useValueListenable(stows.username).trim();
    final theme = useValueListenable(stows.appTheme);
    final trash = useValueListenable(Trash.entries);
    final provider = useValueListenable(stows.syncProvider);
    final signedIn = stows.loggedIn && username.isNotEmpty;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            BnAvatar(
              size: 50,
              iconSize: 22,
              username: username,
              signedIn: signedIn,
              textStyle: BnType.title.copyWith(color: colors.accentStrong),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    signedIn ? username : 'Not signed in',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BnType.section.copyWith(color: colors.text),
                  ),
                  Text(
                    signedIn
                        ? 'Synced with ${provider == SyncProvider.oneDrive ? 'OneDrive' : 'Google Drive'}'
                        : 'Notes stay on this device',
                    style: BnType.caption.copyWith(color: colors.muted),
                  ),
                ],
              ),
            ),
            BnButton(
              label: signedIn ? 'Edit' : 'Sign in',
              height: 32,
              onPressed: () => _settings('account'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Theme',
          style: BnType.caption.copyWith(
            color: colors.muted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        BnSegmented<ThemeMode>(
          height: 36,
          segments: const [
            BnSegment(ThemeMode.light, 'Light'),
            BnSegment(ThemeMode.dark, 'Dark'),
            BnSegment(ThemeMode.system, 'Auto'),
          ],
          selected: theme,
          onChanged: (mode) => stows.appTheme.value = mode,
        ),
        const BnDivider(),
        BnMenuRow(
          icon: BnIcons.settings,
          label: 'Settings',
          onTap: _settings,
        ),
        BnMenuRow(
          icon: BnIcons.rename,
          label: 'Pen & stylus',
          onTap: () => _settings('writing'),
        ),
        BnMenuRow(
          icon: BnIcons.download,
          label: 'Backup & export',
          onTap: () => _settings('backup'),
        ),
        BnMenuRow(
          icon: BnIcons.trash,
          label: 'Trash',
          trailing: trash.isEmpty
              ? null
              : Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.sunkenSoft,
                    borderRadius: const BorderRadius.all(Radius.circular(6)),
                  ),
                  child: Text(
                    '${trash.length}',
                    style: BnType.micro.copyWith(color: colors.text2),
                  ),
                ),
          onTap: () {
            Navigator.of(menu).pop();
            home.go('${RoutePaths.prefixOfHome}/${HomePage.trashSubpage}');
          },
        ),
        BnMenuRow(
          icon: BnIcons.help,
          label: 'Help & about',
          onTap: () {
            Navigator.of(menu).pop();
            AppInfo.show(home);
          },
        ),
        const BnDivider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Text(
                'bad notes',
                style: BnType.section.copyWith(
                  color: colors.text,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  AppInfo.info,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BnType.micro.copyWith(color: colors.muted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A tab's big title and the line under it, with [trailing] (e.g. a
/// segmented control) at the right, as at the top of each home tab.
class HomeTitle extends StatelessWidget {
  const new({
    super.key,
    required this.title,
    this.caption,
    this.trailing,
    this.leading,
  });

  final String title;
  final String? caption;
  final Widget? trailing;

  /// Before the title, e.g. a folder.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final stacked = !HomeChrome.isWide(context);
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: BnType.display.copyWith(color: colors.text),
        ),
        if (caption != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              caption!,
              style: BnType.body.copyWith(
                color: colors.muted,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
      ],
    );
    final titled = leading == null
        ? text
        : Row(
            children: [leading!, const SizedBox(width: 14), Flexible(child: text)],
          );
    if (trailing == null) return titled;
    if (stacked && trailing is BnSegmented) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [titled, const SizedBox(height: 22), trailing!],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: titled),
        const SizedBox(width: 16),
        trailing!,
      ],
    );
  }
}

/// "Good morning", "Good afternoon" or "Good evening", by the clock.
String homeGreeting([DateTime? now]) {
  final hour = (now ?? DateTime.now()).hour;
  if (hour < 5) return 'Good evening';
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

/// "2 min ago", "3 h ago", "yesterday", "12 Nov".
String homeAgo(DateTime when, [DateTime? now]) {
  now ??= DateTime.now();
  final d = now.difference(when);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24 && now.day == when.day) return '${d.inHours} h ago';
  final yesterday = now.subtract(const Duration(days: 1));
  if (when.year == yesterday.year &&
      when.month == yesterday.month &&
      when.day == yesterday.day) {
    return 'yesterday';
  }
  return homeShortDate(when);
}

/// "12 Nov", with the year if it isn't this one.
String homeShortDate(DateTime d, [DateTime? now]) {
  now ??= DateTime.now();
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final date = '${d.day} ${months[d.month - 1]}';
  return d.year == now.year ? date : '$date ${d.year}';
}

/// "1:51 PM".
String homeTime(DateTime d) {
  final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '$hour:${d.minute.toString().padLeft(2, '0')} '
      '${d.hour < 12 ? 'AM' : 'PM'}';
}

/// "Today", "Yesterday", "Today, 1:51 PM" style meta under a notebook.
String homeMeta(DateTime d, {bool withTime = false, DateTime? now}) {
  now ??= DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final days = today.difference(day).inDays;
  final label = switch (days) {
    0 => 'Today',
    1 => 'Yesterday',
    _ => homeShortDate(d, now),
  };
  return withTime ? '$label, ${homeTime(d)}' : label;
}
