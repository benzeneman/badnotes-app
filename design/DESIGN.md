# BadNotes — UI redesign spec ("Minimal")

This folder is the complete design for the new BadNotes look. It replaces the
old GoodNotes-style UI with BadNotes' own design. **The look of the app
changes, and the new features in §7 are built.** The writing engine, shape
engine, eraser, tools logic, file format, sync and everything else that already
works must keep working exactly as it does now.

- `screens/` — every screen as an HTML mockup (69 files). Sizes are logical px:
  landscape tablet 1280×800, portrait 800×1280. Read them as text: every
  colour, size, radius, gap and string is in the inline styles. See §8 for how
  to read them and which Dart file each one maps to.
- `tokens/` — `badnotes_tokens.dart` (all design tokens as Dart),
  `folder_colors.json`, `folder_icons.json`.
- `covers/` — 12 extra cover artworks as SVG (optional, see §6).

---

## 1. Hard rules (read before touching anything)

### Do NOT change (logic, engines, data)
- `lib/components/canvas/**` — strokes, painters, ink cache, palm rejection,
  gesture detector, interactive canvas, images. Only `canvas/hud/**` may be
  restyled (colours, radius, font) — no logic changes there either.
- `lib/data/**` — tools (pen, pencil, highlighter, shape pen, shape
  recognizer, eraser, tape, laser, select), editor core/history/exporter,
  codecs, file_manager, nextcloud/sync, prefs. You may **add** new prefs;
  never rename or remove existing ones or change their stored values.
- `lib/pages/editor/editor.dart` — only edit widget-tree code that draws
  chrome (bars, menus, panels, dialogs, banners). Never change gesture
  handling, stroke/shape/eraser paths, undo/redo history, saving/autosave,
  page logic, audio sync or tool switching logic.
- Stored ids must stay the same: cover ids in `cover_designs.dart`
  (`d:ocean`, ARGB hex for solids…), tape pattern ids, sticker ids, sticky
  note designs, page template ids, layer data.
- `packages/`, `patches/`, `submodules/`, native `android/` and `ios/` code
  (except the one refresh-rate line in §5).
- Do not delete any existing feature, setting or menu item. If a screen in
  `screens/` does not show something the code has, keep it and style it the
  same way.

### Workflow
1. Read the code you are going to change first.
2. Work in phases (§9). After every phase: `flutter analyze` clean,
   `flutter test` green (on CI), then one commit per phase with a
   clear message.
3. Check performance in profile mode after phases 4–6 (§5).
4. No GoodNotes material: delete/stop using
   `docs/goodnotes-editor-redesign-prompt.md` and its reference screenshots.
   No GoodNotes names, icons, layouts or assets anywhere.

---

## 2. Design tokens

All of these are in `tokens/badnotes_tokens.dart`. Put them in the theme
(`lib/components/theming/badnotes_theme.dart` — the `BadNotesColors`
ThemeExtension — and `lib/components/editor_ui/editor_ui_colors.dart`) so
every widget reads them from the theme. No hard-coded colours in widgets.

### Colour — light (designed)
| Token | Hex | Use |
|---|---|---|
| desk | `#F6F6F4` | app & editor background |
| surface | `#FFFFFF` | cards, bars, popovers, pages |
| sunken | `#EDEDEA` | search field, segmented track |
| sunkenSoft | `#F2F2EF` | small pressed/selected bg, previews |
| previewBg | `#F6F6F4` | preview wells inside popovers |
| hairline | `#E7E6E1` | 1px borders |
| divider | `#EFEEEA` | separators inside cards |
| text | `#1C1C1E` | primary text, ink black |
| text2 | `#3A3A3F` | icons, secondary labels |
| muted | `#6B6B70` | captions, meta text |
| faint | `#8A8A90` / `#A4A4AA` | hints, drag handles |
| disabled | `#B4B4B8` | disabled icons |
| accent | `#6E56CF` | primary buttons, selection, sliders, toggles |
| accentStrong | `#5A43B8` | text/icon on accentTint, pressed |
| accentTint | `#F0EDFC` | selected tool, selected chip/row bg |
| accentTintBorder | `#E0D9FA` | border of selected chip |
| accentSoft | `#E9E4FB` | avatar bg, search highlight bg (`#4B3A9E` text) |
| danger | `#D93A2B` | delete, destructive text |
| success | `#2A7660` on `#E2F3EC` | "Up to date", "Knew it" |
| scrim | `rgba(20,20,22,.28)` | behind dialogs/sheets |

Pastels (covers): lavender `#E8E1FB`, blush `#FBE3DA`, mint `#DCEFE9`,
sand `#F7ECCF`, sky `#DCE8FB`, rose `#F8DDE6`, charcoal `#2B2B30`.
Quick-note colours: butter `#FFF4CC`, peach `#FDE7E1`, sky `#E9F1FB`,
lilac `#EEEAFC`, mint `#E2F3EC`.
Default ink presets: `#1C1C1E`, `#2B4ACB`, `#E03131`, `#2F9E77`.
Folder colours: `tokens/folder_colors.json` (back / front / ink per colour).

### Colour — dark (derived, not drawn; keep the same structure)
desk `#111113`, surface `#1C1C1F`, sunken `#26262A`, hairline `#2E2E32`,
divider `#2A2A2E`, text `#EDEDEF`, text2 `#C7C7CC`, muted `#8E8E93`,
accent `#8B7CF0`, accentStrong `#B9ADF7`, accentTint `#2A2440`,
danger `#FF6B5E`, scrim `rgba(0,0,0,.5)`. Pastel covers/folders keep their
colours (they are artwork), ink is not inverted unless the existing
"invert pages in dark mode" setting says so.

### Type
- UI font: **Inter** (OFL). Bundle it as an asset font family `Inter`
  (weights 400, 500, 600, 700) in `pubspec.yaml`; make it the theme
  `fontFamily`. Keep `AtkinsonHyperlegibleNext` and the existing fallbacks; the
  "readable font" setting switches to Atkinson.
- Handwriting-looking text in mockups (sample notes, quick notes) is
  **Caveat**, already bundled — only for sticky/quick-note text.

| Style | Size / weight / tracking | Use |
|---|---|---|
| display | 28 / 600 / −0.8 | page titles ("Good afternoon", "Recent") |
| title | 17 / 600 / −0.2 | dialog & sheet titles |
| section | 15 / 600 | section headers, popover titles |
| body | 13–14 / 500 | rows, buttons, inputs |
| caption | 12 / 400–500, `muted` | meta lines ("Today", "12 items") |
| micro | 11 / 500 | cover labels, tiny badges |

### Shape, depth, spacing
- Radius: chip 8 · input/button/segmented 10 · tool button 12 ·
  card/sub-bar 14 · editor tool dock 16 · popover/sheet 18 · home dock pill 999.
  Notebook covers: `4 12 12 4` (spine side 4) with a 10px darker spine strip
  (`rgba(0,0,0,.08)`).
- Shadows (light): card `0 1 2 rgba(0,0,0,.03)` · floating bar
  `0 10 30 rgba(0,0,0,.08)` · popover `0 2 4 rgba(0,0,0,.04), 0 18 48 rgba(0,0,0,.12)`
  · cover `0 1 2 rgba(0,0,0,.06), 0 10 24 rgba(0,0,0,.08)`.
- Borders: 1px `hairline`. No thick outlines anywhere.
- Spacing on a 4-pt grid. Screen margins: 40 landscape, 28 portrait.
  Common gaps 8 / 12 / 16 / 18 / 24 / 32.
- Icons: **Lucide** style — 1.8 stroke, round caps/joins, 18–21 px in bars,
  16 px in rows. Use the `lucide_icons_flutter` package (UI-only dependency)
  or draw the given SVG paths; if adding a package is not wanted, Material
  Symbols **Rounded, weight 300** is the closest fallback. One icon style
  everywhere.
- Motion: 150–200 ms, `Curves.easeOutCubic`. Popovers fade + scale from 0.96
  out of their anchor. Selected states cross-fade. Nothing bouncy.

---

## 3. Components (build once in `lib/components/ui/`, reuse everywhere)
- **Home dock** — floating pill at bottom centre (22 px from bottom):
  Desk · Recent · Favorites · Whiteboard | **New** (accent filled). Active tab
  = accentTint bg + accentStrong text. Portrait: icons only except Desk/New.
- **Editor tool dock** — floating bar, radius 16: drag handle (6 dots,
  `faint`) · Lasso · Pen · Highlighter · Pencil · Draw shapes · Tape · Shapes ·
  Eraser · Laser | Insert (accent square). Active tool = accentTint +
  accent icon. Keep `FloatingToolbar` behaviour (lift, glide to an edge,
  remembers the edge); restyle only. When at the top, the sub-bar and
  popovers open below it (see `M_EditorTop`).
- **Sub-bar** — the options row of the current tool, radius 14, 5 px
  padding: variant pill (accentTint) · sizes (3 short lines) · colour dots
  (22 px, selected ring 2 px white + 1.5 px accent) · more.
- **Popover / tool panel** — radius 18, popover shadow, 16 px padding;
  title 15/600 + optional caption; previews in a `previewBg` well.
  Nested pages slide in with a back chevron (existing `ToolPanel.push`).
- **Segmented control** — sunken track r10, 3 px padding, selected =
  white chip with tiny shadow.
- **Toggle** — 40×24, off `#E2E1DC`, on accent, white knob with shadow.
- **Slider** — 4 px track `hairline`, fill accent, 20 px white knob with
  shadow; label row above (12/500 muted, value right).
- **Chip** — h30 r8 1px hairline; selected accentTint + accentStrong.
- **Buttons** — h40 r10. Primary accent/white text 600; secondary white
  with hairline; destructive text `danger`.
- **Rows / lists** — h40 menu rows (r10, hover `#F4F4F1`), 60–64 list rows
  inside cards with `divider` lines.
- **Folder tile** — see `M_Home` / `N19_AllFolders`: tab (64×20, r10 top),
  back panel, 1–2 mini covers peeking out, front panel (h56, r12, lighter
  colour) with name + count, and the folder icon in a 28 px
  `rgba(255,255,255,.65)` square at top-right, icon colour = folder ink.
- **Notebook cover tile** — cover 3:4 (176 px tall on landscape home), label
  inside at bottom-left, title 13/600 + meta 12 muted below; star badge when
  favourite.
- **Dialog / sheet** — scrim + popover-style card. Right-side sheets on
  tablet (stickers, cover, layers), bottom sheets on phone.

---

## 4. Screens
See §8 for the full list with the Dart file each one maps to. Landscape is the
reference; portrait (`M_Portrait`) shows how the home reflows (5 folder
columns, 4 notebook columns, quick notes as a horizontal strip, compact dock).
Phone layouts: same components, single column, bottom sheets.

## 5. Performance — must stay at max refresh rate
- Writing, scrolling, zooming and dragging the toolbar must hold 120 Hz on
  ProMotion iPads and high-refresh Android (≤ 8.3 ms build + raster). Check
  with `flutter run --profile` + DevTools Performance before/after each phase.
- Never put `BackdropFilter`, `Opacity` or `ShaderMask` over the canvas.
  The blur seen on scrims/docks in the mockups is decorative: on editor
  screens use a flat translucent colour instead. On home, blur only static
  areas if it costs nothing measurable; otherwise use flat colour.
- Wrap the floating dock, sub-bar and each open panel in `RepaintBoundary`.
  Tool/UI state lives in small `ValueNotifier`s with local
  `ValueListenableBuilder`s — no `setState` on the editor root for chrome.
  Changing a tool, colour or size must not rebuild or repaint the canvas.
- `const` constructors wherever possible; no work in `build` (pre-compute
  colours, paths, text styles).
- Shadows: keep blur radii as in §2; don't stack several big shadows on
  every list item. Grid items (covers, page thumbnails) in
  `RepaintBoundary`, covers' `CustomPainter.shouldRepaint` returns false
  unless the design id changes, images decoded with `cacheWidth`.
- Lists and grids use builders (lazy).
- Animations only on transform/opacity of small widgets.
- iOS ProMotion is already on (`CADisableMinimumFrameDurationOnPhone`).
  On Android request the highest refresh rate at start-up (e.g. the
  `flutter_displaymode` package, `FlutterDisplayMode.setHighRefreshRate()`),
  Android only, behind a platform check.

## 6. Covers
Keep every existing `CoverDesign` (27 + solid colours) and its id. Build the
picker as in `N28_CoverLibrary`: sections Solid colors / Simple / Colorful /
Patterns / Dark, cover tiles 88×118, selected ring, preview panel on the right
with "Show name on cover", "Use a photo", "No cover (show first page)",
"Apply cover". The SVGs in `covers/` are optional extra designs in the new
pastel style — add them as new `CoverDesign`s with **new ids** (`d:mountains`,
`d:waves2`, …) drawn in code like the others, never replacing existing ones.

## 7. Features to build (all of them — not optional)

Some things in the mockups don't exist in the code yet. Build every one of
them. They are UI features: build them on top of the **public** APIs that
already exist (`FileManager.readFile / writeFile / moveFile / deleteFile /
getChildrenOfDirectory / getAllFiles / fileWriteStream`, `stows.*`
(`PlainStow`), the existing note-opening / insert functions). Never change how
notes, strokes or assets are encoded, and never edit inside
`lib/data/file_manager`, `lib/data/codecs` or `lib/components/canvas`. If a
feature truly can't be built without that, stop and ask me.

### 7.0 Rules that make every feature feel smooth
- **Instant UI, saving later.** Change the in-memory state and the screen
  first (optimistic), then save in the background. Debounce writes
  (300–500 ms) for things the user types or drags; never `await` a disk write
  before updating the UI.
- **Heavy work off the UI thread.** Scanning folders, reading many files,
  decoding/resizing images, searching text: do it in an isolate
  (`Isolate.run` / `compute`, or the `worker_manager` already in pubspec).
  Stream results in batches so the list fills progressively.
- **Small rebuilds.** Each feature owns its state in a `ValueNotifier` /
  `ChangeNotifier`; only the widget that shows it listens. Adding a quick note
  must not rebuild the notebook grid; changing a folder colour must rebuild
  only that tile.
- **Lazy + cached lists.** `GridView.builder` / `SliverGrid`; thumbnails
  decoded at display size (`ResizeImage` / `cacheWidth`) and kept in a small
  LRU cache; every tile in a `RepaintBoundary`.
- **Keep up with other devices.** Listen to `FileManager.fileWriteStream`
  and update only the item that changed — no full reloads.
- **Motion.** 150–200 ms `easeOutCubic`; popovers scale 0.96→1 + fade;
  opening a photo/quick note uses a `Hero`; list inserts/removals animate
  (`AnimatedList` / `SliverAnimatedList` or implicit size/opacity). Respect
  "reduce motion" (`MediaQuery.disableAnimations`).
- **Hidden helper files.** Some features store small files whose names start
  with a dot (`.board/`, `.trash/`, `.style.json`). They go through
  `FileManager.writeFile`, so they sync like notes. In the UI (browse,
  folders, recent, search, counts), skip every entry whose name starts with
  `.` — filter in the widgets / view-models, not inside `file_manager.dart`.

### 7.1 Folder icon & colour (`N27_EditFolder`, all folder tiles)
- Data: one small file per folder, `<folder>/.style.json`:
  `{"color":"lavender","icon":"cap"}`. Because it lives inside the folder it
  moves and renames with it automatically and syncs. No file = lavender, no
  icon.
- Colours: `tokens/folder_colors.json` / `BnFolderColor`. Icons:
  `tokens/folder_icons.json` (key → Lucide name + SVG path) + "None".
- UI: folder long-press → "Edit folder" opens N27 (name, colour, icon, live
  preview). Saving renames through the existing rename function if the name
  changed, then writes `.style.json`. New-folder dialog (N05) gets the same
  colour row.
- Smooth: keep a `FolderStyleCache` (path → style) filled lazily in the
  background when a folder tile first appears; tiles show the default style
  instantly and cross-fade (150 ms) when the real style arrives. The folder
  tile is drawn with plain `Container`s/`CustomPainter` (no images), inside a
  `RepaintBoundary`.

### 7.2 Quick notes board (home right column / portrait strip, `N06`, `N12`, `N13`)
- What: small sticky notes (text or checklist, 5 colours) and pinned photos,
  always on the home screen.
- Data: `/.board/board.json` — a list of
  `{id, type: "note"|"photo", text, checklist:[{text,done}], color, photo,
  createdAt, updatedAt, order}`; photos as `/.board/<id>.jpg` (resized to max
  1600 px, JPEG ~85 %, in an isolate before saving). Write with
  `FileManager.writeFile` so it syncs. If two devices edit, merge by `id`
  using `updatedAt` (newest wins).
- UI: "+" on the board → composer (N06) as a popover; tap a note → opens big
  (N12) with Edit, colour, "Add to notebook", Remind me, Unpin, Delete; tap a
  photo → viewer (N13) with prev/next, Share, Save to gallery, "Add to
  notebook", Delete. Long-press + drag to reorder. "Add to notebook" opens a
  notebook picker and inserts the note as a sticky note / the photo as an
  image through the editor's existing insert functions; if that needs engine
  changes, hide only that button.
- "Remind me": local notification with the existing/added notifications
  package; if adding a notification package is a problem, leave the button
  out.
- Smooth: board state in its own `ValueNotifier<List<BoardItem>>`; composer
  typing updates memory only, save debounced 400 ms; photo thumbs decoded at
  tile size; `Hero` from tile to viewer.

### 7.3 Trash for notes (`N20_Trash`, `N07_Delete` + Undo)
- Delete → `FileManager.moveFile` the note into `/.trash/` (it already moves
  assets, audio, OCR and cover side files). Record
  `{trashPath, originalPath, deletedAt}` in `/.trash/index.json`.
- Show a snackbar "Moved to Trash · Undo" for 5 s; Undo moves it back.
- Trash page (from the profile menu and Settings › Storage): restore (back to
  the original path, made unique if taken), delete forever
  (`FileManager.deleteFile`), "Empty trash". On app start, in the background,
  delete forever anything older than 30 days.
- Smooth: the note disappears from the grid immediately (animated); the move
  runs in the background.

### 7.4 Search across all notes (`N08_Search`)
- Search titles + handwriting text from the existing `<note>.ocr.txt` side
  files + PDF text where the app already extracts it. Build an in-memory index
  in an isolate at first open of search (title, folder, ocr text per note),
  update entries from `fileWriteStream`, debounce typing 150 ms, show results
  grouped (Handwriting / Notebooks / Photos / Quick notes) with the match
  highlighted. Tapping a handwriting result opens the note at that page.
- Recent searches: last 8 in a new `stows.recentSearches`.

### 7.5 Photos filter (`N23_Photos`)
- Pictures inside notes are asset files next to the note named
  `<note>.sbn2.<n>` (`FileManager.assetFileRegex`); PDFs end in `p`. In an
  isolate, list them with `getAllFiles`/directory listing, keep the ones whose
  first bytes are a PNG/JPEG/WebP signature (no decoding needed to check),
  plus quick-board photos. Cache the list in memory; update from
  `fileWriteStream`.
- Grid: masonry (`flutter_staggered_grid_view` is already in pubspec),
  thumbnails at tile width, caption = note name + page if known. Tap → viewer
  (same as N13) with "Open note".

### 7.6 Profile / account menu (`N10_Profile`)
- Avatar button in the home header → popover: account line (Google
  Drive/OneDrive account from the existing sync state, or "Not signed in"),
  Theme segmented (Light/Dark/Auto → existing `appTheme` pref), Settings,
  Pen & stylus (Settings section), Backup & export (Settings › Backup),
  Trash (7.3) with count, Help, version.

### 7.7 Customize toolbar (`T19_Customize`)
- Order already exists in `stows.toolbarOrder`. Add `toolbarHidden`
  (list of tool ids), `toolbarCompact` (bool) and `toolbarAutoHide` (bool).
- Sheet: "In your toolbar" (drag to reorder with a reorderable list/wrap,
  "−" moves it to More), "More tools" ("+" adds: Ruler, Zoom window, Record,
  Timer, Text, Sticky note, Photo, Sticker — each opens the existing feature),
  position segmented (Bottom/Top/Left/Right → existing
  `floatingToolbarEdge`), Compact, Hide while writing, Reset, Done.
- "Hide while writing": fade the dock to 0 and ignore pointer while a stroke
  is in progress, fade back 300 ms after pen-up. Do it by listening to the
  existing "drawing started/ended" signal; if there isn't one, ask me before
  adding anything to the canvas code.
- Smooth: changes apply live; the dock only re-lays out, its buttons are not
  rebuilt (same trick `FloatingToolbar` already uses for dragging).

### 7.8 Toolbar drag handle
- 6-dot handle at the start of the editor dock (or the top when vertical).
  Dragging it uses the existing lift-and-glide behaviour; tapping it does
  nothing. While dragging, show a dashed "drop here" outline at the top and
  bottom edges (see `M_EditorTop`).

### 7.9 Home extras
- **Cover size S/M/L** and **Grid/List** in the sort popover (`N11`): new
  `stows.homeCoverSize` (0/1/2), list view uses the row style of `N16`.
- **Empty desk** (`N22`): illustration, "Create notebook", "Import PDF", and
  3 templates (Lecture notes = Study notes paper, Daily planner = Day planner,
  Sketchbook = Plain ivory) that open the document studio pre-filled.
- **Revision banner** (`N16`): restyle the existing `revision_plan.dart`
  reminder; "Start quiz" opens the note's tape quiz.
- **All folders** (`N19`): "See all" on the Folders row opens a full grid
  with Name / Recent / Size sorting.
- **Multi-select** (`N24`): selection ring + check on tiles, top bar with
  Cancel / "N selected" / Select all, bottom action bar Move · Favorite ·
  Duplicate · Export · Delete (→ Trash).

### 7.10 Editor extras
- **Finger-draw toggle** in the editor header (hand icon) bound to the
  existing finger-drawing setting.
- **Timer** (`T18`): the existing focus/break timer in the new popover:
  Focus/Break tabs, presets (15/25/45/60 · 5/10/15), ring progress, Pause /
  Reset / +5 min, "Start break automatically", today's total. Store presets
  and totals in new prefs. Drop the "Do not disturb" row unless the platform
  allows it without extra permissions.
- **Pen presets** (existing `pen_presets.dart`): show them in the pen sub-bar
  as small dots before the colours.

### 7.11 Already in the code — restyle, don't rebuild
Audio record + replay, writing replay, split view, layers, handwriting OCR,
link/comment pins, reading mode, screenshot, tape quiz + revision plan,
present, note lock, whiteboard paper + kits, find in note, page templates,
pages overview, cloud status, backup, stickers, sticky notes, text boxes,
ruler, zoom window, laser, tape, shape tools, colour panel, pen presets,
floating toolbar edges, toolbar order.

## 8. Screen index → code
How to read a mockup: open the `.dc.html` as text. Everything inside
`<x-dc>` is the screen; ignore `support.js` and the `<script>` block (it only
fills sample values — `{{name}}` placeholders take their sample value from
`renderVals()` in that script). A `<dc-import name="M_Home">` /
`"M_Editor"` / `"M_Shell"` line means "this screen is drawn on top of that
screen", so open that file too. Overlays are absolutely positioned in px.

| Mockup | What | Code to restyle |
|---|---|---|
| M_Home | Home (Desk) landscape | pages/home/browse.dart, components/home/documents_grid.dart, documents_widgets.dart, notebook_cover.dart, preview_card.dart, navbar/* |
| M_Portrait | Home portrait | same, responsive |
| M_Shell | Shared header + dock | navbar/*, pages/home/home.dart |
| N01_Create | New button menu | home/new_note_button.dart |
| N02_NotebookHold | Notebook long-press | documents_grid.dart, selection_actions.dart, rename/move/delete/export buttons |
| N03_FolderHold | Folder long-press | grid_folders.dart, rename_folder_button.dart, delete_folder_button.dart |
| N04_NewNotebook | New notebook / whiteboard | home/document_studio.dart |
| N05_NewFolder | New folder | home/new_folder_dialog.dart |
| N06_QuickNote, N12_StickyOpen, N13_PhotoView | Quick notes board | NEW (§7.2) |
| N07_Delete | Delete confirm + Undo | home/delete_note_button.dart |
| N08_Search | Search all notes | browse.dart search + NEW index (§7.4) |
| N09_Sync | Cloud & backup status | home/cloud_status.dart, sync_indicator.dart |
| N10_Profile | Account menu | NEW (§7.6) |
| N11_Sort | Sort & view | home/sort_button.dart, home_layout_button.dart |
| N14_MoveTo | Move to folder | home/move_note_button.dart |
| N15_FolderOpen | Inside a folder | browse.dart (path), components/home/* |
| N16_Recent | Recent + revision banner | pages/home/recent_notes.dart, home/revision_plan.dart |
| N17_Starred | Favorites | pages/home/favorites.dart |
| N18_Whiteboards | Whiteboard tab | pages/home/whiteboard.dart |
| N19_AllFolders | All folders | grid_folders.dart |
| N20_Trash | Trash for notes | NEW (§7.3) |
| N21_Settings, N31_AccountSync, N32_Backup | Settings (sections as in code) | pages/home/settings.dart, components/settings/* |
| N22_Empty | Empty desk | browse.dart empty state |
| N23_Photos | Photos filter | NEW (§7.5) |
| N24_Select | Multi-select | home/selection_actions.dart |
| N25_Rename | Rename | rename_note_button.dart |
| N26_Cover, N28_CoverLibrary | Cover picker | home/notebook_cover.dart (+ cover_designs.dart unchanged) |
| N27_EditFolder | Folder icon & colour | NEW (§7.1) |
| M_Editor | Editor, toolbar bottom, Pen panel | editor_ui/floating_toolbar.dart, tool_bars.dart, tool_chips.dart, tool_panel.dart, undo_redo_pill.dart, editor/note_tabs.dart |
| M_EditorTop | Toolbar dragged to top | floating_toolbar.dart |
| T02_PenSettings | Pen settings → Draw & hold → Gestures | tool_panel.dart pages, toolbar/pen_modal.dart |
| T03–T06, T08 | Highlighter, Pencil, Draw shapes, Tape, Laser | editor_ui/tool_bars.dart, tool_panel.dart |
| T07_Colors | Colour panel (presets / custom grid + wheel / history) | editor_ui/color_panel.dart, color_wheel.dart |
| T09_Shapes | Shapes + stroke settings | tool_bars.dart |
| T10_Eraser | Eraser type + filters | tool_bars.dart, tool_panel.dart |
| T11_Insert, T12_Stickers | Insert, stickers | editor_ui/insert_panels.dart, editor/stickers.dart |
| T13_Text | Text format bar + fonts | editor_ui/text_format_bar.dart, editor/text_box_overlay.dart |
| T14_Record, T15_Playback | Audio record + replay | editor/audio_notes.dart, writing_replay.dart |
| T16_ZoomWindow, T17_Ruler | Zoom window, ruler | editor/canvas_tools_overlay.dart (visual only) |
| T18_Timer | Focus / break timer | timer UI in editor.dart |
| T19_Customize | Customize toolbar | toolbar/toolbar.dart + NEW (§7.7) |
| T20_More | More menu | editor.dart menu |
| T21_Export | Export | toolbar/export_bar.dart, home/export_note_button.dart |
| T22_AddPage | Add page / change template | editor/new_page_sheet.dart |
| T23_PageOverview | All pages | editor/pages_overview.dart, pages_panel.dart |
| T24_Lasso | Selection bar | editor_ui/selection_action_bar.dart |
| T28_SplitView | Two notes | editor/note_split_view.dart, note_tabs.dart |
| T29_Layers | Layers | editor/layers_sheet.dart |
| T30_HandwritingText | Handwriting → text | editor/handwriting_ocr.dart |
| T31_PagePin | Link & comment pins | editor/page_pins.dart |
| T32_ReadingMode | Reading mode | editor/reading_tools.dart |
| T33_Screenshot | Screenshot | editor/screenshot_overlay.dart |
| T34_TapeQuiz | Tape quiz | editor/tape_quiz.dart |
| T35_Present | Present | editor/go_live.dart |
| T36_Locked | Locked note | editor/read_only_banner.dart |
| T37_Whiteboard | Whiteboard paper & layouts | editor/board_paper.dart, board_kits.dart |
| T38_FindInNote | Find in note | editor/note_search_panel.dart |

Strings in the mockups are examples; keep the app's existing strings and
translations (slang `lib/i18n`) where they exist, add new keys for new text.
Sample data (notebook names, dates, "[Your name]") is placeholder content.

## 9. Phases
0. Read this file, the mockups and the files in §8. Write a short plan.
1. Tokens + Inter font + theme (`badnotes_theme.dart`, `editor_ui_colors.dart`).
2. Shared components in `lib/components/ui/`.
3. Home: Desk, folder tiles, covers, dock, header, portrait, empty state.
4. Home dialogs & tabs: N01–N05, N07–N11, N14–N22, N24–N28, N31–N32.
5. Editor chrome: dock + handle, sub-bar, header, tabs, undo/redo.
6. Editor panels: T02–T38 + §7.7, 7.8, 7.10.
7. New home features: §7.1–7.6, 7.9 (one commit per feature).
After each: analyze, tests, profile check (from phase 4), commit.
