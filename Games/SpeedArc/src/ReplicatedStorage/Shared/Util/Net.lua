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
	"Collection", -- server -> client: owned shoes / trails / coaches snapshot
	"CoachReveal", -- server -> client: roll results to reveal
	"Moment", -- server -> client: big moments (rank up, go pro...)
	"Retention", -- server -> client: daily / quests / gifts state, gift paid, notices (M4)
	"Tutorial", -- server -> client: tutorial step changed (M4)
	"Social", -- server -> client: friend boost, race requests, profile (M4)
	"Funnel", -- client -> server: client-side funnel steps (menu PLAY)
	"StoreEvent", -- server -> client: bought, Auto Train AFK check (M5)
}
local FUNCTIONS = {
	"Action", -- client -> server: Action:InvokeServer(name, ...) -> ok, result
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
		for _, name in FUNCTIONS do
			if not folder:FindFirstChild(name) then
				local f = Instance.new("RemoteFunction")
				f.Name = name
				f.Parent = folder
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

-- Server: register a handler for Action:InvokeServer(name, ...). Handlers return ok, result.
local handlers = {}
local busy = {}
function Net.on(name, fn)
	handlers[name] = fn
	if not Net._bound then
		Net._bound = true
		Net.get("Action").OnServerInvoke = function(player, action, ...)
			local h = handlers[action]
			if type(action) ~= "string" or not h then
				return false, "unknown"
			end
			if busy[player] then
				return false, "busy" -- one action at a time per player (no double buys)
			end
			busy[player] = true
			local ok, a, b = pcall(h, player, ...)
			busy[player] = nil
			if not ok then
				warn("[Net] action " .. action .. " failed: " .. tostring(a))
				return false, "error"
			end
			return a, b
		end
	end
end

-- Client: call a server action
function Net.call(name, ...)
	return Net.get("Action"):InvokeServer(name, ...)
end

function Net.get(name)
	local f = getFolder()
	return if RunService:IsServer() then f[name] else f:WaitForChild(name)
end

return Net
