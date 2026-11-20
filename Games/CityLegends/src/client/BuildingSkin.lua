--[[
	BuildingSkin (client)
	Paints every tower with generated PBR facade textures (FacadeTex ->
	EditableImage -> tiled Texture): colour, emissive (lit rooms glow), normal,
	roughness and metalness. The part-built window strips, panes, mullions and
	ledges it replaces are removed locally, which also takes ~25k parts out of
	the scene.

	If runtime images aren't available (e.g. the place hasn't allowed the
	Mesh / Image APIs) nothing changes and the part facades stay.
]]

local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FacadeTex = require(Shared:WaitForChild("FacadeTex"))

local BuildingSkin = {}

local REMOVE = { WinLit = true, Pane = true, Fin = true, Ledge = true }
local FACES = { Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right }

type Maps = { color: any, emissive: any }
type Surface = { normal: any, rough: any, metal: any }

local keepAlive: { any } = {}
-- every facade texture, so the lit windows can follow the time of day (DayCycle)
local textures: { Texture } = {}
local NIGHT_GLOW = 1.4
local DAY_GLOW = 0.1 -- by day the rooms read as dark glass, not glowing
local glow = NIGHT_GLOW
-- Studio (2026-10-31) can refuse scripts writing a Texture's emissive map ("lacking capability
-- Plugin"); then the facades keep their colour maps without the glow
local canGlow = true

local function image(buf: buffer): any
	local N = FacadeTex.SIZE
	local img = AssetService:CreateEditableImage({ Size = Vector2.new(N, N) })
	img:WritePixelsBuffer(Vector2.zero, Vector2.new(N, N), buf)
	table.insert(keepAlive, img)
	return Content.fromObject(img)
end

-- (21 Nov, owner: "make the loading screen ingame load fast") the maps are made only for the looks the towers in
-- the City use, when first needed: the whole library (every style x warm x busy) held the start 3-8 s in Studio
-- Play, for 2 towers (Yangon), and was thrown away when the probe below found textures refused
local moods: { [string]: Maps } = {}
local surfaces: { [string]: Surface } = {}
local function surfaceOf(style: string): Surface
	local s = surfaces[style]
	if not s then
		local n, r, m = FacadeTex.surface(style)
		s = { normal = image(n), rough = image(r), metal = image(m) }
		surfaces[style] = s
	end
	return s
end
local function mapsOf(style: string, warm: boolean, busy: boolean): Maps
	local key = style .. tostring(warm) .. tostring(busy)
	local m = moods[key]
	if not m then
		local c, e = FacadeTex.generate(style, warm, busy)
		m = { color = image(c), emissive = image(e) }
		moods[key] = m
		task.wait() -- spread the work over frames
	end
	return m
end

-- night 1 .. day 0 (DayCycle): how brightly the lit rooms glow
function BuildingSkin.setNight(n: number)
	glow = DAY_GLOW + (NIGHT_GLOW - DAY_GLOW) * math.clamp(n, 0, 1)
	if not canGlow then
		return
	end
	for _, tex in textures do
		tex.EmissiveStrength = glow
	end
end

function BuildingSkin.apply(city: Instance): boolean
	local towers: { BasePart } = {}
	local remove: { Instance } = {}
	for _, d in city:GetDescendants() do
		if d:IsA("BasePart") then
			if d.Name == "Tower" and d:GetAttribute("Style") then
				table.insert(towers, d)
			elseif REMOVE[d.Name] then
				table.insert(remove, d)
			end
		end
	end
	if #towers == 0 then
		return false
	end

	-- Studio (2026-10-31) can refuse scripts putting runtime images on a Texture ("lacking capability
	-- Plugin"): try one first; without the maps keep the part facades, without the glow skip it
	local first = towers[1]
	local ok, anyMaps, anySurf = pcall(function()
		local style = first:GetAttribute("Style") :: string
		return mapsOf(style, first:GetAttribute("Warm") == true, first:GetAttribute("Busy") == true), surfaceOf(style)
	end)
	if not ok then
		warn("[CityLegends] Facade textures unavailable, keeping part facades:", anyMaps)
		return false
	end
	if anyMaps and anySurf then
		local probe = Instance.new("Texture")
		local mapsOk, why = pcall(function()
			probe.ColorMapContent = anyMaps.color
			probe.NormalMapContent = anySurf.normal
			probe.RoughnessMapContent = anySurf.rough
			probe.MetalnessMapContent = anySurf.metal
		end)
		canGlow = pcall(function()
			probe.EmissiveMaskContent = anyMaps.emissive
			probe.EmissiveStrength = glow
		end)
		probe:Destroy()
		if not mapsOk then
			warn("[CityLegends] Facade textures not allowed, keeping part facades:", why)
			return false
		end
		if not canGlow then
			warn("[CityLegends] Facade glow not allowed, windows won't light up")
		end
	end

	local rng = Random.new(4242)
	for i, tower in towers do
		local style = tower:GetAttribute("Style") :: string
		local module = (tower:GetAttribute("Module") :: number?) or 7
		local warm = tower:GetAttribute("Warm") == true
		local busy = tower:GetAttribute("Busy") == true
		local skip = tower:GetAttribute("SkipFace") :: Vector3?
		local got, maps, surf = pcall(function()
			return mapsOf(style, warm, busy), surfaceOf(style)
		end)
		if got and maps and surf then
			local offsetU = rng:NextNumber(0, FacadeTex.tileStudsU(module))
			for _, face in FACES do
				local normal = tower.CFrame:VectorToWorldSpace(Vector3.FromNormalId(face))
				if not (skip and normal:Dot(skip) > 0.9) then
					local tex = Instance.new("Texture")
					tex.Face = face
					tex.ColorMapContent = maps.color
					if canGlow then
						tex.EmissiveMaskContent = maps.emissive
						tex.EmissiveStrength = glow
						tex.EmissiveTint = Color3.new(1, 1, 1)
					end
					tex.NormalMapContent = surf.normal
					tex.RoughnessMapContent = surf.rough
					tex.MetalnessMapContent = surf.metal
					tex.StudsPerTileU = FacadeTex.tileStudsU(module)
					tex.StudsPerTileV = FacadeTex.tileStudsV()
					tex.OffsetStudsU = offsetU
					tex.Parent = tower
					table.insert(textures, tex)
				end
			end
			-- the texture carries the look now; a plain matte core avoids glass refraction artefacts
			tower.Material = Enum.Material.SmoothPlastic
			tower.Reflectance = 0
		end
		if i % 60 == 0 then
			task.wait()
		end
	end

	for i, p in remove do
		p:Destroy()
		if i % 2000 == 0 then
			task.wait()
		end
	end
	-- drop the now-empty facade LOD groups so the LOD system ignores them
	for _, d in city:GetDescendants() do
		if d:IsA("Model") and d.Name == "Facade" and #d:GetChildren() == 0 then
			d:Destroy()
		end
	end
	return true
end

return BuildingSkin
