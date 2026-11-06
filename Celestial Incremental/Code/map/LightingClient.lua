-- GalaxyLightingClient (Galaxy Incremental, lighting pass): on a low-end device (a phone, Roblox graphics 1-3, or under
-- MapConfig.Lighting.LowEnd.FpsBelow FPS over 8 s after loading) this device turns bloom, shadows and the island star
-- lights off (GalaxyLighting.ApplyLowEnd). Studio: Workspace TestLowEnd = true.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local GalaxyLighting = require(Galaxy:WaitForChild("GalaxyLighting"))
local MapConfig = require(Galaxy:WaitForChild("MapConfig"))

-- PURPOSE (5 Nov, #13): until your Ignition 1 the galaxy is DIM (the grade: less colour, a little darker, a cool tint);
-- Ignition 1 "lights it up" (shared.GalaxyLightUp(seconds): back to MapConfig.Lighting.Grade). Your island's star still
-- lights your island, so the first minutes stay readable.
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
task.spawn(function()
	local grade = Lighting:WaitForChild("GalaxyGrade", 20)
	if not grade then return end
	local lit = MapConfig.Lighting.Grade
	local dim = MapConfig.Lighting.DimGrade
	local function apply(t: number?)
		local goal = if (player:GetAttribute("Ignition") or 0) >= 1 then lit else dim
		if t and t > 0 then
			TweenService:Create(grade, TweenInfo.new(t, Enum.EasingStyle.Sine), goal):Play()
		else
			for k, v in pairs(goal) do grade[k] = v end
		end
	end
	while player:GetAttribute("Ignition") == nil do player:GetAttributeChangedSignal("Ignition"):Wait() end
	apply()
	shared.GalaxyLightUp = function(seconds: number?) apply(seconds or 2.5) end
	player:GetAttributeChangedSignal("Ignition"):Connect(function() apply(2.5) end)
end)

-- (7 Nov: board screens are never in shadow: every SurfaceGui, in the map or drawn by this client, LightInfluence 0 +
-- Brightness 1.5 (MapConfig.Lighting.Screens))
do
	local S = MapConfig.Lighting.Screens
	local function screen(d: Instance)
		if d:IsA("SurfaceGui") then
			d.LightInfluence = S.LightInfluence
			d.Brightness = S.Brightness
		end
	end
	local pg = player:WaitForChild("PlayerGui")
	for _, root in ipairs({ workspace, pg }) do
		for _, d in ipairs(root:GetDescendants()) do screen(d) end
		root.DescendantAdded:Connect(screen)
	end
end

if GalaxyLighting.IsLowEnd() then
	GalaxyLighting.ApplyLowEnd()
	return
end

-- a slow PC on automatic graphics: watch the frame rate for 8 s once the map has loaded
task.wait(6)
local frames, start = 0, os.clock()
local counting = RunService.RenderStepped:Connect(function() frames += 1 end)
task.wait(8)
counting:Disconnect()
if frames / (os.clock() - start) < MapConfig.Lighting.LowEnd.FpsBelow then
	GalaxyLighting.ApplyLowEnd()
end
