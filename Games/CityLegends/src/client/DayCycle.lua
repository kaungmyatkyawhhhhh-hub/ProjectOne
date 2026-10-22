--[[
	DayCycle (client)
	Time of day (owner, 2026-10-22: "add time throughout the day like morning, evening, sunset and
	night"). The clock runs from the server's time, so everyone has the same hour; one full day takes
	Config.DayCycle.CycleMinutes. The sky, sun and moon follow the clock, and the light is blended
	between keyframes: a blue moonlit night (the game's own look), a pink dawn, a bright morning and
	day, a gold and orange sunset, a violet dusk. Weather lays its rain mood on top (setBaseLighting).
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Weather = require(script.Parent:WaitForChild("Weather"))

local DayCycle = {}

type Key = {
	hour: number,
	brightness: number,
	ambient: Color3,
	outdoor: Color3,
	shiftTop: Color3,
	exposure: number,
	density: number,
	haze: number,
	glare: number,
	atmo: Color3,
	decay: Color3,
	bloom: number,
	rays: number,
	tint: Color3,
}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

-- the night matches CityBuilder.setupLighting (the game's rainy neon night)
local NIGHT: Key = { hour = 0, brightness = 2.3, ambient = rgb(98, 102, 122), outdoor = rgb(116, 124, 164), shiftTop = rgb(120, 140, 200), exposure = 0.75, density = 0.3, haze = 1.2, glare = 0.25, atmo = rgb(86, 100, 148), decay = rgb(40, 46, 84), bloom = 0.7, rays = 0.03, tint = rgb(236, 242, 255) }
local KEYS: { Key } = {
	NIGHT,
	table.freeze({ hour = 4.6, brightness = 2.3, ambient = rgb(98, 102, 122), outdoor = rgb(116, 124, 164), shiftTop = rgb(120, 140, 200), exposure = 0.75, density = 0.3, haze = 1.2, glare = 0.25, atmo = rgb(86, 100, 148), decay = rgb(40, 46, 84), bloom = 0.7, rays = 0.03, tint = rgb(236, 242, 255) }),
	-- dawn: pink and lilac
	{ hour = 6, brightness = 2.5, ambient = rgb(112, 100, 108), outdoor = rgb(150, 128, 136), shiftTop = rgb(255, 170, 150), exposure = 0.45, density = 0.34, haze = 1.8, glare = 0.7, atmo = rgb(224, 168, 160), decay = rgb(120, 90, 120), bloom = 0.55, rays = 0.12, tint = rgb(255, 238, 236) },
	-- morning: clear and fresh
	{ hour = 8.5, brightness = 3, ambient = rgb(118, 120, 128), outdoor = rgb(146, 150, 162), shiftTop = rgb(255, 236, 214), exposure = 0.1, density = 0.28, haze = 1.2, glare = 0.35, atmo = rgb(196, 208, 230), decay = rgb(110, 128, 168), bloom = 0.35, rays = 0.08, tint = rgb(255, 252, 246) },
	-- day: bright, a little haze over the far towers
	{ hour = 13, brightness = 3.2, ambient = rgb(124, 124, 130), outdoor = rgb(150, 152, 160), shiftTop = rgb(255, 248, 236), exposure = 0, density = 0.25, haze = 1, glare = 0.2, atmo = rgb(204, 216, 240), decay = rgb(120, 140, 180), bloom = 0.3, rays = 0.05, tint = rgb(255, 255, 252) },
	{ hour = 16.5, brightness = 3, ambient = rgb(126, 118, 116), outdoor = rgb(156, 146, 140), shiftTop = rgb(255, 222, 180), exposure = 0.08, density = 0.27, haze = 1.2, glare = 0.4, atmo = rgb(226, 206, 190), decay = rgb(130, 120, 150), bloom = 0.35, rays = 0.1, tint = rgb(255, 246, 232) },
	-- sunset: gold to orange, long shadows
	{ hour = 18.3, brightness = 2.6, ambient = rgb(122, 96, 98), outdoor = rgb(172, 122, 108), shiftTop = rgb(255, 150, 90), exposure = 0.25, density = 0.36, haze = 2, glare = 1, atmo = rgb(255, 156, 108), decay = rgb(150, 76, 92), bloom = 0.5, rays = 0.18, tint = rgb(255, 228, 206) },
	-- dusk: violet, the neon coming up
	{ hour = 19.6, brightness = 2.2, ambient = rgb(92, 86, 116), outdoor = rgb(112, 104, 152), shiftTop = rgb(170, 120, 200), exposure = 0.6, density = 0.33, haze = 1.6, glare = 0.5, atmo = rgb(140, 108, 172), decay = rgb(60, 50, 104), bloom = 0.65, rays = 0.06, tint = rgb(240, 236, 255) },
	table.freeze({ hour = 21, brightness = 2.3, ambient = rgb(98, 102, 122), outdoor = rgb(116, 124, 164), shiftTop = rgb(120, 140, 200), exposure = 0.75, density = 0.3, haze = 1.2, glare = 0.25, atmo = rgb(86, 100, 148), decay = rgb(40, 46, 84), bloom = 0.7, rays = 0.03, tint = rgb(236, 242, 255) }),
}

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

-- the light at an hour: the two keyframes round it, blended smoothly
local function sample(hour: number): Key
	local a, b = KEYS[#KEYS], KEYS[1]
	local ha, hb = a.hour - 24, b.hour
	for k = 1, #KEYS do
		local nk = KEYS[k % #KEYS + 1]
		local nh = if k == #KEYS then nk.hour + 24 else nk.hour
		if hour >= KEYS[k].hour and hour < nh then
			a, b, ha, hb = KEYS[k], nk, KEYS[k].hour, nh
			break
		end
	end
	local t = math.clamp((hour - ha) / math.max(hb - ha, 1e-3), 0, 1)
	t = t * t * (3 - 2 * t)
	return {
		hour = hour,
		brightness = lerp(a.brightness, b.brightness, t),
		ambient = a.ambient:Lerp(b.ambient, t),
		outdoor = a.outdoor:Lerp(b.outdoor, t),
		shiftTop = a.shiftTop:Lerp(b.shiftTop, t),
		exposure = lerp(a.exposure, b.exposure, t),
		density = lerp(a.density, b.density, t),
		haze = lerp(a.haze, b.haze, t),
		glare = lerp(a.glare, b.glare, t),
		atmo = a.atmo:Lerp(b.atmo, t),
		decay = a.decay:Lerp(b.decay, t),
		bloom = lerp(a.bloom, b.bloom, t),
		rays = lerp(a.rays, b.rays, t),
		tint = a.tint:Lerp(b.tint, t),
	}
end

-- the hour now (0 - 24), the same for everyone
function DayCycle.hour(): number
	local c = Config.DayCycle
	local minutes = workspace:GetServerTimeNow() / 60
	return (minutes / c.CycleMinutes * 24 + c.StartHour) % 24
end

-- the part of the day, for the HUD
function DayCycle.phase(hour: number?): string
	local h = hour or DayCycle.hour()
	if h >= 5 and h < 9 then
		return "MORNING"
	elseif h >= 9 and h < 17 then
		return "DAY"
	elseif h >= 17 and h < 19.6 then
		return "SUNSET"
	elseif h >= 19.6 and h < 21 then
		return "EVENING"
	end
	return "NIGHT"
end

function DayCycle.start()
	if not Config.DayCycle.Enabled then
		return
	end
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
	local rays = Lighting:FindFirstChildOfClass("SunRaysEffect")
	local grade: ColorCorrectionEffect? = nil
	for _, c in Lighting:GetChildren() do
		if c:IsA("ColorCorrectionEffect") and c.Name ~= "WeatherGrade" then
			grade = c
		end
	end
	local acc = math.huge
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		-- the sun creeps; the rest of the light only needs a few updates a second
		local hour = DayCycle.hour()
		Lighting.ClockTime = hour
		if acc < 0.25 then
			return
		end
		acc = 0
		local k = sample(hour)
		Lighting.Brightness = k.brightness
		Lighting.Ambient = k.ambient
		Lighting.ColorShift_Top = k.shiftTop
		if bloom and bloom.Parent then
			bloom.Intensity = k.bloom
		end
		if rays and rays.Parent then
			rays.Intensity = k.rays
		end
		if grade and grade.Parent then
			grade.TintColor = k.tint
		end
		local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
		if atmo then
			atmo.Glare = k.glare
		end
		-- haze, exposure and the outdoor light go through Weather, which adds the rain on top
		Weather.setBaseLighting({
			density = k.density,
			haze = k.haze,
			atmoColor = k.atmo,
			decay = k.decay,
			exposure = k.exposure,
			outdoor = k.outdoor,
		})
	end)
end

return DayCycle
