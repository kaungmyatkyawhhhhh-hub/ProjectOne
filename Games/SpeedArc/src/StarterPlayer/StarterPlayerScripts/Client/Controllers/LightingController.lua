-- LightingController: applies the area's preset (Config/Lighting) and drops the costly
-- post effects (Bloom, SunRays) on low graphics quality.
local Lighting = game:GetService("Lighting")
local UserSettings_ = UserSettings()

local Shared = game:GetService("ReplicatedStorage").Shared
local LightingConfig = require(Shared.Config.Lighting)

local LightingController = {}

local function ensure(class, name)
	local inst = Lighting:FindFirstChild(name)
	if not inst then
		inst = Instance.new(class)
		inst.Name = name
		inst.Parent = Lighting
	end
	return inst
end

local function qualityLevel()
	local gs = UserSettings_:GetService("UserGameSettings")
	local q = gs.SavedQualityLevel.Value
	if q == 0 then
		return 10 -- automatic: treat as normal
	end
	return q
end

function LightingController.apply(areaName)
	local p = LightingConfig[areaName]
	if not p then
		return
	end
	Lighting.ClockTime = p.ClockTime
	Lighting.GeographicLatitude = p.GeographicLatitude
	Lighting.Brightness = p.Brightness
	Lighting.Ambient = p.Ambient
	Lighting.OutdoorAmbient = p.OutdoorAmbient
	Lighting.EnvironmentDiffuseScale = p.EnvironmentDiffuseScale
	Lighting.EnvironmentSpecularScale = p.EnvironmentSpecularScale
	Lighting.ExposureCompensation = p.ExposureCompensation

	local cc = ensure("ColorCorrectionEffect", "AreaGrade")
	for k, v in p.ColorCorrection do
		cc[k] = v
	end
	local bloom = ensure("BloomEffect", "AreaBloom")
	for k, v in p.Bloom do
		bloom[k] = v
	end
	local rays = ensure("SunRaysEffect", "AreaSunRays")
	for k, v in p.SunRays do
		rays[k] = v
	end
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere") or ensure("Atmosphere", "Atmosphere")
	for k, v in p.Atmosphere do
		atmo[k] = v
	end

	local low = qualityLevel() <= LightingConfig.LowQualityLevel
	bloom.Enabled = not low
	rays.Enabled = not low
end

function LightingController.start(ctx)
	ctx.Lighting = LightingController
	LightingController.apply("Hub")
	local gs = UserSettings_:GetService("UserGameSettings")
	gs:GetPropertyChangedSignal("SavedQualityLevel"):Connect(function()
		LightingController.apply("Hub")
	end)
end

return LightingController
