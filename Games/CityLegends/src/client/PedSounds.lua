--[[
	PedSounds (client, 27 Nov 2026)
	Owner: "npc footsteps (but only the npc nearest to ur camera that makes the footstep sound so it dont lag)",
	"add sound to npc when they get hit with car too". Vault: City Legends/2026-11-27 Traffic pass-by and footstep sounds.md

	  * footsteps: only the ONE street person nearest the camera within STEP_EAR studs, walking or running, steps.
	    A step plays when their walk cycle plants a foot (PedMotion: left heel at phase 0, right at 0.5). Slipper /
	    flip-flop steps (Config.Sounds.Step, 4 takes), softer walking, louder running; the ground under them sets the
	    feel (pavement as made, asphalt duller, grass / dirt soft). 3 pooled Sounds on one Attachment.
	  * hit by a car (PedHits calls PedSounds.hit): a body thud by speed (soft bump / heavy thud), a cartoon Roblox
	    "oof" / "ouch" (the client's own built-in voices, pitched up a little, kid-friendly) and a tumble scrape when
	    knocked down. One per person per HIT_COOL s, at most VOICE_CAP voices at once.
	Started from PedHits.start; reads YangonStreetLife.walkers() (only adds a walker's voicePitch).
]]

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Audio = require(script.Parent:WaitForChild("Audio"))

local PedSounds = {}

local STEP_EAR, PICK_EVERY = 40, 0.25
local HIT_COOL, VOICE_CAP = 1.2, 2
local VOICES = { "rbxasset://sounds/oof.ogg", "rbxasset://sounds/ouch.ogg" }
-- ground -> { volume x, pitch x }
local GROUND = {
	[Enum.Material.Asphalt] = { 0.85, 0.9 },
	[Enum.Material.Grass] = { 0.45, 0.8 },
	[Enum.Material.LeafyGrass] = { 0.45, 0.8 },
	[Enum.Material.Ground] = { 0.55, 0.82 },
	[Enum.Material.Mud] = { 0.5, 0.78 },
	[Enum.Material.Sand] = { 0.45, 0.85 },
	[Enum.Material.WoodPlanks] = { 1.0, 0.95 },
}

local att: Attachment? = nil
local pool: { Sound } = {}
local nextSound = 1
local who: any = nil
local lastK: number? = nil
local pickT = 0
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function pooled(): Sound?
	if not att then
		local a = Instance.new("Attachment")
		a.Name = "PedSounds"
		a.Parent = Workspace.Terrain
		att = a
		for _ = 1, 3 do
			local s = Instance.new("Sound")
			s.Name = "Step"
			s.RollOffMode = Enum.RollOffMode.InverseTapered
			s.RollOffMinDistance = 6
			s.RollOffMaxDistance = 60
			s.Parent = a
			table.insert(pool, s)
		end
	end
	local s = pool[nextSound]
	nextSound = nextSound % #pool + 1
	return s
end

local function plant(w)
	local id = Audio.pickCustom("Step")
	if not id then
		return
	end
	local s = pooled()
	if not s or not att then
		return
	end
	local foot = w.pos
	rayParams.FilterDescendantsInstances = { w.fig.model }
	local hit = Workspace:Raycast(foot + Vector3.new(0, 2, 0), Vector3.new(0, -6, 0), rayParams)
	local g = hit and GROUND[hit.Material] or { 1, 1 }
	local run = w.gait == "run"
	att.WorldPosition = if hit then hit.Position else foot
	s.SoundId = id
	s.Volume = (if run then 0.8 else 0.45) * g[1] * (0.9 + math.random() * 0.2)
	s.PlaybackSpeed = (if run then 1.06 else 0.97) * g[2] * (0.94 + math.random() * 0.12)
	s.TimePosition = 0
	s:Play()
end

local function step(dt: number)
	local StreetLife = PedSounds.streetLife
	local cam = Workspace.CurrentCamera
	if not StreetLife or not cam then
		return
	end
	local camPos = cam.CFrame.Position
	pickT -= dt
	if pickT <= 0 then
		pickT = PICK_EVERY
		local best, bestD = nil, STEP_EAR
		for _, w in StreetLife.walkers() do
			if w.gait and not w.held and not w.gone then
				local d = (w.pos - camPos).Magnitude
				if d < bestD then
					best, bestD = w, d
				end
			end
		end
		if best ~= who then
			who = best
			lastK = if best then math.floor((best.phase or 0) * 2) else nil
		end
	end
	local w = who
	if not w or w.held or w.gone or not w.gait or (w.pos - camPos).Magnitude > STEP_EAR + 5 then
		return
	end
	local k = math.floor((w.phase or 0) * 2)
	if lastK and k ~= lastK and k - lastK < 3 then -- (a foot came down; a jump of several = it was out of sight)
		plant(w)
	end
	lastK = k
end

---------------------------------------------------------------------
-- hit by a car
---------------------------------------------------------------------
local lastHit: { [any]: number } = setmetatable({}, { __mode = "k" }) :: any
local voicesOut: { number } = {}

local function oneShot(id: string, part: BasePart, volume: number, speed: number, maxD: number)
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume
	s.PlaybackSpeed = speed
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.RollOffMinDistance = 8
	s.RollOffMaxDistance = maxD
	s.Parent = part
	s:Play()
	task.delay(3, function()
		s:Destroy()
	end)
end

-- speed in studs/s at the contact; knocked = a ragdoll (thrown down), else a stumble
function PedSounds.hit(w: any, part: BasePart, speed: number, knocked: boolean)
	local now = os.clock()
	if lastHit[w] and now - lastHit[w] < HIT_COOL then
		return
	end
	lastHit[w] = now
	local k = math.clamp(speed / 60, 0, 1)
	local heavy = knocked and k > 0.3
	local thud = Audio.pickCustom(if heavy then "ThudHeavy" else "ThudSoft")
	if thud then
		oneShot(thud, part, if knocked then 0.5 + 0.4 * k else 0.35, 0.95 + math.random() * 0.1, 90)
	else
		Audio.play("thud", if knocked then 0.5 + 0.3 * k else 0.2, if knocked then 0.75 else 1.1, part)
	end
	for i = #voicesOut, 1, -1 do
		if now - voicesOut[i] > 0.8 then
			table.remove(voicesOut, i)
		end
	end
	if #voicesOut < VOICE_CAP and (knocked or math.random() < 0.6) then
		table.insert(voicesOut, now)
		-- (each person keeps one voice pitch: grown-ups lower, kids higher; Roblox-style, never a scream)
		local pitch = w.voicePitch or (0.95 + math.random() * 0.3)
		w.voicePitch = pitch
		oneShot(VOICES[math.random(1, #VOICES)], part, if knocked then 0.75 else 0.55, pitch, 80)
	end
	if knocked then
		local tumble = Audio.pickCustom("Tumble")
		if tumble then
			task.delay(0.3 + 0.2 * (1 - k), function()
				if part.Parent then
					oneShot(tumble, part, 0.35 + 0.35 * k, 0.9 + math.random() * 0.15, 70)
				end
			end)
		end
	end
end

local started = false
function PedSounds.start(streetLife: any)
	if started then
		return
	end
	started = true
	PedSounds.streetLife = streetLife
	RunService.Heartbeat:Connect(step)
end

return PedSounds
