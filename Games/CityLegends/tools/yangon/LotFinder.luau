--[[
	LotFinder (Studio, Edit; 24 Nov 2026, OVERLAPS FIX agent): the nearest free lot beside a road for a venue / house lot
	that a road runs through.

	local F = require(ServerStorage.ClaudeTools.LotFinder:Clone())   (or paste and use _G.LotFinder)
	F.find({ x, z, w, d, radius?, avoid? }) -> { {x, y, z, fx, fz, dist, shells}, ... } best first
	    w = width across the front, d = depth (YangonSites: size). The pad YangonSites.prepare lays is (w + 16) x (d + 10),
	    3 studs behind the lot's middle. A candidate fronts a pavement (P box): its front edge 3 studs behind the pavement's
	    outer side, facing it. Free = no road / pavement box, landmark, park, other lot pad, pagoda, car-care venue or deck
	    in the pad grown by 6 (shells and far trees are fine: prepare deletes them), no water, the ground under it within
	    16 studs of the floor, and the floor (the pavement top) within 3 of the road top in front.
	    avoid = extra {CFrame, Vector3} boxes (lots already picked this run); self = its own pad's name (ignored).
]]

local F = {}

local function blockers(): { Instance }
	local Y = workspace.Yangon1to1
	local t = {}
	for _, n in { "Roads", "Landmarks", "Parks", "Sites", "CarCare", "Pagodas", "InyaBund" } do
		local f = Y:FindFirstChild(n)
		if f then
			table.insert(t, f)
		end
	end
	for _, c in Y.Green:GetChildren() do
		if c.Name ~= "Far" then
			table.insert(t, c)
		end
	end
	return t
end

function F.find(o): { any }
	local Y = workspace.Yangon1to1
	local R = o.radius or 1500
	local centre = Vector3.new(o.x, 0, o.z)
	local inc = OverlapParams.new()
	inc.FilterType = Enum.RaycastFilterType.Include
	inc.FilterDescendantsInstances = { Y.Roads.Collide }
	local blk = OverlapParams.new()
	blk.FilterType = Enum.RaycastFilterType.Include
	blk.FilterDescendantsInstances = blockers()
	local rayR = RaycastParams.new()
	rayR.FilterType = Enum.RaycastFilterType.Include
	rayR.FilterDescendantsInstances = { Y.Roads.Collide }
	local rayT = RaycastParams.new()
	rayT.FilterType = Enum.RaycastFilterType.Include
	rayT.FilterDescendantsInstances = { workspace.Terrain }
	rayT.IgnoreWater = false
	local shellP = OverlapParams.new()
	shellP.FilterType = Enum.RaycastFilterType.Include
	shellP.FilterDescendantsInstances = { Y.Buildings }
	-- pavement boxes near: candidate fronts
	local boxes = workspace:GetPartBoundsInBox(CFrame.new(o.x, 100, o.z), Vector3.new(2 * R, 600, 2 * R), inc)
	local cands = {}
	for _, b in boxes do
		if b:GetAttribute("RoadBox") ~= "P" then
			continue
		end
		local cf, s = b.CFrame, b.Size
		local along = if s.X >= s.Z then cf.RightVector else cf.LookVector
		local across = if s.X >= s.Z then cf.LookVector else cf.RightVector
		local halfAcross = (if s.X >= s.Z then s.Z else s.X) / 2
		along = Vector3.new(along.X, 0, along.Z).Unit
		across = Vector3.new(across.X, 0, across.Z).Unit
		for _, sgn in { 1, -1 } do
			local n = across * sgn -- out of the road, away from the pavement
			-- the carriageway must be on the other side
			local road = workspace:Raycast(b.Position - n * (halfAcross + 4) + Vector3.new(0, 200, 0), Vector3.new(0, -400, 0), rayR)
			if not road or road.Instance:GetAttribute("RoadBox") ~= "R" then
				continue
			end
			local top = b.Position.Y + s.Y / 2
			local front = b.Position + n * (halfAcross + 3)
			local c = front + n * (o.d / 2)
			local d = (Vector3.new(c.X, 0, c.Z) - centre).Magnitude
			if d <= R then
				table.insert(cands, { c = Vector3.new(c.X, top, c.Z), f = -n, dist = d, roadTop = road.Position.Y })
			end
		end
	end
	table.sort(cands, function(a, b)
		return a.dist < b.dist
	end)
	local out = {}
	local tried = 0
	for _, k in cands do
		if #out >= (o.want or 6) then
			break
		end
		tried += 1
		if tried % 40 == 0 then
			task.wait()
		end
		if math.abs(k.c.Y - k.roadTop) > 3 then
			continue
		end
		local cf = CFrame.lookAt(k.c, k.c + k.f)
		local mid = cf * CFrame.new(0, 0, 3)
		local size = Vector3.new(o.w + 16 + 12, 300, o.d + 10 + 12)
		local hit = false
		for _, p in workspace:GetPartBoundsInBox(mid, size, blk) do
			if not (o.self and p.Name == o.self and p.Parent == Y.Sites) then -- its own old pad
				hit = true
				break
			end
		end
		if hit then
			continue
		end
		local clash = false
		for _, a in o.avoid or {} do
			local rel = a[1]:PointToObjectSpace(mid.Position)
			if math.abs(rel.X) < (a[2].X + size.X) / 2 and math.abs(rel.Z) < (a[2].Z + size.Z) / 2 then
				clash = true
				break
			end
		end
		if clash then
			continue
		end
		-- ground: no water, within 16 of the floor
		local ok = true
		for u = -2, 2 do
			for v = -2, 2 do
				local p = mid * Vector3.new(u * (o.w + 16) / 5, 0, v * (o.d + 10) / 5)
				local r = workspace:Raycast(p + Vector3.new(0, 250, 0), Vector3.new(0, -500, 0), rayT)
				if not r or r.Material == Enum.Material.Water or math.abs(r.Position.Y - k.c.Y) > 16 then
					ok = false
					break
				end
			end
			if not ok then
				break
			end
		end
		if not ok then
			continue
		end
		local shells = #workspace:GetPartBoundsInBox(mid, Vector3.new(o.w + 16, 300, o.d + 10), shellP)
		table.insert(out, { x = k.c.X, y = k.c.Y, z = k.c.Z, fx = k.f.X, fz = k.f.Z, dist = k.dist, shells = shells, cf = mid, size = size })
	end
	return out
end

_G.LotFinder = F
return F
