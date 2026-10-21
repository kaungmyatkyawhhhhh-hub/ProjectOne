---
date: 2026-10-08
tags: [gymarc, feature]
status: done
---
# GYM ARC - Tutorial

Back to [[00 GYM ARC Home|GYM ARC Home]].

The first 5 minutes, taught with glowing floor paths and one-line coach messages.

## How it works
- **Steps:** genetics reveal, first lift on the bench, Beginner Gains title, stamina + a free shake, squat rack, stats, first quest from Coach Dex, the Growth Spurt goal shown.
- **Guidance:** a glowing path on the floor to the next machine, a glowing machine outline, one coach line at a time ("tap Occupy").
- **No shop or purchase prompts** in the first 5 minutes.
- **Replay:** Workspace attribute `ReplayTutorial` replays it on your own save; `FreshPlayer` plays as a new player.

## Where it lives
- `Config/Onboarding` (steps and coach lines), `TutorialClient`

## Related
[[GYM ARC - Genetics]], [[GYM ARC - Quests and Muscle of the Day]], [[GYM ARC - Studio Test Hooks]], [[GYM ARC - Loading Screen and Menu]]

## Screenshots
![[GYM ARC/Screenshots/s4_new-player-phone-small_after.png]]

## UI v2 change (13 Oct)
- Each step's short line shows in the top band (gone after 4 seconds).
- A green SKIP TUTORIAL button sits under the band. Tap it twice to skip (the first tap turns it gold: "Tap again to skip"). Skipping gives no reward.
- Coach Dex talks in a dialog at the bottom with his live portrait, "Reward 50 coins" and "Tap to continue (1/2)". There is no dialog while you are on a machine, so it never covers the machine controls.
- Finishing the whole tutorial now gives 50 coins.
- The last step now asks you to open the Muscles window (where the Growth Spurt row is).
![[GYM ARC/Screenshots/ui_compare_v2_11_tutorial_dialog_phone.jpg]]

## Never stuck (21 Oct, prompt 20)
- Shake step: "Tap the shake!" with a bouncing gold arrow on the DRINK SHAKE button (left of the stamina bar). After 15 s the free shake is drunk for the player and the tutorial moves on.
- Steps can have a `timeout` (Config/Onboarding): Open Stats and Open Muscles finish after 40 s anyway, and have an on-machine line ("Tap STOP, then...").
- No goal hints in the band while the tutorial runs (they used to give a different "next" step than the coach).
- The glowing path is now `Shared/UI/GuidePath` (also used by the Growth Spurt's GO buttons); it only leads to machines in gyms the player has opened.
- Re-test: tutorial done at 3:16 (was 8:10).

## Start in the gym, gold path, Go button (21 Oct, prompt 11; [[2026-10-21 GYM ARC Funnel fixes]])
- New players start the tutorial inside the starter gym (after keeping their genetics): since prompt 32 (old layout back) in the middle aisle at (-12, -64), facing the Flat Bench 16 studs away (`Config/Onboarding` StartSpot / StartFacing; ActionService GeneticsSeen).
- The guide path has a glowing gold ribbon on the floor under its dots (flat Beams, `Shared/UI/GuidePath`).
- A **GO TO FLAT BENCH** button (gold, above the coach dialog) walks the player there along the path (`GuidePath.Walk`, Humanoid:MoveTo); the label follows the step's machine ("Go to Squat Rack", "Go to Coach Dex"). Any steering takes over.
![[GYM ARC/Screenshots/funnel_fixes/start_gold_path_go_button.jpg]]
