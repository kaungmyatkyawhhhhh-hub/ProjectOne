# MEGA BITE - Long work order: status (13 Nov 2026, updated after the model pass)

Owner's order (03:40): do all the models and everything left, quality first, no questions until all of it is done.
Nothing is published. The owner tests and publishes.

## Done and tested in Studio (Play)
| Item | Note |
|---|---|
| Health for sharks, fish and predators (Combat v1) | [[2026-11-13 MEGA BITE - Combat v1 (health for sharks, fish and predators)]] |
| World v2: realistic terrain, rings that get harder, biomes, fish around the player, 34 predators in rings | [[2026-11-13 MEGA BITE - World v2 (open world, rings, biomes, fish director, predators)]] |
| Landmarks, treasure chests, world map, pin + arrow, bigger minimap with the real sea picture | [[2026-11-13 MEGA BITE - Landmarks, treasure chests and the world map]] |
| NPC movement ("stuck in ground, noclips into props, stays in one place") | audit: 0 fish inside props in 12,752 samples, 0 predators inside props or above the surface, schools go round walls |
| World map window on phones | 344 tall, big text, one line per landmark |
| Biome moods | `MB_BiomeMood`: green kelp hills, golden east, pale south, violet west; darker further out and deeper |
| Phone controls | Roblox's own stick and JUMP button are off; MEGA BITE's floating stick + DART / ability buttons only |
| Phone performance (Megalodon camera, Studio) | reef 656K triangles, open sea 350-390K, trench 284K (target under 1M) |
| Both kid simulations on World v2 (round 6): first 5 minutes unchanged; top map tell is still "same prop again" | [[2026-11-13 MEGA BITE - Kid simulations on World v2 (round 6)]] |
| Late game v1: four giant prey fish for the far rings, Fish Index 12 species, feat words, big Gold Rush multiplier | [[2026-11-13 MEGA BITE - Late game v1 (giant prey fish)]] |

## Models built, WAITING FOR UPLOAD (files in `MEGA BITE/Art/Expansion/`)
Uploading stopped on 13 Nov: two Chrome browsers are connected to the account and the owner must say which one to use. Studio's own upload refuses the vault folder (it is not an approved upload folder).

| Model | File | Triangles | Gates (sheet match) |
|---|---|---|---|
| Whale skeleton (Whale Graveyard) | `WhaleSkeleton/MB_LM_WhaleSkeleton_v3.fbx` (v3 = colours fixed) | 9,446 | within 1 stud of the sheet: side 92% / 94%, top 90% / 97% |
| Crystal Arch | `CrystalArch/MB_LM_CrystalArch_v3.fbx` (v3 = colours fixed) | 5,092 | side 0.876, top 0.897 (within 1 stud: 98%) |
| The Lost Galleon | `Galleon/MB_LM_Galleon_v1.fbx` | 9,000 | side 0.954, top 0.981, front 0.950 |
| Open Sea kit: 8 props (tube sponge, giant clam, anemone, whip coral, barrel sponge, moss rock, glow mushrooms, ruin column) | `KitOpenSea/MB_Kit_OpenSea_v2.fbx` (v2 = lighter) | 7,144 in total (580 to 1,252 each) | built by hand from the kit sheet (one 3/4 view per prop); preview `kit_views_v2.jpg` |
| Blue whale, giant turtle, colossal eel, Kraken (rigged) | `Giants/MB_*_v1.fbx` | 2,861 / 3,246 / 3,026 / 3,968 | [[2026-11-13 MEGA BITE - Giants (whale, turtle, eel, Kraken) models and plan]] |

After upload (each must say Approved first):
1. `InsertService:LoadAsset(id)`; the FBX arrives 100x too big, front = -Z; use the texture id Roblox made from the FBX.
2. Landmarks: scale, turn, seat on the seabed, parts anchored, SmoothPlastic, no shadows; solid parts PreciseConvexDecomposition; model Persistent; attributes `MB_Landmark`, `ModelAssetId`.
3. Clone `ReplicatedStorage.MegaBite.Props.Chest` into `workspace.MB_Map.Chests` (attribute `Landmark` = id).
4. Run `MB_WorldBake`, then the movement audit (`ServerStorage.MB_AuditMod`).

| Landmark | Place | Size | Turn | Chest |
|---|---|---|---|---|
| WhaleArch | (-90, 700), seabed -42 | 200 studs long | length east-west | inside the rib cage, on the sand |
| CrystalArch | (-560, -60), seabed -31 | 150 wide, 73 tall | opening faces east; crystals, mushrooms and stars = Neon | 26 studs behind the arch |
| Galleon | (-880, 520), seabed -84 | 200 long | side-on to the reef | behind the hull hole |

## Still to do
- Uploads (blocked, see above), then: place the 3 landmarks + chests, mix the 8 kit props into `MB_WorldDress` (rule from the sim: every patch mixes 5+ kinds), import the 4 giants.
- Giants gameplay (whale and turtle as tanky prey, eel ambush, Kraken event): needs the models in Studio.
- Sounds of their own for the chest and the biomes (code-synthesized; they need uploading too).
- Video ideas left: kill feed with portraits (Trench PvP), tier rooms in the Shop, landmark uses (lighthouse lamp).
- Real-device checks (phones).
