-- SessionBoosts (M4): training boosts on top of Boosts.compute: the New Runner boost and the
-- playtime-gift boost (timed, the bigger one counts), Friend Boost and the invite reward (added).
local Shared = game:GetService("ReplicatedStorage").Shared
local Retention = require(Shared.Config.Retention)
local Store = require(Shared.Config.Store)

local SessionBoosts = {}
local friend = {} -- [player] = 0 .. FriendBoostMax

function SessionBoosts.setFriend(player, value)
	friend[player] = value
	player:SetAttribute("FriendBoost", value)
end

function SessionBoosts.friend(player)
	return friend[player] or 0
end

function SessionBoosts.clear(player)
	friend[player] = nil
end

function SessionBoosts.trainMult(player, data)
	local b = data.Boost or {}
	local timed = 1
	if (b.NewRunner or 0) > 0 then
		timed = math.max(timed, Retention.NewRunnerBoost.Mult)
	end
	if (b.Gift or 0) > 0 then
		timed = math.max(timed, Retention.GiftBoostMult)
	end
	-- the 2x SPEED product (M5) stacks on top: you always get what you paid for
	if (b.Speed or 0) > 0 then
		timed *= Store.SpeedBoostMult
	end
	local add = (friend[player] or 0) + (if (b.Invite or 0) > 0 then Retention.Social.InviteBoost else 0)
	return timed * (1 + add)
end

return SessionBoosts
