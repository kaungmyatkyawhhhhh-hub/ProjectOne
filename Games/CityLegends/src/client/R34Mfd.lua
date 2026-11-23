--!strict
-- The Horizon BNR34's multi-function display (2026-11-21): the small screen on top of the dash (CarSkin.MFD_RECT
-- places the "DashMfd" part; Driving builds and feeds it). Like the real car's: three round gauges (BOOST with the
-- peak held, OIL TEMP, WATER TEMP) and a row of read-outs (THROTTLE %, INTAKE and EXHAUST temperature, VOLTS).
-- The game has no turbo, oil or exhaust model, so the numbers are made from the car's own revs, throttle, speed and
-- the time since the engine started (R34Mfd.step: boost that spools with the revs and lags, temperatures that warm
-- up over a few minutes and climb under load); the water temperature also moves the cluster's TEMP needle
-- (DashGauges.waterShare). Cheap on phones: the screen is redrawn 20 times a second and only while the camera is
-- in the car or close to it; the numbers keep running either way.

local DashGauges = require(script.Parent:WaitForChild("DashGauges"))

local R34Mfd = {}

R34Mfd.REDLINE = 8000 -- (CarStats: the RB26's 8,000)
R34Mfd.HZ = 20
R34Mfd.NEAR = 14 -- studs from the screen: redrawn only this close (or in the interior view)

export type Sim = {
	boost: number, -- x100 kPa (bar): -0.7 vacuum .. ~1.0 on full boost
	peak: number,
	peakT: number, -- seconds the peak has been held
	water: number, -- deg C
	oil: number,
	intake: number,
	exhaust: number,
	volt: number,
	thr: number, -- 0..1, eased
	run: number, -- seconds since the engine started
}

function R34Mfd.newSim(): Sim
	return { boost = 0, peak = 0, peakT = 0, water = 30, oil = 30, intake = 30, exhaust = 60, volt = 12.4, thr = 0, run = 0 }
end

local function ease(v: number, target: number, rate: number, dt: number): number
	return v + (target - v) * (1 - math.exp(-rate * dt))
end

-- one step of the made-up engine readings. rpmShare 0..1 of the redline, throttle 0..1
function R34Mfd.step(s: Sim, dt: number, rpmShare: number, throttle: number, on: boolean, mph: number)
	dt = math.clamp(dt, 0, 0.5)
	local rpm = math.clamp(rpmShare, 0, 1.05) * R34Mfd.REDLINE
	if not on then
		s.run = 0
		s.boost = ease(s.boost, 0, 3, dt)
		s.thr = ease(s.thr, 0, 10, dt)
		s.volt = ease(s.volt, 12.4, 2, dt)
		s.water = ease(s.water, 30, 0.004, dt)
		s.oil = ease(s.oil, 30, 0.004, dt)
		s.exhaust = ease(s.exhaust, 60, 0.05, dt)
		s.intake = ease(s.intake, 30, 0.05, dt)
		return
	end
	s.run += dt
	s.thr = ease(s.thr, math.clamp(throttle, 0, 1), 12, dt)
	-- boost: vacuum off the throttle; the twin turbos come in from ~3,000 and are full by ~4,500
	local spool = math.clamp((rpm - 2600) / 2000, 0, 1)
	local target = -0.7 + s.thr * (0.7 + 1.0 * spool) -- (1.0 bar: a stock car's full boost)
	local rate = if target > s.boost then 0.8 + 3.2 * spool else 7 -- lag up, the blow-off down
	s.boost = ease(s.boost, target, rate, dt)
	if s.boost >= s.peak then
		s.peak, s.peakT = s.boost, 0
	else
		s.peakT += dt
		if s.peakT > 4 then -- (held 4 s, then it falls back to the needle)
			s.peak = ease(s.peak, s.boost, 1.5, dt)
		end
	end
	-- temperatures: warm up over a few minutes (sped up for the game), then climb a little under load
	local load = s.thr * (0.4 + 0.6 * rpm / R34Mfd.REDLINE)
	local cool = math.clamp(mph / 60, 0, 1) -- air through the radiator
	s.water = ease(s.water, 84 + 10 * load - 4 * cool, 0.03, dt)
	s.oil = ease(s.oil, s.water + 6 + 18 * load, 0.02, dt)
	s.intake = ease(s.intake, 32 + 22 * math.max(s.boost, 0) - 4 * cool, 0.4, dt)
	s.exhaust = ease(s.exhaust, 320 + 560 * load + 120 * rpm / R34Mfd.REDLINE, 0.6, dt)
	s.volt = ease(s.volt, 14.2 - 0.25 * math.clamp(1 - rpm / 1500, 0, 1), 2, dt)
end

-- ------------------------------------------------------------------ the screen
local AMBER = Color3.fromRGB(255, 176, 48)
local DIM = Color3.fromRGB(58, 40, 12)
local RED = Color3.fromRGB(255, 64, 40)
local TEXT = Color3.fromRGB(255, 200, 110)
local BG = Color3.fromRGB(6, 8, 10)
local SEGS = 24

local function label(parent: Instance, text: string, x: number, y: number, w: number, h: number, size: number?, align: Enum.TextXAlignment?): TextLabel
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Position = UDim2.fromScale(x, y)
	t.Size = UDim2.fromScale(w, h)
	t.Font = Enum.Font.Code
	t.Text = text
	t.TextColor3 = TEXT
	t.TextScaled = true
	t.TextXAlignment = align or Enum.TextXAlignment.Center
	t.Parent = parent
	if size then
		local c = Instance.new("UITextSizeConstraint")
		c.MaxTextSize = size
		c.Parent = t
	end
	return t
end

-- a round gauge: an arc of segments from -125 to +125 degrees lit up to the value, the number in its middle
local function gauge(parent: Instance, cx: number, title: string, lo: number, hi: number, red: number)
	local box = Instance.new("Frame")
	box.BackgroundTransparency = 1
	box.AnchorPoint = Vector2.new(0.5, 0)
	box.Position = UDim2.fromScale(cx, 0.03)
	box.Size = UDim2.fromScale(0.3, 0.7)
	box.Parent = parent
	local ratio = Instance.new("UIAspectRatioConstraint")
	ratio.AspectRatio = 1
	ratio.Parent = box
	local segs: { Frame } = {}
	for i = 1, SEGS do
		local a = math.rad(-125 + 250 * (i - 0.5) / SEGS)
		local f = Instance.new("Frame")
		f.BorderSizePixel = 0
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromScale(0.5 + 0.42 * math.sin(a), 0.5 - 0.42 * math.cos(a))
		f.Size = UDim2.fromScale(0.035, 0.11)
		f.Rotation = math.deg(a)
		f.BackgroundColor3 = DIM
		f.Parent = box
		table.insert(segs, f)
	end
	local peak = Instance.new("Frame")
	peak.BorderSizePixel = 0
	peak.AnchorPoint = Vector2.new(0.5, 0.5)
	peak.Size = UDim2.fromScale(0.05, 0.16)
	peak.BackgroundColor3 = RED
	peak.Visible = false
	peak.Parent = box
	local value = label(box, "", 0.15, 0.36, 0.7, 0.28)
	label(box, title, 0.1, 0.72, 0.8, 0.16)
	local lit = -1
	local function set(v: number, pk: number?, text: string)
		local share = math.clamp((v - lo) / (hi - lo), 0, 1)
		local n = math.floor(share * SEGS + 0.5)
		if n ~= lit then -- (only the segments that changed)
			for i, f in segs do
				local on = i <= n
				local warm = lo + (hi - lo) * (i - 0.5) / SEGS >= red
				f.BackgroundColor3 = if on then (if warm then RED else AMBER) else DIM
			end
			lit = n
		end
		if pk then
			local a = math.rad(-125 + 250 * math.clamp((pk - lo) / (hi - lo), 0, 1))
			peak.Position = UDim2.fromScale(0.5 + 0.42 * math.sin(a), 0.5 - 0.42 * math.cos(a))
			peak.Rotation = math.deg(a)
			peak.Visible = true
		end
		value.Text = text
	end
	return set
end

-- the update for the car's DashMfd part, or nil when the model has none
function R34Mfd.build(model: Instance): ((dt: number, mph: number, rpmShare: number, throttle: number, on: boolean) -> ())?
	local panel = model:FindFirstChild("DashMfd", true)
	if not (panel and panel:IsA("BasePart")) then
		return nil
	end
	local old = panel:FindFirstChild("Mfd")
	if old then
		old:Destroy()
	end
	local gui = Instance.new("SurfaceGui")
	gui.Name = "Mfd"
	gui.Face = Enum.NormalId.Back -- (CarSkin: the back face looks at the driver)
	gui.CanvasSize = Vector2.new(math.floor(panel.Size.X / panel.Size.Y * 200), 200)
	gui.LightInfluence = 0 -- lit by day and night, like the real screen
	gui.Brightness = 1.1
	gui.MaxDistance = 40
	gui.Parent = panel
	local back = Instance.new("Frame")
	back.Size = UDim2.fromScale(1, 1)
	back.BackgroundColor3 = BG
	back.BorderSizePixel = 0
	back.Parent = gui
	local boost = gauge(back, 0.17, "BOOST", -1, 1.2, 1.0)
	local oil = gauge(back, 0.5, "OIL °C", 40, 140, 120)
	local water = gauge(back, 0.83, "WATER °C", 40, 130, 105)
	local row: { TextLabel } = {}
	for i, name in { "THR", "INT", "EXH", "VOLT" } do
		row[i] = label(back, name, (i - 1) * 0.25, 0.8, 0.25, 0.17, nil, Enum.TextXAlignment.Center)
	end
	local sim = R34Mfd.newSim()
	local acc = 0
	local wasOn = false
	return function(dt: number, mph: number, rpmShare: number, throttle: number, on: boolean)
		if on and not wasOn then
			sim.peak, sim.peakT = -1, 0 -- (a fresh start clears the peak)
		end
		wasOn = on
		R34Mfd.step(sim, dt, rpmShare, throttle, on, mph)
		DashGauges.waterShare = math.clamp((sim.water - 50) / 80, 0, 1) -- (the cluster's TEMP: C at 50, H at 130)
		acc += dt
		if acc < 1 / R34Mfd.HZ then
			return
		end
		acc = 0
		local cam = workspace.CurrentCamera
		local near = cam ~= nil and (cam.CFrame.Position - panel.Position).Magnitude < R34Mfd.NEAR
		gui.Enabled = near
		if not near then
			return
		end
		back.Visible = on -- (dark with the engine off)
		boost(sim.boost, sim.peak, string.format("%+.2f", sim.boost))
		oil(sim.oil, nil, string.format("%d", math.floor(sim.oil + 0.5)))
		water(sim.water, nil, string.format("%d", math.floor(sim.water + 0.5)))
		row[1].Text = string.format("THR %3d%%", math.floor(sim.thr * 100 + 0.5))
		row[2].Text = string.format("INT %d°", math.floor(sim.intake + 0.5))
		row[3].Text = string.format("EXH %d°", math.floor(sim.exhaust + 0.5))
		row[4].Text = string.format("%.1fV", sim.volt)
	end
end

return R34Mfd
