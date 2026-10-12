# Break A Bed: New Player Guide

#break-a-bed #retention

Back to [[Break A Bed/Project Overview|Project Overview]].

Why: Day 1 retention showed 0% on 2026-10-12. New players spawn with nothing telling them what to do, and most players who are lost in the first 30 seconds never come back. The guide makes a new player's first minute fun and clear. It uses the [[Break A Bed/UI Kit/UI Kit|UI Kit]] style, animations and sounds.

## The steps (only for players who have never broken a bed)
1. **"Punch to get stronger!"** A glowing beam and a bouncing arrow lead from spawn to the Straw Post pad. A hint bubble appears above the pad.
2. **Punch 10 times.** A progress bar shows 0/10. Each punch pops "+1 💪" (already in the game). Done → sparkle burst + "Nice!" sound.
3. **"Now break a bed!"** The beam moves to the Cardboard Bed. The bed prompt glows.
4. **Break the Cardboard Bed.** It's easy on purpose (6 health). The normal break effects play.
5. **Reward:** a big popup, "FIRST BED! +$50", with rays and confetti. The Cash flies to the counter.
6. **"Buy the Wooden Post!"** The beam points to the Wooden Post ($50, so they can afford it right away). Buying it ends the guide with "You're a pro! Keep breaking beds!"

The whole guide should take about 45–60 seconds.

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
