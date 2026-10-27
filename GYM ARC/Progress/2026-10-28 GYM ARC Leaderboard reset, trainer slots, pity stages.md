---
date: 2026-10-28
tags: [gymarc, progress]
status: waiting on owner
---
# Leaderboard reset, trainer slots, pity stages (prompt 79)

Back to [[00 GYM ARC Home|GYM ARC Home]]. Prompt: [[2026-10-28 GYM ARC Prompt - 79 Leaderboard reset, trainer slots, pity stages]]. Features: [[GYM ARC - Leaderboards and Statue]], [[GYM ARC - Personal Trainers]], [[GYM ARC - Settings]].

- **Leaderboards reset:** `Config/Leaderboards.StorePrefix` LB1_ -> **LB2_** (new, empty OrderedDataStores; the old ones are left alone). Every server writes each player's current values every 90 s and when they leave, so the boards refill with people who play again (no more old 7'4" entries).
- **Top 25, scrollable:** `Leaderboards.Top` 10 -> 25. `LeaderboardClient.scrollRows` moves each board's Row1..Row10 (built in Studio) into a ScrollingFrame in the same place and adds rows 11..25 (copies of Row10), on the client only. Tested with TestLeaderboards: 25 rows, 10 visible, scroll bar. Scrolling by touch on a phone still to be checked.
- **Trainer slots:** 2 for everyone; the Extra Trainer pass (2032496303) = 3rd slot; new `ExtraTrainer2` = 4th slot (`Config/Monetization`, id = nil, 149 R$ suggested: hidden until the owner gives its id). The old free slots (Growth Spurt 2, first alter) are gone. `Trainers.SlotPasses`, `BaseSlots`, `SlotsFor(passes)`, `SlotPassesOwned`, `NextSlotPass`; the gold + in the Trainers panel offers the next slot pass. The save still keeps up to 4 equipped, so nobody loses a trainer; extra ones just stop following until a slot opens.
- **Trainers near you:** Settings "Trainers Near You" 1 / 2 / 3 / 4 (`settings.trainersShown`, default 1) -> player attribute `TrainersShown` -> `TrainerFollowClient.bestEntries` draws that many of your equipped trainers (rarest first); the rest stay portrait chips. Other players see your choice too (unless Others' Trainers is off / Low Graphics).
- **Pity stages:** `Trainers.PityStages` = Legendary 50, Mythic 100, Secret 150; saved `trainers.pityStage`. A stage ends when you get its rarity or better (luck or pity), then the next stage starts at 0; after Secret, Legendary again. The pill reads "MYTHIC GUARANTEED IN 87 ROLLS". Old saves: stage 1 with their count kept (anyone at 50+ gets a Legendary on the next roll).
- Tested: pity sequence 50 / 150 / 300 rolls, lucky Legendary moves on, old save pity 70; slots 2 -> 3 -> 4 with the passes; followers 1 / 3 / 4 / 2 from the setting (FreshPlayer).
- **Owner:** create the 4th-slot game pass and send its id.
