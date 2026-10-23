--[[
	UIStyle (client)
	One finish for every screen in the game (owner, 2026-10-24: "make all the UI looks
	professionally made by a game development studio"). The menus are built by many scripts with
	the old Gotham fonts; this pass runs over everything in PlayerGui, now and as it's made:

	  * type: Builder Sans (Roblox's own UI family) in four weights, mapped from the Gotham weights
	    the scripts ask for, so headings, labels and numbers read as one family;
	  * panels: dark panels get a soft top-to-bottom sheen, and their outlines become hairlines
	    (accent outlines - selections, warnings - are left as they are);
	  * buttons: a quick press-in and spring-back when clicked or tapped.

	World signs and the car clusters (SurfaceGuis in the world) are not touched.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local UIStyle = {}

local FAMILY = "rbxasset://fonts/families/BuilderSans.json"
local MONO = "rbxasset://fonts/families/RobotoMono.json"

local WEIGHT: { [Enum.Font]: Enum.FontWeight } = {
	[Enum.Font.GothamBlack] = Enum.FontWeight.ExtraBold,
	[Enum.Font.GothamBold] = Enum.FontWeight.Bold,
	[Enum.Font.GothamMedium] = Enum.FontWeight.Medium,
	[Enum.Font.Gotham] = Enum.FontWeight.Regular,
	[Enum.Font.SourceSansBold] = Enum.FontWeight.Bold,
	[Enum.Font.SourceSans] = Enum.FontWeight.Regular,
	[Enum.Font.Montserrat] = Enum.FontWeight.Regular,
	[Enum.Font.MontserratBold] = Enum.FontWeight.Bold,
	[Enum.Font.MontserratBlack] = Enum.FontWeight.ExtraBold,
}

local done: { [Instance]: boolean } = setmetatable({}, { __mode = "k" }) :: any
local fontsWork = pcall(function()
	return Font.new(FAMILY, Enum.FontWeight.Bold)
end)

local function styleText(t: TextLabel | TextButton | TextBox)
	if not fontsWork then
		return
	end
	local ok, font = pcall(function()
		return t.Font
	end)
	if not ok then
		return
	end
	local w = WEIGHT[font]
	if w then
		t.FontFace = Font.new(FAMILY, w)
	elseif font == Enum.Font.RobotoMono or font == Enum.Font.Code then
		t.FontFace = Font.new(MONO, Enum.FontWeight.Medium)
	end
end

-- a panel: a dark, mostly opaque frame with rounded corners
local function isPanel(f: GuiObject): boolean
	if f.BackgroundTransparency > 0.45 or not f:FindFirstChildOfClass("UICorner") then
		return false
	end
	local c = f.BackgroundColor3
	return math.max(c.R, c.G, c.B) < 0.22 and f.AbsoluteSize.X > 40 and f.AbsoluteSize.Y > 24
end

local function stylePanel(f: GuiObject)
	if not f:FindFirstChildOfClass("UIGradient") then
		local g = Instance.new("UIGradient")
		g.Rotation = 90
		g.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(206, 210, 222))
		g.Parent = f
	end
	local s = f:FindFirstChildOfClass("UIStroke")
	if s and s.Color == Config.Theme.Stroke then
		s.Transparency = math.max(s.Transparency, 0.5)
		s.Thickness = math.min(s.Thickness, 1.2)
	end
end

local function styleButton(b: GuiButton)
	local scale = b:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	scale.Parent = b
	local info = TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local back = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	b.MouseButton1Down:Connect(function()
		TweenService:Create(scale, info, { Scale = 0.94 }):Play()
	end)
	local function release()
		TweenService:Create(scale, back, { Scale = 1 }):Play()
	end
	b.MouseButton1Up:Connect(release)
	b.MouseLeave:Connect(release)
end

local function style(d: Instance)
	if done[d] then
		return
	end
	if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
		done[d] = true
		styleText(d :: any)
	end
	if d:IsA("GuiButton") and not d:FindFirstChildOfClass("UIScale") then
		done[d] = true
		styleButton(d)
	end
	if d:IsA("Frame") then
		-- (sized once laid out)
		task.defer(function()
			if d.Parent and not done[d] and isPanel(d) then
				done[d] = true
				stylePanel(d)
			end
		end)
	end
end

function UIStyle.init()
	local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
	for _, d in pg:GetDescendants() do
		style(d)
	end
	pg.DescendantAdded:Connect(style)
end

return UIStyle
