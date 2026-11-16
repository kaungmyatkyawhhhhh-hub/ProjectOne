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
model.Parent = SS
if m ~= model then m:Destroy() end
return ("MB_Mosasaurus_T6 in ServerStorage, %d studs long"):format(model:GetExtentsSize().X)
