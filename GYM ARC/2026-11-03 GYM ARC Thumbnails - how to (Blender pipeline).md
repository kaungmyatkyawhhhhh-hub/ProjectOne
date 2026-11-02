---
date: 2026-11-03
tags: [gymarc, thumbnails, tutorial]
---
# GYM ARC thumbnails - step by step (3 Nov)
Shot list: [[2026-11-03 Thumbnail shot list (GYM ARC + Galaxy) from the art study]]. Bacon: [[2026-11-03 Research - Bacon hair in thumbnails]].

## Step 1 - Claude Code builds the poses (paste in the GYM ARC session)
```text
GYM ARC: build a THUMBNAIL SCENE for marketing renders (edit mode only, never published: put it in ServerStorage.ThumbnailScene and move it to Workspace only while exporting). Never change gameplay.
Make posed, ANCHORED rigs using the real in-game bodies, clothes and textures (tank top + shorts always on, opaque):
1) BACON_4ft: a 4'0" fresh player with the default bacon hair (Roblox's free "Pal Hair") in the white tank top + shorts, shocked pose: looking up, arms slightly out, mouth open face if the game has one.
2) MID_5ft8: the same bacon at 5'8", proud pose.
3) GIANT_7ft: a 7'0" giant (big alter body, NOT gold, tank top + shorts, the bacon hair), pose A: barbell overhead; also a copy GIANT_7ft_flex: front double biceps.
4) GIANT_7ft_wrestle + BACON_wrestle: arm-wrestling pose across the arm-wrestling table (hands locked).
5) Props: the heaviest barbell with plates, the arm-wrestling table, a height ruler (a simple tall measuring board with 4'0" / 5'8" / 7'0" marks).
Pose with the Motor6D Transforms (keep the pose when anchored). Each one its own Model with a clear name. Screenshot each pose for me, and say "ready to export".
```

## Step 2 - Export (you, in Studio, ~5 min)
1. Wait for Claude Code's "ready to export". In Explorer open ServerStorage > ThumbnailScene, drag it into Workspace.
2. Click ONE model (e.g. BACON_4ft) in Explorer.
3. Right-click it > **Export Selection...** > save as `BACON_4ft.obj` in `Downloads\thumb_export\` (Studio also writes the .mtl and texture .png files next to it: keep them all).
4. Repeat for each model and prop (one file each).
5. Also export the **Hall of Fame building** (Workspace > its model) the same way.
6. Move ThumbnailScene back to ServerStorage. Don't publish with it in Workspace.
7. Tell Claude (me): "exported". I read the folder from your PC.

## Step 3 - I render (Claude, Blender)
Bright blue sky + gold glow, key light + white rim light, camera at phone readability, 1920x1080, then the edit: the number ("7'0"", "875 LB"), outline + glow, speed lines, nothing in the bottom 20%. You get 5 thumbnails + the icon in Downloads.

## Step 4 - ChatGPT touch-up (you, optional, effects only)
Attach ONE of my renders and paste:
```text
Touch up this Roblox game thumbnail. Add effects only: a few gold sparkles and soft light glow around the big character, faint dust in the air, slight motion lines around the barbell, a little more contrast. DO NOT change the characters, faces, bodies, clothes, text, colours, or layout. Same size 1920x1080.
```
Compare with my render: if it changed a face, a body or the text, use my render instead.

## Step 5 - Upload + test
1. Creator Hub > GYM ARC > Places > the place > Thumbnails.
2. Experience Detail Page tab: put the HEIGHT one FIRST (it is the search image).
3. Home Page tab: add 4-5 (all different stories) > Thumbnail personalization > Start. Leave 7+ days.
4. Check Analytics > Acquisition > New User Funnel: thumbnail CTR >= 5%, page -> play >= 70%.
5. Ads: use the winner.

## Status (3 Nov, Claude Code): Step 1 done
- Built in Studio: `ServerStorage.ThumbnailScene` (edit mode only, no gameplay change). Models: BACON_4ft (shocked), MID_5ft8 (hands on hips), GIANT_7ft (barbell overhead) + BARBELL_875lb, GIANT_7ft_flex (front double biceps), GIANT_7ft_wrestle + BACON_wrestle + ARMWRESTLE_TABLE (hands locked), HEIGHT_RULER (gold marks at the real head heights; labels go on in the render), HOF_export (13 parts: the building meshes, torch bowls, pedestal plates; no glass, lights, effects or text).
- Bodies are the game's own: Robloxian 2.0 body, the NPC muscle stage meshes, skin maps, white tank top + black shorts, Roblox's free Pal Hair (63690008). Giants = mass monster body, normal skin (Pumped alter skin looked orange/gold, so not used). The game has no open-mouth face: default face.
- All anchored, posed with Motor6D Transforms (the pose is also saved on each model as the `PoseJSON` attribute). Rebuild tool: `ServerStorage._Builders.ThumbnailRigBuilder` (not used by the game).
- Next: Step 2 (export).

## Status (3 Nov, later): 2 action poses added
- LIFT: GIANT_lift (arms straight up, chest out, slight lean back, wide legs) + BACON_lifted (lying on the giant's hands, limbs flailing, head turned to the camera). Center x=70.
- CRUSH: BARBELL_falling (copy of the 875 lb bar, tilted 20 deg, ~6 studs up) + BACON_run (big step, arms pumping, leaning forward, head turned back to the bar) + GIANT_drop (arms down, confident). Center x=95.
- **Bug found and fixed (gameplay):** building in Edit mode required the game's BodyStages module, whose client biceps reshape ran in Edit and swapped the 14 upper arm templates in `ReplicatedStorage.BodyStages` for EditableMesh copies (MeshId empty; after a save they load as plain boxes = everyone else's arms broken). Restored all 14 with the real meshes (ids from `Config.StageMeshBackup`, checked by size), and fixed the arm pieces in every scene model the same way. The builder now runs `B.RestoreTemplates()` before every build. **Rule: after any Edit-mode build, run `B.RestoreTemplates()` and check no `BS_*Arm_Arm_*` template has an empty MeshId before saving.**
- Scene arms use the real upper-arm meshes without the runtime biceps trim (biceps up to ~8% deeper than in game).
