--[[
	GGFest (2026-11-17): GG Gaming Fest at the Yangon Convention Centre, 21-22 Nov 2026 (Config.GGFest)
	  * the screens at YCC (parts tagged GGFestScreen, a SurfaceGui TextLabel "Text"): a countdown before the
	    festival, LIVE while it's on, a thank-you after
	  * workspace attribute GGFestLive (the minimap's live marker)
	  * the GG Quest's two place steps, checked here on the server from the player's own position:
	    reaching YCC ("ggarrive") and stopping on the photo spot at the stage ("ggphoto"); Goals counts them
	Studio test: workspace attribute GGFestForce = true (Config.ggLive).
]]

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local GGFest = {}

local GG = Config.GGFest
local LINE = "21-22 NOV · YANGON CONVENTION CENTRE"

local function clock(s: number): string
	s = math.max(0, math.floor(s))
	local d = s // 86400
	local hms = string.format("%02d:%02d:%02d", (s % 86400) // 3600, (s % 3600) // 60, s % 60)
	return if d > 0 then string.format("%dd %s", d, hms) else hms
end

local function screenText(now: number, live: boolean): string
	if live then
		return "GG GAMING FEST\nLIVE NOW · " .. LINE
	elseif now < GG.Start then
		return "GG GAMING FEST\nSTARTS IN " .. clock(GG.Start - now) .. "\n" .. LINE
	end
	return "GG GAMING FEST\nTHANKS FOR COMING · 21-22 NOV 2026"
end

local function flat(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

function GGFest.init(ctx: any)
	local arrived: { [Player]: boolean } = {}
	local photographed: { [Player]: boolean } = {}
	Players.PlayerRemoving:Connect(function(p)
		arrived[p] = nil
		photographed[p] = nil
	end)
	-- Studio test hook: server player attribute TestGGNote = "stat:n" reports a goal stat (cuts, combo, drifts ...)
	if game:GetService("RunService"):IsStudio() then
		local function hook(p: Player)
			p:GetAttributeChangedSignal("TestGGNote"):Connect(function()
				local stat, n = string.match(tostring(p:GetAttribute("TestGGNote")), "^(%w+):(%d+)$")
				if stat then
					ctx.note(p, stat, tonumber(n))
				end
			end)
		end
		Players.PlayerAdded:Connect(hook)
		for _, p in Players:GetPlayers() do
			hook(p)
		end
	end
	task.spawn(function()
		while true do
			local now = os.time()
			local live = Config.ggLive(now)
			if workspace:GetAttribute("GGFestLive") ~= live then
				workspace:SetAttribute("GGFestLive", live)
			end
			local text = screenText(now, live)
			for _, part in CollectionService:GetTagged("GGFestScreen") do
				local label = part:FindFirstChild("Text", true)
				if label and label:IsA("TextLabel") and label.Text ~= text then
					label.Text = text
				end
			end
			if live then
				for _, p in Players:GetPlayers() do
					-- in a car the player has no character: the car's root counts
					local car = ctx.playerCars:FindFirstChild(p.Name) :: Model?
					local root = (if car then car.PrimaryPart else nil)
						or (p.Character and p.Character:FindFirstChild("HumanoidRootPart") :: BasePart?)
					if root then
						local at = root.Position
						if not arrived[p] and flat(at, GG.Hall) < GG.ArriveRadius and math.abs(at.Y - GG.Hall.Y) < 60 then
							arrived[p] = true
							ctx.note(p, "ggarrive", 1)
						end
						local v = root.AssemblyLinearVelocity
						if not photographed[p] and flat(at, GG.Photo) < GG.PhotoRadius and math.abs(at.Y - GG.Photo.Y) < 15
							and Vector3.new(v.X, 0, v.Z).Magnitude < GG.PhotoSpeed then
							photographed[p] = true
							ctx.note(p, "ggphoto", 1)
						end
					end
				end
			end
			task.wait(1)
		end
	end)
end

return GGFest
