--[[
	Viaducts (Studio, Edit mode; 2026-11-04, the north roads): where a road stands high over a valley
	(the road's `viaducts` runs from tools/map_plan/north_roads.py: sample numbers from 0) it goes on a
	concrete bridge: a deck slab and a box girder under the road, and tall hammerhead piers on the
	natural ground. Built under the road the road tools made, so the driving surface, its lines and
	its rails stay the road's own.

	Viaducts.build(road, parent) -> parts made   (road = the entry from the roads json)
]]

local Viaducts = {}

local CONCRETE = Color3.fromRGB(172, 168, 160)
local DARK = Color3.fromRGB(140, 136, 128)
local SPAN = 120 -- studs between piers

local function part(props, parent)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.Concrete
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end

function Viaducts.build(road, parent: Instance): number
	local runs = road.viaducts or {}
	if #runs == 0 then
		return 0
	end
	local s = road.s
	local half = s[1][7]
	local wide = half >= 30
	local deckW = if wide then 2 * half + 20 else 2 * half + 3
	local girderW = if wide then 44 else 18
	local girderH = if wide then 9 else 6
	local old = parent:FindFirstChild("Viaduct")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Viaduct"
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace.Terrain }
	local count = 0
	for _, run in runs do
		local a, b = run[1] + 1, run[2] + 1
		-- (samples a piece: the deck follows the bends in ~20-stud pieces)
		local sep = (Vector3.new(s[a][1], 0, s[a][3]) - Vector3.new(s[a + 1][1], 0, s[a + 1][3])).Magnitude
		local stride = math.max(1, math.round(20 / sep))
		local acc = 0
		local i = a
		while i < b do
			local j = math.min(i + stride, b)
			local pa = Vector3.new(s[i][1], s[i][2], s[i][3])
			local pb = Vector3.new(s[j][1], s[j][2], s[j][3])
			local len = (pb - pa).Magnitude
			-- (extra length closes the gap on the outside of a bend)
			local d0 = Vector3.new(s[i][4], 0, s[i][5])
			local d1 = Vector3.new(s[j][4], 0, s[j][5])
			local turn = math.acos(math.clamp(d0.Unit:Dot(d1.Unit), -1, 1))
			local grow = math.min(math.tan(turn / 2) * deckW, 12)
			local cf = CFrame.lookAt((pa + pb) / 2, pb)
			part({ Name = "Deck", Size = Vector3.new(deckW, 2.6, len + grow + 0.4), CFrame = cf * CFrame.new(0, -3.4, 0), Color = CONCRETE, CastShadow = true }, folder)
			part({ Name = "Girder", Size = Vector3.new(girderW, girderH, len + grow + 0.4), CFrame = cf * CFrame.new(0, -4.7 - girderH / 2, 0), Color = DARK, CastShadow = true }, folder)
			count += 2
			-- a pier every SPAN studs
			acc += len
			if acc >= SPAN and j < b then
				acc = 0
				local dir = Vector3.new(s[j][4], 0, s[j][5]).Unit
				local top = pb + Vector3.new(0, -4.7 - girderH, 0)
				local hit = workspace:Raycast(top, Vector3.new(0, -500, 0), params)
				if hit and top.Y - hit.Position.Y > 6 then
					local foot = hit.Position.Y - 8
					local h = top.Y - foot
					local look = CFrame.lookAt(Vector3.new(top.X, 0, top.Z), Vector3.new(top.X, 0, top.Z) + dir)
					local w = if wide then 18 else 11
					local depth = if wide then 10 else 7
					part({ Name = "Pier", Size = Vector3.new(w, h, depth), CFrame = look * CFrame.new(0, foot + h / 2, 0), Color = CONCRETE, CastShadow = true }, folder)
					local capW = if wide then deckW - 18 else deckW - 6
					part({ Name = "PierCap", Size = Vector3.new(capW, 6, depth + 3), CFrame = look * CFrame.new(0, top.Y - 3, 0), Color = CONCRETE, CastShadow = true }, folder)
					count += 2
				end
			end
			i = j
			if count % 60 == 0 then
				task.wait()
			end
		end
	end
	folder.Parent = parent
	return count
end

return Viaducts
