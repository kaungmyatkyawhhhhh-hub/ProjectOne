-- MB_SwimServer: every player IS a shark (custom swim controller, no Humanoid). The server builds the shark model,
-- gives the client network ownership (the client steers it), checks speed + position, and handles DART + evolves.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local CS = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local RunService = game:GetService("RunService")
local MB = RS:WaitForChild("MegaBite")
local C = require(MB:WaitForChild("GameConfig"))
local Remotes = MB:WaitForChild("Remotes")
local Action, Correct = Remotes:WaitForChild("SwimAction"), Remotes:WaitForChild("SwimCorrect")

Players.CharacterAutoLoads = false
pcall(function() PhysicsService:RegisterCollisionGroup("MB_Shark") end)
PhysicsService:CollisionGroupSetCollidable("MB_Shark", "MB_Shark", false)

local folder = workspace:FindFirstChild("MB_Players") or Instance.new("Folder")
folder.Name = "MB_Players"; folder.Parent = workspace

local state = {}   -- plr -> {model, root, last, lastGood, strikes, dartAt}

local function headDir(model)
	local h, t = model:FindFirstChild("Spine0", true), model:FindFirstChild("Spine7", true)
	if h and t then return (h.WorldPosition - t.WorldPosition).Unit end
	return model:GetPivot().LookVector
end

local function build(plr, evoIndex, cf)
	local evo = C.Evolutions[evoIndex]
	local src = MB.Sharks:FindFirstChild(evo.key)
	local model = src:Clone()
	model.Name = plr.Name
	local body = model:FindFirstChildWhichIsA("MeshPart", true)
	model:PivotTo(CFrame.new(0, 500, 0) * (model:GetPivot() - model:GetPivot().Position))
	-- the root faces where the head points, upright
	local fwd = headDir(model)
	local fwdFlat = Vector3.new(fwd.X, 0, fwd.Z).Unit
	local centre = body.CFrame.Position
	local rootCF = CFrame.lookAt(centre, centre + fwdFlat)
	local length = math.max(body.Size.X, body.Size.Y, body.Size.Z)
	local ext = model:GetExtentsSize()
	local height = math.min(ext.Y, length)
	local root = Instance.new("Part")
	root.Name = "SwimRoot"; root.Shape = Enum.PartType.Ball
	root.Size = Vector3.one * math.max(1.6, height * 0.85)
	root.Transparency = 1; root.CanCollide = true; root.CanQuery = false; root.CanTouch = true
	root.CollisionGroup = "MB_Shark"
	root.CustomPhysicalProperties = PhysicalProperties.new(0.3, 0, 0, 1, 1)
	root.CFrame = rootCF
	root.Parent = model
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") and d ~= root then
			d.Anchored = false; d.CanCollide = false; d.CanQuery = false; d.Massless = true; d.CollisionGroup = "MB_Shark"
			local w = Instance.new("WeldConstraint"); w.Part0 = root; w.Part1 = d; w.Parent = root
		end
	end
	root.Anchored = false
	local att = Instance.new("Attachment"); att.Name = "SwimAtt"; att.Parent = root
	local lv = Instance.new("LinearVelocity")
	lv.Name = "SwimVel"; lv.Attachment0 = att; lv.RelativeTo = Enum.ActuatorRelativeTo.World
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector; lv.MaxForce = math.huge; lv.VectorVelocity = Vector3.zero
	lv.Parent = root
	local ao = Instance.new("AlignOrientation")
	ao.Name = "SwimAlign"; ao.Attachment0 = att; ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
	ao.RigidityEnabled = true; ao.CFrame = rootCF.Rotation
	ao.Parent = root
	model.PrimaryPart = root
	model:SetAttribute("Owner", plr.UserId)
	model:SetAttribute("Evo", evoIndex)
	model:SetAttribute("Length", length)
	model:SetAttribute("Height", height)
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model:PivotTo(cf or CFrame.new(C.Map.Spawn))
	CS:AddTag(model, "MBPlayerShark")
	model.Parent = folder
	pcall(function() model:AddPersistentPlayer(plr) end)
	root:SetNetworkOwner(plr)
	return model, root
end

local function spawnShark(plr, evoIndex, cf)
	local st = state[plr] or {}
	state[plr] = st
	local pos = (cf or CFrame.new(C.Map.Spawn)).Position
	pcall(function() plr:RequestStreamAroundAsync(pos, 5) end)   -- streaming-safe spawn
	if st.model then st.model:Destroy() end
	local model, root = build(plr, evoIndex, cf)
	st.model, st.root = model, root
	st.last, st.lastGood, st.strikes, st.dartAt = root.Position, root.CFrame, 0, 0
	plr.Character = model
	plr.ReplicationFocus = root
	plr:SetAttribute("Evo", evoIndex)
end

Players.PlayerAdded:Connect(function(plr)
	plr:SetAttribute("EXP", 0); plr:SetAttribute("Carry", 0); plr:SetAttribute("CarryMax", 30)
	plr:SetAttribute("QuestIndex", 1)
	spawnShark(plr, 1)
end)
Players.PlayerRemoving:Connect(function(plr)
	local st = state[plr]; if st and st.model then st.model:Destroy() end
	state[plr] = nil
end)

-- client actions
Action.OnServerEvent:Connect(function(plr, kind, arg)
	local st = state[plr]; if not st or not st.model then return end
	local now = os.clock()
	if kind == "Dart" then
		if now - st.dartAt < C.Swim.DartCooldown * 0.9 then return end
		st.dartAt = now
		st.model:SetAttribute("DartAt", workspace:GetServerTimeNow())
		st.model:SetAttribute("Invuln", true)
		task.delay(C.Swim.DartInvuln, function() if st.model then st.model:SetAttribute("Invuln", false) end end)
	elseif kind == "Ability" then
		if (plr:GetAttribute("Evo") or 1) < 2 then return end
		if now - (st.abilityAt or 0) < 7.5 then return end
		st.abilityAt = now
		st.model:SetAttribute("AbilityAt", workspace:GetServerTimeNow())
	elseif kind == "Quest" then
		local qi = plr:GetAttribute("QuestIndex") or 1
		local q = C.Quests[qi]; if not q then return end
		if q.target == "vent" then
			local ok = false
			for _, v in ipairs(C.Map.Vents) do if (st.root.Position - v).Magnitude < q.radius + 6 then ok = true end end
			if not ok then return end
		end
		plr:SetAttribute("EXP", (plr:GetAttribute("EXP") or 0) + q.reward)
		plr:SetAttribute("QuestIndex", qi + 1)
	elseif kind == "DevEvo" and RunService:IsStudio() then
		local e = math.clamp((plr:GetAttribute("Evo") or 1) + (arg == -1 and -1 or 1), 1, #C.Evolutions)
		local cf = CFrame.new(st.root.Position + Vector3.new(0, 4, 0)) * st.root.CFrame.Rotation
		spawnShark(plr, e, cf)
	end
end)

-- server checks: speed + position (the client owns the physics, so verify it)
task.spawn(function()
	while true do
		task.wait(C.Server.CheckEvery)
		for plr, st in pairs(state) do
			local root = st.root
			if root and root.Parent then
				local evo = C.Evolutions[plr:GetAttribute("Evo") or 1]
				local pos = root.Position
				local allowed = evo.top * C.Swim.DartMult * C.Server.SpeedSlack * C.Server.CheckEvery + C.Server.SpeedExtra
				local flat = Vector3.new(pos.X, 0, pos.Z) - Vector3.new(C.Swim.MapCentre.X, 0, C.Swim.MapCentre.Z)
				local bad = (pos - st.last).Magnitude > allowed or flat.Magnitude > C.Swim.BorderHard + 40 or pos.Y < -30 or pos.Y > C.Swim.Ceiling + 40
					or pos.X ~= pos.X
				if bad then
					st.strikes += 1
					root:SetNetworkOwner(nil)
					root.AssemblyLinearVelocity = Vector3.zero
					root.CFrame = st.lastGood
					Correct:FireClient(plr, st.lastGood)
					task.delay(0.25, function() if root.Parent then root:SetNetworkOwner(plr) end end)
					st.last = st.lastGood.Position
				else
					st.last = pos
					st.lastGood = root.CFrame
				end
			end
		end
	end
end)
