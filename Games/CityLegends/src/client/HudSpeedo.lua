--[[
	HudSpeedo (client): the HUD speedometer, bottom right while driving (bottom middle on phones),
	in two styles the player picks in Settings (owner, 2026-11-03, `City Legends/Prompts/Speedometer
	style setting (digital or analogue).md`). In both the speed is a big digital number; only the
	rev counter changes shape:
	  * Analogue: an arc rev dial (each car's own scale and redline) with a needle, the gear in a ring
	    in the middle, the units, the big speed number underneath.
	  * Digital: the gear in a box, the big speed number, the units, a flat rev bar underneath.
	Both: leading zeros of the speed dimmed, the redline zone in pink-red that flashes at the limiter,
	an LC light while launch control is held, an M beside the gear in manual. Thin white lines on a
	see-through dark backing (the game's HUD look); no logos, no neon.

	HudSpeedo.build(parent, isTouch) -> the holder frame ("Speedometer")
	HudSpeedo.setStyle("Analogue" | "Digital")
	HudSpeedo.setCar(redline x1000 rpm, electric)
	HudSpeedo.update(mph, gear, rpm 0..1 (1 = the redline), kmh, manual, launch)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Theme = Config.Theme

local HudSpeedo = {}

local WHITE = Color3.new(1, 1, 1)
local RED = Color3.fromRGB(255, 58, 104) -- pink-red redline
local DIM = 0.72 -- transparency of the dimmed leading zeros
local NUMBER_FONT = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy, Enum.FontStyle.Italic)
local LABEL_FONT = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold)

local function edge(f: GuiObject)
	local st = Instance.new("UIStroke")
	st.Color = Color3.new(0, 0, 0)
	st.Thickness = 1
	st.Transparency = 0.6
	st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	st.Parent = f
end

local function new(className: string, props: { [string]: any }): any
	local inst = Instance.new(className)
	local parent = props.Parent
	for k, v in props do
		if k ~= "Parent" then
			(inst :: any)[k] = v
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function text(props: { [string]: any }): TextLabel
	-- (owner, 2026-11-03: no background box) a soft dark outline keeps it readable on any scene
	props.TextStrokeColor3 = props.TextStrokeColor3 or Color3.new(0, 0, 0)
	props.TextStrokeTransparency = props.TextStrokeTransparency or 0.55
	if props.BackgroundTransparency == nil then
		props.BackgroundTransparency = 1
	end
	props.TextColor3 = props.TextColor3 or WHITE
	props.FontFace = props.FontFace or LABEL_FONT
	return new("TextLabel", props)
end

-- the speed as three digits, the leading zeros dimmed
local function speedRich(v: number): string
	local n = math.clamp(math.floor(v + 0.5), 0, 999)
	local s = string.format("%03d", n)
	local lead = if n >= 100 then 0 elseif n >= 10 then 1 else 2
	if lead == 0 then
		return s
	end
	return string.format('<font transparency="%.2f">%s</font>%s', DIM, string.sub(s, 1, lead), string.sub(s, lead + 1))
end

---------------------------------------------------------------------
-- State
---------------------------------------------------------------------
local isTouch = false
local holder: Frame
local style = "Analogue"
local redline = 7
local electric = false
local dialMax = 8

local analogue: Frame
local dialLayer: Frame -- ticks, numbers, the track (rebuilt per car)
local needleHolder: Frame
local aGear: TextLabel
local aTag: TextLabel
local aSpeed: TextLabel
local aUnits: TextLabel
local aLC: TextLabel
local aRed: { GuiObject } = {}

local digital: Frame
local dGear: TextLabel
local dTag: TextLabel
local dSpeed: TextLabel
local dUnits: TextLabel
local dLC: TextLabel
local barSegs: { Frame } = {}
local BAR_N = 40

local shown = 0 -- the rev reading on screen (0..1 of the dial), eased
local lastClock = os.clock()
local lastSpeed = -1
local lastGear = ""
local lastUnits = ""
local lastLit = -1
local lastFlash: boolean? = nil

---------------------------------------------------------------------
-- Analogue
---------------------------------------------------------------------
local A0, SWEEP = 220, 260 -- degrees: from bottom-left, clockwise round the top to bottom-right
local function angle(frac: number): number
	return A0 - math.clamp(frac, 0, 1.04) * SWEEP
end
local function polar(r: number, deg: number): UDim2
	local a = math.rad(deg)
	return UDim2.new(0.5, math.cos(a) * r, 0.5, -math.sin(a) * r)
end

local function buildDial()
	for _, c in dialLayer:GetChildren() do
		c:Destroy()
	end
	table.clear(aRed)
	local D = analogue.AbsoluteSize.X
	if D < 10 then
		D = if isTouch then 170 else 224
	end
	local R = D / 2 - 8
	local redFrac = redline / dialMax
	-- the track: a thin arc, the redline part bolder and pink-red
	local N = 72
	local seg = R * math.rad(SWEEP / N) + 1
	for i = 1, N do
		local f = (i - 0.5) / N
		local red = f >= redFrac
		local s = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = polar(R, angle(f)),
			Size = UDim2.fromOffset(seg, if red then 4 else 2),
			Rotation = 90 - angle(f),
			BackgroundColor3 = if red then RED else WHITE,
			BackgroundTransparency = if red then 0.05 else 0.55,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = dialLayer,
		})
		edge(s)
		if red then
			table.insert(aRed, s)
		end
	end
	-- ticks every 500 rpm, numbers every 1,000 (every 2,000 on a long electric scale)
	local numberStep = if dialMax > 10 then 2 else 1
	for t = 0, dialMax * 2 do
		local v = t / 2
		local major = t % 2 == 0
		local f = v / dialMax
		local red = v >= redline
		local len = if major then D * 0.055 else D * 0.03
		local tick = new("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = polar(R - 4 - len / 2, angle(f)),
			Size = UDim2.fromOffset(if major then 2 else 1, len),
			Rotation = 90 - angle(f),
			BackgroundColor3 = if red then RED else WHITE,
			BackgroundTransparency = if major then 0 else 0.3,
			BorderSizePixel = 0,
			ZIndex = 2,
			Parent = dialLayer,
		})
		edge(tick)
		if red then
			table.insert(aRed, tick)
		end
		if major and v % numberStep == 0 then
			local n = text({
				Text = tostring(v),
				TextSize = math.floor(D * 0.062),
				TextColor3 = if red then RED else WHITE,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = polar(R - 4 - D * 0.055 - D * 0.07, angle(f)),
				Size = UDim2.fromOffset(D * 0.12, D * 0.08),
				ZIndex = 2,
				Parent = dialLayer,
			})
			if red then
				table.insert(aRed, n)
			end
		end
	end
	text({
		Text = "x1000 rpm",
		TextSize = math.max(8, math.floor(D * 0.04)),
		TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(0.34, 0.62), -- (left of the ring, opposite the units)
		Size = UDim2.fromScale(0.3, 0.06),
		ZIndex = 2,
		Parent = dialLayer,
	})
	-- the needle: from outside the gear ring to the track
	for _, c in needleHolder:GetChildren() do
		c:Destroy()
	end
	local rIn = D * 0.16
	local needleBody = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0.5, -rIn),
		Size = UDim2.fromOffset(if isTouch then 2 else 3, R + 2 - rIn),
		BackgroundColor3 = WHITE,
		BorderSizePixel = 0,
		ZIndex = 5,
		Parent = needleHolder,
	})
	edge(needleBody)
	-- a short pink-red tip, so the reading is easy to pick out
	new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 0.5, -(R - D * 0.06)),
		Size = UDim2.fromOffset(if isTouch then 2 else 3, D * 0.06 + 2),
		BackgroundColor3 = RED,
		BorderSizePixel = 0,
		ZIndex = 6,
		Parent = needleHolder,
	})
end

local function buildAnalogue(D: number)
	analogue = new("Frame", {
		Name = "Analogue",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(1, 1),
		Size = UDim2.fromOffset(D, D),
		BackgroundTransparency = 1,
		Parent = holder,
	})
	-- (owner, 2026-11-03: no background) the dial floats on the screen; thin dark edges keep it readable
	dialLayer = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2, Parent = analogue })
	needleHolder = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 5,
		Parent = analogue,
	})
	-- the gear in a thin ring
	local ring = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(D * 0.26, D * 0.26),
		BackgroundTransparency = 1,
		ZIndex = 6,
		Parent = analogue,
	})
	new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = ring })
	new("UIStroke", { Color = WHITE, Thickness = 1.5, Transparency = 0.15, Parent = ring })
	aGear = text({ Text = "N", FontFace = NUMBER_FONT, TextSize = math.floor(D * 0.15), Size = UDim2.fromScale(1, 1), ZIndex = 7, Parent = ring })
	aTag = text({
		Text = "M",
		TextSize = math.max(9, math.floor(D * 0.05)),
		TextColor3 = RED,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(1, 3, 0.25, 0),
		Size = UDim2.fromOffset(D * 0.06, D * 0.06),
		Visible = false,
		ZIndex = 7,
		Parent = ring,
	})
	aLC = text({
		Text = "LC",
		TextSize = math.max(9, math.floor(D * 0.05)),
		TextColor3 = Theme.Background,
		BackgroundColor3 = WHITE,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.3),
		Size = UDim2.fromOffset(D * 0.13, D * 0.07),
		Visible = false,
		ZIndex = 7,
		Parent = analogue,
	})
	aLC.BackgroundTransparency = 0.05
	new("UICorner", { CornerRadius = UDim.new(0.3, 0), Parent = aLC })
	aUnits = text({
		Text = "KM/H",
		TextSize = math.max(9, math.floor(D * 0.055)),
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0.66, 0.62),
		Size = UDim2.fromScale(0.3, 0.07),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = 7,
		Parent = analogue,
	})
	aSpeed = text({
		Text = speedRich(0),
		RichText = true,
		FontFace = NUMBER_FONT,
		TextSize = math.floor(D * 0.24),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.81),
		Size = UDim2.fromScale(0.7, 0.24),
		ZIndex = 7,
		Parent = analogue,
	})
end

---------------------------------------------------------------------
-- Digital
---------------------------------------------------------------------
local function buildDigital(W: number, H: number)
	digital = new("Frame", {
		Name = "Digital",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(1, 1),
		Size = UDim2.fromOffset(W, H),
		BackgroundTransparency = 1, -- (owner, 2026-11-03: no background box)
		Visible = false,
		Parent = holder,
	})
	local pad = math.floor(H * 0.13)
	local barH = math.max(5, math.floor(H * 0.07))
	local top = H - pad - barH - pad * 0.6 -- the height above the bar
	-- the gear box
	local box = new("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, pad, 0, top / 2 + pad * 0.4),
		Size = UDim2.fromOffset(top * 0.62, top * 0.62),
		BackgroundTransparency = 1,
		Parent = digital,
	})
	new("UICorner", { CornerRadius = UDim.new(0, 6), Parent = box })
	new("UIStroke", { Color = WHITE, Thickness = 1.5, Transparency = 0.15, Parent = box })
	dGear = text({ Text = "N", FontFace = NUMBER_FONT, TextSize = math.floor(top * 0.46), Size = UDim2.fromScale(1, 1), Parent = box })
	dTag = text({
		Text = "M",
		TextSize = math.max(9, math.floor(top * 0.16)),
		TextColor3 = RED,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 1, 2),
		Size = UDim2.fromScale(1, 0.25),
		Visible = false,
		Parent = box,
	})
	local numLeft = pad + top * 0.62 + pad * 0.6
	dSpeed = text({
		Text = speedRich(0),
		RichText = true,
		FontFace = NUMBER_FONT,
		TextSize = math.floor(top * 0.95),
		TextXAlignment = Enum.TextXAlignment.Left,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, numLeft, 0, top / 2 + pad * 0.4),
		Size = UDim2.new(0, W * 0.5, 0, top),
		Parent = digital,
	})
	dUnits = text({
		Text = "KM/H",
		TextSize = math.max(10, math.floor(top * 0.2)),
		TextXAlignment = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -pad, 0, pad * 1.1),
		Size = UDim2.new(0, W * 0.25, 0, top * 0.25),
		Parent = digital,
	})
	dLC = text({
		Text = "LC",
		TextSize = math.max(9, math.floor(top * 0.17)),
		TextColor3 = Theme.Background,
		BackgroundColor3 = WHITE,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -pad, 0, pad * 1.1 + top * 0.32),
		Size = UDim2.fromOffset(top * 0.36, top * 0.22),
		Visible = false,
		Parent = digital,
	})
	dLC.BackgroundTransparency = 0.05
	new("UICorner", { CornerRadius = UDim.new(0.3, 0), Parent = dLC })
	-- the rev bar: segments left to right, the redline part pink-red
	local bar = new("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, pad, 1, -pad),
		Size = UDim2.new(1, -2 * pad, 0, barH),
		BackgroundTransparency = 1,
		Parent = digital,
	})
	local gap = 2
	local segW = ((W - 2 * pad) - gap * (BAR_N - 1)) / BAR_N
	for i = 1, BAR_N do
		barSegs[i] = new("Frame", {
			Position = UDim2.fromOffset((i - 1) * (segW + gap), 0),
			Size = UDim2.new(0, segW, 1, 0),
			BackgroundColor3 = WHITE,
			BackgroundTransparency = 0.78,
			BorderSizePixel = 0,
			Parent = bar,
		})
		edge(barSegs[i])
	end
end

local function colourBar(lit: number, flashOff: boolean)
	local redFrom = math.floor(redline / dialMax * BAR_N) + 1
	for i, s in barSegs do
		local red = i >= redFrom
		s.BackgroundColor3 = if red then RED else WHITE
		if i <= lit and not (red and flashOff) then
			s.BackgroundTransparency = if red then 0 else 0.05
		else
			s.BackgroundTransparency = if red then 0.55 else 0.78
		end
	end
end

---------------------------------------------------------------------
-- API
---------------------------------------------------------------------
local function layout()
	local a = style == "Analogue"
	analogue.Visible = a
	digital.Visible = not a
	holder.Size = if a then analogue.Size else digital.Size
end

function HudSpeedo.build(parent: Instance, touch: boolean): Frame
	isTouch = touch
	local D = if touch then 170 else 224
	local W, H = if touch then 236 else 300, if touch then 92 else 116
	holder = new("Frame", {
		Name = "Speedometer",
		AnchorPoint = if touch then Vector2.new(0.5, 1) else Vector2.new(1, 1),
		-- (on phones bottom-middle, between the pedals and the steering buttons, above the cash tab)
		Position = if touch then UDim2.new(0.5, 0, 1, -48) else UDim2.new(1, -24, 1, -24),
		Size = UDim2.fromOffset(D, D),
		BackgroundTransparency = 1,
		Parent = parent,
	})
	buildAnalogue(D)
	buildDigital(W, H)
	-- the analogue holder is the same size as the dial (centred children)
	analogue.AnchorPoint = Vector2.new(0.5, 1)
	analogue.Position = UDim2.fromScale(0.5, 1)
	digital.AnchorPoint = Vector2.new(0.5, 1)
	digital.Position = UDim2.fromScale(0.5, 1)
	buildDial()
	colourBar(0, false)
	layout()
	-- Studio test hook (Claude's screenshots): workspace attribute PreviewSpeedo switches the style
	if game:GetService("RunService"):IsStudio() then
		workspace:GetAttributeChangedSignal("PreviewSpeedo"):Connect(function()
			local v = workspace:GetAttribute("PreviewSpeedo")
			if type(v) == "string" then
				HudSpeedo.setStyle(v)
			end
		end)
	end
	return holder
end

function HudSpeedo.setStyle(s: string)
	style = if s == "Digital" then "Digital" else "Analogue"
	if holder then
		layout()
		lastSpeed, lastGear, lastUnits, lastLit, lastFlash = -1, "", "", -1, nil
	end
end

function HudSpeedo.getStyle(): string
	return style
end

function HudSpeedo.setCar(redlineK: number, isElectric: boolean)
	electric = isElectric
	redline = math.clamp(redlineK, 3, 20)
	dialMax = math.ceil(redline + 0.6)
	if holder then
		buildDial()
		lastLit, lastFlash = -1, nil
	end
end

function HudSpeedo.update(mph: number, gear: string, rpm: number, kmh: boolean, manual: boolean, launch: boolean)
	if not holder then
		return
	end
	local now = os.clock()
	local dt = math.clamp(now - lastClock, 0, 0.1)
	lastClock = now
	-- the reading: rpm 1 = the redline; eased so it never jitters
	local target = math.clamp(rpm, 0, 1.04) * redline / dialMax
	shown += (target - shown) * math.min(1, dt * 18)
	local limiter = rpm >= 0.97 and not electric
	local flashOff = limiter and (now * 10) % 2 < 1
	-- the speed: every frame, only when it changes (no flicker)
	local v = math.abs(mph) * (if kmh then 1.609 else 1)
	local vi = math.floor(v + 0.5)
	if vi ~= lastSpeed then
		lastSpeed = vi
		local t = speedRich(vi)
		aSpeed.Text = t
		dSpeed.Text = t
	end
	local units = if kmh then "KM/H" else "MPH"
	if units ~= lastUnits then
		lastUnits = units
		aUnits.Text = units
		dUnits.Text = units
	end
	local g = if electric and gear ~= "R" and gear ~= "N" then "D" else gear
	if g ~= lastGear then
		lastGear = g
		aGear.Text = g
		dGear.Text = g
		local col = if g == "R" then Theme.Warning elseif g == "N" then Theme.SubText else WHITE
		aGear.TextColor3 = col
		dGear.TextColor3 = col
	end
	aTag.Visible = manual and not electric
	dTag.Visible = manual and not electric
	aLC.Visible = launch
	dLC.Visible = launch
	if style == "Analogue" then
		needleHolder.Rotation = 90 - angle(shown)
		if flashOff ~= lastFlash then
			lastFlash = flashOff
			for _, o in aRed do
				o.Visible = not flashOff
			end
		end
	else
		local lit = math.floor(math.clamp(shown, 0, 1) * BAR_N + 0.5)
		if lit ~= lastLit or flashOff ~= lastFlash then
			lastLit = lit
			lastFlash = flashOff
			colourBar(lit, flashOff)
		end
	end
end

local _ = Players
return HudSpeedo
