import 'dart:io';

import 'package:badnotes/components/settings/app_info.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/nextcloud/remote_store.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/i18n/strings.g.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// First login step (design 5): where the notes sync to, Google Drive or
/// OneDrive, or none. On a wide screen a BadNotes panel sits beside it.
class NcLoginStep extends StatelessWidget {
  const new({super.key, required this.recheckCurrentStep});

  final void Function() recheckCurrentStep;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= 900 && size.height >= 560;
    final choices = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: _LoginWithCloud(recheckCurrentStep: recheckCurrentStep),
        ),
      ),
    );
    if (!wide) return choices;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 24,
        children: [
          SizedBox(width: size.width * 0.4, child: const _BrandPanel()),
          Expanded(child: choices),
        ],
      ),
    );
  }
}

/// BadNotes, a few notebooks, and what signing in gives.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    Widget point(String text) => Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Icon(BnIcons.check, size: 18, color: colors.accentStrong),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: BnType.bodyLarge.copyWith(color: colors.text2),
            ),
          ),
        ],
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.accentTint,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const BnLogo(size: 34),
                const SizedBox(width: 10),
                Text(
                  'BadNotes',
                  style: BnType.section.copyWith(
                    color: colors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const Expanded(child: Center(child: _Notebooks())),
            Text(
              'Your notebooks,\non every device.',
              style: BnType.display.copyWith(
                color: colors.text,
                fontSize: 28,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            point('Saved to your own cloud storage'),
            point('Back up and restore any time'),
            point("Works offline; syncs when you're back"),
          ],
        ),
      ),
    );
  }
}

/// Two notebooks and a synced sticky note, drawn.
class _Notebooks extends StatelessWidget {
  const _Notebooks();

  @override
  Widget build(BuildContext context) {
    const shadow = [
      BoxShadow(
        color: Color(0x38281E50),
        blurRadius: 30,
        offset: Offset(0, 16),
      ),
    ];
    Widget turned(double degrees, Widget child) =>
        Transform.rotate(angle: degrees * 3.14159 / 180, child: child);
    return SizedBox(
      width: 340,
      height: 290,
      child: Stack(
        children: [
          Positioned(
            left: 20,
            top: 30,
            child: turned(
              -8,
              Container(
                width: 170,
                height: 224,
                decoration: const BoxDecoration(
                  color: BnColors.charcoal,
                  borderRadius: BnRadius.cover,
                  boxShadow: shadow,
                ),
              ),
            ),
          ),
          Positioned(
            left: 110,
            top: 12,
            child: turned(
              4,
              Container(
                width: 180,
                height: 236,
                padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BnRadius.cover,
                  boxShadow: shadow,
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Physics',
                      style: TextStyle(
                        fontFamily: 'Caveat',
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: BnColors.text,
                      ),
                    ),
                    Divider(color: BnColors.hairline, height: 24),
                    Text(
                      'F = m · a',
                      style: TextStyle(
                        fontFamily: 'Caveat',
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: BnColors.inkBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 230,
            top: 180,
            child: turned(
              -6,
              Container(
                width: 104,
                height: 92,
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: BnColors.noteButter,
                  boxShadow: shadow,
                ),
                child: const Text(
                  'synced ✓',
                  style: TextStyle(
                    fontFamily: 'Caveat',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: BnColors.text,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One tap sign-in with Google Drive or OneDrive.
class const _LoginWithCloud({required final VoidCallback recheckCurrentStep})
    extends HookWidget {
  static bool get showGoogleDrive => Platform.isAndroid;
  static bool get showOneDrive =>
      Platform.isAndroid || Platform.isIOS || Platform.isMacOS;

  Future<void> _login(BuildContext context, SyncProvider provider) async {
    ({String email, String credential})? result;
    try {
      result = await CloudLogin.signIn(provider);
    } catch (e) {
      if (!CloudLogin.isCancelled(e) && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t.login.ncLoginStep.cloudLoginFailed}\n$e'),
          ),
        );
      }
      return;
    }
    final (:email, :credential) = result;

    stows.syncProvider.value = provider;
    stows.cloudSyncState.value = '';
    stows.pfp.value =
        provider == SyncProvider.googleDrive ? GoogleDriveStore.lastPhoto : null;
    stows.encPassword.value = '';
    stows.ncPassword.value = credential;
    stows.username.value = email;
    recheckCurrentStep();
  }

  @override
  Widget build(BuildContext context) {
    final busy = useState(false);
    final colors = BadNotesColors.of(context);

    VoidCallback? signIn(SyncProvider provider) => busy.value
        ? null
        : () async {
            busy.value = true;
            try {
              await _login(context, provider);
            } finally {
              if (context.mounted) busy.value = false;
            }
          };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Sign in to sync',
          style: BnType.display.copyWith(color: colors.text, fontSize: 30),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose where BadNotes keeps your notes. Only you can see them.',
          style: BnType.bodyLarge.copyWith(
            color: colors.muted,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        if (showGoogleDrive)
          _ProviderCard(
            logo: const _DriveLogo(),
            title: 'Google Drive',
            caption: 'Uses a BadNotes folder in your Drive',
            primary: true,
            busy: busy.value,
            onTap: signIn(.googleDrive),
          ),
        if (showOneDrive) ...[
          const SizedBox(height: 12),
          _ProviderCard(
            logo: Icon(BnIcons.cloud, size: 22, color: colors.faint),
            title: 'OneDrive',
            caption: OneDriveStore.isConfigured
                ? 'Uses Apps/BadNotes in your OneDrive'
                : 'Not ready yet',
            badge: OneDriveStore.isConfigured
                ? null
                : t.login.ncLoginStep.comingSoon,
            onTap: OneDriveStore.isConfigured ? signIn(.oneDrive) : null,
          ),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 22),
          child: Row(
            children: [
              Expanded(child: Divider(color: colors.hairline)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'or',
                  style: BnType.caption.copyWith(color: colors.faint),
                ),
              ),
              Expanded(child: Divider(color: colors.hairline)),
            ],
          ),
        ),
        BnButton(
          label: 'Keep notes on this device only',
          expand: true,
          height: 48,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(height: 22),
        Text.rich(
          TextSpan(
            style: BnType.caption.copyWith(color: colors.muted, height: 1.5),
            children: [
              const TextSpan(text: 'By signing in you agree to the '),
              TextSpan(
                text: 'Privacy Policy',
                style: TextStyle(
                  color: colors.accentStrong,
                  fontWeight: FontWeight.w600,
                ),
                recognizer: TapGestureRecognizer()
                  ..onTap = () => AppInfo.showPrivacyPolicy(context),
              ),
              const TextSpan(
                text: '.\nYou can sign out or switch any time in Settings.',
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// A place to keep the notes, as a card to tap.
class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.logo,
    required this.title,
    required this.caption,
    required this.onTap,
    this.primary = false,
    this.busy = false,
    this.badge,
  });

  final Widget logo;
  final String title, caption;
  final VoidCallback? onTap;
  final bool primary, busy;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: title,
      child: Material(
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          side: BorderSide(
            color: primary && enabled ? colors.accent : colors.hairline,
            width: primary && enabled ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 66,
            child: Row(
              children: [
                const SizedBox(width: 16),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: colors.sunkenSoft,
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Center(child: logo),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: BnType.bodyLarge.copyWith(
                          color: enabled ? colors.text : colors.muted,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        caption,
                        style: BnType.caption.copyWith(
                          color: enabled ? colors.muted : colors.faint,
                        ),
                      ),
                    ],
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: colors.sunkenSoft,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(BnRadius.pill),
                      ),
                    ),
                    child: Text(
                      badge!,
                      style: BnType.micro.copyWith(
                        color: colors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else if (busy && primary)
                  SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.accent,
                    ),
                  )
                else
                  Icon(BnIcons.forward, size: 18, color: colors.accent),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Google Drive's three-coloured triangle, drawn.
class _DriveLogo extends StatelessWidget {
  const _DriveLogo();

  @override
  Widget build(BuildContext context) =>
      const CustomPaint(size: Size(22, 20), painter: _DrivePainter());
}

class _DrivePainter extends CustomPainter {
  const _DrivePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width / 22, h = size.height / 20;
    Path path(List<Offset> points) => Path()
      ..addPolygon([for (final p in points) Offset(p.dx * w, p.dy * h)], true);
    canvas
      ..drawPath(
        path(const [
          Offset(7, 1),
          Offset(15, 1),
          Offset(22, 13),
          Offset(14, 13),
        ]),
        Paint()..color = const Color(0xFFFFC21A),
      )
      ..drawPath(
        path(const [Offset(7, 1), Offset(0, 13), Offset(4, 19), Offset(11, 7)]),
        Paint()..color = const Color(0xFF2F9E77),
      )
      ..drawPath(
        path(const [
          Offset(4, 19),
          Offset(18, 19),
          Offset(22, 13),
          Offset(8, 13),
        ]),
        Paint()..color = const Color(0xFF3E8EF7),
      );
  }

  @override
  bool shouldRepaint(_DrivePainter old) => false;
}
