--[[
	DealerMenu (client) (owner, 2026-10-31: "make the UI look a lot better", like Midnight Racing's
	dealership menu). E at the Legends Motors counter (or a display car's stand) opens it:
	  * the camera goes to a showroom stage built on this screen only, high above the city: a round
	    room, a turntable, spotlights. The picked car stands there (drag to turn round it, scroll or
	    pinch to come closer). The dealership building itself isn't touched.
	  * top bar: EXIT, the brand, the car's name and COST, BUY (or DRIVE when owned; greyed with the
	    reason when locked)
	  * left, "Vehicles" in two levels: the brand's models (from $, N trims), then a model's trims,
	    worst to best (price, level lock or OWNED); a Back row goes back
	  * over the car: the trim selector  <  NAME  >
	  * right: max speed, power-to-weight, braking, weight (bars against the best car), drive; then
	    the trim card: power, torque, weight, seats, paint swatches, trim chips, a line about the
	    car, feature icons (ABS, drive, fuel, gearbox, MPG, sound)
	  * bottom: the brand bar with < >; bottom left: your level, XP and the next unlock
	  * BUY asks first; the server checks money, level and ownership and charges once; then NEW CAR
	    with confetti and DRIVE IT NOW. TEST DRIVE is there for cars you don't own.
	Numbers for show come from CarStats.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Cars = require(Shared:WaitForChild("Cars"))
local CarStats = require(Shared:WaitForChild("CarStats"))
local CarBuilder = require(Shared:WaitForChild("CarBuilder"))

local UI = require(script.Parent:WaitForChild("UI"))
local CarSkin = require(script.Parent:WaitForChild("CarSkin"))
local Audio = require(script.Parent:WaitForChild("Audio"))
local CustomsClient = require(script.Parent:WaitForChild("CustomsClient"))

local DealerMenu = {}

export type Result = { ok: boolean, message: string?, data: any? }
export type Callbacks = {
	buy: (string, number?) -> Result,
	drive: (string) -> (),
	testDrive: ((string) -> Result)?,
	close: (() -> ())?,
}

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local Theme = Config.Theme
local kit = UI.kit
local new, label, corner, stroke = kit.new, kit.label, kit.corner, kit.stroke

-- our look: near-black glass panels, a warm red accent like a showroom light, white type
local PANEL = Color3.fromRGB(14, 15, 19)
local PANEL2 = Color3.fromRGB(26, 27, 33)
local LINE = Color3.fromRGB(58, 60, 70)
local RED = Color3.fromRGB(226, 52, 58)
local GOLD = Color3.fromRGB(255, 196, 92)
local WHITE = Color3.fromRGB(244, 244, 246)
local GREY = Color3.fromRGB(150, 152, 162)
local GREEN = Color3.fromRGB(110, 224, 150)

local STAGE = Vector3.new(0, 3000, 0) -- the showroom stage, high above the city (this screen only)
local PALETTE = Config.Customs.Palette

local open = false
local gui: ScreenGui? = nil
local stage: Folder? = nil
local conns: { RBXScriptConnection } = {}
local hiddenGuis: { [ScreenGui]: boolean } = {}
local savedWalk: { number }? = nil

---------------------------------------------------------------------
-- helpers
---------------------------------------------------------------------
local function money(n: number): string
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return "$" .. out:gsub("^,", "")
end

local function panel(props: { [string]: any }): Frame
	local f = new("Frame", props, { corner(10), stroke(LINE, 1, 0.35) })
	f.BackgroundColor3 = props.BackgroundColor3 or PANEL
	f.BackgroundTransparency = if props.BackgroundTransparency ~= nil then props.BackgroundTransparency else 0.12
	return f
end

local function flatButton(text: string, props: { [string]: any }): TextButton
	local base = {
		AutoButtonColor = false,
		BackgroundColor3 = PANEL2,
		BackgroundTransparency = 0.05,
		Font = Enum.Font.GothamBlack,
		Text = text,
		TextColor3 = WHITE,
		TextSize = 20,
	}
	for k, v in props do
		base[k] = v
	end
	local b: TextButton = new("TextButton", base, { corner(8), stroke(LINE, 1, 0.2) })
	b.Activated:Connect(Audio.click)
	return b
end

local function seriesOf(id: string): Cars.Series?
	local at = Cars.SeriesOf[id]
	return if at then at.series else nil
end

local function modelName(series: Cars.Series): string
	local name = series.Name
	local brand = series.Brand or ""
	if string.sub(name, 1, #brand + 1) == brand .. " " then
		name = string.sub(name, #brand + 2)
	end
	return name
end

-- brands in roster order
local function brandList(): { string }
	local out, seen = {}, {}
	for _, s in Cars.Series do
		local b = s.Brand or s.Name
		if not seen[b] then
			seen[b] = true
			table.insert(out, b)
		end
	end
	return out
end

---------------------------------------------------------------------
-- the showroom stage (built once, kept while the menu is open)
---------------------------------------------------------------------
local function part(parent: Instance, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material, opts: { [string]: any }?): Part
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
	p.Material = material
	if opts then
		for k, v in opts do
			(p :: any)[k] = v
		end
	end
	p.Parent = parent
	return p
end

local function buildStage(): Folder
	local f = Instance.new("Folder")
	f.Name = "DealerStage"
	local c = CFrame.new(STAGE)
	-- polished white floor, a dark turntable with a brushed rim
	part(f, Vector3.new(150, 1, 150), c * CFrame.new(0, -0.5, 0), Color3.fromRGB(232, 232, 230), Enum.Material.Marble, { Reflectance = 0.16 })
	part(f, Vector3.new(0.6, 34, 34), c * CFrame.new(0, 0.3, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(30, 30, 34), Enum.Material.Granite, { Shape = Enum.PartType.Cylinder, Reflectance = 0.12 })
	part(f, Vector3.new(0.4, 35, 35), c * CFrame.new(0, 0.2, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(170, 172, 176), Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
	-- a round room: dark panels, warm-lit slots between them, a red band low down (our showroom red)
	local R, H, N = 62, 40, 28
	for k = 0, N - 1 do
		local a = k / N * math.pi * 2
		local w = 2 * math.pi * R / N + 0.4
		local cf = c * CFrame.Angles(0, a, 0) * CFrame.new(0, H / 2, -R)
		part(f, Vector3.new(w, H, 1), cf, Color3.fromRGB(36, 36, 42), Enum.Material.SmoothPlastic)
		part(f, Vector3.new(w, 4, 0.4), c * CFrame.Angles(0, a, 0) * CFrame.new(0, 3, -R + 0.7), Color3.fromRGB(150, 28, 34), Enum.Material.SmoothPlastic)
		if k % 2 == 0 then
			local slot = part(f, Vector3.new(1.2, H - 10, 0.3), c * CFrame.Angles(0, a + math.pi / N, 0) * CFrame.new(0, H / 2 + 2, -R + 0.8), Color3.fromRGB(255, 236, 206), Enum.Material.SmoothPlastic)
			local l = Instance.new("SurfaceLight")
			l.Face = Enum.NormalId.Back
			l.Color = Color3.fromRGB(255, 220, 180)
			l.Brightness = 0.6
			l.Range = 14
			l.Angle = 120
			l.Parent = slot
		end
	end
	-- the ceiling (also keeps the rain off: Weather sees a roof over the camera)
	part(f, Vector3.new(150, 1, 150), c * CFrame.new(0, H + 0.5, 0), Color3.fromRGB(24, 24, 28), Enum.Material.SmoothPlastic)
	for _, p in { { -18, -18 }, { 18, -18 }, { -18, 18 }, { 18, 18 } } do
		local panelPart = part(f, Vector3.new(14, 0.3, 14), c * CFrame.new(p[1], H - 0.2, p[2]), Color3.fromRGB(250, 246, 238), Enum.Material.SmoothPlastic)
		local l = Instance.new("SurfaceLight")
		l.Face = Enum.NormalId.Bottom
		l.Color = Color3.fromRGB(255, 240, 222)
		l.Brightness = 1.4
		l.Range = 48
		l.Angle = 110
		l.Parent = panelPart
	end
	-- four spotlights on the car
	for k = 0, 3 do
		local a = k * math.pi / 2 + math.pi / 4
		local p = (c * CFrame.new(math.cos(a) * 20, 24, math.sin(a) * 20)).Position
		local lamp = part(f, Vector3.new(1.4, 1.4, 2.2), CFrame.lookAt(p, STAGE + Vector3.new(0, 2, 0)), Color3.fromRGB(20, 20, 24), Enum.Material.Metal)
		local s = Instance.new("SpotLight")
		s.Face = Enum.NormalId.Front
		s.Color = Color3.fromRGB(255, 240, 220)
		s.Brightness = 3
		s.Range = 45
		s.Angle = 40
		s.Parent = lamp
	end
	f.Parent = workspace
	return f
end

---------------------------------------------------------------------
-- state shared by the screen
---------------------------------------------------------------------
type State = {
	data: any,
	callbacks: Callbacks,
	owned: { [string]: boolean },
	brands: { string },
	brand: string,
	series: Cars.Series?, -- the open model (level 2 of the list), nil = the model list
	id: string, -- the selected trim
	colour: number?, -- a Palette index, or nil for the car's own colour
	busy: boolean,
}
local st: State? = nil
local car: Model? = nil
local carLen = 14
local yaw, pitch, dist = -0.6, 0.18, 30
local zoomK = 1
local refreshAll: () -> () = function() end

local function levelNow(): number
	local lvl = UI.getProgress()
	return lvl
end

local function needFor(id: string): number
	return Cars.requiredLevel(id)
end

---------------------------------------------------------------------
-- the car on the stage
---------------------------------------------------------------------
local function lookFor(id: string, colour: number?): { [string]: any }
	local s = PALETTE[colour or 0]
	if s then
		return { paint = { s[2], s[3], s[4] } }
	end
	local spec = Cars.get(id)
	return { paint = { math.floor(spec.Color.R * 255), math.floor(spec.Color.G * 255), math.floor(spec.Color.B * 255) } }
end

local function showCar(id: string, colour: number?)
	if car then
		car:Destroy()
		car = nil
	end
	local spec = Cars.get(id)
	local ok, m = pcall(CarBuilder.build, spec, { anchored = true, interior = false })
	if not ok or not m then
		return
	end
	pcall(CarSkin.apply, m, true)
	local h = (m:GetAttribute("Height") :: number?) or 4
	carLen = (m:GetAttribute("Length") :: number?) or 14
	m:PivotTo(CFrame.new(STAGE + Vector3.new(0, 0.6 + h / 2, 0)) * CFrame.Angles(0, math.rad(20), 0))
	m.Parent = stage
	pcall(CustomsClient.paintCar, m, lookFor(id, colour))
	car = m
	dist = carLen * 1.45 + 6
end

---------------------------------------------------------------------
-- thumbnails: a small 3D shot of a car (light bodies, made a few a frame)
---------------------------------------------------------------------
local thumbQueue: { { vp: ViewportFrame, id: string } } = {}
local thumbRunning = false
local function thumb(parent: Instance, id: string, size: Vector2): ViewportFrame
	local vp: ViewportFrame = new("ViewportFrame", {
		BackgroundColor3 = Color3.fromRGB(40, 41, 48),
		Size = UDim2.fromOffset(size.X, size.Y),
		Ambient = Color3.fromRGB(170, 170, 180),
		LightColor = Color3.fromRGB(255, 250, 240),
		LightDirection = Vector3.new(-0.5, -1, -0.4),
		Parent = parent,
	}, { corner(6) })
	table.insert(thumbQueue, { vp = vp, id = id })
	if not thumbRunning then
		thumbRunning = true
		task.spawn(function()
			while #thumbQueue > 0 do
				local job = table.remove(thumbQueue, 1) :: { vp: ViewportFrame, id: string }
				if job.vp.Parent then
					local ok, m = pcall(CarBuilder.build, Cars.get(job.id), { anchored = true, interior = false, lite = true })
					if ok and m then
						pcall(CarSkin.apply, m, true, true)
						local h = (m:GetAttribute("Height") :: number?) or 4
						local len = (m:GetAttribute("Length") :: number?) or 14
						m:PivotTo(CFrame.new(0, h / 2, 0))
						m.Parent = job.vp
						local cam = Instance.new("Camera")
						cam.FieldOfView = 30
						cam.CFrame = CFrame.lookAt(Vector3.new(len * 1.15, len * 0.45, len * 1.25), Vector3.new(0, h * 0.35, 0))
						cam.Parent = job.vp
						job.vp.CurrentCamera = cam
					end
				end
				task.wait()
			end
			thumbRunning = false
		end)
	end
	return vp
end

---------------------------------------------------------------------
-- the screen
---------------------------------------------------------------------
local function confetti(parent: Instance)
	local cols = { RED, GOLD, WHITE, Color3.fromRGB(90, 170, 255), GREEN }
	for i = 1, 70 do
		local f = new("Frame", {
			BackgroundColor3 = cols[i % #cols + 1],
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(math.random(6, 11), math.random(10, 16)),
			Position = UDim2.new(math.random(), 0, -0.05, -math.random(0, 200)),
			Rotation = math.random(0, 360),
			ZIndex = 120,
			Parent = parent,
		})
		kit.tween(f, math.random(18, 32) / 10, { Position = UDim2.new(f.Position.X.Scale + (math.random() - 0.5) * 0.2, 0, 1.1, 0), Rotation = f.Rotation + math.random(-400, 400) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		task.delay(3.4, function()
			f:Destroy()
		end)
	end
end

local function build(root: Frame)
	local s = st :: State

	-----------------------------------------------------------------
	-- top bar: EXIT · brand · name / COST · BUY
	-----------------------------------------------------------------
	local top = panel({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 12), Size = UDim2.new(1, -40, 0, 70), BackgroundTransparency = 0.18, Parent = root })
	new("UISizeConstraint", { MaxSize = Vector2.new(1180, 70), Parent = top })
	local exitBtn = flatButton("EXIT", { Position = UDim2.fromOffset(14, 12), Size = UDim2.fromOffset(140, 46), Parent = top })
	local buyBtn = flatButton("BUY", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 12), Size = UDim2.fromOffset(170, 46), BackgroundColor3 = RED, Parent = top })
	local testBtn = flatButton("TEST DRIVE", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -194, 0, 12), Size = UDim2.fromOffset(130, 46), TextSize = 14, TextColor3 = GOLD, Parent = top })
	local badge = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(0.5, -150, 0.5, 0), Size = UDim2.fromOffset(92, 46), BackgroundColor3 = Color3.fromRGB(8, 8, 10), Parent = top }, { corner(8), stroke(GOLD, 1.5, 0.15) })
	local badgeText = label({ Text = "", TextColor3 = GOLD, Font = Enum.Font.GothamBlack, TextScaled = true, Size = UDim2.new(1, -10, 1, -12), Position = UDim2.fromOffset(5, 6), Parent = badge })
	local nameText = label({ Text = "", TextSize = 22, Font = Enum.Font.GothamBlack, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 30, 0, 10), Size = UDim2.fromOffset(380, 28), Parent = top })
	local costText = label({ Text = "", TextSize = 15, TextColor3 = GREY, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 30, 0, 40), Size = UDim2.fromOffset(380, 20), Parent = top })

	-----------------------------------------------------------------
	-- the trim selector over the car
	-----------------------------------------------------------------
	local trimBar = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 104), Size = UDim2.fromOffset(460, 44), BackgroundColor3 = PANEL, BackgroundTransparency = 0.35, Parent = root }, { corner(8) })
	label({ Text = "Trim", TextSize = 13, TextColor3 = GREY, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromOffset(4, -2), Size = UDim2.fromOffset(60, 16), TextXAlignment = Enum.TextXAlignment.Left, Parent = trimBar })
	local prevTrim = flatButton("<", { Size = UDim2.fromOffset(52, 44), BackgroundTransparency = 1, TextSize = 26, Parent = trimBar })
	local nextTrim = flatButton(">", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(52, 44), BackgroundTransparency = 1, TextSize = 26, Parent = trimBar })
	local trimText = label({ Text = "", TextSize = 22, Font = Enum.Font.GothamBlack, Position = UDim2.fromOffset(56, 0), Size = UDim2.new(1, -112, 1, 0), Parent = trimBar })
	local trimNote = label({ Text = "", TextSize = 13, TextColor3 = GREEN, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 4), Size = UDim2.fromOffset(300, 16), Parent = trimBar })

	-----------------------------------------------------------------
	-- left: Vehicles (models, then a model's trims)
	-----------------------------------------------------------------
	local left = panel({ Position = UDim2.fromOffset(20, 104), Size = UDim2.new(0, 290, 1, -104 - 112), Parent = root })
	local head = new("Frame", { Size = UDim2.new(1, 0, 0, 44), BackgroundColor3 = Color3.fromRGB(6, 6, 8), BackgroundTransparency = 0.1, Parent = left }, { corner(10) })
	local headText = label({ Text = "Vehicles", TextSize = 20, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(14, 0), Size = UDim2.new(1, -28, 1, 0), Parent = head })
	local upBtn = flatButton("︿", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 48), Size = UDim2.new(1, -24, 0, 26), BackgroundTransparency = 1, TextSize = 22, Parent = left })
	local downBtn = flatButton("﹀", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -4), Size = UDim2.new(1, -24, 0, 26), BackgroundTransparency = 1, TextSize = 22, Parent = left })
	local list: ScrollingFrame = new("ScrollingFrame", {
		Position = UDim2.fromOffset(8, 76),
		Size = UDim2.new(1, -16, 1, -76 - 32),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = LINE,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = left,
	}, { new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })
	upBtn.Activated:Connect(function()
		list.CanvasPosition = Vector2.new(0, math.max(0, list.CanvasPosition.Y - 200))
	end)
	downBtn.Activated:Connect(function()
		list.CanvasPosition = Vector2.new(0, list.CanvasPosition.Y + 200)
	end)

	-----------------------------------------------------------------
	-- right: stats bars and the trim card
	-----------------------------------------------------------------
	local right = panel({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0, 104), Size = UDim2.new(0, 320, 1, -104 - 112), BackgroundTransparency = 0.2, Parent = root })
	local rscroll: ScrollingFrame = new("ScrollingFrame", {
		Position = UDim2.fromOffset(14, 10),
		Size = UDim2.new(1, -24, 1, -20),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = LINE,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = right,
	}, { new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }) })
	local order = 0
	local function nextOrder(): number
		order += 1
		return order
	end
	local function bar(name: string): (TextLabel, Frame)
		local row = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -6, 0, 30), LayoutOrder = nextOrder(), Parent = rscroll })
		label({ Text = name, TextSize = 13, TextColor3 = GREY, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(0.55, 0, 0, 16), Parent = row })
		local val = label({ Text = "", TextSize = 13, TextColor3 = GREY, TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.fromScale(0.45, 0), Size = UDim2.new(0.55, 0, 0, 16), Parent = row })
		local back = new("Frame", { Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 0, 7), BackgroundColor3 = Color3.fromRGB(70, 70, 78), BorderSizePixel = 0, Parent = row }, { corner(2) })
		local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = RED, BorderSizePixel = 0, Parent = back }, { corner(2) })
		return val, fill
	end
	local speedVal, speedFill = bar("Max Speed")
	local ptwVal, ptwFill = bar("Power to weight")
	local brakeVal, brakeFill = bar("Braking")
	local weightVal, weightFill = bar("Weight")
	local driveRow = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -6, 0, 22), LayoutOrder = nextOrder(), Parent = rscroll })
	label({ Text = "Drive", TextSize = 15, TextColor3 = GREY, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(0.5, 0, 1, 0), Parent = driveRow })
	local driveVal = label({ Text = "", TextSize = 16, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.fromScale(0.5, 0), Size = UDim2.new(0.5, 0, 1, 0), Parent = driveRow })
	-- the trim card
	new("Frame", { BackgroundColor3 = LINE, BorderSizePixel = 0, Size = UDim2.new(1, -6, 0, 1), LayoutOrder = nextOrder(), Parent = rscroll })
	local facts = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -6, 0, 50), LayoutOrder = nextOrder(), Parent = rscroll }, {
		new("UIGridLayout", { CellSize = UDim2.new(0.25, -6, 0, 50), CellPadding = UDim2.fromOffset(6, 0) }),
	})
	local function fact(name: string): TextLabel
		local cell = new("Frame", { BackgroundColor3 = PANEL2, BackgroundTransparency = 0.1, Parent = facts }, { corner(6) })
		label({ Text = name, TextSize = 11, TextColor3 = GREY, Position = UDim2.fromOffset(0, 5), Size = UDim2.new(1, 0, 0, 14), Parent = cell })
		return label({ Text = "", TextSize = 14, Font = Enum.Font.GothamBlack, Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 0, 20), Parent = cell })
	end
	local powerVal = fact("Power")
	local torqueVal = fact("Torque")
	local wVal = fact("Weight")
	local seatsVal = fact("Seats")
	label({ Text = "Vehicle colour", TextSize = 13, TextColor3 = GREY, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -6, 0, 16), LayoutOrder = nextOrder(), Parent = rscroll })
	local swatches = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -6, 0, 66), LayoutOrder = nextOrder(), Parent = rscroll }, {
		new("UIGridLayout", { CellSize = UDim2.fromOffset(30, 30), CellPadding = UDim2.fromOffset(6, 6) }),
	})
	local swatchStrokes: { [number]: UIStroke } = {}
	local stockSwatch: TextButton = new("TextButton", { Text = "", AutoButtonColor = false, LayoutOrder = 0, Parent = swatches }, { corner(15) })
	swatchStrokes[0] = new("UIStroke", { Thickness = 2, Color = WHITE, Parent = stockSwatch })
	label({ Text = "★", TextSize = 13, TextColor3 = Color3.new(0, 0, 0), Size = UDim2.fromScale(1, 1), Parent = stockSwatch })
	for i, sw in PALETTE do
		local b: TextButton = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.fromRGB(sw[2], sw[3], sw[4]), LayoutOrder = i, Parent = swatches }, { corner(15) })
		swatchStrokes[i] = new("UIStroke", { Thickness = 2, Color = WHITE, Transparency = 1, Parent = b })
		b.Activated:Connect(function()
			s.colour = i
			Audio.click()
			refreshAll()
			if car then
				pcall(CustomsClient.paintCar, car, lookFor(s.id, i))
			end
		end)
	end
	stockSwatch.Activated:Connect(function()
		s.colour = nil
		refreshAll()
		if car then
			pcall(CustomsClient.paintCar, car, lookFor(s.id, nil))
		end
	end)
	local colourName = label({ Text = "", TextSize = 12, TextColor3 = GREY, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -6, 0, 14), LayoutOrder = nextOrder(), Parent = rscroll })
	label({ Text = "Trims", TextSize = 13, TextColor3 = GREY, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -6, 0, 16), LayoutOrder = nextOrder(), Parent = rscroll })
	local chips = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = nextOrder(), Parent = rscroll }, {
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Wraps = true, Padding = UDim.new(0, 6) }),
	})
	local descText = label({ Text = "", TextSize = 14, TextWrapped = true, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, -6, 0, 36), LayoutOrder = nextOrder(), Parent = rscroll })
	local icons = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -6, 0, 52), LayoutOrder = nextOrder(), Parent = rscroll }, {
		new("UIGridLayout", { CellSize = UDim2.new(1 / 6, -5, 0, 52), CellPadding = UDim2.fromOffset(5, 0) }),
	})
	local function featureIcon(sym: string, name: string): (TextLabel, TextLabel)
		local cell = new("Frame", { BackgroundColor3 = PANEL2, BackgroundTransparency = 0.1, Parent = icons }, { corner(6) })
		local top2 = label({ Text = sym, TextSize = 15, Font = Enum.Font.GothamBlack, Position = UDim2.fromOffset(0, 6), Size = UDim2.new(1, 0, 0, 20), Parent = cell })
		local sub = label({ Text = name, TextSize = 10, TextColor3 = GREY, Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 0, 14), Parent = cell })
		return top2, sub
	end
	local absTop = featureIcon("ABS", "brakes")
	local driveTop = featureIcon("", "drive")
	local fuelTop, fuelSub = featureIcon("⛽", "")
	local boxTop = featureIcon("", "gearbox")
	local mpgTop = featureIcon("", "MPG")
	local soundBtn: TextButton = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = PANEL2, BackgroundTransparency = 0.1, Parent = icons }, { corner(6) })
	label({ Text = "🔊", TextSize = 15, Position = UDim2.fromOffset(0, 6), Size = UDim2.new(1, 0, 0, 20), Parent = soundBtn })
	label({ Text = "sound", TextSize = 10, TextColor3 = GREY, Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 0, 14), Parent = soundBtn })
	soundBtn.Activated:Connect(function()
		Audio.engineStart()
	end)

	-----------------------------------------------------------------
	-- bottom: brand bar; bottom left: your level
	-----------------------------------------------------------------
	local brandBar = new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 70, 1, -14), Size = UDim2.new(1, -330, 0, 80), BackgroundColor3 = PANEL, BackgroundTransparency = 0.25, Parent = root }, { corner(10) })
	new("UISizeConstraint", { MaxSize = Vector2.new(900, 80), Parent = brandBar })
	local bPrev = flatButton("<", { Position = UDim2.fromOffset(6, 12), Size = UDim2.fromOffset(44, 56), BackgroundTransparency = 1, TextSize = 30, Parent = brandBar })
	local bNext = flatButton(">", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 12), Size = UDim2.fromOffset(44, 56), BackgroundTransparency = 1, TextSize = 30, Parent = brandBar })
	local tiles: ScrollingFrame = new("ScrollingFrame", {
		Position = UDim2.fromOffset(56, 6),
		Size = UDim2.new(1, -112, 1, -12),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.X,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		CanvasSize = UDim2.new(),
		Parent = brandBar,
	}, { new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Center }) })
	local tileByBrand: { [string]: TextButton } = {}
	for i, b in s.brands do
		local t: TextButton = new("TextButton", { Text = "", AutoButtonColor = false, LayoutOrder = i, BackgroundColor3 = Color3.fromRGB(34, 35, 42), Size = UDim2.fromOffset(128, 60), Parent = tiles }, { corner(8), stroke(LINE, 1, 0.3) })
		label({ Text = b, TextScaled = true, Font = Enum.Font.GothamBlack, TextColor3 = WHITE, Position = UDim2.fromOffset(8, 12), Size = UDim2.new(1, -16, 1, -24), Parent = t })
		t.Activated:Connect(function()
			Audio.click()
			s.brand = b
			s.series = nil
			local first = nil
			for _, ser in Cars.Series do
				if ser.Brand == b then
					first = ser.Ids[1]
					break
				end
			end
			if first then
				s.id = first
				s.colour = nil
				showCar(first, nil)
			end
			refreshAll()
		end)
		tileByBrand[b] = t
	end
	local function stepBrand(d: number)
		local idx = table.find(s.brands, s.brand) or 1
		local nb = s.brands[(idx - 1 + d) % #s.brands + 1]
		local t = tileByBrand[nb]
		if t then
			s.brand = nb
			s.series = nil
			for _, ser in Cars.Series do
				if ser.Brand == nb then
					s.id = ser.Ids[1]
					break
				end
			end
			s.colour = nil
			showCar(s.id, nil)
			refreshAll()
		end
	end
	bPrev.Activated:Connect(function()
		stepBrand(-1)
	end)
	bNext.Activated:Connect(function()
		stepBrand(1)
	end)

	local lvlBox = panel({ AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 20, 1, -14), Size = UDim2.fromOffset(270, 80), BackgroundTransparency = 0.2, Parent = root })
	local lvlCircle = new("Frame", { Position = UDim2.fromOffset(12, 14), Size = UDim2.fromOffset(52, 52), BackgroundColor3 = RED, Parent = lvlBox }, { corner(26) })
	local lvlNum = label({ Text = "", TextSize = 22, Font = Enum.Font.GothamBlack, Size = UDim2.fromScale(1, 1), Parent = lvlCircle })
	label({ Text = "Your Level", TextSize = 13, TextColor3 = GREY, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(76, 12), Size = UDim2.fromOffset(180, 16), Parent = lvlBox })
	local xpBack = new("Frame", { Position = UDim2.fromOffset(76, 32), Size = UDim2.fromOffset(180, 7), BackgroundColor3 = Color3.fromRGB(70, 70, 78), BorderSizePixel = 0, Parent = lvlBox }, { corner(3) })
	local xpFill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = GOLD, BorderSizePixel = 0, Parent = xpBack }, { corner(3) })
	local nextText = label({ Text = "", TextSize = 12, TextColor3 = GREY, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(76, 46), Size = UDim2.fromOffset(186, 28), TextWrapped = true, Parent = lvlBox })

	local msg = label({ Text = "", TextSize = 16, TextColor3 = GOLD, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -104), Size = UDim2.fromOffset(500, 22), Parent = root })

	-----------------------------------------------------------------
	-- the list rows
	-----------------------------------------------------------------
	local function clearList()
		for _, c in list:GetChildren() do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
	end
	local function rowBase(lo: number, h: number): TextButton
		return new("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = PANEL2, BackgroundTransparency = 0.15, Size = UDim2.new(1, -6, 0, h), LayoutOrder = lo, Parent = list }, { corner(8) })
	end
	local function fillList()
		clearList()
		local lv = levelNow()
		if s.series then
			local ser = s.series :: Cars.Series
			headText.Text = modelName(ser)
			local back = rowBase(0, 34)
			label({ Text = "‹  Back to " .. s.brand, TextSize = 14, TextColor3 = GREY, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -24, 1, 0), Parent = back })
			back.Activated:Connect(function()
				Audio.click()
				s.series = nil
				refreshAll()
			end)
			for i, id in ser.Ids do
				local spec = Cars.get(id)
				local row = rowBase(i, 78)
				if id == s.id then
					stroke(RED, 2, 0).Parent = row
				end
				thumb(row, id, Vector2.new(96, 62)).Position = UDim2.fromOffset(8, 8)
				label({ Text = Cars.trimLabel(id), TextSize = 15, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(114, 8), Size = UDim2.new(1, -122, 0, 20), Parent = row })
				label({ Text = money(spec.Price), TextSize = 14, TextColor3 = GREEN, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(114, 30), Size = UDim2.new(1, -122, 0, 18), Parent = row })
				local need = needFor(id)
				local tag = if s.owned[id] then "✔ OWNED" elseif lv < need then "🔒 Level " .. need else "Level " .. need
				label({ Text = tag, TextSize = 12, TextColor3 = if s.owned[id] then Color3.fromRGB(110, 190, 255) elseif lv < need then GOLD else GREY, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(114, 52), Size = UDim2.new(1, -122, 0, 16), Parent = row })
				row.Activated:Connect(function()
					Audio.click()
					if s.id ~= id then
						s.id = id
						showCar(id, s.colour)
						Audio.engineStart()
					end
					refreshAll()
				end)
			end
		else
			headText.Text = "Vehicles"
			local i = 0
			for _, ser in Cars.Series do
				if ser.Brand ~= s.brand then
					continue
				end
				i += 1
				local baseId = ser.Ids[1]
				local row = rowBase(i, 84)
				if seriesOf(s.id) == ser then
					stroke(RED, 2, 0).Parent = row
				end
				thumb(row, baseId, Vector2.new(96, 66)).Position = UDim2.fromOffset(8, 9)
				label({ Text = modelName(ser), TextSize = 15, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(114, 8), Size = UDim2.new(1, -122, 0, 20), Parent = row })
				label({ Text = "from " .. money(Cars.get(baseId).Price), TextSize = 13, TextColor3 = GREEN, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(114, 32), Size = UDim2.new(1, -122, 0, 16), Parent = row })
				label({ Text = "◉ " .. #ser.Ids .. " trim" .. (if #ser.Ids == 1 then "" else "s"), TextSize = 13, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(114, 54), Size = UDim2.new(1, -122, 0, 16), Parent = row })
				row.Activated:Connect(function()
					Audio.click()
					s.series = ser
					if seriesOf(s.id) ~= ser then
						s.id = baseId
						showCar(baseId, s.colour)
					end
					refreshAll()
				end)
			end
		end
		list.CanvasPosition = Vector2.zero
	end

	-----------------------------------------------------------------
	-- everything that follows the selection
	-----------------------------------------------------------------
	local lastListKey = ""
	refreshAll = function()
		local id = s.id
		local spec = Cars.get(id)
		local ser = seriesOf(id)
		local stats = CarStats.of(id)
		local best = CarStats.best()
		local lv = levelNow()
		local need = needFor(id)
		local owned = s.owned[id] == true
		-- top bar
		badgeText.Text = (ser and ser.Brand) or ""
		nameText.Text = spec.Name
		costText.Text = if owned then "OWNED" else "COST: " .. money(spec.Price)
		costText.TextColor3 = if owned then Color3.fromRGB(110, 190, 255) else GREY
		if owned then
			buyBtn.Text = "DRIVE"
			buyBtn.BackgroundColor3 = Color3.fromRGB(40, 110, 200)
			buyBtn.TextColor3 = WHITE
		elseif lv < need then
			buyBtn.Text = "LEVEL " .. need
			buyBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 66)
			buyBtn.TextColor3 = GREY
		else
			buyBtn.Text = "BUY"
			buyBtn.BackgroundColor3 = RED
			buyBtn.TextColor3 = WHITE
		end
		testBtn.Visible = s.callbacks.testDrive ~= nil and not owned
		-- trim selector
		trimText.Text = Cars.trimLabel(id)
		local count = if ser then #ser.Ids else 1
		local idx = if ser then (table.find(ser.Ids, id) or 1) else 1
		prevTrim.Visible = idx > 1
		nextTrim.Visible = idx < count
		trimNote.Text = if owned then "✔ Owned" elseif lv < need then "🔒 Reach level " .. need else count .. " trims · " .. idx .. " of " .. count
		trimNote.TextColor3 = if owned then Color3.fromRGB(110, 190, 255) elseif lv < need then GOLD else GREEN
		-- bars
		speedVal.Text = stats.kmh .. " KM/H · " .. stats.mph .. " MPH"
		speedFill.Size = UDim2.fromScale(stats.kmh / best.kmh, 1)
		ptwVal.Text = stats.ptw .. " HP/T"
		ptwFill.Size = UDim2.fromScale(stats.ptw / best.ptw, 1)
		brakeVal.Text = math.floor(stats.braking * 100) .. " / 100"
		brakeFill.Size = UDim2.fromScale(stats.braking, 1)
		weightVal.Text = stats.weightKg .. " KG"
		weightFill.Size = UDim2.fromScale(stats.weightKg / best.weightKg, 1)
		driveVal.Text = stats.drive
		-- card
		powerVal.Text = stats.hp .. " hp"
		torqueVal.Text = stats.torqueNm .. " Nm"
		wVal.Text = string.format("%.1f t", stats.weightKg / 1000)
		seatsVal.Text = tostring(stats.seats)
		for k, strokeInst in swatchStrokes do
			strokeInst.Transparency = if (s.colour or 0) == k then 0 else 1
		end
		stockSwatch.BackgroundColor3 = spec.Color
		colourName.Text = if s.colour and PALETTE[s.colour] then PALETTE[s.colour][1] else "Factory colour"
		for _, c in chips:GetChildren() do
			if c:IsA("GuiObject") then
				c:Destroy()
			end
		end
		if ser then
			for i, tid in ser.Ids do
				local chip: TextButton = new("TextButton", {
					Text = Cars.trimLabel(tid),
					AutoButtonColor = false,
					Font = Enum.Font.GothamBold,
					TextSize = 12,
					TextColor3 = if tid == id then Color3.new(0, 0, 0) else WHITE,
					BackgroundColor3 = if tid == id then WHITE else PANEL2,
					AutomaticSize = Enum.AutomaticSize.X,
					Size = UDim2.fromOffset(0, 26),
					LayoutOrder = i,
					Parent = chips,
				}, { corner(13), new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) }) })
				chip.Activated:Connect(function()
					if s.id ~= tid then
						s.id = tid
						showCar(tid, s.colour)
						Audio.engineStart()
						refreshAll()
					end
				end)
			end
		end
		descText.Text = stats.description
		absTop.Text = if stats.abs then "ABS" else "—"
		driveTop.Text = stats.drive
		fuelTop.Text = if spec.Electric then "⚡" else "⛽"
		fuelSub.Text = stats.fuel
		boxTop.Text = if stats.gearbox == "1" then "1-SPD" elseif stats.gearbox == "M/A" then "M / A" else "AUTO"
		mpgTop.Text = stats.mpg
		-- brand tiles
		for b, t in tileByBrand do
			local on = b == s.brand
			t.BackgroundColor3 = if on then Color3.fromRGB(70, 22, 26) else Color3.fromRGB(34, 35, 42)
			local st2 = t:FindFirstChildOfClass("UIStroke")
			if st2 then
				st2.Color = if on then RED else LINE
				st2.Transparency = if on then 0 else 0.3
			end
		end
		-- level box
		local plv, pxp, pneed = UI.getProgress()
		lvlNum.Text = tostring(plv)
		xpFill.Size = UDim2.fromScale(math.clamp(pxp / math.max(1, pneed), 0, 1), 1)
		local nextId, nextLv = nil, math.huge
		for _, sp in Cars.List do
			local n2 = needFor(sp.Id)
			if n2 > plv and n2 < nextLv and not s.owned[sp.Id] then
				nextId, nextLv = sp.Id, n2
			end
		end
		nextText.Text = if nextId then "Next: " .. Cars.get(nextId).Name .. " at level " .. nextLv else "Every car is open to you"
		-- the list (rebuilt only when what it shows changes)
		local key = s.brand .. "|" .. (if s.series then s.series.Name else "-") .. "|" .. id .. "|" .. tostring(plv)
		if key ~= lastListKey then
			lastListKey = key
			fillList()
		end
	end

	local function stepTrim(d: number)
		local ser = seriesOf(s.id)
		if not ser then
			return
		end
		local idx = (table.find(ser.Ids, s.id) or 1) + d
		local tid = ser.Ids[idx]
		if tid then
			s.id = tid
			if s.series ~= nil then
				s.series = ser
			end
			showCar(tid, s.colour)
			Audio.engineStart()
			refreshAll()
		end
	end
	prevTrim.Activated:Connect(function()
		stepTrim(-1)
	end)
	nextTrim.Activated:Connect(function()
		stepTrim(1)
	end)

	-----------------------------------------------------------------
	-- buying
	-----------------------------------------------------------------
	local function showMsg(text: string, color: Color3?)
		msg.Text = text
		msg.TextColor3 = color or GOLD
		task.delay(3, function()
			if msg.Text == text then
				msg.Text = ""
			end
		end)
	end

	local function celebrate(id: string)
		local over = new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.45, Size = UDim2.fromScale(1, 1), ZIndex = 100, Active = true, Parent = root })
		confetti(over)
		Audio.cutUp(8, "NEW CAR")
		local card = panel({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(440, 230), ZIndex = 101, BackgroundTransparency = 0.05, Parent = over })
		label({ Text = "NEW CAR", TextSize = 44, Font = Enum.Font.GothamBlack, TextColor3 = GOLD, Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 0, 50), ZIndex = 102, Parent = card })
		label({ Text = Cars.get(id).Name, TextSize = 20, Font = Enum.Font.GothamBold, Position = UDim2.fromOffset(0, 74), Size = UDim2.new(1, 0, 0, 26), ZIndex = 102, Parent = card })
		local driveNow = flatButton("DRIVE IT NOW", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 24, 1, -22), Size = UDim2.new(0.5, -30, 0, 52), BackgroundColor3 = RED, ZIndex = 102, Parent = card })
		local keep = flatButton("KEEP LOOKING", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -24, 1, -22), Size = UDim2.new(0.5, -30, 0, 52), TextSize = 16, ZIndex = 102, Parent = card })
		driveNow.Activated:Connect(function()
			local cb = s.callbacks
			DealerMenu.close()
			cb.drive(id)
		end)
		keep.Activated:Connect(function()
			over:Destroy()
		end)
	end

	local function confirmBuy(id: string)
		local spec = Cars.get(id)
		local over = new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.5, Size = UDim2.fromScale(1, 1), ZIndex = 90, Active = true, Parent = root })
		local card = panel({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(460, 210), ZIndex = 91, BackgroundTransparency = 0.04, Parent = over })
		local colourWord = if s.colour and PALETTE[s.colour] then " in " .. PALETTE[s.colour][1] else ""
		label({ Text = "Buy the " .. spec.Name .. colourWord .. " for " .. money(spec.Price) .. "?", TextSize = 20, Font = Enum.Font.GothamBold, TextWrapped = true, Position = UDim2.fromOffset(24, 22), Size = UDim2.new(1, -48, 0, 70), ZIndex = 92, Parent = card })
		label({ Text = "You have " .. money(s.data.Cash or 0), TextSize = 14, TextColor3 = GREY, Position = UDim2.fromOffset(24, 96), Size = UDim2.new(1, -48, 0, 18), ZIndex = 92, Parent = card })
		local cancel = flatButton("CANCEL", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 24, 1, -20), Size = UDim2.new(0.5, -30, 0, 52), TextSize = 16, ZIndex = 92, Parent = card })
		local yes = flatButton("BUY", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -24, 1, -20), Size = UDim2.new(0.5, -30, 0, 52), BackgroundColor3 = RED, ZIndex = 92, Parent = card })
		cancel.Activated:Connect(function()
			over:Destroy()
		end)
		yes.Activated:Connect(function()
			-- one purchase per click (the server also refuses a second one while it charges)
			if s.busy then
				return
			end
			s.busy = true
			yes.Text = "..."
			local res = s.callbacks.buy(id, s.colour)
			s.busy = false
			over:Destroy()
			if res and res.ok then
				if res.data then
					s.data = res.data
					for _, oid in res.data.Owned or {} do
						s.owned[oid] = true
					end
				end
				s.owned[id] = true
				refreshAll()
				celebrate(id)
			else
				showMsg((res and res.message) or "Couldn't buy it", Theme.Danger)
			end
		end)
	end

	buyBtn.Activated:Connect(function()
		local id = s.id
		if s.owned[id] then
			local cb = s.callbacks
			DealerMenu.close()
			cb.drive(id)
			return
		end
		local need = needFor(id)
		if levelNow() < need then
			showMsg("Reach level " .. need .. " to buy this one")
			return
		end
		if (s.data.Cash or 0) < Cars.get(id).Price then
			showMsg("Not enough cash: " .. money(Cars.get(id).Price - (s.data.Cash or 0)) .. " more", Theme.Danger)
			return
		end
		confirmBuy(id)
	end)
	testBtn.Activated:Connect(function()
		local fn = s.callbacks.testDrive
		if not fn then
			return
		end
		local res = fn(s.id)
		if res and res.ok then
			DealerMenu.close()
		else
			showMsg((res and res.message) or "No test drive right now", Theme.Danger)
		end
	end)
	exitBtn.Activated:Connect(function()
		DealerMenu.close()
	end)

	-- keyboard: arrows step trims (left / right) and scroll the list (up / down); Esc leaves
	table.insert(conns, UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		local k = input.KeyCode
		if k == Enum.KeyCode.Left then
			stepTrim(-1)
		elseif k == Enum.KeyCode.Right then
			stepTrim(1)
		elseif k == Enum.KeyCode.Up then
			list.CanvasPosition = Vector2.new(0, math.max(0, list.CanvasPosition.Y - 90))
		elseif k == Enum.KeyCode.Down then
			list.CanvasPosition = Vector2.new(0, list.CanvasPosition.Y + 90)
		elseif k == Enum.KeyCode.Escape then
			DealerMenu.close()
		end
	end))
end

---------------------------------------------------------------------
-- open / close
---------------------------------------------------------------------
function DealerMenu.isOpen(): boolean
	return open
end

function DealerMenu.close()
	if not open then
		return
	end
	open = false
	UI.modalOpen = false
	local cb = st and st.callbacks
	for _, c in conns do
		c:Disconnect()
	end
	table.clear(conns)
	table.clear(thumbQueue)
	if gui then
		gui:Destroy()
		gui = nil
	end
	if car then
		car:Destroy()
		car = nil
	end
	if stage then
		stage:Destroy()
		stage = nil
	end
	for g, was in hiddenGuis do
		if g.Parent then
			g.Enabled = was
		end
	end
	table.clear(hiddenGuis)
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
	end)
	local character = player.Character
	local hum = character and character:FindFirstChildOfClass("Humanoid")
	if hum and savedWalk then
		hum.WalkSpeed = savedWalk[1]
		hum.JumpPower = savedWalk[2]
	end
	savedWalk = nil
	camera.CameraType = Enum.CameraType.Custom
	camera.FieldOfView = 70
	st = nil
	if cb and cb.close then
		cb.close()
	end
end

function DealerMenu.open(data: any, callbacks: Callbacks, focus: string?)
	if open then
		DealerMenu.close()
	end
	open = true
	UI.modalOpen = true
	local owned: { [string]: boolean } = {}
	for _, id in data.Owned or {} do
		owned[id] = true
	end
	local first = if focus and Cars.ById[focus] then focus else (data.Selected or Cars.StarterId)
	if not Cars.ById[first] then
		first = Cars.StarterId
	end
	local ser = seriesOf(first)
	st = {
		data = data,
		callbacks = callbacks,
		owned = owned,
		brands = brandList(),
		brand = (ser and ser.Brand) or "",
		series = ser,
		id = first,
		colour = nil,
		busy = false,
	}

	-- other screens away, the player held still
	for _, g in player.PlayerGui:GetChildren() do
		if g:IsA("ScreenGui") and g.Enabled and g.Name ~= "DealerMenu" then
			hiddenGuis[g] = true
			g.Enabled = false
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

	stage = buildStage()
	showCar(first, nil)

	local g = Instance.new("ScreenGui")
	g.Name = "DealerMenu"
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	g.DisplayOrder = 40
	g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	g.Parent = player.PlayerGui
	gui = g
	-- one design size, scaled to the screen (a phone gets the same layout, smaller)
	local root: Frame = new("Frame", { BackgroundTransparency = 1, Parent = g })
	local scale = new("UIScale", { Parent = root })
	local function fit()
		local vp = camera.ViewportSize
		local k = math.clamp(math.min(vp.X / 1220, vp.Y / 640), 0.5, 1.25)
		scale.Scale = k
		root.Size = UDim2.fromOffset(vp.X / k, vp.Y / k)
	end
	fit()
	table.insert(conns, camera:GetPropertyChangedSignal("ViewportSize"):Connect(fit))
	build(root)
	refreshAll()

	-- the camera circles the car; drag to turn, scroll or pinch to zoom
	local dragging: InputObject? = nil
	local last = Vector2.zero
	local idle = 0
	table.insert(conns, UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = input
			last = Vector2.new(input.Position.X, input.Position.Y)
		end
	end))
	table.insert(conns, UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			zoomK = math.clamp(zoomK * (if input.Position.Z > 0 then 0.9 else 1.1), 0.6, 1.6)
		elseif dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input == dragging) then
			local p = Vector2.new(input.Position.X, input.Position.Y)
			local d = p - last
			last = p
			yaw -= d.X * 0.008
			pitch = math.clamp(pitch + d.Y * 0.004, 0.02, 0.7)
			idle = 0
		end
	end))
	table.insert(conns, UserInputService.InputEnded:Connect(function(input)
		if dragging and (input == dragging or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2) then
			dragging = nil
		end
	end))
	table.insert(conns, UserInputService.TouchPinch:Connect(function(_, scaleP, _, state)
		if state == Enum.UserInputState.Change then
			zoomK = math.clamp(zoomK / math.max(scaleP, 0.5) ^ 0.05, 0.6, 1.6)
		end
	end))
	table.insert(conns, RunService.RenderStepped:Connect(function(dt)
		idle += dt
		if not dragging and idle > 1.5 then
			yaw += dt * 0.12 -- slowly round, like a turntable
		end
		local target = STAGE + Vector3.new(0, 2.2, 0)
		local d = dist * zoomK
		local offset = Vector3.new(math.sin(yaw) * math.cos(pitch), math.sin(pitch), math.cos(yaw) * math.cos(pitch)) * d
		camera.CameraType = Enum.CameraType.Scriptable
		camera.FieldOfView = 50
		camera.CFrame = CFrame.lookAt(target + offset, target)
		camera.Focus = CFrame.new(target)
	end))
end

return DealerMenu
