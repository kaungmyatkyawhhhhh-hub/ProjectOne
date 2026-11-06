--[[
	LookFx (client)
	The player's own picture settings and the low fog band (owner, 2026-11-06,
	`Prompts/Lighting and car look like the Ghost Driver videos.md`). Settings > Graphics and Weather
	change LookFx.state; DayCycle, Weather and WorldFx read it, so this module needs none of them.
	Graphics levels (Low to Ultra) set these through LookFx.preset. Numbers: Config.Look.
]]

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))

local L = Config.Look

local LookFx = {}

LookFx.state = table.clone(L.Defaults) :: { [string]: any }

local function isPhone(): boolean
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

---------------------------------------------------------------------
-- Settings
---------------------------------------------------------------------
local dof: DepthOfFieldEffect? = nil

-- the lighting properties a setting changes at once (the rest are read by DayCycle and Weather)
function LookFx.apply()
	local s = LookFx.state
	Lighting.GlobalShadows = s.Shadows
	Lighting.EnvironmentDiffuseScale = if s.Ambient == "High" then 1 else L.AmbientLow
	for _, e in Lighting:GetChildren() do
		if e:IsA("BloomEffect") then
			e.Enabled = s.Glow
		elseif e:IsA("SunRaysEffect") then
			e.Enabled = s.Rays
		end
	end
	if not dof then
		local d = Instance.new("DepthOfFieldEffect")
		d.Name = "LookDof"
		d.FarIntensity = L.Dof.Far
		d.FocusDistance = L.Dof.Focus
		d.InFocusRadius = L.Dof.Radius
		d.NearIntensity = 0
		d.Parent = Lighting
		dof = d
	end
	;(dof :: DepthOfFieldEffect).Enabled = s.Dof
	local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
	if clouds then
		clouds.Enabled = s.SunClouds
	end
end

-- a graphics level sets all of these (a phone: no sun rays, a light fog at most)
function LookFx.preset(name: string)
	local p = L.Presets[name] or L.Presets.High
	for k, v in p do
		LookFx.state[k] = v
	end
	if isPhone() then
		LookFx.state.Rays = false
		if LookFx.state.Fog == "Thick" then
			LookFx.state.Fog = "Light"
		end
	end
	LookFx.apply()
end

local function number(v: any, range: number): number?
	local n = tonumber(v)
	return if n and n == n then math.clamp(n, -range, range) else nil
end

-- a saved set (only what the player changed from the graphics level)
function LookFx.load(saved: any)
	if type(saved) ~= "table" then
		return
	end
	local s = LookFx.state
	for _, k in { "Shadows", "Glow", "Rays", "Dof", "SunClouds", "Haze" } do
		if type(saved[k]) == "boolean" then
			s[k] = saved[k]
		end
	end
	for k, allowed in L.Choices do
		if type(saved[k]) == "string" and table.find(allowed, saved[k]) then
			s[k] = saved[k]
		end
	end
	for k, range in L.Sliders do
		s[k] = number(saved[k], range) or s[k]
	end
	local t = tonumber(saved.Time)
	s.Time = if t and t == t and t >= 0 and t < 24 then t else nil
	LookFx.apply()
end

-- what goes in the save
function LookFx.save(): { [string]: any }
	local out = table.clone(LookFx.state)
	return out
end

function LookFx.set(key: string, value: any)
	LookFx.state[key] = value
	LookFx.apply()
end

-- this much haze is on (DayCycle)
function LookFx.hazeOn(): boolean
	return LookFx.state.Haze
end

function LookFx.specular(): number
	return if LookFx.state.Reflections == "High" then 1 else L.ReflectionsLow
end

---------------------------------------------------------------------
-- The low fog band: soft sheets in a ring round the camera, far off, resting on the ground below
-- them (terrain or sea). The city fades into it in the distance and the road ahead stays clear.
---------------------------------------------------------------------
local F = L.Fog
type Sheet = { a: Attachment, b: Attachment, beam: Beam, x: number, z: number, y: number }
local sheets: { Sheet } = {}
local holder: Part? = nil
local amount, tint = 0, Color3.new(1, 1, 1)
local nextProbe = 1
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.IgnoreWater = false

local function buildSheets()
	if holder then
		return
	end
	local p = Instance.new("Part")
	p.Name = "LookFog"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Transparency = 1
	p.Size = Vector3.new(1, 1, 1)
	holder = p
	local n = F.Sheets
	local half = math.pi / n * F.Overlap
	for i = 1, n do
		local mid = (i - 0.5) / n * 2 * math.pi
		local a0, a1 = mid - half, mid + half
		local a = Instance.new("Attachment")
		a.Parent = p
		local b = Instance.new("Attachment")
		b.Parent = p
		a.Position = Vector3.new(math.cos(a0) * F.Radius, 0, math.sin(a0) * F.Radius)
		b.Position = Vector3.new(math.cos(a1) * F.Radius, 0, math.sin(a1) * F.Radius)
		local beam = Instance.new("Beam")
		beam.Attachment0 = a
		beam.Attachment1 = b
		beam.FaceCamera = true
		beam.Segments = 1
		beam.Texture = F.Image
		beam.TextureMode = Enum.TextureMode.Stretch
		beam.TextureLength = 1
		beam.TextureSpeed = 0
		beam.LightInfluence = 0
		beam.LightEmission = 0
		beam.Width0 = F.Height
		beam.Width1 = F.Height
		beam.Parent = p
		table.insert(sheets, { a = a, b = b, beam = beam, x = math.cos(mid) * F.Radius, z = math.sin(mid) * F.Radius, y = 0 })
	end
end

-- DayCycle: how much fog the hour wants (0..1) and its colour
function LookFx.setFog(want: number, color: Color3)
	amount, tint = want, color
	local level = F.Level[LookFx.state.Fog] or 0
	local strength = want * level
	local p = holder
	if not p then
		return
	end
	if strength < 0.02 then
		p.Parent = nil
		return
	end
	if p.Parent == nil then
		p.Parent = workspace.CurrentCamera
	end
	local count = if LookFx.state.Fog == "Light" then math.ceil(#sheets / 2) else #sheets
	local seq = NumberSequence.new(1 - strength)
	local col = ColorSequence.new(color)
	for i, s in sheets do
		-- (Light: every other sheet, half the cost)
		local on = i % 2 == 1 or count == #sheets
		s.beam.Enabled = on
		if on then
			s.beam.Transparency = seq
			s.beam.Color = col
		end
	end
end

function LookFx.start()
	buildSheets()
	rayParams.FilterDescendantsInstances = { workspace.Terrain }
	RunService.RenderStepped:Connect(function()
		local p = holder
		local cam = workspace.CurrentCamera
		if not (p and cam and p.Parent) then
			return
		end
		local pos = cam.CFrame.Position
		p.CFrame = CFrame.new(pos.X, 0, pos.Z)
		-- one sheet looks at the ground each frame: enough, and it costs one ray
		nextProbe = nextProbe % #sheets + 1
		local s = sheets[nextProbe]
		local hit = workspace:Raycast(Vector3.new(pos.X + s.x, pos.Y + 400, pos.Z + s.z), Vector3.new(0, -1400, 0), rayParams)
		if hit then
			s.y = hit.Position.Y + F.Lift
		end
		-- sheets share ends with their neighbours: each end sits at their average height
		local nb = sheets[nextProbe % #sheets + 1]
		local y = s.y + (nb.y - s.y) * 0.5
		s.b.Position = Vector3.new(s.b.Position.X, y, s.b.Position.Z)
		nb.a.Position = Vector3.new(nb.a.Position.X, y, nb.a.Position.Z)
	end)
	LookFx.setFog(amount, tint)
end

return LookFx
