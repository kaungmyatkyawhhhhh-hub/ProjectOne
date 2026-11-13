--[[
	YangonSites (Studio, Edit mode; Yangon build step 9, 2026-11-13): gets the venue lots in Yangon ready, like
	tools/riviera/Sites.luau does in Monaco, and builds the Yangon fuel station on its lot.

	A lot is WestLayout.Lot (216) square, its middle (x, z), entrance facing (fx, fz) towards its road, floor y
	(level with the pavement). prepare() takes away the Yangon buildings standing in it (to
	ServerStorage.YangonSiteHidden/<name>, so undo() can put them back), cuts the terrain above the floor and
	fills it below, and lays a flat pad (Workspace.Yangon.Sites/<name>).

	local S = require(ServerStorage.ClaudeTools.YangonSites:Clone())
	S.prepare(sites, names?)      sites: { [name] = { x, z, fx, fz, y, size?, w? } } (Config.YangonVenues.Sites; w = width when wider)
	S.fuel(id, name, site, CareVenues, litre, kwh) -> the station's pumps / chargers / arrive for Config.Fuel.Stations
	S.undo(name)
]]

local ServerStorage = game:GetService("ServerStorage")

local S = {}

local LOT = 216
local MARGIN = 8

local function frameOf(s): CFrame
	local c = Vector3.new(s.x, s.y, s.z)
	return CFrame.lookAt(c, c + Vector3.new(s.fx, 0, s.fz).Unit)
end

-- (w: the lot's width across the front, when wider than deep: Legends Rewards' car courts)
local function inside(cf: CFrame, p: Vector3, grow: number, lot: number, w: number?): boolean
	local l = cf:PointToObjectSpace(p)
	return math.abs(l.X) < (w or lot) / 2 + grow and l.Z > -lot / 2 - 2 and l.Z < lot / 2 + grow
end

local function hidden(name: string): Folder
	local root = ServerStorage:FindFirstChild("YangonSiteHidden") or Instance.new("Folder")
	root.Name = "YangonSiteHidden"
	root.Parent = ServerStorage
	local f = root:FindFirstChild(name) or Instance.new("Folder")
	f.Name = name
	f.Parent = root
	return f :: Folder
end

function S.prepare(sites: { [string]: any }, names: { string }?): string
	local Y = workspace.Yangon
	local folder = Y:FindFirstChild("Sites") or Instance.new("Folder")
	folder.Name = "Sites"
	folder.Parent = Y
	local T = workspace.Terrain
	local out = {}
	for name, s in sites do
		if names and not table.find(names, name) then
			continue
		end
		local cf = frameOf(s)
		local lot = s.size or LOT
		local w = s.w or lot
		-- buildings with any corner (or middle) of their box in the lot
		local moved = 0
		local keep = hidden(name)
		for _, m in Y.Buildings:GetChildren() do
			if not m:IsA("Model") or m:GetAttribute("MeetSpot") then
				continue
			end
			local bcf, bsz = m:GetBoundingBox()
			local hit = false
			for _, ox in { -0.5, 0, 0.5 } do
				for _, oz in { -0.5, 0, 0.5 } do
					if inside(cf, (bcf * CFrame.new(bsz.X * ox, 0, bsz.Z * oz)).Position, MARGIN, lot, w) then
						hit = true
					end
				end
			end
			if hit then
				m.Parent = keep
				moved += 1
			end
		end
		-- terrain: air above the floor, ground below it
		local span = Vector3.new(w + MARGIN * 2, 0, lot + MARGIN + 2)
		local mid = cf * CFrame.new(0, 0, (MARGIN - 2) / 2)
		T:FillBlock(mid * CFrame.new(0, 80, 0), Vector3.new(span.X, 160, span.Z), Enum.Material.Air)
		T:FillBlock(mid * CFrame.new(0, -26, 0), Vector3.new(span.X, 40, span.Z), Enum.Material.Ground)
		T:FillBlock(mid * CFrame.new(0, -1, 0), Vector3.new(span.X + 2, 9, span.Z + 2), Enum.Material.Air)
		-- grass round the pad's edge, so it doesn't stand on air where the ground falls away
		T:FillBlock(mid * CFrame.new(0, -14, 0), Vector3.new(span.X + 12, 18, span.Z + 12), Enum.Material.Grass)
		T:FillBlock(mid * CFrame.new(0, -1, 0), Vector3.new(span.X + 2, 9, span.Z + 2), Enum.Material.Air)
		local old = folder:FindFirstChild(name)
		if old then
			old:Destroy()
		end
		local pad = Instance.new("Part")
		pad.Name = name
		pad.Anchored = true
		pad.Size = Vector3.new(span.X, 4, span.Z)
		pad.CFrame = mid * CFrame.new(0, -2, 0)
		pad.Material = Enum.Material.Concrete
		pad.Color = Color3.fromRGB(150, 146, 138)
		pad.TopSurface = Enum.SurfaceType.Smooth
		pad.BottomSurface = Enum.SurfaceType.Smooth
		pad.CastShadow = false
		pad:SetAttribute("Venue", name)
		pad.Parent = folder
		table.insert(out, string.format("%s: %d buildings moved", name, moved))
		task.wait()
	end
	return table.concat(out, "; ")
end

function S.undo(name: string)
	local pad = workspace.Yangon:FindFirstChild("Sites") and workspace.Yangon.Sites:FindFirstChild(name)
	if pad then
		pad:Destroy()
	end
	local root = ServerStorage:FindFirstChild("YangonSiteHidden")
	local f = root and root:FindFirstChild(name)
	if f then
		for _, m in f:GetChildren() do
			m.Parent = workspace.Yangon.Buildings
		end
		f:Destroy()
	end
end

-- the fuel station on a prepared lot: its forecourt starts at the lot's front edge (the road side)
function S.fuel(id: string, name: string, s, V, litre: number, kwh: number): string
	V.root = workspace.Yangon
	V.clearIn = workspace.Yangon.Buildings
	V.brand = { "LEGENDS", "FUEL" }
	local cf = frameOf(s)
	local f = Vector3.new(s.fx, 0, s.fz).Unit
	local o = cf.Position + f * ((s.size or LOT) / 2)
	local Z = -f
	local X = Vector3.yAxis:Cross(Z)
	local frame = CFrame.fromMatrix(o, X, Vector3.yAxis, Z)
	local r = V.station({ id = id, name = name, frame = frame, depth = 4, litre = litre, kwh = kwh })
	V.root, V.clearIn, V.brand = nil, nil, nil
	local function v3(p: Vector3): string
		return string.format("Vector3.new(%.1f, %.1f, %.1f)", p.X, p.Y, p.Z)
	end
	local pumps, chargers = {}, {}
	for _, p in r.pumps do
		table.insert(pumps, v3(p))
	end
	for _, p in r.chargers do
		table.insert(chargers, v3(p))
	end
	local a = r.arrive
	local c = { a:GetComponents() }
	for i, n in c do
		c[i] = string.format(if i <= 3 then "%.1f" else "%.4f", n)
	end
	return string.format('{ id = "%s", name = "%s", pumps = { %s }, chargers = { %s }, arrive = CFrame.new(%s) },', id, name, table.concat(pumps, ", "), table.concat(chargers, ", "), table.concat(c, ", "))
end

return S
