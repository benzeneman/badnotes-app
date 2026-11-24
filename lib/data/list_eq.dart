/// Whether [list] and [other] hold equal items in the same order. Like
/// Flutter's `listEquals`, without the nulls.
bool listEq<T>(List<T> list, List<T> other) =>
    identical(list, other) ||
    (list.length == other.length &&
        Iterable<int>.generate(list.length).every((i) => list[i] == other[i]));
