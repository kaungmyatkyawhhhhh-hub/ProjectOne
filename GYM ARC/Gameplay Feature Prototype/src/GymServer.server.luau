--[[
	GymServer
	Server side of the lifting progression loop:
	  Train at a station -> timed reps earn Strength + Cash -> buy heavier
	  weights (bigger gains per rep) -> body grows and rank rises, visible to all.
	The server owns every number: it validates rep timing, cooldowns and purchases.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("GymConfig"))
local Util = require(ReplicatedStorage:WaitForChild("GymUtil"))
local GymWorld = require(script:WaitForChild("GymWorld"))
local PlayerData = require(script:WaitForChild("PlayerData"))

---------------------------------------------------------------------------
-- Remotes
---------------------------------------------------------------------------
local remotes = Instance.new("Folder")
remotes.Name = "GymRemotes"
remotes.Parent = ReplicatedStorage

local function makeRemote(name: string): RemoteEvent
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = remotes
	return r
end

local StartTraining = makeRemote("StartTraining") -- server -> client
local StopTraining = makeRemote("StopTraining") -- both ways
local Rep = makeRemote("Rep") -- client -> server (tap time)
local RepResult = makeRemote("RepResult") -- server -> client
local BuyWeight = makeRemote("BuyWeight") -- client -> server
local StatsChanged = makeRemote("StatsChanged") -- server -> client
local Announce = makeRemote("Announce") -- server -> all clients
local RequestStats = makeRemote("RequestStats") -- client -> server (on join)

---------------------------------------------------------------------------
-- State
---------------------------------------------------------------------------
local stations = GymWorld.build(Config.StationCount)
local sessions = {} -- [Player] = { station, zone, startTime, speed, lastRep, combo }

local function now(): number
	return workspace:GetServerTimeNow()
end

local function newZone(): number
	local half = Config.Rep.zoneWidth / 2
	return half + math.random() * (1 - Config.Rep.zoneWidth)
end

---------------------------------------------------------------------------
-- Visible-to-others feedback: leaderstats, overhead tag, body size
---------------------------------------------------------------------------
local function setupLeaderstats(player: Player)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local strength = Instance.new("StringValue")
	strength.Name = "Strength"
	strength.Parent = ls
	local rank = Instance.new("StringValue")
	rank.Name = "Rank"
	rank.Parent = ls
	ls.Parent = player
end

local function overheadFor(character: Model): BillboardGui?
	local head = character:FindFirstChild("Head")
	if not head then
		return nil
	end
	local existing = head:FindFirstChild("GymTag")
	if existing then
		return existing :: BillboardGui
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "GymTag"
	gui.Size = UDim2.fromOffset(220, 72)
	gui.StudsOffset = Vector3.new(0, 2.8, 0)
	gui.MaxDistance = 90
	gui.Parent = head
	local function label(name: string, y: number, h: number, font: Enum.Font): TextLabel
		local l = Instance.new("TextLabel")
		l.Name = name
		l.BackgroundTransparency = 1
		l.Position = UDim2.fromScale(0, y)
		l.Size = UDim2.fromScale(1, h)
		l.Font = font
		l.TextScaled = true
		l.TextColor3 = Color3.new(1, 1, 1)
		l.TextStrokeTransparency = 0.2
		l.Parent = gui
		return l
	end
	label("Rank", 0, 0.42, Enum.Font.GothamBlack)
	label("Info", 0.42, 0.3, Enum.Font.GothamBold)
	local combo = label("Combo", 0.72, 0.28, Enum.Font.GothamBlack)
	combo.TextColor3 = Color3.fromRGB(255, 150, 40)
	return gui
end

local function refreshVisuals(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	local _, rank = Util.rankFor(data.strength)
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		(ls :: any).Strength.Value = Util.format(data.strength)
		;(ls :: any).Rank.Value = rank.name
	end
	local character = player.Character
	if not character then
		return
	end
	local tag = overheadFor(character)
	if tag then
		local rankLabel = tag:FindFirstChild("Rank") :: TextLabel
		rankLabel.Text = string.upper(rank.name)
		rankLabel.TextColor3 = rank.color
		;(tag:FindFirstChild("Info") :: TextLabel).Text = "💪 " .. Util.format(data.strength) .. "   🏋 " .. Config.Weights[data.tier].name
		local session = sessions[player]
		local combo = session and session.combo or 0
		;(tag:FindFirstChild("Combo") :: TextLabel).Text = if combo >= 3 then ("🔥 x" .. combo .. " COMBO") else ""
	end
	-- body grows with Strength (R15). Tweened so other players see a smooth "pump".
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.RigType == Enum.HumanoidRigType.R15 then
		local w, d, h = Util.bodyScale(data.strength)
		for name, value in pairs({ BodyWidthScale = w, BodyDepthScale = d, BodyHeightScale = h }) do
			local scale = humanoid:FindFirstChild(name)
			if scale and scale:IsA("NumberValue") and math.abs(scale.Value - value) > 0.005 then
				TweenService:Create(scale, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Value = value }):Play()
			end
		end
	end
end

local function pushStats(player: Player)
	local data = PlayerData.get(player)
	if data then
		StatsChanged:FireClient(player, data)
	end
end

---------------------------------------------------------------------------
-- Training sessions
---------------------------------------------------------------------------
local function stopTraining(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	sessions[player] = nil
	local station = session.station
	station.occupant = nil
	station.prompt.Enabled = true
	station.signText.Text = "FREE"
	station.signText.TextColor3 = Color3.fromRGB(120, 255, 140)
	GymWorld.placeBarbell(station.barbell, station.restCFrame)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		(root :: BasePart).Anchored = false
	end
	StopTraining:FireClient(player)
	refreshVisuals(player)
end

local function startTraining(player: Player, station)
	if station.occupant or sessions[player] then
		return
	end
	local data = PlayerData.get(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not (data and humanoid and root and humanoid.Health > 0) then
		return
	end
	station.occupant = player
	station.prompt.Enabled = false
	station.signText.Text = player.DisplayName
	station.signText.TextColor3 = Color3.fromRGB(255, 220, 80)

	-- stand the player on the platform, facing the bar
	root.CFrame = station.standCFrame * CFrame.new(0, humanoid.HipHeight + root.Size.Y / 2, 0)
	root.Anchored = true

	local weight = Config.Weights[data.tier]
	GymWorld.setPlates(station.barbell, weight.plate, weight.color)
	GymWorld.placeBarbell(station.barbell, station.restCFrame)

	local session = {
		station = station,
		zone = newZone(),
		startTime = now(),
		speed = Util.needleSpeed(data.tier),
		lastRep = 0,
		combo = 0,
	}
	sessions[player] = session
	StartTraining:FireClient(player, {
		startTime = session.startTime,
		speed = session.speed,
		zone = session.zone,
		zoneWidth = Config.Rep.zoneWidth,
	})
end

-- Barbell goes up and back down: everyone nearby sees the rep happen.
local function animateRep(station)
	local barbell = station.barbell
	local lift = Instance.new("CFrameValue")
	lift.Value = station.restCFrame
	local conn = lift.Changed:Connect(function(cf)
		GymWorld.placeBarbell(barbell, cf)
	end)
	local up = TweenService:Create(lift, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Value = station.restCFrame * CFrame.new(0, 2.6, 0.4) })
	up:Play()
	up.Completed:Once(function()
		local down = TweenService:Create(lift, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{ Value = station.restCFrame })
		down:Play()
		down.Completed:Once(function()
			conn:Disconnect()
			lift:Destroy()
		end)
	end)
end

Rep.OnServerEvent:Connect(function(player: Player, tapTime: any)
	local session = sessions[player]
	local data = PlayerData.get(player)
	if not (session and data) then
		return
	end
	local t = now()
	if t - session.lastRep < Config.Rep.cooldown then
		return
	end
	-- trust the client's tap time only if it's believable (network delay window)
	if type(tapTime) ~= "number" or tapTime ~= tapTime or math.abs(t - tapTime) > Config.Rep.tapTolerance then
		tapTime = t
	end
	session.lastRep = t

	local needle = Util.needle(tapTime - session.startTime, session.speed)
	local perfect = math.abs(needle - session.zone) <= Config.Rep.zoneWidth / 2
	session.combo = if perfect then session.combo + 1 else 0

	local comboBonus = math.min(Config.Rep.comboMax, math.max(0, session.combo - 1) * Config.Rep.comboStep)
	local gain = Config.Weights[data.tier].mult * (if perfect then Config.Rep.perfectMult else 1) * (1 + comboBonus)
	gain = math.max(1, math.floor(gain + 0.5))

	local _, oldRank = Util.rankFor(data.strength)
	data.strength += gain
	data.cash += gain
	local _, newRankTable = Util.rankFor(data.strength)

	session.zone = newZone()
	RepResult:FireClient(player, {
		gain = gain,
		perfect = perfect,
		combo = session.combo,
		zone = session.zone,
	})

	local station = session.station
	animateRep(station)
	station.sound.PlaybackSpeed = 0.9 + math.random() * 0.2
	station.sound:Play()
	if perfect then
		station.perfectSound:Play()
		station.sparkles:Emit(14)
	end

	if newRankTable ~= oldRank then
		Announce:FireAllClients(player.DisplayName, newRankTable.name, newRankTable.color, player.UserId)
	end
	refreshVisuals(player)
	pushStats(player)
end)

StopTraining.OnServerEvent:Connect(stopTraining)
RequestStats.OnServerEvent:Connect(pushStats)

BuyWeight.OnServerEvent:Connect(function(player: Player)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	local nextTier = data.tier + 1
	local weight = Config.Weights[nextTier]
	if not weight or data.cash < weight.cost then
		return
	end
	data.cash -= weight.cost
	data.tier = nextTier
	local session = sessions[player]
	if session then
		-- heavier plates show up right away, and the timing gets a bit faster
		GymWorld.setPlates(session.station.barbell, weight.plate, weight.color)
		session.speed = Util.needleSpeed(nextTier)
		session.startTime = now()
		StartTraining:FireClient(player, {
			startTime = session.startTime,
			speed = session.speed,
			zone = session.zone,
			zoneWidth = Config.Rep.zoneWidth,
		})
	end
	refreshVisuals(player)
	pushStats(player)
end)

for _, station in ipairs(stations) do
	station.prompt.Triggered:Connect(function(player)
		startTraining(player, station)
	end)
end

---------------------------------------------------------------------------
-- Player lifecycle
---------------------------------------------------------------------------
local function onCharacter(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	character:WaitForChild("Head")
	refreshVisuals(player)
	humanoid.Died:Connect(function()
		stopTraining(player)
	end)
end

local function onPlayerAdded(player: Player)
	PlayerData.load(player)
	setupLeaderstats(player)
	player.CharacterAdded:Connect(function(character)
		onCharacter(player, character)
	end)
	if player.Character then
		task.spawn(onCharacter, player, player.Character)
	end
	pushStats(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	stopTraining(player)
	PlayerData.release(player)
end)

game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		PlayerData.save(player)
	end
end)

-- autosave every 2 minutes
task.spawn(function()
	while true do
		task.wait(120)
		for _, player in ipairs(Players:GetPlayers()) do
			PlayerData.save(player)
		end
	end
end)
