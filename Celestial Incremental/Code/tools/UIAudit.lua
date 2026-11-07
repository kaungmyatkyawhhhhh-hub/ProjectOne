--[[ UIAudit (P&L Studios, 7 Nov: "the phone HUD overlaps everywhere")
Read-only. A ModuleScript in ReplicatedStorage.Tools; run it on the CLIENT, in Play:
  local report = require(game.ReplicatedStorage.Tools.UIAudit)()
It prints the report and returns it as text. Changes nothing. With Studio's Workspace TestDevice (UIKit) it measures the
emulated device in that device's own logical pixels.

Checks (every visible HUD element of the game's ScreenGuis; a closed window is not visible, so not checked):
  OVERLAP   two HUD components cover each other. A component = a child of a gui's root (the counter, a chip, the
            hotbar, LUMI's card...), or a child of a frame with the attribute UIAuditGroup (a column of chips).
  TEXTHIT   two texts inside one component cover each other ("LUMI" over "STEP 1/20").
  SMALL     text drawn under 14 px.
  CLIPPED   text that doesn't fit its box (TextFits false).
  UNSAFE    a component outside the safe area, or under Roblox's own top-left buttons.
Attribute AllowOverlap (on any element or its ancestor): left out (a glow, a shadow, a pop-up effect on purpose).
]]

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")

local MIN_TEXT = 14

return function()
	local player = Players.LocalPlayer
	local pg = player:WaitForChild("PlayerGui")
	local out, counts = {}, {}
	local function add(kind, msg)
		counts[kind] = (counts[kind] or 0) + 1
		table.insert(out, string.format("[%s] %s", kind, msg))
	end

	-- the emulated device's draw scale (TestDevice draws a big device smaller); 1 on a real screen
	local fit = 1
	for _, g in ipairs(pg:GetChildren()) do
		local d = g:IsA("ScreenGui") and g:FindFirstChild("TestDevice")
		local us = d and d:FindFirstChildOfClass("UIScale")
		if us then fit = us.Scale break end
	end
	local function px(v: number): number return v / fit end

	local function shown(o: Instance): boolean
		local c = o
		while c and not c:IsA("LayerCollector") do
			if c:IsA("GuiObject") and not c.Visible then return false end
			if c:GetAttribute("AllowOverlap") then return false end
			c = c.Parent
		end
		return c ~= nil and c.Enabled
	end
	local function scaleOf(o: Instance): number
		local k, c = 1, o
		while c and not c:IsA("LayerCollector") do
			local us = c:FindFirstChildOfClass("UIScale")
			if us and c.Name ~= "TestDevice" then k *= us.Scale end
			c = c.Parent
		end
		return k
	end
	-- the rect a thing really draws (a text: its text's own bounds, not its box)
	local function rectOf(o: GuiObject): (Vector2?, Vector2?)
		if o:IsA("TextLabel") or o:IsA("TextButton") then
			if o.Text == "" or o.TextTransparency >= 0.95 then return nil end
			-- (TextBounds may come unscaled: if it matches the plain TextSize, scale it like the label)
			local k = scaleOf(o) * fit
			local tb = o.TextBounds
			if not o.TextScaled and math.abs(tb.Y - o.TextSize) > math.abs(tb.Y - o.TextSize * k) then k = 1 end
			local b = Vector2.new(math.min(o.AbsoluteSize.X, tb.X * k), math.min(o.AbsoluteSize.Y, tb.Y * k))
			local x = o.AbsolutePosition.X + (if o.TextXAlignment == Enum.TextXAlignment.Left then 0 elseif o.TextXAlignment == Enum.TextXAlignment.Right then o.AbsoluteSize.X - b.X else (o.AbsoluteSize.X - b.X) / 2)
			local y = o.AbsolutePosition.Y + (if o.TextYAlignment == Enum.TextYAlignment.Top then 0 elseif o.TextYAlignment == Enum.TextYAlignment.Bottom then o.AbsoluteSize.Y - b.Y else (o.AbsoluteSize.Y - b.Y) / 2)
			return Vector2.new(x, y), b
		end
		if o:IsA("ImageLabel") or o:IsA("ImageButton") then
			if o.Image == "" or o.ImageTransparency >= 0.6 then
				if o.BackgroundTransparency >= 0.6 then return nil end
			end
			return o.AbsolutePosition, o.AbsoluteSize
		end
		if o:IsA("Frame") and o.BackgroundTransparency < 0.6 then return o.AbsolutePosition, o.AbsoluteSize end
		return nil
	end
	local function hit(ap, as, bp, bs, pad): boolean
		pad = pad or 1
		return ap.X + pad < bp.X + bs.X and bp.X + pad < ap.X + as.X and ap.Y + pad < bp.Y + bs.Y and bp.Y + pad < ap.Y + as.Y
	end
	local function name(o: Instance): string
		return (o:GetFullName():gsub("^Players%.[^%.]+%.PlayerGui%.", ""):gsub("TestDevice%.SafeArea%.", ""))
	end

	-- the components
	local comps = {}
	local safeP, safeS -- (the HUD's safe area, from GalaxyHUD's root)
	local topbarP, topbarS
	for _, g in ipairs(pg:GetChildren()) do
		if not g:IsA("ScreenGui") or not g.Enabled or not g.Name:find("^Galaxy") then continue end
		local root = g:FindFirstChild("SafeArea", true) or g
		if g.Name == "GalaxyHUD" then
			safeP, safeS = root.AbsolutePosition, root.AbsoluteSize
			local mock = g:FindFirstChild("MockTopbar", true)
			if mock then
				topbarP, topbarS = mock.AbsolutePosition, mock.AbsoluteSize
			else
				local r = GuiService.TopbarInset
				topbarP, topbarS = Vector2.new(0, 0), Vector2.new(r.Min.X, r.Max.Y)
			end
		end
		local function collect(parent: Instance)
			for _, c in ipairs(parent:GetChildren()) do
				if c:IsA("GuiObject") and shown(c) then
					if c:GetAttribute("UIAuditGroup") then collect(c) else table.insert(comps, c) end
				end
			end
		end
		collect(root)
	end
	-- each component's drawn rect + its texts
	local info = {}
	for _, c in ipairs(comps) do
		local lo, hi
		local texts = {}
		for _, d in ipairs({ c, table.unpack(c:GetDescendants()) }) do
			if d:IsA("GuiObject") and shown(d) then
				local p, s = rectOf(d)
				if p and s.X > 1 and s.Y > 1 then
					lo = if lo then lo:Min(p) else p
					hi = if hi then hi:Max(p + s) else p + s
					if d:IsA("TextLabel") or d:IsA("TextButton") then table.insert(texts, { o = d, p = p, s = s }) end
				end
			end
		end
		if lo then table.insert(info, { c = c, p = lo, s = hi - lo, texts = texts }) end
	end
	-- OVERLAP
	for i = 1, #info do
		for j = i + 1, #info do
			local a, b = info[i], info[j]
			if hit(a.p, a.s, b.p, b.s, 2) then add("OVERLAP", name(a.c) .. "  x  " .. name(b.c)) end
		end
	end
	-- TEXTHIT / SMALL / CLIPPED (a Kit text's shadow copy is the same text in the same holder: counted once)
	local said = {}
	for _, e in ipairs(info) do
		for i = 1, #e.texts do
			local t = e.texts[i]
			local o = t.o
			local key = tostring(o.Parent) .. "|" .. o.Text
			local first = not said[o.Parent] or said[o.Parent] ~= o.Text
			said[o.Parent] = o.Text
			local real = (if o.TextScaled then t.s.Y else o.TextSize * scaleOf(o) * fit) / fit
			if first and real < MIN_TEXT - 0.5 then add("SMALL", string.format("%s '%s' %.1f px", name(o), o.Text:sub(1, 24), real)) end
			-- (a label that grows with its text (AutomaticSize X) can't be cut sideways; TextFits lags a frame as it changes)
			local grows = o.AutomaticSize == Enum.AutomaticSize.X or o.AutomaticSize == Enum.AutomaticSize.XY
			if first and not grows and not o.TextFits and not o.TextScaled then add("CLIPPED", string.format("%s '%s'", name(o), o.Text:sub(1, 24))) end
			for j = i + 1, #e.texts do
				local u = e.texts[j]
				-- (a Kit text's stroke / shadow copy: same text, same holder)
				if u.o.Parent == o.Parent and u.o.Text == o.Text then continue end
				if hit(t.p, t.s, u.p, u.s, 2) then add("TEXTHIT", string.format("'%s' x '%s' in %s", o.Text:sub(1, 20), u.o.Text:sub(1, 20), name(e.c))) end
			end
		end
	end
	-- UNSAFE
	for _, e in ipairs(info) do
		if safeP and (e.p.X < safeP.X - 1 or e.p.Y < safeP.Y - 1 or e.p.X + e.s.X > safeP.X + safeS.X + 1 or e.p.Y + e.s.Y > safeP.Y + safeS.Y + 1) then
			add("UNSAFE", name(e.c) .. " goes past the safe area")
		end
		if topbarP and hit(e.p, e.s, topbarP, topbarS, 1) then add("UNSAFE", name(e.c) .. " is under Roblox's top-left buttons") end
	end

	local _, dev = nil, workspace:GetAttribute("TestDevice") or "this screen"
	local lines = { string.format("==== UIAudit (%s, %dx%d): %d components ====", tostring(dev), math.floor(px(safeS and safeS.X or 0)), math.floor(px(safeS and safeS.Y or 0)), #info) }
	local kinds = {}
	for k, v in pairs(counts) do table.insert(kinds, k .. " " .. v) end
	table.sort(kinds)
	if #kinds == 0 then table.insert(lines, "CLEAN: nothing to fix") else table.insert(lines, table.concat(kinds, ", ")) end
	for _, l in ipairs(out) do table.insert(lines, l) end
	table.insert(lines, "==== end UIAudit ====")
	local report = table.concat(lines, "\n")
	print(report)
	return report
end
