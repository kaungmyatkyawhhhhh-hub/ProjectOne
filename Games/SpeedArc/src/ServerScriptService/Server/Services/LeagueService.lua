-- LeagueService: ranks inside a league (GDD 9.1) and Go Pro (GDD 9.2).
-- Rank up = a moment on the client + a small coin reward. Go Pro = SPEED and rank reset, everything
-- else kept; next league, x8 training (Boosts), a free coach roll and the league's title.
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Areas = require(Shared.Config.Areas)
local Ranks = require(Shared.Config.Ranks)
local Formulas = require(Shared.Util.Formulas)
local Boosts = require(Shared.Util.Boosts)
local Net = require(Shared.Util.Net)
local PlayerData = require(script.Parent.PlayerData)
local LockerService = require(script.Parent.LockerService)
local RaceService = require(script.Parent.RaceService)

local LeagueService = {}
local Moment = Net.get("Moment")

local function areaForLeague(league)
	for _, id in Areas.Order do
		if Areas[id].League == league then
			return Areas[id]
		end
	end
	return nil
end
LeagueService.areaForLeague = areaForLeague

-- Go Pro (28 Oct pivot): smash your league's last wall. A league whose area has no wall course yet
-- keeps the old rule (Champion rank + race wins).
local function ready(data)
	if data.League >= Areas.MaxLeague then
		return false
	end
	if Formulas.hasCourse(data.League) then
		return Formulas.wallsIn(data, data.League) >= Formulas.wallCount()
	end
	local need = Areas.GoPro.WinsNeeded[data.League] or 99
	return data.Rank >= #Ranks.Names and (data.LeagueWins or 0) >= need
end

function LeagueService.refresh(player)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	player:SetAttribute("Rank", data.Rank)
	player:SetAttribute("RankName", Ranks.Names[data.Rank])
	player:SetAttribute("League", data.League)
	player:SetAttribute("LeagueWins", data.LeagueWins or 0)
	player:SetAttribute("WinsNeeded", Areas.GoPro.WinsNeeded[data.League] or 0)
	player:SetAttribute("GoProReady", ready(data))
	player:SetAttribute("MaxLeague", Areas.MaxLeague)
	-- the tag over the head (title, rank, medals) is drawn by SocialService
end

local function checkRank(player)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	local idx = Boosts.rankIndex(data.League, data.Speed)
	data.BestRank = data.BestRank or {}
	local key = tostring(data.League)
	if idx > (data.BestRank[key] or 1) then
		data.BestRank[key] = idx
	end
	if idx > data.Rank then
		local wasReady = ready(data)
		for r = data.Rank + 1, idx do
			local coins = Formulas.minutesOfCoins(Areas.RankRewardMinutes[r] or 0, data.League)
			PlayerData.set(player, "Coins", data.Coins + coins)
			Moment:FireClient(player, "RankUp", { Rank = Ranks.Names[r], Index = r, Coins = coins, League = data.League })
		end
		data.Rank = idx
		LeagueService.refresh(player)
		if not wasReady and ready(data) then
			Moment:FireClient(player, "GoProReady", { League = data.League })
		end
		LockerService.push(player) -- shoe unlocks may change
	end
end

local function goPro(player)
	local data = PlayerData.get(player)
	if not data or not ready(data) then
		return false, "notready"
	end
	if RaceService.inRace(player) then
		return false, "race"
	end
	local from = data.League
	local to = from + 1
	local firstTime = not (data.SeenGoPro and data.SeenGoPro[tostring(to)])
	data.SeenGoPro = data.SeenGoPro or {}
	data.SeenGoPro[tostring(to)] = true
	data.League = to
	data.BestLeague = math.max(data.BestLeague or 1, to)
	data.Rank = 1
	data.LeagueWins = 0
	data.Stats.GoPros = (data.Stats.GoPros or 0) + 1
	data.FreeRolls = (data.FreeRolls or 0) + Areas.GoPro.FreeRolls
	data.Titles = data.Titles or {}
	local title = Areas.GoPro.Titles[to]
	if title then
		data.Titles[title] = true
		data.Title = title -- worn right away (the tag updates when League changes)
		player:SetAttribute("Title", title)
	end
	PlayerData.set(player, "Speed", 0)
	PlayerData.set(player, "League", to)
	LeagueService.refresh(player)
	LockerService.push(player)
	local area = areaForLeague(to)
	return true, { From = from, To = to, Area = area and area.Id, AreaName = area and area.Name, Title = title, FirstTime = firstTime }
end

-- a wall was smashed for the first time: refresh, and the GO PRO moment when the last one fell
function LeagueService.wallsChanged(player, wasReady)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	LeagueService.refresh(player)
	if not wasReady and ready(data) then
		Moment:FireClient(player, "GoProReady", { League = data.League })
	end
end
LeagueService.ready = ready

function LeagueService.start()
	Net.on("GoPro", goPro)
	PlayerData.Changed.Event:Connect(function(player, key)
		if key == "Speed" then
			checkRank(player)
		end
	end)
	PlayerData.Loaded.Event:Connect(function(player)
		local data = PlayerData.get(player)
		data.Rank = math.max(data.Rank or 1, Boosts.rankIndex(data.League, data.Speed))
		LeagueService.refresh(player)
	end)
	RaceService.Won.Event:Connect(function(player)
		local data = PlayerData.get(player)
		if data then
			local was = player:GetAttribute("GoProReady")
			LeagueService.refresh(player)
			if not was and ready(data) then
				Moment:FireClient(player, "GoProReady", { League = data.League })
			end
		end
	end)
	local function onPlayer(player)
		player.CharacterAdded:Connect(function(char)
			char:WaitForChild("Head", 10)
			if player.Parent then
				LeagueService.refresh(player)
			end
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, p in Players:GetPlayers() do
		onPlayer(p)
	end
end

return LeagueService
