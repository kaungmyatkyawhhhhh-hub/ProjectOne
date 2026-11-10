---
date: 2026-11-10
tags: [gymarc, progress, bugs, retention, ui]
status: in Studio, NOT published. Tested on a TEST save (FreshPlayer, never saves). 0 script errors in 4 Play runs.
---
# GYM ARC: fix prompt part 3 (10 Nov, late)

Prompt: part 3 (pasted by the owner). Goes after [[2026-11-10 GYM ARC - Like-ratio fixes built (part 1 + part 2)]].
Every change has a "(10 Nov" comment in the script. Parts 1 and 2 were not redone or undone. Not published.
Screenshots: `GYM ARC/Screenshots/2026-11-10 part 3/` (phone layout 667x375 unless it says PC).

## A. Tonight's fixes checked
| # | Check | Result |
|---|---|---|
| 1 | Errors (task.defer re-entrancy, MachineHud fitNeeds, Kit 1421, PreferredTextCap, StatsLabels clamp) after ~3 min of training + windows (Store, Stats, Physique, Trainers, Inventory, Quests, Crew) | **PASS**: 0 errors, 0 of the five, in all 4 runs |
| 2 | GO TO puts you ON the machine | **PASS** (flat bench, pull-up bar, treadmill; a gym GO TO lands on a machine) |
| 2 | Walk onto an arm-wrestle stool | **PASS**: not seated. OCCUPY (E) still seats you |
| 3 | Non-owner sees "Auto Rep (pass)" | **PASS** |
| 3 | Auto Rep card: X / 12 s / walk away | **PASS** for X, 12 s and walking. **FAILED** on STOP (it stayed up): fixed, it now closes when you get off the machine |
| 3 | No Starter / Premium card before Growth Spurt 1 | **PASS** |
| 4 | Coral lesson: 1 roll → TRAINERS → BEST EQUIP → Pro Gym guide | **PASS**. Found: Dex's box and the ROLLS card sat on the trainer reveal card: fixed (no box over the reveal, only the spotlight on CLOSE) |
| 5 | Physique % goes up while training | **PASS** (Back 39% → 81%, total 56% → 63% in 12 s) |
| 5 | Growth cutscene: no machine parts in front of the camera | **PASS** (body clear; only the treadmill deck under the feet shows at the bottom edge) |
| 6 | Posing Show pill hidden at 0:00 / tap in the join window joins | **PASS** |

## B. Built
### 1. Bosses: tug of war + WIN card
- **Bully matches (Benny, Coral, all bullies)** are a tug of war now (`ArmWrestleService`, the `TUG` numbers at the top):
  - your taps push a fixed amount (a bit more if you're stronger);
  - the bully pushes all the time and SURGES (a hard shove every 1.1-1.6 s, the first one right after GO), so the bar goes his way and back;
  - nobody can be pinned before 3 s; the match lasts up to 10 s.
- Measured on the server (Benny rematch, no auto-win):

  | Taps a second | Result | Bar |
  |---|---|---|
  | 7 | WIN in 3.3 s | +0.09 → −0.06 → +0.76 → +0.64 → pinned |
  | 5 | WIN in 5.7 s | −0.25 → +0.42 → +0.20 → … → pinned |
  | 0 | LOSE in ~3.5 s | — |

  The first Benny / Coral match (the tutorial's auto-win) also swings now: won in ~3 s with no taps.
- **WIN card** (new kit component `Shared/UI/ResultCard`: Kit.Card + Kit.IconTile + gold Kit.Text + Kit.Chip + Kit.Button CONTINUE + Kit.CloseButton): "BENNY DEFEATED!", "The BEACH GYM is open!", +900 coins, confetti, the victory sound. A rematch win: "BENNY DEFEATED AGAIN!". The cliffhanger waits until the card is closed (or 6 s).
- **PvP / practice arm wrestle:** the same card: YOU WIN! / YOU LOSE / DRAW, who pinned whom, the coins.

### 2. Coach Dex
- **Every step is ONE short line** (tutorial `Config/Onboarding`, unlock guides and window tours `Config/Guides`, the Coral lesson, Genetics, the stamina tip, the "come back tomorrow" note). Before: many were 2 pages.
- **Never covers what it explains:**
  - the window tours put the box on the far side of the screen (button at the top → box at the bottom, and the other way);
  - any other Dex box jumps to the top while it would cover the spotlit button or a trainer reveal / daily streak card;
  - during the trainer reveal there's no box at all (only the spotlight on CLOSE);
  - the stamina tip waits while another Dex box is up (two boxes were stacked);
  - Dex boxes hide while you're on the runway.
- **A tap anywhere on the box advances** (an invisible button over the whole box). Checked on the tutorial, tour, Coral and stamina boxes.

### 3. Posing Show (the runway)
- At the end of your walk a big gold **POSE!** button (Kit.Button). Each tap hits a pose (the server picks it) and adds ~0.3 stars from the judges and models (max 3 poses). Checked: 3/3 poses counted.
- **Results card** for the models (the same ResultCard): 1ST PLACE! / 2ND / 3RD / PLACE 4 OF 4, stars received, coins, trophy, votes and poses, the top 3. It waits for CONTINUE (9 s max); the old small card closed on the first tap, so models missed it. The posing competition uses it too.
- Checked: 2nd show I placed 1st, the card showed. **Not explained:** in the 1st show I placed 4th and no card showed (the server sent the result). The card itself works for 4th place when called. Watch this on the live game.

### 4. Coins
- **Analytics economy sinks (28 days):** TrainerRoll −134.4M, PumpShop −49.9M, DnaToken −28.3M, PlateTier −23.5M, Style −13.1M, TrainerSnack −2.4M, Aura −1.6M, Cosmetic −0.4M. **There is no automatic sink.** Every one is a buy, and no item costs 341 or 68 (a roll is 150, snacks 150 / 500 / 1,500).
- Most likely cause: a trainer roll / snack / Pump Shop buy tapped by accident (ROLL AGAIN is a big red button in the middle of the screen after the free crew-gift roll, which opens by itself, also mid-training). I couldn't make the drop happen in Studio.
- **Fix: every coin spend is shown now.** A red "−150 · Trainer snack" / "−450 · Trainer roll" floats under the coin counter (PlayerData.SpendCoins → PlayerEvent "CoinsSpent" → TopBarClient). Checked.

### 5. Emote icons: ChatGPT prompt (one sheet, 8 icons)
Not faked in code. Paste into ChatGPT:

```text
Make ONE image, 2048x1024, a 4 x 2 grid of 8 square game icons (each 512x512, touching, no gaps, no text, no labels, no numbers, no watermark) for a Roblox gym game. All 8 in exactly the same style: a dark near-black square tile (#141215) with a soft radial glow in the icon's colour behind the centre, a thin circular dial ring with small tick marks around the centre and faint light rays; in the middle a chunky cartoon emblem of a muscular blocky Roblox-style figure (simple head, no face details) striking the pose, filled with flat warm beige (#E9D6B0) with soft shading, a thick dark-brown outline (#24170F) and a few engraved lines for the muscles. Kid-safe: the figure wears a tank top and shorts. The pose must read clearly as a silhouette at 64 px. Left to right, top row then bottom row (glow colour):
1 Front double biceps: facing us, both arms up, fists beside the head (gold)
2 Front lat spread: facing us, fists on the hips, back flared wide (blue)
3 Side chest: side-on, front arm bent, hands clasped at the waist (red)
4 Abs and thigh: facing us, both hands behind the head, one leg forward (orange)
5 Most muscular: facing us, hunched forward, fists together low in front (purple)
6 Back double biceps: seen from behind, both arms up, fists beside the head (teal)
7 High five: one arm straight up with an open palm (green)
8 Victory wave: one arm waving high, the other hand on the hip (pink)
```
Then: cut into 8 PNGs, upload to Myanmar Builders Club, put the ids on the 8 emotes (`Config/ShowOff` Emotes: FrontDoubleBiceps, FrontLatSpread, SideChest, AbsAndThigh, MostMuscular, BackDoubleBiceps, HighFive, VictoryWave).

### 6. Small items
- **Trainers window X over OPTIONS:** on PC the header's last button (EVOLUTIONS) ran under the X, so tapping X opened the chart and the window wouldn't close. Fixed: a narrower button, a shorter EQUIPPED line ("+1 AT SPURT 4"), and the X drawn on top. Checked: X closes it.
- **Training dim:** the tutorial / guide spotlight dimmed the whole gym to half while you trained. Now much lighter (transparency 0.5 → 0.82).
- **Pro Gym:** lighter while you're inside (exposure +0.55, a touch of brightness, `GymMoodClient`). Before / after in the screenshots.
- **Treadmill:** GO TO now puts you on the belt (checked from the side). The card shows "MAX STAMINA 109 · +1 every 40 m run" (the bar's own max) instead of "Quads 0 / 6.47K".
- **PBR texture error:** **not found.** The error names no asset. I checked the 273 PBR textures (skins, plates, Hall marble / gold / roof materials, trainer hair): none of the ones I could look up is the wrong type, but 184 lookups hit Roblox's rate limit. Next step if it matters: Creator Hub > Error report > the message's "first seen" version.

### 7. Next goal
- **NEXT GOAL chip** (kit `RightColumn.Tracker`, gold) once the tutorial is over and Coach Dex is quiet. First that applies:
  1. a gym that's open but you've never trained in → GO TO it;
  2. the next boss: ready = "Beat BENNY at arm wrestling!" → GO TO him; not yet = what he needs → "Train next";
  3. the next plate tier you can afford (Gem Mine open) → GO TO the Plate Forge;
  4. else the next Growth Spurt / Alter → "Train next".
  Checked: it appeared after the Coral lesson and the Pro Gym guide, and a tap teleported me onto a machine in that gym; the NEXT BOSS version shows too.
- **"Needs BRONZE PLATES":** now "Top weight! BRONZE PLATES add more · TAP: Plate Forge". The tap already takes you to the Forge; with the Gem Mine shut it says where the Forge is and when it opens.

## Not done / open
- The 4th-place runway result with no card (see 3).
- The PBR asset (see 6).
- The Pro Gym change was previewed in Edit mode (the screenshot), not looked at in Play.
- Found but not in the prompt (not changed): the crew-gift free trainer roll opens its reveal by itself, even mid-training; in the phone test the left menu showed an extra open column (INVITE, ADMIN, CODES, FREE 1,000, PLUS) next to the tiles; toasts stack under the top band.

## Owner
1. **File > Save** in Studio.
2. Play once on a **new account** on a phone: Benny's fight and card, one Posing Show (POSE + results card), the Coral lesson.
3. Run the emote prompt above in ChatGPT (or tell me to run it in Chrome and wire the icons).
4. **Publish**, then after 2-3 days: Error report, the like ratio, the funnel.
