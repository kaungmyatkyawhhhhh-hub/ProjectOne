-- MB_LandmarkServer (13 Nov, WORLD v2). Owner: "put treasure chests at the landmarks / monuments that reward greatly to its
-- chance of finding landmarks".
--  * DISCOVERY: the first time a player comes within reach of a landmark (its pad + Chest.FindRadius) it is added to the
--    saved list "Found" and pays the discovery bonus.
--  * CHESTS: one chest model per landmark in workspace.MB_Map.Chests (attribute Landmark = id). The client asks to open it
--    when the shark's mouth touches it; the server checks the reach and the refill time (saved, per player) and pays.
--  * Reward = share x the EXP span of the player's evolution (GameConfig.World.Landmarks[i].share), x Fossilize / x2 EXP pass.
-- The lid opening, glow and sounds are the client's (MB_WorldMap).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local MB = RS:WaitForChild("MegaBite")
local C = require(MB:WaitForChild("GameConfig"))
local WD = C.World
local CH = WD.Chest
local Health = require(script.Parent:WaitForChild("MB_Health"))
local Remotes = MB:WaitForChild("Remotes")
local Fx = Remotes:WaitForChild("Fx")
local ChestOpen = Remotes:FindFirstChild("ChestOpen")
if not ChestOpen then ChestOpen = Instance.new("RemoteEvent"); ChestOpen.Name = "ChestOpen"; ChestOpen.Parent = Remotes end

local map = workspace:WaitForChild("MB_Map")
local sites = {}   -- id -> {L, pos (landmark), chest (Vector3 or nil)}
for _, L in ipairs(WD.Landmarks) do
	local model = map:FindFirstChild("Landmarks") and map.Landmarks:FindFirstChild(L.id)
	if model then   -- only landmarks that are really in the map
		local chest = map:FindFirstChild("Chests") and map.Chests:FindFirstChild(L.id)
		sites[L.id] = {L = L, pos = Vector3.new(L.pos.X, 0, L.pos.Z), chest = chest and chest:GetPivot().Position or nil}
	end
end
local function span(evo)
	local E = C.Evolutions
	evo = math.clamp(evo, 1, #E)
	if E[evo + 1] then return E[evo + 1].exp - E[evo].exp end
	return E[evo].exp - E[evo - 1].exp
end
local function reward(plr, L)
	return math.max(CH.MinReward, span(plr:GetAttribute("Evo") or 1) * (L.share or 0.08)) * Health.expMult(plr)
end
local function list(s) local t = {}; for id in string.gmatch(s or "", "[^,]+") do t[id] = true end; return t end
local function chestTimes(plr)
	local s = plr:GetAttribute("ChestAt")
	if s and s ~= "" then local ok, t = pcall(function() return HttpService:JSONDecode(s) end); if ok and type(t) == "table" then return t end end
	return {}
end

-- discovery
task.spawn(function()
	while true do
		task.wait(0.5)
		for _, plr in ipairs(Players:GetPlayers()) do
			local m = plr.Character; local root = m and m.PrimaryPart
			if root and plr:GetAttribute("Loaded") then
				local p = Vector3.new(root.Position.X, 0, root.Position.Z)
				for id, s in pairs(sites) do
					if (p - s.pos).Magnitude < (s.L.pad or 90) + CH.FindRadius then
						local found = list(plr:GetAttribute("Found"))
						if not found[id] then
							local cur = plr:GetAttribute("Found") or ""
							plr:SetAttribute("Found", cur == "" and id or (cur .. "," .. id))
							local got = Health.addExp(plr, reward(plr, s.L))
							local n = 0; for _ in pairs(list(plr:GetAttribute("Found"))) do n += 1 end
							Fx:FireClient(plr, "Discover", id, s.L.name, got, n, #WD.Landmarks)
						end
					end
				end
			end
		end
	end
end)

-- chests
local lastTry = {}
ChestOpen.OnServerEvent:Connect(function(plr, id)
	local s = type(id) == "string" and sites[id]
	if not s or not s.chest then return end
	local now = os.clock()
	if now - (lastTry[plr] or 0) < 0.4 then return end
	lastTry[plr] = now
	local m = plr.Character; local root = m and m.PrimaryPart
	if not root or m:GetAttribute("Caught") then return end
	local L = m:GetAttribute("Length") or 7
	local mouth = root.Position + root.CFrame.LookVector * L * 0.45
	local d = math.min((mouth - s.chest).Magnitude, (root.Position - s.chest).Magnitude)
	if d > CH.Reach + L * 0.3 + 8 then return end
	local times = chestTimes(plr)
	local t = os.time()
	if (times[id] or 0) > t then return end
	times[id] = t + CH.Refill
	plr:SetAttribute("ChestAt", HttpService:JSONEncode(times))
	plr:SetAttribute("Chests", (plr:GetAttribute("Chests") or 0) + 1)
	local got = Health.addExp(plr, reward(plr, s.L))
	Fx:FireClient(plr, "ChestOpened", id, got, CH.Refill)
	Fx:FireAllClients("ChestFx", id, plr.UserId)
end)
Players.PlayerRemoving:Connect(function(p) lastTry[p] = nil end)
