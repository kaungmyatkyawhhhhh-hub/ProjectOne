-- MEGA BITE: park the Livyatan T6 in ServerStorage, Studio only, no game wiring (same as the Mosasaurus T6).
-- NOT RUN YET: upload export/Livyatan_T6.fbx first (owner approves in Blender before that), then set ASSET_ID.
local ASSET_ID = 0
local SS = game:GetService("ServerStorage")
local old = SS:FindFirstChild("MB_Livyatan_T6"); if old then old:Destroy() end
local m = game:GetService("InsertService"):LoadAsset(ASSET_ID)
local model = m:FindFirstChildWhichIsA("Model") or m
model.Name = "MB_Livyatan_T6"
for _, d in model:GetDescendants() do
	if d:IsA("MeshPart") then
		d.Anchored = true; d.CanCollide = false; d.DoubleSided = true
		-- the runes are modelled raised inlays (their own meshes), so Neon makes the real geometry glow
		if d.Name:find("RunesCyan") then d.Material = Enum.Material.Neon; d.Color = Color3.fromRGB(40, 240, 255) end
		if d.Name:find("RunesGold") then d.Material = Enum.Material.Neon; d.Color = Color3.fromRGB(255, 196, 70) end
		if d.Name:find("_Eye") then d.Material = Enum.Material.Neon; d.Color = Color3.fromRGB(60, 250, 255) end
	end
end
model:ScaleTo(model:GetScale() * 165 / model:GetExtentsSize().X)   -- same length as the other Tier 6 (Mosasaurus, ~165 studs)

-- VFX from the card notes (OUTLINES, BLUE AURA, sparkle trail): gold + cyan sparkle trail, blue aura, rune and eye glow, outline.
-- Sprite = MEGA BITE's own "flare" (white-cyan, Art/VFX/abilities sheet 1). Sizes are in studs for the 165-stud model.
local FLARE = "rbxassetid://119101480444141"
local CYAN = ColorSequence.new(Color3.fromRGB(150, 255, 255), Color3.fromRGB(16, 251, 253))
local function fade(a, b) return NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, a), NumberSequenceKeypoint.new(1, b)}) end
local body, crys, gold, eyes = model:FindFirstChild("Livyatan_T6", true), model:FindFirstChild("Livyatan_T6_RunesCyan", true), model:FindFirstChild("Livyatan_T6_RunesGold", true), model:FindFirstChild("Livyatan_T6_Eye", true)
local GOLD = ColorSequence.new(Color3.fromRGB(255, 235, 160), Color3.fromRGB(255, 190, 60))
local function emitter(part, name, props)
	local e = Instance.new("ParticleEmitter"); e.Name = name
	e.Texture = FLARE; e.Color = CYAN; e.LightEmission = 1; e.LightInfluence = 0
	e.Shape = Enum.ParticleEmitterShape.Box; e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	e.LockedToPart = false                          -- world space: the sparkles stay behind as it swims = the trail
	e.Rotation = NumberRange.new(0, 360); e.RotSpeed = NumberRange.new(-60, 60)
	for k, v in props do e[k] = v end
	e.Parent = part; return e
end
if body then
	emitter(body, "MB_SparkleTrail", {Rate = 70, Lifetime = NumberRange.new(1.5, 3), Speed = NumberRange.new(1, 4),
		SpreadAngle = Vector2.new(180, 180), Drag = 1.5, Acceleration = Vector3.new(0, -1.5, 0),
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(0.5, 1.2), NumberSequenceKeypoint.new(1, 0)}),
		Transparency = fade(0, 0.4)})
end
if gold then   -- the card's trail is gold AND cyan
	emitter(gold, "MB_GoldTrail", {Color = GOLD, Rate = 45, Lifetime = NumberRange.new(1.5, 3), Speed = NumberRange.new(1, 4),
		SpreadAngle = Vector2.new(180, 180), Drag = 1.5, Acceleration = Vector3.new(0, -1.5, 0),
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(0.5, 1.2), NumberSequenceKeypoint.new(1, 0)}),
		Transparency = fade(0, 0.4)})
end
if body then   -- BLUE AURA: big soft blue glow that stays on the body
	emitter(body, "MB_BlueAura", {Color = ColorSequence.new(Color3.fromRGB(40, 140, 255)), LockedToPart = true, Rate = 12,
		Lifetime = NumberRange.new(1.2, 1.8), Speed = NumberRange.new(0, 0.5), LightEmission = 0.6,
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 10), NumberSequenceKeypoint.new(1, 14)}),
		Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.4, 0.85), NumberSequenceKeypoint.new(1, 1)})})
end
if crys then
	local l = Instance.new("PointLight"); l.Name = "MB_RuneGlow"; l.Color = Color3.fromRGB(40, 240, 255); l.Range = 40; l.Brightness = 2; l.Shadows = false; l.Parent = crys
end
if eyes then
	local l = Instance.new("PointLight"); l.Name = "MB_EyeGlow"; l.Color = Color3.fromRGB(60, 250, 255); l.Range = 10; l.Brightness = 2; l.Shadows = false; l.Parent = eyes
end
local h = Instance.new("Highlight"); h.Name = "MB_CardOutline"   -- the card's thin cyan outline
h.FillTransparency = 1; h.OutlineColor = Color3.fromRGB(120, 255, 255); h.OutlineTransparency = 0.15
h.DepthMode = Enum.HighlightDepthMode.Occluded; h.Parent = model
model.Parent = SS
if m ~= model then m:Destroy() end
return ("MB_Livyatan_T6 in ServerStorage, %d studs long"):format(model:GetExtentsSize().X)
