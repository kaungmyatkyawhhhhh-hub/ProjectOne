-- StepController (28 Oct pivot): the "+1 SPEED every step" feel. Whenever your SPEED goes up from
-- steps (running or a machine) a +N popup rises (pooled, HUD) with a soft tick, at most a few a
-- second so a fast runner never floods the screen. The server decides the real gain (StepService).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Palette = require(Shared.Config.Palette)
local Format = require(Shared.Util.Format)

local player = Players.LocalPlayer

local Step = {}

local POPUP_GAP = 0.14 -- seconds between popups (the gains in between are added up)
local SOUND_GAP = 0.22

function Step.start(ctx)
	local last = player:GetAttribute("Speed") or 0
	local pending = 0
	local lastPopup, lastSound = 0, 0
	player:GetAttributeChangedSignal("Speed"):Connect(function()
		local v = player:GetAttribute("Speed") or 0
		local d = v - last
		last = v
		-- races, Go Pro (SPEED back to 0) and the tutorial burst have their own moments
		if d > 0 and not player:GetAttribute("InRace") and not player:GetAttribute("InMenu") then
			pending += d
		end
	end)
	RunService.Heartbeat:Connect(function()
		if pending <= 0 then
			return
		end
		local now = os.clock()
		if now - lastPopup < POPUP_GAP then
			return
		end
		lastPopup = now
		local n = pending
		pending = 0
		ctx.Hud.popup("+" .. Format.short(math.max(1, math.floor(n + 0.5))), if player:GetAttribute("AutoTrain") then Palette.Gold else nil)
		ctx.Hud.bounce()
		if now - lastSound > SOUND_GAP then
			lastSound = now
			ctx.Sound.play("Tap", { Volume = 0.45, Pitch = 0.95 + math.random() * 0.1 })
		end
	end)
end

return Step
