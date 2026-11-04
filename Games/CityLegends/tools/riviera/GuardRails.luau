--[[
	GuardRails (Studio, Edit mode; 2026-11-04, the Riviera Highway): steel crash barriers along a road's
	outer shoulder edges, like a mountain highway's: a post every 8 studs and a W-beam rail (with a
	darker edge strip) between posts, following the road's height. Left out near other roads
	(junction mouths) and in tunnels.

	GuardRails.build(data, names, parent?, spacing?) -> parts made   (data = the roads json, names = { [road] = true })
]]

local GuardRails = {}

local HALF, WALK = 32, 10
local OFFSET = HALF + WALK - 1.4 -- the rail's line, near the shoulder's outer edge
local SPACING = 8
local STEEL = Color3.fromRGB(176, 180, 184)
local POST = Color3.fromRGB(120, 124, 128)

local function part(props, parent)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.Metal
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end

function GuardRails.build(data, names, parent: Instance?, spacing: number?): number
	local SPACING = spacing or SPACING
	-- every other road's samples, for keeping clear of junctions
	local grid = {}
	for _, r in data.roads do
		for _, s in r.s do
			local key = math.floor(s[1] / 64) .. "," .. math.floor(s[3] / 64)
			grid[key] = grid[key] or {}
			table.insert(grid[key], { Vector2.new(s[1], s[3]), r.name })
		end
	end
	local function nearOther(p: Vector3, radius: number, self: string): boolean
		local cx, cz = math.floor(p.X / 64), math.floor(p.Z / 64)
		for dx = -2, 2 do
			for dz = -2, 2 do
				for _, q in grid[(cx + dx) .. "," .. (cz + dz)] or {} do
					if q[2] ~= self and (q[1] - Vector2.new(p.X, p.Z)).Magnitude < radius then
						return true
					end
				end
			end
		end
		return false
	end
	local count = 0
	for _, r in data.roads do
		if not names[r.name] then
			continue
		end
		local folder = Instance.new("Folder")
		folder.Name = "GuardRails"
		local roadFolder = parent or workspace.Riviera.Roads:FindFirstChild(r.name)
		-- points along the road every SPACING studs (the samples are ~4 apart)
		local s = r.s
		local pts = {}
		local acc = 0
		for i = 1, #s do
			local p = Vector3.new(s[i][1], s[i][2], s[i][3])
			if i > 1 then
				acc += (p - Vector3.new(s[i - 1][1], s[i - 1][2], s[i - 1][3])).Magnitude
			end
			if i == 1 or acc >= SPACING then
				acc = 0
				table.insert(pts, { pos = p, dir = Vector3.new(s[i][4], 0, s[i][5]).Unit, tunnel = s[i][6] == 1 })
			end
		end
		for _, side in { -1, 1 } do
			local prev = nil
			for k, q in pts do
				local right = Vector3.new(-q.dir.Z, 0, q.dir.X)
				local base = q.pos + right * side * OFFSET
				local skip = q.tunnel or nearOther(base, HALF + WALK + 30, r.name)
				if not skip then
					part({ Name = "RailPost", Size = Vector3.new(0.5, 3.4, 0.5), CFrame = CFrame.new(base + Vector3.new(0, 1.5, 0)), Color = POST, CastShadow = false }, folder)
					count += 1
					if prev then
						local a = prev + Vector3.new(0, 2.4, 0)
						local b = base + Vector3.new(0, 2.4, 0)
						local len = (b - a).Magnitude
						if len < SPACING * 2.5 then
							local cf = CFrame.lookAt((a + b) / 2, b)
							part({ Name = "Rail", Size = Vector3.new(0.25, 1.1, len + 0.15), CFrame = cf * CFrame.new(-side * 0.3, 0, 0), Color = STEEL, Reflectance = 0.05, CastShadow = false }, folder)
							count += 1
						end
					end
					prev = base
				else
					prev = nil
				end
				if k % 200 == 0 then
					task.wait()
				end
			end
		end
		folder.Parent = roadFolder
	end
	return count
end

return GuardRails
