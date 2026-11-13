--[[
	YangonLamps (Studio, Edit mode; Yangon build step 10, 2026-11-14, owner: "Step 10 night lights").

	Street lamps: Monaco's StreetLamp (a 26-stud steel pole, an arm, a warm Neon head tagged LampGlow and a SpotLight
	tagged LODLight / DayOff / ShadowLight, which WorldFx switches on near the camera at night) cloned onto every spot
	from tools/yangon/d16_lamps.py (ServerStorage.ClaudeTools.YangonLampSpots, one string). A spot is used only when a
	ray down finds the right ground: a Pavement piece (P, R) or a deck's Parapet / RampWall (D); a pavement spot that
	misses is tried 1 and 2 studs further from the road. The lamp's arm reaches over the road.

	The far city: its window bands (tag FarBand, YangonFar.city) get the Window + FarWindow tags, so WorldFx lights
	them at night like Monaco's far stand-in.

	local L = require(ServerStorage.ClaudeTools.YangonLamps:Clone())
	L.spawn(function() return L.build() end)   then L.status()  (Workspace.Yangon.Lamps, cleared first)
	L.farWindows()
	L.undo()
]]

local CollectionService = game:GetService("CollectionService")
local ServerStorage = game:GetService("ServerStorage")

local M = {}

-- the lamp model, kept in ServerStorage.YangonData.LampKit (copied from Monaco's the first time, so the lamps can
-- still be rebuilt once Monaco is out of the Workspace)
function M.kit(): Model
	local YD = ServerStorage:FindFirstChild("YangonData")
	local kit = YD and YD:FindFirstChild("LampKit")
	if kit then
		return kit :: Model
	end
	local src = workspace.Riviera.Dressing:FindFirstChild("StreetLamp", true) :: Model
	kit = src:Clone()
	kit.Name = "LampKit"
	-- (owner, 2026-11-14: "yangon lights are white, not dimmed lights") white LED heads and light, not Monaco's amber
	for _, d in kit:GetDescendants() do
		if d:IsA("BasePart") and d.Name == "Head" then
			d.Color = Color3.fromRGB(236, 244, 255)
		elseif d:IsA("SpotLight") then
			d.Color = Color3.fromRGB(232, 240, 255)
			d.Brightness = 7
		end
	end
	kit.Parent = YD
	return kit :: Model
end

-- the foot's offset from the model's pivot, measured from its parts: the lowest point under the pole, and how far
-- the pole stands behind the pivot (the head reaches the other way, local -Z)
local function footOffset(kit: Model): (number, number)
	local pole = kit:FindFirstChild("Foot") or kit:FindFirstChild("Pole")
	local rel = kit:GetPivot():PointToObjectSpace((pole :: BasePart).Position)
	local lowest = math.huge
	for _, p in kit:GetDescendants() do
		if p:IsA("BasePart") then
			local r = kit:GetPivot():PointToObjectSpace(p.Position)
			lowest = math.min(lowest, r.Y - p.Size.Y / 2)
		end
	end
	return -lowest, rel.Z
end

function M.build(): string
	local Y = workspace.Yangon
	local old = Y:FindFirstChild("Lamps")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Lamps"
	folder.Parent = Y
	local kit = M.kit()
	local up, back = footOffset(kit)
	local spots = require(ServerStorage.ClaudeTools.YangonLampSpots:Clone())
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = { Y.Roads, Y:FindFirstChild("Decks") }
	local made, missed = 0, 0
	local n = 0
	for x, z, yh, fx, fz, kind in string.gmatch(spots, "(%S+) (%S+) (%S+) (%S+) (%S+) (%a)") do
		n += 1
		local toward = Vector3.new(tonumber(fx) :: number, 0, tonumber(fz) :: number).Unit
		local base = Vector3.new(tonumber(x) :: number, tonumber(yh) :: number, tonumber(z) :: number)
		local hit
		for _, push in (if kind == "D" then { 0 } else { 0, 1, 2 }) do
			local at = base - toward * push
			local h = workspace:Raycast(at + Vector3.new(0, 25, 0), Vector3.new(0, -60, 0), rp)
			local ok = h and (if kind == "D" then (h.Instance.Name == "Parapet" or h.Instance.Name == "RampWall") else h.Instance.Name == "Pavement")
			if ok then
				hit = h
				break
			end
		end
		if not hit then
			missed += 1
			continue
		end
		local g = hit.Position
		local lamp = kit:Clone()
		lamp.Name = "StreetLamp"
		lamp:PivotTo(CFrame.lookAt(g, g + toward) * CFrame.new(0, up, -back))
		lamp.Parent = folder
		made += 1
		if n % 80 == 0 then
			task.wait()
		end
	end
	return string.format("lamps: %d placed, %d spots without the right ground", made, missed)
end

function M.farWindows(): string
	local far = workspace.Yangon:FindFirstChild("Far")
	local n = 0
	for _, p in (if far then far:GetDescendants() else {}) do
		if p:IsA("BasePart") and CollectionService:HasTag(p, "FarBand") then
			CollectionService:AddTag(p, "Window")
			CollectionService:AddTag(p, "FarWindow")
			n += 1
		end
	end
	return string.format("far window bands tagged: %d", n)
end

function M.undo()
	local old = workspace.Yangon:FindFirstChild("Lamps")
	if old then
		old:Destroy()
	end
end

function M.spawn(fn: () -> string)
	local YD = ServerStorage.YangonData
	YD:SetAttribute("LampsStatus", "running")
	task.spawn(function()
		local t0 = os.clock()
		local ok, res = pcall(fn)
		YD:SetAttribute("LampsStatus", string.format("%s after %.1f s: %s", if ok then "done" else "ERROR", os.clock() - t0, tostring(res)))
	end)
end

function M.status(): string
	return tostring(ServerStorage.YangonData:GetAttribute("LampsStatus"))
end

return M
