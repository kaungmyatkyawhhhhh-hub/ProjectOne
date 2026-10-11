--[[
	DashGauges (client)
	Live instrument cluster drawn on the "DashCluster" panel that CarSkin puts
	behind an imported car's steering wheel. Two looks:
	  * Lambo:  one big round rev counter in the middle (needle, red line from
	            7, digital speed and gear inside), slim bar gauges either side
	  * Modern: Toyota-style screen: power arc on the left, big digital speed
	            and gear in the middle, analog speedometer with a needle on the right
	build() returns an update(mph, gear, rpm) function; rpm is 0..1.
]]

local DashGauges = {}

type Update = (mph: number, gear: string, rpm: number) -> ()

local WHITE = Color3.fromRGB(240, 244, 255)
local DIM = Color3.fromRGB(120, 128, 150)
local RED = Color3.fromRGB(255, 40, 60)
local BLUE = Color3.fromRGB(40, 150, 255)
local AMBER = Color3.fromRGB(255, 196, 40)

local function new(className: string, props: { [string]: any }, parent: Instance?): any
	local o = Instance.new(className)
	for k, v in props do
		(o :: any)[k] = v
	end
	o.Parent = parent
	return o
end

local function text(parent: Instance, t: string, pos: UDim2, size: UDim2, color: Color3, font: Enum.Font?): TextLabel
	return new("TextLabel", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = pos,
		Size = size,
		Text = t,
		TextColor3 = color,
		TextScaled = true,
		Font = font or Enum.Font.GothamBold,
	}, parent)
end

-- A round dial in a square frame: ticks, numbers and a needle. Returns a setter (0..1).
local function dial(parent: Instance, center: UDim2, size: number, labels: { string }, redFrom: number?, needleColor: Color3, a0: number, a1: number): (number) -> ()
	local box = new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = center,
		Size = UDim2.fromScale(size, size),
	}, parent)
	new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, box)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, new("Frame", {
		BackgroundColor3 = Color3.fromRGB(10, 12, 18),
		Size = UDim2.fromScale(1, 1),
	}, box))
	local steps = #labels - 1
	local minorPer = 4
	for i = 0, steps * minorPer do
		local f = i / (steps * minorPer)
		local major = i % minorPer == 0
		local holder = new("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			Rotation = a0 + (a1 - a0) * f,
		}, box)
		local red = redFrom and f >= redFrom
		new("Frame", {
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.03),
			Size = UDim2.fromScale(if major then 0.022 else 0.012, if major then 0.09 else 0.05),
			BackgroundColor3 = if red then RED else (if major then WHITE else DIM),
		}, holder)
		if major then
			local ang = math.rad(a0 + (a1 - a0) * f)
			local rr = 0.34
			text(box, labels[i // minorPer + 1], UDim2.fromScale(0.5 + math.sin(ang) * rr, 0.5 - math.cos(ang) * rr), UDim2.fromScale(0.14, 0.11), if red then RED else WHITE, Enum.Font.GothamBold)
		end
	end
	local needle = new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		Rotation = a0,
		ZIndex = 3,
	}, box)
	new("Frame", {
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.08),
		Size = UDim2.fromScale(0.018, 0.44),
		BackgroundColor3 = needleColor,
		ZIndex = 3,
	}, needle)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.08, 0.08),
		BackgroundColor3 = Color3.fromRGB(30, 32, 40),
		ZIndex = 4,
	}, box))
	local shown = 0
	return function(v: number)
		shown += (math.clamp(v, 0, 1) - shown) * 0.35 -- a little needle lag
		needle.Rotation = a0 + (a1 - a0) * shown
	end
end

-- a thin vertical bar gauge (fuel / temperature look)
local function bar(parent: Instance, pos: UDim2, color: Color3, label: string, value: number)
	local back = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = pos,
		Size = UDim2.fromScale(0.025, 0.55),
		BackgroundColor3 = Color3.fromRGB(30, 34, 44),
		BorderSizePixel = 0,
	}, parent)
	new("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.fromScale(1, value),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
	}, back)
	text(parent, label, pos + UDim2.fromScale(0, 0.36), UDim2.fromScale(0.08, 0.07), DIM, Enum.Font.Gotham)
end

local function clock(): string
	local t = os.date("*t")
	return string.format("%02d:%02d", t.hour, t.min)
end

local function lambo(gui: SurfaceGui): Update
	local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(4, 5, 8), BorderSizePixel = 0 }, gui)
	-- side panels
	local clockText = text(bg, clock(), UDim2.fromScale(0.13, 0.42), UDim2.fromScale(0.16, 0.16), WHITE, Enum.Font.GothamBold)
	text(bg, "FM 97.9", UDim2.fromScale(0.13, 0.28), UDim2.fromScale(0.13, 0.08), DIM, Enum.Font.Gotham)
	text(bg, "74.5 °F", UDim2.fromScale(0.13, 0.6), UDim2.fromScale(0.12, 0.08), DIM, Enum.Font.Gotham)
	bar(bg, UDim2.fromScale(0.3, 0.5), BLUE, "FUEL", 0.8)
	bar(bg, UDim2.fromScale(0.7, 0.5), WHITE, "OIL", 0.55)
	text(bg, "CL", UDim2.fromScale(0.87, 0.45), UDim2.fromScale(0.08, 0.16), AMBER, Enum.Font.GothamBlack)
	text(bg, "STRADA", UDim2.fromScale(0.87, 0.65), UDim2.fromScale(0.12, 0.08), AMBER, Enum.Font.GothamBold)
	-- the big rev counter
	local setRpm = dial(bg, UDim2.fromScale(0.5, 0.5), 0.98, { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" }, 7 / 9, Color3.fromRGB(255, 70, 90), -135, 135)
	local speed = text(bg, "0", UDim2.fromScale(0.535, 0.6), UDim2.fromScale(0.09, 0.15), WHITE, Enum.Font.GothamBlack)
	text(bg, "mph", UDim2.fromScale(0.535, 0.7), UDim2.fromScale(0.05, 0.06), DIM, Enum.Font.Gotham)
	local gear = text(bg, "N", UDim2.fromScale(0.465, 0.62), UDim2.fromScale(0.045, 0.14), AMBER, Enum.Font.GothamBlack)
	local last = 0
	return function(mph: number, g: string, rpm: number)
		setRpm(rpm)
		speed.Text = tostring(math.floor(mph + 0.5))
		gear.Text = g
		if os.clock() - last > 5 then
			last = os.clock()
			clockText.Text = clock()
		end
	end
end

local function modern(gui: SurfaceGui): Update
	local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(3, 6, 12), BorderSizePixel = 0 }, gui)
	new("UIGradient", {
		Color = ColorSequence.new(Color3.fromRGB(20, 40, 80), Color3.fromRGB(6, 10, 20)),
		Rotation = 90,
	}, bg)
	-- left: power arc (segments light up with the revs)
	local segs: { Frame } = {}
	local box = new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.2, 0.55),
		Size = UDim2.fromScale(0.85, 0.85),
	}, bg)
	new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, box)
	for i = 0, 23 do
		local holder = new("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			Rotation = -120 + 240 * i / 23,
		}, box)
		table.insert(segs, new("Frame", {
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.02),
			Size = UDim2.fromScale(0.05, 0.1),
			BackgroundColor3 = Color3.fromRGB(30, 40, 60),
		}, holder))
	end
	text(box, "POWER", UDim2.fromScale(0.5, 0.42), UDim2.fromScale(0.4, 0.1), DIM, Enum.Font.Gotham)
	local powerPct = text(box, "0", UDim2.fromScale(0.5, 0.56), UDim2.fromScale(0.36, 0.18), WHITE, Enum.Font.GothamBold)
	text(box, "ECO", UDim2.fromScale(0.2, 0.86), UDim2.fromScale(0.2, 0.08), Color3.fromRGB(80, 220, 140), Enum.Font.Gotham)
	-- middle: digital speed + gear + clock
	local clockText = text(bg, clock(), UDim2.fromScale(0.5, 0.1), UDim2.fromScale(0.12, 0.1), DIM, Enum.Font.Gotham)
	local speed = text(bg, "0", UDim2.fromScale(0.5, 0.38), UDim2.fromScale(0.18, 0.3), WHITE, Enum.Font.GothamBold)
	text(bg, "mph", UDim2.fromScale(0.5, 0.56), UDim2.fromScale(0.08, 0.08), DIM, Enum.Font.Gotham)
	local gear = text(bg, "N", UDim2.fromScale(0.5, 0.74), UDim2.fromScale(0.07, 0.16), BLUE, Enum.Font.GothamBlack)
	-- right: analog speedometer, 0-180 mph
	local setSpeed = dial(bg, UDim2.fromScale(0.8, 0.55), 0.88, { "0", "20", "40", "60", "80", "100", "120", "140", "160", "180" }, nil, RED, -125, 125)
	local last = 0
	return function(mph: number, g: string, rpm: number)
		setSpeed(mph / 180)
		speed.Text = tostring(math.floor(mph + 0.5))
		gear.Text = g
		local lit = math.floor(rpm * #segs + 0.5)
		for i, seg in segs do
			seg.BackgroundColor3 = if i <= lit then (if i > #segs * 0.8 then RED else BLUE) else Color3.fromRGB(30, 40, 60)
		end
		powerPct.Text = tostring(math.floor(rpm * 100))
		if os.clock() - last > 5 then
			last = os.clock()
			clockText.Text = clock()
		end
	end
end

-- Ferrari 458: big yellow rev counter in the middle (0-10, red from 9, gear in a dark
-- wedge), left screen with outside temperature and a fuel bar, right screen with speed and clock
local FERRARI_YELLOW = Color3.fromRGB(246, 196, 0)
local function ferrari(gui: SurfaceGui): Update
	local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(8, 8, 10), BorderSizePixel = 0 }, gui)
	-- side screens
	local function screen(x: number): Frame
		local f = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(x, 0.58),
			Size = UDim2.fromScale(0.27, 0.62),
			BackgroundColor3 = Color3.fromRGB(26, 30, 38),
			BorderSizePixel = 0,
		}, bg)
		new("UICorner", { CornerRadius = UDim.new(0.08, 0) }, f)
		new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(70, 78, 92), Color3.fromRGB(20, 22, 28)), Rotation = 90 }, f)
		return f
	end
	local left = screen(0.15)
	text(left, "Ambient Temperature", UDim2.fromScale(0.42, 0.16), UDim2.fromScale(0.7, 0.1), DIM, Enum.Font.Gotham)
	text(left, "21.6°C", UDim2.fromScale(0.4, 0.38), UDim2.fromScale(0.65, 0.26), WHITE, Enum.Font.GothamMedium)
	text(left, "1/2", UDim2.fromScale(0.5, 0.62), UDim2.fromScale(0.12, 0.08), DIM, Enum.Font.Gotham)
	text(left, "1", UDim2.fromScale(0.9, 0.62), UDim2.fromScale(0.06, 0.08), DIM, Enum.Font.Gotham)
	for i = 0, 9 do
		new("Frame", {
			Position = UDim2.fromScale(0.1 + i * 0.081, 0.72),
			Size = UDim2.fromScale(0.065, 0.16),
			BackgroundColor3 = Color3.fromRGB(255, 92, 20),
			BorderSizePixel = 0,
		}, left)
	end
	local right = screen(0.85)
	local speed = text(right, "0", UDim2.fromScale(0.45, 0.42), UDim2.fromScale(0.5, 0.36), WHITE, Enum.Font.GothamMedium)
	text(right, "mph", UDim2.fromScale(0.85, 0.48), UDim2.fromScale(0.16, 0.1), DIM, Enum.Font.Gotham)
	new("Frame", { Position = UDim2.fromScale(0.08, 0.64), Size = UDim2.fromScale(0.84, 0.012), BackgroundColor3 = DIM, BorderSizePixel = 0 }, right)
	local pill = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.82),
		Size = UDim2.fromScale(0.42, 0.16),
		BackgroundColor3 = Color3.fromRGB(90, 96, 108),
		BorderSizePixel = 0,
	}, right)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, pill)
	local clockText = text(pill, clock(), UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.8, 0.8), WHITE, Enum.Font.Gotham)
	-- the yellow rev counter
	local box = new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
	}, bg)
	new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, box)
	local rim = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(40, 40, 44), BorderSizePixel = 0 }, box)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, rim)
	local face = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.94, 0.94),
		BackgroundColor3 = FERRARI_YELLOW,
		BorderSizePixel = 0,
	}, box)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, face)
	new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(255, 220, 60), Color3.fromRGB(214, 160, 0)), Rotation = 60 }, face)
	-- 0..10 from 7 o'clock round to 4 o'clock
	local a0, a1 = -150, 110
	for i = 0, 10 do
		local ang = math.rad(a0 + (a1 - a0) * i / 10)
		text(box, tostring(i), UDim2.fromScale(0.5 + math.sin(ang) * 0.36, 0.5 - math.cos(ang) * 0.36), UDim2.fromScale(0.12, 0.11), if i >= 9 then Color3.fromRGB(220, 20, 20) else WHITE, Enum.Font.GothamBold)
	end
	text(box, "RPM", UDim2.fromScale(0.66, 0.53), UDim2.fromScale(0.12, 0.06), Color3.fromRGB(60, 50, 20), Enum.Font.GothamBold)
	text(box, "x1000", UDim2.fromScale(0.66, 0.59), UDim2.fromScale(0.1, 0.045), Color3.fromRGB(60, 50, 20), Enum.Font.Gotham)
	-- gear in a dark wedge, lower right
	local wedge = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.66, 0.74),
		Size = UDim2.fromScale(0.26, 0.24),
		BackgroundColor3 = Color3.fromRGB(28, 20, 10),
		BorderSizePixel = 0,
		Rotation = 8,
	}, box)
	new("UICorner", { CornerRadius = UDim.new(0.15, 0) }, wedge)
	local gear = text(wedge, "N", UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.6, 0.8), Color3.fromRGB(255, 120, 0), Enum.Font.GothamBold)
	-- needle (dark red) with a black hub
	local needle = new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		Rotation = a0,
		ZIndex = 3,
	}, box)
	new("Frame", {
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.1),
		Size = UDim2.fromScale(0.014, 0.42),
		BackgroundColor3 = Color3.fromRGB(150, 20, 24),
		ZIndex = 3,
	}, needle)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.09, 0.09),
		BackgroundColor3 = Color3.fromRGB(12, 12, 14),
		ZIndex = 4,
	}, box))
	local shown, last = 0, 0
	return function(mph: number, g: string, rpm: number)
		shown += (math.clamp(rpm, 0, 1) - shown) * 0.35
		needle.Rotation = a0 + (a1 - a0) * shown
		speed.Text = tostring(math.floor(mph + 0.5))
		gear.Text = g
		if os.clock() - last > 5 then
			last = os.clock()
			clockText.Text = clock()
		end
	end
end

function DashGauges.build(panel: BasePart): Update
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Gauges"
	gui.Face = Enum.NormalId.Back
	gui.CanvasSize = Vector2.new(math.floor(panel.Size.X / panel.Size.Y * 300), 300)
	gui.LightInfluence = 0
	gui.Brightness = 1.4
	gui.MaxDistance = 60
	gui.Parent = panel
	local style = panel:GetAttribute("Style")
	local update = if style == "Lambo" then lambo(gui) elseif style == "Ferrari" then ferrari(gui) else modern(gui)
	-- start-up: the screens fade up and the needles sweep to the end and back, like a real car
	local started = os.clock()
	local SWEEP = 1.6
	return function(mph: number, g: string, rpm: number)
		local t = os.clock() - started
		if t < SWEEP then
			gui.Brightness = 1.4 * math.clamp(t / 0.5, 0, 1)
			local sweep = math.sin(math.clamp(t / SWEEP, 0, 1) * math.pi)
			update(math.max(mph, sweep * 180), g, math.max(rpm, sweep))
		else
			gui.Brightness = 1.4
			update(mph, g, rpm)
		end
	end
end

return DashGauges
