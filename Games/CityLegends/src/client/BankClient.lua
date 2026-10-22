--[[
	BankClient
	The robbery on screen: the bag you carry ("LOOT $45,000"), an arrow and distance to the
	drop-off, and the messages (robbery in progress, bag full, lose the cops first, paid, lost).
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local UI = require(script.Parent:WaitForChild("UI"))
local Audio = require(script.Parent:WaitForChild("Audio"))

local Theme = Config.Theme
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local BankClient = {}

local function formatCash(n: number): string
	local s = tostring(math.floor(n))
	local f = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	if f:sub(1, 1) == "," then
		f = f:sub(2)
	end
	return "$" .. f
end

function BankClient.init()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local event = remotes:WaitForChild("BankEvent") :: RemoteEvent

	local gui = Instance.new("ScreenGui")
	gui.Name = "BankHUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 11
	gui.Parent = player:WaitForChild("PlayerGui")

	local card = Instance.new("Frame")
	card.AnchorPoint = Vector2.new(0.5, 0)
	card.Position = UDim2.new(0.5, 0, 0, 132)
	card.Size = UDim2.fromOffset(260, 54)
	card.BackgroundColor3 = Theme.Panel
	card.BackgroundTransparency = 0.1
	card.Visible = false
	card.Parent = gui
	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(0, 12)
	cc.Parent = card
	local st = Instance.new("UIStroke")
	st.Color = Theme.Money
	st.Thickness = 1.5
	st.Transparency = 0.2
	st.Parent = card
	local loot = Instance.new("TextLabel")
	loot.BackgroundTransparency = 1
	loot.Position = UDim2.fromOffset(14, 4)
	loot.Size = UDim2.new(1, -28, 0, 26)
	loot.Font = Enum.Font.GothamBlack
	loot.TextSize = 22
	loot.TextColor3 = Theme.Money
	loot.TextXAlignment = Enum.TextXAlignment.Left
	loot.Parent = card
	local hint = Instance.new("TextLabel")
	hint.BackgroundTransparency = 1
	hint.Position = UDim2.fromOffset(14, 29)
	hint.Size = UDim2.new(1, -28, 0, 18)
	hint.Font = Enum.Font.GothamMedium
	hint.TextSize = 13
	hint.TextColor3 = Theme.SubText
	hint.TextXAlignment = Enum.TextXAlignment.Left
	hint.Parent = card

	-- an arrow at the screen edge pointing to the drop-off
	local arrow = Instance.new("TextLabel")
	arrow.AnchorPoint = Vector2.new(0.5, 0.5)
	arrow.Size = UDim2.fromOffset(44, 44)
	arrow.BackgroundTransparency = 1
	arrow.Font = Enum.Font.GothamBlack
	arrow.Text = "▲"
	arrow.TextSize = 40
	arrow.TextColor3 = Theme.Money
	arrow.TextStrokeTransparency = 0.3
	arrow.Visible = false
	arrow.Parent = gui

	RunService.RenderStepped:Connect(function()
		local amount = (player:GetAttribute("Loot") :: number?) or 0
		local drop = workspace:GetAttribute("Dropoff") :: Vector3?
		if amount <= 0 or not drop then
			card.Visible = false
			arrow.Visible = false
			return
		end
		card.Visible = true
		loot.Text = "LOOT  " .. formatCash(amount)
		local here = camera.CFrame.Position
		local dist = Vector3.new(drop.X - here.X, 0, drop.Z - here.Z).Magnitude
		local wanted = (player:GetAttribute("Wanted") :: number?) or 0
		hint.Text = (if wanted > 0 then "Lose the cops, then " else "") .. string.format("drop-off %d m", math.floor(dist / 3))
		-- the arrow: towards the drop-off, around the middle of the screen
		local look = camera.CFrame.LookVector
		local flatLook = Vector3.new(look.X, 0, look.Z).Unit
		local to = Vector3.new(drop.X - here.X, 0, drop.Z - here.Z).Unit
		local ang = math.atan2(flatLook:Cross(to).Y, flatLook:Dot(to))
		arrow.Visible = dist > 30
		arrow.Rotation = -math.deg(ang)
		arrow.Position = UDim2.new(0.5 + math.sin(-ang) * 0.12, 0, 0.5 - math.cos(ang) * 0.2, 0)
	end)

	event.OnClientEvent:Connect(function(info)
		if type(info) ~= "table" then
			return
		end
		if info.kind == "robbery" then
			UI.toast(`{info.by} is robbing the Legends Reserve Bank!`, Theme.Danger)
		elseif info.kind == "grab" then
			UI.popup("CASH GRABBED", tonumber(info.amount) or 0, Theme.Money)
			Audio.cutUp(2, "CASH")
		elseif info.kind == "full" then
			UI.toast("Your bag is full: get to the drop-off", Theme.Warning)
		elseif info.kind == "losecops" then
			UI.toast("Lose the cops first!", Theme.Warning)
		elseif info.kind == "paid" then
			UI.popup("HEIST COMPLETE", tonumber(info.amount) or 0, Theme.Money)
			Audio.cutUp(5, "HEIST")
		elseif info.kind == "lost" then
			UI.toast("Busted: the loot is gone", Theme.Danger)
		end
	end)
end

return BankClient
