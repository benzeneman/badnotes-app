import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:stow_codecs/stow_codecs.dart';

/// Identifies each editor tool.
///
/// Settings store these with [codec] and pen presets store [id], so entries
/// must never be renamed, reordered or removed. The drawing tools are also
/// listed bottom-to-top: the highlighter comes first so it is painted beneath
/// every other pen.
enum ToolId(
  /// The string saved for this tool. Some values are the class names that
  /// older versions saved, which is why their casing is mixed.
  final String id,
) {
  highlighter('Highlighter'),
  fountainPen('fountainPen'),
  ballpointPen('ballpointPen'),
  pencil('Pencil'),
  shapePen('ShapePen'),
  eraser('Eraser'),
  select('Select'),
  textEditing('TextEditingTool'),
  laserPointer('LaserPointer'),
  tape('Tape'),
  calligraphyPen('CalligraphyPen'),
  brushPen('BrushPen');

  /// Saves and loads a [ToolId] in settings.
  static const codec = EnumCodec(values);

  static final _log = Logger('ToolId');

  /// Turns a saved pen identifier back into a [ToolId].
  ///
  /// Older files saved the pen's class name instead of an [id]. The class
  /// name `Pen` meant the fountain pen; every other old name already equals
  /// an [id]. Null gives [fallback]. An unknown string throws in debug builds
  /// and otherwise logs a warning and gives [fallback].
  static ToolId parsePenType(String? penType, {required ToolId fallback}) {
    if (penType == null) return fallback;
    if (penType == 'Pen') return .fountainPen;

    final match = _byId(penType);
    if (match != null) return match;

    if (kDebugMode) {
      throw ArgumentError.value(
        penType,
        'penType',
        'Unknown pen type: `$penType`.',
      );
    }
    _log.warning(
      'Unknown pen type: `$penType`, using fallback `${fallback.id}`.',
    );
    return fallback;
  }

  static ToolId? _byId(String id) {
    for (final tool in values) {
      if (tool.id == id) return tool;
    }
    return null;
  }
}
