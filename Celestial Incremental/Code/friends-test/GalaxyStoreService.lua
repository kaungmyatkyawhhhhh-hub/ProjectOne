-- GalaxyStoreService (Galaxy Incremental, overnight part 4, 3 Nov): the x2 STARDUST pass and the ALPHA badge, server side.
--  * x2 STARDUST (GameConfig.Passes.X2Stardust): ownership checked on join (UserOwnsGamePassAsync, retried) and when a
--    purchase finishes; the session's passX2 makes GalaxyEconService's income x2 (the formula applies it once). The
--    player attribute Pass_X2Stardust tells the store window.
--  * the store asks for the prompt (RemoteEvent Galaxy.StoreEvent "Prompt", passKey): the server prompts and logs
--    "PassPromptShown"; a finished purchase logs "PassBought" (analytics custom events, the pass in custom field 1)
--  * ALPHA PLAYER: while GameConfig.AlphaActive, a player's first join saves d.alphaPlayer = true (for the launch title) and
--    awards the badge (once it has an id; d.alphaBadge = true once Roblox confirms, so it's retried until then)
-- Studio test switches: Workspace attribute TestOwnX2 = true -> every player owns x2 Stardust; TestOwnPasses = true -> every
-- pass; TestNoPass = true -> nobody does (the pace test). Studio only.
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

------------------------------------------------------------------------ GAME PASSES (x2 STARDUST; 7 Nov: + VIP, +1 CORE SLOT, AUTO ROLL)
-- Each pass in GameConfig.Passes: ownership checked on join (UserOwnsGamePassAsync, retried) and when a purchase finishes;
-- the session's s.pass[key] = true (GalaxyEconService reads it; x2 also keeps s.passX2), the player attribute Pass_<key>
-- tells the windows. id 0 = not created yet: never owned, never prompted (the store hides it).
-- Studio: TestOwnX2 = true -> x2 owned; TestOwnPasses = true -> every pass owned; TestNoPass = true -> none.
local passKeyById = {}
for key, p in pairs(Config.Passes) do if p.id ~= 0 then passKeyById[p.id] = key end end
local function grantPass(player: Player, key: string)
	local s = Shared.sessions[player]
	player:SetAttribute("Pass_" .. key, true)
	if s then
		s.pass = s.pass or {}
		if not s.pass[key] then
			s.pass[key] = true
			if key == "X2Stardust" then s.passX2 = true end
			if key == "AutoRoll" then s.d.auto.Roll = nil end -- (on when you get it)
			Shared.publish(player, s)
		end
	end
end
local function checkPasses(player: Player)
	if IS_STUDIO and workspace:GetAttribute("TestNoPass") == true then return end
	if IS_STUDIO and workspace:GetAttribute("TestOwnX2") == true then grantPass(player, "X2Stardust") end
	-- (Studio: TestOwnPass = "<key>" -> just that pass, as if bought now)
	local one = IS_STUDIO and workspace:GetAttribute("TestOwnPass")
	if type(one) == "string" and Config.Passes[one] then grantPass(player, one) end
	if IS_STUDIO and workspace:GetAttribute("TestOwnPasses") == true then
		for key in pairs(Config.Passes) do grantPass(player, key) end
		return
	end
	for key, p in pairs(Config.Passes) do
		if p.id ~= 0 then
			task.spawn(function()
				for _ = 1, 3 do
					local ok, owns = pcall(function() return MarketplaceService:UserOwnsGamePassAsync(player.UserId, p.id) end)
					if ok then
						if owns then grantPass(player, key) end
						return
					end
					task.wait(2)
				end
			end)
		end
	end
end
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, passId: number, bought: boolean)
	local key = passKeyById[passId]
	if not key or not bought then return end
	grantPass(player, key)
	log(player, "PassBought", key)
	-- (#91: save right after a purchase)
	task.spawn(Shared.save, player, false)
end)

local lastPrompt = {}
event.OnServerEvent:Connect(function(player: Player, kind, key)
	if kind ~= "Prompt" or type(key) ~= "string" then return end
	local p = Config.Passes[key]
	if not p or p.id == 0 then return end
	if os.clock() - (lastPrompt[player] or 0) < 2 then return end
	lastPrompt[player] = os.clock()
	if player:GetAttribute("Pass_" .. key) == true then return end
	log(player, "PassPromptShown", key)
	pcall(function() MarketplaceService:PromptGamePassPurchase(player, p.id) end)
end)

------------------------------------------------------------------------ DEVELOPER PRODUCTS (Phase 2, #454)
-- ProcessReceipt is the ONLY place a product is granted: the player's session must be loaded, a PurchaseId already in the
-- save is answered "granted" without granting again, the grant + the receipt are SAVED before Roblox hears "granted" (a
-- failed save = NotProcessedYet: Roblox asks again later; the receipt in memory stops a second grant meanwhile).
local productById = {}
for key, p in pairs(Config.Products or {}) do if p.id ~= 0 then productById[p.id] = key end end
local function processReceipt(info, keyOverride: string?)
	local player = Players:GetPlayerByUserId(info.PlayerId)
	local key = keyOverride or productById[info.ProductId]
	if not player or not key or not Shared.products or not Shared.products[key] then return Enum.ProductPurchaseDecision.NotProcessedYet end
	local s = Shared.sessions[player]
	if not s or s.readOnly then return Enum.ProductPurchaseDecision.NotProcessedYet end
	local d = s.d
	local id = tostring(info.PurchaseId)
	if d.receipts[id] then return Enum.ProductPurchaseDecision.PurchaseGranted end
	Shared.products[key](player, s)
	d.receipts[id] = os.time()
	-- (keep the 50 newest receipts)
	local list = {}
	for k, t in pairs(d.receipts) do table.insert(list, { k = k, t = t }) end
	if #list > 50 then
		table.sort(list, function(a, b) return a.t > b.t end)
		for i = 51, #list do d.receipts[list[i].k] = nil end
	end
	log(player, "ProductBought", key)
	if s.noSave then return Enum.ProductPurchaseDecision.PurchaseGranted end -- (Studio without saving)
	if not Shared.save(player, false) then return Enum.ProductPurchaseDecision.NotProcessedYet end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end
MarketplaceService.ProcessReceipt = processReceipt
-- the prompt (the server asks Roblox; the client only says which product it wants)
Shared.promptProduct = function(player: Player, key: string): boolean
	local p = Config.Products and Config.Products[key]
	if not p or p.id == 0 then return false end
	log(player, "ProductPromptShown", key)
	pcall(function() MarketplaceService:PromptProductPurchase(player, p.id) end)
	return true
end
-- (Studio: TestReceipt = "<product key>" runs the same grant with one fake PurchaseId TWICE: the second must not grant)
if IS_STUDIO then
	workspace:GetAttributeChangedSignal("TestReceipt"):Connect(function()
		local key = workspace:GetAttribute("TestReceipt")
		if type(key) ~= "string" or key == "" then return end
		for _, player in ipairs(Players:GetPlayers()) do
			local info = { PlayerId = player.UserId, ProductId = 0, PurchaseId = "test-" .. key .. "-" .. math.floor(os.clock()) }
			local a = processReceipt(info, key)
			local b = processReceipt(info, key)
			print("[GalaxyStore] TestReceipt", key, a, b)
		end
	end)
end

-- any badge by its GameConfig key (id 0 = skipped)
Shared.awardBadge = function(player: Player, key: string)
	local id = Config.Badges[key]
	if not id or id == 0 then return end
	pcall(function()
		if not BadgeService:UserHasBadgeAsync(player.UserId, id) then BadgeService:AwardBadge(player.UserId, id) end
	end)
end

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
	task.spawn(checkPasses, player)
	alpha(player, s)
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(onPlayer, p) end
Players.PlayerRemoving:Connect(function(p) lastPrompt[p] = nil end)
