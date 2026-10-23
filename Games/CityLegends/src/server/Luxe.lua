--[[
	Luxe (server)
	What the rich spend on Downtown (owner, 2026-10-22): VIP membership at the High-Rollers Casino
	and flex items from the Legends Gem Showcase.
	  * VIP cards (Config.Luxe.Vip): a title over your head that everyone sees, the casino's VIP
	    lounge, and money off at the Gem Showcase. A higher card costs the difference.
	  * Wearables (Config.Luxe.Items, built by Flex): bought once, one worn per slot, welded onto
	    your character so everyone sees them, saved in the profile's Luxe field.
	  * Heist loot shared with the bank: Luxe.addLoot fills the same bag (the Loot attribute) that the
	    bank's drop-off pays out.
	Remotes: LuxeCall (RemoteFunction: state, buy, wear, remove, vip) and LuxeEvent (server ->
	client: open the shop / VIP desk, heist messages).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Flex = require(Shared:WaitForChild("Flex"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local L = Config.Luxe

local Luxe = {}

local event: RemoteEvent? = nil

type Data = { vip: number, items: { [string]: boolean }, worn: { [string]: string } }

-- profile Luxe tables already checked (weak: they go with the profile)
local cleaned: { [any]: boolean } = setmetatable({}, { __mode = "k" }) :: any

-- the profile's Luxe table, cleaned up (unknown items and wrong slots dropped)
local function data(player: Player): Data?
	local profile = PlayerData.get(player)
	if not profile then
		return nil
	end
	local raw = (profile :: any).Luxe
	if type(raw) ~= "table" then
		raw = {}
		;(profile :: any).Luxe = raw
	end
	if cleaned[raw] then
		return raw
	end
	local vip = if type(raw.vip) == "number" then math.clamp(math.floor(raw.vip), 0, #L.Vip) else 0
	local items: { [string]: boolean } = {}
	if type(raw.items) == "table" then
		for k, v in raw.items do
			-- (saved as a list of ids or as a set)
			local id = if type(k) == "string" and v == true then k elseif type(v) == "string" then v else nil
			if id and Flex.ById[id] then
				items[id] = true
			end
		end
	end
	local worn: { [string]: string } = {}
	if type(raw.worn) == "table" then
		for slot, id in raw.worn do
			local it = if type(id) == "string" then Flex.ById[id] else nil
			if it and it.slot == slot and items[id] then
				worn[slot] = id
			end
		end
	end
	local clean = { vip = vip, items = items, worn = worn }
	cleaned[clean] = true
	;(profile :: any).Luxe = clean
	return clean :: any
end

function Luxe.vipOf(player: Player): number
	local d = data(player)
	return if d then d.vip else 0
end

function Luxe.discount(player: Player): number
	local tier = L.Vip[Luxe.vipOf(player)]
	return if tier then tier.discount else 0
end

local function priceFor(player: Player, item: Flex.Item): number
	return math.floor(item.price * (1 - Luxe.discount(player)))
end

local function state(player: Player): { [string]: any }
	local d = data(player)
	local owned = {}
	local worn = {}
	if d then
		for id in d.items do
			table.insert(owned, id)
		end
		for slot, id in d.worn do
			worn[slot] = id
		end
	end
	return { vip = if d then d.vip else 0, owned = owned, worn = worn, discount = Luxe.discount(player) }
end

---------------------------------------------------------------------
-- On the character: the worn items and the VIP title
---------------------------------------------------------------------
local function titleTag(character: Model, vip: number)
	local head = character:FindFirstChild("Head")
	if not head then
		return
	end
	local old = head:FindFirstChild("LuxeTitle")
	if old then
		old:Destroy()
	end
	local tier = L.Vip[vip]
	if not tier then
		return
	end
	local bb = Instance.new("BillboardGui")
	bb.Name = "LuxeTitle"
	bb.Size = UDim2.fromOffset(240, 34)
	bb.StudsOffset = Vector3.new(0, 2.9, 0)
	bb.MaxDistance = 140
	bb.LightInfluence = 0
	bb.Parent = head
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.Text = "◆ " .. tier.title .. " ◆"
	label.TextColor3 = tier.color
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0.35
	label.Parent = bb
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new(tier.color, Color3.new(1, 1, 1))
	grad.Rotation = 90
	grad.Parent = label
end

local function dress(player: Player)
	local character = player.Character
	if not character then
		return
	end
	local d = data(player)
	if not d then
		return
	end
	for _, slot in L.Slots do
		local id = d.worn[slot]
		local it = if id then Flex.ById[id] else nil
		if it then
			Flex.wear(character, it)
		else
			Flex.remove(character, slot)
		end
	end
	titleTag(character, d.vip)
end

-- testers (console "UnlockEverything"): the top VIP card and every flex item
function Luxe.unlockAll(player: Player)
	local d = data(player)
	if not d then
		return
	end
	d.vip = #L.Vip
	for id in Flex.ById do
		d.items[id] = true
	end
	dress(player)
end

local function onCharacter(player: Player, character: Model)
	-- wait for the body parts (R15 builds them a moment after CharacterAdded)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then
		return
	end
	character:WaitForChild("Head", 5)
	task.wait(0.2)
	if player.Character == character then
		dress(player)
	end
end

---------------------------------------------------------------------
-- Heist loot (the bank's bag and drop-off)
---------------------------------------------------------------------
-- adds to the bag, up to cap; returns the new total and what was added
function Luxe.addLoot(player: Player, amount: number, cap: number): (number, number)
	local carried = (player:GetAttribute("Loot") :: number?) or 0
	local total = math.min(cap, carried + math.floor(amount))
	total = math.max(total, carried)
	player:SetAttribute("Loot", if total > 0 then total else nil)
	return total, total - carried
end

-- a level bonus on heist grabs (like the bank's)
function Luxe.levelBoost(player: Player, amount: number): number
	local profile = PlayerData.get(player)
	local level = if profile then (profile :: any).Level or 1 else 1
	return math.floor(amount * (1 + math.min(level, 50) * 0.02))
end

function Luxe.fire(player: Player, info: { [string]: any })
	if event then
		event:FireClient(player, info)
	end
end

function Luxe.fireAll(info: { [string]: any })
	if event then
		event:FireAllClients(info)
	end
end

---------------------------------------------------------------------
-- Remotes
---------------------------------------------------------------------
local handlers: { [string]: (Player, any) -> { [string]: any } } = {}

handlers.state = function(player)
	return { ok = true, state = state(player) }
end

handlers.buy = function(player, id)
	local it = if type(id) == "string" then Flex.ById[id] else nil
	local d = data(player)
	local profile = PlayerData.get(player)
	if not (it and d and profile) then
		return { ok = false }
	end
	if d.items[it.id] then
		return { ok = false, message = "You already own it" }
	end
	local cost = priceFor(player, it)
	if profile.Cash < cost then
		return { ok = false, message = "Not enough cash" }
	end
	PlayerData.addCash(player, -cost)
	d.items[it.id] = true
	d.worn[it.slot] = it.id
	dress(player)
	task.spawn(PlayerData.save, player)
	return { ok = true, cost = cost, state = state(player) }
end

handlers.wear = function(player, id)
	local it = if type(id) == "string" then Flex.ById[id] else nil
	local d = data(player)
	if not (it and d and d.items[it.id]) then
		return { ok = false }
	end
	d.worn[it.slot] = it.id
	dress(player)
	return { ok = true, state = state(player) }
end

handlers.remove = function(player, slot)
	local d = data(player)
	if not d or type(slot) ~= "string" then
		return { ok = false }
	end
	d.worn[slot] = nil
	dress(player)
	return { ok = true, state = state(player) }
end

handlers.vip = function(player, tierId)
	local tier = if type(tierId) == "number" then L.Vip[tierId] else nil
	local d = data(player)
	local profile = PlayerData.get(player)
	if not (tier and d and profile) then
		return { ok = false }
	end
	if d.vip >= tier.id then
		return { ok = false, message = "You already have this card" }
	end
	local current = L.Vip[d.vip]
	local cost = tier.price - (if current then current.price else 0)
	if profile.Cash < cost then
		return { ok = false, message = "Not enough cash" }
	end
	PlayerData.addCash(player, -cost)
	d.vip = tier.id
	dress(player)
	task.spawn(PlayerData.save, player)
	Luxe.fireAll({ kind = "vip", by = player.DisplayName, card = tier.name })
	return { ok = true, cost = cost, state = state(player) }
end

function Luxe.init(ctx: any)
	local call: RemoteFunction = ctx.remote("RemoteFunction", "LuxeCall")
	event = ctx.remote("RemoteEvent", "LuxeEvent")
	call.OnServerInvoke = function(player: Player, what: any, arg: any)
		local h = if type(what) == "string" then handlers[what] else nil
		if not h then
			return { ok = false }
		end
		return h(player, arg)
	end
	local function hook(player: Player)
		player.CharacterAdded:Connect(function(character)
			onCharacter(player, character)
		end)
		if player.Character then
			task.spawn(onCharacter, player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(hook)
	for _, player in Players:GetPlayers() do
		hook(player)
	end
end

return Luxe
