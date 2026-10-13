---
date: 2026-10-09
tags: [gymarc, feature]
status: done
---
# GYM ARC - Spotting

Back to [[00 GYM ARC Home|GYM ARC Home]].

Help another player lift: stand by their machine and click to push. They get a gains boost, you get coins.

## How it works
- **Asking:** tap or click a lifter's body for a small "SPOT" / X popup. The lifter gets a card "<name> wants to spot you" with ACCEPT / X (closes after 8 s). "Spot requests: On / Off" in Settings.
- **Up to 5 spotters.** More get "Spot full".
- **Spot types:**
  - **Hands** (flat / incline bench, squat rack, overhead press): spotters' hands under the bar, following it each rep.
  - **Hype** (other machines): a loose half circle in front of the lifter, clapping, pointing, fist pumps.
  - None on cardio.
- **Pushing:** click or tap anywhere on the screen (F on a keyboard). Moving or jumping stops spotting; EXIT button too.
- **Boost by spotter count:** x1.10 / 1.20 / 1.30 / 1.40 / 1.50, plus up to +0.15 when spotters are clicking (all clicking: 1.25 ... 1.65). Clicking = about 3+ pushes a second; at most 8 count; perfectly even timing (auto-clickers) is ignored.
- **Lifter sees:** "SPOTTED x1.35" in gold and the spotters' names.
- **Spotter reward:** coins every 10 lifter reps (5, +3 while clicking). Spotted reps count for the Spotter title.
- **Spotter feel ("more dopamine"):** click rings, a combo counter with milestones (10 / 25 / 50 / 100 / 200), a gold boost moment, a coins bar, a gold "ASSIST" over the lifter, coins flying to the coins pill, and a wrap-up note.
- All checks on the server.

## Where it lives
- `Config/Spotting`, spot types in `Config/Machines`
- `Server/SpotService`, `SpotClient`, builder `tools/builders/SpotPoints`
- Tests: `tests/spotting`
- Sounds SpotPush, SpotBoostOn, SpotCombo, SpotAssist, SpotPayout are placeholders (see [[GYM ARC - Music and Sounds]])

## Known issues
- Not yet tested with two real players (only solo with simulated messages).

## Planned change
- New features prompt: "Spot another player 2 times" as a daily quest, with another way to finish it on an empty server.

## Related
[[GYM ARC - Machines]], [[GYM ARC - Gains and EXP]], [[GYM ARC - Settings]]

## Screenshots
![[GYM ARC/Screenshots/spot_request_card.jpg]]
![[GYM ARC/Screenshots/spot_hands_bench_middle.jpg]]
![[GYM ARC/Screenshots/spot_dopamine_combo_boost.jpg]]
![[GYM ARC/Screenshots/spot_dopamine_payout.jpg]]

## Avatar headshots (14 Oct)
Player pictures here are the real Roblox avatar headshot in a plain dark circle (the same look everywhere, see [[GYM ARC - Loading Screen and Menu]]).
