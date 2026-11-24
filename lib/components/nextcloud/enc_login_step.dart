import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:logging/logging.dart';
import 'package:badnotes/components/misc/faq.dart';
import 'package:badnotes/data/nextcloud/errors.dart';
import 'package:badnotes/data/nextcloud/remote_store.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/i18n/strings.g.dart';
import 'package:sbn/font_fallbacks.dart';
import 'package:yaru/yaru.dart';

/// The sign-in step after the cloud account is linked: the user types the
/// password that locks their notes, and it is checked by trying to unlock
/// the key stored in the cloud.
class const EncLoginStep({
  super.key,
  required final void Function() recheckCurrentStep,
}) extends HookWidget {
  /// The widest the column of content gets on large screens.
  static const width = 400.0;

  static final log = Logger('EncLoginStep');

  @override
  Widget build(BuildContext context) {
    final password = useTextEditingController();
    final problem = useState('');
    final busy = useState(false);

    final colorScheme = ColorScheme.of(context);
    final headline = TextTheme.of(context).headlineSmall;
    final screen = MediaQuery.sizeOf(context);

    final switchAccount = TapGestureRecognizer()
      ..onTap = () {
        stows.username.value = '';
        stows.ncPassword.value = '';
        recheckCurrentStep();
      };

    final greeting = <Widget>[
      Text(t.login.status.hi(u: stows.username.value), style: headline),
      Text.rich(
        t.login.notYou(
          undoLogin: (text) => TextSpan(
            text: text,
            style: TextStyle(color: colorScheme.link),
            recognizer: switchAccount,
          ),
        ),
      ),
    ];

    final passwordForm = <Widget>[
      Text(t.login.encLoginStep.enterEncPassword, style: headline),
      const SizedBox(height: 4),
      Text(t.login.encLoginStep.newToBadNotes),
      const SizedBox(height: 16),
      TextField(
        controller: password,
        style: const TextStyle(
          fontFamily: 'FiraMono',
          fontFamilyFallback: badnotesMonoFontFallbacks,
        ),
        decoration: InputDecoration(
          labelText: t.login.encLoginStep.encPassword,
        ),
        autofillHints: const [AutofillHints.password],
        autofocus: true,
      ),
      ValueListenableBuilder(
        valueListenable: problem,
        builder: (context, message, _) => message.isEmpty
            ? const SizedBox.shrink()
            : Padding(
                padding: const .only(top: 4),
                child: Text(
                  message,
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
      ),
      const SizedBox(height: 4),
      ListenableBuilder(
        listenable: password,
        builder: (context, label) {
          final typed = password.text;
          final canSubmit = typed.isNotEmpty && !busy.value;
          return ElevatedButton(
            onPressed: canSubmit
                ? () async {
                    busy.value = true;
                    try {
                      await _tryPassword(typed, problem);
                    } finally {
                      busy.value = false;
                    }
                  }
                : null,
            child: label,
          );
        },
        child: Text(t.common.continueBtn),
      ),
    ];

    return ListView(
      padding: .symmetric(
        horizontal: screen.width > width ? (screen.width - width) / 2 : 16,
        vertical: 16,
      ),
      children: [
        const SizedBox(height: 16),
        if (screen.height > 500) ...[
          SvgPicture.asset(
            'assets/images/sync_private.svg',
            width: width,
            height: min(width * 576 / 844.6693, screen.height * 0.25),
            excludeFromSemantics: true,
          ),
          SizedBox(height: min(64, screen.height * 0.05)),
        ],
        ...greeting,
        const SizedBox(height: 32),
        ...passwordForm,
        const SizedBox(height: 32),
        Text(t.login.encLoginStep.encFaqTitle, style: headline),
        FaqListView(
          shrinkWrap: true,
          items: [
            for (final entry in t.login.encLoginStep.encFaq)
              FaqItem(entry.q, entry.a),
          ],
        ),
      ],
    );
  }

  /// Saves [attempt] as the notes password and tries to unlock the cloud key
  /// with it. On failure the saved password is wiped again and [problem] is
  /// set to a message for the user.
  Future<void> _tryPassword(
    String attempt,
    ValueNotifier<String> problem,
  ) async {
    problem.value = '';
    if (attempt.isEmpty) return;

    try {
      stows.encPassword.value = attempt;
      final store = RemoteStore.fromSavedDetails()!;
      await store.loadEncryptionKey();
      recheckCurrentStep();
    } catch (e, st) {
      stows.encPassword.value = '';
      if (e is EncLoginFailure) {
        problem.value = t.login.encLoginStep.wrongEncPassword;
        return;
      }
      log.severe('Failed to load encryption key: $e', e, st);
      problem.value = '${t.login.encLoginStep.connectionFailed}\n\n$e';
      if (kDebugMode) rethrow;
    }
  }
}
