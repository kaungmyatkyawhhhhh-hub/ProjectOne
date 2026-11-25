--[[
	FlatWindows (2026-11-26, owner: "make the windows see through like glass and if u click on it, it becomes blurry,
	and if u click on the blurry glass, it becomes slightly clear and see through").
	The Myittar Nyunt flat's window panes (tag FlatWindowPane, attribute Win = which window, made by
	tools/yangon/MyittarNyuntBlock.luau with a ClickDetector each) start clear; a click or tap on any pane of a window
	turns all its panes frosted, the next one clear again. Server side, so every player sees the same window.
	One script for every window. The click is the game's UI tick (Audio.click: volume_slider, 0.35, speed 1.6).
]]

local CollectionService = game:GetService("CollectionService")

local TAG = "FlatWindowPane"
local CLEAR = { Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(205, 225, 222), Transparency = 0.6, Reflectance = 0.12 }
local FROST = { Material = Enum.Material.Glass, Color = Color3.fromRGB(225, 230, 232), Transparency = 0.2, Reflectance = 0 }
local COOLDOWN = 0.25

local frosted = {} -- window id -> true
local last = {} -- window id -> os.clock() of its last switch

local function look(p: BasePart, on: boolean)
	local s = if on then FROST else CLEAR
	p.Material = s.Material
	p.Color = s.Color
	p.Transparency = s.Transparency
	p.Reflectance = s.Reflectance
end

local function panesOf(id: string): { BasePart }
	local out = {}
	for _, p in CollectionService:GetTagged(TAG) do
		if p:IsA("BasePart") and p:GetAttribute("Win") == id then
			table.insert(out, p)
		end
	end
	return out
end

local function click(p: BasePart)
	local s = Instance.new("Sound")
	s.SoundId = "rbxasset://sounds/volume_slider.ogg"
	s.Volume = 0.35
	s.PlaybackSpeed = 1.6
	s.RollOffMaxDistance = 40
	s.Parent = p
	s:Play()
	s.Ended:Once(function()
		s:Destroy()
	end)
	task.delay(3, function()
		if s.Parent then
			s:Destroy()
		end
	end)
end

local function toggle(p: BasePart)
	local id = p:GetAttribute("Win")
	if typeof(id) ~= "string" then
		return
	end
	local now = os.clock()
	if last[id] and now - last[id] < COOLDOWN then
		return
	end
	last[id] = now
	frosted[id] = not frosted[id]
	for _, q in panesOf(id) do
		look(q, frosted[id])
	end
	click(p)
end

local function add(p: Instance)
	if not p:IsA("BasePart") then
		return
	end
	local id = p:GetAttribute("Win")
	look(p, typeof(id) == "string" and frosted[id] == true)
	local cd = p:FindFirstChildOfClass("ClickDetector")
	if not cd then
		cd = Instance.new("ClickDetector")
		cd.MaxActivationDistance = 16
		cd.Parent = p
	end
	cd.MouseClick:Connect(function()
		toggle(p)
	end)
end

for _, p in CollectionService:GetTagged(TAG) do
	add(p)
end

-- Studio test hook (Play only, never live): ServerStorage.FlatWindowsTest:Invoke(windowId) switches that window
if game:GetService("RunService"):IsStudio() then
	local f = Instance.new("BindableFunction")
	f.Name = "FlatWindowsTest"
	f.OnInvoke = function(id: string)
		local ps = panesOf(id)
		if ps[1] then
			last[id] = nil
			toggle(ps[1])
		end
		return frosted[id] == true, #ps
	end
	f.Parent = game:GetService("ServerStorage")
end
CollectionService:GetInstanceAddedSignal(TAG):Connect(add)
