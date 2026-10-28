-- SPEED ARC palette (GDD section 3; candy look since 28 Oct). Use these everywhere: world, UI, effects.
local function hex(h)
	return Color3.fromHex(h)
end

return {
	-- 28 Oct: the owner picked the bright "candy" simulator look. The keys keep their jobs (UI base,
	-- panels, borders ...) but are colourful now: deep indigo instead of black, royal blue panels.
	SpeedBlack = hex("#1C2A7A"), -- UI base, text outlines (deep indigo)
	Carbon = hex("#3557E8"), -- panels (royal blue)
	Graphite = hex("#2A3FA8"), -- borders, dark buttons
	ElectricBlue = hex("#24A8FF"), -- main accent, speed, buttons (sky blue)
	BrightBlue = hex("#6FDDFF"), -- glows, highlights (aqua)
	DeepBlue = hex("#1B3E9E"), -- shadows, gradients
	Gold = hex("#FFD23F"), -- coins, rewards, winners (sunny yellow)
	DeepGold = hex("#FF9F1C"), -- gold gradients (orange)
	White = hex("#FFFFFF"), -- text
	DangerRed = hex("#FF4D6D"), -- warnings and timers only
	-- candy accents (zones, walls, kiosks)
	Mint = hex("#3DDC97"),
	Pink = hex("#FF6FB5"),
	Purple = hex("#9B5DE5"),
	Orange = hex("#FF8A3D"),
	Sky = hex("#4DB8FF"),
	Lime = hex("#7ED957"),
	Cream = hex("#FFF3DC"),

	-- World colours (bright candy naturals)
	World = {
		TrackBlue = hex("#2D7CF6"),
		TrackBlueDark = hex("#2366D1"),
		LaneWhite = hex("#EEF2FA"),
		Grass = hex("#7ED957"),
		GrassDark = hex("#70CC4B"),
		Infield = hex("#8BE06A"),
		Path = hex("#FFF3DC"),
		Concrete = hex("#F2F4F8"),
		Brick = hex("#C7694F"),
		BrickDark = hex("#A9553F"),
		Roof = hex("#2A2F3A"),
		Window = hex("#9FD4FF"),
		WindowLit = hex("#FFE3A0"),
		Steel = hex("#3A4150"),
		Aluminium = hex("#C9D1DD"),
		Wood = hex("#B9824F"),
		TreeLeaf = hex("#5BC236"),
		TreeLeafLight = hex("#8BE06A"),
		TreeLeafDark = hex("#43A62E"),
		Trunk = hex("#7A5236"),
		Cone = hex("#FF8A2B"),
	},
}
