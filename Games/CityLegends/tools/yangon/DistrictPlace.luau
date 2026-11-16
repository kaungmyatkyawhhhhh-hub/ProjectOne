--[[
	DistrictPlace (Studio, Edit; 2026-11-16, "up to batch 3"): P3Place made general for any 1:1 district P<n> built by
	tools/yangon/city/place_pack.py <tag> (terrain packs Folders <tag>TerrainA / B). Build and check in the copy place
	(CitylegendsForCopy.rbxl) first, then the same calls move it into the cloud place.

	local M = require(ServerStorage.ClaudeTools.DistrictPlace:Clone())
	M.tag = "P4"
	M.load({ pack1, pack2, pack3 })   -- place_<tag>_1..3.rbxmx Model ids -> ServerStorage.<tag>Place_1..3
	M.kit(kitId, nightA, nightB)      -- kitId (new kit pieces, or nil) into ReplicatedStorage.YgnKit.Templates, night
	                                  -- window cells (nightB may be nil) into Yangon1to1.Buildings.Night
	M.terrain()                       -- Terrain<tag>_n with a thin skin (YB 12 under each tile's lowest top)
	M.green()                         -- Data_<tag> + Data_<tag>G into YgnKit, ground paint, far crowns (farOld REPLACES
	                                  -- Green.Far: in a place with other districts rename Far first and merge back)
	M.shells()                        -- shells ("code|T|variant" Parts) into Buildings.Shell, then the pitched roofs
	M.pagodas()                       -- PagodaData rows via ClaudeTools.PagodaPlace.placeOne (any class), on the terrain
	M.clear()                         -- copy place only: removes this district's shells / roofs / night / far crowns / data
	M.cleanup()                       -- removes the packs and the Terrain<tag>_ modules
	Status in workspace attribute "DistrictPlace" (poll it).
]]
local SS = game:GetService("ServerStorage")
local RS = game:GetService("ReplicatedStorage")
local IS = game:GetService("InsertService")
local M = { tag = "P4" }

local function status(s)
	workspace:SetAttribute("DistrictPlace", s)
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

local function root()
	local r = workspace:FindFirstChild("Yangon1to1") or Instance.new("Folder")
	r.Name = "Yangon1to1"
	r.Parent = workspace
	local b = r:FindFirstChild("Buildings") or Instance.new("Folder")
	b.Name = "Buildings"
	b.Parent = r
	return r, b
end

local function loadAsset(id)
	for _ = 1, 5 do
		local ok, m = pcall(function()
			return IS:LoadAsset(id)
		end)
		if ok then
			return m
		end
		task.wait(2)
	end
	error("LoadAsset failed " .. tostring(id))
end

function M.load(ids)
	return run("load", function()
		local got = {}
		for _, id in ids do
			local m = loadAsset(id)
			local f = m:FindFirstChildWhichIsA("Folder")
			f.Parent = SS
			m:Destroy()
			table.insert(got, f.Name)
		end
		for _, nm in { M.tag .. "Place_1", M.tag .. "Place_2" } do
			local f = SS:FindFirstChild(nm)
			for _, sub in (f and f:GetChildren() or {}) do
				if sub.Name == M.tag .. "TerrainA" or sub.Name == M.tag .. "TerrainB" then
					for _, mod in sub:GetChildren() do
						mod.Parent = SS.ClaudeTools
					end
				end
			end
		end
		return table.concat(got, ", ")
	end)
end

function M.kit(kitId, nightA, nightB)
	return run("kit", function()
		local P = require(SS.ClaudeTools.YangonKitPlace:Clone())
		local _, b = root()
		local night = b:FindFirstChild("Night") or Instance.new("Folder")
		night.Name = "Night"
		night.Parent = b
		local nc = 0
		for _, id in { nightA, nightB } do
			if not id then continue end
			local m = loadAsset(id)
			nc += P.cells(m, night)
			m:Destroy()
		end
		local nt = 0
		if kitId then
			local k = loadAsset(kitId)
			nt = P.templates(k, RS.YgnKit.Templates)
			k:Destroy()
		end
		return string.format("night %d, templates %d", nc, nt)
	end)
end

function M.terrain()
	return run("terrain", function()
		local T = require(SS.ClaudeTools.YangonTerrain2:Clone())
		local lines = T.load("Terrain" .. M.tag .. "_")
		for k, line in lines do
			local _, _, _, codes, tops = T.decode(line)
			local lo = 1e9
			for i = 1, 4096 do
				if codes[i] ~= "." then
					lo = math.min(lo, tops[i])
				end
			end
			T.YB = math.max(-24, math.floor((lo - 12) / 4) * 4)
			T.tile(line)
			if k % 20 == 0 then
				status(string.format("terrain: %d/%d", k, #lines))
			end
			task.wait()
		end
		return #lines .. " tiles"
	end)
end

function M.green()
	return run("green", function()
		local p1 = SS[M.tag .. "Place_1"]
		local h = p1["GreenHolding_" .. M.tag]
		local G = require(h.YangonGreen1to1:Clone())
		local kit = RS.YgnKit
		local d = p1:FindFirstChild("Data_" .. M.tag)
		if d then
			local old = kit:FindFirstChild("Data_" .. M.tag)
			if old then
				old:Destroy()
			end
			d.Parent = kit
		end
		local r1 = G.paint(h)
		local r2 = G.farOld(h)
		local r3 = G.data(h)
		return string.format("paint %s, far %s, data %s", tostring(r1), tostring(r2), tostring(r3))
	end)
end

function M.shells()
	return run("shells", function()
		local _, b = root()
		local shellF = b:FindFirstChild("Shell") or Instance.new("Folder")
		shellF.Name = "Shell"
		shellF.Parent = b
		local n = 0
		for _, cell in SS[M.tag .. "Place_3"].Shell:GetChildren() do
			for _, q in cell:GetChildren() do
				if q:IsA("BasePart") then
					local w = string.split(q.Name, "|")
					if #w == 3 then
						q.Name = w[1]
						q:SetAttribute("T", w[2])
						q.Material = Enum.Material.Plaster
						q.MaterialVariant = w[3]
						n += 1
					end
				end
			end
			cell.Parent = shellF
			task.wait()
		end
		local P = require(SS.ClaudeTools.YangonKitPlace:Clone())
		P.index(RS.YgnKit.Templates)
		local nr = P.shells(SS[M.tag .. "Place_2"].Roofs.Value, b)
		return string.format("shells %d, roof parts %d", n, nr)
	end)
end

function M.pagodas()
	return run("pagodas", function()
		local PP = require(SS.ClaudeTools.PagodaPlace:Clone())
		local pd = SS[M.tag .. "Place_2"]:FindFirstChild("PagodaData")
		if not pd then
			return "none"
		end
		local kit, folder, out = PP.kit(), PP.folder(), {}
		for _, row in string.split(pd.Value, "
") do
			if row ~= "" then
				local m = PP.placeOne(kit, folder, row)
				table.insert(out, m.Name .. " " .. tostring(m:GetAttribute("Ground")))
			end
		end
		return table.concat(out, "; ")
	end)
end

-- copy place only: this district's placed things out again (terrain stays; the next district's terrain overwrites)
function M.clear(x0, z0, x1, z1)
	return run("clear", function()
		local r = workspace:FindFirstChild("Yangon1to1")
		local n = 0
		local function inBox(p)
			local q = p:IsA("Model") and p:GetPivot().Position or p.Position
			return q.X >= x0 and q.X <= x1 and q.Z >= z0 and q.Z <= z1
		end
		for _, path in { { "Buildings", "Shell" }, { "Buildings", "Night" }, { "Green", "Far" }, { "Pagodas" } } do
			local f = r
			for _, k in path do
				f = f and f:FindFirstChild(k)
			end
			for _, d in (f and f:GetDescendants() or {}) do
				if d:IsA("BasePart") and d.Parent and inBox(d) then
					d:Destroy()
					n += 1
					if n % 2000 == 0 then
						task.wait()
					end
				end
			end
		end
		for _, k in RS.YgnKit:GetChildren() do
			if string.match(k.Name, "^Data_P%d") then
				k:Destroy()
			end
		end
		return "parts removed " .. n
	end)
end

function M.cleanup()
	local n = 0
	for _, nm in { M.tag .. "Place_1", M.tag .. "Place_2", M.tag .. "Place_3" } do
		local f = SS:FindFirstChild(nm)
		if f then
			f:Destroy()
			n += 1
		end
	end
	for _, m in SS.ClaudeTools:GetChildren() do
		if string.sub(m.Name, 1, #M.tag + 8) == "Terrain" .. M.tag .. "_" then
			m:Destroy()
			n += 1
		end
	end
	return "removed " .. n
end

return M
