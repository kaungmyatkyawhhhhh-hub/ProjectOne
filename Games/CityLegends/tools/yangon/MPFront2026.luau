--[[
	MPFront2026 (Studio, Edit; 2026-11-27, owner: "the myanmar plaza thing is on the road. also that thing is from the
	2019 myanmar plaza. the new myanmar plaza is different"; vault `City Legends/2026-11-27 Myanmar Plaza front -
	current design, off the road.md`).

	Swaps the old corner sign (granite ring wall + white HAGL MYANMAR CENTRE band, hedge / lawn ring, teal channel,
	sculpture plinth, MCDrone's round fountain + hedge ring) for the current low semicircle made by
	tools/yangon/city/mp_front_2026.py, all inside the site outline.
	  M.run(frontModelId, patchModelId) -> new meshes in MyanmarCentre.Front2026, patched HDG / LIT / MUW / PGR in
	                                       MyanmarCentre.Meshes, new wall collision Col_front26; everything taken out
	                                       goes to ServerStorage.MyanmarPlazaSign_old2019 (attribute OldParent)
	  M.undo()                          -> puts it all back, removes the new pieces
	Needs ServerStorage.ClaudeTools.LandmarkPlace3D (group looks).
	Done 27 Nov: M.run(129480979539349, 99739996241452) (front v2, patch; group 33151111), then M.collide with all 46
	boxes of imports/sync/landmarks/mc1/mc1_front26.json "coll" (16 wall + 30 paving).
	Round 2 (27 Nov, owner: no grass, straight lines): LandmarkPlace3D.place(LoadAsset(123619769893698), MC, "Front2026")
	(front v10: no lawns, PAV forecourt, hidden fill sheets) + 613 Col_front26 (16 wall + 126 platform + 471 forecourt);
	terrain Grass / Ground under the front -> Pavement; Cell_22x17.RMeshL <- asset 94001462504490 (straight lines).
	Studio v2347.
]]
local InsertService = game:GetService("InsertService")
local ServerStorage = game:GetService("ServerStorage")
local M = {}

local C = Vector3.new(34717.5, 0, 27127.5)
local FACE = Vector3.new(-0.392, 0, -0.92).Unit
-- old meshes that were only the sign (by MeshId) and the merged ones that were patched
local WHOLE = {
	["74920454012171"] = "PBD", ["96975441157136"] = "POL", ["102259067550545"] = "WAT", ["79279852428856"] = "ORG",
	["98203136961135"] = "HGL", ["74800558827988"] = "BLU", ["103558508142798"] = "GLD", ["107222226235044"] = "GLD",
	["107291524348119"] = "LAW",
}
local PATCHED = { HDG = "97769224036288", LIT = "108981973966785", PGR = "135629240369686" }
-- MUW: the ground MUW mesh (93.16 x 26.09 x 600.77 at 34706.28, 48.55, 27389.45)
local MUW_SIZE = Vector3.new(93.16, 26.09, 600.77)

local function mc()
	return workspace.Yangon1to1.Landmarks.MyanmarCentre
end

local function store()
	local f = ServerStorage:FindFirstChild("MyanmarPlazaSign_old2019")
	if not f then
		f = Instance.new("Folder")
		f.Name = "MyanmarPlazaSign_old2019"
		f.Parent = ServerStorage
	end
	return f
end

local function park(inst: Instance)
	inst:SetAttribute("OldParent", inst.Parent:GetFullName())
	inst.Parent = store()
end

local function idOf(p: MeshPart)
	return string.match(p.MeshId, "%d+$") or ""
end

local function inZone(pos: Vector3)
	local d = Vector3.new(pos.X - C.X, 0, pos.Z - C.Z)
	local r = d.Magnitude
	return (r >= 29 and r <= 50 and d:Dot(FACE) >= -2.5) or (math.abs(d.X) < 3.7 and math.abs(d.Z) < 3.7)
end

function M.run(frontId: number, patchId: number)
	local MC = mc()
	assert(not MC:FindFirstChild("Front2026"), "already run")
	local P = require(ServerStorage.ClaudeTools.LandmarkPlace3D:Clone())
	local front = InsertService:LoadAsset(frontId)
	local patch = InsertService:LoadAsset(patchId)
	local log = {}
	-- 1. old sign meshes out (whole or swapped for the patched copy)
	local patchParts = {}
	for _, d in patch:GetDescendants() do
		if d:IsA("MeshPart") then
			local grp, _, c, size = P.parse(d.Name)
			if not grp and d.Parent then
				grp, _, c, size = P.parse((string.gsub(d.Parent.Name, "_Node$", "")))
			end
			if grp then
				patchParts[grp] = { part = d, c = c, size = size }
			end
		end
	end
	for _, p in MC.Meshes:GetChildren() do
		if p:IsA("MeshPart") then
			local id = idOf(p)
			local grp = WHOLE[id]
			local pg = nil
			for g, pid in PATCHED do
				if pid == id then
					pg = g
				end
			end
			if p.Name == "MUW" and (p.Size - MUW_SIZE).Magnitude < 0.2 then
				pg = "MUW"
			end
			if grp then
				park(p)
				table.insert(log, "out " .. grp .. " " .. id)
			elseif pg then
				local np = patchParts[pg]
				assert(np, "no patched " .. pg)
				local q = p:Clone()
				q:ApplyMesh(np.part)
				q.Size = np.size
				q.CFrame = CFrame.new(np.c)
				q:SetAttribute("Patched", "front2026")
				park(p)
				q.Parent = MC.Meshes
				table.insert(log, "patched " .. pg)
			end
		end
	end
	-- 2. the old collision in the sign zone, MCDrone's round fountain + hedge ring
	for _, c in MC.Collide:GetChildren() do
		if c:IsA("BasePart") and inZone(c.Position) and c.Size.Y > 1.3 then
			park(c)
		end
	end
	local dm = MC:FindFirstChild("DroneMatch")
	if dm and dm:FindFirstChild("RoundPlaza") then
		park(dm.RoundPlaza)
		table.insert(log, "out DroneMatch.RoundPlaza")
	end
	-- 3. the new pieces
	local n = P.place(front, MC, "Front2026")
	table.insert(log, "new meshes " .. n)
	front:Destroy()
	patch:Destroy()
	return table.concat(log, "\n")
end

function M.collide(boxes: { { number } })
	local MC = mc()
	for _, b in boxes do
		local c = Instance.new("Part")
		c.Name = "Col_front26"
		c.Anchored = true
		c.Transparency = 1
		c.CanCollide = true
		c.CanTouch = false
		c.CastShadow = false
		c.Size = Vector3.new(b[4], b[5], b[6])
		c.CFrame = CFrame.new(b[1], b[2], b[3]) * CFrame.Angles(0, b[7], 0)
		c.Parent = MC.Collide
	end
end

function M.undo()
	local MC = mc()
	local f = MC:FindFirstChild("Front2026")
	if f then
		f:Destroy()
	end
	for _, c in MC.Collide:GetChildren() do
		if c.Name == "Col_front26" then
			c:Destroy()
		end
	end
	for _, p in MC.Meshes:GetChildren() do
		if p:GetAttribute("Patched") == "front2026" then
			p:Destroy()
		end
	end
	for _, o in store():GetChildren() do
		local path = o:GetAttribute("OldParent")
		local parent = game
		for seg in string.gmatch(path, "[^%.]+") do
			parent = parent:FindFirstChild(seg) or (seg == "Workspace" and workspace) or parent
		end
		o.Parent = parent
	end
end

return M
