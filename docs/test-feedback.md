# Test feedback log

Feedback from closed testing on Google Play, and what was done about it.
Kept for the Play production-access form.

| Date | Reported by | Problem | Fix | Version code |
|---|---|---|---|---|
| 2026-11-26 | Owner | Fountain, brush and calligraphy pens at high stabilization showed small breaks and cuts at bends | A long line is drawn in pieces; each piece now continues the line's steadying instead of starting again at the pen, and no longer ends at the raw pen point | 137013 |
| 2026-11-26 | Owner | A shape with rounded corners off had a missing square at one corner | Closed shapes are drawn as closed outlines, so every corner is joined | 137013 |
| 2026-11-26 | Owner | "More papers" in the page template sheet looked like plain text | Now a tappable row like "More patterns" in the tape panel, with "Fewer papers" to fold it again | 137013 |
| 2026-11-26 | Owner | Every new notebook started on Plain, Ivory paper | New notebooks start on White, Dot grid; the paper and colour last chosen are remembered for the next one | 137013 |
| 2026-11-26 | Owner | Quick notes board: changing a note's pin style, colour or shape only showed after closing the popover | The board behind a popover refreshes when what it shows changes; same for the board background and the home layout panel | 137013 |
| 2026-11-26 | Owner | Some settings didn't preview live: line thickness, line spacing on template pages, a colour added from the grid or wheel, a selected shape's style preview | Each now updates as it is changed | 137013 |
| 2026-11-26 | Owner | After renaming a notebook in the top bar, the text cursor stayed on the name while writing | Tapping outside the name ends editing; Enter saves the name at once | 137013 |
| 2026-11-26 | Owner | Notebook tabs in the top bar couldn't be reordered | Long-press a tab and drop it on another tab to move it there | 137013 |
| 2026-11-26 | Owner | A notebook opened as "corrupted" after closing and reopening it | Numbers past 31 bits (a picture's or text box's order, a timestamp) come back from the file as 64-bit values and failed to read; they are read correctly now, so the affected notes open again. Each save also writes to its own temporary file | 137013 |
| 2026-11-26 | Owner | Pressing back many times quickly after writing closed the app | Leaving a note only closes the note itself; no picture of the page is taken while the app is going away; a note closed before it loaded no longer disposes the shared placeholder | 137013 |
| 2026-11-26 | Owner | A new text box stretched to the edge of the page | It starts small and grows as you type, wrapping at the page's edge | 137013 |
| 2026-11-26 | Owner | With the text tool, a tap on existing text opened the keyboard | A tap picks the text (move, resize, delete); a double tap types in it | 137013 |
| 2026-11-26 | Owner | Asked for notebook tabs like Chrome's | Tablet tabs redone: the open tab is white with curved feet joining the bar, all tabs the same width with ✕ on each, and dragging a tab moves the others aside as it passes | 137015 |
| 2026-11-27 | Code review | Ways notes could be lost: sync writing over an open note, pictures losing their files after a rename, a failed save blocking all later saves, a save asked for during another being dropped, folder renames reappearing from the cloud, picture files written half or out of order, leftover temporary files, edits lost while a text box was open, versions deleted with a cloud deletion, sync timing gaps, the Drive backup running out of memory | Each fixed: an open note's cloud version is kept as "(from cloud)"; pictures follow renames; saves queue and recover from errors; folder renames sync; pictures are written whole and in order; temp files are cleaned; versions are kept; uploads use the time of what was read; the backup is zipped to a file | next |
