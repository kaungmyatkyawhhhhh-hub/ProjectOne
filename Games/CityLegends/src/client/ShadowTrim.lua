--!strict
--[[ ShadowTrim (28 Nov, lag cuts round 2; vault `City Legends/2026-11-27 Terrain low-detail when lagging.md`)
The shadow pass redraws every caster. On the Yangon map 19,884 streamed parts cast shadows, most of them small
props and trim whose shadow nobody sees. On this screen only, a part stops casting when:
  * its biggest size is under 3 studs (trim, frames, sign plates, cable pieces, small props), or
  * it stands under 6 studs tall in the world (flat roads / slabs / markings, bins, carts, stalls, fences, kerbs),
unless it is (in) a tree, palm or lamp. Buildings, walls and poles are taller; people (YangonStreetLife), traffic
and player cars live in other folders and are never touched. Watches the map folders so streamed / client-built
parts obey it too. ]]
local ShadowTrim = {}

local FOLDERS = { "Yangon1to1", "YgnKitNear", "YangonRoadside", "YangonMedians", "City" }
local KEEP = { "tree", "palm", "lamp", "leaf", "trunk" }

-- (owner, 27 Nov: "dont do anything to car") any part inside a car model (showroom, parked, venue display) is left as is
local function isCar(m: Instance): boolean
	return m:IsA("Model") and (m:FindFirstChild("Chassis") ~= nil or m:FindFirstChild("Wheels") ~= nil
		or m:FindFirstChild("DriveSeat") ~= nil or m:FindFirstChildWhichIsA("VehicleSeat") ~= nil or m:GetAttribute("CarId") ~= nil)
end

local function kept(p: Instance): boolean
	local x: Instance? = p
	local depth = 0
	while x and x ~= workspace do
		if depth < 4 then
			local n = string.lower(x.Name)
			for _, k in KEEP do
				if string.find(n, k, 1, true) then
					return true
				end
			end
		end
		if isCar(x) then
			return true
		end
		x = x.Parent
		depth += 1
	end
	return false
end

-- true when this part's shadow is not worth drawing
function ShadowTrim.trims(p: BasePart): boolean
	local cf, h = p.CFrame, p.Size / 2
	local ey = math.abs(cf.RightVector.Y) * h.X + math.abs(cf.UpVector.Y) * h.Y + math.abs(cf.LookVector.Y) * h.Z
	local big = math.max(p.Size.X, p.Size.Y, p.Size.Z)
	-- (ey is half the world height: under 3 = under 6 studs tall, flat pieces included)
	return (big < 3 or ey < 3) and not kept(p)
end

local function one(d: Instance)
	if d:IsA("BasePart") and d.CastShadow and ShadowTrim.trims(d) then
		d.CastShadow = false
	end
end

local watched: { [Instance]: boolean } = {}
local function watch(f: Instance)
	if watched[f] then
		return
	end
	watched[f] = true
	f.DescendantAdded:Connect(one)
	task.spawn(function()
		for i, d in f:GetDescendants() do
			one(d)
			if i % 4000 == 0 then
				task.wait()
			end
		end
	end)
end

function ShadowTrim.start()
	for _, name in FOLDERS do
		local f = workspace:FindFirstChild(name)
		if f then
			watch(f)
		end
	end
	workspace.ChildAdded:Connect(function(c)
		if table.find(FOLDERS, c.Name) then
			watch(c)
		end
	end)
end

return ShadowTrim
