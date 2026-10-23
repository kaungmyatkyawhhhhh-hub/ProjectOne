--[[
	Fountain (server)
	The city park's fountain (owner, 2026-10-23: "make the block_5_2 fountain better"): a round
	cobbled plaza with an eight-sided stone basin, clear water lit from below, a two-tier centre
	piece whose bowls spill water, a jet on top, small arcing jets from the rim, flower beds and
	benches round it. Built by CityBuilder's park(); `kit` is CityBuilder.kit.
]]

local Fountain = {}

local STONE = Color3.fromRGB(196, 190, 178)
local STONE_DARK = Color3.fromRGB(150, 145, 136)
local WATER = Color3.fromRGB(46, 120, 150)
local SPRAY = Color3.fromRGB(215, 235, 255)
local FLOWERS = { Color3.fromRGB(214, 60, 84), Color3.fromRGB(240, 196, 60), Color3.fromRGB(236, 120, 170), Color3.fromRGB(245, 245, 240) }

-- falling or spraying water: soft white-blue puffs; `dir` is where it shoots (world space)
local function spray(at: Attachment, rate: number, speed: number, size: number, spread: number)
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/smoke_main.dds"
	e.Color = ColorSequence.new(SPRAY)
	e.LightEmission = 0.35
	e.LightInfluence = 0.6
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(0.7, 0.55), NumberSequenceKeypoint.new(1, 1) })
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size * 0.5), NumberSequenceKeypoint.new(1, size) })
	e.Rate = rate
	e.Lifetime = NumberRange.new(0.9, 1.2)
	e.Speed = NumberRange.new(speed * 0.9, speed * 1.1)
	e.SpreadAngle = Vector2.new(spread, spread)
	e.Acceleration = Vector3.new(0, -28, 0)
	e.EmissionDirection = Enum.NormalId.Top
	e.Parent = at
	return e
end

local function attachment(part: BasePart, worldCf: CFrame): Attachment
	local a = Instance.new("Attachment")
	a.CFrame = part.CFrame:ToObjectSpace(worldCf)
	a.Parent = part
	return a
end

-- center: the middle of the fountain at ground level
function Fountain.build(kit: any, parent: Instance, center: Vector3)
	local mk, deco, addLight = kit.mk, kit.deco, kit.addLight
	local up = CFrame.Angles(0, 0, math.pi / 2) -- cylinders stand on end
	local function disc(r: number, h: number, y: number, color: Color3, mat: Enum.Material, collide: boolean?, transp: number?): BasePart
		local f = if collide then mk else deco
		return f(parent, Vector3.new(h, r * 2, r * 2), CFrame.new(center + Vector3.new(0, y + h / 2, 0)) * up, color, mat, { shape = Enum.PartType.Cylinder, transparency = transp })
	end
	-- the plaza and a darker ring of setts round the basin
	disc(34, 0.45, 0, Color3.fromRGB(122, 116, 106), Enum.Material.Cobblestone) -- (over the park paths)
	disc(19, 0.47, 0, Color3.fromRGB(92, 88, 82), Enum.Material.Cobblestone)
	-- the basin: eight stone walls with a wider cap, a dark floor and the water
	local R, wallH = 15, 2.4
	for k = 0, 7 do
		local a = k * math.pi / 4
		local side = 2 * R * math.tan(math.pi / 8) + 0.6
		local cf = CFrame.new(center + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, a, 0)
		mk(parent, Vector3.new(side, wallH, 1.6), cf * CFrame.new(0, wallH / 2, -R), STONE, Enum.Material.Limestone, { name = "FountainWall" })
		deco(parent, Vector3.new(side + 0.7, 0.45, 2.4), cf * CFrame.new(0, wallH + 0.22, -R), STONE_DARK, Enum.Material.Limestone, { shadow = true })
	end
	disc(R, 0.4, 0.3, Color3.fromRGB(28, 44, 52), Enum.Material.Slate)
	local water = disc(R - 0.6, 0.2, 1.9, WATER, Enum.Material.Glass, false, 0.25)
	water.Reflectance = 0.25
	-- lit from below: a soft cyan glow in the water and a warm uplight on the centre piece
	addLight("PointLight", water, Color3.fromRGB(90, 190, 230), 26, 0.9)
	-- the centre piece: a stepped plinth, a column, the big bowl, a thinner column, the small bowl
	disc(4, 1.6, 0.7, STONE_DARK, Enum.Material.Limestone, true)
	disc(1.6, 5, 2.3, STONE, Enum.Material.Limestone)
	local bowl1 = disc(6.5, 0.9, 7, STONE, Enum.Material.Limestone)
	disc(6.6, 0.35, 7.9, STONE_DARK, Enum.Material.Limestone)
	disc(5.9, 0.15, 7.75, WATER, Enum.Material.Glass, false, 0.2).Reflectance = 0.25
	disc(0.9, 3.6, 7.9, STONE, Enum.Material.Limestone)
	local bowl2 = disc(3.2, 0.7, 11.4, STONE, Enum.Material.Limestone)
	disc(3.3, 0.3, 12.1, STONE_DARK, Enum.Material.Limestone)
	local tip = deco(parent, Vector3.one * 1.2, CFrame.new(center + Vector3.new(0, 12.9, 0)), STONE, Enum.Material.Limestone, { shape = Enum.PartType.Ball })
	local uplight = addLight("SpotLight", tip, Color3.fromRGB(255, 226, 180), 22, 1.2, Enum.NormalId.Bottom, 70)
	kit.dayOff(tip, uplight)
	-- water: a jet out of the top, curtains spilling over both bowls, arcs from the rim inwards
	spray(attachment(tip, CFrame.new(center + Vector3.new(0, 13.2, 0))), 40, 20, 1.4, 6)
	for k = 0, 11 do
		local a = k * math.pi / 6
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local p1 = center + dir * 6.4 + Vector3.new(0, 8.1, 0)
		spray(attachment(bowl1, CFrame.lookAt(p1, p1 + dir) * CFrame.Angles(-math.pi / 2, 0, 0)), 10, 2, 1.1, 10)
		if k % 2 == 0 then
			local p2 = center + dir * 3.1 + Vector3.new(0, 12.2, 0)
			spray(attachment(bowl2, CFrame.lookAt(p2, p2 + dir) * CFrame.Angles(-math.pi / 2, 0, 0)), 10, 2, 0.9, 10)
		end
	end
	for k = 0, 7 do
		local a = (k + 0.5) * math.pi / 4
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local p = center + dir * (R - 0.8) + Vector3.new(0, 2.8, 0)
		-- aimed up and in, so the arcs land near the centre piece
		local aim = (-dir * 0.55 + Vector3.new(0, 1, 0)).Unit
		local nozzle = deco(parent, Vector3.new(0.5, 0.5, 0.5), CFrame.new(p), Color3.fromRGB(150, 140, 110), Enum.Material.Metal)
		spray(attachment(nozzle, CFrame.lookAt(p, p + aim) * CFrame.Angles(-math.pi / 2, 0, 0)), 18, 15, 0.7, 2)
	end
	-- flower beds between the paths and benches facing the water
	for k = 0, 3 do
		local a = k * math.pi / 2 + math.pi / 4
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local bed = center + dir * 25
		mk(parent, Vector3.new(1.2, 13, 13), CFrame.new(bed + Vector3.new(0, 0.6, 0)) * up, STONE_DARK, Enum.Material.Limestone, { shape = Enum.PartType.Cylinder })
		deco(parent, Vector3.new(0.3, 12, 12), CFrame.new(bed + Vector3.new(0, 1.25, 0)) * up, Color3.fromRGB(34, 54, 28), Enum.Material.LeafyGrass, { shape = Enum.PartType.Cylinder })
		-- low leafy shrubs with small flowers dotted over them
		for sh = 0, 2 do
			local sa = sh * 2.1 + k
			deco(parent, Vector3.one * 4.2, CFrame.new(bed + Vector3.new(math.cos(sa) * 2.6, 1.6, math.sin(sa) * 2.6)), Color3.fromRGB(46, 78, 38), Enum.Material.LeafyGrass, { shape = Enum.PartType.Ball })
		end
		for f = 1, 16 do
			local fa = f * 2.4 + k
			local fr = 1 + (f % 4) * 1.3
			deco(parent, Vector3.one * (0.7 + (f % 3) * 0.2), CFrame.new(bed + Vector3.new(math.cos(fa) * fr, 2.6 + (f % 2) * 0.5, math.sin(fa) * fr)), FLOWERS[(f + k) % #FLOWERS + 1], Enum.Material.SmoothPlastic, { shape = Enum.PartType.Ball })
		end
		local bdir = Vector3.new(math.cos(a - math.pi / 4), 0, math.sin(a - math.pi / 4))
		local bp = center + bdir * 21
		local bcf = CFrame.lookAt(bp, center)
		deco(parent, Vector3.new(7, 0.4, 1.9), bcf * CFrame.new(0, 1.6, 0), Color3.fromRGB(92, 64, 42), Enum.Material.WoodPlanks, { shadow = true })
		deco(parent, Vector3.new(7, 1.5, 0.3), bcf * CFrame.new(0, 2.6, 0.95), Color3.fromRGB(92, 64, 42), Enum.Material.WoodPlanks)
		for _, x in { -2.8, 2.8 } do
			deco(parent, Vector3.new(0.3, 1.5, 1.8), bcf * CFrame.new(x, 0.75, 0), Color3.fromRGB(30, 30, 34), Enum.Material.Metal)
		end
	end
end

return Fountain
