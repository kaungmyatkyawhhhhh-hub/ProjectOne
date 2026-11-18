--[[
	Offers (server; owner approved 19 Nov 2026: "make the dealership and the store easy to find")
	  * The Starter Pack card: offered at a right moment only (K04: small card, never in the
	    tutorial): the first finished race or job paycheck of a session, once the first car is
	    claimed, never once bought, never again after it was closed twice; at most once a session.
	  * The STORE's "!" (HUD SHOP button): player attribute StoreUnseen = store items this player
	    hasn't looked at yet (a new item in Config.Menu.Store shows it again).
	  * Measuring (monetization plan step 5, K04): Seen / Prompted / Bought per store item and per
	    place it was offered ("store", "card", "paylink"), as AnalyticsService custom events, else a
	    server log line.
	Saved in profile.Activities.offers = { seen = { [key] = true }, shown = n, closed = n }.
	Remote OfferCall(what, key?, where?): "seen", "prompted", "closed" (the card), "storeSeen".
	Remote OfferPush: { kind = "starter" }.
	Studio hook: server player attribute TestOfferReset = true clears the saved state and the session.
]]

local AnalyticsService = game:GetService("AnalyticsService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local Offers = {}

local MAX_CLOSED = 2 -- the card never comes back after it was closed this many times
local WHERE = { store = true, card = true, paylink = true }

local items: { [string]: { key: string, id: number, kind: string } } = {}
local byId: { [number]: string } = {}
for _, it in Config.Menu.Store do
	if it.id then
		items[it.key] = it
		byId[it.id] = it.key
	end
end

local offeredThisSession: { [Player]: boolean } = {}
local lastWhere: { [Player]: { [string]: string } } = {}
local calls: { [Player]: { n: number, t: number } } = {}
local push: RemoteEvent

local function state(player: Player): { [string]: any }?
	local profile = PlayerData.get(player) :: any
	if not (profile and profile.Loaded and type(profile.Activities) == "table") then
		return nil
	end
	local o = profile.Activities.offers
	if type(o) ~= "table" then
		o = {}
		profile.Activities.offers = o
	end
	o.seen = if type(o.seen) == "table" then o.seen else {}
	o.shown = if type(o.shown) == "number" then o.shown else 0
	o.closed = if type(o.closed) == "number" then o.closed else 0
	return o
end

-- one event per stage (OfferSeen / OfferPrompted / OfferBought), the item and the place as fields
local function log(player: Player, stage: string, key: string, where: string)
	local ok = pcall(function()
		AnalyticsService:LogCustomEvent(player, "Offer" .. stage, 1, {
			[Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = key,
			[Enum.AnalyticsCustomFieldKeys.CustomField02.Name] = where,
		})
	end)
	if not ok or RunService:IsStudio() then
		print(string.format("[Offers] %s %s %s %s", stage, key, where, player.Name))
	end
end

local function paintUnseen(player: Player)
	local o = state(player)
	if not o then
		return
	end
	local n = 0
	for key in items do
		if not o.seen[key] then
			n += 1
		end
	end
	player:SetAttribute("StoreUnseen", n)
end

-- a right moment (a finished race, a job paycheck): the Starter Pack card, if it's still wanted
function Offers.moment(player: Player)
	if offeredThisSession[player] or player:GetAttribute("StarterPack") == true then
		return
	end
	local profile = PlayerData.get(player) :: any
	local o = state(player)
	if not (o and profile.Claimed == true) or o.closed >= MAX_CLOSED then
		return
	end
	offeredThisSession[player] = true
	push:FireClient(player, { kind = "starter" })
end

function Offers.init(ctx: any)
	push = ctx.remote("RemoteEvent", "OfferPush")
	local call: RemoteFunction = ctx.remote("RemoteFunction", "OfferCall")
	-- the moments: Activities notes "races", Jobs "paychecks" (Goals' note, wrapped here)
	local note = ctx.note
	ctx.note = function(player: Player, what: string, n: number, ...)
		note(player, what, n, ...)
		if what == "races" or what == "paychecks" then
			task.delay(3, Offers.moment, player) -- (after the race result / paycheck popup)
		end
	end
	call.OnServerInvoke = function(player: Player, what: any, key: any, where: any)
		-- (a few calls a second at most: they only count)
		local c = calls[player]
		local now = os.clock()
		if not c or now - c.t > 10 then
			c = { n = 0, t = now }
			calls[player] = c
		end
		c.n += 1
		if c.n > 30 then
			return false
		end
		local o = state(player)
		if not o then
			return false
		end
		if what == "storeSeen" then
			for k in items do
				if not o.seen[k] then
					o.seen[k] = true
					log(player, "Seen", k, "store")
				end
			end
			paintUnseen(player)
			return true
		end
		if type(key) ~= "string" or not items[key] or type(where) ~= "string" or not WHERE[where] then
			return false
		end
		if what == "seen" then
			if where == "card" then
				o.shown += 1
			end
			log(player, "Seen", key, where)
		elseif what == "prompted" then
			lastWhere[player] = lastWhere[player] or {}
			lastWhere[player][key] = where
			log(player, "Prompted", key, where)
		elseif what == "closed" and where == "card" then
			o.closed += 1
		else
			return false
		end
		return true
	end
	local function bought(player: Player, id: number)
		local key = byId[id]
		if key then
			local w = lastWhere[player] and lastWhere[player][key] or "store"
			log(player, "Bought", key, w)
		end
	end
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, id: number, ok: boolean)
		if ok then
			bought(player, id)
		end
	end)
	MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId: number, id: number, ok: boolean)
		local player = Players:GetPlayerByUserId(userId)
		if ok and player then
			bought(player, id)
		end
	end)
	local function join(player: Player)
		task.spawn(function()
			local deadline = os.clock() + 60
			while player.Parent and os.clock() < deadline and not state(player) do
				task.wait(0.5)
			end
			paintUnseen(player)
		end)
		if RunService:IsStudio() then
			player:GetAttributeChangedSignal("TestOfferReset"):Connect(function()
				local profile = PlayerData.get(player) :: any
				if player:GetAttribute("TestOfferReset") == true and profile and type(profile.Activities) == "table" then
					profile.Activities.offers = nil
					offeredThisSession[player] = nil
					player:SetAttribute("TestOfferReset", nil)
					paintUnseen(player)
				end
			end)
		end
	end
	Players.PlayerAdded:Connect(join)
	for _, p in Players:GetPlayers() do
		join(p)
	end
	Players.PlayerRemoving:Connect(function(player)
		offeredThisSession[player] = nil
		lastWhere[player] = nil
		calls[player] = nil
	end)
end

return Offers
