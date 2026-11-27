--[[
	TrafficSounds (client, 27 Nov 2026)
	Owner: "npc traffic has like some car passing wind sound", "make it so that they can honk".
	Vault: City Legends/2026-11-27 Traffic pass-by and footstep sounds.md

	  * pass-by: VOICES pooled voices (2 on low-end), each a tyre/wind roar loop (Config.Sounds.StreetRoar) + a low
	    engine hum (Config.Sounds.Engine pitched down) on an Attachment that follows one car. Every 0.2 s the voices
	    go to the nearest moving cars within EAR studs. Louder and brighter with speed, Doppler pitch from the car's
	    speed toward / away from the camera, so it rises as it comes and drops as it passes. No per-car scripts.
	  * honks (Yangon traffic honks a lot): a car blocked by the player's car, or one driving at it, gives a long or
	    double honk; a cut-in gets a tap; a tap before a racer moves over; now and then a tap at a slow crosser or a
	    stopped queue. Per-car cooldown, at most HONK_CAP honks per HONK_WINDOW s, only within HONK_EAR studs.
	    Horn pitch per car: kei trucks / vans low, small cars high, YBS buses the deep air horn.
	Traffic.update calls TrafficSounds.step(dt, cars); Traffic writes npc.gapNow / gapPlayer / gapAlign.
]]

local Workspace = game:GetService("Workspace")
local Audio = require(script.Parent:WaitForChild("Audio"))
local LowEnd = require(script.Parent:WaitForChild("LowEnd"))

local TrafficSounds = {}

local VOICES, EAR, PICK_EVERY = 4, 170, 0.2
local SOUND_SPEED = 700 -- studs/s for the Doppler (real is ~1030 at 3 studs a metre; lower reads at city speeds)
local FULL_SPEED = 55 -- studs/s (~65 km/h): full roar
-- (the clip study, vault 2026-11-24 "Clip study supplement": horns are rare in real Yangon driving, about one in 13
-- minutes, a long ~405 Hz honk: so honks come only from events, and few)
local HONK_EAR, HONK_CAP, HONK_WINDOW, HONK_GAP, CAR_COOL = 150, 2, 6, 0.35, 6

-- horn per car id: { sound key, pitch }
local HORN = {
	ybs = { "HornBus", 1.0 },
	hiace = { "HornCar", 0.86 },
	carry = { "HornCar", 0.9 },
	suzaki_swift = { "HornCar", 1.12 },
	probox = { "HornCar", 1.04 },
}

type Voice = { att: Attachment, roar: Sound, hum: Sound, npc: any?, vol: number, pitch: number }
local voices: { Voice } = {}
local pickT = 0
local lastCam: Vector3? = nil
local camVel = Vector3.zero

local function sound(parent: Instance, id: string, minD: number, maxD: number): Sound
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Looped = true
	s.Volume = 0
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = minD
	s.RollOffMaxDistance = maxD
	s.Parent = parent
	return s
end

local function makeVoices()
	local roarId = Audio.pickCustom("StreetRoar")
	if not roarId then
		return -- (the sound check isn't done yet, or the upload didn't load: try again later)
	end
	local humId = Audio.pickCustom("Engine") or "rbxasset://sounds/action_falling.ogg"
	for i = 1, VOICES do
		local att = Instance.new("Attachment")
		att.Name = "TrafficVoice" .. i
		att.Parent = Workspace.Terrain
		local roar = sound(att, roarId, 14, EAR)
		roar.TimePosition = i * 0.9 -- (the voices don't start the loop in step)
		local hum = sound(att, humId, 6, 60)
		table.insert(voices, { att = att, roar = roar, hum = hum, npc = nil, vol = 0, pitch = 1 })
	end
end

local function isBus(npc): boolean
	return npc.model:GetAttribute("TrafficId") == "ybs"
end

local function passBy(dt: number, cars: { any }, camPos: Vector3)
	if #voices == 0 then
		makeVoices()
		if #voices == 0 then
			return
		end
	end
	local want = if LowEnd.on then 2 else VOICES
	pickT -= dt
	if pickT <= 0 then
		pickT = PICK_EVERY
		local near = {}
		for _, npc in cars do
			if npc.speed > 2 and npc.model.Parent then
				local d = (npc.pos - camPos).Magnitude
				if d < EAR then
					table.insert(near, { npc = npc, d = d })
				end
			end
		end
		table.sort(near, function(a, b)
			return a.d < b.d
		end)
		local keep = {}
		for i = 1, math.min(#near, want) do
			keep[near[i].npc] = true
		end
		-- a voice keeps its car while that car is still wanted; free voices take the new ones
		for _, v in voices do
			if v.npc and not keep[v.npc] then
				v.npc = nil
			elseif v.npc then
				keep[v.npc] = nil
			end
		end
		for npc in keep do
			for i, v in voices do
				if not v.npc and i <= want then
					v.npc, v.vol = npc, 0
					v.att.WorldPosition = npc.pos
					break
				end
			end
		end
	end
	for _, v in voices do
		local npc = v.npc
		local target, pitch = 0, v.pitch
		if npc and npc.model.Parent then
			v.att.WorldPosition = npc.pos + Vector3.new(0, 1, 0)
			local k = math.clamp(npc.speed / FULL_SPEED, 0, 1.4)
			local toCam = camPos - npc.pos
			local dist = math.max(toCam.Magnitude, 1)
			-- speed of the car toward the camera minus the camera's own toward the car
			local radial = (npc.fwd * npc.speed - camVel):Dot(toCam / dist)
			local doppler = SOUND_SPEED / (SOUND_SPEED - math.clamp(radial, -250, 250))
			target = 0.85 * k ^ 1.4
			pitch = (0.8 + 0.3 * math.min(k, 1)) * doppler * (if isBus(npc) then 0.85 else 1)
			v.hum.Volume = (if isBus(npc) then 0.5 else 0.3) * math.min(v.vol / 0.85 + 0.2, 1)
			v.hum.PlaybackSpeed = (0.45 + 0.35 * math.min(k, 1)) * doppler * (if isBus(npc) then 0.75 else 1)
		else
			v.npc = nil
			v.hum.Volume = 0
		end
		v.vol += (target - v.vol) * math.min(dt * 6, 1)
		v.pitch += (pitch - v.pitch) * math.min(dt * 10, 1)
		v.roar.Volume = v.vol
		v.roar.PlaybackSpeed = math.clamp(v.pitch, 0.4, 2)
		local on = v.vol > 0.01
		if on ~= v.roar.IsPlaying then
			if on then
				v.roar:Resume()
				v.hum:Resume()
			else
				v.roar:Pause()
				v.hum:Pause()
			end
		end
	end
end

---------------------------------------------------------------------
-- honks
---------------------------------------------------------------------
local recent: { number } = {} -- clock of each honk in the window
local lastHonk = 0
local state: { [any]: any } = setmetatable({}, { __mode = "k" }) :: any

local function canHonk(now: number): boolean
	for i = #recent, 1, -1 do
		if now - recent[i] > HONK_WINDOW then
			table.remove(recent, i)
		end
	end
	return #recent < HONK_CAP and now - lastHonk > HONK_GAP
end

local function blow(npc, st, pattern: string)
	local spec = HORN[npc.model:GetAttribute("TrafficId") or ""] or { "HornCar", if npc.racer then 1.06 else 1 }
	local id = Audio.pickCustom(spec[1])
	if not id then
		return
	end
	local now = os.clock()
	table.insert(recent, now)
	lastHonk = now
	st.cool = now + CAR_COOL + math.random() * 2
	local beeps = if pattern == "double" then { 0.13, 0.15 } elseif pattern == "long" then { 0.55 + math.random() * 0.35 } else { 0.14 }
	task.spawn(function()
		for i, len in beeps do
			if not npc.root.Parent then
				return
			end
			local s = Instance.new("Sound")
			s.Name = "Honk"
			s.SoundId = id
			s.Volume = 0.75
			s.PlaybackSpeed = spec[2] * st.pitch
			s.RollOffMode = Enum.RollOffMode.InverseTapered
			s.RollOffMinDistance = 14
			s.RollOffMaxDistance = 240
			s.Parent = npc.root
			s:Play()
			task.wait(len)
			-- a short fade, not a click at the cut
			for k = 1, 4 do
				s.Volume = 0.75 * (1 - k / 4)
				task.wait(0.01)
			end
			s:Destroy()
			if i < #beeps then
				task.wait(0.09)
			end
		end
	end)
	if npc.model:GetAttribute("Staged") or Workspace:GetAttribute("TestHonkLog") then
		Workspace:SetAttribute("TestHonkLog", string.format("%s %s %.1f", tostring(npc.model:GetAttribute("TrafficId")), pattern, now))
	end
end

-- a person on the road just ahead of a car (Traffic.peds: street people crossing)
local function pedAhead(npc, peds: { any }?): boolean
	for _, o in peds or {} do
		local rel = o.pos - npc.pos
		local f = rel:Dot(npc.fwd)
		if f > 0 and f < 26 and math.abs(rel:Dot(npc.fwd:Cross(Vector3.yAxis))) < npc.width / 2 + 2 then
			return true
		end
	end
	return false
end

local function honks(dt: number, cars: { any }, camPos: Vector3, peds: { any }?)
	local now = os.clock()
	if not canHonk(now) then
		return
	end
	for _, npc in cars do
		if (npc.pos - camPos).Magnitude > HONK_EAR or not npc.model.Parent then
			continue
		end
		local st = state[npc]
		if not st then
			st = { cool = now + math.random() * 3, block = 0, ped = 0, queue = 0, pitch = 0.96 + math.random() * 0.08, gap = npc.gapNow, offTo = npc.offTo, asked = false }
			state[npc] = st
		end
		local gap = npc.gapNow or math.huge
		local stopped = npc.speed < 1
		local ped = stopped and gap < 26 and not npc.gapPlayer and pedAhead(npc, peds)
		-- how long it has been held: by the player's car, by a person, in a queue
		st.block = if npc.gapPlayer and stopped and gap < 16 then st.block + dt else 0
		st.ped = if ped then st.ped + dt else 0
		local queued = stopped and gap < 14 and not npc.gapPlayer and not ped
		st.queue = if queued then st.queue + dt else 0
		if not queued and not ped then
			st.asked = false
		end
		local cutIn = st.gap and gap < 25 and st.gap - gap > 8 and npc.speed > 8
		local overtake = npc.racer and npc.offTo and st.offTo and math.abs(npc.offTo - st.offTo) > 1 and npc.speed > 15
		local atIt = npc.gapPlayer and (npc.gapAlign or 1) < -0.5 and gap < 45 and npc.speed > 5
		st.gap, st.offTo = gap, npc.offTo
		if now < st.cool then
			continue
		end
		local pattern: string? = nil
		if st.block > 1.4 or atIt then
			pattern = if math.random() < 0.5 then "long" else "double"
		elseif cutIn then
			pattern = if npc.gapPlayer then "double" else "tap"
		elseif overtake and math.random() < 0.5 then
			pattern = "tap"
		elseif (st.ped > 2.5 or st.queue > 5) and not st.asked then
			st.asked = true -- (one go per wait)
			if math.random() < (if st.ped > 2.5 then 0.3 else 0.15) then
				pattern = "tap"
			end
		end
		if pattern then
			blow(npc, st, pattern)
			if not canHonk(now) then
				return
			end
		end
	end
end

function TrafficSounds.step(dt: number, cars: { any }, running: boolean, peds: { any }?)
	local cam = Workspace.CurrentCamera
	if not cam then
		return
	end
	local camPos = cam.CFrame.Position
	if lastCam and dt > 0 then
		local v = (camPos - lastCam) / dt
		camVel = if v.Magnitude > 400 then Vector3.zero else camVel:Lerp(v, math.min(dt * 8, 1)) -- (a teleport is no speed)
	end
	lastCam = camPos
	if not running then
		cars = {}
	end
	passBy(dt, cars, camPos)
	if running and dt > 0 then
		honks(dt, cars, camPos, peds)
	end
end

-- (for a look in Studio: the voices playing now)
function TrafficSounds.playing(): number
	local n = 0
	for _, v in voices do
		if v.roar.IsPlaying then
			n += 1
		end
	end
	return n
end

return TrafficSounds
