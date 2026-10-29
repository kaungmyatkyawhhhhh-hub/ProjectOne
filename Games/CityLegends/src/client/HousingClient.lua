--[[
	HousingClient (see server/Houses.lua and server/Realty.lua)
	Housing like Driving Empire's, in City Legends' own look (owner, 2026-10-29):
	  * Legends Realty's catalogue: every house blueprint, LOW / MID / HIGH tabs, sort by price or
	    garage, a turning 3D preview (drag to spin), the house's numbers, BUY (with a confirm step)
	    and SELL (70% back)
	  * claiming a lot (E on a FOR SALE sign): your houses that fit the lot, a see-through preview
	    of the one you pick standing on the lot, then CLAIM
	  * the house menu (the mailbox, or the HOUSE button on the HUD): teleport home, who can come
	    in, roommates, change house, an extra garage space, remove
	The screens use UI.kit (the same buttons, labels and panels as the garage and dealership).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local IsleLayout = require(Shared:WaitForChild("IsleLayout"))
local HouseBuilder = require(Shared:WaitForChild("HouseBuilder"))
local UI = require(script.Parent:WaitForChild("UI"))
local Driving = require(script.Parent:WaitForChild("Driving"))

local HousingClient = {}

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local Theme = Config.Theme
local H = Config.Houses
local kit = UI.kit
local new, label, button, corner, stroke = kit.new, kit.label, kit.button, kit.corner, kit.stroke

local TIER_NAME = { [0] = "LOW", [1] = "MID", [2] = "HIGH" }
local TIER_COLOR = { [0] = Color3.fromRGB(14, 140, 134), [1] = Color3.fromRGB(31, 79, 163), [2] = Color3.fromRGB(212, 175, 55) }
local LOT_SIZE = { [0] = { 60, 60 }, [1] = { 104, 100 }, [2] = { 120, 130 } }

local call: RemoteFunction? = nil
local lotsById: { [string]: IsleLayout.Lot } = {}
local screen: Frame? = nil -- the one housing screen open at a time
local ghost: Model? = nil
local ghostCam = false

local function money(n: number): string
	return UI.formatCash(n)
end

local function short(n: number): string
	if n >= 1e6 then
		local m = n / 1e6
		return "$" .. (if m == math.floor(m) then tostring(m) else string.format("%.1f", m)) .. "M"
	end
	return "$" .. math.floor(n / 1e3) .. "K"
end

local function invoke(what: string, arg: any?): any
	if not call then
		return { ok = false }
	end
	local ok, result = pcall(function()
		return (call :: RemoteFunction):InvokeServer(what, arg)
	end)
	if not ok or type(result) ~= "table" then
		return { ok = false, message = "The server didn't answer: try again" }
	end
	return result
end

local function ownedSet(): { [string]: boolean }
	local set = {}
	local raw = player:GetAttribute("Houses")
	if type(raw) == "string" then
		for id in raw:gmatch("[^,]+") do
			set[id] = true
		end
	end
	return set
end

---------------------------------------------------------------------
-- The ghost preview on a lot
---------------------------------------------------------------------
local function clearGhost()
	if ghost then
		ghost:Destroy()
		ghost = nil
	end
	if ghostCam then
		ghostCam = false
		Driving.cameraHold = false
		if not Driving.isDriving() then
			camera.CameraType = Enum.CameraType.Custom
		end
	end
end

local function showGhost(lot: IsleLayout.Lot, id: string)
	if ghost then
		ghost:Destroy()
	end
	local d = H.ById[id]
	local model = HouseBuilder.build(d, lot.frame, lot.width, lot.depth, { ghost = true })
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.Color = p.Color:Lerp(Color3.fromRGB(120, 200, 255), 0.35)
		elseif p:IsA("Light") then
			p.Enabled = false
		end
	end
	model.Parent = workspace
	ghost = model
	-- a view of the lot from the road side, up a little
	if not ghostCam then
		ghostCam = true
		Driving.cameraHold = true
		camera.CameraType = Enum.CameraType.Scriptable
	end
	local f = lot.frame
	local back = math.max(lot.width, lot.depth) * 0.95
	camera.CFrame = CFrame.lookAt((f * CFrame.new(lot.width * 0.35, back * 0.55, -back)).Position, f.Position + Vector3.new(0, 6, 0))
	camera.Focus = f
end

---------------------------------------------------------------------
-- Screens
---------------------------------------------------------------------
local function close()
	clearGhost()
	if screen then
		screen:Destroy()
		screen = nil
	end
end

-- a centred panel (phone first: never wider than the screen, buttons 44 px or more)
local function panel(title: string, sub: string, w: number, h: number): (Frame, Frame)
	close()
	local root = UI.screen()
	local back = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 70, Parent = root })
	screen = back
	local f = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(w, h),
		BackgroundColor3 = Theme.Panel,
		BackgroundTransparency = 0.04,
		ZIndex = 71,
		Parent = back,
	}, { corner(14), stroke(Theme.Stroke, 1.5, 0.1), new("UISizeConstraint", { MaxSize = Vector2.new(w, h) }) })
	-- fits a phone: the panel shrinks to the screen with a margin
	local function fit()
		local vp = camera.ViewportSize
		local s = math.min(1, (vp.X - 24) / w, (vp.Y - 24) / h)
		local sc = f:FindFirstChildOfClass("UIScale") or new("UIScale", { Parent = f })
		sc.Scale = s
	end
	fit()
	label({ Text = title, TextSize = 26, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(20, 14), Size = UDim2.new(1, -90, 0, 30), ZIndex = 72, Parent = f })
	label({ Text = sub, TextSize = 13, TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(20, 46), Size = UDim2.new(1, -90, 0, 16), ZIndex = 72, Parent = f })
	local x = button("×", Theme.Danger, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -12, 0, 12), Size = UDim2.fromOffset(44, 44), TextSize = 20, ZIndex = 72, Parent = f })
	x.Activated:Connect(close)
	local body = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 72), Size = UDim2.new(1, -40, 1, -88), ZIndex = 72, Parent = f })
	return f, body
end

local function chip(parent: Instance, tier: number, x: number, y: number): TextLabel
	local c = label({
		Text = TIER_NAME[tier],
		TextSize = 11,
		Font = Enum.Font.GothamBlack,
		TextColor3 = if tier == 2 then Color3.fromRGB(17, 17, 17) else Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0,
		BackgroundColor3 = TIER_COLOR[tier],
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(42, 18),
		ZIndex = 74,
		Parent = parent,
	})
	corner(4).Parent = c
	return c
end

---------------------------------------------------------------------
-- Legends Realty: the catalogue
---------------------------------------------------------------------
local previewConn: RBXScriptConnection? = nil

function HousingClient.openCatalog(focus: string?)
	close()
	local data = invoke("catalog")
	if not data.ok then
		UI.toast(data.message or "Legends Realty is closed: try again", Theme.Danger)
		return
	end
	local owned: { [string]: boolean } = {}
	for _, id in data.owned do
		owned[id] = true
	end
	local cash, level = data.cash, data.level or 1
	local root = UI.screen()
	local f = new("Frame", { BackgroundColor3 = Theme.Background, BackgroundTransparency = 0.06, Size = UDim2.fromScale(1, 1), ZIndex = 70, Parent = root })
	screen = f
	local compact = camera.ViewportSize.X < 900
	local pad = if compact then 14 else 40
	label({ Text = "LEGENDS REALTY", TextSize = if compact then 26 else 38, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(pad, if compact then 10 else 34), Size = UDim2.new(0.6, 0, 0, 40), ZIndex = 71, Parent = f })
	label({ Text = "BUY A HOUSE, THEN CLAIM A FOR SALE LOT OF ITS TIER ON LEGENDS ISLE", TextSize = 12, TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(pad, if compact then 44 else 76), Size = UDim2.new(0.7, 0, 0, 14), ZIndex = 71, Parent = f })
	local cashText = label({ Text = money(cash), TextColor3 = Theme.Money, TextSize = 24, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -(pad + 56), 0, if compact then 10 else 36), Size = UDim2.new(0.3, 0, 0, 36), ZIndex = 71, Parent = f })
	local x = button("×", Theme.Danger, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -pad, 0, if compact then 8 else 34), Size = UDim2.fromOffset(44, 44), TextSize = 20, ZIndex = 71, Parent = f })
	x.Activated:Connect(close)

	local top = if compact then 66 else 104
	-- tabs and sort
	local tabs = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(pad, top), Size = UDim2.new(if compact then 0.5 else 0.38, 0, 0, 44), ZIndex = 71, Parent = f }, {
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }),
	})
	local listW = if compact then 0.5 else 0.38
	local list = new("ScrollingFrame", {
		Position = UDim2.fromOffset(pad, top + 52),
		Size = UDim2.new(listW, -pad, 1, -(top + 52 + pad)),
		BackgroundColor3 = Theme.Panel,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Theme.Accent,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ZIndex = 71,
		Parent = f,
	}, {
		corner(10),
		stroke(Theme.Stroke, 1, 0.2),
		new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
		new("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 12) }),
	})
	local detail = new("Frame", { Position = UDim2.new(listW, pad / 2 + 10, 0, top), Size = UDim2.new(1 - listW, -(pad * 1.5 + 10), 1, -(top + pad)), BackgroundColor3 = Theme.Panel, BackgroundTransparency = 0.1, ZIndex = 71, Parent = f }, { corner(12), stroke(Theme.Stroke, 1, 0.2) })
	local viewport = new("ViewportFrame", {
		Position = UDim2.fromOffset(12, 12),
		Size = UDim2.new(1, -24, 0.5, 0),
		BackgroundColor3 = Color3.fromRGB(170, 196, 220),
		Ambient = Color3.fromRGB(170, 172, 182),
		LightColor = Color3.fromRGB(255, 250, 240),
		LightDirection = Vector3.new(-0.5, -1, -0.4),
		ZIndex = 72,
		Parent = detail,
	}, { corner(10) })
	new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(205, 214, 226)), Rotation = 90, Parent = viewport })
	local vpCam = new("Camera", { FieldOfView = 38, Parent = viewport })
	viewport.CurrentCamera = vpCam
	label({ Text = "DRAG TO TURN", TextSize = 10, TextColor3 = Color3.fromRGB(70, 80, 96), AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -10, 1, -8), Size = UDim2.fromOffset(120, 12), TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 73, Parent = viewport })

	local nameText = label({ Text = "", TextSize = if compact then 22 else 30, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0, 20, 0.5, 20), Size = UDim2.new(0.62, 0, 0, 34), ZIndex = 72, Parent = detail })
	local tierChip = chip(detail, 0, 20, 0)
	tierChip.Position = UDim2.new(0, 20, 0.5, 58)
	local styleText = label({ Text = "", TextSize = 13, TextColor3 = Theme.Accent, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.new(0, 70, 0.5, 58), Size = UDim2.new(0.6, 0, 0, 18), ZIndex = 72, Parent = detail })
	local descText = label({ Text = "", TextSize = 13, TextColor3 = Theme.SubText, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Font = Enum.Font.GothamMedium, Position = UDim2.new(0, 20, 0.5, 82), Size = UDim2.new(0.58, 0, 0, 34), ZIndex = 72, Parent = detail })
	local facts = label({ Text = "", TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Font = Enum.Font.GothamBold, RichText = true, Position = UDim2.new(0, 20, 0.5, 122), Size = UDim2.new(0.58, 0, 0, 60), ZIndex = 72, Parent = detail })
	local priceText = label({ Text = "", TextSize = if compact then 22 else 30, Font = Enum.Font.GothamBlack, TextColor3 = Theme.Money, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0.5, 20), Size = UDim2.new(0.36, 0, 0, 34), ZIndex = 72, Parent = detail })
	local msgText = label({ Text = "", TextSize = 13, TextColor3 = Theme.SubText, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -20, 0.5, 58), Size = UDim2.new(0.36, 0, 0, 34), ZIndex = 72, Parent = detail })
	local buyBtn = button("BUY", Theme.Accent, { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -20, 1, -20), Size = UDim2.fromOffset(if compact then 150 else 220, if compact then 46 else 56), TextSize = if compact then 18 else 22, ZIndex = 72, Parent = detail })
	local sellBtn = button("SELL", Theme.Danger, { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -(if compact then 180 else 256), 1, -20), Size = UDim2.fromOffset(if compact then 100 else 130, if compact then 46 else 56), TextSize = 16, ZIndex = 72, Parent = detail })

	-- the 3D preview: the camera circles the house; drag to turn it yourself
	local previewModel: Model? = nil
	local radius = 80
	local spin, dragging, lastX = 0.6, false, 0
	local function setPreview(d: any)
		if previewModel then
			previewModel:Destroy()
		end
		local size = LOT_SIZE[d.tier]
		local m = HouseBuilder.build(d, CFrame.new(0, 0, 0), size[1], size[2], {})
		m.Parent = viewport
		previewModel = m
		radius = math.max(size[1], size[2]) * 0.95
	end
	if previewConn then
		previewConn:Disconnect()
	end
	previewConn = RunService.RenderStepped:Connect(function(dt)
		if not viewport.Parent then
			if previewConn then
				previewConn:Disconnect()
				previewConn = nil
			end
			return
		end
		if not dragging then
			spin += dt * 0.25
		end
		vpCam.CFrame = CFrame.lookAt(Vector3.new(math.cos(spin) * radius, radius * 0.5, math.sin(spin) * radius), Vector3.new(0, 8, 0))
	end)
	viewport.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			lastX = input.Position.X
		end
	end)
	viewport.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	viewport.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			spin += (input.Position.X - lastX) * 0.012
			lastX = input.Position.X
		end
	end)

	local tierFilter: number? = nil
	local sortBy = "price"
	local selected = focus or H.Designs[1].id
	local confirming = false
	local rows: { [string]: TextButton } = {}
	local refresh: () -> ()

	local function show(id: string)
		selected = id
		confirming = false
		local d = H.ById[id]
		setPreview(d)
		nameText.Text = string.upper(d.name)
		tierChip.Text = TIER_NAME[d.tier]
		tierChip.BackgroundColor3 = TIER_COLOR[d.tier]
		tierChip.TextColor3 = if d.tier == 2 then Color3.fromRGB(17, 17, 17) else Color3.fromRGB(255, 255, 255)
		styleText.Text = d.style
		descText.Text = d.desc
		local garage = if d.maxBays > d.bays then string.format("%d (up to %d)", d.bays, d.maxBays) else tostring(d.bays)
		facts.Text = string.format("%d %s  ·  %d bed  ·  %d bath  ·  %s sq ft<br/><font color=\"#96a0b4\">GARAGE</font> %s  ·  <font color=\"#96a0b4\">DRIVEWAY</font> %d  ·  <font color=\"#96a0b4\">LOT</font> %s",
			d.floors, if d.floors == 1 then "floor" else "floors", d.beds, d.baths, string.format("%d,%03d", d.sqft // 1000, d.sqft % 1000), garage, d.drive, TIER_NAME[d.tier])
		sellBtn.Visible = owned[id] == true
		if owned[id] then
			priceText.Text = "OWNED"
			priceText.TextColor3 = Theme.Accent
			buyBtn.Text = "CLAIM A LOT"
			msgText.Text = "Walk up to any FOR SALE sign with a " .. TIER_NAME[d.tier] .. " band on Legends Isle"
		elseif level < d.level then
			priceText.Text = money(d.price)
			priceText.TextColor3 = Theme.SubText
			buyBtn.Text = "LEVEL " .. d.level
			msgText.Text = "Unlocks at level " .. d.level .. " (you're level " .. level .. ")"
		else
			priceText.Text = money(d.price)
			priceText.TextColor3 = if cash >= d.price then Theme.Money else Theme.Danger
			buyBtn.Text = "BUY"
			msgText.Text = if cash >= d.price then "" else "You need " .. money(d.price - cash) .. " more"
		end
		for rid, row in rows do
			local st = row:FindFirstChildOfClass("UIStroke")
			if st then
				st.Color = if rid == id then Theme.Accent else Theme.Stroke
			end
		end
	end

	refresh = function()
		for _, r in rows do
			r:Destroy()
		end
		rows = {}
		local items = {}
		for _, d in H.Designs do
			if tierFilter == nil or d.tier == tierFilter then
				table.insert(items, d)
			end
		end
		table.sort(items, function(a, b)
			if sortBy == "garage" and a.maxBays ~= b.maxBays then
				return a.maxBays > b.maxBays
			end
			return a.price < b.price
		end)
		for i, d in items do
			local row: TextButton = new("TextButton", { AutoButtonColor = false, Text = "", LayoutOrder = i, Size = UDim2.new(1, 0, 0, 62), BackgroundColor3 = Theme.PanelLight, ZIndex = 72, Parent = list }, { corner(8), stroke(Theme.Stroke, 1, 0.2) })
			new("Frame", { BackgroundColor3 = TIER_COLOR[d.tier], BorderSizePixel = 0, Position = UDim2.fromOffset(8, 10), Size = UDim2.new(0, 4, 1, -20), ZIndex = 73, Parent = row }, { corner(2) })
			label({ Text = d.name, TextSize = 15, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(22, 8), Size = UDim2.new(0.62, -22, 0, 20), TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 73, Parent = row })
			chip(row, d.tier, 22, 34)
			label({ Text = string.format("%d fl · %d bed · %d car", d.floors, d.beds, d.bays), TextSize = 11, TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(70, 34), Size = UDim2.new(0.6, -70, 0, 18), ZIndex = 73, Parent = row })
			local right = if owned[d.id] then "OWNED" elseif level < d.level then "LVL " .. d.level else short(d.price)
			label({ Text = right, TextSize = 15, Font = Enum.Font.GothamBlack, TextColor3 = if owned[d.id] then Theme.Accent elseif level < d.level then Theme.SubText else Theme.Money, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.new(0.36, 0, 0, 20), ZIndex = 73, Parent = row })
			row.Activated:Connect(function()
				show(d.id)
			end)
			rows[d.id] = row
		end
		show(if H.ById[selected] and (tierFilter == nil or H.ById[selected].tier == tierFilter) then selected else items[1].id)
	end

	local tabButtons: { [string]: TextButton } = {}
	local function tab(text: string, tier: number?)
		local b = button(text, Theme.Accent, { Size = UDim2.fromOffset(if compact then 52 else 64, 44), TextSize = 13, ZIndex = 72, Parent = tabs })
		tabButtons[text] = b
		b.Activated:Connect(function()
			tierFilter = tier
			for t, tb in tabButtons do
				tb.TextColor3 = if t == text then Theme.Accent else Theme.Text
			end
			refresh()
		end)
	end
	tab("ALL", nil)
	tab("LOW", 0)
	tab("MID", 1)
	tab("HIGH", 2)
	tabButtons.ALL.TextColor3 = Theme.Accent
	local sortBtn = button("SORT: PRICE", Theme.Accent2, { Size = UDim2.fromOffset(if compact then 96 else 130, 44), TextSize = 12, ZIndex = 72, Parent = tabs })
	sortBtn.Activated:Connect(function()
		sortBy = if sortBy == "price" then "garage" else "price"
		sortBtn.Text = if sortBy == "price" then "SORT: PRICE" else "SORT: GARAGE"
		refresh()
	end)

	buyBtn.Activated:Connect(function()
		local d = H.ById[selected]
		if owned[d.id] then
			close()
			UI.toast("Drive to Legends Isle and walk up to a " .. TIER_NAME[d.tier] .. " FOR SALE sign", Theme.Accent)
			return
		end
		if level < d.level or cash < d.price then
			return
		end
		if not confirming then
			confirming = true
			buyBtn.Text = "CONFIRM " .. short(d.price)
			msgText.Text = "Tap again to buy the " .. d.name
			return
		end
		confirming = false
		local r = invoke("buy", d.id)
		if r.ok then
			owned[d.id] = true
			cash = r.cash or cash
			cashText.Text = money(cash)
			UI.toast("You bought the " .. d.name .. ": now claim a " .. TIER_NAME[d.tier] .. " lot", Theme.Money)
			refresh()
		else
			msgText.Text = r.message or "Couldn't buy it"
			msgText.TextColor3 = Theme.Danger
		end
	end)
	local sellConfirm = false
	sellBtn.Activated:Connect(function()
		local d = H.ById[selected]
		if not owned[d.id] then
			return
		end
		if not sellConfirm then
			sellConfirm = true
			sellBtn.Text = short(math.floor(d.price * H.SellBack)) .. "?"
			task.delay(4, function()
				sellConfirm = false
				if sellBtn.Parent then
					sellBtn.Text = "SELL"
				end
			end)
			return
		end
		sellConfirm = false
		local r = invoke("sell", d.id)
		if r.ok then
			owned[d.id] = nil
			cash = r.cash or cash
			cashText.Text = money(cash)
			UI.toast("Sold the " .. d.name .. " for " .. money(r.refund or 0), Theme.Money)
			refresh()
		end
	end)
	refresh()
end

---------------------------------------------------------------------
-- Claiming a lot (E on a FOR SALE sign)
---------------------------------------------------------------------
function HousingClient.openClaim(lotId: string, options: { string }, last: string?)
	local lot = lotsById[lotId]
	if not lot then
		return
	end
	local tier = lot.tier
	if #options == 0 then
		local f, body = panel("LOT " .. lot.number .. " · " .. TIER_NAME[tier] .. " TIER", "FOR SALE · LEGENDS PROPERTIES", 440, 230)
		label({ Text = "You don't own a " .. TIER_NAME[tier] .. " house yet. Buy one at Legends Realty, then come back and claim this lot.", TextWrapped = true, TextSize = 15, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 60), ZIndex = 73, Parent = body })
		local open = button("SEE THE HOUSES", Theme.Accent, { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 50), TextSize = 18, ZIndex = 73, Parent = body })
		open.Activated:Connect(function()
			HousingClient.openCatalog(nil)
		end)
		local _ = f
		return
	end
	-- your houses that fit this lot: pick one, see it standing there, then claim
	table.sort(options, function(a, b)
		if a == last or b == last then
			return a == last and b ~= last
		end
		return H.ById[a].price > H.ById[b].price
	end)
	local f, body = panel("CLAIM LOT " .. lot.number, TIER_NAME[tier] .. " TIER · PICK A HOUSE TO PUT HERE", 420, 420)
	f.AnchorPoint = Vector2.new(0, 0.5)
	f.Position = UDim2.new(0, 20, 0.5, 0)
	local list = new("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, -62), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 4, ZIndex = 73, Parent = body }, {
		new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local pick = options[1]
	local rows: { [string]: TextButton } = {}
	local claimBtn = button("CLAIM THIS LOT", Theme.Money, { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 52), TextSize = 18, ZIndex = 73, Parent = body })
	local function choose(id: string)
		pick = id
		for rid, r in rows do
			local st = r:FindFirstChildOfClass("UIStroke")
			if st then
				st.Color = if rid == id then Theme.Money else Theme.Stroke
			end
		end
		showGhost(lot, id)
	end
	for i, id in options do
		local d = H.ById[id]
		local row: TextButton = new("TextButton", { AutoButtonColor = false, Text = "", LayoutOrder = i, Size = UDim2.new(1, 0, 0, 56), BackgroundColor3 = Theme.PanelLight, ZIndex = 74, Parent = list }, { corner(8), stroke(Theme.Stroke, 1.5, 0.1) })
		label({ Text = (if id == last then "★ " else "") .. d.name, TextSize = 15, Font = Enum.Font.GothamBlack, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -28, 0, 20), ZIndex = 75, Parent = row })
		label({ Text = string.format("%d floors · %d bed · garage %d · %s", d.floors, d.beds, d.bays, short(d.price)), TextSize = 12, TextColor3 = Theme.SubText, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(14, 30), Size = UDim2.new(1, -28, 0, 16), ZIndex = 75, Parent = row })
		row.Activated:Connect(function()
			choose(id)
		end)
		rows[id] = row
	end
	claimBtn.Activated:Connect(function()
		claimBtn.Text = "BUILDING..."
		local r = invoke("place", { lot = lotId, design = pick })
		if r.ok then
			close()
		else
			claimBtn.Text = "CLAIM THIS LOT"
			UI.toast(r.message or "Couldn't claim this lot", Theme.Danger)
		end
	end)
	choose(pick)
end

---------------------------------------------------------------------
-- The house menu (mailbox, or the HOUSE button)
---------------------------------------------------------------------
function HousingClient.openMenu(lotId: string?)
	local here = lotId or player:GetAttribute("HouseLot")
	if type(here) ~= "string" then
		-- no house standing
		local f, body = panel("YOUR HOUSE", "NOTHING STANDING IN THIS SERVER YET", 440, 290)
		local owned = ownedSet()
		local n = 0
		for _ in owned do
			n += 1
		end
		label({ Text = if n == 0 then "Buy a house at Legends Realty (Downtown, by the causeway), then claim a FOR SALE lot on Legends Isle." else "Put your last house back on its lot, or walk up to any FOR SALE sign of its tier to claim a new lot.", TextWrapped = true, TextSize = 15, Font = Enum.Font.GothamMedium, TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 64), ZIndex = 73, Parent = body })
		local place = button("PLACE MY LAST HOUSE", Theme.Money, { Position = UDim2.fromOffset(0, 80), Size = UDim2.new(1, 0, 0, 50), TextSize = 16, ZIndex = 73, Parent = body })
		place.Visible = n > 0
		place.Activated:Connect(function()
			local r = invoke("home")
			if r.ok then
				close()
			else
				UI.toast(r.message or "Couldn't place it", Theme.Warning)
			end
		end)
		local shop = button("SEE THE HOUSES", Theme.Accent, { Position = UDim2.fromOffset(0, if n > 0 then 140 else 80), Size = UDim2.new(1, 0, 0, 50), TextSize = 16, ZIndex = 73, Parent = body })
		shop.Activated:Connect(function()
			HousingClient.openCatalog(nil)
		end)
		local _ = f
		return
	end
	local data = invoke("menu", here)
	if not data.ok then
		UI.toast("You can't use this house", Theme.Warning)
		return
	end
	local d = H.ById[data.design]
	local f, body = panel(string.upper(d.name), "LOT " .. data.lot .. " · " .. TIER_NAME[d.tier] .. " TIER" .. (if data.owner then "" else " · ROOMMATE"), 460, if data.owner then 470 else 200)
	local y = 0
	local function row(text: string, color: Color3): TextButton
		local b = button(text, color, { Position = UDim2.fromOffset(0, y), Size = UDim2.new(1, 0, 0, 48), TextSize = 15, ZIndex = 73, Parent = body })
		y += 56
		return b
	end
	row("TELEPORT HOME", Theme.Accent).Activated:Connect(function()
		local r = invoke("home")
		close()
		if not r.ok then
			UI.toast(r.message or "Couldn't get you home", Theme.Warning)
		end
	end)
	if not data.owner then
		return
	end
	local ACCESS = { nobody = "NOBODY", friends = "FRIENDS", everyone = "EVERYONE" }
	local NEXT = { nobody = "friends", friends = "everyone", everyone = "nobody" }
	local access = data.access
	local accessBtn = row("WHO CAN COME IN: " .. ACCESS[access], Theme.Accent2)
	accessBtn.Activated:Connect(function()
		local r = invoke("access", NEXT[access])
		if r.ok then
			access = r.access
			accessBtn.Text = "WHO CAN COME IN: " .. ACCESS[access]
		end
	end)
	row("ROOMMATES (" .. #data.roommates .. ")", Theme.Accent2).Activated:Connect(function()
		HousingClient.openRoommates(here, data.roommates)
	end)
	if #data.fits > 1 then
		row("CHANGE HOUSE", Theme.Accent).Activated:Connect(function()
			HousingClient.openClaim(here, data.fits, data.design)
		end)
	end
	if data.bayPrice then
		local gb = row(string.format("GARAGE %d → %d  ·  %s", data.garage, data.garage + 1, short(data.bayPrice)), Theme.Money)
		gb.Activated:Connect(function()
			local r = invoke("buyBay")
			if r.ok then
				UI.toast("Your garage has one more space", Theme.Money)
				close()
			else
				UI.toast(r.message or "Couldn't add a space", Theme.Warning)
			end
		end)
	end
	local sure = false
	local rm = row("REMOVE HOUSE", Theme.Danger)
	rm.Activated:Connect(function()
		if not sure then
			sure = true
			rm.Text = "SURE? IT GOES BACK TO FOR SALE"
			return
		end
		invoke("remove")
		close()
		UI.toast("Your house is packed away: claim any FOR SALE lot to put it up again", Theme.Accent)
	end)
	local _ = f
end

function HousingClient.openRoommates(lotId: string, current: { { id: number, name: string } })
	local f, body = panel("ROOMMATES", "THEY CAN USE YOUR HOUSE AND OPEN ITS GATES", 440, 420)
	local list = new("ScrollingFrame", { BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, -58), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 4, ZIndex = 73, Parent = body }, {
		new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local mates: { [number]: boolean } = {}
	for _, m in current do
		mates[m.id] = true
	end
	for i, p in Players:GetPlayers() do
		if p ~= player then
			local r: Frame = new("Frame", { LayoutOrder = i, Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = Theme.PanelLight, ZIndex = 74, Parent = list }, { corner(8) })
			label({ Text = p.DisplayName, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(14, 0), Size = UDim2.new(0.6, 0, 1, 0), ZIndex = 75, Parent = r })
			local b = button(if mates[p.UserId] then "REMOVE" else "ADD", if mates[p.UserId] then Theme.Danger else Theme.Money, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -6, 0.5, 0), Size = UDim2.fromOffset(110, 44), TextSize = 14, ZIndex = 75, Parent = r })
			b.Activated:Connect(function()
				local add = not mates[p.UserId]
				local res = invoke("roommate", { id = p.UserId, add = add })
				if res.ok then
					mates[p.UserId] = add or nil
					b.Text = if add then "REMOVE" else "ADD"
				end
			end)
		end
	end
	local back = button("BACK", Theme.Accent, { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 0, 1, 0), Size = UDim2.new(1, 0, 0, 48), TextSize = 16, ZIndex = 73, Parent = body })
	back.Activated:Connect(function()
		HousingClient.openMenu(lotId)
	end)
	local _ = f
end

---------------------------------------------------------------------
-- The FOR SALE signs' prompts, worded for this player
---------------------------------------------------------------------
local function word(p: Instance)
	if not p:IsA("ProximityPrompt") then
		return
	end
	local tier = p:GetAttribute("Tier")
	local has = false
	for id in ownedSet() do
		local d = H.ById[id]
		if d and d.tier == tier then
			has = true
		end
	end
	p.ActionText = if has then "Claim this lot" else "See " .. TIER_NAME[tier :: number] .. " houses"
end

function HousingClient.init()
	for _, lot in IsleLayout.lots() do
		lotsById[lot.id] = lot
	end
	call = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("HouseCall", 60) :: RemoteFunction?
	local fx = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("HouseFx", 60) :: RemoteEvent?
	if fx then
		fx.OnClientEvent:Connect(function(info: any)
			if type(info) ~= "table" then
				return
			end
			if info.kind == "claim" and type(info.lot) == "string" and type(info.options) == "table" then
				HousingClient.openClaim(info.lot, info.options, info.last)
			elseif info.kind == "menu" and type(info.lot) == "string" then
				HousingClient.openMenu(info.lot)
			elseif info.kind == "realty" then
				HousingClient.openCatalog(info.focus)
			elseif info.kind == "placed" then
				UI.toast(tostring(info.text or "Welcome home"), Theme.Money)
			end
		end)
	end
	UI.onHouseButton = function()
		if screen then
			close()
		else
			HousingClient.openMenu(nil)
		end
	end
	for _, p in CollectionService:GetTagged("HouseClaim") do
		word(p)
	end
	CollectionService:GetInstanceAddedSignal("HouseClaim"):Connect(word)
	player:GetAttributeChangedSignal("Houses"):Connect(function()
		for _, p in CollectionService:GetTagged("HouseClaim") do
			word(p)
		end
	end)
	-- Esc closes a housing screen
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.Escape and screen then
			close()
		end
	end)
end

return HousingClient
