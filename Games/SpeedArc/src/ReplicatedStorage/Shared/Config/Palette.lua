-- SPEED ARC palette (GDD section 3). Black + blue + gold. Use these everywhere: world, UI, effects.
local function hex(h)
	return Color3.fromHex(h)
end

return {
	SpeedBlack = hex("#0B0D12"), -- UI base, night skies
	Carbon = hex("#171A22"), -- panels
	Graphite = hex("#2A2F3A"), -- borders
	ElectricBlue = hex("#1E7BFF"), -- main accent, speed, buttons
	BrightBlue = hex("#4FC3FF"), -- glows, highlights
	DeepBlue = hex("#0E3A8A"), -- shadows, gradients
	Gold = hex("#FFC83D"), -- coins, rewards, winners
	DeepGold = hex("#E09A12"), -- gold gradients
	White = hex("#F4F6FA"), -- text
	DangerRed = hex("#FF4A4A"), -- warnings and timers only

	-- World colours (cool-tinted naturals, inside the palette's mood)
	World = {
		TrackBlue = hex("#1C57C8"),
		TrackBlueDark = hex("#17489F"),
		LaneWhite = hex("#EEF2FA"),
		Grass = hex("#5DAA4E"),
		GrassDark = hex("#4A9442"),
		Infield = hex("#66B556"),
		Path = hex("#C9CFD9"),
		Concrete = hex("#B8BFCB"),
		Brick = hex("#C7694F"),
		BrickDark = hex("#A9553F"),
		Roof = hex("#2A2F3A"),
		Window = hex("#9FD4FF"),
		WindowLit = hex("#FFE3A0"),
		Steel = hex("#3A4150"),
		Aluminium = hex("#C9D1DD"),
		Wood = hex("#B9824F"),
		TreeLeaf = hex("#4E9A47"),
		TreeLeafLight = hex("#6DBA55"),
		TreeLeafDark = hex("#3D7F3D"),
		Trunk = hex("#7A5236"),
		Cone = hex("#FF8A2B"),
	},
}
