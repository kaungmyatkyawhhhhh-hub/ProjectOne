-- MB_ShopController: close (X / Esc-free) and reopen the shop with a SHOP button. Shop starts closed.
local gui = script.Parent
local TweenService = game:GetService("TweenService")
local root, dim, close = gui:WaitForChild("Root"), gui:FindFirstChild("Dim"), gui:WaitForChild("Root"):WaitForChild("Close")

local scale = root:FindFirstChild("PopScale") or Instance.new("UIScale")
scale.Name = "PopScale"; scale.Parent = root

local openBtn = gui:FindFirstChild("OpenShop") or Instance.new("TextButton")
openBtn.Name = "OpenShop"
openBtn.AnchorPoint = Vector2.new(0, 0.5); openBtn.Position = UDim2.new(0, 14, 0.5, 0)
openBtn.Size = UDim2.fromOffset(96, 52)
openBtn.BackgroundColor3 = Color3.fromRGB(255, 196, 40)
openBtn.Font = Enum.Font.FredokaOne; openBtn.TextSize = 24; openBtn.TextColor3 = Color3.new(1, 1, 1)
openBtn.Text = "SHOP"; openBtn.ZIndex = 50
if not openBtn:FindFirstChildOfClass("UICorner") then
	Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 12)
	local s = Instance.new("UIStroke", openBtn); s.Thickness = 3; s.Color = Color3.fromRGB(60, 30, 0)
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	local t = Instance.new("UIStroke", openBtn); t.Thickness = 2; t.Color = Color3.fromRGB(60, 30, 0)
	t.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
end
openBtn.Parent = gui

local function setOpen(open)
	if dim then dim.Visible = open end
	openBtn.Visible = not open
	if open then
		root.Visible = true
		scale.Scale = 0.85
		TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
	else
		for _, p in ipairs({"BuyPopup", "GiftPopup"}) do
			local f = root:FindFirstChild(p); if f then f.Visible = false end
		end
		root.Visible = false
	end
end

close.Activated:Connect(function() setOpen(false) end)
openBtn.Activated:Connect(function() setOpen(true) end)
if dim and dim:IsA("GuiButton") then dim.Activated:Connect(function() setOpen(false) end) end
setOpen(false)
