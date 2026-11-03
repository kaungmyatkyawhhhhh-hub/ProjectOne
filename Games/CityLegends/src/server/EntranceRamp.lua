--[[
	EntranceRamp
	A proper driveway from the street onto a venue's lot (owner, 2026-11-03: "make every venue
	entrance perfect because right now at the entrance the car cant drive up the ramp in some venues
	... the ramp looks bad"). The venues stand on Riviera sites whose ground is often a step or two
	above the pavement (a stone ledge, a kerb), so a fixed little wedge on the road either floats or
	leaves a wall in front of the car.

	EntranceRamp.build looks at the real ground: from a point on the lot's edge (facing out to the
	street) it walks outwards, finds the lot's surface, the pavement, the kerb and the road, and lays
	a paved slab from the road up to the lot that clears everything in between (the upper hull of
	the ground's profile, so it is one straight slope wherever it can be). Granite edging runs along
	both sides. Small props standing in the way (bollards, posts, benches) are hidden; nothing big is
	touched. Runs on the server when the venue is built.
]]

local EntranceRamp = {}

export type Opts = {
	width: number?, -- across the drive (default 18)
	color: Color3?, -- the paving
	material: Enum.Material?,
	edge: Color3?, -- the granite edging
	reach: number?, -- how far out to look for the road (default 40)
	keep: { Instance }?, -- never hidden (the venue itself)
}

local GRANITE = Color3.fromRGB(176, 172, 164)
local STEP = 0.5

local function isRoad(r: RaycastResult): boolean
	local inst = r.Instance
	if inst:IsA("Terrain") then
		return r.Material == Enum.Material.Asphalt
	end
	local n = string.lower(inst.Name)
	return string.find(n, "road", 1, true) ~= nil or (inst :: BasePart).Material == Enum.Material.Asphalt
end

-- upper convex hull of points sorted by t (the profile the slab follows)
local function upperHull(pts: { Vector2 }): { Vector2 }
	local hull: { Vector2 } = {}
	for _, p in pts do
		while #hull >= 2 do
			local a, b = hull[#hull - 1], hull[#hull]
			-- drop b if it lies on or below the line a -> p
			if (b.X - a.X) * (p.Y - a.Y) - (b.Y - a.Y) * (p.X - a.X) >= 0 then
				table.remove(hull)
			else
				break
			end
		end
		table.insert(hull, p)
	end
	return hull
end

local function newPart(parent: Instance, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material, solid: boolean): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanCollide = solid
	p.CanTouch = false
	p.CastShadow = false
	p.Parent = parent
	return p
end

-- inner: on the lot's edge in the middle of the drive, its LookVector pointing out to the street
function EntranceRamp.build(parent: Instance, inner: CFrame, opts: Opts?): Model?
	local o = opts or {}
	local W = o.width or 18
	local reach = o.reach or 40
	local out = Vector3.new(inner.LookVector.X, 0, inner.LookVector.Z)
	if out.Magnitude < 0.1 then
		return nil
	end
	out = out.Unit
	local right = out:Cross(Vector3.yAxis).Unit
	local p0 = inner.Position

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.RespectCanCollide = true
	local skip: { Instance } = {}
	for _, pl in game:GetService("Players"):GetPlayers() do
		if pl.Character then
			table.insert(skip, pl.Character)
		end
	end
	params.FilterDescendantsInstances = skip

	-- the ground along the drive (the highest of three lines across it); rays come down from well
	-- above, so a pavement higher than the lot is found too (props are cleared in a first pass)
	local roadLook: RaycastResult? = nil
	local function ground(t: number): (number?, boolean)
		local best: number? = nil
		local road = false
		for _, k in { -0.42, 0, 0.42 } do
			local at = p0 + out * t + right * (k * W)
			local r = workspace:Raycast(Vector3.new(at.X, p0.Y + 14, at.Z), Vector3.new(0, -60, 0), params)
			if r then
				if best == nil or r.Position.Y > best then
					best = r.Position.Y
				end
				if k == 0 then
					road = isRoad(r)
					if road and not roadLook then
						roadLook = r
					end
				end
			end
		end
		return best, road
	end

	local IN = 18 -- how far into the lot the slope may start, for a lot well below or above the street
	local MAX_SLOPE = 0.2 -- about 11 degrees

	-- the profile along the drive and the slab's line over it (the upper hull): the shortest slab
	-- that is no steeper than MAX_SLOPE, starting on the lot (up to IN inside it) and ending on the road
	local function plan(): (number?, { Vector2 }, { Vector2 }, number, number, number)
		local top = ground(0)
		if not top then
			return nil, {}, {}, 0, 0, 0
		end
		local samples: { Vector2 } = {}
		local roadT: number? = nil
		local t = -IN
		while t <= reach do
			local h, road = ground(t)
			if h then
				if t <= 0 then
					h = math.min(h, top + 0.3) -- (the lot: its own kerbs and planters don't count)
				end
				table.insert(samples, Vector2.new(t, h))
				if t > 0 and road and not roadT then
					roadT = t
				end
			end
			if roadT and t >= roadT + 14 then
				break
			end
			t += STEP
		end
		if not roadT or #samples == 0 then
			return nil, {}, {}, 0, 0, 0
		end
		local function hAt(tt: number): number
			local best = samples[1].Y
			for _, s in samples do
				if s.X <= tt + 0.01 then
					best = s.Y
				end
			end
			return best
		end
		local cap = math.max(top, hAt(roadT)) + 3
		local function hullFor(t0: number, t1: number): ({ Vector2 }, number)
			local pts: { Vector2 } = { Vector2.new(t0, hAt(t0)) }
			for _, sm in samples do
				if sm.X > t0 and sm.X < t1 then
					table.insert(pts, Vector2.new(sm.X, math.min(sm.Y, cap)))
				end
			end
			table.insert(pts, Vector2.new(t1, hAt(t1)))
			local hull = upperHull(pts)
			local steep = 0
			for i = 1, #hull - 1 do
				local run = hull[i + 1].X - hull[i].X
				if run > 0.05 then
					steep = math.max(steep, math.abs(hull[i + 1].Y - hull[i].Y) / run)
				end
			end
			return hull, steep
		end
		local bestHull, bestT0, bestT1, bestSteep = nil, 0, roadT + 2.5, math.huge
		for t0 = 0, -IN, -2 do
			for t1 = roadT + 2.5, roadT + 12, 1.5 do
				local hull, steep = hullFor(t0, t1)
				-- the gentlest; among the gentle enough ones, the shortest
				local ok = steep <= MAX_SLOPE
				local bestOk = bestSteep <= MAX_SLOPE
				local better = if ok and bestOk then (t1 - t0) < (bestT1 - bestT0) - 0.01 elseif ok ~= bestOk then ok else steep < bestSteep - 0.002
				if bestHull == nil or better then
					bestHull, bestT0, bestT1, bestSteep = hull, t0, t1, steep
				end
			end
		end
		return top, samples, bestHull :: { Vector2 }, bestT0, bestT1, roadT
	end
	local function surfaceAt(hull: { Vector2 }, tt: number): number
		for i = 1, #hull - 1 do
			local a, b = hull[i], hull[i + 1]
			if tt >= a.X and tt <= b.X then
				return a.Y + (b.Y - a.Y) * (tt - a.X) / math.max(b.X - a.X, 0.01)
			end
		end
		return hull[#hull].Y
	end

	local top, samples, hull, tStart, tEnd, roadT = plan()
	if not top then
		warn("[CityLegends] EntranceRamp: no road found from", parent:GetFullName())
		return nil
	end

	-- small props standing on the drive (posts, bollards, benches, bins): hidden, then the ground
	-- is measured again without them (the venue's own pieces are kept)
	local function clearProps(): number
		local mid = (math.max(tStart, 0) + tEnd) / 2
		local box = CFrame.lookAt(p0 + out * mid + Vector3.new(0, 1, 0), p0 + out * tEnd + Vector3.new(0, 1, 0))
		local op = OverlapParams.new()
		op.FilterType = Enum.RaycastFilterType.Exclude
		local ex: { Instance } = { workspace.Terrain }
		for _, k in o.keep or {} do
			table.insert(ex, k)
		end
		op.FilterDescendantsInstances = ex
		local hid = 0
		for _, part in workspace:GetPartBoundsInBox(box, Vector3.new(W - 1, 16, tEnd - math.max(tStart, 0)), op) do
			local sz = part.Size
			if part.CanCollide and math.max(sz.X, sz.Y, sz.Z) < 24 and sz.X * sz.Z < 60 then
				local surfaceY = surfaceAt(hull, (part.Position - p0):Dot(out))
				local partTop = part.Position.Y + sz.Y / 2
				local bottom = part.Position.Y - sz.Y / 2
				if partTop > surfaceY + 0.4 and bottom < surfaceY + 4 and partTop - bottom > 0.8 then
					part.CanCollide = false
					part.CanQuery = false
					part.Transparency = 1
					for _, d in part:GetDescendants() do
						if d:IsA("Decal") or d:IsA("Texture") then
							d.Transparency = 1
						elseif d:IsA("Light") then
							d.Enabled = false
						end
					end
					hid += 1
				end
			end
		end
		return hid
	end
	if clearProps() > 0 then
		local t2, s2, h2, a2, e2, r2 = plan()
		if t2 then
			top, samples, hull, tStart, tEnd, roadT = t2, s2, h2, a2, e2, r2
		end
	end
	-- split the line where the road begins: the part out on the road is laid in the road's own
	-- asphalt (a dropped-kerb apron), the rest in paving with granite edges
	local kerbT = roadT - STEP / 2
	if kerbT > hull[1].X and kerbT < hull[#hull].X then
		local split: { Vector2 } = {}
		for i, pt in hull do
			table.insert(split, pt)
			local nx = hull[i + 1]
			if nx and pt.X < kerbT and nx.X > kerbT then
				table.insert(split, Vector2.new(kerbT, surfaceAt(hull, kerbT)))
			end
		end
		hull = split
	end

	local model = Instance.new("Model")
	model.Name = "EntranceRamp"
	model.Parent = parent
	local color = o.color or Color3.fromRGB(128, 124, 118)
	local mat = o.material or Enum.Material.Pavement
	local roadColor, roadMat = Color3.fromRGB(52, 52, 56), Enum.Material.Asphalt
	if roadLook and roadLook.Instance:IsA("BasePart") then
		roadColor, roadMat = (roadLook.Instance :: BasePart).Color, (roadLook.Instance :: BasePart).Material
	end
	local edge = o.edge or GRANITE
	local surface: { CFrame } = {}
	for i = 1, #hull - 1 do
		local a, b = hull[i], hull[i + 1]
		local run = b.X - a.X
		if run > 0.05 then
			local dy = b.Y - a.Y
			local len = math.sqrt(run * run + dy * dy)
			-- thick enough to reach down to the lowest ground under it (no gap under the edge)
			local low = math.min(a.Y, b.Y)
			for _, s in samples do
				if s.X >= a.X and s.X <= b.X then
					low = math.min(low, s.Y)
				end
			end
			local mid = (a.Y + b.Y) / 2
			local thick = math.clamp(mid - low + 0.8, 1, 9)
			local pa = p0 + out * a.X
			local pb = p0 + out * b.X
			local topA = Vector3.new(pa.X, a.Y, pa.Z)
			local topB = Vector3.new(pb.X, b.Y, pb.Z)
			local cf = CFrame.lookAt((topA + topB) / 2, topB, Vector3.yAxis)
			table.insert(surface, cf)
			local onRoad = (a.X + b.X) / 2 > kerbT
			newPart(model, Vector3.new(W, thick, len + 0.08), cf * CFrame.new(0, -thick / 2, 0), if onRoad then roadColor else color, if onRoad then roadMat else mat, true).Name = "RampSlab"
			-- granite edging along both sides (no collision: the wheels roll over it)
			for _, sx in (if onRoad then {} else { -1, 1 }) :: { number } do
				newPart(model, Vector3.new(0.9, 0.3, len + 0.08), cf * CFrame.new(sx * (W / 2 - 0.45), 0.1, 0), edge, Enum.Material.Granite, false).Name = "RampEdge"
				-- and down the side, so the slab reads as stone, not a floating plate
				newPart(model, Vector3.new(0.3, thick, len + 0.08), cf * CFrame.new(sx * (W / 2 + 0.12), -thick / 2 + 0.05, 0), edge, Enum.Material.Granite, false).Name = "RampSide"
			end
		end
	end

	return model
end

return EntranceRamp
