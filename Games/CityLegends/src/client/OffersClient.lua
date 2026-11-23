--[[
	OffersClient (see server/Offers.lua; owner approved 19 Nov 2026: "make the store easy to find")
	  * the Starter Pack card: a small card under the top bars when the server says it's a right
	    moment (first race or paycheck of a session); BUY opens Roblox's buy window, CLOSE counts a
	    no. No timers, no "was" prices; the price comes from Roblox.
	  * the Double Pay link: under a job paycheck for players without Double Pay, at most once
	    every 10 minutes, gone after 6 s; a tap opens the pass's buy window. Never blocks driving.
	  * the STORE tab's measuring: the tab seen (clears the HUD SHOP "!"), each buy window opened.
	Same look as the job's "Still on shift?" card (UI.kit: panel, gold hairline, kit buttons).
]]

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local UI = require(script.Parent:WaitForChild("UI"))
local Audio = require(script.Parent:WaitForChild("Audio"))
local MenuArt = require(script.Parent:WaitForChild("MenuArt"))

local OffersClient = {}

local Theme = Config.Theme
local kit = UI.kit
local new, label, button, corner, stroke, tween = kit.new, kit.label, kit.button, kit.corner, kit.stroke, kit.tween
local GOLD = Theme.Accent2
local player = Players.LocalPlayer
local PAYLINK_GAP = 600 -- seconds between two Double Pay links

local call: RemoteFunction? = nil
local lastLink = -math.huge

local function report(what: string, key: string?, where: string?)
	local c = call
	if c then
		task.spawn(pcall, c.InvokeServer, c, what, key, where)
	end
end

local function item(key: string): any
	for _, it in Config.Menu.Store do
		if it.key == key then
			return it
		end
	end
	return nil
end

-- the top slot under the level bar; below the job's shift card when that is up
local function slotY(): number
	local y = if UI.isTouch then 82 else 92
	local hud = UI.screen():FindFirstChild("HUD")
	local ask = hud and hud:FindFirstChild("JobShiftCheck")
	if ask and (ask :: Frame).Visible then
		y += 52
	end
	return y
end

local function priceOf(it: any, into: TextButton, word: string)
	task.spawn(function()
		local ok, info = pcall(function()
			return MarketplaceService:GetProductInfo(it.id, if it.kind == "Pass" then Enum.InfoType.GamePass else Enum.InfoType.Product)
		end)
		if ok and info and info.PriceInRobux and into.Parent then
			into.Text = word .. "  R$ " .. tostring(info.PriceInRobux)
		end
	end)
end

local card: Frame? = nil
local function showStarter()
	local it = item("starter")
	local hud = UI.screen():FindFirstChild("HUD")
	if card or not it or not hud or player:GetAttribute("StarterPack") == true then
		return
	end
	-- (one thing at a time: the card takes the slot from a Double Pay link)
	local link = hud:FindFirstChild("DoublePayLink")
	if link then
		link:Destroy()
	end
	local touch = UI.isTouch
	local w, h = if touch then 330 else 380, if touch then 84 else 92
	local c: Frame = new("Frame", {
		Name = "StarterOffer",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, slotY() - 12),
		Size = UDim2.fromOffset(w, h),
		BackgroundColor3 = Theme.Panel,
		BackgroundTransparency = 1,
		ZIndex = 20,
		Parent = hud,
	}, { corner(12), stroke(GOLD, 1, 0.4) })
	card = c
	local art = h - 16
	new("ImageLabel", { Image = MenuArt.store_starter, BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Crop, Position = UDim2.fromOffset(8, 8), Size = UDim2.fromOffset(art, art), ZIndex = 21, Parent = c }, { corner(8) })
	local tx = art + 18
	label({ Text = "STARTER PACK", TextSize = if touch then 15 else 17, Font = Enum.Font.GothamBlack, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(tx, 8), Size = UDim2.new(1, -tx - 40, 0, 20), ZIndex = 21, Parent = c })
	label({ Text = "$50,000 + a starter car you pick. Once per player", TextSize = if touch then 11 else 12, Font = Enum.Font.GothamMedium, TextColor3 = Theme.SubText, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Position = UDim2.fromOffset(tx, 28), Size = UDim2.new(1, -tx - 10, 0, 28), ZIndex = 21, Parent = c })
	local buy = button("BUY", Theme.Money, { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, tx, 1, -8), Size = UDim2.fromOffset(if touch then 120 else 130, if touch then 30 else 32), TextSize = 13, TextColor3 = Theme.Money, ZIndex = 21, Parent = c })
	priceOf(it, buy, "BUY")
	local close = button("X", Theme.Danger, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 6), Size = UDim2.fromOffset(if touch then 30 else 28, if touch then 30 else 28), TextSize = 13, TextColor3 = Theme.Danger, ZIndex = 21, Parent = c })
	local function gone(closed: boolean)
		if card ~= c then
			return
		end
		card = nil
		if closed then
			report("closed", "starter", "card")
		end
		tween(c, 0.2, { BackgroundTransparency = 1 })
		task.delay(0.2, function()
			c:Destroy()
		end)
	end
	buy.Activated:Connect(function()
		report("prompted", "starter", "card")
		MarketplaceService:PromptProductPurchase(player, it.id)
	end)
	close.Activated:Connect(function()
		gone(true)
	end)
	-- bought (Store.lua sets StarterPack): the card goes, the first-car picker takes over
	player:GetAttributeChangedSignal("StarterPack"):Connect(function()
		if player:GetAttribute("StarterPack") == true then
			gone(false)
		end
	end)
	tween(c, 0.25, { BackgroundTransparency = 0.08, Position = UDim2.new(0.5, 0, 0, slotY()) })
	Audio.play("tick", 0.6, 1.1)
	report("seen", "starter", "card")
end

-- a right moment from the server: wait for a calm screen (no menu, garage or dealer open)
local function onStarter()
	task.spawn(function()
		local deadline = os.clock() + 90
		while UI.modalOpen and os.clock() < deadline do
			task.wait(1)
		end
		if not UI.modalOpen then
			showStarter()
		end
	end)
end

local function showPayLink()
	local it = item("doublepay")
	local hud = UI.screen():FindFirstChild("HUD")
	if not it or not hud or card or UI.modalOpen or player:GetAttribute("DoublePay") == true or os.clock() - lastLink < PAYLINK_GAP then
		return
	end
	lastLink = os.clock()
	local b = button("2x with Double Pay  ›", GOLD, {
		Name = "DoublePayLink",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, slotY()),
		Size = UDim2.fromOffset(if UI.isTouch then 190 else 210, if UI.isTouch then 30 else 32),
		TextSize = 13,
		TextColor3 = GOLD,
		BackgroundColor3 = Theme.Panel,
		ZIndex = 20,
		Parent = hud,
	})
	b.Activated:Connect(function()
		report("prompted", "doublepay", "paylink")
		MarketplaceService:PromptGamePassPurchase(player, it.id)
		b:Destroy()
	end)
	report("seen", "doublepay", "paylink")
	task.delay(6, function()
		if b.Parent then
			tween(b, 0.3, { BackgroundTransparency = 1, TextTransparency = 1 })
			task.delay(0.3, function()
				b:Destroy()
			end)
		end
	end)
end

function OffersClient.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	call = remotes:WaitForChild("OfferCall", 20) :: RemoteFunction?
	local push = remotes:WaitForChild("OfferPush", 20) :: RemoteEvent?
	if push then
		push.OnClientEvent:Connect(function(msg: any)
			if type(msg) == "table" and msg.kind == "starter" then
				onStarter()
			end
		end)
	end
	-- a paycheck without Double Pay (Jobs' push; JobsClient shows the paycheck itself)
	local jobPush = remotes:WaitForChild("JobPush", 20) :: RemoteEvent?
	if jobPush then
		jobPush.OnClientEvent:Connect(function(msg: any)
			if type(msg) == "table" and msg.kind == "paid" and not msg.double and not player:GetAttribute("Guide") then -- (not during the new-player guide)
				task.delay(1.5, showPayLink) -- (after the PAYCHECK popup)
			end
		end)
	end
	local MainMenu = require(script.Parent:WaitForChild("MainMenu")) :: any
	MainMenu.onStore = function(what: string, key: string?)
		if what == "tab" then
			report("storeSeen")
		elseif what == "prompted" and key then
			report("prompted", key, "store")
		end
	end
end

-- (Studio tests) show the card or the link now
OffersClient.showStarter = showStarter
OffersClient.showPayLink = showPayLink

return OffersClient
