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
- 2026-10-12: Settings kept its 4 rows and size; sliders replace the Music/Sounds toggles. "Sounds" instead of "Sound Effects" (fits next to the slider), ON/OFF buttons 120 x 48. Settings now save with the player's data. #break-a-bed
- 2026-10-12: training posts use a ProximityPrompt ("Train"/"Buy") like beds and auto-punch for free; the Auto Punch pass now only works at beds ("breaks beds for you!"). #break-a-bed
- 2026-10-12: free auto training punches every 0.25 s (4/s), so clicking (up to 8/s) is worth it; Auto Punch pass speed at beds is unchanged. Walking or jumping now ends bed breaking too (the note said "the same as beds", so both work the same). The guide ends training by itself after the 10 punches. The VIP post got a Train / "Get VIP" prompt. #break-a-bed
- 2026-10-12: soft shutdown: on server close, save a short-lived Resume (position, activity, Free Gifts progress) and move players to new servers (Roblox "restart for updates" + reserved-server backup); applied on join if < 3 min old. #break-a-bed
- 2026-10-12: Sound Effects default lowered from 85% to 40%; old saves still at 85 are moved to 40 once. #break-a-bed
- 2026-10-12: HUD: only Shop/Boosts move to the vertical middle of the left edge; the stats go back to where they were (the LeftColumn / stats-at-top change is reverted). #break-a-bed
- 2026-10-12: phones: HUD sized from screen height (squares ~11%, Shop/Boosts ~10%); squares in a column on the right edge, never a row across the top. #break-a-bed
- 2026-10-13: Sound Effects default is 40% (old saves at exactly 85 move to 40 once, flag SfxDefaultV2). Left side is one LeftColumn; on phones it sits top-left above the thumbstick zone (bottom 45%), Shop/Boosts go side by side on short phones, Group Bonus hidden, right squares go to 2 columns above the jump button, and the break screen moves to the top. #break-a-bed
- 2026-10-13: LeftColumn reverted: stats back where they were (PC bottom-left); Shop/Boosts centred on the left edge. Phones: stats moved to the top-left under the top bar (their old phone spot would overlap the centred buttons), Group Bonus hidden; HUD sized from screen height (squares 11-12%, buttons 10%, stat icons 7%); squares in a centred right column, 2 columns if needed. #break-a-bed
- 2026-10-13: Soft Shutdown via a reserved waiting-room server (5 s) then a new public server; Resume only in shutdown saves, under 3 min old, read from the save; welcome-back x2 Strength 5 min once per place version. Settings window scrolls (9 rows). 1KLIKES code is in but switched off until 1,000 likes. Replay Tutorial gives no rewards. #break-a-bed
- 2026-10-13: thumbnail scene lives in ServerStorage (never published) with a ThumbnailMode helper that saves and restores the game's lighting; the camera is placed from the far side of the bed so the character's face shows. #break-a-bed
- 2026-10-12: game title on Roblox is "[🎃HALLOWEEN] Break A Bed" until Nov 1. #break-a-bed
- 2026-10-13: Onboarding funnel only for new players, each step once per player (saved). Like goal number is set by hand (GameConfig.LikeGoal.Current). Favorite popup appears after the first new bed outside the guide, once ever, never rewarded. #break-a-bed
- 2026-10-13: owner chose to really check favorites on the Free Gift (Roblox permission window + GetFavorite), knowing Roblox's rules don't allow rewarding favorites. Like goal is automatic via RoProxy; LikeGoal gets an adapter onto GameConfig.Codes instead of a separate CodesServer. #break-a-bed
- 2026-10-13: favorite step removed from the Free Gift and Exclusive Chest (Roblox rule: no rewards for favorites). Screens ask Like (not checked) + Join group (checked). The no-reward favorite popup stays. #break-a-bed
- 2026-10-13: favorite step removed from the Free Gift and Exclusive Chest (Roblox rules); claim checks only the group. Daily Quests are the same 3 for everyone, reset at midnight UTC; all free boosts (quests, daily, gifts, spins, codes, welcome gift) go to the Boost Inventory, bought ones start at once; the Boosts button now opens the inventory. OP Day 7 boosts also go to the inventory. #break-a-bed
- 2026-10-13: the Boosts button stays as the Boost Inventory (owner). #break-a-bed
- 2026-10-13 (later): favorite step and favorite check put back on the Free Gift and Exclusive Chest (owner accepts the Roblox-rules risk). As before the removal: the favorite is checked on the Free Gift's Claim; the chest screen asks for it, but only the group unlocks the chest. #break-a-bed
- 2026-10-13: the Onboarding funnel became "Onboarding2" (13 steps: Loaded, Joined, …, Claimed First Gift, Played 3/5/7 Min, Stayed 10 Min). It has a new name because the steps changed; the old funnel keeps its data for comparing. Loaded = the server has the new player and their save; Joined = their game finished loading and they can move. #break-a-bed
- 2026-10-13: minutes 2–10 pacing: beds 6–10 and posts 4–7 re-tuned from a model of three players (normal, active, fast) so no wait is longer than ~75 s before 10 min. Bed 5 and the Bamboo Post kept (the funnel's first minutes work). Water 2.4K, Hospital 5.1K, Royal 12K, Gold 22K, Diamond 58K Strength (Health ~3x); Brick $4.3K, Stone $41K, Iron $100K, Steel $1.4M. #break-a-bed
- 2026-10-13: Starter Quests are first-session only, as asked (leaving early = gone; a Soft Shutdown hop keeps it; `FirstSessionOnly = false` would let players finish later). The card sits under the next-bed bar at the top, because PC stats are on the bottom edge (no room under them). Rewards start straight away (not in the Boost Inventory). The last goal stays "Break the Hospital Bed" as planned; with the new pacing that's about minute 4–5. #break-a-bed
- 2026-10-13: training combo is counted on the server (punches faster than auto alone); +10% / +20% / +30% Strength at x5 / x10 / x25. The click hint shows in the first 3 sessions and hides once you start clicking; saves from before today count as 3 sessions. #break-a-bed
- 2026-10-13: next-bed bar always on screen, also while breaking or training (phones: under the bed panel). Newly affordable beds/posts get the guide's arrow + beam for up to 40 s. Come-back toast once a session at 8 min, with tomorrow's daily day number. #break-a-bed
- 2026-10-13: the tutorial can't be skipped (SKIP removed). The Starter Quest/next-bed pills can be hidden with an x and brought back from the Quests menu (TRACK). The tutorial ends with dimmed-screen highlights on To Bed, then SPAWN. #break-a-bed
- 2026-10-13: top centre = one slim tracker pill (tutorial step → Starter Quest → next bed). Smallest size 240×36 on PC and 210×32 on phones, so it stays readable (6% of a 338 px phone screen would be 20 px). Boost timers became chips above Strength (PC) or under the Level bar (phones, where the stats touch the top bar). #break-a-bed
- 2026-10-13: To Bed button (owner): under Shop/Boosts, purple. Goes to the next bed if you're strong enough, otherwise your best broken bed. Hidden until the New Player Guide is done. Once every 2 s. #break-a-bed
- 2026-10-13 (later): To Bed = the best bed you can break right now (highest bed whose Strength you have). It's in the top bar next to SPAWN (owner chose this over the left column), small on phones, with a quick fade and a 3 s cooldown. #break-a-bed
- 2026-10-13: "Need more Strength?" box removed. Trying to break a locked bed shows only BREAK IT, priced by how many beds ahead it is (vs the best bed you can break): R$9 (1), 19 (2), 39 (3–4), 79 (5–7), 149 (8+). #break-a-bed
- 2026-10-13: guide last steps say CLICK on PC and TAP on phones ("CLICK TO BED!" / "TAP TO BED!"), like the other guide steps. If SPAWN disappears for 2 s during "TAP SPAWN!" (walked off the path), the guide ends. Short of $50 at the Wooden Post step = the server gives the rest. #break-a-bed
- 2026-10-13: one hide flag for the quest and next-bed pill (saved with Settings). The Quests window's top row shows the current Starter Quest or next bed, with TRACK / TRACKING. #break-a-bed
- 2026-10-13: BREAK IT products by bed gap (1, 2, 3–4, 5–7, 8+ beds ahead of the best bed you can break). A product bought for a smaller gap breaks the furthest bed it covers, never more. Prices are always read live from Roblox. #break-a-bed
- 2026-10-13: players finish all 25 beds in ~30 min. Plan: unique post models, Gloves, slower late game (beds 16–25), Rebirths with tokens, Bed Mastery, World 2. See [[Break A Bed/Content Plan|Content Plan]]. #break-a-bed
- 2026-10-13: undiscovered beds are black silhouettes named "???" (client-side, saved DiscoveredBeds, kept after Rebirth). The first break cracks the shell off with a "NEW BED DISCOVERED!" reveal. #break-a-bed
- 2026-10-13: Steel Post = riveted I-beam with a hazard base; Neon Post = pink/cyan neon tube tower (names not in the plan's table). Post sounds: Pro Sound Effects only (Roblox-licensed, play in any game). #break-a-bed
- 2026-10-13: Rebirth keeps Level (LevelFloor) and discovered beds/posts. Old saves that broke bed 15 or later have rebirth unlocked. Token upgrades: Head Start, Cheap Posts, Lucky Hits, Fast Hands, Daily Spins (1–3 tokens a level). The head tag uses 🔄 (the font has no ⟳). #break-a-bed
- 2026-10-13: Glove Shop stand moved to the plaza between spawn and the training area (visible from spawn), pad instead of a prompt. Invite Friend stand on the left of the plaza. Friend bonus counts Roblox friends in the same server, +10% each, max +30%. #break-a-bed
- 2026-10-13: shop order FEATURED → PASSES → DEALS (Starter Pack, Server x2, Spins) → STRENGTH → CASH. #break-a-bed
- 2026-10-13: gloves use the owner's Toolbox "blocky boxing glove" mesh (no scripts), recoloured per tier. The Glove Shop pad copies the Exclusive Chest pad's style (owner). #break-a-bed
- 2026-10-13: Glove Shop pad changed to a simple solid design (navy disc, white edge, one cyan glowing ring); the chest-style and see-through versions were dropped (owner). #break-a-bed
- 2026-10-13: Glove Shop pad = a plain flat glowing disc like a typical simulator pad (owner), replacing the solid navy version. #break-a-bed
- 2026-10-13: stand pads = big see-through tinted circle with a thick glowing neon ring (SELL-stall look); cyan for Glove Shop, yellow for Invite Friend. Invite figure = rongstrix's avatar (userId 1834504124). #break-a-bed
- 2026-10-13: game page showed "Ages 16+" → under-16 players can't join. Top priority: make the game all-ages (fix the questionnaire/age setting truthfully). #break-a-bed
- 2026-10-13: the 16+ limit lifts after 250+ engaged players (Roblox rule for new games). Goal: reach 250 engaged players fast, then the ads can bring kids. #break-a-bed
- 2026-10-13: Money leaderboard reuses the existing TotalCash save field (all Cash ever earned) instead of a new TotalCashEarned. Glove rarities: 2 Common, 2 Uncommon, 2 Rare, 2 Epic, 2 Legendary, Void Mythic, Infinity Secret. #break-a-bed
- 2026-10-13: map layout: stands in the front plaza (Glove Shop front-left, Invite front-right), training floor 76x88 with staggered posts. Music = a shuffled 3-song APM playlist. #break-a-bed
- 2026-10-13: Invite Friend stand at (-18.5, 35) between the upgrade boards and the VIP Lounge; plaza items keep 10 studs clear in front of boards, pads, crate, VIP door, arch and leaderboards. #break-a-bed
- 2026-10-13: training floor x 56..132 / z -6..42 with the TRAINING sign on its front edge; Glove Shop left of the spawn -> training route; leaderboards moved 8 studs back to make room. #break-a-bed
- 2026-10-13: AFK training hop at 15 min idle (before Roblox's 20-min kick), same server first, any server if full; only while training. #break-a-bed
- 2026-10-13: no city backdrop. The owner removed it on purpose and wants a clean, simple map floating in the sky. #break-a-bed
- 2026-10-13: the map stays clean on purpose: no city or backdrop around it (owner). Glove Shop kept about 4 studs from the VIP Lounge's glass corner. #break-a-bed
- 2026-10-13: gloves in the tutorial = a last step that leads to the Glove Shop pad and opens it, with no free glove (the first costs $91K), to keep early pacing. #break-a-bed
- 2026-10-14: Rebirth window = pictures (two cards, chips, icon row), 9 visible words; the lose/keep/get lists only behind "?". Tests that change Strength/Cash/Rebirths in Studio must be client-side (the real save is loaded and saved). #break-a-bed
- 2026-10-14: Rebirth resets the discovered beds and posts (they go black again; Bed 1 / Post 1 stay), reversing the earlier "never reset" rule. #break-a-bed
- 2026-10-14: buying a Head Start level tops Cash up to that amount immediately if you're below it (and still applies each rebirth). #break-a-bed
- 2026-10-14: Free Gift and Exclusive Chest need only the group (no like/favorite steps); a no-reward "Like and Favorite!" popup shows once, a minute after the group reward. A JOIN GROUP button + a once-per-session 3-minute popup bring the group offer back. #break-a-bed
- 2026-10-14: free boosts = x2 only, 15 min max, on their own timer; bought boosts stack on top (x2 free + x3 bought = x6). x3 products kept at 10 min (their pictures say 10 MIN). #break-a-bed
- 2026-10-14: break/training camera = fixed 3/4 side view sized to the bed/post (SessionCamera); steeper and closer at the training posts; JOIN GROUP button hidden during sessions. #break-a-bed
