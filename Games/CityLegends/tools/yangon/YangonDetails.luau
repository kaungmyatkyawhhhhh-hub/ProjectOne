--[[
	YangonDetails (Studio, Edit mode; Yangon whole-map plan step A6, 14 Nov 2026, owner: "the ingame yangon is too clean ...
	in real life its compact", "wheres the fusan basketball court, u need to add EVERY single detail").

	Places the detail layer made by tools/yangon/city/details.py (OpenStreetMap contributors, ODbL) from the data modules
	ServerStorage.ClaudeTools.Details_05_1 .. Details_05_<n> (each returns ONE string; read in order and joined) into
	Workspace.Yangon.Details/<kind>/<256-stud cell>/<item Model>. Kinds: sport, sportfence, pool, parking, worship, busstop,
	signal, tree, gate, wall, fence, hedge, compound, footbridge, shopsign, teashop, pole, kerbtree, trishaw, patch.

	Every item's height comes from rays at place time onto the terrain, Workspace.Yangon.Roads (Road / Pavement / Kerb ...)
	and Workspace.Yangon.StreetCollide (the mesh streets' collision boxes; when it is missing the terrain is used and an item
	marked S, standing on a mesh street's pavement, is lifted 0.75, the pavement's height over the ground). Modes:
	  G  one ray at the item;   M  the highest of 5 rays (the item and its 4 corners ex / ez);
	  R  all 5 rays must land on a part named "Road" (road patches, footbridges), and a patch that would lie on a road line
	     is left out (a patch 0.06 over the asphalt and a line 0.08 over it would flicker).
	Data lines (see details.py's header): Q palette, D/E prototype, I item, U prototype use, B/C/H/S/W part, T text, K kit tree.
	Power-line wires are Beams between the crossarms of consecutive poles of one chain (0 parts). Signal lamps are Neon, no
	Light objects. Small things (tea sets, trishaws, patches, shop signs) sit in cells tagged LOD (Center / Range 340) so
	client/WorldFx.lua hides them far away. Only poles, walls, fences, hedges, gates, shelters, stupas / churches,
	footbridges and signal poles collide; CastShadow only on walls, buildings, shelters, footbridges, gates.

	THE EXACT STEPS (Studio, Edit, the Yangon place; nothing else may be running a build):
	  1. From Games/CityLegends:
	       python tools/yangon/city/details.py
	       python tools/yangon/city/details_test.py
	       python tools/yangon/pack_sync.py imports/sync/yangon_tools_1.rbxmx tools/yangon/YangonDetails.luau build/city/Details_05_1.luau ... build/city/Details_05_<n>.luau
	     (every Details_05_*.luau that details.py printed), upload as usual (Model asset 133014134133489), insert_asset,
	     then move YangonToolsIn.Tools' ModuleScripts into ServerStorage.ClaudeTools (replace the old ones).
	  2. In the command bar (or execute_luau):
	       local D = require(game.ServerStorage.ClaudeTools.YangonDetails:Clone())
	       D.spawn()                                   -- builds everything (clears Workspace.Yangon.Details first)
	       D.spawn({ only = { "pole", "compound" } })  -- or rebuild some kinds only (clears only those folders)
	     then poll  require(game.ServerStorage.ClaudeTools.YangonDetails:Clone()).status()  (or ServerStorage.YangonData's
	     attribute DetailsStatus) until it says "done".  D.undo() removes the whole layer.
	  3. Re-run after the roads, the street collision, the plots, the lots or the lamps change (like the lamps).
	The GreenKit trees come from ServerStorage.YangonData.GreenKit (YangonGreen.kit() makes it).
]]

local SS = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

local M = {}

local COLLIDE = {
	pole = true, wall = true, compound = true, fence = true, hedge = true, sportfence = true, busstop = true,
	worship = true, gate = true, footbridge = true, signal = true,
}
local SHADOW = { wall = true, compound = true, worship = true, footbridge = true, busstop = true, gate = true }
local LODK = { teashop = true, trishaw = true, patch = true, shopsign = true }
local LOD_RANGE = 340
local CELL = 256
local WIRE_MAX = 95
local STREET_LIFT = 0.75
local FONT = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold)

local function holder(): Instance
	return SS:FindFirstChild("YangonData") or SS
end

function M.data(): string
	local parts = {}
	for i = 1, 99 do
		local name = "Details_05_" .. i
		local src = SS.ClaudeTools:FindFirstChild(name) or (SS:FindFirstChild("YangonData") and SS.YangonData:FindFirstChild(name))
		if not src then
			break
		end
		table.insert(parts, require((src :: ModuleScript):Clone()))
	end
	assert(#parts > 0, "no Details_05_1 in ServerStorage.ClaudeTools")
	return table.concat(parts, "\n")
end

local function nums(line: string): { string }
	return string.split(line, " ")
end

-- a GreenKit tree with its foot at ground height g (as YangonGreen's tree()); returns the trunk part
local function kitTree(kit: Instance, name: string, x: number, g: number, z: number, wide: number, yaw: number, parent: Instance): (Model?, BasePart?)
	local src = kit:FindFirstChild(name) :: Model?
	if not src then
		return nil, nil
	end
	local t = src:Clone()
	local _, size = t:GetBoundingBox()
	t:ScaleTo(t:GetScale() * (wide / math.max(size.X, size.Z)))
	local cf, sz = t:GetBoundingBox()
	local foot = CFrame.new(x, g - 0.4, z) * CFrame.Angles(0, yaw, 0)
	t:PivotTo(foot * (CFrame.new(cf.Position - Vector3.new(0, sz.Y / 2, 0)):Inverse() * t:GetPivot()))
	local trunk: BasePart? = nil
	for _, d in t:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			if d.Name == "Trunk" then
				trunk = d
			end
			if d.Size.Y < sz.Y * 0.6 or d.Position.Y > g + sz.Y * 0.45 then
				d.CanCollide = false
			end
		end
	end
	t.Name = "YangonTree"
	t.Parent = parent
	return t, trunk
end

-- the white (or red and white) lime band round a kerb tree's trunk, measured with rays against the trunk itself
local function trunkBand(trunk: BasePart, x: number, g: number, z: number, band: number, parent: Instance, pal: { any })
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { trunk }
	local y = g + 1.6
	local hits = {}
	for _, d in { Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, 0, -1) } do
		local h = workspace:Raycast(Vector3.new(x, y, z) + d * 9, -d * 18, rp)
		if not h then
			return
		end
		table.insert(hits, h.Position)
	end
	local cx, cz = (hits[1].X + hits[2].X) / 2, (hits[3].Z + hits[4].Z) / 2
	local r = math.max(math.abs(hits[1].X - hits[2].X), math.abs(hits[3].Z - hits[4].Z)) / 2
	if r > 3 then
		return -- a hull, not a trunk: leave it
	end
	local d = 2 * r + 0.16
	local function ring(lo: number, hi: number, col: Color3)
		local p = Instance.new("Part")
		p.Name = "TrunkBand"
		p.Shape = Enum.PartType.Cylinder
		p.Size = Vector3.new(hi - lo, d, d)
		p.CFrame = CFrame.new(cx, g + (lo + hi) / 2, cz) * CFrame.Angles(0, 0, math.pi / 2)
		p.Color = col
		p.Material = Enum.Material.SmoothPlastic
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Parent = parent
	end
	if band == 2 then
		ring(-0.3, 1.6, Color3.fromRGB(196, 40, 36))
		ring(1.6, 3.4, Color3.fromRGB(238, 236, 228))
	else
		ring(-0.3, 3.4, Color3.fromRGB(238, 236, 228))
	end
end

local function makePart(spec: { any }, itemCF: CFrame, kind: string, pal: { any }, parent: Instance): BasePart
	local shape = spec[1]
	local sx, sy, sz = spec[2], spec[3], spec[4]
	local p: BasePart
	if shape == "W" then
		p = Instance.new("WedgePart")
		p.Size = Vector3.new(sx, sy, sz)
	else
		local q = Instance.new("Part")
		if shape == "C" then
			q.Shape = Enum.PartType.Cylinder
			q.Size = Vector3.new(sy, sx, sz)
		elseif shape == "H" then
			q.Shape = Enum.PartType.Cylinder
			q.Size = Vector3.new(sx, sy, sz)
		elseif shape == "S" then
			q.Shape = Enum.PartType.Ball
			q.Size = Vector3.new(sx, sx, sx)
		else
			q.Size = Vector3.new(sx, sy, sz)
		end
		p = q
	end
	local cf = itemCF * CFrame.new(spec[5], spec[6], spec[7]) * CFrame.fromEulerAnglesYXZ(math.rad(spec[9]), math.rad(spec[8]), math.rad(spec[10]))
	if shape == "C" then
		cf = cf * CFrame.Angles(0, 0, math.pi / 2)
	end
	p.CFrame = cf
	local c = pal[spec[11]]
	p.Color = c[1]
	p.Material = c[2]
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	local collide = COLLIDE[kind] == true and math.max(sx, sy, sz) >= 1
	p.CanCollide = collide
	p.CanQuery = collide
	p.CanTouch = false
	p.CastShadow = SHADOW[kind] == true and sy >= 3
	p.Parent = parent
	if spec.text then
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 40
		gui.LightInfluence = 0.6
		gui.MaxDistance = 260
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.fromScale(0.92, 0.8)
		t.Position = UDim2.fromScale(0.04, 0.1)
		t.TextScaled = true
		t.FontFace = FONT
		t.Text = spec.text[2]
		t.TextColor3 = if spec.text[1] == "w" then Color3.fromRGB(250, 250, 248) else Color3.fromRGB(24, 24, 28)
		t.Parent = gui
		gui.Parent = p
	end
	return p
end

function M.build(opts: { [string]: any }?): string
	local o = opts or {}
	local only: { [string]: boolean }? = nil
	if o.only then
		only = {}
		for k, v in o.only do
			if type(k) == "number" then
				(only :: any)[v] = true
			else
				(only :: any)[k] = v
			end
		end
	end
	local Y = workspace.Yangon
	local root = Y:FindFirstChild("Details")
	if root and not only then
		root:Destroy()
		root = nil
	end
	if not root then
		root = Instance.new("Folder")
		root.Name = "Details"
		root.Parent = Y
	end
	if only then
		for k in only do
			local f = root:FindFirstChild(k)
			if f then
				f:Destroy()
			end
		end
	end
	local kit = SS:FindFirstChild("YangonData") and SS.YangonData:FindFirstChild("GreenKit")

	local include = { workspace.Terrain, Y:FindFirstChild("Roads") }
	if Y:FindFirstChild("StreetCollide") then
		table.insert(include, Y.StreetCollide)
	end
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = include
	rp.IgnoreWater = true
	local op = OverlapParams.new()
	op.FilterType = Enum.RaycastFilterType.Include
	op.FilterDescendantsInstances = { Y:FindFirstChild("Roads") }

	local function ray(x: number, z: number, yh: number?): RaycastResult?
		local top = if yh then yh + 40 else 900
		local len = if yh then 130 else 1400
		return workspace:Raycast(Vector3.new(x, top, z), Vector3.new(0, -len, 0), rp)
	end

	local pal: { [number]: { any } } = {}
	local protos: { [string]: { { any } } } = {}
	local cells: { [string]: Model } = {}
	local kindFolders: { [string]: Folder } = {}
	local chainLast: { [number]: { arm: BasePart, pos: Vector3 } } = {}
	local stats: { [string]: { number } } = {}
	local made, partsMade, wires = 0, 0, 0
	local rng = Random.new(20261114)

	local function cellFor(kind: string, x: number, y: number, z: number): Model
		local f = kindFolders[kind]
		if not f then
			f = root:FindFirstChild(kind) :: Folder?
			if not f then
				f = Instance.new("Folder")
				f.Name = kind
				f.Parent = root
			end
			kindFolders[kind] = f :: Folder
		end
		local cx, cz = math.floor(x / CELL), math.floor(z / CELL)
		local key = kind .. ":" .. cx .. "_" .. cz
		local c = cells[key]
		if not c then
			c = Instance.new("Model")
			c.Name = cx .. "_" .. cz
			if LODK[kind] then
				c:SetAttribute("Center", Vector3.new((cx + 0.5) * CELL, y, (cz + 0.5) * CELL))
				c:SetAttribute("Range", LOD_RANGE)
				CollectionService:AddTag(c, "LOD")
			end
			c.Parent = f
			cells[key] = c
		end
		return c :: Model
	end

	local function stat(kind: string, ok: boolean)
		local s = stats[kind]
		if not s then
			s = { 0, 0 }
			stats[kind] = s
		end
		s[if ok then 1 else 2] += 1
	end

	local function wire(a: BasePart, b: BasePart)
		for _, z in { -1.9, 0, 1.9 } do
			local att0 = Instance.new("Attachment")
			att0.Parent = a
			att0.WorldCFrame = CFrame.fromMatrix((a.CFrame * CFrame.new(0, 0.15, z)).Position, Vector3.new(0, -1, 0), Vector3.new(1, 0, 0))
			local att1 = Instance.new("Attachment")
			att1.Parent = b
			att1.WorldCFrame = CFrame.fromMatrix((b.CFrame * CFrame.new(0, 0.15, z)).Position, Vector3.new(0, -1, 0), Vector3.new(1, 0, 0))
			local dist = (att0.WorldPosition - att1.WorldPosition).Magnitude
			local sag = dist * 0.045 + rng:NextNumber(0, 0.6)
			local beam = Instance.new("Beam")
			beam.Attachment0 = att0
			beam.Attachment1 = att1
			beam.Width0 = 0.12
			beam.Width1 = 0.12
			beam.Color = ColorSequence.new(Color3.fromRGB(20, 20, 22))
			beam.Transparency = NumberSequence.new(0)
			beam.LightInfluence = 1
			beam.FaceCamera = true
			beam.Segments = 12
			beam.CurveSize0 = sag
			beam.CurveSize1 = -sag
			beam.Texture = ""
			beam.Parent = b
			wires += 1
		end
	end

	local function place(it: { any })
		local kind = it.kind
		local mode = string.sub(it.mode, 1, 1)
		local lift = string.sub(it.mode, 2, 2) == "S"
		local pts = { { it.x, it.z } }
		if (mode == "M" or mode == "R") and (it.ex > 0 or it.ez > 0) then
			local c, s = math.cos(math.rad(it.yaw)), math.sin(math.rad(it.yaw))
			for _, uv in { { -1, -1 }, { 1, -1 }, { 1, 1 }, { -1, 1 } } do
				local u, v = uv[1] * it.ex, uv[2] * it.ez
				table.insert(pts, { it.x + u * c + v * s, it.z - u * s + v * c })
			end
		end
		local y: number? = nil
		local terrainHit = false
		for _, q in pts do
			local h = ray(q[1], q[2], it.yh)
			if mode == "R" and (not h or h.Instance.Name ~= "Road") then
				stat(kind, false)
				return
			end
			if h and (y == nil or h.Position.Y > (y :: number)) then
				y = h.Position.Y
				terrainHit = h.Instance == workspace.Terrain
			end
		end
		if y == nil then
			stat(kind, false)
			return
		end
		local gy = y :: number
		if lift and terrainHit then
			gy += STREET_LIFT
		end
		local cf = CFrame.new(it.x, gy, it.z) * CFrame.Angles(0, math.rad(it.yaw), 0)
		if kind == "patch" then
			local spec = it.parts[1]
			if spec then
				local pcf = cf * CFrame.new(spec[5], spec[6], spec[7]) * CFrame.fromEulerAnglesYXZ(0, math.rad(spec[8]), 0)
				for _, q in workspace:GetPartBoundsInBox(pcf, Vector3.new(spec[2], 1, spec[4]), op) do
					if q.Name ~= "Road" and q.Position.Y + q.Size.Y / 2 > gy - 0.2 then
						stat(kind, false)
						return
					end
				end
			end
		end
		local model = Instance.new("Model")
		model.Name = if it.name then kind .. " " .. it.name else kind
		local all = {}
		for _, u in it.uses do
			for _, spec in protos[u] or {} do
				table.insert(all, spec)
			end
		end
		for _, spec in it.parts do
			table.insert(all, spec)
		end
		local created = {}
		for _, spec in all do
			table.insert(created, makePart(spec, cf, kind, pal, model))
		end
		partsMade += #created
		for _, k in it.kits do
			if kit then
				local tm, trunk = kitTree(kit, k[1], it.x, gy, it.z, k[2], math.rad(it.yaw), model)
				if tm and trunk and k[3] > 0 then
					trunkBand(trunk :: BasePart, it.x, gy, it.z, k[3], model, pal)
				end
				partsMade += 3
			end
		end
		model.Parent = cellFor(kind, it.x, gy, it.z)
		if kind == "pole" and it.chain > 0 and created[2] then
			local arm = created[2]
			local last = chainLast[it.chain]
			if last and (last.pos - arm.Position).Magnitude < WIRE_MAX then
				wire(last.arm, arm)
			end
			chainLast[it.chain] = { arm = arm, pos = arm.Position }
		end
		made += 1
		stat(kind, true)
		if made % 60 == 0 then
			task.wait()
		end
	end

	local data = M.data()
	local cur: { any }? = nil
	local protoName: string? = nil
	local lastSpec: { any }? = nil
	for line in string.gmatch(data, "[^\n]+") do
		local c = string.sub(line, 1, 1)
		local w = nums(line)
		if c == "I" then
			if cur then
				place(cur)
			end
			cur = nil
			if not only or (only :: any)[w[2]] then
				cur = {
					kind = w[2], x = tonumber(w[3]), z = tonumber(w[4]), yh = tonumber(w[5]), yaw = tonumber(w[6]),
					ex = tonumber(w[7]), ez = tonumber(w[8]), mode = w[9], chain = tonumber(w[10]) or 0,
					parts = {}, uses = {}, kits = {}, name = nil,
				}
			end
			lastSpec = nil
		elseif c == "B" or c == "C" or c == "H" or c == "S" or c == "W" then
			local spec = {
				c, tonumber(w[2]), tonumber(w[3]), tonumber(w[4]), tonumber(w[5]), tonumber(w[6]), tonumber(w[7]),
				tonumber(w[8]), tonumber(w[9]), tonumber(w[10]), tonumber(w[11]),
			}
			if protoName then
				table.insert(protos[protoName :: string], spec)
			elseif cur then
				table.insert((cur :: any).parts, spec)
			end
			lastSpec = spec
		elseif c == "T" then
			if lastSpec then
				(lastSpec :: any).text = { w[2], string.sub(line, 5) }
				if cur and protoName == nil then
					(cur :: any).name = (cur :: any).name or string.sub(line, 5)
				end
			end
		elseif c == "U" then
			if cur then
				table.insert((cur :: any).uses, w[2])
			end
		elseif c == "K" then
			if cur then
				table.insert((cur :: any).kits, { w[2], tonumber(w[3]), tonumber(w[4]) })
			end
		elseif c == "Q" then
			pal[tonumber(w[2]) :: number] = {
				Color3.fromRGB(tonumber(w[3]) :: number, tonumber(w[4]) :: number, tonumber(w[5]) :: number),
				(Enum.Material :: any)[w[6]] or Enum.Material.SmoothPlastic,
			}
		elseif c == "D" then
			protoName = w[2]
			protos[w[2]] = {}
		elseif c == "E" then
			protoName = nil
		end
	end
	if cur then
		place(cur)
	end
	local out = {}
	for k, s in stats do
		table.insert(out, string.format("%s %d/%d", k, s[1], s[1] + s[2]))
	end
	table.sort(out)
	return string.format("details: %d items, %d parts, %d wire beams; placed/tried: %s", made, partsMade, wires, table.concat(out, ", "))
end

function M.undo()
	local d = workspace.Yangon:FindFirstChild("Details")
	if d then
		d:Destroy()
	end
end

function M.status(): string
	return tostring(holder():GetAttribute("DetailsStatus"))
end

-- spawn()  /  spawn({ only = { "pole" } })  /  spawn(function() return ... end)
function M.spawn(arg: any)
	local h = holder()
	h:SetAttribute("DetailsStatus", "running")
	task.spawn(function()
		local t0 = os.clock()
		local ok, res = pcall(function()
			if type(arg) == "function" then
				return arg()
			end
			return M.build(arg)
		end)
		h:SetAttribute("DetailsStatus", string.format("%s after %.1f s: %s", if ok then "done" else "ERROR", os.clock() - t0, tostring(res)))
	end)
end

return M
