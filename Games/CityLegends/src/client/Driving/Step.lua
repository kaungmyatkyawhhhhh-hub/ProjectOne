--[[
	Driving.step: the car's physics step (client/Driving)
	Moved out of the parent module (2026-11-26: Studio caps a script at 200,000 characters).
	The parent calls this once with its locals; the ones it changes later (state, curP, keyThrottle) are read
	through getters, so this sees their live values exactly as before.
]]

return function(E: any)
	local Audio = E.Audio
	local CarPhysics = E.CarPhysics
	local Config = E.Config
	local DashGauges = E.DashGauges
	local Driving = E.Driving
	local HARD_SURFACE = E.HARD_SURFACE
	local LOOSE_SURFACE = E.LOOSE_SURFACE
	local Players = E.Players
	local RunService = E.RunService
	local UI = E.UI
	local WaterRescue = E.WaterRescue
	local buzz = E.buzz
	local cruiseOff = E.cruiseOff
	local cruisePedals = E.cruisePedals
	local detectCuts = E.detectCuts
	local evPull = E.evPull
	local exhaustPop = E.exhaustPop
	local forwardFromYaw = E.forwardFromYaw
	local gearHi = E.gearHi
	local gearMul = E.gearMul
	local gearsNow = E.gearsNow
	local hitMark = E.hitMark
	local indicatorState = E.indicatorState
	local nitroHeld = E.nitroHeld
	local noLiftPops = E.noLiftPops
	local noPops = E.noPops
	local noShiftPops = E.noShiftPops
	local rayParams = E.rayParams
	local readInput = E.readInput
	local reportCrash = E.reportCrash
	local roadOverlap = E.roadOverlap
	local roadRay = E.roadRay
	local setCarPower = E.setCarPower
	local setTails = E.setTails
	local skidMark = E.skidMark
	local sparks = E.sparks
	local torqueCurve = E.torqueCurve
	local waterState = E.waterState
	local wetAt = E.wetAt
	local yawFromLook = E.yawFromLook

	local rayModel: Instance?, rayTraffic: Instance? = nil, nil
	function Driving.step(dt: number)
		local s = E.get_state()
		if not s or not s.root.Parent then
			return
		end
		dt = math.min(dt, 1 / 20)
		local root = s.root
		local throttleKey, brake, steerIn, handbrake, clutch = readInput()
		-- Studio test hooks (Claude's driving tests): TestEngine starts the engine, TestGearbox sets it
		if RunService:IsStudio() then
			local tester = Players.LocalPlayer
			if tester:GetAttribute("TestEngine") and not s.engineOn and s.cranking <= 0 then
				s.cranking = 0.3
				s.ignition = true
			end
			local tp = tester:GetAttribute("TestTeleport")
			if typeof(tp) == "CFrame" then
				tester:SetAttribute("TestTeleport", nil)
				Driving.teleport(tp)
			end
			local gb = tester:GetAttribute("TestGearbox")
			if (gb == "Auto" or gb == "Manual") and (gb == "Manual") ~= s.manual and not s.electric then
				Driving.setGearbox(gb)
			end
			-- (2026-11-08) the driver aids for a test: TestTC / TestESC 0..2, TestABS, TestHelp 0..1
			local tc, esc, ab, hp = tester:GetAttribute("TestTC"), tester:GetAttribute("TestESC"), tester:GetAttribute("TestABS"), tester:GetAttribute("TestHelp")
			if type(tc) == "number" then
				Driving.tcMode = tc
			end
			if type(esc) == "number" then
				Driving.escMode = esc
			end
			if type(ab) == "boolean" then
				Driving.abs = ab
			end
			if type(hp) == "number" then
				Driving.help = hp
			end
		end
		-- steering help on phones (driving assists): a little less lock at speed, so a thumb can't flick
		-- the car round at 200 km/h
		if UI.isTouch and Driving.assist > 0 then
			steerIn *= 1 - Config.DrivingFeel.TouchSteerAssist * Driving.assist * math.clamp(s.vel.Magnitude / s.topSpeed, 0, 1)
		end
		-- the engine: the starter turns it over for a moment, then it runs; off, the pedal does nothing
		if s.cranking > 0 then
			s.cranking -= dt
			if s.cranking <= 0 and s.ignition then
				UI.startPrompt(false)
				s.engineOn = true
				s.warmT = os.clock()
				s.engine:setRunning(not s.electric)
				setCarPower(s, true)
				UI.setIndicators(indicatorState(s))
			end
		end
		-- (2026-11-07) out of fuel: it sputters, then the engine stops and the car coasts
		local careNow = s.care
		if careNow and careNow.empty and s.engineOn then
			if s.sputter <= 0 then
				s.sputter = 1.4
				UI.toast(if s.electric then "Battery empty" else "Out of fuel", Config.Theme.Warning)
			end
			s.sputter -= dt
			throttleKey = if math.sin(os.clock() * 19) > 0 then throttleKey else 0
			if s.sputter <= 0.02 then
				s.sputter = 0
				s.engineOn = false
				s.engine:setRunning(false)
				setCarPower(s, false)
				cruiseOff(s, true)
				UI.setIndicators(indicatorState(s))
			end
		elseif careNow and careNow.misfire and s.engineOn and not s.electric then
			-- under 30%: it stumbles now and then, a pop and a puff of smoke
			s.misT -= dt
			if s.misT <= 0.14 then
				throttleKey = 0
			end
			if s.misT <= 0 then
				s.misT = 1.2 + math.random() * 2.5
				Audio.backfire(s.root)
				if Driving.onMisfire then
					Driving.onMisfire()
				end
			end
		end
		throttleKey, brake = cruisePedals(s, throttleKey, brake, dt)
		-- (2026-11-08) a keyboard's on / off throttle eases in (full in about a sixth of a second) and drops quickly
		if E.get_keyThrottle() and s.axle then
			s.thrRamp += math.clamp(throttleKey - s.thrRamp, -dt * 12, dt * Config.DrivingFeel.Axle.KeyThrottleRamp)
			throttleKey = s.thrRamp
		else
			s.thrRamp = throttleKey
		end
		local throttle = if s.engineOn then throttleKey else 0
		-- (the wear the server can't see)
		local rep = s.report
		rep.thr += throttle
		rep.n += 1
		if s.rpm >= 0.97 and throttle > 0.5 and not s.electric then
			s.redHold += dt
			if s.redHold > Config.Wear.Engine.RedlineAfter then
				rep.red += dt
			end
		else
			s.redHold = 0
		end
		if s.drifting then
			rep.drift += dt
		end
		if brake > 0.8 and s.vel.Magnitude > 30 then
			rep.hard += dt
		end
		local braking = s.engineOn and brake > 0.05
		if braking ~= (s.tailBrake == true) then
			s.tailBrake = braking
			setTails(s)
		end
		handbrake = handbrake or s.parkBrake
		-- clutch (manual gearbox): dropping it at high revs from a standstill launches the car
		local clutchWas = s.clutch
		s.clutch = clutch and s.manual
		local DF = Config.DrivingFeel
		local launchWas = s.launch
		if clutchWas and not s.clutch and s.freeRpm > 0.6 and s.mgear >= 1 and s.engineOn and Config.spsToMph(s.vel.Magnitude) < 20 then
			s.launch = 0.8
		end
		s.launch = math.max(0, s.launch - dt)
		-- launch control (automatic): hold the brake and floor it at a stop, the revs build; let go of
		-- the brake and the car launches
		-- It latches: once set at a stop it holds until the brake is let go (it used to drop out whenever
		-- the car crept, so the revs bounced 1,000-3,000 and the car rolled: owner, 2026-10-24)
		local standing = math.abs(s.vel:Dot(forwardFromYaw(s.yaw))) < 3
		local holding
		-- (owner, 2026-11-03: "when cars use manual mode launch control doesnt work"): the manual and
		-- sequential gearbox get it too, in a forward gear with the clutch up (Shift dropped at high revs
		-- still launches as well)
		if s.launchReady then
			holding = s.engineOn and brake > 0.3 and throttle > 0.3
		else
			holding = s.engineOn and standing and brake > 0.5 and throttle > 0.5 and (not s.manual or (s.mgear >= 1 and not s.clutch))
		end
		-- (owner, 2026-11-10: "to actually bring smoke on tire is when using launch control then release and then press S")
		-- a burnout: after a launch-control start, with the throttle still down, press the brake again: the brakes hold
		-- the car and the driven tyres spin and smoke on the spot. Lift the throttle (or get past BurnArmMph) and it's over
		if s.burnArmed and not s.burnout and (throttle < 0.3 or not s.engineOn or Config.spsToMph(s.vel.Magnitude) > DF.BurnArmMph) then
			s.burnArmed = false
		end
		-- (owner, 2026-11-13: "make it so that AWD cars cant do burnouts": all four wheels drive, the brakes can't hold it)
		s.burnout = s.burnArmed and s.engineOn and throttle > 0.5 and brake > 0.3 and not s.electric and s.drive ~= "AWD" and (not s.manual or (s.mgear >= 1 and not s.clutch))
		if s.burnout then
			holding = false -- (the pedals are the burnout's, not launch control's)
		end
		if s.launchReady and not holding and not s.burnout and throttle > 0.5 and brake <= 0.3 then
			s.launch = 0.8
			s.report.launch += 1
			-- (owner, 2026-11-10: "when doing launch control there is tire smoke ... remove that") the start itself is clean
			s.launchClean = DF.LaunchClean
			s.burnArmed = true
		end
		if s.launchClean > 0 then
			s.launchClean = if throttle < 0.3 or s.burnout then 0 else math.max(0, s.launchClean - dt)
		end
		if holding and not s.launchReady then
			UI.toast("Launch control: let go of the brake")
		end
		s.launchReady = holding
		s.engine:setLaunch(holding)
		-- a launch: the view kicks wide and blurs for a moment, the camera is thrown back
		if s.launch > launchWas + 0.5 then
			s.fovPunch += DF.LaunchKickFov
			s.blurPulse = math.max(s.blurPulse, DF.LaunchBlur)
			s.camLag += 2.5
			s.shake = math.max(s.shake, 0.35)
			-- (2026-11-26) a launch cracks two or three pops out of the pipes (once per launch: no spam)
			if not s.electric and s.pops == 0 and (s.popTune or s.flameLevel >= 2 or not noPops(s)) then
				s.pops = math.random(2, 3)
				s.popTimer = 0.06
			end
		end
		s.throttle += (throttle - s.throttle) * math.min(1, dt * 10)
		-- lifting off at high revs: a short crackle of pops + flames
		if s.throttleIn > 0.7 and throttle < 0.2 and not s.electric then
			local liftMph = Config.spsToMph(s.vel.Magnitude)
			local map = s.popTune
			if map == "crackle" or map == "antilag" then
				if s.rpm > 0.4 then
					s.pops = math.random(8, 12)
					s.popTimer = 0.04
				end
			elseif map == "pop" then
				if s.rpm > 0.45 then
					s.pops = math.random(4, 6)
					s.popTimer = 0.04
				end
			elseif map == "burble" then
				if s.rpm > 0.18 and s.rpm < 0.7 then
					s.pops = math.random(3, 5)
					s.popTimer = 0.08
				end
			elseif s.flameLevel >= 2 and s.rpm > 0.4 then
				-- (2026-11-21) the Flame Tune with no ECU map (S2 / R / X cars can't fit one): a burst of bangs + flames
				s.pops = math.random(6, 9)
				s.popTimer = 0.04
			elseif s.rpm > 0.55 and liftMph > 30 and not noPops(s) and not noLiftPops(s) then
				s.pops = math.random(3, 5) -- (2026-11-26: was rpm 0.6, 2-4 pops)
				s.popTimer = 0.04
			elseif s.rpm > 0.7 and liftMph > 40 and #s.flames > 0 then
				-- (2026-11-21) a silent flame + smoke lifting off high revs on the flame cars that have no pop sound
				exhaustPop(s, 0.6)
			end
		end
		s.throttleIn = throttle

		-- the ride height (TUNE), and air suspension sinking when parked
		do
			local parked = s.airRide and s.vel.Magnitude < 2 and throttle == 0
			s.rideDrop += (s.rideWant + (if parked then 0.35 else 0) - s.rideDrop) * math.min(1, dt * 1.5)
		end

		-- ground check
		local trafficF = workspace:FindFirstChild("Traffic")
		if s.model ~= rayModel or trafficF ~= rayTraffic then -- (2026-11-26) the filter is set again only when these change
			rayModel, rayTraffic = s.model, trafficF
			rayParams.FilterDescendantsInstances = { s.model, trafficF :: Instance }
		end
		local hit = workspace:Raycast(root.Position, Vector3.new(0, -(s.halfHeight + 1.2), 0), rayParams)
		s.grounded = hit ~= nil
		-- kerbs, ramps and bumps: a sudden change in the ground under the car kicks the body
		if hit then
			local last = s.groundDist
			if last then
				local jump = last - hit.Distance -- up when the ground rises
				-- (owner, 2026-11-02: "the car is jerking and jump and lifting up too much when there is
				-- a stud or a bump"): only a real kerb or ramp kicks the body, and gently; a stud or a
				-- seam in the road is soaked up by the springs. No random sideways roll any more.
				if math.abs(jump) > 0.45 and math.abs(jump) < 4 then
					local k = math.clamp(math.abs(jump) - 0.45, 0, 1.5) * math.sign(jump)
					s.pitchVel += k * DF.BumpKick * 20 * s.weightK ^ -DF.WeightBump * s.bumpK
					s.shake = math.max(s.shake, math.min(math.abs(k) * 0.3 * s.bumpK, 0.35))
					buzz(0.25 + 0.3 * math.abs(k), 0.06)
				end
			end
			s.groundDist = hit.Distance
		else
			s.groundDist = nil
		end
		-- the suspension: a ray down from each wheel finds the road under it; how far the wheel sits
		-- from where it should be is its spring's travel. The springs together carry the body (one
		-- force through its middle; the tilt comes from the road plane below)
		local sp = s.susp
		local up = root.CFrame.UpVector
		local sum, nOn = 0, 0
		for _, c in s.corners do
			local origin = root.CFrame:PointToWorldSpace(c.at) + up * 1
			local r = workspace:Raycast(origin, -up * (1 + c.rest + sp.droop + 0.6), rayParams)
			if r and r.Normal.Y > 0.6 then
				c.gap = (r.Distance - 1) - (c.rest - s.rideDrop) -- above zero: the road is lower than the wheel's rest
				c.hit = r.Position
				c.mat = r.Material
				c.partName = r.Instance.Name
				c.nrm = r.Normal
				sum += c.gap
				nOn += 1
			else
				c.gap = sp.droop
				c.hit = nil
				c.mat = nil
			end
		end
		-- The springs act as a vertical speed for the body, which the physics holds every physics step
		-- (a force set once a frame overshot at low frame rates: a dropped car bounced 7 studs high).
		-- The body rises or sinks back to its ride height at the spring's own rate, plus the road's own
		-- climb or fall under it, and the damping is the speed limit on the way.
		if nOn > 0 then
			-- the springs' mean travel, smoothed: the body follows the road, not each stud under a
			-- wheel (it rises more slowly than it settles, so a bump doesn't throw it up)
			local raw = sum / nOn
			local prev = s.gapSm or raw
			local k = if raw < prev then DF.LiftEase else DF.SettleEase
			s.gapSm = prev + (raw - prev) * math.min(1, dt * k)
			local avg = s.gapSm
			local rate = math.sqrt(sp.spring) * 0.45
			local vy = -avg * rate
			-- (fewer wheels on the road: over an edge the car drops away freely)
			if nOn < #s.corners then
				vy = math.min(vy, root.AssemblyLinearVelocity.Y)
			end
			s.vyTarget = math.clamp(vy, -sp.damp, sp.damp)
		else
			s.vyTarget = nil
			s.gapSm = nil
		end
		-- the road plane under the four wheels: the body lies along it (one wheel up a kerb tips it; a
		-- crest or a dip pitches it). In the air it eases back level.
		local upNow = Vector3.yAxis
		do
			local fl, fr, rl, rr
			for _, c in s.corners do
				if c.hit then
					if c.front then
						if c.left then
							fl = c.hit
						else
							fr = c.hit
						end
					else
						if c.left then
							rl = c.hit
						else
							rr = c.hit
						end
					end
				end
			end
			if fl and fr and rl and rr then
				local along = (fl + fr) / 2 - (rl + rr) / 2
				local across = (fr + rr) / 2 - (fl + rl) / 2
				if along.Magnitude > 0.5 and across.Magnitude > 0.5 then
					local nrm = across.Unit:Cross(along.Unit)
					if nrm.Y > 0.6 then
						upNow = nrm.Unit
					end
				end
			elseif hit and hit.Normal.Y > 0.75 then
				upNow = hit.Normal
			end
		end
		-- (the road plane eases in: a sudden tilt of more than ~6 degrees is one wheel on a stud, which
		-- tilts the body only slowly; a real change of slope comes through within a few tenths)
		local tiltRate = if nOn == 0 then 2 elseif upNow:Dot(s.groundUp) < 0.9945 then 3 else 8
		s.groundUp = s.groundUp:Lerp(upNow, math.min(1, dt * tiltRate)).Unit
		s.grounded = nOn > 0

		local actual = root.AssemblyLinearVelocity
		local actualFlat = Vector3.new(actual.X, 0, actual.Z)

		-- in the air (a ramp, the viaduct's kinks, a kerb at speed) and the landing: the body
		-- compresses, the nose dips, the camera thumps, a hard one bangs
		if not s.grounded then
			s.airT += dt
			s.airVy = math.min(s.airVy, actual.Y)
		else
			if s.airT > 0.25 then
				local fall = -s.airVy
				if fall > 8 then
					s.pitchVel -= DF.LandKick * fall * s.weightK ^ -DF.WeightBump
					s.headVel += Vector3.new(0, -fall * 0.04, 0)
					s.shake = math.max(s.shake, math.clamp(fall / 60, 0.2, 1))
					if fall > 45 then
						Audio.crash(fall * 0.5)
					end
				end
			end
			s.airT, s.airVy = 0, 0
		end

		-- Crash detection: physics couldn't give us the velocity we asked for
		if s.grounded and s.lastCommand.Magnitude > 25 then
			local loss = (s.lastCommand - actualFlat).Magnitude
			if loss > math.max(22, s.lastCommand.Magnitude * 0.35) then
				-- (2026-11-07) where it hit: from the way the speed went, on the side that took it
				local push = s.lastCommand - actualFlat
				local fwdNow = forwardFromYaw(s.yaw)
				local sideNow = fwdNow:Cross(Vector3.yAxis)
				local along, across = push:Dot(fwdNow), push:Dot(sideNow)
				local kind = if loss > 34 then "d" else "t"
				local sizeK = math.clamp(loss / 45, 0.5, 1.6)
				if math.abs(along) >= math.abs(across) then
					hitMark(s, kind, if along > 0 then "F" else "B", 0.5 + math.clamp(across / math.max(math.abs(along), 1), -1, 1) * 0.38, 0.35 + math.random() * 0.15, sizeK, loss)
				else
					hitMark(s, kind, if across > 0 then "R" else "L", 0.5 + (math.random() - 0.5) * 0.7, 0.3 + math.random() * 0.25, sizeK, loss)
				end
				cruiseOff(s, true)
				s.vel = actualFlat
				reportCrash(s, loss)
				-- the jolt: the body and the driver's head are thrown
				local k = math.clamp(loss / 40, 0, 2) * DF.CrashJolt * s.weightK ^ -DF.WeightBump
				s.pitchVel -= k * 2
				s.rollVel += k * 3 * (if math.random() < 0.5 then -1 else 1)
				s.headVel += Vector3.new(0, 0, -k * 3)
				s.drifting = false
			end
		end

		local fwd = forwardFromYaw(s.yaw)
		local right = Vector3.new(math.cos(s.yaw), 0, -math.sin(s.yaw))
		local fwdSpeed = s.vel:Dot(fwd)
		local latSpeed = s.vel:Dot(right)
		local handling = s.spec.Handling

		if s.grounded then
			-- longitudinal
			local a = 0
			local speedFrac = fwdSpeed / s.topSpeed
			s.brakeIn += (brake - s.brakeIn) * math.min(1, dt * 7)
			-- the automatic picks its gear by revs and how hard you press: flat out it holds each gear
			-- near the limiter, cruising it shifts early; pressing hard at low revs kicks down
			if not s.manual and s.shiftT <= 0 and not s.electric then
				if fwdSpeed > 1 and s.engineOn then
					local rev = speedFrac / gearHi(s.agear)
					if s.agear < gearsNow() and rev >= 0.5 + (s.cls.upshift - 0.5) * throttle then
						s.nextGear = s.agear + 1
						-- (each car's own gearbox with the two-axle model: dual-clutch quick, old automatics slow)
						local shiftTime = if E.get_curP() then E.get_curP().shift else s.cls.shiftTime
						s.shiftT = (if throttle > 0.5 then shiftTime else shiftTime * 1.6) * s.shiftK
					elseif s.agear > 1 and rev < (if throttle > 0.8 then 0.55 else 0.28) and speedFrac / gearHi(s.agear - 1) < (if E.get_curP() then 0.82 else 0.9) then
						s.nextGear = s.agear - 1
						s.shiftT = 0.12
					end
				elseif fwdSpeed <= 1 then
					s.agear = 1
				end
			end
			local gearNow = if s.manual then s.mgear else s.agear
			local engaged = s.engineOn and not s.clutch and s.shiftT <= 0 and gearNow ~= 0
			-- (2026-11-08) the two-axle model takes the engine's push and the brakes apart (each through its tyres' grip)
			local axleOn = s.axle ~= nil
			local aEng, aBrk = 0, 0
			if engaged and gearNow > 0 and fwdSpeed > -2 then
				local rev = if s.electric then math.max(speedFrac, 0) else math.max(speedFrac, 0) / gearHi(gearNow)
				if throttle > 0 and speedFrac < 1 and not (s.capTop and fwdSpeed >= s.capTop) then -- at top speed the limiter holds it there
					local pull = if s.electric then evPull(math.max(speedFrac, 0)) else torqueCurve(math.max(rev, 0.3)) * gearMul(gearNow)
					local push = s.accel * s.powerK * throttle * pull * (if s.launch > 0 then s.launchK else 1)
					a += push
					aEng += push
				elseif throttle == 0 and fwdSpeed > 2 and not (axleOn and brake > 0.3) then
					-- engine braking (regen on an electric car); not under hard braking (the clutch is out)
					local eb = 3 + 6 * math.min(rev, 1)
					a -= eb
					aEng -= eb
				end
				if rev > 1.02 then
					a -= 30 * (rev - 1) -- shifted down too early: the engine holds the car back
					aEng -= 30 * (rev - 1)
				end
			elseif throttle > 0 and fwdSpeed < -2 and not (s.manual and gearNow < 0) then
				-- braking out of reverse (not in a manual's R gear: there the throttle drives it backwards;
				-- owner, 2026-10-30: manual reverse crawled at ~5 km/h because this braked it)
				a += 140 * throttle
			end
			-- brakes by class; a hard stop at speed pulses the anti-lock (keeps some steering)
			-- (2026-11-03, realistic physics) real stopping power: the class's brake (about g x 28 x
			-- BrakeBoost), a heavier car stops later, a wet road too
			local brakeForce = s.cls.brake * s.brakeK * s.brakeIn * s.weightK ^ -DF.WeightBrake * (1 - DF.WetBrakeLoss * Driving.wet)
			if axleOn then
				-- each car's own brakes, for its real stopping distance (CarPhysics.brakeFor); with ABS off a full pedal
				-- squeezes harder than the tyres can take, and they lock
				brakeForce = s.brakeAxle * s.brakeK * s.brakeIn * (1 - DF.WetBrakeLoss * Driving.wet) * (if Driving.abs then 1 else DF.Axle.AbsOffSqueeze)
			end
			local abs = s.brakeIn > 0.8 and Config.spsToMph(math.abs(fwdSpeed)) > 12 and (Driving.abs or not axleOn)
			if abs then
				s.absT += dt
				brakeForce *= 1 - DF.AbsPulse * (0.5 + 0.5 * math.sin(s.absT * math.pi * 2 * DF.AbsHz))
				s.shake = math.max(s.shake, 0.05)
			end
			-- reverse: 10 km/h at most for every car (owner, 2026-10-31: "make the top speed like 10 kmh";
			-- it was 25 mph), with a gentle pull so it creeps back rather than jumping
			local reverseTop = Config.mphToSps(10 / 1.609)
			local reversePull = 24
			if s.manual then
				if engaged and gearNow < 0 and throttle > 0 and fwdSpeed > -reverseTop then
					a -= if fwdSpeed > 2 then 140 * throttle else reversePull * throttle
				end
				if fwdSpeed > 2 then
					a -= brakeForce
					aBrk += brakeForce
				elseif fwdSpeed < -2 then
					a += brakeForce
					aBrk += brakeForce
				end
			elseif fwdSpeed > 2 then
				a -= brakeForce
				aBrk += brakeForce
			elseif brake > 0 and throttle == 0 and fwdSpeed > -reverseTop and s.engineOn and not s.launchReady and s.stopT > 0.12 then
				-- automatic: hold the brake at a stop to reverse (not with the throttle down too). It waits
				-- a moment after stopping, so a hard stop doesn't bounce straight into reverse
				a -= reversePull * brake
			end
			if brake > 0 and math.abs(fwdSpeed) <= 2 then
				s.stopT += dt
			elseif brake == 0 or fwdSpeed > 2 then
				s.stopT = 0
			end
			if s.launchReady then
				-- launch control: the brakes hold the car dead still while the revs build
				a, fwdSpeed, latSpeed = 0, 0, 0
			end
			-- rolling resistance + aero drag (each car's own, so it tops out at its real top speed)
			local drag = 2 + s.dragC * fwdSpeed * fwdSpeed
			if handbrake and not axleOn then
				drag += 40 -- (the two-axle model locks the rear wheels instead)
			end
			if math.abs(fwdSpeed) > 0.5 then
				a -= math.sign(fwdSpeed) * drag
			elseif throttle == 0 and brake == 0 then
				fwdSpeed = 0
			end
			-- nitro: extra pull, and past the car's own top speed up to NitroTop of it
			s.boosting = nitroHeld() and s.nitro > 0 and engaged and gearNow > 0 and throttle > 0.3 and fwdSpeed > 5 and not s.towTop
			if s.capTop and fwdSpeed > s.capTop then
				a -= math.min(50, 6 + (fwdSpeed - s.capTop) * 2) -- (downhill, or just hitched at speed)
			end
			if s.boosting then
				if speedFrac < 1 then
					a += DF.NitroAccel
				else
					a += drag + DF.NitroAccel * math.clamp((DF.NitroTop - speedFrac) / (DF.NitroTop - 1), 0, 1)
				end
				s.nitro = math.max(0, s.nitro - s.nitroDrain * dt)
			elseif s.nitroOn then
				s.nitro = math.min(1, s.nitro + DF.NitroFillIdle * dt) -- (a fitted bottle refills slowly)
			end
			-- (the two-axle model moves the speed with its tyres below; the rest of the pull (drag, reverse, a limiter) is
			-- the same)
			local aOther = a - aEng + aBrk * (if fwdSpeed >= 0 then 1 else -1)
			if not axleOn then
				fwdSpeed += a * dt
			end

			-- steering: speed-sensitive wheel angle, capped by lateral grip; the wheel turns slower and
			-- finer at speed
			local speedAbs = math.abs(fwdSpeed)
			local steerRate = (if math.abs(steerIn) > math.abs(s.steer) then 6 else 8.5) / (1 + speedAbs / DF.SteerSlowdown)
			s.steer += (steerIn - s.steer) * math.min(1, dt * steerRate)
			-- (owner, 2026-11-22: "make the car steering lighter ... going fast in a curve the car understeer alot": the lock
			-- fell away with speed from 70 studs/s; now from 96, about a third more lock at 150 mph)
			local maxAngle = math.rad(36) * s.steerK / (1 + (speedAbs / 96) ^ 1.3)
			local angle = s.steer * maxAngle
			local yawRate = fwdSpeed * math.tan(angle) / s.wheelbase
			local out: any = nil
			if axleOn then
				-- (2026-11-08) the two-axle tyre model (CarPhysics.step): each axle's grip from its own load, surface and the
				-- rain; drive and brakes share it with cornering; the driver aids from Settings
				local AX = DF.Axle
				local P = s.axle :: any
				-- front drive: a gentle pull on a hard launch
				if s.drive == "FWD" and throttle > 0.8 and speedAbs < 40 then
					angle += AX.TorqueSteer * throttle * (1 - speedAbs / 40)
				end
				-- the surface under each axle (kerbs, paint, cobbles a little less; grass, sand, gravel much less)
				local gF, gR, nF, nR = 0, 0, 0, 0
				for _, c in s.corners do
					local g = 1
					if c.mat then
						g = AX.Surface[c.mat.Name] or 1
						local nm = c.partName or ""
						if string.find(nm, "Kerb", 1, true) then
							g = math.min(g, AX.KerbGrip)
						elseif string.find(nm, "Line", 1, true) or string.find(nm, "Dash", 1, true) or string.find(nm, "Paint", 1, true) then
							g = math.min(g, AX.PaintGrip)
						end
						if g < 0.8 then
							g = math.min(1, g * (1 + s.rallyK)) -- rally tyres
						end
					end
					if c.front then
						gF += g
						nF += 1
					else
						gR += g
						nR += 1
					end
				end
				local wetK = (1 - DF.WetGripLoss * Driving.wet) * s.gripK * (1 - math.min(s.driftK, 0.6) * 0.3)
				s.gripF = (if nF > 0 then gF / nF else 1) * wetK
				s.gripR = (if nR > 0 then gR / nR else 1) * wetK
				out = CarPhysics.step(P, {
					vx = fwdSpeed,
					vy = latSpeed,
					r = s.yawRate,
					delta = angle,
					drive = if s.launchReady or s.burnout then 0 elseif aEng > 0 then aEng * CarPhysics.reserve(P, fwdSpeed, s.topSpeed, if s.tc then Driving.tcMode else 0) else aEng,
					brake = aBrk,
					handbrake = handbrake,
					ax = s.axAxle,
					gripF = s.gripF,
					gripR = s.gripR,
					tc = if s.tc then Driving.tcMode else 0,
					esc = Driving.escMode,
					abs = Driving.abs,
					help = Driving.help,
					pedal = s.brakeIn,
					throttle = if engaged and gearNow > 0 then throttle else 0,
					top = s.topSpeed,
					drift = s.driftTyres,
				}, dt)
				-- a burnout: the driven tyres spin flat out on the spot (the wheels, the smoke and the squeal follow `spin`)
				if s.burnout then
					out.spin = 1
				end
				s.axleOut = out
				s.axAxle = out.ax
				-- the TC light: flashes while the aids are working (steady when TC is off), HUD and the live cluster
				if s.tc and out.tcCut > 0.12 then
					s.tcFlashT = 0.35
				end
				s.tcFlashT = math.max(0, s.tcFlashT - dt)
				local flick = s.tcFlashT > 0 and (os.clock() % 0.24) < 0.12
				DashGauges.tcOff = (not s.tc) or flick
				UI.setTcWorking(s.tcFlashT > 0)
				-- the speed: what the tyres put down plus the rest, then the car's frame turns with it
				fwdSpeed += (out.ax + aOther) * dt
				if s.launchReady or (s.burnout and math.abs(fwdSpeed) < 2) then
					fwdSpeed = 0
				end
				latSpeed = out.vy
				s.yawRate = out.r
				yawRate = out.r
				fwdSpeed += latSpeed * out.r * dt
				s.yaw -= out.r * dt
				fwd = forwardFromYaw(s.yaw)
				right = Vector3.new(math.cos(s.yaw), 0, -math.sin(s.yaw))
				-- (Studio driving tests: what the tyres and the engine are doing, on the car's root)
				if RunService:IsStudio() and Players.LocalPlayer:GetAttribute("TestDrive") then
					root:SetAttribute("Dbg", string.format("eng %.1f brk %.1f ax %.1f oth %.1f gF %.2f gR %.2f spin %.2f lock %.2f tc %.2f hb %s g %s wet %.2f k %.2f acc %.1f", aEng, aBrk, out.ax, aOther, s.gripF, s.gripR, out.spin, out.lock, out.tcCut, tostring(handbrake), tostring(s.gear), Driving.wet, s.powerK, s.accel))
				end
			end
			-- (2026-11-03, realistic physics) real tyre grip in g (the car's handling, a little help from
			-- GameGrip), lower for a heavy car, lower in the wet; aero downforce grows with speed squared
			-- (a lot on supercars, a little on the others), so a fast car is planted at speed
			local gripG = (DF.GripBase + DF.GripHandling * handling) * DF.GameGrip * s.weightK ^ -DF.WeightGrip * s.gripK
			gripG *= 1 + ((DF.Downforce[s.spec.Class] or 0) + s.downK) * math.clamp(speedAbs / s.topSpeed, 0, 1.1) ^ 2
			gripG *= 1 - DF.WetGripLoss * Driving.wet
			local latA = gripG * DF.G -- the sideways pull the tyres have (studs/s^2)
			-- weight transfer: braking loads the front (it turns in harder), pulling away loads the rear
			local brakeLoad = math.clamp(s.brakeIn, 0, 1) * math.clamp(speedAbs / 60, 0, 1)
			-- power on the rear (traction control off, or a clutch-drop launch) loosens it
			local loss = 0
			if not handbrake and (throttle > 0.5 or s.launch > 0) and s.drive ~= "FWD" then
				loss = (if s.tc then 0.05 else 0.4) * throttle * math.clamp(1 - math.abs(speedFrac) * 1.5, 0, 1)
				-- (the rear squats under power: a rear-drive car puts it down a little better as it digs in)
				loss *= 1 - DF.SquatGrip * math.clamp(s.lonGReal, 0, 1)
				if s.launch > 0 then
					loss += 0.2
				end
				if s.drive == "AWD" then
					loss *= if s.spec.RearBias then DF.AwdRearBias else DF.AwdPowerOversteer -- all four wheels share the power
				end
				loss = math.min(loss, 0.7)
			end
			local cap = latA / math.max(speedAbs, 1)
			cap *= 1 + DF.BrakeTurnIn * brakeLoad
			-- the front tyres give up first on a heavy-nosed car at speed (understeer), more so when a
			-- front-drive car is flooring it through the corner; braking hard keeps most of the steering
			cap *= 1 - s.cls.understeer * math.clamp(speedAbs / s.topSpeed, 0, 1)
			if s.drive == "FWD" then
				cap *= 1 - DF.FwdUndersteer * throttle * math.clamp(speedAbs / (s.topSpeed * 0.5), 0, 1)
			end
			if abs then
				cap *= DF.AbsSteer
			end
			if handbrake then
				cap *= 1.7
			elseif not s.tc then
				cap *= 1 + DF.PowerOversteer * loss / 0.4 -- the rear steps out under power
			end
			if not axleOn then
				yawRate = math.clamp(yawRate, -cap, cap)
				-- the car's turn follows the wheel with its weight: quick when parking, heavier at speed
				local response = (DF.YawResponse + DF.YawResponseHandling * handling) * (1 + 3 * math.max(0, 1 - speedAbs / 40)) / s.cls.inertia
				-- (2026-11-03) momentum: a heavy car's turn builds slower, and every car resists sudden
				-- direction changes at speed (no snapping at 250 km/h)
				response /= s.weightK ^ DF.WeightInertia * (1 + speedAbs / DF.HighSpeedYaw)
				s.yawRate += (yawRate - s.yawRate) * math.min(1, dt * response)
				yawRate = s.yawRate
				s.yaw -= yawRate * dt
			end

			-- drifting: a slide past DriftEnter at speed (or the handbrake thrown into a corner) is a
			-- drift; the nose is eased towards where the car is going (countersteer help), gently while
			-- you steer and firmly past the spin limit, so a drift can be held and linked
			local driftAngle = math.atan2(latSpeed, math.max(math.abs(fwdSpeed), 1))
			s.driftAngle = driftAngle
			local driftMph = Config.spsToMph(speedAbs)
			if not s.drifting then
				if driftMph > DF.DriftMinMph and fwdSpeed > 0 and (math.abs(driftAngle) > DF.DriftEnter or (handbrake and math.abs(s.steer) > 0.25)) then
					s.drifting = true
					s.driftCalm = 0
				end
			else
				s.driftCalm = if math.abs(driftAngle) < DF.DriftExit then s.driftCalm + dt else 0
				if s.driftCalm > DF.DriftHold or driftMph < DF.DriftMinMph * 0.7 or fwdSpeed <= 0 then
					s.drifting = false
				end
			end
			if s.drifting and speedAbs > 1 then
				local velYaw = yawFromLook((fwd * fwdSpeed + right * latSpeed).Unit)
				local d = (velYaw - s.yaw + math.pi) % (2 * math.pi) - math.pi
				if not axleOn then
					s.yaw += d * DF.DriftAssist * (0.4 + 0.6 * Driving.assist) * (1 - 0.6 * math.abs(steerIn)) * dt
					if math.abs(d) > DF.DriftMaxAngle then
						s.yaw += (math.abs(d) - DF.DriftMaxAngle) * math.sign(d) * math.min(1, dt * 12)
					end
				elseif Driving.help > 0 and math.abs(d) > DF.DriftMaxAngle then
					-- (the two-axle model) past the spin limit the countersteer help turns the car back towards where it's
					-- going (off for "Pro"); its speed stays, seen from the new heading
					local wv = fwd * fwdSpeed + right * latSpeed
					s.yaw += (math.abs(d) - DF.DriftMaxAngle) * math.sign(d) * math.min(1, dt * 8)
					s.yawRate *= math.exp(-dt * 4)
					fwd = forwardFromYaw(s.yaw)
					right = Vector3.new(math.cos(s.yaw), 0, -math.sin(s.yaw))
					fwdSpeed, latSpeed = wv:Dot(fwd), wv:Dot(right)
				end
				s.nitro = math.min(1, s.nitro + DF.NitroFillDrift * dt)
			end

			-- the car turns, its momentum doesn't: the velocity stays where it was and the tyres pull
			-- it round as far as their grip allows (below), which is what lets a car slide and drift
			-- (the two-axle model did all of this in CarPhysics.step)
			if not axleOn then
				local nf = forwardFromYaw(s.yaw)
				local nr = Vector3.new(math.cos(s.yaw), 0, -math.sin(s.yaw))
				local wv = fwd * fwdSpeed + right * latSpeed
				fwdSpeed, latSpeed = wv:Dot(nf), wv:Dot(nr)
				fwd, right = nf, nr
			end

			-- lateral grip (low with handbrake -> drift). Past the tyres' peak slip angle the grip falls
			-- away, so a slide keeps going until you catch it
			local grip = if handbrake then 1.4 else 4.5 + 5 * handling
			local slipAngle = math.atan2(math.abs(latSpeed), math.max(math.abs(fwdSpeed), 6))
			if not axleOn then
			grip *= 1 - loss
			grip *= 1 - math.min(s.driftK, 0.6) * 0.4 -- (drift tyres, a drift kit, high pressures)
			if s.surface == "loose" then
				grip *= 1 + s.rallyK
			end
			-- braking hard mid-corner: the rear goes light and can step out
			grip *= 1 - DF.TrailBrakeLoose * brakeLoad * math.abs(s.steer)
			grip *= 1 - DF.WetGripLoss * Driving.wet
			if slipAngle > DF.SlipPeak then
				grip *= 1 - (1 - DF.SlideGrip) * math.clamp((slipAngle - DF.SlipPeak) / DF.SlipPeak, 0, 1)
			end
			if s.drifting and not handbrake then
				-- in a held drift the side grip stays low while you stay on the throttle
				grip = math.min(grip, if throttle > 0.4 then DF.DriftGrip else DF.DriftGrip * 2.2)
			end
			-- the tyres pull the side speed out up to the sideways force they have (the same grip that
			-- caps the turn, a little more so a normal corner holds its line); a drift, the handbrake,
			-- wheelspin or a slide past the peak leaves them less, and the car slides
			do
				local gripK = grip / (4.5 + 5 * handling)
				local remove = latA * 1.15 * gripK * dt
				latSpeed *= math.exp(-grip * 0.5 * dt)
				latSpeed = math.sign(latSpeed) * math.max(0, math.abs(latSpeed) - remove)
			end
			-- driving assist (Settings: Off / Low / Normal): past the tyres' peak, outside a drift or the
			-- handbrake, the slide and the spin are gently caught, so keyboard and touch players don't spin
			if Driving.assist > 0 and not handbrake and not s.drifting and slipAngle > DF.SlipPeak then
				latSpeed *= math.exp(-DF.StabilityAssist * Driving.assist * dt)
				s.yawRate *= math.exp(-DF.StabilityAssist * 0.5 * Driving.assist * dt)
			end
			end -- (the old model)
			s.slip = math.abs(latSpeed) + (if handbrake and math.abs(fwdSpeed) > 20 then 25 else 0)
			if out then
				-- (the two-axle model) tyre noise from the real slip: a soft squeal near the limit, louder in a slide, a
				-- screech when locking or spinning; smoke per axle
				local x = math.max(out.slipF / 1.1, out.slipR)
				s.slip = 40 * math.clamp((x - 0.82) / 1.2, 0, 1) + 38 * out.spin + 38 * out.lock + (if handbrake and math.abs(fwdSpeed) > 20 then 20 else 0)
				if math.abs(fwdSpeed) < 4 and out.spin < 0.1 then
					s.slip = 0
				end
				local frontSpin = if s.drive ~= "RWD" then out.spin else 0
				local rearSpin = if s.drive ~= "FWD" then out.spin else 0
				-- (owner, 2026-11-10: "fix tire smoke coming out for no reason when idle") at a crawl the slip angle is no
				-- measure of a slide (a few cm/s of side creep read as a big angle): it smokes only once the car really moves
				local moving = math.clamp((math.abs(fwdSpeed) - 4) / 8, 0, 1)
				s.smokeF = math.clamp(math.max(frontSpin, (out.slipF - 1.4) / 1.5 * moving, if s.brakeIn > 0.8 and not Driving.abs then out.lock else 0), 0, 1)
				s.smokeR = math.clamp(math.max(rearSpin, (out.slipR - 1.3) / 1.4 * moving, if handbrake then out.lock * 0.6 else 0), 0, 1)
				if s.launchClean > 0 then
					s.smokeF, s.smokeR = 0, 0
				end
			end
			-- (2026-11-13: a donut or any hard wheelspin burns the tyres like a burnout does)
			-- (holding launch control is not a burnout: only tyres that really spin wear)
			if s.burnout or (s.axleOut ~= nil and throttle > 0.6 and s.axleOut.spin >= Config.DrivingFeel.Axle.SpinRedline) then
				s.report.burn += dt
			end
			if s.drifting then
				s.slip += 30 * math.clamp(math.abs(driftAngle) / 0.5, 0, 1)
			end
			-- tyre noise and smoke: a real launch (traction control off, flooring it from a stop, or a
			-- clutch drop) for a moment only, a hard stop at speed, and turning hard when fast
			local sf = math.abs(fwdSpeed) / s.topSpeed
			-- (the two-axle model hears the real slip, above; these are the old model's guesses)
			if not axleOn and not s.tc and throttle > 0.8 and fwdSpeed >= -1 and sf < 0.06 then
				s.slip += 30 * throttle * (1 - sf / 0.06)
			end
			if s.launch > 0 and not axleOn then
				s.slip += 25 * s.launch / 0.8
			end
			if s.brakeIn > 0.85 and fwdSpeed > 70 then
				s.slip += (if axleOn then 8 else 14) * s.brakeIn
			end
			if not axleOn and math.abs(s.steer) > 0.35 and sf > 0.4 then
				s.slip += 60 * math.abs(s.steer) * (sf - 0.4)
			end
			-- a loud tyre cry pulling away hard and on a launch (sound only: no smoke unless they slip)
			local cry = 0
			if engaged and gearNow > 0 and throttle > 0.8 and fwdSpeed >= -1 and sf < 0.12 then
				cry = (1 - sf / 0.12) * (if s.tc then 0.75 else 1)
			end
			if s.launch > 0 then
				cry = 1
			end
			s.chirp = math.max(0, s.chirp - dt)
			if s.chirp > 0 then
				cry = math.max(cry, 0.8)
			end
			s.screech = cry

			-- body on its springs: leans out in turns, dives under braking, squats pulling away, and
			-- rocks a little when a shift cuts and returns the drive
			-- (g in real units: the body leans and dives by what the car really does; the camera keeps its
			-- old, gentler scale)
			local latG = math.clamp(fwdSpeed * yawRate / DF.G, -2.5, 2.5)
			local lonG = math.clamp(a / DF.G, -2.5, 2.5)
			s.lonGReal = lonG
			s.latG, s.lonG = latG * DF.CameraG, lonG * DF.CameraG
			-- (and a fine shimmy from the road surface at speed)
			local tex = DF.RoadTexture * math.clamp(speedAbs / s.topSpeed, 0, 1)
			local tnow = os.clock()
			local texP = tex * math.noise(tnow * 9, 0, 7)
			local texR = tex * math.noise(0, tnow * 11, 8)
			s.pitchVel += ((math.rad(DF.BodyPitch) * s.cls.pitch * lonG + texP - s.pitch) * 70 - s.pitchVel * 10) * dt
			s.pitch += s.pitchVel * dt
			s.rollVel += ((math.rad(DF.BodyRoll) * s.cls.roll * latG + texR - s.roll) * 90 - s.rollVel * 12) * dt
			s.roll += s.rollVel * dt

			local newFwd = forwardFromYaw(s.yaw)
			local newRight = Vector3.new(math.cos(s.yaw), 0, -math.sin(s.yaw))
			s.vel = newFwd * fwdSpeed + newRight * latSpeed
			s.lv.MaxForce = root.AssemblyMass * 400
			s.lv.MaxAxesForce = Vector3.new(root.AssemblyMass * 400, root.AssemblyMass * 320, root.AssemblyMass * 400)
		else
			s.lv.MaxForce = root.AssemblyMass * 8
			s.steer += (steerIn - s.steer) * math.min(1, dt * 6)
			s.yawRate *= math.exp(-dt * 2)
			s.boosting = false
			-- (2026-11-04) off the ground for a while, the speed is what the car really does: wedged with
			-- no wheel on anything it kept its old speed, and "Slow down to get out" never went away
			if s.airT > 0.5 then
				s.vel = actualFlat
			end
			-- in the air the nose follows the arc (up off a ramp, down to land)
			local arc = math.clamp(math.atan2(actual.Y, math.max(actualFlat.Magnitude, 1)) * 0.6, -0.35, 0.35)
			s.pitch += (arc - s.pitch) * math.min(1, dt * 2)
			s.pitchVel *= math.exp(-dt * 4)
		end

		-- scraping a wall: sparks, speed bleeding off, a buzz in the camera
		if s.grounded and Config.spsToMph(s.vel.Magnitude) > DF.ScrapeMinMph then
			local side = Vector3.new(math.cos(s.yaw), 0, -math.sin(s.yaw))
			for _, sd in { 1, -1 } do
				local w = workspace:Raycast(root.Position, side * sd * (s.width / 2 + 0.4), rayParams)
				if w and w.Instance.CanCollide and math.abs(w.Normal.Y) < 0.5 then
					s.vel *= 1 - DF.ScrapeDrag * dt
					s.shake = math.max(s.shake, 0.15)
					sparks(w.Position, w.Normal, 3 + math.floor(Config.spsToMph(s.vel.Magnitude) / 25))
					-- (2026-11-07) a mark every half second of grinding, moving along the side; a metal grind
					s.scrapeT[sd] += dt
					if s.scrapeT[sd] > 0.5 then
						s.scrapeT[sd] = 0
						s.scrapeU[sd] = (s.scrapeU[sd] + 0.17) % 1
						hitMark(s, "s", if sd > 0 then "R" else "L", 0.12 + s.scrapeU[sd] * 0.76, 0.32 + math.random() * 0.16, 1, 0)
						Audio.scrape(math.clamp(s.vel.Magnitude / 80, 0.3, 1))
					end
				end
			end
		end
		-- a kerb under a wheel at speed: curb rash on that rim (a low ray at each front corner, a few times a second)
		s.rashT -= dt
		if s.rashT <= 0 and s.grounded and Config.spsToMph(s.vel.Magnitude) > 8 then
			s.rashT = 0.2
			for i, sd in { -1, 1 } do
				local at = root.Position + Vector3.new(math.cos(s.yaw), 0, -math.sin(s.yaw)) * sd * (s.width / 2 + 0.2) + forwardFromYaw(s.yaw) * s.wheelbase * 0.5
				local d = workspace:Raycast(at, Vector3.new(0, -8, 0), rayParams)
				if d and string.find(d.Instance.Name, "Kerb", 1, true) then
					s.report.rash = i
				end
			end
		end

		-- nitro fills from driving fast (not while it's being used)
		local mphNow = Config.spsToMph(s.vel.Magnitude)
		if not s.boosting and mphNow > 60 then
			s.nitro = math.min(1, s.nitro + DF.NitroFillSpeed * math.clamp((mphNow - 60) / 80, 0, 1) * dt)
		end

		-- the surface under the car: hard (asphalt, concrete) or loose (grass, sand: dust, no marks)
		if hit then
			s.surface = if HARD_SURFACE[hit.Material] then "hard" elseif LOOSE_SURFACE[hit.Material] then "loose" else "hard"
		end
		-- (2026-11-08, the two-axle model) marks from each tyre's own contact patch, as wide as that tyre, darker the
		-- harder it slides, spins or locks; only on hard ground
		if s.axleOut and s.axle then
			s.skidT += dt
			if s.skidT > 0.05 then
				s.skidT = 0
				local AX = DF.Axle
				local P = s.axle :: any
				for _, c in s.corners do
					local amount = if c.front then s.smokeF else math.max(s.smokeR, if s.drifting then 0.6 else 0)
					-- (2026-11-26) faint marks braking hard (ABS too) and from the driven tyres on a launch
					if s.brakeIn > 0.8 and mphNow > 20 then
						amount = math.max(amount, 0.3)
					end
					if s.launch > 0 and (if c.front then s.drive ~= "RWD" else s.drive ~= "FWD") then
						amount = math.max(amount, 0.4)
					end
					local hard = c.mat ~= nil and (AX.Surface[(c.mat :: Enum.Material).Name] or 1) >= 0.85
					if s.grounded and c.hit and hard and amount > 0.15 and mphNow > (if s.launch > 0 or s.burnout then 1 else 6) then
						local p = root.CFrame:PointToWorldSpace(c.at)
						p = Vector3.new(p.X, (c.hit :: Vector3).Y, p.Z) -- skidMark lifts it off the road
						local w = math.clamp((if c.front then P.tyreF else P.tyreR) / 1000 * 3 * 0.9, 0.5, 1.3)
						if c.skid then
							skidMark(c.skid :: Vector3, p, w, math.clamp(amount, 0.25, 1), c.nrm)
						end
						c.skid = p
					else
						c.skid = nil
					end
				end
			end
		-- skid marks under the rear tyres while they slide (only on a hard road surface)
		elseif s.grounded and hit and s.surface == "hard" and (s.slip > 28 or s.drifting) and mphNow > 8 then
			s.skidT += dt
			if s.skidT > 0.05 then
				s.skidT = 0
				local y = hit.Position.Y
				local cf = CFrame.new(root.Position) * CFrame.Angles(0, s.yaw, 0)
				local back = s.wheelbase * 0.5
				local l = cf:PointToWorldSpace(Vector3.new(-(s.width / 2 - 1.1), 0, back))
				local r = cf:PointToWorldSpace(Vector3.new(s.width / 2 - 1.1, 0, back))
				l = Vector3.new(l.X, y, l.Z)
				r = Vector3.new(r.X, y, r.Z)
				local tyre = math.clamp(s.width * 0.13, 0.6, 1.2)
				local dark = math.clamp((s.slip - 20) / 50, 0, 1)
				if s.skidL then
					skidMark(s.skidL, l, tyre, dark, hit.Normal)
				end
				if s.skidR then
					skidMark(s.skidR, r, tyre, dark, hit.Normal)
				end
				s.skidL, s.skidR = l, r
			end
		else
			s.skidL, s.skidR = nil, nil
		end

		-- out of the world
		if root.Position.Y < -40 then
			Driving.reset()
			return
		end
		-- (2026-11-04) in the sea: off a quay the car skates on the water or sits on the shallow seabed, and
		-- never gets down to the check above. Two seconds of that and it's back on the road (the ray starts
		-- above the car: from under the surface it would miss the water)
		-- (2026-11-21, owner: "make it so that when a car goes in water, they get teleported back to the nearest road
		-- near the water, facing the roads direction") the "Y < 20" gate missed Inya Lake (water at 40) and a sunk
		-- car; now 5 checks a second at any height: water is the first thing under the car (a bridge deck or a road
		-- beside the river is hit first, rain and pools are not Terrain water) or the body's middle is under water.
		-- After WaterRescue.Hold: a quick fade, back onto the nearest dry road to where it went in, no penalty
		s.seaT = (s.seaT or 0) + dt
		if (s.seaT :: number) >= WaterRescue.Every then
			local sea = workspace:Raycast(root.Position + Vector3.new(0, 8, 0), Vector3.new(0, -(s.halfHeight + 9.2), 0), rayParams)
			local wet = (sea ~= nil and sea.Material == Enum.Material.Water) or wetAt(root.Position)
			local from = WaterRescue.step(waterState, wet, root.Position, s.seaT :: number, os.clock())
			-- (2026-11-22, owner: "in Sule, in some parts u can go through the road and get stuck in the ground") a car
			-- that fell through a hole in the road's collision sits in the ground under the road: no road box under it,
			-- a road box's top 4+ studs over it within 12 studs, and hardly moving. 2 s of that: back on the road
			if not from and not wet then
				local stuck = false
				local map = workspace:FindFirstChild("Yangon1to1")
				local roadsF = map and map:FindFirstChild("Roads")
				local collideF = roadsF and roadsF:FindFirstChild("Collide")
				local flat = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z).Magnitude
				if collideF and flat < 8 then
					roadRay.FilterDescendantsInstances = { collideF }
					local under = workspace:Raycast(root.Position + Vector3.new(0, 1, 0), Vector3.new(0, -(s.halfHeight + 4), 0), roadRay)
					if not under then
						roadOverlap.FilterDescendantsInstances = { collideF }
						local bottom = root.Position.Y - s.halfHeight
						for _, p in workspace:GetPartBoundsInBox(CFrame.new(root.Position + Vector3.new(0, 10, 0)), Vector3.new(24, 30, 24), roadOverlap) do
							if p:GetAttribute("RoadBox") and p.Position.Y + p.Size.Y / 2 > bottom + 4 then
								stuck = true
								break
							end
						end
					end
				end
				s.holeT = if stuck then (s.holeT or 0) + (s.seaT :: number) else 0
				if (s.holeT :: number) >= 2 then
					s.holeT = 0
					from = root.Position
				end
			end
			s.seaT = 0
			if from then
				task.spawn(function()
					UI.fade(true, 0.25)
					if E.get_state() == s then
						Driving.reset(from)
						UI.toast("Back on the road")
					end
					UI.fade(false, 0.35)
				end)
			end
		end

		if s.vyTarget and s.grounded then
			-- on its wheels: the suspension holds the vertical speed too, following the road's climb
			local nrm = s.groundUp
			local climb = if nrm.Y > 0.5 then -(nrm.X * s.vel.X + nrm.Z * s.vel.Z) / nrm.Y else 0
			s.lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
			s.lv.ForceLimitMode = Enum.ForceLimitMode.PerAxis
			s.lv.VectorVelocity = Vector3.new(s.vel.X, climb + s.vyTarget, s.vel.Z)
		else
			s.lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
			s.lv.ForceLimitMode = Enum.ForceLimitMode.Magnitude
			s.lv.PlaneVelocity = Vector2.new(s.vel.X, s.vel.Z)
		end
		do
			local look = CFrame.Angles(0, s.yaw, 0).LookVector
			local n = s.groundUp
			local along = (look - n * look:Dot(n)).Unit
			s.ao.CFrame = CFrame.fromMatrix(Vector3.zero, along:Cross(n).Unit, n, -along) * CFrame.Angles(s.pitch, 0, s.roll)
		end
		s.lastCommand = s.vel

		-- gears / rpm (cosmetic)
		local fs = s.vel:Dot(forwardFromYaw(s.yaw))
		local frac = math.clamp(math.abs(fs) / s.topSpeed, 0, 1)
		local function manualName(): string
			return if s.mgear < 0 then "R" elseif s.mgear == 0 then "N" else tostring(s.mgear)
		end
		-- a shift: the drive comes back with a kick
		if s.shiftT > 0 then
			s.shiftT -= dt
			if s.shiftT <= 0 then
				if not s.manual then
					s.agear = s.nextGear
				end
				s.pitchVel += math.rad(16) * throttle
				s.headVel += Vector3.new(0, 0, 1.6 * throttle)
				if throttle > 0.5 then
					buzz(0.15 + 0.15 * throttle, 0.04) -- a little kick on phones
				end
				-- flat out near the limiter: the view punches wider for a moment
				if throttle > 0.8 and s.rpm > 0.8 then
					s.fovPunch += Config.DrivingFeel.ShiftPunchFov
					s.blurPulse = math.max(s.blurPulse, Config.DrivingFeel.ShiftBlur)
				end
				local g = if s.manual then s.mgear else s.agear
				if throttle > 0.8 and g >= 1 and g <= 3 then
					s.chirp = 0.25 -- the tyres chirp as the drive slams back in
				end
			end
		end
		if not s.engineOn then
			s.gear = if s.manual then manualName() else "N"
			s.rpm = if s.cranking > 0 then 0.12 else 0
			s.freeRpm = s.rpm
		else
			local free = s.manual and (s.mgear == 0 or s.clutch)
			s.freeRpm += (0.12 + 0.86 * throttle - s.freeRpm) * math.min(1, dt * 6)
			local target
			if s.manual then
				s.gear = manualName()
			elseif fs < -1 then
				s.gear = "R"
			elseif math.abs(fs) < 1 and throttle == 0 then
				s.gear = if s.electric then "D" else "N"
			else
				s.gear = if s.electric then "D" else tostring(s.agear)
			end
			if free then
				target = s.freeRpm
			elseif fs < -1 or (s.manual and s.mgear < 0) then
				target = math.clamp(0.12 + 0.8 * -fs / Config.mphToSps(math.min(35, s.spec.TopSpeed * 0.33)), 0.12, 1)
			elseif s.electric then
				target = 0.1 + 0.85 * frac -- the motor's speed: no gears, no limiter
			elseif s.launchReady then
				target = s.launchRev -- launch control holds the revs, steady
				s.rpm = target
			elseif s.burnout or (s.axle and throttle > 0.6 and fs > -1 and s.axleOut ~= nil and s.axleOut.spin >= Config.DrivingFeel.Axle.SpinRedline) then
				-- (owner, 2026-11-13: "when doing donuts or burnout it redline") the driven tyres spinning free (a burnout,
				-- a donut, a power slide with the tyres lit): the engine runs up to its limiter and bounces off it, heard
				-- and on the dials
				if throttle > 0.6 then
					if s.rpm >= 0.96 then
						s.limitT += dt
						target = 1 - Config.DrivingFeel.Axle.RevBounce * (0.5 + 0.5 * math.sin(s.limitT * math.pi * 2 * 9))
						s.rpm = target
					else
						target = 1.02 -- (on its way up to the limiter)
					end
				else
					target = 0.6 + 0.4 * throttle -- a burnout on part throttle: the revs high, off the limiter
					s.limitT = 0
				end
			elseif s.gear == "N" then
				target = 0.12
			else
				-- during an automatic shift the revs already fall to the next gear
				local g = if s.manual then s.mgear elseif s.shiftT > 0 then s.nextGear else s.agear
				local rev = frac / gearHi(g)
				target = 0.12 + 0.88 * rev
				if rev < 0.35 and throttle > 0 then
					target = math.max(target, 0.2 + 0.25 * throttle) -- pulling away: the clutch slips
				end
				target = math.clamp(target, 0.12, 1.02)
				-- (2026-11-08) on the limiter the revs bounce off it (the cut and the catch), heard and on the dials
				if s.axle and throttle > 0.6 and rev >= 0.985 then
					s.limitT += dt
					target = 1 - Config.DrivingFeel.Axle.RevBounce * (0.5 + 0.5 * math.sin(s.limitT * math.pi * 2 * 9))
					s.rpm = target
				else
					s.limitT = 0
				end
			end
			s.rpm += (target - s.rpm) * math.min(1, dt * s.cls.revRate)
			if not free then
				s.freeRpm = s.rpm
			end
		end

		-- shift sounds (dip in revs, pops on hard upshifts, the downshift blip): the moment the gearbox
		-- takes the new gear, which is when the revs start to move (owner, 2026-11-03: "the downshift sound
		-- doesn't match the actual downshift"; it used to wait for the gear on the dash, after the shift)
		local effGear: number? = if s.electric then nil elseif s.manual then (if s.mgear > 0 then s.mgear else nil) elseif s.shiftT > 0 then s.nextGear else s.agear
		if effGear and s.soundGear and effGear ~= s.soundGear and math.abs(fs) > 2 and s.engineOn then
			local isUp = effGear > s.soundGear
			s.engine:shift(isUp, math.clamp(0.12 + 0.88 * frac / gearHi(effGear), 0.12, 1.02))
			if isUp and throttle > 0.5 and (s.popTune or s.flameLevel >= 2 or (not noPops(s) and not noShiftPops(s))) then
				exhaustPop(s, if s.popLoud then 1.4 else 1)
			elseif isUp and throttle > 0.8 and s.rpm > 0.7 and #s.flames > 0 then
				-- (2026-11-21) a flame + smoke on a hard, high-rev upshift for the flame cars with no pop sound
				exhaustPop(s, 0.8)
			end
			-- the crackle map also crackles on the way down the gears
			if not isUp and (s.popTune == "crackle" or s.popTune == "antilag") then
				s.pops = math.max(s.pops, 3)
				s.popTimer = 0.04
			end
		end
		s.soundGear = effGear

		local mph = Config.spsToMph(math.abs(fs))
		detectCuts(s, forwardFromYaw(s.yaw), mph)
	end
end
