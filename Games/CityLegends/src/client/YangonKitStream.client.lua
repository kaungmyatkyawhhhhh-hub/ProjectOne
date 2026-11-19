--[[
	YangonKitStream (2026-11-16, light pass of the 1:1 Yangon buildings): builds the kit detail of the 256-stud tiles near
	the camera on this client, and hides those tiles' shells.

	The place keeps only each building's shell (Workspace.Yangon1to1.Buildings.Shell: boxes in the wall colour that are
	also its collision, plus the pitched roofs). The detail is data (ReplicatedStorage.YgnKit.Data_<district>, decoded
	by Shared.YangonKitData) made from the shared kit templates (ReplicatedStorage.YgnKit.Templates). A tile is built
	when its middle comes within LOAD studs of the camera and taken down past UNLOAD; building runs a few ms a frame,
	nearest tiles first. While a tile is built its shells are hidden on this client only (LocalTransparencyModifier;
	collision and camera rays still use them). Visual parts only: no collision, no rays, no touches.
	Studio test hook: player attribute KitStreamOff = true takes everything down and stops.
	(2026-11-18, Settings > Render distance) player attribute RenderDist (MainMenu: 0.5 / 0.75 / 1 / 1.5, nil = 1)
	multiplies every folder's LOAD; a change re-checks the tiles at once (loads or takes down).
	(2026-11-16, the street detail layer) a data folder whose Meta has LOAD=<studs> (Data_<district>S: poles, cables,
	lamps, signals, stops, stalls ...) is built within its own radius; its tiles are keyed "S<i>_<j>" and hide no shells.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LOAD = 1000
local UNLOAD = 1150
local FRAME_MS = 3.0 -- building time a frame
local STEP_PARTS = 60

local root = ReplicatedStorage:WaitForChild("YgnKit", 60)
if not root then
	return
end
local shared = ReplicatedStorage:WaitForChild("Shared", 60)
local kdModule = shared and shared:WaitForChild("YangonKitData", 60)
if not kdModule then
	warn("YangonKitStream: Shared.YangonKitData missing")
	return
end
local KD = require(kdModule)
local templates = root:WaitForChild("Templates", 60)
if not templates then
	return
end
local T = KD.index(templates)

-- tiles: key "i_j" -> { { s, meta }, ... } (two districts may share a tile on their border)
local tiles = {}
local centre = {}
local loadOf = {} -- key -> its build radius
local tileSize = 256
local prefixes = { [""] = LOAD }
local function addData(folder: Instance)
	local meta = KD.meta(folder)
	if not meta then
		return
	end
	tileSize = meta.tile
	local pre = if meta.load then "S" else ""
	if meta.load then
		prefixes[pre] = meta.load
	end
	for _, v in folder:GetChildren() do
		if v:IsA("StringValue") and v.Name ~= "Meta" then
			local i, j = string.match(v.Name, "^(%-?%d+)_(%-?%d+)$")
			if i then
				local key = pre .. v.Name
				tiles[key] = tiles[key] or {}
				table.insert(tiles[key], { s = v.Value, meta = meta, i = tonumber(i), j = tonumber(j) })
				centre[key] = Vector2.new((tonumber(i) + 0.5) * meta.tile, (tonumber(j) + 0.5) * meta.tile)
				loadOf[key] = meta.load or LOAD
			end
		end
	end
end
for _, f in root:GetChildren() do
	if f:IsA("Folder") and string.sub(f.Name, 1, 5) == "Data_" then
		addData(f)
	end
end

-- (2026-11-17, the venues on the 1:1 map) nothing is built inside the boxes of ReplicatedStorage.YgnKit.KeepOut (venue lots
-- and the buildings their lots replaced, tools/yangon/YangonSites.luau): those parts are taken out once a tile is built
local keepOut = {}
do
	local ko = root:FindFirstChild("KeepOut")
	for _, b in (if ko then ko:GetChildren() else {}) do
		if b:IsA("BasePart") then
			table.insert(keepOut, { cf = b.CFrame:Inverse(), hx = b.Size.X / 2, hz = b.Size.Z / 2, c = Vector2.new(b.Position.X, b.Position.Z), r = Vector2.new(b.Size.X, b.Size.Z).Magnitude / 2 })
		end
	end
end
local function clearKeepOut(f: Instance, key: string)
	local mine = {}
	for _, k in keepOut do
		if (k.c - centre[key]).Magnitude < k.r + 400 then -- (a tile is at most 256 across)
			table.insert(mine, k)
		end
	end
	if #mine == 0 then
		return
	end
	for _, d in f:GetDescendants() do
		if d:IsA("BasePart") then
			for _, k in mine do
				local l = k.cf * d.Position
				if math.abs(l.X) < k.hx and math.abs(l.Z) < k.hz then
					d:Destroy()
					break
				end
			end
		end
	end
end

local near = Instance.new("Folder")
near.Name = "YgnKitNear"
near.Parent = workspace

-- shells by tile (they stream in and out with StreamingEnabled)
local shells = {} -- key -> { [part] = true }
local built = {} -- key -> true once built
local function hide(q: BasePart, on: boolean)
	q.LocalTransparencyModifier = if on then 1 else 0
	for _, t in q:GetChildren() do
		if t:IsA("Texture") or t:IsA("Decal") then
			t.Transparency = if on then 1 else 0
		end
	end
end
local function watchShells(folder: Instance)
	local function add(d: Instance)
		if d:IsA("BasePart") then
			local key = d:GetAttribute("T")
			if key then
				shells[key] = shells[key] or {}
				shells[key][d] = true
				if built[key] then
					hide(d, true)
				end
			end
		end
	end
	for _, d in folder:GetDescendants() do
		add(d)
	end
	folder.DescendantAdded:Connect(add)
	folder.DescendantRemoving:Connect(function(d)
		local key = d:GetAttribute("T")
		if key and shells[key] then
			shells[key][d] = nil
		end
	end)
end
task.spawn(function()
	local y = workspace:WaitForChild("Yangon1to1", 120)
	local b = y and y:WaitForChild("Buildings", 60)
	local sh = b and b:WaitForChild("Shell", 60)
	if sh then
		watchShells(sh)
	end
end)
-- (2026-11-16, greenery) the far looks of the big trees (Workspace.Yangon1to1.Green.Far, attribute T) hide the same way
-- once their tile's real trees (ReplicatedStorage.YgnKit.Data_<district>G) are built
task.spawn(function()
	local y = workspace:WaitForChild("Yangon1to1", 120)
	local g = y and y:WaitForChild("Green", 60)
	local far = g and g:WaitForChild("Far", 60)
	if far then
		watchShells(far)
	end
end)

local folders = {} -- key -> Folder
local jobs = {} -- key -> { job, job, ... }, k
local queue = {} -- keys waiting, nearest first

local function setShells(key: string, on: boolean)
	local set = shells[key]
	if set then
		for q in set do
			hide(q, on)
		end
	end
end

local function unload(key: string)
	if folders[key] then
		folders[key]:Destroy()
		folders[key] = nil
	end
	jobs[key] = nil
	if built[key] then
		built[key] = nil
		setShells(key, false)
	end
end

local stopped = false
local lastPos: Vector3? = nil
local mult = 1
local function readMult()
	local plr = Players.LocalPlayer
	local v = plr and plr:GetAttribute("RenderDist")
	mult = if type(v) == "number" and v > 0 then v else 1
	lastPos = nil -- (re-check the tiles on the next beat)
end
if Players.LocalPlayer then
	readMult()
	Players.LocalPlayer:GetAttributeChangedSignal("RenderDist"):Connect(readMult)
end
local function refresh()
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local p = cam.CFrame.Position
	lastPos = p
	local here = Vector2.new(p.X, p.Z)
	for key in folders do
		if (centre[key] - here).Magnitude > loadOf[key] * mult + (UNLOAD - LOAD) then
			unload(key)
		end
	end
	table.clear(queue)
	local r = math.ceil(LOAD * mult / tileSize) + 1
	local ci, cj = math.floor(p.X / tileSize), math.floor(p.Z / tileSize)
	for i = ci - r, ci + r do
		for j = cj - r, cj + r do
			for pre in prefixes do
				local key = pre .. i .. "_" .. j
				if tiles[key] and not folders[key] and (centre[key] - here).Magnitude <= loadOf[key] * mult then
					table.insert(queue, key)
				end
			end
		end
	end
	table.sort(queue, function(a, b)
		return (centre[a] - here).Magnitude < (centre[b] - here).Magnitude
	end)
end

local acc = 0
RunService.Heartbeat:Connect(function(dt)
	if stopped then
		return
	end
	local plr = Players.LocalPlayer
	if plr and plr:GetAttribute("KitStreamOff") then
		stopped = true
		for key in folders do
			unload(key)
		end
		return
	end
	acc += dt
	local cam = workspace.CurrentCamera
	if (acc > 0.3 or not lastPos) and cam and (not lastPos or (cam.CFrame.Position - lastPos).Magnitude > 24) then
		acc = 0
		refresh()
	end
	local t0 = os.clock()
	-- start the nearest waiting tile, then keep building until the frame's budget is spent
	while (os.clock() - t0) * 1000 < FRAME_MS do
		local key = next(jobs)
		if not key then
			local nk = table.remove(queue, 1)
			if not nk then
				break
			end
			local f = Instance.new("Folder")
			f.Name = nk
			f.Parent = near
			folders[nk] = f
			local list = {}
			for _, d in tiles[nk] do
				table.insert(list, KD.job(d.s, d.i, d.j, d.meta, T, f))
			end
			jobs[nk] = list
			key = nk
		end
		local list = jobs[key]
		local job = list[1]
		if job == nil or job:step(STEP_PARTS, t0 + FRAME_MS / 1000) then
			if job then
				table.remove(list, 1)
			end
			if #list == 0 then
				jobs[key] = nil
				clearKeepOut(folders[key], key)
				built[key] = true
				setShells(key, true)
			end
		end
	end
end)
