# MEGA BITE - Landmarks, treasure chests and the world map (13 Nov 2026)

Owner's order: "make the map interactable also make the minimap bigger ... put treasure chests at the landmarks / monuments that reward greatly to its chance of finding landmarks".

Status: built and tested in Play in Studio, **not published**.

## What the player gets
- **Discover a landmark**: swim close the first time -> "DISCOVERED! KELP LIGHTHOUSE  +EXP", and it appears on both maps.
- **Treasure chest** at each landmark: glows while it is full, touch it with your mouth, the lid swings open, "TREASURE! +EXP". It refills in 15 minutes (per player, saved). While it refills it stays open and shows "Refills in m:ss".
- **World map**: tap the minimap or press M. A picture of the real sea (drawn from the game's terrain), your landmarks with their chests, you (gold arrow), other sharks. Tap anywhere, a landmark or a row to drop a **pin**.
- **Pin**: a gold arrow on the screen with the distance in metres, and a pin on the minimap. It clears when you arrive ("You made it!").
- **Minimap**: bigger (132 px), now shows the same sea picture sliding and turning under you.

## Numbers
- Reward = share x the EXP span of your evolution (minimum 12) x passes. Shares: Lighthouse 0.08, Crystal Arch 0.08, Whale Graveyard 0.11, Ocean King 0.14, Lost Galleon 0.20 (further and harder to find = more).
- Discovery pays the same amount once.
- `GameConfig.World.Chest = {Refill = 900, Reach = 15, MinReward = 12, FindRadius = 50}`.

## Tested (Play, Studio, new player)
- Discovery: fired at the lighthouse, +24 EXP (x2 pass), icon on the minimap.
- Chest: opened by touch, EXP 24 -> 48, `ChestAt` saved, lid open, "Refills in 8:14" tag.
- World map: opens with M, shows the picture, the list (found 1/5, hints for the rest), the zone name.
- Pin: tap on the sea -> pin on the map, REMOVE PIN button, arrow + "401 m" on screen, pin on the minimap rim.
- No script errors.

## Where things are
- Server: `ServerScriptService.MB_LandmarkServer`. Client: `StarterPlayerScripts.MB_WorldMap`. Config: `GameConfig.World`.
- Chest model: `ReplicatedStorage.MegaBite.Props.Chest` (4,252 triangles; gates front 0.961, top 0.911, end 0.927). Files: `MEGA BITE/Art/Expansion/Chest/`.
- Map picture: `MEGA BITE/UI/map_art/` (`worldmap_render.py` draws it from the terrain heights `h150.npy` and the prop clusters `clusters.json`). **Redraw and re-upload it when the map changes.**
- Icons: `MEGA BITE/UI/map_icons/`.

## Asset ids (all Approved)
| Asset | Id |
|---|---|
| World map picture v1 | 114207362077970 |
| Gold arrow | 75765145266293 |
| Chest model / texture | 79421424707953 / 71922442915040 |
| Icons: Chest, ChestOpen, Pin, Map, Compass | 138505551499239, 126894529071513, 86944542344501, 102165644302946, 138647759277443 |
| Icons: Lighthouse, Ocean King, Whale Arch, Crystal Arch, Galleon | 81366330102395, 131098746463085, 97749629537107, 123493834826708, 125652079921298 |

## Still open
- Three landmarks are not modelled yet (whale skeleton, crystal arch, galleon): their rows show "???" with a hint.
- A chest-opening sound of its own (now it uses the bank ding + star burst).
