--[[
	YangonEditPreview (2026-11-16, owner: "all the buildings in roblox studio look like the ones in game (not some random
	blocks)"): a LOCAL Studio plugin that does in Edit what src/client/YangonKitStream.client.lua does in Play. Every
	~0.3 s it looks at Studio's camera and builds the kit detail (ReplicatedStorage.YgnKit.Data_<district>: buildings,
	street props Data_<d>S within their own Meta LOAD, near trees Data_<d>G) of the 256-stud tiles within LOAD studs,
	and hides those tiles' shells (Workspace.Yangon1to1.Buildings.Shell) and far trees (Yangon1to1.Green.Far) with
	LocalTransparencyModifier, which is never saved. Tiles past UNLOAD are taken down and their shells shown again.

	Nothing it makes is ever saved or sent to Team Create: everything lives in workspace.CurrentCamera._YgnEditPreview
	(the Studio camera's children are local to this Studio; the folder is Archivable = false, so a save skips it and
	all under it). Decals / Textures on hidden shells get LocalTransparencyModifier too (their Transparency is saved:
	never touched). Builds at most FRAME_MS a frame. Off in Play, off in places without Workspace.Yangon1to1 and
	ReplicatedStorage.YgnKit. Toolbar button "Yangon preview" switches it off / on (remembered).

	Install: copy this file to %LOCALAPPDATA%\Roblox\Plugins\YangonEditPreview.lua and restart Studio (or Plugins tab
	-> Plugins Folder, put it there, restart). Same code runs from execute_luau for a test (`plugin` is nil there:
	_G.YgnEditPreviewStop() stops it).
]]

local LOAD = 1000
local UNLOAD = 1150
local FRAME_MS = 3.0
local STEP_PARTS = 60

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local thePlugin = (typeof(plugin) == "Instance") and plugin or nil
if RunService:IsRunning() or not RunService:IsEdit() then
	return
end

local enabled = true
if thePlugin then
	local ok, v = pcall(function()
		return thePlugin:GetSetting("YgnEditPreviewOn")
	end)
	if ok and v == false then
		enabled = false
	end
end

local state = nil -- the running preview (nil when off)

local function start()
	local root = ReplicatedStorage:FindFirstChild("YgnKit")
	local shared = ReplicatedStorage:FindFirstChild("Shared")
	local kdModule = shared and shared:FindFirstChild("YangonKitData")
	local y1 = workspace:FindFirstChild("Yangon1to1")
	local templates = root and root:FindFirstChild("Templates")
	if not (root and kdModule and y1 and templates) then
		return nil
	end
	local KD = require(kdModule:Clone()) -- a fresh copy: Edit's require cache can hold an old one
	local T = KD.index(templates)

	local S = { alive = true, conns = {} }
	local tiles, centre, loadOf = {}, {}, {}
	local tileSize = 256
	local prefixes = { [""] = LOAD }
	for _, folder in root:GetChildren() do
		if folder:IsA("Folder") and string.sub(folder.Name, 1, 5) == "Data_" then
			local meta = KD.meta(folder)
			if meta then
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
		end
	end

	local cam = workspace.CurrentCamera
	local near = Instance.new("Folder")
	near.Name = "_YgnEditPreview"
	near.Archivable = false
	near.Parent = cam

	local shells, built = {}, {}
	local function hide(q: BasePart, on: boolean)
		q.LocalTransparencyModifier = if on then 1 else 0
		for _, t in q:GetChildren() do
			if t:IsA("Decal") then -- Texture is a Decal
				t.LocalTransparencyModifier = if on then 1 else 0
			end
		end
	end
	local function watch(folder: Instance)
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
		table.insert(S.conns, folder.DescendantAdded:Connect(add))
		table.insert(S.conns, folder.DescendantRemoving:Connect(function(d)
			local key = d:GetAttribute("T")
			if key and shells[key] then
				shells[key][d] = nil
			end
		end))
	end
	local b = y1:FindFirstChild("Buildings")
	if b and b:FindFirstChild("Shell") then
		watch(b.Shell)
	end
	local g = y1:FindFirstChild("Green")
	if g and g:FindFirstChild("Far") then
		watch(g.Far)
	end

	local folders, jobs, queue = {}, {}, {}
	local function setShells(key: string, on: boolean)
		local set = shells[key]
		if set then
			for q in set do
				if q.Parent then
					hide(q, on)
				end
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
	local lastPos = nil
	local function refresh()
		local c = workspace.CurrentCamera
		if not c then
			return
		end
		if near.Parent ~= c then
			near.Parent = c
		end
		local p = c.CFrame.Position
		lastPos = p
		local here = Vector2.new(p.X, p.Z)
		for key in folders do
			if (centre[key] - here).Magnitude > loadOf[key] + (UNLOAD - LOAD) then
				unload(key)
			end
		end
		table.clear(queue)
		local maxLoad = LOAD
		for _, l in prefixes do
			maxLoad = math.max(maxLoad, l)
		end
		local r = math.ceil(maxLoad / tileSize) + 1
		local ci, cj = math.floor(p.X / tileSize), math.floor(p.Z / tileSize)
		for i = ci - r, ci + r do
			for j = cj - r, cj + r do
				for pre in prefixes do
					local key = pre .. i .. "_" .. j
					if tiles[key] and not folders[key] and (centre[key] - here).Magnitude <= loadOf[key] then
						table.insert(queue, key)
					end
				end
			end
		end
		table.sort(queue, function(a, b2)
			return (centre[a] - here).Magnitude < (centre[b2] - here).Magnitude
		end)
	end

	function S.stop()
		S.alive = false
		for _, c in S.conns do
			c:Disconnect()
		end
		for key in folders do
			unload(key)
		end
		for key in built do
			setShells(key, false)
		end
		near:Destroy()
	end

	task.spawn(function()
		local acc = 0
		while S.alive do
			local dt = task.wait()
			if not S.alive then
				break
			end
			if RunService:IsRunning() then
				continue
			end
			acc += dt
			local c = workspace.CurrentCamera
			if acc > 0.3 and c and (not lastPos or (c.CFrame.Position - lastPos).Magnitude > 24) then
				acc = 0
				refresh()
			end
			local t0 = os.clock()
			while (os.clock() - t0) * 1000 < FRAME_MS do
				local key = next(jobs)
				if not key then
					local nk = table.remove(queue, 1)
					if not nk then
						break
					end
					local f = Instance.new("Folder")
					f.Name = nk
					f.Archivable = false
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
				if job == nil or job:step(STEP_PARTS) then
					if job then
						table.remove(list, 1)
					end
					if #list == 0 then
						jobs[key] = nil
						built[key] = true
						setShells(key, true)
					end
				end
			end
		end
	end)
	return S
end

local function setOn(on: boolean)
	if on and not state then
		local ok, s = pcall(start)
		if ok then
			state = s
		else
			warn("YangonEditPreview: " .. tostring(s))
		end
	elseif not on and state then
		state.stop()
		state = nil
	end
end

if thePlugin then
	local toolbar = thePlugin:CreateToolbar("Yangon")
	local button = toolbar:CreateButton("Yangon preview", "Show the game's building detail round the Studio camera", "")
	button.ClickableWhenViewportHidden = true
	button:SetActive(enabled)
	button.Click:Connect(function()
		enabled = not enabled
		button:SetActive(enabled)
		pcall(function()
			thePlugin:SetSetting("YgnEditPreviewOn", enabled)
		end)
		setOn(enabled)
	end)
	thePlugin.Unloading:Connect(function()
		setOn(false)
	end)
	-- the place's data may arrive after the plugin loads (Team Create): try until it is there
	task.spawn(function()
		for _ = 1, 120 do
			if state or not enabled then
				if state then
					break
				end
			else
				setOn(true)
			end
			task.wait(5)
		end
	end)
else
	if _G.YgnEditPreviewStop then
		_G.YgnEditPreviewStop()
	end
	setOn(true)
	_G.YgnEditPreviewStop = function()
		setOn(false)
		_G.YgnEditPreviewStop = nil
	end
	return state ~= nil
end
