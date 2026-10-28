---
date: 2026-10-29
tags: [gymarc, progress, hall-of-fame, monetization]
status: done in Studio by Claude (not published; owner tests + publishes)
---
# Prompt 95 done: Hall of Fame fixes before launch (29 Oct)

Back to [[00 GYM ARC Home|GYM ARC Home]] · Prompt: [[2026-10-29 GYM ARC Prompt - 95 Hall of Fame fixes before launch]] · Feature: [[GYM ARC - Hall of Fame]]

Done directly in the GYM ARC Studio through the Studio connection (Claude Code wasn't used: Windows doesn't let Claude type into a terminal). **Nothing was published.** Remember: File > Save to Roblox, then Download a Copy to `Documents\GymArc_backups\GymArc_2026-10-29.rbxl`, then publish.

## What changed
| Item | Change | Where |
|---|---|---|
| Run 2 is fast | Star 1 = **x2 EXP + start at Growth Spurt 3**; every star faster: ★2 x2.25, ★3 x2.5 (+10% coins), ★4 x2.75 (GS 4), ★5 x3 (+20% coins), ★6-9 +0.25 each, ★10 x4.5 + GS 5 + LEGEND, then +0.15 a star. Never lower than the old table | `Config/HallOfFame.Stars` |
| Live tuning | Creator Hub Configs key **HallOfFame_EXPScale** (number, default 1, 0.25-3) scales every star's EXP bonus without a publish | `Config/HallOfFame.Perks`, `Server/LiveConfig` |
| Honest speed line | The ENTER screen says "**Run 2 is about 2x faster**" (x2 EXP from Spurt 3; a pacing estimate: ~7.75 h → ~3.7 h; the real number comes from SecondRun_Done) | `HallOfFameClient`, `Config/HallOfFame.RunSpeedText` |
| Peak height kept | Over-head tag: "**PEAK 7'0" ★1** <title>"; profile card height: "4'8" (PEAK 7'0")"; the peak is saved as `data.fame.peakInches` when entering | `TitleService`, `ProfileService`, `PlayerData.EnterHallOfFame`, `HallOfFame.PeakText/PeakInches` |
| ENTER screen | YOU KEEP line + the ARE YOU SURE card now say the peak height stays on your name and statue; the next star's reward stays shown (★N + perks) | `HallOfFameClient` |
| No cheaters as statues | `HallOfFame.Plausible(data)`: peak must have reached Alter 15, at least 3,000 reps per star, runs not impossibly fast; stars set from the console (`fame.admin`) always pass. Failing saves are removed from `LB2_HallOfFame`, never become statues, and are listed by `game.ServerStorage.Admin:Invoke("fame", "suspicious")` | `HallOfFameService`, `AdminService` |
| Analytics | `HallOfFame_Declined` (Not yet), `RunDone_Minutes` + `SecondRun_Done` (minutes between entries), `StarPlayer_Day` (once a day per star player), `Alter15NoStar_Day` (Alter-15 players who haven't entered), `HallOfFame_Suspicious`; `fame.firstAt` / `lastEnteredAt` saved | `HallOfFameService`, `PlayerData` |
| Trainer slots (never take away) | Anyone who had reached an alter (or a star) keeps the old free 3rd slot: `data.onboarding.legacySlot3` set once per save; slot passes add on top (max 4) | `TrainerService` |
| Starter Pack | **49 R$** in Config AND on Roblox (Creator Hub price changed 79 → 49, checked with GetProductInfo) | `Config/Monetization`, Creator Hub |
| Coin packs | **Fixed: 25 R$ = 2,000 · 99 R$ = 9,000 · 249 R$ = 25,000 (BEST VALUE)**, no more scaling by stage | `Config/Monetization` |

## Tested (Studio, test save never saves)
- Perks: ★1 "x2 EXP · Start at Growth Spurt 3", ★11 "x4.65 EXP · +20% coins".
- PeakText for a 7'0" ★1 save: `PEAK 7'0" ★1`; Plausible: 100 reps → refused, 50,000 → ok.
- Coin packs pay 2,000 / 9,000 / 25,000 at Growth Spurt 6.
- Full entry on the owner's Alter-15 test save: ceremony played, ★1, restarted at **Growth Spurt 3, alter 0**, over-head tag `PEAK 7'0" ★1  No Days Off`, `fame suspicious` empty, no errors in the output.

## Not done / for later
- "Legend Form" (wearing your peak height in the Hall and on the posing stage): skipped for Saturday (optional item; risky body change two days before launch).
- tests/pacing for run 2 wasn't run (it lives in the repo, not in Studio); read `SecondRun_Done` after launch and tune live with `HallOfFame_EXPScale`.
- The board's cheat check can only be seen working on the live game (Studio saves aren't persistent).
