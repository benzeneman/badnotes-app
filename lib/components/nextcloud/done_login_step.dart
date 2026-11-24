import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:badnotes/components/misc/faq.dart';
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
  static const width = 400.0;

  /// Asks Google or Microsoft for a fresh token after the old one stopped
  /// working. Only the account already linked is accepted, because another
  /// account's notes would be locked with a different password.
  static Future<void> signInAgain(BuildContext context) async {
    void tell(String message) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
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
    // Rebuild whenever any of these move, so the status lines stay fresh.
    final needsLogin = useValueListenable(stows.syncNeedsLogin);
    final quota = useValueListenable(stows.lastStorageQuota);
    useValueListenable(stows.lastSyncedMs);
    useStream(syncer.uploader.queueStream);
    useStream(syncer.downloader.queueStream);

    final headline = TextTheme.of(context).headlineSmall;
    final screen = MediaQuery.sizeOf(context);
    final avatar = stows.pfp.value;
    final providerName = switch (stows.syncProvider.value) {
      .googleDrive => 'Google Drive',
      .oneDrive => 'OneDrive',
    };

    return ListView(
      padding: .symmetric(
        horizontal: screen.width > width ? (screen.width - width) / 2 : 16,
        vertical: 16,
      ),
      children: [
        const SizedBox(height: 16),
        if (screen.height > 500) ...[
          SvgPicture.asset(
            'assets/images/sync_done.svg',
            width: width,
            height: min(width * 576 / 844.6693, screen.height * 0.25),
            excludeFromSemantics: true,
          ),
          SizedBox(height: min(64, screen.height * 0.05)),
        ],
        Row(
          children: [
            if (avatar case final picture?)
              Image.memory(picture, width: 32, height: 32)
            else
              const Icon(Icons.account_circle, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                t.login.status.hi(u: stows.username.value),
                style: headline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (needsLogin) ..._reconnectPrompt(context),
        Text(describeSyncStatus()),
        const SizedBox(height: 8),
        Text(quota?.describe() ?? Quota.describePlaceholder()),
        const SizedBox(height: 2),
        LinearProgressIndicator(
          value: quota?.progressIndicatorValue,
          minHeight: 32,
          borderRadius: _buttonCorners(context),
        ),
        const SizedBox(height: 4),
        ElevatedButton(onPressed: _signOut, child: Text(t.profile.logout)),
        const SizedBox(height: 32),
        Text(t.profile.connectedTo, style: const TextStyle(height: 0.8)),
        Text(providerName, style: headline),
        const SizedBox(height: 32),
        Text(t.profile.faqTitle, style: headline),
        FaqListView(
          shrinkWrap: true,
          items: [for (final entry in t.profile.faq) FaqItem(entry.q, entry.a)],
        ),
      ],
    );
  }

  /// The warning and button shown when the cloud token has expired.
  List<Widget> _reconnectPrompt(BuildContext context) => [
    Text(
      t.profile.signInAgainNeeded,
      style: TextStyle(color: ColorScheme.of(context).error),
    ),
    const SizedBox(height: 4),
    FilledButton(
      onPressed: () => signInAgain(context),
      child: Text(t.profile.signInAgain),
    ),
    const SizedBox(height: 8),
  ];

  /// Matches the quota bar's corners to the app's raised buttons, falling
  /// back to an 8 px rounding when the theme doesn't say.
  static BorderRadius _buttonCorners(BuildContext context) =>
      switch (ElevatedButtonTheme.of(context).style?.shape?.resolve({})) {
        final RoundedRectangleBorder rounded => rounded.borderRadius.resolve(
          TextDirection.ltr,
        ),
        _ => const .all(.circular(8)),
      };
}
