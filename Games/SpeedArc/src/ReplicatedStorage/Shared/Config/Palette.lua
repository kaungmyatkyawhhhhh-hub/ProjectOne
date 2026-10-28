-- SPEED ARC palette (GDD section 3; bright but sporty since prompt 12). Use these everywhere: world, UI, effects.
local function hex(h)
	return Color3.fromHex(h)
end

return {
	-- Prompt 12 (owner, 28 Oct): BRIGHT BUT SPORTY. Saturated, bold, high contrast, never pastel; no
	-- pink, purple or cream anywhere. Navy is the outline / text stroke / panel colour.
	SpeedBlack = hex("#0F1E4A"), -- Navy: UI base, outlines, text stroke
	Carbon = hex("#1A2E6E"), -- panels (navy, lighter at the top of the gradient)
	Graphite = hex("#2C4499"), -- borders, dark buttons
	ElectricBlue = hex("#1E90FF"), -- main accent, speed, buttons
	BrightBlue = hex("#5AB4FF"), -- glows, highlights
	DeepBlue = hex("#2152D9"), -- Royal Blue: shadows, gradients
	Gold = hex("#FFD21F"), -- Sunny Yellow: coins, rewards, winners
	DeepGold = hex("#FFB300"), -- Gold: gold gradients
	White = hex("#FFFFFF"), -- text
	DangerRed = hex("#FF3B3B"), -- Red: warnings, timers, LIVE, close
	-- sporty accents (zones, walls, kiosks)
	Navy = hex("#0F1E4A"),
	Royal = hex("#2152D9"),
	Sky = hex("#1E90FF"),
	Cyan = hex("#1EC8FF"),
	Yellow = hex("#FFD21F"),
	Orange = hex("#FF7A1A"),
	Lime = hex("#6BE33B"),
	Red = hex("#FF3B3B"),
	Light = hex("#E3E7EE"), -- light grey for roads, pads, plazas

	-- World colours (bright, saturated naturals)
	World = {
		TrackBlue = hex("#1E6FE8"),
		TrackBlueDark = hex("#1A5BC4"),
		LaneWhite = hex("#EEF2FA"),
		Grass = hex("#4CC23A"),
		GrassDark = hex("#3FAE2F"),
		Infield = hex("#5ACF3F"),
		Path = hex("#E3E7EE"),
		Concrete = hex("#E8ECF2"),
		Brick = hex("#C7694F"),
		BrickDark = hex("#A9553F"),
		Roof = hex("#2A2F3A"),
		Window = hex("#9FD4FF"),
		WindowLit = hex("#FFE3A0"),
		Steel = hex("#3A4150"),
		Aluminium = hex("#C9D1DD"),
		Wood = hex("#B9824F"),
		TreeLeaf = hex("#3FAE2F"),
		TreeLeafLight = hex("#5ACF3F"),
		TreeLeafDark = hex("#2F8F24"),
		Trunk = hex("#7A5236"),
		Cone = hex("#FF7A1A"),
	},
}
