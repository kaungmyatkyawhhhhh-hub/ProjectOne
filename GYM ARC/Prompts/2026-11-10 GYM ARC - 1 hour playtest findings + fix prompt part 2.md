---
date: 2026-11-10
tags: [gymarc, playtest, bugs, retention, monetization, prompt, claude-code]
---
# GYM ARC: 1-hour playtest on a fresh account (10 Nov) + fix prompt part 2

Owner: "try again for 1 hour straight ... find stuff that players wont like and unappealing stuff and find why players dislike the game".
How: Claude played the live game on the owner's 2nd fresh account (PC, ~20:10–21:00 MMT, ~50 min). It stopped when the owner brought Discord to the front. Reached Growth Spurt 4, the Beach Gym, the Pro Gym, beat Benny and Coral, did 1 Posing Show, rolled 10 trainers.
Goes with: [[2026-11-10 GYM ARC - Why the like ratio fell (74 to 69) + fix prompt]] (part 1: the error flood + first tutorial walk). Send part 1 first, then this one.

## Timeline (what a new player sees)
| Time in | What happened |
|---|---|
| 0:00 | ~35–40 s plain grey screen, then a 15 s intro |
| 0:05 | 4 tutorial machines → Growth Spurt 1 (4'0" → 4'4") |
| 0:10 | Benny (Chapter 1 boss) won in ~8 taps |
| 0:11–0:16 | Trainer Agency + menu tour (~20 Coach Dex dialog taps) |
| 0:23 | Growth Spurt 2 (4'8"), then "NEW: GEM UPDATE" popup |
| 0:30 | Tutorial guidance stops; no next arrow |
| 0:36 | Growth Spurt 3 (5'0"), Chapter 2: Coral |
| 0:40 | First Posing Show (runway) |
| 0:42 | Coral won in ~8 taps → "roll the trainer gacha 10 times" |
| 0:45 | Physique window says **0% BEGINNER, all grades D** |

## What players won't like (ranked)
### 1. Pushy / accidental Robux prompts (dislikes + "scam" feeling)
- **The AUTO REP R$249 popup can't be closed.** Its X does nothing (tried 3× with hover). It shows on every machine and even stays on the HUD while swimming. It sits under the GO TO button.
- **A misclick near that popup opened a Roblox Plus subscription prompt.** Kids who tap fast will hit Robux buttons by accident.
- The Store sells AUTO REP (R$249, "best seller", "lifts for you") right next to the **free** AUTO TRAIN button. Kids can't tell the difference, so it feels like a trick.
- Offers escalate on the HUD: Starter Pack R$29 (with countdown) → Premium Pack R$599→199. Plus the DEAL badge, PLUS +20% EXP and FREE 1,000.
- **The tutorial makes you roll the trainer gacha 10 times** (1,500 coins) before the Pro Gym. A "DUKE IRONSIDE" (Legendary) name flashed during a reveal, but I didn't get him. That looks like a near-miss tease. Playbook rule: no gambling pressure for kids.

### 2. The "get huge" fantasy never shows
- After 3 growth spurts and ~45 min, the body is still a small bacon-hair (5'0"). The **Physique window says "0% BEGINNER", every muscle grade D.** The game tells you that you made no progress.
- "Muscles start fresh" after every spurt (EXP and stats reset to 0) feels like losing progress. The Posing Show then judges you with 0 stats, right after a reset.
- YOUR ROAD shows the same tiny silhouette for every spurt (no preview of getting bigger).
- Weight numbers fly up (45 → 545 lb) but nothing on the character matches.

### 3. Guidance breaks or lies
- **GO TO sends you to the wrong place.** Twice, GO → Planche Push-Up put me on the arm-wrestle seat next to it ("Pick an opponent: Rocco/Tess/Big Lou"). GO → Goblet Squat dropped me at a dumbbell rack with no E prompt.
- Walking past an arm-wrestle table auto-seats you (twice by accident).
- **GO TO clicks are eaten while training / while a dialog is open.** STOP, GO and CLAIM often need a 2nd click (the first one is ignored).
- Contradictions:
  - The Growth window says "chest and arms are furthest behind", but the card says "NEEDS CORE, LEGS".
  - The coach says "CHEST first", but the card says "NEEDS BACK, LEGS".
  - "Train your CHEST" uses the Planche Push-Up, labelled SHOULDERS.
  - "Your shakes and boosts are here", but the inventory is empty.
- Out-of-order steps:
  - "POSES are open!" fired after I'd already used poses.
  - "Tap TRAINERS" came right after I'd closed Trainers.
- **The guidance just ends twice:**
  - after Growth Spurt 2;
  - after the gacha step (the "Pro Gym is open" message has no arrow, no GO and no hint).
  The Growth window only lists starter-gym machines.
- Walls with no explanation: "Needs BRONZE PLATES – Plate Forge" capped the bench at 315 and the planche at 100. Nothing says what or where the Plate Forge is.
- The Goals tab: "Do 10 reps on any machine" shows SOON after 100+ reps.

### 4. Too much text, too many popups
- ~20 Coach Dex dialogs in the first 16 minutes. Many sit on top of the thing they explain (the streak rewards, the trainer reveal cards). Only the small diamond advances some of them.
- **"NEW: GEM UPDATE" popup for a brand-new player** (alters 16-20, Run Card picks, Hall of Fame Star Track). It's jargon to them; show it only to returning players.
- Other prompts in the first 30 min:
  - notifications;
  - favourite (twice);
  - the Runway invite (it covers the menus).

### 5. Events and bosses feel empty
- **Posing Show:** the chip counted to 0:00 three times with no invite and no reaction to clicks. When it finally ran:
  - "strike a pose" came with no pose button;
  - you rate 3 bot models;
  - it ended with **no result or placement screen** (+30 coins).
- **Bosses:**
  - Benny and Coral fall in ~8 taps;
  - no win celebration for Benny;
  - the PvP arm-wrestle ended with no win/lose screen.
  There's no tension, so there's no pride.

### 6. Looks / polish
- **The Growth Spurt 2 cutscene camera was inside the barbell/character mesh** (grey wall texture + black). It's the biggest reward moment.
- Camera blocked by:
  - the "TODAY'S WORKOUT" sign;
  - big wooden poles;
  - racks;
  - the trainer pet (it stands between the camera and the player, even on the machine).
- The Stats world labels (Shoulders 0, Chest 0, …) followed my character for 20+ min after the tutorial turned them on. They overlap the machine name, the E prompt and the name tag.
- Overlaps:
  - the Trainers window's X over the OPTIONS button;
  - the "FAVOURITE = FREE COINS" title under its X;
  - "REACH GROWTH SPURT 4REACH GROWTH SPURT 5";
  - toast over the "NEW PERSONAL RECORD" banner;
  - a toast cut off at the right screen edge;
  - two players' name tags merged.
- The 8 emote buttons all use the same pink flex icon (placeholder look).
- The dark dim while training (even on the sunny beach) and the very dark Pro Gym.
- Tiny unlabeled collapse arrows hide the whole left menu or the right cards by accident.
- Coins drop with no message (10,561 → 10,220 during auto train; 336 → 268 before). Probably auto weight unlocks spending coins silently.
- The treadmill showed REP x12 but "Quads 0 / 6.47K" and Growth +0%. The character stood beside it, not on it.

### What's good (keep)
- The Beach Gym looks great (water, palms, day/night).
- Auto Train pacing is fine (~8–30%/min of a spurt).
- 2 daily quests are claimable at once.
- The "come back tomorrow for a free roll" hook; Coral's ragdoll is funny.
- Teleport GO TO works when you're not training.

## Why players leave (summary)
1. Lag from the error flood (part 1).
2. The first walk/tutorial friction (part 1).
3. **The game feels like a shop with ads, not a gym.** There's an unclosable Robux popup, accidental purchase prompts and a gacha quest in the tutorial.
4. **No visible growth:** the game itself says you're at 0%.
5. Guidance that sends you to the wrong seat, contradicts itself, then stops.
6. Events and bosses with no payoff.

```text
GYM ARC – FIX PROMPT PART 2 (after the 10 Nov part-1 prompt: error flood + first tutorial walk). From a ~50-min playtest on a fresh account. Maintenance fixes only, no new features. Do NOT publish (the owner publishes). Test on a TEST save. Phone first.

A. MONETIZATION THAT FEELS LIKE A TRAP (top priority)
1. The AUTO REP (R$249) popup's X does nothing: fix the close button. Show this upsell at most once per session, never during the tutorial, never under/over the GO TO button, and hide it when you leave the machine (it stayed on the HUD while swimming).
2. No Robux button may sit next to or overlap a common button (X, GO TO, STOP, REP). A misclick near the AUTO REP popup opened a Roblox Plus subscription prompt. Keep ≥ 40 px between a price button and any other button; add a 0.5 s input lock when a popup opens.
3. Explain AUTO REP vs the free AUTO TRAIN (rename or add one line: "AUTO REP = trains even when you're away / 2x speed" — whatever is true). If they do the same thing, remove the pass from sale.
4. Remove the "Roll the trainer gacha 10 times" tutorial step before the Pro Gym. Replace it with "Equip your free trainer" (1 free roll is OK). No HUD pack offers (Starter/Premium) until the tutorial is finished, and only one offer card at a time.
5. Trainer reveal: never show another trainer's name (e.g. "DUKE IRONSIDE") during a reveal unless the player gets that trainer. The "Trainer Rolls x/10" quest box must not cover the reveal cards.

B. MAKE GROWTH VISIBLE
6. The Physique window showed "0% BEGINNER", all grades D after 3 growth spurts (~45 min). Make the % and grade measure progress inside the CURRENT spurt (or overall height), so it always goes up. Never show a fresh player 0%.
7. After a growth spurt, don't present "Muscles start fresh" as a loss: say "Gains x1.71!" and keep showing the total/lifetime numbers. The Posing Show must not judge stats that were just reset (use lifetime or physique score).
8. YOUR ROAD: show the character's real bigger look for each spurt (a scaled preview), not the same silhouette. Fix the "REACH GROWTH SPURT 4REACH GROWTH SPURT 5" overlap.
9. Growth Spurt cutscene: the camera ended up INSIDE the barbell/character mesh (grey wall + black). Pull the camera to a fixed safe offset in front of the character, hide machines/props within the shot, and stand the character up off the machine first.

C. GUIDANCE THAT LIES OR STOPS
10. GO TO must land on the RIGHT machine and auto-occupy it. Twice GO → Planche Push-Up put the player on the arm-wrestle seat next to it; GO → Goblet Squat landed at a dumbbell rack with no E prompt. Arm-wrestle seats must never auto-seat on walk-by or teleport (only with E).
11. GO TO / STOP / CLAIM: the first click was often ignored (only worked after hovering). Make them fire on Activated with no hover state needed; GO TO while training = stop + go.
12. One source of truth for "what to train next": the Growth Spurt window, the HUD card ("NEEDS …") and Coach Dex said three different things. "Train your CHEST" used the Planche Push-Up which the HUD calls SHOULDERS.
13. The tutorial must never end without a next goal. After Growth Spurt 2 and after the Coral/trainer step the arrows/GO button disappeared and the Pro Gym was "open" with no way to find it. Always show 1 next-goal chip with a GO TO (the Pro Gym, the next boss, the Plate Forge).
14. Explain gates when they appear: "Needs BRONZE PLATES – Plate Forge" capped the bench at 315 and planche at 100 with no explanation; tap it = GO TO the Plate Forge + one line on how to get plates.
15. Fix steps that fire out of order ("POSES are open!" after poses were used; "tap TRAINERS" right after closing Trainers; "your shakes and boosts are here" with an empty inventory). Goals tab "Do 10 reps on any machine" stayed SOON after 100+ reps.

D. TOO MANY POPUPS / TOO MUCH TEXT
16. Cut Coach Dex to one short line per step (≈20 dialogs in the first 16 minutes now). Dialogs must not cover what they explain (streak rewards, reveal cards), and tapping anywhere on the box advances.
17. "NEW: GEM UPDATE" (alters, Run Cards, Star Track): only for returning players, never on a first visit.
18. Max one system prompt (notifications / favourite / runway invite) per 5 minutes, none during tutorial steps.

E. EVENTS AND BOSSES
19. Posing Show: the chip counted to 0:00 three times with nothing happening and clicking it did nothing. Always send the invite at 0:00 (or say "Next show in …"). During your walk show a big POSE button. End with a results screen (placement, stars received, reward).
20. Benny and Coral fell in ~8 taps: add a short tug of war (3–5 s) and a win celebration (confetti, "BENNY DEFEATED!", reward card). PvP arm wrestle needs a win/lose screen.

F. POLISH
21. Stats world labels: turn them off when the tutorial step ends, and never overlap the machine label / E prompt / name tag.
22. The trainer pet must not stand between the camera and the player (stand behind/side, fade when it blocks the camera). Fade signs/poles/racks that block the camera (the TODAY'S WORKOUT sign at the Trainer Agency, beach poles).
23. Overlaps: the Trainers window X over OPTIONS; the FAVOURITE = FREE COINS title under its X; toasts over the NEW PERSONAL RECORD banner; a toast cut off at the right screen edge; 2 players' name tags merging.
24. The 8 emotes all share one placeholder icon: give each pose its own icon (silhouette of the pose).
25. Coins drop with no message (10,561→10,220 in auto train): show "-341 coins: unlocked 455 lb" or remove the charge.
26. Treadmill showed REP x12 but "Quads 0 / 6.47K" and the character stood beside it: fix the seat/animation and show what cardio gives (stamina).
27. Lighter training dim; the Pro Gym is very dark. The tiny collapse arrows for the left menu / right cards need a label or must be harder to hit by accident.

REPORT (short): what changed per item, phone + PC screenshots of: the machine HUD (no AUTO REP popup), the Physique window after Growth Spurt 1, the growth cutscene, the Posing Show results screen, the Benny win screen.
```
