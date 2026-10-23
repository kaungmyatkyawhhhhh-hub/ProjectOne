---
date: 2026-10-22
tags: [gymarc, config]
status: check
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# GYM ARC - Uploaded images (21-22 Oct)

**Owner rules (22 Oct, after a warning for 94284470299221 and a 1-day ban for 92067653704245):**
- Never upload an image that shows a body, torso, skin or a character's figure.
- Before uploading ANY image, Claude says what it shows and waits for the owner's OK.
- Never use 94284470299221, 71823894969577 or 92067653704245.

Claude can't archive or delete assets: Creator Dashboard > Creations > Development Items > Images (and Decals) > Archive.

## ARCHIVE these (they show a body / character figure)
| ID | What it shows | Still used? |
|---|---|---|
| 92067653704245 | alter_bodies\vascular: shirtless chest-up body (the ban) | no |
| 134320459804351 | alter_bodies\natural: shirtless chest-up body | no |
| 121360002586660 | alter_bodies\pumped: shirtless chest-up body | no |
| 135100527736077 | alter_bodies\shredded: shirtless chest-up body | no |
| 137088818220143 | alter_bodies\tanned: shirtless chest-up body | no |
| 94284470299221 | old Aura Pack art, shirtless body (the warning; probably from the upload Claude stopped) | no |
| 71823894969577 | old Aura Pack art used in the Store, muscular body | no (removed 22 Oct) |
| 111996233150308, 133631360699790 | Coach Sam portrait + full body | no (removed 22 Oct, 3D rig now)* |
| 74140288375328, 103527138019682 | Coach Nia portrait + full body | no* |
| 129899333760066, 81355892884003 | Coach Lou portrait + full body | no* |
| 109521843426253, 83568357420697 | Coach Rex portrait + full body | no* |
| 135032054415213, 131905642086129 | Duke Ironside portrait + full body (bare arms) | no* |
| 96891532200424, 111446003430999, 119113066569801 | Volta portrait + full body (x2) (bare arms) | no* |
| 120093887679988, 75559340067116 | The Shadow portrait + full body | no* |
| 105948301268005, 128216581907404 | Atlas portrait + full body (bare marble body) | no* |
| 86466880073442, 129465909046082, 92192772625761, 92179967724810, 113681452937688, 114074076872071, 79347691775252, 91786313487049 | older trainer render icons (21 Oct, prompt 25) | no |
| 125829932471956, 138377614470876, 131053188064620, 122323729220125, 115748213011909, 129640648829938, 97574058899490, 75461569868523 | older trainer render full bodies (21 Oct, prompt 25) | no |
| 137156947592087 | trainer "???" black silhouette (a character figure) | no* |

\* removed in code on 22 Oct but NOT yet pushed to Studio (Studio disconnected): push before publishing.

## Skin textures (no body shape, but "skin": owner decides)
Flat skin-colour texture squares (colour / normal / roughness maps) the Body Alter skins are made of. **In use**: removing them breaks the Alters.
- In use: Pumped 118652537566937 / 77670612429230; Shredded 80449661881061 / 112368353705678 / 135284888816077; Tanned 124927923688709 / 95570134134448; Vascular 138226447249744 / 134369961190395 / 79671580983023; Peak 88467569632374 / 99012039750322 / 122443770392636.
- Not used (older copies): 93007598131259, 90002662702707, 119977506086729, 89167961578723, 134103429399150, 74285776621086, 119513312479015, 103766752198769, 103109392852988, 72861088552312, 128233798561844, 127999198166079, 89748828998136.
- Trainer marble skin (Atlas, in use): 105774110488913, 95563628937342, 136099375982457, 107405359147472.

## OK (no body)
- 96266064858389 three aura orbs (Aura Pack, in use) · 117814833566275 hex lines (in use) · 133971863105248 older hex lines (not used) · 88290636191617 DNA token coin (streak).
- 22 Oct transparent shop icons (no bodies, set in config, not yet in Studio): 2x Coins 139439539739456, 2x EXP 137970570833539, Auto Rep 130822231832547, Pet Slot 126251085640637, Extra Trainer 109848179089518, VIP 117186665302232, Coins L 137118465714551 / M 109576862777341 / S 72419777964449, DNA Token 79070513529244, Endless Stamina 110376857651697, Quest Reroll 83529030902372, Shake Bundle 134456065661684, Skip Growth Cooldown 117690663398784 (not used: no paid skips), Stamina Refill 74537571266013 (not used).
- 22 Oct aura orbs (no bodies, set in config, not yet in Studio): Ember 138073278679148, Frost 74261206142711, Storm 134283670005654, Golden 72969190443545, Titan 73997537236580, Inferno 125663321482602, Blood Moon 134602853072749, Void 72815742565724, Neon 135059066043320, Galaxy 99887350441472, Royal 85878618078587, Toxic 115598555521730, Shadow 131376115105796.
- 21 Oct Body Alter popup backgrounds (abstract: heartbeat, light streaks, sun rays, veins, gold mountain): 118148533402740, 121615053568328, 107568445227398, 120390420209329, 116089241327514; alter VFX textures (rim, ember dot, lightning, smoke, droplet, spark, ring, ground): 138347218007327, 76009392745145, 80590302550492, 113405238797101, 137490039482038, 82372237523631, 131893925782949, 74138882329945.

## Older (before 21 Oct) with a body: check too
- UI.MenuArt 124549460345839: the main menu / loading screen picture of a shirtless muscular orange character (15 Oct).
- UI.Trainers 123149177753009, 73804538355114, 100097169445664, 86536100657185: old trainer portraits (14 Oct), still preloaded on the loading screen and used as Coach Dex's fallback.
- Coach Dex in the tutorial box is a live 3D view (no picture), but if that fails it falls back to UI.Trainers trainer_exp (123149177753009).
- UI.MenuArt and UI.Trainers are still used: owner decides whether to replace them (the menu art is on the first screen everyone sees).
