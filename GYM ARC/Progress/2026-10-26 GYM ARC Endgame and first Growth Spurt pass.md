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
- Image ownership: the alter images (Tier 1 too) were on the owner's account, not the group: that is likely why Tier 1 skins never showed in the live game. Owner is importing `Downloads\gym_arc_altersor_group` (56 files: the in-use Tier 1-3 maps + the 5 Tier 1 popup backgrounds) to the group by hand; then the ids go into Config/Alters / AlterThemes and the skins are rebuilt.

## Daily reward notifications (26 Oct)
- Message id `c7200b38-2ab4-cc40-b4a3-8a0ab40d67fc` (owner). `Config/Notifications`, `Server/NotifyService`, opt-in prompt in `DailyClient` after the daily claim (once a session).
- A player who leaves is queued for the next UTC reset (+ up to 30 min); any live server sends it through Open Cloud. Not in Studio.
- **Needs the owner:** an Open Cloud API key (user notifications write, this experience) saved in Creator Hub > Secrets as `notify_key` (domain apis.roblox.com). Until then nothing is sent (one warning per server).

## Alter images moved to the group (26 Oct)
- The owner imported `Downloads\gym_arc_altersor_group` (56 images) to the group Myanmar Builders Club; Claude found them in the group inventory by name and swapped every id: 51 skin maps in Config/Alters (Tiers 1-3) and the 5 Tier 1 popup backgrounds in Config/AlterThemes. All 15 skins rebuilt in ReplicatedStorage.SkinStages. Clay checked on the body in a play test.
- Likely why Tier 1 skins never showed in the live game: the old copies were on the owner's account, not the group that owns the game.

## Alter backgrounds in (26 Oct)
- The owner imported the 10 backgrounds to the group; their ids are in Config/AlterThemes (`bgs`, alters 6-15). The popup, its ALTER button, the NEXT card and the overhead pill now show them. Checked: the Granite popup.

## Pacing with trainers (26 Oct)
`lune run tests/pacing trainers`: the sim now rolls trainers (every rep coin, the free first roll, one free roll per hour of play, evolutions, levels, slots 1/2/3, all four boosts). Median of 30 bot players:

| Step | Min | Total | Typical trainers then |
|---|---|---|---|
| Spurt 1 | 4.9 | 0h05 | none yet |
| Spurt 2 | 9.3 | 0h14 | Coach Rex + Coach Lou (BASE) |
| Spurt 3 | 13.2 | 0h27 | Rex + Lou (IRON-BORN) |
| Spurt 4 | 20.1 | 0h47 | Duke Ironside + Rex |
| Spurt 5 | 25.4 | 1h12 | Duke (IRON-BORN) + Rex |
| Spurt 6 (7'0") | 26.2 | 1h39 | Volta + Duke |
| Alters 1-5 | 25, 13, 13, 12, 11 | 2h52 | Duke (IRON-BORN), Volta x2 (3rd slot) |
| Alters 6-10 | ~11 each | 3h46 | Duke x2 (IRON-BORN) + Volta |
| Alters 11-15 | 11-12 each | 4h45 | Duke (BEAST-MODE), The Shadow, Volta |

With trainers the whole game is ~4 h 45 of perfect play (8 h 53 without). By 7'0" a typical player has +77% EXP and +20% progress; at the end +150% / +40%. Alters take only ~11-13 min each with trainers.
