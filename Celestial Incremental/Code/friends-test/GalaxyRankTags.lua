-- GalaxyRankTags (Galaxy Incremental, alpha part 1, 3 Nov): every player's RANK over their head (design section 7: "rank
-- over the head"; MapConfig.Ranks: SPARK at Supernova 1, ...), in the rank's colour, from the first Supernova on (a new
-- player has none: the island plate already says NEW STAR). Everyone sees everyone's.
-- shared.GalaxyRankLand(): YOUR tag drops in from above with a bounce and sparkles (the Supernova cinematic calls it).
-- RANK AURA (Phase 1 social, 5 Nov; #290): a light sparkle aura round every player by the rank TIER (the Cosmic Level's band:
-- 1 SPARK .. 7 QUASAR), tinted with the band colour, our own fx_sparkle texture. Tiers 1-2: none; 3-5: faint; 6-7: brighter
-- and the sparkles ORBIT you (the emitter rides an attachment circling the body, so they leave a ring of stars). ONE
-- emitter a player; off past 60 studs; low graphics (quality 1-3) = fewer and no orbit; Reduced Motion = no orbit.
-- Studio tests: Workspace TestAuraLevel = n draws every player's aura as Cosmic Level n; models put in Workspace.AuraTestRigs
-- get the aura of their CosmicLevel attribute (the FPS test with 8 rigs).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local MapConfig = require(Galaxy:WaitForChild("MapConfig"))
local Kit = require(Galaxy:WaitForChild("UIKit"))

local RunService = game:GetService("RunService")
local REST = Vector3.new(0, 2.4, 0)
local tags = {} -- [Player] = BillboardGui

-- (feel pass, 5 Nov: the rank = the COSMIC LEVEL's name + the Supernovas, "FLARE III · ✦12", for everyone from the start;
-- the colour = the level's band)
local Econ = require(Galaxy:WaitForChild("EconConfig"))
local function build(p: Player)
	if tags[p] then tags[p]:Destroy() tags[p] = nil end
	local char = p.Character
	local head = char and char:FindFirstChild("Head")
	local text = p:GetAttribute("Rank")
	if not head or type(text) ~= "string" or text == "" then return end
	local def = { name = text, colour = Econ.LevelBand(tonumber(p:GetAttribute("CosmicLevel")) or 1).colour }
	local _ = MapConfig
	local bb = Instance.new("BillboardGui")
	bb.Name = "Rank_" .. p.Name
	bb.Adornee = head
	bb.Size = UDim2.fromScale(5.2, 0.8) -- (studs: the name + the Supernovas; smaller than before: it shows from the start now)
	bb.StudsOffsetWorldSpace = REST
	bb.LightInfluence = 0
	bb.MaxDistance = 90
	bb.ResetOnSpawn = false
	bb.Parent = playerGui
	-- (the ✦ is our sparkle image: the font has no ✦, Kit.rankLine)
	local labels = Kit.rankLine(bb, def.name, Kit.FONT_HEAVY)
	for _, l in ipairs(labels) do
		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new(def.colour:Lerp(Color3.new(1, 1, 1), 0.6), def.colour)
		g.Rotation = 90
		g.Parent = l
		local st = Instance.new("UIStroke")
		st.Color = Color3.fromRGB(26, 16, 40)
		st.Thickness = 2.5
		st.Parent = l
	end
	tags[p] = bb
end

------------------------------------------------------------------------ rank aura (#290)
local A = require(Galaxy:WaitForChild("UIAssets"))
local AURA_FAR = 60
-- per tier: rate, alpha (0 = solid), size, brightness, orbit
local AURA = {
	[3] = { rate = 6, alpha = 0.4, size = 0.5, bright = 1.2, orbit = false },
	[4] = { rate = 8, alpha = 0.35, size = 0.55, bright = 1.4, orbit = false },
	[5] = { rate = 10, alpha = 0.3, size = 0.6, bright = 1.6, orbit = false },
	[6] = { rate = 22, alpha = 0.15, size = 0.55, bright = 1.8, orbit = true },
	[7] = { rate = 28, alpha = 0.1, size = 0.6, bright = 2, orbit = true },
}
local auras = {} -- [Model] = { att, em, def, root, phase }
local function lowGraphics(): boolean
	local q = UserSettings().GameSettings.SavedQualityLevel.Value -- (0 = automatic)
	return q >= 1 and q <= 3
end
local function auraOff(model)
	local a = auras[model]
	if a then a.att:Destroy() auras[model] = nil end
end
local function auraOn(model: Model, level: number)
	local band = math.clamp((level - 1) // 9 + 1, 1, #Econ.LevelBands)
	local def = AURA[band]
	local root = model:FindFirstChild("HumanoidRootPart")
	if not def or not root or not root:IsA("BasePart") then auraOff(model) return end
	local a = auras[model]
	if a and a.band == band and a.root == root then return end
	auraOff(model)
	local colour = Econ.LevelBands[band].colour
	local att = Instance.new("Attachment")
	att.Name = "RankAura"
	local em = Instance.new("ParticleEmitter")
	em.Texture = A.fxSparkle
	em.Color = ColorSequence.new(colour:Lerp(Color3.new(1, 1, 1), 0.45), colour)
	em.LightEmission = 1
	em.Brightness = def.bright
	em.LightInfluence = 0
	em.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.25, def.size), NumberSequenceKeypoint.new(1, 0) })
	em.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, def.alpha), NumberSequenceKeypoint.new(1, 1) })
	em.Lifetime = if def.orbit then NumberRange.new(1, 1.4) else NumberRange.new(1.6, 2.4)
	-- (faint tiers: thrown out ~2 studs and slowed by drag, so they hang round the body, not inside it)
	em.Speed = if def.orbit then NumberRange.new(0.1, 0.3) else NumberRange.new(4, 5)
	em.SpreadAngle = Vector2.new(180, 180)
	em.Acceleration = Vector3.new(0, 0.6, 0)
	em.Drag = 2
	em.Rotation = NumberRange.new(0, 90)
	em.RotSpeed = NumberRange.new(-40, 40)
	em.LockedToPart = false
	em.Parent = att
	att.Parent = root
	auras[model] = { att = att, em = em, def = def, band = band, root = root, phase = math.random() * math.pi * 2 }
end
-- each frame: the orbit; every 0.5 s: distance, low graphics and Reduced Motion -> on / off, the rate
local check = 0
RunService.Heartbeat:Connect(function(dt)
	check += dt
	local refresh = check >= 0.5
	if refresh then check = 0 end
	local cam = workspace.CurrentCamera
	local low, calm = false, false
	if refresh then low, calm = lowGraphics(), Kit.calm() end
	for model, a in pairs(auras) do
		if not a.att.Parent or not model.Parent then auraOff(model) continue end
		if refresh then
			local near = cam ~= nil and (a.root.Position - cam.CFrame.Position).Magnitude <= AURA_FAR
			a.em.Enabled = near
			a.em.Rate = a.def.rate * (if low then 0.4 else 1) * (if calm then 0.5 else 1)
			a.spin = a.def.orbit and not low and not calm
			if not a.spin then a.att.Position = Vector3.zero end
		end
		if a.spin and a.em.Enabled then
			a.phase += dt * 2.2
			a.att.Position = Vector3.new(math.cos(a.phase) * 2.4, 0.4 + math.sin(a.phase * 0.5) * 0.8, math.sin(a.phase) * 2.4)
		end
	end
end)
local IS_STUDIO = RunService:IsStudio()
local function auraFor(p: Player)
	local char = p.Character
	if not char then return end
	local test = if IS_STUDIO then workspace:GetAttribute("TestAuraLevel") else nil
	auraOn(char, if type(test) == "number" then test else tonumber(p:GetAttribute("CosmicLevel")) or 1)
end
if IS_STUDIO then
	workspace:GetAttributeChangedSignal("TestAuraLevel"):Connect(function()
		for _, p in ipairs(Players:GetPlayers()) do auraFor(p) end
	end)
	task.spawn(function()
		local rigs = workspace:WaitForChild("AuraTestRigs", math.huge)
		local function rig(m)
			if m:IsA("Model") then
				m:WaitForChild("HumanoidRootPart", 5)
				auraOn(m, tonumber(m:GetAttribute("CosmicLevel")) or 1)
			end
		end
		rigs.ChildAdded:Connect(rig)
		for _, m in ipairs(rigs:GetChildren()) do task.spawn(rig, m) end
	end)
end

local function watch(p: Player)
	p.CharacterAdded:Connect(function(char)
		char:WaitForChild("Head", 10)
		build(p)
		char:WaitForChild("HumanoidRootPart", 10)
		auraFor(p)
	end)
	p:GetAttributeChangedSignal("Rank"):Connect(function() build(p) end)
	p:GetAttributeChangedSignal("CosmicLevel"):Connect(function() auraFor(p) end)
	if p.Character then build(p) auraFor(p) end
end
for _, p in ipairs(Players:GetPlayers()) do task.spawn(watch, p) end
Players.PlayerAdded:Connect(watch)
Players.PlayerRemoving:Connect(function(p)
	if tags[p] then tags[p]:Destroy() tags[p] = nil end
	if p.Character then auraOff(p.Character) end
end)

-- your rank lands: dropped from high above, a bounce, sparkles round it
shared.GalaxyRankLand = function()
	build(player)
	local bb = tags[player]
	if not bb then return end
	if Kit.calm() then return end
	bb.StudsOffsetWorldSpace = REST + Vector3.new(0, 9, 0)
	TweenService:Create(bb, TweenInfo.new(0.7, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), { StudsOffsetWorldSpace = REST }):Play()
	for i = 1, 6 do
		local s = Kit.sparkle(bb, math.random(0, 100), math.random(0, 20), 12, 0.5 + i * 0.08)
		s.Position = UDim2.fromScale(math.random(), math.random())
		task.delay(2.5, function() s:Destroy() end)
	end
end
