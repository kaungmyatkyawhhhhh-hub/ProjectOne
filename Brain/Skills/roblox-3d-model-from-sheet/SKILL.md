---
name: "roblox-3d-model-from-sheet"
description: "Use when making a 3D model (shark, fish, creature, prop) for a Roblox game in the owner's Blender: ChatGPT design sheet first, then trace, check face landmarks and look, then export."
---

# Roblox 3D model from a design sheet

**OWNER RULE (9 Nov): ALL models must be HIGH QUALITY.** No placeholder or "good enough" model ever ships; a model is done only when every gate in step 4 passes, it looks Fisch-level from the game camera, it moves smoothly, it works in Studio, and the owner approves it. The full checklist is in the game's home note (MEGA BITE: "RULE: ALL models must be HIGH QUALITY").

The owner's rules: no Creator Store models, no AI model generators (Meshy, Tripo, Hyper3D, Hunyuan). Claude is the artist. ChatGPT is fine for 2D design sheets. Read first: vault `Brain\00 BRAIN.md`, the game's art notes (for MEGA BITE: `Shark art research`, `Art style guide`), and `Roblox Playbook\Research notes\MEGA BITE\2026-11-09 Research - Blender modelling skills for Claude.md`.

Toolkit: roble3/cc-blender-skill (MIT) is unpacked in the vault at `Tools\cc-blender-skill`, with the same files at github.com/roble3/cc-blender-skill. Read `plugin/skills/reference-to-3d/SKILL.md`, `landmark-fit-repair`, `reference-look-calibration` and `multiview-fit-loop` before the first model of a session. Their scripts (template_analyzer.py, silhouette_validator.py, landmark_fit_report.py, look_fit_report.py, multiview_fit_report.py) need Python with opencv, numpy, scipy and Pillow. In a cloud session, stage them from the vault or clone the repo.

**Modelling tools (vault: `Roblox Playbook\Research notes\MEGA BITE\2026-11-09 Research - Modelling tools for Claude (round 2)`)** - geometry and measuring tools only, never AI model generators:
- `pip install bpy` = full Blender in the cloud workspace. Build, render and compare LOCALLY (seconds per loop); only send the finished script to the owner's Blender.
- `pip install mitsuba` (variant `llvm_ad_rgb`, CPU) = differentiable rendering: optimise vertex positions/colours so renders match the sheet views (silhouette + RGB loss, Laplacian/edge/normal regularisers; see PyTorch3D's fit_textured_mesh tutorial).
- `pip install libigl` = ARAP/biharmonic deformation: move named landmark vertices (eye, lip, jaw) to their targets and the head bends smoothly.
- `trimesh` for mesh checks; Blender's UV Project / projection painting to put the sheet's exact colour regions on the mesh.
- Optional: the official Blender Lab MCP (searches the Blender API docs). The community "MCP for Blender" has Hyper3D/Hunyuan/Tripo generators: NEVER use them.

## 1. Design first (never invent shapes in code)
- In ChatGPT (owner's Chrome), make ONE one-try prompt for a **full turnaround sheet**: 1536x1024, flat MAGENTA #FF00FF background, orthographic; TOP ROW the side view (nose right); BOTTOM LEFT the top view, same length and directly under it; BOTTOM RIGHT the front view. Include the style (e.g. Fisch-like low-poly, flat shading, 2-4 flat colours) and every feature with its colour.
- Then a second **head close-up sheet**: side and front of the head only, big, the same style, so the face can be measured accurately. The head is where players judge quality.
- Download it via fetch(blob) and an `<a download>` link into the owner's Downloads. Copy it into the vault with the Blender Python (Downloads is not a connected folder), then stage it.

## 1b. Check the sheet is consistent BEFORE modelling
- Scale the side and front views to the same head height and draw horizontal guide lines (eye centre, top of mouth, lower jaw top, chin). If the front puts features at different heights than the side, NO 3D model can match both 1:1. Show the owner the guide-line image and ask which view wins (default: split the difference).
- ChatGPT ignores guide-line templates (tested 9 Nov), so regenerating the sheet doesn't fix a mismatch. Fix it in 3D instead.

## 2. Analyse (the sheet is the contract)
- Key the magenta with a border flood fill. Split the views into components. Measure in pixels: body top/bottom per column (side), half-width per column (top), the section shape (front). Get fins by subtracting the body from the silhouette, then cv2.approxPolyDP.
- Write a `reference_manifest.json` and a **landmarks JSON**: named points per view for eye centre, brow ends, mouth corner, upper lip line, lower lip line, each tooth tip, gill slit ends, fin tips, nose tip, tail tips.
- Sample the flat colours from the sheet (median per region) for the palette.

## 3. Build in Blender (by code, in its own scene "MEGA BITE" or the game's name)
- Body: loft cross-sections (12-vert faceted ring) from the measured side and top profiles, triangulated with alternating diagonals. A constant colour threshold in the band row gives a clean zig-zag countershade line.
- **Head as its own pieces:** upper head + brow, white lip band, lower jaw, a maroon mouth interior set inside the cheeks, and separate tooth rows (upper and lower). Never build the head as a squashed body section.
- Fins: faceted plates (thick root, thin edge, raised inner outline) from the traced outlines, with roots pushed into the body. Black tips use the distance to the named tip points.
- Decals only for flat markings (gill slits, stripes): project each vertex onto the surface by ray cast and subdivide edges, so they hug the curve.
- **Brow, eye socket and other face forms are CARVED into the head, never stuck-on slabs** (owner: they looked like separate parts). Subdivide the head around the eye, bisect it along the traced brow fold, crease and socket lines, push the brow band out (0 at the fold to max at the crease) and the groove in (deepest under the crease and at the back, so its floor faces forward), and colour the groove faces black on the un-carved positions.
- Eyes: a domed glowing lens SEATED in the groove, turned about 45 deg between side and front (widen it by 1/cos45 so the side size stays), so it reads from the side, the 3/4 view and the front. Measure the eye outline from the sheet's cyan pixels.
- Mouth: cheek walls that are visible through the gape are mouth-coloured on BOTH faces (a white face read as a slab). Teeth count and size from the sheet; the chin keeps a real thickness (no razor-thin jaw tip).
- Flat shading. Keep the scripts in the vault (`<Game>\Art\<Model>\`) and rebuild from the script, never hand-edit.

## 4. Check before showing the owner (hard gates)
- Render ortho side/top/front at the sheet's framing, then **paste the renders into the sheet layout on magenta** and compare side by side at the same size.
- Silhouette IoU ≥ 0.90 per view (do NOT stretch the render's bbox to the sheet's; keep the aspect). Render ortho at the sheet's EXACT pixel scale (account for different x/y scales in the head sheet) and score per colour region (white, black, maroon, cyan IoU) plus a mismatch map; check every change by these numbers, not by eye.
- Backface check: render with backfaces in magenta from 6 angles (Roblox draws one side only). Orient normals per island (ray parity), with a slice-by-slice rule for bevelled wings such as a hammerhead's cephalofoil and a convex rule for teeth and brows. Zero open edges (`MEGA BITE\Art\holes.py`). Set MeshPart.DoubleSided = true in Studio.
- **Fin attachment gate (owner, 10 Nov: "the side fins ... like levitating")**: every fin island must have vertices INSIDE the body, measured per fin with `MEGA BITE\Art\fincheck.py`. Sink the roots 15-25 px into the body; side fins start from the body's real width at that height (ray-cast), never a constant offset; side fins drawn ON the flank have their front third rooted in the body. Look from BELOW and the FRONT too, never only the side view.
- **Face landmarks checked separately** (landmark_fit_report.py): eye, brow, lip line, mouth corner and teeth within ~2% of the head length. A passing body outline does not mean the face is right.
- Look calibration last (look_fit_report.py): camera framing → background → base colours → glow → exposure. Never hide bad shapes with lighting.
- Crop the HEAD from both images side by side and look at it. If it doesn't read as the same character, fix it before showing anything.
- Then load into the owner's Blender (exec the vault script) and use `look` with angles.

## 4b. Techniques that passed owner review (MEGA BITE, all 7 evolutions approved 10 Nov 2026)
Reference generators to copy from: `MEGA BITE\Art\GreatWhite\greatwhite_v2.py` (sharks), `Art\Minnow\minnow_v3.py` (round fish, closed mouth), `Art\Piranha\piranha_v3.py` (underbite, two-tone back band), `Art\Barracuda\barracuda_v3.py` (long fish, stripes).
- Face markings, stripes and glow lines are TRACED from the sheet's pixels and ray-cast onto the body as thin decals (BVH needs `bm.normal_update()` first). Domed decals (eyes) get interior rings; long stripes are sliced every ~50 px so no flat chord cuts into the curved body; a mark that sits on the front (a smile) is projected from the FRONT view.
- Each colour band boundary (countershade, grey back band) gets its own ring row so the edge is clean; a jagged belly line is a clean synthetic zig-zag rather than the traced noise.
- The snout keeps one continuous section past the chin (no seam); end the nose with a small tapered station, not a flat cap.
- Clip modules: reuse the shared clips re-scaled by SEG and add only the model's ability clip (6 KB instead of 16 KB to paste into Studio).

## 5. Roblox export
- Triangles under 20K per mesh (aim 1-3K for a creature). One material: bake the colours into one 512 px texture. Up to 4 bone influences per vertex; the root bone at the origin. FBX with Add Leaf Bones off and embedded textures; import with the 3D Importer.
- Rig: 8 spine bones plus a Jaw bone, weights by position along the body, a Swim action (carangiform; thunniform for big sharks).

## 5b. Owner's device
- `device_commit_files` can report success but NOT overwrite an existing file. Write each version to a NEW file name (reef_shark_v6.py) and check the size in Blender before running it.

## 6. Save
Add to the vault the sheet PNGs, the prompts note, the build script, the analysis JSONs, the check renders, and a line in the game's home note.