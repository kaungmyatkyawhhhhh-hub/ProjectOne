-- GalaxyRankTags (Galaxy Incremental, alpha part 1, 3 Nov): every player's RANK over their head (design section 7: "rank
-- over the head"; MapConfig.Ranks: SPARK at Supernova 1, ...), in the rank's colour, from the first Supernova on (a new
-- player has none: the island plate already says NEW STAR). Everyone sees everyone's.
-- shared.GalaxyRankLand(): YOUR tag drops in from above with a bounce and sparkles (the Supernova cinematic calls it).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local MapConfig = require(Galaxy:WaitForChild("MapConfig"))
local Kit = require(Galaxy:WaitForChild("UIKit"))

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

local function watch(p: Player)
	p.CharacterAdded:Connect(function(char)
		char:WaitForChild("Head", 10)
		build(p)
	end)
	p:GetAttributeChangedSignal("Rank"):Connect(function() build(p) end)
	if p.Character then build(p) end
end
for _, p in ipairs(Players:GetPlayers()) do task.spawn(watch, p) end
Players.PlayerAdded:Connect(watch)
Players.PlayerRemoving:Connect(function(p)
	if tags[p] then tags[p]:Destroy() tags[p] = nil end
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
