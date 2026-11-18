--[[
	MallLift (client, 2026-11-19): the floor picker inside a lift car (Models tagged "MallLift", run by the server's
	MallMovers). While the player stands in a car a small panel shows one big button per floor (B1, G, 1, 2, 3), the
	current floor lit; a tap sends MallLiftCall(lift, floor). Phone-first: 56 px buttons, bottom middle above the
	thumbstick zone. Checks twice a second, and only when a lift is within 80 studs.
]]
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local call = ReplicatedStorage:WaitForChild("MallLiftCall", 30)
if not call then
	return
end

local gui = Instance.new("ScreenGui")
gui.Name = "MallLiftPanel"
gui.ResetOnSpawn = false
gui.Enabled = false
gui.DisplayOrder = 8
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 1)
panel.Position = UDim2.new(0.5, 0, 1, -150)
panel.AutomaticSize = Enum.AutomaticSize.X
panel.Size = UDim2.fromOffset(0, 92)
panel.BackgroundColor3 = Color3.fromRGB(18, 20, 26)
panel.BackgroundTransparency = 0.12
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)
local stroke = Instance.new("UIStroke", panel)
stroke.Color = Color3.fromRGB(255, 255, 255)
stroke.Transparency = 0.85
local pad = Instance.new("UIPadding", panel)
pad.PaddingLeft, pad.PaddingRight, pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 12), UDim.new(0, 12), UDim.new(0, 8), UDim.new(0, 10)
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 16)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 13
title.TextColor3 = Color3.fromRGB(200, 204, 214)
title.Text = "LIFT"
title.Parent = panel
local row = Instance.new("Frame")
row.Position = UDim2.fromOffset(0, 20)
row.AutomaticSize = Enum.AutomaticSize.X
row.Size = UDim2.fromOffset(0, 56)
row.BackgroundTransparency = 1
row.Parent = panel
local list = Instance.new("UIListLayout", row)
list.FillDirection = Enum.FillDirection.Horizontal
list.Padding = UDim.new(0, 8)
list.SortOrder = Enum.SortOrder.LayoutOrder

local GOLD = Color3.fromRGB(240, 196, 84)
local current: Model? = nil
local buttons: { [number]: TextButton } = {}

local function build(lift: Model)
	for _, b in buttons do
		b:Destroy()
	end
	buttons = {}
	local stops = lift:FindFirstChild("Stops")
	if not stops then
		return
	end
	for _, s in stops:GetChildren() do
		local i = tonumber(s.Name:match("^Stop(%d+)$"))
		if i then
			local b = Instance.new("TextButton")
			b.LayoutOrder = i
			b.Size = UDim2.fromOffset(56, 56)
			b.BackgroundColor3 = Color3.fromRGB(44, 48, 58)
			b.Font = Enum.Font.GothamBlack
			b.TextSize = 22
			b.TextColor3 = Color3.fromRGB(240, 242, 246)
			b.Text = s:GetAttribute("Label") or tostring(i)
			b.AutoButtonColor = true
			Instance.new("UICorner", b).CornerRadius = UDim.new(1, 0)
			b.Activated:Connect(function()
				call:FireServer(lift, i)
				b.BackgroundColor3 = GOLD
				b.TextColor3 = Color3.fromRGB(24, 22, 16)
			end)
			b.Parent = row
			buttons[i] = b
		end
	end
end

local function carOf(lift: Model): BasePart?
	local car = lift:FindFirstChild("Car")
	return car and (car.PrimaryPart or car:FindFirstChild("Floor")) :: BasePart?
end

local function inside(lift: Model, root: BasePart): boolean
	local f = carOf(lift)
	if not f then
		return false
	end
	local rel = f.CFrame:PointToObjectSpace(root.Position)
	return math.abs(rel.X) < f.Size.X / 2 and math.abs(rel.Z) < f.Size.Z / 2 and rel.Y > -1 and rel.Y < (lift:GetAttribute("CarHeight") or 8)
end

local function refresh(lift: Model)
	local at = lift:GetAttribute("At")
	for i, b in buttons do
		local here = i == at
		if here or b.BackgroundColor3 ~= GOLD then
			b.BackgroundColor3 = here and Color3.fromRGB(70, 160, 110) or Color3.fromRGB(44, 48, 58)
			b.TextColor3 = Color3.fromRGB(240, 242, 246)
		end
	end
end

while true do
	task.wait(0.5)
	local c = player.Character
	local root = c and c:FindFirstChild("HumanoidRootPart") :: BasePart?
	local found: Model? = nil
	if root then
		for _, lift in CollectionService:GetTagged("MallLift") do
			local f = carOf(lift)
			if f and (f.Position - root.Position).Magnitude < 80 and inside(lift, root) then
				found = lift
				break
			end
		end
	end
	if found ~= current then
		current = found
		if found then
			build(found)
		end
		gui.Enabled = found ~= nil
	end
	if current then
		refresh(current)
	end
end
