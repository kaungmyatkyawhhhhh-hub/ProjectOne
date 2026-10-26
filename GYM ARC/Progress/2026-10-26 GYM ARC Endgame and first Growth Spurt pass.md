---
date: 2026-10-26
tags: [gymarc, progress, retention]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-26 GYM ARC Endgame and first Growth Spurt pass

Prompt: [[2026-10-26 GYM ARC Prompt - Endgame and the open decisions]] (after [[2026-10-26 GYM ARC Retention pass]]). Game commit 87edcc8. Owner allowed uploads for this pass.

## What the funnel showed (owner's screenshots, 26 Oct)
- 6,829 new players. 57.6% finish or skip the tutorial, but only **26.4% reach the first Growth Spurt goal**: step 13 -> 14 loses **54%**. The other big steps: walking to the Flat Bench (11%), "stamina ran low" (12%), the free shake (9%).
- So most players leave in the first session, long before the end. The few who stay do reach the end: Tier 1 alters took ~2 h on the pacing sim (not the 8 h estimated on 24 Oct), then "Coming soon".

## First Growth Spurt
- After the tutorial nothing said where to train (the last tutorial step even sends you outside to skate). New: a gold **GO TRAIN <GROUP>** button at the bottom centre until the first Growth Spurt, off a machine, when no window / Coach Dex dialog / other GO TO is up. It names the group furthest from the goal and teleports you to a machine for it (the Train next window's GO). It steps aside for 12 s after a tap. `ProgressClient` (GoTrain gui).
- Tutorial stamina step: 20 reps -> **10** ("Do 10 more reps!"). Finish toast: "You're all set. Tap GO TRAIN for your first Growth Spurt!" (`Config/Onboarding`). The skate tip stays (owner, 14 Oct).
- Tested: fresh player, skip -> "GO TRAIN CHEST" -> one tap puts you at the Flat Bench's Occupy prompt.

## Endgame: Body Alter Tiers 2 and 3
- 10 new skins, our own procedural textures (`tools/alter_textures.py`, `Downloads\gym_arc_alters\tier2_stone`, `tier3_metal`): Clay, Sandstone, Granite, Marble, Obsidian; Bronze, Iron, Steel, Chrome, Gold. 37 images uploaded (color / normal / roughness, plus metalness for Obsidian and the metals).
- `tone = "Raw"`: they show their own colours (no skin tint). `SkinStages BuildAlters()` sets the metalness map. Popups use the tier colours (no background art yet).
- Pacing sim (`lune run tests/pacing alters 15`, bot play): Tier 1 ~2 h, Tier 2 ~2 h, Tier 3 ~2 h 40. About **6.5 h after 7'0"** (was ~2 h). Goals unchanged (205 +25).
- Tested in play: Granite and Gold on the body.

## LVL never drops
- LVL = average muscle level + `stats.levelBase`, the levels a Growth Spurt / Body Alter reset (`Muscles.Lvl`). Banked in `PlayerData.GrowthSpurt / Alter`; old saves get it once from the goals they met.
- Used by the top bar, menu card, LVL auras, unlock guides, crew list and the LEVEL board. LVL UP only past the highest LVL shown.
- Tested: LVL 15 before and after Growth Spurt 1 (was 0 after). Owner's save: Level 2054.

## Friends
- **Friend Boost:** +10% gains per Roblox friend in the server, up to +30% (`Config/Social.Friends`, `Server/FriendService`, BoostService source "Friends"). Toast "Maya is here! Friend Boost: +10% gains".
- **Invite:** Crew window row "Invite friends" (top when you have no crew, above Leave crew when you do); one Roblox invite prompt after Growth Spurt 2, after a "Train with friends" toast (`FriendClient`).

## Other
- Old tests updated to the current config (alters, offline coins, 8 boards, trainer odds): all 19 test files pass.
- `Config/Machines` comment: Pro Gym opens at Spurt 3.

## Needs the owner
- Tier 1 was set to "8 hours" on 24 Oct from an estimate; the sim says ~2 h. Kept as is (more frequent rewards); say if it should be slower.
- "Daily reward ready" notifications: Creator Hub > the experience > Engagement > Notifications: make a notification string (e.g. "Your daily reward is ready!"), then tell Claude its id. Sending also needs an Open Cloud API key saved as a secret.
- Image ownership: check in the Creator Dashboard that the 37 new images belong to the group like the Tier 1 ones, or the skins may not show in the live game.
