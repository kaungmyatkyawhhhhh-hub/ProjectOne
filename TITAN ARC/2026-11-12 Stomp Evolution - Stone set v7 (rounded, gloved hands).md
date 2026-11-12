---
date: 2026-11-12
tags: [stomp-evolution, titan, armour, stone-set, bundle, studio]
status: STONE v7 IN STUDIO (saved, version 13, not published).
---
# Stomp Evolution: Stone set v7 (rounded, gloved hands) — 12 Nov 2026, 12:30 to 13:20

Follows [[2026-11-12 Stomp Evolution - Stone set v6 (full cuirass, crystal crests)]].

## Owner (12:29, 12:35)
- "korblox models are not blocky, thats the main reason"
- "the roblox catalog bundle hands are different from ours too"

## Rule for every armour set (from these two)
- **Not blocky.** Limbs have ROUNDED cross-sections (superellipse), every plate and box edge is a wide 3-segment round bevel, everything is shaded smooth. Only crystals and glowing runes keep sharp edges.
- **Hands are gloved hands, not fists or boxes:** a relaxed open hand with the palm towards the leg, four fingers together and slightly curled in (shallow finger gaps), a thumb in front, a cuff at the wrist. Size like the bundles: about 0.75 W x 0.9 H x 0.8 D studs.

## How (`Art\Stone\stone_v7.py`)
- `bevel()`: offset x1.8 (env `STONE_ROUND`), at least 3 segments, clamp overlap.
- `loft()`: 20-point superellipse sections (exponent from the old chamfer value: bigger chamfer = rounder) instead of 8-point chamfered rectangles.
- Smooth shading on all faces except crystal/glow/groove.
- Tried first: one Catmull-Clark subdivision over every piece (`STONE_SUBD=1`). It barely rounded the already-bevelled shapes and broke the carved runes. Off by default.
- Hand: stone cuff with rivets, dark glove palm with a small glowing rune on the back, a finger mitten that curls inwards with 3 dark finger gaps, a thumb in front.

## In Roblox
- Model `115908084006170`; Torso `73617726776577` (TextureID); Arms `72958019055805` / glow `130019059521644`; Legs `91291155444792` / glow `118877981287433`. All waited for Approved before use (no more cached failures).
- v6 template kept in `ServerStorage.StompEvolution.Raw.Stone_v6`.
- Picture: `Art\Stone\v7\studio_stone_v7_vs_korblox.jpg`.

## Known issues
- **Triangle count is high: ~87k for the whole set** (torso 13.7k, each upper arm 8.2k, each hand 7.2k). Korblox-style bundles are far lighter. Fine for testing; before launch cut it (2 bevel segments, fewer loft points on small parts, decimate) and test on a phone.
- Some forearm runes became short dashes on the rounded surface.
- Colour/contrast gap vs Korblox (see the v6 note) is still open.
