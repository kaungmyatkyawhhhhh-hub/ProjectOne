-- LockerService: shoes and trails (GDD 11, 13). Buy with coins, owned forever, one of each worn.
-- Also: the collection snapshot each client gets, the boost attributes the HUD reads,
-- and the shoes / trail attached to every character.
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local Shared = game:GetService("ReplicatedStorage").Shared
local Shoes = require(Shared.Config.Shoes)
local Trails = require(Shared.Config.Trails)
local Boosts = require(Shared.Util.Boosts)
local Net = require(Shared.Util.Net)
local PlayerData = require(script.Parent.PlayerData)

local LockerService = {}

local CollectionEvent = Net.get("Collection")

----------------------------------------------------------------------------
-- snapshot + boost attributes
----------------------------------------------------------------------------
function LockerService.snapshot(data)
	return {
		Shoe = data.Shoe,
		OwnedShoes = data.OwnedShoes,
		Trail = data.Trail,
		OwnedTrails = data.OwnedTrails,
		Coaches = data.Coaches,
		EquippedCoaches = data.EquippedCoaches,
		Pity = data.Pity,
		CoachRolls = data.CoachRolls,
		SeenCutscenes = data.SeenCutscenes,
		Slots = Boosts.slotCount(data),
		League = data.League,
		BestLeague = data.BestLeague,
		BestRank = data.BestRank,
		Passes = data.Passes,
	}
end

function LockerService.push(player)
	local data = PlayerData.get(player)
	if not data then
		return
	end
	local b = Boosts.compute(data)
	player:SetAttribute("TrainMult", b.Train)
	player:SetAttribute("PaceMult", b.Pace)
	player:SetAttribute("CoinMult", b.Coins)
	player:SetAttribute("Shoe", data.Shoe)
	player:SetAttribute("Trail", data.Trail)
	CollectionEvent:FireClient(player, LockerService.snapshot(data))
end

----------------------------------------------------------------------------
-- shoes on the feet: the Blender mesh "Shoe_<Id>" from ServerStorage.Meshes if it's there,
-- otherwise a light two-part shoe (sole + upper) per foot in the pair's colours
----------------------------------------------------------------------------
local function clearShoes(char)
	for _, d in char:GetChildren() do
		if d:GetAttribute("SpeedArcShoe") then
			d:Destroy()
		end
	end
end

local function makeShoePart(foot, shoe, side)
	local holder = Instance.new("Model")
	holder.Name = "Shoe_" .. side
	holder:SetAttribute("SpeedArcShoe", true)
	local lib = ServerStorage:FindFirstChild("Meshes")
	local meshModel = lib and lib:FindFirstChild("Shoe_" .. shoe.Id)
	local fs = foot.Size
	local function weld(p, offset)
		p.Anchored = false
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		p.CastShadow = false
		p.CFrame = foot.CFrame * offset
		local w = Instance.new("WeldConstraint")
		w.Part0 = foot
		w.Part1 = p
		w.Parent = p
		p.Parent = holder
	end
	local template = meshModel and (if meshModel:IsA("MeshPart") then meshModel else meshModel:FindFirstChildWhichIsA("MeshPart"))
	if template then
		local m = template:Clone()
		local s = math.max(fs.X / 1.0, 0.6)
		m.Size = template.Size * s
		weld(m, CFrame.new(0, -fs.Y / 2 + m.Size.Y / 2 - 0.05, -0.08))
	else
		local c = shoe.Colors
		local sole = Instance.new("Part")
		sole.Name = "Sole"
		sole.Material = Enum.Material.SmoothPlastic
		sole.Color = Color3.fromHex(c[1])
		sole.Size = Vector3.new(fs.X * 1.12, math.max(0.12, fs.Y * 0.35), fs.Z * 1.25)
		weld(sole, CFrame.new(0, -fs.Y / 2 + sole.Size.Y / 2 - 0.06, -fs.Z * 0.08))
		local upper = Instance.new("Part")
		upper.Name = "Upper"
		upper.Material = Enum.Material.SmoothPlastic
		upper.Color = Color3.fromHex(c[2])
		upper.Size = Vector3.new(fs.X * 1.08, fs.Y * 0.85, fs.Z * 1.12)
		weld(upper, CFrame.new(0, sole.Size.Y * 0.35, -fs.Z * 0.04))
		local stripe = Instance.new("Part")
		stripe.Name = "Stripe"
		stripe.Material = Enum.Material.SmoothPlastic
		stripe.Color = Color3.fromHex(c[3])
		stripe.Size = Vector3.new(fs.X * 1.1, fs.Y * 0.18, fs.Z * 0.5)
		weld(stripe, CFrame.new(0, sole.Size.Y * 0.2, fs.Z * 0.15))
	end
	return holder
end

function LockerService.dressShoes(player)
	local char = player.Character
	local data = PlayerData.get(player)
	if not char or not data then
		return
	end
	clearShoes(char)
	local shoe = Boosts.shoe(data.Shoe)
	if not shoe or shoe.Id == Shoes.Default then
		return -- worn sneakers = the avatar's own feet
	end
	for _, side in { "Left", "Right" } do
		local foot = char:FindFirstChild(side .. "Foot")
		if foot then
			makeShoePart(foot, shoe, side).Parent = char
		end
	end
end

----------------------------------------------------------------------------
-- trail: one Trail between two attachments at the hips + an optional small emitter at the feet.
-- Clients switch it on/off (speed, distance, low graphics) locally.
----------------------------------------------------------------------------
function LockerService.dressTrail(player)
	local char = player.Character
	local data = PlayerData.get(player)
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or not data then
		return
	end
	local old = root:FindFirstChild("SpeedArcTrail")
	if old then
		old:Destroy()
	end
	local t = Boosts.trail(data.Trail) or Boosts.trail(Trails.Default)
	local folder = Instance.new("Folder")
	folder.Name = "SpeedArcTrail"
	folder:SetAttribute("TrailId", t.Id)
	local a0 = Instance.new("Attachment")
	a0.Name = "TrailA"
	a0.Position = Vector3.new(0, -0.6, 0.4)
	a0.Parent = root
	local a1 = Instance.new("Attachment")
	a1.Name = "TrailB"
	a1.Position = Vector3.new(0, -2.4, 0.4)
	a1.Parent = root
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = t.Life
	trail.MinLength = 0.2
	trail.FaceCamera = true
	trail.LightEmission = t.Light or 0
	trail.LightInfluence = 0.3
	local keys = {}
	for i, hex in t.Colors do
		table.insert(keys, ColorSequenceKeypoint.new((i - 1) / math.max(1, #t.Colors - 1), Color3.fromHex(hex)))
	end
	trail.Color = ColorSequence.new(keys)
	trail.Transparency = NumberSequence.new(t.Transparency[1], t.Transparency[2])
	trail.WidthScale = NumberSequence.new(t.Width[1], t.Width[2])
	trail.Enabled = false
	trail.Parent = folder
	if t.Emit then
		local e = t.Emit
		local pe = Instance.new("ParticleEmitter")
		pe.Name = "Emit"
		pe.Texture = e.Texture
		pe.Color = ColorSequence.new(Color3.fromHex(e.Color))
		pe.Rate = e.Rate
		pe.Lifetime = NumberRange.new(e.Life * 0.7, e.Life)
		pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, e.Size), NumberSequenceKeypoint.new(1, e.Size * 0.2) })
		pe.Transparency = NumberSequence.new(0.2, 1)
		pe.Speed = NumberRange.new(0.5, 2)
		pe.SpreadAngle = Vector2.new(40, 40)
		pe.LightEmission = t.Light or 0
		pe.Rotation = NumberRange.new(0, 360)
		pe.RotSpeed = if e.Spin then NumberRange.new(-180, 180) else NumberRange.new(0, 0)
		pe.Enabled = false
		pe.Parent = a1
	end
	-- keep the attachments with the folder so a re-dress cleans everything
	a0:SetAttribute("SpeedArcTrail", true)
	a1:SetAttribute("SpeedArcTrail", true)
	for _, a in root:GetChildren() do
		if a:IsA("Attachment") and a:GetAttribute("SpeedArcTrail") and a ~= a0 and a ~= a1 then
			a:Destroy()
		end
	end
	folder.Parent = root
end

----------------------------------------------------------------------------
-- actions
----------------------------------------------------------------------------
local Toast = Net.get("Toast")

local function buyShoe(player, id)
	local data = PlayerData.get(player)
	local shoe = Boosts.shoe(id)
	if not data or not shoe then
		return false, "missing"
	end
	if data.OwnedShoes[id] then
		return false, "owned"
	end
	if not Boosts.unlocked(data, shoe.Unlock) then
		return false, "locked"
	end
	if data.Coins < shoe.Price then
		return false, "coins"
	end
	PlayerData.set(player, "Coins", data.Coins - shoe.Price)
	data.OwnedShoes[id] = true
	data.Shoe = id
	LockerService.dressShoes(player)
	LockerService.push(player)
	return true
end

local function equipShoe(player, id)
	local data = PlayerData.get(player)
	if not data or not data.OwnedShoes[id] then
		return false, "notowned"
	end
	data.Shoe = id
	LockerService.dressShoes(player)
	LockerService.push(player)
	return true
end

local function buyTrail(player, id)
	local data = PlayerData.get(player)
	local t = Boosts.trail(id)
	if not data or not t then
		return false, "missing"
	end
	if data.OwnedTrails[id] then
		return false, "owned"
	end
	if not t.Price then
		return false, "pass" -- Trail Pack (M5)
	end
	if t.League and (data.BestLeague or 1) < t.League then
		return false, "locked"
	end
	if data.Coins < t.Price then
		return false, "coins"
	end
	PlayerData.set(player, "Coins", data.Coins - t.Price)
	data.OwnedTrails[id] = true
	data.Trail = id
	LockerService.dressTrail(player)
	LockerService.push(player)
	return true
end

local function equipTrail(player, id)
	local data = PlayerData.get(player)
	if not data or not data.OwnedTrails[id] then
		return false, "notowned"
	end
	data.Trail = id
	LockerService.dressTrail(player)
	LockerService.push(player)
	return true
end

function LockerService.start()
	Net.on("BuyShoe", buyShoe)
	Net.on("EquipShoe", equipShoe)
	Net.on("BuyTrail", buyTrail)
	Net.on("EquipTrail", equipTrail)
	Net.on("GetCollection", function(player)
		local data = PlayerData.get(player)
		return data ~= nil, data and LockerService.snapshot(data)
	end)

	local function onCharacter(player, char)
		char:WaitForChild("HumanoidRootPart", 10)
		char:WaitForChild("LeftFoot", 10)
		if player.Parent and PlayerData.get(player) then
			LockerService.dressShoes(player)
			LockerService.dressTrail(player)
		end
	end
	local function onPlayer(player)
		player.CharacterAdded:Connect(function(char)
			onCharacter(player, char)
		end)
		if player.Character then
			task.spawn(onCharacter, player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, p in Players:GetPlayers() do
		onPlayer(p)
	end
	PlayerData.Loaded.Event:Connect(function(player)
		LockerService.push(player)
		if player.Character then
			LockerService.dressShoes(player)
			LockerService.dressTrail(player)
		end
	end)
end

LockerService.Toast = Toast
return LockerService
