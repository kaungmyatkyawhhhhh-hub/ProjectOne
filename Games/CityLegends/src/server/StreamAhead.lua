--!strict
--[[
	StreamAhead (2026-11-26, owner: "when u go fast, the next map chunk takes long to load and u just fall off the map")
	Streaming only promises StreamingMinRadius (64 studs) round a player's ReplicationFocus: at 200 studs/s that's
	0.3 s of road. Each driver gets two extra replication foci ahead of the car along its velocity (0.6 s and 1.4 s
	of travel), so the road ahead streams in at the top priority before the car gets there. Slow or on foot: the
	foci sit on the focus itself (no extra area to stream). Client side, Driving's safety floor catches what's left.
	Vault: City Legends/2026-11-26 Streaming ahead - no more falling off the map.md
]]
local Players = game:GetService("Players")

local StreamAhead = {}

local LEADS = { 0.6, 1.4 } -- seconds of travel ahead of the car
local MAX_AHEAD = 420 -- studs (a teleport's jump in velocity can't throw a focus across the map)
local MIN_SPEED = 45 -- studs/s: slower than this the normal 64-stud bubble keeps up
local EVERY = 0.2

local folder: Folder

local function partsFor(player: Player): { BasePart }
	local list = {}
	for i = 1, #LEADS do
		local p = Instance.new("Part")
		p.Name = player.Name .. "_ahead" .. i
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Transparency = 1
		p.Size = Vector3.one
		p.Parent = folder
		list[i] = p
	end
	return list
end

function StreamAhead.init()
	folder = Instance.new("Folder")
	folder.Name = "StreamAhead"
	folder.Parent = workspace
	local foci: { [Player]: { BasePart } } = {}
	local added: { [Player]: boolean } = {}
	Players.PlayerRemoving:Connect(function(player)
		for _, p in foci[player] or {} do
			p:Destroy()
		end
		foci[player] = nil
		added[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(EVERY)
			for _, player in Players:GetPlayers() do
				-- (on foot the focus is nil = the character: the foci must follow it, not stay where the car was)
				local focus: Instance? = player.ReplicationFocus
					or (player.Character and player.Character:FindFirstChild("HumanoidRootPart"))
				if not (focus and focus:IsA("BasePart") and focus.Parent) then
					continue
				end
				local parts = foci[player]
				if not parts then
					parts = partsFor(player)
					foci[player] = parts
				end
				local at = (focus :: BasePart).Position
				local v = (focus :: BasePart).AssemblyLinearVelocity
				local flat = Vector3.new(v.X, 0, v.Z)
				local speed = flat.Magnitude
				for i, p in parts do
					local ahead = if speed > MIN_SPEED then flat * math.min(LEADS[i], MAX_AHEAD / speed) else Vector3.zero
					p.Position = at + ahead
				end
				if not added[player] then
					added[player] = true
					for _, p in parts do
						pcall(player.AddReplicationFocus, player, p)
					end
				end
			end
		end
	end)
end

return StreamAhead
