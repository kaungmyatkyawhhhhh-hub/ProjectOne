--[[
	MenuShots (shared) - the camera shots behind the loading screen and the main menu, on the 1:1 Yangon map
	(Workspace.Yangon1to1, world studs; no Config.mapAt offsets).

	(owner, 19 Nov: "in loading screen, the scenes are inside of the buildings") the old shots were set before
	the 1:1 Myanmar Centre / Sedona refit and sat inside them. Every shot is now checked in open air before it
	is used: a ray from the camera to its target meets nothing until the target itself, nothing solid is
	within CLEAR_RADIUS of the camera, and the camera is above whatever is under it (ground, terrain, roof).
	A shot that fails is dropped (with a warning); with none left, FALLBACK (a high aerial over Myanmar Plaza).
	MenuShots.selfTest() prints every shot's result (run it on the Server in Play, or in Edit: the whole map).

	A shot: { name, from, at, drift (studs a second, both ends move), fov }
]]

local MenuShots = {}

MenuShots.SHOT_TIME = 4.6 -- seconds per loading shot (the drift is checked at both ends)
local CLEAR_RADIUS = 12
local TARGET_SLACK = 0.12 -- a ray may stop this share of the way short of the target (it hits the target)

MenuShots.SHOTS = {
	{ name = "Myanmar Plaza from above Kabar Aye", from = Vector3.new(34150, 330, 28150), at = Vector3.new(34845, 120, 27534), drift = Vector3.new(6, 0, -4), fov = 58 },
	{ name = "Sedona and Myanmar Centre over Inya", from = Vector3.new(35650, 300, 26300), at = Vector3.new(34920, 140, 27150), drift = Vector3.new(-6, 0, 3), fov = 60 },
	{ name = "Shwedagon from People's Park", from = Vector3.new(32300, 260, 38250), at = Vector3.new(33107, 330, 37198), drift = Vector3.new(5, 0, 2), fov = 55 },
	{ name = "Sule Pagoda roundabout from above", from = Vector3.new(36250, 260, 44850), at = Vector3.new(35999, 85, 45119), drift = Vector3.new(-4, 0, 3), fov = 56 },
	{ name = "Strand Road along the river", from = Vector3.new(37700, 140, 46950), at = Vector3.new(36900, 40, 46600), drift = Vector3.new(-8, 0, -1), fov = 58 },
	{ name = "YCC, GGFest", from = Vector3.new(34200, 200, 22450), at = Vector3.new(33706, 71, 21990), drift = Vector3.new(-5, 0, 3), fov = 58 },
}
MenuShots.FALLBACK = { name = "high over Myanmar Plaza", from = Vector3.new(34300, 620, 28400), at = Vector3.new(34845, 120, 27534), drift = Vector3.new(4, 0, -3), fov = 60 }

-- the menu's slow circle (Main.client's startOrbit): centre, radius, height over the centre, seconds a turn
MenuShots.ORBIT = { centre = Vector3.new(34845, 150, 27534), radius = 760, height = 260, period = 150 }
MenuShots.ORBIT_FALLBACK = { centre = Vector3.new(34845, 150, 27534), radius = 900, height = 520, period = 150 }

local function solid(p: BasePart): boolean
	return p.Transparency < 0.95 and p.CanCollide or p.Transparency < 0.6
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

-- nil when the camera at `from` sees `at` in open air, else why not
function MenuShots.blocked(from: Vector3, at: Vector3): string?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local skip = ignoreList()
	params.FilterDescendantsInstances = skip
	-- 1) the line of sight (see-through parts are skipped)
	local dir = at - from
	for _ = 1, 12 do
		local hit = workspace:Raycast(from, dir, params)
		if not hit then
			break
		end
		if hit.Instance:IsA("BasePart") and not solid(hit.Instance :: BasePart) then
			table.insert(skip, hit.Instance)
			params.FilterDescendantsInstances = skip
		elseif hit.Distance < dir.Magnitude * (1 - TARGET_SLACK) then
			return ("view blocked by %s at %.0f of %.0f studs"):format(hit.Instance:GetFullName(), hit.Distance, dir.Magnitude)
		else
			break
		end
	end
	-- 2) nothing round the camera
	local op = OverlapParams.new()
	op.FilterType = Enum.RaycastFilterType.Exclude
	op.FilterDescendantsInstances = ignoreList()
	for _, p in workspace:GetPartBoundsInRadius(from, CLEAR_RADIUS, op) do
		if solid(p) then
			return "a part round the camera: " .. p:GetFullName()
		end
	end
	-- 3) the camera is above what is under it (not under terrain or a roof)
	local down = workspace:Raycast(from + Vector3.new(0, 2000, 0), Vector3.new(0, -4000, 0), params)
	if down and down.Position.Y > from.Y - 4 then
		return "under " .. down.Instance:GetFullName()
	end
	return nil
end

function MenuShots.shotBlocked(shot): string?
	return MenuShots.blocked(shot.from, shot.at)
		or MenuShots.blocked(shot.from + shot.drift * MenuShots.SHOT_TIME, shot.at + shot.drift * MenuShots.SHOT_TIME)
end

-- the orbit's camera and target at angle a
function MenuShots.orbitAt(o, a: number): (Vector3, Vector3)
	local pos = o.centre + Vector3.new(math.cos(a), 0, math.sin(a)) * o.radius + Vector3.new(0, o.height, 0)
	return pos, o.centre
end

function MenuShots.orbitBlocked(o): string?
	for i = 0, 23 do
		local pos, at = MenuShots.orbitAt(o, i / 24 * math.pi * 2)
		local why = MenuShots.blocked(pos, at)
		if why then
			return ("at %d deg: %s"):format(i * 15, why)
		end
	end
	return nil
end

-- the shots that pass (in order), or just the fallback
function MenuShots.pick(): { any }
	local good = {}
	for _, s in MenuShots.SHOTS do
		local why = MenuShots.shotBlocked(s)
		if why then
			warn("[CityLegends] menu shot dropped, " .. s.name .. ": " .. why)
		else
			table.insert(good, s)
		end
	end
	if #good == 0 then
		table.insert(good, MenuShots.FALLBACK)
	end
	return good
end

function MenuShots.orbit()
	local why = MenuShots.orbitBlocked(MenuShots.ORBIT)
	if why then
		warn("[CityLegends] menu orbit blocked, using the high one: " .. why)
		return MenuShots.ORBIT_FALLBACK
	end
	return MenuShots.ORBIT
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
	for name, o in { orbit = MenuShots.ORBIT, orbitFallback = MenuShots.ORBIT_FALLBACK } do
		local why = MenuShots.orbitBlocked(o)
		ok = ok and why == nil
		table.insert(lines, name .. ": " .. (why or "clear"))
	end
	return ok, table.concat(lines, "\n")
end

return MenuShots
