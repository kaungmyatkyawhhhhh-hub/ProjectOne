---
date: 2026-11-01
tags: [gymarc, roadmap, schedule]
status: current schedule (replaces the table in the whole game plan from 7 Nov on)
---
# GYM ARC - roadmap after the Gem update (1 Nov night)

Owner: "what are all the future updates after those". Built from [[2026-10-29 GYM ARC The whole game plan (research loop)]] (schedule + build status) and the 1 Nov decisions ([[2026-11-01 GYM ARC Plan - Hall of Fame repeat value and alters 16-30]], [[2026-11-01 GYM ARC Alter skins - every alter special]]).
Date fix: Saturdays are 7 / 14 / 21 / 28 Nov (1 Nov 2026 is a Sunday); earlier notes said 8 / 15 Nov by mistake, corrected.

## Checked in Studio (1 Nov night; owner: "i think most of these are already done, check again")
Studio "[HALL OF FAME] GYM ARC" (place 80031260599632), Config + script names + script_grep:
- **Already built (were on the old schedule):** Golden Era Gym (was 5 Dec, Round 47-50), gym agencies incl. the HALL OF FAME agency at star 3 (part of the Star Track), Storyline with 6 bullies (Benny, Coral, Dante, Hank, Magnus, Vince) + strength arm wrestling (covers the Champion Ladder idea), alter skip, alter pacing (GoalsVersion 6, TargetMinutes 75-115), first-minutes / tutorial v4 fixes, levels removed (EXP only), Runway judges, Winter season in Config/Seasons, real-player arm wrestling (ArmWrestleService: sit and wait for a player, or pick an NPC; Profiles CHALLENGE) + the Arm wrestling wins board (Config/Leaderboards ArmWins) - owner, 1 Nov: "isnt arm wrestling against real players aready done" = yes.
- **Not built (nothing in scripts):** Run Cards (`runCards` 0 hits), Star Track screen + per-star visuals + fastest-run board (Config/HallOfFame.Stars = text + EXP only), save dataVersion / PolicyService (108), Alters 16-30 (in Config/Alters.List but no textures, unreachable), alter special looks, Power Hour, rested gains, Future You / Progression Road, Feats (no Stomp/Power Jump), Aura Altar, Collection book.

| Date (Sat) | Update | What | Prompts |
|---|---|---|---|
| **7 Nov** | GEM | 108 save version + PolicyService, Run Cards, Star Track (agency exists: add the track screen, per-star looks, fastest-run board), Gem alters 16-20 with full looks + story chapters at 16/17/19, light/motion/sound on 1-15 | 108, 105, 101, new |
| **14 Nov** | ELEMENTS | Alters 21-25 (to 7'8"), shape pieces for alters 6-15, **Gem posing division** (owner 3 Nov: the reward for beating Flint in chapter 7; unlocked for everyone who already beat Flint), Legend Form colours + the ★10 LEGENDS wall if they slipped | new |
| **21 Nov** | LEGENDS (Alter 30) | Gate 1 read. Alters 26-30 (to 8'0"), Hall of Fame from 25 = 2 stars, from 30 = 3 | new |
| 28 Nov | POWER HOUR (Thanksgiving) | Power Hour + stronger aura visuals (friends and come-back already built; rested gains dropped) | 107 (Power Hour only), 102A |
| 5 Dec | MY ROAD | Gate 2. Future You + Progression Road (fixed prices already done) | 91 |
| Thu 10 Dec | Winter Lifts season | already in Config/Seasons: check it starts by itself | - |
| 12 Dec | FEATS (moved up; Champion Ladder cancelled, the storyline covers it) | Power Jump, Ground Stomp, Iron Grip Throw, Sprint Charge, Hype Roar, Flex Shockwave | 93 |
| 19 Dec | COLLECTION BOOK (moved up: winter break = most players online) | | new |
| 26 Dec | no release | gift code only | - |
| 2 Jan | AURA ALTAR | coin sink for holiday savings | 102B |
| 9 Jan | POLISH | sound, music, VFX (Audio API) | 100 |
| 16 Jan | open slot | boosts merge cancelled; economy already fixed 1 Nov | - |
| 23 Jan | no release | buffer | - |
| 30 Jan | open slot | decided from the data | - |
| Feb-Mar | from the data | Run Cards set 2, Hall of Fame agency 2, Lunar New Year (6 Feb), Easter (28 Mar), subscription decision | - |

## Notes
- Something new at alters 16/17/19 = Storyline chapters (same system as the 6 bullies). Champion Ladder (92) cancelled: the storyline does its job.
- Fallback each week: anything unfinished slips one week; never publish untested on a Saturday night; 10-15 min on a cheap Android before publishing.
- Hall of Fame stars from higher alters: 15-19 = 1, 20-24 = 2 (+1 Legacy card), 25-29 = 2 (+1), 30 = 3 (+2). Re-check the star curve before 21 Nov.

## Owner check 2 (1 Nov night): "isnt rested gains already done and friends. isnt economy + boosts merged into 3 already done"
Checked in Studio:
- Friends: DONE (FriendService Friend Boost +gains with friends in the server, invite boost, Profiles ADD FRIEND). Removed from 28 Nov.
- Rested gains: NOT built as planned (an EXP bonus after a break), but offline coins on return exist (RetentionService "While you were away: +N coins", Economy.OfflineCoins, Shadow aura +15%) + the come-back gift. Decision: drop rested gains (offline coins + come-back gift already do the come-back job; one system less).
- Economy: DONE ([[2026-11-01 GYM ARC Economy fix - coin faucets and boost prices]]).
- Boosts merged into 3: NOT done (Config/Boosts has 11 items: Shake, Coconut Water, Creatine, Protein Powder, Supplements, Pre-Workout, Mass Gainer, Elite Pre-Workout, Whey Isolate, BCAA Recovery, 2x EXP). Decision: CANCEL the merge: several are sold for Robux now and merging would change what players paid for (rule: never weaken what players own); the boosts bar already groups them. 16 Jan = open slot.

## VERIFIED LEFT LIST (1 Nov night, checked all at once in Studio: Config + script names + script_grep)
Owner: "ok now what is left for updates" (after "why did u not check at the first place": rule = check Studio + newest Progress notes BEFORE any built/not-built answer).
| When | Left to build | Evidence |
|---|---|---|
| 7 Nov | 108 save version + PolicyService | `dataVersion`, `PolicyService` 0 hits |
| 7 Nov | Run Cards | `runCards` 0 hits |
| 7 Nov | Star Track screen, per-star looks, fastest-run board | Config/HallOfFame.Stars = text + EXP/coins only |
| 7 Nov | Alters 16-20 + special looks; effects on 1-15 | Alters.List 16-30 have no textures; AlterSkinClient only puts the skin on |
| 14 Nov | Alters 21-25 + shape pieces 6-15; Gem posing division (Flint's chapter 7 reward, for everyone who already beat him: `stats.beatFlint` / `story.beaten.Flint`) | same; Flint gives coins + the Mine Breaker title for 7 Nov |
| 21 Nov | Alters 26-30 (8'0") | same |
| 28 Nov | Power Hour; aura visuals (rarity looks, walking power 0.15 -> 0.5); small 107 extras (party joins same server, break reminder) | `PowerHour`, `PartyId`, break reminder 0 hits; Auras.IdlePower 0.15 |
| 5 Dec | Future You + Progression Road | "Progression Road" 0 hits. (Fixed prices = DONE: prompt 103 done 30 Oct, snacks 150/500/1,500 fixed in Config/Style; coin packs scale with the buyer's own coin rate, never under 2,000/9,000/25,000, by the owner's choice 31 Oct "ok sure do coin pack scaling"; the Economy.Minutes lines left are old fallback code) |
| 12 Dec | Feats | no Stomp / Power Jump |
| 19 Dec | Collection book | none |
| 2 Jan | Aura Altar + equip preview | `Altar` 0 hits (only "Alter") |
| 9 Jan | Sound/music/VFX polish + Audio API | AudioPlayer only in StoryClient |
| 16 Jan, 30 Jan, Feb-Mar | open slots | |
