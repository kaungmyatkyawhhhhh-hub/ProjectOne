---
date: 2026-10-23
tags: [gymarc, prompt]
status: done
---
# 53 Tutorial and toast cleanup

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
The owner says the tutorial screen looks like a mess. Screenshots: C:\Users\kaung\Downloads\gym_arc_tutorial_mess\ (01 phone GO TO, 02 desktop GO TO, 03 NEW WEIGHT toast on a machine, 04 LVL UP + "Set done"). Mockups to match: Downloads\gym_arc_ui_style_match\real\tutorial.png and tutorial2.png. Follow CLAUDE.md Speed rules. Mobile first. Never undo the owner's manual Studio changes.

WHAT'S WRONG -> FIX
1. GO TO button is huge and sits in the middle of the screen over the character.
   -> Move it to the bottom centre, just above the hotbar/stamina bar. Normal ChunkyButton size (about 30% of the screen width on phones, max ~320 px on desktop). Never over the character.
2. SKIP is a big button floating in different places (top right on phone, top middle on desktop, next to the Growth Spurt card).
   -> One small dark pill "SKIP" (about 1/3 of its current size) in the SAME spot always: top-right, just under the top bar, inside the safe area. Same on every step, on and off machines.
3. Non-tutorial UI still shows during the tutorial (Growth Spurt card + its arrow, DAILY, quest card).
   -> Hide everything that isn't the tutorial while it runs (prompt 40), except coins + LVL in the top bar and the machine controls when on a machine. Bring them back with a fade when the tutorial ends.
4. The marker label ("FLAT BENCH 4m") gets cut off by the top bar on desktop.
   -> Clamp the marker + label below the top bar / safe area.
5. A white hand pointer sits on the character (phone).
   -> Remove it, or put it on the GO TO button only (small, tapping animation).
6. Toasts ("NEW WEIGHT UNLOCKED", "LVL UP") pop up in the MIDDLE of the screen over the lift, in the old style.
   -> ONE toast lane at the top centre, just under the top bar. Toasts queue: one at a time, ~2.5 s each, slide down and fade out. Never in the middle of the screen.
   -> New chunky style: dark graphite with hex texture, thin gold outline, dark bottom edge, a transparent icon (no square box), title in white chunky stroked text, sub line small and light grey. Same style for every toast in the game.
7. "Set done · +80,545 Chest" is huge floating text overlapping the toast and the STOP button.
   -> Smaller (about the size of the PUMP label), short ("+80.5K CHEST"), floats up from just above the REP button and fades. Never overlaps buttons or toasts.
8. The player's own overhead title ("Beginner Gains") shows through the bar/plates while lifting.
   -> Hide your OWN overhead title while you're on a machine (others still see it).
9. Coach Dex dialog: when it shows, it's at the bottom with the new look (prompt 37 style) and the GO TO button sits right above it, not on top of it.

LAYOUT RULE (write it in CLAUDE.md so it stays): top bar = coins/LVL/daily/settings; under it on the right = SKIP; top centre = toast lane; bottom centre = GO TO / Coach Dex dialog / stamina; right side = machine controls; left = left nav. Nothing in the middle of the screen except the world marker.

TEST: phone (667x375) and desktop screenshots of: the GO TO step, being on the Flat Bench with a NEW WEIGHT toast, a LVL UP + set done at the same time, and the shake step. Each next to the old screenshot. Short progress note in the vault.
```
