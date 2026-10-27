-- Drawn art that needs no uploads: coach portrait cards (UI shapes), shoe models (parts, used in
-- shop displays and Locker previews), trail swatches. Same palette as everything else.
local Shared = script.Parent.Parent
local UIKit = require(Shared.UIKit)
local Coaches = require(Shared.Config.Coaches)

local P = UIKit.Palette
local make = UIKit.make
local Art = {}

-- Coach portrait: rarity-coloured disc, shoulders in the coach's top colour, head, hair, eyes,
-- and one prop hint (whistle, headband, stopwatch, braid, wind, sunrise band, cap, wings).
function Art.portrait(coach, size, parent, dark)
	local look = coach.Look
	local rc = Coaches.RarityColors[coach.Rarity]
	local root = make("Frame", { Name = "Portrait", BackgroundColor3 = P.White, Size = UDim2.fromOffset(size, size), ClipsDescendants = true, Parent = parent })
	UIKit.corner(root, UDim.new(0.5, 0))
	UIKit.gradient(root, rc:Lerp(P.White, 0.25), rc:Lerp(P.SpeedBlack, 0.45), 135)
	UIKit.stroke(root, rc, math.max(2, size / 22))
	local function shape(name, x, y, w, h, color, round, rot)
		local f = make("Frame", {
			Name = name,
			BackgroundColor3 = if dark then P.SpeedBlack else color,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(x, y),
			Size = UDim2.fromScale(w, h),
			Rotation = rot or 0,
			BorderSizePixel = 0,
			Parent = root,
		})
		if round then
			UIKit.corner(f, UDim.new(round, 0))
		end
		return f
	end
	shape("Shoulders", 0.5, 1.02, 0.86, 0.5, Color3.fromHex(look.Top), 0.45)
	shape("Neck", 0.5, 0.72, 0.18, 0.16, Color3.fromHex(look.Skin), 0.3)
	local head = shape("Head", 0.5, 0.47, 0.44, 0.48, Color3.fromHex(look.Skin), 0.5)
	shape("Hair", 0.5, 0.29, 0.46, 0.2, Color3.fromHex(look.Hair), 0.5)
	if not dark then
		shape("EyeL", 0.42, 0.5, 0.05, 0.06, P.SpeedBlack, 0.5)
		shape("EyeR", 0.58, 0.5, 0.05, 0.06, P.SpeedBlack, 0.5)
		shape("Smile", 0.5, 0.6, 0.12, 0.025, P.SpeedBlack, 0.5)
	end
	local prop = coach.Prop
	if prop == "Whistle" then
		shape("Lanyard", 0.5, 0.86, 0.36, 0.04, P.ElectricBlue, 0.5)
		shape("Whistle", 0.6, 0.9, 0.1, 0.07, P.Gold, 0.3)
	elseif prop == "Headband" then
		shape("Band", 0.5, 0.36, 0.48, 0.07, P.White, 0.3)
	elseif prop == "Stopwatch" then
		shape("Watch", 0.78, 0.86, 0.16, 0.16, P.Gold, 0.5)
	elseif prop == "Braid" then
		shape("Braid", 0.73, 0.62, 0.08, 0.3, Color3.fromHex(look.Hair), 0.5, 12)
	elseif prop == "Wind" then
		for i = 0, 2 do
			shape("Swoosh", 0.22 + i * 0.04, 0.35 + i * 0.12, 0.22, 0.03, P.BrightBlue, 0.5, -15)
		end
	elseif prop == "Barefoot" then
		shape("Sun", 0.2, 0.22, 0.18, 0.18, P.Gold, 0.5)
	elseif prop == "PocketWatch" then
		shape("Cap", 0.5, 0.24, 0.5, 0.12, P.Graphite, 0.3)
		shape("Brim", 0.5, 0.3, 0.56, 0.04, P.Graphite, 0.3)
	elseif prop == "Wings" then
		shape("WingL", 0.24, 0.3, 0.16, 0.08, P.Gold, 0.5, -30)
		shape("WingR", 0.76, 0.3, 0.16, 0.08, P.Gold, 0.5, 30)
	end
	return root, head
end

-- A small shoe model from parts in the pair's colours (sole, upper, stripe, toe cap, laces).
-- Used on the shop pedestals and in Locker previews.
function Art.shoeModel(shoe, scale, dark)
	scale = scale or 1
	local assets = game:GetService("ReplicatedStorage"):FindFirstChild("Assets")
	local lib = assets and assets:FindFirstChild("Shoes")
	local meshModel = lib and lib:FindFirstChild("Shoe_" .. shoe.Id)
	local template = meshModel and (if meshModel:IsA("MeshPart") then meshModel else meshModel:FindFirstChildWhichIsA("MeshPart"))
	if template then
		-- the Blender pair (1.55 long); the part version below is 2.2 long, so match its size
		local m = Instance.new("Model")
		m.Name = "Shoe_" .. shoe.Id
		local p = template:Clone()
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.Size = template.Size * (2.2 / template.Size.Z) * scale
		p.Color = if dark then P.SpeedBlack else Color3.new(1, 1, 1)
		if dark then
			p.Material = Enum.Material.SmoothPlastic
		end
		p.CFrame = CFrame.new(0, p.Size.Y / 2, 0)
		p.PivotOffset = CFrame.new(0, -p.Size.Y / 2, 0) -- pivot at the sole, like the part version
		p.Parent = m
		m.PrimaryPart = p
		return m
	end
	local c = shoe.Colors
	local m = Instance.new("Model")
	m.Name = "Shoe_" .. shoe.Id
	local function part(name, size, cf, hex, shape)
		local p = Instance.new("Part")
		p.Name = name
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.SmoothPlastic
		p.Color = if dark then P.SpeedBlack else Color3.fromHex(hex)
		if shape then
			p.Shape = shape
		end
		p.Size = size * scale
		p.CFrame = CFrame.new(cf.Position * scale) * cf.Rotation
		p.Parent = m
		return p
	end
	local base = part("Sole", Vector3.new(1.0, 0.22, 2.2), CFrame.new(0, 0.11, 0), c[1])
	part("Upper", Vector3.new(0.92, 0.55, 1.7), CFrame.new(0, 0.48, 0.18), c[2])
	part("Toe", Vector3.new(0.9, 0.36, 0.6), CFrame.new(0, 0.38, -0.82), c[2])
	part("Heel", Vector3.new(0.94, 0.75, 0.45), CFrame.new(0, 0.55, 0.88), c[2])
	part("Stripe", Vector3.new(0.96, 0.14, 1.1), CFrame.new(0, 0.42, 0.05) * CFrame.Angles(math.rad(12), 0, 0), c[3])
	part("Laces", Vector3.new(0.5, 0.06, 0.8), CFrame.new(0, 0.78, -0.15) * CFrame.Angles(math.rad(-14), 0, 0), "#F4F6FA")
	part("Tab", Vector3.new(0.3, 0.32, 0.12), CFrame.new(0, 0.95, 1.05), c[3])
	m.PrimaryPart = base
	return m
end

-- A trail swatch: a slanted ribbon with the trail's colour gradient
function Art.trailSwatch(trail, parent, dark)
	local holder = make("Frame", { Name = "Swatch", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ClipsDescendants = true, Parent = parent })
	for i = 0, 2 do
		local ribbon = make("Frame", {
			BackgroundColor3 = P.White,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.35 + i * 0.15),
			Size = UDim2.fromScale(1.3, 0.16 - i * 0.04),
			Rotation = -14,
			BackgroundTransparency = i * 0.25,
			Parent = holder,
		})
		UIKit.corner(ribbon, UDim.new(0.5, 0))
		local keys = {}
		for k, hex in trail.Colors do
			table.insert(keys, ColorSequenceKeypoint.new((k - 1) / math.max(1, #trail.Colors - 1), if dark then P.Graphite else Color3.fromHex(hex)))
		end
		make("UIGradient", { Color = ColorSequence.new(keys), Transparency = NumberSequence.new(1, 0), Parent = ribbon })
	end
	return holder
end

return Art
