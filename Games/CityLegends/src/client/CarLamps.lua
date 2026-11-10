--[[
	The working lamps of the newest models (owner, 2026-11-06: "make proper working headlights", "the
	headlight and taillight NEEDS to work in its proper place"; 2026-11-07: "only do the hyper cars for
	now"). Each car in CARS has lamp shells in ReplicatedStorage.CarModels (LampFx_<role><L/R>, cut from
	the model's own lamp pieces by tools/lamps): HeadCore (projectors, LED strips), HeadGlass (the
	cover), TurnF, TurnR, Rev, and Tail where the model's own lens isn't a part of its own. Every other
	car keeps the old lights exactly: nothing here touches them.

	Beams: DRL (the strips glow with the engine on), low, high, off; Auto follows DayCycle and tunnels.
	A SpotLight stops at 60 studs, so high beam adds one more light further up the road.
	Real lights only on the player's car and the nearest few (Config.Lamps.NearCars); the rest glow.
	The driver's game sends the beam to the others through the "Beam" attribute (CarSignals).
]]

local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Cars = require(Shared:WaitForChild("Cars"))
local Config = require(Shared:WaitForChild("Config"))

local LookFx = require(script.Parent:WaitForChild("LookFx"))
local WorldFx = require(script.Parent:WaitForChild("WorldFx"))

local L = Config.Lamps
local AMBER = Color3.fromRGB(255, 140, 16)
local WHITE = Color3.fromRGB(255, 252, 244)

local CarLamps = {}

CarLamps.wet = 0 -- how wet it is (Driving.wet, set by Weather; Driving passes it on)

-- the models with shells (a trim on another car's model counts through Cars.modelOf)
CarLamps.CARS = {
	lexis_lfa = true, lexis_lfa_circuit = true,
	lambrini_lp570 = true, lambrini_lp560 = true, lambrini_huracan = true, lambrini_performante = true, lambrini_sto = true,
	lambrini_sterrato = true, lambrini_lp640 = true, lambrini_lp670 = true, lambrini_urusp = true, lambrini_countach = true,
	ferrara_california = true, ferrara_458spider = true, ferrara_458speciale = true,
	dearb_focus_rs = true, bentz_s680 = true, bentz_gls = true,
	lambrini_lp700 = true, lambrini_lp750 = true, lambrini_revuelto = true, lambrini_svj = true, lambrini_svj63 = true,
	bugotti_veyron = true, bugotti_veyron_sport = true, bugotti_veyron_top = true,
	bugotti_chiron = true, bugotti_chiron_pursport = true, bugotti_chiron_supersport = true,
	audy_r8 = true, -- (its shells cut from the 2010 model's own lamps, 2026-11-09)
	audy_r8_lw = true, -- (the 2011 model's own lamps, 2026-11-09)
	audy_r8_4s = true, -- (the 2016 model's own lamps, 2026-11-09)
	bnw_m5_e60 = true, -- (the 2009 model's own lamps, 2026-11-10)
} :: { [string]: boolean }

function CarLamps.has(id: string?): boolean
	return id ~= nil and CarLamps.CARS[Cars.modelOf(id)] == true
end

function CarLamps.hasModel(model: Model): boolean
	return CarLamps.has(model:GetAttribute("CarId") :: string?)
end

type Lamp = { [string]: BasePart }
type Car = {
	model: Model,
	root: BasePart,
	parts: Lamp,
	tails: { BasePart },
	beam: string?,
	left: boolean?,
	right: boolean?,
	rev: boolean?,
	lit: boolean?,
	glass: number, -- how see-through the cover is on low beam
	colour: Color3,
	source: Light?, -- the box car's SpotLight: Customs colours it, so its colour is the car's
	spots: { low: { SpotLight }, high: { SpotLight }, haze: { Beam }, glare: { ImageLabel } }?,
	near: boolean,
	own: boolean,
}

local cars: { [Model]: Car } = setmetatable({}, { __mode = "k" }) :: any
local tried: { [Model]: number } = setmetatable({}, { __mode = "k" }) :: any

local own: { model: Model?, beam: string, blinker: string, phase: boolean, rev: boolean } =
	{ model = nil, beam = "off", blinker = "", phase = false, rev = false }

local function build(model: Model): Car?
	local root = model.PrimaryPart
	if not root then
		return nil
	end
	local parts: Lamp = {}
	local tails: { BasePart } = {}
	local source: Light? = nil
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			local src = d:GetAttribute("SrcName")
			if type(src) == "string" and src:sub(1, 7) == "LampFx_" then
				parts[src:sub(8)] = d
			end
			if d:GetAttribute("TailLight") and d:GetAttribute("TailOff") then
				table.insert(tails, d)
			end
		elseif d:IsA("SpotLight") and d.Name ~= "LampBeam" then
			d.Enabled = false
			source = source or d
		end
	end
	if not (parts.HeadCoreL or parts.HeadGlassL) then
		return nil
	end
	return {
		model = model,
		root = root,
		parts = parts,
		tails = tails,
		glass = L.Glass[Cars.modelOf(model:GetAttribute("CarId") :: string)] or L.LowGlass,
		colour = if source then source.Color else WHITE,
		source = source,
		near = false,
		own = false,
	}
end

local function set(c: Car, name: string, transparency: number, colour: Color3?)
	for _, side in { "L", "R" } do
		local p = c.parts[name .. side]
		if p then
			p.Transparency = transparency
			if colour then
				p.Color = colour
			end
		end
	end
end

-- the real lights: made the first time a car needs them
local function makeSpots(c: Car)
	local spots = { low = {}, high = {}, haze = {}, glare = {} }
	c.spots = spots
	local root = c.root
	local function spot(at: Attachment, range: number, angle: number, brightness: number): SpotLight
		local s = Instance.new("SpotLight")
		s.Name = "LampBeam"
		s.Face = Enum.NormalId.Front
		s.Range = range
		s.Angle = angle
		s.Brightness = brightness
		s.Color = c.colour
		s.Shadows = false
		s.Enabled = false
		s.Parent = at
		return s
	end
	for _, side in { "L", "R" } do
		local lamp = c.parts["HeadGlass" .. side] or c.parts["HeadCore" .. side]
		local pos = root.CFrame:PointToObjectSpace(lamp.Position)
		local x = pos.X
		-- (from just ahead of the nose, level with the lamp: from the lamp itself it lights the bonnet)
		local length = (c.model:GetAttribute("Length") :: number?) or math.abs(pos.Z * 2)
		local origin = Vector3.new(x, pos.Y - 0.2, -(length / 2 + L.NoseGap))
		local function aim(name: string, tilt: number, out: number): Attachment
			local at = Instance.new("Attachment")
			at.Name = name
			at.CFrame = CFrame.new(origin) * CFrame.Angles(0, -math.rad(out) * math.sign(x), 0) * CFrame.Angles(math.rad(tilt), 0, 0)
			at.Parent = root
			return at
		end
		table.insert(spots.low, spot(aim("LampLow", L.LowTilt, L.LowOut), L.LowRange, L.LowAngle, L.LowBrightness))
		table.insert(spots.high, spot(aim("LampHigh", L.HighTilt, L.HighOut), L.HighRange, L.HighAngle, L.HighBrightness))
		-- the soft cone in rain and mist
		local a0 = Instance.new("Attachment")
		a0.Name = "LampHaze"
		a0.Position = pos
		a0.Parent = root
		local a1 = Instance.new("Attachment")
		a1.Name = "LampHazeEnd"
		a1.Position = pos + Vector3.new(x * 0.4, -1.2, -L.HazeLength)
		a1.Parent = root
		local b = Instance.new("Beam")
		b.Name = "LampBeam"
		b.Attachment0 = a0
		b.Attachment1 = a1
		b.Texture = L.HazeTexture
		b.TextureMode = Enum.TextureMode.Stretch
		b.FaceCamera = true
		b.LightEmission = 1
		b.LightInfluence = 0
		b.Width0 = 1
		b.Width1 = L.HazeWidth
		b.Segments = 2
		b.Color = ColorSequence.new(c.colour)
		b.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.86), NumberSequenceKeypoint.new(0.4, 0.92), NumberSequenceKeypoint.new(1, 1) })
		b.Enabled = false
		b.Parent = root
		table.insert(spots.haze, b)
		-- the glare from a car facing you
		if not c.own then
			local g = Instance.new("BillboardGui")
			g.Name = "LampGlare"
			g.Adornee = a0
			g.Size = UDim2.fromOffset(L.GlareSize, L.GlareSize)
			g.LightInfluence = 0
			g.MaxDistance = L.GlareDistance
			g.Parent = a0
			local i = Instance.new("ImageLabel")
			i.BackgroundTransparency = 1
			i.Size = UDim2.fromScale(1, 1)
			i.Image = L.GlareImage
			i.ImageTransparency = 1
			i.ImageColor3 = c.colour
			i.Parent = g
			table.insert(spots.glare, i)
		end
	end
	-- high beam's reach: a SpotLight's range ends at 60 studs
	local reach = Instance.new("Attachment")
	reach.Name = "LampReach"
	reach.CFrame = CFrame.new(0, L.ReachUp, -L.ReachAhead) * CFrame.Angles(math.rad(L.ReachTilt), 0, 0)
	reach.Parent = root
	table.insert(spots.high, spot(reach, L.ReachRange, L.ReachAngle, L.ReachBrightness))
end

local function hazy(): boolean
	local h = Lighting.ClockTime
	return CarLamps.wet > 0.3 or (LookFx.state.Fog == "Thick" and h > 4.5 and h < 9)
end

local function colourNow(c: Car): Color3
	local src = c.source
	if src and src.Parent then
		c.colour = src.Color
	end
	return c.colour
end

local function applyBeam(c: Car, beam: string)
	if c.beam == beam then
		return
	end
	c.beam = beam
	local colour = colourNow(c)
	if beam == "off" then
		set(c, "HeadCore", 1)
		set(c, "HeadGlass", 1)
	elseif beam == "drl" then
		set(c, "HeadCore", L.DrlCore, colour)
		-- (a model with no separate lamp pieces: the cover glows softly instead)
		set(c, "HeadGlass", if c.parts.HeadCoreL then 1 else L.DrlGlass, colour)
	elseif beam == "low" then
		set(c, "HeadCore", 0, colour)
		set(c, "HeadGlass", c.glass, colour)
	else
		set(c, "HeadCore", 0, colour)
		set(c, "HeadGlass", c.glass * L.HighGlass, colour)
	end
	-- other players' tail lamps follow their lights (your own: Driving)
	if not c.own then
		local on = beam == "low" or beam == "high"
		for _, t in c.tails do
			t.Transparency = if on then t:GetAttribute("TailOff") :: number else 1
		end
	end
end

local function applyTurn(c: Car, left: boolean, right: boolean)
	if c.left == left and c.right == right then
		return
	end
	c.left, c.right = left, right
	for side, on in { L = left, R = right } do
		for _, name in { "TurnF", "TurnR" } do
			local p = c.parts[name .. side]
			if p then
				p.Transparency = if on then 0 else 1
				p.Color = AMBER
			end
		end
	end
end

local function applyRev(c: Car, on: boolean)
	if c.rev ~= on then
		c.rev = on
		set(c, "Rev", if on then 0 else 1, WHITE)
	end
end

local function lightsFor(c: Car, cam: Vector3)
	local beam = c.beam
	local on = c.near and (beam == "low" or beam == "high")
	if on and not c.spots then
		makeSpots(c)
	end
	local spots = c.spots
	if not spots then
		return
	end
	local shadows = c.own and WorldFx.qualityScale() >= L.ShadowQuality
	local colour = colourNow(c)
	for _, s in spots.low do
		s.Enabled = on and beam == "low"
		s.Shadows = shadows
		s.Color = colour
	end
	for _, s in spots.high do
		s.Enabled = on and beam == "high"
		s.Color = colour
	end
	local haze = on and WorldFx.qualityScale() > 0.6 and hazy()
	for _, b in spots.haze do
		b.Enabled = haze
	end
	if #spots.glare > 0 then
		local toCam = cam - c.root.Position
		local facing = if toCam.Magnitude > 1 then c.root.CFrame.LookVector:Dot(toCam.Unit) else 0
		local strength = if on and facing > 0.55 then (facing - 0.55) / 0.45 else 0
		strength *= if beam == "high" then 0.85 else 0.45
		for _, i in spots.glare do
			i.ImageTransparency = 1 - strength
		end
	end
end

local folder: Instance? = nil
local tick12, tick2 = 0, 0

local function refreshNear(cam: Vector3)
	local list: { { c: Car, d: number } } = {}
	for model, c in cars do
		if model.Parent then
			local beam = c.beam
			if not c.own and (beam == "low" or beam == "high") then
				local to = c.root.Position - cam
				-- (behind the camera: its light can't be seen)
				local ahead = workspace.CurrentCamera ~= nil and workspace.CurrentCamera.CFrame.LookVector:Dot(to) > -30
				if ahead and to.Magnitude < L.NearDistance then
					table.insert(list, { c = c, d = to.Magnitude })
				end
			end
			c.near = c.own
		end
	end
	table.sort(list, function(a, b)
		return a.d < b.d
	end)
	local q = WorldFx.qualityScale()
	local n = if q <= 0.6 then 0 elseif q < 1 then L.NearCars // 2 elseif q > 1.1 then L.NearCars * 2 else L.NearCars
	for i = 1, math.min(n, #list) do
		list[i].c.near = true
	end
end

local function step(dt: number)
	tick12 += dt
	if tick12 < 1 / 12 then
		return
	end
	tick12 = 0
	folder = folder or workspace:FindFirstChild("PlayerCars")
	if not folder then
		return
	end
	local now = os.clock()
	local phase = (now % 0.8) < 0.4
	local cam = if workspace.CurrentCamera then workspace.CurrentCamera.CFrame.Position else Vector3.zero
	for _, model in (folder :: Instance):GetChildren() do
		if model:IsA("Model") and CarLamps.hasModel(model) then
			local c = cars[model]
			if not c and now - (tried[model] or 0) > 1 then
				tried[model] = now
				c = build(model) :: any
				if c then
					cars[model] = c
					set(c, "TurnF", 1, AMBER)
					set(c, "TurnR", 1, AMBER)
					set(c, "Rev", 1, WHITE)
				end
			end
			if c then
				local mine = model == own.model
				c.own = mine
				if mine then
					applyBeam(c, own.beam)
					local b = own.blinker
					applyTurn(c, own.phase and (b == "L" or b == "H"), own.phase and (b == "R" or b == "H"))
					applyRev(c, own.rev)
				else
					local b = (model:GetAttribute("Blinker") :: string?) or ""
					applyBeam(c, (model:GetAttribute("Beam") :: string?) or "off")
					applyTurn(c, phase and (b == "L" or b == "H"), phase and (b == "R" or b == "H"))
					applyRev(c, false)
				end
			end
		end
	end
	tick2 += 1
	if tick2 >= 6 then
		tick2 = 0
		refreshNear(cam)
	end
	for model, c in cars do
		if model.Parent then
			if c.own then
				c.near = true
			end
			lightsFor(c, cam)
		end
	end
end

---------------------------------------------------------------------
-- the driver: Auto / Low / High / Off, hold or double-tap to flash
---------------------------------------------------------------------
CarLamps.mode = "auto"
local ORDER = { auto = "low", low = "high", high = "off", off = "auto" }
local pressedAt: number? = nil
local flashUntil = 0
local lastTap = 0
local lastMode = "auto"
local dusk = false

-- how much of the night it is, as DayCycle.night (DayCycle needs Weather, which needs Driving, so not
-- from here: Lighting.ClockTime is what DayCycle set)
local function nightNow(): number
	local h = Lighting.ClockTime
	local function ramp(a: number, b: number): number
		local t = math.clamp((h - a) / (b - a), 0, 1)
		return t * t * (3 - 2 * t)
	end
	return if h < 12 then 1 - ramp(5.6, 7.6) else ramp(17.8, 19.9)
end

function CarLamps.reset()
	CarLamps.mode = "auto"
	pressedAt = nil
	flashUntil = 0
end

function CarLamps.press()
	pressedAt = os.clock()
end

-- a release: the new mode if it changed
function CarLamps.release(): string?
	local at = pressedAt
	pressedAt = nil
	if not at then
		return nil
	end
	local now = os.clock()
	if now - at >= L.HoldFlash then
		return nil
	end
	if now - lastTap < L.DoubleTap then
		-- the second tap: the first one's change is taken back, and it flashes
		lastTap = 0
		CarLamps.mode = lastMode
		flashUntil = now + L.FlashTime
		return CarLamps.mode
	end
	lastTap = now
	lastMode = CarLamps.mode
	CarLamps.mode = ORDER[CarLamps.mode]
	return CarLamps.mode
end

function CarLamps.beamFor(engineOn: boolean, inTunnel: boolean): string
	if not engineOn then
		return "off"
	end
	local now = os.clock()
	if now < flashUntil or (pressedAt ~= nil and now - pressedAt >= L.HoldFlash) then
		return "high"
	end
	local mode = CarLamps.mode
	if mode == "off" then
		return "off"
	elseif mode == "low" or mode == "high" then
		return mode
	end
	local night = nightNow()
	if night > L.AutoOn then
		dusk = true
	elseif night < L.AutoOff then
		dusk = false
	end
	return if dusk or inTunnel then "low" else "drl"
end

-- every frame from Driving: the player's car
function CarLamps.drive(model: Model?, beam: string, blinker: string, phase: boolean, rev: boolean)
	own.model = model
	own.beam = beam
	own.blinker = blinker
	own.phase = phase
	own.rev = rev
end

RunService.Heartbeat:Connect(step)

return CarLamps
