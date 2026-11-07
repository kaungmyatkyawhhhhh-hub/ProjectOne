-- GalaxySettings (Galaxy Incremental, alpha part 2, 3 Nov): the music loop + the SETTINGS window (key Q / the hotbar's Q).
--  * starts the music playlist (Galaxy.Sounds.Playlist, UIKit) and sets the MUSIC / SOUND EFFECTS volumes from your save
--  * the SETTINGS window (the v12 frame, Kit.window): MUSIC and SOUND EFFECTS sliders (Kit.slider), heard while you drag;
--    saved on release (EconRequest "Settings", { music, sfx } -> the VolMusic / VolSfx attributes)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local Kit = require(Galaxy:WaitForChild("UIKit"))
local WM = require(Galaxy:WaitForChild("WindowManager")) -- (7 Nov: closes only by X, Esc / B, outside)
local request = Galaxy:WaitForChild("EconRequest") :: RemoteFunction
local hex = Kit.hex
local CENTRE = Enum.TextXAlignment.Center

while not player:GetAttribute("Loaded") do player:GetAttributeChangedSignal("Loaded"):Wait() end

local function vol(name: string, default: number): number
	local v = player:GetAttribute(name)
	return if type(v) == "number" then math.clamp(v, 0, 1) else default
end
local musicVol, sfxVol = vol("VolMusic", Kit.Sounds.Default.music), vol("VolSfx", Kit.Sounds.Default.sfx)
Kit.setVolumes(musicVol, sfxVol)
Kit.music()
-- (the effects load in the background, so the first buy / comet isn't silent)
task.spawn(Kit.preloadSounds)

------------------------------------------------------------------------ screen
local gui = Instance.new("ScreenGui")
gui.Name = "GalaxySettings"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 3
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui
local PHONE_TEST = Kit.testDevice() ~= nil -- (Studio: Workspace TestDevice / TestPhone, UIKit)
local root: GuiObject | ScreenGui = Kit.testRoot(gui) -- (7 Nov: the safe area; Studio: the emulated device)
local function viewport(): Vector2
	return Kit.viewport(root)
end
local function screenScale(): number
	local vp = viewport()
	if vp.Y < 500 then return math.min(vp.X / 1000, vp.Y / 540) end
	return math.clamp(math.min(vp.X / 1280, vp.Y / 720), 0.6, 1.4)
end

------------------------------------------------------------------------ the window (520 x 260)
local W, H = 520, 336
local holder = Kit.box(root, 0, 0, W, H, { Name = "SettingsWindow", AnchorPoint = Vector2.new(0.5, 0.5), Visible = false })
local scale = Instance.new("UIScale")
scale.Parent = holder
local win, closeBtn = Kit.window(holder, W, H, { title = "SETTINGS", icon = "gear", iconGlow = Color3.fromRGB(200, 196, 210),
	c1 = hex("#3f3a48"), c2 = hex("#8a8496"), lip = hex("#5a5562"), glow = Color3.fromRGB(170, 165, 185), line = hex("#c9c4d2") })

local function row(y: number, title: string, value: number, onChange, onDone)
	Kit.panel(win, 16, y, W - 32, 76)
	Kit.text(win, 34, y + 10, 300, 24, title, 20, { ZIndex = 8, FontFace = Kit.FONT_HEAVY, stroke = 1.6 })
	local pct = Kit.text(win, W - 110, y + 10, 76, 24, "", 20, { ZIndex = 8, stroke = 1.6, TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = hex("#ffd84a") })
	local function show(v) Kit.setText(pct, math.floor(v * 100 + 0.5) .. "%") end
	show(value)
	local s = Kit.slider(win, 46, y + 44, W - 92, value, function(v)
		show(v)
		onChange(v)
	end, onDone, 6)
	return s, show
end
local Econ = require(Galaxy:WaitForChild("EconConfig"))
-- (#6: the number format, for every number in the game on this screen; saved like the sliders)
local sci = player:GetAttribute("NumSci") == true
Econ.NumberMode = if sci then "sci" else "short"
local function save()
	task.spawn(function() request:InvokeServer("Settings", { music = musicVol, sfx = sfxVol, sci = sci }) end)
end
local musicSlider, showMusic = row(76, "MUSIC", musicVol, function(v)
	musicVol = v
	Kit.setVolumes(v, nil)
end, save)
local lastTick = 0
local sfxSlider, showSfx = row(164, "SOUND EFFECTS", sfxVol, function(v)
	sfxVol = v
	Kit.setVolumes(nil, v)
	-- (a click now and then while you drag, so you hear the new level)
	if os.clock() - lastTick > 0.15 then
		lastTick = os.clock()
		Kit.sound("tab")
	end
end, save)

-- the bottom row (2.7): NUMBERS (#6 short / scientific), STATS (#4), CODES (overnight part 2)
local BW = (W - 32 - 16) / 3
local numBtn, numInner = Kit.button(win, 16, 256, BW, 62, hex("#5ad1ff"), hex("#1f6fd1"), { ZIndex = 6 })
Kit.text(numInner, 0, Kit.ps(6, 5), BW, 22, "NUMBERS", Kit.ps(17, 19), { ZIndex = numInner.ZIndex, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 1.6 })
local numText = Kit.text(numInner, 0, Kit.ps(30, 29), BW, 24, "", Kit.ps(18, 20), { ZIndex = numInner.ZIndex, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 1.6 })
local function showNum() Kit.setText(numText, if sci then "1.20e6" else "1.2M") end
showNum()
numBtn.MouseButton1Click:Connect(function()
	sci = not sci
	Econ.NumberMode = if sci then "sci" else "short"
	Kit.sound("tab")
	showNum()
	save()
end)
local statsBtn, statsInner = Kit.button(win, 16 + BW + 8, 256, BW, 62, hex("#ffd84a"), hex("#e08a00"), { ZIndex = 6 })
Kit.text(statsInner, 0, Kit.ps(18, 16), BW, 28, "STATS", Kit.ps(24, 26), { ZIndex = statsInner.ZIndex, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 2 })
local codes, codesInner = Kit.button(win, 16 + 2 * (BW + 8), 256, BW, 62, hex("#ff7d8e"), hex("#c22a3e"), { ZIndex = 6 })
Kit.text(codesInner, 0, Kit.ps(18, 16), BW, 28, "CODES", Kit.ps(24, 26), { ZIndex = codesInner.ZIndex, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 2 })
codes.MouseButton1Click:Connect(function()
	if shared.GalaxyCodesOpen then shared.GalaxyCodesOpen() end
end)

------------------------------------------------------------------------ open / close
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
	Kit.sound("close")
	Kit.tween(scale, { Scale = scale.Scale * 0.85 }, 0.15)
	task.delay(0.15, function() if not isOpen then holder.Visible = false end end)
	if shared.GalaxySideWindow then shared.GalaxySideWindow("Q", false) end
end
local function open()
	if isOpen then return end
	if shared.GalaxyCloseSide then shared.GalaxyCloseSide("Q") end
	isOpen = true
	Kit.sound("open")
	musicSlider.set(musicVol)
	sfxSlider.set(sfxVol)
	showMusic(musicVol)
	showSfx(sfxVol)
	holder.Visible = true
	if shared.GalaxySideWindow then shared.GalaxySideWindow("Q", true) end
	local want = place()
	scale.Scale = want * 0.8
	Kit.tween(scale, { Scale = want }, 0.25, Enum.EasingStyle.Back)
end
shared.GalaxySettingsToggle = function() if isOpen then close() else open() end end
shared.GalaxySettingsClose = close
WM.register("Q", holder, close)
closeBtn.MouseButton1Click:Connect(close)
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() if isOpen then scale.Scale = place() end end)

------------------------------------------------------------------------ #4 the STATS window (Settings > STATS; side key "P"): your income,
-- step by step (the server's IncomeSplit: each line a multiplier on the one before), the total, and the time to your next
-- Supernova at this income
local HttpService = game:GetService("HttpService")
local SW, SH = 560, 620 -- (7 Nov: + YOUR STATS on top, an icon per line)
local stats = Kit.box(root, 0, 0, SW, SH, { Name = "StatsWindow", AnchorPoint = Vector2.new(0.5, 0.5), Visible = false })
local sScale = Instance.new("UIScale")
sScale.Parent = stats
-- (7 Nov: on a PHONE the window fits the width (text >= 14 px) and scrolls up / down, like UPGRADES)
local sHolder: GuiObject = stats
if Kit.phone() then
	sHolder = Kit.new("ScrollingFrame", { Name = "PhoneScroll", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromOffset(SW, SH),
		CanvasSize = UDim2.fromOffset(0, SH), ScrollBarThickness = 8, ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarImageColor3 = hex("#ffd84a") }, stats)
end
local sWin, sClose = Kit.window(sHolder, SW, SH, { title = "STATS", icon = "stardust", iconGlow = Color3.fromRGB(255, 200, 70),
	c1 = hex("#7a4a0a"), c2 = hex("#ffc83a"), lip = hex("#c2840c"), glow = Color3.fromRGB(255, 170, 40), line = hex("#ffe08a") })
-- (7 Nov, item 7: YOUR STATS: 10 lines in 2 columns, each with its own icon (ArtIds.uiIcon))
local gPanel = Kit.panel(sWin, 16, 66, SW - 32, 212, 4)
Kit.stroke(gPanel, hex("#ffc83a"), 2, 0.2)
local STATS = {
	{ icon = "supernova", name = "SUPERNOVAS" }, { icon = "comet", name = "COMETS" },
	{ icon = "starShard", name = "SHARDS" }, { icon = "starCore", name = "CORES" },
	{ icon = "essence", name = "ESSENCE" }, { icon = "darkMatter", name = "DARK MATTER" },
	{ icon = "forgeRolls", name = "FORGE ROLLS" }, { icon = "bodies", name = "BODIES" },
	{ icon = "playtime", name = "TIME PLAYED" }, { icon = "trophy", name = "RANK" },
}
local gridVals = {}
for i, st in ipairs(STATS) do
	local col, row = (i - 1) % 2, (i - 1) // 2
	local x, y = 26 + col * 262, 74 + row * 40
	Kit.icon(sWin, "ui:" .. st.icon, x, y, 36, nil, { ZIndex = 8 })
	Kit.text(sWin, x + 42, y + 8, 120, 22, st.name, Kit.ps(13, 15), { ZIndex = 8, FontFace = Kit.FONT_BOLD, stroke = 1.2, TextColor3 = hex("#cfc6dd") })
	gridVals[i] = Kit.text(sWin, x + 132, y + 6, 112, 26, "", Kit.ps(16, 18), { ZIndex = 8, FontFace = Kit.FONT_HEAVY, stroke = 1.4, TextXAlignment = Enum.TextXAlignment.Right })
end
local sPanel = Kit.panel(sWin, 16, 290, SW - 32, 262, 4)
Kit.stroke(sPanel, hex("#ffc83a"), 2, 0.2)
local statRows = {}
for i = 1, 9 do
	local y = 298 + (i - 1) * 28
	local name = Kit.text(sWin, 30, y, 380, 24, "", Kit.ps(14, 16), { ZIndex = 8, FontFace = Kit.FONT_BOLD, stroke = 1.2 })
	local val = Kit.text(sWin, SW - 170, y, 140, 24, "", Kit.ps(16, 18), { ZIndex = 8, FontFace = Kit.FONT_HEAVY, stroke = 1.4, TextXAlignment = Enum.TextXAlignment.Right })
	statRows[i] = { name = name, val = val }
end
local nextLine = Kit.text(sWin, 16, 562, SW - 32, 40, "", Kit.ps(17, 19), { ZIndex = 8, FontFace = Kit.FONT_HEAVY, stroke = 1.6, TextXAlignment = CENTRE,
	TextColor3 = hex("#ffd84a"), TextWrapped = true })
local fmt = Econ.Format
local function mult(x: number): string
	if x >= 10 then return "x" .. fmt(x) end
	return "x" .. (string.format("%.2f", x):gsub("0+$", ""):gsub("%.$", ""))
end
local function playTime(sec: number): string
	if sec >= 3600 then return math.floor(sec / 3600) .. "h " .. math.floor(sec % 3600 / 60) .. "m" end
	return math.floor(sec / 60) .. " min"
end
local function refreshGrid()
	local okF, forge = pcall(function() return HttpService:JSONDecode(player:GetAttribute("Forge") or "{}") end)
	if not okF or type(forge) ~= "table" then forge = {} end
	local cores = 0
	for _ in pairs(type(forge.cores) == "table" and forge.cores or {}) do cores += 1 end
	local bodies = 0
	for i = 1, #Econ.Tiers do bodies += tonumber(player:GetAttribute("Copies" .. i)) or 0 end
	local rank = string.gsub(tostring(player:GetAttribute("Rank") or ""), "%s*·.*$", "")
	local vals = {
		fmt(player:GetAttribute("Supernovas") or 0), fmt(player:GetAttribute("CometsCaught") or 0),
		fmt(player:GetAttribute("Shards") or 0), cores .. "/" .. (#Econ.Forge.Kinds * #Econ.Forge.Rarities),
		fmt(player:GetAttribute("Essence") or 0), fmt(player:GetAttribute("DarkMatter") or 0),
		fmt(tonumber(forge.rolls) or 0), fmt(bodies),
		playTime(player:GetAttribute("PlayTime") or 0), if rank ~= "" then rank else "NEW STAR",
	}
	for i, v in ipairs(vals) do Kit.setText(gridVals[i], v) end
end
local function refreshStats()
	refreshGrid()
	local ok, list = pcall(function() return HttpService:JSONDecode(player:GetAttribute("IncomeSplit") or "[]") end)
	if not ok or type(list) ~= "table" then list = {} end
	for i, r in ipairs(statRows) do
		local e = list[i]
		r.name.Parent.Visible = e ~= nil
		r.val.Parent.Visible = e ~= nil
		if e then
			Kit.setText(r.name, e[1])
			Kit.setText(r.val, if e[3] == "base" or e[3] == "total" then fmt(e[2]) .. "/s" else mult(e[2]))
			r.val.TextColor3 = if e[3] == "total" then hex("#ffd84a") elseif e[3] == "base" then Color3.new(1, 1, 1) elseif e[2] > 1.0001 then hex("#7dff6b") else hex("#a99fb8")
			r.name.TextColor3 = if e[3] == "total" then hex("#ffd84a") else Color3.new(1, 1, 1)
		end
	end
	local need = player:GetAttribute("SupernovaNeed") or 0
	local earned = player:GetAttribute("EarnedRun") or 0
	local income = math.max(player:GetAttribute("Income") or 0, 1e-9)
	local left = math.max(0, need - earned) / income
	Kit.setText(nextLine, if player:GetAttribute("SupernovaReady") then "Your SUPERNOVA is ready!"
		else "Next SUPERNOVA in about " .. (if left >= 3600 then math.floor(left / 3600) .. " h " .. math.floor(left % 3600 / 60) .. " min" elseif left >= 60 then math.floor(left / 60) .. " min " .. math.floor(left % 60) .. " s" else math.ceil(left) .. " s") .. " at this income")
end
local sOpen = false
local function closeStats()
	if not sOpen then return end
	sOpen = false
	Kit.sound("close")
	Kit.tween(sScale, { Scale = sScale.Scale * 0.85 }, 0.15)
	task.delay(0.15, function() if not sOpen then stats.Visible = false end end)
	if shared.GalaxySideWindow then shared.GalaxySideWindow("P", false) end
end
local function openStats()
	if sOpen then return end
	if shared.GalaxyCloseSide then shared.GalaxyCloseSide("P") end
	sOpen = true
	Kit.sound("open")
	refreshStats()
	stats.Visible = true
	if shared.GalaxySideWindow then shared.GalaxySideWindow("P", true) end
	local s = screenScale()
	local vp = viewport()
	local small = vp.Y < 500
	local top = 124 * s
	local room = (if small then vp.Y - 6 else vp.Y - 104 * s) - top
	local want = math.min(Kit.ps(s, 0.85), room / (SH + Kit.ps(34, 6)), (vp.X - Kit.ps(24, 8)) / (SW + 40))
	if sHolder ~= stats then
		want = math.min(1, (vp.X - 12) / (SW + 16))
		local h = math.min(SH, math.floor(room / want))
		-- (7 Nov, corners: the scroll bar runs in a 12 px margin BESIDE the window; at the window's own width Roblox drew it over
		-- the rounded right edge, a square layer at the corners)
		sHolder.Size = UDim2.fromOffset(SW + 12, h)
		stats.Size = UDim2.fromOffset(SW + 12, h)
	end
	stats.Position = UDim2.fromOffset(vp.X / 2, top + room / 2 + (if sHolder ~= stats then 0 else 15 * want))
	sScale.Scale = want * 0.8
	Kit.tween(sScale, { Scale = want }, 0.25, Enum.EasingStyle.Back)
end
shared.GalaxyStatsClose = closeStats
WM.register("P", stats, closeStats)
statsBtn.MouseButton1Click:Connect(function() Kit.sound("click") openStats() end)
sClose.MouseButton1Click:Connect(closeStats)
task.spawn(function()
	while true do
		task.wait(1)
		if sOpen then refreshStats() end
	end
end)
