--[[
	YangonLampsBatch (Studio, Edit mode; whole-Yangon map, 14 Nov 2026): the street lamps of a BATCH (1, 2, 3), next to batch
	0.5's (YangonLamps.luau builds Workspace.Yangon.Lamps and clears it first, so this one never touches that folder).

	Spots: tools/yangon/city/details.py <tag> -> build/city/YangonLampSpots_<tag>_<n>.luau (one string each, YangonLamps' line
	format "x z yHint towardsRoadX towardsRoadZ kind"; kind P = pavement, D = a deck parapet), in ServerStorage.ClaudeTools.
	Rule (details.py lamps_batch): main roads with 2+ lanes each way, both sides, every 96 studs (staggered), 1.5 in from the
	kerb; flyovers / bridges on the parapet every 64; none in a junction, under a deck, on a landmark's ground or a lot.
	The lamp is YangonLamps' kit (ServerStorage.YangonData.LampKit: white LED head, white SpotLight; owner: "yangon lights
	are white"). A spot is used only when a ray down finds the right ground: a batch road's collision box (the roads are
	MeshParts without collision in Workspace.Yangon.RoadMeshesB<t>; their invisible boxes are in RoadCollideB<t> with
	attribute RoadBox): P needs RoadBox "P" or "M" (or batch 0.5's "Pavement" part), D needs RoadBox "W" (or a 0.5 deck's
	"Parapet" / "RampWall"); a P spot that misses is tried 1 and 2 studs further from the road.

	local L = require(game.ServerStorage.ClaudeTools.YangonLampsBatch:Clone())
	L.spawn("1")        then  L.status("1")       -> Workspace.Yangon.Lamps_1 (cleared first)
	L.undo("1")
]]

local ServerStorage = game:GetService("ServerStorage")

local M = {}

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

local function spots(tag: string): string
	local parts = {}
	for i = 1, 99 do
		local m = ServerStorage.ClaudeTools:FindFirstChild("YangonLampSpots_" .. tag .. "_" .. i)
		if not m then
			break
		end
		table.insert(parts, require((m :: ModuleScript):Clone()))
	end
	assert(#parts > 0, "no YangonLampSpots_" .. tag .. "_1 in ServerStorage.ClaudeTools")
	return table.concat(parts, "\n")
end

function M.build(tag: string): string
	tag = tostring(tag)
	local Y = workspace.Yangon
	local old = Y:FindFirstChild("Lamps_" .. tag)
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Lamps_" .. tag
	folder.Parent = Y
	-- the kit is YangonLamps' (it copies it into YangonData the first time)
	local kit = require(ServerStorage.ClaudeTools.YangonLamps:Clone()).kit()
	local up, back = footOffset(kit)
	local include = {}
	for _, name in { "Roads", "Decks", "RoadCollideB1", "RoadCollideB2", "RoadCollideB3" } do
		local f = Y:FindFirstChild(name)
		if f then
			table.insert(include, f)
		end
	end
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Include
	rp.FilterDescendantsInstances = include
	local made, missed, n = 0, 0, 0
	for x, z, yh, fx, fz, kind in string.gmatch(spots(tag), "(%S+) (%S+) (%S+) (%S+) (%S+) (%a)") do
		n += 1
		local toward = Vector3.new(tonumber(fx) :: number, 0, tonumber(fz) :: number).Unit
		local base = Vector3.new(tonumber(x) :: number, tonumber(yh) :: number, tonumber(z) :: number)
		local hit
		for _, push in (if kind == "D" then { 0 } else { 0, 1, 2 }) do
			local at = base - toward * push
			local h = workspace:Raycast(at + Vector3.new(0, 25, 0), Vector3.new(0, -60, 0), rp)
			local ok = false
			if h then
				local box = h.Instance:GetAttribute("RoadBox")
				if kind == "D" then
					ok = box == "W" or h.Instance.Name == "Parapet" or h.Instance.Name == "RampWall"
				else
					ok = box == "P" or box == "M" or h.Instance.Name == "Pavement"
				end
			end
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
	return string.format("batch %s lamps: %d placed, %d spots without the right ground", tag, made, missed)
end

function M.undo(tag: string)
	local old = workspace.Yangon:FindFirstChild("Lamps_" .. tostring(tag))
	if old then
		old:Destroy()
	end
end

function M.status(tag: string): string
	return tostring(ServerStorage.YangonData:GetAttribute("LampsStatus_" .. tostring(tag)))
end

function M.spawn(tag: string)
	tag = tostring(tag)
	local YD = ServerStorage.YangonData
	YD:SetAttribute("LampsStatus_" .. tag, "running")
	task.spawn(function()
		local t0 = os.clock()
		local ok, res = pcall(M.build, tag)
		YD:SetAttribute("LampsStatus_" .. tag, string.format("%s after %.1f s: %s", if ok then "done" else "ERROR", os.clock() - t0, tostring(res)))
	end)
end

return M
