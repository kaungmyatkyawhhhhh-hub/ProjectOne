--!nocheck
-- retro_highlight.luau (roblox-game-lighting skill)
-- The "retro / Block Tales" look from the Develuper lighting video: an outline Highlight on every player character
-- that does NOT show through walls (DepthMode Occluded). Client-side, so it costs the server nothing.
--
-- Install: a LocalScript named "RetroOutline" in StarterPlayer.StarterPlayerScripts with this source.
-- With the Studio MCP (Edit datamodel), create it like this:
--   local s = Instance.new("LocalScript"); s.Name = "RetroOutline"; s.Source = <this file's text>
--   s.Parent = game.StarterPlayer.StarterPlayerScripts
--
-- Roblox renders at most 31 Highlights at once per client. CAP keeps the nearest characters outlined.

local OUTLINE_COLOR = Color3.fromRGB(20, 20, 30)
local OUTLINE_TRANSPARENCY = 0
local FILL_TRANSPARENCY = 1   -- 1 = outline only (retro); 0.8 = a light tint too
local INCLUDE_LOCAL = true    -- outline your own character as well
local CAP = 28                -- leave a few of the 31 for game Highlights (pickups, targets)
local NAME = "RetroOutline"

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer

local function make(character)
	local h = character:FindFirstChild(NAME)
	if not h then
		h = Instance.new("Highlight")
		h.Name = NAME
		h.DepthMode = Enum.HighlightDepthMode.Occluded
		h.FillTransparency = FILL_TRANSPARENCY
		h.OutlineTransparency = OUTLINE_TRANSPARENCY
		h.OutlineColor = OUTLINE_COLOR
		h.Parent = character
	end
	return h
end

local function hook(player)
	if player == localPlayer and not INCLUDE_LOCAL then return end
	if player.Character then make(player.Character) end
	player.CharacterAdded:Connect(make)
end
for _, p in Players:GetPlayers() do hook(p) end
Players.PlayerAdded:Connect(hook)

-- keep only the nearest CAP outlines on (checked twice a second, not every frame)
local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < 0.5 then return end
	acc = 0
	local cam = workspace.CurrentCamera
	if not cam then return end
	local list = {}
	for _, p in Players:GetPlayers() do
		local c = p.Character
		local h = c and c:FindFirstChild(NAME)
		local root = c and c:FindFirstChild("HumanoidRootPart")
		if h and root then
			table.insert(list, {h = h, d = (root.Position - cam.CFrame.Position).Magnitude})
		end
	end
	if #list <= CAP then
		for _, e in list do e.h.Enabled = true end
		return
	end
	table.sort(list, function(a, b) return a.d < b.d end)
	for i, e in list do e.h.Enabled = i <= CAP end
end)
