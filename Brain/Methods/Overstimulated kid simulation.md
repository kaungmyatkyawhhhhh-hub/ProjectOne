---
tags: [brain, method]
created: 2026-11-13
---
# Overstimulated kid simulation

**Owner's words:** taught 13 Nov 2026 (Stomp Evolution: a boss kill fired DEFEATED + evolve card + AREA UNLOCKED + Coin Rain together); first run on Galaxy: "do the simulator on my galaxy incremental" (13 Nov)
**Use when:** a game's screen may get too busy: stacked cards / toasts / banners / sounds, "kids miss the important thing", before any launch or big update with new popups.
**Skill:** overstimulated-kid-sim (research: [[2026-11-13 Research - Overstimulated kids (UI overload, stacked popups)]])

## Steps
1. Read the LIVE client scripts: every emitter (toast, banner, card, cutscene, flash, shake, sound), its region, how long, what it waits for, its weight, KEY or not.
2. Put a logger in Play (DescendantAdded on PlayerGui for texts, Sound.Played for sounds) and fire the real chains with the Studio test switches. `execute_luau` runs in its OWN Lua copy: wrapping a module's functions there does nothing, so log instances, not function calls.
3. Python kid model on the impatient-kid sim's live timeline: slots 2 / 3 / 3.5 by age, reading 1.5 w/s at 7, 3 at 10; overload, missed KEY, collisions, noise, flash, blocked.
4. One change per version, cumulative; then build the fixes and fire the same chains again in Play.
5. Re-run the impatient-kid sim (spacing must not create dead time).

## Tools
- `Celestial Incremental/Calc/overstim.py` (imports kidsim / variants: run from the Calc folder).

## Output
- A note in the game's folder with the emitter table, version table, worst moment before / after, screenshots; the sim in `Calc`.

## Used on
- 2026-11-13 Galaxy: KEY messages missed at age 7 ~77% → ~1-2%, overload mid-game ~6 → ~0.4 s per 10 min, sound pile-ups 6 → 0 per kid → [[2026-11-13 Galaxy Incremental - Overstimulated kid simulation]]

## Learned
- The worst moment is where several systems END together (Galaxy: the last tutorial step = Ignition = the free Forge gift). Look for "X happens when Y finishes" chains.
- Shorter texts and a toast queue alone were not enough: the big drop came from ONE queue for every KEY message (toast, NEW card, tutorial card), paused by cutscenes and kid-paced cards.
- 6-year-olds miss most text in every version: they need icons, colour and sound, not words.
- Checking at a real phone size in Play found layout bugs the audit's fake device hid (the top bar counted twice).
