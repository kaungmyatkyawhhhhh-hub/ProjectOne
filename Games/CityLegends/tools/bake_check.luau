--!nocheck
-- Checks the baked map in Studio (run it in the Edit place: Studio's command bar, or the Roblox
-- Studio MCP's execute_luau). Lune can't open the owner's Studio-saved place on the PC, so this is
-- the bake test: the map is there and marked baked, every lane has road under it and nothing solid
-- stands in one, the tags the client needs survived, terrain water is there.
local CS = game:GetService("CollectionService")
local CityLayout = require(game.ReplicatedStorage.Shared.CityLayout)

local city = workspace:FindFirstChild("City")
assert(city, "no Workspace.City: the map isn't baked")
assert(city:GetAttribute("Baked"), "Workspace.City has no Baked attribute")
assert(not city:GetAttribute("Ready"), "a baked City must not be saved Ready (the venues set it at start)")

local out = {}
local parts = 0
for _, d in city:GetDescendants() do
	if d:IsA("BasePart") then
		parts += 1
	end
end
table.insert(out, `parts {parts} (about 136,000 baked; the venues add ~16,000 at start)`)

for _, t in { "LOD", "LODLight", "DayOff", "TrafficLamp", "Blink", "AnimatedBoard" } do
	local n = #CS:GetTagged(t)
	assert(n > 0, "no " .. t .. " tags")
	table.insert(out, `{t} {n}`)
end

local graph = CityLayout.buildGraph()
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = { city }
local missing, blocked, checked = 0, 0, 0
for i, seg in graph.all do
	for k = 0, 8 do
		local p = CityLayout.sample(seg, seg.length * k / 8)
		checked += 1
		local under = workspace:Raycast(p + Vector3.new(0, 3, 0), Vector3.new(0, -6, 0), params)
		if not (under and under.Instance.CanCollide) then
			missing += 1
		end
		local above = workspace:Raycast(p + Vector3.new(0, 7, 0), Vector3.new(0, -4.5, 0), params)
		if above and above.Instance.CanCollide then
			blocked += 1
		end
	end
	if i % 300 == 0 then
		task.wait()
	end
end
assert(missing == 0, `{missing} of {checked} lane points have no road under them`)
assert(blocked == 0, `{blocked} lane points have something solid in the way`)
table.insert(out, `lanes ok ({checked} points)`)

local voxels = workspace.Terrain:ReadVoxels(Region3.new(Vector3.new(-4000, -16, -100), Vector3.new(4000, 0, 100)):ExpandToGrid(4), 4)
local water = 0
for x = 1, voxels.Size.X, 8 do
	for y = 1, voxels.Size.Y do
		for z = 1, voxels.Size.Z, 4 do
			if voxels[x][y][z] == Enum.Material.Water then
				water += 1
			end
		end
	end
end
assert(water > 0, "no terrain water")
table.insert(out, "terrain water ok")
print("[bake_check] OK: " .. table.concat(out, ", "))
return table.concat(out, "\n")
