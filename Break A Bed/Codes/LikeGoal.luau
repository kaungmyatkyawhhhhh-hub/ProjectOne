--!strict
-- Break A Bed: automatic like goal (server). ModuleScript in ServerScriptService.
-- Reads the game's real like count every 5 minutes through RoProxy (a public relay for
-- roblox.com, which games can't call directly). Needs Game Settings -> Security ->
-- "Allow HTTP Requests" ON.
--
-- Usage from the main server script:
--   local LikeGoal = require(ServerScriptService.LikeGoal)
--   LikeGoal.Start(require(ServerScriptService.CodesServer))
-- The board reads ReplicatedStorage.LikeGoal (Likes, Goal, Code attributes) and updates itself.
--
-- Goals go up automatically: when the likes pass a goal, its code switches on and the
-- board moves to the next goal. Add goals + codes below whenever you want.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LikeGoal = {}

LikeGoal.Goals = {
	{ Likes = 1000, Code = "1KLIKES" },
	{ Likes = 2500, Code = "2500LIKES" },
	{ Likes = 5000, Code = "5KLIKES" },
	{ Likes = 10000, Code = "10KLIKES" },
}
LikeGoal.Fallback = 0 -- your last known like count, used if RoProxy can't be reached
local REFRESH = 300 -- seconds

local function fetchLikes(): number?
	local url = ("https://games.roproxy.com/v1/games/votes?universeIds=%d"):format(game.GameId)
	local ok, body = pcall(HttpService.GetAsync, HttpService, url)
	if not ok then return nil end
	local ok2, data = pcall(HttpService.JSONDecode, HttpService, body)
	if not ok2 or type(data) ~= "table" or type(data.data) ~= "table" or not data.data[1] then return nil end
	local up = tonumber(data.data[1].upVotes)
	return up
end

function LikeGoal.Start(Codes: any)
	local state = ReplicatedStorage:FindFirstChild("LikeGoal") or Instance.new("Folder")
	state.Name = "LikeGoal"
	state.Parent = ReplicatedStorage

	local likes = LikeGoal.Fallback
	local function apply()
		local nextGoal = nil
		for _, g in ipairs(LikeGoal.Goals) do
			if likes >= g.Likes then
				local entry = Codes.List[g.Code]
				if entry then entry.Active = true end -- reached: the code works now
			elseif not nextGoal then
				nextGoal = g
			end
		end
		state:SetAttribute("Likes", likes)
		state:SetAttribute("Goal", nextGoal and nextGoal.Likes or 0) -- 0 = all goals reached
		state:SetAttribute("Code", nextGoal and nextGoal.Code or "")
	end

	apply()
	task.spawn(function()
		while true do
			local n = game.GameId ~= 0 and fetchLikes() or nil
			if n and n >= likes then likes = n end
			apply()
			task.wait(REFRESH)
		end
	end)
end

return LikeGoal
