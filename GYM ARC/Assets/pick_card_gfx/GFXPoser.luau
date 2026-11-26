-- GFX poser (owner, 26 Nov): poses an R15 rig in Edit mode by forward kinematics over its RigAttachments, for the
-- muscle-picker card renders. Pose(model, rootCFrame, angles) where angles[joint] is a CFrame in that joint's frame.
-- Lives in ServerStorage._Builders.GFXPoser (if Studio lost it, paste this back).
local GFXPoser = {}

GFXPoser.Joints = {
	{"Root", "HumanoidRootPart", "LowerTorso", "RootRigAttachment"},
	{"Waist", "LowerTorso", "UpperTorso", "WaistRigAttachment"},
	{"Neck", "UpperTorso", "Head", "NeckRigAttachment"},
	{"LeftShoulder", "UpperTorso", "LeftUpperArm", "LeftShoulderRigAttachment"},
	{"LeftElbow", "LeftUpperArm", "LeftLowerArm", "LeftElbowRigAttachment"},
	{"LeftWrist", "LeftLowerArm", "LeftHand", "LeftWristRigAttachment"},
	{"RightShoulder", "UpperTorso", "RightUpperArm", "RightShoulderRigAttachment"},
	{"RightElbow", "RightUpperArm", "RightLowerArm", "RightElbowRigAttachment"},
	{"RightWrist", "RightLowerArm", "RightHand", "RightWristRigAttachment"},
	{"LeftHip", "LowerTorso", "LeftUpperLeg", "LeftHipRigAttachment"},
	{"LeftKnee", "LeftUpperLeg", "LeftLowerLeg", "LeftKneeRigAttachment"},
	{"LeftAnkle", "LeftLowerLeg", "LeftFoot", "LeftAnkleRigAttachment"},
	{"RightHip", "LowerTorso", "RightUpperLeg", "RightHipRigAttachment"},
	{"RightKnee", "RightUpperLeg", "RightLowerLeg", "RightKneeRigAttachment"},
	{"RightAnkle", "RightLowerLeg", "RightFoot", "RightAnkleRigAttachment"},
}

function GFXPoser.Pose(model: Model, rootCFrame: CFrame, angles: {[string]: CFrame})
	local root = model.HumanoidRootPart
	root.CFrame = rootCFrame
	for _, j in GFXPoser.Joints do
		local p0, p1 = model[j[2]], model[j[3]]
		local a0, a1 = p0[j[4]], p1[j[4]]
		p1.CFrame = p0.CFrame * a0.CFrame * (angles[j[1]] or CFrame.identity) * a1.CFrame:Inverse()
	end
	for _, acc in model:GetChildren() do
		if acc:IsA("Accessory") then
			local h = acc.Handle
			local att = h:FindFirstChildOfClass("Attachment")
			for _, part in model:GetChildren() do
				local match = part:IsA("BasePart") and part:FindFirstChild(att.Name)
				if match then h.CFrame = part.CFrame * match.CFrame * att.CFrame:Inverse() break end
			end
		end
	end
	for _, p in model:GetDescendants() do if p:IsA("BasePart") then p.Anchored = true end end
end

-- Places a limb part so attachment a sits at pa and attachment b points at pb; `side` picks the part's X axis.
local function placeBone(part: BasePart, a: string, b: string, pa: Vector3, pb: Vector3, side: Vector3)
	local y = (pa - pb).Unit
	local x = (side - y * side:Dot(y)).Unit
	part.CFrame = CFrame.fromMatrix(pa, x, y) * part[a].CFrame:Inverse()
end

-- Two-bone IK for an arm or leg ("Left"/"Right", "Arm"/"Leg"): puts the hand (wrist) or ankle on `target`, bending
-- the elbow/knee toward `pole`. Call after Pose, which fixed the shoulder/hip.
function GFXPoser.Reach(model: Model, side: string, limb: string, target: Vector3, pole: Vector3, endDir: Vector3?)
	local upper, lower, tip, j0, j1, j2
	if limb == "Arm" then
		upper, lower, tip = model[side .. "UpperArm"], model[side .. "LowerArm"], model[side .. "Hand"]
		j0, j1, j2 = side .. "ShoulderRigAttachment", side .. "ElbowRigAttachment", side .. "WristRigAttachment"
	else
		upper, lower, tip = model[side .. "UpperLeg"], model[side .. "LowerLeg"], model[side .. "Foot"]
		j0, j1, j2 = side .. "HipRigAttachment", side .. "KneeRigAttachment", side .. "AnkleRigAttachment"
	end
	local l1 = (upper[j0].Position - upper[j1].Position).Magnitude
	local l2 = (lower[j1].Position - lower[j2].Position).Magnitude
	local s = upper[j0].WorldPosition
	local toT = target - s
	local d = math.clamp(toT.Magnitude, math.abs(l1 - l2) + 1e-3, l1 + l2 - 1e-3)
	local dir = toT.Unit
	local a = (l1 * l1 - l2 * l2 + d * d) / (2 * d)
	local h = math.sqrt(math.max(l1 * l1 - a * a, 0))
	local n = pole - dir * pole:Dot(dir)
	n = n.Magnitude > 1e-4 and n.Unit or Vector3.yAxis
	local mid = s + dir * a + n * h
	local tip3 = s + dir * d
	local sideAxis = dir:Cross(n)
	if sideAxis.Magnitude < 1e-4 then sideAxis = Vector3.xAxis end
	sideAxis = sideAxis.Unit
	placeBone(upper, j0, j1, s, mid, sideAxis)
	placeBone(lower, j1, j2, mid, tip3, sideAxis)
	local ed = endDir or (tip3 - mid).Unit
	placeBone(tip, j2, j2, tip3, tip3 + ed, sideAxis)
end

return GFXPoser

--[[ Scene recipes used on 26 Nov (machine pivots from workspace.Gym.Machines clones, Bacon = HumanoidDescription
Shirt 144076358 "Blue and Black Motorcycle Shirt", Pants 144076760 "Dark Green Jeans", Face 144075659 "Smile",
skin (234,184,146), plus the Pal Hair accessory cloned from ServerStorage.ThumbnailScene.BACON_4ft):

LEGS / SquatRack: Pose(npc, piv*CFrame.new(0,3,0.4)*CFrame.Angles(0,pi,0), {Root=Angles(-28deg), Waist=Angles(4deg),
  Neck=Angles(14deg), L/RHip=Angles(108deg,0,-/+12deg), L/RKnee=Angles(-112deg)}); feet set level, body dropped so the
  soles touch platform top (piv.Y+0.23); rack Bar moved to UpperTorso*(0, 0.36*h, 0.5*d+0.12); Reach both hands to
  bar +-1.35 along the right vector; the two Plate45 models moved onto the bar ends at +-2.3.
ABS / CrunchBench: root = piv*fromMatrix((0,2.35,0.75), X(-1,0,0), Y(0,0,-1), Z(0,-1,0)) (lying face up, head to -Z),
  Waist=Angles(-40deg), Neck=Angles(-10deg); lowered so LowerTorso rests on the pad top (piv.Y+1.8); Reach legs to
  (+-0.5, 2.3, 3.28) pole up (ankles between the foot rollers); arms crossed on the chest (hand to the opposite
  shoulder at torso*(+-0.55, 0.35, -0.68)).
BACK / PullUpBar: Pose(npc, piv*CFrame.new(0,7.62,0.15), {Neck 8deg, LHip 12/RHip 18, LKnee -55/RKnee -65, ankles 15});
  Reach hands to the Bar at (+-1.25, 9.05, 0), pole (side, -0.9, 0.35), hand dir up. Camera behind = rear 3/4.
]]
