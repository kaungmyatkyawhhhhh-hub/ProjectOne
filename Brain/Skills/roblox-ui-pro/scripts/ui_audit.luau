-- ui_audit.luau (roblox-ui-pro skill)
-- Run through the Studio MCP `execute_luau`:
--   * in Play, datamodel_type = "Client"  -> audits the live PlayerGui (what players see; use this)
--   * in Edit, datamodel_type = "Edit"    -> audits StarterGui templates
-- Read-only: it creates and changes nothing. Returns a text report: ERRORs must be fixed,
-- WARNs fixed or explained, INFO is context. Edit CONFIG below before sending if needed.

local CONFIG = {
	only = nil :: { string }?, -- e.g. { "MB_Store", "MB_HUD" } to audit just those ScreenGuis
	root = nil :: Instance?,   -- override where ScreenGuis live (e.g. game.CoreGui for an Edit-mode preview)
	minTouch = 44,             -- px, smallest comfortable tap target (touch / gamepad)
	hardMinTouch = 36,         -- below this it's an ERROR, not a WARN
	minMouse = 24,             -- px, when the player uses a mouse (WCAG 2.5.8); 20 = ERROR
	minText = 14,              -- px, smallest readable text on a phone
	minContrast = 3.0,         -- text vs its plate (WCAG large-text level; body text should reach 4.5)
	maxExamples = 6,           -- examples printed per rule
	maxFonts = 2, maxRadii = 4, maxTextSizes = 8,
	-- the game's own touch controls (names of GuiButtons/Frames, anywhere in the audited UI): other buttons must not sit on
	-- them, e.g. { "Dart", "Sprint" }. Roblox's real jump button and thumbstick are found automatically when they exist.
	reserve = {} :: { string },
}

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

-- LocalPlayer can exist without a PlayerGui (e.g. Edit mode with the Device Simulator on), so check both
local lp = Players.LocalPlayer
local playerGui = lp and lp:FindFirstChildOfClass("PlayerGui")
if not playerGui then lp = nil end
local root: Instance = CONFIG.root or playerGui or game:GetService("StarterGui")
local cam = workspace.CurrentCamera
local vp = cam.ViewportSize
local inset = (GuiService:GetGuiInset()) -- top-left inset (topbar)
-- (zones for Roblox's touch controls are set up below, after the geometry helpers)
-- a mouse pointer is precise: smaller targets are fine on PC
if UserInputService.PreferredInput == Enum.PreferredInput.KeyboardAndMouse then
	CONFIG.minTouch, CONFIG.hardMinTouch = CONFIG.minMouse, CONFIG.minMouse - 4
end

local findings: { [string]: { level: string, items: { string }, seen: { [string]: number }, total: number } } = {}
local order: { string } = {}
local function add(level: string, rule: string, text: string)
	local f = findings[rule]
	if not f then
		f = { level = level, items = {}, seen = {}, total = 0 }
		findings[rule] = f
		table.insert(order, rule)
	end
	f.total += 1
	if level == "ERROR" then f.level = "ERROR" end -- one rule can hold both (e.g. TINY_TEXT 13 px WARN + 9 px ERROR)
	-- identical lines (siblings with the same name) are folded into one "xN" line
	if f.seen[text] then
		f.seen[text] += 1
	else
		f.seen[text] = 1
		table.insert(f.items, text)
	end
end

local function rel(o: Instance): string
	local full = o:GetFullName()
	local prefix = root:GetFullName() .. "."
	if full:sub(1, #prefix) == prefix then return full:sub(#prefix + 1) end
	return full
end

-- rects are {x0, y0, x1, y1} in screen pixels (viewport space, topbar included)
local function rectOf(g: GuiObject)
	local p = g.AbsolutePosition + inset
	local s = g.AbsoluteSize
	return { p.X, p.Y, p.X + s.X, p.Y + s.Y }
end
local function intersect(a, b)
	local r = { math.max(a[1], b[1]), math.max(a[2], b[2]), math.min(a[3], b[3]), math.min(a[4], b[4]) }
	if r[3] <= r[1] or r[4] <= r[2] then return nil end
	return r
end
local function area(r) return (r[3] - r[1]) * (r[4] - r[2]) end

-- WCAG relative luminance / contrast
local function lum(c: Color3): number
	local function ch(v: number) return if v <= 0.03928 then v / 12.92 else ((v + 0.055) / 1.055) ^ 2.4 end
	return 0.2126 * ch(c.R) + 0.7152 * ch(c.G) + 0.0722 * ch(c.B)
end
local function contrast(a: Color3, b: Color3): number
	local la, lb = lum(a), lum(b)
	if la < lb then la, lb = lb, la end
	return (la + 0.05) / (lb + 0.05)
end

-- touch-reserved zones. Real ones when Roblox's TouchGui is on screen; otherwise estimates of Roblox's default controls,
-- used only when the game hasn't turned them off (a game with its own controls lists them in CONFIG.reserve instead).
local minAxis = math.min(vp.X, vp.Y)
local small = minAxis <= 500
local jump = if small
	then { vp.X - 95 - 8, vp.Y - 90 - 8, vp.X - 25 + 8, vp.Y - 20 + 8 }
	else { vp.X - 170 - 8, vp.Y - 210 - 8, vp.X - 50 + 8, vp.Y - 90 + 8 }
local stick = { 0, vp.Y - math.min(vp.Y * 0.45, 220), math.min(vp.X * 0.35, 300), vp.Y }
local zoneSource = "estimated Roblox controls (touch devices)"
local touchGui = playerGui and playerGui:FindFirstChild("TouchGui")
if touchGui and touchGui:IsA("ScreenGui") and touchGui.Enabled then
	zoneSource = "Roblox TouchGui (measured)"
	jump, stick = nil, nil
	for _, d in touchGui:GetDescendants() do
		if d:IsA("GuiObject") and d.Visible and d.AbsoluteSize.X > 0 then
			local p = d.AbsolutePosition + inset
			local r = { p.X - 8, p.Y - 8, p.X + d.AbsoluteSize.X + 8, p.Y + d.AbsoluteSize.Y + 8 }
			if d.Name == "JumpButton" then jump = r elseif d.Name:find("Thumbstick") and not stick then stick = r end
		end
	end
elseif lp and #CONFIG.reserve > 0 then
	-- the game has its own controls: Roblox's default jump/stick estimates don't apply
	zoneSource = "the game's own controls: " .. table.concat(CONFIG.reserve, ", ")
	jump, stick = nil, nil
end
local reserved: { { rect: { number }, obj: Instance } } = {}
local function centreIn(r, z)
	if not z then return false end
	local cx, cy = (r[1] + r[3]) / 2, (r[2] + r[4]) / 2
	return cx >= z[1] and cx <= z[3] and cy >= z[2] and cy <= z[4]
end

local fonts, radii, textSizes = {}, {}, {}
local buttons = {}
local counted = { screenGuis = 0, objects = 0, text = 0, buttons = 0 }

local function textObj(o: Instance): boolean
	return o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox")
end

local function hasOutline(t: GuiObject): (boolean, Color3?)
	for _, c in t:GetChildren() do
		if c:IsA("UIStroke") and c.Enabled and c.Transparency < 0.5 and c.Thickness >= 1
			and c.ApplyStrokeMode == Enum.ApplyStrokeMode.Contextual then
			return true, c.Color
		end
	end
	local tt = t :: any
	if tt.TextStrokeTransparency ~= nil and tt.TextStrokeTransparency < 0.5 then return true, tt.TextStrokeColor3 end
	return false, nil
end

-- nearest drawn background behind a text object, or nil if it sits on the 3D world. Looks at the text itself, its
-- ancestors, and at each level the siblings drawn under it (kits often put a "Body" plate next to the "Face" content).
local function backdropColour(t: GuiObject, sg: Instance): Color3?
	local centre = t.AbsolutePosition + t.AbsoluteSize / 2
	local function covers(g: GuiObject)
		local p, s = g.AbsolutePosition, g.AbsoluteSize
		return g.Visible and g.BackgroundTransparency < 0.3 and s.X > 0
			and centre.X >= p.X and centre.X <= p.X + s.X and centre.Y >= p.Y and centre.Y <= p.Y + s.Y
	end
	local o: Instance? = t
	while o and o ~= sg do
		if o:IsA("GuiObject") and covers(o) then return o.BackgroundColor3 end
		local parent = o.Parent
		if parent and o:IsA("GuiObject") then
			for _, sib in parent:GetChildren() do
				if sib ~= o and sib:IsA("GuiObject") and sib.ZIndex <= o.ZIndex and covers(sib) then return sib.BackgroundColor3 end
			end
		end
		o = parent
	end
	return nil
end

local function walk(o: Instance, sg: LayerCollector, clip, uiScale: number, hiddenByGroup: boolean)
	for _, c in o:GetChildren() do
		if c:IsA("GuiObject") then
			if not c.Visible then continue end
			counted.objects += 1
			local r = rectOf(c)
			local vis = if clip then intersect(r, clip) else r
			local scale = uiScale
			local us = c:FindFirstChildOfClass("UIScale")
			if us then scale *= us.Scale end
			local groupHidden = hiddenByGroup or (c:IsA("CanvasGroup") and c.GroupTransparency >= 0.95)
			local sizeX, sizeY = c.AbsoluteSize.X, c.AbsoluteSize.Y

			if sizeX > 0 and sizeY > 0 and vis then
				if table.find(CONFIG.reserve, c.Name) then table.insert(reserved, { rect = vis, obj = c }) end
				-- off screen
				local over = math.max(0 - vis[1], 0 - vis[2], vis[3] - vp.X, vis[4] - vp.Y)
				local fullScreen = sizeX >= vp.X * 0.9 and sizeY >= vp.Y * 0.8 -- dim layers / backdrops bleed on purpose
				if over > 2 and not fullScreen and (textObj(c) or c:IsA("GuiButton") or c:IsA("ImageLabel")) then
					add("ERROR", "OFF_SCREEN", ("%s sticks out %dpx"):format(rel(c), math.floor(over)))
				end
				-- fixed sizes that can't fit small phones (~705x338, ~280 usable height).
				-- Skipped inside a clipping window (a big map inside a minimap frame is fine).
				if not clip and c.Size.X.Scale == 0 and c.Size.X.Offset > 640 then
					add("WARN", "FIXED_TOO_WIDE", ("%s is a fixed %dpx wide (small phones are ~705)"):format(rel(c), c.Size.X.Offset))
				end
				if not clip and c.Size.Y.Scale == 0 and c.Size.Y.Offset > 300 then
					add("WARN", "FIXED_TOO_TALL", ("%s is a fixed %dpx tall (phones have ~280 usable)"):format(rel(c), c.Size.Y.Offset))
				end
				if c.BorderSizePixel > 0 and c.BackgroundTransparency < 1 then
					add("INFO", "BORDER_PIXEL", rel(c) .. " uses BorderSizePixel (use UIStroke)")
				end
				if c.BackgroundTransparency < 1 and c.BackgroundColor3 == Color3.fromRGB(163, 162, 165) and not c:IsA("ScrollingFrame") then
					add("WARN", "DEFAULT_GREY", rel(c) .. " still has Roblox's default grey background")
				end
				local corner = c:FindFirstChildOfClass("UICorner")
				if corner and corner.CornerRadius.Scale == 0 then radii[corner.CornerRadius.Offset] = true end

				-- text (labels tagged UIDecor are decoration, e.g. the darker copy under depth text)
				if textObj(c) and not c:GetAttribute("UIDecor") then
					local t = c :: any
					if t.Text ~= "" and t.TextTransparency < 0.9 then
						counted.text += 1
						local fam = t.FontFace.Family:match("families/(.-)%.json") or t.FontFace.Family
						fonts[fam] = true
						if fam:find("LegacyArial") or fam == "Arial" then
							add("WARN", "DEFAULT_FONT", rel(c) .. " uses the default " .. fam .. " font")
						end
						local size
						if t.TextScaled then
							local lines = 1
							if not t.TextWrapped then lines = #string.split(t.Text, "\n") end
							size = t.TextBounds.Y / math.max(lines, 1)
						else
							size = t.TextSize * scale
						end
						if size > 0 then
							textSizes[math.floor(size + 0.5)] = true
							if size < CONFIG.minText - 0.1 then -- 13.97 from scaling is 14
								add(if size < 12 then "ERROR" else "WARN", "TINY_TEXT", ("%s text is %.1fpx: \"%s\""):format(rel(c), size, t.Text:sub(1, 24)))
							end
						end
						if not t.TextFits and t.TextTruncate == Enum.TextTruncate.None then
							add("WARN", "TEXT_CUT_OFF", ("%s doesn't fit: \"%s\""):format(rel(c), t.Text:sub(1, 30)))
						end
						local outlined, strokeCol = hasOutline(c)
						local bg = backdropColour(c, sg)
						if bg then
							local ratio = contrast(t.TextColor3, bg)
							if outlined and strokeCol then ratio = math.max(ratio, contrast(t.TextColor3, strokeCol)) end
							if ratio < CONFIG.minContrast then
								add("WARN", "LOW_CONTRAST", ("%s %.1f:1 \"%s\""):format(rel(c), ratio, t.Text:sub(1, 20)))
							end
						elseif not outlined then
							add("WARN", "TEXT_OVER_WORLD", ("%s has no plate and no outline: \"%s\""):format(rel(c), t.Text:sub(1, 20)))
						end
					end
				end

				-- buttons
				if c:IsA("GuiButton") and c.Interactable and c.Active ~= false then
					local isBackdrop = sizeX >= vp.X * 0.9 and sizeY >= (vp.Y - inset.Y) * 0.85
					if not isBackdrop then
						counted.buttons += 1
						if groupHidden then
							add("ERROR", "INVISIBLE_BUT_CLICKABLE", rel(c) .. " is inside a faded-out CanvasGroup but still takes taps")
						else
							table.insert(buttons, { obj = c, rect = vis, path = rel(c) })
							local minSide = math.min(sizeX, sizeY)
							-- a slim visual with a bigger invisible tap area as a child (a "Hit" button) is fine:
							-- the finger gets the child's size
							local padded = false
							if minSide < CONFIG.minTouch then
								for _, d in c:GetDescendants() do
									if d:IsA("GuiButton") and d.Visible and d.Interactable
										and math.min(d.AbsoluteSize.X, d.AbsoluteSize.Y) >= CONFIG.minTouch
										and d.AbsoluteSize.X >= sizeX - 1 then
										padded = true
										break
									end
								end
							end
							if minSide < CONFIG.minTouch and not padded then
								add(if minSide < CONFIG.hardMinTouch then "ERROR" else "WARN", "SMALL_TARGET",
									("%s is %dx%d"):format(rel(c), math.floor(sizeX), math.floor(sizeY)))
							end
							if r[2] < inset.Y - 1 and sg:IsA("ScreenGui") then
								add("WARN", "UNDER_TOPBAR", rel(c) .. " is (partly) in the Roblox topbar band; check it doesn't sit under the Roblox buttons")
							end
							if centreIn(vis, jump) then
								add("WARN", "UNDER_JUMP_BUTTON", rel(c) .. " sits where the jump button is (" .. zoneSource .. ")")
							elseif centreIn(vis, stick) then
								add("WARN", "UNDER_THUMBSTICK", rel(c) .. " sits in the thumbstick area (" .. zoneSource .. ")")
							end
						end
					end
				end
			end

			local childClip = clip
			if c.ClipsDescendants or c:IsA("ScrollingFrame") or c:IsA("CanvasGroup") then -- a CanvasGroup clips too
				childClip = if clip then intersect(r, clip) else r
				if not childClip then continue end -- everything inside is clipped away
			end
			walk(c, sg, childClip, scale, groupHidden)
		elseif c:IsA("Folder") or c:IsA("Configuration") then
			walk(c, sg, clip, uiScale, hiddenByGroup)
		end
	end
end

-- ScreenGui-level checks
local names = {}
for _, sg in root:GetChildren() do
	if sg:IsA("ScreenGui") then
		names[sg.Name] = (names[sg.Name] or 0) + 1
	end
end
for n, k in names do
	if k > 1 then add("ERROR", "DUPLICATE_SCREENGUI", ("%s x%d (respawn duplicate or double-built)"):format(n, k)) end
end

local function wanted(name: string): boolean
	if not CONFIG.only then return true end
	return table.find(CONFIG.only, name) ~= nil
end

for _, sg in root:GetChildren() do
	if sg:IsA("ScreenGui") and sg.Enabled and wanted(sg.Name) then
		counted.screenGuis += 1
		if sg.ResetOnSpawn then
			add("WARN", "RESET_ON_SPAWN", sg.Name .. " has ResetOnSpawn = true (vanishes/rebuilds on respawn)")
		end
		if sg.ZIndexBehavior == Enum.ZIndexBehavior.Global then
			add("INFO", "ZINDEX_GLOBAL", sg.Name .. " uses ZIndexBehavior Global")
		end
		walk(sg, sg, nil, 1, false)
	end
end

-- overlapping tappable buttons (not parent/child)
for i = 1, math.min(#buttons, 400) do
	local a = buttons[i]
	for j = i + 1, math.min(#buttons, 400) do
		local b = buttons[j]
		if not a.obj:IsAncestorOf(b.obj) and not b.obj:IsAncestorOf(a.obj) then
			local x = intersect(a.rect, b.rect)
			if x and area(x) > 0.3 * math.min(area(a.rect), area(b.rect)) then
				add("WARN", "BUTTONS_OVERLAP", a.path .. " overlaps " .. b.path)
			end
		end
	end
end

-- buttons sitting on the game's own touch controls (CONFIG.reserve)
for _, b in buttons do
	for _, z in reserved do
		if b.obj ~= z.obj and not z.obj:IsAncestorOf(b.obj) and not b.obj:IsAncestorOf(z.obj) then
			local x = intersect(b.rect, z.rect)
			if x and area(x) > 0.15 * math.min(area(b.rect), area(z.rect)) then
				add("WARN", "ON_GAME_CONTROL", b.path .. " overlaps the control " .. rel(z.obj))
			end
		end
	end
end

-- style consistency
local function keys(t)
	local out = {}
	for k in t do table.insert(out, k) end
	table.sort(out, function(x, y) return tostring(x) < tostring(y) end)
	return out
end
local fontList, radiusList, sizeList = keys(fonts), keys(radii), keys(textSizes)
table.sort(radiusList); table.sort(sizeList)
-- radius families: ignore pills/circles (>= 100) and fold values within 3px together
-- (an inner corner is usually outer minus the outline, which is the same family)
local radiusFamilies, familyStart = 0, -100
for _, r in radiusList do
	if r < 100 and r - familyStart > 3 then
		radiusFamilies += 1
		familyStart = r
	end
end
if #fontList > CONFIG.maxFonts then add("WARN", "TOO_MANY_FONTS", table.concat(fontList, ", ")) end
if radiusFamilies > CONFIG.maxRadii then
	add("WARN", "TOO_MANY_RADII", ("%d corner sizes: %s"):format(radiusFamilies, table.concat(radiusList, ", ")))
end
if #sizeList > CONFIG.maxTextSizes then add("WARN", "TOO_MANY_TEXT_SIZES", table.concat(sizeList, ", ")) end

-- report
local out = {}
local sel = GuiService.SelectedObject
table.insert(out, ("UI AUDIT | %s | viewport %dx%d | topbar %d | input %s | reducedMotion %s"):format(
	if CONFIG.root then root:GetFullName() elseif lp then "PlayerGui (live)" else "StarterGui (templates)", vp.X, vp.Y, inset.Y,
	UserInputService.PreferredInput.Name, tostring(GuiService.ReducedMotionEnabled)))
table.insert(out, ("checked %d ScreenGuis, %d objects, %d text, %d buttons | gamepad selection: %s"):format(
	counted.screenGuis, counted.objects, counted.text, counted.buttons, if sel then rel(sel) else "none"))
table.insert(out, "touch zones: " .. zoneSource)
table.insert(out, ("fonts: %s | corner radii: %s | text sizes: %s"):format(
	table.concat(fontList, ", "), table.concat(radiusList, ","), table.concat(sizeList, ",")))
local errors, warns = 0, 0
local levelRank = { ERROR = 1, WARN = 2, INFO = 3 }
table.sort(order, function(a, b)
	local ra, rb = levelRank[findings[a].level], levelRank[findings[b].level]
	if ra ~= rb then return ra < rb end
	return a < b
end)
for _, rule in order do
	local f = findings[rule]
	if f.level == "ERROR" then errors += f.total elseif f.level == "WARN" then warns += f.total end
	table.insert(out, ("%s %s (%d)"):format(f.level, rule, f.total))
	for i = 1, math.min(#f.items, CONFIG.maxExamples) do
		local n = f.seen[f.items[i]]
		table.insert(out, "   - " .. f.items[i] .. (if n > 1 then (" x" .. n) else ""))
	end
	if #f.items > CONFIG.maxExamples then table.insert(out, ("   ... and %d more"):format(#f.items - CONFIG.maxExamples)) end
end
table.insert(out, ("RESULT: %d errors, %d warnings"):format(errors, warns))
return table.concat(out, "\n")
