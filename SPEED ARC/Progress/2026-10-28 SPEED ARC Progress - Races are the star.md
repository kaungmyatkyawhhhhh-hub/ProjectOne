---
date: 2026-10-28
tags: [speedarc, progress]
---
# SPEED ARC Progress - Races are the star

Back to [[00 SPEED ARC Home|SPEED ARC Home]] · Feature: [[SPEED ARC - Races]] · Before: [[2026-10-28 SPEED ARC Progress - 11 Finish the +1 SPEED pivot]]

## Owner decision (28 Oct)
"No more pivots. The game stays '+1 SPEED every step' + wall course + LIVE RACES every 3 min (our difference from other +1 games). Make the race the star (the race card and the podium are the most exciting moments, race wins give the best rewards), and suggest a title and a description that highlight racing real players."
Saved in `SPEED ARC/CLAUDE.md` (The game) and GDD section 28. Prompt 11 was already done (see the note above); this is on top of it.

## Done
- **LIVE RACE card** (top right, 15 s join window, was 10): a blinking LIVE pill, the race type, the countdown (red in the last 3 s), the heads of the real players who joined, the prize ("WIN +720 COINS + 2x SPEED"), and the JOIN button inside it. The old "A RACE IS STARTING! Tap JOIN" toast is gone.
- **The podium** after every race: full screen; 2nd / 1st / 3rd blocks rise; real players' headshots (NPCs: an initial); YOU in gold; "YOU WON!" / "2ND PLACE!" / "4TH - SO CLOSE!"; "6 RUNNERS - 1 REAL PLAYER"; 4th-8th; the medal, the time, coins counting up and flying to the counter; the SPEED boost; NEW PB!; confetti (twice for a win); fanfare.
- **Race wins = the best rewards:** 1st 10 min of coins (+2 for finishing = 12, the biggest payout in the game), 2nd 6, 3rd 4. The top 3 also get **2x SPEED per step** for 2 min / 1 min / 30 s (on the boost badge). Repeat wall smashes pay 5% (first smash x3 stays), so walls can't out-earn races.
- **Pacing re-solved** with the bigger race rewards and the boost (`tools/step_pacing_sim.py --solve`). Go Pro still at **14.8 / 34.4 / 56.2 min** (L1 / L2 / L3). Wall needs and ranks were updated (L1 walls 310 ... 89K; ranks on walls 4 / 6 / 8 / 10). Racing well now makes you faster: the 2x boost feeds straight into the next wall.

## Suggested title and description (owner picks, Creator Hub)
- **Title:** **"+1 Speed Every Step: LIVE RACES"**. It has the words kids search for ("+1 Speed") plus what no other +1 game has.
  - Other options: "+1 Speed Race vs Real Players", "SPEED ARC: +1 Speed Race". SPEED ARC stays the brand on the logo and in the game.
- **Description:** "+1 SPEED every step! Run, get faster and SMASH through walls. Every 3 minutes a LIVE RACE starts: race real players on the track, climb the podium and win the biggest prizes in the game (huge coins + 2x SPEED!). Collect shoes, trails and coaches, smash the last wall and GO PRO to new worlds: City Park and the Big Stadium. Quiet server? Runner bots fill the lanes, so a race always starts."
  - The last line is there so the page stays honest: races fill up with bot runners when few players join.
- **Thumbnails:** the podium moment, the LIVE RACE card over a full start line, a wall smash.
(Also in the Launch Checklist, section 3.)

## Tested (Studio)
- The card with nobody in ("BE THE FIRST TO JOIN!") and after I joined (my head, "1 RUNNER IN", "JOINED!", the red countdown).
- A 6-runner Lap Race to the podium: 2ND PLACE, +720 coins, silver medal, 2x SPEED 1:00, the boost badge counting down. No console errors.
- Not tested: a race with 2+ real players (needs a team test or a live server), the podium on a phone.

![[2026-10-28 race live card.jpg]]
![[2026-10-28 race live card joined.jpg]]
![[2026-10-28 race podium.jpg]]

## Owner to do
1. Pick the title and description and set them in Creator Hub (title / description / thumbnails).
2. A test with a friend (2 real players in one race) to see two headshots on the card and the podium.
3. File > Save to Roblox + a dated backup.
