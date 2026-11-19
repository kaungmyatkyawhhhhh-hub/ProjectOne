--[[
	LangUI (client, 19 Nov 2026, the Burmese language option; vault "City Legends/2026-11-19 Burmese language.md").
	Every TextLabel / TextButton in PlayerGui (and the BillboardGuis over players' heads: job tags) shows
	its text in the player's language: the screens keep building English, this runs each text through
	Strings.tr as it is set, and again for all of them when the language changes (live switch).
	The English text stays on the label as attribute "En" (code that reads a label's text back must use
	it: UI's gearbox / sound toggles). Burmese runs taller and longer: a translated one-line label gets
	TextScaled with its English TextSize as the cap, so it shrinks to fit and never clips.
	Not translated: TextBoxes (player input), RichText labels, SurfaceGuis in the world (car clusters).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Strings = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Strings"))

local LangUI = {}

local tracked: { [Instance]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local setting: { [Instance]: boolean } = setmetatable({}, { __mode = "k" }) :: any -- our own Text writes
local FIT = "LangFit" -- our UITextSizeConstraint

local function unfit(l: any)
	local c = l:FindFirstChild(FIT)
	if c then
		l.TextScaled = l:GetAttribute("LangScaled") == true
		c:Destroy()
	end
	local ts = l:GetAttribute("LangSize")
	if ts then
		l.TextSize = ts
		l:SetAttribute("LangSize", nil)
	end
end

-- a label that sizes itself to its text (AutomaticSize) inside a fixed box: step its TextSize down
-- until it ends inside the box (the box was sized for the English word)
local function shrinkAuto(l: any)
	task.defer(function()
		local box = l.Parent
		while box and box:IsA("GuiObject") and box.AutomaticSize ~= Enum.AutomaticSize.None do
			box = box.Parent
		end
		if not (box and box:IsA("GuiObject")) then
			return
		end
		l:SetAttribute("LangSize", l:GetAttribute("LangSize") or l.TextSize)
		for _ = 1, 14 do
			local over = (l.AbsolutePosition.X + l.AbsoluteSize.X) - (box.AbsolutePosition.X + box.AbsoluteSize.X - 4)
			if over <= 0 or l.TextSize <= 9 or Strings.lang() ~= "my" then
				break
			end
			l.TextSize -= 1
			task.wait()
		end
	end)
end

-- one-line label: Myanmar letters look smaller than Latin at the same size and need more height than
-- the box has, so TextScaled made them tiny. Instead: the English size (x1.15 for small labels), stepped
-- down only while the line is wider than its box (marks may reach a little above / below the box)
local function fitLine(l: any, tries: number)
	if l.AbsoluteSize.X < 2 then
		if tries < 3 then
			task.delay(0.05, fitLine, l, tries + 1)
		end
		return
	end
	if Strings.lang() ~= "my" or not l:GetAttribute("En") then
		return
	end
	local base = l:GetAttribute("LangSize") or l.TextSize
	l:SetAttribute("LangSize", base)
	local size = math.ceil(base * (if base <= 12 then 1.15 else 1))
	l.TextSize = size
	while size > 9 and l.TextBounds.X > l.AbsoluteSize.X - 2 do
		size -= 1
		l.TextSize = size
	end
end

-- Burmese fitting: one-line labels by width (fitLine), wrapped ones shrink to their box (TextScaled
-- capped at the English size), self-sizing ones inside a fixed box (shrinkAuto); never under 9 px
local function fit(l: any)
	if l:FindFirstChild(FIT) or l.TextScaled then
		return
	end
	if l.AutomaticSize ~= Enum.AutomaticSize.None then
		shrinkAuto(l)
		return
	end
	if not l.TextWrapped then
		fitLine(l, 0)
		return
	end
	l:SetAttribute("LangScaled", l.TextScaled)
	local c = Instance.new("UITextSizeConstraint")
	c.Name = FIT
	c.MaxTextSize = math.max(9, math.floor(l.TextSize))
	c.MinTextSize = 9
	c.Parent = l
	l.TextScaled = true
end

local function apply(l: any)
	if l.RichText then
		return
	end
	local en = l:GetAttribute("En") or l.Text
	local t = Strings.tr(en)
	if t ~= l.Text then
		setting[l] = true
		l.Text = t
		setting[l] = nil
	end
	if t ~= en then
		l:SetAttribute("En", en)
		if Strings.lang() == "my" then
			fit(l)
		end
	else
		l:SetAttribute("En", nil)
		unfit(l)
	end
end

local function track(d: Instance)
	if tracked[d] or not (d:IsA("TextLabel") or d:IsA("TextButton")) then
		return
	end
	tracked[d] = true
	d:GetPropertyChangedSignal("Text"):Connect(function()
		if setting[d] then
			return
		end
		-- the screen set new text (English, or Burmese from Strings.get): that is the source now
		d:SetAttribute("En", nil)
		apply(d)
	end)
	apply(d)
end

-- the text a label shows in English (for code that compares a label's text)
function LangUI.en(l: Instance): string
	return (l:GetAttribute("En") or (l :: any).Text) :: string
end

function LangUI.init()
	local player = Players.LocalPlayer
	local pg = player:WaitForChild("PlayerGui")
	for _, d in pg:GetDescendants() do
		track(d)
	end
	pg.DescendantAdded:Connect(track)
	-- job tags over heads (BillboardGuis on characters)
	local function watchChar(c: Model)
		c.DescendantAdded:Connect(function(d)
			if d:IsA("TextLabel") and d:FindFirstAncestorWhichIsA("BillboardGui") then
				track(d)
			end
		end)
		for _, d in c:GetDescendants() do
			if d:IsA("TextLabel") and d:FindFirstAncestorWhichIsA("BillboardGui") then
				track(d)
			end
		end
	end
	local function watchPlayer(p: Player)
		if p.Character then
			watchChar(p.Character)
		end
		p.CharacterAdded:Connect(watchChar)
	end
	for _, p in Players:GetPlayers() do
		watchPlayer(p)
	end
	Players.PlayerAdded:Connect(watchPlayer)
	-- Studio test hook: player attribute TestLang = "en" / "my" / "auto" switches live
	player:GetAttributeChangedSignal("TestLang"):Connect(function()
		Strings.setLang(tostring(player:GetAttribute("TestLang") or "auto"))
	end)
	Strings.Changed.Event:Connect(function()
		for l in tracked do
			if l.Parent then
				apply(l)
			end
		end
	end)
end

return LangUI
