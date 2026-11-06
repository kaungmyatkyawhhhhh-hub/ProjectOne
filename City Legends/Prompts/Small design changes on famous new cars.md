# Prompt: very small design changes on the famous new car models (vents, side details, lights)

_For Claude Code on the PC, with Blender (`C:/Users/USER/tools/blender-4.5.9-windows-x64`) and Roblox Studio connected (MCP). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras._

## What the owner wants (2026-11-06)
"Make a very very small difference ... vents, side, basically very small details ... change the lights like very small detail, to the point players can't know until they zoom in." The car should look the same to players from normal view; the differences show only up close.

**Only the newly imported models** (owner rule): the Aventador SVJ / SVJ 63, the 6 Bugattis, the 9 Lamborghinis from `Lamborghini imports.md`, the cars from `New imports - Murcielago, Urus Performante, Ferraris.md`, and future imports. **Never touch older models.**

## Which cars (the famous ones first)
1. Enfurecido (Lamborghini): LB834 / ZV / ZVX / ZVX 63, LB744, LB724 / Aero Spyder / VTZ / Rally, L140 Leggera / Spyder, L147 Roadster / Veloce, Brava Sport.
2. Rosso Rampante (Ferrari): F142 Spider, F142 Speciale, F149 Riviera.
3. Velocité Noir (Bugatti): the 6 Bugattis.
Cars in the same family get the same changes (e.g. all LB724s match), so the brand stays consistent.

## The changes (small, up-close only)
Pick **4–6 per car** from this list. Keep the body shape, size and stance exactly the same.
- **Vents and intakes:** change the slat count (e.g. 5 slats → 4 or 6), the slat angle, or the mesh pattern (hex → diamond, diamond → horizontal bars); a small extra fin inside a side intake; round off or sharpen a vent's inner corner.
- **Side details:** the shape of the small side-skirt blade end, a fin on the rear-arch vent, the door-handle / door-cut-line shape, a slightly different mirror-cap edge or mirror arm.
- **Headlights:** change the **inner pattern** only: the shape of the daytime running light (e.g. a Y-shape becomes a split double line, a C-shape becomes three short bars), the number of projector lenses, a different inner housing pattern. The outer light shape stays.
- **Tail lights:** the inner light graphic (e.g. the number or shape of glowing lines, a different hexagon / bar layout), the lens texture. The outer shape stays.
- **Small parts:** exhaust tip shape (round ↔ hexagon ↔ oval, or a different count inside the same area), diffuser fin count, the fuel-cap shape, wing end-plate cut, wheel centre cap (our own simple design), brake caliper shape lettering removed.
- **Badge spots:** where a real badge was, leave clean paint or our own small mark (never the real one).

## Rules
- **Backup first:** keep the original `.glb` and the current packed model; work on copies.
- **Nothing lost:** every other part, texture, PBR map, cluster, interior, door, wheel and light function stays. Before / after part lists match (only the changed parts differ).
- **No visible change from normal view:** check with a render at the game's normal chase-camera distance: before and after must look the same. The differences show only in close-up renders.
- Lights still glow and work (headlights, tail lights, brake lights, indicators); new light parts keep the right material and glow.
- Clean geometry: no holes, gaps, z-fighting or stretched textures; stay inside the triangle budget.
- Then the normal routine: `render_car.py` → `pack_cars.py`, pack for Import 3D in `imports/new_cars/`, and tell the owner when to import. After import, check in Play.

## Check before you say done
- Per car: one picture with **before / after at normal distance** (should look the same) and **before / after close-ups** of each changed spot (front light, tail light, the vents, the side).
- In Play: lights work day and night, Customs paint works, no errors; FPS not worse.
- Commit, push, save the place; note in `City Legends/City Legends.md` what changed on each car.

## When done, tell the owner (short)
- the before / after pictures;
- the list of what changed per car;
- when to import the packs.
