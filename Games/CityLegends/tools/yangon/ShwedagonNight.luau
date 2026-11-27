--[[
	ShwedagonNight (Studio, Edit mode; owner 27 Nov 2026: "at night, theres lights that points to shwedagon pagoda and the
	shwedagon pagoda reflects golden light and at night it becomes shiny & glossy & bright irl").
	Vault note "City Legends/2026-11-27 Shwedagon night floodlighting.md"; refs "Yangon ref - Shwedagon at night from the east"
	and "... night skyline over Kandawgyi" (Wikimedia Commons).

	Builds (delete to undo: M.undo()):
	  ReplicatedStorage.NightGold   SurfaceAppearance templates: glossy metal gold (metal 1, rough 0.16) with an emissive
	                                gold layer: "Stupa" (the main stupa), "Shrine" (small stupas, shrines, hall / stair gold,
	                                a step dimmer, as in the photos)
	  every gold MeshPart of Landmarks.Shwedagon gets tag NightGold + attribute NightSA (WorldFx.setNightGold puts a copy of the
	                                template on at night and takes it off by day: the day look is the part's own gold variant)
	  Landmarks.Shwedagon.Night     floodlight rig: SpotLights in three rings aimed up the stupa (plinth top -> terraces, dais top
	                                -> bell, bell shoulder -> rings / lotus / bud), warm gold-white, no shadows, LODLight + DayOff
	                                (WorldFx: on at night near the camera only); lamp boxes only on the plinth top; the hti
	                                sparkle (Sparkles-like ParticleEmitter, tag NightGold) + one small PointLight

	The far glow is the emissive layer (no real light needed): the stupa sits in the Persistent FarVisible model, so every
	client has it from anywhere on the map.
	Run: execute_luau (Edit) with `return require(<this as a ModuleScript>:Clone()).build()` or paste with the last line changed.
	M.preview(true / false) shows the night state in Edit.
]]
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local M = {}
local FROM = "ShwedagonNight 27Nov"
local rgb = Color3.fromRGB

-- the frame (vault "2026-11-16 Shwedagon 3D model 1 to 1"): stupa axis, platform top; 3 studs = 1 m
M.AXIS = Vector3.new(33065.66, 174, 37182.89)

-- solid PBR maps already uploaded for the car looks (tools/lambo/pbr_ids.json)
local WHITE = "rbxassetid://99576478960484"
local METAL_1 = "rbxassetid://110771824463632"
local ROUGH_016 = "rbxassetid://100767250547240"

-- photo-measured (blueprint section 4): floodlit gold median (150,110,6)-(205,137,52), highlights to (255,234,89)
M.LOOK = {
	-- glow = emissive near the camera (the floods do the rest), far = at 3000+ studs (WorldFx ramps it: the haze eats it);
	-- tuned in Play 27-28 Nov: 0.55 near read as a flat orange blob, 0.3 still flattened the tiers (coordinator 28 Nov:
	-- "one flat blown-out yellow blob"); 0.16 keeps the tier banding. Far 3 was a faint orange cone from Kandawgyi: 12 + a paler tint reads as the brightest thing there
	Stupa = { color = rgb(255, 208, 112), tint = rgb(255, 226, 150), glow = 0.16, far = 12 },
	Shrine = { color = rgb(255, 208, 112), tint = rgb(255, 204, 116), glow = 0.08, far = 4 },
}
M.FLOOD = rgb(255, 196, 120) -- warm gold-white (blueprint: about 255,190,110)

local function landmark(): Instance
	return workspace.Yangon1to1.Landmarks.Shwedagon
end

local function isGold(p: Instance): boolean
	return p:IsA("MeshPart") and (p.MaterialVariant == "YgnGoldLeaf" or p.MaterialVariant == "YgnGoldPlate" or p.MaterialVariant == "YgnCarvedGold")
end

function M.templates(): string
	local lib = ReplicatedStorage:FindFirstChild("NightGold")
	if lib then
		lib:Destroy()
	end
	lib = Instance.new("Folder")
	lib.Name = "NightGold"
	lib:SetAttribute("From", FROM)
	for name, l in M.LOOK do
		local sa = Instance.new("SurfaceAppearance")
		sa.Name = name
		sa.ColorMapContent = Content.fromUri(WHITE)
		sa.MetalnessMapContent = Content.fromUri(METAL_1)
		sa.RoughnessMapContent = Content.fromUri(ROUGH_016)
		sa.EmissiveMaskContent = Content.fromUri(WHITE)
		sa.Color = l.color
		sa.EmissiveTint = l.tint
		sa.EmissiveStrength = l.glow
		sa:SetAttribute("FarGlow", l.far)
		sa.Parent = lib
	end
	lib.Parent = ReplicatedStorage
	return "templates: " .. #lib:GetChildren()
end

-- tag every gold mesh: the main stupa's three meshes "Stupa", the rest "Shrine"
function M.tag(): string
	local n, s = 0, 0
	for _, d in landmark():GetDescendants() do
		if isGold(d) then
			local main = d.Name:find("^SHW_Stupa_") ~= nil
			d:SetAttribute("NightSA", if main then "Stupa" else "Shrine")
			d:AddTag("NightGold")
			n += 1
			if main then
				s += 1
			end
		end
	end
	return string.format("tagged %d gold meshes (%d main stupa)", n, s)
end

local function light(l: Light, parent: Instance, brightness: number, range: number): Light
	l.Color = M.FLOOD
	l.Brightness = brightness;
	(l :: any).Range = range
	l.Shadows = false
	l.Enabled = false
	l:SetAttribute("LodRange", 900) -- (WorldFx: on within 900 x render distance; a DayOff light's default 560 cut it off from the hill roads)
	l:SetAttribute("From", FROM)
	l:AddTag("LODLight")
	l:AddTag("DayOff")
	l.Parent = parent
	return l
end

local function anchor(parent: Instance, name: string, cf: CFrame, size: Vector3, visible: boolean): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.CastShadow = false
	p.Size = size
	p.CFrame = cf
	p.Color = rgb(38, 38, 40)
	p.Material = Enum.Material.Metal
	p.Transparency = if visible then 0 else 1
	p:SetAttribute("From", FROM)
	p.Parent = parent
	return p
end

-- rings of floodlights: { count, radius, height over the platform, aim radius, aim height, angle, brightness, offset deg }
M.RINGS = {
	-- (wide and soft: 60-70 deg at brightness 6-7 put round hot spots on the gold, 120 deg at 1.4 reads as a wash + glints)
	{ n = 4, r = 128, y = 19.6, ar = 99, ay = 50, angle = 120, b = 0.9, off = 45, lamp = true }, -- plinth top corners -> terraces (r 128: inside the ring of plinth stupas, 9 studs clear of their boxes; 140 stood in one)
	{ n = 6, r = 88, y = 76, ar = 40, ay = 118, angle = 120, b = 1.4, off = 0 }, -- over the dais -> bell
	{ n = 4, r = 50, y = 126, ar = 14, ay = 185, angle = 120, b = 1.4, off = 30 }, -- over the bell shoulder -> rings, lotus, bud
}
M.PLINTH_TOP = 18.39 -- over the platform (Collision raycast)
M.HTI_Y = 273 -- over the platform: the middle of the hti tiers (Play check 27 Nov, 247 / 262 fell under it)

function M.rig(): string
	local root = landmark()
	local old = root:FindFirstChild("Night")
	if old then
		old:Destroy()
	end
	local f = Instance.new("Folder")
	f.Name = "Night"
	f:SetAttribute("From", FROM)
	local nLight = 0
	local hidden = anchor(f, "FloodAnchor", CFrame.new(M.AXIS + Vector3.new(0, 1, 0)), Vector3.new(1, 1, 1), false)
	for k, ring in M.RINGS do
		for i = 0, ring.n - 1 do
			local a = math.rad(ring.off + 360 * i / ring.n + 17) -- (+17: the complex is turned 17 deg about Y)
			local dir = Vector3.new(math.cos(a), 0, math.sin(a))
			local from = M.AXIS + dir * ring.r + Vector3.new(0, ring.y, 0)
			local at = M.AXIS + dir * ring.ar + Vector3.new(0, ring.ay, 0)
			local sl = Instance.new("SpotLight")
			sl.Face = Enum.NormalId.Front
			sl.Angle = ring.angle
			if ring.lamp then
				local lamp = anchor(f, "Flood" .. k .. "_" .. i, CFrame.lookAt(from, at), Vector3.new(1.4, 1.0, 0.8), true)
				-- a short stand from 0.06 over the plinth top to under the head (never in the plinth's plane)
				local foot = M.AXIS.Y + M.PLINTH_TOP + 0.06
				anchor(f, "Stand" .. k .. "_" .. i, CFrame.new(Vector3.new(from.X, (foot + from.Y - 0.4) / 2, from.Z)), Vector3.new(0.3, from.Y - 0.4 - foot, 0.3), true)
				light(sl, lamp, ring.b, 60)
			else
				local att = Instance.new("Attachment")
				att.Name = "Flood" .. k .. "_" .. i
				att.Parent = hidden
				att.WorldCFrame = CFrame.lookAt(from, at) -- (parent first: WorldCFrame before parenting is taken as local)
				sl.Face = Enum.NormalId.Front
				light(sl, att, ring.b, 60)
			end
			nLight += 1
		end
	end
	-- the hti: a twinkle of white-gold sparks round the umbrella + a small glow
	local hti = anchor(f, "HtiSparkle", CFrame.new(M.AXIS + Vector3.new(0, M.HTI_Y, 0)), Vector3.new(9, 22, 9), false)
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "Sparkle"
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(rgb(255, 246, 214), rgb(255, 214, 120))
	pe.LightEmission = 1
	pe.LightInfluence = 0
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 2.4), NumberSequenceKeypoint.new(1, 0) })
	pe.Transparency = NumberSequence.new(0.1)
	pe.Lifetime = NumberRange.new(0.25, 0.6)
	pe.Rate = 30
	pe.Speed = NumberRange.new(0)
	pe.Rotation = NumberRange.new(0, 360)
	pe.Shape = Enum.ParticleEmitterShape.Box
	pe.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	pe.Enabled = false
	pe:AddTag("NightGold")
	pe:SetAttribute("From", FROM)
	pe.Parent = hti
	light(Instance.new("PointLight"), hti, 2, 40)
	nLight += 1
	f.Parent = root
	return string.format("rig: %d lights (%d with lamp boxes), hti sparkle", nLight, M.RINGS[1].n)
end

-- (28 Nov, coordinator: from Kandawgyi "the brightest thing in the view with a halo and the whole hill of smaller stupas
-- glowing", "the golden reflection on Kandawgyi lake") a halo sprite behind the stupa in the Persistent FarVisible model
-- (WorldFx fades it in with distance; its anchor's attribute Reflect lays the lake streak), and the gold small stupas moved
-- into FarVisible so they are on every client from across the city (they were streamed out past ~4000 studs)
M.HALO = { y = 140, size = Vector2.new(480, 620), farScale = 1.6, alpha = 0.9, brightness = 4, color = rgb(255, 190, 90) }
M.FAR_GROUPS = { "PlinthStupa", "CardinalStupa", "PStupa", "Naungdawgyi" }
function M.halo(): string
	local far = landmark():FindFirstChild("FarVisible")
	local old = far:FindFirstChild("HaloAnchor")
	if old then
		old:Destroy()
	end
	local a = anchor(far, "HaloAnchor", CFrame.new(M.AXIS + Vector3.new(0, M.HALO.y, 0)), Vector3.new(1, 1, 1), false)
	a:SetAttribute("Reflect", true)
	local g = Instance.new("BillboardGui")
	g.Name = "NightHalo"
	g.Size = UDim2.fromScale(M.HALO.size.X, M.HALO.size.Y)
	g.LightInfluence = 0
	g.Brightness = M.HALO.brightness
	g.AlwaysOnTop = false -- (the stupa in front of the halo's plane hides its middle: the glow shows round the edge)
	g.Enabled = false
	g:SetAttribute("BaseSize", M.HALO.size)
	g:SetAttribute("FarScale", M.HALO.farScale)
	g:SetAttribute("HaloAlpha", M.HALO.alpha)
	local img = Instance.new("ImageLabel")
	img.Name = "Glow"
	img.BackgroundTransparency = 1
	img.Size = UDim2.fromScale(1, 1)
	img.Image = "rbxassetid://83825952241880" -- the street lamps' soft glow sprite (city/lamp_glow.py)
	img.ImageColor3 = M.HALO.color
	img.ImageTransparency = 1
	img.Parent = g
	g:AddTag("NightGold")
	g.Parent = a
	local moved = 0
	for _, name in M.FAR_GROUPS do
		local m = landmark().Visual:FindFirstChild(name)
		if m then
			m:SetAttribute("MovedFrom", "Visual")
			m.Parent = far
			moved += 1
		end
	end
	return string.format("halo + reflect anchor; %d gold stupa groups moved into FarVisible", moved)
end

-- the night state in Edit (in Play WorldFx does it by the tags)
function M.preview(night: boolean): string
	local lib = ReplicatedStorage:FindFirstChild("NightGold")
	for _, d in CollectionService:GetTagged("NightGold") do
		if d:IsDescendantOf(landmark()) then
			if d:IsA("ParticleEmitter") then
				d.Enabled = night
			elseif d:IsA("BasePart") then
				local cur = d:FindFirstChild("NightGoldSA")
				if cur then
					cur:Destroy()
				end
				if night and lib then
					local c = lib[d:GetAttribute("NightSA")]:Clone()
					c.Name = "NightGoldSA"
					c.Parent = d
				end
			end
		end
	end
	local rig = landmark():FindFirstChild("Night")
	if rig then
		for _, l in rig:GetDescendants() do
			if l:IsA("Light") then
				l.Enabled = night
			end
		end
	end
	return "preview " .. (if night then "night" else "day")
end

-- self-check: no SA left on by day, lights off and switched by WorldFx, few lights, nothing collides
function M.check(): string
	local lights, tagged = 0, 0
	for _, d in landmark():GetDescendants() do
		if d.Name == "NightGoldSA" then
			error("a night SurfaceAppearance is saved on " .. d.Parent:GetFullName())
		end
		if d:HasTag("NightGold") and d:IsA("BasePart") then
			tagged += 1
			assert(ReplicatedStorage.NightGold:FindFirstChild(d:GetAttribute("NightSA")), "no template for " .. d:GetFullName())
		end
		if d:IsA("Light") and d:GetAttribute("From") == FROM then
			lights += 1
			assert(not d.Enabled and not d.Shadows and d:HasTag("LODLight") and d:HasTag("DayOff"), "light not switched by WorldFx: " .. d:GetFullName())
		end
		if d:IsA("BasePart") and d:GetAttribute("From") == FROM then
			assert(d.Anchored and not d.CanCollide and not d.CanQuery, "rig part collides: " .. d:GetFullName())
		end
	end
	assert(lights <= 16, "too many lights: " .. lights)
	return string.format("check ok: %d gold meshes tagged, %d lights", tagged, lights)
end

function M.build(): string
	return table.concat({ M.templates(), M.tag(), M.rig(), M.halo(), M.check() }, "\n")
end

function M.undo()
	local lib = ReplicatedStorage:FindFirstChild("NightGold")
	if lib then
		lib:Destroy()
	end
	local rig = landmark():FindFirstChild("Night")
	if rig then
		rig:Destroy()
	end
	local far = landmark().FarVisible
	if far:FindFirstChild("HaloAnchor") then
		far.HaloAnchor:Destroy()
	end
	for _, m in far:GetChildren() do
		if m:GetAttribute("MovedFrom") == "Visual" then
			m:SetAttribute("MovedFrom", nil)
			m.Parent = landmark().Visual
		end
	end
	for _, d in landmark():GetDescendants() do
		if d:HasTag("NightGold") then
			d:RemoveTag("NightGold")
			d:SetAttribute("NightSA", nil)
		end
		if d.Name == "NightGoldSA" then
			d:Destroy()
		end
	end
end

return M
