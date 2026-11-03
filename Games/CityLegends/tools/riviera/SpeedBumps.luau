--[[
	Riviera speed bumps (Studio, Edit mode). Loaded into ServerStorage.RivieraTools by the MCP and run
	on build/riviera/roads.json after Roads.build.

	(owner, 2026-11-03: "add slow down ramps on intersection and heavy turns"): a low rounded hump in
	yellow and black stripes across the whole road
	  * on every road coming into a junction, BEFORE studs before the junction's edge;
	  * before and after every sharp turn (the road turns more than SHARP degrees over ~100 studs).
	Not on the three long routes (yellow on the map: owner, the same day).
	It stands HUMP studs above the road (a firm bump through the suspension at speed, no jump; the
	car's bump kick starts at 0.45), each stripe on the road's own height, so it follows the camber.
	Never on a tunnel, never within GAP studs of another bump. Tagged "SpeedBump" (Traffic slows for
	them).

	SpeedBumps.build(data, roadsFolder, parent) -> bumps made (parent: e.g. Workspace.Riviera.Dressing)
]]

local CollectionService = game:GetService("CollectionService")

local SpeedBumps = {}

local HALF = 32
local BEFORE = 26 -- studs before a junction's edge
local SHARP = 55 -- degrees over the window: a sharp turn
local WINDOW = 8 -- samples each side (~50 studs)
local HUMP = 0.35 -- how far it stands above the road
local DEPTH = 3.2 -- along the road
local STRIPE = 4 -- stripe width across the road
local GAP = 45 -- no two bumps closer than this
local YELLOW = Color3.fromRGB(236, 190, 40)
local BLACK = Color3.fromRGB(28, 28, 30)

function SpeedBumps.build(data, roadsFolder: Instance, parent: Instance): number
	local roads, grid = {}, {}
	for ri, r in data.roads do
		local pts = {}
		for i, s in r.s do
			pts[i] = { pos = Vector3.new(s[1], s[2], s[3]), dir = Vector3.new(s[4], 0, s[5]), tunnel = s[6] == 1, wl = s[7] or HALF, wr = s[8] or HALF }
			local key = math.floor(s[1] / 24) .. "," .. math.floor(s[3] / 24)
			grid[key] = grid[key] or {}
			table.insert(grid[key], { ri, i })
		end
		roads[ri] = { name = r.name, kind = r.kind, pts = pts }
	end
	local function otherNear(pos: Vector3, self: number, radius: number): boolean
		local cx, cz = math.floor(pos.X / 24), math.floor(pos.Z / 24)
		local reach = math.ceil(radius / 24)
		for dx = -reach, reach do
			for dz = -reach, reach do
				for _, e in grid[(cx + dx) .. "," .. (cz + dz)] or {} do
					if e[1] ~= self then
						local q = roads[e[1]].pts[e[2]].pos
						if Vector2.new(q.X - pos.X, q.Z - pos.Z).Magnitude < radius then
							return true
						end
					end
				end
			end
		end
		return false
	end

	local roadParts = {}
	for _, d in roadsFolder:GetDescendants() do
		if d:IsA("BasePart") and (d.Name == "Road" or d.Name == "TurningCircle") then
			table.insert(roadParts, d)
		end
	end
	local onRoad = RaycastParams.new()
	onRoad.FilterType = Enum.RaycastFilterType.Include
	onRoad.FilterDescendantsInstances = roadParts

	local folder = parent:FindFirstChild("SpeedBumps")
	if folder then
		folder:Destroy()
	end
	folder = Instance.new("Folder")
	folder.Name = "SpeedBumps"
	folder.Parent = parent

	local placed: { Vector3 } = {}
	local count = 0
	local function bumpAt(ri: number, i: number)
		local r = roads[ri]
		local p = r.pts[i]
		if not p or p.tunnel or otherNear(p.pos, ri, HALF + 8) then
			return
		end
		for _, q in placed do
			if Vector2.new(q.X - p.pos.X, q.Z - p.pos.Z).Magnitude < GAP then
				return
			end
		end
		local d = p.dir.Unit
		local right = Vector3.new(-d.Z, 0, d.X)
		local model = Instance.new("Model")
		model.Name = "SpeedBump"
		local stripes = 0
		local n = math.floor((p.wl + p.wr - 3) / STRIPE)
		for k = 0, n - 1 do
			local x = -p.wl + 1.5 + (k + 0.5) * STRIPE
			local c = p.pos + right * x
			local hit = workspace:Raycast(c + Vector3.new(0, 8, 0), Vector3.new(0, -20, 0), onRoad)
			if hit and hit.Instance.Parent and hit.Instance.Parent.Name == r.name then
				-- a cylinder lying across the road, sunk so only its top HUMP shows: a smooth hump
				local part = Instance.new("Part")
				part.Name = "Hump"
				part.Shape = Enum.PartType.Cylinder
				part.Anchored = true
				part.CastShadow = false
				part.Material = Enum.Material.SmoothPlastic
				part.Color = if k % 2 == 0 then YELLOW else BLACK
				local radius = (DEPTH * DEPTH / 4 + HUMP * HUMP) / (2 * HUMP) -- the circle through the hump's ends and top
				part.Size = Vector3.new(STRIPE + 0.02, radius * 2, radius * 2)
				part.CFrame = CFrame.fromMatrix(hit.Position + Vector3.new(0, HUMP - radius, 0), right, Vector3.yAxis)
				part.Parent = model
				stripes += 1
			end
		end
		if stripes >= 3 then
			model.Parent = folder
			CollectionService:AddTag(model, "SpeedBump")
			model:SetAttribute("Dir", d)
			table.insert(placed, p.pos)
			count += 1
		else
			model:Destroy()
		end
	end

	for ri, r in roads do
		-- (owner, same day: "don't add slow down ramps on yellow roads") none on the three long routes
		if r.kind == "route" then
			continue
		end
		local n = #r.pts
		local step = if n > 1 then math.max(Vector2.new(r.pts[2].pos.X - r.pts[1].pos.X, r.pts[2].pos.Z - r.pts[1].pos.Z).Magnitude, 1) else 6.4
		local back = math.max(1, math.floor(BEFORE / step + 0.5))
		-- junctions: where the road comes within reach of another one (each run's start and end)
		local inJ = {}
		for i, p in r.pts do
			inJ[i] = otherNear(p.pos, ri, HALF + 6)
		end
		for i = 2, n do
			if inJ[i] and not inJ[i - 1] then
				bumpAt(ri, i - back) -- coming into the junction this way
			end
			if inJ[i - 1] and not inJ[i] then
				bumpAt(ri, i - 1 + back) -- ...and the other way
			end
		end
		-- sharp turns: bumps before each end of a run of sharp turning
		local sharp = {}
		for i = 1, n do
			local a = r.pts[math.max(1, i - WINDOW)].dir
			local b = r.pts[math.min(n, i + WINDOW)].dir
			sharp[i] = a.Magnitude > 0 and b.Magnitude > 0 and math.deg(math.acos(math.clamp(a.Unit:Dot(b.Unit), -1, 1))) > SHARP
		end
		for i = 2, n do
			if sharp[i] and not sharp[i - 1] then
				bumpAt(ri, i - 2)
			end
			if sharp[i - 1] and not sharp[i] then
				bumpAt(ri, i + 1)
			end
		end
		if ri % 4 == 0 then
			task.wait()
		end
	end
	return count
end

return SpeedBumps
