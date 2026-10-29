--[[
	HouseClient - the island houses (see server/Houses.lua)
	  * prompts for this player: "Buy" / "Move in" on free plots, owner-only prompts on your house
	  * the cars in the gallery bays: skinned when you come close
	  * the garage setup panel: pick the car that stands in each bay
	  * "Drive" on a bay car: the car spawns on the driveway and you drive off
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Cars = require(Shared:WaitForChild("Cars"))
local UI = require(script.Parent:WaitForChild("UI"))
local CarSkin = require(script.Parent:WaitForChild("CarSkin"))

local HouseClient = {}

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local Theme = Config.Theme
local COLORS = { money = Theme.Money, accent = Theme.Accent, warning = Theme.Warning, danger = Theme.Danger }

local houses: { [string]: Instance } = {} -- plot id -> house model
local call: RemoteFunction? = nil

---------------------------------------------------------------------
-- Prompts worded and shown for this player
---------------------------------------------------------------------
local function ownedKinds(): { [string]: boolean }
	local set = {}
	local raw = player:GetAttribute("Houses")
	if type(raw) == "string" then
		for id in raw:gmatch("[^,]+") do
			set[id] = true
		end
	end
	return set
end

local function word(p: Instance)
	if not p:IsA("ProximityPrompt") then
		return
	end
	local plotId = p:GetAttribute("Plot")
	local house = if type(plotId) == "string" then houses[plotId] else nil
	if not house then
		return
	end
	local owner = house:GetAttribute("Owner")
	if p:HasTag("HouseBuy") then
		local kind = house:GetAttribute("Kind")
		p.Enabled = owner == nil
		local moving = type(kind) == "string" and ownedKinds()[kind] == true
		p.ActionText = if moving then "Move in" else "Buy"
		p.HoldDuration = if moving then 0.4 else 1.5
	elseif p:HasTag("HouseOwner") then
		p.Enabled = owner == player.UserId
	elseif p:HasTag("HouseVisitor") then
		-- the doorbell: for everyone but the owner
		p.Enabled = owner ~= player.UserId
	end
end

local function rewordAll()
	for _, tag in { "HouseBuy", "HouseOwner", "HouseVisitor" } do
		for _, p in CollectionService:GetTagged(tag) do
			word(p)
		end
	end
end

local function addHouse(model: Instance)
	local id = model:GetAttribute("Plot")
	if type(id) ~= "string" then
		return
	end
	houses[id] = model
	model:GetAttributeChangedSignal("Owner"):Connect(rewordAll)
	task.defer(rewordAll)
end

---------------------------------------------------------------------
-- The garage setup panel
---------------------------------------------------------------------
local gui: ScreenGui? = nil

local function closePanel()
	if gui then
		gui:Destroy()
		gui = nil
	end
end

local function corner(parent: Instance, r: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = parent
end

local function stroke(parent: Instance)
	local s = Instance.new("UIStroke")
	s.Color = Theme.Stroke
	s.Thickness = 1
	s.Parent = parent
end

local function label(parent: Instance, text: string, size: number, color: Color3, font: Enum.Font?): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextSize = size
	l.TextColor3 = color
	l.Font = font or Enum.Font.GothamMedium
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextTruncate = Enum.TextTruncate.AtEnd
	l.Parent = parent
	return l
end

local function carName(id: string): string
	local spec = Cars.ById[id]
	return if spec then spec.Name else id
end

local function openPanel(plotId: string)
	local remote = call
	if not remote then
		return
	end
	local ok, state = pcall(function()
		return remote:InvokeServer("garage", plotId)
	end)
	if not ok or type(state) ~= "table" or not state.ok then
		UI.toast("Only the owner can set up this garage", Theme.Warning)
		return
	end
	closePanel()
	local bays: { string } = state.bays
	local owned: { string } = state.owned
	table.sort(owned, function(a, b)
		return Cars.get(a).Price > Cars.get(b).Price
	end)
	local selected = 1

	local screen = Instance.new("ScreenGui")
	screen.Name = "HouseGarage"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.DisplayOrder = 20
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui = screen

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.new(0.92, 0, 0.78, 0)
	panel.BackgroundColor3 = Theme.Panel
	panel.BackgroundTransparency = 0.04
	panel.Parent = screen
	corner(panel, 14)
	stroke(panel)
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = Vector2.new(720, 460)
	limit.Parent = panel

	local title = label(panel, "GARAGE  ·  " .. string.upper(tostring(state.name)), 20, Theme.Text, Enum.Font.GothamBlack)
	title.Position = UDim2.new(0, 20, 0, 14)
	title.Size = UDim2.new(1, -80, 0, 28)
	local hint = label(panel, "Pick a bay, then the car that stands in it", 13, Theme.SubText)
	hint.Position = UDim2.new(0, 20, 0, 42)
	hint.Size = UDim2.new(1, -80, 0, 18)

	local close = Instance.new("TextButton")
	close.Size = UDim2.fromOffset(36, 36)
	close.Position = UDim2.new(1, -50, 0, 14)
	close.BackgroundColor3 = Theme.PanelLight
	close.Text = "X"
	close.Font = Enum.Font.GothamBold
	close.TextSize = 16
	close.TextColor3 = Theme.Text
	close.Parent = panel
	corner(close, 8)
	close.Activated:Connect(closePanel)

	local function column(x: number, w: number): ScrollingFrame
		local f = Instance.new("ScrollingFrame")
		f.Position = UDim2.new(x, if x == 0 then 16 else 8, 0, 72)
		f.Size = UDim2.new(w, -24, 1, -88)
		f.BackgroundColor3 = Theme.Background
		f.BackgroundTransparency = 0.3
		f.BorderSizePixel = 0
		f.ScrollBarThickness = 5
		f.AutomaticCanvasSize = Enum.AutomaticSize.Y
		f.CanvasSize = UDim2.new()
		f.Parent = panel
		corner(f, 10)
		local list = Instance.new("UIListLayout")
		list.Padding = UDim.new(0, 6)
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.Parent = f
		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0, 8)
		pad.PaddingBottom = UDim.new(0, 8)
		pad.PaddingLeft = UDim.new(0, 8)
		pad.PaddingRight = UDim.new(0, 12)
		pad.Parent = f
		return f
	end
	local left = column(0, 0.45)
	local right = column(0.45, 0.55)

	local bayButtons: { TextButton } = {}
	local function row(parent: Instance, order: number, head: string, text: string, color: Color3): TextButton
		local b = Instance.new("TextButton")
		b.LayoutOrder = order
		b.Size = UDim2.new(1, 0, 0, 44)
		b.BackgroundColor3 = Theme.PanelLight
		b.AutoButtonColor = true
		b.Text = ""
		b.Parent = parent
		corner(b, 8)
		local h = label(b, head, 15, color, Enum.Font.GothamBlack)
		h.Position = UDim2.new(0, 10, 0, 0)
		h.Size = UDim2.new(0, 34, 1, 0)
		local t = label(b, text, 14, Theme.Text)
		t.Name = "Text"
		t.Position = UDim2.new(0, 46, 0, 0)
		t.Size = UDim2.new(1, -52, 1, 0)
		return b
	end

	local function paint()
		for k, b in bayButtons do
			local id = bays[k]
			local t = b:FindFirstChild("Text") :: TextLabel
			t.Text = if id ~= "" then carName(id) else "Empty"
			t.TextColor3 = if id ~= "" then Theme.Text else Theme.SubText
			b.BackgroundColor3 = if k == selected then Theme.Stroke else Theme.PanelLight
		end
	end

	for k = 1, #bays do
		-- (the garage's bays first, then the driveway spots: D1, D2...)
		local tag = if type(state.garage) == "number" and k > state.garage then "D" .. (k - state.garage) else string.format("%02d", k)
		local b = row(left, k, tag, "", Theme.Accent)
		bayButtons[k] = b
		b.Activated:Connect(function()
			selected = k
			paint()
		end)
	end

	local busy = false
	local function assign(carId: string)
		if busy then
			return
		end
		busy = true
		local okSet, result = pcall(function()
			return remote:InvokeServer("setBay", { plot = plotId, bay = selected, car = carId })
		end)
		busy = false
		if okSet and type(result) == "table" and result.ok and type(result.bays) == "table" then
			bays = result.bays
			if selected < #bays then
				selected += 1
			end
			paint()
		else
			UI.toast(if okSet and type(result) == "table" and result.message then tostring(result.message) else "Could not change the bay", Theme.Danger)
		end
	end

	local empty = row(right, 0, "–", "Empty bay", Theme.SubText)
	empty.Activated:Connect(function()
		assign("")
	end)
	for k, id in owned do
		local b = row(right, k, "", carName(id), Theme.Money)
		local tag = b:FindFirstChildWhichIsA("TextLabel")
		if tag then
			tag.Text = Cars.get(id).Tier == "High" and "★" or "•"
		end
		b.Activated:Connect(function()
			assign(id)
		end)
	end
	paint()
	screen.Parent = player:WaitForChild("PlayerGui")
end

---------------------------------------------------------------------
-- Start
---------------------------------------------------------------------
-- onDrive: Main's own "drive this car" (spawns the car and attaches the controls)
function HouseClient.init(onDrive: (string) -> ())
	for _, m in CollectionService:GetTagged("IslandHouse") do
		addHouse(m)
	end
	CollectionService:GetInstanceAddedSignal("IslandHouse"):Connect(addHouse)
	for _, tag in { "HouseBuy", "HouseOwner", "HouseVisitor" } do
		CollectionService:GetInstanceAddedSignal(tag):Connect(word)
	end
	player:GetAttributeChangedSignal("Houses"):Connect(rewordAll)
	task.defer(rewordAll)

	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	call = remotes:WaitForChild("HouseCall", 60) :: RemoteFunction?
	local fx = remotes:WaitForChild("HouseFx", 60) :: RemoteEvent?
	if fx then
		fx.OnClientEvent:Connect(function(info)
			if type(info) ~= "table" then
				return
			end
			if info.kind == "toast" then
				UI.toast(tostring(info.text), COLORS[info.color] or Theme.Accent)
			elseif info.kind == "bought" then
				UI.toast(tostring(info.text), Theme.Money)
				UI.popup("HOUSE BOUGHT", tonumber(info.amount) or 0, Theme.Money)
			elseif info.kind == "garage" and type(info.plot) == "string" then
				openPanel(info.plot)
			elseif info.kind == "drive" and type(info.id) == "string" then
				closePanel()
				onDrive(info.id)
			end
		end)
	end

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and gui and input.KeyCode == Enum.KeyCode.Escape then
			closePanel()
		end
	end)

	-- the cars in the bays: the smooth body when you come close
	local skinned: { [Instance]: boolean } = setmetatable({}, { __mode = "k" }) :: any
	local acc = 0
	RunService.Heartbeat:Connect(function(dt: number)
		acc += dt
		if acc < 0.5 then
			return
		end
		acc = 0
		local camPos = camera.CFrame.Position
		for _, car in CollectionService:GetTagged("HouseShowcase") do
			if car:IsA("Model") and car.Parent and not skinned[car] and (car:GetPivot().Position - camPos).Magnitude < 420 then
				skinned[car] = true
				task.spawn(function()
					local okSkin, err = pcall(CarSkin.apply, car, false)
					if not okSkin then
						warn("[CityLegends] house car skin failed:", err)
					end
				end)
			end
		end
	end)
end

return HouseClient
