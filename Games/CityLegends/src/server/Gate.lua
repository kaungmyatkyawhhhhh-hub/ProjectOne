--[[
	Gate
	The Summit's gate on Legends Isle (owner, 2026-10-29: a gated community on top of the mountain
	with police guards and a barrier that opens only for residents).

	  * residents: players who own a top tier house (Config.Houses.Types with tier >= Resident)
	  * the two steel gates slide open (about 3 s, a motor hum and a clunk) for a car that a
	    resident drives, rides in (passenger seat) or is driven in by the chauffeur, and for a
	    resident walking up; they close again behind them; wanted players are refused
	  * anyone else who gets inside (tailgating, on foot over the rocks) is put back outside the
	    gate with a message; police chases can't follow because nobody wanted gets in
	  * two guards: one at the guard house, one walking his beat by the gate
	The guard house, pillars, walls, arch and cameras are scenery (Isle); the gates and the guards are
built here at start.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local IsleLayout = require(Shared:WaitForChild("IsleLayout"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local Gate = {}

local RESIDENT_TIER = 2 -- the house tier that lives on the Summit
local OPEN_RANGE = 70 -- studs from the gate where an allowed car opens it (it takes 3 s)
local SLIDE_TIME = 3
local HALF = IsleLayout.Road / 2

local ctx: any
local fx: RemoteEvent?
local leaves: { { part: BasePart, closed: CFrame, open: CFrame } } = {}
local motor: Sound? = nil
local clunk: Sound? = nil
local isOpen = false
local lastAllowed = 0
local warned: { [Player]: number } = {}

local NAVY = Color3.fromRGB(24, 32, 58)
local BLACK = Color3.fromRGB(20, 20, 24)

---------------------------------------------------------------------
-- Who may go in
---------------------------------------------------------------------
function Gate.isResident(player: Player): boolean
	local profile = PlayerData.get(player)
	if not profile or not profile.Houses then
		return false
	end
	for id in profile.Houses do
		local t = Config.Houses.Types[id]
		if t and t.tier >= RESIDENT_TIER then
			return true
		end
	end
	return false
end

local function wanted(player: Player): boolean
	return ((player:GetAttribute("Wanted") :: number?) or 0) > 0
end

local function send(player: Player, text: string)
	local t = warned[player]
	if t and os.clock() - t < 4 then
		return
	end
	warned[player] = os.clock()
	if fx then
		fx:FireClient(player, { kind = "toast", text = text, color = "warning" })
	end
end

-- the people in a car: its driver (owner, when not on foot) or the chauffeur's rider, and riders
local function occupants(car: Model): { Player }
	local out: { Player } = {}
	local owner = Players:GetPlayerByUserId((car:GetAttribute("Owner") :: number?) or 0)
	if car.Parent and car.Parent.Name == "Chauffeurs" then
		local name = car.Name:match("^Chauffeur_(.+)$")
		local rider = if name then Players:FindFirstChild(name) else nil
		if rider and rider:IsA("Player") then
			table.insert(out, rider)
		end
	elseif owner and not owner.Character then
		table.insert(out, owner)
	end
	for _, s in car:GetChildren() do
		if s:IsA("Seat") and s.Occupant then
			local p = Players:GetPlayerFromCharacter(s.Occupant.Parent)
			if p then
				table.insert(out, p)
			end
		end
	end
	return out
end

-- may this car go through? (a resident aboard, nobody aboard wanted)
local function carAllowed(car: Model): (boolean, Player?)
	local people = occupants(car)
	local resident = false
	for _, p in people do
		if wanted(p) then
			return false, p
		end
		if Gate.isResident(p) then
			resident = true
		end
	end
	return resident, people[1]
end

---------------------------------------------------------------------
-- The gates and the guards
---------------------------------------------------------------------
-- the two gate leaves: black steel frames with bars, each covering half the road, sliding out
-- behind the walls to open (owner, 2026-10-29: "a sliding or swinging metal gate")
local function buildGates(parent: Instance)
	local g = IsleLayout.GateCFrame
	local half = HALF + 0.5 -- each leaf covers half the road and a little more
	local height = 10
	local z = -4.6 -- just inside the pillars and walls
	for _, s in { -1, 1 } do
		local closed = g * CFrame.new(s * half / 2, 0.5, z)
		local open = closed * CFrame.new(s * (half + 3), 0, 0)
		local rail = Instance.new("Part")
		rail.Name = "GateLeaf"
		rail.Anchored = true
		rail.Size = Vector3.new(half, 0.8, 0.6)
		rail.Color = Color3.fromRGB(30, 31, 34)
		rail.Material = Enum.Material.Metal
		rail.CFrame = closed
		rail.CanCollide = true
		-- the frame and the bars, welded to the bottom rail so they move with it
		local function piece(size: Vector3, offset: CFrame, collide: boolean)
			local p = Instance.new("Part")
			p.Anchored = false
			p.Massless = true
			p.CanCollide = collide
			p.Size = size
			p.Color = Color3.fromRGB(30, 31, 34)
			p.Material = Enum.Material.Metal
			p.CFrame = closed * offset
			local w = Instance.new("WeldConstraint")
			w.Part0 = rail
			w.Part1 = p
			w.Parent = p
			p.Parent = rail
		end
		piece(Vector3.new(half, 0.6, 0.6), CFrame.new(0, height, 0), false)
		piece(Vector3.new(half, 0.4, 0.5), CFrame.new(0, height * 0.45, 0), false)
		piece(Vector3.new(0.6, height, 0.6), CFrame.new(-half / 2 + 0.3, height / 2, 0), false)
		piece(Vector3.new(0.6, height, 0.6), CFrame.new(half / 2 - 0.3, height / 2, 0), false)
		local bars = math.floor(half / 1.5)
		for k = 1, bars - 1 do
			piece(Vector3.new(0.25, height, 0.25), CFrame.new(-half / 2 + k * half / bars, height / 2, 0), false)
		end
		-- one solid panel inside the bars that stops cars (the bars alone are thin)
		piece(Vector3.new(half, height, 0.3), CFrame.new(0, height / 2, 0), true)
		for _, c in rail:GetChildren() do
			if c:IsA("BasePart") and c.Size.Z == 0.3 then
				c.Transparency = 1 -- (invisible: you see the bars)
			end
		end
		rail.Parent = parent
		table.insert(leaves, { part = rail, closed = closed, open = open })
	end
	-- the gate motor's hum while they move, and a clunk when they stop
	local box = Instance.new("Part")
	box.Name = "GateMotor"
	box.Anchored = true
	box.CanCollide = false
	box.Transparency = 1
	box.Size = Vector3.new(1, 1, 1)
	box.CFrame = g * CFrame.new(0, 3, z)
	box.Parent = parent
	local m = Instance.new("Sound")
	m.SoundId = "rbxasset://sounds/action_falling.ogg"
	m.PlaybackSpeed = 0.32
	m.Volume = 0.7
	m.Looped = true
	m.RollOffMaxDistance = 160
	m.Parent = box
	motor = m
	local c = Instance.new("Sound")
	c.SoundId = "rbxasset://sounds/action_jump_land.mp3"
	c.PlaybackSpeed = 0.55
	c.Volume = 0.9
	c.RollOffMaxDistance = 160
	c.Parent = box
	clunk = c
end

local slideId = 0
local function setOpen(open: boolean)
	if open == isOpen or #leaves == 0 then
		return
	end
	isOpen = open
	slideId += 1
	local id = slideId
	local info = TweenInfo.new(SLIDE_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	for _, l in leaves do
		-- (they stop blocking as soon as they start opening, and block again once shut)
		if open then
			l.part.CanCollide = false
			for _, c in l.part:GetChildren() do
				if c:IsA("BasePart") and c.Transparency == 1 then
					c.CanCollide = false
				end
			end
		end
		TweenService:Create(l.part, info, { CFrame = if open then l.open else l.closed }):Play()
	end
	if motor then
		motor:Play()
	end
	task.delay(SLIDE_TIME, function()
		if id ~= slideId then
			return
		end
		if motor then
			motor:Stop()
		end
		if clunk then
			clunk:Play()
		end
		if not open then
			for _, l in leaves do
				l.part.CanCollide = true
				for _, c in l.part:GetChildren() do
					if c:IsA("BasePart") and c.Transparency == 1 then
						c.CanCollide = true
					end
				end
			end
		end
	end)
end

-- a police guard (Roblox's default avatar in uniform), standing or walking a beat
local function guard(parent: Instance, name: string, a: CFrame, b: CFrame?)
	task.spawn(function()
		local ok, rig = pcall(function()
			local d = Instance.new("HumanoidDescription")
			d.HeadColor = Color3.fromRGB(204, 160, 120)
			d.TorsoColor = NAVY
			d.LeftArmColor = NAVY
			d.RightArmColor = NAVY
			d.LeftLegColor = BLACK
			d.RightLegColor = BLACK
			return Players:CreateHumanoidModelFromDescription(d, Enum.HumanoidRigType.R6)
		end)
		if not ok or not rig then
			return
		end
		local model = rig :: Model
		model.Name = name
		local root = model:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hum = model:FindFirstChildOfClass("Humanoid")
		local head = model:FindFirstChild("Head") :: BasePart?
		local torso = model:FindFirstChild("Torso") :: BasePart?
		if not (root and hum and head and torso) then
			return
		end
		root.Anchored = true
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		-- a police cap and a badge
		local function weld(part: BasePart, to: BasePart)
			part.Anchored = false
			part.CanCollide = false
			part.Massless = true
			local w = Instance.new("WeldConstraint")
			w.Part0 = to
			w.Part1 = part
			w.Parent = part
			part.Parent = model
		end
		local cap = Instance.new("Part")
		cap.Shape = Enum.PartType.Cylinder
		cap.Size = Vector3.new(0.6, 1.35, 1.35)
		cap.Color = NAVY
		cap.CFrame = head.CFrame * CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, math.pi / 2)
		weld(cap, head)
		local brim = Instance.new("Part")
		brim.Size = Vector3.new(1.1, 0.1, 0.5)
		brim.Color = BLACK
		brim.CFrame = head.CFrame * CFrame.new(0, 0.32, -0.75)
		weld(brim, head)
		local badge = Instance.new("Part")
		badge.Size = Vector3.new(0.4, 0.45, 0.08)
		badge.Color = Color3.fromRGB(214, 180, 90)
		badge.Material = Enum.Material.Metal
		badge.CFrame = torso.CFrame * CFrame.new(-0.5, 0.4, -0.52)
		weld(badge, torso)
		model:PivotTo(a * CFrame.new(0, 3, 0))
		model.Parent = parent
		local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator")
		animator.Parent = hum
		local function track(id: string): AnimationTrack?
			local anim = Instance.new("Animation")
			anim.AnimationId = id
			local okT, t = pcall(function()
				return (animator :: Animator):LoadAnimation(anim)
			end)
			return if okT then t else nil
		end
		local idle = track("rbxassetid://180435571")
		local walk = track("rbxassetid://180426354")
		if idle then
			idle.Looped = true
			idle:Play()
		end
		if not b then
			return
		end
		-- the beat: walk to b, look round, walk back
		local from, to = a, b :: CFrame
		while model.Parent do
			local dist = (to.Position - from.Position).Magnitude
			local face = CFrame.lookAt(from.Position, to.Position)
			if walk then
				walk:Play()
			end
			local tw = TweenService:Create(root, TweenInfo.new(dist / 6, Enum.EasingStyle.Linear), { CFrame = (face + (to.Position - from.Position)) * CFrame.new(0, 3, 0) })
			root.CFrame = face * CFrame.new(0, 3, 0)
			tw:Play()
			tw.Completed:Wait()
			if walk then
				walk:Stop()
			end
			task.wait(4)
			from, to = to, from
		end
	end)
end

---------------------------------------------------------------------
-- The watch: lift the barrier for the right cars, put intruders back out
---------------------------------------------------------------------
local function outside(): CFrame
	-- on the mid ring just outside the gate, facing away from it
	local g = IsleLayout.GateCFrame
	local p = (g * CFrame.new(0, 0, 40)).Position
	return CFrame.lookAt(p, p + g.LookVector * -1)
end

local function putOut(player: Player, car: Model?)
	local cf = outside()
	if car then
		local h = (car:GetAttribute("Height") :: number?) or 4
		car:PivotTo(cf + Vector3.new(0, h / 2 + 0.5, 0))
		local root = car.PrimaryPart
		if root then
			root.AssemblyLinearVelocity = Vector3.zero
		end
	elseif player.Character then
		player.Character:PivotTo(cf + Vector3.new(6, 3, 0))
	end
	send(player, "The Summit is residents only")
end

local function step()
	local gatePos = IsleLayout.GateCFrame.Position
	local open = false
	local cars: { Model } = {}
	for _, name in { "PlayerCars", "Chauffeurs" } do
		local f = workspace:FindFirstChild(name)
		if f then
			for _, m in f:GetChildren() do
				if m:IsA("Model") and m.PrimaryPart then
					table.insert(cars, m)
				end
			end
		end
	end
	for _, car in cars do
		local pos = (car.PrimaryPart :: BasePart).Position
		local near = (pos - gatePos).Magnitude < OPEN_RANGE
		local inside = IsleLayout.inGated(pos)
		if near or inside then
			local ok, who = carAllowed(car)
			if ok then
				open = open or near
			elseif inside and who then
				putOut(who, car)
			elseif near and who then
				send(who, if wanted(who) then "The guards won't let a wanted driver in" else "The Summit is residents only: the barrier stays down")
			end
		end
	end
	-- people on foot
	for _, p in Players:GetPlayers() do
		local char = p.Character
		local root = if char then char:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
		local hum = if char then char:FindFirstChildOfClass("Humanoid") else nil
		if root and hum and not hum.SeatPart then
			local inside = IsleLayout.inGated(root.Position)
			local near = (root.Position - gatePos).Magnitude < 22
			local ok = Gate.isResident(p) and not wanted(p)
			if inside and not ok then
				putOut(p, nil)
			elseif near and ok then
				open = true
			end
		end
	end
	if open then
		lastAllowed = os.clock()
	end
	setOpen(open or os.clock() - lastAllowed < 2.5)
end

-- may the chauffeur drive this player up there?
function Gate.mayEnter(player: Player): boolean
	return Gate.isResident(player) and not wanted(player)
end

function Gate.init(c: any)
	ctx = c
	fx = ctx.remote("RemoteEvent", "HouseFx")
	local folder = Instance.new("Folder")
	folder.Name = "SummitGate"
	folder.Parent = workspace
	buildGates(folder)
	local g = IsleLayout.GateCFrame
	-- one at the guard house door, one walking along the road's edge outside the barrier
	guard(folder, "GateGuard", g * CFrame.new(-(HALF + 6), 0, 4) * CFrame.Angles(0, math.rad(90), 0), nil)
	guard(folder, "GatePatrol", g * CFrame.new(HALF + 6, 0, 8), g * CFrame.new(HALF + 6, 0, 30))
	task.spawn(function()
		while true do
			task.wait(0.25)
			local okStep, err = pcall(step)
			if not okStep then
				warn("[CityLegends] gate:", err)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		warned[p] = nil
	end)
end

return Gate
