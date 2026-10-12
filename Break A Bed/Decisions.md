# Break A Bed: Decisions

#break-a-bed

Back to [[Break A Bed/Project Overview|Project Overview]].

## Current
- **2026-10-10: Punch combo, lag-proof effects, hand-made-looking UI, SPAWN only on the path.** The karate chop and alternating punch are replaced by left hook â†’ right hook â†’ uppercut. Effects are pooled and capped. The UI uses chunky buttons, navy panels and icons drawn from shapes (no emoji, no uploaded images; can be swapped for uploaded art later). SPAWN shows only inside the bed path zone and not in the break screen.
- **2026-10-10: The map is real models saved in the place** (owner's request), in Workspace folders Path, Beds, TrainingArea, Upgrades, Signs (plus Scenery). Scripts load them instead of building them. One template per bed in ServerStorage brings a bed back if it's ever missing. Breaking stays per player (only on your screen), so templates are a safety net. COMPLETED signs are real models too; each player sees only their own. Sign numbers still come from `GameConfig`.
- **2026-10-10: Cartoon style pass.** Kept the FredokaOne font (bold, rounded, the usual simulator look) and added thick dark outlines to all text. Short numbers use Qa/Qi and show in Roblox's player list too. Punches alternate arms. Bed breaks got more cash, sparkles and confetti. Saving got retries and quicker saves. The HUD shrinks on phones.
- **2026-10-10: Robux shop** on the left of the screen: +1 / +3 / +9 Level packs (suggested R$19 / R$49 / R$129) and a permanent x2 Strength game pass (suggested R$199). A level pack sets Strength to exactly what the new Level needs. Prices are suggestions; the real ones come from Roblox once the products exist.
- **2026-10-10: Critical hits.** 1 in 10 chops is a CRITICAL!: 3Ã— damage and bonus Cash on the spot (10% of that bed's break reward, at least $1), with orange text and a harder hit.
- **2026-10-10: "TOP Total Damage Dealt" leaderboard sign** on the right of the spawn plaza: top 10 across all servers, refreshed every 3 minutes, shows your own total too.
- **2026-10-10: Group Reward** ðŸŽ button on the right: join the Roblox group and claim **+10% Strength from every punch, forever** (Claude's pick; easy to change). Waiting for the owner's group id (`GameConfig.GroupId`); until then it says "Coming soon".
- **2026-10-10: Upgrade boards with green buy pads** on the spawn plaza: Training Speed (+0.15Ã— Strength per punch per level) and Walk Speed (+2 per level, 16 â†’ 60). Boards show current â†’ next and the price.
- **2026-10-10: Training is punching posts on glowing pads.** 17 posts (Strength per punch 1, 4, 17, 70, 290, 1.2Kâ€¦ up to 7.9B). Stand on the pad and click to punch; no break screen for training. Locked posts show ðŸ”’ + price; not enough cash shows "Not enough money". Replaces the 12 training items.
- **2026-10-10: Quality pass.** Lighting and sky effects, grass terrain with trees and bushes, brick spawn plaza, real sounds and music, more bed detail (folded sheets, quilt stitching, headboard panels), tile borders and floor numbers, fence caps, and much more hit/break feedback.
- **2026-10-10: Long fenced path of 25 beds on colored tiles.** Cardboard Bed â†’ Air Mattress â†’ Sleeping Bag â†’ â€¦ â†’ Infinity Bed (17 trillion health). Each bed needs more Strength (the prompt shows "Need ðŸ’ª X"), has more health and pays more Cash. Health grows ~3.3Ã— per bed, requirement = health Ã· 3.
- **2026-10-10: 12 training items** (up to Black Hole Cube, +3.8B per chop) so the trillions are reachable.
- **2026-10-10: Level curve changed** to ~35% more Strength per level, so levels keep coming into the trillions (Infinity Bed â‰ˆ Level 91).
- **2026-10-10: SPAWN button** at the top teleports you back to spawn, even mid-break.
- **2026-10-10: The current game lives in "Break a bed test version"** (placeId `92195183145806`), which the owner saved from the test copy.
- **2026-10-10: Rebuilt to the Chop A Brick spec.** Training area + a path of 15 beds, with Strength â†’ Level, Cash, E-to-Break, camera zoom, EXIT, karate chop, splinters and COMPLETED signs. The owner chose to **replace** the first version; rebirths and the coin rows were dropped. Rebirths could come back later as an add-on.
- **2026-10-10: Cash buys training items.** The spec didn't give Cash a use. Better items (Pillow â†’ Diamond Block) cost Cash and give more Strength per chop.
- **2026-10-10: Breaking is per player.** Each player breaks their own copy of a bed and sees their own COMPLETED signs, so players never get in each other's way.
- **2026-10-10: Beds respawn instantly** (no delay). The first break of a bed sends you back to normal view. After that, entering it keeps you in the break screen so you can break it over and over for cash until EXIT. (Replaces the earlier 5-second respawn.)
- **2026-10-10: Faster chopping.** Cooldown cut from 0.25s to 0.12s (about 8 chops a second); the arm swing was sped up to match.
- **2026-10-10: Damage = 1 + Strength Ã· 10.** Still needs balancing in real play.
- **2026-10-10: Everything is built from code.** No hand-built models or animation assets. The karate chop is animated in code. *(Later the same day the map was baked into real models; see above. Effects and animations are still code.)*
- **2026-10-10: The game lives in the Studio place "Break A Bed"** (placeId `116443177548785`). Claude puts scripts in through the Roblox Studio MCP.
- **2026-10-10: Notes go in this vault** (`ProjectOne`), folder `Break A Bed` only. City Legends notes stay in `City Legends`.

## Replaced (first version, same day)
- ~~Coins split by damage, rebirths (+1 damage, +50% coins, cost 500 Ã— 2.5â¿), locked tier row Cardboard â†’ Cosmic, "Canopy Bed"~~: dropped in the rebuild.

- 2026-10-11: HUD moved to the top (SPAWN + music center, stats top right, gift under them) inside the safe area; light-mode white panels; custom styled proximity prompt instead of Roblox's gray one. #break-a-bed

- 2026-10-11: on phones the Robux shop is one SHOP button (top-left) that opens a panel, so the thumbstick area stays clear. #break-a-bed

- 2026-10-11: map split into 5 themed zones (5 beds each) with gates; screen effects (edge glow, speed lines, flying cash, combo counter); sounds stay per player with a quieter version for nearby players. StreamingEnabled stays off (map ~4k parts). #break-a-bed

- 2026-10-11: back to Roblox's default proximity prompt (the custom one showed empty white boxes). HUD moved right up to the top edge (inside phone notches). Trees/hills/pond outside the play area replaced by a city backdrop with three landmarks (Bed Mart, Mattress Factory, Grand Sleep Hotel). Map now ~7.25k parts; StreamingEnabled still off. #break-a-bed

- 2026-10-11: more monetization: one Strength tier button (x2 â†’ x12 passes, highest counts), passes Auto Punch / x2 Cash / VIP / Fast Walk / Break Spam, products for 15-min boosts, spins and progress-scaled Cash packs, plus free daily reward, playtime gifts and a spin wheel. Tabbed SHOP panel; phones only show SHOP + the tier button. #break-a-bed

- 2026-10-11: punch and break sounds are now different: punches only make a punch thump; breaking a bed plays a big wooden crash ("Wooden Gate Crash 1") plus a short crack. #break-a-bed

- 2026-10-11: the top Strength tier pass is now x15 instead of x12 (still R$100). #break-a-bed

- 2026-10-11: punch and break sounds are client-sided: each player only hears their own punches and bed breaks (other players still see your punch animation). #break-a-bed

- 2026-10-11: the training platform floor is now dark grey tiles in a neat grid with thin dark grout lines. #break-a-bed

- 2026-10-11: walking into the VIP door without VIP opens the VIP game pass purchase window. #break-a-bed

- 2026-10-11: training numbers (post signs, the "click to punch" hint, VIP post hint) now include all Strength boosts: x2â€“x15 passes, the 15-min boost, VIP, group reward and Training Speed. #break-a-bed

- 2026-10-11: four leaderboards in a row by the training area: Top Total Damage and Top Total Money (all players, every 3 min), Server Top Damage and Server Top Money (players in this server, live). "Total money" = all Cash ever earned (spending doesn't lower it). #break-a-bed

- 2026-10-11: bed signs show the Cash a break pays you, including x2 Cash, the Cash boost and VIP. #break-a-bed

- 2026-10-12: the UI will be designed in **Figma** (owner's choice) and brought into Roblox as uploaded images, replacing the shape-drawn icons and panels. #break-a-bed

- 2026-10-12: new UI style because the old one looked AI-made: bright gradient buttons with a stud pattern, thick dark outlines, a 3D bottom edge and white Montserrat text with a dark outline, sharp corners (owner wants it sharp, not rounded). Images and rules in [[Break A Bed/UI Kit/UI Kit|UI Kit]]. #break-a-bed

- 2026-10-12: game pass prices stay as they are. Add lots of cheap developer products: timed x2/x3/x5/x10 Strength and Cash boosts, Cash/Strength/Level/Spin packs from R$5, a server boost, Instant Break, and a one-time R$19 Starter Pack. See [[Break A Bed/Shop Plan|Shop Plan]]. #break-a-bed
- 2026-10-12: UI matched exactly to the owner's reference: see-through dark window (transparency 0.41), stroke `#161822`, 3 px corners, Montserrat Heavy text with stroke + shadow. #break-a-bed

- 2026-10-12: Free Gifts playtime rewards (12 gifts from 1 to 90 min, reset when you leave, SKIP ALL R$99) replace the 5-minute playtime gift. See [[Break A Bed/Playtime Rewards|Playtime Rewards]]. #break-a-bed
- 2026-10-12: every menu and button gets animations (open, close, hover, press, idle, ready, ending) and satisfying sounds from Roblox's free Creator Store sounds. See [[Break A Bed/UI Kit/UI Kit|UI Kit]]. #break-a-bed

- 2026-10-12: all developer products lowered to R$1â€“R$49 (owner thought they were too expensive; products had only made R$36 vs R$501 from passes). Starter Pack R$9, Instant Break R$2, Skip All gifts R$49. Game passes unchanged. #break-a-bed

- 2026-10-12: no product under R$3 (Roblox keeps 30% and rounds down, so R$1 earns 0). Tiny packs dropped; +1 Spin and Instant Break R$3; x3 boosts R$6. 25 products + 11 passes in total. #break-a-bed

- 2026-10-12: product prices raised to R$9â€“R$49 (owner wants each above R$5â€“6). x2 boosts R$9, x3 R$15, x5 R$25, x10 R$49; packs R$9/15/30/49; Starter Pack R$19; Instant Break R$9. #break-a-bed

- 2026-10-12: all 15 new developer products created on Roblox (ids in [[Break A Bed/Shop Plan|Shop Plan]]). #break-a-bed

- 2026-10-12: built the New Player Guide, the UI Kit, Free Gifts and the Shop Plan in that order (owner's order), testing each in Studio before the next. Details in [[Break A Bed/2026-10-12|2026-10-12]]. #break-a-bed
- 2026-10-12: the old CASH PILE / BAG / VAULT products are reused as Medium / Big / Huge Cash (40 / 150 / 500 breaks), as the Shop Plan says. #break-a-bed
- 2026-10-12: Free Gifts' timer starts when a new player finishes (or skips) the guide, so nothing pops up during it. Players who already finished it start the timer on join. #break-a-bed
- 2026-10-12: the Starter Pack pop-up waits until you leave break mode and no other window is open, so it never interrupts breaking. #break-a-bed
- 2026-10-12: main-screen buttons don't bob or move when idle (they only animate on hover, press or "Ready"). #break-a-bed
- 2026-10-12: PC side buttons are SHOP, the Strength tier button, then SPIN and AUTO squares. The Free Gifts button is on the right under the group reward. #break-a-bed

- 2026-10-12: no idle animation on main-screen buttons (too much movement). Idle effects only inside open menus. The "Ready" pulse/wiggle stays. #break-a-bed

- 2026-10-12: no idle animation on main-screen buttons (too much movement). Idle effects only inside open menus. The "Ready" pulse/wiggle stays. #break-a-bed
- 2026-10-12: main screen + tutorial go **light and icon-first** (square shiny icon buttons, light stat panels, colored numbers). Ground guide = moving arrow Beam. Big menus stay dark with the rainbow title. #break-a-bed
- 2026-10-12: square icon HUD rejected. Main screen keeps the old wide-button layout in the owner's "Shop" reference design (gradient, diamond pattern, light inner border, 3D icon, Press Start 2P pixel text). Stats + tutorial light. #break-a-bed
- 2026-10-12: owner preferred the rounded gradient version over the square "identical" copy. Side buttons made **short** (about 236 Ã— 88). #break-a-bed
- 2026-10-12: **FINAL UI direction**: the owner's favourite simulator look (solid studded buttons with same-color dark outlines, white glyph icons, Montserrat Heavy, dark studded shop with a shiny green title bar, scrolling sections, floating italic stats, square right-side buttons) plus big effects (server announcements, flashy bed breaks, auras). Earlier styles replaced. #break-a-bed
- 2026-10-12: Daily reward, Spin wheel and Free Gifts moved out of the shop's FREE tab to their own square buttons on the right of the main screen (with badges and the gift countdown). #break-a-bed
- 2026-10-12: light rays behind open menus removed ("circus" look). Shop restyled closer to the other game (L pattern, thin outlines, lime price buttons). Item pictures should be real 3D (ViewportFrames or 3D icon images), not flat drawings. #break-a-bed
- 2026-10-12: limited Aura Crates added to the plan (weekly crate, 6 auras boosting Strength + Walk Speed, R$49 / R$129 / R$399, pity at 50). #break-a-bed
- 2026-10-12: FINAL STYLE built in the game. The Strength tier button left the main screen: the "DOUBLE Your STRENGTH x1 â–¶ x2" card at the top of the shop's Strength section replaces it. Boosts opens the shop at Strength. #break-a-bed
- 2026-10-12: the pink group reward button is gone; the "Group Bonus: +10%" line under the stats opens it (yellow "Join group: +10% Strength!" until claimed). Music moved from the top bar into Settings (Music and Sounds on/off). The rainbow title bar is dropped for the green one. #break-a-bed
- 2026-10-12: no purple "gift to a friend" button on shop cards yet: it needs real gifting code (pick a player, give it to them). #break-a-bed
- 2026-10-12: stats go back to the stacked LVL / Strength / Cash bars, but in light mode (light studded panels, yellow LVL badge, green bar, yellow and green numbers). #break-a-bed *(Not built yet: the game still has the floating italic stats. Check with the owner which one stays.)*
- 2026-10-12: **Free Rewards built** ([[Break A Bed/Free Rewards/Free Rewards|Free Rewards]]). The FREE chest stands on the open paving left of the VIP lounge (left of the flower bed, clear of the lamp post) and faces spawn. Chest = 20 breaks of your best bed (at least $500), every 15 min. Ad = 100 breaks (at least $2.5K), every 10 min. Free Gift = 50 breaks (at least $50K) + x2 Strength 15 min, and it also gives the Group Reward. #break-a-bed
- 2026-10-12: the Free Gift popup can be reopened from a cyan "Free Gift!" button in the Free Gifts window and from the yellow "Join group" line under the stats, until it's claimed. #break-a-bed
- 2026-10-12: the ad board stays hidden until a developer product for the ad reward exists (`GameConfig.AdReward.ProductId`); the owner has to make it and turn on Rewarded Video in the Creator Dashboard. #break-a-bed
- 2026-10-12: stats go back to the stacked LVL / Strength / Cash bars, but in light mode (light studded panels, yellow LVL badge, green bar, yellow and green numbers). #break-a-bed
- 2026-10-12: changed mind: keep the current stats as they are (no light stat bars). #break-a-bed
- 2026-10-12: the chest is no longer free for everyone. It's a GROUP CHEST: it opens only for Myanmar Builders Club members (checked); like and favorite are asked but can't be checked. #break-a-bed
- 2026-10-12: rewarded video ads on hold (the game isn't eligible yet). The ad board is switched off (`AdBoardEnabled = false`) until it is. #break-a-bed
- 2026-10-12: GROUP CHEST built. Non-members who step on the pad get a "Group Chest!" screen ("~ MEMBERS ONLY! ~", the chest's Cash, the same 3 steps as the Free Gift, an "I joined!" button). The group check is shared (`InGroup`, checked on join, on "I joined!" and on the Free Gift's Claim!). The ad board part was removed from the map; its code makes a board above the chest by itself when `AdBoardEnabled` is turned back on. #break-a-bed
- 2026-10-12: stats rebuilt to match `preview-stats.png` (star level badge, studded bar, 3D dumbbell, money-small, italic gradient numbers, one font). Phones get smaller stat icons so the stats stay above the thumbstick. #break-a-bed
- 2026-10-12: GROUP CHEST reward raised to 40 breaks of the best bed, at least $1,000 (was 20 / $500). The Group Chest screen adds "(grows as you level up!)". #break-a-bed
- 2026-10-12: the first limited crate is HALLOWEEN AURAS (Ghost, Bats, Web, Pumpkin, Cursed, Reaper) until Nov 1. Galaxy moves to later. #break-a-bed
- 2026-10-12: Group Chest renamed to EXCLUSIVE CHEST, with a unique purple/gold floating chest, rune circle, light pillar and particles. Claim = like + favorite + join (only the join is checked). #break-a-bed
- 2026-10-12: EXCLUSIVE CHEST built (replaces the Group Chest, same spot left of the VIP lounge): a floating purple-and-gold chest with a rune circle, light pillar, sparkles and rays. The Group Chest model was removed. #break-a-bed
- 2026-10-12: Daily Reward pictures: Cash days use bigger money piles for bigger rewards; Day 3 (Cash + 1 Spin) shows the money with a small wheel; the boost day uses `icon-boost-x2`. Today's card is clicked (or Claim!) to claim. #break-a-bed
- 2026-10-12: the whoosh plays only for big windows (Shop, Free Gifts, Daily, Settings), at most once every 2 s per window; closing a window is a lower pop instead of its own sound. #break-a-bed
- 2026-10-12: Effects built ([[Break A Bed/Effects/Effects|Effects]]). Bloom Threshold 1.5 instead of the note's 0.92 (white floors were washing out). Phones start with Low Graphics on. Announcements: Level every 25, beds 21–25, Server x2. Rebirth trails wait until rebirths exist. #break-a-bed
- 2026-10-12: Exclusive Chest rebuilt from the owner's Toolbox treasure chest (purple wood, gold metal, pink gem, 5.5 studs, one thin ring, soft glow) and moved to the grass left of the bed path past the entrance arch (away from the VIP lounge). #break-a-bed
- 2026-10-12: Exclusive Chest doesn't turn any more; its pad is the hitbox and got a fancy look (purple stone, gold rim + studs, glow, runes). The owner moved it into the plaza at (−28, 28). #break-a-bed
- 2026-10-12: Exclusive Chest floating effect built. The swirl is a spinning decal disc instead of a flat particle (flat particles with no speed didn't render reliably). #break-a-bed
- 2026-10-12: Halloween Aura Crate built. A newly rolled better aura is equipped automatically. Gifting = pick a player, then the next crate purchase within 2 min goes to them. Aura star = +10% of the boost (x3 → x3.2). The right side now has 5 squares (Daily, Spin, Gifts, Auras, Settings), slightly smaller. Crate product ids still to add. #break-a-bed
- 2026-10-12: the Exclusive Chest opens from an invisible Trigger under the chest (not the pad); its popup has a big purple "+EXCLUSIVE CHEST!". #break-a-bed
- 2026-10-12: auras use the owner's AuraLayers module (layered, lighter for yourself, others only within 60 studs). Shop cards: product pictures + price-tier colours, best item per section is a wide card. The Halloween card is compact (45% of the shop) and still. #break-a-bed
- 2026-10-12: Free Gifts VFX: the full READY effects show on 2 ready cards at most (keeps about 40 effect images); the card dims only after the claim pop. #break-a-bed
