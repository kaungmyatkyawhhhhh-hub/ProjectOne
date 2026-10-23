---
tags: [gymarc, feature]
status: built
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# GYM ARC - Undiscovered items

Built 22 Oct ([[2026-10-21 GYM ARC Prompt - 31 Shops rework and undiscovered|prompt 31]]). Curiosity: what you haven't found yet is a dark tile with a "?", the name "???" and a small gray UNDISCOVERED. No name, no description.

## What counts as discovered
- **Alters** (Inventory > Looks > Alters): yours + the NEXT one. Tiers with no textures yet are not shown at all.
- **Auras** (Inventory > Auras): yours, the store ones (coins / pass) and the next one to earn.
- **Titles** (Inventory > Looks > Titles): yours + the next one in each category. Secret titles stay hidden until yours.
- **Trainers** (Trainers > My trainers): the ones you've had; the rest are UNDISCOVERED cards after yours.

## Counts, reveal, dots
- Each list says "x / y DISCOVERED".
- When something new is discovered: a red dot on its tab (and chip) until you open it; then its tile turns over with a gold burst, once.
- What you've seen is saved per list in `settings.revealed` (server checked in `PlayerData.SetSettings`). The first time (old players) everything you have counts as seen, so nobody gets a pile of reveals.
- Code: `Shared/UI/Discovery` (overlay, reveal, dot), used by `AltersPanel`, `TitlesClient`, `TrainersPanel`, `TrainerClient`.

## HUD NEXT alter card
"NEXT: TANNED" wears the next alter's theme (`Config/AlterThemes`): dark base in its colour, its accent edge, a thin strip of its background art, the name in its title gradient; "55%" white top-right; "TAP FOR WHAT TO TRAIN" small gray (`ProgressClient`).
