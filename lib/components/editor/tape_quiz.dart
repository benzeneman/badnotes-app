import 'package:flutter/material.dart';

/// Goes through what's hidden under tape like flashcards: anything not known
/// comes round again at the end, until everything has been known once.
class TapeQuiz<T> {
  TapeQuiz(List<T> items) : total = items.length, _queue = [...items];

  final int total;
  final List<T> _queue;
  final _missed = <T>{};

  T? get current => _queue.isEmpty ? null : _queue.first;
  bool get finished => _queue.isEmpty;

  /// How many cards have been known so far.
  int get done => total - _queue.length;

  /// How many were known at the first try.
  int get firstTry => total - _missed.length;

  void answer({required bool knewIt}) {
    if (_queue.isEmpty) return;
    final card = _queue.removeAt(0);
    if (knewIt) return;
    _missed.add(card);
    _queue.add(card);
  }
}

/// The quiz's controls, under the tape being asked.
class TapeQuizBar extends StatelessWidget {
  const TapeQuizBar({
    super.key,
    required this.done,
    required this.total,
    required this.revealed,
    required this.onReveal,
    required this.onAnswer,
    required this.onClose,
  });

  final int done, total;
  final bool revealed;
  final VoidCallback onReveal;
  final ValueChanged<bool> onAnswer;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(24),
      color: ColorScheme.of(context).surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: .min,
          spacing: 8,
          children: [
            IconButton(
              tooltip: 'End quiz',
              icon: const Icon(Icons.close),
              onPressed: onClose,
            ),
            Text('${done + 1} / $total'),
            if (revealed) ...[
              OutlinedButton(
                onPressed: () => onAnswer(false),
                child: const Text('Again'),
              ),
              FilledButton(
                onPressed: () => onAnswer(true),
                child: const Text('Knew it'),
              ),
            ] else
              FilledButton(onPressed: onReveal, child: const Text('Reveal')),
          ],
        ),
      ),
    );
  }
}
