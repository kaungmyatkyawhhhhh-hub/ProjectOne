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
Kit.text(bulkInner, 0, Kit.ps(9, 8), 238, 26, "BULK x" .. F.Bulk .. " · " .. F.Bulk * F.RollCost, Kit.ps(17, 20), { ZIndex = bulkInner.ZIndex, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 1.6 })
Kit.text(win, 30, 238, 230, 22, "ODDS", 18, { ZIndex = 8, FontFace = Kit.FONT_HEAVY, stroke = 1.5, TextColor3 = hex("#ffe08a") })
for i, r in ipairs(F.Rarities) do
	local y = 260 + (i - 1) * 20
	Kit.text(win, 30, y, 150, 20, r.name, Kit.ps(13, 15), { ZIndex = 8, TextColor3 = r.colour, stroke = 1.2, FontFace = Kit.FONT_HEAVY })
	Kit.text(win, 160, y, 100, 20, r.odds .. "%", Kit.ps(13, 15), { ZIndex = 8, TextXAlignment = RIGHT, stroke = 1.2 })
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
local bookCount = Kit.text(win, 470, 174, 180, 22, "0/42", 16, { ZIndex = 8, TextXAlignment = RIGHT, stroke = 1.3 })
local tiles = {}
local TS, PITCH = 34, 38 -- (6 rows fit the panel: 198 + 5 x 38 + 34 = 422)
for ki, kind in ipairs(F.Kinds) do
	for ri, r in ipairs(F.Rarities) do
		local x, y = 334 + (ri - 1) * PITCH, 198 + (ki - 1) * PITCH
		local t = Kit.box(win, x, y, TS, TS, { BackgroundTransparency = 0, BackgroundColor3 = hex("#130f1e"), ZIndex = 6 })
		Kit.corner(t, 7)
		local st = Kit.stroke(t, r.colour, 2, 0.6)
		local icon = Kit.icon(win, kind.icon, x + 2, y + 1, 30, nil, { ZIndex = 8 })
		local lv = Kit.text(win, x, y + 18, TS - 3, 16, "", 12, { ZIndex = 9, TextXAlignment = RIGHT, FontFace = Kit.FONT_HEAVY, stroke = 1.4 })
		local q = Kit.text(win, x, y + 6, TS, 22, "?", 16, { ZIndex = 9, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, TextColor3 = hex("#5a5562"), stroke = 1 })
		local hit = Kit.new("TextButton", { Text = "", BackgroundTransparency = 1, AutoButtonColor = false, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(TS, TS), ZIndex = 10 }, win)
		local key = kind.id .. ":" .. r.id
		hit.MouseButton1Click:Connect(function()
			local ok = request:InvokeServer("ForgeEquip", key)
			Kit.sound(if ok then "click" else "error")
		end)
		tiles[key] = { t = t, st = st, icon = icon, lv = lv, q = q }
	end
	Kit.icon(win, kind.icon, 302, 198 + (ki - 1) * PITCH + 2, 28, nil, { ZIndex = 8 })
end

local function shown(main: GuiObject, on: boolean) main.Parent.Visible = on end
local function refresh()
	local ess = player:GetAttribute("Essence") or 0
	Kit.setText(essText, Econ.Format(ess) .. " ESSENCE")
	local can = ess >= F.RollCost
	Kit.recolour(rollBtn, if can then hex("#7dff7a") else hex("#6a6474"), if can then hex("#1fa83a") else hex("#3f3a48"))
	rollShine.Visible = can
	Kit.setText(rollText, "ROLL · " .. F.RollCost)
	local canBulk = ess >= F.Bulk * F.RollCost
	Kit.recolour(bulkBtn, if canBulk then hex("#5ad1ff") else hex("#6a6474"), if canBulk then hex("#1f6fd1") else hex("#3f3a48"))
	local d = forgeData()
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
		Kit.setText(t.lv, if have then tostring(lv) else "")
		local eq = table.find(d.equipped, key) ~= nil
		t.st.Thickness = if eq then 3.5 else 2
		t.st.Transparency = if eq then 0 elseif have then 0.2 else 0.65
		t.st.Color = if eq then Color3.new(1, 1, 1) else Econ.ForgeRarityById[string.match(key, ":(%a+)$")].colour
	end
	Kit.setText(bookCount, owned .. "/" .. (#F.Kinds * #F.Rarities))
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
for _, a in ipairs({ "Essence", "Forge" }) do
	player:GetAttributeChangedSignal(a):Connect(function() if holder.Visible then refresh() end end)
end

------------------------------------------------------------------------ the roll's reveal
local reveal = Kit.box(win, 0, 0, W, H, { Visible = false, ZIndex = 40 })
local revealBg = Kit.box(reveal, 120, 120, W - 240, 200, { BackgroundTransparency = 0, BackgroundColor3 = hex("#0b090e"), ZIndex = 41 })
Kit.corner(revealBg, 10)
local revealStroke = Kit.stroke(revealBg, Color3.new(1, 1, 1), 3)
local revealIcon = Kit.icon(reveal, "stardust", 140, 140, 120, nil, { ZIndex = 43 })
local revealRarity = Kit.text(reveal, 270, 150, 270, 36, "", 30, { ZIndex = 44, FontFace = Kit.FONT_HEAVY, stroke = 2.4 })
local revealName = Kit.text(reveal, 272, 190, 270, 26, "", 20, { ZIndex = 44, FontFace = Kit.FONT_HEAVY, stroke = 1.6 })
local revealVal = Kit.text(reveal, 272, 220, 270, 30, "", 26, { ZIndex = 44, FontFace = Kit.FONT_HEAVY, stroke = 1.8, TextColor3 = hex("#7dff6b") })
local revealMore = Kit.text(reveal, 272, 256, 270, 22, "", 15, { ZIndex = 44, TextColor3 = hex("#a99fb8"), stroke = 1.1 })
local revealHit = Kit.new("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 45 }, reveal)
revealHit.MouseButton1Click:Connect(function() reveal.Visible = false end)
local function showRoll(results)
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
	for _, c in ipairs(revealIcon.Parent:GetChildren()) do
		if c:IsA("ImageLabel") and (c.Name == "Icon" or c.Name == "Shadow") then c.Image = Kit.A.icon[kind.icon] or "" end
	end
	revealStroke.Color = rar.colour
	Kit.setText(revealRarity, rar.name)
	revealRarity.TextColor3 = rar.colour
	Kit.setText(revealName, kind.name .. " · LV " .. (d.cores[best] or 1))
	Kit.setText(revealVal, Econ.CoreText(k, r, d.cores[best] or 1) .. "  " .. kind.desc:gsub(" x$", ""):gsub("^%+%% ", ""))
	local others = {}
	for _, key in ipairs(results) do if key ~= best then table.insert(others, (string.match(key, ":(%a+)$"))) end end
	Kit.setText(revealMore, if #others > 0 then "+ " .. table.concat(others, ", ") else "Tap to close")
	reveal.Visible = true
	for i = 1, (if bestI >= 4 then 14 else 6) do
		local s = Kit.sparkle(reveal, math.random(130, W - 140), math.random(110, 320), math.random(10, 20), i * 0.05)
		s.ImageColor3 = rar.colour
		task.delay(2, function() s:Destroy() end)
	end
	Kit.sound(if bestI >= 4 then "milestone" else "piecePop")
end
local rolling = false
local function roll(n: number)
	if rolling then return end
	rolling = true
	local ok, results = request:InvokeServer("ForgeRoll", n)
	rolling = false
	if not ok then Kit.sound("error") return end
	task.defer(function()
		refresh()
		showRoll(results)
	end)
end
rollBtn.MouseButton1Click:Connect(function() roll(1) end)
bulkBtn.MouseButton1Click:Connect(function() roll(F.Bulk) end)

------------------------------------------------------------------------ open / close (a side window, key "F")
local isOpen = false
local function place()
	local s = screenScale()
	local vp = viewport()
	local small = vp.Y < 500
	local top = 84 * s
	local room = (if small then vp.Y - 6 else vp.Y - 104 * s) - top
	local want = math.min(Kit.ps(s, 0.85), room / (H + Kit.ps(34, 6)), (vp.X - Kit.ps(24, 8)) / (W + 40))
	holder.Position = UDim2.fromOffset(vp.X / 2, top + room / 2 + 15 * want)
	return want
end
local function close()
	if not isOpen then return end
	isOpen = false
	Kit.sound("close")
	Kit.tween(scale, { Scale = scale.Scale * 0.85 }, 0.15)
	task.delay(0.15, function() if not isOpen then holder.Visible = false end end)
	if shared.GalaxySideWindow then shared.GalaxySideWindow("F", false) end
end
local function open()
	if isOpen then return end
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
