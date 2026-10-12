--!strict
-- Break A Bed: the CODES row in the Settings window (client).
-- ModuleScript next to the Settings script. Usage inside Settings, after the other rows:
--   local CodesRow = require(script.Parent.CodesRow)
--   CodesRow.Build(rowsContainer, layoutOrder, UIKit)
-- Look: yellow studded row (sim-btn-yellow, 9-slice), "CODES" label, white text box
-- "Enter code...", green REDEEM button (sim-btn-green). Same height as the CODES row in
-- preview-settings-sliders.png. Uses the UI Kit's sounds/animations if passed in.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CodesRow = {}

local function shake(gui: GuiObject)
	local start = gui.Position
	for i = 1, 6 do
		local dx = (i % 2 == 0) and 6 or -6
		gui.Position = start + UDim2.fromOffset(dx, 0)
		task.wait(0.03)
	end
	gui.Position = start
end

function CodesRow.Build(parent: Instance, order: number, UIKit: any?)
	local rf = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("RedeemCode") :: RemoteFunction

	-- Claude Code: replace these three with the UI Kit's real builders/images
	-- (yellow studded row, white input, green studded button) so it matches the other rows.
	local row = Instance.new("Frame")
	row.Name = "CodesRow"
	row.LayoutOrder = order
	row.Size = UDim2.new(1, 0, 0, 84)
	row.BackgroundColor3 = Color3.fromRGB(255, 215, 20)
	row.Parent = parent

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Size = UDim2.new(0, 140, 1, 0)
	label.Position = UDim2.fromOffset(20, 0)
	label.Font = Enum.Font.FredokaOne
	label.Text = "CODES"
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Parent = row

	local box = Instance.new("TextBox")
	box.Name = "Input"
	box.Size = UDim2.new(0.42, 0, 0, 52)
	box.Position = UDim2.new(0, 170, 0.5, -26)
	box.PlaceholderText = "Enter code..."
	box.Text = ""
	box.ClearTextOnFocus = false
	box.Font = Enum.Font.FredokaOne
	box.TextScaled = true
	box.TextColor3 = Color3.fromRGB(30, 30, 40)
	box.BackgroundColor3 = Color3.fromRGB(245, 245, 250)
	box.Parent = row

	local btn = Instance.new("TextButton")
	btn.Name = "Redeem"
	btn.Size = UDim2.new(0, 170, 0, 58)
	btn.AnchorPoint = Vector2.new(1, 0.5)
	btn.Position = UDim2.new(1, -16, 0.5, 0)
	btn.Font = Enum.Font.FredokaOne
	btn.Text = "REDEEM"
	btn.TextScaled = true
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.BackgroundColor3 = Color3.fromRGB(110, 220, 20)
	btn.Parent = row

	local sending = false
	local function submit()
		if sending then return end
		local text = box.Text
		if #text:gsub("%s", "") == 0 then
			task.spawn(shake, box)
			return
		end
		sending = true
		btn.Text = "..."
		local ok, res = pcall(function()
			return rf:InvokeServer(text)
		end)
		sending = false
		btn.Text = "REDEEM"
		if not ok or typeof(res) ~= "table" then
			res = { ok = false, message = "Try again!" }
		end
		if res.ok then
			box.Text = ""
			box.PlaceholderText = res.message
			-- green flash on the row
			local flash = TweenService:Create(row, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(120, 255, 90) })
			flash:Play(); flash.Completed:Wait()
			TweenService:Create(row, TweenInfo.new(0.35), { BackgroundColor3 = Color3.fromRGB(255, 215, 20) }):Play()
			if UIKit and UIKit.PlaySound then UIKit.PlaySound("Claim") end
			if UIKit and UIKit.Toast then UIKit.Toast("Code redeemed: " .. res.message) end
		else
			box.TextColor3 = Color3.fromRGB(220, 40, 40)
			box.Text = res.message
			task.spawn(shake, box)
			if UIKit and UIKit.PlaySound then UIKit.PlaySound("Error") end
			task.delay(1.4, function()
				if box.Text == res.message then box.Text = "" end
				box.TextColor3 = Color3.fromRGB(30, 30, 40)
			end)
		end
	end

	btn.Activated:Connect(submit)
	box.FocusLost:Connect(function(enter)
		if enter then submit() end
	end)
	return row
end

return CodesRow
