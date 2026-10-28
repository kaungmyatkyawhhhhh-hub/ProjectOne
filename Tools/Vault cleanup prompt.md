---
date: 2026-10-28
tags: [vault, prompt]
status: todo
---
# Vault cleanup prompt (run once in a Claude Code session on the PC)

Back to [[00-START-HERE]]

```text
VAULT CLEANUP (owner asked for it: "the obsidian needs to be organised"). The root notes 00-START-HERE, Active-Projects and CLAUDE.md are already updated; follow them. Never delete anything: move, don't delete. Leave .obsidian/ alone. Don't touch any Roblox Studio.

1) ARCHIVE (use git mv so history is kept)
- Create Archive/. Move "SPEED ARC" -> "Archive/SPEED ARC" and "Break A Bed" -> "Archive/Break A Bed".
- Move Untitled.canvas -> Archive/Untitled.canvas.
- Code folders in Games/ stay where they are (MOW ARC reads Games/SpeedArc).

2) FIX LINKS
- After moving, search the whole vault for links that pointed into the moved folders ([[SPEED ARC/...]], [[Break A Bed/...]], ![[...]] embeds, paths in CLAUDE.md / Quick Rules / prompts) and update them to the new paths. List how many you fixed.
- Check Obsidian's own link style: if notes use short links ([[Note name]]) and the name is unique, they still work; only fix path links.
- MOW ARC notes mention SPEED ARC code at Games\SpeedArc\src: that path doesn't change.

3) GYM ARC FOLDER TIDY (keep it light, nothing renamed that other notes embed by path)
- Root of GYM ARC: keep 00 GYM ARC Home and Handoff. Move "2026-10-20 GYM ARC Gameplay plan.md" into GYM ARC/Archive/ (create it) unless the home note says it's still current.
- Prompts: add a frontmatter status to any prompt missing one (done / todo / replaced, from its progress note). Create "GYM ARC/GYM ARC - Prompt Log.md": a table of every prompt (number, title, date, status, progress link), newest first. Move prompts marked "replaced" into GYM ARC/Prompts/Replaced/.
- Make "00 GYM ARC Home.md" SHORT (under ~120 lines): what the game is, current status + next update, links to CLAUDE.md, Features index, Prompt Log, Bugs index, Monetization. Move the long prompt list and old history from the home into the Prompt Log (nothing lost).
- Bugs: create "GYM ARC/GYM ARC - Bugs Index.md" (open vs fixed, one line each) if there isn't one.
- Screenshots: DON'T move them (many notes embed them by path). Just report the folder size.

4) MOW ARC: nothing to move; make sure its home lists its prompts.

5) REPORT: a short list of what moved where, links fixed, anything you weren't sure about (ask me instead of guessing). Commit with a clear message and push so Obsidian pulls it.
