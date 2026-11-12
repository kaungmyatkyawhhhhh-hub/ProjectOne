-- MEGA BITE WorldDress (13 Nov): dresses the Open Sea (r 430-1120) with the kit, by biome, in clusters with open sand
-- between them. Deterministic (seeded). Re-run any time: it rebuilds workspace.MB_Map.OpenSea from scratch.
--   N kelp hills: giant kelp forests, sea-palm groves, mossy boulders      E sunken kingdom: sandstone mesas, teal + gold corals
--   S pale plain: bone-white rocks, starfish fields, purple bubble corals  W glow gardens: violet spires, neon corals
-- Use (Edit mode): require(game.ServerStorage.MB_WorldDress:Clone())()  -> part count
local C = require(game.ReplicatedStorage.MegaBite.GameConfig:Clone())
local WD = C.World
local N = math.noise
local map = workspace.MB_Map
local terr = workspace.Terrain
local rpT = RaycastParams.new(); rpT.FilterType = Enum.RaycastFilterType.Include; rpT.FilterDescendantsInstances = {terr}; rpT.IgnoreWater = true
local function floorAt(x, z) local hit = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -700, 0), rpT); return hit and hit.Position.Y, hit and hit.Normal end
local function ss(t) t = math.clamp(t, 0, 1); return t * t * (3 - 2 * t) end
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

return function(seed)
	local rng = Random.new(seed or 20261113)
	local function rnd(a, b) return rng:NextNumber(a, b) end
	local function pick(t) return t[rng:NextInteger(1, #t)] end
	local function jitter(c, k) local h, s, v = c:ToHSV(); return Color3.fromHSV((h + rnd(-0.02, 0.02)) % 1, math.clamp(s + rnd(-k, k), 0, 1), math.clamp(v + rnd(-k, k), 0, 1)) end
	-- templates: one clean copy of every kit mesh
	local tpl = {}
	for _, name in ipairs({"Kelp", "SeaFan", "BrainCoral", "BubbleCoral", "BranchCoral", "TableCoral", "Starfish", "SeaPalm", "Boulder_Round", "Boulder_Flat", "Spire"}) do
		local ref
		for _, d in ipairs(map.Reef:GetDescendants()) do if d:IsA("MeshPart") and d.Name == name then ref = d; break end end
		if not ref then for _, d in ipairs(map:GetDescendants()) do if d:IsA("MeshPart") and d.Name == name and not d:IsDescendantOf(map:FindFirstChild("OpenSea") or game.ServerStorage) then ref = d; break end end end
		local c = ref:Clone()
		for k in pairs(c:GetAttributes()) do c:SetAttribute(k, nil) end
		for _, ch in ipairs(c:GetChildren()) do ch:Destroy() end
		c.Material = Enum.Material.SmoothPlastic
		tpl[name] = c
	end
	local old = map:FindFirstChild("OpenSea"); if old then old:Destroy() end
	local root = Instance.new("Folder"); root.Name = "OpenSea"
	local count, nClusters = 0, 0
	local folder
	local ROCK = {Boulder_Round = true, Boulder_Flat = true, Spire = true}
	-- put one kit piece on the seabed. h = its height in studs. o: col, neon, sink (share of its height under the sand), wide (x/z stretch), yaw, y (explicit floor)
	local function put(name, x, z, h, o)
		o = o or {}
		for _, L in ipairs(WD.Landmarks) do   -- nothing on top of a treasure chest (or in the way to it)
			if L.chest then
				local t = tpl[name]
				local half = math.max(t.MeshSize.X, t.MeshSize.Z) * (h / t.MeshSize.Y) * 0.5
				if (x - L.chest.X) ^ 2 + (z - L.chest.Z) ^ 2 < (13 + half) ^ 2 then return end
			end
		end
		local fy = o.y or floorAt(x, z)
		if not fy then return end
		local t = tpl[name]
		local p = t:Clone()
		local s = h / t.MeshSize.Y
		local w = o.wide or 1
		p.Size = Vector3.new(t.MeshSize.X * s * w, h, t.MeshSize.Z * s * w)
		p.CFrame = CFrame.new(x, fy + h * (0.5 - (o.sink or 0.1)), z) * CFrame.Angles(0, o.yaw or rnd(0, math.pi * 2), 0)
		if o.col then
			-- the kit's textures are opaque (a textured fan is always blue, a brain coral always green): plain faces take the
			-- biome colour. About a third of the corals keep the painted texture so the old look is still part of the mix.
			if ROCK[name] or name == "SeaPalm" or not (o.keep and rng:NextNumber() < 0.3) then p.TextureID = "" end
			p.Color = o.col
		end
		if o.neon then p.Material = Enum.Material.Neon end
		p.Anchored = true
		local solid = ROCK[name] == true
		p.CanCollide = solid; p.CanQuery = solid; p.CanTouch = false
		p.CastShadow = solid
		p.Parent = folder
		count += 1
		return p
	end
	-- biome looks
	local B = {
		N = {rock = {rgb(104, 150, 120), rgb(90, 132, 110), rgb(120, 160, 128)},
			coral = {rgb(255, 214, 90), rgb(160, 230, 96), rgb(255, 150, 80), rgb(110, 214, 160), rgb(255, 120, 150)},
			kelp = {rgb(72, 176, 104), rgb(96, 196, 84), rgb(60, 150, 110), rgb(120, 200, 90)}, fan = {rgb(255, 170, 70), rgb(240, 110, 90), rgb(120, 220, 150)}},
		E = {rock = {rgb(255, 196, 132), rgb(240, 178, 120), rgb(255, 210, 150)},
			coral = {rgb(60, 214, 200), rgb(255, 206, 80), rgb(40, 180, 190), rgb(255, 170, 60), rgb(120, 236, 214)},
			kelp = {rgb(60, 170, 150), rgb(80, 190, 140)}, fan = {rgb(255, 200, 70), rgb(70, 210, 200), rgb(255, 140, 90)}},
		S = {rock = {rgb(240, 238, 232), rgb(224, 226, 232), rgb(250, 246, 240)},
			coral = {rgb(190, 130, 255), rgb(255, 170, 220), rgb(236, 236, 250), rgb(150, 120, 240), rgb(255, 200, 230)},
			kelp = {rgb(150, 190, 200), rgb(170, 160, 220)}, fan = {rgb(200, 150, 255), rgb(255, 180, 220), rgb(240, 240, 255)}},
		W = {rock = {rgb(92, 72, 170), rgb(76, 60, 150), rgb(110, 84, 190)},
			coral = {rgb(70, 240, 230), rgb(190, 100, 255), rgb(255, 90, 200), rgb(90, 160, 255), rgb(120, 255, 210)},
			kelp = {rgb(130, 90, 240), rgb(70, 220, 220), rgb(170, 100, 255)}, fan = {rgb(90, 240, 230), rgb(210, 110, 255), rgb(255, 100, 190)}},
	}
	local CORALS = {{"BrainCoral", 5, 9}, {"BubbleCoral", 7, 12}, {"BranchCoral", 8, 13}, {"TableCoral", 6, 9}}
	local function coralAt(b, x, z, k, glow)
		local c = pick(CORALS)
		put(c[1], x, z, rnd(c[2], c[3]) * k, {col = jitter(pick(B[b].coral), 0.06), neon = glow and rng:NextNumber() < 0.55})
	end
	local function ring(cx, cz, r0, r1) local a, r = rnd(0, math.pi * 2), rnd(r0, r1); return cx + math.cos(a) * r, cz + math.sin(a) * r end
	-- recipes -------------------------------------------------------------------------------------------------
	local R = {}
	function R.garden(b, cx, cz, k, glow)
		local flat = rng:NextNumber() < 0.4
		local rh = flat and rnd(12, 20) * k or rnd(18, 32) * k
		local rock = put(flat and "Boulder_Flat" or "Boulder_Round", cx, cz, rh, {col = jitter(pick(B[b].rock), 0.04), sink = 0.28})
		local rr = rock and math.max(rock.Size.X, rock.Size.Z) * 0.5 or 14
		for _ = 1, rng:NextInteger(4, 6) do local x, z = ring(cx, cz, rr * 0.75, rr + 9); coralAt(b, x, z, k, glow) end
		for _ = 1, rng:NextInteger(2, 4) do local x, z = ring(cx, cz, rr * 0.8, rr + 12); put("SeaFan", x, z, rnd(10, 18) * k, {col = jitter(pick(B[b].fan), 0.06), neon = glow and rng:NextNumber() < 0.4}) end
		for _ = 1, rng:NextInteger(1, 3) do local x, z = ring(cx, cz, rr + 2, rr + 14); put("Kelp", x, z, rnd(14, 28) * k, {col = jitter(pick(B[b].kelp), 0.06), neon = glow and rng:NextNumber() < 0.3}) end
		for _ = 1, rng:NextInteger(0, 2) do local x, z = ring(cx, cz, rr + 4, rr + 18); put("Starfish", x, z, rnd(0.9, 1.4), {sink = 0.05}) end
	end
	function R.rocks(b, cx, cz, k, glow)
		local n = rng:NextInteger(2, 4)
		local a0 = rnd(0, math.pi * 2)
		for i = 1, n do
			local a = a0 + i * (math.pi * 2 / n) + rnd(-0.5, 0.5)
			local d = i == 1 and 0 or rnd(22, 44) * k
			local name = rng:NextNumber() < 0.65 and "Boulder_Round" or "Boulder_Flat"
			put(name, cx + math.cos(a) * d, cz + math.sin(a) * d, (name == "Boulder_Round" and rnd(34, 78) or rnd(20, 38)) * k * (i == 1 and 1.15 or 0.8), {col = jitter(pick(B[b].rock), 0.04), sink = 0.3})
		end
		if rng:NextNumber() < 0.45 then local x, z = ring(cx, cz, 10, 30); put("Spire", x, z, rnd(70, 130) * k, {col = jitter(pick(B[b].rock), 0.04), sink = 0.2}) end
		for _ = 1, rng:NextInteger(3, 5) do local x, z = ring(cx, cz, 30 * k, 52 * k); if rng:NextNumber() < 0.5 then coralAt(b, x, z, k, glow) else put("SeaFan", x, z, rnd(11, 19) * k, {col = jitter(pick(B[b].fan), 0.06), neon = glow and rng:NextNumber() < 0.4}) end end
	end
	function R.kelpForest(b, cx, cz, k)
		local rad = rnd(34, 54)
		for _ = 1, rng:NextInteger(22, 32) do
			local a, r = rnd(0, math.pi * 2), rad * math.sqrt(rng:NextNumber())
			local x, z = cx + math.cos(a) * r, cz + math.sin(a) * r
			local fy = floorAt(x, z)
			if fy then
				local h = math.min(rnd(30, 78) * (1 - 0.45 * r / rad), C.Swim.Ceiling - 8 - fy)
				put("Kelp", x, z, h, {col = jitter(pick(B[b].kelp), 0.07), y = fy, wide = rnd(0.55, 0.8)})
			end
		end
		for _ = 1, 2 do local x, z = ring(cx, cz, 8, rad * 0.8); put("Boulder_Round", x, z, rnd(14, 26), {col = jitter(pick(B[b].rock), 0.04), sink = 0.3}) end
		for _ = 1, 3 do local x, z = ring(cx, cz, 6, rad); coralAt(b, x, z, 1, false) end
	end
	function R.palms(b, cx, cz, k)
		for _ = 1, rng:NextInteger(5, 8) do local x, z = ring(cx, cz, 0, 34); put("SeaPalm", x, z, rnd(18, 34) * k, {sink = 0.06}) end
		for _ = 1, 3 do local x, z = ring(cx, cz, 6, 36); put("Starfish", x, z, rnd(0.9, 1.4), {sink = 0.05}) end
		for _ = 1, 3 do local x, z = ring(cx, cz, 10, 38); coralAt(b, x, z, k, false) end
	end
	function R.mesa(b, cx, cz, k)   -- stacked sandstone slabs
		local yaw = rnd(0, math.pi)
		local fy = floorAt(cx, cz); if not fy then return end
		local y = fy
		local n = rng:NextInteger(2, 3)
		for i = 1, n do
			local h = rnd(20, 34) * k * (1 - (i - 1) * 0.22)
			local p = put("Boulder_Flat", cx + rnd(-8, 8) * (i - 1), cz + rnd(-8, 8) * (i - 1), h, {col = jitter(pick(B[b].rock), 0.04), sink = i == 1 and 0.25 or 0.3, y = y, yaw = yaw + (i - 1) * rnd(0.4, 1.2), wide = 1 - (i - 1) * 0.2})
			if p then y = p.Position.Y + p.Size.Y * 0.32 end
		end
		for _ = 1, rng:NextInteger(3, 5) do local x, z = ring(cx, cz, 34 * k, 60 * k); put("TableCoral", x, z, rnd(6, 10) * k, {col = jitter(pick(B[b].coral), 0.06)}) end
		for _ = 1, rng:NextInteger(2, 4) do local x, z = ring(cx, cz, 30 * k, 58 * k); put("SeaFan", x, z, rnd(11, 19) * k, {col = jitter(pick(B[b].fan), 0.06)}) end
	end
	function R.starfield(b, cx, cz, k)
		for _ = 1, rng:NextInteger(6, 10) do local x, z = ring(cx, cz, 0, 34); put("Starfish", x, z, rnd(0.9, 1.6), {sink = 0.05}) end
		for _ = 1, 3 do local x, z = ring(cx, cz, 4, 26); put("BrainCoral", x, z, rnd(5, 10) * k, {col = jitter(pick(B[b].coral), 0.05)}) end
		for _ = 1, 3 do local x, z = ring(cx, cz, 4, 30); put("BubbleCoral", x, z, rnd(8, 13) * k, {col = jitter(pick(B[b].coral), 0.05)}) end
		put("Boulder_Round", cx, cz, rnd(10, 18) * k, {col = jitter(pick(B[b].rock), 0.03), sink = 0.35})
	end
	function R.spires(b, cx, cz, k)   -- a row of tall dark spires along a ridge
		local a = rnd(0, math.pi)
		local n = rng:NextInteger(3, 5)
		for i = 1, n do
			local d = (i - (n + 1) / 2) * rnd(26, 40)
			local x, z = cx + math.cos(a) * d + rnd(-8, 8), cz + math.sin(a) * d + rnd(-8, 8)
			local fy = floorAt(x, z)
			if fy then put("Spire", x, z, math.min(rnd(80, 170) * k, C.Swim.Ceiling + 6 - fy), {col = jitter(pick(B[b].rock), 0.04), sink = 0.18, y = fy}) end
		end
		for _ = 1, rng:NextInteger(4, 6) do local x, z = ring(cx, cz, 14, 50); coralAt(b, x, z, k, true) end
		for _ = 1, 2 do local x, z = ring(cx, cz, 14, 46); put("Kelp", x, z, rnd(20, 40) * k, {col = jitter(pick(B[b].kelp), 0.06), neon = true}) end
	end
	local MIX = {
		N = {{"kelpForest", 0.32}, {"garden", 0.3}, {"rocks", 0.2}, {"palms", 0.18}},
		E = {{"mesa", 0.34}, {"garden", 0.36}, {"rocks", 0.2}, {"palms", 0.1}},
		S = {{"starfield", 0.36}, {"garden", 0.34}, {"rocks", 0.3}},
		W = {{"spires", 0.42}, {"garden", 0.4}, {"rocks", 0.18}},
	}
	-- where things may go
	local function info(x, z)
		local Rr = math.sqrt(x * x + z * z)
		local ux, uz = x / Rr, z / Rr
		local w = {E = math.max(0, ux) ^ 2, W = math.max(0, -ux) ^ 2, S = math.max(0, uz) ^ 2, N = math.max(0, -uz) ^ 2}
		local env = ss((Rr - 384) / 140)
		local ch = (1 - ss(math.abs(N(x / 430 + 7.7, z / 430 + 3.1, 8.8)) / 0.075)) * env
		local wob = N(x / 210 + 3.3, z / 210 - 7.7, 4.4) * 46
		return Rr, w, ch, Rr + wob
	end
	local function biomeAt(w)
		local r = rng:NextNumber()
		for _, b in ipairs({"N", "E", "S", "W"}) do r -= w[b]; if r <= 0 then return b end end
		return "W"
	end
	local function nearLandmark(x, z, extra)
		for _, L in ipairs(WD.Landmarks) do
			local d = math.sqrt((x - L.pos.X) ^ 2 + (z - L.pos.Z) ^ 2)
			if d < (L.pad or 90) + extra then return true end
		end
		return false
	end
	-- the clusters: one try per 105-stud cell, jittered; channels and some cells stay open sand
	local CELL = 105
	for gx = -11, 11 do
		for gz = -11, 11 do
			local x, z = gx * CELL + rnd(-36, 36), gz * CELL + rnd(-36, 36)
			local Rr, w, ch, Rc = info(x, z)
			if Rr > 440 and Rc < WD.SeaOut - 30 and ch < 0.4 and not nearLandmark(x, z, 55) and rng:NextNumber() > 0.2 then
				local b = biomeAt(w)
				local r, kind = rng:NextNumber(), nil
				for _, e in ipairs(MIX[b]) do r -= e[2]; if r <= 0 then kind = e[1]; break end end
				kind = kind or MIX[b][1][1]
				local _, ti = C.TierAt(Vector3.new(x, 0, z))
				local k = 1 + 0.16 * math.clamp((Rr - 510) / 210, 0, 3)   -- things get bigger further out
				nClusters += 1
				folder = Instance.new("Folder"); folder.Name = kind .. "_" .. b .. nClusters; folder:SetAttribute("Biome", b)
				R[kind](b, x, z, k, b == "W")
				folder.Parent = root
				if nClusters % 6 == 0 then task.wait() end
			end
		end
	end
	-- singles between the clusters (so no view is empty)
	folder = Instance.new("Folder"); folder.Name = "Singles"
	for i = 1, 520 do
		local a, Rr = rnd(0, math.pi * 2), math.sqrt(rnd(440 ^ 2, 1110 ^ 2))
		local x, z = math.cos(a) * Rr, math.sin(a) * Rr
		local _, w, ch, Rc = info(x, z)
		if Rc < WD.SeaOut - 30 and not nearLandmark(x, z, 20) then
			local b = biomeAt(w)
			local r = rng:NextNumber()
			if ch > 0.5 then put("Starfish", x, z, rnd(0.9, 1.5), {sink = 0.05})
			elseif r < 0.4 then coralAt(b, x, z, rnd(0.9, 1.5), b == "W")
			elseif r < 0.65 then put("SeaFan", x, z, rnd(10, 20), {col = jitter(pick(B[b].fan), 0.06), neon = b == "W" and rng:NextNumber() < 0.4})
			elseif r < 0.85 then put("Kelp", x, z, rnd(14, 34), {col = jitter(pick(B[b].kelp), 0.06), neon = b == "W" and rng:NextNumber() < 0.3})
			else put("Boulder_Round", x, z, rnd(8, 18), {col = jitter(pick(B[b].rock), 0.04), sink = 0.35}) end
		end
		if i % 120 == 0 then task.wait() end
	end
	folder.Parent = root
	-- around the landmarks
	folder = Instance.new("Folder"); folder.Name = "LandmarkDressing"
	for _, L in ipairs(WD.Landmarks) do
		local b = L.biome
		local toReef = math.atan2(-L.pos.Z, -L.pos.X)
		for i = 1, 46 do
			local a = rnd(0, math.pi * 2)
			local open = math.abs(((a - toReef + math.pi) % (math.pi * 2)) - math.pi) < 0.5   -- the side that faces the reef stays open (the way in)
			if not open then
				local r = (L.pad or 90) * rnd(0.85, 1.0) + rnd(0, (L.blend or 100) * 0.7)
				local x, z = L.pos.X + math.cos(a) * r, L.pos.Z + math.sin(a) * r
				local q = rng:NextNumber()
				if b == "N" then
					if q < 0.6 then local fy = floorAt(x, z); if fy then put("Kelp", x, z, math.min(rnd(34, 74), C.Swim.Ceiling - 8 - fy), {col = jitter(pick(B.N.kelp), 0.07), y = fy, wide = rnd(0.55, 0.8)}) end
					elseif q < 0.75 then put("Boulder_Round", x, z, rnd(14, 30), {col = jitter(pick(B.N.rock), 0.04), sink = 0.3})
					else coralAt("N", x, z, 1.3, false) end
				elseif b == "E" then
					if q < 0.3 then put("Boulder_Flat", x, z, rnd(12, 24), {col = jitter(pick(B.E.rock), 0.04), sink = 0.3})
					elseif q < 0.6 then put("TableCoral", x, z, rnd(7, 12), {col = jitter(pick(B.E.coral), 0.06)})
					elseif q < 0.8 then put("SeaFan", x, z, rnd(12, 22), {col = jitter(pick(B.E.fan), 0.06)})
					else coralAt("E", x, z, 1.4, false) end
				elseif b == "S" then
					if q < 0.4 then put("Starfish", x, z, rnd(1, 1.8), {sink = 0.05})
					elseif q < 0.7 then put("BubbleCoral", x, z, rnd(9, 15), {col = jitter(pick(B.S.coral), 0.05)})
					else put("Boulder_Round", x, z, rnd(10, 22), {col = jitter(pick(B.S.rock), 0.03), sink = 0.35}) end
				else
					if q < 0.25 then local fy = floorAt(x, z); if fy then put("Spire", x, z, math.min(rnd(60, 120), C.Swim.Ceiling + 6 - fy), {col = jitter(pick(B.W.rock), 0.04), sink = 0.18, y = fy}) end
					elseif q < 0.7 then coralAt("W", x, z, 1.4, true)
					else put("Kelp", x, z, rnd(20, 40), {col = jitter(pick(B.W.kelp), 0.06), neon = true}) end
				end
			end
		end
		task.wait()
	end
	folder.Parent = root
	root.Parent = map
	return count, nClusters
end
