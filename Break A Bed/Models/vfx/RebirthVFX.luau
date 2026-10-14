--!nonstrict
-- RebirthVFX: custom VFX for the 8 rebirth cutscene creatures (Break A Bed).
-- Put this ModuleScript and RebirthVFXAnchors in ReplicatedStorage. Client-side only (cutscenes are local).
--
-- Usage:
--   local VFX = require(ReplicatedStorage.RebirthVFX)
--   local fx = VFX.Attach(creatureModel, "Phoenix")   -- aura, light, trails and looping particles
--   VFX.Burst(creatureModel, "Phoenix", groundPosition) -- the burst-out moment (rings, rays, flash, tier extras)
--   VFX.Dissolve(creatureModel, "Phoenix", 0.8)       -- end: fades the model and blows it apart into particles
--   fx:Destroy()                                       -- cleanup (Dissolve also cleans up)
--   VFX.SetLowGraphics(true)                           -- fewer particles, no afterimages

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Anchors = require(script.Parent:WaitForChild("RebirthVFXAnchors"))

local VFX = {}

-- The custom sprites in "Break A Bed/Models/vfx/sprites", uploaded 2026-10-14.
VFX.Sprites = {
	glow = "rbxassetid://72718961291471", spark = "rbxassetid://118257515762052", star = "rbxassetid://91261169508957", flame = "rbxassetid://84524091514752",
	flame_white = "rbxassetid://99098586951767", smoke = "rbxassetid://116516066522009", feather = "rbxassetid://90477064327301", ember = "rbxassetid://86116414486799",
	snowflake = "rbxassetid://133312230570253", ice_shard = "rbxassetid://93934057963322", coin = "rbxassetid://75677936675812", bubble = "rbxassetid://74830347392931",
	ring = "rbxassetid://114812788166514", petal = "rbxassetid://103770413540512", claw_slash = "rbxassetid://136607883066223", lightning = "rbxassetid://94110313424083",
	rune_circle = "rbxassetid://105909629892935", rays = "rbxassetid://84297323769537", cloud = "rbxassetid://107048214238270", trail = "rbxassetid://82683263065069",
	energy = "rbxassetid://125689238568684", dust = "rbxassetid://137582597658372", orb = "rbxassetid://107235527432295",
	-- 4x4 flipbooks (1024x1024): animated cartoon flames and anime aura spikes. Upload these two and paste the ids.
	flame_flipbook = "rbxassetid://80758190475188", aura_flipbook = "rbxassetid://89060942632732",
}

-- sprites that don't load yet (a new upload still in moderation) are swapped for a plain one, so nothing shows blank
VFX.FallbackUsed = {}
local FALLBACK = { flame_flipbook = "flame", aura_flipbook = "flame_white", rune_circle = "ring" }
task.spawn(function()
	local ids = {}
	for name, id in pairs(VFX.Sprites) do ids[id] = name end
	local list = {}
	for id in pairs(ids) do table.insert(list, id) end
	game:GetService("ContentProvider"):PreloadAsync(list, function(id, status)
		local name = ids[id]
		if status ~= Enum.AssetFetchStatus.Success and name and FALLBACK[name] then
			VFX.FallbackUsed[name] = true
			VFX.Sprites[name] = VFX.Sprites[FALLBACK[name]]
		end
	end)
end)

local low = false
function VFX.SetLowGraphics(on: boolean) low = on end
-- size multiplier for the particles and trails of the creature being set up (the cutscene resizes the models)
local curMul = 1

local function c3(hex: any): Color3 if typeof(hex) == "Color3" then return hex end return Color3.fromHex(hex) end
local function cs(...: string): ColorSequence
	local list = { ... }
	if #list == 1 then return ColorSequence.new(c3(list[1])) end
	local keys = {}
	for i, h in ipairs(list) do table.insert(keys, ColorSequenceKeypoint.new((i - 1) / (#list - 1), c3(h))) end
	return ColorSequence.new(keys)
end
local function ns(...: number): NumberSequence
	local list = { ... }
	if #list == 1 then return NumberSequence.new(list[1]) end
	local keys = {}
	for i, v in ipairs(list) do table.insert(keys, NumberSequenceKeypoint.new((i - 1) / (#list - 1), v)) end
	return NumberSequence.new(keys)
end
local FADE = ns(1, 0, 0.15, 1) -- fade in, hold, fade out
local function scaleSeq(seq: NumberSequence, k: number): NumberSequence
	if k == 1 then return seq end
	local keys = {}
	for _, kp in ipairs(seq.Keypoints) do table.insert(keys, NumberSequenceKeypoint.new(kp.Time, kp.Value * k, kp.Envelope * k)) end
	return NumberSequence.new(keys)
end

------------------------------------------------------------------------------------------
-- Profiles: one per creature. Every emitter is fully custom per creature.
-- emit fields: at (anchor or "Body"), sprite, color, size, rate, life, speed, spread,
--   accel, drag, rot, rotSpeed, light (LightEmission), trans, lockedToPart, zOffset, orient
-- trails: { from = anchor, width = studs, color, life, light }
-- burst: list of one-shot effects at the burst moment
------------------------------------------------------------------------------------------
type Profile = { [string]: any }
local P: { [string]: Profile } = {}

P.Phoenix = {
	tint = "#FFB42A", outline = "#FFE27A", light = { "#FFB347", 6, 22 },
	emit = {
		{ at = "Body", sprite = "flame_flipbook", color = cs("#FFF2B0", "#FFB42A", "#E8551C"), size = ns(3.2, 2.2, 0.4), rate = 40, life = { 0.5, 0.9 }, speed = { 2, 4 }, spread = 180, accel = Vector3.new(0, 8, 0), light = 1 },
		{ at = "WingR_Back", sprite = "feather", color = cs("#FFE27A", "#F28C1C"), size = ns(0.9, 0.7), rate = 10, life = { 1.4, 2.2 }, speed = { 1, 3 }, spread = 70, accel = Vector3.new(0, -2, 0), drag = 1.5, rotSpeed = { -120, 120 }, light = 0.6 },
		{ at = "WingL_Back", sprite = "feather", color = cs("#FFE27A", "#F28C1C"), size = ns(0.9, 0.7), rate = 10, life = { 1.4, 2.2 }, speed = { 1, 3 }, spread = 70, accel = Vector3.new(0, -2, 0), drag = 1.5, rotSpeed = { -120, 120 }, light = 0.6 },
		{ at = "Tail_Mid", sprite = "ember", color = cs("#FFF6C8", "#FF8A1E"), size = ns(0.5, 0.15), rate = 45, life = { 0.8, 1.4 }, speed = { 2, 6 }, spread = 60, accel = Vector3.new(0, 4, 0), light = 1 },
		{ at = "Crest", sprite = "spark", color = cs("#FFFFFF", "#FFD34D"), size = ns(1.4, 0), rate = 8, life = { 0.4, 0.6 }, speed = { 0, 1 }, spread = 180, light = 1, rotSpeed = { -90, 90 } },
		{ at = "Body", sprite = "glow", color = cs("#FFD34D"), size = ns(9, 11), rate = 3, life = { 0.8, 0.8 }, speed = { 0, 0 }, trans = ns(1, 0.65, 1), light = 1, lockedToPart = true },
	},
	trails = {
		{ from = "WingR_Tip", width = 1.2, color = cs("#FFF2B0", "#FF7A1A"), life = 0.45, light = 1 },
		{ from = "WingL_Tip", width = 1.2, color = cs("#FFF2B0", "#FF7A1A"), life = 0.45, light = 1 },
		{ from = "Tail_R", width = 1.0, color = cs("#FFD34D", "#E8551C"), life = 0.6, light = 1 },
		{ from = "Tail_L", width = 1.0, color = cs("#FFD34D", "#E8551C"), life = 0.6, light = 1 },
		{ from = "Tail_Mid", width = 1.4, color = cs("#FFD34D", "#E8551C"), life = 0.7, light = 1 },
	},
	burst = { ring = "#FFC83A", rays = "#FFE27A", rune = "#FFB42A",
		extra = { { sprite = "feather", color = cs("#FFE27A", "#F28C1C"), count = 40, size = ns(1.2, 0.8), speed = { 15, 30 }, life = { 1.5, 2.5 }, accel = Vector3.new(0, -6, 0) } } },
	dissolve = { sprite = "ember", color = cs("#FFF6C8", "#FF8A1E") },
}

P.FirePhoenix = {
	tint = "#FF3B2F", outline = "#FF9A3C", light = { "#FF5A1F", 8, 26 },
	emit = {
		{ at = "Body", sprite = "flame_flipbook", color = cs("#FFF0A0", "#FF6A1A", "#B3120A"), size = ns(4.5, 3, 0.5), rate = 70, life = { 0.5, 0.9 }, speed = { 3, 6 }, spread = 180, accel = Vector3.new(0, 14, 0), light = 1 },
		{ at = "WingR_Back", sprite = "flame_flipbook", color = cs("#FFD34D", "#FF3B2F"), size = ns(2.2, 0.3), rate = 30, life = { 0.4, 0.7 }, speed = { 2, 4 }, spread = 40, accel = Vector3.new(0, 10, 0), light = 1 },
		{ at = "WingL_Back", sprite = "flame_flipbook", color = cs("#FFD34D", "#FF3B2F"), size = ns(2.2, 0.3), rate = 30, life = { 0.4, 0.7 }, speed = { 2, 4 }, spread = 40, accel = Vector3.new(0, 10, 0), light = 1 },
		{ at = "Tail_Mid", sprite = "ember", color = cs("#FFF6C8", "#FF3B1A"), size = ns(0.6, 0.1), rate = 80, life = { 1, 1.8 }, speed = { 4, 9 }, spread = 70, accel = Vector3.new(0, 6, 0), light = 1 },
		{ at = "Body", sprite = "smoke", color = cs("#3A1A12", "#1A0E0A"), size = ns(4, 9), rate = 10, life = { 1.5, 2.5 }, speed = { 2, 4 }, spread = 60, accel = Vector3.new(0, 6, 0), trans = ns(1, 0.55, 1), light = 0 },
		{ at = "Beak", sprite = "flame_flipbook", color = cs("#FFF0A0", "#FF3B2F"), size = ns(1.6, 0.2), rate = 25, life = { 0.3, 0.5 }, speed = { 8, 12 }, spread = 15, light = 1 },
	},
	trails = {
		{ from = "WingR_Tip", width = 1.6, color = cs("#FFF0A0", "#FF3B2F", "#5A0A06"), life = 0.6, light = 1 },
		{ from = "WingL_Tip", width = 1.6, color = cs("#FFF0A0", "#FF3B2F", "#5A0A06"), life = 0.6, light = 1 },
		{ from = "Tail_R", width = 1.4, color = cs("#FFD34D", "#C21807"), life = 0.8, light = 1 },
		{ from = "Tail_L", width = 1.4, color = cs("#FFD34D", "#C21807"), life = 0.8, light = 1 },
		{ from = "Tail_Mid", width = 1.8, color = cs("#FFD34D", "#C21807"), life = 0.9, light = 1 },
	},
	burst = { ring = "#FF3B2F", rays = "#FFB347", rune = "#FF5A1F",
		extra = { { sprite = "flame_flipbook", color = cs("#FFF0A0", "#FF3B2F"), count = 60, size = ns(4, 0.5), speed = { 20, 40 }, life = { 0.6, 1 }, accel = Vector3.new(0, 10, 0) },
			{ sprite = "smoke", color = cs("#2A1410"), count = 20, size = ns(6, 14), speed = { 8, 14 }, life = { 1.5, 2.5 }, accel = Vector3.new(0, 5, 0), trans = ns(1, 0.5, 1) } },
		lava = true },
	dissolve = { sprite = "flame_flipbook", color = cs("#FFD34D", "#FF3B2F") },
}

P.Tiger = {
	tint = "#FF8A2B", outline = "#FFD08A", light = { "#FF9A3C", 6, 20 },
	emit = {
		{ at = "Back", sprite = "flame_flipbook", color = cs("#FFE0A0", "#FF8A2B", "#C24A0A"), size = ns(3, 2, 0.3), rate = 50, life = { 0.4, 0.8 }, speed = { 2, 5 }, spread = 50, accel = Vector3.new(0, 10, 0), light = 1 },
		{ at = "Belly", sprite = "dust", color = cs("#C9A27A"), size = ns(2, 5), rate = 12, life = { 0.8, 1.2 }, speed = { 1, 3 }, spread = 90, trans = ns(1, 0.6, 1), light = 0 },
		{ at = "Back", sprite = "lightning", color = cs("#FFF2C8", "#FFB000"), size = ns(3, 2), rate = 6, life = { 0.12, 0.2 }, speed = { 0, 0 }, spread = 180, light = 1, rotSpeed = { 0, 0 }, rot = { 0, 360 }, lockedToPart = true },
		{ at = "TailTip", sprite = "ember", color = cs("#FFF0C0", "#FF8A2B"), size = ns(0.6, 0.1), rate = 30, life = { 0.6, 1 }, speed = { 1, 3 }, spread = 180, light = 1 },
		{ at = "Mouth", sprite = "ring", color = cs("#FFE0A0"), size = ns(1, 7), rate = 2, life = { 0.5, 0.5 }, speed = { 6, 6 }, spread = 0, trans = ns(0.2, 1), light = 1 },
	},
	trails = {
		{ from = "Paw_FR", width = 0.9, color = cs("#FFF0C0", "#FF8A2B"), life = 0.35, light = 1 },
		{ from = "Paw_FL", width = 0.9, color = cs("#FFF0C0", "#FF8A2B"), life = 0.35, light = 1 },
		{ from = "Paw_BR", width = 0.8, color = cs("#FFF0C0", "#FF8A2B"), life = 0.3, light = 1 },
		{ from = "Paw_BL", width = 0.8, color = cs("#FFF0C0", "#FF8A2B"), life = 0.3, light = 1 },
		{ from = "TailTip", width = 0.7, color = cs("#FFE0A0", "#C24A0A"), life = 0.5, light = 1 },
	},
	burst = { ring = "#FF8A2B", rays = "#FFD08A", rune = "#FF8A2B",
		extra = { { sprite = "claw_slash", color = cs("#FFF6D8", "#FF8A2B"), count = 3, size = ns(10, 12), speed = { 0, 0 }, life = { 0.45, 0.45 }, trans = ns(0, 1), rot = { -30, 30 } },
			{ sprite = "dust", color = cs("#B89470"), count = 25, size = ns(3, 8), speed = { 10, 20 }, life = { 0.8, 1.4 }, trans = ns(0.3, 1) } },
		groundCrack = "#FF8A2B" },
	dissolve = { sprite = "flame_flipbook", color = cs("#FFE0A0", "#FF8A2B") },
}

P.Crane = {
	tint = "#DDE8FF", outline = "#FFFFFF", light = { "#CFE0FF", 5, 22 },
	emit = {
		{ at = "Back", sprite = "glow", color = cs("#E8F0FF"), size = ns(0.3, 0.6, 0), rate = 40, life = { 1.5, 2.5 }, speed = { 0.5, 1.5 }, spread = 180, light = 1, accel = Vector3.new(0, 1, 0) },
		{ at = "WingR_Back", sprite = "feather", color = cs("#FFFFFF", "#C9D2E6"), size = ns(1.0, 0.8), rate = 8, life = { 2, 3 }, speed = { 0.5, 2 }, spread = 60, accel = Vector3.new(0, -1.5, 0), drag = 2, rotSpeed = { -90, 90 }, light = 0.4 },
		{ at = "WingL_Back", sprite = "feather", color = cs("#FFFFFF", "#C9D2E6"), size = ns(1.0, 0.8), rate = 8, life = { 2, 3 }, speed = { 0.5, 2 }, spread = 60, accel = Vector3.new(0, -1.5, 0), drag = 2, rotSpeed = { -90, 90 }, light = 0.4 },
		{ at = "Feet", sprite = "smoke", color = cs("#DCE6FF"), size = ns(3, 7), rate = 8, life = { 1.5, 2 }, speed = { 0.5, 1.5 }, spread = 90, trans = ns(1, 0.7, 1), light = 0.3 },
		{ at = "Back", sprite = "spark", color = cs("#FFFFFF", "#AFC8FF"), size = ns(1.2, 0), rate = 6, life = { 0.5, 0.8 }, speed = { 0, 1 }, spread = 180, light = 1 },
	},
	trails = {
		{ from = "WingR_Tip", width = 0.6, color = cs("#FFFFFF", "#AFC8FF"), life = 0.9, light = 1 },
		{ from = "WingL_Tip", width = 0.6, color = cs("#FFFFFF", "#AFC8FF"), life = 0.9, light = 1 },
		{ from = "Feet", width = 0.4, color = cs("#FFFFFF", "#AFC8FF"), life = 0.7, light = 1 },
	},
	burst = { ring = "#E8F0FF", rays = "#FFFFFF", rune = "#AFC8FF", moon = true,
		extra = { { sprite = "feather", color = cs("#FFFFFF", "#C9D2E6"), count = 35, size = ns(1.2, 1), speed = { 6, 14 }, life = { 2.5, 3.5 }, accel = Vector3.new(0, -2, 0), drag = 1 } } },
	dissolve = { sprite = "feather", color = cs("#FFFFFF", "#C9D2E6") },
}

P.GoldDragon = {
	tint = "#FFD23A", outline = "#FFF2A8", light = { "#FFD23A", 7, 26 },
	emit = {
		{ at = "Spine2", sprite = "flame_flipbook", color = cs("#FFF2A8", "#FFB000"), size = ns(2, 0.3), rate = 25, life = { 0.4, 0.7 }, speed = { 1, 3 }, spread = 30, accel = Vector3.new(0, 8, 0), light = 1 },
		{ at = "Spine4", sprite = "flame_flipbook", color = cs("#FFF2A8", "#FFB000"), size = ns(2, 0.3), rate = 25, life = { 0.4, 0.7 }, speed = { 1, 3 }, spread = 30, accel = Vector3.new(0, 8, 0), light = 1 },
		{ at = "Spine3", sprite = "coin", color = cs("#FFFFFF"), size = ns(0.8, 0.8), rate = 14, life = { 1.5, 2.2 }, speed = { 3, 6 }, spread = 60, accel = Vector3.new(0, -14, 0), rotSpeed = { -300, 300 }, light = 0.2 },
		{ at = "Spine5", sprite = "coin", color = cs("#FFFFFF"), size = ns(0.8, 0.8), rate = 14, life = { 1.5, 2.2 }, speed = { 3, 6 }, spread = 60, accel = Vector3.new(0, -14, 0), rotSpeed = { -300, 300 }, light = 0.2 },
		{ at = "Spine1", sprite = "cloud", color = cs("#FFF6D8"), size = ns(3, 5), rate = 4, life = { 1.5, 2 }, speed = { 0.5, 1 }, spread = 90, trans = ns(1, 0.3, 1), light = 0.3 },
		{ at = "Spine6", sprite = "cloud", color = cs("#FFF6D8"), size = ns(3, 5), rate = 4, life = { 1.5, 2 }, speed = { 0.5, 1 }, spread = 90, trans = ns(1, 0.3, 1), light = 0.3 },
		{ at = "Spine3", sprite = "star", color = cs("#FFFFFF", "#FFD23A"), size = ns(0.9, 0), rate = 15, life = { 0.6, 1 }, speed = { 1, 3 }, spread = 180, light = 1, rotSpeed = { -180, 180 } },
		{ at = "Mouth", sprite = "glow", color = cs("#FFD23A"), size = ns(2.5, 3.5), rate = 4, life = { 0.5, 0.5 }, speed = { 0, 0 }, trans = ns(1, 0.4, 1), light = 1, lockedToPart = true },
	},
	trails = {
		{ from = "Whisker", width = 0.5, color = cs("#FFF2A8", "#FF6A00"), life = 0.8, light = 1 },
		{ from = "TailTip", width = 1.4, color = cs("#FFF2A8", "#FFB000"), life = 0.9, light = 1 },
		{ from = "Spine1", width = 1.0, color = cs("#FFE27A", "#FFB000"), life = 0.6, light = 1 },
		{ from = "Spine4", width = 1.0, color = cs("#FFE27A", "#FFB000"), life = 0.6, light = 1 },
	},
	burst = { ring = "#FFD23A", rays = "#FFF2A8", rune = "#FFB000",
		extra = { { sprite = "coin", color = cs("#FFFFFF"), count = 70, size = ns(1, 1), speed = { 15, 30 }, life = { 2, 3 }, accel = Vector3.new(0, -30, 0), rotSpeed = { -400, 400 } } },
		coinRain = true },
	dissolve = { sprite = "star", color = cs("#FFFFFF", "#FFD23A") },
}

P.IceDragon = {
	tint = "#7FDBFF", outline = "#E8FBFF", light = { "#8EE8FF", 6, 24 },
	emit = {
		{ at = "Back", sprite = "snowflake", color = cs("#FFFFFF", "#BDF2FF"), size = ns(0.8, 0.5), rate = 25, life = { 1.5, 2.5 }, speed = { 1, 3 }, spread = 180, accel = Vector3.new(0, -2, 0), rotSpeed = { -60, 60 }, light = 0.7 },
		{ at = "WingR_Low", sprite = "ice_shard", color = cs("#E8FBFF", "#7FDBFF"), size = ns(0.9, 0.4), rate = 10, life = { 0.8, 1.3 }, speed = { 3, 6 }, spread = 60, accel = Vector3.new(0, -12, 0), rotSpeed = { -200, 200 }, light = 0.6 },
		{ at = "WingL_Low", sprite = "ice_shard", color = cs("#E8FBFF", "#7FDBFF"), size = ns(0.9, 0.4), rate = 10, life = { 0.8, 1.3 }, speed = { 3, 6 }, spread = 60, accel = Vector3.new(0, -12, 0), rotSpeed = { -200, 200 }, light = 0.6 },
		{ at = "Mouth", sprite = "smoke", color = cs("#FFFFFF", "#BDF2FF"), size = ns(1.5, 6), rate = 25, life = { 0.8, 1.2 }, speed = { 8, 12 }, spread = 15, trans = ns(0.4, 1), light = 0.5 },
		{ at = "Chest", sprite = "spark", color = cs("#FFFFFF", "#8EE8FF"), size = ns(1.3, 0), rate = 12, life = { 0.4, 0.7 }, speed = { 0, 1 }, spread = 180, light = 1 },
		{ at = "Back", sprite = "glow", color = cs("#8EE8FF"), size = ns(8, 10), rate = 3, life = { 0.8, 0.8 }, speed = { 0, 0 }, trans = ns(1, 0.7, 1), light = 1, lockedToPart = true },
	},
	trails = {
		{ from = "WingR_Tip", width = 1.0, color = cs("#FFFFFF", "#7FDBFF"), life = 0.6, light = 1 },
		{ from = "WingL_Tip", width = 1.0, color = cs("#FFFFFF", "#7FDBFF"), life = 0.6, light = 1 },
		{ from = "TailTip", width = 1.2, color = cs("#E8FBFF", "#3FA8FF"), life = 0.7, light = 1 },
	},
	burst = { ring = "#8EE8FF", rays = "#E8FBFF", rune = "#7FDBFF", frost = true,
		extra = { { sprite = "ice_shard", color = cs("#FFFFFF", "#7FDBFF"), count = 45, size = ns(1.4, 0.6), speed = { 20, 35 }, life = { 0.8, 1.4 }, accel = Vector3.new(0, -20, 0), rotSpeed = { -300, 300 } },
			{ sprite = "snowflake", color = cs("#FFFFFF"), count = 40, size = ns(1, 0.6), speed = { 5, 12 }, life = { 2, 3 }, accel = Vector3.new(0, -2, 0) } } },
	dissolve = { sprite = "snowflake", color = cs("#FFFFFF", "#8EE8FF") },
}

P.RainbowKoi = {
	tint = "#FF7AD9", outline = "#FFFFFF", light = { "#C8A0FF", 5, 20 }, rainbow = true,
	emit = {
		{ at = "Mouth", sprite = "bubble", color = cs("#FFFFFF", "#BDEBFF"), size = ns(0.4, 0.7), rate = 10, life = { 1.2, 2 }, speed = { 2, 4 }, spread = 25, accel = Vector3.new(0, 3, 0), light = 0.4 },
		{ at = "Dorsal", sprite = "spark", color = cs("#FF5A5A", "#FFD34D", "#5AFF8A", "#5AC8FF", "#C85AFF"), size = ns(1, 0), rate = 15, life = { 0.5, 0.9 }, speed = { 1, 2 }, spread = 180, light = 1 },
		{ at = "FinR", sprite = "petal", color = cs("#FFFFFF"), size = ns(0.6, 0.5), rate = 5, life = { 1.5, 2.5 }, speed = { 1, 2 }, spread = 90, accel = Vector3.new(0, -1, 0), rotSpeed = { -120, 120 }, light = 0.2 },
		{ at = "FinL", sprite = "petal", color = cs("#FFFFFF"), size = ns(0.6, 0.5), rate = 5, life = { 1.5, 2.5 }, speed = { 1, 2 }, spread = 90, accel = Vector3.new(0, -1, 0), rotSpeed = { -120, 120 }, light = 0.2 },
		{ at = "Dorsal", sprite = "ring", color = cs("#BDEBFF"), size = ns(1, 5), rate = 1.5, life = { 0.8, 0.8 }, speed = { 0, 0 }, trans = ns(0.4, 1), light = 0.8, lockedToPart = true },
	},
	trails = {
		{ from = "Tail_Top", width = 1.0, color = cs("#FF5A5A", "#FFD34D", "#5AFF8A", "#5AC8FF", "#C85AFF"), life = 0.9, light = 1 },
		{ from = "Tail_Bottom", width = 1.0, color = cs("#C85AFF", "#5AC8FF", "#5AFF8A", "#FFD34D", "#FF5A5A"), life = 0.9, light = 1 },
	},
	burst = { ring = "#FFFFFF", rays = "#FFE6FF", rune = "#C85AFF", rainbowArc = true,
		extra = { { sprite = "bubble", color = cs("#FFFFFF", "#BDEBFF"), count = 50, size = ns(0.8, 1.4), speed = { 6, 14 }, life = { 1.5, 2.5 }, accel = Vector3.new(0, 4, 0) },
			{ sprite = "spark", color = cs("#FF5A5A", "#FFD34D", "#5AFF8A", "#5AC8FF", "#C85AFF"), count = 40, size = ns(2, 0), speed = { 10, 25 }, life = { 0.6, 1 } } } },
	dissolve = { sprite = "bubble", color = cs("#FFFFFF", "#BDEBFF") },
}

P.GalaxyDragon = {
	tint = "#9B5CFF", outline = "#E2CCFF", light = { "#B07CFF", 7, 26 },
	emit = {
		{ at = "Spine2", sprite = "smoke", color = cs("#6A2CFF", "#E048C8", "#2A0E5A"), size = ns(4, 8), rate = 12, life = { 1.2, 2 }, speed = { 1, 2 }, spread = 180, trans = ns(1, 0.45, 1), light = 1 },
		{ at = "Spine5", sprite = "smoke", color = cs("#3FA8FF", "#6A2CFF", "#2A0E5A"), size = ns(4, 8), rate = 12, life = { 1.2, 2 }, speed = { 1, 2 }, spread = 180, trans = ns(1, 0.45, 1), light = 1 },
		{ at = "Spine3", sprite = "star", color = cs("#FFFFFF", "#E2CCFF"), size = ns(0.8, 0), rate = 30, life = { 0.8, 1.4 }, speed = { 1, 3 }, spread = 180, light = 1, rotSpeed = { -180, 180 } },
		{ at = "Spine6", sprite = "spark", color = cs("#FFFFFF", "#9B5CFF"), size = ns(1.5, 0), rate = 15, life = { 0.4, 0.7 }, speed = { 0, 1 }, spread = 180, light = 1 },
		{ at = "Mouth", sprite = "energy", color = cs("#E2CCFF", "#9B5CFF"), size = ns(2, 4), rate = 10, life = { 0.3, 0.5 }, speed = { 0, 0 }, spread = 0, trans = ns(0.3, 1), light = 1, lockedToPart = true },
		{ at = "Spine1", sprite = "orb", color = cs("#FF9AE6"), size = ns(0.9, 0.9), rate = 1, life = { 3, 3 }, speed = { 2, 3 }, spread = 180, light = 0.3 },
		{ at = "Spine4", sprite = "orb", color = cs("#7FC8FF"), size = ns(1.2, 1.2), rate = 1, life = { 3, 3 }, speed = { 2, 3 }, spread = 180, light = 0.3 },
	},
	trails = {
		{ from = "TailTip", width = 1.6, color = cs("#E2CCFF", "#6A2CFF", "#120626"), life = 1.0, light = 1 },
		{ from = "Spine2", width = 1.2, color = cs("#E048C8", "#2A0E5A"), life = 0.7, light = 1 },
		{ from = "Spine5", width = 1.2, color = cs("#3FA8FF", "#2A0E5A"), life = 0.7, light = 1 },
	},
	burst = { ring = "#9B5CFF", rays = "#E2CCFF", rune = "#6A2CFF", vortex = true, planets = true,
		extra = { { sprite = "star", color = cs("#FFFFFF", "#E2CCFF"), count = 80, size = ns(1.2, 0), speed = { 15, 35 }, life = { 1, 2 }, rotSpeed = { -360, 360 } } } },
	dissolve = { sprite = "star", color = cs("#FFFFFF", "#9B5CFF") },
}

VFX.Profiles = P

------------------------------------------------------------------------------------------
-- Helpers
------------------------------------------------------------------------------------------
local function anchorAttachment(model: Model, creature: string, anchor: string): Attachment?
	local def = Anchors[creature] and Anchors[creature][anchor]
	local part: BasePart?
	local offset = Vector3.zero
	if def then
		part = model:FindFirstChild(def.part, true) :: BasePart?
		offset = def.offset
	else
		part = model:FindFirstChild(anchor, true) :: BasePart?
	end
	if not part then return nil end
	local a = Instance.new("Attachment")
	a.Name = "VFX_" .. anchor
	a.Position = offset * model:GetScale() -- (the anchors were measured on the unscaled model)
	a.Parent = part
	return a
end

local function emitter(e: any, parent: Instance): ParticleEmitter
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = VFX.Sprites[e.sprite]
	pe.Color = e.color or ColorSequence.new(Color3.new(1, 1, 1))
	pe.Size = scaleSeq(e.size or ns(1), curMul)
	pe.Transparency = e.trans or FADE
	pe.Lifetime = NumberRange.new(e.life[1], e.life[2])
	pe.Speed = NumberRange.new(e.speed[1], e.speed[2])
	pe.SpreadAngle = Vector2.new(e.spread or 0, e.spread or 0)
	pe.Acceleration = e.accel or Vector3.zero
	pe.Drag = e.drag or 0
	pe.Rotation = e.rot and NumberRange.new(e.rot[1], e.rot[2]) or NumberRange.new(0, 360)
	pe.RotSpeed = e.rotSpeed and NumberRange.new(e.rotSpeed[1], e.rotSpeed[2]) or NumberRange.new(0)
	pe.LightEmission = e.light or 0.5
	pe.LightInfluence = 0
	pe.LockedToPart = e.lockedToPart or false
	pe.ZOffset = e.zOffset or 0
	pe.Rate = (e.rate or 0) * (low and 0.35 or 1)
	if string.find(e.sprite, "flipbook") and not VFX.FallbackUsed[e.sprite] then
		pe.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
		pe.FlipbookMode = Enum.ParticleFlipbookMode.Loop
		pe.FlipbookFramerate = NumberRange.new(18, 26)
		pe.FlipbookStartRandom = true
		pe.Orientation = Enum.ParticleOrientation.FacingCameraWorldUp -- flames stay upright
		if e.rot == nil then pe.Rotation = NumberRange.new(0) end
		if e.rotSpeed == nil then pe.RotSpeed = NumberRange.new(0) end
	end
	pe.Parent = parent
	return pe
end

local function trail(t: any, a0: Attachment): Trail
	local a1 = Instance.new("Attachment")
	a1.Name = a0.Name .. "_B"
	a1.Position = a0.Position + Vector3.new(0, t.width * curMul, 0)
	a1.Parent = a0.Parent
	local tr = Instance.new("Trail")
	tr.Attachment0 = a0
	tr.Attachment1 = a1
	tr.Texture = VFX.Sprites.trail
	tr.TextureMode = Enum.TextureMode.Stretch
	tr.Color = t.color
	tr.Transparency = ns(0, 0.4, 1)
	tr.Lifetime = t.life
	tr.LightEmission = t.light or 1
	tr.LightInfluence = 0
	tr.FaceCamera = true
	tr.WidthScale = ns(1, 0.2)
	tr.MinLength = 0.05
	tr.Parent = a0.Parent
	return tr
end

local function worldBurst(pos: Vector3, e: any, life: number?)
	if e.spread == nil then e = table.clone(e); e.spread = 180 end
	local p = Instance.new("Part")
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	p.Transparency = 1; p.Size = Vector3.one; p.CFrame = CFrame.new(pos)
	p.Parent = workspace
	local pe = emitter(e, p)
	pe.Rate = 0
	pe:Emit(math.floor((e.count or 20) * (low and 0.4 or 1)))
	Debris:AddItem(p, life or (e.life[2] + 0.5))
	return p
end

local function flatDecal(pos: Vector3, sprite: string, color: string, size: number, life: number, spin: number?, grow: number?)
	-- a flat glowing image on the ground (rings, rune circles, cracks)
	local p = Instance.new("Part")
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	p.Transparency = 1; p.Size = Vector3.new(size, 0.05, size)
	p.CFrame = CFrame.new(pos + Vector3.new(0, 0.08, 0))
	p.Parent = workspace
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Top; gui.LightInfluence = 0; gui.Brightness = 3
	gui.CanvasSize = Vector2.new(512, 512); gui.Parent = p
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1; img.Size = UDim2.fromScale(1, 1)
	img.AnchorPoint = Vector2.new(0.5, 0.5); img.Position = UDim2.fromScale(0.5, 0.5)
	img.Image = VFX.Sprites[sprite]; img.ImageColor3 = c3(color); img.Parent = gui
	if spin then TweenService:Create(img, TweenInfo.new(life, Enum.EasingStyle.Linear), { Rotation = spin }):Play() end
	if grow then
		local target = Vector3.new(size * grow, 0.05, size * grow)
		TweenService:Create(p, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = target }):Play()
	end
	TweenService:Create(img, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { ImageTransparency = 1 }):Play()
	Debris:AddItem(p, life + 0.1)
	return p
end

local function billboard(pos: Vector3, sprite: string, color: string, size: number, life: number, grow: number?)
	local p = Instance.new("Part")
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	p.Transparency = 1; p.Size = Vector3.one; p.CFrame = CFrame.new(pos); p.Parent = workspace
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromScale(size, size); bb.LightInfluence = 0; bb.Brightness = 4; bb.AlwaysOnTop = false
	bb.Parent = p
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1; img.Size = UDim2.fromScale(1, 1)
	img.Image = VFX.Sprites[sprite]; img.ImageColor3 = c3(color); img.Parent = bb
	if grow then TweenService:Create(bb, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Size = UDim2.fromScale(size * grow, size * grow) }):Play() end
	TweenService:Create(img, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { ImageTransparency = 1, Rotation = 25 }):Play()
	Debris:AddItem(p, life + 0.1)
end

------------------------------------------------------------------------------------------
-- Public API
------------------------------------------------------------------------------------------
export type Handle = { Destroy: (self: Handle) -> (), Instances: { Instance }, Conns: { RBXScriptConnection } }

function VFX.Attach(model: Model, creature: string, sizeMul: number?): Handle
	curMul = sizeMul or 1
	local prof = P[creature]
	assert(prof, "RebirthVFX: unknown creature " .. tostring(creature))
	local made: { Instance } = {}
	local conns: { RBXScriptConnection } = {}
	local body = (model:FindFirstChild("Body", true) or model.PrimaryPart) :: BasePart

	-- spirit outline + soft fill in the tier color (keeps the textures visible)
	local hl = Instance.new("Highlight")
	hl.Adornee = model; hl.DepthMode = Enum.HighlightDepthMode.Occluded
	hl.FillColor = c3(prof.tint); hl.FillTransparency = 0.78
	hl.OutlineColor = c3(prof.outline); hl.OutlineTransparency = 0
	hl.Parent = model; table.insert(made, hl)

	-- light inside the body (lights up the player and the ground)
	local light = Instance.new("PointLight")
	light.Color = c3(prof.light[1]); light.Brightness = prof.light[2]; light.Range = prof.light[3]; light.Shadows = false
	light.Parent = body; table.insert(made, light)
	-- breathing pulse
	local t0 = os.clock()
	table.insert(conns, RunService.RenderStepped:Connect(function()
		local s = 0.5 + 0.5 * math.sin((os.clock() - t0) * 4)
		light.Brightness = prof.light[2] * (0.75 + 0.5 * s)
		hl.FillTransparency = 0.82 - 0.1 * s
		if prof.rainbow then
			local h = ((os.clock() - t0) * 0.25) % 1
			hl.OutlineColor = Color3.fromHSV(h, 0.6, 1); light.Color = Color3.fromHSV(h, 0.5, 1)
		end
	end))

	-- looping particles
	for _, e in ipairs(prof.emit) do
		local a = if e.at == "Body" then nil else anchorAttachment(model, creature, e.at)
		local parent: Instance = a or body
		table.insert(made, emitter(e, parent))
		if a then table.insert(made, a) end
	end
	-- trails
	for _, t in ipairs(prof.trails) do
		local a = anchorAttachment(model, creature, t.from)
		if a then
			table.insert(made, a)
			local tr = trail(t, a); table.insert(made, tr)
		end
	end
	-- afterimages: 3 fading ghost copies every 0.12 s while it moves (off on low graphics)
	if not low then
		local last = 0
		table.insert(conns, RunService.Heartbeat:Connect(function()
			if os.clock() - last < 0.12 then return end
			last = os.clock()
			local ghost = Instance.new("Model")
			for _, d in ipairs(model:GetDescendants()) do
				if d:IsA("MeshPart") then
					local g = d:Clone()
					g:ClearAllChildren()
					g.Anchored = true; g.CanCollide = false; g.CanQuery = false; g.CanTouch = false
					g.Material = Enum.Material.Neon; g.Color = c3(prof.tint); g.Transparency = 0.85 -- (tuned in Play: 0.6 washed the animal out)
					g.TextureID = ""
					g.Parent = ghost
					TweenService:Create(g, TweenInfo.new(0.35), { Transparency = 1 }):Play()
				end
			end
			ghost.Parent = workspace
			Debris:AddItem(ghost, 0.4)
		end))
	end

	curMul = 1
	local h = { Instances = made, Conns = conns } :: any
	function h:Destroy()
		for _, c in ipairs(self.Conns) do c:Disconnect() end
		for _, i in ipairs(self.Instances) do if i.Parent then i:Destroy() end end
	end
	return h
end

function VFX.Burst(model: Model, creature: string, ground: Vector3)
	local prof = P[creature]; local b = prof.burst
	local center = (model:GetPivot()).Position
	-- white flash + light rays + shockwave rings + spinning rune circle
	billboard(center, "glow", "#FFFFFF", 30, 0.35, 1.6)
	billboard(center, "rays", b.rays, 26, 0.9, 1.4)
	flatDecal(ground, "ring", b.ring, 6, 0.6, nil, 7)
	task.delay(0.12, function() flatDecal(ground, "ring", b.ring, 6, 0.7, nil, 9) end)
	flatDecal(ground, "rune_circle", b.rune, 18, 2.5, 180, 1.15)
	billboard(center, "ring", b.ring, 8, 0.5, 6) -- vertical ring
	-- tier extras
	for _, e in ipairs(b.extra or {}) do worldBurst(center, e) end
	if b.groundCrack then
		for i = 1, 6 do
			local ang = (i / 6) * math.pi * 2
			flatDecal(ground + Vector3.new(math.cos(ang), 0, math.sin(ang)) * 5, "lightning", b.groundCrack, 9, 1.5, math.deg(ang))
		end
	end
	if b.frost then flatDecal(ground, "snowflake", "#DFF8FF", 4, 2.2, 60, 6) end
	if b.lava then
		for i = 1, 8 do
			local ang = (i / 8) * math.pi * 2
			flatDecal(ground + Vector3.new(math.cos(ang), 0, math.sin(ang)) * 6, "lightning", "#FF5A1F", 8, 2, math.deg(ang))
		end
	end
	if b.coinRain then
		worldBurst(center + Vector3.new(0, 18, 0), { sprite = "coin", color = cs("#FFFFFF"), count = 60, size = ns(1.1, 1.1), speed = { 2, 6 }, spread = 180, life = { 2, 3 }, accel = Vector3.new(0, -25, 0), rotSpeed = { -400, 400 } }, 3.5)
	end
	if b.moon then billboard(center + Vector3.new(0, 14, 12), "orb", "#EAF2FF", 22, 3, 1.05) end
	if b.rainbowArc then
		for i, col in ipairs({ "#FF5A5A", "#FFB04A", "#FFE84A", "#5AFF8A", "#5AC8FF", "#8A6CFF" }) do
			billboard(center + Vector3.new(0, 4, 0), "ring", col, 24 - i * 1.6, 2.5, 1.1)
		end
	end
	if b.vortex then flatDecal(ground + Vector3.new(0, 0.1, 0), "rune_circle", "#E048C8", 10, 2.5, -540, 2.2) end
	if b.planets then
		for i = 1, 3 do
			local p = Instance.new("Part")
			p.Shape = Enum.PartType.Ball; p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
			p.Material = Enum.Material.Neon; p.Color = ({ c3("#FF9AE6"), c3("#7FC8FF"), c3("#FFD27A") })[i]
			p.Size = Vector3.one * (1 + i * 0.5); p.Parent = workspace
			local r, sp, ph = 6 + i * 2.5, 2 + i * 0.6, i * 2
			local start = os.clock()
			local conn; conn = RunService.RenderStepped:Connect(function()
				local t = os.clock() - start
				if t > 3 then conn:Disconnect(); p:Destroy(); return end
				p.Position = ground + Vector3.new(math.cos(ph + t * sp) * r, 3 + i, math.sin(ph + t * sp) * r)
				p.Transparency = math.clamp((t - 2.4) / 0.6, 0, 1)
			end)
		end
	end
	-- camera punch: shake + quick FOV zoom
	local cam = workspace.CurrentCamera
	if cam then
		local fov = cam.FieldOfView
		TweenService:Create(cam, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = fov - 10 }):Play()
		task.delay(0.12, function() TweenService:Create(cam, TweenInfo.new(0.35, Enum.EasingStyle.Back), { FieldOfView = fov }):Play() end)
	end
end

-- Anime-style power aura around the player's character (used in the belt and rebirth cutscenes).
-- Replaces any Roblox default Fire/Sparkles/Smoke effect: never use those instances.
function VFX.PlayerAura(character: Model, colorHex: string, duration: number)
	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end
	local made = {}
	local function add(i)
		table.insert(made, i)
		return i
	end
	local feet = add(Instance.new("Attachment")); feet.Position = Vector3.new(0, -2.8, 0); feet.Parent = root
	local mid = add(Instance.new("Attachment")); mid.Parent = root
	local col = c3(colorHex)
	local hot = col:Lerp(Color3.new(1, 1, 1), 0.6)
	-- 1) ring of sharp aura spikes rising around the feet (8 points on a circle), tier color outside, white-hot inside
	for k = 1, (low and 4 or 8) do
		local ang = (k / (low and 4 or 8)) * math.pi * 2
		local a = add(Instance.new("Attachment"))
		a.Position = Vector3.new(math.cos(ang) * 1.6, -2.8, math.sin(ang) * 1.6)
		a.Parent = root
		add(emitter({ sprite = "aura_flipbook", color = ColorSequence.new(col), size = ns(2.4, 3.2, 1.0), rate = 7, life = { 0.35, 0.55 },
			speed = { 6, 9 }, spread = 10, trans = ns(1, 0.1, 0.2, 1), light = 1 }, a))
		add(emitter({ sprite = "aura_flipbook", color = ColorSequence.new(hot), size = ns(1.4, 2.0, 0.5), rate = 5, life = { 0.3, 0.45 },
			speed = { 5, 7 }, spread = 8, trans = ns(1, 0.2, 1), light = 1, zOffset = 0.5 }, a))
	end
	-- 3) soft body glow + rising embers + a glowing ground ring
	add(emitter({ sprite = "glow", color = ColorSequence.new(col), size = ns(6, 7), rate = 6, life = { 0.5, 0.5 }, speed = { 0, 0 }, trans = ns(1, 0.8, 1), light = 1, lockedToPart = true }, mid))
	add(emitter({ sprite = "ember", color = ColorSequence.new(hot, col), size = ns(0.35, 0.05), rate = 40, life = { 0.8, 1.3 }, speed = { 3, 7 }, spread = 25, accel = Vector3.new(0, 6, 0), light = 1 }, feet))
	flatDecal(root.Position - Vector3.new(0, 2.9, 0), "ring", colorHex, 7, duration, nil, 1.2)
	local light = add(Instance.new("PointLight")); light.Color = col; light.Brightness = 2; light.Range = 12; light.Parent = root -- (tuned in Play: 4 overexposed the player)
	task.delay(duration, function()
		for _, i in ipairs(made) do
			if i:IsA("ParticleEmitter") then i.Enabled = false end
		end
		task.wait(0.8)
		for _, i in ipairs(made) do if i.Parent then i:Destroy() end end
	end)
end

function VFX.Dissolve(model: Model, creature: string, duration: number, handle: Handle?)
	local prof = P[creature]
	local d = prof.dissolve
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			-- blow each part apart into its tier particles while it fades
			local pe = emitter({ sprite = d.sprite, color = d.color, size = ns(1.2, 0), rate = 0, life = { 0.8, 1.4 }, speed = { 4, 10 }, spread = 180, accel = Vector3.new(0, 4, 0), light = 1 }, part)
			pe:Emit(low and 6 or 18)
			TweenService:Create(part, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Transparency = 1 }):Play()
		end
	end
	local hl = model:FindFirstChildOfClass("Highlight")
	if hl then TweenService:Create(hl, TweenInfo.new(duration), { OutlineTransparency = 1, FillTransparency = 1 }):Play() end
	task.delay(duration + 1.5, function()
		if handle then handle:Destroy() end
		model:Destroy()
	end)
end

-- the building blocks, for the belt / master belt / intro cutscenes (colors: hex or Color3)
VFX.Billboard = billboard
VFX.FlatDecal = flatDecal
VFX.WorldBurst = worldBurst
VFX.Emitter = emitter
VFX.Trail = trail
VFX.ns = ns
VFX.cs = cs

return VFX
