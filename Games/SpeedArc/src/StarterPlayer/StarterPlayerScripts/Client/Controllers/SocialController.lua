-- SocialController (M4, GDD 14 + 18): tap another runner -> VIEW PROFILE / RACE THEM / ADD FRIEND,
-- the profile window (yours too, with a title picker), RACE THEM requests, Friend Boost toasts,
-- the INVITE button and the favourite prompt (once, after your first Go Pro).
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local SocialService = game:GetService("SocialService")
local AvatarEditorService = game:GetService("AvatarEditorService")

local Shared = game:GetService("ReplicatedStorage").Shared
local UIKit = require(Shared.UIKit)
local Format = require(Shared.Util.Format)
local Areas = require(Shared.Config.Areas)
local Ranks = require(Shared.Config.Ranks)

local P = UIKit.Palette
local F = UIKit.Fonts
local make = UIKit.make
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local Social = {}
local ctx, canvas
local quick, quickName, quickTarget, quickHideAt
local askCard, askText, askFrom, askUntil
local profileWin, profileBody

----------------------------------------------------------------------------
-- quick menu (bottom centre)
----------------------------------------------------------------------------
local function hideQuick()
	quick.Visible = false
	quickTarget = nil
end

local function showQuick(target)
	quickTarget = target
	quickName.Text = string.upper(target.DisplayName)
	quick.Visible = true
	quickHideAt = os.clock() + 7
	ctx.Sound.play("Toast")
end

local function line(parent, y, label, value, color)
	UIKit.text({ Text = label, Font = F.BodyBold, TextSize = 13, Color = P.BrightBlue, XAlign = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(0, y), Size = UDim2.new(0.45, 0, 0, 20), Parent = parent })
	UIKit.text({ Text = value, Font = F.BodyBold, TextSize = 15, Color = color or P.White, XAlign = Enum.TextXAlignment.Left, Position = UDim2.new(0.45, 0, 0, y), Size = UDim2.new(0.55, 0, 0, 20), Parent = parent })
end

local function renderProfile(p)
	for _, ch in profileBody:GetChildren() do
		ch:Destroy()
	end
	local mine = p.UserId == player.UserId
	local left = UIKit.panel({ Position = UDim2.fromOffset(0, 0), Size = UDim2.new(0.38, -6, 1, 0), Parent = profileBody })
	local inner = make("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(18, 10), Size = UDim2.new(1, -28, 1, -20), Parent = left })
	UIKit.text({ Text = string.upper(p.Name), TextSize = 22, XAlign = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 26), Parent = inner })
	UIKit.text({ Text = if p.Title ~= "" then p.Title else "NO TITLE YET", TextSize = 15, Color = P.Gold, XAlign = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 20), Parent = inner })
	local rankColor = Ranks.Colors[p.Rank] or P.White
	line(inner, 60, "LEAGUE", ("%d  -  %s"):format(p.League, string.upper(p.Rank)), rankColor)
	line(inner, 82, "SPEED", Format.short(p.Speed) .. " MPH")
	line(inner, 104, "TOP HERE", Format.short(p.TopSpeed and p.TopSpeed[tostring(p.League)] or p.Speed) .. " MPH")
	line(inner, 126, "WINS", ("%d of %d races"):format(p.Wins, p.Races))
	line(inner, 148, "PLAYED", ("%d min"):format(p.PlayMinutes))
	if mine and #p.Titles > 1 then
		UIKit.button({ Style = "Dark", Text = "CHANGE TITLE", TextSize = 14, Position = UDim2.fromOffset(0, 176), Size = UDim2.new(1, 0, 0, 36), Parent = inner, OnClick = function()
			local i = table.find(p.Titles, p.Title) or 0
			local nextTitle = p.Titles[i % #p.Titles + 1]
			if ctx.Net.call("SetTitle", nextTitle) then
				p.Title = nextTitle
				renderProfile(p)
			end
		end })
	end

	local mid = UIKit.panel({ Position = UDim2.new(0.38, 0, 0, 0), Size = UDim2.new(0.31, -6, 1, 0), AccentColor = P.Gold, Parent = profileBody })
	local m = make("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(18, 10), Size = UDim2.new(1, -28, 1, -20), Parent = mid })
	UIKit.text({ Text = "MEDALS", TextSize = 16, Color = P.Gold, XAlign = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 20), Parent = m })
	local medals = make("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 0, 40), Parent = m })
	for i, kind in { "Gold", "Silver", "Bronze" } do
		local holder = make("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset((i - 1) * 54, 0), Size = UDim2.fromOffset(50, 40), Parent = medals })
		pcall(UIKit.medalIcon, kind, 34, holder, p.Medals[kind])
	end
	UIKit.text({ Text = "BEST TIMES", TextSize = 16, Color = P.Gold, XAlign = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(0, 72), Size = UDim2.new(1, 0, 0, 20), Parent = m })
	local y = 96
	for _, id in Areas.Order do
		local t = p.BestTimes[id .. "_Sprint"]
		if t then
			line(m, y, string.upper(Areas[id].Name):sub(1, 12), ("%.2f s"):format(t))
			y += 22
		end
	end
	if y == 96 then
		UIKit.text({ Text = "No races yet", Font = F.BodyBold, TextSize = 13, XAlign = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(0, 96), Size = UDim2.new(1, 0, 0, 20), Parent = m })
	end

	local right = UIKit.panel({ Position = UDim2.new(0.69, 0, 0, 0), Size = UDim2.new(0.31, 0, 1, 0), AccentColor = P.BrightBlue, Parent = profileBody })
	local r = make("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(18, 10), Size = UDim2.new(1, -28, 1, -20), Parent = right })
	UIKit.text({ Text = "COACHES", TextSize = 16, Color = P.Gold, XAlign = Enum.TextXAlignment.Left, Size = UDim2.new(1, 0, 0, 20), Parent = r })
	for i, c in p.Coaches do
		UIKit.text({ Text = ("%s  %s"):format(c.Name, c.Stage ~= "BASE" and c.Stage or ""), Font = F.BodyBold, TextSize = 14, XAlign = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(0, 2 + i * 22), Size = UDim2.new(1, 0, 0, 20), Parent = r })
	end
	if #p.Coaches == 0 then
		UIKit.text({ Text = "None yet", Font = F.BodyBold, TextSize = 13, XAlign = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 0, 20), Parent = r })
	end
	UIKit.text({ Text = "TRAIL", TextSize = 16, Color = P.Gold, XAlign = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(0, 120), Size = UDim2.new(1, 0, 0, 20), Parent = r })
	UIKit.text({ Text = p.Trail or "-", Font = F.BodyBold, TextSize = 14, XAlign = Enum.TextXAlignment.Left, Position = UDim2.fromOffset(0, 142), Size = UDim2.new(1, 0, 0, 20), Parent = r })
end

function Social.openProfile(userId)
	local ok, p = ctx.Net.call("Profile", userId)
	if not ok or not p then
		ctx.Hud.toast("That runner left", "Denied")
		return
	end
	profileWin.show()
	renderProfile(p)
end

local function raceThem(target)
	local ok, why = ctx.Net.call("RaceThem", target.UserId)
	if ok then
		ctx.Hud.toast(("Asked %s to race. Waiting..."):format(target.DisplayName), "Gold")
	else
		ctx.Hud.toast(if why == "busy" then "One of you is busy right now" elseif why == "area" then "You need to be in the same area" elseif why == "pending" then "They already have a race request" else "Can't race right now", "Denied")
	end
end

function Social.invite()
	local can = false
	pcall(function()
		can = SocialService:CanSendGameInviteAsync(player)
	end)
	if not can then
		ctx.Hud.toast("Invites aren't available right now", "Denied")
		return
	end
	local opts = Instance.new("ExperienceInviteOptions")
	opts.PromptMessage = "Race me in SPEED ARC!"
	opts.LaunchData = "invite:" .. player.UserId
	pcall(function()
		SocialService:PromptGameInvite(player, opts)
	end)
end

----------------------------------------------------------------------------
local function build()
	quick = UIKit.panel({ Name = "PlayerMenu", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -70), Size = UDim2.fromOffset(440, 92), ZIndex = 15, Parent = canvas })
	quick.Visible = false
	quickName = UIKit.text({ Text = "", TextSize = 18, Position = UDim2.fromOffset(0, 6), Size = UDim2.new(1, 0, 0, 22), ZIndex = 16, Parent = quick })
	local function qb(x, text, style, fn)
		UIKit.button({ Style = style, Text = text, TextSize = 15, Position = UDim2.fromOffset(x, 36), Size = UDim2.fromOffset(132, 44), ZIndex = 16, Parent = quick, OnClick = function()
			local t = quickTarget
			hideQuick()
			if t and t.Parent then
				fn(t)
			end
		end })
	end
	qb(14, "VIEW PROFILE", "Blue", function(t)
		Social.openProfile(t.UserId)
	end)
	qb(154, "RACE THEM", "Gold", raceThem)
	qb(294, "ADD FRIEND", "Dark", function(t)
		pcall(function()
			StarterGui:SetCore("PromptSendFriendRequest", t)
		end)
	end)

	askCard = UIKit.panel({ Name = "RaceAsk", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -70), Size = UDim2.fromOffset(400, 92), AccentColor = P.Gold, StrokeColor = P.Gold, ZIndex = 16, Parent = canvas })
	askCard.Visible = false
	askText = UIKit.text({ Text = "", TextSize = 17, Position = UDim2.fromOffset(0, 6), Size = UDim2.new(1, 0, 0, 24), ZIndex = 17, Parent = askCard })
	local function answer(yes)
		askCard.Visible = false
		local from = askFrom
		askFrom = nil
		if from then
			task.spawn(function()
				local ok = ctx.Net.call("RaceAnswer", from, yes)
				if yes and not ok then
					ctx.Hud.toast("That race can't start now", "Denied")
				end
			end)
		end
	end
	UIKit.button({ Style = "Gold", Text = "RACE!", TextSize = 17, Position = UDim2.fromOffset(40, 38), Size = UDim2.fromOffset(150, 44), ZIndex = 17, Parent = askCard, OnClick = function()
		answer(true)
	end })
	UIKit.button({ Style = "Dark", Text = "NOT NOW", TextSize = 17, Position = UDim2.fromOffset(210, 38), Size = UDim2.fromOffset(150, 44), ZIndex = 17, Parent = askCard, OnClick = function()
		answer(false)
	end })

	profileWin = UIKit.window({ Name = "Profile", Title = "PROFILE", Size = Vector2.new(700, 300), Parent = canvas })
	profileBody = make("Frame", { Name = "Body", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, 10), Size = UDim2.new(1, 0, 1, -10), Parent = profileWin.content })
end

local function playerAt(pos)
	local ray = camera:ViewportPointToRay(pos.X, pos.Y)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character }
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 200, params)
	local model = hit and hit.Instance:FindFirstAncestorOfClass("Model")
	return model and Players:GetPlayerFromCharacter(model)
end

function Social.start(c)
	ctx = c
	ctx.Social = Social
	canvas = ctx.Hud.canvas
	build()

	-- tap / click another runner (not while training or racing: those taps are for running)
	local downAt, downPos = 0, nil
	UserInputService.InputBegan:Connect(function(input, processed)
		local t = input.UserInputType
		if processed or (t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch) then
			return
		end
		downAt, downPos = os.clock(), input.Position
	end)
	UserInputService.InputEnded:Connect(function(input, processed)
		local t = input.UserInputType
		if processed or not downPos or (t ~= Enum.UserInputType.MouseButton1 and t ~= Enum.UserInputType.Touch) then
			return
		end
		if os.clock() - downAt > 0.35 or (input.Position - downPos).Magnitude > 12 then
			return -- a drag (camera) or a hold, not a tap
		end
		if ctx.Training.isTraining() or player:GetAttribute("InRace") then
			return
		end
		local target = playerAt(input.Position)
		if target and target ~= player then
			showQuick(target)
		end
	end)

	-- your own profile: tap the rank badge
	local rank = ctx.Hud.refs.rank
	if rank then
		local hit = make("TextButton", { Name = "ProfileHit", BackgroundTransparency = 1, Text = "", Size = UDim2.fromScale(1, 1), Parent = rank })
		hit.Activated:Connect(function()
			Social.openProfile(player.UserId)
		end)
	end

	ctx.Net.get("Social").OnClientEvent:Connect(function(kind, info)
		if kind == "friend" then
			if info.Boost then
				ctx.Hud.toast(("%s is here! Friend Boost +%d%%"):format(info.Name, math.floor(info.Boost * 100 + 0.5)), "Gold")
			end
		elseif kind == "friendTotal" then
			ctx.Hud.toast(("Friends here! Friend Boost +%d%%"):format(math.floor(info.Boost * 100 + 0.5)), "Gold")
		elseif kind == "raceAsk" then
			askFrom = info.FromId
			askUntil = os.clock() + info.Seconds
			askText.Text = ("%s wants to race you!"):format(string.upper(info.Name))
			askCard.Visible = true
			ctx.Sound.play("Join")
		end
	end)

	-- the favourite prompt: once, after your first Go Pro (after the arrival banner)
	player:GetAttributeChangedSignal("League"):Connect(function()
		if (player:GetAttribute("League") or 1) == 2 then
			task.delay(7, function()
				local ok, first = ctx.Net.call("Prompted", "Favourite")
				if ok and first then
					pcall(function()
						AvatarEditorService:PromptSetFavorite(game.PlaceId, Enum.AvatarItemType.Asset, true)
					end)
				end
			end)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(0.5)
			if quick.Visible and os.clock() > quickHideAt then
				hideQuick()
			end
			if askCard.Visible and askUntil and os.clock() > askUntil then
				askCard.Visible = false
				askFrom = nil
			end
		end
	end)
end

return Social
