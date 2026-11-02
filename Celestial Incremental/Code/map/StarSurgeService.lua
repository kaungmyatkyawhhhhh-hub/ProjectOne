-- GalaxyStarSurgeService (Galaxy Incremental): the server-wide STAR SURGE bar on the plaza (design, section 7: SOCIAL).
--  * every Supernova in the server (a player's Supernovas count going up) fills MapConfig.Surge.PerSupernova %
--  * full = x2 stardust for EVERYONE for Duration seconds, at most once per Cooldown seconds (a full bar waits for the
--    cooldown, then fires); the bar shows who filled it last
--  * the state lives on ReplicatedStorage.Galaxy's attributes (GalaxyEconService reads SurgeUntil for the x2):
--    SurgeFill (0..100), SurgeUntil / SurgeReadyAt (workspace:GetServerTimeNow()), SurgeLast (a display name)
--  * the plaza board's labels (Centre.StarSurge.Screen.Surge) are written here, once a second
-- Studio test: Workspace attribute TestSurge = a number -> the bar set to that % (100 fires it if the cooldown allows).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local MapConfig = require(Galaxy:WaitForChild("MapConfig"))
local SU = MapConfig.Surge

local function now(): number return workspace:GetServerTimeNow() end
Galaxy:SetAttribute("SurgeFill", 0)
Galaxy:SetAttribute("SurgeUntil", 0)
Galaxy:SetAttribute("SurgeReadyAt", 0)
Galaxy:SetAttribute("SurgeLast", "")

local function tryFire()
	if (Galaxy:GetAttribute("SurgeFill") or 0) < 100 then return end
	if now() < (Galaxy:GetAttribute("SurgeReadyAt") or 0) or now() < (Galaxy:GetAttribute("SurgeUntil") or 0) then return end
	Galaxy:SetAttribute("SurgeFill", 0)
	Galaxy:SetAttribute("SurgeUntil", now() + SU.Duration)
	Galaxy:SetAttribute("SurgeReadyAt", now() + SU.Cooldown)
end
local function add(player: Player, supernovas: number)
	Galaxy:SetAttribute("SurgeFill", math.min(100, (Galaxy:GetAttribute("SurgeFill") or 0) + SU.PerSupernova * supernovas))
	Galaxy:SetAttribute("SurgeLast", player.DisplayName)
	tryFire()
end

local function onPlayer(player: Player)
	local last = tonumber(player:GetAttribute("Supernovas")) or 0
	local loaded = player:GetAttribute("Loaded") == true
	player:GetAttributeChangedSignal("Loaded"):Connect(function()
		-- (the save's count arrives with Loaded: that's not a new Supernova)
		last = tonumber(player:GetAttribute("Supernovas")) or 0
		loaded = true
	end)
	player:GetAttributeChangedSignal("Supernovas"):Connect(function()
		local n = tonumber(player:GetAttribute("Supernovas")) or 0
		if loaded and n > last then add(player, n - last) end
		last = n
	end)
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(onPlayer, p) end

local function clock(s: number): string
	s = math.max(0, math.floor(s))
	return string.format("%d:%02d", s // 60, s % 60)
end
-- the board, once a second (real time left, never a fake timer)
task.spawn(function()
	while true do
		task.wait(1)
		tryFire()
		local board = workspace:FindFirstChild("Galaxy")
		board = board and board:FindFirstChild("Centre")
		board = board and board:FindFirstChild("StarSurge")
		local screen = board and board:FindFirstChild("Screen")
		local gui = screen and screen:FindFirstChild("Surge")
		if gui then
			local fill = Galaxy:GetAttribute("SurgeFill") or 0
			local left = (Galaxy:GetAttribute("SurgeUntil") or 0) - now()
			local wait = (Galaxy:GetAttribute("SurgeReadyAt") or 0) - now()
			local bar = gui:FindFirstChild("Bar")
			if left > 0 then
				bar.Fill.Size = UDim2.fromScale(left / SU.Duration, 1)
				bar.Pct.Text = "x" .. SU.Mult .. " STARDUST"
				gui.Status.Text = "x" .. SU.Mult .. " stardust for everyone: " .. clock(left)
			else
				bar.Fill.Size = UDim2.fromScale(fill / 100, 1)
				bar.Pct.Text = math.floor(fill) .. "%"
				gui.Status.Text = if fill >= 100 and wait > 0 then "Full: the next surge in " .. clock(wait)
					else "Every Supernova in the server fills " .. SU.PerSupernova .. "%"
			end
			local who = Galaxy:GetAttribute("SurgeLast") or ""
			gui.Last.Text = if who ~= "" then "LAST: " .. who else ""
		end
	end
end)

if RunService:IsStudio() then
	workspace:GetAttributeChangedSignal("TestSurge"):Connect(function()
		local v = workspace:GetAttribute("TestSurge")
		if type(v) == "number" then
			Galaxy:SetAttribute("SurgeFill", math.clamp(v, 0, 100))
			Galaxy:SetAttribute("SurgeLast", "Tester")
			tryFire()
		end
	end)
end
