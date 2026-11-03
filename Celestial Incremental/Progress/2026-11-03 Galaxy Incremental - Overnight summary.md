---
date: 2026-11-03
tags: [galaxy, overnight, summary, progress]
status: all 6 parts built and tested in Studio; NOT published, NOT saved (File > Save is yours)
---
# Galaxy Incremental - Overnight summary (3 Nov, Claude Code)

From [[2026-11-03 Galaxy Incremental - Prompt - OVERNIGHT (alpha 2 + 3)]].
Place "Galaxy Incremental" (111654682859982, P&L Studios XP). GYM ARC was never touched.
Every part has its own note in `Progress\`, and all code is in the vault (`Code\friends-test\`, `Code\map\`), checked identical to Studio (23 scripts).

## What's done
| Part | What | Note |
|---|---|---|
| 1 ALPHA 2 | Pace 2M / Starfire x1.75; tutorial 1-7 checked + the Star Forge glows at the end; GUIDE BOOK (G); licensed sounds + music + MUSIC / SFX sliders; music cut in the Supernova | [[2026-11-03 Galaxy Incremental alpha part 2 - pace, tutorial, guide, sounds]] |
| 2 CODES + POTIONS | Codes window; ALPHA / GALAXY; owner console; x2 STARDUST / x2 COMETS potions with HUD timers, stacking by time | [[2026-11-03 Galaxy Incremental overnight part 2 - codes and boost potions]] |
| 3 PLAYERS NEAR YOU | Its own board next to the leaderboard wall (5 above, you in gold, 5 below); the wall shows the top 10 in 2 columns | [[2026-11-03 Galaxy Incremental overnight part 3 - players near you board]] |
| 4 PASS + BADGE | STORE window (E); x2 Stardust pass flow; Alpha Player badge + save flag; ONE config for every Creator Hub id | [[2026-11-03 Galaxy Incremental overnight part 4 - x2 Stardust pass and Alpha badge]] |
| 5 FUNNEL + PHONE | 8 custom events + the funnel; phone pass: row descriptions 6 px → 12 px | [[2026-11-03 Galaxy Incremental overnight part 5 - analytics and phone readability]] |
| 6 FULL CHECK | Fresh save to Supernova 2 with the bot, a manual pass of every window and board, no errors | this note |

## Part 6: the full check (fresh save, Studio Play)
- **The bot run:**
  - Supernova 1 at **441 s** (14 shards, rank SPARK).
  - Supernova 2 after another **197 s** (2.2x faster), 639 s in total.
  - Tutorial 7/7, Essence 7.
  - **All 3 bot runs tonight:** first Supernova at 392-441 s. That's **~9-10 min for a real player**, on target.
- **Manual pass, desktop:**
  - the 4 island boards (BODIES, STAR UPGRADES, TREE, INFO);
  - UPGRADES, TREE, GUIDE, STORE, CODES, SETTINGS, potions, the Supernova card;
  - the leaderboard wall + PLAYERS NEAR YOU;
  - the STAR SURGE bar.
  - **Earlier tonight on the phone frame:** every window measured (part 5).
- **Output:** no errors from the game. Analytics: the 7 funnel steps and the custom events fired.
- **Screenshots:** `Progress\screens\overnight\` (p2-p6) and `Progress\screens\2026-11-03-alpha2\` (17 shots).

## What you must do
1. **Listen once (5 min):** play in Studio with sound. Every sound is one id in `ReplicatedStorage.Galaxy.Sounds` (I balanced them by measurement, not by ear).
2. **Creator Hub (P&L Studios XP > Galaxy Incremental):** create these, then put the ids in `ReplicatedStorage.Galaxy.GameConfig`:
   - **Game pass "x2 Stardust"**, 249 Robux. Description: "All your stardust x2, forever. Stacks with potions and Star Surge." → `Passes.X2Stardust.id`
   - **Badge "Alpha Player"**. Description: "You played Galaxy Incremental during the Alpha. Thank you!" → `Badges.AlphaPlayer`
3. **Re-upload 10 images to P&L Studios XP** and swap the ids in `UIAssets`. They are test copies uploaded from Studio, like the sky ones on 2 Nov:
   - `Icons\rendered\icon_book.png`, `icon_potion_stardust.png`, `icon_potion_comets.png` → `icon.book`, `icon.potionStardust`, `icon.potionComets`
   - `UI\guide\guide_*.png` (7) → `guide.*`
4. **Nothing to upload for sound:** all of it is Roblox-licensed Creator Store audio.
5. **File > Save** (Studio), then **publish** when you're happy. Nothing was published.
6. **At full launch:** set `GameConfig.AlphaActive = false`.

## Owner answers (3 Nov): see [[2026-11-03 Galaxy Incremental - owner answers (comet floor, store art, studio code key)]]
1. **x2 COMETS:** keep twice as many, plus a 15 s floor (done).
2. **Pass and badge images:** rendered in Blender, in `Downloads\galaxy_store_art\`.
3. **Phone captions:** leave them for the alpha. Added to the 21 Nov update; they must be fixed before 28 Nov.
4. **Codes in Studio:** now use their own `studio_list` key (done, tested).
5. **Pace:** kept at 2M / x1.75.

## Open questions (with my recommendation) - answered above
1. **x2 COMETS:** I made it "twice as many comets" (more to tap). The other reading is "comets pay x2".
   - **Recommend:** keep twice as many. It's more fun, and the payout already scales with income.
2. **Pass and badge images:** none were made (no AI art rule).
   - **Recommend:** I render them in Blender in the icon style: the stardust star with an "x2" for the pass, a gold "ALPHA" medal for the badge. Say yes and I'll do it.
3. **Tiny captions on phones:** in UPGRADES and the tree window, short captions are still ~10-11 px ("ESSENCE", "SUPERNOVA 3" under locked tabs/tiles).
   - **Recommend:** leave them for the alpha. Fixing them needs a phone-only layout for those two windows (a bigger job). The row text that matters now reads at 12 px.
4. **Code console test:** Studio has API access here, so my console tests wrote 2 test codes into the REAL live code list for a few seconds. I removed them, and the stored list is empty again (checked).
   - **Recommend:** nothing to do. Just know that console commands in Studio change the live list.
5. **The pace:** run 2 went 1.8x faster in the first test and 2.2x tonight (the comets change it a little).
   - **Recommend:** keep 2M / x1.75 (both inside the target).
