-- CoachView (28 Oct): a coach's 3D bust in a ViewportFrame for the window tiles (no pictures, no
-- uploads). The still models come from ReplicatedStorage.CoachPreviews (CoachService). A coach you
-- don't own yet is a black silhouette. Clones are made only while a tile exists (windows rebuild
-- their pages), so nothing piles up.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CoachView = {}

local previews = nil
local function folder()
	if not previews then
		previews = ReplicatedStorage:FindFirstChild("CoachPreviews")
	end
	return previews
end

-- parent: a Frame; opts: { Silhouette = bool, Zoom = number (1 = chest up), ZIndex }
function CoachView.make(parent, coachId, opts)
	opts = opts or {}
	local vp = Instance.new("ViewportFrame")
	vp.Name = "CoachView"
	vp.BackgroundTransparency = 1
	vp.Size = UDim2.fromScale(1, 1)
	vp.Ambient = Color3.fromRGB(170, 170, 185)
	vp.LightColor = Color3.fromRGB(255, 250, 240)
	vp.LightDirection = Vector3.new(-0.6, -1, -1)
	vp.ZIndex = opts.ZIndex or parent.ZIndex + 1
	if opts.Silhouette then
		vp.ImageColor3 = Color3.new(0, 0, 0)
		vp.Ambient = Color3.new(0, 0, 0)
		vp.LightColor = Color3.new(0, 0, 0)
	end
	vp.Parent = parent
	local f = folder()
	local template = f and f:FindFirstChild(coachId)
	if not template then
		return vp
	end
	local m = template:Clone()
	m.Parent = vp
	local head = m:FindFirstChild("Head")
	local root = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
	local cam = Instance.new("Camera")
	cam.FieldOfView = 32
	cam.Parent = vp
	vp.CurrentCamera = cam
	if head and root then
		local look = root.CFrame.LookVector
		local target = head.Position - Vector3.new(0, 0.9 * (opts.Zoom or 1), 0)
		local dist = 7.2 * (opts.Zoom or 1)
		cam.CFrame = CFrame.lookAt(target + look * dist + Vector3.new(0, 0.6, 0) + root.CFrame.RightVector * 0.8, target)
	else
		local cf, size = m:GetBoundingBox()
		cam.CFrame = CFrame.lookAt(cf.Position + cf.LookVector * size.Magnitude, cf.Position)
	end
	return vp
end

return CoachView
