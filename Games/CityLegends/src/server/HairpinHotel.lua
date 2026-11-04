--[[
	HairpinHotel (server)
	The Grand Hairpin Hotel (owner, 2026-11-04: "add a new hotel near the hairpin as you can view the
	hair pin from the hotel"): a curved hotel round the outside of the bend, baked in the map
	(Workspace.Riviera.Dressing.GrandHairpin). Its door on the pavement takes you up to the roof
	terrace, free for everyone, and the door up there brings you back to the street. On foot only.
]]

local HairpinHotel = {}

local function goTo(player: Player, spot: BasePart)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not char or not hum or hum.SeatPart or hum.Health <= 0 then
		return
	end
	char:PivotTo(spot.CFrame)
end

local function door(part: BasePart, action: string, spot: BasePart)
	local p = Instance.new("ProximityPrompt")
	p.ActionText = action
	p.ObjectText = "Grand Hairpin Hotel"
	p.KeyboardKeyCode = Enum.KeyCode.E
	p.MaxActivationDistance = 14
	p.RequiresLineOfSight = false
	p.Parent = part
	p.Triggered:Connect(function(player: Player)
		goTo(player, spot)
	end)
end

function HairpinHotel.init()
	local riv = workspace:FindFirstChild("Riviera")
	local dress = riv and riv:FindFirstChild("Dressing")
	local group = dress and dress:FindFirstChild("GrandHairpin")
	local hotel = group and group:FindFirstChild("GrandHairpinHotel")
	if not hotel then
		return
	end
	local lobby = hotel:FindFirstChild("LobbyDoor") :: BasePart?
	local roof = hotel:FindFirstChild("TerraceDoor") :: BasePart?
	local street = hotel:FindFirstChild("StreetSpot") :: BasePart?
	local terrace = hotel:FindFirstChild("TerraceSpot") :: BasePart?
	if lobby and roof and street and terrace then
		door(lobby, "Go up to the terrace", terrace)
		door(roof, "Back to the street", street)
	end
end

return HairpinHotel
