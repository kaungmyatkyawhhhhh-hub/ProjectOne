--[[ BoardPlacer v1: put a board/sign at the EDGE of an island, back to the void, front to the players.
Use this for EVERY board instead of moving/rotating by hand.

  local BoardPlacer = require(path.to.BoardPlacer)
  BoardPlacer.place(board, island, angleDeg, opts)

board    : Model (pivot = bottom-centre, front = -Z / LookVector, SurfaceGui Face = Front) or a Part
island   : the island Model/Part (its bounding box gives centre + radius); an "IslandSpawn" part inside it is used as the look target if present
angleDeg : where on the rim, 0 = +X side, 90 = +Z side ... (pick the side opposite the bridge/arrival so players walk toward it)
opts     : { margin = 4 (studs in from the edge), tiltBack = 10 (deg, top leans away), pairSpread = 0 (deg, for 2 boards angled in), groundY = nil (auto raycast) }
]]
local BoardPlacer = {}

local function bbox(inst)
	if inst:IsA("Model") then return inst:GetBoundingBox() end
	return inst.CFrame, inst.Size
end

function BoardPlacer.place(board, island, angleDeg, opts)
	opts = opts or {}
	local margin = opts.margin or 4
	local tilt = opts.tiltBack or 10
	local icf, isize = bbox(island)
	local centre = icf.Position
	local radius = math.min(isize.X, isize.Z) / 2
	local a = math.rad(angleDeg)
	local pos = centre + Vector3.new(math.cos(a), 0, math.sin(a)) * (radius - margin)

	-- ground height under that spot (top of the island)
	local y = opts.groundY
	if not y then
		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Exclude
		rp.FilterDescendantsInstances = { board }
		local hit = workspace:Raycast(Vector3.new(pos.X, centre.Y + isize.Y + 50, pos.Z), Vector3.new(0, -(isize.Y + 200), 0), rp)
		y = hit and hit.Position.Y or (centre.Y + isize.Y / 2)
	end
	pos = Vector3.new(pos.X, y, pos.Z)

	-- look at the island spawn (or centre), level, so the FRONT faces the players and the BACK faces the void
	local targetInst = island:FindFirstChild("IslandSpawn", true)
	local target = targetInst and targetInst.Position or centre
	local cf = CFrame.lookAt(pos, Vector3.new(target.X, pos.Y, target.Z))
	if opts.pairSpread and opts.pairSpread ~= 0 then cf = cf * CFrame.Angles(0, math.rad(opts.pairSpread), 0) end
	cf = cf * CFrame.Angles(math.rad(tilt), 0, 0) -- top leans back, away from the viewer

	if board:IsA("Model") then board:PivotTo(cf) else board.CFrame = cf * CFrame.new(0, board.Size.Y / 2, 0) end
	board:SetAttribute("Island", island.Name)
	board:SetAttribute("AllowTilt", tilt ~= 0)
	return cf
end

return BoardPlacer
