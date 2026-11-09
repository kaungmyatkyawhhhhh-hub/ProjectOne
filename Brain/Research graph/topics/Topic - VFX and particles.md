---
tags: [graph-topic/VFX_and_particles]
created: 2026-11-09
---
# VFX and particles
Research-graph topic (42 concepts). Back to [[00 BRAIN]] · [[Research graph - how to use]]

**Source notes:** [[Playbook notes - Visual effects]] · [[Playbook notes - Whole-game research (Oct 2026)]]

## ParticleEmitter
From [[Playbook notes - Visual effects]]
- Links: Playbook notes Roblox VFX for kids' simulators on cheap phones (references) · LightEmission (additive blending) (references) · LightInfluence default gotcha (Studio 1 vs Instance.new 0) (references) · ZOffset render-order layering (references) · Squash (particle stretch) (references) · ParticleOrientation modes (references) · Emit(n) burst on disabled emitter (references) · Drag and WindAffectsDrag (references) · TimeScale (particle hit-stop  slow-mo) (references) · Particle flipbooks (Grid layouts, max 30 fps, auto-off on low memory) (references) · Particle rate limit (400s per emitter, 100 on mobile) (references)

## Particle flipbooks (Grid layouts, max 30 fps, auto-off on low memory)
From [[Playbook notes - Visual effects]]
- Links: Texture memory by pixel count (512256 guidance) (conceptually_related_to) · Coin burst recipe (implements) · ParticleEmitter (references) · Particle limits (100s mobile, 20 s lifetime, flipbooks 30 fps) (references)

## Camera shake, FOV punch and hit-stop
From [[Playbook notes - Visual effects]]
- Links: Flash limit ~3 per second (photosensitivity) (references) · GuiService.ReducedMotionEnabled (references) · Game juice (Jonasson & Purho; Nijman) (conceptually_related_to)

## Emit(n) burst on disabled emitter
From [[Playbook notes - Visual effects]]
- Links: Coin burst recipe (implements) · Emitter pooling on Attachments (references) · ParticleEmitter (references)

## LightEmission (additive blending)
From [[Playbook notes - Visual effects]]
- Links: Aura recipe (implements) · Post-processing effects (Bloom, ColorCorrection, ColorGrading) (rationale_for) · ParticleEmitter (references)

## Particle rate limit (400s per emitter, 100 on mobile)
From [[Playbook notes - Visual effects]]
- Links: ParticleEmitter (references) · Cheap-phone particle budget (~300 alive on screen) (rationale_for) · Particle limits (100s mobile, 20 s lifetime, flipbooks 30 fps) (semantically_similar_to)

## GuiService.ReducedMotionEnabled
From [[Playbook notes - Visual effects]]
- Links: Camera shake, FOV punch and hit-stop (references) · Level-up recipe (references) · Accessibility settings (ReducedMotion, PreferredTextSize, PreferredTransparency) (references)

## Three-phase VFX timing (anticipation, impact, dissipation)
From [[Playbook notes - Visual effects]]
- Links: Squash (particle stretch) (references) · TimeScale (particle hit-stop  slow-mo) (references) · Game juice (Jonasson & Purho; Nijman) (semantically_similar_to)

## UIGradient shine (GUI Shine Module)
From [[Playbook notes - Visual effects]]
- Links: Rarity reveal  egg hatch recipe (implements) · ViewportFrame VFX limitations (rationale_for) · UI-layer VFX in top simulators (references)

## Cheap-phone particle budget (~300 alive on screen)
From [[Playbook notes - Visual effects]]
- Links: Overdraw  fill-rate cost of transparent particles (rationale_for) · Quality scaling via UserGameSettings.SavedQualityLevel (conceptually_related_to) · Particle rate limit (400s per emitter, 100 on mobile) (rationale_for)

## Coin burst recipe
From [[Playbook notes - Visual effects]]
- Links: Emit(n) burst on disabled emitter (implements) · Particle flipbooks (Grid layouts, max 30 fps, auto-off on low memory) (implements)

## Emitter pooling on Attachments
From [[Playbook notes - Visual effects]]
- Links: Emit(n) burst on disabled emitter (references) · Highlight (255 limit, first costs ~1 ms GPU on mobile) (references)

## Rarity reveal  egg hatch recipe
From [[Playbook notes - Visual effects]]
- Links: UIGradient shine (GUI Shine Module) (implements) · Rarity colour readability (paired with shapesize) (references)

## Level-up recipe
From [[Playbook notes - Visual effects]]
- Links: Beam (implements) · GuiService.ReducedMotionEnabled (references)

## Lighting.Technology superseded by LightingStyle + PrioritizeLightingQuality
From [[Playbook notes - Visual effects]]
- Links: Post-processing effects (Bloom, ColorCorrection, ColorGrading) (conceptually_related_to) · LightingStyle + PrioritizeLightingQuality (semantically_similar_to)

## Flash limit ~3 per second (photosensitivity)
From [[Playbook notes - Visual effects]]
- Links: Camera shake, FOV punch and hit-stop (references) · Photosensitivity limit (WCAG 2.3.1) (semantically_similar_to)

## Post-processing effects (Bloom, ColorCorrection, ColorGrading)
From [[Playbook notes - Visual effects]]
- Links: LightEmission (additive blending) (rationale_for) · Lighting.Technology superseded by LightingStyle + PrioritizeLightingQuality (conceptually_related_to)

## Rarity colour readability (paired with shapesize)
From [[Playbook notes - Visual effects]]
- Links: Rarity reveal  egg hatch recipe (references) · Rarity colour ladder (grey to gold + Mythic) (semantically_similar_to)

## Squash (particle stretch)
From [[Playbook notes - Visual effects]]
- Links: ParticleEmitter (references) · Three-phase VFX timing (anticipation, impact, dissipation) (references)

## Texture memory by pixel count (512256 guidance)
From [[Playbook notes - Visual effects]]
- Links: Grayscale textures tinted in-engine (conceptually_related_to) · Particle flipbooks (Grid layouts, max 30 fps, auto-off on low memory) (conceptually_related_to)

## TimeScale (particle hit-stop  slow-mo)
From [[Playbook notes - Visual effects]]
- Links: ParticleEmitter (references) · Three-phase VFX timing (anticipation, impact, dissipation) (references)

## ZOffset render-order layering
From [[Playbook notes - Visual effects]]
- Links: VisuallyFX 'Introduction to VFX Particles' (DevForum) (cites) · ParticleEmitter (references)

## Accessibility settings (ReducedMotion, PreferredTextSize, PreferredTransparency)
From [[Playbook notes - Whole-game research (Oct 2026)]]
- Links: Rarity colour ladder (grey to gold + Mythic) (conceptually_related_to) · GuiService.ReducedMotionEnabled (references)

## Game juice (Jonasson & Purho; Nijman)
From [[Playbook notes - Whole-game research (Oct 2026)]]
- Links: Three-phase VFX timing (anticipation, impact, dissipation) (semantically_similar_to) · Camera shake, FOV punch and hit-stop (conceptually_related_to)

## Particle limits (100s mobile, 20 s lifetime, flipbooks 30 fps)
From [[Playbook notes - Whole-game research (Oct 2026)]]
- Links: Particle flipbooks (Grid layouts, max 30 fps, auto-off on low memory) (references) · Particle rate limit (400s per emitter, 100 on mobile) (semantically_similar_to)

## Rarity colour ladder (grey to gold + Mythic)
From [[Playbook notes - Whole-game research (Oct 2026)]]
- Links: Accessibility settings (ReducedMotion, PreferredTextSize, PreferredTransparency) (conceptually_related_to) · Rarity colour readability (paired with shapesize) (semantically_similar_to)

## Playbook notes Roblox VFX for kids' simulators on cheap phones
From [[Playbook notes - Visual effects]]
- Links: Roblox 'Intro to VFX art' curriculum (cites) · ParticleEmitter (references)

## Aura recipe
From [[Playbook notes - Visual effects]]
- Links: LightEmission (additive blending) (implements)

## Beam
From [[Playbook notes - Visual effects]]
- Links: Level-up recipe (implements)

## Drag and WindAffectsDrag
From [[Playbook notes - Visual effects]]
- Links: ParticleEmitter (references)

## Grayscale textures tinted in-engine
From [[Playbook notes - Visual effects]]
- Links: Texture memory by pixel count (512256 guidance) (conceptually_related_to)

## Highlight (255 limit, first costs ~1 ms GPU on mobile)
From [[Playbook notes - Visual effects]]
- Links: Emitter pooling on Attachments (references)

## LightInfluence default gotcha (Studio 1 vs Instance.new 0)
From [[Playbook notes - Visual effects]]
- Links: ParticleEmitter (references)

## ParticleOrientation modes
From [[Playbook notes - Visual effects]]
- Links: ParticleEmitter (references)

## Overdraw  fill-rate cost of transparent particles
From [[Playbook notes - Visual effects]]
- Links: Cheap-phone particle budget (~300 alive on screen) (rationale_for)

## Quality scaling via UserGameSettings.SavedQualityLevel
From [[Playbook notes - Visual effects]]
- Links: Cheap-phone particle budget (~300 alive on screen) (conceptually_related_to)

## UI-layer VFX in top simulators
From [[Playbook notes - Visual effects]]
- Links: UIGradient shine (GUI Shine Module) (references)

## ViewportFrame VFX limitations
From [[Playbook notes - Visual effects]]
- Links: UIGradient shine (GUI Shine Module) (rationale_for)

## LightingStyle + PrioritizeLightingQuality
From [[Playbook notes - Whole-game research (Oct 2026)]]
- Links: Lighting.Technology superseded by LightingStyle + PrioritizeLightingQuality (semantically_similar_to)

## Photosensitivity limit (WCAG 2.3.1)
From [[Playbook notes - Whole-game research (Oct 2026)]]
- Links: Flash limit ~3 per second (photosensitivity) (semantically_similar_to)

## Roblox 'Intro to VFX art' curriculum
From [[Playbook notes - Visual effects]]
- Links: Playbook notes Roblox VFX for kids' simulators on cheap phones (cites)

## VisuallyFX 'Introduction to VFX Particles' (DevForum)
From [[Playbook notes - Visual effects]]
- Links: ZOffset render-order layering (cites)
