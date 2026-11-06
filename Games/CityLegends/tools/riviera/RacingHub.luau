--[[
	Racing Hub (Studio, Edit mode; owner 2026-11-06: "collect all of those racing areas and make a racing
	hub at the Old Rock place"). Dresses the palace square: an arch over the top of the ramp, a pad and a
	sign for each race (Config.Activities.Hub.Bays), flags, tyre stacks. The rings themselves and the
	trip to the start line are the game's (client/Activities.lua, server/Activities.lua). The square's
	two benches move out of the way (attribute OldCFrame).

	RacingHub.build(oldRock, races, checker) -> part count; races = ActivityData.races
	RacingHub.undo(oldRock)
]]

local CollectionService = game:GetService("CollectionService")

local RacingHub = {}

local Y = 52 -- the square's top
local DARK = Color3.fromRGB(30, 32, 38)
local STEEL = Color3.fromRGB(58, 62, 70)
local GOLD = Color3.fromRGB(255, 196, 64)
local WHITE = Color3.fromRGB(240, 240, 236)

local function part(parent: Instance, props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in props do
		(p :: any)[k] = v
	end
	p.Parent = parent
	return p
end

-- a sign face: text on the part's front
local function face(p: BasePart, canvas: Vector2, rows: { { text: string, y: number, h: number, color: Color3, font: Enum.Font } })
	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId.Front
	g.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	g.CanvasSize = canvas
	g.LightInfluence = 0.6
	g.MaxDistance = 400
	g.Parent = p
	for _, r in rows do
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Position = UDim2.fromScale(0.04, r.y)
		t.Size = UDim2.fromScale(0.92, r.h)
		t.Font = r.font
		t.Text = r.text
		t.TextColor3 = r.color
		t.TextScaled = true
		t.Parent = g
	end
end

local function checkerOn(p: BasePart, image: string, tile: number)
	for _, side in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local t = Instance.new("Texture")
		t.Face = side
		t.Texture = image
		t.StudsPerTileU = tile
		t.StudsPerTileV = tile
		t.Parent = p
	end
end

local function disc(parent: Instance, name: string, pos: Vector3, d: number, color: Color3, material: Enum.Material): Part
	return part(parent, {
		Name = name,
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.06, d, d),
		CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)),
		Color = color,
		Material = material,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
	})
end

local function tyres(parent: Instance, at: Vector3, n: number)
	for k = 0, n - 1 do
		local t = part(parent, {
			Name = "Tyre",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(1.1, 3.6, 3.6),
			CFrame = CFrame.new(at + Vector3.new(0, 0.55 + k * 1.1, 0)) * CFrame.Angles(0, 0, math.rad(90)),
			Color = if k % 2 == 0 then Color3.fromRGB(22, 22, 24) else WHITE,
			Material = Enum.Material.Rubber,
		})
		CollectionService:AddTag(t, "LOD")
	end
end

function RacingHub.undo(oldRock: Instance)
	local m = oldRock:FindFirstChild("RacingHub")
	if m then
		m:Destroy()
	end
	for _, d in oldRock:GetDescendants() do
		local cf = d:GetAttribute("OldCFrame")
		if typeof(cf) == "CFrame" and d:IsA("BasePart") then
			d.CFrame = cf
			d:SetAttribute("OldCFrame", nil)
		end
	end
end

function RacingHub.build(oldRock: Instance, races: { any }, checker: string): number
	RacingHub.undo(oldRock)
	local m = Instance.new("Model")
	m.Name = "RacingHub"

	-- the benches stood where the pads go
	local spots = { Vector3.new(12974, 0, 1240), Vector3.new(12974, 0, 1320) }
	local k = 0
	for _, d in oldRock:GetDescendants() do
		if d.Name == "Bench" and d:IsA("BasePart") and d.Position.X > 13000 and d.Position.X < 13040 then
			k += 1
			if spots[k] then
				d:SetAttribute("OldCFrame", d.CFrame)
				d.CFrame = CFrame.new(spots[k].X, d.Position.Y, spots[k].Z) * d.CFrame.Rotation
			end
		end
	end

	-- the arch over the top of the ramp
	local ax, az = 13032, 1333
	for _, sx in { -1, 1 } do
		part(m, { Name = "ArchPost", Size = Vector3.new(2.6, 24, 2.6), CFrame = CFrame.new(ax + sx * 21, Y + 12, az), Color = STEEL, Material = Enum.Material.Metal })
		part(m, { Name = "ArchFoot", Size = Vector3.new(4.4, 1.2, 4.4), CFrame = CFrame.new(ax + sx * 21, Y + 0.6, az), Color = DARK, Material = Enum.Material.Concrete })
		tyres(m, Vector3.new(ax + sx * 25, Y, az - 1), 4)
		tyres(m, Vector3.new(ax + sx * 25, Y, az + 2.6), 3)
	end
	local beam = part(m, { Name = "ArchSign", Size = Vector3.new(46, 7, 1.6), CFrame = CFrame.lookAt(Vector3.new(ax, Y + 21, az), Vector3.new(ax, Y + 21, az + 10)), Color = DARK, Material = Enum.Material.Concrete })
	local back = part(m, { Name = "ArchSignBack", Size = Vector3.new(46, 7, 0.2), CFrame = CFrame.lookAt(Vector3.new(ax, Y + 21, az - 0.91), Vector3.new(ax, Y + 21, az - 10)), Color = DARK, Material = Enum.Material.Concrete })
	for _, p in { beam, back } do
		face(p, Vector2.new(1314, 200), { { text = "RACING HUB", y = 0.12, h = 0.76, color = WHITE, font = Enum.Font.GothamBlack } })
	end
	local strip = part(m, { Name = "ArchChecker", Size = Vector3.new(46, 1.6, 1.8), CFrame = CFrame.new(ax, Y + 25.3, az), Color = WHITE })
	checkerOn(strip, checker, 1.6)
	part(m, { Name = "ArchEdge", Size = Vector3.new(46, 0.3, 1.8), CFrame = CFrame.new(ax, Y + 17.35, az), Color = GOLD, Material = Enum.Material.Metal })

	-- a pad and a sign for each race
	local bays = require(game:GetService("ReplicatedStorage").Shared.Config).Activities.Hub.Bays
	for n, r in races do
		local at: Vector3 = bays[r.id]
		if at then
			disc(m, "PadEdge", at + Vector3.new(0, 0.05, 0), 33.6, WHITE, Enum.Material.SmoothPlastic)
			disc(m, "Pad", at + Vector3.new(0, 0.13, 0), 32, Color3.fromRGB(46, 46, 50), Enum.Material.Asphalt)
			local s = at + Vector3.new(0, 0, -20)
			for _, sx in { -1, 1 } do
				part(m, { Name = "SignPost", Size = Vector3.new(0.8, 9, 0.8), CFrame = CFrame.new(s.X + sx * 7, Y + 4.5, s.Z - 0.7), Color = STEEL, Material = Enum.Material.Metal })
			end
			local board = part(m, { Name = "RaceSign", Size = Vector3.new(18, 6.4, 0.6), CFrame = CFrame.lookAt(s + Vector3.new(0, 7.6, 0), s + Vector3.new(0, 7.6, 10)), Color = DARK, Material = Enum.Material.Concrete })
			face(board, Vector2.new(720, 256), {
				{ text = "RACE " .. n, y = 0.06, h = 0.2, color = GOLD, font = Enum.Font.GothamBold },
				{ text = string.upper(r.name), y = 0.28, h = 0.38, color = WHITE, font = Enum.Font.GothamBlack },
				{ text = "STOP IN THE RING TO JOIN", y = 0.72, h = 0.16, color = Color3.fromRGB(190, 192, 200), font = Enum.Font.GothamMedium },
			})
			part(m, { Name = "SignEdge", Size = Vector3.new(18, 0.25, 0.7), CFrame = CFrame.new(s.X, Y + 4.3, s.Z), Color = GOLD, Material = Enum.Material.Metal })
		end
	end

	-- flags at the corners
	for _, c in { Vector2.new(12978, 1234), Vector2.new(12978, 1326), Vector2.new(13082, 1326) } do -- (the leaderboard has the fourth corner)
		part(m, { Name = "FlagPole", Shape = Enum.PartType.Cylinder, Size = Vector3.new(20, 0.5, 0.5), CFrame = CFrame.new(c.X, Y + 10, c.Y) * CFrame.Angles(0, 0, math.rad(90)), Color = STEEL, Material = Enum.Material.Metal })
		local flag = part(m, { Name = "Flag", Size = Vector3.new(7, 4.6, 0.06), CFrame = CFrame.new(c.X + 3.7, Y + 17.4, c.Y), Color = WHITE, CanCollide = false, CanQuery = false, CanTouch = false })
		checkerOn(flag, checker, 2.3)
		CollectionService:AddTag(flag, "LOD")
	end
	m.Parent = oldRock
	local n = 0
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			n += 1
		end
	end
	return n
end

return RacingHub
