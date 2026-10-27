-- CoachService: roll coaches with coins (odds + pity), evolve with 3 duplicates, 2 free slots,
-- BEST EQUIP, and the first equipped coach follows you (GDD 12). Server decides every roll.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local Coaches = require(Shared.Config.Coaches)
local Palette = require(Shared.Config.Palette)
local Boosts = require(Shared.Util.Boosts)
local Formulas = require(Shared.Util.Formulas)
local Net = require(Shared.Util.Net)
local PlayerData = require(script.Parent.PlayerData)
local LockerService = require(script.Parent.LockerService)

local CoachService = {}

local IS_STUDIO = RunService:IsStudio()
local rng = Random.new()
local Reveal = Net.get("CoachReveal")

local function rarityIndex(r)
	return table.find(Coaches.Rarities, r) or 1
end

function CoachService.rollPrice(data)
	return math.max(Coaches.RollMinPrice, Formulas.minutesOfCoins(Coaches.RollMinutes, data.League))
end

-- one draw, honouring pity
local function draw(data)
	local minIdx = 1
	local forced = nil
	for _, p in Coaches.Pity do
		data.Pity[p.Rarity] = (data.Pity[p.Rarity] or 0) + 1
		if data.Pity[p.Rarity] >= p.Rolls and rarityIndex(p.Rarity) > minIdx then
			minIdx = rarityIndex(p.Rarity)
			forced = p.Rarity
		end
	end
	local pool, total = {}, 0
	for _, c in Coaches.List do
		if rarityIndex(c.Rarity) >= minIdx then
			table.insert(pool, c)
			total += c.Chance
		end
	end
	local roll = rng:NextNumber() * total
	local pick = pool[#pool]
	for _, c in pool do
		roll -= c.Chance
		if roll <= 0 then
			pick = c
			break
		end
	end
	local got = rarityIndex(pick.Rarity)
	for _, p in Coaches.Pity do
		if got >= rarityIndex(p.Rarity) then
			data.Pity[p.Rarity] = 0
		end
	end
	return pick, forced
end

local function addCoach(data, id, stage)
	local entry = { Uid = data.NextCoachUid, Id = id, Stage = stage or 1 }
	data.NextCoachUid += 1
	table.insert(data.Coaches, entry)
	if #data.EquippedCoaches < Boosts.slotCount(data) then
		table.insert(data.EquippedCoaches, entry.Uid)
	end
	return entry
end

local function findEntry(data, uid)
	for i, e in data.Coaches do
		if e.Uid == uid then
			return e, i
		end
	end
	return nil
end

----------------------------------------------------------------------------
-- follower (the first equipped coach walks behind you)
----------------------------------------------------------------------------
local followers = {} -- [player] = { model, hum, root, entryUid, track }
local WALK_ANIM = "rbxassetid://913402848"

local function propParts(model, coach, stage)
	local function add(name, size, color, attachTo, offset, shape, material)
		local part = model:FindFirstChild(attachTo)
		if not part then
			return
		end
		local p = Instance.new("Part")
		p.Name = name
		p.Size = size
		p.Color = color
		p.Material = material or Enum.Material.SmoothPlastic
		if shape then
			p.Shape = shape
		end
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		p.CastShadow = false
		p.CFrame = part.CFrame * offset
		local w = Instance.new("WeldConstraint")
		w.Part0 = part
		w.Part1 = p
		w.Parent = p
		p.Parent = model
	end
	local prop = coach.Prop
	if prop == "Whistle" then
		add("Lanyard", Vector3.new(0.9, 0.08, 0.6), Palette.ElectricBlue, "UpperTorso", CFrame.new(0, 0.55, -0.1))
		add("Whistle", Vector3.new(0.25, 0.18, 0.35), Palette.Gold, "UpperTorso", CFrame.new(0.15, 0.1, -0.55))
	elseif prop == "Headband" then
		add("Headband", Vector3.new(0.3, 1.25, 1.25), Palette.White, "Head", CFrame.new(0, 0.25, 0) * CFrame.Angles(0, 0, math.pi / 2), Enum.PartType.Cylinder)
	elseif prop == "Stopwatch" then
		add("Stopwatch", Vector3.new(0.12, 0.5, 0.5), Palette.Gold, "RightHand", CFrame.new(0, -0.2, -0.2) * CFrame.Angles(0, math.pi / 2, 0), Enum.PartType.Cylinder)
		add("Clipboard", Vector3.new(0.08, 1.0, 0.8), Color3.fromHex("#B9824F"), "LeftHand", CFrame.new(0, -0.3, -0.2))
	elseif prop == "Braid" then
		add("Braid", Vector3.new(0.35, 1.1, 0.35), Color3.fromHex(coach.Look.Hair), "Head", CFrame.new(0, -0.3, 0.6) * CFrame.Angles(math.rad(20), 0, 0))
	elseif prop == "Wind" then
		add("WindBand", Vector3.new(0.2, 1.5, 1.5), Palette.BrightBlue, "UpperTorso", CFrame.new(0, 0.2, 0) * CFrame.Angles(0, 0, math.pi / 2), Enum.PartType.Cylinder, Enum.Material.Neon)
	elseif prop == "PocketWatch" then
		add("Watch", Vector3.new(0.1, 0.4, 0.4), Palette.Gold, "LowerTorso", CFrame.new(0.5, 0.1, -0.4) * CFrame.Angles(0, math.pi / 2, 0), Enum.PartType.Cylinder)
		add("Cap", Vector3.new(1.25, 0.25, 1.35), Color3.fromHex("#2A2F3A"), "Head", CFrame.new(0, 0.55, -0.1))
	elseif prop == "Wings" then
		for _, s in { -1, 1 } do
			add("Wing", Vector3.new(0.12, 0.5, 0.9), Palette.Gold, s < 0 and "LeftFoot" or "RightFoot", CFrame.new(s * 0.45, 0.2, 0.3) * CFrame.Angles(0, 0, s * 0.4), nil, Enum.Material.Neon)
		end
	end
	-- evolved coaches get a coloured aura ring at their feet
	if stage >= 2 then
		local ringColors = { nil, Palette.BrightBlue, Palette.Gold, Palette.White }
		add("Aura", Vector3.new(0.15, 4, 4), ringColors[stage], "HumanoidRootPart", CFrame.new(0, -2.9, 0) * CFrame.Angles(0, 0, math.pi / 2), Enum.PartType.Cylinder, Enum.Material.Neon)
		local aura = model:FindFirstChild("Aura")
		if aura then
			aura.Transparency = 0.55
		end
	end
end

local function buildCoachModel(coach, stage)
	local look = coach.Look
	local desc = Instance.new("HumanoidDescription")
	local skin = Color3.fromHex(look.Skin)
	desc.HeadColor = skin
	desc.LeftArmColor = skin
	desc.RightArmColor = skin
	desc.TorsoColor = Color3.fromHex(look.Top)
	desc.LeftLegColor = Color3.fromHex(look.Bottom)
	desc.RightLegColor = Color3.fromHex(look.Bottom)
	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
	end)
	if not ok then
		warn("[CoachService] coach model failed", model)
		return nil
	end
	model.Name = "Coach_" .. coach.Id
	local animate = model:FindFirstChild("Animate")
	if animate then
		animate:Destroy()
	end
	local hum = model:FindFirstChildOfClass("Humanoid")
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
	for _, p in model:GetDescendants() do
		if p:IsA("BasePart") then
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.CastShadow = false
		end
	end
	propParts(model, coach, stage)
	local head = model:FindFirstChild("Head")
	if head then
		local tag = Instance.new("BillboardGui")
		tag.Name = "NameTag"
		tag.Size = UDim2.fromOffset(140, 34)
		tag.StudsOffset = Vector3.new(0, 2.4, 0)
		tag.MaxDistance = 60
		local name = Instance.new("TextLabel")
		name.BackgroundTransparency = 1
		name.Size = UDim2.fromScale(1, 0.6)
		name.FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy, Enum.FontStyle.Italic)
		name.TextScaled = true
		name.Text = string.upper(coach.Name)
		name.TextColor3 = Coaches.RarityColors[coach.Rarity]
		local s = Instance.new("UIStroke")
		s.Thickness = 2
		s.Color = Palette.SpeedBlack
		s.Parent = name
		name.Parent = tag
		local st = name:Clone()
		st.Position = UDim2.fromScale(0, 0.6)
		st.Size = UDim2.fromScale(1, 0.4)
		st.Text = Coaches.Stages[stage]
		st.TextColor3 = Palette.White
		st.Parent = tag
		tag.Parent = head
	end
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	return model
end

local function removeFollower(player)
	local f = followers[player]
	if f then
		f.model:Destroy()
		followers[player] = nil
	end
end

function CoachService.refreshFollower(player)
	local data = PlayerData.get(player)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local uid = data and data.EquippedCoaches[1]
	local entry = uid and findEntry(data, uid)
	local f = followers[player]
	if f and (not entry or f.entryUid ~= uid or f.stage ~= entry.Stage) then
		removeFollower(player)
		f = nil
	end
	if not entry or not root or f then
		return
	end
	local coach = Boosts.coach(entry.Id)
	local model = coach and buildCoachModel(coach, entry.Stage)
	if not model then
		return
	end
	local mroot = model:FindFirstChild("HumanoidRootPart")
	model:PivotTo(root.CFrame * CFrame.new(3, 0, 4))
	model.Parent = workspace:FindFirstChild("Runtime") or workspace
	pcall(function()
		mroot:SetNetworkOwner(player) -- the owner's machine moves it smoothly
	end)
	local hum = model:FindFirstChildOfClass("Humanoid")
	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
	local anim = Instance.new("Animation")
	anim.AnimationId = WALK_ANIM
	local track = animator:LoadAnimation(anim)
	track.Looped = true
	followers[player] = { model = model, hum = hum, root = mroot, entryUid = uid, stage = entry.Stage, track = track }
end

-- a cheap follow step for every follower, 4 times a second
local function stepFollowers()
	for player, f in followers do
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not player.Parent or not root or not f.root.Parent then
			removeFollower(player)
			continue
		end
		local inRace = player:GetAttribute("InRace") == true
		if inRace then
			if f.model.Parent ~= nil then
				f.model.Parent = nil
			end
			continue
		elseif f.model.Parent == nil then
			f.model.Parent = workspace:FindFirstChild("Runtime") or workspace
			f.model:PivotTo(root.CFrame * CFrame.new(3, 0, 4))
		end
		local target = (root.CFrame * CFrame.new(3, 0, 4.5)).Position
		local dist = (f.root.Position - target).Magnitude
		if dist > 45 then
			f.model:PivotTo(CFrame.new(target, target + root.CFrame.LookVector))
		elseif dist > 1.5 then
			local hum = char:FindFirstChildOfClass("Humanoid")
			f.hum.WalkSpeed = (hum and hum.WalkSpeed or 16) + (if dist > 10 then 6 else 1)
			f.hum:MoveTo(target)
		end
		local moving = dist > 1.6
		if moving and not f.track.IsPlaying then
			f.track:Play(0.2)
		elseif not moving and f.track.IsPlaying then
			f.track:Stop(0.3)
		end
		if f.track.IsPlaying then
			f.track:AdjustSpeed(math.clamp(f.hum.WalkSpeed / 16, 0.8, 1.8))
		end
	end
end

----------------------------------------------------------------------------
-- actions
----------------------------------------------------------------------------
local function changed(player)
	LockerService.push(player)
	CoachService.refreshFollower(player)
end

local function roll(player)
	local data = PlayerData.get(player)
	if not data then
		return false, "missing"
	end
	local price = CoachService.rollPrice(data)
	if data.Coins < price then
		return false, "coins"
	end
	PlayerData.set(player, "Coins", data.Coins - price)
	local pick, forced = draw(data)
	data.CoachRolls += 1
	local entry = addCoach(data, pick.Id, 1)
	local firstCutscene = pick.Cutscene ~= nil and not data.SeenCutscenes[pick.Id]
	if pick.Cutscene then
		data.SeenCutscenes[pick.Id] = true
	end
	changed(player)
	return true, { Id = pick.Id, Uid = entry.Uid, Rarity = pick.Rarity, Forced = forced, FirstCutscene = firstCutscene, Price = price }
end

local function equip(player, uid)
	local data = PlayerData.get(player)
	if not data or not findEntry(data, uid) then
		return false, "missing"
	end
	local i = table.find(data.EquippedCoaches, uid)
	if i then
		table.remove(data.EquippedCoaches, i) -- tap again = unequip
	else
		if #data.EquippedCoaches >= Boosts.slotCount(data) then
			return false, "slots"
		end
		table.insert(data.EquippedCoaches, uid)
	end
	changed(player)
	return true
end

local function score(e)
	local t, p, c = Boosts.coachValues(e.Id, e.Stage)
	return t + p * 6 + c * 0.8
end

local function bestEquip(player)
	local data = PlayerData.get(player)
	if not data then
		return false
	end
	local list = table.clone(data.Coaches)
	table.sort(list, function(a, b)
		return score(a) > score(b)
	end)
	table.clear(data.EquippedCoaches)
	for i = 1, math.min(#list, Boosts.slotCount(data)) do
		table.insert(data.EquippedCoaches, list[i].Uid)
	end
	changed(player)
	return true
end

local function evolve(player, coachId, stage)
	local data = PlayerData.get(player)
	if not data or not Boosts.coach(coachId) or type(stage) ~= "number" or stage >= #Coaches.Stages then
		return false, "missing"
	end
	local same = {}
	for _, e in data.Coaches do
		if e.Id == coachId and e.Stage == stage then
			table.insert(same, e)
		end
	end
	if #same < Coaches.EvolveCost then
		return false, "need"
	end
	-- use unequipped copies first
	table.sort(same, function(a, b)
		local ea, eb = table.find(data.EquippedCoaches, a.Uid) ~= nil, table.find(data.EquippedCoaches, b.Uid) ~= nil
		return (not ea) and eb
	end)
	local slot = nil
	for i = 1, Coaches.EvolveCost do
		local e = same[i]
		local ei = table.find(data.EquippedCoaches, e.Uid)
		if ei then
			slot = slot or ei
			table.remove(data.EquippedCoaches, ei)
		end
		local _, idx = findEntry(data, e.Uid)
		table.remove(data.Coaches, idx)
	end
	local new = { Uid = data.NextCoachUid, Id = coachId, Stage = stage + 1 }
	data.NextCoachUid += 1
	table.insert(data.Coaches, new)
	if slot then
		table.insert(data.EquippedCoaches, math.min(slot, #data.EquippedCoaches + 1), new.Uid)
	end
	changed(player)
	return true, { Id = coachId, Stage = stage + 1, Uid = new.Uid }
end

-- Studio admin: give coaches (to test evolve). Workspace attribute TestGiveCoach = "Benji,3"
local function adminGive(text)
	local id, n = string.match(text, "^(%w+),?(%d*)$")
	n = tonumber(n) or 1
	for _, player in Players:GetPlayers() do
		local data = PlayerData.get(player)
		if data and Boosts.coach(id) then
			for _ = 1, n do
				addCoach(data, id, 1)
			end
			changed(player)
		end
	end
end

function CoachService.start()
	Net.on("RollCoach", roll)
	Net.on("EquipCoach", equip)
	Net.on("BestEquip", bestEquip)
	Net.on("EvolveCoach", evolve)
	Net.on("RollPrice", function(player)
		local data = PlayerData.get(player)
		return data ~= nil, data and CoachService.rollPrice(data)
	end)

	if IS_STUDIO then
		workspace:GetAttributeChangedSignal("TestGiveCoach"):Connect(function()
			local v = workspace:GetAttribute("TestGiveCoach")
			if type(v) == "string" and v ~= "" then
				adminGive(v)
				workspace:SetAttribute("TestGiveCoach", "")
			end
		end)
	end

	Players.PlayerRemoving:Connect(removeFollower)
	local function onPlayer(player)
		player.CharacterAdded:Connect(function()
			task.wait(1)
			if player.Parent then
				removeFollower(player)
				CoachService.refreshFollower(player)
			end
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, p in Players:GetPlayers() do
		onPlayer(p)
	end
	PlayerData.Loaded.Event:Connect(function(player)
		task.wait(1)
		CoachService.refreshFollower(player)
	end)
	task.spawn(function()
		while true do
			task.wait(0.25)
			stepFollowers()
		end
	end)
end

return CoachService
