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
local WorldFx = require(script.Parent:WaitForChild("WorldFx"))
local BuildingSkin = require(script.Parent:WaitForChild("BuildingSkin"))

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
	water: Color3,
}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

-- the night matches CityBuilder.setupLighting (the game's rainy neon night)
local NIGHT: Key = { hour = 0, brightness = 2.3, ambient = rgb(96, 98, 108), outdoor = rgb(108, 114, 136), shiftTop = rgb(150, 160, 190), exposure = 0.75, density = 0.3, haze = 1.2, glare = 0.25, atmo = rgb(96, 104, 128), decay = rgb(46, 50, 70), bloom = 0.45, rays = 0.03, tint = rgb(246, 248, 255), water = rgb(14, 34, 44) }
local KEYS: { Key } = {
	NIGHT,
	table.freeze({ hour = 4.6, brightness = 2.3, ambient = rgb(96, 98, 108), outdoor = rgb(108, 114, 136), shiftTop = rgb(150, 160, 190), exposure = 0.75, density = 0.3, haze = 1.2, glare = 0.25, atmo = rgb(96, 104, 128), decay = rgb(46, 50, 70), bloom = 0.45, rays = 0.03, tint = rgb(246, 248, 255), water = rgb(14, 34, 44) }),
	-- dawn: pink and lilac
	{ hour = 6, brightness = 2.5, ambient = rgb(108, 104, 106), outdoor = rgb(146, 136, 136), shiftTop = rgb(255, 170, 150), exposure = 0.45, density = 0.34, haze = 1.8, glare = 0.7, atmo = rgb(224, 168, 160), decay = rgb(120, 90, 120), bloom = 0.55, rays = 0.12, tint = rgb(255, 238, 236), water = rgb(40, 62, 78) },
	-- morning: clear and fresh
	{ hour = 8.5, brightness = 3, ambient = rgb(118, 120, 128), outdoor = rgb(146, 150, 162), shiftTop = rgb(255, 236, 214), exposure = 0.1, density = 0.28, haze = 1.2, glare = 0.35, atmo = rgb(196, 208, 230), decay = rgb(110, 128, 168), bloom = 0.35, rays = 0.08, tint = rgb(255, 252, 246), water = rgb(34, 92, 104) },
	-- day: bright, a little haze over the far towers
	{ hour = 13, brightness = 3.2, ambient = rgb(124, 124, 130), outdoor = rgb(150, 152, 160), shiftTop = rgb(255, 248, 236), exposure = 0, density = 0.25, haze = 1, glare = 0.2, atmo = rgb(204, 216, 240), decay = rgb(120, 140, 180), bloom = 0.3, rays = 0.05, tint = rgb(255, 255, 252), water = rgb(30, 100, 112) },
	{ hour = 16.5, brightness = 3, ambient = rgb(126, 118, 116), outdoor = rgb(156, 146, 140), shiftTop = rgb(255, 222, 180), exposure = 0.08, density = 0.27, haze = 1.2, glare = 0.4, atmo = rgb(226, 206, 190), decay = rgb(130, 120, 150), bloom = 0.35, rays = 0.1, tint = rgb(255, 246, 232), water = rgb(34, 88, 100) },
	-- sunset: gold to orange, long shadows
	{ hour = 18.3, brightness = 2.6, ambient = rgb(122, 96, 98), outdoor = rgb(172, 122, 108), shiftTop = rgb(255, 150, 90), exposure = 0.25, density = 0.36, haze = 2, glare = 1, atmo = rgb(255, 156, 108), decay = rgb(150, 76, 92), bloom = 0.5, rays = 0.18, tint = rgb(255, 228, 206), water = rgb(52, 60, 70) },
	-- dusk: violet, the neon coming up
	{ hour = 19.6, brightness = 2.2, ambient = rgb(92, 86, 116), outdoor = rgb(112, 104, 152), shiftTop = rgb(170, 120, 200), exposure = 0.6, density = 0.33, haze = 1.6, glare = 0.5, atmo = rgb(140, 108, 172), decay = rgb(60, 50, 104), bloom = 0.65, rays = 0.06, tint = rgb(240, 236, 255), water = rgb(26, 36, 56) },
	table.freeze({ hour = 21, brightness = 2.3, ambient = rgb(96, 98, 108), outdoor = rgb(108, 114, 136), shiftTop = rgb(150, 160, 190), exposure = 0.75, density = 0.3, haze = 1.2, glare = 0.25, atmo = rgb(96, 104, 128), decay = rgb(46, 50, 70), bloom = 0.45, rays = 0.03, tint = rgb(246, 248, 255), water = rgb(14, 34, 44) }),
}

-- the Riviera (the Monaco-shaped map east of X 9000, owner 2026-11-01 from his drive videos): a
-- crisp clear day with a deep blue sky and no haze, a gold sunset, a navy-blue "blue hour" and a
-- warm night lit by sodium lamps and windows. No neon. Blended in by the camera's position.
local function with(k: Key, hour: number): Key
	local c = table.clone(k)
	c.hour = hour
	return c
end
local R_NIGHT: Key = { hour = 0, brightness = 1.6, ambient = rgb(62, 68, 92), outdoor = rgb(72, 82, 120), shiftTop = rgb(120, 130, 170), exposure = 0.55, density = 0.22, haze = 0.6, glare = 0.1, atmo = rgb(40, 52, 92), decay = rgb(22, 30, 64), bloom = 0.6, rays = 0, tint = rgb(255, 244, 228), water = rgb(8, 22, 42) }
local RIVIERA_KEYS: { Key } = {
	R_NIGHT,
	table.freeze(with(R_NIGHT, 4.6)),
	{ hour = 6, brightness = 2.4, ambient = rgb(110, 104, 110), outdoor = rgb(150, 138, 140), shiftTop = rgb(255, 190, 150), exposure = 0.3, density = 0.24, haze = 1, glare = 0.6, atmo = rgb(230, 190, 170), decay = rgb(140, 110, 140), bloom = 0.45, rays = 0.1, tint = rgb(255, 240, 230), water = rgb(40, 80, 110) },
	{ hour = 8.5, brightness = 3.2, ambient = rgb(120, 122, 130), outdoor = rgb(150, 154, 165), shiftTop = rgb(255, 240, 220), exposure = 0.05, density = 0.18, haze = 0.25, glare = 0.3, atmo = rgb(190, 210, 240), decay = rgb(100, 130, 190), bloom = 0.25, rays = 0.06, tint = rgb(255, 252, 246), water = rgb(20, 110, 150) },
	{ hour = 13, brightness = 3.4, ambient = rgb(126, 126, 132), outdoor = rgb(152, 154, 164), shiftTop = rgb(255, 250, 238), exposure = 0, density = 0.16, haze = 0.2, glare = 0.2, atmo = rgb(200, 218, 245), decay = rgb(110, 140, 200), bloom = 0.25, rays = 0.04, tint = rgb(255, 255, 250), water = rgb(18, 112, 155) },
	{ hour = 16.5, brightness = 3.1, ambient = rgb(130, 122, 118), outdoor = rgb(160, 148, 138), shiftTop = rgb(255, 226, 186), exposure = 0.05, density = 0.18, haze = 0.4, glare = 0.4, atmo = rgb(230, 210, 190), decay = rgb(140, 130, 160), bloom = 0.3, rays = 0.1, tint = rgb(255, 246, 230), water = rgb(24, 100, 140) },
	{ hour = 18.3, brightness = 2.6, ambient = rgb(128, 100, 92), outdoor = rgb(176, 128, 104), shiftTop = rgb(255, 160, 100), exposure = 0.2, density = 0.25, haze = 0.9, glare = 0.9, atmo = rgb(255, 170, 120), decay = rgb(150, 90, 90), bloom = 0.45, rays = 0.15, tint = rgb(255, 232, 206), water = rgb(40, 70, 100) },
	-- blue hour: a navy sky over the dark mountain, the lamps and windows coming on
	{ hour = 19.6, brightness = 1.9, ambient = rgb(70, 78, 108), outdoor = rgb(84, 96, 140), shiftTop = rgb(110, 130, 200), exposure = 0.45, density = 0.22, haze = 0.6, glare = 0.3, atmo = rgb(52, 70, 128), decay = rgb(30, 40, 90), bloom = 0.6, rays = 0.02, tint = rgb(250, 244, 236), water = rgb(14, 34, 66) },
	table.freeze(with(R_NIGHT, 21)),
}
DayCycle.RIVIERA_X = 9000 -- east of this the camera is on the Riviera map

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

-- the light at an hour: the two keyframes round it, blended smoothly
local function sample(hour: number, keys: { Key }?): Key
	local KEYS = keys or KEYS
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
		water = a.water:Lerp(b.water, t),
	}
end

-- photo mode can hold the time of day (nil: the shared clock)
DayCycle.override = nil :: number?

-- the hour now (0 - 24), the same for everyone
function DayCycle.hour(): number
	if DayCycle.override then
		return DayCycle.override
	end
	local c = Config.DayCycle
	local minutes = workspace:GetServerTimeNow() / 60
	return (minutes / c.CycleMinutes * 24 + c.StartHour) % 24
end

-- how much of the night it is: 1 from late evening to dawn, 0 through the day, smooth between
function DayCycle.night(hour: number?): number
	local h = hour or DayCycle.hour()
	local function ramp(a: number, b: number): number
		local t = math.clamp((h - a) / (b - a), 0, 1)
		return t * t * (3 - 2 * t)
	end
	if h < 12 then
		return 1 - ramp(5.6, 7.6) -- dawn
	end
	return ramp(17.8, 19.9) -- dusk
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
	local lastNight = -1
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
		-- on the Riviera map its own light (blended over 1500 studs so it never pops)
		local cam = workspace.CurrentCamera
		local w = if cam then math.clamp((cam.CFrame.Position.X - (DayCycle.RIVIERA_X - 1500)) / 1500, 0, 1) else 0
		if w > 0 then
			local r = sample(hour, RIVIERA_KEYS)
			for key, v in r do
				local base = (k :: any)[key]
				if typeof(v) == "Color3" then
					(k :: any)[key] = base:Lerp(v, w)
				elseif type(v) == "number" and key ~= "hour" then
					(k :: any)[key] = base + (v - base) * w
				end
			end
		end
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
		workspace.Terrain.WaterColor = k.water
		local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
		if atmo then
			atmo.Glare = k.glare
		end
		-- lit windows and street lamps follow the night
		local n = DayCycle.night(hour)
		if math.abs(n - lastNight) > 0.04 or (n == 0 and lastNight ~= 0) or (n == 1 and lastNight ~= 1) then
			lastNight = n
			BuildingSkin.setNight(n)
			WorldFx.setDaylight(1 - n)
		end
		-- haze, exposure and the outdoor light go through Weather, which adds the rain on top; clouds
		-- are white and lighter by day, dark and fuller at night
		Weather.setBaseLighting({
			cloudColor = Color3.fromRGB(236, 238, 242):Lerp(Color3.fromRGB(56, 58, 74), n),
			cover = 0.48 + 0.12 * n,
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
