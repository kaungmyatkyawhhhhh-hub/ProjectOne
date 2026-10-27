-- MenuController: the left menu (LOCKER, COACHES for M2) and the hub's shop prompts
-- (Shoe Shop -> Locker SHOES, Trail Booth -> Locker TRAILS, Coach Corner -> COACHES).
-- Also the shop pedestals: shoes turn slowly, locked pairs show dark with "UNLOCKS AT ...".
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")

local Shared = game:GetService("ReplicatedStorage").Shared
local UIKit = require(Shared.UIKit)
local Art = require(Shared.Util.Art)
local Boosts = require(Shared.Util.Boosts)
local Shoes = require(Shared.Config.Shoes)

local P = UIKit.Palette
local make = UIKit.make
local player = Players.LocalPlayer

local Menu = {}
local ctx
local pedestals = {} -- { shoe, model, base CFrame, sign label, wasUnlocked }

local function buildMenu()
	local holder = make("Frame", { Name = "LeftMenu", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 14, 0.5, -10), Size = UDim2.fromOffset(124, 112), Parent = ctx.Hud.canvas })
	make("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = holder })
	local locker = UIKit.button({ Name = "Locker", Style = "Blue", Text = "LOCKER", TextSize = 18, Size = UDim2.fromOffset(124, 48), OnClick = function()
		ctx.Locker.open("SHOES")
	end })
	locker.LayoutOrder = 1
	locker.Parent = holder
	local coaches = UIKit.button({ Name = "Coaches", Style = "Gold", Text = "COACHES", TextSize = 18, Size = UDim2.fromOffset(124, 48), OnClick = function()
		ctx.Coaches.open("ROLL")
	end })
	coaches.LayoutOrder = 2
	coaches.Parent = holder
	ctx.Hud.refs.menu = holder
end

local function buildPedestals()
	local hub = workspace:WaitForChild("Hub")
	local shop = hub:WaitForChild("Shops", 10)
	local spots = shop and shop:FindFirstChild("ShoePedestals", true)
	if not spots then
		return
	end
	for _, spot in spots:GetChildren() do
		local idx = spot:GetAttribute("ShoeIndex")
		local shoe = idx and Shoes.List[idx]
		if shoe then
			local entry = { shoe = shoe, spot = spot, model = nil, label = spot:FindFirstChild("Label", true), unlocked = nil }
			table.insert(pedestals, entry)
		end
	end
end

local function dataView(coll)
	return { Speed = player:GetAttribute("Speed") or 0, League = coll and coll.League or 1, BestLeague = coll and coll.BestLeague or 1, BestRank = coll and coll.BestRank }
end

local function refreshPedestals()
	local coll = ctx.Locker.collection()
	for _, e in pedestals do
		local owned = coll and coll.OwnedShoes and coll.OwnedShoes[e.shoe.Id]
		local unlocked = owned or Boosts.unlocked(dataView(coll), e.shoe.Unlock)
		if unlocked ~= e.unlocked then
			e.unlocked = unlocked
			if e.model then
				e.model:Destroy()
			end
			e.model = Art.shoeModel(e.shoe, 1.6, not unlocked)
			e.base = e.spot.CFrame * CFrame.new(0, e.spot.Size.Y / 2 + 0.05, 0)
			e.model:PivotTo(e.base)
			e.model.Parent = e.spot
			if e.label then
				e.label.Text = if unlocked then string.upper(e.shoe.Name) else Boosts.unlockText(e.shoe.Unlock)
				e.label.TextColor3 = if unlocked then P.White else P.Gold
			end
		end
	end
end

function Menu.start(c)
	ctx = c
	buildMenu()

	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		local open = prompt:GetAttribute("Opens")
		if open == "ShoeShop" then
			ctx.Locker.open("SHOES")
		elseif open == "TrailBooth" then
			ctx.Locker.open("TRAILS")
		elseif open == "CoachCorner" then
			ctx.Coaches.open("ROLL")
		end
	end)

	task.spawn(function()
		buildPedestals()
		refreshPedestals()
		ctx.Net.get("Collection").OnClientEvent:Connect(function()
			task.defer(refreshPedestals)
		end)
		player:GetAttributeChangedSignal("Speed"):Connect(refreshPedestals)
		-- turn the shoes slowly, only when you're near the shop
		local camera = workspace.CurrentCamera
		local acc = 0
		RunService.Heartbeat:Connect(function(dt)
			acc += dt
			if acc < 1 / 30 or #pedestals == 0 then
				return
			end
			local step = acc
			acc = 0
			local near = (pedestals[1].spot.Position - camera.CFrame.Position).Magnitude < 120
			if not near then
				return
			end
			local t = os.clock()
			for i, e in pedestals do
				if e.model and e.base then
					e.model:PivotTo(e.base * CFrame.new(0, 0.15 + math.sin(t * 1.5 + i) * 0.08, 0) * CFrame.Angles(0, t * 0.6 + i, 0))
				end
			end
		end)
	end)
end

return Menu
