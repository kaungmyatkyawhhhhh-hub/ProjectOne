---
tags: [gymarc, feature]
status: built
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# GYM ARC - Body Alters

The endless progression after 7'0" (owner's [[2026-10-20 GYM ARC Gameplay plan]], prompt 21, built 21 Oct). Progress: [[2026-10-21 GYM ARC Body alters]].

## How it works
- **Ladder:** 30 alters in 6 tiers of 5 (Human, Stone, Metal, Gem, Elements, Legend). Alter 0 = Natural (the normal skin stages). Tiers 1-3 have textures (Tier 1 Pumped..Peak; Tier 2 Stone and Tier 3 Metal since 26 Oct); Tiers 4-6 show "Coming soon" and can't be reached yet.
- **Goal:** at 7'0", every muscle group at a level, like a Growth Spurt goal: alter 1 = 205, then +25 per alter (24 Oct; was 95, +10).
- **Doing it:** BODY ALTER READY popup (also on a machine) with ALTER / Later; the player chooses when. Every muscle keeps 25% of its EXP, height stays, the new skin goes on, gains bonus +15% per alter (stacking, outside the gains cap). A camera / flash / "ALTER 3: TANNED" moment.
- **Safety:** the save is written before the alter (if it fails nothing changes) and again right after. Old 7'0" saves start at Natural with their muscles.
- **Tier reward** (every 5th alter): a title (Peak Human, Stone Cold, Heavy Metal, Crown Jewel, Force of Nature, Living Legend), an aura (placeholder looks) and DNA tokens (1/1/2/2/3/3).
- **Skin:** the alter's texture set replaces the skin stages at every muscle size, tinted with the player's skin color; on your live body and on the stage meshes other players see (MuscleRig, `ReplicatedStorage.SkinStages.Alter_<id>`). The statue stays marble.
- **Choose your skin:** Inventory > Alters: wear any unlocked alter; the bonus is always the highest alter's.
- **PUMP SHOP > Alters:** the alters of your tier with their state, the next one's goal and bonus, ALTER NOW when ready, MY SKINS. Nothing is sold (no coin or Robux cost).
- **Best physique:** the biggest body ever (Growth Spurts, then EXP) is saved; the Total / group boards and the statue use it, so an alter never makes them smaller.
- **Shows:** at 7'0" the posing divisions are Open (Natural) and one per alter tier; stage presence at 7'0" = 50% + the rest by alter number (of 30).
- **HUD:** the Growth Spurt card / machine strip become "NEXT: SHREDDED · 62% · Needs LEGS"; top bar "7'0" MAX · Alter 3 Tanned"; a small gold "ALTER 3" pill over the nametag.
  - (23 Oct, prompt 57; [[2026-10-23 GYM ARC Roll card side layout and NEXT pill outline]]) The NEXT pill's outline is the HUD cards' own (1.5 px) in the next alter's colour (no gold); READY = the ready glow (`Shared/UI/ReadyGlow`) in that colour. A dark alter art can get a lighter shade and a wash of its colour on the pill (`AlterThemes` `pillShade` / `pillWash`; SHREDDED has them).

## Popups and transformation (prompt 22, 21 Oct; [[2026-10-21 GYM ARC Unique alter popups]])
- **Every alter has its own theme** (`Config/AlterThemes`): background art (Tier 1, by the planner), accent, title gradient, intro, particles, sounds. Tiers 2-6 use colors only until their art comes (Stone thud + dust, Metal clang + sheen, Gem chime + prism, each Element its own sound and particles, Legend cosmic swell + rays); every alter has its own name colors.
- **BODY ALTER READY popup** (`Shared/UI/AlterPopup`): the screen dims with a vignette, letterbox bars, the music ducks, a riser; the panel slams in (sub boom + punch, shockwave ring, small shake), the name stamps in with sparks, then the theme's beat (Pumped heartbeat x2, Shredded slashes + wipe, Tanned rise, Vascular vein crackles, Peak spotlight + gold dust). While open: border pulse, title shine every 2.5 s, drifting particles, breathing ALTER button, soft hum. Tier finale: "TIER 1 COMPLETE".
- **Transformation** (`Shared/VFX/AlterFX`, ~3 s, tap to skip): camera close (picks a clear angle, never through walls), world darker, music muffled, heartbeat faster + swell, energy pulled into the body with an accent rim glow, 0.2 s silence, FLASH (boom + punch + sparkle + reverb, ground shockwave, particles, camera shake), the reveal chime (a step higher every alter) + the theme's sting + cheer + its screen effect, the body flexes (front double biceps, everyone sees it), the title card "ALTER 3: TANNED". The ALTER action goes to the server at the flash, so the new skin appears under the white.
- **Others nearby** (150 studs) see the flash, the ground shockwave and particles and hear a quieter 3D boom (no camera move).
- **Inventory > Alters and PUMP SHOP > Alters** cards have a strip of each alter's art (or colors) and a line in its accent.
- Sound ids: [[GYM ARC - Music and Sounds]]. Max ~40 particles at the peak, ~20 idle, half on low graphics; Reduced Motion: no shakes.

## Where it lives
- `Config/Alters` (all numbers), `PlayerData.Alter / EquipAlter / UpdateBest`, `ActionService` (Alter, EquipAlter), `BodyService.PublishData` (Alter, AlterNumber attributes), `Gains.PerRep` (bonus), `MuscleRig` (skin), `ProgressClient`, `Shared/UI/AltersPanel`, `PumpShopClient`, `TopBarClient`, `OverheadTitleClient`, `ShowOffService` (best physique), `PosingComp`, `Config/AlterThemes`, `Shared/UI/AlterPopup`, `Shared/VFX/AlterFX`, `Audio.Duck / Muffle`.
- Textures: `Downloads\gym_arc_alters\tier1_human`, uploaded 21 Oct (ids in Config/Alters). Skins built with `tools/builders/SkinStages` `BuildAlters()`.
- Pacing: `lune run tests/pacing alters`. Tests: `tests/alters`.

## Adding a tier
1. Upload its 15 maps, put the ids in Config/Alters `textures`.
2. Run `BuildAlters()` in Studio (command bar).
3. Re-run `tests/pacing alters` and tune `FirstGoal` / `GoalPer`.

![[GYM ARC/Screenshots/alters/tier1_preview.png]]

## Texture fix (21 Oct, prompt 38; [[GYM ARC - Bug - Alter textures only change color]])
- The body's UVs spread one texture over 10-14 studs, so Tier 1's detail came out too big and soft ("only the color changes"). Shredded and Peak maps now repeat 2x2 inside the image; Vascular keeps its scale with much stronger veins (`Downloads\gym_arc_alters\tier1_human_tiled`, ids in Config/Alters). Rule for new tiers: design detail for ~10-14 studs per texture (70-120 px per stud), thin lines need strong contrast.
- MuscleRig re-applies the skin on every new body piece and every 2 s, and preloads every skin map (ids from Config/SkinStages + Config/Alters).
![[GYM ARC/Screenshots/alters/alters_side_by_side.jpg]]

## Tint and head (21 Oct, prompt 38b)
- Each textured alter has `mean` (its color map's average). Tanned and Peak have `tone = "Tan"`: their tint comes from `Alters.TanColor(skin)` (a deep bronze, numbers in `Alters.Tan`) instead of the plain skin, so a light skin is warm bronze and a dark one a bit deeper. Others: the skin.
- `Alters.PlainSkin(id, skin)`: the plain color that matches the alter's body. The head (no alter maps on it), the elbow / knee balls and the flat skin under a training tint use it; Natural = the skin. The head's own color comes back on Natural (`NaturalColor` attribute while tinted).
- A Face accessory with the skin baked in can't be tinted (it keeps its color).
![[GYM ARC/Screenshots/alters/alters_bronze_light_dark.jpg]]

## Tier 1 takes 8 hours (24 Oct, owner)
- `Config/Alters`: FirstGoal 95 -> **205**, GoalPer 10 -> **25** (goals 205, 230, 255, 280, 305).
- Estimated times: alter 1 ~1 h 50, 2 ~1 h 15, 3 ~1 h 30, 4 ~1 h 40, 5 ~1 h 55 = **~8 h for all of Tier 1** (was ~1 h).
- Estimate from the EXP curve + the 21 Oct times, not a full sim. Rerun `tests/pacing alters` on the PC with the repo to confirm.
- Players already close to the old goal now need more levels (nothing lost).

## Taller per alter tier (24 Oct, owner)
- Every finished alter tier (5 alters) adds **4 inches**: Tier 1 done (Peak) = 7'4", Tier 2 = 7'8", ... Tier 6 = 9'0".
- `Config/GrowthSpurts.AlterTierInches = 4`, `AltersPerTier = 5`, `GrowthSpurts.PlayerHeight(data)` (Growth Spurt height + tiers from `data.alter.highest`).
- Used for the body (BodyService), top bar, menu, mirror, posing shows, titles, Tallest board. The statue / best physique still use the Growth Spurt height.

## Tiers 2 and 3 (26 Oct; [[2026-10-26 GYM ARC Endgame and first Growth Spurt pass]])
- Stone: Clay, Sandstone, Granite, Marble, Obsidian. Metal: Bronze, Iron, Steel, Chrome, Gold. Our own procedural maps (`tools/alter_textures.py`, `Downloads\gym_arc_alters\tier2_stone`, `tier3_metal`), metalness maps on Obsidian and the metals.
- `tone = "Raw"` in Config/Alters: their own colours, no skin tint (`Alters.Tint` = white). Popups use the tier colours (no background art yet).
- Pacing sim (`lune run tests/pacing alters 15`): Tier 1 ~2 h, Tier 2 ~2 h, Tier 3 ~2 h 40 of bot play. The 24 Oct "8 hours" was an estimate; the sim says ~2 h. Goals unchanged.

## Overhead ALTER pill styled (26 Oct, owner: "like the granite button")
- The "ALTER n" pill over the nametag looks like that alter's ALTER button in the BODY ALTER READY popup: the alter's accent with a darker bottom edge, a dark outline, white letters in the ALTER button's chunky font with a dark stroke, and a faint copy of the alter's popup background art, like the button. Your own is still smaller and faded. `OverheadTitleClient`.

## Popup backgrounds for alters 6-15 (26 Oct)
- Owner: Tier 1 has background art (popup, ALTER button texture, NEXT pill, overhead pill) and the new alters didn't. `tools/alter_backgrounds.py` draws 10 abstract 1200x480 backgrounds (glowing cracks, dunes, light shards, veins, glass shards, forge sparks, a hot seam, blades, mirror sweeps, a gold burst; no bodies, no text) into `Downloads\gym_arc_altersor_group_bg` for the owner to import to the group; then the ids go into Config/AlterThemes `bg` (themes 6-15).

## Alters about 27 min each with trainers (26 Oct; [[2026-10-26 GYM ARC First 15 minutes, deals, invites, memory]])
- Each alter has its own goal (`Alters.Goals`), tuned with trainers in the sim (`lune run tests/pacing tunealters`); alters 14-15 take longer (harder after about 8 hours of play).
- The overhead ALTER pill uses the NEXT card background (the alter art under a dark shade, its colour outline) and the ALTER button font.

## Skins v2 (27 Oct, owner: "do the alter skins")
- Looked at all 15 on max bodies: Iron, Obsidian, Clay, Sandstone and Granite read as fur (fine high-contrast normal noise); metals looked like clay; stone / metal skins had an orange skin-coloured head.
- Done: `Alters.RawPlain` (Config/Alters): stone / metal alters' head and plain parts take the skin's own average colour, not the player's skin. `Lighting.EnvironmentSpecularScale` 0.35 -> **0.7** (owner chose the middle): Chrome / Steel / Gold get real reflections.
- New maps for the 5 furry ones (`Downloads\gym_arc_alterslter_textures_v2.py` -> `v2\`): calmer, bigger shapes: Clay wide cracks, Sandstone smooth bands, Granite polished, Obsidian faceted glossy glass (no metalness), Iron forged with soft dents. Uploaded once (ids in this session's chat), but maps set on the SkinStages SurfaceAppearances by script rendered as flat colour in play, so it was put back to the v1 maps. Owner imports the v2 PNGs into the SurfaceAppearances himself, then Claude updates Config/Alters and checks.
- **Why Claude's uploads rendered grey:** they weren't owned by the group that owns the place; SurfaceAppearance maps must belong to the place's creator (Myanmar Builders Club). The owner imported the 16 v2 PNGs into the group (decals kept in `ServerStorage.AlterMapsV2_GroupImages`); each checked against the source PNG. Ids now in Config/Alters and the SkinStages SurfaceAppearances:
  - Clay 111377035465967 / 94434595808584 / 95510333365247; Sandstone 92399925894287 / 134089560150506 / 73529013070921; Granite 82803887369076 / 98831725213571 / 86557093389409; Obsidian 116060486444251 / 102861573559689 / 96472928361338 (no metalness); Iron 133443749485829 / 75095035934589 / 119090568302532 / metal 85492534663638 (color / normal / roughness).
- Rule for future textures: upload them to the group (owner), never with Claude's upload tool, if they go on SurfaceAppearances.

## Cutscene title font (27 Oct)
Owner: "during the cutscene the ALTER text needs the premium font". The transformation's title card ("ALTER 8: GRANITE", AlterFX) uses Montserrat Black Italic (`UIFonts.Display`, the REP / titles font) instead of Luckiest Guy; the popup and the trainer screens keep theirs. Shot `alter_title_premium_font.jpg`.

## Alter variants (27 Oct, prompt 76; [[2026-10-27 GYM ARC Alter variants]])
Owner: "add alter variants in some of the alters. and it will cost robux. in the halloween update theres gonna be a halloween variant for one out of all the alters".
- A variant is another look for an alter's skin: its own colour map on the base alter's normal / roughness / metalness maps. Look only (gains, the ALTER label and posing divisions stay your real alters). Bought once with Robux; you don't need to have reached the base alter.
- **Where:** Inventory > Looks > Alters, in the alter's detail: a row of round swatches (the alter's own skin first, then its variants; a lock on ones you don't own). Tap = preview on you for 6 s (your screen only). Button: WEAR / WORN, BUY R$ <price> (Roblox's purchase prompt), or SOON while the product id is 0. Wearing any alter takes the variant off.
- **Server:** developer products in `Config/Products` (Variant*), listed by `Config/Monetization` (store = false: not in the Store). `MonetizationService` grantProduct -> `PlayerData.GrantVariant` (once per PurchaseId, saved before granting, then worn). `ActionService` EquipVariant -> `PlayerData.EquipVariant` (only owned ones). `BodyService.PublishData` shows the worn variant's skin. Save: `data.alter.variants` (owned), `data.alter.variant` (worn); every alter write keeps them.
- **Config:** `Config/Alters.Variants` (id, base alter, name, `color` = the colour map id, `mean`, `plain`, product key, robux, `event`), `Alters.Events = { Halloween = false }`; helpers VariantsOf / OwnsVariant / WornVariant / VariantSkinName / VariantOnSale.
- **Skins:** `ServerStorage._Builders.VariantSkins` builds `ReplicatedStorage.SkinStages.Alter_<id>` (a copy of the base's SurfaceAppearance with the new colour map). A variant without its colour map doesn't show anywhere.
- **Halloween:** the Zombie variant (Vascular) is in the list with `event = "Halloween"`: it shows and sells only while `Alters.Events.Halloween = true`; owners keep it after.
- Studio test hooks: Workspace `TestReceipt` = "<productId>:<purchaseId>" (existing), new `TestRevokeVariant` = "<variant id>" (takes it away again and saves).

| Variant | Base alter | Look | Robux (suggested) | Product key | Status |
|---|---|---|---|---|---|
| Inferno | 1 Pumped | deep crimson, orange in the folds | 149 | VariantInferno | map + product needed |
| Frostbite | 2 Shredded | icy blue-white, frosty speckle | 149 | VariantFrostbite | map + product needed |
| Zombie (HALLOWEEN) | 4 Vascular | grey-green skin, dark blotches (no gore) | 199 | VariantZombie | map + product needed; on sale only while `Alters.Events.Halloween = true` |
| Black Marble | 9 Marble | black stone, gold veins | 249 | VariantBlackMarble | map + product needed |
| Patina | 11 Bronze | green verdigris over bronze | 199 | VariantPatina | map + product needed |
| Rose Gold | 15 Gold | pink gold | 299 | VariantRoseGold | map + product needed |

### To finish (owner)
1. Import the 6 colour maps from `Downloads\gym_arc_alters\variants\variant_<id>_color.png` to the group (Myanmar Builders Club) and send the ids. (Generated by `Downloads\gym_arc_alters\alter_variants.py`; preview `variants_preview.png`.)
2. Create 6 developer products on the Creator Hub (names / prices above, or your own) and send the ids.
3. Claude puts the ids in `Config/Alters` (`color`) and `Config/Products`, runs VariantSkins, and checks each on a body.

### Where they're sold (27 Oct; owner: "ok do all 3 of them")
1. **Store > SKINS tab** (new, after PASSES): a tile per variant on sale (a round swatch in its colour with the base alter's bicep), the card on the left with the Robux price + TRY ON (the skin on you for 6 s, your screen only). Owned: "WEAR IT" opens Inventory > Alters. A Halloween (event) variant goes first with a "HALLOWEEN · LIMITED" tag. No product id yet: SOON. The tab only appears once a variant has its skin. (`StoreClient`, isSkin entries)
2. **Inventory > Looks > Alters**: the swatch row in the alter's detail (wear / switch / buy).
3. **Coach Dex > ALTERS**: the same swatch row above the buttons; a picked variant's button is BUY R$ / WEAR / WORN / SOON (`AltersPanel` shop mode).
- Tested all three with a temporary Inferno (fake product id): the SKINS tab and card, TRY ON (on the body, back to Granite after 6 s), Coach Dex's row and BUY R$ 149. Test values removed after.
- (27 Oct) **Products created by the owner** and in `Config/Products` (checked with GetProductInfo, all for sale): Inferno 3722938194 (149), Frostbite 3722938311 (149), Zombie (Halloween) 3722938374 (199), Black Marble 3722938401 (249), Patina 3722938453 (199), Rose Gold 3722938509 (299).
- (27 Oct, owner: "the alter variant circle should have like a texture image to it") the circles (Inventory / Coach Dex) and the Store tile show a crop of the skin's own colour map (variant: its map; the first circle: the alter's own map) over its average colour.
- Still needed: the 6 colour map image ids (the owner imported them through the Asset Manager, which leaves nothing in the place to read).
- (27 Oct) **LIVE:** the owner's 6 colour map ids (matched by each image's average colour, read with EditableImage): Inferno 112680245482263, Frostbite 96466644672178, Zombie 130949710639595, Black Marble 115874328653239, Patina 75379110261738, Rose Gold 109857879721191. In `Config/Alters`; `VariantSkins` built the 6 SkinStages. Checked each on LuigiRED's body outdoors (all read well; Black Marble's gold veins and Rose Gold's shine show) and the Store SKINS tab (5 tiles with textured circles and Roblox prices; Zombie hidden until `Alters.Events.Halloween = true`).
