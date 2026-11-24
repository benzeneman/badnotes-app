/// A value before and after an edit, used by undo and redo.
class Change<T> {
  /// The value before the edit.
  final T previous;

  /// The value after the edit.
  final T current;

  const new({required this.previous, required this.current});

  /// The opposite edit: going from [current] back to [previous].
  Change<T> reverse() => Change(previous: current, current: previous);
}
