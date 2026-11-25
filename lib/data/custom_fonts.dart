import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

/// Fonts the user added from .ttf/.otf files. Each is kept in the app's own
/// folder (the folder is the list: nothing else to keep in step) and
/// registered at start-up. A text box stores just the family name, so a
/// removed font falls back to the default one.
abstract final class CustomFonts {
  static final _log = Logger('CustomFonts');

  /// The families added, by name.
  static final families = ValueNotifier<List<String>>(const []);

  static Future<Directory> _folder() async {
    final support = await getApplicationSupportDirectory();
    return Directory('${support.path}/custom_fonts').create(recursive: true);
  }

  static String _familyOf(File f) {
    final name = f.uri.pathSegments.last;
    return name.substring(0, name.lastIndexOf('.'));
  }

  static bool _isFont(String path) {
    final p = path.toLowerCase();
    return p.endsWith('.ttf') || p.endsWith('.otf');
  }

  static Future<void> _register(String family, Uint8List bytes) =>
      (FontLoader(family)..addFont(Future.value(ByteData.sublistView(bytes))))
          .load();

  /// Registers the added fonts; once, at start-up.
  static Future<void> loadAll() async {
    try {
      final files = [
        for (final e in (await _folder()).listSync())
          if (e is File && _isFont(e.path)) e,
      ];
      for (final f in files) {
        await _register(_familyOf(f), await f.readAsBytes());
      }
      families.value = [for (final f in files) _familyOf(f)]..sort();
    } catch (e) {
      _log.warning('Custom fonts not loaded: $e');
    }
  }

  /// Asks for a font file and adds it. Returns its family, or null when none
  /// was chosen; throws [FormatException] when the file isn't a font.
  /// [taken]: bundled family names, which the new one must not shadow.
  static Future<String?> add(Iterable<String> taken) async {
    final picked = await FilePicker.pickFile(type: FileType.any);
    final path = picked?.path;
    if (path == null) return null;
    if (!_isFont(path)) throw const FormatException('Pick a .ttf or .otf file');
    final bytes = await File(path).readAsBytes();
    // TrueType (00 01 00 00, "true") or OpenType ("OTTO")
    final magic = bytes.length < 4
        ? ''
        : String.fromCharCodes(bytes.sublist(0, 4));
    if (!{'\x00\x01\x00\x00', 'true', 'OTTO'}.contains(magic)) {
      throw const FormatException("That file isn't a font");
    }
    final base = File(path).uri.pathSegments.last;
    // safe in an SVG attribute and a file name
    var family = base
        .substring(0, base.lastIndexOf('.'))
        .replaceAll(RegExp(r'[^A-Za-z0-9 _-]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (family.isEmpty) family = 'Custom font';
    if (taken.contains(family)) family = 'My $family';
    final ext = path.substring(path.lastIndexOf('.')).toLowerCase();
    final folder = await _folder();
    for (final e in folder.listSync()) {
      if (e is File && _familyOf(e) == family) await e.delete();
    }
    await File('${folder.path}/$family$ext').writeAsBytes(bytes);
    await _register(family, bytes);
    families.value = {...families.value, family}.toList()..sort();
    return family;
  }

  /// Deletes [family]'s file. It stays usable until the app restarts.
  static Future<void> remove(String family) async {
    try {
      for (final e in (await _folder()).listSync()) {
        if (e is File && _familyOf(e) == family) await e.delete();
      }
    } catch (e) {
      _log.warning('Custom font not removed: $e');
    }
    families.value = [
      for (final f in families.value)
        if (f != family) f,
    ];
  }
}
