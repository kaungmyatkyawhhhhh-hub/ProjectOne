-- SPEED ARC client boot. Starts every controller in order; they share one ctx table.
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Net = require(Shared.Util.Net)

local Controllers = script.Parent:WaitForChild("Controllers")
local ORDER = {
	"SoundController",
	"LightingController",
	"HudController",
	"CameraController",
	"TrainingController",
	"RaceController",
	"WorldLifeController",
	"LockerController",
	"CoachController",
	"MenuController",
	"CosmeticsController",
	"SpeedFeelController",
	"MomentController",
	"MusicController",
}

local ctx = { Net = Net }
for _, name in ORDER do
	local ok, err = pcall(function()
		require(Controllers:WaitForChild(name)).start(ctx)
	end)
	if not ok then
		warn("[SPEED ARC] " .. name .. " failed to start: " .. tostring(err))
	end
end
