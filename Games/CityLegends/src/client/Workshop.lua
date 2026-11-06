--[[
	Workshop (client) (owner, 2026-11-06: "make the upgrading area way better ... add a part shop")
	The car's upgrade screen, from the garage's UPGRADE, the menu and Legends Customs. The camera goes
	to the Legends Customs workshop room, built on this screen only and high above the city (like the
	dealer's stage): the real car up on a two-post lift over a red ring, tool chests, a tyre rack, an
	engine on a stand, warm strip lights, polished concrete.
	Our own layout (imports/refs/ui/upgrades/workshop_mockup.png), phone first:
	  * pins on the car: filled slots / all slots, coloured by the best rarity fitted; a pin zooms there
	  * left rail: the categories. Top: the car, UPGRADE / SHOP / TUNE / STYLE, cash, CP
	  * right: the PI ring with the change, power, 0-100, top speed, grip, DYNO RUN
	  * bottom drawer: the category's slots as rarity tiles, then that slot's options
	SHOP: tabs, search, rarity filters, tiles, a details panel with BUY and BUY & INSTALL.
	TUNE: launch control and the small settings, saved per car, and the 3 builds.
	DYNO RUN: the car comes down onto the rollers, revs to the limiter with its real sound and pops,
	the graph draws live, "412 hp -> 468 hp (+56)".
	Every change is the server's (CarLevels): this screen asks and shows the answer. A Studio test hook:
	workspace attribute PreviewPhone draws it at 667 x 375.
]]

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Cars = require(Shared:WaitForChild("Cars"))
local CarStats = require(Shared:WaitForChild("CarStats"))
local CarBuilder = require(Shared:WaitForChild("CarBuilder"))
local PartData = require(Shared:WaitForChild("PartData"))

local UI = require(script.Parent:WaitForChild("UI"))
local Audio = require(script.Parent:WaitForChild("Audio"))
local CarSkin = require(script.Parent:WaitForChild("CarSkin"))
local CustomsClient = require(script.Parent:WaitForChild("CustomsClient"))
local Driving = require(script.Parent:WaitForChild("Driving"))
local PartArt = require(script.Parent:WaitForChild("PartArt"))
local CarUpgrades = require(script.Parent:WaitForChild("CarUpgrades"))

local Workshop = {}

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local kit = UI.kit
local new, label, corner, stroke = kit.new, kit.label, kit.corner, kit.stroke
local DF = Config.DrivingFeel

local STAGE = Vector3.new(0, 3400, 0) -- the room, high above the city (this screen only)
local LIFT = 2.6 -- how high the car stands on the lift
local RING = "rbxassetid://125153978505617"
local W, H = 740, 416 -- one design size, scaled to the screen
local FOV = 36

local PANEL = Color3.fromRGB(16, 17, 21)
local PANEL2 = Color3.fromRGB(28, 29, 35)
local LINE = Color3.fromRGB(70, 72, 84)
local RED = Color3.fromRGB(230, 56, 62)
local GOLD = Color3.fromRGB(255, 190, 80)
local WHITE = Color3.fromRGB(244, 244, 246)
local GREY = Color3.fromRGB(150, 153, 164)
local GREEN = Color3.fromRGB(118, 240, 156)
local BLUE = Color3.fromRGB(60, 130, 240)
local BLACK = Color3.new(0, 0, 0)

local open = false
local closing = false
local gui: ScreenGui? = nil
local room: Folder? = nil
local grade: ColorCorrectionEffect? = nil
local conns: { RBXScriptConnection } = {}
local hiddenGuis: { [ScreenGui]: boolean } = {}
local savedHold: { boolean }? = nil
local savedWalk: { number }? = nil
local savedBlur: { [Instance]: boolean } = {}
local savedFov = 70
local savedCamType = Enum.CameraType.Custom
local modalBefore = false

type St = {
	carId: string,
	spec: Cars.CarSpec,
	tab: string, -- UPGRADE, SHOP, TUNE
	cat: string,
	slot: string,
	preview: string?, -- a part being looked at
	shopTab: string, -- a category, "swap" or "mine"
	shopRarity: string?,
	shopGroup: string,
	shopSearch: string,
	shopPick: string?,
	busy: boolean,
	dyno: boolean,
}
local st: St = nil :: any
local car: Model? = nil
local carL, carW, carH = 14, 6, 4
local lift = LIFT
local liftArms: { BasePart } = {}
local liftPosts: { BasePart } = {}
local armBase: { [BasePart]: CFrame } = {}
local rollers: { BasePart } = {}
local wheelMotors: { { motor: Motor6D, front: boolean } } = {}

-- the camera
local yaw, pitch, dist = 2.5, 0.2, 30
local wantYaw, wantPitch, wantDist = 2.5, 0.2, 30
local look = Vector3.zero
local wantLook = Vector3.zero
local posed = false -- a pin or category holds the shot (a drag lets go)
local idle = 0
local shiftX, wantShift = 0, 0
local shiftY, wantShiftY = 0.24, 0.24

-- the screen's pieces, set by build
local ui: { [string]: any } = {}
local fns: { [string]: any } = {}

---------------------------------------------------------------------
-- small things
---------------------------------------------------------------------
local money = UI.formatCash

local function short(n: number): string
	if n >= 1000000 then
		return string.format("$%gM", math.floor(n / 10000 + 0.5) / 100)
	elseif n >= 10000 then
		return string.format("$%gK", math.floor(n / 100 + 0.5) / 10)
	end
	return money(n)
end

local function viewport(): Vector2
	if RunService:IsStudio() and workspace:GetAttribute("PreviewPhone") then
		return Vector2.new(667, 375)
	end
	local v = camera.ViewportSize
	return Vector2.new(v.X, v.Y)
end

local function panel(props: { [string]: any }): Frame
	local base: { [string]: any } = { BackgroundColor3 = PANEL, BackgroundTransparency = 0.1, BorderSizePixel = 0 }
	for k, v in props do
		base[k] = v
	end
	return new("Frame", base, { corner(10), stroke(WHITE, 1, 0.9) })
end

local function btn(text: string, props: { [string]: any }): TextButton
	local base: { [string]: any } = {
		AutoButtonColor = false,
		BackgroundColor3 = PANEL2,
		Font = Enum.Font.GothamBlack,
		Text = text,
		TextColor3 = WHITE,
		TextSize = 11,
	}
	for k, v in props do
		base[k] = v
	end
	local b: TextButton = new("TextButton", base, { corner(6) })
	return b
end

local function round(f: Instance, r: number)
	local c = f:FindFirstChildOfClass("UICorner")
	if c then
		c.CornerRadius = UDim.new(0, r)
	end
end

local function icon(key: string, parent: Instance, size: number, pos: UDim2?): ImageLabel
	return new("ImageLabel", {
		BackgroundTransparency = 1,
		Image = PartArt[key] or PartArt.block,
		ScaleType = Enum.ScaleType.Fit,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = pos or UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(size, size),
		Parent = parent,
	})
end

-- a tile in a rarity's colours: gradient, the shine over its top half
local function rarityBack(f: GuiObject, rarity: string?, r: number?)
	local info = PartData.Rarity[rarity or "Common"]
	f.BackgroundColor3 = WHITE
	f.BackgroundTransparency = 0
	new("UIGradient", { Color = ColorSequence.new(info.color, info.dark), Rotation = 90, Parent = f })
	new("UICorner", { CornerRadius = UDim.new(0, r or 8), Parent = f })
	new("UIStroke", { Color = WHITE, Thickness = 1, Transparency = 0.84, Parent = f })
	new("Frame", {
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 0.46),
		Parent = f,
	}, {
		new("UICorner", { CornerRadius = UDim.new(0, r or 8) }),
		new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0.8, 1) }),
	})
end

-- a progress ring: two halves, each a clipped ring with a hard-edged gradient turned round
local function ring(parent: Instance, size: number, pos: UDim2, color: Color3): (Frame, (number, Color3?) -> ())
	local f: Frame = new("Frame", { BackgroundTransparency = 1, Position = pos, Size = UDim2.fromOffset(size, size), Parent = parent })
	new("ImageLabel", { BackgroundTransparency = 1, Image = RING, ImageColor3 = Color3.fromRGB(52, 54, 62), Size = UDim2.fromScale(1, 1), Parent = f })
	local step = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.5, 0),
		NumberSequenceKeypoint.new(0.5001, 1),
		NumberSequenceKeypoint.new(1, 1),
	})
	local grads, imgs = {}, {}
	for side = 0, 1 do
		local clip: Frame = new("Frame", { BackgroundTransparency = 1, ClipsDescendants = true, Position = UDim2.fromScale(side * 0.5, 0), Size = UDim2.fromScale(0.5, 1), Parent = f })
		local img: ImageLabel = new("ImageLabel", { BackgroundTransparency = 1, Image = RING, ImageColor3 = color, Position = UDim2.fromScale(-side, 0), Size = UDim2.fromScale(2, 1), Parent = clip })
		grads[side] = new("UIGradient", { Transparency = step, Parent = img })
		imgs[side] = img
	end
	return f, function(k: number, c: Color3?)
		local deg = math.clamp(k, 0, 1) * 360
		grads[1].Rotation = math.clamp(deg, 0, 180)
		grads[0].Rotation = math.clamp(deg, 180, 360)
		if c then
			imgs[0].ImageColor3 = c
			imgs[1].ImageColor3 = c
		end
	end
end

local function parts(): CarStats.Parts
	return CarUpgrades.get(st.carId).parts
end

-- the numbers the screen shows, for a set of parts
local function numbers(set: CarStats.Parts?): { [string]: any }
	local spec = CarStats.tunedSpec(st.carId, set)
	local hp = CarStats.powerOf(st.carId, set)
	local letter, color, pi = CarStats.classOf(st.carId, set)
	return {
		letter = letter,
		color = color,
		pi = pi,
		hp = math.floor(hp + 0.5),
		t100 = spec.ZeroToSixty * 1.06,
		kmh = math.floor(spec.TopSpeed * 1.609 + 0.5),
		grip = DF.GripBase + DF.GripHandling * spec.Handling,
	}
end

local function nextClass(letter: string): (string?, number?)
	local R = Config.CarClasses.Ranges
	for i, r in R do
		if r[1] == letter and R[i + 1] then
			return R[i + 1][1], R[i + 1][2]
		end
	end
	return nil, nil
end

local function showMsg(text: string, color: Color3?)
	local m = ui.msg
	if not m then
		return
	end
	m.Text = text
	m.TextColor3 = color or GOLD
	m.Visible = true
	task.delay(3, function()
		if m.Text == text then
			m.Visible = false
		end
	end)
end

-- the best spare of a part, and what it costs to fit on this car
local function spareOf(partId: string): (number?, number)
	local list = CarUpgrades.bag()[partId]
	if not list or #list == 0 then
		return nil, 0
	end
	local k = 0
	for _, v in list do
		k = math.max(k, v)
	end
	local def = PartData.Parts[partId]
	local swap = def.engine ~= nil
	local fee = math.max(0, Config.partCash(def.list, Config.partK(st.spec.Price), swap) - Config.partCash(def.list, k, swap))
	return k, fee
end

---------------------------------------------------------------------
-- the room
---------------------------------------------------------------------
local function part(parent: Instance, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, props: { [string]: any }?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	if props then
		for k, v in props do
			(p :: any)[k] = v
		end
	end
	p.Parent = parent
	return p
end

local function surfaceLight(p: BasePart, face: Enum.NormalId, color: Color3, brightness: number, range: number, angle: number)
	local l = Instance.new("SurfaceLight")
	l.Face = face
	l.Color = color
	l.Brightness = brightness
	l.Range = range
	l.Angle = angle
	l.Parent = p
end

local function sign(p: BasePart, text: string, sub: string?)
	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId.Front
	g.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
	g.CanvasSize = Vector2.new(900, 180)
	g.LightInfluence = 0
	g.Parent = p
	label({ Text = text, Font = Enum.Font.GothamBlack, TextScaled = true, TextColor3 = WHITE, Position = UDim2.fromScale(0.03, 0.08), Size = UDim2.fromScale(0.94, if sub then 0.56 else 0.84), Parent = g })
	if sub then
		label({ Text = sub, Font = Enum.Font.GothamBold, TextScaled = true, TextColor3 = RED, Position = UDim2.fromScale(0.03, 0.66), Size = UDim2.fromScale(0.94, 0.24), Parent = g })
	end
end

local function toolChest(f: Instance, c: CFrame, color: Color3)
	part(f, Vector3.new(7, 5.2, 3), c * CFrame.new(0, 3.1, 0), color, Enum.Material.Metal)
	part(f, Vector3.new(7.3, 0.3, 3.3), c * CFrame.new(0, 5.85, 0), Color3.fromRGB(30, 30, 34), Enum.Material.Metal)
	for k = 0, 4 do
		part(f, Vector3.new(6.5, 0.8, 0.12), c * CFrame.new(0, 1.2 + k * 0.98, 1.54), Color3.fromRGB(38, 38, 44), Enum.Material.Metal)
		part(f, Vector3.new(4.6, 0.14, 0.2), c * CFrame.new(0, 1.42 + k * 0.98, 1.64), Color3.fromRGB(196, 198, 204), Enum.Material.Metal)
	end
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			part(f, Vector3.new(0.6, 0.5, 0.6), c * CFrame.new(sx * 3, 0.25, sz * 1.1), BLACK, Enum.Material.Rubber)
		end
	end
end

local function tyreRack(f: Instance, c: CFrame)
	for _, sx in { -7, 7 } do
		part(f, Vector3.new(0.5, 12, 0.5), c * CFrame.new(sx, 6, 0), Color3.fromRGB(190, 60, 44), Enum.Material.Metal)
	end
	for _, y in { 1.5, 5.3, 9.1 } do
		part(f, Vector3.new(14.6, 0.4, 2.8), c * CFrame.new(0, y, 0), Color3.fromRGB(64, 66, 74), Enum.Material.Metal)
		for k = 0, 5 do
			part(f, Vector3.new(1.3, 3, 3), c * CFrame.new(-6 + k * 2.4, y + 1.7, 0) * CFrame.Angles(0, math.rad(4 * ((k % 3) - 1)), 0), Color3.fromRGB(18, 18, 20), Enum.Material.Rubber, { Shape = Enum.PartType.Cylinder })
		end
	end
end

local function engineStand(f: Instance, c: CFrame)
	part(f, Vector3.new(4.6, 0.3, 3), c * CFrame.new(0, 0.3, 0), Color3.fromRGB(180, 50, 44), Enum.Material.Metal)
	part(f, Vector3.new(0.5, 3.2, 0.5), c * CFrame.new(-1.6, 2, 0), Color3.fromRGB(180, 50, 44), Enum.Material.Metal)
	part(f, Vector3.new(1.2, 0.4, 0.4), c * CFrame.new(-1, 3.4, 0), Color3.fromRGB(180, 50, 44), Enum.Material.Metal)
	local block = Color3.fromRGB(70, 72, 78)
	part(f, Vector3.new(3.4, 2.2, 2.2), c * CFrame.new(0.8, 3.4, 0), block, Enum.Material.Metal)
	part(f, Vector3.new(3.2, 0.9, 1.5), c * CFrame.new(0.8, 4.9, 0), Color3.fromRGB(150, 36, 36), Enum.Material.Metal)
	part(f, Vector3.new(3.4, 0.5, 1.8), c * CFrame.new(0.8, 2, 0), Color3.fromRGB(30, 30, 34), Enum.Material.Metal)
	for k = 0, 3 do
		part(f, Vector3.new(0.3, 0.5, 0.3), c * CFrame.new(-0.2 + k * 0.68, 5.5, 0), Color3.fromRGB(196, 198, 204), Enum.Material.Metal)
	end
	part(f, Vector3.new(0.35, 1.6, 1.6), c * CFrame.new(2.7, 3.4, 0), Color3.fromRGB(180, 182, 188), Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
end

local function buildRoom(): Folder
	local f = Instance.new("Folder")
	f.Name = "WorkshopRoom"
	local c = CFrame.new(STAGE)
	local RW, RD, RH = 56, 46, 26
	local wall = Color3.fromRGB(58, 60, 66)
	-- polished concrete (it mirrors the lights a little), joints across it
	part(f, Vector3.new(RW * 2, 1, RD * 2), c * CFrame.new(0, -0.5, 0), Color3.fromRGB(96, 98, 104), Enum.Material.SmoothPlastic, { Reflectance = 0.1 })
	for k = -2, 2 do
		part(f, Vector3.new(RW * 2, 0.02, 0.12), c * CFrame.new(0, 0.01, k * 18), Color3.fromRGB(70, 72, 78))
		part(f, Vector3.new(0.12, 0.02, RD * 2), c * CFrame.new(k * 22, 0.01, 0), Color3.fromRGB(70, 72, 78))
	end
	-- walls: concrete, a dark band low down and a red line, two roller doors, the ceiling
	for _, w in { { 0, -RD, 0 }, { 0, RD, math.pi }, { -RW, 0, math.pi / 2 }, { RW, 0, -math.pi / 2 } } do
		local wc = c * CFrame.new(w[1], 0, w[2]) * CFrame.Angles(0, w[3], 0)
		local len = if w[1] == 0 then RW * 2 else RD * 2
		part(f, Vector3.new(len, RH, 1), wc * CFrame.new(0, RH / 2, -0.5), wall, Enum.Material.Concrete)
		part(f, Vector3.new(len, 6, 0.2), wc * CFrame.new(0, 3, 0.1), Color3.fromRGB(36, 37, 42), Enum.Material.SmoothPlastic)
		part(f, Vector3.new(len, 0.3, 0.24), wc * CFrame.new(0, 6.1, 0.12), Color3.fromRGB(196, 44, 48), Enum.Material.SmoothPlastic)
	end
	part(f, Vector3.new(RW * 2, 1, RD * 2), c * CFrame.new(0, RH + 0.5, 0), Color3.fromRGB(34, 35, 40), Enum.Material.Concrete)
	for _, sx in { -1, 1 } do
		local d = c * CFrame.new(RW - 0.3, 0, sx * 20) * CFrame.Angles(0, -math.pi / 2, 0)
		part(f, Vector3.new(22, 16, 0.4), d * CFrame.new(0, 8, 0.2), Color3.fromRGB(96, 98, 104), Enum.Material.Metal)
		for k = 0, 7 do
			part(f, Vector3.new(22, 0.12, 0.1), d * CFrame.new(0, 1 + k * 2, 0.45), Color3.fromRGB(70, 72, 78), Enum.Material.Metal)
		end
	end
	-- warm strip lights
	for _, z in { -24, 0, 24 } do
		for _, x in { -30, 0, 30 } do
			local strip = part(f, Vector3.new(20, 0.3, 1.1), c * CFrame.new(x, RH - 0.2, z), Color3.fromRGB(255, 232, 196), Enum.Material.Neon)
			surfaceLight(strip, Enum.NormalId.Bottom, Color3.fromRGB(255, 226, 190), 0.4, 40, 120)
		end
	end
	-- spots on the car
	for k = 0, 3 do
		local a = k * math.pi / 2 + math.pi / 4
		local p = (c * CFrame.new(math.cos(a) * 20, 21, math.sin(a) * 20)).Position
		local lamp = part(f, Vector3.new(1.2, 1.2, 2), CFrame.lookAt(p, STAGE + Vector3.new(0, 3, 0)), Color3.fromRGB(20, 20, 24), Enum.Material.Metal)
		local s = Instance.new("SpotLight")
		s.Face = Enum.NormalId.Front
		s.Color = Color3.fromRGB(255, 240, 222)
		s.Brightness = 0.6
		s.Range = 42
		s.Angle = 42
		s.Shadows = k < 2
		s.Parent = lamp
	end
	local key = part(f, Vector3.one, c * CFrame.new(0, 14, 0), BLACK, nil, { Transparency = 1 })
	local pl = Instance.new("PointLight")
	pl.Color = Color3.fromRGB(255, 244, 232)
	pl.Brightness = 0.25
	pl.Range = 26
	pl.Parent = key
	-- the red ring and the floor light under the car
	local R, N = 15, 56
	for k = 0, N - 1 do
		local a = k / N * math.pi * 2
		part(f, Vector3.new(2 * math.pi * R / N + 0.05, 0.05, 0.34), c * CFrame.Angles(0, a, 0) * CFrame.new(0, 0.04, R), Color3.fromRGB(230, 40, 48), Enum.Material.Neon)
	end
	part(f, Vector3.new(0.06, R * 2 - 1, R * 2 - 1), c * CFrame.new(0, 0.03, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(66, 62, 62), Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Cylinder, Reflectance = 0.14 })
	local glow = part(f, Vector3.new(14, 0.05, 22), c * CFrame.new(0, 0.05, 0), Color3.fromRGB(255, 226, 190), nil, { Transparency = 1 })
	surfaceLight(glow, Enum.NormalId.Top, Color3.fromRGB(255, 224, 186), 0.2, 12, 150)
	-- the props, against the walls
	sign(part(f, Vector3.new(34, 6.8, 0.4), CFrame.lookAt((c * CFrame.new(0, 15, -RD + 0.3)).Position, (c * CFrame.new(0, 15, 0)).Position), Color3.fromRGB(22, 23, 27)), "LEGENDS CUSTOMS", "WORKSHOP")
	for k = -2, 2 do
		toolChest(f, c * CFrame.new(k * 8.2, 0, -RD + 2), if k % 2 == 0 then Color3.fromRGB(176, 40, 44) else Color3.fromRGB(40, 42, 50))
	end
	part(f, Vector3.new(44, 7, 0.2), c * CFrame.new(0, 9.6, -RD + 0.15), Color3.fromRGB(44, 46, 52), Enum.Material.Metal) -- the tool wall
	for k = -9, 9 do
		part(f, Vector3.new(0.3, 2.2 + (k % 3) * 0.7, 0.14), c * CFrame.new(k * 2.2, 10 - (k % 3) * 0.3, -RD + 0.32), Color3.fromRGB(176, 178, 186), Enum.Material.Metal)
	end
	tyreRack(f, c * CFrame.new(-RW + 2, 0, -18) * CFrame.Angles(0, math.pi / 2, 0))
	tyreRack(f, c * CFrame.new(-RW + 2, 0, 18) * CFrame.Angles(0, math.pi / 2, 0))
	engineStand(f, c * CFrame.new(RW - 12, 0, 0) * CFrame.Angles(0, math.rad(200), 0))
	engineStand(f, c * CFrame.new(-16, 0, RD - 10) * CFrame.Angles(0, math.rad(30), 0))
	-- a bench along the near wall
	part(f, Vector3.new(30, 0.5, 4), c * CFrame.new(8, 4, RD - 2.6), Color3.fromRGB(70, 56, 44), Enum.Material.WoodPlanks)
	for _, x in { -6, 8, 22 } do
		part(f, Vector3.new(0.5, 4, 3.6), c * CFrame.new(x, 2, RD - 2.6), Color3.fromRGB(40, 42, 48), Enum.Material.Metal)
	end
	f.Parent = workspace
	return f
end

-- the lift: two red posts either side, arms under the car's sills. The arms come down with it
local function buildLift(f: Instance)
	local c = CFrame.new(STAGE)
	local red = Color3.fromRGB(198, 44, 46)
	table.clear(liftArms)
	table.clear(armBase)
	table.clear(liftPosts)
	for _, sx in { -1, 1 } do
		local x = sx * (carW / 2 + 4.6)
		part(f, Vector3.new(2.6, 0.3, 2.6), c * CFrame.new(x, 0.15, 0), Color3.fromRGB(38, 39, 44), Enum.Material.Metal)
		table.insert(liftPosts, part(f, Vector3.new(1, 12, 1.3), c * CFrame.new(x, 6, 0), red, Enum.Material.Metal))
		table.insert(liftPosts, part(f, Vector3.new(0.24, 11, 0.32), c * CFrame.new(x - sx * 0.52, 6, 0), Color3.fromRGB(30, 30, 34), Enum.Material.Metal))
		for _, sz in { -1, 1 } do
			local arm = part(f, Vector3.new(5.6, 0.3, 0.6), c * CFrame.new(x - sx * 3.1, LIFT, sz * 1.5) * CFrame.Angles(0, sx * sz * math.rad(22), 0), Color3.fromRGB(58, 60, 66), Enum.Material.Metal)
			table.insert(liftArms, arm)
			armBase[arm] = arm.CFrame
		end
	end
	part(f, Vector3.new(carW + 10.2, 0.7, 0.8), c * CFrame.new(0, 12.4, 0), red, Enum.Material.Metal)
	-- the dyno rollers, set in the floor under the axles
	table.clear(rollers)
	for _, w in wheelMotors do
		if w.motor.C0.Position.X > 0 then
			local z = w.motor.C0.Position.Z
			part(f, Vector3.new(carW + 1, 0.06, 3.4), c * CFrame.new(0, 0.03, z), Color3.fromRGB(30, 31, 36), Enum.Material.Metal)
			for _, dz in { -0.7, 0.7 } do
				local roller = part(f, Vector3.new(carW + 0.5, 1.1, 1.1), c * CFrame.new(0, -0.25, z + dz), Color3.fromRGB(150, 152, 158), Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
				table.insert(rollers, roller)
			end
		end
	end
end

local function putCar(k: number)
	lift = k
	local m = car
	if m then
		m:PivotTo(CFrame.new(STAGE + Vector3.new(0, carH / 2 + 0.3 + k, 0)))
	end
	for _, arm in liftArms do
		arm.CFrame = armBase[arm] - Vector3.new(0, LIFT - k, 0)
	end
end

local function showCar(id: string)
	local spec = Cars.get(id)
	local ok, m = pcall(CarBuilder.build, spec, { anchored = true, interior = false })
	if not ok or not m then
		return
	end
	pcall(CarSkin.apply, m, true)
	carH = (m:GetAttribute("Height") :: number?) or 4
	carL = (m:GetAttribute("Length") :: number?) or 14
	carW = (m:GetAttribute("Width") :: number?) or 6
	m.Parent = room
	local info = CarUpgrades.get(id)
	if type(info.look) == "table" then
		pcall(CustomsClient.paintCar, m, info.look)
	end
	car = m
	table.clear(wheelMotors)
	local root = m.PrimaryPart
	if root then
		for _, j in root:GetChildren() do
			if j:IsA("Motor6D") and j.Name:sub(1, 6) == "Wheel_" then
				table.insert(wheelMotors, { motor = j, front = j.C0.Position.Z < 0 })
			end
		end
	end
	buildLift(room :: Folder)
	putCar(LIFT)
end

---------------------------------------------------------------------
-- camera poses
---------------------------------------------------------------------
local function midEngine(): boolean
	return st.spec.Class == "Supercar" or st.spec.Class == "Hypercar"
end

local function pose(name: string)
	posed = true
	idle = 0
	local base = STAGE + Vector3.new(0, carH / 2 + 0.3 + lift, 0)
	local near = carL * 0.95 + 4
	if name == "engine" then
		-- the bonnet, or behind the seats on a mid-engined car
		local z = if midEngine() then carL * 0.22 else -carL * 0.3
		wantYaw, wantPitch, wantDist = if midEngine() then 0.5 else math.pi - 0.55, 0.48, near
		wantLook = base + Vector3.new(0, carH * 0.2, z)
	elseif name == "rear" then
		wantYaw, wantPitch, wantDist = 0.42, 0.1, near
		wantLook = base + Vector3.new(0, -carH * 0.14, carL * 0.42)
	elseif name == "wheel" then
		wantYaw, wantPitch, wantDist = math.pi * 0.66, 0.08, near * 0.8
		wantLook = base + Vector3.new(-carW * 0.3, -carH * 0.22, -carL * 0.28)
	elseif name == "side" then
		-- (past the posts: they stand at the car's sides)
		wantYaw, wantPitch, wantDist = -math.pi * 0.72, 0.1, near * 1.3
		wantLook = base
	elseif name == "dyno" then
		wantYaw, wantPitch, wantDist = 0.72, 0.14, carL * 1.25 + 7
		wantLook = STAGE + Vector3.new(0, carH / 2 + 0.3, 0)
	else
		wantYaw, wantPitch, wantDist = wantYaw, 0.2, carL * 1.05 + 5
		wantLook = base + Vector3.new(0, 0.4, 0)
		posed = false
	end
	-- turn the short way round
	local d = (wantYaw - yaw + math.pi) % (2 * math.pi) - math.pi
	wantYaw = yaw + d
end

-- where each pin stands on the car
local function pinPos(key: string): Vector3
	local base = CFrame.new(STAGE + Vector3.new(0, carH / 2 + 0.3 + lift, 0))
	local rearEngine = midEngine()
	if key == "engine" then
		return (base * CFrame.new(0, carH * 0.32, if rearEngine then carL * 0.24 else -carL * 0.3)).Position
	elseif key == "boost" then
		return (base * CFrame.new(-carW * 0.3, carH * 0.3, if rearEngine then carL * 0.06 else -carL * 0.12)).Position
	elseif key == "exhaust" then
		return (base * CFrame.new(carW * 0.2, -carH * 0.2, carL * 0.5)).Position
	elseif key == "grip" then
		return (base * CFrame.new(-carW * 0.5, -carH * 0.26, -carL * 0.3)).Position
	end
	return (base * CFrame.new(carW * 0.5, -carH * 0.1, carL * 0.28)).Position
end

---------------------------------------------------------------------
-- doing things
---------------------------------------------------------------------
local refreshAll: () -> ()

local function act(what: string, arg: { [string]: any }, okText: string?): boolean
	if st.busy then
		return false
	end
	st.busy = true
	arg.car = arg.car or st.carId
	local res = CarUpgrades.ask(what, arg)
	st.busy = false
	if res.ok then
		st.preview = nil
		if type(res.cash) == "number" then
			ui.cash = res.cash
		end
		if okText then
			showMsg(okText, GREEN)
		end
		Audio.cutUp(4, "UPGRADE")
		refreshAll()
	else
		showMsg(res.message or "Couldn't do that", Config.Theme.Danger)
	end
	return res.ok == true
end

local function buy(partId: string, pay: string, install: boolean)
	local def = PartData.Parts[partId]
	act("buy", { part = partId, pay = pay, install = install }, def.name .. (if install then " fitted" else " is in My Parts"))
end

local function install(partId: string)
	act("install", { part = partId }, PartData.Parts[partId].name .. " fitted")
end

local function uninstall(slot: string)
	act("uninstall", { slot = slot }, "Back in My Parts")
end

---------------------------------------------------------------------
-- the right panel and the top bar
---------------------------------------------------------------------
local function refreshStats()
	local now = parts()
	local cur = numbers(now)
	local info = CarUpgrades.get(st.carId)
	ui.chipLetter.Text = cur.letter
	ui.chipPi.Text = tostring(cur.pi)
	ui.chip.BackgroundColor3 = cur.color
	ui.subName.Text = string.format("CAR LEVEL %d  ·  LEGENDS CUSTOMS WORKSHOP", info.level)
	ui.cpText.Text = info.cp .. " CP"
	ui.cashText.Text = money(ui.cash or UI.getCash())

	local show = cur
	local base = numbers(nil)
	local line1
	if st.preview then
		local def = PartData.Parts[st.preview]
		local set = table.clone(now)
		set[def.slot] = st.preview
		show = numbers(set)
		base = cur
		line1 = "with " .. def.name
	else
		line1 = "over stock"
	end
	local d = show.pi - base.pi
	ui.piLetter.Text = show.letter
	ui.piNumber.Text = tostring(show.pi)
	ui.piChange.Text = (if d >= 0 then "+" else "") .. d
	ui.piChange.TextColor3 = if d >= 0 then GREEN else Config.Theme.Danger
	ui.piLine1.Text = line1
	local nl, nf = nextClass(show.letter)
	ui.piLine2.Text = if show.letter ~= base.letter then "moves up to class " .. show.letter elseif nl then string.format("still class %s (%s at %d)", show.letter, nl, nf) else "top class"
	ui.piRing(math.clamp((show.pi - 100) / 899, 0, 1), show.color)
	local function delta(a: number, b: number, fmt: string, better: boolean): string
		local v = a - b
		if math.abs(v) < 0.001 then
			return ""
		end
		return string.format(" <font color=\"#%s\">%s" .. fmt .. "</font>", if better then "76f09c" else "ff6a6a", if v > 0 then "+" else "", v)
	end
	ui.stat.power.value.Text = show.hp .. " hp" .. delta(show.hp, base.hp, "%d", show.hp >= base.hp)
	ui.stat.power.set(show.hp / 1200)
	ui.stat.t100.value.Text = string.format("%.1f s", show.t100) .. delta(math.floor(show.t100 * 10 + 0.5) / 10, math.floor(base.t100 * 10 + 0.5) / 10, "%.1f", show.t100 <= base.t100)
	ui.stat.t100.set((10.5 - show.t100) / 8.5)
	ui.stat.top.value.Text = show.kmh .. delta(show.kmh, base.kmh, "%d", show.kmh >= base.kmh)
	ui.stat.top.set(show.kmh / 480)
	ui.stat.grip.value.Text = string.format("%.2f g", show.grip)
	ui.stat.grip.set((show.grip - 0.8) / 0.4)
end

local function refreshPins()
	local now = parts()
	for _, cat in PartData.Cats do
		local pin = ui.pins[cat.key]
		if pin then
			local filled, best = 0, 0
			local bestName: string? = nil
			for _, slot in cat.slots do
				local id = now[slot]
				if id then
					filled += 1
					local o = PartData.Rarity[PartData.Parts[id].rarity].order
					if o > best then
						best, bestName = o, PartData.Parts[id].rarity
					end
				end
			end
			pin.text.Text = string.format("%s %d/%d", cat.name, filled, #cat.slots)
			pin.dot.BackgroundColor3 = if bestName then PartData.Rarity[bestName].color else GREY
			pin.halo.BackgroundColor3 = pin.dot.BackgroundColor3
		end
	end
end

---------------------------------------------------------------------
-- the drawer: the category's slots, then the slot's options
---------------------------------------------------------------------
local function clear(f: Instance)
	for _, c in f:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
end

local function catOf(key: string): any
	for _, c in PartData.Cats do
		if c.key == key then
			return c
		end
	end
	return PartData.Cats[1]
end

local function optionCard(order: number, def: PartData.Part?, slot: string)
	local now = parts()
	local slotDef = PartData.Slots[slot]
	local fitted = now[slot]
	local id = def and def.id
	local rarity = if def then def.rarity else "Common"
	local rinfo = PartData.Rarity[rarity]
	local on = (id == fitted) or (not def and not fitted)
	local picked = id ~= nil and st.preview == id
	local b: TextButton = new("TextButton", {
		AutoButtonColor = false,
		Text = "",
		BackgroundColor3 = PANEL2,
		BackgroundTransparency = 0.1,
		Size = UDim2.fromOffset(158, 76),
		LayoutOrder = order,
		Parent = ui.options,
	}, { corner(8), stroke(if picked then WHITE elseif on then GREEN else WHITE, 1, if picked then 0.3 elseif on then 0.45 else 0.9) })
	local t: Frame = new("Frame", { Position = UDim2.fromOffset(5, 6), Size = UDim2.fromOffset(44, 64), Parent = b })
	rarityBack(t, rarity, 7)
	icon(if def then def.icon else slotDef.icon, t, 34)
	label({ Text = if def then rinfo.name else "STOCK", TextSize = 9, Font = Enum.Font.GothamBlack, TextColor3 = rinfo.text, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(55, 4), Size = UDim2.fromOffset(100, 11), Parent = b })
	label({ Text = if def then def.name else "Stock " .. slotDef.name, TextSize = 11, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(55, 15), Size = UDim2.fromOffset(100, 14), Parent = b })
	label({ Text = if def then def.brand else "Factory", TextSize = 9, Font = Enum.Font.GothamMedium, TextColor3 = GREY, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(55, 29), Size = UDim2.fromOffset(100, 11), Parent = b })
	b.Activated:Connect(function()
		Audio.click()
		st.preview = if picked then nil else id
		if def then
			fns.drawer()
		end
		refreshStats()
	end)
	-- the action
	local function pill(text: string, color: Color3, x: number, w: number, fn: (() -> ())?)
		local p = btn(text, { Position = UDim2.fromOffset(x, 46), Size = UDim2.fromOffset(w, 24), BackgroundColor3 = BLACK, BackgroundTransparency = 0.35, TextColor3 = color, TextSize = 10, Parent = b })
		if fn then
			p.Activated:Connect(function()
				Audio.click()
				fn()
			end)
		else
			p.Active = false
		end
	end
	if not def then
		if fitted then
			pill("FIT STOCK", WHITE, 55, 98, function()
				uninstall(slot)
			end)
		else
			pill("FITTED", GREY, 55, 98)
		end
		return
	end
	if id == fitted then
		pill("INSTALLED", GREEN, 55, 98)
		return
	end
	local fits, why = CarStats.fits(st.carId, def.id, now)
	if not fits then
		pill(why == "Needs a turbo" and "NEEDS A TURBO" or why == "Needs a supercharger" and "NEEDS A SC" or why == "Needs a turbo or supercharger" and "NEEDS BOOST" or "DOESN'T FIT", GREY, 55, 98)
		return
	end
	local spare, fee = spareOf(def.id)
	if spare then
		pill(if fee > 0 then "INSTALL " .. short(fee) else "OWNED · INSTALL", WHITE, 55, 98, function()
			install(def.id)
		end)
		return
	end
	local cash, cp = CarStats.partPrice(st.carId, def.id)
	if cp then
		pill("BUY " .. short(cash), GREEN, 55, 62, function()
			buy(def.id, "cash", true)
		end)
		pill(cp .. " CP", GOLD, 119, 34, function()
			buy(def.id, "cp", true)
		end)
	else
		pill("BUY " .. short(cash), GREEN, 55, 98, function()
			buy(def.id, "cash", true)
		end)
	end
end

local function refreshDrawer()
	local cat = catOf(st.cat)
	if not table.find(cat.slots, st.slot) then
		st.slot = cat.slots[1]
	end
	local now = parts()
	ui.drawerTitle.Text = cat.name
	ui.drawerSub.Text = #cat.slots .. " SLOTS · TAP ONE"
	local defs = PartData.BySlot[st.slot] or {}
	ui.drawerSide.Text = string.upper(PartData.Slots[st.slot].name) .. " · " .. (#defs + 1) .. " OPTIONS"
	clear(ui.slots)
	for k, slot in cat.slots do
		local id = now[slot]
		local def = id and PartData.Parts[id]
		local sd = PartData.Slots[slot]
		local sel = slot == st.slot
		local b: TextButton = new("TextButton", { AutoButtonColor = false, Text = "", BackgroundTransparency = 1, Size = UDim2.fromOffset(52, 76), LayoutOrder = k, Parent = ui.slots })
		local t: Frame = new("Frame", { Position = UDim2.fromOffset(3, 4), Size = UDim2.fromOffset(46, 46), Parent = b })
		rarityBack(t, if def then def.rarity else "Common", 8)
		if not def then
			t.BackgroundColor3 = Color3.fromRGB(120, 122, 130)
		end
		icon(if def then def.icon else sd.icon, t, 34).ImageTransparency = if def then 0 else 0.35
		if sel then
			new("UIStroke", { Color = RED, Thickness = 2, Parent = t })
		end
		label({ Text = string.upper(sd.short or sd.name), TextSize = 9, Font = Enum.Font.GothamBlack, TextColor3 = if sel then RED else WHITE, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(-2, 54), Size = UDim2.fromOffset(56, 12), Parent = b })
		b.Activated:Connect(function()
			Audio.click()
			st.slot = slot
			st.preview = nil
			refreshDrawer()
			refreshStats()
		end)
	end
	clear(ui.options)
	if st.slot == "swap" then
		-- 43 engines: the shop's filters are the way to see them
		local go = btn("OPEN ENGINE SWAPS  ›", { Size = UDim2.fromOffset(178, 76), LayoutOrder = 0, TextColor3 = GOLD, BackgroundColor3 = PANEL2, Parent = ui.options })
		go.Activated:Connect(function()
			Audio.click()
			st.shopTab = "swap"
			fns.setTab("SHOP")
		end)
		if now.swap then
			optionCard(1, PartData.Parts[now.swap], "swap")
		end
		optionCard(2, nil, "swap")
	else
		optionCard(0, nil, st.slot)
		local list = table.clone(defs)
		table.sort(list, function(a, b)
			local oa, ob = PartData.Rarity[a.rarity].order, PartData.Rarity[b.rarity].order
			return if oa ~= ob then oa < ob else a.list < b.list
		end)
		for k, def in list do
			optionCard(k, def, st.slot)
		end
	end
	ui.options.CanvasPosition = Vector2.zero
end
fns.drawer = refreshDrawer

---------------------------------------------------------------------
-- the Part Shop
---------------------------------------------------------------------
local function shopList(): { PartData.Part }
	local out: { PartData.Part } = {}
	local tab = st.shopTab
	if tab == "mine" then
		for id in CarUpgrades.bag() do
			if PartData.Parts[id] then
				table.insert(out, PartData.Parts[id])
			end
		end
	elseif tab == "swap" then
		for _, def in PartData.SwapList do
			if st.shopGroup == "All" or (def.engine and def.engine.group == st.shopGroup) then
				table.insert(out, def)
			end
		end
	else
		for _, slot in catOf(tab).slots do
			if slot ~= "swap" then
				for _, def in PartData.BySlot[slot] or {} do
					table.insert(out, def)
				end
			end
		end
	end
	local q = string.lower(st.shopSearch)
	local kept: { PartData.Part } = {}
	for _, def in out do
		local hit = q == "" or string.find(string.lower(def.name .. " " .. def.brand .. " " .. PartData.Slots[def.slot].name), q, 1, true) ~= nil
		if hit and (not st.shopRarity or def.rarity == st.shopRarity) then
			table.insert(kept, def)
		end
	end
	table.sort(kept, function(a, b)
		local oa, ob = PartData.Rarity[a.rarity].order, PartData.Rarity[b.rarity].order
		if oa ~= ob then
			return oa > ob
		end
		return if a.list ~= b.list then a.list > b.list else a.id < b.id
	end)
	return kept
end

local function shopTile(def: PartData.Part, order: number)
	local now = parts()
	local fits = CarStats.fits(st.carId, def.id, now)
	local cash = CarStats.partPrice(st.carId, def.id)
	local rinfo = PartData.Rarity[def.rarity]
	local installed = now[def.slot] == def.id
	local spare = spareOf(def.id)
	local b: TextButton = new("TextButton", { AutoButtonColor = false, Text = "", LayoutOrder = order, ClipsDescendants = true, Parent = ui.grid })
	rarityBack(b, def.rarity, 9)
	if st.shopPick == def.id then
		local s = b:FindFirstChildOfClass("UIStroke")
		if s then
			s.Color = WHITE
			s.Thickness = 2
			s.Transparency = 0
		end
	end
	label({ Text = rinfo.name, TextSize = 8, Font = Enum.Font.GothamBlack, TextColor3 = rinfo.text, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(6, 4), Size = UDim2.new(1, -10, 0, 10), Parent = b })
	local ic = icon(def.icon, b, 44, UDim2.new(0.5, 0, 0, 37))
	label({ Text = def.name, TextSize = 10, Font = Enum.Font.GothamBlack, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Bottom, Position = UDim2.fromOffset(6, 58), Size = UDim2.new(1, -10, 0, 25), Parent = b })
	label({ Text = def.brand .. " · " .. string.upper(PartData.Slots[def.slot].short or PartData.Slots[def.slot].name), TextSize = 7, Font = Enum.Font.GothamMedium, TextColor3 = Color3.fromRGB(226, 228, 232), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(6, 84), Size = UDim2.new(1, -10, 0, 9), Parent = b })
	local bar: Frame = new("Frame", { BackgroundColor3 = BLACK, BackgroundTransparency = 0.45, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 16), Parent = b })
	local text, color
	if installed then
		text, color = "INSTALLED", WHITE
	elseif spare then
		text, color = "OWNED x" .. #(CarUpgrades.bag()[def.id] or {}), GOLD
	elseif not fits then
		text, color = "DOESN'T FIT", Color3.fromRGB(255, 130, 130)
	else
		text, color = money(cash), GREEN
	end
	label({ Text = text, TextSize = 10, Font = Enum.Font.GothamBlack, TextColor3 = color, Size = UDim2.fromScale(1, 1), Parent = bar })
	if not fits and not installed then
		ic.ImageTransparency = 0.55
	else
		label({ Text = "FITS", TextSize = 7, Font = Enum.Font.GothamBlack, TextColor3 = GREEN, TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.fromOffset(0, 4), Size = UDim2.new(1, -6, 0, 10), Parent = b })
	end
	b.Activated:Connect(function()
		Audio.click()
		st.shopPick = def.id
		fns.shop()
	end)
end

local function refreshDetails()
	local d: Frame = ui.details
	clear(d)
	local id = st.shopPick
	local def = id and PartData.Parts[id]
	if not def then
		label({ Text = "Pick a part", TextSize = 13, TextColor3 = GREY, Size = UDim2.fromScale(1, 1), Parent = d })
		return
	end
	local rinfo = PartData.Rarity[def.rarity]
	local now = parts()
	local t: Frame = new("Frame", { Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(58, 58), Parent = d })
	rarityBack(t, def.rarity, 8)
	icon(def.icon, t, 46)
	label({ Text = rinfo.name, TextSize = 9, Font = Enum.Font.GothamBlack, TextColor3 = rinfo.text, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(72, 7), Size = UDim2.fromOffset(112, 11), Parent = d })
	label({ Text = def.name, TextSize = 12, Font = Enum.Font.GothamBlack, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Position = UDim2.fromOffset(72, 19), Size = UDim2.fromOffset(112, 32), Parent = d })
	label({ Text = def.brand .. " · " .. PartData.Slots[def.slot].name, TextSize = 8, Font = Enum.Font.GothamMedium, TextColor3 = GREY, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(72, 53), Size = UDim2.fromOffset(112, 11), Parent = d })
	local y = 72
	local note = def.perk and ("Perk: " .. def.perk) or def.desc
	if def.engine then
		local e = def.engine
		note = string.format("%d hp stock, %d hp tuned max. Revs to %.1fk. %s%s", e.hp, e.tuned, e.redline, if e.kg > 0 then "+" else "", e.kg .. " kg")
	end
	if note then
		label({ Text = note, TextSize = 10, Font = Enum.Font.GothamMedium, TextColor3 = if def.perk then rinfo.text else Color3.fromRGB(214, 216, 222), TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Position = UDim2.fromOffset(9, y), Size = UDim2.fromOffset(172, 26), Parent = d })
		y += 28
	end
	-- what it does on this car
	local set = table.clone(now)
	set[def.slot] = def.id
	local a, b = numbers(now), numbers(set)
	local function row(name: string, text: string)
		label({ Text = name, TextSize = 9, Font = Enum.Font.GothamBold, TextColor3 = GREY, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(9, y), Size = UDim2.fromOffset(60, 13), Parent = d })
		label({ Text = text, TextSize = 10, Font = Enum.Font.GothamBlack, RichText = true, TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.fromOffset(60, y), Size = UDim2.fromOffset(120, 13), Parent = d })
		y += 14
	end
	local function green(s: string): string
		return "<font color=\"#76f09c\">" .. s .. "</font>"
	end
	row("CLASS", if now[def.slot] == def.id then a.letter .. " " .. a.pi else a.letter .. " " .. a.pi .. " → " .. green(b.letter .. " " .. b.pi))
	row("POWER", if a.hp == b.hp then a.hp .. " hp" else a.hp .. " → " .. green(b.hp .. " hp"))
	row("0-100", if math.abs(a.t100 - b.t100) < 0.05 then string.format("%.1f s", a.t100) else string.format("%.1f → ", a.t100) .. green(string.format("%.1f s", b.t100)))
	local fits, why = CarStats.fits(st.carId, def.id, now)
	-- the buttons, from the bottom up
	local by = 318
	local function action(text: string, color: Color3, back: Color3, hgt: number, fn: () -> ())
		by -= hgt + 4
		local b2 = btn(text, { Position = UDim2.fromOffset(8, by), Size = UDim2.fromOffset(172, hgt), BackgroundColor3 = back, TextColor3 = color, TextSize = 11, Parent = d })
		b2.Activated:Connect(function()
			Audio.click()
			fn()
		end)
	end
	local cash, cp = CarStats.partPrice(st.carId, def.id)
	local spare, fee = spareOf(def.id)
	local fitted = now[def.slot] == def.id
	if spare then
		local list = CarUpgrades.bag()[def.id] or {}
		local back = math.floor(Config.partCash(def.list, spare, def.engine ~= nil) * Config.CarParts.SellShare / 100 + 0.5) * 100
		action("SELL ONE  " .. short(back), WHITE, PANEL2, 24, function()
			act("sell", { part = def.id }, "Sold")
		end)
		if not fitted and fits then
			action((if fee > 0 then "INSTALL · FEE " .. short(fee) else "INSTALL") .. (if #list > 1 then "  (x" .. #list .. ")" else ""), Color3.fromRGB(14, 40, 22), GREEN, 28, function()
				install(def.id)
			end)
		end
	end
	if fitted then
		action("UNINSTALL", WHITE, PANEL2, 24, function()
			uninstall(def.slot)
		end)
	end
	if not fits and not fitted then
		label({ Text = why or "Doesn't fit this car", TextSize = 10, Font = Enum.Font.GothamBold, TextColor3 = Color3.fromRGB(255, 130, 130), TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(9, by - 36), Size = UDim2.fromOffset(172, 30), Parent = d })
	elseif not spare then
		if cp then
			action("BUY WITH " .. cp .. " CP", GOLD, PANEL2, 24, function()
				buy(def.id, "cp", false)
			end)
		end
		action("BUY  " .. money(cash), GREEN, PANEL2, 24, function()
			buy(def.id, "cash", false)
		end)
		action("BUY & INSTALL  " .. short(cash), Color3.fromRGB(14, 40, 22), GREEN, 30, function()
			buy(def.id, "cash", true)
		end)
	end
end

local function refreshShop()
	-- tabs
	for key, b in ui.shopTabs do
		local on = key == st.shopTab
		b.BackgroundColor3 = if on then RED else PANEL2
		b.TextColor3 = if on then WHITE else GREY
	end
	for key, b in ui.rarityBtns do
		local on = (key == "All" and st.shopRarity == nil) or key == st.shopRarity
		b.BackgroundColor3 = if on then WHITE else PANEL2
		b.TextColor3 = if on then Color3.fromRGB(16, 16, 20) elseif key ~= "All" then PartData.Rarity[key].text else GREY
	end
	ui.groupRow.Visible = st.shopTab == "swap"
	for key, b in ui.groupBtns do
		local on = key == st.shopGroup
		b.BackgroundColor3 = if on then GOLD else PANEL2
		b.TextColor3 = if on then Color3.fromRGB(16, 16, 20) else GREY
	end
	ui.grid.Position = UDim2.fromOffset(64, if st.shopTab == "swap" then 54 else 30)
	ui.grid.Size = UDim2.fromOffset(456, if st.shopTab == "swap" then 298 else 322)
	clear(ui.grid)
	local list = shopList()
	for k, def in list do
		shopTile(def, k)
	end
	ui.shopEmpty.Visible = #list == 0
	ui.shopEmpty.Text = if st.shopTab == "mine" then "No spare parts. Parts you take off a car come here" else "Nothing matches"
	refreshDetails()
end
fns.shop = refreshShop

---------------------------------------------------------------------
-- TUNE
---------------------------------------------------------------------
local function tuneValueText(def: any, v: number): string
	if def.rpm then
		return string.format("%d rpm", math.floor(v * CarStats.redlineOf(st.carId, parts()) * 10 + 0.5) * 100)
	elseif def.key == "bias" then
		return string.format("%d%% front", math.floor(v * 100 + 0.5))
	end
	local p = math.floor((v - def.def) * 100 + 0.5)
	return if p == 0 then "STOCK" elseif p > 0 then "+" .. p else tostring(p)
end

local function sendSetup(values: { [string]: number })
	task.spawn(function()
		CarUpgrades.ask("setup", { car = st.carId, values = values })
	end)
end

local function refreshTune()
	clear(ui.tuneRows)
	local info = CarUpgrades.get(st.carId)
	local values: { [string]: number } = table.clone(info.setup)
	local now = parts()
	local n = 0
	for _, def in PartData.Tune do
		if def.wing and not now.wing then
			continue
		end
		n += 1
		local col, row = (n - 1) % 2, (n - 1) // 2
		local f: Frame = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(4 + col * 356, 2 + row * 46), Size = UDim2.fromOffset(346, 44), Parent = ui.tuneRows })
		label({ Text = string.upper(def.name), TextSize = 10, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.fromOffset(180, 12), Parent = f })
		local valueText = label({ Text = "", TextSize = 10, Font = Enum.Font.GothamBlack, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.fromOffset(180, 0), Size = UDim2.fromOffset(166, 12), Parent = f })
		label({ Text = def.help, TextSize = 9, Font = Enum.Font.GothamMedium, TextColor3 = GREY, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(0, 12), Size = UDim2.fromOffset(346, 11), Parent = f })
		local track: TextButton = new("TextButton", { AutoButtonColor = false, Text = "", BackgroundColor3 = Color3.fromRGB(52, 54, 62), BorderSizePixel = 0, Position = UDim2.fromOffset(0, 30), Size = UDim2.fromOffset(346, 6), Parent = f }, { corner(3) })
		local fill: Frame = new("Frame", { BackgroundColor3 = RED, BorderSizePixel = 0, Parent = track }, { corner(3) })
		local knob: Frame = new("Frame", { BackgroundColor3 = WHITE, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(16, 16), Parent = track }, { corner(8) })
		local function show(v: number)
			local k = (v - def.min) / (def.max - def.min)
			local zero = math.clamp((def.def - def.min) / (def.max - def.min), 0, 1)
			if def.rpm then
				zero = 0
			end
			fill.Position = UDim2.fromScale(math.min(zero, k), 0)
			fill.Size = UDim2.fromScale(math.abs(k - zero), 1)
			knob.Position = UDim2.fromScale(k, 0.5)
			valueText.Text = tuneValueText(def, v)
		end
		show(values[def.key] or def.def)
		local dragging = false
		local function setFrom(x: number)
			local k = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
			local v = def.min + k * (def.max - def.min)
			v = math.clamp(def.min + math.floor((v - def.min) / def.step + 0.5) * def.step, def.min, def.max)
			if math.abs(v - def.def) < def.step / 2 then
				v = def.def
			end
			values[def.key] = v
			show(v)
		end
		track.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				setFrom(input.Position.X)
			end
		end)
		table.insert(conns, UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				setFrom(input.Position.X)
			end
		end))
		table.insert(conns, UserInputService.InputEnded:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
				dragging = false
				Audio.click()
				sendSetup(values)
			end
		end))
	end
	-- the builds
	local b = info.builds
	local active = if type(b) == "table" and type(b.active) == "number" then b.active else 1
	local list = if type(b) == "table" and type(b.list) == "table" then b.list else {}
	for n2, pill in ui.buildBtns do
		local on = n2 == active
		pill.BackgroundColor3 = if on then RED else PANEL2
		pill.TextColor3 = if on then WHITE else GREY
		local has = type(list[n2]) == "table" and next(list[n2]) ~= nil
		pill.Text = PartData.BuildNames[n2] .. (if has or on then "" else " +")
	end
end
fns.tune = refreshTune

---------------------------------------------------------------------
-- DYNO RUN
---------------------------------------------------------------------
local function line(parent: Instance, a: Vector2, b: Vector2, color: Color3, thick: number, transparency: number?): Frame
	local d = b - a
	return new("Frame", {
		BackgroundColor3 = color,
		BackgroundTransparency = transparency or 0,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset((a.X + b.X) / 2, (a.Y + b.Y) / 2),
		Size = UDim2.fromOffset(d.Magnitude + 1, thick),
		Rotation = math.deg(math.atan2(d.Y, d.X)),
		Parent = parent,
	})
end

local function dynoFlames(): { ParticleEmitter }
	local out = {}
	local m = car
	local root = m and m.PrimaryPart
	if not (m and root) then
		return out
	end
	local i = 1
	while true do
		local p = m:GetAttribute("Exhaust" .. i)
		if typeof(p) ~= "Vector3" then
			break
		end
		local att = Instance.new("Attachment")
		att.Position = p
		att.Parent = root
		local e = Instance.new("ParticleEmitter")
		e.Rate = 0
		e.LockedToPart = true
		e.EmissionDirection = Enum.NormalId.Back
		e.Lifetime = NumberRange.new(0.05, 0.14)
		e.Speed = NumberRange.new(8, 15)
		e.SpreadAngle = Vector2.new(8, 8)
		e.Size = NumberSequence.new(0.34, 0.04)
		e.Color = ColorSequence.new(Color3.fromRGB(90, 140, 255), Color3.fromRGB(255, 150, 50))
		e.Transparency = NumberSequence.new(0.05, 1)
		e.LightEmission = 1
		e.Brightness = 2
		e.Parent = att
		table.insert(out, e)
		i += 1
	end
	return out
end

local function dynoRun()
	if st.dyno then
		return
	end
	st.dyno = true
	local carId = st.carId
	local spec = st.spec
	local set = parts()
	local clean = CarStats.cleanParts(carId, set)
	local tune = CarStats.tuneOf(clean)
	local dyno = CarStats.dyno(carId, set)
	local stock = CarStats.dyno(carId, nil)
	local panelF: Frame = ui.dynoPanel
	ui.right.Visible = false
	ui.drawer.Visible = false
	ui.rail.Visible = false
	ui.pinLayer.Visible = false
	panelF.Visible = true
	ui.dynoResult.Text = ""
	ui.dynoClose.Visible = false
	clear(ui.dynoGraph)
	-- the axes
	local gw, gh = 330, 104
	local topHp, topNm = math.max(dyno.hp, stock.hp) * 1.08, math.max(dyno.nm, stock.nm) * 1.08
	for k = 0, 4 do
		line(ui.dynoGraph, Vector2.new(0, k * gh / 4), Vector2.new(gw, k * gh / 4), WHITE, 1, 0.9)
	end
	local maxRpm = math.max(dyno.redline, stock.redline)
	for k = 1, math.floor(maxRpm / 1000) do
		local x = k * 1000 / maxRpm * gw
		line(ui.dynoGraph, Vector2.new(x, 0), Vector2.new(x, gh), WHITE, 1, 0.94)
		if k % 2 == 0 then
			label({ Text = tostring(k) .. "k", TextSize = 8, TextColor3 = GREY, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(x, gh + 1), Size = UDim2.fromOffset(20, 10), Parent = ui.dynoGraph })
		end
	end
	local function px(p: any, v: number, top: number): Vector2
		return Vector2.new(p.rpm / maxRpm * gw, gh - v / top * gh)
	end
	-- the stock curve, faint, then the live ones
	for k = 2, #stock.points do
		line(ui.dynoGraph, px(stock.points[k - 1], stock.points[k - 1].hp, topHp), px(stock.points[k], stock.points[k].hp, topHp), WHITE, 1, 0.65)
	end
	local segs: { { rpm: number, hp: Frame, nm: Frame } } = {}
	for k = 2, #dyno.points do
		local a, b = dyno.points[k - 1], dyno.points[k]
		local h = line(ui.dynoGraph, px(a, a.hp, topHp), px(b, b.hp, topHp), RED, 2)
		local n = line(ui.dynoGraph, px(a, a.nm, topNm), px(b, b.nm, topNm), GOLD, 2)
		h.Visible, n.Visible = false, false
		table.insert(segs, { rpm = b.rpm, hp = h, nm = n })
	end
	pose("dyno")
	wantShift, wantShiftY = 0, 0.5
	Driving.muteEngine(true)
	task.spawn(function()
		-- down onto the rollers
		local t0 = os.clock()
		while os.clock() - t0 < 0.9 and open and st and st.dyno do
			local k = (os.clock() - t0) / 0.9
			putCar(LIFT * (1 - k * k * (3 - 2 * k)))
			task.wait()
		end
		putCar(0)
		if not (open and st and st.dyno) then
			return
		end
		local engine = Audio.engine(spec.Class, nil, spec.Id, tune.engine and tune.engine.layout)
		engine:setRedline(dyno.redline)
		engine:setMods(tune)
		engine:setRunning(not spec.Electric)
		if not spec.Electric then
			engine:crank()
		end
		task.wait(if spec.Electric then 0.2 else 1)
		local flames = dynoFlames()
		local driven = CarStats.of(carId).drive
		local spin = 0
		local rate = 0
		local function step(r: number, throttle: number, dt: number)
			engine:update(r, throttle, 0, 0, 1, 0)
			rate = r * 70
			spin -= rate * dt
			for _, w in wheelMotors do
				if driven == "AWD" or (driven == "FWD") == w.front then
					w.motor.Transform = CFrame.Angles(spin, 0, 0)
				end
			end
			for i, p in rollers do
				p.CFrame *= CFrame.Angles(rate * dt * 2 * (if i % 2 == 0 then 1 else -1), 0, 0)
			end
		end
		-- the pull: idle to the limiter
		local T = 5
		local start = os.clock()
		local last = start
		while open and st and st.dyno do
			local now = os.clock()
			local k = (now - start) / T
			if k >= 1 then
				break
			end
			local r = 0.14 + 0.86 * k ^ 1.1
			step(r, 1, now - last)
			last = now
			local rpm = r * dyno.redline
			local hpNow = 0
			for _, s in segs do
				local on = s.rpm <= rpm
				s.hp.Visible, s.nm.Visible = on, on
			end
			for _, p in dyno.points do
				if p.rpm <= rpm then
					hpNow = math.max(hpNow, p.hp)
				end
			end
			ui.dynoLive.Text = string.format("%d rpm    %d hp", math.floor(rpm / 50) * 50, hpNow)
			task.wait()
		end
		for _, s in segs do
			s.hp.Visible, s.nm.Visible = true, true
		end
		-- on the limiter, then off the throttle: the car's pops
		local holdStart = os.clock()
		last = holdStart
		while open and st and st.dyno and os.clock() - holdStart < 0.7 do
			local now = os.clock()
			step(0.97 + 0.03 * math.sin(now * 40), 1, now - last)
			last = now
			task.wait()
		end
		local liftStart = os.clock()
		last = liftStart
		local nextPop = liftStart + 0.05
		local pops = if tune.pop == "crackle" or tune.pop == "antilag" then 10 elseif tune.pop == "pop" then 6 elseif tune.pop == "burble" then 4 else 2
		while open and st and st.dyno and os.clock() - liftStart < 2 do
			local now = os.clock()
			step(0.14 + 0.83 * math.max(0, 1 - (now - liftStart) / 1.6) ^ 2, 0, now - last)
			last = now
			if pops > 0 and now >= nextPop and not spec.Electric then
				pops -= 1
				nextPop = now + 0.07 + math.random() * 0.12
				engine:pop(0.6 + math.random() * 0.4)
				for _, e in flames do
					e:Emit(if tune.loud >= 2 or tune.decat then 7 else 3)
				end
			end
			task.wait()
		end
		engine:destroy()
		for _, w in wheelMotors do
			w.motor.Transform = CFrame.new()
		end
		for _, e in flames do
			if e.Parent then
				e.Parent:Destroy()
			end
		end
		if not (open and st and st.dyno) then
			return
		end
		local a, b = math.floor(stock.hp + 0.5), math.floor(dyno.hp + 0.5)
		ui.dynoResult.Text = if b ~= a then string.format("%d hp  →  %d hp  (%s%d)", a, b, if b > a then "+" else "", b - a) else string.format("%d hp  ·  stock", b)
		ui.dynoLive.Text = string.format("%d Nm    redline %.1fk", dyno.nm, dyno.redline / 1000)
		Audio.cutUp(8, "DYNO")
		ui.dynoClose.Visible = true
	end)
end

local function dynoDone()
	st.dyno = false
	Driving.muteEngine(false)
	ui.dynoPanel.Visible = false
	ui.right.Visible = st.tab == "UPGRADE"
	ui.drawer.Visible = st.tab == "UPGRADE"
	ui.rail.Visible = st.tab == "UPGRADE"
	ui.pinLayer.Visible = st.tab == "UPGRADE"
	pose("home")
	wantShift, wantShiftY = if st.tab == "UPGRADE" then 1 else 0, 0.24
	task.spawn(function()
		local t0 = os.clock()
		while os.clock() - t0 < 0.9 and open do
			local k = (os.clock() - t0) / 0.9
			putCar(LIFT * k * k * (3 - 2 * k))
			task.wait()
		end
		if open then
			putCar(LIFT)
		end
	end)
end

---------------------------------------------------------------------
-- the screen
---------------------------------------------------------------------
local function setTab(name: string)
	if st.dyno then
		return
	end
	if name == "STYLE" then
		-- (opened from Legends Customs: its paint screen is underneath)
		if savedHold and savedHold[1] then
			Workshop.close()
		else
			showMsg("Paint and looks are at Legends Customs: stop in the tuning bay", GOLD)
		end
		return
	end
	st.tab = name
	for key, b in ui.tabs do
		local on = key == name
		b.BackgroundColor3 = if on then RED else PANEL
		b.BackgroundTransparency = if on then 0 else 1
		b.TextColor3 = if on then WHITE else GREY
	end
	local up = name == "UPGRADE"
	ui.right.Visible = up
	ui.drawer.Visible = up
	ui.rail.Visible = up
	ui.pinLayer.Visible = up
	ui.shop.Visible = name == "SHOP"
	ui.tune.Visible = name == "TUNE"
	wantShift = if up then 1 else 0
	if name == "SHOP" then
		st.shopPick = nil
		if st.shopTab ~= "swap" and st.shopTab ~= "mine" then
			st.shopTab = st.cat
		end
		refreshShop()
	elseif name == "TUNE" then
		refreshTune()
	end
end
fns.setTab = setTab

local function setCat(key: string, zoom: boolean?)
	st.cat = key
	st.slot = catOf(key).slots[1]
	st.preview = nil
	for k, b in ui.rails do
		local on = k == key
		b.back.BackgroundColor3 = if on then RED else PANEL2
		b.text.TextColor3 = if on then WHITE else GREY
	end
	refreshDrawer()
	refreshStats()
	if zoom ~= false then
		pose(catOf(key).zoom)
	end
end

refreshAll = function()
	if not open or not st then
		return
	end
	refreshStats()
	refreshPins()
	if st.tab == "UPGRADE" then
		refreshDrawer()
	elseif st.tab == "SHOP" then
		refreshShop()
	elseif st.tab == "TUNE" then
		refreshTune()
	end
end

local function buildGui()
	local g = Instance.new("ScreenGui")
	g.Name = "Workshop"
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	g.DisplayOrder = 60
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	g.Parent = player:WaitForChild("PlayerGui")
	gui = g
	table.clear(ui)
	ui.pins = {}
	ui.rails = {}
	ui.tabs = {}
	ui.stat = {}

	-- a drag anywhere on the car turns round it
	local drag: TextButton = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = g })
	-- soft dark bands top and bottom, so the panels sit on the room
	new("Frame", { BackgroundColor3 = BLACK, BorderSizePixel = 0, Size = UDim2.fromScale(1, 0.2), Parent = g }, { new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(0.35, 1) }) })
	new("Frame", { BackgroundColor3 = BLACK, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0.34), Parent = g }, { new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new(1, 0.25) }) })
	local root: Frame = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(W, H), Parent = g })
	ui.root = root
	local scale: UIScale = new("UIScale", { Parent = root })
	ui.scale = scale
	local function fit()
		local v = viewport()
		scale.Scale = math.min(v.X / W, v.Y / H)
	end
	fit()
	table.insert(conns, camera:GetPropertyChangedSignal("ViewportSize"):Connect(fit))

	-- the pins (under the panels)
	local pinLayer: Frame = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(W, H), Parent = root })
	ui.pinLayer = pinLayer
	for _, key in { "engine", "boost", "exhaust", "grip", "chassis" } do
		local b: TextButton = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Size = UDim2.fromOffset(104, 24), Parent = pinLayer })
		local halo: Frame = new("Frame", { BackgroundTransparency = 0.6, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(9, 12), Size = UDim2.fromOffset(18, 18), Parent = b }, { corner(9) })
		local dot: Frame = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(9, 12), Size = UDim2.fromOffset(10, 10), Parent = b }, { corner(5) })
		local tag: Frame = new("Frame", { BackgroundColor3 = PANEL, BackgroundTransparency = 0.12, Position = UDim2.fromOffset(21, 3), Size = UDim2.fromOffset(82, 18), Parent = b }, { corner(9) })
		local text = label({ Text = "", TextSize = 9, Font = Enum.Font.GothamBlack, Size = UDim2.fromScale(1, 1), Parent = tag })
		ui.pins[key] = { button = b, dot = dot, halo = halo, text = text }
		b.Activated:Connect(function()
			Audio.click()
			setCat(key)
		end)
	end

	-- the top bar
	local x0 = if UI.isTouch then 50 else 12
	local chip: Frame = new("Frame", { BackgroundColor3 = BLUE, Position = UDim2.fromOffset(x0, 8), Size = UDim2.fromOffset(34, 34), Parent = root }, { corner(8) })
	ui.chip = chip
	ui.chipLetter = label({ Text = "", TextSize = 14, Font = Enum.Font.GothamBlack, Position = UDim2.fromOffset(0, 3), Size = UDim2.new(1, 0, 0, 16), Parent = chip })
	ui.chipPi = label({ Text = "", TextSize = 10, Font = Enum.Font.GothamBlack, Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 12), Parent = chip })
	label({ Text = st.spec.Name, TextSize = 15, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(x0 + 40, 8), Size = UDim2.fromOffset(204 - (x0 - 12), 18), Parent = root })
	ui.subName = label({ Text = "", TextSize = 8, Font = Enum.Font.GothamBold, TextColor3 = GREY, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(x0 + 40, 27), Size = UDim2.fromOffset(204 - (x0 - 12), 11), Parent = root })
	local pills: Frame = panel({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(372, 9), Size = UDim2.fromOffset(232, 32), Parent = root })
	round(pills, 16)
	for k, name in { "UPGRADE", "SHOP", "TUNE", "STYLE" } do
		local b = btn(name, { Position = UDim2.fromOffset(4 + (k - 1) * 56, 3), Size = UDim2.fromOffset(56, 26), TextSize = 10, BackgroundTransparency = 1, Parent = pills })
		round(b, 13)
		ui.tabs[name] = b
		b.Activated:Connect(function()
			Audio.click()
			setTab(name)
		end)
	end
	local cashPill: Frame = panel({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromOffset(638, 11), Size = UDim2.fromOffset(92 - 2, 28), Parent = root })
	round(cashPill, 14)
	ui.cashText = label({ Text = "", TextSize = 11, Font = Enum.Font.GothamBlack, TextColor3 = GREEN, TextTruncate = Enum.TextTruncate.AtEnd, Size = UDim2.fromScale(1, 1), Parent = cashPill })
	local cpPill: Frame = panel({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromOffset(694, 11), Size = UDim2.fromOffset(52, 28), Parent = root })
	round(cpPill, 14)
	ui.cpText = label({ Text = "", TextSize = 10, Font = Enum.Font.GothamBlack, TextColor3 = GOLD, Size = UDim2.fromScale(1, 1), Parent = cpPill })
	local closeBtn = btn("×", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromOffset(730, 9), Size = UDim2.fromOffset(32, 32), BackgroundColor3 = PANEL, TextColor3 = RED, TextSize = 14, Parent = root })
	round(closeBtn, 16)
	closeBtn.Activated:Connect(function()
		Audio.click()
		Workshop.close()
	end)

	-- the left rail
	local rail: Frame = panel({ Position = UDim2.fromOffset(10, 48), Size = UDim2.fromOffset(46, 256), Parent = root })
	ui.rail = rail
	for k, cat in PartData.Cats do
		local b: TextButton = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 3 + (k - 1) * 36), Size = UDim2.new(1, 0, 0, 36), Parent = rail })
		local back: Frame = new("Frame", { BackgroundColor3 = PANEL2, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.fromOffset(26, 26), Parent = b }, { corner(13) })
		icon(cat.icon, back, 19)
		local text = label({ Text = cat.name, TextSize = 7.5, Font = Enum.Font.GothamBlack, TextColor3 = GREY, Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, 9), Parent = b })
		ui.rails[cat.key] = { back = back, text = text }
		b.Activated:Connect(function()
			Audio.click()
			setCat(cat.key)
		end)
	end

	-- the right panel
	local right: Frame = panel({ Position = UDim2.fromOffset(548, 48), Size = UDim2.fromOffset(182, 256), Parent = root })
	ui.right = right
	label({ Text = "PERFORMANCE INDEX", TextSize = 8, Font = Enum.Font.GothamBlack, TextColor3 = GREY, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(10, 7), Size = UDim2.fromOffset(160, 10), Parent = right })
	local piRing, setPi = ring(right, 66, UDim2.fromOffset(8, 20), BLUE)
	ui.piRing = setPi
	ui.piLetter = label({ Text = "", TextSize = 17, Font = Enum.Font.GothamBlack, Position = UDim2.fromOffset(0, 13), Size = UDim2.new(1, 0, 0, 20), Parent = piRing })
	ui.piNumber = label({ Text = "", TextSize = 11, Font = Enum.Font.GothamBlack, Position = UDim2.fromOffset(0, 33), Size = UDim2.new(1, 0, 0, 14), Parent = piRing })
	ui.piChange = label({ Text = "", TextSize = 20, Font = Enum.Font.GothamBlack, TextColor3 = GREEN, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(80, 20), Size = UDim2.fromOffset(96, 24), Parent = right })
	ui.piLine1 = label({ Text = "", TextSize = 9, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(80, 45), Size = UDim2.fromOffset(98, 12), Parent = right })
	ui.piLine2 = label({ Text = "", TextSize = 9, Font = Enum.Font.GothamMedium, TextColor3 = GREY, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(80, 58), Size = UDim2.fromOffset(98, 22), TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Parent = right })
	for k, s in { { "power", "POWER" }, { "t100", "0-100" }, { "top", "TOP SPEED" }, { "grip", "GRIP" } } do
		local col, row = (k - 1) % 2, (k - 1) // 2
		local f: Frame = new("Frame", { BackgroundColor3 = PANEL2, BackgroundTransparency = 0.25, Position = UDim2.fromOffset(6 + col * 86, 92 + row * 58), Size = UDim2.fromOffset(84, 54), Parent = right }, { corner(8) })
		local _, set = ring(f, 22, UDim2.fromOffset(5, 5), GREEN)
		label({ Text = s[2], TextSize = 8, Font = Enum.Font.GothamBlack, TextColor3 = GREY, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(31, 10), Size = UDim2.fromOffset(52, 10), Parent = f })
		local value = label({ Text = "", TextSize = 12, Font = Enum.Font.GothamBlack, RichText = true, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(6, 32), Size = UDim2.fromOffset(76, 16), Parent = f })
		ui.stat[s[1]] = { value = value, set = set }
	end
	local dynoBtn = btn("▶  DYNO RUN", { Position = UDim2.fromOffset(8, 212), Size = UDim2.fromOffset(166, 36), BackgroundColor3 = RED, TextSize = 13, Parent = right })
	dynoBtn.Activated:Connect(function()
		Audio.click()
		dynoRun()
	end)

	-- the bottom drawer
	local drawer: Frame = panel({ Position = UDim2.fromOffset(10, 310), Size = UDim2.fromOffset(720, 100), Parent = root })
	ui.drawer = drawer
	ui.drawerTitle = label({ Text = "", TextSize = 13, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(10, 3), Size = UDim2.fromOffset(84, 15), Parent = drawer })
	ui.drawerSub = label({ Text = "", TextSize = 8, Font = Enum.Font.GothamBold, TextColor3 = GREY, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(92, 5), Size = UDim2.fromOffset(160, 12), Parent = drawer })
	ui.drawerSide = label({ Text = "", TextSize = 8, Font = Enum.Font.GothamBold, TextColor3 = GREY, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 5), Size = UDim2.fromOffset(300, 12), Parent = drawer })
	ui.slots = new("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(6, 19),
		Size = UDim2.fromOffset(268, 79),
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = LINE,
		ScrollingDirection = Enum.ScrollingDirection.X,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		CanvasSize = UDim2.new(),
		Parent = drawer,
	}, { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 1), SortOrder = Enum.SortOrder.LayoutOrder }) })
	new("Frame", { BackgroundColor3 = LINE, BorderSizePixel = 0, Position = UDim2.fromOffset(278, 24), Size = UDim2.fromOffset(1, 66), Parent = drawer })
	ui.options = new("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(284, 19),
		Size = UDim2.fromOffset(432, 79),
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = LINE,
		ScrollingDirection = Enum.ScrollingDirection.X,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		CanvasSize = UDim2.new(),
		Parent = drawer,
	}, { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }) })

	-- SHOP
	local shop: Frame = panel({ Position = UDim2.fromOffset(10, 48), Size = UDim2.fromOffset(720, 362), BackgroundTransparency = 0.04, Visible = false, Parent = root })
	ui.shop = shop
	ui.shopTabs = {}
	local tabs: { any } = {}
	for _, c in PartData.Cats do
		table.insert(tabs, { c.key, c.name })
	end
	table.insert(tabs, { "swap", "SWAPS" })
	table.insert(tabs, { "mine", "MY PARTS" })
	for k, t in tabs do
		local b = btn(t[2], { Position = UDim2.fromOffset(6 + (k - 1) * 58, 6), Size = UDim2.fromOffset(56, 20), TextSize = 9, Parent = shop })
		ui.shopTabs[t[1]] = b
		b.Activated:Connect(function()
			Audio.click()
			st.shopTab = t[1]
			st.shopPick = nil
			refreshShop()
		end)
	end
	local search: TextBox = new("TextBox", {
		BackgroundColor3 = PANEL2,
		PlaceholderText = "Search",
		PlaceholderColor3 = GREY,
		Text = "",
		ClearTextOnFocus = false,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = WHITE,
		Position = UDim2.fromOffset(530, 6),
		Size = UDim2.fromOffset(184, 20),
		Parent = shop,
	}, { corner(6) })
	table.insert(conns, search:GetPropertyChangedSignal("Text"):Connect(function()
		st.shopSearch = search.Text
		task.delay(0.15, function()
			if open and st and st.shopSearch == search.Text then
				refreshShop()
			end
		end)
	end))
	ui.rarityBtns = {}
	local rarityKeys = { "All", "Common", "Uncommon", "Rare", "Epic", "Legendary" }
	for k, key in rarityKeys do
		local b = btn(string.upper(if key == "Legendary" then "Legend." elseif key == "Uncommon" then "Uncomm." else key), { Position = UDim2.fromOffset(6, 30 + (k - 1) * 26), Size = UDim2.fromOffset(54, 23), TextSize = 9, Parent = shop })
		ui.rarityBtns[key] = b
		b.Activated:Connect(function()
			Audio.click()
			st.shopRarity = if key == "All" then nil else key
			refreshShop()
		end)
	end
	local groupRow: Frame = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(64, 30), Size = UDim2.fromOffset(456, 20), Visible = false, Parent = shop })
	ui.groupRow = groupRow
	ui.groupBtns = {}
	for k, key in PartData.SwapGroups do
		local b = btn(string.upper(key), { Position = UDim2.fromOffset((k - 1) * 76, 0), Size = UDim2.fromOffset(72, 20), TextSize = 9, Parent = groupRow })
		ui.groupBtns[key] = b
		b.Activated:Connect(function()
			Audio.click()
			st.shopGroup = key
			refreshShop()
		end)
	end
	ui.grid = new("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(64, 30),
		Size = UDim2.fromOffset(456, 322),
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = LINE,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = shop,
	}, { new("UIGridLayout", { CellSize = UDim2.fromOffset(86, 112), CellPadding = UDim2.fromOffset(4, 5), SortOrder = Enum.SortOrder.LayoutOrder }) })
	ui.shopEmpty = label({ Text = "", TextSize = 12, TextColor3 = GREY, Position = UDim2.fromOffset(64, 80), Size = UDim2.fromOffset(456, 20), Visible = false, Parent = shop })
	ui.details = panel({ BackgroundColor3 = PANEL2, BackgroundTransparency = 0.2, Position = UDim2.fromOffset(526, 32), Size = UDim2.fromOffset(188, 322), Parent = shop })

	-- TUNE
	local tune: Frame = panel({ Position = UDim2.fromOffset(10, 232), Size = UDim2.fromOffset(720, 178), Visible = false, Parent = root })
	ui.tune = tune
	label({ Text = "TUNE", TextSize = 13, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(10, 5), Size = UDim2.fromOffset(60, 16), Parent = tune })
	label({ Text = "Small changes, free, saved on this car", TextSize = 9, Font = Enum.Font.GothamMedium, TextColor3 = GREY, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(56, 8), Size = UDim2.fromOffset(200, 12), Parent = tune })
	ui.buildBtns = {}
	label({ Text = "BUILDS", TextSize = 9, Font = Enum.Font.GothamBlack, TextColor3 = GREY, TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.fromOffset(250, 8), Size = UDim2.fromOffset(46, 12), Parent = tune })
	for n = 1, PartData.MaxBuilds do
		local b = btn(PartData.BuildNames[n], { Position = UDim2.fromOffset(300 + (n - 1) * 72, 4), Size = UDim2.fromOffset(68, 22), TextSize = 9, Parent = tune })
		ui.buildBtns[n] = b
		b.Activated:Connect(function()
			Audio.click()
			local info = CarUpgrades.get(st.carId)
			local bd = info.builds
			local has = type(bd) == "table" and type(bd.list) == "table" and type(bd.list[n]) == "table" and next(bd.list[n]) ~= nil
			if has then
				act("useBuild", { n = n }, PartData.BuildNames[n] .. " build on")
			else
				act("saveBuild", { n = n }, "Saved as " .. PartData.BuildNames[n])
			end
		end)
	end
	local saveBtn = btn("SAVE", { Position = UDim2.fromOffset(518, 4), Size = UDim2.fromOffset(52, 22), TextSize = 9, Parent = tune })
	saveBtn.Activated:Connect(function()
		Audio.click()
		local bd = CarUpgrades.get(st.carId).builds
		local n = if type(bd) == "table" and type(bd.active) == "number" then bd.active else 1
		act("saveBuild", { n = n }, "Saved as " .. PartData.BuildNames[n])
	end)
	local resetBtn = btn("RESET", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 4), Size = UDim2.fromOffset(58, 22), TextSize = 9, TextColor3 = RED, Parent = tune })
	resetBtn.Activated:Connect(function()
		Audio.click()
		task.spawn(function()
			CarUpgrades.ask("setup", { car = st.carId, values = {} })
			showMsg("Back to stock settings", GREEN)
			refreshTune()
		end)
	end)
	ui.tuneRows = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(8, 30), Size = UDim2.fromOffset(704, 144), Parent = tune })

	-- the dyno's panel
	local dp: Frame = panel({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(370, 232), Size = UDim2.fromOffset(372, 178), Visible = false, Parent = root })
	ui.dynoPanel = dp
	label({ Text = "DYNO", TextSize = 13, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(12, 5), Size = UDim2.fromOffset(60, 16), Parent = dp })
	label({ Text = "<font color=\"#e6383e\">■</font> POWER   <font color=\"#ffbe50\">■</font> TORQUE   <font color=\"#9a9aa2\">■</font> STOCK", RichText = true, TextSize = 8, Font = Enum.Font.GothamBold, TextColor3 = GREY, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(62, 8), Size = UDim2.fromOffset(190, 12), Parent = dp })
	ui.dynoLive = label({ Text = "", TextSize = 10, Font = Enum.Font.GothamBlack, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 7), Size = UDim2.fromOffset(150, 12), Parent = dp })
	ui.dynoGraph = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(21, 26), Size = UDim2.fromOffset(330, 104), ClipsDescendants = false, Parent = dp })
	ui.dynoResult = label({ Text = "", TextSize = 14, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -7), Size = UDim2.fromOffset(280, 20), Parent = dp })
	ui.dynoClose = btn("DONE", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -8, 1, -6), Size = UDim2.fromOffset(62, 24), BackgroundColor3 = RED, Visible = false, Parent = dp })
	ui.dynoClose.Activated:Connect(function()
		Audio.click()
		dynoDone()
	end)

	-- a message line
	ui.msg = label({ Text = "", TextSize = 12, Font = Enum.Font.GothamBlack, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromOffset(300, 46), Size = UDim2.fromOffset(470, 18), TextStrokeTransparency = 0.5, Visible = false, ZIndex = 5, Parent = root })

	-- dragging turns round the car, the wheel comes closer
	local dragging = false
	local lastPos = Vector2.zero
	drag.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			lastPos = Vector2.new(input.Position.X, input.Position.Y)
			idle = 0
		end
	end)
	table.insert(conns, UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local p = Vector2.new(input.Position.X, input.Position.Y)
			local d = p - lastPos
			lastPos = p
			yaw -= d.X * 0.008
			wantYaw = yaw
			pitch = math.clamp(pitch + d.Y * 0.005, 0.03, 0.75)
			wantPitch = pitch
			idle = 0
			posed = false
		elseif input.UserInputType == Enum.UserInputType.MouseWheel then
			wantDist = math.clamp(wantDist * (1 - input.Position.Z * 0.08), carL * 0.7, carL * 2.4 + 10)
		end
	end))
	table.insert(conns, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end))
	table.insert(conns, UserInputService.InputBegan:Connect(function(input, processed)
		if input.KeyCode == Enum.KeyCode.Escape or (not processed and input.KeyCode == Enum.KeyCode.Backspace) then
			if not (st and st.dyno) then
				Workshop.close()
			end
		end
	end))
	table.insert(conns, CarUpgrades.onChangeConn(function()
		if open and st and not st.busy then
			refreshAll()
		end
	end))
end

---------------------------------------------------------------------
-- open / close
---------------------------------------------------------------------
function Workshop.isOpen(): boolean
	return open or closing
end

function Workshop.close()
	if not open then
		return
	end
	open = false
	if st and st.dyno then
		st.dyno = false
		Driving.muteEngine(false)
	end
	pcall(function()
		RunService:UnbindFromRenderStep("WorkshopCamera")
	end)
	for _, c in conns do
		c:Disconnect()
	end
	table.clear(conns)
	if gui then
		gui:Destroy()
		gui = nil
	end
	if car then
		car:Destroy()
		car = nil
	end
	if room then
		room:Destroy()
		room = nil
	end
	if grade then
		grade:Destroy()
		grade = nil
	end
	for g, _ in hiddenGuis do
		if g.Parent then
			g.Enabled = true
		end
	end
	table.clear(hiddenGuis)
	for fx, was in savedBlur do
		if fx.Parent then
			(fx :: any).Enabled = was
		end
	end
	table.clear(savedBlur)
	Driving.workshopOpen = false
	if savedHold then
		Driving.cameraHold = savedHold[1]
		Driving.menuHold = savedHold[2]
		savedHold = nil
	end
	local character = player.Character
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	if hum and savedWalk then
		hum.WalkSpeed = savedWalk[1]
		hum.JumpPower = savedWalk[2]
	end
	savedWalk = nil
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
	end)
	camera.CameraType = savedCamType
	camera.FieldOfView = savedFov
	-- (a beat later: Backspace shuts this, and the same press would go on to put the car back on the road)
	closing = true
	task.delay(0.1, function()
		closing = false
		if not open then
			UI.modalOpen = modalBefore
		end
	end)
end

function Workshop.open(carId: string)
	if open then
		Workshop.close()
	end
	if not Cars.ById[carId] then
		return
	end
	open = true
	if not closing then
		modalBefore = UI.modalOpen == true
	end
	UI.modalOpen = true
	local firstCat = "engine"
	st = {
		carId = carId,
		spec = Cars.get(carId),
		tab = "UPGRADE",
		cat = firstCat,
		slot = catOf(firstCat).slots[1],
		preview = nil,
		shopTab = firstCat,
		shopRarity = nil,
		shopGroup = "All",
		shopSearch = "",
		shopPick = nil,
		busy = false,
		dyno = false,
	}
	for _, g in player.PlayerGui:GetChildren() do
		if g:IsA("ScreenGui") and g.Enabled and g.Name ~= "Workshop" then
			hiddenGuis[g] = true
			g.Enabled = false
		end
	end
	for _, fx in Lighting:GetChildren() do
		if fx:IsA("BlurEffect") or fx:IsA("DepthOfFieldEffect") then
			savedBlur[fx] = fx.Enabled
			fx.Enabled = false
		end
	end
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
	end)
	local character = player.Character
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	if hum then
		savedWalk = { hum.WalkSpeed, hum.JumpPower }
		hum.WalkSpeed = 0
		hum.JumpPower = 0
	end
	savedHold = { Driving.cameraHold, Driving.menuHold }
	Driving.cameraHold = true
	Driving.menuHold = true
	Driving.workshopOpen = true
	savedFov = camera.FieldOfView
	savedCamType = camera.CameraType
	room = buildRoom()
	showCar(carId)
	-- (the room is lit by its own lamps: the sky's light would wash it out)
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "WorkshopGrade"
	cc.Brightness = -0.05
	cc.Contrast = 0.12
	cc.Parent = Lighting
	grade = cc

	buildGui()
	yaw, pitch = 2.5, 0.2
	wantYaw, wantPitch = yaw, pitch
	dist = carL * 1.05 + 5
	wantDist = dist
	look = STAGE + Vector3.new(0, carH / 2 + 0.3 + LIFT + 0.4, 0)
	wantLook = look
	posed = false
	idle = 0
	shiftX, wantShift = 1, 1
	shiftY, wantShiftY = 0.24, 0.24
	ui.cash = UI.getCash()
	setTab("UPGRADE")
	setCat(firstCat, false)
	refreshPins()
	task.spawn(function()
		CarUpgrades.refresh()
		if open and st and st.carId == carId then
			refreshAll()
		end
	end)

	-- (bound last in the frame, so a driving or on-foot camera can't take the shot back)
	pcall(function()
		RunService:UnbindFromRenderStep("WorkshopCamera")
	end)
	RunService:BindToRenderStep("WorkshopCamera", Enum.RenderPriority.Last.Value, function(dt)
		idle += dt
		if not posed and idle > 1.5 and not st.dyno then
			yaw += dt * 0.12 -- slowly round
			wantYaw = yaw
		end
		local k = math.min(1, dt * 3.5)
		yaw += (wantYaw - yaw) * k
		pitch += (wantPitch - pitch) * k
		dist += (wantDist - dist) * k
		look = look:Lerp(wantLook, k)
		shiftX += (wantShift - shiftX) * k
		shiftY += (wantShiftY - shiftY) * k
		local offset = Vector3.new(math.sin(yaw) * math.cos(pitch), math.sin(pitch), math.cos(yaw) * math.cos(pitch)) * dist
		local scaleNow = ui.scale and ui.scale.Scale or 1
		local v = camera.ViewportSize
		-- the car stands in the gap between the panels: left of the middle and a little high
		local halfH = math.tan(math.rad(FOV / 2)) * dist
		local halfW = halfH * v.X / v.Y
		local sx = halfW * 0.2 * shiftX
		local sy = -halfH * shiftY
		camera.CameraType = Enum.CameraType.Scriptable
		camera.FieldOfView = FOV
		camera.CFrame = CFrame.lookAt(look + offset, look) * CFrame.new(sx, sy, 0)
		camera.Focus = CFrame.new(look)
		-- (a lift post between the camera and the car fades)
		local camSide = math.sin(yaw)
		for _, post in liftPosts do
			post.LocalTransparencyModifier = if (post.Position.X - STAGE.X) * camSide > 0 and math.abs(camSide) > 0.2 then 0.9 else 0
		end
		if st.tab == "UPGRADE" and not st.dyno and ui.root then
			local rootPos = ui.root.AbsolutePosition
			for key, pin in ui.pins do
				local p, on = camera:WorldToViewportPoint(pinPos(key))
				pin.button.Visible = on
				pin.button.Position = UDim2.fromOffset((p.X - rootPos.X) / scaleNow - 9, (p.Y - rootPos.Y) / scaleNow)
			end
		end
	end)
end

function Workshop.init()
	CarUpgrades.screen = { open = Workshop.open, close = Workshop.close, isOpen = Workshop.isOpen }
	-- Studio test hooks (MCP clicks don't reach the game): player attribute TestWorkshop = a car id
	-- opens it, "" shuts it; TestWorkshopDo = "tab:SHOP", "cat:exhaust", "slot:muffler", "pick:mf_straight",
	-- "shop:swap", "group:BMW", "shopPick:sw_2jz", "dyno", "dynoDone", "buy:id", "fit:id", "off:slot"
	if RunService:IsStudio() then
		player:GetAttributeChangedSignal("TestWorkshop"):Connect(function()
			local id = player:GetAttribute("TestWorkshop")
			if type(id) == "string" and id ~= "" then
				Workshop.open(id)
			else
				Workshop.close()
			end
		end)
		player:GetAttributeChangedSignal("TestWorkshopDo"):Connect(function()
			local cmd = player:GetAttribute("TestWorkshopDo")
			if type(cmd) ~= "string" or not open then
				return
			end
			local what, arg = string.match(cmd, "^(%a+):?(.*)$")
			if what == "tab" then
				setTab(arg)
			elseif what == "cat" then
				setCat(arg)
			elseif what == "slot" then
				st.slot = arg
				st.preview = nil
				refreshDrawer()
				refreshStats()
			elseif what == "pick" then
				st.preview = arg
				refreshDrawer()
				refreshStats()
			elseif what == "shop" then
				st.shopTab = arg
				st.shopPick = nil
				refreshShop()
			elseif what == "group" then
				st.shopGroup = arg
				refreshShop()
			elseif what == "shopPick" then
				st.shopPick = arg
				refreshShop()
			elseif what == "dyno" then
				dynoRun()
			elseif what == "dynoDone" then
				dynoDone()
			elseif what == "buy" then
				buy(arg, "cash", true)
			elseif what == "fit" then
				install(arg)
			elseif what == "off" then
				uninstall(arg)
			end
		end)
	end
end

return Workshop
