--[[
	DashGauges (client)
	Live instrument cluster drawn on the "DashCluster" panel that CarSkin puts
	behind an imported car's steering wheel. Looks (the panel's Style attribute), e.g.:
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
local function dial(parent: Instance, center: UDim2, size: number, labels: { string }, redFrom: number?, needleColor: Color3, a0: number, a1: number, face: Color3?, faceless: boolean?, needleWidth: number?): (number) -> ()
	local box = new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = center,
		Size = UDim2.fromScale(size, size),
	}, parent)
	new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, box)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, new("Frame", {
		BackgroundColor3 = face or Color3.fromRGB(10, 12, 18),
		BackgroundTransparency = if faceless then 1 else 0,
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
			local num = text(box, labels[i // minorPer + 1], UDim2.fromScale(0.5 + math.sin(ang) * rr, 0.5 - math.cos(ang) * rr), UDim2.fromScale(0.17, 0.14), if red then RED else WHITE, Enum.Font.GothamBlack)
			num.TextStrokeTransparency = 0.35 -- dark outline keeps the numbers readable on any face
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
		Size = UDim2.fromScale(needleWidth or 0.018, 0.44),
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

-- a round bezel (chrome or coloured ring) to sit a dial in
local function bezel(parent: Instance, center: UDim2, size: number, ringColor: Color3, thickness: number?)
	local box = new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = center,
		Size = UDim2.fromScale(size, size),
	}, parent)
	new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, box)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, box)
	new("UIStroke", { Color = ringColor, Thickness = thickness or 5 }, box)
end

local function numbers(from: number, to: number, step: number): { string }
	local out = {}
	for v = from, to, step do
		table.insert(out, tostring(v))
	end
	return out
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
local FERRARI_YELLOW = Color3.fromRGB(196, 146, 0) -- deep yellow, not glaring at night
-- speedDial (599 GTO): an analog speedometer with its own needle on the left instead of the
-- temperature screen
local function ferrari(gui: SurfaceGui, speedDial: boolean?): Update
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
	local setSpeedDial: ((number) -> ())? = nil
	if speedDial then
		bezel(bg, UDim2.fromScale(0.165, 0.55), 0.8, Color3.fromRGB(150, 150, 156), 4)
		setSpeedDial = dial(bg, UDim2.fromScale(0.165, 0.55), 0.76, numbers(0, 220, 20), nil, Color3.fromRGB(230, 30, 30), -135, 135, Color3.fromRGB(14, 14, 16), nil, 0.012)
		text(bg, "MPH", UDim2.fromScale(0.165, 0.72), UDim2.fromScale(0.03, 0.045), DIM, Enum.Font.Gotham)
	else
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
	new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(210, 160, 10), Color3.fromRGB(160, 112, 0)), Rotation = 60 }, face)
	-- 0..10 from 7 o'clock round to 4 o'clock
	local a0, a1 = -150, 110
	for i = 0, 10 do
		local ang = math.rad(a0 + (a1 - a0) * i / 10)
		local num = text(box, tostring(i), UDim2.fromScale(0.5 + math.sin(ang) * 0.36, 0.5 - math.cos(ang) * 0.36), UDim2.fromScale(0.13, 0.12), if i >= 9 then Color3.fromRGB(230, 20, 20) else WHITE, Enum.Font.GothamBlack)
		num.TextStrokeColor3 = Color3.fromRGB(20, 14, 0) -- outlined so they read on the yellow
		num.TextStrokeTransparency = 0.1
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
		if setSpeedDial then
			setSpeedDial(mph / 220)
		end
		speed.Text = tostring(math.floor(mph + 0.5))
		gear.Text = g
		if os.clock() - last > 5 then
			last = os.clock()
			clockText.Text = clock()
		end
	end
end

local function aventador(gui: SurfaceGui, dialOnly: boolean?): Update
	-- matches the real Aventador LP700-4 cluster in Sport mode (owner's Forza reference)
	local NAVY = Color3.fromRGB(12, 18, 30)
	local YELLOW = Color3.fromRGB(240, 210, 40)
	local SEG_OFF = Color3.fromRGB(34, 46, 66)
	local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(6, 9, 15), BackgroundTransparency = if dialOnly then 1 else 0, BorderSizePixel = 0 }, gui)
	local clockText: TextLabel? = nil
	-- the model's own cluster already shows the side screens: then only the round dial is drawn
	if not dialOnly then
		-- blue-grey frame with screws
		local frame = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.98, 0.92),
			BackgroundTransparency = 1,
		}, bg)
		new("UICorner", { CornerRadius = UDim.new(0.22, 0) }, frame)
		new("UIStroke", { Color = Color3.fromRGB(118, 136, 160), Thickness = 6 }, frame)
		for _, xy in { { 0.03, 0.5 }, { 0.2, 0.1 }, { 0.8, 0.1 }, { 0.97, 0.5 }, { 0.2, 0.9 }, { 0.8, 0.9 } } do
			local sc = new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(xy[1], xy[2]),
				Size = UDim2.fromScale(0.012, 0.035),
				BackgroundColor3 = Color3.fromRGB(20, 24, 30),
			}, bg)
			new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, sc)
		end

		-- far left: clock and outside temperature between thin yellow lines
		for _, y in { 0.36, 0.5, 0.64 } do
			new("Frame", { Position = UDim2.fromScale(0.05, y), Size = UDim2.fromScale(0.13, 0.006), BackgroundColor3 = Color3.fromRGB(150, 128, 40), BorderSizePixel = 0 }, bg)
		end
		clockText = text(bg, clock(), UDim2.fromScale(0.115, 0.43), UDim2.fromScale(0.09, 0.11), WHITE, Enum.Font.GothamMedium)
		text(bg, "15.7 °C", UDim2.fromScale(0.115, 0.57), UDim2.fromScale(0.08, 0.08), Color3.fromRGB(200, 206, 216), Enum.Font.Gotham)

		-- a side gauge: a short column of slanted segments (yellow, red at the end), its scale,
		-- name and a red needle at the current value
		local function side(x: number, y: number, flip: boolean, labels: { string }, name: string, value: number, redTop: boolean)
			local holder = new("Frame", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(x, y),
				Size = UDim2.fromScale(0.09, 0.34),
			}, bg)
			local n = 8
			for i = 1, n do
				local f = (i - 1) / (n - 1)
				local red = if redTop then i >= n - 1 else i <= 2
				new("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(if flip then 0.32 + f * 0.12 else 0.68 - f * 0.12, 0.95 - f * 0.88),
					Size = UDim2.fromScale(0.16, 0.085),
					Rotation = if flip then -20 else 20,
					BackgroundColor3 = if red then Color3.fromRGB(220, 40, 40) else YELLOW,
					BorderSizePixel = 0,
				}, holder)
			end
			for i, l in labels do
				local f = (i - 1) / math.max(#labels - 1, 1)
				text(holder, l, UDim2.fromScale(if flip then 0.72 - f * 0.1 else 0.28 + f * 0.1, 0.1 + f * 0.8), UDim2.fromScale(0.36, 0.13), WHITE, Enum.Font.GothamBold)
			end
			text(holder, name, UDim2.fromScale(0.5, if redTop then -0.08 else 1.1), UDim2.fromScale(0.9, 0.11), Color3.fromRGB(200, 206, 216), Enum.Font.Gotham)
			new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.95 - value * 0.88),
				Size = UDim2.fromScale(0.75, 0.025),
				Rotation = if flip then 12 else -12,
				BackgroundColor3 = Color3.fromRGB(230, 30, 40),
				BorderSizePixel = 0,
			}, holder)
		end
		side(0.29, 0.3, false, { "100", "50", "0" }, "Benzina", 0.85, true)
		side(0.29, 0.7, false, { "130", "90", "50" }, "Temp. Acqua", 0.5, true)
		side(0.71, 0.3, true, { "10", "5", "0" }, "Press. Olio", 0.55, true)
		side(0.71, 0.7, true, { "170", "130", "50" }, "Temp. Olio", 0.5, true)

		-- far right: thin yellow line and the gold shield
		new("Frame", { Position = UDim2.fromScale(0.82, 0.36), Size = UDim2.fromScale(0.13, 0.006), BackgroundColor3 = Color3.fromRGB(150, 128, 40), BorderSizePixel = 0 }, bg)
		local shield = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.885, 0.56),
			Size = UDim2.fromScale(0.045, 0.24),
			BackgroundColor3 = Color3.fromRGB(30, 26, 12),
			BorderSizePixel = 0,
		}, bg)
		new("UICorner", { CornerRadius = UDim.new(0.35, 0) }, shield)
		new("UIStroke", { Color = Color3.fromRGB(214, 176, 70), Thickness = 2 }, shield)
		text(shield, "L", UDim2.fromScale(0.5, 0.55), UDim2.fromScale(0.7, 0.55), Color3.fromRGB(214, 176, 70), Enum.Font.GothamBlack)
	end

	-- the rev counter
	local box = new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
	}, bg)
	new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, box)
	local silver = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(176, 182, 192), BorderSizePixel = 0 }, box)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, silver)
	local face = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.95, 0.95),
		BackgroundColor3 = NAVY,
		BorderSizePixel = 0,
	}, box)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, face)
	-- 0 at the bottom, 6 at the top, 9 at about 3 o'clock
	local a0, a1 = -165, 105
	local segs: { Frame } = {}
	local SEGS = 54
	for i = 0, SEGS - 1 do
		local f = i / (SEGS - 1)
		local h = new("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			Rotation = a0 + (a1 - a0) * f,
		}, box)
		table.insert(segs, new("Frame", {
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.035),
			Size = UDim2.fromScale(0.03, 0.06),
			BackgroundColor3 = SEG_OFF,
		}, h))
	end
	for i = 0, 9 do
		local ang = math.rad(a0 + (a1 - a0) * i / 9)
		text(box, tostring(i), UDim2.fromScale(0.5 + math.sin(ang) * 0.33, 0.5 - math.cos(ang) * 0.33), UDim2.fromScale(0.12, 0.13), if i == 9 then Color3.fromRGB(230, 30, 40) else WHITE, Enum.Font.GothamBlack)
	end
	-- inner blue ring, shown on the lower half only, and a thin yellow ring inside it
	local blue = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.56, 0.56), BackgroundTransparency = 1 }, box)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, blue)
	local blueStroke = new("UIStroke", { Color = Color3.fromRGB(50, 130, 220), Thickness = 7 }, blue)
	new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.4, 1), NumberSequenceKeypoint.new(0.55, 0), NumberSequenceKeypoint.new(1, 0) }) }, blueStroke)
	local ylw = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.44, 0.44), BackgroundTransparency = 1 }, box)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, ylw)
	new("UIStroke", { Color = YELLOW, Thickness = 1.5, Transparency = 0.2 }, ylw)
	text(box, "ESC", UDim2.fromScale(0.52, 0.33), UDim2.fromScale(0.08, 0.05), YELLOW, Enum.Font.GothamBold)
	text(box, "SPORT", UDim2.fromScale(0.52, 0.38), UDim2.fromScale(0.12, 0.05), YELLOW, Enum.Font.GothamBold)
	text(box, "/min x 1000", UDim2.fromScale(0.5, 0.43), UDim2.fromScale(0.16, 0.035), WHITE, Enum.Font.Gotham)
	-- digital speed (km/h) in a white box
	local spdBox = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.66, 0.6),
		Size = UDim2.fromScale(0.26, 0.1),
		BackgroundColor3 = Color3.fromRGB(226, 230, 236),
		BorderSizePixel = 0,
		Rotation = -3,
		ZIndex = 5,
	}, box)
	local speed = text(spdBox, "0", UDim2.fromScale(0.72, 0.5), UDim2.fromScale(0.5, 1), Color3.fromRGB(14, 16, 22), Enum.Font.GothamBlack)
	speed.ZIndex = 6
	speed.TextXAlignment = Enum.TextXAlignment.Right
	local unit = text(box, "km/h", UDim2.fromScale(0.73, 0.68), UDim2.fromScale(0.08, 0.035), WHITE, Enum.Font.Gotham)
	unit.ZIndex = 5
	-- gear strip: R N 1-7, the current one lit yellow
	local gears = { "R", "N", "1", "2", "3", "4", "5", "6", "7" }
	local gearLabels: { [string]: TextLabel } = {}
	local strip = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.56, 0.76),
		Size = UDim2.fromScale(0.42, 0.06),
		BackgroundColor3 = Color3.fromRGB(40, 90, 150),
		BorderSizePixel = 0,
		ZIndex = 5,
	}, box)
	for i, gname in gears do
		local l = text(strip, gname, UDim2.fromScale((i - 0.5) / #gears, 0.5), UDim2.fromScale(1 / #gears, 0.9), Color3.fromRGB(200, 210, 226), Enum.Font.GothamBold)
		l.ZIndex = 6
		gearLabels[gname] = l
	end
	local mode = text(box, "SPORT", UDim2.fromScale(0.58, 0.84), UDim2.fromScale(0.14, 0.05), YELLOW, Enum.Font.GothamBold)
	mode.ZIndex = 5
	local odo = text(box, "001126.3 km", UDim2.fromScale(0.58, 0.9), UDim2.fromScale(0.18, 0.04), WHITE, Enum.Font.Gotham)
	odo.ZIndex = 5
	-- red needle, silver hub
	local needle = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), Rotation = a0, ZIndex = 7 }, box)
	new("Frame", { BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.12), Size = UDim2.fromScale(0.012, 0.4), BackgroundColor3 = Color3.fromRGB(230, 30, 40), ZIndex = 7 }, needle)
	local hub = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.07, 0.07), BackgroundColor3 = NAVY, ZIndex = 8 }, box)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, hub)
	new("UIStroke", { Color = Color3.fromRGB(190, 196, 206), Thickness = 3 }, hub)

	local shown, last, lastGear = 0, 0, ""
	return function(mph: number, g: string, rpm: number)
		shown += (math.clamp(rpm, 0, 1) - shown) * 0.35
		needle.Rotation = a0 + (a1 - a0) * shown
		local lit = math.floor(shown * SEGS + 0.5)
		for i, seg in segs do
			seg.BackgroundColor3 = if i <= lit then YELLOW else SEG_OFF
		end
		speed.Text = tostring(math.floor(mph * 1.609 + 0.5))
		if g ~= lastGear then
			if gearLabels[lastGear] then
				gearLabels[lastGear].TextColor3 = Color3.fromRGB(200, 210, 226)
			end
			if gearLabels[g] then
				gearLabels[g].TextColor3 = YELLOW
			end
			lastGear = g
		end
		if os.clock() - last > 5 then
			last = os.clock()
			if clockText then
				clockText.Text = clock()
			end
		end
	end
end


-- BMW G20 330i "Live Cockpit": open arcs, speedometer left (clockwise from the bottom),
-- rev counter right (anticlockwise), big digital speed in the middle, a strip along the bottom
local function bmwLive(gui: SurfaceGui): Update
	local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(4, 5, 8), BorderSizePixel = 0 }, gui)
	local setSpeed = dial(bg, UDim2.fromScale(0.23, 0.48), 0.95, numbers(0, 200, 20), nil, Color3.fromRGB(230, 232, 238), 165, 390, nil, true)
	local setRpm = dial(bg, UDim2.fromScale(0.77, 0.48), 0.95, numbers(0, 8, 1), 6.5 / 8, Color3.fromRGB(230, 232, 238), 195, -30, nil, true)
	local speed = text(bg, "0", UDim2.fromScale(0.37, 0.45), UDim2.fromScale(0.08, 0.16), WHITE, Enum.Font.GothamBold)
	text(bg, "mph", UDim2.fromScale(0.42, 0.47), UDim2.fromScale(0.04, 0.06), DIM, Enum.Font.Gotham)
	local kmh = text(bg, "0", UDim2.fromScale(0.375, 0.6), UDim2.fromScale(0.05, 0.08), WHITE, Enum.Font.GothamBold)
	text(bg, "km/h", UDim2.fromScale(0.42, 0.6), UDim2.fromScale(0.04, 0.05), DIM, Enum.Font.Gotham)
	-- torque / power bars inside the rev counter
	local function bar2(x: number, label: string): Frame
		local back = new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(x, 0.7), Size = UDim2.fromScale(0.012, 0.36), BackgroundColor3 = Color3.fromRGB(40, 44, 54), BorderSizePixel = 0 }, bg)
		local fill = new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, 0), BackgroundColor3 = Color3.fromRGB(235, 70, 40), BorderSizePixel = 0 }, back)
		text(bg, label, UDim2.fromScale(x, 0.75), UDim2.fromScale(0.04, 0.05), DIM, Enum.Font.Gotham)
		return fill
	end
	local torque = bar2(0.7, "lb-ft")
	local power = bar2(0.74, "hp")
	-- bottom strip
	new("Frame", { Position = UDim2.fromScale(0.2, 0.86), Size = UDim2.fromScale(0.6, 0.004), BackgroundColor3 = Color3.fromRGB(110, 114, 124), BorderSizePixel = 0 }, bg)
	text(bg, "187 mi", UDim2.fromScale(0.2, 0.92), UDim2.fromScale(0.07, 0.07), WHITE, Enum.Font.GothamBold)
	text(bg, "Ampere Ave", UDim2.fromScale(0.5, 0.93), UDim2.fromScale(0.12, 0.07), WHITE, Enum.Font.Gotham)
	local gear = text(bg, "P", UDim2.fromScale(0.73, 0.93), UDim2.fromScale(0.03, 0.08), WHITE, Enum.Font.GothamBold)
	text(bg, "+48 °F", UDim2.fromScale(0.82, 0.93), UDim2.fromScale(0.06, 0.06), WHITE, Enum.Font.Gotham)
	return function(mph: number, g: string, rpm: number)
		setSpeed(mph / 200)
		setRpm(rpm)
		speed.Text = tostring(math.floor(mph + 0.5))
		kmh.Text = tostring(math.floor(mph * 1.609 + 0.5))
		gear.Text = if g == "N" then "N" elseif g == "R" then "R" else "D" .. g
		torque.Size = UDim2.fromScale(1, math.clamp(rpm * 1.1, 0, 1))
		power.Size = UDim2.fromScale(1, math.clamp(rpm, 0, 1))
	end
end

-- classic BMW (E60 M5 / E63 M6 / E92 M3): two round dials, grey faces, white numbers, red needles
-- grey: the M5 / M6 / X6 panel in grey instead of black (owner's wish)
local function bmwClassic(gui: SurfaceGui, grey: boolean?): Update
	local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = if grey then Color3.fromRGB(92, 94, 100) else Color3.fromRGB(8, 8, 10), BorderSizePixel = 0 }, gui)
	if grey then
		new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(128, 130, 136), Color3.fromRGB(78, 80, 86)), Rotation = 90 }, bg)
	end
	local face = Color3.fromRGB(34, 36, 40)
	bezel(bg, UDim2.fromScale(0.3, 0.5), 0.98, Color3.fromRGB(170, 174, 182), 4)
	bezel(bg, UDim2.fromScale(0.7, 0.5), 0.98, Color3.fromRGB(170, 174, 182), 4)
	local setSpeed = dial(bg, UDim2.fromScale(0.3, 0.5), 0.94, numbers(0, 200, 20), nil, Color3.fromRGB(240, 40, 30), -135, 135, face)
	local setRpm = dial(bg, UDim2.fromScale(0.7, 0.5), 0.94, numbers(0, 9, 1), 7.5 / 9, Color3.fromRGB(240, 40, 30), -135, 135, face)
	text(bg, "MPH", UDim2.fromScale(0.3, 0.7), UDim2.fromScale(0.04, 0.05), DIM, Enum.Font.Gotham)
	text(bg, "1/min x1000", UDim2.fromScale(0.7, 0.7), UDim2.fromScale(0.07, 0.04), DIM, Enum.Font.Gotham)
	local screen = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.72), Size = UDim2.fromScale(0.09, 0.2), BackgroundColor3 = Color3.fromRGB(14, 6, 4), BorderSizePixel = 0 }, bg)
	local gear = text(screen, "N", UDim2.fromScale(0.5, 0.38), UDim2.fromScale(0.6, 0.5), Color3.fromRGB(255, 120, 40), Enum.Font.GothamBold)
	local speed = text(screen, "0", UDim2.fromScale(0.5, 0.8), UDim2.fromScale(0.8, 0.3), Color3.fromRGB(255, 120, 40), Enum.Font.Gotham)
	return function(mph: number, g: string, rpm: number)
		setSpeed(mph / 200)
		setRpm(rpm)
		gear.Text = g
		speed.Text = tostring(math.floor(mph + 0.5))
	end
end

-- Mercedes-AMG CLA 45: two chrome-ringed dials on carbon, red needles, small fuel / temperature
-- dials, a middle screen with P R N D M, temperatures, km/h and the clock.
-- biturbo (CLS 63 S, G 63 of the 2010s): rev counter on the left with "V8 BITURBO" under it,
-- speedometer on the right
local function amg(gui: SurfaceGui, biturbo: boolean?, topMph: number?): Update
	local top = topMph or 200
	local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(6, 6, 8), BorderSizePixel = 0 }, gui)
	local carbon = Color3.fromRGB(22, 22, 26)
	local needle = Color3.fromRGB(235, 40, 60)
	local sx, rx = if biturbo then 0.75 else 0.25, if biturbo then 0.25 else 0.75
	bezel(bg, UDim2.fromScale(0.25, 0.5), 1, Color3.fromRGB(190, 194, 202), 6)
	bezel(bg, UDim2.fromScale(0.75, 0.5), 1, Color3.fromRGB(190, 194, 202), 6)
	local setSpeed = dial(bg, UDim2.fromScale(sx, 0.5), 0.95, numbers(0, top, 20), nil, needle, -135, 135, carbon)
	local setRpm = dial(bg, UDim2.fromScale(rx, 0.5), 0.95, numbers(0, 8, 1), 6.5 / 8, needle, -135, 135, carbon)
	dial(bg, UDim2.fromScale(sx + 0.05, 0.72), 0.3, { "0", "1/2", "1" }, nil, needle, -120, 0)(0.75)
	dial(bg, UDim2.fromScale(rx + 0.05, 0.72), 0.3, { "40", "80", "120" }, nil, needle, -120, 0)(0.55)
	text(bg, "mph", UDim2.fromScale(sx + 0.07, 0.6), UDim2.fromScale(0.03, 0.04), DIM, Enum.Font.Gotham)
	text(bg, "AMG", UDim2.fromScale(rx + 0.02, 0.3), UDim2.fromScale(0.05, 0.05), WHITE, Enum.Font.GothamBlack)
	if biturbo then
		text(bg, "V8 BITURBO", UDim2.fromScale(rx, 0.86), UDim2.fromScale(0.09, 0.045), WHITE, Enum.Font.GothamBold)
		text(bg, "1/min x1000", UDim2.fromScale(rx, 0.38), UDim2.fromScale(0.06, 0.035), DIM, Enum.Font.Gotham)
	end
	-- the middle screen
	local pr = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.2), Size = UDim2.fromScale(0.16, 0.12), BackgroundColor3 = Color3.fromRGB(10, 10, 12), BorderSizePixel = 0 }, bg)
	new("UIStroke", { Color = Color3.fromRGB(160, 164, 172), Thickness = 2 }, pr)
	local letters: { [string]: TextLabel } = {}
	for i, l in { "P", "R", "N", "D", "M" } do
		letters[l] = text(pr, l, UDim2.fromScale(0.1 + (i - 1) * 0.2, 0.5), UDim2.fromScale(0.18, 0.8), if l == "M" then Color3.fromRGB(230, 40, 40) else DIM, Enum.Font.GothamBold)
	end
	local screen = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.3), Size = UDim2.fromScale(0.15, 0.62), BackgroundColor3 = Color3.fromRGB(4, 4, 6), BorderSizePixel = 0 }, bg)
	local speed = text(screen, "0mph", UDim2.fromScale(0.3, 0.1), UDim2.fromScale(0.45, 0.1), WHITE, Enum.Font.GothamBold)
	local gearBig = text(screen, "P", UDim2.fromScale(0.7, 0.1), UDim2.fromScale(0.25, 0.15), WHITE, Enum.Font.GothamBold)
	for i, t in { "97°C", "94°C", "76°C" } do
		text(screen, t, UDim2.fromScale(0.6, 0.28 + i * 0.1), UDim2.fromScale(0.5, 0.08), WHITE, Enum.Font.GothamBold)
	end
	local kmh = text(screen, "0km/h", UDim2.fromScale(0.27, 0.9), UDim2.fromScale(0.45, 0.08), WHITE, Enum.Font.Gotham)
	local clockText = text(screen, clock(), UDim2.fromScale(0.75, 0.9), UDim2.fromScale(0.4, 0.08), WHITE, Enum.Font.Gotham)
	local last, lastLetter = 0, ""
	return function(mph: number, g: string, rpm: number)
		setSpeed(mph / top)
		setRpm(rpm)
		speed.Text = tostring(math.floor(mph + 0.5)) .. "mph"
		kmh.Text = tostring(math.floor(mph * 1.609 + 0.5)) .. "km/h"
		gearBig.Text = if tonumber(g) then "D" .. g else g
		local letter = if g == "R" then "R" elseif g == "N" then "N" else "D"
		if letter ~= lastLetter then
			if letters[lastLetter] then
				letters[lastLetter].TextColor3 = DIM
			end
			letters[letter].TextColor3 = WHITE
			lastLetter = letter
		end
		if os.clock() - last > 5 then
			last = os.clock()
			clockText.Text = clock()
		end
	end
end

-- Toyota Supra MK4 (TRD): fuel + temperature left, big 0-10 rev counter in the middle with
-- the end in orange and red, speedometer right with "Supra" in script; white on black, red needles
local function supraTrd(gui: SurfaceGui): Update
	local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(4, 4, 6), BorderSizePixel = 0 }, gui)
	local needle = Color3.fromRGB(240, 40, 30)
	dial(bg, UDim2.fromScale(0.17, 0.38), 0.6, { "E", "", "F" }, nil, needle, -150, -30, nil, true)(0.8)
	dial(bg, UDim2.fromScale(0.17, 0.72), 0.5, { "C", "", "H" }, nil, needle, -150, -30, nil, true)(0.45)
	text(bg, "TRD", UDim2.fromScale(0.21, 0.5), UDim2.fromScale(0.05, 0.06), WHITE, Enum.Font.GothamBlack)
	local setRpm = dial(bg, UDim2.fromScale(0.5, 0.5), 1, numbers(0, 10, 1), 0.7, needle, -180 + 10, 170, nil)
	text(bg, "x1000RPM", UDim2.fromScale(0.5, 0.6), UDim2.fromScale(0.07, 0.04), WHITE, Enum.Font.Gotham)
	text(bg, "TRD", UDim2.fromScale(0.52, 0.72), UDim2.fromScale(0.05, 0.06), WHITE, Enum.Font.GothamBlack)
	local setSpeed = dial(bg, UDim2.fromScale(0.83, 0.5), 0.95, numbers(0, 200, 20), 0.85, needle, -125, 125, nil)
	text(bg, "MPH", UDim2.fromScale(0.85, 0.62), UDim2.fromScale(0.03, 0.04), WHITE, Enum.Font.Gotham)
	text(bg, "Supra", UDim2.fromScale(0.82, 0.74), UDim2.fromScale(0.07, 0.07), WHITE, Enum.Font.Arcade)
	return function(mph: number, _g: string, rpm: number)
		setRpm(rpm)
		setSpeed(mph / 200)
	end
end

-- Toyota (Camry, Crown, Land Cruiser, Alphard): power meter left (CHARGE / ECO / POWER) with a
-- small temperature gauge, middle screen with the gear and odometer, km/h speedometer right with
-- a small fuel gauge; chrome rings lit blue, red needles
local function toyota(gui: SurfaceGui): Update
	local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(8, 9, 12), BorderSizePixel = 0 }, gui)
	local needle = Color3.fromRGB(240, 40, 30)
	for _, x in { 0.24, 0.76 } do
		bezel(bg, UDim2.fromScale(x, 0.52), 0.98, Color3.fromRGB(190, 196, 206), 4)
		bezel(bg, UDim2.fromScale(x, 0.52), 0.92, Color3.fromRGB(40, 110, 220), 3)
	end
	local setPower = dial(bg, UDim2.fromScale(0.24, 0.52), 0.88, { "CHG", "", "ECO", "", "", "PWR" }, 0.85, needle, -100, 80)
	dial(bg, UDim2.fromScale(0.24, 0.8), 0.25, { "C", "H" }, nil, needle, -60, 60, nil, true)(0.5)
	local setSpeed = dial(bg, UDim2.fromScale(0.76, 0.52), 0.88, numbers(0, 180, 20), nil, needle, -120, 120)
	dial(bg, UDim2.fromScale(0.76, 0.8), 0.25, { "E", "F" }, nil, needle, -60, 60, nil, true)(0.7)
	text(bg, "km/h", UDim2.fromScale(0.76, 0.36), UDim2.fromScale(0.04, 0.05), DIM, Enum.Font.Gotham)
	-- middle screen
	local screen = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromScale(0.13, 0.78), BackgroundColor3 = Color3.fromRGB(10, 12, 20), BorderSizePixel = 0 }, bg)
	new("UIStroke", { Color = Color3.fromRGB(120, 126, 140), Thickness = 2 }, screen)
	text(screen, "READY", UDim2.fromScale(0.5, 0.12), UDim2.fromScale(0.6, 0.08), Color3.fromRGB(80, 220, 120), Enum.Font.GothamBold)
	local gear = text(screen, "P", UDim2.fromScale(0.5, 0.55), UDim2.fromScale(0.5, 0.25), WHITE, Enum.Font.GothamBold)
	text(screen, "ODO 99137km", UDim2.fromScale(0.5, 0.9), UDim2.fromScale(0.9, 0.07), Color3.fromRGB(120, 170, 255), Enum.Font.Gotham)
	return function(mph: number, g: string, rpm: number)
		setPower(rpm)
		setSpeed(mph * 1.609 / 180)
		gear.Text = if tonumber(g) then "D" else g
	end
end

-- a clock / extra hand that turns round a dial's centre (fraction 0..1 of a full turn)
local function hand(box: Frame, length: number, width: number, color: Color3, z: number): Frame
	local holder = new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		ZIndex = z,
	}, box)
	new("Frame", {
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(width, length),
		BackgroundColor3 = color,
		ZIndex = z,
	}, holder)
	return holder
end

local function squareBox(parent: Instance, center: UDim2, size: number): Frame
	local box = new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = center,
		Size = UDim2.fromScale(size, size),
	}, parent)
	new("UIAspectRatioConstraint", { AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }, box)
	return box
end

-- Mercedes E-Class W212: five round tubes in one hood, chrome rings, black faces, white numbers,
-- red needles: coolant temperature, rev counter, big speedometer (screen inside), analog clock, fuel
local function w212(gui: SurfaceGui): Update
	local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(5, 5, 7), BorderSizePixel = 0 }, gui)
	local chrome = Color3.fromRGB(196, 200, 208)
	local face = Color3.fromRGB(12, 12, 15)
	local needle = Color3.fromRGB(240, 50, 40)
	for _, d in { { 0.07, 0.58, 0.48 }, { 0.245, 0.5, 0.8 }, { 0.5, 0.5, 0.96 }, { 0.755, 0.5, 0.8 }, { 0.93, 0.58, 0.48 } } do
		bezel(bg, UDim2.fromScale(d[1], d[2]), d[3], chrome, if d[3] > 0.9 then 6 else 4)
	end
	dial(bg, UDim2.fromScale(0.07, 0.58), 0.45, { "40", "", "120" }, 0.85, needle, -60, 60, face)(0.5)
	text(bg, "°C", UDim2.fromScale(0.07, 0.72), UDim2.fromScale(0.03, 0.06), DIM, Enum.Font.Gotham)
	local setRpm = dial(bg, UDim2.fromScale(0.245, 0.5), 0.76, numbers(0, 7, 1), 6 / 7, needle, -130, 130, face)
	text(bg, "1/min x1000", UDim2.fromScale(0.245, 0.68), UDim2.fromScale(0.06, 0.04), DIM, Enum.Font.Gotham)
	local setSpeed = dial(bg, UDim2.fromScale(0.5, 0.5), 0.92, numbers(0, 160, 20), nil, needle, -135, 135, face)
	-- the screen inside the speedometer: gear and digital speed
	local screen = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.72), Size = UDim2.fromScale(0.07, 0.2), BackgroundColor3 = Color3.fromRGB(26, 28, 34), BorderSizePixel = 0 }, bg)
	new("UICorner", { CornerRadius = UDim.new(0.12, 0) }, screen)
	local gear = text(screen, "P", UDim2.fromScale(0.5, 0.32), UDim2.fromScale(0.7, 0.45), WHITE, Enum.Font.GothamBold)
	local speed = text(screen, "0 mph", UDim2.fromScale(0.5, 0.78), UDim2.fromScale(0.9, 0.3), WHITE, Enum.Font.Gotham)
	-- analog clock
	local clockBox = squareBox(bg, UDim2.fromScale(0.755, 0.5), 0.76)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = face, BorderSizePixel = 0 }, clockBox))
	for i = 1, 12 do
		local ang = math.rad(i * 30)
		text(clockBox, tostring(i), UDim2.fromScale(0.5 + math.sin(ang) * 0.36, 0.5 - math.cos(ang) * 0.36), UDim2.fromScale(0.14, 0.12), WHITE, Enum.Font.GothamBold)
	end
	local hourHand = hand(clockBox, 0.22, 0.035, WHITE, 3)
	local minuteHand = hand(clockBox, 0.36, 0.022, WHITE, 3)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.07, 0.07), BackgroundColor3 = chrome, ZIndex = 4 }, clockBox))
	dial(bg, UDim2.fromScale(0.93, 0.58), 0.45, { "0", "1/2", "1" }, nil, needle, -60, 60, face)(0.7)
	text(bg, "FUEL", UDim2.fromScale(0.93, 0.72), UDim2.fromScale(0.035, 0.05), DIM, Enum.Font.Gotham)
	local last = -10
	return function(mph: number, g: string, rpm: number)
		setRpm(rpm)
		setSpeed(mph / 160)
		gear.Text = if tonumber(g) then "D" else g
		speed.Text = tostring(math.floor(mph + 0.5)) .. " mph"
		if os.clock() - last > 5 then
			last = os.clock()
			local t = os.date("*t")
			hourHand.Rotation = (t.hour % 12 + t.min / 60) * 30
			minuteHand.Rotation = t.min * 6
		end
	end
end

-- Mercedes-AMG E-Class W213 (E 43 / E 400 AMG Line) widescreen cockpit, "Sport" look: one wide
-- glass screen, digital rev counter left and speedometer right as rings with red light that
-- fills with the value, white numbers, the gear, digital speed and drive mode in the middle
local function w213(gui: SurfaceGui): Update
	local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(2, 3, 6), BorderSizePixel = 0 }, gui)
	new("UICorner", { CornerRadius = UDim.new(0.06, 0) }, bg)
	new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(24, 28, 40), Color3.fromRGB(2, 3, 6)), Rotation = 90 }, bg)
	local RINGRED = Color3.fromRGB(255, 36, 52)
	local OFF = Color3.fromRGB(46, 50, 62)
	local function ringGauge(x: number, labels: { string }, redFrom: number?): (number) -> ()
		local box = squareBox(bg, UDim2.fromScale(x, 0.53), 0.9)
		local segs: { Frame } = {}
		local a0, a1, n = -135, 135, 48
		for i = 0, n - 1 do
			local h = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), Rotation = a0 + (a1 - a0) * i / (n - 1) }, box)
			table.insert(segs, new("Frame", { BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.02), Size = UDim2.fromScale(0.035, 0.05), BackgroundColor3 = OFF }, h))
		end
		local setNeedle = dial(box, UDim2.fromScale(0.5, 0.5), 0.86, labels, redFrom, RINGRED, a0, a1, nil, true)
		return function(v: number)
			setNeedle(v)
			local lit = math.floor(math.clamp(v, 0, 1) * n + 0.5)
			for i, seg in segs do
				seg.BackgroundColor3 = if i <= lit then RINGRED else OFF
			end
		end
	end
	local setRpm = ringGauge(0.2, numbers(0, 7, 1), 6.2 / 7)
	local setSpeed = ringGauge(0.8, numbers(0, 160, 20), nil)
	text(bg, "x1000/min", UDim2.fromScale(0.2, 0.72), UDim2.fromScale(0.06, 0.04), DIM, Enum.Font.Gotham)
	text(bg, "mph", UDim2.fromScale(0.8, 0.72), UDim2.fromScale(0.03, 0.04), DIM, Enum.Font.Gotham)
	-- middle
	local clockText = text(bg, clock(), UDim2.fromScale(0.42, 0.08), UDim2.fromScale(0.06, 0.07), WHITE, Enum.Font.Gotham)
	text(bg, "+18.5 °C", UDim2.fromScale(0.58, 0.08), UDim2.fromScale(0.06, 0.06), WHITE, Enum.Font.Gotham)
	local speed = text(bg, "0", UDim2.fromScale(0.5, 0.4), UDim2.fromScale(0.12, 0.26), WHITE, Enum.Font.GothamMedium)
	text(bg, "mph", UDim2.fromScale(0.5, 0.56), UDim2.fromScale(0.04, 0.06), DIM, Enum.Font.Gotham)
	local gear = text(bg, "P", UDim2.fromScale(0.5, 0.74), UDim2.fromScale(0.05, 0.13), RINGRED, Enum.Font.GothamBold)
	text(bg, "S+", UDim2.fromScale(0.5, 0.9), UDim2.fromScale(0.03, 0.08), WHITE, Enum.Font.GothamBold)
	local last = 0
	return function(mph: number, g: string, rpm: number)
		setRpm(rpm)
		setSpeed(mph / 160)
		speed.Text = tostring(math.floor(mph + 0.5))
		gear.Text = if tonumber(g) then "D" .. g else g
		if os.clock() - last > 5 then
			last = os.clock()
			clockText.Text = clock()
		end
	end
end

-- Lamborghini Gallardo LP560-4 / LP570-4: seven round dials on black, white numbers, orange
-- needles: speedometer left and rev counter right (big, silver rings), the trip screen between
-- them, two small dials either side (fuel and water temperature, oil temperature and pressure)
-- and a small voltmeter on top
local function gallardo(gui: SurfaceGui): Update
	local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(4, 4, 6), BorderSizePixel = 0 }, gui)
	local silver = Color3.fromRGB(176, 182, 192)
	local face = Color3.fromRGB(10, 10, 12)
	local needle = Color3.fromRGB(255, 110, 20)
	bezel(bg, UDim2.fromScale(0.31, 0.52), 0.86, silver, 5)
	bezel(bg, UDim2.fromScale(0.69, 0.52), 0.86, silver, 5)
	local setSpeed = dial(bg, UDim2.fromScale(0.31, 0.52), 0.82, numbers(0, 220, 20), nil, needle, -135, 135, face)
	local setRpm = dial(bg, UDim2.fromScale(0.69, 0.52), 0.82, numbers(0, 10, 1), 8 / 10, needle, -135, 135, face)
	text(bg, "mph", UDim2.fromScale(0.31, 0.7), UDim2.fromScale(0.03, 0.045), DIM, Enum.Font.Gotham)
	text(bg, "RPM x1000", UDim2.fromScale(0.69, 0.7), UDim2.fromScale(0.06, 0.045), DIM, Enum.Font.Gotham)
	for _, d in { { 0.08, 0.3, "FUEL", { "0", "1/2", "1" }, 0.75 }, { 0.08, 0.74, "°C", { "50", "", "130" }, 0.45 }, { 0.92, 0.3, "OIL °C", { "50", "", "150" }, 0.5 }, { 0.92, 0.74, "OIL bar", { "0", "5", "10" }, 0.4 }, { 0.5, 0.2, "V", { "8", "", "16" }, 0.55 } } do
		local x, y = d[1] :: number, d[2] :: number
		local sz = if x == 0.5 then 0.32 else 0.38
		bezel(bg, UDim2.fromScale(x, y), sz, silver, 3)
		dial(bg, UDim2.fromScale(x, y), sz - 0.02, d[4] :: { string }, nil, needle, -90, 90, face)(d[5] :: number)
		text(bg, d[3] :: string, UDim2.fromScale(x, y + 0.13), UDim2.fromScale(0.04, 0.045), DIM, Enum.Font.Gotham)
	end
	-- trip screen between the big dials
	local screen = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.66), Size = UDim2.fromScale(0.1, 0.4), BackgroundColor3 = Color3.fromRGB(14, 16, 20), BorderSizePixel = 0 }, bg)
	new("UIStroke", { Color = Color3.fromRGB(80, 84, 92), Thickness = 2 }, screen)
	local gear = text(screen, "N", UDim2.fromScale(0.5, 0.3), UDim2.fromScale(0.5, 0.35), needle, Enum.Font.GothamBold)
	local speed = text(screen, "0", UDim2.fromScale(0.5, 0.65), UDim2.fromScale(0.7, 0.22), WHITE, Enum.Font.GothamBold)
	text(screen, "mph", UDim2.fromScale(0.5, 0.86), UDim2.fromScale(0.4, 0.12), DIM, Enum.Font.Gotham)
	return function(mph: number, g: string, rpm: number)
		setSpeed(mph / 220)
		setRpm(rpm)
		gear.Text = g
		speed.Text = tostring(math.floor(mph + 0.5))
	end
end

-- Aston Martin DB9 / V8 Vantage: two big dials on graphite with chrome rings, speedometer left
-- turning clockwise and the rev counter right turning the other way (mirror image), white
-- needles, a small screen between them with the gear, speed, fuel and temperature
local function aston(gui: SurfaceGui): Update
	local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(8, 8, 10), BorderSizePixel = 0 }, gui)
	local chrome = Color3.fromRGB(200, 204, 212)
	local face = Color3.fromRGB(34, 36, 40)
	local needle = Color3.fromRGB(245, 245, 250)
	bezel(bg, UDim2.fromScale(0.27, 0.5), 0.98, chrome, 5)
	bezel(bg, UDim2.fromScale(0.73, 0.5), 0.98, chrome, 5)
	local setSpeed = dial(bg, UDim2.fromScale(0.27, 0.5), 0.94, numbers(0, 200, 20), nil, needle, -135, 135, face)
	local setRpm = dial(bg, UDim2.fromScale(0.73, 0.5), 0.94, numbers(0, 8, 1), 6.8 / 8, needle, 135, -135, face)
	text(bg, "MPH", UDim2.fromScale(0.27, 0.7), UDim2.fromScale(0.035, 0.045), DIM, Enum.Font.Gotham)
	text(bg, "RPM x1000", UDim2.fromScale(0.73, 0.7), UDim2.fromScale(0.06, 0.045), DIM, Enum.Font.Gotham)
	local screen = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.fromScale(0.13, 0.62), BackgroundColor3 = Color3.fromRGB(4, 4, 6), BorderSizePixel = 0 }, bg)
	new("UIStroke", { Color = Color3.fromRGB(90, 94, 102), Thickness = 2 }, screen)
	local gear = text(screen, "N", UDim2.fromScale(0.5, 0.22), UDim2.fromScale(0.4, 0.25), WHITE, Enum.Font.GothamBold)
	local speed = text(screen, "0 mph", UDim2.fromScale(0.5, 0.48), UDim2.fromScale(0.8, 0.14), WHITE, Enum.Font.Gotham)
	for _, b in { { 0.3, 0.75 }, { 0.7, 0.5 } } do
		local back = new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(b[1], 0.86), Size = UDim2.fromScale(0.06, 0.26), BackgroundColor3 = Color3.fromRGB(40, 42, 48), BorderSizePixel = 0 }, screen)
		new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, b[2]), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, back)
	end
	text(screen, "FUEL", UDim2.fromScale(0.3, 0.93), UDim2.fromScale(0.35, 0.08), DIM, Enum.Font.Gotham)
	text(screen, "TEMP", UDim2.fromScale(0.7, 0.93), UDim2.fromScale(0.35, 0.08), DIM, Enum.Font.Gotham)
	return function(mph: number, g: string, rpm: number)
		setSpeed(mph / 200)
		setRpm(rpm)
		gear.Text = g
		speed.Text = tostring(math.floor(mph + 0.5)) .. " mph"
	end
end

-- a car outline seen from above / side / behind (Urus screen pictures)
local function carIcon(parent: Instance, pos: UDim2, size: UDim2, rot: number)
	local body = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = size, BackgroundColor3 = Color3.fromRGB(70, 74, 84), BorderSizePixel = 0, Rotation = rot }, parent)
	new("UICorner", { CornerRadius = UDim.new(0.3, 0) }, body)
	new("UIStroke", { Color = Color3.fromRGB(220, 224, 232), Thickness = 2 }, body)
	return body
end

-- Lamborghini Urus (owner's photo): dark screen, round rev counter in the middle with a segmented
-- ring that lights up and goes red at the top, "STRADA", a big gear letter and digital speed in it;
-- the car from above on the left, pitch and roll pictures on the right, radio / range / clock /
-- temperature / boost along the edges
local function urus(gui: SurfaceGui): Update
	local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(10, 11, 14), BorderSizePixel = 0 }, gui)
	new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(30, 32, 38), Color3.fromRGB(8, 8, 10)), Rotation = 90 }, bg)
	local RED = Color3.fromRGB(230, 40, 40)
	local OFF = Color3.fromRGB(70, 74, 84)
	-- top edge
	text(bg, "98.3FM", UDim2.fromScale(0.12, 0.08), UDim2.fromScale(0.08, 0.07), WHITE, Enum.Font.GothamMedium)
	text(bg, "40 km", UDim2.fromScale(0.9, 0.08), UDim2.fromScale(0.06, 0.07), WHITE, Enum.Font.GothamMedium)
	-- left: the car from above
	local top = carIcon(bg, UDim2.fromScale(0.15, 0.5), UDim2.fromScale(0.06, 0.48), 0)
	for _, xy in { { -0.1, 0.18 }, { 1.1, 0.18 }, { -0.1, 0.8 }, { 1.1, 0.8 } } do
		new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(xy[1], xy[2]), Size = UDim2.fromScale(0.25, 0.14), BackgroundColor3 = RED, BorderSizePixel = 0 }, top)
	end
	-- the rev counter
	local box = squareBox(bg, UDim2.fromScale(0.5, 0.52), 0.92)
	local a0, a1, n = -140, 140, 60
	local segs: { Frame } = {}
	for i = 0, n - 1 do
		local f = i / (n - 1)
		local h = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), Rotation = a0 + (a1 - a0) * f }, box)
		table.insert(segs, new("Frame", { BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.02), Size = UDim2.fromScale(0.025, 0.07), BackgroundColor3 = if f > 0.78 then Color3.fromRGB(110, 30, 30) else OFF }, h))
	end
	for i = 0, 9 do
		local ang = math.rad(a0 + (a1 - a0) * i / 9)
		text(box, tostring(i), UDim2.fromScale(0.5 + math.sin(ang) * 0.36, 0.5 - math.cos(ang) * 0.36), UDim2.fromScale(0.1, 0.1), if i >= 8 then RED else WHITE, Enum.Font.GothamBold)
	end
	text(box, "STRADA", UDim2.fromScale(0.5, 0.3), UDim2.fromScale(0.26, 0.07), WHITE, Enum.Font.GothamBold)
	local gearBox = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.26, 0.28), BackgroundColor3 = Color3.fromRGB(30, 32, 38), BorderSizePixel = 0 }, box)
	new("UICorner", { CornerRadius = UDim.new(0.15, 0) }, gearBox)
	local gear = text(gearBox, "P", UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.8, 0.9), WHITE, Enum.Font.GothamBlack)
	local speed = text(box, "0", UDim2.fromScale(0.5, 0.75), UDim2.fromScale(0.2, 0.12), WHITE, Enum.Font.GothamBold)
	text(box, "km/h", UDim2.fromScale(0.5, 0.84), UDim2.fromScale(0.1, 0.05), DIM, Enum.Font.Gotham)
	-- right: pitch and roll
	carIcon(bg, UDim2.fromScale(0.78, 0.45), UDim2.fromScale(0.08, 0.14), 2)
	carIcon(bg, UDim2.fromScale(0.9, 0.45), UDim2.fromScale(0.045, 0.16), -1)
	text(bg, "2°", UDim2.fromScale(0.78, 0.62), UDim2.fromScale(0.03, 0.07), WHITE, Enum.Font.GothamMedium)
	text(bg, "1°", UDim2.fromScale(0.9, 0.62), UDim2.fromScale(0.03, 0.07), WHITE, Enum.Font.GothamMedium)
	-- bottom edge
	local clockText = text(bg, clock(), UDim2.fromScale(0.42, 0.95), UDim2.fromScale(0.05, 0.06), WHITE, Enum.Font.Gotham)
	text(bg, "+16.5°C", UDim2.fromScale(0.58, 0.95), UDim2.fromScale(0.05, 0.06), WHITE, Enum.Font.Gotham)
	local boostBack = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.85, 0.86), Size = UDim2.fromScale(0.16, 0.035), BackgroundColor3 = OFF, BorderSizePixel = 0 }, bg)
	local boost = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, boostBack)
	text(bg, "BOOST", UDim2.fromScale(0.85, 0.93), UDim2.fromScale(0.05, 0.05), DIM, Enum.Font.Gotham)
	local shown, last = 0, 0
	return function(mph: number, g: string, rpm: number)
		shown += (math.clamp(rpm, 0, 1) - shown) * 0.35
		local lit = math.floor(shown * n + 0.5)
		for i, seg in segs do
			local f = (i - 1) / (n - 1)
			seg.BackgroundColor3 = if i <= lit then (if f > 0.78 then RED else WHITE) else (if f > 0.78 then Color3.fromRGB(110, 30, 30) else OFF)
		end
		gear.Text = g
		speed.Text = tostring(math.floor(mph * 1.609 + 0.5))
		boost.Size = UDim2.fromScale(math.clamp(rpm * 1.1 - 0.1, 0, 1), 1)
		if os.clock() - last > 5 then
			last = os.clock()
			clockText.Text = clock()
		end
	end
end

-- two big dials with four small ones between them (2 x 2) and a small screen under those:
-- Murcielago LP640 (rev counter left) and Corvette C6 (speedometer left)
local function twinWithSmalls(gui: SurfaceGui, rpmLeft: boolean, rpmTop: number, redFrom: number, needle: Color3, ring: Color3, smalls: { { string } }): Update
	local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(5, 5, 7), BorderSizePixel = 0 }, gui)
	local face = Color3.fromRGB(10, 10, 12)
	local lx, rx = 0.23, 0.77
	bezel(bg, UDim2.fromScale(lx, 0.5), 0.98, ring, 5)
	bezel(bg, UDim2.fromScale(rx, 0.5), 0.98, ring, 5)
	local rpmX, spdX = if rpmLeft then lx else rx, if rpmLeft then rx else lx
	local setRpm = dial(bg, UDim2.fromScale(rpmX, 0.5), 0.94, numbers(0, rpmTop, 1), redFrom / rpmTop, needle, -135, 135, face)
	local setSpeed = dial(bg, UDim2.fromScale(spdX, 0.5), 0.94, numbers(0, 200, 20), nil, needle, -135, 135, face)
	text(bg, "RPM x1000", UDim2.fromScale(rpmX, 0.7), UDim2.fromScale(0.06, 0.045), DIM, Enum.Font.Gotham)
	text(bg, "MPH", UDim2.fromScale(spdX, 0.7), UDim2.fromScale(0.035, 0.045), DIM, Enum.Font.Gotham)
	for i, sm in smalls do
		local x = if i % 2 == 1 then 0.452 else 0.548
		local y = if i <= 2 then 0.22 else 0.52
		bezel(bg, UDim2.fromScale(x, y), 0.26, ring, 2)
		dial(bg, UDim2.fromScale(x, y), 0.24, { sm[2], "", sm[3] }, nil, needle, -90, 90, face)(0.4 + 0.1 * i)
		text(bg, sm[1], UDim2.fromScale(x, y + 0.1), UDim2.fromScale(0.035, 0.04), DIM, Enum.Font.Gotham)
	end
	local screen = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.84), Size = UDim2.fromScale(0.12, 0.2), BackgroundColor3 = Color3.fromRGB(12, 14, 18), BorderSizePixel = 0 }, bg)
	new("UIStroke", { Color = Color3.fromRGB(80, 84, 92), Thickness = 2 }, screen)
	local gear = text(screen, "N", UDim2.fromScale(0.2, 0.5), UDim2.fromScale(0.25, 0.8), needle, Enum.Font.GothamBold)
	local speed = text(screen, "0 mph", UDim2.fromScale(0.65, 0.5), UDim2.fromScale(0.6, 0.6), WHITE, Enum.Font.Gotham)
	return function(mph: number, g: string, rpm: number)
		setRpm(rpm)
		setSpeed(mph / 200)
		gear.Text = g
		speed.Text = tostring(math.floor(mph + 0.5)) .. " mph"
	end
end

-- Corvette C7 (Sport theme): an 8-inch screen in the middle with one big round rev counter whose
-- ring glows yellow, then amber, then red, digital speed and gear inside; an analog speedometer
-- on the left and analog fuel and temperature gauges on the right
local function c7(gui: SurfaceGui): Update
	local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(5, 5, 7), BorderSizePixel = 0 }, gui)
	local needle = Color3.fromRGB(240, 60, 40)
	local face = Color3.fromRGB(12, 12, 14)
	local silver = Color3.fromRGB(170, 176, 186)
	bezel(bg, UDim2.fromScale(0.145, 0.52), 0.8, silver, 4)
	local setSpeed = dial(bg, UDim2.fromScale(0.145, 0.52), 0.76, numbers(0, 200, 20), nil, needle, -135, 135, face)
	text(bg, "MPH", UDim2.fromScale(0.145, 0.7), UDim2.fromScale(0.03, 0.045), DIM, Enum.Font.Gotham)
	for _, d in { { 0.86, 0.3, "FUEL", { "E", "", "F" }, 0.7 }, { 0.86, 0.74, "TEMP", { "C", "", "H" }, 0.45 } } do
		local x, y = d[1] :: number, d[2] :: number
		bezel(bg, UDim2.fromScale(x, y), 0.4, silver, 3)
		dial(bg, UDim2.fromScale(x, y), 0.38, d[4] :: { string }, nil, needle, -90, 90, face)(d[5] :: number)
		text(bg, d[3] :: string, UDim2.fromScale(x, y + 0.12), UDim2.fromScale(0.035, 0.045), DIM, Enum.Font.Gotham)
	end
	-- the screen
	local screen = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.44, 0.96), BackgroundColor3 = Color3.fromRGB(8, 10, 16), BorderSizePixel = 0 }, bg)
	new("UICorner", { CornerRadius = UDim.new(0.05, 0) }, screen)
	local box = squareBox(screen, UDim2.fromScale(0.5, 0.52), 0.94)
	local a0, a1, n = -135, 135, 56
	local segs: { Frame } = {}
	for i = 0, n - 1 do
		local h = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), Rotation = a0 + (a1 - a0) * i / (n - 1) }, box)
		table.insert(segs, new("Frame", { BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.02), Size = UDim2.fromScale(0.03, 0.06), BackgroundColor3 = Color3.fromRGB(40, 44, 54) }, h))
	end
	for i = 0, 8 do
		local ang = math.rad(a0 + (a1 - a0) * i / 8)
		text(box, tostring(i), UDim2.fromScale(0.5 + math.sin(ang) * 0.36, 0.5 - math.cos(ang) * 0.36), UDim2.fromScale(0.1, 0.1), if i >= 7 then Color3.fromRGB(240, 50, 40) else WHITE, Enum.Font.GothamBold)
	end
	local speed = text(box, "0", UDim2.fromScale(0.5, 0.46), UDim2.fromScale(0.34, 0.24), WHITE, Enum.Font.GothamBold)
	text(box, "MPH", UDim2.fromScale(0.5, 0.6), UDim2.fromScale(0.1, 0.06), DIM, Enum.Font.Gotham)
	local gear = text(box, "N", UDim2.fromScale(0.5, 0.76), UDim2.fromScale(0.12, 0.13), Color3.fromRGB(255, 200, 40), Enum.Font.GothamBlack)
	local shown = 0
	return function(mph: number, g: string, rpm: number)
		setSpeed(mph / 200)
		shown += (math.clamp(rpm, 0, 1) - shown) * 0.35
		local lit = math.floor(shown * n + 0.5)
		-- yellow to amber to red as the revs rise
		local col = if shown > 0.85 then Color3.fromRGB(240, 40, 30) elseif shown > 0.65 then Color3.fromRGB(255, 140, 20) else Color3.fromRGB(255, 210, 40)
		for i, seg in segs do
			seg.BackgroundColor3 = if i <= lit then col else Color3.fromRGB(40, 44, 54)
		end
		speed.Text = tostring(math.floor(mph + 0.5))
		gear.Text = g
	end
end

-- Mercedes-AMG G 63 (W463, 2012-2018, owner's photo): speedometer left with a small fuel dial in
-- it, rev counter right (red from 6) with a small temperature dial in it,
-- dark faces in silver rings, big white numbers, thin needles (white speed, red revs); between
-- them the P R N D + C (Comfort, green) strip, a trip / odometer screen and the clock + outside
-- temperature line
local function g63(gui: SurfaceGui): Update
	local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(6, 6, 8), BorderSizePixel = 0 }, gui)
	local silver = Color3.fromRGB(196, 200, 210)
	local face = Color3.fromRGB(20, 21, 25)
	local white = Color3.fromRGB(246, 246, 250)
	local red = Color3.fromRGB(235, 40, 50)
	bezel(bg, UDim2.fromScale(0.21, 0.5), 1, silver, 6)
	bezel(bg, UDim2.fromScale(0.79, 0.5), 1, silver, 6)
	local setSpeed = dial(bg, UDim2.fromScale(0.21, 0.5), 0.96, numbers(0, 160, 20), nil, white, -135, 135, face, nil, 0.011)
	local setRpm = dial(bg, UDim2.fromScale(0.79, 0.5), 0.96, numbers(0, 7, 1), 6 / 7, red, -135, 135, face, nil, 0.011)
	text(bg, "mph", UDim2.fromScale(0.21, 0.33), UDim2.fromScale(0.03, 0.045), DIM, Enum.Font.Gotham)
	text(bg, "AMG", UDim2.fromScale(0.79, 0.32), UDim2.fromScale(0.045, 0.06), WHITE, Enum.Font.GothamBlack)
	text(bg, "1/min x1000", UDim2.fromScale(0.79, 0.4), UDim2.fromScale(0.05, 0.035), DIM, Enum.Font.Gotham)
	-- small dials inside the big ones
	dial(bg, UDim2.fromScale(0.21, 0.8), 0.22, { "0", "", "1" }, nil, white, -90, 90, face, nil, 0.02)(0.7)
	dial(bg, UDim2.fromScale(0.79, 0.8), 0.22, { "40", "", "120" }, 0.85, white, -90, 90, face, nil, 0.02)(0.45)
	-- middle
	local strip = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.13), Size = UDim2.fromScale(0.15, 0.13), BackgroundColor3 = Color3.fromRGB(10, 10, 12), BorderSizePixel = 0 }, bg)
	new("UIStroke", { Color = silver, Thickness = 2 }, strip)
	local letters: { [string]: TextLabel } = {}
	for i, l in { "P", "R", "N", "D", "C" } do
		letters[l] = text(strip, l, UDim2.fromScale(0.1 + (i - 1) * 0.2, 0.5), UDim2.fromScale(0.17, 0.75), if l == "C" then Color3.fromRGB(60, 220, 90) else DIM, Enum.Font.GothamBold)
	end
	local screen = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.48), Size = UDim2.fromScale(0.09, 0.36), BackgroundColor3 = Color3.fromRGB(14, 15, 18), BorderSizePixel = 0 }, bg)
	new("UIStroke", { Color = Color3.fromRGB(90, 94, 102), Thickness = 2 }, screen)
	local speed = text(screen, "0", UDim2.fromScale(0.5, 0.3), UDim2.fromScale(0.8, 0.3), WHITE, Enum.Font.GothamBold)
	text(screen, "mph", UDim2.fromScale(0.5, 0.52), UDim2.fromScale(0.4, 0.12), DIM, Enum.Font.Gotham)
	text(screen, "52918 mi", UDim2.fromScale(0.5, 0.8), UDim2.fromScale(0.85, 0.16), WHITE, Enum.Font.Gotham)
	new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.74), Size = UDim2.fromScale(0.2, 0.004), BackgroundColor3 = Color3.fromRGB(110, 90, 40), BorderSizePixel = 0 }, bg)
	local clockText = text(bg, clock(), UDim2.fromScale(0.45, 0.82), UDim2.fromScale(0.05, 0.08), WHITE, Enum.Font.Gotham)
	text(bg, "85°F", UDim2.fromScale(0.56, 0.82), UDim2.fromScale(0.04, 0.07), WHITE, Enum.Font.Gotham)
	local last, lastLetter = 0, ""
	return function(mph: number, g: string, rpm: number)
		setSpeed(mph / 160)
		setRpm(rpm)
		speed.Text = tostring(math.floor(mph + 0.5))
		local letter = if g == "R" then "R" elseif g == "N" then "N" else "D"
		if letter ~= lastLetter then
			if letters[lastLetter] then
				letters[lastLetter].TextColor3 = DIM
			end
			letters[letter].TextColor3 = WHITE
			lastLetter = letter
		end
		if os.clock() - last > 5 then
			last = os.clock()
			clockText.Text = clock()
		end
	end
end

-- Ferrari 599 GTO (owner's photo of the real cluster): carbon surround, a screen on the left with
-- the speed in big digits (owner's wish), the big yellow rev counter in the middle (0 at the bottom round to 10, red from 9, white
-- hub, small gear window), a black speedometer on the right (20-220 mph, white numbers), both with
-- thin red needles
local function ferrari599(gui: SurfaceGui): Update
	local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(26, 26, 28), BorderSizePixel = 0 }, gui)
	new("UICorner", { CornerRadius = UDim.new(0.18, 0) }, bg)
	new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(46, 46, 50), Color3.fromRGB(16, 16, 18)), Rotation = 35 }, bg)
	local RED = Color3.fromRGB(225, 25, 25)
	-- left: the screen, showing how fast you're going
	local screen = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.16, 0.58), Size = UDim2.fromScale(0.25, 0.6), BackgroundColor3 = Color3.fromRGB(8, 9, 11), BorderSizePixel = 0 }, bg)
	new("UICorner", { CornerRadius = UDim.new(0.05, 0) }, screen)
	new("UIStroke", { Color = Color3.fromRGB(60, 60, 64), Thickness = 3 }, screen)
	new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(40, 44, 54), Color3.fromRGB(10, 11, 14)), Rotation = 90 }, screen)
	local digital = text(screen, "0", UDim2.fromScale(0.45, 0.45), UDim2.fromScale(0.7, 0.5), WHITE, Enum.Font.GothamBold)
	text(screen, "mph", UDim2.fromScale(0.86, 0.55), UDim2.fromScale(0.2, 0.14), DIM, Enum.Font.Gotham)
	new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.78), Size = UDim2.fromScale(0.84, 0.012), BackgroundColor3 = Color3.fromRGB(90, 94, 104), BorderSizePixel = 0 }, screen)
	local kmh = text(screen, "0 km/h", UDim2.fromScale(0.5, 0.89), UDim2.fromScale(0.6, 0.14), DIM, Enum.Font.Gotham)
	-- middle: the yellow rev counter
	local box = squareBox(bg, UDim2.fromScale(0.5, 0.5), 0.98)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(20, 20, 22), BorderSizePixel = 0 }, box))
	local face = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.94, 0.94), BackgroundColor3 = FERRARI_YELLOW, BorderSizePixel = 0 }, box)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, face)
	new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(226, 188, 40), Color3.fromRGB(196, 150, 10)), Rotation = 60 }, face)
	local a0, a1 = -178, 108
	for i = 0, 40 do
		local f = i / 40
		local h = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), Rotation = a0 + (a1 - a0) * f }, box)
		local major = i % 4 == 0
		new("Frame", { BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.04), Size = UDim2.fromScale(if major then 0.018 else 0.009, if major then 0.07 else 0.04), BackgroundColor3 = if f >= 0.9 then RED else Color3.fromRGB(20, 18, 10) }, h)
	end
	for i = 0, 10 do
		local ang = math.rad(a0 + (a1 - a0) * i / 10)
		text(box, tostring(i), UDim2.fromScale(0.5 + math.sin(ang) * 0.34, 0.5 - math.cos(ang) * 0.34), UDim2.fromScale(0.12, 0.12), if i >= 9 then RED else Color3.fromRGB(16, 14, 8), Enum.Font.GothamBold)
	end
	text(box, "rpm x 1000", UDim2.fromScale(0.42, 0.68), UDim2.fromScale(0.18, 0.05), Color3.fromRGB(40, 34, 14), Enum.Font.Gotham)
	local gearBox = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.7, 0.66), Size = UDim2.fromScale(0.1, 0.1), BackgroundColor3 = Color3.fromRGB(24, 26, 34), BorderSizePixel = 0, ZIndex = 2 }, box)
	new("UICorner", { CornerRadius = UDim.new(0.15, 0) }, gearBox)
	local gear = text(gearBox, "N", UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.8, 0.8), Color3.fromRGB(230, 232, 240), Enum.Font.GothamBold)
	gear.ZIndex = 3
	local revNeedle = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), Rotation = a0, ZIndex = 4 }, box)
	new("Frame", { BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.07), Size = UDim2.fromScale(0.012, 0.43), BackgroundColor3 = RED, ZIndex = 4 }, revNeedle)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.1, 0.1), BackgroundColor3 = Color3.fromRGB(244, 244, 246), ZIndex = 5 }, box))
	-- right: the speedometer
	local setSpeed = dial(bg, UDim2.fromScale(0.845, 0.52), 0.8, { "", "20", "40", "60", "80", "100", "120", "140", "160", "180", "200", "220" }, nil, RED, -170, 140, Color3.fromRGB(10, 10, 12), nil, 0.011)
	text(bg, "mph", UDim2.fromScale(0.855, 0.62), UDim2.fromScale(0.03, 0.045), DIM, Enum.Font.Gotham)
	local shown = 0
	return function(mph: number, g: string, rpm: number)
		shown += (math.clamp(rpm, 0, 1) - shown) * 0.35
		revNeedle.Rotation = a0 + (a1 - a0) * shown
		setSpeed(mph / 220)
		gear.Text = g
		digital.Text = tostring(math.floor(mph + 0.5))
		kmh.Text = tostring(math.floor(mph * 1.609 + 0.5)) .. " km/h"
	end
end

-- a small screen in a grey frame (gear, speed and the like sit on it)
local function panelScreen(parent: Instance, pos: UDim2, size: UDim2, color: Color3?): Frame
	local f = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = pos, Size = size, BackgroundColor3 = color or Color3.fromRGB(8, 9, 12), BorderSizePixel = 0 }, parent)
	new("UICorner", { CornerRadius = UDim.new(0.08, 0) }, f)
	new("UIStroke", { Color = Color3.fromRGB(80, 84, 94), Thickness = 2 }, f)
	return f
end

-- Maybach 57 S: two big dials with chrome rings on black, the speedometer left and the rev counter
-- right (red from 6), orange-red needles, a screen between them with the gear, the speed, the
-- outside temperature and the clock
local function maybach(gui: SurfaceGui): Update
	local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(6, 6, 8), BorderSizePixel = 0 }, gui)
	local chrome = Color3.fromRGB(206, 208, 214)
	local face = Color3.fromRGB(14, 14, 17)
	local needle = Color3.fromRGB(255, 96, 40)
	bezel(bg, UDim2.fromScale(0.25, 0.5), 1, chrome, 6)
	bezel(bg, UDim2.fromScale(0.75, 0.5), 1, chrome, 6)
	local setSpeed = dial(bg, UDim2.fromScale(0.25, 0.5), 0.95, numbers(0, 200, 20), nil, needle, -135, 135, face)
	local setRpm = dial(bg, UDim2.fromScale(0.75, 0.5), 0.95, numbers(0, 7, 1), 6 / 7, needle, -135, 135, face)
	text(bg, "mph", UDim2.fromScale(0.25, 0.68), UDim2.fromScale(0.03, 0.045), DIM, Enum.Font.Gotham)
	text(bg, "1/min x1000", UDim2.fromScale(0.75, 0.68), UDim2.fromScale(0.06, 0.04), DIM, Enum.Font.Gotham)
	text(bg, "57 S", UDim2.fromScale(0.75, 0.33), UDim2.fromScale(0.045, 0.06), WHITE, Enum.Font.GothamBold)
	local screen = panelScreen(bg, UDim2.fromScale(0.5, 0.54), UDim2.fromScale(0.13, 0.66))
	local gear = text(screen, "P", UDim2.fromScale(0.5, 0.2), UDim2.fromScale(0.35, 0.22), WHITE, Enum.Font.GothamBold)
	local speed = text(screen, "0", UDim2.fromScale(0.5, 0.47), UDim2.fromScale(0.6, 0.2), WHITE, Enum.Font.GothamBold)
	text(screen, "mph", UDim2.fromScale(0.5, 0.6), UDim2.fromScale(0.3, 0.08), DIM, Enum.Font.Gotham)
	text(screen, "+64 °F", UDim2.fromScale(0.5, 0.75), UDim2.fromScale(0.55, 0.08), WHITE, Enum.Font.Gotham)
	local clockText = text(screen, clock(), UDim2.fromScale(0.5, 0.88), UDim2.fromScale(0.5, 0.09), WHITE, Enum.Font.Gotham)
	local last = 0
	return function(mph: number, g: string, rpm: number)
		setSpeed(mph / 200)
		setRpm(rpm)
		gear.Text = if tonumber(g) then "D" else g
		speed.Text = tostring(math.floor(mph + 0.5))
		if os.clock() - last > 5 then
			last = os.clock()
			clockText.Text = clock()
		end
	end
end

-- electric cars' wide screen (Xiaomi SU7: a thin strip above the wheel; Yangwang U8: a wide screen):
-- big digital speed on the left, P R N D with the one in use lit, a power bar that fills as you
-- pull away, battery and range on the right, the clock in the corner
local function evScreen(gui: SurfaceGui, accent: Color3): Update
	local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(4, 5, 8), BorderSizePixel = 0 }, gui)
	new("UICorner", { CornerRadius = UDim.new(0.12, 0) }, bg)
	new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(22, 26, 36), Color3.fromRGB(4, 5, 8)), Rotation = 90 }, bg)
	local speed = text(bg, "0", UDim2.fromScale(0.2, 0.44), UDim2.fromScale(0.2, 0.5), WHITE, Enum.Font.GothamBold)
	text(bg, "mph", UDim2.fromScale(0.2, 0.76), UDim2.fromScale(0.06, 0.1), DIM, Enum.Font.Gotham)
	local letters: { [string]: TextLabel } = {}
	for i, l in { "P", "R", "N", "D" } do
		letters[l] = text(bg, l, UDim2.fromScale(0.41 + (i - 1) * 0.06, 0.36), UDim2.fromScale(0.05, 0.22), DIM, Enum.Font.GothamBold)
	end
	local back = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.7), Size = UDim2.fromScale(0.3, 0.06), BackgroundColor3 = Color3.fromRGB(36, 40, 50), BorderSizePixel = 0 }, bg)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, back)
	local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = accent, BorderSizePixel = 0 }, back)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, fill)
	text(bg, "POWER", UDim2.fromScale(0.5, 0.84), UDim2.fromScale(0.08, 0.08), DIM, Enum.Font.Gotham)
	-- battery
	local batt = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.8, 0.38), Size = UDim2.fromScale(0.09, 0.2), BackgroundTransparency = 1, BorderSizePixel = 0 }, bg)
	new("UIStroke", { Color = WHITE, Thickness = 2 }, batt)
	new("Frame", { Position = UDim2.fromScale(0.06, 0.12), Size = UDim2.fromScale(0.88 * 0.82, 0.76), BackgroundColor3 = Color3.fromRGB(80, 220, 120), BorderSizePixel = 0 }, batt)
	text(bg, "82%", UDim2.fromScale(0.91, 0.38), UDim2.fromScale(0.07, 0.16), WHITE, Enum.Font.GothamBold)
	text(bg, "318 mi", UDim2.fromScale(0.84, 0.66), UDim2.fromScale(0.1, 0.13), WHITE, Enum.Font.GothamMedium)
	local clockText = text(bg, clock(), UDim2.fromScale(0.9, 0.14), UDim2.fromScale(0.07, 0.12), DIM, Enum.Font.Gotham)
	local last, lastLetter = 0, ""
	local shown = 0
	return function(mph: number, g: string, rpm: number)
		speed.Text = tostring(math.floor(mph + 0.5))
		shown += (math.clamp(rpm, 0, 1) - shown) * 0.35
		fill.Size = UDim2.fromScale(shown, 1)
		local letter = if g == "R" then "R" elseif g == "N" then "N" else "D"
		if letter ~= lastLetter then
			if letters[lastLetter] then
				letters[lastLetter].TextColor3 = DIM
			end
			letters[letter].TextColor3 = accent
			lastLetter = letter
		end
		if os.clock() - last > 5 then
			last = os.clock()
			clockText.Text = clock()
		end
	end
end

-- Mazda RX-8: three tubes with chrome rings, the big rev counter in the middle (0-10, red from 9)
-- with the speed in digits and the gear inside it, fuel on the left and water temperature on the
-- right; black faces, white numbers, red needles
local function rx8(gui: SurfaceGui): Update
	local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(5, 5, 7), BorderSizePixel = 0 }, gui)
	local chrome = Color3.fromRGB(190, 194, 202)
	local face = Color3.fromRGB(10, 10, 12)
	local needle = Color3.fromRGB(240, 40, 30)
	for _, d in { { 0.2, 0.56, 0.66, { "E", "", "F" }, 0.7, "FUEL" }, { 0.8, 0.56, 0.66, { "C", "", "H" }, 0.45, "TEMP" } } do
		local x, y, sz = d[1] :: number, d[2] :: number, d[3] :: number
		bezel(bg, UDim2.fromScale(x, y), sz, chrome, 4)
		dial(bg, UDim2.fromScale(x, y), sz - 0.04, d[4] :: { string }, nil, needle, -70, 70, face)(d[5] :: number)
		text(bg, d[6] :: string, UDim2.fromScale(x, y + 0.16), UDim2.fromScale(0.04, 0.05), DIM, Enum.Font.Gotham)
	end
	bezel(bg, UDim2.fromScale(0.5, 0.5), 1, chrome, 6)
	local setRpm = dial(bg, UDim2.fromScale(0.5, 0.5), 0.96, numbers(0, 10, 1), 0.9, needle, -135, 135, face)
	text(bg, "x1000r/min", UDim2.fromScale(0.5, 0.36), UDim2.fromScale(0.06, 0.04), DIM, Enum.Font.Gotham)
	local screen = panelScreen(bg, UDim2.fromScale(0.5, 0.72), UDim2.fromScale(0.1, 0.2), Color3.fromRGB(10, 12, 16))
	local speed = text(screen, "0", UDim2.fromScale(0.4, 0.5), UDim2.fromScale(0.55, 0.7), WHITE, Enum.Font.GothamBold)
	text(screen, "mph", UDim2.fromScale(0.82, 0.62), UDim2.fromScale(0.25, 0.3), DIM, Enum.Font.Gotham)
	local gear = text(bg, "N", UDim2.fromScale(0.5, 0.6), UDim2.fromScale(0.03, 0.08), Color3.fromRGB(255, 140, 40), Enum.Font.GothamBold)
	return function(mph: number, g: string, rpm: number)
		setRpm(rpm)
		speed.Text = tostring(math.floor(mph + 0.5))
		gear.Text = g
	end
end

-- Lexus LFA screen (the LX 700's meter carries the same look): one big round rev counter in a
-- silver ring with a thin bright needle, the speed in big digits and the gear in the middle, fuel
-- and temperature bars on the left, trip and clock on the right
local function lexus(gui: SurfaceGui, rpmTop: number, redFrom: number, accent: Color3): Update
	local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(4, 5, 7), BorderSizePixel = 0 }, gui)
	new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(18, 22, 30), Color3.fromRGB(4, 5, 7)), Rotation = 90 }, bg)
	bezel(bg, UDim2.fromScale(0.5, 0.5), 1, Color3.fromRGB(200, 204, 212), 7)
	local setRpm = dial(bg, UDim2.fromScale(0.5, 0.5), 0.96, numbers(0, rpmTop, 1), redFrom / rpmTop, accent, -135, 135, Color3.fromRGB(8, 9, 12), nil, 0.012)
	local speed = text(bg, "0", UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.1, 0.2), WHITE, Enum.Font.GothamMedium)
	text(bg, "mph", UDim2.fromScale(0.5, 0.63), UDim2.fromScale(0.03, 0.05), DIM, Enum.Font.Gotham)
	local gear = text(bg, "N", UDim2.fromScale(0.5, 0.78), UDim2.fromScale(0.03, 0.1), accent, Enum.Font.GothamBold)
	bar(bg, UDim2.fromScale(0.16, 0.5), WHITE, "FUEL", 0.72)
	bar(bg, UDim2.fromScale(0.24, 0.5), WHITE, "TEMP", 0.5)
	text(bg, "TRIP A", UDim2.fromScale(0.8, 0.36), UDim2.fromScale(0.07, 0.06), DIM, Enum.Font.Gotham)
	text(bg, "128.4 mi", UDim2.fromScale(0.8, 0.46), UDim2.fromScale(0.1, 0.08), WHITE, Enum.Font.GothamMedium)
	local clockText = text(bg, clock(), UDim2.fromScale(0.8, 0.64), UDim2.fromScale(0.07, 0.08), WHITE, Enum.Font.Gotham)
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

-- Porsche 718 Cayman: three round tubes, the rev counter in the middle and biggest (0-8, red from
-- 7.5) with the gear and the speed in digits inside, the speedometer on the left, a round screen
-- on the right (range, outside temperature, clock); black faces, white numbers, red needles
local function porsche718(gui: SurfaceGui): Update
	local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(5, 5, 7), BorderSizePixel = 0 }, gui)
	local ring = Color3.fromRGB(150, 154, 162)
	local face = Color3.fromRGB(10, 10, 12)
	local needle = Color3.fromRGB(240, 40, 30)
	bezel(bg, UDim2.fromScale(0.2, 0.55), 0.82, ring, 4)
	local setSpeed = dial(bg, UDim2.fromScale(0.2, 0.55), 0.78, numbers(0, 200, 40), nil, needle, -135, 135, face)
	text(bg, "mph", UDim2.fromScale(0.2, 0.72), UDim2.fromScale(0.03, 0.045), DIM, Enum.Font.Gotham)
	bezel(bg, UDim2.fromScale(0.5, 0.5), 1, ring, 5)
	local setRpm = dial(bg, UDim2.fromScale(0.5, 0.5), 0.96, numbers(0, 8, 1), 7.5 / 8, needle, -135, 135, face)
	text(bg, "1/min x1000", UDim2.fromScale(0.5, 0.35), UDim2.fromScale(0.06, 0.04), DIM, Enum.Font.Gotham)
	local gear = text(bg, "N", UDim2.fromScale(0.5, 0.62), UDim2.fromScale(0.035, 0.1), WHITE, Enum.Font.GothamBold)
	local speed = text(bg, "0", UDim2.fromScale(0.5, 0.76), UDim2.fromScale(0.05, 0.08), WHITE, Enum.Font.GothamBold)
	-- the round screen
	bezel(bg, UDim2.fromScale(0.8, 0.55), 0.82, ring, 4)
	local screen = squareBox(bg, UDim2.fromScale(0.8, 0.55), 0.78)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(14, 18, 26), BorderSizePixel = 0 }, screen))
	text(screen, "RANGE", UDim2.fromScale(0.5, 0.3), UDim2.fromScale(0.3, 0.08), DIM, Enum.Font.Gotham)
	text(screen, "214 mi", UDim2.fromScale(0.5, 0.42), UDim2.fromScale(0.5, 0.13), WHITE, Enum.Font.GothamBold)
	text(screen, "+61 °F", UDim2.fromScale(0.5, 0.62), UDim2.fromScale(0.36, 0.1), WHITE, Enum.Font.Gotham)
	local clockText = text(screen, clock(), UDim2.fromScale(0.5, 0.76), UDim2.fromScale(0.3, 0.1), WHITE, Enum.Font.Gotham)
	local last = 0
	return function(mph: number, g: string, rpm: number)
		setSpeed(mph / 200)
		setRpm(rpm)
		gear.Text = g
		speed.Text = tostring(math.floor(mph + 0.5))
		if os.clock() - last > 5 then
			last = os.clock()
			clockText.Text = clock()
		end
	end
end

-- Nissan GT-R (R35): the big rev counter in the middle (0-8, red from 7) with the gear in a window
-- and the speed in digits inside, the speedometer on the right (0-200 mph), fuel and water temperature
-- dials on the left; silver rings, black faces, white numbers, red needles
local function gtr(gui: SurfaceGui): Update
	local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(5, 5, 7), BorderSizePixel = 0 }, gui)
	local ring = Color3.fromRGB(176, 182, 192)
	local face = Color3.fromRGB(10, 10, 12)
	local needle = Color3.fromRGB(240, 40, 30)
	for _, d in { { 0.15, 0.32, { "E", "", "F" }, 0.7, "FUEL" }, { 0.15, 0.74, { "C", "", "H" }, 0.45, "TEMP" } } do
		local x, y = d[1] :: number, d[2] :: number
		bezel(bg, UDim2.fromScale(x, y), 0.42, ring, 3)
		dial(bg, UDim2.fromScale(x, y), 0.4, d[3] :: { string }, nil, needle, -90, 90, face)(d[4] :: number)
		text(bg, d[5] :: string, UDim2.fromScale(x, y + 0.12), UDim2.fromScale(0.035, 0.045), DIM, Enum.Font.Gotham)
	end
	bezel(bg, UDim2.fromScale(0.47, 0.5), 1, ring, 6)
	local setRpm = dial(bg, UDim2.fromScale(0.47, 0.5), 0.96, numbers(0, 8, 1), 7 / 8, needle, -135, 135, face)
	text(bg, "x1000r/min", UDim2.fromScale(0.47, 0.36), UDim2.fromScale(0.06, 0.04), DIM, Enum.Font.Gotham)
	local window = panelScreen(bg, UDim2.fromScale(0.47, 0.68), UDim2.fromScale(0.08, 0.22), Color3.fromRGB(14, 16, 20))
	local gear = text(window, "N", UDim2.fromScale(0.5, 0.36), UDim2.fromScale(0.5, 0.5), Color3.fromRGB(255, 140, 40), Enum.Font.GothamBold)
	local speed = text(window, "0 mph", UDim2.fromScale(0.5, 0.8), UDim2.fromScale(0.85, 0.28), WHITE, Enum.Font.Gotham)
	bezel(bg, UDim2.fromScale(0.82, 0.52), 0.86, ring, 4)
	local setSpeed = dial(bg, UDim2.fromScale(0.82, 0.52), 0.82, numbers(0, 200, 40), nil, needle, -135, 135, face)
	text(bg, "MPH", UDim2.fromScale(0.82, 0.7), UDim2.fromScale(0.03, 0.045), DIM, Enum.Font.Gotham)
	return function(mph: number, g: string, rpm: number)
		setRpm(rpm)
		setSpeed(mph / 200)
		gear.Text = g
		speed.Text = tostring(math.floor(mph + 0.5)) .. " mph"
	end
end

-- the styles by name (the DashCluster panel's Style attribute)
local STYLES: { [string]: (SurfaceGui) -> Update } = {
	Maybach57 = maybach,
	SU7 = function(gui)
		return evScreen(gui, Color3.fromRGB(255, 105, 0))
	end,
	U8 = function(gui)
		return evScreen(gui, Color3.fromRGB(60, 200, 230))
	end,
	RX8 = rx8,
	LFA = function(gui)
		return lexus(gui, 10, 9, Color3.fromRGB(255, 120, 40))
	end,
	LexusLX = function(gui)
		return lexus(gui, 8, 6, Color3.fromRGB(80, 170, 255))
	end,
	Porsche718 = porsche718,
	GTR = gtr,
}

function DashGauges.build(panel: BasePart): Update
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Gauges"
	gui.Face = Enum.NormalId.Back
	gui.CanvasSize = Vector2.new(math.floor(panel.Size.X / panel.Size.Y * 300), 300)
	gui.LightInfluence = 0
	gui.Brightness = 1.8
	gui.MaxDistance = 60
	gui.Parent = panel
	local style = panel:GetAttribute("Style")
	local own = if type(style) == "string" then STYLES[style] else nil
	local update = if own then own(gui) elseif style == "BMWLive" then bmwLive(gui) elseif style == "BMWClassic" then bmwClassic(gui) elseif style == "BMWClassicGrey" then bmwClassic(gui, true) elseif style == "AMG" then amg(gui) elseif style == "AMGBiturbo" then amg(gui, true) elseif style == "G63" then g63(gui) elseif style == "AMGSls" then amg(gui, false, 220) elseif style == "Aston" then aston(gui) elseif style == "Urus" then urus(gui) elseif style == "Murcielago" then twinWithSmalls(gui, true, 9, 8, Color3.fromRGB(255, 90, 20), Color3.fromRGB(176, 182, 192), { { "OIL °C", "50", "150" }, { "OIL bar", "0", "10" }, { "FUEL", "0", "1" }, { "°C", "50", "130" } }) elseif style == "C6" then twinWithSmalls(gui, false, 7, 6.5, Color3.fromRGB(255, 110, 30), Color3.fromRGB(150, 156, 166), { { "FUEL", "E", "F" }, { "OIL", "0", "80" }, { "TEMP", "100", "280" }, { "VOLTS", "8", "18" } }) elseif style == "C7" then c7(gui) elseif style == "W212" then w212(gui) elseif style == "W213" then w213(gui) elseif style == "Gallardo" then gallardo(gui) elseif style == "SupraTRD" then supraTrd(gui) elseif style == "Toyota" then toyota(gui) elseif style == "Aventador" then aventador(gui, true) elseif style == "Lambo" then lambo(gui) elseif style == "Ferrari" then ferrari(gui) elseif style == "Ferrari599" then ferrari599(gui) else modern(gui)
	-- start-up: the screens fade up and the needles sweep to the end and back, like a real car
	local started = os.clock()
	local SWEEP = 1.6
	return function(mph: number, g: string, rpm: number)
		local t = os.clock() - started
		if t < SWEEP then
			gui.Brightness = 1.8 * math.clamp(t / 0.5, 0, 1)
			local sweep = math.sin(math.clamp(t / SWEEP, 0, 1) * math.pi)
			update(math.max(mph, sweep * 180), g, math.max(rpm, sweep))
		else
			gui.Brightness = 1.8
			update(mph, g, rpm)
		end
	end
end

return DashGauges
