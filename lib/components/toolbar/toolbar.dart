import 'dart:io';

import 'package:collapsible/collapsible.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:badnotes/components/editor_ui/floating_toolbar.dart';
import 'package:badnotes/components/editor_ui/option_previews.dart';
import 'package:badnotes/components/theming/badnotes_theme.dart';
import 'package:badnotes/components/ui/ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:keybinder/keybinder.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:badnotes/components/editor/audio_notes.dart';
import 'package:badnotes/components/editor_ui/editor_ui_colors.dart';
import 'package:badnotes/components/editor_ui/tool_bars.dart';
import 'package:badnotes/components/editor_ui/tool_panel.dart';
import 'package:badnotes/components/theming/apple_ui.dart';
import 'package:badnotes/components/theming/dynamic_material_app.dart';
import 'package:badnotes/components/toolbar/export_bar.dart';
import 'package:badnotes/data/editor/page.dart';
import 'package:badnotes/data/prefs.dart';
import 'package:badnotes/data/tools/_tool.dart';
import 'package:badnotes/data/tools/eraser.dart';
import 'package:badnotes/data/extensions/color_extensions.dart';
import 'package:badnotes/data/tools/highlighter.dart';
import 'package:badnotes/data/tools/laser_pointer.dart';
import 'package:badnotes/data/tools/pen.dart';
import 'package:badnotes/data/tools/pencil.dart';
import 'package:badnotes/data/tools/select.dart';
import 'package:badnotes/data/tools/shape_pen.dart';
import 'package:badnotes/data/tools/tape.dart';
import 'package:badnotes/i18n/strings.g.dart';

/// Which part of the editor's tools a [Toolbar] shows.
enum ToolbarPart {
  /// Everything in one bar (the editor before the floating dock).
  full,

  /// The header across the top: back, pages, the note's title or tabs,
  /// finger drawing, undo, redo, add page, share and More.
  header,

  /// The floating tool dock: the drag handle, the tools and Insert.
  dock,
}

/// A whiteboard's own part of the ⋯ menu, in place of the page's.
typedef BoardMenu = ({
  VoidCallback paper,
  VoidCallback rename,
  VoidCallback duplicate,
  VoidCallback fit,
  VoidCallback delete,
});

/// The editor's controls: its header, its tool dock, or both in one bar
/// (see [part]). It also binds the editor's keyboard shortcuts and holds the
/// export bar and the text formatting bar.
class Toolbar extends StatefulWidget {
  const new({
    super.key,
    required this.readOnly,
    required this.currentTool,
    required this.setTool,
    required this.setColor,
    this.inkInverted,
    required this.undo,
    required this.redo,
    required this.isUndoPossible,
    required this.isRedoPossible,
    required this.textEditing,
    required this.toggleTextEditing,
    required this.quillFocus,
    this.textBoxOpen = false,
    required this.toggleFingerDrawing,
    required this.pickPhoto,
    required this.addStickyNote,
    required this.addSticker,
    required this.addTextBox,
    required this.timerActive,
    required this.toggleTimer,
    required this.magnifierOn,
    required this.toggleMagnifier,
    required this.horizontalScroll,
    required this.setHorizontalScroll,
    this.setTwoPages,
    this.twoPagesOn = false,
    required this.rulerOn,
    required this.toggleRuler,
    required this.toggleTape,
    required this.hasPdf,
    required this.pdfDarkMode,
    required this.setPdfDarkMode,
    required this.jumpToPage,
    required this.pasteFromNote,
    required this.copyToOtherNote,
    required this.changeShape,
    required this.audioNotes,
    required this.toggleRecording,
    required this.clearPage,
    required this.reorderSelection,
    required this.editSelectionText,
    required this.takeScreenshot,
    required this.rotatePage,
    required this.trashPage,
    required this.deleteSpecificItems,
    required this.showLayers,
    required this.startTapeQuiz,
    required this.openShareMenu,
    required this.addBoardKit,
    required this.takePhoto,
    required this.splitOn,
    required this.openSplit,
    required this.showRecordings,
    required this.playFromSelection,
    required this.convertSelectionToText,
    required this.paste,
    required this.duplicateSelection,
    required this.deleteSelection,
    required this.transformSelection,
    required this.exportAsPdf,
    required this.exportAsPng,
    required this.exportAsSba,
    this.pagesOpen = false,
    this.board,
    this.openVersionHistory,
    this.openTags,
    this.saveAsTemplate,
    this.stickyNoteActive = false,
    this.togglePages,
    this.openSearch,
    this.toggleReadingMode,
    this.addPage,
    this.pageBookmarked = false,
    this.toggleBookmark,
    this.duplicatePage,
    this.openNoteSettings,
    this.locked = false,
    this.toggleLock,
    this.pageNumber = 1,
    this.pageCount = 1,
    this.part = ToolbarPart.full,
    this.headerLeading,
    this.headerTitle,
    this.dockAxis = Axis.horizontal,
    this.fingerDrawing = false,
    this.timerChip,
    this.headerUndo,
    this.centerTitle = false,
  });

  /// In the header: undo and redo, before share, when the tools are in the
  /// header's middle.
  final Widget? headerUndo;

  /// In the header: [headerTitle] in the middle (the docked tools or the
  /// page), the buttons either side.

  /// Which part this bar shows.
  final ToolbarPart part;

  /// In the header: before the pages button (back, or close this side).
  final Widget? headerLeading;

  /// In the header: the note's title, or the open notes' tabs.
  final Widget? headerTitle;

  /// In the dock: along which way the tools run.
  final Axis dockAxis;

  /// In the header: whether fingers draw (the hand button is on).
  final bool fingerDrawing;

  /// In the header: the running timer, before the hand button.
  final Widget? timerChip;

  final bool centerTitle;

  /// Whether the sticky note tool is in use.
  final bool stickyNoteActive;

  /// Whether the pages sidebar is open, and opening or closing it.
  final bool pagesOpen;
  final VoidCallback? togglePages;
  final VoidCallback? openSearch;
  final VoidCallback? toggleReadingMode;

  /// Adds a page, from a button at [Rect].
  final ValueChanged<Rect>? addPage;
  final bool pageBookmarked;
  final VoidCallback? toggleBookmark;
  final VoidCallback? duplicatePage;
  final VoidCallback? openNoteSettings;
  final bool locked;

  /// Null when the note can't be locked or unlocked.
  final VoidCallback? toggleLock;

  /// The page in view, from 1, and how many there are.
  final int pageNumber, pageCount;

  /// Whether the note can only be looked at: the tools are hidden.
  final bool readOnly;

  /// Whether ink on the current page is drawn inverted, as decided by
  /// `InnerCanvas.invertsInk`. Colors are shown as they'll be drawn.
  final bool? inkInverted;

  /// Whether a text box is being typed, which has its own font options: the
  /// page's text formatting doesn't apply to it.
  final bool textBoxOpen;

  /// The tool in hand, and choosing another (choosing the one in hand again
  /// may put it down, as with the eraser).
  final Tool currentTool;
  final ValueChanged<Tool> setTool;

  /// Sets the color of the tool in hand.
  final ValueChanged<Color> setColor;

  /// Typing on the page itself: whether it's on, turning it on or off, and
  /// the text field being typed into (which the formatting bar acts on).
  final bool textEditing;
  final VoidCallback toggleTextEditing;
  final ValueNotifier<QuillStruct?> quillFocus;

  /// Undo and redo, and whether there is anything to undo or redo.
  final VoidCallback undo, redo;
  final bool isUndoPossible, isRedoPossible;

  /// Lets fingers draw, or only scroll (also Ctrl+F).
  final VoidCallback toggleFingerDrawing;

  /// Open their panels next to the given button.
  final ValueChanged<Rect> pickPhoto;
  final ValueChanged<Rect> addStickyNote;
  final ValueChanged<Rect> addSticker;
  final VoidCallback addTextBox;
  final bool timerActive;
  final VoidCallback toggleTimer;
  final bool magnifierOn;
  final VoidCallback toggleMagnifier;
  final bool horizontalScroll;
  final ValueChanged<bool> setHorizontalScroll;

  /// Two pages side by side; null where the screen is too narrow.
  final ValueChanged<bool>? setTwoPages;
  final bool twoPagesOn;
  final bool rulerOn;
  final VoidCallback toggleRuler;
  final VoidCallback toggleTape;
  final bool hasPdf;
  final bool pdfDarkMode;
  final ValueChanged<bool> setPdfDarkMode;
  final VoidCallback jumpToPage;
  final VoidCallback pasteFromNote;
  final VoidCallback copyToOtherNote;
  final VoidCallback changeShape;
  final AudioNotes? audioNotes;
  final VoidCallback toggleRecording;
  final VoidCallback clearPage;

  /// Moves the selection to the front (true) or back.
  final ValueChanged<bool> reorderSelection;
  final VoidCallback editSelectionText;
  final VoidCallback takeScreenshot;

  /// Turns the current page; true is clockwise.
  final ValueChanged<bool> rotatePage;
  final VoidCallback trashPage;
  final VoidCallback deleteSpecificItems;
  final VoidCallback showLayers;
  final VoidCallback startTapeQuiz;
  final ValueChanged<Rect> openShareMenu;
  final VoidCallback addBoardKit;
  final VoidCallback takePhoto;
  final bool splitOn;
  final VoidCallback openSplit;
  final VoidCallback showRecordings;
  final VoidCallback playFromSelection;
  final VoidCallback convertSelectionToText;

  /// Pastes from the clipboard (also Ctrl+V).
  final VoidCallback paste;

  /// Acting on what the lasso holds.
  final VoidCallback duplicateSelection, deleteSelection;
  final void Function({double scale, double angle}) transformSelection;

  /// Saving the note as a PDF, as pictures, or as a note file to share, from
  /// the export bar (Ctrl+Shift+S). Null where that export isn't offered.
  final Future Function(BuildContext)? exportAsPdf, exportAsPng, exportAsSba;

  /// Set on a whiteboard: Pages is Boards, Add page is New whiteboard, and
  /// the menu has the board's part.
  final BoardMenu? board;

  /// Opens the note's earlier versions, in More › Settings.
  final VoidCallback? openVersionHistory;

  /// Saves the page as one of my templates, in More › Page.
  final VoidCallback? saveAsTemplate;

  /// The note's tags, in More › Settings.
  final VoidCallback? openTags;

  @override
  State<Toolbar> createState() => _ToolbarState();

  /// Narrower than this, some buttons move into the More menu.
  static const compactWidth = 520.0;

}

class _ToolbarState extends State<Toolbar> {
  /// Whether the export bar is open.
  ValueNotifier<bool> showExportOptions = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    // the header and dock are two bars of one editor: bind keys once
    if (widget.part != ToolbarPart.dock) _assignKeybindings();
    DynamicMaterialApp.addFullscreenListener(_setState);
  }

  void _setState() => setState(() {});

  /// The shortcuts this bar has bound, to unbind when it goes.
  final _shortcuts = <Keybinding>[];

  /// Binds the editor's shortcuts: Ctrl+F for finger drawing, Ctrl+E for the
  /// eraser, Ctrl+Shift+S for the export bar, F11 for fullscreen and Ctrl+V
  /// to paste.
  void _assignKeybindings() {
    KeyCode key(LogicalKeyboardKey logical) => KeyCode.from(logical);
    final shortcuts = <(List<KeyCode>, VoidCallback)>[
      ([KeyCode.ctrl, key(.keyF)], widget.toggleFingerDrawing),
      ([KeyCode.ctrl, key(.keyE)], toggleEraser),
      ([KeyCode.ctrl, KeyCode.shift, key(.keyS)], toggleExportBar),
      ([key(.f11)], toggleFullscreen),
      ([KeyCode.ctrl, key(.keyV)], widget.paste),
    ];
    for (final (keys, action) in shortcuts) {
      final binding = Keybinding(keys, inclusive: true);
      _shortcuts.add(binding);
      Keybinder.bind(binding, action);
    }
  }

  void _removeKeybindings() {
    for (final binding in _shortcuts) {
      Keybinder.remove(binding);
    }
    _shortcuts.clear();
  }

  /// Picks the eraser, or puts it down if it's already in hand.
  void toggleEraser() => widget.setTool(Eraser());

  void toggleExportBar() => showExportOptions.value = !showExportOptions.value;

  void toggleFullscreen() => DynamicMaterialApp.setFullscreen(
    !DynamicMaterialApp.isFullscreen,
    updateSystem: true,
  );

  /// Whether the toolbar is short of room, see [Toolbar.compactWidth].
  var compact = false;

  /// Buttons that go in the More menu when [compact].
  static const _inMoreOnPhones = {
    'laser',
    'stickers',
    'stickyNote',
    'record',
    'accessories',
  };

  bool get isToolbarVerticalNow =>
      stows.editorToolbarAlignment.value == AxisDirection.left ||
      stows.editorToolbarAlignment.value == AxisDirection.right;

  /// The icon of the writing tool the pen button picks.
  static IconData _writingIcon(Pen pen) {
    for (final kind in ToolFloatingBar.penKinds) {
      if (kind.pen == pen) return kind.icon;
    }
    return switch (pen) {
      Highlighter() => Symbols.ink_highlighter,
      Pencil() => Symbols.edit,
      Tape() => Tape.tapeIcon,
      ShapePen() => Symbols.shape_line,
      _ => Symbols.stylus_fountain_pen,
    };
  }

  /// A white button in the navy bar: light when its tool is in use.
  Widget _button(
    String tooltip,
    IconData icon, {
    bool selected = false,
    bool enabled = true,
    required void Function(Rect anchor) onTap,
  }) => Builder(
    builder: (context) => Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
        child: Material(
          color: selected ? EditorUi.of(context).topBarSelected : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          child: InkWell(
            borderRadius: BorderRadius.circular(9),
            onTap: enabled ? () => onTap(rectOf(context)) : null,
            child: SizedBox(
              width: 40,
              height: 34,
              child: Icon(
                icon,
                size: 22,
                weight: 400,
                color: !enabled
                    ? Colors.white38
                    : selected
                    ? EditorUi.of(context).topBarSelectedIcon
                    : EditorUi.of(context).topBarIcon,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => switch (widget.part) {
    ToolbarPart.full => _full(context),
    ToolbarPart.header => _header(context),
    ToolbarPart.dock => _dock(context),
  };

  Widget _full(BuildContext context) {
    final isToolbarVertical = isToolbarVerticalNow;
    // a phone held upright fits the main tools only: the rest go in More
    compact =
        !isToolbarVertical &&
        MediaQuery.sizeOf(context).width < Toolbar.compactWidth;

    final tool = widget.currentTool;
    final writing = ToolFloatingBar.isWritingTool(tool);
    final lastWriting = ToolFloatingBar.lastWritingTool;
    final canEdit = !widget.readOnly;

    final tools = <String, Widget>{
      'lasso': _button(
        t.editor.toolbar.select,
        Symbols.lasso_select,
        selected: tool is Select,
        enabled: canEdit,
        onTap: (_) => widget.setTool(Select.currentSelect),
      ),
      'pen': _button(
        'Pen',
        _writingIcon(writing ? tool as Pen : lastWriting),
        selected: writing,
        enabled: canEdit,
        onTap: (_) {
          if (writing) return;
          if (lastWriting is ShapePen) ShapePen.kind = ShapeKind.auto;
          widget.setTool(lastWriting);
        },
      ),
      'laser': _button(
        t.editor.pens.laserPointer,
        Symbols.stylus_laser_pointer,
        selected: tool is LaserPointer,
        onTap: (_) => widget.setTool(LaserPointer.currentLaserPointer),
      ),
      'shapes': _button(
        t.editor.pens.shapePen,
        Symbols.shapes,
        selected: tool is ShapePen && ShapePen.kind != ShapeKind.auto,
        enabled: canEdit,
        onTap: (_) {
          ShapePen.kind = ToolFloatingBar.lastShapeKind;
          widget.setTool(ShapePen.currentShapePen);
        },
      ),
      'eraser': _button(
        t.editor.toolbar.toggleEraser,
        Symbols.ink_eraser,
        selected: tool is Eraser,
        enabled: canEdit,
        onTap: (_) => toggleEraser(),
      ),
      'image': _button(
        t.editor.toolbar.photo,
        Symbols.image,
        enabled: canEdit,
        onTap: widget.pickPhoto,
      ),
      'stickers': _button(
        'Stickers',
        Symbols.add_reaction,
        enabled: canEdit,
        onTap: widget.addSticker,
      ),
      'stickyNote': _button(
        'Sticky note',
        Symbols.sticky_note_2,
        selected: widget.stickyNoteActive,
        enabled: canEdit,
        onTap: widget.addStickyNote,
      ),
      // Typing on the page, on and off.
      'textBox': _button(
        widget.textEditing ? 'Stop typing' : 'Text',
        Symbols.text_fields,
        selected: widget.textEditing,
        enabled: canEdit,
        onTap: (_) {
          if (widget.textEditing) {
            widget.toggleTextEditing();
          } else {
            widget.addTextBox();
          }
        },
      ),
      if (widget.audioNotes != null)
        'record': ListenableBuilder(
          listenable: widget.audioNotes!,
          builder: (context, _) {
            final recording = widget.audioNotes!.isRecording;
            return _button(
              recording ? 'Stop recording' : 'Record audio',
              recording ? Symbols.stop_circle : Symbols.mic,
              selected: recording,
              enabled: canEdit,
              onTap: (_) => widget.toggleRecording(),
            );
          },
        ),
      'accessories': _button(
        'Accessories',
        Symbols.widgets,
        selected:
            widget.magnifierOn || widget.rulerOn || widget.timerActive,
        onTap: _openAccessories,
      ),
    };

    final bars = <Widget>[
      ..._extraBars(context, isToolbarVertical),
      ColoredBox(
        color: EditorUi.of(context).topBar,
        child: isToolbarVertical
            ? SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
                child: Column(
                  mainAxisSize: .min,
                  children: [
                    ..._leftButtons(),
                    for (final id in _toolOrder())
                      if (tools[id] != null) tools[id]!,
                    ..._rightButtons(),
                  ],
                ),
              )
            : Row(
                children: [
                  const SizedBox(width: 4),
                  ..._leftButtons(),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        child: Row(
                          mainAxisSize: .min,
                          children: [
                            for (final id in _toolOrder())
                              if (tools[id] != null &&
                                  !(compact && _inMoreOnPhones.contains(id)))
                                tools[id]!,
                          ],
                        ),
                      ),
                    ),
                  ),
                  ..._rightButtons(),
                  const SizedBox(width: 4),
                ],
              ),
      ),
    ];

    return Flex(
      direction: isToolbarVertical ? Axis.horizontal : Axis.vertical,
      textDirection: switch (stows.editorToolbarAlignment.value) {
        AxisDirection.left => .rtl,
        AxisDirection.right => .ltr,
        _ => null,
      },
      verticalDirection: switch (stows.editorToolbarAlignment.value) {
        AxisDirection.down => VerticalDirection.down,
        AxisDirection.up => VerticalDirection.up,
        _ => VerticalDirection.down,
      },
      children: bars,
    );
  }

  /// Pages, search and reading mode, at the left of the bar.
  List<Widget> _leftButtons() => [
    if (widget.togglePages != null)
      _button(
        widget.board != null ? 'Whiteboards' : 'Pages',
        Symbols.view_sidebar,
        selected: widget.pagesOpen,
        onTap: (_) => widget.togglePages!(),
      ),
    if (!compact && widget.openSearch != null)
      _button('Search', Symbols.search, onTap: (_) => widget.openSearch!()),
    if (!compact && widget.toggleReadingMode != null)
      _button(
        'Reading mode',
        Symbols.menu_book,
        onTap: (_) => widget.toggleReadingMode!(),
      ),
  ];

  /// Add page, share and More, at the right of the bar.
  List<Widget> _rightButtons() => [
    if (!compact && widget.addPage != null)
      _button(
        widget.board != null ? 'New whiteboard' : 'Add page',
        Symbols.note_add,
        enabled: !widget.readOnly,
        onTap: widget.addPage!,
      ),
    if (!compact)
      _button(
        'Share and export',
        Symbols.ios_share,
        onTap: widget.openShareMenu,
      ),
    _button('More', Symbols.more_horiz, onTap: _openMore),
  ];

  /// Vertical or horizontal, with the pages going by that way.
  PanelPage _scrollingPage() {
    var horizontal = widget.horizontalScroll;
    return PanelPage(
      title: 'Scrolling Direction',
      width: 300,
      builder: (context, setState) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ScrollPreview(horizontal: horizontal),
          const SizedBox(height: 10),
          PanelChoiceCards<bool>(
            gap: 8,
            choices: const [
              (value: false, icon: Icon(Icons.swap_vert), label: 'Vertical'),
              (value: true, icon: Icon(Icons.swap_horiz), label: 'Horizontal'),
            ],
            value: horizontal,
            onChanged: (v) {
              setState(() => horizontal = v);
              widget.setHorizontalScroll(v);
            },
          ),
        ],
      ),
    );
  }

  /// Show Recordings, Zoom Window, Ruler and Time Keeper, then Toolbar
  /// Customization.
  void _openAccessories(Rect anchor) => showToolPanel(
    context,
    anchor: anchor,
    page: PanelPage(
      title: 'Accessories',
      width: 300,
      builder: (context, _) {
        void run(VoidCallback action) {
          Navigator.pop(context);
          action();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PanelGroup(
              children: [
                if (widget.audioNotes != null)
                  PanelNavRow(
                    icon: Icons.graphic_eq,
                    title: 'Show Recordings',
                    chevron: false,
                    onTap: () => run(widget.showRecordings),
                  ),
                PanelNavRow(
                  icon: Icons.zoom_in,
                  title: 'Zoom Window',
                  chevron: false,
                  checked: widget.magnifierOn,
                  onTap: () => run(widget.toggleMagnifier),
                ),
                PanelNavRow(
                  icon: Icons.straighten,
                  title: 'Ruler',
                  chevron: false,
                  checked: widget.rulerOn,
                  onTap: () => run(widget.toggleRuler),
                ),
                PanelNavRow(
                  icon: Icons.timer_outlined,
                  title: 'Time Keeper',
                  chevron: false,
                  checked: widget.timerActive,
                  onTap: () => run(widget.toggleTimer),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PanelGroup(
              children: [
                PanelNavRow(
                  title: 'Toolbar Customization',
                  chevron: false,
                  onTap: () => run(_showToolbarCustomizer),
                ),
              ],
            ),
          ],
        );
      },
    ),
  );

  /// The page's actions and the note's settings, as in the reference's More.
  void _openMore(Rect anchor) {
    final canEdit = !widget.readOnly;
    showToolPanel(
      context,
      anchor: anchor,
      page: PanelPage(
        title: 'More',
        width: 340,
        builder: (context, setPanel) {
          void run(VoidCallback? action) {
            Navigator.pop(context);
            action?.call();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (compact) ...[
                PanelGroup(
                  children: [
                    if (widget.openSearch != null)
                      PanelNavRow(
                        icon: Icons.search,
                        title: 'Search',
                        chevron: false,
                        onTap: () => run(widget.openSearch),
                      ),
                    PanelNavRow(
                      icon: Icons.ios_share,
                      title: 'Share and Export',
                      chevron: false,
                      onTap: () {
                        Navigator.pop(context);
                        widget.openShareMenu(anchor);
                      },
                    ),
                    if (widget.addPage != null)
                      PanelNavRow(
                        icon: Icons.note_add_outlined,
                        title: widget.board != null
                            ? 'New Whiteboard'
                            : 'Add Page',
                        chevron: false,
                        enabled: canEdit,
                        onTap: () {
                          Navigator.pop(context);
                          widget.addPage!(anchor);
                        },
                      ),
                    PanelNavRow(
                      icon: Symbols.stylus_laser_pointer,
                      title: t.editor.pens.laserPointer,
                      chevron: false,
                      checked: widget.currentTool is LaserPointer,
                      onTap: () => run(
                        () => widget.setTool(LaserPointer.currentLaserPointer),
                      ),
                    ),
                    PanelNavRow(
                      icon: Icons.add_reaction_outlined,
                      title: 'Stickers',
                      chevron: false,
                      enabled: canEdit,
                      onTap: () {
                        Navigator.pop(context);
                        widget.addSticker(anchor);
                      },
                    ),
                    PanelNavRow(
                      icon: Icons.sticky_note_2_outlined,
                      title: 'Sticky Note',
                      chevron: false,
                      enabled: canEdit,
                      onTap: () {
                        Navigator.pop(context);
                        widget.addStickyNote(anchor);
                      },
                    ),
                    if (widget.audioNotes != null)
                      PanelNavRow(
                        icon: Icons.mic_none,
                        title: (widget.audioNotes?.isRecording ?? false)
                            ? 'Stop Recording'
                            : 'Record Audio',
                        chevron: false,
                        enabled: canEdit,
                        onTap: () => run(widget.toggleRecording),
                      ),
                    PanelNavRow(
                      icon: Icons.widgets_outlined,
                      title: 'Accessories',
                      onTap: () {
                        Navigator.pop(context);
                        _openAccessories(anchor);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              if (widget.board case final board?) ...[
                const PanelSection('Board'),
                PanelGroup(
                  children: [
                    PanelNavRow(
                      icon: Icons.texture,
                      title: 'Paper and Colour',
                      chevron: false,
                      enabled: canEdit,
                      onTap: () => run(board.paper),
                    ),
                    PanelNavRow(
                      icon: Icons.drive_file_rename_outline,
                      title: 'Rename',
                      chevron: false,
                      enabled: canEdit,
                      onTap: () => run(board.rename),
                    ),
                    PanelNavRow(
                      icon: Icons.copy_outlined,
                      title: 'Duplicate Board',
                      chevron: false,
                      onTap: () => run(board.duplicate),
                    ),
                    PanelNavRow(
                      icon: Icons.fit_screen_outlined,
                      title: 'Show Everything',
                      chevron: false,
                      onTap: () => run(board.fit),
                    ),
                  ],
                ),
                const PanelSection('Clear or Delete'),
                PanelGroup(
                  children: [
                    PanelNavRow(
                      icon: Icons.checklist,
                      title: 'Delete Specific Items',
                      enabled: canEdit,
                      onTap: () => run(widget.deleteSpecificItems),
                    ),
                    PanelNavRow(
                      icon: Icons.delete_sweep_outlined,
                      title: 'Clear Board',
                      destructive: true,
                      enabled: canEdit,
                      onTap: () => run(widget.clearPage),
                    ),
                    PanelNavRow(
                      icon: Icons.delete_outline,
                      title: 'Delete Board',
                      destructive: true,
                      onTap: () => run(board.delete),
                    ),
                  ],
                ),
              ] else ...[
                PanelSection('Page ${widget.pageNumber}'),
                PanelGroup(
                  children: [
                    if (widget.toggleBookmark != null)
                      PanelSwitchRow(
                        icon: Icons.bookmark_border,
                        title: 'Add to Favorites',
                        value: widget.pageBookmarked,
                        onChanged: (_) => run(widget.toggleBookmark),
                      ),
                    if (widget.duplicatePage != null)
                      PanelNavRow(
                        icon: Icons.copy_outlined,
                        title: 'Copy Page',
                        chevron: false,
                        enabled: canEdit,
                        onTap: () => run(widget.duplicatePage),
                      ),
                    PanelNavRow(
                      icon: Icons.rotate_right,
                      title: 'Rotate Page',
                      enabled: canEdit,
                      onTap: () => ToolPanel.push(
                        context,
                        PanelPage(
                          title: 'Rotate Page',
                          // its own context: the first page's is gone by now
                          builder: (context, _) => PanelGroup(
                            children: [
                              PanelNavRow(
                                icon: Icons.rotate_right,
                                title: 'Clockwise',
                                chevron: false,
                                onTap: () {
                                  Navigator.pop(context);
                                  widget.rotatePage(true);
                                },
                              ),
                              PanelNavRow(
                                icon: Icons.rotate_left,
                                title: 'Anticlockwise',
                                chevron: false,
                                onTap: () {
                                  Navigator.pop(context);
                                  widget.rotatePage(false);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (widget.saveAsTemplate != null)
                      PanelNavRow(
                        icon: Icons.bookmark_add_outlined,
                        title: 'Save as My Template',
                        chevron: false,
                        enabled: canEdit,
                        onTap: () => run(widget.saveAsTemplate),
                      ),
                    if (widget.openNoteSettings != null)
                      PanelNavRow(
                        icon: Icons.texture,
                        title: 'Change Template',
                        chevron: false,
                        enabled: canEdit,
                        onTap: () => run(widget.openNoteSettings),
                      ),
                    PanelNavRow(
                      icon: Icons.input,
                      title: 'Go to Page',
                      trailing: '(1–${widget.pageCount})',
                      chevron: false,
                      onTap: () => run(widget.jumpToPage),
                    ),
                  ],
                ),
                const PanelSection('Clear or Trash Page'),
                PanelGroup(
                  children: [
                    PanelNavRow(
                      icon: Icons.checklist,
                      title: 'Delete Specific Items',
                      enabled: canEdit,
                      onTap: () => run(widget.deleteSpecificItems),
                    ),
                    PanelNavRow(
                      icon: Icons.delete_sweep_outlined,
                      title: 'Clear Page',
                      destructive: true,
                      enabled: canEdit,
                      onTap: () => run(widget.clearPage),
                    ),
                    PanelNavRow(
                      icon: Icons.delete_outline,
                      title: 'Move Page to Trash',
                      destructive: true,
                      enabled: canEdit,
                      onTap: () => run(widget.trashPage),
                    ),
                  ],
                ),
              ],
              const PanelSection('Settings'),
              PanelGroup(
                children: [
                  if (widget.openTags != null)
                    PanelNavRow(
                      icon: Icons.sell_outlined,
                      title: 'Tags',
                      onTap: () => run(widget.openTags),
                    ),
                  if (widget.openVersionHistory != null)
                    PanelNavRow(
                      icon: Icons.history,
                      title: 'Version History',
                      onTap: () => run(widget.openVersionHistory),
                    ),
                  PanelNavRow(
                    icon: DynamicMaterialApp.isFullscreen
                        ? Icons.fullscreen_exit
                        : Icons.fullscreen,
                    title: DynamicMaterialApp.isFullscreen
                        ? 'Leave Full Screen'
                        : 'Full Screen',
                    chevron: false,
                    checked: DynamicMaterialApp.isFullscreen,
                    onTap: () => run(toggleFullscreen),
                  ),
                  if (widget.toggleLock != null)
                    PanelNavRow(
                      icon: widget.locked ? Icons.lock_open : Icons.lock_outline,
                      title: widget.locked ? 'Remove Lock' : 'Add Lock',
                      chevron: false,
                      onTap: () => run(widget.toggleLock),
                    ),
                  PanelNavRow(
                    icon: Icons.swap_vert,
                    title: 'Scrolling Direction',
                    trailing: widget.horizontalScroll ? 'Horizontal' : 'Vertical',
                    onTap: () => ToolPanel.push(context, _scrollingPage()),
                  ),
                ],
              ),
              const PanelSection('More Tools'),
              PanelGroup(
                children: [
                  PanelNavRow(
                    icon: Icons.layers_outlined,
                    title: 'Layers',
                    chevron: false,
                    enabled: canEdit,
                    onTap: () => run(widget.showLayers),
                  ),
                  PanelNavRow(
                    icon: Icons.vertical_split_outlined,
                    title: 'Split View',
                    checked: widget.splitOn,
                    chevron: false,
                    onTap: () => run(widget.openSplit),
                  ),
                  PanelNavRow(
                    icon: Icons.quiz_outlined,
                    title: 'Tape Quiz',
                    chevron: false,
                    onTap: () => run(widget.startTapeQuiz),
                  ),
                  PanelNavRow(
                    icon: Icons.dashboard_customize_outlined,
                    title: 'Ready-made Layouts',
                    chevron: false,
                    enabled: canEdit,
                    onTap: () => run(widget.addBoardKit),
                  ),
                  if (widget.hasPdf)
                    PanelNavRow(
                      icon: widget.pdfDarkMode ? Icons.light_mode : Icons.dark_mode,
                      title: widget.pdfDarkMode ? 'PDF Light Mode' : 'PDF Dark Mode',
                      chevron: false,
                      onTap: () =>
                          run(() => widget.setPdfDarkMode(!widget.pdfDarkMode)),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  /// The toolbar's buttons, in their default order.


  /// The formatting bar's buttons in the editor's top bar colors: clear when
  /// off, the selected color when on.
  QuillIconTheme _formattingIconTheme(BuildContext context) {
    final colors = EditorUi.of(context);
    final base = IconButtonTheme.of(context).style ?? const ButtonStyle();
    IconButtonData look(Color background, Color foreground) => IconButtonData(
      style: base.copyWith(
        backgroundColor: WidgetStateProperty.all(background),
        foregroundColor: WidgetStateProperty.all(foreground),
      ),
    );
    return QuillIconTheme(
      iconButtonUnselectedData: look(Colors.transparent, colors.topBarIcon),
      iconButtonSelectedData: look(
        colors.topBarSelected,
        colors.topBarSelectedIcon,
      ),
    );
  }

  /// The export options and the page text's formatting, when they're open.
  List<Widget> _extraBars(BuildContext context, bool isToolbarVertical) => [
      ValueListenableBuilder(
        valueListenable: showExportOptions,
        // the bar stays built while closed, so it opens without a hitch
        builder: (context, open, bar) => Collapsible(
          axis: isToolbarVertical
              ? CollapsibleAxis.horizontal
              : CollapsibleAxis.vertical,
          maintainState: true,
          collapsed: !open,
          child: bar!,
        ),
        child: ExportBar(
          exportAsPdf: widget.exportAsPdf,
          exportAsPng: widget.exportAsPng,
          exportAsSba: widget.exportAsSba,
          toggleExportBar: toggleExportBar,
          axis: isToolbarVertical ? Axis.vertical : Axis.horizontal,
        ),
      ),
      ValueListenableBuilder(
        valueListenable: widget.quillFocus,
        builder: (context, quill, _) => ListenableBuilder(
          listenable: quill?.focusNode ?? const _NoListenable(),
          builder: (context, _) {
          final colors = EditorUi.of(context);
          return Collapsible(
            axis: isToolbarVertical
                ? CollapsibleAxis.horizontal
                : CollapsibleAxis.vertical,
            maintainState: false,
            // only while typing into the page's own text: text boxes have
            // their own bar
            collapsed:
                !widget.textEditing ||
                widget.textBoxOpen ||
                quill == null ||
                !quill.focusNode.hasFocus,
            child: quill != null
                ? QuillSimpleToolbar(
                    controller: quill.controller,
                    config: QuillSimpleToolbarConfig(
                      // undo is the editor's own; fonts are the app's
                      showUndo: false,
                      showRedo: false,
                      showFontFamily: false,
                      showFontSize: false,
                      showClearFormat: false,
                      // one scrolling row on phones, wrapped rows elsewhere
                      multiRowsDisplay: !Platform.isAndroid && !Platform.isIOS,
                      axis: isToolbarVertical ? Axis.vertical : Axis.horizontal,
                      color: colors.topBar,
                      buttonOptions: QuillSimpleToolbarButtonOptions(
                        base: QuillToolbarBaseButtonOptions(
                          iconTheme: _formattingIconTheme(context),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          );
          },
        ),
      ),
  ];

  // ---- the header and the tool dock (design M_Editor) ----

  /// The tools of the dock, by id, in the design's order.
  static const dockTools = [
    'lasso',
    'pen',
    'highlighter',
    'pencil',
    'eraser',
    'drawShapes',
    'tape',
    'shapes',
    'laser',
    'record',
    'textBox',
    'image',
  ];

  /// What can be added to the dock from "More tools".
  static const moreTools = [
    'ruler',
    'zoom',
    'timer',
    'stickyNote',
    'stickers',
  ];

  static const dockLabels = <String, String>{
    'lasso': 'Lasso',
    'pen': 'Pen',
    'highlighter': 'Highlighter',
    'pencil': 'Pencil',
    'drawShapes': 'Draw shapes',
    'tape': 'Tape',
    'shapes': 'Shapes',
    'eraser': 'Eraser',
    'laser': 'Laser',
    'ruler': 'Ruler',
    'zoom': 'Zoom window',
    'record': 'Record',
    'timer': 'Timer',
    'textBox': 'Text',
    'stickyNote': 'Sticky note',
    'image': 'Photo',
    'stickers': 'Sticker',
  };

  /// The tools in the dock now, in order: the saved order with the hidden
  /// ones left out. Until the toolbar is customized, the dock has the
  /// design's tools and the rest are in "More tools".
  static List<String> dockOrder() {
    final hidden = stows.toolbarHidden.value;
    // a customized toolbar keeps a marker, so "nothing hidden" stays itself
    final customized = hidden.isNotEmpty;
    final known = {...dockTools, ...moreTools};
    final saved = [
      for (final id in stows.toolbarOrder.value)
        if (known.contains(id)) id,
    ];
    final order = [
      ...saved,
      for (final id in [...dockTools, ...moreTools])
        if (!saved.contains(id)) id,
    ];
    return [
      for (final id in order)
        if (customized ? !hidden.contains(id) : dockTools.contains(id)) id,
    ];
  }

  /// The pen the Pen button picks: the last of the pens used.
  static Pen _lastPen = Pen.currentPen;

  static bool _isPlainPen(Tool tool) =>
      tool is Pen &&
      tool is! Highlighter &&
      tool is! Pencil &&
      tool is! Tape &&
      tool is! ShapePen;

  Widget _dockButton(
    String id, {
    required bool selected,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final path = switch (id) {
      'lasso' => BnToolIcons.lasso,
      'pen' => switch (_lastPen.toolId) {
        .ballpointPen => BnToolIcons.ballpoint,
        .brushPen => BnToolIcons.brush,
        .calligraphyPen => BnToolIcons.calligraphy,
        _ => BnToolIcons.fountain,
      },
      'highlighter' => BnToolIcons.highlighter,
      'pencil' => BnToolIcons.pencil,
      'drawShapes' => BnToolIcons.drawShapes,
      'tape' => BnToolIcons.tape,
      'shapes' => BnToolIcons.shapes,
      'eraser' => BnToolIcons.eraser,
      'laser' => BnToolIcons.laser,
      _ => null,
    };
    final icon = switch (id) {
      'ruler' => BnIcons.ruler,
      'zoom' => BnIcons.zoomWindow,
      'record' => BnIcons.mic,
      'timer' => BnIcons.timer,
      'textBox' => BnIcons.text,
      'stickyNote' => BnIcons.sticky,
      'image' => BnIcons.photo,
      'stickers' => BnIcons.sticker,
      _ => null,
    };
    final compact = stows.toolbarCompact.value;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: BnToolButton(
        label: dockLabels[id] ?? id,
        path: path,
        icon: icon,
        dashed: id == 'lasso',
        selected: selected,
        size: compact ? 36 : 42,
        // the pens show their ink, as it's drawn on this page
        inkColor: switch (id) {
          'pen' => _lastPen.color,
          'highlighter' => Highlighter.currentHighlighter.color.withAlpha(255),
          'pencil' => Pencil.currentPencil.color,
          _ => null,
        }?.withInversion(widget.inkInverted ?? false),
        centerDot: id == 'laser' ? const Color(0xFFF14B4B) : null,
        onTap: enabled ? onTap : null,
      ),
    );
  }

  Widget _dock(BuildContext context) {
    final tool = widget.currentTool;
    final canEdit = !widget.readOnly;
    if (_isPlainPen(tool)) _lastPen = tool as Pen;
    final writingShape = tool is ShapePen && ShapePen.kind == ShapeKind.auto;
    final vertical = widget.dockAxis == Axis.vertical;

    Widget? item(String id) => switch (id) {
      'lasso' => _dockButton(
        id,
        selected: tool is Select,
        enabled: canEdit,
        onTap: () => widget.setTool(Select.currentSelect),
      ),
      'pen' => _dockButton(
        id,
        selected: _isPlainPen(tool),
        enabled: canEdit,
        onTap: () {
          if (!_isPlainPen(tool)) widget.setTool(_lastPen);
        },
      ),
      'highlighter' => _dockButton(
        id,
        selected: tool is Highlighter,
        enabled: canEdit,
        onTap: () => widget.setTool(Highlighter.currentHighlighter),
      ),
      'pencil' => _dockButton(
        id,
        selected: tool is Pencil,
        enabled: canEdit,
        onTap: () => widget.setTool(Pencil.currentPencil),
      ),
      'drawShapes' => _dockButton(
        id,
        selected: writingShape,
        enabled: canEdit,
        onTap: () {
          ShapePen.kind = ShapeKind.auto;
          widget.setTool(ShapePen.currentShapePen);
        },
      ),
      'tape' => _dockButton(
        id,
        selected: tool is Tape,
        enabled: canEdit,
        onTap: () {
          if (tool is! Tape) widget.setTool(Tape.currentTape);
        },
      ),
      'shapes' => _dockButton(
        id,
        selected: tool is ShapePen && !writingShape,
        enabled: canEdit,
        onTap: () {
          ShapePen.kind = ToolFloatingBar.lastShapeKind;
          widget.setTool(ShapePen.currentShapePen);
        },
      ),
      'eraser' => _dockButton(
        id,
        selected: tool is Eraser,
        enabled: canEdit,
        onTap: toggleEraser,
      ),
      'laser' => _dockButton(
        id,
        selected: tool is LaserPointer,
        onTap: () => widget.setTool(LaserPointer.currentLaserPointer),
      ),
      'ruler' => _dockButton(
        id,
        selected: widget.rulerOn,
        onTap: widget.toggleRuler,
      ),
      'zoom' => _dockButton(
        id,
        selected: widget.magnifierOn,
        onTap: widget.toggleMagnifier,
      ),
      'record' when widget.audioNotes != null => _dockButton(
        id,
        selected: widget.audioNotes!.isRecording,
        enabled: canEdit,
        onTap: widget.toggleRecording,
      ),
      'timer' => _dockButton(
        id,
        selected: widget.timerActive,
        onTap: widget.toggleTimer,
      ),
      'textBox' => _dockButton(
        id,
        selected: widget.textEditing,
        enabled: canEdit,
        onTap: () => widget.textEditing
            ? widget.toggleTextEditing()
            : widget.addTextBox(),
      ),
      'stickyNote' => Builder(
        builder: (context) => _dockButton(
          id,
          selected: widget.stickyNoteActive,
          enabled: canEdit,
          onTap: () => widget.addStickyNote(rectOf(context)),
        ),
      ),
      'image' => Builder(
        builder: (context) => _dockButton(
          id,
          selected: false,
          enabled: canEdit,
          onTap: () => widget.pickPhoto(rectOf(context)),
        ),
      ),
      'stickers' => Builder(
        builder: (context) => _dockButton(
          id,
          selected: false,
          enabled: canEdit,
          onTap: () => widget.addSticker(rectOf(context)),
        ),
      ),
      _ => null,
    };

    return ListenableBuilder(
      // customizing changes the dock live
      listenable: Listenable.merge([
        stows.toolbarHidden,
        stows.toolbarOrder,
        stows.toolbarCompact,
      ]),
      builder: (context, _) => Flex(
        direction: widget.dockAxis,
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          FloatingToolbar.handle(context, vertical: vertical),
          for (final id in dockOrder()) ?item(id),
          BnBarDivider(height: 22, vertical: vertical),
          Builder(
            builder: (context) => BnToolButton(
              label: 'Insert',
              icon: BnIcons.insert,
              filled: true,
              size: stows.toolbarCompact.value ? 36 : 42,
              onTap: () => _openInsert(context, rectOf(context)),
            ),
          ),
        ],
      ),
    );
  }

  /// Everything that adds something to the page (design T11), so the dock
  /// stays short.
  void _openInsert(BuildContext anchorContext, Rect anchor) {
    final canEdit = !widget.readOnly;
    showToolPanel(
      context,
      anchor: anchor,
      page: PanelPage(
        title: 'Insert',
        width: 392,
        builder: (context, _) {
          void run(VoidCallback action) {
            Navigator.pop(context);
            action();
          }

          Widget tile(String label, IconData icon, Color color, VoidCallback onTap) =>
              _InsertTile(
                label: label,
                icon: icon,
                color: color,
                onTap: canEdit ? () => run(onTap) : null,
              );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.4,
                children: [
                  tile('Photo', BnIcons.photo, BnColors.sky,
                      () => widget.pickPhoto(anchor)),
                  tile('Camera', LucideIcons.camera, BnColors.lavender,
                      widget.takePhoto),
                  tile('Sticker', BnIcons.sticker, BnColors.blush,
                      () => widget.addSticker(anchor)),
                  tile('Sticky note', BnIcons.sticky, BnColors.noteButter,
                      () => widget.addStickyNote(anchor)),
                  tile('Text box', BnIcons.text, const Color(0xFFEEF5E1),
                      widget.addTextBox),
                  // recording is the 🎙 tool; this opens what was recorded
                  if (widget.audioNotes != null)
                    _InsertTile(
                      label: 'Recordings',
                      icon: Icons.graphic_eq,
                      color: BnColors.mint,
                      onTap: () => run(widget.showRecordings),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              PanelGroup(
                children: [
                  PanelNavRow(
                    icon: Icons.straighten,
                    title: 'Ruler',
                    chevron: false,
                    checked: widget.rulerOn,
                    onTap: () => run(widget.toggleRuler),
                  ),
                  PanelNavRow(
                    icon: Icons.zoom_in,
                    title: 'Zoom window',
                    chevron: false,
                    checked: widget.magnifierOn,
                    onTap: () => run(widget.toggleMagnifier),
                  ),
                  PanelNavRow(
                    icon: Icons.timer_outlined,
                    title: 'Timer & stopwatch',
                    chevron: false,
                    checked: widget.timerActive,
                    onTap: () => run(widget.toggleTimer),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              PanelGroup(
                children: [
                  PanelNavRow(
                    icon: Icons.tune,
                    title: 'Customize toolbar',
                    onTap: () => run(_showToolbarCustomizer),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  /// A 38 px header button: tinted when [selected].
  Widget _headerButton(
    String tooltip,
    IconData icon, {
    bool selected = false,
    bool enabled = true,
    required void Function(Rect anchor) onTap,
  }) => Builder(
    builder: (context) => BnIconButton(
      icon: icon,
      tooltip: tooltip,
      selected: selected,
      onPressed: enabled ? () => onTap(rectOf(context)) : null,
    ),
  );

  Widget _header(BuildContext context) {
    final phone = MediaQuery.sizeOf(context).width < Toolbar.compactWidth;
    compact = phone;
    final row = SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        // the middle (the tools, or the page) centred on the whole bar,
        // not on the room between the buttons: they're wider on the left,
        // and the tools sat right of the screen's middle
        child: NavigationToolbar(
          centerMiddle: widget.centerTitle,
          middleSpacing: 12,
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
                ?widget.headerLeading,
                // left: the panel, search, reading, finger drawing
                if (widget.togglePages != null)
                  _headerButton(
                    widget.board != null ? 'Whiteboards' : 'Pages',
                    BnIcons.pages,
                    selected: widget.pagesOpen,
                    onTap: (_) => widget.togglePages!(),
                  ),
                if (!phone && widget.openSearch != null)
                  _headerButton(
                    'Search',
                    BnIcons.search,
                    onTap: (_) => widget.openSearch!(),
                  ),
                if (!phone && widget.toggleReadingMode != null)
                  _headerButton(
                    'Reading mode',
                    BnIcons.open,
                    onTap: (_) => widget.toggleReadingMode!(),
                  ),
                // two pages side by side, for this note (a wide screen)
                if (!phone && widget.setTwoPages != null)
                  _headerButton(
                    widget.twoPagesOn ? 'One page at a time' : 'Two pages side by side',
                    // not the open book: that's Reading mode
                    Symbols.two_pager,
                    selected: widget.twoPagesOn,
                    onTap: (_) => widget.setTwoPages!(!widget.twoPagesOn),
                  ),
                if (!stows.hideFingerDrawingToggle.value)
                  _headerButton(
                    widget.fingerDrawing
                        ? 'Draw with finger (on)'
                        : 'Draw with finger (off)',
                    BnIcons.hand,
                    selected: widget.fingerDrawing,
                    onTap: (_) => widget.toggleFingerDrawing(),
                  ),
            ],
          ),
          middle: widget.headerTitle,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
                ?widget.timerChip,
                // right: undo/redo, share and More (add page is in Insert, full
                // screen in More)
                if (widget.headerUndo != null) ...[
                  const SizedBox(width: 4),
                  widget.headerUndo!,
                  const SizedBox(width: 4),
                ],
                if (!phone && widget.addPage != null)
                  _headerButton(
                    widget.board != null ? 'New whiteboard' : 'Add page',
                    BnIcons.addPage,
                    enabled: !widget.readOnly,
                    onTap: widget.addPage!,
                  ),
                if (!phone)
                  _headerButton(
                    'Share and export',
                    BnIcons.share,
                    onTap: widget.openShareMenu,
                  ),
                _headerButton('More', BnIcons.more, onTap: _openMore),
            ],
          ),
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [row, ..._extraBars(context, false)],
    );
  }

  static const _toolLabels = <String, String>{
    'lasso': 'Lasso',
    'pen': 'Pen',
    'laser': 'Laser pointer',
    'shapes': 'Shapes',
    'eraser': 'Eraser',
    'image': 'Image',
    'stickers': 'Stickers',
    'stickyNote': 'Sticky note',
    'textBox': 'Text',
    'record': 'Record audio',
    'accessories': 'Accessories',
  };

  /// The saved order, with any tools it doesn't know about at the end.
  List<String> _toolOrder() {
    final saved = stows.toolbarOrder.value.where(_toolLabels.containsKey);
    return [
      ...saved,
      ..._toolLabels.keys.where((id) => !saved.contains(id)),
    ];
  }

  /// Which tools are in the dock and in what order, where the dock sits,
  /// its size and whether it hides while writing (design T19).
  void _showToolbarCustomizer() {
    final colors = BadNotesColors.of(context);
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: colors.scrim,
      transitionDuration: BnMotion.normal,
      pageBuilder: (context, _, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 940),
            child: const BnPopover(
              padding: EdgeInsets.zero,
              child: _ToolbarCustomizer(),
            ),
          ),
        ),
      ),
      transitionBuilder: (context, animation, _, child) =>
          bnPopIn(context, animation, child),
    );
  }

  @override
  void dispose() {
    _removeKeybindings();
    // fullscreen is part of being in the editor: leaving it ends fullscreen
    DynamicMaterialApp.removeFullscreenListener(_setState);
    DynamicMaterialApp.setFullscreen(false, updateSystem: true);
    super.dispose();
  }
}

class _NoListenable implements Listenable {
  const _NoListenable();
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}


/// A coloured square of the Insert panel: an icon and a name.
class _InsertTile extends StatelessWidget {
  const _InsertTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.45 : 1,
      child: Material(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          side: BorderSide(color: BnColors.text.withValues(alpha: 0.06)),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 20, color: BnColors.text),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BnType.body.copyWith(
                    color: BnColors.text,
                    fontWeight: FontWeight.w600,
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


/// The "Customize toolbar" sheet (design T19).
class _ToolbarCustomizer extends StatefulWidget {
  const _ToolbarCustomizer();

  @override
  State<_ToolbarCustomizer> createState() => _ToolbarCustomizerState();
}

class _ToolbarCustomizerState extends State<_ToolbarCustomizer> {
  /// Marks the toolbar as customized, see [_ToolbarState.dockOrder].
  static const _customized = '_';

  late var _shown = _ToolbarState.dockOrder();

  List<String> get _more => [
    for (final id in [..._ToolbarState.dockTools, ..._ToolbarState.moreTools])
      if (!_shown.contains(id)) id,
  ];

  void _save() {
    stows.toolbarOrder.value = [..._shown, ..._more];
    stows.toolbarHidden.value = [_customized, ..._more];
    setState(() {});
  }

  void _reset() {
    stows.toolbarOrder.value = [];
    stows.toolbarHidden.value = [];
    setState(() => _shown = _ToolbarState.dockOrder());
  }

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final total =
        _ToolbarState.dockTools.length + _ToolbarState.moreTools.length;
    final edge = stows.floatingToolbarEdge.value < 0
        ? (MediaQuery.sizeOf(context).width < 600
              ? ToolbarEdge.bottom
              : ToolbarEdge.top)
        : FloatingToolbar.savedEdge;
    Widget label(String text, [String? trailing]) => Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: BnType.caption.copyWith(
                color: colors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing,
              style: BnType.caption.copyWith(color: colors.muted),
            ),
        ],
      ),
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Customize toolbar',
                      style: BnType.display.copyWith(
                        color: colors.text,
                        fontSize: 26,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Drag to reorder · tap – to remove · tap + to add',
                      style: BnType.caption.copyWith(color: colors.muted),
                    ),
                  ],
                ),
              ),
              BnButton(
                label: 'Reset',
                kind: BnButtonKind.quiet,
                onPressed: _reset,
              ),
              const SizedBox(width: 6),
              BnButton.primary(
                label: 'Done',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          label('In your toolbar', '${_shown.length} of $total'),
          Wrap(
            spacing: 10,
            runSpacing: 12,
            children: [
              for (final id in _shown)
                DragTarget<String>(
                  onWillAcceptWithDetails: (d) => d.data != id,
                  onAcceptWithDetails: (d) {
                    final from = _shown.indexOf(d.data);
                    final to = _shown.indexOf(id);
                    _shown = [..._shown]
                      ..removeAt(from)
                      ..insert(to, d.data);
                    _save();
                  },
                  builder: (context, candidates, _) => LongPressDraggable<String>(
                    data: id,
                    delay: const Duration(milliseconds: 150),
                    feedback: Material(
                      type: MaterialType.transparency,
                      child: _CustomizeChip(id: id, shown: true),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.35,
                      child: _CustomizeChip(id: id, shown: true),
                    ),
                    child: _CustomizeChip(
                      id: id,
                      shown: true,
                      highlighted: candidates.isNotEmpty,
                      onBadge: _shown.length <= 1
                          ? null
                          : () {
                              _shown = [..._shown]..remove(id);
                              _save();
                            },
                    ),
                  ),
                ),
            ],
          ),
          label('More tools'),
          Wrap(
            spacing: 10,
            runSpacing: 12,
            children: [
              for (final id in _more)
                _CustomizeChip(
                  id: id,
                  shown: false,
                  onBadge: () {
                    _shown = [..._shown, id];
                    _save();
                  },
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: SizedBox(
              height: 1,
              child: ColoredBox(color: colors.divider),
            ),
          ),
          label('Toolbar position'),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 300,
                child: BnSegmented<ToolbarEdge>(
                  segments: const [
                    BnSegment(ToolbarEdge.bottom, 'Bottom'),
                    BnSegment(ToolbarEdge.top, 'Top'),
                    BnSegment(ToolbarEdge.left, 'Left'),
                    BnSegment(ToolbarEdge.right, 'Right'),
                  ],
                  selected: edge,
                  onChanged: (edge) =>
                      setState(() => stows.floatingToolbarEdge.value = edge.index),
                ),
              ),
              // label, then a small switch right beside it (a full-width
              // row put the switch far from its label, and it looked big)
              for (final (label, value, set) in [
                (
                  'Compact size',
                  stows.toolbarCompact.value,
                  (bool v) => stows.toolbarCompact.value = v,
                ),
                (
                  'Hide while writing',
                  stows.toolbarAutoHide.value,
                  (bool v) => stows.toolbarAutoHide.value = v,
                ),
              ])
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => set(!value)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 10,
                    children: [
                      Text(label, style: BnType.body.copyWith(color: colors.text)),
                      Transform.scale(
                        scale: 0.8,
                        child: BnToggle(
                          value: value,
                          onChanged: (v) => setState(() => set(v)),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A tool in the customizer: grip, icon and name, with a red "–" to take it
/// out of the dock or a "+" to put it in.
class _CustomizeChip extends StatelessWidget {
  const _CustomizeChip({
    required this.id,
    required this.shown,
    this.onBadge,
    this.highlighted = false,
  });

  final String id;

  /// In the dock (solid, "–") or in More tools (dashed, "+").
  final bool shown;
  final VoidCallback? onBadge;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = BadNotesColors.of(context);
    final path = switch (id) {
      'lasso' => BnToolIcons.lasso,
      'pen' => BnToolIcons.pen,
      'highlighter' => BnToolIcons.highlighter,
      'pencil' => BnToolIcons.pencil,
      'drawShapes' => BnToolIcons.drawShapes,
      'tape' => BnToolIcons.tape,
      'shapes' => BnToolIcons.shapes,
      'eraser' => BnToolIcons.eraser,
      'laser' => BnToolIcons.laser,
      _ => null,
    };
    final icon = switch (id) {
      'ruler' => BnIcons.ruler,
      'zoom' => BnIcons.zoomWindow,
      'record' => BnIcons.mic,
      'timer' => BnIcons.timer,
      'textBox' => BnIcons.text,
      'stickyNote' => BnIcons.sticky,
      'image' => BnIcons.photo,
      _ => BnIcons.sticker,
    };
    final chip = Container(
      height: 50,
      padding: EdgeInsets.only(left: shown ? 10 : 14, right: 16),
      decoration: BoxDecoration(
        color: shown
            ? (highlighted ? colors.accentTint : colors.sunkenSoft)
            : colors.surface,
        borderRadius: const BorderRadius.all(Radius.circular(BnRadius.card)),
        border: shown ? Border.all(color: colors.hairline) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (shown) ...[
            const BnDragHandle(),
            const SizedBox(width: 2),
          ],
          if (path != null)
            BnPathIcon(path, size: 18, color: colors.text, dashed: id == 'lasso')
          else
            Icon(icon, size: 18, color: colors.text),
          const SizedBox(width: 8),
          Text(
            _ToolbarState.dockLabels[id] ?? id,
            style: BnType.body.copyWith(
              color: colors.text,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (shown)
          chip
        else
          CustomPaint(
            foregroundPainter: _DashedChipBorder(colors.faint),
            child: chip,
          ),
        if (onBadge != null)
          Positioned(
            right: -6,
            top: -6,
            child: GestureDetector(
              onTap: onBadge,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: shown ? const Color(0xFFF2564A) : colors.accentTint,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.surface, width: 1.5),
                ),
                child: Icon(
                  shown ? BnIcons.minus : BnIcons.add,
                  size: 12,
                  color: shown ? Colors.white : colors.accentStrong,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DashedChipBorder extends CustomPainter {
  const _DashedChipBorder(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.5),
          const Radius.circular(BnRadius.card),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke;
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 7) {
        canvas.drawPath(metric.extractPath(d, d + 4), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedChipBorder old) => old.color != color;
}
