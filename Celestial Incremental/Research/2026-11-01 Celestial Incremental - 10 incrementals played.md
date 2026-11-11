---
date: 2026-11-01
tags: [celestial, research, competitors, incremental]
source: played live on the owner's PC (Roblox account LuigiRED / HEINHEIN1922), 1 Nov 2026; live player counts from games.roblox.com at the time
---
# Celestial Incremental - 10 incrementals played (competitor research)

Owner (1 Nov): "learn how to play these other 10 incremental games and then get the information and we can use whats good from them."
Picked from the top Roblox incremental lists (topincrementalgames.com, rbxtcg.com) by live players, then checked live with the Roblox games API.

| # | Game | Playing (1 Nov) | Visits | Rating | Core idea in one line |
|---|---|---|---|---|---|
| 1 | Noob Incremental | 4,389 | 53.5M | 96% | Buy noobs that make Oofs; hex upgrade TREE with hidden nodes; prestige; runes RNG |
| 2 | Idle Mafia Game | 3,485 | 17.3M | 87% | Pure 2D UI "Mafia Wars": jobs with energy, properties that pay per real hour, crews, families |
| 3 | Immortality Incremental | 2,169 | 43.8M | 98% | Cultivation: click for Qi, BREAKTHROUGH to the next realm is a luck roll with shown odds |
| 4 | Tower Incremental | 1,153 | 6.7M | 89% | Climb a tower; every floor is a themed room with a new mechanic; glyph collection |
| 5 | Resource Incremental | 663 | 6.8M | 96% | Noob-Incremental template; GLOBAL MILESTONES: likes / favourites / CCU boost everyone |
| 6 | Dropper Incremental | 599 | 11.6M | ? | Dropper tycoon that levels up with use; daily login calendar; in-world product signs |
| 7 | Grass Cutting Incremental | 145 | 30.1M | ? | The old genre king: cut grass, level perks; plain blocky look, now small |
| 8 | Circle Grinding Incremental | 153 | 25.8M | ? | A circle under you grinds crystals; "Steps Completed 0/723 (0%)" whole-game meter |
| 9 | Grass Incremental Simulator | 126 | 41.6M | ? | Trim grass with a blade that grows with upgrades (visible on others), level-locked areas |
| 10 | Faith Incremental | 173 | 11.7M | ? | Stand inside a church to earn Faith (zone income); stained-glass upgrade boards; event hunt |

(The raw play notes for each game are below the summary.)

## What the top games share (the patterns)
1. **The next step is always shown in the world**: a white chevron BEAM / giant floor arrows / bouncing arrows over targets (Noob, Immortality, Tower, Dropper, Circle, GIS). Plus one quest line at the top ("Go closer to the grass and trim it").
2. **One-line tutorial bar with a character portrait and SKIP** (Immortality's elder, Mafia's boss): short, always one action.
3. **Community boosts that grow with the game**: "Every LIKE boosts cash x3.18, every FAVORITE boosts diamonds x1.79, every CONCURRENT USER boosts stats x1.41" (Noob + Resource), "for each FRIEND in the server +100% money" (Circle), Friend Boost +x% (GIS), "join the group for a free auto clicker" (Dropper), "like and favorite for x2" (Circle, Immortality). Every player has a reason to like, favourite, join the group and bring friends: free growth.
4. **Prestige/rank shown above your head** (Immortality realm "Qi Gathering I [#1]", Tower "Rebirth 0"), and **upgrades visible on your character** (GIS: other players' trimmer blades are huge).
5. **Hidden-node upgrade trees / collection books** ("?" hexes in Noob, "???" in Circle, "Discover the rune" in Resource, Glyphs 0/100 in Tower, Marks slots in Immortality): curiosity pulls you forward.
6. **Rank-ups with odds** (Immortality: breakthrough "1 in 1.85" with Breakthrough Luck x1.5): the RNG thrill inside an incremental.
7. **Live-world modifiers**: weather (Sandstorm 1:59) + season (Summer) boosts (Immortality), Weekend Boost list (Noob), 2X WEEKEND BUFF timer (Mafia), "2x Event" pill (Faith), timed collectible hunts (Faith candy corn 0/15, respawn 14:15), global boss (Mafia).
8. **Daily playtime ladders** (Mafia 5/15/30/60/90/120/180 min with named crates; "Played today 0:07") and **daily login calendars** (Dropper).
9. **Everything named is visible before it's unlocked**: grey "LEVEL 2 / LEVEL 3" rows (Mafia), "Reach Level 5 to unlock" walls (GIS), "Reach Tier 3 to unlock" doors (Circle), "Unlock Perks at level 2 (0%)" (GCI).
10. **A whole-game completion meter**: Circle's "Steps Completed 0/723 (0%)".
11. **Each new area = one new mechanic** (Tower: The Mine, Smeltery, Merchant, Glyph floors, Upgrade Tree... per floor).
12. **Monetization in the world**: product bubbles and signs next to the action (2X GRASS 49 R$, Auto Trim 39 R$, Auto Clicker 109 R$, Permanent x2 Cash 39 R$), early soft offers ("2x Walkspeed for you? [29] [Nevermind]"). Free path to a pass with earnable tickets (Circle).
13. **Public leaderboards everywhere at spawn**, incl. Top Robux / Robux Spent (whale boards) and Top Sects/Guilds.
14. **Pure-UI games can hold 3.5K CCU** (Idle Mafia): depth (many locked tabs, mastery bars per job, real-time hourly property income) beats graphics.

## What was weak (avoid)
- Long walks to the first action in big worlds (Noob Incremental): I spent minutes finding the starter station; small/forgiving islands (GCI: walk off into water).
- Windows that won't close (Dropper's Daily Rewards X), changelog popup on join (GCI).
- Daily quests with absurd goals for new players ("Roll 56.3k runes, play 2h53m") (Noob).
- Plain default-stud looks (GCI, Dropper) = the genre's old guard is shrinking (GCI only 145 players now).

## What Celestial already has (good)
Server-wide STAR SURGE bar (co-op, nobody else has a shared goal like it), shared sky, friends boost (+10% each), cinematic Supernova, meteor shower event, daily streak + playtime gifts + quests, satellites visible orbiting you, gravity ring, tutorial with a pulsing button, kit UI, nebula island.

## TAKE FOR CELESTIAL (proposed, in order of impact)
1. **Community milestones star board at spawn** ("Every LIKE: +x% stardust", "Every FAVORITE: +x% shards", "Every PLAYER online: +x% rain", "Join P&L Studios XP: +10%") using real like/favourite counts (fetched server-side every few minutes); show the next milestone. Fair: free for everyone.
2. **A floor BEAM / glowing arrow trail** from the player to the current tutorial target (the altar, an upgrade, the star map) + the one-line quest at the top (we have the hint pill; add the beam).
3. **Show progress on the avatar**: realm-style title over the head ("Supernova 3 · Orion"), the gravity ring and satellites already show; add a halo/aura colour by Supernova count so others see it.
4. **A whole-game "Cosmos Charted 0 / N (0%)" meter** (every upgrade level, constellation, mote type found, star map node) in the profile + HUD.
5. **Hidden "?" nodes**: the constellation map and shard upgrades start as "?" until the previous is bought; a MOTE INDEX (collection book: Dust, Ember, Nebula, Comet, Nova, + event motes) with "Discover" placeholders.
6. **Rank-up with odds** as an optional thrill: e.g. a "STAR FORGE" roll at the altar with shown odds (never sold luck).
7. **Rotating cosmic weather** (Solar Wind: +x% speed; Aurora: nebula motes; Eclipse: comets) every ~10 min alongside the meteor shower, shown in an ACTIVE BOOSTS panel with timers, + weekend x2 schedule.
8. **Event collectibles**: hidden "lost stars" around the island, 0/15 with a respawn timer (scavenger hunt).
9. **Playtime ladder with named crates** like Mafia (5/15/30/60/90/120 min), "Played today" shown.
10. **Area/level gates you can see**: a locked second island (e.g. "THE RING NEBULA - reach Supernova 5") visible across the void from day 1.
11. **In-world product bubbles** next to the action (x2 Stardust bubble near the field, Auto Gravity sign) once passes exist; a free path to one pass with earnable tickets.
12. Keep the island compact; no changelog popups; every window closes on X and on tapping outside.
# Played notes (raw)
## 1. Noob Incremental (Ghoulax Games) - 4,389 playing, 53.5M visits, 96%
- Spawn HUD: top centre "0/5T Oofs" = progress to Prestige 1 (the goal is the HUD title). Left: prism counter (+4.25 every ~60 s timer, shown as [52s] countdown), settings, profile.
- "Weekend Boost" list on the left (x2 realm currencies, x1.5 aura luck, x1.5 prisms, x1.5 minion luck, x2 expedition luck, x2 hacker points, ends in 17h) - a real weekend event, shown as a plain text list.
- Bottom bar: Shop, Tree, Inventory, Quests (4 icon buttons, red badge on Tree).
- One persistent guide card at bottom centre: "Buy First Noob - Purchase your Starter Noob 0/1" + a white chevron BEAM on the ground leading to the target.
- UPGRADE TREE: full-screen dark hex grid, nodes hidden as "?" until a neighbour is bought (fog of war); hover tooltip shows "+1.5% -> +3%" / "x2 -> x2.5"; nodes show level 0/10 and cost; first node FREE. Spent with prisms (slow timer currency).
- World boards (SurfaceGui): "Oof Upgrades" (More Oof x1->x2 "x2 every 15 upgrades", cost 75 Oof; Faster Noobs -0s->-0.1s 10k Oof) with Buy + Max buttons (red / pink).
- "GAME MILESTONES" board: community goals - Game Likes 75.7k -> x2.5 Rune Bulk, Favorites goal -> x3.36 Rune Luck, Game CCU 18.3k -> x1.03 stats, Group Join -> +x% (inactive) = the whole player base unlocks boosts by liking / favouriting / being online. (strong growth hook)
- Profile window: stats (Oofs, playtime, prisms, runes opened, dice rolled, enchants, cards, capsules, robux spent) + titles; Rune Luck x3.36, Rune Bulk +2, Rune Speed 1s, RPS 2 -> RNG "rune" rolling is a side system.
- Daily quests: Open 56.3k runes, Play 2h53m, Buy 6.83k upgrades, Harvest wheat (huge numbers, rewards tickets + gems).
- Right side: a vertical panel (Oof / Runes Rolled / Robux Spent / Time Played) leaderboards.
- Big world, hard to find the starter station: the beam helps but walking is slow (weak for us: keep things near spawn).

## 2. Idle Mafia Game (Stacks of Cash) - 3,485 playing, 17.3M visits, 87%
- NOT 3D: a full-screen 2D "browser game" UI (Mafia Wars 2009 remake). Proves an incremental can be pure UI and still hold 3.5K CCU.
- Top bar: avatar + level + XP bar (2/18), "2X WEEKEND BUFF 19:29:24" timer, CASH ON HAND $ + BANKED $, ENERGY 20/20, STAMINA 6/6, HEALTH 100/100 bars each with a "+" refill (regen resources gate the actions).
- Left sidebar tabs, most LOCKED with padlocks until a level: Safehouse, Jobs, Properties, Shop, Crew, Fight, Inventory, Collection, Bank, Operations, Contracts, Bosses, Family, TERRITORY (unlocks at level 9), Rankings. Events box at the bottom: GLOBAL BOSS (defeated), EVENT SHOP (5d left).
- JOBS: rows "Keep Watch on the Corner: 1 energy, $60, 2 XP, 2.5% item drop" + a MASTERY bar per job (0/25 to Bronze, then silver / gold medals). Next job rows show big grey "LEVEL 2/3/4" = what unlocks next is always visible.
- Level up toast "You reached Level 2, +5 skill points" (stat points to spend), +5 POINTS button in the top bar.
- PROPERTIES: build shops that pay $/HOUR in real time (Newsstand $600/hr for $500, Pizzeria $2,100/hr lvl 3, ... Import warehouse $295,000/hr lvl 20); "YOUR BLOCK" = 10 lots grid (FOR SALE, tap to build), "25% while offline", Gold bars/day unlock at level 125. Next lot costs 1 skill point.
- SAFEHOUSE: 18 safehouse levels (Back Alley Hideout -> Coldwater Flat +3%), "Animals" pets.
- DAILY PLAYTIME REWARDS row on the home screen: 5 / 15 / 30 / 60 / 90 / 120 / 180 MIN (cash, energy refill, street stash crate, strongbox, 3 gold bars, mystery crate, consumables crate) + "Played today 0:07".
- Tutorial = a mafia boss portrait in a bottom bar with one line + SKIP, an arrow pointing at the button (do job -> open Properties -> build -> open Jobs). Cash counts up live.
- PvP: attack players and steal cash; families (guilds) war over a shared persistent map, 24/7 world.

## 3. Immortality Incremental (Immortality Incremental) - 2,169 playing, 43.8M visits, 98% (highest rating)
- TITLE SCREEN: your own avatar sits on a bench meditating with a blue flame, big game logo, one "Play" button (cinematic first impression; you see yourself in the theme).
- Theme: cultivation (xianxia). Currency Qi (blue flame icon, "0.32/sec"). Tutorial bar at the top: elder portrait + one line + progress "(2/10)" + red SKIP.
  1. "Click anywhere to gain Qi (x/10)" (clicking first, AUTOCLICK button big at the bottom centre with a red dot).
  2. "Step on the realm button and try to make a BREAKTHROUGH" - a glowing white BEAM from you to a stone pad in front of the Realm board.
  3. "Buy Qi upgrades to help you reach Realm Foundation V [#10] (1/10)".
- REALM BOARD (in world): Current "Mortal [#0] 1 in 1" -> Next "Qi Gathering I [#1] 1 in 1.85", x1.27 Qi; a bar "3.27 Qi / 12 Qi" then "Breakthrough Ready!"; Breakthrough Luck x1.5, Breakthrough Speed x1. = the prestige rank-up is a LUCK ROLL with shown odds (RNG + incremental hybrid). Your realm name shows over your head ("Qi Gathering I [#1]"), so everyone sees your rank.
- Qi Upgrades board: cards (More Qi x1 -> x1.62, cost 28 Qi) with Buy (red) / Buy Max (x0).
- World leaderboards right at spawn: Top Robux, Top Sects (guilds: total realm), realm-based.
- Left menu: Shop, Marks, Profile, Options, Warp, Sects. MARKS = Global Marks (Unity, Confluence, Ambivalence) + Normal Marks (Insight, Essence...), each a set of locked slots (collection / equip system).
- ACTIVE BOOSTS panel top right: weather "Sandstorm" (timer 1:59, "Weather: +x% ...") + "Summer Season" = rotating world weather/season modifiers (live world feel).
- Description: Breakthrough (scale realms), Reset Layers (sacrifice for boosts), Open Marks, leaderboards; code RELEASE for potions; "Like & Favorite the game - activate insane boosts".

## 4. Tower Incremental (Lucky CStudios) - 1,153 playing, 6.7M visits, 89% (great CCU for its visits)
- Concept: you climb a TOWER. Top centre "Floor 0" + a cyan "Auto Run: Off" toggle; over your head "Rebirth 0 / Gold 1.82K".
- Gold ticks up passively even at spawn; coins spawn on the floor (yellow dots, "+20" popups) to walk over.
- World boards on the walls: Walk speed "16 > 17 Move much faster! 100 GOLD [Purchase] [1x]" (green purchase + yellow 1x multi-buy), "Unlock Room 400 GOLD [Purchase]" (red). A gold BEAM + bouncing yellow triangle marker leads to the next thing to do.
- TELEPORT menu: Tower 1-4, each split in SECTIONS of 20 floors; every floor is a themed room with its own mechanic: The Bottom, Lava Glyphs, The Mine, Upgrade Tree, Water Glyphs, The Smeltery, Poison Glyphs, The Merchant... (= each new floor = new mechanic, the "new layer = one new mechanic" rule made physical/vertical).
- GLYPHS: a collection of 10 element families (Lava, Water, Poison, Wind, Electric, Crimson, Earth, Frost, Cosmic, Sakura), each glyph shows "0/100 collected" and its buff (Gold 1x, Silver 1x): collecting duplicates levels the buff.
- Bottom bar (6 square icon buttons, pixel-art font): shop, backpack, glyphs, teleport [T], settings, stats. Bottom-left: EDIT + gold counter.
- Look: brick interior, pixel font, warm torch light: distinct identity.

## 5. Resource Incremental (PGS Squad) - 663 playing, 6.8M visits, 96%
- Same template family as Noob Incremental (flat grey tile plaza ringed by giant SurfaceGui boards, left icon menu Shop / Runes / Profile / Settings / Teleport, diamonds counter with a green "+").
- GLOBAL MILESTONES board (2nd game with it, so it's a genre convention): "Every LIKE boosts Cash in the game x3.18", "Every FAVORITE boosts Diamonds x1.79", "Every CONCURRENT USER boosts Stats x1.41" -> the boost grows continuously with the game's likes / favourites / live players: every player is motivated to like, favourite and bring friends.
- Plaza boards: Diamond Upgrades (More Cash 0/10, x1 -> x1.25, cost diamonds, Buy / Max), Highest Noob Level top list, Playtime top list, ROBUX SPENT top list (public whale board: #1 153.42K).
- RUNES index window: Event runes (Beach, Tropical, 1M, 3M, 5M = visit-milestone runes) + Noob / Beginner / Experienced / Skilled tiers, "Discover the rune" placeholders (a collection book with hidden entries).
- Bottom-left "0% Cash" boost chip (group/friends bonus).

## 6. [BLACKHOLE] Dropper Incremental (Shedwaa's Incrementals) - 599 playing, 11.6M visits
- Opens with a DAILY REWARDS window: "Log in daily for more rewards!" TODAY (+1 gold bar, Claim!) vs TOMORROW (+1, skip for 29 R$); after claiming "Next Reward In: 23h 59m". (Its X close button didn't respond to clicks; I had to toggle it from the left Daily Reward button = sloppy, avoid.)
- Tutorial card top centre: cash icon + "Get 5 Cash 0/5" bar. White chevron BEAM on the ground to the dropper.
- Core: a DROPPER machine with a glowing plate, "Level 0, 0/100, +1.05 cash, +1 star" floating over it (each dropper levels up with use).
- In-world selling everywhere: floating "PERMANENT x2 Cash 39 R$" product, "Auto Clicker 109 R$" sign beside the machine, "FREE Auto Clicker: join the group" sign (group join = free auto clicker), Merchant stall "Buy boosts" with a green ring.
- Left menu: Settings, Shop, Stats, Rewards, Daily Reward (calendar "31"); right: gold bars counter; bottom right "+0% Cash boost (+)".
- Low-poly blue tiles, wooden fence; plain look.

## 7. [AWAKENING] Grass Cutting Incremental (LethalDolphin) - 145 playing now, 30.1M visits (the old genre king; small now)
- Loading screen: big green logo + "Loading" + a number counting; badge "Welcome" awarded on join.
- A "Version 0.9" CHANGELOG pops on join (Relevant changes, v0.9 Awakening: new areas, features, music, Planet Run minigame, consumable boosts, rare flowers currency, World 2...). Big red Close.
- HUD: top grass bar "0", "5/5" (grass grown on the field / cap), big world-space text "Level: 1 (1/s)" and "Grass: 0" on the island, a "1" block, "Locked - Reach level 2" board. Bottom: Help (yellow), Stats & Settings (red), Map (cyan); bottom strip "Unlock Perks at level 2 (0%)" = a level XP bar with the next unlock named.
- MAP: a top-down view of the island with icons (Field ...) and the area name "The Island" in big letters; tap an icon to go there (didn't work for me with the mouse).
- Very plain blocky look (default studs), small island in an endless sea: easy to walk off into water. Old UI style; the genre has since moved on to prettier games.

## 8. Circle Grinding Incremental (Jeremy Studio's) - 153 playing, 25.8M visits
- You stand on a pink CIRCLE that follows you; it grinds the cyan crystals on the ground into money. Top: "Upgrade your Circle 0/50" + "Steps Completed: 0 / 723 (0%)" = the WHOLE game is counted as 723 steps and you always see your % complete (a completion meter).
- Giant white ARROWS painted on the floor lead you (huge, impossible to miss), turning toward the next step.
- Left: money + diamonds counters, Index, Settings, Shop (red). Under them a rotating tip line: "No friends here: for each FRIEND in the server you get +100% more money!" / "Join Jeremy Studio's, like and favorite the game for x2 Money!".
- Big wall boards: the upgrade tree with "???" hidden nodes (Unlock..., Boosts money, Prestiges, Increases circle...), "Locked: Reach Tier 3 to unlock" door, two leaderboards (Most Money, Most Time Played) with "Your Placement".
- Server message in big yellow text: "You're able to get a free gamepass inside the shop using TICKETS!" (earnable premium tickets that buy a pass = free-to-play path to a pass).
- A wooden "Pro Tip: ALWAYS buy upgrades even if you don't know what they do..." sign = teaching through the world.

## 9. Grass Incremental Simulator (Unequal Games) - 126 playing, 41.6M visits
- Clean modern look: grey stone plaza, low-poly trees, white spawn pad with a black star mark, pastel UI.
- HUD: top "Level 1" bar (XP), left counters (gems, grass) + settings + shop basket (red "!" badge), bottom-left "Friend Boost: +0%", bottom centre "AUTO TRIM 39 R$" button, a round "2X GRASS 49 R$" product bubble floating in the world.
- Hint line under the level bar: "Go closer to the grass and trim it". Big bouncing yellow ARROWS over each grass tuft.
- You hold a spinning TRIMMER blade; click near a tuft to cut it ("+1 grass"); other players' blades are HUGE = your upgrades are visible on your character (social proof / envy).
- Grass Upgrades board: Increase Growth Rate (3s -> 2.6s, cost 5 grass), Increase Grass Value (1 -> 2), Increase Grass Amount (2 -> 4) with Buy 1 / Max; "Reach Level 5 to unlock" padlock walls (next areas locked by LEVEL, not currency).
- A sign: "Tip: collect as much grass as possible before rebirthing!"; floating "Grass Per Second: 0" text over the field.
- A popup offer appeared ~1 min in: "2x Walkspeed, gamepass for you! [29] [Nevermind]" (small, dismissable, bottom-right corner: an early but soft offer).

## 10. [🙏] Faith Incremental (Blinky Studios Official) - 173 playing, 11.7M visits
- Spawn faces a little Halloween-decorated church; one quest line at top centre: "Step inside the church and earn Faith / Enter the church to pray" -> then "Purchase an upgrade / Buy any highlighted upgrade".
- ZONE income: you earn Faith (cross icon) just by standing inside the church; the counter ticks.
- Upgrade boards line the church walls like stained-glass panels ("Upgrades 1/2", "Increase Chance of Super Pray" with Buy / Max); the one to buy is highlighted.
- Outside: GAMEPASSES board (2x Walk Speed, 2x XP, 2x Faith, 2x Rebirth) and a "group / likes" boost board (+0% / +0%).
- Event: candy corn collectibles around the map "0/15, Respawn 14:15" (a timed scavenger hunt) + a "2x Event" pill top right + Players list button + version "V1.17.0".
- Bottom: "Level 0, 0/50" XP bar; left: faith + gems, shop basket, halo (rebirth?) icon; bottom-left group/premium boost chips.
