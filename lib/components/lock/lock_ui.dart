import 'dart:async';
import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:badnotes/data/pro/pro.dart';
import 'package:badnotes/components/home/cover_designs.dart';
import 'package:badnotes/components/home/notebook_cover.dart';
import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/bn_home_dialogs.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/locks.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path/path.dart' as p;

/// The fingerprint reader, where there is one.
abstract final class Biometrics {
  static final _auth = LocalAuthentication();

  // ponytail: Android only; iOS needs NSFaceIDUsageDescription first.
  static Future<bool> available() async {
    if (!Platform.isAndroid) return false;
    try {
      return await _auth.isDeviceSupported() &&
          await _auth.canCheckBiometrics &&
          (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
    } catch (_) {
      return false;
    }
  }
}

String _kindWord(LockKind kind) => kind == .note ? 'notebook' : 'folder';

/// A password field with an eye to show what's typed.
class _PasswordField extends StatefulWidget {
  const new({
    required this.controller,
    required this.hint,
    this.autofocus = false,
    this.onSubmitted,
    this.dark = false,
  });

  final TextEditingController controller;
  final String hint;
  final bool autofocus, dark;
  final ValueChanged<String>? onSubmitted;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  var _hidden = true;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final fg = widget.dark ? Colors.white : colors.text;
    final line = widget.dark ? Colors.white24 : colors.hairline;
    OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(BnRadius.card),
      borderSide: BorderSide(color: c, width: w),
    );
    return TextField(
      controller: widget.controller,
      autofocus: widget.autofocus,
      obscureText: _hidden,
      enableSuggestions: false,
      autocorrect: false,
      onSubmitted: widget.onSubmitted,
      textInputAction: TextInputAction.done,
      cursorColor: widget.dark ? Colors.white : colors.accent,
      style: BnType.bodyLarge.copyWith(color: fg, fontSize: 16),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: widget.dark
            ? Colors.white.withValues(alpha: 0.08)
            : colors.surface,
        hintText: widget.hint,
        hintStyle: BnType.bodyLarge.copyWith(
          color: widget.dark ? Colors.white54 : colors.faint,
          fontSize: 16,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: border(line, 1),
        enabledBorder: border(line, 1),
        focusedBorder: border(widget.dark ? Colors.white70 : colors.accent, 1.5),
        suffixIcon: IconButton(
          tooltip: _hidden ? 'Show password' : 'Hide password',
          icon: Icon(
            _hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 20,
            color: widget.dark ? Colors.white70 : colors.muted,
          ),
          onPressed: () => setState(() => _hidden = !_hidden),
        ),
      ),
    );
  }
}

/// The sheet that locks [path] with a new password, or sets a new one with
/// [change]. True once it's saved.
Future<bool> showSetLockSheet(
  BuildContext context, {
  required String path,
  required LockKind kind,
  bool change = false,
}) async {
  // changing an existing lock's password stays free
  if (!change && !await Pro.require(context, ProFeature.noteLock)) {
    return false;
  }
  if (!context.mounted) return false;
  return await showBnSheet<bool>(
        context: context,
        builder: (context) =>
            _SetLockSheet(path: path, kind: kind, change: change),
      ) ??
      false;
}

class _SetLockSheet extends StatefulWidget {
  const new({
    required this.path,
    required this.kind,
    required this.change,
  });

  final String path;
  final LockKind kind;
  final bool change;

  @override
  State<_SetLockSheet> createState() => _SetLockSheetState();
}

class _SetLockSheetState extends State<_SetLockSheet> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  late final _hint = TextEditingController(
    text: widget.change ? NoteLocks.book.value.lockOf(widget.path)?.hint : '',
  );
  late var _fingerprint = NoteLocks.usesBiometric(widget.path);
  final _canFingerprint = Biometrics.available();
  String? _error;
  var _busy = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    _hint.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final password = _password.text;
    if (password.length < 4) {
      return setState(() => _error = 'Use at least 4 characters');
    }
    if (password != _confirm.text) {
      return setState(() => _error = "The passwords don't match");
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    await NoteLocks.setLock(
      widget.path,
      widget.kind,
      password,
      hint: _hint.text.trim(),
    );
    NoteLocks.setBiometric(widget.path, _fingerprint);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final name = p.basename(widget.path);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BnDialogTitle(
            title: widget.change ? 'New password for “$name”' : 'Lock “$name”',
            size: 22,
          ),
          const SizedBox(height: 6),
          Text(
            'Asks every time it opens · stays locked on your other devices '
            'through Drive',
            style: BnType.caption.copyWith(color: colors.muted, height: 1.45),
          ),
          const SizedBox(height: 18),
          const BnFieldLabel('Password'),
          _PasswordField(
            controller: _password,
            hint: 'At least 4 characters',
            autofocus: true,
          ),
          const SizedBox(height: 12),
          const BnFieldLabel('Confirm password'),
          _PasswordField(
            controller: _confirm,
            hint: 'Type it again',
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 12),
          const BnFieldLabel('Hint (optional)'),
          BnTextInput(
            controller: _hint,
            hint: 'Shown after a wrong password',
            fontWeight: FontWeight.w500,
          ),
          FutureBuilder(
            future: _canFingerprint,
            builder: (context, snapshot) => snapshot.data ?? false
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: BnToggleRow(
                      icon: Icons.fingerprint,
                      label: 'Unlock with fingerprint too',
                      description: 'On this device only',
                      value: _fingerprint,
                      onChanged: (v) => setState(() => _fingerprint = v),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.sunkenSoft,
              borderRadius: BorderRadius.circular(BnRadius.card),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                Icon(Icons.info_outline, size: 16, color: colors.muted),
                Expanded(
                  child: Text(
                    'Forgot it? You can set a new one with your cloud notes '
                    "password. Without that, it can't be recovered.",
                    style: BnType.caption.copyWith(
                      color: colors.text2,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _error!,
                style: BnType.caption.copyWith(color: colors.danger),
              ),
            ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            spacing: 8,
            children: [
              BnButton(
                label: 'Cancel',
                onPressed: () => Navigator.of(context).pop(false),
              ),
              BnButton.primary(
                label: widget.change ? 'Save' : 'Lock',
                icon: BnIcons.lock,
                onPressed: _busy ? null : _save,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Asks for the password of [path]'s own lock, even if it's open now (to
/// take the lock off or change it). True when it was right.
Future<bool> confirmLockPassword(BuildContext context, String path) =>
    _pushLockScreen(context, path, always: true);

/// Opens whatever locks stand in front of [path]. True once it can be seen.
Future<bool> ensureUnlocked(BuildContext context, String path) async {
  if (!NoteLocks.needsUnlock(path)) return true;
  return _pushLockScreen(context, path);
}

Future<bool> _pushLockScreen(
  BuildContext context,
  String path, {
  bool always = false,
}) async =>
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => LockScreen(
          path: path,
          always: always,
          onUnlocked: () => Navigator.of(context).pop(true),
          onClose: () => Navigator.of(context).pop(false),
        ),
      ),
    ) ??
    false;

/// What a long-press menu offers for [path]'s lock.
class LockAction {
  const new(this.icon, this.label, this.run);

  final IconData icon;
  final String label;

  /// Run from the page under the menu, after it closed.
  final void Function(BuildContext page) run;

  static List<LockAction> of(String path, LockKind kind) {
    if (!NoteLocks.isLocked(path)) {
      return [
        LockAction(
          BnIcons.lock,
          'Lock ${_kindWord(kind)}',
          (page) async {
            if (await showSetLockSheet(page, path: path, kind: kind) &&
                page.mounted) {
              showBanner(page, '“${p.basename(path)}” is locked');
            }
          },
        ),
      ];
    }
    return [
      LockAction(Icons.lock_open_rounded, 'Remove lock', (page) async {
        if (!await confirmLockPassword(page, path)) return;
        await NoteLocks.removeLock(path);
        if (page.mounted) showBanner(page, 'Lock removed');
      }),
      LockAction(Icons.key_rounded, 'Change password', (page) async {
        if (!await confirmLockPassword(page, path) || !page.mounted) return;
        if (await showSetLockSheet(page, path: path, kind: kind, change: true) &&
            page.mounted) {
          showBanner(page, 'Password changed');
        }
      }),
    ];
  }
}

/// A small lock over a locked notebook's or folder's corner.
class LockBadge extends StatelessWidget {
  const new({super.key, required this.path, this.size = 22});

  final String path;
  final double size;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: NoteLocks.book,
    builder: (context, _) => !NoteLocks.isLocked(path)
        ? const SizedBox.shrink()
        : Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              color: Color(0xE623264A),
              shape: BoxShape.circle,
            ),
            child: Icon(BnIcons.lock, size: size * 0.55, color: Colors.white),
          ),
  );
}

/// Inside an opened locked folder: it locks again when the app closes.
class UnlockedFolderBanner extends StatelessWidget {
  const new({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: NoteLocks.changes,
    builder: (context, _) {
      if (!NoteLocks.isProtected(path) || NoteLocks.needsUnlock(path)) {
        return const SizedBox.shrink();
      }
      final colors = BadNotesColors.of(context);
      return Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
        decoration: BoxDecoration(
          color: colors.successTint,
          borderRadius: BorderRadius.circular(BnRadius.card),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_open_rounded, size: 16, color: colors.success),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Folder unlocked — locks again when you close the app',
                style: BnType.caption.copyWith(color: colors.text),
              ),
            ),
            BnButton(
              label: 'Lock now',
              kind: BnButtonKind.quiet,
              onPressed: () {
                for (final dir in [path, ...LockBook.ancestors(path)]) {
                  NoteLocks.relock(dir);
                }
              },
            ),
          ],
        ),
      );
    },
  );
}

/// Stands in front of a locked notebook or folder until its password (or
/// fingerprint) is given. Opens every lock on the way to [path], outermost
/// first; with [always], only [path]'s own lock, open or not.
class LockScreen extends StatefulWidget {
  const new({
    super.key,
    required this.path,
    required this.onUnlocked,
    this.onClose,
    this.always = false,
  });

  final String path;
  final VoidCallback onUnlocked;

  /// Back to where the user came from; by default the route pops.
  final VoidCallback? onClose;
  final bool always;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _password = TextEditingController();
  late String _target = _nextTarget() ?? widget.path;
  var _wrong = false;
  var _busy = false;
  var _canFingerprint = false;

  String? _nextTarget() =>
      widget.always ? widget.path : NoteLocks.lockToOpen(widget.path);

  LockEntry? get _entry => NoteLocks.book.value.lockOf(_target);
  LockKind get _kind => _entry?.kind ?? .note;

  @override
  void initState() {
    super.initState();
    unawaited(_tryFingerprint(auto: true));
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _tryFingerprint({bool auto = false}) async {
    if (!NoteLocks.usesBiometric(_target)) return;
    final can = await Biometrics.available();
    if (!mounted) return;
    setState(() => _canFingerprint = can);
    if (!can) return;
    final ok = await Biometrics.authenticate(
      'Open “${p.basename(_target)}”',
    );
    if (ok && mounted) _opened();
  }

  void _opened() {
    NoteLocks.unlock(_target);
    final next = widget.always ? null : _nextTarget();
    if (next == null) return widget.onUnlocked();
    // a lock inside the one just opened
    setState(() {
      _target = next;
      _wrong = false;
      _password.clear();
    });
    unawaited(_tryFingerprint(auto: true));
  }

  Future<void> _submit() async {
    if (_busy || _password.text.isEmpty) return;
    setState(() => _busy = true);
    final ok = await NoteLocks.verify(_target, _password.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _wrong = !ok;
    });
    if (ok) {
      _opened();
    } else {
      _password.clear();
    }
  }

  Future<void> _forgot() async {
    await stows.encPassword.waitUntilRead();
    if (!mounted) return;
    if (!stows.loggedIn) {
      await showBnDialog<void>(
        context: context,
        title: "This password can't be recovered",
        message:
            'Only the password you set opens it. Sign in to the cloud to '
            'reset it with your notes password.',
        actions: [const BnDialogAction('OK', primary: true)],
      );
      return;
    }
    final controller = TextEditingController();
    final entered = await showBnDialog<String>(
      context: context,
      title: 'Reset with your notes password',
      message:
          'Type the password your notes are encrypted with in the cloud, '
          'then choose a new one for this lock.',
      content: _PasswordField(
        controller: controller,
        hint: 'Cloud notes password',
        autofocus: true,
      ),
      actions: [
        const BnDialogAction('Cancel'),
        const BnDialogAction('Continue', value: '', primary: true),
      ],
    );
    final typed = controller.text;
    controller.dispose();
    if (entered == null || !mounted) return;
    if (typed != stows.encPassword.value) {
      showBanner(context, "That isn't your notes password");
      return;
    }
    final set = await showSetLockSheet(
      context,
      path: _target,
      kind: _kind,
      change: true,
    );
    if (set && mounted) _opened();
  }

  @override
  Widget build(BuildContext context) {
    final name = p.basename(_target);
    final hint = _entry?.hint ?? '';
    final cover = _kind == .note ? NotebookCovers.read(_target) : null;
    final close = widget.onClose ?? () => Navigator.of(context).maybePop();
    return Scaffold(
      backgroundColor: const Color(0xFF121327),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF23264A), Color(0xFF121327)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(child: _art(cover)),
                        const SizedBox(height: 22),
                        Text(
                          name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: BnType.title.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Locked ${_kindWord(_kind)}',
                          textAlign: TextAlign.center,
                          style: BnType.caption.copyWith(color: Colors.white60),
                        ),
                        const SizedBox(height: 24),
                        if (_canFingerprint) ...[
                          Center(
                            child: IconButton.filledTonal(
                              iconSize: 34,
                              tooltip: 'Use fingerprint',
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white12,
                                foregroundColor: Colors.white,
                                fixedSize: const Size(64, 64),
                              ),
                              onPressed: _tryFingerprint,
                              icon: const Icon(Icons.fingerprint),
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                        _PasswordField(
                          controller: _password,
                          hint: 'Password',
                          dark: true,
                          autofocus: !_canFingerprint,
                          onSubmitted: (_) => _submit(),
                        ),
                        if (_wrong)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              hint.isEmpty
                                  ? 'Wrong password'
                                  : 'Wrong password · Hint: $hint',
                              textAlign: TextAlign.center,
                              style: BnType.caption.copyWith(
                                color: const Color(0xFFFF8A80),
                              ),
                            ),
                          ),
                        const SizedBox(height: 14),
                        BnPillButton(
                          label: 'Open',
                          kind: BnPillKind.accent,
                          expand: true,
                          onPressed: _busy ? null : _submit,
                        ),
                        const SizedBox(height: 6),
                        TextButton(
                          onPressed: _forgot,
                          child: Text(
                            'Forgot password?',
                            style: BnType.body.copyWith(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 8,
                top: 8,
                child: IconButton(
                  tooltip: 'Close',
                  onPressed: close,
                  icon: const Icon(BnIcons.close, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The cover (never the pages), blurred, with a lock on it.
  Widget _art(CoverDesign? cover) => SizedBox(
    width: 120,
    height: 156,
    child: Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: SizedBox.expand(
              child: cover != null
                  ? NotebookCover(design: cover, title: '')
                  : ColoredBox(
                      color: _kind == .note
                          ? const Color(0xFF3A3E6E)
                          : const Color(0xFF4A4F8A),
                    ),
            ),
          ),
        ),
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Color(0x99121327),
            shape: BoxShape.circle,
          ),
          child: const Icon(BnIcons.lock, color: Colors.white, size: 24),
        ),
      ],
    ),
  );
}

/// Asks for each locked one of [paths] in turn (a copy or an export has no
/// lock); false if any stays shut.
Future<bool> unlockEach(BuildContext context, List<String> paths) async {
  for (final path in paths) {
    if (!context.mounted || !await ensureUnlocked(context, path)) return false;
  }
  return true;
}
