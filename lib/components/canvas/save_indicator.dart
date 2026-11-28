import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:badnotes/data/is_this_a_test.dart';
import 'package:badnotes/components/theming/badnotes_tokens.dart';
import 'package:badnotes/data/routes.dart';

/// Where the open note stands with saving.
enum SavingState {
  /// There are changes that have not been written yet.
  waitingToSave,

  /// The note is being written right now.
  saving,

  /// Everything is written.
  saved,
}

/// The editor's back button. A small dot on its corner tells whether the
/// note is saved: green when it is, orange while changes wait or are being
/// written.
///
/// Tapping it with unsaved changes saves first and then leaves, so getting
/// out is always one tap.
class SaveIndicator extends StatelessWidget {
  const new({
    super.key,
    required this.savingState,
    required this.triggerSave,
    this.onLeave,
  });

  final ValueNotifier<SavingState> savingState;
  final Future<void> Function() triggerSave;

  /// Leaves the note instead of this button doing it itself: the editor
  /// passes the same leave Android's back uses, so the two can't both pop.
  final Future<void> Function()? onLeave;

  static const _savedColor = Color(0xFF2FB36A);
  static const _unsavedColor = Color(0xFFF39C12);

  /// The longest we wait for a save in progress before giving up on leaving.
  static const _saveTimeout = Duration(seconds: 10);

  static String _tooltipFor(SavingState state) => switch (state) {
    .saved => 'Home',
    .waitingToSave => 'Save and go home',
    .saving => 'Saving…',
  };

  @override
  Widget build(BuildContext context) {
    final ringColor = ColorScheme.of(context).surface;
    // the dot changes with every save: only the button is drawn again
    return RepaintBoundary(
      child: ValueListenableBuilder(
        valueListenable: savingState,
        builder: (context, state, _) => IconButton(
          tooltip: _tooltipFor(state),
          onPressed: () => onLeave != null ? onLeave!() : _leave(context),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              Positioned(top: -3, right: -5, child: _dot(state, ringColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(SavingState state, Color ringColor) => AnimatedContainer(
    duration: isThisATest ? Duration.zero : BnMotion.fast,
    curve: BnMotion.curve,
    width: 8,
    height: 8,
    decoration: BoxDecoration(
      color: state == .saved ? _savedColor : _unsavedColor,
      shape: BoxShape.circle,
      border: Border.all(color: ringColor, width: 1.5),
    ),
  );

  /// Saves if needed, waits for a save already running, and leaves only once
  /// the note is saved.
  Future<void> _leave(BuildContext context) async {
    // pressed again while the first press is still saving: that one leaves
    final route = ModalRoute.of(context);
    if (route != null && _leaving.contains(route)) return;
    if (route != null) _leaving.add(route);
    try {
      if (savingState.value == .waitingToSave) await triggerSave();
      if (savingState.value == .saving) await _whileSaving();
      if (!context.mounted) return;
      if (savingState.value != .saved) return;
      _goBack(context);
    } finally {
      if (route != null) _leaving.remove(route);
    }
  }

  /// Editors whose back button is already leaving them.
  static final _leaving = <ModalRoute<Object?>>{};

  /// Completes soon after [savingState] stops being [SavingState.saving]
  /// (it is checked every 50 ms), or after [_saveTimeout] at the latest.
  Future<void> _whileSaving() {
    if (savingState.value == .saved) return Future.value();
    var finished = false;
    void onChange() {
      if (savingState.value != .saving) finished = true;
    }

    savingState.addListener(onChange);
    final poll = Future.doWhile(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return !finished;
    });
    return Future.any([poll, Future<void>.delayed(_saveTimeout)])
        .whenComplete(() => savingState.removeListener(onChange));
  }

  /// Pops the editor, or, when it is the whiteboard and there is nothing to
  /// pop, goes to the first home tab (recent notes).
  void _goBack(BuildContext context) {
    // Android's back (gesture or button) may have left the note already,
    // while this one was saving: popping now would pop the home screen
    // under it, and with nothing left the app closed.
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return;
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      context.go(HomeRoutes.routes[0].path);
    }
  }
}
