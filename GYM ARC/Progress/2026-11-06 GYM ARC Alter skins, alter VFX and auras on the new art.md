---
date: 2026-11-06
tags: [gymarc, alters, auras, vfx, art, progress]
status: built in Studio, not published
---
# GYM ARC - Alter skins 1-20, alter VFX and auras on the new ChatGPT art (6 Nov)

Prompt: the Claude Code prompt in [[2026-11-06 GYM ARC - ChatGPT art prompts (auras, alter textures, alter VFX)]]. Plan it follows: [[2026-11-01 GYM ARC Alter skins - every alter special]] (4-layer table), [[GYM ARC - Aura]].
Studio: "GYM ARC" (placeId 80031260599632). **Not published, not saved to Roblox.**

## 1. Uploads (all owned by Myanmar Builders Club)
- 314 images uploaded through Creator Hub (Development items > Upload assets, "Uploading to Myanmar Builders Club"), then 160 + 20 re-tiled skin maps and 10 flat rings. Decal ids turned into image ids in Studio.
- **One config module:** `ReplicatedStorage.Shared.Config.ArtIds` (324 image ids). Config/Alters, AlterLooks, AuraVFX, AuraPrestige, AlterFX, MuscleRig all read from it; no new id is typed anywhere else.
- Full list (decal + image ids): [[2026-11-06 GYM ARC - Art ids (ChatGPT batch)]].
- Fresh uploads take ~30-60 min to "process" on Roblox. Before that a map can fail to load and the body shows grey for that whole session. All 324 load now.

## 2. Alter skins 1-20 + the 6 skins
- `ReplicatedStorage.SkinStages`: `Alter_<id>` (arms, legs, hands, upper legs) and new `Alter_<id>_T` (torso + waist pieces). Builder: `ServerStorage._Builders.AlterSkinsArt`.
- ColorMap, NormalMap, RoughnessMap, MetalnessMap where a file exists (bronze, iron, steel, chrome, gold, marble, black marble, patina, rose gold); no metalness map = metalness 0.
- **Scale.** Measured the body meshes: on a big body one texture tile covers ~10 studs of arm and ~20 of torso, so the first upload's facets / plates were wider than a forearm (the ruby looked like smooth red plastic). Each skin is now pre-tiled so one facet / plate / vein cell is about hand-sized: x1 bronze, x2 most, x3 granite / marble / obsidian / chrome / sapphire / inferno / rose gold, x4 iron / steel; the torso set is 2x denser again (max x8). `MuscleRig.setSkin` puts the `_T` skin on any piece named *Torso* / *Waist*.
- **Human 1-5:** the ChatGPT colour maps were orange; turned into a light skin base (the player's own skin tint does the colour, like before), detail kept. Tanned / Peak keep the bronze tan math. Vascular veins made stronger in pass 3.
- **Gems:** normal maps rebuilt from the painted facets (they were only edge lines), low roughness, no Neon parts. Ruby / sapphire / amethyst / diamond now read as cut crystal.
- **Pass 3 colour fixes (after seeing them in the gym):** clay terracotta (was bright orange-red), bronze golden-brown (was copper red), jade softer (was neon green), granite speckle smaller.
- `Config/Alters`: textures from ArtIds, new `mean` values, head colours (`RawPlain`), variants use their own full map sets (`art = "..."`).
- **Head (my call):** no texture on the head, only the alter's colour + material as before. A textured head hides the face completely (screenshot B).

## 3. Alter VFX (Config/AlterLooks + AlterLookClient + AlterFX)
- Every emitter uses the new textures (`AlterLooks.Texture`): `_add` glows with LightEmission 1; clay fleck, rock chip, coin glint, sweat drop, jade leaf, amethyst shard, ruby heart use `_alpha` with LightEmission 0.
- Sizes and speeds now grow with the body (they were tiny on big bodies). Rep bursts and flex effects draw in front of the body (they were hidden inside the chest).

| # | Alter | Idle | Rep | Flex | Step |
|---|---|---|---|---|---|
| 1 | Pumped | heat haze | steam puff | - | - |
| 2 | Shredded | sweat drops | sweat flicks | - | - |
| 3 | Tanned | oil glints | oil-shine flash | - | - |
| 4 | Vascular | vein pulse | bright vein pulse | - | - |
| 5 | Peak | gold dust | gold dust | spotlight cone | gold-dust print |
| 6 | Clay | clay flecks | clay flecks | - | puff |
| 7 | Sandstone | sand trickle | sand burst | - | puff |
| 8 | Granite | grit | rock chips | - | puff |
| 9 | Marble | marble dust | dust burst | - | puff |
| 10 | Obsidian | embers | ember flash | lava cracks | glowing puff |
| 11 | Bronze | - | clank sparks + spark shower | - | puff |
| 12 | Iron | sparks | forge glow + spark shower | - | puff |
| 13 | Steel | steam jets | vent burst + spark shower | - | puff |
| 14 | Chrome | glints | chrome ripple + spark shower | big ripple | puff |
| 15 | Gold | gold dust | coin glints + spark shower | sun-ray halo behind the head | puff |
| 16 | Jade | jade leaves | jade leaves | - | puff |
| 17 | Ruby | red glints | ruby hearts from the core | - | puff |
| 18 | Sapphire | frost mist | frost burst | - | puff |
| 19 | Amethyst | shards | shard burst + orbit spin | - | puff |
| 20 | Diamond | rainbow sparkles | rainbow sparkles | prism beams | puff |

Skins (Robux / earned) got the same treatment: Inferno embers + lava cracks, Frostbite mist, Zombie green haze + drips, Black Marble gold dust + coins + sun-ray halo, Patina teal sparks + shower, Rose Gold sparkles + prism beams, Olympian gold dust + halo.
- **Flipbooks:** transform burst (every alter-up, white tinted per tier, 4x4 one shot 0.8 s, in front of the body), footstep puff (stone / metal / gem + skins, tinted per alter, max 1 per 0.3 s, others' puffs off on phones past 30 studs), spark shower (metal 11-15 + Patina / Rose Gold, on each rep, 0.7 s). The 3 flipbooks preload at join (the first burst was blank while it downloaded).
- Budget unchanged: others past 60 studs = skin only, idle <= 8 alive, lights only yours + 2 nearest.
- **Phones:** the 4 Nov rule still stands: alter particles and lights are off on phones / low graphics (and "Alter effects" defaults Off on phones). Phones see the skin + crystal pieces.

## 4. Auras (Shared/VFX/AuraVFX v4)
- Each aura = its own **wisp** (rising, 3-6 a second) + its own **particle** (floaters, 4-8 a second) + its **ground ring** + the **white flame loop** (4x4 Loop) tinted to the aura, coming off the body parts from behind (silhouette).
- **Rings:** the ChatGPT rings are drawn from slightly above (ovals). The 9 plain rings (storm, toxic, inferno, blood moon, void, neon, galaxy, royal, shadow) + the flare ring were redrawn flat and uploaded: they lie on the floor and turn slowly. Ember, frost, golden and titan have flames / rays rising out of their rings, so theirs stands up at the feet facing the camera (no spin, it breathes).
- **Level-up flare:** the game has no aura levels, so the flare (star + flat ring + pillar, tinted) plays on the aura's power-up moments: a personal record, the pump hitting 100%, and equipping an aura.
- Hard auras' own looks (Peak Human, Stone Skin, Forged, Gemstone, Elemental, Living Legend, star auras) borrow the closest art set with a light tint. The prestige layer's motes / halo / shockwave use the flare art.
- Budget: ~45 particles alive for your own aura at full power; other players x0.5 (6 nearest full, the rest ring + wisps); off past 60 studs (was 90); phones / low graphics x0.6. Only the flame loop + flares preload at join.

## 5. Tests
- Play test: 0 errors from these scripts on the client (server only shows an old unrelated asset still "being generated").
- Screenshots: `GYM ARC/Screenshots/alter_art_1106/` - alters 1-20 front + back, the 4 tier VFX, transform burst, all 13 auras + the flare, head options, before/after ruby + granite, 2 phone low-end shots; `phone/` = 667x375 copies of all of them.
- Screenshots of bursts were taken with the effects slowed down (Studio-only) so the capture catches them.
- **FPS:** Studio runs at 15 fps while I remote-control it, with or without effects (same as earlier notes), so it can't show a difference: empty gym 15.0 fps, 5 bodies in Diamond + full auras 15.0 fps. 5-player test was 1 player + 4 clones (Studio can't start a multi-client test from here). **Needs a real phone check.**
- Not tested: real phone, 2+ real players, a real alter-up on a live save (the burst was fired by hand).

## 6. Owner
- Look at the screenshots; say if any alter needs another colour / scale pass (most likely: clay, amethyst, jade).
- File > Save to Roblox, then publish when you want it live.
- After publishing: one real-phone check of FPS with auras on.

![[GYM ARC/Screenshots/alter_art_1106/alter17_ruby_front.jpg]]
![[GYM ARC/Screenshots/alter_art_1106/alter10_obsidian_front.jpg]]
![[GYM ARC/Screenshots/alter_art_1106/aura11_galaxy.jpg]]
![[GYM ARC/Screenshots/alter_art_1106/aura_flare_levelup_golden.jpg]]

## Later, 6 Nov: no aura VFX under the feet (owner)
Owner: "in every aura, remove the vfx thats under ur foot".
- AuraVFX: the ground ring and the flare's ground ring are off for every aura (`GROUND_EFFECTS = false` at the top of the module; true brings them back).
- AuraPrestige: the tier-5 ground shockwave at the feet is off too.
- Kept: wisps, floaters, the flame loop on the body, and the flare's star + pillar. Tested in Play: 0 emitters at the feet, 0 errors.

![[GYM ARC/Screenshots/alter_art_1106/aura_no_ground_vfx_galaxy_flare.jpg]]

## Later, 6 Nov: AURA VFX FIX (black boxes + too much)
Owner's prompt "AURA VFX FIX". Owner answers: keep nothing under the feet (no ring); tiers = Common/Uncommon/Rare/Epic **low**, Legendary + Mythic **top** (no mid tier).

**1. Re-upload.** The owner rebuilt every texture in `Assets\vfx\auras`, `alters`, `titan` (clean transparent `_alpha`, pure black `_add`). 159 images re-uploaded to Myanmar Builders Club (+1 flat flare ring for the prestige halo). New ids in `Config/ArtIds` (alter VFX, aura wisp / particle / ring, flare, flame loop) and a new `ArtIds.Titan` (the 9 Titan textures, not used by the game yet). Table: [[2026-11-06 GYM ARC - Art ids (ChatGPT batch)]].

**2. Blending rule** (`_alpha` at LightEmission 0.2-0.4 + LightInfluence 0; `_add` only at LightEmission 1). Changed:
| Where | Before | Now |
|---|---|---|
| AuraVFX wisp / particle / flame | `_add` at 1 or 0.9 (flame), dark auras `_alpha` at 0 with LightInfluence 0.3 | `_alpha`, LightEmission 0.3, LightInfluence 0 |
| AuraVFX ground ring | `_add` at 0.5 for dark auras (the black square) | removed (owner) |
| AuraPrestige halo | `_add` flat ring at 1 | new flat `_alpha` ring at 0.3 (layer is off, see 3) |
| AlterLookClient solid things (clay, rock, coin, sweat, jade, amethyst, ruby) | `_alpha` at 0, LightInfluence 0.5 | `_alpha` at 0.3, LightInfluence 0 |
| AlterLookClient footstep puff | `_alpha` at 0, LightInfluence 0.6 | `_alpha` at 0.3, LightInfluence 0 |
Already OK, unchanged: alter glows, spark shower, transform burst, flare star / pillar, Peak's gold dust, prestige motes (`_add` at 1). No UI, Beam, BillboardGui or Decal uses these textures (the only ImageLabels are invisible preloaders).

**3. Toned down (AuraVFX v5).**
- low: particles only, 2-3 a second. top: + wisp 1-2 a second + one flame-loop emitter 2-3 a second, both behind the body.
- Particles: Transparency 0.35 -> 1, Size 0.4-0.9 studs, Lifetime 1-1.6 s, from a box hugging the body (~0.75 stud out) from the feet to the shoulders, never at the face.
- Flare (record / full pump / equipping): star + pillar, unchanged size.
- Others x0.5, past 60 studs off, phones / low graphics (LowEnd: phones, tablets and slow PCs) x0.5 again. Reduced Motion: no aura particles and no flare (the rule said "ring only" and the ring is off).
- **The prestige layer (orbs, motes, halo, light pillar, from 4 Nov) is off**: it was outside the per-tier budget. One switch in AuraClient (`PRESTIGE_LAYER`) brings it back. The hard auras' own colours stay.

**4. Test.**
- Particles alive per player (rate x lifetime, own aura at full power): **before** Frost 39, Galaxy 48, Golden 48, Titan 54, Gemstone 57 (10-12 emitters). **After** low ~4 (1 emitter), top ~10 (3 emitters); another player's half; on a phone half again.
- FPS (Studio, PC): no aura 53 fps, 10 bodies with top auras 50 fps (~53 aura particles alive on a normal PC). 9 of the 10 were clones (Studio can't start a 10-player test from here). Real phone still to check.
- No black or hazy boxes on the light plaza floor or in the dark gym; the body and face stay readable. 0 script errors.
- Screenshots: `GYM ARC/Screenshots/aura_fix_1106/` (low Frost, low-Epic Galaxy, top Golden; dark gym + light plaza; front + side; the flare; phone low-end shots; `phone/` = 667x375 copies). The gym floors are all dark, so the light floor is the outdoor plaza.
- Note: the low auras are now very quiet (a few small floaters); top auras show most from the side (wisp + flame sit behind the body).

![[GYM ARC/Screenshots/aura_fix_1106/top_golden_light_front.jpg]]
![[GYM ARC/Screenshots/aura_fix_1106/top_golden_dark_side.jpg]]
