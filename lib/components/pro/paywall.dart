import 'dart:async';

import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/pro/pro.dart';
import 'package:badnotes/data/pro/pro_billing.dart';
import 'package:badnotes/data/routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the BadNotes Pro paywall, saying [reason] at the top: a sheet
/// from the bottom on a phone, a dialog in the middle on a tablet.
Future<void> showPaywall(
  BuildContext context, {
  ProFeature reason = ProFeature.upgrade,
}) {
  unawaited(ProBilling.init());
  if (ProBilling.step.value != ProBuyStep.pending &&
      ProBilling.step.value != ProBuyStep.waiting) {
    ProBilling.step.value = ProBuyStep.idle;
    ProBilling.message.value = null;
  }
  final colors = BadNotesColors.of(context);
  if (!bnIsWide(context)) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(BnRadius.popover),
        ),
      ),
      builder: (context) => Paywall(reason: reason),
    );
  }
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: colors.scrim,
    transitionDuration: BnMotion.normal,
    pageBuilder: (context, _, _) => Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: BnPopover(
          width: 440,
          padding: EdgeInsets.zero,
          child: Paywall(reason: reason),
        ),
      ),
    ),
    transitionBuilder: (context, animation, _, child) =>
        bnPopIn(context, animation, child),
  );
}

/// What BadNotes Pro gives, and the button that buys it.
class Paywall extends StatefulWidget {
  const new({super.key, this.reason = ProFeature.upgrade});

  final ProFeature reason;

  static const benefits = <(IconData, String, String)>[
    (
      BnIcons.notebook,
      'Unlimited notebooks',
      'Plus unlimited whiteboards and PDFs of any size',
    ),
    (
      BnIcons.synced,
      'Automatic sync',
      'Your notes keep up on every device by themselves',
    ),
    (
      BnIcons.palette,
      'Every cover, colour, tape and font',
      'All cover designs, more colours, your own tapes and fonts',
    ),
    (
      BnIcons.lock,
      'Lock notes and save templates',
      'Keep private notes locked; reuse your own pages',
    ),
    (
      BnIcons.restore,
      'Version history',
      'Go back to an earlier copy of a note',
    ),
    (
      BnIcons.mic,
      'Real-time reveal and Spotlight',
      'Watch your writing replay with your recordings',
    ),
  ];

  @override
  State<Paywall> createState() => _PaywallState();
}

class _PaywallState extends State<Paywall> {
  final _listening = Listenable.merge([
    ProBilling.step,
    ProBilling.message,
    ProBilling.product,
    Pro.isPro,
    stows.username,
  ]);

  @override
  void initState() {
    super.initState();
    _listening.addListener(_changed);
  }

  @override
  void dispose() {
    _listening.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  bool get _busy => switch (ProBilling.step.value) {
    .buying || .activating => true,
    _ => false,
  };

  Future<void> _getPro() async {
    if (Pro.account == null) {
      if (stows.loggedIn &&
          stows.syncProvider.value != SyncProvider.googleDrive) {
        ProBilling.step.value = ProBuyStep.failed;
        ProBilling.message.value =
            'BadNotes Pro is tied to a Google account. Sign in with Google '
            'in Settings › Cloud sync, then come back.';
        return;
      }
      // sign in first: Pro belongs to the Google account
      await GoRouter.of(context).push(RoutePaths.login);
      if (!mounted || Pro.account == null) return;
      // maybe bought already on another device
      ProBilling.step.value = ProBuyStep.activating;
      await Pro.refresh(force: true);
      if (!mounted) return;
      if (Pro.has) {
        ProBilling.step.value = ProBuyStep.done;
        return;
      }
      ProBilling.step.value = ProBuyStep.idle;
    }
    await ProBilling.buy();
  }

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final done = ProBilling.step.value == ProBuyStep.done ||
        (Pro.isPro.value && ProBilling.step.value != ProBuyStep.idle);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      // the offer gives way to the welcome with a short cross-fade
      child: AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : BnMotion.normal,
        switchInCurve: BnMotion.curve,
        switchOutCurve: BnMotion.curve,
        child: KeyedSubtree(
          key: ValueKey(done),
          child: done ? _welcome(context, colors) : _offer(context, colors),
        ),
      ),
    );
  }

  Widget _closeButton(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: BnIconButton(
      icon: BnIcons.close,
      size: 32,
      iconSize: 18,
      tooltip: 'Close',
      onPressed: () => Navigator.of(context).pop(),
    ),
  );

  Widget _welcome(BuildContext context, BadNotesColors colors) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _closeButton(context),
      Center(
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: colors.successTint,
            shape: BoxShape.circle,
          ),
          child: Icon(BnIcons.check, size: 32, color: colors.success),
        ),
      ),
      const SizedBox(height: 18),
      Text(
        'Welcome to BadNotes Pro',
        textAlign: TextAlign.center,
        style: BnType.title.copyWith(color: colors.text),
      ),
      const SizedBox(height: 8),
      Text(
        'Everything is unlocked. Sign in with ${Pro.account ?? 'this Google '
            'account'} on your other devices and Pro is there too.',
        textAlign: TextAlign.center,
        style: BnType.body.copyWith(
          color: colors.muted,
          fontWeight: FontWeight.w400,
          height: 1.45,
        ),
      ),
      const SizedBox(height: 24),
      BnButton.primary(
        label: 'Start',
        expand: true,
        height: 46,
        onPressed: () => Navigator.of(context).pop(),
      ),
    ],
  );

  Widget _offer(BuildContext context, BadNotesColors colors) {
    final step = ProBilling.step.value;
    final price = ProBilling.product.value?.price;
    final email = Pro.account;
    final canBuy = ProBilling.supported;
    final note = switch (step) {
      .pending || .waiting || .failed => ProBilling.message.value,
      _ => null,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const BnLogo(size: 40),
            const Spacer(),
            BnIconButton(
              icon: BnIcons.close,
              size: 32,
              iconSize: 18,
              tooltip: 'Close',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (widget.reason != ProFeature.upgrade)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.reason.reason,
              style: BnType.caption.copyWith(
                color: colors.highlightText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Text(
          'BadNotes Pro',
          style: BnType.display.copyWith(color: colors.text),
        ),
        const SizedBox(height: 4),
        Text(
          'Pay once. Yours forever.',
          style: BnType.bodyLarge.copyWith(
            color: colors.muted,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 20),
        for (final (icon, title, caption) in Paywall.benefits)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.accentTint,
                    border: Border.all(color: colors.accentTintBorder),
                    borderRadius: BorderRadius.circular(BnRadius.control),
                  ),
                  child: Icon(icon, size: 16, color: colors.accentStrong),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: BnType.body.copyWith(
                          color: colors.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        caption,
                        style: BnType.caption.copyWith(color: colors.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        if (note != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: step == ProBuyStep.failed
                  ? colors.sunkenSoft
                  : colors.accentSoft,
              borderRadius: BorderRadius.circular(BnRadius.control),
            ),
            child: Text(
              note,
              style: BnType.caption.copyWith(
                color: step == ProBuyStep.failed
                    ? colors.danger
                    : colors.highlightText,
                height: 1.4,
              ),
            ),
          ),
        if (canBuy)
          _BuyButton(
            label: _busy
                ? step == ProBuyStep.activating
                      ? 'Turning on Pro…'
                      : 'Opening Google Play…'
                : price == null
                ? 'Get Pro'
                : 'Get Pro · $price',
            busy: _busy,
            onPressed: _busy || step == ProBuyStep.pending ? null : _getPro,
          )
        else
          Text(
            'Buy Pro in the BadNotes app on an Android phone or tablet. '
            'It then works here when you sign in with the same Google account.',
            textAlign: TextAlign.center,
            style: BnType.caption.copyWith(color: colors.muted),
          ),
        const SizedBox(height: 10),
        Text(
          email == null
              ? "You'll sign in with Google so Pro works on all your devices."
              : 'For $email. Works on every device you sign in on.',
          textAlign: TextAlign.center,
          style: BnType.caption.copyWith(color: colors.muted),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: [
            if (canBuy)
              BnButton(
                label: 'Restore purchase',
                kind: .quiet,
                height: 36,
                onPressed: _busy || email == null ? null : ProBilling.restore,
              ),
            BnButton(
              label: 'Terms',
              kind: .quiet,
              height: 36,
              onPressed: () => launchUrl(
                Uri.parse('https://badnotes.space/tos'),
                mode: LaunchMode.externalApplication,
              ),
            ),
            BnButton(
              label: 'Privacy',
              kind: .quiet,
              height: 36,
              onPressed: () => launchUrl(
                Uri.parse('https://badnotes.space/policy'),
                mode: LaunchMode.externalApplication,
              ),
            ),
          ],
        ),
        if (Pro.devBuild)
          BnToggleRow(
            label: 'Developer: unlock Pro on this device',
            value: stows.proDevUnlock.value,
            onChanged: (on) => setState(() => stows.proDevUnlock.value = on),
          ),
      ],
    );
  }
}

class _BuyButton extends StatelessWidget {
  const new({required this.label, required this.busy, this.onPressed});

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Material(
      color: onPressed == null && !busy
          ? colors.accent.withValues(alpha: 0.4)
          : colors.accent,
      borderRadius: BorderRadius.circular(BnRadius.control),
      child: InkWell(
        borderRadius: BorderRadius.circular(BnRadius.control),
        onTap: onPressed,
        child: SizedBox(
          height: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy) ...[
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Text(
                label,
                style: BnType.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small lock on things that need Pro, shown to free users.
class ProBadge extends StatelessWidget {
  const new({super.key, this.size = 14});

  final double size;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: Pro.isPro,
    builder: (context, _, _) {
      if (Pro.has) return const SizedBox.shrink();
      final colors = BadNotesColors.of(context);
      return Container(
        padding: EdgeInsets.all(size * 0.25),
        decoration: BoxDecoration(
          color: colors.accentSoft,
          shape: BoxShape.circle,
        ),
        child: Icon(BnIcons.lock, size: size, color: colors.highlightText),
      );
    },
  );
}

/// Settings' first item: what Pro gives and a way to get it, or a thank
/// you and the account it belongs to.
class ProSettingsCard extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([Pro.isPro, Pro.licence, stows.username]),
    builder: (context, _) {
      final colors = BadNotesColors.of(context);
      final pro = Pro.has;
      return BnCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const BnLogo(size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pro ? 'You have BadNotes Pro' : 'BadNotes Pro',
                    style: BnType.section.copyWith(color: colors.text),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pro
                        ? 'Thank you! Tied to '
                              '${Pro.licence.value?.email ?? Pro.account ?? 'this device'}.'
                        : 'Unlimited notebooks, automatic sync, every cover '
                              'and more. Pay once.',
                    style: BnType.caption.copyWith(color: colors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (pro)
              BnButton(
                label: 'Restore',
                onPressed: ProBilling.supported
                    ? () {
                        unawaited(ProBilling.restore());
                        showBanner(context, 'Checking your purchase…');
                      }
                    : () => unawaited(Pro.refresh(force: true)),
              )
            else
              BnButton.primary(
                label: 'Get Pro',
                onPressed: () => showPaywall(context),
              ),
          ],
        ),
      );
    },
  );
}
