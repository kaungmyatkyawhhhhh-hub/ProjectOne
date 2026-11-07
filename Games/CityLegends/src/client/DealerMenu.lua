--[[
	DealerMenu (client) (owner, 2026-10-31: "make the UI look a lot better", like Midnight Racing's
	dealership menu). E at the Legends Motors counter (or a display car's stand) opens it:
	  * the camera goes to a showroom stage built on this screen only, high above the city: a round
	    room, a polished dark floor, a turntable under spotlights. The picked car stands there and the
	    camera circles it slowly (drag to turn round it, scroll or pinch to come closer). The
	    dealership building itself isn't touched.
	  * top bar: EXIT, the brand and the car's name with its class badge, the price, TEST DRIVE and
	    BUY (or DRIVE when owned; greyed with the reason when locked)
	  * left, the vehicles in two levels: the brand's models (from $, N trims), then a model's trims,
	    worst to best (price, class, OWNED or locked); a Back row goes back
	  * over the car: the trim selector  <  NAME  >
	  * right: performance bars against the best car (speed, power to weight, braking, weight),
	    specs, paint swatches, trim chips, a line about the car, features
	  * bottom: the brand bar; bottom left: your level and the next unlock
	  * BUY asks first; the server checks money, level and ownership and charges once; then NEW CAR
	    with confetti and DRIVE IT NOW. TEST DRIVE is there for cars you don't own.
	  * (2026-11-03, "car class grades") every car shows its class badge ("A 661", CarStats.pi): cars
	    cost money only, class X also needs player level 60. A brand's level-50 cars take 5% each
	    off its prices (max 25%, the "BrandOff" attribute from CarLevels).
	  * (2026-11-04, owner-away run: "looks vibe coded", make it look like a top racing game's
	    showroom) one look for the whole screen: dark glass panels (a soft gradient, a thin light
	    edge and a highlight along the top), one font family (Builder Sans: ExtraBold for names
	    and prices, Bold for labels, Medium for text), drawn icons (DealerArt, tools/dealer_art.py),
	    gold for the main action and the selection, hover / press / slide-in animations. Phones
	    (and any small screen) get a compact layout with bigger type and touch targets.
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
local TrailerBuilder = require(Shared:WaitForChild("TrailerBuilder"))
local CarBuilder = require(Shared:WaitForChild("CarBuilder"))

local UI = require(script.Parent:WaitForChild("UI"))
local CarSkin = require(script.Parent:WaitForChild("CarSkin"))
local Audio = require(script.Parent:WaitForChild("Audio"))
local CustomsClient = require(script.Parent:WaitForChild("CustomsClient"))
local DealerArt = require(script.Parent:WaitForChild("DealerArt"))
local TrailerClient = require(script.Parent:WaitForChild("TrailerClient"))
local Driving = require(script.Parent:WaitForChild("Driving"))

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
local kit = UI.kit
local new, corner = kit.new, kit.corner

---------------------------------------------------------------------
-- the look
---------------------------------------------------------------------
local FAMILY = "rbxasset://fonts/families/BuilderSans.json"
local HEAVY = Font.new(FAMILY, Enum.FontWeight.ExtraBold)
local BOLD = Font.new(FAMILY, Enum.FontWeight.Bold)
local MEDIUM = Font.new(FAMILY, Enum.FontWeight.Medium)

local INK = Color3.fromRGB(10, 12, 20) -- the darkest glass
local GLASS = Color3.fromRGB(18, 21, 32)
local GLASS2 = Color3.fromRGB(32, 36, 50)
local EDGE = Color3.new(1, 1, 1)
local GOLD = Color3.fromRGB(255, 196, 82)
local GOLD_D = Color3.fromRGB(226, 146, 40)
local WHITE = Color3.fromRGB(246, 247, 251)
local GREY = Color3.fromRGB(160, 166, 184)
local DIM = Color3.fromRGB(104, 110, 130)
local GREEN = Color3.fromRGB(116, 228, 160)
local BLUE = Color3.fromRGB(124, 192, 255)
local RED = Color3.fromRGB(236, 72, 78)

local STAGE = Vector3.new(0, 3000, 0) -- the showroom stage, high above the city (this screen only)
local PALETTE = Config.Customs.Palette

local open = false
local gui: ScreenGui? = nil
local stage: Folder? = nil
local conns: { RBXScriptConnection } = {}
local hiddenGuis: { [ScreenGui]: boolean } = {}
local savedWalk: { number }? = nil
local savedHold: { boolean }? = nil -- Driving's camera / car holds before the screen opened

-- the layout: one design size scaled to the screen; small screens get the compact one
type Layout = {
	compact: boolean,
	W: number,
	H: number,
	m: number, -- outer margin
	topH: number,
	leftW: number,
	rightW: number,
	bottomH: number,
	rowH: number,
	btnH: number,
	f: number, -- type scale
}
local L: Layout = { compact = false, W = 1240, H = 660, m = 20, topH = 78, leftW = 304, rightW = 336, bottomH = 70, rowH = 86, btnH = 52, f = 1 }
local function layoutFor(vp: Vector2): Layout
	if vp.Y < 520 or vp.X < 1000 then
		return { compact = true, W = 860, H = 440, m = 10, topH = 60, leftW = 250, rightW = 256, bottomH = 54, rowH = 80, btnH = 46, f = 1.16 }
	end
	return { compact = false, W = 1240, H = 660, m = 20, topH = 78, leftW = 304, rightW = 336, bottomH = 70, rowH = 86, btnH = 52, f = 1 }
end
local function fs(n: number): number
	return math.floor(n * L.f + 0.5)
end

---------------------------------------------------------------------
-- helpers: text, icons, glass, buttons
---------------------------------------------------------------------
local function money(n: number): string
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return "$" .. out:gsub("^,", "")
end

local function text(props: { [string]: any }): TextLabel
	local base: { [string]: any } = {
		BackgroundTransparency = 1,
		FontFace = MEDIUM,
		TextColor3 = WHITE,
		TextSize = fs(15),
		Text = "",
		TextXAlignment = Enum.TextXAlignment.Left,
	}
	for k, v in props do
		base[k] = v
	end
	if props.TextSize then
		base.TextSize = fs(props.TextSize)
	end
	return new("TextLabel", base)
end

local function tween(inst: Instance, t: number, props: { [string]: any }, style: Enum.EasingStyle?)
	kit.tween(inst, t, props, style or Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
end

-- a drawn icon from the sheet (white, tinted)
local function glyph(name: string, size: number, color: Color3?, props: { [string]: any }?): ImageLabel
	local i = (table.find(DealerArt.icons, name) or 1) - 1
	local c = DealerArt.cell
	local base: { [string]: any } = {
		BackgroundTransparency = 1,
		Image = DealerArt.sheet,
		ImageRectOffset = Vector2.new((i % DealerArt.cols) * c, (i // DealerArt.cols) * c),
		ImageRectSize = Vector2.new(c, c),
		ImageColor3 = color or WHITE,
		Size = UDim2.fromOffset(size, size),
		ScaleType = Enum.ScaleType.Fit,
	}
	if props then
		for k, v in props do
			base[k] = v
		end
	end
	return new("ImageLabel", base)
end
local function setGlyph(img: ImageLabel, name: string)
	local i = (table.find(DealerArt.icons, name) or 1) - 1
	local c = DealerArt.cell
	img.ImageRectOffset = Vector2.new((i % DealerArt.cols) * c, (i // DealerArt.cols) * c)
end

-- dark glass: a soft top-to-bottom gradient, a thin light edge, a highlight along the top
local function glass(props: { [string]: any }, radius: number?): Frame
	local r = radius or 14
	local base: { [string]: any } = { BackgroundColor3 = GLASS, BackgroundTransparency = 0.16, BorderSizePixel = 0 }
	for k, v in props do
		base[k] = v
	end
	local f: Frame = new("Frame", base, {
		corner(r),
		new("UIStroke", { Color = EDGE, Transparency = 0.86, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		new("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(150, 156, 176)),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.18) }),
		}),
	})
	new("Frame", {
		Name = "Shine",
		BackgroundColor3 = EDGE,
		BackgroundTransparency = 0.82,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(r, 1),
		Size = UDim2.new(1, -2 * r, 0, 1),
		ZIndex = (base.ZIndex or 1),
		Parent = f,
	}, {
		new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }) }),
	})
	return f
end

-- a small caption over a section ("PERFORMANCE")
local function caption(str: string, props: { [string]: any }): TextLabel
	local p: { [string]: any } = { Text = str, TextSize = 12, FontFace = BOLD, TextColor3 = DIM }
	for k, v in props do
		p[k] = v
	end
	return text(p)
end

-- hover / press life for anything clickable: a slight grow on hover, a squeeze on press
local function alive(b: GuiButton, onHover: ((boolean) -> ())?)
	local sc = new("UIScale", { Parent = b })
	b.MouseEnter:Connect(function()
		tween(sc, 0.18, { Scale = 1.03 })
		if onHover then
			onHover(true)
		end
	end)
	b.MouseLeave:Connect(function()
		tween(sc, 0.22, { Scale = 1 })
		if onHover then
			onHover(false)
		end
	end)
	b.MouseButton1Down:Connect(function()
		tween(sc, 0.08, { Scale = 0.96 }, Enum.EasingStyle.Quad)
	end)
	b.MouseButton1Up:Connect(function()
		tween(sc, 0.2, { Scale = 1.03 })
	end)
end

type Btn = { b: TextButton, label: TextLabel, icon: ImageLabel?, set: (string?, string?, string?) -> () }
-- kind: "primary" (gold, the main action), "secondary" (glass), "ghost" (icon only, no plate)
local function button(kind: string, str: string, iconName: string?, props: { [string]: any }): Btn
	local primary = kind == "primary"
	local ghost = kind == "ghost"
	local base: { [string]: any } = {
		AutoButtonColor = false,
		Text = "",
		BackgroundColor3 = if primary then GOLD else GLASS2,
		BackgroundTransparency = if ghost then 1 elseif primary then 0 else 0.25,
		BorderSizePixel = 0,
	}
	for k, v in props do
		base[k] = v
	end
	local b: TextButton = new("TextButton", base, { corner(if ghost then 10 else 12) })
	local edge = new("UIStroke", { Color = EDGE, Transparency = if ghost then 1 elseif primary then 0.6 else 0.84, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = b })
	local grad = new("UIGradient", {
		Rotation = 90,
		Color = if primary then ColorSequence.new(Color3.fromRGB(255, 226, 150), Color3.fromRGB(255, 255, 255)) else ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(170, 176, 196)),
		Parent = b,
	})
	if primary then
		-- (the gold runs from a light top to a deeper bottom)
		grad.Color = ColorSequence.new(Color3.fromRGB(255, 238, 190), GOLD_D)
		b.BackgroundColor3 = Color3.new(1, 1, 1)
	end
	local fg = if primary then INK else WHITE
	local row = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), Parent = b }, {
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local ic: ImageLabel? = nil
	if iconName then
		ic = glyph(iconName, fs(if ghost then 26 else 20), fg, { LayoutOrder = 1, Parent = row })
	end
	local lab = text({ Text = str, FontFace = HEAVY, TextSize = 17, TextColor3 = fg, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1), LayoutOrder = 2, Visible = str ~= "", Parent = row })
	b.Activated:Connect(Audio.click)
	alive(b, function(on)
		if not ghost then
			tween(edge, 0.18, { Transparency = if on then (if primary then 0.3 else 0.6) else (if primary then 0.6 else 0.84) })
		else
			b.BackgroundTransparency = if on then 0.75 else 1
			b.BackgroundColor3 = GLASS2
		end
	end)
	local function set(t: string?, state: string?, iconN: string?)
		if t then
			lab.Text = t
			lab.Visible = t ~= ""
		end
		if iconN and ic then
			setGlyph(ic, iconN)
		end
		if state then
			-- "gold" (buy), "blue" (owned: drive), "off" (locked)
			local light, dark, ink2 = Color3.fromRGB(255, 238, 190), GOLD_D, INK
			if state == "blue" then
				light, dark, ink2 = Color3.fromRGB(170, 214, 255), Color3.fromRGB(40, 110, 210), INK
			elseif state == "off" then
				light, dark, ink2 = Color3.fromRGB(96, 100, 116), Color3.fromRGB(52, 55, 68), GREY
			end
			grad.Color = ColorSequence.new(light, dark)
			lab.TextColor3 = ink2
			if ic then
				ic.ImageColor3 = ink2
			end
		end
	end
	return { b = b, label = lab, icon = ic, set = set }
end

---------------------------------------------------------------------
-- roster helpers
---------------------------------------------------------------------
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
	-- a polished dark floor (it mirrors the car and the lights), a turntable with a brushed rim
	part(f, Vector3.new(150, 1, 150), c * CFrame.new(0, -0.5, 0), Color3.fromRGB(24, 25, 29), Enum.Material.SmoothPlastic, { Reflectance = 0.05 })
	part(f, Vector3.new(0.6, 34, 34), c * CFrame.new(0, 0.3, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(46, 47, 52), Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Cylinder, Reflectance = 0.06 })
	part(f, Vector3.new(0.4, 35, 35), c * CFrame.new(0, 0.2, 0) * CFrame.Angles(0, 0, math.pi / 2), Color3.fromRGB(196, 198, 204), Enum.Material.Metal, { Shape = Enum.PartType.Cylinder })
	-- a round room: dark panels with tall warm light slots between them and a thin warm line low down
	local R, H, N = 62, 40, 28
	for k = 0, N - 1 do
		local a = k / N * math.pi * 2
		local w = 2 * math.pi * R / N + 0.4
		part(f, Vector3.new(w, H, 1), c * CFrame.Angles(0, a, 0) * CFrame.new(0, H / 2, -R), Color3.fromRGB(26, 27, 32), Enum.Material.SmoothPlastic)
		part(f, Vector3.new(w, 0.5, 0.4), c * CFrame.Angles(0, a, 0) * CFrame.new(0, 2.2, -R + 0.7), Color3.fromRGB(255, 226, 190), Enum.Material.SmoothPlastic)
		if k % 2 == 0 then
			local slot = part(f, Vector3.new(1.2, H - 10, 0.3), c * CFrame.Angles(0, a + math.pi / N, 0) * CFrame.new(0, H / 2 + 2, -R + 0.8), Color3.fromRGB(255, 236, 206), Enum.Material.SmoothPlastic)
			local l = Instance.new("SurfaceLight")
			l.Face = Enum.NormalId.Back
			l.Color = Color3.fromRGB(255, 220, 180)
			l.Brightness = 0.45
			l.Range = 14
			l.Angle = 120
			l.Parent = slot
		end
	end
	-- the ceiling (also keeps the rain off: Weather sees a roof over the camera)
	part(f, Vector3.new(150, 1, 150), c * CFrame.new(0, H + 0.5, 0), Color3.fromRGB(18, 18, 22), Enum.Material.SmoothPlastic)
	for _, p in { { -18, -18 }, { 18, -18 }, { -18, 18 }, { 18, 18 } } do
		local panelPart = part(f, Vector3.new(14, 0.3, 14), c * CFrame.new(p[1], H - 0.2, p[2]), Color3.fromRGB(250, 246, 238), Enum.Material.SmoothPlastic)
		local l = Instance.new("SurfaceLight")
		l.Face = Enum.NormalId.Bottom
		l.Color = Color3.fromRGB(255, 240, 222)
		l.Brightness = 0.7
		l.Range = 48
		l.Angle = 110
		l.Parent = panelPart
	end
	-- spotlights on the car (soft shadows on the floor) and a key light over it for the paint
	for k = 0, 3 do
		local a = k * math.pi / 2 + math.pi / 4
		local p = (c * CFrame.new(math.cos(a) * 20, 24, math.sin(a) * 20)).Position
		local lamp = part(f, Vector3.new(1.4, 1.4, 2.2), CFrame.lookAt(p, STAGE + Vector3.new(0, 2, 0)), Color3.fromRGB(20, 20, 24), Enum.Material.Metal)
		local s = Instance.new("SpotLight")
		s.Face = Enum.NormalId.Front
		s.Color = Color3.fromRGB(255, 242, 226)
		s.Brightness = 1.8
		s.Range = 46
		s.Angle = 42
		s.Shadows = k < 2
		s.Parent = lamp
	end
	local key = part(f, Vector3.new(1, 1, 1), c * CFrame.new(0, 16, 0), Color3.new(0, 0, 0), Enum.Material.SmoothPlastic, { Transparency = 1 })
	local pl = Instance.new("PointLight")
	pl.Color = Color3.fromRGB(255, 248, 238)
	pl.Brightness = 0.9
	pl.Range = 26
	pl.Parent = key
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
local yaw, pitch, dist = -0.6, 0.14, 30
local zoomK = 1
local uiScale = 1
local refreshAll: () -> () = function() end

local function levelNow(): number
	local lvl = UI.getProgress()
	return lvl
end

local function needFor(id: string): number
	return CarStats.requiredLevel(id)
end

-- this player's brand discount on a car (CarLevels on the server: the "BrandOff" attribute), and
-- the price after it (the server works out the same)
local function brandOff(id: string): number
	local raw = player:GetAttribute("BrandOff")
	if type(raw) ~= "string" then
		return 0
	end
	local ok, t = pcall(function()
		return game:GetService("HttpService"):JSONDecode(raw)
	end)
	local at = Cars.SeriesOf[id]
	local brand = at and at.series.Brand
	return if ok and type(t) == "table" and brand then tonumber(t[brand]) or 0 else 0
end
local function priceOf(id: string): number
	return math.floor(Cars.get(id).Price * (1 - brandOff(id)) / 100 + 0.5) * 100
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
	if colour then
		pcall(CustomsClient.paintCar, m, lookFor(id, colour))
	end
	car = m
	-- (the camera's FOV is 40: the car fills the gap between the panels)
	dist = (carLen * 1.3 + 6) * 1.2
end

---------------------------------------------------------------------
-- thumbnails: a small 3D shot of a car (light bodies, made a few a frame)
---------------------------------------------------------------------
local thumbQueue: { { vp: ViewportFrame, id: string } } = {}
local thumbRunning = false
local function thumb(parent: Instance, id: string, size: Vector2, pos: UDim2): Frame
	local holder = new("Frame", {
		BackgroundColor3 = Color3.fromRGB(44, 48, 64),
		BorderSizePixel = 0,
		Position = pos,
		Size = UDim2.fromOffset(size.X, size.Y),
		Parent = parent,
	}, {
		corner(10),
		new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(90, 94, 112)) }),
	})
	local vp: ViewportFrame = new("ViewportFrame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Ambient = Color3.fromRGB(170, 170, 180),
		LightColor = Color3.fromRGB(255, 250, 240),
		LightDirection = Vector3.new(-0.5, -1, -0.4),
		Parent = holder,
	})
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
						cam.CFrame = CFrame.lookAt(Vector3.new(len * 1.15, len * 0.42, len * 1.25), Vector3.new(0, h * 0.35, 0))
						cam.Parent = job.vp
						job.vp.CurrentCamera = cam
					end
				end
				task.wait()
			end
			thumbRunning = false
		end)
	end
	return holder
end

---------------------------------------------------------------------
-- the screen
---------------------------------------------------------------------
local function confetti(parent: Instance)
	local cols = { GOLD, WHITE, Color3.fromRGB(90, 170, 255), GREEN, RED }
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

-- a panel slides a little and settles when the screen opens
local function slideIn(f: GuiObject, dx: number, dy: number, delay: number)
	local to = f.Position
	f.Position = to + UDim2.fromOffset(dx, dy)
	task.delay(delay, function()
		if f.Parent then
			tween(f, 0.45, { Position = to })
		end
	end)
end

local function build(root: Frame)
	local s = st :: State
	local m = L.m
	local compact = L.compact

	-----------------------------------------------------------------
	-- top bar: EXIT · brand / name + class · price · TEST DRIVE · BUY
	-----------------------------------------------------------------
	local top = glass({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, m), Size = UDim2.new(1, -2 * m, 0, L.topH), Parent = root })
	local bh = L.btnH
	local pad = math.floor((L.topH - bh) / 2)
	local exitBtn = button("secondary", if compact then "" else "EXIT", "exit", { Position = UDim2.fromOffset(pad, pad), Size = UDim2.fromOffset(if compact then bh else 118, bh), Parent = top })
	local buyBtn = button("primary", "BUY", "tag", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -pad, 0, pad), Size = UDim2.fromOffset(if compact then 132 else 172, bh), Parent = top })
	local testBtn = button("secondary", if compact then "" else "TEST DRIVE", "wheel", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -pad - (if compact then 132 else 172) - 10, 0, pad), Size = UDim2.fromOffset(if compact then bh else 166, bh), Parent = top })
	-- the name block
	local nameX = pad + (if compact then bh else 118) + (if compact then 12 else 20)
	local brandRow = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(nameX, if compact then 7 else 12), Size = UDim2.new(0.5, 0, 0, fs(18)), Parent = top }, {
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local brandText = text({ Text = "", FontFace = BOLD, TextSize = 13, TextColor3 = GOLD, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1), LayoutOrder = 1, Parent = brandRow })
	local _, setClass = kit.classBadge({ Height = fs(18), LayoutOrder = 2, Parent = brandRow })
	-- the price, right of the name, left of the buttons
	local priceRight = pad + (if compact then 132 + bh else 172 + 166) + (if compact then 22 else 30)
	local nameText = text({ Text = "", FontFace = HEAVY, TextSize = if compact then 20 else 26, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(nameX, if compact then 25 else 34), Size = UDim2.new(1, -nameX - priceRight - (if compact then 120 else 200), 0, fs(if compact then 24 else 32)), Parent = top })
	local priceCap = caption("PRICE", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -priceRight, 0, if compact then 8 else 13), Size = UDim2.fromOffset(200, fs(14)), TextXAlignment = Enum.TextXAlignment.Right, Parent = top })
	local priceText = text({ Text = "", FontFace = HEAVY, TextSize = if compact then 20 else 26, TextColor3 = GREEN, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -priceRight, 0, if compact then 24 else 32), Size = UDim2.fromOffset(240, fs(if compact then 24 else 30)), TextXAlignment = Enum.TextXAlignment.Right, Parent = top })
	-- (2026-11-07) a car with a hitch
	local function towTag(id: string): string
		local kg = CarStats.towKg(id)
		return if kg > 0 then "TOWS " .. string.format("%d,%03d", kg // 1000, kg % 1000) .. " KG" else ""
	end
	local priceNote = text({ Text = "", FontFace = BOLD, TextSize = 12, TextColor3 = GOLD, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -priceRight - 120, 0, if compact then 8 else 13), Size = UDim2.fromOffset(160, fs(14)), TextXAlignment = Enum.TextXAlignment.Right, Parent = top })

	-----------------------------------------------------------------
	-- the trim selector over the car
	-----------------------------------------------------------------
	local barY = m + L.topH + (if compact then 6 else 12)
	local trimBar = glass({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, barY), Size = UDim2.fromOffset(if compact then 280 else 400, if compact then 40 else 48), BackgroundTransparency = 0.3 }, 24)
	trimBar.Parent = root
	local prevTrim = button("ghost", "", "back", { Size = UDim2.new(0, if compact then 44 else 52, 1, 0), Parent = trimBar })
	local nextTrim = button("ghost", "", "next", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0, if compact then 44 else 52, 1, 0), Parent = trimBar })
	local trimText = text({ Text = "", FontFace = HEAVY, TextSize = if compact then 17 else 21, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(52, 0), Size = UDim2.new(1, -104, 1, 0), Parent = trimBar })
	local trimNote = text({ Text = "", FontFace = BOLD, TextSize = 12, TextColor3 = GREY, TextXAlignment = Enum.TextXAlignment.Center, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 5), Size = UDim2.fromOffset(320, fs(14)), Parent = trimBar })

	-----------------------------------------------------------------
	-- left: vehicles (models, then a model's trims)
	-----------------------------------------------------------------
	local panelTop = barY
	local panelBottom = L.bottomH + m + (if compact then 8 else 12)
	local left = glass({ Position = UDim2.fromOffset(m, panelTop), Size = UDim2.new(0, L.leftW, 1, -panelTop - panelBottom), Parent = root })
	local headH = if compact then 40 else 52
	local headCap = caption("VEHICLES", { Position = UDim2.fromOffset(16, if compact then 5 else 9), Size = UDim2.new(1, -32, 0, fs(13)), Parent = left })
	local headText = text({ Text = "", FontFace = HEAVY, TextSize = if compact then 16 else 19, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(16, if compact then 18 else 24), Size = UDim2.new(1, -32, 0, fs(22)), Parent = left })
	new("Frame", { BackgroundColor3 = EDGE, BackgroundTransparency = 0.9, BorderSizePixel = 0, Position = UDim2.fromOffset(12, headH + 2), Size = UDim2.new(1, -24, 0, 1), Parent = left })
	local list: ScrollingFrame = new("ScrollingFrame", {
		Position = UDim2.fromOffset(8, headH + 8),
		Size = UDim2.new(1, -16, 1, -headH - 14),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = GREY,
		ScrollBarImageTransparency = 0.5,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = left,
	}, {
		new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
		new("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 6), PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 2) }),
	})

	-----------------------------------------------------------------
	-- right: performance, specs, paint, trims, features
	-----------------------------------------------------------------
	local right = glass({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -m, 0, panelTop), Size = UDim2.new(0, L.rightW, 1, -panelTop - panelBottom), Parent = root })
	local rscroll: ScrollingFrame = new("ScrollingFrame", {
		Position = UDim2.fromOffset(0, 6),
		Size = UDim2.new(1, -4, 1, -12),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = GREY,
		ScrollBarImageTransparency = 0.5,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		Parent = right,
	}, {
		new("UIListLayout", { Padding = UDim.new(0, if compact then 8 else 10), SortOrder = Enum.SortOrder.LayoutOrder }),
		new("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 10) }),
	})
	local order = 0
	local function nextOrder(): number
		order += 1
		return order
	end
	local function section(str: string)
		caption(str, { Size = UDim2.new(1, 0, 0, fs(14)), LayoutOrder = nextOrder(), Parent = rscroll })
	end
	section("PERFORMANCE")
	local function bar(iconName: string, name: string): (TextLabel, Frame)
		local row = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, fs(32)), LayoutOrder = nextOrder(), Parent = rscroll })
		glyph(iconName, fs(16), GREY, { Position = UDim2.fromOffset(0, 0), Parent = row })
		text({ Text = name, FontFace = BOLD, TextSize = 13, TextColor3 = GREY, Position = UDim2.fromOffset(fs(22), 0), Size = UDim2.new(0.55, 0, 0, fs(16)), Parent = row })
		local val = text({ Text = "", FontFace = HEAVY, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0.6, 0, 0, fs(16)), Parent = row })
		local back = new("Frame", { Position = UDim2.new(0, 0, 1, -7), Size = UDim2.new(1, 0, 0, 6), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.9, BorderSizePixel = 0, Parent = row }, { corner(3) })
		local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = back }, {
			corner(3),
			new("UIGradient", { Color = ColorSequence.new(GOLD_D, Color3.fromRGB(255, 232, 160)) }),
		})
		return val, fill
	end
	local speedVal, speedFill = bar("gauge", "Top speed")
	local ptwVal, ptwFill = bar("bolt", "Power to weight")
	local brakeVal, brakeFill = bar("abs", "Braking")
	local weightVal, weightFill = bar("weight", "Weight")

	section("SPECS")
	local facts = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, fs(58)), LayoutOrder = nextOrder(), Parent = rscroll }, {
		new("UIGridLayout", { CellSize = UDim2.new(0.25, -6, 1, 0), CellPadding = UDim2.fromOffset(8, 0), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local function fact(iconName: string, name: string): TextLabel
		local cell = new("Frame", { BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.94, LayoutOrder = nextOrder(), Parent = facts }, { corner(10), new("UIStroke", { Color = EDGE, Transparency = 0.9 }) })
		glyph(iconName, fs(16), GREY, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Parent = cell })
		local v = text({ Text = "", FontFace = HEAVY, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.new(0, 0, 0, fs(24)), Size = UDim2.new(1, 0, 0, fs(16)), Parent = cell })
		text({ Text = name, FontFace = MEDIUM, TextSize = 10, TextColor3 = DIM, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.new(0, 0, 0, fs(40)), Size = UDim2.new(1, 0, 0, fs(12)), Parent = cell })
		return v
	end
	local powerVal = fact("power", "power")
	local torqueVal = fact("torque", "torque")
	local driveVal = fact("drive", "drive")
	local seatsVal = fact("seat", "seats")

	local paintRow = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, fs(14)), LayoutOrder = nextOrder(), Parent = rscroll })
	caption("PAINT", { Size = UDim2.new(0.4, 0, 1, 0), Parent = paintRow })
	local colourName = text({ Text = "", FontFace = BOLD, TextSize = 12, TextColor3 = GREY, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), Size = UDim2.new(0.6, 0, 1, 0), Parent = paintRow })
	local sw = if compact then 30 else 28
	local swatches = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = nextOrder(), Parent = rscroll }, {
		new("UIGridLayout", { CellSize = UDim2.fromOffset(sw, sw), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local swatchStrokes: { [number]: UIStroke } = {}
	local stockSwatch: TextButton = new("TextButton", { Text = "", AutoButtonColor = false, LayoutOrder = 0, Parent = swatches }, { corner(sw // 2) })
	swatchStrokes[0] = new("UIStroke", { Thickness = 2, Color = WHITE, Parent = stockSwatch })
	glyph("star", math.floor(sw * 0.5), INK, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Parent = stockSwatch })
	alive(stockSwatch)
	for i, swc in PALETTE do
		local b: TextButton = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.fromRGB(swc[2], swc[3], swc[4]), LayoutOrder = i, Parent = swatches }, {
			corner(sw // 2),
			new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(190, 190, 200)) }),
		})
		swatchStrokes[i] = new("UIStroke", { Thickness = 1, Color = WHITE, Transparency = 0.6, Parent = b })
		alive(b)
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
		-- (the factory look: the car rebuilt as it comes, livery and all)
		Audio.click()
		s.colour = nil
		showCar(s.id, nil)
		refreshAll()
	end)

	section("TRIMS")
	local chips = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = nextOrder(), Parent = rscroll }, {
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Wraps = true, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local descText = text({ Text = "", TextSize = 14, TextWrapped = true, TextColor3 = GREY, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = nextOrder(), Parent = rscroll })

	section("FEATURES")
	local icons = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, fs(56)), LayoutOrder = nextOrder(), Parent = rscroll }, {
		new("UIGridLayout", { CellSize = UDim2.new(1 / 5, -6, 1, 0), CellPadding = UDim2.fromOffset(7, 0), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local function feature(iconName: string, name: string, clickable: boolean?): (TextLabel, TextLabel, ImageLabel, GuiObject)
		local cell: GuiObject = new(if clickable then "TextButton" else "Frame", { BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.94, LayoutOrder = nextOrder(), Parent = icons }, { corner(10), new("UIStroke", { Color = EDGE, Transparency = 0.9 }) })
		if clickable then
			(cell :: TextButton).Text = "";
			(cell :: TextButton).AutoButtonColor = false
			alive(cell :: TextButton)
		end
		local ic = glyph(iconName, fs(18), WHITE, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Parent = cell })
		local v = text({ Text = "", FontFace = HEAVY, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.new(0, 0, 0, fs(27)), Size = UDim2.new(1, 0, 0, fs(13)), Parent = cell })
		local sub = text({ Text = name, FontFace = MEDIUM, TextSize = 10, TextColor3 = DIM, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.new(0, 0, 0, fs(41)), Size = UDim2.new(1, 0, 0, fs(12)), Parent = cell })
		return v, sub, ic, cell
	end
	local absVal = feature("abs", "brakes")
	local fuelVal, fuelSub, fuelIcon = feature("fuel", "fuel")
	local boxVal = feature("gearbox", "gearbox")
	local mpgVal = feature("drop", "economy")
	local soundVal, _, _, soundCell = feature("sound", "listen", true)
	soundVal.Text = "PLAY";
	(soundCell :: TextButton).Activated:Connect(function()
		Audio.engineStart()
	end)

	-----------------------------------------------------------------
	-- bottom: your level (left) and the brand bar
	-----------------------------------------------------------------
	local lvlW = if compact then 0 else L.leftW
	local brandBar = glass({ AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, m + lvlW + (if compact then 0 else 12), 1, -m), Size = UDim2.new(1, -2 * m - lvlW - (if compact then 0 else 12), 0, L.bottomH), Parent = root })
	local arrowW = if compact then 44 else 48
	local bPrev = button("ghost", "", "back", { Position = UDim2.fromOffset(4, 4), Size = UDim2.new(0, arrowW, 1, -8), Parent = brandBar })
	local bNext = button("ghost", "", "next", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -4, 0, 4), Size = UDim2.new(0, arrowW, 1, -8), Parent = brandBar })
	local tiles: ScrollingFrame = new("ScrollingFrame", {
		Position = UDim2.fromOffset(arrowW + 6, 0),
		Size = UDim2.new(1, -2 * arrowW - 12, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		ScrollingDirection = Enum.ScrollingDirection.X,
		AutomaticCanvasSize = Enum.AutomaticSize.X,
		CanvasSize = UDim2.new(),
		ClipsDescendants = true,
		Parent = brandBar,
	}, {
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
		new("UIPadding", { PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 4) }),
	})
	local tileW, tileH = if compact then 118 else 136, L.bottomH - (if compact then 14 else 18)
	local tileByBrand: { [string]: { b: TextButton, t: TextLabel, e: UIStroke } } = {}
	local function pickBrand(b: string)
		s.brand = b
		s.series = nil
		for _, ser in Cars.Series do
			if ser.Brand == b then
				s.id = ser.Ids[1]
				break
			end
		end
		s.colour = nil
		showCar(s.id, nil)
		refreshAll()
	end
	for i, b in s.brands do
		local t: TextButton = new("TextButton", { Text = "", AutoButtonColor = false, LayoutOrder = i, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.94, Size = UDim2.fromOffset(tileW, tileH), Parent = tiles }, { corner(10) })
		local e = new("UIStroke", { Color = EDGE, Transparency = 0.88, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = t })
		local lab = text({ Text = string.upper(b), FontFace = HEAVY, TextSize = 14, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = GREY, Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -16, 1, 0), Parent = t })
		alive(t)
		t.Activated:Connect(function()
			Audio.click()
			pickBrand(b)
		end)
		tileByBrand[b] = { b = t, t = lab, e = e }
	end
	-- (2026-11-07) trailers: not a brand, a tile of its own at the end of the row
	local buyTrailer: () -> ()
	do
		local t: TextButton = new("TextButton", { Name = "TrailersTile", Text = "", AutoButtonColor = false, LayoutOrder = #s.brands + 1, BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.94, Size = UDim2.fromOffset(tileW, tileH), Parent = tiles }, { corner(10) })
		new("UIStroke", { Color = GOLD, Transparency = 0.45, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = t })
		text({ Text = "TRAILERS", FontFace = HEAVY, TextSize = 14, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = GOLD, Position = UDim2.fromOffset(8, 0), Size = UDim2.new(1, -16, 1, 0), Parent = t })
		alive(t)
		t.Activated:Connect(function()
			Audio.click()
			buyTrailer()
		end)
	end
	local function stepBrand(d: number)
		local idx = table.find(s.brands, s.brand) or 1
		pickBrand(s.brands[(idx - 1 + d) % #s.brands + 1])
	end
	bPrev.b.Activated:Connect(function()
		stepBrand(-1)
	end)
	bNext.b.Activated:Connect(function()
		stepBrand(1)
	end)

	local lvlNum, xpFill, nextText
	if not compact then
		local lvlBox = glass({ AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, m, 1, -m), Size = UDim2.fromOffset(L.leftW, L.bottomH), Parent = root })
		local ring = new("Frame", { Position = UDim2.fromOffset(12, (L.bottomH - 46) // 2), Size = UDim2.fromOffset(46, 46), BackgroundColor3 = INK, Parent = lvlBox }, {
			corner(23),
			new("UIStroke", { Color = GOLD, Thickness = 2 }),
		})
		lvlNum = text({ Text = "", FontFace = HEAVY, TextSize = 19, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = ring })
		caption("YOUR LEVEL", { Position = UDim2.fromOffset(70, 12), Size = UDim2.fromOffset(200, 14), Parent = lvlBox })
		local xpBack = new("Frame", { Position = UDim2.fromOffset(70, 31), Size = UDim2.new(1, -86, 0, 6), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.9, BorderSizePixel = 0, Parent = lvlBox }, { corner(3) })
		xpFill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = xpBack }, { corner(3), new("UIGradient", { Color = ColorSequence.new(GOLD_D, Color3.fromRGB(255, 232, 160)) }) })
		nextText = text({ Text = "", FontFace = MEDIUM, TextSize = 12, TextColor3 = GREY, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(70, 42), Size = UDim2.new(1, -84, 0, 16), Parent = lvlBox })
		slideIn(lvlBox, 0, 30, 0.1)
	end

	-- messages: a glass pill over the brand bar
	local toast = glass({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -m - L.bottomH - 12), Size = UDim2.fromOffset(0, fs(40)), AutomaticSize = Enum.AutomaticSize.X, Visible = false, ZIndex = 20, Parent = root }, 20)
	local toastRow = new("Frame", { BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1), ZIndex = 21, Parent = toast }, {
		new("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 18) }),
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local toastIcon = glyph("lock", fs(18), GOLD, { ZIndex = 21, LayoutOrder = 1, Parent = toastRow })
	local toastText = text({ Text = "", FontFace = BOLD, TextSize = 15, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromScale(0, 1), ZIndex = 21, LayoutOrder = 2, Parent = toastRow })

	slideIn(top, 0, -30, 0)
	slideIn(left, -40, 0, 0.05)
	slideIn(right, 40, 0, 0.05)
	slideIn(brandBar, 0, 30, 0.1)

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
	local function rowBase(lo: number, h: number, selected: boolean): TextButton
		local r: TextButton = new("TextButton", {
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = if selected then GOLD else Color3.fromRGB(255, 255, 255),
			BackgroundTransparency = if selected then 0.86 else 0.95,
			Size = UDim2.new(1, 0, 0, h),
			LayoutOrder = lo,
			Parent = list,
		}, { corner(12) })
		local e = new("UIStroke", { Color = if selected then GOLD else EDGE, Transparency = if selected then 0.1 else 0.9, Thickness = if selected then 1.5 else 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = r })
		r.MouseEnter:Connect(function()
			if not selected then
				tween(r, 0.15, { BackgroundTransparency = 0.9 })
				tween(e, 0.15, { Transparency = 0.75 })
			end
		end)
		r.MouseLeave:Connect(function()
			if not selected then
				tween(r, 0.2, { BackgroundTransparency = 0.95 })
				tween(e, 0.2, { Transparency = 0.9 })
			end
		end)
		return r
	end
	local thumbW, thumbH = if compact then 64 else 104, if compact then 46 else L.rowH - 16
	local function fillList()
		clearList()
		local lv = levelNow()
		local tx = thumbW + 18
		if s.series then
			local ser = s.series :: Cars.Series
			headCap.Text = string.upper(s.brand)
			headText.Text = modelName(ser)
			local back = rowBase(0, fs(36), false)
			glyph("back", fs(14), GREY, { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0), Parent = back })
			text({ Text = "All " .. s.brand .. " models", FontFace = BOLD, TextSize = 13, TextColor3 = GREY, Position = UDim2.fromOffset(12 + fs(14) + 8, 0), Size = UDim2.new(1, -40, 1, 0), Parent = back })
			back.Activated:Connect(function()
				Audio.click()
				s.series = nil
				refreshAll()
			end)
			for i, id in ser.Ids do
				local row = rowBase(i, L.rowH, id == s.id)
				thumb(row, id, Vector2.new(thumbW, thumbH), UDim2.fromOffset(8, (L.rowH - thumbH) // 2))
				text({ Text = Cars.trimLabel(id), FontFace = HEAVY, TextSize = 16, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(tx, 9), Size = UDim2.new(1, -tx - 8, 0, fs(19)), Parent = row })
				text({ Text = money(priceOf(id)), FontFace = BOLD, TextSize = 14, TextColor3 = GREEN, Position = UDim2.fromOffset(tx, 9 + fs(20)), Size = UDim2.new(1, -tx - 8, 0, fs(16)), Parent = row })
				local need = needFor(id)
				UI.classBadgeFor(id, nil, { Height = fs(17), Position = UDim2.new(0, tx, 1, -fs(17) - 9), Parent = row })
				local state = if s.owned[id] then "owned" elseif lv < need then "locked" else ""
				if state ~= "" then
					local col = if state == "owned" then BLUE else GOLD
					local sx = tx + math.floor(fs(17) * 2.9) + 8
					glyph(if state == "owned" then "check" else "lock", fs(14), col, { Position = UDim2.new(0, sx, 1, -fs(16) - 9), Parent = row })
					text({ Text = if state == "owned" then "OWNED" else "LV " .. need, FontFace = HEAVY, TextSize = 11, TextColor3 = col, Position = UDim2.new(0, sx + fs(14) + 4, 1, -fs(16) - 9), Size = UDim2.new(1, -sx - 30, 0, fs(15)), Parent = row })
				end
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
			headCap.Text = "VEHICLES"
			headText.Text = s.brand
			local i = 0
			for _, ser in Cars.Series do
				if ser.Brand ~= s.brand then
					continue
				end
				i += 1
				local baseId = ser.Ids[1]
				local row = rowBase(i, L.rowH, seriesOf(s.id) == ser)
				thumb(row, baseId, Vector2.new(thumbW, thumbH), UDim2.fromOffset(8, (L.rowH - thumbH) // 2))
				text({ Text = modelName(ser), FontFace = HEAVY, TextSize = 16, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(tx, 9), Size = UDim2.new(1, -tx - 8, 0, fs(19)), Parent = row })
				text({ Text = "from " .. money(Cars.get(baseId).Price), FontFace = BOLD, TextSize = 13, TextColor3 = GREEN, Position = UDim2.fromOffset(tx, 9 + fs(20)), Size = UDim2.new(1, -tx - 8, 0, fs(16)), Parent = row })
				UI.classBadgeFor(baseId, nil, { Height = fs(17), Position = UDim2.new(0, tx, 1, -fs(17) - 9), Parent = row })
				local sx = tx + math.floor(fs(17) * 2.9) + 8
				text({ Text = #ser.Ids .. " trim" .. (if #ser.Ids == 1 then "" else "s"), FontFace = BOLD, TextSize = 12, TextColor3 = GREY, Position = UDim2.new(0, sx, 1, -fs(16) - 9), Size = UDim2.new(1, -sx - 24, 0, fs(15)), Parent = row })
				glyph("next", fs(14), DIM, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Parent = row })
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
	local lastId = ""
	refreshAll = function()
		local id = s.id
		local spec = Cars.get(id)
		local ser = seriesOf(id)
		local stats = CarStats.of(id)
		local best = CarStats.best()
		local lv = levelNow()
		local need = needFor(id)
		local owned = s.owned[id] == true
		local locked = not owned and lv < need
		-- top bar
		brandText.Text = string.upper((ser and ser.Brand) or "")
		local brand = (ser and ser.Brand) or ""
		-- (the name without the make, which is shown over it: "Aventador SVJ")
		local head = Cars.upper(string.sub(spec.Name, 1, #brand))
		nameText.Text = if brand ~= "" and head == Cars.upper(brand) and string.sub(spec.Name, #brand + 1, #brand + 1) == " " then string.sub(spec.Name, #brand + 2) else spec.Name
		local letter, _, pi = CarStats.classOf(id)
		setClass(letter, pi)
		local off = brandOff(id)
		if owned then
			priceCap.Text = "IN YOUR GARAGE"
			priceText.Text = "OWNED"
			priceText.TextColor3 = BLUE
			priceNote.Text = towTag(id)
			buyBtn.set("DRIVE", "blue", "key")
		else
			-- (2026-11-07) real prices: what kind of price it is
			local kind = spec.PriceSource
			priceCap.Text = if kind then "PRICE  ·  " .. string.upper(kind) else "PRICE"
			priceText.Text = money(priceOf(id))
			priceText.TextColor3 = if (s.data.Cash or 0) >= priceOf(id) then GREEN else WHITE
			priceNote.Text = if off > 0 then string.format("-%d%% BRAND BONUS", math.floor(off * 100 + 0.5)) else towTag(id)
			if locked then
				buyBtn.set("LEVEL " .. need, "off", "lock")
			else
				buyBtn.set("BUY", "gold", "tag")
			end
		end
		testBtn.b.Visible = s.callbacks.testDrive ~= nil and not owned
		-- the name fades in on a new car
		if id ~= lastId then
			lastId = id
			nameText.TextTransparency = 1
			trimText.TextTransparency = 1
			tween(nameText, 0.35, { TextTransparency = 0 })
			tween(trimText, 0.35, { TextTransparency = 0 })
		end
		-- trim selector
		trimText.Text = string.upper(Cars.trimLabel(id))
		local count = if ser then #ser.Ids else 1
		local idx = if ser then (table.find(ser.Ids, id) or 1) else 1
		prevTrim.b.Visible = idx > 1
		nextTrim.b.Visible = idx < count
		trimNote.Text = if owned then "OWNED" elseif locked then "CLASS " .. letter .. " · REACH LEVEL " .. need else "TRIM " .. idx .. " OF " .. count
		trimNote.TextColor3 = if owned then BLUE elseif locked then GOLD else GREY
		-- bars (they grow to the new value)
		speedVal.Text = if compact then stats.kmh .. " km/h" else stats.kmh .. " km/h  ·  " .. stats.mph .. " mph"
		tween(speedFill, 0.4, { Size = UDim2.fromScale(math.clamp(stats.kmh / best.kmh, 0.02, 1), 1) })
		ptwVal.Text = stats.ptw .. " hp/t"
		tween(ptwFill, 0.4, { Size = UDim2.fromScale(math.clamp(stats.ptw / best.ptw, 0.02, 1), 1) })
		brakeVal.Text = math.floor(stats.braking * 100) .. " / 100"
		tween(brakeFill, 0.4, { Size = UDim2.fromScale(math.clamp(stats.braking, 0.02, 1), 1) })
		weightVal.Text = string.format("%d kg", stats.weightKg)
		tween(weightFill, 0.4, { Size = UDim2.fromScale(math.clamp(stats.weightKg / best.weightKg, 0.02, 1), 1) })
		-- specs
		powerVal.Text = stats.hp .. " hp"
		torqueVal.Text = stats.torqueNm .. " Nm"
		driveVal.Text = stats.drive
		seatsVal.Text = tostring(stats.seats)
		-- (the picked swatch gets a gold ring; the others a faint one, so black still shows)
		for k, strokeInst in swatchStrokes do
			local on = (s.colour or 0) == k
			strokeInst.Color = if on then GOLD else WHITE
			strokeInst.Transparency = if on then 0 else 0.6
			strokeInst.Thickness = if on then 3 else 1
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
				local on = tid == id
				local chip: TextButton = new("TextButton", {
					Text = string.upper(Cars.trimLabel(tid)),
					AutoButtonColor = false,
					FontFace = HEAVY,
					TextSize = fs(12),
					TextColor3 = if on then INK else WHITE,
					BackgroundColor3 = if on then GOLD else Color3.fromRGB(255, 255, 255),
					BackgroundTransparency = if on then 0 else 0.92,
					AutomaticSize = Enum.AutomaticSize.X,
					Size = UDim2.fromOffset(0, fs(if compact then 30 else 28)),
					LayoutOrder = i,
					Parent = chips,
				}, { corner(14), new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }), new("UIStroke", { Color = EDGE, Transparency = if on then 1 else 0.86, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }) })
				alive(chip)
				chip.Activated:Connect(function()
					if s.id ~= tid then
						Audio.click()
						s.id = tid
						showCar(tid, s.colour)
						Audio.engineStart()
						refreshAll()
					end
				end)
			end
		end
		descText.Text = stats.description
		absVal.Text = if stats.abs then "ABS" else "—"
		fuelVal.Text = string.upper(stats.fuel)
		fuelSub.Text = if spec.Electric then "power" else "fuel"
		setGlyph(fuelIcon, if spec.Electric then "bolt" else "fuel")
		boxVal.Text = if stats.gearbox == "1" then "1-SPEED" elseif stats.gearbox == "M/A" then "M / A" else "AUTO"
		mpgVal.Text = stats.mpg
		-- brand tiles (the picked one scrolled into view)
		local bi = table.find(s.brands, s.brand) or 1
		local view = tiles.AbsoluteSize.X / math.max(uiScale, 0.01)
		tween(tiles, 0.35, { CanvasPosition = Vector2.new(math.max(0, (bi - 1) * (tileW + 8) - (view / 2 - tileW / 2)), 0) })
		for b, t in tileByBrand do
			local on = b == s.brand
			t.b.BackgroundColor3 = if on then GOLD else Color3.fromRGB(255, 255, 255)
			t.b.BackgroundTransparency = if on then 0.84 else 0.94
			t.e.Color = if on then GOLD else EDGE
			t.e.Transparency = if on then 0.05 else 0.88
			t.t.TextColor3 = if on then GOLD else GREY
		end
		-- level box
		local plv, pxp, pneed = UI.getProgress()
		if lvlNum then
			lvlNum.Text = tostring(plv)
			xpFill.Size = UDim2.fromScale(math.clamp(pxp / math.max(1, pneed), 0, 1), 1)
			local nextId, nextLv = nil, math.huge
			for _, sp in Cars.List do
				local n2 = needFor(sp.Id)
				if n2 > plv and n2 < nextLv and not s.owned[sp.Id] then
					nextId, nextLv = sp.Id, n2
				end
			end
			nextText.Text = if nextId then "Class X opens at level " .. nextLv else "Every car is open to you"
		end
		-- the list (rebuilt only when what it shows changes)
		local ownedN = 0
		for _ in s.owned do
			ownedN += 1
		end
		local key = s.brand .. "|" .. (if s.series then s.series.Name else "-") .. "|" .. id .. "|" .. tostring(plv) .. "|" .. ownedN
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
	prevTrim.b.Activated:Connect(function()
		stepTrim(-1)
	end)
	nextTrim.b.Activated:Connect(function()
		stepTrim(1)
	end)

	-----------------------------------------------------------------
	-- buying
	-----------------------------------------------------------------
	local toastId = 0
	local function showMsg(str: string, color: Color3?, iconName: string?)
		toastId += 1
		local mine = toastId
		toastText.Text = str
		toastText.TextColor3 = color or WHITE
		toastIcon.ImageColor3 = color or GOLD
		setGlyph(toastIcon, iconName or "lock")
		toast.Visible = true
		task.delay(3, function()
			if toastId == mine then
				toast.Visible = false
			end
		end)
	end

	-- a modal card over a dimmed screen
	local function modal(w: number, h: number, z: number): (Frame, Frame)
		local over = new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = z, Active = true, Parent = root })
		tween(over, 0.25, { BackgroundTransparency = 0.45 })
		local card = glass({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 24), Size = UDim2.fromOffset(w, h), ZIndex = z + 1, BackgroundTransparency = 0.06, Parent = over }, 18)
		tween(card, 0.35, { Position = UDim2.fromScale(0.5, 0.5) })
		return over, card
	end

	local function celebrate(id: string)
		local over, card = modal(if compact then 420 else 460, if compact then 220 else 250, 100)
		confetti(over)
		Audio.cutUp(8, "NEW CAR")
		caption("NEW CAR", { TextColor3 = GOLD, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 0, fs(16)), ZIndex = 102, Parent = card })
		text({ Text = Cars.get(id).Name, FontFace = HEAVY, TextSize = 26, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(20, 44), Size = UDim2.new(1, -40, 0, fs(60)), ZIndex = 102, Parent = card })
		local driveNow = button("primary", "DRIVE IT NOW", "key", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 22, 1, -22), Size = UDim2.new(0.5, -28, 0, L.btnH), ZIndex = 102, Parent = card })
		local keep = button("secondary", "KEEP LOOKING", nil, { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -22, 1, -22), Size = UDim2.new(0.5, -28, 0, L.btnH), ZIndex = 102, Parent = card })
		for _, d in card:GetDescendants() do
			if d:IsA("GuiObject") then
				d.ZIndex = math.max(d.ZIndex, 102)
			end
		end
		-- (a moment before these work: the clicks that bought the car mustn't close this too)
		local readyAt = os.clock() + 0.8
		driveNow.b.Activated:Connect(function()
			if os.clock() < readyAt then
				return
			end
			local cb = s.callbacks
			DealerMenu.close()
			cb.drive(id)
		end)
		keep.b.Activated:Connect(function()
			if os.clock() >= readyAt then
				over:Destroy()
			end
		end)
	end

	-- (2026-11-07) the trailer: a card with a picture of it; it goes in the garage list
	buyTrailer = function()
		local T = Config.Towing.Trailer
		local over, card = modal(if compact then 440 else 500, if compact then 300 else 340, 90)
		caption("TRAILERS", { TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 16), Size = UDim2.new(1, 0, 0, fs(14)), ZIndex = 92, Parent = card })
		text({ Text = T.Name, FontFace = HEAVY, TextSize = 22, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(20, 32), Size = UDim2.new(1, -40, 0, fs(26)), ZIndex = 92, Parent = card })
		local photoH = if compact then 110 else 140
		local vp: ViewportFrame = new("ViewportFrame", { BackgroundTransparency = 1, Ambient = Color3.fromRGB(170, 172, 178), LightColor = Color3.new(1, 1, 1), LightDirection = Vector3.new(-1, -2, -0.6), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 58), Size = UDim2.new(1, -40, 0, photoH), ZIndex = 92, Parent = card })
		local world = Instance.new("WorldModel")
		world.Parent = vp
		local model = TrailerBuilder.build()
		model.Parent = world
		local cam = Instance.new("Camera")
		cam.FieldOfView = 26
		cam.CFrame = CFrame.lookAt(Vector3.new(-30, 15, 38), Vector3.new(0, 1.4, -2.4))
		cam.Parent = vp
		vp.CurrentCamera = cam
		local tail = 58 + photoH + 2
		local have = TrailerClient.owned == true
		text({ Text = if have then "IN YOUR GARAGE" else money(T.Price), FontFace = HEAVY, TextSize = 20, TextColor3 = if have then BLUE else GREEN, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(20, tail), Size = UDim2.new(1, -40, 0, fs(24)), ZIndex = 92, Parent = card })
		text({ Text = "Weighs " .. T.Kg .. " kg. Only cars tagged TOWS can pull it. Take it out from CARS.", FontFace = MEDIUM, TextSize = 13, TextColor3 = GREY, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(20, tail + fs(25)), Size = UDim2.new(1, -40, 0, fs(16)), ZIndex = 92, Parent = card })
		local cancel = button("secondary", if have then "CLOSE" else "CANCEL", nil, { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 22, 1, -18), Size = if have then UDim2.new(1, -44, 0, L.btnH) else UDim2.new(0.5, -28, 0, L.btnH), ZIndex = 92, Parent = card })
		cancel.b.Activated:Connect(function()
			over:Destroy()
		end)
		if not have then
			local yes = button("primary", "BUY", "tag", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -22, 1, -18), Size = UDim2.new(0.5, -28, 0, L.btnH), ZIndex = 92, Parent = card })
			yes.b.Activated:Connect(function()
				if s.busy then
					return
				end
				if (s.data.Cash or 0) < T.Price then
					showMsg("Not enough cash: " .. money(T.Price - (s.data.Cash or 0)) .. " more", RED, "tag")
					return
				end
				s.busy = true
				yes.set("...")
				TrailerClient.call("buy", nil, function(res: any)
					s.busy = false
					over:Destroy()
					if res and res.ok then
						s.data.Cash = (s.data.Cash or 0) - T.Price
						refreshAll()
						showMsg(T.Name .. " is yours: CARS > TRAILER", GREEN, "tag")
					else
						showMsg((res and res.message) or "Couldn't buy it", RED, "lock")
					end
				end)
			end)
		end
		for _, d in card:GetDescendants() do
			if d:IsA("GuiObject") then
				d.ZIndex = math.max(d.ZIndex, 92)
			end
		end
	end

	local function confirmBuy(id: string)
		local spec = Cars.get(id)
		local over, card = modal(if compact then 420 else 480, if compact then 210 else 236, 90)
		local colourWord = if s.colour and PALETTE[s.colour] then PALETTE[s.colour][1] .. " · " else ""
		caption("CONFIRM PURCHASE", { TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 20), Size = UDim2.new(1, 0, 0, fs(14)), ZIndex = 92, Parent = card })
		text({ Text = spec.Name, FontFace = HEAVY, TextSize = 22, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(20, 40), Size = UDim2.new(1, -40, 0, fs(28)), ZIndex = 92, Parent = card })
		text({ Text = colourWord .. money(priceOf(id)), FontFace = HEAVY, TextSize = 20, TextColor3 = GREEN, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(20, 40 + fs(30)), Size = UDim2.new(1, -40, 0, fs(24)), ZIndex = 92, Parent = card })
		text({ Text = "You have " .. money(s.data.Cash or 0), FontFace = MEDIUM, TextSize = 13, TextColor3 = GREY, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(20, 40 + fs(56)), Size = UDim2.new(1, -40, 0, fs(16)), ZIndex = 92, Parent = card })
		local cancel = button("secondary", "CANCEL", nil, { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 22, 1, -20), Size = UDim2.new(0.5, -28, 0, L.btnH), ZIndex = 92, Parent = card })
		local yes = button("primary", "BUY", "tag", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -22, 1, -20), Size = UDim2.new(0.5, -28, 0, L.btnH), ZIndex = 92, Parent = card })
		for _, d in card:GetDescendants() do
			if d:IsA("GuiObject") then
				d.ZIndex = math.max(d.ZIndex, 92)
			end
		end
		cancel.b.Activated:Connect(function()
			over:Destroy()
		end)
		yes.b.Activated:Connect(function()
			-- one purchase per click (the server also refuses a second one while it charges)
			if s.busy then
				return
			end
			s.busy = true
			yes.set("...")
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
				showMsg((res and res.message) or "Couldn't buy it", RED, "lock")
			end
		end)
	end

	buyBtn.b.Activated:Connect(function()
		local id = s.id
		if s.owned[id] then
			local cb = s.callbacks
			DealerMenu.close()
			cb.drive(id)
			return
		end
		local need = needFor(id)
		if levelNow() < need then
			showMsg("Class X: reach level " .. need .. " to buy this one", GOLD, "lock")
			return
		end
		if (s.data.Cash or 0) < priceOf(id) then
			showMsg("Not enough cash: " .. money(priceOf(id) - (s.data.Cash or 0)) .. " more", RED, "tag")
			return
		end
		confirmBuy(id)
	end)
	testBtn.b.Activated:Connect(function()
		local fn = s.callbacks.testDrive
		if not fn then
			return
		end
		local res = fn(s.id)
		if res and res.ok then
			DealerMenu.close()
		else
			showMsg((res and res.message) or "No test drive right now", RED, "wheel")
		end
	end)
	exitBtn.b.Activated:Connect(function()
		DealerMenu.close()
	end)

	-- keyboard: arrows step trims (left / right) and scroll the list (up / down); Q / E step brands;
	-- Esc leaves
	table.insert(conns, UserInputService.InputBegan:Connect(function(input, processed)
		local k = input.KeyCode
		-- (Esc reaches us marked as used by Roblox's own menu: leave either way. Not Backspace: the
		-- driving keys would see it too once the screen is shut, and put the car back on the road)
		if k == Enum.KeyCode.Escape then
			DealerMenu.close()
			return
		end
		if processed then
			return
		end
		if k == Enum.KeyCode.Left then
			stepTrim(-1)
		elseif k == Enum.KeyCode.Right then
			stepTrim(1)
		elseif k == Enum.KeyCode.Q then
			stepBrand(-1)
		elseif k == Enum.KeyCode.E then
			stepBrand(1)
		elseif k == Enum.KeyCode.Up then
			list.CanvasPosition = Vector2.new(0, math.max(0, list.CanvasPosition.Y - 90))
		elseif k == Enum.KeyCode.Down then
			list.CanvasPosition = Vector2.new(0, list.CanvasPosition.Y + 90)
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
	pcall(function()
		RunService:UnbindFromRenderStep("DealerCamera")
	end)
	if savedHold then
		Driving.cameraHold = savedHold[1]
		Driving.menuHold = savedHold[2]
		savedHold = nil
	end
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
	if not Cars.forSale(first) then
		first = Cars.StarterId -- (a retired car isn't in the dealer)
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

	-- (the driving camera lets go of the shot, and a car you sit in stays braked)
	savedHold = { Driving.cameraHold, Driving.menuHold }
	Driving.cameraHold = true
	Driving.menuHold = true
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
	-- one design size, scaled to the screen (small screens get the compact layout)
	-- (Studio test hook for Claude's screenshots: workspace attribute PreviewPhone draws the screen
	-- in a 667 x 375 box, the size of a small phone held sideways)
	local function viewport(): Vector2
		if RunService:IsStudio() and workspace:GetAttribute("PreviewPhone") then
			return Vector2.new(667, 375)
		end
		local v = camera.ViewportSize
		return Vector2.new(v.X, v.Y)
	end
	L = layoutFor(viewport())
	local root: Frame = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Parent = g })
	local scale = new("UIScale", { Parent = root })
	local function fit()
		local vp = viewport()
		local k = math.clamp(math.min(vp.X / L.W, vp.Y / L.H), 0.5, 1.4)
		scale.Scale = k
		uiScale = k
		root.Size = UDim2.fromOffset(vp.X / k, vp.Y / k)
	end
	fit()
	table.insert(conns, camera:GetPropertyChangedSignal("ViewportSize"):Connect(fit))
	-- a soft dark edge round the screen (the car stays bright in the middle)
	for _, side in { { 0, 0 }, { 0, 1 } } do
		new("Frame", {
			BackgroundColor3 = INK,
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0, side[2]),
			Position = UDim2.fromScale(0, side[2]),
			Size = UDim2.new(1, 0, 0.22, 0),
			Parent = root,
		}, {
			new("UIGradient", { Rotation = if side[2] == 0 then 90 else -90, Transparency = NumberSequence.new(0.35, 1) }),
		})
	end
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
	-- (bound last in the frame, so a driving or on-foot camera can't take the shot back)
	pcall(function()
		RunService:UnbindFromRenderStep("DealerCamera")
	end)
	RunService:BindToRenderStep("DealerCamera", Enum.RenderPriority.Last.Value, function(dt)
		idle += dt
		if not dragging and idle > 1.5 then
			yaw += dt * 0.1 -- slowly round, like a turntable
		end
		-- (the car sits a little low in the frame: the trim bar is over it)
		local target = STAGE + Vector3.new(0, 2.6, 0)
		local d = dist * zoomK * (if L.compact then 1.1 else 1)
		local offset = Vector3.new(math.sin(yaw) * math.cos(pitch), math.sin(pitch), math.cos(yaw) * math.cos(pitch)) * d
		camera.CameraType = Enum.CameraType.Scriptable
		camera.FieldOfView = 40
		camera.CFrame = CFrame.lookAt(target + offset, target)
		camera.Focus = CFrame.new(target)
	end)
end

return DealerMenu
