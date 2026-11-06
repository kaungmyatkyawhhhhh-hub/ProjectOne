---
date: 2026-11-06
tags: [galaxy, progress, phase-2]
status: built and tested in Studio; NOT published, NOT saved
---
# Galaxy Incremental - Phase 2.5: the FORGE COLLECTION BOOK (6 Nov, Claude Code)

Step 2.5 of [[2026-11-06 Galaxy Incremental - Prompt - Phases 2 and 3 + trend changes]]. Checklist rows: **#62 #158 #247 #289 #438**.

## What's new
- **The book** (already 42 cores, dupes level 1-10):
  - A core you don't have is a dark "?".
  - A core at **MAX** shows a gold "M" and **leaves the roll pool**. When every kind of a rarity is maxed, that rarity's odds move to the rarer ones, by what they still hold.
  - Lune test: all 6 Commons maxed → Common 0%, Uncommon 62.5%, Rare 25%, Epic 10%, Legendary 2.25%, Mythic 0.225%, Celestial 0.025%, total 100%.
- **ODDS (YOUR NEXT ROLL):** the Forge shows the odds your next roll really uses, before any roll. They include your Luck cores, FORGE LUCK, FORGE MASTER and maxed cores, and always sum to 100%.
- **% complete:** total in the BOOK header ("17/42 · 40%"), and per rarity under each column.
- **A rarity's row complete =**
  - a **COLLECTOR title**: STAR FINDER, CORE HUNTER, RARE COLLECTOR, EPIC COLLECTOR, LEGEND KEEPER, MYTH MAKER, CELESTIAL ARCHIVIST
  - a gold trim round that column (the "card trim")
  - its **badge**: GameConfig.Badges.Collection<Rarity>, id 0 until you create them, so nothing is awarded yet
  - The best title shows **under your rank tag for everyone**, and in the BOOK header.
  - Rows completed before this existed count too.
  - Names are mine: change them freely.
- **Rarity colour ladder (#158):** grey / green / blue / purple / gold / red / **rainbow (Celestial)**, always with its name.
  - Mythic is red because the ladder in the plan has 6 colours for 7 rarities.
- **Sound ladder (#247):**
  - Common: pop
  - Uncommon: chime
  - Rare: 3-note rising arpeggio
  - Epic: whoosh + chime
  - Legendary and up: a held breath, then the boom + stinger
  - All from Galaxy.Sounds (licensed Roblox audio).
- **VFX ladder (#289):**
  - every roll: sparkles
  - Rare+: a ring pulse
  - Epic+: confetti
  - Legendary+: rays turning behind the core
  - Reduced Motion: sparkles only
  - The cutscene lengths by rarity (5 Nov) still play on top.

## Tests
- Studio test save: the window (screen `2.5-pc-forge-book-odds`).
- A BULK roll: the reveal card, plus "BOOK ROW DONE: STAR FINDER!" for the save's complete Common row; the title shows in the header (screen `2.5-pc-forge-roll-row-done`).
- Not seen live: the Legendary+ rays, and the sound ladder by ear (no Legendary rolled in the test).
