---
date: 2026-11-05
tags: [gymarc, thumbnails, icon, blender, prompt]
---
# GYM ARC - Prompt: new icon + 2 thumbnails (Blender)

Research: [[2026-11-05 Research - What the owner clicks on Roblox (10 min watch)]]. Owner (5 Nov): "ok lets do new icon new #1 thumbnail second thumbnail", "give prompt for claude code then, also dont crash the studio".
Note: my glTF export (4 rigs, Skinning on) crashed Studio on 5 Nov; nothing was saved. Use OBJ, one model at a time.

```text
GYM ARC – NEW ICON + 2 THUMBNAILS (read vault first: Roblox Playbook\Research notes\2026-11-05 Research - What the owner clicks on Roblox (10 min watch).md)

0. DON'T CRASH STUDIO (glTF export with Skinning crashed it on 5 Nov):
   - File > Save to Roblox first. Never Play mode during this.
   - Export as .OBJ only (no glTF/skinning), ONE model per export, wait for each to finish.
   - Make a temp folder Workspace._ThumbExport_TEMP with clones from ServerStorage.ThumbnailScene (BACON_4ft, GIANT_7ft + BARBELL_875lb together, GIANT_7ft_flex), moved +4000 Y. Select one model, File > Export as .obj, save to C:\ObsidianOne\Claude+Obsidian\GYM ARC\Assets\thumbs_nov\<model>.obj. Delete the temp folder at the end and confirm it's gone. Never touch the originals or anything else in the place.
   - GIANT BUILD (owner 5 Nov), for BOTH giants only (GIANT_7ft, GIANT_7ft_flex); BACON_4ft stays as he is. % = of the MASS MONSTER (muscle look 0..2, 2 = mass monster, look = % x 2): arms (biceps, triceps, forearms) MAX, traps MAX, rhomboids MAX, lower back MAX, lats 25% (look 0.5), legs 50% (quads, hamstrings, glutes, calves = look 1.0); everything else as today's giant. Build it with the game's OWN body/muscle-stage system (MuscleData / BodyStages / LimbStages / the module that dresses players) on the temp clones, so it matches exactly what a player with those levels looks like in-game; don't hand-scale parts. Screenshot the clone front + back in Studio and send it before exporting. Lopsided is wanted.
   - Head (123480233606534) and Pal Hair (29938421) won't export (permissions): model our own Roblox-style head, hair and faces in Blender.

1. BLENDER: new scene "Thumbs_Nov" only; never edit the owner's other scenes. Import the OBJs. Our own art, polished render look (rim light, skin shine, depth), NOT painted / AI-looking. No emojis, no known characters, no copied art. Cycles or EEVEE with bloom.

2. ICON (512x512, must read at 50 px): tight crop. Front: the bacon player's face filling ~60% of the frame, confident smirk, eyes glowing purple/teal. Behind him: the giant flex silhouette as a dark shadow with two glowing gem-coloured eyes, purple left / teal right rim light. No text except optionally one small "+1". No logo.

3. #1 THUMBNAIL (1920x1080): GIANT_7ft holding the barbell, low camera angle, the plates swapped to big glowing M WEIGHTS Diamond (clear crystal, platinum rim) + Ruby (red crystal, gunmetal rim) plates in front, near the lens (like Power Lifters' 300 KG). Straining/angry face, veins. Dark gym (use our gym look), the plates are the main light source. ONE huge number: the real Diamond top weight in lb from the game data (no fake number), white with a dark outline. Small GYM ARC wordmark top corner.

4. SECOND THUMBNAIL (1920x1080): BACON_4ft in front stepping toward the camera (low angle), smirk, glowing eyes, holding a small dumbbell or gem plate. Behind him, filling the frame: GIANT_7ft_flex as a huge dark shadow silhouette with glowing gem eyes and purple/teal edge glow (= what you become). 3-5 small "+1 STR" stickers (white, dark outline). Purple left / teal right light split, light debris/sparks.

5. Output PNGs to GYM ARC\Assets\thumbs_nov\ (icon_v1.png, thumb1_v1.png, thumb2_v1.png) + a preview sheet with each at real Roblox sizes (icon 150 px and 50 px, thumbnail 384x216). Send me the previews. Don't upload, don't publish.
6. Order after approval: new #1, Halloween temple #2 until Halloween ends, thumb 2, gym screenshots last, drop 7'0". A/B test thumb1 vs thumb2.
```
