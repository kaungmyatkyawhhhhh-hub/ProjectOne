-- Lune test (2026-11-21) for the rare cars' races (TrafficMix.Race): two racers that meet going the same way race
-- (owner: "no dont spawn as pairs i mean like when they meet each other coincidencely"), and the top speed factor
-- that makes them trade places.
--   lune run tools/racer_race_test.luau <path to Games/CityLegends>
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local process = require("@lune/process")

local root = process.args[1] or "."
local env = {
	Color3 = roblox.Color3,
	script = { Parent = { WaitForChild = function(_, n) return n end } },
	require = function() return { OLD_MODELS = {} } end,
}
local Mix = luau.load(fs.readFile(root .. "/src/shared/TrafficMix.lua"), { debugName = "TrafficMix", environment = env })()
local R = Mix.Race

local fails = 0
local function check(cond: any, msg: string)
	if not cond then
		fails += 1
		print("FAIL", msg)
	else
		print("ok  ", msg)
	end
end

local m = Mix.raceMeets
check(m(80, 0, 1), "same way, 80 ahead in the lane: a race")
check(m(-80, 12, 0.95), "same way, 80 behind in the lane beside: a race")
check(m(R.MeetGap, 0, 1) and not m(R.MeetGap + 1, 0, 1), "the meeting distance is MeetGap")
check(not m(-R.MeetGap - 1, 0, 1), "beyond MeetGap behind: no race")
check(not m(40, 8, -1), "oncoming: no race")
check(not m(40, 0, 0), "on a crossing road: no race")
check(not m(40, R.MeetSide + 1, 1), "same way on another road beside: no race")
check(R.Chance == nil and Mix.rival == nil, "no rival is spawned: races start by meeting only")

local f = Mix.raceFactor
check(f(-10) == R.Tow and f(-R.TowGap) == R.Tow and R.Tow == 1.08, "behind within TowGap: x 1.08")
check(f(-R.TowGap - 1) == 1, "behind beyond TowGap: no tow")
check(f(R.LeadGap + 1) == R.Ease and R.Ease == 0.92, "leading beyond LeadGap: x 0.92")
check(f(R.LeadGap) == 1 and f(0) == 1 and f(30) == 1, "level or just ahead: 1")
check(R.Split == 900 and R.TowGap == 90 and R.LeadGap == 70 and R.MeetGap == 120, "the race numbers")
check(Mix.Rare.ferrari == 1 and Mix.RareChance == 0.01, "caps and the rare chance are unchanged")

if fails > 0 then
	print(fails .. " FAILED")
	process.exit(1)
end
print("racer_race_test: all passed")
