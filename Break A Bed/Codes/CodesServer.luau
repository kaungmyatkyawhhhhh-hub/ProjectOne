--!strict
-- Break A Bed: redeem codes (server). ModuleScript in ServerScriptService.
-- Wire it up once from the main server script:
--   local Codes = require(ServerScriptService.CodesServer)
--   Codes.Init({
--     GetData = function(player) return <the player's loaded save table or nil> end,
--     MarkDirty = function(player) <tell the save system to save this player> end,
--     Grant = function(player, reward) <give the reward, see Reward types below> end,
--     GroupId = <Myanmar Builders Club group id from GameConfig>,
--   })
-- The client calls ReplicatedStorage.Remotes.RedeemCode:InvokeServer(text)
-- and gets back { ok = bool, message = string, reward = table? }.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Codes = {}

-- ===== The codes (keep codes UPPERCASE here; players can type any case) =====
-- Active = false hides a code until you switch it on (for example 1KLIKES at 1,000 likes).
-- Expires = os.time() number, or nil for never.
-- Reward types the game's Grant function must handle:
--   { Type = "Boost", Stat = "Strength" | "Cash", Mult = 2, Minutes = 15 }
--   { Type = "CashBreaks", Breaks = 20 }   -- Cash = 20 breaks of the player's best completed bed
--   { Type = "Spins", Amount = 3 }
--   { Type = "Multi", List = { <rewards> } }
Codes.List = {
	RELEASE = {
		Active = true,
		Reward = { Type = "Boost", Stat = "Strength", Mult = 2, Minutes = 15 },
		Text = "x2 Strength for 15 min!",
	},
	BREAKABED = {
		Active = true,
		Reward = { Type = "CashBreaks", Breaks = 20 },
		Text = "Medium Cash!",
	},
	MYANMAR = {
		Active = true,
		GroupOnly = true,
		Reward = { Type = "Spins", Amount = 3 },
		Text = "+3 Spins!",
	},
	["1KLIKES"] = {
		Active = false, -- turn on when the game reaches 1,000 likes
		Reward = { Type = "Multi", List = {
			{ Type = "CashBreaks", Breaks = 60 },
			{ Type = "Boost", Stat = "Cash", Mult = 2, Minutes = 15 },
		} },
		Text = "Big Cash + x2 Cash 15 min!",
	},
}

local COOLDOWN = 1.5 -- seconds between tries per player (stops spam/guessing)
local MAX_LEN = 24

local cfg: any = nil
local lastTry: { [Player]: number } = {}
local busy: { [Player]: boolean } = {}

local function normalize(text: any): string?
	if typeof(text) ~= "string" then return nil end
	if #text > MAX_LEN * 2 then return nil end
	local s = string.upper((text:gsub("%s+", "")))
	if #s == 0 or #s > MAX_LEN then return nil end
	if not s:match("^[%w]+$") then return nil end
	return s
end

local function inGroup(player: Player): boolean
	if not cfg.GroupId or cfg.GroupId == 0 then return false end
	local ok, result = pcall(function()
		return player:IsInGroupAsync(cfg.GroupId)
	end)
	return ok and result == true
end

local function redeem(player: Player, text: any)
	local now = os.clock()
	if busy[player] or (lastTry[player] and now - lastTry[player] < COOLDOWN) then
		return { ok = false, message = "Slow down!" }
	end
	lastTry[player] = now

	local code = normalize(text)
	local entry = code and Codes.List[code]
	if not entry or not entry.Active or (entry.Expires and os.time() > entry.Expires) then
		return { ok = false, message = "Invalid code" }
	end

	local data = cfg.GetData(player)
	if not data then
		return { ok = false, message = "Still loading, try again!" }
	end
	data.RedeemedCodes = data.RedeemedCodes or {}
	if data.RedeemedCodes[code] then
		return { ok = false, message = "Already redeemed!" }
	end

	busy[player] = true
	local result
	if entry.GroupOnly and not inGroup(player) then
		result = { ok = false, message = "Join the group to use this code!" }
	else
		-- Mark first, then grant: a crash in Grant can never let a code be used twice.
		data.RedeemedCodes[code] = os.time()
		local ok, err = pcall(cfg.Grant, player, entry.Reward)
		if ok then
			cfg.MarkDirty(player)
			result = { ok = true, message = entry.Text, reward = entry.Reward }
		else
			data.RedeemedCodes[code] = nil
			warn("[Codes] Grant failed for", player.Name, code, err)
			result = { ok = false, message = "Something went wrong, try again!" }
		end
	end
	busy[player] = nil
	return result
end

function Codes.Init(config)
	assert(config.GetData and config.MarkDirty and config.Grant, "CodesServer.Init needs GetData, MarkDirty and Grant")
	cfg = config

	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotes"
		remotes.Parent = ReplicatedStorage
	end
	local rf = remotes:FindFirstChild("RedeemCode") :: RemoteFunction?
	if not rf then
		rf = Instance.new("RemoteFunction")
		rf.Name = "RedeemCode"
		rf.Parent = remotes
	end
	(rf :: RemoteFunction).OnServerInvoke = redeem

	Players.PlayerRemoving:Connect(function(p)
		lastTry[p] = nil
		busy[p] = nil
	end)
end

return Codes
