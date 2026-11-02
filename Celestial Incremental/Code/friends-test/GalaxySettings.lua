-- GalaxySettings (Galaxy Incremental, alpha part 2, 3 Nov): the music loop + the SETTINGS window (key Q / the hotbar's Q).
--  * starts the one calm space loop (Galaxy.Sounds.Music) and sets the MUSIC / SOUND EFFECTS volumes from your save
--  * the SETTINGS window (the v12 frame, Kit.window): MUSIC and SOUND EFFECTS sliders (Kit.slider), heard while you drag;
--    saved on release (EconRequest "Settings", { music, sfx } -> the VolMusic / VolSfx attributes)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local Kit = require(Galaxy:WaitForChild("UIKit"))
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

------------------------------------------------------------------------ the window (520 x 260)
local W, H = 520, 260
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
local function save()
	task.spawn(function() request:InvokeServer("Settings", { music = musicVol, sfx = sfxVol }) end)
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

------------------------------------------------------------------------ open / close
local isOpen = false
local function place()
	local s = screenScale()
	local vp = viewport()
	local small = vp.Y < 500
	local top = 84 * s
	local room = (if small then vp.Y - 6 else vp.Y - 104 * s) - top
	local want = math.min(s, room / (H + 34), (vp.X - 24) / (W + 40))
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
closeBtn.MouseButton1Click:Connect(close)
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() if isOpen then scale.Scale = place() end end)
