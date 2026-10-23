---
date: 2026-10-22
tags: [gymarc, prompt]
status: done
---
# 44 Visible hex mesh

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
The hex mesh on tiles/panels is so tiny it's invisible in game. Fix it everywhere (streak tiles, reward tiles, nav tiles, panels):
- Use the texture C:\Users\kaung\Downloads\gym_arc_textures\hex_tile.png (seamless, white lines on transparent, 156x90). Upload it once and reuse it.
- ImageLabel over the tile background: ScaleType = Tile, TileSize = UDim2.fromOffset(52, 30) on normal tiles (about 3 hexes across a tile), UDim2.fromOffset(78, 45) on big panels. Never scale it with the tile (no Fit/Stretch) or it shrinks to nothing.
- Tint with ImageColor3 (tile/rarity colour or gold), ImageTransparency ~0.8 (visible but subtle), clipped by the tile's UICorner (ClipsDescendants on a rounded frame, or put it inside the CanvasGroup).
- Also in the streak: the gold day 4/7 tiles look muddy; brighten their background a bit and make the DNA token not dimmed on those tiles. The row is cut off at the left edge; keep the margins from prompt 42.
Screenshot of the streak and one other tiled screen at phone size.
```

## Done (22 Oct)
- Uploaded once: rbxassetid://117814833566275 (Theme.HexImage). Tiled at a fixed size everywhere: 52x30 tiles, 78x45 panels, 26x15 bars. Tinted: rarity / item colour on reward and item tiles, gold on nav tiles, the Store hero, the aura detail and DNA days, white elsewhere.
- ImageTransparency 0.65 on tiles, not 0.8: at 52x30 the 156x90 texture's lines come out about 1 px, and at 0.8 they vanished in the phone-size test. Panels stay quieter (0.86).
- Streak: brighter gold day 4 / 7 backgrounds, the DNA token never dimmed, the row 6 px in from each side (the glow and TODAY ring were clipped at the left edge).
- Code commit: see the git log ("Visible hex mesh (prompt 44)").

![[GYM ARC/Screenshots/hex44/streak_phone.jpg]]
![[GYM ARC/Screenshots/hex44/store_phone.jpg]]
