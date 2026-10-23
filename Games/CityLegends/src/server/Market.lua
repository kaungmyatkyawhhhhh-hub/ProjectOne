--[[
	Market (server): the car stock market (owner, 2026-10-22, modelled on the Flip Rush market).
	Every car in the roster trades as collectible stock in four conditions (Barn find, Driven,
	Clean, Showroom). Owning a unit is not owning the car; a Showroom unit can be taken delivery
	of (it becomes a car in your garage).
	  * prices: a random walk per car round a base value (a share of the dealer price), moved
	    every Config.Market.TickSeconds and nudged by news ("Lambrini ▲ ..."); history kept for
	    the sparklines
	  * listings: a few cars for sale per player; tap to buy at the asking price, hold to
	    lowball (a chance of a discount, else the seller walks)
	  * stash: what you hold; sell to the market (Stalls) for its value minus fees, or to an NPC
	    buyer's offer (no fee)
	  * requests: three a day, a buyer wants a car in a condition (or better) for a premium
	  * hype: good flips raise it (better offers, lower fees, lowballs land more); it fades
	  * Flip-off: 3 minutes to out-earn Slick Vinny for a prize
	Everything is decided here; the client only asks (MarketCall) and shows (MarketPush).
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Cars = require(Shared:WaitForChild("Cars"))

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local M = Config.Market
local Market = {}

type Cond = { Id: string, Name: string, Mult: number, Color: Color3 }
local COND: { [string]: Cond } = {}
local RANK: { [string]: number } = {}
for i, c in M.Conditions do
	COND[c.Id] = c
	RANK[c.Id] = i
end

type Item = { u: string, c: string, k: string, p: number, t: number }
type Request = { c: string, k: string, m: number, done: boolean }
type Data = {
	Stash: { Item },
	Hype: number,
	HypeAt: number,
	Day: number,
	Req: { Request },
	Profit: number,
	Flips: number,
	Wins: number,
}
type Listing = { lid: number, c: string, k: string, ask: number, rating: number }
type Offer = { u: string, amount: number, rating: number, expires: number }
type FlipOff = { endsAt: number, mine: number, vinny: number, step: number }
type Session = {
	listings: { Listing },
	nextLid: number,
	offer: Offer?,
	nextOffer: number,
	open: boolean,
	flip: FlipOff?,
	flipReady: number,
}

local rng = Random.new()
local sessions: { [Player]: Session } = {}
local push: RemoteEvent? = nil

---------------------------------------------------------------------
-- Prices
---------------------------------------------------------------------
local base: { [string]: number } = {}
local price: { [string]: number } = {}
local hist: { [string]: { number } } = {}
local drift: { [string]: { per: number, left: number } } = {}

local function gauss(): number
	local u1 = math.max(rng:NextNumber(), 1e-9)
	return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * rng:NextNumber())
end

local function brandOf(id: string): string
	local spec = Cars.ById[id]
	return if spec then (spec.Name:match("^(%S+)") or spec.Name) else id
end

local function stepPrice(id: string)
	local b, p = base[id], price[id]
	local move = 0
	local d = drift[id]
	if d and d.left > 0 then
		move = d.per
		d.left -= 1
	end
	local lp = math.log(p) + move + M.Volatility * gauss() + M.Revert * (math.log(b) - math.log(p))
	p = math.clamp(math.exp(lp), b * M.Floor, b * M.Ceiling)
	price[id] = p
	local h = hist[id]
	table.insert(h, p)
	while #h > M.History do
		table.remove(h, 1)
	end
end

for _, spec in Cars.List do
	local b = math.max(M.MinBase, spec.Price * M.BaseK)
	base[spec.Id] = b
	price[spec.Id] = b * rng:NextNumber(0.85, 1.15)
	hist[spec.Id] = {}
	for _ = 1, M.History do
		stepPrice(spec.Id)
	end
end

local function value(id: string, cond: string): number
	local c = COND[cond]
	return math.floor((price[id] or 0) * (if c then c.Mult else 1))
end
Market.value = value

---------------------------------------------------------------------
-- News: a brand or a class moves for a few ticks
---------------------------------------------------------------------
local BRANDS: { string } = {}
do
	local seen = {}
	for _, spec in Cars.List do
		local b = brandOf(spec.Id)
		if not seen[b] then
			seen[b] = true
			table.insert(BRANDS, b)
		end
	end
end
local CLASS_TAG = { Sedan = "Sedans", Coupe = "Coupes", SUV = "SUVs", Supercar = "Supercars", Hypercar = "Hypercars" }
local UP_LINES = {
	"Collectors are hunting them down",
	"New hypercar reveal has fans buzzing",
	"Celebrity spotted in one downtown",
	"Limited run sells out overnight",
	"Wins the Legends Cup",
	"Street racers can't get enough",
	"Auction record smashed",
}
local DOWN_LINES = {
	"Recall hits the news",
	"Dealers dump their stock",
	"Influencer trashes the ride",
	"Parts shortage drags on",
	"Insurance prices go through the roof",
	"Everyone's selling at once",
	"Review calls it boring",
}
local news = { tag = "Market", up = true, text = "Doors open: buy low, flip high", at = os.time() }

local function makeNews()
	local up = rng:NextNumber() < 0.55
	local impact = rng:NextNumber(M.NewsImpact[1], M.NewsImpact[2])
	local per = math.log(1 + impact) / M.NewsTicks * (if up then 1 else -1)
	local tag: string
	if rng:NextNumber() < 0.7 then
		tag = BRANDS[rng:NextInteger(1, #BRANDS)]
		for _, spec in Cars.List do
			if brandOf(spec.Id) == tag then
				drift[spec.Id] = { per = per, left = M.NewsTicks }
			end
		end
	else
		local classes = Cars.Classes
		local class = classes[rng:NextInteger(1, #classes)]
		tag = CLASS_TAG[class] or class
		for _, spec in Cars.List do
			if spec.Class == class then
				drift[spec.Id] = { per = per, left = M.NewsTicks }
			end
		end
	end
	local lines = if up then UP_LINES else DOWN_LINES
	news = { tag = tag, up = up, text = lines[rng:NextInteger(1, #lines)], at = os.time() }
end

---------------------------------------------------------------------
-- Player data (kept in the profile, checked on every load)
---------------------------------------------------------------------
local function today(): number
	return math.floor(os.time() / 86400)
end

local function dataOf(player: Player): Data?
	local profile = PlayerData.get(player)
	if not profile then
		return nil
	end
	local raw = profile.Market
	if type(raw) ~= "table" then
		raw = {}
		profile.Market = raw
	end
	local d = raw :: any
	if type(d.Stash) ~= "table" then
		d.Stash = {}
	end
	local clean: { Item } = {}
	for _, it in d.Stash do
		if type(it) == "table" and type(it.c) == "string" and Cars.ById[it.c] and COND[it.k] and type(it.p) == "number" then
			table.insert(clean, {
				u = if type(it.u) == "string" then it.u else HttpService:GenerateGUID(false):sub(1, 8),
				c = it.c,
				k = it.k,
				p = math.max(0, math.floor(it.p)),
				t = if type(it.t) == "number" then it.t else os.time(),
			})
		end
		if #clean >= M.StashSlots then
			break
		end
	end
	d.Stash = clean
	d.Hype = math.clamp(math.floor(tonumber(d.Hype) or 0), 0, M.HypeMax)
	d.HypeAt = tonumber(d.HypeAt) or os.time()
	d.Day = tonumber(d.Day) or 0
	d.Profit = tonumber(d.Profit) or 0
	d.Flips = tonumber(d.Flips) or 0
	d.Wins = tonumber(d.Wins) or 0
	if type(d.Req) ~= "table" then
		d.Req = {}
	end
	-- hype fades a point per HypeDecayMinutes without a good flip
	local step = M.HypeDecayMinutes * 60
	if d.Hype > 0 then
		local fades = math.floor((os.time() - d.HypeAt) / step)
		if fades > 0 then
			d.Hype = math.max(0, d.Hype - fades)
			d.HypeAt += fades * step
		end
	else
		d.HypeAt = os.time()
	end
	return d :: Data
end

local function addHype(d: Data, n: number)
	d.Hype = math.clamp(d.Hype + n, 0, M.HypeMax)
	d.HypeAt = os.time()
end

local function fee(d: Data): number
	return math.max(M.MinFee, M.Fee - M.FeePerHype * d.Hype)
end

local function stashValue(d: Data): number
	local total = 0
	for _, it in d.Stash do
		total += value(it.c, it.k)
	end
	return total
end

local function pickCond(): string
	local r = rng:NextNumber()
	if r < 0.2 then
		return "Barn"
	elseif r < 0.55 then
		return "Driven"
	elseif r < 0.85 then
		return "Clean"
	end
	return "Showroom"
end

-- a car a player can think about buying: mostly ones they can afford, some to dream about
local function pickCar(cash: number): string
	local list = Cars.List
	if rng:NextNumber() < 0.7 then
		local cap = math.max(cash * 0.9, 25000)
		local ok = {}
		for _, spec in list do
			if value(spec.Id, "Driven") <= cap then
				table.insert(ok, spec.Id)
			end
		end
		if #ok > 0 then
			return ok[rng:NextInteger(1, #ok)]
		end
	end
	return list[rng:NextInteger(1, #list)].Id
end

local function refreshRequests(player: Player, d: Data)
	local day = today()
	if d.Day == day and #d.Req == M.Requests then
		return
	end
	local profile = PlayerData.get(player)
	local cash = if profile then profile.Cash else 0
	d.Day = day
	d.Req = {}
	for _ = 1, M.Requests do
		local k = ({ "Driven", "Clean", "Clean", "Showroom" })[rng:NextInteger(1, 4)]
		table.insert(d.Req, {
			c = pickCar(cash * 1.5),
			k = k,
			m = math.floor(rng:NextNumber(M.RequestPremium[1], M.RequestPremium[2]) * 100) / 100,
			done = false,
		})
	end
end

---------------------------------------------------------------------
-- Sessions: listings, offers, flip-off
---------------------------------------------------------------------
-- the market-only cars a player could take delivery of next (the first of a series, or the one
-- after a car they own)
local function nextUnlocks(owned: { [string]: boolean }): { string }
	local out = {}
	for _, spec in Cars.List do
		if Cars.isMarketOnly(spec.Id) and not owned[spec.Id] then
			local prev = Cars.previous(spec.Id)
			if not prev or owned[prev] then
				table.insert(out, spec.Id)
			end
		end
	end
	return out
end

local function newListing(s: Session, cash: number, owned: { [string]: boolean }?): Listing
	s.nextLid += 1
	local c = pickCar(cash)
	local k = pickCond()
	-- a market-only car is hardly ever a Showroom unit
	if Cars.isMarketOnly(c) and k == "Showroom" and rng:NextNumber() > M.HighShowroomKeep then
		k = "Clean"
	end
	-- some listings are the high-end cars only the market sells, often in Showroom condition
	if owned and rng:NextNumber() < M.UnlockListingChance then
		local options = nextUnlocks(owned)
		if #options > 0 then
			c = options[rng:NextInteger(1, #options)]
			k = if rng:NextNumber() < M.UnlockShowroomChance then "Showroom" else pickCond()
		end
	end
	local spread = if Cars.isMarketOnly(c) then M.HighListingSpread else M.ListingSpread
	return {
		lid = s.nextLid,
		c = c,
		k = k,
		ask = math.floor(value(c, k) * rng:NextNumber(spread[1], spread[2])),
		rating = math.floor(rng:NextNumber(3.5, 5.0) * 10 + 0.5) / 10,
	}
end

local function session(player: Player): Session
	local s = sessions[player]
	if not s then
		s = {
			listings = {},
			nextLid = 0,
			offer = nil,
			nextOffer = os.clock() + rng:NextNumber(M.OfferEvery[1], M.OfferEvery[2]),
			open = false,
			flip = nil,
			flipReady = 0,
		}
		sessions[player] = s
	end
	local profile = PlayerData.get(player)
	local cash = if profile then profile.Cash else 0
	while #s.listings < M.Listings do
		table.insert(s.listings, newListing(s, cash, if profile then profile.Owned else nil))
	end
	return s
end

local function findItem(d: Data, u: any): (Item?, number)
	if type(u) ~= "string" then
		return nil, 0
	end
	for i, it in d.Stash do
		if it.u == u then
			return it, i
		end
	end
	return nil, 0
end

-- a sale closed: profit bookkeeping, hype and the flip-off score
local function closed(player: Player, d: Data, it: Item, got: number)
	local profit = got - it.p
	d.Profit += profit
	d.Flips += 1
	if it.p > 0 and profit / it.p >= M.HypeFlip then
		addHype(d, 1)
	end
	local s = sessions[player]
	if s and s.flip then
		s.flip.mine += profit
	end
end

---------------------------------------------------------------------
-- What the client sees
---------------------------------------------------------------------
local function state(player: Player): { [string]: any }?
	local d = dataOf(player)
	local profile = PlayerData.get(player)
	if not d or not profile then
		return nil
	end
	refreshRequests(player, d)
	local s = session(player)
	local now = os.clock()
	local histOut: { [string]: { number } } = {}
	local function withHist(id: string)
		if not histOut[id] then
			local h = {}
			for i, v in hist[id] do
				h[i] = math.floor(v)
			end
			histOut[id] = h
		end
	end
	local listings = {}
	for _, l in s.listings do
		withHist(l.c)
		table.insert(listings, { lid = l.lid, car = l.c, cond = l.k, ask = l.ask, mkt = value(l.c, l.k), rating = l.rating })
	end
	local stash = {}
	for _, it in d.Stash do
		withHist(it.c)
		table.insert(stash, { u = it.u, car = it.c, cond = it.k, value = value(it.c, it.k), paid = it.p, owned = profile.Owned[it.c] == true })
	end
	local offer = nil
	local o = s.offer
	if o and o.expires > now then
		local it = findItem(d, o.u)
		if it then
			offer = { u = o.u, car = it.c, cond = it.k, amount = o.amount, worth = value(it.c, it.k), rating = o.rating, left = math.ceil(o.expires - now) }
		end
	end
	local requests = {}
	for i, r in d.Req do
		table.insert(requests, { i = i, car = r.c, cond = r.k, pay = math.floor(value(r.c, r.k) * r.m), premium = r.m, done = r.done })
	end
	local flip = nil
	if s.flip then
		flip = { left = math.max(0, math.ceil(s.flip.endsAt - now)), mine = math.floor(s.flip.mine), vinny = math.floor(s.flip.vinny) }
	end
	return {
		cash = profile.Cash,
		fee = fee(d),
		hype = d.Hype,
		hypeMax = M.HypeMax,
		slots = M.StashSlots,
		news = { tag = news.tag, up = news.up, text = news.text },
		listings = listings,
		stash = stash,
		hist = histOut,
		offer = offer,
		requests = requests,
		resetIn = (today() + 1) * 86400 - os.time(),
		flip = flip,
		flipReadyIn = math.max(0, math.ceil(s.flipReady - now)),
		lowballChance = math.min(M.LowballMaxChance, M.LowballChance + M.LowballChancePerHype * d.Hype),
		profit = math.floor(d.Profit),
		flips = d.Flips,
		wins = d.Wins,
		tick = M.TickSeconds,
	}
end

local function pushTo(player: Player, extra: { [string]: any }?)
	local r = push
	if not r then
		return
	end
	local st = state(player)
	if st then
		if extra then
			for k, v in extra do
				st[k] = v
			end
		end
		r:FireClient(player, st)
	end
end

---------------------------------------------------------------------
-- Actions
---------------------------------------------------------------------
type Result = { ok: boolean, msg: string? }

local function buy(player: Player, d: Data, args: any): Result
	local s = session(player)
	local lid = if type(args) == "table" then tonumber(args.lid) else nil
	local lowball = type(args) == "table" and args.lowball == true
	local idx = 0
	for i, l in s.listings do
		if l.lid == lid then
			idx = i
		end
	end
	if idx == 0 then
		return { ok = false, msg = "That car just sold" }
	end
	if #d.Stash >= M.StashSlots then
		return { ok = false, msg = "Your stash is full: sell something first" }
	end
	local profile = PlayerData.get(player)
	if not profile then
		return { ok = false, msg = "Profile not loaded" }
	end
	local l = s.listings[idx]
	local pay = l.ask
	local msg = "Bought"
	if lowball then
		local chance = math.min(M.LowballMaxChance, M.LowballChance + M.LowballChancePerHype * d.Hype)
		if rng:NextNumber() > chance then
			table.remove(s.listings, idx)
			table.insert(s.listings, newListing(s, profile.Cash, profile.Owned))
			return { ok = false, msg = "Lowball refused: the seller walked" }
		end
		local off = rng:NextNumber(M.LowballDiscount[1], M.LowballDiscount[2])
		pay = math.floor(l.ask * (1 - off))
		msg = ("Lowball landed: %d%% off"):format(math.floor(off * 100 + 0.5))
	end
	if profile.Cash < pay then
		return { ok = false, msg = "Not enough cash" }
	end
	PlayerData.addCash(player, -pay)
	table.insert(d.Stash, { u = HttpService:GenerateGUID(false):sub(1, 8), c = l.c, k = l.k, p = pay, t = os.time() })
	table.remove(s.listings, idx)
	table.insert(s.listings, newListing(s, profile.Cash, profile.Owned))
	return { ok = true, msg = msg }
end

local function sell(player: Player, d: Data, args: any): Result
	local it, i = findItem(d, if type(args) == "table" then args.u else nil)
	if not it then
		return { ok = false, msg = "Not in your stash" }
	end
	local got = math.floor(value(it.c, it.k) * (1 - fee(d)))
	table.remove(d.Stash, i)
	PlayerData.addCash(player, got)
	closed(player, d, it, got)
	return { ok = true, msg = "Sold for " .. got }
end

local function acceptOffer(player: Player, d: Data): Result
	local s = session(player)
	local o = s.offer
	if not o or o.expires < os.clock() then
		s.offer = nil
		return { ok = false, msg = "The buyer left" }
	end
	local it, i = findItem(d, o.u)
	s.offer = nil
	s.nextOffer = os.clock() + rng:NextNumber(M.OfferEvery[1], M.OfferEvery[2])
	if not it then
		return { ok = false, msg = "Not in your stash any more" }
	end
	table.remove(d.Stash, i)
	PlayerData.addCash(player, o.amount)
	closed(player, d, it, o.amount)
	return { ok = true, msg = "Sold to the buyer" }
end

local function passOffer(player: Player): Result
	local s = session(player)
	s.offer = nil
	s.nextOffer = os.clock() + rng:NextNumber(M.OfferEvery[1], M.OfferEvery[2]) * 0.5
	return { ok = true }
end

local function fulfil(player: Player, d: Data, args: any): Result
	if type(args) ~= "table" then
		return { ok = false }
	end
	refreshRequests(player, d)
	local r = d.Req[tonumber(args.i) or 0]
	if not r or r.done then
		return { ok = false, msg = "That request is gone" }
	end
	local it, i = findItem(d, args.u)
	if not it then
		-- pick the best matching unit for them
		for j, x in d.Stash do
			if x.c == r.c and RANK[x.k] >= RANK[r.k] and (not it or RANK[x.k] < RANK[it.k]) then
				it, i = x, j
			end
		end
	end
	if not it or it.c ~= r.c or RANK[it.k] < RANK[r.k] then
		return { ok = false, msg = "You need that car in that condition (or better)" }
	end
	local got = math.floor(value(it.c, it.k) * r.m)
	table.remove(d.Stash, i)
	r.done = true
	PlayerData.addCash(player, got)
	closed(player, d, it, got)
	addHype(d, 1)
	return { ok = true, msg = "Request filled" }
end

local function redeem(player: Player, d: Data, args: any): Result
	local it, i = findItem(d, if type(args) == "table" then args.u else nil)
	local profile = PlayerData.get(player)
	if not it or not profile then
		return { ok = false, msg = "Not in your stash" }
	end
	if it.k ~= "Showroom" then
		return { ok = false, msg = "Only Showroom units can be delivered" }
	end
	if profile.Owned[it.c] then
		return { ok = false, msg = "You already own this car" }
	end
	-- a car in a series comes after the one before it (owner, 2026-10-22)
	local prev = Cars.previous(it.c)
	if prev and not profile.Owned[prev] then
		local ps = Cars.ById[prev]
		return { ok = false, msg = "Own the " .. (if ps then ps.Name else prev) .. " first" }
	end
	table.remove(d.Stash, i)
	profile.Owned[it.c] = true
	return { ok = true, msg = "Delivered to your garage" }
end

local function startFlip(player: Player, d: Data): Result
	local s = session(player)
	local now = os.clock()
	if s.flip then
		return { ok = false, msg = "Flip-off already running" }
	end
	if now < s.flipReady then
		return { ok = false, msg = "Vinny needs a breather" }
	end
	-- Vinny aims for a profit that matches your stash (and some cash), spread over the ticks
	local profile = PlayerData.get(player)
	local cash = if profile then profile.Cash else 0
	local target = math.max(4000, (stashValue(d) + cash * 0.3) * rng:NextNumber(0.03, 0.08))
	s.flip = { endsAt = now + M.FlipOffSeconds, mine = 0, vinny = 0, step = target / (M.FlipOffSeconds / M.TickSeconds) }
	return { ok = true, msg = "Flip-off: beat Slick Vinny in 3 minutes!" }
end

local ACTIONS: { [string]: (Player, Data, any) -> Result } = {
	buy = buy,
	sell = sell,
	accept = function(p, d)
		return acceptOffer(p, d)
	end,
	pass = function(p)
		return passOffer(p)
	end,
	fulfil = fulfil,
	redeem = redeem,
	flipoff = function(p, d)
		return startFlip(p, d)
	end,
}

---------------------------------------------------------------------
-- Loops
---------------------------------------------------------------------
local function finishFlip(player: Player, s: Session)
	local f = s.flip
	if not f then
		return
	end
	s.flip = nil
	s.flipReady = os.clock() + M.FlipOffCooldown
	local d = dataOf(player)
	local result = { won = false, mine = math.floor(f.mine), vinny = math.floor(f.vinny), prize = 0 }
	if d and f.mine > f.vinny then
		local prize = math.floor(M.FlipOffPrize + math.min(M.FlipOffPrizeCap, stashValue(d) * M.FlipOffPrizeShare))
		PlayerData.addCash(player, prize)
		addHype(d, 1)
		d.Wins += 1
		result.won = true
		result.prize = prize
	end
	pushTo(player, { flipResult = result })
end

local function tick()
	for id in price do
		stepPrice(id)
	end
	for player, s in sessions do
		if not player.Parent then
			continue
		end
		local profile = PlayerData.get(player)
		local cash = if profile then profile.Cash else 0
		-- a couple of listings rotate
		for _ = 1, M.ListingRotate do
			if #s.listings > 0 then
				table.remove(s.listings, rng:NextInteger(1, #s.listings))
			end
			table.insert(s.listings, newListing(s, cash, if profile then profile.Owned else nil))
		end
		local f = s.flip
		if f then
			f.vinny += f.step * rng:NextNumber(0.2, 1.8)
		end
		if s.open then
			pushTo(player)
		end
	end
end

local function offers()
	local now = os.clock()
	for player, s in sessions do
		if not player.Parent then
			continue
		end
		local f = s.flip
		if f and now >= f.endsAt then
			finishFlip(player, s)
		end
		local o = s.offer
		if o and o.expires < now then
			s.offer = nil
			o = nil
			if s.open then
				pushTo(player)
			end
		end
		if not o and now >= s.nextOffer then
			s.nextOffer = now + rng:NextNumber(M.OfferEvery[1], M.OfferEvery[2])
			local d = dataOf(player)
			if d and #d.Stash > 0 then
				local it = d.Stash[rng:NextInteger(1, #d.Stash)]
				local amount = value(it.c, it.k) * rng:NextNumber(M.OfferSpread[1], M.OfferSpread[2]) * (1 + M.OfferPerHype * d.Hype)
				s.offer = {
					u = it.u,
					amount = math.floor(amount),
					rating = math.floor(rng:NextNumber(3.5, 5.0) * 10 + 0.5) / 10,
					expires = now + M.OfferLasts,
				}
				if s.open then
					pushTo(player, { newOffer = true })
				end
			end
		end
	end
end

---------------------------------------------------------------------
-- Start
---------------------------------------------------------------------
function Market.start(remotes: Instance)
	local call = Instance.new("RemoteFunction")
	call.Name = "MarketCall"
	call.Parent = remotes
	local ev = Instance.new("RemoteEvent")
	ev.Name = "MarketPush"
	ev.Parent = remotes
	push = ev

	call.OnServerInvoke = function(player: Player, action: any, args: any)
		if type(action) ~= "string" then
			return { ok = false }
		end
		local s = session(player)
		if action == "open" or action == "close" then
			s.open = action == "open"
			return { ok = true, state = if s.open then state(player) else nil }
		end
		local fn = ACTIONS[action]
		local d = dataOf(player)
		if not fn or not d then
			return { ok = false, msg = "Market not ready" }
		end
		local ok, res = pcall(fn, player, d, args)
		if not ok then
			warn("[CityLegends] market", action, res)
			return { ok = false, msg = "Something went wrong" }
		end
		local r = res :: Result
		if r.ok and action ~= "pass" then
			task.spawn(PlayerData.save, player)
		end
		return { ok = r.ok, msg = r.msg, state = state(player) }
	end

	Players.PlayerRemoving:Connect(function(player)
		sessions[player] = nil
	end)

	task.spawn(function()
		local nextNews = os.clock() + rng:NextNumber(M.NewsEvery[1], M.NewsEvery[2])
		local nextTick = os.clock() + M.TickSeconds
		while true do
			task.wait(1)
			local now = os.clock()
			if now >= nextNews then
				nextNews = now + rng:NextNumber(M.NewsEvery[1], M.NewsEvery[2])
				makeNews()
			end
			if now >= nextTick then
				nextTick = now + M.TickSeconds
				tick()
			end
			offers()
		end
	end)
end

-- for tests
Market._step = tick
Market._news = makeNews
Market._price = price
Market._base = base

return Market
