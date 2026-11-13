--!nocheck
-- lighting_snapshot.luau (roblox-game-lighting skill). READ-ONLY.
-- Run with the Studio MCP execute_luau, in Edit (the saved look) or Client during Play (the runtime look,
-- after zone/biome/day-night scripts have run). Returns a text report: every Lighting property that matters,
-- every post effect (Lighting and Camera), sky, clouds, light/shadow counts, and a RISKS list.
-- Paste the output into the change log before you change anything: it is the "old look".

local Lighting = game:GetService("Lighting")
local out, risks = {}, {}

local function c3(c)
	return ("(%d,%d,%d)"):format(math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end
local function get(obj, prop)
	local ok, v = pcall(function() return obj[prop] end)
	if not ok then return "n/a" end
	if typeof(v) == "Color3" then return c3(v) end
	if typeof(v) == "number" then return (math.abs(v) >= 100 and ("%d"):format(v)) or ("%.3g"):format(v) end
	return tostring(v)
end
local function line(obj, props)
	local parts = {}
	for _, p in props do table.insert(parts, p .. "=" .. get(obj, p)) end
	table.insert(out, ("%s [%s]: %s"):format(obj:GetFullName(), obj.ClassName, table.concat(parts, "  ")))
end
local function risk(s) table.insert(risks, s) end
local function lum(c) return 0.2126 * c.R + 0.7152 * c.G + 0.0722 * c.B end

line(Lighting, {"LightingStyle", "PrioritizeLightingQuality", "Brightness", "Ambient", "OutdoorAmbient", "ClockTime",
	"GeographicLatitude", "ShadowSoftness", "EnvironmentDiffuseScale", "EnvironmentSpecularScale", "ExposureCompensation",
	"GlobalShadows", "FogEnd", "ColorShift_Top", "ColorShift_Bottom"})
table.insert(out, "Technology: not readable from the plugin, check it in the Properties panel")

local counts = {}
local function scan(container)
	for _, k in container:GetChildren() do
		counts[k.ClassName] = (counts[k.ClassName] or 0) + 1
		if k:IsA("Atmosphere") then
			line(k, {"Density", "Offset", "Color", "Decay", "Glare", "Haze"})
			if k.Density > 0.5 then risk("Atmosphere Density " .. ("%.2f"):format(k.Density) .. " > 0.5: grey wall on land maps (fine for horror)") end
		elseif k:IsA("BloomEffect") then
			line(k, {"Enabled", "Intensity", "Size", "Threshold"})
			if k.Enabled and k.Threshold < 1 and k.Intensity > 0.6 then risk(k.Name .. ": Bloom Threshold < 1 with Intensity > 0.6, white parts will glow") end
		elseif k:IsA("SunRaysEffect") then
			line(k, {"Enabled", "Intensity", "Spread"})
			if k.Enabled and k.Intensity > 0.15 then risk(k.Name .. ": SunRays Intensity > 0.15, streaks during play") end
		elseif k:IsA("ColorCorrectionEffect") then
			line(k, {"Enabled", "Brightness", "Contrast", "Saturation", "TintColor"})
			if k.Enabled and k.Saturation > 0.55 then risk(k.Name .. ": Saturation > 0.55 looks cheap") end
			local t = k.TintColor
			if k.Enabled and math.min(t.R, t.G, t.B) < 215 / 255 then risk(k.Name .. ": a TintColor channel below 215, filter look") end
		elseif k:IsA("DepthOfFieldEffect") then
			line(k, {"Enabled", "FarIntensity", "FocusDistance", "InFocusRadius", "NearIntensity"})
			if k.Enabled and k.FarIntensity > 0.25 then risk(k.Name .. ": DepthOfField FarIntensity > 0.25 blurs gameplay at range") end
		elseif k:IsA("BlurEffect") then
			line(k, {"Enabled", "Size"})
			if k.Enabled and k.Size > 0 and container == Lighting then risk(k.Name .. ": a BlurEffect is on in the world (UI backdrop left on?)") end
		elseif k:IsA("Sky") then
			line(k, {"CelestialBodiesShown", "StarCount", "SunAngularSize", "MoonAngularSize", "SkyboxOrientation", "SkyboxUp"})
		elseif k:IsA("PostEffect") then
			line(k, {"Enabled"})
		end
	end
end
scan(Lighting)
local cam = workspace.CurrentCamera
if cam then scan(cam) end

for cls, n in counts do
	if n > 1 and (cls == "ColorCorrectionEffect" or cls == "BloomEffect" or cls == "Atmosphere" or cls == "Sky" or cls == "SunRaysEffect") then
		risk(("%d %s objects: they stack or fight; name them by job (base, zone, cutscene, hit flash)"):format(n, cls))
	end
end
if not counts.Atmosphere then risk("No Atmosphere: grey default horizon (FogEnd is used instead)") end
if not counts.ColorCorrectionEffect then risk("No ColorCorrection: no grade, usually looks flat") end
if not counts.Sky then risk("No Sky: the default sky") end

local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
if clouds then line(clouds, {"Enabled", "Cover", "Density", "Color"}) end

if not Lighting.GlobalShadows then risk("GlobalShadows off: no depth") end
if Lighting.Brightness > 3.5 then risk("Brightness > 3.5: whites clip") end
if Lighting.Brightness < 0.8 then risk("Brightness < 0.8: too dark on phones") end
if lum(Lighting.Ambient) < 0.12 then risk("Ambient " .. c3(Lighting.Ambient) .. " very dark: black shadows, unreadable on phones") end
local a = Lighting.Ambient
if math.abs(a.R - a.G) < 0.02 and math.abs(a.G - a.B) < 0.02 then risk("Ambient is grey " .. c3(a) .. ": give shadows a colour") end
if math.abs(Lighting.ExposureCompensation) > 0.5 then risk("ExposureCompensation beyond ±0.5: fix Brightness/Ambient instead") end

-- lights and shadow cost
local lights, shadowLights, neon, textures = 0, 0, 0, 0
for _, d in workspace:GetDescendants() do
	if d:IsA("Light") then
		lights += 1
		if d.Enabled and d.Shadows then shadowLights += 1 end
	elseif d:IsA("BasePart") and d.Material == Enum.Material.Neon then
		neon += 1
	elseif d:IsA("Texture") then
		textures += 1
	end
end
table.insert(out, ("Workspace: %d lights (%d with shadows), %d Neon parts, %d Textures"):format(lights, shadowLights, neon, textures))
if shadowLights > 40 then risk(shadowLights .. " lights cast shadows: heavy on Future, phones drop them") end

-- who else changes lighting at runtime (names only; read them with script_read)
local owners = {}
for _, s in game:GetDescendants() do
	-- ServerStorage is skipped: that's where script backups live, and they don't run
	if s:IsA("LuaSourceContainer") and not s:IsDescendantOf(game:GetService("ServerStorage")) then
		local ok, src = pcall(function() return s.Source end)
		if ok and src and (src:find("Lighting") and (src:find("ColorCorrection") or src:find("Atmosphere") or src:find("ClockTime") or src:find("Bloom"))) then
			table.insert(owners, s:GetFullName())
		end
	end
end
table.insert(out, "Scripts that touch lighting: " .. (#owners > 0 and table.concat(owners, ", ") or "none"))

table.insert(out, "")
table.insert(out, #risks == 0 and "RISKS: none" or ("RISKS (" .. #risks .. "):\n- " .. table.concat(risks, "\n- ")))
return table.concat(out, "\n")
