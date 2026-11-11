---
date: 2026-11-01
tags: [gymarc, alters, skins, vfx, art]
status: decided, for the 7 Nov / 14 Nov updates
---
# GYM ARC - make every alter skin look special (1 Nov night)

Owner: "we also need to make every alter skin look special because rn i feel like it all look the same, just different colors and materials".
Related: [[GYM ARC - Body Alters]], [[2026-10-29 GYM ARC Master plan - one ladder]] (Alter 8-9 wall: "only the skin changes, Stone skins grey/brown read as fur"), [[2026-11-01 GYM ARC Plan - Hall of Fame repeat value and alters 16-30]], [[2026-11-01 Supernova Incremental - VFX plan]] (anime transformation toolkit), [[2026-11-01 Research - Modeling like a professional (stylized low poly)]].

## Why they look the same
- Character-design rule (readability order): **silhouette first, then value / pattern, then colour last**. Every alter today changes only the LAST layer (colour map + normal + roughness on the same body). From 10 studs away, in a gym's lighting, Clay / Sandstone / Granite all read as "brown guy".
- Nothing moves, glows or sounds different: a transformation in anime = new shape + light + motion + sound, not a new paint.
Source: Rocketbrush, "Shape language in game character design" (rocketbrush.com/blog/shape-language-in-game-character-design-how-to-make-characters-readable-and-consistent).

## The rule: every alter gets 4 layers on top of its material
1. **SHAPE** (silhouette): 0-3 attached low-poly pieces from one reusable kit (rock chunks, plates, rivets, crystals, crown). Human tier has none (the body IS the fantasy); pieces start at Granite and grow through each tier, the tier finale (5, 10, 15, 20) has the most.
2. **LIGHT**: an emissive detail (thin Neon mesh lines / cracks, glowing eyes from Tier 2). Brightens while lifting / flexing.
3. **MOTION**: a small idle effect (max 8 particles per player) + a rep effect (on each rep).
4. **TOUCH**: own footstep (puff / print / crack, own sound) and a sound layer on the rep + the flex.

| # | Alter | Shape | Light | Motion (idle / rep) | Footstep |
|---|---|---|---|---|---|
| 1 | Pumped | - | red flush pulses on each rep | heat haze off the shoulders / steam puff | normal |
| 2 | Shredded | - | sharp striation highlight | sweat sheen / sweat flicks | normal |
| 3 | Tanned | - | gold shine sweeps over the body every 4 s | glints / oil shine flash | normal |
| 4 | Vascular | - | veins glow orange, pulse like a heartbeat | slow pulse / bright pulse | normal |
| 5 | Peak (finale) | - | gold rim light | spotlight dust / gold sparks | small gold dust |
| 6 | Clay | handprint smudges (decal) | eyes faint warm | wet drips / clay flecks | clay prints (fade 3 s) |
| 7 | Sandstone | worn layered bands on shoulders | eyes amber | sand trickles from elbows / sand burst | sand puffs |
| 8 | Granite | rock chunks on both shoulders | eyes white | grit falling / chips fly | ground crack decal + thud |
| 9 | Marble | laurel band on the head, carved edges | gold kintsugi veins glow | white dust / marble chips | stone tap |
| 10 | Obsidian (finale) | glass shards on shoulders + back | lava cracks glow orange | embers / lava flash | glowing cracks |
| 11 | Bronze | rivets + plate seams on chest/shoulders | eyes copper | none / clank sparks | metal clank |
| 12 | Iron | forged shoulder plates | seams glow hot after reps, cool down | sparks / forge flare | heavy clank |
| 13 | Steel | forearm + shoulder armour plates | blue-white seam lights | steam vents on the back / vent burst | hiss + clank |
| 14 | Chrome | smooth chrome collar | moving light glints | mirror ripple / liquid-metal ripple on flex | ring tone step |
| 15 | Gold (finale) | gold crown halo plate behind the head | sun-ray halo on flex | gold sparkles / coin glints | gold chime |
| 16 | Jade | carved jade cuffs | soft green inner glow | leaf-shaped jade flecks | soft chime |
| 17 | Ruby | red crystals on the shoulders | glowing heart core in the chest (heartbeat) | red glints / core flare | crystal tink |
| 18 | Sapphire | blue crystal spikes on the forearms | cold blue glow | frost mist / frost burst | frost print |
| 19 | Amethyst | bigger purple clusters on shoulders + back | violet glow | 3 floating shards orbit / shards spin | crystal tink |
| 20 | Diamond (finale) | crystal crown + clear crystal clusters | prism light, rainbow sparkle | refraction sparkles / prism beams on flex | diamond chime |

## Rules
- Pieces follow the muscles (scale with the body size; attach to the existing rig parts), never cover the face or block the muscles (the muscles are the game).
- **Performance**: one kit of ~20 meshes reused by every alter (colour from the alter); max 3 pieces + 8 idle particles per player; others beyond 60 studs = material only; Low graphics / phones under the LowEnd FPS line = material + pieces, no particles; ReducedMotion = no shakes.
- Variants (Inferno, Rose Gold...) keep their colour map; the pieces take the variant's colour.
- Gameplay stays the same: looks only. Statue stays marble.
- Settings toggle "Alter effects: All / Mine only / Off".
- Art by Claude Code (no AI image generation), textures imported to the group by the owner (group rule: SurfaceAppearance maps must belong to Myanmar Builders Club).

## Schedule (decided)
- **7 Nov:** Gem alters 16-20 launch with all 4 layers from day one (new content must feel special); alters 1-15 get the cheap layers (LIGHT, MOTION, TOUCH) = no new meshes.
- **14 Nov:** SHAPE pieces for alters 6-15 (with alters 21-30).
- Fallback order for the week stays: pacing fix -> Run Cards -> Star Track -> Alters 16-20 (+ their looks) -> the layers on 1-15. Anything not done moves to 14 Nov.
