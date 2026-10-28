-- SocialService (M4, GDD 14 + 18): titles (earned, worn over the head with rank + medal count),
-- profiles, Friend Boost, the invite reward and RACE THEM (a private 1v1 sprint).
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Retention = require(Shared.Config.Retention)
local Ranks = require(Shared.Config.Ranks)
local Coaches = require(Shared.Config.Coaches)
local Trails = require(Shared.Config.Trails)
local Net = require(Shared.Util.Net)
local PlayerData = require(script.Parent.PlayerData)
local SessionBoosts = require(script.Parent.SessionBoosts)
local RaceService = require(script.Parent.RaceService)
local TrainingService = require(script.Parent.TrainingService)

local SocialService = {}
local Event = Net.get("Social")
local Toast = Net.get("Toast")
local S = Retention.Social
local TT = Retention.Titles
local MONTSERRAT = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy, Enum.FontStyle.Italic)

local friendCache = {} -- [a.UserId .. ":" .. b.UserId] = bool
local requests = {} -- [target] = { from = player, at = clock }
local sessionStart = {}

----------------------------------------------------------------------------
-- titles + the tag over the head
----------------------------------------------------------------------------
local function medalCount(data)
	return data.Medals.Gold + data.Medals.Silver + data.Medals.Bronze
end

function SocialService.refreshTag(player)
	local data = PlayerData.get(player)
	local head = player.Character and player.Character:FindFirstChild("Head")
	if not data or not head then
		return
	end
	local old = head:FindFirstChild("RankTag")
	if old then
		old:Destroy() -- the M3 tag, replaced by this one
	end
	local tag = head:FindFirstChild("Overhead")
	if not tag then
		tag = Instance.new("BillboardGui")
		tag.Name = "Overhead"
		tag.Size = UDim2.fromOffset(170, 40)
		tag.StudsOffset = Vector3.new(0, 3.3, 0)
		tag.MaxDistance = 60
		tag.ResetOnSpawn = false
		local function label(name, y, h)
			local l = Instance.new("TextLabel")
			l.Name = name
			l.BackgroundTransparency = 1
			l.Position = UDim2.fromScale(0, y)
			l.Size = UDim2.fromScale(1, h)
			l.TextScaled = true
			l.FontFace = MONTSERRAT
			local st = Instance.new("UIStroke")
			st.Thickness = 2
			st.Color = Color3.fromHex("#0B0D12")
			st.Parent = l
			l.Parent = tag
			return l
		end
		label("Title", 0, 0.45)
		label("Rank", 0.48, 0.52)
		tag.Parent = head
	end
	local title = data.Title ~= "" and data.Title or nil
	tag.Title.Text = title or ""
	tag.Title.TextColor3 = Color3.fromHex("#FFC83D")
	tag.Title.Visible = title ~= nil
	local name = Ranks.Names[data.Rank] or "Bronze"
	local medals = medalCount(data)
	tag.Rank.Text = ("%s - L%d%s"):format(string.upper(name), data.League, if medals > 0 then ("   %d MEDAL%s"):format(medals, if medals == 1 then "" else "S") else "")
	tag.Rank.TextColor3 = Ranks.Colors[name]
end

function SocialService.award(player, title)
	local data = PlayerData.get(player)
	if not data or data.Titles[title] then
		return
	end
	data.Titles[title] = true
	data.Title = title -- wear the newest one (it can be changed in the profile)
	player:SetAttribute("Title", title)
	Toast:FireClient(player, "New title: " .. title, "Gold")
	SocialService.refreshTag(player)
end

local function checkTitles(player)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	if data.Stats.Races >= 1 then
		SocialService.award(player, "FIRST RACE")
	end
	for n, title in TT.Wins do
		if data.Stats.Wins >= n then
			SocialService.award(player, title)
		end
	end
	for league, title in TT.Champion do
		if (data.BestRank[tostring(league)] or 1) >= #Ranks.Names then
			SocialService.award(player, title)
		end
	end
	if (data.Stats.PBs or 0) >= TT.PBs then
		SocialService.award(player, "PB HUNTER")
	end
	-- Go Pro titles are given by LeagueService (data.Titles); wear them too when new
	for title in data.Titles do
		if data.Title == "" then
			data.Title = title
		end
	end
end

----------------------------------------------------------------------------
-- profile
----------------------------------------------------------------------------
local function profileOf(target)
	local data = PlayerData.get(target)
	if not data then
		return nil
	end
	local coaches = {}
	local byUid = {}
	for _, e in data.Coaches do
		byUid[e.Uid] = e
	end
	for _, uid in data.EquippedCoaches do
		local e = byUid[uid]
		if e then
			for _, c in Coaches.List do
				if c.Id == e.Id then
					table.insert(coaches, { Name = c.Name, Rarity = c.Rarity, Stage = Coaches.Stages[e.Stage or 1] })
				end
			end
		end
	end
	local trail = data.Trail
	for _, t in Trails.List do
		if t.Id == data.Trail then
			trail = t.Name
		end
	end
	local titles = {}
	for _, t in TT.Order do
		if data.Titles[t] then
			table.insert(titles, t)
		end
	end
	return {
		UserId = target.UserId,
		Name = target.DisplayName,
		User = target.Name,
		Title = data.Title,
		Titles = titles,
		League = data.League,
		Rank = Ranks.Names[data.Rank],
		Speed = data.Speed,
		TopSpeed = data.TopSpeed,
		BestTimes = data.BestTimes,
		Medals = data.Medals,
		Wins = data.Stats.Wins,
		Races = data.Stats.Races,
		Coaches = coaches,
		Trail = trail,
		PlayMinutes = math.floor((data.Stats.PlaySeconds + (os.clock() - (sessionStart[target] or os.clock()))) / 60),
	}
end

----------------------------------------------------------------------------
-- Friend Boost + invites
----------------------------------------------------------------------------
local function areFriends(a, b)
	local key = math.min(a.UserId, b.UserId) .. ":" .. math.max(a.UserId, b.UserId)
	if friendCache[key] == nil then
		local ok, res = pcall(function()
			return a:IsFriendsWith(b.UserId)
		end)
		friendCache[key] = ok and res == true
	end
	return friendCache[key]
end

local function updateFriendBoost(player)
	local n = 0
	for _, other in Players:GetPlayers() do
		if other ~= player and areFriends(player, other) then
			n += 1
		end
	end
	SessionBoosts.setFriend(player, math.min(S.FriendBoostMax, n * S.FriendBoostEach))
end

local function onJoinedFriends(player)
	for _, other in Players:GetPlayers() do
		if other ~= player and areFriends(player, other) then
			updateFriendBoost(other)
			Event:FireClient(other, "friend", { Name = player.DisplayName, Boost = SessionBoosts.friend(other) })
			Event:FireClient(player, "friend", { Name = other.DisplayName, Boost = nil })
		end
	end
	updateFriendBoost(player)
	if SessionBoosts.friend(player) > 0 then
		Event:FireClient(player, "friendTotal", { Boost = SessionBoosts.friend(player) })
	end
	-- invited by someone in this server? they get +10% for 30 min
	local ok, join = pcall(function()
		return player:GetJoinData()
	end)
	local launch = ok and join and join.LaunchData
	local inviterId = tonumber(launch and string.match(launch, "^invite:(%d+)$"))
	local inviter = inviterId and Players:GetPlayerByUserId(inviterId)
	if inviter and inviter ~= player then
		local d = PlayerData.get(inviter)
		if d then
			d.Boost.Invite = S.InviteBoostSeconds
			Toast:FireClient(inviter, ("%s joined from your invite! +%d%% training for %d min"):format(player.DisplayName, S.InviteBoost * 100, S.InviteBoostSeconds // 60), "Gold")
		end
	end
end

----------------------------------------------------------------------------
-- RACE THEM
----------------------------------------------------------------------------
local function free(p)
	return p.Parent and PlayerData.get(p) and not RaceService.inRace(p) and p.Character ~= nil
end

local function ask(player, targetId)
	local target = Players:GetPlayerByUserId(tonumber(targetId) or 0)
	if not target or target == player then
		return false, "gone"
	end
	if not free(player) or not free(target) then
		return false, "busy"
	end
	if (player:GetAttribute("Area") or "Hub") ~= (target:GetAttribute("Area") or "Hub") then
		return false, "area"
	end
	local r = requests[target]
	if r and os.clock() - r.at < S.ChallengeAskSeconds then
		return false, "pending"
	end
	requests[target] = { from = player, at = os.clock() }
	Event:FireClient(target, "raceAsk", { FromId = player.UserId, Name = player.DisplayName, Seconds = S.ChallengeAskSeconds })
	return true
end

local function answer(target, fromId, yes)
	local r = requests[target]
	requests[target] = nil
	if not r or r.from.UserId ~= fromId or os.clock() - r.at > S.ChallengeAskSeconds + 2 then
		return false, "expired"
	end
	local from = r.from
	if not yes then
		Toast:FireClient(from, target.DisplayName .. " can't race right now", "Denied")
		return true
	end
	if not free(from) or not free(target) or (from:GetAttribute("Area") or "Hub") ~= (target:GetAttribute("Area") or "Hub") then
		return false, "busy"
	end
	TrainingService.leave(from)
	TrainingService.leave(target)
	local ok = RaceService.private({ from, target }, { kind = "challenge", raceType = "Sprint", npcs = 0 })
	return ok
end

----------------------------------------------------------------------------
function SocialService.start()
	Net.on("Profile", function(player, userId)
		local target = Players:GetPlayerByUserId(tonumber(userId) or 0)
		if not target then
			return false, "gone"
		end
		return true, profileOf(target)
	end)
	Net.on("SetTitle", function(player, title)
		local data = PlayerData.get(player)
		if not data or (title ~= "" and not data.Titles[title]) then
			return false
		end
		data.Title = title
		player:SetAttribute("Title", title)
		SocialService.refreshTag(player)
		return true
	end)
	-- one-time prompts (the favourite prompt after the first Go Pro): returns true the first time only
	Net.on("Prompted", function(player, which)
		local data = PlayerData.get(player)
		if not data or type(which) ~= "string" or data.Prompted[which] then
			return true, false
		end
		data.Prompted[which] = true
		return true, true
	end)
	Net.on("RaceThem", ask)
	Net.on("RaceAnswer", answer)

	PlayerData.Loaded.Event:Connect(function(player)
		sessionStart[player] = os.clock()
		local data = PlayerData.get(player)
		player:SetAttribute("Title", data.Title)
		checkTitles(player)
		SocialService.refreshTag(player)
		task.spawn(onJoinedFriends, player)
	end)
	PlayerData.Changed.Event:Connect(function(player, key)
		if key == "League" or key == "Speed" then
			local data = PlayerData.get(player)
			local l = tostring(data.League)
			if data.Speed > (data.TopSpeed[l] or 0) then
				data.TopSpeed[l] = data.Speed
			end
		end
	end)
	RaceService.Won.Event:Connect(function(player)
		checkTitles(player)
		SocialService.refreshTag(player)
	end)
	-- rank / league changes come through LeagueService attributes
	local function onPlayer(player)
		player.CharacterAdded:Connect(function(char)
			char:WaitForChild("Head", 10)
			if player.Parent then
				SocialService.refreshTag(player)
			end
		end)
		player:GetAttributeChangedSignal("RankName"):Connect(function()
			checkTitles(player)
			SocialService.refreshTag(player)
		end)
		player:GetAttributeChangedSignal("League"):Connect(function()
			checkTitles(player)
			SocialService.refreshTag(player)
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, p in Players:GetPlayers() do
		onPlayer(p)
	end
	Players.PlayerRemoving:Connect(function(player)
		requests[player] = nil
		sessionStart[player] = nil
		SessionBoosts.clear(player)
		for _, other in Players:GetPlayers() do
			if other ~= player and areFriends(player, other) then
				task.defer(updateFriendBoost, other)
			end
		end
	end)
end

return SocialService
