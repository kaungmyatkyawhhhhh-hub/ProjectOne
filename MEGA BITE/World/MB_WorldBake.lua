-- MEGA BITE WorldBake (13 Nov): bakes two height maps of the finished world for the server's creatures (fish, predators):
--   MB_GridFloor = the seabed (terrain only)        MB_GridTop = the highest solid thing (seabed, rocks, landmarks, corals)
-- 8-stud cells, +-1800 studs, one byte per cell (height + 170, whole studs), stored as base64 in ServerStorage.
-- Creatures read them through ServerScriptService.MB_World (no raycasts at run time, nothing swims into the ground or a rock).
-- RE-RUN after every map change (Edit mode):  require(game.ServerStorage.MB_WorldBake:Clone())()
local CELL, HALF, OFF = 8, 1800, 170
local NX = HALF * 2 / CELL
local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function encode(buf)
	local n = buffer.len(buf)
	local out, parts = table.create(1024), {}
	local k = 0
	for i = 0, n - 1, 3 do
		local a = buffer.readu8(buf, i)
		local b = i + 1 < n and buffer.readu8(buf, i + 1) or 0
		local c = i + 2 < n and buffer.readu8(buf, i + 2) or 0
		local v = a * 65536 + b * 256 + c
		local c1, c2, c3, c4 = v // 262144 % 64 + 1, v // 4096 % 64 + 1, v // 64 % 64 + 1, v % 64 + 1
		k += 1
		out[k] = string.sub(B64, c1, c1) .. string.sub(B64, c2, c2) .. (i + 1 < n and string.sub(B64, c3, c3) or "=") .. (i + 2 < n and string.sub(B64, c4, c4) or "=")
		if k == 1024 then table.insert(parts, table.concat(out)); k = 0; table.clear(out) end
	end
	if k > 0 then table.insert(parts, table.concat(out, "", 1, k)) end
	return table.concat(parts)
end
return function()
	local terr = workspace.Terrain
	local rpF = RaycastParams.new(); rpF.FilterType = Enum.RaycastFilterType.Include; rpF.FilterDescendantsInstances = {terr}; rpF.IgnoreWater = true
	local rpT = RaycastParams.new(); rpT.FilterType = Enum.RaycastFilterType.Include; rpT.FilterDescendantsInstances = {terr, workspace.MB_Map}; rpT.IgnoreWater = true; rpT.RespectCanCollide = true
	local fl, tp = buffer.create(NX * NX), buffer.create(NX * NX)
	local down = Vector3.new(0, -400, 0)
	local t0 = os.clock()
	for iz = 0, NX - 1 do
		local z = -HALF + (iz + 0.5) * CELL
		for ix = 0, NX - 1 do
			local x = -HALF + (ix + 0.5) * CELL
			local a = workspace:Raycast(Vector3.new(x, 130, z), down, rpF)
			local fy = a and a.Position.Y or 100
			local b = workspace:Raycast(Vector3.new(x, 130, z), down, rpT)
			local ty = b and b.Position.Y or fy
			buffer.writeu8(fl, iz * NX + ix, math.clamp(math.floor(fy + OFF + 0.5), 0, 255))
			buffer.writeu8(tp, iz * NX + ix, math.clamp(math.floor(math.max(ty, fy) + OFF + 0.5), 0, 255))
		end
		if iz % 6 == 0 then task.wait() end
	end
	-- corals and sea palms (not solid, but fish should not swim through the middle of them)
	local SOFT = {BrainCoral = true, BubbleCoral = true, BranchCoral = true, TableCoral = true, SeaPalm = true}
	local n = 0
	for _, d in ipairs(workspace.MB_Map:GetDescendants()) do
		if d:IsA("MeshPart") and SOFT[d.Name] and not d.CanCollide then
			n += 1
			local r = math.max(d.Size.X, d.Size.Z) * 0.4
			local top = math.clamp(math.floor(d.Position.Y + d.Size.Y * 0.5 + OFF + 0.5), 0, 255)
			local x0, x1 = math.floor((d.Position.X - r + HALF) / CELL), math.floor((d.Position.X + r + HALF) / CELL)
			local z0, z1 = math.floor((d.Position.Z - r + HALF) / CELL), math.floor((d.Position.Z + r + HALF) / CELL)
			for iz = math.max(z0, 0), math.min(z1, NX - 1) do
				for ix = math.max(x0, 0), math.min(x1, NX - 1) do
					local i = iz * NX + ix
					if buffer.readu8(tp, i) < top then buffer.writeu8(tp, i, top) end
				end
			end
			if n % 500 == 0 then task.wait() end
		end
	end
	local SS = game.ServerStorage
	local function save(name, buf)
		-- a StringValue holds under 200,000 characters: the text is split over children "1", "2", ... (read in order)
		local old = SS:FindFirstChild(name); if old then old:Destroy() end
		local v = Instance.new("Folder")
		v.Name = name
		local text = encode(buf)
		local PIECE = 180000   -- a multiple of 4, so every piece decodes on its own
		local k = 0
		for i = 1, #text, PIECE do
			k += 1
			local sv = Instance.new("StringValue"); sv.Name = tostring(k); sv.Value = string.sub(text, i, i + PIECE - 1); sv.Parent = v
		end
		v:SetAttribute("Cell", CELL); v:SetAttribute("Half", HALF); v:SetAttribute("Offset", OFF); v:SetAttribute("N", NX); v:SetAttribute("Pieces", k)
		v:SetAttribute("Baked", os.date("!%Y-%m-%d %H:%M UTC"))
		v.Parent = SS
		return #text
	end
	local a, b = save("MB_GridFloor", fl), save("MB_GridTop", tp)
	return string.format("baked %d x %d cells in %.1f s; %d soft props; floor %d chars, top %d chars", NX, NX, os.clock() - t0, n, a, b)
end
