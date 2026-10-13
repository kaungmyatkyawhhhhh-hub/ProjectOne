# Break A Bed: New Player Guide

#break-a-bed #retention

Back to [[Break A Bed/Project Overview|Project Overview]].

Why: Day 1 retention showed 0% on 2026-10-12. New players spawn with nothing telling them what to do, and most players who are lost in the first 30 seconds never come back. The guide makes a new player's first minute fun and clear. It uses the [[Break A Bed/UI Kit/UI Kit|UI Kit]] style, animations and sounds.

## The steps (only for players who have never broken a bed)
1. **"Punch to get stronger!"** A glowing beam and a bouncing arrow lead from spawn to the Straw Post pad. A hint bubble appears above the pad. **(2026-10-12) Training now uses a prompt: the hint says "Press E to train!", and the 10 punches count auto punches too (training auto-punches for free).** **Built:** the step card says "PRESS E TO TRAIN!" (phones: "TAP TRAIN!"), then "PUNCH 10 TIMES!" with the bar once training; after 10 punches training ends by itself so the player can walk to the bed.
2. **Punch 10 times.** A progress bar shows 0/10. Each punch pops "+1 💪" (already in the game). Done → sparkle burst + "Nice!" sound.
3. **"Now break a bed!"** The beam moves to the Cardboard Bed. The bed prompt glows.
4. **Break the Cardboard Bed.** It's easy on purpose (6 health). The normal break effects play.
5. **Reward:** a big popup, "FIRST BED! +$50", with rays and confetti. The Cash flies to the counter.
6. **"Buy the Wooden Post!"** The beam points to the Wooden Post ($50, so they can afford it right away). Buying it ends the guide with "You're a pro! Keep breaking beds!"

The whole guide should take about 45–60 seconds. **Show, don't tell:** use beams, arrows, glowing targets and effects, with only 2–4 words of text per step.

## Look: light style (changed 2026-10-12)
**Updated:** the owner wants the tutorial card **light, not dark**, and the ground path as **moving arrows**. Follow the "Main screen (HUD) and tutorial" section of the [[Break A Bed/UI Kit/UI Kit|UI Kit]] and `preview-hud.png`. The older dark version below is replaced where they differ.

### Older dark version (replaced)
The first build used plain dark panels that didn't match the [[Break A Bed/UI Kit/UI Kit|UI Kit]]. It should look like this:

![[UI Kit/preview-tutorial.png]]

- **Step card** (top center, about 30% of the screen width, never wider): a slate UI Kit box (`btn-slate.png` look: `#3E4454`, studs, light rim, 3D bottom edge, stroke `#161822`, 3 px corners).
  - The title is yellow `#FFE20C`, Montserrat Heavy, with the UI Kit text stroke and shadow. Keep it short: "PUNCH 10 TIMES!", "BREAK THE BED!", "BUY THE WOODEN POST!".
  - On the left is an icon (`icon-bolt.png` for punching, `icon-cash.png` for buying), and next to it a **progress bar**: a dark track `#2A2F3D` with the stroke and a **green** UI Kit fill with studs. White "3 / 10" text sits in the middle of the bar.
- **SKIP:** a small red UI Kit button under the right edge of the card. It must not overlap anything else.
- **In the world:** a big yellow down-arrow with a dark outline (UI Kit look) bouncing above the target, with 2 twinkling sparkles, plus the beam on the ground. This does most of the "telling".
- **Next goal bar** (only after the guide, never at the same time as the step card): a slimmer slate box (about 30% width) with `icon-bolt.png`, white text "Next bed: Air Mattress" and a **cyan** progress bar "4 / 7 Strength". Put it at the top center where the step card was, or just above the bottom buttons on phones.
- **Animations:** the card drops in from above (Back Out). The bar fill slides smoothly. Each step done = the card flashes white, sparkles burst and a "ding" plays, then the next step's text pops in. The arrow bobs 10 px up and down.
- Only one guide element at a time. Never stack two dark panels.

## Make it smaller (owner, 2026-10-13)
The owner's screenshot: the step card is huge (about 60% of the screen width and a big chunk of the height) and covers the middle of the screen. It must be a small strip at the top center, with the world arrow and beam doing the telling.
- **Size:** a slim pill **at most 24% of the screen width on PC** and 40% on phones, and about 6% of the screen height (around 40–48 px on PC). Use `UISizeConstraint` so it never grows on big screens.
- **Inside, one row:** a small icon on the left (about 70% of the pill's height), then the step text in one line, with the text size scaling down to fit (`TextScaled` plus a `UITextSizeConstraint`, max around 22). Keep the light card style from the UI Kit.
- **Progress:** a thin bar (about 6 px) along the bottom edge of the pill, only on steps that count (punches). There's no separate big bar.
- **SKIP:** a small red "SKIP" chip right under the pill's right end, about 1/3 of the pill's height. It's never a big button.
- **Position:** top center, below Roblox's top bar, never covering the stats (top right) or the left buttons. On phones, keep it clear of the thumbstick and jump button.
- Everything else (steps, arrow, beam, sounds) stays the same.

## Rules
- The beam is a `Beam` from the player's character to the target, plus a bouncing arrow `BillboardGui` above the target. Only the player sees them (made on the client).
- A small top-center bubble shows the current step (UI Kit style), and a **SKIP** text button sits under it.
- **Saved:** a `TutorialDone` flag in the save. Players who already have progress (any bed completed) never see it.
- **Nothing pops up during the guide:** the daily reward, the Starter Pack and the shop "!" badge wait until it's finished.
- After the guide, the daily reward shows, then Free Gifts starts its first 1-minute gift. That way there's a reward waiting almost right away.

## Also for the first minutes
- **Next goal hint:** after the guide, a small top-center line always shows the next goal, for example "Next bed: Air Mattress — need 7 💪", with a progress bar. Tapping it points the beam at that goal for 5 seconds.
- **Phones first:** check that the hint bubble, SKIP and the progress bar don't cover the thumbstick or the jump button.

## For Claude Code (in the code folder: `Cashgrab` or `BAB`)
1. Build this as a new client module (`Tutorial`) plus the `TutorialDone` save field on the server.
2. Hold back the other pop-ups until the guide is done.
3. Test it with a fresh save in Studio, on the PC layout and the phone emulator.
