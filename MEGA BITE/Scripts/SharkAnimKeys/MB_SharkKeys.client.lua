-- MB_SharkKeys (client): plays the shark's clips for everyone; the controller gets keys 1-6 + a key-map panel.
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CAS = game:GetService("ContextActionService")
local lp = Players.LocalPlayer
local folder = RS:WaitForChild("MB_Anim")
local remote = folder:WaitForChild("PlayClip")
local BonePlayer = require(folder:WaitForChild("BonePlayer"))
local okVFX, BiteVFX = pcall(function() return require(RS:WaitForChild("MB_VFX", 5):WaitForChild("BiteVFX", 5)) end)

local shark = workspace:WaitForChild("MB_ImportTest"):WaitForChild("MB_ReefShark_v11")
local body = shark:WaitForChild("ReefShark")
local anim = BonePlayer.new(shark, "Idle")
local NAMES = BonePlayer.ClipNames
local KEYS = {
	[Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4, [Enum.KeyCode.Five] = 5, [Enum.KeyCode.Six] = 6,
	[Enum.KeyCode.KeypadOne] = 1, [Enum.KeyCode.KeypadTwo] = 2, [Enum.KeyCode.KeypadThree] = 3,
	[Enum.KeyCode.KeypadFour] = 4, [Enum.KeyCode.KeypadFive] = 5, [Enum.KeyCode.KeypadSix] = 6,
}

-- bite flash at the snap, in front of the jaw
local function bones(n) return body:FindFirstChild(n, true) end
anim:OnMarker(function(clip, marker)
	if clip == "Bite" and marker == "Snap" and okVFX and BiteVFX then
		local jaw, head, tail = bones("Jaw"), bones("Spine0"), bones("Spine7")
		if not (jaw and head and tail) then return end
		local fwd = (head.WorldPosition - tail.WorldPosition).Unit
		local tip = jaw.WorldPosition + fwd * (shark:GetAttribute("BiteReach") or 3)
		BiteVFX.Play(CFrame.lookAt(tip, tip + fwd), {size = 6})
	end
end)

-- key-map panel (also clickable, so it works on phones)
local gui = Instance.new("ScreenGui")
gui.Name = "MB_SharkKeysGui"; gui.ResetOnSpawn = false; gui.Enabled = false
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 1); panel.Position = UDim2.new(0.5, 0, 1, -18)
panel.Size = UDim2.fromOffset(6 * 112 + 7 * 8, 92)
panel.BackgroundColor3 = Color3.fromRGB(14, 22, 48); panel.BackgroundTransparency = 0.15
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)
local st = Instance.new("UIStroke", panel); st.Thickness = 3; st.Color = Color3.fromRGB(70, 200, 255)
local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1; title.Size = UDim2.new(1, 0, 0, 24); title.Position = UDim2.fromOffset(0, 4)
title.Font = Enum.Font.FredokaOne; title.TextSize = 18; title.TextColor3 = Color3.new(1, 1, 1)
title.Text = "SHARK CONTROL  -  press 1-6  (E to stop)"; title.Parent = panel
local btns = {}
for i, n in ipairs(NAMES) do
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromOffset(112, 52); b.Position = UDim2.fromOffset(8 + (i - 1) * 120, 32)
	b.BackgroundColor3 = Color3.fromRGB(30, 60, 120); b.AutoButtonColor = true
	b.Font = Enum.Font.FredokaOne; b.TextSize = 17; b.TextColor3 = Color3.new(1, 1, 1)
	b.Text = i .. "  " .. n; b.Parent = panel
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
	local s = Instance.new("UIStroke", b); s.Thickness = 2; s.Color = Color3.fromRGB(10, 14, 30)
	b.Activated:Connect(function() remote:FireServer(n) end)
	btns[n] = b
end
gui.Parent = lp:WaitForChild("PlayerGui")

local function highlight(name)
	for n, b in pairs(btns) do
		b.BackgroundColor3 = (n == name) and Color3.fromRGB(40, 170, 255) or Color3.fromRGB(30, 60, 120)
	end
end

remote.OnClientEvent:Connect(function(name)
	anim:Play(name, 0.15)
	highlight(name)
end)

local function onKey(_, state, input)
	if state ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
	local i = KEYS[input.KeyCode]
	if i then remote:FireServer(NAMES[i]) end
	return Enum.ContextActionResult.Sink
end

local keyList = {}
for k in pairs(KEYS) do table.insert(keyList, k) end
local function refresh()
	local mine = shark:GetAttribute("ControllerId") == lp.UserId
	gui.Enabled = mine
	if mine then
		CAS:BindActionAtPriority("MB_SharkAnim", onKey, false, Enum.ContextActionPriority.High.Value + 10, table.unpack(keyList))
		highlight(anim.name)
	else
		CAS:UnbindAction("MB_SharkAnim")
	end
end
shark:GetAttributeChangedSignal("ControllerId"):Connect(refresh)
refresh()
