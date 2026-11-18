--[[
	Store (server)
	Robux: the game passes and the developer products (owner, 18 Nov 2026; Config.Passes,
	Config.Products, the STORE tab in MainMenu).
	  * Passes: owned is checked at join (UserOwnsGamePassAsync) and on a buy mid-session
	    (PromptGamePassPurchaseFinished), cached as player attributes Cash2x / Vip / DoublePay.
	    Roblox Premium is the attribute Premium.
	  * Store.earnMult(player, kind): what driving ("drive"), cut-ups ("cut") and jobs ("job") pay
	    is multiplied by: 2x Cash x2, Premium +10%, VIP +10% on cut-ups. Races and duels never call
	    it (no paid power in competitions). Double Pay is for the jobs system to read.
	  * VIP: a VIP tag over the head (the chat tag is client side: MainMenu), free VIP bays (Parking).
	  * ProcessReceipt: the game's ONLY receipt handler. Idempotent: the PurchaseId is kept in the
	    save (profile.Rewards.Receipts, the last 50) and the grant is saved before it is confirmed;
	    a failed save undoes the grant and Roblox retries. NotProcessedYet while the save isn't loaded.
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local Store = {}

local deps: any = {} -- Rewards, Houses, Cars, notify (set by init: no require loops)

---------------------------------------------------------------------
-- Pass ownership and the pay multipliers
---------------------------------------------------------------------
function Store.earnMult(player: Player, kind: string): number
	local m = 1
	if player:GetAttribute("Cash2x") == true then
		m *= 2
	end
	if player:GetAttribute("Premium") == true then
		m *= Config.PremiumBonus
	end
	if kind == "cut" and player:GetAttribute("Vip") == true then
		m *= Config.VipCutBonus
	end
	return m
end

local function vipTag(player: Player)
	local head = player.Character and player.Character:FindFirstChild("Head")
	if not head then
		return
	end
	local old = head:FindFirstChild("VipTag")
	if player:GetAttribute("Vip") ~= true then
		if old then
			old:Destroy()
		end
		return
	end
	if old then
		return
	end
	-- (above the Luxe card title at 2.9, never on it)
	local bb = Instance.new("BillboardGui")
	bb.Name = "VipTag"
	bb.Size = UDim2.fromScale(2.4, 0.7)
	bb.StudsOffset = Vector3.new(0, 3.9, 0)
	bb.MaxDistance = 140
	bb.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Text = "VIP"
	label.TextColor3 = Color3.fromRGB(255, 214, 110)
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0.3
	label.Parent = bb
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new(Color3.fromRGB(255, 236, 170), Color3.fromRGB(214, 150, 40))
	grad.Rotation = 90
	grad.Parent = label
	bb.Parent = head
end

local function checkPasses(player: Player)
	for name, id in Config.Passes do
		if player:GetAttribute(name) ~= true then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, id)
			end)
			if ok and owns == true then
				player:SetAttribute(name, true)
			end
		end
	end
	player:SetAttribute("Premium", player.MembershipType == Enum.MembershipType.Premium)
	vipTag(player)
end

---------------------------------------------------------------------
-- Receipts
---------------------------------------------------------------------
-- each grant changes the profile and returns (undo, after): undo puts it back if the save fails,
-- after runs once the purchase is saved (messages, rebuilding the house); nil = can't grant now
local grants: { [number]: (Player, any, any) -> ((() -> ())?, (() -> ())?) } = {}

grants[Config.Products.Spin] = function(player, _profile, d)
	d.Spins.wheel = (d.Spins.wheel or 0) + 1
	return function()
		d.Spins.wheel -= 1
	end, function()
		deps.Rewards.send(player, { kind = "bought", what = "1 " .. Config.Rewards.Wheels.wheel.name })
		deps.Rewards.refresh(player)
	end
end

grants[Config.Products.StarterPack] = function(player, profile, d)
	local cash = Config.StarterPackCash
	if d.StarterPack then
		-- (bought again past the client's block: the pack is once per player, so it pays its cash only)
		PlayerData.addCash(player, cash)
		return function()
			PlayerData.addCash(player, -cash)
		end, function()
			deps.notify(player, "Starter Pack already claimed: +$" .. cash)
		end
	end
	-- a pick waits only if one of the starter cars isn't owned yet; else its price in cash
	local free = false
	for _, c in Config.Menu.StarterChoices do
		local id = if deps.Cars.forSale(c.id) or not c.fallback then c.id else c.fallback
		if not profile.Owned[id] then
			free = true
		end
	end
	local extra = if free then 0 else (deps.Cars.ById[Config.Menu.StarterChoices[1].id] or {}).Price or 0
	d.StarterPack = true
	d.StarterPick = free
	PlayerData.addCash(player, cash + extra)
	return function()
		d.StarterPack = false
		d.StarterPick = false
		PlayerData.addCash(player, -(cash + extra))
	end, function()
		player:SetAttribute("StarterPack", true)
		player:SetAttribute("StarterPick", free)
		deps.notify(player, "STARTER PACK: +$" .. (cash + extra) .. (if free then ", now pick your car" else ""))
	end
end

grants[Config.Products.GarageSpace] = function(player, profile, _d)
	local design = deps.Houses.bayRoom(player)
	if not design then
		-- (the house went away between the prompt and the receipt: the space's cash price instead)
		local price = Config.Houses.BayPrices[1]
		PlayerData.addCash(player, price)
		return function()
			PlayerData.addCash(player, -price)
		end, function()
			deps.notify(player, "No house with room for a space: +$" .. price .. " instead")
		end
	end
	profile.HouseExtraBays = profile.HouseExtraBays or {}
	profile.HouseExtraBays[design] = (profile.HouseExtraBays[design] or 0) + 1
	return function()
		profile.HouseExtraBays[design] -= 1
	end, function()
		deps.Houses.rebuild(player)
		deps.notify(player, "GARAGE SPACE added")
	end
end

-- (exposed for tools/store_test.luau)
function Store.processReceipt(info: any): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(info.PlayerId)
	local profile = player and PlayerData.get(player) :: any
	if not (player and profile and profile.Loaded) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local d = deps.Rewards.data(profile)
	local pid = tostring(info.PurchaseId)
	if table.find(d.Receipts, pid) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	local grant = grants[info.ProductId]
	if not grant then
		warn("[CityLegends] receipt for an unknown product", info.ProductId)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local undo, after = grant(player, profile, d)
	if not undo then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	table.insert(d.Receipts, pid)
	while #d.Receipts > 50 do
		table.remove(d.Receipts, 1)
	end
	if not PlayerData.save(player) then
		undo()
		table.remove(d.Receipts, table.find(d.Receipts, pid) or #d.Receipts)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if after then
		task.spawn(after)
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function Store.init(ctx: any, d: any)
	deps = d
	MarketplaceService.ProcessReceipt = Store.processReceipt
	if game:GetService("RunService"):IsStudio() then
		-- (Studio only: a test can send the same receipt twice; ServerStorage is never on clients)
		local hook = Instance.new("BindableFunction")
		hook.Name = "StoreTestReceipt"
		hook.OnInvoke = function(info: any)
			return Store.processReceipt(info).Name
		end
		hook.Parent = game:GetService("ServerStorage")
	end
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, passId: number, bought: boolean)
		if not bought then
			return
		end
		for name, id in Config.Passes do
			if id == passId then
				player:SetAttribute(name, true)
				deps.notify(player, "Thanks! Pass active")
			end
		end
		vipTag(player)
	end)
	Players.PlayerMembershipChanged:Connect(function(player)
		player:SetAttribute("Premium", player.MembershipType == Enum.MembershipType.Premium)
	end)
	local function join(player: Player)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("Head", 10)
			vipTag(player)
		end)
		task.spawn(checkPasses, player)
		-- the saved Starter Pack state, once the save is loaded
		task.spawn(function()
			local deadline = os.clock() + 60
			while player.Parent and os.clock() < deadline do
				local profile = PlayerData.get(player) :: any
				if profile and profile.Loaded then
					local rd = deps.Rewards.data(profile)
					player:SetAttribute("StarterPack", rd.StarterPack)
					player:SetAttribute("StarterPick", rd.StarterPick)
					return
				end
				task.wait(0.5)
			end
		end)
	end
	Players.PlayerAdded:Connect(join)
	for _, p in Players:GetPlayers() do
		join(p)
	end
	local _ = ctx
end

return Store
