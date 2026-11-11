---
date: 2026-11-01
tags: [celestial, design, revamp]
status: plan, to build next
---
# Celestial Incremental - Revamp 2: no more collecting (1 Nov night)

Owner: "we need to not let anything behind. also i played the game and it was pretty boring. its tiring to repetitively collect and i dont think people like collecting in the new incrementals".

## Evidence (our own played research, 1 Nov: [[2026-11-01 Celestial Incremental - 10 incrementals played]])
- The BIG games are automation + choices + luck: Noob Incremental 4,389 playing (buy noobs that earn for you, hidden upgrade tree, rune rolls), Idle Mafia 3,485 (no walking at all), Immortality 2,169 (breakthrough = a roll with shown odds), Tower 1,153 (each floor a new mechanic).
- The COLLECTING games are the small ones now: Grass Cutting Incremental 145, Circle Grinding 153, Grass Incremental Simulator 126 (despite 25-42M visits = the old style that players left).
- So the owner is right: walking around picking things up is the core of the shrinking games. Celestial's core is exactly that today.

## New core: build a star system that earns for you
- **Your system**: a row of slots around your own star. Buy STAR BODIES that make Stardust every second by themselves: Asteroid -> Moon -> Planet -> Gas Giant -> Star -> Binary Star -> Pulsar -> Quasar (8 tiers, each ~10x the last, each its own 3D object orbiting you). Each body levels up; every 25 levels x2 (milestone pop).
- **No collecting needed**: income is automatic from second 1. Motes stay only as a bonus: a COMET streaks past now and then; click it for a burst (a choice, not a chore). Lost Stars hunt and meteor shower stay as events.
- **Active play = decisions**: what to buy next, which tree node, when to reset, when to roll.

## Layers (each new layer = one new mechanic; Tower's rule)
1. **Supernova** (reset bodies) -> Star Shards -> the **CONSTELLATION TREE**: a big sky map of nodes, hidden "?" until a neighbour is bought (Noob's tree), each node drawn as a star line.
2. **STAR FORGE** (opens Supernova 3): roll Star Cores with shown odds (Common .. Celestial), equip 3; duplicates level them (Immortality breakthrough / Noob runes / Tower glyphs). Odds never sold.
3. **Black Hole** (second reset, Supernova 10+): resets shards too -> Dark Matter -> automation (auto-buy bodies, auto-Supernova) and a new body line.
4. **The Ring Nebula** (second island) opens with Black Hole 1: its own mechanic (fusion: merge 3 bodies into the next tier).
5. **Big Bang** (third reset, later update): Universe points, a new galaxy.

## Every gap from the comparison closed
| Gap | Fix |
|---|---|
| Depth | 3 reset layers + Star Forge + Ring Nebula + tree: days of play |
| No luck roll | Star Forge with shown odds |
| No community boost | GLOBAL MILESTONES board: likes / favourites / players online boost everyone (real numbers; game servers can't call roblox.com directly, so through a public proxy such as RoProxy, refreshed every few minutes; if it fails, the board shows the last numbers) |
| Nothing to buy | 4 passes (x2 Stardust, Auto Forge, +1 Core slot, VIP) + product bubbles next to your system; owner makes them on the Creator Hub |
| Untested multiplayer | 2-player test of Star Surge, shared sky, friend bonus |

## Keep
Star Surge (server bar now fills from everyone's income, not collected motes), shared sky, friend / group / server bonus, ranks + aura, Cosmos Charted %, weather, Lost Stars, Supernova cinematic, daily / gifts / quests, kit UI, the island.

## UPDATE (owner screenshot, 1 Nov night): "these are the top incrementals rn"
Noob Incremental 96%, Everything Upgrade Tree 88%, Energy Incremental 84%, Ore Grinding Incremental 87%, UT Incremental: The Maelstrom ("Upgrade Tree Incremental") 81%, Matrix Incremental 95%, Immortality Incremental 98%, Resource Incremental 96%, Grass Incremental Simulator 96%, Tower Incremental 89%, Untitled Upgrade Tree 87%.
- 3 of 11 are literally UPGRADE TREE games (Everything Upgrade Tree, UT Maelstrom, Untitled Upgrade Tree), and Noob's tree is its centre: the tree is the genre's main screen now, not a side feature.
- Untitled Upgrade Tree's thumbnail = a Roblox kid flying past the Earth in space: a space-looking competitor exists, so our thumbnail must look different (our own star system, not a planet + avatar).
- Names: "[one word] Incremental" (Noob, Energy, Matrix, Tower, Resource, Immortality) or "... Upgrade Tree". Short and plain.
- Ore Grinding's thumbnail = a currency chain (rock -> star -> gem -> coin -> lightning -> fire -> halo -> black hole -> ???): shows the whole progression at a glance.
### Changes to the plan
- The CONSTELLATION TREE becomes the main screen from minute 1 (not after Supernova): a big pannable sky map, hidden "?" nodes, every node drawn as a star line; Stardust buys the first ring, Shards / Dark Matter the outer rings. The star system around you is what the tree builds.
- Name: follow "[word] Incremental": "Galaxy Incremental" (first choice, check it's free), or "Constellation Incremental" / "Star Tree Incremental".
- Thumbnail: the currency chain idea in space (asteroid -> moon -> planet -> star -> pulsar -> black hole -> ???) on our kit style, no avatar-in-space look.

## NAME DECIDED (owner, 1 Nov night): SUPERNOVA INCREMENTAL
- Owner: "lets do Supernova Incremental" (over Galaxy Incremental). Fits the "[word] Incremental" pattern; Supernova is already the game's main reset, so the name = the big moment.
- To do: rename the experience on the Creator Hub (owner) to "Supernova Incremental" (title case like every top game: Noob Incremental, Tower Incremental; all-caps titles look spammy). Only the in-game logo / thumbnail art is drawn in capitals. Vault folder name stays "Celestial Incremental" for links.
- Thumbnail idea now: the chain asteroid -> moon -> planet -> star -> SUPERNOVA burst (the centre, biggest) -> black hole -> ???.

## CUTSCENES (owner, 1 Nov night: "ok do that in supernova incremental")
From [[2026-11-01 Research - Do cutscenes help, what makes a good one]]. Build with Revamp 2:
- No intro cutscene: join -> your asteroid is already earning (first 90 s = play).
- SUPERNOVA: first ever = ~5 s full cinematic (star swells, bursts, shockwave, new rank lands over your head), ends on a tease of the next goal ("Supernova 3: the STAR FORGE awakens..."); after that a 2 s version, tap to skip (rewards given either way); none with auto-Supernova.
- New layer unlocks (Star Forge, Black Hole, Ring Nebula): 3-5 s camera move onto the new thing, ending on what it does.
- Star Forge rolls: commons instant; Legendary+ 2-4 s reveal, bigger the rarer; first-time Mythic+ can't be skipped for 2 s.
- Others see it: a burst in the sky over your island + server message when anyone goes Supernova / rolls Mythic+.
- Rules: player's own avatar / system is the star, one idea per shot, sound timed, music ducks, no text walls, no QTEs, camera + controls + HUD always restored (skip, reset, error).
