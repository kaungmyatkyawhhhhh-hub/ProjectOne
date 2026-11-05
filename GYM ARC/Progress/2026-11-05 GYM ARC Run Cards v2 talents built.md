---
date: 2026-11-05
tags: [gymarc, progress, runcards, talents]
---
# GYM ARC - Run Cards v2: talents built (5 Nov)

Back to [[00 GYM ARC Home|GYM ARC Home]] · Prompt: [[2026-11-05 GYM ARC Prompt - Run Cards v2 FULL (talents, unique, every 2 alters)]] · Balance: [[2026-11-05 GYM ARC Run Cards v2 balance report]] · Feature: [[GYM ARC - Run Cards]]

In Studio only. **Not published.** Behind the GEM event like before (`RunCards.On`; Studio: `TestRunCards`).

## Owner's cap decision (built as asked)
- Tuned: Mind-Muscle perfect x1.5, Heavy Day MAX OUT = 15 reps, Unbreakable 25%, Lopsided Legend +40%, Iron Bond 15%. Card text = the real numbers.
- Safety net, visible: all talents together add at most +60% of your normal EXP over any 10 min. TALENT POWER meter in MY BUILD ("All talents together add up to +60% EXP") and a mini bar under the talent buttons ("+38% / +60% max", gold MAXED). (The window counts at least 150 of your plain reps, so right after joining a first MAX OUT isn't cut.)
- Recomputed: a normal 2 Rare + 1 Legendary build x1.49; the strongest 5-talent build x1.68 -> held at x1.6 by the net (x1.5 vs Commons); 90%-perfect players and late-run 11-card builds hit the net. Coins unchanged (x1.44). Estimates: measure real Mind-Muscle perfect rates in playtests.

## What changed
- **Rarities / odds:** Common 65 / Rare 28 / Legendary 7. Commons = the 10 stat cards (values unchanged). Rare / Legendary = the 15 talents. Epic and the % Rare / Legendary stat cards are never offered again.
- **Picks on odd alters only** (1, 3, 5...). Waiting picks stay. Even alters: "NEXT CARD AT ALTER n" after the transformation.
- **Unique cards:** a card held (this run + active legacy, by kind: a CLASSIC Chest_Rare holds Chest) is never offered; a Legendary only when its prerequisite is held (cards in the same offer don't count); an empty rarity rolls another; nothing left = 25,000 coins instead (`RunCards.EmptyPoolCoins`).
- **Legacy collection:** up to 3 active (only active ones count as held; a card you hold this run can't be switched on). Hall of Fame keep: cards already in the collection are greyed "Already in your collection"; a run of only collected cards = 1 DNA Token ("Enter (+1 DNA Token)").
- **CLASSIC:** old Rare / Epic / Legendary % cards and stacks keep working; "CLASSIC" on the card and in MY BUILD.
- **Card faces:** talents show the owner's 15 icons (uploaded on the owner's account like v5; ids in `Config/RunCards.Art.Types`), the rule in one line, "Requires: ..." on Legendaries, a gold shimmer border and the choir flip chord on Legendaries. ODDS screen updated.

## The talents (server-checked, `Server/TalentService`; screen: `TalentClient`)
| Talent | How it works in game |
|---|---|
| Second Wind | Out of stamina: BREATHE button, 3 taps 0.3-1.2 s apart = +60% stamina, reps work again; 90 s cooldown |
| Mind-Muscle | A timing bar on REP; the FIRST tap during a rep is judged on the server (62-95% of the rep, +-0.12 s): PERFECT = +0.5 rep, streak chip |
| Heavy Day | MAX OUT button (on a machine), every 2 min: +14 reps (15 in all), floor slam ring + thud for players near |
| Negative Reps | Hold REP 2.6 s: +2 reps (3 in all), costs 2 more reps' stamina; the server needs 2.3 s with no rep between; auto reps wait while you hold |
| Spotter's Call | SPOT prompt (F) on anyone lifting: they +10% EXP 30 s (one source, max +10% from all spotters), you get 10 reps' coins and +10% for 30 s per lifter spotted (max +30%); 30 s per lifter |
| Lucky Plate | 1 in 50 reps drops a glowing gem 8 studs away; walk over it: 15 reps' coins; 60 s, max 3 |
| Iron Lungs | SPRINT button (off machines) / double-tap W: walk x1.4, stamina refills x1.6; stops 2 s after standing still |
| Rest-Pause | Sit on any seat (not arm-wrestling / posing seats): refill x3; 3 s seated charges the next 15 reps +40% |
| Specialist | "Pick focus" prompt (R) at the Progress Mirror: +20% on that group; change once per alter |
| Adrenaline | A Body Alter or Growth Spurt: 30 s reps x2 speed, red screen edge + heartbeat thud; once per 3 min; never on Strongman stations |
| Titan's Grip | A new heaviest weight = "HOLD: PR!" (1.5 s, 20 s to do it): +24 reps (25 in all), orange floor cracks + a gold line in chat for the server |
| Golden Hour | Every 5 min: 30 s of 3x rep coins, gold screen edge + sound, "GOLD IN 4m" chip |
| Unbreakable | At 0 stamina reps go on at 25% EXP (and 25% coins) while the bar refills; not on Strongman |
| Lopsided Legend | With Specialist's focus at 2x every other group: +40% on it, and it grows up to 12% past the max size (MuscleRig "Overgrow") |
| Iron Bond | BOND prompt (G) on a Roblox friend near you: while both train within 20 studs, each rep gives the other 15% (never more than 15% of their own rep) |
- Never on Strongman machines; shows and arm wrestling read bodies, not EXP rates. Nothing hurts another player.
- TALENT column: next to REP (inside the machine HUD, follows REP on phone), bottom-up: TALENT POWER, buttons with cooldown shade, effect chips (FRENZY, 3x COINS / GOLD IN, REST-PAUSE xN, PERFECT xN, SPOTTED, BOND). Off a machine: bottom right (SPRINT, chips). Hidden under any window.
- Analytics: `Talent_Used` (talent id), plus the old RunCard_Picked.
- Studio switch: Workspace `TestTalent` = golden / frenzy / shard / pr / refocus.

## Tested (Studio, temporary save, TestRunCards; PC + phone layout)
- 3,000 offers: 0 duplicates / held cards; Legendaries only with their prerequisite (a same-offer bug found and fixed); empty pool -> nil (coins).
- Odd alters: alter 2 no pick, 3 one pick, an ALTER SKIP 3 -> 6 one pick; the offer opened by itself.
- Mind-Muscle: in-window tap PERFECT (+bonus, streak), early tap + spam nothing. MAX OUT 14.6 reps, cooldown shown. Hold REP (real button) slow rep. Out of stamina -> Unbreakable rep at 0, BREATHE x3 -> 6 to 97 stamina, recovering ended.
- Golden Hour (gold edge, 3X COINS 29S), PR attempt -> hold -> PR bonus + server PR message, TALENT POWER +38%. Lucky shard dropped and paid 300 coins (it dropped inside the pickup range: now 8 studs away). Sprint 16 -> 22.4, ends after stopping. Rest-Pause charge 15 (the nearest seat was the arm-wrestling stool: such seats now excluded). Adrenaline red edge, RepSpeed 2. Specialist focus Chest, second change refused.
- Pick window (talent faces, Requires, shimmer), ODDS, MY BUILD (TALENT POWER, talents, CLASSIC rows), keep window greyed + DNA Token fallback, CLASSIC Back_Epic still +35%.
- Fixed while testing: the talent column overlapped AUTO (moved next to REP); button labels pushed out by the cooldown shade; the stat bonus text shrank on cards; a server error on every pick (`emptyPaid`); the keep window's greyed cards; the bar showing over windows.
- **Not tested:** SPOT and BOND (need 2 players: the Studio tool runs solo), Lopsided's overgrow on the body, the Strongman exclusion live, a real phone, Mind-Muscle perfect rates of real players.

![[GYM ARC/Screenshots/2026-11-05_runcards_v2/05_pick_rare_legendary_common.jpg]]
![[GYM ARC/Screenshots/2026-11-05_runcards_v2/04_after_pr_lift_power_38.jpg]]
![[GYM ARC/Screenshots/2026-11-05_runcards_v2/11_phone_talent_column_golden.jpg]]
![[GYM ARC/Screenshots/2026-11-05_runcards_v2/07_my_build_talent_power.jpg]]
![[GYM ARC/Screenshots/2026-11-05_runcards_v2/08_my_build_classic_rows.jpg]]
![[GYM ARC/Screenshots/2026-11-05_runcards_v2/12_hall_of_fame_keep_collected_greyed.jpg]]
![[GYM ARC/Screenshots/2026-11-05_runcards_v2/06_odds_screen.jpg]]
![[GYM ARC/Screenshots/2026-11-05_runcards_v2/10_adrenaline_frenzy_red_edge.jpg]]
(All 13 in `GYM ARC/Screenshots/2026-11-05_runcards_v2/`.)

## Where it lives
`Config/RunCards` (Talents, odds, PickAt, HeldSet / Pool / OfferFrom, CollectionSet, TalentCap), `Server/TalentService` (new), `Server/RunCardService` (odd alters, unique, legacy, DNA fallback), `Server/MachineService.lift` (hooks), `Config/Gains.PerRep` (extraFor), `ActionService` (alter / spurt hooks), `MuscleRig` (Overgrow), `Shared/TalentInput` (new), `MachineClient` (4 hooks), `TalentClient` (new), `RunCardsClient` (faces, ODDS, MY BUILD, keep).
