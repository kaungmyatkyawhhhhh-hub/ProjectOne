---
date: 2026-10-26
tags: [gymarc, progress, retention]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-26 GYM ARC Retention pass

Prompt: [[2026-10-26 GYM ARC Prompt - Bugs, appeal, progression and retention]]. Game commit b19e616.

## Body changed with distance (fixed)
- Cause: the 20 Oct phone-lag "far look". On a device the game counts as low-end (graphics quality 1-3 by hand, or under 40 FPS for 5 s), your own body swapped to the low-poly stage meshes past 15 studs. Those were made on 19 Oct, before the owner's October body changes, so the quads, hamstrings and shoulders looked different.
- Fix: the swap is off (`MuscleClient` `FAR_LOOK_ON = false`). Your body is always the live meshes. Other players and NPCs still use the existing stage meshes (owner: "use the old poly stage meshes"; nothing regenerated or uploaded).
- Checked in Studio: same meshes near and far; RenderFidelity Automatic vs Precise made no difference.

## Bugs fixed
- **Daily quests:** finished but unclaimed quests (and the all-3 bonus) are now paid before the daily reset. They used to vanish.
- **Login streak:** survives one missed UTC day (`Economy.StreakGraceDays = 1`). The UTC day turns over at 4-5 PM in the US, so a kid playing every afternoon could lose the streak without missing a real day. The rules line now says "Miss two days in a row and it starts over."
- **Login popup:** used to be skipped for good if you were on a machine when it tried. Now it waits until you're off the machine and no window is open.
- **Coach Dex shop:** opens when the tutorial is done (owner rule: SHOP is never locked). It used to say "The shops open after a few minutes of training."
- **Genetics:** no R$ / 25,000 coin reroll offer during the tutorial (the button hides once the free reroll is used).

## Progression
- Growth Spurt targets 5/15/25/35/45 -> **5/10/18/28/38 min**. Goals retuned with `tests/pacing tune`: 52/92/132/191/238 -> **35/68/113/163/197**. The 1 -> 2 jump was 3x longer than the first spurt, and the middle spurts took 3-4 sessions each. 7'0" now takes about 2 h 20 of bot play (was 2 h 50); Body Alters unchanged (Tier 1 about 8 h, owner 24 Oct).
- Milestone coins at 25/50/75% of the bar: 0.5 -> 2 minutes of coins. The marks stay at 25/50/75 because the funnel steps 13a-c use them.
- `PumpShop.CoinsPerMinute` re-measured (`tests/pacing coins`): 55/84/119/179/255/304/328, was 57/110/152/200/220/222/328. Rolls and supplements are a bit cheaper at Spurts 1-3 and a bit dearer at Spurts 4-5.
- **Trainers open at Growth Spurt 1** (was 2), with **one free first roll** (saved flag `onboarding.firstTrainerRoll`; also given once to existing players at Spurt 1+ who never rolled). Spurt 2's unlock line now says 2ND TRAINER SLOT and GEAR.

## New retention hooks
- **Playtime gifts** ([[GYM ARC - Playtime Gifts]]): 6 a day for minutes played today (3 / 8 / 15 / 25 / 40 / 60). They pay by themselves with a popup naming the next gift. The last one is a free trainer roll.
- **Favourite prompt:** Roblox's favourite prompt once, after the first Growth Spurt, when you're off the machine (`FavoriteClient`).
- **Daily window:** shows the current streak and, once claimed, "TOMORROW: +X COINS". The claim toast says what tomorrow gives.

## Tested
- Play test: no new errors in Output. Playtime gift 1 arrived at 3 minutes ("+655 coins. Next: Protein Shake in 5 min").
- `tests/run_all`: 17 old tests fail (trainer odds changed 23 Oct, offline coins changed 22 Oct, leaderboard count). None come from this pass; the tests need updating.

## Needs the owner
- After a Growth Spurt every muscle goes back to 0, so the top-bar LVL drops and the body looks smaller. This is a core design choice. A lifetime LVL in the top bar would stop it looking like a loss.
- Roblox experience notifications ("your daily reward is ready") need notification strings made in Creator Hub first.
- A crew invite button (`SocialService:PromptGameInvite`) would bring friends in, but where it goes is the owner's layout call.
- More Body Alter tiers need textures (uploads), so the owner has to OK them first.
