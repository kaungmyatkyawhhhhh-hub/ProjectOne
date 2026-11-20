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

if fails > 0 then
	print(fails .. " FAILED")
	process.exit(1)
end
print("racer_pass_test: all passed")
