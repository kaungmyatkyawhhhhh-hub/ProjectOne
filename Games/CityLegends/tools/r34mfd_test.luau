-- Lune test for src/client/R34Mfd.lua (2026-11-21): the BNR34 MFD's made-up readings behave like the real car's.
--   lune run tools/r34mfd_test.luau <path to Games/CityLegends>
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")

local root = process.args[1] or "."
local src = fs.readFile(root .. "/src/client/R34Mfd.lua")
local env = setmetatable({
	script = { Parent = { WaitForChild = function(_, n) return {} end } },
	require = function(x) return x end,
	Color3 = { fromRGB = function(r, g, b) return { r, g, b } end },
}, { __index = _G })
local M = luau.load(src, { debugName = "R34Mfd", environment = env })()

local function run(s, secs, share, thr, on, mph)
	for _ = 1, math.floor(secs * 30) do
		M.step(s, 1 / 30, share, thr, on, mph)
	end
end

local s = M.newSim()
run(s, 2, 0.11, 0, true, 0)
assert(s.boost < -0.5, "idle off the throttle is vacuum: " .. s.boost)
assert(s.volt > 13.8, "charging at idle: " .. s.volt)

-- full throttle low in the revs: little boost; high in the revs: full boost, but not at once (lag)
local low = M.newSim()
run(low, 3, 0.3, 1, true, 30)
assert(low.boost < 0.3, "no full boost at 2,400: " .. low.boost)
local hi = M.newSim()
run(hi, 0.15, 0.8, 1, true, 60)
local early = hi.boost
run(hi, 3, 0.8, 1, true, 60)
assert(early < hi.boost - 0.3, "boost builds up (lag): " .. early .. " -> " .. hi.boost)
assert(hi.boost > 0.85 and hi.boost < 1.05, "full boost about 1.0: " .. hi.boost)

-- the peak stays after the throttle is lifted, then falls back
local peak = hi.peak
run(hi, 1, 0.5, 0, true, 60)
assert(hi.boost < 0, "off the throttle: vacuum again " .. hi.boost)
assert(math.abs(hi.peak - peak) < 1e-6, "peak held")
run(hi, 8, 0.5, 0, true, 60)
assert(hi.peak < peak - 0.3, "peak falls back after the hold: " .. hi.peak)

-- warm-up and load
local w = M.newSim()
run(w, 5, 0.11, 0, true, 0)
assert(w.water < 50, "cold for the first seconds: " .. w.water)
run(w, 240, 0.11, 0, true, 0)
assert(w.water > 78 and w.water < 90, "running heat: " .. w.water)
assert(w.oil > w.water, "oil runs hotter than water")
local ex0 = w.exhaust
run(w, 10, 0.9, 1, true, 80)
assert(w.exhaust > ex0 + 300, "exhaust heats under load: " .. ex0 .. " -> " .. w.exhaust)

-- engine off: no boost, battery volts
run(w, 3, 0, 0, false, 0)
assert(math.abs(w.boost) < 0.05 and w.volt < 12.8, "engine off")
print("r34mfd_test: ok")
