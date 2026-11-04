---
date: 2026-11-05
tags: [galaxy, vfx, cutscene, art, artist]
status: placeholders in the game now; swap the ids in UIAssets when the art comes
---
# Galaxy Incremental - Cutscene template + VFX art list (for the artist)

From [[2026-11-05 Galaxy Incremental - Prompt - Cutscene template (Sols RNG style)]] item 7 and [[2026-11-05 Galaxy Incremental - Prompt - VFX layering pass]].
- **Every image:** white (or greyscale) on a transparent background, because the game tints it with the moment's colour. PNG.
- **Sizes:** ≤ 512 px for particle textures (Playbook), ≤ 1024 px for the big screen symbols.
- **Where they go:** `ReplicatedStorage.Galaxy.UIAssets` → `fx.*` (and `icon.*` for symbols).

## A. World particle textures (the VFX layering pass)
| # | Name | Size | What it looks like | Used for | Placeholder now |
|---|---|---|---|---|---|
| 1 | fx_sparkle | 256 | 4-point star, thin rays, bright core, soft glow | every sparkle burst | owner's upload 94374970413464 |
| 2 | fx_glowdot | 128 | soft round light, small bright centre | slow embers after a Supernova | 99926211922098 |
| 3 | fx_ring | 256 | thin bright circle, soft glow either side | ring flashes (new body, tier-up, comet catch, Supernova) | 96523294175789 |
| 4 | fx_streak | 512 x 64 | long soft line, bright head on the right | a new body's trail, cutscene speed lines + starburst rays | 94618099610729 |
| 5 | fx_shard | 128 | a sharp crystal splinter, pointing up | the Supernova's fast shards ("sharp = impact") | 118739627833700 |
| 6 | fx_smoke4x4 | 512 (4x4 frames of 128) | a soft puff growing and fading over 16 frames | the haze that lingers after a Supernova | 101295804867366 |

## B. Cutscene template (screen-space, GalaxyCutscene)
| # | Name | Size | What it looks like | Used for |
|---|---|---|---|---|
| 7 | cs_symbol_star | 1024 | the big centre STAR symbol (rays, maybe a ring), clean lines | first Supernova, Ignition (now: the sun icon) |
| 8 | cs_symbol_forge_* (6) | 1024 | one symbol per core kind: stardust, shard, comet, XP sun, luck crystal, gas giant | Forge roll cutscenes (now: the game's icons) |
| 9 | cs_ring_thin | 1024 | a very thin ring with 2-4 small "beads" on it | the 3 rings orbiting the symbol (now fx_ring) |
| 10 | cs_glint | 128 | a 4-point star glint, sharper than the sparkle | the twinkling glints (now fx_sparkle) |
| 11 | cs_nebula (2-3 variants) | 1024 | soft cloudy nebula shapes, greyscale | the coloured background (now soft glows) |
| 12 | cs_ray | 512 x 32 | a light ray, bright at the left, tapering | the starburst at the climax (now fx_streak) |
| 13 | cs_constellation_star | 128 | a small star node with a halo | the points the constellation lines connect (Ignition) |

## C. Sounds (Roblox-licensed only)
- **Now:**
  - riser = `windup` (9126102694), its END is placed on the drop
  - hit = `boom` (9126102254)
  - mini = `milestone`
- **Wanted:** one stinger per rarity tier (Rare / Epic / Legendary / Mythic / Celestial), each with a clear drop. Its drop time gets measured and stored in the config.
