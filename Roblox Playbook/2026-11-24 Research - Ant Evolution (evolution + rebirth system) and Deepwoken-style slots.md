---
tags: [research, mega-bite, ant-evolution, deepwoken, slots, rebirth, ui]
date: 2026-11-24
---
# 2026-11-24 Research - Ant Evolution (evolution + rebirth system) and Deepwoken-style slots

**Why:** Zev's list (relayed by the owner, 24 Nov 05:52):
- "just work on the uis, evolution tree and fossilize"
- "copy ant evolution system, but entire, but use it as a reference"
- "ill make the models and world map"
- "add slots on the game like deepwoken"
- "make the starting ui like play the game option"

Build log: [[2026-11-24 MEGA BITE - Title screen, slots, Evolutions window, fossil sharks]].

## Ant Evolution (Roblox)
- **Basics:** by the group "tiny ants to big ants". Out Oct 2026, peak about 38K CCU, 4.7M visits by mid-Nov.
- **Sources:** guides on allthings.how and beatcopgame/roonby; videos ump35kXfQ40, acSkwNMR--Y and i_Mp8oStspI, watched as frames in Chrome.
- **Screenshots:** in `MEGA BITE/Art/UI/Evolutions/`.

**Core loop**
- The ladder runs Ant Egg → Larva → Baby → Worker → Carpenter → Leafcutter → Soldier → Trap-Jaw → Bullet → Army → Bulldog → Siafu Warlord → Titan → Queen → Emperor → Cosmic (16).
- Rebirth adds more stages: Solar (17), Void (18), Star Dragon (needs Rebirth 6), and Omega.
- Each form has its own **Power bar**, filled by orbs, bugs and kills.
- When a bar is full, an **EVOLVE** button appears (HATCH for the egg).
- Some forms bring a Q move, shown with a NEW MOVE prompt.
- If another player eats you, **you drop one stage**.
- Fights are blocked when ants are 3 or more stages apart ("Too small to fight!").

**HUD**
- Top centre: the Power bar, with the current form's icon on the left and the next form or rebirth egg on the right, plus "COSMIC ANT 16/16 4x POWER" and a "+28.8K" gain pop.
- Left: round wooden buttons (STORE, MUTATE, PETS, **SPECIES**, REWARDS, TOP, SETTINGS).
- Top left: DNA, tokens and kills.
- Bottom: the HP bar and a kill streak.
- Bottom left: timers (next gift, Queen's Feast, 2x Power).

**EVOLUTIONS window** (from SPECIES)
- A wood frame with tabs **ANT LADDER / REBIRTH / BREEDS / BUGS** and "STAGE 11 / 18" at the top right.
- **Ladder rows:** a number circle on a spine, a round portrait, the name, stat chips (HP, a second stat, speed), and a status: ✓ REACHED, the current one, a lock ("STAGE 18 · EVOLVE TO FIND OUT"), or "REBIRTH 6" in purple.
- **REBIRTH tab:**
  - a purple banner: "Fill your top ant's bar, then hatch again as an egg with x1.25 power FOREVER. Every rebirth adds +0.25x and unlocks cooler ants!" with a SEE REBIRTH button;
  - then a "REBIRTH ANTS" list.

**REBIRTH panel**
- Title and a "1 REBIRTH" count.
- A purple band: the old and new multiplier (x1.25 » **x1.5**) with "POWER FOREVER", and reward chips: NEW: JADE BREED, +4,000 DNA, +1 MUTATION SLOT.
- Two boxes: ✓ **YOU KEEP** (DNA, mutations, pets, breeds, passes, ladders, codex) and **RESETS** (back to an egg, Power bar back to 0).
- "REACH THE SOLAR ANT AND FILL ITS BAR" with a STAGE 1/17 bar.
- The button reads REBIRTH X1.5, or NOT READY YET.
- **"TAP AGAIN TO REBIRTH!"** confirm, then a full-screen "REBIRTH! 1.5X POWER FOREVER UNLOCKED: JADE BREED" and a server-wide banner.

**Rebirth numbers**
- First rebirth: Cosmic at 1.08M → x1.25, Solar Ant, Bronze Breed, 2,000 DNA.
- Next: Solar at 3.696M → x1.5, Jade Breed, +4,000 DNA, +1 mutation slot.
- Rebirth 3 needs 5.346M.
- Rebirth 4 gives Obsidian Breed, x2.

**Mutations**
- Rolls cost 1 token or 120 DNA; x5 costs 5 tokens or 600 DNA.
- Pity: Epic+ at 25 rolls, Legendary+ at 100.
- Duplicates add stars.
- 1 slot to start. +1 slot at Rebirth 2, or with a 249 R$ pass.
- 31 mutations, e.g. Honeypot, Hunter, Swift, Winged, Razor Jaws, Vampire, and Phoenix (a revive with a 120 s cooldown).

## Deepwoken-style slots
- Deepwoken has character slots, each with its own saved character. The DevForum pattern: one account record + one record per slot (or a slots array) + the selected slot. Slot data loads only after the pick.
- Slayers 2 (a similar game): the main menu has PLAY / CUSTOMIZE / HUB / SLOTS. Each slot card has a red Reset under it, and extra slots cost Robux.

## What MEGA BITE took (and what it didn't yet)
**Taken (built 24 Nov):**
- the Evolutions window with a ladder plus a Fossilize tab;
- "fossil sharks" = Ant's rebirth ants (Dunkleosteus at Fossil I, Mosasaurus at II, Leviathan at III);
- the rebirth rule "your top shark + its bar full";
- the rebirth panel layout and the double tap;
- 3 save slots with a title screen.

**Not taken yet, to decide with the owner and Zev:**
1. **Dropping a stage when eaten.** The owner decided on 11 Nov that being eaten costs nothing, so this wasn't copied.
2. **A per-form EVOLVE button** instead of the auto-evolve with its cutscene.
3. **A stage-gap fight block.**
4. **A DNA currency with mutation rolls, pity and slots.** MEGA BITE has mutation cards.
5. **Pets.**
6. **Breeds as rebirth cosmetics.**
7. **Lost Eggs collectibles.**
8. **A TOP leaderboard button.**
