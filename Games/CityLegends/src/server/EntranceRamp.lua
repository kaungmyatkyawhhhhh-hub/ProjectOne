--[[
	EntranceRamp
	A proper driveway from the street onto a venue's lot (owner, 2026-11-03: "make every venue
	entrance perfect because right now at the entrance the car cant drive up the ramp in some venues
	... the ramp looks bad"). The venues stand on Riviera sites whose ground is often a step or two
	above the pavement (a stone ledge, a kerb), so a fixed little wedge on the road either floats or
	leaves a wall in front of the car.

	EntranceRamp.build looks at the real ground: from a point on the lot's edge (facing out to the
	street) it walks outwards, finds the lot's surface and the road, and lays a paved slab from the
	road's edge up to the lot. Kerb stone edging runs along both sides. Small props standing in the
	way (bollards, posts, benches) are hidden; nothing big is touched. Runs on the server when the
	venue is built.

	(owner, 2026-11-04: "Dont make the ramp onto the road or else it look bad and affect driving")
	Nothing is laid on the road any more: the slab ends level with the road at its edge, a dropped
	kerb (the kerb and pavement pieces across the drive are hidden).

	(owner, 2026-11-06, a picture of the Legends Rewards drive) The drive is now one straight plane
	from the lot's edge to the road's edge. It used to be up to six slabs over the hull of the ground:
	the pavement it was about to remove bent it, so it showed lines across, curved dark edges and a
	steep last stud (up to 37 degrees), and strips of the old pavement came through at its sides.
]]

local EntranceRamp = {}

export type Opts = {
	width: number?, -- across the drive (default 18)
	color: Color3?, -- the paving
	material: Enum.Material?,
	edge: Color3?, -- the edging
	reach: number?, -- how far out to look for the road (default 40)
	keep: { Instance }?, -- never hidden (the venue itself)
	lift: number?, -- the drive's paving stands this much over the lot's floor where they meet
	notch: boolean?, -- the slab may start inside the lot, under its floor (the caller cuts the floor)
	ignore: { Instance }?, -- never measured (a house already standing on the lot: its gate read as the ground)
}

local KERB = Color3.fromRGB(205, 202, 194) -- the road's kerb stone
local EDGE_W = 0.9
local EDGE_UP = 0.08 -- the edge's top over the slab
local STEP = 0.5

local function isRoad(r: RaycastResult): boolean
	local inst = r.Instance
	if inst:IsA("Terrain") then
		return r.Material == Enum.Material.Asphalt
	end
	local n = string.lower(inst.Name)
	return string.find(n, "road", 1, true) ~= nil or (inst :: BasePart).Material == Enum.Material.Asphalt
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
	for _, i in o.ignore or {} do
		table.insert(skip, i)
	end
	params.FilterDescendantsInstances = skip

	local riv = workspace:FindFirstChild("Riviera")
	local roads = riv and riv:FindFirstChild("Roads")

	local function cast(at: Vector3): RaycastResult?
		return workspace:Raycast(Vector3.new(at.X, p0.Y + 14, at.Z), Vector3.new(0, -60, 0), params)
	end
	-- the ground on a line along the drive, the road's own kerb and pavement left out: they go.
	-- Measuring them bent the slab over the pavement and dropped its last stud steeply to the road.
	local function floorAt(at: Vector3): number?
		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Exclude
		rp.RespectCanCollide = true
		rp.FilterDescendantsInstances = skip
		for _ = 1, 8 do
			local r = workspace:Raycast(Vector3.new(at.X, p0.Y + 14, at.Z), Vector3.new(0, -60, 0), rp)
			if not r then
				return nil
			end
			if roads and r.Instance:IsDescendantOf(roads) and (r.Instance.Name == "Kerb" or r.Instance.Name == "Pavement") then
				rp:AddToFilter(r.Instance)
			else
				return r.Position.Y
			end
		end
		return nil
	end

	local MAX_SLOPE = 0.2 -- about 11 degrees
	local IN = 18 -- how far into the lot the slope may start

	local lot = cast(p0 - out)
	if not lot then
		warn("[CityLegends] EntranceRamp: no lot found from", parent:GetFullName())
		return nil
	end
	local lotY = lot.Position.Y
	local top = lotY + (o.lift or 0)

	-- (a venue's own asphalt forecourt is not the road)
	local function own(inst: Instance): boolean
		for _, k in o.keep or {} do
			if inst:IsDescendantOf(k) then
				return true
			end
		end
		return false
	end

	-- the road's edge: the first point out from the lot where the middle line lands on road
	local roadT: number? = nil
	do
		local t = 0
		while t <= reach do
			local r = cast(p0 + out * t)
			if r and isRoad(r) and not own(r.Instance) then
				roadT = t
				break
			end
			t += STEP
		end
	end
	if not roadT then
		warn("[CityLegends] EntranceRamp: no road found from", parent:GetFullName())
		return nil
	end
	local rT: number = roadT

	-- the lot's edge: where the floor stops being the lot
	local edgeT = 0
	do
		local t = 0
		while t < rT do
			local h = floorAt(p0 + out * t)
			if not h or math.abs(h - lotY) > 0.3 then
				break
			end
			edgeT = t
			t += STEP
		end
	end

	-- the road at the slab's end: the middle and both sides (the road leans across)
	local function roadAt(u: number): number?
		local r = cast(p0 + out * (rT + 1) + right * u)
		return if r then r.Position.Y else nil
	end
	local roadY = roadAt(0) or top
	local leftY, rightY = roadAt(-(W / 2 - 1)) or roadY, roadAt(W / 2 - 1) or roadY
	local roll = math.clamp((rightY - leftY) / math.max(W - 2, 1), -0.03, 0.03)

	-- one straight plane from the lot to the road: no bends, so no joints across the drive and side
	-- edges that run straight
	local rise = roadY - top
	local tS = math.min(edgeT, rT - 2)
	if math.abs(rise) / math.max(rT - tS, 0.1) > MAX_SLOPE then
		-- too steep from the lot's edge: start further in. Where the road is higher the slab lies on the
		-- lot; where the lot is higher it needs a notch in the lot's floor (opts.notch)
		local want = rT - math.abs(rise) / MAX_SLOPE
		if rise > 0 or o.notch then
			tS = math.max(want, -IN)
		end
	end
	local function planeAt(t: number): number
		return top + rise * (t - tS) / math.max(rT - tS, 0.1)
	end

	-- small props standing on the drive (posts, bollards, benches, bins): hidden (the venue's own
	-- pieces are kept)
	local function clearProps(): number
		local mid = (math.max(tS, 0) + rT) / 2
		local box = CFrame.lookAt(p0 + out * mid + Vector3.new(0, 1, 0), p0 + out * rT + Vector3.new(0, 1, 0))
		local op = OverlapParams.new()
		op.FilterType = Enum.RaycastFilterType.Exclude
		local ex: { Instance } = { workspace.Terrain }
		-- (owner, 2026-11-03: "there is a hole at the ramp of legends hotel") never the road itself:
		-- the road's small triangle pieces were taken for props and hidden
		if roads then
			table.insert(ex, roads)
		end
		for _, k in o.keep or {} do
			table.insert(ex, k)
		end
		op.FilterDescendantsInstances = ex
		local hid = 0
		for _, part in workspace:GetPartBoundsInBox(box, Vector3.new(W - 1, 16, rT - math.max(tS, 0)), op) do
			local sz = part.Size
			-- (railings: their long pieces too, and all of them: the drive goes through; left standing, the
			-- slab rose over them in a hump)
			local nm = string.lower(part.Name)
			local railing = string.find(nm, "rail", 1, true) ~= nil or string.find(nm, "plinth", 1, true) ~= nil or string.find(nm, "baluster", 1, true) ~= nil or string.find(nm, "post", 1, true) ~= nil or string.find(nm, "bollard", 1, true) ~= nil
			if part.CanCollide and (railing or (math.max(sz.X, sz.Y, sz.Z) < 24 and sz.X * sz.Z < 60)) then
				local surfaceY = planeAt((part.Position - p0):Dot(out))
				local partTop = part.Position.Y + sz.Y / 2
				local bottom = part.Position.Y - sz.Y / 2
				if railing or (partTop > surfaceY + 0.4 and bottom < surfaceY + 4 and partTop - bottom > 0.8) then
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

	-- the road's kerb and pavement across the drive: hidden, so the slab comes down level with the road.
	-- A piece that stands half in the drive is cut back to the drive's edge: left whole it came up
	-- through the slab in a strip; hidden it left a gap beside the drive
	local function hide(part: BasePart)
		part.CanCollide = false
		part.CanQuery = false
		part.Transparency = 1
	end
	local function dropKerb(): number
		if not roads then
			return 0
		end
		local t0, t1 = math.max(rT - 18, math.min(tS, 0)), rT + 1.2
		local c = p0 + out * ((t0 + t1) / 2)
		local op = OverlapParams.new()
		op.FilterType = Enum.RaycastFilterType.Include
		op.FilterDescendantsInstances = { roads }
		local done = 0
		for _, part in workspace:GetPartBoundsInBox(CFrame.lookAt(c, c + out), Vector3.new(W + 1, 24, t1 - t0), op) do
			if (part.Name == "Kerb" or part.Name == "Pavement") and part:IsA("BasePart") then
				local rel = part.Position - p0
				-- (the far kerb of a narrow road stays)
				if rel:Dot(out) < rT + 1.2 then
					local cf, sz = part.CFrame, part.Size
					-- the piece's length runs along the road: its local Z, or X for one laid crosswise
					local alongZ = math.abs(cf.LookVector:Dot(right)) >= math.abs(cf.RightVector:Dot(right))
					local axis = if alongZ then cf.LookVector else cf.RightVector
					local len = if alongZ then sz.Z else sz.X
					local wide = if alongZ then sz.X else sz.Z
					local slant = axis:Dot(right)
					local u0 = rel:Dot(right)
					local spread = len / 2 * math.abs(slant) + wide / 2 * math.sqrt(math.max(1 - slant * slant, 0))
					if math.abs(u0) - spread >= W / 2 then
						-- beside the drive: stays
						continue
					elseif math.abs(u0) + spread <= W / 2 + 0.2 or math.abs(slant) < 0.35 then
						-- all in the drive (or a piece lying along it: nothing to cut it by)
						hide(part)
						done += 1
					else
						-- keep the end of the piece outside the drive
						local side = if u0 >= 0 then 1 else -1
						local meet = (side * W / 2 - u0) / slant -- where its middle line meets the drive's edge
						local dir = if side * slant > 0 then 1 else -1 -- which end is outside
						local keep = len / 2 - meet * dir
						if keep < 0.4 then
							hide(part)
						elseif keep < len then
							part.Size = if alongZ then Vector3.new(sz.X, sz.Y, keep) else Vector3.new(keep, sz.Y, sz.Z)
							part.CFrame = cf + axis * (dir * (len - keep) / 2)
						end
						done += 1
					end
				end
			end
		end
		return done
	end

	-- ground standing above the slab: dug away, or it would come up through the drive
	local function digGround(): boolean
		local over = 0
		local t = math.max(tS, 0) + 0.5
		while t < rT - 0.5 do
			for _, k in { -0.42, 0, 0.42 } do
				local r = cast(p0 + out * t + right * (k * W))
				if r and r.Instance:IsA("Terrain") then
					over = math.max(over, r.Position.Y - planeAt(t))
				end
			end
			t += 1
		end
		if over < 0.25 then
			return false
		end
		local from = math.max(tS, 0)
		local a = Vector3.new(p0.X, 0, p0.Z) + out * from + Vector3.new(0, planeAt(from), 0)
		local e = p0 + out * rT
		local b = Vector3.new(e.X, planeAt(rT), e.Z)
		-- (piece by piece along the drive, each level across: 4-stud voxels go by their centres)
		local len = (b - a).Magnitude
		for d = 0, len, 6 do
			local q = a:Lerp(b, d / math.max(len, 0.1))
			workspace.Terrain:FillBlock(CFrame.lookAt(q, q + out) * CFrame.new(0, 6, 0), Vector3.new(W + 8, 18, 8), Enum.Material.Air)
		end
		return true
	end

	-- (opts.notch) the slab starts inside the lot: a rectangle comes out of the lot's floor and of the wall
	-- along its edge, each one split into the pieces round the rectangle
	local function cutFloor()
		local from, to = tS, edgeT + 3
		local c = p0 + out * ((from + to) / 2)
		local op = OverlapParams.new()
		op.FilterType = Enum.RaycastFilterType.Exclude
		op.FilterDescendantsInstances = { workspace.Terrain, roads :: Instance }
		local corner1 = p0 + out * from - right * (W / 2)
		local corner2 = p0 + out * to + right * (W / 2)
		for _, part in workspace:GetPartBoundsInBox(CFrame.lookAt(c, c + out), Vector3.new(W - 0.2, 12, to - from), op) do
			local sz = part.Size
			local byX = math.abs(part.CFrame.RightVector:Dot(right))
			local byZ = math.abs(part.CFrame.LookVector:Dot(right))
			local long = (byX > 0.99 and sz.X > W + 1) or (byZ > 0.99 and sz.Z > W + 1)
			if part:IsA("Part") and long and part.Position.Y + sz.Y / 2 < lotY + 0.3 then
				local a = part.CFrame:PointToObjectSpace(corner1)
				local b = part.CFrame:PointToObjectSpace(corner2)
				local hx, hz = sz.X / 2, sz.Z / 2
				local x0, x1 = math.clamp(math.min(a.X, b.X), -hx, hx), math.clamp(math.max(a.X, b.X), -hx, hx)
				local z0, z1 = math.clamp(math.min(a.Z, b.Z), -hz, hz), math.clamp(math.max(a.Z, b.Z), -hz, hz)
				local cf = part.CFrame
				local rects = {
					{ -hx, x0, -hz, hz },
					{ x1, hx, -hz, hz },
					{ x0, x1, -hz, z0 },
					{ x0, x1, z1, hz },
				}
				local function put(p: BasePart, r: { number })
					p.Size = Vector3.new(r[2] - r[1], sz.Y, r[4] - r[3])
					p.CFrame = cf * CFrame.new((r[1] + r[2]) / 2, 0, (r[3] + r[4]) / 2)
				end
				table.sort(rects, function(m, n)
					return (m[2] - m[1]) * (m[4] - m[3]) > (n[2] - n[1]) * (n[4] - n[3])
				end)
				for i = #rects, 2, -1 do
					local r = rects[i]
					if r[2] - r[1] > 0.05 and r[4] - r[3] > 0.05 then
						local q = part:Clone()
						q:ClearAllChildren()
						put(q, r)
						q.Parent = part.Parent
					end
				end
				put(part, rects[1]) -- (the biggest stays the part itself, with its walls)
			end
		end
	end
	local notched = tS < edgeT - 0.5 and rise < 0 and o.notch == true
	if notched then
		cutFloor()
	end

	clearProps()
	dropKerb()
	if digGround() then
		-- (rays see the dug ground a moment later)
		task.wait(0.25)
	end

	local model = Instance.new("Model")
	model.Name = "EntranceRamp"
	model.Parent = parent
	local color = o.color or Color3.fromRGB(128, 124, 118)
	local mat = o.material or Enum.Material.Pavement
	local edge = o.edge or KERB
	local edgeMat = Enum.Material.Concrete

	-- the slab: the plane from the lot's edge to the road's edge, leaning across with the road
	local pa = p0 + out * tS
	local pb = p0 + out * rT
	local topA = Vector3.new(pa.X, top, pa.Z)
	local topB = Vector3.new(pb.X, roadY, pb.Z)
	local look = (topB - topA).Unit
	local tilted = (right + Vector3.new(0, roll, 0)).Unit
	local up = tilted:Cross(look).Unit
	local across = look:Cross(up).Unit
	local cf = CFrame.fromMatrix((topA + topB) / 2, across, up, -look)
	local len = (topB - topA).Magnitude
	-- thick enough to reach down to the lowest ground under it (no gap under the edge)
	local low = math.min(top, roadY)
	do
		local t = tS
		while t <= rT do
			local h = floorAt(p0 + out * t)
			if h then
				low = math.min(low, h)
			end
			t += 1
		end
	end
	local thick = math.clamp((top + roadY) / 2 - low + 0.8, 1, 9)
	newPart(model, Vector3.new(W, thick, len), cf * CFrame.new(0, -thick / 2, 0), color, mat, true).Name = "RampSlab"
	model:SetAttribute("RampSlope", math.abs(rise) / math.max(rT - tS, 0.1))
	model:SetAttribute("RampRise", rise)
	model:SetAttribute("RampRun", rT - tS)
	model:SetAttribute("RampLotEdge", edgeT)
	model:SetAttribute("RampStart", tS)
	model:SetAttribute("RampRoad", rT)

	-- kerb stone along both edges, flush with the slab (no collision: the wheels roll over it), and
	-- down the side, so the slab reads as stone, not a floating plate
	for _, sx in { -1, 1 } do
		newPart(model, Vector3.new(EDGE_W, 0.3, len), cf * CFrame.new(sx * (W / 2 - EDGE_W / 2), EDGE_UP - 0.15, 0), edge, edgeMat, false).Name = "RampEdge"
		newPart(model, Vector3.new(0.3, thick, len), cf * CFrame.new(sx * (W / 2 + 0.12), EDGE_UP - thick / 2, 0), edge, edgeMat, false).Name = "RampSide"
		-- the cut sides of a notch in the lot's floor
		if notched then
			local H = lotY - planeAt(edgeT) + 1.5
			local mid = p0 + out * ((tS + edgeT) / 2) + right * (sx * (W / 2 + 0.2))
			local spot = Vector3.new(mid.X, lotY + 0.02 - H / 2, mid.Z)
			newPart(model, Vector3.new(0.3, H, edgeT - tS + 0.3), CFrame.lookAt(spot, spot + out), edge, edgeMat, false).Name = "RampCheek"
		end
		-- where the pavement beside the drive stands over the slab (a road above its lot): a kerb stone
		-- face over the pavement's cut end
		if roads then
			local rp = RaycastParams.new()
			rp.FilterType = Enum.RaycastFilterType.Include
			rp.FilterDescendantsInstances = { roads }
			local first, last = nil, nil
			local t = tS
			while t <= rT do
				local at = p0 + out * t + right * (sx * (W / 2 + 1.2))
				local r = workspace:Raycast(Vector3.new(at.X, p0.Y + 14, at.Z), Vector3.new(0, -60, 0), rp)
				if r and (r.Instance.Name == "Pavement" or r.Instance.Name == "Kerb") and r.Position.Y > planeAt(t) + 0.12 then
					local q = Vector3.new(at.X, r.Position.Y, at.Z) - right * (sx * 1.0)
					first = first or q
					last = q
				end
				t += 1
			end
			if first and last and (last - first).Magnitude > 1 then
				local H = math.max(first.Y, last.Y) - math.min(top, roadY) + 2
				local mid = (first + last) / 2
				newPart(model, Vector3.new(0.3, H, (last - first).Magnitude + 1), CFrame.lookAt(mid, last) * CFrame.new(0, 0.03 - H / 2, 0), edge, edgeMat, false).Name = "RampCheek"
			end
		end
	end

	return model
end

return EntranceRamp
