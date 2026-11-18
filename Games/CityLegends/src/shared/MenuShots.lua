--[[
	MenuShots (shared) - the camera shots behind the loading screen and the main menu, on the 1:1 Yangon map
	(world studs; no Config.mapAt offsets).

	(owner, 19 Nov: "in loading screen, the scenes are inside of the buildings") the old shots were set before
	the 1:1 Myanmar Centre / Sedona refit and sat inside their meshes. Every shot is now checked in open air:
	  1) a ray from the camera to its target meets no terrain and no colliding part until the target itself;
	  2) the same line meets no visible map mesh's box (the landmark / kit meshes are CanQuery false, so rays
	     miss them: their boxes are tested by hand);
	  3) nothing solid round the camera (CLEAR_RADIUS), and the camera is above whatever is under it.
	The server runs the check once at start on the whole map (`MenuShots.publish`) and puts the good shots'
	numbers in workspace attribute `MenuShots` (and `MenuOrbit`); a shot that fails is warned and dropped,
	with none left the clients use FALLBACK (high over Myanmar Plaza). `MenuShots.selfTest()` prints every
	shot (Server in Play, or Edit). A shot: { name, from, at, drift (studs a second, both ends), fov }.
]]

local MenuShots = {}

MenuShots.SHOT_TIME = 4.6 -- seconds per loading shot (the drift is checked at both ends)
local CLEAR_RADIUS = 12
local TARGET_SLACK = 0.12 -- the line may meet something in the last 12% of the way (the target itself)
local CELL = 256

-- the first ones sit by the spawn (Myanmar Plaza, Persistent landmarks): they show at once on a phone
MenuShots.SHOTS = {
	{ name = "Myanmar Plaza from above Kabar Aye", subject = "MyanmarCentre", from = Vector3.new(34150, 330, 28150), at = Vector3.new(34845, 120, 27534), drift = Vector3.new(6, 0, -4), fov = 58 },
	{ name = "Sedona and Myanmar Centre over Inya", subject = "MyanmarCentre", from = Vector3.new(35650, 300, 26300), at = Vector3.new(34920, 140, 27150), drift = Vector3.new(-6, 0, 3), fov = 60 },
	{ name = "YCC, GGFest", subject = "YangonConventionCentre", from = Vector3.new(34200, 200, 22450), at = Vector3.new(33706, 71, 21990), drift = Vector3.new(-5, 0, 3), fov = 58 },
	{ name = "Shwedagon from People's Park", subject = "Shwedagon", from = Vector3.new(32300, 260, 38250), at = Vector3.new(33107, 330, 37198), drift = Vector3.new(5, 0, 2), fov = 55 },
	{ name = "Sule Pagoda roundabout from above", subject = "Sule", from = Vector3.new(36250, 260, 44850), at = Vector3.new(35999, 85, 45119), drift = Vector3.new(-4, 0, 3), fov = 56 },
	{ name = "Strand Road along the river", subject = "strand_hotel", from = Vector3.new(37750, 150, 47150), at = Vector3.new(37295, 50, 46671), drift = Vector3.new(-6, 0, -1), fov = 58 },
}
MenuShots.FALLBACK = { name = "high over Myanmar Plaza", subject = "MyanmarCentre", from = Vector3.new(34300, 620, 28400), at = Vector3.new(34845, 120, 27534), drift = Vector3.new(4, 0, -3), fov = 60 }

-- the menu's slow circle (Main.client's startOrbit): centre, radius, height over the centre, seconds a turn
MenuShots.ORBIT = { subject = "MyanmarCentre", centre = Vector3.new(34845, 150, 27534), radius = 760, height = 260, period = 150 }
MenuShots.ORBIT_FALLBACK = { subject = "MyanmarCentre", centre = Vector3.new(34845, 150, 27534), radius = 900, height = 520, period = 150 }

local function solid(p: BasePart): boolean
	return p.Transparency < 0.6 or (p.Transparency < 0.95 and p.CanCollide)
end

local function ignoreList(): { Instance }
	local list = {}
	for _, n in { "StreamFocus", "Traffic", "PlayerCars", "Pedestrians" } do
		local f = workspace:FindFirstChild(n)
		if f then
			table.insert(list, f)
		end
	end
	for _, pl in game:GetService("Players"):GetPlayers() do
		if pl.Character then
			table.insert(list, pl.Character)
		end
	end
	return list
end

-- the visible map parts rays can't see (CanQuery false: landmark, kit and tree meshes), by 256-stud cell;
-- the roads are left out (they lie on the ground, which the ray already meets)
local grid: { [number]: { BasePart } }? = nil
local function key(x: number, z: number): number
	return (x + 1000) * 4096 + (z + 1000)
end
local function buildGrid()
	grid = {}
	local root = workspace:FindFirstChild("Yangon1to1") or workspace:FindFirstChild("Yangon")
	if not root then
		return
	end
	local roads = root:FindFirstChild("Roads")
	for i, d in root:GetDescendants() do
		if i % 20000 == 0 then
			task.wait()
		end
		if d:IsA("BasePart") and not d.CanQuery and solid(d) and not (roads and d:IsDescendantOf(roads)) then
			local cf, h = d.CFrame, d.Size / 2
			local ex = math.abs(cf.RightVector.X) * h.X + math.abs(cf.UpVector.X) * h.Y + math.abs(cf.LookVector.X) * h.Z
			local ez = math.abs(cf.RightVector.Z) * h.X + math.abs(cf.UpVector.Z) * h.Y + math.abs(cf.LookVector.Z) * h.Z
			for cx = math.floor((cf.X - ex) / CELL), math.floor((cf.X + ex) / CELL) do
				for cz = math.floor((cf.Z - ez) / CELL), math.floor((cf.Z + ez) / CELL) do
					local k = key(cx, cz)
					local cell = (grid :: any)[k]
					if not cell then
						cell = {}
						;(grid :: any)[k] = cell
					end
					table.insert(cell, d)
				end
			end
		end
	end
end

-- does the line a -> a + d * (0..maxT) pass through part p's box (grown by pad)?
local function segHitsBox(p: BasePart, a: Vector3, d: Vector3, maxT: number, pad: number): boolean
	local o = p.CFrame:PointToObjectSpace(a)
	local v = p.CFrame:VectorToObjectSpace(d)
	local h = p.Size / 2 + Vector3.one * pad
	local t0, t1 = 0, maxT
	for _, ax in { "X", "Y", "Z" } do
		local oa, va, ha = (o :: any)[ax], (v :: any)[ax], (h :: any)[ax]
		if math.abs(va) < 1e-6 then
			if math.abs(oa) > ha then
				return false
			end
		else
			local u1, u2 = (-ha - oa) / va, (ha - oa) / va
			if u1 > u2 then
				u1, u2 = u2, u1
			end
			t0, t1 = math.max(t0, u1), math.min(t1, u2)
			if t0 > t1 then
				return false
			end
		end
	end
	return true
end

-- nil when the camera at `from` sees `at` in open air, else why not; `subject` (a landmark's name) is what the
-- shot looks at: the line may run into its boxes (they are the target), the camera may not sit in them
function MenuShots.blocked(from: Vector3, at: Vector3, subject: string?): string?
	if not grid then
		buildGrid()
	end
	local root = workspace:FindFirstChild("Yangon1to1") or workspace:FindFirstChild("Yangon")
	local marks = root and root:FindFirstChild("Landmarks")
	local target = subject and marks and marks:FindFirstChild(subject)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local skip = ignoreList()
	params.FilterDescendantsInstances = skip
	local dir = at - from
	local reach = 1 - TARGET_SLACK
	-- 1) terrain and colliding parts on the line (see-through parts skipped)
	for _ = 1, 12 do
		local hit = workspace:Raycast(from, dir, params)
		if not hit then
			break
		end
		if hit.Instance:IsA("BasePart") and not solid(hit.Instance :: BasePart) then
			table.insert(skip, hit.Instance)
			params.FilterDescendantsInstances = skip
		elseif hit.Distance < dir.Magnitude * reach then
			return ("view blocked by %s at %.0f of %.0f studs"):format(hit.Instance:GetFullName(), hit.Distance, dir.Magnitude)
		else
			break
		end
	end
	-- 2) the meshes rays can't see: the camera inside one's box, or the line through one
	local seen = {}
	local steps = math.max(1, math.ceil(dir.Magnitude * reach / (CELL / 2)))
	for s = 0, steps do
		local p = from + dir * (reach * s / steps)
		for dx = -1, 1 do
			for dz = -1, 1 do
				local cell = (grid :: any)[key(math.floor(p.X / CELL) + dx, math.floor(p.Z / CELL) + dz)]
				for _, part in cell or {} do
					if not seen[part] then
						seen[part] = true
						if part.Parent and not (target and part:IsDescendantOf(target)) and segHitsBox(part, from, dir, reach, 0) then
							return "view through the box of " .. part:GetFullName()
						end
					end
				end
			end
		end
	end
	-- 3) nothing round the camera, and the camera above what is under it
	local op = OverlapParams.new()
	op.FilterType = Enum.RaycastFilterType.Exclude
	op.FilterDescendantsInstances = ignoreList()
	for _, p in workspace:GetPartBoundsInRadius(from, CLEAR_RADIUS, op) do
		if solid(p) then
			return "a part round the camera: " .. p:GetFullName()
		end
	end
	for part in seen do -- (every mesh near the line, the camera's cells too)
		if part.Parent and segHitsBox(part, from, Vector3.zero, 0, CLEAR_RADIUS) then
			return "camera inside the box of " .. part:GetFullName()
		end
	end
	local down = workspace:Raycast(from + Vector3.new(0, 2000, 0), Vector3.new(0, -4000, 0), params)
	if down and down.Position.Y > from.Y - 4 then
		return "under " .. down.Instance:GetFullName()
	end
	return nil
end

function MenuShots.shotBlocked(shot): string?
	return MenuShots.blocked(shot.from, shot.at, shot.subject)
		or MenuShots.blocked(shot.from + shot.drift * MenuShots.SHOT_TIME, shot.at + shot.drift * MenuShots.SHOT_TIME, shot.subject)
end

-- the orbit's camera and target at angle a
function MenuShots.orbitAt(o, a: number): (Vector3, Vector3)
	return o.centre + Vector3.new(math.cos(a), 0, math.sin(a)) * o.radius + Vector3.new(0, o.height, 0), o.centre
end

function MenuShots.orbitBlocked(o): string?
	for i = 0, 23 do
		local pos, at = MenuShots.orbitAt(o, i / 24 * math.pi * 2)
		local why = MenuShots.blocked(pos, at, o.subject)
		if why then
			return ("at %d deg: %s"):format(i * 15, why)
		end
	end
	return nil
end

-- (server, once at start) check every shot and publish the good ones for the clients
function MenuShots.publish()
	local good = {}
	for i, s in MenuShots.SHOTS do
		local why = MenuShots.shotBlocked(s)
		if why then
			warn("[CityLegends] menu shot dropped, " .. s.name .. ": " .. why)
		else
			table.insert(good, i)
		end
		task.wait()
	end
	local orbitWhy = MenuShots.orbitBlocked(MenuShots.ORBIT)
	if orbitWhy then
		warn("[CityLegends] menu orbit blocked, the high one instead: " .. orbitWhy)
	end
	workspace:SetAttribute("MenuOrbit", if orbitWhy then "high" else "low")
	workspace:SetAttribute("MenuShots", table.concat(good, ","))
	grid = nil -- (free it: only used at start)
	return good
end

-- (client) the published good shots, or FALLBACK alone; waits up to `wait` seconds for the server
function MenuShots.good(wait: number?): { any }
	local deadline = os.clock() + (wait or 0)
	while workspace:GetAttribute("MenuShots") == nil and os.clock() < deadline do
		task.wait(0.1)
	end
	local list = {}
	for n in string.gmatch(tostring(workspace:GetAttribute("MenuShots") or ""), "%d+") do
		table.insert(list, MenuShots.SHOTS[tonumber(n) :: number])
	end
	if #list == 0 then
		table.insert(list, MenuShots.FALLBACK)
	end
	return list
end

function MenuShots.orbit()
	return if workspace:GetAttribute("MenuOrbit") == "low" then MenuShots.ORBIT else MenuShots.ORBIT_FALLBACK
end

-- (client) has the ground under a shot's target streamed in yet?
function MenuShots.streamed(shot): boolean
	return workspace:Raycast(shot.at + Vector3.new(0, 1500, 0), Vector3.new(0, -3000, 0)) ~= nil
end

-- every shot's result, one line each (true when all pass)
function MenuShots.selfTest(): (boolean, string)
	local lines, ok = {}, true
	local all = table.clone(MenuShots.SHOTS)
	table.insert(all, MenuShots.FALLBACK)
	for _, s in all do
		local why = MenuShots.shotBlocked(s)
		ok = ok and why == nil
		table.insert(lines, s.name .. ": " .. (why or "clear"))
	end
	for _, o in { MenuShots.ORBIT, MenuShots.ORBIT_FALLBACK } do
		local why = MenuShots.orbitBlocked(o)
		ok = ok and why == nil
		table.insert(lines, ("orbit r%d h%d: %s"):format(o.radius, o.height, why or "clear"))
	end
	grid = nil
	return ok, table.concat(lines, "\n")
end

return MenuShots
