--[[
	PlacesApply (Studio, Edit; 2026-11-16, P1 real places + condos): swaps a district's kit-building shells and data for
	a new buildings_1to1.py run and puts in places_1to1.py's places layer. Holding Folder PlacesHold_<tag>
	(tools/yangon/city/places_pack.py): Data_<tag>, Data_<tag>P, Shell_<n> (new), OldShell_<n> (the run being replaced),
	YangonKitData (ModuleScript source for ReplicatedStorage.Shared).

	local A = require(ServerStorage.ClaudeTools.PlacesApply:Clone())
	A.spawn("unshell", function() return A.unshells(holding, P) end)   -- removes exactly the old run's S / R / W parts
	A.spawn("shell", function() return A.shells(holding, P) end)       -- YangonKitPlace.shells of every Shell_<n>
	A.data(holding)                                                     -- Data_<tag>, Data_<tag>P into ReplicatedStorage.YgnKit
	A.kitData(holding)                                                  -- ReplicatedStorage.Shared.YangonKitData Source
	A.status()                                                          -- ServerStorage attribute PlacesApplyStatus
	(P = require(ServerStorage.ClaudeTools.YangonKitPlace:Clone()) with P.index(ReplicatedStorage.YgnKit.Templates))
	Matching is by position (0.05 studs): a part of another district is never touched.
]]

local SS = game:GetService("ServerStorage")
local RS = game:GetService("ReplicatedStorage")

local A = {}

local function key(x: number, y: number, z: number): string
	return string.format("%d_%d_%d", math.round(x * 10), math.round(y * 10), math.round(z * 10))
end

local function pages(holding: Instance, prefix: string): { string }
	local out = {}
	for _, v in holding:GetChildren() do
		if v:IsA("StringValue") and string.match(v.Name, "^" .. prefix .. "_%d+$") then
			table.insert(out, v.Value)
		end
	end
	return out
end

-- every part position the old run's lines made (S and W: the record's middle; R: each roof piece, as P.shells does)
function A.oldKeys(holding: Instance, P): ({ [string]: boolean }, number)
	local set, n = {}, 0
	for _, text in pages(holding, "OldShell") do
		for line in string.gmatch(text, "[^\n]+") do
			local w = string.split(line, " ")
			if w[1] == "S" then
				set[key(tonumber(w[3]) :: number, tonumber(w[4]) :: number, tonumber(w[5]) :: number)] = true
				n += 1
			elseif w[1] == "W" then
				set[key(tonumber(w[2]) :: number, tonumber(w[3]) :: number, tonumber(w[4]) :: number)] = true
				n += 1
			elseif w[1] == "R" then
				local parts = P.T[w[2]]
				if parts then
					local sx, sy, sz = tonumber(w[3]) :: number, tonumber(w[9]) :: number, tonumber(w[10]) :: number
					local cf = CFrame.new(tonumber(w[4]) :: number, tonumber(w[5]) :: number, tonumber(w[6]) :: number)
						* CFrame.Angles(0, tonumber(w[7]) :: number, 0)
					for _, t in parts do
						local p = (cf * CFrame.new(t.c.X * sx, t.c.Y * sy, t.c.Z * sz)).Position
						set[key(p.X, p.Y, p.Z)] = true
						n += 1
					end
				end
			end
		end
	end
	return set, n
end

function A.unshells(holding: Instance, P): string
	local set, n = A.oldKeys(holding, P)
	local root = workspace.Yangon1to1.Buildings
	local removed, seen = 0, 0
	for _, fname in { "Shell", "WallCollide" } do
		local f = root:FindFirstChild(fname)
		if f then
			for _, cm in f:GetChildren() do
				for _, q in cm:GetChildren() do
					if q:IsA("BasePart") then
						seen += 1
						local p = q.Position
						if set[key(p.X, p.Y, p.Z)] then
							q:Destroy()
							removed += 1
						end
						if seen % 2000 == 0 then
							task.wait()
						end
					end
				end
			end
		end
	end
	return string.format("old keys %d, parts seen %d, removed %d", n, seen, removed)
end

function A.shells(holding: Instance, P): string
	local root = workspace.Yangon1to1.Buildings
	local n = 0
	for _, text in pages(holding, "Shell") do
		n += P.shells(text, root)
		task.wait()
	end
	return "placed " .. n
end

function A.data(holding: Instance): string
	local kit = RS:FindFirstChild("YgnKit")
	local moved = {}
	for _, f in holding:GetChildren() do
		if f:IsA("Folder") and string.sub(f.Name, 1, 5) == "Data_" then
			local old = kit:FindFirstChild(f.Name)
			if old then
				old:Destroy()
			end
			f.Parent = kit
			table.insert(moved, f.Name .. " " .. #f:GetChildren())
		end
	end
	return table.concat(moved, ", ")
end

function A.kitData(holding: Instance): string
	local src = holding:FindFirstChild("YangonKitData")
	local dst = RS.Shared:FindFirstChild("YangonKitData")
	if not (src and dst) then
		return "missing"
	end
	dst.Source = src.Source
	local h = 0
	for i = 1, #dst.Source do
		h = (h * 31 + string.byte(dst.Source, i)) % 2147483647
	end
	return "YangonKitData " .. #dst.Source .. " chars, checksum " .. h
end

-- terrain cut over the graded slabs (Grade_<n> lines "cx cz sx sz yaw top"): Air from top - 0.5 up 40 studs, so the
-- forecourt / car park / court slab is the surface (no terrain through it, no flicker with it)
function A.grade(holding: Instance): string
	local n = 0
	for _, text in pages(holding, "Grade") do
		for line in string.gmatch(text, "[^\n]+") do
			local w = string.split(line, " ")
			local cx, cz, sx, sz, yaw, top = tonumber(w[1]), tonumber(w[2]), tonumber(w[3]), tonumber(w[4]), tonumber(w[5]), tonumber(w[6])
			if cx then
				local H = 40
				workspace.Terrain:FillBlock(CFrame.new(cx, top - 0.5 + H / 2, cz) * CFrame.Angles(0, yaw, 0),
					Vector3.new(sx, H, sz), Enum.Material.Air)
				n += 1
				if n % 5 == 0 then
					task.wait()
				end
			end
		end
	end
	return "graded " .. n
end

-- a district's places layer only (Data_<tag>P): replaces the folder in ReplicatedStorage.YgnKit
function A.placesData(holding: Instance): string
	return A.data(holding)
end

function A.spawn(name: string, fn)
	SS:SetAttribute("PlacesApplyStatus", name .. ": running")
	task.spawn(function()
		local ok, res = pcall(fn)
		SS:SetAttribute("PlacesApplyStatus", name .. ": " .. (ok and tostring(res) or ("ERROR " .. tostring(res))))
	end)
end

function A.status(): string
	return SS:GetAttribute("PlacesApplyStatus") or "-"
end

return A
