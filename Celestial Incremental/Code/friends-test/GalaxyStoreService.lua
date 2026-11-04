-- GalaxyStoreService (Galaxy Incremental, overnight part 4, 3 Nov): the x2 STARDUST pass and the ALPHA badge, server side.
--  * x2 STARDUST (GameConfig.Passes.X2Stardust): ownership checked on join (UserOwnsGamePassAsync, retried) and when a
--    purchase finishes; the session's passX2 makes GalaxyEconService's income x2 (the formula applies it once). The
--    player attribute Pass_X2Stardust tells the store window.
--  * the store asks for the prompt (RemoteEvent Galaxy.StoreEvent "Prompt", passKey): the server prompts and logs
--    "PassPromptShown"; a finished purchase logs "PassBought" (analytics custom events, the pass in custom field 1)
--  * ALPHA PLAYER: while GameConfig.AlphaActive, a player's first join saves d.alphaPlayer = true (for the launch title) and
--    awards the badge (once it has an id; d.alphaBadge = true once Roblox confirms, so it's retried until then)
-- Studio test switches: Workspace attribute TestOwnX2 = true -> every player owns x2 Stardust; TestNoPass = true -> nobody
-- does (the pace test). Studio only.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local BadgeService = game:GetService("BadgeService")
local AnalyticsService = game:GetService("AnalyticsService")
local RunService = game:GetService("RunService")

local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local Config = require(Galaxy:WaitForChild("GameConfig"))
local Shared = require(ServerStorage:WaitForChild("GalaxyEconShared"))

local event = Galaxy:FindFirstChild("StoreEvent") or Instance.new("RemoteEvent")
event.Name = "StoreEvent"
event.Parent = Galaxy

local IS_STUDIO = RunService:IsStudio()
local function log(player: Player, name: string, field: string)
	pcall(function() AnalyticsService:LogCustomEvent(player, name, 1, { [Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = field }) end)
end
local function sessionOf(player: Player)
	local t = os.clock()
	while player.Parent and not Shared.sessions[player] and os.clock() - t < 60 do task.wait(0.5) end
	return Shared.sessions[player]
end

------------------------------------------------------------------------ x2 STARDUST
local X2 = Config.Passes.X2Stardust
local function grantX2(player: Player)
	local s = Shared.sessions[player]
	player:SetAttribute("Pass_X2Stardust", true)
	if s and not s.passX2 then
		s.passX2 = true
		Shared.publish(player, s)
	end
end
local function checkX2(player: Player)
	if IS_STUDIO and workspace:GetAttribute("TestOwnX2") == true then grantX2(player) return end
	-- (Studio: TestNoPass = true -> nobody owns it, for the pace test; the owner's account owns the real pass)
	if IS_STUDIO and workspace:GetAttribute("TestNoPass") == true then return end
	if X2.id == 0 then return end
	for _ = 1, 3 do
		local ok, owns = pcall(function() return MarketplaceService:UserOwnsGamePassAsync(player.UserId, X2.id) end)
		if ok then
			if owns then grantX2(player) end
			return
		end
		task.wait(2)
	end
end
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, passId: number, bought: boolean)
	if passId ~= X2.id or X2.id == 0 or not bought then return end
	grantX2(player)
	log(player, "PassBought", "X2Stardust")
end)

local lastPrompt = {}
event.OnServerEvent:Connect(function(player: Player, kind, key)
	if kind ~= "Prompt" or key ~= "X2Stardust" then return end
	if os.clock() - (lastPrompt[player] or 0) < 2 then return end
	lastPrompt[player] = os.clock()
	if player:GetAttribute("Pass_X2Stardust") == true or X2.id == 0 then return end
	log(player, "PassPromptShown", "X2Stardust")
	pcall(function() MarketplaceService:PromptGamePassPurchase(player, X2.id) end)
end)

------------------------------------------------------------------------ ALPHA PLAYER
local function alpha(player: Player, s)
	if not Config.AlphaActive then return end
	local d = s.d
	if not d.alphaPlayer then
		d.alphaPlayer = true
		Shared.publish(player, s)
		task.spawn(Shared.save, player, false)
	end
	player:SetAttribute("AlphaPlayer", true)
	if Config.Badges.AlphaPlayer ~= 0 and not d.alphaBadge then
		local ok, has = pcall(function() return BadgeService:UserHasBadgeAsync(player.UserId, Config.Badges.AlphaPlayer) end)
		if ok and not has then ok = pcall(function() BadgeService:AwardBadge(player.UserId, Config.Badges.AlphaPlayer) end) end
		if ok then d.alphaBadge = true end
	end
end

------------------------------------------------------------------------ players
local function onPlayer(player: Player)
	local s = sessionOf(player)
	if not s or not player.Parent then return end
	task.spawn(checkX2, player)
	alpha(player, s)
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(onPlayer, p) end
Players.PlayerRemoving:Connect(function(p) lastPrompt[p] = nil end)
