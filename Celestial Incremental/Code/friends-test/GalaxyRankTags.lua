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
local REST = Vector3.new(0, 2.5, 0) -- (7 Nov: the tag's centre, 2.5 studs over the head's)
local tags = {} -- [Player] = BillboardGui

-- (feel pass, 5 Nov: the rank = the COSMIC LEVEL's name + the Supernovas, "FLARE III · ✦12", for everyone from the start;
-- the colour = the level's band)
local Econ = require(Galaxy:WaitForChild("EconConfig"))
-- (6 Nov, LUMI + RANK TITLE ART, #271 #339 #396): the rank is a PLATE (RankPlate: the rank's banner, its emblem in the
-- slot, the title in Luckiest Guy) + your Supernovas (a sparkle + the count) + a Forge COLLECTOR title under it. Sized in
-- PIXELS: readable at 60 studs and more; past FAR studs only the emblem shows
local RankPlate = require(Galaxy:WaitForChild("RankPlate"))
local Vfx = require(Galaxy:WaitForChild("VfxLibrary"))
local FAR = 140
local tagParts = {} -- [BillboardGui] = { full, far, head }
local function plateH(): number
	return if Vfx.phone() then 20 else 30 -- (7 Nov, phone HUD: smaller over the heads on a phone)
end
local function build(p: Player)
	if tags[p] then tagParts[tags[p]] = nil tags[p]:Destroy() tags[p] = nil end
	local char = p.Character
	local head = char and char:FindFirstChild("Head")
	local text = p:GetAttribute("Rank")
	if not head or type(text) ~= "string" or text == "" then return end
	local _ = MapConfig
	local base, novas = string.match(text, "^(.-)%s*·%s*✦(%d+)$")
	base = base or text
	local key = RankPlate.keyOf(base)
	-- (7 Nov, owner: "it becomes big when i zoom out and when i zoom in its tiny"; three loose pieces; "✦3" meant nothing;
	-- no name; too low. Now ONE compact tag: the DisplayName, then one row: the rank plate with the Supernova count INSIDE it
	-- ("FLARE IV  x3") and the VIP chip attached to its right end. Sized in STUDS (Kit.studsBillboard: it stays the avatar's
	-- size at any zoom, ~4.5 studs wide), centred 2.5 studs over the head, seen to 60 studs, fading out closer than 6)
	local h = 30 -- (design px; the billboard turns them into studs)
	local bb = Instance.new("BillboardGui")
	bb.Name = "Rank_" .. p.Name
	bb.Adornee = head
	bb.StudsOffsetWorldSpace = REST
	bb.LightInfluence = 0
	bb.MaxDistance = 60
	bb.ResetOnSpawn = false
	local full = Instance.new("CanvasGroup")
	full.Name = "Full"
	full.BackgroundTransparency = 1
	local nameH = math.floor(h * 0.62)
	local nameL = Instance.new("TextLabel")
	nameL.Name = "PlayerName"
	nameL.BackgroundTransparency = 1
	nameL.FontFace = RankPlate.FONT
	nameL.Text = p.DisplayName
	nameL.TextColor3 = Color3.new(1, 1, 1)
	nameL.TextSize = math.floor(nameH * 0.9)
	local ns = Instance.new("UIStroke")
	ns.Color, ns.Thickness = RankPlate.INK, 2
	ns.Parent = nameL
	nameL.Parent = full
	local plate = RankPlate.build(full, base .. (if novas then "  x" .. novas else ""), key, h)
	plate.Position = UDim2.fromOffset(0, nameH + 2)
	local w = plate:GetAttribute("W")
	-- (7 Nov: the VIP pass: a gold VIP chip ATTACHED to the plate's right end (the kit's gold chip: gradient, ink outline))
	if p:GetAttribute("Pass_VIP") == true then
		local pill = Instance.new("Frame")
		pill.Name = "VIP"
		pill.BackgroundColor3 = Color3.new(1, 1, 1)
		pill.Position = UDim2.fromOffset(w - 3, nameH + 2 + h * 0.18)
		pill.Size = UDim2.fromOffset(h * 1.25, h * 0.64)
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0.35, 0)
		c.Parent = pill
		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new(Color3.fromRGB(255, 241, 160), Color3.fromRGB(224, 138, 10))
		g.Rotation = 90
		g.Parent = pill
		local ps = Instance.new("UIStroke")
		ps.Color, ps.Thickness = RankPlate.INK, 2
		ps.Parent = pill
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.fromScale(1, 1)
		t.FontFace = RankPlate.FONT
		t.Text = "VIP"
		t.TextColor3 = Color3.new(1, 1, 1)
		t.TextSize = math.floor(h * 0.44)
		local ts = Instance.new("UIStroke")
		ts.Color, ts.Thickness = RankPlate.INK, 2
		ts.Parent = t
		t.Parent = pill
		pill.Parent = full
		w += h * 1.25 - 3
	end
	local total = nameH + 2 + h
	-- (Phase 2.5: a Forge COLLECTOR title, when you have one, in a smaller line under the plate)
	local title = p:GetAttribute("CollectorTitle")
	if type(title) == "string" and title ~= "" then
		local t = Instance.new("TextLabel")
		t.Name = "Collector"
		t.BackgroundTransparency = 1
		t.Position = UDim2.fromOffset(0, total + 1)
		t.Size = UDim2.fromOffset(w, math.floor(h * 0.5))
		t.FontFace = RankPlate.FONT
		t.TextSize = math.floor(h * 0.46)
		t.Text = title
		t.TextColor3 = Color3.fromRGB(255, 216, 74)
		local st = Instance.new("UIStroke")
		st.Color, st.Thickness = RankPlate.INK, 2
		st.Parent = t
		t.Parent = full
		total += math.floor(h * 0.5) + 1
	end
	nameL.Size = UDim2.fromOffset(w, nameH)
	-- (the plate's emblem pokes out of its left end: a margin all round)
	local pad = math.floor(h * 0.25)
	local designW, designH = w + pad * 2, total + pad * 2
	full.Position = UDim2.fromOffset(pad, pad)
	full.Size = UDim2.fromOffset(w + pad, total + pad)
	local inner = Kit.studsBillboard(bb, designW, designH, math.min(designW * 0.024, 5.5))
	full.Parent = inner
	local far = RankPlate.emblem(inner, key, h * 1.1) -- (kept for the far check; MaxDistance 60 is inside it now)
	far.Name = "Far"
	far.Position = UDim2.new(0.5, 0, 0, h * 0.55)
	far.Visible = false
	-- (7 Nov, owner: your OWN tag covered the island buy pad's label in front of you: you don't see your own, everyone
	-- else still sees it over your head)
	bb.Enabled = p ~= player
	bb.Parent = playerGui
	tags[p] = bb
	tagParts[bb] = { full = full, far = far, head = head, plate = plate }
end
-- (7 Nov: a tag fades out closer than 6 studs to the camera (gone at 4), every frame)
RunService.RenderStepped:Connect(function()
	local cam = workspace.CurrentCamera
	if not cam then return end
	for bb, t in pairs(tagParts) do
		if bb.Parent and t.head.Parent and t.full:IsA("CanvasGroup") then
			local d = (t.head.Position - cam.CFrame.Position).Magnitude
			t.full.GroupTransparency = math.clamp((6 - d) / 2, 0, 1)
		end
	end
end)
-- (every 0.5 s: past FAR studs a tag shows the emblem only)
local farCheck = 0
RunService.Heartbeat:Connect(function(dt)
	farCheck += dt
	if farCheck < 0.5 then return end
	farCheck = 0
	local cam = workspace.CurrentCamera
	if not cam then return end
	for bb, t in pairs(tagParts) do
		if not bb.Parent or not t.head.Parent then continue end
		local d = (t.head.Position - cam.CFrame.Position).Magnitude
		local isFar = d > FAR
		t.full.Visible = not isFar
		t.far.Visible = isFar
	end
end)

------------------------------------------------------------------------ rank aura (#290)
local VT = require(Galaxy:WaitForChild("VfxTextures")) -- (the VFX pass: our sparkle_star)
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
	em.Texture = VT.alpha.starburst_twinkle -- (white-cored: takes the band colour; 7 Nov: _alpha, no black boxes)
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
	p:GetAttributeChangedSignal("CollectorTitle"):Connect(function() build(p) end)
	p:GetAttributeChangedSignal("Pass_VIP"):Connect(function() build(p) end)
	p:GetAttributeChangedSignal("CosmicLevel"):Connect(function() auraFor(p) end)
	if p.Character then build(p) auraFor(p) end
end
for _, p in ipairs(Players:GetPlayers()) do task.spawn(watch, p) end
Players.PlayerAdded:Connect(watch)
Players.PlayerRemoving:Connect(function(p)
	if tags[p] then tags[p]:Destroy() tags[p] = nil end
	if p.Character then auraOff(p.Character) end
end)

-- your rank lands (after a Supernova, the cinematic calls it): the new EMBLEM scales in, then the PLATE slides in, a burst
-- of sparkle_star round your head and the rising chime (3 notes; #257 has no sound of its own yet). Reduced Motion: it just shows
shared.GalaxyRankLand = function()
	build(player)
	local bb = tags[player]
	local t = bb and tagParts[bb]
	if not t then return end
	local head = t.head
	Vfx.Sparkles(head.Position + Vector3.new(0, 3, 0), 24, Color3.fromRGB(255, 225, 150), 0.7, { mine = true })
	for k = 0, 2 do task.delay(0.25 + k * 0.1, function() Kit.sound("buyBody", { pitch = 1 + k * 0.26, volume = 0.7 }) end) end
	if Kit.calm() then return end
	local em = t.plate:FindFirstChild("Emblem")
	if em then
		local sc = Instance.new("UIScale")
		sc.Scale = 0
		sc.Parent = em
		TweenService:Create(sc, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	end
	local plate, title = t.plate:FindFirstChild("Plate"), t.plate:FindFirstChild("Title")
	for _, o in ipairs({ plate, title }) do
		if o then
			local goal = o.Position
			o.Position = goal - UDim2.fromOffset(40, 0)
			local prop = if o:IsA("TextLabel") then "TextTransparency" else "ImageTransparency"
			o[prop] = 1
			task.delay(0.25, function()
				TweenService:Create(o, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = goal, [prop] = 0 }):Play()
			end)
		end
	end
	local st = title and title:FindFirstChildOfClass("UIStroke")
	if st then
		st.Transparency = 1
		task.delay(0.25, function() TweenService:Create(st, TweenInfo.new(0.3), { Transparency = 0 }):Play() end)
	end
end
-- (Studio test switch: Workspace TestRankLand = any new value plays your rank landing)
if RunService:IsStudio() then workspace:GetAttributeChangedSignal("TestRankLand"):Connect(function() shared.GalaxyRankLand() end) end
