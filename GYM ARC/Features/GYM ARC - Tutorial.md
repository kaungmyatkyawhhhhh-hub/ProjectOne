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
