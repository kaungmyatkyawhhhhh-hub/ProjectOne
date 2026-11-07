-- GalaxyBlackHole (Galaxy Incremental, Phase 3.1, 6 Nov; design "Full game design" §1 + §4, checklist #58 #26 #299 #258 #417):
-- the BLACK HOLE window (opened from your island's BLACK HOLE board or the plaza's Black Hole gate: Galaxy.OpenWindow
-- "BlackHole") and its WOAH moment.
--  * the window: your Dark Matter (+25% shards each), the shards earned since the last Black Hole / 100K, the Dark Matter
--    you'd get, what resets and what stays, the COLLAPSE button (a 2nd tap confirms), AUTO-SUPERNOVA (from Black Hole 1)
--  * the moment (#299 #258): the camera at the plaza's Black Hole; everything is pulled in, rings warp, the music + every sound
--    drop away (a low suck, a pitch-down), a held silence, then the DARK PULSE; the Dark Matter is given on that pulse (#318),
--    SKIP after 1 s
-- Numbers: EconConfig.BlackHole. The server does the Black Hole (EconRequest "BlackHole"); this only draws.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local Kit = require(Galaxy:WaitForChild("UIKit"))
local WM = require(Galaxy:WaitForChild("WindowManager")) -- (7 Nov: closes only by X, Esc / B, outside)
local Econ = require(Galaxy:WaitForChild("EconConfig"))
local Vfx = require(Galaxy:WaitForChild("VfxLibrary"))
local Cutscene = require(Galaxy:WaitForChild("GalaxyCutscene"))
local request = Galaxy:WaitForChild("EconRequest") :: RemoteFunction
local hex = Kit.hex
local CENTRE = Enum.TextXAlignment.Center
local fmt = Econ.Format
local BH = Econ.BlackHole
local VIOLET = Color3.fromRGB(170, 90, 255)

while not player:GetAttribute("Loaded") do player:GetAttributeChangedSignal("Loaded"):Wait() end

local gui = Instance.new("ScreenGui")
gui.Name = "GalaxyBlackHole"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 4
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
-- a window centred between the counter and the hotbar, as big as fits (the side windows' rule, GalaxyDaily)
local function placeIn(holder: GuiObject, W: number, H: number): number
	local s = screenScale()
	local vp = viewport()
	local small = vp.Y < 500
	local top = 124 * s
	local room = (if small then vp.Y - 6 else vp.Y - 104 * s) - top
	local want = math.min(Kit.ps(s, 0.85), room / (H + Kit.ps(34, 6)), (vp.X - Kit.ps(24, 8)) / (W + 40))
	holder.Position = UDim2.fromOffset(vp.X / 2, top + room / 2 + 15 * want)
	return want
end

------------------------------------------------------------------------ the window (600 x 440)
local W, H = 600, 440
local holder = Kit.box(root, 0, 0, W, H, { Name = "BlackHoleWindow", AnchorPoint = Vector2.new(0.5, 0.5), Visible = false })
local hScale = Instance.new("UIScale")
hScale.Parent = holder
local win, closeBtn = Kit.window(holder, W, H, { title = "BLACK HOLE", icon = "blackHole", iconGlow = VIOLET,
	c1 = hex("#2a0f4a"), c2 = hex("#8a4dff"), lip = hex("#4b1d8f"), glow = VIOLET, line = hex("#c9a6ff") })
local function heading(x: number, y: number, str: string)
	Kit.text(win, x, y, 300, 24, str, Kit.ps(17, 19), { ZIndex = 8, FontFace = Kit.FONT_HEAVY, stroke = 1.8,
		gradient = ColorSequence.new(hex("#f2e8ff"), hex("#b98aff")) })
end
-- your Dark Matter
local dmPanel = Kit.panel(win, 24, 66, W - 48, 64, 4)
Kit.stroke(dmPanel, VIOLET, 2, 0.3)
Kit.icon(win, "ui:darkMatter", 34, 68, 60, VIOLET, { ZIndex = 7 }) -- (7 Nov: the Dark Matter icon)
local dmText = Kit.text(win, 104, 72, W - 140, 30, "", Kit.ps(24, 26), { ZIndex = 8, FontFace = Kit.FONT_HEAVY, stroke = 2,
	gradient = ColorSequence.new(hex("#f2e8ff"), hex("#b98aff")) })
local dmSub = Kit.text(win, 104, 102, W - 140, 22, "", Kit.ps(14, 16), { ZIndex = 8, TextColor3 = hex("#cfc6dd"), stroke = 1.2 })
-- the progress to the next one
heading(24, 142, "SHARDS EARNED SINCE THE LAST BLACK HOLE")
local bar = Kit.box(win, 24, 172, W - 48, 22, { BackgroundTransparency = 0, BackgroundColor3 = hex("#1a1426"), ZIndex = 6 })
Kit.corner(bar, 11)
Kit.stroke(bar, Kit.INK, 2)
local fill = Kit.box(bar, 0, 0, 0, 22, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 7 })
Kit.corner(fill, 11)
Kit.grad(fill, hex("#e0c8ff"), hex("#7a2cff"), 90)
local barText = Kit.text(bar, 0, Kit.ps(1, 0), W - 48, 22, "", Kit.ps(14, 16), { ZIndex = 8, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 1.5 })
local gainText = Kit.text(win, 24, 200, W - 48, 24, "", Kit.ps(16, 18), { ZIndex = 8, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 1.6,
	TextColor3 = hex("#d7b8ff") })
-- what goes, what stays
-- (7 Nov, item 8: LOSE with the reset icon, KEEP with the keep icon)
Kit.icon(win, "ui:reset", 24, 228, 30, nil, { ZIndex = 8 })
heading(60, 232, "LOSE")
Kit.icon(win, "ui:keep", W / 2 + 6, 228, 30, nil, { ZIndex = 8 })
heading(W / 2 + 42, 232, "KEEP")
local goes = "Stardust + bodies\nRing 1 + shards\nRing 2 + capstone\nthe Supernova climb"
local stays = "Supernovas + rank\nCosmic Level + perks\nPads, Ignition, Forge\nEssence + Dark Matter\nthe AUTOMATION branch"
-- (7 Nov: bigger lines, they were ~11 px on a phone)
Kit.text(win, 24, 262, W / 2 - 34, 96, goes, Kit.ps(16, 19), { ZIndex = 8, TextColor3 = hex("#ff9db0"), stroke = 1.2, TextWrapped = true,
	TextYAlignment = Enum.TextYAlignment.Top })
Kit.text(win, W / 2 + 6, 262, W / 2 - 30, 96, stays, Kit.ps(16, 19), { ZIndex = 8, TextColor3 = hex("#9dffb0"), stroke = 1.2, TextWrapped = true,
	TextYAlignment = Enum.TextYAlignment.Top })
-- the COLLAPSE button (a 2nd tap confirms: it resets a lot) + AUTO-SUPERNOVA
local goBtn, goInner, _, goShadow = Kit.button(win, 24, 362, 330, 56, hex("#b98aff"), hex("#5a1fc2"), { ZIndex = 6 })
local goText = Kit.text(goInner, 0, Kit.ps(12, 10), 330, 30, "COLLAPSE", Kit.ps(24, 26), { ZIndex = goInner.ZIndex, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 2 })
local autoBtn, autoInner, _, autoShadow = Kit.button(win, 370, 362, 206, 56, hex("#7dff7a"), hex("#1fa83a"), { ZIndex = 6 })
local autoText = Kit.text(autoInner, 0, Kit.ps(4, 3), 206, 24, "AUTO-SUPERNOVA", Kit.ps(15, 17), { ZIndex = autoInner.ZIndex, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 1.6 })
local autoState = Kit.text(autoInner, 0, Kit.ps(28, 27), 206, 22, "", Kit.ps(14, 16), { ZIndex = autoInner.ZIndex, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 1.4 })
local _ = goShadow
local _2 = autoShadow

local armed = false
local function refresh()
	local dm = player:GetAttribute("DarkMatter") or 0
	local holes = player:GetAttribute("BlackHoles") or 0
	local have = player:GetAttribute("ShardsHole") or 0
	local gain = player:GetAttribute("BlackHoleGain") or 0
	local ready = player:GetAttribute("BlackHoleReady") == true
	Kit.setText(dmText, fmt(dm) .. " DARK MATTER")
	Kit.setText(dmSub, "shards x" .. string.format("%.2f", Econ.DarkMatterMult(dm)) .. "  ·  +" .. math.floor(BH.DMBonus * 100) .. "% each  ·  Black Holes: " .. holes)
	local k = math.clamp(have / BH.Need, 0, 1)
	fill.Size = UDim2.new(k, 0, 1, 0)
	fill.Visible = k > 0
	Kit.setText(barText, fmt(have) .. " / " .. fmt(BH.Need))
	-- (what the next one pays: with 100K it's 10; it grows with the square root)
	local next = if ready then gain else Econ.DarkMatterFor(BH.Need)
	Kit.setText(gainText, (if ready then "COLLAPSE NOW: +" else "AT 100K: +") .. next .. " DARK MATTER  (shards x" .. string.format("%.2f", Econ.DarkMatterMult(dm + next)) .. ")")
	Kit.recolour(goBtn, if ready then hex("#b98aff") else hex("#6a6474"), if ready then hex("#5a1fc2") else hex("#3f3a48"))
	Kit.setText(goText, if not ready then "NOT YET" elseif armed then "TAP AGAIN" else "COLLAPSE")
	local autoOpen = holes >= 1
	local on = player:GetAttribute("AutoSupernova") == true
	Kit.recolour(autoBtn, if not autoOpen then hex("#6a6474") elseif on then hex("#7dff7a") else hex("#5ad1ff"),
		if not autoOpen then hex("#3f3a48") elseif on then hex("#1fa83a") else hex("#1f6fd1"))
	Kit.setText(autoState, if not autoOpen then "AT BLACK HOLE 1" elseif on then "ON" else "OFF")
end
for _, a in ipairs({ "DarkMatter", "BlackHoles", "ShardsHole", "BlackHoleGain", "BlackHoleReady", "AutoSupernova" }) do
	player:GetAttributeChangedSignal(a):Connect(function() if holder.Visible then refresh() end end)
end

local isOpen = false
local function close()
	if not isOpen then return end
	isOpen = false
	armed = false
	Kit.sound("close")
	Kit.tween(hScale, { Scale = hScale.Scale * 0.85 }, 0.15)
	task.delay(0.15, function() if not isOpen then holder.Visible = false end end)
	if shared.GalaxySideWindow then shared.GalaxySideWindow("B", false) end
end
local function open()
	if isOpen then return end
	if shared.GalaxyCloseSide then shared.GalaxyCloseSide("B") end
	isOpen = true
	Kit.sound("open")
	refresh()
	holder.Visible = true
	if shared.GalaxySideWindow then shared.GalaxySideWindow("B", true) end
	local want = placeIn(holder, W, H)
	hScale.Scale = want * 0.8
	Kit.tween(hScale, { Scale = want }, 0.25, Enum.EasingStyle.Back)
end
shared.GalaxyBlackHoleToggle = function() if isOpen then close() else open() end end
shared.GalaxyBlackHoleClose = close
WM.register("B", holder, close)
closeBtn.MouseButton1Click:Connect(close)
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() if isOpen then hScale.Scale = placeIn(holder, W, H) end end)

------------------------------------------------------------------------ the WOAH moment (#299 #258)
-- the plaza's Black Hole gate: where the camera looks, and where the hole opens
local function gateSpot(): (Vector3?, Vector3?)
	local g = workspace:FindFirstChild("Galaxy")
	local centre = g and g:FindFirstChild("Centre")
	local hole = centre and centre:FindFirstChild("BlackHoleGate")
	if not hole then return nil end
	local cf = hole:GetAttribute("RingCF")
	local at = if typeof(cf) == "CFrame" then cf.Position else hole:GetBoundingBox().Position
	-- (the camera stands on the plaza side: from the gate toward the Core, flat)
	local core = centre:FindFirstChild("Core")
	local o = if core then core:GetPivot().Position else Vector3.zero
	local flat = Vector3.new(o.X - at.X, 0, o.Z - at.Z)
	return at, if flat.Magnitude > 0.1 then flat.Unit else Vector3.new(0, 0, 1)
end
local busy = false
local function collapse()
	if busy or player:GetAttribute("BlackHoleReady") ~= true then return end
	busy = true
	close()
	local holes = (player:GetAttribute("BlackHoles") or 0) + 1
	local gain = player:GetAttribute("BlackHoleGain") or 0
	local at, look = gateSpot()
	local fx
	local LEN, DROP = 9, 7
	-- (the sound, #258: a reversed Supernova: a low suck (the riser pitched down), the music + world fall silent, then the
	-- DARK PULSE (the boom an octave down))
	local suck = Kit.sound("windup", { pitch = 0.55, volume = 0.9 })
	local camera = nil
	if at and look then
		fx = Vfx.BlackHole(at, 1.4)
		camera = function(t: number)
			local away = look * (46 - 14 * t) + Vector3.new(0, 10 - 4 * t, 0)
			local turn = CFrame.Angles(0, t * 0.5, 0)
			local pos = at + (turn * CFrame.new(away)).Position
			return CFrame.lookAt(pos, at), at
		end
	end
	local ok, got
	Cutscene.play({ colour = VIOLET, symbol = Kit.A.icon.blackHole, length = LEN, drop = DROP, audio = false, camera = camera, world = camera ~= nil,
		words = { "EVERYTHING", "FALLS", "IN" }, title = "BLACK HOLE " .. holes, sub = "+" .. gain .. " DARK MATTER",
		onClimax = function()
			if suck then suck:Stop() end
			Kit.sound("boom", { pitch = 0.5, volume = 0.9 })
			ok, got = request:InvokeServer("BlackHole")
			if fx then fx:Pulse() end
			if at then
				Vfx.Ring(at, 60, Color3.fromRGB(60, 20, 110), 1.2, { alpha = false, mine = true })
				Vfx.Ring(at, 40, VIOLET, 0.9, { mine = true, delay = 0.2 })
			end
		end })
	if fx then task.delay(1.5, function() fx:Stop() end) end
	busy = false
	if ok then
		Kit.sound("milestone")
		if shared.GalaxyToast then shared.GalaxyToast("+" .. tostring(got) .. " DARK MATTER: shards x" .. string.format("%.2f", Econ.DarkMatterMult(player:GetAttribute("DarkMatter") or 0)), VIOLET) end
	else
		Kit.sound("error")
	end
end
goBtn.MouseButton1Click:Connect(function()
	if player:GetAttribute("BlackHoleReady") ~= true then Kit.sound("error") return end
	if not armed then
		armed = true
		Kit.sound("click")
		refresh()
		task.delay(3, function() if armed then armed = false refresh() end end)
		return
	end
	armed = false
	task.spawn(collapse)
end)
autoBtn.MouseButton1Click:Connect(function()
	local ok = request:InvokeServer("AutoToggle", "Supernova")
	Kit.sound(if ok then "click" else "error")
end)
