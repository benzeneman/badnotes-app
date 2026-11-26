import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:badnotes/components/canvas/image/editor_image.dart';
import 'package:badnotes/data/editor/page.dart';
import 'package:sbn/canvas_background_pattern.dart';
import 'package:sbn/change.dart';

/// The editor's undo and redo: changes done (newest last) and changes
/// undone (most recently undone last), and which of them is saved.
class EditorHistory {
  /// The most changes that can be undone; older ones are forgotten.
  static const maxHistoryLength = 100;

  /// Ticks whenever [canUndo] or [canRedo] may have changed, for the undo
  /// buttons to follow without rebuilding the editor.
  final changes = ValueNotifier(0);
  void _changed() => changes.value++;

  /// Changes made, to undo from the end.
  final List<Historic> _past = [];

  /// Changes undone, to redo from the end.
  final List<Historic> _future = [];

  /// The newest change when the note was last saved (null: none).
  Historic? _lastSaved;

  /// Something not in the history (it can't be undone) waits to be saved.
  var _hasUnsavedExtra = false;

  /// Every change counted, including [markUnsaved].
  var _changeCount = 0;

  /// Whether redo is offered. Separate from [_future]: a stroke taken back
  /// as an accident (a finger landing while zooming) mustn't throw away what
  /// could be redone.
  var _isRedoPossible = false;

  /// Makes the next save go through though the history hasn't changed.
  void markUnsaved() {
    _hasUnsavedExtra = true;
    _changeCount++;
  }

  /// Moves the newest change of [from] to [to] and returns it; [what] names
  /// the step for the error when there's nothing to move.
  Historic _shift(List<Historic> from, List<Historic> to, String what) {
    if (from.isEmpty) throw Exception('Nothing to $what');
    final item = from.removeLast();
    to.add(item);
    _changeCount++;
    _changed();
    return item;
  }

  /// Takes back the newest change and returns it to be reversed. Check
  /// [canUndo] first: with nothing to undo this throws.
  Historic undo() => _shift(_past, _future, 'undo');

  /// Puts back the most recently undone change and returns it. Check
  /// [canRedo] first: with nothing to redo this throws.
  Historic redo() => _shift(_future, _past, 'redo');

  /// The change [undo] would take back, left where it is. Throws if none.
  Historic peekUndo() =>
      _past.isEmpty ? throw Exception('Nothing to undo') : _past.last;

  /// The change [redo] would put back, left where it is. Throws if none.
  Historic peekRedo() =>
      _future.isEmpty ? throw Exception('Nothing to redo') : _future.last;

  /// Adds a change just made. Past [maxHistoryLength] the oldest goes, and
  /// redo is no longer offered.
  void recordChange(Historic item) {
    assert(
      item is! HistoricQuillReverseChange,
      'A reversed text change is only made while undoing; record the change itself.',
    );
    _past.add(item);
    _changeCount++;
    if (_past.length > maxHistoryLength) _past.removeAt(0);
    _isRedoPossible = false;
    _changed();
  }

  /// The note was just saved as it is now.
  void markLastChangeAsSaved() {
    _lastSaved = _past.lastOrNull;
    _hasUnsavedExtra = false;
  }

  /// What [markSavedAt] needs to know about the state being saved now.
  ({Historic? last, int changes}) get savePoint =>
      (last: _past.lastOrNull, changes: _changeCount);

  /// Marks [point] as saved, from before a save that took a while: changes
  /// made since then still need saving.
  void markSavedAt(({Historic? last, int changes}) point) {
    _lastSaved = point.last;
    if (point.changes == _changeCount) _hasUnsavedExtra = false;
  }

  /// Whether the note on disk is the note as it is now. Compares the newest
  /// change, not the length: old changes are forgotten past
  /// [maxHistoryLength].
  bool get isCurrentStateSaved =>
      !_hasUnsavedExtra && _past.lastOrNull == _lastSaved;

  /// Takes back the stroke just recorded because it was an accident (a
  /// single stroke, no pictures), keeping redo as it was. Returns it, or
  /// null if there's nothing to take back.
  Historic? removeAccidentalStroke() {
    _isRedoPossible = true;
    if (_past.isEmpty) return null;
    assert(() {
      final last = _past.last;
      return last is HistoricAdd &&
          last.strokes.length == 1 &&
          last.images.isEmpty;
    }(), 'The last change should be one accidental stroke, not ${_past.last}');
    final removed = _past.removeLast();
    _changed();
    return removed;
  }

  bool get canUndo => _past.isNotEmpty;

  bool get canRedo => _isRedoPossible && _future.isNotEmpty;
  set canRedo(bool isRedoPossible) {
    if (_isRedoPossible == isRedoPossible) return;
    _isRedoPossible = isRedoPossible;
    _changed();
  }

  /// Forgets everything that could be redone.
  void clearRedo() {
    _future.clear();
    _changed();
  }
}

/// One change to a note, which can be undone by doing its [reverse].
sealed class Historic {
  @protected
  const new();

  /// The change that undoes this one (an add's is a delete, and so on).
  Historic reverse();
}

/// Several changes made as one, undone as one.
class HistoricGroup extends Historic {
  const HistoricGroup(this.changes);

  /// In the order they were made.
  final List<Historic> changes;

  @override
  HistoricGroup reverse() =>
      HistoricGroup([for (final change in changes.reversed) change.reverse()]);
}

/// Strokes and pictures were put on a page.
class const HistoricAdd({
  required final List<Stroke> strokes,
  required final List<EditorImage> images,
}) extends Historic {
  @override
  HistoricDelete reverse() => .new(strokes: strokes, images: images);
}

/// Strokes and pictures were taken off a page.
class const HistoricDelete({
  required final List<Stroke> strokes,
  required final List<EditorImage> images,
}) extends Historic {
  @override
  HistoricAdd reverse() => .new(strokes: strokes, images: images);
}

/// Strokes were swapped for others in one step,
/// e.g. the precise eraser cutting strokes into pieces.
class const HistoricReplace({
  required final List<Stroke> removed,
  required final List<Stroke> added,
}) extends Historic {
  @override
  HistoricReplace reverse() => .new(removed: added, added: removed);
}

/// Strokes changed shape in place, e.g. stretched with the lasso: [before]
/// and [after] are copies of how they looked. The strokes themselves stay
/// the same objects, so changes recorded before and after this one still
/// find them on the page when they're undone.
class const HistoricReshape({
  required final List<Stroke> strokes,
  required final List<Stroke> before,
  required final List<Stroke> after,
}) extends Historic {
  @override
  HistoricReshape reverse() =>
      .new(strokes: strokes, before: after, after: before);
}

/// Strokes and pictures were moved by [offset], from page [prevPageIndex]
/// to page [pageIndex] (the same page, unless they went to another).
class const HistoricMove({
  required final int pageIndex,
  required final int prevPageIndex,
  required final List<Stroke> strokes,
  required final List<EditorImage> images,
  required final Rect offset,
}) extends Historic {
  @override
  HistoricMove reverse() => .new(
    pageIndex: prevPageIndex,
    prevPageIndex: pageIndex,
    strokes: strokes,
    images: images,
    offset: .fromLTRB(-offset.left, -offset.top, -offset.right, -offset.bottom),
  );
}

/// Strokes and images were scaled by [scale] and rotated by [angle] radians
/// around [center]. Images are only scaled (their position follows the rotation).
class const HistoricTransform({
  required final List<Stroke> strokes,
  required final List<EditorImage> images,
  required final Offset center,
  required final double scale,
  required final double angle,
}) extends Historic {
  @override
  HistoricTransform reverse() => .new(
    strokes: strokes,
    images: images,
    center: center,
    scale: 1 / scale,
    angle: -angle,
  );
}

/// [page] was put in as page [pageIndex].
class const HistoricPageInsert({
  required final int pageIndex,
  required final EditorPage page,
  final bool onlyPage = false,
}) extends Historic {
  @override
  HistoricPageDelete reverse() =>
      .new(pageIndex: pageIndex, page: page, onlyPage: onlyPage);
}

/// [page], page [pageIndex], was taken out. With [onlyPage] it was the
/// note's only page, and a blank one took its place.
class const HistoricPageDelete({
  required final int pageIndex,
  required final EditorPage page,
  final bool onlyPage = false,
}) extends Historic {
  @override
  HistoricPageInsert reverse() =>
      .new(pageIndex: pageIndex, page: page, onlyPage: onlyPage);
}

/// The text of a sticky note, text box, link or comment changed.
class const HistoricSvgEdit({
  required final SvgEditorImage image,
  required final String svgBefore,
  required final Size sizeBefore,
  required final String svgAfter,
  required final Size sizeAfter,
}) extends Historic {
  @override
  HistoricSvgEdit reverse() => .new(
    image: image,
    svgBefore: svgAfter,
    sizeBefore: sizeAfter,
    svgAfter: svgBefore,
    sizeAfter: sizeBefore,
  );
}

/// The order of a page's strokes and images changed.
class const HistoricReorder({
  required final int pageIndex,
  required final List<Stroke> strokesBefore,
  required final List<EditorImage> imagesBefore,
  required final List<Stroke> strokesAfter,
  required final List<EditorImage> imagesAfter,
}) extends Historic {
  @override
  HistoricReorder reverse() => .new(
    pageIndex: pageIndex,
    strokesBefore: strokesAfter,
    imagesBefore: imagesAfter,
    strokesAfter: strokesBefore,
    imagesAfter: imagesBefore,
  );
}

/// The page at [pageIndex] was turned by a quarter.
/// The pages were put in a different order.
class const HistoricPageOrder({
  required final List<EditorPage> before,
  required final List<EditorPage> after,
}) extends Historic {
  @override
  HistoricPageOrder reverse() => .new(before: after, after: before);
}

class const HistoricPageRotate({
  required final int pageIndex,
  required final bool clockwise,
}) extends Historic {
  @override
  HistoricPageRotate reverse() =>
      .new(pageIndex: pageIndex, clockwise: !clockwise);
}

/// The page's typed text changed.
class const HistoricQuillChange({
  required final int pageIndex,
  required final DocChange quillChange,
}) extends Historic {
  @override
  HistoricQuillReverseChange reverse() =>
      .new(pageIndex: pageIndex, quillChange: quillChange);
}

/// A typed-text change being undone: holds the same [quillChange] as the
/// change it undoes, so undoing it hands the text editor that change to
/// take back.
class const HistoricQuillReverseChange({
  required final int pageIndex,
  required final DocChange quillChange,
}) extends Historic {
  @override
  HistoricQuillChange reverse() =>
      .new(pageIndex: pageIndex, quillChange: quillChange);
}

/// Strokes changed colour; [colorChanges] has each one's old and new.
class const HistoricColorChange({
  required final int pageIndex,
  required final Map<Stroke, Change<Color>> colorChanges,
}) extends Historic {
  @override
  HistoricColorChange reverse() => .new(
    pageIndex: pageIndex,
    colorChanges: colorChanges.map(
      (key, value) => MapEntry(key, value.reverse()),
    ),
  );
}

/// Several pages' background patterns were changed at once (the page
/// template set for all pages): undone in one step.
class const HistoricPagesPatternChange({
  required final List<int> pageIndexes,
  required final List<CanvasBackgroundPattern?> before,
  required final List<CanvasBackgroundPattern?> after,
}) extends Historic {
  @override
  HistoricPagesPatternChange reverse() =>
      .new(pageIndexes: pageIndexes, before: after, after: before);
}

/// A page's lines, squares or dots changed.
class const HistoricBackgroundPatternChange({
  required final int pageIndex,
  required final Change<CanvasBackgroundPattern> change,
}) extends Historic {
  @override
  HistoricBackgroundPatternChange reverse() =>
      .new(pageIndex: pageIndex, change: change.reverse());
}
