-- Remotes in one place. The server creates them, clients wait for them.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Net = {}

local EVENTS = {
	"TrainTap", -- client -> server: one tap while on a station
	"TrainLeave", -- client -> server: STOP / moved
	"TrainState", -- server -> client: station id or nil
	"RaceJoin", -- client -> server
	"RaceBoost", -- client -> server
	"RaceEvent", -- server -> client: joined / start / results / boost
	"Toast", -- server -> client: one line in the toast lane
}
local UNRELIABLE = {
	"RaceTick", -- server -> client: runner progress, 10 times a second
}

local folder

local function getFolder()
	if folder then
		return folder
	end
	if RunService:IsServer() then
		folder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
		folder.Name = "Remotes"
		for _, name in EVENTS do
			if not folder:FindFirstChild(name) then
				local e = Instance.new("RemoteEvent")
				e.Name = name
				e.Parent = folder
			end
		end
		for _, name in UNRELIABLE do
			if not folder:FindFirstChild(name) then
				local e = Instance.new("UnreliableRemoteEvent")
				e.Name = name
				e.Parent = folder
			end
		end
		folder.Parent = ReplicatedStorage
	else
		folder = ReplicatedStorage:WaitForChild("Remotes")
	end
	return folder
end

function Net.get(name)
	local f = getFolder()
	return if RunService:IsServer() then f[name] else f:WaitForChild(name)
end

return Net
