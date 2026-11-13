---
tags: [mega-bite, abilities, ui, vfx, build-log]
date: 2026-11-13
---
# MEGA BITE - Own abilities for evolutions 8-10 (13 Nov evening, owner AFK)

Owner 18:01: "do 3,4,5 and then 1,2 and then 6" - item 2 = the Dunkleosteus' own ability. Its BONE RAM borrowed the
Hammerhead's clip, gold VFX and button icon. The Mosasaurus and Leviathan also borrowed the Breach and Roar icons.

## What changed
- **Icons (ChatGPT sheet, one try; magenta keyed, cut, 256 px):** BONE RAM = armoured fish charging with a lime impact;
  SEA LUNGE = the Mosasaurus leaping out of a splash; INFERNO ROAR = the Leviathan's head roaring orange waves.
  Ids (Approved): BoneRam 124212372546700, SeaLunge 77737022872563, InfernoRoar 133682228634259.
  `UIKit.Icons` BoneRam / SeaLunge / InfernoRoar, `UIKit.AbilityIcon` points the three abilities at them.
  Files: `UI\icons_evo810\` (the ChatGPT sheet, the three icons, a dark/light preview).
- **Colour:** new `UIKit.Colors.Lime` (9BEA45); `AbilityColor["BONE RAM"] = "Lime"` (button bubble). The ram VFX reads the
  model's `MB_RamColour` (lime) and `MB_RamColour2`, so the Hammerhead keeps its gold.
- **The move:** `MB_Anim.DunkleosteusClips` - at the skull hit (0.36-0.62 s) the bone jaws snap open wide (up to 0.63 rad)
  and shut again, so BONE RAM is a ram AND a guillotine bite (real Dunkleosteus opened its jaws in a flash). The sound
  (BoneRam, hit at 0.42 s) already lines up.
- Sounds were already its own (BoneBite, BoneRam, EvolveAncient).

## Checked in Play
Dunkleosteus: lime button with the new icon, lime ram flash and crescents; Leviathan: INFERNO ROAR button with its icon.
0 errors. Test account EXP restored.

## Backups
`UIKit_preAbilityIcons_13Nov`, `GameConfig_preAbilityIcons_13Nov`, `DunkleosteusClips_preJawSnap_13Nov`.

![[boneram_lime.jpg]]
![[leviathan_button.jpg]]
