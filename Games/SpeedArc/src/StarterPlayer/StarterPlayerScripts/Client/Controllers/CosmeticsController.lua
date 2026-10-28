-- CosmeticsController: switches every character's trail on/off locally. Your own trail runs full;
-- other players' are simplified (no emitter) and off past 80 studs. On low graphics, emitters halve.
-- A short list (players in the server), checked 5 times a second. Worn meshes hide past 150 studs.
local Players = game:GetService("Players")
local UserSettings_ = UserSettings()

local Shared = game:GetService("ReplicatedStorage").Shared
local Trails = require(Shared.Config.Trails)
local CosmeticsConfig = require(Shared.Config.Cosmetics)

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local Cosmetics = {}

local function lowGraphics()
	local q = UserSettings_:GetService("UserGameSettings").SavedQualityLevel.Value
	return q ~= 0 and q <= 3
end

local function step()
	local low = lowGraphics()
	local camPos = camera.CFrame.Position
	for _, p in Players:GetPlayers() do
		local char = p.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local folder = root and root:FindFirstChild("SpeedArcTrail")
		if folder then
			local trail = folder:FindFirstChildOfClass("Trail")
			local emit = root:FindFirstChild("TrailB") and root.TrailB:FindFirstChild("Emit")
			local v = root.AssemblyLinearVelocity
			local speed = Vector3.new(v.X, 0, v.Z).Magnitude
			local fast = speed > Trails.ShowAboveWalkSpeed or p:GetAttribute("InRace") == true
			local mine = p == player
			local near = mine or (root.Position - camPos).Magnitude < Trails.OthersMaxDistance
			local on = fast and near
			if trail and trail.Enabled ~= on then
				trail.Enabled = on
			end
			if emit then
				local want = on and mine
				if emit.Enabled ~= want then
					emit.Enabled = want
				end
				local base = emit:GetAttribute("BaseRate") or emit.Rate
				emit:SetAttribute("BaseRate", base)
				emit.Rate = if low then base * 0.5 else base
			end
		end
	end
end

-- other players' worn meshes (kits, headwear, bib, shoes) hide far away (M5); checked once a second
local function hideFar()
	local camPos = camera.CFrame.Position
	for _, p in Players:GetPlayers() do
		local char = p.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root and p ~= player then
			local far = (root.Position - camPos).Magnitude > CosmeticsConfig.HideOthersBeyond
			for _, m in char:GetChildren() do
				if m:IsA("Model") and (m:GetAttribute("SpeedArcCosmetic") or m:GetAttribute("SpeedArcShoe")) and m:GetAttribute("Far") ~= far then
					m:SetAttribute("Far", far)
					for _, d in m:GetDescendants() do
						if d:IsA("BasePart") then
							d.LocalTransparencyModifier = if far then 1 else 0
						end
					end
				end
			end
		end
	end
end

function Cosmetics.start(ctx)
	ctx.Cosmetics = Cosmetics
	task.spawn(function()
		local n = 0
		while true do
			step()
			n += 1
			if n % 5 == 0 then
				hideFar()
			end
			task.wait(0.2)
		end
	end)
end

return Cosmetics
