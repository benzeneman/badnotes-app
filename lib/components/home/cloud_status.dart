import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/bn_home_dialogs.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:badnotes/data/nextcloud/badnotes_syncer.dart';
import 'package:badnotes/data/nextcloud/remote_store.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/routes.dart';
import 'package:badnotes/pages/editor/editor.dart';

/// What kind of thing stopped syncing.
enum SyncProblem {
  storageFull,
  signIn,
  offline,
  other;

  static SyncProblem? of(Object? error) => switch (error) {
    null => null,
    CloudAuthRequired() => signIn,
    SocketException() => offline,
    CloudHttpException(:final statusCode, :final body)
        when statusCode == 507 ||
            body.contains('storageQuotaExceeded') ||
            body.contains('quotaLimitReached') ||
            body.contains('insufficientStorage') =>
      storageFull,
    CloudHttpException(statusCode: 401) => signIn,
    _ => other,
  };

  /// Worth a banner, as it won't fix itself.
  bool get serious => this == storageFull || this == signIn;

  String get title => switch (this) {
    storageFull => 'Not Enough ${_provider()} Storage',
    signIn => 'Sign In to ${_provider()} Again',
    offline => "You're Offline",
    other => "Some Notes Couldn't Sync",
  };

  String get message => switch (this) {
    storageFull =>
      "BadNotes can't sync your notes to ${_provider()}. Your notes are still "
          'saved on this device. Free up space in your ${_provider()} account.',
    signIn =>
      'Your ${_provider()} sign-in has expired. Your notes are still saved on '
          'this device until you sign in again.',
    offline => 'Your notes are saved on this device and sync once you are '
        'back online.',
    other => 'Your notes are still saved on this device. BadNotes keeps '
        'trying to sync them.',
  };
}

String _provider() => switch (stows.syncProvider.value) {
  SyncProvider.oneDrive => 'OneDrive',
  SyncProvider.googleDrive => 'Google Drive',
};

/// How many notes haven't reached the cloud yet.
int _unsyncedNotes() => {
  for (final path in SyncStatus.waiting)
    if (path.endsWith(Editor.extension) || path.endsWith(Editor.extensionOldJson))
      path,
}.length;

/// Rebuilds with anything the sync status depends on.
void _useSyncStatus() {
  useListenable(stows.username);
  useListenable(SyncStatus.error);
  useListenable(SyncStatus.failedUploads);
  useStream(syncer.uploader.queueStream);
  useStream(syncer.downloader.queueStream);
}

void _syncNow() {
  syncer.downloader.refresh();
  syncer.uploader.refresh();
}

/// The cloud next to the New button: red when syncing stopped, and a panel
/// of what's going on when tapped (design N09).
class CloudStatusButton extends HookWidget {
  const CloudStatusButton({super.key});

  @override
  Widget build(BuildContext context) {
    _useSyncStatus();
    final colors = BadNotesColors.of(context);
    final problem = SyncProblem.of(SyncStatus.error.value);
    final busy =
        syncer.uploader.pendingNotEmpty || syncer.downloader.pendingNotEmpty;

    final IconData icon;
    final Color color;
    if (!stows.loggedIn) {
      (icon, color) = (BnIcons.cloudOff, colors.text2);
    } else if (problem != null) {
      (icon, color) = (BnIcons.cloud, colors.danger);
    } else if (busy) {
      (icon, color) = (LucideIcons.cloudUpload, colors.accent);
    } else {
      (icon, color) = (BnIcons.synced, colors.text2);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        BnIconButton(
          tooltip: 'Cloud & backup status',
          icon: icon,
          color: color,
          size: 40,
          radius: 12,
          onPressed: () => showAnchoredPanel<void>(
            context,
            anchor: rectOf(context),
            width: 350,
            builder: (_) => _CloudStatusPanel(home: context),
          ),
        ),
        if (stows.loggedIn && problem != null)
          Positioned(
            right: 6,
            bottom: 6,
            child: IgnorePointer(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: colors.danger,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.surface, width: 1.5),
                ),
                child: const Icon(
                  Icons.priority_high,
                  size: 8,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CloudStatusPanel extends HookWidget {
  const _CloudStatusPanel({required this.home});

  /// Where to go from, as the panel closes first.
  final BuildContext home;

  @override
  Widget build(BuildContext context) {
    _useSyncStatus();
    useListenable(stows.syncOnlyOnWifi);
    final colors = BadNotesColors.of(context);
    final problem = SyncProblem.of(SyncStatus.error.value);
    final unsynced = _unsyncedNotes();

    void close(void Function() then) {
      Navigator.pop(context);
      if (home.mounted) then();
    }

    final String title;
    final String message;
    final IconData icon;
    final bool bad;
    if (!stows.loggedIn) {
      title = 'Not Syncing';
      message = 'Your notes are only on this device. Sign in to Google Drive '
          'or OneDrive to back them up and use them on your other devices.';
      icon = BnIcons.cloudOff;
      bad = false;
    } else if (problem != null) {
      title = problem.title;
      message = problem.message;
      icon = LucideIcons.triangleAlert;
      bad = true;
    } else if (unsynced > 0) {
      title = 'Syncing';
      message = '$unsynced ${unsynced == 1 ? 'note is' : 'notes are'} going '
          'up to ${_provider()}.';
      icon = LucideIcons.cloudUpload;
      bad = false;
    } else {
      title = 'Up to Date';
      message = 'All your notes are backed up to ${_provider()}.';
      icon = BnIcons.check;
      bad = false;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: .stretch,
        mainAxisSize: .min,
        children: [
          Row(
            spacing: 14,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: bad
                      ? Color.alphaBlend(
                          colors.danger.withValues(alpha: 0.12),
                          colors.surface,
                        )
                      : colors.accentTint,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.hairline),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: bad ? colors.danger : colors.text,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: bad ? colors.danger : colors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stows.loggedIn
                          ? '${describeSyncStatus()} · ${_provider()}'
                          : 'Only on this device',
                      style: BnType.caption.copyWith(color: colors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.sunkenSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: .start,
              spacing: 6,
              children: [
                Text(
                  message,
                  style: BnType.body.copyWith(
                    fontWeight: FontWeight.w400,
                    height: 1.45,
                    color: colors.text2,
                  ),
                ),
                if (stows.loggedIn && problem != null)
                  Text(
                    "Don't delete BadNotes until your notes sync, or they may "
                    'be lost.',
                    style: BnType.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.text,
                    ),
                  ),
              ],
            ),
          ),
          if (stows.loggedIn) ...[
            const SizedBox(height: 12),
            BnToggleRow(
              label: 'Sync only on Wi-Fi',
              value: stows.syncOnlyOnWifi.value,
              onChanged: (value) => stows.syncOnlyOnWifi.value = value,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: BnPillButton(
                  label: !stows.loggedIn
                      ? 'Sign In'
                      : problem == null
                      ? 'Sync now'
                      : 'Retry syncing',
                  icon: stows.loggedIn ? LucideIcons.refreshCw : null,
                  kind: BnPillKind.tint,
                  height: 46,
                  expand: true,
                  onPressed: stows.loggedIn
                      ? () => close(_syncNow)
                      : () => close(() => home.push(RoutePaths.login)),
                ),
              ),
              BnPillButton(
                label: 'Settings',
                height: 46,
                onPressed: () =>
                    close(() => home.go(HomeRoutes.routes.last.path)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A card along the bottom when syncing stopped and won't start again by
/// itself, until it's dismissed.
class SyncErrorBanner extends HookWidget {
  const SyncErrorBanner({super.key});

  /// Dismissed for the rest of this session, on every page.
  static final _dismissed = ValueNotifier<SyncProblem?>(null);

  @override
  Widget build(BuildContext context) {
    _useSyncStatus();
    useListenable(_dismissed);
    final problem = SyncProblem.of(SyncStatus.error.value);
    final shown =
        stows.loggedIn &&
            problem != null &&
            problem.serious &&
            problem != _dismissed.value
        ? problem
        : null;
    final colors = BadNotesColors.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Align(
      alignment: .bottomCenter,
      child: AnimatedSwitcher(
        duration: BnMotion.normal,
        transitionBuilder: (child, animation) => SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.4),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: BnMotion.curve)),
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: shown == null
            ? const SizedBox.shrink()
            : Padding(
                key: ValueKey(shown),
                padding: EdgeInsets.fromLTRB(16, 0, 16, bottom + 12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: DecoratedBox(
                    decoration: popoverDecoration(context),
                    child: Material(
                      type: MaterialType.transparency,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
                        child: Row(
                          spacing: 12,
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Color.alphaBlend(
                                  colors.danger.withValues(alpha: 0.12),
                                  colors.surface,
                                ),
                                borderRadius: BorderRadius.circular(
                                  BnRadius.control,
                                ),
                              ),
                              child: Icon(
                                BnIcons.cloudOff,
                                size: 18,
                                color: colors.danger,
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: .start,
                                mainAxisSize: .min,
                                spacing: 2,
                                children: [
                                  Text(
                                    shown.title,
                                    style: BnType.body.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colors.text,
                                    ),
                                  ),
                                  Text(
                                    shown.message,
                                    style: BnType.caption.copyWith(
                                      color: colors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (shown == SyncProblem.signIn)
                              BnButton.primary(
                                label: 'Sign In',
                                height: 34,
                                onPressed: () =>
                                    context.push(RoutePaths.login),
                              ),
                            BnButton(
                              label: 'OK',
                              kind: BnButtonKind.quiet,
                              height: 34,
                              onPressed: () => _dismissed.value = shown,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

/// The signed in account's initial, which opens the settings.
class AccountButton extends HookWidget {
  const AccountButton({super.key});

  @override
  Widget build(BuildContext context) {
    final username = useValueListenable(stows.username).trim();
    final signedIn = stows.loggedIn && username.isNotEmpty;
    return IconButton(
      tooltip: signedIn ? username : 'Settings',
      onPressed: () => context.go(HomeRoutes.routes.last.path),
      icon: CircleAvatar(
        radius: 16,
        backgroundColor: signedIn
            ? const Color(0xFF19C3A0)
            : ColorScheme.of(context).surfaceContainerHighest,
        child: signedIn
            ? Text(
                username.characters.first.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              )
            : Icon(
                Icons.person_outline,
                size: 20,
                color: ColorScheme.of(context).onSurfaceVariant,
              ),
      ),
    );
  }
}
