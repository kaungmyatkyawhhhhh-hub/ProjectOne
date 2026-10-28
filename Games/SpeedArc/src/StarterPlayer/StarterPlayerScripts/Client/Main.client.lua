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
	"RaceFxController",
	"WorldLifeController",
	"LockerController",
	"CoachController",
	"MenuController",
	"CosmeticsController",
	"SpeedFeelController",
	"MomentController",
	"MusicController",
	"TutorialController",
	"RetentionController",
	"StoreController",
	"SocialController",
	"LeaderboardController",
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

-- build every window once behind the loading screen / menu (lesson: the first open must not freeze)
task.spawn(function()
	local UIKit = require(Shared.UIKit)
	local player = game:GetService("Players").LocalPlayer
	task.wait(1)
	if not player:GetAttribute("InMenu") then
		return
	end
	local sound = UIKit.windowSound
	UIKit.windowSound = nil
	for _, open in {
		function() ctx.Locker.open("SHOES") end,
		function() ctx.Coaches.open("ROLL") end,
		function() ctx.Store.open("PASSES") end,
	} do
		pcall(open)
		task.wait(0.1)
		UIKit.closeWindows()
	end
	UIKit.windowSound = sound
end)
