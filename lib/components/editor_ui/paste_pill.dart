import 'package:badnotes/components/editor/note_clipboard.dart';
import 'package:flutter/material.dart';

/// After a copy, a dark pill at the top of the page (design 16): what was
/// copied and Paste, in this note or any other opened next; × closes it.
class PastePill extends StatelessWidget {
  const PastePill({super.key, required this.onPaste, this.enabled = true});

  final VoidCallback onPaste;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: NoteClipboard.offered,
      builder: (context, offered, _) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, -0.4),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: !offered || !enabled || !NoteClipboard.hasContent
            ? const SizedBox.shrink()
            : Material(
                key: const ValueKey('paste-pill'),
                color: const Color(0xFF1C1C1F),
                elevation: 8,
                shadowColor: Colors.black45,
                shape: const StadiumBorder(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 5, 5, 5),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.content_paste,
                        size: 16,
                        color: Color(0xFFEDEDEF),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        NoteClipboard.summary,
                        style: const TextStyle(
                          color: Color(0xFFEDEDEF),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Material(
                        color: const Color(0xFFB9ADF7),
                        shape: const StadiumBorder(),
                        child: InkWell(
                          customBorder: const StadiumBorder(),
                          onTap: onPaste,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              'Paste',
                              style: TextStyle(
                                color: Color(0xFF1C1C1F),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        visualDensity: VisualDensity.compact,
                        iconSize: 18,
                        color: const Color(0xFF8E8E93),
                        onPressed: () => NoteClipboard.offered.value = false,
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
