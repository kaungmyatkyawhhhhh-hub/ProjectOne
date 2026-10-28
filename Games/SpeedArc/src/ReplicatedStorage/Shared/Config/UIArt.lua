-- The UI art kit images (prompt 12). The 43 sprites live in 3 sheets made by tools/make_ui_kit.py.
-- Ids: the 3 sheets uploaded to P&L Studios XP (947215423) on 28 Oct (image ids, not the decal ids).
-- If the kit changes, re-run make_ui_kit.py, re-upload the 3 sheets and paste the new image ids here.
-- Until then Studio shows the local copies (make_ui_kit.py copies them into Studio's content folder);
-- a live server with empty ids shows no kit images, so the ids MUST be filled before publishing.
return {
	Ids = {
		Buttons = "83935751108134", -- ui_buttons.png: 12 buttons (6 styles x normal / pressed), panel, pills, bars, badges
		Tiles = "131954584345503", -- ui_tiles.png: 7 colour-glow tiles
		Icons = "98928878835456", -- ui_icons.png: 15 icons
	},
	LocalFolder = "rbxasset://textures/SpeedArcKit/",
	-- (the local file names are in Config/UIArtSprites: they change with every build)
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
