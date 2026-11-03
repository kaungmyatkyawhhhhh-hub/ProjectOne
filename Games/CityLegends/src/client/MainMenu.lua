--[[
	MainMenu (client)
	The City Legends main menu (owner, 2026-11-02, "Main menu (tile style)"): big bold tiles on a
	soft patterned background, a top bar (the car you drive by name, or CLAIM CAR for a new player;
	the player, level and cash on the right) and three tabs: CAMPAIGN, CARS, STORE. Our own look:
	deep navy, warm gold and one mint accent; the pictures are drawn by tools/menu_art.py (MenuArt).

	  * CAMPAIGN: PLAY (the big highlighted tile: back to driving, or your car out), WORLD MAP (a live
	    map: venue symbols, a card with FAST TRAVEL and SET WAYPOINT), ACHIEVEMENTS (the cars
	    collection and the Legends Path; opens the GOALS screen) and SETTINGS (mini map on / off and
	    corner, graphics, camera, units, gearbox, music and sound sliders, radio, controls).
	  * CARS: your cars by brand (sort, search), a side panel with SPAWN, FAVOURITE, CUSTOMISE (a
	    waypoint to Legends Customs) and MARKET; "Get more cars" sets a waypoint to Legends Motors.
	  * STORE: passes and products by name and exact effect, prices read from Roblox; greyed with
	    "Coming soon" until the owner gives the ids (Config.Menu.Store).
	  * A new player: CLAIM CAR (and PLAY) open the pick of 3 starter cars; the pick is the server's.

	It opens from the HUD's MENU button (in place of SETTINGS; no extra key, owner) and as the start
	screen. While it's open the game runs on and your car is braked and held (Driving.menuHold).
	Keys inside it: Enter select, arrows move, Q / E switch tab, Backspace back; gamepad A / B / LB / RB.
]]

local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Cars = require(Shared:WaitForChild("Cars"))
local TravelSpots = require(Shared:WaitForChild("TravelSpots"))

local UI = require(script.Parent:WaitForChild("UI"))
local Audio = require(script.Parent:WaitForChild("Audio"))
local Driving = require(script.Parent:WaitForChild("Driving"))
local Minimap = require(script.Parent:WaitForChild("Minimap"))
local WorldFx = require(script.Parent:WaitForChild("WorldFx"))
local Weather = require(script.Parent:WaitForChild("Weather"))
local MenuArt = require(script.Parent:WaitForChild("MenuArt"))

local MainMenu = {}

local player = Players.LocalPlayer

-- the look: deep navy, warm gold, one mint accent (colour = meaning: mint go, gold claim, blue
-- normal, red close, grey locked)
local NAVY0 = Color3.fromRGB(8, 12, 26)
local NAVY = Color3.fromRGB(17, 26, 54)
local PANEL = Color3.fromRGB(14, 20, 42)
local BLUE = Color3.fromRGB(46, 86, 170)
local GOLD = Color3.fromRGB(255, 192, 72)
local MINT = Color3.fromRGB(74, 234, 172)
local WHITE = Color3.fromRGB(246, 248, 255)
local SUB = Color3.fromRGB(160, 172, 204)
local RED = Color3.fromRGB(255, 96, 96)
local GREY = Color3.fromRGB(92, 98, 116)
local GREEN = Color3.fromRGB(96, 228, 146)

local FAMILY = "rbxasset://fonts/families/BuilderSans.json"
local HEAVY = Font.new(FAMILY, Enum.FontWeight.ExtraBold)
local BOLD = Font.new(FAMILY, Enum.FontWeight.Bold)
local MEDIUM = Font.new(FAMILY, Enum.FontWeight.Medium)

local W, H = 1180, 640 -- the design canvas (scaled to the screen)

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------
local function new(className: string, props: { [string]: any }?, children: { Instance }?): any
	local inst = Instance.new(className)
	local parent = nil
	for k, v in (props or {}) :: { [string]: any } do
		if k == "Parent" then
			parent = v
		else
			(inst :: any)[k] = v
		end
	end
	for _, c in (children or {}) :: { Instance } do
		c.Parent = inst
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

local function corner(r: number): UICorner
	return new("UICorner", { CornerRadius = UDim.new(0, r) })
end

local function text(props: { [string]: any }): TextLabel
	local base: { [string]: any } = {
		BackgroundTransparency = 1,
		FontFace = BOLD,
		TextColor3 = WHITE,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = "",
	}
	for k, v in props do
		base[k] = v
	end
	return new("TextLabel", base)
end

local function gradient(top: Color3, bottom: Color3, rot: number?): UIGradient
	return new("UIGradient", { Color = ColorSequence.new(top, bottom), Rotation = rot or 90 })
end

local calm = GuiService.ReducedMotionEnabled
local function tween(inst: Instance, t: number, props: { [string]: any }, style: Enum.EasingStyle?)
	local tw = TweenService:Create(inst, TweenInfo.new(if calm then 0 else t, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function hoverSound()
	Audio.play("tick", 0.1, 2.3)
end
local function selectSound()
	Audio.click()
end

local function money(n: number): string
	return UI.formatCash(n)
end

-- a button with our finish: rounded, a colour by meaning, a press-in
local function button(label: string, color: Color3, props: { [string]: any }): TextButton
	local base: { [string]: any } = {
		AutoButtonColor = false,
		BackgroundColor3 = color,
		FontFace = HEAVY,
		Text = label,
		TextColor3 = if color == MINT or color == GOLD or color == GREEN then NAVY0 else WHITE,
		TextSize = 18,
	}
	for k, v in props do
		base[k] = v
	end
	local b: TextButton = new("TextButton", base, { corner(8) })
	new("UIGradient", { Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(205, 210, 222)), Rotation = 90, Parent = b })
	b.MouseEnter:Connect(hoverSound)
	return b
end

-- key caps for the hints
local function keyCap(parent: Instance, key: string, order: number): Frame
	local f = new("Frame", { BackgroundColor3 = WHITE, Size = UDim2.fromOffset(math.max(26, #key * 9 + 14), 24), LayoutOrder = order, Parent = parent }, { corner(5) })
	text({ Text = key, FontFace = HEAVY, TextColor3 = NAVY0, TextSize = 13, Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Parent = f })
	return f
end

---------------------------------------------------------------------
-- State
---------------------------------------------------------------------
type Api = {
	getData: () -> any,
	refresh: () -> any,
	drive: (string) -> (),
	travel: (string) -> { ok: boolean, message: string? },
	claim: (string) -> { ok: boolean, message: string?, data: any },
	settings: { [string]: any },
	saveSettings: () -> (),
	openGoals: () -> (),
	openMarket: () -> (),
	openPhoto: () -> (),
	onClosed: (() -> ())?,
}
local api: Api? = nil

local gui: ScreenGui? = nil
local canvas: Frame
local scaler: UIScale
local blur: BlurEffect? = nil
local isOpen = false
local startMode = false -- the start screen: no car yet (nothing to go back to)
local tabName = "CAMPAIGN"
local TABS = { "CAMPAIGN", "CARS", "STORE" }
local tabButtons: { [string]: TextButton } = {}
local tabBadges: { [string]: Frame } = {}
local pages: { [string]: Frame } = {}
local sub: Frame? = nil -- an open page on top (world map, settings, claim)
local topLeft: Frame
local topRight: Frame
local hintsBar: Frame
local refreshers: { () -> () } = {}

-- keyboard / gamepad: the things you can move between on the current page
type Focus = { button: GuiButton, activate: () -> () }
local focusList: { Focus } = {}
local focused: Focus? = nil

local function setFocus(f: Focus?)
	if focused and focused.button.Parent then
		local st = focused.button:FindFirstChild("FocusStroke") :: UIStroke?
		if st then
			st.Transparency = 1
		end
	end
	focused = f
	if f then
		local st = f.button:FindFirstChild("FocusStroke") :: UIStroke?
		if st then
			st.Transparency = 0
		end
		-- (only for a gamepad: with a keyboard Roblox's own UI navigation would take the arrows)
		if string.sub(UserInputService:GetLastInputType().Name, 1, 7) == "Gamepad" then
			GuiService.SelectedObject = f.button
		end
	end
end

local function focusable(b: GuiButton, activate: () -> (), color: Color3?): Focus
	if not b:FindFirstChild("FocusStroke") then
		new("UIStroke", { Name = "FocusStroke", Color = color or WHITE, Thickness = 4, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = b })
	end
	local f = { button = b, activate = activate }
	table.insert(focusList, f)
	b.MouseEnter:Connect(function()
		setFocus(f)
	end)
	b.Activated:Connect(function()
		selectSound()
		activate()
	end)
	return f
end

-- the nearest focusable in a direction (arrow keys)
local function moveFocus(dir: Vector2)
	local cur = focused
	if not cur or not cur.button.Parent then
		setFocus(focusList[1])
		return
	end
	local c0 = cur.button.AbsolutePosition + cur.button.AbsoluteSize / 2
	local best, bestScore = nil, math.huge
	for _, f in focusList do
		if f ~= cur and f.button.Parent and f.button.Visible and f.button:IsDescendantOf(canvas) then
			local c = f.button.AbsolutePosition + f.button.AbsoluteSize / 2
			local d = c - c0
			local along = d.X * dir.X + d.Y * dir.Y
			if along > 4 then
				local across = math.abs(d.X * dir.Y - d.Y * dir.X)
				local score = along + across * 2
				if score < bestScore then
					best, bestScore = f, score
				end
			end
		end
	end
	if best then
		hoverSound()
		setFocus(best)
	end
end

local function data(): any
	return if api then api.getData() else {}
end

local function ownedList(): { string }
	local list = {}
	for _, id in data().Owned or {} do
		if Cars.ById[id] then
			table.insert(list, id)
		end
	end
	return list
end

local function claimed(): boolean
	return data().Claimed ~= false
end

-- where you are now (car, on foot, or the camera)
local function here(): Vector3
	local model = Driving.getModel()
	if model and model.PrimaryPart then
		return model.PrimaryPart.Position
	end
	local character = player.Character
	local hrp = character and character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then
		return hrp.Position
	end
	return workspace.CurrentCamera.Focus.Position
end

local function spotById(id: string): TravelSpots.Spot?
	return TravelSpots.get(id)
end

---------------------------------------------------------------------
-- Background, top bar, tabs, hints
---------------------------------------------------------------------
local function buildBackground(root: Frame)
	local back = new("Frame", { Name = "Back", Size = UDim2.fromScale(1, 1), BackgroundColor3 = NAVY0, BackgroundTransparency = 0.04, BorderSizePixel = 0, Parent = root }, {
		gradient(Color3.fromRGB(40, 52, 96), Color3.fromRGB(8, 12, 26)),
	})
	new("ImageLabel", {
		Name = "Pattern",
		BackgroundTransparency = 1,
		Image = MenuArt.menu_pattern,
		ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.fromOffset(256, 256),
		ImageTransparency = 0.35,
		Size = UDim2.fromScale(1, 1),
		Parent = back,
	})
	-- a warm glow from the top
	new("Frame", { BackgroundColor3 = GOLD, BackgroundTransparency = 0, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0.5, 0), Parent = back }, {
		new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.86), NumberSequenceKeypoint.new(1, 1) }) }),
	})
end

local function tierColor(tier: string): Color3
	return if tier == "High" then GOLD elseif tier == "Mid" then Color3.fromRGB(120, 170, 255) else MINT
end

local openClaim: () -> ()

local function buildTopBar()
	topLeft = new("Frame", { Name = "Car", BackgroundColor3 = PANEL, BackgroundTransparency = 0.1, Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(400, 104), Parent = canvas }, { corner(10) })
	new("Frame", { BackgroundColor3 = GOLD, BorderSizePixel = 0, Size = UDim2.new(0, 6, 1, 0), Parent = topLeft }, { corner(3) })
	topRight = new("Frame", { Name = "Player", BackgroundColor3 = PANEL, BackgroundTransparency = 0.1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(400, 104), Parent = canvas }, { corner(10) })

	local function fillLeft()
		for _, c in topLeft:GetChildren() do
			if c.Name == "Fill" then
				c:Destroy()
			end
		end
		local fill = new("Frame", { Name = "Fill", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = topLeft })
		if not claimed() then
			-- a new player: CLAIM CAR (gold = claim), pulsing
			local b = button("CLAIM CAR", GOLD, { Position = UDim2.fromOffset(22, 16), Size = UDim2.new(1, -40, 0, 50), TextSize = 26, Parent = fill })
			text({ Text = "Pick your first car: it's free", TextColor3 = SUB, TextSize = 15, FontFace = MEDIUM, Position = UDim2.fromOffset(24, 72), Size = UDim2.new(1, -40, 0, 20), Parent = fill })
			b.Activated:Connect(function()
				selectSound()
				openClaim()
			end)
			task.spawn(function()
				while b.Parent do
					tween(b, 0.6, { BackgroundColor3 = Color3.fromRGB(255, 220, 140) }, Enum.EasingStyle.Sine)
					task.wait(0.6)
					tween(b, 0.6, { BackgroundColor3 = GOLD }, Enum.EasingStyle.Sine)
					task.wait(0.6)
				end
			end)
			return
		end
		local model = Driving.getModel()
		local id = (if model then model:GetAttribute("CarId") else nil) or data().Selected
		local spec = Cars.ById[id]
		if not spec then
			return
		end
		text({ Text = if model then "DRIVING" else "YOUR CAR", FontFace = HEAVY, TextSize = 13, TextColor3 = GOLD, Position = UDim2.fromOffset(24, 12), Size = UDim2.fromOffset(200, 16), Parent = fill })
		text({ Text = spec.Name, FontFace = HEAVY, TextSize = 28, TextScaled = true, Position = UDim2.fromOffset(24, 30), Size = UDim2.new(1, -80, 0, 36), Parent = fill })
		local chip = new("Frame", { BackgroundColor3 = tierColor(spec.Tier), Position = UDim2.fromOffset(24, 72), Size = UDim2.fromOffset(78, 22), Parent = fill }, { corner(11) })
		text({ Text = string.upper(spec.Tier), FontFace = HEAVY, TextSize = 13, TextColor3 = NAVY0, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = chip })
		text({ Text = string.upper(Cars.ClassLabels[spec.Class] or spec.Class), FontFace = BOLD, TextSize = 14, TextColor3 = SUB, Position = UDim2.fromOffset(112, 72), Size = UDim2.fromOffset(160, 22), Parent = fill })
		new("Frame", { BackgroundColor3 = spec.Color, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -20, 0.5, 0), Size = UDim2.fromOffset(34, 34), Parent = fill }, {
			new("UICorner", { CornerRadius = UDim.new(1, 0) }),
			new("UIStroke", { Color = WHITE, Thickness = 2 }),
		})
	end

	-- the player: headshot, name, level and XP, cash
	local avatar = new("ImageLabel", { BackgroundColor3 = NAVY, Position = UDim2.fromOffset(14, 14), Size = UDim2.fromOffset(76, 76), Parent = topRight }, { corner(10) })
	task.spawn(function()
		local ok, img = pcall(function()
			return Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		end)
		if ok then
			avatar.Image = img
		end
	end)
	text({ Text = player.DisplayName, FontFace = HEAVY, TextSize = 22, Position = UDim2.fromOffset(104, 12), Size = UDim2.fromOffset(200, 26), TextTruncate = Enum.TextTruncate.AtEnd, Parent = topRight })
	local lvl = new("Frame", { BackgroundColor3 = GOLD, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 14), Size = UDim2.fromOffset(74, 24), Parent = topRight }, { corner(12) })
	local lvlText = text({ Text = "LV 1", FontFace = HEAVY, TextSize = 15, TextColor3 = NAVY0, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = lvl })
	local xpBack = new("Frame", { BackgroundColor3 = NAVY, Position = UDim2.fromOffset(104, 46), Size = UDim2.new(1, -118, 0, 10), Parent = topRight }, { corner(5) })
	local xpFill = new("Frame", { BackgroundColor3 = MINT, Size = UDim2.fromScale(0, 1), Parent = xpBack }, { corner(5) })
	local cash = text({ Text = "$0", FontFace = HEAVY, TextSize = 26, TextColor3 = GREEN, Position = UDim2.fromOffset(104, 62), Size = UDim2.new(1, -118, 0, 30), Parent = topRight })

	table.insert(refreshers, function()
		fillLeft()
		local level, xp, need = UI.getProgress()
		lvlText.Text = "LV " .. tostring(level)
		xpFill.Size = UDim2.fromScale(math.clamp(xp / math.max(need, 1), 0, 1), 1)
		local stats = player:FindFirstChild("leaderstats")
		local c = stats and stats:FindFirstChild("Cash")
		cash.Text = money(if c and c:IsA("IntValue") then c.Value else (data().Cash or 0))
	end)
end

local switchTab: (string) -> ()
local closeSubPage: () -> ()

local function buildTabs()
	local strip = new("Frame", { Name = "Tabs", BackgroundColor3 = NAVY0, BackgroundTransparency = 0.05, Position = UDim2.fromOffset(0, 118), Size = UDim2.new(1, 0, 0, 46), Parent = canvas }, { corner(6) })
	new("Frame", { BackgroundColor3 = GOLD, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 3), Parent = strip })
	local row = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.fromOffset(3 * 196, 36), Parent = strip }, {
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center }),
	})
	for i, name in TABS do
		local b = new("TextButton", { AutoButtonColor = false, Text = name, FontFace = HEAVY, TextSize = 20, TextColor3 = WHITE, BackgroundColor3 = WHITE, BackgroundTransparency = 1, LayoutOrder = i, Size = UDim2.fromOffset(190, 36), Parent = row }, { corner(6) })
		b.MouseEnter:Connect(hoverSound)
		b.Activated:Connect(function()
			if sub then
				closeSubPage()
			end
			if tabName ~= name then
				selectSound()
				switchTab(name)
			end
		end)
		tabButtons[name] = b
		local badge = new("Frame", { Name = "Badge", BackgroundColor3 = GOLD, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -14, 0, 2), Size = UDim2.fromOffset(22, 22), Visible = false, ZIndex = 3, Parent = b }, {
			new("UICorner", { CornerRadius = UDim.new(1, 0) }),
			new("UIStroke", { Color = NAVY0, Thickness = 2 }),
		})
		text({ Name = "N", Text = "1", FontFace = HEAVY, TextSize = 13, TextColor3 = NAVY0, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), ZIndex = 4, Parent = badge })
		tabBadges[name] = badge
	end
	-- the arrows either side (Q / E)
	for _, side in { -1, 1 } do
		local b = new("TextButton", {
			AutoButtonColor = false,
			Text = if side < 0 then "◀  Q" else "E  ▶",
			FontFace = HEAVY,
			TextSize = 16,
			TextColor3 = NAVY0,
			BackgroundColor3 = WHITE,
			AnchorPoint = Vector2.new(if side < 0 then 0 else 1, 0),
			Position = if side < 0 then UDim2.fromOffset(8, 9) else UDim2.new(1, -8, 0, 9),
			Size = UDim2.fromOffset(64, 30),
			Parent = strip,
		}, { corner(5) })
		b.MouseEnter:Connect(hoverSound)
		b.Selectable = false
		b.Activated:Connect(function()
			if sub then
				closeSubPage()
			end
			local i = table.find(TABS, tabName) or 1
			selectSound()
			switchTab(TABS[(i - 1 + side) % #TABS + 1])
		end)
	end
	table.insert(refreshers, function()
		local campaignNew = (not claimed()) or ((data().DailyIn or 1) <= 0)
		tabBadges.CAMPAIGN.Visible = campaignNew
	end)
end

local closeMenu: () -> ()
local goBack: () -> ()

local function buildHints()
	hintsBar = new("Frame", { Name = "Hints", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, H - 36), Size = UDim2.new(1, 0, 0, 32), Parent = canvas }, {
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), VerticalAlignment = Enum.VerticalAlignment.Center }),
	})
	local function refresh()
		for _, c in hintsBar:GetChildren() do
			if not c:IsA("UIListLayout") then
				c:Destroy()
			end
		end
		local pad = UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled
		local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not pad
		local order = 0
		local function hint(keys: { string }, label: string, onClick: (() -> ())?)
			order += 1
			local pill = new("TextButton", { AutoButtonColor = false, Text = "", BackgroundColor3 = PANEL, BackgroundTransparency = 0.15, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 32), LayoutOrder = order, Parent = hintsBar }, {
				corner(8),
				new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 10) }),
				new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center }),
			})
			if not touch then
				for k, key in keys do
					keyCap(pill, key, k)
				end
			end
			local t = text({ Text = label, TextSize = 15, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 32), LayoutOrder = 10, Parent = pill })
			t.TextXAlignment = Enum.TextXAlignment.Left
			if onClick then
				pill.MouseEnter:Connect(hoverSound)
				pill.Activated:Connect(function()
					selectSound()
					onClick()
				end)
			end
		end
		if not touch then
			hint(if pad then { "A" } else { "Enter" }, "Select", nil)
		end
		if sub or not startMode then
			hint(if pad then { "B" } else { "Backspace" }, if sub then "Back" else "Close", goBack)
		end
		if not touch and not sub then
			hint(if pad then { "LB", "RB" } else { "Q", "E" }, "Switch tab", nil)
		end
	end
	table.insert(refreshers, refresh)
end

---------------------------------------------------------------------
-- Tiles
---------------------------------------------------------------------
type TileOpts = { top: Color3, bottom: Color3, title: string, sub: string?, art: string?, artSize: Vector2?, artPos: UDim2?, titleSize: number?, dark: boolean? }

local function tile(parent: Instance, x: number, y: number, w: number, h: number, o: TileOpts): TextButton
	local b: TextButton = new("TextButton", { AutoButtonColor = false, Text = "", BackgroundColor3 = WHITE, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), ClipsDescendants = true, Parent = parent }, {
		corner(10),
		gradient(o.top, o.bottom, 115),
	})
	-- a soft shine across the top
	new("Frame", { BackgroundColor3 = WHITE, BorderSizePixel = 0, Size = UDim2.new(1, 0, 0.45, 0), Parent = b }, {
		new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.82), NumberSequenceKeypoint.new(1, 1) }) }),
	})
	if o.art then
		new("ImageLabel", {
			Name = "Art",
			BackgroundTransparency = 1,
			Image = o.art,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = o.artPos or UDim2.new(1, -8, 0.5, 0),
			Size = UDim2.fromOffset((o.artSize or Vector2.new(h, h)).X, (o.artSize or Vector2.new(h, h)).Y),
			ZIndex = 2,
			Parent = b,
		})
	end
	local ink = if o.dark then NAVY0 else WHITE
	local title = text({ Name = "Title", Text = o.title, FontFace = HEAVY, TextSize = o.titleSize or 40, TextColor3 = ink, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Position = UDim2.fromOffset(20, 16), Size = UDim2.new(1, -40, 0, (o.titleSize or 40) * 2.2), ZIndex = 3, Parent = b })
	new("UIStroke", { Color = Color3.new(0, 0, 0), Transparency = if o.dark then 1 else 0.7, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, Parent = title })
	if o.sub then
		text({ Name = "Sub", Text = o.sub, FontFace = MEDIUM, TextSize = 17, TextColor3 = ink, TextTransparency = 0.1, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Bottom, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 20, 1, -14), Size = UDim2.new(1, -40, 0, 44), ZIndex = 3, Parent = b })
	end
	-- hover: lift a little
	local scale = new("UIScale", { Parent = b })
	b.MouseEnter:Connect(function()
		hoverSound()
		tween(scale, 0.12, { Scale = 1.015 })
	end)
	b.MouseLeave:Connect(function()
		tween(scale, 0.12, { Scale = 1 })
	end)
	return b
end

---------------------------------------------------------------------
-- The map (drawn once, shown in the WORLD MAP tile and on the map page)
---------------------------------------------------------------------
local mapDrawing: Frame? = nil
local MAP_CENTRE = Vector2.new(14300, 250) -- Monaco's middle (world x, z)
local function getMap(): Frame
	if mapDrawing then
		return mapDrawing
	end
	local f = new("Frame", { Name = "MapDrawing", BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 0) })
	new("UIScale", { Name = "Zoom", Parent = f })
	pcall(Minimap.drawWhole, f)
	mapDrawing = f
	return f
end
-- shows the map in `pane` centred on world (cx, cz) at `scale` px per stud
local function placeMap(pane: GuiObject, cx: number, cz: number, scale: number)
	local m = getMap()
	m.Parent = pane
	local zoom = m:FindFirstChild("Zoom") :: UIScale
	zoom.Scale = scale
	local size = pane.AbsoluteSize / (if scaler then scaler.Scale else 1)
	m.Position = UDim2.fromOffset(-cx * scale + size.X / 2, -cz * scale + size.Y / 2)
end

local ICON_COLOR: { [string]: Color3 } = {
	dealership = GOLD,
	customs = Color3.fromRGB(255, 140, 60),
	bank = Color3.fromRGB(80, 220, 130),
	tower = Color3.fromRGB(170, 140, 255),
	hotel = Color3.fromRGB(255, 196, 120),
	rewards = Color3.fromRGB(255, 200, 90),
	gems = Color3.fromRGB(110, 205, 255),
	realty = MINT,
	home = Color3.fromRGB(120, 255, 200),
	race = Color3.fromRGB(255, 110, 60),
	delivery = Color3.fromRGB(226, 186, 120),
	beach = Color3.fromRGB(255, 220, 100),
	stadium = Color3.fromRGB(140, 220, 140),
	palace = Color3.fromRGB(214, 196, 255),
	harbour = Color3.fromRGB(110, 186, 255),
	lookout = Color3.fromRGB(190, 210, 170),
}
local function venueIcon(parent: Instance, kind: string, size: number): ImageButton
	local k = table.find(MenuArt.venues, kind) or 1
	local b: ImageButton = new("ImageButton", {
		AutoButtonColor = false,
		BackgroundColor3 = ICON_COLOR[kind] or BLUE,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(size, size),
		Image = "",
		Parent = parent,
	}, { new("UICorner", { CornerRadius = UDim.new(1, 0) }), new("UIStroke", { Color = NAVY0, Thickness = 2 }) })
	new("ImageLabel", {
		BackgroundTransparency = 1,
		Image = MenuArt.menu_venues,
		ImageRectOffset = Vector2.new((k - 1) * 64, 0),
		ImageRectSize = Vector2.new(64, 64),
		ImageColor3 = NAVY0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.72, 0.72),
		Parent = b,
	})
	return b
end

local function timeOfDay(): string
	local h = Lighting.ClockTime
	if h >= 5 and h < 8 then
		return "Dawn"
	elseif h >= 8 and h < 17 then
		return "Day"
	elseif h >= 17 and h < 19.6 then
		return "Sunset"
	end
	return "Night"
end

local function district(): string
	local p = here()
	local best, bestD = "Riviera Bay", math.huge
	for _, s in TravelSpots.list() do
		if s.icon ~= "race" and s.icon ~= "delivery" then
			local d = (Vector3.new(s.cf.Position.X, 0, s.cf.Position.Z) - Vector3.new(p.X, 0, p.Z)).Magnitude
			if d < bestD then
				best, bestD = s.name, d
			end
		end
	end
	return best
end

---------------------------------------------------------------------
-- Sub pages (open over the tabs' area)
---------------------------------------------------------------------
local function closeSub()
	GuiService.SelectedObject = nil
	if sub then
		local m = mapDrawing
		if m and m:IsDescendantOf(sub) then
			m.Parent = nil
		end
		sub:Destroy()
		sub = nil
	end
	for _, p in pages do
		p.Visible = false
	end
	if pages[tabName] then
		pages[tabName].Visible = true
	end
	switchTab(tabName)
end

closeSubPage = function()
	closeSub()
end

local function openSub(title: string): Frame
	if sub then
		sub:Destroy()
	end
	for _, p in pages do
		p.Visible = false
	end
	setFocus(nil)
	table.clear(focusList)
	local f = new("Frame", { Name = "Sub", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 176), Size = UDim2.new(1, 0, 0, H - 176 - 46), Parent = canvas })
	local back = button("◀  BACK", BLUE, { Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(120, 36), TextSize = 16, Parent = f })
	back.Activated:Connect(function()
		selectSound()
		goBack()
	end)
	text({ Text = title, FontFace = HEAVY, TextSize = 30, Position = UDim2.fromOffset(136, 0), Size = UDim2.fromOffset(600, 36), Parent = f })
	sub = f
	for _, r in refreshers do
		r()
	end
	return f
end

---------------------------------------------------------------------
-- The world map page: symbols, a card, fast travel and waypoints
---------------------------------------------------------------------
local function openWorldMap()
	local page = openSub("World Map")
	local paneW, paneH = 800, 368
	local pane = new("Frame", { Name = "Pane", BackgroundColor3 = Color3.fromRGB(14, 34, 58), Position = UDim2.fromOffset(0, 46), Size = UDim2.fromOffset(paneW, paneH), ClipsDescendants = true, Parent = page }, {
		corner(10),
		new("UIStroke", { Color = GOLD, Thickness = 2, Transparency = 0.3 }),
	})
	local layer = new("Frame", { Name = "Symbols", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 20, Parent = pane })
	local cx, cz = MAP_CENTRE.X, MAP_CENTRE.Y
	local p0 = here()
	if p0.X > 10000 then
		cx, cz = p0.X, p0.Z
	end
	local scale = 0.12
	-- filters
	local show = { venue = true, race = true, job = true }
	local function groupOf(s: TravelSpots.Spot): string
		return if s.icon == "race" then "race" elseif s.icon == "delivery" then "job" else "venue"
	end
	local spots = table.clone(TravelSpots.list())
	if player:GetAttribute("HouseLot") then
		-- your house (the server knows where): its symbol sits at the lot's sign, if it's streamed in
		local lot = player:GetAttribute("HouseLot")
		local houses = workspace:FindFirstChild("Houses", true)
		local model = houses and houses:FindFirstChild(tostring(lot), true)
		if model and model:IsA("Model") then
			table.insert(spots, { id = "home", name = "Your House", icon = "home", info = TravelSpots.INFO.home, cf = model:GetPivot() })
		end
	end
	local icons: { { b: ImageButton, s: TravelSpots.Spot } } = {}
	local you = text({ Text = "▲", FontFace = HEAVY, TextSize = 22, TextColor3 = MINT, TextXAlignment = Enum.TextXAlignment.Center, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(24, 24), ZIndex = 25, Parent = layer })
	new("UIStroke", { Color = NAVY0, Thickness = 2, Parent = you })
	local youTag = text({ Text = "You are here", FontFace = HEAVY, TextSize = 13, TextColor3 = WHITE, TextXAlignment = Enum.TextXAlignment.Center, AnchorPoint = Vector2.new(0.5, 0), Size = UDim2.fromOffset(110, 16), ZIndex = 25, Parent = layer })
	new("UIStroke", { Color = NAVY0, Thickness = 2, Parent = youTag })

	-- the card on the right
	local card = new("Frame", { Name = "Card", BackgroundColor3 = PANEL, BackgroundTransparency = 0.05, Position = UDim2.fromOffset(paneW + 16, 46), Size = UDim2.fromOffset(W - paneW - 16, paneH), Parent = page }, { corner(10) })
	local function fillCard(s: TravelSpots.Spot?)
		for _, c in card:GetChildren() do
			if not c:IsA("UICorner") then
				c:Destroy()
			end
		end
		if not s then
			text({ Text = "Pick a place", FontFace = HEAVY, TextSize = 26, Position = UDim2.fromOffset(20, 18), Size = UDim2.new(1, -40, 0, 32), Parent = card })
			text({ Text = "Click or tap a symbol on the map to see what's there, fast travel to it or set a waypoint.\n\nDrag to move, scroll or + / - to zoom.", FontFace = MEDIUM, TextSize = 16, TextColor3 = SUB, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Position = UDim2.fromOffset(20, 60), Size = UDim2.new(1, -40, 0, 160), Parent = card })
			return
		end
		local ic = venueIcon(card, s.icon, 56)
		ic.AnchorPoint = Vector2.new(0, 0)
		ic.Position = UDim2.fromOffset(20, 18)
		text({ Text = s.name, FontFace = HEAVY, TextSize = 24, TextWrapped = true, TextScaled = true, Position = UDim2.fromOffset(88, 18), Size = UDim2.new(1, -104, 0, 56), Parent = card })
		text({ Text = s.info, FontFace = MEDIUM, TextSize = 17, TextColor3 = SUB, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Position = UDim2.fromOffset(20, 88), Size = UDim2.new(1, -40, 0, 48), Parent = card })
		local d = (Vector3.new(s.cf.Position.X, 0, s.cf.Position.Z) - Vector3.new(here().X, 0, here().Z)).Magnitude
		local metres = d / 3
		text({ Text = if metres >= 1000 then string.format("%.1f km away", metres / 1000) else string.format("%d m away", math.floor(metres)), FontFace = BOLD, TextSize = 17, TextColor3 = GOLD, Position = UDim2.fromOffset(20, 140), Size = UDim2.new(1, -40, 0, 22), Parent = card })
		local status = text({ Text = "", FontFace = BOLD, TextSize = 15, TextColor3 = RED, TextWrapped = true, Position = UDim2.fromOffset(20, 170), Size = UDim2.new(1, -40, 0, 40), Parent = card })
		if ((player:GetAttribute("Wanted") :: number?) or 0) > 0 then
			status.Text = "Lose the police first"
		end
		local go = button("FAST TRAVEL", MINT, { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 20, 1, -76), Size = UDim2.new(1, -40, 0, 50), TextSize = 22, Parent = card })
		local way = button("SET WAYPOINT", BLUE, { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 20, 1, -16), Size = UDim2.new(1, -40, 0, 50), TextSize = 20, Parent = card })
		focusable(go, function()
			if not api then
				return
			end
			go.Text = "TRAVELLING..."
			local result = api.travel(s.id)
			if result.ok then
				closeMenu()
			else
				go.Text = "FAST TRAVEL"
				status.Text = result.message or "Can't travel now"
				Audio.play("thud", 0.3, 1.2)
			end
		end, MINT)
		focusable(way, function()
			Minimap.setWaypoint(s.cf.Position)
			UI.toast("Waypoint: " .. s.name .. " (on your map)", MINT)
			way.Text = "WAYPOINT SET ✓"
		end)
	end
	fillCard(nil)

	for _, s in spots do
		local b = venueIcon(layer, s.icon, 30)
		b.ZIndex = 21
		for _, c in b:GetDescendants() do
			if c:IsA("GuiObject") then
				c.ZIndex = 22
			end
		end
		b.MouseEnter:Connect(function()
			hoverSound()
			tween(b, 0.1, { Size = UDim2.fromOffset(38, 38) })
		end)
		b.MouseLeave:Connect(function()
			tween(b, 0.1, { Size = UDim2.fromOffset(30, 30) })
		end)
		-- (keyboard and gamepad move between the symbols too)
		focusable(b, function()
			fillCard(s)
		end, WHITE)
		table.insert(icons, { b = b, s = s })
	end

	local function redraw()
		placeMap(pane, cx, cz, scale)
		local size = Vector2.new(paneW, paneH)
		local function put(g: GuiObject, p: Vector3): boolean
			local x, y = (p.X - cx) * scale + size.X / 2, (p.Z - cz) * scale + size.Y / 2
			g.Position = UDim2.fromOffset(x, y)
			return x > -20 and x < size.X + 20 and y > -20 and y < size.Y + 20
		end
		for _, it in icons do
			local on = put(it.b, it.s.cf.Position)
			it.b.Visible = on and show[groupOf(it.s)] ~= false
		end
		local p = here()
		local onYou = put(you, p)
		you.Visible = onYou
		youTag.Visible = onYou
		youTag.Position = you.Position + UDim2.fromOffset(0, 14)
		local look = workspace.CurrentCamera.CFrame.LookVector
		local model = Driving.getModel()
		if model and model.PrimaryPart then
			look = model.PrimaryPart.CFrame.LookVector
		end
		you.Rotation = math.deg(math.atan2(look.X, -look.Z))
	end
	-- drag and zoom (the connections go with the page)
	local conns: { RBXScriptConnection } = {}
	page.Destroying:Connect(function()
		for _, c in conns do
			c:Disconnect()
		end
	end)
	local dragging: Vector2? = nil
	pane.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = Vector2.new(input.Position.X, input.Position.Y)
		end
	end)
	table.insert(conns, UserInputService.InputChanged:Connect(function(input)
		if not pane.Parent then
			return
		end
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local p = Vector2.new(input.Position.X, input.Position.Y)
			local d = (p - dragging) / (scaler.Scale * scale)
			cx -= d.X
			cz -= d.Y
			dragging = p
			redraw()
		elseif input.UserInputType == Enum.UserInputType.MouseWheel then
			local m = UserInputService:GetMouseLocation() -- (the menu ignores the top bar inset: screen pixels)
			local a, s = pane.AbsolutePosition, pane.AbsoluteSize
			if m.X >= a.X and m.Y >= a.Y and m.X <= a.X + s.X and m.Y <= a.Y + s.Y then
				scale = math.clamp(scale * (if input.Position.Z > 0 then 1.2 else 1 / 1.2), 0.04, 0.6)
				redraw()
			end
		end
	end))
	table.insert(conns, UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = nil
		end
	end))
	for k, z in { { "+", 1.3 }, { "−", 1 / 1.3 } } do
		local b = button(z[1] :: string, NAVY, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10 + (k - 1) * 44), Size = UDim2.fromOffset(38, 38), TextSize = 24, ZIndex = 30, Parent = pane })
		b.Activated:Connect(function()
			selectSound()
			scale = math.clamp(scale * (z[2] :: number), 0.04, 0.6)
			redraw()
		end)
	end
	local centre = button("◎", NAVY, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 98), Size = UDim2.fromOffset(38, 38), TextSize = 22, ZIndex = 30, Parent = pane })
	centre.Activated:Connect(function()
		selectSound()
		local p = here()
		cx, cz = p.X, p.Z
		redraw()
	end)
	-- the legend: filters
	local legend = new("Frame", { BackgroundColor3 = NAVY0, BackgroundTransparency = 0.2, Position = UDim2.fromOffset(10, 10), Size = UDim2.fromOffset(330, 40), ZIndex = 30, Parent = pane }, {
		corner(8),
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center }),
		new("UIPadding", { PaddingLeft = UDim.new(0, 6) }),
	})
	for k, f in { { "venue", "Places", GOLD }, { "race", "Races", Color3.fromRGB(255, 110, 60) }, { "job", "Jobs", Color3.fromRGB(226, 186, 120) } } do
		local key, label, col = f[1] :: string, f[2] :: string, f[3] :: Color3
		local chip = new("TextButton", { AutoButtonColor = false, Text = "● " .. label, FontFace = HEAVY, TextSize = 15, TextColor3 = NAVY0, BackgroundColor3 = col, Size = UDim2.fromOffset(100, 28), LayoutOrder = k, ZIndex = 31, Parent = legend }, { corner(14) })
		chip.Activated:Connect(function()
			selectSound()
			show[key] = not show[key]
			chip.BackgroundColor3 = if show[key] then col else GREY
			redraw()
		end)
	end
	task.defer(redraw)
	page:GetPropertyChangedSignal("AbsoluteSize"):Connect(redraw)
end

---------------------------------------------------------------------
-- Settings
---------------------------------------------------------------------
local function openSettings()
	local page = openSub("Settings")
	local a = api :: Api
	local st = a.settings
	local list = new("ScrollingFrame", {
		BackgroundColor3 = PANEL,
		BackgroundTransparency = 0.08,
		Position = UDim2.fromOffset(0, 46),
		Size = UDim2.new(1, 0, 1, -46),
		CanvasSize = UDim2.fromOffset(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = GOLD,
		BorderSizePixel = 0,
		Parent = page,
	}, {
		corner(10),
		new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }),
		new("UIPadding", { PaddingLeft = UDim.new(0, 20), PaddingRight = UDim.new(0, 20), PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12) }),
	})
	local order = 0
	local function heading(t: string)
		order += 1
		local h = text({ Text = t, FontFace = HEAVY, TextSize = 15, TextColor3 = GOLD, Size = UDim2.new(1, 0, 0, 30), LayoutOrder = order, Parent = list })
		h.TextYAlignment = Enum.TextYAlignment.Bottom
	end
	local function row(label: string): Frame
		order += 1
		local r = new("Frame", { BackgroundColor3 = NAVY, BackgroundTransparency = 0.3, Size = UDim2.new(1, 0, 0, 46), LayoutOrder = order, Parent = list }, { corner(8) })
		text({ Text = label, FontFace = BOLD, TextSize = 18, Position = UDim2.fromOffset(14, 0), Size = UDim2.new(0.4, 0, 1, 0), Parent = r })
		return r
	end
	-- a row of choices; the picked one is mint
	local function choices(r: Frame, options: { string }, current: () -> string, pick: (string) -> ())
		local holder = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.new(0.58, 0, 0, 34), Parent = r }, {
			new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Right }),
		})
		local buttons = {}
		local function refresh()
			local cur = current()
			for name, b in buttons do
				b.BackgroundColor3 = if name == cur then MINT else Color3.fromRGB(34, 46, 84)
				b.TextColor3 = if name == cur then NAVY0 else WHITE
			end
		end
		for k, name in options do
			local b = new("TextButton", { AutoButtonColor = false, Text = name, FontFace = HEAVY, TextSize = 15, Size = UDim2.fromOffset(math.max(84, #name * 10 + 24), 34), LayoutOrder = k, Parent = holder }, { corner(8) })
			b.MouseEnter:Connect(hoverSound)
			b.Activated:Connect(function()
				selectSound()
				pick(name)
				refresh()
				a.saveSettings()
			end)
			buttons[name] = b
		end
		refresh()
	end
	-- a slider 0..1
	local function slider(r: Frame, get: () -> number, set: (number) -> ())
		local back = new("TextButton", { AutoButtonColor = false, Text = "", BackgroundColor3 = Color3.fromRGB(34, 46, 84), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -70, 0.5, 0), Size = UDim2.new(0.5, 0, 0, 10), Parent = r }, { corner(5) })
		local fill = new("Frame", { BackgroundColor3 = MINT, Size = UDim2.fromScale(get(), 1), Parent = back }, { corner(5) })
		local knob = new("Frame", { BackgroundColor3 = WHITE, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(get(), 0.5), Size = UDim2.fromOffset(22, 22), Parent = back }, {
			new("UICorner", { CornerRadius = UDim.new(1, 0) }),
			new("UIStroke", { Color = MINT, Thickness = 3 }),
		})
		local value = text({ Text = "", FontFace = HEAVY, TextSize = 16, TextColor3 = MINT, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(52, 30), TextXAlignment = Enum.TextXAlignment.Right, Parent = r })
		local function show(v: number)
			fill.Size = UDim2.fromScale(v, 1)
			knob.Position = UDim2.fromScale(v, 0.5)
			value.Text = tostring(math.floor(v * 100 + 0.5)) .. "%"
		end
		show(get())
		local held = false
		local function at(x: number)
			local v = math.clamp((x - back.AbsolutePosition.X) / back.AbsoluteSize.X, 0, 1)
			v = math.floor(v * 20 + 0.5) / 20
			set(v)
			show(v)
		end
		back.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				held = true
				at(input.Position.X)
			end
		end)
		local c1 = UserInputService.InputChanged:Connect(function(input)
			if held and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				at(input.Position.X)
			end
		end)
		local c2 = UserInputService.InputEnded:Connect(function(input)
			if held and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
				held = false
				selectSound()
				a.saveSettings()
			end
		end)
		page.Destroying:Connect(function()
			c1:Disconnect()
			c2:Disconnect()
		end)
	end

	heading("MAP")
	choices(row("Mini map"), { "ON", "OFF" }, function()
		return if Minimap.isVisible() then "ON" else "OFF"
	end, function(v)
		Minimap.setVisible(v == "ON")
		st.Minimap = { on = v == "ON", corner = (st.Minimap and st.Minimap.corner) or "TopRight" }
	end)
	local CORNERS = { ["TOP RIGHT"] = "TopRight", ["TOP LEFT"] = "TopLeft", ["BOTTOM RIGHT"] = "BottomRight", ["BOTTOM LEFT"] = "BottomLeft" }
	choices(row("Mini map spot"), { "TOP RIGHT", "TOP LEFT", "BOTTOM RIGHT", "BOTTOM LEFT" }, function()
		local c = (st.Minimap and st.Minimap.corner) or "TopRight"
		for k, v in CORNERS do
			if v == c then
				return k
			end
		end
		return "TOP RIGHT"
	end, function(v)
		Minimap.setCorner(CORNERS[v])
		st.Minimap = { on = Minimap.isVisible(), corner = CORNERS[v] }
	end)

	heading("GRAPHICS")
	choices(row("Quality"), { "LOW", "MEDIUM", "HIGH", "ULTRA" }, function()
		return string.upper(st.Graphics or "HIGH")
	end, function(v)
		local name = string.sub(v, 1, 1) .. string.lower(string.sub(v, 2))
		st.Graphics = name
		WorldFx.setQuality(name)
	end)

	heading("CAMERA")
	local function fx(): any
		return table.clone(Driving.camFx)
	end
	local function setFx(t: any)
		UI.setCamFx(t)
		if UI.onCamFxChanged then
			UI.onCamFxChanged(t) -- (Main saves it with the settings)
		end
	end
	local LEVEL = { OFF = 0, LOW = 0.5, NORMAL = 1 }
	local function levelName(v: number): string
		return if v <= 0 then "OFF" elseif v < 1 then "LOW" else "NORMAL"
	end
	choices(row("Camera shake"), { "OFF", "LOW", "NORMAL" }, function()
		return levelName(Driving.camFx.shake)
	end, function(v)
		local t = fx()
		t.shake = LEVEL[v]
		setFx(t)
	end)
	choices(row("Head movement"), { "OFF", "LOW", "NORMAL" }, function()
		return levelName(Driving.camFx.head)
	end, function(v)
		local t = fx()
		t.head = LEVEL[v]
		setFx(t)
	end)
	choices(row("Motion blur"), { "ON", "OFF" }, function()
		return if Driving.camFx.blur then "ON" else "OFF"
	end, function(v)
		local t = fx()
		t.blur = v == "ON"
		setFx(t)
	end)
	do
		local r = row("Chase camera FOV")
		local holder = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(180, 34), Parent = r })
		local value = text({ Text = "", FontFace = HEAVY, TextSize = 18, TextColor3 = MINT, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(46, 0), Size = UDim2.fromOffset(88, 34), Parent = holder })
		local function show()
			value.Text = tostring(Driving.camFx.fov)
		end
		show()
		for k, d in { -2, 2 } do
			local b = button(if d < 0 then "−" else "+", Color3.fromRGB(34, 46, 84), { Position = UDim2.fromOffset(if k == 1 then 0 else 142, 0), Size = UDim2.fromOffset(38, 34), TextSize = 22, Parent = holder })
			b.Activated:Connect(function()
				selectSound()
				local t = fx()
				t.fov = math.clamp(t.fov + d, Config.Camera.FovMin, Config.Camera.FovMax)
				setFx(t)
				show()
			end)
		end
	end
	choices(row("Calm motion (less shake and blur)"), { "ON", "OFF" }, function()
		local c = Driving.camFx
		return if c.shake == 0 and c.head == 0 and not c.blur then "ON" else "OFF"
	end, function(v)
		local t = fx()
		if v == "ON" then
			t.shake, t.head, t.blur = 0, 0, false
		else
			t.shake, t.head, t.blur = 1, 1, true
		end
		setFx(t)
	end)

	heading("DRIVING")
	choices(row("Speed units"), { "MPH", "KM/H" }, function()
		return if st.Units == "kmh" then "KM/H" else "MPH"
	end, function(v)
		local u = if v == "KM/H" then "kmh" else "mph"
		UI.setUnits(u)
		if UI.onUnitsChanged then
			UI.onUnitsChanged(u)
		end
	end)
	choices(row("Gearbox"), { "AUTO", "MANUAL" }, function()
		return if st.Gearbox == "Manual" then "MANUAL" else "AUTO"
	end, function(v)
		local mode = if v == "MANUAL" then "Manual" else "Auto"
		UI.setGearboxLabel(mode)
		if UI.onGearboxChanged then
			UI.onGearboxChanged(mode)
		end
	end)
	choices(row("Controls on screen"), { "SHOW", "HIDE" }, function()
		return if st.HideKeys then "HIDE" else "SHOW"
	end, function(v)
		st.HideKeys = v == "HIDE"
		UI.toggleControls(v == "SHOW")
	end)

	heading("SOUND")
	slider(row("Music"), function()
		return if type(st.Music) == "number" then st.Music else 1
	end, function(v)
		st.Music = v
		Audio.setMusicLevel(v)
	end)
	slider(row("Sound effects"), function()
		return if type(st.Sfx) == "number" then st.Sfx else 1
	end, function(v)
		st.Sfx = v
		Audio.setSfxLevel(v)
	end)
	do
		local r = row("Radio")
		local b = button(Audio.stationName() .. "  ▶", Color3.fromRGB(34, 46, 84), { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(240, 34), TextSize = 16, Parent = r })
		b.Activated:Connect(function()
			selectSound()
			b.Text = Audio.nextStation() .. "  ▶"
		end)
	end

	heading("MORE")
	do
		local r = row("Photo mode")
		local b = button("OPEN", BLUE, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(120, 34), TextSize = 16, Parent = r })
		b.Activated:Connect(function()
			selectSound()
			closeMenu()
			a.openPhoto()
		end)
	end
	order += 1
	text({ Text = table.concat(Config.Credits, "\n"), FontFace = MEDIUM, TextSize = 13, TextColor3 = SUB, TextWrapped = true, AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.new(1, 0, 0, 20), LayoutOrder = order, Parent = list })
end

---------------------------------------------------------------------
-- The first car: 1 of 3
---------------------------------------------------------------------
local function statBar(parent: Instance, y: number, label: string, k: number, valueText: string)
	text({ Text = label, FontFace = BOLD, TextSize = 14, TextColor3 = SUB, Position = UDim2.fromOffset(0, y), Size = UDim2.fromOffset(120, 18), Parent = parent })
	text({ Text = valueText, FontFace = HEAVY, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, y), Size = UDim2.fromOffset(120, 18), Parent = parent })
	local back = new("Frame", { BackgroundColor3 = Color3.fromRGB(34, 46, 84), Position = UDim2.fromOffset(0, y + 21), Size = UDim2.new(1, 0, 0, 8), Parent = parent }, { corner(4) })
	new("Frame", { BackgroundColor3 = MINT, Size = UDim2.fromScale(math.clamp(k, 0.04, 1), 1), Parent = back }, { corner(4) })
end

local BEST_TOP, BEST_060 = 1, 99
for _, c in Cars.List do
	BEST_TOP = math.max(BEST_TOP, c.TopSpeed)
	BEST_060 = math.min(BEST_060, c.ZeroToSixty)
end
local function speedText(mph: number): string
	return if Driving.units == "kmh" then string.format("%d km/h", math.floor(mph * 1.609 + 0.5)) else string.format("%d mph", mph)
end
local function carStats(parent: Instance, y: number, spec: any)
	statBar(parent, y, "TOP SPEED", spec.TopSpeed / BEST_TOP, speedText(spec.TopSpeed))
	statBar(parent, y + 38, "0-60 MPH", BEST_060 / spec.ZeroToSixty, string.format("%.1f s", spec.ZeroToSixty))
	statBar(parent, y + 76, "HANDLING", spec.Handling, string.format("%d / 100", math.floor(spec.Handling * 100 + 0.5)))
end

openClaim = function()
	if claimed() then
		return
	end
	local page = openSub("Pick your first car")
	text({ Text = "It's yours for good. You can buy more at Legends Motors.", FontFace = MEDIUM, TextSize = 17, TextColor3 = SUB, Position = UDim2.fromOffset(136, 34), Size = UDim2.fromOffset(700, 22), Parent = page })
	local picked: string? = nil
	local cards: { [string]: TextButton } = {}
	local confirm: TextButton
	local n = #Config.Menu.StarterChoices
	local cw = (W - (n - 1) * 16) / n
	for k, choice in Config.Menu.StarterChoices do
		local spec = Cars.ById[choice.id]
		if not spec then
			continue
		end
		local card: TextButton = new("TextButton", { AutoButtonColor = false, Text = "", BackgroundColor3 = WHITE, Position = UDim2.fromOffset((k - 1) * (cw + 16), 66), Size = UDim2.fromOffset(cw, 268), Parent = page }, {
			corner(10),
			gradient(Color3.fromRGB(46, 70, 140), Color3.fromRGB(18, 28, 60), 115),
		})
		new("UIStroke", { Name = "Pick", Color = MINT, Thickness = 4, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = card })
		local body = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 16), Size = UDim2.new(1, -40, 1, -32), Parent = card })
		text({ Text = string.upper(Cars.ClassLabels[spec.Class] or spec.Class), FontFace = HEAVY, TextSize = 13, TextColor3 = GOLD, Size = UDim2.new(1, 0, 0, 16), Parent = body })
		text({ Text = spec.Name, FontFace = HEAVY, TextSize = 28, TextScaled = true, Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, -44, 0, 34), Parent = body })
		new("Frame", { BackgroundColor3 = spec.Color, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 20), Size = UDim2.fromOffset(30, 30), Parent = body }, {
			new("UICorner", { CornerRadius = UDim.new(1, 0) }),
			new("UIStroke", { Color = WHITE, Thickness = 2 }),
		})
		text({ Text = "“" .. choice.feel .. "”", FontFace = BOLD, TextSize = 18, TextColor3 = MINT, Position = UDim2.fromOffset(0, 58), Size = UDim2.new(1, 0, 0, 24), Parent = body })
		carStats(body, 96, spec)
		cards[choice.id] = card
		focusable(card, function()
			picked = choice.id
			for id, c in cards do
				(c:FindFirstChild("Pick") :: UIStroke).Transparency = if id == picked then 0 else 1
			end
			confirm.Text = "CLAIM THE " .. string.upper(spec.Name)
			confirm.BackgroundColor3 = MINT
		end, MINT)
	end
	confirm = button("PICK A CAR ABOVE", GREY, { Position = UDim2.fromOffset(0, 348), Size = UDim2.new(1, 0, 0, 56), TextSize = 24, Parent = page })
	focusable(confirm, function()
		if not picked or not api then
			return
		end
		confirm.Text = "ONE MOMENT..."
		local result = api.claim(picked)
		if result.ok then
			UI.popup("YOUR FIRST CAR", 0, GOLD)
			local id = picked
			closeMenu()
			api.drive(id)
		else
			confirm.Text = result.message or "Try again"
		end
	end, MINT)
end

---------------------------------------------------------------------
-- The tabs' pages
---------------------------------------------------------------------
local function playNow()
	if not claimed() then
		openClaim()
		return
	end
	if Driving.isDriving() then
		closeMenu()
		return
	end
	local character = player.Character
	if character and character.Parent then
		-- on foot: back to walking (the car is where you left it, F gets in)
		closeMenu()
		return
	end
	-- the start screen: your selected car out on the road
	local id = data().Selected
	closeMenu()
	if api and id then
		api.drive(id)
	end
end

local function buildCampaign(page: Frame)
	local y0 = 0
	local hTall = page.Size.Y.Offset
	local c1, c2 = 300, 520
	local c3 = W - c1 - c2 - 24
	local x2, x3 = c1 + 12, c1 + c2 + 24
	local topH = 196
	local lowY = topH + 12
	local lowH = hTall - lowY

	-- ACHIEVEMENTS (tall, left)
	local ach = tile(page, 0, y0, c1, hTall, { top = Color3.fromRGB(122, 74, 214), bottom = Color3.fromRGB(56, 30, 120), title = "Achievements", sub = "", art = MenuArt.menu_trophy, artSize = Vector2.new(250, 250), artPos = UDim2.new(1, 10, 0.5, 0), titleSize = 34 })
	local achSub = ach:FindFirstChild("Sub") :: TextLabel
	achSub.Size = UDim2.new(1, -40, 0, 70)
	focusable(ach, function()
		closeMenu()
		if api then
			api.openGoals()
		end
	end)

	-- WORLD MAP (wide, top)
	local mapTile = tile(page, x2, y0, c2 + 12 + c3, topH, { top = Color3.fromRGB(20, 44, 80), bottom = Color3.fromRGB(10, 22, 44), title = "World Map", titleSize = 44 })
	local mapPane = new("Frame", { Name = "MapPane", BackgroundColor3 = Color3.fromRGB(14, 34, 58), Size = UDim2.fromScale(1, 1), ZIndex = 1, Parent = mapTile })
	local shadeL = new("Frame", { BackgroundColor3 = NAVY0, BorderSizePixel = 0, Size = UDim2.new(0.55, 0, 1, 0), ZIndex = 2, Parent = mapTile }, {
		new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) }) }),
	})
	local _ = shadeL
	local chips = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 20, 1, -14), Size = UDim2.new(1, -40, 0, 32), ZIndex = 4, Parent = mapTile }, {
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Center }),
	})
	local function chip(t: string, color: Color3, order: number): TextLabel
		local c = text({ Text = t, FontFace = HEAVY, TextSize = 16, TextColor3 = NAVY0, BackgroundColor3 = color, BackgroundTransparency = 0, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 30), LayoutOrder = order, ZIndex = 5, Parent = chips })
		new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = c })
		corner(8).Parent = c
		return c
	end
	local timeChip = chip("", WHITE, 1)
	local weatherChip = chip("", WHITE, 2)
	local placeChip = chip("", GOLD, 3)
	local youDot = new("Frame", { BackgroundColor3 = MINT, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(14, 14), ZIndex = 3, Parent = mapTile }, {
		new("UICorner", { CornerRadius = UDim.new(1, 0) }),
		new("UIStroke", { Color = NAVY0, Thickness = 3 }),
	})
	local function refreshMap()
		if not mapPane.Parent or sub then
			return
		end
		local p = here()
		local cx, cz = MAP_CENTRE.X, MAP_CENTRE.Y
		if p.X > 10000 then
			cx, cz = p.X + 600, p.Z
		end
		local scale = 0.085
		placeMap(mapPane, cx, cz, scale)
		youDot.Position = UDim2.fromOffset((p.X - cx) * scale + mapPane.AbsoluteSize.X / scaler.Scale / 2, (p.Z - cz) * scale + mapPane.AbsoluteSize.Y / scaler.Scale / 2)
		timeChip.Text = timeOfDay()
		weatherChip.Text = if Weather.isRaining() then "Rain" else "Clear"
		placeChip.Text = district()
	end
	table.insert(refreshers, refreshMap)
	focusable(mapTile, openWorldMap)

	-- PLAY (the big highlighted one)
	local play = tile(page, x2, lowY, c2, lowH, { top = Color3.fromRGB(70, 236, 176), bottom = Color3.fromRGB(18, 150, 120), title = "Play", sub = "", art = MenuArt.menu_play, artSize = Vector2.new(lowH * 2, lowH), artPos = UDim2.new(1, -6, 0.5, 0), titleSize = 52, dark = true })
	new("UIStroke", { Color = WHITE, Thickness = 4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = play })
	local playSub = play:FindFirstChild("Sub") :: TextLabel
	playSub.Size = UDim2.new(0.62, 0, 0, 60)
	local playFocus = focusable(play, playNow, GOLD)
	table.insert(refreshers, function()
		local title = play:FindFirstChild("Title") :: TextLabel
		if not claimed() then
			title.Text = "Play"
			playSub.Text = "First, pick your free car"
		elseif Driving.isDriving() then
			title.Text = "Play"
			playSub.Text = "Back to the road"
		else
			title.Text = "Play"
			playSub.Text = "Drive your car out"
		end
		local ok, Goals = pcall(function()
			return require(script.Parent:WaitForChild("GoalsClient", 1)) :: any
		end)
		if ok and Goals and Goals.getState then
			local done, total, nxt = Goals.getState()
			if nxt then
				playSub.Text ..= "\nNext goal: " .. tostring(nxt.text)
			end
			achSub.Text = string.format("Legends Path %d / %d\nCars %d / %d", done, total, #ownedList(), #Cars.List)
		else
			achSub.Text = string.format("Cars %d / %d", #ownedList(), #Cars.List)
		end
	end)

	-- SETTINGS
	local set = tile(page, x3, lowY, c3, lowH, { top = Color3.fromRGB(58, 98, 190), bottom = Color3.fromRGB(26, 46, 104), title = "Settings", sub = "Map, graphics, camera, sound", art = MenuArt.menu_settings, artSize = Vector2.new(150, 150), artPos = UDim2.new(1, 6, 0.52, 0), titleSize = 36 })
	focusable(set, openSettings)
	return playFocus
end

local favs: { [string]: boolean } = {}
local function loadFavs()
	table.clear(favs)
	local st = if api then api.settings else nil
	for _, id in (st and st.Favs) or {} do
		favs[id] = true
	end
end

local function buildCars(page: Frame)
	local listW = 760
	local sortBy = "Brand"
	local search = ""
	local selected: string? = data().Selected
	local header = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0, listW, 0, 40), Parent = page })
	local count = text({ Text = "", FontFace = HEAVY, TextSize = 22, Size = UDim2.fromOffset(200, 40), Parent = header })
	local sorts = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(200, 3), Size = UDim2.fromOffset(330, 34), Parent = header }, {
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }),
	})
	local box = new("TextBox", {
		PlaceholderText = "Search",
		Text = "",
		FontFace = BOLD,
		TextSize = 16,
		TextColor3 = WHITE,
		PlaceholderColor3 = SUB,
		BackgroundColor3 = Color3.fromRGB(34, 46, 84),
		ClearTextOnFocus = false,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 3),
		Size = UDim2.fromOffset(210, 34),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = header,
	}, { corner(8), new("UIPadding", { PaddingLeft = UDim.new(0, 12) }) })
	local scroll = new("ScrollingFrame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 48),
		Size = UDim2.new(0, listW, 1, -48),
		CanvasSize = UDim2.fromOffset(0, 0),
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = GOLD,
		BorderSizePixel = 0,
		Parent = page,
	})
	local side = new("Frame", { BackgroundColor3 = PANEL, BackgroundTransparency = 0.05, Position = UDim2.fromOffset(listW + 16, 0), Size = UDim2.new(1, -listW - 16, 1, 0), Parent = page }, { corner(10) })

	local fillSide: () -> ()
	local rebuild: () -> ()

	fillSide = function()
		for _, c in side:GetChildren() do
			if not c:IsA("UICorner") then
				c:Destroy()
			end
		end
		local spec = selected and Cars.ById[selected]
		if not spec then
			text({ Text = "Pick a car", FontFace = HEAVY, TextSize = 24, Position = UDim2.fromOffset(20, 18), Size = UDim2.fromOffset(300, 30), Parent = side })
			return
		end
		local body = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 16), Size = UDim2.new(1, -40, 1, -32), Parent = side })
		text({ Text = Cars.upper(Cars.makeOf(spec.Name)), FontFace = HEAVY, TextSize = 13, TextColor3 = GOLD, Size = UDim2.new(1, 0, 0, 16), Parent = body })
		text({ Text = spec.Name, FontFace = HEAVY, TextSize = 26, TextScaled = true, Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, -40, 0, 34), Parent = body })
		new("Frame", { BackgroundColor3 = spec.Color, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 20), Size = UDim2.fromOffset(30, 30), Parent = body }, {
			new("UICorner", { CornerRadius = UDim.new(1, 0) }),
			new("UIStroke", { Color = WHITE, Thickness = 2 }),
		})
		local chip = new("Frame", { BackgroundColor3 = tierColor(spec.Tier), Position = UDim2.fromOffset(0, 58), Size = UDim2.fromOffset(78, 22), Parent = body }, { corner(11) })
		text({ Text = string.upper(spec.Tier), FontFace = HEAVY, TextSize = 13, TextColor3 = NAVY0, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), Parent = chip })
		text({ Text = string.upper(Cars.ClassLabels[spec.Class] or spec.Class) .. "  ·  " .. Cars.trimLabel(spec.Id), FontFace = BOLD, TextSize = 14, TextColor3 = SUB, Position = UDim2.fromOffset(88, 58), Size = UDim2.new(1, -88, 0, 22), TextTruncate = Enum.TextTruncate.AtEnd, Parent = body })
		carStats(body, 92, spec)
		local by = 210
		local driving = Driving.getModel()
		local spawn = button(if driving and driving:GetAttribute("CarId") == spec.Id then "DRIVING ✓" else "SPAWN", MINT, { Position = UDim2.fromOffset(0, by), Size = UDim2.new(1, 0, 0, 48), TextSize = 22, Parent = body })
		focusable(spawn, function()
			if ((player:GetAttribute("Wanted") :: number?) or 0) > 0 then
				UI.toast("Lose the police first", RED)
				return
			end
			local Activities = require(script.Parent:WaitForChild("Activities")) :: any
			if Activities.getTarget and Activities.getTarget() then
				UI.toast("Finish your race or job first", RED)
				return
			end
			closeMenu()
			if api then
				api.drive(spec.Id)
			end
		end, GOLD)
		local fav = button(if favs[spec.Id] then "★ FAVOURITE" else "☆ SET AS FAVOURITE", GOLD, { Position = UDim2.fromOffset(0, by + 56), Size = UDim2.new(1, 0, 0, 40), TextSize = 17, Parent = body })
		focusable(fav, function()
			if favs[spec.Id] then
				favs[spec.Id] = nil
			else
				favs[spec.Id] = true
			end
			local list = {}
			for id in favs do
				table.insert(list, id)
			end
			if api then
				api.settings.Favs = list
				api.saveSettings()
			end
			fillSide()
			rebuild()
		end)
		local half = UDim2.new(0.5, -4, 0, 40)
		local custom = button("CUSTOMISE", BLUE, { Position = UDim2.fromOffset(0, by + 104), Size = half, TextSize = 16, Parent = body })
		focusable(custom, function()
			local s = spotById("customs")
			if s then
				Minimap.setWaypoint(s.cf.Position)
				UI.toast("Waypoint: Legends Customs (on your map)", MINT)
			end
			closeMenu()
		end)
		local market = button("SELL / MARKET", BLUE, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, by + 104), Size = half, TextSize = 16, Parent = body })
		focusable(market, function()
			closeMenu()
			if api then
				api.openMarket()
			end
		end)
	end

	local function card(parent: Instance, x: number, y: number, w: number, h: number, id: string)
		local spec = Cars.ById[id]
		local isSel = id == selected
		local b: TextButton = new("TextButton", { AutoButtonColor = false, Text = "", BackgroundColor3 = if isSel then Color3.fromRGB(40, 66, 130) else Color3.fromRGB(24, 34, 70), Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), Parent = parent }, { corner(8) })
		if isSel then
			new("UIStroke", { Color = MINT, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = b })
		end
		new("Frame", { BackgroundColor3 = tierColor(spec.Tier), BorderSizePixel = 0, Size = UDim2.new(0, 5, 1, 0), Parent = b }, { corner(3) })
		text({ Text = spec.Name, FontFace = HEAVY, TextSize = 17, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -60, 0, 20), Parent = b })
		text({ Text = string.upper(spec.Tier) .. "  ·  " .. speedText(spec.TopSpeed) .. "  ·  " .. string.format("%.1f s", spec.ZeroToSixty), FontFace = BOLD, TextSize = 13, TextColor3 = SUB, Position = UDim2.fromOffset(16, 34), Size = UDim2.new(1, -24, 0, 16), Parent = b })
		new("Frame", { BackgroundColor3 = spec.Color, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 10), Size = UDim2.fromOffset(20, 20), Parent = b }, {
			new("UICorner", { CornerRadius = UDim.new(1, 0) }),
			new("UIStroke", { Color = WHITE, Thickness = 1.5 }),
		})
		local tags = (if favs[id] then "★ " else "") .. (if id == data().Selected then "✔ SELECTED" else "")
		if tags ~= "" then
			text({ Text = tags, FontFace = HEAVY, TextSize = 13, TextColor3 = GOLD, Position = UDim2.fromOffset(16, 54), Size = UDim2.new(1, -24, 0, 16), Parent = b })
		end
		focusable(b, function()
			selected = id
			fillSide()
			rebuild()
		end, MINT)
	end

	rebuild = function()
		for _, c in scroll:GetChildren() do
			c:Destroy()
		end
		local owned = ownedList()
		count.Text = string.format("%d / %d owned", #owned, #Cars.List)
		local q = string.lower(search)
		local list = {}
		for _, id in owned do
			local spec = Cars.ById[id]
			if q == "" or string.find(string.lower(spec.Name), q, 1, true) then
				table.insert(list, id)
			end
		end
		local function key(id: string): any
			local s = Cars.ById[id]
			return s
		end
		table.sort(list, function(a, b)
			local sa, sb = key(a), key(b)
			if (favs[a] ~= nil) ~= (favs[b] ~= nil) then
				return favs[a] ~= nil
			end
			if sortBy == "Price" then
				return sa.Price > sb.Price
			elseif sortBy == "Speed" then
				return sa.TopSpeed > sb.TopSpeed
			elseif sortBy == "Newest" then
				return (sa.Order or 0) > (sb.Order or 0)
			end
			local ma, mb = Cars.makeOf(sa.Name), Cars.makeOf(sb.Name)
			if ma ~= mb then
				return ma < mb
			end
			return (sa.Order or 0) < (sb.Order or 0)
		end)
		local cols, gap = 3, 10
		local cw, ch = (listW - 12 - (cols - 1) * gap) / cols, 78
		local y = 0
		-- "Get more cars" first
		local more: TextButton = new("TextButton", { AutoButtonColor = false, Text = "", BackgroundColor3 = Color3.fromRGB(60, 46, 14), Position = UDim2.fromOffset(0, y), Size = UDim2.fromOffset(listW - 12, 52), Parent = scroll }, {
			corner(8),
			new("UIStroke", { Color = GOLD, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		})
		local ic = venueIcon(more, "dealership", 36)
		ic.Position = UDim2.fromOffset(30, 26)
		ic.Active = false
		ic.Interactable = false
		text({ Text = "Get more cars  ·  Legends Motors", FontFace = HEAVY, TextSize = 18, TextColor3 = GOLD, Position = UDim2.fromOffset(60, 0), Size = UDim2.new(1, -70, 1, 0), Parent = more })
		focusable(more, function()
			local s = spotById("dealership")
			if s then
				Minimap.setWaypoint(s.cf.Position)
				UI.toast("Waypoint: Legends Motors (on your map)", MINT)
			end
			closeMenu()
		end, GOLD)
		y += 64
		local lastGroup = nil
		local col = 0
		for _, id in list do
			local spec = Cars.ById[id]
			local group = if favs[id] then "FAVOURITES" elseif sortBy == "Brand" then Cars.upper(Cars.makeOf(spec.Name)) else nil
			if group ~= lastGroup and group then
				if col > 0 then
					y += ch + gap
					col = 0
				end
				text({ Text = group, FontFace = HEAVY, TextSize = 15, TextColor3 = GOLD, Position = UDim2.fromOffset(2, y), Size = UDim2.fromOffset(400, 22), Parent = scroll })
				y += 26
				lastGroup = group
			end
			card(scroll, col * (cw + gap), y, cw, ch, id)
			col += 1
			if col >= cols then
				col = 0
				y += ch + gap
			end
		end
		if col > 0 then
			y += ch + gap
		end
		scroll.CanvasSize = UDim2.fromOffset(0, y)
	end

	for k, name in { "Brand", "Price", "Speed", "Newest" } do
		local b = new("TextButton", { AutoButtonColor = false, Text = name, FontFace = HEAVY, TextSize = 14, Size = UDim2.fromOffset(76, 34), LayoutOrder = k, Parent = sorts }, { corner(8) })
		local function paint()
			b.BackgroundColor3 = if sortBy == name then MINT else Color3.fromRGB(34, 46, 84)
			b.TextColor3 = if sortBy == name then NAVY0 else WHITE
		end
		paint()
		table.insert(refreshers, paint)
		b.MouseEnter:Connect(hoverSound)
		b.Activated:Connect(function()
			selectSound()
			sortBy = name
			for _, r in refreshers do
				r()
			end
			rebuild()
		end)
	end
	box:GetPropertyChangedSignal("Text"):Connect(function()
		search = box.Text
		rebuild()
	end)
	return function()
		loadFavs()
		selected = selected or data().Selected
		table.clear(focusList)
		fillSide()
		rebuild()
	end
end

local function buildStore(page: Frame)
	local items = Config.Menu.Store
	local cols = 3
	local gap = 14
	local cw = (W - (cols - 1) * gap) / cols
	local ch = (page.Size.Y.Offset - gap) / 2
	for k, item in items do
		local col, rowN = (k - 1) % cols, (k - 1) // cols
		local live = item.id ~= nil
		local b = tile(page, col * (cw + gap), rowN * (ch + gap), cw, ch, {
			top = if live then Color3.fromRGB(46, 86, 170) else Color3.fromRGB(56, 62, 80),
			bottom = if live then Color3.fromRGB(20, 34, 80) else Color3.fromRGB(30, 34, 46),
			title = item.name,
			sub = item.effect,
			art = MenuArt[item.art],
			artSize = Vector2.new(150, 150),
			artPos = UDim2.new(1, -4, 0.4, 0),
			titleSize = 28,
		})
		local subLabel = b:FindFirstChild("Sub") :: TextLabel
		subLabel.Size = UDim2.new(0.62, 0, 0, 66)
		subLabel.TextSize = 15
		subLabel.Position = UDim2.new(0, 20, 1, -58)
		local price = new("Frame", { BackgroundColor3 = if live then GREEN else GREY, AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -14), Size = UDim2.fromOffset(130, 34), ZIndex = 4, Parent = b }, { corner(8) })
		local priceText = text({ Text = if live then "..." else "COMING SOON", FontFace = HEAVY, TextSize = 14, TextColor3 = if live then NAVY0 else WHITE, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = price })
		if not live then
			-- greyed until the owner gives the id
			local art = b:FindFirstChild("Art") :: ImageLabel?
			if art then
				art.ImageTransparency = 0.45
				art.ImageColor3 = Color3.fromRGB(170, 176, 190)
			end
		else
			task.spawn(function()
				local ok, info = pcall(function()
					return MarketplaceService:GetProductInfo(item.id, if item.kind == "Pass" then Enum.InfoType.GamePass else Enum.InfoType.Product)
				end)
				if ok and info and info.PriceInRobux then
					priceText.Text = "R$ " .. tostring(info.PriceInRobux)
				else
					priceText.Text = "UNAVAILABLE"
				end
			end)
		end
		focusable(b, function()
			if not live then
				UI.toast(item.name .. ": coming soon", SUB)
				return
			end
			if item.kind == "Pass" then
				MarketplaceService:PromptGamePassPurchase(player, item.id)
			else
				MarketplaceService:PromptProductPurchase(player, item.id)
			end
		end, if live then GREEN else GREY)
	end
end

---------------------------------------------------------------------
-- Tabs, open, close
---------------------------------------------------------------------
local carsRefresh: (() -> ())? = nil
local playFocus: Focus? = nil
local campaignFocus: { Focus } = {}
local storeFocus: { Focus } = {}

switchTab = function(name: string)
	tabName = name
	for n, b in tabButtons do
		local on = n == name
		b.BackgroundTransparency = if on then 0 else 1
		b.TextColor3 = if on then NAVY0 else WHITE
	end
	if sub then
		return
	end
	for n, p in pages do
		p.Visible = n == name
	end
	setFocus(nil)
	table.clear(focusList)
	if name == "CAMPAIGN" then
		for _, f in campaignFocus do
			table.insert(focusList, f)
		end
		setFocus(playFocus)
	elseif name == "STORE" then
		for _, f in storeFocus do
			table.insert(focusList, f)
		end
		setFocus(focusList[1])
	elseif name == "CARS" and carsRefresh then
		carsRefresh()
	end
	-- (a little slide in)
	local p = pages[name]
	if p and not calm then
		p.Position = UDim2.fromOffset(18, 176)
		tween(p, 0.18, { Position = UDim2.fromOffset(0, 176) }, Enum.EasingStyle.Quint)
	end
	for _, r in refreshers do
		r()
	end
end

local function build()
	local pg = player:WaitForChild("PlayerGui")
	gui = new("ScreenGui", { Name = "MainMenu", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 40, Enabled = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = pg })
	local root = new("Frame", { Name = "Root", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = gui })
	buildBackground(root)
	canvas = new("Frame", { Name = "Canvas", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(W, H), Parent = root })
	scaler = new("UIScale", { Parent = canvas })
	local function fit()
		local vp = workspace.CurrentCamera.ViewportSize
		scaler.Scale = math.min((vp.X - 24) / W, (vp.Y - 16) / H)
	end
	fit()
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)

	buildTopBar()
	buildTabs()
	buildHints()
	local pageH = H - 176 - 46
	for _, name in TABS do
		pages[name] = new("Frame", { Name = name, BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 176), Size = UDim2.fromOffset(W, pageH), Visible = false, Parent = canvas })
	end
	-- each page's focusables are collected as it's built
	table.clear(focusList)
	playFocus = buildCampaign(pages.CAMPAIGN)
	campaignFocus = table.clone(focusList)
	table.clear(focusList)
	carsRefresh = buildCars(pages.CARS)
	table.clear(focusList)
	buildStore(pages.STORE)
	storeFocus = table.clone(focusList)
	table.clear(focusList)

	-- keys inside the menu
	UserInputService.InputBegan:Connect(function(input, processed)
		if not isOpen or UserInputService:GetFocusedTextBox() then
			return
		end
		local k = input.KeyCode
		if k == Enum.KeyCode.Q or k == Enum.KeyCode.ButtonL1 then
			if not sub then
				local i = table.find(TABS, tabName) or 1
				selectSound()
				switchTab(TABS[(i - 2) % #TABS + 1])
			end
		elseif k == Enum.KeyCode.E or k == Enum.KeyCode.ButtonR1 then
			if not sub then
				local i = table.find(TABS, tabName) or 1
				selectSound()
				switchTab(TABS[i % #TABS + 1])
			end
		elseif k == Enum.KeyCode.Backspace or k == Enum.KeyCode.ButtonB then
			goBack()
		elseif processed then
			return
		elseif k == Enum.KeyCode.Return or k == Enum.KeyCode.KeypadEnter then
			if focused and focused.button.Parent then
				selectSound()
				focused.activate()
			end
		elseif k == Enum.KeyCode.Left then
			moveFocus(Vector2.new(-1, 0))
		elseif k == Enum.KeyCode.Right then
			moveFocus(Vector2.new(1, 0))
		elseif k == Enum.KeyCode.Up then
			moveFocus(Vector2.new(0, -1))
		elseif k == Enum.KeyCode.Down then
			moveFocus(Vector2.new(0, 1))
		end
	end)

	-- live bits (the map tile, the car name) while it's open
	task.spawn(function()
		while gui and gui.Parent do
			task.wait(1)
			if isOpen and not sub then
				for _, r in refreshers do
					r()
				end
			end
		end
	end)
end

goBack = function()
	if sub then
		selectSound()
		closeSub()
	elseif not startMode then
		selectSound()
		closeMenu()
	end
end

closeMenu = function()
	if not isOpen or not gui then
		return
	end
	isOpen = false
	if sub then
		closeSub()
	end
	GuiService.SelectedObject = nil
	Driving.menuHold = false
	UI.modalOpen = false
	local g = gui
	tween(scaler, 0.16, { Scale = scaler.Scale * 0.97 })
	local b = blur
	if b then
		tween(b, 0.2, { Size = 0 })
	end
	task.delay(if calm then 0 else 0.16, function()
		if not isOpen then
			g.Enabled = false
			local vp = workspace.CurrentCamera.ViewportSize
			scaler.Scale = math.min((vp.X - 24) / W, (vp.Y - 16) / H)
		end
	end)
	if api and api.onClosed then
		api.onClosed()
	end
end

function MainMenu.init(a: Api)
	api = a
	loadFavs()
	build()
end

-- start: the menu as the start screen (no car out yet: nothing to close back to)
function MainMenu.open(start: boolean?)
	if not gui then
		return
	end
	if api then
		pcall(api.refresh)
	end
	loadFavs()
	startMode = start == true
	isOpen = true
	UI.modalOpen = true
	if Driving.isDriving() then
		Driving.menuHold = true
	end
	gui.Enabled = true
	if not blur or not blur.Parent then
		blur = new("BlurEffect", { Name = "MenuBlur", Size = 0, Parent = Lighting })
	end
	tween(blur :: BlurEffect, 0.25, { Size = 14 })
	local vp = workspace.CurrentCamera.ViewportSize
	local target = math.min((vp.X - 24) / W, (vp.Y - 16) / H)
	scaler.Scale = if calm then target else target * 0.96
	tween(scaler, 0.22, { Scale = target }, Enum.EasingStyle.Quint)
	Audio.play("swoosh", 0.25, 1.3)
	GuiService.SelectedObject = nil -- (the HUD's MENU button may still hold the gamepad selection)
	if sub then
		closeSub()
	end
	switchTab("CAMPAIGN")
	-- a new player: straight to the pick
	if not claimed() and startMode then
		task.defer(openClaim)
	end
end

function MainMenu.close()
	closeMenu()
end

function MainMenu.isOpen(): boolean
	return isOpen
end

function MainMenu.toggle()
	if isOpen then
		if not startMode then
			closeMenu()
		end
	else
		MainMenu.open(false)
	end
end

-- (screenshots / tests) open a tab or a page by name
function MainMenu.show(what: string)
	if what == "CAMPAIGN" or what == "CARS" or what == "STORE" then
		if sub then
			closeSub()
		end
		switchTab(what)
	elseif what == "MAP" then
		openWorldMap()
	elseif what == "SETTINGS" then
		openSettings()
	elseif what == "CLAIM" then
		openClaim()
	end
end

-- the saved settings at start (minimap, graphics, sound)
function MainMenu.applySettings(st: { [string]: any })
	if type(st.Minimap) == "table" then
		Minimap.setVisible(st.Minimap.on ~= false)
		Minimap.setCorner(st.Minimap.corner or "TopRight")
	end
	if type(st.Graphics) == "string" then
		WorldFx.setQuality(st.Graphics)
	end
	if type(st.Music) == "number" then
		Audio.setMusicLevel(st.Music)
	end
	if type(st.Sfx) == "number" then
		Audio.setSfxLevel(st.Sfx)
	end
end

local _ = RunService
return MainMenu
