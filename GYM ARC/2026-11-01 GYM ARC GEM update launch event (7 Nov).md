---
date: 2026-11-01
tags: [gymarc, update, live-event, gem]
status: decided
---
# GYM ARC - GEM update launch event, Sat 7 Nov 15:00 UTC (21:30 Myanmar)

Owner (1 Nov night): "for the sat 7 nov, the GEM update, we need to put a countdown like the hall of fame update and if we do that, we also need a new gym (yes?) and we need to make it automatic so that those things only happen when the countdown reaches 0".
Related: [[2026-11-01 GYM ARC Roadmap after the Gem update]], [[2026-11-01 GYM ARC Plan - Hall of Fame repeat value and alters 16-30]], [[2026-11-01 GYM ARC Alter skins - every alter special]], [[GYM ARC - Live Update Events]] (prompt 90).

## The system already exists (checked in Studio)
`Config/LiveEvents` has the Hall of Fame entry: `time`, `countdownHours` 24, `cover` (a cover over the building until 0), `cutscene`, `unlocks` list, `warmUp` (2x EXP the hour before), `reward` (Launch Day title + 30 min x1.5 boost), `openToast`, `lines` / `newLines` (popup for later joiners), `goTo`, `gatherMinutes`, Studio test attribute `TestLaunchIn`. The GEM update = a second entry, nothing new to invent.

## Decisions
- **Countdown: yes**, same as Hall of Fame: Sat 7 Nov 15:00 UTC, the countdown card 24 h before, warm-up hour (2x EXP), 10..1, live cutscene, reward (title "GEM RUSH" + 30 min x1.5), popup for later joiners, update code GEM. Real countdown to a real time (not a fake timer).
- **New gym: yes, the GEM MINE GYM** (a crystal cave gym). Reason: the Hall of Fame launch had a covered building to reveal; a big update needs something everyone can SEE in town before 0 (curiosity + the cover is the countdown's stage), and Alter 15+ players have no new place to train (Golden Era is the last gym, Alter 8). Kept SMALL (one floor, ~10 machines from the reusable kit) because the week is full.
  - Opens at Alter 15 (the Gem alters' players; Hall of Fame players get in from star 1 like Golden Era's rule), gains x1.30 (one step above Golden Era x1.20, VIP x1.25 stays a different kind of bonus).
  - The Gem story chapters (alters 16 / 17 / 19) happen here (Config/Story is per gym: one new Gem bully).
  - Locked look until 0: a cover / crystal shell over it with the countdown on it (like HallOfFameCover). Arrow + GO TO "GemMine" after 0.
- **Automatic: yes.** Everything visible flips by itself at 0 on every server through `unlocks`: GemAlters (16-20 reachable, Alter 15's MAX pill moves), GemMine (gym + door + arrow), RunCards (first picks), StarTrack (screen, star looks, fastest-run board). Before 0 none of them shows anywhere (no menu tile, no hint except the countdown card).
- Not behind the countdown: the save-version system (108) goes live with the publish (invisible), Future You + Progression Road ship mid-week (Road shows the Gem stops as "OPENS SAT" until 0, then real).
- Publish the build by Fri 6 Nov evening (locked); test the whole flip in Studio with `TestLaunchIn` = 60 s on a fresh save, an Alter 15 save and a ★1 save.
- Scope guard: alter effects on 1-15 move to 14 Nov (already allowed). If the Gem Mine isn't done by Thursday, the cover stays and it opens with 14 Nov (cover text "OPENS NEXT WEEK"), never half-built.

## Status (3 Nov)
- **Gem Mine Gym: built** in Studio (east block by the basketball court, the owner's choice), with its cover (tarp, barriers, board "OPENS SAT 15:00 UTC") and the launch flip tested. [[2026-11-03 GYM ARC Gem Mine Gym built]]
- Still to do for 7 Nov: the Gem cutscene (LaunchCutscenes.Gem), Star Track, Gem alters 16-20, then switch the event on (`enabled = true` / `Launch_Gem_Enabled`) and the full flip test.
