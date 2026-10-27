-- Analytics (M4, GDD 26): the onboarding funnel, each step once per player (saved), always in
-- order: a step reached early waits ("pending") until the one before it fires. Plus race joins vs skips.
local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Retention = require(Shared.Config.Retention)
local Net = require(Shared.Util.Net)
local PlayerData = require(script.Parent.PlayerData)
local RaceService = require(script.Parent.RaceService)

local Analytics = {}
local STEPS = Retention.Funnel

local function log(player, index, name)
	pcall(function()
		AnalyticsService:LogOnboardingFunnelStepEvent(player, index, name)
	end)
end

function Analytics.step(player, name)
	local data = PlayerData.get(player)
	if not data or data.Funnel[name] == true then
		return
	end
	data.Funnel[name] = "pending"
	-- fire every step, in order, up to the first one that hasn't happened yet
	for i, step in STEPS do
		local v = data.Funnel[step]
		if v == true then
			continue
		elseif v == "pending" then
			data.Funnel[step] = true
			log(player, i, step)
		else
			break
		end
	end
end

function Analytics.event(player, name, value)
	pcall(function()
		AnalyticsService:LogCustomEvent(player, name, value or 1)
	end)
end

-- the steps the server can see in the save, checked every few seconds
local function check(player, data)
	local owned = 0
	for _ in data.OwnedShoes do
		owned += 1
	end
	if owned > 1 then
		Analytics.step(player, "first_shoes")
	end
	if (data.CoachRolls or 0) > 0 then
		Analytics.step(player, "first_coach_roll")
	end
	local l1 = data.BestRank and data.BestRank["1"] or 1
	if l1 >= 2 or (data.BestLeague or 1) > 1 then
		Analytics.step(player, "silver")
	end
	if l1 >= 3 or (data.BestLeague or 1) > 1 then
		Analytics.step(player, "gold")
	end
	if (data.BestLeague or 1) >= 2 then
		Analytics.step(player, "go_pro_1")
	end
	if (data.BestLeague or 1) >= 3 then
		Analytics.step(player, "go_pro_2")
	end
end

function Analytics.start()
	PlayerData.Loaded.Event:Connect(function(player)
		local data = PlayerData.get(player)
		Analytics.step(player, "loaded")
		if data.FirstJoin > 0 and math.floor(os.time() / 86400) > math.floor(data.FirstJoin / 86400) then
			Analytics.step(player, "day2_return")
		end
	end)
	Net.get("Funnel").OnServerEvent:Connect(function(player, name)
		if name == "menu_play" then
			Analytics.step(player, "menu_play")
		end
	end)
	RaceService.Joined.Event:Connect(function(player)
		Analytics.step(player, "first_race_joined")
		Analytics.event(player, "RaceJoined")
	end)
	RaceService.Skipped.Event:Connect(function(player)
		Analytics.event(player, "RaceSkipped")
	end)
	RaceService.Won.Event:Connect(function(player, _, _, info)
		if info and info.kind == "tutorial" then
			Analytics.step(player, "first_race_joined") -- the tutorial race is the first race
		end
		Analytics.step(player, "first_race_finished")
	end)
	task.spawn(function()
		while true do
			task.wait(3)
			for _, p in Players:GetPlayers() do
				local data = PlayerData.get(p)
				if data then
					pcall(check, p, data)
				end
			end
		end
	end)
end

return Analytics
