--[[
	Flex
	Builds the Gem Showcase's wearables (Config.Luxe.Items) out of small parts: chains, pendants,
	watches, rings, earrings, shades and crowns. Shared: the server welds them onto characters
	(everyone sees them), the shop shows them on velvet busts and in its previews.

	Flex.build(item, size) makes the parts round a body part of that size, in the body part's own
	space (front = -Z):
	  * Neck: round the torso (size = the torso's), the chain hanging on the chest
	  * Head / Eyes / Ears: round the head
	  * Wrist / Hand: a band round an arm or hand whose cross-section is size.X x size.Z, centred
	    on the origin (Flex.anchor gives the point on the arm)
	Flex.wear(character, item) builds and welds one onto a character (R15 or R6).
]]

local Config = require(script.Parent.Config)

local L = Config.Luxe

local Flex = {}

export type Item = {
	id: string,
	slot: string,
	name: string,
	price: number,
	metal: string,
	gem: string?,
	style: string,
}

Flex.ById = {} :: { [string]: Item }
for _, it in L.Items do
	Flex.ById[it.id] = it :: any
end

local function metalOf(item: Item): Color3
	return L.Metals[item.metal] or L.Metals.gold
end

local function gemOf(item: Item): Color3?
	return if item.gem then L.GemColors[item.gem] else nil
end

-- one small part, in the body part's space
local function piece(model: Model, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, shape: Enum.PartType?): BasePart
	local p = Instance.new("Part")
	p.Name = "Flex"
	if shape then
		p.Shape = shape
	end
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material
	p.Reflectance = if material == Enum.Material.Metal then 0.35 else 0
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

-- a cut gem: a glassy block turned on its corner, with a faint glow
local function gem(model: Model, s: number, cf: CFrame, color: Color3, glow: boolean?): BasePart
	local dark = color.R + color.G + color.B < 0.5
	local g = piece(model, Vector3.new(s, s, s * 0.6), cf * CFrame.Angles(0, 0, math.rad(45)), color, if dark then Enum.Material.Glass else Enum.Material.Neon)
	g.Transparency = if dark then 0 else 0.15
	g.Reflectance = if dark then 0.5 else 0
	if glow then
		local light = Instance.new("PointLight")
		light.Color = color
		light.Range = 5
		light.Brightness = 1.2
		light.Shadows = false
		light.Parent = g
	end
	return g
end

-- the sparkle on the costliest pieces
local function sparkle(part: BasePart, color: Color3)
	local s = Instance.new("Sparkles")
	s.SparkleColor = color
	s.TimeScale = 0.6
	s.Parent = part
end

-- points along a chain hanging on the chest: a U from one side of the neck to the other
local function chainCurve(S: Vector3, k: number, n: number, drop: number): (Vector3, Vector3)
	local a = -1 + 2 * k / n
	local x = a * S.X * 0.24
	local y = S.Y / 2 - 0.04 - (1 - a * a) * drop
	local z = -S.Z / 2 - 0.05 - 0.03 * (1 - a * a)
	-- the tangent (for links that line up along the chain)
	local da = 2 / n
	local x2 = (a + da) * S.X * 0.24
	local y2 = S.Y / 2 - 0.04 - (1 - (a + da) * (a + da)) * drop
	return Vector3.new(x, y, z), Vector3.new(x2 - x, y2 - y, 0)
end

local function neck(model: Model, item: Item, S: Vector3)
	local metal = metalOf(item)
	local g = gemOf(item)
	local style = item.style
	local drop = if style == "chain" or style == "cuban" then S.Y * 0.3 else S.Y * 0.36
	local n = if style == "cuban" then 16 else 20
	local last = Vector3.zero
	for k = 0, n do
		local p, t = chainCurve(S, k, n, drop)
		last = if k == n // 2 then p else last
		local cf = CFrame.lookAt(p, p + Vector3.new(0, 0, -1), t.Unit) -- link along the chain
		if style == "cuban" then
			piece(model, Vector3.new(0.13, 0.2, 0.07), cf, metal, Enum.Material.Metal)
			if g then
				gem(model, 0.07, cf * CFrame.new(0, 0, -0.04), g)
			end
		else
			piece(model, Vector3.new(0.09, 0.09, 0.09), cf, metal, Enum.Material.Metal, Enum.PartType.Ball)
		end
	end
	if style == "pendant" or style == "star" then
		-- the pendant below the chain's lowest point
		local base = CFrame.new(last + Vector3.new(0, -0.22, -0.03))
		local gc = g or Color3.new(1, 1, 1)
		if style == "star" then
			for k = 0, 4 do
				piece(model, Vector3.new(0.09, 0.42, 0.06), base * CFrame.Angles(0, 0, math.rad(k * 72)) * CFrame.new(0, 0.14, 0), L.Metals.white, Enum.Material.Metal)
			end
			local core = gem(model, 0.24, base * CFrame.new(0, 0, -0.04), gc, true)
			sparkle(core, gc)
		else
			piece(model, Vector3.new(0.34, 0.34, 0.06), base * CFrame.Angles(0, 0, math.rad(45)), metal, Enum.Material.Metal)
			local core = gem(model, 0.2, base * CFrame.new(0, 0, -0.04), gc, item.price >= 2000000)
			if item.price >= 2000000 then
				sparkle(core, gc)
			end
		end
		piece(model, Vector3.new(0.05, 0.12, 0.05), CFrame.new(last + Vector3.new(0, -0.07, -0.03)), metal, Enum.Material.Metal)
	end
end

-- a band round an arm or a hand (cross-section S.X x S.Z), centred on the origin
local function band(model: Model, S: Vector3, h: number, metal: Color3, grow: number)
	local w, d = S.X + grow, S.Z + grow
	local t = 0.06
	piece(model, Vector3.new(w, h, t), CFrame.new(0, 0, -d / 2), metal, Enum.Material.Metal)
	piece(model, Vector3.new(w, h, t), CFrame.new(0, 0, d / 2), metal, Enum.Material.Metal)
	piece(model, Vector3.new(t, h, d), CFrame.new(-w / 2, 0, 0), metal, Enum.Material.Metal)
	piece(model, Vector3.new(t, h, d), CFrame.new(w / 2, 0, 0), metal, Enum.Material.Metal)
end

local function wrist(model: Model, item: Item, S: Vector3)
	local metal = metalOf(item)
	local g = gemOf(item)
	band(model, S, 0.22, metal, 0.08)
	-- the watch face on the outside of the arm (-X)
	-- (a cylinder's round faces point along its X)
	piece(model, Vector3.new(0.08, 0.42, 0.42), CFrame.new(-(S.X / 2 + 0.1), 0, 0), metal, Enum.Material.Metal, Enum.PartType.Cylinder)
	local dial = piece(model, Vector3.new(0.02, 0.34, 0.34), CFrame.new(-(S.X / 2 + 0.145), 0, 0), if item.metal == "gold" then Color3.fromRGB(40, 30, 20) else Color3.fromRGB(16, 22, 40), Enum.Material.Glass, Enum.PartType.Cylinder)
	dial.Reflectance = 0.4
	-- hands
	piece(model, Vector3.new(0.01, 0.14, 0.02), CFrame.new(-(S.X / 2 + 0.16), 0.05, 0), Color3.new(1, 1, 1), Enum.Material.Neon)
	piece(model, Vector3.new(0.01, 0.02, 0.11), CFrame.new(-(S.X / 2 + 0.16), 0, 0.04), Color3.new(1, 1, 1), Enum.Material.Neon)
	if g then
		-- an iced bezel
		for k = 0, 11 do
			local a = k * math.pi / 6
			gem(model, 0.05, CFrame.new(-(S.X / 2 + 0.15), math.cos(a) * 0.19, math.sin(a) * 0.19), g)
		end
		if item.price >= 2000000 then
			sparkle(dial, g)
		end
	end
end

local function hand(model: Model, item: Item, S: Vector3)
	local metal = metalOf(item)
	local g = gemOf(item)
	band(model, Vector3.new(S.X * 0.55, S.Y, S.Z), 0.08, metal, 0.04)
	local top = CFrame.new(0, 0, -(S.Z / 2 + 0.06))
	if g then
		piece(model, Vector3.new(0.16, 0.16, 0.05), top, metal, Enum.Material.Metal)
		local stone = gem(model, 0.12, top * CFrame.new(0, 0, -0.04), g, item.price >= 2000000)
		if item.price >= 2000000 then
			sparkle(stone, g)
		end
	else
		-- a signet: a flat engraved top
		piece(model, Vector3.new(0.18, 0.14, 0.05), top, metal, Enum.Material.Metal)
		piece(model, Vector3.new(0.1, 0.07, 0.01), top * CFrame.new(0, 0, -0.03), metal:Lerp(Color3.new(0, 0, 0), 0.4), Enum.Material.Metal)
	end
end

local function head(model: Model, item: Item, S: Vector3)
	local metal = metalOf(item)
	local g = gemOf(item)
	if item.style == "studs" then
		for _, s in { -1, 1 } do
			local stud = gem(model, 0.13, CFrame.new(s * (S.X / 2 + 0.02), -S.Y * 0.08, 0.04), g or Color3.new(1, 1, 1))
			if item.price >= 1000000 then
				sparkle(stud, g or Color3.new(1, 1, 1))
			end
		end
	elseif item.style == "shades" then
		local y, z = S.Y * 0.1, -S.Z / 2 - 0.04
		for _, s in { -1, 1 } do
			local lens = piece(model, Vector3.new(S.X * 0.34, S.Y * 0.2, 0.04), CFrame.new(s * S.X * 0.21, y, z), Color3.fromRGB(14, 14, 20), Enum.Material.Glass)
			lens.Reflectance = 0.5
			lens.Transparency = 0.1
			-- frame round each lens
			piece(model, Vector3.new(S.X * 0.36, 0.04, 0.05), CFrame.new(s * S.X * 0.21, y + S.Y * 0.105, z), metal, Enum.Material.Metal)
			piece(model, Vector3.new(S.X * 0.36, 0.03, 0.05), CFrame.new(s * S.X * 0.21, y - S.Y * 0.105, z), metal, Enum.Material.Metal)
			-- the arm back to the ear
			piece(model, Vector3.new(0.04, 0.04, S.Z * 0.9), CFrame.new(s * (S.X / 2 + 0.02), y + S.Y * 0.08, -S.Z * 0.05), metal, Enum.Material.Metal)
			if g then
				for k = -2, 2 do
					gem(model, 0.04, CFrame.new(s * S.X * 0.21 + k * S.X * 0.07, y + S.Y * 0.12, z - 0.03), g)
				end
			end
		end
		piece(model, Vector3.new(S.X * 0.1, 0.04, 0.05), CFrame.new(0, y + S.Y * 0.06, z), metal, Enum.Material.Metal)
	elseif item.style == "crown" then
		local r = S.X * 0.46
		local y = S.Y / 2 + 0.06
		local n = 14
		for k = 0, n - 1 do
			local a = k / n * math.pi * 2
			local p = Vector3.new(math.cos(a) * r, y, math.sin(a) * r)
			local cf = CFrame.lookAt(p, Vector3.new(0, y, 0))
			piece(model, Vector3.new(r * 2 * math.pi / n + 0.02, 0.22, 0.05), cf, metal, Enum.Material.Metal)
			if k % 2 == 0 then
				-- a point with a jewel on it
				piece(model, Vector3.new(0.1, 0.3, 0.05), cf * CFrame.new(0, 0.24, 0), metal, Enum.Material.Metal)
				piece(model, Vector3.new(0.09, 0.09, 0.09), cf * CFrame.new(0, 0.42, 0), metal, Enum.Material.Metal, Enum.PartType.Ball)
			end
			if g then
				gem(model, 0.08, cf * CFrame.new(0, 0, -0.04), if k % 2 == 0 then g else L.GemColors.diamond)
			end
		end
		-- the velvet cap inside and the big stone on the front
		piece(model, Vector3.new(0.3, r * 1.9, r * 1.9), CFrame.new(0, y + 0.1, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(110, 10, 30), Enum.Material.Fabric, Enum.PartType.Cylinder)
		local stone = gem(model, 0.2, CFrame.new(0, y + 0.02, -r - 0.06), g or L.GemColors.diamond, true)
		sparkle(stone, g or L.GemColors.diamond)
	end
end

-- builds an item round a body part of size S (in that body part's own space)
function Flex.build(item: Item, S: Vector3): Model
	local model = Instance.new("Model")
	model.Name = "Flex_" .. item.slot
	if item.slot == "Neck" then
		neck(model, item, S)
	elseif item.slot == "Wrist" then
		wrist(model, item, S)
	elseif item.slot == "Hand" then
		hand(model, item, S)
	else
		head(model, item, S)
	end
	return model
end

-- the body part an item goes on, its size and the item's origin on it
function Flex.anchor(character: Model, slot: string): (BasePart?, Vector3, CFrame)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local r15 = humanoid ~= nil and humanoid.RigType == Enum.HumanoidRigType.R15
	local function part(name: string): BasePart?
		local p = character:FindFirstChild(name)
		return if p and p:IsA("BasePart") then p else nil
	end
	if slot == "Neck" then
		local torso = part(if r15 then "UpperTorso" else "Torso")
		return torso, if torso then torso.Size else Vector3.one, CFrame.new()
	elseif slot == "Wrist" then
		local arm = part(if r15 then "LeftLowerArm" else "Left Arm")
		if not arm then
			return nil, Vector3.one, CFrame.new()
		end
		local s = arm.Size
		return arm, s, CFrame.new(0, -s.Y / 2 + (if r15 then 0.12 else 0.45), 0)
	elseif slot == "Hand" then
		local h = part(if r15 then "RightHand" else "Right Arm")
		if not h then
			return nil, Vector3.one, CFrame.new()
		end
		local s = h.Size
		return h, s, CFrame.new(0, -s.Y / 2 + (if r15 then s.Y * 0.3 else 0.2), 0)
	end
	local headPart = part("Head")
	local size = if headPart then headPart.Size else Vector3.one
	-- R15 heads are mesh heads round the face: treat them as about 1.2 studs across
	if r15 then
		size = Vector3.new(math.min(size.X, 1.25), math.min(size.Y, 1.25), math.min(size.Z, 1.25))
	end
	return headPart, size, CFrame.new()
end

-- puts an item on a character (welded, massless, seen by everyone); replaces that slot's old one
function Flex.wear(character: Model, item: Item)
	local old = character:FindFirstChild("Flex_" .. item.slot)
	if old then
		old:Destroy()
	end
	local anchor, size, offset = Flex.anchor(character, item.slot)
	if not anchor then
		return
	end
	local model = Flex.build(item, size)
	local base = anchor.CFrame * offset
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.CFrame = base * p.CFrame
			p.Anchored = false
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = anchor
			weld.Part1 = p
			weld.Parent = p
		end
	end
	model.Parent = character
end

function Flex.remove(character: Model, slot: string)
	local old = character:FindFirstChild("Flex_" .. slot)
	if old then
		old:Destroy()
	end
end

return Flex
