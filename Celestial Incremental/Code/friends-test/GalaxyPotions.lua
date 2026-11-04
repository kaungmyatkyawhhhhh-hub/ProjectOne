-- GalaxyPotions (Galaxy Incremental, overnight part 2, 3 Nov): the BOOST POTIONS on the HUD (design additions 3).
-- Left side, one v12 card per potion you have or have running: the potion icon, its name, how many you have, a green USE,
-- and the timer while it runs (a second one adds 15 min to the timer: they stack by time). Numbers: the server's
-- Potion_<id> (count) and BoostEnd_<id> (server time the boost ends) attributes; USE = EconRequest "UsePotion", id.
-- Social (Phase 1, 5 Nov; #394 #395): under the potions, a FRIENDS chip ("FRIENDS +20%", only with a friend in the server)
-- and a GROUP chip ("GROUP +10%", or "JOIN GROUP FOR +10%": a tap opens Roblox's join-group prompt). From the server's
-- FriendsHere / InGroup attributes.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local Econ = require(Galaxy:WaitForChild("EconConfig"))
local Kit = require(Galaxy:WaitForChild("UIKit"))
local request = Galaxy:WaitForChild("EconRequest") :: RemoteFunction
local hex = Kit.hex
local CENTRE = Enum.TextXAlignment.Center

while not player:GetAttribute("Loaded") do player:GetAttributeChangedSignal("Loaded"):Wait() end

local gui = Instance.new("ScreenGui")
gui.Name = "GalaxyPotions"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 1
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

local CW, CH, GAP = 214, 74, 10
local SH = 40 -- (the social chips' height)
local strip = Kit.box(root, 0, 0, CW, (CH + GAP) * #Econ.Potions + (SH + GAP) * 2, { Name = "Potions", AnchorPoint = Vector2.new(0, 0.5) })
local scale = Instance.new("UIScale")
scale.Parent = strip

local cards = {}
for i, p in ipairs(Econ.Potions) do
	local c = Kit.box(strip, 0, (i - 1) * (CH + GAP), CW, CH, { Name = p.id, Visible = false })
	local shadow = Kit.box(c, 0, 3, CW, CH, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 1 })
	Kit.corner(shadow, 8)
	local plate = Kit.box(c, 0, 0, CW, CH, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 2 })
	Kit.corner(plate, 8)
	Kit.stroke(plate, Kit.INK, 2)
	Kit.grad(plate, hex("#2a2433"), hex("#121016"), 90)
	local edge = Kit.box(c, 3, 3, CW - 6, CH - 6, { ZIndex = 3 })
	Kit.corner(edge, 6)
	Kit.stroke(edge, p.colour, 1.5, 0.3)
	Kit.box(c, 8, 4, CW - 16, 2, { BackgroundTransparency = 0.55, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3 })
	Kit.icon(c, p.icon, -10, -6, 78, p.colour, { ZIndex = 5 })
	Kit.text(c, 66, Kit.ps(8, 6), 146, 24, p.name, Kit.ps(17, 19), { ZIndex = 6, FontFace = Kit.FONT_HEAVY, stroke = 1.6 })
	-- how many you have: a small count chip on the icon
	local chip = Kit.box(c, 44, 46, 30, 22, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 7 })
	Kit.corner(chip, 5)
	Kit.stroke(chip, Kit.INK, 2)
	Kit.grad(chip, hex("#ffd84a"), hex("#c79a0a"), 90)
	local count = Kit.text(chip, 0, 1, 30, 20, "1", Kit.ps(15, 18), { ZIndex = 8, TextXAlignment = CENTRE, stroke = 1.3 })
	-- the timer while it runs
	local timer = Kit.text(c, 66, 38, 80, 26, "", 21, { ZIndex = 6, FontFace = Kit.FONT_HEAVY, stroke = 1.6, TextColor3 = hex("#ffd84a") })
	local use, useInner, _, useShadow = Kit.button(c, 146, 36, 58, 30, hex("#7dff7a"), hex("#1fa83a"), { ZIndex = 6 })
	Kit.text(useInner, 0, Kit.ps(5, 4), 58, 22, "USE", Kit.ps(17, 19), { ZIndex = useInner.ZIndex, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 1.6 })
	use.MouseButton1Click:Connect(function()
		Kit.sound("click")
		local ok = request:InvokeServer("UsePotion", p.id)
		if ok then
			Kit.sound("milestone")
			if shared.GalaxyToast then shared.GalaxyToast(p.name .. " ON: +" .. p.minutes .. " MIN", p.colour) end
		else
			Kit.sound("error")
		end
	end)
	cards[p.id] = { frame = c, count = count, chip = chip, timer = timer, use = use, useShadow = useShadow }
end

-- the social chips: the potion card's look at chip height (shadow, dark plate, coloured edge, shine, icon, heavy text)
local function socialChip(name: string, colour: Color3)
	local c = Kit.new("TextButton", { Name = name, Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromOffset(CW, SH), Visible = false }, strip)
	local shadow = Kit.box(c, 0, 3, CW, SH, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 1 })
	Kit.corner(shadow, 8)
	local plate = Kit.box(c, 0, 0, CW, SH, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 2 })
	Kit.corner(plate, 8)
	Kit.stroke(plate, Kit.INK, 2)
	Kit.grad(plate, hex("#2a2433"), hex("#121016"), 90)
	local edge = Kit.box(c, 3, 3, CW - 6, SH - 6, { ZIndex = 3 })
	Kit.corner(edge, 6)
	Kit.stroke(edge, colour, 1.5, 0.3)
	Kit.box(c, 8, 4, CW - 16, 2, { BackgroundTransparency = 0.55, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 3 })
	Kit.icon(c, "stardust", -4, -4, 48, colour, { ZIndex = 5 })
	local label, _, holder = Kit.text(c, 44, Kit.ps(9, 8), CW - 52, 22, "", 16, { ZIndex = 6, FontFace = Kit.FONT_HEAVY, stroke = 1.6, TextColor3 = colour, TextScaled = true })
	-- ("JOIN GROUP FOR +10%" is long: the text shrinks to fit, never over 17)
	for _, l in ipairs(holder:GetChildren()) do Kit.new("UITextSizeConstraint", { MaxTextSize = Kit.ps(16, 17) }, l) end
	return c, label
end
local friendsChip, friendsText = socialChip("Friends", hex("#7dff7a"))
local groupChip, groupText = socialChip("Group", hex("#ffd84a"))
local function refreshSocial()
	local n = math.min(player:GetAttribute("FriendsHere") or 0, Econ.Social.FriendMax)
	friendsChip:SetAttribute("Show", n > 0)
	Kit.setText(friendsText, "FRIENDS +" .. math.floor(n * Econ.Social.FriendPer * 100 + 0.5) .. "%")
	local inGroup = player:GetAttribute("InGroup") == true
	Kit.setText(groupText, if inGroup then "GROUP +" .. math.floor(Econ.Social.Group * 100 + 0.5) .. "%" else "JOIN GROUP FOR +" .. math.floor(Econ.Social.Group * 100 + 0.5) .. "%")
	groupChip.Active = not inGroup
end
groupChip.MouseButton1Click:Connect(function()
	if player:GetAttribute("InGroup") == true then return end
	Kit.sound("click")
	local ok, status = pcall(function() return game:GetService("GroupService"):PromptJoinAsync(Econ.Social.GroupId) end)
	if ok and (status == Enum.GroupMembershipStatus.Joined or status == Enum.GroupMembershipStatus.AlreadyMember) then
		if request:InvokeServer("CheckGroup") then
			Kit.sound("milestone")
			if shared.GalaxyToast then shared.GalaxyToast("GROUP BOOST ON: +10% STARDUST", hex("#ffd84a")) end
		end
	end
end)

local function layout()
	local s = screenScale()
	local vp = viewport()
	scale.Scale = s
	strip.Position = UDim2.fromOffset(math.floor(10 * s), math.floor(vp.Y * 0.5))
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(layout)
layout()

-- shown / hidden, counts, and the order (only the visible cards, packed from the top)
local function refresh()
	local y = 0
	for _, p in ipairs(Econ.Potions) do
		local c = cards[p.id]
		local n = player:GetAttribute("Potion_" .. p.id) or 0
		local running = (player:GetAttribute("BoostEnd_" .. p.id) or 0) > workspace:GetServerTimeNow()
		c.frame.Visible = n > 0 or running
		c.chip.Visible = n > 0
		Kit.setText(c.count, tostring(n))
		c.use.Visible = n > 0
		c.useShadow.Visible = n > 0
		if c.frame.Visible then
			c.frame.Position = UDim2.fromOffset(0, y)
			y += CH + GAP
		end
	end
	refreshSocial()
	for _, chip in ipairs({ friendsChip, groupChip }) do
		chip.Visible = chip ~= friendsChip or chip:GetAttribute("Show") == true
		if chip.Visible then
			chip.Position = UDim2.fromOffset(0, y)
			y += SH + GAP
		end
	end
end
player:GetAttributeChangedSignal("FriendsHere"):Connect(function() refresh() end)
player:GetAttributeChangedSignal("InGroup"):Connect(function() refresh() end)
for _, p in ipairs(Econ.Potions) do
	player:GetAttributeChangedSignal("Potion_" .. p.id):Connect(refresh)
	player:GetAttributeChangedSignal("BoostEnd_" .. p.id):Connect(refresh)
end
refresh()

-- the timers (mm:ss), and the card goes when a boost ends with none left
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 0.25 then return end
	acc = 0
	local now = workspace:GetServerTimeNow()
	local changed = false
	for _, p in ipairs(Econ.Potions) do
		local c = cards[p.id]
		local left = (player:GetAttribute("BoostEnd_" .. p.id) or 0) - now
		if left > 0 then
			Kit.setText(c.timer, string.format("%d:%02d", math.floor(left / 60), math.floor(left % 60)))
		else
			Kit.setText(c.timer, "")
			if c.frame.Visible and (player:GetAttribute("Potion_" .. p.id) or 0) == 0 then changed = true end
		end
	end
	if changed then refresh() end
end)
