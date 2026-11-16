---
tags: [mm-outfit-catalog, build-log]
created: 2026-11-16
plan: "[[2026-11-16 CAC lessons - MM build list]]"
---
# Built: "Worn by N players" (build list item 6)

- **Not saved or published by Claude.** File > Save, then publish, is the owner's step.
- **Backup:** `ServerStorage.ScriptBackups.pre_WornBy_16Nov` (OutfitShowcaseServer, OutfitViewer).

## What it does
- The viewer's quiet line under the outfit name now reads **"ID 02 · 2 of 3 · Worn by 50.4K"**.
- **Hidden below 10.** "Worn by 2" reads as "nobody plays this"; the line only appears once the number helps.
- **Short numbers:** 1.2K, 50.4K, 3M.

## How it counts (`OutfitShowcaseServer`)
- **What counts as "worn":** a **whole-outfit Try On**. Trying one piece doesn't count.
- **Once per player per outfit:**
  - Each player's profile (the existing `MMShowroomProfiles_v1` record) gets a `worn` list.
  - Counting waits until the profile has loaded, so a returning player is never counted twice.
- **The global count:**
  - Stored in a new DataStore, `MMOutfitWorn_v1`, one key per outfit ID.
  - New counts are batched and written every 30 s and on server shutdown.
  - Reads are cached for 2 minutes. That's a few DataStore calls per minute, well under the limits.
- **Studio never writes either store**, same as the rest of the showroom; counts there live in memory only.
- `GetOutfitInfo` now also returns `WornBy`.
- **Studio-only test hook:** set the attribute `WornTestBoost` on `ReplicatedStorage.OutfitShowcase` to preview big numbers. It's ignored in the live game.

## Tested (Studio Play)
- Count 0 → Try Frost → 1.
- Reset and Try Frost again: still 1 (once per player).
- Trying a single Midnight piece: Midnight stays 0.
- At 1 the line stays hidden ("ID 02 · 2 of 3").
- With the test boost: "Worn by 50.4K" fits on PC and on Galaxy A06. Boost removed afterwards.
- 0 console errors.

![[Screenshots/2026-11-16 viewer - Worn by 50.4K (PC, test boost).jpg]]
![[Screenshots/2026-11-16 viewer - Worn by (phone A06, test boost).jpg]]

## Not tested
- The real DataStore writes. Studio doesn't write; this needs the published game.
- **Ideas for later:** show "Worn by" on the Featured cards, and use the count to sort a "Most worn" list (both CAC ideas).
