--!strict
-- WindowManager (ModuleScript, ReplicatedStorage.Galaxy; 7 Nov, the "clicking inside a window closes it" bug)
-- ONE place that knows which 2D window is open (UPGRADES, TREE, FORGE, BLACK HOLE, STORE, DAILY, STATS, SETTINGS, GUIDE,
-- CODES, SECTORS, the return screen). Every window registers its root + its close function once; its open / close tell
-- WindowManager (GalaxyHUD's shared.GalaxySideWindow does it for the side windows).
--
-- A window closes ONLY by:
--   * its X button (the window's own code);
--   * Esc / gamepad B;
--   * a tap on the BACKDROP: four dim strips AROUND the open window. They cover only the outside, so a click inside a
--     window can never reach them (the old backdrop was one full-screen button under the windows, and Roblox gave it
--     the clicks on the windows' plain frames: that was the bug);
--   * walking more than 25 studs from the board that opened it.
-- Also: while a window is open, world clicks (board taps, prompts) are ignored (WindowManager.anyOpen()), and opening a
-- window that is already open does nothing (WindowManager.isOpen(key)).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local WM = {}
WM.AUTO_CLOSE = 25 -- studs from the board that opened the window

type Win = { root: GuiObject, close: () -> () }
local wins: { [string]: Win } = {}
local current: string? = nil
local boardPos: Vector3? = nil
local strips: { Frame } = {}

-- the window's panels sink input (Active); not the things inside buttons (that would block the buttons)
local function sinkOne(o: Instance)
	if (o:IsA("Frame") or o:IsA("ScrollingFrame")) and not o:FindFirstAncestorWhichIsA("GuiButton") then
		(o :: GuiObject).Active = true
	end
end
local function sink(root: GuiObject)
	root.Active = true
	for _, d in ipairs(root:GetDescendants()) do sinkOne(d) end
	root.DescendantAdded:Connect(sinkOne)
end

function WM.register(key: string, root: GuiObject, close: () -> ())
	wins[key] = { root = root, close = close }
	sink(root)
end
function WM.opened(key: string)
	current = key
	boardPos = nil
end
function WM.closed(key: string)
	if current == key then
		current = nil
		boardPos = nil
	end
end
function WM.isOpen(key: string): boolean return current == key end
function WM.anyOpen(): boolean return current ~= nil end
function WM.current(): string? return current end
-- the board this window was opened from (a tap / prompt / OPEN button on a board): it closes when you walk away
function WM.fromBoard(pos: Vector3?) boardPos = pos end
function WM.closeCurrent()
	local w = current and wins[current]
	if w then w.close() end
end

-- the backdrop strips (made by GalaxyHUD under its HUD: the hotbar stays on top of them)
local function screenRect(o: GuiObject): (Vector2, Vector2)
	local sg = o:FindFirstAncestorWhichIsA("ScreenGui")
	local inset = if sg and not sg.IgnoreGuiInset then GuiService:GetGuiInset() else Vector2.zero
	return o.AbsolutePosition + inset, o.AbsoluteSize
end
function WM.backdrop(parent: GuiBase2d, z: number)
	for i = 1, 4 do
		local s = Instance.new("TextButton")
		s.Name = "Backdrop" .. i
		s.Text = ""
		s.AutoButtonColor = false
		s.BorderSizePixel = 0
		s.BackgroundColor3 = Color3.new(0, 0, 0)
		s.BackgroundTransparency = 0.65
		s.ZIndex = z
		s.Visible = false
		s.MouseButton1Click:Connect(WM.closeCurrent)
		s.Parent = parent
		strips[i] = s
	end
	local parentGui = if parent:IsA("ScreenGui") then parent else parent:FindFirstAncestorWhichIsA("ScreenGui")
	RunService:BindToRenderStep("GalaxyWindowBackdrop", Enum.RenderPriority.Last.Value, function()
		local w = current and wins[current]
		local show = w ~= nil and w.root.Visible and w.root.AbsoluteSize.X > 0
		for _, s in ipairs(strips) do s.Visible = show end
		if not show or not w then return end
		local pos, size = screenRect(w.root)
		local offset = if parentGui and not parentGui.IgnoreGuiInset then GuiService:GetGuiInset() else Vector2.zero
		pos -= offset + parent.AbsolutePosition
		local W, H = parent.AbsoluteSize.X, parent.AbsoluteSize.Y
		local x0, y0 = math.max(0, pos.X), math.max(0, pos.Y)
		local x1, y1 = math.min(W, pos.X + size.X), math.min(H, pos.Y + size.Y)
		-- top, bottom (full width); left, right (between them)
		strips[1].Position, strips[1].Size = UDim2.fromOffset(0, 0), UDim2.fromOffset(W, y0)
		strips[2].Position, strips[2].Size = UDim2.fromOffset(0, y1), UDim2.fromOffset(W, math.max(0, H - y1))
		strips[3].Position, strips[3].Size = UDim2.fromOffset(0, y0), UDim2.fromOffset(x0, math.max(0, y1 - y0))
		strips[4].Position, strips[4].Size = UDim2.fromOffset(x1, y0), UDim2.fromOffset(math.max(0, W - x1), math.max(0, y1 - y0))
	end)
end

-- Esc / gamepad B close the open window
UserInputService.InputBegan:Connect(function(input)
	if current and (input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB) then WM.closeCurrent() end
end)

-- walked away from the board that opened it (measured from the CHARACTER, not the camera)
task.spawn(function()
	local player = Players.LocalPlayer
	while true do
		task.wait(0.5)
		local char = player and player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if current and boardPos and hrp then
			local d = hrp.Position - boardPos
			if Vector3.new(d.X, 0, d.Z).Magnitude > WM.AUTO_CLOSE then WM.closeCurrent() end
		end
	end
end)

return WM
