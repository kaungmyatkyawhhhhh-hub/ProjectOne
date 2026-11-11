---
date: 2026-11-11
tags: [megabite, ui, v5, store, chatgpt, art, build]
status: built in Studio (not published), play-tested. Owner reviews on his phone.
---
# MEGA BITE: UI v5 "illustrated shop" (11 Nov, ~03:00-03:40, autopilot)

Back to [[00 MEGA BITE Home]]. Direction + owner words: [[2026-11-11 Research - Modern UI direction (owner feedback + all TikTok UIs)]]. Replaces UI v4 neon sign ([[2026-11-11 MEGA BITE - Settings, real Store, skins + UI v4 neon sign (build steps 4-5)]]).

## Why
Owner, 02:38: the Shark Shop TikTok UI "SUCKS", "stone-age ui... modern ui where everything is INSANE", "viewport frame is bad, use image instead with chatgpt". The key reference turned out to be the @.6ix13 "completely made by AI" Roblox shop TikTok (8.2K likes): every product is an illustrated banner or card, product art breaking the frame, patterned header band, themed corner ornaments, heavy cartoon titles, swoosh transitions.

## What's built
- **`K.Window` v5** (UIKit; every window: Store, Settings, Fish Index, Fossilize): bright ocean-blue gradient body with soft diagonal light streaks, an illustrated patterned header band (sliced), the window icon tilted on the top-left corner, a heavy cartoon title (LuckiestGuy), an optional yellow tagline, 4 ocean corner ornaments that bob gently, a header sheen that sweeps every 4 s, the red round X, and `win.Pop()` = a swirl + ring + star-glint swoosh on open. Neon v4 kept as `K.WindowNeon`.
- **Store v5** (`MB_StoreUI`; backups `ServerStorage.MB_StoreUI_v2_backup`, `MB_StoreUI_v4_neon_backup`): a scrolling shop. SKINS: 5 illustrated cards (no more 3D ViewportFrame), each with its own button (green R$ price → blue EQUIP → gold EQUIPPED), the equipped one has a slow turning glow, cards breathe. PASSES: 3 illustrated banners; each hero object (star, crown, radar) floats and tilts above its banner. Benefits written big ("x1 > x2 EXP FROM EVERY FISH"). Real prices from Roblox, no fake discounts. A purchase closes the window and plays the centre celebration.
- Kit helpers: `K.Heavy` (cartoon title text), `K.Section` (dark strip header), `K.Swoosh`, `K.V5` (all art IDs), startup preload of every kit image (no half-empty first open), `K.HealImage` retry.

## ChatGPT art (4 one-try prompts in one chat, our in-game skin lineup attached as the colour reference `MEGA BITE/UI/v5/mb_skins_reference.png`)
1. 5 square skin cards on magenta: the chunky low-poly great white swimming left, breaking the card edges, each in its skin's exact colours, saturated themed background (turquoise rays / coral reef / midnight + golden motes / lavender fog / volcanic embers).
2. (pass banners with objects: art good, but the objects overlapped the next banner → split into 3 + 4)
3. The 3 hero objects alone: golden star with fish + coins, golden crown with blue gems + bubbles, green sonar radar.
4. The 3 banner backgrounds alone: gold sunburst + coins, purple + diamonds, teal + waves; empty glowing spot on the left.
5. Window chrome: a turquoise fish-scale header band + 4 corner ornaments (coral + shell, starfish + seaweed, clam + pearl, sea-foam wave).
Processing in the browser: border flood key + soft edge un-mix, plus a soft GLOBAL magenta key for enclosed pockets (star swirl, crown ring), cut on empty columns / rows, trimmed, ≤1024 px.

## Asset table (group 33151111, all approved)
| Piece | ID |
|---|---|
| Skin card Classic / Coral / Lantern / Ghost / Ember | 80439444364020 / 80914580298074 / 71858044103083 / 119402450954740 / 122451131499954 |
| Object x2 EXP / VIP / Radar | 84163091388721 / 75026350735364 / 71245899221864 |
| Banner x2 EXP / VIP / Radar (1024x213) | 92492434527531 / 103974237661152 / 137951488116083 |
| Header band (1024x192, SliceCenter 220,40,804,152) | 78819132014361 |
| Ornament Coral / Star / Pearl / Foam | 104980791031527 / 117431334819461 / 130359423107404 / 92990921810958 |

## Lessons
- Ask ChatGPT for objects and backgrounds SEPARATELY when objects should break a frame: cleaner cuts AND they can be animated in-game.
- Enclosed magenta pockets survive a border flood → always run the soft global magenta pass on art with rings/swirls.
- First open of a window showed blank pills/icons → preload every kit image at startup.

## Next
- HUD buttons (STORE / INDEX / gear / DART) in the same v5 language; the Fish Index cards as illustrated rarity cards.
- Evolve / Fossilize reveal in the RNG-Battlegrounds style (darkness, the shark lit, a clean name card).
- Step 6: Red Trench + crown bounty.
