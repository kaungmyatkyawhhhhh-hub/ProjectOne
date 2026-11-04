---
date: 2026-11-04
tags: [gymarc, progress, runcards, plates, armwrestling]
status: built + tested in Studio (temp saves), not published
---
# GYM ARC - Legacy card backfill, next weight panel, tap arm wrestling (4 Nov)

Back to [[00 GYM ARC Home|GYM ARC Home]] · Related: [[GYM ARC - Run Cards]], [[GYM ARC - Arm Wrestling]], [[2026-11-04 GYM ARC Prompt - Plate tiers FINAL (7 Nov part 9)]]

Three owner prompts, all in Studio, nothing published.

## 1. Retroactive Legacy cards (GEM update)
Owner: players who already have stars must get the Legacy cards those stars would have given.
- **Save version 2 -> 3** (`DataMigrations` step 2). Every star already earned with no card in `runCards.legacy.byStar` gets 1 waiting LEGACY PICK (`runCards.legacyPicks = { "1", "2", ... }`). Then `runCards.legacyBackfill = true`, so it never runs twice. 0 stars = nothing.
- **The pick:** the same pick window (title "LEGACY CARDS", line "★2 Legacy card · Keep 1 of 3 · 2 more waiting"). 3 cards, each rarity rolled with the normal odds (Common 60 / Rare 28 / Epic 10 / Legendary 2), no "hold 2 of a type" rule (a legacy pick has no run). One free reroll, like every pick.
- The picked card goes to `byStar["<star>"]` and is legacy-active like a kept card (on while fewer than 3 are on, else stored; swap in MY BUILD).
- **Popup:** once a session, when nothing else is on screen (it waits for the daily streak, the trainer roll, guides, the shared popup queue), the window opens with "Your ★4 earned you 4 Legacy cards – pick them now". LATER keeps them on the RUN CARDS card ("4 Legacy card picks are waiting. Tap to pick!").
- Analytics: `LegacyCard_Backfill` (card id, star).
- **Tested:** the step on fake saves: ★4 -> picks 1,2,3,4; ★0 -> none; ★4 with byStar["2"] -> only 1,3,4; a second run -> nothing new. In Play (★4 save from version 2): popup line, tracker, 4 picks, `byStar` 1-4 filled, the ★4 strip on the Star Track shows "LEGACY: +30% TO YOUR TRAINERS' BONUS".
- **Note:** only 3 Legacy cards can be on at once (existing rule), so a ★4 player has 3 on and 1 stored.
- Fixed while testing: the window opened over the trainer roll / was pushed away by the daily streak. `RunCards` is now a cover screen (UIBus.CoverGuis) and `Kit.ModalOpen()` (new, small) lets it wait.

## 2. Weight panel: show the next weight
Owner: "didn't even notice heavier weights exist", "thought Gold was the top tier".
- **At your best weight:** "NEXT: 961 LB", a thin gold bar, and "Mid Chest 2.06B / 2.23B EXP" (short numbers, 3 digits; one more digit when both would read the same: "1.8996B / 1.9002B"). AT BEST is gone.
  - The bar fills from what your best weight needed to what the next one needs (a plain now / needed bar sat at ~97% all the time).
- **Plates not bought:** "Needs PLATINUM PLATES · Plate Forge" in gold (wraps to 2 lines, never shrunk). Tap = you get off the machine, go to the Plate Forge counter and its shop opens (server `PumpShop` "GoForge", Gem Mine must be open for you).
- **Tier line** "GOLD PLATES 3/13": wraps to a 2nd line on small screens, never "...".
- **Plate ladder** beside it: 6 small plates Bronze -> Diamond, owned = lit, the tier you're looking at = white ring, not owned = dim. Tap = the Plate Forge.
- **+ button:** a small lock badge while the next weight is locked. When a heavier weight unlocks and you weren't moved up, + glows and pulses 5 s.
- **Toasts:** "NEW WEIGHT UNLOCKED: 961 LB" once per weight (saved per machine `machines[id].toastTop`: re-unlocking after a Growth Spurt is quiet). A tier's last step: "GOLD PLATES MAXED" + "NEXT: PLATINUM PLATES (Plate Forge)", tap = the Forge (only when the next tier isn't owned). Diamond 13: "ALL PLATES MAXED". Toasts can now take a tap (`Notify.Reward(..., onTap)`).
- **Tested (Gem bench, temp save):** locked by EXP (PC + phone 667x375), locked by plates (PC + phone), just unlocked: toast + glowing + (PC), GOLD PLATES MAXED fired, the Forge shortcut (39 studs, shop open on PLATES). No errors.
- Not screenshotted: the glow on a phone frame.

## 3. Arm wrestling: TAP, not hold
Owner: "players just click, lose and leave".
- **Every tap pushes the bar** toward you: `TapPush` 0.09 x 2 x your share of the two strengths (equal strength = 0.09 a tap). The opponent pushes back all the time: an NPC at its taps a second (Rocco 2.5, Tess 4, Big Lou 5, bullies 5), a player with their own taps.
- **Strength** = the ladder power (spurts, alters, stars) x the arm look (biceps, forearms, triceps) x arm gear. Stronger = fewer taps.
- **Server** counts at most 12 taps a second, decides the result. Rewards, NPC ladder, titles unchanged.
- **Screen:** big pulsing "TAP!" button ("Tap fast to win!"), tap anywhere / Space / A works; every tap: the bar moves at once, a hit sound, the button pops, the bar shakes a little (more near the win; off with Reduced Motion).
- **Story:** the bully card says "You're stronger. Tap fast to win!"; the tutorial's first Benny match and Coral push for you (like 7 taps a second) so a new player still wins. Tutorial line: "Walk up to him and tap ARM WRESTLE. Then tap fast to win!". No "hold" text left.
- **Tested (fresh save):** vs Rocco at 5 taps/s: WON in 3.6 s. Weak save vs Big Lou at 12 taps/s: LOST in 3.6 s. Auto-clicker at ~40 taps/s vs Big Lou: still LOST (cap works). Real mouse clicks on the TAP button: 10 clicks = 10 taps counted. No errors.
- **Not tested:** PvP with two real players (Studio from here runs one player). A phone-frame screenshot of the match (the arm wrestle screen ignored the Studio phone-size switch; PC frame checked).

## Owner to do
- Save to Roblox. When publishing: this is a **save version bump (2 -> 3)**: back up first, publish with "Migrate to latest update", never roll back past it.
- Try PvP arm wrestling with a friend.
