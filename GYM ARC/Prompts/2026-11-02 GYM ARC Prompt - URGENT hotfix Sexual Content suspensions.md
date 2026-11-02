---
date: 2026-11-02
tags: [gymarc, prompt, moderation, urgent]
status: done in Studio 2 Nov, owner to publish ([[2026-11-02 GYM ARC Hotfix - Sexual Content suspensions (clothes always on)]])
---
# Prompt: URGENT hotfix, players suspended for Sexual Content

Owner (2 Nov):

> GYM ARC URGENT HOTFIX: players get "Roblox suspended you from this game: Sexual Content - your avatar broke the rules". Happens to everyone. When you look through glass, everyone's shirt and pants disappear. Read GYM ARC\2026-11-02 GYM ARC Bug - players suspended for Sexual Content (avatar).md.
> 1) FIND: how the tank top and shorts are made on the muscle body (Shirt/Pants, meshes, textures, decals, SurfaceAppearance) and every way they can be see-through: Transparency > 0, LocalTransparencyModifier (WorldLodClient / NoHalfFade / camera scripts), alpha textures. List every part with Material = Glass in the map.
> 2) CLOTHES ALWAYS SOLID: shorts and tank top are real opaque geometry on the body (Transparency exactly 0, no alpha, never touched by any LocalTransparencyModifier script), shorts cover hips to mid-thigh front and back, tank top covers chest and back. No skin colour anywhere between waist and mid-thigh. Remove/flatten any glute or crotch muscle bulge shapes.
> 3) GLASS: Glass material hides transparent parts behind it. Change every window from Glass to SmoothPlastic (or Neon frame + SmoothPlastic pane) with Transparency ~0.4 and a light blue tint, so nothing behind it disappears.
> 4) NO SHIRTLESS for now: every player, NPC, trainer, statue (Hall of Fame), cutscene and mirror shows the tank top. Hide the MINE/shirtless option (keep the code behind a config switch, off).
> 5) TEST: Play as a player with a normal avatar and with an avatar that has no shirt/pants: look at them from every gym's windows, from outside, close and far, at night; phone too. Screenshots of each window view. Then publish right away (live players from ads).
> 6) Progress note in GYM ARC\Progress\ with what made the clothes disappear.

Bug note: [[2026-11-02 GYM ARC Bug - players suspended for Sexual Content (avatar)]].
