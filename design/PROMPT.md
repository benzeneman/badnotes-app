# Paste this into Claude Code (run it inside the badnotes repo)

---

You are working on BadNotes (Flutter) in this repo. I want the
whole app's UI redesigned to the new BadNotes "Minimal" design that is in the
`design/` folder. Talk to me in simple Hinglish; keep code, comments and
commit messages in English.

Read first, in this order:
1. `design/DESIGN.md` — the full spec, rules and phases. Follow it exactly.
2. `design/screens/*.dc.html` — every screen as an HTML mockup. Open them as
   text: every colour, size, radius, gap and string is in the inline styles.
   `M_Home`, `M_Shell` and `M_Editor` are the base screens others are drawn on.
3. `design/tokens/` — Dart tokens, folder colours and folder icons.
4. The Dart files listed in DESIGN.md §8 before you change them.

The most important rules:
- Build EVERY feature in DESIGN.md §7 that the app doesn't have yet (folder
  icon & colour, quick notes board, trash for notes, search across all notes,
  photos filter, profile menu, customize toolbar, drag handle, home and
  editor extras). §7 tells you how to build each one and how to keep it
  smooth (instant UI + background saving, heavy work in isolates, small
  rebuilds, lazy cached grids). Use only the existing public APIs.
- Apart from those features, only the UI changes. The writing
  engine, shape engine, eraser, all tool logic, strokes, history/undo, saving,
  file format, sync, audio sync and every existing feature must keep working
  exactly as now. Don't touch `lib/components/canvas/**` (except visuals in
  `hud/`), `lib/data/**` (you may only ADD prefs), or the logic parts of
  `lib/pages/editor/editor.dart`. Keep all stored ids (covers, tape, stickers,
  templates).
- Never remove a feature, setting or menu item. If the mockups don't show
  something the code has, keep it and style it the same way.
- The UI must stay at max refresh rate (120 Hz) with no lag or jitter while
  writing, zooming, scrolling or dragging the toolbar — follow DESIGN.md §5,
  and check in profile mode.
- No GoodNotes material anywhere. Stop using
  `docs/goodnotes-editor-redesign-prompt.md`.

How to work:
- Start with phase 0: read everything and give me a short plan (in Hinglish)
  with the list of files you will change in each phase. Wait for my OK.
- Then do one phase at a time (DESIGN.md §9). After each phase:
  `flutter analyze` with no new issues, tests green, then commit with a clear
  message, and tell me in 3–4 lines what changed and what to check on my
  iPad.
- If something in the design conflicts with how the code works, or a change
  would need touching engine code, stop and ask me instead of guessing.
