---
date: 2026-11-03
tags: [gymarc, progress, gem, checklist]
status: for the owner, before publishing Fri 6 Nov
---
# GYM ARC GEM update - ready to publish Friday checklist

Back to [[00 GYM ARC Home|GYM ARC Home]] · Build log: [[2026-11-03 GYM ARC GEM update - verify and build]] · Event: [[2026-11-01 GYM ARC GEM update launch event (7 Nov)]]

Everything below is built and tested in Studio (3 Nov). **Nothing is published.** The update is switched ON (`Config/LiveEvents` Gem, `enabled = true`, Sat 7 Nov 15:00 UTC). Before that time players see the game exactly as now, plus the countdown 24 h before.

## Before you publish
- [ ] File > Save, and Download a Copy to `Documents\GymArc_backups\`.
- [ ] Play once in Studio as yourself (not a test save): no red errors in Output.
- [ ] No test switches left on: Workspace attributes `TestHallOfFame`, `TestStars`, `TestHallLevel`, `FreshPlayer`, `TestLaunchIn`, `TestPhoneSize` are all off (checked 3 Nov). `TestCrews` is on: it was there before and isn't mine. Check it's meant to be.
- [ ] ReplicatedStorage has no `LaunchDone_Gem` attribute (it must be set only by the server at launch).
- [ ] Creator Hub > Configs: `Launch_Gem_Enabled` not set to false; `Launch_Gem_Time` empty (or "2026-11-07 15:00").

## What changes for players (after Sat 15:00 UTC)
1. Gem Mine opens (Alter 15+), Alters 16-20 with their crystal looks; Alters 1-15 get glow / particles / footsteps; Settings "Alter Effects".
2. Hall of Fame becomes a choice (ENTER NOW / KEEP GOING); from Alter 20 it gives 2★ + 2 Legacy cards.
3. Story chapters 7-9 in the Gem Mine (Flint, Ruby, Onyx); Vince's ending now points there.
4. Star Track: Legacy cards shown, auto Growth Spurts from ★2, Star Belt + Wraps at ★4, profile frame + gold statue base at ★6, the Hall of Fame Agency is pointed out at ★3.
5. NEWS entry, launch cutscene, GEM RUSH title + 30 min boost for players online at launch.

## Live bug fix in this publish
- Hall of Fame TOP 10 board: the cheat rule kept a real ★7 player off; writes on join / star / leave with retries. [[2026-11-03 GYM ARC Hall of Fame board bug fixed]]

## Tested (Studio)
- Fresh save; Alter 15 test save through 16, 17, 19, 20 (test switch); every Hall of Fame card state (before the update, goal met / not met, Alter 20).
- The event flip with a test time (countdown, cutscene, unlocks live on a running server).
- Phone 667x375 for the choice screen.
- Story 7-9 start to finish; rep burst on a Gem machine; Road / Alters tab after the flip; agency card / dot / desk; star 4 and 6 rewards; auto spurt.

## NOT tested (be aware)
- **FPS with 10+ players in the Gem Mine.** Studio can't run that many clients here. Lights were cut 14 → 8 and every look follows the budget, but please do a quick live check after the launch.
- A real full timed run for the FASTEST RUN board, and the board rows (DataStores in Studio).
- Voices for the new bullies (voices are off for the whole story).

## Open questions for the owner
See the chat (3 Nov): faster runs per star, the alter-skip number, Flint's Gem posing division, auto spurt star, the new bullies' outfits.
