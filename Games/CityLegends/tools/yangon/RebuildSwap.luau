--[[
	RebuildSwap (Studio, Edit; 2026-11-26): swap an already-placed district's buildings for a fresh buildings_1to1.py run
	(P1-P3 re-made against today's roads). Uses DistrictPlace's packs (place_<tag>_1..3 = Data_<tag>, Roofs, Shell cells).

	local R = require(ServerStorage.ClaudeTools.RebuildSwap:Clone())
	R.removeOld(tag, oldText, box)  -- old S / R records (the old Shell_*.txt joined) -> matching shells + roofs, the old
	                                 -- NWH night parts (bbox mostly in box = {x0, z0, x1, z1}) and Data_<tag> moved to
	                                 -- ServerStorage.OverlapFixBackup.RebuildOld_<tag>
	R.placeNew(tag)                  -- after DistrictPlace load + kit: Data_<tag> in, shells merged into existing Cell_ models,
	                                 -- roofs; new shells / roofs with their centre in a KeepOut box are dropped (counted)
	R.restore(tag)                   -- undo removeOld (the new ones must be cleared by hand first)
	Status in workspace attribute "RebuildSwap".
]]
local SS = game:GetService("ServerStorage")
local RS = game:GetService("ReplicatedStorage")
local R = {}

local function status(s)
	workspace:SetAttribute("RebuildSwap", s)
end

local function run(name, fn)
	status(name .. ": running")
	task.spawn(function()
		local t0 = os.clock()
		local ok, r = pcall(fn)
		status(string.format("%s: %s %s (%.0f s)", name, ok and "done" or "ERROR", tostring(r), os.clock() - t0))
	end)
	return "started " .. name
end

local function backupFolder(tag)
	local ob = SS:FindFirstChild("OverlapFixBackup") or Instance.new("Folder")
	ob.Name = "OverlapFixBackup"
	ob.Parent = SS
	local f = ob:FindFirstChild("RebuildOld_" .. tag) or Instance.new("Folder")
	f.Name = "RebuildOld_" .. tag
	f.Parent = ob
	return f
end

local function sub(parent, name, class)
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new(class or "Folder")
		f.Name = name
		f.Parent = parent
	end
	return f
end

-- expected parts of the S / R records: bucket key (floor x/8, floor z/8) -> list of {name, pos}
local function expected(text)
	local P = require(SS.ClaudeTools.YangonKitPlace:Clone())
	P.index(RS.YgnKit.Templates)
	local B, n, miss = {}, 0, 0
	local function add(name, p)
		local k = math.floor(p.X / 8) .. "_" .. math.floor(p.Z / 8)
		local l = B[k]
		if not l then
			l = {}
			B[k] = l
		end
		table.insert(l, { name, p })
		n += 1
	end
	for line in string.gmatch(text, "[^\n]+") do
		local w = string.split(line, " ")
		if w[1] == "S" then
			add(w[10], Vector3.new(tonumber(w[3]), tonumber(w[4]), tonumber(w[5])))
		elseif w[1] == "R" then
			local parts = P.T[w[2]]
			if parts then
				local sx, sy, sz = tonumber(w[3]) :: number, tonumber(w[9]) :: number, tonumber(w[10]) :: number
				local cf = CFrame.new(tonumber(w[4]) :: number, tonumber(w[5]) :: number, tonumber(w[6]) :: number)
					* CFrame.Angles(0, tonumber(w[7]) :: number, 0)
				for _, t in parts do
					add(t.kind == "KRO" and w[11] or w[8], (cf * CFrame.new(t.c.X * sx, t.c.Y * sy, t.c.Z * sz)).Position)
				end
			else
				miss += 1
			end
		end
	end
	return B, n, miss
end

local function matches(B, q)
	local p = q.Position
	local k = math.floor(p.X / 8) .. "_" .. math.floor(p.Z / 8)
	for _, e in (B[k] or {}) do
		if e[1] == q.Name and (e[2] - p).Magnitude < 0.08 then
			return true
		end
	end
	return false
end

local function inBox(box, p)
	return p.X >= box[1] and p.X <= box[3] and p.Z >= box[2] and p.Z <= box[4]
end

function R.removeOld(tag, oldText, box)
	return run("removeOld " .. tag, function()
		local bf = backupFolder(tag)
		local B, nExp, miss = expected(oldText)
		local bld = workspace.Yangon1to1.Buildings
		local shellB = sub(bf, "Shell")
		local moved = 0
		for _, cell in bld.Shell:GetChildren() do
			local tgt
			for _, q in cell:GetChildren() do
				if q:IsA("BasePart") and inBox(box, q.Position) and matches(B, q) then
					tgt = tgt or sub(shellB, cell.Name, "Model")
					q.Parent = tgt
					moved += 1
					if moved % 500 == 0 then
						task.wait()
					end
				end
			end
		end
		-- night: an NWH part whose box is mostly inside the district box
		local nightB = sub(bf, "Night")
		local nn = 0
		for _, cell in bld.Night:GetChildren() do
			for _, q in cell:GetChildren() do
				if q:IsA("BasePart") then
					local c, s = q.Position, q.Size
					local ax0, az0, ax1, az1 = c.X - s.X / 2, c.Z - s.Z / 2, c.X + s.X / 2, c.Z + s.Z / 2
					local ix = math.max(0, math.min(ax1, box[3]) - math.max(ax0, box[1]))
					local iz = math.max(0, math.min(az1, box[4]) - math.max(az0, box[2]))
					if ix * iz > 0.5 * s.X * s.Z then
						q:SetAttribute("FromCell", cell.Name)
						q.Parent = nightB
						nn += 1
					end
				end
			end
		end
		local d = RS.YgnKit:FindFirstChild("Data_" .. tag)
		if d then
			d.Parent = bf
		end
		return string.format("expected %d (roof ids missing %d), shells+roofs moved %d, night %d, data %s", nExp, miss, moved,
			nn, tostring(d ~= nil))
	end)
end

function R.placeNew(tag)
	return run("placeNew " .. tag, function()
		local bld = workspace.Yangon1to1.Buildings
		local p1 = SS[tag .. "Place_1"]
		local d = p1:FindFirstChild("Data_" .. tag)
		assert(d, "no Data_" .. tag .. " in the pack")
		assert(not RS.YgnKit:FindFirstChild("Data_" .. tag), "old Data_" .. tag .. " still in YgnKit")
		d.Parent = RS.YgnKit
		-- roofs into a holding folder first (YangonKitPlace.shells makes Shell cells under it)
		local P = require(SS.ClaudeTools.YangonKitPlace:Clone())
		P.index(RS.YgnKit.Templates)
		local hold = Instance.new("Folder")
		hold.Name = "_RebuildHold_" .. tag
		hold.Parent = SS
		local nr = P.shells(SS[tag .. "Place_2"].Roofs.Value, hold)
		local cells = SS[tag .. "Place_3"].Shell:GetChildren()
		local p4 = SS:FindFirstChild(tag .. "Place_4")
		for _, c in (p4 and p4.Shell:GetChildren() or {}) do
			table.insert(cells, c)
		end
		for _, c in hold.Shell:GetChildren() do
			table.insert(cells, c)
		end
		local keep = RS.YgnKit.KeepOut:GetChildren()
		local function keptOut(p)
			for _, k in keep do
				if k:IsA("BasePart") then
					local l = k.CFrame:PointToObjectSpace(p)
					local s = k.Size / 2 + Vector3.new(1, 1000, 1)
					if math.abs(l.X) <= s.X and math.abs(l.Z) <= s.Z then
						return k
					end
				end
			end
			return nil
		end
		local dropF = sub(backupFolder(tag), "NewInKeepOut")
		local n, dropped = 0, 0
		for _, cell in cells do
			local tgt = bld.Shell:FindFirstChild(cell.Name) or Instance.new("Model")
			tgt.Name = cell.Name
			tgt.Parent = bld.Shell
			for _, q in cell:GetChildren() do
				if q:IsA("BasePart") then
					local w = string.split(q.Name, "|")
					if #w == 3 then
						q.Name = w[1]
						q:SetAttribute("T", w[2])
						q.Material = Enum.Material.Plaster
						q.MaterialVariant = w[3]
					end
					local k = keptOut(q.Position)
					if k then
						q:SetAttribute("KeepOut", k.Name)
						q.Parent = dropF
						dropped += 1
					else
						q.Parent = tgt
						n += 1
					end
				end
			end
			task.wait()
		end
		hold:Destroy()
		return string.format("shells+roofs %d (roof parts made %d), dropped in KeepOut %d", n, nr, dropped)
	end)
end

function R.restore(tag)
	return run("restore " .. tag, function()
		local bf = SS.OverlapFixBackup["RebuildOld_" .. tag]
		local bld = workspace.Yangon1to1.Buildings
		local n = 0
		for _, cell in bf.Shell:GetChildren() do
			local tgt = bld.Shell:FindFirstChild(cell.Name) or Instance.new("Model")
			tgt.Name = cell.Name
			tgt.Parent = bld.Shell
			for _, q in cell:GetChildren() do
				q.Parent = tgt
				n += 1
			end
		end
		for _, q in bf.Night:GetChildren() do
			local c = bld.Night:FindFirstChild(q:GetAttribute("FromCell")) or Instance.new("Model")
			c.Name = q:GetAttribute("FromCell")
			c.Parent = bld.Night
			q.Parent = c
		end
		local d = bf:FindFirstChild("Data_" .. tag)
		if d then
			d.Parent = RS.YgnKit
		end
		return "restored " .. n
	end)
end

return R
