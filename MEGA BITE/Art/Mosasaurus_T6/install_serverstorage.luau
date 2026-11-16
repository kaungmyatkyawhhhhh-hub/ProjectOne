-- MEGA BITE: park the Mosasaurus T6 in ServerStorage (owner 16 Nov: "Studio only, not in play"). No game wiring.
local ASSET_ID = 0 -- set after the tweaked FBX is uploaded (104031266367399 = v1, before the tweaks)
local SS = game:GetService("ServerStorage")
local old = SS:FindFirstChild("MB_Mosasaurus_T6"); if old then old:Destroy() end
local m = game:GetService("InsertService"):LoadAsset(ASSET_ID)
local model = m:FindFirstChildWhichIsA("Model") or m
model.Name = "MB_Mosasaurus_T6"
for _, d in model:GetDescendants() do
	if d:IsA("MeshPart") then
		d.Anchored = true; d.CanCollide = false; d.DoubleSided = true
		if d.Name:find("Crystals") then d.Material = Enum.Material.Neon; d.Color = Color3.fromRGB(16, 251, 253) end
		if d.Name:find("Eyes") then d.Material = Enum.Material.Neon; d.Color = Color3.fromRGB(255, 236, 40) end
	end
end
model:ScaleTo(model:GetScale() * 165 / model:GetExtentsSize().X)   -- same length as evolution 9 (~165 studs)

-- VFX from the card (matches the Blender preview): cyan sparkle trail off the body, glints off the crystals, glow lights.
-- Sprite = MEGA BITE's own "flare" (white-cyan, Art/VFX/abilities sheet 1). Sizes are in studs for the 165-stud model.
local FLARE = "rbxassetid://119101480444141"
local CYAN = ColorSequence.new(Color3.fromRGB(150, 255, 255), Color3.fromRGB(16, 251, 253))
local function fade(a, b) return NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, a), NumberSequenceKeypoint.new(1, b)}) end
local body, crys, eyes = model:FindFirstChild("Mosasaurus_T6", true), model:FindFirstChild("Mosasaurus_T6_Crystals", true), model:FindFirstChild("Mosasaurus_T6_Eyes", true)
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
if crys then
	emitter(crys, "MB_CrystalGlints", {Rate = 18, Lifetime = NumberRange.new(1, 2), Speed = NumberRange.new(2, 5),
		EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(35, 35), Drag = 1,
		Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.4), NumberSequenceKeypoint.new(1, 0)}),
		Transparency = fade(0, 0.3)})
	local l = Instance.new("PointLight"); l.Name = "MB_CrystalGlow"; l.Color = Color3.fromRGB(16, 251, 253); l.Range = 40; l.Brightness = 2; l.Shadows = false; l.Parent = crys
end
if eyes then
	local l = Instance.new("PointLight"); l.Name = "MB_EyeGlow"; l.Color = Color3.fromRGB(255, 236, 40); l.Range = 10; l.Brightness = 2; l.Shadows = false; l.Parent = eyes
end
model.Parent = SS
if m ~= model then m:Destroy() end
return ("MB_Mosasaurus_T6 in ServerStorage, %d studs long"):format(model:GetExtentsSize().X)
