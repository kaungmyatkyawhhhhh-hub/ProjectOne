--[[
	The car trailer (owner, 2026-11-07: "add car trailers ... only SUVs or cars that have a trailer hitch can
	carry trailers"). The owner's model is ReplicatedStorage.TrailerModels.hauler ("Flatbed Baked" by 3DE_Study,
	CC BY 4.0; tools/trailer_export.py): Body and four Wheel_ parts. It is a semi-trailer, so a drawbar, ramps,
	working lamps, a plate and a solid deck are added here. Without the model (a fresh Rojo build) a plain deck
	stands in.

	Frame: the origin is on the ground between the axles, -Z towards the coupler, in studs. Root is the only
	anchored part; everything else hangs off it, so moving Root moves the lot (client/TrailerClient.lua moves
	it on each player's screen while it is towed). Wheels and ramps turn on Motor6Ds.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

	local function setup(p: BasePart)
		p.Anchored = false
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		p.Parent = model
	end
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
		p.CastShadow = true
		setup(p)
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
	local function spin(p: BasePart, at: Vector3)
		local m = Instance.new("Motor6D")
		m.Name = "Spin"
		m.Part0 = root
		m.Part1 = p
		m.C0 = CFrame.new(at)
		m.Parent = p
	end

	local H, W = T.DeckHeight, T.Width
	local front, back = T.DeckFront, T.DeckBack
	local midZ, len = (front + back) / 2, back - front
	local folder = ReplicatedStorage:FindFirstChild("TrailerModels")
	local src = if folder then folder:FindFirstChild(T.Id) else nil
	local realModel = src ~= nil
	if src then
		for _, d in src:GetChildren() do
			if d:IsA("BasePart") then
				local p = d:Clone()
				setup(p)
				if d.Name:sub(1, 5) == "Wheel" then
					spin(p, d.Position)
				else
					fix(p)
				end
			end
		end
	else
		box("RailL", Vector3.new(0.24, 0.5, len), Vector3.new(-W / 2 + 0.12, H - 0.3, midZ), STEEL)
		box("RailR", Vector3.new(0.24, 0.5, len), Vector3.new(W / 2 - 0.12, H - 0.3, midZ), STEEL)
		box("RearRail", Vector3.new(W, 0.5, 0.24), Vector3.new(0, H - 0.3, back), STEEL)
		box("LampBar", Vector3.new(W, 0.6, 0.14), Vector3.new(0, 2.73, back - 0.08), STEEL)
		local R, tyre = T.WheelRadius, T.WheelWidth
		for _, z in { -1.35, 1.35 } do
			box("Axle", Vector3.new(W - 0.6, 0.22, 0.22), Vector3.new(0, R, z), STEEL)
			for _, x in { -(W / 2 - tyre / 2 - 0.1), W / 2 - tyre / 2 - 0.1 } do
				local at = Vector3.new(x, R, z)
				local p = part("Tyre", Vector3.new(tyre, R * 2, R * 2), CFrame.new(at), RUBBER, Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
				spin(p, at)
			end
		end
	end
	-- the solid floor (the floor and ramps carry a "Solid" attribute: solid when it stands parked)
	local floor = box("DeckFloor", Vector3.new(W, 0.12, len), Vector3.new(0, H - 0.06, midZ), ALLOY, Enum.Material.DiamondPlate)
	floor:SetAttribute("Solid", true)
	if realModel then
		floor.Transparency = 1
	end
	-- the marked spot
	for _, z in { T.LoadZ - 8.4, T.LoadZ + 8.4 } do
		box("DeckMark", Vector3.new(W - 1, 0.02, 0.2), Vector3.new(0, H + 0.02, z), Color3.fromRGB(228, 196, 64), Enum.Material.SmoothPlastic)
	end

	-- the drawbar: an A-frame from under the deck to the coupler
	local cz, cy = -T.AxleToHitch, T.CouplerHeight
	local tip = Vector3.new(0, cy, cz + 1.1)
	for _, x in { -2.4, 2.4 } do
		local from = Vector3.new(x, H - 0.45, front + 1.5)
		local d = tip - from
		fix(part("Drawbar", Vector3.new(0.3, 0.4, d.Magnitude), CFrame.lookAt(from + d / 2, tip), STEEL))
	end
	box("DrawbarCross", Vector3.new(5.1, 0.3, 0.3), Vector3.new(0, H - 0.45, front + 1.5), STEEL)
	fix(part("Coupler", Vector3.new(0.34, 0.36, 1.4), CFrame.lookAt(Vector3.new(0, cy + 0.08, cz + 0.6), Vector3.new(0, cy + 0.08, cz - 1)), STEEL))
	fix(part("JackPost", Vector3.new(0.2, 1.1, 0.2), CFrame.new(0.6, cy - 0.2, cz + 3.4), ALLOY))
	box("JackFoot", Vector3.new(0.5, 0.08, 0.5), Vector3.new(0.6, cy - 0.78, cz + 3.4), STEEL)

	-- the ramps: slide-outs under the deck; TrailerClient slides them out and tips them to the road
	local rl = T.RampLength
	for _, x in { -2.65, 2.65 } do
		local r = part("Ramp", Vector3.new(2, 0.16, rl), CFrame.new(x, H, back + rl / 2), ALLOY, Enum.Material.DiamondPlate)
		r:SetAttribute("Solid", true)
		local m = Instance.new("Motor6D")
		m.Name = "Hinge"
		m.Part0 = root
		m.Part1 = r
		m.C0 = CFrame.new(x, H, back)
		m.C1 = CFrame.new(0, 0, -rl / 2)
		m.Parent = r
	end

	-- the lamps: discs on the model's own round lamps, seen only when lit (TrailerClient)
	local function disc(name: string, kind: string, at: Vector3, axis: CFrame, size: number, color: Color3): BasePart
		local p = part(name, Vector3.new(0.05, size, size), CFrame.new(at) * axis, color, Enum.Material.Neon, Enum.PartType.Cylinder)
		fix(p)
		p:SetAttribute("Lamp", kind)
		p:SetAttribute("Side", if at.X < 0 then "L" else "R")
		p:SetAttribute("Lit", color)
		p.Transparency = 1
		p.CastShadow = false
		return p
	end
	local Y, Z = 2.73, 3.44
	local REAR, SIDE = CFrame.Angles(0, math.pi / 2, 0), CFrame.new()
	local RED, AMBER, WHITE = Color3.fromRGB(255, 22, 22), Color3.fromRGB(255, 140, 16), Color3.fromRGB(255, 252, 244)
	for _, s in { -1, 1 } do
		disc("TailLamp", "Tail", Vector3.new(s * 1.47, Y, Z), REAR, 0.3, RED)
		disc("TailLamp", "Tail", Vector3.new(s * 2.11, Y, Z), REAR, 0.3, RED)
		disc("TailLamp", "Tail", Vector3.new(s * 2.76, Y, Z), REAR, 0.3, RED)
		disc("TurnLamp", "Turn", Vector3.new(s * 2.76, Y, Z + 0.03), REAR, 0.3, AMBER)
		disc("TurnLamp", "Turn", Vector3.new(s * 3.63, 2.74, 3.31), SIDE, 0.24, AMBER)
		disc("TurnLamp", "Turn", Vector3.new(s * 3.63, 3.25, 3.31), SIDE, 0.24, AMBER)
		local rev = box("RevsLens", Vector3.new(0.42, 0.2, 0.04), Vector3.new(s * 0.72, Y, Z), Color3.fromRGB(64, 64, 62), Enum.Material.SmoothPlastic)
		rev.CastShadow = false
		disc("RevsLamp", "Revs", Vector3.new(s * 0.72, Y, Z + 0.03), REAR, 0.2, WHITE)
	end
	-- the number plate
	local plate = box("Plate", Vector3.new(0.84, 0.4, 0.06), Vector3.new(0, Y, Z), Color3.fromRGB(226, 226, 222), Enum.Material.SmoothPlastic)
	plate.CastShadow = false

	model:SetAttribute("Length", back - cz)
	model:SetAttribute("Width", W)
	return model
end

return TrailerBuilder
