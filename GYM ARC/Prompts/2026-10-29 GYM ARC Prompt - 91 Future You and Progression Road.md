---
date: 2026-10-29
tags: [gymarc, prompt, retention]
status: todo (14 Nov, after 106 and 108 on 7 Nov)
---
# 91 Future You and Progression Road

Back to [[00 GYM ARC Home|GYM ARC Home]] · Why: [[2026-10-29 GYM ARC Why players stop grinding - research]] (about half of new players leave before the first Growth Spurt)

```text
GYM ARC: make the reason to grind OBVIOUS from the first minute. Follow CLAUDE.md and "Roblox Playbook - Rules for every game". Only the GYM ARC Studio. Read the notes first: Growth Spurts, Unlock Guides, Tutorial, Body Alters, Town and Gyms. Don't rebuild what exists (locked tiles, "Next: Pro Gym", READY popup, milestones, transformation scene). Never undo my manual Studio changes.

1) FUTURE YOU (HUD):
- Next to the GROWTH SPURT card, a small "NEXT YOU" preview: a 2D/viewport-free image or a cheap silhouette of the player's own avatar at the next height (gold glow), with the height ("4'4"") and what unlocks there (one line, e.g. "Beach Gym · Posing shows"). Tap = opens the Progression Road. Cheap on phones (no live 3D every frame).
- At 6'0" and in alter mode it shows the next alter tier instead.

2) [DROPPED 29 Oct: no extra tutorial step; prompt 106 owns the tutorial. Skip this item.] TUTORIAL "THIS COULD BE YOU":
- At the tutorial's goal step: Coach Dex points at Dante (or the nearest Hall of Fame statue): "This could be you. Every Growth Spurt makes you taller." A 3-second camera move to Dante and back, skippable, Camera.Focus every frame, calm with Reduced Motion. Must not add a new long step: total tutorial time stays the same or shorter.

3) PROGRESSION ROAD (one screen, menu tile + from the card):
- A horizontal road: Start 4'0" → Spurt 1 ... Spurt 6 (6'0") → Alter tiers (to 7'0" at Alter 15, later Gem alters). Each stop: the body at that stage (silhouette or the existing body art), height, gains bonus, and icons of what unlocks there (gyms, trainers, arm wrestling, shows, auras, gear, alters, Strongman Yard...). Read everything from Config (GrowthSpurts.Unlocks, Guides.Locks, alters), no hard-coded lists.
- You are here marker + progress % to the next stop. Locked stops greyed with "Reach Growth Spurt X". Done stops ticked.
- 2D UI with the locked UI kit (no placeholders), fits a landscape phone, scrolls.

4) Every locked thing in the game (tiles, gates, items, stations) shows WHEN it unlocks, using the existing Unlock Guides toast. List any that don't and fix them.

TEST: fresh player in Studio: the NEXT YOU card shows in the first 30 s, the Dante moment, the Road at Spurt 0 / 3 / 6'0" / alter. Phone-size screenshots. Analytics: custom events Road_Opened, FutureYou_Tapped. Progress note + update the feature notes.
```

## Added 29 Oct: the ladder unlock map + shorter tutorial
Plan: [[2026-10-29 GYM ARC Master plan - one ladder]]

```text
5) UNLOCK MAP (one Config table that the Road, locks, guides and the Growth Spurt moment all read): match the "Full feature list" table in the master plan exactly (3-4 things per step: Spurt 1 Beach Gym + posing / Trainers / Inventory; Spurt 2 arm wrestling + Regional Show / Champion Ladder / Power Jump; Spurt 3 Pro Gym + Pro gear / Auras (today's aura shop; it becomes the Aura Altar on 2 Jan); Spurt 4 National Show / Genetics; Spurt 5 Powerlifting Gym / Crews; Spurt 6 Body Alters; Alter 2 Strongman Yard; Alter 15 Hall of Fame). Features that aren't built yet (feats, Champion Ladder, Run Cards) just get their slot for later. Cancelled, don't add slots: skill tree, Champion Arena, rush hour, Star Perks. Existing players keep everything they already have. Show me a before/after table first.
6) TUTORIAL = train → grow → next goal only. Remove the skate tip step (skateboard stays usable, its guide waits until Spurt 2). Keep the funnel step names stable (add, don't renumber). The first-spurt time, the 4-step tutorial and the WELCOME BONUS come from prompt 106 (run it first, same update): keep 106's numbers, don't re-add steps.
7) BASKETBALL COURT: removed in prompt 104 (same update). Boost types: don't touch here (prompt 97).
8) ONE GAINS NUMBER: Stats / HUD show "GAINS x3.4" with 4 parts: BODY (spurts/alters/genetics), TRAINERS, BOOSTS, GEAR (+ BALANCED x1.1 chip when it's on). Same math as now, just shown simply.
9) MAXED, NEVER WASTED: if using a boost/item would add nothing because of a cap, its button says "MAXED: no effect right now" and Robux offers for it don't show while maxed.
10) DEFAULT LOOK: NEW players start wearing the white tank top (settings.top = the white tank); existing players keep what they wear; "MINE"/shirtless stays a choice at the clothing store mirror.
```
