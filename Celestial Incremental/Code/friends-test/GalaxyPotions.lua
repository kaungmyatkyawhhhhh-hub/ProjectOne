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
-- (7 Nov, owner: the boost chips go to the MIDDLE-BOTTOM LEFT, out of the way on PC and phone: one column, its bottom
-- fixed (BOOSTS at the bottom, the social chips + potions stacked above it, growing upward). See layoutBoosts)
local strip = Kit.box(root, 0, 0, CW, (CH + GAP) * #Econ.Potions + (SH + GAP) * 2, { Name = "Potions", AnchorPoint = Vector2.new(0, 1) })
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
-- (7 Nov: PREMIUM: Roblox Premium players get +10% stardust; others see it grey, a tap opens Roblox's Premium page (once a
-- session at most))
local premiumChip, premiumText = socialChip("Premium", hex("#ffb02a"))
-- (7 Nov: INVITE on the FRIENDS chip: Roblox's invite prompt (SocialService), only where the player can send invites)
local inviteBtn, inviteInner, _, inviteShadow = Kit.button(friendsChip, CW - 76, 6, 70, 28, hex("#7dff7a"), hex("#1fa83a"), { ZIndex = 7, Visible = false })
Kit.text(inviteInner, 0, Kit.ps(5, 4), 70, 20, "INVITE", Kit.ps(14, 16), { ZIndex = inviteInner.ZIndex, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 1.4 })
inviteShadow.Visible = false
local SocialService = game:GetService("SocialService")
local canInvite = false
local refreshLater: (() -> ())? = nil -- (= refresh, once it exists below)
task.spawn(function()
	local ok, yes = pcall(function() return SocialService:CanSendGameInviteAsync(player) end)
	canInvite = ok and yes == true
	inviteBtn.Visible = canInvite
	inviteShadow.Visible = canInvite
	-- (the label makes room for the button)
	if canInvite then (friendsText.Parent :: GuiObject).Size = UDim2.fromOffset(CW - 52 - 78, 22) end
	if refreshLater then refreshLater() end
end)
inviteBtn.MouseButton1Click:Connect(function()
	Kit.sound("click")
	local opts = Instance.new("ExperienceInviteOptions")
	opts.LaunchData = "invite:" .. player.UserId -- (who invited: the analytics can count invites that came back)
	pcall(function() SocialService:PromptGameInvite(player, opts) end)
end)
local function refreshSocial()
	local n = math.min(player:GetAttribute("FriendsHere") or 0, Econ.Social.FriendMax)
	-- (owner 6 Nov: shown at 0 too, greyed, as the invite hint: "+10% PER FRIEND (0/3)")
	friendsChip:SetAttribute("Show", true)
	local per = math.floor(Econ.Social.FriendPer * 100 + 0.5)
	if n > 0 then
		Kit.setText(friendsText, "FRIENDS +" .. math.floor(n * Econ.Social.FriendPer * 100 + 0.5) .. "% (" .. n .. "/" .. Econ.Social.FriendMax .. ")")
		friendsText.TextColor3 = hex("#7dff7a")
	else
		-- (with the INVITE button beside it the hint is shorter)
		Kit.setText(friendsText, "+" .. per .. (if canInvite then "% EACH (0/" else "% PER FRIEND (0/") .. Econ.Social.FriendMax .. ")")
		friendsText.TextColor3 = hex("#8f889c")
	end
	local inGroup = player:GetAttribute("InGroup") == true
	Kit.setText(groupText, if inGroup then "GROUP +" .. math.floor(Econ.Social.Group * 100 + 0.5) .. "%" else "JOIN GROUP FOR +" .. math.floor(Econ.Social.Group * 100 + 0.5) .. "%")
	groupChip.Active = not inGroup
	local prem = player:GetAttribute("Premium") == true
	Kit.setText(premiumText, if prem then "PREMIUM +" .. math.floor(Econ.Premium * 100 + 0.5) .. "%" else "PREMIUM: +" .. math.floor(Econ.Premium * 100 + 0.5) .. "% STARDUST")
	premiumText.TextColor3 = if prem then hex("#ffb02a") else hex("#8f889c")
	premiumChip.Active = not prem
end
local premiumAsked = false
premiumChip.MouseButton1Click:Connect(function()
	if player:GetAttribute("Premium") == true or premiumAsked then return end
	premiumAsked = true
	Kit.sound("click")
	pcall(function() game:GetService("MarketplaceService"):PromptPremiumPurchase(player) end)
end)
local function promptGroup()
	local ok, status = pcall(function() return game:GetService("GroupService"):PromptJoinAsync(Econ.Social.GroupId) end)
	if ok and (status == Enum.GroupMembershipStatus.Joined or status == Enum.GroupMembershipStatus.AlreadyMember) then
		if request:InvokeServer("CheckGroup") then
			Kit.sound("milestone")
			if shared.GalaxyToast then shared.GalaxyToast("GROUP BOOST ON: +10% STARDUST", hex("#ffd84a")) end
		end
	end
end
groupChip.MouseButton1Click:Connect(function()
	if player:GetAttribute("InGroup") == true then return end
	Kit.sound("click")
	promptGroup()
end)
-- (owner 6 Nov: the JOIN GROUP prompt comes by itself ONCE, after the first Supernova of this session's player (never on
-- join), when the cinematic is over; whatever the answer, it never comes by itself again (the save remembers). The chip
-- still opens it on a tap)
local novasSeen = player:GetAttribute("Supernovas") or 0
player:GetAttributeChangedSignal("Supernovas"):Connect(function()
	local now = player:GetAttribute("Supernovas") or 0
	local up = now > novasSeen
	novasSeen = now
	if not up or player:GetAttribute("GroupPrompted") == true or player:GetAttribute("InGroup") == true then return end
	task.spawn(function()
		task.wait(1)
		while shared.GalaxyCinematic do task.wait(0.5) end
		task.wait(2.5)
		if player:GetAttribute("GroupPrompted") == true or player:GetAttribute("InGroup") == true then return end
		request:InvokeServer("Settings", { groupPrompt = true })
		promptGroup()
	end)
end)

local function layout()
	local s = screenScale()
	local vp = viewport()
	-- (phones: the column is a bit smaller, so a running potion doesn't push it up into the top HUD)
	scale.Scale = if vp.Y < 500 then s * 0.82 else s
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(layout)
------------------------------------------------------------------------ #144 the BOOSTS chip + #229 the ACTIVE BOOSTS list (Phase 2.7): on the
-- right, "BOOSTS x2.30" = every boost of yours added together (#69: same kind adds); a tap opens the list of each one with its
-- timer (the pass, the potions, the Star Surge, friends, group)
local Galaxy2 = ReplicatedStorage:WaitForChild("Galaxy")
local boostRoot = Kit.box(root, 0, 0, 230, 40, { Name = "Boosts", AnchorPoint = Vector2.new(0, 1) })
local bScale = Instance.new("UIScale")
bScale.Parent = boostRoot
local bChip = Kit.new("TextButton", { Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromOffset(230, 40), ZIndex = 9 }, boostRoot)
do
	local sh = Kit.box(boostRoot, 0, 3, 230, 40, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 1 })
	Kit.corner(sh, 8)
	local plate = Kit.box(boostRoot, 0, 0, 230, 40, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 2 })
	Kit.corner(plate, 8)
	Kit.stroke(plate, Kit.INK, 2)
	Kit.grad(plate, hex("#2a2433"), hex("#121016"), 90)
	local edge = Kit.box(boostRoot, 3, 3, 224, 34, { ZIndex = 3 })
	Kit.corner(edge, 6)
	Kit.stroke(edge, hex("#ffb02a"), 1.5, 0.3)
	Kit.icon(boostRoot, "boosts", -4, -4, 48, Color3.fromRGB(255, 170, 60), { ZIndex = 5 })
end
local bText = Kit.text(boostRoot, 44, Kit.ps(9, 8), 180, 22, "BOOSTS x1", Kit.ps(16, 17), { ZIndex = 6, FontFace = Kit.FONT_HEAVY, stroke = 1.6, TextColor3 = hex("#ffd84a") })
local list = Kit.box(boostRoot, 0, 48, 230, 10, { ZIndex = 10, Visible = false })
local listBg = Kit.box(list, 0, 0, 230, 10, { BackgroundTransparency = 0, BackgroundColor3 = hex("#0b090e"), ZIndex = 10 })
Kit.corner(listBg, 8)
Kit.stroke(listBg, hex("#ffb02a"), 2, 0.2)
local listLines = {}
for i = 1, 9 do
	listLines[i] = Kit.text(list, 12, 8 + (i - 1) * 24, 210, 22, "", Kit.ps(14, 16), { ZIndex = 11, FontFace = Kit.FONT_BOLD, stroke = 1.2 })
end
local function boostLines(): { string }
	local out = {}
	local now = workspace:GetServerTimeNow()
	local function mmss(t) t = math.max(0, math.floor(t)) return string.format("%d:%02d", t // 60, t % 60) end
	if player:GetAttribute("Pass_X2Stardust") == true then table.insert(out, "x2 STARDUST PASS  +1x  forever") end
	if player:GetAttribute("Pass_VIP") == true then table.insert(out, "VIP  +" .. math.floor(Econ.VIP.stardust * 100 + 0.5) .. "%  +" .. math.floor(Econ.VIP.shards * 100 + 0.5) .. "% SHARDS") end
	if player:GetAttribute("Premium") == true then table.insert(out, "PREMIUM  +" .. math.floor(Econ.Premium * 100 + 0.5) .. "%") end
	local evEnds = Galaxy2:GetAttribute("EventEnds") or 0
	if evEnds > workspace:GetServerTimeNow() and (Galaxy2:GetAttribute("EventStardust") or 0) > 0 then
		table.insert(out, tostring(Galaxy2:GetAttribute("EventTitle")) .. "  " .. mmss(evEnds - workspace:GetServerTimeNow()))
	end
	for _, p in ipairs(Econ.Potions) do
		local left = (player:GetAttribute("BoostEnd_" .. p.id) or 0) - now
		if left > 0 then table.insert(out, p.name .. " POTION  " .. mmss(left)) end
	end
	local surge = (Galaxy2:GetAttribute("SurgeUntil") or 0) - now
	if surge > 0 then table.insert(out, "STAR SURGE  +1x  " .. mmss(surge)) end
	local friends = math.min(player:GetAttribute("FriendsHere") or 0, Econ.Social.FriendMax)
	if friends > 0 then table.insert(out, "FRIENDS HERE  +" .. math.floor(friends * Econ.Social.FriendPer * 100 + 0.5) .. "%") end
	if player:GetAttribute("InGroup") == true then table.insert(out, "GROUP  +" .. math.floor(Econ.Social.Group * 100 + 0.5) .. "%") end
	if #out == 0 then table.insert(out, "No boosts right now") end
	return out
end
local function refreshBoosts()
	local total = player:GetAttribute("BoostTotal") or 1
	Kit.setText(bText, "BOOSTS x" .. (string.format("%.2f", total):gsub("0+$", ""):gsub("%.$", "")))
	if list.Visible then
		local lines = boostLines()
		for i, l in ipairs(listLines) do Kit.setText(l, lines[i] or "") end
		listBg.Size = UDim2.fromOffset(230, 12 + #lines * 24)
		list.Position = UDim2.fromOffset(0, -(12 + #lines * 24) - 8) -- (it opens UPWARD: the chip is at the bottom of the column)
	end
end
bChip.MouseButton1Click:Connect(function()
	Kit.sound("tab")
	list.Visible = not list.Visible
	refreshBoosts()
end)
player:GetAttributeChangedSignal("BoostTotal"):Connect(refreshBoosts)
task.spawn(function()
	while true do
		task.wait(1)
		refreshBoosts()
	end
end)
local function layoutBoosts()
	local s = screenScale()
	local vp = viewport()
	local cs = if vp.Y < 500 then s * 0.82 else s
	bScale.Scale = cs
	scale.Scale = cs
	-- the column's bottom: 80% down the screen on PC, 74% on a phone (above the move thumbstick's corner); BOOSTS there,
	-- the potions + social chips right above it
	local bottom = math.floor(vp.Y * (if vp.Y < 500 then 0.74 else 0.8))
	boostRoot.Position = UDim2.fromOffset(math.floor(10 * s), bottom)
	strip.Position = UDim2.fromOffset(math.floor(10 * s), bottom - math.floor((40 + GAP) * cs))
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(layoutBoosts)
layoutBoosts()
refreshBoosts()

-- (6 Nov overlap check: the strip covered the TREE window's left column; it hides while a window is open: GalaxyHUD calls this)
shared.GalaxyPotionsShow = function(on: boolean)
	strip.Visible = on
	boostRoot.Visible = on
	if not on then list.Visible = false end
end
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
	for _, chip in ipairs({ friendsChip, groupChip, premiumChip }) do
		chip.Visible = chip ~= friendsChip or chip:GetAttribute("Show") == true
		if chip.Visible then
			chip.Position = UDim2.fromOffset(0, y)
			y += SH + GAP
		end
	end
	-- (the column's bottom is fixed: its height = what's in it, so it grows upward)
	strip.Size = UDim2.fromOffset(CW, math.max(1, y - GAP))
end
player:GetAttributeChangedSignal("FriendsHere"):Connect(function() refresh() end)
player:GetAttributeChangedSignal("InGroup"):Connect(function() refresh() end)
player:GetAttributeChangedSignal("Premium"):Connect(function() refresh() end)
for _, p in ipairs(Econ.Potions) do
	player:GetAttributeChangedSignal("Potion_" .. p.id):Connect(refresh)
	player:GetAttributeChangedSignal("BoostEnd_" .. p.id):Connect(refresh)
end
refresh()
refreshLater = refresh

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
