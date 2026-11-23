--[[
	Guide (server; owner approved 24 Nov 2026: "the first 5 minutes for new players"; vault
	"City Legends/2026-11-24 First 5 minutes for new players.md")
	A new player's short guided start: 1 pick a car (the menu's claim) -> 2 drive to the Myanmar Plaza
	dispatch -> 3 deliver one parcel -> 4 see the next goal -> DONE. The hints and the arrow are the
	client's (client/Guide.lua); this only keeps the step, saves it and counts it.
	  * Saved as profile.Activities.guide = step (DONE when finished or skipped). Only a save that is
	    still unclaimed when it loads starts it: old saves never see it.
	  * Player attribute "Guide" = the step while it runs: Activities sends the first parcel to the
	    nearest drop; Offers and OffersClient show no shop card / pass link while it runs (Playbook:
	    no shop offers in the tutorial).
	  * Remote GuideCall: "get" -> { step, car, price } (the cheapest dealer car you don't own: the
	    next goal), "step"(n) moves forward only, "skip".
	  * Onboarding funnel (AnalyticsService, server only, counts in a published game) once per step,
	    plus a custom event GuideSkipped (field: the step).
	Studio hook: server player attribute TestGuide = true starts the guide again from step 1.
]]

local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Cars = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Cars"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local Guide = {}

local DONE = 99
local FUNNEL = { "Joined", "Got a car", "Delivery started", "Delivered", "Next goal seen" }

local function profileOf(player: Player): any
	local profile = PlayerData.get(player) :: any
	if profile and profile.Loaded and type(profile.Activities) == "table" then
		return profile
	end
	return nil
end

local function funnel(player: Player, upTo: number)
	-- (Roblox counts each step once per player, and step n completes the ones before it)
	local n = math.min(upTo, #FUNNEL)
	pcall(function()
		AnalyticsService:LogOnboardingFunnelStepEvent(player, n, FUNNEL[n])
	end)
	if RunService:IsStudio() then
		print(string.format("[Guide] %s step %d %s", player.Name, n, FUNNEL[n]))
	end
end

local function set(player: Player, profile: any, step: number)
	profile.Activities.guide = step
	player:SetAttribute("Guide", if step < DONE then step else nil)
end

-- the next goal after the first job: the cheapest dealer (Local) car you don't own yet
local function nextCar(profile: any): (string?, number?)
	local best = nil
	for _, c in Cars.List do
		if (c.Price or 0) > 0 and not Cars.isImport(c.Id) and not (profile.Owned and profile.Owned[c.Id]) then
			if not best or c.Price < best.Price then
				best = c
			end
		end
	end
	return if best then best.Name else nil, if best then best.Price else nil
end

local handlers: { [string]: (Player, any, any) -> any } = {}

handlers.get = function(_player, profile)
	local car, price = nextCar(profile)
	return { step = tonumber(profile.Activities.guide) or DONE, car = car, price = price }
end

handlers.step = function(player, profile, n)
	local cur = tonumber(profile.Activities.guide) or DONE -- (not set yet: the join hasn't read the save)
	if type(n) ~= "number" or n ~= n or cur >= DONE or n <= cur then
		return { step = cur }
	end
	n = math.clamp(math.floor(n), cur + 1, DONE)
	set(player, profile, n)
	funnel(player, if n >= DONE then #FUNNEL else n)
	return { step = n }
end

handlers.skip = function(player, profile)
	local cur = tonumber(profile.Activities.guide) or DONE -- (not set yet: the join hasn't read the save)
	if cur < DONE then
		pcall(function()
			AnalyticsService:LogCustomEvent(player, "GuideSkipped", cur)
		end)
		set(player, profile, DONE)
	end
	return { step = DONE }
end

function Guide.init(ctx: any)
	local call: RemoteFunction = ctx.remote("RemoteFunction", "GuideCall")
	local lastCall: { [Player]: number } = {}
	call.OnServerInvoke = function(player: Player, what: any, arg: any)
		local h = if type(what) == "string" then handlers[what] else nil
		local profile = profileOf(player)
		if not (h and profile) or os.clock() - (lastCall[player] or 0) < 0.2 then
			return nil
		end
		lastCall[player] = os.clock()
		return h(player, profile, arg)
	end
	local function join(player: Player)
		task.spawn(function()
			local deadline = os.clock() + 60
			local profile = profileOf(player)
			while player.Parent and os.clock() < deadline and not profile do
				task.wait(0.5)
				profile = profileOf(player)
			end
			if not profile then
				return
			end
			local g = profile.Activities.guide
			if type(g) ~= "number" then
				-- (only a brand-new save starts it: an unclaimed first car)
				g = if profile.Claimed == false then 1 else DONE
			end
			set(player, profile, g)
			if g == 1 then
				funnel(player, 1)
			end
		end)
		if RunService:IsStudio() then
			player:GetAttributeChangedSignal("TestGuide"):Connect(function()
				local profile = profileOf(player)
				if player:GetAttribute("TestGuide") == true and profile then
					player:SetAttribute("TestGuide", nil)
					set(player, profile, 1)
				end
			end)
		end
	end
	Players.PlayerAdded:Connect(join)
	for _, p in Players:GetPlayers() do
		join(p)
	end
	Players.PlayerRemoving:Connect(function(player)
		lastCall[player] = nil
	end)
end

return Guide
