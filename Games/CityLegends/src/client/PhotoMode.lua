--[[
	PhotoMode (owner, 2026-10-30, from the research: Driving Empire's photo mode, Midnight Racing's
	car meets): O (or Settings > Photo mode) hides every screen and lets you frame your car.
	  * drag to turn round the car (or you), scroll / + - to come closer or go back
	  * TIME: hold the time of day; FOV; BLUR: depth of field on the car; HIDE: the bar too (tap
	    anywhere to bring it back); EXIT
	It's all on your own screen: nobody else sees the time or the camera change.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local UI = require(script.Parent:WaitForChild("UI"))
local Driving = require(script.Parent:WaitForChild("Driving"))
local DayCycle = require(script.Parent:WaitForChild("DayCycle"))

local PhotoMode = {}

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local Theme = Config.Theme
local kit = UI.kit

local open = false
local gui: ScreenGui? = nil
local hidden: { [ScreenGui]: boolean } = {}
local conns: { RBXScriptConnection } = {}
local dof: DepthOfFieldEffect? = nil
local yaw, pitch, dist = 0, 0.25, 22
local fov = 50
local blur = true
local hour = 0
local oldFov = 70
local closedAt = 0

local function target(): BasePart?
	local root = Driving.getRoot()
	if root then
		return root
	end
	local character = player.Character
	return if character then character:FindFirstChild("HumanoidRootPart") :: BasePart? else nil
end

function PhotoMode.isOpen(): boolean
	return open
end

function PhotoMode.close()
	if not open then
		return
	end
	open = false
	closedAt = os.clock()
	for _, c in conns do
		c:Disconnect()
	end
	table.clear(conns)
	if gui then
		gui:Destroy()
		gui = nil
	end
	for g, was in hidden do
		if g.Parent then
			g.Enabled = was
		end
	end
	table.clear(hidden)
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
	end)
	if dof then
		dof:Destroy()
		dof = nil
	end
	DayCycle.override = nil
	camera.FieldOfView = oldFov
	Driving.cameraHold = false
	camera.CameraType = Enum.CameraType.Custom
end

function PhotoMode.open()
	local t = target()
	if open or not t then
		return
	end
	open = true
	oldFov = camera.FieldOfView
	-- every screen away (kept to put back as they were)
	for _, g in player.PlayerGui:GetChildren() do
		if g:IsA("ScreenGui") then
			hidden[g] = g.Enabled
			g.Enabled = false
		end
	end
	pcall(function()
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
	end)
	Driving.cameraHold = true
	camera.CameraType = Enum.CameraType.Scriptable
	local look = camera.CFrame.LookVector
	yaw = math.atan2(-look.X, -look.Z)
	pitch, dist, fov, blur = 0.22, 22, 50, true
	hour = DayCycle.hour()
	local d = Instance.new("DepthOfFieldEffect")
	d.Name = "PhotoDof"
	d.InFocusRadius = 12
	d.NearIntensity = 0.3
	d.FarIntensity = 0.55
	d.Parent = Lighting
	dof = d

	-- the bar along the bottom
	local g = Instance.new("ScreenGui")
	g.Name = "PhotoMode"
	g.ResetOnSpawn = false
	g.IgnoreGuiInset = true
	g.DisplayOrder = 50
	g.Parent = player.PlayerGui
	gui = g
	local compact = camera.ViewportSize.X < 760
	local b: Frame = kit.new("Frame", {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -14),
		Size = UDim2.fromOffset(if compact then 600 else 720, 64),
		BackgroundColor3 = Theme.Panel,
		BackgroundTransparency = 0.1,
		Parent = g,
	}, { kit.corner(14), kit.stroke(Theme.Stroke, 1.5, 0.1), kit.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Center }) })
	local sc = kit.new("UIScale", { Parent = b })
	sc.Scale = math.min(1, (camera.ViewportSize.X - 20) / (if compact then 600 else 720))
	local timeLabel: TextLabel
	local fovLabel: TextLabel
	local function group(name: string, minus: () -> (), plus: () -> ()): TextLabel
		local f = kit.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(150, 48), Parent = b })
		local l = kit.label({ Text = name, TextSize = 13, Font = Enum.Font.GothamBlack, Position = UDim2.fromOffset(44, 0), Size = UDim2.new(1, -88, 1, 0), Parent = f })
		local m = kit.button("-", Theme.Accent, { Size = UDim2.fromOffset(40, 44), Position = UDim2.fromOffset(0, 2), TextSize = 20, Parent = f })
		local p = kit.button("+", Theme.Accent, { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 2), Size = UDim2.fromOffset(40, 44), TextSize = 20, Parent = f })
		m.Activated:Connect(minus)
		p.Activated:Connect(plus)
		return l
	end
	local function showTime()
		local h = math.floor(hour) % 24
		local m = math.floor((hour % 1) * 60)
		timeLabel.Text = string.format("TIME %02d:%02d", h, m)
	end
	timeLabel = group("TIME", function()
		hour = (hour - 1) % 24
		DayCycle.override = hour
		showTime()
	end, function()
		hour = (hour + 1) % 24
		DayCycle.override = hour
		showTime()
	end)
	DayCycle.override = hour
	showTime()
	fovLabel = group("FOV", function()
		fov = math.clamp(fov - 5, 15, 100)
		fovLabel.Text = "FOV " .. fov
	end, function()
		fov = math.clamp(fov + 5, 15, 100)
		fovLabel.Text = "FOV " .. fov
	end)
	fovLabel.Text = "FOV " .. fov
	local blurBtn = kit.button("BLUR ON", Theme.Accent, { Size = UDim2.fromOffset(110, 44), TextSize = 14, Parent = b })
	blurBtn.Activated:Connect(function()
		blur = not blur
		blurBtn.Text = if blur then "BLUR ON" else "BLUR OFF"
		if dof then
			dof.Enabled = blur
		end
	end)
	local hideBtn = kit.button("HIDE", Theme.Accent2, { Size = UDim2.fromOffset(84, 44), TextSize = 14, TextColor3 = Theme.Accent2, Parent = b })
	hideBtn.Activated:Connect(function()
		b.Visible = false
		UI.toast("Tap or click anywhere to bring the bar back", Theme.SubText)
	end)
	local exitBtn = kit.button("EXIT", Theme.Danger, { Size = UDim2.fromOffset(84, 44), TextSize = 14, TextColor3 = Theme.Danger, Parent = b })
	exitBtn.Activated:Connect(PhotoMode.close)
	if UI.isTouch then
		-- (on a phone: two buttons to come closer and go back)
		local zoom = kit.new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -14, 0.45, 0), Size = UDim2.fromOffset(48, 104), BackgroundTransparency = 1, Parent = g })
		local zin = kit.button("+", Theme.Accent, { Size = UDim2.fromOffset(48, 48), TextSize = 22, Parent = zoom })
		local zout = kit.button("-", Theme.Accent, { Position = UDim2.fromOffset(0, 56), Size = UDim2.fromOffset(48, 48), TextSize = 22, Parent = zoom })
		zin.Activated:Connect(function()
			dist = math.clamp(dist * 0.8, 6, 90)
		end)
		zout.Activated:Connect(function()
			dist = math.clamp(dist * 1.25, 6, 90)
		end)
	end

	-- drag to turn, wheel to zoom
	local dragging: InputObject? = nil
	local last = Vector2.zero
	table.insert(conns, UserInputService.InputBegan:Connect(function(input, processed)
		if input.KeyCode == Enum.KeyCode.O or input.KeyCode == Enum.KeyCode.Escape then
			if not processed or input.KeyCode == Enum.KeyCode.Escape then
				PhotoMode.close()
			end
			return
		end
		if processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.Touch then
			if not b.Visible then
				b.Visible = true
			end
			dragging = input
			last = Vector2.new(input.Position.X, input.Position.Y)
		end
	end))
	table.insert(conns, UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			dist = math.clamp(dist * (if input.Position.Z > 0 then 0.88 else 1.14), 6, 90)
		elseif dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input == dragging) then
			local p = Vector2.new(input.Position.X, input.Position.Y)
			local d = p - last
			last = p
			yaw -= d.X * 0.008
			pitch = math.clamp(pitch + d.Y * 0.006, -0.15, 1.35)
		end
	end))
	table.insert(conns, UserInputService.InputEnded:Connect(function(input)
		if dragging and (input == dragging or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2) then
			dragging = nil
		end
	end))
	table.insert(conns, RunService.RenderStepped:Connect(function()
		local part = target()
		if not part then
			PhotoMode.close()
			return
		end
		local focus = part.Position + Vector3.new(0, 1.6, 0)
		local offset = CFrame.Angles(0, yaw, 0) * CFrame.Angles(-pitch, 0, 0) * Vector3.new(0, 0, dist)
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = CFrame.lookAt(focus + offset, focus)
		camera.Focus = CFrame.new(focus)
		camera.FieldOfView = fov
		if dof then
			dof.FocusDistance = dist
			dof.InFocusRadius = math.max(6, dist * 0.35)
		end
	end))
end

function PhotoMode.toggle()
	if open then
		PhotoMode.close()
	else
		PhotoMode.open()
	end
end

function PhotoMode.init()
	UserInputService.InputBegan:Connect(function(input, processed)
		-- O, or Shift + P (Driving Empire's free camera)
		local key = input.KeyCode == Enum.KeyCode.O or (input.KeyCode == Enum.KeyCode.P and UserInputService:IsKeyDown(Enum.KeyCode.LeftShift))
		if not processed and not open and key and UserInputService:GetFocusedTextBox() == nil and os.clock() - closedAt > 0.3 then
			PhotoMode.open()
		end
	end)
	UI.onPhotoButton = PhotoMode.open
end

return PhotoMode
