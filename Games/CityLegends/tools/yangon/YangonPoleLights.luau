--[[
	YangonPoleLights (Studio, Edit mode; 14 Nov 2026, batch 0.5 playtest: the new side streets were dark at night).

	Real Yangon side streets are lit by white LED lamps on the concrete power poles. After YangonDetails has placed the poles
	(Workspace.Yangon.Details.pole/<cell>/pole Models: the shaft is the longest part), every second pole gets a lamp: a small
	white head under the crossarm (Neon at night through tag LampGlow) with a PointLight (white, range 30) tagged LODLight +
	DayOff, so WorldFx switches it on at night and off past its range, like the street lamps.

	Run again after YangonDetails.spawn() (it clears the poles): require(ClaudeTools.YangonPoleLights:Clone()).run()
]]

local CollectionService = game:GetService("CollectionService")

local M = {}

function M.run(): string
	local f = workspace.Yangon:FindFirstChild("Details")
	f = f and f:FindFirstChild("pole")
	if not f then
		return "no poles"
	end
	local n, made = 0, 0
	for _, cell in f:GetChildren() do
		for _, m in cell:GetChildren() do
			n += 1
			if n % 2 == 0 or m:FindFirstChild("PoleLamp") then
				continue
			end
			local shaft
			for _, p in m:GetChildren() do
				if p:IsA("BasePart") and (not shaft or p.Size.Magnitude > shaft.Size.Magnitude) then
					shaft = p
				end
			end
			if not shaft then
				continue
			end
			local long = math.max(shaft.Size.X, shaft.Size.Y, shaft.Size.Z)
			local top = shaft.Position.Y + long / 2
			local head = Instance.new("Part")
			head.Name = "PoleLamp"
			head.Anchored = true
			head.CanCollide = false
			head.CanQuery = false
			head.CanTouch = false
			head.CastShadow = false
			head.Size = Vector3.new(1.3, 0.45, 0.7)
			head.Color = Color3.fromRGB(236, 244, 255)
			head.Material = Enum.Material.SmoothPlastic
			head.CFrame = CFrame.new(shaft.Position.X, top - 5.5, shaft.Position.Z) * CFrame.new(0, 0, 0.9)
			head.Parent = m
			CollectionService:AddTag(head, "LampGlow")
			local l = Instance.new("PointLight")
			l.Color = Color3.fromRGB(232, 240, 255)
			l.Range = 30
			l.Brightness = 1.6
			l.Shadows = false
			l.Parent = head
			CollectionService:AddTag(l, "LODLight")
			CollectionService:AddTag(l, "DayOff")
			made += 1
		end
		if n % 400 == 0 then
			task.wait()
		end
	end
	return string.format("%d poles, %d lamps", n, made)
end

return M
