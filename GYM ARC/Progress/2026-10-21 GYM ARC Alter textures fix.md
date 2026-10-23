---
date: 2026-10-21
tags: [gymarc, progress]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-21 GYM ARC Alter textures fix

Prompt: [[2026-10-21 GYM ARC Prompt - 38 Alter textures not showing]]. Bug note (the full check, IDs, causes): [[GYM ARC - Bug - Alter textures only change color]].

## Done
- The alter maps were on every body part and loaded; the detail was just drawn too big and soft (one texture over 10-14 studs of body). New Shredded / Vascular / Peak maps (smaller striations, stronger veins and bumps) uploaded and set.
- Body updates can't drop the alter skin any more (skin pass on every new piece + every 2 s), and alter maps are really preloaded now.
- Also done (owner, same session): **on a machine the hotbar hides and the item is put away** (client and server; taking an item out on a machine is blocked, and you can't drink there); it comes back when you get off. Tested: holding a shake -> on the Flat Bench: hands empty, hotbar hidden, equip blocked -> off: hotbar back.

![[GYM ARC/Screenshots/alters/alters_side_by_side.jpg]]

## Owner's answers: bronze tan + head color ([[2026-10-21 GYM ARC Prompt - 38b Bronze tan and head color]]) - done
- **Tanned and Peak are a deep bronze now.** Their color maps are orange-brown, so times a light skin they came out orange-red (and a dark skin muddy). Their tint is now worked out from the skin (`Alters.TanColor` / `Alters.Tint`, numbers in `Alters.Tan`): hue moved toward bronze (31 deg), saturation kept 0.36-0.50, a light skin darkened to 60%, a dark one only to 84%. Light skin = warm bronze; dark skin = a bit deeper and glossier, not redder. Pumped / Shredded / Vascular keep the plain skin tint. The Alters tab and Looks swatches use the same tint.
- **The head follows the alter.** With an alter worn the head wears no alter maps; its Color becomes the body's average alter tone (`Alters.PlainSkin`: the alter map's average x its tint, over the plain skin's), so the face (its own SurfaceAppearance / decal) stays as it is. Back to Natural: the original head color and the normal skin stage come back. The elbow / knee balls and the flat skin shown under a training tint use the same alter tone.
- Forearm / calf stage meshes: their skin tint followed their part color (the plain skin), now converted to the alter's tint.
- **Found and fixed on the way:** the prompt 38 "preload every skin map" step errored in game (a game script can't read a SurfaceAppearance's map ids) and preloaded nothing; it takes the ids from the configs now. And Peak's normal map (74285776621086) never loaded in game (its bumps were missing); re-uploaded as 99012039750322, which loads. All 30 skin maps load now.
- Tested in Studio (my client only, your save unchanged): light skin (your own) and a dark skin (105, 64, 40), Natural / Tanned / Peak, outdoors. Head color matches; Natural brings the original head color back. No errors.

![[GYM ARC/Screenshots/alters/alters_bronze_light_dark.jpg]]

## Needs the owner
- Your own avatar's face is a **Face accessory** ("7", an opaque head-shaped mesh with the skin baked into its texture). A script can't tint that, so on your avatar the face stays its own skin color with an alter (the head under it is tinted). Normal heads (a face decal or a dynamic head) tint fine. The screenshot uses a plain face decal on my test client to show a normal head.
