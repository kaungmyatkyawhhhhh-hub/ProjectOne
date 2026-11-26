--!strict
--[[
	Explore, server side (2026-11-26; shared/Explore has the grid). Every 2 s each player's position (the car's root
	or the character) marks its 512-stud cell; the cells are saved in profile.Activities.explored and sent to the
	player as the attribute "Explored" (the bitset string) and "ExploredPct". The server decides what was visited:
	a client can't claim cells. Teleports and fast travel count too (you were there).
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ExploreGrid = require(Shared:WaitForChild("Explore"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local Explore = {}

local EVERY = 2

function Explore.init()
	local bitsOf: { [Player]: { boolean } } = {}
	Players.PlayerRemoving:Connect(function(player)
		bitsOf[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(EVERY)
			for _, player in Players:GetPlayers() do
				local profile = PlayerData.get(player) :: any
				if not profile or type(profile.Activities) ~= "table" then
					continue
				end
				local bits = bitsOf[player]
				if not bits then
					bits = ExploreGrid.decode(profile.Activities.explored)
					bitsOf[player] = bits
					player:SetAttribute("Explored", ExploreGrid.encode(bits))
					player:SetAttribute("ExploredPct", math.floor(ExploreGrid.count(bits) / ExploreGrid.COUNT * 1000 + 0.5) / 10)
				end
				local focus = player.ReplicationFocus
					or (player.Character and player.Character:FindFirstChild("HumanoidRootPart"))
				if not (focus and focus:IsA("BasePart")) then
					continue
				end
				-- (the menu's focus part flies over the city: only the car or the character counts)
				if focus.Parent and focus.Parent.Name == "StreamFocus" then
					continue
				end
				local p = (focus :: BasePart).Position
				local i = ExploreGrid.cellOf(p.X, p.Z)
				if i and not bits[i + 1] then
					bits[i + 1] = true
					local s = ExploreGrid.encode(bits)
					profile.Activities.explored = s
					player:SetAttribute("Explored", s)
					player:SetAttribute("ExploredPct", math.floor(ExploreGrid.count(bits) / ExploreGrid.COUNT * 1000 + 0.5) / 10)
				end
			end
		end
	end)
end

return Explore
