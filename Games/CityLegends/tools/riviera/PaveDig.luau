--[[
	PaveDig (Studio, Edit mode; owner, 2026-11-06, "FIND IT ALL"): the hillside coming up through a pavement in
	patches of grass and stone. Road writes smooth the terrain over the pavement's edge, and terrain
	voxels are 4 studs, so a slope can stand a little over a flat piece of paving.

	Each pavement piece is sampled at POINTS across; where the ground stands over the paving, the ground
	above the paving comes away, the piece's size plus MARGIN. The pieces stay where they are.

	PaveDig.check(roads) -> pieces with ground over them, worst height
	PaveDig.run(roads) -> pieces dug
]]

local PaveDig = {}

local MARGIN = 1
local OVER = 0.02
local HIGH = 14
local POINTS = { { 0, 0 }, { -0.45, -0.45 }, { 0.45, -0.45 }, { -0.45, 0.45 }, { 0.45, 0.45 }, { 0, -0.45 }, { 0, 0.45 }, { -0.45, 0 }, { 0.45, 0 } }

local function over(p: BasePart, params: RaycastParams): number
	local cf, s = p.CFrame, p.Size
	local worst = 0
	for _, q in POINTS do
		local at = cf * Vector3.new(q[1] * s.X, s.Y / 2, q[2] * s.Z)
		local r = workspace:Raycast(at + Vector3.new(0, HIGH, 0), Vector3.new(0, -HIGH - 0.3, 0), params)
		if r then
			worst = math.max(worst, r.Position.Y - at.Y)
		end
	end
	return worst
end

local function each(roads: Instance, fn: (BasePart) -> ())
	local n = 0
	for _, road in roads:GetChildren() do
		for _, p in road:GetChildren() do
			if p.Name == "Pavement" and p:IsA("Part") and p.Transparency < 1 then
				n += 1
				fn(p)
				if n % 500 == 0 then
					task.wait()
				end
			end
		end
	end
end

local function terrainOnly(): RaycastParams
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace.Terrain }
	return params
end

function PaveDig.check(roads: Instance): (number, number)
	local params = terrainOnly()
	local count, worst = 0, 0
	each(roads, function(p)
		local h = over(p, params)
		if h > OVER then
			count += 1
			worst = math.max(worst, h)
		end
	end)
	return count, worst
end

function PaveDig.run(roads: Instance): number
	local params = terrainOnly()
	local dug = 0
	each(roads, function(p)
		local h = over(p, params)
		if h > OVER then
			local tall = h + 8
			local cf = p.CFrame * CFrame.new(0, p.Size.Y / 2 + tall / 2 - 0.1, 0)
			workspace.Terrain:FillBlock(cf, Vector3.new(p.Size.X + MARGIN, tall, p.Size.Z + MARGIN), Enum.Material.Air)
			dug += 1
		end
	end)
	return dug
end

return PaveDig
