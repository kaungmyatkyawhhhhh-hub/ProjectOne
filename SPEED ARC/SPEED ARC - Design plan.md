---
date: 2026-10-28
tags: [speedarc, design]
status: living document
---
# SPEED ARC - Design plan

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

## The idea in one line
Start as the slowest kid on the school track. Train, race, and get faster until you win the World Games.

## Core loop (every few minutes)
1. **Train**: tap on training spots (treadmill, sprint lane, hurdles, stairs) to gain SPEED. Each spot gives more speed the further you get.
2. **Race**: every 3 minutes a live race starts in your league (about 30 s). Your SPEED decides how fast you run; tapping during the race gives small boost bursts. Everyone on the server races together.
3. **Earn**: coins and medals for your place (1st / 2nd / 3rd + everyone who finishes).
4. **Spend**: shoes (main speed upgrade), coaches (rolled with coins, give boosts), trails (look + small boost).
5. **Go Pro** (rebirth): reach the league goal, move to the next league. Speed resets, you keep coaches/trails/shoes' looks, and get a permanent multiplier. Each run is faster.

## How speed works (keep it simple and fair)
- One main stat: **SPEED**, shown as MPH. Walking speed in the hub grows slowly and is capped, so the hub stays easy to control.
- In races, SPEED sets your race pace on a fixed-length track, so races always take about 30 s no matter how fast players are. Faster players simply finish first and further ahead.
- Small secondary stats later (stamina for longer boosts, jump for hurdles), only if they make races more fun.

## Leagues (each is its own small area you teleport to)
| League | Place | Unlock |
|---|---|---|
| 1 | School Track | start |
| 2 | City Park Run | Go Pro 1 |
| 3 | Big Stadium | Go Pro 2 |
| 4 | Mountain Trail | Go Pro 3 |
| 5 | World Games | Go Pro 4 |
Each league: one training area + one race track + a small hub piece. Later leagues = heavier training, longer tracks, better rewards.

## Things to collect
- **Shoes**: bought with coins, each pair adds speed and looks different (worn sneakers -> spikes -> carbon racers -> golden shoes).
- **Coaches**: rolled with coins (like GYM ARC trainers): rarities, boosts, follow you, evolve with duplicates.
- **Trails**: the effect behind you when you run (dust, fire, lightning, rainbow, stars). Mostly cosmetic + a small boost.
- **Medals and titles**: shown on your profile.

## Retention (reuse from GYM ARC, it works)
Daily streak, playtime gifts, daily quests, codes, profiles, weekly leaderboards (fastest race time per league), friend boost, invite boost, a weekly event (Relay Weekend, Hurdle Week...).

## Monetization (fair, no paid random rewards)
Passes: 2x Speed, Auto Train, VIP, Extra Coach Slot, Trail Pack. Products: coin packs (scale with league), Starter Pack, boosts. Coaches only from coin rolls.

## SOUND RULE (owner)
Sound quality is a core feature: it makes players feel the speed and the rewards. Every action gets a designed, layered sound before it counts as done; every milestone has a sound pass. Details: [[SPEED ARC - Audio (SFX and Music)]].

## PERFORMANCE RULES (the most important part)
- **Target: 60 FPS on cheap phones.** Check FPS + memory after every prompt.
- **Low-poly, bright, flat colours.** Few textures, no realistic materials.
- **Small separate areas** (hub, training, each track) with teleports, not one giant open map. StreamingEnabled with a small radius.
- **Few lights:** the sun + Neon parts. No shadows from props. Max ~20 lights per area.
- **Characters stay simple:** normal Roblox avatars. Progress shows through shoes, trails, effects and size of effects, never through live meshes on the body.
- **Particles:** small counts, fewer on low graphics, other players' trails simplified when far.
- **Part budget:** each area under ~3,000 parts; merge static decoration into meshes.
- **Scripts:** nothing runs every frame unless it must; no objects created per tap without pooling/cleanup.
- **UI:** clean and simple, few animations at once.


## ART QUALITY RULES (light on devices, but it must look PREMIUM, never cheap or "AI slop")
Owner, 28 Oct: "easy-going for devices but it gotta look quality".
- **One clear art style:** stylized low-poly, like a polished cartoon sports game. Clean shapes, strong silhouettes, chunky rounded edges, no default Roblox plastic/studs look, no random free models.
- **One colour palette** in Config (black, electric blue, gold, white: see the GDD section 3) used everywhere: world, UI, effects. Every area has its own accent colour but follows the palette.
- **Hand-made Blender meshes** for everything important (track, bleachers, trees, buildings, props): low-poly but well shaped, bevelled edges, vertex colours / gradients instead of big textures, baked soft shading (ambient occlusion) in vertex colours so it looks lit without real lights.
- **Lighting that does the heavy lifting cheaply:** a tuned Atmosphere + sky, a soft ColorCorrection, light Bloom, sun angle chosen per area, Neon for glow instead of many lights.
- **Details that make it feel real:** painted track lines, lane numbers, banners, flags that wave, crowds as simple animated silhouettes/sprites, birds, clouds moving. Cheap but alive.
- **UI made properly:** custom icons (not emoji or generic clip art), consistent spacing, real hierarchy, smooth animations, satisfying sounds. Same quality bar as GYM ARC's best screens.
- **Effects:** few particles but well designed (custom textures, good colours, speed lines, trails with gradients).
- **Quality check every milestone:** screenshots from the player's view at phone size; if anything looks generic, placeholder or messy, fix it before moving on.

## What we reuse from GYM ARC (copy, never change GYM ARC)
UI kit (black + gold, adapted colours), data saving, monetization/receipts, trainers -> coaches, daily rewards, playtime gifts, codes, profiles, admin console, analytics, unlock guides, settings.

## Milestones
1. **Core loop**: hub, School Track training + race, SPEED, coins, saving. (Prompt 1)
2. **Shoes, trails, coaches.**
3. **Leagues 2-3 + Go Pro.**
4. **Retention + monetization** (daily, gifts, codes, passes, starter pack).
5. **Polish + soft launch**, watch the first 15 minutes and day-1 return.

## Open questions for the owner
- Name: DECIDED, SPEED ARC.
- Colour theme: DECIDED black + blue + gold (see the GDD).
