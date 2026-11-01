---
date: 2026-11-02
tags: [gymarc, playtest, live, retention, monetization, bugs]
---
# GYM ARC - live playtest in the Roblox player (2 Nov, Claude Code)

Owner (1-2 Nov night): "play the gym arc game by ur self, not in studio, in roblox player ... find why players keep leaving ... what makes the game bad and get dislikes ... bugs ... why the cutscene and animations and the storyline and the entire start of the game is messed up ... document everything" + "play until u get first hall of fame" + "also document about the monetization". Live version = before tonight's Studio fixes (right drawer not expandable on a machine).
How: our `play-roblox` tool (rbx.exe), owner's account (fresh save, display name 2asccq3r5qew), screenshots in `2026-11-02 live player playtest/`.

## Game page (00:00)
- Search "GYM ARC": [HALL OF FAME] GYM ARC, **74% likes, 105 players**. Neighbours: Gym League 96%, My Gym RNG 97%, Gym Star Simulator 92%, Power Lifters 90%, Muscle Legends 88%, Untitled Gym Game 87%. **We are the lowest-rated gym game on the first row.**

## Play log (real clock)
**23:59 join**
- Loading screen: "WARMING UP..." with a height bar 4'0" -> **7'0"** (the max Growth Spurt is 6'0" live; misleading). Roblox memory 2.9-3.1 GB during load (high; phones will struggle). Took ~15 s.
- First frame: spawned INSIDE another player at the Flat Bench (2 players stacked on the spawn).
- **Top bar shows 35.3K EXP at 4'0" for a brand-new player** and the GROWTH SPURT 1 card says **13%** before any rep. Looks like a bug / confusing ("what did I do?").
- Coach Dex: "Welcome! Lift to grow TALLER. Here's 2x EXP for your first 25 minutes!" with a **+750 coins** chip. **Coins stayed 0** after tapping: the +750 never arrived (only +100 for the first rep later). Broken promise in second 10.
- Tutorial step text "Walk to the Flat Bench and tap Occupy." + gold GO TO FLAT BENCH button (teleports, good).
- At the bench: my name tag, the E OCCUPY prompt and the machine's "Mid Chest 53%" diamond all overlap above the head.

**00:00 first set**
- FIRST REP! +100 coins. EXP jumps 49.6K -> 684K -> 962K in 30 taps: numbers explode (fine) but the bar shows 56% after one set.
- **Other players' name tags are HUGE** (Chayan..., "Glow Up" title) and cover half the screen while lifting.
- "Great set! Tap STOP" dims the screen; the PUMP pill says "TAP TO..." (text cut off).
- Squat Rack (GO TO): fine. 35 reps -> 85%. The red REP button shows "x14 / x22 / x26" combo counter.
- **INVITE A FRIEND card pops up in the middle of the tutorial while lifting** (bottom centre, over the stamina bar). Interrupts the first minutes.
- Tutorial: "Tap your GROWTH SPURT bar to see which muscles to train next" -> the small strip at the top left (on a machine) opens GROWTH SPURT 1 "Your core is furthest behind. Train: CRUNCH BENCH [GO]" + SEE YOUR PHYSIQUE. Clear.
- Crunch Bench: Coach Dex again "Every muscle on your GROWTH SPURT bar has to be full." (1/2), still showing the +750 chip.

**00:03 Growth Spurt 1 (~4 min after joining)**
- READY TO GROW popup (TAP TO GROW / LATER) -> cutscene: gold silhouette "4'3"" -> "4'0" -> 4'4"", "Muscles start fresh · Gains x1.36". Short and readable. Good.
- **Right after it, everything at once** (screenshot 11): the left menu goes from 6 padlocks to 6 NEW badges + 2 red "!", a STARTER PACK card "Worth R$ 199, ONLY R$ 29" with a 23:00 timer, a DEAL tag on SHOP, Coach Dex "A heavier weight just opened", a stale SKIP pill, the DAILY "!" - then the full-potential scene.
- **"THIS IS ONLY THE BEGINNING / Your full potential: 8'0" MASS MONSTER"** scene: the 8'0" monster is shown IN the crowded Starter Gym; other players lifting in front of it and their giant name tags ("Beginner Gains Farousss7") cover it. The payoff moment is ruined in a busy server. Fix: put the camera on a clean spot (or hide other players / their tags during it, LocalTransparency), always facing away from the crowd.
- Then a 2nd wave: Benny's caption "Nice growth spurt, shorty. You're still not..." + the "GROWTH SPURT 2: fill every muscle again. Beat Benny to unlock the BEACH GYM!" band + a "(x GAINS)" toast + **Roblox's Favorite prompt** + Coach Dex "Great work! You're 0% of the way to Growth Spurt 2" (screenshot 13). **5 things at once.** Benny's call-out SHOT never played (only his caption, under everything else). "CHAPTER 1 · THE NEW KID - Beat Benny at arm wrestling to..." came as a toast after.
- Coach Dex then: "when you play again tomorrow, I'll have a free trainer roll and 500 coins for you" (good D1 hook). Then the TRAINERS unlock guide.
- **Tap-through bug:** the 3rd tap on a dialog that just closed went through to the world and opened a stranger's PROFILE (Cell1169). Dialog close should eat the tap (or a 0.3 s input guard).

**00:05 the store (monetization)** - see MONETIZATION below.
- **AUTO TRAIN button on the machine panel opens Roblox's REAL-MONEY purchase prompt at once** ("Buy Robux and item: Auto Rep 249, 500 Robux $6.98") for a player with 0 Robux. No explanation card first. A kid tapping "auto train" expecting a feature gets a payment screen: dislike / refund-request bait. (Reps kept going behind it.)

**00:06-00:15 grind to Growth Spurt 2**
- Loop: REP x40 -> the GO TRAIN <GROUP> button appears on the machine -> teleport to the right machine -> E. Smooth once learned. ~10 min for Spurt 2 (with 2x new-player EXP).
- **GO TRAIN teleport bug:** once the wipe transition stayed stuck over half the screen (a blue panel with a machine outline) and the camera ended up inside a giant pumpkin decoration (screenshot 15). E got me out.
- Stamina 100 runs out after ~45-80 reps (combo REP x65+), then reps stop until it refills; the REP button just does nothing at 0 (no "out of stamina" cue seen on the deadlift).
- Pop-ups during the grind: "LIFTING TOGETHER +10% gains", NEW WEIGHT UNLOCKED (often), TODAY'S QUEST, POSING SHOW timer, **THE RUNWAY "Walk the runway... YES, I'M IN / NO"** card over the machine (screenshot 17). The left menu also got INVITE +10%, CODES, FREE 1,000, PLUS +20% EXP buttons: **the menu column is now 12 buttons tall**.
- A "SKIP" pill stays at the top for minutes with nothing to skip.
- **00:15 Growth Spurt 2 (4'8").** Coach Dex then says "You can GROWTH SPURT! Grow taller..." AFTER I grew (stale guide, screenshot 16). Card: "GROWTH SPURT 3 · 0% · NEXT: PRO GYM" while the Beach Gym is still locked behind Benny (confusing: which gym is next?).
- The Roblox window dropped out of full screen by itself once (taskbar showing).

## MONETIZATION (what a new player sees)
- **Store (SHOP tile, DEAL tag from Spurt 1).** Tabs PASSES / AURAS / BOOSTS / COINS + "COACH DEX" and "GO TO PUMP SHOP" buttons.
  - PASSES: AUTO REP 249 (hero "BEST SELLER": "Lifts for you while you're on a machine"), 2X EXP 249, 2X COINS 149, VIP 299, AURA PACK 199, AUTO REP again 249 (listed twice: hero + grid), EXTRA TRAINER 99.
  - AURAS: nothing to buy: every tile is an EXP goal (Ember 10M, Frost 50M, Storm 300M, Golden 1B, Titan all quests, Peak Human Alter 5) + VIEW AURAS. A store tab with no products (the paid Aura Pack is in PASSES).
  - BOOSTS: STARTER PACK 29 ("NEW PLAYER PACK, only in your first day. +29,600 coins, 2 free trainer rolls, 3 Protein Shakes, a DNA Token, 30 min 2x EXP, the..." text cut off), SHAKE BUNDLE 49, ENDLESS STAMINA 49, DNA TOKEN 99, DNA TOKEN X3 249.
  - COINS: SMALL 25 (+7,410), MEDIUM 99, LARGE 249.
- HUD pushes: STARTER PACK card under the Growth Spurt card ("Worth R$ 199 / ONLY R$ 29", countdown 23:00 -> 20:00), DEAL tag on SHOP, PLUS +20% EXP button, FREE 1,000 (group/like reward), INVITE +10%.
- AUTO TRAIN -> instant real-money prompt (above). Biggest risk item.
- Good: prices are low (25-299), the starter pack is a real deal, nothing forced to progress so far.
- Risky: "Worth R$ 199" anchor on a pack (Roblox's rules: value claims must be honest; fine if the items really total that), the AUTO TRAIN prompt, the countdown timer + DEAL + PLUS + FREE + INVITE all inside the first 5 minutes.

(continued)
