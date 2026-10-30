--[[
	Standins (client) (owner, 2026-10-30: "fix that black thing throughout the map and on the roads")
	Far buildings are streamed out (StreamingEnabled). Roblox's own low-detail stand-ins drew them
	as flat black shapes, so the place has its own instead: City.Standins (always loaded, made by
	tools/standins.luau), one plain copy of each building's big parts with a few lit floors.
	Each copy has a "Real" ObjectValue pointing at the part it copies; while that part is streamed in
	the copy is hidden (on this screen only), so it never shows through the real building.
]]

local Standins = {}

type Entry = { body: BasePart, link: ObjectValue, shown: boolean? }

local entries: { Entry } = {}
local byBody: { [BasePart]: Entry } = {}

local function setShown(e: Entry, on: boolean)
	e.shown = on
	local hide = if on then 0 else 1
	e.body.LocalTransparencyModifier = hide
	for _, d in e.body:GetDescendants() do
		if d:IsA("BasePart") then
			d.LocalTransparencyModifier = hide
		end
	end
end

local function add(d: Instance)
	if not d:IsA("BasePart") or byBody[d] then
		return
	end
	local link = d:FindFirstChild("Real")
	if link and link:IsA("ObjectValue") then
		local e: Entry = { body = d, link = link, shown = nil }
		byBody[d] = e
		table.insert(entries, e)
	end
end

local function update()
	for _, e in entries do
		local real = e.link.Value
		local away = real == nil or not real:IsDescendantOf(workspace)
		if away ~= e.shown then
			setShown(e, away)
		end
	end
end

function Standins.init(city: Instance)
	task.spawn(function()
		local root = city:WaitForChild("Standins", 20)
		if not root then
			return -- an older place without stand-ins: nothing to do
		end
		root.DescendantAdded:Connect(function(d)
			add(d)
			local parent = d.Parent
			if d.Name == "Real" and parent then
				add(parent)
			end
			-- a lit floor that arrives after its body follows the body
			local e = if parent and parent:IsA("BasePart") then byBody[parent] else nil
			if e and e.shown ~= nil and d:IsA("BasePart") then
				d.LocalTransparencyModifier = if e.shown then 0 else 1
			end
		end)
		for _, d in root:GetDescendants() do
			add(d)
		end
		while true do
			update()
			task.wait(0.5)
		end
	end)
end

return Standins
