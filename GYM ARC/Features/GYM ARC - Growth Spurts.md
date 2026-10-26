---
date: 2026-10-13
tags: [gymarc, feature]
status: done
---
# GYM ARC - Growth Spurts

Back to [[00 GYM ARC Home|GYM ARC Home]].

The rebirth system (never called "sacrifice"): when all 6 muscle groups hit the goal, muscles reset, you get taller and earn a permanent gains bonus. Height stops at exactly 7'0".

## How it works
- **Start:** Growth Spurt 0, 4'0" tall (release setting since 9 Oct).
- **Goal:** every group must reach the required level. The first one is 50,000 EXP per group and takes about 8 minutes.
- **Stages:**
  - 1: 4'6", gains x1.25
  - 2: 5'0", x1.5 (opens the pro gym)
  - 3: 5'6", x1.75
  - 4: 6'0", x2
  - 5: 6'6", x2.5
  - 6: 7'0", x3 (the last one)
- **Pacing targets:** 5, 10, 18, 28, 38 minutes per spurt (26 Oct, was 5/15/25/35/45). Goals 9 / 35 / 68 / 113 / 163 / 197 (tests/pacing tune). Milestone coins at 25/50/75%: 2 minutes of coins. See [[2026-10-26 GYM ARC Retention pass]].
- **What you get:** taller body, permanent bonus, +1 DNA Token. Muscles reset to 0. A "you grew" moment plays.
- **7'0" cap (13 Oct):** no spurt ever goes past 7'0". At the cap the button reads "MAX GROWTH SPURT REACHED" (greyed, not pressable, nothing charged), heights show "7'0" (MAX)", and muscles keep growing. Old saves past spurt 6 are shown at 7'0".
- **Unlocks by spurt:** beach gym at 1, pro gym at 2.
- **Progress bar:** an always-visible Growth Spurt bar at the top with a "next goal" line.

## Where it lives
- `Config/GrowthSpurts` (`MaxHeightInches = 84`, `Stages`, `Targets`)
- `Server/PlayerData` (GrowthSpurt), `Server/BodyService` (height), `ProgressClient`, `StatsClient`
- Tests: `tests/pacing`
- Numbers: [[GYM ARC - Config values]]

## Known issues
- After about 11 spurts each spurt takes longer (the 5x multiplier cap). With the 7'0" cap there are now only 6 spurts, so this mostly no longer applies.

## Planned change
- Monetization prompt: a "Skip Growth Spurt cooldown" product, only if there is a cooldown (there is none today) and never past 7'0".

## Related
[[GYM ARC - Muscles and Bodies]], [[GYM ARC - Stats and Muscles Panel]], [[GYM ARC - Town and Gyms]], [[GYM ARC - Titles]]

## Screenshots
![[GYM ARC/Screenshots/full_spurt_ready.png]]
![[GYM ARC/Screenshots/full_spurt_done.png]]
![[GYM ARC/Screenshots/s1_you-grew_after.png]]
![[GYM ARC/Screenshots/body_7ft_max_front.png]]

## Players past the height cap (14 Oct)
Some old saves had more Growth Spurts than the last one (6, which reaches 7'0") from before the cap existed. When such a save loads, once: every one of the 18 muscles gets +10,000,000 EXP and the Growth Spurt count goes back to 6. It can't happen twice, because the save isn't past the cap any more. (Spurt 7's gains bonus x3.5 becomes spurt 6's x3.0.) Tested on the owner's save.

## Rules
- **No growth spurt cooldown.** A player can do the next Growth Spurt as soon as they've earned it (owner, 14 Oct). Checked: no timer or time check exists in the code; the Skip Growth Cooldown product was removed.

## At 7'0" (15 Oct)
No Growth Spurt card on the HUD at 7'0" (owner): the top bar's "7'0" MAX" says it. The Stats panel keeps its greyed "Max Growth Spurt reached" button.

## What it needs, READY popup, faster first spurt (21 Oct, prompt 20)
- First Growth Spurt goal: level 15 -> **9** (about 5 min); spurt 2: 58 -> 56 to keep its 15 min with the new stamina. `GrowthSpurts.Targets` = 5, 15, 25, 35, 45 (tests/pacing passes). The EXP scale stays (level 15 = 50,000 EXP), so the first goal now shows about 24,700 EXP.
- The card says what's behind: "62% · Needs LEGS" (groups at least 15% behind the best one). A tap opens **Train next**: the machines for those groups with a GO button each (a glowing path to the nearest free one). On a machine a small card at the top left shows the same.
- On a machine that doesn't train the groups that are behind: one hint, "Your legs are holding you back. Try the Squat Rack."
- The Body Map colors the needed groups red.
- When the spurt is ready: a big **READY TO GROW!** popup (sound, glowing TAP TO GROW, Later), over the machine HUD too. Tapping it on a machine gets you off, then grows.

![[GYM ARC/Screenshots/playtest_fixes/train_next_window.jpg]]
![[GYM ARC/Screenshots/playtest_fixes/ready_to_grow.jpg]]

## Card outline (23 Oct, prompt 58; [[2026-10-23 GYM ARC Growth Spurt card quiet outline]])
The GROWTH SPURT card (right column) and the machine strip are quiet chrome cards: the HUD cards' own 1.5 px outline tinted in the Growth Spurt gold (the TAP TO GROW gold; the strip uses the next alter's colour in alter mode). READY = the same dark card with TAP TO GROW in gold and the outline doing the ready glow (`Shared/UI/ReadyGlow`); no loud gold button any more. The READY TO GROW popup is unchanged.

## Gym ladder and unlock list (23 Oct, prompt 58; [[2026-10-23 GYM ARC Pro Gym lights and Powerlifting Gym]])
- Gyms: Beach at 1, Pro at **3** (was 2), Powerlifting at **5**; no gym at 2 and 4. The "Growth Spurt!" moment adds a gold line with what opened (`GrowthSpurts.Unlocks`, e.g. "NEW: TRAINERS · ARM WRESTLING · REGIONAL SHOW").
- The card says "Next: Pro Gym" / "Next: Powerlifting Gym" when the next spurt opens a gym.
- Spurt 6 goal **216 -> 238** (the Powerlifting tiers had made it 41 min; 45.0 again in tests/pacing).

## Milestone rewards (21 Oct, prompt 11; [[2026-10-21 GYM ARC Funnel fixes]])
- At 25%, 50% and 75% of the goal bar (the same share the HUD shows): a popup ("Growth Spurt 1: 50%, +14 coins"), a sound and a few coins (half a minute of coins at your stage). At 75%: "Almost there!". Every spurt, not at 7'0" (alters have their own).
- `Config/GrowthSpurts` Milestones / MilestoneCoinMinutes / Share, `Server/SpurtMilestoneService` (checked after reps, data.spurtMilestones), popup in ProgressClient.
![[GYM ARC/Screenshots/funnel_fixes/milestone_75.jpg]]

## LVL never drops (26 Oct; [[2026-10-26 GYM ARC Endgame and first Growth Spurt pass]])
- The top bar's LVL = average muscle level + `stats.levelBase` (the levels each Growth Spurt / Body Alter reset), `Muscles.Lvl`. After a spurt it stays where it was instead of going to 0. Auras, guides, crew list and the LEVEL board use the same number.
