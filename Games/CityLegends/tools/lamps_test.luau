-- Lune test for src/client/CarLamps.lua (2026-11-21): no DRL on the old cars, lamp colour by model,
-- other players' reverse lamps, and every lamp set afresh when the driver gets in or out.
--   lune run tools/lamps_test.luau <path to Games/CityLegends>
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")

local root = process.args[1] or "."

local beat: (number) -> ()
local folder = { children = {} }
function folder:GetChildren()
	return self.children
end
local stubs = {
	Cars = { modelOf = function(id) return if id == "nisun_gtr_nismo" then "nisun_gtr" else id end },
	Config = {
		Lamps = { DrlCore = 0.35, DrlGlass = 0.72, LowGlass = 0.62, HighGlass = 0.5, Glass = {} },
		Customs = { Headlights = { white = { 255, 250, 240 }, warm = { 255, 212, 150 } } },
	},
	LookFx = { state = {} },
	WorldFx = { qualityScale = function() return 1 end },
}
local function child(name)
	return { WaitForChild = function(_, n) return n end, name = name }
end
local env = {
	game = { GetService = function(_, name)
		if name == "RunService" then
			return { Heartbeat = { Connect = function(_, fn) beat = fn end } }
		elseif name == "ReplicatedStorage" then
			return { WaitForChild = function() return child("Shared") end }
		end
		return { ClockTime = 12 }
	end },
	script = { Parent = child("Client") },
	require = function(name) return stubs[name] end,
	Color3 = { fromRGB = function(r, g, b) return { R = r / 255, G = g / 255, B = b / 255 } end },
	workspace = { FindFirstChild = function() return folder end, CurrentCamera = { CFrame = { Position = 0 } } },
	os = os, math = math, table = table, setmetatable = setmetatable, type = type,
}
local CarLamps = luau.load(fs.readFile(root .. "/src/client/CarLamps.lua"), { debugName = "CarLamps", environment = env })()

local fails = 0
local function check(name: string, ok: boolean)
	if not ok then
		fails += 1
		print("FAIL " .. name)
	end
end

-- the pure lookups
check("ae86 drl -> off", CarLamps.shown("toyoka_ae86", "drl") == "off")
check("ae86 low stays", CarLamps.shown("toyoka_ae86", "low") == "low")
check("r8 drl stays", CarLamps.shown("audy_r8", "drl") == "drl")
local C = env.Color3.fromRGB
local function rgb(c)
	return math.round(c.R * 255) .. "," .. math.round(c.G * 255) .. "," .. math.round(c.B * 255)
end
check("halogen", rgb(CarLamps.colourOf("toyoka_ae86", nil)) == "255,214,160")
check("xenon over the box car's light", rgb(CarLamps.colourOf("audy_r8", C(232, 240, 255))) == "240,246,255")
check("led over Customs white", rgb(CarLamps.colourOf("porsha_gt3", C(255, 250, 240))) == "228,238,255")
check("a bought Customs colour wins", rgb(CarLamps.colourOf("porsha_gt3", C(255, 212, 150))) == "255,212,150")
check("no tint: as before", rgb(CarLamps.colourOf("pleiad_gc8", C(232, 240, 255))) == "232,240,255")
check("no tint, no light: white", rgb(CarLamps.colourOf("pleiad_gc8", nil)) == "255,252,244")
for id in CarLamps.TINT do
	check("tint only on a lamp car: " .. id, CarLamps.CARS[id] == true)
end
for id in CarLamps.NO_DRL do
	check("no-DRL only on a lamp car: " .. id, CarLamps.CARS[id] == true)
end
check("pleiad_gc8 kept", CarLamps.CARS.pleiad_gc8 == true)

-- a car in PlayerCars, lamps as shells
local function car(id: string)
	local attrs = { CarId = id, Beam = "off" }
	local parts = {}
	local list = {}
	for _, name in { "HeadCoreL", "HeadCoreR", "RevL", "RevR" } do
		local p = { Transparency = 0.9, src = "LampFx_" .. name }
		function p:IsA(class) return class == "BasePart" end
		function p:GetAttribute(a) return if a == "SrcName" then self.src else nil end
		parts[name] = p
		table.insert(list, p)
	end
	local model = { PrimaryPart = {}, Parent = folder, attrs = attrs, parts = parts }
	function model:IsA(class) return class == "Model" end
	function model:GetAttribute(a) return self.attrs[a] end
	function model:GetDescendants() return list end
	table.insert(folder.children, model)
	return model
end
local old, r8 = car("toyoka_ae86"), car("audy_r8")
old.attrs.Beam, old.attrs.Rev = "drl", true
r8.attrs.Beam = "drl"
beat(1)
check("another player's ae86: no DRL", old.parts.HeadCoreL.Transparency == 1)
check("another player's reverse lamp", old.parts.RevL.Transparency == 0 and old.parts.RevR.Transparency == 0)
check("another player's r8: DRL, xenon", r8.parts.HeadCoreL.Transparency == 0.35 and rgb(r8.parts.HeadCoreL.Color) == "240,246,255")
check("no reverse lamp without Rev", r8.parts.RevL.Transparency == 1)
-- you drive the r8 (same beam), then get out: its lamps are set again both times
r8.parts.HeadCoreL.Transparency = 0.9
CarLamps.drive(r8, "drl", "", false, true)
beat(1)
check("in: lamps set afresh", r8.parts.HeadCoreL.Transparency == 0.35 and r8.parts.RevL.Transparency == 0)
r8.parts.HeadCoreL.Transparency = 0.9
r8.attrs.Beam = "off"
CarLamps.drive(nil, "off", "", false, false)
beat(1)
check("out: lamps off", r8.parts.HeadCoreL.Transparency == 1 and r8.parts.RevL.Transparency == 1)

if fails > 0 then
	print(fails .. " failed")
	process.exit(1)
end
print("lamps_test: all passed")
