import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:logging/logging.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/nextcloud/errors.dart';
import 'package:badnotes/data/nextcloud/remote_store.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/i18n/strings.g.dart';

/// The sign-in step after the cloud account is linked: the password that
/// locks the notes. The cloud is asked first. If it already holds a key (set
/// up on another device) the user unlocks it with their password; if not,
/// they create a password, typed twice. An existing key is never replaced.
class const EncLoginStep({
  super.key,
  required final void Function() recheckCurrentStep,
}) extends HookWidget {
  /// The widest the column of content gets on large screens.
  static const width = 420.0;

  /// The shortest password that can be created.
  static const minLength = 8;

  static final log = Logger('EncLoginStep');

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final screen = MediaQuery.sizeOf(context);

    final password = useTextEditingController();
    final confirm = useTextEditingController();
    final problem = useState('');
    final busy = useState(false);
    final show = useState(false);
    final lookups = useState(0);

    // does the cloud already hold a key? (asked again on "Try again")
    final lookup = useMemoized(() async {
      final store = RemoteStore.forLinkedAccount();
      if (store == null) throw StateError('Not signed in');
      final config = await store.getConfig();
      return config.containsKey(stows.key.key) &&
          config.containsKey(stows.iv.key);
    }, [lookups.value]);
    final cloud = useFuture(lookup);

    final Widget body;
    if (cloud.hasError) {
      body = _Message(
        icon: BnIcons.cloudOff,
        title: "Couldn't reach your cloud",
        text:
            'BadNotes needs to look in your cloud before it asks for a '
            'password.\n\n${cloud.error}',
        action: BnButton.primary(
          label: 'Try again',
          expand: true,
          onPressed: () => lookups.value++,
        ),
      );
    } else if (cloud.connectionState != ConnectionState.done) {
      body = Padding(
        padding: const .only(top: 64),
        child: Center(
          child: SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: colors.accent,
            ),
          ),
        ),
      );
    } else {
      body = _form(
        context,
        colors,
        existing: cloud.data ?? false,
        password: password,
        confirm: confirm,
        problem: problem,
        busy: busy,
        show: show,
        lookups: lookups,
      );
    }

    return ListView(
      padding: .symmetric(
        horizontal: screen.width > width + 64
            ? (screen.width - width) / 2
            : BnSpace.xl,
        vertical: BnSpace.xl,
      ),
      children: [body],
    );
  }

  Widget _form(
    BuildContext context,
    BadNotesColors colors, {
    required bool existing,
    required TextEditingController password,
    required TextEditingController confirm,
    required ValueNotifier<String> problem,
    required ValueNotifier<bool> busy,
    required ValueNotifier<bool> show,
    required ValueNotifier<int> lookups,
  }) {
    void switchAccount() {
      stows.username.value = '';
      stows.ncPassword.value = '';
      recheckCurrentStep();
    }

    String? mistake() {
      if (existing) return null;
      final typed = password.text;
      if (typed.isNotEmpty && typed.length < minLength) {
        return 'Use at least $minLength characters.';
      }
      if (confirm.text.isNotEmpty && confirm.text != typed) {
        return "The two passwords don't match.";
      }
      return null;
    }

    return ListenableBuilder(
      listenable: Listenable.merge([password, confirm, busy, show, problem]),
      builder: (context, _) {
        final typed = password.text;
        final ready = !busy.value &&
            typed.isNotEmpty &&
            (existing || (typed.length >= minLength && confirm.text == typed));
        final live = mistake();
        final shown = problem.value.isNotEmpty ? problem.value : live;

        Future<void> submit() async {
          if (!ready) return;
          busy.value = true;
          try {
            await _tryPassword(typed, existing, problem, lookups);
          } finally {
            busy.value = false;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colors.accentTint,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.accentTintBorder),
                ),
                child: Icon(
                  LucideIcons.lock,
                  size: 22,
                  color: colors.accentStrong,
                ),
              ),
            ),
            const SizedBox(height: BnSpace.l),
            Text(
              existing ? 'Unlock your notes' : 'Create a notes password',
              style: BnType.display.copyWith(color: colors.text, fontSize: 30),
            ),
            const SizedBox(height: BnSpace.s),
            Text(
              existing
                  ? 'Your notes in ${_provider()} are locked. Type the '
                        'password you chose on your other device.'
                  : 'Your notes are locked before they leave this device. '
                        'Choose a password; you will type the same one on '
                        'your other devices.',
              style: BnType.bodyLarge.copyWith(
                color: colors.muted,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            _Field(
              controller: password,
              label: existing ? 'Password' : 'New password',
              show: show.value,
              onToggle: () => show.value = !show.value,
              autofocus: true,
              action: existing ? TextInputAction.done : TextInputAction.next,
              onSubmitted: existing ? (_) => submit() : null,
            ),
            if (!existing) ...[
              const SizedBox(height: BnSpace.m),
              _Field(
                controller: confirm,
                label: 'Type it again',
                show: show.value,
                onToggle: null,
                action: TextInputAction.done,
                onSubmitted: (_) => submit(),
              ),
            ],
            if (shown != null) ...[
              const SizedBox(height: BnSpace.s),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const .only(top: 2),
                    child: Icon(
                      LucideIcons.triangleAlert,
                      size: 14,
                      color: colors.danger,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      shown,
                      style: BnType.caption.copyWith(
                        color: colors.danger,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (!existing) ...[
              const SizedBox(height: BnSpace.l),
              _Note(
                icon: LucideIcons.triangleAlert,
                text:
                    'Write it down somewhere safe. BadNotes cannot reset it. '
                    'If you forget it, the notes in ${_provider()} cannot '
                    'be opened by anyone.',
              ),
            ],
            const SizedBox(height: 28),
            BnButton.primary(
              label: busy.value
                  ? 'Checking…'
                  : (existing ? 'Unlock' : 'Create password'),
              expand: true,
              height: 46,
              onPressed: ready ? submit : null,
            ),
            const SizedBox(height: BnSpace.s),
            Center(
              child: BnButton(
                label: 'Signed in as ${stows.username.value}. Not you?',
                kind: BnButtonKind.quiet,
                onPressed: busy.value ? null : switchAccount,
              ),
            ),
            const SizedBox(height: BnSpace.xl),
            const BnSectionHeader(title: 'Questions'),
            for (final entry in t.login.encLoginStep.encFaq)
              LoginQuestion(question: entry.q, answer: entry.a),
          ],
        );
      },
    );
  }

  static String _provider() => switch (stows.syncProvider.value) {
    SyncProvider.oneDrive => 'OneDrive',
    SyncProvider.googleDrive => 'Google Drive',
  };

  /// Saves [attempt] as the notes password and unlocks (or, for a new
  /// account, creates) the key in the cloud. On failure the saved password
  /// is wiped again and [problem] says why.
  Future<void> _tryPassword(
    String attempt,
    bool existing,
    ValueNotifier<String> problem,
    ValueNotifier<int> lookups,
  ) async {
    problem.value = '';
    if (attempt.isEmpty) return;

    try {
      stows.encPassword.value = attempt;
      final store = RemoteStore.fromSavedDetails()!;
      // an existing key is only ever unlocked, never replaced
      await store.loadEncryptionKey(generateKeyIfMissing: !existing);
      recheckCurrentStep();
    } catch (e, st) {
      stows.encPassword.value = '';
      if (e is EncLoginFailure) {
        if (existing) {
          problem.value = "That isn't the password for these notes.";
        } else {
          // a key appeared in the cloud while this was typed
          problem.value =
              'Your cloud already has a notes password, and this is not it. '
              'Enter that one instead.';
          lookups.value++;
        }
        return;
      }
      log.severe('Failed to load encryption key: $e', e, st);
      problem.value = "Couldn't reach your cloud.\n$e";
      if (kDebugMode) rethrow;
    }
  }
}

/// A password box: surface with a hairline, accent ring when focused, and an
/// eye to show what was typed.
class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.show,
    required this.onToggle,
    required this.action,
    this.onSubmitted,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String label;
  final bool show;
  final VoidCallback? onToggle;
  final TextInputAction action;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(BnRadius.control),
          borderSide: BorderSide(color: color, width: width),
        );
    return TextField(
      controller: controller,
      obscureText: !show,
      autofocus: autofocus,
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: action,
      onSubmitted: onSubmitted,
      autofillHints: const [AutofillHints.password],
      style: BnType.bodyLarge.copyWith(color: colors.text),
      cursorColor: colors.accent,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: BnType.body.copyWith(color: colors.faint),
        floatingLabelStyle: BnType.caption.copyWith(color: colors.muted),
        filled: true,
        fillColor: colors.surface,
        contentPadding: const .symmetric(horizontal: 14, vertical: 16),
        border: border(colors.hairline),
        enabledBorder: border(colors.hairline),
        focusedBorder: border(colors.accent, 1.5),
        suffixIcon: onToggle == null
            ? null
            : IconButton(
                tooltip: show ? 'Hide' : 'Show',
                onPressed: onToggle,
                icon: Icon(
                  show ? LucideIcons.eyeOff : LucideIcons.eye,
                  size: 18,
                  color: colors.faint,
                ),
              ),
      ),
    );
  }
}

/// A calm callout: soft amber, an icon and a sentence.
class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(BnRadius.control),
      ),
      child: Padding(
        padding: const .all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: colors.highlightText),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: BnType.caption.copyWith(
                  color: colors.highlightText,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A full-width message with one button (used when the cloud can't be
/// reached).
class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.text,
    required this.action,
  });

  final IconData icon;
  final String title, text;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: BnSpace.xxl),
        Icon(icon, size: 28, color: colors.faint),
        const SizedBox(height: BnSpace.l),
        Text(
          title,
          style: BnType.title.copyWith(color: colors.text),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: BnSpace.s),
        Text(
          text,
          style: BnType.body.copyWith(
            color: colors.muted,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: BnSpace.xl),
        action,
      ],
    );
  }
}

/// One question of the list; the answer opens when it is tapped.
class LoginQuestion extends StatelessWidget {
  const LoginQuestion({super.key, required this.question, required this.answer});

  final String question, answer;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: .zero,
        childrenPadding: const .only(bottom: BnSpace.m),
        expandedAlignment: Alignment.centerLeft,
        iconColor: colors.faint,
        collapsedIconColor: colors.faint,
        title: Text(
          question,
          style: BnType.body.copyWith(color: colors.text),
        ),
        children: [
          SelectableText(
            answer,
            style: BnType.body.copyWith(
              color: colors.muted,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
