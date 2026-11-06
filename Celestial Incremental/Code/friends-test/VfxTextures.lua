-- VfxTextures (Galaxy Incremental, VFX pass 6 Nov): EVERY VFX texture id, in one place (no ids anywhere else).
-- Files: Celestial Incremental\Assets\vfx\ (A, BDE, C, F, G, H). Two versions of each:
--   add   = black background -> ParticleEmitter / Beam LightEmission 1 (the black disappears)
--   alpha = transparent -> normal particles and screen UI (ImageLabels), tinted with Color
-- Flipbooks (4x4, 1024): FlipbookLayout Grid4x4; one-shots explosion_burst, supernova_flash, anvil_impact, confetti_burst,
-- smoke_puff; loops electric_arc, forge_sparks, portal_swirl.
-- The ids are the P&L Studios XP group's uploads (the owner's bulk import, 6 Nov).
local T = {}
T.add = {
	anvil_impact = "rbxassetid://118234560109808", -- H/vfx_anvil_impact_flipbook4x4_1024_add.png
	aura_common = "rbxassetid://99263984325120", -- BDE/vfx_aura_common_512_add.png
	aura_epic = "rbxassetid://97016518847576", -- BDE/vfx_aura_epic_512_add.png
	aura_legendary = "rbxassetid://99104629862358", -- BDE/vfx_aura_legendary_512_add.png
	aura_mythic = "rbxassetid://93487927686996", -- BDE/vfx_aura_mythic_512_add.png
	aura_rare = "rbxassetid://90907938363173", -- BDE/vfx_aura_rare_512_add.png
	aura_uncommon = "rbxassetid://107869676751354", -- BDE/vfx_aura_uncommon_512_add.png
	black_hole_swirl = "rbxassetid://113787647440456", -- BDE/vfx_black_hole_swirl_512_add.png
	bridge_segment = "rbxassetid://119934130338878", -- G/vfx_bridge_segment_512_add.png
	build_sparkle_trail = "rbxassetid://136031776956581", -- G/vfx_build_sparkle_trail_512_add.png
	comet_head = "rbxassetid://140413475547141", -- BDE/vfx_comet_head_512_add.png
	comet_tail = "rbxassetid://100336815743008", -- BDE/vfx_comet_tail_512_add.png
	confetti_burst = "rbxassetid://80044379144048", -- H/vfx_confetti_burst_flipbook4x4_1024_add.png
	confetti_pieces = "rbxassetid://99701066884789", -- F/vfx_confetti_pieces_512_add.png
	core_light_rays = "rbxassetid://113369449336887", -- BDE/vfx_core_light_rays_512_add.png (the image inside decal 115502892460875)
	crystal_shard = "rbxassetid://89429839064369", -- A/vfx_crystal_shard_add_512.png
	dark_pulse = "rbxassetid://108298599304639", -- BDE/vfx_dark_pulse_512_add.png
	electric_arc = "rbxassetid://118833364940449", -- C/vfx_electric_arc_flipbook4x4_1024_add.png
	explosion_burst = "rbxassetid://138077903200783", -- C/vfx_explosion_burst_flipbook4x4_1024_add.png
	forge_beam = "rbxassetid://129178535120439", -- F/vfx_forge_beam_512_add.png
	forge_card_frame = "rbxassetid://97771959834506", -- F/vfx_forge_card_frame_512_add.png
	forge_glow = "rbxassetid://88641632604369", -- F/vfx_forge_glow_512_add.png
	forge_sparks = "rbxassetid://109713926738340", -- H/vfx_forge_sparks_flipbook4x4_1024_add.png
	glow_dot = "rbxassetid://133199307031116", -- A/vfx_glow_dot_add_512.png
	gold_coin_sparkle = "rbxassetid://102633277159397", -- BDE/vfx_gold_coin_sparkle_512_add.png
	ground_dust_ring = "rbxassetid://99850540078768", -- G/vfx_ground_dust_ring_512_add.png
	hammer_impact_star = "rbxassetid://127003640213374", -- F/vfx_hammer_impact_star_512_add.png
	island_beam = "rbxassetid://100643319879576", -- G/vfx_island_beam_512_add.png
	light_streak = "rbxassetid://115111583892768", -- A/vfx_light_streak_add_512.png
	molten_droplet = "rbxassetid://118920688958955", -- F/vfx_molten_droplet_512_add.png
	nebula_wisp = "rbxassetid://110591065638585", -- BDE/vfx_nebula_wisp_512_add.png
	pad_build_ring = "rbxassetid://118889089009159", -- G/vfx_pad_build_ring_512_add.png
	portal_swirl = "rbxassetid://134951907503343", -- H/vfx_portal_swirl_flipbook4x4_1024_add.png
	quasar_beam = "rbxassetid://138620865814186", -- BDE/vfx_quasar_beam_512_add.png
	rays_burst = "rbxassetid://111293750211595", -- BDE/vfx_rays_burst_512_add.png
	rune_circle = "rbxassetid://88530392310419", -- BDE/vfx_rune_circle_512_add.png
	shockwave_ring = "rbxassetid://129047833466274", -- A/vfx_shockwave_ring_add_512.png
	smoke_puff = "rbxassetid://84100266532094", -- C/vfx_smoke_puff_flipbook4x4_add_1024.png
	sparkle_star = "rbxassetid://139000120976614", -- A/vfx_sparkle_star_add_512.png
	star_surge_wave = "rbxassetid://113627907524220", -- BDE/vfx_star_surge_wave_512_add.png
	starburst_twinkle = "rbxassetid://122731686716614", -- BDE/vfx_starburst_twinkle_512_add.png
	stardust_mote = "rbxassetid://104242775397850", -- A/vfx_stardust_mote_add_512.png
	supernova_flash = "rbxassetid://70982360068144", -- C/vfx_supernova_flash_flipbook4x4_1024_add.png
	tierup_crown_burst = "rbxassetid://100141602774407", -- G/vfx_tierup_crown_burst_512_add.png
}
T.alpha = {
	anvil_impact = "rbxassetid://82071130009882", -- H/vfx_anvil_impact_flipbook4x4_1024_alpha.png
	aura_common = "rbxassetid://99706750086174", -- BDE/vfx_aura_common_512_alpha.png
	aura_epic = "rbxassetid://102414582733787", -- BDE/vfx_aura_epic_512_alpha.png
	aura_legendary = "rbxassetid://81532581081598", -- BDE/vfx_aura_legendary_512_alpha.png
	aura_mythic = "rbxassetid://73366641640104", -- BDE/vfx_aura_mythic_512_alpha.png
	aura_rare = "rbxassetid://81877384098811", -- BDE/vfx_aura_rare_512_alpha.png
	aura_uncommon = "rbxassetid://116501870555582", -- BDE/vfx_aura_uncommon_512_alpha.png
	black_hole_swirl = "rbxassetid://125237533530152", -- BDE/vfx_black_hole_swirl_512_alpha.png
	bridge_segment = "rbxassetid://112503823963940", -- G/vfx_bridge_segment_512_alpha.png
	build_sparkle_trail = "rbxassetid://82719035072589", -- G/vfx_build_sparkle_trail_512_alpha.png
	comet_head = "rbxassetid://90899113298190", -- BDE/vfx_comet_head_512_alpha.png (re-uploaded 7 Nov: 124706844499223 never loaded)
	comet_tail = "rbxassetid://113370765750175", -- BDE/vfx_comet_tail_512_alpha.png
	confetti_burst = "rbxassetid://78001004234977", -- H/vfx_confetti_burst_flipbook4x4_1024_alpha.png
	confetti_pieces = "rbxassetid://133137263419583", -- F/vfx_confetti_pieces_512_alpha.png
	core_light_rays = "rbxassetid://82573454991524", -- BDE/vfx_core_light_rays_512_alpha.png
	crystal_shard = "rbxassetid://72466718280633", -- A/vfx_crystal_shard_alpha_512.png
	dark_pulse = "rbxassetid://113482456156465", -- BDE/vfx_dark_pulse_512_alpha.png
	electric_arc = "rbxassetid://83257025081904", -- C/vfx_electric_arc_flipbook4x4_1024_alpha.png
	explosion_burst = "rbxassetid://85666920494132", -- C/vfx_explosion_burst_flipbook4x4_1024_alpha.png
	forge_beam = "rbxassetid://94442343358983", -- F/vfx_forge_beam_512_alpha.png
	forge_card_frame = "rbxassetid://137572793272248", -- F/vfx_forge_card_frame_512_alpha.png
	forge_glow = "rbxassetid://137489360341714", -- F/vfx_forge_glow_512_alpha.png
	forge_sparks = "rbxassetid://89837646840352", -- H/vfx_forge_sparks_flipbook4x4_1024_alpha.png (re-uploaded 7 Nov: 99004213794315 never loaded)
	glow_dot = "rbxassetid://128335922437416", -- A/vfx_glow_dot_alpha_512.png
	gold_coin_sparkle = "rbxassetid://100475753325033", -- BDE/vfx_gold_coin_sparkle_512_alpha.png (re-uploaded 7 Nov: 105414210629114 never loaded)
	ground_dust_ring = "rbxassetid://72420258647993", -- G/vfx_ground_dust_ring_512_alpha.png
	hammer_impact_star = "rbxassetid://110328091080135", -- F/vfx_hammer_impact_star_512_alpha.png
	island_beam = "rbxassetid://88900452951935", -- G/vfx_island_beam_512_alpha.png
	light_streak = "rbxassetid://120811300419494", -- A/vfx_light_streak_alpha_512.png
	molten_droplet = "rbxassetid://125473186626408", -- F/vfx_molten_droplet_512_alpha.png
	nebula_wisp = "rbxassetid://114832747855756", -- BDE/vfx_nebula_wisp_512_alpha.png
	pad_build_ring = "rbxassetid://75419192874318", -- G/vfx_pad_build_ring_512_alpha.png
	portal_swirl = "rbxassetid://114280229008076", -- H/vfx_portal_swirl_flipbook4x4_1024_alpha.png
	quasar_beam = "rbxassetid://118655526772239", -- BDE/vfx_quasar_beam_512_alpha.png
	rays_burst = "rbxassetid://99524271493276", -- BDE/vfx_rays_burst_512_alpha.png
	rune_circle = "rbxassetid://71604763525467", -- BDE/vfx_rune_circle_512_alpha.png
	shockwave_ring = "rbxassetid://124595918859980", -- A/vfx_shockwave_ring_alpha_512.png
	smoke_puff = "rbxassetid://79164406517700", -- C/vfx_smoke_puff_flipbook4x4_alpha_1024.png
	sparkle_star = "rbxassetid://137600102248146", -- A/vfx_sparkle_star_alpha_512.png
	star_surge_wave = "rbxassetid://103082783620839", -- BDE/vfx_star_surge_wave_512_alpha.png
	starburst_twinkle = "rbxassetid://91499991030980", -- BDE/vfx_starburst_twinkle_512_alpha.png
	stardust_mote = "rbxassetid://86226269904831", -- A/vfx_stardust_mote_alpha_512.png
	supernova_flash = "rbxassetid://126825831045463", -- C/vfx_supernova_flash_flipbook4x4_1024_alpha.png
	tierup_crown_burst = "rbxassetid://136986321978447", -- G/vfx_tierup_crown_burst_512_alpha.png
}
-- (7 Nov: the _alpha twin of any id (an _add id, or an old upload of the mote); nil = unknown. Used by MapService to fix
-- emitters saved in the place, and by Tools/VfxTextureAudit)
T.oldIds = { ["rbxassetid://107591336585756"] = "stardust_mote" } -- (an early upload of the mote, on the Black Hole's Pull)
-- (an _alpha upload that won't load on Roblox goes here (its name = true): effects then use the _add file at LightEmission
-- 1 until it's re-uploaded. 7 Nov: comet_head, forge_sparks, gold_coin_sparkle were here; the owner re-uploaded them)
T.brokenAlpha = {}
-- the texture an EFFECT (emitter / beam / trail) should use, and whether it must be LightEmission 1
function T.fx(name: string): (string, boolean)
	if T.brokenAlpha[name] then return T.add[name], true end
	return T.alpha[name], false
end
function T.alphaOf(id: string): string?
	for _, v in pairs(T.alpha) do if v == id then return v end end
	for k, v in pairs(T.add) do if v == id then return (T.fx(k)) end end
	local old = T.oldIds[id]
	return if old then T.alpha[old] else nil
end
T.flipbooks = { explosion_burst = "OneShot", supernova_flash = "OneShot", anvil_impact = "OneShot", confetti_burst = "OneShot",
	smoke_puff = "OneShot", electric_arc = "Loop", forge_sparks = "Loop", portal_swirl = "Loop" }
return T
