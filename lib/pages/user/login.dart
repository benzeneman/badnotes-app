import 'package:badnotes/components/nextcloud/done_login_step.dart';
import 'package:badnotes/components/nextcloud/enc_login_step.dart';
import 'package:badnotes/components/nextcloud/nc_login_step.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/bn_settings.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/i18n/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:stow_secure/stow_secure.dart';

/// Signing in to sync: the cloud account first, then the encryption
/// password, then a profile screen once both are set.
class NcLoginPage extends StatefulWidget {
  const new({
    super.key,
    @visibleForTesting this.forceAppBarLeading = false,
    @visibleForTesting this.forceCurrentStep,
  });

  /// Shows the back arrow even when there is nothing to go back to.
  final bool forceAppBarLeading;

  /// Pins the page to one step instead of working it out from the prefs.
  final LoginStep? forceCurrentStep;

  /// The prefs that decide which step the user is on.
  static List<SecureStow<String>> get _accountPrefs => [
    stows.username,
    stows.ncPassword,
    stows.encPassword,
    stows.key,
    stows.iv,
  ];

  static bool get _accountPrefsLoaded =>
      _accountPrefs.every((pref) => pref.loaded);

  /// Works out the step from what is saved: nothing until the prefs are read,
  /// then whichever of the account or the encryption details is missing.
  static LoginStep getCurrentStep() {
    if (!_accountPrefsLoaded) return .waitingForPrefs;

    final hasAccount =
        stows.username.value.isNotEmpty && stows.ncPassword.value.isNotEmpty;
    if (!hasAccount) return .nc;

    final hasEncryption =
        stows.encPassword.value.isNotEmpty &&
        stows.key.value.isNotEmpty &&
        stows.iv.value.isNotEmpty;
    return hasEncryption ? .done : .enc;
  }

  @override
  State<NcLoginPage> createState() => _NcLoginPageState();
}

class _NcLoginPageState extends State<NcLoginPage> {
  final log = Logger('_NcLoginPageState');

  late LoginStep step = .waitingForPrefs;

  @override
  void initState() {
    _loadThenDecide();
    super.initState();
  }

  /// Reads the account prefs if they aren't in memory yet, then picks the
  /// step. When they are already loaded this finishes before the first build.
  Future<void> _loadThenDecide() async {
    if (_applyForcedStep()) return;
    step = .waitingForPrefs;

    if (!NcLoginPage._accountPrefsLoaded) {
      await Future.wait([
        for (final pref in NcLoginPage._accountPrefs) pref.waitUntilRead(),
      ]);
    }
    recheckCurrentStep();
  }

  /// Uses the test override if there is one; true when it did.
  bool _applyForcedStep() {
    final forced = widget.forceCurrentStep;
    if (forced == null) return false;
    step = forced;
    return true;
  }

  /// Called by each step widget after it changes the saved details; rebuilds
  /// only when that moves the user to another step.
  void recheckCurrentStep() {
    if (_applyForcedStep()) return;
    final before = step;
    step = NcLoginPage.getCurrentStep();
    if (step != before && mounted) setState(() {});
  }

  String get _title => switch (step) {
    .waitingForPrefs => '',
    .done => t.profile.title,
    _ => t.login.title,
  };

  PreferredSizeWidget _header(BuildContext context, BadNotesColors colors) {
    final canGoBack =
        widget.forceAppBarLeading ||
        (ModalRoute.of(context)?.impliesAppBarDismissal ?? false);
    return PreferredSize(
      preferredSize: const .fromHeight(kToolbarHeight + 2),
      child: Material(
        color: colors.desk,
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .stretch,
            children: [
              Padding(
                padding: const .symmetric(horizontal: 8),
                child: BnSettingsTopBar(
                  height: kToolbarHeight,
                  title: _title,
                  backTooltip: MaterialLocalizations.of(context)
                      .backButtonTooltip,
                  onBack: canGoBack
                      ? () => Navigator.of(context).maybePop()
                      : null,
                ),
              ),
              BnProgressLine(value: step.progress),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content(BadNotesColors colors) => switch (step) {
    .waitingForPrefs => Center(
      child: SizedBox.square(
        dimension: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: colors.accent,
        ),
      ),
    ),
    .nc => NcLoginStep(recheckCurrentStep: recheckCurrentStep),
    .enc => EncLoginStep(recheckCurrentStep: recheckCurrentStep),
    .done => DoneLoginStep(recheckCurrentStep: recheckCurrentStep),
  };

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Scaffold(
      backgroundColor: colors.desk,
      appBar: _header(context, colors),
      body: _content(colors),
    );
  }
}

/// Where the user is in signing in, in order. [progress] fills the thin bar
/// under the title.
enum LoginStep(final double progress) {
  /// Still reading the saved account details.
  waitingForPrefs(0),

  /// Needs to sign in to the cloud server.
  nc(0.2),

  /// Signed in, but the encryption password is still missing.
  enc(0.6),

  /// Fully set up.
  done(1),
}
