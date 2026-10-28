-- The UI art kit images (prompt 12). The 43 sprites live in 3 sheets made by tools/make_ui_kit.py.
-- Ids: the owner uploads the 3 sheets to the GROUP (after prompt 13) and pastes the numbers here.
-- Until then Studio shows the local copies (make_ui_kit.py copies them into Studio's content folder);
-- a live server with empty ids shows no kit images, so the ids MUST be filled before publishing.
return {
	Ids = {
		Buttons = "", -- ui_buttons.png: 12 buttons (6 styles x normal / pressed), panel, pills, bars, badges
		Tiles = "", -- ui_tiles.png: 7 colour-glow tiles
		Icons = "", -- ui_icons.png: 15 icons
	},
	LocalFolder = "rbxasset://textures/SpeedArcKit/",
	Files = { Buttons = "ui_buttons.png", Tiles = "ui_tiles.png", Icons = "ui_icons.png" },
	-- the colour-glow tiles (UIKit.tile picks the nearest one for any colour)
	TileColors = {
		blue = "#1E90FF",
		lime = "#6BE33B",
		orange = "#FF7A1A",
		gold = "#FFB300",
		red = "#FF3B3B",
		cyan = "#1EC8FF",
		grey = "#8C97AD",
	},
}
