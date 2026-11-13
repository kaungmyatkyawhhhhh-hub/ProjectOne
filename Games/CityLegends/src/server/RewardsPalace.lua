--[[
	RewardsPalace (server)
	The look of Legends Rewards (the casino building), owner, 2026-11-04: "make the casino looks million
	times better", "add a exclusive parking infront of the casino with beautiful scenery", "remodel the
	interior", "player actually spawn at the garden of the casino". It stays a rewards hall: scenery
	only, no gambling. Rewards.lua builds the rooms and desks and calls these:

	  * RewardsPalace.square: the casino square. From the street in: an oval garden with a low black
	    railing (mirror ball fountain, flower beds, palms), the exclusive parking (10 marked bays at
	    the garden's kerb, for players' own cars: owner, 2026-11-04: no parked cars here), the drive in
	    front of the steps, two arms round the garden to the street (EntranceRamp stops at the road's
	    edge), hedges, flags. Beside the palace two side courts (owner, 2026-11-04: "expand the area
	    ... for atleast 35 cars", "use the realistic palm tree"): 21 more bays each side, 52 in all,
	    planted islands with the map's real palms, lanterns, hedges. Reached from the drive before the
	    steps. tools/riviera/CasinoGround.luau grades the ground round them.
	    Tags: CasinoGardenSpawn (players start here on foot), CasinoCarStart (a first car).
	  * RewardsPalace.roof: the hipped slate roof over the hall, its dormers, the twin towers, the clock.
	  * RewardsPalace.hall: the blue stained-glass oval dome (art: tools/casino_art.py), gold mouldings,
	    rose marble columns, painted lunettes and landscapes, a marble medallion on the floor.
]]

local CollectionService = game:GetService("CollectionService")

local Garden = require(script.Parent:WaitForChild("Garden"))
local EntranceRamp = require(script.Parent:WaitForChild("EntranceRamp"))

local RewardsPalace = {}

-- (tools/casino_art.py, uploaded with the Studio MCP)
local ART = {
	dome = "rbxassetid://92771270926165",
	lunette = "rbxassetid://92369121799433",
	garden = "rbxassetid://72223064780191",
	harbour = "rbxassetid://107051221302045",
}

local TAU = math.pi * 2
local PAVING = Color3.fromRGB(214, 206, 192)
local PAVING_PALE = Color3.fromRGB(232, 226, 214)
local SETT = Color3.fromRGB(128, 122, 114)
local LAWN = Color3.fromRGB(86, 138, 62)
local HEDGE = Color3.fromRGB(44, 88, 44)
local IRON = Color3.fromRGB(20, 20, 22)
local GOLD = Color3.fromRGB(226, 180, 78)
local MARBLE = Color3.fromRGB(236, 232, 224)
local ROSE = Color3.fromRGB(164, 104, 92)
local CREAM = Color3.fromRGB(226, 204, 164) -- warm: the hall's strong light turns anything paler white
local STONE = Color3.fromRGB(242, 228, 198)
local STONE_DARK = Color3.fromRGB(216, 194, 154)
local SLATE = Color3.fromRGB(66, 82, 92)
local COPPER = Color3.fromRGB(88, 146, 124)
local NAVY = Color3.fromRGB(26, 46, 92)
local WARM = Color3.fromRGB(255, 214, 160)

-- the square, in the building's frame (-z is the street)
local GARDEN_Z, GARDEN_A, GARDEN_B = -89, 58, 14.5 -- the oval
local BAY_Z0, BAY_Z1 = -76, -62 -- the parking row
local AISLE_Z0, AISLE_Z1 = -62, -48 -- the drive in front of the steps
local ARM_X0, ARM_X1 = 62, 84 -- the drives round the garden's ends
local RAMP_Z = -98 -- where the ramps from the street end
local BAY_W, BAY_START = 10.5, 8 -- 5 bays each side of the path to the steps
-- the side courts (x mirrored each side): inner row, drive, outer row, a planted border
local ROW1_X0, ROW1_X1 = 92, 106
local LANE_X0, LANE_X1 = 106, 124
local ROW2_X0, ROW2_X1 = 124, 138
local COURT_OUT = 148 -- (a Belle Epoque block stands at 151 by the street)
local COURT_FRONT, COURT_BACK = -100, 36.5
local LINK_Z0, LINK_Z1 = -62, -46 -- the drive through to the court

export type Frame = (number, number, number) -> CFrame

---------------------------------------------------------------------
-- Small helpers
---------------------------------------------------------------------
-- a flat round: a cylinder standing on end
local function round(kit: any, parent: Instance, solid: boolean, cf: CFrame, r: number, h: number, color: Color3, mat: Enum.Material, o: { [string]: any }?): BasePart
	local opts: { [string]: any } = o or {}
	opts.shape = Enum.PartType.Cylinder
	local f = if solid then kit.mk else kit.deco
	return f(parent, Vector3.new(h, r * 2, r * 2), cf * CFrame.Angles(0, 0, math.rad(90)), color, mat, opts)
end

-- a beam between two points
local function beam(kit: any, parent: Instance, a: Vector3, b: Vector3, w: number, h: number, color: Color3, mat: Enum.Material, o: { [string]: any }?)
	return kit.deco(parent, Vector3.new(w, h, (b - a).Magnitude + 0.1), CFrame.lookAt((a + b) / 2, b), color, mat, o)
end

-- a flat triangle from two wedges
local function tri(kit: any, parent: Instance, a: Vector3, b: Vector3, c: Vector3, color: Color3, mat: Enum.Material, solid: boolean)
	local ab, ac, bc = b - a, c - a, c - b
	local abd, acd, bcd = ab:Dot(ab), ac:Dot(ac), bc:Dot(bc)
	if abd > acd and abd > bcd then
		c, a = a, c
	elseif acd > bcd and acd > abd then
		a, b = b, a
	end
	ab, ac, bc = b - a, c - a, c - b
	local right = ac:Cross(ab).Unit
	local up = bc:Cross(right).Unit
	local back = bc.Unit
	local height = math.abs(ab:Dot(up))
	local f = if solid then kit.mk else kit.deco
	f(parent, Vector3.new(0.3, height, math.abs(ab:Dot(back))), CFrame.fromMatrix((a + b) / 2, right, up, back), color, mat, { class = "Wedge" })
	f(parent, Vector3.new(0.3, height, math.abs(ac:Dot(back))), CFrame.fromMatrix((a + c) / 2, -right, up, -back), color, mat, { class = "Wedge" })
end

local function quad(kit: any, parent: Instance, a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color3, mat: Enum.Material, solid: boolean)
	tri(kit, parent, a, b, c, color, mat, solid)
	tri(kit, parent, a, c, d, color, mat, solid)
end

-- a picture on one face of an invisible board
local function picture(kit: any, parent: Instance, size: Vector3, cf: CFrame, face: Enum.NormalId, image: string): BasePart
	local p = kit.deco(parent, size, cf, Color3.new(1, 1, 1), Enum.Material.SmoothPlastic, { transparency = 1 })
	local d = Instance.new("Decal")
	d.Texture = image
	d.Face = face
	d.Parent = p
	return p
end

-- the map's own palm (a real-looking tree), its foot at pos, h tall; the built one if the map has none
function RewardsPalace.palm(kit: any, parent: Instance, pos: Vector3, h: number, seed: number)
	-- (Monaco kept in ServerStorage since Yangon step 11: its palms and pieces are still copied from there)
	local riv = workspace:FindFirstChild("Riviera") or game:GetService("ServerStorage"):FindFirstChild("Riviera")
	local dressing = riv and riv:FindFirstChild("Dressing")
	local m = dressing and dressing:FindFirstChild("Palm", true)
	if not (m and m:IsA("Model")) then
		Garden.palm(kit, parent, pos, h, seed)
		return
	end
	local tree = m:Clone()
	tree:ScaleTo(tree:GetScale() * (h / tree:GetExtentsSize().Y))
	local cf, size = tree:GetBoundingBox()
	local foot = CFrame.new(pos) * CFrame.Angles(0, (seed * 1.7) % TAU, 0)
	tree:PivotTo(foot * (CFrame.new(cf.Position - Vector3.new(0, size.Y / 2, 0)):Inverse() * tree:GetPivot()))
	tree.Parent = parent
end

---------------------------------------------------------------------
-- The square: garden, exclusive parking, drive, flags
---------------------------------------------------------------------
local function fountain(kit: any, model: Instance, at: Frame, gy: number)
	local stone = Enum.Material.Marble
	round(kit, model, true, at(0, gy + 0.03, GARDEN_Z), 13, 0.12, PAVING_PALE, Enum.Material.Pavement, { name = "FountainWalk" })
	round(kit, model, true, at(0, gy + 1.1, GARDEN_Z), 10.2, 2.2, MARBLE, stone, { name = "Basin" })
	local water = round(kit, model, false, at(0, gy + 2.2, GARDEN_Z), 9.4, 0.12, Color3.fromRGB(46, 128, 170), Enum.Material.SmoothPlastic, {})
	water.Reflectance = 0.35
	round(kit, model, true, at(0, gy + 3.2, GARDEN_Z), 2.8, 2.4, MARBLE, stone, { name = "Pedestal" })
	round(kit, model, false, at(0, gy + 4.5, GARDEN_Z), 3.4, 0.4, GOLD, Enum.Material.Metal, {})
	-- the mirror ball, like the owner's photo
	kit.mk(model, Vector3.one * 11, at(0, gy + 9.8, GARDEN_Z), Color3.fromRGB(214, 220, 226), Enum.Material.Metal, { shape = Enum.PartType.Ball, reflectance = 0.55, name = "MirrorBall" })
	for k = 0, 3 do
		local a = k / 4 * TAU + 0.4
		local jet = kit.deco(model, Vector3.new(0.6, 0.3, 0.6), at(math.cos(a) * 7, gy + 2.3, GARDEN_Z + math.sin(a) * 7), MARBLE, stone)
		local spray = Instance.new("ParticleEmitter")
		spray.Color = ColorSequence.new(Color3.fromRGB(205, 236, 255))
		spray.LightEmission = 0.4
		spray.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
		spray.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) })
		spray.Lifetime = NumberRange.new(0.9, 1.2)
		spray.Rate = 22
		spray.Speed = NumberRange.new(13, 16)
		spray.SpreadAngle = Vector2.new(6, 6)
		spray.Acceleration = Vector3.new(0, -32, 0)
		spray.EmissionDirection = Enum.NormalId.Top
		spray.Parent = jet
	end
	kit.addLight("PointLight", water, Color3.fromRGB(150, 210, 255), 26, 0.9)
end

-- a flower bed: rings of colour, a few bushes on the rings
local function bed(kit: any, model: Instance, at: Frame, gy: number, x: number, r: number, rings: { Color3 })
	local n = #rings
	for i, col in rings do
		local rr = r * (1 - (i - 1) / n)
		round(kit, model, false, at(x, gy + 0.03 + i * 0.06, GARDEN_Z), rr, 0.14, col, Enum.Material.Grass, {})
		local count = math.floor(rr * 1.6)
		for k = 0, count - 1 do
			local a = k / count * TAU
			local q = rr - r / n * 0.5
			kit.deco(model, Vector3.one * 1.5, at(x + math.cos(a) * q, gy + 0.55, GARDEN_Z + math.sin(a) * q), col, Enum.Material.Grass, { shape = Enum.PartType.Ball })
		end
	end
end

local function garden(kit: any, model: Instance, at: Frame, top: number): number
	local mk, deco = kit.mk, kit.deco
	local gy = top + 0.5 -- the lawn's surface
	-- the lawn (strips: their ends sit under the stone rim)
	for z = -GARDEN_B + 1.25, GARDEN_B - 1.25, 2.5 do
		local hw = (GARDEN_A - 0.4) * math.sqrt(math.max(1 - (z / GARDEN_B) ^ 2, 0))
		if hw > 1 then
			mk(model, Vector3.new(hw * 2, 0.5, 2.5), at(0, top + 0.25, GARDEN_Z + z), LAWN, Enum.Material.Grass, { name = "Lawn" })
		end
	end
	-- the stone path from the pavement to the fountain and on to the steps
	mk(model, Vector3.new(8, 0.56, GARDEN_B * 2 + 1), at(0, top + 0.28, GARDEN_Z), PAVING_PALE, Enum.Material.Pavement, { name = "GardenPath" })
	-- the stone rim and the low black railing, open where the path goes through
	local n = 36
	for k = 0, n - 1 do
		local a0, a1 = (k + 0.5) / n * TAU, (k + 1.5) / n * TAU
		local x0, z0 = math.cos(a0) * GARDEN_A, math.sin(a0) * GARDEN_B
		local x1, z1 = math.cos(a1) * GARDEN_A, math.sin(a1) * GARDEN_B
		local mx, mz = (x0 + x1) / 2, (z0 + z1) / 2
		if math.abs(mx) > 6 then
			local len = math.sqrt((x1 - x0) ^ 2 + (z1 - z0) ^ 2)
			local turn = CFrame.Angles(0, -math.atan2(z1 - z0, x1 - x0), 0)
			mk(model, Vector3.new(len + 0.5, 0.9, 1.8), at(mx, top + 0.45, GARDEN_Z + mz) * turn, PAVING_PALE, Enum.Material.Pavement, { name = "GardenRim" })
			mk(model, Vector3.new(len + 0.2, 0.24, 0.24), at(mx, top + 2.7, GARDEN_Z + mz) * turn, IRON, Enum.Material.Metal, { name = "GardenRail" })
			deco(model, Vector3.new(len + 0.2, 0.16, 0.16), at(mx, top + 1.9, GARDEN_Z + mz) * turn, IRON, Enum.Material.Metal)
			if math.abs(x1) > 6 then
				deco(model, Vector3.new(0.3, 1.9, 0.3), at(x1, top + 1.85, GARDEN_Z + z1), IRON, Enum.Material.Metal)
				deco(model, Vector3.one * 0.5, at(x1, top + 2.95, GARDEN_Z + z1), GOLD, Enum.Material.Metal, { shape = Enum.PartType.Ball })
			end
		end
	end
	-- bollards in the path's two mouths: people walk through, cars don't
	for _, z in { GARDEN_Z - GARDEN_B - 0.6, GARDEN_Z + GARDEN_B + 0.6 } do
		for _, x in { -5.2, 0, 5.2 } do
			mk(model, Vector3.new(2.6, 1, 1), at(x, top + 1.3, z) * CFrame.Angles(0, 0, math.rad(90)), IRON, Enum.Material.Metal, { shape = Enum.PartType.Cylinder, name = "GardenBollard" })
			deco(model, Vector3.one * 0.8, at(x, top + 2.7, z), GOLD, Enum.Material.Metal, { shape = Enum.PartType.Ball })
		end
	end
	fountain(kit, model, at, gy)
	-- the flower beds, a palm in each end bed
	for _, s in { -1, 1 } do
		bed(kit, model, at, gy, s * 27, 9.6, { Color3.fromRGB(52, 104, 50), Color3.fromRGB(198, 46, 96), Color3.fromRGB(244, 236, 226), Color3.fromRGB(240, 190, 60) })
		bed(kit, model, at, gy, s * 46, 7.4, { Color3.fromRGB(52, 104, 50), Color3.fromRGB(238, 130, 50), Color3.fromRGB(168, 80, 170) })
		RewardsPalace.palm(kit, model, at(s * 46, gy, GARDEN_Z).Position, 38, if s > 0 then 11 else 23)
		RewardsPalace.palm(kit, model, at(s * 27, gy, GARDEN_Z).Position, 32, if s > 0 then 37 else 41)
	end
	-- where players start
	local spawns = Instance.new("Folder")
	spawns.Name = "GardenSpawns"
	spawns.Parent = model
	for _, p in { { -6.5, GARDEN_Z + 11 }, { 6.5, GARDEN_Z + 11 }, { -11.2, GARDEN_Z + 6 }, { 11.2, GARDEN_Z + 6 } } do
		local s = deco(spawns, Vector3.one, at(p[1], gy + 0.15, p[2]), Color3.new(), Enum.Material.SmoothPlastic, { transparency = 1, name = "GardenSpawn" })
		CollectionService:AddTag(s, "CasinoGardenSpawn")
	end
	return gy
end

local function parking(kit: any, model: Instance, at: Frame, top: number)
	local deco = kit.deco
	local starts = Instance.new("Folder")
	starts.Name = "CarStarts"
	starts.Parent = model
	local depth = BAY_Z1 - BAY_Z0
	deco(model, Vector3.new((BAY_START + BAY_W * 5) * 2, 0.08, depth), at(0, top + 0.04, (BAY_Z0 + BAY_Z1) / 2), PAVING_PALE, Enum.Material.Pavement)
	for _, s in { -1, 1 } do
		for k = 0, 5 do
			local x = s * (BAY_START + k * BAY_W)
			deco(model, Vector3.new(0.4, 0.06, depth - 0.6), at(x, top + 0.11, (BAY_Z0 + BAY_Z1) / 2), GOLD, Enum.Material.SmoothPlastic)
		end
	end
	-- where a first car waits, on the drive before the steps, facing the gentle way out
	for _, x in { 18, -18, 40, -40, -62 } do
		local c = deco(starts, Vector3.one, at(x, top, (AISLE_Z0 + AISLE_Z1) / 2) * CFrame.Angles(0, -math.pi / 2, 0), Color3.new(), Enum.Material.SmoothPlastic, { transparency = 1, name = "CarStart" })
		CollectionService:AddTag(c, "CasinoCarStart")
	end
end

-- a row of bays: pale paving, gold lines, a low stone stop at the nose (nose = the x the cars point at)
local function bayRow(kit: any, model: Instance, at: Frame, top: number, x0: number, x1: number, nose: number, z0: number, n: number)
	local deco = kit.deco
	local mid, wide = (x0 + x1) / 2, math.abs(x1 - x0)
	local long = n * BAY_W
	deco(model, Vector3.new(wide, 0.08, long), at(mid, top + 0.04, z0 + long / 2), PAVING_PALE, Enum.Material.Pavement)
	for k = 0, n do
		deco(model, Vector3.new(wide - 0.6, 0.06, 0.4), at(mid, top + 0.11, z0 + k * BAY_W), GOLD, Enum.Material.SmoothPlastic)
	end
	for k = 0, n - 1 do
		deco(model, Vector3.new(0.9, 0.34, BAY_W * 0.62), at(nose, top + 0.25, z0 + (k + 0.5) * BAY_W), STONE_DARK, Enum.Material.Pavement)
	end
end

-- a planted island at a row's end: a stone kerb, grass, two clipped shrubs, a real palm
local function island(kit: any, model: Instance, at: Frame, top: number, x0: number, x1: number, z0: number, z1: number, h: number, seed: number)
	local mk, deco = kit.mk, kit.deco
	local mid, wide = (x0 + x1) / 2, math.abs(x1 - x0)
	local midZ, long = (z0 + z1) / 2, z1 - z0
	mk(model, Vector3.new(wide, 0.8, long), at(mid, top + 0.4, midZ), PAVING_PALE, Enum.Material.Pavement, { name = "CourtIsland" })
	deco(model, Vector3.new(wide - 1.4, 0.1, long - 1.4), at(mid, top + 0.85, midZ), LAWN, Enum.Material.Grass)
	for _, f in { -0.3, 0.3 } do
		deco(model, Vector3.new(3, 2.4, 3), at(mid + wide * f, top + 1.9, midZ), HEDGE, Enum.Material.Grass, { shape = Enum.PartType.Ball })
	end
	RewardsPalace.palm(kit, model, at(mid, top + 0.9, midZ).Position, h, seed)
end

-- a black lantern on a post, gold collar, warm at night
local function lantern(kit: any, model: Instance, at: Frame, top: number, x: number, z: number)
	local deco = kit.deco
	deco(model, Vector3.new(1.4, 0.8, 1.4), at(x, top + 1.2, z), IRON, Enum.Material.Metal)
	deco(model, Vector3.new(0.42, 15, 0.42), at(x, top + 8.4, z), IRON, Enum.Material.Metal)
	deco(model, Vector3.new(0.8, 0.3, 0.8), at(x, top + 15.9, z), GOLD, Enum.Material.Metal)
	local glow = deco(model, Vector3.new(1.3, 1.9, 1.3), at(x, top + 17, z), WARM, Enum.Material.SmoothPlastic)
	deco(model, Vector3.new(1.8, 0.3, 1.8), at(x, top + 18.1, z), IRON, Enum.Material.Metal)
	deco(model, Vector3.one * 0.5, at(x, top + 18.5, z), GOLD, Enum.Material.Metal, { shape = Enum.PartType.Ball })
	kit.addLight("PointLight", glow, WARM, 36, 1.3)
end

-- a side court (s: which side): the slab past the plate, the drive, two rows of bays, islands, a
-- planted border with palms and lanterns
local function court(kit: any, model: Instance, at: Frame, top: number, s: number)
	local mk, deco = kit.mk, kit.deco
	local function A(x: number, y: number, z: number): CFrame
		return at(s * x, y, z)
	end
	local stone = Enum.Material.Pavement
	mk(model, Vector3.new(COURT_OUT - 108 + 2, 4.3, 148), A((108 + COURT_OUT + 2) / 2, top - 2.15, -30), PAVING, stone, { name = "CourtSlab" })
	-- the drive down the court and the way through from the steps
	deco(model, Vector3.new(LANE_X1 - LANE_X0, 0.08, COURT_BACK - COURT_FRONT), A((LANE_X0 + LANE_X1) / 2, top + 0.04, (COURT_FRONT + COURT_BACK) / 2), SETT, Enum.Material.Cobblestone)
	deco(model, Vector3.new(LANE_X0 - ARM_X1, 0.08, LINK_Z1 - LINK_Z0), A((LANE_X0 + ARM_X1) / 2, top + 0.04, (LINK_Z0 + LINK_Z1) / 2), SETT, Enum.Material.Cobblestone)
	-- the bays: 3 + 4 + 3 on the palace side, 4 + 4 + 3 on the outer side
	bayRow(kit, model, A, top, ROW1_X0, ROW1_X1, ROW1_X0 + 0.9, -93, 3)
	bayRow(kit, model, A, top, ROW1_X0, ROW1_X1, ROW1_X0 + 0.9, -44, 4)
	bayRow(kit, model, A, top, ROW1_X0, ROW1_X1, ROW1_X0 + 0.9, 5, 3)
	bayRow(kit, model, A, top, ROW2_X0, ROW2_X1, ROW2_X1 - 0.9, -93, 4)
	bayRow(kit, model, A, top, ROW2_X0, ROW2_X1, ROW2_X1 - 0.9, -44, 4)
	bayRow(kit, model, A, top, ROW2_X0, ROW2_X1, ROW2_X1 - 0.9, 5, 3)
	-- islands at the rows' ends and between them
	local seed = if s > 0 then 3 else 17
	for k, r in { { ROW1_X0, ROW1_X1, -100, -93 }, { ROW1_X0, ROW1_X1, -2, 5 }, { ROW2_X0, ROW2_X1, -100, -93 }, { ROW2_X0, ROW2_X1, -51, -44 }, { ROW2_X0, ROW2_X1, -2, 5 } } do
		island(kit, model, A, top, r[1], r[2], r[3], r[4], 38 + (k % 3) * 5, seed + k * 13)
	end
	-- the walk beside the palace: black bollards with gold tops
	for z = -43, 36, 11 do
		mk(model, Vector3.new(2.6, 1, 1), A(ROW1_X0 - 0.6, top + 1.3, z) * CFrame.Angles(0, 0, math.rad(90)), IRON, Enum.Material.Metal, { shape = Enum.PartType.Cylinder, name = "GardenBollard" })
		deco(model, Vector3.one * 0.8, A(ROW1_X0 - 0.6, top + 2.7, z), GOLD, Enum.Material.Metal, { shape = Enum.PartType.Ball })
	end
	-- the border: a stone kerb, grass, a tall hedge at the back, palms, shrubs, lanterns
	local bedMid = (ROW2_X1 + COURT_OUT) / 2
	mk(model, Vector3.new(COURT_OUT - ROW2_X1, 0.8, COURT_BACK - COURT_FRONT), A(bedMid, top + 0.4, (COURT_FRONT + COURT_BACK) / 2), PAVING_PALE, stone, { name = "CourtBorder" })
	deco(model, Vector3.new(COURT_OUT - ROW2_X1 - 1.4, 0.1, COURT_BACK - COURT_FRONT - 1.4), A(bedMid, top + 0.85, (COURT_FRONT + COURT_BACK) / 2), LAWN, Enum.Material.Grass)
	mk(model, Vector3.new(2.6, 4.2, COURT_BACK - COURT_FRONT + 9), A(COURT_OUT - 0.6, top + 2.1, (COURT_FRONT + COURT_BACK + 9) / 2 - 1.5), HEDGE, Enum.Material.Grass, { name = "Hedge" })
	-- the back: the same bed across the end of the court
	local backZ = COURT_BACK + 3.5
	mk(model, Vector3.new(COURT_OUT - ROW1_X0, 0.8, 7), A((ROW1_X0 + COURT_OUT) / 2, top + 0.4, backZ), PAVING_PALE, stone, { name = "CourtBorder" })
	deco(model, Vector3.new(COURT_OUT - ROW1_X0 - 1.4, 0.1, 5.6), A((ROW1_X0 + COURT_OUT) / 2, top + 0.85, backZ), LAWN, Enum.Material.Grass)
	mk(model, Vector3.new(COURT_OUT - ROW1_X0, 3, 2.2), A((ROW1_X0 + COURT_OUT) / 2, top + 1.6, COURT_BACK + 6), HEDGE, Enum.Material.Grass, { name = "Hedge" })
	local t = 0
	for z = -84, 28, 28 do
		t += 1
		RewardsPalace.palm(kit, model, A(bedMid - 1, top + 0.9, z).Position, 40 + (t % 3) * 5, seed + t * 29)
	end
	for z = -70, 14, 28 do
		for _, dz in { -5, 5 } do
			deco(model, Vector3.new(3, 2.4, 3), A(bedMid + 1, top + 1.9, z + dz), Color3.fromRGB(52, 100, 50), Enum.Material.Grass, { shape = Enum.PartType.Ball })
		end
		lantern(kit, model, A, top, ROW2_X1 + 1.2, z)
	end
	for _, x in { (LANE_X0 + LANE_X1) / 2 - 8, (LANE_X0 + LANE_X1) / 2 + 8 } do
		lantern(kit, model, A, top, x, COURT_BACK + 1.6)
	end
	RewardsPalace.palm(kit, model, A((LANE_X0 + LANE_X1) / 2, top + 0.9, COURT_BACK + 3.2).Position, 44, seed + 91)
end

local function flag(kit: any, model: Instance, at: Frame, top: number, x: number, z: number, s: number)
	local deco = kit.deco
	deco(model, Vector3.new(0.5, 28, 0.5), at(x, top + 14, z), Color3.fromRGB(236, 236, 232), Enum.Material.Metal)
	deco(model, Vector3.one * 1, at(x, top + 28.3, z), GOLD, Enum.Material.Metal, { shape = Enum.PartType.Ball })
	deco(model, Vector3.new(0.14, 4.2, 7.4), at(x, top + 25.2, z - 3.9), NAVY, Enum.Material.Fabric)
	deco(model, Vector3.new(0.18, 0.8, 7.4), at(x, top + 25.2, z - 3.9), GOLD, Enum.Material.Fabric)
end

function RewardsPalace.square(kit: any, model: Instance, at: Frame, half: number)
	local mk, deco = kit.mk, kit.deco
	local top = 0.3
	mk(model, Vector3.new(half * 2, top, half * 2), at(0, top / 2, 0), PAVING, Enum.Material.Pavement, { name = "Plaza" })
	-- the drive in granite setts: in front of the steps, round both ends of the garden
	local function setts(x0: number, x1: number, z0: number, z1: number)
		deco(model, Vector3.new(x1 - x0, 0.08, z1 - z0), at((x0 + x1) / 2, top + 0.04, (z0 + z1) / 2), SETT, Enum.Material.Cobblestone)
	end
	setts(-ARM_X1, ARM_X1, AISLE_Z0, AISLE_Z1)
	setts(-ARM_X1, -ARM_X0, RAMP_Z, AISLE_Z0)
	setts(ARM_X0, ARM_X1, RAMP_Z, AISLE_Z0)
	-- the walk across it to the steps, the red carpet up them
	deco(model, Vector3.new(8, 0.08, AISLE_Z1 - AISLE_Z0), at(0, top + 0.1, (AISLE_Z0 + AISLE_Z1) / 2), PAVING_PALE, Enum.Material.Pavement)
	garden(kit, model, at, top)
	parking(kit, model, at, top)
	for _, s in { -1, 1 } do
		-- behind the drive: a hedge (open where the way through to the side court goes), flags
		mk(model, Vector3.new(2.4, 2.8, 41.5), at(s * (ARM_X1 + 1.2), top + 1.4, -82.75), HEDGE, Enum.Material.Grass, { name = "Hedge" })
		mk(model, Vector3.new(COURT_OUT - ARM_X1, 2.8, 2.4), at(s * (ARM_X1 + COURT_OUT) / 2, top + 1.4, -102.5), HEDGE, Enum.Material.Grass, { name = "Hedge" })
		for z = -96, -64, 15.3 do
			flag(kit, model, at, top, s * (ARM_X1 + 5), z, s)
		end
		court(kit, model, at, top, s)
		-- a stone planter along the front wall, clipped balls, the lamps that wash the stone
		mk(model, Vector3.new(47, 1.2, 4.6), at(s * 60.5, top + 0.6, -44.6), STONE_DARK, Enum.Material.Pavement, { name = "Planter" })
		deco(model, Vector3.new(46, 1.4, 3.8), at(s * 60.5, top + 1.8, -44.6), HEDGE, Enum.Material.Grass)
		for x = 41, 81, 8 do
			deco(model, Vector3.one * 3.4, at(s * x, top + 3.4, -44.6), Color3.fromRGB(52, 100, 50), Enum.Material.Grass, { shape = Enum.PartType.Ball })
		end
		for _, x in { 50, 74 } do
			local lamp = deco(model, Vector3.new(1.6, 1, 1.6), at(s * x, top + 2.4, -42.6), Color3.fromRGB(30, 30, 34), Enum.Material.Metal)
			kit.addLight("SpotLight", lamp, Color3.fromRGB(255, 196, 120), 70, 2.6, Enum.NormalId.Top, 50)
		end
		-- the drives from the street: they stop at the road's edge
		-- (owner, 2026-11-06) the setts run on from the drive to where the ramp starts
		local inner = at(s * (ARM_X0 + ARM_X1) / 2, top, RAMP_Z)
		task.defer(function()
			local ramp = EntranceRamp.build(model, inner, { width = ARM_X1 - ARM_X0, reach = 40, color = SETT, material = Enum.Material.Cobblestone, keep = { model }, lift = 0.08, notch = true })
			local from = if ramp then ramp:GetAttribute("RampStart") else nil
			if type(from) == "number" and from > 0 then
				local x0, x1 = math.min(s * ARM_X0, s * ARM_X1), math.max(s * ARM_X0, s * ARM_X1)
				setts(x0, x1, RAMP_Z - from, RAMP_Z)
			end
		end)
	end
end

---------------------------------------------------------------------
-- The roof: slate hip over the hall, dormers, twin towers, the clock
---------------------------------------------------------------------
function RewardsPalace.roof(kit: any, model: Instance, at: Frame, o: { [string]: number }): number
	local mk, deco = kit.mk, kit.deco
	local FLOOR, H, HX, ZF, ZH = o.FLOOR, o.H, o.HX, o.ZF, o.ZH
	local cz = (ZF + ZH) / 2
	local yb, yt = FLOOR + H + 2, FLOOR + H + 17
	-- the flat roof round the opening over the hall's dome
	local hw, hd = 72, (ZH - ZF) / 2 - 6
	for _, s in { -1, 1 } do
		mk(model, Vector3.new(HX - hw + 1, 2, ZH - ZF), at(s * (HX + hw) / 2, FLOOR + H + 1, cz), SLATE, Enum.Material.Slate, { name = "Roof" })
		mk(model, Vector3.new(hw * 2, 2, 7), at(0, FLOOR + H + 1, cz + s * (hd + 3)), SLATE, Enum.Material.Slate, { name = "Roof" })
	end
	-- the hip
	local bx, bz, tx, tz = 80, hd + 2, 38, 26
	local function p(x: number, y: number, z: number): Vector3
		return at(x, y, cz + z).Position
	end
	local b = { p(-bx, yb, -bz), p(bx, yb, -bz), p(bx, yb, bz), p(-bx, yb, bz) }
	local t = { p(-tx, yt, -tz), p(tx, yt, -tz), p(tx, yt, tz), p(-tx, yt, tz) }
	for i = 1, 4 do
		local j = i % 4 + 1
		quad(kit, model, b[i], b[j], t[j], t[i], SLATE, Enum.Material.Slate, false)
		beam(kit, model, b[i], t[i], 0.9, 0.9, GOLD, Enum.Material.Metal)
		beam(kit, model, t[i], t[j], 0.7, 0.7, GOLD, Enum.Material.Metal)
	end
	deco(model, Vector3.new(tx * 2, 0.4, tz * 2), at(0, yt, cz), SLATE, Enum.Material.Slate)
	-- round dormers on the street side
	for k = -2, 2 do
		local x = k * 26
		local q = 0.34
		local z, y = cz - bz + (bz - tz) * q, yb + (yt - yb) * q
		deco(model, Vector3.new(8, 6, 6), at(x, y + 2.4, z - 1), STONE, Enum.Material.Plaster)
		deco(model, Vector3.new(9, 0.8, 7), at(x, y + 5.6, z - 1), COPPER, Enum.Material.Metal)
		local front = at(x, y + 2.4, z - 4.1) * CFrame.Angles(0, math.pi / 2, 0)
		deco(model, Vector3.new(0.3, 5, 5), front * CFrame.Angles(0, 0, 0), STONE_DARK, Enum.Material.Plaster, { shape = Enum.PartType.Cylinder })
		deco(model, Vector3.new(0.4, 3.6, 3.6), front, Color3.fromRGB(26, 28, 40), Enum.Material.SmoothPlastic, { shape = Enum.PartType.Cylinder, reflectance = 0.2 })
	end
	-- the twin towers either side of the entrance
	local fz = ZF
	local towerTop = FLOOR + H + 30
	for _, s in { -1, 1 } do
		local x, z = s * 20, fz + 3.5
		mk(model, Vector3.new(11, towerTop - FLOOR, 9), at(x, (FLOOR + towerTop) / 2, z), STONE, Enum.Material.Plaster, { name = "TwinTower" })
		-- paired stone strips, a belfry arch on the front and on the outer side
		for _, dx in { -4.4, 4.4 } do
			deco(model, Vector3.new(1.4, towerTop - FLOOR - 7, 0.5), at(x + dx, FLOOR + 3.5 + (towerTop - FLOOR - 7) / 2 , z - 4.6), STONE_DARK, Enum.Material.Plaster)
		end
		local by = FLOOR + H + 15
		deco(model, Vector3.new(5, 11, 0.4), at(x, by, z - 4.55), Color3.fromRGB(26, 28, 40), Enum.Material.SmoothPlastic)
		deco(model, Vector3.new(0.4, 5, 5), at(x, by + 5.5, z - 4.55) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(26, 28, 40), Enum.Material.SmoothPlastic, { shape = Enum.PartType.Cylinder })
		deco(model, Vector3.new(0.3, 8, 0.3), at(x, by + 1, z - 4.8), IRON, Enum.Material.Metal)
		deco(model, Vector3.new(5, 0.4, 0.5), at(x, by - 2, z - 4.8), IRON, Enum.Material.Metal)
		deco(model, Vector3.new(1.6, 2, 0.8), at(x, by + 8.3, z - 4.7), GOLD, Enum.Material.Metal)
		-- the top: a cornice, a little balustrade, a copper cap and a gold spire
		deco(model, Vector3.new(12.6, 1.2, 10.6), at(x, towerTop, z), STONE_DARK, Enum.Material.Plaster)
		deco(model, Vector3.new(11.4, 2.2, 9.4), at(x, towerTop + 1.6, z), STONE, Enum.Material.Plaster)
		mk(model, Vector3.one * 10, at(x, towerTop + 3, z), COPPER, Enum.Material.Metal, { shape = Enum.PartType.Ball, name = "Dome" })
		deco(model, Vector3.new(1.2, 3.4, 1.2), at(x, towerTop + 9, z), GOLD, Enum.Material.Metal, { reflectance = 0.25 })
		deco(model, Vector3.one * 1.4, at(x, towerTop + 11.4, z), GOLD, Enum.Material.Metal, { shape = Enum.PartType.Ball, reflectance = 0.25 })
		-- urns on the balustrade
		for _, ux in { 42.5, 61.5, 82 } do
			local uy = FLOOR + H + 9.2
			deco(model, Vector3.new(2.2, 1.2, 2.2), at(s * ux, uy, fz - 0.6), STONE_DARK, Enum.Material.Plaster)
			deco(model, Vector3.new(2.4, 2.2, 2.2), at(s * ux, uy + 1.6, fz - 0.6), STONE, Enum.Material.Plaster, { shape = Enum.PartType.Ball })
			deco(model, Vector3.one * 0.8, at(s * ux, uy + 3.1, fz - 0.6), GOLD, Enum.Material.Metal, { shape = Enum.PartType.Ball })
		end
	end
	-- the clock between the towers: a round-topped stone panel over the frieze
	local cy = FLOOR + H + 13
	deco(model, Vector3.new(29, 9, 2), at(0, FLOOR + H + 9.5, fz + 0.5), STONE, Enum.Material.Plaster)
	local disc = at(0, cy + 1, fz + 0.5) * CFrame.Angles(0, math.pi / 2, 0)
	kit.deco(model, Vector3.new(2, 29, 29), disc, STONE, Enum.Material.Plaster, { shape = Enum.PartType.Cylinder })
	kit.deco(model, Vector3.new(2.3, 24, 24), disc, STONE_DARK, Enum.Material.Plaster, { shape = Enum.PartType.Cylinder })
	kit.deco(model, Vector3.new(2.6, 17, 17), disc, GOLD, Enum.Material.Metal, { shape = Enum.PartType.Cylinder, reflectance = 0.15 })
	kit.deco(model, Vector3.new(2.9, 15.4, 15.4), disc, Color3.fromRGB(246, 240, 226), Enum.Material.SmoothPlastic, { shape = Enum.PartType.Cylinder })
	local face = at(0, cy + 1, fz - 1)
	for k = 0, 11 do
		local a = k / 12 * TAU
		deco(model, Vector3.new(0.5, 1.5, 0.2), face * CFrame.new(math.sin(a) * 6.2, math.cos(a) * 6.2, 0) * CFrame.Angles(0, 0, -a), IRON, Enum.Material.SmoothPlastic)
	end
	deco(model, Vector3.new(0.6, 4.6, 0.2), face * CFrame.Angles(0, 0, math.rad(-50)) * CFrame.new(0, 2.1, -0.05), IRON, Enum.Material.SmoothPlastic)
	deco(model, Vector3.new(0.4, 6.2, 0.2), face * CFrame.Angles(0, 0, math.rad(30)) * CFrame.new(0, 2.9, -0.1), IRON, Enum.Material.SmoothPlastic)
	deco(model, Vector3.one * 1, face * CFrame.new(0, 0, -0.1), GOLD, Enum.Material.Metal, { shape = Enum.PartType.Ball })
	deco(model, Vector3.new(1.8, 3, 1.8), at(0, cy + 16.4, fz + 0.5), GOLD, Enum.Material.Metal, { reflectance = 0.25 })
	deco(model, Vector3.one * 1.8, at(0, cy + 18.6, fz + 0.5), GOLD, Enum.Material.Metal, { shape = Enum.PartType.Ball, reflectance = 0.25 })
	return yt -- what the great dome's drum stands on
end

---------------------------------------------------------------------
-- The hall: the dome, the walls, the floor
---------------------------------------------------------------------
-- one ring's corners, in the frame: an oval at height y
local function ovalPoint(cz: number, a: number, b: number, y: number, t: number): Vector3
	return Vector3.new(math.cos(t) * a, y, cz + math.sin(t) * b)
end

function RewardsPalace.hall(kit: any, inside: Instance, at: Frame, o: { [string]: number })
	local deco = kit.deco
	local FLOOR, H, HX, ZF, ZH = o.FLOOR, o.H, o.HX, o.ZF, o.ZH
	local cz = (ZF + ZH) / 2
	local base = at(0, 0, 0)
	local yC = FLOOR + H - 2 -- the flat ceiling
	local rx, rz = HX - 3, (ZH - ZF) / 2 - 1 -- the room's half size
	-- the flat ceiling: strips that stop at the oval (their ends hide behind the first band)
	local A0, B0 = 64.5, 48.5
	local step = 2.5
	local z = -rz
	while z < rz do
		local mid = z + step / 2
		local e = 1 - (mid / B0) ^ 2
		if e > 0 then
			local chord = A0 * math.sqrt(e)
			for _, s in { -1, 1 } do
				deco(inside, Vector3.new(rx - chord, 0.5, step + 0.02), at(s * (rx + chord) / 2, yC, cz + mid), CREAM, Enum.Material.SmoothPlastic)
			end
		else
			deco(inside, Vector3.new(rx * 2, 0.5, step + 0.02), at(0, yC, cz + mid), CREAM, Enum.Material.SmoothPlastic)
		end
		z += step
	end
	-- gold coffers on the flat part, only in its corners and ends
	for _, s in { -1, 1 } do
		for k = 0, 2 do
			local x = s * (rx - 4 - k * 8)
			deco(inside, Vector3.new(1, 1.1, rz * 2 - 2), at(x, yC - 0.6, cz), GOLD, Enum.Material.Metal, { reflectance = 0.15 })
		end
		for _, dz in { -rz + 2, rz - 2 } do
			deco(inside, Vector3.new(rx * 2 - 2, 1.1, 1), at(0, yC - 0.6, cz + dz), GOLD, Enum.Material.Metal, { reflectance = 0.15 })
		end
		for _, dz in { -28, 0, 28 } do
			deco(inside, Vector3.new(20, 1.1, 1), at(s * (rx - 12), yC - 0.6, cz + dz), GOLD, Enum.Material.Metal, { reflectance = 0.15 })
		end
	end
	-- the cove up to the glass: three bands between gold mouldings, every fourth seam a gold rib
	local rings = {
		{ 66, 50, yC - 2.6 },
		{ 61.5, 46, yC + 3 },
		{ 54, 40, yC + 8.4 },
		{ 46.5, 34.5, yC + 13 },
	}
	local bands = { CREAM, Color3.fromRGB(30, 62, 112), CREAM }
	local n = 28
	for r = 1, 3 do
		local a, b = rings[r], rings[r + 1]
		for k = 0, n - 1 do
			local t0, t1 = k / n * TAU, (k + 1) / n * TAU
			local p00 = ovalPoint(cz, a[1], a[2], a[3], t0)
			local p01 = ovalPoint(cz, a[1], a[2], a[3], t1)
			local p10 = ovalPoint(cz, b[1], b[2], b[3], t0)
			local p11 = ovalPoint(cz, b[1], b[2], b[3], t1)
			local mid = (p00 + p01 + p10 + p11) / 4
			local along = (p01 - p00).Unit
			local across = (p10 + p11 - p00 - p01) / 2
			local normal = across:Cross(along).Unit
			deco(inside, Vector3.new((p01 - p00).Magnitude + 1.2, 0.3, across.Magnitude + 0.3), base * CFrame.fromMatrix(mid, along, normal, across.Unit), bands[r], Enum.Material.SmoothPlastic)
			if k % 4 == 0 then
				beam(kit, inside, (base * CFrame.new(p00)).Position, (base * CFrame.new(p10)).Position, 1, 0.8, GOLD, Enum.Material.Metal, { reflectance = 0.15 })
			end
		end
	end
	for r = 1, 4 do
		local a = rings[r]
		for k = 0, n - 1 do
			local t0, t1 = k / n * TAU, (k + 1) / n * TAU
			local p0 = (base * CFrame.new(ovalPoint(cz, a[1], a[2], a[3], t0))).Position
			local p1 = (base * CFrame.new(ovalPoint(cz, a[1], a[2], a[3], t1))).Position
			beam(kit, inside, p0, p1, 1.1, 1, GOLD, Enum.Material.Metal, { reflectance = 0.15 })
		end
	end
	-- the painted lunettes on the blue band
	for k = 0, 7 do
		local t = (k + 0.5) / 8 * TAU
		local a, b = rings[2], rings[3]
		local p0 = ovalPoint(cz, a[1], a[2], a[3], t)
		local p1 = ovalPoint(cz, b[1], b[2], b[3], t)
		local tang = Vector3.new(-math.sin(t) * a[1], 0, math.cos(t) * a[2]).Unit
		local across = (p1 - p0)
		local normal = tang:Cross(across).Unit
		if normal.Y > 0 then
			normal = -normal
			tang = -tang
		end
		local mid = (p0 + p1) / 2 + normal * 0.3
		local cf = CFrame.fromMatrix(mid, tang, across.Unit:Cross(tang).Unit, across.Unit)
		picture(kit, inside, Vector3.new(15, 0.1, 7.2), base * cf, Enum.NormalId.Bottom, ART.lunette)
	end
	-- the stained glass: self-lit so it glows like daylight behind blue glass, day and night
	local top = rings[4]
	local glass = deco(inside, Vector3.new(top[1] * 2 / 0.984, 0.4, top[2] * 2 / 0.984), at(0, top[3] + 0.3, cz), Color3.fromRGB(8, 22, 70), Enum.Material.SmoothPlastic, { name = "StainedGlass" })
	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId.Bottom
	g.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	g.CanvasSize = Vector2.new(1024, 760)
	g.LightInfluence = 0
	g.Brightness = 1.5
	g.MaxDistance = 500
	g.Parent = glass
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.Size = UDim2.fromScale(1, 1)
	img.Image = ART.dome
	img.Parent = g
	-- the walls: cream panels, a rose marble dado, marble columns in pairs, a gold cornice, landscapes,
	-- lunettes
	local bay = 22
	local colH = 28
	local capY = FLOOR + colH
	-- the front wall's inside, round the windows and the door
	local function skin(x0: number, x1: number, y0: number, y1: number)
		deco(inside, Vector3.new(x1 - x0, y1 - y0, 0.2), at((x0 + x1) / 2, (y0 + y1) / 2, ZF + 1.1), CREAM, Enum.Material.SmoothPlastic)
	end
	local top1 = FLOOR + H - 1.5
	local cuts = { -HX + 3, -78, -64, -59, -45, -40, -26, -14, 14, 26, 40, 45, 59, 64, 78, HX - 3 }
	for i = 1, #cuts, 2 do
		skin(cuts[i], cuts[i + 1], FLOOR, top1)
	end
	for i = 2, #cuts - 1, 2 do
		if cuts[i] ~= -14 then
			skin(cuts[i], cuts[i + 1], FLOOR, FLOOR + 3.6)
			skin(cuts[i], cuts[i + 1], FLOOR + 32, top1)
		else
			skin(cuts[i], cuts[i + 1], FLOOR + 39, top1)
		end
	end
	deco(inside, Vector3.new(HX * 2 - 6, H - 1.5, 0.4), at(0, FLOOR + (H - 1.5) / 2, ZH - 1.2), CREAM, Enum.Material.SmoothPlastic)
	for _, s in { -1, 1 } do
		local wx = s * (HX - 3.6)
		deco(inside, Vector3.new(0.4, H - 1.5, ZH - ZF - 2), at(s * (HX - 3.2), FLOOR + (H - 1.5) / 2, cz), CREAM, Enum.Material.SmoothPlastic)
		deco(inside, Vector3.new(0.5, 4.5, ZH - ZF - 4), at(wx, FLOOR + 2.25, cz), ROSE, Enum.Material.Marble)
		deco(inside, Vector3.new(1.2, 0.5, ZH - ZF - 4), at(s * (HX - 3.9), FLOOR + 4.6, cz), GOLD, Enum.Material.Metal)
		for _, y in { capY + 0.8, capY + 3.4 } do
			deco(inside, Vector3.new(1.6, 0.9, ZH - ZF - 4), at(s * (HX - 4.1), y, cz), GOLD, Enum.Material.Metal, { reflectance = 0.15 })
		end
		local cz0 = ZF + 14
		for k = 0, 4 do
			local cc = cz0 + k * bay
			for _, dz in { -2, 2 } do
				local cf = at(s * (HX - 5.2), FLOOR + colH / 2, cc + dz) * CFrame.Angles(0, 0, math.rad(90))
				deco(inside, Vector3.new(colH, 2.8, 2.8), cf, ROSE, Enum.Material.Marble, { shape = Enum.PartType.Cylinder })
				deco(inside, Vector3.new(1.6, 3.6, 3.6), at(s * (HX - 5.2), FLOOR + 0.8, cc + dz) * CFrame.Angles(0, 0, math.rad(90)), GOLD, Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
				deco(inside, Vector3.new(1.6, 3.6, 3.6), at(s * (HX - 5.2), capY - 0.8, cc + dz) * CFrame.Angles(0, 0, math.rad(90)), GOLD, Enum.Material.Metal, { shape = Enum.PartType.Cylinder, reflectance = 0.15 })
			end
			if k < 4 then
				local mz = cc + bay / 2
				local face = if s < 0 then Enum.NormalId.Right else Enum.NormalId.Left
				deco(inside, Vector3.new(0.3, 12.4, 15.4), at(s * (HX - 3.7), FLOOR + 21, mz), GOLD, Enum.Material.Metal, { reflectance = 0.15 })
				picture(kit, inside, Vector3.new(0.2, 11, 14), at(s * (HX - 3.92), FLOOR + 21, mz), face, if k % 2 == 0 then ART.garden else ART.harbour)
				picture(kit, inside, Vector3.new(0.2, 6.6, 13.2), at(s * (HX - 3.6), capY + 7.4, mz), face, ART.lunette)
			end
		end
	end
	-- the back wall and the front wall: a cornice and lunettes
	for x = -60, 60, 20 do
		picture(kit, inside, Vector3.new(13.2, 6.6, 0.2), at(x, FLOOR + colH + 7.4, ZH - 1.6), Enum.NormalId.Front, ART.lunette)
	end
	for _, y in { capY + 0.8, capY + 3.4 } do
		deco(inside, Vector3.new(rx * 2, 0.9, 1.6), at(0, y, ZH - 2), GOLD, Enum.Material.Metal, { reflectance = 0.15 })
	end
	for _, x in { -71, -52, -33, 33, 52, 71 } do
		picture(kit, inside, Vector3.new(13.2, 6.6, 0.2), at(x, FLOOR + colH + 7.4, ZF + 1.35), Enum.NormalId.Back, ART.lunette)
	end
	-- warm light hidden along the walls
	for _, s in { -1, 1 } do
		local cove = deco(inside, Vector3.new(0.6, 0.4, ZH - ZF - 8), at(s * (HX - 6), yC - 1.6, cz), WARM, Enum.Material.SmoothPlastic, { transparency = 1 })
		kit.addLight("SurfaceLight", cove, WARM, 22, 0.4, Enum.NormalId.Bottom, 120)
	end
	-- the marble medallion on the floor under the dome
	local ring = { { 34, GOLD, Enum.Material.Metal }, { 33, NAVY, Enum.Material.Marble }, { 27, MARBLE, Enum.Material.Marble }, { 26, ROSE, Enum.Material.Marble }, { 15, GOLD, Enum.Material.Metal }, { 14.2, MARBLE, Enum.Material.Marble } }
	for i, m in ring do
		round(kit, inside, false, at(0, FLOOR + i * 0.04, cz), m[1], 0.1, m[2], m[3], {})
	end
	for k = 0, 3 do
		deco(inside, Vector3.new(19, 0.06, 1.6), at(0, FLOOR + 0.3, cz) * CFrame.Angles(0, math.rad(k * 45), 0), GOLD, Enum.Material.Metal)
	end
end

return RewardsPalace
