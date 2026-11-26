import 'dart:async';
import 'dart:math';

import 'package:badnotes/components/onboarding/scenes/biology.dart';
import 'package:badnotes/components/onboarding/scenes/board.dart';
import 'package:badnotes/components/onboarding/scenes/brain.dart';
import 'package:badnotes/components/onboarding/scenes/chemistry.dart';
import 'package:badnotes/components/onboarding/scenes/heart.dart';
import 'package:badnotes/components/onboarding/scenes/math.dart';
import 'package:badnotes/components/onboarding/scenes/physics.dart';
import 'package:badnotes/components/onboarding/tour_engine.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/theming/badnotes_tokens.dart';
import 'package:badnotes/components/ui/bn_controls.dart';
import 'package:badnotes/components/ui/bn_icons.dart';
import 'package:badnotes/components/ui/bn_overlays.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One page of the tour: a scene and what it shows.
class _Slide {
  const new(this.kicker, this.title, this.text, this.scene);

  final String kicker, title, text;
  final TourScene Function() scene;
}

final _slides = <_Slide>[
  _Slide(
    'Welcome',
    'Write like paper. Edit like magic.',
    'Smooth ink, real pens and smart tools for every subject you study.',
    () => dnaScene,
  ),
  _Slide(
    'Pens',
    'Pens that feel like ink.',
    'Fountain pen, ballpoint, brush and highlighter in any colour, one tap '
        'apart in the toolbar.',
    () => neuronScene,
  ),
  _Slide(
    'Shapes',
    'Sketch it rough. Hold to snap.',
    'With Draw shapes, keep the pen still at the end of a line, box or arrow '
        'and it turns clean.',
    () => physicsScene,
  ),
  _Slide(
    'Lasso',
    'Circle it. Move it. Restyle it.',
    'Lasso any writing to move it, pull a corner to resize, and recolour or '
        'copy it from the bar.',
    () => lassoScene,
  ),
  _Slide(
    'Search',
    'Search your handwriting.',
    'BadNotes reads what you write, so a typed search finds handwritten '
        'words too.',
    () => searchScene,
  ),
  _Slide(
    'Recording',
    'Replay the lecture with your notes.',
    'Record while you write. Playback redraws each line in time, or '
        'Spotlight brings up what you wrote at that moment.',
    () => recordingScene,
  ),
  _Slide(
    'Study',
    'Tape over it. Quiz yourself.',
    'Cover labels with tape and tap to peek, or run Tape Quiz from the More '
        'menu.',
    () => tapeScene,
  ),
  _Slide(
    'Make it yours',
    'Dark pages. Your toolbar, your way.',
    'Pages turn dark with the app, and the tools float over the page or dock '
        'in the header.',
    () => darkScene,
  ),
  _Slide(
    'Pin board',
    'Pin it to your desk.',
    'Quick notes, to-dos and sketches stay on your desk. Tap New to start '
        'your first notebook.',
    () => boardScene,
  ),
];

/// Every page's scene, in order (for tests).
@visibleForTesting
List<TourScene> get tourScenes => [for (final s in _slides) s.scene()];

/// Shows the tour as a card over the dimmed desk. Only Skip (or the last
/// page's button) closes it: a tap beside it does nothing.
Future<void> showFeatureTour(BuildContext context) => showGeneralDialog<void>(
  context: context,
  useRootNavigator: true,
  barrierDismissible: false,
  barrierColor: const Color(0x8C0E0E12),
  transitionDuration: BnMotion.normal,
  pageBuilder: (_, _, _) => const FeatureTour(),
  transitionBuilder: (context, animation, _, child) =>
      bnPopIn(context, animation, child),
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

/// What BadNotes can do, one short film at a time: shown once after a fresh
/// install and from Settings › Help.
class FeatureTour extends StatefulWidget {
  const new({super.key});

  @override
  State<FeatureTour> createState() => _FeatureTourState();
}

class _FeatureTourState extends State<FeatureTour> {
  final _pages = PageController();
  var _index = 0;

  @override
  void initState() {
    super.initState();
    // seen once it has been opened, even if the app is closed mid-way
    stows.tourSeen.value = true;
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  bool get _last => _index == _slides.length - 1;

  void _go(int to) {
    if (to < 0 || to >= _slides.length || to == _index) return;
    final from = _index;
    // the page coming in starts playing (from its first frame) now, not
    // halfway through the slide, and the one going out holds its frame
    setState(() => _index = to);
    if (MediaQuery.disableAnimationsOf(context) || (to - from).abs() > 1) {
      _pages.jumpToPage(to);
    } else {
      _pages.animateToPage(
        to,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeInOutCubic,
      );
    }
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
    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            final wide = size.width >= 640 && size.height >= 520;
            final pad = wide ? 24.0 : 14.0;
            final textHeight = wide ? 102.0 : 122.0;
            const headerHeight = 50.0, footerHeight = 66.0, gap = 16.0;
            const chrome = headerHeight + gap + footerHeight;
            final maxW = wide ? min(880.0, size.width - 48) : size.width * 0.92;
            final maxH = size.height - (wide ? 40 : 24);
            var stageW = maxW - pad * 2;
            var stageH = stageW / 1.6;
            if (stageH + textHeight + chrome > maxH) {
              stageH = max(120.0, maxH - textHeight - chrome);
              stageW = stageH * 1.6;
            }
            final cardW = wide ? stageW + pad * 2 : maxW;
            final cardH = min(maxH, stageH + textHeight + chrome);

            return Center(
              child: Container(
                width: cardW,
                height: cardH,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: const BorderRadius.all(Radius.circular(28)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x2E000000), blurRadius: 60, offset: Offset(0, 24)),
                    BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
                  ],
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    children: [
                      SizedBox(
                        height: headerHeight,
                        child: Padding(
                          padding: EdgeInsets.only(left: pad + 4, right: pad - 6),
                          child: Row(
                            children: [
                              Text(
                                '${_index + 1} / ${_slides.length}',
                                style: BnType.caption.copyWith(
                                  color: colors.muted,
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                              const Spacer(),
                              if (_last)
                                IconButton(
                                  tooltip: 'Close',
                                  onPressed: _close,
                                  icon: Icon(BnIcons.close, size: 20, color: colors.muted),
                                )
                              else
                                BnButton(
                                  label: 'Skip',
                                  kind: BnButtonKind.quiet,
                                  height: 36,
                                  onPressed: _close,
                                ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: PageView.builder(
                          controller: _pages,
                          itemCount: _slides.length,
                          onPageChanged: (i) => setState(() => _index = i),
                          itemBuilder: (context, i) => _Crossfade(
                            controller: _pages,
                            index: i,
                            child: _Page(
                              slide: _slides[i],
                              active: i == _index,
                              stage: Size(stageW, stageH),
                              textHeight: textHeight,
                              pad: pad,
                              wide: wide,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        height: footerHeight,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(pad + 4, 0, pad, 6),
                          child: _Controls(
                            index: _index,
                            last: _last,
                            onBack: _index == 0 ? null : () => _go(_index - 1),
                            onNext: _next,
                            onDot: _go,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Holds a page in place as the pager slides it, so pages crossfade (with
/// a slight scale) instead of moving sideways.
class _Crossfade extends StatelessWidget {
  const new({required this.controller, required this.index, required this.child});

  final PageController controller;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, child) {
      var delta = 0.0;
      if (controller.hasClients && controller.position.haveDimensions) {
        delta = (controller.page ?? index.toDouble()) - index;
      }
      final d = delta.abs().clamp(0.0, 1.0);
      return LayoutBuilder(
        builder: (context, c) => Transform.translate(
          offset: Offset(delta * c.maxWidth, 0),
          child: Opacity(
            opacity: Curves.easeInOut.transform(1 - d),
            child: Transform.scale(scale: 1 - 0.04 * d, child: child),
          ),
        ),
      );
    },
    child: child,
  );
}

/// A page: the stage, then the kicker, title and line under it, which
/// rise into place when the page comes up.
class _Page extends StatefulWidget {
  const new({
    required this.slide,
    required this.active,
    required this.stage,
    required this.textHeight,
    required this.pad,
    required this.wide,
  });

  final _Slide slide;
  final bool active, wide;
  final Size stage;
  final double textHeight, pad;

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> with SingleTickerProviderStateMixin {
  late final _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 640),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _enter.value = 1;
    } else if (widget.active && _enter.value == 0) {
      _enter.forward();
    }
  }

  @override
  void didUpdateWidget(_Page old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active && !MediaQuery.disableAnimationsOf(context)) {
      _enter.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  /// [child] fading in and rising 14 dp, between [a] and [b] of the entrance.
  Widget _rise(double a, double b, Widget child) {
    final k = CurvedAnimation(parent: _enter, curve: Interval(a, b, curve: Curves.easeOutCubic));
    return FadeTransition(
      opacity: k,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.35), end: Offset.zero).animate(k),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final slide = widget.slide;
    return Column(
      children: [
        Center(
          child: SizedBox.fromSize(
            size: widget.stage,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: colors.hairline),
                borderRadius: const BorderRadius.all(Radius.circular(18)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(17)),
                child: TourStage(scene: slide.scene(), playing: widget.active),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: widget.textHeight,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.pad + 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _rise(0, 0.6, Text(
                  slide.kicker.toUpperCase(),
                  maxLines: 1,
                  style: BnType.micro.copyWith(
                    color: colors.accent,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                )),
                const SizedBox(height: 6),
                _rise(0.1, 0.75, Text(
                  slide.title,
                  maxLines: widget.wide ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: BnType.display.copyWith(
                    color: colors.text,
                    fontSize: widget.wide ? 26 : 21,
                    height: 1.15,
                  ),
                )),
                const SizedBox(height: 6),
                Flexible(
                  child: _rise(0.22, 0.9, Text(
                    slide.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: BnType.bodyLarge.copyWith(
                      color: colors.text2,
                      fontSize: widget.wide ? 15 : 14,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  )),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The progress dots (the current one stretched) and the buttons.
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
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
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
                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 320),
                            curve: Curves.easeOutCubic,
                            width: i == index ? 22 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: i == index
                                  ? colors.accent
                                  : i < index
                                  ? colors.handle
                                  : colors.hairline,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (onBack != null) ...[
          BnButton(label: 'Back', kind: BnButtonKind.quiet, height: 42, onPressed: onBack),
          const SizedBox(width: 4),
        ],
        BnButton.primary(
          label: last ? 'Get started' : 'Next',
          height: 42,
          onPressed: onNext,
        ),
      ],
    );
  }
}
