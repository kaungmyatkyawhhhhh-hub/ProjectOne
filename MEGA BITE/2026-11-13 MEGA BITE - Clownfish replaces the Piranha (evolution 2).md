# 2026-11-13 MEGA BITE - Clownfish replaces the Piranha (evolution 2)

Owner, 13 Nov 02:46: "my friend said piranha is ugly and we should replace with something else for the kids".

## Decision (research first, then decided)
- The Piranha was an angry red fish with a big underbite and teeth. For young kids it reads as ugly/scary, and its blue back blended into the water.
- What kids like: lists of the sea animals children know and love name dolphins, sharks, turtles, crabs, seahorses, starfish, clownfish and jellyfish (Jaques London, "Why children love ocean animals"). Hungry Shark World's own smallest playable tiers are small reef sharks (Blacktip Reef, Whitetip Reef; Pocket Gamer list).
- Evolution 2 has to be: bigger than the Minnow, smaller than the Barracuda, a chunky body (the rig, the clips and the Shop/Index fitting are tuned for a tall round fish), and it keeps the FRENZY ability.
- **Clownfish** fits all of that: every kid knows it, it lives on the reef, orange is the opposite of the blue water so it is easy to follow, and the white bands make it clearly different from the yellow Minnow and the golden treasure fish.
- Considered and dropped: baby shark (a shark at tier 2, then a Barracuda, then a Reef Shark breaks the ladder), pufferfish (already a food fish), parrotfish (pretty but kids do not know it), blue tang (blue on blue), lionfish (many spines = many triangles), anglerfish (same "ugly teeth" problem).
- Original design: a generic clownfish, not a film character (the prompt says so).

## Sheet
`Art\HSE_sheets\mb_hse_clownfish.png` (ChatGPT, one try, the Minnow sheet attached as the style image). Prompt = the hero prompt from the HSE rebuild note with: "a cute, brave, cheeky little hero fish that kids love at first sight: a small closed confident smile, no teeth showing, friendly determined eyes (brave, not angry, no frown). THE CREATURE: an original CLOWNFISH of your own design (do not copy any film or cartoon character): a chubby oval body about 1.6 times as long as it is tall ...; bright warm ORANGE body, slightly lighter orange belly; exactly THREE clean white vertical bands, each with a thin black edge ...; a big round eye with a dark brown iris; a rounded two-lobed orange dorsal fin with a thin black rim; a rounded paddle tail (not forked) ...; round paddle pectoral fins ...; small rounded pelvic and anal fins. No spots, no whiskers, no spikes."

## Model (FishKit v3, files in `Art\Clownfish_hse\`)
- `clownh_cfg.py` (food-fish template: no jaw, painted eye and smile; 8 spine bones at the old Piranha rig positions so `PiranhaClips` still drive it), `clownh_rig.json`, `clownh_clean.py`.
- **6,868 triangles** (the first build was 14,046; the Piranha was 17,710). `NR=30, NA=22, fin_step=13, fin_grid=18`.
- Same length as the Piranha (9.06 studs), a little wider (4.97 vs 4.23).
- New in the kit (`Art\FishKit_v3_hse\fishkit_v3b_bodysheet.py`, key `body_sheet`): the BODY colours can be sampled from a cleaned copy of the sheet. Needed because this fish has bands:
  1. the pectoral fin painted on the flank is removed by mirroring the paint above it (a blur smeared orange into the white band);
  2. the dorsal fin drawn lying on the back in the top view is removed the same way, so the back gets real scales and bands from the top view (`top_w=0.75`);
  3. the top view's bands are slid along x to where the side view puts them (the head band was 35 px further forward in the top view).
- Body top and bottom under the fins are measured from the sheet (`bridge_top`, `bridge_bot` with explicit rows).
- Palette: belly class = white, so in the skins the bands take the belly colour and the chin stays with the body.
- Check picture: `clownh_sheet_vs_model_and_skins.jpg`; owner picture `MEGA BITE - Clownfish check.jpg`.

## Roblox assets (all Approved)
| What | Id |
|---|---|
| Model (FBX) | 104310426694665 |
| Texture | 112335679990043 (the model in the game uses Roblox's copy from the FBX, 76442960437035) |
| Skin Coral | 89741413326187 |
| Skin Lantern | 132947040273399 |
| Skin Ghost | 102290849173803 |
| Skin Ember | 103866600456032 |

## Installed in Studio (not published)
- `MB_InstallV2("Piranha", 104310426694665)`: `ReplicatedStorage.MegaBite.Sharks.Piranha` is now the clownfish. **The key stays "Piranha"** (saves, clips, quest ids, analytics step) so nothing else had to change.
- `GameConfig`: evolution 2 `name = "Clownfish"`, quest text "Grow into a CLOWNFISH", `Store.SkinTex.Piranha` = the four new skins. `MB_HUD`: "NEXT: CLOWNFISH".
- Backups: `ServerStorage.MB_Piranha_HSE_backup_13Nov` (the model), `GameConfig_preClownfish_13Nov`, `MB_HUD_preClownfish_13Nov`. To go back: put the backup model in `Sharks` as `Piranha` and restore the two scripts.

## Checked
- Edit: the five looks lined up next to the Minnow and the Barracuda, all textured.
- Play as a new player, evolution 2: the HUD says the new name, the clownfish swims on the Piranha clips (spine bones move), no script errors.

## Not done / known
- It has no jaw bone: the mouth does not open on Bite and FRENZY (same as the Minnow). The bite VFX still plays. A jaw would need a sheet with the mouth parts and the biter template.
- The FRENZY button icon still shows a toothy orange fish.
- Not looked at: the Shop and Index 3D card, the evolve cutscene, a phone.
- Small paint flaws seen at sheet scale: a band kink under the pectoral fin and along the dorsal base.

Sources: https://www.jaqueslondon.co.uk/blogs/posts/why-children-love-ocean-animals , https://www.pocketgamer.com/hungry-shark-world/how-to-unlock-every-shark-in-hungry-shark-world-from-whitetip-to-great-white-to-/
