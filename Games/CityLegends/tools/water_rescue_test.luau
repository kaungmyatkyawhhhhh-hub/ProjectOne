-- Lune test for src/shared/WaterRescue.lua (2026-11-21): the water timer and the choice of the road point.
--   lune run tools/water_rescue_test.luau <path to Games/CityLegends>
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local Vector3 = require("@lune/roblox").Vector3

local root = process.args[1] or "."
local W = luau.load(fs.readFile(root .. "/src/shared/WaterRescue.lua"), { debugName = "WaterRescue" })()

local fails = 0
local function check(cond: any, msg: string)
	if not cond then
		fails += 1
		print("FAIL", msg)
	else
		print("ok  ", msg)
	end
end

-- the timer: 5 checks a second
local st = W.new()
local now = 10
local function tick(wet: boolean, x: number)
	now += W.Every
	return W.step(st, wet, Vector3.new(x, 0, 0), W.Every, now)
end
check(tick(false, 0) == nil, "dry: nothing")
local got = nil
local n = 0
for i = 1, 20 do
	n = i
	got = tick(true, i)
	if got then
		break
	end
end
check(got ~= nil and math.abs(n * W.Every - W.Hold) < 1e-6, "wet for Hold seconds: one rescue")
check(got and got.X == 1, "the rescue starts from where it went in, not where it drifted to")
local again = false
for i = 1, math.floor(W.Cooldown / W.Every) - 1 do
	again = again or tick(true, 50) ~= nil
end
check(not again, "no second rescue inside the cooldown")
-- a splash: wet 0.8 s, dry, wet 0.8 s never adds up
st, now = W.new(), 100
local fired = false
for _ = 1, 3 do
	for _ = 1, 4 do
		fired = fired or tick(true, 0) ~= nil
	end
	fired = fired or tick(false, 0) ~= nil
end
check(not fired, "short splashes don't add up")

-- candidates: straight lanes along x at different z; sample = a point along the lane, forward +x
local function lane(z: number, x0: number, len: number)
	return { p0 = Vector3.new(x0, 0, z), p1 = Vector3.new(x0 + len / 2, 0, z), p2 = Vector3.new(x0 + len, 0, z), length = len }
end
local function sample(seg, s: number)
	return seg.p0 + Vector3.new(s, 0, 0), Vector3.new(1, 0, 0)
end
local lanes = { lane(200, -90, 180), lane(30, -90, 180), lane(-60, -90, 180), lane(36, -90, 180), lane(5000, 0, 60) }
local list = W.candidates(lanes, sample, Vector3.new(0, 0, 0), 8, 24)
check(#list == 3, "nearest first, 24 apart (the lane 6 beside is skipped), the far lane left out: " .. #list)
check(list[1].p.Z == 30 and list[2].p.Z == -60 and list[3].p.Z == 200, "order by distance")
check(math.abs(list[1].p.X) < 1e-6 and list[1].dir.X == 1, "the lane's nearest point and its direction")
check(#W.candidates(lanes, sample, Vector3.new(0, 0, 0), 2, 24) == 2, "at most n")
check(#W.candidates({}, sample, Vector3.new(0, 0, 0), 8, 24) == 0, "no lanes: empty")

-- pick: the nearest dry one; none dry = the nearest anyway; empty = nil
list[1].dry, list[2].dry, list[3].dry = false, true, true
check(W.pick(list) == list[2], "skips the lane point over water")
list[2].dry, list[3].dry = false, false
check(W.pick(list) == list[1], "nothing confirmed: the nearest")
check(W.pick({}) == nil, "no candidates: nil")

print(if fails == 0 then "ALL PASSED" else fails .. " FAILED")
process.exit(if fails == 0 then 0 else 1)
