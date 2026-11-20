-- Kit props standing on the new roads (the lost KF / KW helpers, rebuilt). Paste in Studio Edit via execute_luau:
-- _G.KOR(false) counts, _G.KOR(true) removes (old tiles -> ServerStorage.KitTiles_P6); poll _G.KORS.
-- Set X0..Z1 to the district's swap range.
-- KitOnRoad: rebuilt 19 Nov from rebuild_progress.json props_cleanup.how + HANDOVER "MAP BUG FIXES (b)". Not the lost original.
local RS, SS = game:GetService("ReplicatedStorage"), game:GetService("ServerStorage")
local KD = require(RS.Shared.YangonKitData:Clone())
local kit = RS.YgnKit
local T = KD.index(kit.Templates)
local num, TWO_PI = KD.num, 2 * math.pi
local LEN = { [80] = 21, [81] = 27, [66] = 25, [76] = 31, [75] = 25, [84] = 22 } -- P Q B L K T
local X0, Z0, X1, Z1 = 21504, 32256, 30720, 46080 -- 1536 cells x14..19 z21..29
local rp = RaycastParams.new()
rp.FilterType = Enum.RaycastFilterType.Include
rp.FilterDescendantsInstances = { workspace.Yangon1to1.Roads.Collide }
local function onR(p: Vector3, up: number, down: number): boolean
	local h = workspace:Raycast(p + Vector3.new(0, up, 0), Vector3.new(0, -(up + down), 0), rp)
	return h ~= nil and h.Instance:GetAttribute("RoadBox") == "R"
end
local function share(cf: CFrame, half: number): number -- part of a piece's length (local X) standing on R
	local n = math.max(1, math.ceil(half))
	local hit = 0
	for k = -n, n do
		if onR(cf * Vector3.new(half * 0.95 * k / n, 0, 0), 3, 8) then hit += 1 end
	end
	return hit / (2 * n + 1)
end
local CW = {} -- compound-wall piece ids (YangonKitData propPid: "q" + crc32 of the Python repr)
for _, k in { 1, 2, 4, 8 } do
	CW[string.format("q%08x", KD.crc32("('prop', 'cwall" .. k .. "')"))] = true
end
local function scan(folder: Instance, apply: boolean)
	local meta = KD.meta(folder)
	if not meta then return "no Meta" end
	local building = string.match(folder.Name, "^Data_P%d+$") ~= nil -- building data: walls only
	local res = { tiles = 0, records = 0, removed = 0, changedTiles = 0, skipped = 0, kinds = {}, sample = {} }
	for q, v in folder:GetChildren() do
		local si, sj = string.match(v.Name, "^(-?%d+)_(-?%d+)$")
		if v:IsA("StringValue") and si then
			local i, j = tonumber(si), tonumber(sj)
			local x0, z0 = i * meta.tile, j * meta.tile
			if x0 + meta.tile > X0 and x0 < X1 and z0 + meta.tile > Z0 and z0 < Z1 then
				res.tiles += 1
				local s, badn = v.Value, 0
				if string.byte(s, 1) == 33 then s, badn = KD.expand(s, i, j, meta) end -- "!" compact -> plain records
				local function xyz(a: number): Vector3
					return Vector3.new(num(s, a, 4) / 500 - 16384 + x0, num(s, a + 4, 3) / 200 - 200, num(s, a + 7, 4) / 500 - 16384 + z0)
				end
				local keep, p, cut = {}, 1, 0
				while p <= #s do
					local t = string.byte(s, p)
					local L = LEN[t]
					if not L then keep = nil break end -- unknown record: the tile is left alone
					local drop, tag, pos = false, string.char(t), Vector3.zero
					if t == 80 or t == 81 then
						local pid = meta.pids[num(s, p + 1, 2) + 1]
						pos = xyz(p + 3)
						if not building then
							drop, tag = onR(pos, 3, 8), tostring(pid)
						elseif CW[pid] then
							local tp = T[pid] and T[pid][1]
							local sx = num(s, p + 17, 3) / 50000 + 0.1
							local cf = CFrame.new(pos) * CFrame.Angles(0, num(s, p + 14, 3) / 262144 * TWO_PI, 0)
							drop = if tp then share(cf * CFrame.new(tp.c.X * sx, 0, 0), tp.size.X * sx / 2) >= 0.25 else onR(pos, 3, 8)
							tag = "cwall"
						end
					elseif t == 66 then
						local code = meta.codes[num(s, p + 24, 1) + 1] or "?"
						if not building or code == "WCOL" or string.sub(code, 1, 2) == "KW" then
							pos = xyz(p + 1)
							local sx, sy = num(s, p + 15, 3) / 200, num(s, p + 18, 3) / 200
							local cf = CFrame.new(pos.X, pos.Y - sy / 2, pos.Z) * CFrame.Angles(0, num(s, p + 12, 3) / 262144 * TWO_PI, 0)
							local sh = share(cf, sx / 2)
							drop = if code == "WCOL" then sh > 0 else sh >= 0.25 -- invisible collision: any part on the carriageway
							tag = code
						end
					elseif t == 76 then -- L: a cable span, both poles
						pos = xyz(p + 1)
						drop = onR(pos, 3, 8) or onR(xyz(p + 15), 3, 8)
					elseif t == 84 and not building then -- T: a name plate, ray 12 down
						pos = xyz(p + 1)
						drop = onR(pos, 1, 12)
					end -- K (75) cables are kept
					res.records += 1
					if drop then
						cut += 1
						res.kinds[tag] = (res.kinds[tag] or 0) + 1
						if #res.sample < 8 then table.insert(res.sample, string.format("%s %s (%.0f, %.1f, %.0f)", v.Name, tag, pos.X, pos.Y, pos.Z)) end
					else
						table.insert(keep, string.sub(s, p, p + L - 1))
					end
					p += L
				end
				if not keep or badn > 0 then
					res.skipped += 1
				elseif cut > 0 then
					res.removed += cut
					res.changedTiles += 1
					if apply then
						local bk = SS:FindFirstChild("KitTiles_P6") or Instance.new("Folder")
						bk.Name = "KitTiles_P6"
						bk.Parent = SS
						local c = v:Clone()
						c.Name = folder.Name .. "|" .. v.Name
						c.Parent = bk
						v.Value = table.concat(keep) -- a compact tile is stored expanded (as P4 / P7 did)
					end
				end
			end
		end
		if q % 25 == 0 then task.wait() end
	end
	return res
end
function _G.KOR(apply: boolean)
	_G.KORS = { status = "running" }
	task.spawn(function()
		local ok, err = pcall(function()
			for _, f in kit:GetChildren() do
				if f:IsA("Folder") and string.sub(f.Name, 1, 5) == "Data_" then
					_G.KORS.status = "running " .. f.Name
					_G.KORS[f.Name] = scan(f, apply)
				end
			end
		end)
		_G.KORS.status = if ok then (if apply then "done APPLIED" else "done COUNT") else "ERR " .. tostring(err)
	end)
	return "started"
end
return _G.KOR(false)
