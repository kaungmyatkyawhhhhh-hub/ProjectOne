---
date: 2026-11-10
tags: [gymarc, progress, bugs, retention, monetization]
status: in Studio, NOT published. One Play run: no script errors on startup.
---
# GYM ARC: like-ratio fixes built (10 Nov night, Claude in Studio)

Prompts:
- [[2026-11-10 GYM ARC - Why the like ratio fell (74 to 69) + fix prompt]]
- [[2026-11-10 GYM ARC - 1 hour playtest findings + fix prompt part 2]]

Owner: "ok fix all of it, my roblox studio is open".

## 1. The error flood / lag (part 1)
| Error (per day) | Fix |
|---|---|
| 98,956 re-entrancy `task.defer` + 8,323 `Kit` line 1421 | `Shared.UI.Kit` enforce: each label once (weak table), one pending fit at a time (`task.delay(0)`, not chained defers), size/text listeners dropped once the label is scaled |
| 9,556 `MachineHud fitNeeds` line 295 | busy guard + at most one deferred refit (sizes it changes no longer re-trigger it) |
| 2,477 `PreferredTextCap` parent locked | `TextSizeGuard`: dead label skipped, a destroyed cap is replaced (pcall) |
| 5,683 `StatsLabelsClient:623` clamp | min ≤ max guaranteed (both clamps) |
| 2,145 PBR texture failed | **not fixed**: no asset name in the error |

## 2. Robux traps
- **AUTO TRAIN button (non-owners)** now says **"Auto Rep (pass)"** with the lock. Owners still see AUTO TRAIN / AUTO ON. (It was always the pass; it looked free.)
- **Auto Rep card:**
  - auto-hides after 12 s;
  - a 2nd tap on the button closes it;
  - it closes when you walk;
  - the Offer layer is now **above** the tutorial layer (DisplayOrder 8 → 24), so its X works and taps can't land on the price by accident.
- **All offer cards:** price buttons ignore taps in the first 0.8 s. That's the misclick that opened the Roblox Plus prompt.
- **Starter / Premium Pack side card:** hidden until Growth Spurt 1 (the first ~5 min).
- **Coral's trainer lesson:** **1 roll** (the ROLL button) instead of "roll 10 times with X3".
- **Trainer roll reveal:** no near-miss. `RollReveal.Roller.tease` 3 → 0, so the names before the result are random, not rarer trainers.

## 3. Guidance
- **GO TO a machine now puts you ON it** (`MachineService.Enter`, called by GoToService after the fade). A dumbbell exercise opens the picker.
- **Arm-wrestle stools no longer seat you by touch** (`CanTouch = false`). Only OCCUPY seats you. This fixes walk-by and GO TO landings on the planche.
- **Tutorial CHEST step** goes to Push-Ups (else a flat bench), not the Planche (a SHOULDERS machine next to the arm-wrestle table).
- **Tutorial "Tap TRAINERS" repeat** (right after the Agency tour) now finishes by itself. The step number is unchanged, so saves don't move.
- **"Train next" window vs the card:** equal shares were sorted randomly. Ties now keep the group order, so both say the same muscles.
- **The INVENTORY coach line** no longer claims you have shakes.

## 4. Growth you can see
- **Physique window:** each row's % and grade = progress to the **next Growth Spurt** (fills, resets each spurt). It used to be the end-game look, so a new player was stuck at 0% / D. Header: "% = READY FOR YOUR NEXT GROWTH SPURT". The word is never "Beginner" after a spurt (Getting Fit at 1+, Athletic at 3+).
- **Growth cutscene:**
  - every part near the body (machines, props) fades out on your screen during the moment, then comes back (the camera was inside the barbell);
  - the line now says "TALLER! · Gains x1.71 forever" instead of "Muscles start fresh".

## 5. Popups / events / polish
- **"NEW: <update>" popup:** only for players who joined before that update launched.
- **POSING SHOW pill:**
  - hidden at 0:00 when no show runs for you (it sat on 0:00);
  - in the join window a tap joins (the runway YES) with a toast "You're in the show!".
- **Stats labels:** if the tutorial turned them on, they switch off by themselves after 8 s.
- **Your own trainer** fades to see-through while he's between the camera and you (new `TrainerCameraFade`).
- **FREE 1,000 window:** title "Favourite", wider (the long title ran under the X).

## Not done (needs the owner or art)
- **Boss fights** (Benny / Coral in ~8 taps, no win screen): a difficulty / design choice. Say if you want a 3-5 s tug of war + a win card.
- **Fewer Coach Dex dialogs** (~20 in 16 min): a rewrite of many tours. Kept for a later pass.
- **8 emote icons** (one placeholder icon): needs real pose art (ChatGPT prompts).
- **Silent coin drops** (−341 during auto): cause not found (weights are free in code); check the Analytics economy sinks.
- **Smaller items:**
  - the Trainers window X over OPTIONS;
  - the dark training dim;
  - the dark Pro Gym;
  - the treadmill seat;
  - the PBR texture.
- **"First click ignored"** on buttons was probably the test tool (clicks with no mouse move first), not a real bug.

## Owner
1. **File > Save** in Studio.
2. **Test on a new account:**
   - no Starter card before Growth Spurt 1;
   - AUTO button says "Auto Rep (pass)";
   - GO TO puts you on the machine;
   - walking past an arm-wrestle table doesn't sit you;
   - Physique % moves;
   - the growth cutscene is clean.
3. **Publish**, then after 2-3 days check:
   - Error Report (those errors ~0);
   - FPS back to ~50;
   - the funnel step 03 drop;
   - the like ratio.
