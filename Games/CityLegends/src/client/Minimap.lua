--[[
	Minimap (client)
	A round minimap like Highway Legends / GTA (owner, 2026-10-23: "add a mini map to the game"):
	bottom left, clear of the side buttons, the cash pill and the rev counter (on phones: above the
	steering arrows). It turns with the camera (the way you look is up, an N marks north), the
	player's arrow sits in the middle, and it zooms out the faster you go.

	The map is drawn once from the real layout (Config.City, CityLayout, Config.West, WestLayout):
	water and land, the city and Downtown grids, the east highway, the Legends Loop, the coastal
	highway, the causeway, the island bridges and ring roads. About 90 frames, in world studs, under
	one pivot frame; each frame only that pivot turns and one container moves, and a UIScale zooms.
	A CanvasGroup with round corners clips it (ClipsDescendants doesn't clip turned frames).

	Blips (kept upright, on a layer above): police cars, the bank drop-off while you carry loot,
	the race checkpoint or delivery drop (held on the rim when far), and the landmarks (bank,
	towers, hotel, casino, gem showcase, chauffeur stands, Downtown, the beach and the islands).
	The rim flashes red and blue while you're wanted. N shows / hides it; on a phone a tap on it
	switches to a bigger map.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local CityLayout = require(Shared:WaitForChild("CityLayout"))
local WestLayout = require(Shared:WaitForChild("WestLayout"))
local ActivityData = require(Shared:WaitForChild("ActivityData"))

local Driving = require(script.Parent:WaitForChild("Driving"))
local Police = require(script.Parent:WaitForChild("Police"))
local Activities = require(script.Parent:WaitForChild("Activities"))

local Minimap = {}

local player = Players.LocalPlayer
local C = Config.City
local W = Config.West
local MM = Config.Minimap
local Theme = Config.Theme

local N = C.Blocks
local HR = C.RoadWidth / 2
local HW = C.HighwayWidth / 2

local isTouch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- colours: a dark night map with light roads (like the HUD)
local COL = {
	back = Color3.fromRGB(22, 28, 30), -- land
	water = Color3.fromRGB(14, 34, 58),
	block = Color3.fromRGB(36, 40, 50), -- city blocks
	sand = Color3.fromRGB(78, 72, 56),
	road = Color3.fromRGB(128, 136, 154),
	highway = Color3.fromRGB(196, 180, 128),
	island = Color3.fromRGB(40, 58, 42),
}

---------------------------------------------------------------------
-- Drawing the map (world studs: x right, z down = north up)
---------------------------------------------------------------------
local function rect(parent: Instance, x0: number, z0: number, x1: number, z1: number, color: Color3, z: number)
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	f.BackgroundColor3 = color
	f.Position = UDim2.fromOffset(math.min(x0, x1), math.min(z0, z1))
	f.Size = UDim2.fromOffset(math.abs(x1 - x0), math.abs(z1 - z0))
	f.ZIndex = z
	f.Parent = parent
end

local function line(parent: Instance, a: Vector3, b: Vector3, width: number, color: Color3, z: number)
	local d = Vector2.new(b.X - a.X, b.Z - a.Z)
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	f.BackgroundColor3 = color
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Z + b.Z) / 2)
	-- a little longer, so pieces meet without gaps at bends
	f.Size = UDim2.fromOffset(d.Magnitude + width * 0.5, width)
	f.Rotation = math.deg(math.atan2(d.Y, d.X))
	f.ZIndex = z
	f.Parent = parent
end

local function disc(parent: Instance, c: Vector3, r: number, color: Color3, z: number): Frame
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	f.BackgroundColor3 = color
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromOffset(c.X, c.Z)
	f.Size = UDim2.fromOffset(r * 2, r * 2)
	f.ZIndex = z
	local k = Instance.new("UICorner")
	k.CornerRadius = UDim.new(0.5, 0)
	k.Parent = f
	f.Parent = parent
	return f
end

-- a ring road: a circle's outline (the stroke sits outside the frame's edge)
local function ringRoad(parent: Instance, c: Vector3, r: number, width: number, color: Color3, z: number)
	local f = disc(parent, c, r - width / 2, color, z)
	f.BackgroundTransparency = 1
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = width
	s.Parent = f
end

local function drawMap(map: Frame)
	local E = C.HalfExtent + HR -- the city's road edge
	local O = E + C.OuterRingDepth -- the city island's edge
	local Wh = O + 1500 -- the harbour's outer edge
	-- water: the harbour round the city, the river, the sea
	rect(map, -Wh, -Wh, Wh, Wh, COL.water, 1)
	rect(map, -O, -O, O, O, COL.back, 2)
	rect(map, O, -O, Wh, O, COL.back, 2) -- the east spur is land
	rect(map, W.River[2], -W.HalfZ - 1600, W.River[1], W.HalfZ + 1600, COL.water, 2)
	rect(map, W.SeaWest, -W.HalfZ - 1600, W.BeachWest, W.HalfZ + 1600, COL.water, 2)
	rect(map, WestLayout.DowntownWest, -W.HalfZ, W.BeachWest, W.HalfZ, COL.sand, 3)

	-- the two street grids: blocks, then their roads
	for _, ib in CityLayout.GridBases do
		local x0, x1 = CityLayout.roadCoord(ib) - HR, CityLayout.roadCoord(ib + N) + HR
		local z0, z1 = CityLayout.roadCoord(0) - HR, CityLayout.roadCoord(N) + HR
		rect(map, x0, z0, x1, z1, COL.block, 3)
		for i = ib, ib + N do
			local x = CityLayout.roadCoord(i)
			line(map, Vector3.new(x, 0, z0), Vector3.new(x, 0, z1), C.RoadWidth, COL.road, 5)
		end
		for j = 0, N do
			local z = CityLayout.roadCoord(j)
			line(map, Vector3.new(x0, 0, z), Vector3.new(x1, 0, z), C.RoadWidth, COL.road, 5)
		end
	end

	-- the east highway out to the loop
	local zH = CityLayout.roadCoord(CityLayout.HighwayJ)
	line(map, Vector3.new(E, 0, zH), Vector3.new(C.LoopHalf, 0, zH), C.HighwayWidth, COL.highway, 6)
	-- the Legends Loop: four straights and the rounded corners in short pieces
	local R = C.LoopCorner
	local side = 2 * (C.LoopHalf - R)
	local arc = math.pi / 2 * R
	local s = 0
	for _ = 1, 4 do
		line(map, CityLayout.loopSample(s + 0.01), CityLayout.loopSample(s + side - 0.01), C.HighwayWidth, COL.highway, 6)
		s += side
		local steps = 8
		for k = 0, steps - 1 do
			line(map, CityLayout.loopSample(s + arc * k / steps), CityLayout.loopSample(s + arc * (k + 1) / steps), C.HighwayWidth, COL.highway, 6)
		end
		s += arc
	end
	-- the coastal highway west to Downtown, the causeway and the island bridges
	line(map, Vector3.new(-E, 0, zH), Vector3.new(WestLayout.DowntownEast, 0, zH), C.HighwayWidth, COL.highway, 6)
	line(map, Vector3.new(WestLayout.DowntownWest, 0, zH), Vector3.new(WestLayout.CausewayEnd, 0, zH), C.LaneWidth * C.LanesPerSide * 2 + 12, COL.road, 6)
	for _, b in WestLayout.IslandBridges do
		line(map, b.from, b.to, C.LaneWidth * 2 + 12, COL.road, 6)
	end
	-- the islands: sand, lawn, ring road
	for _, isl in W.Islands do
		local c = Vector3.new(isl.x, 0, isl.z)
		disc(map, c, isl.r, COL.sand, 3)
		disc(map, c, isl.r - 24, COL.island, 4)
		ringRoad(map, c, isl.ring + W.IslandRoad / 2, W.IslandRoad, COL.road, 6)
	end
	local _ = HW
end

---------------------------------------------------------------------
-- Blips
---------------------------------------------------------------------
type Blip = { frame: Frame, pos: Vector3, edge: boolean }

local function makeBlip(parent: Instance, glyph: string, color: Color3, size: number, z: number): Frame
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Size = UDim2.fromOffset(size, size)
	f.BackgroundColor3 = color
	f.BorderSizePixel = 0
	f.ZIndex = z
	local k = Instance.new("UICorner")
	k.CornerRadius = UDim.new(0.5, 0)
	k.Parent = f
	local st = Instance.new("UIStroke")
	st.Color = Color3.fromRGB(10, 12, 16)
	st.Thickness = 1.5
	st.Parent = f
	if glyph ~= "" then
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.fromScale(1, 1)
		t.Text = glyph
		t.TextScaled = true
		t.Font = Enum.Font.GothamBlack
		t.TextColor3 = Color3.fromRGB(12, 14, 18)
		t.ZIndex = z + 1
		t.Parent = f
	end
	f.Parent = parent
	return f
end

-- the landmarks (fixed): glyph and colour per place
local LANDMARKS: { [string]: { glyph: string, color: Color3 } } = {
	bank = { glyph = "$", color = Color3.fromRGB(80, 230, 130) },
	hotel = { glyph = "H", color = Color3.fromRGB(255, 200, 120) },
	casino = { glyph = "♠", color = Color3.fromRGB(255, 90, 170) },
	gems = { glyph = "◆", color = Color3.fromRGB(120, 210, 255) },
	beach = { glyph = "☀", color = Color3.fromRGB(255, 220, 110) },
	downtown = { glyph = "D", color = Color3.fromRGB(200, 200, 210) },
}

---------------------------------------------------------------------
-- Start
---------------------------------------------------------------------
local started = false
local shown = true
local big = false

function Minimap.setVisible(on: boolean)
	shown = on
end

function Minimap.start()
	if started or not MM.Enabled then
		return
	end
	started = true
	local pg = player:WaitForChild("PlayerGui")
	local gui = Instance.new("ScreenGui")
	gui.Name = "Minimap"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 9 -- under the main UI's panels
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = pg

	local holder = Instance.new("Frame")
	holder.Name = "Holder"
	holder.BackgroundTransparency = 1
	holder.AnchorPoint = Vector2.new(0, 1)
	holder.Parent = gui

	-- the round window
	local clip = Instance.new("CanvasGroup")
	clip.Name = "Clip"
	clip.Size = UDim2.fromScale(1, 1)
	clip.BackgroundColor3 = COL.back
	clip.BorderSizePixel = 0
	clip.Parent = holder
	local ck = Instance.new("UICorner")
	ck.CornerRadius = UDim.new(0.5, 0)
	ck.Parent = clip

	-- the pivot sits in the middle of the window; the map hangs off it in world studs
	local pivot = Instance.new("Frame")
	pivot.Name = "Pivot"
	pivot.BackgroundTransparency = 1
	pivot.AnchorPoint = Vector2.new(0.5, 0.5)
	pivot.Position = UDim2.fromScale(0.5, 0.5)
	pivot.Size = UDim2.fromOffset(0, 0)
	pivot.Parent = clip
	local zoom = Instance.new("UIScale")
	zoom.Scale = MM.ZoomNear
	zoom.Parent = pivot
	local map = Instance.new("Frame")
	map.Name = "Map"
	map.BackgroundTransparency = 1
	map.Size = UDim2.fromOffset(0, 0)
	map.Parent = pivot
	drawMap(map)

	-- blips (upright, placed by hand each frame)
	local layer = Instance.new("Frame")
	layer.Name = "Blips"
	layer.BackgroundTransparency = 1
	layer.Size = UDim2.fromScale(1, 1)
	layer.ZIndex = 20
	layer.Parent = clip

	local fixed: { Blip } = {}
	for _, pl in WestLayout.places() do
		local style = LANDMARKS[pl.id]
		if not style and string.sub(pl.id, 1, 6) == "tower_" then
			style = { glyph = "⌂", color = Color3.fromRGB(190, 150, 255) }
		elseif not style and string.sub(pl.id, 1, 7) == "island_" then
			style = { glyph = "◉", color = Color3.fromRGB(110, 220, 170) }
		end
		if style then
			table.insert(fixed, { frame = makeBlip(layer, style.glyph, style.color, 14, 21), pos = pl.cf.Position, edge = false })
		end
	end
	-- chauffeur stands (city corners, as Chauffeur.lua places them)
	local CH = (Config :: any).Chauffeur
	if CH and CH.Stands then
		for _, st in CH.Stands do
			if CityLayout.inGrid(st[1], st[2]) then
				local p = ActivityData.corner(st[1], st[2], st[3], st[4]) + Vector3.new(st[3] * 34, 0, 0)
				table.insert(fixed, { frame = makeBlip(layer, "C", Color3.fromRGB(240, 200, 90), 12, 21), pos = p, edge = false })
			end
		end
	end
	local dropBlip = makeBlip(layer, "$", Color3.fromRGB(80, 255, 140), 16, 23)
	local targetBlip = makeBlip(layer, "", Color3.fromRGB(255, 214, 40), 13, 24)
	local policePool: { Frame } = {}
	for _ = 1, 8 do
		local f = makeBlip(layer, "", Color3.fromRGB(255, 40, 40), 9, 25)
		f.Visible = false
		table.insert(policePool, f)
	end

	-- the player's arrow in the middle
	local arrow = Instance.new("TextLabel")
	arrow.AnchorPoint = Vector2.new(0.5, 0.5)
	arrow.Position = UDim2.fromScale(0.5, 0.5)
	arrow.Size = UDim2.fromOffset(18, 18)
	arrow.BackgroundTransparency = 1
	arrow.Text = "▲"
	arrow.TextScaled = true
	arrow.Font = Enum.Font.GothamBlack
	arrow.TextColor3 = Theme.Accent
	arrow.ZIndex = 30
	arrow.Parent = clip
	local arrowStroke = Instance.new("UIStroke")
	arrowStroke.Color = Color3.fromRGB(0, 0, 0)
	arrowStroke.Thickness = 1.5
	arrowStroke.Parent = arrow

	-- the rim (outside the clip, so it isn't cut) and north
	local rim = Instance.new("Frame")
	rim.Size = UDim2.fromScale(1, 1)
	rim.BackgroundTransparency = 1
	rim.ZIndex = 40
	rim.Parent = holder
	local rk = Instance.new("UICorner")
	rk.CornerRadius = UDim.new(0.5, 0)
	rk.Parent = rim
	local rimStroke = Instance.new("UIStroke")
	rimStroke.Color = Theme.Stroke
	rimStroke.Thickness = 3
	rimStroke.Transparency = 0.1
	rimStroke.Parent = rim
	local north = Instance.new("TextLabel")
	north.AnchorPoint = Vector2.new(0.5, 0.5)
	north.Size = UDim2.fromOffset(18, 18)
	north.BackgroundColor3 = Theme.Panel
	north.Text = "N"
	north.TextScaled = true
	north.Font = Enum.Font.GothamBlack
	north.TextColor3 = Color3.new(1, 1, 1)
	north.ZIndex = 41
	north.Parent = holder
	local nk = Instance.new("UICorner")
	nk.CornerRadius = UDim.new(0.5, 0)
	nk.Parent = north

	-- size and place: clear of the side buttons and the touch arrows
	local function layout()
		local cam = workspace.CurrentCamera
		local vp = if cam then cam.ViewportSize else Vector2.new(1280, 720)
		local size, x, bottom
		if isTouch then
			size = math.clamp(vp.Y * 0.3, 90, 130) * (if big then 1.6 else 1)
			x, bottom = 76, 140 -- right of the side buttons, above the steering arrows
		else
			size = math.clamp(vp.Y * 0.26, 130, 220) * (if big then 1.5 else 1)
			-- under the side buttons when there's room, else beside them
			local sideBottom = vp.Y * 0.5 + 180
			x = if vp.Y - 20 - size > sideBottom + 8 then 20 else 100
			bottom = 20
		end
		holder.Size = UDim2.fromOffset(size, size)
		holder.Position = UDim2.new(0, x, 1, -bottom)
		return size
	end
	local radius = layout() / 2
	local cam0 = workspace.CurrentCamera
	if cam0 then
		cam0:GetPropertyChangedSignal("ViewportSize"):Connect(function()
			radius = layout() / 2
		end)
	end

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.N then
			shown = not shown
		end
	end)
	-- phones: a tap on the map switches to the big one and back
	clip.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			big = not big
			radius = layout() / 2
		end
	end)

	-- the HUD frame of the main UI (the minimap shows only with the HUD)
	local hudFrame: GuiObject? = nil
	local function hudVisible(): boolean
		if not hudFrame or not hudFrame.Parent then
			local main = pg:FindFirstChild("CityLegendsUI")
			hudFrame = if main then main:FindFirstChild("HUD") :: GuiObject? else nil
		end
		return hudFrame ~= nil and (hudFrame :: GuiObject).Visible
	end

	local scale = MM.ZoomNear
	RunService.RenderStepped:Connect(function(dt)
		local on = shown and hudVisible()
		holder.Visible = on
		if not on then
			return
		end
		local cam = workspace.CurrentCamera
		if not cam then
			return
		end
		-- where we are and which way the camera looks
		local model = Driving.getModel()
		local character = player.Character
		local hrp = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
		local here: Vector3
		local facing: Vector3
		if model and model.PrimaryPart then
			here = model.PrimaryPart.Position
			facing = model.PrimaryPart.CFrame.LookVector
		elseif hrp then
			here = hrp.Position
			facing = hrp.CFrame.LookVector
		else
			here = cam.Focus.Position
			facing = cam.CFrame.LookVector
		end
		local look = cam.CFrame.LookVector
		local heading = math.atan2(look.X, -look.Z) -- 0 = north, clockwise
		-- zoom out with speed
		local mph = Config.spsToMph(Driving.getSpeed())
		local want = MM.ZoomNear + (MM.ZoomFar - MM.ZoomNear) * math.clamp(mph / MM.FarMph, 0, 1)
		if big then
			want *= 0.6
		end
		scale += (want - scale) * math.min(1, dt * 2.5)
		zoom.Scale = scale
		pivot.Rotation = -math.deg(heading)
		map.Position = UDim2.fromOffset(-here.X, -here.Z)
		-- the arrow points where the car (or you) faces, relative to the camera
		local carHeading = math.atan2(facing.X, -facing.Z)
		arrow.Rotation = math.deg(carHeading - heading)
		-- north on the rim
		local nAng = -heading
		north.Position = UDim2.new(0.5, math.sin(nAng) * radius, 0.5, -math.cos(nAng) * radius)

		-- a world point -> its spot in the window (offset from the middle); far ones clamp to the rim
		local cosH, sinH = math.cos(heading), math.sin(heading)
		local function place(f: GuiObject, p: Vector3, edge: boolean)
			local dx, dz = (p.X - here.X) * scale, (p.Z - here.Z) * scale
			-- turn by -heading: the camera's forward becomes up
			local sx = dx * cosH + dz * sinH
			local sy = -dx * sinH + dz * cosH
			local d = math.sqrt(sx * sx + sy * sy)
			local maxR = radius - 8
			if d > maxR then
				if not edge then
					f.Visible = false
					return
				end
				sx, sy = sx / d * maxR, sy / d * maxR
			end
			f.Visible = true
			f.Position = UDim2.new(0.5, sx, 0.5, sy)
		end
		for _, b in fixed do
			place(b.frame, b.pos, b.edge)
		end
		-- the bank drop-off while you carry loot
		local drop = workspace:GetAttribute("Dropoff")
		local loot = player:GetAttribute("Loot")
		if typeof(drop) == "Vector3" and type(loot) == "number" and loot > 0 then
			place(dropBlip, drop, true)
		else
			dropBlip.Visible = false
		end
		-- the race checkpoint or the delivery drop
		local target = Activities.getTarget()
		if target then
			place(targetBlip, target, true)
		else
			targetBlip.Visible = false
		end
		-- police cars, flashing red and blue
		local flash = math.floor(os.clock() * 4) % 2 == 0
		local cops = Police.getUnitPositions()
		for i, f in policePool do
			local p = cops[i]
			if p then
				f.BackgroundColor3 = if flash then Color3.fromRGB(255, 40, 40) else Color3.fromRGB(60, 120, 255)
				place(f, p, false)
			else
				f.Visible = false
			end
		end
		-- the rim flashes while you're wanted
		if Police.getWanted() > 0 then
			rimStroke.Color = if flash then Color3.fromRGB(255, 40, 40) else Color3.fromRGB(60, 120, 255)
			rimStroke.Thickness = 4
		else
			rimStroke.Color = Theme.Stroke
			rimStroke.Thickness = 3
		end
	end)
end

return Minimap
