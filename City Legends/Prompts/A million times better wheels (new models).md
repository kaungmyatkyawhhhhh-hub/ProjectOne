# Prompt: a million times better looking wheels on every newly imported car

_For Claude Code on the PC, with Blender (`C:/Users/USER/tools/blender-4.5.9-windows-x64`) and Roblox Studio connected (MCP). Read all of this first. Owner: talk short and simple (caveman mode, see `Preferences.md`). Don't add your own extras. Do it properly and with **no errors** (the owner's standing rule)._

## What the owner wants (2026-11-08)
"A million times better looking car wheels for all newly imported cars."

## Which cars
**Only the newly imported models** (`CarFinish.NEW`: the SVJ / SVJ 63, the Bugattis, the Lamborghinis, the new Ferraris, the LFAs, the Maybachs, the Countach, the Focus RS, and every car added by the import prompts, e.g. the 12C Spider, SLS, SL65, 599, DBX, Continental, 350Z, 330i when they're in). **Old models stay exactly as they are.**

If `Small design changes on famous new cars.md` has made **our own wheel library** (Furia 7, Saetta Y5, Corsa 10, Centro 6 CL...), build those designs to this standard; otherwise improve each car's own wheels (logos removed).

## Look at the cars first
Render every new car's four wheels close up (side, 3/4, low angle, day and night, still and spinning) and list what's wrong per car: flat or blurry rims, grey parts, no depth, missing brakes, cheap tyres, wrong size or position, logos, triangles showing. Fix the worst first.

## What "a million times better" means
### Rims
- **Real depth:** a concave face (the spokes curve in towards the hub, deeper on the rear wheels of supercars), spokes with real thickness and soft bevelled edges that catch the light, a visible **barrel** behind the spokes (darker, with a soft shadow inside).
- **Details:** **lug nuts / bolts** (or a **centre-lock nut** on cars that have one), a **centre cap** with our own small mark or blank (no maker logos), the **valve stem**, the fine machined ring on the lip.
- **Materials (PBR, `SurfaceAppearance`):** gloss black, satin black, gunmetal, silver paint, polished / machined faces, brushed aluminium, chrome, forged carbon: each with the right roughness and metalness so they reflect the sky and street lights properly. A polished **lip** where the design has one.
- **Ambient shading:** baked soft shadow (AO) in the barrel and between the spokes so they don't look flat.

### Tyres
- A real **tyre profile**: rounded shoulders, a slight sidewall bulge, the right sidewall height for the car (thin on supercars, taller on SUVs).
- **Sidewall:** matte black rubber with a faint texture and our own simple sidewall lettering style (size code like "275/35 R20" and a fictional tyre brand, or blank; **never real brands** like Pirelli or Michelin).
- **Tread:** a real tread pattern on the contact face (normal map), slightly lighter worn rubber where it touches the road.
- Rubber that is **dark and matte**, never shiny plastic or grey.

### Brakes (behind the spokes)
- **Discs:** drilled or slotted where the real car has them; **carbon-ceramic** grey discs on cars that have them; a darker hat in the middle; a slight blue / gold heat tint at the edge.
- **Calipers:** the right size and shape (6–10 piston on supercars), in the car's real caliper colour (yellow, red, black, grey...), with **no brand lettering**; Customs caliper colours if Customs has them.
- The hub and a dark backing plate, so you never see through to the sky.

### Fit and position
- Each wheel at the **right size, position, offset and stance**: filling the arch like the real car, centred in the arch, not sticking out or sunk in; right ride height; front / rear sizes different where the real car is staggered.
- **Steering** turns the front wheels on the right axis; the wheels **spin** at the right speed for the car's speed, the right way.
- A dark **wheel-arch liner** behind the wheel (no see-through arches).

### In motion
- At speed, the spokes get a **soft motion blur** (a blurred spinning disc that fades in, like real cameras), not a strobe / wagon-wheel effect.
- Brakes glowing faintly orange after very hard braking from high speed (subtle, short) if it looks good.
- The damage system's **curb rash** and **dirt** still show on the new rims (if those systems exist).

## Rules
- **Logos off** everywhere on the wheels, tyres and calipers.
- Shared meshes and textures per design (one rim mesh used on many cars), textures 512–1024 px, LODs (simpler wheels for far-away and traffic cars), so **FPS doesn't drop**.
- Nothing lost: every car keeps its other parts; before / after part lists.
- **No errors:** no floating, wobbling or clipping wheels, no gaps between rim and tyre, no z-fighting, no flipped faces, no grey parts, no console errors.
- Back up each car's current model (dated, in `ServerStorage`) before replacing its wheels, so it can be reverted.
- Import the new packs yourself (permission given); if you truly can't, leave them ready and write the steps at the top of the notes.

## Check before you say done
- **One picture per car:** before / after of a wheel close up (side and 3/4), day and night.
- In Play, per car: driving, steering, braking, at speed (motion blur), parked; PC and phone size; another player sees the same.
- FPS at the 3 usual spots with lots of traffic: not worse.
- Lune tests and `luau-lsp analyze` clean; no errors. Save the place, commit, push; note it in `City Legends/City Legends.md`.

## When done, tell the owner (short)
- the before / after wheel pictures;
- any car that still needs work and why.
