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
return A
