import 'package:badnotes/data/pro/pro.dart';
import 'package:badnotes/components/canvas/canvas_background_preview.dart';
import 'package:badnotes/components/canvas/inner_canvas.dart';
import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/toolbar/ink_dial.dart';
import 'package:badnotes/data/editor/editor_core_info.dart';
import 'package:badnotes/data/my_templates.dart';
import 'package:flutter/material.dart';

/// ⋯ › Page › Save as My Template (design N4): a name, whether to keep
/// what's written on the page or only its paper, then Save. Completes with
/// the saved template, or null.
Future<MyTemplate?> showSaveTemplateSheet(
  BuildContext context, {
  required EditorCoreInfo note,
  required int pageIndex,
}) async {
  if (!await Pro.require(context, ProFeature.templates)) return null;
  if (!context.mounted) return null;
  return showModalBottomSheet<MyTemplate>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: InkPalette.of(context).desk,
    builder: (context) => _SaveTemplatePanel(note: note, pageIndex: pageIndex),
  );
}

class _SaveTemplatePanel extends StatefulWidget {
  const new({required this.note, required this.pageIndex});

  final EditorCoreInfo note;
  final int pageIndex;

  @override
  State<_SaveTemplatePanel> createState() => _SaveTemplatePanelState();
}

class _SaveTemplatePanelState extends State<_SaveTemplatePanel> {
  final _name = TextEditingController();
  var _keepContent = true;
  var _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final template = await MyTemplates.save(
      note: widget.note,
      pageIndex: widget.pageIndex,
      name: _name.text,
      keepContent: _keepContent,
    );
    if (mounted) Navigator.pop(context, template);
  }

  // a ListTile, not a RadioListTile: its groupValue is on the way out
  Widget _choice(bool keep, String label) => ListTile(
    contentPadding: EdgeInsets.zero,
    selected: keep == _keepContent,
    leading: Icon(
      keep == _keepContent
          ? Icons.radio_button_checked
          : Icons.radio_button_unchecked,
      color: InkPalette.of(context).accent,
    ),
    title: Text(label, style: TextStyle(color: InkPalette.of(context).text)),
    onTap: () => setState(() => _keepContent = keep),
  );

  @override
  Widget build(BuildContext context) {
    final ink = InkPalette.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .stretch,
            spacing: 8,
            children: [
              Text(
                'Save as template',
                style: TextStyle(
                  color: ink.text,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextField(
                controller: _name,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Weekly planner',
                  filled: true,
                  fillColor: ink.raised,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _saving ? null : _save(),
              ),
              _choice(true, "Keep what's written on it"),
              _choice(false, 'Only the paper (colour and lines)'),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: ink.accent,
                    foregroundColor: ink.onAccent,
                  ),
                  onPressed: _saving ? null : _save,
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The "Mine" row: the user's templates with their pictures, then "＋ From
/// this page" when [note] is given. Tap one to pick it; hold one to rename,
/// delete or make it the default.
class MyTemplatesRail extends StatefulWidget {
  const new({
    super.key,
    required this.selected,
    required this.onPick,
    this.note,
    this.pageIndex,
    this.tileWidth = 72,
    this.onLoaded,
  });

  /// The name of the picked template.
  final String? selected;
  final ValueChanged<MyTemplate?> onPick;

  /// Where "From this page" saves from; null hides it.
  final EditorCoreInfo? note;
  final int? pageIndex;

  final double tileWidth;

  /// Called with the templates each time they're read.
  final ValueChanged<List<MyTemplate>>? onLoaded;

  @override
  State<MyTemplatesRail> createState() => _MyTemplatesRailState();
}

class _MyTemplatesRailState extends State<MyTemplatesRail> {
  var _templates = const <MyTemplate>[];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final templates = await MyTemplates.list();
    if (!mounted) return;
    setState(() => _templates = templates);
    widget.onLoaded?.call(templates);
  }

  Future<void> _fromThisPage() async {
    final saved = await showSaveTemplateSheet(
      context,
      note: widget.note!,
      pageIndex: widget.pageIndex ?? 0,
    );
    if (saved == null) return;
    await _reload();
    widget.onPick(saved);
  }

  Future<void> _rename(MyTemplate template) async {
    final name = TextEditingController(text: template.name);
    final newName = await showAppleDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename template'),
        content: TextField(
          controller: name,
          autofocus: true,
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, name.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    name.dispose();
    if (newName == null || newName.trim() == template.name) return;
    final renamed = await MyTemplates.rename(template, newName);
    if (widget.selected == template.name) widget.onPick(renamed);
    await _reload();
  }

  Future<void> _hold(MyTemplate template) async {
    final ink = InkPalette.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: ink.desk,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: .min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Rename'),
              onTap: () => Navigator.pop(context, 'rename'),
            ),
            ListTile(
              leading: Icon(
                template.isDefault ? Icons.star : Icons.star_outline,
              ),
              title: Text(
                template.isDefault
                    ? 'Stop using for new notebooks'
                    : 'Set as default for new notebooks',
              ),
              onTap: () => Navigator.pop(context, 'default'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case 'rename':
        await _rename(template);
      case 'default':
        await MyTemplates.setDefault(template.isDefault ? null : template);
        await _reload();
      case 'delete':
        await MyTemplates.delete(template);
        if (widget.selected == template.name) widget.onPick(null);
        await _reload();
    }
  }

  Widget _tile({
    required String label,
    required Widget picture,
    required bool chosen,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    bool star = false,
  }) {
    final ink = InkPalette.of(context);
    final width = widget.tileWidth;
    return Semantics(
      button: true,
      selected: chosen,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: SizedBox(
          width: width + 8,
          child: Column(
            spacing: 6,
            children: [
              Stack(
                children: [
                  Container(
                    width: width,
                    height: width * 1.3,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: ink.raised,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: chosen
                            ? ink.accent
                            : ink.muted.withValues(alpha: 0.3),
                        width: chosen ? 2.5 : 1,
                      ),
                    ),
                    child: picture,
                  ),
                  if (star)
                    Positioned(
                      right: 3,
                      top: 3,
                      child: Icon(Icons.star, size: 14, color: ink.accent),
                    ),
                ],
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ink.text,
                  fontSize: 12,
                  fontWeight: chosen ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _picture(MyTemplate template) {
    if (template.thumbnail case final png?) {
      return Image.memory(
        png,
        // decoded at the tile's size, not the thumbnail's full size
        cacheWidth: (widget.tileWidth * MediaQuery.devicePixelRatioOf(context))
            .round(),
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
      );
    }
    final paper = template.paper;
    return FittedBox(
      fit: BoxFit.cover,
      child: CanvasBackgroundPreview(
        selected: false,
        invert: false,
        backgroundColor: paper.color ?? InnerCanvas.defaultBackgroundColor,
        backgroundPattern: paper.pattern ?? .none,
        backgroundImage: null,
        pageSize: paper.size,
        lineHeight: paper.lineHeight ?? 40,
        lineThickness: 3,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ink = InkPalette.of(context);
    final tiles = [
      for (final template in _templates)
        _tile(
          label: template.name,
          picture: _picture(template),
          chosen: template.name == widget.selected,
          star: template.isDefault,
          onTap: () =>
              widget.onPick(template.name == widget.selected ? null : template),
          onLongPress: () => _hold(template),
        ),
      if (widget.note != null)
        _tile(
          label: 'From this page',
          picture: Icon(Icons.add, color: ink.muted),
          chosen: false,
          onTap: _fromThisPage,
        ),
    ];
    if (tiles.isEmpty) {
      return Text(
        'Save a page as a template from ⋯ › Page › Save as My Template.',
        style: TextStyle(color: ink.muted, fontSize: 13),
      );
    }
    return Column(
      crossAxisAlignment: .start,
      mainAxisSize: .min,
      spacing: 6,
      children: [
        SizedBox(
          height: widget.tileWidth * 1.3 + 26,
          child: ListView(
            scrollDirection: .horizontal,
            children: [
              for (final tile in tiles)
                Padding(padding: const EdgeInsets.only(right: 8), child: tile),
            ],
          ),
        ),
        if (_templates.isNotEmpty)
          Text(
            'Hold one: rename · delete · set as default for new notebooks',
            style: TextStyle(color: ink.muted, fontSize: 12),
          ),
      ],
    );
  }
}
