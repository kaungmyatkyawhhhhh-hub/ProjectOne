--[[
	P3Place (Studio, Edit; 2026-11-16, step 6): puts the 1:1 downtown district P3 into a place from the packs made by
	tools/yangon/city/place_pack.py P3 (built and checked first in the copy place CitylegendsForCopy.rbxl).
	Run each step from execute_luau (they spawn and report in workspace attribute "P3Place"; poll it):

	local M = require(ServerStorage.ClaudeTools.P3Place:Clone())   -- or paste this file's body
	M.load({ pack1, pack2, pack3 })   -- the three Model asset ids (place_p3_1..3.rbxmx) -> ServerStorage.P3Place_1..3
	M.kit(kitId, nightA, nightB)      -- kit pieces 79973726669188 into ReplicatedStorage.YgnKit.Templates,
	                                  -- night windows 82960431231204 + 75559474746620 into Yangon1to1.Buildings.Night
	M.terrain()                       -- TerrainP3_1..81 (packs 1 + 2) with a thin skin: YB 12 studs under each tile's
	                                  -- lowest top (river beds go to -24); about 50 s
	M.green()                         -- Data_P3 + Data_P3G into YgnKit, ground paint, far crowns (farOld: the old-map
	                                  -- tree kit); about 25 s. Merge note: farOld REPLACES Workspace.Yangon1to1.Green.Far
	                                  -- (P1 / P2's far crowns too): in the cloud place rename Far first and merge back
	M.shells()                        -- the 13,039 shells (Parts named "code|T|variant" -> Name, attribute T,
	                                  -- MaterialVariant, Plaster) into Buildings.Shell, then the 952 pitched roofs
	M.pagodas()                       -- the two P3 pagodas (PagodaPlace rows, class M) on the terrain
	M.landmarks(ids, pack)            -- the 9 downtown landmarks (build/landmarks/dt_assets.json ids, pack =
	                                  -- ServerStorage.DTLandmarks from asset 128412859648997), TEMP plates deleted
	M.cleanup()                       -- removes the packs and the TerrainP3_ modules (never leave data in the place)
	In the cloud place also delete Landmarks.SulePlate_TEMP, BotataungPlate_TEMP and BotataungRiver_TEMP (the terrain
	pads replace them).
]]
local SS = game:GetService("ServerStorage")
local RS = game:GetService("ReplicatedStorage")
local IS = game:GetService("InsertService")
local M = {}

local function status(s)
	workspace:SetAttribute("P3Place", s)
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
		for _, nm in { "P3Place_1", "P3Place_2" } do
			local f = SS:FindFirstChild(nm)
			for _, sub in (f and f:GetChildren() or {}) do
				if sub.Name == "P3TerrainA" or sub.Name == "P3TerrainB" then
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
			local m = loadAsset(id)
			nc += P.cells(m, night)
			m:Destroy()
		end
		local k = loadAsset(kitId)
		local nt = P.templates(k, RS.YgnKit.Templates)
		k:Destroy()
		return string.format("night %d, templates %d", nc, nt)
	end)
end

function M.terrain()
	return run("terrain", function()
		local T = require(SS.ClaudeTools.YangonTerrain2:Clone())
		local lines = T.load("TerrainP3_")
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
		local p1 = SS.P3Place_1
		local h = p1.GreenHolding_P3
		local G = require(h.YangonGreen1to1:Clone())
		local kit = RS.YgnKit
		local d = p1:FindFirstChild("Data_P3")
		if d then
			local old = kit:FindFirstChild("Data_P3")
			if old then
				old:Destroy()
			end
			d.Parent = kit
		end
		-- (no G.terrainLook: the Ygn grass overrides stay off, owner 16 Nov "this grass color is good")
		local r1 = G.paint(h)
		-- farOld replaces Yangon1to1.Green.Far: keep the other districts' far crowns and merge them back
		local green = workspace:FindFirstChild("Yangon1to1") and workspace.Yangon1to1:FindFirstChild("Green")
		local keep = green and green:FindFirstChild("Far")
		if keep then
			keep.Name = "Far_keep"
		end
		local r2 = G.farOld(h)
		if keep then
			local far = green:FindFirstChild("Far")
			for _, c in keep:GetChildren() do
				if far:FindFirstChild(c.Name) then
					c.Name = c.Name .. "_old"
				end
				c.Parent = far
			end
			keep:Destroy()
		end
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
		for _, cell in SS.P3Place_3.Shell:GetChildren() do
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
		local nr = P.shells(SS.P3Place_2.Roofs.Value, b)
		return string.format("shells %d, roof parts %d", n, nr)
	end)
end

-- tools/yangon/PagodaPlace.luau placeOne for the class-M stupas of P3 (both are M)
function M.pagodas()
	return run("pagodas", function()
		local kit = SS.YgnPagodaKit
		local REF, HR = 54, 1.9
		local C = { BASE = 11.61, BELL = 45.9, TOP = 74.79, HTI = 93.15 }
		local GOLD = { mat = Enum.Material.Metal, var = "YgnGoldLeaf", col = Color3.fromRGB(226, 222, 245) }
		local MOSAIC = { mat = Enum.Material.Foil, col = Color3.fromRGB(150, 160, 140), refl = 0.2 }
		local WHITE = { mat = Enum.Material.SmoothPlastic, col = Color3.fromRGB(255, 255, 250) }
		local SCH = {
			gold = { BASE = GOLD, BELL = GOLD, TOP = GOLD, HTI = GOLD },
			mosaic = { BASE = MOSAIC, BELL = MOSAIC, TOP = MOSAIC, HTI = GOLD },
			whitegold = { BASE = WHITE, BELL = GOLD, TOP = GOLD, HTI = GOLD },
		}
		local r = root()
		local folder = r:FindFirstChild("Pagodas") or Instance.new("Folder")
		folder.Name = "Pagodas"
		folder.Parent = r
		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Include
		rp.FilterDescendantsInstances = { workspace.Terrain }
		local out = {}
		for _, row in string.split(SS.P3Place_2.PagodaData.Value, "\n") do
			if row == "" then
				continue
			end
			local f = string.split(row, "|")
			local id, x, z, glo = f[1], tonumber(f[3]), tonumber(f[4]), tonumber(f[5])
			local W, H, shape, yaw, cls, scheme = tonumber(f[6]), tonumber(f[7]), f[8], math.rad(tonumber(f[9])), f[10], f[11]
			assert(cls == "M", "only class M here")
			local lo, n = math.huge, 0
			for _, o in { { 0, 0 }, { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
				local hit = workspace:Raycast(Vector3.new(x + o[1] * W * 0.5, glo + 400, z + o[2] * W * 0.5), Vector3.new(0, -900, 0), rp)
				if hit and math.abs(hit.Position.Y - glo) < 60 then
					lo = math.min(lo, hit.Position.Y)
					n += 1
				end
			end
			local gy = n >= 4 and lo or glo
			local kw, ky = W / REF, H / (HR * REF)
			local old = folder:FindFirstChild(id)
			if old then
				old:Destroy()
			end
			local model = Instance.new("Model")
			model.Name = id
			model:SetAttribute("Name", f[2])
			model:SetAttribute("Class", cls)
			model:SetAttribute("Scheme", scheme)
			model:SetAttribute("Shape", shape)
			model:SetAttribute("Ground", n >= 4 and "terrain" or "GLO-30")
			local base = CFrame.new(x, gy, z) * CFrame.Angles(0, yaw, 0)
			for _, piece in { "BASE_" .. shape, "BELL", "TOP", "HTI" } do
				local key = string.match(piece, "^(%a+)")
				local src = kit:FindFirstChild("PG_M_" .. piece)
				local p = src:Clone()
				p.Size = Vector3.new(src.Size.X * kw, src.Size.Y * ky, src.Size.Z * kw)
				p.CFrame = base * CFrame.new(0, C[key] * ky, 0)
				local lk = (SCH[scheme] or SCH.gold)[key]
				p.Material = lk.mat
				p.MaterialVariant = lk.var or ""
				p.Color = lk.col
				p.Reflectance = lk.refl or 0
				p.Anchored = true
				p.CastShadow = true
				p.Name = key
				p.Parent = model
			end
			local tH = 0.30 * REF * ky
			local col = Instance.new("Part")
			col.Name = "Collide_Base"
			col.Anchored = true
			col.Transparency = 1
			col.CanTouch = false
			col.CastShadow = false
			col.Size = Vector3.new(W, tH, W)
			col.CFrame = base * CFrame.new(0, tH / 2, 0)
			col.Parent = model
			local bH = 0.6 * REF * ky
			local bell = Instance.new("Part")
			bell.Name = "Collide_Bell"
			bell.Shape = Enum.PartType.Cylinder
			bell.Anchored = true
			bell.Transparency = 1
			bell.CanTouch = false
			bell.CastShadow = false
			bell.Size = Vector3.new(bH, 0.6 * W, 0.6 * W)
			bell.CFrame = base * CFrame.new(0, tH + bH / 2, 0) * CFrame.Angles(0, 0, math.rad(90))
			bell.Parent = model
			model.WorldPivot = base
			model.Parent = folder
			for _, p in model:GetChildren() do
				if p:IsA("MeshPart") then
					p.CanCollide = false
					p.CanQuery = false
					p.CanTouch = false
					pcall(function()
						p.CollisionFidelity = Enum.CollisionFidelity.Box
					end)
				end
			end
			table.insert(out, string.format("%s y%.2f", id, gy))
		end
		return table.concat(out, "; ")
	end)
end

-- the 9 downtown landmarks (tools/yangon/landmarks3d/dt_landmarks.py, DowntownPlace) into Yangon1to1.Landmarks
function M.landmarks(ids, pack)
	return run("landmarks", function()
		local D = require(pack.DowntownPlace:Clone())
		local r = root()
		local L = r:FindFirstChild("Landmarks") or Instance.new("Folder")
		L.Name = "Landmarks"
		L.Parent = r
		local out = {}
		for lid, id in ids do
			local m = loadAsset(id)
			table.insert(out, lid .. " " .. D.place(m, pack["Place_" .. lid].Value, L))
			m:Destroy()
			task.wait()
		end
		-- the terrain pads replace the plates the Sule / Botataung models stood on
		for _, nm in { "SulePlate_TEMP", "BotataungPlate_TEMP", "BotataungRiver_TEMP" } do
			local p = L:FindFirstChild(nm)
			if p then
				p:Destroy()
				table.insert(out, "deleted " .. nm)
			end
		end
		return table.concat(out, ", ")
	end)
end

function M.cleanup()
	local n = 0
	for _, nm in { "P3Place_1", "P3Place_2", "P3Place_3" } do
		local f = SS:FindFirstChild(nm)
		if f then
			f:Destroy()
			n += 1
		end
	end
	for _, m in SS.ClaudeTools:GetChildren() do
		if string.sub(m.Name, 1, 10) == "TerrainP3_" then
			m:Destroy()
			n += 1
		end
	end
	return "removed " .. n
end

return M
