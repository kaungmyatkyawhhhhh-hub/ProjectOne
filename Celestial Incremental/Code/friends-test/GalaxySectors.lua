-- GalaxySectors (Galaxy Incremental, purpose, 5 Nov; vault "Prompt - Purpose", checklist #13-#27): the GALAXY window and
-- IGNITION 1.
--  * The GALAXY window (the HUD's IGNITION pill): GALAXY LIT %, the Ignition checklist of your sector (all at once: the
--    server checks it, GalaxyEconService checkIgnition), the sectors = chapters (done / here / locked; later ones "?"), your
--    PATH and its switch (Econ.PathSwitchShards shards).
--  * IGNITION 1 (EconEvent "Ignition"): the cinematic: the camera turns to Sector 2, the bridge lights up, the galaxy's
--    colours come back (shared.GalaxyLightUp), "SECTOR 1 LIT!" + the Essence; SKIP after 1 s, Camera.Focus every frame. Then
--    the PATH card: pick 1 of 2 (EconRequest "PickPath").
-- No dates for sectors not built yet ("LATER"), no fake timers.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local Kit = require(Galaxy:WaitForChild("UIKit"))
local Econ = require(Galaxy:WaitForChild("EconConfig"))
local MapConfig = require(Galaxy:WaitForChild("MapConfig"))
local request = Galaxy:WaitForChild("EconRequest") :: RemoteFunction
local event = Galaxy:WaitForChild("EconEvent") :: RemoteEvent
local hex = Kit.hex
local CENTRE = Enum.TextXAlignment.Center
local RIGHT = Enum.TextXAlignment.Right
local fmt = Econ.Format

while not player:GetAttribute("Loaded") do player:GetAttributeChangedSignal("Loaded"):Wait() end

local gui = Instance.new("ScreenGui")
gui.Name = "GalaxySectors"
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

------------------------------------------------------------------------ the GALAXY window (640 x 420)
local W, H = 640, 420
local holder = Kit.box(root, 0, 0, W, H, { Name = "GalaxyWindow", AnchorPoint = Vector2.new(0.5, 0.5), Visible = false })
local scale = Instance.new("UIScale")
scale.Parent = holder
local win, closeBtn = Kit.window(holder, W, H, { title = "GALAXY", icon = "sun", iconGlow = Color3.fromRGB(90, 200, 255),
	c1 = hex("#1d2a6a"), c2 = hex("#5a7dff"), lip = hex("#2a46c2"), glow = Color3.fromRGB(80, 130, 255), line = hex("#9ab4ff") })

-- GALAXY LIT % (the finish line)
local litText = Kit.text(win, 24, 70, 360, 32, "GALAXY LIT 0%", 26, { ZIndex = 8, FontFace = Kit.FONT_HEAVY, stroke = 2,
	gradient = ColorSequence.new(hex("#e8f2ff"), hex("#7db4ff")) })
Kit.text(win, 300, 76, W - 324, 22, Econ.Premise, Kit.ps(12, 15), { ZIndex = 8, TextColor3 = hex("#a99fb8"), TextXAlignment = RIGHT, stroke = 1.1 })
local litBar = Kit.box(win, 24, 106, W - 48, 16, { BackgroundTransparency = 0, BackgroundColor3 = hex("#16131b"), ZIndex = 6 })
Kit.corner(litBar, 8)
Kit.stroke(litBar, Kit.INK, 2)
local litFill = Kit.box(litBar, 0, 0, 0, 16, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 7 })
Kit.corner(litFill, 8)
Kit.grad(litFill, hex("#bfe9ff"), hex("#5a7dff"), 90)

-- left: the IGNITION checklist (or, once lit, your PATH)
local left = Kit.panel(win, 16, 136, 300, 268, 4)
Kit.stroke(left, hex("#ff9a3a"), 2, 0.2)
local ignTitle = Kit.text(win, 30, 146, 280, 28, "IGNITION · EMBER BELT", 21, { ZIndex = 8, FontFace = Kit.FONT_HEAVY, stroke = 1.8,
	gradient = ColorSequence.new(hex("#fff1c0"), hex("#ff9a3a")) })
local ignSub = Kit.text(win, 30, 174, 280, 18, "All four at once lights your sector", Kit.ps(12, 14), { ZIndex = 8, TextColor3 = hex("#a99fb8"), stroke = 1 })
local rows = {}
for i, item in ipairs(MapConfig.Ignition) do
	local y = 198 + (i - 1) * 48
	local dot = Kit.box(win, 30, y + 8, 24, 24, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 7 })
	Kit.corner(dot, 12)
	Kit.stroke(dot, Kit.INK, 2)
	local dotGrad = Kit.grad(dot, hex("#6a6474"), hex("#3f3a48"), 90)
	local text = Kit.text(win, 62, y + 4, 180, 32, item.text, Kit.ps(15, 18), { ZIndex = 8, FontFace = Kit.FONT_BOLD, stroke = 1.3, TextWrapped = true })
	local count = Kit.text(win, 240, y + 8, 64, 24, "0/" .. item.need, Kit.ps(15, 18), { ZIndex = 8, TextXAlignment = RIGHT, stroke = 1.4, FontFace = Kit.FONT_HEAVY })
	rows[i] = { dot = dot, grad = dotGrad, text = text, count = count, item = item }
end
-- (after Ignition 1) the path + its switch
local pathName = Kit.text(win, 30, 214, 280, 30, "", 24, { ZIndex = 8, FontFace = Kit.FONT_HEAVY, stroke = 2 })
local pathDesc = Kit.text(win, 30, 248, 280, 40, "", Kit.ps(14, 17), { ZIndex = 8, TextColor3 = hex("#cfc6dd"), stroke = 1.2, TextWrapped = true })
local switchBtn, switchInner = Kit.button(win, 30, 330, 272, 50, hex("#b49bff"), hex("#5a3ad8"), { ZIndex = 6 })
local switchText = Kit.text(switchInner, 0, Kit.ps(12, 10), 272, 28, "", Kit.ps(17, 20), { ZIndex = switchInner.ZIndex, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 1.8 })

-- right: the SECTORS (chapters)
local right = Kit.panel(win, 324, 136, 300, 268, 4)
Kit.stroke(right, hex("#5a7dff"), 2, 0.2)
Kit.text(win, 338, 146, 270, 28, "SECTORS", 21, { ZIndex = 8, FontFace = Kit.FONT_HEAVY, stroke = 1.8, gradient = ColorSequence.new(hex("#e8f2ff"), hex("#7db4ff")) })
local sectorRows = {}
for i, sec in ipairs(Econ.Sectors) do
	local y = 178 + (i - 1) * 45
	local icon = Kit.icon(win, sec.icon, 334, y - 2, 44, nil, { ZIndex = 8 })
	local name = Kit.text(win, 382, y, 150, 22, (if i <= 4 then i .. "  " else "") .. sec.name, Kit.ps(16, 18), { ZIndex = 8, FontFace = Kit.FONT_HEAVY, stroke = 1.6 })
	local sys = Kit.text(win, 382, y + 21, 160, 18, sec.system, Kit.ps(11, 14), { ZIndex = 8, TextColor3 = hex("#a99fb8"), stroke = 1 })
	local chip = Kit.box(win, 540, y + 6, 74, 24, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 7 })
	Kit.corner(chip, 5)
	Kit.stroke(chip, Kit.INK, 2)
	local chipGrad = Kit.grad(chip, hex("#6a6474"), hex("#3f3a48"), 90)
	local chipText = Kit.text(chip, 0, Kit.ps(3, 2), 74, 20, "", Kit.ps(12, 14), { ZIndex = 8, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 1.3 })
	sectorRows[i] = { icon = icon, name = name, sys = sys, chipGrad = chipGrad, chipText = chipText }
end

local function shown(main: GuiObject, on: boolean) main.Parent.Visible = on end
local function refresh()
	local lit = player:GetAttribute("GalaxyLit") or 0
	Kit.setText(litText, "GALAXY LIT " .. lit .. "%")
	litFill.Size = UDim2.fromOffset(math.floor((W - 48) * math.clamp(lit / 100, 0, 1)), 16)
	litFill.Visible = lit > 0
	local ignited = (player:GetAttribute("Ignition") or 0) >= 1
	-- the checklist (before) / the path (after)
	Kit.setText(ignTitle, if ignited then "SECTOR 1 LIT" else "IGNITION · EMBER BELT")
	shown(ignSub, not ignited)
	for _, r in ipairs(rows) do
		local v = tonumber(player:GetAttribute(r.item.attribute)) or 0
		local ok = v >= r.item.need
		shown(r.text, not ignited)
		shown(r.count, not ignited)
		r.dot.Visible = not ignited
		r.grad.Color = if ok then ColorSequence.new(hex("#7dff7a"), hex("#1fa83a")) else ColorSequence.new(hex("#6a6474"), hex("#3f3a48"))
		Kit.setText(r.count, math.min(v, r.item.need) .. "/" .. r.item.need)
		r.count.TextColor3 = if ok then hex("#7dff6b") else Color3.new(1, 1, 1)
	end
	local path = player:GetAttribute("Path") or ""
	local def
	for _, p in ipairs(Econ.Paths) do if p.id == path then def = p end end
	shown(pathName, ignited)
	shown(pathDesc, ignited)
	switchBtn.Visible = ignited
	if ignited then
		Kit.setText(pathName, if def then def.name else "PICK YOUR PATH")
		Kit.setText(pathDesc, if def then def.desc else "Two ways to grow: pick one.")
		Kit.setText(switchText, if def then "SWITCH  " .. Econ.PathSwitchShards .. " SHARDS" else "PICK A PATH")
	end
	-- the sectors: 1 = here (lit after Ignition 1), 2 = locked until Ignition 1, then here; later ones "LATER" / "?"
	for i, r in ipairs(sectorRows) do
		local sec = Econ.Sectors[i]
		local state, c1, c2
		if i == 1 then
			state, c1, c2 = if ignited then "LIT" else "HERE", if ignited then "#7dd8ff" else "#ff9a3a", if ignited then "#1f6fd1" else "#c2410c"
		elseif i == 2 then
			state, c1, c2 = if ignited then "HERE" else "IGNITION", if ignited then "#ff9a3a" else "#6a6474", if ignited then "#c2410c" else "#3f3a48"
		else
			state, c1, c2 = if sec.name == "?" then "?" else "LATER", "#6a6474", "#3f3a48"
		end
		r.chipGrad.Color = ColorSequence.new(hex(c1), hex(c2))
		Kit.setText(r.chipText, state)
		local dark = i >= 3 or (i == 2 and not ignited)
		r.icon.ImageColor3 = if dark then Color3.new(0, 0, 0) else Color3.new(1, 1, 1)
		r.name.TextColor3 = if dark then hex("#8a8296") else Color3.new(1, 1, 1)
	end
end
for _, a in ipairs({ "GalaxyLit", "Ignition", "Path", "Supernovas", "CosmicLevel", "Pads", "BestTier" }) do
	player:GetAttributeChangedSignal(a):Connect(function() if holder.Visible then refresh() end end)
end

------------------------------------------------------------------------ the PATH card (after the Ignition cinematic, or SWITCH)
local cardHolder = Kit.box(root, 0, 0, 560, 300, { Name = "PathCard", AnchorPoint = Vector2.new(0.5, 0.5), Visible = false })
local cardScale = Instance.new("UIScale")
cardScale.Parent = cardHolder
local card, cardClose = Kit.window(cardHolder, 560, 300, { title = "PICK YOUR PATH", icon = "sun", iconGlow = Color3.fromRGB(255, 160, 60),
	c1 = hex("#7a3a14"), c2 = hex("#ff9a3a"), lip = hex("#c2410c"), glow = Color3.fromRGB(255, 140, 40), line = hex("#ffc58a") })
for i, p in ipairs(Econ.Paths) do
	local x = 16 + (i - 1) * 270
	local panel = Kit.panel(card, x, 76, 258, 208, 4)
	Kit.stroke(panel, hex(if i == 1 then "#5ad1ff" else "#b49bff"), 2, 0.2)
	Kit.icon(card, p.icon, x + 8, 70, 96, if i == 1 then Color3.fromRGB(90, 200, 255) else Color3.fromRGB(170, 130, 255), { ZIndex = 8 })
	Kit.text(card, x + 108, 90, 146, 30, p.name, 21, { ZIndex = 8, FontFace = Kit.FONT_HEAVY, stroke = 1.8, TextWrapped = true })
	Kit.text(card, x + 14, 168, 232, 40, p.desc, Kit.ps(14, 17), { ZIndex = 8, TextColor3 = hex("#cfc6dd"), stroke = 1.2, TextWrapped = true })
	local b, inner = Kit.button(card, x + 14, 222, 230, 50, hex("#7dff7a"), hex("#1fa83a"), { ZIndex = 6 })
	Kit.text(inner, 0, Kit.ps(12, 10), 230, 28, "PICK", 22, { ZIndex = inner.ZIndex, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 1.8 })
	Kit.tagVfx(Kit.shine(b, 2.6))
	b.MouseButton1Click:Connect(function()
		local ok = request:InvokeServer("PickPath", p.id)
		Kit.sound(if ok then "milestone" else "error")
		if ok then
			Kit.tween(cardScale, { Scale = cardScale.Scale * 0.85 }, 0.15)
			task.delay(0.15, function() cardHolder.Visible = false end)
			refresh()
		end
	end)
end
local function showPathCard()
	cardHolder.Visible = true
	local vp = viewport()
	cardHolder.Position = UDim2.fromOffset(vp.X / 2, vp.Y / 2)
	local want = math.min(screenScale(), (vp.X - 16) / 600, (vp.Y - 16) / 340)
	cardScale.Scale = want * 0.8
	Kit.tween(cardScale, { Scale = want }, 0.25, Enum.EasingStyle.Back)
	Kit.sound("open")
end
cardClose.MouseButton1Click:Connect(function() cardHolder.Visible = false end)

------------------------------------------------------------------------ open / close (a side window, key "S")
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
	if shared.GalaxySideWindow then shared.GalaxySideWindow("S", false) end
end
local function open()
	if isOpen then return end
	if shared.GalaxyCloseSide then shared.GalaxyCloseSide("S") end
	isOpen = true
	Kit.sound("open")
	refresh()
	holder.Visible = true
	if shared.GalaxySideWindow then shared.GalaxySideWindow("S", true) end
	local want = place()
	scale.Scale = want * 0.8
	Kit.tween(scale, { Scale = want }, 0.25, Enum.EasingStyle.Back)
end
shared.GalaxySectorsToggle = function() if isOpen then close() else open() end end
shared.GalaxySectorsClose = close
closeBtn.MouseButton1Click:Connect(close)
switchBtn.MouseButton1Click:Connect(function()
	close()
	showPathCard()
end)
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() if isOpen then scale.Scale = place() end end)

------------------------------------------------------------------------ IGNITION 1: the cinematic (client only)
-- (cutscene template, 5 Nov: IGNITION ~8 s with GalaxyCutscene: the camera's high arc over the plaza to Sector 2 + the
-- screen layers in the sector's colour, constellation lines drawing, the words = the sector's name; the climax (white flash,
-- starburst, boom) lights the galaxy and gives the reward line; then the PATH card)
local Cutscene = require(Galaxy:WaitForChild("GalaxyCutscene"))
local function cinematic(essence: number)
	-- (Studio: Workspace TestSlowMo = n plays it n x slower, for frame-by-frame screenshots)
	local slow = if RunService:IsStudio() then tonumber(workspace:GetAttribute("TestSlowMo")) or 1 else 1
	if shared.GalaxyCloseSide then shared.GalaxyCloseSide() end
	local cam = workspace.CurrentCamera
	local NS = MapConfig.NextSector
	local target = MapConfig.Origin + NS.Position
	-- (an ARC high over the plaza, so it never skims the plaza's boards: from you, up to ~70 above the middle, down to 70 studs
	-- short of Sector 2 and 36 above it; the look turns from where you looked to Sector 2)
	local from = cam.CFrame
	local dir = Vector3.new(target.X - MapConfig.Origin.X, 0, target.Z - MapConfig.Origin.Z).Unit
	local p0 = from.Position
	local p2 = target - dir * 70 + Vector3.new(0, 36, 0)
	local p1 = (p0 + p2) / 2 + Vector3.new(0, 70, 0)
	local look0 = p0 + from.LookVector * 50
	Cutscene.play({
		colour = Color3.fromRGB(255, 150, 60), symbol = Kit.A.icon.sun, length = 8, drop = 6.2, slow = slow, lines = true,
		words = { "SECTOR 1", "EMBER BELT" }, title = "SECTOR 1 LIT!", sub = "SECTOR 2: COMET REACH · THE STAR FORGE · +" .. essence .. " ESSENCE",
		camera = function(k)
			local kk = math.clamp(k / 0.6, 0, 1) -- (the flight is the first 60%: then it holds on Sector 2)
			kk = kk * kk * (3 - 2 * kk)
			local pos = (1 - kk) ^ 2 * p0 + 2 * (1 - kk) * kk * p1 + kk ^ 2 * p2
			return CFrame.lookAt(pos, look0:Lerp(target, math.min(1, kk * 1.4))), target
		end,
		onClimax = function()
			if shared.GalaxyLightUp then shared.GalaxyLightUp(1.5 * slow) end
		end,
	})
	showPathCard()
end
event.OnClientEvent:Connect(function(kind, a, b)
	if kind == "Ignition" then task.spawn(cinematic, tonumber(b) or 0) end
end)
-- (a save that lit Sector 1 without picking a path: the card on join)
if (player:GetAttribute("Ignition") or 0) >= 1 and (player:GetAttribute("Path") or "") == "" then task.delay(4, showPathCard) end
local _ = fmt
