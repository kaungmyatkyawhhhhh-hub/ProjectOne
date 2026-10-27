---
date: 2026-10-08
tags: [gymarc, feature]
status: done
---
# GYM ARC - Tutorial

Back to [[00 GYM ARC Home|GYM ARC Home]].

The first 5 minutes, taught with glowing floor paths and one-line coach messages.

## How it works
- **Steps:** (no genetics reveal since 27 Oct) first lift on the bench, Beginner Gains title, stamina + a free shake, squat rack, stats, first quest from Coach Dex, the GROWTH SPURT card tapped (its "Train next" window), the SKATE button.
- **Guidance:** a gold path of chevron arrows on the floor to the next machine, a big gold arrow at the screen edge when the target is off screen, a glowing machine outline, one coach line at a time ("tap Occupy").
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
- A green SKIP TUTORIAL button sits under the band. Tap it twice to skip (the first tap turns it gold: "Tap again to skip"). Skipping gives no reward. (22 Oct, owner: it shows only after 5 s of play, counted from when the menu is gone and the genetics screen has closed.)
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

## Prompt 28 (21 Oct; [[2026-10-21 GYM ARC UI cleanup]])
- The shake step points at hotbar slot 1 (the DRINK SHAKE button is gone); tapping the slot drinks it. The Coach Dex dialog moves up above the hotbar while it shows.

## Quiet tutorial + teleport (22 Oct; [[2026-10-22 GYM ARC GO TO teleport, quiet tutorial, odds, grunts]])
- GO TO buttons teleport (GoToService); a small dark SKIP pill top-right; the target machine glows gold with a bouncing gold arrow; only its sign shows; no quest card, notices, item popups or offers until the tutorial ends (`UIBus.InTutorial`, `UIBus.AfterTutorial`). The Coach Dex dialog is unchanged.

## New UI and a clean screen (23 Oct, prompts 53a / 53; [[2026-10-23 GYM ARC Tutorial restyle and screen cleanup]])
- Coach Dex dialog: graphite + hex, thin gold outline, dark bottom edge; gold-framed live portrait; COACH DEX in gold chunky; the words in Montserrat Bold; a gold "+50" coin pill; "Tap to continue (1/2)". ~55% wide, fits its words (`Shared/UI/CoachDialog`).
- GO TO: normal ChunkyButton size at the bottom centre, 12 px above the dialog / hotbar / stamina bar.
- SKIP: a small dark pill under the top bar on the right, always there (`Shared/UI/SkipPill`); first tap gold "TAP AGAIN TO SKIP".
- Buttons a step needs (shake slot, STOP, Stats, Muscles): the Spotlight (`Shared/UI/Spotlight`): dim around it, gold glow, bouncing arrow + "TAP STOP".
- World marker: gold name + distance + diamond + chevron, kept under the top bar, hidden right next to the target (`GuidePath.Mark`).
- While it runs only the tutorial shows (plus coins, LVL, left nav, machine controls); the rest fades back after.
- The step band is a dark pill; toasts use the one lane at the top centre (`Shared/UI/Notify`).
![[GYM ARC/Screenshots/ui_v3/tutorial/phone_01_first_step.jpg]]
![[GYM ARC/Screenshots/ui_v3/tutorial/phone_04_tap_stop_lvl_up.jpg]]
- (owner, 23 Oct, option B) The shake step on a machine: "Tap STOP, then tap your free shake to drink it." with the arrow on STOP, then on the shake once off; the safety net waits 25 s.

## GO TRAIN after the tutorial (26 Oct; [[2026-10-26 GYM ARC Endgame and first Growth Spurt pass]])
- Funnel: 54% left between the end of the tutorial and the first Growth Spurt goal. Until the first Growth Spurt a gold GO TRAIN <GROUP> button sits at the bottom centre (off a machine, nothing else open); it teleports you to a machine for the group furthest behind (`ProgressClient`).
- The stamina step needs 10 reps (was 20). Finish toast: "Tap GO TRAIN for your first Growth Spurt!"

## First 15 minutes (26 Oct; [[2026-10-26 GYM ARC First 15 minutes, deals, invites, memory]])
- NEW PLAYER BOOST 2x EXP and coins for the first 15 min of play, announced by Coach Dex; +100 coins and "FIRST REP! YOU GOT STRONGER" on the first rep; the GROWTH SPURT card shows from the first second; 750 starting coins when the tutorial ends (skipped too).

## Prompt 68: clear and never stuck (27 Oct; [[2026-10-27 GYM ARC Tutorial fix and genetics at join]])
Tester: "confusing, breaks midway, should show everything with pathways and arrows". I played the whole tutorial as a new player first. What broke, and the fix:
- **Genetics reroll popped up on join:** gone. New players start at x1.00 genetics and PLAY goes straight into the tutorial (see [[GYM ARC - Genetics]]). The server puts them at the start spot on "TutorialStart".
- **GO TO COACH DEX put the player ON the front desk**, so his Talk button never showed. This was the "breaks midway". Now the spot is on the floor straight in front of him, past the desk (`Shared/GoTo` coachSpot). GO TO never stands you on furniture (`GoToService`). The Coach step also has a 60 s safety timeout.
- **Steps skipped themselves:** OpenStats and Goal timed out while the player was still lifting (reps go on their own), and the last steps ran behind an open window. Now a timeout or a "seconds" step only counts while the step can be done: the tutorial is on screen, no window is open, the player isn't teleporting, and they're off a machine unless the step is about the machine.
- **The hint vanished after 4 s:** the step's line now comes back in the top band every 12 s until it's done (on a machine too).
- **Coach box lost:** a step reached on a machine now shows its coach box once you step off.
- **"Open Muscles to see your Growth Spurt goal" didn't explain anything:** the Goal step now points at the GROWTH SPURT card ("TAP IT"). Its window says which muscles are furthest behind, with GO buttons. SKIP hides during that step, because the arrow sat on it.
- **Arrows:** the floor dots are now gold chevrons pointing the way, on a wider ribbon, snapped to the floor (they floated 1.6 studs up). While the target is off screen, a big gold arrow at the screen edge points at it; when it's behind you the arrow goes left or right ("turn this way"). It stays clear of the left nav, the right cards and the top bar.
- **First look:** the camera starts high behind the player so the arrow path to the Flat Bench shows (from the normal angle the player's body hid it).
- **Popup clutter:** during the tutorial these stay quiet: LVL UP, NEW WEIGHT UNLOCKED, NEW PERSONAL RECORD, Growth Spurt milestones, plain toasts and trainer cheer bubbles. Purchases and gifts still show. After the tutorial, unlock guides wait 45 s so "Tap GO TRAIN" gets the screen.
- Files: `Config/Onboarding`, `TutorialClient`, `Shared/UI/GuidePath`, `Shared/GoTo`, `GoToService`, `ActionService` (TutorialStart), `ProgressClient` (UIBus.SpurtTile / NeedsIsOpen), `Shared/UI/Notify`, `MachineClient`, `TrainerFollowClient`, `GuideClient`.
- Note: the gold marker over the target and the Talk prompt draw on top of everything. Studio's screenshot tool can't see those, so check them by eye.

## No skipping, no trainer (27 Oct, prompt 69; [[2026-10-27 GYM ARC Tires, NPC waists, rerack coins, plates, court]])
- Owner: "dont let players skip tutorial". The SKIP pill is gone, and the server ignores "SkipTutorial" (ActionService). Every step still has its arrows and a safety timeout, so nobody gets stuck.
- Owner: "yes, hide it during tutorial". Your own trainer is fully hidden while the tutorial runs (`TrainerFollowClient`: it stood between the camera and the bench on the first lift) and comes back after.
- (27 Oct, owner again: "dont let players skip tutorial") Also locked on the server: `PlayerData.SetTutorialStep` only accepts the next step, or Done from the last step, so a modified client can't jump ahead or to the end. Tested as a new player: jump to the end / to step 5 / SkipTutorial all refused, the next step accepted, no skip button. The old NEWS line "You can skip it too" was removed (`Config/UI`).
