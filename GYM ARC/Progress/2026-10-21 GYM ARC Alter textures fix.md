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

## Needs the owner
- Tanned is a strong orange-red on a light skin; tone it down?
- The head keeps the avatar's own skin with every alter (its face lives in it).
