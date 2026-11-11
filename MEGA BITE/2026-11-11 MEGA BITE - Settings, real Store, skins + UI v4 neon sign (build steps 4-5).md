---
date: 2026-11-11
tags: [megabite, build, settings, store, gamepass, skins, ui, neon]
status: built in Studio (not published). Owner tests on his phone.
---
# MEGA BITE: Settings, the real Store, Abyss skins + UI v4 "neon sign" (11 Nov, night)

Back to [[00 MEGA BITE Home]]. Follows [[2026-11-11 MEGA BITE - Titan steals built (growth, size tags, crown)]].

## Owner messages
- 01:34 "do the step 1-6 in order while i sleep ... quality > quantity ... loop until perfect"
- 02:29 "our ui looks sloppy rn, use the references from tiktok videos' uis"

## Step 4: Settings (done, play-tested)
- Gear bubble next to STORE / INDEX opens the Settings window: colour-blind outlines, UI size (small/normal/big), screen shake, vibration, music + sounds (off/low/mid/high).
- Saved in player data (`Settings` JSON attribute, 1.2 s debounce = one save per burst of taps).
- New icon sheet 2 (ChatGPT, keyed + cut in the browser, uploaded as group 33151111): Settings 74291811685089, Music 85310774230148, Speaker 115934152773672, Vibrate 78963268509764, Eye 74165447872742, UISize 100990936945851, Shake 79579407335630, Ammonite 103631033430741, FossilTooth 129375286612349, Trench 108975183941711, Bounty 118575674670217, Brush 88929535704120, Lantern 118391778969809, Ghost 122226483720850, Ember 94416876642536, Coral 77740751984017 (all in `K.Icons`).
- Fixes found in testing: windows could be taller than a 390 px phone at UI size BIG → `K.AttachScale` now clamps centred windows to 90% of the safe area. First-open pop-in → pill art preloaded. An image fetch that fails once stays blank forever (Studio) → `K.HealImage` re-requests once with a cache-busting suffix (all kit icons).

## Step 5: the real Store (done, play-tested)
Game passes made via the Open Cloud game-passes API (the experience is Private, so nothing could be bought by real players yet). Universe 10775517854.

| Pass | ID | R$ | What it does (never helps in a fight) |
|---|---|---|---|
| x2 EXP | 2076269037 | 349 | food + golden fish EXP x2, stacks with Fossilize |
| VIP | 2076275101 | 249 | shining gold name on your size tag + gold bubble trail |
| Shark Radar | 2074684996 | 199 | nearest 16 fish as dots on the minimap (golden = gold dot) |
| Coral Skin | 2075051046 | 99 | coral-pink + pearl bubbles |
| Lantern Skin | 2074487008 | 149 | abyss navy + warm light + glowing motes |
| Ghost Skin | 2074817047 | 149 | pale, 22% see-through + misty trail |
| Ember Skin | 2074750986 | 199 | charcoal + orange belly + drifting embers |

- Skins work on EVERY evolution: each shark's texture is a small palette strip, so a skin = a per-slot palette remap (body gradient, belly, eye, dark trims; mouth + teeth kept). Minnow/Piranha keep their cute black pupils. 28 textures, IDs in `C.Store.SkinTex`.
- Server `MB_StoreServer`: ownership checked on join + on purchase → `Pass_<key>` attributes; `StoreAction` remote ("Buy" prompts Roblox's purchase, "Equip" only for owned skins); skin look re-fits when the body grows; analytics `Pass_Bought_<key>`.
- Store window: YOUR current shark in a 3D preview wearing the picked skin, 5 skin chips (Classic + 4), one clear button (R$ price → EQUIP → EQUIPPED), three offers with OWNED tags. Prices are read from Roblox (`GetProductInfo`), never typed fake prices. A purchase closes the store and plays the centre celebration.
- Old store kept in `ServerStorage.MB_StoreUI_v2_backup`.

## UI v4 "neon sign" (owner 02:29)
Reference: the Shark Shop TikTok sign (navy plate, cyan neon edge, warm marquee bulbs, chunky cyan letters, red sub-banner) + the Claude cutscene TikToks (one hero colour on darkness + glow = premium). See [[2026-11-10 Research - Map style reference (Shark Shop TikTok)]] and [[2026-11-11 Research - 14 TikToks (Claude cutscenes, VFX, ocean games, Roblox dev tips)]].
- What was sloppy: 5 competing colours (orange card, yellow/pink/blue ribbons, grey dead pills), ribbon ends that looked misaligned, a wrapped line, a filler sentence.
- Now (one kit, every window: Store, Settings, Fish Index, Fossilize): navy gradient plate, 4 px cyan neon edge + soft halo behind, a thin inner second line, chasing warm bulbs top + bottom, the title on a navy sign plate with white-to-cyan letters, a red sub-banner for the tagline, the red round X.
- Only navy + cyan + warm bulbs + one red accent. Each card has ONE hero colour (the skin card's edge + spotlight take the skin's colour; Index cards take the rarity colour once caught). Done states are calm kelp outlines, not grey pills.
- Code: `K.Neon`, `K.NeonPanel`, `K.Bulbs`, new `K.Window` (old one kept as `K.WindowV2`).

## Next
- Step 6: Red Trench zone + crown bounty (everyone who bit the crown shark in the last 10 s shares it) + a threat intro card.
- Later (TikTok lessons): 2.5 s evolve / Fossilize cutscene (white-out flash + name card), ocean beauty pass (god rays, marine snow, coral variety, a gentle giant).
