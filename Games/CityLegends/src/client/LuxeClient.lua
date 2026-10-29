--[[
	LuxeClient
	The High-Rollers Casino and the Legends Gem Showcase on screen (server: Luxe, Casino,
	GemShowcase):
	  * the Gem Showcase's shop (the concierge desk): pieces by slot with a 3D preview, the price
	    (VIP money off), BUY / WEAR / TAKE OFF
	  * the VIP desk: the Gold, Platinum and Black cards, what each gives, BUY / UPGRADE
	  * heist messages (robbery under way, lasers down, grabs, bag full)
	  * the buildings' effects, run on each client: the marquee's chasing bulbs, the stage's moving
	    lights, the turning gems, and the VIP lounge's gate (members walk through it)
	The server decides everything; this only asks and shows.
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Flex = require(Shared:WaitForChild("Flex"))
local UI = require(script.Parent:WaitForChild("UI"))
local Audio = require(script.Parent:WaitForChild("Audio"))

local L = Config.Luxe
local Theme = Config.Theme
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local LuxeClient = {}

local C = {
	bg = Color3.fromRGB(10, 9, 12),
	card = Color3.fromRGB(22, 20, 26),
	cardHi = Color3.fromRGB(32, 28, 36),
	stroke = Color3.fromRGB(70, 58, 40),
	gold = Color3.fromRGB(232, 190, 96),
	text = Color3.fromRGB(240, 236, 228),
	sub = Color3.fromRGB(150, 142, 130),
	green = Color3.fromRGB(74, 222, 128),
}
local SLOT_NAMES = { Neck = "NECKLACES", Wrist = "WATCHES", Hand = "RINGS", Ears = "EARRINGS", Eyes = "SHADES", Head = "CROWNS" }

type State = { vip: number, owned: { string }, worn: { [string]: string }, discount: number }
local state: State = { vip = 0, owned = {}, worn = {}, discount = 0 }
local ownedSet: { [string]: boolean } = {}
local call: RemoteFunction

local function new(className: string, props: { [string]: any }?, children: { Instance }?): any
	local inst = Instance.new(className)
	local parent = nil
	if props then
		for k, v in props do
			if k == "Parent" then
				parent = v
			else
				(inst :: any)[k] = v
			end
		end
	end
	if children then
		for _, c in children do
			c.Parent = inst
		end
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end
local function corner(r: number): UICorner
	return new("UICorner", { CornerRadius = UDim.new(0, r) })
end
local function stroke(color: Color3, t: number?, tr: number?): UIStroke
	return new("UIStroke", { Color = color, Thickness = t or 1, Transparency = tr or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end
local function label(props: { [string]: any }): TextLabel
	local base = {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextColor3 = C.text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = "",
	}
	for k, v in props do
		base[k] = v
	end
	return new("TextLabel", base)
end
local function button(props: { [string]: any }): TextButton
	local base = {
		AutoButtonColor = true,
		BackgroundColor3 = C.gold,
		Font = Enum.Font.GothamBlack,
		TextColor3 = Color3.fromRGB(24, 18, 8),
		TextSize = 14,
		Text = "",
	}
	for k, v in props do
		base[k] = v
	end
	local b = new("TextButton", base)
	corner(8).Parent = b
	return b
end

local function cash(): number
	local stats = player:FindFirstChild("leaderstats")
	local v = stats and stats:FindFirstChild("Cash")
	return if v and v:IsA("IntValue") then v.Value else 0
end

local function setState(s: any)
	if type(s) ~= "table" then
		return
	end
	state = s
	ownedSet = {}
	for _, id in s.owned or {} do
		ownedSet[id] = true
	end
	-- the VIP gate: members walk through it (on their own client)
	for _, g in CollectionService:GetTagged("VipGate") do
		if g:IsA("BasePart") then
			g.CanCollide = (state.vip or 0) < 1
		end
	end
end
-- (streaming: the gate can arrive after the state did)
CollectionService:GetInstanceAddedSignal("VipGate"):Connect(function(g)
	if g:IsA("BasePart") then
		g.CanCollide = (state.vip or 0) < 1
	end
end)

local function priceOf(it: Flex.Item): number
	return math.floor(it.price * (1 - (state.discount or 0)))
end

---------------------------------------------------------------------
-- The window frame both screens use
---------------------------------------------------------------------
local gui: ScreenGui
local openPanel: Frame? = nil
local openedAt: Vector3? = nil

local function closePanel()
	if openPanel then
		openPanel:Destroy()
		openPanel = nil
	end
	openedAt = nil
end

local function window(title: string, subtitle: string, accent: Color3): (Frame, Frame, TextLabel)
	closePanel()
	local panel = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromScale(0.92, 0.82),
		BackgroundColor3 = C.bg,
		BackgroundTransparency = 0.04,
		Parent = gui,
	}, { corner(16), stroke(accent, 1.5, 0.2), new("UISizeConstraint", { MaxSize = Vector2.new(880, 560) }) })
	label({ Text = title, Font = Enum.Font.Garamond, TextSize = 30, TextColor3 = accent, Position = UDim2.fromOffset(22, 12), Size = UDim2.new(1, -200, 0, 34), Parent = panel })
	label({ Text = subtitle, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.sub, Position = UDim2.fromOffset(22, 46), Size = UDim2.new(1, -200, 0, 18), Parent = panel })
	local cashLabel = label({ Text = UI.formatCash(cash()), Font = Enum.Font.RobotoMono, TextSize = 18, TextColor3 = Theme.Money, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -66, 0, 18), Size = UDim2.fromOffset(200, 24), Parent = panel })
	local close = button({ Text = "×", BackgroundColor3 = C.cardHi, TextColor3 = C.text, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -16, 0, 14), Size = UDim2.fromOffset(36, 32), Parent = panel })
	close.Activated:Connect(closePanel)
	local body = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 76), Size = UDim2.new(1, -32, 1, -92), Parent = panel })
	openPanel = panel
	local character = player.Character
	local hrp = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
	openedAt = if hrp then hrp.Position else nil
	return panel, body, cashLabel
end

local function refreshCash(cashLabel: TextLabel)
	cashLabel.Text = UI.formatCash(cash())
end

---------------------------------------------------------------------
-- 3D previews of the pieces
---------------------------------------------------------------------
local function preview(parent: Instance, it: Flex.Item)
	local vp = new("ViewportFrame", {
		BackgroundColor3 = Color3.fromRGB(16, 14, 20),
		Size = UDim2.new(1, -12, 0, 110),
		Position = UDim2.fromOffset(6, 6),
		Ambient = Color3.fromRGB(150, 140, 130),
		LightColor = Color3.fromRGB(255, 240, 220),
		LightDirection = Vector3.new(-0.4, -1, -0.6),
		Parent = parent,
	}, { corner(10) })
	local world = Instance.new("Model")
	-- what it sits on: a bust, a head, a wrist
	local size: Vector3
	local stand = Instance.new("Part")
	stand.Color = Color3.fromRGB(26, 22, 34)
	stand.Material = Enum.Material.Fabric
	stand.Anchored = true
	if it.slot == "Neck" then
		size = Vector3.new(2, 1.6, 1)
		stand.Size = size
	elseif it.slot == "Wrist" or it.slot == "Hand" then
		size = if it.slot == "Wrist" then Vector3.new(0.7, 1, 0.7) else Vector3.new(0.5, 0.6, 0.3)
		stand.Size = Vector3.new(size.X * 0.95, 1.6, size.Z * 0.95)
	else
		size = Vector3.new(1.2, 1.2, 1.2)
		stand.Shape = Enum.PartType.Ball
		stand.Size = size
	end
	stand.CFrame = CFrame.new()
	stand.Parent = world
	local m = Flex.build(it, size)
	m.Parent = world
	world.Parent = vp
	local cf, ext = m:GetBoundingBox()
	local reach = math.max(ext.X, ext.Y, ext.Z)
	local cam = Instance.new("Camera")
	local eye = cf.Position + Vector3.new(reach * 0.35, reach * 0.35, -reach * 1.5)
	cam.CFrame = CFrame.lookAt(eye, cf.Position)
	cam.FieldOfView = 40
	cam.Parent = vp
	vp.CurrentCamera = cam
end

---------------------------------------------------------------------
-- The Gem Showcase's shop
---------------------------------------------------------------------
local shopSlot = "Neck"

local function openShop()
	local _, body, cashLabel = window("LEGENDS GEM SHOWCASE", if (state.discount or 0) > 0 then string.format("The collection  ·  your VIP card takes %d%% off", math.floor(state.discount * 100 + 0.5)) else "The collection  ·  VIP members pay less (casino VIP desk)", C.gold)
	local tabs = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0, 132, 1, 0), Parent = body }, {
		new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local list = new("ScrollingFrame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(144, 0),
		Size = UDim2.new(1, -144, 1, 0),
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = C.gold,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BorderSizePixel = 0,
		Parent = body,
	}, {
		new("UIGridLayout", { CellSize = UDim2.fromOffset(172, 206), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
	})

	local renderCards: () -> ()
	local function act(what: string, arg: any)
		local ok, res = pcall(function()
			return call:InvokeServer(what, arg)
		end)
		if not ok or type(res) ~= "table" then
			return
		end
		if res.state then
			setState(res.state)
		end
		if res.ok then
			if what == "buy" then
				UI.toast("Bought for " .. UI.formatCash(res.cost or 0) .. ": you're wearing it", C.gold)
				Audio.cutUp(3, "FLEX")
			end
		elseif res.message then
			UI.toast(res.message, Theme.Warning)
		end
		refreshCash(cashLabel)
		renderCards()
	end

	renderCards = function()
		for _, c in list:GetChildren() do
			if c:IsA("Frame") then
				c:Destroy()
			end
		end
		local order = 0
		for _, raw in L.Items do
			local it = raw :: any
			if it.slot ~= shopSlot then
				continue
			end
			order += 1
			local owned = ownedSet[it.id] == true
			local wearing = state.worn and state.worn[it.slot] == it.id
			local card = new("Frame", { BackgroundColor3 = C.card, LayoutOrder = order, Parent = list }, { corner(12), stroke(if wearing then C.gold else C.stroke, if wearing then 2 else 1) })
			preview(card, it)
			label({ Text = it.name, Position = UDim2.fromOffset(10, 122), Size = UDim2.new(1, -20, 0, 18), TextSize = 13, Parent = card })
			local price = priceOf(it)
			label({
				Text = if owned then "IN YOUR COLLECTION" else UI.formatCash(price),
				Font = Enum.Font.RobotoMono,
				TextColor3 = if owned then C.green else C.gold,
				TextSize = 13,
				Position = UDim2.fromOffset(10, 142),
				Size = UDim2.new(1, -20, 0, 16),
				Parent = card,
			})
			if not owned and price < it.price then
				label({ Text = UI.formatCash(it.price), Font = Enum.Font.RobotoMono, TextColor3 = C.sub, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.fromOffset(10, 142), Size = UDim2.new(1, -20, 0, 16), Parent = card })
			end
			local b = button({ Position = UDim2.new(0, 10, 1, -40), Size = UDim2.new(1, -20, 0, 30), Parent = card })
			if wearing then
				b.Text = "TAKE OFF"
				b.BackgroundColor3 = C.cardHi
				b.TextColor3 = C.text
				b.Activated:Connect(function()
					act("remove", it.slot)
				end)
			elseif owned then
				b.Text = "WEAR"
				b.Activated:Connect(function()
					act("wear", it.id)
				end)
			else
				b.Text = "BUY"
				if cash() < price then
					b.BackgroundColor3 = Color3.fromRGB(70, 60, 44)
					b.TextColor3 = C.sub
				end
				b.Activated:Connect(function()
					act("buy", it.id)
				end)
			end
		end
	end

	local tabButtons: { [string]: TextButton } = {}
	local function paintTabs()
		for slot, b in tabButtons do
			b.BackgroundColor3 = if slot == shopSlot then C.gold else C.card
			b.TextColor3 = if slot == shopSlot then Color3.fromRGB(24, 18, 8) else C.text
		end
	end
	for k, slot in L.Slots do
		local b = button({ Text = SLOT_NAMES[slot] or slot, LayoutOrder = k, Size = UDim2.new(1, 0, 0, 38), TextSize = 13, Parent = tabs })
		tabButtons[slot] = b
		b.Activated:Connect(function()
			shopSlot = slot
			paintTabs()
			renderCards()
		end)
	end
	paintTabs()
	renderCards()
end

---------------------------------------------------------------------
-- The VIP desk
---------------------------------------------------------------------
local function openVip()
	local _, body, cashLabel = window("HIGH-ROLLERS VIP", "Membership cards  ·  in-game cash only  ·  a higher card costs the difference", Color3.fromRGB(200, 150, 255))
	local row = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = body }, {
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 12), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local render: () -> ()
	render = function()
		for _, c in row:GetChildren() do
			if c:IsA("Frame") then
				c:Destroy()
			end
		end
		local current = L.Vip[state.vip or 0]
		for k, tier in L.Vip do
			local card = new("Frame", { BackgroundColor3 = C.card, LayoutOrder = k, Size = UDim2.new(1 / 3, -8, 1, 0), Parent = row }, { corner(14), stroke(tier.color, if (state.vip or 0) == tier.id then 2.5 else 1, 0.1) })
			-- the card itself
			local face = new("Frame", { BackgroundColor3 = tier.color, Position = UDim2.fromOffset(12, 12), Size = UDim2.new(1, -24, 0, 96), Parent = card }, {
				corner(10),
				new("UIGradient", { Color = ColorSequence.new(tier.color, tier.color:Lerp(Color3.new(0, 0, 0), 0.55)), Rotation = 35 }),
			})
			label({ Text = "HIGH-ROLLERS", Font = Enum.Font.Garamond, TextSize = 16, TextColor3 = Color3.fromRGB(20, 16, 10), Position = UDim2.fromOffset(12, 8), Size = UDim2.new(1, -24, 0, 18), Parent = face })
			label({ Text = tier.name, Font = Enum.Font.GothamBlack, TextSize = 18, TextColor3 = Color3.new(1, 1, 1), Position = UDim2.new(0, 12, 1, -30), Size = UDim2.new(1, -24, 0, 22), Parent = face })
			local perks = {
				"Title over your head:\n◆ " .. tier.title .. " ◆",
				"The casino's VIP lounge",
				string.format("%d%% off at the Gem Showcase", math.floor(tier.discount * 100 + 0.5)),
			}
			label({
				Text = table.concat(perks, "\n\n"),
				TextWrapped = true,
				TextTruncate = Enum.TextTruncate.None,
				TextYAlignment = Enum.TextYAlignment.Top,
				Font = Enum.Font.GothamMedium,
				TextSize = 13,
				TextColor3 = C.text,
				Position = UDim2.fromOffset(14, 120),
				Size = UDim2.new(1, -28, 1, -186),
				Parent = card,
			})
			local cost = tier.price - (if current then current.price else 0)
			local b = button({ Position = UDim2.new(0, 12, 1, -50), Size = UDim2.new(1, -24, 0, 38), BackgroundColor3 = tier.color, Parent = card })
			if (state.vip or 0) >= tier.id then
				b.Text = if (state.vip or 0) == tier.id then "YOUR CARD" else "INCLUDED"
				b.BackgroundColor3 = C.cardHi
				b.TextColor3 = C.sub
			else
				b.Text = (if current then "UPGRADE  " else "BUY  ") .. UI.formatCash(cost)
				b.Activated:Connect(function()
					local ok, res = pcall(function()
						return call:InvokeServer("vip", tier.id)
					end)
					if ok and type(res) == "table" then
						if res.state then
							setState(res.state)
						end
						if res.ok then
							UI.toast("Welcome, " .. tier.title, tier.color)
							Audio.cutUp(4, "VIP")
						elseif res.message then
							UI.toast(res.message, Theme.Warning)
						end
					end
					refreshCash(cashLabel)
					render()
				end)
			end
		end
	end
	render()
end

---------------------------------------------------------------------
-- Effects on the buildings
---------------------------------------------------------------------
local function tracked(tag: string): { Instance }
	local list = CollectionService:GetTagged(tag)
	CollectionService:GetInstanceAddedSignal(tag):Connect(function(inst)
		table.insert(list, inst)
		if tag == "VipGate" and inst:IsA("BasePart") then
			inst.CanCollide = (state.vip or 0) < 1
		end
	end)
	CollectionService:GetInstanceRemovedSignal(tag):Connect(function(inst)
		local i = table.find(list, inst)
		if i then
			table.remove(list, i)
		end
	end)
	return list
end

local function startEffects()
	local marquee = tracked("Marquee")
	local spots = tracked("CasinoSpot")
	local gems = tracked("SpinGem")
	local gates = tracked("VipGate")
	local BULB_ON = Color3.fromRGB(255, 226, 170)
	local BULB_OFF = Color3.fromRGB(90, 60, 30)
	local lastStep = -1
	local gateWarned = false
	RunService.Heartbeat:Connect(function()
		local now = workspace:GetServerTimeNow()
		local camPos = camera.CFrame.Position
		-- the marquee's bulbs chase round the sign (10 Hz)
		local step = math.floor(now * 10)
		if step ~= lastStep then
			lastStep = step
			for _, b in marquee do
				if b:IsA("BasePart") then
					local i = (b:GetAttribute("Index") :: number?) or 0
					local on = (i + step) % 4 < 2
					b.Color = if on then BULB_ON else BULB_OFF
				end
			end
		end
		-- the stage's moving heads sweep and change colour
		for _, h in spots do
			if h:IsA("BasePart") and (h.Position - camPos).Magnitude < 350 then
				local home = h:GetAttribute("Home") :: CFrame?
				local phase = (h:GetAttribute("Phase") :: number?) or 0
				if home then
					h.CFrame = home * CFrame.Angles(math.sin(now * 0.9 + phase) * 0.7, 0, math.cos(now * 0.7 + phase * 1.3) * 0.7)
					local beam = h:FindFirstChild("Beam")
					if beam and beam:IsA("SpotLight") then
						beam.Color = Color3.fromHSV((now * 0.06 + phase * 0.12) % 1, 0.75, 1)
					end
				end
			end
		end
		-- the gems turn
		for _, g in gems do
			if g:IsA("BasePart") and (g.Position - camPos).Magnitude < 500 then
				local home = g:GetAttribute("Home") :: CFrame?
				if home then
					g.CFrame = CFrame.new(home.Position + Vector3.new(0, math.sin(now * 1.4) * 0.3, 0)) * CFrame.Angles(0, now * 0.7, 0) * home.Rotation
				end
			end
		end
		-- the VIP gate: a word for non-members who walk up to it
		if (state.vip or 0) < 1 then
			local character = player.Character
			local hrp = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
			local near = false
			if hrp then
				for _, g in gates do
					if g:IsA("BasePart") and (g.Position - hrp.Position).Magnitude < 9 then
						near = true
					end
				end
			end
			if near and not gateWarned then
				UI.toast("VIP members only: buy a card at the VIP desk", Color3.fromRGB(200, 150, 255))
			end
			gateWarned = near
		end
		-- walking away closes the shop
		if openPanel and openedAt then
			local character = player.Character
			local hrp = if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
			if not hrp or (hrp.Position - openedAt).Magnitude > 24 then
				closePanel()
			end
		end
	end)
end

---------------------------------------------------------------------
function LuxeClient.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	call = remotes:WaitForChild("LuxeCall") :: RemoteFunction
	local event = remotes:WaitForChild("LuxeEvent") :: RemoteEvent

	gui = Instance.new("ScreenGui")
	gui.Name = "LuxeUI"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 14
	gui.Parent = player:WaitForChild("PlayerGui")

	task.spawn(function()
		local ok, res = pcall(function()
			return call:InvokeServer("state")
		end)
		if ok and type(res) == "table" then
			setState(res.state)
		end
	end)
	startEffects()

	event.OnClientEvent:Connect(function(info)
		if type(info) ~= "table" then
			return
		end
		local kind = info.kind
		if kind == "openShop" then
			openShop()
		elseif kind == "openVip" then
			openVip()
		elseif kind == "casinoRobbery" then
			UI.toast(`{info.by} is robbing the High-Rollers Casino vault!`, Theme.Danger)
		elseif kind == "gemsRobbery" then
			UI.toast(`{info.by} is smashing up the Legends Gem Showcase!`, Theme.Danger)
		elseif kind == "heartRobbery" then
			UI.toast(`{info.by} is going for the Legends Heart!`, Theme.Danger)
		elseif kind == "hacked" then
			local s = tonumber(info.seconds) or 0
			UI.toast(string.format("Security hacked: the lasers are down for %d:%02d. Drill the vault!", s // 60, s % 60), Theme.Warning)
			Audio.cutUp(2, "HACKED")
		elseif kind == "grab" then
			UI.popup(if type(info.what) == "string" then info.what else "LOOT GRABBED", tonumber(info.amount) or 0, Theme.Money)
			Audio.cutUp(2, "CASH")
		elseif kind == "full" then
			UI.toast("Your bag is full: get to the drop-off", Theme.Warning)
		elseif kind == "vip" then
			if info.by ~= player.DisplayName then
				UI.toast(`{info.by} is now a {info.card} member`, Color3.fromRGB(200, 150, 255))
			end
		end
	end)
end

return LuxeClient
