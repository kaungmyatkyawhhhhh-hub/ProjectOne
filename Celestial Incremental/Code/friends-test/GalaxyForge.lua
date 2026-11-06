-- GalaxyForge (Galaxy Incremental, 5 Nov; design "Full game design" 3b; checklist #59-#62): the STAR FORGE window (hotbar F
-- or the anvil on Sector 2; opens at IGNITION 1).
--  * left: ROLL (1 Essence) and BULK x3, your Essence, the ODDS (every rarity, summing to 100%: shown before any roll), the
--    pity ("Legendary in n rolls at most")
--  * right: the 3 EQUIPPED slots and the BOOK: 6 kinds x 7 rarities = 42 cores; one you own shows its level (duplicates
--    level it, 1-10); a tap equips / unequips it (a full set replaces the first slot); one you don't is a dark "?"
--  * a roll shows its core (the rarity's colour, sparkles; Epic and up get the milestone sound)
-- Numbers: EconConfig.Forge. The server rolls (EconRequest "ForgeRoll" / "ForgeEquip"); this only draws.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local Kit = require(Galaxy:WaitForChild("UIKit"))
local Econ = require(Galaxy:WaitForChild("EconConfig"))
local request = Galaxy:WaitForChild("EconRequest") :: RemoteFunction
local hex = Kit.hex
local CENTRE = Enum.TextXAlignment.Center
local RIGHT = Enum.TextXAlignment.Right
local F = Econ.Forge
local Cutscene = require(Galaxy:WaitForChild("GalaxyCutscene"))
local Vfx = require(Galaxy:WaitForChild("VfxLibrary"))
local Art = require(Galaxy:WaitForChild("ArtIds")) -- (7 Nov: the Forge card art)
local event = Galaxy:WaitForChild("EconEvent") :: RemoteEvent

while not player:GetAttribute("Loaded") do player:GetAttributeChangedSignal("Loaded"):Wait() end

local gui = Instance.new("ScreenGui")
gui.Name = "GalaxyForge"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 3
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui
local PHONE_TEST = RunService:IsStudio() and workspace:GetAttribute("TestPhone") == true
local root: GuiObject | ScreenGui = gui
if PHONE_TEST then
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = UDim2.fromScale(0.5, 0.5)
	f.Size = UDim2.fromOffset(667, 375)
	f.BackgroundTransparency = 1
	f.ClipsDescendants = true
	f.Parent = gui
	root = f
end
-- (2.5 #158: the rarity colour ladder grey / green / blue / purple / gold / red / RAINBOW, always with its name)
local RAINBOW = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 90, 90)), ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 200, 60)),
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(120, 255, 120)), ColorSequenceKeypoint.new(0.6, Color3.fromRGB(90, 200, 255)),
	ColorSequenceKeypoint.new(0.8, Color3.fromRGB(190, 110, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 120, 230)) })
local function rainbow(main: GuiObject)
	if main:FindFirstChild("Rainbow") then return end
	if main:IsA("TextLabel") then main.TextColor3 = Color3.new(1, 1, 1) end
	local g = Instance.new("UIGradient")
	g.Name = "Rainbow"
	g.Color = RAINBOW
	g.Parent = main
end
local function viewport(): Vector2
	return if PHONE_TEST then Vector2.new(667, 375) else workspace.CurrentCamera.ViewportSize
end
local function screenScale(): number
	local vp = viewport()
	if vp.Y < 500 then return math.min(vp.X / 1000, vp.Y / 540) end
	return math.clamp(math.min(vp.X / 1280, vp.Y / 720), 0.6, 1.4)
end
local function forgeData()
	local ok, t = pcall(function() return HttpService:JSONDecode(player:GetAttribute("Forge") or "{}") end)
	t = if ok and type(t) == "table" then t else {}
	t.cores = if type(t.cores) == "table" then t.cores else {}
	t.equipped = if type(t.equipped) == "table" then t.equipped else {}
	return t
end

------------------------------------------------------------------------ the window (680 x 440)
local W, H = 680, 440
local holder = Kit.box(root, 0, 0, W, H, { Name = "ForgeWindow", AnchorPoint = Vector2.new(0.5, 0.5), Visible = false })
local scale = Instance.new("UIScale")
scale.Parent = holder
local win, closeBtn = Kit.window(holder, W, H, { title = "STAR FORGE", icon = "forge", iconGlow = Color3.fromRGB(255, 200, 70),
	c1 = hex("#7a4a0a"), c2 = hex("#ffc83a"), lip = hex("#c2840c"), glow = Color3.fromRGB(255, 170, 40), line = hex("#ffe08a") })

-- left: rolls, Essence, odds, pity
local left = Kit.panel(win, 16, 72, 262, 352, 4)
Kit.stroke(left, hex("#ffc83a"), 2, 0.2)
Kit.icon(win, "essence", 26, 76, 44, Color3.fromRGB(60, 230, 210), { ZIndex = 8 })
local essText = Kit.text(win, 74, 84, 190, 30, "0 ESSENCE", 22, { ZIndex = 8, FontFace = Kit.FONT_HEAVY, stroke = 1.8, TextColor3 = hex("#7dffe9") })
local rollBtn, rollInner = Kit.button(win, 28, 124, 238, 54, hex("#7dff7a"), hex("#1fa83a"), { ZIndex = 6 })
local rollText = Kit.text(rollInner, 0, Kit.ps(13, 11), 238, 30, "ROLL · 1", Kit.ps(20, 23), { ZIndex = rollInner.ZIndex, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 1.8 })
local rollShine = Kit.tagVfx(Kit.shine(rollBtn, 2.6))
local bulkBtn, bulkInner = Kit.button(win, 28, 186, 238, 44, hex("#5ad1ff"), hex("#1f6fd1"), { ZIndex = 6 })
local bulkText = Kit.text(bulkInner, 0, Kit.ps(9, 8), 238, 26, "BULK x" .. F.Bulk .. " · " .. F.Bulk * F.RollCost, Kit.ps(17, 20), { ZIndex = bulkInner.ZIndex, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 1.6 })
-- (2.5: the ODDS shown are the ones your next roll uses: your Luck cores, FORGE LUCK, FORGE MASTER, and maxed cores
-- moved up the ladder; always summing to 100%)
Kit.text(win, 30, 238, 230, 22, "ODDS (YOUR NEXT ROLL)", 18, { ZIndex = 8, FontFace = Kit.FONT_HEAVY, stroke = 1.5, TextColor3 = hex("#ffe08a") })
local oddsText = {}
for i, r in ipairs(F.Rarities) do
	local y = 260 + (i - 1) * 20
	local name = Kit.text(win, 30, y, 150, 20, r.name, Kit.ps(13, 15), { ZIndex = 8, TextColor3 = r.colour, stroke = 1.2, FontFace = Kit.FONT_HEAVY })
	if r.id == "Celestial" then rainbow(name) end
	oddsText[i] = Kit.text(win, 160, y, 100, 20, r.odds .. "%", Kit.ps(13, 15), { ZIndex = 8, TextXAlignment = RIGHT, stroke = 1.2 })
end
local function luckNow(d): number
	return Econ.ForgeEffect(d.equipped, d.cores, "Luck") * (if (player:GetAttribute("R2_ForgeLuck") or 0) >= 1 then 1.1 else 1)
		* (if player:GetAttribute("Capstone") == "ForgeMaster" then 1.25 else 1)
end
local function pctText(p: number): string
	if p >= 10 then return string.format("%.0f%%", p) end
	if p >= 0.1 then return (string.format("%.2f", p):gsub("0+$", ""):gsub("%.$", "")) .. "%" end
	return (string.format("%.3f", p):gsub("0+$", ""):gsub("%.$", "")) .. "%"
end
local pityText = Kit.text(win, 30, 402, 236, 18, "", Kit.ps(11, 13), { ZIndex = 8, TextColor3 = hex("#a99fb8"), stroke = 1 })

-- right: equipped + the book
local right = Kit.panel(win, 290, 72, 374, 352, 4)
Kit.stroke(right, hex("#ffc83a"), 2, 0.2)
Kit.text(win, 304, 80, 200, 24, "EQUIPPED", 18, { ZIndex = 8, FontFace = Kit.FONT_HEAVY, stroke = 1.5, TextColor3 = hex("#ffe08a") })
local slots = {}
for i = 1, F.Slots do
	local x = 304 + (i - 1) * 118
	local s = Kit.box(win, x, 106, 110, 64, { BackgroundTransparency = 0, BackgroundColor3 = hex("#130f1e"), ZIndex = 6 })
	Kit.corner(s, 8)
	local st = Kit.stroke(s, hex("#4b4170"), 2.5, 0.2)
	local icon = Kit.icon(win, "stardust", x + 2, 108, 44, nil, { ZIndex = 8 })
	local name = Kit.text(win, x + 46, 112, 62, 18, "", Kit.ps(11, 13), { ZIndex = 8, FontFace = Kit.FONT_HEAVY, stroke = 1.2 })
	local val = Kit.text(win, x + 46, 132, 62, 22, "", Kit.ps(15, 17), { ZIndex = 8, FontFace = Kit.FONT_HEAVY, stroke = 1.4, TextColor3 = hex("#7dff6b") })
	local empty = Kit.text(win, x, 126, 110, 24, "EMPTY", 15, { ZIndex = 8, TextXAlignment = CENTRE, TextColor3 = hex("#8a8296"), stroke = 1.2 })
	slots[i] = { st = st, icon = icon, name = name, val = val, empty = empty }
end
Kit.text(win, 304, 174, 200, 22, "BOOK", 18, { ZIndex = 8, FontFace = Kit.FONT_HEAVY, stroke = 1.5, TextColor3 = hex("#ffe08a") })
local bookCount = Kit.text(win, 400, 174, 250, 22, "0/42", 16, { ZIndex = 8, TextXAlignment = RIGHT, stroke = 1.3 })
local tiles = {}
-- (2.5: 6 rows + the % row under them fit the panel: 198 + 5 x 33 + 30 = 393, the % row at 397)
local TS, PITCH = 30, 33
local rowPct, rowTrim = {}, {}
for ri, r in ipairs(F.Rarities) do
	local x = 334 + (ri - 1) * PITCH
	-- (a complete row = a gold trim round its column: the "card trim" reward)
	local trim = Kit.box(win, x - 2, 196, TS + 4, 5 * PITCH + TS + 4, { ZIndex = 5, Visible = false })
	Kit.corner(trim, 8)
	Kit.stroke(trim, hex("#ffd84a"), 2.5)
	rowTrim[r.id] = trim
	local pct = Kit.text(win, x - 6, 398, TS + 12, 18, "0%", Kit.ps(11, 13), { ZIndex = 8, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 1.2, TextColor3 = r.colour })
	if r.id == "Celestial" then rainbow(pct) end
	rowPct[r.id] = pct
end
for ki, kind in ipairs(F.Kinds) do
	for ri, r in ipairs(F.Rarities) do
		local x, y = 334 + (ri - 1) * PITCH, 198 + (ki - 1) * PITCH
		local t = Kit.box(win, x, y, TS, TS, { BackgroundTransparency = 0, BackgroundColor3 = hex("#130f1e"), ZIndex = 6 })
		Kit.corner(t, 7)
		local st = Kit.stroke(t, r.colour, 2, 0.6)
		local icon = Kit.icon(win, kind.icon, x + 2, y + 1, 26, nil, { ZIndex = 8 })
		local lv = Kit.text(win, x, y + 15, TS - 3, 15, "", 12, { ZIndex = 9, TextXAlignment = RIGHT, FontFace = Kit.FONT_HEAVY, stroke = 1.4 })
		local q = Kit.text(win, x, y + 4, TS, 22, "?", 16, { ZIndex = 9, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, TextColor3 = hex("#5a5562"), stroke = 1 })
		local hit = Kit.new("TextButton", { Text = "", BackgroundTransparency = 1, AutoButtonColor = false, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(TS, TS), ZIndex = 10 }, win)
		local key = kind.id .. ":" .. r.id
		hit.MouseButton1Click:Connect(function()
			local ok = request:InvokeServer("ForgeEquip", key)
			Kit.sound(if ok then "click" else "error")
		end)
		-- (c1, 6 Nov: a core you just found for the first time GLOWS in the book until you've seen it: the window closes)
		local glow = Kit.box(win, x - 3, y - 3, TS + 6, TS + 6, { ZIndex = 7, Visible = false })
		Kit.corner(glow, 9)
		local gst = Kit.stroke(glow, hex("#fff1a8"), 3, 0)
		if not Kit.calm() then Kit.tween(gst, { Transparency = 0.7 }, 0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true) end
		local tag = Kit.text(win, x - 6, y - 10, TS + 12, 14, "NEW", 11, { ZIndex = 11, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 1.3,
			TextColor3 = hex("#fff1a8") })
		tag.Parent.Visible = false
		tiles[key] = { t = t, st = st, icon = icon, lv = lv, q = q, glow = glow, tag = tag }
	end
	Kit.icon(win, kind.icon, 302, 198 + (ki - 1) * PITCH + 1, 26, nil, { ZIndex = 8 })
end

local function shown(main: GuiObject, on: boolean) main.Parent.Visible = on end
local fresh = {} -- [key] = true: cores found for the first time, not seen in the book yet
local function refresh()
	local ess = player:GetAttribute("Essence") or 0
	Kit.setText(essText, Econ.Format(ess) .. " ESSENCE")
	local can = ess >= F.RollCost
	Kit.recolour(rollBtn, if can then hex("#7dff7a") else hex("#6a6474"), if can then hex("#1fa83a") else hex("#3f3a48"))
	rollShine.Visible = can
	Kit.setText(rollText, "ROLL · " .. F.RollCost)
	local canBulk = ess >= (player:GetAttribute("BulkSize") or F.Bulk) * F.RollCost
	Kit.recolour(bulkBtn, if canBulk then hex("#5ad1ff") else hex("#6a6474"), if canBulk then hex("#1f6fd1") else hex("#3f3a48"))
	local d = forgeData()
	local bulk = player:GetAttribute("BulkSize") or F.Bulk
	Kit.setText(bulkText, "BULK x" .. bulk .. " · " .. bulk * F.RollCost)
	local odds = Econ.ForgeOdds(d.cores, luckNow(d))
	for i, t in ipairs(oddsText) do Kit.setText(t, pctText(odds[i])) end
	Kit.setText(pityText, "Legendary in " .. math.max(1, F.PityLegendary - (tonumber(d.pityL) or 0)) .. " rolls at most · Mythic in " .. math.max(1, F.PityMythic - (tonumber(d.pityM) or 0)))
	local owned = 0
	for key, t in pairs(tiles) do
		local lv = d.cores[key]
		local have = lv ~= nil
		if have then owned += 1 end
		t.icon.ImageColor3 = if have then Color3.new(1, 1, 1) else Color3.new(0, 0, 0)
		t.icon.ImageTransparency = if have then 0 else 0.4
		shown(t.q, not have)
		shown(t.lv, have)
		-- (a core at MAX has left the pool: "M" in gold)
		Kit.setText(t.lv, if have then (if lv >= F.MaxLevel then "M" else tostring(lv)) else "")
		t.lv.TextColor3 = if have and lv >= F.MaxLevel then hex("#ffd84a") else Color3.new(1, 1, 1)
		local eq = table.find(d.equipped, key) ~= nil
		t.st.Thickness = if eq then 3.5 else 2
		t.st.Transparency = if eq then 0 elseif have then 0.2 else 0.65
		t.st.Color = if eq then Color3.new(1, 1, 1) else Econ.ForgeRarityById[string.match(key, ":(%a+)$")].colour
		t.glow.Visible = fresh[key] == true
		t.tag.Parent.Visible = fresh[key] == true
	end
	-- (2.5: % complete in total and per rarity; a complete row has its gold trim; the COLLECTOR title)
	local total = #F.Kinds * #F.Rarities
	local title = player:GetAttribute("CollectorTitle") or ""
	Kit.setText(bookCount, owned .. "/" .. total .. " · " .. math.floor(owned / total * 100) .. "%" .. (if title ~= "" then " · " .. title else ""))
	for _, r in ipairs(F.Rarities) do
		local n = 0
		for _, k in ipairs(F.Kinds) do if d.cores[k.id .. ":" .. r.id] then n += 1 end end
		Kit.setText(rowPct[r.id], math.floor(n / #F.Kinds * 100) .. "%")
		rowTrim[r.id].Visible = (d.done or {})[r.id] == true
	end
	for i, s in ipairs(slots) do
		local key = d.equipped[i]
		local k, r
		if key then k, r = string.match(key, "^(%a+):(%a+)$") end
		s.icon.Parent.Visible = key ~= nil
		shown(s.name, key ~= nil)
		shown(s.val, key ~= nil)
		shown(s.empty, key == nil)
		if key and k and r then
			local kind, rar = Econ.ForgeKindById[k], Econ.ForgeRarityById[r]
			for _, c in ipairs(s.icon.Parent:GetChildren()) do
				if c:IsA("ImageLabel") and (c.Name == "Icon" or c.Name == "Shadow") then c.Image = Kit.A.icon[kind.icon] or "" end
			end
			Kit.setText(s.name, rar.name)
			s.name.TextColor3 = rar.colour
			Kit.setText(s.val, Econ.CoreText(k, r, d.cores[key] or 1))
			s.st.Color = rar.colour
		else
			s.st.Color = hex("#4b4170")
		end
	end
end
for _, a in ipairs({ "Essence", "Forge", "BulkSize", "CollectorTitle", "Capstone", "R2_ForgeLuck" }) do
	player:GetAttributeChangedSignal(a):Connect(function() if holder.Visible then refresh() end end)
end

------------------------------------------------------------------------ the roll's reveal
local reveal = Kit.box(win, 0, 0, W, H, { Visible = false, ZIndex = 40 })
-- (7 Nov, new UI art: the window dims behind the CARD; the card = galaxy_card_<rarity>_full (ArtIds.ui.card), the core in
-- its dark window, the core's NAME in its bottom banner (Luckiest Guy). It shows its BACK first, then flips (0.25 s))
local revealBg = Kit.box(reveal, 0, 0, W, H, { BackgroundTransparency = 0.08, BackgroundColor3 = hex("#07050c"), ZIndex = 41 })
Kit.corner(revealBg, 12)
local CARD_W, CARD_H, CARD_X, CARD_Y = 232, 318, 200, 226 -- (the card's size + its centre in the window; the art is ~0.73 wide)
local cardHolder = Kit.new("Frame", { Name = "Card", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromOffset(CARD_X, CARD_Y), Size = UDim2.fromOffset(CARD_W, CARD_H), ZIndex = 42 }, reveal)
local cardImg = Kit.new("ImageLabel", { Name = "Art", BackgroundTransparency = 1, Image = Art.ui.cardBack, ScaleType = Enum.ScaleType.Fit,
	Size = UDim2.fromScale(1, 1), ZIndex = 42 }, cardHolder)
-- (the core in the card's dark window: its middle sits at ~44% of the card's height)
local cardShadow = Kit.new("ImageLabel", { Name = "Shadow", BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.44, 4), Size = UDim2.fromScale(0.56, 0.4), ImageColor3 = Color3.new(0, 0, 0), ImageTransparency = 0.4, ZIndex = 43 }, cardHolder)
local cardIcon = Kit.new("ImageLabel", { Name = "Icon", BackgroundTransparency = 1, ScaleType = Enum.ScaleType.Fit, AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.44), Size = UDim2.fromScale(0.56, 0.4), ZIndex = 44 }, cardHolder)
local cardName = Kit.new("TextLabel", { Name = "CoreName", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.845), Size = UDim2.fromScale(0.62, 0.065), FontFace = Font.fromEnum(Enum.Font.LuckiestGuy), Text = "",
	TextColor3 = Color3.new(1, 1, 1), TextScaled = true, ZIndex = 45 }, cardHolder)
Kit.stroke(cardName, hex("#1a0e28"), 2)
local revealRarity = Kit.text(reveal, 340, 136, 320, 40, "", 34, { ZIndex = 44, FontFace = Kit.FONT_HEAVY, stroke = 2.4 })
local revealName = Kit.text(reveal, 342, 182, 320, 26, "", 20, { ZIndex = 44, FontFace = Kit.FONT_HEAVY, stroke = 1.6 })
local revealVal = Kit.text(reveal, 342, 214, 320, 30, "", 26, { ZIndex = 44, FontFace = Kit.FONT_HEAVY, stroke = 1.8, TextColor3 = hex("#7dff6b") })
local revealMore = Kit.text(reveal, 342, 252, 320, 22, "", 15, { ZIndex = 44, TextColor3 = hex("#a99fb8"), stroke = 1.1 })
-- the card flip: the back shows, it turns edge-on, the rarity card turns back to face you (0.25 s; Reduced Motion: a swap)
local function flipCard(art: string, front: () -> ())
	cardIcon.Visible, cardShadow.Visible, cardName.Visible = false, false, false
	if Kit.calm() then
		cardImg.Image = art
		front()
		return
	end
	cardImg.Image = Art.ui.cardBack
	cardHolder.Size = UDim2.fromOffset(CARD_W, CARD_H)
	Kit.tween(cardHolder, { Size = UDim2.fromOffset(0, CARD_H) }, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	task.delay(0.12, function()
		cardImg.Image = art
		front()
		Kit.tween(cardHolder, { Size = UDim2.fromOffset(CARD_W, CARD_H) }, 0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end)
end
-- (c1: the NEW CORE! pop, above the rarity in the text column (7 Nov: it sat on the rarity before))
local newPop = Kit.box(reveal, 0, 0, 320, 44, { ZIndex = 47, Visible = false, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(500, 108) })
local newScale = Kit.new("UIScale", { Scale = 1 }, newPop)
local newText = Kit.text(newPop, 0, 0, 320, 44, "NEW CORE!", 34, { ZIndex = 48, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 2.6,
	gradient = ColorSequence.new(hex("#fff1c0"), hex("#ffb02a")) })
local revealHit = Kit.new("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 45 }, reveal)
revealHit.MouseButton1Click:Connect(function() reveal.Visible = false end)
local function showRoll(results, newOnes)
	-- the best of the results gets the card; the rest are listed under it
	local best, bestI = nil, 0
	for _, key in ipairs(results) do
		local r = string.match(key, ":(%a+)$")
		local i = Econ.ForgeRarityById[r].index
		if i > bestI then best, bestI = key, i end
	end
	if not best then return end
	local k, r = string.match(best, "^(%a+):(%a+)$")
	local kind, rar = Econ.ForgeKindById[k], Econ.ForgeRarityById[r]
	local d = forgeData()
	-- (the card: its back, then the flip to this rarity's card with the core + its name)
	cardIcon.Image = Kit.A.icon[kind.icon] or ""
	cardShadow.Image = cardIcon.Image
	cardName.Text = kind.name
	flipCard(Art.ui.card[r] or Art.ui.card.Common, function()
		cardIcon.Visible, cardShadow.Visible, cardName.Visible = true, true, true
	end)
	Kit.setText(revealRarity, rar.name)
	revealRarity.TextColor3 = rar.colour
	Kit.setText(revealName, kind.name .. " · LV " .. (d.cores[best] or 1))
	Kit.setText(revealVal, Econ.CoreText(k, r, d.cores[best] or 1) .. "  " .. kind.desc:gsub(" x$", ""):gsub("^%+%% ", ""))
	local others = {}
	for _, key in ipairs(results) do if key ~= best then table.insert(others, (string.match(key, ":(%a+)$"))) end end
	Kit.setText(revealMore, if #others > 0 then "+ " .. table.concat(others, ", ") else "Tap to close")
	reveal.Visible = true
	-- (c1, 6 Nov: the NEW CORE! moment: a gold pop over the card + a bright chime; "NEW CORES x3!" when a bulk found several)
	local nNew = 0
	for _ in pairs(newOnes or {}) do nNew += 1 end
	newPop.Visible = nNew > 0
	if nNew > 0 then
		Kit.setText(newText, if nNew > 1 then "NEW CORES x" .. nNew .. "!" else "NEW CORE!")
		newScale.Scale = if Kit.calm() then 1 else 0.3
		if not Kit.calm() then
			Kit.tween(newScale, { Scale = 1 }, 0.35, Enum.EasingStyle.Back)
			Vfx.UiPop(reveal, "starburst_twinkle", UDim2.fromOffset(W / 2, 128), 140, 0.6, hex("#fff1a8"), 43)
		end
		task.delay(0.12, function() Kit.sound("buyBody", { pitch = 1.5, volume = 0.8 }) end)
	end
	if r == "Celestial" then rainbow(revealRarity) else
		local g = revealRarity:FindFirstChild("Rainbow")
		if g then g:Destroy() end
	end
	for i = 1, (if bestI >= 4 then 14 else 6) do
		local s = Kit.sparkle(reveal, math.random(130, W - 140), math.random(110, 320), math.random(10, 20), i * 0.05)
		s.ImageColor3 = rar.colour
		task.delay(2, function() s:Destroy() end)
	end
	-- (2.5 #289 + the VFX pass: the card's ladder from VfxLibrary: the hammer hit every roll; Uncommon + the rarity's aura;
	-- Rare + a ring; Epic + rays; Legendary + confetti + a starburst; Celestial + the supernova flash. Reduced Motion: the hit only)
	Vfx.UiForgeReveal(reveal, bestI, rar.colour, UDim2.fromOffset(CARD_X, CARD_Y), 41)
	-- (#247: the SOUND ladder: pop, chime, a rising arpeggio, a whoosh + chime, then a held silence + the big stinger)
	if bestI <= 1 then Kit.sound("piecePop")
	elseif bestI == 2 then Kit.sound("cometCatch")
	elseif bestI == 3 then
		for k = 0, 2 do task.delay(k * 0.09, function() Kit.sound("buyBody", { pitch = 1 + k * 0.26, volume = 0.7 }) end) end
	elseif bestI == 4 then
		Kit.sound("cometAppear", { volume = 0.6 })
		task.delay(0.25, function() Kit.sound("milestone") end)
	else
		task.delay(0.35, function()
			Kit.sound("boom", { volume = 0.7 })
			Kit.sound("milestone")
		end)
	end
end
-- the anvil to show a roll on: the one nearest to you (the plaza's Star Forge, or Sector 2's); returns (model, its top)
local function nearestAnvil(): (Instance?, Vector3?)
	local root = workspace:FindFirstChild("Galaxy")
	local char = player.Character
	local me = char and char:FindFirstChild("HumanoidRootPart")
	local best, bestTop, bestD = nil, nil, math.huge
	for _, path in ipairs({ { "Centre", "StarForge" }, { "NextSector", "SectorForge" } }) do
		local f = root and root:FindFirstChild(path[1])
		f = f and f:FindFirstChild(path[2])
		local a = f and f:FindFirstChild("Anvil")
		if a and (a:IsA("Model") or a:IsA("BasePart")) then
			local cf, size = if a:IsA("Model") then a:GetBoundingBox() else a.CFrame, a.Size
			local top = cf.Position + Vector3.new(0, size.Y / 2, 0)
			local d = if me and me:IsA("BasePart") then (me.Position - top).Magnitude else 0
			if d < bestD then best, bestTop, bestD = a, top, d end
		end
	end
	return best, bestTop
end
local rolling = false
local function roll(n: number)
	if rolling then return end
	rolling = true
	local before = forgeData().cores
	local ok, results = request:InvokeServer("ForgeRoll", n)
	rolling = false
	if not ok then Kit.sound("error") return end
	-- (c1: the cores that are NEW to your book: they glow there, and the card says NEW CORE!)
	local newOnes = {}
	for _, key in ipairs(results) do
		if not before[key] and not newOnes[key] then newOnes[key] = true fresh[key] = true end
	end
	-- (cutscene template, 5 Nov: the length grows with the best rarity: Common / Uncommon instant, Rare 3 s, Epic 5 s,
	-- Legendary 8 s, Mythic 12 s, Celestial 18 s; the card shows at the climax. A Celestial is told to the whole server.)
	local bestI, bestKey = 0, nil
	for _, key in ipairs(results) do
		local i = Econ.ForgeRarityById[string.match(key, ":(%a+)$")].index
		if i > bestI then bestI, bestKey = i, key end
	end
	local LEN = { [3] = 3, [4] = 5, [5] = 8, [6] = 12, [7] = 18 }
	local anvil, top = nearestAnvil()
	local rar0 = bestKey and Econ.ForgeRarityById[string.match(bestKey, ":(%a+)$")]
	if LEN[bestI] and Cutscene and not Cutscene.busy() then
		local k, r = string.match(bestKey, "^(%a+):(%a+)$")
		local rar, kind = Econ.ForgeRarityById[r], Econ.ForgeKindById[k]
		holder.Visible = false
		-- (the VFX pass (b): the STAR FORGE / ANVIL ladder in the world: the camera goes to the anvil; 1. the STRIKE, 2. the
		-- BUILD-UP for the whole length (the rune circle, arcs, stardust pulled in), 3. the REVEAL on the climax; the reward is
		-- given on the climax and SKIP (after 1 s) jumps to it, #318)
		local build
		local cam
		if top then
			local look = anvil:GetPivot().LookVector
			local side = Vector3.new(look.X, 0, look.Z)
			side = if side.Magnitude > 0.1 then side.Unit else Vector3.new(0, 0, 1)
			cam = function(t: number)
				local a = t * 0.7
				local dir = (CFrame.Angles(0, a, 0) * CFrame.new(side)).Position
				local dist = 19 - 6 * t
				local pos = top + dir * dist + Vector3.new(0, 6 - 2 * t, 0)
				return CFrame.lookAt(pos, top + Vector3.new(0, 2, 0)), top
			end
			Vfx.ForgeStrike(top, true)
			build = Vfx.ForgeBuild(top, rar.colour, LEN[bestI])
		end
		Cutscene.play({ colour = rar.colour, symbol = Kit.A.icon[kind.icon], length = LEN[bestI], drop = LEN[bestI] * 0.8,
			words = if bestI >= 5 then { "THE FORGE", "SPEAKS" } else nil, title = rar.name .. "!", sub = kind.name, camera = cam, world = top ~= nil,
			onClimax = function()
				refresh()
				if build then build:Stop() end
				if not top then return end
				if bestI >= 7 then
					-- (Celestial: the sky turns, a star falls onto the anvil, then the reveal)
					Vfx.SkyTurn(3)
					Vfx.FallingStar(top, rar.colour, 0.35, function() Vfx.ForgeReveal(top, bestI, rar.colour, true, anvil, true) end)
				else
					Vfx.ForgeReveal(top, bestI, rar.colour, true, anvil, true)
				end
			end })
		holder.Visible = true -- (the window was open: the roll came from its buttons)
	elseif top and rar0 then
		-- (Common / Uncommon: no cutscene; the strike + the small reveal at the anvil, seen if you're near it)
		Vfx.ForgeStrike(top)
		task.delay(0.15, function() Vfx.ForgeReveal(top, bestI, rar0.colour, false, anvil) end)
	end
	task.defer(function()
		refresh()
		showRoll(results, newOnes)
	end)
end
rollBtn.MouseButton1Click:Connect(function() roll(1) end)
bulkBtn.MouseButton1Click:Connect(function() roll(F.Bulk) end)
-- (a book row completed: its COLLECTOR title + the trim)
event.OnClientEvent:Connect(function(kind, rarity)
	if kind ~= "ForgeRowDone" then return end
	local r = Econ.ForgeRarityById[rarity]
	if not r then return end
	Kit.sound("milestone")
	if shared.GalaxyToast then shared.GalaxyToast("BOOK ROW DONE: " .. Econ.CollectorTitles[rarity] .. "!", r.colour) end
	if holder.Visible then refresh() end
end)

------------------------------------------------------------------------ open / close (a side window, key "F")
local isOpen = false
local function place()
	local s = screenScale()
	local vp = viewport()
	local small = vp.Y < 500
	local top = 124 * s -- (6 Nov overlap check: under the GALAXY LIT bar + the counter's SUPERNOVA bar)
	local room = (if small then vp.Y - 6 else vp.Y - 104 * s) - top
	local want = math.min(Kit.ps(s, 0.85), room / (H + Kit.ps(34, 6)), (vp.X - Kit.ps(24, 8)) / (W + 40))
	holder.Position = UDim2.fromOffset(vp.X / 2, top + room / 2 + 15 * want)
	return want
end
local function close()
	if not isOpen then return end
	isOpen = false
	table.clear(fresh) -- (the new cores' glow has been seen)
	Kit.sound("close")
	Kit.tween(scale, { Scale = scale.Scale * 0.85 }, 0.15)
	task.delay(0.15, function() if not isOpen then holder.Visible = false end end)
	if shared.GalaxySideWindow then shared.GalaxySideWindow("F", false) end
end
local cardsLoaded = false
local function open()
	if isOpen then return end
	-- (7 Nov: the card art loads the first time the Forge opens, so the first roll's flip doesn't show an empty card)
	if not cardsLoaded then
		cardsLoaded = true
		for _, id in ipairs({ Art.ui.cardBack, Art.ui.card.Common, Art.ui.card.Uncommon, Art.ui.card.Rare, Art.ui.card.Epic,
			Art.ui.card.Legendary, Art.ui.card.Mythic, Art.ui.card.Celestial }) do
			Kit.new("ImageLabel", { Name = "Preload", BackgroundTransparency = 1, Image = id, ImageTransparency = 0.99, Size = UDim2.fromOffset(2, 2), ZIndex = 1 }, win)
		end
	end
	if shared.GalaxyCloseSide then shared.GalaxyCloseSide("F") end
	isOpen = true
	Kit.sound("open")
	reveal.Visible = false
	refresh()
	holder.Visible = true
	if shared.GalaxySideWindow then shared.GalaxySideWindow("F", true) end
	local want = place()
	scale.Scale = want * 0.8
	Kit.tween(scale, { Scale = want }, 0.25, Enum.EasingStyle.Back)
end
shared.GalaxyForgeToggle = function() if isOpen then close() else open() end end
shared.GalaxyForgeClose = close
closeBtn.MouseButton1Click:Connect(close)
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() if isOpen then scale.Scale = place() end end)
local _ = CENTRE
