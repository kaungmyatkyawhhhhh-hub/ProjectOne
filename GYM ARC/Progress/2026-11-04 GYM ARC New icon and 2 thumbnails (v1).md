---
date: 2026-11-04
tags: [gymarc, progress, thumbnails, icon]
---
# GYM ARC - new icon + 2 thumbnails (v1, 4 Nov)

Back to [[00 GYM ARC Home|GYM ARC Home]] · research: [[2026-11-05 Research - What the owner clicks on Roblox (10 min watch)]] · pipeline: [[2026-11-03 GYM ARC Thumbnails - how to (Blender pipeline)]]

Nothing uploaded, nothing published. Waiting for the owner's OK.

## Files (`GYM ARC/Assets/thumbs_nov/`)
- `icon_v1.png` (512x512), `thumb1_v1.png`, `thumb2_v1.png` (1920x1080), `preview_sheet_v1.png` (icon at 150 + 50 px, thumbnails at 384x216 and 192x108).
- `BACON_4ft.obj`, `GIANT_7ft.obj` (+ the barbell's position as a MARK line), `GIANT_7ft_flex.obj`. Plain OBJ: positions + faces, studs, Roblox Y-up. MARK lines = the parts the place can't read (head, hair, hands, feet, elbow balls).
- `giants_build_front.jpg` / `giants_build_back.jpg`: the giants' new build in Studio before the export.
- `_tools/`: the Blender build / render / post scripts and our face textures, to make v2 quickly.
- Blender file: `Downloads\thumb_export\Thumbs_Nov.blend` (a NEW file, one scene "Thumbs_Nov"; `gymarc_thumbs.blend` and its scenes were never opened).

## The three images
- **Icon:** the bacon's face (~55-60% of the frame), confident smirk, eyes glowing purple (left) / teal (right). Behind him: the flex giant as a glossy black silhouette with two glowing gem eyes, purple rim on the left, teal on the right. No text.
- **#1 thumb1:** GIANT_7ft holding the barbell overhead, low camera. Plates = M WEIGHTS crystal plates (Diamond: clear crystal, platinum rim; Ruby: red crystal, gunmetal rim), the main light. Straining angry face (gritted teeth, temple veins), arm veins. Dark brick gym with the red neon strip. Number **1,735 LB** = the real Crystal Deadlift (Gem Mine) top weight with DIAMOND plates 13/13 (game data, heaviest barbell lift). Small GYM ARC logo top right.
- **thumb2:** BACON_4ft stepping toward a low camera, smirk, glowing eyes, a small purple gem dumbbell. Behind him, filling the frame: the flex giant as a dark silhouette with glowing gem eyes and purple / teal edge glow. 5 "+1 STR" stickers (white, dark outline), sparks, purple left / teal right. Logo top left.

## How it was made
- Studio (Edit mode only, never Play): `Workspace._ThumbExport_TEMP` with clones of BACON_4ft, GIANT_7ft, BARBELL_875lb, GIANT_7ft_flex (+4000 Y).
- Giants rebuilt with the game's own system (ThumbnailRigBuilder: Robloxian body -> the saved PoseJSON -> BodyStages / LimbStages muscle stages), owner's build: arms, traps, rhomboids, lower back MAX (mass monster), lats look 0.5, quads / hamstrings / glutes / calves look 1.0, the rest as before (mass monster).
- The bacon (temp copy) re-posed to a step toward the camera (Motor6D pose, the muscle pieces follow their body parts). Build unchanged.
- Export: Studio has no script command for File > Export, so a temp script read each muscle mesh (EditableMesh) and sent plain OBJ text to a tiny receiver on this PC (127.0.0.1 only, stopped after). No glTF, no skinning, one model at a time.
- The head (123480233606534), Pal Hair, hands and feet can't be read (permissions): our own Roblox-style head, swept bacon hair, hands and feet were modelled in Blender, faces drawn by us.
- Cleanup: the temp folder deleted and checked gone; originals untouched. `B.RestoreTemplates()` put back 14 upper-arm stage templates (the known Edit-mode side effect, 3 Nov note); 0 bad templates after.
- Render: Cycles (GPU), AgX, then bloom / grade / text in post (Montserrat Black Italic, the game's title font).

## Known weak points (for v2 if wanted)
- Diamond plates read white-hot more than clear crystal; Ruby faces go pinkish where the light is strongest.
- At 50 px the bacon's eyes read light, not strongly purple / teal; the giant's eyes are small.
- The giant's white tank top is the largest bright area in thumb1.

## Order after approval (owner)
New #1 (thumb1), Halloween temple #2 until Halloween ends, thumb2, gym screenshots last, drop 7'0". A/B test thumb1 vs thumb2.
