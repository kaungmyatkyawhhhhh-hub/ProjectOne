-- ArtIds (Galaxy Incremental, 6 Nov; prompt "LUMI EXPRESSIONS + RANK TITLE ART"): every id of the LUMI and rank-title
-- art in one place (no ids anywhere else). Files: Celestial Incremental\Assets\lumi, \titles, \vfx\lumi.
-- These ids are STUDIO TEST UPLOADS (the owner's account, 6 Nov). Re-upload the files to the P&L Studios XP group (Asset
-- Manager > bulk import, owner = group) and replace the ids here.
local A = {}
-- LUMI's 6 expressions (512 = the tutorial card portrait, 128 = small spots)
A.lumi = {
	talking = "rbxassetid://86517474174718",
	pointing = "rbxassetid://72446359091922",
	excited = "rbxassetid://112947438872116",
	happy = "rbxassetid://90070385135133",
	proud = "rbxassetid://120686016664649",
	thinking = "rbxassetid://90676836208382",
}
A.lumi128 = {
	talking = "rbxassetid://137508388908351",
	pointing = "rbxassetid://122520790496245",
	excited = "rbxassetid://71736526436123",
	happy = "rbxassetid://116468315221258",
	proud = "rbxassetid://128277732193795",
	thinking = "rbxassetid://134969940337546",
}
-- LUMI's effects (_alpha = UI, tinted; _add = world particles, LightEmission 1)
A.lumiFx = {
	halo = "rbxassetid://129668798916581",
	sparkleTrail = "rbxassetid://120524903399304",
	appearPoof = "rbxassetid://81777597165123",
	heartStar = "rbxassetid://98808007750824",
	pointer = "rbxassetid://101020742980242",
	twinkle = "rbxassetid://112741314252595",
}
A.lumiFxAdd = {
	halo = "rbxassetid://116318669325387",
	sparkleTrail = "rbxassetid://92133608514725",
	appearPoof = "rbxassetid://71372342802395",
	heartStar = "rbxassetid://136939412221987",
	pointer = "rbxassetid://77036979346853",
	twinkle = "rbxassetid://88539862264577",
}
-- the rank emblems (512 + 128) and their banner plates (1024, empty: the text goes on top)
A.rank = {
	new_star = "rbxassetid://126442591640340",
	spark = "rbxassetid://127220283595259",
	flare = "rbxassetid://76874216180823",
	blaze = "rbxassetid://102893906472943",
	nova = "rbxassetid://100920364275003",
	supergiant = "rbxassetid://108053138507561",
}
A.rank128 = {
	new_star = "rbxassetid://120191686916052",
	spark = "rbxassetid://82668862483966",
	flare = "rbxassetid://111886495152738",
	blaze = "rbxassetid://128176229752282",
	nova = "rbxassetid://99404668018336",
	supergiant = "rbxassetid://99580656420762",
}
A.plate = {
	new_star = "rbxassetid://87666283308292",
	spark = "rbxassetid://113165423008936",
	flare = "rbxassetid://111610866151387",
	blaze = "rbxassetid://92874499389265",
	nova = "rbxassetid://91327781688430",
	supergiant = "rbxassetid://136662700522424",
}
return A
