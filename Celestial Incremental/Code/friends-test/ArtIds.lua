-- ArtIds (Galaxy Incremental, 6 Nov; prompt "LUMI EXPRESSIONS + RANK TITLE ART"): every id of the LUMI and rank-title
-- art in one place (no ids anywhere else). Files: Celestial Incremental\Assets\lumi, \titles, \vfx\lumi.
-- The ids are the P&L Studios XP group's uploads (the owner's bulk import, 6 Nov).
local A = {}
-- LUMI's 6 expressions (512 = the tutorial card portrait, 128 = small spots)
A.lumi = {
	talking = "rbxassetid://117087396384265",
	pointing = "rbxassetid://116972303663451",
	excited = "rbxassetid://78745470630381",
	happy = "rbxassetid://100806683828254",
	proud = "rbxassetid://98563703573699",
	thinking = "rbxassetid://92379491430795",
}
A.lumi128 = {
	talking = "rbxassetid://135519780884542",
	pointing = "rbxassetid://77048347575761",
	excited = "rbxassetid://98489180035028",
	happy = "rbxassetid://83390434803417",
	proud = "rbxassetid://139436876692543",
	thinking = "rbxassetid://109122289254709",
}
-- LUMI's effects (_alpha = UI, tinted; _add = world particles, LightEmission 1)
A.lumiFx = {
	halo = "rbxassetid://73791118365269",
	sparkleTrail = "rbxassetid://138197985681512",
	appearPoof = "rbxassetid://114426201526288",
	heartStar = "rbxassetid://124680954988176",
	pointer = "rbxassetid://103914951127321",
	twinkle = "rbxassetid://93069422416896",
}
A.lumiFxAdd = {
	halo = "rbxassetid://106833981704410",
	sparkleTrail = "rbxassetid://123166084368179",
	appearPoof = "rbxassetid://127799425174988",
	heartStar = "rbxassetid://88226058838843",
	pointer = "rbxassetid://102610469057455",
	twinkle = "rbxassetid://111123325584281",
}
-- the rank emblems (512 + 128) and their banner plates (1024, empty: the text goes on top)
A.rank = {
	new_star = "rbxassetid://89600082591566",
	spark = "rbxassetid://78235015398286",
	flare = "rbxassetid://103685803249557",
	blaze = "rbxassetid://125822913474233",
	nova = "rbxassetid://129474209423866",
	supergiant = "rbxassetid://119057112345542",
}
A.rank128 = {
	new_star = "rbxassetid://109422878615763",
	spark = "rbxassetid://100717744950357",
	flare = "rbxassetid://124894169368229",
	blaze = "rbxassetid://121418444009621",
	nova = "rbxassetid://139364379072580",
	supergiant = "rbxassetid://107767160242843",
}
A.plate = {
	new_star = "rbxassetid://115246382082318",
	spark = "rbxassetid://90217463350727",
	flare = "rbxassetid://93504942305740",
	blaze = "rbxassetid://136165374295889",
	nova = "rbxassetid://123306551172765",
	supergiant = "rbxassetid://128041560933204",
}
-- (7 Nov: the 9 weak UIs' new art, Assets/ui, prompt 'NEW UI ART FOR THE 9 WEAK UIs'. Group ids (P&L Studios XP,
-- imported by the owner 7 Nov))
A.ui = {
	cardBack = "rbxassetid://101387423894945", -- the Forge card's back (before the flip)
	card = { Common = "rbxassetid://71021729038330", Uncommon = "rbxassetid://91441307241226", Rare = "rbxassetid://119201555133285", Epic = "rbxassetid://125758543057445",
		Legendary = "rbxassetid://118469745280338", Mythic = "rbxassetid://73920516614074", Celestial = "rbxassetid://110110572885031" },
	plaque = "rbxassetid://89093867656806", -- the leaderboard boards
	row = { gold = "rbxassetid://105709001777534", silver = "rbxassetid://122860293572816", bronze = "rbxassetid://99479388410995" },
	medal = { "rbxassetid://135666899361723", "rbxassetid://100056181929811", "rbxassetid://101043733093147" },
	signLocked = "rbxassetid://106374341547572", -- the locked island boards
}
-- the new icons (512; Kit.icon finds them by these names too, as "ui:<name>")
A.uiIcon = {
	bodies = "rbxassetid://89134302104435",
	checkDone = "rbxassetid://104179310775621",
	checkEmpty = "rbxassetid://137691735892950",
	comet = "rbxassetid://131343793351633",
	cooldown = "rbxassetid://93195828602893",
	darkMatter = "rbxassetid://92182121871359",
	essence = "rbxassetid://106572560252409",
	forgeRolls = "rbxassetid://73151743225016",
	keep = "rbxassetid://123989008126451",
	lock = "rbxassetid://101709923599217",
	playtime = "rbxassetid://124171523892238",
	reset = "rbxassetid://101881184721305",
	starCore = "rbxassetid://104761787576688",
	starShard = "rbxassetid://91902429832510",
	supernova = "rbxassetid://135507495295555",
	trophy = "rbxassetid://127031199985219",
}
A.uiIcon128 = {
	bodies = "rbxassetid://131155501758809",
	checkDone = "rbxassetid://126618089355699",
	checkEmpty = "rbxassetid://140251785262733",
	comet = "rbxassetid://140170910795888",
	cooldown = "rbxassetid://94368522621794",
	darkMatter = "rbxassetid://110464494247708",
	essence = "rbxassetid://125698901531060",
	forgeRolls = "rbxassetid://74987758501372",
	keep = "rbxassetid://82841944521392",
	lock = "rbxassetid://122051159998588",
	playtime = "rbxassetid://97306154160718",
	reset = "rbxassetid://107868642223501",
	starCore = "rbxassetid://118039856854925",
	starShard = "rbxassetid://90956822079526",
	supernova = "rbxassetid://128906966133797",
	trophy = "rbxassetid://139972944661727",
}
return A
