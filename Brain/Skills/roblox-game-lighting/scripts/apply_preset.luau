--!nocheck
-- apply_preset.luau (roblox-game-lighting skill)
-- Run with the Studio MCP execute_luau in the Edit datamodel (changes the place; nothing is saved until the owner saves)
-- or in the Server datamodel during Play (a throwaway preview that vanishes when Play stops).
--
-- MODE = "APPLY"   : backs the current look up to ServerStorage.LightingBackups.<TAG>, then applies PRESETS[PRESET]
-- MODE = "RESTORE" : puts ServerStorage.LightingBackups.<TAG> back (properties + effect objects)
-- MODE = "LIST"    : lists the backups
--
-- The backup holds: every Lighting property in LIGHT_PROPS as attributes, and clones of the Atmosphere, Sky and post
-- effects under Lighting. Runtime mood scripts that cached the old values must be updated separately (see SKILL.md).
-- Lighting.Technology cannot be set from the plugin: set it by hand in the Properties panel.

local MODE = "APPLY"          -- "APPLY" | "RESTORE" | "LIST"
local PRESET = "stylized_day" -- a key of PRESETS
local TAG = "before_" .. os.date("!%d%b_%H%M") -- backup name; for RESTORE set it to an existing backup's name
local CC_NAME = nil            -- name of the ColorCorrection to use (e.g. "MB_ColorCorrection"); nil = first one found / "ColorCorrection"

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

-- Keep in sync with references/presets.md
local PRESETS = {
	stylized_day = { -- Develuper "Make your Roblox game look 10x better with lighting" (values read off the video)
		lighting = {LightingStyle = "Realistic", PrioritizeLightingQuality = true, Brightness = 3, Ambient = rgb(84, 107, 156),
			OutdoorAmbient = rgb(117, 120, 145), ClockTime = 9.6, GeographicLatitude = 7, ShadowSoftness = 0.2,
			EnvironmentDiffuseScale = 1, EnvironmentSpecularScale = 1, GlobalShadows = true, ExposureCompensation = 0},
		atmosphere = {Density = 0.34, Offset = 0, Color = rgb(199, 199, 199), Decay = rgb(106, 112, 125), Glare = 2.86, Haze = 1.27},
		bloom = {Enabled = true, Intensity = 1, Size = 56, Threshold = 2},
		sunrays = {Enabled = true, Intensity = 0.048, Spread = 0.895},
		cc = {Enabled = true, Brightness = 0, Contrast = 0.3, Saturation = 0.5, TintColor = rgb(226, 238, 255)},
		dof = {Enabled = false},
		sky = {CelestialBodiesShown = true},
	},
	kid_sim_noon = {
		lighting = {LightingStyle = "Soft", Brightness = 2.6, Ambient = rgb(110, 125, 160), OutdoorAmbient = rgb(140, 140, 150),
			ClockTime = 12.5, GeographicLatitude = 20, ShadowSoftness = 0.5, EnvironmentDiffuseScale = 1,
			EnvironmentSpecularScale = 0.6, GlobalShadows = true, ExposureCompensation = 0},
		atmosphere = {Density = 0.28, Offset = 0, Color = rgb(215, 230, 255), Decay = rgb(120, 150, 200), Glare = 0.4, Haze = 0.8},
		bloom = {Enabled = true, Intensity = 0.6, Size = 30, Threshold = 1.6},
		sunrays = {Enabled = true, Intensity = 0.06, Spread = 0.7},
		cc = {Enabled = true, Brightness = 0.02, Contrast = 0.18, Saturation = 0.35, TintColor = rgb(245, 250, 255)},
		dof = {Enabled = false},
		sky = {CelestialBodiesShown = true},
	},
	golden_hour = {
		lighting = {LightingStyle = "Realistic", Brightness = 2.4, Ambient = rgb(95, 85, 120), OutdoorAmbient = rgb(150, 120, 110),
			ClockTime = 17.2, GeographicLatitude = 25, ShadowSoftness = 0.25, EnvironmentDiffuseScale = 1,
			EnvironmentSpecularScale = 1, GlobalShadows = true, ExposureCompensation = 0},
		atmosphere = {Density = 0.36, Offset = 0, Color = rgb(255, 200, 160), Decay = rgb(150, 95, 110), Glare = 3, Haze = 1.6},
		bloom = {Enabled = true, Intensity = 0.9, Size = 40, Threshold = 1.7},
		sunrays = {Enabled = true, Intensity = 0.12, Spread = 0.6},
		cc = {Enabled = true, Brightness = 0, Contrast = 0.22, Saturation = 0.3, TintColor = rgb(255, 240, 225)},
		dof = {Enabled = false},
		sky = {CelestialBodiesShown = true},
	},
	overcast = {
		lighting = {LightingStyle = "Soft", Brightness = 1.6, Ambient = rgb(120, 128, 140), OutdoorAmbient = rgb(150, 155, 165),
			ClockTime = 13, ShadowSoftness = 0.9, EnvironmentDiffuseScale = 1, EnvironmentSpecularScale = 0.4,
			GlobalShadows = true, ExposureCompensation = 0},
		atmosphere = {Density = 0.42, Offset = 0, Color = rgb(200, 205, 212), Decay = rgb(120, 128, 140), Glare = 0, Haze = 2},
		bloom = {Enabled = true, Intensity = 0.3, Size = 24, Threshold = 1.8},
		sunrays = {Enabled = false},
		cc = {Enabled = true, Brightness = 0, Contrast = 0.12, Saturation = 0.05, TintColor = rgb(240, 245, 250)},
		dof = {Enabled = false},
		sky = {CelestialBodiesShown = false},
	},
	readable_night = {
		lighting = {LightingStyle = "Realistic", Brightness = 1.2, Ambient = rgb(45, 55, 90), OutdoorAmbient = rgb(70, 80, 125),
			ClockTime = 0.5, GeographicLatitude = 30, ShadowSoftness = 0.4, EnvironmentDiffuseScale = 1,
			EnvironmentSpecularScale = 1, GlobalShadows = true, ExposureCompensation = 0},
		atmosphere = {Density = 0.38, Offset = 0, Color = rgb(70, 90, 140), Decay = rgb(25, 30, 60), Glare = 0, Haze = 1.4},
		bloom = {Enabled = true, Intensity = 1, Size = 36, Threshold = 1.2},
		sunrays = {Enabled = false},
		cc = {Enabled = true, Brightness = 0.03, Contrast = 0.2, Saturation = 0.1, TintColor = rgb(225, 232, 255)},
		dof = {Enabled = false},
		sky = {CelestialBodiesShown = true, StarCount = 3000},
	},
	horror = {
		lighting = {LightingStyle = "Realistic", Brightness = 0.8, Ambient = rgb(30, 32, 40), OutdoorAmbient = rgb(45, 50, 60),
			ClockTime = 2, ShadowSoftness = 0.3, EnvironmentDiffuseScale = 0.6, EnvironmentSpecularScale = 0.6,
			GlobalShadows = true, ExposureCompensation = 0},
		atmosphere = {Density = 0.55, Offset = 0.1, Color = rgb(90, 100, 95), Decay = rgb(20, 25, 25), Glare = 0, Haze = 2.5},
		bloom = {Enabled = true, Intensity = 0.5, Size = 24, Threshold = 1.4},
		sunrays = {Enabled = false},
		cc = {Enabled = true, Brightness = -0.02, Contrast = 0.25, Saturation = -0.35, TintColor = rgb(225, 240, 230)},
		dof = {Enabled = false},
		sky = {CelestialBodiesShown = true, StarCount = 500},
	},
	neon_scifi = {
		lighting = {LightingStyle = "Realistic", Brightness = 1, Ambient = rgb(40, 30, 70), OutdoorAmbient = rgb(60, 50, 110),
			ClockTime = 22, ShadowSoftness = 0.3, EnvironmentDiffuseScale = 1, EnvironmentSpecularScale = 1,
			GlobalShadows = true, ExposureCompensation = 0},
		atmosphere = {Density = 0.35, Offset = 0, Color = rgb(120, 80, 200), Decay = rgb(40, 20, 90), Glare = 0.5, Haze = 1.5},
		bloom = {Enabled = true, Intensity = 1.2, Size = 40, Threshold = 0.95},
		sunrays = {Enabled = false},
		cc = {Enabled = true, Brightness = 0, Contrast = 0.25, Saturation = 0.4, TintColor = rgb(235, 225, 255)},
		dof = {Enabled = false},
		sky = {CelestialBodiesShown = true},
	},
	underwater_reef = { -- MEGA BITE base look (live, 14 Nov 2026)
		lighting = {LightingStyle = "Soft", Brightness = 1.9, Ambient = rgb(70, 95, 125), OutdoorAmbient = rgb(95, 125, 160),
			ClockTime = 13, GeographicLatitude = 0, ShadowSoftness = 0.6, EnvironmentDiffuseScale = 0.85, EnvironmentSpecularScale = 0.45,
			ColorShift_Top = rgb(190, 225, 255),
			GlobalShadows = true, ExposureCompensation = -0.1},
		atmosphere = {Density = 0.40, Offset = 0.18, Color = rgb(46, 150, 196), Decay = rgb(10, 38, 98), Glare = 0.15, Haze = 1.9},
		bloom = {Enabled = true, Intensity = 0.75, Size = 28, Threshold = 1.05},
		sunrays = {Enabled = true, Intensity = 0.13, Spread = 0.5},
		cc = {Enabled = true, Brightness = 0, Contrast = 0.26, Saturation = 0.38, TintColor = rgb(236, 248, 255)},
		dof = {Enabled = true, FarIntensity = 0.18, FocusDistance = 70, InFocusRadius = 90, NearIntensity = 0},
		sky = {CelestialBodiesShown = false, StarCount = 0},
	},
}

local Lighting = game:GetService("Lighting")
local ServerStorage = game:GetService("ServerStorage")
local LIGHT_PROPS = {"LightingStyle", "PrioritizeLightingQuality", "Brightness", "Ambient", "OutdoorAmbient", "ClockTime",
	"GeographicLatitude", "ShadowSoftness", "EnvironmentDiffuseScale", "EnvironmentSpecularScale", "GlobalShadows",
	"ExposureCompensation", "ColorShift_Top", "ColorShift_Bottom", "FogEnd", "FogStart", "FogColor"}
local EFFECT_CLASSES = {Atmosphere = true, Sky = true, BloomEffect = true, SunRaysEffect = true,
	ColorCorrectionEffect = true, DepthOfFieldEffect = true}
local log = {}

local function setProp(obj, prop, value)
	if typeof(value) == "string" and prop == "LightingStyle" then value = Enum.LightingStyle[value] end
	local ok, err = pcall(function() obj[prop] = value end)
	if not ok then table.insert(log, ("skip %s.%s (%s)"):format(obj.Name, prop, tostring(err):sub(1, 60))) end
end

local function backupRoot()
	local root = ServerStorage:FindFirstChild("LightingBackups")
	if not root then
		root = Instance.new("Folder")
		root.Name = "LightingBackups"
		root.Parent = ServerStorage
	end
	return root
end

local function backup(tag)
	local root = backupRoot()
	if root:FindFirstChild(tag) then return root[tag], false end
	local f = Instance.new("Folder")
	f.Name = tag
	for _, p in LIGHT_PROPS do
		local ok, v = pcall(function() return Lighting[p] end)
		if ok then
			if typeof(v) == "EnumItem" then v = v.Name end
			pcall(function() f:SetAttribute(p, v) end)
		end
	end
	for _, k in Lighting:GetChildren() do
		if EFFECT_CLASSES[k.ClassName] then
			local ok, c = pcall(function() return k:Clone() end)
			if ok and c then c.Parent = f end
		end
	end
	f:SetAttribute("_madeAt", os.date("!%Y-%m-%d %H:%M UTC"))
	f.Parent = root
	return f, true
end

local function findOrMake(class, name)
	local obj = (name and Lighting:FindFirstChild(name)) or Lighting:FindFirstChildOfClass(class)
	if not obj then
		obj = Instance.new(class)
		obj.Name = name or class
		obj.Parent = Lighting
		table.insert(log, "made " .. obj.Name)
	end
	return obj
end

local function apply(p)
	for k, v in p.lighting or {} do setProp(Lighting, k, v) end
	local map = {atmosphere = {"Atmosphere"}, bloom = {"BloomEffect"}, sunrays = {"SunRaysEffect"},
		cc = {"ColorCorrectionEffect", CC_NAME}, dof = {"DepthOfFieldEffect"}, sky = {"Sky"}}
	for key, spec in map do
		local props = p[key]
		if props then
			local existing = (spec[2] and Lighting:FindFirstChild(spec[2])) or Lighting:FindFirstChildOfClass(spec[1])
			-- don't create an effect only to switch it off
			if existing or props.Enabled ~= false then
				local obj = existing or findOrMake(spec[1], spec[2])
				for k, v in props do setProp(obj, k, v) end
			end
		end
	end
end

-- Restore copies values onto the EXISTING objects (same name + class) instead of swapping objects: runtime scripts
-- (zone moods, cutscene grades) hold references to them, and a new object would leave those scripts tweening a
-- destroyed one. Objects missing from Lighting are cloned back; effects the preset added are removed.
local COPY_PROPS = {
	Atmosphere = {"Density", "Offset", "Color", "Decay", "Glare", "Haze"},
	BloomEffect = {"Enabled", "Intensity", "Size", "Threshold"},
	SunRaysEffect = {"Enabled", "Intensity", "Spread"},
	ColorCorrectionEffect = {"Enabled", "Brightness", "Contrast", "Saturation", "TintColor"},
	DepthOfFieldEffect = {"Enabled", "FarIntensity", "FocusDistance", "InFocusRadius", "NearIntensity"},
	Sky = {"CelestialBodiesShown", "StarCount", "SunAngularSize", "MoonAngularSize", "SkyboxOrientation", "SkyboxBk",
		"SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp", "SunTextureId", "MoonTextureId"},
}
local function restore(tag)
	local f = backupRoot():FindFirstChild(tag)
	if not f then return "no backup named " .. tag end
	local keep = {}
	for _, saved in f:GetChildren() do
		local live = Lighting:FindFirstChild(saved.Name)
		if live and live.ClassName == saved.ClassName then
			for _, p in COPY_PROPS[saved.ClassName] or {} do
				local ok, v = pcall(function() return saved[p] end)
				if ok then setProp(live, p, v) end
			end
		else
			live = saved:Clone()
			live.Parent = Lighting
			table.insert(log, "put back " .. live.Name)
		end
		keep[live] = true
	end
	for _, k in Lighting:GetChildren() do
		if EFFECT_CLASSES[k.ClassName] and not keep[k] then
			table.insert(log, "removed " .. k.Name .. " (not in the backup)")
			k:Destroy()
		end
	end
	for p, v in f:GetAttributes() do
		if p:sub(1, 1) ~= "_" then setProp(Lighting, p, v) end
	end
	return "restored " .. tag
end

if MODE == "LIST" then
	local names = {}
	for _, f in backupRoot():GetChildren() do table.insert(names, f.Name .. " (" .. tostring(f:GetAttribute("_madeAt")) .. ")") end
	return #names > 0 and table.concat(names, "\n") or "no backups"
elseif MODE == "RESTORE" then
	local msg = restore(TAG)
	return msg .. (#log > 0 and ("\n" .. table.concat(log, "\n")) or "")
else
	local p = PRESETS[PRESET]
	if not p then return "unknown preset " .. tostring(PRESET) end
	local f, made = backup(TAG)
	apply(p)
	return ("applied %s; backup %s %s\nTechnology: set by hand in Properties if the preset needs Future.\n%s"):format(
		PRESET, made and "saved as" or "already existed:", f:GetFullName(), table.concat(log, "\n"))
end
