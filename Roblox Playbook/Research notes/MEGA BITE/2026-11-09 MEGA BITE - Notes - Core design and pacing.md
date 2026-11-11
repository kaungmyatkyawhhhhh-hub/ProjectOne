# MEGA BITE: Core Design, Pacing and Progression of Eat-to-Grow Games (researched 9 Nov 2026)

Scope: how eat-to-grow games handle growth, pacing, abilities, rebirth, carry-and-bank risk and phone controls, with numbers where sources gave them. Owner's earlier rules (first reward in about 10 s, an action every ~3 s in the first 30 s, a big goal at ~5 min, power that is used AND seen, one big number, collection books, run 2 about 2x faster) are treated as given and not re-researched here.

Overall caveat: published numbers for these games are rare. Wikis and guides describe the systems but almost never give EXP curves, drain rates or unlock times. The best hard numbers are agar.io's reverse-engineered formulas and slither.io's boost cost. Everything marked "Inference" is my design suggestion built on the cited findings, not a sourced fact.

## 1. How eat-to-grow games structure growth (EXP curves, size scaling, eat ratio, time to evolve, speed vs size)

### Takeaway
The genre runs on a few simple rules: you can eat things about 25% smaller than you, getting bigger makes you slower and zooms the camera out, size tiers decide what you can eat and where you can go, and the next tier unlocks when you max out the current one. Costs rise faster than rewards, so the early game is quick and the late game is slow.

### Cited Findings
- agar.io (reverse-engineered): cell speed = 86.05 / size^0.45. Speed falls as size grows, but slowly (a sub-linear power curve). — [agario-bot game_mechanics.txt](https://windfis.ch/git/agario-bot/tree/reversing_game_mechanics/game_mechanics.txt)
- agar.io: a cell can eat another if it is at least about 1.25x its size or mass. The source marks the exact basis "(??)". The prey is eaten when its centre is inside the bigger cell's circle. — [agario-bot game_mechanics.txt](https://windfis.ch/git/agario-bot/tree/reversing_game_mechanics/game_mechanics.txt)
- agar.io: camera zoom = 369.399 * (total own size)^0.431776, so the view widens as you grow. — [agario-bot game_mechanics.txt](https://windfis.ch/git/agario-bot/tree/reversing_game_mechanics/game_mechanics.txt)
- agar.io: heavier cells move more slowly, and cells slowly lose mass over time, which discourages idling. When all your cells are eaten you restart small. — [Wikipedia: Agar.io](https://en.wikipedia.org/wiki/Agar.io)
- Hungry Shark Evolution: most sharks unlock by reaching level 10 at 100% XP on the previous shark, or by paying gems. Coin prices climb steeply: Reef free, Mako 1,000, Hammerhead 5,000, Tiger 15,000, Great White 35,000, Megalodon 50,000, Big Daddy 150,000, and up to 500,000+ for late sharks. — [Hungry Shark Wiki: Shark](https://hungry-shark.fandom.com/wiki/Shark)
- Hungry Shark World: 17 sharks at launch in 7 size tiers (XS, S, M, L, XL, XXL, then "!!"). You start as a Blacktip Reef Shark, and XP from play unlocks the next tier. — [PocketGamer.biz IAP Inspector](https://www.pocketgamer.biz/iap-inspector-hungry-shark-world/); tier list from [Hungry Shark Wiki](https://hungry-shark.fandom.com/wiki/Shark)
- Hungry Shark World: costs for coins and gems rise faster than rewards, so the early game is smooth and later sharks push players towards buying or heavy grinding. — [PocketGamer.biz](https://www.pocketgamer.biz/iap-inspector-hungry-shark-world/)
- Hungry Shark World: the size class decides which prey you can eat and which map areas open. XS/S sharks eat small fish, swimmers and crabs in shallow water. M/L sharks reach new areas and bigger prey. XXL sharks can eat almost anything, including bosses and submarines. — [BlueStacks HSW beginner guide](https://www.bluestacks.com/blog/game-guides/hungry-shark-world/hsw-beginner-guide-en.html)
- Hungry Shark: health drains over time and only eating restores it, so survival time drives score. — [BlueStacks](https://www.bluestacks.com/blog/game-guides/hungry-shark-world/hsw-beginner-guide-en.html)
- Katamari Damacy: one stage takes the ball from 1 m to over 500 m. The growth curve was tuned by trial and error while actually playing, and object placement was planned together with that curve. Ordinary objects were scaled up with a "giant" prefix to fill the high-size range. — [Game Developer: Katamari postmortem](https://gamedeveloper.com/design/postmortem-the-singular-design-of-namco-s-katamari-damacy-2004-)
- Katamari: the designer said growth feels less impressive once you are big, because players forget how small they started, and he wished for a stronger "I've gotten so big" moment during play. Rolling sounds, controller vibration and combo celebrations (fireworks, confetti) reinforced each pickup. — [Game Developer: Katamari postmortem](https://gamedeveloper.com/design/postmortem-the-singular-design-of-namco-s-katamari-damacy-2004-)
- Roblox "How Big Will You Grow?": the loop is grow clicks, then power-ups, then quests, then zones that unlock at size milestones, then leaderboards. Giant-only "Hungry Zones" have unique food. The guide gives no figures. — [Odyssey guide](https://odysseyk.blogspot.com/2025/07/how-big-will-you-grow-roblox-full-guide.html)
- Roblox Fish Evolution (June 2025): eat to level up, and levels unlock new fish. Rebirth unlocks talents, plus pets and equipment. About 5.1M visits, a 94.3% like ratio and an all-time peak of 156 CCU. Its growth boosts are +5% for friends and +10% for group members, plus 30% more coins for Premium. — [RoWatcher: Fish Evolution](https://rowatcher.com/games/7999885745/fish-evolution)

### Inferences
- Eat rule for MEGA BITE: let a fish eat anything at most about 0.8x its SIZE (agar.io's 1.25x rule, inverted). Draw a colour outline on every fish: green = edible, white = same size, red = danger. This is the single most important readability rule for kids.
- Speed: use an agar-style soft curve, roughly speed proportional to SIZE^-0.3 to -0.45, but give each of the 7 sharks a base-speed reset so an evolution never feels slower than the stage before it.
- Camera: zoom out with SIZE on a power curve (agar uses an exponent of about 0.43). Add one dramatic "I got big" moment at each evolution, such as a slow-mo pull-back plus the old body's outline shown next to the new one, which answers Katamari's complaint.
- Prices: copy HSE's roughly 3 to 5x step between tiers, with the curve kept gentle for the first 3 sharks (Minnow, Piranha, Barracuda) and steep from Hammerhead onwards.
- Map: unlock depth or areas by shark tier, as HSW does, so the prey you can eat and the places you can go grow together.

### Gaps
- No source gave real EXP-per-level curves, HSE/HSW health drain per second, or the median time to unlock each shark. These are not published. The wiki says HSW stat values live in an external spreadsheet that I did not retrieve.
- Feed and Grow: Fish mechanics (biting bigger fish down, bleed) could not be found from a reliable source in this pass.
- DEVOUR, "Eat the World" and "+1 size every second" Roblox games: I found no mechanics or numbers, only store pages.

## 2. The "big player always wins" snowball problem

### Takeaway
Games limit the snowball with built-in costs to being big: slower movement, mass decay, boosts that burn size, hazards that punish big bodies, and hiding spots only small players fit into. Small players get burst-escape tools and are hard to catch.

### Cited Findings
- agar.io: big cells are slower (speed = 86.05 / size^0.45) and lose mass over time. — [agario-bot](https://windfis.ch/git/agario-bot/tree/reversing_game_mechanics/game_mechanics.txt); [Wikipedia](https://en.wikipedia.org/wiki/Agar.io)
- agar.io viruses: a big cell that touches a green spiky virus splits into many small pieces that are easy to eat. Small cells can hide under viruses. Players feed mass into viruses to shoot them at big cells. — [Wikipedia: Agar.io](https://en.wikipedia.org/wiki/Agar.io)
- agar.io splitting (up to 16 cells) works both as a ranged attack and as an escape tool. — [Wikipedia: Agar.io](https://en.wikipedia.org/wiki/Agar.io)
- slither.io: boosting costs a fixed 15 length units per second, which the wiki says hurts small snakes more. Boosting also makes steering less precise. — [Slither.io wiki: How to boost](https://slitherio-archive.fandom.com/wiki/How_to_boost)
- Hungry Shark: mines, jellyfish, lionfish and bigger predators damage even large sharks, and players are told to avoid mines until they are strong enough. — [BlueStacks HSW guide](https://www.bluestacks.com/blog/game-guides/hungry-shark-world/hsw-beginner-guide-en.html)
- Katamari designers meant for a 300 m ball to be able to crumble back to about 2 m (only partly built), and noted that reversible shrinking needs objects to keep their state. — [Game Developer: Katamari postmortem](https://gamedeveloper.com/design/postmortem-the-singular-design-of-namco-s-katamari-damacy-2004-)
- Mobile extraction advice: keep the power gap between weak and strong players modest, use matchmaking, and use seasonal resets to level the field. — [Naavik: Extraction shooters](https://naavik.co/f2p-mobile/extraction-shooters/)

### Inferences
- MEGA BITE anti-snowball kit:
  - Big sharks turn more slowly (a wider turn radius), not just swim more slowly. Small fish can out-turn them, which is readable and fun for kids.
  - Reef caves and kelp tunnels that only fish below a certain SIZE can enter, like agar's virus hiding.
  - Minnow DART: a short dash with a brief moment of invulnerability, as the escape tool.
  - Sea bombs from Zev's idea: punish big bodies (larger hitbox, more damage) and are triggered by rams, like agar's virus.
  - Megalodons in the PvP zone should be uncommon. Players could be kicked back to the Safe Reef after X minutes without eating, or face a slow EXP decay instead of losing SIZE, so idle campers fade.
  - In PvP, eating a player should give a fraction of the victim's carried EXP, not all of it, which caps the snowball.
- Do not shrink kids' SIZE permanently. Losing carried EXP (the extraction mechanic) is already the loss. Shrinking the shark itself as well would double the punishment.

### Gaps
- No published numbers on agar.io's mass-decay rate (the source does not list it) or slither.io's boost speed multiplier.

## 3. Evolution timings and pacing the first 10 minutes

### Takeaway
No reliable source publishes "time to evolution N". The structural pattern is that early tiers are cheap and fast, and costs rise faster than rewards. HSE's "max level 10 on the previous shark" rule means every evolution is earned by playing the current one.

### Cited Findings
- HSE: unlock the next shark by reaching level 10 at 100% XP on the previous one. — [Hungry Shark Wiki](https://hungry-shark.fandom.com/wiki/Shark)
- HSW: the early game is smooth, and later sharks need far more because costs outpace rewards. The endgame is thin: once the top tier is unlocked, daily missions are the main draw. — [PocketGamer.biz](https://www.pocketgamer.biz/iap-inspector-hungry-shark-world/)
- Katamari: most stages have time limits. The designer wanted to remove them but couldn't keep the game fun without one. — [Game Developer](https://gamedeveloper.com/design/postmortem-the-singular-design-of-namco-s-katamari-damacy-2004-)
- Mobile extraction advice: a polished first-time experience and AI opponents that are believable but not challenging. — [Naavik](https://naavik.co/f2p-mobile/extraction-shooters/)

### Inferences (proposed MEGA BITE timeline, built from the owner's rules plus the cited curve shape)
| Milestone | Target time (new player, no rebirth) |
|---|---|
| First fish eaten | under 5 s (spawn next to 3 to 5 tiny fish) |
| First "+SIZE" pop and level-up | about 10 s |
| Minnow → Piranha | about 60 to 90 s (the first evolution must happen in the first session's first 2 min) |
| Piranha → Barracuda | about 4 to 5 min (this is the "first big goal" at about 5 min) |
| Barracuda → Reef Shark | about 12 to 15 min (first danger-zone trip and first bank) |
| Reef Shark → Hammerhead | about 35 to 45 min (end of session 1 or into session 2) |
| Hammerhead → Great White | about 2 to 3 h total |
| Great White → Megalodon | about 6 to 10 h total, the first Fossilize goal |
- This is about a 3x time step per tier, which matches HSE's 3 to 5x coin steps. With the owner's "run 2 about 2x faster" rule, the second Megalodon would come at about 3 to 5 h.
- First 10 minutes: by about 60 s the Piranha has used FRENZY. By about 3 min the first shiny fish and a Fish Index pop. By about 5 min the Barracuda's TORPEDO is unlocked. At about 6 to 8 min the danger zone is shown with a small, safe first carry (a tutorial bank worth 2 to 3x the normal EXP). By about 10 min the first squid boss teaser appears.
- Within a run, use HSE's levels-within-a-shark idea: about 5 to 10 visible levels per shark so the big number ticks up often between evolutions.

### Gaps
- No data on real session lengths, D1 retention or evolution times for HSE, HSW or Roblox fish games.

## 4. What makes abilities desirable and readable

### Takeaway
The best-documented abilities change how you eat (Gold Rush lets you eat anything and makes you invincible), are tied to one specific shark (Hungry Shark Primal's one ability per shark), and can be seen on screen (shimmer, effects). Desirable abilities give big sharks a feeling small fish can watch and want.

### Cited Findings
- HSW Gold Rush: eating enough golden prey fills a meter. Then, for a limited time, the shark is invincible, can eat almost anything, and earns multiplied coins. — [BlueStacks](https://www.bluestacks.com/blog/game-guides/hungry-shark-world/hsw-beginner-guide-en.html); [PocketGamer.biz](https://www.pocketgamer.biz/iap-inspector-hungry-shark-world/)
- Hungry Shark Primal gives each shark one signature ability: Creto stuns enemies it hits while boosting, Lio gets +50% bite on predators from behind, Aquilo gets a second jump while boosting, Dunk damages creatures that touch it, Rhizodus resists damage, and Thal gets a bigger bite while boosting. — [Hungry Shark Wiki](https://hungry-shark.fandom.com/wiki/Shark)
- Hungry Shark upgrades: Bite, Speed and Boost. Accessories (jetpacks, lasers, pets) add small effects, and pets eat small prey for you. — [BlueStacks](https://www.bluestacks.com/blog/game-guides/hungry-shark-world/hsw-beginner-guide-en.html); [PocketGamer.biz](https://www.pocketgamer.biz/iap-inspector-hungry-shark-world/)
- slither.io: a boosting snake gets a visible shimmer, so other players can read the ability. — [Slither wiki](https://slitherio-archive.fandom.com/wiki/How_to_boost)
- Katamari: sound, vibration and combo effects made each pickup feel rewarding. — [Game Developer](https://gamedeveloper.com/design/postmortem-the-singular-design-of-namco-s-katamari-damacy-2004-)

### Inferences
- Primal's pattern (one ability per shark, often tied to boost) matches MEGA BITE's 7 signature abilities. Each one should change how you eat or move, not just add a stat.
- Give FRENZY or TIDAL ROAR a Gold Rush-style meter (eat X fish → 8 to 10 s of "eat anything 1 tier up"). It is the most proven "feel powerful" moment in the genre.
- Readability for watchers: each ability needs one unique colour plus a sound, visible from about 50 studs away, so small fish see a Megalodon's TIDAL ROAR and want it.

### Gaps
- No sources found on Depth's or SPTS's ability design in this pass.

## 5. Rebirth and prestige in eat-and-grow games

### Takeaway
On Roblox, rebirth means "reset size for a permanent multiplier and unlocks". The meta advice is to rebirth when growth stalls, and some games add rebirth-only talents.

### Cited Findings
- How Big Will You Grow?: rebirth resets progress for a permanent growth multiplier, auto-clickers come from rebirths, and the meta is to rush early rebirths and "prioritize rebirths once you hit a wall." — [Odyssey guide](https://odysseyk.blogspot.com/2025/07/how-big-will-you-grow-roblox-full-guide.html)
- Fish Evolution (Roblox): rebirthing unlocks extra talents. — [RoWatcher](https://rowatcher.com/games/7999885745/fish-evolution)
- HSW's endgame is thin after the top tier (daily missions only), which shows the risk of having no prestige layer. — [PocketGamer.biz](https://www.pocketgamer.biz/iap-inspector-hungry-shark-world/)

### Inferences
- Fossilize should give a permanent multiplier (the owner's "run 2 about 2x faster" rule) plus a visible new thing: prehistoric skins and fossil names for the 7 sharks. Prestige should be seen, not only counted.
- Keep the Fish Index, shinies and mutations through Fossilize so collections never reset.

### Gaps
- No numbers found on rebirth multipliers in fish or eat games.

## 6. Extraction-style "carry it home" risk, tuned for kids

### Takeaway
Modern extraction design softens loss in three ways: a small protected stash, progress that counts even when you fail, and free retries or catch-up help for players on losing streaks. Longer time-to-kill and a real chance to escape keep deaths feeling fair.

### Cited Findings
- Extraction basics: death loses everything carried except insured items and a small safe section of inventory. — [Naavik](https://naavik.co/f2p-mobile/extraction-shooters/)
- The Cycle: Frontier gives metagoals that reward players even when they fail to extract. Free randomised gear runs (Tarkov's "Scav runs") soften loss. — [Naavik](https://naavik.co/f2p-mobile/extraction-shooters/)
- Badlanders warning: when loot auto-collects and means nothing, the tension disappears. — [Naavik](https://naavik.co/f2p-mobile/extraction-shooters/)
- Mobile extraction: short rounds, small maps, low player counts and enemy indicators keep it "snackable" and readable. — [Naavik](https://naavik.co/f2p-mobile/extraction-shooters/)
- ARC Raiders (Embark's Virgil Watkins):
  - Quests and meta-progression advance without extracting, as a "safety net".
  - A safe pocket keeps quest items through death.
  - A free loadout is always available.
  - A longer time-to-kill means fights at full health are back-and-forth, with a good chance to disengage.
  - "Scrappy" gives extra materials to players on a losing streak, because tests showed struggling players were falling behind. — [Kotaku interview](https://kotaku.com/arc-raiders-embark-extraction-virgil-watkins-interview-2000639879)

### Inferences (MEGA BITE carry-and-bank tuning)
- Safe pocket: always keep about 25% of carried EXP on death, and protect 100% during the tutorial and for players under Reef Shark tier. Losing everything is what makes kids rage-quit.
- Progress that counts on death: Fish Index entries, shiny catches and quest kills count the moment they happen. Only bonus EXP is at risk.
- Losing-streak helper ("Scrappy"): after 2 deaths in a row while carrying EXP, the next danger trip gives a +50% carry bonus, or spawns a friendly remora that auto-banks a little.
- Readable danger: show a "CARRYING: 1,240 EXP" counter that pulses when a predator is near, and a direction arrow to the Safe Reef. Put several bank points (bubble vents) about 20 to 40 s of swimming apart, so a trip is a 1 to 3 minute bet, not 15 minutes.
- Fair deaths: big sharks need 2 or more bites to kill a player (a longer time-to-kill) so DART or hiding can save you.
- Carry multiplier: EXP in danger zones should be about 3 to 5x the Safe Reef rate (Zev's "lots of EXP") so the risk is worth it.

### Gaps
- Exact Tarkov secure container sizes and Albion, Dark and Darker or ArcheAge trade-pack numbers were not fetched in this pass. Search pointed to [AFK Gaming's secure container guide](https://afkgaming.com/esports/guide/everything-about-secure-containers-in-escape-from-tarkov), which I did not read.
- No studies specific to children on how they tolerate loss in games were found.

## 7. Swimming controls and camera on phones

### Takeaway
Shipped mobile eat games use simple controls: touch or tilt steering with a boost (Hungry Shark), and double-tap to boost (slither.io). Reviewers' most common complaint about agar.io was "floaty" mobile controls. On Roblox, devs build either a fish StarterCharacter or a custom client-owned controller.

### Cited Findings
- Hungry Shark World supports tilt or touch controls, and boost is an upgradable stat used to chase or escape. — [BlueStacks](https://www.bluestacks.com/blog/game-guides/hungry-shark-world/hsw-beginner-guide-en.html)
- slither.io mobile: double-tap the screen to boost, and the snake shimmers while boosting. — [Slither wiki](https://slitherio-archive.fandom.com/wiki/How_to_boost)
- agar.io criticism: repetitiveness and mobile controls, with one reviewer calling them "floaty". — [Wikipedia](https://en.wikipedia.org/wiki/Agar.io)
- Touch controls lack precision, and mobile players often mute audio, so visual danger indicators matter. — [Naavik](https://naavik.co/f2p-mobile/extraction-shooters/)
- Roblox fish controller options:
  - Option A: a fish StarterCharacter with default scripts plus swim and idle animations (fast to set up, less flexible).
  - Option B: a custom welded model with client network ownership, a LocalScript moving the primary part with a body mover, and camera.CameraSubject set to the fish (flexible).
  - Also stop the fish from floating to the surface. — [DevForum: fish character controller](https://devforum.roblox.com/t/tips-for-going-about-making-a-fish-character-controller/1833846)

### Inferences
- For kids on phones: use Roblox's default thumbstick for direction, plus auto-forward swim at cruise speed so kids never stall. Put a big BOOST button bottom-right and ability buttons above it, with the ability button at least 1.5x a normal button.
- Use a 3rd-person chase camera that follows the fish's heading with a slight lag. Zoom out with SIZE, and use automatic up and down pitch so kids never have to manage depth by hand.
- Because many kids play muted, every danger needs a visual cue: a red edge flash and an arrow towards the predator.

### Gaps
- No sources on Roblox swim-game camera or auto-swim retention data. I found no DevForum thread with mobile-specific fish control benchmarks.
