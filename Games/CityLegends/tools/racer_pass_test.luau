-- Lune test (2026-11-21) for TrafficMix.racerBehindPlayer: a racer behind a player's car matches its speed, never
-- stops for a moving player, and keeps rolling while it moves over to pass.
--   lune run tools/racer_pass_test.luau <path to Games/CityLegends>
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
local R = Mix.Racer
local f = Mix.racerBehindPlayer

local fails = 0
local function check(cond: any, msg: string)
	if not cond then
		fails += 1
		print("FAIL", msg)
	else
		print("ok  ", msg)
	end
end

check(f(300, 2000, 100, 60, false) == 300, "far behind: own speed")
check(f(300, 100, 100, 60, false) == 60, "at the gap: the player's speed, not 0")
check(f(300, 20, 100, 60, false) == 60, "inside the gap: still the player's speed (no stop-go)")
local a, b = f(300, 150, 100, 60, false), f(300, 400, 100, 60, false)
check(a > 60 and b > a and b < 300, "closing in: eases down towards the player's speed")
check(f(300, 30, 16, 0, false) > 0, "stopped player, room left: still closing up")
check(f(300, 10, 16, 0, false) == 0, "stopped player, nothing open: waits at the gap")
check(f(300, 10, 16, 0, true) == R.PassCreep, "stopped player, moving over: keeps rolling")
check(f(300, R.PassGap, 16, 0, true) == 0, "on the player's bumper: never rolls into it")
check(f(0, 10, 16, 0, true) == 0, "a red light / bend limit still wins")
check(f(40, 100, 100, 60, false) == 40, "never faster than its own limit")
check(R.PlayerGap == nil, "the old wide player gap is gone")

-- (owner, 2026-11-21: "every 1 degree = 3% slower ... 10 degrees = 30% slower so 100 mph to 70 mph")
local t = Mix.racerTurnSpeed
check(math.abs(t(100, 10, 15) - 70) < 1e-6, "turn: 100 mph, 10 degrees -> 70")
check(t(100, 0, 15) == 100, "turn: 0 degrees -> top speed")
check(t(100, 40, 15) == 15, "turn: 40 degrees -> the floor, never 0")
check(t(100, 30, 15) == 15, "turn: 30 degrees -> the floor")
check(R.TurnSlowPerDeg == 0.03 and R.LatAccel == nil, "3% a degree; the old bend rule is gone")
check(R.SideHold >= 0.5, "a minimum time between sideways choices")
check(Mix.LowEndCars == 14, "low-end devices keep 14 cars")

if fails > 0 then
	print(fails .. " FAILED")
	process.exit(1)
end
print("racer_pass_test: all passed")
