--[[
	Driving.render: the rig animation and the camera, every frame (client/Driving)
	Moved out of the parent module (2026-11-26: Studio caps a script at 200,000 characters).
	The parent calls this once with its locals; the ones it changes later (state, blur, windDof, nitroFill) are read
	through getters, so this sees their live values exactly as before.
]]

return function(E: any)
	local Audio = E.Audio
	local CameraLook = E.CameraLook
	local CarBuilder = E.CarBuilder
	local CarLamps = E.CarLamps
	local CarStats = E.CarStats
	local Config = E.Config
	local DUST = E.DUST
	local Driving = E.Driving
	local GuiService = E.GuiService
	local LowEnd = E.LowEnd
	local NITRO_FLAME = E.NITRO_FLAME
	local SMOKE = E.SMOKE
	local SoundService = E.SoundService
	local UI = E.UI
	local UserInputService = E.UserInputService
	local buzz = E.buzz
	local camera = E.camera
	local exhaustPop = E.exhaustPop
	local fadeSkids = E.fadeSkids
	local forwardFromYaw = E.forwardFromYaw
	local fxQuality = E.fxQuality
	local indicatorState = E.indicatorState
	local isInTunnel = E.isInTunnel
	local lookRay = E.lookRay
	local player = E.player
	local remote = E.remote
	local setLights = E.setLights
	local setVignette = E.setVignette

	local lookModel: Instance?, lookChar: Instance? = nil, nil
	function Driving.render(dt: number)
		local s = E.get_state()
		if not s or not s.root.Parent then
			return
		end
		local root = s.root
		local fwd = forwardFromYaw(s.yaw)
		local fwdSpeed = s.vel:Dot(fwd)
		local speedFrac = math.clamp(math.abs(fwdSpeed) / s.topSpeed, 0, 1)

		-- wheels
		s.wheelSpin = (s.wheelSpin - fwdSpeed * dt / 1.1) % (math.pi * 2)
		local wheelAngle = -s.steer * math.rad(28) / (1 + (math.abs(fwdSpeed) / 90))
		-- (2026-11-08) each wheel spins at its own radius: driven wheels faster when they spin up, locked ones stop;
		-- the front wheels at the angle the tyres really have (two-axle model)
		local ao = s.axleOut
		if ao then
			wheelAngle = -math.clamp(ao.delta, -math.rad(30), math.rad(30)) -- (30 degrees at most: the tyre stays in its arch)
		end
		for _, c in s.corners do
			local v = fwdSpeed
			if ao then
				local driven = if s.drive == "AWD" then true elseif s.drive == "FWD" then c.front else not c.front
				if driven and ao.spin > 0 then
					v += (if fwdSpeed >= 0 then 1 else -1) * ao.spin * 45
				end
				if ao.lock > 0.5 and (not c.front or not Driving.abs) and (not c.front or s.brakeIn > 0.8) then
					v = 0
				end
			end
			c.spin = (c.spin - v * dt / math.max(c.radius, 0.3)) % (math.pi * 2)
			-- the kit-v2 wheels: at speed the spokes give way to a blurred spinning face (no strobe), as a camera sees it
			local k = s.kit[c]
			if k then
				local w = math.abs(v) / math.max(c.radius, 0.3)
				local f = math.clamp((w - 12) / 18, 0, 1)
				if math.abs(f - k.shown) > 0.03 or (f == 0 and k.shown ~= 0) or (f == 1 and k.shown ~= 1) then
					k.shown = f
					for _, b in k.blur do
						b.Transparency = 1 - f
					end
					for _, p in k.spokes do
						p.Transparency = f * f
					end
				end
			end
		end
		-- hot brakes after a hard stop from high speed: the discs glow a faint orange, then cool
		do
			local sf = math.abs(fwdSpeed) / s.topSpeed
			if s.brakeIn > 0.7 and sf > 0.35 then
				s.brakeHeat = math.min(1, s.brakeHeat + s.brakeIn * sf * sf * dt * 0.9)
			else
				s.brakeHeat = math.max(0, s.brakeHeat - dt * 0.09)
			end
			local glow = math.clamp((s.brakeHeat - 0.35) / 0.65, 0, 1)
			if math.abs(glow - s.glowShown) > 0.02 or (glow == 0 and s.glowShown ~= 0) then
				s.glowShown = glow
				for _, k in s.kit do
					for _, sa in k.discs do
						pcall(function()
							sa.EmissiveStrength = glow * 1.6
						end)
					end
				end
			end
		end
		-- the other players see the front wheels turn (a steering value on the car, a few times a second)
		s.steerSendT -= dt
		local steerQ = math.floor(s.steer * 10 + 0.5) / 10
		-- (2026-11-09) the engine's revs, throttle, gear and on / off go with it, so the other players hear the
		-- car (rounded, a few times a second at most)
		local engQ = math.floor(math.clamp(s.rpm, 0, 1.1) * 40 + 0.5) / 40
		local thrQ = math.floor(math.clamp(s.throttle, 0, 1) * 4 + 0.5) / 4
		local gearQ = s.soundGear or 0
		local onQ = s.engineOn == true
		if s.steerSendT <= 0 and (math.abs(steerQ - s.steerSent) >= 0.1 or engQ ~= s.engSent or thrQ ~= s.thrSent or gearQ ~= s.gearSent or onQ ~= s.onSent) then
			s.steerSent, s.engSent, s.thrSent, s.gearSent, s.onSent = steerQ, engQ, thrQ, gearQ, onQ
			s.steerSendT = 0.15
			remote("CarSignals"):FireServer({ steer = steerQ, eng = { engQ, thrQ, gearQ, onQ } })
		end
		-- each wheel moves up and down on its spring to stay on the road (its travel smoothed a touch)
		local sp = s.susp
		for _, c in s.corners do
			local want = math.clamp(-c.gap + s.rideDrop, -sp.droop, sp.bump)
			c.travel += (want - c.travel) * math.min(1, dt * 30)
			local m = c.motor
			local lift = CFrame.new(m.C0.Rotation:Inverse() * Vector3.new(0, c.travel, 0))
			local klift = if c.knuckle then CFrame.new(c.knuckle.C0.Rotation:Inverse() * Vector3.new(0, c.travel, 0)) else CFrame.new()
			if m:GetAttribute("Front") then
				m.Transform = lift * CFrame.Angles(0, wheelAngle, 0) * CFrame.Angles(c.spin, 0, 0)
				-- brake caliper rides on a knuckle that steers but doesn't spin
				if c.knuckle then
					c.knuckle.Transform = klift * CFrame.Angles(0, wheelAngle, 0)
				end
			else
				m.Transform = lift * CFrame.Angles(c.spin, 0, 0)
				if c.knuckle then
					c.knuckle.Transform = klift
				end
			end
		end

		-- steering wheel + hands + IK arms. The wheel turns much further at parking speeds than at
		-- speed (as the road wheels do), with small corrections on the straight; the hands follow and
		-- re-grip (cross over) on big turns
		local DF = Config.DrivingFeel
		local mphAbs = Config.spsToMph(math.abs(fwdSpeed))
		local slowK = math.clamp(1 - mphAbs / DF.LockFadeMph, 0, 1)
		local lock = s.steerMaxRot + math.max(0, math.rad(DF.WheelLockSlow) - s.steerMaxRot) * slowK
		local wobble = math.rad(DF.WheelWobble) * math.noise(os.clock() * 0.9, 3.3, 0) * math.clamp((mphAbs - 30) / 60, 0, 1)
		local rot = -s.steer * lock + wobble
		if s.steerMotor then
			s.steerMotor.Transform = CFrame.Angles(0, 0, rot)
		end
		local reach = math.rad(DF.HandReach)
		local grip = rot - math.pi * math.floor(rot / math.pi + 0.5) -- the nearest half turn: hands swap over
		if math.abs(rot) <= reach then
			grip = rot
		end
		if math.abs(grip - s.handRot) > math.pi * 0.6 then
			s.handRot = grip -- a re-grip: let go and take hold again
		else
			s.handRot += (grip - s.handRot) * math.min(1, dt * 18)
		end
		pcall(function()
			if s.steerMount and #s.localSteer > 0 then
				local wheelWorld = root.CFrame * s.steerMount * CFrame.Angles(0, 0, rot)
				for _, ls in s.localSteer do
					ls.part.CFrame = wheelWorld * ls.offset
				end
			end
			if s.steerMount and #s.localArms > 0 then
				local wheelCF = s.steerMount * CFrame.Angles(0, 0, s.handRot)
				for _, arm in s.localArms do
					local handPos = (wheelCF * CFrame.new(arm.grip)).Position
					local fore, glove = arm.fore, arm.glove
					if fore then
						local upperCF, foreCF = CarBuilder.solveArm(arm.shoulder, handPos, arm.upperLen, arm.foreLen, arm.pole)
						arm.upper.CFrame = root.CFrame * upperCF * arm.rot
						fore.CFrame = root.CFrame * foreCF * arm.rot
						if glove then
							glove.CFrame = root.CFrame * foreCF * CFrame.new(0, 0, -(arm.foreLen + arm.handLen) / 2) * arm.rot
						end
					else
						-- one straight arm, shoulder to hand. In first person only the forearm and hand
						-- show (owner, 2026-10-17: the whole arm came past the camera as a big slab;
						-- 2026-10-22: the hands on the wheel disappeared when it was hidden)
						local from = arm.shoulder
						if Driving.cameraMode == "Interior" then
							from = handPos + (arm.shoulder - handPos) * DF.CockpitArm
						end
						-- the hand runs on past the grip, over and round the rim, so its flat end doesn't
						-- show beside the wheel when the hands come up in a turn (owner, 2026-10-29)
						local tip = handPos + (handPos - from).Unit * DF.HandPastGrip
						local len = (tip - from).Magnitude
						if math.abs(arm.upper.Size.Y - len) > 0.02 then
							arm.upper.Size = Vector3.new(arm.upper.Size.X, len, arm.upper.Size.Z)
						end
						arm.upper.CFrame = root.CFrame * CFrame.lookAt((from + tip) / 2, tip) * arm.rot
					end
					-- jointed arms: in first person the upper arm (next to the camera) hides, the
					-- forearm and glove stay on the wheel
					arm.upper.LocalTransparencyModifier = if fore and Driving.cameraMode == "Interior" then 1 else 0
					if fore then
						fore.LocalTransparencyModifier = 0
					end
					if arm.glove then
						(arm.glove :: BasePart).LocalTransparencyModifier = 0
					end
				end
			end
		end)
		if s.steerMount then
			local wheelCF = s.steerMount * CFrame.Angles(0, 0, rot)
			for _, arm in s.arms do
				local hand = (wheelCF * CFrame.new(arm.grip)).Position
				local upperCF, foreCF = CarBuilder.solveArm(arm.shoulder, hand, s.upperLen, s.foreLen, arm.pole)
				arm.upper.Transform = arm.upper.C0:Inverse() * upperCF
				arm.fore.Transform = arm.fore.C0:Inverse() * foreCF
			end
		end

		-- dashboard cluster + HUD
		local mph = Config.spsToMph(math.abs(fwdSpeed))
		if s.gaugeSpeed then
			s.gaugeSpeed.Text = tostring(math.floor((if Driving.units == "kmh" then mph * 1.609 else mph) + 0.5))
		end
		if s.gaugeGear then
			s.gaugeGear.Text = s.gear
		end
		if s.gaugeBar then
			s.gaugeBar.Size = UDim2.fromScale(s.rpm, 1)
		end
		if s.dashUpdate then
			pcall(s.dashUpdate, mph, s.gear, s.rpm)
		end
		if s.mfdUpdate then
			pcall(s.mfdUpdate, dt, mph, s.rpm, s.throttle, s.engineOn == true)
		end
		pcall(function()
			if #s.partNeedles > 0 or #s.guiNeedles > 0 or #s.guiTexts > 0 or #s.dialNeedles > 0 then
				local k = 1 - math.exp(-dt * 10) -- needles swing, they don't snap
				s.speedShown += (math.clamp(mph / 160, 0, 1) - s.speedShown) * k
				s.mphShown += (mph - s.mphShown) * k
				s.rpmShown += (math.clamp(s.rpm, 0, 1) - s.rpmShown) * k
				local sweep = 0
				if s.dialSweep then
					local t = (os.clock() - s.dialSweep) / 1.6
					if t < 1 then
						sweep = math.sin(t * math.pi)
					else
						s.dialSweep = nil
					end
				end
				for _, n in s.dialNeedles do
					local pts = n.scale
					local top = pts[#pts][1]
					-- the rev counter reads 8000 at our limiter (as the cars' own read-outs do)
					local v = if n.kind == "speed" then (if n.unit == "kmh" then s.mphShown * 1.609 else s.mphShown) else s.rpmShown * 8000
					v = math.max(v, sweep * top)
					local ang = pts[#pts][2]
					for i = 1, #pts - 1 do
						local a, b = pts[i], pts[i + 1]
						if v <= b[1] then
							ang = a[2] + (b[2] - a[2]) * math.clamp((v - a[1]) / (b[1] - a[1]), 0, 1)
							break
						end
					end
					n.gui.Rotation = ang
				end
				s.powerShown += ((if s.engineOn then s.throttle * s.rpm else 0) - s.powerShown) * k
				for _, n in s.partNeedles do
					local turn: number
					local pts = n.scale
					if pts then
						-- the dial's own scale (OWN_NEEDLES), from where the model's needle points
						local first, top = pts[1][1], pts[#pts][1]
						local v: number
						if n.kind == "speed" then
							v = if n.unit == "kmh" then s.mphShown * 1.609 else s.mphShown
						elseif n.kind == "rpm" then
							v = s.rpmShown * (if n.unit == "redline" then CarStats.redline(s.spec.Id) * 1000 else 8000) -- (redline is in thousands)
						elseif n.kind == "power" then
							v = s.powerShown * top
						elseif n.kind == "fuel" then
							v = first + (top - first) * 0.85 -- nearly full
						elseif n.kind == "oil" then
							-- warms up over the first minute to its normal reading
							local warm = if s.warmT then math.clamp((os.clock() - s.warmT) / 60, 0, 1) else 0
							v = first + (top - first) * 0.6 * warm
						else
							v = first
						end
						if n.kind == "speed" or n.kind == "rpm" or n.kind == "power" then
							v = math.max(v, sweep * top)
						end
						local ang = pts[#pts][2]
						for i = 1, #pts - 1 do
							local a, b = pts[i], pts[i + 1]
							if v <= b[1] then
								ang = a[2] + (b[2] - a[2]) * math.clamp((v - a[1]) / (b[1] - a[1]), 0, 1)
								break
							end
						end
						turn = ang - n.rest
					else
						turn = (if n.kind == "speed" then s.speedShown else s.rpmShown) * 240
					end
					-- the pivot's +Z looks at the driver: a negative turn is clockwise as the driver sees it
					n.part.CFrame = root.CFrame * n.pivot * CFrame.Angles(0, 0, -math.rad(turn)) * n.offset
				end
				for _, tl in s.guiTexts do
					tl.label.Text = if tl.kind == "Speed" then tostring(math.floor((if (tl.unit or Driving.units) == "kmh" then mph * 1.609 else mph) + 0.5)) elseif tl.kind == "RPM" then tostring(math.floor(s.rpm * 80) * 100) else s.gear
				end
				for _, n in s.guiNeedles do
					n.gui.Rotation = n.base + (if n.kind == "speed" then s.speedShown else s.rpmShown) * 240
				end
			end
		end)
		UI.setSpeed(mph, speedFrac, s.gear, s.rpm, s.launchReady, s.manual)

		-- blinkers: the corner lights and the HUD arrows flash together, with a soft tick
		if s.blinker ~= "" then
			local before = (s.blinkT % 0.8) < 0.4
			s.blinkT += dt
			local lit = (s.blinkT % 0.8) < 0.4
			for side, lights in s.blinkLights do
				local on = lit and (s.blinker == "H" or s.blinker == side) and not s.lamps
				for _, l in lights do
					l.Enabled = on
				end
			end
			UI.setBlink(lit and s.blinker ~= "R", lit and s.blinker ~= "L")
			if lit ~= before then
				Audio.tick(lit)
			end
		elseif s.blinkT ~= 0 then
			s.blinkT = 0
			for _, lights in s.blinkLights do
				for _, l in lights do
					l.Enabled = false
				end
			end
			UI.setBlink(false, false)
		end

		local reversing = s.engineOn and (fwdSpeed < -1 or (s.manual and s.mgear < 0))
		-- the new models' lamps (CarLamps): the beam it should be now, told to everyone when it changes
		if s.lamps then
			local beam = CarLamps.beamFor(s.engineOn, s.inTunnel == true)
			if beam ~= s.beam then
				s.beam = beam
				setLights(s, beam == "low" or beam == "high")
				UI.setIndicators(indicatorState(s))
				remote("CarSignals"):FireServer({ blinker = s.blinker, lights = s.lightsOn, beam = beam })
			end
			CarLamps.drive(s.model, beam, s.blinker, s.blinker ~= "" and (s.blinkT % 0.8) < 0.4, reversing)
			CarLamps.wet = Driving.wet
		end

		-- (owner, 2026-11-21: headlights and taillights without bugs, like the real cars): brake and reverse lamps told to
		-- everyone when they change, towing or not (2026-11-07: the trailer's lamps show them too)
		local braking = s.tailBrake == true
		if braking ~= s.towBrake or reversing ~= s.towRev then
			s.towBrake, s.towRev = braking, reversing
			remote("CarSignals"):FireServer({ brake = braking, rev = reversing })
		end
		-- towing: the camera turns round while reversing
		local towReverse = s.towTop ~= nil and s.engineOn and (fwdSpeed < -1.5 or (s.manual and s.mgear < 0))
		s.towTurn += ((if towReverse then math.pi else 0) - s.towTurn) * math.min(1, dt * Config.Towing.Camera.Turn)
		s.towPull += ((if s.towTop then 1 else 0) - s.towPull) * math.min(1, dt * 2)

		-- the rush: how fast it feels, by real speed (so a quick car at 150 feels it whatever its top)
		local mphNow = Config.spsToMph(math.abs(fwdSpeed))
		local rush = math.clamp((mphNow - DF.RushFrom) / (DF.RushTo - DF.RushFrom), 0, 1) ^ 1.2
		local fx = math.max(speedFrac, rush)

		-- engine / wind / tyre audio (the wind by the rush too)
		-- in a tunnel (a roof overhead along the way; owner, 2026-11-03): the engine doubles and
		-- the sound gets a stone-corridor echo; checked a few times a second
		s.tunnelCheck = (s.tunnelCheck or 0) - dt
		if s.tunnelCheck <= 0 then
			s.tunnelCheck = 0.2
			local inside = isInTunnel(s)
			if inside ~= s.inTunnel then
				s.inTunnel = inside
				s.engine:setTunnel(inside)
				SoundService.AmbientReverb = if inside then Enum.ReverbType.StoneCorridor else Enum.ReverbType.City
			end
		end
		s.engine:setCabin(Driving.cameraMode == "Interior")
		s.engine:update(s.rpm, s.throttle, fx, s.slip, nil, s.screech)
		if s.roar then
			local k = if s.grounded then math.clamp(mphNow / 180, 0, 1) ^ 1.3 else 0
			s.roar.Volume += (DF.RoadRoar * k - s.roar.Volume) * math.min(1, dt * 4)
			s.roar.PlaybackSpeed = 0.35 + 0.45 * k
		end
		-- smoke with the squeal (same curve as the sound); launches smoke the rear tyres most
		local squeal = math.clamp((s.slip - 8) / 40, 0, 1)
		-- (2026-11-03) the Tyre smoke setting, none in the rain (wet tyres don't smoke), dust and less
		-- of it on grass or sand; the driven wheels smoke most
		local q = fxQuality() * Driving.smoke * (if Driving.wet > 0.3 then 0 else 1) * (if s.surface == "loose" then 0.4 else 1)
		local loose = s.surface == "loose"
		if loose ~= s.smokeDust then
			s.smokeDust = loose
			for _, sm in s.smoke do
				sm.emitter.Color = if loose then DUST else SMOKE
			end
		end
		local total = 0
		for _, sm in s.smoke do
			local driven = if s.drive == "FWD" then not sm.rear elseif s.drive == "AWD" then true else sm.rear
			local rate = if squeal > 0.05 then squeal * (if driven then 70 else 35) else 0
			if s.axleOut then
				-- (the two-axle model) each axle smokes from its own tyres' slide, spin or lock
				rate = 75 * (if sm.rear then s.smokeR else s.smokeF)
			end
			if s.launchClean > 0 then
				rate = 0 -- (a launch-control start: no smoke)
			end
			-- a drift smokes the rear tyres hard
			if s.drifting and sm.rear then
				rate = math.max(rate, 55 * math.clamp(math.abs(s.driftAngle) / 0.4, 0.4, 1))
			end
			sm.emitter.Rate = math.min(rate * q, 100) -- (Playbook: about 100 a second per emitter at most)
			total += sm.emitter.Rate
		end
		-- other players see it too: a smoke level on the car (0 / 1 / 2), sent only when it changes
		local level = if total > 120 then 2 elseif total > 25 then 1 else 0
		s.smokeSendT = (s.smokeSendT or 0) - dt
		if level ~= s.smokeSent and s.smokeSendT <= 0 then
			s.smokeSent = level
			s.smokeSendT = 0.3
			remote("CarSignals"):FireServer({ smoke = level })
		end
		fadeSkids(dt)

		-- nitro: blue flames out of the pipes, the view kicks wide and blurs, a whoosh as it lights
		if s.boosting then
			if not s.boostWas then
				for _, e in s.flames do
					e.Color = NITRO_FLAME
				end
				if s.flameLight then
					s.flameLight.Color = Color3.fromRGB(90, 140, 255)
				end
				Audio.passBy(1)
				s.camLag += 2
				s.shake = math.max(s.shake, 0.3)
			end
			for _, e in s.flames do
				e:Emit(if q > 0.7 then 2 else 1)
			end
			s.flameGlow = math.max(s.flameGlow, 3)
			s.fovPunch = math.max(s.fovPunch, Config.DrivingFeel.NitroFov)
			s.blurPulse = math.max(s.blurPulse, Config.DrivingFeel.NitroBlur)
		elseif s.boostWas then
			for i, e in s.flames do
				e.Color = s.flameColors[i] or e.Color
			end
			if s.flameLight then
				s.flameLight.Color = Color3.fromRGB(255, 140, 50)
			end
		end
		s.boostWas = s.boosting
		if E.get_nitroFill() then
			E.get_nitroFill().Size = UDim2.fromScale(math.clamp(s.nitro, 0, 1), 1)
			E.get_nitroFill().BackgroundTransparency = if s.boosting then 0 else 0.15
		end

		-- exhaust crackle + flame glow
		if s.pops > 0 then
			s.popTimer -= dt
			if s.popTimer <= 0 then
				s.pops -= 1
				if s.popTune then
					s.popTimer = s.popGap + math.random() * s.popGap * 1.2
					local k = 0.6 + math.random() * 0.4
					s.engine:pop(k)
					-- (burbles are soft: no flame)
					if s.popTune ~= "burble" then
						exhaustPop(s, k * (if s.popLoud then 1.5 else 1))
					end
				else
					s.popTimer = 0.07 + math.random() * 0.12
					exhaustPop(s, 0.6 + math.random() * 0.4)
					if math.random() < 0.6 then
						Audio.backfire()
					end
				end
			end
		end
		if s.flameLight then
			-- (2026-11-26) an orange flash at the tips that also lights the road under them, ~0.12 s a pop
			s.flameGlow = math.max(0, s.flameGlow - dt * 50)
			s.flameLight.Brightness = s.flameGlow
			s.flameLight.Enabled = s.flameGlow > 0 and not LowEnd.on
		end
		if s.roadGlow then
			local braking = s.tailBrake == true
			s.roadGlow.Brightness = (if braking then 1.2 else 0.35) * (0.15 + 0.85 * CarLamps.night())
			s.roadGlow.Enabled = (s.lightsOn or braking) and not LowEnd.on
		end

		if Driving.cameraHold then
			return
		end
		-- (2026-11-04) a screen that shut while you sat in the car hands the walking camera back
		if camera.CameraType ~= Enum.CameraType.Scriptable then
			camera.CameraType = Enum.CameraType.Scriptable
		end
		-- camera (owner, 2026-10-29: "like the video"). The speed comes from the camera's lag, distance,
		-- sway, shake and blur; the FOV only moves a little outside and never in the cockpit. Settings:
		-- Driving.camFx (shake, head movement, motion blur, outside FOV).
		local C = Config.Camera
		local cfx = Driving.camFx
		local mode = Driving.cameraMode
		local interior = mode == "Interior"
		s.shake = math.max(0, s.shake - dt * 2.5)
		local t = os.clock()
		-- moments of extra speed: launches, flat-out shifts and close passes punch the view
		s.fovPunch *= math.exp(-dt * 3.5)
		s.blurPulse = math.max(0, s.blurPulse - dt * 14)
		-- (owner, 2026-11-03: "the shaking at top speed is too much ... unrealistic") a real camera at
		-- speed rumbles slowly and a little; it was a fast jitter. Smaller and about 9 times a second now
		local speedShake = 0.008 * math.min(fx * 6, 1) + math.max(0, fx - 0.3) * 0.05
		local shakeAmt = (speedShake + s.shake * 0.5) * cfx.shake
		local shakeOffset = Vector3.new(math.noise(t * 9, 0, 1), math.noise(0, t * 8, 2), 0) * shakeAmt
		local function setBlur(size: number)
			if E.get_blur() then
				E.get_blur().Size = if cfx.blur then size else 0
			end
		end

		-- the g-forces on the outside cameras: the camera slides in a corner (the car moves out in the
		-- frame) and rolls with it, tips with the pull and the braking, lags behind a launch and comes
		-- closer braking. All smoothed, back to centre in about half a second.
		local G = C.Drama
		local IC = C.Immersive
		local gk = math.min(1, dt * G.Response)
		local latG = math.clamp(s.latG, -1.2, 1.2)
		local lonG = math.clamp(s.lonG, -1.2, 1.2)
		local yawRate = s.steer * math.min(math.abs(fwdSpeed), 60) / 60
		s.camLag += ((lonG * IC.Lag) - s.camLag) * math.min(1, dt * IC.LagResponse)
		s.camSwing += ((yawRate * IC.Swing) - s.camSwing) * math.min(1, dt * 3.5)
		local swingFrac = if IC.Swing > 0 then math.clamp(s.camSwing / IC.Swing, -1, 1) else 0
		s.camSide += (swingFrac * (G.Side + G.SideSpeed * fx) * math.min(1, fx * 3) - s.camSide) * gk
		s.camRoll += (math.clamp(-latG * G.Roll, -G.MaxRoll, G.MaxRoll) - s.camRoll) * gk
		s.camPitch += (lonG * G.Pitch - s.camPitch) * gk
		s.gFov += ((if lonG > 0 then lonG * G.AccelFov else lonG * G.BrakeFov) - s.gFov) * gk

		-- high-speed sway (every camera): a slow roll and float from smooth noise, a fine vibration
		-- on top, both growing with speed
		local HS = C.Shake
		local hs = math.clamp((mphNow - HS.FromMph) / (HS.ToMph - HS.FromMph), 0, 1) * cfx.shake
		local sway = CFrame.identity
		if hs > 0 then
			local function n(a: number, b: number): number
				return math.clamp(math.noise(a, b, 0.5) * 2, -1, 1)
			end
			local float = Vector3.new(0, HS.Bob * hs * n(t * HS.Rate, 21.7), 0)
			local buzz = Vector3.new(n(t * 11, 5.1), n(5.3, t * 13), 0) * HS.Buzz * hs
			sway = CFrame.new(float + buzz) * CFrame.Angles(0, 0, HS.Roll * hs * n(t * HS.Rate, 13.3))
		end

		-- (owner, 2026-11-13: "make it so that u can look around in third person camera view") the outside
		-- cameras swing round the car: right mouse button held, a finger dragged on free screen, or the right
		-- stick (client/CameraLook). Swung round, the camera looks at the car instead of the road ahead and
		-- comes in before a wall or the ground; let go and drive, and it eases back behind the car.
		CameraLook.update(dt, mphNow)
		local lookK = if interior then 0 else CameraLook.amount()
		local function orbit(camPos: Vector3, lookAt: Vector3): (Vector3, Vector3)
			if interior or not CameraLook.active() then
				return camPos, lookAt
			end
			local pivot = root.Position + Vector3.new(0, 1.8, 0)
			local turnY = CFrame.Angles(0, CameraLook.yaw, 0)
			local off = turnY:VectorToWorldSpace(camPos - pivot)
			local flatOff = Vector3.new(off.X, 0, off.Z)
			local dist = off.Magnitude
			if flatOff.Magnitude > 1e-3 and dist > 1e-3 then
				local e = math.clamp(math.atan2(off.Y, flatOff.Magnitude) + CameraLook.pitch, -0.2, 1.35)
				off = flatOff.Unit * math.cos(e) * dist + Vector3.new(0, math.sin(e) * dist, 0)
			end
			local look = (pivot + turnY:VectorToWorldSpace(lookAt - pivot)):Lerp(pivot, lookK)
			local char = player.Character
			if s.model ~= lookModel or char ~= lookChar then -- (2026-11-26) the filter is set again only when these change
				lookModel, lookChar = s.model, char
				lookRay.FilterDescendantsInstances = { s.model, char :: Instance }
			end
			local hit = workspace:Raycast(pivot, off, lookRay)
			if hit then
				off = (hit.Position - pivot) * 0.9
			end
			return pivot + off, look
		end
		local targetFov
		local rootCF = root.CFrame
		if interior then
			targetFov = C.InteriorFov + C.MaxFovBoost * C.InteriorFovBoost * speedFrac ^ 1.5
			local H = C.Head
			local hk = cfx.head
			local mouseLook = 0
			if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
				local vp = camera.ViewportSize
				local mp = UserInputService:GetMouseLocation()
				mouseLook = -((mp.X / vp.X) - 0.5) * math.rad(160)
			end
			local lookInto = -s.steer * math.rad(H.LookInto) * hk
			local eyeCF = rootCF * CFrame.new(s.eye) * CFrame.Angles(0, lookInto + mouseLook, 0) * CFrame.Angles(math.rad(-4), 0, 0)
			-- the driver's head on a spring, from the real g: slides to the outside of a turn and tilts
			-- the horizon, dips forward and down braking, is pushed back pulling away; a crash jolts it
			local brakeK = math.clamp(-lonG / 0.8, 0, 1)
			local pullK = math.clamp(lonG / 0.8, 0, 1)
			local headTarget = Vector3.new(-latG * H.Lean, -brakeK * H.Brake * 0.5, pullK * H.Launch - brakeK * H.Brake) * hk
			local tiltTarget = Vector2.new(-brakeK * H.BrakePitch + pullK * 0.02, math.clamp(-latG * H.TiltPerG, -H.Tilt, H.Tilt)) * hk
			local w = H.Response
			local step = math.min(dt, 1 / 30)
			s.headVel += ((headTarget - s.headPos) * (w * w) - s.headVel * (2 * H.Bounce * w)) * step
			s.headPos += s.headVel * step
			s.headTiltVel += ((tiltTarget - s.headTilt) * (w * w) - s.headTiltVel * (2 * H.Bounce * w)) * step
			s.headTilt += s.headTiltVel * step
			-- breathing when slow or parked: a tiny slow rise and fall, a little uneven
			local slow = math.clamp(1 - mphNow / H.BreathFadeMph, 0, 1)
			local breath = H.Breath * slow * hk * math.sin(t * 2 * math.pi / H.BreathPeriod + math.noise(t * 0.15, 7.7, 0) * 1.5) * (0.85 + 0.3 * math.noise(t * 0.1, 9.9, 0))
			local jolt = Vector3.new(math.noise(t * 10, 0, 1), math.noise(0, t * 9, 2), 0) * (s.shake * 0.15 + DF.CabinBuzz * rush) * cfx.shake
			camera.CFrame = eyeCF * CFrame.new(s.headPos + jolt + Vector3.new(0, breath, 0)) * CFrame.Angles(s.headTilt.X, 0, s.headTilt.Y)
			setBlur(0)
		elseif mode == "Immersive" or mode == "Low" then
			-- low and close behind the car, like a racing game's near camera; "Low" sits at wheel-top
			-- height off to one side, closer, with more blur
			local low = mode == "Low"
			local LC = C.Low
			targetFov = cfx.fov + (if low then (LC.Fov - IC.Fov) + LC.FovBoost * fx ^ 1.25 else IC.FovBoost * fx ^ 1.25)
			local back = if low then LC.Distance + s.camLag * 0.6 + fx * LC.SpeedPull else IC.Distance + s.camLag + fx * IC.SpeedPull
			local up = if low then LC.Height else IC.Height - fx * 0.5
			back += s.towPull * Config.Towing.Camera.Back
			up += s.towPull * Config.Towing.Camera.Up
			local side = if low then -LC.Side + s.camSide * 0.5 else s.camSide
			local base = CFrame.new(root.Position) * CFrame.Angles(0, s.yaw, 0) -- level with the road, not the body roll
			local camPos = (base * CFrame.Angles(0, s.camSwing + s.towTurn, 0) * CFrame.new(side, up, back)).Position
			-- road buzz: fine fast shake that grows with speed, plus a slow float
			s.camBob += dt * (4 + fx * 8)
			local buzz = (0.01 + fx ^ 2 * IC.Buzz + s.shake * 0.4) * cfx.shake
			local shake = Vector3.new(math.noise(t * 9, 0, 3), math.noise(0, t * 8, 4), 0) * buzz
				+ Vector3.new(0, math.sin(s.camBob) * 0.012 * fx * cfx.shake, 0)
			local ahead = if low then CFrame.new(-LC.Side * 0.3, LC.LookHeight, -LC.LookAhead) else CFrame.new(0, IC.LookHeight, -IC.LookAhead)
			local lookAt = (base * CFrame.Angles(0, -s.camSwing * 0.6 + s.towTurn, 0) * ahead).Position
			s.camPos = camPos
			s.camLook = lookAt
			local oPos, oLook = orbit(camPos, lookAt)
			camera.CFrame = CFrame.lookAt(oPos + shake, oLook + shake * 0.5) * CFrame.Angles(s.camPitch, 0, s.camRoll)
			local blurMax = if low then LC.Blur else IC.Blur
			local blurFrom = if low then LC.BlurFrom else IC.BlurFrom
			setBlur(math.max(blurMax * math.max(0, fx - blurFrom) ^ 1.3, s.blurPulse))
		else
			targetFov = cfx.fov + (C.ChaseFov - IC.Fov) + C.MaxFovBoost * fx ^ 1.4
			-- follow the direction of travel a little when drifting
			local velDir = if s.vel.Magnitude > 5 then s.vel.Unit else fwd
			if s.vel:Dot(fwd) < -5 then
				velDir = fwd
			end
			local camDir = (fwd * 0.75 + velDir * 0.25).Unit
			local dist = C.ChaseDistance + speedFrac * 4 + s.camLag * 0.6 + s.towPull * Config.Towing.Camera.Back
			local right = camDir:Cross(Vector3.yAxis)
			local desired = root.Position - camDir * dist + right * s.camSide + Vector3.new(0, C.ChaseHeight - speedFrac * 0.8, 0)
			local alpha = 1 - math.exp(-dt * 10)
			s.camPos = s.camPos:Lerp(desired, alpha)
			-- never let the camera lag too far behind at hyper speeds
			local offset = s.camPos - root.Position
			if offset.Magnitude > dist * 1.6 then
				s.camPos = root.Position + offset.Unit * dist * 1.6
			end
			local look = root.Position + fwd * 10 + Vector3.new(0, 1.8, 0)
			s.camLook = s.camLook:Lerp(look, 1 - math.exp(-dt * 14))
			local oPos, oLook = orbit(s.camPos, s.camLook)
			camera.CFrame = CFrame.lookAt(oPos + shakeOffset, oLook) * CFrame.Angles(s.camPitch * 0.7, 0, s.camRoll * 0.8)
			setBlur(math.max(2 * math.max(0, fx - 0.55) ^ 1.5, s.blurPulse))
		end
		camera.CFrame *= sway
		camera.Focus = CFrame.new(root.Position) -- (Playbook: every frame, or shadows and detail break)
		s.fov += (targetFov - s.fov) * math.min(1, dt * 4)
		-- (the cockpit keeps one FOV: the owner wants that view steady and readable)
		camera.FieldOfView = s.fov + (if interior then 0 else s.fovPunch + s.gFov)
		-- speed: a realistic wind blur, not cartoon lines (owner, 2026-11-03): the hard white streaks are
		-- gone; from WindFromMph to the car's top speed the near roadside blurs as it rushes past (depth
		-- of field: what's close, at the screen's edges, smears; the road ahead, where you look, stays
		-- sharp), a touch of far haze, the edges darken a little. Off in the cockpit (the cluster stays
		-- readable), with Motion blur off or Reduced Motion; lighter on phones
		local wind = 0
		if not interior and cfx.blur and not GuiService.ReducedMotionEnabled then
			local mphWind = Config.spsToMph(s.vel.Magnitude)
			local full = math.max(DF.WindFromMph + 30, Config.spsToMph(s.topSpeed) * 0.95)
			wind = math.clamp((mphWind - DF.WindFromMph) / (full - DF.WindFromMph), 0, 1) ^ 1.2 * (if UI.isTouch then 0.6 else 1)
		end
		if E.get_windDof() then
			s.wind = (s.wind or 0) + (wind - (s.wind or 0)) * math.min(1, dt * 3)
			local w = s.wind :: number
			-- (Roblox has no screen-edge blur: the car and the road close by stay sharp, the street further
			-- ahead and the roadside rushing past blur softly, plus a few feathered streaks at the very edge)
			E.get_windDof().NearIntensity = 0
			E.get_windDof().FarIntensity = DF.WindFarBlur * w
			E.get_windDof().FocusDistance = 30
			E.get_windDof().InFocusRadius = 90 - 40 * w
		end
		UI.setSpeedLines((s.wind or 0) * DF.WindStreaks)
		setVignette(DF.Vignette * (s.wind or 0) * (if interior then 0.5 else 1))
	end
end
