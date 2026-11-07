--[[
	The car trailer (owner, 2026-11-07: "add car trailers ... only SUVs or cars that have a trailer hitch can
	carry trailers"). A stand-in built from parts until the owner's model arrives: a flatbed car hauler with a
	drawbar, tandem axle, mudguards, two ramps and lamps. Drop a model called Config.Towing.Trailer.Id in
	ReplicatedStorage.TrailerModels and swap it in here (see the notes).

	Frame: the origin is on the ground between the axles, -Z towards the coupler, in studs. Root is the only
	anchored part; everything else hangs off it, so moving Root moves the lot (client/TrailerClient.lua moves
	it on each player's screen while it is towed). Wheels and ramps turn on Motor6Ds.
]]

local Shared = script.Parent
local Config = require(Shared:WaitForChild("Config"))

local TrailerBuilder = {}

local STEEL = Color3.fromRGB(34, 36, 40)
local ALLOY = Color3.fromRGB(150, 154, 160)
local RUBBER = Color3.fromRGB(18, 18, 20)

function TrailerBuilder.build(): Model
	local T = Config.Towing.Trailer
	local model = Instance.new("Model")
	model.Name = T.Id
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(1, 0.2, 1)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = false
	root.CanTouch = false
	root.CFrame = CFrame.new(0, 0, 0)
	root.Parent = model
	model.PrimaryPart = root

	local function part(name: string, size: Vector3, cf: CFrame, color: Color3, material: Enum.Material?, shape: Enum.PartType?): BasePart
		local p = Instance.new("Part")
		p.Name = name
		p.Shape = shape or Enum.PartType.Block
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Material = material or Enum.Material.Metal
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Anchored = false
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		p.CastShadow = true
		p.Parent = model
		return p
	end
	local function fix(p: BasePart): BasePart
		local w = Instance.new("WeldConstraint")
		w.Part0 = root
		w.Part1 = p
		w.Parent = p
		return p
	end
	local function box(name: string, size: Vector3, at: Vector3, color: Color3, material: Enum.Material?): BasePart
		return fix(part(name, size, CFrame.new(at), color, material))
	end

	local H, W = T.DeckHeight, T.Width
	local front, back = T.DeckFront, T.DeckBack
	local midZ, len = (front + back) / 2, back - front
	-- the bed: side rails, cross members and the floor. The floor and ramps carry a "Solid" attribute:
	-- they are the solid parts when it stands parked
	local floor = box("DeckFloor", Vector3.new(W, 0.12, len), Vector3.new(0, H - 0.06, midZ), ALLOY, Enum.Material.DiamondPlate)
	floor:SetAttribute("Solid", true)
	for _, x in { -W / 2 + 0.12, W / 2 - 0.12 } do
		box("SideRail", Vector3.new(0.24, 0.5, len), Vector3.new(x, H - 0.3, midZ), STEEL)
	end
	box("FrontRail", Vector3.new(W, 0.5, 0.24), Vector3.new(0, H - 0.3, front), STEEL)
	box("RearRail", Vector3.new(W, 0.5, 0.24), Vector3.new(0, H - 0.3, back), STEEL)
	for z = front + 2, back - 1, 3 do
		box("CrossMember", Vector3.new(W - 0.4, 0.28, 0.2), Vector3.new(0, H - 0.5, z), STEEL)
	end
	-- the strap rails along the deck
	for _, x in { -2.3, 2.3 } do
		box("StrapRail", Vector3.new(0.16, 0.08, len - 2), Vector3.new(x, H + 0.04, midZ), STEEL)
	end
	-- the marked spot
	for _, z in { T.LoadZ - 8, T.LoadZ + 8 } do
		box("DeckMark", Vector3.new(W - 0.6, 0.02, 0.2), Vector3.new(0, H + 0.01, z), Color3.fromRGB(228, 196, 64), Enum.Material.SmoothPlastic)
	end

	-- the drawbar: an A-frame to the coupler
	local cz, cy = -T.AxleToHitch, T.CouplerHeight
	local tip = Vector3.new(0, cy, cz + 1.1)
	for _, x in { -2.2, 2.2 } do
		local from = Vector3.new(x, H - 0.3, front)
		local d = tip - from
		local mid = from + d / 2
		fix(part("Drawbar", Vector3.new(0.26, 0.34, d.Magnitude), CFrame.lookAt(mid, tip), STEEL))
	end
	fix(part("Coupler", Vector3.new(0.34, 0.36, 1.4), CFrame.lookAt(Vector3.new(0, cy + 0.08, cz + 0.6), Vector3.new(0, cy + 0.08, cz - 1)), STEEL))
	fix(part("JackPost", Vector3.new(0.2, 1.1, 0.2), CFrame.new(0.6, cy - 0.2, cz + 3.4), ALLOY))
	box("JackFoot", Vector3.new(0.5, 0.08, 0.5), Vector3.new(0.6, cy - 0.78, cz + 3.4), STEEL)

	-- axles, wheels on Motor6Ds so each screen can spin them
	local R, tyre = T.WheelRadius, T.WheelWidth
	for _, z in { -1.15, 1.15 } do
		box("Axle", Vector3.new(W - 0.6, 0.22, 0.22), Vector3.new(0, R, z), STEEL)
		for _, x in { -(W / 2 + tyre / 2 - 0.1), W / 2 + tyre / 2 - 0.1 } do
			local p = part("Tyre", Vector3.new(tyre, R * 2, R * 2), CFrame.new(x, R, z), RUBBER, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
			local hub = part("Hub", Vector3.new(tyre + 0.04, R * 1.25, R * 1.25), CFrame.new(x, R, z), ALLOY, Enum.Material.Metal, Enum.PartType.Cylinder)
			local w = Instance.new("WeldConstraint")
			w.Part0, w.Part1 = p, hub
			w.Parent = hub
			local m = Instance.new("Motor6D")
			m.Name = "Spin"
			m.Part0 = root
			m.Part1 = p
			m.C0 = CFrame.new(x, R, z)
			m.Parent = p
		end
	end
	-- mudguards
	for _, x in { -(W / 2 + tyre / 2 - 0.1), W / 2 + tyre / 2 - 0.1 } do
		box("Mudguard", Vector3.new(tyre + 0.3, 0.12, 5.6), Vector3.new(x, R * 2 + 0.28, 0), STEEL)
		for _, z in { -2.85, 2.85 } do
			fix(part("MudguardEnd", Vector3.new(tyre + 0.3, 0.12, 0.9), CFrame.new(x, R * 2 - 0.05, z) * CFrame.Angles(math.rad(if z > 0 then 48 else -48), 0, 0), STEEL))
		end
	end

	-- the ramps: slide-outs under the deck; TrailerClient slides them out and tips them to the road
	local rl = T.RampLength
	for _, x in { -2.15, 2.15 } do
		local r = part("Ramp", Vector3.new(1.7, 0.16, rl), CFrame.new(x, H, back + rl / 2), ALLOY, Enum.Material.DiamondPlate)
		r:SetAttribute("Solid", true)
		local m = Instance.new("Motor6D")
		m.Name = "Hinge"
		m.Part0 = root
		m.Part1 = r
		m.C0 = CFrame.new(x, H, back)
		m.C1 = CFrame.new(0, 0, -rl / 2)
		m.Parent = r
	end

	-- the lamps, under the rear rail: dark until TrailerClient lights them
	local function lamp(name: string, x: number, w: number, color: Color3)
		local p = box(name, Vector3.new(w, 0.3, 0.1), Vector3.new(x, H - 0.72, back + 0.16), color, Enum.Material.SmoothPlastic)
		p:SetAttribute("Lamp", name:sub(1, 4))
		p:SetAttribute("Side", if x < 0 then "L" else "R")
		p:SetAttribute("Lit", color)
		p.Color = color:Lerp(Color3.new(0, 0, 0), 0.72)
		p.CastShadow = false
	end
	box("LampBar", Vector3.new(W, 0.4, 0.14), Vector3.new(0, H - 0.72, back + 0.08), STEEL)
	for _, s in { -1, 1 } do
		lamp("TailLamp", s * 2.5, 0.9, Color3.fromRGB(255, 22, 22))
		lamp("TurnLamp", s * 3.1, 0.34, Color3.fromRGB(255, 140, 16))
		lamp("RevsLamp", s * 1.9, 0.3, Color3.fromRGB(255, 252, 244))
	end
	-- the number plate
	local plate = box("Plate", Vector3.new(1.5, 0.42, 0.06), Vector3.new(0, H - 0.72, back + 0.17), Color3.fromRGB(226, 226, 222), Enum.Material.SmoothPlastic)
	plate.CastShadow = false

	model:SetAttribute("Length", back - cz)
	model:SetAttribute("Width", W + tyre * 2)
	return model
end

return TrailerBuilder
