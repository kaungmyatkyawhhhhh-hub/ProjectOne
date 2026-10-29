--[[
	CITY LEGENDS - server entry point
	  * builds the city
	  * spawns player cars (client-owned physics)
	  * pays passive driving income + validates "cut up" rewards
	  * XP / levels (earned with the same events as cash) + the daily gift
	  * garage purchases + saving
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Cars = require(Shared:WaitForChild("Cars"))
local CarBuilder = require(Shared:WaitForChild("CarBuilder"))
local CityLayout = require(Shared:WaitForChild("CityLayout"))

local CityBuilder = require(script.Parent:WaitForChild("CityBuilder"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local OnFoot = require(script.Parent:WaitForChild("OnFoot"))
local Police = require(script.Parent:WaitForChild("Police"))
local Bank = require(script.Parent:WaitForChild("Bank"))
local Activities = require(script.Parent:WaitForChild("Activities"))
local Houses = require(script.Parent:WaitForChild("Houses"))
local Hotel = require(script.Parent:WaitForChild("Hotel"))
local Towers = require(script.Parent:WaitForChild("Towers"))
local Chauffeur = require(script.Parent:WaitForChild("Chauffeur"))

Players.CharacterAutoLoads = false

---------------------------------------------------------------------
-- Remotes (created before the slow city build so clients can connect)
---------------------------------------------------------------------
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
local function remote(className: string, name: string): any
	-- (one remote per name: several systems share some, like HouseFx for Houses, Realty and the
	-- Summit gate; a second one of the same name would never reach the client's listener)
	local existing = remotes:FindFirstChild(name)
	if existing and existing:IsA(className) then
		return existing
	end
	local r = Instance.new(className)
	r.Name = name
	r.Parent = remotes
	return r
end
local GetData: RemoteFunction = remote("RemoteFunction", "GetData")
local BuyCar: RemoteFunction = remote("RemoteFunction", "BuyCar")
local SpawnCar: RemoteEvent = remote("RemoteEvent", "SpawnCar")
local DespawnCar: RemoteEvent = remote("RemoteEvent", "DespawnCar")
local CutUp: RemoteEvent = remote("RemoteEvent", "CutUp")
local Crash: RemoteEvent = remote("RemoteEvent", "Crash")
local Earned: RemoteEvent = remote("RemoteEvent", "Earned")
local Progress: RemoteEvent = remote("RemoteEvent", "Progress") -- server -> client XP / level updates
local ClaimDaily: RemoteFunction = remote("RemoteFunction", "ClaimDaily")
local SaveSettings: RemoteEvent = remote("RemoteEvent", "SaveSettings") -- client -> server: speed units, gearbox
local CarSignals: RemoteEvent = remote("RemoteEvent", "CarSignals") -- client -> server: blinkers + lights, shown to everyone
local Knock: RemoteEvent = remote("RemoteEvent", "Knock") -- a prop knocked down (Knockables): passed on to everyone else
remotes.Parent = ReplicatedStorage

-- the car stock market (its own remotes, MarketCall / MarketPush)
require(script.Parent:WaitForChild("Market")).start(remotes)

local playerCars = Instance.new("Folder")
playerCars.Name = "PlayerCars"
playerCars.Parent = workspace

local cityStart = os.clock()
CityBuilder.build()
print(string.format("[CityLegends] city built in %.2fs", os.clock() - cityStart))

---------------------------------------------------------------------
-- Per-player runtime state
---------------------------------------------------------------------
type Session = {
	car: Model?,
	combo: number,
	lastCut: number,
	cutTimes: { number },
	incomeCarry: number,
	xpCarry: number,
}
local sessions: { [Player]: Session } = {}

local function getSession(player: Player): Session
	local s = sessions[player]
	if not s then
		s = { car = nil, combo = 0, lastCut = 0, cutTimes = {}, incomeCarry = 0, xpCarry = 0 }
		sessions[player] = s
	end
	return s
end

local function horizontalSpeed(part: BasePart): number
	local v = part.AssemblyLinearVelocity
	return Vector3.new(v.X, 0, v.Z).Magnitude
end

---------------------------------------------------------------------
-- XP / levels
---------------------------------------------------------------------
local function grantXp(player: Player, amount: number, source: string)
	local result = PlayerData.addXp(player, amount)
	if not result then
		return
	end
	Progress:FireClient(player, {
		level = result.level,
		xp = result.xp,
		need = result.need,
		gained = math.floor(amount),
		source = source,
		levelUp = result.levels > 0,
		reward = result.reward,
	})
	if result.levels > 0 then
		task.spawn(PlayerData.save, player)
	end
end

---------------------------------------------------------------------
-- Car spawning
---------------------------------------------------------------------
local graph = CityLayout.buildGraph()
local spawnRng = Random.new()

local function findSpawnCFrame(): CFrame
	local candidates = {}
	for _, seg in graph.lanes do
		local mid = (seg.p0 + seg.p2) / 2
		if mid.Magnitude < 520 then
			table.insert(candidates, seg)
		end
	end
	for _ = 1, 30 do
		local seg = candidates[spawnRng:NextInteger(1, #candidates)]
		local s = spawnRng:NextNumber(30, seg.length * 0.6)
		local pos, dir = CityLayout.sample(seg, s)
		local free = true
		for _, car in playerCars:GetChildren() do
			if car:IsA("Model") and (car:GetPivot().Position - pos).Magnitude < 45 then
				free = false
				break
			end
		end
		if free then
			return CFrame.lookAt(pos, pos + dir)
		end
	end
	local seg = candidates[1]
	local pos, dir = CityLayout.sample(seg, 40)
	return CFrame.lookAt(pos, pos + dir)
end

-- the start block (Config.Spawn): its middle at ground level and the edge players start on
local function startBlock(): (Vector3, Vector3, number)
	local bi, bj = Config.Spawn.Block[1], Config.Spawn.Block[2]
	local c = Vector3.new((CityLayout.roadCoord(bi) + CityLayout.roadCoord(bi + 1)) / 2, 0, (CityLayout.roadCoord(bj) + CityLayout.roadCoord(bj + 1)) / 2)
	return c, Config.Spawn.Side, Config.City.BlockSize - Config.City.RoadWidth
end

local function carNear(pos: Vector3, range: number): boolean
	for _, car in playerCars:GetChildren() do
		if car:IsA("Model") and (car:GetPivot().Position - pos).Magnitude < range then
			return true
		end
	end
	return false
end

-- a first car: on the street along the start block's edge, in a lane clear of other players' cars
local function startSpawnCFrame(): CFrame?
	local c, side, inner = startBlock()
	local edge = c + side * (inner / 2 + Config.City.RoadWidth / 2) -- the road's centre line
	local along = side:Cross(Vector3.yAxis)
	local spots = {}
	for _, seg in graph.lanes do
		for s = 30, seg.length - 30, 12 do
			local pos, dir = CityLayout.sample(seg, s)
			local off = pos - edge
			-- on this road (the lanes on the block's side, not a crossing street), beside the block, not in a junction
			if off:Dot(side) < 0 and off:Dot(side) > -Config.City.RoadWidth / 2 and math.abs(off:Dot(along)) < inner * 0.4 and math.abs(dir:Dot(along)) > 0.9 then
				table.insert(spots, CFrame.lookAt(pos, pos + dir))
			end
		end
	end
	for _ = 1, #spots do
		local cf = spots[spawnRng:NextInteger(1, #spots)]
		if not carNear(cf.Position, 30) then
			return cf
		end
	end
	return nil
end

-- the start block's sidewalk, by the streetscape, facing the road (OnFoot: on foot with no car)
local function startFootCFrame(): CFrame
	local c, side, inner = startBlock()
	local along = side:Cross(Vector3.yAxis)
	-- between the planters and the bench, a few studs in from the curb
	local pos = c + side * (inner / 2 - 11) - along * (inner * 0.04) + Vector3.new(0, Config.City.CurbHeight + 3.2, 0)
	return CFrame.lookAt(pos, pos + side)
end

-- a car called while on foot: on the ground right in front of you when there's room for it
local function frontSpawnCFrame(player: Player, size: Vector3): CFrame?
	local character = player.Character
	local hrp = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
	if not hrp then
		return nil
	end
	local look = Vector3.new(hrp.CFrame.LookVector.X, 0, hrp.CFrame.LookVector.Z)
	if look.Magnitude < 0.1 then
		return nil
	end
	look = look.Unit
	local right = look:Cross(Vector3.yAxis)
	local ray = RaycastParams.new()
	ray.FilterType = Enum.RaycastFilterType.Exclude
	ray.FilterDescendantsInstances = { character, playerCars }
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.FilterDescendantsInstances = { character }
	overlap.RespectCanCollide = true
	-- the car stands across your path (side on), close first, then a little further or to a side
	for _, d in { size.X / 2 + 5, size.X / 2 + 9, Config.Spawn.FrontRange } do
		for _, sideOff in { 0, -6, 6 } do
			local at = hrp.Position + look * d + right * sideOff
			local hit = workspace:Raycast(at + Vector3.new(0, 6, 0), Vector3.new(0, -14, 0), ray)
			if hit and hit.Normal.Y > 0.9 then
				local cf = CFrame.lookAt(hit.Position, hit.Position + right)
				local blocked = workspace:GetPartBoundsInBox(cf + Vector3.new(0, size.Y / 2 + 0.6, 0), size + Vector3.new(1, 0, 1), overlap)
				if #blocked == 0 and not carNear(hit.Position, 12) then
					return cf
				end
			end
		end
	end
	return nil
end

-- one-off spawn spots for a player's next car (the hotel valet brings it round to the door)
local spawnAt: { [Player]: CFrame } = {}

-- what the gameplay modules (on foot, police, bank) get from here
local ctx = {
	remote = remote,
	getCar = function(player: Player): Model?
		local car = getSession(player).car
		return if car and car.Parent then car else nil
	end,
	grantXp = grantXp,
	playerCars = playerCars,
	-- the next car this player drives out starts here (ground level, facing the way to go)
	spawnAt = spawnAt,
	-- the start block's sidewalk (a player on foot with no car stands up there)
	startFootCFrame = startFootCFrame,
	setSpawnAt = function(player: Player, cf: CFrame)
		spawnAt[player] = cf
	end,
	-- hands the player's car over (the hotel valet drives it away): it stops being their car
	releaseCar = function(player: Player): Model?
		local s = getSession(player)
		local car = s.car
		s.car = nil
		s.combo = 0
		return if car and car.Parent then car else nil
	end,
}
OnFoot.init(ctx)
Police.init(ctx)
Bank.init(ctx, Police)
Activities.init(ctx)
Houses.init(ctx)
require(script.Parent:WaitForChild("Realty")).init(ctx) -- Legends Realty: the house catalogue
-- the Summit's gate on Legends Isle (residents only)
require(script.Parent:WaitForChild("Gate")).init(ctx)
Hotel.init(ctx)
Chauffeur.init(ctx)
-- Legends Motors: new cars are bought there only (owner, 2026-10-23)
local Dealership = require(script.Parent:WaitForChild("Dealership"))
Dealership.init(ctx)
-- drift scoring, speed traps, jumps and the leaderboard
require(script.Parent:WaitForChild("Challenges")).init(ctx)
local Customs = require(script.Parent:WaitForChild("Customs"))
Customs.init(ctx)
-- the High-Rollers Casino and the Legends Gem Showcase, Downtown (VIP, flex items, two heists)
local Luxe = require(script.Parent:WaitForChild("Luxe"))
Luxe.init(ctx)
require(script.Parent:WaitForChild("Casino")).init(ctx, Police, Luxe)
require(script.Parent:WaitForChild("GemShowcase")).init(ctx, Police, Luxe)

local function despawn(player: Player)
	local s = getSession(player)
	if s.car then
		s.car:Destroy()
		s.car = nil
	end
	s.combo = 0
end

-- opts.stolen: a car taken from a garage (Parking): not theirs, never saved or selected;
-- opts.at: where it starts (ground level, facing the way out)
local function spawnFor(player: Player, carId: string, opts: { stolen: boolean?, at: CFrame? }?)
	local profile = PlayerData.get(player)
	local stolen = opts and opts.stolen
	if not profile or not (profile.Owned[carId] or (stolen and Cars.ById[carId])) then
		return
	end
	if not stolen then
		profile.Selected = carId
	end
	if opts and opts.at then
		spawnAt[player] = opts.at
	end
	-- swapping cars while driving: the new one comes out where the old one was
	local oldCar = getSession(player).car
	local swapCF: CFrame? = nil
	if oldCar and oldCar.Parent and not player.Character then
		local at = oldCar:GetPivot()
		local ray = RaycastParams.new()
		ray.FilterType = Enum.RaycastFilterType.Exclude
		ray.FilterDescendantsInstances = { playerCars }
		local hit = workspace:Raycast(at.Position + Vector3.new(0, 4, 0), Vector3.new(0, -30, 0), ray)
		local look = Vector3.new(at.LookVector.X, 0, at.LookVector.Z)
		if hit and look.Magnitude > 0.1 then
			swapCF = CFrame.lookAt(hit.Position, hit.Position + look.Unit)
		end
	end
	despawn(player)
	local onFoot = player.Character ~= nil

	local spec = Cars.get(carId)
	local model = CarBuilder.build(spec, { interior = true, lights = true, anchored = false })
	model:SetAttribute("Plate", string.upper(player.Name):gsub("[^%w]", ""):sub(1, 7))
	Customs.applyTo(player, model, carId) -- the car's Legends Customs look (and its own plate)
	model.Name = player.Name
	model:SetAttribute("Owner", player.UserId)
	if stolen then
		model:SetAttribute("Stolen", true)
	end

	local root = model.PrimaryPart :: BasePart
	local att = Instance.new("Attachment")
	att.Name = "DriveAttachment"
	att.Parent = root

	-- Velocity is controlled in the ground plane only, so gravity still works
	local lv = Instance.new("LinearVelocity")
	lv.Name = "Drive"
	lv.Attachment0 = att
	lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	lv.PrimaryTangentAxis = Vector3.xAxis
	lv.SecondaryTangentAxis = Vector3.zAxis
	lv.PlaneVelocity = Vector2.zero
	lv.MaxForce = 1e6
	lv.Parent = root

	local ao = Instance.new("AlignOrientation")
	ao.Name = "Steer"
	ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
	ao.Attachment0 = att
	ao.MaxTorque = 1e9
	ao.MaxAngularVelocity = 40
	ao.Responsiveness = 60
	ao.Parent = root

	-- (a house's "Drive" prompt and the hotel valet ask for their own spot; on foot: in front of
	-- you; otherwise the street by the start block)
	local h = model:GetAttribute("Height") :: number
	local spawnCF = spawnAt[player] or swapCF or (if onFoot then frontSpawnCFrame(player, Vector3.new(model:GetExtentsSize().X, h, model:GetExtentsSize().Z)) else nil) or startSpawnCFrame() or findSpawnCFrame()
	spawnAt[player] = nil
	OnFoot.removeCharacter(player) -- a car from the garage: straight in, off your feet
	-- (streaming: the ground there reaches the player's game before the car does)
	pcall(function()
		player:RequestStreamAroundAsync(spawnCF.Position, 6)
	end)
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic -- the whole car arrives at once
	model:PivotTo(spawnCF + Vector3.new(0, h / 2 + 0.3, 0))
	ao.CFrame = spawnCF.Rotation
	-- a big car reaches clients in pieces: they wait for this many before putting the body on
	model:SetAttribute("Pieces", #model:GetDescendants())
	model.Parent = playerCars

	lv.MaxForce = root.AssemblyMass * 400
	root:SetNetworkOwner(player)
	player.ReplicationFocus = root
	getSession(player).car = model
end

---------------------------------------------------------------------
-- Remotes
---------------------------------------------------------------------
GetData.OnServerInvoke = function(player: Player)
	local timeout = os.clock() + 10
	while not PlayerData.get(player) and os.clock() < timeout do
		task.wait(0.1)
	end
	return PlayerData.snapshot(player)
end

ClaimDaily.OnServerInvoke = function(player: Player)
	local ok, amount = PlayerData.claimDaily(player)
	local readyIn = PlayerData.dailyReadyIn(player)
	if not ok then
		return { ok = false, message = "Your next gift isn't ready yet", amount = 0, readyIn = readyIn }
	end
	task.spawn(PlayerData.save, player)
	return { ok = true, message = "Daily gift claimed", amount = amount, readyIn = readyIn }
end

BuyCar.OnServerInvoke = function(player: Player, carId: any)
	if type(carId) ~= "string" or not Cars.ById[carId] then
		return { ok = false, message = "Unknown car" }
	end
	local profile = PlayerData.get(player)
	if not profile then
		return { ok = false, message = "Profile not loaded" }
	end
	if profile.Owned[carId] then
		return { ok = true, message = "Already owned", data = PlayerData.snapshot(player) }
	end
	local spec = Cars.ById[carId]
	-- new cars come from the dealership, in person
	if not Dealership.near(player, ctx.getCar) then
		return { ok = false, message = "Buy new cars at " .. Config.Dealership.Name }
	end
	-- from the F430 up only the car market sells them; in a series each car opens 5 levels on
	if Cars.isMarketOnly(carId) then
		return { ok = false, message = "Only on the car market" }
	end
	local need = Cars.requiredLevel(carId)
	if (profile.Level or 1) < need then
		return { ok = false, message = "Unlocks at level " .. need }
	end
	if profile.Cash < spec.Price then
		return { ok = false, message = "Not enough cash" }
	end
	PlayerData.addCash(player, -spec.Price)
	profile.Owned[carId] = true
	task.spawn(PlayerData.save, player)
	return { ok = true, message = "Purchased " .. spec.Name, data = PlayerData.snapshot(player) }
end

-- the luxury towers' garages: parked cars to steal, paid VIP bays (after spawnFor, which a theft uses)
ctx.spawnCar = spawnFor
ctx.despawn = despawn
require(script.Parent:WaitForChild("Parking")).init(ctx, Police, Towers)

SpawnCar.OnServerEvent:Connect(function(player: Player, carId: any)
	if type(carId) ~= "string" then
		return
	end
	spawnFor(player, carId)
end)

-- the driver's blinkers and lights go on their car as attributes, so every player sees them
CarSignals.OnServerEvent:Connect(function(player: Player, raw: any)
	local car = getSession(player).car
	if not car or not car.Parent or type(raw) ~= "table" then
		return
	end
	if raw.blinker == "" or raw.blinker == "L" or raw.blinker == "R" or raw.blinker == "H" then
		car:SetAttribute("Blinker", raw.blinker)
	end
	if type(raw.lights) == "boolean" then
		car:SetAttribute("Lights", raw.lights)
	end
end)

-- a street light, tree or traffic pole knocked down: the other games drop it too (only from a
-- player whose car is right there, a few a second at most)
local lastKnock: { [Player]: { number } } = {}
Knock.OnServerEvent:Connect(function(player: Player, id: any, dir: any, speed: any)
	if type(id) ~= "string" or #id > 40 or typeof(dir) ~= "Vector3" or dir.Magnitude < 1 or dir.Magnitude ~= dir.Magnitude or type(speed) ~= "number" then
		return
	end
	local car = getSession(player).car
	local x, y, z = string.match(id, "^(-?%d+),(-?%d+),(-?%d+)$")
	if not (car and car.Parent and x) then
		return
	end
	if (car:GetPivot().Position - Vector3.new(tonumber(x) :: number, tonumber(y) :: number, tonumber(z) :: number)).Magnitude > 60 then
		return
	end
	local now = os.clock()
	local recent = lastKnock[player] or {}
	while recent[1] and now - recent[1] > 1 do
		table.remove(recent, 1)
	end
	if #recent >= 6 then
		return
	end
	table.insert(recent, now)
	lastKnock[player] = recent
	for _, other in Players:GetPlayers() do
		if other ~= player then
			Knock:FireClient(other, id, dir.Unit * math.min(dir.Magnitude, 400), math.clamp(speed, 0, 400))
		end
	end
end)
Players.PlayerRemoving:Connect(function(player)
	lastKnock[player] = nil
end)

SaveSettings.OnServerEvent:Connect(function(player: Player, raw: any)
	PlayerData.setSettings(player, raw) -- kept with the profile, saved with it
end)

DespawnCar.OnServerEvent:Connect(function(player: Player)
	despawn(player)
end)

Crash.OnServerEvent:Connect(function(player: Player)
	local s = getSession(player)
	if s.combo > 0 then
		s.combo = 0
		Earned:FireClient(player, { amount = 0, combo = 0, kind = "crash" })
	end
end)

local E = Config.Economy
CutUp.OnServerEvent:Connect(function(player: Player, info: any)
	if type(info) ~= "table" then
		return
	end
	local s = getSession(player)
	local car = s.car
	if not car or not car.PrimaryPart then
		return
	end
	local now = os.clock()
	if now - s.lastCut < E.CutCooldown then
		return
	end
	-- no more than 30 cuts in 10 seconds
	local recent = {}
	for _, t in s.cutTimes do
		if now - t < 10 then
			table.insert(recent, t)
		end
	end
	if #recent >= 30 then
		s.cutTimes = recent
		return
	end
	table.insert(recent, now)
	s.cutTimes = recent

	local spec = Cars.get(car:GetAttribute("CarId") :: string)
	local mph = math.min(Config.spsToMph(horizontalSpeed(car.PrimaryPart)), spec.TopSpeed * 1.2) -- (nitro boosts past the top speed)
	-- a little slack for replication lag
	if mph < E.CutMinMph * 0.8 then
		return
	end

	local closeness = math.clamp(tonumber(info.closeness) or 0, 0, 1)
	local oncoming = info.oncoming == true
	local thread = info.thread == true

	if now - s.lastCut <= E.ComboWindow then
		s.combo = math.min(s.combo + 1, E.ComboMax)
	else
		s.combo = 1
	end
	s.lastCut = now

	local speedFactor = math.clamp(mph / 100, 0.6, 2.6)
	local comboFactor = 1 + E.ComboStep * (s.combo - 1)
	local amount = E.CutBase * (0.6 + 0.8 * closeness) * speedFactor * comboFactor
	if oncoming then
		amount *= E.OncomingBonus
	end
	if thread then
		amount *= E.ThreadBonus
	end
	amount = math.floor(amount)
	PlayerData.addCash(player, amount)

	local label = if thread then "THREAD THE NEEDLE" elseif oncoming then "ONCOMING CUT" elseif closeness > 0.75 then "INSANE CUT" elseif closeness > 0.4 then "CLOSE CUT" else "CUT UP"
	Earned:FireClient(player, { amount = amount, combo = s.combo, kind = "cut", label = label })

	local P = Config.Progression
	grantXp(player, math.clamp(math.floor(amount * P.CutXpPerCash + 0.5), 1, P.CutXpMax), "cut")
end)

---------------------------------------------------------------------
-- Passive driving income
---------------------------------------------------------------------
local incomeTimer = 0
RunService.Heartbeat:Connect(function(dt)
	incomeTimer += dt
	if incomeTimer < 0.5 then
		return
	end
	local step = incomeTimer
	incomeTimer = 0
	for player, s in sessions do
		local car = s.car
		if car and car.PrimaryPart then
			local spec = Cars.get(car:GetAttribute("CarId") :: string)
			local mph = math.min(Config.spsToMph(horizontalSpeed(car.PrimaryPart)), spec.TopSpeed * 1.2) -- (nitro boosts past the top speed)
			if mph >= E.DriveMinMph then
				s.incomeCarry += mph * E.DrivePerSecond * step
				local whole = math.floor(s.incomeCarry)
				if whole >= 1 then
					s.incomeCarry -= whole
					PlayerData.addCash(player, whole)
				end
				-- driving XP mirrors the driving income
				s.xpCarry += mph * Config.Progression.DriveXpPerSecond * step
				local xp = math.floor(s.xpCarry)
				if xp >= 1 then
					s.xpCarry -= xp
					grantXp(player, xp, "drive")
				end
			end
			-- drop combos that expired
			if s.combo > 0 and os.clock() - s.lastCut > E.ComboWindow then
				s.combo = 0
			end
		end
	end
end)

---------------------------------------------------------------------
-- Player lifecycle
---------------------------------------------------------------------
--[[
	Console money hook (server side only: Studio command bar, or the F9
	Developer Console's server command line in a live game, which only the
	game's owner / editors can use). Players can't trigger it: attributes they
	set on themselves don't replicate to the server.
	  game.Players.NAME:SetAttribute("SetCash", 1000000)  -- set to an amount
	  game.Players.NAME:SetAttribute("AddCash", 50000)    -- add (negative takes)
	  game.Players.NAME:SetAttribute("UnlockAllCars", true) -- own every car (testers)
	  game.Players.NAME:SetAttribute("UnlockEverything", true) -- cars, level, homes, VIP, items
]]
local function watchConsoleCash(player: Player)
	for _, attr in { "SetCash", "AddCash" } do
		player:GetAttributeChangedSignal(attr):Connect(function()
			local v = player:GetAttribute(attr)
			if type(v) ~= "number" then
				return
			end
			player:SetAttribute(attr, nil)
			local profile = PlayerData.get(player)
			if not profile then
				return
			end
			PlayerData.addCash(player, if attr == "SetCash" then v - profile.Cash else v)
			task.spawn(PlayerData.save, player)
			print(("[CityLegends] %s now has $%d"):format(player.Name, profile.Cash))
		end)
	end
end

-- testers (owner, 2026-10-22): own every car in the roster at once
local function watchConsoleUnlock(player: Player)
	player:GetAttributeChangedSignal("UnlockAllCars"):Connect(function()
		if player:GetAttribute("UnlockAllCars") ~= true then
			return
		end
		player:SetAttribute("UnlockAllCars", nil)
		local profile = PlayerData.get(player)
		if not profile then
			return
		end
		local n = 0
		for _, spec in Cars.List do
			if not profile.Owned[spec.Id] then
				profile.Owned[spec.Id] = true
				n += 1
			end
		end
		task.spawn(PlayerData.save, player)
		print(("[CityLegends] %s now owns every car (%d new)"):format(player.Name, n))
	end)
end

-- testers (owner, 2026-10-23: "a server command line to unlock everything"): every car, the
-- level every car needs, every penthouse and hotel suite, every house, every chauffeur contract,
-- the top VIP card and every flex item
local function watchConsoleEverything(player: Player)
	player:GetAttributeChangedSignal("UnlockEverything"):Connect(function()
		if player:GetAttribute("UnlockEverything") ~= true then
			return
		end
		player:SetAttribute("UnlockEverything", nil)
		local profile = PlayerData.get(player) :: any
		if not profile then
			return
		end
		local need = 1
		for _, spec in Cars.List do
			profile.Owned[spec.Id] = true
			need = math.max(need, Cars.requiredLevel(spec.Id))
		end
		if (profile.Level or 1) < need then
			profile.Level = need
			profile.XP = 0
		end
		Progress:FireClient(player, { level = profile.Level, xp = profile.XP or 0, need = Config.xpForLevel(profile.Level), gained = 0, source = "console", levelUp = false })
		profile.Penthouses = profile.Penthouses or {}
		for _, t in Config.Towers.List do
			profile.Penthouses[t.id] = true
		end
		for _, t in Config.Hotel.Suites do
			profile.Penthouses[t.id] = true
		end
		profile.Houses = profile.Houses or {}
		for kind in Config.Houses.Types do
			profile.Houses[kind] = true
		end
		profile.Chauffeur = profile.Chauffeur or {}
		for id in Config.Chauffeur.Fleet do
			profile.Chauffeur[id] = true
		end
		if profile.Home == "" or profile.Home == nil then
			profile.Home = Config.Towers.List[1].id
		end
		Towers.refresh(player)
		Houses.refresh(player)
		Luxe.unlockAll(player)
		task.spawn(PlayerData.save, player)
		print(("[CityLegends] %s has everything unlocked"):format(player.Name))
	end)
end

-- Streaming (owner, 2026-10-29: "i cant even load it up"): players get the map around them, not
-- all of it. Until their car or avatar is out, the city's middle streams in, where the menu and
-- the intro fly.
local focusFolder = Instance.new("Folder")
focusFolder.Name = "StreamFocus"
focusFolder.Parent = workspace
local function menuFocus(player: Player)
	local p = Instance.new("Part")
	p.Name = player.Name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.one
	p.Position = Vector3.new(500, 30, 0)
	p.Parent = focusFolder
	if not player.ReplicationFocus then
		player.ReplicationFocus = p
	end
end

local function onPlayerAdded(player: Player)
	menuFocus(player)
	getSession(player)
	watchConsoleCash(player)
	watchConsoleUnlock(player)
	watchConsoleEverything(player)
	PlayerData.load(player)
	-- Studio play tests start with everything unlocked and the test cash (owner, 2026-10-23:
	-- "always make me unlock all in the testing"); never in a live server
	if RunService:IsStudio() and Config.Testing.StudioUnlockAll then
		task.spawn(function()
			local timeout = os.clock() + 15
			while player.Parent and not PlayerData.get(player) and os.clock() < timeout do
				task.wait(0.2)
			end
			if player.Parent and PlayerData.get(player) then
				player:SetAttribute("UnlockEverything", true)
				player:SetAttribute("SetCash", Config.Testing.StudioCash)
			end
		end)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, p in Players:GetPlayers() do
	task.spawn(onPlayerAdded, p)
end

Players.PlayerRemoving:Connect(function(player)
	local f = focusFolder:FindFirstChild(player.Name)
	if f then
		f:Destroy()
	end
	despawn(player)
	sessions[player] = nil
	PlayerData.release(player)
end)

task.spawn(function()
	while true do
		task.wait(120)
		PlayerData.saveAll()
	end
end)

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		PlayerData.save(player)
	end
end)
