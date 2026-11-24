import 'dart:math';
import 'dart:ui' as ui;

import 'package:badnotes/components/canvas/_stroke.dart';
import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:badnotes/data/editor/page.dart';

/// Add, pick, hide, lock, rename, reorder and delete the layers of [page].
/// The top of the list is the top of the page. [onChanged] runs after every
/// change, [deleteLayer] has to ask and do the deleting, then return.
/// [pageNumber], when given, shows in the title.
Future<void> showLayersSheet(
  BuildContext context, {
  required EditorPage page,
  required VoidCallback onChanged,
  required Future<void> Function(PageLayer layer) deleteLayer,
  int? pageNumber,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        void change(VoidCallback edit) {
          setState(edit);
          onChanged();
        }

        final colors = BadNotesColors.of(context);
        final count = page.layers.length;
        // every thumbnail shows the same part of the page, so they line up
        final area = _inkArea(page);
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.6,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                mainAxisSize: .min,
                crossAxisAlignment: .stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          pageNumber == null
                              ? 'Layers'
                              : 'Layers · page $pageNumber',
                          style: BnType.title.copyWith(color: colors.text),
                        ),
                      ),
                      BnButton.primary(
                        label: 'Layer',
                        icon: Icons.add,
                        height: 32,
                        onPressed: () => change(page.addLayer),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Top layer is drawn over the others · drag ⠿ to reorder',
                    style: BnType.caption.copyWith(color: colors.muted),
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: ReorderableListView.builder(
                      shrinkWrap: true,
                      buildDefaultDragHandles: false,
                      itemCount: count,
                      onReorder: (from, to) => change(() {
                        // the list is shown top first, and [to] counts the
                        // moved item as still being in its old place
                        if (to > from) to--;
                        page.moveLayer(count - 1 - from, count - 1 - to);
                      }),
                      itemBuilder: (context, i) {
                        final layer = page.layers[count - 1 - i];
                        return ReorderableDelayedDragStartListener(
                          key: ValueKey(layer.id),
                          index: i,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _LayerRow(
                              page: page,
                              layer: layer,
                              index: i,
                              area: area,
                              change: change,
                              onRename: () async {
                                final name = await _askName(
                                  context,
                                  layer.name,
                                );
                                if (name != null && name.isNotEmpty) {
                                  change(() => layer.name = name);
                                }
                              },
                              onDelete: count > 1
                                  ? () async {
                                      await deleteLayer(layer);
                                      if (context.mounted) setState(() {});
                                    }
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}

/// The part of [page] the thumbnails show: the page, or on a board the ink.
Rect _inkArea(EditorPage page) {
  if (!page.isBoard) return Offset.zero & page.size;
  Rect? area;
  for (final stroke in page.strokes) {
    area = area?.expandToInclude(stroke.bounds) ?? stroke.bounds;
  }
  return area ?? Offset.zero & const Size(100, 70);
}

class _LayerRow extends StatelessWidget {
  const new({
    required this.page,
    required this.layer,
    required this.index,
    required this.area,
    required this.change,
    required this.onRename,
    required this.onDelete,
  });

  final EditorPage page;
  final PageLayer layer;
  final int index;
  final Rect area;
  final void Function(VoidCallback edit) change;
  final VoidCallback onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final active = layer.id == page.activeLayer;
    final canDisable = page.canDisableLayer(layer);
    final strokes = [
      for (final stroke in page.strokes)
        if (stroke.layer == layer.id) stroke,
    ];
    final (subtitle, subtitleColor) = !layer.visible
        ? ('hidden', colors.faint)
        : active
        ? ('writing here', colors.accent)
        : ('${strokes.length} ${strokes.length == 1 ? 'stroke' : 'strokes'}',
            colors.muted);
    const radius = BorderRadius.all(Radius.circular(BnRadius.card));
    return Opacity(
      opacity: layer.visible ? 1 : 0.55,
      child: Material(
        color: active ? colors.accentTint : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: active ? colors.accent : colors.hairline,
            width: active ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: layer.editable
              ? () => change(() => page.activeLayer = layer.id)
              : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      Icons.drag_indicator,
                      size: 18,
                      color: colors.handle,
                    ),
                  ),
                ),
                Container(
                  width: 58,
                  height: 42,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(BnRadius.chip),
                    ),
                    border: Border.all(color: colors.hairline),
                  ),
                  child: CustomPaint(
                    painter: _LayerInkPainter(strokes, area),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    mainAxisSize: .min,
                    children: [
                      Text(
                        layer.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BnType.bodyLarge.copyWith(
                          color: colors.text,
                          fontWeight: active ? FontWeight.w600 : null,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: BnType.micro.copyWith(color: subtitleColor),
                      ),
                    ],
                  ),
                ),
                BnIconButton(
                  tooltip: layer.visible ? 'Hide' : 'Show',
                  icon: layer.visible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: layer.visible ? colors.text2 : colors.danger,
                  size: 34,
                  iconSize: 18,
                  onPressed: canDisable
                      ? () => change(() {
                          layer.visible = !layer.visible;
                          page.updateActiveLayer();
                        })
                      : null,
                ),
                BnIconButton(
                  tooltip: layer.locked ? 'Unlock' : 'Lock',
                  icon: layer.locked ? Icons.lock : Icons.lock_open,
                  color: layer.locked ? colors.accent : colors.text2,
                  size: 34,
                  iconSize: 18,
                  onPressed: canDisable
                      ? () => change(() {
                          layer.locked = !layer.locked;
                          page.updateActiveLayer();
                        })
                      : null,
                ),
                Builder(
                  builder: (context) => BnIconButton(
                    tooltip: 'More',
                    icon: Icons.more_horiz,
                    color: colors.text2,
                    size: 34,
                    iconSize: 18,
                    onPressed: () => showAppleMenu(
                      context,
                      anchor: rectOf(context),
                      entries: [
                        AppleMenuItem(
                          'Rename',
                          icon: Icons.edit_outlined,
                          onTap: onRename,
                        ),
                        AppleMenuItem(
                          'Delete',
                          icon: Icons.delete_outline,
                          destructive: true,
                          enabled: onDelete != null,
                          onTap: onDelete,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// [strokes] as plain lines in their colours, [area] of the page fitted in.
class _LayerInkPainter extends CustomPainter {
  _LayerInkPainter(this.strokes, this.area);

  final List<Stroke> strokes;
  final Rect area;

  @override
  void paint(Canvas canvas, Size size) {
    if (strokes.isEmpty || area.isEmpty) return;
    final scale = min(size.width / area.width, size.height / area.height);
    canvas
      ..translate(
        (size.width - area.width * scale) / 2,
        (size.height - area.height * scale) / 2,
      )
      ..scale(scale)
      ..translate(-area.left, -area.top);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final stroke in strokes) {
      // shapes like circles have no points: their outline stands in
      final List<Offset> line = stroke.points.isNotEmpty
          ? stroke.points
          : stroke.lowQualityPolygon;
      if (line.isEmpty) continue;
      paint
        ..color = stroke.color
        ..strokeWidth = max(stroke.options.size, 1.2 / scale);
      canvas.drawPoints(
        line.length == 1 ? ui.PointMode.points : ui.PointMode.polygon,
        line,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_LayerInkPainter old) =>
      old.area != area || !identical(old.strokes, strokes);
}

Future<String?> _askName(BuildContext context, String current) async {
  final controller = TextEditingController(text: current);
  final name = await showAppleDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Layer name'),
      content: TextField(controller: controller, autofocus: true),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('OK'),
        ),
      ],
    ),
  );
  controller.dispose();
  return name;
}
