--!nocheck
-- random_textures.luau (roblox-game-lighting skill)
-- The Develuper "random textures" trick: pick 3-4 similar textures; every map part gets a random one on all 6 faces,
-- plus a small random tone change on its colour. Big flat areas stop looking copy-pasted.
-- Run with the Studio MCP execute_luau in the Edit datamodel (or paste into the command bar).
--
-- TARGET: what to texture. "selection" = the parts selected in Studio (and their descendants),
--         or a path string like "Workspace.Map.Rocks", or a CollectionService tag "tag:Rocky".
-- MODE:   "APPLY" | "UNDO" (removes only textures this script made and puts the old colours back)
-- Undo data lives on the parts as attributes (RT_OrigColor) and textures are named RT_Texture.
--
-- Best on blocky Parts (stud / brick / obby maps, like the video). On low-poly MeshPart art the textures project per
-- box face and barely show (tested on MEGA BITE's reef, 9,000 MeshParts: no visible change); the tone variation
-- still helps there, so for mesh maps set TRANSPARENCY = 1 or remove the texture loop and keep only the tone nudge.
-- Tested 14 Nov 2026: 528 parts / 3,168 textures in one run, all four video IDs load, UNDO puts back every colour.

local MODE = "APPLY"
local TARGET = "selection"
local TEXTURES = { -- the four from the video; swap in your own set (similar textures, same scale)
	"rbxassetid://10044626935",
	"rbxassetid://10025439383",
	"rbxassetid://10024249523",
	"rbxassetid://10025395487",
}
local TRANSPARENCY = 0.675   -- video value; 0.6-0.8 keeps the part colour in charge
local STUDS_PER_TILE = 7     -- video value
local TONE_STEPS = {-0.12, -0.05, 0.05, 0.175} -- added to the colour's brightness (HSV value), one picked per part
local SKIP_SMALLER_THAN = 2  -- studs: tiny props don't need it (and each Texture costs draw time)
local MAX_PARTS = 3000
local SEED = 7               -- same seed = same result every run

local CollectionService = game:GetService("CollectionService")
local Selection = game:GetService("Selection")
local rng = Random.new(SEED)

local function resolve(target)
	if target == "selection" then return Selection:Get() end
	if target:sub(1, 4) == "tag:" then return CollectionService:GetTagged(target:sub(5)) end
	local obj = game
	for _, name in string.split(target, ".") do
		obj = obj:FindFirstChild(name) or (obj == game and game:GetService(name))
		if not obj then return {} end
	end
	return {obj}
end

local parts = {}
for _, root in resolve(TARGET) do
	if root:IsA("BasePart") then table.insert(parts, root) end
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then table.insert(parts, d) end
	end
end
if #parts == 0 then return "nothing found for TARGET " .. TARGET end
if #parts > MAX_PARTS then return ("%d parts > MAX_PARTS %d: narrow TARGET or raise the cap"):format(#parts, MAX_PARTS) end

local done, skipped, undone = 0, 0, 0
for _, p in parts do
	if MODE == "UNDO" then
		for _, t in p:GetChildren() do
			if t:IsA("Texture") and t.Name == "RT_Texture" then t:Destroy() end
		end
		local orig = p:GetAttribute("RT_OrigColor")
		if orig then
			p.Color = orig
			p:SetAttribute("RT_OrigColor", nil)
			undone += 1
		end
	else
		local s = p.Size
		local skip = math.max(s.X, s.Y, s.Z) < SKIP_SMALLER_THAN
			or p.Transparency >= 0.9 or p:IsA("Terrain") or p:FindFirstChild("RT_Texture")
		if skip then
			skipped += 1
		else
			local id = TEXTURES[rng:NextInteger(1, #TEXTURES)]
			for _, face in Enum.NormalId:GetEnumItems() do
				local t = Instance.new("Texture")
				t.Name = "RT_Texture"
				t.Texture = id
				t.Face = face
				t.Transparency = TRANSPARENCY
				t.StudsPerTileU = STUDS_PER_TILE
				t.StudsPerTileV = STUDS_PER_TILE
				t.Parent = p
			end
			if p:GetAttribute("RT_OrigColor") == nil then p:SetAttribute("RT_OrigColor", p.Color) end
			local h, sat, v = p:GetAttribute("RT_OrigColor"):ToHSV()
			local step = TONE_STEPS[rng:NextInteger(1, #TONE_STEPS)]
			p.Color = Color3.fromHSV(h, sat, math.clamp(v + step, 0, 1))
			done += 1
		end
	end
end
if MODE == "UNDO" then return ("undo: %d parts restored"):format(undone) end
return ("textured %d parts (%d textures), skipped %d. Undo: MODE = \"UNDO\" with the same TARGET."):format(done, done * 6, skipped)
