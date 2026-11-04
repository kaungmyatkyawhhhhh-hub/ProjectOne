--[[
	Mouth (Studio, Edit mode; 2026-11-04, the north roads): opens the way for a new road. Walks the
	road a few samples at a time and takes out of the way whatever stands on it: the kerbs, pavements,
	shoulders, rails, walls and edge lines of the roads it joins (the same pieces the road builder
	leaves out at a junction mouth), and street furniture, retaining walls and lamps along its length.
	Everything goes to ServerStorage.HighwayHidden with a `WasIn` ObjectValue and a `HiddenFor`
	attribute (the road's name), so it can be put back.

	Mouth.clear(data, name, opts) -> report table
	  opts.buildings = { Vector3 ... }: only these buildings may go (the nearest within 12 studs)
	Mouth.restore(name) -> pieces put back
]]

local Mouth = {}

local ServerStorage = game:GetService("ServerStorage")

-- road pieces that give way
local ROAD_PIECES = {
	Kerb = true, Pavement = true, Shoulder = true, Rail = true, RailPost = true, Parapet = true,
	LegWall = true, Zebra = true, TurningCircle = true, Wall = true, CurveWall = true, Island = true,
	WallCap = true,
}

local GROUPS = { Furniture = true, Walls = true }

local function hiddenFolder(): Folder
	local f = ServerStorage:FindFirstChild("HighwayHidden")
	if not f then
		f = Instance.new("Folder")
		f.Name = "HighwayHidden"
		f.Parent = ServerStorage
	end
	return f :: Folder
end

local function hide(obj: Instance, name: string, hidden: Folder)
	if obj.Parent == hidden then
		return
	end
	local was = Instance.new("ObjectValue")
	was.Name = "WasIn"
	was.Value = obj.Parent
	was.Parent = obj
	obj:SetAttribute("HiddenFor", name)
	obj.Parent = hidden
end

function Mouth.clear(data, name: string, opts)
	opts = opts or {}
	local road
	for _, r in data.roads do
		if r.name == name then
			road = r
		end
	end
	assert(road, "no road " .. name)
	local Riviera = workspace.Riviera
	local mine = Riviera.Roads:FindFirstChild(name)
	local hidden = hiddenFolder()
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { workspace.Terrain, mine }
	local s = road.s
	local half = s[1][7]
	local wide = half >= 30
	local report = { road = 0, dressing = 0, buildings = {}, lots = {}, other = {} }
	local seen = {}
	local n = #s
	local step = math.max(1, math.round(12 / math.max((Vector3.new(s[1][1], 0, s[1][3]) - Vector3.new(s[2][1], 0, s[2][3])).Magnitude, 1)))
	local i = 1
	while i < n do
		local j = math.min(i + step, n)
		local a = Vector3.new(s[i][1], s[i][2], s[i][3])
		local b = Vector3.new(s[j][1], s[j][2], s[j][3])
		local flatB = Vector3.new(b.X, a.Y, b.Z)
		local len = (flatB - a).Magnitude
		local mid = (a + b) / 2
		if len > 0.1 then
			local cf = CFrame.lookAt(Vector3.new(mid.X, mid.Y + 11, mid.Z), Vector3.new(flatB.X, mid.Y + 11, flatB.Z))
			-- (the road pieces of a road it joins: its own width + 2, like the builder's rule; street
			-- furniture: its pavements too)
			local nearEnd = i < 40 / 6 * step or j > n - 40 / 6 * step or i <= 30 or j >= n - 30
			for _, p in workspace:GetPartBoundsInBox(cf, Vector3.new(2 * (half + (if wide then 10 else 3)), 40, len + 1), params) do
				if seen[p] then
					continue
				end
				seen[p] = true
				local rel = cf:PointToObjectSpace(p.Position)
				local inRoad = math.abs(rel.X) <= half + 2.5
				if p:IsDescendantOf(Riviera.Roads) then
					if nearEnd and inRoad and (ROAD_PIECES[p.Name] or (p.Name == "Line" and math.abs(p.Size.X - 0.6) < 0.05)) then
						hide(p, name, hidden)
						report.road += 1
					end
				elseif p:IsDescendantOf(Riviera.Dressing) then
					-- (the Furniture and Walls models are big groups spread over a whole district: only the
					-- piece standing here goes)
					local top: Instance = p
					while top.Parent and top.Parent ~= Riviera.Dressing and not (top.Parent:IsA("Model") and GROUPS[top.Parent.Name]) do
						top = top.Parent
					end
					hide(top, name, hidden)
					report.dressing += 1
				elseif p:IsDescendantOf(Riviera.Buildings) then
					local top: Instance = p
					while top.Parent ~= Riviera.Buildings do
						top = top.Parent :: Instance
					end
					local allowed = false
					local where = (top :: any):GetPivot().Position
					for _, q in opts.buildings or {} do
						if Vector2.new(q.X - where.X, q.Z - where.Z).Magnitude < 12 then
							allowed = true
						end
					end
					if allowed then
						hide(top, name, hidden)
					end
					report.buildings[top.Name .. " " .. math.floor(where.X) .. "," .. math.floor(where.Z) .. (if allowed then " moved" else " STILL IN THE WAY")] = true
				elseif p:IsDescendantOf(Riviera.Sites) then
					report.lots[p.Name] = true
				elseif not p:IsDescendantOf(Riviera.Roads) then
					report.other[p:GetFullName()] = true
				end
			end
		end
		i = j
		if i % 80 == 0 then
			task.wait()
		end
	end
	return report
end

function Mouth.restore(name: string): number
	local hidden = hiddenFolder()
	local n = 0
	for _, obj in hidden:GetChildren() do
		if obj:GetAttribute("HiddenFor") == name then
			local was = obj:FindFirstChild("WasIn")
			if was and was.Value then
				local parent = was.Value
				was:Destroy()
				obj:SetAttribute("HiddenFor", nil)
				obj.Parent = parent
				n += 1
			end
		end
	end
	return n
end

return Mouth
