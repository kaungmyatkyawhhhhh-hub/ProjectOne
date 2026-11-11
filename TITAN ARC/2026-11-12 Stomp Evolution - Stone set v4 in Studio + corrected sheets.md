---
date: 2026-11-12
tags: [stomp-evolution, titan, armour, stone-set, studio, roblox, sheets]
status: STONE v4 IN STUDIO (Stomp Evolution place, saved as version 4, not published). Iron, Magma, Storm and Crystal sheets redrawn to the new rules; not modelled yet.
---
# Stomp Evolution: Stone set v4 in Studio + corrected sheets (12 Nov 2026, 01:55 to 03:15)

Follows [[2026-11-11 Stomp Evolution - Stone set model v3 (real 3D, on the Bacon Hair avatar)]].

## Owner rules (12 Nov 02:14), for EVERY armour set
- **No one-sided shoulder pieces.** "i dont like those shoulder things on one side only ... its assymmetrical ... and that thing is huge too". Every set is symmetric: both shoulders wear the same modest pauldron (two or three stepped plates on the shoulder and upper arm, no wider than the upper arm plus a third, top well below the head). The theme goes on the chest, back piece, forearms, belt, knees and boots.
- **Four fingers, front only.** "it looks like the armor have 9 fingers because from each side theres 3 fingers sticking out". A closed fist shows four knuckles on the front; the outer side and the back are one smooth plate; a small thumb on the inner side.
- Skip approval for now; quality over quantity.

## Stone v4 (`Art\Stone\stone_v4.py`, review picture `Art\Stone\stone_v4_symmetric_pauldrons_4finger_fists.png`)
- Crystal boulder shoulder and slab shoulder removed. Both arms now carry the same pauldron: three stepped stone plates built on the upper arm (so they move with the arm), a carved glowing rune and two rivets on the outer plate, a small flat moss patch on top.
- New fist: four finger columns with glowing knuckle slots on the front only, smooth stone plates on the outer side and the back, small thumb on the inner side, about 12% smaller than before.
- 14 body parts, about 15,400 triangles in the Roblox version.

## In Roblox (step 3)
- Export: `Art\Stone\v4\export_roblox.py` builds the set with the arms straight down (= the R15 rest pose: arm centre 1.5 studs out, top 4.0 studs up; the model was already built at 125 cm per stud on that rig), drops the head, splits every glowing face into its own part, and bakes three 1024 colour maps (Torso, Arms, Legs; colour + glow added) from the 2048 paint.
- Uploaded to Myanmar Builders Club (33151111, the place's owner): model `105415394874292` (StompEvo_StoneSet_v4), images Torso `89557190832488`, Arms `94696822194783`, Legs `95487694908135` (arms/legs were "Reviewing" at upload; they showed in Studio).
- In the place (Stomp Evolution, placeId 74035932308449):
  - `ServerStorage.StompEvolution.Armour.Stone`: 28 MeshParts (14 stone with a SurfaceAppearance, 14 Neon glow parts), each with attributes `Limb` and `Offset`.
  - `ServerStorage.StompEvolution.ArmourKit` (ModuleScript): `Apply(character, "Stone")` welds every piece to its R15 limb with an explicit C0 and hides the body parts under it (head, face, hair and hats stay); `Remove(character)`.
  - `ServerStorage.StompEvolution.Raw.StoneSet_v4_raw`: the import as it came in (Roblox imports it 125x too big and turned 180 degrees; the template fixes both).
  - `Workspace.StoneSet_v4_Test`: an anchored test dummy wearing the set (delete before publishing).
- Tested in Play on the owner's own avatar: standard blocky body forced through `ApplyDescription` (body parts 0, scales 1), then `ArmourKit.Apply`. Idle and walking: every piece follows its limb, nothing tears. Pictures: `Art\Stone\v4\studio_stone_v4_on_owner_avatar_idle.jpg`, `studio_stone_v4_walking.jpg`.
- Saved to Roblox (version 4). NOT published.

## Not done / known issues (honest list)
1. Arms straight down: the bracers sit close to the wide hip plates. Roblox's default idle keeps the arms away enough in the test; a custom idle/walk with the arms a little out would look stronger (Titan Simulator style).
2. The pauldrons are built on the upper arm, so they turn with the arm; on a big punch they may dip into the chest. Not checked with a punch animation.
3. Players with other body types are forced to the standard body (needed so the armour fits). Accessories that sit on the body (capes, backpacks, swords) stay and can poke through.
4. Not checked on a real phone yet (14 stone + 14 Neon parts per player, 15.4K triangles).
5. Texture: one 1024 map per region (torso, arms, legs). Close-up detail is softer than the Blender render.

## Corrected sheets (step 4, design part) — same ChatGPT chat as the line-up
Made with the Stone v4 render attached as the body/shoulder/fist reference and the owner rules pasted into every prompt. Previews (963x648) in `Art\Concepts\`; the full-size originals are in the ChatGPT chat "Create Roblox Character Lineup" (they could not be saved: this PC's Chrome is not the one connected, so downloads went to the other PC).
| Set | Preview | Check |
|---|---|---|
| Iron | `stomp_sheet_stage4_iron_v2_symmetric_preview.png` | symmetric riveted pauldrons, centred torn cape, 4 knuckles |
| Magma | `stomp_sheet_stage5_magma_v2_symmetric_preview.png` | no chimneys, centred basalt spine ridge, 4 knuckles (the mouse pointer is in the side view of the preview only) |
| Storm | `stomp_sheet_stage6_storm_v2_symmetric_preview.png` | no big bolt fin, cloud collar, mirrored forearm fins; first try had 3 knuckles, fixed in one follow-up |
| Crystal | `stomp_sheet_stage7_crystal_v2_symmetric_preview.png` | same small crystal row on both pauldrons, centred back fan, 4 knuckles |
The first versions made earlier tonight (one-sided fin, chimneys, bolt, crystal cluster) are rejected by the owner's rule.

**Rules block pasted into every sheet prompt (reuse it):**
> OWNER RULES FOR EVERY SET: 1) The armour is perfectly SYMMETRIC left to right. BOTH shoulders wear the SAME matching shoulder piece, mirrored. NO one-sided signature piece, NO tall fin, blade, chimney, crystal cluster or boulder on only one shoulder. Each shoulder piece is a modest layered pauldron of two or three stepped plates that sits ON the shoulder and upper arm, no wider than the upper arm plus one third, and its top stays well below the top of the head. 2) The fists: a closed fist with exactly FOUR fingers, visible ONLY on the front knuckle side; the outer side and the back of the fist are one smooth armour plate with NO fingers; a small thumb on the inner side only. 3) The theme goes on the chest, the back piece, the forearms, the belt, the knees and the boots, never as one big lopsided add-on.

## Next
1. Iron set model: reuse the Stone v4 body (same lofts, pauldron and fist builders), new plate shapes from the Iron v2 sheet, and a METAL painter (brushed scratches, worn bright edges, grime in gaps, rivets) instead of the stone painter. Then the same export, upload and `ArmourKit` test.
2. Then Magma, Storm, Crystal in that order; the Starter and Brawler sets need redrawn sheets under the same rules.

## Lessons
- The Chrome connected to Claude is the OTHER PC's Chrome (16 threads, its own Downloads). On this PC, sheets can't be downloaded from it; use previews or the PC's own browser.
- Roblox Open Cloud: an FBX upload needs the file typed as `model/fbx`, or it fails with "Creating Model from a application/octet-stream file".
- An FBX exported from Blender (cm scale) imports 125x too big at 1 stud = 125 cm and turned 180 degrees about Y: fix it in the template, not in the export.
- `CreateHumanoidModelFromDescription` in Edit has no Motor6Ds; test poses in Play.
