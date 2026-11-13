# MEGA BITE - Giants: models and plan (13 Nov 2026)

Four giant creatures for the late game. Built with the sheet method (sheets: `Art/Expansion/mb_sheet_cr_*.png`). Files: `Art/Expansion/Giants/`.
Status: models finished and rigged, WAITING FOR UPLOAD (see the status note). The gameplay is not coded yet: it needs the models in Studio to test.

Preview: `Art/Expansion/Giants/giants_v1_preview.jpg`

| Creature | File | Triangles | Bones | Sheet match |
|---|---|---|---|---|
| Blue whale | `MB_Whale_v1.fbx` | 2,861 | 7 | body outline: side 0.991, top 0.988 |
| Giant turtle (reef garden + 2 little fish on its shell) | `MB_Turtle_v1.fbx` | 3,246 | 10 | top 0.991 (the sheet's side view is a 3/4 picture: not a contract view) |
| Colossal eel | `MB_Eel_v1.fbx` | 3,026 | 8 | side 0.985 (straightened), top body 0.950 |
| Kraken | `MB_Kraken_v1.fbx` | 3,968 | 34 | mantle and head measured and painted from the sheet; arms are designed curls (the sheet's arms are hand-drawn 3/4) |

All four: one mesh, one 1024 texture, at most 2 bones per vertex, 100 studs long as built (scale in Studio).

## How they were made (`gk.py`, one build script per creature)
- Body = a loft from the sheet's measured outline (side profile + top-view width).
- Fins, flippers, crest, frills = rounded plates cut from the sheet's own outlines.
- Colour = the sheet's own pixels, projected from the view each surface faces, into one atlas.
- Eel: the sheet draws it in a wave. `eel_rectify.py` straightens the picture along the body axis first (check: `eel_rect_check.jpg`).
- Turtle: the garden (coral, sea grass, sponges, clam) is real geometry; the painted garden was removed from the shell picture.
- Sheet conflicts and what won: eel width (top view too fat: scaled x0.72 so the head is 0.86 as wide as tall, like the front view); eel tail fin (top view draws it flat: the side view won); whale fluke and flippers (side view is 3/4: the top view won).

## Bones (for the code: animate with Bone.Transform, like the manta)
| Creature | Bones |
|---|---|
| Whale | Root, Tail1, Tail2, Tail3, Fluke, FlipL, FlipR |
| Turtle | Root, Neck, Head, FlipFL, FlipFR, FlipRL, FlipRR, Tail, Fish1, Fish2 |
| Eel | Root (head), Spine1 ... Spine7 (to the tail) |
| Kraken | Root (head), Mantle, Arm1_1..3 ... Arm8_1..3, TentL_1..4, TentR_1..4 |
Pose tests: `*_poses.jpg` (tail beat, flipper flap, eel wave, Kraken arms open).

## Gameplay plan (to build after the upload)
The plan is the one in [[2026-11-13 MEGA BITE - Bigger sea, landmarks and giant creatures (plan)]] (owner: "huge creatures that are violent and some friendly too"). Sizes in the game are set in Studio (the files are 100 studs long).

| Giant | Size | Where | Behaviour (from the plan) |
|---|---|---|---|
| Giant Sea Turtle | about 90 studs | N, Kelp Lighthouse | friendly, slow loop through the kelp. Swimming in its wake = x1.5 speed and a small EXP trickle. The coral patch on its shell has fish to eat (bones Fish1, Fish2 are the two little fish). Never hurts. |
| Blue Whale | about 220 studs | the whole Open Sea ring | friendly, a 4-minute loop. Sings (our synth) within about 300 studs. A cloud of sardines follows it = easy food. Never hurts. |
| Colossal Eel | about 160 studs | E, in a crack under the Ocean King | violent. Glowing eyes + a growl first, red wind-up 1.2 s, then a lunge of about 70 studs; DART dodges. A hit works like the live predators (damage, no blood). Ignores Great White and Megalodon. |
| KRAKEN event | about 250 studs | W, Glow Gardens | every 10 min or so (first after about 6). Toast, red minimap marker, red light pillar. 90 s: arms slam on red warning circles (knockback, no kill); everyone bites the arms and body; HP scales with the players nearby; EXP shared by everyone with 3+ bites; sinks with a gold fish burst. Nothing sold. |

Tanky prey for the big sharks is already in the game as the four giant fish: [[2026-11-13 MEGA BITE - Late game v1 (giant prey fish)]].

## Upload and import notes
- Upload each FBX as a Model to the group (33151111) and wait for Approved.
- Import as a skinned mesh (bones kept). Find each bone's turn axis in Studio from its world frame (do not trust the FBX axes).
- Put the models in `ReplicatedStorage.MegaBite.Creatures`.

## Tool fix found on the way (all baked models)
`bake_common.py` read the baked picture from an 8-bit image, which is already sRGB, and encoded it again: every baked colour came out pale.
Fixed (`bake_common_v2.py`: float image + a tone mode that never lets a face be paler than its own colour).
The whale skeleton and the crystal arch were re-baked: use `MB_LM_WhaleSkeleton_v3.fbx` and `MB_LM_CrystalArch_v3.fbx` (v2 has washed-out colours).
