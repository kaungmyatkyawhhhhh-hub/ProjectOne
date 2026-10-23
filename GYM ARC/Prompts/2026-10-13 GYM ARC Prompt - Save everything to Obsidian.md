---
date: 2026-10-13
tags: [gymarc, prompt]
status: done
---
# 2026-10-13 GYM ARC Prompt - Save everything to Obsidian

Back to [[00 GYM ARC Home|GYM ARC Home]].

Saved exactly as sent (in a text block, so the example links in it don't show as missing notes):

```text
STANDING RULE: SAVE EVERYTHING TO MY OBSIDIAN VAULT TOO

1. The vault
   - My vault is: C:\ObsidianOne\Claude+Obsidian
   - It already has notes for my OTHER games. Never edit, move, rename or delete anything outside the GYM ARC folder.
   - First look at how the vault is organized (folder names, how the other games are laid out, existing templates, tags, a home/index note). Match that style. If the other games already have their own folder structure, use the same one for GYM ARC instead of the one below.
   - If there's a main index/home note that lists the games, add a link to GYM ARC there (just one line, don't change anything else in it).
   - Write the vault path in CLAUDE.md.

2. Folder layout (only if the vault has no existing pattern to copy)
   C:\ObsidianOne\Claude+Obsidian\GYM ARC\
     00 Home.md            (overview: what the game is, current status, what's next, open bugs, links)
     Progress/             (one note per work session, named YYYY-MM-DD <short title>.md)
     Prompts/              (every prompt I give you, saved as I sent it, named YYYY-MM-DD <title>.md)
     Features/             (one note per system: Muscles, Spotting, Growth Spurt, Posing Competition, Arm Wrestling, Monetization, Aura, Music & Sounds, etc.)
     Bugs/                 (one note per bug: what happened, cause, fix, status open/fixed)
     Config/               (Config values.md: every tunable number and what it does)
     Monetization/         (passes and products: name, description, price, ID, status)
     Sounds/               (every SoundId / music slot: filled or still empty)
     Screenshots/          (copies of the screenshots, same file names)
     Assets/               (meshes/textures/images imported, with asset IDs)

3. How to write the notes
   - Markdown with frontmatter: date, tags (use #gymarc on everything, plus #bug / #feature / #progress etc.), status.
   - Link notes with [[wikilinks]]; embed screenshots with ![[file.png]].
   - Note names must be unique across the whole vault (my other games may have notes like "Progress" or "Config"). Prefix them if needed, e.g. "GYM ARC - Config values".
   - Short and readable. No emojis.

4. When to save
   - Every time you update PROGRESS.md, also write/update the vault: a Progress note for this session, plus the Feature/Bug/Config/Monetization/Sounds notes that changed.
   - When I give you a new prompt, save it in Prompts/ first, then start working.
   - Put the morning report at the top of that day's Progress note too.
   - Keep 00 Home.md up to date.

5. First run now
   - Create the GYM ARC folder and fill it from what already exists: PROGRESS.md, repo docs, the prompts in my Downloads (GYM_ARC_*.md), the screenshots folder and Config. One Feature note per existing system, one Bug note per known bug (fixed or open).
   - The vault is a copy. Don't move or delete anything from the repo or Downloads. GitHub src/ stays the backup; Studio stays the source of truth.
   - Add this whole rule to CLAUDE.md so every future session follows it.
   - Tell me what you created and how you matched my other games' layout.
```
