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
local PHONE_TEST = Kit.testDevice() ~= nil -- (Studio: Workspace TestDevice / TestPhone, UIKit)
local root: GuiObject | ScreenGui = Kit.testRoot(gui) -- (7 Nov: the safe area; Studio: the emulated device)
local function viewport(): Vector2
	return Kit.viewport(root)
end
local function screenScale(): number
	local vp = viewport()
	if vp.Y < 500 then return math.min(vp.X / 1000, vp.Y / 540) end
	return math.clamp(math.min(vp.X / 1280, vp.Y / 720), if Kit.touch() then 1 else 0.6, 1.4) -- (7 Nov: a TABLET never under 1, like GalaxyHUD)
end

local CW, CH, GAP = 214, 74, 8
-- (7 Nov, live: the phone HUD overlapped + the owner: the left column "looks like placeholders". ONE column, laid out by a
-- UIListLayout: the potions, the GIFT chip (GalaxyLive), FRIENDS / INVITE, GROUP, PREMIUM, BOOSTS; each social chip is the
-- kit's HUD chip (Kit.hudChip: a hotbar-style diamond icon tile + a text pill; the new art drops in there). PC: its bottom at
-- 80% of the screen, it grows upward. Phone: it hangs under the LVL / IGNITION row (GalaxyHUD shared.GalaxyColumnTop), short
-- labels, drawn at full size so the text is >= 14 px)
local PH = Kit.phone()
local strip = Kit.new("Frame", { Name = "Potions", BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0),
	AnchorPoint = if PH then Vector2.new(0, 0) else Vector2.new(0, 1) }, root)
strip:SetAttribute("UIAuditGroup", true)
Kit.new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, GAP), FillDirection = Enum.FillDirection.Vertical,
	VerticalAlignment = if PH then Enum.VerticalAlignment.Top else Enum.VerticalAlignment.Bottom }, strip)
local scale = Instance.new("UIScale")
scale.Parent = strip

local cards = {}
for i, p in ipairs(Econ.Potions) do
	local c = Kit.box(strip, 0, 0, CW, CH, { Name = p.id, Visible = false, LayoutOrder = i })
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
	Kit.text(c, 66, 6, 146, 24, p.name, 19, { ZIndex = 6, FontFace = Kit.FONT_HEAVY, stroke = 1.6 })
	-- how many you have: a small count chip on the icon
	local chip = Kit.box(c, 44, 46, 30, 22, { BackgroundTransparency = 0, BackgroundColor3 = Color3.new(1, 1, 1), ZIndex = 7 })
	Kit.corner(chip, 5)
	Kit.stroke(chip, Kit.INK, 2)
	Kit.grad(chip, hex("#ffd84a"), hex("#c79a0a"), 90)
	local count = Kit.text(chip, 0, 1, 30, 20, "1", 18, { ZIndex = 8, TextXAlignment = CENTRE, stroke = 1.3 })
	-- the timer while it runs
	local timer = Kit.text(c, 66, 38, 80, 26, "", 21, { ZIndex = 6, FontFace = Kit.FONT_HEAVY, stroke = 1.6, TextColor3 = hex("#ffd84a") })
	local use, useInner, _, useShadow = Kit.button(c, 146, 36, 58, 30, hex("#7dff7a"), hex("#1fa83a"), { ZIndex = 6 })
	Kit.text(useInner, 0, 4, 58, 22, "USE", 19, { ZIndex = useInner.ZIndex, TextXAlignment = CENTRE, FontFace = Kit.FONT_HEAVY, stroke = 1.6 })
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

-- the social chips + BOOSTS: the kit's HUD chip (order in the column: potions 1-9, GIFT 20, then these)
local CHIP_H, CHIP_TEXT = if PH then 34 else 40, if PH then 17 else 18
local function hudChip(name: string, colour: Color3, icon: string, order: number)
	local c = Kit.hudChip(strip, { name = name, colour = colour, icon = icon, height = CHIP_H, textSize = CHIP_TEXT, order = order })
	return c.button, c.text
end
shared.GalaxyHudChip = hudChip -- (GalaxyLive's GIFT chip: the same chip, in this column)
local friendsChip, friendsText = hudChip("Friends", hex("#7dff7a"), "stardust", 30)
local groupChip, groupText = hudChip("Group", hex("#ffd84a"), "stardust", 40)
-- (7 Nov: PREMIUM: Roblox Premium players get +10% stardust; others see it grey, a tap opens Roblox's Premium page (once a
-- session at most))
local premiumChip, premiumText = hudChip("Premium", hex("#ffb02a"), "stardust", 50)
-- (the FRIENDS chip IS the invite button now: a tap opens Roblox's invite prompt (SocialService) where you can send one;
-- the separate INVITE button was clipped on phones)
local SocialService = game:GetService("SocialService")
local canInvite = false
local refreshLater: (() -> ())? = nil -- (= refresh, once it exists below)
task.spawn(function()
	local ok, yes = pcall(function() return SocialService:CanSendGameInviteAsync(player) end)
	canInvite = ok and yes == true
	if refreshLater then refreshLater() end
end)
friendsChip.MouseButton1Click:Connect(function()
	if not canInvite then return end
	Kit.sound("click")
	local opts = Instance.new("ExperienceInviteOptions")
	opts.LaunchData = "invite:" .. player.UserId -- (who invited: the analytics can count invites that came back)
	pcall(function() SocialService:PromptGameInvite(player, opts) end)
end)
local function refreshSocial()
	local n = math.min(player:GetAttribute("FriendsHere") or 0, Econ.Social.FriendMax)
	-- (owner 6 Nov: shown at 0 too, greyed, as the invite hint)
	friendsChip:SetAttribute("Show", true)
	local per = math.floor(Econ.Social.FriendPer * 100 + 0.5)
	local max = Econ.Social.FriendMax
	if n > 0 then
		local pct = math.floor(n * Econ.Social.FriendPer * 100 + 0.5)
		Kit.setText(friendsText, if PH then "+" .. pct .. "% " .. n .. "/" .. max else "FRIENDS +" .. pct .. "% (" .. n .. "/" .. max .. ")")
		friendsText.TextColor3 = hex("#7dff7a")
	elseif canInvite then
		Kit.setText(friendsText, if PH then "INVITE" else "INVITE  +" .. per .. "% EACH")
		friendsText.TextColor3 = hex("#7dff7a")
	else
		Kit.setText(friendsText, if PH then "0/" .. max else "+" .. per .. "% PER FRIEND (0/" .. max .. ")")
		friendsText.TextColor3 = hex("#8f889c")
	end
	local inGroup = player:GetAttribute("InGroup") == true
	local gp = math.floor(Econ.Social.Group * 100 + 0.5)
	Kit.setText(groupText, if inGroup then (if PH then "+" .. gp .. "%" else "GROUP +" .. gp .. "%") else (if PH then "JOIN +" .. gp .. "%" else "JOIN GROUP FOR +" .. gp .. "%"))
	groupChip.Active = not inGroup
	local prem = player:GetAttribute("Premium") == true
	local pp = math.floor(Econ.Premium * 100 + 0.5)
	Kit.setText(premiumText, if prem then (if PH then "+" .. pp .. "%" else "PREMIUM +" .. pp .. "%") else (if PH then "PREMIUM" else "PREMIUM: +" .. pp .. "% STARDUST"))
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

------------------------------------------------------------------------ #144 the BOOSTS chip + #229 the ACTIVE BOOSTS list (Phase 2.7): the
-- column's last chip, "BOOSTS x2.30" (phone: "x2.30") = every boost of yours added together (#69: same kind adds); a tap
-- opens the list of each one with its timer, beside the column
local Galaxy2 = ReplicatedStorage:WaitForChild("Galaxy")
local bChip, bText = hudChip("Boosts", hex("#ffb02a"), "boosts", 60)
bText.TextColor3 = hex("#ffd84a")
local list = Kit.box(root, 0, 0, 250, 10, { Name = "BoostList", ZIndex = 10, Visible = false })
local listBg = Kit.box(list, 0, 0, 250, 10, { BackgroundTransparency = 0, BackgroundColor3 = hex("#0b090e"), ZIndex = 10 })
Kit.corner(listBg, 8)
Kit.stroke(listBg, hex("#ffb02a"), 2, 0.2)
local listLines = {}
for i = 1, 9 do
	listLines[i] = Kit.text(list, 12, 8 + (i - 1) * 24, 230, 22, "", 16, { ZIndex = 11, FontFace = Kit.FONT_BOLD, stroke = 1.2 })
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
	local x = "x" .. (string.format("%.2f", total):gsub("0+$", ""):gsub("%.$", ""))
	Kit.setText(bText, if PH then x else "BOOSTS " .. x)
	if list.Visible then
		local lines = boostLines()
		for i, l in ipairs(listLines) do Kit.setText(l, lines[i] or "") end
		listBg.Size = UDim2.fromOffset(250, 12 + #lines * 24)
		-- (beside the BOOSTS chip, right of the column, in the root's own units)
		local vp = viewport()
		local k = if root.AbsoluteSize.X > 0 then root.AbsoluteSize.X / vp.X else 1
		local at = (bChip.AbsolutePosition - root.AbsolutePosition) / k
		local w = bChip.AbsoluteSize.X / k
		list.Position = UDim2.fromOffset(math.floor(at.X + w + 8), math.floor(math.min(at.Y, vp.Y - (12 + #lines * 24) - 6)))
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
	if PH then
		-- (phone: full size (the chips are made for it), under GalaxyHUD's LVL / IGNITION row)
		scale.Scale = math.clamp(vp.Y / 375, 0.9, 1.1)
		local top = if shared.GalaxyColumnTop then shared.GalaxyColumnTop() else 96
		strip.Position = UDim2.fromOffset(8, top)
	else
		scale.Scale = s
		-- the column's bottom: 80% down the screen
		strip.Position = UDim2.fromOffset(math.floor(10 * s), math.floor(vp.Y * 0.8))
	end
end
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(layoutBoosts)
shared.GalaxyColumnLayout = layoutBoosts
layoutBoosts()
refreshBoosts()

-- (6 Nov overlap check: the strip covered the TREE window's left column; it hides while a window is open: GalaxyHUD calls this)
shared.GalaxyPotionsShow = function(on: boolean)
	strip.Visible = on
	if not on then list.Visible = false end
end

-- shown / hidden, counts (the column's UIListLayout places them)
local function refresh()
	for _, p in ipairs(Econ.Potions) do
		local c = cards[p.id]
		local n = player:GetAttribute("Potion_" .. p.id) or 0
		local running = (player:GetAttribute("BoostEnd_" .. p.id) or 0) > workspace:GetServerTimeNow()
		c.frame.Visible = n > 0 or running
		c.chip.Visible = n > 0
		Kit.setText(c.count, tostring(n))
		c.use.Visible = n > 0
		c.useShadow.Visible = n > 0
	end
	refreshSocial()
	local gift = strip:FindFirstChild("GiftChip")
	if gift then gift.Visible = gift:GetAttribute("Want") == true end
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
shared.GalaxyColumn = strip
shared.GalaxyColumnRefresh = refresh

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
