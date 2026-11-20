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

-- (owner, 2026-11-21: "the faster car will go around and make an u turn and go near the other rare car")
local s = Mix.raceSees
check(s(200, 0) and s(R.SeeGap, -R.SeeHeight), "within SeeGap at the same level: they meet, whatever their ways")
check(not s(R.SeeGap + 1, 0), "beyond SeeGap: no meeting")
check(not s(40, 20) and not s(40, -20), "a flyover over a street: no meeting")
local w = Mix.raceTurns
check(w(220, 136, 0, 50) and not w(136, 220, 50, 0), "the faster one turns round")
check(w(150, 150, 80, -80) and not w(150, 150, -80, 80), "the same speed: the one behind turns")
check(R.Chase > 1 and R.Wait < 1 and R.ChaseTime == 25 and R.Cooldown > 0, "chase boost, wait, give-up time, cooldown")

local V = roblox.Vector3
local p0, fwd, side, r = V.new(100, 5, -40), V.new(0, 0, -1), V.new(-1, 0, 0), 9
local pose = Mix.uTurnPose
local a0, f0 = pose(p0, fwd, side, r, 0)
local a1, f1 = pose(p0, fwd, side, r, 1)
check((a0 - p0).Magnitude < 1e-6 and (f0 - fwd).Magnitude < 1e-6, "U-turn starts on the lane heading forward")
check((a1 - (p0 + side * (2 * r))).Magnitude < 1e-4 and (f1 + fwd).Magnitude < 1e-4, "U-turn ends on the oncoming lane heading back")
local smooth, onArc, prevP, prevF = true, true, a0, f0
for k = 1, 100 do
	local p, f = pose(p0, fwd, side, r, k / 100)
	local step = p - prevP
	-- no jump, the nose turns a little at a time and points the way the car moves, the car stays on the half circle
	smooth = smooth and step.Magnitude < math.pi * r / 100 * 1.01 and f:Dot(prevF) > 0.999 and step.Unit:Dot(f) > 0.999
	onArc = onArc and math.abs((p - (p0 + side * r)).Magnitude - r) < 1e-4 and math.abs(f.Magnitude - 1) < 1e-6 and (p - p0):Dot(fwd) > -1e-6
	prevP, prevF = p, f
end
check(smooth, "U-turn is continuous: no snap in place or heading")
check(onArc, "U-turn stays on the half circle ahead of where it began")

if fails > 0 then
	print(fails .. " FAILED")
	process.exit(1)
end
print("racer_race_test: all passed")
