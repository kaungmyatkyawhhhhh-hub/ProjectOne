---
date: 2026-10-22
tags: [gymarc, progress]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-22 GYM ARC GO TO teleport, quiet tutorial, odds, grunts

Prompts: [[2026-10-22 GYM ARC Prompt - GO TO buttons teleport]] (+ the owner's tutorial follow-up in it), [[2026-10-22 GYM ARC Prompt - Agency odds board fixes]], [[2026-10-22 GYM ARC Prompt - Lifting voices grunts]]. Features: [[GYM ARC - Tutorial]], [[GYM ARC - Personal Trainers]], [[GYM ARC - Music and Sounds]].

## GO TO buttons teleport
- Every GO TO button (the tutorial's "GO TO FLAT BENCH / SQUAT RACK / COACH DEX", the Growth Spurt "Train next" window's Go buttons) teleports: a 0.3 s fade to black with a whoosh; the server (GoToService) checks the target (a real machine id or the Coach, in a gym you've opened), a 3 s cooldown, gets you off your machine first, finds a clear spot on the floor in front of the nearest free one (tries around it if blocked) and turns you to face it; the camera turns to it too; fade back in. The GO TO button then steps aside (it sat over the machine's Occupy prompt). If a teleport can't happen, the glowing path shows as before.
- Shared logic: `Shared/GoTo` (the client's glowing path and the server use the same machine and spot).
- Prompt 37's "gold ChunkyButton" isn't built yet (37 is on hold), so the GO TO button stays the kit's gold button.

## Tutorial (the owner's follow-up; the Coach Dex dialog is unchanged)
- During the tutorial: no "Today's quest" card, no season / Muscle of the Day notices (they show right after it), no "Added to inventory / USE NOW" or item notes, no offer cards, no machine labels or "!" except on the step's target machine.
- SKIP TUTORIAL is a small dark SKIP pill top-right (left of the right column; still after 5 s of play; tap twice: "Sure?").
- The target machine has a glowing gold marker (a soft gold glow, a gold outline) and a gold arrow bouncing above its sign, for the whole step.

## Agency odds fixes
- Secret (The Shadow) and Eternal (Atlas) are hidden until you own them: a black silhouette with a rim in the rarity color, "???" in the tooltip and in other players' pull messages; the cork board at the stand covers both cards.
- Every chance is a percentage (`Trainers.ChanceText`): 50% / 30% / 12% / 5% / 2% / 0.6% / 0.15% / 0.035%. (Common is really 50.215% so the 8 add up to 100; it shows as 50%.) The My Trainers tab only lists trainers you own (its locked tiles are slots), so nothing to hide there.

## Lifting voices
- The screams are gone. A short strained grunt from the lifter's head, only on heavy reps (85%+ of the heaviest you can lift there): every 5th heavy rep, and a new personal record; never a light rep, 3 s cooldown. 40% of the old volume, pitch 0.95 - 1.05, a short 3D range so others hear it quietly. No more win screams (arm wrestling / posing), no camera shake.
- Settings: a new "Lifting Voices" toggle (on by default) turns them all off on that device; "Others' Sounds" still mutes other players'.
- The sounds: 4 clips from Roblox's licensed library (Pro Sound Effects), picked by their descriptions (not heard); see [[GYM ARC - Music and Sounds]]. The reference file was not uploaded.

## Tested (Studio, 844x390, temporary save)
- Tutorial start: quiet HUD, SKIP pill, gold glow on the Flat Bench; GO TO: fade, in front of a free Flat Bench facing it, camera on it, OCCUPY right there, the button gone. The arrow shows (Studio screenshots don't draw always-on-top labels; checked with it turned off).
- Agency: the percentages; Eternal "???". Settings has "Lifting Voices"; no errors. Not tested: hearing the grunts.

![[GYM ARC/Screenshots/tutorial22/tutorial_quiet_hud_skip_pill.jpg]]
![[GYM ARC/Screenshots/tutorial22/gold_arrow_on_target.jpg]]
![[GYM ARC/Screenshots/tutorial22/after_go_to_teleport.jpg]]
![[GYM ARC/Screenshots/tutorial22/agency_odds_percent_hidden.jpg]]

## Needs the owner
- Listen to the 4 grunts (Settings: Lifting Voices) and swap any id in `Config/Sounds` LiftGrunt.
