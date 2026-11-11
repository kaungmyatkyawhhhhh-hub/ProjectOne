---
date: 2026-11-11
tags: [stomp-evolution, titan, 3d, blender, stone-set, model, bacon-hair]
status: IN PROGRESS. Loaded in the owner's Blender (collection StoneSet_v3) for a look. NOT approved, NOT high quality yet. No rig, no Roblox export, not seen in Studio.
---
# Stomp Evolution: STONE set, model v3 (real 3D, on the Bacon Hair avatar), 11 Nov 2026, 15:54 to 16:55

Follows [[2026-11-11 Stomp Evolution - Stone set model v1 (first pass in Blender)]].

## What the owner said (in order)
1. 15:54, with a screenshot of the v1 fist and bracer: "its suppose to be 3d and not just pictures on a block", "same for the body and legs and shoulders too", "also make the legs longer by 1.2x".
2. 16:24: "are u using ur blender? use my blender in my pc".
3. 16:32: sent `baconhair.obj`: "use this instead of the character rn".
4. 16:33: "the armor dont have to be blocky, they look fat cuz the bellys pushing outwards and the legs look like sticks when theyre blocky".

## What v3 is
- **The wearer is the Bacon Hair avatar** (`Art\Character\baconhair.obj`, exported from Roblox Studio, 3,868 faces). Scaled 125 cm per stud. At that scale its legs are 252 cm = the sheet's 210 x 1.2, so the "legs 1.2x" ask is met by the avatar itself. The yellow smiley head is gone.
- **The dark under-suit IS the avatar's body**, painted dark slate with thin glowing cracks. Nothing is wrapped round the belly or the legs any more.
- **The armour is thin fitted stones on the body's measured shape**: chest plate (six wedges round a framed cut gem), collar stones, straps with rivets, belt with a carved buckle, flat skirt flaps that hang straight down, thigh plates (wider at the hip), knee caps, knee straps, shin greaves (flare up to the knee), boot cuffs, boots (heel block, faceted toe cap, instep strap, glowing sole), bracers and fists built straight and then swung onto the avatar's real arms (17 degrees out, 12 forward), the rock shoulder with crystals and moss, the slab shoulder, the back rune slab.
- **No sheet picture is used anywhere.** Every rune, crack, knuckle plate, rivet and strap is geometry. Runes and cracks are cut into the stone (boolean) with a glowing floor.
- **Textures are painted on the model in 3D** by `stone_v3_paint.py`: per-stone colour drift, top light, dirt in the gaps (Cycles AO), worn light edges, crack lines with a light lip, pits, moss tint on tops, stitches on leather, glow spill next to runes. One 2048 atlas: `stone_v3_color.png` + `stone_v3_glow.png`.
- 14 parts, 19,586 triangles (Head 1,822, Body 2,090, UpperTorso 4,364, LowerTorso 1,560, each lower arm about 1,580, each hand 1,428, legs 484 to 892, feet 508).

## Files (`TITAN ARC\Art\Stone\`)
`stone_v3.py` (model), `stone_v3_paint.py` (run this one: builds, unwraps, paints, applies), `stone_v3_color.png`, `stone_v3_glow.png`, `stone_v3_front_and_three_quarter.png`, `stone_v3_back_side_top.png`. `stone_v2.py` / `stone_v2_paint.py` = the blocky in-between version (own block body), kept for reference only.
Blender needs scipy for the painter: installed into `Tools\blender_pylibs` (pip --target), added to sys.path by the script.
Run: `exec(open(r"C:\ObsidianOne\Claude+Obsidian\TITAN ARC\Art\Stone\stone_v3_paint.py").read())`. About 40 s at 2048. Set `STONE_RES=4096` only for close-up renders (takes over 80 s and the tool call times out, but it finishes).

## Checked so far
- Looked at from front, both three-quarters, back three-quarter, side and from above in the owner's Blender (material view, Standard colour).
- Every armour piece is a closed mesh (0 open edges) except the head decals (eyes, smile: flat on purpose).

## NOT done / known problems (honest list)
1. The outline was not scored against the sheet (the body is a different character now, so the old 0.90 gate needs a new reference).
2. No backface check from 6 angles. No rig, no R15 split check, no FBX, not in Studio, not at phone size.
3. The avatar's face came without its picture, so eyes and smile are my own flat shapes. The real Bacon Hair face and hair texture should come from the Roblox files.
4. Fists are big and hide the forearm from some angles; the two shoulders differ on purpose (sheet), but the slab side still reads simpler than the boulder side.
5. The stone paint is procedural. It reads as cracked rock, but it is not yet the hand-painted look of the sheet (bold highlight strokes, cleaner big shapes). Next: stronger big light/dark shapes per stone, fewer thin cracks.
6. Leg armour follows the avatar's box legs, so the legs are still straight; only the plates give them shape. If the owner wants more leg shape, the greave and thigh plates can be made thicker and more tapered.

## Lessons (for the 3D method)
- An armour set is modelled ON the real avatar mesh from Studio, never on a made-up block body. Measure the avatar (sections per body part, arm axis) and fit plates to it.
- Never project the design sheet onto simple shapes as the final look. The sheet is a reference for sizes and colours only; every detail the owner can see becomes geometry.
- "Fat" came from wrapping a thick box round the hips and tilting the skirt plates outward. Keep waist armour flat against the body and let the chest plate be the furthest-forward thing.
- Ask which Blender before a long build: the owner wants the work visible in his own Blender. Build straight there (scripts in the vault, exec from Blender); the cloud copy is only for syntax checks.
- Saving a changed script: write it under a new name (stone_v3_b.py), then copy it over stone_v3.py from inside Blender and check the size. Overwriting through the file tool was not tested here.


## Update 16:55 to 17:10 (owner's proportions and the shoulder)
- Owner 16:55: "the hips need to be wider by 0.3 studs and legs wider by 0.3 studs each side too". Done on the avatar itself: hips +0.3 studs on EACH side (they flare out below the waist; the waist, belt and chest stay), each leg +0.3 studs wider (grows outward, the legs still meet in the middle). Thigh plates, knee caps, greaves, boot cuffs, boots, skirt flaps and side plates were refitted. Settings at the top of `stone_v3.py`: `HIPW`, `LEGW` (studs; 0 = stock avatar).
- Side effect: the bracers hit the wider hips, so the arms are swung 16 degrees further out (`ARM_OUT`), now about 33 degrees from straight down. Smallest gap bracer to hip armour: about 5 cm. This is a pose, not a shape: the rig/animation will decide the real arm angle later.
- Owner 16:58 (screenshot of the rock shoulder): "this shoulder thing is too big and it look like its floating". Now 0.7x the size (`SH_K`) and seated on the shoulder joint (`SH_AT`): the arm comes out of the middle of its underside and its inner side sinks into the collar. The two small floating shards from the sheet are still there (smaller).
- Rule: a shoulder piece must sit ON the joint with the arm coming out of it, and stay smaller than the head. Check picture: `Art\Stone\stone_v3_wider_hips_legs_smaller_shoulder.png`.


## Update 17:18 to 17:35 (legs sculpted like a catalog bundle)
- Owner 17:18: "the leg look fat now , why cant u just do like the models from roblox catalog".
- Cause: I kept the avatar's box legs, made the boxes 0.3 studs wider as asked, and put plates on top. Same width from hip to floor = fat (wide box) or stick (narrow box).
- Looked again at the owner's Titan Simulator references (`Art\Concepts\titan_sim_ref_1_green_armour.png`, `titan_sim_ref_3_frost_armour.png`). In a catalog armour bundle the leg is its own sculpted part: a slim dark thigh half hidden under the tassets, a knee, a greave/boot that gets wider towards the floor, and a clear gap between the two legs. The bulk sits on shoulders, chest and gauntlets.
- Now: the avatar's leg meshes are no longer used. `leg()` lofts each leg from chamfered sections: under-suit leg (slim), thigh guard (wider at the hip, narrower at the knee), knee cap, greave that flares down, ankle cuff of fitted stones, heel block, toe cap, glowing sole. Leg centre lines moved out to 62 cm (`LEG_X`, stock 49) so there is a gap between the legs under the wider hips. Hips stay +0.3 studs per side. `LEGW` is retired.
- Still weak: the hip block is a flat wide box above the slim thighs (its dark underside shows under the skirt); arms and torso are still plates on the avatar and should get the same sculpted treatment.
- Check picture: `Art\Stone\stone_v3_catalog_style_legs.png`.


## Update 17:59 to 18:40 (decision: OUR OWN sets, built like catalog bundles)
- Owner 17:56: "just copy 1:1 of titan simulator armor from catalog", then 17:59: "the bundles are good but i want our own one to be different from titan simulator armor".
- **Decision: every Stomp Evolution set is our own design, built the way a Roblox catalog body bundle is built** (each body part its own sculpted mesh, the player's head on top). Roblox's bundles are the quality and construction reference, not the designs. The real-bundle route stays written up in [[2026-11-11 Stomp Evolution - Catalog armour route (use the real Roblox bundles like Titan Simulator)]] as a fallback.
- Measured in Studio (read-only, unparented rigs): default blocky R15 = torso 1.94 wide, each leg 0.99, legs centred +-0.5, arms centred +-1.5; bundle 192 = upper torso 2.60 wide (1.34x), limbs about 1 stud. Rule: bulk in the upper torso and shoulders, limbs slim.
- Stone set now: the Bacon Hair body is gone (only his head and hair stay). `body()` lofts neck, chest (wide, tapering to a narrow waist) and hips (flare below the belt, +0.3 studs per side kept); `arm()` has a slim upper arm; `leg()` as before. 15 parts, 19,720 triangles.
- Check picture: `Art\Stone\stone_v3_own_bundle_full_body.png`.
- Next: (1) texture closer to catalog bundles (smooth surfaces, bold painted shapes, less crack noise), (2) rig to R15 and test in a Stomp Evolution place in Studio, (3) the other sets as the same kind of bundle, each with a theme Titan Simulator did not have.
