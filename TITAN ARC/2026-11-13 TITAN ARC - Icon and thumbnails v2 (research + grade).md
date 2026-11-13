---
date: 2026-11-13
game: Stomp Evolution
tags: [research, thumbnails, icon, titanarc]
---
# Stomp Evolution: icon + thumbnail research and set v2 (13 Nov)

Method: skill roblox-icon-thumbnail, recipe [[2026-11-05 PLAYBOOK - Roblox icon, thumbnail and logo recipe]].

## Live genre check (Roblox search API, 13 Nov, players at the time)
| Game | Players | Icon | Thumbnail |
|---|---|---|---|
| +1 Venom Evolution | 16.7K | dark split face bacon / venom | before/after halves, sky blue, +1 / +7M stickers |
| +1 Sukuna Evolution | 13.8K | bright blue, bacon + "+1" | bacon close-up roaring, sky, +1 stickers |
| Bug Evolution | 9.7K | plain spider photo | plain in-game render |
| +1 Spider Arm | 8.9K | pink/cyan, bacon climbing | bacon on a wall, sky |
| +1 Power Fruit | 7.9K | purple fruit face | bacon + fruits, lava, +1 |
| Tap Simulator REBORN | 39K | red dragon | pet card + arrow |
| +1 Titan Evolution | 1.6K | titan +1 on green | muscle titan crouch, green grass, lightning, +1 |
| Titan Training Sim | 249 | gold titan | NOOB vs PRO halves |
| Giant Sim REBORN | 160 | cartoon giant | Halloween |

**Conclusions:**
- **Icon:** dark split face, the Venom formula and our GYM ARC 23x winner.
- **Thumbnails:** the genre leaders are BRIGHT, with a sky-blue background, white "+1" stickers, one big bacon, and before/after halves. My first (dark lime) thumbnails broke this, so they were redone bright.

## Character refs
- Real avatar render: `GYM ARC\Assets\thumbs_nov\bacon_real_v1.png` (Blender Cycles).
- Real in-game armour (Studio capture, NPCKit forms): `TITAN ARC\Assets\thumbs\refs\stone_form_ingame.jpg`, `forms_lineup_ingame.jpg` (Star / Magma / Stone / Starter).
- Lime = the STONE form's crystal colour, so the icon's titan half is the real Stone armour.

## Icon v2 (stomp_icon_v2_graded)
Attachments:
1. the bacon render;
2. the Stone form capture;
3. the GYM ARC 23x winner as the composition reference.

Raw ChatGPT grade: mean 0.44, 30% black, face/corners 4.7x (failed). Fixed in code:
- protected the face mask, gamma 1.25, radial vignette (r 0.30-0.70, 6% at the corners), green background x0.7;
- then pushed the face 55% toward white.

Result at 64 px: mean 0.315, 47% black, 10% white, 7.5% clip, face 22x the corners. It reads at 60 px next to Venom and Sukuna.

## Thumbnails v2 (bright, genre style)
- **thumb1 before/after** (`stomp_thumb1_beforeafter_v2`): the small nervous bacon next to "+1" stickers, then a white line, then the colossal STONE titan stomping a house, with "+1M" stickers. Measured at 384x216: mean 0.57, 8.5% black (bright style, like Venom and Sukuna). Reads at 384.
- **thumb2 boss** (`stomp_thumb2_boss_v2`): the MAGMA-armour bacon lunging a punch at the camera, the Rogue Titan smashing a tower behind him, avatars fleeing, "+1M" stickers. Mean 0.52. Reads at 384.
- Both used one chat: the icon first, then "same exact style" plus the forms lineup attached.
- Suggested home page set (2-3 active): thumb1 + thumb2, plus v1 dark stomp (`stomp_thumb1_stomp_v1`) as a contrast test.

## Files
In the owner's Downloads (the copy into the vault was blocked):
- stomp_icon_v2_graded.png, stomp_icon_v2_raw.png;
- stomp_thumb*_v2 files;
- v1 (dark lime set, superseded): stomp_icon_v1_*, stomp_thumb1_stomp_v1, stomp_thumb2_evolution_v1.

Setting the icon and thumbnails live is the owner's call (Creator Dashboard > Places > Thumbnails).
