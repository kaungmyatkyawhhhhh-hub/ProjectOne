---
date: 2026-11-12
tags: [gymarc, playtest, critique]
---
# GYM ARC: critic review (12 Nov, fresh player, phone layout 844x390)

The owner asked: "test the game and be the game critic".
- **Played:** Studio build v1868 as a new player (FreshPlayer), from join to Growth Spurt 2.
- **Also looked at:** the town, the beach gym, the Gem Mine and the hill behind the Powerlifting Gym, from Edit.

**Score: 6.5 / 10.** It's a strong, fast hook, but the HUD hides the body you're growing, and it sells too early.

| | Score |
|---|---|
| Hook / first minutes | 8 |
| Core feel (rep → grow) | 6 |
| Clarity | 6 |
| World visuals | 7 |
| UI | 5.5 |
| Monetization fairness | 5 |

## Timeline
| Time from join | What happens |
|---|---|
| 0:00 | Loading screen ("LET'S LIFT!" bar). |
| ~0:05 | Intro: Benny the bully, the membership sign, the flyover. |
| ~0:35 | Control. Coach Dex and GO TO FLAT BENCH. |
| ~0:40 | First rep: +100 coins, "FIRST REP!". |
| ~1:00 | Bench done; Growth Spurt bar at 50%. Then the squat rack, crunch bench and pull-up bar, about 6 reps each. |
| ~2:20 | GROWTH SPURT 1 ready. The gold-glow growth shot with the height counting up. |
| ~2:40 | Six menus unlock at once, each with a NEW or ! badge. |
| ~3:00 | Starter Pack side card (R$29, 24 min timer). |
| ~4:00 | Closing the Growth Spurt window opens a full-screen NEW PLAYER PACK (R$29, "worth 199, save 85%", "30 min only"). |

## What works
1. **Speed:** control at 0:35, first reward 5 s later, first Growth Spurt at 2:20. Every step pays (coins, a %, a toast).
2. **The growth moment:** the gold body glow and the counting height is a real "wow". Keep it.
3. **Story hook:** a bully who calls you "skinny" gives the grind a reason to exist.
4. **Low friction:** GO TO teleports you and gold floor arrows lead the way. Nobody gets lost.
5. **The town:** cohesive and readable. Brick starter gym, a beach gym with clear zones, the crystal Gem Mine, the court and the runway.
6. **The Emotes window** looks finished with the new pose icons.

## What hurts (most important first)
1. **You can't see your own body in the core loop.**
   - In the gym, Coach Dex's box and the GO TO button sit right on top of the character.
   - On a machine, the rep card, the stamina bar and two stacked toasts cover the middle of the screen.
   - The camera is high and the barbell sits in the foreground.
   - The fantasy is "get huge", and the HUD hides exactly that.
   - **Fix:** Dex's box at the bottom edge; stamina inside or under the REP button; one toast at a time, at the top; a lower, side-on camera on machines.
2. **The muscles reset when you grow.** The puffy arms from the pull-ups are gone after Growth Spurt 1. It reads as losing progress at the best moment.
   - **Fix:** keep part of the size, or show a before/after with the word "TALLER".
3. **The promise doesn't match.** Dex says "Every rep makes you TALLER", but the height stays 4'0" for 2 minutes and only jumps at the spurt.
   - **Fix:** say "every rep fills your Growth Spurt bar", or add small height ticks.
4. **Unlock flood after Growth Spurt 1.** All at once:
   - 6 menus with NEW or ! badges;
   - DAILY with a red !;
   - the quest;
   - the posing-show timer;
   - the Starter Pack.

   **Fix:** open one menu per goal.
5. **It sells too early.** A full-screen pack at minute 4, triggered by closing a different window, with fake-urgency wording ("worth 199, save 85%, 30 min only").
   - **Fix:** keep the side card; hold the full-screen pack until after Growth Spurt 2 or 10 minutes; drop the "worth" anchor.
6. **Mixed goals and instructions.**
   - The Growth Spurt 2 chip says "NEXT: BEAT BENNY", but its window lists chest machines.
   - The tutorial says "Follow the gold arrows and tap Occupy" while a GO TO button teleports you.
   - Two TAP TO GROW buttons are on screen at the same time.
   - The top banner repeats the rep card's line word for word.
7. **The intro:**
   - 35 s before control;
   - a subtitle printed over the sign's own text;
   - the flyover shows the **floating apartment blocks** on the hill behind the Powerlifting Gym: `Town.Buildings.Distant`, 13 flat-bottomed towers on bumpy grass, some hovering up to 18 studs. A cheap tell every new player sees.
8. **Tiny text:** the weight card at the top right ("Mid Chest 24.4K / 36.5K EXP", the tier dots) is about 8 px on a phone, and "Tap to continue (1/1)" is small too.
9. **Choppy tutorial rhythm:** Dex line → GO TO → 6 reps → "TAP STOP" → Dex line, four times. Let the set end by itself and auto-advance.
10. **A dark gym:** the lower half of the screen is murky on a phone.

## Not issues (checked)
- **The orange starbursts everywhere:** the owner's own avatar accessory (GreenPixie, a Sparkles object), not the game.
- **The camera "stuck":** my test tool resets the camera type after each script run, so it's not a game bug.
- **The X on the Growth Spurt window:** it works. The test tool's click had missed it.
- **Console:** no errors. Existing warnings: "No ShakeMachine in Workspace", "Missing PosePrompt in Workspace.Town".

## Suggested order to fix
1. Clear the middle of the screen while training (1).
2. Fix the floating hill towers (7).
3. Hold the full-screen pack (5).
4. Fix Dex's line (3).
5. Stagger the unlocks (4).
6. Keep some muscle after a spurt (2). This is a design call.
