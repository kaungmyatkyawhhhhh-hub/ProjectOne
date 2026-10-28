-- WallService (28 Oct pivot): the wall course. Each area's course (Config/Course.Areas) has a wall at
-- the end of every stage; wall k needs Formulas.wallNeed(league, k) SPEED. Your own client lets you
-- through a wall you're fast enough for (WallController); the server checks where you are and pays:
-- passing wall k after wall k-1 in this run = SMASH (coins, first time x3, the wall bonus grows).
-- Past a wall without the SPEED (or skipping one) = put back in front of it. Going back behind the
-- start line (or respawning) starts a new run: every wall stands again.
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Areas = require(Shared.Config.Areas)
local Course = require(Shared.Config.Course)
local Formulas = require(Shared.Util.Formulas)
local Boosts = require(Shared.Util.Boosts)
local Net = require(Shared.Util.Net)
local Format = require(Shared.Util.Format)
local PlayerData = require(script.Parent.PlayerData)
local LeagueService = require(script.Parent.LeagueService)
local Analytics = require(script.Parent.Analytics)

local WallService = {}
WallService.Smashed = Instance.new("BindableEvent") -- (player, league, k, firstTime)

local TICK = 0.15
local runs = {} -- [player] = stage (walls passed in this run)
local WallEvent = Net.get("WallEvent")

local function courseOf(player)
	local id = player:GetAttribute("Area") or "Hub"
	local c = Course.Areas[id]
	return c, Areas[id] and Areas[id].League or 1
end

local function setStage(player, n)
	runs[player] = n
	player:SetAttribute("RunStage", n)
end

-- put the player back on the course, `along` studs from the start, facing down the course
local function putBack(player, root, c, along)
	local pos = c.Start + c.Dir * along + Vector3.new(0, 3.5, 0)
	root.AssemblyLinearVelocity = Vector3.zero
	root.CFrame = CFrame.lookAt(pos, pos + c.Dir)
end

local function smash(player, data, league, k)
	local own = league == data.League
	local key = tostring(league)
	data.Walls = data.Walls or {}
	local first = own and k > (data.Walls[key] or 0)
	local minutes = (Course.RewardMinutes[k] or 1) * (if first then Course.FirstSmashMult else 1)
	if not own then
		minutes *= Areas.LowerLeagueRewardMult
	end
	local coins = math.floor(Formulas.minutesOfCoins(minutes, data.League) * Boosts.compute(data).Coins + 0.5)
	data.Stats.Smashes = (data.Stats.Smashes or 0) + 1 -- the "Smash 5 walls" quests
	-- funnel steps (each fires once per player)
	if k == 1 then
		Analytics.step(player, "first_wall")
	elseif k == 5 then
		Analytics.step(player, "wall_5")
	elseif k == Formulas.wallCount() then
		Analytics.step(player, "last_wall")
	end
	PlayerData.set(player, "Coins", data.Coins + coins)
	if first then
		local wasReady = LeagueService.ready(data)
		data.Walls[key] = k
		player:SetAttribute("BestWall", k)
		Analytics.event(player, "WallSmashed_" .. k)
		LeagueService.wallsChanged(player, wasReady)
	end
	WallEvent:FireClient(player, "smash", { Index = k, Coins = coins, First = first, Last = k == Formulas.wallCount() })
	WallService.Smashed:Fire(player, league, k, first)
end

local function check(player)
	local data = PlayerData.get(player)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not data or not root then
		return
	end
	local c, league = courseOf(player)
	if not c then
		return
	end
	local rel = root.Position - c.Start
	local along = rel:Dot(c.Dir)
	local side = (rel - c.Dir * along)
	side = Vector3.new(side.X, 0, side.Z).Magnitude
	if along < 0 or side > Course.Width / 2 + 8 then
		if along < 0 and (runs[player] or 0) > 0 then
			setStage(player, 0) -- back at the start: a new run
		end
		return
	end
	local stage = runs[player] or 0
	local nextK = stage + 1
	if nextK > Formulas.wallCount() then
		-- on the finish stage: back to the start for the next run
		if along > stage * Course.StageLength + 30 then
			Net.get("Toast"):FireClient(player, "COURSE DONE!  Back to the start", "Unlock")
			WallService.toStart(player)
		end
		return
	end
	local wallAt = nextK * Course.StageLength
	if along > wallAt + 1.5 then
		if data.Speed >= Formulas.wallNeed(league, nextK) and along < wallAt + Course.StageLength then
			setStage(player, nextK)
			smash(player, data, league, nextK)
		else
			-- through a wall without the SPEED, or more than one wall at once: back in front of it
			putBack(player, root, c, wallAt - 8)
		end
	end
end

-- teleport to the start of your area's course (tutorial GO TO, BACK TO START)
function WallService.toStart(player)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local c = courseOf(player)
	if not root or not c then
		return false
	end
	setStage(player, 0)
	putBack(player, root, c, -6)
	return true
end

-- the world position of wall k on a course (tutorial marker)
function WallService.wallPosition(areaId, k)
	local c = Course.Areas[areaId]
	return c and c.Start + c.Dir * (k * Course.StageLength) + Vector3.new(0, 4, 0)
end

function WallService.start()
	local function add(player)
		setStage(player, 0)
		player.CharacterAdded:Connect(function()
			setStage(player, 0)
		end)
	end
	Players.PlayerAdded:Connect(add)
	for _, p in Players:GetPlayers() do
		add(p)
	end
	Players.PlayerRemoving:Connect(function(p)
		runs[p] = nil
	end)
	PlayerData.Loaded.Event:Connect(function(player)
		local data = PlayerData.get(player)
		player:SetAttribute("BestWall", Formulas.wallsIn(data, data.League))
	end)
	-- Go Pro changes the league: show that league's best wall
	PlayerData.Changed.Event:Connect(function(player, key)
		if key == "League" then
			local data = PlayerData.get(player)
			if data then
				player:SetAttribute("BestWall", Formulas.wallsIn(data, data.League))
				setStage(player, 0)
			end
		end
	end)
	Net.on("BackToStart", function(player)
		if player:GetAttribute("InRace") then
			return false
		end
		return WallService.toStart(player)
	end)
	-- not enough SPEED: the wall itself shows how close you are (WallController), no toast (prompt 11)
	task.spawn(function()
		while true do
			task.wait(TICK)
			for _, player in Players:GetPlayers() do
				check(player)
			end
		end
	end)
end

return WallService
