import 'dart:async';
import 'dart:convert';

import 'package:badnotes/components/home/cover_designs.dart';
import 'package:badnotes/components/editor_ui/color_panel.dart';
import 'package:badnotes/components/home/notebook_cover.dart';
import 'package:badnotes/components/ui/bn_tool_panels.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:badnotes/data/file_manager/file_manager.dart';
import 'package:badnotes/pages/editor/editor.dart';
import 'package:flutter/material.dart';

/// Whether a file or folder [name] is one of the app's hidden helpers
/// (`.board/`, `.trash/`, `.style.json`…), which the home screen never shows.
bool isHiddenName(String name) {
  final slash = name.lastIndexOf('/');
  return name.substring(slash + 1).startsWith('.');
}

/// [path] (a note or folder) with no hidden part anywhere along it.
bool isVisiblePath(String path) =>
    !path.split('/').any((part) => part.startsWith('.'));

/// A colour standing for a notebook's cover, for the small covers that peek
/// out of folders and the little covers in lists.
Color coverColor(CoverDesign? design) {
  if (design == null) return Colors.white;
  final solid = int.tryParse(design.id, radix: 16);
  if (solid != null) return Color(solid);
  return _designColors[design.id] ?? BnColors.lavender;
}

const _designColors = <String, Color>{
  'd:ocean': Color(0xFF2F6FB0),
  'd:forest': Color(0xFF2E6B4F),
  'd:kraft': Color(0xFFC49A6C),
  'd:linen': Color(0xFFEDE6DA),
  'd:leather': Color(0xFF7A4A2E),
  'd:sunset': Color(0xFFF08A5D),
  'd:aurora': Color(0xFF6BC5B8),
  'd:candy': Color(0xFFF6A6C1),
  'd:mesh': Color(0xFFB9A7F5),
  'd:citrus': Color(0xFFF7C948),
  'd:arches': Color(0xFFE9A07A),
  'd:bloom': Color(0xFFF4D4DC),
  'd:terrazzo': Color(0xFFF1EBE3),
  'd:confetti': Color(0xFFFFF4E0),
  'd:polka': Color(0xFFFDE2E4),
  'd:waves': Color(0xFFBFE0F2),
  'd:memphis': Color(0xFFFFE9A8),
  'd:honey': Color(0xFFF6C453),
  'd:leaves': Color(0xFFDCEFE9),
  'd:graph': Color(0xFFDCEFE9),
  'd:galaxy': Color(0xFF2B2550),
  'd:midnight': Color(0xFF1E2140),
  'd:neon': Color(0xFF1C1C2E),
  'd:marble': Color(0xFF2E2E33),
  'd:peaks': Color(0xFF23314F),
  'd:midgrid': Color(0xFF141A33),
  'd:constellation': Color(0xFF0F1426),
  'd:charterrazzo': Color(0xFF25262B),
  'd:forestnight': Color(0xFF12261F),
  'd:plumwaves': Color(0xFF2A1730),
  'd:inkmarble': Color(0xFF1A1D22),
  'd:tealgeo': Color(0xFF0E2A2E),
  'd:graphdots': Color(0xFF202226),
  'd:nightcity': Color(0xFF141428),
  'd:auroralines': Color(0xFF0F1720),
};

/// What a folder tile shows about what's inside.
class FolderInfo {
  const new({
    required this.notebooks,
    required this.folders,
    required this.peeks,
    required this.modified,
  });

  final int notebooks, folders;

  /// The cover colours of its first notebooks, at most two.
  final List<Color> peeks;
  final DateTime? modified;

  int get items => notebooks + folders;

  String get itemsLabel => items == 1 ? '1 item' : '$items items';

  String get summary => [
    '$notebooks notebook${notebooks == 1 ? '' : 's'}',
    if (folders > 0) '$folders folder${folders == 1 ? '' : 's'}',
  ].join(' · ');
}

/// [FolderInfo] for each folder, read in the background the first time a
/// tile asks, and again (only that folder's) when something in it changes.
abstract final class FolderInfos {
  static final _infos = <String, ValueNotifier<FolderInfo?>>{};
  static StreamSubscription<FileOperation>? _changes;
  static final _stale = <String>{};
  static Timer? _reload;

  /// The info of the folder at [path] (e.g. `/College`); null until read.
  static ValueNotifier<FolderInfo?> of(String path) {
    _listen();
    return _infos.putIfAbsent(path, () {
      final info = ValueNotifier<FolderInfo?>(null);
      unawaited(_load(path, info));
      return info;
    });
  }

  static void _listen() {
    _changes ??= FileManager.fileWriteStream.stream.listen((event) {
      for (final folder in _infos.keys) {
        if (event.filePath.startsWith('$folder/')) _stale.add(folder);
      }
      if (_stale.isEmpty) return;
      _reload?.cancel();
      _reload = Timer(const Duration(milliseconds: 400), () {
        for (final folder in _stale) {
          final info = _infos[folder];
          if (info != null) unawaited(_load(folder, info));
        }
        _stale.clear();
      });
    });
  }

  static Future<void> _load(String path, ValueNotifier<FolderInfo?> info) async {
    final children = await FileManager.getChildrenOfDirectory(
      path,
      sortMetric: .lastModifiedNewToOld,
    );
    if (children == null) return;
    final files = children.files.where((f) => !isHiddenName(f)).toList();
    final folders = children.directories.where((d) => !isHiddenName(d));
    info.value = FolderInfo(
      notebooks: files.length,
      folders: folders.length,
      peeks: [
        for (final file in files.take(2))
          coverColor(NotebookCovers.read('$path/$file')),
      ],
      modified: files.isEmpty
          ? null
          : FileManager.lastModified('$path/${files.first}${Editor.extension}'),
    );
  }

  /// Forgets everything, e.g. after a folder was renamed.
  static void clear() {
    for (final info in _infos.values) {
      info.dispose();
    }
    _infos.clear();
  }
}

/// A folder's colour and icon, kept in `<folder>/.style.json`, so it moves,
/// renames and syncs with the folder.
class FolderStyle {
  const new({this.color = BnFolderColor.lavender, this.custom, this.icon});

  /// The preset; also what older versions show when [custom] is set.
  final BnFolderColor color;

  /// Any colour the user picked (ARGB), in place of [color]'s.
  final int? custom;
  final BnFolderIcon? icon;

  /// What the folder is drawn in.
  BnFolderShades get shades =>
      custom == null ? color : BnCustomFolderColor(Color(custom!));

  /// A preset [color] drops the [custom] colour; a [custom] one keeps the
  /// preset underneath.
  FolderStyle copyWith({
    BnFolderColor? color,
    int? custom,
    BnFolderIcon? icon,
    bool noIcon = false,
  }) => FolderStyle(
    color: color ?? this.color,
    custom: custom ?? (color != null ? null : this.custom),
    icon: noIcon ? null : icon ?? this.icon,
  );

  static FolderStyle fromJson(Map<String, dynamic> json) => FolderStyle(
    color: BnFolderColor.fromKey(json['color'] as String?),
    custom: json['customColor'] as int?,
    icon: BnFolderIcon.fromKey(json['icon'] as String?),
  );

  Map<String, dynamic> toJson() => {
    'color': color.name,
    if (custom != null) 'customColor': custom,
    if (icon != null) 'icon': icon!.key,
  };

  @override
  bool operator ==(Object other) =>
      other is FolderStyle &&
      other.color == color &&
      other.custom == custom &&
      other.icon == icon;

  @override
  int get hashCode => Object.hash(color, custom, icon);
}

/// Each folder's [FolderStyle]: the default at once, the saved one as soon as
/// it's read; saving shows at once and writes in the background.
abstract final class FolderStyles {
  static final _styles = <String, ValueNotifier<FolderStyle>>{};
  static StreamSubscription<FileOperation>? _changes;

  static String _file(String folder) => '$folder/.style.json';

  static ValueNotifier<FolderStyle> of(String folder) {
    _changes ??= FileManager.fileWriteStream.stream.listen((event) {
      // another device changed a folder's style
      if (!event.filePath.endsWith('/.style.json')) return;
      final folder = event.filePath.substring(
        0,
        event.filePath.length - '/.style.json'.length,
      );
      final style = _styles[folder];
      if (style != null) unawaited(_load(folder, style));
    });
    return _styles.putIfAbsent(folder, () {
      final style = ValueNotifier(const FolderStyle());
      unawaited(_load(folder, style));
      return style;
    });
  }

  static Future<void> _load(String folder, ValueNotifier<FolderStyle> style) async {
    if (!FileManager.doesFileExist(_file(folder))) return;
    final bytes = await FileManager.readFile(_file(folder), retries: 0);
    if (bytes == null) return;
    try {
      style.value = FolderStyle.fromJson(
        jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
      );
    } on FormatException {
      // a broken file: keep the default
    }
  }

  static final _pending = <String, Timer>{};

  /// Shows [style] for [folder] at once and saves it a moment later.
  static void save(String folder, FolderStyle style) {
    of(folder).value = style;
    _pending[folder]?.cancel();
    _pending[folder] = Timer(const Duration(milliseconds: 400), () {
      _pending.remove(folder);
      unawaited(
        FileManager.writeFile(
          _file(folder),
          utf8.encode(jsonEncode(style.toJson())),
        ),
      );
    });
  }

  /// A folder was renamed or moved: its style file went with it.
  static void moved(String from, String to) {
    final style = _styles.remove(from);
    if (style != null) _styles[to] = style;
  }
}

/// The "+" at the end of a row of folder colours: any colour, from the full
/// colour panel (presets, grid, wheel).
class FolderColorPlus extends StatelessWidget {
  const new({
    super.key,
    required this.current,
    required this.onChanged,
    this.size = 30,
  });

  /// The folder's custom colour, if it has one.
  final Color? current;
  final ValueChanged<Color> onChanged;
  final double size;

  @override
  Widget build(BuildContext context) => BnAddColorDot(
    size: size,
    tooltip: 'Any color',
    onTap: () {
      final box = context.findRenderObject()! as RenderBox;
      ColorPanel.show(
        context,
        anchor: box.localToGlobal(Offset.zero) & box.size,
        title: 'Folder color',
        color: current,
        onChanged: (color) => onChanged(color.withValues(alpha: 1)),
      );
    },
  );
}
