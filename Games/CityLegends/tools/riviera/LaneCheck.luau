--[[
	LaneCheck (Studio, Edit mode; 2026-11-03, `Prompts/Smooth roads.md`: "test all 4 lanes of every
	road"): walks every traffic lane (src/shared/RivieraLanes.lua: each road has way +1 / -1 and lane
	1 / 2) a stud at a time, at its middle and 3 studs to each side (a car's width), and logs:
	  * hole: no road under it (terrain, the sea, nothing)
	  * edge: a kerb, pavement, island or wall under the lane
	  * step: the surface height kinks by more than `limit` (second difference over 1-stud steps:
	    a smooth slope or crest is 0, a 0.05 step is 0.05)
	  * block: something solid standing in the lane (from 0.6 to 7 studs over the road)
	Problems within 6 studs of each other on a lane count as one spot.

	LaneCheck.run(lanes, opts) -> { spots }, counts
	  opts.limit (0.05), opts.roads (Workspace.Riviera), opts.only = { [road] = true }
	  spot = { kind, road, way, lane, at: Vector3, value }
]]

local LaneCheck = {}

local SURFACE = { Road = true, Line = true, Zebra = true, SpeedBump = true, Stripe = true, IslandPatch = true, JunctionFill = true, Fill = true }
local EDGE = { Kerb = true, Pavement = true, Island = true, Wall = true, LegWall = true, CurveWall = true, Shoulder = false, TurningCircle = false }

local function pointsOf(lane): { Vector3 }
	local f = lane.pts
	local out = {}
	if typeof(f[1]) == "Vector3" then
		return f
	end
	for i = 1, #f - 2, 3 do
		table.insert(out, Vector3.new(f[i], f[i + 1], f[i + 2]))
	end
	return out
end

function LaneCheck.run(lanes, opts)
	opts = opts or {}
	local limit = opts.limit or 0.05
	local riv = opts.roads or workspace:FindFirstChild("Riviera")
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { riv, workspace.Terrain }
	params.RespectCanCollide = true
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Include
	overlap.FilterDescendantsInstances = { riv }
	overlap.RespectCanCollide = true
	local spots = {}
	local counts = { hole = 0, edge = 0, step = 0, block = 0, points = 0 }
	local function add(kind: string, lane, at: Vector3, value: any)
		-- one spot per 6 studs of a lane
		for k = #spots, math.max(1, #spots - 6), -1 do
			local s = spots[k]
			if s.kind == kind and s.road == lane.road and s.way == lane.way and s.lane == lane.lane and (s.at - at).Magnitude < 6 then
				return
			end
		end
		table.insert(spots, { kind = kind, road = lane.road, way = lane.way, lane = lane.lane, at = at, value = value })
		counts[kind] += 1
	end
	for li, lane in lanes do
		if opts.only and not opts.only[lane.road] then
			continue
		end
		local pts = pointsOf(lane)
		local h1, h2: number? = nil, nil
		for i = 1, #pts - 1 do
			local a, b = pts[i], pts[i + 1]
			local d = b - a
			local flat = Vector3.new(d.X, 0, d.Z)
			local len = flat.Magnitude
			if len < 0.01 then
				continue
			end
			local right = Vector3.new(-flat.Z, 0, flat.X).Unit
			local steps = math.max(1, math.floor(len))
			for k = 0, steps - 1 do
				local p = a + d * (k / steps)
				counts.points += 1
				local surfY: number? = nil
				for _, side in { 0, -3, 3 } do
					local q = p + right * side
					local hit = workspace:Raycast(q + Vector3.new(0, 8, 0), Vector3.new(0, -20, 0), params)
					if not hit or hit.Instance == workspace.Terrain then
						add("hole", lane, q, if hit then "terrain" else "nothing")
					elseif EDGE[hit.Instance.Name] then
						add("edge", lane, q, hit.Instance.Name)
					elseif side == 0 then
						surfY = hit.Position.Y
					end
				end
				if surfY then
					if h1 and h2 then
						local kink = surfY - 2 * h1 + h2
						if math.abs(kink) > limit then
							add("step", lane, p, kink)
						end
					end
					h2, h1 = h1, surfY
					-- something solid standing in the lane
					local box = CFrame.lookAt(Vector3.new(p.X, surfY + 3.8, p.Z), Vector3.new(p.X, surfY + 3.8, p.Z) + flat)
					if k % 2 == 0 then
						for _, part in workspace:GetPartBoundsInBox(box, Vector3.new(5, 6.4, 1), overlap) do
							if not SURFACE[part.Name] and part.CanCollide and part.Transparency < 1 then
								add("block", lane, p, part:GetFullName())
								break
							end
						end
					end
				else
					h1, h2 = nil, nil
				end
			end
		end
		if li % 6 == 0 then
			task.wait()
		end
	end
	return spots, counts
end

return LaneCheck
