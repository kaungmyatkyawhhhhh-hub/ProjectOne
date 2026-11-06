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
-- (7 Nov: the 9 weak UIs' new art, Assets/ui, prompt 'NEW UI ART FOR THE 9 WEAK UIs'. STUDIO TEST UPLOADS (owner's
-- account): the owner group-imports them to P&L Studios XP, then these ids are swapped)
A.ui = {
	cardBack = "rbxassetid://96221144388203", -- the Forge card's back (before the flip)
	card = { Common = "rbxassetid://114295653500669", Uncommon = "rbxassetid://127186091425923", Rare = "rbxassetid://129497951198810", Epic = "rbxassetid://75366703719479",
		Legendary = "rbxassetid://135433262557381", Mythic = "rbxassetid://90141110823451", Celestial = "rbxassetid://123754381422922" },
	plaque = "rbxassetid://136967023294881", -- the leaderboard boards
	row = { gold = "rbxassetid://112855235823462", silver = "rbxassetid://83163898460461", bronze = "rbxassetid://74762401196466" },
	medal = { "rbxassetid://138499823934662", "rbxassetid://117671087560688", "rbxassetid://108286234795446" },
	signLocked = "rbxassetid://110023859014734", -- the locked island boards
}
-- the new icons (512; Kit.icon finds them by these names too, as "ui:<name>")
A.uiIcon = {
	bodies = "rbxassetid://108900349699469",
	checkDone = "rbxassetid://95931168962571",
	checkEmpty = "rbxassetid://136880282203905",
	comet = "rbxassetid://134722181316248",
	cooldown = "rbxassetid://115935213244757",
	darkMatter = "rbxassetid://128843910231978",
	essence = "rbxassetid://101698449037013",
	forgeRolls = "rbxassetid://87109939015182",
	keep = "rbxassetid://114970167622370",
	lock = "rbxassetid://89185707033939",
	playtime = "rbxassetid://107423182688241",
	reset = "rbxassetid://89575373606738",
	starCore = "rbxassetid://126417965974860",
	starShard = "rbxassetid://126842361932133",
	supernova = "rbxassetid://130128298476349",
	trophy = "rbxassetid://76394301271069",
}
A.uiIcon128 = {
	bodies = "rbxassetid://99555165341158",
	checkDone = "rbxassetid://114495593514870",
	checkEmpty = "rbxassetid://105551373234340",
	comet = "rbxassetid://107496112247116",
	cooldown = "rbxassetid://72177186522453",
	darkMatter = "rbxassetid://90110184353787",
	essence = "rbxassetid://80653408039264",
	forgeRolls = "rbxassetid://127141706915818",
	keep = "rbxassetid://138082696306807",
	lock = "rbxassetid://136642507891980",
	playtime = "rbxassetid://79209912137928",
	reset = "rbxassetid://103665160679183",
	starCore = "rbxassetid://113231424892654",
	starShard = "rbxassetid://97211927698186",
	supernova = "rbxassetid://91415311029827",
	trophy = "rbxassetid://132558760047562",
}
return A
