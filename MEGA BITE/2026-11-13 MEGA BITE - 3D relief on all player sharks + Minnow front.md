---
tags: [mega-bite, art, fishkit, relief, build-log]
date: 2026-11-13
---
# MEGA BITE - 3D relief on all player sharks + the Minnow's front (13 Nov, owner AFK)

Owner 15:35: "the first evolution fish front looks funny too. do 3,4,5 and then 1,2 and then 6 at last. no questions".
Follows [[2026-11-13 MEGA BITE - 3D relief on player sharks (pilot on the Dunkleosteus)]].

## The Minnow's front
- What was funny: seen from the front it had TWO smiles (the side view's mouth wrapped round each cheek), a pinched "beak"
  crease at the nose and the white belly ran up to the nose tip. Cause: the kit's `front_box` was off to the left and too
  narrow (968..1238 instead of 1035..1360), and the front view was never used for paint (`front_w = 0`).
- Fix: the right front box, `front_w = 1.4`; the sheet's front view is cleaned first (`fixfront`: its eyes filled with the
  skin around them, the pelvic fins and the chin outline removed, so nothing smears); the eyeball dome raised 0.04 -> 0.075 so
  the big eyes bulge out and show from the front like on the sheet.
- Result: one centred smile under a round yellow muzzle, eyes at the sides, white belly below (checked in Blender and in Studio).
- Assets (Approved): model 109207817439667, texture 95082541061776, skins Coral 82557960387951, Lantern 80013489721080,
  Ghost 93594061352222, Ember 98065173126952. Backups: MB_Minnow_hse_relief_backup_13Nov, MB_Minnow_front_v3a_backup_13Nov.
- Vault: `Art\Minnow_hse\front_v3\` (cfg.py, rig.json, sheet_frontclean.png, views).

## Relief on the other six (Clownfish, Barracuda, Reef Shark, Hammerhead, Great White, Megalodon)
- Same relief step as the Dunkleosteus: x_from = -0.40 x length (head + front body; Clownfish -0.45), amp 0.010, wide 16,
  contrast 0.11, up 0.4, soft 3.5, jaw_k 0.35, end_fade 0.04, belly_rows 0.2.
- New in `fishbuild.py`: `side_only = [0.35, 0.75]` (relief only where the side view sees the surface: without it the snout's
  outline became a saw-tooth) and `skip_px` on each painted eye (the glowing eyes stayed clean).
- Triangles: first try 29-34K (too many, owner rule) -> lighter base mesh `NR=34, NA=26, fin_step=14, fin_grid=18`:
  Barracuda 17,980 / Reef Shark 18,046 / Hammerhead 18,710 / Great White 18,730 / Megalodon 18,838 / Clownfish ~11K.
- Clownfish also got the front fix (`fixfront.py` + new kit option `front_pow = 4`: only faces that look straight ahead take
  the front view, so the white face ring of the front view does not paint extra stripes on the cheeks).
- Installed with the new `ServerStorage.MB_Reinstall(KEY, modelId, texId, backupName)` (uses the CURRENT model as the
  template, parks the 11 Nov v1 backup, sets the texture). Backups `MB_<KEY>_preRelief_backup_13Nov`; GameConfig backup
  `GameConfig_preRelief6_13Nov`; SkinTex lines keep the old ids in a comment.
- Checked in Play: every evolution 2-7 spawns with the new model and texture; 0 errors.

| Shark | Model | Texture | Coral | Lantern | Ghost | Ember |
|---|---|---|---|---|---|---|
| Clownfish (Piranha key) | 108495866826428 | 113504433067486 | 110976244684845 | 74385196650519 | 70598051229968 | 98895299603020 |
| Barracuda | 101273344944415 | 90395502732071 | 110747914491988 | 89122225317826 | 108097149882328 | 120529174134187 |
| Reef Shark | 127323407638833 | 139902637491688 | 118735578077458 | 72051790896190 | 132971672468448 | 87819521552976 |
| Hammerhead | 83116494963994 | 127261169800962 | 80103688023453 | 134949315209083 | 135782722157157 | 138148667088526 |
| Great White | 98734994353495 | 91969056810542 | 91589738996014 | 122695288153251 | 116272346756692 | 136821592153750 |
| Megalodon | 71425818249139 | 116402184692651 | 116712491859333 | 86652665281556 | 87357358783702 | 83859466035476 |

Vault: `Art\Relief_13Nov\<Shark>\` (fbx, tex, skins, cfg.py, rig.json, views, skins sheets) and the kit files.

## Seen while testing (for the polish pass)
- A newly evolved shark is pitch black for a moment while its texture loads (Great White, Clownfish) -> preload all shark
  textures when a player joins.
