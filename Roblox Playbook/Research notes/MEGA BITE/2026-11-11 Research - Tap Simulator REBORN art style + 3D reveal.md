---
date: 2026-11-11
tags: [megabite, research, art-style, reference, vfx, ui]
source: owner's recording "Roblox 2026-11-11 09-44-53.mp4" (Downloads)
---
# Tap Simulator REBORN: art style + the "3D effect" (for MEGA BITE)

Owner 11 Nov: "i want like the tap reborn art style (the one that i showed reference video)" and, about the hatch, "u see the 3d effect its so cool". Back to [[00 MEGA BITE Home]]. UI side of the same recording: [[2026-11-11 Research - Modern UI direction (owner feedback + all TikTok UIs)]].

Game: Tap Simulator REBORN (Cursor Makers, Aug 2026), about 35K average CCU, 50M+ visits, 93.6% rating, about 38-minute sessions. Sources: [RoTrends](https://www.rotrends.com/game/10629695169/Tap-Simulator-REBORN), [Destructoid](https://www.destructoid.com/tap-simulator-reborn-codes/).
Frames: `MEGA BITE/Research video/tapreborn_art_sheet.jpg` (12 stills), `tapreborn_hatch_strip_4fps.jpg` (the hatch, 0.25 s per cell).

## Art style
- **Light:** bright, clean noon daylight. Saturated but not neon. Almost no haze, soft short shadows, clear sky.
- **World:** chunky rounded props: blob trees, pebble rocks in blue-grey, thick wooden decks. The floor is big orange/peach tiles with lighter grout. The grass is a flat bright green. There are few, big shapes and no small noise.
- **Pets (the look the owner means):**
  - Chibi and cube-ish with rounded edges.
  - The head is the body. Huge glossy eyes with big white catch-lights, tiny limbs.
  - 2-4 flat pastel colours with SMOOTH soft shading (not faceted).
  - Examples: a white Bunny with pink inner ears and green eyes; a blue-grey Kitty with yellow eyes.
- **Eggs:** glossy, speckled. Glowing cracks (green), and the egg wobbles.
- **Compared with our sharks:**
  - Ours are faceted, angular "Fisch-like" low-poly with fierce eyes; that is the opposite direction.
  - To match: rounder bodies, smooth shading, bigger friendlier eyes and fewer facets, while keeping our rigs (Spine0..3, Jaw) and the SkinTex skins.

## The "3D effect" (hatch reveal), measured at 4 fps
| t | What happens |
|---|---|
| 0.0-1.5 s | Egg on a pedestal, close to the camera. Shrinking white ring (tap timer), cracks grow and glow. |
| 1.75 s | Light beams leak from the cracks. |
| 2.25 s | White burst and shards. The pet appears in the same spot, big, facing the camera. |
| 2.25-3.75 s | The pet bobs, 3D confetti CUBES tumble, name + "1 in 10" under it. |
| ~4.0 s | The pet shrinks and flies to the player; the normal view returns. |

Why it feels 3D:
- The pet is a REAL 3D model right in front of the camera, not a 2D card.
- The world behind it is out of focus (depth of field), so it pops out of the screen.
- The confetti is real 3D cubes at different depths.
- It flies into the world at the end.

## Built in MEGA BITE (11 Nov): `MB_Reveal3D` (LocalScript)
The first time you eat a species (server Fx "IndexNew"), the real fish model pops up like the pet:
- DepthOfField: focus 10 studs, far 0.75 in 0.12 s, then restored.
- Pop-in 0.28 s back-out.
- 3/4 front pose, nose left, facing you; the same pose as the Index tiles.
- Bob and tail wag.
- A soft key light.
- 18 tumbling 3D cubes in white, rarity colour, gold, lime and pink.
- "NEW FISH!" chip, outlined name, and the rarity + EXP line in the rarity colour.
- Hold 1.55 s, then a 0.32 s fly into the INDEX button, which bumps.

Rules:
- Gameplay never stops: the fish follows the camera.
- A tap skips it.
- It waits while a window or the evolve cutscene is open, and it queues.
- It replaces the old "NEW FISH" toast (still used as a fallback).

Tried and dropped: a neon glow sphere behind the fish read as a flat, hard-edged disc. There is no sunburst anywhere (owner rule).

Tested in Play with Puffer, Tuna, Squid and Golden: no errors, and DOF returns to far 0.18 / focus 70 / radius 90. Shots: `mb_reveal3d_puffer.jpg`, `mb_reveal3d_golden.jpg`.

## Next (art style)
1. Pilot: the Minnow remade chibi-round in this style (ChatGPT sheet, then a bpy model with smooth shading). Shown beside the current one for the owner's OK before converting everything.
2. World grade toward the reference: brighter, cleaner, less haze, keeping the underwater feel.
3. The same 3D reveal for evolving and for buying a skin.

## Pilot built: the Minnow in the Tap style (11 Nov), files `MEGA BITE/Art/MinnowTap/`
Sheet: `mb_minnow_tapstyle_sheet_v1.png`, made in ChatGPT in one try. Prompt is in the chat "Create fish turnaround image", with the pets reference `tapreborn_style_ref_pets.png` and our old Minnow views attached.

**Model** (`mn_tap_gen.py` then `mn_tap_build.py`, local bpy):
- Body: a smooth superellipse loft, exponent 2.3. Heights come from the side view, widths from the top view ×1.06 (the top view is 11% narrower than the front view, so I split the difference).
- **Colours by rules** (projection alone gave jagged edges):
  - Yellow base.
  - Stripes taken from the side/top views (upper back only).
  - Cream below a belly line fitted to the side view (robust cubic).
  - A blush oval 49 px behind and 76 px below the eye.
- Glossy domed eyes seated on the surface, with a drawn navy rim, iris gradient, pupil and 2 catch-lights.
- The smile is a small dark tube on the face (from the front view).
- Pillow fins: thickness ∝ (distance to edge)^0.55, with smoothed edges.
- **Inverted-hull outline**: a dark shell 0.024 m out with flipped faces, like the reference pets' dark outline. It works because Roblox culls back faces; the MeshPart must have DoubleSided = false.

**Checks:**
- Side silhouette IoU 0.969.
- 12.4K triangles, of which half is the outline shell.
- Same length and rig as Minnow v1 (Root + Spine0..7, SEG 0.4023), so the existing clips play unchanged. Checked in Play: the tail swings, no errors.

**Assets:**
- Model 86446886337808 (v1b). v1 (82834005346881) was too long; not used.
- Skins on the new UV layout (`skins.py`): Coral 70478989020173, Lantern 71561318800352, Ghost 104274740125761, Ember 125524893217055 (GameConfig `SkinTex.Minnow`; old IDs in a comment).

**In Studio:**
- `Sharks.Minnow` is now the Tap Minnow.
- Old one at `ServerStorage.MB_Minnow_v1_backup_11Nov`.
- Clean copy at `ServerStorage.MinnowTap`.
- Not published.

**Owner decides:** keep this direction, then remake Piranha → Megalodon and the 8 food fish the same way (one sheet each).

## Owner feedback on the pilot (14:32): "looks too cartoony and toy", then (14:38) "the eyes should be cute"
v2b is now the game's Minnow: a less toy-like body, with cute eyes kept (`mn_tap_gen_v2b.py`).

**Toned down (body):**
- Body height ×0.88 and width ×0.70: a real fish is narrower than it is tall; the chibi bean was round.
- The rear 45% tapers to a tail stalk.
- Section exponent 2.05.
- Fine scale texture, with fewer scales on the face.
- Soft darker back (countershading).
- Stripes at 55% strength.
- No blush.
- A small mouth line.
- Thinner fins (about half the thickness).
- Outline 0.011 m: a fine edge, not a cartoon outline.

**Kept cute (eyes):**
- Eye size 54 px (the sheet was 62; a "natural" 42 px gold-eye try is kept as `ServerStorage.MinnowNatural_v2_goldeye`).
- Blue glossy iris, 2 catch-lights.
- The eyes look a little forward (16°).

Rule learned: **smooth + clean shapes, fish proportions, cute eyes; no toy chibi body, blush or thick outline.**

**Assets:**
- Model 110114214174139.
- Skins (keep scales and shading, `skins_v2.py`): Coral 127808637648152, Lantern 78169849724657, Ghost 71727769545270, Ember 101176833047095.

**In Studio:**
- Kept in ServerStorage: `MinnowTap` (toy pilot), `MinnowV2b` (clean copy), `MB_Minnow_v1_backup_11Nov` (original).
- Comparison shot: `MEGA BITE/Art/MinnowTap/minnow_old_toy_v2b_studio.jpg`.

## Rollout: FishKit (owner 14:41 "yes that is good")
The approved v2b look as one generic pipeline, in `MEGA BITE/Art/FishKit/`:
- `fishkit.py`: the generator; species config in `<Species>V2/cfg.py`.
- `fishbuild.py`: the build; the old rig numbers go in `rig.json`.
- `skins.py`: luminance gradient-map skins.

**Per species:**
1. A ChatGPT sheet, attaching `MinnowTap/style_ref_v2b.png` and the old model's views.
2. Fins separated by a colour rule.
3. Body colour = the sheet's own blurred gradient. Eyes, brows, teeth, fins and magenta edges are masked out and filled from the body.
4. Biters get a real mouth: separate upper-head and jaw lofts, a dark-red inside, and cone teeth on both lips (lower teeth on the Jaw bone). The snout ends in a rounded dome.
5. Brow ridges are tubes.
6. Swap in Studio: the old model is kept as `MB_<Species>_v1_backup_11Nov`, and the rig is placed so its Root bone sits where the old one did.

**Piranha v2 (done 15:20):**
- Model 109399594911343.
- Skins: Coral 108524953262338, Lantern 81313974463639, Ghost 77322719406215, Ember 129562469212580.
- Tested in Play: evolved to Piranha, swims, no errors; the jaw opens with the shared Bite clip.
- Shots: `PiranhaV2/piranha_v2_play.jpg`, `piranha_old_vs_v2.jpg`.

**Next:** Barracuda, Reef Shark, Hammerhead, Great White, Megalodon, then the 8 food fish.

**Barracuda v2 (done 15:35):**
- Model 80059521210664.
- Skins: Coral 138152118368865, Lantern 79746564609374, Ghost 104729399292912, Ember 74023479382787.
- Tested in Play (evolved to Evo 3), no errors.

Kit fixes found on the way:
- ChatGPT drew the top view only 0.685× as long, so the top view is now rescaled to the side's body length (`TSC`).
- Notches where fins and eyes were cut out of the top view are filled with a running max (`tw_fill`).
- The snout rounding applies only to the last 30% of the mouth (`round_from`).

The camera zoom fade is now solid → hidden (MB_Swim). A half-transparent body showed the edge-line shell as dark patches (owner 15:05).

## Sharks v2 (owner 15:27 "do all the next sharks"), done ~16:20, not published
| Shark | Model | Skins (Coral / Lantern / Ghost / Ember) |
|---|---|---|
| Reef Shark | 86922237373768 | 112105447021965 / 113069790986289 / 126316109624419 / 105878236602948 |
| Hammerhead | 81639818057520 | 139585389680009 / 133381305767328 / 109243132778225 / 93321672182910 |
| Great White | 114368305518705 | 124983034203413 / 138876359345675 / 87512430366280 / 84458250815120 |
| Megalodon **v3 (intimidating)** | 116472709130149 | 104316641683851 / 87026424625545 / 120532138831904 / 89537889465944 |

- Tested in Play by evolving all the way from Evo 1 to Evo 7: every shark appears and swims, no errors. Old models are kept as `ServerStorage.MB_<Shark>_v1_backup_11Nov`.

**Owner rule (15:55): "not all of them need to look cute, creatures like MEGALODON need to look intimidating".**
- Megalodon v3: small slit-pupil glowing eyes, no white, deep under a heavy brow; claw scars; a blunt heavy snout; 10/9 big jagged teeth.
- The cute Megalodon v2 (78885165429768) was NOT installed.
- Kit `eye_style='slit'`.
- Rule: small fish = cute; the top predators get fiercer the higher they are; the Megalodon is the boss.

**Kit additions:**
- `env_px` body envelope (shark fins share the body colour, so fins can't be split by colour).
- `env_top`/`env_bot` x-ranges.
- `tw_min_ranges` / `tw_scale_ranges` for top-view widths (hammer T head).
- `pect_comp_boxes`, `pect_hinge_flank`.
- `ignore_circles` (the drawn eye).
- `root_x`.

**Studio:** `ServerStorage.MB_InstallV2(key, assetId)` installs a model:
- InsertService load, Spine0-aligned.
- The Root bone is moved back to the old rotation pivot.
- PivotOffset is copied, so the model pivot matches the old one.
- insert_asset fails on these FBX packages ("Request Failed"); InsertService:LoadAsset works.

Rollout left: the 8 food fish.

## Sharp textures (owner 11 Nov: "textures look blurry, especially megalodon and from barracuda up")
- Fix in fishkit.py: body + jaw UVs mirrored (both flanks share pixels → 2x texel density), final blur removed, unsharp mask added (sharp_blur 0.7). Files: `MEGA BITE/Art/SharksSharp/`.
- Installed with MB_InstallV2 (backups kept), SkinTex updated (old lines kept as `-- sharp-before:` comments). Play-tested to Evo 7, no script errors.

| Species | Model | Lantern | Ghost | Ember | Coral |
|---|---|---|---|---|---|
| Piranha | 130342042936464 | 91739722346980 | 87270287369201 | 95453464736916 | 113040201981391 |
| Barracuda | 109968206920557 | 137450088715562 | 105867995784876 | 79989824330815 | 105314320070511 |
| ReefShark | 118782808835627 | 136367702567594 | 77479200540716 | 115025437382178 | 84888553014249 |
| Hammerhead | 110861423549787 | 139769450273606 | 95338145185965 | 130210474733554 | 138050033872366 |
| GreatWhite | 112561172691159 | 87447371328428 | 80784511961410 | 74387595894120 | 131617651729326 |
| Megalodon | 119297746113537 | 128715567311084 | 104740693384068 | 76396169767559 | 72968343701903 |

## 17:09 Owner decision: "i think the old style was better" → old models for all sharks
- (Owner also said at 17:07: "the megalodon front the top view is bad". The Tap-style mega had a narrow, pointed snout from the top because `tw_mode='min'` eroded the head width. A fixed v4 with a blunt, round head and a bridged pectoral width (`tw_interp_ranges`, `tex_seams` inpaint) was built in `Art/MegalodonV4`, but not installed.)
- Restored: Piranha, Barracuda, ReefShark, Hammerhead, GreatWhite and Megalodon back to the `MB_<Key>_v1_backup_11Nov` models plus their v1 SkinTex IDs. The Tap-style sharp models were moved to `ServerStorage.MB_<Key>_tapstyle_backup_11Nov`, and their SkinTex lines were kept as `-- tapstyle-sharp` comments.
- Minnow: still the v2b Tap pilot, which the owner approved earlier. Revert it with `MB_Minnow_v1_backup_11Nov`; its v1 skins are in the comments.
- Play-tested up to Evo 7 with no errors.
- LESSON: the owner prefers the original low-poly, flat-shaded Fisch-like shark models over the Tap REBORN puffy, rounded, cute style for sharks. Don't restyle the shark line again without a side-by-side check in game first.
