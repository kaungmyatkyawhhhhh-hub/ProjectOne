--[[ MapAudit v2 (P&L Studios / Myanmar Builders Club)
Read-only. A ModuleScript (put it in ServerStorage.Tools; it never runs by itself). In Play (server) or Studio:
  local report = require(game.ServerStorage.Tools.MapAudit)({ root = workspace.Galaxy })
It prints the report and returns it as text. Changes nothing.

Checks:
  FLOAT / SUNK   - object not resting on the ground
  TILT           - object rotated on X/Z (leaning / upside down) without AllowTilt
  ROT            - Y rotation not a multiple of 15 degrees (skipped for things aimed at a target: FaceTarget / Island)
  OVERLAP        - two objects inside each other
  STACK          - two objects at (almost) the same spot
  FACING         - sign / board / screen faces away from its target (default: spawn)
  EDGE / OUTWARD - a board on an island not at the rim / not facing the island
  UNREACHABLE    - spawn cannot walk to an interactable (path blocked)
  CROWDED        - two interactables closer than 6 studs (prompts fight)
  SMALLTEXT      - SurfaceGui text too small to read from its view distance
  DOUBLEFRAME    - framed art placed inside another frame

Attributes you can put on any object (Model or Part):
  Placeable   (bool)   include in the audit (or tag it "Placeable"; else the root's children are used)
  Floating    (bool)   allowed to float (sky islands, signs on posts...)
  AllowTilt   (bool)   allowed to lean
  FaceTarget  (string) the object it must face: a name, or a path from workspace ("Galaxy.Centre.Core"). Default: the
                       island's IslandSpawn for island boards, else the SpawnLocation
  ViewDistance(number) studs players read it from (default 30)
  HasOwnFrame (bool)   on an ImageLabel whose image already contains a frame
  Board       (any)    a board whose screen UI is drawn by the client (no SurfaceGui in the map): still checked as a board
  Island      (string) the island (by name) a board stands on (BoardPlacer sets it)
  NotGround   (bool)   on a PART that isn't floor (a door inside an arch): the ground ray goes through it
  Animated    (bool)   spins / hovers on purpose (a landmark): FLOAT, TILT and ROT are skipped

v2 (7 Nov, first run on Galaxy Incremental), changed from v1:
  - a ModuleScript can't run code without returning a value: v1 errored when required. Now it returns a function (opts).
  - root: opts.root (v1 only knew workspace.Map, else the whole workspace: it audited the Camera and the characters).
  - FaceTarget may be a path; a plain name search found the first "Core" anywhere.
  - a part with screens on two sides (a two-faced leaderboard) passed FACING only if EVERY side faced the target: now one
    facing side is enough.
  - boards whose UI the client draws (no SurfaceGui in the map) were skipped by EDGE / OUTWARD: attribute Board counts.
  - ROT is skipped for objects aimed at something (FaceTarget / Island): rule 2 allows any angle "when angling toward".
  - FACING is judged per OBJECT (any of its screens facing the target is enough), not per part: a board's decorated back
    panel faces the void on purpose. A Board whose UI the client draws counts its own front (its pivot's LookVector).
  - NotGround parts (a door in an arch) are skipped by the ground ray; Animated objects skip FLOAT / TILT / ROT.
]]

local PFS = game:GetService("PathfindingService")
local CS = game:GetService("CollectionService")

return function(opts)
	opts = opts or {}
	local ws = workspace
	local out, counts = {}, {}
	local function add(kind, inst, msg)
		counts[kind] = (counts[kind] or 0) + 1
		table.insert(out, string.format("[%s] %s: %s", kind, inst:GetFullName(), msg))
	end

	local MAP = opts.root or ws:FindFirstChild("Map") or ws
	local spawnLoc = MAP:FindFirstChildWhichIsA("SpawnLocation", true) or ws:FindFirstChildWhichIsA("SpawnLocation", true)

	-- what to audit
	local items, isItem = {}, {}
	for _, inst in ipairs(CS:GetTagged("Placeable")) do if inst:IsDescendantOf(MAP) then table.insert(items, inst) end end
	for _, d in ipairs(MAP:GetDescendants()) do
		if d:GetAttribute("Placeable") then table.insert(items, d) end
	end
	if #items == 0 then
		for _, c in ipairs(MAP:GetChildren()) do
			if (c:IsA("Model") or c:IsA("BasePart")) and not c:IsA("Terrain") and c.Name ~= "Ground" and not CS:HasTag(c, "Ground") then
				table.insert(items, c)
			end
		end
	end
	for _, it in ipairs(items) do isItem[it] = true end

	local function bbox(inst)
		if inst:IsA("Model") then return inst:GetBoundingBox() end
		return inst.CFrame, inst.Size
	end
	local function itemOf(part)
		local p = part
		while p and p ~= ws do
			if isItem[p] then return p end
			p = p.Parent
		end
		return nil
	end
	local function interactable(it)
		if it:GetAttribute("Interactable") then return true end
		return it:FindFirstChildWhichIsA("ProximityPrompt", true) ~= nil or it:FindFirstChildWhichIsA("ClickDetector", true) ~= nil
	end
	-- a name or a dotted path from workspace
	local function resolve(name: string)
		if string.find(name, "%.") then
			local cur = ws
			for seg in string.gmatch(name, "[^%.]+") do
				cur = cur and cur:FindFirstChild(seg)
			end
			return cur
		end
		return ws:FindFirstChild(name, true)
	end
	local function islandOf(it)
		local name = it:GetAttribute("Island")
		if name then return resolve(name) end
		return nil
	end
	local function findTarget(it)
		local name = it:GetAttribute("FaceTarget")
		if name then return resolve(name) end
		local isl = islandOf(it)
		if isl then return isl:FindFirstChild("IslandSpawn", true) or isl end -- boards on an island face that island
		return spawnLoc
	end
	local function posOf(inst)
		if not inst then return nil end
		if inst:IsA("Model") then return inst:GetPivot().Position end
		if inst:IsA("BasePart") then return inst.Position end
		return nil
	end
	local function isBoard(it)
		return it:GetAttribute("Board") ~= nil or it:FindFirstChildWhichIsA("SurfaceGui", true) ~= nil
	end

	-- 1. ground contact + 2. rotation
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	local notGround = {}
	for _, d in ipairs(MAP:GetDescendants()) do if d:IsA("BasePart") and d:GetAttribute("NotGround") then table.insert(notGround, d) end end
	for _, it in ipairs(items) do
		local cf, size = bbox(it)
		local animated = it:GetAttribute("Animated") == true
		if not it:GetAttribute("Floating") and not animated then
			local ex = table.clone(notGround)
			table.insert(ex, it)
			rp.FilterDescendantsInstances = ex
			local top = cf.Position + Vector3.new(0, size.Y / 2 + 0.05, 0)
			local hit = ws:Raycast(top, Vector3.new(0, -(size.Y + 60), 0), rp)
			local bottomY = cf.Position.Y - size.Y / 2
			if not hit then
				add("FLOAT", it, "nothing under it within 60 studs")
			else
				local gap = bottomY - hit.Position.Y
				if gap > 0.3 then add("FLOAT", it, string.format("%.1f studs above %s", gap, hit.Instance.Name))
				elseif gap < -0.6 then add("SUNK", it, string.format("%.1f studs into %s", -gap, hit.Instance.Name)) end
			end
		end
		local rcf = it:IsA("Model") and it:GetPivot() or it.CFrame
		if not it:GetAttribute("AllowTilt") and not animated and rcf.UpVector.Y < 0.985 then
			add("TILT", it, string.format("leans %.0f deg (UpVector.Y=%.2f)", math.deg(math.acos(math.clamp(rcf.UpVector.Y, -1, 1))), rcf.UpVector.Y))
		end
		if not it:GetAttribute("FaceTarget") and not it:GetAttribute("Island") and not animated then
			local _, ry, _ = rcf:ToOrientation()
			local deg = math.deg(ry) % 15
			if deg > 0.5 and deg < 14.5 then add("ROT", it, string.format("Y rotation %.1f deg (snap to 15)", math.deg(ry))) end
		end
	end

	-- 3. overlaps + stacks
	local op = OverlapParams.new()
	op.FilterType = Enum.RaycastFilterType.Exclude
	local seen = {}
	for _, it in ipairs(items) do
		local cf, size = bbox(it)
		op.FilterDescendantsInstances = { it }
		local shrink = Vector3.new(math.max(size.X - 0.4, 0.1), math.max(size.Y - 0.4, 0.1), math.max(size.Z - 0.4, 0.1))
		for _, p in ipairs(ws:GetPartBoundsInBox(cf, shrink, op)) do
			local other = itemOf(p)
			if other and other ~= it then
				local key = it:GetFullName() < other:GetFullName() and (it:GetFullName() .. "|" .. other:GetFullName()) or (other:GetFullName() .. "|" .. it:GetFullName())
				if not seen[key] then seen[key] = true; add("OVERLAP", it, "inside " .. other:GetFullName()) end
			end
		end
	end
	for i = 1, #items do
		for j = i + 1, #items do
			local a, b = posOf(items[i]), posOf(items[j])
			if a and b and (a - b).Magnitude < 1 then add("STACK", items[i], "same spot as " .. items[j]:GetFullName()) end
		end
	end

	-- 4. facing + text size + double frames (per part: one side facing its target is enough)
	local partFaces = {} -- [owner] = { owner, best dot, target name, upDown }
	for _, sg in ipairs(MAP:GetDescendants()) do
		if sg:IsA("SurfaceGui") then
			local part = sg.Adornee or sg.Parent
			if part and part:IsA("BasePart") then
				local owner = itemOf(part) or part
				local target = findTarget(owner)
				local tpos = posOf(target)
				local normal = part.CFrame:VectorToWorldSpace(Vector3.FromNormalId(sg.Face))
				local rec = partFaces[owner] or { owner = owner, best = -2, target = target and target.Name or "?", upDown = false }
				partFaces[owner] = rec
				if tpos then
					local to = tpos - part.Position
					to = Vector3.new(to.X, 0, to.Z)
					local flat = Vector3.new(normal.X, 0, normal.Z)
					if to.Magnitude > 1 and flat.Magnitude > 0.01 then rec.best = math.max(rec.best, flat.Unit:Dot(to.Unit)) else rec.best = math.max(rec.best, 1) end
				else
					rec.best = math.max(rec.best, 1)
				end
				if math.abs(normal.Y) > 0.7 then rec.upDown = true end
				local dist = owner:GetAttribute("ViewDistance") or 30
				if sg.SizingMode == Enum.SurfaceGuiSizingMode.PixelsPerStud then
					for _, t in ipairs(sg:GetDescendants()) do
						if (t:IsA("TextLabel") or t:IsA("TextButton")) and not t.TextScaled then
							local studs = t.TextSize / sg.PixelsPerStud
							if studs < dist / 30 then add("SMALLTEXT", owner, string.format("'%s' is %.2f studs tall, needs %.2f for %d studs", t.Text:sub(1, 20), studs, dist / 30, dist)) end
						end
					end
				end
				for _, img in ipairs(sg:GetDescendants()) do
					if img:IsA("ImageLabel") and img:GetAttribute("HasOwnFrame") then
						local extra = sg:FindFirstChildWhichIsA("UIStroke", true)
						local frameParts = 0
						for _, s in ipairs((owner:IsA("Model") and owner or part):GetDescendants()) do
							if s:IsA("BasePart") and s ~= part and s.Name:lower():find("frame") then frameParts += 1 end
						end
						if extra or frameParts > 0 then add("DOUBLEFRAME", owner, "framed art inside another frame (remove the part frame / UIStroke)") end
					end
				end
			end
		end
	end
	-- (a Board drawn by the client: its own front = its pivot's LookVector)
	for owner, rec in pairs(partFaces) do
		if owner:GetAttribute("Board") ~= nil and owner:IsA("Model") then
			local target = findTarget(owner)
			local tpos = posOf(target)
			if tpos then
				local piv = owner:GetPivot()
				local to = Vector3.new(tpos.X - piv.Position.X, 0, tpos.Z - piv.Position.Z)
				local look = Vector3.new(piv.LookVector.X, 0, piv.LookVector.Z)
				if to.Magnitude > 1 and look.Magnitude > 0.01 then rec.best = math.max(rec.best, look.Unit:Dot(to.Unit)) end
			end
		end
	end
	for _, rec in pairs(partFaces) do
		if rec.best < 0.5 then add("FACING", rec.owner, string.format("screen faces %.0f deg away from %s", math.deg(math.acos(math.clamp(rec.best, -1, 1))), rec.target)) end
		if rec.upDown then add("FACING", rec.owner, "screen points up/down") end
	end

	-- 4b. boards on islands: at the EDGE, back to the void, front to the island
	for _, it in ipairs(items) do
		local isl = islandOf(it)
		if isl and isBoard(it) then
			local icf, isize = bbox(isl)
			local radius = math.min(isize.X, isize.Z) / 2
			local p = posOf(it)
			local flat = Vector3.new(p.X - icf.Position.X, 0, p.Z - icf.Position.Z)
			if flat.Magnitude < radius * 0.6 then
				add("EDGE", it, string.format("%.0f studs from the island centre; boards go at the edge (>= %.0f)", flat.Magnitude, radius * 0.6))
			end
			local rcf = it:IsA("Model") and it:GetPivot() or it.CFrame
			if flat.Magnitude > 1 then
				local inward = (-flat).Unit
				local look = Vector3.new(rcf.LookVector.X, 0, rcf.LookVector.Z).Unit
				if look:Dot(inward) < 0.7 then
					add("OUTWARD", it, "front is not facing the island centre (players can't read it); use BoardPlacer")
				end
			end
		end
	end

	-- 5. reachability + crowding
	local inter = {}
	for _, it in ipairs(items) do if interactable(it) then table.insert(inter, it) end end
	for i = 1, #inter do
		for j = i + 1, #inter do
			local a, b = posOf(inter[i]), posOf(inter[j])
			if a and b and (a - b).Magnitude < 6 then add("CROWDED", inter[i], string.format("%.1f studs from %s", (a - b).Magnitude, inter[j]:GetFullName())) end
		end
	end
	if spawnLoc then
		for _, it in ipairs(inter) do
			local cf, size = bbox(it)
			local front = cf.Position + cf.LookVector * (size.Z / 2 + 4) -- a spot just in front of it
			local path = PFS:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true })
			local ok = pcall(function() path:ComputeAsync(spawnLoc.Position + Vector3.new(0, 3, 0), front) end)
			if not ok or path.Status ~= Enum.PathStatus.Success then
				add("UNREACHABLE", it, "no walking path from spawn to its front (" .. (ok and tostring(path.Status) or "error") .. ")")
			end
		end
	else
		table.insert(out, "[INFO] no SpawnLocation found: FACING defaults and UNREACHABLE skipped")
	end

	local lines = { string.format("==== MapAudit: %d objects, %d interactables ====", #items, #inter) }
	local kinds = {}
	for k, v in pairs(counts) do table.insert(kinds, k .. " " .. v) end
	table.sort(kinds)
	if #kinds == 0 then table.insert(lines, "CLEAN: nothing to fix") else table.insert(lines, table.concat(kinds, ", ")) end
	for _, line in ipairs(out) do table.insert(lines, line) end
	table.insert(lines, "==== end MapAudit ====")
	local report = table.concat(lines, "\n")
	print(report)
	return report
end
