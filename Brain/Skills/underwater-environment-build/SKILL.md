---
name: underwater-environment-build
description: Use when building, decorating, lighting or fixing an underwater (or any natural) Roblox environment, e.g. MEGA BITE seas, reefs, biomes, landmarks: hand-placed heroes, slope-painted terrain, seeded scatter, caustic/dapple light plates, god rays, haze.
---

# Underwater environment build (Roblox)

This skill was built from two videos watched frame by frame on 23 Nov 2026. The research note in the vault has the full step-by-step breakdown with timestamps: `Roblox Playbook/2026-11-23 Research - Underwater environment videos (DatBoiEle Roblox + Lunar9 UE5).md`.
- **V1:** DatBoiEle, "How To make a Realistic Underwater Build" (Roblox Studio, kvEf3pzKOqQ). Music only; every value below was read off his Properties panels.
- **V2:** Lunar9, "Underwater Environment & Landscape" (Unreal Engine 5, HECwGXgGu50). Landscape layers, tiling, PCG scatter, depth mood.

**Demonstrated vs. mine:** the values and steps tagged V1/V2 were shown in the videos. **All Luau code here is Claude's own**, written to reproduce those techniques in Roblox. Neither video showed any code.

**Owner rules that override the videos:**
- Lighting is **never dark**. V1's dark sand and V2's "deeper = darker" turn into contrast and denser haze, never black.
- Models are our own and HIGH QUALITY, made with roblox-3d-model-from-sheet. No Toolbox or Creator Store assets.
- Keep triangle counts low.
- Mobile UI must clear the joystick and jump button.
- For lighting numbers in general, also read **roblox-game-lighting**. This skill covers the environment build and its underwater light tricks.

## 1. Why the V1 look works (keep this order of impact)
1. A **photographic underwater Sky** does the far background.
2. **Atmosphere**: Density 0.7, Offset 0, Color [57,157,162], Decay [64,106,115], Glare 0.8, Haze 2.15. Distance turns into blue-green, and only silhouettes survive.
3. **ColorCorrection**: Brightness 0.05, Contrast 0.5, Saturation 0.5. Tint starts white and is nudged greener at the end.
4. **Projected light layers.** A **dark dapple plate** ("custom shadow") and a **bright cyan caustic plate**, each tiled over the build just above the surface, so light patterns land on everything.
5. **God-ray beam parts** scattered at random, plus **Bloom** (Intensity 1, Size 60, Threshold 2), so only the brightest things glow.
6. **Dark seabed**: Sand MaterialColor [52,48,32], so lit things pop. For MEGA BITE use a mid tone, not this dark.
7. **Small seaweed scatter** in the gaps: Brushtool with Radius 1, Spacing 2, Rotation random −360..360, Scale random ×1–2, Orientation Normal.

The rest of the V1 Lighting panel: Ambient [57,122,162], Brightness 3.5, ColorShift 0/0, EnvDiffuse 1, EnvSpecular 1, GlobalShadows on, OutdoorAmbient [70,70,70], ShadowSoftness 0.2, Technology Future, ClockTime 14.5, ExposureCompensation 0, Fog off (FogEnd 100000). Atmosphere does the fog.

**V1 build trick:** move Atmosphere into ServerStorage while placing things, so you can see, then move it back into Lighting to judge. In code, set `Atmosphere.Parent` the same way.

## 2. What V2 adds
- **Terrain:** sculpt the big forms (small brush, low strength), then **smooth**.
- **Seabed material blend:** 3 layers (sand, rock A, rock B). Rock goes on the slopes, sand in the flats, and the edges are smoothed so they blend. Roughness 1.
- **Hide tiling** with texture scale. He tried 30, then 100 ("too giant"), and settled on 50. Bigger = less repetition but blurrier.
- **Deeper = darker and foggier.** For us: deeper = denser, more saturated haze, with a brightness floor.
- **Hand-place the landscape and biomes. Only spawn the small clutter and the interactables** (in his reference game, only ores and creatures are spawned).
- **Bake scale** into a prop instead of scaling every copy. In Roblox, set the master's scale with `Model:ScaleTo` once.
- **PCG for small clutter only, never for caves or big forms** ("it's not going to look good").
- His PCG chain: **Surface Sampler** (points per area, point extents = spacing, looseness, seed) → **Transform Points** (random rotation, scale min/max, offset) → **Static Mesh Spawner** (several meshes, random pick).
- Extents 2000 = sparse, 200 = a visible grid, 250 = his pick. In Roblox, use min-spacing plus jitter so it never reads as a grid.
- **Use references:** search real and game references per biome before building (he used Subnautica).

## 3. Workflow (do it in this order)
1. **Read the vault first:** the game's map and biome notes (MEGA BITE: World v2, Titan Sea, Bigger sea plan), roblox-game-lighting, and this skill.
2. **Reference board** per biome: palette, hero shape, mood. Save it to the vault.
3. **Plan the space:**
   - One **hero landmark** per biome, tall enough to read through the haze from the next area.
   - **Clusters** (dense, 3+ kit pieces mixed) around the heroes.
   - **Breathers** (open sand) between clusters.
   - Guide lines (ridges, beams, currents) that point at the heroes.
   - A budget per biome (MEGA BITE: about 900 mesh parts, about 7K triangles per landmark).
4. **Light before building:** run `apply_underwater_v1` (section 5A), or the game's own preset. Then set Atmosphere aside while placing.
5. **Terrain:** big forms → smooth → materials by slope and height (section 5D) → seabed MaterialColor in a mid tone.
6. **Heroes by hand**, built with roblox-3d-model-from-sheet.
7. **Clusters by hand**, or with the seeded cluster dresser (MEGA BITE: MB_WorldDress / MB_TitanDress).
8. **Small scatter** in the cluster seams and along the cluster edges (section 5B). Seeded, so it can be re-run.
9. **Light layers:** dapple plates, caustic plates, beams, then bloom (section 5C).
10. **Grade:** nudge the whole scene one hue (V1 went greener). Check the never-dark floor.
11. **Optimise and check:**
    - Scatter flags, streaming and culling.
    - Screenshots from player height in every biome, then the **quality-nerd-kid-sim**.
    - For the first minutes, the impatient-kid-sim.
    - A phone test.

## 4. Composition rules (the why)
- **Silhouette beats detail through haze.** Far things are flat shapes, so heroes need simple, recognisable outlines (an arch, a statue head, a lighthouse).
- **Clusters, not carpets.** Even coverage reads as fake and random. Group 3–7 pieces of mixed size (one big, two medium, small fill), then leave open sand.
- **Odd variety:** at least 3 meshes per scatter, random yaw, scale ×0.8–2, a slight tilt to the slope, and a sink of 5–15% into the ground so nothing floats.
- **Density follows interest:** dense at the heroes and the cluster edges, sparse in the open, none on paths you want players to swim along.
- **One hue family per biome** (cyan → teal → deep blue) with warm accents used sparingly (coral, sand, a lamp).
- **Light patterns are what make it read as "underwater":** caustics, dapple and shafts. Without them it reads as a foggy field.
- **Repetition tells:** the same mesh at the same scale and angle, terrain tiling, evenly spaced props, flat empty ground. Break each one up.

## 5. Scripts (Claude's own; run in the Studio command bar or as a ServerStorage ModuleScript; vault copies in `scripts/`)

### A. apply_underwater_v1 (V1's exact look, with a backup first)
```lua
local L = game:GetService("Lighting")
local bk = game.ServerStorage:FindFirstChild("LightingBackup_preUnderwaterV1")
if not bk then
	bk = Instance.new("Folder"); bk.Name = "LightingBackup_preUnderwaterV1"
	for _, c in L:GetChildren() do c:Clone().Parent = bk end
	for _, p in {"Ambient","Brightness","OutdoorAmbient","ShadowSoftness","ClockTime","ExposureCompensation","FogEnd","GlobalShadows"} do
		bk:SetAttribute(p, L[p])
	end
	bk.Parent = game.ServerStorage
end
local function get(class)
	local o = L:FindFirstChildOfClass(class) or Instance.new(class)
	o.Parent = L
	return o
end
L.Ambient = Color3.fromRGB(57,122,162); L.Brightness = 3.5
L.ColorShift_Bottom = Color3.new(); L.ColorShift_Top = Color3.new()
L.EnvironmentDiffuseScale = 1; L.EnvironmentSpecularScale = 1
L.GlobalShadows = true; L.OutdoorAmbient = Color3.fromRGB(70,70,70)
L.ShadowSoftness = 0.2; L.ClockTime = 14.5; L.ExposureCompensation = 0
L.FogEnd = 100000
pcall(function() L.Technology = Enum.Technology.Future end) -- may not be script-writable
local a = get("Atmosphere"); a.Density = 0.7; a.Offset = 0
a.Color = Color3.fromRGB(57,157,162); a.Decay = Color3.fromRGB(64,106,115); a.Glare = 0.8; a.Haze = 2.15
local cc = get("ColorCorrectionEffect"); cc.Brightness = 0.05; cc.Contrast = 0.5; cc.Saturation = 0.5
cc.TintColor = Color3.fromRGB(235,255,250) -- V1 pushed it greener; this is a mild version
local b = get("BloomEffect"); b.Intensity = 1; b.Size = 60; b.Threshold = 2
workspace.Terrain:SetMaterialColor(Enum.Material.Sand, Color3.fromRGB(52,48,32)) -- V1 value; MEGA BITE: use a lighter mid tone
-- Sky: V1 used a Toolbox "Underwater Sky". For our games, make our own skybox (6 faces) and put it in a Sky object.
```
To restore: delete Lighting's effects, move the backup's children back, then apply its attributes.

### B. scatter (V2 PCG chain in Luau: sample → filter → spacing → transform → spawn)
```lua
-- opts = {name, seed, center=Vector3, size=Vector2 (X,Z), count, spacing, models={Model...},
--         scaleMin, scaleMax, maxSlopeDeg, tilt=0..1, sink, top, depth, parent, avoid={Vector3...}, avoidR}
return function(opts)
	local rng = Random.new(opts.seed)
	local old = (opts.parent or workspace):FindFirstChild(opts.name); if old then old:Destroy() end
	local folder = Instance.new("Folder"); folder.Name = opts.name
	local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Exclude
	rp.FilterDescendantsInstances = {folder}; rp.IgnoreWater = true
	local cell, grid, placed = opts.spacing, {}, 0
	local minUp = math.cos(math.rad(opts.maxSlopeDeg or 35))
	local function near(x, z)
		local cx, cz = math.floor(x / cell), math.floor(z / cell)
		for dx = -1, 1 do for dz = -1, 1 do
			local p = grid[(cx + dx) .. "," .. (cz + dz)]
			if p and (p - Vector2.new(x, z)).Magnitude < cell then return true end
		end end
		for _, v in opts.avoid or {} do
			if (Vector2.new(v.X, v.Z) - Vector2.new(x, z)).Magnitude < (opts.avoidR or 0) then return true end
		end
		return false
	end
	for _ = 1, opts.count * 6 do
		if placed >= opts.count then break end
		local x = opts.center.X + (rng:NextNumber() - 0.5) * opts.size.X
		local z = opts.center.Z + (rng:NextNumber() - 0.5) * opts.size.Y
		if not near(x, z) then
			local hit = workspace:Raycast(Vector3.new(x, opts.top, z), Vector3.new(0, -opts.depth, 0), rp)
			if hit and hit.Normal.Y >= minUp then
				local m = opts.models[rng:NextInteger(1, #opts.models)]:Clone()
				m:ScaleTo(m:GetScale() * rng:NextNumber(opts.scaleMin, opts.scaleMax))
				local up = Vector3.yAxis:Lerp(hit.Normal, opts.tilt or 0.6).Unit
				local axis = Vector3.yAxis:Cross(up)
				local tilt = axis.Magnitude > 1e-4 and CFrame.fromAxisAngle(axis.Unit, math.acos(math.clamp(up.Y, -1, 1))) or CFrame.identity
				local h = m:GetExtentsSize().Y
				m:PivotTo(CFrame.new(hit.Position) * tilt * CFrame.Angles(0, rng:NextNumber(0, 2 * math.pi), 0) * CFrame.new(0, -h * (opts.sink or 0.1), 0))
				for _, d in m:GetDescendants() do
					if d:IsA("BasePart") then d.Anchored = true; d.CanCollide = false; d.CanQuery = false; d.CanTouch = false; d.CastShadow = false end
				end
				m.Parent = folder; placed += 1
				grid[math.floor(x / cell) .. "," .. math.floor(z / cell)] = Vector2.new(x, z)
			end
		end
	end
	folder.Parent = opts.parent or workspace
	return placed
end
```
Notes:
- The kit models need a sensible pivot at their base.
- `PivotTo` uses the model's pivot, so set it at the bottom centre.
- Use `avoid` for paths, landmark doors and spawn points.
- For an even, PCG-like spread, set `spacing` to about the width of the mesh × 1.5. Larger spacing = clumps further apart.
- For clumps, call it several times with small `size` boxes around the cluster centres.

### C. light_plates (V1's dapple and caustic layers + beams)
```lua
-- server, run once per area: tile plates over a box, just above the seabed tops
local function plates(name, center, sizeXZ, tile, y, texId, color, transp, studsPerTile, parent)
	local f = Instance.new("Folder"); f.Name = name
	for ix = 0, math.ceil(sizeXZ.X / tile) - 1 do for iz = 0, math.ceil(sizeXZ.Y / tile) - 1 do
		local p = Instance.new("Part"); p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
		p.CastShadow = false; p.Transparency = 1; p.Size = Vector3.new(tile, 0.2, tile)
		p.Position = Vector3.new(center.X - sizeXZ.X / 2 + (ix + 0.5) * tile, y, center.Z - sizeXZ.Y / 2 + (iz + 0.5) * tile)
		local t = Instance.new("Texture"); t.Face = Enum.NormalId.Top; t.Texture = texId; t.Color3 = color
		t.Transparency = transp; t.StudsPerTileU = studsPerTile; t.StudsPerTileV = studsPerTile; t.Parent = p
		local t2 = t:Clone(); t2.Face = Enum.NormalId.Bottom; t2.Parent = p -- visible from below too
		p.Parent = f
	end end
	f.Parent = parent; return f
end
-- dapple: dark leafy-shadow texture, transparency 0.65; caustic: bright cyan web texture, transparency 0.55
```
- A flat plate shows its texture on that plane only. It doesn't drape over shapes. That's why V1 stacks it **just above** a flat build.
- On uneven terrain, use several smaller plates at different heights, or (better) a client-side caustic decal on the big rocks' top faces.
- Make the textures ourselves (code or the ChatGPT art pipeline). They must tile seamlessly.
- **Animated caustics (client):** each frame add `dt * 0.6` to `OffsetStudsU` and `dt * 0.4` to `OffsetStudsV` of the caustic Textures, wrapping at `StudsPerTile`.
- **Beams (god rays):**
  - Thin tall Parts (about 1–3 × 120 × 1 studs), Neon or a light-ray texture, Transparency about 0.6–0.85, CanCollide/CastShadow off.
  - Tilted 5–20° the same way the sun comes from, then scattered with random yaw and height.
  - Or a `Beam` between two Attachments, with a soft gradient texture, `LightEmission 1`, `FaceCamera true`.
  - Bloom Threshold 2 makes only these glow.

### D. Terrain materials by slope (V2's layer painting, done by rule)
- Sample a grid (4–8 studs).
- Raycast down to get the normal and the height.
- `slope = 1 - normal.Y`:
  - slope < 0.15 → Sand
  - 0.15–0.45 → Ground or Slate
  - > 0.45 → Rock
- Add noise (`math.noise(x/60, z/60)`) so the borders wander.
- Write it with `Terrain:ReplaceMaterial(region, 4, from, to)` per small region, or rebuild with `FillBlock` per cell.
- MEGA BITE's `MB_WorldGen` already writes materials from its height function, so put the slope rule there and re-run `MB_WorldBake` after any map change.

### E. depth_mood (V2 depth mood, never dark)
- A client LocalScript, run every 0.2 s.
- `d = math.clamp((surfaceY - camera.Y) / maxDepth, 0, 1)`
- Lerp the Atmosphere Density 0.55 → 0.8, Color/Decay towards a deeper teal, and ColorCorrection Saturation 0.3 → 0.5.
- **Hold `ColorCorrection.Brightness ≥ 0` and `Lighting.Brightness ≥ the base value`** (owner rule).
- In MEGA BITE, extend `MB_BiomeMood` instead of adding a second mood script, so the two can't fight.

## 6. Common mistakes → fixes
- **Flat field with even props** → no hero and no clusters. Add a hero silhouette, group the props, leave breathers.
- **Repeated mesh tells** → at least 3 meshes per scatter, random yaw and scale, tilt and sink. Never line things up.
- **Grid look from scatter** → spacing too even. Add jitter, use bigger spacing, scatter in clumps (V2: extents 200 = grid).
- **Floating props on slopes** → sink 5–15% and tilt towards the normal. Skip slopes above `maxSlopeDeg`.
- **Haze hides your work while building** → park Atmosphere in ServerStorage (V1).
- **Bloom on everything** → Threshold too low. V1 uses 2.
- **Washed-out look** → V1 raises Contrast and Saturation to 0.5 each. Then check it's not too much on phones.
- **Too dark at depth** (V2's darker = deeper) → the owner rule says never dark. Use denser haze and stronger colour instead.
- **Visible terrain tiling** → material patches, scatter and light plates. V2's answer was texture scale 50.
- **Scatter lag** → CanCollide, CanQuery, CanTouch and CastShadow off, streaming, a budget per biome.
- **PCG for big forms** → V2 says no. Hand-make caves, arches and cliffs.
- **Toolbox assets** → not allowed for our games. Make our own (sheet skill).
- **Multiple directional lights fighting** (V2 shows Unreal's warning) → in Roblox, one Sky plus one look per zone. Don't stack Atmospheres or ColorCorrections from two scripts.

## 7. Done checklist
- [ ] Heroes readable through the haze from the next area.
- [ ] Clusters plus breathers, not carpets.
- [ ] Materials vary by slope.
- [ ] Scatter is seeded and re-runnable.
- [ ] Caustics, dapple and beams present, and bloom catches only the bright bits.
- [ ] Never dark anywhere (check the deepest spot).
- [ ] Budget met.
- [ ] Phone test done.
- [ ] Quality-nerd sim passed.
- [ ] Research or decisions saved to the vault.
