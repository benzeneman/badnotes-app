import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:badnotes/components/nextcloud/enc_login_step.dart';
import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/nextcloud/badnotes_syncer.dart';
import 'package:badnotes/data/nextcloud/remote_store.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/quota.dart';
import 'package:badnotes/i18n/strings.g.dart';

/// The last sign-in step, shown once sync is fully set up: who is signed in,
/// how syncing is going, how much cloud space is used, and a way to sign out.
class const DoneLoginStep({
  super.key,
  required final void Function() recheckCurrentStep,
}) extends HookWidget {
  /// The widest the column of content gets on large screens.
  static const width = 420.0;

  /// Asks Google or Microsoft for a fresh token after the old one stopped
  /// working. Only the account already linked is accepted, because another
  /// account's notes would be locked with a different password.
  static Future<void> signInAgain(BuildContext context) async {
    void tell(String message) {
      if (!context.mounted) return;
      showBanner(context, message, kind: BannerKind.error);
    }

    final String email;
    final String credential;
    try {
      (:email, :credential) = await CloudLogin.signIn(stows.syncProvider.value);
    } catch (e) {
      if (!CloudLogin.isCancelled(e)) {
        tell('${t.login.ncLoginStep.cloudLoginFailed}\n$e');
      }
      return;
    }

    final linked = stows.username.value;
    if (email != linked) return tell(t.profile.wrongAccount(email: linked));

    stows.ncPassword.value = credential;
    if (stows.syncProvider.value == SyncProvider.googleDrive) {
      stows.pfp.value = GoogleDriveStore.lastPhoto ?? stows.pfp.value;
    }
    stows.syncNeedsLogin.value = false;
    syncer.downloader.refresh();
    syncer.uploader.refresh();
  }

  /// Forgets the account and everything saved for it, then moves the sign-in
  /// flow back to its first step.
  void _signOut() {
    stows.username.value = '';
    stows.ncPassword.value = '';
    stows.encPassword.value = '';
    stows.pfp.value = null;
    stows.lastStorageQuota.value = null;
    stows.key.value = '';
    stows.iv.value = '';
    stows.cloudSyncState.value = '';
    stows.syncNeedsLogin.value = false;
    stows.lastSyncedMs.value = 0;
    recheckCurrentStep();
  }

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    // Rebuild whenever any of these move, so the status lines stay fresh.
    final needsLogin = useValueListenable(stows.syncNeedsLogin);
    final quota = useValueListenable(stows.lastStorageQuota);
    useValueListenable(stows.lastSyncedMs);
    useStream(syncer.uploader.queueStream);
    useStream(syncer.downloader.queueStream);

    final screen = MediaQuery.sizeOf(context);
    final username = stows.username.value;
    final providerName = switch (stows.syncProvider.value) {
      .googleDrive => 'Google Drive',
      .oneDrive => 'OneDrive',
    };

    return ListView(
      padding: .symmetric(
        horizontal: screen.width > width + 64
            ? (screen.width - width) / 2
            : BnSpace.xl,
        vertical: BnSpace.xl,
      ),
      children: [
        Row(
          children: [
            BnAvatar(
              size: 56,
              iconSize: 24,
              username: username,
              signedIn: username.isNotEmpty,
              textStyle: BnType.display.copyWith(
                fontSize: 22,
                color: colors.accentStrong,
              ),
            ),
            const SizedBox(width: BnSpace.l),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BnType.title.copyWith(color: colors.text),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Connected to $providerName',
                    style: BnType.caption.copyWith(color: colors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: BnSpace.xl),
        BnCard(
          padding: const .all(BnSpace.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    needsLogin ? LucideIcons.triangleAlert : LucideIcons.check,
                    size: 16,
                    color: needsLogin ? colors.danger : colors.success,
                  ),
                  const SizedBox(width: BnSpace.s),
                  Expanded(
                    child: Text(
                      describeSyncStatus(),
                      style: BnType.body.copyWith(color: colors.text),
                    ),
                  ),
                ],
              ),
              if (needsLogin) ...[
                const SizedBox(height: BnSpace.m),
                Text(
                  t.profile.signInAgainNeeded,
                  style: BnType.caption.copyWith(color: colors.danger),
                ),
                const SizedBox(height: BnSpace.s),
                BnButton.primary(
                  label: t.profile.signInAgain,
                  expand: true,
                  onPressed: () => signInAgain(context),
                ),
              ],
              const SizedBox(height: BnSpace.l),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: quota?.progressIndicatorValue,
                  minHeight: 8,
                  backgroundColor: colors.sunken,
                  color: colors.accent,
                ),
              ),
              const SizedBox(height: BnSpace.s),
              Text(
                quota?.describe() ?? Quota.describePlaceholder(),
                style: BnType.caption.copyWith(color: colors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: BnSpace.l),
        BnButton.destructive(
          label: t.profile.logout,
          expand: true,
          height: 44,
          onPressed: _signOut,
        ),
        const SizedBox(height: BnSpace.xl),
        const BnSectionHeader(title: 'Questions'),
        for (final entry in t.profile.faq)
          LoginQuestion(question: entry.q, answer: entry.a),
      ],
    );
  }
}
