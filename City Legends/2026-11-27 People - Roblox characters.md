---
tags: [city-legends, people, look, performance]
created: 2026-11-27
---
# Street people: Roblox characters, never realistic (27 Nov 2026)

**Owner, 27 Nov:** first "also fix the people looking like mannequins", then a change of direction: "make it just roblox character, like the tiktok video car game, not some realistic looking people because thats terrifying and kids gonna get scared because the game is in roblox and they expect roblox character".

Reference: the TorqX clip, a normal Roblox avatar ragdolled on the crossing (`refs_2026-11-26_torqx/torqx_t0027.60s.jpg`). Replaces [[2026-11-27 Pedestrians - realistic people]] (its meshes stay uploaded, unused).

## What made them read as mannequins (checked in Play, before the change)
- One smooth body shape for everyone, flat single colours, a hard helmet-shaped hair shell, sliding walk with tiny arm swing (0.22 rad) and no knee or hip motion, standers frozen between snap turns, no head turns.
- The owner's answer was not "more real" but "Roblox": so no more work on the realistic meshes.

## What the people are now
- **Classic R6 Roblox avatars:** 7 anchored parts (torso, head with Roblox's head mesh, hair, 2 arms, 2 legs), still posed with BulkMoveTo.
- **Faces:** Roblox's classic faces (the smile most often). No thanaka, no custom faces.
- **Hair:** Roblox's own free catalog hairs (Pal Hair, Stylish Brown Hair, Brown Hair, Chestnut Spikes, Messy Hair, Trecky Hair, Brown Charmer Hair (Shaggy = Sideswept Bangs and Messy Hair taken out later the same day: see [[2026-11-27 NPC hair and joints]]); women and some schoolgirls: Lavender Updo, a bun). Kept in `ReplicatedStorage.PedKit.Hair` (Studio), texture cleared so the hair takes a dark colour. Monks: bald.
- **Skin:** Roblox body colours, classic yellow included.
- **Clothes (the Yangon part):** Roblox-style shirt / pants templates drawn by `tools/people/roblox_clothes.py`:
  - men: white / blue / cream / navy shirts, red and black T-shirts with jeans now and then, longyi checks in green, blue, brown, grey, maroon (knot at the front);
  - women: eingyi blouses (white, pink, yellow, lilac), htamein with a hem band (pink, teal, purple, gold);
  - monks: maroon robe over one shoulder; kids: white shirt and green longyi;
  - bare feet with flip-flop straps under the longyi.
- **Walk:** the classic Roblox walk: arms swing 0.6 rad and legs 0.55 rad from shoulders and hips, the body dips as the legs open, shorter people step faster, heads turn now and then.
- **Standing:** a small arm sway, slow head turns, turns eased instead of snapping (posed only when within 90 studs and in view).
- **Builds:** height 0.95-1.05 (men), 0.9-0.98 (women), 0.68-0.8 (kids); shoulder width 0.9-1.15.
- Walkers still go round shelters (`clearOf`, `PedBlock`), spread across the pavement, 30% in twos.

## Why no Humanoid (phones)
A Humanoid with Shirt / Pants is the normal way, and it worked, but its clothing composite cost about **1.4 MB of character texture per person** (Studio: 86 MB with 40 people, 28 MB without). Instead each clothed face wears a `Texture` cropped out of **two shared 1024 atlases** (shirts, pants; half-size faces with 4 px edge gutters). Character texture: **4.2 MB** with 40 people out.

## Numbers (Studio Play, PC, GUI hidden)
| | before (realistic meshes) | after (Roblox avatars) |
|---|---|---|
| people out | 31 | 40 (cap 40) |
| parts | 248 | 280 |
| textures + decals | ~93 | 1,040 (25 + face each) |
| FPS, fixed camera by the plaza | 38.4 | 52.2 |
| FPS looking at a crowd: with / without people | | 53.2 / 54.5 |
| character texture memory | | 4.2 MB (Humanoid version: 86 MB) |
| Studio process memory | 16,939 MB | 14,748 MB |

The FPS numbers are noisy on this PC (the "before" run was slower overall; Studio itself was busy). The fair cost of the people now is the crowd A/B: about 1.3 FPS. Memory in Studio is the whole process: only a phone's dev console gives the real number. **Not measured on a phone.**

## Pictures (same kind of spot: the Kabar Aye pavement by Sedona, 7-12 studs)
- Before: ![[2026-11-27 People - before (noon close-up).jpg]] ![[2026-11-27 People - before (evening, pavement).jpg]] ![[2026-11-27 People - before (mall shopper).jpg]]
- After: ![[2026-11-27 People - after (noon close-up).jpg]] ![[2026-11-27 People - after (walking in twos, noon).jpg]] ![[2026-11-27 People - after (evening, pavement).jpg]]
- Grazing close-up (no flicker; arms, torso and legs only touch, no two textures share a face): ![[2026-11-27 People - after (grazing close-up, no flicker).jpg]]
- PedHits: a 58 km/h hit made a ragdoll (both hips now have their own socket), it stood up again, 0 parts left loose: ![[2026-11-27 People - after (PedHits ragdoll at 58 kmh).jpg]]

## Files and ids
- Code: `src/client/YangonStreetLife.lua` (R6 layout `R6`, `geoFor`, `setClothes`, `setHair`, `pose`, `lookStep`), `src/client/PedHits.lua` (7 parts, 2 hip sockets, faces and clothes fade too), `src/shared/PedClothes.lua` (atlas image ids, garment cells, face slots).
- Clothes: `tools/people/roblox_clothes.py` -> `imports/people/clothes/*.png` (templates) + `imports/people/atlas_shirts.png` / `atlas_pants.png`. Atlas Decals 108837918839483 / 127064658584205 (images 95156362837878 / 83307406615981), group 33151111. The single templates were uploaded first too (`tools/people/clothes_ids.json`), not used.
- Studio: scripts written by Source (Open Cloud model + checksum), `ReplicatedStorage.PedKit.Hair` added, PlayerData store back on `CityLegends_v1`, saved (not published).

## Traps
- A Texture can show one rectangle of an atlas: `StudsPerTileU = faceWidth * atlasPx / slotPx`, `OffsetStudsU = slotX / atlasPx * StudsPerTileU` (same for V). Checked in Play: shirts, sleeves and longyi land on the right faces.
- A Decal / Texture ignores its part's Transparency: PedHits' fade now fades them too.
- Roblox catalog hair handles come as MeshParts now: clone them (a MeshPart's MeshId can't change at run time) and place by the handle's HairAttachment (head HairAttachment at 0, 0.6, 0).
- A flip-flop V strap on the front of the leg read as a smiling mouth: straps are straight bands now.
- "Beautiful Hair for Beautiful People" reads as a spiky emo cut, not long hair: left out.

## Not done / not checked
- Not tested on a phone (memory, FPS).
- Mall shoppers (standers) not looked at up close after the change.
- Only one long hair (the updo); more Roblox women's hairs would add variety.
- Hats and caps not added.

## Update: Roblox's Blocky body, 20 people (27 Nov, later)
**Owner:** "the characters blocky are too sharp and the corners need rounding, so i think u need to use the real roblox character from "Avatar" "Character" "Blocky"". Also: "the npc characters are too much": `Config.YangonStreetLife.PedMax` 40 -> 20.

- **The Blocky body is Roblox's default R15 body** (the bevelled blocks with the hand / foot lips). The catalog search found no Roblox-made "Blocky" bundle (only UGC copies), and `Players:CreateHumanoidModelFromDescription` with an empty HumanoidDescription (scales 1, proportion / body type 0) builds exactly that body. Its 15 MeshParts went into `ReplicatedStorage.PedKit.Body` (Studio, saved): one folder per R6 limb (`Torso`, `Left Arm` ...) with the R15 pieces `1`, `2`, `3` top down (attribute `Off` = the piece's centre from the limb box's centre, folder attribute `Box`), plus `Head` (texture cleared so the skin colour shows, attribute `HairAt`).
- **In the game:** each limb's first piece is its part 1-7 (pose and PedHits' joints unchanged); the other pieces are parts 8+ that follow their limb (`extraOf`), and PedHits welds them to it in a ragdoll. 16 parts a person (was 7), 20 people = 320 parts (was 280 at 40 people).
- **Clothes:** each piece shows its own slice of the limb's picture in the atlas. Hands stay bare skin (8 Textures a person fewer).
- **Traps found:**
  - **A Texture on a MeshPart takes the face's middle as its origin; on a Part, the corner.** Tested side by side in Studio: the clothes came out shifted half a face (wrong colours) until the offset gained W/2, H/2 on MeshParts.
  - **UnionAsync of MeshParts now returns a MeshPart** whose geometry only lives in the place (MeshContent None). In Edit it drew fine; in Play it drew a checkerboard. So the R15 pieces are kept as they are, not joined.
  - A union takes the colours of the parts it was made from; only white sources let Part.Color tint it. A union's CFrame is its first part's, not its box centre.
- **Checked in Play:** clothes land right on the rounded pieces (shirt collar / pocket / short sleeves, longyi checks, blouse, htamein); faces sit on the Blocky head; a 58 km/h hit ragdolled a person with every piece staying on its limb (largest sideways drift 0.004 studs), and they stood up again; no loose parts left.
- **Numbers (20 people, Studio Play, PC):** looking at the crowd 58.8 FPS without people, 58.0 with them (one more run was noisy: 49.1 with, warming up); 320 parts; 1,080 textures and decals; character texture memory 6.1 MB.
- Pictures: ![[2026-11-27 People - Blocky body (noon close-up).jpg]] ![[2026-11-27 People - Blocky body (rounded corners, very close).jpg]] ![[2026-11-27 People - Blocky body (evening, pavement).jpg]]
- Studio saved as version 2326 (not published). Note: version 2321 was saved earlier in this job while the PlayerData store was still on the test store; 2326 has it back on `CityLegends_v1`.
