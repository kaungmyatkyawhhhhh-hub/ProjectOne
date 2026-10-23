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

-- speed units (the player's setting): every speed on a cluster, its dial and its label follow it
local KMH = false
function DashGauges.setUnits(units: string)
	KMH = units == "kmh"
end
local function spd(mph: number): string
	return tostring(math.floor((if KMH then mph * 1.609 else mph) + 0.5))
end
local function alt(mph: number): string -- the other unit, for clusters that show both
	return tostring(math.floor((if KMH then mph else mph * 1.609) + 0.5))
end
local function unit(upper: boolean?): string
	local u = if KMH then "km/h" else "mph"
	return if upper then u:upper() else u
end
local function altUnit(): string
	return if KMH then "mph" else "km/h"
end
-- a speedometer scale drawn for topMph: its labels in the player's unit and the mph at its end
local function speedScale(topMph: number, stepMph: number): ({ string }, number)
	if not KMH then
		return numbers(0, topMph, stepMph), topMph
	end
	local step = if stepMph >= 40 then 60 elseif topMph * 1.609 > 170 then 40 else 20
	local top = math.ceil(topMph * 1.609 / step - 0.15) * step
	return numbers(0, top, step), top / 1.609
end

-- a speedometer dial (see speedScale); its setter takes mph
local function speedDial(parent: Instance, center: UDim2, size: number, topMph: number, stepMph: number, redFrom: number?, needleColor: Color3, a0: number, a1: number, face: Color3?, faceless: boolean?, needleWidth: number?): (number) -> ()
	local labels, endMph = speedScale(topMph, stepMph)
	local set = dial(parent, center, size, labels, redFrom, needleColor, a0, a1, face, faceless, needleWidth)
	return function(mph: number)
		set(mph / endMph)
	end
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
	text(bg, unit(), UDim2.fromScale(0.535, 0.7), UDim2.fromScale(0.05, 0.06), DIM, Enum.Font.Gotham)
	local gear = text(bg, "N", UDim2.fromScale(0.465, 0.62), UDim2.fromScale(0.045, 0.14), AMBER, Enum.Font.GothamBlack)
	local last = 0
	return function(mph: number, g: string, rpm: number)
		setRpm(rpm)
		speed.Text = spd(mph)
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
	text(bg, unit(), UDim2.fromScale(0.5, 0.56), UDim2.fromScale(0.08, 0.08), DIM, Enum.Font.Gotham)
	local gear = text(bg, "N", UDim2.fromScale(0.5, 0.74), UDim2.fromScale(0.07, 0.16), BLUE, Enum.Font.GothamBlack)
	-- right: analog speedometer, 0-180 mph
	local setSpeed = speedDial(bg, UDim2.fromScale(0.8, 0.55), 0.88, 180, 20, nil, RED, -125, 125)
	local last = 0
	return function(mph: number, g: string, rpm: number)
		setSpeed(mph)
		speed.Text = spd(mph)
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
-- withSpeedDial (599 GTO): an analog speedometer with its own needle on the left instead of the
-- temperature screen
local function ferrari(gui: SurfaceGui, withSpeedDial: boolean?): Update
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
	if withSpeedDial then
		bezel(bg, UDim2.fromScale(0.165, 0.55), 0.8, Color3.fromRGB(150, 150, 156), 4)
		setSpeedDial = speedDial(bg, UDim2.fromScale(0.165, 0.55), 0.76, 220, 20, nil, Color3.fromRGB(230, 30, 30), -135, 135, Color3.fromRGB(14, 14, 16), nil, 0.012)
		text(bg, unit(true), UDim2.fromScale(0.165, 0.72), UDim2.fromScale(0.03, 0.045), DIM, Enum.Font.Gotham)
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
	text(right, unit(), UDim2.fromScale(0.85, 0.48), UDim2.fromScale(0.16, 0.1), DIM, Enum.Font.Gotham)
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
			setSpeedDial(mph)
		end
		speed.Text = spd(mph)
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
	local unitLabel = text(box, unit(), UDim2.fromScale(0.73, 0.68), UDim2.fromScale(0.08, 0.035), WHITE, Enum.Font.Gotham)
	unitLabel.ZIndex = 5
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
		speed.Text = spd(mph)
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
	local setSpeed = speedDial(bg, UDim2.fromScale(0.23, 0.48), 0.95, 200, 20, nil, Color3.fromRGB(230, 232, 238), 165, 390, nil, true)
	local setRpm = dial(bg, UDim2.fromScale(0.77, 0.48), 0.95, numbers(0, 8, 1), 6.5 / 8, Color3.fromRGB(230, 232, 238), 195, -30, nil, true)
	local speed = text(bg, "0", UDim2.fromScale(0.37, 0.45), UDim2.fromScale(0.08, 0.16), WHITE, Enum.Font.GothamBold)
	text(bg, unit(), UDim2.fromScale(0.42, 0.47), UDim2.fromScale(0.04, 0.06), DIM, Enum.Font.Gotham)
	local kmh = text(bg, "0", UDim2.fromScale(0.375, 0.6), UDim2.fromScale(0.05, 0.08), WHITE, Enum.Font.GothamBold)
	text(bg, altUnit(), UDim2.fromScale(0.42, 0.6), UDim2.fromScale(0.04, 0.05), DIM, Enum.Font.Gotham)
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
		setSpeed(mph)
		setRpm(rpm)
		speed.Text = spd(mph)
		kmh.Text = alt(mph)
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
	local setSpeed = speedDial(bg, UDim2.fromScale(0.3, 0.5), 0.94, 200, 20, nil, Color3.fromRGB(240, 40, 30), -135, 135, face)
	local setRpm = dial(bg, UDim2.fromScale(0.7, 0.5), 0.94, numbers(0, 9, 1), 7.5 / 9, Color3.fromRGB(240, 40, 30), -135, 135, face)
	text(bg, unit(true), UDim2.fromScale(0.3, 0.7), UDim2.fromScale(0.04, 0.05), DIM, Enum.Font.Gotham)
	text(bg, "1/min x1000", UDim2.fromScale(0.7, 0.7), UDim2.fromScale(0.07, 0.04), DIM, Enum.Font.Gotham)
	local screen = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.72), Size = UDim2.fromScale(0.09, 0.2), BackgroundColor3 = Color3.fromRGB(14, 6, 4), BorderSizePixel = 0 }, bg)
	local gear = text(screen, "N", UDim2.fromScale(0.5, 0.38), UDim2.fromScale(0.6, 0.5), Color3.fromRGB(255, 120, 40), Enum.Font.GothamBold)
	local speed = text(screen, "0", UDim2.fromScale(0.5, 0.8), UDim2.fromScale(0.8, 0.3), Color3.fromRGB(255, 120, 40), Enum.Font.Gotham)
	return function(mph: number, g: string, rpm: number)
		setSpeed(mph)
		setRpm(rpm)
		gear.Text = g
		speed.Text = spd(mph)
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
	local setSpeed = speedDial(bg, UDim2.fromScale(sx, 0.5), 0.95, top, 20, nil, needle, -135, 135, carbon)
	local setRpm = dial(bg, UDim2.fromScale(rx, 0.5), 0.95, numbers(0, 8, 1), 6.5 / 8, needle, -135, 135, carbon)
	dial(bg, UDim2.fromScale(sx + 0.05, 0.72), 0.3, { "0", "1/2", "1" }, nil, needle, -120, 0)(0.75)
	dial(bg, UDim2.fromScale(rx + 0.05, 0.72), 0.3, { "40", "80", "120" }, nil, needle, -120, 0)(0.55)
	text(bg, unit(), UDim2.fromScale(sx + 0.07, 0.6), UDim2.fromScale(0.03, 0.04), DIM, Enum.Font.Gotham)
	-- (brand mark removed: owner, 2026-10-17)
	if biturbo then
		-- (brand mark removed: owner, 2026-10-17)
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
	local speed = text(screen, "0" .. unit(), UDim2.fromScale(0.3, 0.1), UDim2.fromScale(0.45, 0.1), WHITE, Enum.Font.GothamBold)
	local gearBig = text(screen, "P", UDim2.fromScale(0.7, 0.1), UDim2.fromScale(0.25, 0.15), WHITE, Enum.Font.GothamBold)
	for i, t in { "97°C", "94°C", "76°C" } do
		text(screen, t, UDim2.fromScale(0.6, 0.28 + i * 0.1), UDim2.fromScale(0.5, 0.08), WHITE, Enum.Font.GothamBold)
	end
	local kmh = text(screen, "0" .. altUnit(), UDim2.fromScale(0.27, 0.9), UDim2.fromScale(0.45, 0.08), WHITE, Enum.Font.Gotham)
	local clockText = text(screen, clock(), UDim2.fromScale(0.75, 0.9), UDim2.fromScale(0.4, 0.08), WHITE, Enum.Font.Gotham)
	local last, lastLetter = 0, ""
	return function(mph: number, g: string, rpm: number)
		setSpeed(mph)
		setRpm(rpm)
		speed.Text = spd(mph) .. unit()
		kmh.Text = alt(mph) .. altUnit()
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
	-- (brand mark removed: owner, 2026-10-17)
	local setRpm = dial(bg, UDim2.fromScale(0.5, 0.5), 1, numbers(0, 10, 1), 0.7, needle, -180 + 10, 170, nil)
	text(bg, "x1000RPM", UDim2.fromScale(0.5, 0.6), UDim2.fromScale(0.07, 0.04), WHITE, Enum.Font.Gotham)
	-- (brand mark removed: owner, 2026-10-17)
	local setSpeed = speedDial(bg, UDim2.fromScale(0.83, 0.5), 0.95, 200, 20, 0.85, needle, -125, 125, nil)
	text(bg, unit(true), UDim2.fromScale(0.85, 0.62), UDim2.fromScale(0.03, 0.04), WHITE, Enum.Font.Gotham)
	text(bg, "Supra", UDim2.fromScale(0.82, 0.74), UDim2.fromScale(0.07, 0.07), WHITE, Enum.Font.Arcade)
	return function(mph: number, _g: string, rpm: number)
		setRpm(rpm)
		setSpeed(mph)
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
	local setSpeed = speedDial(bg, UDim2.fromScale(0.76, 0.52), 0.88, 120, 20, nil, needle, -120, 120)
	dial(bg, UDim2.fromScale(0.76, 0.8), 0.25, { "E", "F" }, nil, needle, -60, 60, nil, true)(0.7)
	text(bg, unit(), UDim2.fromScale(0.76, 0.36), UDim2.fromScale(0.04, 0.05), DIM, Enum.Font.Gotham)
	-- middle screen
	local screen = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52), Size = UDim2.fromScale(0.13, 0.78), BackgroundColor3 = Color3.fromRGB(10, 12, 20), BorderSizePixel = 0 }, bg)
	new("UIStroke", { Color = Color3.fromRGB(120, 126, 140), Thickness = 2 }, screen)
	text(screen, "READY", UDim2.fromScale(0.5, 0.12), UDim2.fromScale(0.6, 0.08), Color3.fromRGB(80, 220, 120), Enum.Font.GothamBold)
	local gear = text(screen, "P", UDim2.fromScale(0.5, 0.55), UDim2.fromScale(0.5, 0.25), WHITE, Enum.Font.GothamBold)
	text(screen, "ODO 99137km", UDim2.fromScale(0.5, 0.9), UDim2.fromScale(0.9, 0.07), Color3.fromRGB(120, 170, 255), Enum.Font.Gotham)
	return function(mph: number, g: string, rpm: number)
		setPower(rpm)
		setSpeed(mph)
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
	local setSpeed = speedDial(bg, UDim2.fromScale(0.5, 0.5), 0.92, 160, 20, nil, needle, -135, 135, face)
	-- the screen inside the speedometer: gear and digital speed
	local screen = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.72), Size = UDim2.fromScale(0.07, 0.2), BackgroundColor3 = Color3.fromRGB(26, 28, 34), BorderSizePixel = 0 }, bg)
	new("UICorner", { CornerRadius = UDim.new(0.12, 0) }, screen)
	local gear = text(screen, "P", UDim2.fromScale(0.5, 0.32), UDim2.fromScale(0.7, 0.45), WHITE, Enum.Font.GothamBold)
	local speed = text(screen, "0 " .. unit(), UDim2.fromScale(0.5, 0.78), UDim2.fromScale(0.9, 0.3), WHITE, Enum.Font.Gotham)
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
		setSpeed(mph)
		gear.Text = if tonumber(g) then "D" else g
		speed.Text = spd(mph) .. " " .. unit()
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
	local speedLabels, speedEnd = speedScale(160, 20)
	local setSpeed = ringGauge(0.8, speedLabels, nil)
	text(bg, "x1000/min", UDim2.fromScale(0.2, 0.72), UDim2.fromScale(0.06, 0.04), DIM, Enum.Font.Gotham)
	text(bg, unit(), UDim2.fromScale(0.8, 0.72), UDim2.fromScale(0.03, 0.04), DIM, Enum.Font.Gotham)
	-- middle
	local clockText = text(bg, clock(), UDim2.fromScale(0.42, 0.08), UDim2.fromScale(0.06, 0.07), WHITE, Enum.Font.Gotham)
	text(bg, "+18.5 °C", UDim2.fromScale(0.58, 0.08), UDim2.fromScale(0.06, 0.06), WHITE, Enum.Font.Gotham)
	local speed = text(bg, "0", UDim2.fromScale(0.5, 0.4), UDim2.fromScale(0.12, 0.26), WHITE, Enum.Font.GothamMedium)
	text(bg, unit(), UDim2.fromScale(0.5, 0.56), UDim2.fromScale(0.04, 0.06), DIM, Enum.Font.Gotham)
	local gear = text(bg, "P", UDim2.fromScale(0.5, 0.74), UDim2.fromScale(0.05, 0.13), RINGRED, Enum.Font.GothamBold)
	text(bg, "S+", UDim2.fromScale(0.5, 0.9), UDim2.fromScale(0.03, 0.08), WHITE, Enum.Font.GothamBold)
	local last = 0
	return function(mph: number, g: string, rpm: number)
		setRpm(rpm)
		setSpeed(mph / speedEnd)
		speed.Text = spd(mph)
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
	local setSpeed = speedDial(bg, UDim2.fromScale(0.31, 0.52), 0.82, 220, 20, nil, needle, -135, 135, face)
	local setRpm = dial(bg, UDim2.fromScale(0.69, 0.52), 0.82, numbers(0, 10, 1), 8 / 10, needle, -135, 135, face)
	text(bg, unit(), UDim2.fromScale(0.31, 0.7), UDim2.fromScale(0.03, 0.045), DIM, Enum.Font.Gotham)
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
	text(screen, unit(), UDim2.fromScale(0.5, 0.86), UDim2.fromScale(0.4, 0.12), DIM, Enum.Font.Gotham)
	return function(mph: number, g: string, rpm: number)
		setSpeed(mph)
		setRpm(rpm)
		gear.Text = g
		speed.Text = spd(mph)
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
	local setSpeed = speedDial(bg, UDim2.fromScale(0.27, 0.5), 0.94, 200, 20, nil, needle, -135, 135, face)
	local setRpm = dial(bg, UDim2.fromScale(0.73, 0.5), 0.94, numbers(0, 8, 1), 6.8 / 8, needle, 135, -135, face)
	text(bg, unit(true), UDim2.fromScale(0.27, 0.7), UDim2.fromScale(0.035, 0.045), DIM, Enum.Font.Gotham)
	text(bg, "RPM x1000", UDim2.fromScale(0.73, 0.7), UDim2.fromScale(0.06, 0.045), DIM, Enum.Font.Gotham)
	local screen = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.55), Size = UDim2.fromScale(0.13, 0.62), BackgroundColor3 = Color3.fromRGB(4, 4, 6), BorderSizePixel = 0 }, bg)
	new("UIStroke", { Color = Color3.fromRGB(90, 94, 102), Thickness = 2 }, screen)
	local gear = text(screen, "N", UDim2.fromScale(0.5, 0.22), UDim2.fromScale(0.4, 0.25), WHITE, Enum.Font.GothamBold)
	local speed = text(screen, "0 " .. unit(), UDim2.fromScale(0.5, 0.48), UDim2.fromScale(0.8, 0.14), WHITE, Enum.Font.Gotham)
	for _, b in { { 0.3, 0.75 }, { 0.7, 0.5 } } do
		local back = new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(b[1], 0.86), Size = UDim2.fromScale(0.06, 0.26), BackgroundColor3 = Color3.fromRGB(40, 42, 48), BorderSizePixel = 0 }, screen)
		new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, b[2]), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, back)
	end
	text(screen, "FUEL", UDim2.fromScale(0.3, 0.93), UDim2.fromScale(0.35, 0.08), DIM, Enum.Font.Gotham)
	text(screen, "TEMP", UDim2.fromScale(0.7, 0.93), UDim2.fromScale(0.35, 0.08), DIM, Enum.Font.Gotham)
	return function(mph: number, g: string, rpm: number)
		setSpeed(mph)
		setRpm(rpm)
		gear.Text = g
		speed.Text = spd(mph) .. " " .. unit()
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
	text(box, unit(), UDim2.fromScale(0.5, 0.84), UDim2.fromScale(0.1, 0.05), DIM, Enum.Font.Gotham)
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
		speed.Text = spd(mph)
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
	local setSpeed = speedDial(bg, UDim2.fromScale(spdX, 0.5), 0.94, 200, 20, nil, needle, -135, 135, face)
	text(bg, "RPM x1000", UDim2.fromScale(rpmX, 0.7), UDim2.fromScale(0.06, 0.045), DIM, Enum.Font.Gotham)
	text(bg, unit(true), UDim2.fromScale(spdX, 0.7), UDim2.fromScale(0.035, 0.045), DIM, Enum.Font.Gotham)
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
	local speed = text(screen, "0 " .. unit(), UDim2.fromScale(0.65, 0.5), UDim2.fromScale(0.6, 0.6), WHITE, Enum.Font.Gotham)
	return function(mph: number, g: string, rpm: number)
		setRpm(rpm)
		setSpeed(mph)
		gear.Text = g
		speed.Text = spd(mph) .. " " .. unit()
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
	local setSpeed = speedDial(bg, UDim2.fromScale(0.145, 0.52), 0.76, 200, 20, nil, needle, -135, 135, face)
	text(bg, unit(true), UDim2.fromScale(0.145, 0.7), UDim2.fromScale(0.03, 0.045), DIM, Enum.Font.Gotham)
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
	text(box, unit(true), UDim2.fromScale(0.5, 0.6), UDim2.fromScale(0.1, 0.06), DIM, Enum.Font.Gotham)
	local gear = text(box, "N", UDim2.fromScale(0.5, 0.76), UDim2.fromScale(0.12, 0.13), Color3.fromRGB(255, 200, 40), Enum.Font.GothamBlack)
	local shown = 0
	return function(mph: number, g: string, rpm: number)
		setSpeed(mph)
		shown += (math.clamp(rpm, 0, 1) - shown) * 0.35
		local lit = math.floor(shown * n + 0.5)
		-- yellow to amber to red as the revs rise
		local col = if shown > 0.85 then Color3.fromRGB(240, 40, 30) elseif shown > 0.65 then Color3.fromRGB(255, 140, 20) else Color3.fromRGB(255, 210, 40)
		for i, seg in segs do
			seg.BackgroundColor3 = if i <= lit then col else Color3.fromRGB(40, 44, 54)
		end
		speed.Text = spd(mph)
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
	local setSpeed = speedDial(bg, UDim2.fromScale(0.21, 0.5), 0.96, 160, 20, nil, white, -135, 135, face, nil, 0.011)
	local setRpm = dial(bg, UDim2.fromScale(0.79, 0.5), 0.96, numbers(0, 7, 1), 6 / 7, red, -135, 135, face, nil, 0.011)
	text(bg, unit(), UDim2.fromScale(0.21, 0.33), UDim2.fromScale(0.03, 0.045), DIM, Enum.Font.Gotham)
	-- (brand mark removed: owner, 2026-10-17)
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
	text(screen, unit(), UDim2.fromScale(0.5, 0.52), UDim2.fromScale(0.4, 0.12), DIM, Enum.Font.Gotham)
	text(screen, "52918 mi", UDim2.fromScale(0.5, 0.8), UDim2.fromScale(0.85, 0.16), WHITE, Enum.Font.Gotham)
	new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.74), Size = UDim2.fromScale(0.2, 0.004), BackgroundColor3 = Color3.fromRGB(110, 90, 40), BorderSizePixel = 0 }, bg)
	local clockText = text(bg, clock(), UDim2.fromScale(0.45, 0.82), UDim2.fromScale(0.05, 0.08), WHITE, Enum.Font.Gotham)
	text(bg, "85°F", UDim2.fromScale(0.56, 0.82), UDim2.fromScale(0.04, 0.07), WHITE, Enum.Font.Gotham)
	local last, lastLetter = 0, ""
	return function(mph: number, g: string, rpm: number)
		setSpeed(mph)
		setRpm(rpm)
		speed.Text = spd(mph)
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
	text(screen, unit(), UDim2.fromScale(0.86, 0.55), UDim2.fromScale(0.2, 0.14), DIM, Enum.Font.Gotham)
	new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.78), Size = UDim2.fromScale(0.84, 0.012), BackgroundColor3 = Color3.fromRGB(90, 94, 104), BorderSizePixel = 0 }, screen)
	local kmh = text(screen, "0 " .. altUnit(), UDim2.fromScale(0.5, 0.89), UDim2.fromScale(0.6, 0.14), DIM, Enum.Font.Gotham)
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
	local setSpeed = speedDial(bg, UDim2.fromScale(0.845, 0.52), 0.8, 220, 20, nil, RED, -170, 140, Color3.fromRGB(10, 10, 12), nil, 0.011)
	text(bg, unit(), UDim2.fromScale(0.855, 0.62), UDim2.fromScale(0.03, 0.045), DIM, Enum.Font.Gotham)
	local shown = 0
	return function(mph: number, g: string, rpm: number)
		shown += (math.clamp(rpm, 0, 1) - shown) * 0.35
		revNeedle.Rotation = a0 + (a1 - a0) * shown
		setSpeed(mph)
		gear.Text = g
		digital.Text = spd(mph)
		kmh.Text = alt(mph) .. " " .. altUnit()
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
	local setSpeed = speedDial(bg, UDim2.fromScale(0.25, 0.5), 0.95, 200, 20, nil, needle, -135, 135, face)
	local setRpm = dial(bg, UDim2.fromScale(0.75, 0.5), 0.95, numbers(0, 7, 1), 6 / 7, needle, -135, 135, face)
	text(bg, unit(), UDim2.fromScale(0.25, 0.68), UDim2.fromScale(0.03, 0.045), DIM, Enum.Font.Gotham)
	text(bg, "1/min x1000", UDim2.fromScale(0.75, 0.68), UDim2.fromScale(0.06, 0.04), DIM, Enum.Font.Gotham)
	text(bg, "57 S", UDim2.fromScale(0.75, 0.33), UDim2.fromScale(0.045, 0.06), WHITE, Enum.Font.GothamBold)
	local screen = panelScreen(bg, UDim2.fromScale(0.5, 0.54), UDim2.fromScale(0.13, 0.66))
	local gear = text(screen, "P", UDim2.fromScale(0.5, 0.2), UDim2.fromScale(0.35, 0.22), WHITE, Enum.Font.GothamBold)
	local speed = text(screen, "0", UDim2.fromScale(0.5, 0.47), UDim2.fromScale(0.6, 0.2), WHITE, Enum.Font.GothamBold)
	text(screen, unit(), UDim2.fromScale(0.5, 0.6), UDim2.fromScale(0.3, 0.08), DIM, Enum.Font.Gotham)
	text(screen, "+64 °F", UDim2.fromScale(0.5, 0.75), UDim2.fromScale(0.55, 0.08), WHITE, Enum.Font.Gotham)
	local clockText = text(screen, clock(), UDim2.fromScale(0.5, 0.88), UDim2.fromScale(0.5, 0.09), WHITE, Enum.Font.Gotham)
	local last = 0
	return function(mph: number, g: string, rpm: number)
		setSpeed(mph)
		setRpm(rpm)
		gear.Text = if tonumber(g) then "D" else g
		speed.Text = spd(mph)
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
	text(bg, unit(), UDim2.fromScale(0.2, 0.76), UDim2.fromScale(0.06, 0.1), DIM, Enum.Font.Gotham)
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
		speed.Text = spd(mph)
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
	text(screen, unit(), UDim2.fromScale(0.82, 0.62), UDim2.fromScale(0.25, 0.3), DIM, Enum.Font.Gotham)
	local gear = text(bg, "N", UDim2.fromScale(0.5, 0.6), UDim2.fromScale(0.03, 0.08), Color3.fromRGB(255, 140, 40), Enum.Font.GothamBold)
	return function(mph: number, g: string, rpm: number)
		setRpm(rpm)
		speed.Text = spd(mph)
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
	text(bg, unit(), UDim2.fromScale(0.5, 0.63), UDim2.fromScale(0.03, 0.05), DIM, Enum.Font.Gotham)
	local gear = text(bg, "N", UDim2.fromScale(0.5, 0.78), UDim2.fromScale(0.03, 0.1), accent, Enum.Font.GothamBold)
	bar(bg, UDim2.fromScale(0.16, 0.5), WHITE, "FUEL", 0.72)
	bar(bg, UDim2.fromScale(0.24, 0.5), WHITE, "TEMP", 0.5)
	text(bg, "TRIP A", UDim2.fromScale(0.8, 0.36), UDim2.fromScale(0.07, 0.06), DIM, Enum.Font.Gotham)
	text(bg, "128.4 mi", UDim2.fromScale(0.8, 0.46), UDim2.fromScale(0.1, 0.08), WHITE, Enum.Font.GothamMedium)
	local clockText = text(bg, clock(), UDim2.fromScale(0.8, 0.64), UDim2.fromScale(0.07, 0.08), WHITE, Enum.Font.Gotham)
	local last = 0
	return function(mph: number, g: string, rpm: number)
		setRpm(rpm)
		speed.Text = spd(mph)
		gear.Text = g
		if os.clock() - last > 5 then
			last = os.clock()
			clockText.Text = clock()
		end
	end
end

-- Lexus LFA (owner's photo of the real screen, 2026-10-23): a black screen with one big round rev
-- counter: a thick white ring with black numbers 0-10 (squeezed below 4000), red from just before
-- 9, a thin red needle; inside it on black, the speed in big white digits with the unit, a thin
-- line, the gear and SPORT, "x1000 r/min" bottom right. Either side, arcs following the ring:
-- coolant and fuel on the left with the temperature read-out, oil temperature and pressure on the
-- right with the clock. Only the needle, the speed and the gear move.
local LFA_SCALE = { { 0, -180 }, { 2000, -151 }, { 4000, -123 }, { 5000, -91.5 }, { 6000, -61 }, { 7000, -31 }, { 8000, 0 }, { 9000, 31 }, { 10000, 63 } }
local function lfaAngle(rpm: number): number
	rpm = math.clamp(rpm, 0, 10000)
	for k = 1, #LFA_SCALE - 1 do
		local a, b = LFA_SCALE[k], LFA_SCALE[k + 1]
		if rpm <= b[1] then
			return a[2] + (b[2] - a[2]) * (rpm - a[1]) / (b[1] - a[1])
		end
	end
	return LFA_SCALE[#LFA_SCALE][2]
end

local function lfa(gui: SurfaceGui): Update
	local INK = Color3.fromRGB(10, 10, 12)
	local RING = Color3.fromRGB(236, 236, 232)
	local LFA_RED = Color3.fromRGB(232, 40, 30)
	local GREY = Color3.fromRGB(120, 122, 126)
	local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(0, 0, 0), BorderSizePixel = 0 }, gui)
	local box = squareBox(bg, UDim2.fromScale(0.5, 0.5), 0.6) -- (as on the real screen: the ring is about 0.6 of its height)
	local function disc(size: number, color: Color3, z: number)
		new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(size, size),
			BackgroundColor3 = color,
			BorderSizePixel = 0,
			ZIndex = z,
		}, box))
	end
	-- something drawn at an angle round the middle (a turned full-size holder)
	local function spoke(angle: number, z: number): Frame
		return new("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			Rotation = angle,
			ZIndex = z,
		}, box)
	end
	-- the white ring, its red zone (overlapping wedges on the ring), the black middle
	disc(1, RING, 1)
	local r0, r1 = lfaAngle(8750), lfaAngle(9900)
	for a = r0, r1, 2.5 do
		new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0), Size = UDim2.fromScale(0.07, 0.18), BackgroundColor3 = LFA_RED, BorderSizePixel = 0, ZIndex = 2 }, spoke(a, 2))
	end
	disc(0.66, Color3.fromRGB(0, 0, 0), 3)
	-- ticks on the ring's outer edge and the numbers on it
	for rpm = 0, 10000, 250 do
		local major = rpm % 1000 == 0
		if rpm < 4000 and not major and rpm % 500 ~= 0 then
			continue -- (the squeezed bottom of the scale has fewer ticks)
		end
		local red = rpm >= 8750 and rpm < 9900
		new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.004),
			Size = UDim2.fromScale(if major then 0.01 else 0.006, if major then 0.05 else 0.028),
			BackgroundColor3 = if red then Color3.fromRGB(255, 255, 255) else INK,
			BorderSizePixel = 0,
			ZIndex = 4,
		}, spoke(lfaAngle(rpm), 4))
	end
	for _, v in { 0, 2, 4, 5, 6, 7, 8, 9, 10 } do
		local ang = math.rad(lfaAngle(v * 1000))
		local rr = 0.405
		local num = text(box, tostring(v), UDim2.fromScale(0.5 + math.sin(ang) * rr, 0.5 - math.cos(ang) * rr), UDim2.fromScale(0.09, 0.075), if v == 9 then Color3.fromRGB(255, 255, 255) else INK, Enum.Font.GothamMedium)
		num.ZIndex = 5
	end
	-- the needle: from near the middle out across the ring
	local needle = spoke(lfaAngle(0), 7)
	new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.05), Size = UDim2.fromScale(0.012, 0.32), BackgroundColor3 = LFA_RED, BorderSizePixel = 0, ZIndex = 7 }, needle)
	-- inside: speed, unit, line, gear, SPORT, x1000 r/min
	local speed = text(box, "0", UDim2.fromScale(0.5, 0.32), UDim2.fromScale(0.22, 0.13), WHITE, Enum.Font.GothamMedium)
	speed.ZIndex = 6
	local unitText = text(box, unit(), UDim2.fromScale(0.5, 0.41), UDim2.fromScale(0.08, 0.035), WHITE, Enum.Font.Gotham)
	unitText.ZIndex = 6
	new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.435), Size = UDim2.fromScale(0.3, 0.005), BackgroundColor3 = Color3.fromRGB(200, 200, 200), BorderSizePixel = 0, ZIndex = 6 }, box)
	local gear = text(box, "N", UDim2.fromScale(0.5, 0.535), UDim2.fromScale(0.12, 0.11), WHITE, Enum.Font.GothamBold)
	gear.ZIndex = 6
	local mode = text(box, "SPORT", UDim2.fromScale(0.5, 0.61), UDim2.fromScale(0.1, 0.035), WHITE, Enum.Font.GothamMedium)
	mode.ZIndex = 6
	local x1000 = text(box, "x1000\nr/min", UDim2.fromScale(0.62, 0.87), UDim2.fromScale(0.09, 0.055), WHITE, Enum.Font.Gotham)
	x1000.ZIndex = 6
	-- the side arcs round the ring: grey track with a white filled part, end labels
	local side = squareBox(bg, UDim2.fromScale(0.5, 0.5), 0.93)
	local function arcPoint(angle: number, rr: number): UDim2
		local a = math.rad(angle)
		return UDim2.fromScale(0.5 + math.sin(a) * rr, 0.5 - math.cos(a) * rr)
	end
	local function arc(a0: number, a1: number, fill: number, labels: { { number | string } })
		local n = 16
		for k = 0, n do
			local f = k / n
			local a = a0 + (a1 - a0) * f
			new("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = arcPoint(a, 0.47),
				Size = UDim2.fromScale(0.012, 0.012 * 1.6),
				Rotation = a,
				BackgroundColor3 = if f <= fill then Color3.fromRGB(220, 222, 226) else GREY,
				BorderSizePixel = 0,
			}, side)
		end
		for _, l in labels do
			local a = a0 + (a1 - a0) * (l[1] :: number)
			text(side, l[2] :: string, arcPoint(a, 0.43), UDim2.fromScale(0.05, 0.022), WHITE, Enum.Font.Gotham)
		end
	end
	-- left: coolant (top, 100-265 F) and fuel (bottom); right: oil temperature and pressure
	arc(-58, -96, 0.55, { { 0, "265°F" }, { 0.45, "210" }, { 0.75, "160" }, { 1, "100" } })
	arc(-104, -125, 0.85, { { 0, "1/1" }, { 1, "E" } })
	arc(58, 96, 0.5, { { 0, "320°F" }, { 0.5, "210" }, { 1, "100" } })
	arc(104, 125, 0.4, { { 0, "8" }, { 0.5, "4" }, { 1, "0" } })
	text(side, "x100kPa", arcPoint(122, 0.43) + UDim2.fromScale(0.03, 0.02), UDim2.fromScale(0.05, 0.016), WHITE, Enum.Font.Gotham)
	text(side, "180°F", arcPoint(-100, 0.36), UDim2.fromScale(0.07, 0.03), WHITE, Enum.Font.GothamMedium)
	local clockText = text(side, clock(), arcPoint(100, 0.36), UDim2.fromScale(0.07, 0.03), WHITE, Enum.Font.GothamMedium)
	local shown = 0
	local last = 0
	return function(mph: number, g: string, rpm: number)
		-- rpm is 0..1 of the car's own range; the LFA's scale is 0-10,000 with its limiter at 9,500
		shown += (math.clamp(rpm, 0, 1) * 9500 - shown) * 0.35
		needle.Rotation = lfaAngle(shown)
		speed.Text = spd(mph)
		unitText.Text = unit()
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
	local setSpeed = speedDial(bg, UDim2.fromScale(0.2, 0.55), 0.78, 200, 40, nil, needle, -135, 135, face)
	text(bg, unit(), UDim2.fromScale(0.2, 0.72), UDim2.fromScale(0.03, 0.045), DIM, Enum.Font.Gotham)
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
		setSpeed(mph)
		setRpm(rpm)
		gear.Text = g
		speed.Text = spd(mph)
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
	local speed = text(window, "0 " .. unit(), UDim2.fromScale(0.5, 0.8), UDim2.fromScale(0.85, 0.28), WHITE, Enum.Font.Gotham)
	bezel(bg, UDim2.fromScale(0.82, 0.52), 0.86, ring, 4)
	local setSpeed = speedDial(bg, UDim2.fromScale(0.82, 0.52), 0.82, 200, 40, nil, needle, -135, 135, face)
	text(bg, unit(true), UDim2.fromScale(0.82, 0.7), UDim2.fromScale(0.03, 0.045), DIM, Enum.Font.Gotham)
	return function(mph: number, g: string, rpm: number)
		setRpm(rpm)
		setSpeed(mph)
		gear.Text = g
		speed.Text = spd(mph) .. " " .. unit()
	end
end

-- Lamborghini Aventador LP750-4 SV (owner's photo of the real cluster): a dark screen in a grey
-- frame with a big yellow middle; on it a wide rev arc (2 to 10: grey-blue ticks, then red from 6,
-- black / bright red as they light), a big gear letter and the R 1234567 A strip; under it the
-- speed and the revs in big blue digits, STRADA and the odometer; small yellow screens either side
-- (clock, date, temperature / fuel) with bar gauges under them
local function aventadorSV(gui: SurfaceGui): Update
	local YELLOW = Color3.fromRGB(246, 210, 36)
	local INK = Color3.fromRGB(16, 16, 22)
	local DARK = Color3.fromRGB(12, 13, 16)
	local DIGIT = Color3.fromRGB(60, 170, 255)
	local LAMBO_RED = Color3.fromRGB(226, 26, 30)
	local bg = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = DARK, BorderSizePixel = 0 }, gui)
	new("UICorner", { CornerRadius = UDim.new(0.16, 0) }, bg)
	new("UIStroke", { Color = Color3.fromRGB(70, 72, 78), Thickness = 6 }, bg)
	for _, xy in { { 0.04, 0.2 }, { 0.04, 0.8 }, { 0.96, 0.2 }, { 0.96, 0.8 } } do
		new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(xy[1], xy[2]), Size = UDim2.fromScale(0.012, 0.035), BackgroundColor3 = Color3.fromRGB(46, 48, 54), BorderSizePixel = 0 }, bg))
	end
	-- the yellow middle, its lower corners cut off at an angle
	local mid = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.05), Size = UDim2.fromScale(0.43, 0.72), BackgroundColor3 = YELLOW, BorderSizePixel = 0, ClipsDescendants = true }, bg)
	new("UICorner", { CornerRadius = UDim.new(0.04, 0) }, mid)
	for _, x in { 0, 1 } do
		new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, 1), Size = UDim2.fromScale(0.24, 0.62), Rotation = if x == 0 then 40 else -40, BackgroundColor3 = DARK, BorderSizePixel = 0, ZIndex = 2 }, mid)
	end
	-- the rev arc: an oval from 2 (lower left) over the top to 10 (lower right)
	local cx, cy, rx, ry = 0.5, 0.5, 0.165, 0.37
	local a0, a1 = -120, 120
	local segs: { { frame: Frame, at: number } } = {}
	local n = 44
	for i = 0, n - 1 do
		local f = i / (n - 1)
		local a = math.rad(a0 + (a1 - a0) * f)
		local seg = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(cx + math.sin(a) * rx, cy - math.cos(a) * ry),
			Size = UDim2.fromScale(0.006, 0.075),
			Rotation = math.deg(a),
			BorderSizePixel = 0,
			ZIndex = 3,
		}, bg)
		table.insert(segs, { frame = seg, at = 2 + 8 * f })
	end
	for v = 2, 10 do
		local a = math.rad(a0 + (a1 - a0) * (v - 2) / 8)
		local l = text(bg, tostring(v), UDim2.fromScale(cx + math.sin(a) * rx * 0.8, cy - math.cos(a) * ry * 0.74), UDim2.fromScale(0.03, 0.1), if v >= 6 then LAMBO_RED else INK, Enum.Font.GothamBlack)
		l.ZIndex = 4
	end
	local gear = text(bg, "N", UDim2.fromScale(0.5, 0.43), UDim2.fromScale(0.09, 0.34), INK, Enum.Font.GothamBlack)
	gear.ZIndex = 4
	-- R 1234567 A, the gear in use in red
	local order = { "R", "1", "2", "3", "4", "5", "6", "7", "A" }
	local gearLabels: { [string]: TextLabel } = {}
	for i, gname in order do
		local l = text(bg, gname, UDim2.fromScale(0.44 + (i - 1) * 0.015, 0.66), UDim2.fromScale(0.014, 0.065), INK, Enum.Font.GothamBold)
		l.ZIndex = 4
		gearLabels[gname] = l
	end
	local smallRed = text(bg, unit(), UDim2.fromScale(0.34, 0.72), UDim2.fromScale(0.03, 0.05), LAMBO_RED, Enum.Font.GothamBold)
	smallRed.ZIndex = 4
	local rpmTag = text(bg, "rpm", UDim2.fromScale(0.66, 0.72), UDim2.fromScale(0.03, 0.05), LAMBO_RED, Enum.Font.GothamBold)
	rpmTag.ZIndex = 4
	local strada = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.43, 0.775), Size = UDim2.fromScale(0.07, 0.05), BackgroundColor3 = Color3.fromRGB(20, 40, 80), BorderSizePixel = 0, ZIndex = 4 }, bg)
	text(strada, "STRADA", UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.9, 0.85), WHITE, Enum.Font.GothamBold).ZIndex = 5
	local odo = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.57, 0.775), Size = UDim2.fromScale(0.07, 0.05), BackgroundColor3 = INK, BorderSizePixel = 0, ZIndex = 4 }, bg)
	text(odo, "006365", UDim2.fromScale(0.5, 0.5), UDim2.fromScale(0.9, 0.85), WHITE, Enum.Font.GothamBold).ZIndex = 5
	-- the big blue digits under the yellow
	local speed = text(bg, "0", UDim2.fromScale(0.33, 0.87), UDim2.fromScale(0.06, 0.15), DIGIT, Enum.Font.GothamBold)
	speed.TextXAlignment = Enum.TextXAlignment.Right
	text(bg, unit(), UDim2.fromScale(0.385, 0.9), UDim2.fromScale(0.025, 0.05), DIGIT, Enum.Font.Gotham)
	local revs = text(bg, "900", UDim2.fromScale(0.65, 0.87), UDim2.fromScale(0.07, 0.15), DIGIT, Enum.Font.GothamBold)
	revs.TextXAlignment = Enum.TextXAlignment.Right
	text(bg, "SET", UDim2.fromScale(0.4, 0.96), UDim2.fromScale(0.025, 0.04), DIM, Enum.Font.Gotham)
	text(bg, "0.0", UDim2.fromScale(0.6, 0.96), UDim2.fromScale(0.025, 0.04), DIM, Enum.Font.Gotham)
	-- side screens: a yellow box, then two bar gauges (white, red at the top)
	local function sideBox(x: number): Frame
		local f = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(x, 0.3), Size = UDim2.fromScale(0.12, 0.24), BackgroundColor3 = YELLOW, BorderSizePixel = 0 }, bg)
		new("UICorner", { CornerRadius = UDim.new(0.08, 0) }, f)
		return f
	end
	local function barPair(x: number, values: { number })
		for i, v in values do
			local bx = x + (i - 1.5) * 0.04
			local back = new("Frame", { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.fromScale(bx, 0.86), Size = UDim2.fromScale(0.012, 0.34), BackgroundColor3 = Color3.fromRGB(40, 42, 48), BorderSizePixel = 0 }, bg)
			new("Frame", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.fromScale(1, v), BackgroundColor3 = WHITE, BorderSizePixel = 0 }, back)
			new("Frame", { Size = UDim2.fromScale(1, 0.18), BackgroundColor3 = LAMBO_RED, BorderSizePixel = 0 }, back)
			for k = 0, 4 do
				new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(bx - 0.009, 0.52 + k * 0.085), Size = UDim2.fromScale(0.008, 0.006), BackgroundColor3 = DIM, BorderSizePixel = 0 }, bg)
			end
		end
	end
	local left = sideBox(0.15)
	local clockText = text(left, clock(), UDim2.fromScale(0.5, 0.22), UDim2.fromScale(0.8, 0.3), INK, Enum.Font.GothamBold)
	text(left, os.date("%d.%m.%Y") :: string, UDim2.fromScale(0.5, 0.52), UDim2.fromScale(0.75, 0.2), INK, Enum.Font.GothamMedium)
	text(left, "52.0 °F", UDim2.fromScale(0.5, 0.8), UDim2.fromScale(0.65, 0.2), INK, Enum.Font.GothamMedium)
	barPair(0.15, { 0.55, 0.45 })
	local right = sideBox(0.85)
	new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.22, 0.5), Size = UDim2.fromScale(0.12, 0.36), BackgroundColor3 = INK, BorderSizePixel = 0 }, right)
	text(right, "72 L", UDim2.fromScale(0.62, 0.5), UDim2.fromScale(0.6, 0.4), INK, Enum.Font.GothamBold)
	barPair(0.85, { 0.6, 0.5 })
	local shown, last, lastGear = 0, 0, ""
	return function(mph: number, g: string, rpm: number)
		shown += (math.clamp(rpm, 0, 1) - shown) * 0.35
		local v = shown * 10
		for _, s in segs do
			local high = s.at >= 6
			s.frame.BackgroundColor3 = if s.at <= v then (if high then Color3.fromRGB(255, 24, 24) else INK) else (if high then Color3.fromRGB(122, 30, 30) else Color3.fromRGB(96, 108, 130))
		end
		gear.Text = g
		speed.Text = spd(mph)
		revs.Text = tostring(math.max(900, math.floor(shown * 8500 / 50) * 50))
		local key = if tonumber(g) then g elseif g == "R" then "R" else ""
		if key ~= lastGear then
			if gearLabels[lastGear] then
				gearLabels[lastGear].TextColor3 = INK
			end
			if gearLabels[key] then
				gearLabels[key].TextColor3 = LAMBO_RED
			end
			lastGear = key
		end
		if os.clock() - last > 5 then
			last = os.clock()
			clockText.Text = clock()
		end
	end
end

---------------------------------------------------------------------
-- Clusters drawn on a fixed design canvas (design pixels, W x H), kept in proportion inside the
-- panel, which is filled with the background colour so it covers the car's own screen
---------------------------------------------------------------------
type Design = {
	area: Frame,
	rect: (x: number, y: number, w: number, h: number, color: Color3, z: number?, rot: number?, transp: number?) -> Frame,
	round: (x: number, y: number, r: number, color: Color3?, z: number?, stroke: Color3?, strokeW: number?) -> Frame,
	seg: (cx: number, cy: number, a: number, r0: number, r1: number, w: number, color: Color3, z: number?, transp: number?) -> Frame,
	arc: (cx: number, cy: number, a0: number, a1: number, r: number, w: number, color: Color3, z: number?, transp: number?, step: number?) -> { Frame },
	label: (t: string, x: number, y: number, h: number, color: Color3, font: Enum.Font?, z: number?, wChars: number?) -> TextLabel,
	needle: (cx: number, cy: number, r0: number, r1: number, w: number, color: Color3, z: number?) -> Frame,
	line: (x0: number, y0: number, x1: number, y1: number, w: number, color: Color3, z: number?, transp: number?) -> Frame,
}

local function design(gui: SurfaceGui, W: number, H: number, bg: Color3): Design
	local back = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = bg, BorderSizePixel = 0 }, gui)
	local area = new("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
	}, back)
	new("UIAspectRatioConstraint", { AspectRatio = W / H }, area)
	-- canvas pixels per design pixel (the SurfaceGui is 300 canvas pixels high)
	local px = 300 / H
	local D = {} :: any
	D.area = area
	function D.rect(x: number, y: number, w: number, h: number, color: Color3, z: number?, rot: number?, transp: number?): Frame
		return new("Frame", {
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(x / W, y / H),
			Size = UDim2.fromScale(w / W, h / H),
			BackgroundColor3 = color,
			BackgroundTransparency = transp or 0,
			Rotation = rot or 0,
			ZIndex = z or 1,
		}, area)
	end
	function D.round(x: number, y: number, r: number, color: Color3?, z: number?, stroke: Color3?, strokeW: number?): Frame
		local f = D.rect(x, y, 2 * r, 2 * r, color or Color3.new(), z)
		f.BackgroundTransparency = if color then 0 else 1
		new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, f)
		if stroke then
			new("UIStroke", { Color = stroke, Thickness = (strokeW or 2) * px, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, f)
		end
		return f
	end
	-- a bar along the radius at angle a (degrees clockwise from 12) from r0 to r1
	function D.seg(cx: number, cy: number, a: number, r0: number, r1: number, w: number, color: Color3, z: number?, transp: number?): Frame
		local t = math.rad(a)
		local mid = (r0 + r1) / 2
		return D.rect(cx + mid * math.sin(t), cy - mid * math.cos(t), w, r1 - r0, color, z, a, transp)
	end
	-- an arc band of short segments; returns them in order (to light them up one by one)
	function D.arc(cx: number, cy: number, a0: number, a1: number, r: number, w: number, color: Color3, z: number?, transp: number?, step: number?): { Frame }
		local n = math.max(2, math.floor(math.abs(a1 - a0) / (step or 2.5)))
		local out = {}
		for i = 0, n - 1 do
			local a = a0 + (a1 - a0) * (i + 0.5) / n
			table.insert(out, D.seg(cx, cy, a, r - w / 2, r + w / 2, math.abs(a1 - a0) / n * math.pi / 180 * r + 1.2, color, z, transp))
		end
		return out
	end
	function D.label(t: string, x: number, y: number, h: number, color: Color3, font: Enum.Font?, z: number?, wChars: number?): TextLabel
		local l = text(area, t, UDim2.fromScale(x / W, y / H), UDim2.fromScale(h * 0.62 * (wChars or math.max(#t, 1)) / W, h / H), color, font)
		l.ZIndex = z or 3
		return l
	end
	-- a needle turning about (cx, cy): a bar from r0 (negative: a tail) to r1; turn it by Rotation
	function D.needle(cx: number, cy: number, r0: number, r1: number, w: number, color: Color3, z: number?): Frame
		local R = math.max(r1, -r0)
		local box = new("Frame", {
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(cx / W, cy / H),
			Size = UDim2.fromScale(2 * R / W, 2 * R / H),
			ZIndex = z or 4,
		}, area)
		new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, new("Frame", {
			BorderSizePixel = 0,
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, (R - r1) / (2 * R)),
			Size = UDim2.fromScale(w / (2 * R), (r1 - r0) / (2 * R)),
			BackgroundColor3 = color,
			ZIndex = z or 4,
		}, box))
		return box
	end
	function D.line(x0: number, y0: number, x1: number, y1: number, w: number, color: Color3, z: number?, transp: number?): Frame
		local dx, dy = x1 - x0, y1 - y0
		return D.rect((x0 + x1) / 2, (y0 + y1) / 2, w, math.sqrt(dx * dx + dy * dy), color, z, math.deg(math.atan2(dx, -dy)), transp)
	end
	return D :: Design
end

-- angle on a dial from a table of { value, angle } points (in order of value)
local function angleOn(points: { { number } }, v: number): number
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		if v <= b[1] or i == #points - 1 then
			return a[2] + (b[2] - a[2]) * math.clamp((v - a[1]) / (b[1] - a[1]), 0, if i == #points - 1 then 1 else 1)
		end
	end
	return points[#points][2]
end

-- BMW M3 F80 / M4 F82 (owner's photo): two dark dials in chrome rings, white numbers, red needles,
-- orange / red shift lights at the top of the rev counter, small fuel and oil temperature dials at
-- the sides, the M stripes, digital speed, outside temperature, odometers, gear and drive modes
local function bmwF80(gui: SurfaceGui): Update
	local D = design(gui, 1000, 420, Color3.fromRGB(12, 13, 16))
	local FACE = Color3.fromRGB(26, 27, 31)
	local INNER = Color3.fromRGB(16, 17, 20)
	local CHROME = Color3.fromRGB(196, 199, 205)
	local NEEDLE = Color3.fromRGB(232, 46, 30)
	local GREY = Color3.fromRGB(176, 179, 186)
	local function dialBase(cx: number, cy: number)
		D.round(cx, cy, 152, CHROME, 1)
		D.round(cx, cy, 148, FACE, 1)
		D.round(cx, cy, 62, INNER, 1)
	end
	-- speedometer: 0 at 7:30, top at 4:30
	local SX, SY = 300, 190
	dialBase(SX, SY)
	local top = if KMH then 320 else 200
	local step = if KMH then 40 else 20
	local function sAng(v: number): number
		return -135 + 270 * v / top
	end
	for v = 0, top, step / 2 do
		local major = v % step == 0
		D.seg(SX, SY, sAng(v), if major then 130 else 139, 148, if major then 4 else 2, if major then WHITE else GREY, 2)
		if major then
			local t = math.rad(sAng(v))
			D.label(tostring(v), SX + 106 * math.sin(t), SY - 106 * math.cos(t), 24, WHITE, Enum.Font.GothamMedium, 3)
		end
	end
	D.label(unit(), SX, SY - 42, 18, GREY, Enum.Font.GothamMedium, 3)
	local sNeedle = D.needle(SX, SY, -20, 140, 6, NEEDLE, 5)
	D.round(SX, SY, 16, Color3.fromRGB(18, 18, 20), 6, Color3.fromRGB(70, 70, 76), 2)
	-- rev counter: 4 at the top, 30 degrees per 1000 rpm
	local TX, TY = 700, 190
	dialBase(TX, TY)
	local function tAng(v: number): number
		return -120 + 30 * v
	end
	for v = 0, 8, 0.5 do
		local major = v % 1 == 0
		D.seg(TX, TY, tAng(v), if major then 130 else 139, 148, if major then 4 else 2, if major then WHITE else GREY, 2)
		if major and v > 0 then
			local t = math.rad(tAng(v))
			D.label(tostring(v), TX + 106 * math.sin(t), TY - 106 * math.cos(t), 26, WHITE, Enum.Font.GothamMedium, 3)
		end
	end
	D.arc(TX, TY, tAng(6.4), tAng(7.2), 144, 8, Color3.fromRGB(255, 140, 30), 3, 0, 3)
	D.arc(TX, TY, tAng(7.2), tAng(8), 144, 8, Color3.fromRGB(232, 30, 26), 3, 0, 3)
	D.label("1/min x 1000", TX, TY - 42, 15, GREY, Enum.Font.GothamMedium, 3)
	D.label("READY", TX - 72, TY + 52, 11, GREY, Enum.Font.GothamMedium, 3)
	local tNeedle = D.needle(TX, TY, -20, 140, 6, NEEDLE, 5)
	D.round(TX, TY, 16, Color3.fromRGB(18, 18, 20), 6, Color3.fromRGB(70, 70, 76), 2)
	-- small fuel (left) and oil temperature (right) dials
	for _, sd in { { 82, 265, { "0", "1/2", "1" }, 0.82 }, { 918, 265, if KMH then { "70", "120", "170" } else { "160", "250", "340" }, 0.45 } } do
		local x, y = sd[1] :: number, sd[2] :: number
		D.round(x, y, 64, CHROME, 1)
		D.round(x, y, 61, FACE, 1)
		local labels = sd[3] :: { string }
		for i, l in labels do
			local a = math.rad(-110 + (i - 1) * 110)
			D.seg(x, y, -110 + (i - 1) * 110, 50, 60, 3, WHITE, 2)
			D.label(l, x + 36 * math.sin(a), y - 36 * math.cos(a), 15, WHITE, Enum.Font.GothamMedium, 3)
		end
		local n = D.needle(x, y, -8, 52, 4, NEEDLE, 5)
		n.Rotation = -110 + 220 * (sd[4] :: number)
		D.round(x, y, 8, Color3.fromRGB(18, 18, 20), 6)
	end
	D.label(if KMH then "°C" else "°F", 918, 300, 12, GREY, Enum.Font.GothamMedium, 3)
	-- middle: M stripes, digital speed, outside temperature, odometers, gear, drive modes
	-- (brand mark removed: owner, 2026-10-17)
	local speedText = D.label("0", 492, 316, 34, WHITE, Enum.Font.GothamBold, 3, 3)
	local unitText = D.label(unit(), 548, 322, 14, GREY, Enum.Font.GothamMedium, 3, 4)
	D.label(if KMH then "+12 °C" else "+53 °F", 500, 352, 16, WHITE, Enum.Font.GothamMedium, 3)
	D.label("04868", 445, 388, 18, Color3.fromRGB(230, 160, 60), Enum.Font.GothamMedium, 3)
	D.label("070.4", 560, 388, 18, Color3.fromRGB(230, 160, 60), Enum.Font.GothamMedium, 3)
	local gearText = D.label("N", 700, 360, 40, WHITE, Enum.Font.GothamBold, 3, 1.6)
	D.label("Sport      Sport Plus", 700, 400, 12, Color3.fromRGB(120, 124, 132), Enum.Font.GothamMedium, 3)
	return function(mph: number, g: string, rpm: number)
		local v = if KMH then mph * 1.609 else mph
		sNeedle.Rotation = sAng(math.clamp(v, 0, top))
		tNeedle.Rotation = tAng(math.clamp(rpm, 0, 1) * 7.6)
		speedText.Text = spd(mph)
		unitText.Text = unit()
		gearText.Text = g
	end
end

-- BMW Live Cockpit (owner's photo, a G30 in Sport): black screen, two open dials with a dark red glow
-- that lights up red as they sweep, short red needles at the rim, big digital speed in the left and
-- the gear in the right, clock and outside temperature at the top, the M stripes with red road
-- lines under them, odometers at the bottom, small gauges at the far sides
local function bmwLiveCockpit(gui: SurfaceGui): Update
	local D = design(gui, 1000, 380, Color3.fromRGB(4, 4, 6))
	local RING = Color3.fromRGB(188, 191, 198)
	local GLOW = Color3.fromRGB(96, 10, 12)
	local LIT = Color3.fromRGB(214, 34, 30)
	local GREY = Color3.fromRGB(150, 152, 160)
	-- left: speed. km/h as on the real cluster; mph spread over the same sweep
	local LX, LY = 290, 200
	local sPts = if KMH then { { 0, -138 }, { 50, -100 }, { 100, -55 }, { 150, -11 }, { 200, 35 }, { 260, 93 } }
		else { { 0, -138 }, { 40, -80 }, { 80, -22 }, { 120, 35 }, { 160, 93 } }
	-- right: revs (x1000)
	local RX, RY = 710, 200
	local rPts = { { 0, -95 }, { 1, -66 }, { 2, -34 }, { 3, 0 }, { 4, 38 }, { 5, 73 }, { 6, 107 }, { 7, 137 } }
	local function dialFrame(cx: number, cy: number, pts: { { number } }, labels: { { number } }, redFrom: number?): { Frame }
		local a0, a1 = pts[1][2], pts[#pts][2]
		D.arc(cx, cy, a0 - 4, a1 + 4, 170, 3, RING, 2, 0, 2)
		D.arc(cx, cy, a0, a1, 145, 30, GLOW, 1, 0.1)
		D.arc(cx, cy, a0, a1, 118, 24, Color3.fromRGB(44, 5, 7), 1, 0.2)
		D.arc(cx, cy, a0, a1, 160, 2.5, Color3.fromRGB(200, 36, 36), 2, 0.1, 2)
		local lit = D.arc(cx, cy, a0, a1, 145, 30, LIT, 2, 1)
		local top = pts[#pts][1]
		local step = labels[2][1] - labels[1][1]
		for v = 0, top, step / 5 do
			local major = math.abs(v / step - math.floor(v / step + 0.5)) < 1e-6
			local red = redFrom ~= nil and v >= redFrom
			D.seg(cx, cy, angleOn(pts, v), if major then 150 else 156, 162, if major then 3 else 1.5, if red then Color3.fromRGB(255, 60, 50) else WHITE, 3)
		end
		for _, l in labels do
			local t = math.rad(angleOn(pts, l[1]))
			local red = redFrom ~= nil and l[1] >= redFrom
			D.label(tostring(l[2]), cx + 116 * math.sin(t), cy - 116 * math.cos(t), 24, if red then Color3.fromRGB(255, 70, 60) else WHITE, Enum.Font.GothamMedium, 3)
		end
		return lit
	end
	local sLabels = {}
	for _, p in sPts do
		table.insert(sLabels, { p[1], p[1] })
	end
	local sLit = dialFrame(LX, LY, sPts, sLabels, nil)
	local rLabels = {}
	for v = 0, 7 do
		table.insert(rLabels, { v, v })
	end
	local rLit = dialFrame(RX, RY, rPts, rLabels, 6)
	local sNeedle = D.needle(LX, LY, 118, 172, 7, Color3.fromRGB(246, 54, 44), 5)
	local rNeedle = D.needle(RX, RY, 118, 172, 7, Color3.fromRGB(246, 54, 44), 5)
	D.round(LX, LY, 74, Color3.fromRGB(0, 0, 0), 3)
	local speedText = D.label("0", LX, LY - 4, 72, WHITE, Enum.Font.GothamBold, 4, 3)
	local unitText = D.label(unit(), LX, LY + 44, 14, GREY, Enum.Font.GothamMedium, 4, 4)
	D.round(RX, RY, 74, Color3.fromRGB(0, 0, 0), 3)
	local gearText = D.label("P", RX, RY - 4, 80, WHITE, Enum.Font.GothamBold, 4, 1.4)
	D.label("1/min x1000", RX, RY + 48, 12, GREY, Enum.Font.GothamMedium, 4)
	-- middle: clock and temperature, the M stripes and red road lines, odometers
	D.rect(500, 48, 80, 2, Color3.fromRGB(70, 70, 78), 2)
	local clockText = D.label(clock(), 500, 72, 30, WHITE, Enum.Font.GothamMedium, 3)
	D.label(if KMH then "+14.5°C" else "+58°F", 500, 104, 14, GREY, Enum.Font.GothamMedium, 3)
	D.rect(500, 120, 80, 2, Color3.fromRGB(70, 70, 78), 2)
	-- (brand mark removed: owner, 2026-10-17)
	D.line(468, 205, 330, 330, 4, Color3.fromRGB(196, 30, 30), 2, 0.15)
	D.line(532, 205, 670, 330, 4, Color3.fromRGB(196, 30, 30), 2, 0.15)
	local bar = D.rect(500, 352, 340, 30, Color3.fromRGB(12, 12, 14), 2)
	new("UICorner", { CornerRadius = UDim.new(0.5, 0) }, bar)
	new("UIStroke", { Color = Color3.fromRGB(70, 70, 78), Thickness = 1.5 }, bar)
	D.label(if KMH then "TOTAL 82176 km" else "TOTAL 51063 mi", 418, 352, 13, WHITE, Enum.Font.GothamMedium, 3)
	D.label(if KMH then "TRIP 0053.7 km" else "TRIP 0033.4 mi", 585, 352, 13, WHITE, Enum.Font.GothamMedium, 3)
	-- far sides: oil temperature (left) and fuel (right) arcs
	D.arc(60, 300, -150, -40, 52, 9, Color3.fromRGB(150, 22, 24), 2, 0.1, 4)
	D.arc(60, 300, -150, -40, 59, 2, RING, 2, 0, 4)
	D.label(if KMH then "162 km" else "101 mi", 82, 340, 13, WHITE, Enum.Font.GothamMedium, 3)
	D.arc(940, 300, 40, 150, 52, 9, Color3.fromRGB(150, 22, 24), 2, 0.1, 4)
	D.arc(940, 300, 40, 150, 59, 2, RING, 2, 0, 4)
	D.label("AUTO H", 918, 235, 12, Color3.fromRGB(110, 220, 130), Enum.Font.GothamBold, 3)
	D.label("SPORT", 742, 352, 14, Color3.fromRGB(236, 80, 44), Enum.Font.GothamBold, 3)
	local function light(lit: { Frame }, frac: number)
		local n = math.floor(#lit * math.clamp(frac, 0, 1) + 0.5)
		for i, f in lit do
			f.BackgroundTransparency = if i <= n then 0.15 else 1
		end
	end
	local sTop = sPts[#sPts][1]
	return function(mph: number, g: string, rpm: number)
		local v = math.clamp(if KMH then mph * 1.609 else mph, 0, sTop)
		local revs = math.clamp(rpm, 0, 1) * 6.8
		sNeedle.Rotation = angleOn(sPts, v)
		rNeedle.Rotation = angleOn(rPts, revs)
		local s0, s1 = sPts[1][2], sPts[#sPts][2]
		light(sLit, (angleOn(sPts, v) - s0) / (s1 - s0))
		local r0, r1 = rPts[1][2], rPts[#rPts][2]
		light(rLit, (angleOn(rPts, revs) - r0) / (r1 - r0))
		speedText.Text = spd(mph)
		unitText.Text = unit()
		gearText.Text = g
		clockText.Text = clock()
	end
end

-- Lexus LX 700h's 12.3-inch digital meter: a big ringed rev counter in the middle with a blue sweep,
-- the digital speed and gear inside it; the hybrid system indicator (CHG / ECO / PWR) and fuel on
-- the left; clock, outside temperature, a lane-assist picture, READY and the odometer on the right
local function lexusLX700(gui: SurfaceGui): Update
	local D = design(gui, 1000, 420, Color3.fromRGB(6, 8, 12))
	local SILVER = Color3.fromRGB(176, 182, 194)
	local BLUE = Color3.fromRGB(70, 168, 255)
	local GREY = Color3.fromRGB(140, 148, 162)
	local CX, CY = 500, 212
	D.round(CX, CY, 176, SILVER, 1)
	D.round(CX, CY, 172, Color3.fromRGB(10, 12, 18), 1)
	D.round(CX, CY, 132, Color3.fromRGB(14, 17, 25), 1, Color3.fromRGB(56, 64, 80), 2)
	local function ang(v: number): number
		return -135 + 270 * v / 8
	end
	for v = 0, 8, 0.5 do
		local major = v % 1 == 0
		D.seg(CX, CY, ang(v), if major then 152 else 160, 168, if major then 4 else 2, if v >= 6.5 then Color3.fromRGB(240, 60, 50) else WHITE, 3)
		if major then
			local t = math.rad(ang(v))
			D.label(tostring(v), CX + 116 * math.sin(t), CY - 116 * math.cos(t), 22, Color3.fromRGB(214, 220, 232), Enum.Font.GothamMedium, 3)
		end
	end
	D.arc(CX, CY, ang(0), ang(8), 143, 6, Color3.fromRGB(24, 34, 52), 2, 0)
	local sweep = D.arc(CX, CY, ang(0), ang(8), 143, 6, BLUE, 3, 1)
	local speedText = D.label("0", CX, CY + 2, 92, WHITE, Enum.Font.GothamBold, 4, 3)
	local unitText = D.label(unit(), CX, CY + 56, 16, GREY, Enum.Font.GothamMedium, 4, 4)
	local gearBox = D.rect(CX, CY - 78, 46, 36, Color3.fromRGB(14, 17, 25), 4)
	new("UICorner", { CornerRadius = UDim.new(0.2, 0) }, gearBox)
	new("UIStroke", { Color = Color3.fromRGB(130, 140, 160), Thickness = 1.5 }, gearBox)
	local gearText = D.label("P", CX, CY - 78, 26, WHITE, Enum.Font.GothamBold, 5, 1.4)
	D.label("x1000r/min", CX, CY + 92, 12, GREY, Enum.Font.GothamMedium, 4)
	D.label("NORMAL", CX, 400, 15, BLUE, Enum.Font.GothamBold, 3)
	-- left: hybrid system indicator and fuel
	D.label("HYBRID SYSTEM", 185, 100, 13, GREY, Enum.Font.GothamMedium, 3)
	D.rect(125, 140, 80, 10, Color3.fromRGB(40, 120, 220), 2)
	D.rect(205, 140, 80, 10, Color3.fromRGB(50, 190, 170), 2)
	D.rect(285, 140, 80, 10, Color3.fromRGB(70, 74, 86), 2)
	D.label("CHG", 105, 168, 12, GREY, Enum.Font.GothamMedium, 3)
	D.label("ECO", 205, 168, 12, GREY, Enum.Font.GothamMedium, 3)
	D.label("PWR", 300, 168, 12, GREY, Enum.Font.GothamMedium, 3)
	local hybrid = D.rect(125, 140, 4, 26, WHITE, 4)
	D.label("E", 98, 292, 14, GREY, Enum.Font.GothamMedium, 3)
	D.label("F", 290, 292, 14, GREY, Enum.Font.GothamMedium, 3)
	for i = 1, 8 do
		D.rect(110 + i * 19.5, 292, 15, 12, if i <= 6 then WHITE else Color3.fromRGB(46, 50, 60), 2)
	end
	D.label(if KMH then "620 km" else "385 mi", 194, 330, 20, WHITE, Enum.Font.GothamMedium, 3)
	-- right: clock, temperature, lane picture, READY, odometer
	local clockText = D.label(clock(), 815, 92, 28, WHITE, Enum.Font.GothamMedium, 3)
	D.label(if KMH then "24°C" else "75°F", 815, 124, 15, GREY, Enum.Font.GothamMedium, 3)
	D.line(772, 320, 798, 186, 3, Color3.fromRGB(110, 120, 140), 2)
	D.line(858, 320, 832, 186, 3, Color3.fromRGB(110, 120, 140), 2)
	local car = D.rect(815, 288, 34, 22, Color3.fromRGB(200, 206, 218), 3)
	new("UICorner", { CornerRadius = UDim.new(0.3, 0) }, car)
	D.label("READY", 815, 350, 15, Color3.fromRGB(80, 220, 120), Enum.Font.GothamBold, 3)
	D.label(if KMH then "ODO 2315 km" else "ODO 1438 mi", 815, 388, 13, GREY, Enum.Font.GothamMedium, 3)
	return function(mph: number, g: string, rpm: number)
		local r = math.clamp(rpm, 0, 1)
		local n = math.floor(#sweep * r * 6.4 / 8 + 0.5)
		for i, f in sweep do
			f.BackgroundTransparency = if i <= n then 0 else 1
		end
		-- the hybrid needle: charging when coasting, eco when easy, power when pushing
		hybrid.Position = UDim2.fromScale((95 + 230 * r) / 1000, 140 / 420)
		speedText.Text = spd(mph)
		unitText.Text = unit()
		gearText.Text = g
		clockText.Text = clock()
	end
end

-- Aventador LP700-4 (owner, 2026-10-17: "watch the aventador cluster and copy exactly like that",
-- from an LP700-4 0-353 km/h video): one wide dark screen with grey angular side panels, a big round
-- rev counter in the middle (silver ring, black band with white 0-9, red from 8.5, a cyan ring
-- round a dark navy face, a cyan arc below), a white needle with a glowing red tip, slanted white
-- digital speed and a big red italic gear inside, a lime drive-mode badge and the odometer below.
-- Left: clock, date, outside temperature, two upright bar gauges with red tops and the fuel bar.
-- Right: water and oil temperature bars, a green light lamp, the range and the use bars.
-- The needle climbs smoothly with the revs and snaps straight down on each upshift, like the video.
-- No maker's name or badge on it (owner, 2026-10-17)
local function aventadorLP700(gui: SurfaceGui): Update
	local D = design(gui, 1000, 436, Color3.fromRGB(16, 16, 18))
	local PANEL = Color3.fromRGB(26, 30, 38)
	local EDGE = Color3.fromRGB(92, 98, 110)
	local SILVER = Color3.fromRGB(184, 190, 200)
	local BAND = Color3.fromRGB(8, 8, 10)
	local NAVY = Color3.fromRGB(11, 43, 76)
	local CYAN = Color3.fromRGB(0, 174, 239)
	local LRED = Color3.fromRGB(230, 26, 26)
	local TIP = Color3.fromRGB(255, 32, 32)
	local LIME = Color3.fromRGB(198, 223, 32)
	local GREY = Color3.fromRGB(160, 166, 178)
	local OFF = Color3.fromRGB(52, 58, 70)
	local function italic(l: TextLabel)
		l.FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Italic)
	end
	-- the side panels: grey edged, their outer corners cut at an angle
	for _, side in { -1, 1 } do
		local cx = 500 + side * 318
		D.rect(cx, 228, 330, 330, EDGE, 1)
		D.rect(cx, 228, 324, 324, PANEL, 1)
		for _, cy in { 63, 393 } do
			D.rect(cx + side * 165, cy, 120, 120, Color3.fromRGB(16, 16, 18), 1, 45)
		end
	end
	-- left: clock, date and outside temperature
	local clockText = D.label(clock(), 120, 116, 36, WHITE, Enum.Font.GothamMedium, 3)
	D.label(os.date("%d.%m.%Y") :: string, 120, 152, 15, GREY, Enum.Font.GothamMedium, 3)
	D.label(if KMH then "+14 °C" else "+57 °F", 120, 180, 17, WHITE, Enum.Font.GothamMedium, 3)
	-- thin amber rules between the lines of the screen (refs/aventador_lp700_cluster_lit_crop.jpg)
	for _, y in { 92, 136, 166, 198 } do
		D.rect(132, y, 150, 1.5, Color3.fromRGB(196, 120, 30), 2, 0, 0.35)
	end
	-- an upright bar gauge of white segments with red tops; returns a setter (0..1)
	local function column(x: number, name: string, value: number): (number) -> ()
		local segs: { Frame } = {}
		local N = 12
		for i = 1, N do
			local red = i >= N - 1
			table.insert(segs, D.rect(x, 322 - (i - 1) * 17, 22, 12, if red then LRED else WHITE, 2))
			if i % 3 == 1 then
				D.rect(x - 18, 322 - (i - 1) * 17, 7, 2, GREY, 2)
			end
		end
		D.label(name, x, 350, 12, GREY, Enum.Font.GothamMedium, 3)
		local function set(v: number)
			local lit = math.floor(v * N + 0.5)
			for i, s in segs do
				s.BackgroundTransparency = if i <= lit then 0 else 0.82
			end
		end
		set(value)
		return set
	end
	column(222, "OIL bar", 0.55)
	column(262, "BAR", 0.4)
	-- fuel along the lower left
	D.label("FUEL", 70, 374, 12, GREY, Enum.Font.GothamMedium, 3)
	for i = 1, 10 do
		D.rect(88 + i * 14, 374, 11, 11, if i == 1 then LRED elseif i <= 7 then WHITE else OFF, 2)
	end
	-- right: water and oil temperature, the light lamp, range and use
	local water = column(740, "H2O °C", 0.3)
	local oil = column(780, "OIL °C", 0.25)
	local lamp = D.rect(862, 118, 46, 22, Color3.fromRGB(70, 210, 90), 3)
	new("UICorner", { CornerRadius = UDim.new(0.4, 0) }, lamp)
	for i = -1, 1 do
		D.rect(895, 118 + i * 8, 14, 3, Color3.fromRGB(70, 210, 90), 3)
	end
	D.rect(812, 250, 18, 26, GREY, 3)
	D.rect(825, 244, 6, 14, GREY, 3)
	D.label(if KMH then "90 km" else "56 mi", 880, 250, 26, WHITE, Enum.Font.GothamMedium, 3)
	D.label(if KMH then "l/100km" else "mpg", 880, 290, 12, GREY, Enum.Font.GothamMedium, 3)
	for i = 1, 8 do
		D.rect(820 + i * 13, 330 - i * 2, 9, 14 + i * 4, if i <= 5 then WHITE else OFF, 2)
	end

	-- the rev counter: 0 at about 7:50, 9 at about 3:50, a gap at the bottom
	local CX, CY = 500, 218
	local function ang(v: number): number
		return -125 + 240 * v / 9
	end
	D.round(CX, CY, 212, SILVER, 2)
	D.round(CX, CY, 205, BAND, 2)
	D.arc(CX, CY, ang(8.5), ang(9), 196, 12, Color3.fromRGB(150, 12, 12), 3, 0, 1.5)
	for v = 0, 9, 0.25 do
		local major = v % 1 == 0
		local half = v % 0.5 == 0
		D.seg(CX, CY, ang(v), if major then 176 else if half then 186 else 192, 202, if major then 5 else 2.5, if v >= 8.5 then TIP else WHITE, 4)
		if major then
			local t = math.rad(ang(v))
			D.label(tostring(v), CX + 152 * math.sin(t), CY - 152 * math.cos(t), if v == 9 then 40 else 32, if v == 9 then LRED else WHITE, Enum.Font.GothamBold, 4)
		end
	end
	-- the lit sweep along the inside of the band, following the needle
	local sweep = D.arc(CX, CY, ang(0), ang(9), 129, 6, CYAN, 4, 1, 2.5)
	D.round(CX, CY, 125, CYAN, 4)
	D.round(CX, CY, 120, NAVY, 4)
	-- the cyan status arc below the middle
	D.arc(CX, CY, 125, 235, 100, 3, CYAN, 5, 0.15, 3)
	D.label("x1000 r/min", CX, CY - 62, 13, GREY, Enum.Font.GothamMedium, 5)
	local gearText = D.label("N", CX + 66, CY - 6, 78, LRED, Enum.Font.GothamBlack, 6, 1.2)
	italic(gearText)
	local speedText = D.label("0", CX + 40, CY + 62, 44, WHITE, Enum.Font.GothamBold, 6, 3)
	italic(speedText)
	local unitText = D.label(unit(), CX + 40, CY + 92, 14, GREY, Enum.Font.GothamMedium, 6, 4)
	local badge = D.rect(CX - 58, CY + 64, 72, 22, LIME, 6)
	new("UICorner", { CornerRadius = UDim.new(0.25, 0) }, badge)
	D.label("CORSA", CX - 58, CY + 64, 15, Color3.fromRGB(16, 20, 8), Enum.Font.GothamBlack, 7)
	D.label(if KMH then "002714 km" else "001686 mi", CX, CY + 160, 16, Color3.fromRGB(90, 220, 220), Enum.Font.GothamMedium, 4) -- cyan, like the real one
	-- the needle: a white arm with a glowing red tip
	local arm = D.needle(CX, CY, -24, 150, 7, WHITE, 8)
	local glow = D.needle(CX, CY, 148, 200, 13, TIP, 8)
	glow.ZIndex = 8
	for _, f in glow:GetChildren() do
		(f :: Frame).BackgroundTransparency = 0.6
	end
	local tip = D.needle(CX, CY, 146, 198, 6, TIP, 9)
	D.round(CX, CY, 20, Color3.fromRGB(14, 16, 22), 10, SILVER, 3)

	local born = os.clock()
	local shown, lastT, lastClock = 0, born, 0
	return function(mph: number, g: string, rpm: number)
		local now = os.clock()
		local dt = math.clamp(now - lastT, 0, 0.1)
		lastT = now
		-- the game's revs (0..1) run to the 8.5k limiter; a little bounce on the limiter
		local target = math.clamp(rpm, 0, 1) * 8.5
		if rpm >= 0.985 then
			target -= math.random() * 0.25
		end
		-- climbs smoothly, snaps down on an upshift
		local k = if target < shown - 0.3 then 30 else 14
		shown += (target - shown) * math.min(1, dt * k)
		local a = ang(shown)
		arm.Rotation = a
		glow.Rotation = a
		tip.Rotation = a
		local n = math.floor(#sweep * shown / 9 + 0.5)
		for i, f in sweep do
			f.BackgroundTransparency = if i <= n then 0.1 else 1
		end
		speedText.Text = spd(mph)
		unitText.Text = unit()
		gearText.Text = g
		-- the engine warms up as it is driven
		water(math.min(0.62, 0.3 + (now - born) / 600))
		oil(math.min(0.55, 0.25 + (now - born) / 900))
		if now - lastClock > 5 then
			lastClock = now
			clockText.Text = clock()
		end
	end
end

-- Bugatti Veyron 16.4 (2026-10-23, from real photos: imports/refs/veyron_cluster_lit_vitesse.jpg and
-- veyron_cluster_crop.png): black, five round dials in thin silver rings. The big rev counter in the
-- middle (white 0-8, "1/min x 1000", a wide blue band, red needle, a small grey screen low inside
-- with the gear and speed), the power meter left (0-1001 hp, blue band, red needle), the speedometer
-- right (to 280 mph, km/h inside, blue band, red needle) and two small dials up between them (fuel,
-- oil temperature). No maker's logo on the faces (owner, 2026-10-17)
local function veyron(gui: SurfaceGui): Update
	local D = design(gui, 1000, 436, Color3.fromRGB(5, 5, 7))
	local SILVER = Color3.fromRGB(200, 204, 212)
	local FACE = Color3.fromRGB(9, 10, 14)
	local VBLUE = Color3.fromRGB(46, 70, 210)
	local NEEDLE = Color3.fromRGB(235, 34, 30)
	local GREY = Color3.fromRGB(150, 154, 164)
	-- a dial: silver ring, face, blue band, ticks and numbers from a0 to a1 (degrees clockwise from 12);
	-- returns a setter (0..1) for its red needle
	local function vdial(cx: number, cy: number, r: number, labels: { string }, a0: number, a1: number, band: { number }?, numSize: number, minor: number?): (number) -> ()
		D.round(cx, cy, r, FACE, 2, SILVER, 3)
		local steps = #labels - 1
		local function ang(f: number): number
			return a0 + (a1 - a0) * f
		end
		if band then
			D.arc(cx, cy, ang(band[1]), ang(band[2]), r * 0.62, r * 0.16, VBLUE, 3, 0.1, 2)
		end
		local per = minor or 2
		for i = 0, steps * per do
			local f = i / (steps * per)
			local major = i % per == 0
			D.seg(cx, cy, ang(f), r * (if major then 0.84 else 0.89), r * 0.95, if major then 3.5 else 2, if major then Color3.new(1, 1, 1) else GREY, 4)
			if major then
				local t = math.rad(ang(f))
				D.label(labels[i // per + 1], cx + r * 0.7 * math.sin(t), cy - r * 0.7 * math.cos(t), numSize, Color3.new(1, 1, 1), Enum.Font.GothamMedium, 4)
			end
		end
		local arm = D.needle(cx, cy, -r * 0.14, r * 0.86, math.max(3, r * 0.035), NEEDLE, 8)
		D.round(cx, cy, r * 0.11, Color3.fromRGB(150, 154, 162), 9, SILVER, 2)
		local shown = 0
		return function(v: number)
			shown += (math.clamp(v, 0, 1) - shown) * 0.35
			arm.Rotation = ang(shown)
		end
	end
	-- the two small dials up between the big ones (not lit, like the photo)
	local function small(cx: number, label: string, v: number)
		D.round(cx, 70, 46, FACE, 2, SILVER, 2.5)
		D.arc(cx, 70, -120, 120, 38, 2, GREY, 3, 0.4, 6)
		D.label(label, cx, 98, 10, GREY, Enum.Font.GothamMedium, 4)
		D.needle(cx, 70, -6, 34, 3, NEEDLE, 5).Rotation = -120 + 240 * v
	end
	small(330, "FUEL", 0.7)
	small(670, "OIL °C", 0.45)

	-- the rev counter: 0 at the bottom left round to 8 at the bottom right
	local setRpm = vdial(500, 205, 200, numbers(0, 8, 1), -138, 138, { 0.2, 0.82 }, 30, 4)
	D.label("1/min x 1000", 500, 345, 13, GREY, Enum.Font.GothamMedium, 5)
	local screen = D.rect(500, 282, 92, 70, Color3.fromRGB(58, 62, 70), 5)
	new("UICorner", { CornerRadius = UDim.new(0.08, 0) }, screen)
	local gearText = D.label("P", 500, 268, 34, Color3.new(1, 1, 1), Enum.Font.GothamBold, 6, 1.2)
	local speedText = D.label("0", 500, 302, 16, Color3.fromRGB(220, 224, 232), Enum.Font.GothamMedium, 6, 4)
	-- the power meter (left) and the speedometer (right)
	local setPower = vdial(165, 262, 140, numbers(0, 1000, 100), -150, 120, { 0.1, 0.75 }, 17)
	D.label("hp", 165, 352, 13, GREY, Enum.Font.GothamMedium, 5)
	local speedLabels, endMph = speedScale(280, 20)
	local setSpeed = vdial(835, 262, 140, speedLabels, -125, 130, { 0.05, 0.6 }, if #speedLabels > 10 then 13 else 17)
	local unitText = D.label(unit(), 835, 352, 13, GREY, Enum.Font.GothamMedium, 5)

	local lastPower = 0
	return function(mph: number, g: string, rpm: number)
		setRpm(math.clamp(rpm, 0, 1) * 6.4 / 8) -- the W16's limiter is 6,400 rpm
		setSpeed(mph / endMph)
		-- power in use: the revs times how hard it is pulling (more at low speed), 1001 hp flat out
		local p = math.clamp(rpm, 0, 1) * (if mph > 1 then 1 else 0.2)
		lastPower += (p - lastPower) * 0.2
		setPower(lastPower * 1.001)
		gearText.Text = g
		speedText.Text = spd(mph) .. " " .. unit()
		unitText.Text = unit()
	end
end

-- the styles by name (the DashCluster panel's Style attribute)
local STYLES: { [string]: (SurfaceGui) -> Update } = {
	Veyron = veyron,
	Maybach57 = maybach,
	SU7 = function(gui)
		return evScreen(gui, Color3.fromRGB(255, 105, 0))
	end,
	U8 = function(gui)
		return evScreen(gui, Color3.fromRGB(60, 200, 230))
	end,
	RX8 = rx8,
	LFA = lfa, -- the real LFA screen (owner's photo)
	LexusLX = function(gui)
		return lexus(gui, 8, 6, Color3.fromRGB(80, 170, 255))
	end,
	Porsche718 = porsche718,
	GTR = gtr,
	AventadorSV = aventadorSV,
	BMWF80 = bmwF80,
	BMWLiveCockpit = bmwLiveCockpit,
	LexusLX700 = lexusLX700,
	AventadorLP700 = aventadorLP700,
}

-- screens lit but below the bloom, so the numbers stay sharp in first person (owner, 2026-10-17)
local BRIGHT = 1.1

function DashGauges.build(panel: BasePart): Update
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Gauges"
	gui.Face = Enum.NormalId.Back
	gui.CanvasSize = Vector2.new(math.floor(panel.Size.X / panel.Size.Y * 300), 300)
	gui.LightInfluence = 0
	gui.Brightness = BRIGHT
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
			gui.Brightness = BRIGHT * math.clamp(t / 0.5, 0, 1)
			local sweep = math.sin(math.clamp(t / SWEEP, 0, 1) * math.pi)
			update(math.max(mph, sweep * 180), g, math.max(rpm, sweep))
		else
			gui.Brightness = BRIGHT
			update(mph, g, rpm)
		end
	end
end

return DashGauges
