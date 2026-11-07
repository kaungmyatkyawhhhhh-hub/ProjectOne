-- BoardsFx (Galaxy Incremental): what spills OUTSIDE the island boards' screens (pass 2): the pair's huge titles over the top
-- frame edge, the glow halo + crackling energy beams, Star Upgrades' flame strip. Moved here from GalaxyBoards (7 Nov) so the
-- game and Tools/BoardPreview (the boards' look in Edit mode) draw the very same thing. decorate(spec, screen, folder) ->
-- { parts, step }: the parts go in `folder`; step(dt) animates them (the game calls it every frame).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Galaxy = ReplicatedStorage:WaitForChild("Galaxy")
local MapConfig = require(Galaxy:WaitForChild("MapConfig"))
local Kit = require(Galaxy:WaitForChild("UIKit"))
local B = MapConfig.Boards
local M = {}

local TITLE_FONT = Font.fromEnum(Enum.Font.FredokaOne)
-- (the VFX pass, #281: was Roblox's stock fire_main.dds; now our forge_sparks flipbook, looping)
local FIRE = require(Galaxy:WaitForChild("VfxTextures")).fx("forge_sparks") -- (7 Nov: VfxTextures.fx; the flames are LightEmission 1)
local function fxPart(folder: Instance, name: string, size: Vector3, cf: CFrame): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Transparency = 1
	p.Size = size
	p.CFrame = cf
	p.Parent = folder
	return p
end
local function faceGui(p: BasePart, pps: number): SurfaceGui
	local g = Instance.new("SurfaceGui")
	g.Face = Enum.NormalId.Back
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = pps
	g.LightInfluence = 0
	g.MaxDistance = B.DrawRange + 40
	g.Parent = p
	return g
end
-- a board's frame outline, board-local (the screen's centre = 0): half width, top, bottom, front, back
local function outline(spec)
	local w, h = spec.Width, spec.Height
	if spec.pair then
		local P = B.Pair
		return w / 2 + P.Lip + P.Post, h / 2 + P.Lip + P.Bar + 0.3 + P.Post / 2, -h / 2 - P.Lip - P.BarLow, P.PostDepth / 2, P.Depth / 2
	elseif spec.Style == "Neon" then
		local G = B.Angular
		return w / 2 + G.Wide + 0.3, h / 2 + G.High + 0.7, -h / 2 - G.Low - 0.3, 0.5, 0.45
	end
	return w / 2 + B.Frame, h / 2 + B.Frame, -h / 2 - B.Frame, B.Depth / 2, B.Depth / 2
end
M.part = fxPart
M.outline = outline
function M.decorate(spec, screen: BasePart, folder: Instance)
	local function fxPart(name: string, size: Vector3, cf: CFrame): Part return M.part(folder, name, size, cf) end
	local cf = screen.CFrame * CFrame.new(0, 0, -0.1) -- (the board's centre plane)
	local hw, top, bottom, front, back = outline(spec)
	local parts, beams, glows, flames = {}, {}, {}, {}
	local neon = spec.Neon
	if spec.pair then
		-- the halo: a glow behind the frame, so only what spills round its outline shows
		local S = 1.8
		local halo = fxPart("Halo", Vector3.new(2 * hw + 2 * S, top - bottom + 2 * S, 0.05), cf * CFrame.new(0, (top + bottom) / 2, -back - 0.15))
		table.insert(parts, halo)
		local hg = faceGui(halo, 20)
		-- (four strips round the edge, bright where they meet the frame, fading outward)
		for _, s in ipairs({ { UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0, S * 20 + 8), 90 }, { UDim2.new(0, 0, 1, -S * 20 - 8), UDim2.new(1, 0, 0, S * 20 + 8), 270 },
			{ UDim2.new(0, 0, 0, 0), UDim2.new(0, S * 20 + 8, 1, 0), 0 }, { UDim2.new(1, -S * 20 - 8, 0, 0), UDim2.new(0, S * 20 + 8, 1, 0), 180 } }) do
			local f = Instance.new("Frame")
			f.BorderSizePixel = 0
			f.BackgroundColor3 = neon
			f.Position, f.Size = s[1], s[2]
			local g = Instance.new("UIGradient")
			g.Rotation = s[3]
			g.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.15) })
			g.Parent = f
			f.Parent = hg
			table.insert(glows, f)
		end
	end
	if spec.pair then
		-- the huge title over the top frame edge (Regrowth's "PERKS TREE" / "INFO"): white, a thick dark outline
		local P = B.Pair
		local band = fxPart("Title", Vector3.new(2 * hw, 3, 0.05), cf * CFrame.new(0, spec.Height / 2 + P.Lip + P.Bar / 2 - 0.1, front + 0.08))
		table.insert(parts, band)
		local tg = faceGui(band, 40)
		tg.Brightness = B.Brightness
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Position = UDim2.new(0, 34, 0, 6)
		l.Size = UDim2.new(1, -60, 1, -12)
		l.FontFace = TITLE_FONT
		l.Text = spec.title
		l.TextColor3 = Color3.new(1, 1, 1)
		l.TextScaled = true
		l.TextXAlignment = Enum.TextXAlignment.Left
		local cap = Instance.new("UITextSizeConstraint")
		cap.MaxTextSize = 96
		cap.Parent = l
		local st = Instance.new("UIStroke")
		st.Color = Color3.fromRGB(26, 16, 48)
		st.Thickness = 7
		st.LineJoinMode = Enum.LineJoinMode.Round
		st.Parent = l
		l.Parent = tg
		-- the energy strip: crackling beams along the frame's sides and top (+ a soft wide glow beam under each)
		local holder = fxPart("Energy", Vector3.new(1, 1, 1), cf)
		table.insert(parts, holder)
		local z = front + 0.2
		local pts = { Vector3.new(-hw, bottom + 1, z), Vector3.new(-hw, (top + bottom) / 2, z), Vector3.new(-hw, top - 0.6, z), Vector3.new(0, top + 0.2, z),
			Vector3.new(hw, top - 0.6, z), Vector3.new(hw, (top + bottom) / 2, z), Vector3.new(hw, bottom + 1, z) }
		local bright = ColorSequence.new(neon:Lerp(Color3.new(1, 1, 1), 0.55), neon)
		for i = 1, #pts - 1 do
			local a, c = pts[i], pts[i + 1]
			local d = (c - a).Unit
			local perp = Vector3.new(-d.Y, d.X, 0)
			local function att(p: Vector3): Attachment
				local at = Instance.new("Attachment")
				at.CFrame = CFrame.fromMatrix(p, perp, Vector3.new(0, 0, 1):Cross(perp))
				at.Parent = holder
				return at
			end
			local a0, a1 = att(a), att(c)
			for layer = 1, 2 do
				local bm = Instance.new("Beam")
				bm.Attachment0, bm.Attachment1 = a0, a1
				bm.FaceCamera = true
				bm.LightEmission, bm.LightInfluence = 1, 0
				bm.Segments = 14
				bm.Color = bright
				if layer == 1 then
					bm.Width0, bm.Width1 = 1.4, 1.4
					bm.Transparency = NumberSequence.new(0.72)
				else
					bm.Width0, bm.Width1 = 0.3, 0.3
					table.insert(beams, bm)
				end
				bm.Parent = holder
			end
		end
	end
	if spec.Flames then
		-- Factory Upgrades' flame border (pass 3: a STRIP hugging the frame, not a cloud): along each edge of the angular
		-- frame a thin glow line + small short-lived flames licking outward (gold, turning violet), at most ~1 stud out
		local G = B.Angular
		local w, h = spec.Width, spec.Height
		local o = 0.3 -- (just outside the neon tube)
		local corners = { Vector2.new(-w / 2 - G.Low - o, -h / 2 - G.Low - o), Vector2.new(w / 2 + G.Low + o, -h / 2 - G.Low - o),
			Vector2.new(w / 2 + G.Wide + o, h / 2 + G.High + o), Vector2.new(-w / 2 - G.Wide - o, h / 2 + G.High + o) }
		local holder = fxPart("FlameLine", Vector3.new(1, 1, 1), cf * CFrame.new(0, 0, 0.45))
		table.insert(parts, holder)
		for i = 1, 4 do
			-- (corners run anticlockwise, so each edge's outside is its part's -Y: EmissionDirection Bottom)
			local p0, p1 = corners[i], corners[i % 4 + 1]
			local d = p1 - p0
			local mid = (p0 + p1) / 2
			local edge = fxPart("Flames", Vector3.new(d.Magnitude, 0.12, 0.3), cf * CFrame.new(mid.X, mid.Y, 0.45) * CFrame.Angles(0, 0, math.atan2(d.Y, d.X)))
			table.insert(parts, edge)
			local e = Instance.new("ParticleEmitter")
			e.Texture = FIRE
			e.FlipbookLayout = Enum.ParticleFlipbookLayout.Grid4x4
			e.FlipbookMode = Enum.ParticleFlipbookMode.Loop
			e.FlipbookFramerate = NumberRange.new(20, 20)
			e.FlipbookStartRandom = true
			e.Shape = Enum.ParticleEmitterShape.Box
			e.EmissionDirection = Enum.NormalId.Bottom
			e.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 226, 130)), ColorSequenceKeypoint.new(0.25, neon),
				ColorSequenceKeypoint.new(0.55, spec.Neon2 or neon), ColorSequenceKeypoint.new(1, spec.Neon2 or neon) })
			e.LightEmission, e.LightInfluence, e.Brightness = 1, 0, 3
			e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.25), NumberSequenceKeypoint.new(0.5, 0.9), NumberSequenceKeypoint.new(1, 0.15) })
			e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.6, 0.25), NumberSequenceKeypoint.new(1, 1) })
			e.Lifetime = NumberRange.new(0.25, 0.45)
			e.Speed = NumberRange.new(0.6, 1.2)
			e.SpreadAngle = Vector2.new(12, 12)
			e.Acceleration = Vector3.new(0, 1.5, 0)
			e.RotSpeed = NumberRange.new(-60, 60)
			e.Rate = math.floor(d.Magnitude * 6) -- (was 14 a stud: ~400 alive per board; the 300 budget, #304)
			e.Parent = edge
			-- the glow line under the flames
			local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
			a0.Position, a1.Position = Vector3.new(p0.X, p0.Y, 0), Vector3.new(p1.X, p1.Y, 0)
			a0.Parent, a1.Parent = holder, holder
			local bm = Instance.new("Beam")
			bm.Attachment0, bm.Attachment1 = a0, a1
			bm.FaceCamera = true
			bm.LightEmission, bm.LightInfluence = 1, 0
			bm.Color = ColorSequence.new(neon:Lerp(Color3.new(1, 1, 1), 0.3))
			bm.Width0, bm.Width1 = 0.45, 0.45
			bm.Transparency = NumberSequence.new(0.35)
			bm.Parent = holder
			table.insert(flames, { beam = bm, width = 0.45 })
		end
	end
	-- the animation: the halo breathes, the energy crackles (new bends + widths ~14 times a second)
	local acc = 0
	local function step(dt: number)
		if Kit.calm() then return end
		local a = 0.25 + math.sin(os.clock() * 2.2) * 0.15
		for _, g in ipairs(glows) do g.BackgroundTransparency = a end
		acc += dt
		if acc < 0.07 then return end
		acc = 0
		for _, f in ipairs(flames) do
			f.beam.Width0 = f.width * (0.8 + math.random() * 0.4)
			f.beam.Width1 = f.width * (0.8 + math.random() * 0.4)
		end
		for _, bm in ipairs(beams) do
			bm.CurveSize0 = (math.random() - 0.5) * 2.4
			bm.CurveSize1 = (math.random() - 0.5) * 2.4
			bm.Width0 = 0.12 + math.random() * 0.35
			bm.Width1 = 0.12 + math.random() * 0.35
			bm.Transparency = NumberSequence.new(math.random() * 0.45)
		end
	end
	return { parts = parts, step = step }
end

return M
