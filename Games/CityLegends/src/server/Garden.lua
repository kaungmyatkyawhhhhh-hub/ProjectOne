--[[
	Garden
	Plaza dressing shared by the Downtown venues (Legends Rewards, the Gem Showcase): a palm tree and
	a marble fountain. (Moved out of the old Casino module, 2026-11-03.)
]]

local Garden = {}

local MARBLE = Color3.fromRGB(236, 232, 224)

-- a palm tree: a gently curved, ringed trunk and drooping fronds
function Garden.palm(kit: any, parent: Instance, pos: Vector3, h: number, seed: number)
	local rng = Random.new(seed)
	local lean = rng:NextNumber(0, math.pi * 2)
	local leanDir = Vector3.new(math.cos(lean), 0, math.sin(lean))
	local segs = 6
	local prev = pos
	local trunk = Color3.fromRGB(120, 98, 72)
	for k = 1, segs do
		local t = k / segs
		local p = pos + Vector3.new(0, h * t, 0) + leanDir * (t * t * h * 0.12)
		local mid = (prev + p) / 2
		local len = (p - prev).Magnitude
		local r = 1.5 - t * 0.5
		kit.deco(parent, Vector3.new(len + 0.2, r * 2, r * 2), CFrame.lookAt(mid, p) * CFrame.Angles(0, math.rad(90), 0), trunk:Lerp(Color3.fromRGB(90, 72, 54), t), Enum.Material.Wood, { shape = Enum.PartType.Cylinder, shadow = true })
		prev = p
	end
	local top = prev
	-- fronds: each two long thin leaves bending down
	for k = 0, 8 do
		local a = k / 9 * math.pi * 2 + rng:NextNumber(-0.2, 0.2)
		local dir = Vector3.new(math.cos(a), 0, math.sin(a))
		local green = Color3.fromRGB(34, 96, 44):Lerp(Color3.fromRGB(70, 130, 50), rng:NextNumber())
		local p1 = top + dir * 4 + Vector3.new(0, 1.2, 0)
		local p2 = top + dir * 9.5 - Vector3.new(0, 2.6, 0)
		kit.deco(parent, Vector3.new(2.6, 0.25, (p1 - top).Magnitude + 0.5), CFrame.lookAt((top + p1) / 2, p1), green, Enum.Material.Grass, { shadow = true })
		kit.deco(parent, Vector3.new(2.2, 0.25, (p2 - p1).Magnitude + 0.5), CFrame.lookAt((p1 + p2) / 2, p2), green, Enum.Material.Grass, { shadow = true })
	end
	for k = 0, 2 do
		local a = k * 2.1
		kit.deco(parent, Vector3.one * 0.9, CFrame.new(top + Vector3.new(math.cos(a) * 0.8, -0.8, math.sin(a) * 0.8)), Color3.fromRGB(70, 50, 30), Enum.Material.Wood, { shape = Enum.PartType.Ball })
	end
end

-- a fountain: a marble basin, glowing water, a spray
function Garden.fountain(kit: any, parent: Instance, cf: CFrame, r: number)
	local mk, deco = kit.mk, kit.deco
	mk(parent, Vector3.new(2.4, r * 2, r * 2), cf * CFrame.new(0, 1.2, 0) * CFrame.Angles(0, 0, math.rad(90)), MARBLE, Enum.Material.Marble, { shape = Enum.PartType.Cylinder, name = "Fountain" })
	local water = deco(parent, Vector3.new(0.3, r * 2 - 2, r * 2 - 2), cf * CFrame.new(0, 2.3, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(40, 160, 255), Enum.Material.Glass, { shape = Enum.PartType.Cylinder, transparency = 0.35 })
	water.Reflectance = 0.3
	kit.addLight("PointLight", water, Color3.fromRGB(60, 190, 255), r * 1.6, 1.4)
	mk(parent, Vector3.new(5, 2, 2), cf * CFrame.new(0, 3.5, 0) * CFrame.Angles(0, 0, math.rad(90)), MARBLE, Enum.Material.Marble, { shape = Enum.PartType.Cylinder })
	local bowl = deco(parent, Vector3.new(0.8, 6, 6), cf * CFrame.new(0, 6.2, 0) * CFrame.Angles(0, 0, math.rad(90)), MARBLE, Enum.Material.Marble, { shape = Enum.PartType.Cylinder })
	local spray = Instance.new("ParticleEmitter")
	spray.Color = ColorSequence.new(Color3.fromRGB(200, 235, 255))
	spray.LightEmission = 0.6
	spray.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	spray.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1.4) })
	spray.Lifetime = NumberRange.new(1.1, 1.5)
	spray.Rate = 70
	spray.Speed = NumberRange.new(16, 20)
	spray.SpreadAngle = Vector2.new(9, 9)
	spray.Acceleration = Vector3.new(0, -34, 0)
	spray.EmissionDirection = Enum.NormalId.Right -- (the bowl is a cylinder lying along X: +X is up)
	spray.Parent = bowl
end

return Garden
