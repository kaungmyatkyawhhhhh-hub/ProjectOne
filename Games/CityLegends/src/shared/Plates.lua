--[[
	Plates (shared, 19 Nov 2026, owner: "add license plates like the real myanmar. its like the 9E-9999
	is expensive and 3Q-3152 (random letters & numbers) are cheap").
	Research: vault "City Legends/2026-11-19 Research - Myanmar license plates.md".

	Real Yangon plate (2021 format): black plate, white letters, top line "YGN-38" (region + township),
	big middle line "5T-1648". Taxis / hire / buses: red plate, doubled letters "HH-7891".
	Owner rules (19 Nov): prefix digit 1-9 (never 0), number 1000-9999 (never starts with 0).
	Letters: I and O are left out (unconfirmed in the research; they read as 1 and 0).

	  Plates.valid("9E-9999")        -> true (private plates only)
	  Plates.roll(rng)               -> a random private plate
	  Plates.taxi(rng)               -> a random taxi / hire plate ("AA".."HH")
	  Plates.price("9E-9999")        -> cash price at the Plate Office, { "why" lines }
	  Plates.draw(parent, text, kind)-> draws the plate (kind "taxi" = red) into a SurfaceGui / Frame
	  Plates.selfTest()              -> asserts (10,000 rolls valid, price checks)
]]

local Plates = {}

Plates.LETTERS = "ABCDEFGHJKLMNPQRSTUVWXYZ" -- (no I, no O)
Plates.TAXI = "ABCDEFGH" -- AA..HH (the real taxi series has reached HH)
Plates.EVENT = { GGFEST26 = true } -- event plates (Customs looks) that still show

Plates.ROLL_COST = 3000 -- a new random plate from the menu
Plates.BASE = 25000 -- choosing your own number at the office (no pattern)
Plates.SELL_SHARE = 0.5 -- selling a plate back pays half of what you paid
Plates.BAG_MAX = 20 -- bought plates one player can own (free ones on cars don't count)

local PRIVATE = "^([1-9])([" .. Plates.LETTERS .. "])%-([1-9]%d%d%d)$"

function Plates.parse(text: any): (number?, string?, string?)
	if type(text) ~= "string" then
		return nil
	end
	local p, l, n = string.match(text, PRIVATE)
	if not p then
		return nil
	end
	return tonumber(p), l, n
end

function Plates.valid(text: any): boolean
	return Plates.parse(text) ~= nil
end

-- "9e 9999" / "9E9999" -> "9E-9999" (nil if it can't be a plate)
function Plates.normalize(text: any): string?
	if type(text) ~= "string" then
		return nil
	end
	local t = string.upper(text):gsub("[^%w]", "")
	local p, l, n = string.match(t, "^(%d)(%a)(%d%d%d%d)$")
	if not p then
		return nil
	end
	local out = p .. l .. "-" .. n
	return if Plates.valid(out) then out else nil
end

function Plates.roll(rng: Random): string
	local k = rng:NextInteger(1, #Plates.LETTERS)
	return string.format("%d%s-%d", rng:NextInteger(1, 9), Plates.LETTERS:sub(k, k), rng:NextInteger(1000, 9999))
end

function Plates.taxi(rng: Random): string
	local k = rng:NextInteger(1, #Plates.TAXI)
	local l = Plates.TAXI:sub(k, k)
	return string.format("%s%s-%d", l, l, rng:NextInteger(1000, 9999))
end

-- the township number on the top line ("YGN-38"): fixed per plate, 1-45 like Yangon's townships
function Plates.township(text: string): number
	local h = 0
	for i = 1, #text do
		h = (h * 31 + string.byte(text, i)) % 9973
	end
	return h % 45 + 1
end

---------------------------------------------------------------------
-- Price by pattern (cash only). Ordinary vanity plates ~$50k-$500k; the top (9E-9999) ~$3.5M, above
-- the best Local car ($1.8M, economy proposal 19 Nov). Lucky digits: 9 (Burmese), 8 (Chinese).
---------------------------------------------------------------------
local LUCK = { [8] = 1.5, [9] = 3 }

local function round2(v: number): number
	local mag = 10 ^ math.max(0, math.floor(math.log10(v)) - 1)
	return math.floor(v / mag + 0.5) * mag
end

function Plates.price(text: string): (number?, { string })
	local p, l, n = Plates.parse(text)
	if not p then
		return nil, {}
	end
	local d = { tonumber(n:sub(1, 1)), tonumber(n:sub(2, 2)), tonumber(n:sub(3, 3)), tonumber(n:sub(4, 4)) }
	local num = tonumber(n) :: number
	local why: { string } = {}
	local v = Plates.BASE
	local function add(amount: number, line: string)
		v += amount
		table.insert(why, line)
	end
	local same4 = d[1] == d[2] and d[2] == d[3] and d[3] == d[4]
	if same4 then
		add(400000 * (LUCK[d[1]] or 1), string.format("four %ds", d[1]))
	elseif num % 1000 == 0 then
		add(150000 * (LUCK[d[1]] or 1), "round thousand")
	else
		local up, down = true, true
		for i = 2, 4 do
			up = up and d[i] == d[i - 1] + 1
			down = down and d[i] == d[i - 1] - 1
		end
		if up or down then
			add(250000, "sequence " .. n)
		end
		if d[1] == d[2] and d[2] == d[3] then
			add(70000 * (LUCK[d[1]] or 1), string.format("three %ds", d[1]))
		elseif d[2] == d[3] and d[3] == d[4] then
			add(70000 * (LUCK[d[2]] or 1), string.format("three %ds", d[2]))
		elseif num % 100 == 0 then
			add(40000, "round hundred")
		end
		if d[1] == d[4] and d[2] == d[3] and d[1] ~= d[2] then
			add(80000, "mirror number")
		elseif d[1] == d[3] and d[2] == d[4] and d[1] ~= d[2] then
			add(60000, "repeating pair")
		elseif d[1] == d[2] and d[3] == d[4] and d[1] ~= d[3] then
			add(50000, "double pairs")
		end
		local lucky = 0
		for _, x in d do
			if x == 8 or x == 9 then
				lucky += 1
			end
		end
		if lucky == 4 then
			add(150000, "only 8s and 9s")
		elseif lucky >= 2 then
			add(15000 * lucky, string.format("%d lucky 8s / 9s", lucky))
		end
	end
	if (d[1] + d[2] + d[3] + d[4]) % 9 == 0 then
		add(15000, "adds up to 9")
	end
	if same4 and p == d[1] then
		v *= 2.5
		table.insert(why, string.format("matches the %d in front", p))
	elseif p == d[1] and #why > 0 then
		v *= 1.2
		table.insert(why, string.format("starts with its %d series", p))
	end
	if (p == 9 or p == 8) and #why > 0 then
		v *= 1.15
		table.insert(why, string.format("lucky %d series", p))
	end
	if #why == 0 then
		table.insert(why, "your own pick")
	end
	return round2(v), why
end

---------------------------------------------------------------------
-- Fancy plate ideas for the office list (any series; the server checks who holds them)
---------------------------------------------------------------------
function Plates.ideas(rng: Random, count: number): { string }
	local out, seen = {}, {}
	local function put(t: string)
		if not seen[t] and Plates.valid(t) then
			seen[t] = true
			table.insert(out, t)
		end
	end
	local tries = 0
	while #out < count and tries < 200 do
		tries += 1
		local p = rng:NextInteger(1, 9)
		local k = rng:NextInteger(1, #Plates.LETTERS)
		local l = Plates.LETTERS:sub(k, k)
		local kind = rng:NextInteger(1, 6)
		local x = rng:NextInteger(1, 9)
		local y = (x + rng:NextInteger(1, 8)) % 10
		local n = if kind == 1 then string.rep(tostring(x), 4)
			elseif kind == 2 then tostring(x) .. "000"
			elseif kind == 3 then ({ "1234", "2345", "3456", "4567", "5678", "6789", "9876", "8765", "7654", "6543", "5432", "4321" })[rng:NextInteger(1, 12)]
			elseif kind == 4 then tostring(x) .. tostring(y) .. tostring(y) .. tostring(x)
			elseif kind == 5 then tostring(x) .. tostring(x) .. tostring(x) .. tostring(rng:NextInteger(0, 9))
			else string.format("%d%d%d%d", rng:NextInteger(8, 9), rng:NextInteger(8, 9), rng:NextInteger(8, 9), rng:NextInteger(8, 9))
		put(p .. l .. "-" .. n)
	end
	return out
end

---------------------------------------------------------------------
-- Drawing: the real look (black / white, red for taxis), top line "YGN-nn", big number, Latin only
---------------------------------------------------------------------
local COLORS = {
	private = { bg = Color3.fromRGB(16, 16, 18), fg = Color3.fromRGB(246, 246, 242) },
	taxi = { bg = Color3.fromRGB(176, 24, 30), fg = Color3.fromRGB(250, 248, 244) },
}
local FONT = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold) -- (condensed, like the real plates)

-- draws into `parent` (a SurfaceGui or a Frame), replacing an older drawing there
function Plates.draw(parent: Instance, text: string, kind: string?)
	local old = parent:FindFirstChild("PlateDraw")
	if old then
		old:Destroy()
	end
	local real = Plates.valid(text) or string.match(text, "^(%u)%1%-[1-9]%d%d%d$") ~= nil
	local c = COLORS[if kind == "taxi" then "taxi" else "private"]
	local bg = Instance.new("Frame")
	bg.Name = "PlateDraw"
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = c.bg
	bg.BorderSizePixel = 0
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.08, 0)
	corner.Parent = bg
	-- the raised rim
	local rim = Instance.new("Frame")
	rim.AnchorPoint = Vector2.new(0.5, 0.5)
	rim.Position = UDim2.fromScale(0.5, 0.5)
	rim.Size = UDim2.new(1, -6, 1, -6)
	rim.BackgroundTransparency = 1
	rim.Parent = bg
	local rc = Instance.new("UICorner")
	rc.CornerRadius = UDim.new(0.08, 0)
	rc.Parent = rim
	local st = Instance.new("UIStroke")
	st.Color = c.fg
	st.Thickness = 2
	st.Transparency = 0.15
	st.Parent = rim
	local function line(t: string, y: number, h: number)
		local l = Instance.new("TextLabel")
		l.Name = if h > 0.5 then "Number" else "Region"
		l.BackgroundTransparency = 1
		l.Position = UDim2.fromScale(0.04, y)
		l.Size = UDim2.fromScale(0.92, h)
		l.FontFace = FONT
		l.TextScaled = true
		l.TextColor3 = c.fg
		l.Text = t
		l.Parent = bg
	end
	if real then
		line("YGN-" .. Plates.township(text), 0.06, 0.26)
		line(text, 0.3, 0.64)
	else
		line(text, 0.14, 0.72) -- an event plate (GGFEST26)
	end
	bg.Parent = parent
end

---------------------------------------------------------------------
-- Self-check (run in Studio: require(game.ReplicatedStorage.Shared.Plates).selfTest())
---------------------------------------------------------------------
function Plates.selfTest(): string
	local rng = Random.new(1)
	for _ = 1, 10000 do
		local t = Plates.roll(rng)
		assert(Plates.valid(t), "bad roll " .. t)
		local x = Plates.taxi(rng)
		assert(string.match(x, "^(%u)%1%-[1-9]%d%d%d$"), "bad taxi " .. x)
	end
	for _, bad in { "0E-9999", "9E-0999", "9E-0001", "9I-1234", "9O-1234", "9E-999", "9E9999", "99-9999", "AA-1234" } do
		assert(not Plates.valid(bad), "should be invalid " .. bad)
	end
	assert(Plates.normalize("9e 9999") == "9E-9999")
	assert(Plates.normalize("0e9999") == nil)
	for _, t in Plates.ideas(rng, 50) do
		assert(Plates.valid(t), "bad idea " .. t)
	end
	local top = Plates.price("9E-9999")
	local plain = Plates.price("3Q-3152")
	assert(plain == Plates.BASE, "plain " .. tostring(plain))
	assert(top and top >= 2000000, "top " .. tostring(top))
	assert((Plates.price("1A-1221") :: number) < 500000)
	local out = {}
	for _, t in { "9E-9999", "8E-8888", "1A-1111", "9E-9000", "5K-1234", "3Q-1221", "7M-2020", "2B-8989", "4C-7704", "3Q-3152" } do
		local v, why = Plates.price(t)
		table.insert(out, string.format("%s $%d (%s)", t, v :: number, table.concat(why, ", ")))
	end
	return "ok\n" .. table.concat(out, "\n")
end

return Plates
