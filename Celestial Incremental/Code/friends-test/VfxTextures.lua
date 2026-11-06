-- VfxTextures (Galaxy Incremental, VFX pass 6 Nov): EVERY VFX texture id, in one place (no ids anywhere else).
-- Files: Celestial Incremental\Assets\vfx\ (A, BDE, C, F, G, H). Two versions of each:
--   add   = black background -> ParticleEmitter / Beam LightEmission 1 (the black disappears)
--   alpha = transparent -> normal particles and screen UI (ImageLabels), tinted with Color
-- Flipbooks (4x4, 1024): FlipbookLayout Grid4x4; one-shots explosion_burst, supernova_flash, anvil_impact, confetti_burst,
-- smoke_puff; loops electric_arc, forge_sparks, portal_swirl.
-- These ids are STUDIO TEST UPLOADS (the owner's account, 6 Nov). Re-upload the files to the P&L Studios XP group (Asset
-- Manager > bulk import, owner = group) and replace the ids here.
local T = {}
T.add = {
	anvil_impact = "rbxassetid://124413239805008", -- H/vfx_anvil_impact_flipbook4x4_1024_add.png
	aura_common = "rbxassetid://123436895092520", -- BDE/vfx_aura_common_512_add.png
	aura_epic = "rbxassetid://105108725707261", -- BDE/vfx_aura_epic_512_add.png
	aura_legendary = "rbxassetid://108140616150957", -- BDE/vfx_aura_legendary_512_add.png
	aura_mythic = "rbxassetid://137419388230849", -- BDE/vfx_aura_mythic_512_add.png
	aura_rare = "rbxassetid://99226559069913", -- BDE/vfx_aura_rare_512_add.png
	aura_uncommon = "rbxassetid://82493815574677", -- BDE/vfx_aura_uncommon_512_add.png
	black_hole_swirl = "rbxassetid://104798222947210", -- BDE/vfx_black_hole_swirl_512_add.png
	bridge_segment = "rbxassetid://86840033076457", -- G/vfx_bridge_segment_512_add.png
	build_sparkle_trail = "rbxassetid://81562456657276", -- G/vfx_build_sparkle_trail_512_add.png
	comet_head = "rbxassetid://118735959636048", -- BDE/vfx_comet_head_512_add.png
	comet_tail = "rbxassetid://121842342773547", -- BDE/vfx_comet_tail_512_add.png
	confetti_burst = "rbxassetid://100266960654313", -- H/vfx_confetti_burst_flipbook4x4_1024_add.png
	confetti_pieces = "rbxassetid://108106412372837", -- F/vfx_confetti_pieces_512_add.png
	core_light_rays = "rbxassetid://109864604358324", -- BDE/vfx_core_light_rays_512_add.png (re-uploaded, as above)
	crystal_shard = "rbxassetid://94050750335533", -- A/vfx_crystal_shard_add_512.png
	dark_pulse = "rbxassetid://96168485212194", -- BDE/vfx_dark_pulse_512_add.png
	electric_arc = "rbxassetid://126086375296415", -- C/vfx_electric_arc_flipbook4x4_1024_add.png (re-uploaded, as above)
	explosion_burst = "rbxassetid://106846492434754", -- C/vfx_explosion_burst_flipbook4x4_1024_add.png
	forge_beam = "rbxassetid://101653298760879", -- F/vfx_forge_beam_512_add.png
	forge_card_frame = "rbxassetid://96841240841401", -- F/vfx_forge_card_frame_512_add.png
	forge_glow = "rbxassetid://109215121482650", -- F/vfx_forge_glow_512_add.png
	forge_sparks = "rbxassetid://108672907992202", -- H/vfx_forge_sparks_flipbook4x4_1024_add.png (re-uploaded, as above)
	glow_dot = "rbxassetid://70908126201612", -- A/vfx_glow_dot_add_512.png
	gold_coin_sparkle = "rbxassetid://97346391518938", -- BDE/vfx_gold_coin_sparkle_512_add.png
	ground_dust_ring = "rbxassetid://126178353833555", -- G/vfx_ground_dust_ring_512_add.png
	hammer_impact_star = "rbxassetid://107273780062087", -- F/vfx_hammer_impact_star_512_add.png
	island_beam = "rbxassetid://140345607359500", -- G/vfx_island_beam_512_add.png
	light_streak = "rbxassetid://130714650356337", -- A/vfx_light_streak_add_512.png
	molten_droplet = "rbxassetid://131413474703809", -- F/vfx_molten_droplet_512_add.png
	nebula_wisp = "rbxassetid://140209881372935", -- BDE/vfx_nebula_wisp_512_add.png
	pad_build_ring = "rbxassetid://134334058258634", -- G/vfx_pad_build_ring_512_add.png
	portal_swirl = "rbxassetid://106289347610660", -- H/vfx_portal_swirl_flipbook4x4_1024_add.png
	quasar_beam = "rbxassetid://105737528715102", -- BDE/vfx_quasar_beam_512_add.png
	rays_burst = "rbxassetid://110474773343714", -- BDE/vfx_rays_burst_512_add.png
	rune_circle = "rbxassetid://75039029085786", -- BDE/vfx_rune_circle_512_add.png
	shockwave_ring = "rbxassetid://108653492215290", -- A/vfx_shockwave_ring_add_512.png
	smoke_puff = "rbxassetid://74761726311191", -- C/vfx_smoke_puff_flipbook4x4_add_1024.png
	sparkle_star = "rbxassetid://108205306637757", -- A/vfx_sparkle_star_add_512.png
	star_surge_wave = "rbxassetid://119138714857329", -- BDE/vfx_star_surge_wave_512_add.png
	starburst_twinkle = "rbxassetid://109542141755813", -- BDE/vfx_starburst_twinkle_512_add.png
	stardust_mote = "rbxassetid://115083399536350", -- A/vfx_stardust_mote_add_512.png (re-uploaded 6 Nov: the first copy never finished processing)
	supernova_flash = "rbxassetid://94375615122925", -- C/vfx_supernova_flash_flipbook4x4_1024_add.png
	tierup_crown_burst = "rbxassetid://97529024113499", -- G/vfx_tierup_crown_burst_512_add.png
}
T.alpha = {
	anvil_impact = "rbxassetid://83193099791164", -- H/vfx_anvil_impact_flipbook4x4_1024_alpha.png
	aura_common = "rbxassetid://113735012641898", -- BDE/vfx_aura_common_512_alpha.png
	aura_epic = "rbxassetid://72811380058211", -- BDE/vfx_aura_epic_512_alpha.png
	aura_legendary = "rbxassetid://90046726836365", -- BDE/vfx_aura_legendary_512_alpha.png
	aura_mythic = "rbxassetid://93850946940012", -- BDE/vfx_aura_mythic_512_alpha.png
	aura_rare = "rbxassetid://97554959875089", -- BDE/vfx_aura_rare_512_alpha.png
	aura_uncommon = "rbxassetid://136935679586939", -- BDE/vfx_aura_uncommon_512_alpha.png
	black_hole_swirl = "rbxassetid://87462087208792", -- BDE/vfx_black_hole_swirl_512_alpha.png
	bridge_segment = "rbxassetid://116467706701029", -- G/vfx_bridge_segment_512_alpha.png
	build_sparkle_trail = "rbxassetid://79312347420500", -- G/vfx_build_sparkle_trail_512_alpha.png
	comet_head = "rbxassetid://108650159012155", -- BDE/vfx_comet_head_512_alpha.png
	comet_tail = "rbxassetid://78082218758177", -- BDE/vfx_comet_tail_512_alpha.png
	confetti_burst = "rbxassetid://137347329841404", -- H/vfx_confetti_burst_flipbook4x4_1024_alpha.png
	confetti_pieces = "rbxassetid://78684197535694", -- F/vfx_confetti_pieces_512_alpha.png
	core_light_rays = "rbxassetid://92810398172293", -- BDE/vfx_core_light_rays_512_alpha.png
	crystal_shard = "rbxassetid://99808765750536", -- A/vfx_crystal_shard_alpha_512.png
	dark_pulse = "rbxassetid://80579896699603", -- BDE/vfx_dark_pulse_512_alpha.png
	electric_arc = "rbxassetid://86306402662870", -- C/vfx_electric_arc_flipbook4x4_1024_alpha.png
	explosion_burst = "rbxassetid://130600153609930", -- C/vfx_explosion_burst_flipbook4x4_1024_alpha.png
	forge_beam = "rbxassetid://100997363751229", -- F/vfx_forge_beam_512_alpha.png
	forge_card_frame = "rbxassetid://103881444649940", -- F/vfx_forge_card_frame_512_alpha.png
	forge_glow = "rbxassetid://83503575449526", -- F/vfx_forge_glow_512_alpha.png
	forge_sparks = "rbxassetid://137474928889108", -- H/vfx_forge_sparks_flipbook4x4_1024_alpha.png
	glow_dot = "rbxassetid://76594526128656", -- A/vfx_glow_dot_alpha_512.png
	gold_coin_sparkle = "rbxassetid://135694111691070", -- BDE/vfx_gold_coin_sparkle_512_alpha.png
	ground_dust_ring = "rbxassetid://123702856290236", -- G/vfx_ground_dust_ring_512_alpha.png
	hammer_impact_star = "rbxassetid://97365251584266", -- F/vfx_hammer_impact_star_512_alpha.png
	island_beam = "rbxassetid://119122265026891", -- G/vfx_island_beam_512_alpha.png
	light_streak = "rbxassetid://70970124805876", -- A/vfx_light_streak_alpha_512.png
	molten_droplet = "rbxassetid://71877201242598", -- F/vfx_molten_droplet_512_alpha.png
	nebula_wisp = "rbxassetid://102783879099888", -- BDE/vfx_nebula_wisp_512_alpha.png
	pad_build_ring = "rbxassetid://86644681624643", -- G/vfx_pad_build_ring_512_alpha.png
	portal_swirl = "rbxassetid://100349262505734", -- H/vfx_portal_swirl_flipbook4x4_1024_alpha.png
	quasar_beam = "rbxassetid://86892683025175", -- BDE/vfx_quasar_beam_512_alpha.png
	rays_burst = "rbxassetid://105935187500976", -- BDE/vfx_rays_burst_512_alpha.png
	rune_circle = "rbxassetid://122701084626724", -- BDE/vfx_rune_circle_512_alpha.png
	shockwave_ring = "rbxassetid://86012991092743", -- A/vfx_shockwave_ring_alpha_512.png
	smoke_puff = "rbxassetid://138439974753173", -- C/vfx_smoke_puff_flipbook4x4_alpha_1024.png
	sparkle_star = "rbxassetid://94916858645859", -- A/vfx_sparkle_star_alpha_512.png
	star_surge_wave = "rbxassetid://71884519272837", -- BDE/vfx_star_surge_wave_512_alpha.png
	starburst_twinkle = "rbxassetid://112468428950379", -- BDE/vfx_starburst_twinkle_512_alpha.png
	stardust_mote = "rbxassetid://101847071084706", -- A/vfx_stardust_mote_alpha_512.png
	supernova_flash = "rbxassetid://138438201873503", -- C/vfx_supernova_flash_flipbook4x4_1024_alpha.png
	tierup_crown_burst = "rbxassetid://95893801117431", -- G/vfx_tierup_crown_burst_512_alpha.png
}
T.flipbooks = { explosion_burst = "OneShot", supernova_flash = "OneShot", anvil_impact = "OneShot", confetti_burst = "OneShot",
	smoke_puff = "OneShot", electric_arc = "Loop", forge_sparks = "Loop", portal_swirl = "Loop" }
return T
