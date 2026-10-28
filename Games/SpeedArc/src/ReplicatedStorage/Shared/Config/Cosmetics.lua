-- Locker cosmetics (M5, Customization note). Cosmetic only: no stats. Prices are minutes of coins at
-- your league (long goals). Each worn item = 1 light mesh from the Blender kit ("Kit_*" / "Head_*" in
-- ServerStorage.Meshes); until it's imported a simple part stands in. One mesh shape can be used
-- by several items in different colours (the mesh is one plain material, tinted by Color).
return {
	Kits = {
		{ Id = "SingletBlue", Name = "Blue Singlet", Slot = "Top", Mesh = "Kit_Singlet", Color = "#1E7BFF", Minutes = 5 },
		{ Id = "TeeGold", Name = "Gold Race Tee", Slot = "Top", Mesh = "Kit_Tee", Color = "#FFC83D", Minutes = 15 },
		{ Id = "ZipBlack", Name = "Black Zip Top", Slot = "Top", Mesh = "Kit_ZipTop", Color = "#1A1F29", Minutes = 30 },
		{ Id = "ShortsBlue", Name = "Blue Race Shorts", Slot = "Bottom", Mesh = "Kit_Shorts", Color = "#0E3A8A", Minutes = 5 },
		{ Id = "SplitBlack", Name = "Black Split Shorts", Slot = "Bottom", Mesh = "Kit_SplitShorts", Color = "#161A22", Minutes = 15 },
		{ Id = "TightsGold", Name = "Gold Run Tights", Slot = "Bottom", Mesh = "Kit_Tights", Color = "#E0A92A", Minutes = 30 },
		-- VIP kit (the VIP pass)
		{ Id = "VipTop", Name = "VIP Singlet", Slot = "Top", Mesh = "Kit_Singlet", Color = "#FFC83D", Pass = "VIP" },
		{ Id = "VipShorts", Name = "VIP Shorts", Slot = "Bottom", Mesh = "Kit_Shorts", Color = "#0B0D12", Pass = "VIP" },
	},
	Headwear = {
		{ Id = "Headband", Name = "Headband", Mesh = "Head_Headband", Color = "#1E7BFF", Minutes = 5 },
		{ Id = "Cap", Name = "Team Cap", Mesh = "Head_Cap", Color = "#0E3A8A", Minutes = 10 },
		{ Id = "Visor", Name = "Gold Visor", Mesh = "Head_Visor", Color = "#FFC83D", Minutes = 12 },
		{ Id = "Shades", Name = "Sport Shades", Mesh = "Head_Shades", Color = "#161A22", Minutes = 15 },
		{ Id = "BucketHat", Name = "Bucket Hat", Mesh = "Head_BucketHat", Color = "#F4F6FA", Minutes = 18 },
		{ Id = "Beanie", Name = "Winter Beanie", Mesh = "Head_Beanie", Color = "#FF4A4A", Minutes = 20 },
	},
	-- Bib: your race number on your chest (1-999, free). Colours unlock by league.
	Bib = {
		MaxNumber = 999,
		Colors = {
			{ Id = "Blue", Name = "Blue", Color = "#1E7BFF", League = 1 },
			{ Id = "Green", Name = "Park Green", Color = "#3FA34D", League = 2 },
			{ Id = "Silver", Name = "Stadium Silver", Color = "#C9D1DD", League = 3 },
			{ Id = "Gold", Name = "World Gold", Color = "#FFC83D", League = 5 },
		},
	},
	-- Name styles: the colour of your name over your head (long coin goals)
	NameStyles = {
		{ Id = "Blue", Name = "Electric Blue", Colors = { "#4FC3FF", "#1E7BFF" }, Minutes = 60 },
		{ Id = "Gold", Name = "Gold", Colors = { "#FFE38C", "#FFC83D" }, Minutes = 90 },
		{ Id = "Ice", Name = "Ice", Colors = { "#F4F6FA", "#4FC3FF" }, Minutes = 120 },
		{ Id = "Fire", Name = "Fire", Colors = { "#FFE38C", "#FF7A1F" }, Minutes = 150 },
		{ Id = "BlackGold", Name = "Black Gold", Colors = { "#FFC83D", "#5A4A1A" }, Minutes = 180 },
		{ Id = "VIP", Name = "VIP", Colors = { "#FFC83D", "#FF7A1F" }, Pass = "VIP" },
	},
	-- shoe skins (colourways): the Starter Pack's gold Canvas Runners
	ShoeSkins = {
		CanvasRunners_Starter = { Shoe = "CanvasRunners", Name = "Starter Gold", Color = "#FFC83D" },
	},
	HideOthersBeyond = 150, -- studs: other players' worn meshes hide further away
}
