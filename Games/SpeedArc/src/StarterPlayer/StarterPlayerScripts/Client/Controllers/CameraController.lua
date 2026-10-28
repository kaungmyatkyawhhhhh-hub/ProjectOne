-- CameraController: field of view widens a little as your walk speed grows (GDD 6.3: 70 -> 80).
-- Only reacts to WalkSpeed changes; the race camera is RaceController's job.
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local GameConfig = require(Shared.Config.GameConfig)
local UIKit = require(Shared.UIKit)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local CameraController = {}
local ctx

local function fovFor(walkSpeed)
	local w = GameConfig.Walk
	local t = math.clamp((walkSpeed - w.Base) / (w.Cap - w.Base), 0, 1)
	return w.FovMin + (w.FovMax - w.FovMin) * t
end

local function hook(char)
	local hum = char:WaitForChild("Humanoid")
	local function update()
		if player:GetAttribute("InRace") then
			return
		end
		local reduced = ctx and ctx.Settings and ctx.Settings.reduced()
		UIKit.tween(camera, 0.6, { FieldOfView = if reduced then 70 else fovFor(hum.WalkSpeed) }, Enum.EasingStyle.Sine)
	end
	hum:GetPropertyChangedSignal("WalkSpeed"):Connect(update)
	update()
end

function CameraController.start(c)
	ctx = c
	ctx.Camera = CameraController
	player.CharacterAdded:Connect(hook)
	if player.Character then
		task.spawn(hook, player.Character)
	end
end

return CameraController
