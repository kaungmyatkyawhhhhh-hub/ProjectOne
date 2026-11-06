-- UIAssets (Galaxy Incremental): every UI image id in one place. Files: Downloads\galaxy_ui_upload\ (icons rendered in
-- Blender: Icons\rendered, UI\supernova_icons_blender.py + UI\galaxy_icons_extra.py; textures: UI\make_ui_textures.py).
-- P&L Studios XP uploads (2 Nov; decals kept in ServerStorage.UIUploads). Replace ids here only.
return {
	icon = {
		stardust = "rbxassetid://93985102473923",
		shard = "rbxassetid://110263397705097",
		sun = "rbxassetid://122559700198678",
		planet = "rbxassetid://89305471713718",
		comet = "rbxassetid://93755418339111",
		forge = "rbxassetid://117529477019033",
		gear = "rbxassetid://81402585488835",
		asteroid = "rbxassetid://91552050312107",
		moon = "rbxassetid://134915759247424",
		gasgiant = "rbxassetid://115501670650344",
		essence = "rbxassetid://76524340395639",
		lock = "rbxassetid://116845939092136",
		-- (alpha part 2, 3 Nov: the GUIDE BOOK key; Icons\rendered\icon_book.png, uploaded from Studio = a test copy, re-upload to P&L Studios XP)
		book = "rbxassetid://80421452290179",
		-- (overnight part 2: the BOOST POTIONS; Icons\rendered\icon_potion_*.png, Studio test copies too)
		potionStardust = "rbxassetid://75757117780273",
		potionComets = "rbxassetid://111020939074381",
		-- (6 Nov: the Phase 2 features' own icons, Assets galaxy_icon_*_512, P&L Studios XP group import)
		offlineEarnings = "rbxassetid://88662519526579", -- the RETURN screen
		dailyStreak = "rbxassetid://96631498406611", -- the DAILY window
		quests = "rbxassetid://104265099631183", -- the QUESTS hotbar key
		playtimeGift = "rbxassetid://97650869572088", -- the PLAYTIME GIFTS tiles
		freeRewards = "rbxassetid://126118769169465", -- the FREE REWARDS board
		boosts = "rbxassetid://82218225965129", -- the BOOSTS chip
		-- (3.1: the BLACK HOLE's icon = our black_hole_swirl texture, the transparent version: VfxTextures.alpha.black_hole_swirl)
		blackHole = "rbxassetid://125237533530152",
	},
	-- (the same icons at 128 px, for small spots)
	icon128 = {
		offlineEarnings = "rbxassetid://119076193495482",
		dailyStreak = "rbxassetid://133675373246183",
		quests = "rbxassetid://105917484730156",
		playtimeGift = "rbxassetid://123554725293656",
		freeRewards = "rbxassetid://97169368459028",
		boosts = "rbxassetid://107966977637634",
	},
	stripes = "rbxassetid://123710673700412", -- 512x128, white diagonal stripes (v12 .stripes)
	glow9 = "rbxassetid://109052962777294", -- 128 px 9-slice soft glow (window breathe)
	softglow = "rbxassetid://113034099262576", -- round glow behind icons
	sparkle = "rbxassetid://94034532317377",
	mote = "rbxassetid://70545138129350",
	-- (the world VFX textures moved to VfxTextures in the VFX pass, 6 Nov: fxSparkle + the fx placeholders are gone)
	plate = "rbxassetid://126195526088194", -- the top counter's slanted plate (white, tinted)
	header = "rbxassetid://98206491746323", -- 900x80 orange header texture
	arrow = "rbxassetid://138731187772172", -- tutorial arrow (points down)
	-- the GUIDE BOOK pictures (alpha part 2): screenshots of the game taken in Studio, UI\guide\guide_<id>.png
	guide = {
		Stardust = "rbxassetid://117771352697576",
		Island = "rbxassetid://88625933516654",
		Tree = "rbxassetid://88657456847726",
		Comets = "rbxassetid://88359616710103",
		Supernova = "rbxassetid://83888667277193",
		Surge = "rbxassetid://70451896435179",
		Ranks = "rbxassetid://123011182047961",
	},
}
