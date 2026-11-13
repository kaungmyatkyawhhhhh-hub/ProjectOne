# MEGA BITE - Long work order: status (13 Nov 2026)

Owner's order (03:40): do all the models and everything left, quality first, no questions until all of it is done.
Nothing is published. The owner tests and publishes.

## Done and tested in Studio (Play)
| Item | Note |
|---|---|
| Health for sharks, fish and predators (Combat v1) | [[2026-11-13 MEGA BITE - Combat v1 (health for sharks, fish and predators)]] |
| World v2: realistic terrain, rings that get harder, biomes, fish around the player, 34 predators in rings | [[2026-11-13 MEGA BITE - World v2 (open world, rings, biomes, fish director, predators)]] |
| Landmarks, treasure chests, world map, pin + arrow, bigger minimap with the real sea picture | [[2026-11-13 MEGA BITE - Landmarks, treasure chests and the world map]] |
| NPC movement ("stuck in ground, noclips into props, stays in one place") | audit: 0 fish inside props in 12,752 samples, 0 predators inside props or above the surface, schools go round walls |
| World map window on phones | was 512 tall (text 8 px on a phone); now 344 tall, big text, one line per landmark |
| Biome moods | new `MB_BiomeMood`: green kelp hills, golden east, pale south, violet west; darker further out and deeper; the red trench blended in |
| Phone controls | Roblox's own stick and JUMP button are off (MB_Swim); MEGA BITE's floating stick + DART / ability buttons only |
| Phone performance (Megalodon camera, Studio) | reef 656K triangles, open sea 350-390K, trench 284K (target under 1M); 310-425 draw calls |
| Lost body guard | a shark whose body is destroyed (thrown out of the world) gets a fresh shark at the reef (MB_SwimServer) |

## Models built, WAITING FOR UPLOAD (files in `MEGA BITE/Art/Expansion/`)
Uploading stopped on 13 Nov: a second Chrome browser connected to the account and the browser tool must be told by the owner which one to use. Studio's own upload refuses the vault folder (it is not an approved upload folder).

| Model | File | Triangles | Gates (sheet match) |
|---|---|---|---|
| Whale skeleton (Whale Graveyard) | `WhaleSkeleton/MB_LM_WhaleSkeleton_v2.fbx` | 9,446 | within 1 stud of the sheet: side 92% / 94%, top 90% / 97% (strict IoU 0.72 / 0.74: thin bones) |
| Crystal Arch | `CrystalArch/MB_LM_CrystalArch_v2.fbx` | 5,092 | side 0.876, top 0.897 (within 1 stud: 98%) |
| The Lost Galleon | `Galleon/MB_LM_Galleon_v1.fbx` | 9,000 | side 0.954, top 0.981, front 0.950 |

After upload (each must say Approved first):
1. `InsertService:LoadAsset(id)`; the FBX arrives 100x too big, front = -Z; use the texture id Roblox made from the FBX.
2. Scale to the size below, turn it, seat it on the seabed, parts anchored, SmoothPlastic, no shadows; solid parts: PreciseConvexDecomposition; model Persistent; attributes `MB_Landmark`, `ModelAssetId`.
3. Clone `ReplicatedStorage.MegaBite.Props.Chest` into `workspace.MB_Map.Chests` (attribute `Landmark` = id).
4. Run `MB_WorldBake`, then the movement audit.

| Landmark | Place | Size | Turn | Chest |
|---|---|---|---|---|
| WhaleArch | (-90, 700), seabed -42 | 200 studs long | length east-west (players arrive from the north and see its side) | inside the rib cage, on the sand |
| CrystalArch | (-560, -60), seabed -31 | 150 wide, 73 tall | opening faces east (toward the reef); crystals, mushrooms and stars = Neon | 26 studs behind the arch (swim through to reach it) |
| Galleon | (-880, 520), seabed -84 | 200 long | side-on to the reef | behind the hull hole (swim through the hole) |

## Still to do
- The 8 Open Sea kit props, then mix them into `MB_WorldDress`.
- Giants: turtle, blue whale, colossal eel, Kraken (models, then the gameplay: tanky prey, eel ambush, Kraken event).
- Late game: bigger prey for the far rings; tune predator and chest rewards.
- Sounds of their own for the chest and the biomes (code-synthesized; they need uploading too).
- Video ideas: pun pop-ups, big multiplier, kill feed, tier rooms.
- Both kid simulations again on the new world.
