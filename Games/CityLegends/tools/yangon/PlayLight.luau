--[[
	PlayLight.luau (Studio, Edit): sets the Edit place's lighting to what DayCycle + Weather give a
	player in Yangon (clear weather, default Look settings, the REAL grade) at an hour, so Edit
	screenshots and colour checks match Play. M.apply(hour) saves the Edit lighting first (Lighting
	attribute EditLight), M.restore() puts it back. Keys copied from client/DayCycle.lua RIVIERA_KEYS
	(keep them in step if those change).
]]
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local RS = game:GetService("ReplicatedStorage")

local M = {}
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end
local R_NIGHT = { brightness = 1.3, ambient = rgb(74, 86, 124), outdoor = rgb(88, 104, 154), shiftTop = rgb(110, 124, 170), exposure = 0.66, density = 0.2, haze = 0.4, glare = 0, atmo = rgb(34, 50, 96), decay = rgb(18, 28, 66), bloom = 0.32, rays = 0, tint = rgb(255, 242, 226), sat = 0.06, con = 0.1, soft = 0.12, offset = 0.12 }
local function with(k, h)
	local c = table.clone(k)
	c.hour = h
	return c
end
local KEYS = {
	with(R_NIGHT, 0),
	with(R_NIGHT, 4.6),
	{ hour = 6, brightness = 2.2, ambient = rgb(122, 120, 132), outdoor = rgb(158, 154, 166), shiftTop = rgb(255, 214, 190), exposure = 0.3, density = 0.3, haze = 1.8, glare = 0.3, atmo = rgb(226, 214, 216), decay = rgb(170, 160, 176), bloom = 0.3, rays = 0.04, tint = rgb(252, 244, 244), sat = 0.04, con = -0.05, soft = 0.4, offset = 0.12 },
	{ hour = 7.2, brightness = 2.5, ambient = rgb(150, 158, 174), outdoor = rgb(174, 186, 206), shiftTop = rgb(232, 236, 248), exposure = 0.2, density = 0.33, haze = 2.3, glare = 0.1, atmo = rgb(220, 224, 230), decay = rgb(186, 192, 204), bloom = 0.2, rays = 0.02, tint = rgb(244, 247, 255), sat = 0.01, con = -0.09, soft = 0.5, offset = 0.12 },
	{ hour = 8.5, brightness = 2.83, ambient = rgb(156, 163, 178), outdoor = rgb(179, 191, 209), shiftTop = rgb(238, 240, 248), exposure = 0.12, density = 0.3, haze = 2, glare = 0.1, atmo = rgb(222, 224, 226), decay = rgb(196, 198, 204), bloom = 0.2, rays = 0.02, tint = rgb(246, 248, 255), sat = 0.02, con = -0.09, soft = 0.45, offset = 0.12 },
	{ hour = 13, brightness = 3.15, ambient = rgb(154, 161, 176), outdoor = rgb(177, 188, 206), shiftTop = rgb(246, 246, 250), exposure = 0.06, density = 0.25, haze = 1.5, glare = 0.15, atmo = rgb(222, 228, 236), decay = rgb(170, 186, 208), bloom = 0.2, rays = 0.03, tint = rgb(250, 251, 255), sat = 0.06, con = -0.05, soft = 0.35, offset = 0.12 },
	{ hour = 16.5, brightness = 3.1, ambient = rgb(146, 142, 146), outdoor = rgb(170, 162, 160), shiftTop = rgb(255, 230, 196), exposure = 0.06, density = 0.22, haze = 0.9, glare = 0.35, atmo = rgb(230, 216, 200), decay = rgb(160, 146, 160), bloom = 0.25, rays = 0.08, tint = rgb(255, 246, 232), sat = 0.08, con = 0.02, soft = 0.22, offset = 0.15 },
	{ hour = 17.3, brightness = 2.55, ambient = rgb(207, 195, 207), outdoor = rgb(252, 238, 240), shiftTop = rgb(255, 200, 165), exposure = 0.24, density = 0.12, haze = 1, glare = 0.25, atmo = rgb(240, 214, 204), decay = rgb(190, 150, 160), bloom = 0.24, rays = 0.16, tint = rgb(255, 246, 238), sat = 0.09, con = 0.08, soft = 0.12, offset = 0.18 },
	{ hour = 18.3, brightness = 2.6, ambient = rgb(210, 178, 183), outdoor = rgb(255, 220, 208), shiftTop = rgb(255, 170, 120), exposure = 0.5, density = 0.12, haze = 1.2, glare = 0.4, atmo = rgb(245, 196, 170), decay = rgb(170, 110, 120), bloom = 0.24, rays = 0.15, tint = rgb(255, 238, 220), sat = 0.11, con = 0.08, soft = 0.12, offset = 0.2 },
	{ hour = 19.6, brightness = 1.7, ambient = rgb(96, 108, 148), outdoor = rgb(116, 132, 182), shiftTop = rgb(120, 140, 210), exposure = 0.72, density = 0.22, haze = 0.5, glare = 0.2, atmo = rgb(62, 86, 152), decay = rgb(36, 52, 112), bloom = 0.35, rays = 0, tint = rgb(246, 244, 255), sat = 0.08, con = 0.05, soft = 0.12, offset = 0.12 },
	with(R_NIGHT, 21),
}
local REAL = { sat = 0.16, con = 0.05, density = 0.08, hazeMin = 0.7, bloom = 0.75, brightness = 0.92, shade = 0.18 }
local SUN_CLOCK = { { 0, 0 }, { 16.5, 16.5 }, { 18.3, 17.72 }, { 19.6, 18.32 }, { 21, 19.3 }, { 24, 24 } }

local function sample(hour)
	local a, b, ha, hb = KEYS[#KEYS], KEYS[1], KEYS[#KEYS].hour, 24
	for k = 1, #KEYS do
		local nk = KEYS[k % #KEYS + 1]
		local nh = if k == #KEYS then 24 else nk.hour
		if hour >= KEYS[k].hour and hour < nh then
			a, b, ha, hb = KEYS[k], nk, KEYS[k].hour, nh
			break
		end
	end
	local t = if hb > ha then (hour - ha) / (hb - ha) else 0
	local r = {}
	for key, v in a do
		local w = b[key]
		if typeof(v) == "Color3" then
			r[key] = v:Lerp(w, t)
		elseif type(v) == "number" then
			r[key] = v + (w - v) * t
		end
	end
	return r
end

local PROPS = { "Brightness", "Ambient", "OutdoorAmbient", "ExposureCompensation", "ColorShift_Top", "ShadowSoftness", "ClockTime", "EnvironmentDiffuseScale", "EnvironmentSpecularScale", "GlobalShadows" }

function M.apply(hour)
	if not Lighting:GetAttribute("EditLight") then
		local s = {}
		for _, p in PROPS do
			local v = (Lighting :: any)[p]
			s[p] = if typeof(v) == "Color3" then { v.R, v.G, v.B } else v
		end
		local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
		if atmo then
			s.atmo = { atmo.Density, atmo.Haze, atmo.Glare, atmo.Offset, { atmo.Color.R, atmo.Color.G, atmo.Color.B }, { atmo.Decay.R, atmo.Decay.G, atmo.Decay.B } }
		end
		for _, c in Lighting:GetChildren() do
			if c:IsA("ColorCorrectionEffect") then
				s["cc_" .. c.Name] = { c.Brightness, c.Contrast, c.Saturation, { c.TintColor.R, c.TintColor.G, c.TintColor.B }, c.Enabled }
			elseif c:IsA("BloomEffect") then
				s.bloom = c.Intensity
			elseif c:IsA("SunRaysEffect") then
				s.rays = c.Intensity
			end
		end
		local sky = Lighting:FindFirstChildOfClass("Sky")
		if sky then
			s.sky = { sky.SkyboxBk, sky.SkyboxDn, sky.SkyboxFt, sky.SkyboxLf, sky.SkyboxRt, sky.SkyboxUp }
		end
		Lighting:SetAttribute("EditLight", HttpService:JSONEncode(s))
	end
	local k = sample(hour)
	k.sat -= REAL.sat
	k.con += REAL.con
	k.density += REAL.density
	k.haze = math.max(k.haze, REAL.hazeMin)
	k.bloom *= REAL.bloom
	k.brightness *= REAL.brightness
	k.ambient = k.ambient:Lerp(Color3.new(0, 0, 0), REAL.shade)
	k.outdoor = k.outdoor:Lerp(Color3.new(0, 0, 0), REAL.shade * 0.6)
	local clock = hour
	for i = 2, #SUN_CLOCK do
		local a, b = SUN_CLOCK[i - 1], SUN_CLOCK[i]
		if hour <= b[1] then
			clock = a[2] + (b[2] - a[2]) * (hour - a[1]) / (b[1] - a[1])
			break
		end
	end
	Lighting.ClockTime = clock
	Lighting.Brightness = k.brightness
	Lighting.Ambient = k.ambient
	Lighting.OutdoorAmbient = k.outdoor
	Lighting.ExposureCompensation = k.exposure
	Lighting.ColorShift_Top = k.shiftTop
	Lighting.ShadowSoftness = k.soft
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	Lighting.GlobalShadows = true
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmo then
		atmo.Density, atmo.Haze, atmo.Glare, atmo.Offset = k.density, k.haze, k.glare, k.offset
		atmo.Color, atmo.Decay = k.atmo, k.decay
	end
	for _, c in Lighting:GetChildren() do
		if c:IsA("ColorCorrectionEffect") then
			if c.Name == "WeatherGrade" then
				c.Brightness, c.Contrast, c.Saturation, c.TintColor = 0, 0, 0, Color3.new(1, 1, 1)
			else
				c.TintColor, c.Saturation, c.Contrast = k.tint, k.sat, k.con
				c.Enabled = true
			end
		elseif c:IsA("BloomEffect") then
			c.Intensity = k.bloom
		elseif c:IsA("SunRaysEffect") then
			c.Intensity = k.rays
		end
	end
	local name = if hour >= 16.9 and hour < 19.2 then "Sunset" elseif hour >= 5 and hour < 6.8 then "Dusk" else "Day"
	local src = RS:FindFirstChild("RivieraSkies") and RS.RivieraSkies:FindFirstChild(name)
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if src and sky then
		for _, f in { "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp" } do
			(sky :: any)[f] = (src :: any)[f]
		end
	end
	return string.format("hour %.1f clock %.2f bright %.2f exp %.2f sky %s", hour, clock, k.brightness, k.exposure, tostring(src and name))
end

function M.restore()
	local j = Lighting:GetAttribute("EditLight")
	if not j then
		return "nothing saved"
	end
	local s = HttpService:JSONDecode(j)
	for _, p in PROPS do
		local v = s[p]
		if type(v) == "table" then
			v = Color3.new(v[1], v[2], v[3])
		end
		(Lighting :: any)[p] = v
	end
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmo and s.atmo then
		local a = s.atmo
		atmo.Density, atmo.Haze, atmo.Glare, atmo.Offset = a[1], a[2], a[3], a[4]
		atmo.Color, atmo.Decay = Color3.new(table.unpack(a[5])), Color3.new(table.unpack(a[6]))
	end
	for _, c in Lighting:GetChildren() do
		local cc = s["cc_" .. c.Name]
		if c:IsA("ColorCorrectionEffect") and cc then
			c.Brightness, c.Contrast, c.Saturation, c.TintColor, c.Enabled = cc[1], cc[2], cc[3], Color3.new(table.unpack(cc[4])), cc[5]
		elseif c:IsA("BloomEffect") and s.bloom then
			c.Intensity = s.bloom
		elseif c:IsA("SunRaysEffect") and s.rays then
			c.Intensity = s.rays
		end
	end
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if sky and s.sky then
		for i, f in { "SkyboxBk", "SkyboxDn", "SkyboxFt", "SkyboxLf", "SkyboxRt", "SkyboxUp" } do
			(sky :: any)[f] = s.sky[i]
		end
	end
	Lighting:SetAttribute("EditLight", nil)
	return "restored"
end

return M
