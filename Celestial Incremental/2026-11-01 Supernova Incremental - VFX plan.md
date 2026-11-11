---
date: 2026-11-01
tags: [celestial, supernova, vfx, plan]
status: discussing
---
# Supernova Incremental - VFX plan (1 Nov night)

Owner: "so now we need to discuss our vfx". From [[Roblox Playbook - Game craft deep dive]] (4. VFX), [[Playbook notes - Visual effects]], [[2026-11-01 Research - Do cutscenes help, what makes a good one]] (CHI 2024: effects tied to YOUR success raise motivation; just making effects bigger lowered it), GYM ARC owner rule (no stock Roblox effects like Fire / ForceField: our own textures), [[2026-11-01 Supernova Incremental - Map plan]] (glow only on what matters).

## Rules
1. Every effect answers something the player DID or GOT (buy, milestone, Supernova, roll). No decorative effects running everywhere (today's world glows everywhere = noise).
2. Three beats: anticipation 0.1-0.3 s -> impact 1-3 frames bright -> fade 0.4-1 s. Big impact, short tail.
3. Bigger reward = bigger effect (escalation ladder), so the eye learns what matters.
4. Shape meaning: round + stars = reward; sharp shards = impact (the Supernova blast).
5. Colour meaning, same as UI: gold = Supernova / premium, cyan-white = stardust, violet = rare, rarity colours on Forge rolls.
6. Our own textures, hand-drawn as vectors (white on transparent, tinted by Color, LightEmission 1): star sparkle, soft glow dot, ring, streak, shard, smoke puff flipbook (4x4). No stock Fire / Sparkles / ForceField, no AI art.
7. Budget (cheap phone): <=300 particles alive on screen, <=100/s per emitter, small sizes before fewer particles, pooled emitters + Emit(n), far emitters off, 1 Highlight max, Reduced Motion = no shake / flash, max 3 white flashes a second.

## The effects
| Moment | Effect | Size |
|---|---|---|
| Income tick | none in the world; the HUD number counts up + a tiny pop every second | tiny |
| Buy a tree node | node lights, a star line draws to it, 8-12 sparkles | small |
| New body joins your system (asteroid..quasar) | a streak flies in from space, lands in orbit with a ring flash; bigger tier = bigger streak + ring | medium, grows by tier |
| x2 milestone (25 levels) | the body pulses, gold ring, "x2" pop | small-medium |
| Comet fly-by | long trail across the sky (Trail + glow head); click = burst of 16 stardust sparks into your pad | medium |
| Star Surge full (server) | the Core's rim turns gold, a slow wave rolls over the plaza for everyone | medium, shared |
| SUPERNOVA (yours) | anticipation: your system's bodies pull into the Core, the star swells and pulses, music to silence; impact: white flash, two shockwave rings across the plaza, shards out; fade: your rank appears over your head, shards fly into your HUD | biggest, ~5 s first time / 2 s after |
| Someone else's Supernova | the burst in the sky over their pad (small, no flash for you) | social |
| Star Forge roll | Common pop / Rare sparkle / Epic rays / Legendary+ beam + rarity rays + confetti, longer charge for rarer | ladder |
| Rank aura | 8-15 particles, rank colour, off past ~60 studs | persistent, small |
| Lost Stars | soft twinkle on the star (no big glow blob), quiet sparkle when found | small |

## World glow fix
- Remove the always-on glow on path tiles, lamps, mushrooms and the big Lost Star blobs.
- Persistent glow only on: the Core, your pad rim (gold), what's ready to press.

## "WOAHHH SO COOL" level (owner, 1 Nov night: "we need our vfx to be the best")
Researched 1 Nov: Keith Guerrette (80.lv, real-time VFX: composition, colour, shape, timing, follow-through, secondary motion; purpose first; layering for depth; performance is a constraint), VFX Apprentice "What is timing in VFX" (wind-up -> climax -> fall-off; crescendo = fast + slow elements together, each with its own job; faster than ~60 BPM = aggressive, slower = calm; block in timing with simple shapes first; the goal is satisfaction), RoWatcher "Why anime battlegrounds are taking over Roblox in 2026" (screen-filling "ultimates" are why players clip and share; ~10 s clips = free marketing).
### What makes the WOAH
1. **Contrast**: a calm world makes the big moment explode. Quiet before it (music out, world dims), then everything at once.
2. **Layers** (6-8 per hero effect, each its own job): core flash, light burst (one temporary light), 2 shockwave rings (fast), shards (fast), embers (slow), nebula cloud (slow, lingers), camera (FOV punch + short shake), UI (white flash + rays), sound.
3. **Fast + slow together**: rings and shards rip out fast while the nebula cloud blooms slowly and stays: it reads huge.
4. **Wind-up you can feel**: 1-2 s crescendo (bodies pulled in, the star pulses faster and faster, rumble rising), the player KNOWS something big is coming.
5. **Follow-through that leaves a mark**: after each Supernova the sky keeps a new nebula / your constellation lines get brighter: the world remembers it (progress others see).
6. **World scale, screen-filling**: the blast reaches the sky, the whole plaza is lit; clip-worthy in ~10 s (like anime "ultimates").
7. **Never the same twice**: colour and size change with your rank (Spark gold -> Pulsar blue -> Quasar rainbow), so the 20th Supernova still surprises.
8. **Others see it**: the burst over your pad for the whole server = everyone goes "woah" together.
### The 5 WOAH moments (hero effects, built first, best quality)
| Moment | Signature |
|---|---|
| First Supernova | full crescendo + blast + new nebula in the sky + rank lands over your head |
| Black Hole | the reverse: everything pulled IN, light bends (warping rings), silence, then a dark pulse |
| Quasar joins your system | twin beams shoot up into space from your pad, visible across the map |
| Star Forge Celestial roll | the sky turns, a falling star lands in the Forge, rainbow rays |
| Ring Nebula opens | a bridge of light builds across the void |
### How we make sure it's actually WOW
- Block in each effect's timing with simple shapes first, then add layers (VFX Apprentice).
- Record a 10 s clip of each; test question: "would a kid post this?" If not, it isn't done.
- Low-end phones: same timing, fewer particles (smaller size first); Reduced Motion: no shake / flash.
