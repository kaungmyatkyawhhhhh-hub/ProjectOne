# Blender workflow for high-quality stylised shark/fish models driven by Python code (2026)

Research note for MEGA BITE (Roblox shark game). Written 9 Nov 2026.

Read this first: the Blender manual and API pages (docs.blender.org) could not be read in this session. The proxy refused the domain for curl, and WebFetch got back only the navigation bar. Wherever a finding cites a docs.blender.org URL and is marked **[docs, from prior knowledge]**, the URL is the correct reference page, but the details come from my own knowledge of Blender 4.x and were not re-read from that page here. Check the exact parameter names against the installed Blender build with `help(bpy.ops.object.bake)` or similar before relying on them. Every other citation was read in this session.

---

## 1. Which steps of the pro pipeline can code do?

### Takeaway
A pro stylised creature goes through these steps: reference, blockout, sculpt (secondary forms), retopology, UV, bake (normal, AO, curvature), a painted grayscale value pass with an AO shadow base and gradient colour, then rig. Every step except freehand sculpting maps onto a bpy operation. The sculpt step can be replaced by signed displacement driven by masks, plus Geometry Nodes or bmesh offsets along designed curves, applied to a dense copy that is then baked onto a clean low poly. The current method looks "inflated" because it has only the primary form. Loft + subdivision with no secondary forms (plane changes, muscle masses, creases) and no baked detail always reads as a balloon.

### Cited Findings
- Pro stylised shark workflow (80.lv breakdown of an anthropomorphic shark): gather references and set scale with a ruler, then define materials **before** detailing the high poly. Sculpt the organic forms while following the concept's line flow. Retopo and UV come next (split by material for texel density), then bake in Marmoset as the base for hand painting. Texturing builds **a grayscale value pass first, then shadows, using AO as the starting point**, and a **gradient filter adjusts hue, saturation and lightness non-destructively**. — [80.lv: Making Stylized Anthropomorphic Shark Adventurer](https://80.lv/articles/making-stylized-anthropomorphic-shark-adventurer)
- The same article says the tail's role in swimming should inform the design and that silhouette and line flow matter most. It does not cover fins, gills or teeth. — [80.lv](https://80.lv/articles/making-stylized-anthropomorphic-shark-adventurer)
- General stylised workflows from blockout to render follow the same order: blockout, sculpt, retopo, UV, bake, texture. — [80.lv: 001agt stylized character workflow](https://80.lv/articles/001agt-stylized-character-art-workflow-from-blockout-to-render); [Gnomon: modeling a stylized character for games](https://hs.thegnomonworkshop.com/blog/modeling-a-stylized-character-for-games)
- Infinigen (Princeton, an open-source procedural generator built on Blender) builds creatures from a **genome tree**. Nodes hold part parameters and edges say how parts attach. Each part is a node graph or a **NURBS surface lofted as deviations from a centre curve**, and the authors **tuned the distributions by hand-modelling about 30 example heads and bodies**. It ships five creature genome generators, **fish** among them, and produces rigs. Optional cloth simulation adds skin folding and sagging. — [Infinigen paper (arXiv 2306.09310)](https://ar5iv.labs.arxiv.org/html/2306.09310)
- Infinigen code is BSD-3-Clause, which allows commercial use with attribution (keep the copyright notice). — [Infinigen GitHub](https://github.com/princeton-vl/infinigen); the LICENSE file read in this session says "BSD 3-Clause License, Copyright (c) 2023, Princeton University"
- Blender operations that code can run (**[docs, from prior knowledge]**):
  - **Voxel remesh.** `mesh.remesh_voxel_size` + `bpy.ops.object.voxel_remesh()`, or the Remesh modifier in Voxel mode, fuses joined primitives (body + fins + eye sockets) into one watertight surface with no internal faces. — [Remesh modifier](https://docs.blender.org/manual/en/latest/modeling/modifiers/generate/remesh.html)
  - **QuadriFlow.** `bpy.ops.object.quadriflow_remesh(target_faces=...)` does automatic quad retopology to a target face count. — [Object operators API](https://docs.blender.org/api/current/bpy.ops.object.html)
  - **Decimate modifier** (Collapse ratio, or Planar). — [Decimate](https://docs.blender.org/manual/en/latest/modeling/modifiers/generate/decimate.html)
  - **Shrinkwrap modifier.** Modes Nearest Surface Point, Project and Target Normal Project, with an optional vertex group to limit it. Snaps a clean low poly onto the dense high poly. — [Shrinkwrap](https://docs.blender.org/manual/en/latest/modeling/modifiers/deform/shrinkwrap.html)
  - **Displace modifier.** Takes a texture (image or procedural) along the normal or a custom direction, limited by a vertex group, with a midlevel and strength. — [Displace](https://docs.blender.org/manual/en/latest/modeling/modifiers/deform/displace.html)
  - **Multiresolution modifier** (Subdivide, Unsubdivide, Rebuild Subdivisions, Apply Base). Its levels can be set from code and sculpt detail is stored per level. — [Multiresolution](https://docs.blender.org/manual/en/latest/modeling/modifiers/generate/multiresolution.html)
  - **Lattice, Simple Deform and Curve modifiers** for global shaping and for bending a straight body along a curve. — [Lattice](https://docs.blender.org/manual/en/latest/modeling/modifiers/deform/lattice.html)
  - **Skin modifier.** Turns a vertex/edge skeleton with per-vertex radii into a quad body with a branching skeleton, and can create an armature. — [Skin modifier](https://docs.blender.org/manual/en/latest/modeling/modifiers/generate/skin.html)
  - **Metaballs** and the **Geometry Nodes "Points to Volume / Volume to Mesh"** route make blobby unions that can be remeshed. — [Volume to Mesh node](https://docs.blender.org/manual/en/latest/modeling/geometry_nodes/volume/operations/volume_to_mesh.html)
  - **Subdivision Surface with edge creases.** In Blender 4.x creases are stored as the float attribute `crease_edge`, and bevel weights as `bevel_weight_edge`. — [Subdivision Surface](https://docs.blender.org/manual/en/latest/modeling/modifiers/generate/subdivision_surface.html)
  - **Bevel modifier** limited by weight or angle. — [Bevel modifier](https://docs.blender.org/manual/en/latest/modeling/modifiers/generate/bevel.html)
- Sculpt brushes can technically be driven from Python by passing a synthetic `stroke` list to `bpy.ops.sculpt.brush_stroke`, but this needs a correct context override and is fragile. **[inference, not verified this session]**

### Inferences
- **Recommended code-only pipeline** (my synthesis of the sources above):
  1. **Reference lock.** Load front, side and top reference silhouettes (see section 5). Measure key ratios: snout length / total length, head depth, dorsal fin height and sweep angle, caudal fin height (heterocercal: upper lobe about 1.3–1.6x the lower), pectoral span.
  2. **Primary blockout.** Keep the existing superellipse loft, but drive it from 3–5 **profile curves** (top, bottom and side outlines traced from the reference) instead of a few parameters. Superellipse exponents should vary along the length: flatter belly (exponent about 2.5–3 at the bottom), sharper back, an almost triangular snout, and a laterally flattened caudal peduncle with keels.
  3. **Assemble parts.** Body, fins (see section 2), eye-socket cutters, gill-slit cutters and mouth cavity, joined with Boolean (Exact) or Voxel Remesh (voxel ≈ 0.5–1% of body length). This gives one fused surface with fillets where fins meet the body, which a flat fin stuck onto a body never has.
  4. **Secondary forms on the dense mesh** (the sculpt replacement): signed offsets along the normal from analytic masks computed per vertex in bmesh or Geometry Nodes, such as distance to a curve, gradient along the body axis, and noise. Examples: a brow ridge over the eye, a cheek/jaw mass bulge, a gill-region recess, a lateral line groove, a raised dorsal ridge into the fin, muscle bulges at the pectoral root, and a belly plane change (a hard-ish edge where the flat belly meets the flank). Then smooth (Corrective Smooth or `bmesh.ops.smooth_vert`) to blend. **Stylised = big clear planes + a few sharp transitions.** That is the missing ingredient.
  5. **Tertiary detail** (optional, mostly baked): gill slit inner lips, nostrils, a faint skin-noise displacement, fin rays.
  6. **Low poly.** Either (a) keep a hand-authored low-poly cage, generated parametrically with known edge loops (best for rig control), and Shrinkwrap it onto the high poly, or (b) QuadriFlow then Decimate. Option (a) is better for animation topology (section 6).
  7. **UV.** Smart UV Project, or seams marked by code (along the belly midline and fin edges) with `bpy.ops.uv.unwrap`, then `uv.pack_islands`.
  8. **Bake** high to low (normal, AO, curvature; section 3).
  9. **Texture composite** in numpy (section 3), then export albedo, normal and roughness.
  10. **Rig** (section 6), then the **automatic quality gate** (section 7).

### Gaps
- Infinigen's fish-generator source files (folder layout, how fins are built) could not be opened. GitHub API and HTML access to that repo were blocked in this session, and guessed raw paths returned 404. Appendix G.6 of the paper describes the fish generator but was past the fetched part of the page.
- No public step-by-step tutorial was found for a fully code-driven stylised creature. All pro workflows found use manual sculpting.

---

## 2. Modelling fins, gills, mouth/teeth, eye sockets and keels with code

### Takeaway
Fins must be **wedge-shaped in cross-section**: thick at the root, which blends into the body with a fillet, and tapering to a sharp, nearly zero-thickness trailing edge. They should be **cambered and swept**, never a flat extruded outline with uniform Solidify. Gills, eye sockets and the mouth are best made as subtractive forms (cutters or negative displacement), followed by a remesh or smooth so they read as carved into the skin.

### Cited Findings
- The pro article gives no specific technique for fins, gills or teeth. — [80.lv](https://80.lv/articles/making-stylized-anthropomorphic-shark-adventurer)
- Tools available for these features (**[docs, from prior knowledge]**):
  - **Solidify** has thickness, offset and a *vertex-group thickness factor*. Zero weight on the trailing edge gives a tapering fin. — [Solidify](https://docs.blender.org/manual/en/latest/modeling/modifiers/generate/solidify.html)
  - **Subdivision creases** keep trailing edges crisp. — [Subdivision Surface](https://docs.blender.org/manual/en/latest/modeling/modifiers/generate/subdivision_surface.html)
  - The **Boolean modifier (Exact solver)** can carve gill slits and mouth cavities. — [Boolean](https://docs.blender.org/manual/en/latest/modeling/modifiers/generate/booleans.html)
- Blender Studio has an official anglerfish training course (a stylised fish character). It is a reference for how pros handle fish mouths and teeth. — [Blender Studio: Anglerfish training](https://studio.blender.org/training/anglerfish/5d78e8401a019fdce379bdbd)
- A tutorial article on fin topology exists, but it comes from an AI-mesh company blog and is a low-authority source. — [Tripo3D blog: fish fins topology](https://www.tripo3d.ai/blog/explore/smart-mesh-topology-for-fish-fins-and-scales-simplified)

### Inferences (concrete code recipes, my design)
- **Fin as a lofted aerofoil, not solidify:**
  1. Define the fin with three 2D curves in fin-local space: leading edge, trailing edge and root chord. A shark dorsal fin has a convex leading edge, a concave (falcate) trailing edge and a sharp tip.
  2. Build a grid in (u along the span, v along the chord).
  3. Thickness t(u, v) = t_root · (1 − u)^0.7 · NACA-like profile(v). For a symmetric profile, use the NACA 4-digit formula with a max thickness around 0.08–0.15 at the root, falling to about 0 at the tip.
  4. Add **camber** (a slight curve sideways), **sweep** (shift the tip backwards), and a **twist** for the pectorals.
  5. Weld the top and bottom shells at the trailing edge so it is a true single edge, and set `crease_edge = 1.0` on it.
  6. Root: sink the fin root 10–20% into the body and voxel-remesh, or use a Boolean union and smooth a band about 2 voxels wide, to get a **fillet**. This is the single biggest "pro" cue.
- **Caudal fin:** heterocercal. The upper lobe is longer and the vertebral column continues into it. Make the upper lobe a continuation of the body loft (the spine curves up), not a separate piece. Give it a notch near the upper tip (the subterminal notch) for a shark read.
- **Keels:** on the caudal peduncle, add a lateral ridge with a positive displacement mask in a narrow band at the side, combined with a sharper superellipse exponent locally.
- **Gill slits (5 for most sharks):** five thin, slightly curved cutters, angled forward at the top, positioned in front of the pectoral fin. Do a Boolean difference with a small depth, then add a raised rear lip (a positive displacement band just behind each cut) so each slit looks like an overlapping flap. Alternative for low poly: keep them only in the normal map and AO bake.
- **Eye socket:** subtract a slightly larger sphere, then insert the eye sphere so the lid rim overlaps it. Add a brow mass (a positive bump above and in front of the eye). For a stylised look, make eyes larger with a dark iris, a single specular highlight painted in albedo, and a subtle lid.
- **Mouth/jaw:**
  - Cut a mouth cavity (a closed volume) with an inner surface (gums, a dark gradient into the throat). The upper and lower jaw are separate edge-loop regions.
  - **Gum ridges:** a tube along a curve following the jaw line, made with a Curve object that has bevel depth, then converted to mesh.
  - **Teeth:** instanced along the same curve with Geometry Nodes (Curve to Points with Count, Instance on Points, Align to Curve Tangent, random scale 0.8–1.1, slight random tilt). Use 2–3 rows with smaller rows behind. Make teeth **flat triangular blades** (a serrated-edge silhouette, flattened cones), not round cones. Then Realize Instances and apply.
- **Countershading line and lateral planes** are partly geometry: a slight crease where the dark back meets the white belly helps the colour boundary read.

### Gaps
- No authoritative source was found on stylised shark fin topology or gill construction specific to games. The recipes above are my own engineering and should be tested visually.

---

## 3. Stylised textures generated by code

### Takeaway
The stylised hand-painted look is a stack of layers:

1. Flat base colours (countershading with an irregular, noise-broken edge)
2. Gradient along the body (darker back, lighter flank, warm belly)
3. AO multiplied in as painted shadow
4. Curvature: convex edges lightened, cavities darkened
5. A top-down "sun" gradient (world-space Z of the normal)
6. Small details (freckles, scars, fin-tip colour)
7. A final hue/saturation/value grade

All of these can be computed in Blender bakes plus numpy compositing. Roblox needs separate maps: Color, an OpenGL tangent-space Normal, Roughness, Metalness and an optional Emissive mask.

### Cited Findings
- The pro texturing order is a grayscale value pass, then AO as the shadow starting point, then a gradient filter for hue, saturation and lightness. — [80.lv shark](https://80.lv/articles/making-stylized-anthropomorphic-shark-adventurer)
- **Curvature in Blender via Pointiness:**
  1. Take the Geometry → Pointiness output (>0.5 is convex, <0.5 is concave).
  2. Subtract 0.5, multiply by 5–20, clamp.
  3. Convex = clamp(v·10), concave = clamp(−v·10).
  4. Bake by feeding an Emission shader with an unconnected, selected Image Texture node, using bake type **Emit**.
  - Caveat: patchy on low poly, and it ignores normal-map detail. — [StraySpark: curvature maps in Blender](https://www.strayspark.studio/blog/curvature-maps-blender-substance-painter-alternative)
- **Curvature via Geometry Nodes:** Edge Angle → Map Range (0–π to 0–1) → Store Named Attribute, with a dot product against face normals for the sign, then bake through Emit. It is blocky on low poly. — [StraySpark](https://www.strayspark.studio/blog/curvature-maps-blender-substance-painter-alternative)
- There are known issues with baked pointiness: the mask can disappear or leave artifacts in bakes. — [Blender issue #97641](https://projects.blender.org/blender/blender/issues/97641)
- Edge and occlusion "mesh maps" baked in Blender can stand in for Substance Painter's mesh maps for edge effects. — [BlenderNation: Baking bevel and occlusion maps](https://www.blendernation.com/2022/02/10/baking-bevel-and-occlusion-maps/)
- A paid add-on, CurvBake Pro, bakes high-quality curvature (GPU OptiX, C++). — [BlenderArtists release thread](https://blenderartists.org/t/release-curvbake-pro-high-quality-curvature-map-baker-gpu-optix-c/1649540)
- **Cycles baking from Python** (**[docs, from prior knowledge]**):
  - Call `bpy.ops.object.bake(type='NORMAL'|'AO'|'EMIT'|'DIFFUSE'|'ROUGHNESS'...)`.
  - High→low uses `use_selected_to_active=True` and `cage_extrusion` / `max_ray_distance` (or a cage object), with `normal_space='TANGENT'` and `margin`.
  - The target image is the **active Image Texture node** in each material of the low poly.
  - Settings live in `scene.render.bake` (BakeSettings).
  - Baking needs Cycles (`scene.render.engine='CYCLES'`). — [BakeSettings API](https://docs.blender.org/api/current/bpy.types.BakeSettings.html); [Cycles baking manual](https://docs.blender.org/manual/en/latest/render/cycles/baking.html)
- Example open scripts and tools for scripted baking exist, such as an MCP server's `baking.py` handler and a baking gist. Their licences were not checked. — [retopoflow_blender_mcp baking.py](https://glama.ai/mcp/servers/@ShirshovDIM/retopoflow_blender_mcp/blob/78358fedc1d6d47808d380d331e176370b479c59/src/blender_handlers/baking.py); [gist aobond2](https://gist.github.com/aobond2/6823ab471c22cc538ef813d03a3f38c8)
- **Roblox SurfaceAppearance:**
  - Five maps: Color (albedo), Normal, Roughness, Metalness and an Emissive mask.
  - **Only OpenGL-format tangent-space normal maps** are supported, and a flat normal is [127, 127, 255]. Blender's default bake output is OpenGL (+Y), which matches **[inference / docs prior knowledge]**.
  - Roughness and Metalness are separate grayscale maps, not channel-packed.
  - AlphaMode options are Overlay (default), Transparency, TintMask and Opaque (beta).
  - Properties can't be changed by scripts at runtime. — [Roblox: Surface appearance](https://create.roblox.com/docs/art/modeling/surface-appearance.md)
- **TintMask** applies `SurfaceAppearance.Color` where alpha is opaque. This is useful for player skins: one albedo, with tint per skin. — [Roblox: Surface appearance](https://create.roblox.com/docs/art/modeling/surface-appearance.md)

### Inferences (concrete code recipe)
1. **Bake from the high poly to the low poly at 1024²** (downscale to 512 later for mobile if needed):
   - NORMAL (tangent)
   - AO (Cycles AO bake, around 64–128 samples, distance about 10% of body length)
   - An EMIT bake of a "data" material carrying pointiness curvature
   - EMIT bakes of a **world-space normal Z** (top-light gradient) and an **object-space position** pass (for gradients along the body axis and the countershading mask)
2. **numpy composite** (read the images with `bpy.data.images[...].pixels.foreach_get`):
   - `mask_back = smoothstep(edge − w, edge + w, posZ_local + 0.04 · fbm_noise(pos))` gives countershading with an irregular, wavy edge.
   - `base = lerp(belly_col, back_col, mask_back)`, plus a gradient along X (darker toward the snout and tail, warmer gill area).
   - `base *= lerp(0.55, 1, AO)` tinted toward a cool shadow hue, not black.
   - `base += 0.15 · convex_curv`, a light edge highlight on the fin edges and the brow.
   - `base *= 1 − 0.25 · concave_curv`, which darkens gills, mouth corners and the eye socket.
   - `base = lerp(base, base · 1.15, saturate(nZ))` for top-light.
   - Freckles: a thresholded Voronoi/cellular noise in the back region only. Scars: a few UV-space line strokes.
   - Fin tips are darker (as on blacktip and oceanic whitetip sharks), driven by the fin-local span u stored as a vertex attribute before joining.
3. **Roughness:** about 0.45–0.6 on the body, lower (glossier) on the eyes, gums and teeth, raised slightly in cavities. **Metalness:** 0 everywhere. **Normal:** baked, plus optional fine skin noise (dermal-denticle "sandpaper") added with a low-strength Displace before the bake.
4. Keep the palette limited: 3–5 hues for the body plus one accent colour. Value contrast should carry the read at thumbnail size.

### Gaps
- The Roblox texture resolution limit could not be confirmed. The specifications page linked out to a separate texture-spec page that was not read.
- No source was found that tested Pointiness bakes in Blender 5.x specifically.

---

## 4. Existing scripts and add-ons for procedural fish/sharks (licences)

### Takeaway
The only commercially-safe, serious procedural creature/fish system found is **Infinigen** (BSD-3). It is heavy and aimed at photoreal computer-vision data, but its fish genome and NURBS-loft design are worth copying. The Superhive and Blender Market "fish" products are mostly swim-animation or crowd tools, not modelling tools, and their licences need checking.

### Cited Findings
- **Infinigen.** BSD-3-Clause and built on Blender. It has fish/carnivore/herbivore/bird/beetle genome generators, NURBS parts lofted from a centre curve, rigs, and export to OBJ/USD. — [GitHub](https://github.com/princeton-vl/infinigen); [paper](https://ar5iv.labs.arxiv.org/html/2306.09310); [CG Channel coverage](https://www.cgchannel.com/2023/07/infinigen-a-free-generator-for-procedural-3d-environments)
- **"Fish Generator"** on Superhive. A Geometry Nodes setup that "will automatically make fish swim in a circle", for Blender 3.1–4.2, at $7. It is listed under a Creative Commons licence without saying which variant. It is not a modelling generator. — [Superhive: Fish Generator](https://superhivemarket.com/products/fish-generator)
- **Procedural Fish Animator** (a Superhive/Blender Market add-on) is for animation. — [docs](https://superhivemarket.com/products/procedural-fish-animator/docs)
- **Geo Fish** (a Superhive add-on). — [docs](https://superhivemarket.com/products/geo-fish/docs/new)
- Gumroad procedural fish-motion setups. — [Tereschenko](https://tereschenko.gumroad.com/l/socgj); [bbbn19](https://bbbn19.gumroad.com/l/udlwo)
- A procedural goldfish animation in Blender (an 80.lv feature). — [80.lv](https://80.lv/articles/procedural-goldfish-animations-created-with-blender)
- **Procedural wings in Geometry Nodes** (80.lv). This is analogous to fin generation by curves and instancing. — [80.lv wings](https://80.lv/articles/generating-wings-procedurally-with-geometry-nodes-in-blender)
- A free "cute fish sculpt" project file on CGTrader could serve as a style reference. Its licence was not checked. — [CGTrader](https://www.cgtrader.com/free-3d-models/animal/fish/cute-fish-sculpt-free-project-files)

### Inferences
- Do not depend on the paid add-ons. Reimplement the useful ideas (genome-style parameter tree, NURBS or loft along a centre curve, Geometry Nodes instancing for teeth) in our own bpy code. Infinigen's code may be read and adapted under BSD-3 as long as the copyright notice is kept.

### Gaps
- Licence text for Geo Fish and the Procedural Fish Animator was not read.

---

## 5. Using reference images and fitting a mesh to a silhouette by code

### Takeaway
Load the side, top and front references as image empties or image planes. **Extract the silhouette outline in code** (threshold the alpha or the background, take the per-column top and bottom edges), turn it into profile curves, and drive the loft radii from those curves. Then render the model's silhouette from the same orthographic camera and compute IoU against the reference as a numeric fit score.

### Cited Findings
- A pro uses references and a ruler to set proportions before sculpting. — [80.lv shark](https://80.lv/articles/making-stylized-anthropomorphic-shark-adventurer)
- Blender references can be added as image empties (`bpy.data.objects.new(name, None)`, `empty_display_type='IMAGE'`, `.data = image`) or as image planes. In 4.2+ "Import Images as Planes" is built into core as File → Import. **[docs, from prior knowledge]** — [Image empties](https://docs.blender.org/manual/en/latest/modeling/empties.html); [Import Images as Planes](https://docs.blender.org/manual/en/latest/files/import_export/image_as_planes.html)

### Inferences
- **Silhouette fitting algorithm:**
  1. Load a side-view PNG with a clean background and threshold it to a mask.
  2. For each x-column, get top_y and bottom_y. Do the same for the top view to get half-width.
  3. Map these to body length, then smooth with a 1D Gaussian.
  4. Drive each loft ring: centre z = (top + bottom) / 2, half-height = (top − bottom) / 2, half-width from the top view.
  5. Fins: trace their outline contour from the side and top masks (for example with marching squares on the mask) and use it as the fin planform for the lofted aerofoil (section 2).
  6. Verification: render an orthographic silhouette from Workbench in flat mode with a black material on a white world, then compute IoU with the reference mask. Aim for > 0.92 on the side view.
- Because of copyright, references should be the team's own drawings or ChatGPT-generated concept turnarounds (the user's preferred art pipeline), not copied commercial game art.

### Gaps
- No published Blender script for silhouette-to-loft fitting was found. The algorithm above is my design.

---

## 6. Topology for animation and triangle budgets

### Takeaway
Use a parametric low-poly cage with **evenly spaced rings along the body**, denser where it bends (the peduncle and behind the head), plus concentric **loops around the mouth and eyes** and a split loop where the jaw hinges. The roughly 5–8K triangle budget is well within Roblox's 20K-per-mesh cap. Roblox allows at most 4 bone influences per vertex and needs frozen bones and a root at the origin with no influences.

### Cited Findings
- Roblox mesh specifications:
  - **20,000 triangles max per mesh**
  - Watertight, quads preferred, real volume (no zero-thickness surfaces)
  - **Max 4 bone/joint influences per vertex**
  - Bones frozen (scale 1, rotation 0)
  - **Root bone at 0,0,0 with no influences**
  - .fbx for animated meshes, with one animation track per export — [Roblox: Mesh specifications](https://create.roblox.com/docs/art/modeling/specifications)
- The Roblox "volume" requirement means fins **must have thickness**, which matches the wedge-fin approach. — [Roblox specs](https://create.roblox.com/docs/art/modeling/specifications)

### Inferences
- **Budget split for a player shark at about 6K triangles:**

  | Part | Triangles |
  |---|---|
  | Body | about 3,000 (28–36 rings × 40–48 verts per ring) |
  | Caudal fin | about 500 |
  | Dorsal + pectorals | about 700 |
  | Small fins (pelvic, anal, second dorsal) | about 300 |
  | Mouth interior + gums | about 600 |
  | Teeth | about 600 (simple 4–6-triangle blades, around 40–60 teeth) |
  | Eyes | about 300 |

  Gills and skin detail go in the normal map only.
- **Rig:** 5 spine bones is too few for a smooth S-curve swim. Use 8–10 chained spine/tail bones (shorter toward the tail), plus jaw, 2 pectoral and caudal-lobe bones. Weight by distance to the bone segment with a smooth falloff, normalise to ≤ 4 influences, and run `bpy.ops.object.vertex_group_limit_total(limit=4)` and `vertex_group_normalize_all`. Alternatively use the Automatic Weights `parent_set(type='ARMATURE_AUTO')` path and then clean up. Jaw weights should be 1.0 on the lower-jaw region with a 1–2-loop falloff at the hinge, and 0 on the upper teeth.
- Rings should follow the spine bones' joint positions so each joint has 2–3 rings nearby for clean bending.

### Gaps
- No authoritative source was found on recommended spine-bone counts for Roblox fish rigs.

---

## 7. Judging quality automatically

### Takeaway
Use a render-and-critique loop: fixed multi-view renders, silhouette IoU against the reference, mesh-health checks, and a short loop of critique iterations. Research on AI-driven Blender modelling finds that quality **plateaus or degrades after about 3 iterations** and that small, idempotent scripts with deterministic object names work best.

### Cited Findings
- The Planner–Actor–Critic framework for Blender through MCP:
  - The Critic reviews scene metadata plus viewport screenshots.
  - It beat a single agent mainly on proportions, fine adjustments and materials.
  - Lessons: break the work into small scripts, use deterministic object names and idempotent edits, never clear the scene, finish each step with a screenshot, and expect quality to plateau or degrade after about 3 iterations.
  - Primitive-based modelling limits expressiveness.
  - The evidence is qualitative and small-scale. — [arXiv 2601.05016](https://arxiv.org/html/2601.05016v1)
- A comparison of Blender MCP and headless bpy as control approaches. Not read in detail. — [sumguy.com](https://sumguy.com/blender-mcp-vs-headless-bpy/)

### Inferences (automatic quality gate; my design)
1. **Fixed turntable render set** in EEVEE: side, top, front, 3/4 front-high, 3/4 rear-low, a close-up of the head and mouth open, and **a 128 px thumbnail** (the Roblox read test). Use the same lights every time: a key light, a rim light and a flat studio HDRI.
2. **Silhouette IoU** against the reference masks for the side and top views (> 0.9).
3. **Flat-grey (matcap / Workbench) render** to judge form without the texture. If the shark still reads as a balloon in grey, the secondary forms are missing.
4. **Mesh-health script:**
   - Non-manifold count = 0
   - Triangle count within budget
   - No faces under an area epsilon
   - Normals consistent
   - Max influences ≤ 4 and weights summing to 1
   - UV overlap and texel-density variance
   - Fin trailing-edge thickness < 0.5% of body length (the crispness check)
   - Fin-root fillet present (measure the dihedral angle at the fin/body junction: it should be a smooth transition, not 90°)
5. **Pose test:** render the swim-bend extremes and jaw-open, and check for self-intersection with a BVH-tree overlap check.
6. **Critique checklist** for the vision model: silhouette clarity, primary/secondary/tertiary forms all present, a fin-edge crispness rating, a countershading edge that is irregular rather than straight, readable eyes, teeth as blades in rows, and no "inflated" look. Score 1–5 each, stop at 3 iterations, and keep the best version.
7. Optionally run the `quality-nerd-kid-sim` skill on the renders as an additional "does it look cheap / AI-made" judge.

### Gaps
- No published automatic metric for "stylised appeal" was found. Human or vision-model judgement plus the geometric checks above is the best available approach.
