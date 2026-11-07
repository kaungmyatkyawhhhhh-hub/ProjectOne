--[[
	MainMenu (client)
	The City Legends main menu (owner, 2026-11-02, "Main menu (tile style)"): big tiles over the live
	game scene (blurred), a top bar (the car you drive by name, or CLAIM CAR for a new player; the
	player, level and cash on the right) and the tabs CAMPAIGN, CARS, HOUSES, STORE. The look
	(2026-11-04, owner-away step 7: same bar as the dealer menu): dark glass panels, Builder Sans,
	gold for the main action, drawn icons from DealerArt (no emoji, no cartoon tiles).

	  * CAMPAIGN: PLAY (the big highlighted tile: back to driving, or your car out), WORLD MAP (a live
	    map: venue symbols, a card with FAST TRAVEL and SET WAYPOINT), ACHIEVEMENTS (the cars
	    collection and the Legends Path; opens the GOALS screen) and SETTINGS (mini map on / off and
	    corner, graphics, camera, units, gearbox, music and sound sliders, radio, controls).
	  * CARS: your cars by brand (sort, search), a side panel with SPAWN, FAVOURITE, CUSTOMISE (a
	    waypoint to Legends Customs) and MARKET; "Get more cars" sets a waypoint to Legends Motors.
	  * HOUSES (2026-11-04): the house standing in this server (TELEPORT HOME), your blueprints, the
	    house settings (HousingClient's house menu) and Legends Realty (fast travel).
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
local CarStats = require(Shared:WaitForChild("CarStats"))
local CarCare = require(Shared:WaitForChild("CarCare"))
local TravelSpots = require(Shared:WaitForChild("TravelSpots"))
local IsleLayout = require(Shared:WaitForChild("IsleLayout"))

local UI = require(script.Parent:WaitForChild("UI"))
local Audio = require(script.Parent:WaitForChild("Audio"))
local Driving = require(script.Parent:WaitForChild("Driving"))
local Minimap = require(script.Parent:WaitForChild("Minimap"))
local WorldFx = require(script.Parent:WaitForChild("WorldFx"))
local Weather = require(script.Parent:WaitForChild("Weather"))
local LookFx = require(script.Parent:WaitForChild("LookFx"))
local DayCycle = require(script.Parent:WaitForChild("DayCycle"))
local MenuArt = require(script.Parent:WaitForChild("MenuArt"))
local DealerArt = require(script.Parent:WaitForChild("DealerArt"))
local TrailerClient = require(script.Parent:WaitForChild("TrailerClient"))
local CareClient = require(script.Parent:WaitForChild("CareClient"))
local CarUpgrades = require(script.Parent:WaitForChild("CarUpgrades"))

local MainMenu = {}

local player = Players.LocalPlayer

-- the look, the dealer menu's (colour = meaning: MINT the main action, drawn gold; GOLD a gold
-- outline; BLUE / NAVY plain glass; RED close, grey locked, green money)
local NAVY0 = Color3.fromRGB(10, 12, 20) -- the darkest glass
local NAVY = Color3.fromRGB(30, 33, 46)
local PANEL = Color3.fromRGB(18, 21, 32) -- panels (new() gives them the glass edge)
local BLUE = Color3.fromRGB(44, 48, 64)
local GOLD = Color3.fromRGB(255, 196, 82)
local GOLD_D = Color3.fromRGB(226, 146, 40)
local MINT = Color3.fromRGB(255, 197, 83)
local WHITE = Color3.fromRGB(246, 247, 251)
local SUB = Color3.fromRGB(160, 166, 184)
local RED = Color3.fromRGB(236, 72, 78)
local GREY = Color3.fromRGB(72, 76, 92)
local GREEN = Color3.fromRGB(116, 228, 160)

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
	-- a panel is dark glass: a soft gradient and a thin light edge
	if inst:IsA("GuiObject") and inst.BackgroundColor3 == PANEL and inst.BackgroundTransparency < 0.9 and not inst:FindFirstChildOfClass("UIStroke") then
		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(150, 154, 168))
		g.Rotation = 90
		g.Parent = inst
		local e = Instance.new("UIStroke")
		e.Color = Color3.new(1, 1, 1)
		e.Transparency = 0.86
		e.Thickness = 1
		e.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		e.Parent = inst
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
	local primary = color == MINT or color == GREEN
	local base: { [string]: any } = {
		AutoButtonColor = false,
		BackgroundColor3 = if primary then Color3.new(1, 1, 1) else BLUE,
		FontFace = HEAVY,
		Text = label,
		TextColor3 = if primary then NAVY0 elseif color == GOLD then GOLD elseif color == RED then RED else WHITE,
		TextSize = 18,
	}
	for k, v in props do
		base[k] = v
	end
	local b: TextButton = new("TextButton", base, { corner(10) })
	if primary then
		new("UIGradient", { Color = ColorSequence.new(GOLD, GOLD_D), Rotation = 90, Parent = b })
	else
		new("UIGradient", { Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(176, 180, 192)), Rotation = 90, Parent = b })
	end
	local rest = if primary then 0.6 elseif color == GOLD then 0.45 else 0.84
	local edge = new("UIStroke", { Color = if color == GOLD then GOLD else Color3.new(1, 1, 1), Transparency = rest, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = b })
	local scale = new("UIScale", { Parent = b })
	b.MouseEnter:Connect(function()
		hoverSound()
		tween(scale, 0.12, { Scale = 1.03 })
		tween(edge, 0.12, { Transparency = rest * 0.55 })
	end)
	b.MouseLeave:Connect(function()
		tween(scale, 0.12, { Scale = 1 })
		tween(edge, 0.12, { Transparency = rest })
	end)
	b.MouseButton1Down:Connect(function()
		tween(scale, 0.07, { Scale = 0.96 })
	end)
	b.MouseButton1Up:Connect(function()
		tween(scale, 0.14, { Scale = 1.03 })
	end)
	return b
end

-- a drawn icon from the sheet (white, tinted)
local function glyph(name: string, size: number, color: Color3?, props: { [string]: any }?): ImageLabel
	local i = (table.find(DealerArt.icons, name) or 1) - 1
	local c = DealerArt.cell
	local base: { [string]: any } = {
		BackgroundTransparency = 1,
		Image = DealerArt.sheet,
		ImageRectOffset = Vector2.new((i % DealerArt.cols) * c, (i // DealerArt.cols) * c),
		ImageRectSize = Vector2.new(c, c),
		ImageColor3 = color or WHITE,
		Size = UDim2.fromOffset(size, size),
		ScaleType = Enum.ScaleType.Fit,
	}
	if props then
		for k, v in props do
			base[k] = v
		end
	end
	return new("ImageLabel", base)
end

-- key caps for the hints
local function keyCap(parent: Instance, key: string, order: number): Frame
	local f = new("Frame", { BackgroundColor3 = BLUE, Size = UDim2.fromOffset(math.max(26, #key * 9 + 14), 24), LayoutOrder = order, Parent = parent }, {
		corner(6),
		new("UIStroke", { Color = Color3.new(1, 1, 1), Transparency = 0.8, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
	})
	text({ Text = key, FontFace = HEAVY, TextColor3 = WHITE, TextSize = 13, Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center, Parent = f })
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
local TABS = { "CAMPAIGN", "CARS", "HOUSES", "STORE" }
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
		new("UIStroke", { Name = "FocusStroke", Color = color or GOLD, Thickness = 2, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = b })
	end
	local f = { button = b, activate = activate }
	table.insert(focusList, f)
	b.MouseEnter:Connect(function()
		setFocus(f)
	end)
	-- (2026-11-04) a double tap ran it twice (PLAY and SPAWN asked for the car twice): not once the
	-- menu is shutting, and not the same press again
	local lastPress = 0
	b.Activated:Connect(function()
		if not isOpen or os.clock() - lastPress < 0.35 then
			return
		end
		lastPress = os.clock()
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

-- how many of the cars on sale you own (retired ones you keep don't count towards the total)
local function ownedOnSale(): number
	local n = 0
	for _, id in ownedList() do
		if Cars.forSale(id) then
			n += 1
		end
	end
	return n
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
	-- the live game behind a dark veil (the blur is MenuBlur in Lighting), darker at the edges
	new("Frame", { Name = "Back", Size = UDim2.fromScale(1, 1), BackgroundColor3 = WHITE, BackgroundTransparency = 0, BorderSizePixel = 0, Parent = root }, {
		new("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new(Color3.fromRGB(26, 29, 42), NAVY0),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.22), NumberSequenceKeypoint.new(0.5, 0.3), NumberSequenceKeypoint.new(1, 0.12) }),
		}),
	})
end

-- (2026-11-03, "classes only": the Starter / Mid / High tiers aren't shown any more) a car's parts
-- (its level and CP too) from CarUpgrades, for the class badge
local function partsOf(id: string): { [string]: string }?
	local info = if UI.carInfo then UI.carInfo(id) else nil
	return info and info.parts
end

local openClaim: () -> ()

local function buildTopBar()
	topLeft = new("Frame", { Name = "Car", BackgroundColor3 = PANEL, BackgroundTransparency = 0.1, Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(400, 104), Parent = canvas }, { corner(10) })
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
			local b = button("CLAIM CAR", MINT, { Position = UDim2.fromOffset(22, 16), Size = UDim2.new(1, -40, 0, 50), TextSize = 26, Parent = fill })
			text({ Text = "Pick your first car: it's free", TextColor3 = SUB, TextSize = 15, FontFace = MEDIUM, Position = UDim2.fromOffset(24, 72), Size = UDim2.new(1, -40, 0, 20), Parent = fill })
			b.Activated:Connect(function()
				selectSound()
				openClaim()
			end)
			task.spawn(function()
				while b.Parent do
					tween(b, 0.6, { BackgroundColor3 = Color3.fromRGB(255, 226, 176) }, Enum.EasingStyle.Sine)
					task.wait(0.6)
					tween(b, 0.6, { BackgroundColor3 = Color3.new(1, 1, 1) }, Enum.EasingStyle.Sine)
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
		UI.classBadgeFor(spec.Id, partsOf(spec.Id), { Height = 22, Position = UDim2.fromOffset(24, 72), Parent = fill })
		local info = if UI.carInfo then UI.carInfo(spec.Id) else nil
		text({ Text = string.upper(Cars.ClassLabels[spec.Class] or spec.Class) .. (if info then "  ·  CAR LV " .. info.level else ""), FontFace = BOLD, TextSize = 14, TextColor3 = SUB, Position = UDim2.fromOffset(98, 72), Size = UDim2.fromOffset(220, 22), Parent = fill })
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
	local strip = new("Frame", { Name = "Tabs", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 118), Size = UDim2.new(1, 0, 0, 46), Parent = canvas }, { corner(6) })
	new("Frame", { BackgroundColor3 = WHITE, BackgroundTransparency = 0.86, BorderSizePixel = 0, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 1), Parent = strip })
	local row = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.fromOffset(#TABS * 196, 36), Parent = strip }, {
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
		b.BackgroundTransparency = 1
		new("Frame", { Name = "Under", BackgroundColor3 = GOLD, BorderSizePixel = 0, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 4), Size = UDim2.new(0.5, 0, 0, 3), Visible = false, Parent = b }, { corner(2) })
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
			Text = if side < 0 then "Q" else "E",
			FontFace = HEAVY,
			TextSize = 16,
			TextColor3 = WHITE,
			BackgroundColor3 = BLUE,
			AnchorPoint = Vector2.new(if side < 0 then 0 else 1, 0),
			Position = if side < 0 then UDim2.fromOffset(2, 8) else UDim2.new(1, -2, 0, 8),
			Size = UDim2.fromOffset(64, 30),
			TextXAlignment = if side < 0 then Enum.TextXAlignment.Right else Enum.TextXAlignment.Left,
			Parent = strip,
		}, {
			corner(8),
			new("UIStroke", { Color = Color3.new(1, 1, 1), Transparency = 0.84, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
			new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }),
		})
		glyph(if side < 0 then "back" else "next", 16, WHITE, { AnchorPoint = Vector2.new(if side < 0 then 0 else 1, 0.5), Position = UDim2.new(if side < 0 then 0 else 1, 0, 0.5, 0), Parent = b })
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
local outOfMenu: (after: (() -> ())?) -> ()

local function buildHints()
	hintsBar = new("Frame", { Name = "Hints", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, H - 36), Size = UDim2.new(1, 0, 0, 32), Parent = canvas }, {
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), VerticalAlignment = Enum.VerticalAlignment.Center }),
	})
	local hintsShown = ""
	local function refresh()
		local pad = UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled
		local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled and not pad
		-- (2026-11-04) only when they change: rebuilt every second, a tap across the rebuild was lost,
		-- and on a phone the Close pill is the way out
		local shownNow = tostring(sub ~= nil) .. tostring(startMode) .. tostring(pad) .. tostring(touch)
		if shownNow == hintsShown then
			return
		end
		hintsShown = shownNow
		for _, c in hintsBar:GetChildren() do
			if not c:IsA("UIListLayout") then
				c:Destroy()
			end
		end
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
type TileOpts = { title: string, sub: string?, icon: string?, iconSize: number?, iconPos: UDim2?, titleSize: number?, primary: boolean? }

-- a tile: dark glass, or gold for the main action, with a drawn icon
local function tile(parent: Instance, x: number, y: number, w: number, h: number, o: TileOpts): TextButton
	local b: TextButton = new("TextButton", { AutoButtonColor = false, Text = "", BackgroundColor3 = WHITE, BackgroundTransparency = if o.primary then 0 else 0.06, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), ClipsDescendants = true, Parent = parent }, {
		corner(12),
		if o.primary then gradient(GOLD, GOLD_D, 100) else gradient(Color3.fromRGB(38, 42, 56), PANEL, 100),
	})
	-- a thin highlight along the top
	new("Frame", { BackgroundColor3 = WHITE, BackgroundTransparency = if o.primary then 0.55 else 0.8, BorderSizePixel = 0, Position = UDim2.fromOffset(14, 1), Size = UDim2.new(1, -28, 0, 1), Parent = b })
	if o.icon then
		local size = o.iconSize or math.floor(math.min(h * 0.46, 120))
		glyph(o.icon, size, if o.primary then NAVY0 else GOLD, {
			Name = "Art",
			AnchorPoint = Vector2.new(1, 0),
			Position = o.iconPos or UDim2.new(1, -20, 0, 20),
			ImageTransparency = if o.primary then 0.12 else 0,
			ZIndex = 2,
			Parent = b,
		})
	end
	local ink = if o.primary then NAVY0 else WHITE
	text({ Name = "Title", Text = o.title, FontFace = HEAVY, TextSize = o.titleSize or 40, TextColor3 = ink, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Top, Position = UDim2.fromOffset(20, 16), Size = UDim2.new(1, -40, 0, (o.titleSize or 40) * 2.2), ZIndex = 3, Parent = b })
	if o.sub then
		text({ Name = "Sub", Text = o.sub, FontFace = MEDIUM, TextSize = 17, TextColor3 = ink, TextTransparency = 0.1, TextWrapped = true, TextYAlignment = Enum.TextYAlignment.Bottom, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 20, 1, -14), Size = UDim2.new(1, -40, 0, 44), ZIndex = 3, Parent = b })
	end
	-- (2026-11-04) a thin light edge, brighter on hover, like the dealer menu's glass
	local edge = new("UIStroke", { Color = WHITE, Transparency = 0.84, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = b })
	-- hover: lift a little; press: squeeze
	local scale = new("UIScale", { Parent = b })
	b.MouseEnter:Connect(function()
		hoverSound()
		tween(scale, 0.12, { Scale = 1.015 })
		tween(edge, 0.12, { Transparency = 0.45 })
	end)
	b.MouseLeave:Connect(function()
		tween(scale, 0.12, { Scale = 1 })
		tween(edge, 0.12, { Transparency = 0.84 })
	end)
	b.MouseButton1Down:Connect(function()
		tween(scale, 0.07, { Scale = 0.985 })
	end)
	b.MouseButton1Up:Connect(function()
		tween(scale, 0.14, { Scale = 1.015 })
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
	fuel = Color3.fromRGB(120, 200, 255),
	service = Color3.fromRGB(255, 170, 90),
}
local function venueIcon(parent: Instance, kind: string, size: number): ImageButton
	local k2 = table.find(MenuArt.venues2, kind)
	local k = k2 or table.find(MenuArt.venues, kind) or 1
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
		Image = if k2 then MenuArt.menu_venues2 else MenuArt.menu_venues,
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
		if s.icon ~= "race" and s.icon ~= "delivery" and s.icon ~= "fuel" and s.icon ~= "service" then
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
	local back = button("BACK", BLUE, { Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(120, 36), TextSize = 16, Parent = f })
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
	local homeLot = player:GetAttribute("HouseLot")
	if homeLot then
		-- your house (the server knows where) (2026-11-04: from the lot list; it looked for a "Houses"
		-- folder that isn't there, and the house itself may not be streamed in)
		for _, lot in IsleLayout.lots() do
			if lot.id == homeLot then
				table.insert(spots, { id = "home", name = "Your House", icon = "home", info = TravelSpots.INFO.home, cf = lot.frame })
				break
			end
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
-- The leaderboard (2026-11-04): the J key's board, here for phones and gamepads too
---------------------------------------------------------------------
local function openLeaderboard()
	local page = openSub("Leaderboard")
	local paneW = (W - 16) / 2
	local paneH = H - 176 - 46 - 46 - 62
	local function pane(x: number): TextLabel
		local f = new("Frame", { BackgroundColor3 = PANEL, BackgroundTransparency = 0.08, Position = UDim2.fromOffset(x, 46), Size = UDim2.fromOffset(paneW, paneH), Parent = page }, { corner(10) })
		return text({ Text = "Loading...", FontFace = BOLD, TextSize = 19, TextYAlignment = Enum.TextYAlignment.Top, Position = UDim2.fromOffset(20, 14), Size = UDim2.new(1, -40, 1, -28), Parent = f })
	end
	local speedList, driftList = pane(0), pane(paneW + 16)
	local mine = text({ Text = "", FontFace = BOLD, TextSize = 18, TextColor3 = GOLD, TextWrapped = true, Position = UDim2.fromOffset(4, 46 + paneH + 8), Size = UDim2.new(1, -8, 0, 46), Parent = page })
	local function lines(title: string, rows: any, unit: string): string
		local out = { title, "" }
		for i, r in (if type(rows) == "table" then rows else {}) :: { any } do
			if type(r) == "table" then
				table.insert(out, string.format("%d. %s  %s%s", i, tostring(r.name), tostring(r.value), unit))
			end
		end
		if #out == 2 then
			table.insert(out, "No one yet")
		end
		return table.concat(out, "\n")
	end
	task.spawn(function()
		local remotes = ReplicatedStorage:FindFirstChild("Remotes")
		local call = remotes and remotes:FindFirstChild("ChallengeBoard")
		local ok, res = false, nil
		if call and call:IsA("RemoteFunction") then
			ok, res = pcall(function()
				return (call :: RemoteFunction):InvokeServer()
			end)
		end
		if not page.Parent then
			return
		end
		if not (ok and type(res) == "table") then
			speedList.Text = "Couldn't load the board: try again"
			driftList.Text = ""
			return
		end
		speedList.Text = lines("TOP SPEED", res.speed, " mph")
		driftList.Text = lines("BEST DRIFT", res.drift, "")
		if type(res.mine) == "table" then
			mine.Text = string.format("YOU  ·  top speed %d mph  ·  best drift %d  ·  longest jump %.1fs", tonumber(res.mine.speed) or 0, tonumber(res.mine.drift) or 0, tonumber(res.mine.air) or 0)
		end
	end)
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
	local refreshers: { () -> () } = {} -- (a graphics level changes what the rows below it show)
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
				b.BackgroundColor3 = if name == cur then MINT else BLUE
				b.TextColor3 = if name == cur then NAVY0 else WHITE
			end
		end
		table.insert(refreshers, refresh)
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
	-- a slider 0..1 (`say`: its value in words, `steps`: how many stops, 20 unless given)
	local function slider(r: Frame, get: () -> number, set: (number) -> (), say: ((number) -> string)?, steps: number?)
		local back = new("TextButton", { AutoButtonColor = false, Text = "", BackgroundColor3 = BLUE, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -70, 0.5, 0), Size = UDim2.new(0.5, 0, 0, 10), Parent = r }, { corner(5) })
		local fill = new("Frame", { BackgroundColor3 = MINT, Size = UDim2.fromScale(get(), 1), Parent = back }, { corner(5) })
		local knob = new("Frame", { BackgroundColor3 = WHITE, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(get(), 0.5), Size = UDim2.fromOffset(22, 22), Parent = back }, {
			new("UICorner", { CornerRadius = UDim.new(1, 0) }),
			new("UIStroke", { Color = MINT, Thickness = 3 }),
		})
		local value = text({ Text = "", FontFace = HEAVY, TextSize = 16, TextColor3 = MINT, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(52, 30), TextXAlignment = Enum.TextXAlignment.Right, Parent = r })
		local function show(v: number)
			fill.Size = UDim2.fromScale(v, 1)
			knob.Position = UDim2.fromScale(v, 0.5)
			value.Text = if say then say(v) else tostring(math.floor(v * 100 + 0.5)) .. "%"
		end
		show(get())
		table.insert(refreshers, function()
			show(get())
		end)
		local held = false
		local function at(x: number)
			local v = math.clamp((x - back.AbsolutePosition.X) / back.AbsoluteSize.X, 0, 1)
			local n = steps or 20
			v = math.floor(v * n + 0.5) / n
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

	-- (2026-11-04) reset and the camera views, first: on a phone there's no Backspace or V
	heading("YOUR CAR")
	do
		local r = row("Stuck? Back on the road")
		local b = button("RESET CAR", GOLD, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(160, 34), TextSize = 16, Parent = r })
		b.Activated:Connect(function()
			selectSound()
			if not Driving.isDriving() then
				UI.toast("Get in your car first", SUB)
				return
			end
			closeMenu()
			Driving.reset()
		end)
	end
	do
		local r = row("Camera view")
		local b = button(string.upper(Driving.cameraMode) .. "  ▶", BLUE, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(240, 34), TextSize = 16, Parent = r })
		b.Activated:Connect(function()
			selectSound()
			Driving.toggleCamera()
			b.Text = string.upper(Driving.cameraMode) .. "  ▶"
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
		return string.upper(st.Graphics or WorldFx.defaultQuality())
	end, function(v)
		local name = string.sub(v, 1, 1) .. string.lower(string.sub(v, 2))
		st.Graphics = name
		st.Look = false -- (the level's own values; the time, weather and sky stay as you set them)
		local keep = { Time = LookFx.state.Time, Weather = LookFx.state.Weather, Sky = LookFx.state.Sky }
		WorldFx.setQuality(name)
		LookFx.state.Time, LookFx.state.Weather, LookFx.state.Sky = keep.Time, keep.Weather, keep.Sky
		for _, f in refreshers do
			f()
		end
	end)
	-- (2026-11-06) one setting of the picture, kept in the save with the rest of the look
	local function look(key: string, value: any)
		LookFx.set(key, value)
		st.Look = LookFx.save()
	end
	local function onOff(label: string, key: string)
		choices(row(label), { "ON", "OFF" }, function()
			return if LookFx.state[key] then "ON" else "OFF"
		end, function(v)
			look(key, v == "ON")
		end)
	end
	local function pickOne(label: string, key: string)
		local options = {}
		for _, o in Config.Look.Choices[key] do
			table.insert(options, string.upper(o))
		end
		choices(row(label), options, function()
			return string.upper(LookFx.state[key])
		end, function(v)
			look(key, string.sub(v, 1, 1) .. string.lower(string.sub(v, 2)))
		end)
	end
	local function plusMinus(label: string, key: string)
		local range = Config.Look.Sliders[key]
		slider(row(label), function()
			return (LookFx.state[key] + range) / (2 * range)
		end, function(v)
			look(key, (v - 0.5) * 2 * range)
		end, function(v)
			local n = math.floor((v - 0.5) * 200 + 0.5)
			return (if n > 0 then "+" else "") .. tostring(n)
		end)
	end
	onOff("Shadows", "Shadows")
	pickOne("Reflections", "Reflections")
	pickOne("Ambient light", "Ambient")
	onOff("Glow", "Glow")
	onOff("Sun rays", "Rays")
	onOff("Depth of field", "Dof")
	plusMinus("Brightness", "Brightness")
	plusMinus("Contrast", "Contrast")
	plusMinus("Saturation", "Saturation")

	heading("TIME AND WEATHER")
	-- (owner, 2026-11-06: "add a feature to edit lighting time of day") yours only: the others keep
	-- the server's clock
	local HOURS = { MORNING = 8, NOON = 13, SUNSET = 17.3, NIGHT = 22 }
	choices(row("Time of day"), { "SERVER", "MORNING", "NOON", "SUNSET", "NIGHT" }, function()
		local t = LookFx.state.Time
		if t == nil then
			return "SERVER"
		end
		for name, h in HOURS do
			if h == t then
				return name
			end
		end
		return ""
	end, function(v)
		look("Time", HOURS[v])
		for _, f in refreshers do
			f()
		end
	end)
	slider(row("Set the hour"), function()
		return (LookFx.state.Time or DayCycle.hour()) / 24
	end, function(v)
		look("Time", math.min(v * 24, 23.75))
		for _, f in refreshers do
			f()
		end
	end, function(v)
		local minutes = math.floor(v * 24 * 60 + 0.5)
		return string.format("%02d:%02d", (minutes // 60) % 24, minutes % 60)
	end, 96)
	pickOne("Weather", "Weather")
	pickOne("Sky", "Sky")
	onOff("Sun and clouds", "SunClouds")
	onOff("Horizon haze", "Haze")
	pickOne("Fog layer", "Fog")

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
			local b = button(if d < 0 then "−" else "+", BLUE, { Position = UDim2.fromOffset(if k == 1 then 0 else 142, 0), Size = UDim2.fromOffset(38, 34), TextSize = 22, Parent = holder })
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
	-- (2026-11-04) not on a phone: shifting is Q / E only, so MANUAL left the car stuck in neutral
	if not UI.isTouch then
		choices(row("Gearbox"), { "AUTO", "MANUAL" }, function()
			return if st.Gearbox == "Manual" then "MANUAL" else "AUTO"
		end, function(v)
			local mode = if v == "MANUAL" then "Manual" else "Auto"
			UI.setGearboxLabel(mode)
			if UI.onGearboxChanged then
				UI.onGearboxChanged(mode)
			end
		end)
	end
	-- (owner, 2026-11-03) the HUD speedometer: an arc rev dial or a flat rev bar, both with the big
	-- digital speed
	choices(row("Speedometer"), { "ANALOGUE", "DIGITAL" }, function()
		return if st.Speedo == "Digital" then "DIGITAL" else "ANALOGUE"
	end, function(v)
		st.Speedo = if v == "DIGITAL" then "Digital" else "Analogue"
		UI.setSpeedoStyle(st.Speedo)
	end)
	-- (2026-11-03, realistic physics) how much help: a slide is caught, the phone's steering calmed at
	-- speed, drifts held; tyre smoke and tyre marks
	choices(row("Driving assists"), { "OFF", "LOW", "NORMAL" }, function()
		return if st.Assist == "Off" then "OFF" elseif st.Assist == "Low" then "LOW" else "NORMAL"
	end, function(v)
		st.Assist = if v == "OFF" then "Off" elseif v == "LOW" then "Low" else "Normal"
		Driving.assist = if v == "OFF" then 0 elseif v == "LOW" then 0.5 else 1
	end)
	choices(row("Tyre smoke"), { "OFF", "LOW", "HIGH" }, function()
		return if st.Smoke == "Off" then "OFF" elseif st.Smoke == "Low" then "LOW" else "HIGH"
	end, function(v)
		st.Smoke = if v == "OFF" then "Off" elseif v == "LOW" then "Low" else "High"
		Driving.smoke = if v == "OFF" then 0 elseif v == "LOW" then 0.5 else 1
	end)
	choices(row("Tyre marks"), { "ON", "OFF" }, function()
		return if st.Marks == false then "OFF" else "ON"
	end, function(v)
		st.Marks = v == "ON"
		Driving.marks = v == "ON"
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
		local b = button(Audio.stationName() .. "  ▶", BLUE, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(240, 34), TextSize = 16, Parent = r })
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
			-- (2026-11-04) the start screen has no car to frame yet, and closing it left nothing on screen
			if startMode then
				UI.toast("Drive your car out first", SUB)
				return
			end
			closeMenu()
			-- (2026-11-04) off now, not in a moment: photo mode saves what's on and puts it back, and it
			-- put this menu back over the game, closed, with Close doing nothing
			if gui then
				gui.Enabled = false
			end
			a.openPhoto()
		end)
	end
	do
		local r = row("Leaderboard")
		local b = button("OPEN", BLUE, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), Size = UDim2.fromOffset(120, 34), TextSize = 16, Parent = r })
		b.Activated:Connect(function()
			selectSound()
			openLeaderboard()
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
	local back = new("Frame", { BackgroundColor3 = BLUE, Position = UDim2.fromOffset(0, y + 21), Size = UDim2.new(1, 0, 0, 8), Parent = parent }, { corner(4) })
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
		-- (a pick still waiting for its model shows its stand-in: Config.Menu.StarterChoices fallback)
		local useFallback = choice.fallback ~= nil and not Cars.forSale(choice.id)
		local carId = if useFallback then choice.fallback :: string else choice.id
		local feel = if useFallback then choice.fallbackFeel or choice.feel else choice.feel
		local spec = Cars.ById[carId]
		if not spec then
			continue
		end
		local card: TextButton = new("TextButton", { AutoButtonColor = false, Text = "", BackgroundColor3 = WHITE, Position = UDim2.fromOffset((k - 1) * (cw + 16), 66), Size = UDim2.fromOffset(cw, 268), Parent = page }, {
			corner(10),
			gradient(Color3.fromRGB(38, 42, 56), PANEL, 115),
		})
		new("UIStroke", { Name = "Pick", Color = MINT, Thickness = 4, Transparency = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = card })
		local body = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 16), Size = UDim2.new(1, -40, 1, -32), Parent = card })
		UI.classBadgeFor(spec.Id, nil, { Height = 18, Position = UDim2.fromOffset(0, -1), Parent = body })
		text({ Text = string.upper(Cars.ClassLabels[spec.Class] or spec.Class), FontFace = HEAVY, TextSize = 13, TextColor3 = GOLD, Position = UDim2.fromOffset(60, 0), Size = UDim2.new(1, -60, 0, 16), Parent = body })
		text({ Text = spec.Name, FontFace = HEAVY, TextSize = 28, TextScaled = true, Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, -44, 0, 34), Parent = body })
		new("Frame", { BackgroundColor3 = spec.Color, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 20), Size = UDim2.fromOffset(30, 30), Parent = body }, {
			new("UICorner", { CornerRadius = UDim.new(1, 0) }),
			new("UIStroke", { Color = WHITE, Thickness = 2 }),
		})
		text({ Text = "“" .. feel .. "”", FontFace = BOLD, TextSize = 18, TextColor3 = MINT, Position = UDim2.fromOffset(0, 58), Size = UDim2.new(1, 0, 0, 24), Parent = body })
		carStats(body, 96, spec)
		cards[carId] = card
		focusable(card, function()
			picked = carId
			for id, c in cards do
				(c:FindFirstChild("Pick") :: UIStroke).Transparency = if id == picked then 0 else 1
			end
			confirm.Text = "CLAIM THE " .. string.upper(spec.Name)
			confirm.BackgroundColor3 = MINT
			confirm.TextColor3 = NAVY0 -- (it was pale on gold)
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
	local ach = tile(page, 0, y0, c1, hTall, { title = "Achievements", sub = "", icon = "trophy", iconSize = 150, iconPos = UDim2.new(0.5, 75, 0.5, -90), titleSize = 32 })
	local achSub = ach:FindFirstChild("Sub") :: TextLabel
	achSub.Size = UDim2.new(1, -40, 0, 70)
	-- (2026-11-04) outOfMenu, here and below: on the start screen a plain close left nothing to go
	-- back to, no HUD and no menu
	focusable(ach, function()
		outOfMenu(function()
			if api then
				api.openGoals()
			end
		end)
	end)

	-- WORLD MAP (wide, top)
	local mapTile = tile(page, x2, y0, c2 + 12 + c3, topH, { title = "World Map", titleSize = 32 })
	local mapPane = new("Frame", { Name = "MapPane", BackgroundColor3 = Color3.fromRGB(14, 34, 58), Size = UDim2.fromScale(1, 1), ZIndex = 1, Parent = mapTile })
	local shadeL = new("Frame", { BackgroundColor3 = NAVY0, BorderSizePixel = 0, Size = UDim2.new(0.55, 0, 1, 0), ZIndex = 2, Parent = mapTile }, {
		new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) }) }),
	})
	local _ = shadeL
	local chips = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 20, 1, -14), Size = UDim2.new(1, -40, 0, 32), ZIndex = 4, Parent = mapTile }, {
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Center }),
	})
	local function chip(t: string, color: Color3, order: number): TextLabel
		local c = text({ Text = t, FontFace = HEAVY, TextSize = 15, TextColor3 = color, BackgroundColor3 = NAVY0, BackgroundTransparency = 0.2, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 30), LayoutOrder = order, ZIndex = 5, Parent = chips })
		new("UIPadding", { PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), Parent = c })
		corner(8).Parent = c
		new("UIStroke", { Color = Color3.new(1, 1, 1), Transparency = 0.84, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = c })
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
	local play = tile(page, x2, lowY, c2, lowH, { title = "Play", sub = "", icon = "play", iconSize = 96, iconPos = UDim2.new(1, -28, 0.5, -48), titleSize = 50, primary = true })
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
			achSub.Text = string.format("Legends Path %d / %d\nCars %d / %d", done, total, ownedOnSale(), #Cars.List)
		else
			achSub.Text = string.format("Cars %d / %d", ownedOnSale(), #Cars.List)
		end
	end)

	-- SETTINGS
	local set = tile(page, x3, lowY, c3, lowH, { title = "Settings", sub = "Map, graphics, camera, sound", icon = "gear", iconSize = 64, titleSize = 30 })
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
		BackgroundColor3 = BLUE,
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
	local trailerSide: (spec: any) -> ()
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
		UI.classBadgeFor(spec.Id, partsOf(spec.Id), { Height = 22, Position = UDim2.fromOffset(0, 58), Parent = body })
		local info = if UI.carInfo then UI.carInfo(spec.Id) else nil
		text({ Text = (if info then "CAR LV " .. info.level .. "  ·  " .. info.cp .. " CP  ·  " else "") .. string.upper(Cars.ClassLabels[spec.Class] or spec.Class), FontFace = BOLD, TextSize = 14, TextColor3 = SUB, Position = UDim2.fromOffset(74, 58), Size = UDim2.new(1, -74, 0, 22), TextTruncate = Enum.TextTruncate.AtEnd, Parent = body })
		carStats(body, 92, spec)
		-- (2026-11-07) miles and worth, from the server's book
		local worth = text({ Text = "", FontFace = BOLD, TextSize = 13, TextColor3 = SUB, Position = UDim2.fromOffset(0, 192), Size = UDim2.new(1, 0, 0, 16), TextTruncate = Enum.TextTruncate.AtEnd, Parent = body })
		CareClient.info(spec.Id, function(st: any)
			if st and st.ok and worth.Parent then
				local alert = if st.check == 2 then "  ·  ENGINE NEEDS REPAIR" elseif st.check == 1 or st.due < 0 then "  ·  SERVICE DUE" else ""
				worth.Text = CarCare.milesText(st.miles) .. "  ·  WORTH " .. CarCare.money(st.value) .. alert
			end
		end)
		-- (2026-11-07) a car with a hitch
		local towKg = CarStats.towKg(spec.Id)
		if towKg > 0 then
			text({ Text = "TOWS " .. string.format("%d,%03d", towKg // 1000, towKg % 1000) .. " KG", FontFace = HEAVY, TextSize = 13, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -38, 0, 0), Size = UDim2.fromOffset(120, 16), Parent = body })
		end
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
		local fav = button(if favs[spec.Id] then "★ FAVOURITE" else "☆ FAVOURITE", GOLD, { Position = UDim2.fromOffset(0, by + 56), Size = UDim2.new(0.5, -4, 0, 40), TextSize = 16, Parent = body })
		-- (2026-11-03) the car's performance parts (CarUpgrades)
		local upgrade = button("UPGRADE", GOLD, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, by + 56), Size = UDim2.new(0.5, -4, 0, 40), TextSize = 16, Parent = body })
		focusable(upgrade, function()
			if UI.onUpgrade then
				UI.onUpgrade(spec.Id)
			end
		end, GOLD)
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
			outOfMenu()
		end)
		if Config.Market.Enabled then
			local market = button("SELL / MARKET", BLUE, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, by + 104), Size = half, TextSize = 16, Parent = body })
			focusable(market, function()
				outOfMenu(function()
					if api then
						api.openMarket()
					end
				end)
			end)
		end
		-- (2026-11-07) the trailer (the market's slot while the market is off; under it when it's on)
		local trailerBtn = button("TRAILER", BLUE, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, by + (if Config.Market.Enabled then 152 else 104)), Size = half, TextSize = 16, Parent = body })
		focusable(trailerBtn, function()
			trailerSide(spec)
		end)
	end

	-- what you can do with the trailer, with the car picked in the list
	trailerSide = function(spec: any)
		TrailerClient.state(function(st: any)
			if not side.Parent or selected ~= spec.Id then
				return
			end
			for _, c in side:GetChildren() do
				if not c:IsA("UICorner") then
					c:Destroy()
				end
			end
			local T = Config.Towing.Trailer
			local body = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 16), Size = UDim2.new(1, -40, 1, -32), Parent = side })
			text({ Text = "TRAILER", FontFace = HEAVY, TextSize = 13, TextColor3 = GOLD, Size = UDim2.new(1, 0, 0, 16), Parent = body })
			text({ Text = T.Name, FontFace = HEAVY, TextSize = 26, TextScaled = true, Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 34), Parent = body })
			local line = if not st.owned then "Buy one at Legends Motors: TRAILERS."
				elseif st.load then "On it: " .. (if Cars.ById[st.load] then Cars.ById[st.load].Name else st.load)
				elseif st.hitched then "Hitched to your car."
				elseif st.out then "Parked out on the road."
				else "In your garage."
			text({ Text = line, FontFace = BOLD, TextSize = 15, TextColor3 = SUB, TextWrapped = true, Position = UDim2.fromOffset(0, 58), Size = UDim2.new(1, 0, 0, 40), Parent = body })
			local y = 104
			local function row(label: string, color: Color3, fn: () -> ())
				local b = button(label, color, { Position = UDim2.fromOffset(0, y), Size = UDim2.new(1, 0, 0, 44), TextSize = 17, Parent = body })
				focusable(b, fn, color)
				y += 52
			end
			local driving = Driving.getModel()
			local inThis = driving ~= nil and driving:GetAttribute("CarId") == spec.Id
			if st.owned and not st.hitched then
				if CarStats.towKg(spec.Id) > 0 then
					row("TOW WITH THIS CAR", MINT, function()
						closeMenu()
						if inThis then
							TrailerClient.call("take")
						elseif api then
							api.drive(spec.Id)
							TrailerClient.takeWhenIn(spec.Id)
						end
					end)
				else
					text({ Text = "This car can't tow. Pick one with the TOWS tag.", FontFace = MEDIUM, TextSize = 14, TextColor3 = SUB, TextWrapped = true, Position = UDim2.fromOffset(0, y), Size = UDim2.new(1, 0, 0, 40), Parent = body })
					y += 44
				end
				if not st.out then
					row("PARK IT HERE", BLUE, function()
						outOfMenu(function()
							TrailerClient.call("park")
						end)
					end)
				end
			end
			if st.out and not st.load and not inThis then
				row("LOAD THIS CAR", GOLD, function()
					outOfMenu(function()
						TrailerClient.call("load", spec.Id)
					end)
				end)
			end
			if st.out then
				row("PUT TRAILER AWAY", BLUE, function()
					outOfMenu(function()
						TrailerClient.call("stow")
					end)
				end)
			end
			row("BACK", BLUE, fillSide)
		end)
	end

	local function card(parent: Instance, x: number, y: number, w: number, h: number, id: string)
		local spec = Cars.ById[id]
		local isSel = id == selected
		local b: TextButton = new("TextButton", { AutoButtonColor = false, Text = "", BackgroundColor3 = if isSel then Color3.fromRGB(46, 50, 68) else Color3.fromRGB(26, 29, 42), Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), Parent = parent }, { corner(8) })
		if isSel then
			new("UIStroke", { Color = MINT, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = b })
		end
		local parts = partsOf(id)
		local letter = CarStats.classOf(id, parts)
		new("Frame", { BackgroundColor3 = Config.CarClasses.Colors[letter] or MINT, BorderSizePixel = 0, Size = UDim2.new(0, 5, 1, 0), Parent = b }, { corner(3) })
		text({ Text = spec.Name, FontFace = HEAVY, TextSize = 17, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(16, 10), Size = UDim2.new(1, -60, 0, 20), Parent = b })
		local info = if UI.carInfo then UI.carInfo(id) else nil
		text({ Text = (if info then "LV " .. info.level .. "  ·  " else "") .. speedText(spec.TopSpeed) .. "  ·  " .. string.format("%.1f s", spec.ZeroToSixty), FontFace = BOLD, TextSize = 13, TextColor3 = SUB, TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(16, 34), Size = UDim2.new(1, -78, 0, 16), Parent = b })
		UI.classBadgeFor(id, parts, { Height = 18, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 33), Parent = b })
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
		count.Text = string.format("%d / %d owned", ownedOnSale(), #Cars.List)
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
			outOfMenu()
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
			b.BackgroundColor3 = if sortBy == name then MINT else BLUE
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

local STORE_ICON = { store_vip = "crown", store_cash2x = "cash", store_starter = "gift", store_bundle = "cash", store_garage = "garage" }

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
			title = item.name,
			sub = item.effect,
			icon = STORE_ICON[item.art or ""] or "tag",
			iconSize = 78,
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
				art.ImageTransparency = 0.3
				art.ImageColor3 = SUB
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
-- HOUSES (2026-11-04, owner-away run step 7.2): your house(s) in one place: the house standing in
-- this server (TELEPORT HOME), your blueprints (the catalogue), the house settings (who can come
-- in, roommates, change house, garage, remove: HousingClient's house menu) and Legends Realty (fast
-- travel there). Reads the player's "HouseLot" / "HouseDesign" / "Houses" attributes (Houses.lua).
---------------------------------------------------------------------
local TIER_WORD = { [0] = "Low", [1] = "Mid", [2] = "High" }

local function housing(): any
	local ok, mod = pcall(function()
		return require(script.Parent:WaitForChild("HousingClient", 2)) :: any
	end)
	return if ok then mod else nil
end

local function houseCall(what: string, arg: any?): any
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local call = remotes and remotes:FindFirstChild("HouseCall")
	if not (call and call:IsA("RemoteFunction")) then
		return { ok = false }
	end
	local ok, r = pcall(function()
		return (call :: RemoteFunction):InvokeServer(what, arg)
	end)
	return if ok and type(r) == "table" then r else { ok = false }
end

local function ownedHouses(): { string }
	local out = {}
	local raw = player:GetAttribute("Houses")
	if type(raw) == "string" then
		for id in raw:gmatch("[^,]+") do
			table.insert(out, id)
		end
	end
	return out
end

-- leaves the menu for another screen; on the start screen (no car, no avatar yet) your car comes
-- out first, or you'd be left looking at the backdrop
outOfMenu = function(after: (() -> ())?)
	-- (2026-11-04) a new player picks their car first
	if startMode and not claimed() then
		openClaim()
		return
	end
	local needCar = startMode or (not Driving.isDriving() and not (player.Character and player.Character.Parent))
	local id = data().Selected
	closeMenu()
	if needCar and api and id then
		api.drive(id)
		if after then
			task.delay(2.5, after)
		end
	elseif after then
		after()
	end
end

local function buildHouses(page: Frame)
	local hTall = page.Size.Y.Offset
	local c1 = 470
	local c2 = (W - c1 - 24) / 2
	local x2, x3 = c1 + 12, c1 + 12 + c2 + 12
	local rowH = (hTall - 12) / 2

	-- MY HOUSE (tall, left): the house standing in this server
	local mine = tile(page, 0, 0, c1, hTall, { title = "My House", sub = "", icon = "house", iconSize = 110, titleSize = 34 })
	local mineSub = mine:FindFirstChild("Sub") :: TextLabel
	mineSub.Size = UDim2.new(1, -40, 0, 96)
	local action = new("Frame", { BackgroundColor3 = NAVY0, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 20, 1, -122), Size = UDim2.fromOffset(230, 44), ZIndex = 4, Parent = mine }, { corner(10) })
	local actionText = text({ Text = "", FontFace = HEAVY, TextSize = 17, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), ZIndex = 5, Parent = action })
	focusable(mine, function()
		local lot = player:GetAttribute("HouseLot")
		outOfMenu(function()
			if type(lot) == "string" then
				local r = houseCall("home")
				if not r.ok then
					UI.toast(r.message or "Couldn't get you home", RED)
				end
			else
				local H = housing()
				if H then
					if #ownedHouses() > 0 then
						H.openMenu(nil)
					else
						H.openCatalog(nil)
					end
				end
			end
		end)
	end, GOLD)

	-- BLUEPRINTS (top middle): the houses you own, the catalogue
	local blue = tile(page, x2, 0, c2, rowH, { title = "Blueprints", sub = "", icon = "blueprint", iconSize = 64, titleSize = 30 })
	local blueSub = blue:FindFirstChild("Sub") :: TextLabel
	focusable(blue, function()
		outOfMenu(function()
			local H = housing()
			if H then
				H.openCatalog(nil)
			end
		end)
	end)

	-- HOUSE SETTINGS (top right)
	local set = tile(page, x3, 0, c2, rowH, { icon = "gear", iconSize = 64, title = "House Settings", sub = "Who can come in, roommates, garage", art = MenuArt.menu_settings, artSize = Vector2.new(120, 120), artPos = UDim2.new(1, 10, 0.55, 0), titleSize = 30 })
	focusable(set, function()
		local lot = player:GetAttribute("HouseLot")
		outOfMenu(function()
			local H = housing()
			if H then
				H.openMenu(if type(lot) == "string" then lot else nil)
			end
		end)
	end)

	-- LEGENDS REALTY (bottom, wide): fast travel to the agency
	local realty = tile(page, x2, rowH + 12, c2 * 2 + 12, rowH, { title = "Legends Realty", sub = "Buy a house, then claim a FOR SALE lot  ·  fast travel there", icon = "pin", iconSize = 64, titleSize = 30 })
	local realtySub = realty:FindFirstChild("Sub") :: TextLabel
	realtySub.Size = UDim2.new(0.8, 0, 0, 44)
	focusable(realty, function()
		if api then
			local r = api.travel("realty")
			if r and r.ok then
				closeMenu()
			else
				UI.toast((r and r.message) or "Can't travel right now", RED)
			end
		end
	end, MINT)

	table.insert(refreshers, function()
		if not page.Visible then
			return
		end
		local lot = player:GetAttribute("HouseLot")
		local design = player:GetAttribute("HouseDesign")
		local owned = ownedHouses()
		local d = if type(design) == "string" then (Config.Houses.ById :: any)[design] else nil
		local title = mine:FindFirstChild("Title") :: TextLabel
		if type(lot) == "string" and d then
			title.Text = d.name
			mineSub.Text = string.format("%s tier  ·  %s\nLot %s", TIER_WORD[d.tier] or "", d.style or "", tostring(lot))
			actionText.Text = "TELEPORT HOME"
		elseif #owned > 0 then
			title.Text = "My House"
			mineSub.Text = "Nothing standing in this server yet. Put your house back, or claim a FOR SALE lot of its tier."
			actionText.Text = "PLACE MY HOUSE"
		else
			title.Text = "My House"
			mineSub.Text = "You don't own a house yet. Pick one at Legends Realty, then claim a lot."
			actionText.Text = "SEE THE HOUSES"
		end
		local names = {}
		for _, id in owned do
			local dd = (Config.Houses.ById :: any)[id]
			if dd then
				table.insert(names, dd.name)
			end
		end
		blueSub.Text = if #names == 0 then "None yet  ·  open the catalogue" else #names .. " owned: " .. table.concat(names, ", ")
		blueSub.TextTruncate = Enum.TextTruncate.AtEnd
	end)
end

---------------------------------------------------------------------
-- Tabs, open, close
---------------------------------------------------------------------
local carsRefresh: (() -> ())? = nil
local playFocus: Focus? = nil
local campaignFocus: { Focus } = {}
local storeFocus: { Focus } = {}
local housesFocus: { Focus } = {}

switchTab = function(name: string)
	tabName = name
	for n, b in tabButtons do
		local on = n == name
		b.TextColor3 = if on then WHITE else SUB
		local under = b:FindFirstChild("Under")
		if under then
			(under :: any).Visible = on
		end
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
	elseif name == "HOUSES" then
		for _, f in housesFocus do
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

-- the canvas's scale for this screen (Studio: workspace attribute PreviewPhone draws it phone size)
local function fitScale(): number
	local vp = workspace.CurrentCamera.ViewportSize
	if workspace:GetAttribute("PreviewPhone") then
		vp = Vector2.new(667, 375)
	end
	return math.min((vp.X - 24) / W, (vp.Y - 16) / H)
end

local function build()
	local pg = player:WaitForChild("PlayerGui")
	gui = new("ScreenGui", { Name = "MainMenu", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 40, Enabled = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = pg })
	local root = new("Frame", { Name = "Root", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = gui })
	buildBackground(root)
	canvas = new("Frame", { Name = "Canvas", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(W, H), Parent = root })
	scaler = new("UIScale", { Parent = canvas })
	local function fit()
		scaler.Scale = fitScale()
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
	buildHouses(pages.HOUSES)
	housesFocus = table.clone(focusList)
	table.clear(focusList)

	-- keys inside the menu
	UserInputService.InputBegan:Connect(function(input, processed)
		-- (2026-11-04) not behind the parts screen: Backspace shut both at once
		if not isOpen or UserInputService:GetFocusedTextBox() or CarUpgrades.isOpen() then
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
	-- (2026-11-04) the driving keys come back a beat later: Backspace closes this, and the same press
	-- went on to put the car back on the road
	task.delay(0.1, function()
		if not isOpen then
			UI.modalOpen = false
		end
	end)
	local g = gui
	tween(scaler, 0.16, { Scale = scaler.Scale * 0.97 })
	local b = blur
	if b then
		tween(b, 0.2, { Size = 0 })
	end
	task.delay(if calm then 0 else 0.16, function()
		if not isOpen then
			g.Enabled = false
			scaler.Scale = fitScale()
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
	if start then
		DayCycle.holdMenu(true) -- (2026-11-06: the first thing a player sees is the sunset)
	end
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
	local target = fitScale()
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
	DayCycle.holdMenu(false)
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
	if what == "CAMPAIGN" or what == "CARS" or what == "HOUSES" or what == "STORE" then
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
	WorldFx.setQuality(if type(st.Graphics) == "string" then st.Graphics else WorldFx.defaultQuality())
	LookFx.load(st.Look)
	UI.setSpeedoStyle(if st.Speedo == "Digital" then "Digital" else "Analogue")
	Driving.assist = if st.Assist == "Off" then 0 elseif st.Assist == "Low" then 0.5 else 1
	Driving.smoke = if st.Smoke == "Off" then 0 elseif st.Smoke == "Low" then 0.5 else 1
	Driving.marks = st.Marks ~= false
	if type(st.Music) == "number" then
		Audio.setMusicLevel(st.Music)
	end
	if type(st.Sfx) == "number" then
		Audio.setSfxLevel(st.Sfx)
	end
end

local _ = RunService
return MainMenu
