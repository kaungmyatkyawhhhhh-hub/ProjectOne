--[[
	Openables (2026-11-26, owner: "make it so that i can open & close the entrance of that apartment room & it has to be
	satisfying on closing and opening everything in the game interactable").
	One server script for every door, cabinet door, fridge door, drawer and folding gate tagged "Openable" (made by
	tools/yangon/MyittarNyuntBlock.luau). A Model tagged Openable holds its parts and one invisible "Hinge" part:
	  Kind = "hinge"  : the parts turn about the Hinge part's up axis by Angle degrees (built pose -> other pose)
	  Kind = "drawer" : the parts slide by SlideL (studs, in the Hinge part's own axes)
	  Kind = "gate"   : each part with a GateFold attribute (Vector3, Hinge axes) slides by it; parts with LatticeX
	                    show only while the gate is closed
	  BuiltOpen = the built pose is the open one; Sound = door | cabinet | fridge | drawer | gate; Label = prompt text.
	State is the model's "Open" attribute (server side: everyone sees the same door). A tween of about 0.6 s with a Back
	ease-out (a small overshoot that settles), open / close sounds from the game's car doors (ProSoundEffects, public
	domain) and built-in clicks. Collision is off while moving and stays off after a close until nobody stands in it, so
	a door never traps a player. A ProximityPrompt on each (E / tap, short range, one shown per key).
]]

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local TAG = "Openable"
local SECONDS = { hinge = 0.62, drawer = 0.45, gate = 0.7 }
local OPEN_SOUND = "rbxassetid://9113204879" -- Config.DoorFeel.OpenSound
local CLOSE_SOUND = "rbxassetid://9113205539" -- Config.DoorFeel.CloseSound
local CLICK = "rbxasset://sounds/volume_slider.ogg"
local THUD = "rbxasset://sounds/action_jump_land.mp3"
local SLIDE = "rbxasset://sounds/action_get_up.mp3"
-- per kind: { open = { id, volume, pitch }, close = { ... }, extra on close }
local SOUNDS = {
	door = { open = { OPEN_SOUND, 0.5, 0.8 }, close = { CLOSE_SOUND, 0.55, 0.75 }, closeExtra = { THUD, 0.35, 0.8 } },
	cabinet = { open = { OPEN_SOUND, 0.3, 1.45 }, close = { CLOSE_SOUND, 0.35, 1.5 }, closeExtra = { CLICK, 0.3, 1.2 } },
	fridge = { open = { OPEN_SOUND, 0.35, 1.15 }, close = { CLOSE_SOUND, 0.45, 1.05 }, closeExtra = { THUD, 0.25, 1.3 } },
	drawer = { open = { SLIDE, 0.35, 1.6 }, close = { SLIDE, 0.35, 1.9 }, closeExtra = { CLICK, 0.3, 1.0 } },
	gate = { open = { SLIDE, 0.4, 0.75 }, close = { SLIDE, 0.4, 0.7 }, closeExtra = { CLOSE_SOUND, 0.4, 1.7 } },
}

type Item = {
	model: Model,
	hinge: BasePart,
	parts: { BasePart },
	built: { [BasePart]: CFrame },
	collide: { [BasePart]: boolean },
	moving: boolean,
	tween: Tween?,
}
local items: { [Model]: Item } = {}

local function play(where: BasePart, s: { any }?)
	if not s then
		return
	end
	local snd = Instance.new("Sound")
	snd.SoundId = s[1]
	snd.Volume = s[2]
	snd.PlaybackSpeed = s[3] * (0.96 + math.random() * 0.08)
	snd.RollOffMaxDistance = 45
	snd.Parent = where
	snd:Play()
	task.delay(4, function()
		snd:Destroy()
	end)
end

-- pose of every part at progress a (0 = built, 1 = the other state); a can overshoot 1 a little (Back ease)
local function pose(it: Item, a: number)
	local m = it.model
	local kind = m:GetAttribute("Kind")
	local h = it.hinge.CFrame
	if kind == "hinge" then
		local r = h * CFrame.Angles(0, math.rad((m:GetAttribute("Angle") or 90) * a), 0) * h:Inverse()
		for _, p in it.parts do
			p.CFrame = r * it.built[p]
		end
	elseif kind == "drawer" then
		local off = h:VectorToWorldSpace((m:GetAttribute("SlideL") or Vector3.zero) * a)
		for _, p in it.parts do
			p.CFrame = it.built[p] + off
		end
	elseif kind == "gate" then
		for _, p in it.parts do
			local fold = p:GetAttribute("GateFold")
			if typeof(fold) == "Vector3" then
				p.CFrame = it.built[p] + h:VectorToWorldSpace(fold * a)
			end
		end
	end
end

local function isOpenAt(it: Item, a: number): boolean
	-- built pose = open when BuiltOpen; a = 1 means the other pose
	local builtOpen = it.model:GetAttribute("BuiltOpen") == true
	return if a >= 0.5 then not builtOpen else builtOpen
end

local function lattice(it: Item, show: boolean)
	for _, p in it.parts do
		if p:GetAttribute("LatticeX") then
			p.Transparency = if show then 0 else 1
		end
	end
end

local function blocked(it: Item): boolean
	-- is a player standing in any solid part of the item now?
	local op = OverlapParams.new()
	op.FilterType = Enum.RaycastFilterType.Include
	local chars = {}
	for _, pl in Players:GetPlayers() do
		if pl.Character then
			table.insert(chars, pl.Character)
		end
	end
	if #chars == 0 then
		return false
	end
	op.FilterDescendantsInstances = chars
	for _, p in it.parts do
		if it.collide[p] and #workspace:GetPartsInPart(p, op) > 0 then
			return true
		end
	end
	return false
end

local function setCollide(it: Item, on: boolean)
	for _, p in it.parts do
		if it.collide[p] then
			p.CanCollide = on
		end
	end
end

local function restoreCollision(it: Item)
	task.spawn(function()
		for _ = 1, 120 do
			if not it.model.Parent or it.moving then
				return
			end
			if not blocked(it) then
				setCollide(it, true)
				return
			end
			task.wait(0.5)
		end
		setCollide(it, true)
	end)
end

local function toggle(it: Item)
	if it.moving then
		return
	end
	local m = it.model
	local kind = m:GetAttribute("Kind")
	local builtOpen = m:GetAttribute("BuiltOpen") == true
	local wantOpen = not (m:GetAttribute("Open") == true)
	local target = if wantOpen == builtOpen then 0 else 1 -- progress to go to
	local from = 1 - target
	it.moving = true
	setCollide(it, false)
	local snd = SOUNDS[m:GetAttribute("Sound") or "door"] or SOUNDS.door
	if wantOpen then
		play(it.hinge, snd.open)
		if kind == "gate" then
			lattice(it, false)
		end
	else
		play(it.hinge, snd.close)
	end
	local v = Instance.new("NumberValue")
	v.Value = from
	local conn = v.Changed:Connect(function(a)
		pose(it, a)
	end)
	local tw = TweenService:Create(v, TweenInfo.new(SECONDS[kind] or 0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Value = target })
	it.tween = tw
	tw.Completed:Once(function()
		conn:Disconnect()
		pose(it, target)
		v:Destroy()
		m:SetAttribute("Open", wantOpen)
		local p = m:FindFirstChildWhichIsA("ProximityPrompt", true)
		if p then
			p.ActionText = if wantOpen then "Close" else "Open"
		end
		if not wantOpen then
			play(it.hinge, snd.closeExtra)
			if kind == "gate" then
				lattice(it, true)
			end
		end
		it.moving = false
		restoreCollision(it)
	end)
	tw:Play()
	local _ = isOpenAt
end

local function add(m: Instance)
	if not m:IsA("Model") or items[m] then
		return
	end
	local hinge = m:FindFirstChild("Hinge")
	if not (hinge and hinge:IsA("BasePart")) then
		warn("Openable without a Hinge part: " .. m:GetFullName())
		return
	end
	local it: Item = { model = m, hinge = hinge, parts = {}, built = {}, collide = {}, moving = false, tween = nil }
	local biggest, size = nil, 0
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") and p ~= hinge then
			table.insert(it.parts, p)
			it.built[p] = p.CFrame
			it.collide[p] = p.CanCollide
			local v = p.Size.X * p.Size.Y * p.Size.Z
			if v > size then
				biggest, size = p, v
			end
		end
	end
	items[m] = it
	local builtOpen = m:GetAttribute("BuiltOpen") == true
	if m:GetAttribute("Open") == nil then
		m:SetAttribute("Open", builtOpen)
	elseif (m:GetAttribute("Open") == true) ~= builtOpen then
		pose(it, 1)
	end
	if m:GetAttribute("Kind") == "gate" then
		lattice(it, m:GetAttribute("Open") ~= true)
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "OpenablePrompt"
	prompt.ActionText = if m:GetAttribute("Open") == true then "Close" else "Open"
	prompt.ObjectText = m:GetAttribute("Label") or ""
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = m:GetAttribute("Reach") or 7
	prompt.RequiresLineOfSight = false
	prompt.Exclusivity = Enum.ProximityPromptExclusivity.OnePerButton
	prompt.Parent = biggest or hinge
	prompt.Triggered:Connect(function()
		toggle(it)
	end)
end

for _, m in CollectionService:GetTagged(TAG) do
	add(m)
end
CollectionService:GetInstanceAddedSignal(TAG):Connect(add)

-- Studio test hook (Play only, never live): ServerStorage.OpenablesTest:Invoke(modelName) toggles the first match
if RunService:IsStudio() then
	local f = Instance.new("BindableFunction")
	f.Name = "OpenablesTest"
	f.OnInvoke = function(name: string)
		for m, it in items do
			if m.Name == name then
				toggle(it)
				task.wait((SECONDS[m:GetAttribute("Kind")] or 0.6) + 0.15)
				return m:GetAttribute("Open")
			end
		end
		return nil
	end
	f.Parent = game:GetService("ServerStorage")
end
