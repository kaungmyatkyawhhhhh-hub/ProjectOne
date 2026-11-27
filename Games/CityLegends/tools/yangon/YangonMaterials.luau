--[[
	YangonMaterials.luau (2026-11-16): the Yangon texture / material library in Studio (Edit only).

	Maps: Games/CityLegends/build/materials/<slug>/roblox/ (CC0 ambientCG / Poly Haven, or procedural), table and
	notes in build/materials/materials_library.md. 3 studs = 1 m: StudsPerTile = 3 x the texture's real size.
	This module does NOT upload anything: upload the PNG / JPG maps first (Open Cloud), then hand the ids over.

	Use (ServerStorage.ClaudeTools.YangonMaterials, require a :Clone()):
		local Y = require(ServerStorage.ClaudeTools.YangonMaterials:Clone())
		Y.setIds({ YgnRenderStained = { color = 123, normal = 124, roughness = 125, metalness = 126 }, ... })
		Y.createVariants()                      -> MaterialVariants in MaterialService (masks: templates, see below)
		Y.apply(workspace.Yangon, { "kit", "landmarks", "roads" }, { dry = true })  -> counts, nothing changed
		Y.apply(workspace.Yangon, { "kit" })    -> sets Material + MaterialVariant (+ Color) on matching parts
		Y.terrain()                             -> base-material overrides for the terrain set (Y.TERRAIN)
		Y.undo(workspace.Yangon)                -> puts back Material / Color / MaterialVariant from attribute YgnOld
		Y.status()                              -> what exists, what is missing ids

	How a part is matched: its Name equals a rule's `match` (landmark meshes are named by their group code, e.g.
	"KRF"; LandmarkPlace3D renames each MeshPart to its group), or, with `pattern = true`, the Name matches a Lua
	pattern ("^GOLD_" for YangonLandmarks' GOLD_<id> meshes). For a "fixed" variant (its ColorMap already carries the
	measured Yangon colour) Part.Color becomes white, or the rule's `color` multiplier; for a neutral (per-part colour)
	variant the part keeps its Color (rule `keep`). Parts with a TextureID are skipped (the TextureID would hide the
	ColorMap) unless opts.force.

	Traps (read before running):
	* MeshParts use their mesh UVs for a material's texture. landmark_glb3d.export / geom3d write every UV as
	  (0.5, 0.5), so on today's landmark and kit meshes a variant shows ONE texel (a flat colour, only the normal
	  and roughness change little). The exporters need world-scale box-projected UVs before textures can show on
	  meshes (test on one mesh first: apply YgnBrickRed to a box mesh and a Part of the same size and compare the
	  tiling). Parts (roads, kerbs, pavements, Studio-built parts) and Terrain tile by StudsPerTile at once.
	* A part shows its MaterialVariant only when Part.Material equals the variant's BaseMaterial; apply() sets both.
	* SetBaseMaterialOverride is global: every part AND terrain cell of that material changes. The place already
	  has Riviera overrides (Plaster RivStucco, Limestone RivLimestone, Concrete RivConcrete2, Slate RivSlate,
	  ClayRoofTiles RivClayTile, 2026-11-04). terrain() touches only Y.TERRAIN's materials (Grass, LeafyGrass,
	  Ground, Mud, Pebble, Salt) and stores the old override name in MaterialService attribute YgnOld_<material>.
	* MaterialVariants have no alpha. The three masks (YgnGrilleMask, YgnChainLinkMask, YgnRazorWireMask) are made
	  as SurfaceAppearance templates (AlphaMode Transparency) in ServerStorage.YgnMaskTemplates and cloned into
	  matching MeshParts; on Parts they become Textures on opts.faces (default Front and Back).
	* LandmarkGlow parts (attribute DayMaterial / DayColor, WorldFx swaps them to Neon at night): apply() rewrites
	  DayMaterial / DayColor so the night switch puts the variant's base back.
	* Map properties (ColorMap etc.) can only be written from the Edit side (plugin / command bar / MCP).
]]

local MaterialService = game:GetService("MaterialService")
local ServerStorage = game:GetService("ServerStorage")

local M = {}

-- name, base material, StudsPerTile, MaterialPattern, fixed (ColorMap carries the colour), mask, file (slug)
-- ids (color, normal, roughness, metalness) come in through M.setIds
M.SURFACES = {
	{ name = "YgnRenderStained", base = "Plaster", studsPerTile = 9.0, pattern = "Regular", fixed = false, file = "render_stained" },
	{ name = "YgnRenderPainted", base = "Plaster", studsPerTile = 6.0, pattern = "Regular", fixed = false, file = "render_painted" },
	{ name = "YgnConcreteBare", base = "Concrete", studsPerTile = 8.13, pattern = "Regular", fixed = true, file = "concrete_bare" },
	{ name = "YgnConcreteStained", base = "Concrete", studsPerTile = 6.0, pattern = "Regular", fixed = true, file = "concrete_stained" },
	{ name = "YgnBrickRed", base = "Brick", studsPerTile = 7.5, pattern = "Regular", fixed = true, file = "brick_red" },
	{ name = "YgnAsphaltWorn", base = "Asphalt", studsPerTile = 9.0, pattern = "Regular", fixed = true, file = "asphalt_worn" },
	{ name = "YgnAsphaltPatched", base = "Asphalt", studsPerTile = 24.0, pattern = "Regular", fixed = true, file = "asphalt_patched" },
	{ name = "YgnAsphaltOily", base = "Asphalt", studsPerTile = 12.0, pattern = "Regular", fixed = true, file = "asphalt_oily" },
	{ name = "YgnConcreteLaneSlab", base = "Pavement", studsPerTile = 10.5, pattern = "Regular", fixed = true, file = "concrete_lane_slab" },
	{ name = "YgnPavementSlabs", base = "Pavement", studsPerTile = 9.0, pattern = "Regular", fixed = true, file = "pavement_slabs_broken" },
	{ name = "YgnPaversMall", base = "Pavement", studsPerTile = 5.4, pattern = "Regular", fixed = true, file = "pavers_forecourt" },
	{ name = "YgnKerb", base = "Concrete", studsPerTile = 6.0, pattern = "Regular", fixed = false, file = "kerb_stone" },
	-- 1:1 pavements (RMeshP, Sandstone): the kerb's fine concrete, tinted by each part's grey (27 Nov, "blurry" fix)
	{ name = "YgnPavementFine", base = "Sandstone", studsPerTile = 9.0, pattern = "Regular", fixed = false, file = "kerb_stone" },
	{ name = "YgnDrainSlab", base = "Concrete", studsPerTile = 3.0, pattern = "Regular", fixed = true, file = "drain_cover" },
	{ name = "YgnCorrugatedRust", base = "CorrodedMetal", studsPerTile = 6.0, pattern = "Regular", fixed = true, file = "corrugated_rust" },
	{ name = "YgnCorrugatedBlue", base = "Metal", studsPerTile = 3.6, pattern = "Regular", fixed = true, file = "corrugated_blue" },
	{ name = "YgnCorrugatedZinc", base = "Metal", studsPerTile = 5.4, pattern = "Regular", fixed = true, file = "corrugated_zinc" },
	{ name = "YgnRollerShutter", base = "Metal", studsPerTile = 4.11, pattern = "Regular", fixed = true, file = "roller_shutter" },
	{ name = "YgnSteelRusty", base = "CorrodedMetal", studsPerTile = 6.6, pattern = "Regular", fixed = true, file = "steel_rusty" },
	{ name = "YgnSteelPainted", base = "Metal", studsPerTile = 3.0, pattern = "Regular", fixed = false, file = "steel_painted" },
	{ name = "YgnGrilleMask", base = "Metal", studsPerTile = 0.9, pattern = "Regular", fixed = true, mask = true, file = "steel_grille" },
	{ name = "YgnChainLinkMask", base = "DiamondPlate", studsPerTile = 2.4, pattern = "Regular", fixed = true, mask = true, file = "chain_link" },
	{ name = "YgnRazorWireMask", base = "Metal", studsPerTile = 3.0, pattern = "Regular", fixed = true, mask = true, file = "razor_wire" },
	{ name = "YgnClayRoofTile", base = "ClayRoofTiles", studsPerTile = 7.8, pattern = "Regular", fixed = true, file = "clay_roof_tile" },
	{ name = "YgnTerrazzoGrey", base = "Granite", studsPerTile = 7.2, pattern = "Regular", fixed = true, file = "terrazzo_grey" },
	{ name = "YgnMarbleWhite", base = "Marble", studsPerTile = 6.0, pattern = "Regular", fixed = true, file = "marble_white" },
	{ name = "YgnMarbleBeige", base = "Marble", studsPerTile = 6.0, pattern = "Regular", fixed = true, file = "marble_beige" },
	{ name = "YgnTilesShophouse", base = "CeramicTiles", studsPerTile = 5.7, pattern = "Regular", fixed = true, file = "tiles_shophouse" },
	{ name = "YgnTilesBlueWhite", base = "CeramicTiles", studsPerTile = 1.8, pattern = "Regular", fixed = true, file = "tiles_blue_white" },
	{ name = "YgnTilesChequer", base = "CeramicTiles", studsPerTile = 6.0, pattern = "Regular", fixed = true, file = "tiles_chequer" },
	{ name = "YgnTilesPool", base = "CeramicTiles", studsPerTile = 3.0, pattern = "Regular", fixed = true, file = "tiles_pool" },
	{ name = "YgnTeakShutter", base = "Wood", studsPerTile = 3.0, pattern = "Regular", fixed = true, file = "teak_shutter" },
	{ name = "YgnTeakPanel", base = "WoodPlanks", studsPerTile = 6.3, pattern = "Regular", fixed = true, file = "teak_panel" },
	{ name = "YgnWoodPainted", base = "WoodPlanks", studsPerTile = 4.8, pattern = "Regular", fixed = false, file = "wood_painted" },
	{ name = "YgnWoodRaw", base = "WoodPlanks", studsPerTile = 5.4, pattern = "Regular", fixed = true, file = "wood_raw" },
	{ name = "YgnBamboo", base = "Wood", studsPerTile = 1.2, pattern = "Regular", fixed = true, file = "bamboo_scaffold" },
	{ name = "YgnShadeNet", base = "Fabric", studsPerTile = 0.75, pattern = "Regular", fixed = true, file = "mesh_green" },
	{ name = "YgnTarpBlue", base = "Fabric", studsPerTile = 4.5, pattern = "Regular", fixed = true, file = "tarp_blue" },
	{ name = "YgnCanvas", base = "Fabric", studsPerTile = 1.2, pattern = "Regular", fixed = false, file = "canvas_awning" },
	{ name = "YgnVinyl", base = "Fabric", studsPerTile = 6.0, pattern = "Regular", fixed = false, file = "banner_vinyl" },
	{ name = "YgnGoldLeaf", base = "Metal", studsPerTile = 3.0, pattern = "Regular", fixed = true, file = "gold_leaf" },
	{ name = "YgnGoldPlate", base = "Metal", studsPerTile = 3.6, pattern = "Regular", fixed = true, file = "gold_plate" },
	{ name = "YgnGlassMosaic", base = "Foil", studsPerTile = 0.9, pattern = "Regular", fixed = true, file = "glass_mosaic" },
	{ name = "YgnGrassLawn", base = "Grass", studsPerTile = 4.2, pattern = "Organic", fixed = true, file = "grass_lawn" },
	{ name = "YgnGrassDry", base = "LeafyGrass", studsPerTile = 6.0, pattern = "Organic", fixed = true, file = "grass_dry" },
	{ name = "YgnEarthRed", base = "Salt", studsPerTile = 6.0, pattern = "Organic", fixed = true, file = "earth_red" },
	{ name = "YgnDirtPacked", base = "Ground", studsPerTile = 9.0, pattern = "Organic", fixed = true, file = "dirt_packed" },
	{ name = "YgnGravel", base = "Pebble", studsPerTile = 6.75, pattern = "Organic", fixed = true, file = "gravel" },
	{ name = "YgnMudEdge", base = "Mud", studsPerTile = 3.9, pattern = "Organic", fixed = true, file = "mud_lake_edge" },
	{ name = "YgnLeafLitter", base = "Ground", studsPerTile = 6.0, pattern = "Organic", fixed = true, file = "leaf_litter" },
	{ name = "YgnBark", base = "Wood", studsPerTile = 3.0, pattern = "Regular", fixed = true, file = "bark_tree" },
}

local BY: { [string]: any } = {}
for _, s in M.SURFACES do
	BY[s.name] = s
end
M.BY = BY

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

--[[ Rule sets. { match, variant, keep = keep the part's Color (neutral variants), color = Color3 multiplier,
	pattern = true for a Lua pattern }. Targets and reasons in materials_library.md. ]]
M.RULES = {
	kit = {
		-- walls: per-part colours stay (the variant is neutral)
		{ match = "KW0", variant = "YgnRenderPainted", keep = true },
		{ match = "KW1", variant = "YgnRenderPainted", keep = true },
		{ match = "KW2", variant = "YgnRenderPainted", keep = true },
		{ match = "KW3", variant = "YgnRenderPainted", keep = true },
		{ match = "KW4", variant = "YgnRenderPainted", keep = true },
		{ match = "KW5", variant = "YgnRenderPainted", keep = true },
		{ match = "KW6", variant = "YgnRenderPainted", keep = true },
		{ match = "KW7", variant = "YgnRenderPainted", keep = true },
		{ match = "KWB", variant = "YgnRenderPainted", keep = true },
		{ match = "KWG", variant = "YgnRenderStained", keep = true },
		{ match = "KWD2", variant = "YgnRenderStained", keep = true },
		{ match = "KWC", variant = "YgnRenderStained", keep = true },
		{ match = "KCO", variant = "YgnConcreteBare" },
		-- roofs
		{ match = "KRF", variant = "YgnCorrugatedRust" },
		{ match = "KRG", variant = "YgnCorrugatedZinc" },
		{ match = "KRB", variant = "YgnCorrugatedBlue" },
		{ match = "KAW", variant = "YgnCorrugatedBlue" },
		{ match = "KRT", variant = "YgnClayRoofTile" },
		-- metal
		{ match = "KRS", variant = "YgnRollerShutter" },
		{ match = "KGU", variant = "YgnSteelRusty" },
		{ match = "KCU", variant = "YgnSteelRusty", color = rgb(184, 159, 154) },
		{ match = "KGT", variant = "YgnSteelPainted", keep = true },
		{ match = "KCB", variant = "YgnSteelPainted", keep = true },
		{ match = "KCG", variant = "YgnSteelPainted", keep = true },
		{ match = "KGR", variant = "YgnSteelPainted", keep = true },
		{ match = "KCW", variant = "YgnSteelPainted", keep = true },
		-- wood
		{ match = "KSH", variant = "YgnTeakShutter" },
		{ match = "KSH2", variant = "YgnWoodPainted", keep = true },
		{ match = "KSH3", variant = "YgnWoodPainted", keep = true },
		{ match = "KSH4", variant = "YgnWoodPainted", keep = true },
		{ match = "KWD", variant = "YgnWoodRaw" },
		{ match = "KTW", variant = "YgnBark" },
		-- fabric
		{ match = "KAR", variant = "YgnCanvas", keep = true },
		{ match = "KTP", variant = "YgnTarpBlue" },
		{ match = "KNT", variant = "YgnShadeNet" },
		{ match = "KSV", variant = "YgnVinyl", keep = true },
		-- ground
		{ match = "KPV", variant = "YgnPavementSlabs" },
		{ match = "KRD", variant = "YgnAsphaltWorn" },
		{ match = "KGS", variant = "YgnGrassLawn" },
	},
	landmarks = {
		{ match = "LAW", variant = "YgnGrassLawn" },
		{ match = "HDG", variant = "YgnGrassLawn", color = rgb(205, 215, 200) },
		{ match = "PAV", variant = "YgnPaversMall" },
		{ match = "DRV", variant = "YgnAsphaltWorn" },
		{ match = "ROF", variant = "YgnConcreteBare" },
		{ match = "FEN", variant = "YgnChainLinkMask" },
		{ match = "TRZ", variant = "YgnTerrazzoGrey" },
		{ match = "MWH", variant = "YgnMarbleWhite" },
		{ match = "MDK", variant = "YgnMarbleWhite" },
		{ match = "MAR", variant = "YgnMarbleWhite" },
		{ match = "MFL", variant = "YgnMarbleBeige" },
		{ match = "CAR", variant = "YgnMarbleBeige", color = rgb(237, 199, 137) },
		{ match = "TEK", variant = "YgnTeakPanel" },
		{ match = "TKC", variant = "YgnTeakPanel" },
		{ match = "WOD", variant = "YgnTeakPanel" },
		{ match = "MBM", variant = "YgnTeakPanel", color = rgb(102, 102, 115) },
		{ match = "MCO", variant = "YgnTeakPanel", color = rgb(118, 116, 128) },
		{ match = "POL", variant = "YgnTilesPool" },
		{ match = "TLB", variant = "YgnTilesBlueWhite" },
		{ match = "TLW", variant = "YgnTilesShophouse", color = rgb(255, 255, 255) },
		{ match = "WTL", variant = "YgnTilesShophouse" },
		{ match = "RTL", variant = "YgnClayRoofTile", color = rgb(255, 191, 140) },
		{ match = "RED", variant = "YgnVinyl", keep = true },
		{ match = "SGD", variant = "YgnGoldLeaf" },
		-- YangonLandmarks meshes are named <KIND>_<id>
		{ match = "^GOLD_", pattern = true, variant = "YgnGoldLeaf" },
		{ match = "^STONE_", pattern = true, variant = "YgnMarbleWhite", color = rgb(236, 232, 229) },
	},
	-- the owner set these landmark walls white and flat by hand (16 Nov): opt in only after a look
	landmarkWalls = {
		{ match = "MEL", variant = "YgnRenderPainted", keep = true },
		{ match = "RES", variant = "YgnRenderPainted", keep = true },
		{ match = "SED", variant = "YgnRenderPainted", keep = true },
		{ match = "CRM", variant = "YgnRenderPainted", keep = true },
		{ match = "GRN", variant = "YgnRenderPainted", keep = true },
		{ match = "CEL", variant = "YgnRenderPainted", keep = true },
		{ match = "GFA", variant = "YgnRenderPainted", keep = true },
		{ match = "TER", variant = "YgnClayRoofTile", color = rgb(200, 175, 160) },
	},
	roads = {
		{ match = "Road", variant = "YgnAsphaltWorn" },
		{ match = "Pavement", variant = "YgnPavementSlabs" },
		{ match = "Kerb", variant = "YgnKerb", keep = true },
		{ match = "MedianKerb", variant = "YgnKerb", keep = true },
		{ match = "Pier", variant = "YgnConcreteBare" },
		{ match = "PierCap", variant = "YgnConcreteBare" },
		{ match = "Girder", variant = "YgnConcreteStained" },
		{ match = "Barrier", variant = "YgnConcreteBare" },
	},
	-- 1:1 road meshes (Yangon1to1.Roads.Meshes, 27 Nov 2026, owner: "those look blurry"): plain Concrete / Sandstone
	-- fell to the Monaco base overrides (RivConcrete2, 22 studs a tile) = a smeared blotch next to the car.
	meshRoads = {
		{ match = "RMeshKR", variant = "YgnKerb", keep = true },
		{ match = "RMeshKW", variant = "YgnKerb", keep = true },
		{ match = "RMeshB", variant = "YgnKerb", keep = true },
		{ match = "RMeshP", variant = "YgnPavementFine", keep = true },
	},
}

-- terrain material -> variant (SetBaseMaterialOverride). Salt is a spare terrain material re-used as red earth.
M.TERRAIN = {
	Grass = "YgnGrassLawn",
	LeafyGrass = "YgnGrassDry",
	Ground = "YgnDirtPacked",
	Mud = "YgnMudEdge",
	Pebble = "YgnGravel",
	Salt = "YgnEarthRed",
}

local function uri(id: any): string?
	if id == nil or id == "" or id == 0 then
		return nil
	end
	local s = tostring(id)
	if string.match(s, "^%d+$") then
		return "rbxassetid://" .. s
	end
	return s
end

-- writes ColorMap etc.; newer Studios also take <Prop>Content (Content.fromUri)
local function setMap(inst: Instance, prop: string, id: any): boolean
	local u = uri(id)
	if not u then
		return false
	end
	local ok = pcall(function()
		(inst :: any)[prop] = u
	end)
	if not ok then
		ok = pcall(function()
			(inst :: any)[prop .. "Content"] = (Content :: any).fromUri(u)
		end)
	end
	return ok
end

function M.setIds(ids: { [string]: { color: any?, normal: any?, roughness: any?, metalness: any? } })
	local n = 0
	for name, t in ids do
		local s = BY[name]
		if s then
			s.color, s.normal, s.roughness, s.metalness = t.color, t.normal, t.roughness, t.metalness
			n += 1
		else
			warn("YangonMaterials.setIds: unknown variant " .. tostring(name))
		end
	end
	return n
end

local function maskFolder(): Folder
	local f = ServerStorage:FindFirstChild("YgnMaskTemplates")
	if not f then
		f = Instance.new("Folder")
		f.Name = "YgnMaskTemplates"
		f.Parent = ServerStorage
	end
	return f :: Folder
end

-- one MaterialVariant per surface (masks: a SurfaceAppearance template). Existing ones are updated in place.
function M.createVariants(only: { string }?)
	local want: { [string]: boolean }? = nil
	if only then
		want = {}
		for _, n in only do
			(want :: any)[n] = true
		end
	end
	local made, skipped, log = 0, 0, {}
	for _, s in M.SURFACES do
		if want and not want[s.name] then
			continue
		end
		if not s.color then
			skipped += 1
			table.insert(log, s.name .. ": no ids yet")
			continue
		end
		if s.mask then
			local f = maskFolder()
			local sa = f:FindFirstChild(s.name) :: SurfaceAppearance?
			if not sa then
				sa = Instance.new("SurfaceAppearance")
				;(sa :: SurfaceAppearance).Name = s.name
				;(sa :: SurfaceAppearance).Parent = f
			end
			pcall(function()
				(sa :: SurfaceAppearance).AlphaMode = Enum.AlphaMode.Transparency
			end)
			setMap(sa :: any, "ColorMap", s.color)
			setMap(sa :: any, "NormalMap", s.normal)
			setMap(sa :: any, "RoughnessMap", s.roughness)
			setMap(sa :: any, "MetalnessMap", s.metalness)
			sa:SetAttribute("StudsPerTile", s.studsPerTile)
			made += 1
			continue
		end
		local v = MaterialService:FindFirstChild(s.name)
		if v and not v:IsA("MaterialVariant") then
			table.insert(log, s.name .. ": a non-variant of that name is in MaterialService, skipped")
			skipped += 1
			continue
		end
		local isNew = v == nil
		local mv: MaterialVariant = (v or Instance.new("MaterialVariant")) :: MaterialVariant
		local ok, err = pcall(function()
			mv.Name = s.name
			mv.BaseMaterial = (Enum.Material :: any)[s.base]
			mv.StudsPerTile = s.studsPerTile
			mv.MaterialPattern = (Enum.MaterialPattern :: any)[s.pattern or "Regular"]
		end)
		if not ok then
			table.insert(log, s.name .. ": " .. tostring(err))
			skipped += 1
			if isNew then
				mv:Destroy()
			end
			continue
		end
		local okC = setMap(mv, "ColorMap", s.color)
		setMap(mv, "NormalMap", s.normal)
		setMap(mv, "RoughnessMap", s.roughness)
		setMap(mv, "MetalnessMap", s.metalness)
		if not okC then
			table.insert(log, s.name .. ": ColorMap not writable (run from the Edit side)")
		end
		mv:SetAttribute("YgnSource", "build/materials/" .. tostring(s.file))
		mv.Parent = MaterialService
		made += 1
	end
	return made, skipped, log
end

local function remember(p: BasePart)
	if p:GetAttribute("YgnOld") == nil then
		local c = p.Color
		p:SetAttribute("YgnOld", string.format("%s|%d,%d,%d|%s", p.Material.Name, math.round(c.R * 255),
			math.round(c.G * 255), math.round(c.B * 255), p.MaterialVariant))
	end
end

local function rulesFrom(sets: { string }?): { any }
	local out = {}
	for _, name in (sets or { "kit", "landmarks", "roads" }) do
		local r = M.RULES[name]
		if r then
			for _, x in r do
				table.insert(out, x)
			end
		else
			warn("YangonMaterials: no rule set " .. tostring(name))
		end
	end
	return out
end

local function ruleFor(rules: { any }, name: string): any?
	for _, r in rules do
		if r.pattern then
			if string.match(name, r.match) then
				return r
			end
		elseif r.match == name then
			return r
		end
	end
	return nil
end

--[[ apply(root, sets, opts) -> { [variant] = count }, total
	opts.dry: count only. opts.force: also parts with a TextureID. opts.faces: Texture faces for masks on Parts.
	opts.classes: "MeshPart" / "Part" / nil = both. Yields every 400 parts. ]]
function M.apply(root: Instance, sets: { string }?, opts: any?)
	local o = opts or {}
	local rules = rulesFrom(sets)
	local counts, total, seen, skippedTex = {}, 0, 0, 0
	local faces = o.faces or { Enum.NormalId.Front, Enum.NormalId.Back }
	for _, d in root:GetDescendants() do
		if not d:IsA("BasePart") then
			continue
		end
		if o.classes == "MeshPart" and not d:IsA("MeshPart") or o.classes == "Part" and d:IsA("MeshPart") then
			continue
		end
		local r = ruleFor(rules, d.Name)
		if not r then
			continue
		end
		local s = BY[r.variant]
		if not s then
			continue
		end
		if d:IsA("MeshPart") and (d :: MeshPart).TextureID ~= "" and not o.force then
			skippedTex += 1
			continue
		end
		counts[r.variant] = (counts[r.variant] or 0) + 1
		total += 1
		seen += 1
		if seen % 400 == 0 then
			task.wait()
		end
		if o.dry then
			continue
		end
		remember(d)
		if s.mask then
			local tpl = maskFolder():FindFirstChild(s.name)
			if d:IsA("MeshPart") and tpl then
				local old = d:FindFirstChild("YgnMask")
				if old then
					old:Destroy()
				end
				local sa = tpl:Clone()
				sa.Name = "YgnMask"
				sa.Parent = d
			elseif s.color then
				for _, f in faces do
					local t = Instance.new("Texture")
					t.Name = "YgnMask"
					t.Face = f
					t.Texture = uri(s.color) :: string
					t.StudsPerTileU = s.studsPerTile
					t.StudsPerTileV = s.studsPerTile
					t.Parent = d
				end
			end
			continue
		end
		d.Material = (Enum.Material :: any)[s.base]
		d.MaterialVariant = s.name
		if not r.keep then
			d.Color = r.color or Color3.new(1, 1, 1)
		end
		if d:GetAttribute("DayMaterial") ~= nil then
			d:SetAttribute("DayMaterial", s.base)
			d:SetAttribute("DayColor", d.Color)
		end
	end
	if skippedTex > 0 then
		warn(string.format("YangonMaterials.apply: %d parts with a TextureID skipped (opts.force to include)", skippedTex))
	end
	return counts, total
end

function M.undo(root: Instance): number
	local n = 0
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			local old = d:GetAttribute("YgnOld")
			if type(old) == "string" then
				local mat, r, g, b, var = string.match(old, "^(%w+)|(%d+),(%d+),(%d+)|(.*)$")
				if mat then
					d.Material = (Enum.Material :: any)[mat]
					d.Color = Color3.fromRGB(tonumber(r) :: number, tonumber(g) :: number, tonumber(b) :: number)
					d.MaterialVariant = var :: string
					if d:GetAttribute("DayMaterial") ~= nil then
						d:SetAttribute("DayMaterial", mat)
						d:SetAttribute("DayColor", d.Color)
					end
				end
				for _, ch in d:GetChildren() do
					if ch.Name == "YgnMask" then
						ch:Destroy()
					end
				end
				d:SetAttribute("YgnOld", nil)
				n += 1
			end
		end
	end
	return n
end

-- base-material overrides for terrain (global: parts of these materials change too)
function M.terrain(map: { [string]: string }?, undo: boolean?)
	local done = {}
	for matName, variant in (map or M.TERRAIN) do
		local mat = (Enum.Material :: any)[matName]
		local key = "YgnOld_" .. matName
		if undo then
			local old = MaterialService:GetAttribute(key)
			if old ~= nil then
				MaterialService:SetBaseMaterialOverride(mat, old)
				MaterialService:SetAttribute(key, nil)
				table.insert(done, matName .. " -> " .. tostring(old))
			end
		elseif MaterialService:FindFirstChild(variant) then
			if MaterialService:GetAttribute(key) == nil then
				MaterialService:SetAttribute(key, MaterialService:GetBaseMaterialOverride(mat))
			end
			MaterialService:SetBaseMaterialOverride(mat, variant)
			table.insert(done, matName .. " -> " .. variant)
		else
			table.insert(done, matName .. ": " .. variant .. " not created yet")
		end
	end
	return done
end

function M.status()
	local rows = {}
	for _, s in M.SURFACES do
		local inst = if s.mask then maskFolder():FindFirstChild(s.name) else MaterialService:FindFirstChild(s.name)
		table.insert(rows, string.format("%-20s %-14s spt %5.2f ids %s  %s", s.name, s.base, s.studsPerTile,
			if s.color then "yes" else "NO", if inst then "created" else "-"))
	end
	return table.concat(rows, "\n")
end

return M
