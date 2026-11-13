# 2026-11-13 MEGA BITE - Giants in the game, chest opening, kit dressing, 4K textures

Owner 09:12: "do the ones that u havent done. also make treasure chest opening animation and vfx and sfx very great".
Owner 09:57: "also the ingame textures should be high quality, rn i see blurry textures so please fix that".
Nothing is published. All of this is in Studio only. Tested in Studio Play (one player, PC). Not tested: phones, 2+ players.
Related: [[2026-11-13 MEGA BITE - Bigger sea, landmarks and giant creatures (plan)]], [[2026-11-13 MEGA BITE - Giants (whale, turtle, eel, Kraken) models and plan]], [[2026-11-13 MEGA BITE - Long work order status (13 Nov)]]

## 1. Treasure chest opening (done, tested)
- `ReplicatedStorage.MB_VFX.ChestFx` (new) + `MB_WorldMap` (wired in). Backups: `MB_WorldMap_preChestFx_13Nov`, `MB_Sounds_preChest_13Nov`.
- Full chest: gold light beam, floating stars, glow, a soft hum (3D), the lid "peeks" every few seconds when you are near.
- Opening (2.4 s): the chest rattles for 0.64 s, the lid springs open with a bounce, gold flash + light column + shock rings,
  14 gold stars fly to your shark with a rising note each, 20 coins pop out, "TREASURE! +N EXP". Other players see the burst too.
- Sounds (our own synth, `MEGA BITE\Audio\chest\`): ChestOpen 93866950046882 (Approved, in MB_Sounds), ChestHum 79187386997160.
- Checked on the Whale Graveyard chest: +783 EXP (x4 test boosts). The flash was toned down after the first test (it was a white screen).

## 2. Open Sea kit in the map (done)
- 8 kit props (model 128858224238288) as templates in `MegaBite.Props.OpenSeaKit`; `ServerStorage.MB_WorldDress` uses them
  (backup `MB_WorldDress_preKit_13Nov`). Rule from the quality-nerd sim: every patch mixes kinds.
- New patch kinds: ruins (E), mushroom grove (W), sponge garden (N, E, S), clam bed (S). Kit props also in every old patch,
  in the singles and around the landmarks. Fewer starfish, smaller kelp forests, fewer spires round the W landmarks.
- Big corals no longer glow as flat Neon blobs (only thin corals glow; mushrooms glow 3 in 10).
- Now 3,362 props of 19 kinds. Quality-nerd count "same prop again" per 3 min: r300-720 was 16.6-19.6, now 12.4 (before the
  spire change; the rest comes from the spire rings round the reef and the W landmarks); r720-1150 now 7.2.
- Movement audit after it: 0 fish in props in the open sea (1 Damsel in a reef coral), 0 predators in props, 2 slow puffers.
- `C.World.Arenas`: places the dressing keeps clear (Kraken pit r 150, eel burrow r 30).

## 3. The four giants in the game (done, tested)
Models: `MegaBite.Creatures` Whale (220 studs), Turtle (90), Eel (160), Kraken (240). Numbers: `GameConfig.Giants`.
Scripts: `ServerScriptService.MB_GiantsServer` (rules), `StarterPlayerScripts.MB_Giants` (what you see), `MegaBite.GiantPath`
(shared maths), remote `GiantBite`, folder `MegaBite.GiantState` (attributes). Small edits: `MB_Swim` (slipstream speed),
`MB_FishServer` (`_G.MB_FishEscort`), `MB_PredatorServer` (`NoPredUntil`). Backups: `*_preGiants_13Nov`.
| Giant | Where | What it does |
|---|---|---|
| Giant Sea Turtle | circles the Kelp Lighthouse (N), 9 studs/s, low over the seabed | friendly. Bubble trail behind it = slipstream: speed x1.5 and (1 + evolution) EXP a second. Mackerel schools appear near it. Two little fish live on its shell. |
| Blue Whale | one loop round the Open Sea at r 620, 4 minutes, high in the water | friendly. Sardine schools appear along its way when a player is near. It sings (WhaleSong) when you are within 300 studs. |
| Colossal Eel | a real burrow in the seabed beside the Ocean King's chest (738, 48) | sees a shark within 120 studs: gold outline + growl (1.0 s), red wind-up (1.2 s), lunge up to 92 studs. DART dodges. Hurts at most 45% of your HP; at 0 HP you go back to the reef and lose nothing. Leaves alone: Great White and Megalodon, sharks in a Gold Rush, sharks that just spawned. 8 s rest. |
| THE KRAKEN | its pit in the Glow Gardens (-790, 180): a real hole with a stone ring | event: first 6 min after the server starts, then every 10 min, 90 s. Toast for everyone, red light pillar, red dot on the minimap, a bar with a clock. Bite its body or arms: EXP on every bite (0.5% of your evolution's EXP span). Arms slam on red circles (1.6 s warning): 20% HP, never a kill. Each fighter adds 60 of their own bites to its HP, so every shark counts the same. Beaten: everyone with 3+ bites gets 20% of their span + a 12 s Gold Rush. Hunters leave fighters alone. Not beaten in time: it sinks, you keep the bite EXP. |
- How they move: the server makes the turtle and whale paths once from the baked world (a search for the clearest ring: the
  whale path has no blocked point), publishes them as text; server and clients walk the same path by server time. Nothing is
  sent many times a second. The eel slides along one curve out of its burrow (every bone follows the curve). The Kraken's arms
  are turned bone by bone; the slam arm lifts during the warning and comes down at the hit.
- Terrain changed (backups `ServerStorage.MB_TerrainBackup_KrakenPit_13Nov`, `..._EelLair_13Nov`): Kraken arena levelled to
  y -52 (r 105, blended to r 175) + the pit; the eel burrow. `workspace.MB_Map.Lairs` holds the dark discs and rim stones.
  `MB_WorldBake` was re-run.
- Test hook (Studio only): `ServerStorage.MB_GiantDev:Invoke("kraken" | "krakenhp", frac | "krakenend" | "eel" | "pos")`.
- Tested: turtle slipstream pays EXP; eel warn -> wind-up -> strike took 150 HP (372 -> 222) from 78 studs away; Kraken rise, bites (+36 a
  bite at evolution 4 with x4 boosts), slam (-75 HP), kill ("KRAKEN BEATEN! +1,424 EXP", Gold Rush x3), sink. No script errors.
- Sounds (our own synth, `MEGA BITE\Audio\giants\`): EelGrowl 98583576558033, WhaleSong 118006360788733 and
  KrakenRise 118505351629475 are all Approved and in `MB_Sounds.List` (the last two were added later on 13 Nov).
  Not heard in a Play test yet.
- Known limits: the Kraken's arms curl (the model's far arm parts have no bones), so they reach about 85 studs; the bite
  zone and the slam circles were shortened to match. The eel's burrow is half hidden behind the statue's moustache.

## 4. Sharper textures (done for the 10 biggest)
- Research: Roblox now stores and shows textures up to 4096 x 4096 on MeshParts (texture streaming gives weaker devices a
  smaller copy by itself). Our big models had one 1024 texture each on 90-240 stud models = about 4 pixels a stud.
- Fix: every big texture upscaled 4x to 4096 with `MEGA BITE\Art\Textures4K\up4.py` (no AI model: cubic upscale, a small blur
  that rounds the stair-steps, then edge steepening clamped to the source colours). Same UVs, so only the TextureID changed
  (1,131 parts). An AI upscaler (Real-ESRGAN) was not used: loading its downloaded model file was blocked in this workspace.
| Texture | 1024 id (old) | 4096 id (new, Approved) |
|---|---|---|
| Ocean King | 110078965457018 | 70736711346695 |
| Lighthouse | 74025654703706 | 118469795396305 |
| Lost Galleon | 125860337920561 | 71753548218939 |
| Whale skeleton | 71177787427253 | 117032449921519 |
| Crystal Arch | 95806257899069 | 95113933751927 |
| Open Sea kit | 71858655631234 | 92474267977211 |
| Blue whale | 138948535286991 | 137757419706706 |
| Turtle | 76253176742420 | 103669378883479 |
| Eel | 110836603692159 | 82557432053226 |
| Kraken | 109737767509962 | 138515138021967 |
- Seen in Studio: the statue's beard and the galleon's planks, windows and ropes have clean edges now.
- Still soft (honest list): the statue's moustache ends and the galleon's sails are stretched paint (a UV problem, not size);
  the detail is only as fine as the design sheets (about 1,000 px per view). Real new detail needs new, larger art per model.
- Not changed: sharks and fish (1024 on models up to 40 studs = sharp enough), terrain, UI.
- The Output window shows "ContentId ... No asset content representation found" for some textures (old and new ones). They
  are Roblox texture-streaming messages, not script errors; the textures show.

## Still open
- Owner: test on a phone and with 2+ players (Kraken HP sharing, the "other player opened a chest" burst), then publish.
- (WhaleSong + KrakenRise: added.) Kill feed with portraits (Trench PvP), tier rooms in the Shop/Index,
  landmark uses (lighthouse lamp), biome sounds, hunters for big sharks: not started.
- Kit models are simpler than the sheet (the rock pillar has no hole, the mushrooms no glowing gills): a v3 would fix that.
