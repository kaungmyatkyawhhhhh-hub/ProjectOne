---
date: 2026-11-01
tags: [gymarc, progress, cutscenes]
---
# GYM ARC - Cutscene fixes, Hall of Fame popup once, deal timer (1 Nov, Claude Code)

From [[2026-11-01 GYM ARC Cutscenes review]] and [[2026-11-01 Research - Do cutscenes help, what makes a good one]]. In Studio, **not published**.

## 1. First-time rolls and the Atlas / Solaris stories
- A tap now skips them **3 s after they start, even the first time** (`Config/RollReveal` `Cinematic.firstSkipAfter = 3`; TrainerClient). Before, a new Legendary+ locked every tap until the end.
- After a skip the trainer card still shows (tested: skipped the first-time Atlas story at 3.5 s, the ATLAS card with NEW! came up, camera back).
- The story's corner text: "FIRST TIME: WATCH THE STORY" for 3 s, then "TAP TO SKIP".
- **New ending:** the player's own avatar appears on the world next to the trainer in a flash of his colour, one arm up, both facing the camera, "ATLAS JOINS YOUR TEAM!" (~2.4 s). Then the card.
- The story narrator loads its voice lines one a second (all at once gave "Rate limited" and silent lines).

## 2. Hall of Fame launch cutscene
- **24 s -> 10 s:** fly-in 1.6 s, the curtains drop at 2 s, beams / fireworks / cheer at 2.9 s, HALL OF FAME title 5-8.2 s, back to you at 8.6 s. The server's timing (doors open, cover put away, launch reward) follows it by itself.
- A tap skips it after 3 s ("Tap to skip" shows then). Tested: full run 10.0 s; tapped at 3.5 s, it ended at 4.4 s; camera and HUD back both times.

## 3. Storyline rule (owner)
Benny's first moment doesn't take the camera (he walks up and talks while you move). Every bully shot is 5 s or less and a tap skips it. See [[2026-11-01 GYM ARC Storyline built - bullies, arm wrestling, voices]].

## 4. "NEW: HALL OF FAME" popup: once ever, after the tutorial
- LiveEventClient `afterTutorial()`: also false before Growth Spurt 1 (a save with no tutorial step used to count as finished).
- After it shows: every 5 s (up to 12 times) it re-sends "popupSeen" until the save has `launchEvents.HallOfFame.popup = true` (the first send could be dropped by the PlayerAction rate limit right after joining, so it came back every join).
- It also waits for a storyline shot / bully card, and a bully call-out waits for it (they started in the same second once).
- Tested in one Studio session (Studio test saves don't keep data): at Growth Spurt 1 it showed once and the data got `popup = true`; at Growth Spurt 0 it never showed. Rejoin on a real save not tested.

## 5. Starter Pack timer (owner: "tilted a bit to the left, only a bit of rounded edge, thinner outline")
The "29:47" pill on the deal card: turned -6 degrees, 5 px corners (was a full pill), 1 px gold outline (was 1.5).

## Not done / owner
- Phone-size screenshots (the Studio window can't be resized from here).
- Save to Roblox, then publish.

## 6. Right-side drawer opens on a machine (owner, 1 Nov night: "while in machine, that thing isnt expandable")
- On a machine the right drawer (the GROWTH SPURT card) folds by itself, and its "<" tab did nothing: the fold was forced while training, so a tap only changed the saved choice.
- Now (`Shared/UI/RightColumn`) a tap on a machine opens it, a second tap folds it. That's not saved: getting on or off a machine goes back to the player's own choice.
- Tested in Studio on the Starter Gym Flat Bench: tap = the GROWTH SPURT card slides in, arrow flips; tap again = folded. No errors.
