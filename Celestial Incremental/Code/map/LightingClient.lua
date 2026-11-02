-- GalaxyLightingClient (Galaxy Incremental, lighting pass): on a low-end device (a phone, Roblox graphics 1-3, or under
-- MapConfig.Lighting.LowEnd.FpsBelow FPS over 8 s after loading) this device turns bloom, shadows and the island star
-- lights off (GalaxyLighting.ApplyLowEnd). Studio: Workspace TestLowEnd = true.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local GalaxyLighting = require(Galaxy:WaitForChild("GalaxyLighting"))
local MapConfig = require(Galaxy:WaitForChild("MapConfig"))

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
