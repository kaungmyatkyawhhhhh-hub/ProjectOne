---
date: 2026-10-20
tags: [gymarc, prompt]
status: done
---
# 11 Funnel fixes

Back to [[00 GYM ARC Home|GYM ARC Home]]

Funnel (530 new players, 20 Oct): 66.6% finish the tutorial, but only 31.5% reach the first Growth Spurt goal. Biggest drops: step 14 Growth Spurt goal (52.7% lost), step 6 drank the free shake (16.4%), step 3 walked to the Flat Bench (12.1%).

```text
Fix the 3 biggest drops in the new-player funnel. Follow CLAUDE.md Speed rules. Mobile first.
Data (530 new players): 66.6% finish the tutorial, but only 31.5% reach the first Growth Spurt goal.

1) STEP 13 -> 14: GROWTH SPURT GOAL (52.7% LOST, BIGGEST)
Half the players finish the tutorial and leave before their first Growth Spurt. It takes too long and nothing changes on the way.
- First measure: average time from "tutorial finished" to "Growth Spurt goal reached" for a new player with no passes. Report it.
- Target: first Growth Spurt within about 4-5 minutes of normal training after the tutorial. Lower ONLY the first goal (and maybe the second); keep later goals as they are.
- Show progress all the time: a gold progress bar "Growth Spurt 63%" near the top (Black + Gold, collapsible like the other panels, fits on phones).
- Small rewards on the way: at 25%, 50% and 75% give a popup, a sound, a few coins, and a visible body change, so players see they are growing.
- At 75% show "Almost there!" with a pulse on the bar.
- Log new funnel steps: 13a goal 25%, 13b goal 50%, 13c goal 75%, so we can see where they stop next time.

2) STEP 5 -> 6: DRANK THE FREE SHAKE (16.4% LOST)
- Check on a phone layout that the shake button is visible and not hidden behind the topbar or another panel (this overlap was reported before).
- When stamina runs low in the tutorial: show a big pulsing shake button with a hand/arrow pointing at it, and pause stamina drain until they drink it.
- If they don't press it within 8 seconds, show "Tap the shake!" again. After 20 seconds, drink it automatically and continue.

3) STEP 2 -> 3: WALKED TO THE FLAT BENCH (12.1% LOST)
- Measure the distance and walk time from spawn to the Flat Bench. Spawn new players closer, or move the tutorial bench, so it takes under 5 seconds.
- Add a glowing gold Beam path on the ground to the bench and a "Go to bench" button that auto-walks the player there (Humanoid:MoveTo).
- Check join load time on mobile: no long freeze before the player can move (the shop and loading screen were slow before). Load shop and other heavy UI after the tutorial starts, not before.

Don't change step names 1-15, so the funnel stays comparable. Write a short progress note in the vault with the time measurements.
```

## Owner update (21 Oct, given while prompt 25 ran; do after prompt 26)
```text
For prompt 11, skip everything prompt 20 already did (the tutorial shake + auto-drink, the first Growth Spurt timing, the ready popups). Don't change those.
Only do what's still missing:
1) Small rewards at 25%, 50% and 75% of the Growth Spurt bar (popup, sound, a few coins), plus the new funnel steps 13a/13b/13c. Keep the 15 funnel step names unchanged.
2) The walk to the Flat Bench: spawn new players closer (under 5 s walk) after the new starter gym layout from prompt 26, a gold Beam path to the bench, and a "Go to bench" button that auto-walks there.
3) Load the shop and other heavy UI after the tutorial starts, not on join.
Then mark prompt 11 done.
```
