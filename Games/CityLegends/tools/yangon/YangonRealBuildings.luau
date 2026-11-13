--[[
	YangonRealBuildings (Studio, Edit mode; Yangon batch 0.5 accuracy pass, 14 Nov 2026, owner: "the buildings rn are not
	accurate", "do everything").

	Builds the REAL buildings (OpenStreetMap outlines, tools/yangon/d19_buildings.py -> ServerStorage.YangonData.Plots2_1..n)
	at their real places, sizes and floor counts:
	  * walkup / shophouse / villa (facing a road): the detailed Yangon kit (YangonBuildings), with the real floors;
	  * tower (10+ floors): YangonBuildings.tower with the real floors and name; an outline wider than 70 studs (a whole
	    complex) gets a podium of 3 floors over the outline and the tower on top;
	  * round (a round outline): a round tower (cylinder) with dark window bands;
	  * mass (inside a block): a light block, its floors' window bands (tag Window: WorldFx lights them at night), a cap,
	    and a water tank on many roofs (Yangon);
	  * the three landmarks (Optima Werkz, Novotel, Myanmar Plaza) as in step 8.
	The step-8 buildings are kept in ServerStorage.YangonBuildings_step8 (moved there the first time).

	local R = require(ServerStorage.ClaudeTools.YangonRealBuildings:Clone())
	R.spawn(function() return R.build() end)   then R.status()
]]

local SS = game:GetService("ServerStorage")
local Http = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")

local M = {}

local terrainOnly = RaycastParams.new()
terrainOnly.FilterType = Enum.RaycastFilterType.Include
local roadsOnly = RaycastParams.new()
roadsOnly.FilterType = Enum.RaycastFilterType.Include

local DARK = Color3.fromRGB(46, 52, 60)
local TANKS = { Color3.fromRGB(30, 32, 34), Color3.fromRGB(34, 70, 140), Color3.fromRGB(196, 196, 190) }
local ROOFS = { Color3.fromRGB(150, 60, 46), Color3.fromRGB(120, 124, 128), Color3.fromRGB(96, 100, 104), Color3.fromRGB(164, 78, 54), Color3.fromRGB(138, 140, 136) }

local function box(name: string, size: Vector3, cf: CFrame, col: Color3, mat: Enum.Material, parent: Instance, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = col
	p.Material = mat
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		p.Shape = shape
	end
	p.CastShadow = size.Y >= 6 and size.X >= 6
	p.Parent = parent
	return p
end

local function hash(s: string): number
	local h = 2166136261
	for k = 1, #s do
		h = bit32.bxor(h, string.byte(s, k))
		h = (h * 16777619) % 4294967296
	end
	return h / 4294967296
end

-- the window bands of a block: one dark band a floor, a little proud of the wall (lit at night, tag Window)
local function bands(m: Model, base: CFrame, W: number, D: number, bottom: number, floors: number, GF: number, FH: number, round: boolean)
	for f = 0, floors - 1 do
		local y = (if f == 0 then GF * 0.45 else GF + (f - 1) * FH + FH * 0.5)
		local hgt = if f == 0 then GF * 0.42 else FH * 0.44
		local p
		if round then
			p = box("Windows", Vector3.new(hgt, D + 0.6, D + 0.6), base * CFrame.new(0, y, 0) * CFrame.Angles(0, 0, math.rad(90)), DARK, Enum.Material.SmoothPlastic, m, Enum.PartType.Cylinder)
		else
			p = box("Windows", Vector3.new(W + 0.4, hgt, D + 0.4), base * CFrame.new(0, y, 0), DARK, Enum.Material.SmoothPlastic, m)
		end
		p.CastShadow = false
		CollectionService:AddTag(p, "Window")
	end
end

-- a light block (inside a block): body, window bands, cap, maybe a water tank
function M.mass(cf: CFrame, W: number, D: number, bottom: number, floors: number, key: string, parent: Instance, B: any): Model
	local m = Instance.new("Model")
	m.Name = "Block"
	local GF, FH = B.GF, B.FH
	local H = GF + math.max(0, floors - 1) * FH
	local col = B.PASTEL[1 + math.floor(hash(key) * #B.PASTEL) % #B.PASTEL]
	if floors >= 8 and hash(key .. "c") < 0.5 then
		col = B.CONDO[1 + math.floor(hash(key .. "d") * #B.CONDO) % #B.CONDO]
	end
	local base = cf * CFrame.new(0, 0, D / 2) -- (cf: the front middle at the floor, looking out of the front; the block is local +Z)
	box("Body", Vector3.new(W, H - bottom, D), base * CFrame.new(0, (H + bottom) / 2, 0), col, Enum.Material.Plaster, m)
	if floors >= 1 then
		bands(m, base, W, D, bottom, floors, GF, FH, false)
	end
	local roof = ROOFS[1 + math.floor(hash(key .. "r") * #ROOFS) % #ROOFS]
	box("Cap", Vector3.new(W + 0.8, 1.4, D + 0.8), base * CFrame.new(0, H + 0.7, 0), if floors <= 3 then roof else col:Lerp(Color3.fromRGB(110, 108, 104), 0.45), Enum.Material.Concrete, m)
	if floors >= 3 and W > 16 and D > 16 and hash(key .. "t") < 0.6 then
		local t = box("Tank", Vector3.new(6, 6, 6), base * CFrame.new((hash(key .. "x") - 0.5) * (W - 10), H + 4.4, (hash(key .. "z") - 0.5) * (D - 10)) * CFrame.Angles(0, 0, math.rad(90)), TANKS[1 + math.floor(hash(key .. "k") * #TANKS) % #TANKS], Enum.Material.SmoothPlastic, m, Enum.PartType.Cylinder)
		t.CastShadow = false
	end
	m.Parent = parent
	return m
end

-- a round tower: a cylinder, its window bands, a cap
function M.round(cf: CFrame, Dia: number, bottom: number, floors: number, key: string, parent: Instance, B: any): Model
	local m = Instance.new("Model")
	m.Name = "RoundTower"
	local GF, FH = B.GF, B.FH
	local H = GF + math.max(0, floors - 1) * FH
	local col = B.CONDO[1 + math.floor(hash(key) * #B.CONDO) % #B.CONDO]
	local base = cf * CFrame.new(0, 0, Dia / 2)
	box("Body", Vector3.new(H - bottom, Dia, Dia), base * CFrame.new(0, (H + bottom) / 2, 0) * CFrame.Angles(0, 0, math.rad(90)), col, Enum.Material.Plaster, m, Enum.PartType.Cylinder)
	bands(m, base, Dia, Dia, bottom, floors, GF, FH, true)
	box("Cap", Vector3.new(2, Dia + 1, Dia + 1), base * CFrame.new(0, H + 1, 0) * CFrame.Angles(0, 0, math.rad(90)), col:Lerp(Color3.fromRGB(80, 84, 92), 0.4), Enum.Material.Concrete, m, Enum.PartType.Cylinder)
	m.Parent = parent
	return m
end

function M.folder(): Instance
	local y = workspace.Yangon
	local f = y:FindFirstChild("Buildings")
	if f and not SS:FindFirstChild("YangonBuildings_step8") then
		f.Name = "YangonBuildings_step8"
		f.Parent = SS
		f = nil
	end
	if not f then
		f = Instance.new("Folder")
		f.Name = "Buildings"
		f.Parent = y
	end
	return f
end

function M.spawn(fn)
	local YD = SS.YangonData
	YD:SetAttribute("RealBuildingsStatus", "running")
	task.spawn(function()
		local t0 = os.clock()
		local ok, res = xpcall(fn, function(e)
			return tostring(e) .. "\n" .. debug.traceback()
		end)
		YD:SetAttribute("RealBuildingsStatus", string.format("%s after %.0f s: %s", if ok then "done" else "ERROR", os.clock() - t0, tostring(res)))
	end)
end

function M.status(): string
	return tostring(SS.YangonData:GetAttribute("RealBuildingsStatus"))
end

function M.build(opts)
	opts = opts or {}
	local B = require(SS.ClaudeTools.YangonBuildings:Clone())
	local YD = SS.YangonData
	local pieces, k = {}, 1
	while YD:FindFirstChild("Plots2_" .. k) do
		pieces[k] = require(YD["Plots2_" .. k]:Clone())
		k += 1
	end
	local plots = Http:JSONDecode(table.concat(pieces)).plots
	local parent = M.folder()
	if not opts.keep then
		for i, c in parent:GetChildren() do
			c:Destroy()
			if i % 300 == 0 then
				task.wait()
			end
		end
	end
	terrainOnly.FilterDescendantsInstances = { workspace.Terrain }
	roadsOnly.FilterDescendantsInstances = { workspace.Yangon.Roads }
	local made, skipped, kinds, parts = 0, 0, {}, 0
	for i, p in plots do
		if opts.limit and made >= opts.limit then
			break
		end
		local prng = Random.new(5000 + i)
		local style = p.landmark or p.style or "mass"
		local key = tostring(p.osm or i)
		local f = Vector3.new(p.fx, 0, p.fz) -- (from the front to the back)
		local centre = Vector3.new(p.x, 0, p.z)
		local front = centre - f * (p.d / 2)
		-- floor: the pavement in front (buildings facing a road), else the ground at the front
		local hit = workspace:Raycast(Vector3.new((front - f * (B.SETBACK + 2.5)).X, 400, (front - f * (B.SETBACK + 2.5)).Z), Vector3.new(0, -600, 0), roadsOnly)
		local tg = workspace:Raycast(Vector3.new(front.X, 400, front.Z), Vector3.new(0, -600, 0), terrainOnly)
		if not hit and not tg then
			skipped += 1
			continue
		end
		local inside = style == "mass" or style == "round"
		local floorY = if hit and not inside then hit.Position.Y elseif tg then tg.Position.Y + 0.4 else hit.Position.Y
		-- (the kit's frame: at the front middle, looking OUT of the front towards the road; the building is local +Z)
		local cf = CFrame.lookAt(Vector3.new(front.X, floorY, front.Z), Vector3.new(front.X, floorY, front.Z) - f)
		local gnd, water, above = {}, false, -math.huge
		for _, c in { { -1, 0 }, { 1, 0 }, { -1, 1 }, { 1, 1 } } do
			local wp = cf * Vector3.new(c[1] * p.w / 2, 0, c[2] * p.d)
			local g = workspace:Raycast(Vector3.new(wp.X, 400, wp.Z), Vector3.new(0, -600, 0), terrainOnly)
			local gy = if g then g.Position.Y else floorY - 6
			if g and g.Material == Enum.Material.Water then
				water = true
			end
			above = math.max(above, gy - floorY)
			table.insert(gnd, math.min(0, gy - floorY))
		end
		if water and not p.landmark then
			skipped += 1
			continue
		end
		if above > 0.5 then
			workspace.Terrain:FillBlock(cf * CFrame.new(0, above / 2 + 40, p.d / 2), Vector3.new(p.w, 80 + above, p.d), Enum.Material.Air)
		end
		local bottom = math.min(gnd[1], gnd[2], gnd[3], gnd[4]) - 2
		local floors = p.floors or 4
		local m
		if style == "walkup" then
			m = B.walkup(cf, p.w, p.d, gnd, prng, parent, math.max(2, floors - 1), true, true)
		elseif style == "shophouse" then
			m = B.shophouse(cf, p.w, p.d, gnd, prng, parent, math.max(1, floors - 1), true)
		elseif style == "villa" then
			m = B.villa(cf, p.w, p.d, gnd, prng, parent)
		elseif style == "tower" then
			local name = if p.name and p.name ~= "" then string.upper(p.name) else B.TOWER_NAMES[prng:NextInteger(1, #B.TOWER_NAMES)]
			if p.w > 70 or p.d > 70 then
				-- a complex: a 3-floor podium over the outline, the tower on it at the back middle
				local pod = M.mass(cf, p.w, p.d, bottom, 3, key, parent, B)
				pod.Name = "Podium"
				local tw, td = math.min(p.w * 0.7, 60), math.min(p.d * 0.6, 56)
				local podH = B.GF + 2 * B.FH + 1.4
				local tcf = cf * CFrame.new(0, podH, (p.d - td) / 2)
				m = B.tower(tcf, tw, td, { 0, 0, 0, 0 }, prng, parent, math.max(4, floors - 3), name)
				m:SetAttribute("Podium", true)
				pod.Parent = m
			else
				m = B.tower(cf, p.w, p.d, gnd, prng, parent, math.max(4, floors - 1), name)
			end
		elseif style == "round" then
			m = M.round(cf, math.min(p.w, p.d), bottom, floors, key, parent, B)
		elseif style == "optima" then
			m = B.optima(cf, p.w, p.d, gnd, prng, parent)
		elseif style == "novotel" then
			m = B.novotel(cf, p.w, p.d, gnd, prng, parent)
		elseif style == "mmplaza" then
			m = B.mmplaza(cf, p.w, p.d, gnd, prng, parent)
		else
			m = M.mass(cf, p.w, p.d, bottom, floors, key, parent, B)
		end
		if m then
			m:SetAttribute("Plot", i)
			m:SetAttribute("Osm", p.osm)
			m:SetAttribute("Floors", floors)
			if p.name and p.name ~= "" then
				m:SetAttribute("RealName", p.name)
			end
			made += 1
			kinds[style] = (kinds[style] or 0) + 1
			for _, d in m:GetDescendants() do
				if d:IsA("BasePart") then
					parts += 1
				end
			end
		end
		if made % 12 == 0 then
			task.wait()
		end
	end
	-- no two faces on one plane: the kit's fixer
	local moved, left = 0, 0
	local un = SS.ClaudeTools:FindFirstChild("Unstack")
	if un then
		moved, left = (require(un:Clone()) :: any).all(parent)
	end
	local t = {}
	for kk, v in kinds do
		table.insert(t, kk .. " " .. v)
	end
	return string.format("%d buildings (%s), %d skipped, %d parts; unstack moved %d, %d left", made, table.concat(t, ", "), skipped, parts, moved, left)
end

return M
