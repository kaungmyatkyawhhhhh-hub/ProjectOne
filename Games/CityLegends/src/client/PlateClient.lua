--[[
	PlateClient (19 Nov 2026): the NUMBER PLATES screen (server: PlateShop, shared: Plates).
	Opens from the phone car menu (PLATES), Legends Customs (NUMBER PLATES button) and the Plate
	Office counter (PlateOpen). Built like the Customs panel (Theme colours, 14 px panel corners,
	8 px buttons, Gotham weights that UIStyle turns into Builder Sans); phone first: on touch the
	panel takes half the screen width, full height.
	  * THIS CAR: its plate drawn big, < > to pick another of your cars, ROLL NEW PLATE
	  * PLATE OFFICE: type a number or tap an idea -> price + why -> CLAIM (only at the office;
	    elsewhere a waypoint button)
	  * MY PLATES: every plate you own: PUT ON this car, SELL for half of what you paid
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Plates = require(Shared:WaitForChild("Plates"))
local S = require(Shared:WaitForChild("Strings"))
local UI = require(script.Parent:WaitForChild("UI"))

local PlateClient = {}

local Theme = Config.Theme
local player = Players.LocalPlayer
local gui: ScreenGui? = nil
local busy = false

local function new(className: string, props: { [string]: any }, parent: Instance?): any
	local o = Instance.new(className)
	for k, v in props do
		(o :: any)[k] = v
	end
	o.Parent = parent
	return o
end

local function corner(parent: Instance, r: number)
	new("UICorner", { CornerRadius = UDim.new(0, r) }, parent)
end

local function money(n: number): string
	return UI.formatCash(n)
end

local function remote(): RemoteFunction?
	local f = ReplicatedStorage:FindFirstChild("Remotes")
	return f and f:FindFirstChild("PlateCall") :: RemoteFunction?
end

local function ask(...): any
	local call = remote()
	if not call then
		return nil
	end
	local ok, r = pcall(call.InvokeServer, call, ...)
	return if ok and type(r) == "table" then r else nil
end

function PlateClient.close()
	if gui then
		gui:Destroy()
		gui = nil
	end
end

function PlateClient.open()
	if gui or busy then
		return
	end
	busy = true
	local state = ask("state")
	busy = false
	if not (state and state.ok) or gui then
		UI.toast(S.get("common.noServerShort"), Theme.Warning)
		return
	end
	local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	local screen = new("ScreenGui", { Name = "NumberPlates", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 45 }, player:WaitForChild("PlayerGui"))
	gui = screen
	local panel = new("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -16, 0.5, 0),
		Size = UDim2.new(if touch then 0.5 else 0, if touch then 0 else 380, 1, -40),
		BackgroundColor3 = Theme.Panel,
		BackgroundTransparency = 0.06,
		Active = true,
	}, screen)
	corner(panel, 14)
	new("UIStroke", { Color = Theme.Stroke, Thickness = 1.5 }, panel)
	new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(18, 10),
		Size = UDim2.new(1, -36, 0, 26),
		Font = Enum.Font.GothamBlack,
		Text = S.get("plates.title"),
		TextSize = 22,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.Text,
	}, panel)
	local sub = new("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(18, 36),
		Size = UDim2.new(1, -36, 0, 16),
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextColor3 = Theme.SubText,
	}, panel)
	local list = new("ScrollingFrame", {
		Position = UDim2.fromOffset(12, 58),
		Size = UDim2.new(1, -24, 1, -112),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
	}, panel)
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, list)
	local closeBtn = new("TextButton", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -10),
		Size = UDim2.new(1, -28, 0, 40),
		BackgroundColor3 = Theme.PanelLight,
		Font = Enum.Font.GothamBlack,
		Text = S.get("common.close"),
		TextSize = 15,
		TextColor3 = Theme.Text,
		AutoButtonColor = true,
	}, panel)
	corner(closeBtn, 8)
	closeBtn.Activated:Connect(PlateClient.close)

	local pick = 1 -- index into state.cars
	for i, c in state.cars do
		if c.id == state.current then
			pick = i
		end
	end
	local order = 0
	local function nextOrder(): number
		order += 1
		return order
	end
	local function heading(t: string)
		new("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -6, 0, 18),
			Font = Enum.Font.GothamBlack,
			Text = t,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = Theme.SubText,
			LayoutOrder = nextOrder(),
		}, list)
	end
	local function line(t: string, color: Color3?, size: number?): TextLabel
		return new("TextLabel", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -6, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Font = Enum.Font.GothamMedium,
			Text = t,
			TextSize = size or 13,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = color or Theme.Text,
			LayoutOrder = nextOrder(),
		}, list)
	end
	local function button(t: string, color: Color3, textColor: Color3, parent: Instance?, size: UDim2?): TextButton
		local b = new("TextButton", {
			Size = size or UDim2.new(1, -6, 0, 40),
			BackgroundColor3 = color,
			Font = Enum.Font.GothamBlack,
			Text = t,
			TextSize = 14,
			TextColor3 = textColor,
			AutoButtonColor = true,
			LayoutOrder = nextOrder(),
		}, parent or list)
		corner(b, 8)
		return b
	end
	-- a drawn plate in a box of width w (real 2.2 : 1)
	local function plateBox(parent: Instance, text: string, w: number, lo: number?): Frame
		local f = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(w, math.floor(w / 2.2)), LayoutOrder = lo or nextOrder() }, parent)
		Plates.draw(f, text, "private")
		return f
	end

	local rebuild: () -> ()
	local function apply(r: any, okText: string?)
		if r and r.ok then
			if r.state then
				state = r.state
			end
			if okText then
				UI.toast(okText, Theme.Money)
			end
			if r.state and type(r.state.cash) == "number" then
				UI.setCash(r.state.cash)
			end
			rebuild()
		else
			UI.toast(if r and r.message then r.message else S.get("common.cantNow"), Theme.Warning)
		end
	end

	rebuild = function()
		for _, c in list:GetChildren() do
			if not c:IsA("UIListLayout") then
				c:Destroy()
			end
		end
		order = 0
		sub.Text = if state.office then S.get("plates.atOffice") else S.get("common.youHave", money(state.cash or 0))
		local car = state.cars[pick]
		-- THIS CAR
		heading(S.get("plates.thisCar"))
		if car then
			local row = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -6, 0, 32), LayoutOrder = nextOrder() }, list)
			local prev = button("‹", Theme.PanelLight, Theme.Text, row, UDim2.fromOffset(36, 32))
			local nxt = button("›", Theme.PanelLight, Theme.Text, row, UDim2.fromOffset(36, 32))
			nxt.AnchorPoint = Vector2.new(1, 0)
			nxt.Position = UDim2.fromScale(1, 0)
			new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.fromOffset(42, 0), Size = UDim2.new(1, -84, 1, 0), Font = Enum.Font.GothamBold, Text = car.name, TextSize = 14, TextTruncate = Enum.TextTruncate.AtEnd, TextColor3 = Theme.Text }, row)
			prev.Activated:Connect(function()
				pick = (pick - 2) % #state.cars + 1
				rebuild()
			end)
			nxt.Activated:Connect(function()
				pick = pick % #state.cars + 1
				rebuild()
			end)
			local holder = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -6, 0, 100), LayoutOrder = nextOrder() }, list)
			local big = plateBox(holder, car.plate or "- - -", 220) -- (no plate yet: it gets one on its first drive)
			big.AnchorPoint = Vector2.new(0.5, 0)
			big.Position = UDim2.fromScale(0.5, 0)
			if car.plate then
				local value, why = Plates.price(car.plate)
				if value and value > Plates.BASE then
					line(S.get("plates.worth", money(value), table.concat(why, ", ")), Theme.Accent2)
				end
			end
			button(S.get("plates.roll", money(Plates.ROLL_COST)), Theme.Money, Theme.Background).Activated:Connect(function()
				local r = ask("roll", car.id)
				apply(r, r and r.ok and (if r.lucky then S.get("plates.lucky", r.plate, r.lucky) else S.get("plates.rolled", r.plate)) or nil)
			end)
		end

		-- PLATE OFFICE
		heading(S.get("plates.office"))
		if not state.office then
			line(S.get("plates.officeOnly"), Theme.SubText)
			button(S.get("plates.waypoint"), Theme.PanelLight, Theme.Accent2).Activated:Connect(function()
				local Minimap = require(script.Parent:WaitForChild("Minimap")) :: any
				if typeof(state.officeAt) == "Vector3" then
					Minimap.setWaypoint(state.officeAt)
					UI.toast(S.get("common.waypointSet", S.get("plates.officeName")), Theme.Accent)
				end
			end)
		else
			local box = new("TextBox", {
				Size = UDim2.new(1, -6, 0, 40),
				BackgroundColor3 = Color3.fromRGB(16, 16, 18),
				Font = Enum.Font.GothamBlack,
				PlaceholderText = "9E-9999",
				PlaceholderColor3 = Color3.fromRGB(110, 110, 116),
				Text = "",
				TextSize = 22,
				TextColor3 = Color3.fromRGB(246, 246, 242),
				ClearTextOnFocus = false,
				LayoutOrder = nextOrder(),
			}, list)
			corner(box, 8)
			local quote = line(S.get("plates.hint"), Theme.SubText)
			local claimBtn = button(S.get("plates.check"), Theme.PanelLight, Theme.Text)
			local want: string? = nil
			local function check(text: string)
				local r = ask("quote", text)
				if not (r and r.ok) then
					want = nil
					quote.Text = if r and r.message then r.message else S.get("plates.hint")
					quote.TextColor3 = Theme.Warning
					claimBtn.Text = S.get("plates.check")
					return
				end
				box.Text = r.plate
				quote.Text = S.get("plates.quote", money(r.price), table.concat(r.why, ", "))
				if r.free then
					want = r.plate
					quote.TextColor3 = Theme.Money
					claimBtn.Text = S.get("plates.claim", money(r.price))
					claimBtn.BackgroundColor3 = Theme.Accent2
					claimBtn.TextColor3 = Theme.Background
				else
					want = nil
					quote.Text ..= "  ·  " .. S.get("plates.taken")
					quote.TextColor3 = Theme.Danger
					claimBtn.Text = S.get("plates.check")
				end
			end
			box.FocusLost:Connect(function()
				if #box.Text > 0 then
					check(box.Text)
				end
			end)
			claimBtn.Activated:Connect(function()
				if want and car then
					local r = ask("claim", want, car.id)
					apply(r, r and r.ok and S.get("plates.claimed", r.plate, money(r.cost or 0)) or nil)
				elseif #box.Text > 0 then
					check(box.Text)
				end
			end)
			heading(S.get("plates.ideas"))
			local grid = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -6, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = nextOrder() }, list)
			new("UIGridLayout", { CellSize = UDim2.fromOffset(108, 70), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder }, grid)
			for k, t in Plates.ideas(Random.new(), 6) do
				local cell = new("TextButton", { Text = "", BackgroundColor3 = Theme.PanelLight, AutoButtonColor = true, LayoutOrder = k }, grid)
				corner(cell, 8)
				local p = plateBox(cell, t, 92, 0)
				p.Position = UDim2.fromOffset(8, 4)
				new("TextLabel", { BackgroundTransparency = 1, Position = UDim2.new(0, 0, 1, -22), Size = UDim2.new(1, 0, 0, 20), Font = Enum.Font.GothamBold, Text = money(Plates.price(t) :: number), TextSize = 12, TextColor3 = Theme.Money }, cell)
				cell.Activated:Connect(function()
					check(t)
				end)
			end
		end

		-- MY PLATES
		heading(S.get("plates.mine"))
		local names = {}
		for _, c in state.cars do
			names[c.id] = c.name
		end
		for _, b in state.bag do
			local row = new("Frame", { BackgroundColor3 = Theme.PanelLight, Size = UDim2.new(1, -6, 0, 64), LayoutOrder = nextOrder() }, list)
			corner(row, 8)
			local p = plateBox(row, b.plate, 100, 0)
			p.Position = UDim2.fromOffset(8, 9)
			new("TextLabel", {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(116, 8),
				Size = UDim2.new(1, -124, 0, 18),
				Font = Enum.Font.GothamBold,
				Text = if b.car then S.get("plates.on", names[b.car] or b.car) else S.get("plates.spare"),
				TextSize = 12,
				TextTruncate = Enum.TextTruncate.AtEnd,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextColor3 = Theme.Text,
			}, row)
			local btns = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(116, 30), Size = UDim2.new(1, -124, 0, 28) }, row)
			new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }, btns)
			if car and b.car ~= car.id then
				local put = button(S.get("plates.putOn"), Theme.Accent, Theme.Background, btns, UDim2.fromOffset(78, 28))
				put.TextSize = 11
				put.Activated:Connect(function()
					apply(ask("move", b.plate, car.id), S.get("plates.moved", b.plate))
				end)
			end
			if (b.paid or 0) > 0 then
				local sell = button(S.get("plates.sell", money(math.floor(b.paid * Plates.SELL_SHARE))), Theme.Danger, Theme.Text, btns, UDim2.fromOffset(96, 28))
				sell.TextSize = 11
				sell.Activated:Connect(function()
					local r = ask("sell", b.plate)
					apply(r, r and r.ok and S.get("plates.sold", b.plate, money(r.refund or 0)) or nil)
				end)
			end
		end
	end
	rebuild()
end

function PlateClient.init()
	task.spawn(function()
		local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
		local ev = remotes and remotes:WaitForChild("PlateOpen", 30) :: RemoteEvent?
		if ev then
			ev.OnClientEvent:Connect(function()
				PlateClient.open()
			end)
		end
	end)
	UI.onPlatesButton = PlateClient.open
end

return PlateClient
