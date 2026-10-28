-- LeaderboardController (M4, GDD 17): the TOP panel. Tabs: SPEED (all leagues), WINS, SPRINT (per
-- league area), THIS WEEK (wins + fastest Hometown Sprint, reset Monday). Top 25, scrollable.
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local UIKit = require(Shared.UIKit)
local Areas = require(Shared.Config.Areas)

local P = UIKit.Palette
local F = UIKit.Fonts
local make = UIKit.make
local player = Players.LocalPlayer

local Leaderboards = {}
local ctx
local win, list, title, sub, setTab
local tab = "SPEED"
local areaIndex = 1

local function boardKeys()
	if tab == "SPEED" then
		return { "Speed" }
	elseif tab == "WINS" then
		return { "Wins" }
	elseif tab == "SPRINT" then
		return { "Sprint_" .. Areas.Order[areaIndex] }
	end
	return { "WeeklyWins", "WeeklyTime" }
end

local function row(parent, r, order)
	local mine = r.UserId == player.UserId
	local f = UIKit.pill({ Kind = if mine then "blue" else "navy", Size = UDim2.new(1, -10, 0, 32), Parent = parent })
	f.LayoutOrder = order
	UIKit.text({ Text = tostring(r.Rank), TextSize = 16, Color = if r.Rank <= 3 then P.Gold else P.White, Size = UDim2.fromOffset(40, 30), Parent = f })
	UIKit.text({ Text = r.Name, Font = F.BodyBold, TextSize = 15, XAlign = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(46, 0), Size = UDim2.new(0.55, -46, 1, 0), Parent = f })
	UIKit.text({ Text = r.Text, TextSize = 15, Color = P.BrightBlue, XAlign = Enum.TextXAlignment.Right, Position = UDim2.new(0.55, 0, 0, 0), Size = UDim2.new(0.45, -12, 1, 0), Parent = f })
end

local function render()
	for _, ch in list:GetChildren() do
		if ch:IsA("GuiObject") then
			ch:Destroy()
		end
	end
	local order = 0
	local keys = boardKeys()
	for _, key in keys do
		local ok, c = ctx.Net.call("Leaderboard", key)
		order += 1
		if #keys > 1 then
			UIKit.text({ Text = if ok and c then c.Title else key, TextSize = 15, Color = P.Gold, XAlign = Enum.TextXAlignment.Left, Size = UDim2.new(1, -10, 0, 24), Parent = list }).LayoutOrder = order
		end
		if ok and c then
			if #keys == 1 then
				title.Text = c.Title
			end
			for _, r in c.Rows do
				order += 1
				row(list, r, order)
			end
			if #c.Rows == 0 then
				order += 1
				UIKit.text({ Text = "Nobody yet - be the first!", Font = F.BodyBold, TextSize = 14, Size = UDim2.new(1, -10, 0, 28), Parent = list }).LayoutOrder = order
			end
		else
			order += 1
			UIKit.text({ Text = "Loading... try again in a minute", Font = F.BodyBold, TextSize = 14, Size = UDim2.new(1, -10, 0, 28), Parent = list }).LayoutOrder = order
		end
	end
	if #keys > 1 then
		title.Text = "THIS WEEK"
	end
	sub.Text = if tab == "THIS WEEK" then "Resets every Monday. The top 3 for wins get a title + coins!" elseif tab == "SPRINT" then "Press the title to switch tracks" else "The whole game, every server"
end

function Leaderboards.open()
	win.show()
	setTab(tab)
end

function Leaderboards.start(c)
	ctx = c
	ctx.Leaderboards = Leaderboards
	win = UIKit.window({ Name = "Leaderboards", Title = "LEADERBOARDS", Size = Vector2.new(640, 320), Accent = P.Gold, Parent = ctx.Hud.canvas })
	setTab = UIKit.tabs(win.content, { "SPEED", "WINS", "SPRINT", "THIS WEEK" }, function(name)
		tab = name
		task.spawn(render)
	end)
	local titleBtn = make("TextButton", { BackgroundTransparency = 1, Text = "", Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 0, 26), Parent = win.content })
	title = UIKit.text({ Text = "", TextSize = 18, Color = P.Gold, XAlign = Enum.TextXAlignment.Left, Size = UDim2.fromScale(1, 1), Parent = titleBtn })
	titleBtn.Activated:Connect(function()
		if tab == "SPRINT" then
			areaIndex = areaIndex % #Areas.Order + 1
			task.spawn(render)
		end
	end)
	sub = UIKit.text({ Text = "", Font = F.BodyBold, TextSize = 13, Color = P.BrightBlue, XAlign = Enum.TextXAlignment.Right, Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 0, 26), Parent = win.content })
	list = make("ScrollingFrame", { Name = "List", BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(0, 76), Size = UDim2.new(1, 0, 1, -76), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 6, ScrollBarImageColor3 = P.ElectricBlue, Parent = win.content })
	make("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
end

return Leaderboards
