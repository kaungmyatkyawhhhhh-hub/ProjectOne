--[[
	CasinoGround (Studio, Edit mode; 2026-11-04, owner: "the casino looks like is dug down and the terrain
	doesnt match"). The casino's plate sat in a pit: SitePads cut a 33-stud rock face behind it and 15-30
	studs along its sides, into a hill that rises at 18%. This regrades the ground round the casino and
	its two side car parks (RewardsPalace):

	  * the flat: the plate and the two courts (`FLAT`, in the building's frame)
	  * from the flat's edge a long grass bank at `SLOPE` rises until it meets the old hill, with a soft
	    crease where it does. Near the flat (out to NEAR) the ground follows the bank exactly, which fills
	    the trench SitePads left round the plate; further out the ground is only ever lowered
	  * columns with a road, kerb or pavement (and 4 studs round them), buildings, other plates and the
	    sea are left alone

	CasinoGround.backup() -> stores the region in ServerStorage.CasinoGroundBackup (a TerrainRegion)
	CasinoGround.restore() -> puts it back
	CasinoGround.tiles() -> the 256-stud tiles to do, one run call each (a run stays short)
	CasinoGround.run(tile) -> columns changed
]]

local CasinoGround = {}

local C = 4 -- terrain voxel
local PLATE_TOP = 72.9 -- Riviera.Sites.casino's top
local SINK = 4.4 -- the ground under the flat
local EDGE = PLATE_TOP - 0.4 -- the ground at the flat's edge
local SLOPE = 0.3 -- the bank (the hill itself is about 0.18)
local NEAR, BLEND = 34, 34 -- the bank is exact out to NEAR, free to stay lower by NEAR + BLEND
local REACH = 300 -- how far out a column can change
local CREASE = 14 -- how soft the line is where the bank meets the hill

-- the building's frame: x across the front, -z towards the street (WestLayout.site("rewards"))
local BASE = CFrame.new(14378.5, 72.9, 31.2, -0.991009355, 0, 0.133792743, 0, 1, 0, -0.133792743, 0, -0.991009355)

-- (x0, x1, z0, z1) in that frame
local FLAT = {
	{ -116, 116, -110, 116 }, -- the plate
	{ -150, 150, -104, 44 }, -- the two courts
}

-- the front band beside the street stays as it is: only behind this line does the ground change
local FRONT_Z = -105

local ROADISH = {
	Road = true,
	Kerb = true,
	Pavement = true,
	Shoulder = true,
	LegWall = true,
	TurningCircle = true,
	Wall = true,
	WallCap = true,
	DriveSlab = true,
}

local function outside(x: number, z: number): number
	local best = math.huge
	for _, r in FLAT do
		local dx = math.max(r[1] - x, x - r[2], 0)
		local dz = math.max(r[3] - z, z - r[4], 0)
		best = math.min(best, math.sqrt(dx * dx + dz * dz))
	end
	return best
end

local function smin(a: number, b: number, k: number): number
	local h = math.max(k - math.abs(a - b), 0) / k
	return math.min(a, b) - h * h * k / 4
end

local function smooth(t: number): number
	t = math.clamp(t, 0, 1)
	return t * t * (3 - 2 * t)
end

local function worldBox(): (Vector3, Vector3)
	local x0, x1, z0, z1 = math.huge, -math.huge, math.huge, -math.huge
	for _, u in { -150 - REACH, 150 + REACH } do
		for _, v in { FRONT_Z, 116 + REACH } do
			local w = BASE:PointToWorldSpace(Vector3.new(u, 0, v))
			x0, x1 = math.min(x0, w.X), math.max(x1, w.X)
			z0, z1 = math.min(z0, w.Z), math.max(z1, w.Z)
		end
	end
	return Vector3.new(x0, 0, z0), Vector3.new(x1, 0, z1)
end

function CasinoGround.tiles(): { Vector2 }
	local a, b = worldBox()
	local out = {}
	for x = math.floor(a.X / 256), math.floor(b.X / 256) do
		for z = math.floor(a.Z / 256), math.floor(b.Z / 256) do
			table.insert(out, Vector2.new(x, z))
		end
	end
	return out
end

local function backupRegion(): Region3int16
	local a, b = worldBox()
	local lo = Vector3int16.new(math.floor(a.X / C), 8, math.floor(a.Z / C))
	local hi = Vector3int16.new(math.ceil(b.X / C), 80, math.ceil(b.Z / C))
	return Region3int16.new(lo, hi)
end

function CasinoGround.backup(): string
	local ss = game:GetService("ServerStorage")
	local old = ss:FindFirstChild("CasinoGroundBackup")
	if old then
		return "backup already there"
	end
	local copy = workspace.Terrain:CopyRegion(backupRegion())
	copy.Name = "CasinoGroundBackup"
	copy.Parent = ss
	return "backup stored"
end

function CasinoGround.restore(): string
	local ss = game:GetService("ServerStorage")
	local copy = ss:FindFirstChild("CasinoGroundBackup")
	if not copy then
		return "no backup"
	end
	local r = backupRegion()
	workspace.Terrain:PasteRegion(copy, r.Min, true)
	return "restored"
end

function CasinoGround.run(tile: Vector2): number
	local T = workspace.Terrain
	local x0, z0 = tile.X * 256, tile.Y * 256
	local x1, z1 = x0 + 256, z0 + 256
	local nx, nz = 64, 64
	local y0, y1 = 32, 320
	local want, near = {}, {}
	local any = false
	for i = 1, nx do
		want[i], near[i] = {}, {}
		local px = x0 + (i - 0.5) * C
		for k = 1, nz do
			local pz = z0 + (k - 0.5) * C
			local q = BASE:PointToObjectSpace(Vector3.new(px, PLATE_TOP, pz))
			if q.Z >= FRONT_Z then
				local d = outside(q.X, q.Z)
				if d <= REACH then
					want[i][k] = d
					any = true
				end
			end
		end
	end
	if not any then
		return 0
	end

	-- what must stay as it is
	local keep = {}
	local road = {}
	for i = 1, nx do
		keep[i], road[i] = {}, {}
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { T, workspace.Riviera.Sites.casino }
	params.RespectCanCollide = false
	for i = 1, nx do
		local px = x0 + (i - 0.5) * C
		for k = 1, nz do
			if want[i][k] then
				local pz = z0 + (k - 0.5) * C
				local hit = workspace:Raycast(Vector3.new(px, y1 + 80, pz), Vector3.new(0, -(y1 + 80 - y0), 0), params)
				if hit then
					local inst = hit.Instance
					if ROADISH[inst.Name] then
						road[i][k] = true
					elseif inst:IsDescendantOf(workspace.Riviera.Sites) or inst.Size.Magnitude > 30 then
						keep[i][k] = true
					end
				end
			end
		end
		if i % 20 == 0 then
			task.wait()
		end
	end
	for i = 1, nx do
		for k = 1, nz do
			if road[i][k] then
				for a = math.max(i - 1, 1), math.min(i + 1, nx) do
					for b = math.max(k - 1, 1), math.min(k + 1, nz) do
						keep[a][b] = true
					end
				end
			end
		end
	end

	local region = Region3.new(Vector3.new(x0, y0, z0), Vector3.new(x1, y1, z1))
	local mats, occs = T:ReadVoxels(region, C)
	local ny = #mats[1]
	local changed = 0
	for i = 1, nx do
		local mx, ox = mats[i], occs[i]
		local px = x0 + (i - 0.5) * C
		for k = 1, nz do
			local d = want[i][k]
			if d and not keep[i][k] then
				local pz = z0 + (k - 0.5) * C
				local cur: number? = nil
				for iy = ny, 1, -1 do
					local m = mx[iy][k]
					if ox[iy][k] > 0.01 and m ~= Enum.Material.Air and m ~= Enum.Material.Water then
						cur = y0 + (iy - 1) * C + ox[iy][k] * C
						break
					end
				end
				if cur then
					local target: number
					if d <= 0 then
						target = PLATE_TOP - SINK
					else
						local bank = EDGE + d * SLOPE
						local free = smin(cur, bank, CREASE)
						target = bank + (free - bank) * smooth((d - NEAR) / BLEND)
					end
					if math.abs(target - cur) > 0.2 then
						-- lawn near the casino, the hill's own grass and earth further out
						local lush = smooth((d - 60) / 140)
						local earthy = math.noise(px / 38, pz / 38, 7.3) > 0.32 - lush * 0.3
						local skin = if d > 60 and earthy then Enum.Material.Ground else Enum.Material.Grass
						-- the column, from the air down to under whichever is lower, the old or the new ground
						local low = math.min(cur, target) - 2 * C
						for iy = ny, 1, -1 do
							local yb = y0 + (iy - 1) * C
							if yb < low then
								break
							end
							if yb >= target then
								mx[iy][k] = Enum.Material.Air
								ox[iy][k] = 0
							else
								ox[iy][k] = math.min((target - yb) / C, 1)
								mx[iy][k] = if yb >= target - 8 then skin else Enum.Material.Ground
							end
						end
						changed += 1
					end
				end
			end
		end
	end
	T:WriteVoxels(region, C, mats, occs)
	return changed
end

return CasinoGround
