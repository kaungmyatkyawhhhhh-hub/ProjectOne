-- MEGA BITE WorldGen v2 (13 Nov): ONE natural seabed for the whole map (owner: "make the map landscape like realistic terrain
-- because rn the spawn area is high and the other areas are sunk in ... an open world that people can explore but it gets
-- harder the further they get").
--   reef plate (r < 384, the hand-shaped reef, unchanged) -> fore-reef slope -> rolling Open Sea that deepens with distance
--   (4 biomes by bearing: N kelp hills, E sandstone terraces, S pale dune plain, W dark ridges) -> the Red Trench (deep
--   basalt ring) -> the outer wall.
-- Use (Edit mode):  local G = require(game.ServerStorage.MB_WorldGen:Clone());  G.write(x0, x1)   -- columns x0..x1 (studs)
--                   G.height(x, z) -> y, material     G.colours()
local TER = workspace.Terrain
local C = require(game.ReplicatedStorage.MegaBite.GameConfig:Clone())
local WD = C.World
local H = game:GetService("HttpService"):JSONDecode(game.ServerStorage.MB_PlateHeights.Value)   -- the reef plate surface, 8-stud grid
local function hp(ix, iz) return H[ix .. "," .. iz] end
local function bil(x, z)
	local fx, fz = x / 8, z / 8; local x0, z0 = math.floor(fx), math.floor(fz); local tx, tz = fx - x0, fz - z0
	local a, b, c, d = hp(x0, z0), hp(x0 + 1, z0), hp(x0, z0 + 1), hp(x0 + 1, z0 + 1)
	if not (a and b and c and d) then return a or b or c or d end
	return (a * (1 - tx) + b * tx) * (1 - tz) + (c * (1 - tx) + d * tx) * tz
end
local function ss(t) t = math.clamp(t, 0, 1); return t * t * (3 - 2 * t) end
local N = math.noise
local M = Enum.Material
local max, min, abs, clamp, floor, sqrt = math.max, math.min, math.abs, math.clamp, math.floor, math.sqrt

local PLATE = 384            -- inside this radius the reef plate is kept as it is
local SEA_OUT = WD.SeaOut    -- the Open Sea ends, the trench cliff begins
local T_IN, T_OUT = WD.TrenchIn, WD.TrenchOut   -- the trench floor ring
local WALL = WD.WallTop      -- the outer wall reaches the surface here
local T_FLOOR = WD.TrenchFloorY

-- the Open Sea floor (no landmark pads, no trench): returns height + the biome weights + helper noises
local function openSea(x, z, R)
	local ux, uz = x / R, z / R
	local wE, wW, wS, wN = max(0, ux) ^ 2, max(0, -ux) ^ 2, max(0, uz) ^ 2, max(0, -uz) ^ 2   -- sum = 1
	local t = clamp((R - 400) / (SEA_OUT - 400), 0, 1.25)
	local base = 12 - 100 * t ^ 0.75                         -- +12 at the reef rim .. -88 at the trench cliff
	local env = ss((R - PLATE) / 140)                         -- the relief grows away from the reef
	local n1 = N(x / 310 + 11.3, z / 310 - 4.2, 0.37)         -- long swells
	local n2 = N(x / 120 - 3.1, z / 120 + 8.8, 5.11)          -- hills
	local n3 = N(x / 45 + 2.2, z / 45 + 1.7, 9.4)             -- mounds
	local n4 = N(x / 17, z / 17, 2.2)                         -- small bumps
	local rd = clamp(1 - abs(N(x / 170 + 40, z / 170 - 13, 3.3)) * 2.2, 0, 1) ^ 3   -- thin ridges
	local A1 = 30 * wN + 22 * wE + 12 * wS + 28 * wW
	local A2 = 16 * wN + 11 * wE + 5 * wS + 16 * wW
	local A3 = 5 * wN + 4 * wE + 2 * wS + 7 * wW
	local AR = 8 * wN + 12 * wE + 0 * wS + 34 * wW
	local off = 3 * wN - 4 * wE + 0 * wS - 8 * wW
	local h = base + off * env + (n1 * A1 + n2 * A2 + n3 * A3 + n4 * 1.2 + rd * AR) * env
	-- S: long dunes on the pale plain
	h += wS * env * 2.4 * math.sin((x * 0.8 + z * 0.6) / 21 + n2 * 3)
	-- E: stepped terraces (the sunken kingdom was built on steps)
	local st = 7
	local q = floor(h / st + 0.5) * st
	local e = (h - q) / st                                    -- -0.5 .. 0.5 inside a step
	local stepped = q + st * 0.5 * (e > 0 and 1 or -1) * (abs(e) * 2) ^ 5   -- flat tread, short riser
	h += (stepped - h) * 0.7 * wE * env
	-- winding channels (valleys with flat floors: natural swim roads between the biomes)
	local cn = abs(N(x / 430 + 7.7, z / 430 + 3.1, 8.8))
	local ch = (1 - ss(cn / 0.075)) * env
	h -= 16 * ch
	return h, wN, wE, wS, wW, ch, n2, n3, rd, env
end

-- landmark sites: a level pad around each landmark (and its treasure chest) so the models sit on real ground
local sites = {}
for _, L in ipairs(WD.Landmarks) do
	local x, z = L.pos.X, L.pos.Z
	local R = sqrt(x * x + z * z)
	local c = openSea(x, z, R)
	table.insert(sites, {x = x, z = z, r0 = L.pad or 90, r1 = (L.pad or 90) + (L.blend or 110), y = c + (L.lift or 0)})
end

local function height(x, z)
	local R = sqrt(x * x + z * z)
	if R <= PLATE then return bil(x, z) or 10, M.Sand, 0 end
	local dith = (N(x / 7, z / 7, 3.3) + N(x / 3.1, z / 3.1, 9.7) * 0.6) * 0.6 + 0.5   -- ~0..1 fine dither for soft material blends
	local h, wN, wE, wS, wW, ch, n2, n3, rd, env = openSea(x, z, max(R, 1))
	-- landmark pads
	for _, s in ipairs(sites) do
		local dx, dz = x - s.x, z - s.z
		local d2 = dx * dx + dz * dz
		if d2 < s.r1 * s.r1 then
			local w = 1 - ss((sqrt(d2) - s.r0) / (s.r1 - s.r0))
			h += (s.y - h) * w
		end
	end
	-- seam with the reef plate
	if R < PLATE + 44 then
		local k = PLATE - 1
		local rim = bil(x / R * k, z / R * k) or 12
		local t = ss((R - PLATE) / 44)
		h = rim + (h - rim) * t
	end
	-- material by biome
	local mat = M.Sand
	local far = ss((R - 430) / 170)                       -- the reef's pale sand runs out into the shallows
	if dith < far then
		-- pick the biome ground by weight (dithered so borders are soft)
		local r = (N(x / 23 + 5, z / 23 - 9, 6.6) * 0.5 + 0.5) * 0.5 + dith * 0.5
		local a = wN
		if r < a then mat = (n2 > 0.08 and n3 > -0.25) and M.Grass or M.Mud            -- N: seagrass meadows on the hills, dark mud between
		elseif r < a + wE then mat = M.Sandstone                                         -- E: warm sandstone
		elseif r < a + wE + wS then mat = (n3 > 0.3 and dith > 0.55) and M.Salt or M.Limestone   -- S: pale bone-white plain
		else mat = (rd > 0.25) and M.Rock or M.Slate end                                 -- W: dark slate, rock ridges
	end
	if ch > 0.55 and dith < ch then mat = M.Ground end      -- channel floors: violet mud
	-- THE RED TRENCH: the cliff line wobbles so the edge is never a perfect circle
	local wob = N(x / 210 + 3.3, z / 210 - 7.7, 4.4) * 46
	local Rc = R + wob
	if Rc > SEA_OUT then
		local n1 = N(x / 300 - 9.1, z / 300 + 2.2, 7.3)
		local F = T_FLOOR + n1 * 9 + n3 * 3 + clamp(1 - abs(N(x / 150 - 20, z / 150 + 31, 1.7)) * 2.4, 0, 1) ^ 3 * 20   -- floor + basalt spines
		if Rc <= T_OUT then
			local s = ss((Rc - SEA_OUT) / (T_IN - SEA_OUT))
			-- one ledge half way down the cliff
			local led = s + 0.10 * math.sin(s * math.pi * 2) * (1 - s)
			local h2 = h + (F - h) * clamp(led, 0, 1)
			local t = clamp((h - h2) / max(h - F, 1), 0, 1)     -- 0 at the lip .. 1 on the trench floor
			h = h2
			if t > 0.06 then
				if t < 0.4 then mat = (dith < (t - 0.06) / 0.34) and M.Ground or mat
				elseif t < 0.85 then mat = (dith < (t - 0.4) / 0.45) and M.Basalt or M.Ground
				else mat = M.Basalt end
				if t > 0.9 and n2 > 0.32 and dith > 0.35 then mat = M.CrackedLava end   -- glowing cracks on the deep floor
			end
		else
			local s = ss((Rc - T_OUT) / (WALL - T_OUT))
			h = F + (WD.WallY - F) * s + N(x / 90, z / 90, 1.3) * 10 * s
			mat = (dith < ss((h - (F + 10)) / 40)) and M.Rock or M.Basalt
		end
	end
	return h, mat, env
end

local G = {}
G.height = height
function G.colours()
	TER:SetMaterialColor(M.Sand, Color3.fromRGB(150, 190, 214))
	TER:SetMaterialColor(M.Ground, Color3.fromRGB(116, 104, 140))
	TER:SetMaterialColor(M.Basalt, Color3.fromRGB(92, 32, 46))
	TER:SetMaterialColor(M.Rock, Color3.fromRGB(70, 46, 66))
	TER:SetMaterialColor(M.CrackedLava, Color3.fromRGB(255, 62, 62))
	TER:SetMaterialColor(M.Sandstone, Color3.fromRGB(214, 172, 136))
	TER:SetMaterialColor(M.Limestone, Color3.fromRGB(206, 216, 226))
	TER:SetMaterialColor(M.Salt, Color3.fromRGB(238, 242, 250))
	TER:SetMaterialColor(M.Slate, Color3.fromRGB(72, 64, 122))
	TER:SetMaterialColor(M.Mud, Color3.fromRGB(62, 116, 104))
	TER:SetMaterialColor(M.Grass, Color3.fromRGB(64, 156, 118))
end
-- writes the columns x0 <= x < x1 (multiples of 128), all z. Steep faces become rock.
function G.write(xa, xb, zOnly)
	local Y0, NY, RES, CH = WD.TerrainY0, WD.TerrainNY, 4, 32
	local HALF = WD.TerrainHalf
	local n = 0
	for cx = xa, xb - 1, CH * RES do
		for cz = -HALF, HALF - 1, CH * RES do
			-- chunks wholly inside the reef plate are left exactly as they are (the hand-shaped reef)
			local farC = 0
			for _, c in ipairs({{cx, cz}, {cx + CH * RES, cz}, {cx, cz + CH * RES}, {cx + CH * RES, cz + CH * RES}}) do farC = max(farC, sqrt(c[1] ^ 2 + c[2] ^ 2)) end
			if farC >= 380 and (not zOnly or (cz >= zOnly[1] and cz < zOnly[2])) then
				-- heights on a (CH+2)^2 grid (one extra column each side for the slope)
				local hs, ms = {}, {}
				for i = 0, CH + 1 do
					hs[i], ms[i] = {}, {}
					for k = 0, CH + 1 do
						local h, mat = height(cx + (i - 0.5) * RES, cz + (k - 0.5) * RES)
						hs[i][k], ms[i][k] = h, mat
					end
				end
				local mats, occ = {}, {}
				for i = 1, CH do
					mats[i], occ[i] = {}, {}
					for j = 1, NY do mats[i][j], occ[i][j] = {}, {} end
					for k = 1, CH do
						local h, mat = hs[i][k], ms[i][k]
						local x, z = cx + (i - 0.5) * RES, cz + (k - 0.5) * RES
						if x * x + z * z > PLATE * PLATE then
							local sx, sz = (hs[i + 1][k] - hs[i - 1][k]) / (2 * RES), (hs[i][k + 1] - hs[i][k - 1]) / (2 * RES)
							local slope = sqrt(sx * sx + sz * sz)
							if slope > 1.05 and mat ~= M.CrackedLava and mat ~= M.Basalt then mat = M.Rock end
						end
						for j = 1, NY do
							local o = clamp((h - (Y0 + (j - 1) * RES)) / RES, 0, 1)
							occ[i][j][k] = o; mats[i][j][k] = o > 0 and mat or M.Air
						end
					end
				end
				TER:WriteVoxels(Region3.new(Vector3.new(cx, Y0, cz), Vector3.new(cx + CH * RES, Y0 + NY * RES, cz + CH * RES)), RES, mats, occ)
				n += 1
				if n % 2 == 0 then task.wait() end
			end
		end
	end
	return n
end
return G
