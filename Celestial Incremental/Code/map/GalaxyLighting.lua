-- GalaxyLighting (Galaxy Incremental, lighting pass 2 Nov): puts MapConfig.Lighting on the game (every lighting value is
-- there; change a number there to tune it).
--  * Apply(): Lighting's properties, the Atmosphere, the Bloom, the "GalaxyGrade" colour correction, the Core's warm light;
--    sun rays and depth of field off. The server runs it at start (GalaxyLightingService), the map builder after a rebuild.
--  * IsLowEnd() / ApplyLowEnd(): THIS device only (GalaxyLightingClient): phones (touch, no keyboard), Roblox graphics set to
--    1-3, or Workspace TestLowEnd in Studio -> bloom off, shadows off (+ the warmer LowEnd ambient), the island star lights
--    off (shared.GalaxyLowEnd tells GalaxyMapClient not to make them; the ones made already are switched off)
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local MapConfig = require(ReplicatedStorage:WaitForChild("Galaxy"):WaitForChild("MapConfig"))

local M = {}

local PROPS = { "ClockTime", "GeographicLatitude", "Brightness", "ColorShift_Top", "ColorShift_Bottom", "GlobalShadows", "ShadowSoftness",
	"Ambient", "OutdoorAmbient", "EnvironmentDiffuseScale", "EnvironmentSpecularScale", "ExposureCompensation" }

local function effect(class: string, name: string?): Instance
	local x = (name and Lighting:FindFirstChild(name)) or Lighting:FindFirstChildOfClass(class)
	if not x then
		x = Instance.new(class)
		if name then x.Name = name end
		x.Parent = Lighting
	end
	return x
end

function M.Apply()
	local L = MapConfig.Lighting
	for _, k in ipairs(PROPS) do Lighting[k] = L[k] end
	local atm = effect("Atmosphere")
	for k, v in pairs(L.Atmosphere) do atm[k] = v end
	local bloom = effect("BloomEffect")
	for k, v in pairs(L.Bloom) do bloom[k] = v end
	local cc = effect("ColorCorrectionEffect", "GalaxyGrade")
	for k, v in pairs(L.Grade) do cc[k] = v end
	for _, d in ipairs(Lighting:GetChildren()) do
		if d:IsA("SunRaysEffect") or d:IsA("DepthOfFieldEffect") then d.Enabled = false end
	end
	-- the Core's warm light (the map builder makes it; it lights the plaza round the Core)
	local root = workspace:FindFirstChild("Galaxy")
	local core = root and root:FindFirstChild("Centre") and root.Centre:FindFirstChild("Core")
	local host = core and core:FindFirstChild("CoreLight")
	local light = host and host:FindFirstChildOfClass("PointLight")
	if light then
		light.Color, light.Range, light.Brightness, light.Shadows = L.Core.Color, L.Core.Range, L.Core.Brightness, false
	end
end

function M.IsLowEnd(): boolean
	if RunService:IsStudio() and workspace:GetAttribute("TestLowEnd") == true then return true end
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then return true end
	local ok, level = pcall(function() return UserSettings():GetService("UserGameSettings").SavedQualityLevel end)
	if ok and level and level ~= Enum.SavedQualitySetting.Automatic and level.Value <= MapConfig.Lighting.LowEnd.QualityAtMost then
		return true
	end
	return false
end

function M.ApplyLowEnd()
	shared.GalaxyLowEnd = true
	Lighting.GlobalShadows = false
	Lighting.OutdoorAmbient = MapConfig.Lighting.LowEnd.OutdoorAmbient
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
	if bloom then bloom.Enabled = false end
	local localFolder = workspace:FindFirstChild("GalaxyLocal")
	if localFolder then
		for _, d in ipairs(localFolder:GetDescendants()) do
			if d:IsA("PointLight") and d.Name == "StarLight" then d.Enabled = false end
		end
	end
end

return M
