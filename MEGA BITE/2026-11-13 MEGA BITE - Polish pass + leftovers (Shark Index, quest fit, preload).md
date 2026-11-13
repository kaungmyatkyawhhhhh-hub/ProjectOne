---
tags: [mega-bite, ui, polish, build-log]
date: 2026-11-13
---
# MEGA BITE - Polish pass + leftovers (13 Nov, owner AFK)

Owner 15:35: "do 3,4,5 and then 1,2 and then 6 at last. no questions" (3 = 3D on six sharks, 4 = polish, 5 = leftovers).
The friends never said WHAT to polish, so I played through every screen (HUD, Shop, Index, Settings, spawn view, every
evolution) as a picky kid and fixed what a kid would notice. Earlier the same day: [[2026-11-13 MEGA BITE - 3D relief on all player sharks + Minnow front]].

## Polish (found in my play-through, all fixed in Studio)
| What a kid saw | Fix | Where |
|---|---|---|
| The quest "EAT 5 FISH IN A FEEDING FRENZY" ran past the edge of the NEXT UP card | the line scales down to fit (max 18, min 9) | `MB_HUD` qLine |
| A newly evolved shark was pitch black for a second (its texture was still loading) | every shark's mesh + texture preloads 4 s after joining | new `StarterPlayerScripts.MB_Preload` |
| The KRAKEN SATURDAY sign sat in the middle of the first view, over the shark | moved ahead and up (spawn + (0, 38, -60)), a bit bigger so its second line reads | `MB_UpdateSign` |
| A Great White saw MEGALODON twice in the right column (next shark + the locked Fossilize tile) | the locked tile is labelled FOSSILIZE (tap: "unlocks at MEGALODON") | `MB_HUD` itFossil |
| "Eat 27 fish in the OPEN SEA" for a Megalodon in the Titan Sea (it counts every fish past the reef) | loop quest text "Eat %d fish out in the SEA" | `GameConfig` quest loop |

Skin preloading was tried and taken out: brand-new image ids only print "no content representation" warnings until the
CDN has them (they load fine on first use).

## Leftovers
- **Minnow's dark line on the back:** gone with the rebuilt Minnow (checked in the top view).
- **Quest text for Titan Sea fish:** done (above).
- **Tier rooms in the Index = the SHARKS tab (built):** FISH / SHARKS tabs (`K.Tabs`) on top of the Index window. The Shark
  Index shows every evolution in tier bands: REEF (teal: Minnow, Clownfish, Barracuda), OPEN SEA (blue: Reef Shark,
  Hammerhead), APEX (gold: Great White, Megalodon), ANCIENT (purple: Dunkleosteus and the next ones). Grown = full colour +
  tick, you = gold edge, next = dark shape "NEXT · 160K EXP", later = dark shape + padlock. A bar "7/8 GROWN", a hint line
  "Next: DUNKLEOSTEUS at 160K EXP". Tapping a shark shows it on the 3D hero card (ability, grows at, lives in). It reads
  `C.Evolutions`, so the Mosasaurus and Leviathan appear by themselves. Tested in Play, 0 errors.
- Backups: `MB_HUD_prePolish_13Nov`, `MB_UpdateSign_prePolish_13Nov`, `MB_Index_preSharkTab_13Nov`, `GameConfig_preQuestText_13Nov`.
