-- StoreService (M5, GDD 20): game passes, developer products and the Starter Pack.
-- One ProcessReceipt on the server: the receipt id is recorded with the grant and the save is written
-- BEFORE Roblox is told PurchaseGranted, so a product is never granted twice and survives a rejoin.
-- Pass ownership comes from Roblox (checked at join) and is cached in data.Passes.
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Store = require(Shared.Config.Store)
local Trails = require(Shared.Config.Trails)
local Formulas = require(Shared.Util.Formulas)
local Net = require(Shared.Util.Net)
local PlayerData = require(script.Parent.PlayerData)
local LockerService = require(script.Parent.LockerService)
local SocialService = require(script.Parent.SocialService)
local Analytics = require(script.Parent.Analytics)

local StoreService = {}
local IS_STUDIO = RunService:IsStudio()
local Toast = Net.get("Toast")
local Event = Net.get("StoreEvent")

local passByKey, passById, productByKey, productById = {}, {}, {}, {}
for _, p in Store.Passes do
	passByKey[p.Key] = p
	if p.Id > 0 then
		passById[p.Id] = p
	end
end
for _, p in Store.Products do
	productByKey[p.Key] = p
	if p.Id > 0 then
		productById[p.Id] = p
	end
end

----------------------------------------------------------------------------
-- passes
----------------------------------------------------------------------------
-- what owning a pass gives right away (the multipliers are in Boosts.compute)
local function applyPass(player, key)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	data.Passes[key] = true
	for _, t in Trails.List do
		if t.Pass == key then
			data.OwnedTrails[t.Id] = true
		end
	end
	player:SetAttribute("Pass_" .. key, true)
	if key == "VIP" then
		player:SetAttribute("VIP", true)
		SocialService.refreshTag(player)
	end
	LockerService.push(player)
end
StoreService.applyPass = applyPass

function StoreService.owns(player, key)
	local data = PlayerData.get(player)
	return data ~= nil and data.Passes[key] == true
end

local function checkPasses(player)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	for _, p in Store.Passes do
		if p.Id > 0 and not data.Passes[p.Key] then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, p.Id)
			end)
			if ok and owns then
				data.Passes[p.Key] = true
			end
		end
	end
	for key in data.Passes do
		applyPass(player, key)
	end
end

----------------------------------------------------------------------------
-- products
----------------------------------------------------------------------------
function StoreService.starterEligible(data)
	if (data.Purchases.StarterPack or 0) > 0 then
		return false
	end
	return os.time() - (data.FirstJoin or os.time()) < Store.StarterWindowHours * 3600
end

-- grant a product into the save; returns a short text of what was given
local function grantProduct(player, data, product)
	local parts = {}
	if product.Minutes then
		local coins = Formulas.minutesOfCoins(product.Minutes, data.League)
		PlayerData.set(player, "Coins", data.Coins + coins)
		table.insert(parts, ("+%d coins"):format(coins))
	end
	if product.SpeedBoost then
		data.Boost.Speed = (data.Boost.Speed or 0) + product.SpeedBoost
		table.insert(parts, ("2x SPEED for %d min"):format(product.SpeedBoost // 60))
	end
	if product.ShoeSkin then
		data.ShoeSkins[product.ShoeSkin] = true
		data.OwnedShoes.CanvasRunners = true -- the skin needs the pair
		table.insert(parts, "gold Canvas Runners")
	end
	if product.Title then
		SocialService.award(player, product.Title)
	end
	data.Purchases[product.Key] = (data.Purchases[product.Key] or 0) + 1
	LockerService.push(player)
	return table.concat(parts, " + ")
end

local function pruneReceipts(data)
	local n = 0
	for _ in data.Receipts do
		n += 1
	end
	if n <= 60 then
		return
	end
	local oldest, oldestT = nil, math.huge
	for id, t in data.Receipts do
		if t < oldestT then
			oldest, oldestT = id, t
		end
	end
	data.Receipts[oldest] = nil
end

-- the one receipt handler (also used by the Studio test switch with a fake receipt)
local function handleReceipt(info)
	local player = Players:GetPlayerByUserId(info.PlayerId)
	local data = player and PlayerData.get(player)
	if not data then
		return Enum.ProductPurchaseDecision.NotProcessedYet -- Roblox asks again next time they join
	end
	local id = tostring(info.PurchaseId)
	if data.Receipts[id] then
		return Enum.ProductPurchaseDecision.PurchaseGranted -- already granted (a retry)
	end
	local product = info.Product or productById[info.ProductId]
	if not product then
		warn("[Store] unknown product", info.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	data.Receipts[id] = os.time()
	pruneReceipts(data)
	local text = grantProduct(player, data, product)
	if not PlayerData.saveNow(player) then
		-- not saved yet: Roblox will retry; the receipt id is in memory so it won't grant twice
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	Toast:FireClient(player, ("%s: %s"):format(product.Name, text), "Gold")
	Event:FireClient(player, "bought", { Key = product.Key, Text = text })
	Analytics.event(player, "OfferBought_" .. product.Key)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end
StoreService.handleReceipt = handleReceipt

----------------------------------------------------------------------------
function StoreService.state(player)
	local data = PlayerData.get(player)
	if not data then
		return nil
	end
	local prices = {}
	return {
		Passes = data.Passes,
		Purchases = data.Purchases,
		StarterEligible = StoreService.starterEligible(data),
		Prices = prices,
	}
end

-- Roblox's real prices (lesson: the price in the game must be the one Roblox asks)
local realPrice = {}
local function fetchPrices()
	for _, p in Store.Passes do
		if p.Id > 0 then
			local ok, info = pcall(function()
				return MarketplaceService:GetProductInfo(p.Id, Enum.InfoType.GamePass)
			end)
			if ok and info and info.PriceInRobux then
				realPrice[p.Key] = info.PriceInRobux
			end
		end
	end
	for _, p in Store.Products do
		if p.Id > 0 then
			local ok, info = pcall(function()
				return MarketplaceService:GetProductInfo(p.Id, Enum.InfoType.Product)
			end)
			if ok and info and info.PriceInRobux then
				realPrice[p.Key] = info.PriceInRobux
			end
		end
	end
end

function StoreService.start()
	MarketplaceService.ProcessReceipt = handleReceipt
	task.spawn(fetchPrices)

	Net.on("StoreState", function(player)
		local st = StoreService.state(player)
		if st then
			st.Prices = realPrice
		end
		return st ~= nil, st
	end)
	Net.on("BuyPass", function(player, key)
		local p = passByKey[key]
		if not p then
			return false, "missing"
		end
		if StoreService.owns(player, key) then
			return false, "owned"
		end
		if p.Needs and not StoreService.owns(player, p.Needs) then
			return false, "needs"
		end
		if p.Id <= 0 then
			return false, "soon"
		end
		Analytics.event(player, "OfferTapped_" .. key)
		MarketplaceService:PromptGamePassPurchase(player, p.Id)
		return true
	end)
	Net.on("BuyProduct", function(player, key)
		local p = productByKey[key]
		local data = PlayerData.get(player)
		if not p or not data then
			return false, "missing"
		end
		if p.Key == "StarterPack" and not StoreService.starterEligible(data) then
			return false, "gone"
		end
		if p.Id <= 0 then
			return false, "soon"
		end
		Analytics.event(player, "OfferTapped_" .. key)
		MarketplaceService:PromptProductPurchase(player, p.Id)
		return true
	end)
	Net.on("OfferShown", function(player, key)
		if type(key) == "string" and (passByKey[key] or productByKey[key]) then
			Analytics.event(player, "OfferShown_" .. key)
		end
		return true
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		local p = passById[passId]
		if purchased and p then
			applyPass(player, p.Key)
			Toast:FireClient(player, p.Name .. " is yours! Thank you!", "Gold")
			Event:FireClient(player, "bought", { Key = p.Key })
			Analytics.event(player, "OfferBought_" .. p.Key)
		end
	end)

	PlayerData.Loaded.Event:Connect(function(player)
		task.spawn(checkPasses, player)
	end)

	-- Studio test switches (test purchases without real Robux):
	--   TestGrantPass = "AutoTrain"            -> as if the pass was bought
	--   TestBuyProduct = "CoinsSmall"          -> a new fake receipt
	--   TestBuyProduct = "CoinsSmall:abc"      -> receipt id "abc" (send twice: must grant once)
	if IS_STUDIO then
		workspace:GetAttributeChangedSignal("TestGrantPass"):Connect(function()
			local key = workspace:GetAttribute("TestGrantPass")
			if type(key) == "string" and passByKey[key] then
				for _, player in Players:GetPlayers() do
					applyPass(player, key)
					Toast:FireClient(player, "(Studio) " .. passByKey[key].Name .. " granted", "Gold")
				end
				workspace:SetAttribute("TestGrantPass", nil)
			end
		end)
		workspace:GetAttributeChangedSignal("TestBuyProduct"):Connect(function()
			local v = workspace:GetAttribute("TestBuyProduct")
			if type(v) ~= "string" or v == "" then
				return
			end
			local key, rid = string.match(v, "^(%w+):?(.*)$")
			local product = productByKey[key]
			if product then
				for _, player in Players:GetPlayers() do
					local data = PlayerData.get(player)
					if key == "StarterPack" and data and not StoreService.starterEligible(data) and rid == "" then
						Toast:FireClient(player, "(Studio) Starter Pack already bought", "Denied")
					else
						local decision = handleReceipt({ PlayerId = player.UserId, ProductId = product.Id, PurchaseId = if rid ~= "" then rid else ("studio-" .. key .. "-" .. os.clock()), Product = product })
						print("[Store] test receipt", key, rid, decision)
					end
				end
			end
			workspace:SetAttribute("TestBuyProduct", nil)
		end)
	end
end

return StoreService
