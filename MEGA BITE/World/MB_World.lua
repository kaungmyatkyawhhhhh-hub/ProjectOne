-- MB_World (13 Nov): the finished world as two baked height maps, for the server's creatures (fish schools, predators).
--   floor(x, z) = the seabed      top(x, z) = the highest solid thing there (seabed, rock, landmark, coral)
-- Baked in Studio by ServerStorage.MB_WorldBake (re-run it after every map change). No raycasts at run time.
-- Owner 13 Nov: "the npc pathwalking need to be better because some are stuck in ground, noclips into props, stays in one place".
local SS = game:GetService("ServerStorage")
local RS = game:GetService("ReplicatedStorage")
local C = require(RS:WaitForChild("MegaBite"):WaitForChild("GameConfig"))
local W = {}
local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local REV = {}
for i = 1, 64 do REV[string.byte(B64, i)] = i - 1 end
local function decode(folder)
	local n = folder:GetAttribute("N")
	local buf = buffer.create(n * n)
	local o = 0
	for k = 1, folder:GetAttribute("Pieces") do
		local s = folder[tostring(k)].Value
		for i = 1, #s, 4 do
			local a, b, c, d = string.byte(s, i, i + 3)
			local v = REV[a] * 262144 + REV[b] * 4096 + (REV[c] or 0) * 64 + (REV[d] or 0)
			if o < n * n then buffer.writeu8(buf, o, v // 65536) end
			if c ~= 61 and o + 1 < n * n then buffer.writeu8(buf, o + 1, v // 256 % 256) end
			if d ~= 61 and o + 2 < n * n then buffer.writeu8(buf, o + 2, v % 256) end
			o += 3
		end
	end
	return buf
end
local gf, gt = SS:FindFirstChild("MB_GridFloor"), SS:FindFirstChild("MB_GridTop")
W.ready = gf ~= nil and gt ~= nil
local CELL, HALF, OFF, NX = 8, 1800, 170, 450
local FL, TP
if W.ready then
	CELL, HALF, OFF, NX = gf:GetAttribute("Cell"), gf:GetAttribute("Half"), gf:GetAttribute("Offset"), gf:GetAttribute("N")
	FL, TP = decode(gf), decode(gt)
else
	warn("[MB_World] no baked world (ServerStorage.MB_GridFloor / MB_GridTop): creatures use a flat seabed. Run MB_WorldBake.")
end
local CEIL = C.Swim.Ceiling
W.Ceiling = CEIL
local function cell(buf, ix, iz)
	if ix < 0 or iz < 0 or ix >= NX or iz >= NX then return 100 end   -- outside the map: a wall
	return buffer.readu8(buf, iz * NX + ix) - OFF
end
-- the seabed height (smooth: blended between the 4 nearest cells)
function W.floor(x, z)
	if not FL then return 2 end
	local fx, fz = (x + HALF) / CELL - 0.5, (z + HALF) / CELL - 0.5
	local ix, iz = math.floor(fx), math.floor(fz)
	local tx, tz = fx - ix, fz - iz
	local a, b, c, d = cell(FL, ix, iz), cell(FL, ix + 1, iz), cell(FL, ix, iz + 1), cell(FL, ix + 1, iz + 1)
	return (a * (1 - tx) + b * tx) * (1 - tz) + (c * (1 - tx) + d * tx) * tz
end
-- the highest solid thing in this cell (never below the seabed)
function W.top(x, z)
	if not TP then return 2 end
	return cell(TP, math.floor((x + HALF) / CELL), math.floor((z + HALF) / CELL))
end
-- keep y inside a band above the seabed (lo .. hi studs), above anything solid and under the surface
function W.clampY(x, z, y, lo, hi)
	local fl, tp = W.floor(x, z), W.top(x, z)
	local a = math.max(fl + lo, tp + 1.5)
	local b = math.max(a, math.min(fl + hi, CEIL - 4))
	return math.clamp(y, a, b), fl, tp
end
-- is (x, z) a wall for something swimming at height y? (a tall solid thing it cannot simply hop over)
function W.wall(x, z, y, hop)
	local tp = W.top(x, z)
	return tp + 1 > y and (tp - y > (hop or 9) or tp + 4 > CEIL - 4), tp
end
-- which ring (World.Tiers) and which biome ("N", "E", "S", "W") a point is in
function W.tier(x, z)
	local r = math.sqrt(x * x + z * z)
	local T = C.World.Tiers
	for i, t in ipairs(T) do if r < t.r1 then return i, t end end
	return #T, T[#T]
end
function W.biome(x, z)
	if math.abs(x) > math.abs(z) then return x > 0 and "E" or "W" end
	return z > 0 and "S" or "N"
end
return W
