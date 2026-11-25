import 'dart:async';

import 'package:badnotes/components/onboarding/demos.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/theming/badnotes_tokens.dart';
import 'package:badnotes/components/ui/bn_controls.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One page of the tour: a live demo and what it shows.
class _Slide {
  const new(this.kicker, this.title, this.text, this.demo);

  final String kicker, title, text;
  final Widget Function() demo;
}

final _slides = <_Slide>[
  const _Slide(
    'Welcome',
    'Handwriting, with a few tricks paper never had.',
    'A one-minute look at what BadNotes can do. Skip it whenever you like; '
        'it stays in Settings under Help.',
    welcomeDemo,
  ),
  const _Slide(
    'Lasso',
    'Circle it, then move it anywhere.',
    'Draw a loop round any writing with the lasso. Drag it to move, pull a '
        'corner to resize, and use the bar underneath to recolor, copy, '
        'duplicate or take a screenshot of it.',
    lassoDemo,
  ),
  const _Slide(
    'Shapes',
    'Draw it rough. Hold, and it snaps.',
    'With Draw shapes, sketch a circle, box or arrow and keep the pen still '
        'for a moment: it turns into a clean shape. Turn on Hold for shapes '
        'to do the same with the ballpoint.',
    shapesDemo,
  ),
  const _Slide(
    'Search',
    'Search finds your handwriting.',
    'BadNotes reads your writing in the background, so a search finds '
        'handwritten words like typed ones, in a note or across all of them '
        'from the desk.',
    searchDemo,
  ),
  const _Slide(
    'Recording',
    'Play back the lecture, and your notes with it.',
    'Record while you write. On playback, each line writes itself in time '
        'with the sound, or Spotlight fades the page and brings up what you '
        'wrote at that moment.',
    recordingDemo,
  ),
  const _Slide(
    'Study',
    'Tape over the answers. Tap to check.',
    'Cover anything with the tape and tap a strip to peek underneath; Tape '
        'Quiz in the More menu runs through them like flashcards. At night, '
        'pages turn dark with the app.',
    tapeDemo,
  ),
  const _Slide(
    'Tabs and split view',
    'Two notes, side by side.',
    'Notes you open stay as tabs. Hold a tab and drag it onto the page to '
        'read and write in both, or pick Split View in the More menu.',
    splitDemo,
  ),
  const _Slide(
    'Make it yours',
    'Floating or docked. Light or dark.',
    'Keep the tools in a bar that floats over the page, or dock them in the '
        'header. Toolbar style is under Settings › Editor, and the theme '
        'under Settings › General.',
    toolbarDemo,
  ),
  const _Slide(
    'Present',
    'Point, and it fades away.',
    'The laser draws a glowing trail that disappears once you stop. Share › '
        'Present puts the note on a TV or projector: everything, just your '
        'ink, or the whole page.',
    presentDemo,
  ),
  const _Slide(
    'Pin board',
    'Quick notes, pinned to your desk.',
    'Jot something down, write on it by hand, and it lands on the board on '
        'your desk. Hold a note to move, resize or turn it.',
    pinBoardDemo,
  ),
  const _Slide(
    'Version history',
    'Go back to any earlier version.',
    'Versions are kept while you work. Open Version History from the More '
        'menu to look back, open one as a copy, or restore it.',
    versionsDemo,
  ),
  const _Slide(
    'All set',
    'Start your first notebook.',
    'Tap New on the desk for a notebook, a whiteboard or a quick note.',
    startDemo,
  ),
];

/// Shows the tour as a full-screen page that fades in.
Future<void> showFeatureTour(BuildContext context) =>
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, _, _) => const FeatureTour(),
        transitionsBuilder: (_, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        ),
      ),
    );

var _checked = false;

/// Shows the tour once, on the first launch after a fresh install.
///
/// The [Stows.tourSeen] key is new, so an install updated from an older
/// version doesn't have it either. Those already have notes, recent notes or
/// a sync behind them: when any of that is there the tour is marked seen
/// without showing. A fresh install has none of it.
Future<void> maybeShowFeatureTour(BuildContext context) async {
  if (_checked) return;
  _checked = true;
  await Future.wait([
    stows.tourSeen.waitUntilRead(),
    stows.recentFiles.waitUntilRead(),
    stows.lastSyncedMs.waitUntilRead(),
  ]);
  if (stows.tourSeen.value) return;
  final notes = await FileManager.getChildrenOfDirectory('/');
  final fresh =
      (notes == null || notes.isEmpty) &&
      stows.recentFiles.value.isEmpty &&
      stows.lastSyncedMs.value == 0;
  if (!fresh) {
    stows.tourSeen.value = true;
    return;
  }
  if (context.mounted) await showFeatureTour(context);
}

/// What BadNotes can do, one live demo at a time: shown once after a fresh
/// install and from Settings › Help.
class FeatureTour extends StatefulWidget {
  const new({super.key});

  @override
  State<FeatureTour> createState() => _FeatureTourState();
}

class _FeatureTourState extends State<FeatureTour> {
  var _index = 0;

  /// 1 going forward, -1 going back: which side the text comes in from.
  var _direction = 1;

  @override
  void initState() {
    super.initState();
    // seen once it has been opened, even if the app is closed mid-way
    stows.tourSeen.value = true;
  }

  bool get _last => _index == _slides.length - 1;

  void _go(int to) {
    if (to < 0 || to >= _slides.length || to == _index) return;
    setState(() {
      _direction = to > _index ? 1 : -1;
      _index = to;
    });
  }

  void _next() => _last ? _close() : _go(_index + 1);

  void _close() => Navigator.of(context).pop();

  KeyEventResult _onKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _next();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _go(_index - 1);
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      _close();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final still = MediaQuery.disableAnimationsOf(context);
    final slide = _slides[_index];

    // the demo: scales up from 0.96 as it fades in; one plays at a time
    final stage = AnimatedSwitcher(
      duration: still ? Duration.zero : const Duration(milliseconds: 480),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween(begin: 0.96, end: 1.0).animate(animation),
          child: child,
        ),
      ),
      child: KeyedSubtree(key: ValueKey(_index), child: slide.demo()),
    );

    final stageCard = DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.hairline),
        borderRadius: const BorderRadius.all(Radius.circular(BnRadius.popover)),
        boxShadow: BnShadows.floating,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(
          Radius.circular(BnRadius.popover - 1),
        ),
        child: AspectRatio(aspectRatio: 4 / 3, child: stage),
      ),
    );

    final skip = _last
        ? const SizedBox(height: 40)
        : BnButton(
            label: 'Skip',
            kind: BnButtonKind.quiet,
            onPressed: _close,
          );

    return Scaffold(
      backgroundColor: colors.desk,
      body: Focus(
        autofocus: true,
        onKeyEvent: _onKey,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: (details) {
            final v = details.primaryVelocity ?? 0;
            if (v < -250) _next();
            if (v > 250) _go(_index - 1);
          },
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide =
                    constraints.maxWidth >= 720 &&
                    constraints.maxWidth > constraints.maxHeight * 0.9;
                final text = _SlideText(
                  slide: slide,
                  index: _index,
                  direction: _direction,
                  still: still,
                  large: wide,
                );
                final controls = _Controls(
                  index: _index,
                  last: _last,
                  onBack: _index == 0 ? null : () => _go(_index - 1),
                  onNext: _next,
                  onDot: _go,
                );
                if (wide) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(40, 16, 40, 32),
                    child: Column(
                      children: [
                        Align(alignment: Alignment.centerRight, child: skip),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                flex: 11,
                                child: Center(child: stageCard),
                              ),
                              const SizedBox(width: 48),
                              Expanded(
                                flex: 7,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    text,
                                    const SizedBox(height: 32),
                                    controls,
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(alignment: Alignment.centerRight, child: skip),
                      const SizedBox(height: 4),
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: constraints.maxHeight * 0.48,
                          ),
                          child: stageCard,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: text,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: controls,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// The kicker, title and description, sliding in 12 dp from the side the
/// tour is going.
class _SlideText extends StatelessWidget {
  const new({
    required this.slide,
    required this.index,
    required this.direction,
    required this.still,
    required this.large,
  });

  final _Slide slide;
  final int index, direction;
  final bool still, large;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return AnimatedSwitcher(
      duration: still ? Duration.zero : const Duration(milliseconds: 420),
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topLeft,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) {
        // the new text waits a moment for the demo, the old one just fades
        final incoming = child.key == ValueKey(index);
        final eased = CurvedAnimation(
          parent: animation,
          curve: incoming
              ? const Interval(0.2, 1, curve: Curves.easeOutCubic)
              : Curves.easeOut,
        );
        return FadeTransition(
          opacity: eased,
          child: incoming
              ? AnimatedBuilder(
                  animation: eased,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(12.0 * direction * (1 - eased.value), 0),
                    child: child,
                  ),
                  child: child,
                )
              : child,
        );
      },
      child: Column(
        key: ValueKey(index),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            slide.kicker.toUpperCase(),
            style: BnType.micro.copyWith(
              color: colors.accent,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            slide.title,
            style: BnType.display.copyWith(
              color: colors.text,
              fontSize: large ? 34 : 26,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            slide.text,
            style: BnType.bodyLarge.copyWith(
              color: colors.text2,
              fontSize: large ? 16 : 15,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// The progress pills and the buttons.
class _Controls extends StatelessWidget {
  const new({
    required this.index,
    required this.last,
    required this.onBack,
    required this.onNext,
    required this.onDot,
  });

  final int index;
  final bool last;
  final VoidCallback? onBack;
  final VoidCallback onNext;
  final ValueChanged<int> onDot;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < _slides.length; i++)
                Semantics(
                  button: true,
                  selected: i == index,
                  label: 'Page ${i + 1} of ${_slides.length}',
                  child: GestureDetector(
                    onTap: () => onDot(i),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOutCubic,
                        width: i == index ? 22 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == index
                              ? colors.accent
                              : i < index
                              ? colors.handle
                              : colors.hairline,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (onBack != null) ...[
          BnButton(label: 'Back', kind: BnButtonKind.quiet, onPressed: onBack),
          const SizedBox(width: 4),
        ],
        BnButton.primary(
          label: last ? 'Get started' : 'Next',
          height: 44,
          onPressed: onNext,
        ),
      ],
    );
  }
}
