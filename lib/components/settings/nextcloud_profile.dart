import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/bn_settings.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/data/nextcloud/badnotes_syncer.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/quota.dart';
import 'package:badnotes/data/routes.dart';
import 'package:badnotes/i18n/strings.g.dart';
import 'package:badnotes/pages/user/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The cloud account at the top of the settings: who is signed in and how
/// full their storage is, then, once signed in, a card saying whether
/// everything is synced, with a button to upload it all again.
class const NextcloudProfile({super.key}) extends HookWidget {
  /// Tests set this to show a login state without signing in.
  @visibleForTesting
  static LoginStep? forceLoginStep;

  /// Fetches the storage quota and remembers it. Offline (or with a forced
  /// login step) the last known quota is kept.
  static Future<Quota?> getStorageQuota() async {
    if (forceLoginStep != null) return stows.lastStorageQuota.value;

    final store = BadNotesSyncInterface.store;
    if (store == null) return stows.lastStorageQuota.value = null;

    try {
      return stows.lastStorageQuota.value = await store.quota();
    } catch (_) {
      return stows.lastStorageQuota.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    // the quota is fetched again whenever any of the credentials change
    final username = useValueListenable(stows.username);
    final encPassword = useValueListenable(stows.encPassword);
    final key = useValueListenable(stows.key);
    final iv = useValueListenable(stows.iv);
    final pfp = useValueListenable(stows.pfp);
    final quota = useValueListenable(stows.lastStorageQuota);
    useMemoized(getStorageQuota, [username, encPassword, key, iv]);

    // rebuild as syncing moves along
    final needsLogin = useValueListenable(stows.syncNeedsLogin);
    useValueListenable(stows.lastSyncedMs);
    useStream(syncer.uploader.queueStream);
    useStream(syncer.downloader.queueStream);

    final step = forceLoginStep ?? NcLoginPage.getCurrentStep();
    final signedIn = step == .done;
    final greeting = switch (step) {
      .waitingForPrefs => '',
      .nc => t.login.status.loggedOut,
      .enc || .done => t.login.status.hi(u: stows.username.value),
    };
    final status = switch (step) {
      .waitingForPrefs => '',
      .nc => t.login.status.tapToLogin,
      .enc => t.login.status.almostDone,
      .done when needsLogin => t.profile.signInAgainNeeded,
      .done => describeSyncStatus(),
    };
    void openLogin() => context.push(RoutePaths.login);

    final accountRow = BnSettingsRow(
      minHeight: 52,
      onTap: openLogin,
      leading: BnSettingsTile(
        icon: LucideIcons.user,
        child: pfp == null
            ? null
            : Image.memory(pfp, width: 36, height: 36, fit: BoxFit.cover),
      ),
      title: greeting,
      titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      subtitle: signedIn ? null : status,
      trailing: signedIn
          ? _QuotaSummary(quota: quota)
          : BnButton(label: t.login.title, height: 34, onPressed: openLogin),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        BnSettingsGroup(label: 'Cloud sync', children: [accountRow]),
        if (signedIn)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _SyncCard(
              needsLogin: needsLogin,
              status: status,
              openLogin: openLogin,
            ),
          ),
      ],
    );
  }
}

/// Whether the notes are synced (or the cloud wants the user to sign in
/// again), next to a button that uploads everything again.
class _SyncCard extends StatelessWidget {
  const new({
    required this.needsLogin,
    required this.status,
    required this.openLogin,
  });

  final bool needsLogin;
  final String status;
  final VoidCallback openLogin;

  /// Marks every file as needing upload and queues them all.
  static Future<void> _resyncEverything() async {
    stows.fileSyncResyncEverythingDate.value = DateTime.now();
    final everything = await FileManager.getAllFiles(
      includeExtensions: true,
      includeAssets: true,
    );
    for (final file in everything) {
      syncer.uploader.enqueueRel(file);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final idle = syncer.uploader.numPending + syncer.downloader.numPending == 0;

    final BnSettingsTile badge;
    final String title;
    if (needsLogin) {
      badge = BnSettingsTile(
        round: true,
        icon: LucideIcons.cloudAlert,
        color: colors.danger.withValues(alpha: 0.12),
        iconColor: colors.danger,
      );
      title = t.profile.signInAgainNeeded;
    } else {
      badge = BnSettingsTile(
        round: true,
        icon: LucideIcons.check,
        color: colors.successTint,
        iconColor: colors.success,
      );
      title = idle ? 'Up to date' : 'Syncing';
    }

    return BnCard(
      child: BnSettingsRow(
        minHeight: 42,
        onTap: needsLogin ? openLogin : null,
        leading: badge,
        title: title,
        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        subtitle: needsLogin ? null : status,
        trailing: Tooltip(
          message: t.settings.resyncEverything,
          child: BnButton(
            label: t.settings.resyncEverything,
            icon: LucideIcons.cloudUpload,
            onPressed: _resyncEverything,
          ),
        ),
      ),
    );
  }
}

/// A short bar of how much cloud storage is used, over a "1 GB / 15 GB"
/// style caption.
class _QuotaSummary extends StatelessWidget {
  const new({required this.quota});

  final Quota? quota;

  @override
  Widget build(BuildContext context) {
    final caption =
        quota?.describeConcise() ?? Quota.describeConcisePlaceholder();
    return SizedBox(
      width: 120,
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .end,
        spacing: 6,
        children: [
          Semantics(
            label: 'Storage usage',
            child: BnProgressLine(
              value: quota?.progressIndicatorValue ?? 0,
              height: 4,
            ),
          ),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: BnType.caption.copyWith(
              color: BadNotesColors.of(context).muted,
            ),
          ),
        ],
      ),
    );
  }
}
