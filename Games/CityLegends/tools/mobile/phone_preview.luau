--[[ Phone preview for screenshots in Studio Play (2026-11-19, mobile pass). Run on the Client
datamodel with execute_luau. Every ScreenGui's top-level pieces are moved into a W x H "Phone"
frame (default 812 x 375, an iPhone X in landscape) blown up to fill the window with a UIScale,
so scale-anchored HUD pieces sit where they would on that phone. Re-run after new screens open
(they are made straight in their ScreenGui). Undo: run with UNDO = true. Not game code. ]]
local W, H, UNDO = 812, 375, false
local pg = game:GetService("Players").LocalPlayer.PlayerGui
local cam = workspace.CurrentCamera.ViewportSize
for _, g in pg:GetChildren() do
	if g:IsA("ScreenGui") then
		local phone = g:FindFirstChild("PhonePreview")
		if UNDO then
			if phone then
				for _, c in phone:GetChildren() do
					if not c:IsA("UIScale") then c.Parent = g end
				end
				phone:Destroy()
			end
		else
			if not phone then
				phone = Instance.new("Frame")
				phone.Name = "PhonePreview"
				phone.BackgroundTransparency = 1
				phone.AnchorPoint = Vector2.new(0.5, 0.5)
				phone.Position = UDim2.fromScale(0.5, 0.5)
				phone.ClipsDescendants = true
				local s = Instance.new("UIScale")
				s.Parent = phone
				phone.Parent = g
			end
			phone.Size = UDim2.fromOffset(W, H)
			phone:FindFirstChildOfClass("UIScale").Scale = math.min(cam.X / W, cam.Y / H)
			for _, c in g:GetChildren() do
				if c ~= phone and c:IsA("GuiObject") then c.Parent = phone end
			end
		end
	end
end
return "ok"
