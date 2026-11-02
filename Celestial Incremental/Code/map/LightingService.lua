-- GalaxyLightingService (Galaxy Incremental, lighting pass): puts MapConfig.Lighting on the game when the server starts
-- (GalaxyLighting.Apply), once the map (and so the Core's light) is there.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GalaxyLighting = require(ReplicatedStorage:WaitForChild("Galaxy"):WaitForChild("GalaxyLighting"))

workspace:WaitForChild("Galaxy", 30)
GalaxyLighting.Apply()
