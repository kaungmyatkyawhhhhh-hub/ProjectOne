---
date: 2026-10-21
tags: [gymarc, bug]
status: fixed
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# GYM ARC - Bug - Alter textures only change color

Prompt: [[2026-10-21 GYM ARC Prompt - 38 Alter textures not showing]]. Feature: [[GYM ARC - Body Alters]]. Progress: [[2026-10-21 GYM ARC Alter textures fix]].

## What the owner saw
Wearing a Body Alter only changed the skin color; no striations, veins or gloss.

## What was checked (21 Oct)
1. **The maps on the body:** after wearing Shredded, all 25 skin pieces (live muscle meshes, forearm / calf stages, hands, feet, head) wore `SkinStage` = Alter_Shredded with Color 119513312479015 / Normal 103766752198769 / Roughness 71101897859940 (Vascular: 103109392852988 / 72861088552312 / 121431954405592). So the right maps were on.
2. **Uploads and config:** all 15 Tier 1 maps were uploaded, load fine, and match Config/Alters and `ReplicatedStorage.SkinStages.Alter_<id>`.
3. **Body updates:** a real gap. The skin pass only ran when the look stage, the color or the NUMBER of pieces changed; a swapped mesh with the same count kept a plain skin. Also the "preload every skin" step loaded nothing (PreloadAsync on a SurfaceAppearance loads nothing), so the first time someone wore an alter its maps streamed in for a few seconds and only the tint showed.
4. **UV scale (the main cause):** the body's UVs spread ONE texture over ~14 studs on the torso, ~10 on the arms and ~8.5 x 17.7 on the thighs, on a 7-stud body (70-120 texture pixels per stud). Each part showed a magnified patch of the texture: Shredded's striations (12 px apart) became 0.16-stud "wood grain", and Vascular's thin veins with ~3% color contrast were nearly invisible.

## Fix
- **New maps** (`Downloads\gym_arc_alters\tier1_human_tiled`, uploaded, ids in Config/Alters with the old ids in a comment):
  - Shredded: repeated 2x2 inside the image (striations half the size), bumps 1.5x.
  - Vascular: same scale (its veins are thin lines), bumps 2.5x, color contrast 3x.
  - Peak: 2x2 (its striations), bumps 2x, color contrast 2x.
  - Pumped and Tanned unchanged (by design mostly color + gloss).
- **MuscleRig:** the skin pass also runs when a piece is added to the body and every 2 s (cheap: a piece that already wears the right skin is skipped). Tested: a stripped piece got its alter back in 1.3 s.
- **MuscleRig preload:** every skin map is preloaded through an image, so a first-time alter shows at once.

## Follow-up (owner's answers, [[2026-10-21 GYM ARC Prompt - 38b Bronze tan and head color]])
- Tanned / Peak: a deep bronze tint worked out from the skin (no more orange-red); the head's color follows the alter (no alter maps on it). See [[2026-10-21 GYM ARC Alter textures fix]].
- The preload above did NOT work in game (a game script can't read a SurfaceAppearance's map ids: it errored); it uses the config ids now. Peak's normal map never loaded (re-uploaded as 99012039750322).

![[GYM ARC/Screenshots/alters/alters_side_by_side.jpg]]
