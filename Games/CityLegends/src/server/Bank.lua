--[[
	Bank (server)
	The Legends Reserve Bank and its robbery (owner, 2026-10-22: "add a bank which u can rob").
	  * A stone bank on its own city block: steps, columns, a marble hall with chandeliers and
	    teller counters, and a round steel vault door at the back.
	  * On foot, hold E at the vault door to crack it: the alarm rings, the door swings open and
	    the robber gets 4 stars. Inside, cash carts: hold E to stuff a bag (up to a limit).
	  * The loot rides with you (on foot or in your car). Lose the police, then bring it to the
	    drop-off (a lock-up garage across town) to cash in. Busted: the loot is gone.
	  * The vault closes again after a while and stays locked for a cooldown.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local CityLayout = require(Shared:WaitForChild("CityLayout"))
local WestLayout = require(Shared:WaitForChild("WestLayout"))
local EntranceRamp = require(script.Parent:WaitForChild("EntranceRamp"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local B = Config.Bank
local C = Config.City

local Bank = {}
Bank.BLOCK = B.Block -- { bi, bj }

local vault: {
	door: Model?,
	prompt: ProximityPrompt?,
	carts: { ProximityPrompt },
	alarm: Sound?,
	alarmLights: { Light },
	openUntil: number,
	lockedUntil: number,
	hinge: CFrame?,
} = { door = nil, prompt = nil, carts = {}, alarm = nil, alarmLights = {}, openUntil = 0, lockedUntil = 0, hinge = nil }
local dropoff: Vector3? = nil

-- (2026-11-04 remodel: warm Riviera stone, cream trims, dark bronze; no neon anywhere)
local STONE = Color3.fromRGB(206, 172, 124)
local STONE_DARK = Color3.fromRGB(160, 142, 114)
local TRIM = Color3.fromRGB(222, 208, 180)
local MARBLE = Color3.fromRGB(232, 226, 214)
local MARBLE_DARK = Color3.fromRGB(92, 72, 58)
local GOLD = Color3.fromRGB(206, 164, 76)
local BRONZE = Color3.fromRGB(70, 52, 36)
local WOOD = Color3.fromRGB(86, 52, 30)
local STEEL = Color3.fromRGB(150, 156, 164)
local IRON = Color3.fromRGB(28, 28, 30)
local WALL = Enum.Material.Sandstone -- (Limestone read as white in the sun)

-- a ready-made piece from ServerStorage.VenueKit (cleaned Creator Store models, see the notes), or nil
local function kitPiece(name: string, cf: CFrame, scale: number?, parent: Instance): Model?
	local vk = game:GetService("ServerStorage"):FindFirstChild("VenueKit")
	local src = vk and vk:FindFirstChild(name)
	if not (src and src:IsA("Model")) then
		return nil
	end
	local m = src:Clone()
	if scale and scale ~= 1 then
		m:ScaleTo(scale)
	end
	m:PivotTo(cf)
	m.Parent = parent
	return m
end

---------------------------------------------------------------------
-- The remodel (2026-11-04, owner-away run, `Prompts/Remodel the venues.md`: "a grand Belle Epoque
-- stone bank: columns, a big bronze door, carved cornice, flags, a stone stair, warm floodlights;
-- inside a marble banking hall, wooden counters with brass lamps, a chandelier, the vault door, a
-- corridor to the vault, CCTV, the guard desk"). Looks only: the vault door, its prompt, the cash
-- carts and the alarm are built as before.
---------------------------------------------------------------------
function Bank.dress(kit: any, model: Model, at: (number, number, number) -> CFrame, d: { [string]: number })
	local mk, deco = kit.mk, kit.deco
	local W, D, H, FLOOR = d.W, d.D, d.H, d.FLOOR
	local zFront, zf, colZ = d.zFront, d.zf, d.colZ
	local doorW, doorH, vz, cz2 = d.doorW, d.doorH, d.vz, d.cz2
	local wallFace = zf - 1.5 -- the front wall's outer face
	local dress = Instance.new("Model")
	dress.Name = "Remodel"
	dress.Parent = model
	local function s(size: Vector3, cf: CFrame, color: Color3?, mat: Enum.Material?): BasePart
		return deco(dress, size, cf, color or STONE, mat or Enum.Material.Limestone)
	end
	local function lightOff(head: BasePart?, l: Light?)
		-- (lamps and floodlights only at night: WorldFx's day switch; a lamp's glass glows too)
		if head and kit.dayOff then
			kit.dayOff(head, l)
		elseif l then
			game:GetService("CollectionService"):AddTag(l, "DayOff")
		end
	end

	-------------------------------------------------------------------
	-- outside
	-------------------------------------------------------------------
	-- a rusticated base: deep joints every 2 studs up to the first band, on the front and sides
	local baseTop = FLOOR + 9
	for y = FLOOR + 2, baseTop - 1, 2 do
		s(Vector3.new(W + 0.6, 0.25, 0.3), at(0, y, wallFace - 0.1), STONE_DARK)
		for _, sx in { -1, 1 } do
			s(Vector3.new(0.3, 0.25, D - 2), at(sx * (W / 2 + 0.12), y, 0), STONE_DARK)
		end
	end
	-- the band over the base
	s(Vector3.new(W + 1.6, 1, 1.4), at(0, baseTop, wallFace - 0.5), TRIM)
	for _, sx in { -1, 1 } do
		s(Vector3.new(1.4, 1, D + 1.6), at(sx * (W / 2 + 0.5), baseTop, 0), TRIM)
	end
	-- the front wall beside the doors: tall dark windows with stone surrounds and bronze grilles
	for _, x in { -54, -42, 42, 54 } do
		local wy = FLOOR + 22
		s(Vector3.new(6, 14, 0.4), at(x, wy, wallFace - 0.05), Color3.fromRGB(40, 36, 32), Enum.Material.Glass)
		s(Vector3.new(7.6, 1, 0.9), at(x, wy + 7.5, wallFace - 0.35), TRIM) -- head
		s(Vector3.new(8.4, 0.8, 1.2), at(x, wy + 8.4, wallFace - 0.5), TRIM) -- hood
		s(Vector3.new(1.4, 1.8, 1.0), at(x, wy + 7.6, wallFace - 0.6), TRIM) -- keystone
		s(Vector3.new(7.6, 0.8, 1.2), at(x, wy - 7.4, wallFace - 0.5), TRIM) -- sill
		for _, ex in { -3.4, 3.4 } do
			s(Vector3.new(0.8, 15, 0.8), at(x + ex, wy, wallFace - 0.3), TRIM)
		end
		for k = -1, 1 do
			s(Vector3.new(0.18, 13, 0.18), at(x + k * 1.8, wy, wallFace - 0.4), BRONZE, Enum.Material.Metal)
		end
		s(Vector3.new(6, 0.18, 0.18), at(x, wy - 2, wallFace - 0.4), BRONZE, Enum.Material.Metal)
	end
	-- the doors: tall bronze leaves standing open, a bronze grille over each, gold handles
	for _, dx in { -(doorW + 12), 0, doorW + 12 } do
		for _, side in { -1, 1 } do
			local hinge = at(dx + side * doorW / 2, FLOOR + doorH / 2, zf + 0.8)
			local leaf = hinge * CFrame.Angles(0, side * math.rad(72), 0) * CFrame.new(-side * doorW / 4, 0, 0)
			s(Vector3.new(doorW / 2 - 0.2, doorH - 0.4, 0.5), leaf, BRONZE, Enum.Material.Metal)
			for _, py in { -5, 4 } do
				s(Vector3.new(doorW / 2 - 2, 6, 0.65), leaf * CFrame.new(0, py, 0), Color3.fromRGB(92, 70, 48), Enum.Material.Metal)
			end
			s(Vector3.new(0.3, 2.6, 0.9), leaf * CFrame.new(-side * (doorW / 4 - 1), 0, 0), GOLD, Enum.Material.Metal)
		end
		-- the grille over the doorway (in the stone above it)
		local gy = FLOOR + doorH + 4
		s(Vector3.new(doorW - 1, 6, 0.4), at(dx, gy, wallFace - 0.1), Color3.fromRGB(34, 28, 22), Enum.Material.Glass)
		for k = -3, 3 do
			s(Vector3.new(0.2, 6, 0.3), at(dx + k * 1.9, gy, wallFace - 0.3), BRONZE, Enum.Material.Metal)
		end
		s(Vector3.new(doorW, 0.4, 0.4), at(dx, gy - 3, wallFace - 0.3), GOLD, Enum.Material.Metal)
		s(Vector3.new(doorW, 0.4, 0.4), at(dx, gy + 3, wallFace - 0.3), GOLD, Enum.Material.Metal)
	end
	-- the columns: a moulded ring at the foot and under the capital, scrolls at the top
	for k = 0, 5 do
		local x = -W / 2 + 14 + k * (W - 28) / 5
		deco(dress, Vector3.new(1.2, 6.2, 6.2), at(x, FLOOR + H - 8.4, colZ) * CFrame.Angles(0, 0, math.rad(90)), TRIM, Enum.Material.Limestone, { shape = Enum.PartType.Cylinder })
		deco(dress, Vector3.new(1.2, 6.2, 6.2), at(x, FLOOR + 2.2, colZ) * CFrame.Angles(0, 0, math.rad(90)), TRIM, Enum.Material.Limestone, { shape = Enum.PartType.Cylinder })
		for _, sx in { -1, 1 } do
			deco(dress, Vector3.new(1.4, 1.8, 1.8), at(x + sx * 3.3, FLOOR + H - 7.2, colZ) * CFrame.Angles(0, math.rad(90), 0), TRIM, Enum.Material.Limestone, { shape = Enum.PartType.Cylinder })
		end
		-- warm uplights at each column's foot
		local up = s(Vector3.new(1, 0.4, 1), at(x, FLOOR + 0.4, colZ - 4.2), IRON, Enum.Material.Metal)
		lightOff(nil, kit.addLight("SpotLight", up, Color3.fromRGB(255, 214, 160), 46, 1.4, Enum.NormalId.Top, 28))
	end
	-- the entablature: an architrave under the name, dentils and a deep cornice over it
	local beamTop = FLOOR + H
	s(Vector3.new(W + 7, 1, 14.6), at(0, beamTop - 6.2, zFront + 4), TRIM)
	for x = -W / 2 - 2, W / 2 + 2, 3 do
		s(Vector3.new(1.2, 1.1, 1.2), at(x, beamTop + 0.15, zFront - 3.6), TRIM)
	end
	s(Vector3.new(W + 10, 1, 17), at(0, beamTop + 1.2, zFront + 4), TRIM)
	s(Vector3.new(W + 12, 0.6, 18.4), at(0, beamTop + 1.9, zFront + 4), TRIM)
	-- the pediment over the middle three bays, with a gold medallion
	local pw, ph = 74, 13
	local py = beamTop + 2.2
	local pz = zFront - 2.6
	for _, sx in { -1, 1 } do
		-- (a wedge's slope runs from its top-back edge down to its bottom-front edge: turned so
		-- the high side meets the middle)
		mk(dress, Vector3.new(3, ph, pw / 2), at(sx * pw / 4, py + ph / 2, pz) * CFrame.Angles(0, -sx * math.rad(90), 0), STONE, WALL, { class = "Wedge", collide = false, shadow = false })
		local len = math.sqrt((pw / 2) ^ 2 + ph ^ 2)
		local ang = math.atan2(ph, pw / 2)
		s(Vector3.new(len + 1.5, 1.2, 4), at(sx * pw / 4, py + ph / 2 + 0.6, pz) * CFrame.Angles(0, 0, -sx * ang), TRIM)
	end
	local medal = deco(dress, Vector3.new(0.6, 7, 7), at(0, py + ph * 0.36, pz - 1.6) * CFrame.Angles(0, math.rad(90), 0), GOLD, Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
	kit.surfaceText(medal, Enum.NormalId.Left, "L", Color3.fromRGB(70, 52, 24), nil, 1, Enum.Font.Garamond, Vector2.new(200, 200))
	-- a stone balustrade along the front of the roof
	local by = beamTop + 2.5
	s(Vector3.new(W + 4, 0.8, 2.4), at(0, by + 0.4, zFront + 9), TRIM)
	s(Vector3.new(W + 4, 0.7, 2.6), at(0, by + 4.1, zFront + 9), TRIM)
	for x = -W / 2, W / 2, 2.6 do
		deco(dress, Vector3.new(3, 1.2, 1.2), at(x, by + 2.3, zFront + 9) * CFrame.Angles(0, 0, math.rad(90)), TRIM, Enum.Material.Limestone, { shape = Enum.PartType.Cylinder })
	end
	-- two flagpoles on the roof with the bank's own flag (navy and gold)
	for _, sx in { -1, 1 } do
		local x = sx * (W / 2 - 6)
		deco(dress, Vector3.new(22, 0.5, 0.5), at(x, by + 11, zFront + 9) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(220, 220, 224), Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
		deco(dress, Vector3.new(1, 1, 1), at(x, by + 22.4, zFront + 9), GOLD, Enum.Material.Metal, { shape = Enum.PartType.Ball })
		local flag = s(Vector3.new(8, 5, 0.12), at(x - sx * 4.2, by + 19, zFront + 9) * CFrame.Angles(0, 0, sx * 0.04), Color3.fromRGB(22, 34, 72), Enum.Material.Fabric)
		s(Vector3.new(8, 0.6, 0.14), flag.CFrame * CFrame.new(0, 1.9, 0), GOLD, Enum.Material.Fabric)
		s(Vector3.new(8, 0.6, 0.14), flag.CFrame * CFrame.new(0, -1.9, 0), GOLD, Enum.Material.Fabric)
	end
	-- the side windows: stone hoods, sills, keystones and iron grilles; pilasters between them
	for _, sx in { -1, 1 } do
		local fx = sx * (W / 2 + 0.4)
		for k = -1, 1 do
			local z = k * 26
			s(Vector3.new(1.2, 1, 12.6), at(fx, FLOOR + 29.6, z), TRIM)
			s(Vector3.new(1.6, 0.8, 13.4), at(fx + sx * 0.2, FLOOR + 30.5, z), TRIM)
			s(Vector3.new(1.4, 2, 1.6), at(fx + sx * 0.3, FLOOR + 29.6, z), TRIM)
			s(Vector3.new(1.6, 0.9, 12.6), at(fx + sx * 0.2, FLOOR + 6.6, z), TRIM)
			for j = -2, 2 do
				s(Vector3.new(0.2, 21, 0.2), at(fx + sx * 0.3, FLOOR + 18, z + j * 1.9), IRON, Enum.Material.Metal)
			end
			for _, gy in { FLOOR + 10, FLOOR + 26 } do
				s(Vector3.new(0.2, 0.2, 10), at(fx + sx * 0.3, gy, z), IRON, Enum.Material.Metal)
			end
		end
		for _, z in { -39, -13, 13, 39 } do
			s(Vector3.new(1, H - 10, 3.6), at(sx * (W / 2 + 0.5), FLOOR + 9 + (H - 10) / 2, z), TRIM)
			s(Vector3.new(1.6, 1.4, 4.6), at(sx * (W / 2 + 0.8), FLOOR + H - 1.4, z), TRIM)
		end
	end
	-- the stair: stone cheek blocks at both ends with lanterns on iron posts
	for _, sx in { -1, 1 } do
		local x = sx * (W / 2 - 3)
		mk(dress, Vector3.new(6, 4.4, 20), at(x, 2.2, zFront - 12), STONE_DARK, Enum.Material.Limestone)
		s(Vector3.new(6.6, 0.6, 20.6), at(x, 4.7, zFront - 12), TRIM)
		for _, z in { zFront - 20, zFront - 4 } do
			s(Vector3.new(0.6, 9, 0.6), at(x, 9.5, z), IRON, Enum.Material.Metal)
			s(Vector3.new(1.4, 0.4, 1.4), at(x, 14.1, z), IRON, Enum.Material.Metal)
			local glass = s(Vector3.new(1.2, 2.2, 1.2), at(x, 15.4, z), Color3.fromRGB(255, 226, 170), Enum.Material.Glass)
			glass.Transparency = 0.2
			s(Vector3.new(1.6, 0.5, 1.6), at(x, 16.7, z), IRON, Enum.Material.Metal)
			lightOff(glass, kit.addLight("PointLight", glass, Color3.fromRGB(255, 210, 150), 18, 1))
		end
	end
	-- clipped box trees in stone planters on the plaza
	for _, x in { -48, -30, 30, 48 } do
		local z = zFront - 26
		mk(dress, Vector3.new(4.4, 3, 4.4), at(x, 1.5, z), TRIM, Enum.Material.Limestone)
		deco(dress, Vector3.new(4.6, 4.6, 4.6), at(x, 5.2, z), Color3.fromRGB(56, 84, 44), Enum.Material.Grass, { shape = Enum.PartType.Ball })
	end

	-------------------------------------------------------------------
	-- inside
	-------------------------------------------------------------------
	local hallFront, hallBack = zf + 1.5, vz - 1.5
	-- a dark marble border round the floor and a runner from the doors to the counter
	for _, z in { hallFront + 1.5, hallBack - 1.5 } do
		s(Vector3.new(W - 8, 0.08, 3), at(0, FLOOR + 0.26, z), MARBLE_DARK, Enum.Material.Marble)
	end
	for _, sx in { -1, 1 } do
		s(Vector3.new(3, 0.08, hallBack - hallFront), at(sx * (W / 2 - 5.5), FLOOR + 0.26, (hallFront + hallBack) / 2), MARBLE_DARK, Enum.Material.Marble)
	end
	s(Vector3.new(8, 0.1, cz2 - 3 - hallFront), at(0, FLOOR + 0.3, (hallFront + cz2 - 3) / 2), Color3.fromRGB(96, 24, 30), Enum.Material.Fabric)
	-- wood panelling on the lower walls, marble pilasters and a cornice at the ceiling
	for _, sx in { -1, 1 } do
		local ix = sx * (W / 2 - 3.2)
		s(Vector3.new(0.4, 6, hallBack - hallFront), at(ix, FLOOR + 3, (hallFront + hallBack) / 2), WOOD, Enum.Material.Wood)
		s(Vector3.new(0.6, 0.4, hallBack - hallFront), at(ix, FLOOR + 6.1, (hallFront + hallBack) / 2), GOLD, Enum.Material.Metal)
		for _, z in { -26, 0, 22 } do
			s(Vector3.new(0.8, H - 7, 3), at(sx * (W / 2 - 3.4), FLOOR + (H - 7) / 2, z - 13), TRIM, Enum.Material.Marble)
		end
		s(Vector3.new(1.4, 1.2, hallBack - hallFront), at(sx * (W / 2 - 3.6), FLOOR + H - 7, (hallFront + hallBack) / 2), TRIM)
	end
	s(Vector3.new(W - 6, 6, 0.4), at(0, FLOOR + 3, hallFront + 0.3), WOOD, Enum.Material.Wood)
	-- a coffered ceiling
	local ceilY = FLOOR + H - 6.9
	for x = -W / 2 + 10, W / 2 - 10, 12 do
		s(Vector3.new(1.2, 1, hallBack - hallFront), at(x, ceilY, (hallFront + hallBack) / 2), TRIM)
	end
	for z = hallFront + 6, hallBack - 4, 12 do
		s(Vector3.new(W - 8, 1, 1.2), at(0, ceilY, z), TRIM)
	end
	-- the teller counter: raised wood panels and brass on its front
	for k = -6, 6 do
		s(Vector3.new(6, 3, 0.3), at(k * 7.6, FLOOR + 2.2, cz2 - 2.1), Color3.fromRGB(110, 70, 42), Enum.Material.Wood)
	end
	s(Vector3.new(W - 40, 0.3, 0.4), at(0, FLOOR + 4.1, cz2 - 2.2), GOLD, Enum.Material.Metal)
	-- a queue line in front of it: brass posts and velvet ropes
	for k = -2, 2 do
		local x = k * 8
		deco(dress, Vector3.new(3.2, 0.5, 0.5), at(x, FLOOR + 1.6, cz2 - 9) * CFrame.Angles(0, 0, math.rad(90)), GOLD, Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
		deco(dress, Vector3.new(0.8, 0.8, 0.8), at(x, FLOOR + 3.3, cz2 - 9), GOLD, Enum.Material.Metal, { shape = Enum.PartType.Ball })
		if k < 2 then
			s(Vector3.new(7.4, 0.3, 0.3), at(x + 4, FLOOR + 2.6, cz2 - 9), Color3.fromRGB(120, 20, 30), Enum.Material.Fabric)
		end
	end
	-- a big clock over the vault
	local clock = deco(dress, Vector3.new(0.5, 7, 7), at(0, FLOOR + 30, vz - 1.9) * CFrame.Angles(0, math.rad(90), 0), Color3.fromRGB(244, 238, 222), Enum.Material.SmoothPlastic, { shape = Enum.PartType.Cylinder })
	deco(dress, Vector3.new(0.4, 7.8, 7.8), clock.CFrame * CFrame.new(0.1, 0, 0), GOLD, Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
	s(Vector3.new(0.3, 2.4, 0.2), at(0.5, FLOOR + 31, vz - 2.3) * CFrame.Angles(0, 0, math.rad(-25)), IRON, Enum.Material.Metal)
	s(Vector3.new(0.3, 3.2, 0.2), at(-0.8, FLOOR + 29.4, vz - 2.3) * CFrame.Angles(0, 0, math.rad(120)), IRON, Enum.Material.Metal)
	-- the vault: riveted steel cladding beside the round door, a VAULT plate, warning stripes
	for _, sx in { -1, 1 } do
		s(Vector3.new(4, 24, 1.2), at(sx * 14, FLOOR + 12, vz - 2.1), Color3.fromRGB(96, 100, 106), Enum.Material.DiamondPlate)
		for k = 0, 5 do
			s(Vector3.new(0.6, 0.6, 0.4), at(sx * 14, FLOOR + 2 + k * 4, vz - 2.8), STEEL, Enum.Material.Metal)
		end
	end
	local plate = s(Vector3.new(14, 2.4, 0.5), at(0, FLOOR + 23, vz - 2.2), Color3.fromRGB(40, 42, 46), Enum.Material.Metal)
	kit.surfaceText(plate, Enum.NormalId.Front, "VAULT", GOLD, nil, 1, Enum.Font.Garamond, Vector2.new(400, 70))
	for k = -6, 6 do
		s(Vector3.new(2, 0.06, 3), at(k * 2, FLOOR + 0.28, vz - 6), if k % 2 == 0 then Color3.fromRGB(230, 180, 30) else Color3.fromRGB(26, 26, 28), Enum.Material.SmoothPlastic)
	end
	-- the guard desk by the doors and CCTV in the corners
	local gx, gz = W / 2 - 16, hallFront + 10
	mk(dress, Vector3.new(10, 4, 3), at(gx, FLOOR + 2, gz), WOOD, Enum.Material.Wood)
	s(Vector3.new(10.4, 0.3, 3.4), at(gx, FLOOR + 4.15, gz), MARBLE, Enum.Material.Marble)
	for _, ox in { -2.4, 0, 2.4 } do
		s(Vector3.new(2.2, 1.5, 0.2), at(gx + ox, FLOOR + 5.2, gz + 0.8) * CFrame.Angles(math.rad(-10), 0, 0), Color3.fromRGB(40, 70, 110), Enum.Material.Glass)
	end
	for _, c in { { -W / 2 + 5, hallFront + 3 }, { W / 2 - 5, hallFront + 3 }, { -W / 2 + 5, vz - 4 }, { W / 2 - 5, vz - 4 } } do
		local y = FLOOR + H - 9
		s(Vector3.new(0.4, 0.4, 2), at(c[1], y + 0.6, c[2]), IRON, Enum.Material.Metal)
		local cam = s(Vector3.new(1.2, 1, 2.2), CFrame.lookAt(at(c[1], y, c[2]).Position, at(0, FLOOR + 4, (hallFront + vz) / 2).Position), Color3.fromRGB(230, 230, 232), Enum.Material.SmoothPlastic)
		s(Vector3.new(0.5, 0.5, 0.2), cam.CFrame * CFrame.new(0, 0, -1.15), Color3.fromRGB(14, 14, 16), Enum.Material.Glass)
	end
	-- a waiting area: leather sofas and palms from the kit
	kitPiece("Chesterfield", at(-W / 2 + 14, FLOOR + 0.3, hallFront + 18) * CFrame.Angles(0, math.rad(-90), 0), nil, dress)
	kitPiece("Armchair", at(-W / 2 + 22, FLOOR + 0.3, hallFront + 10) * CFrame.Angles(0, math.rad(-130), 0), nil, dress)
	for _, p in { { -W / 2 + 8, hallFront + 4 }, { W / 2 - 8, hallFront + 4 }, { -W / 2 + 8, cz2 - 4 }, { W / 2 - 8, cz2 - 4 } } do
		kitPiece("PottedPalm", at(p[1], FLOOR + 0.3, p[2]), nil, dress)
	end
end

---------------------------------------------------------------------
-- The building
---------------------------------------------------------------------
-- builds the bank when (bi, bj) is its block; returns true if it did
-- (CityBuilder asks this when baking the map: this block stays empty and is built at start)
function Bank.isBlock(bi: number, bj: number): boolean
	return bi == B.Block[1] and bj == B.Block[2]
end

function Bank.block(kit: any, parent: Instance, bi: number, bj: number, cx: number, cz: number, lot: number): boolean
	if not (bi == B.Block[1] and bj == B.Block[2]) then
		return false
	end
	local mk, deco = kit.mk, kit.deco
	local model = Instance.new("Model")
	model.Name = "LegendsReserveBank"
	model.Parent = parent
	local ground = C.CurbHeight
	-- the front looks at the city centre along X
	local front = if cx < 0 then Vector3.new(1, 0, 0) else Vector3.new(-1, 0, 0)
	local base = CFrame.lookAt(Vector3.new(cx, ground, cz), Vector3.new(cx, ground, cz) + front)
	-- (in Monaco when the Riviera is in the place: Config.RivieraVenues.Sites.bank)
	base = WestLayout.rivieraSite("bank") or base
	local function at(x: number, y: number, z: number): CFrame
		return base * CFrame.new(x, y, z) -- -z is the front
	end
	local W, D, H = 140, 100, 44 -- width, depth, wall height
	local FLOOR = 3.6
	local zFront, zBack = -D / 2, D / 2

	-- front plaza and steps
	mk(model, Vector3.new(W + 30, 0.4, lot / 2 - D / 2 + 10), at(0, 0.2, zFront - (lot / 2 - D / 2 + 10) / 2), Color3.fromRGB(120, 116, 110), Enum.Material.Pavement)
	for k = 1, 3 do
		local depth = 6
		mk(model, Vector3.new(W - 10, 1.2 * k, depth), at(0, 0.6 * k, zFront - 4 - (3 - k) * depth - depth / 2 + 2), STONE, WALL)
	end
	-- floor
	mk(model, Vector3.new(W, FLOOR, D), at(0, FLOOR / 2, 0), STONE_DARK, Enum.Material.Limestone)
	mk(model, Vector3.new(W - 4, 0.2, D - 4), at(0, FLOOR + 0.1, 0), MARBLE, Enum.Material.Marble, { name = "MarbleFloor" })
	-- marble floor inlay
	deco(model, Vector3.new(16, 0.05, 16), at(0, FLOOR + 0.22, -14) * CFrame.Angles(0, math.rad(45), 0), Color3.fromRGB(150, 130, 100), Enum.Material.Marble)

	local wallT = 3
	-- back and side walls
	mk(model, Vector3.new(W, H, wallT), at(0, FLOOR + H / 2, zBack - wallT / 2), STONE, WALL)
	for _, sx in { -1, 1 } do
		mk(model, Vector3.new(wallT, H, D), at(sx * (W / 2 - wallT / 2), FLOOR + H / 2, 0), STONE, WALL)
		-- tall windows on the sides
		for k = -1, 1 do
			deco(model, Vector3.new(0.3, 22, 10), at(sx * (W / 2 + 0.05), FLOOR + 18, k * 26), Color3.fromRGB(255, 214, 150), Enum.Material.Glass, { transparency = 0.25 })
			deco(model, Vector3.new(0.6, 24, 1.2), at(sx * (W / 2 + 0.2), FLOOR + 18, k * 26 - 5.6), STONE_DARK, Enum.Material.Limestone)
			deco(model, Vector3.new(0.6, 24, 1.2), at(sx * (W / 2 + 0.2), FLOOR + 18, k * 26 + 5.6), STONE_DARK, Enum.Material.Limestone)
		end
	end
	-- the front wall with three tall doorways
	local doorW, doorH = 14, 20
	local zf = zFront + 10
	local xs = { -W / 2, -doorW * 1.5 - 12, -doorW / 2 - 12, -doorW / 2, doorW / 2, doorW / 2 + 12, doorW * 1.5 + 12, W / 2 }
	-- solid pieces between the doorways
	local solid = { { -W / 2, -doorW * 1.5 - 12 }, { -doorW * 0.5 - 12, -doorW / 2 }, { doorW / 2, doorW / 2 + 12 }, { doorW * 1.5 + 12, W / 2 } }
	local _ = xs
	for _, r in solid do
		local w = r[2] - r[1]
		mk(model, Vector3.new(w, H, wallT), at((r[1] + r[2]) / 2, FLOOR + H / 2, zf), STONE, WALL)
	end
	for _, dx in { -(doorW + 12), 0, doorW + 12 } do
		mk(model, Vector3.new(doorW, H - doorH, wallT), at(dx, FLOOR + doorH + (H - doorH) / 2, zf), STONE, WALL)
		-- bronze door frames, warm light spilling out
		deco(model, Vector3.new(doorW + 1.5, 1.2, wallT + 0.4), at(dx, FLOOR + doorH + 0.6, zf), GOLD, Enum.Material.Metal)
		for _, s in { -1, 1 } do
			deco(model, Vector3.new(0.8, doorH, wallT + 0.4), at(dx + s * (doorW / 2 + 0.4), FLOOR + doorH / 2, zf), GOLD, Enum.Material.Metal)
		end
	end
	-- the portico: columns, beam and pediment
	local colZ = zFront + 2
	for k = 0, 5 do
		local x = -W / 2 + 14 + k * (W - 28) / 5
		mk(model, Vector3.new(H - 6, 5, 5), at(x, FLOOR + (H - 6) / 2, colZ) * CFrame.Angles(0, 0, math.rad(90)), TRIM, Enum.Material.Limestone, { shape = Enum.PartType.Cylinder })
		deco(model, Vector3.new(7, 1.6, 7), at(x, FLOOR + 0.8, colZ), STONE, WALL)
		deco(model, Vector3.new(7, 1.6, 7), at(x, FLOOR + H - 6.8, colZ), STONE, WALL)
	end
	local beam = mk(model, Vector3.new(W + 6, 6, 14), at(0, FLOOR + H - 3, zFront + 4), STONE, WALL, { name = "Beam" })
	kit.surfaceText(beam, Enum.NormalId.Front, "LEGENDS RESERVE BANK", GOLD, nil, 1, Enum.Font.Garamond, Vector2.new(1400, 80))
	-- the attic above the beam, stepped back
	mk(model, Vector3.new(W + 2, 5, 10), at(0, FLOOR + H + 2.5, zFront + 6), STONE_DARK, Enum.Material.Limestone, { name = "Attic" })
	deco(model, Vector3.new(W + 8, 0.8, 15), at(0, FLOOR + H + 0.4, zFront + 4), STONE, WALL)
	-- roof
	mk(model, Vector3.new(W + 2, 2, D + 2), at(0, FLOOR + H + 1, 0), STONE_DARK, Enum.Material.Limestone)
	-- floodlights washing the facade
	for _, x in { -W / 2 + 14, 0, W / 2 - 14 } do
		local lamp = deco(model, Vector3.new(1.4, 1, 1.4), at(x, 1, zFront - 16), Color3.fromRGB(30, 30, 34), Enum.Material.Metal)
		kit.addLight("SpotLight", lamp, Color3.fromRGB(255, 220, 170), 60, 3, Enum.NormalId.Back, 60)
	end

	-- inside: ceiling, chandeliers, counters
	deco(model, Vector3.new(W - 6, 1, D - 6), at(0, FLOOR + H - 6, 4), Color3.fromRGB(230, 222, 205), Enum.Material.SmoothPlastic)
	for _, z in { -14, 10 } do
		for _, x in { -36, 0, 36 } do
			local hub = deco(model, Vector3.new(1, 1, 1), at(x, FLOOR + H - 14, z), GOLD, Enum.Material.Metal, { transparency = 1 })
			deco(model, Vector3.new(0.3, 7, 0.3), at(x, FLOOR + H - 9.5, z), GOLD, Enum.Material.Metal)
			if not kitPiece("Chandelier", at(x, FLOOR + H - 20, z), 1.1, model) then
				-- (without the kit: a brass hub and a warm glass bowl)
				deco(model, Vector3.new(4, 2.4, 4), at(x, FLOOR + H - 12, z), GOLD, Enum.Material.Metal)
				deco(model, Vector3.new(5, 1.2, 5), at(x, FLOOR + H - 13.4, z), Color3.fromRGB(255, 236, 200), Enum.Material.Glass, { transparency = 0.2 })
			end
			kit.addLight("PointLight", hub, Color3.fromRGB(255, 220, 170), 34, 1.6)
		end
	end
	-- teller counter across the hall with glass screens
	local cz2 = 12
	mk(model, Vector3.new(W - 40, 4.6, 4), at(0, FLOOR + 2.3, cz2), WOOD, Enum.Material.Wood)
	deco(model, Vector3.new(W - 40, 0.4, 4.6), at(0, FLOOR + 4.8, cz2), MARBLE, Enum.Material.Marble)
	deco(model, Vector3.new(W - 40, 5, 0.2), at(0, FLOOR + 7.5, cz2 + 1), Color3.fromRGB(200, 220, 230), Enum.Material.Glass, { transparency = 0.7 })
	for k = -3, 3 do
		deco(model, Vector3.new(0.4, 5.4, 0.4), at(k * (W - 40) / 7, FLOOR + 7.5, cz2 + 1), GOLD, Enum.Material.Metal)
		local lx = k * (W - 40) / 7 + 3
		deco(model, Vector3.new(0.2, 0.9, 0.9), at(lx, FLOOR + 5.1, cz2) * CFrame.Angles(0, 0, math.rad(90)), GOLD, Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
		deco(model, Vector3.new(0.12, 1.1, 0.12), at(lx, FLOOR + 5.7, cz2), GOLD, Enum.Material.Metal)
		local lampP = deco(model, Vector3.new(1.6, 0.5, 0.7), at(lx, FLOOR + 6.35, cz2), Color3.fromRGB(30, 110, 64), Enum.Material.Glass, { transparency = 0.15 })
		kit.addLight("PointLight", lampP, Color3.fromRGB(255, 226, 170), 9, 0.7)
	end
	-- the vault wall at the back with the round door
	local vz = zBack - 22
	for _, r in { { -W / 2 + 3, -12 }, { 12, W / 2 - 3 } } do
		mk(model, Vector3.new(r[2] - r[1], H - 6, 3), at((r[1] + r[2]) / 2, FLOOR + (H - 6) / 2, vz), STEEL:Lerp(STONE, 0.6), Enum.Material.Concrete)
	end
	mk(model, Vector3.new(24, H - 6 - 20, 3), at(0, FLOOR + 20 + (H - 26) / 2, vz), STEEL:Lerp(STONE, 0.6), Enum.Material.Concrete)
	-- the vault room behind it
	mk(model, Vector3.new(W - 6, 0.2, 19), at(0, FLOOR + 0.1, vz + 10.5), Color3.fromRGB(60, 62, 66), Enum.Material.DiamondPlate)
	-- gold and cash shelves
	for _, x in { -40, -24, 24, 40 } do
		deco(model, Vector3.new(12, 0.6, 5), at(x, FLOOR + 3, zBack - 6), STEEL, Enum.Material.Metal)
		deco(model, Vector3.new(12, 0.6, 5), at(x, FLOOR + 7, zBack - 6), STEEL, Enum.Material.Metal)
		for k = -2, 2 do
			deco(model, Vector3.new(1.6, 0.8, 0.9), at(x + k * 2, FLOOR + 3.7, zBack - 6), Color3.fromRGB(255, 200, 60), Enum.Material.Foil)
			deco(model, Vector3.new(1.8, 1.2, 1.2), at(x + k * 2, FLOOR + 7.9, zBack - 6), Color3.fromRGB(70, 140, 80), Enum.Material.SmoothPlastic)
		end
	end
	local vaultLamp = deco(model, Vector3.new(2, 0.4, 2), at(0, FLOOR + 20, zBack - 10), Color3.fromRGB(255, 240, 210), Enum.Material.Glass)
	kit.addLight("PointLight", vaultLamp, Color3.fromRGB(255, 230, 190), 30, 1.2)

	-- the vault door: a thick steel disc hinged on its left edge
	local door = Instance.new("Model")
	door.Name = "VaultDoor"
	local R = 9.5
	local doorCF = at(0, FLOOR + 10.2, vz) * CFrame.Angles(0, math.rad(90), 0)
	local disc = mk(door, Vector3.new(3.2, R * 2, R * 2), doorCF, STEEL, Enum.Material.DiamondPlate, { shape = Enum.PartType.Cylinder, name = "Disc" })
	deco(door, Vector3.new(3.4, R * 2 - 3, R * 2 - 3), doorCF, Color3.fromRGB(120, 126, 134), Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
	-- the wheel and bolts on its face
	local face = at(0, FLOOR + 10.2, vz - 1.8)
	deco(door, Vector3.new(0.6, 6, 6), face * CFrame.Angles(0, math.rad(90), 0), GOLD, Enum.Material.Metal, { shape = Enum.PartType.Cylinder })
	for k = 0, 2 do
		deco(door, Vector3.new(0.5, 9, 0.6), face * CFrame.Angles(0, 0, math.rad(k * 60)), GOLD, Enum.Material.Metal)
	end
	for k = 0, 11 do
		local a = k * math.pi / 6
		deco(door, Vector3.new(0.8, 0.8, 0.6), face * CFrame.new(math.cos(a) * (R - 1.4), math.sin(a) * (R - 1.4), 0), GOLD, Enum.Material.Metal)
	end
	door.PrimaryPart = disc
	door.Parent = model
	vault.door = door
	vault.hinge = at(-R, FLOOR + 10.2, vz - 1.6)
	-- frame ring around the door
	deco(model, Vector3.new(3.6, R * 2 + 2.4, R * 2 + 2.4), doorCF * CFrame.new(0.4, 0, 0), Color3.fromRGB(60, 62, 66), Enum.Material.Metal, { shape = Enum.PartType.Cylinder })

	local promptPart = deco(model, Vector3.new(2, 2, 2), at(0, FLOOR + 5, vz - 5), Color3.new(), Enum.Material.SmoothPlastic, { transparency = 1 })
	promptPart.Name = "VaultPrompt"
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Crack the vault"
	prompt.ObjectText = "Legends Reserve Bank"
	prompt.HoldDuration = B.CrackSeconds
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = promptPart
	vault.prompt = prompt

	-- cash carts inside the vault
	for k, x in { -30, -10, 10, 30 } do
		local cart = deco(model, Vector3.new(5, 3.2, 3), at(x, FLOOR + 1.8, zBack - 12), Color3.fromRGB(60, 64, 70), Enum.Material.Metal)
		cart.Name = "CashCart" .. k
		for j = -1, 1 do
			deco(model, Vector3.new(1.4, 1, 2.4), at(x + j * 1.5, FLOOR + 3.9, zBack - 12), Color3.fromRGB(80, 160, 90), Enum.Material.SmoothPlastic)
		end
		local cp = Instance.new("ProximityPrompt")
		cp.ActionText = "Grab cash"
		cp.ObjectText = "Cash cart"
		cp.HoldDuration = B.GrabSeconds
		cp.MaxActivationDistance = 9
		cp.RequiresLineOfSight = false
		cp.Enabled = false
		cp.Parent = cart
		table.insert(vault.carts, cp)
	end

	Bank.dress(kit, model, at, { W = W, D = D, H = H, FLOOR = FLOOR, zFront = zFront, zBack = zBack, zf = zf, colZ = colZ, doorW = doorW, doorH = doorH, vz = vz, cz2 = cz2 })

	-- alarm: a bell and red lights
	local alarmPart = deco(model, Vector3.new(1, 1, 1), at(0, FLOOR + 30, 0), Color3.fromRGB(150, 0, 0), Enum.Material.SmoothPlastic, { transparency = 1 })
	local alarm = Instance.new("Sound")
	alarm.Name = "Alarm"
	alarm.SoundId = Config.Sounds.Alarm
	alarm.Looped = true
	alarm.Volume = 0.9
	alarm.RollOffMaxDistance = 600
	alarm.Parent = alarmPart
	vault.alarm = alarm
	for _, x in { -W / 2 + 6, W / 2 - 6 } do
		local beacon = deco(model, Vector3.new(1.2, 1.2, 1.2), at(x, FLOOR + H - 8, zFront + 14), Color3.fromRGB(120, 0, 0), Enum.Material.Glass)
		local l = Instance.new("PointLight")
		l.Color = Color3.fromRGB(255, 20, 20)
		l.Range = 40
		l.Brightness = 0
		l.Parent = beacon
		table.insert(vault.alarmLights, l)
	end
	return true
end

---------------------------------------------------------------------
-- The drop-off: a lock-up garage at the far corner of the city
---------------------------------------------------------------------
local function buildDropoff(parent: Instance)
	local i, j = B.Dropoff[1], B.Dropoff[2]
	local corner = CityLayout.intersectionPos(i, j)
	-- on the sidewalk at the block's corner, inside the grid
	local inward = Vector3.new(if i == 0 then 1 else -1, 0, if j == 0 then 1 else -1)
	local pos = corner + inward * (C.RoadWidth / 2 + 14)
	-- (in Monaco: a lot of its own at the far east end, Config.RivieraVenues.Sites.dropoff; the
	-- marker's height is added below as the kerb's, so the floor height comes off it here)
	local riv = WestLayout.rivieraSite("dropoff")
	if riv then
		pos = riv.Position - Vector3.new(0, C.CurbHeight, 0)
	end
	dropoff = pos
	local m = Instance.new("Model")
	m.Name = "Dropoff"
	local ring = Instance.new("Part")
	ring.Name = "Marker"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.3, 22, 22)
	ring.CFrame = CFrame.new(pos + Vector3.new(0, C.CurbHeight + 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Color = Color3.fromRGB(61, 255, 143)
	ring.Material = Enum.Material.Neon
	ring.Transparency = 0.55
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery = false
	ring.Parent = m
	local beam = Instance.new("Part")
	beam.Name = "Beam"
	beam.Shape = Enum.PartType.Cylinder
	beam.Size = Vector3.new(120, 3, 3)
	beam.CFrame = CFrame.new(pos + Vector3.new(0, 60, 0)) * CFrame.Angles(0, 0, math.rad(90))
	beam.Color = Color3.fromRGB(61, 255, 143)
	beam.Material = Enum.Material.Neon
	beam.Transparency = 0.7
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.Parent = m
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(220, 60)
	bb.StudsOffset = Vector3.new(0, 14, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 2500
	bb.Parent = ring
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.GothamBlack
	t.TextSize = 22
	t.TextColor3 = Color3.fromRGB(61, 255, 143)
	t.TextStrokeTransparency = 0.3
	t.Text = "DROP-OFF"
	t.Parent = bb
	m:SetAttribute("Dropoff", true)
	m.Parent = parent
	-- (owner, 2026-11-04: every venue you can drive onto) the paved pad to the road, over the kerb
	if riv then
		local inner = riv * CFrame.new(0, 0.2, -96)
		task.defer(function()
			EntranceRamp.build(m, inner, { width = 30, reach = 50, keep = { m } })
		end)
	end
end

---------------------------------------------------------------------
-- The robbery
---------------------------------------------------------------------
local function setVaultOpen(open: boolean)
	workspace:SetAttribute("LiveBank", open) -- (the live map markers: Minimap)
	local door = vault.door
	local hinge = vault.hinge
	if not (door and hinge) then
		return
	end
	-- swing the door round its hinge (each part tweened along the arc's end)
	local swing = if open then CFrame.Angles(0, math.rad(-100), 0) else CFrame.new()
	for _, p in door:GetDescendants() do
		if p:IsA("BasePart") then
			local home = p:GetAttribute("Home") :: CFrame?
			if not home then
				home = p.CFrame
				p:SetAttribute("Home", home)
			end
			local rel = hinge:ToObjectSpace(home :: CFrame)
			local goal = hinge * swing * rel
			TweenService:Create(p, TweenInfo.new(if open then 4 else 3, Enum.EasingStyle.Sine), { CFrame = goal }):Play()
		end
	end
	for _, cp in vault.carts do
		cp.Enabled = open
		cp:SetAttribute("Left", if open then B.GrabsPerCart else 0)
	end
	if vault.alarm then
		if open then
			vault.alarm:Play()
		else
			vault.alarm:Stop()
		end
	end
end

function Bank.init(ctx: any, Police: any)
	local BankEvent: RemoteEvent = ctx.remote("RemoteEvent", "BankEvent")
	buildDropoff(workspace:FindFirstChild("City") or workspace)
	workspace:SetAttribute("Dropoff", dropoff)

	local function setLoot(player: Player, amount: number)
		player:SetAttribute("Loot", if amount > 0 then amount else nil)
	end

	-- busted: the loot is gone
	table.insert(Police.onBusted, function(player: Player)
		if ((player:GetAttribute("Loot") :: number?) or 0) > 0 then
			setLoot(player, 0)
			BankEvent:FireClient(player, { kind = "lost" })
		end
	end)

	local prompt = vault.prompt
	if prompt then
		prompt.Triggered:Connect(function(who: Player)
			local now = os.clock()
			if now < vault.lockedUntil then
				return
			end
			vault.openUntil = now + B.OpenSeconds
			vault.lockedUntil = now + B.OpenSeconds + B.CooldownSeconds
			prompt.Enabled = false
			setVaultOpen(true)
			Police.setWanted(who, math.max(Police.getWanted(who), B.Stars), "bank")
			BankEvent:FireAllClients({ kind = "robbery", by = who.DisplayName })
		end)
	end
	for _, cp in vault.carts do
		cp.Triggered:Connect(function(who: Player)
			local left = (cp:GetAttribute("Left") :: number?) or 0
			if left <= 0 or os.clock() > vault.openUntil then
				return
			end
			local carried = (who:GetAttribute("Loot") :: number?) or 0
			if carried >= B.MaxLoot then
				BankEvent:FireClient(who, { kind = "full" })
				return
			end
			local grab = math.random(B.GrabMin, B.GrabMax)
			local profile = PlayerData.get(who)
			local level = if profile then (profile :: any).Level or 1 else 1
			grab = math.floor(grab * (1 + math.min(level, 50) * 0.02))
			local total = math.min(B.MaxLoot, carried + grab)
			setLoot(who, total)
			cp:SetAttribute("Left", left - 1)
			if left - 1 <= 0 then
				cp.Enabled = false
			end
			-- anyone grabbing is a robber too
			Police.setWanted(who, math.max(Police.getWanted(who), B.Stars), "bank")
			BankEvent:FireClient(who, { kind = "grab", amount = total - carried, total = total })
		end)
	end

	-- vault timers, the alarm lights and cashing in
	task.spawn(function()
		local blink = false
		while true do
			task.wait(0.25)
			local now = os.clock()
			local open = now < vault.openUntil
			if vault.openUntil > 0 and not open and vault.door and (vault.door :: any):GetAttribute("Open") then
				(vault.door :: any):SetAttribute("Open", false)
				setVaultOpen(false)
			elseif open and vault.door and not (vault.door :: any):GetAttribute("Open") then
				(vault.door :: any):SetAttribute("Open", true)
			end
			blink = not blink
			for _, l in vault.alarmLights do
				l.Brightness = if open and blink then 5 else 0
			end
			local p = vault.prompt
			if p then
				if now < vault.lockedUntil then
					p.Enabled = false
				else
					p.Enabled = true
				end
			end
			-- cashing in at the drop-off: in a car or on foot, with the police lost
			local drop = dropoff
			if drop then
				for _, player in Players:GetPlayers() do
					local loot = (player:GetAttribute("Loot") :: number?) or 0
					if loot > 0 then
						local pos: Vector3? = nil
						local car = ctx.getCar(player)
						local character = player.Character
						local hrp = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
						if hrp then
							pos = hrp.Position
						elseif car and car.PrimaryPart then
							pos = car.PrimaryPart.Position
						end
						if pos and Vector3.new(pos.X - drop.X, 0, pos.Z - drop.Z).Magnitude < B.DropoffRadius then
							if Police.getWanted(player) > 0 then
								if not player:GetAttribute("DropWarned") then
									player:SetAttribute("DropWarned", true)
									BankEvent:FireClient(player, { kind = "losecops" })
								end
							else
								player:SetAttribute("DropWarned", nil)
								setLoot(player, 0)
								PlayerData.addCash(player, loot)
								ctx.grantXp(player, B.DeliverXp, "bank")
								ctx.note(player, "bank", 1)
								task.spawn(PlayerData.save, player)
								BankEvent:FireClient(player, { kind = "paid", amount = loot })
							end
						else
							player:SetAttribute("DropWarned", nil)
						end
					end
				end
			end
		end
	end)
end

return Bank
