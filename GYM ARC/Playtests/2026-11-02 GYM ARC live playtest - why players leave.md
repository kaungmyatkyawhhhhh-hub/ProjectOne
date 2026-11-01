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

**00:16-00:30 the storyline and the beach**
- After Spurt 2: a "BEAT BENNY · 16 studs" marker over the gym. No call-out shot, no card, no gold path: just the floating marker.
- **The INVISIBLE INVITE BUTTON is real live:** a tap on an empty spot (where the invite card had been) opened Roblox's Invite Friends screen (screenshot 18). Fixed in Studio tonight (MiniOffer).
- Walking backwards dropped me onto the BEACH RUNWAY stage ("You're a model! The show starts in 0:15"): the runway is ON the beach, while the Beach Gym is "locked behind Benny". Confusing.
- **THE RUNWAY show:** "NOW WALKING 1/4 J3FF311 / RATE J3FF311'S LOOK" with 5 stars (nice), but at **"YOUR WALK! STRIKE A POSE" my own character was NOT on the runway** (only NPCs far away). No result screen, +120 coins only, then the camera was left against a wall outside.
- **After the runway my character was invisible** and GO TRAIN did nothing (teleport broken, Benny stayed 222 studs away). Only Roblox menu > Respawn fixed it.
- Genetics (Coach Dex unlock guide): all B x1.00 + a FREE reroll -> Legs S x1.50, Arms A x1.20, Back D x0.75, Frame Average +5%, Body Balanced +5%. 2 DNA tokens given. Fun moment.
- Respawn: **a giant high-alter player ("Aesthetics God", marble/gold skin) stands on the spawn** and fills the screen.
- **The NEW PLAYER PACK popup opened by itself while I walked** (centre screen, big red BUY R$ 29, "30 min only", "SAVE 85%", "WORTH 199 R$"). It says **+26,600 coins; the Store card says +29,600** for the same pack.
- THE RUNWAY invite card came back every 2-3 minutes.
- **The camera gets stuck inside things all the time:** a pumpkin decoration, a giant NPC's body (Theo), above the gym ceiling (zoomed out), against walls.
- **Benny: the "Sit down / Arm wrestle" prompt by his marker did nothing** (tap E, hold E 1.5 s, click it). After 30 minutes I could not start the storyline at all. Either the bully and his table weren't built for me (the live build is older than tonight's Studio rebuild) or the prompt belongs to the shared PvP table. **For a new player, chapter 1 is a dead end in the live game.**

## Stopped at 00:30 (31 min, Growth Spurt 2, 4'8", 7,531 coins)
The owner asked to "play until u get first hall of fame". Not possible in one sitting: the Hall of Fame needs Growth Spurt 6 + 15 Body Alters + its goal (tuned to ~17-75 min PER alter for a normal player: 10+ hours in total), and the storyline was blocked at Benny. Stopped to write this up while it's fresh.

## WHY PLAYERS LEAVE (most important first)
1. **The first 5 minutes are a pile-up.** After Spurt 1: 6 NEW badges, 2 "!", a DEAL tag, a Starter Pack card with a countdown, Coach Dex 3 times, the full-potential scene, Benny's caption, a mission band, a toast, Roblox's Favorite prompt, then the trainer / genetics / inventory / poses unlock guides one after another. A kid can't tell what matters. **Fix: one thing at a time, everything queued behind the Growth Spurt moment, at most 1 popup per 30 s, no Favorite prompt before minute 10.**
2. **Broken promises in the first minute:** "+750 coins" never arrives (coins 0), "35.3K EXP / 13%" before any rep, the loading bar says 7'0", Dex says "You can GROWTH SPURT!" after you grew, "GROWTH SPURT 3 · NEXT: PRO GYM" while the Beach Gym is still locked.
3. **Monetization feels grabby early:** AUTO TRAIN opens a real-money prompt instantly; Starter Pack card + countdown + DEAL + PLUS +20% + a popup "30 min only / SAVE 85%" in the first 20 minutes. The low prices are good, but the frequency reads as a cash grab -> dislikes.
4. **The storyline doesn't start:** no Benny cutscene, only a marker, and the arm wrestle prompt does nothing. The whole "beat the bully to open the gym" loop is dead live, so the Beach Gym stays locked for a new player = the game feels like it has 1 gym.
5. **Camera and world bugs that look cheap:** camera inside pumpkins / NPC bodies / above the ceiling, the crunch bench camera straight down, the teleport wipe stuck on screen, an invisible character after the runway, spawning inside other players, other players' giant name tags covering the screen while lifting.
6. **Tap-through and invisible buttons:** a dialog tap opened a stranger's profile; an empty tap opened Invite Friends.
7. **Crowd vs big moments:** the "full potential" scene plays in the crowded gym; other players and their tags cover the 8'0" monster.
8. **Too many HUD buttons:** the left column = 8 tiles + INVITE, CODES, FREE 1,000, PLUS = 12 buttons, plus the Starter Pack card, quest card, spurt card, posing timer, DAILY and a SKIP pill. On a phone this covers the game.

## FIX LIST (for Studio; check each against tonight's Studio build first)
**P0, before the ads**
- [ ] Benny / bully arm wrestle can't be started live: test tonight's client-side story build on a FRESH save in a crowded server; ship it.
- [ ] Character invisible + teleports dead after THE RUNWAY (restore the real body, camera and Anchored after the show, even if the player leaves the stage).
- [ ] Runway "YOUR WALK" doesn't move / show the player's own character.
- [ ] Invisible invite button (fixed in Studio: MiniOffer) + automatic invite prompt (removed in Studio: FriendClient).
- [ ] AUTO TRAIN: show the Auto Rep card first (what it does, price); the Robux prompt only on its BUY.
- [ ] Welcome "+750" chip: pay it, or remove the chip.
- [ ] A new player shows 35.3K EXP and 13% before any rep: start at 0 / 0% (or say "starter EXP").
- [ ] The GO TRAIN teleport wipe sometimes stays on screen; the camera can land inside props: teleport to a clear spot and reset the camera.
**P1**
- [ ] Post-spurt pile-up: one queue (UIBus): Growth Spurt moment -> Benny call-out shot -> ONE unlock guide; Starter Pack card and Favorite prompt later (minute 10+).
- [ ] Full-potential scene: hide other players and their tags during it, or show it in a private spot.
- [ ] Stale Dex "You can GROWTH SPURT!" after growing; "NEXT: PRO GYM" while Beach is locked -> "NEXT: BEAT BENNY".
- [ ] Starter Pack: 26,600 (popup) vs 29,600 (store): one number. Check "WORTH 199 R$" is honest. The popup must not open while walking or every few minutes.
- [ ] Runway invite card: at most once per 10 min, never on a machine.
- [ ] Other players' name tags: much smaller, fade with distance, hidden while you're on a machine.
- [ ] Crunch bench camera straight down; camera collision with pumpkins / NPC giants.
- [ ] A dialog's close eats the tap (no tap-through to profiles).
- [ ] Loading bar 4'0" -> 7'0": should match the real ladder (6'0" last spurt).
- [ ] The AURAS store tab sells nothing: put the Aura Pack there or merge the tab.
- [ ] AUTO REP listed twice on PASSES.
**P2**
- [ ] Left menu: CODES / FREE 1,000 / PLUS into the Shop or one "+" button; keep the 8 tiles.
- [ ] SKIP pill visible with nothing to skip.
- [ ] Spawn: several spawn points; keep giants off the spawn pad.
- [ ] PUMP pill text cut ("TAP TO...").
- [ ] Memory 2.9-3.1 GB on PC: check on a phone.

## MONETIZATION SUMMARY
- Prices are kid-friendly (25-299 R$) and the Starter Pack (29) is a real deal: keep.
- Too many pushes in the first 20 min (Starter Pack card + timer, DEAL, PLUS, FREE, INVITE, the popup, the AUTO TRAIN prompt). Keep 1-2: the Starter Pack card after Spurt 1 and the Shop's DEAL tag. The popup after Spurt 2, once.
- AUTO TRAIN is the strongest seller AND the most dangerous: a card first, then the prompt.
- Full price list: [[2026-10-29 GYM ARC Prices - every coin and Robux item]].

