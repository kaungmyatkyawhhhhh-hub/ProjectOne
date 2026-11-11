# Modern Real-Time Game VFX (Stylised / Anime / Roblox): VFX Bible for the Shark Game

Scope note: these notes cover professional real-time VFX craft (Riot/League, stylised action games, fighting-game hit feel) and how to build each technique with Roblox's tools. Everything in "Cited Findings" has a source. Everything in "Inferences" is my synthesis or standard industry practice that I could not tie to a page fetched in this session, so treat the numbers there as starting values to tune, not as facts from a source. Kid-friendly throughout: no blood or gore. A bite reads through bubbles, white flashes, cartoon "chomp" shapes and screen punch, never through red liquid.

---

## Q1. What separates pro VFX from amateur VFX (timing, layering, silhouette, value contrast, motion)?

### Takeaway
Pro VFX is designed around **communication first** (what is it, what does it do, how big is it) and **timing first** (block it in with simple shapes, lock the rhythm, polish last). One clear primary shape, a controlled value range with a bright hot core, one dominant colour, short durations, and visual weight that matches gameplay weight. Amateur VFX does the opposite: lots of emitters at once, full-saturation colours, effects that linger, every effect equally loud, and texture detail that turns into noise.

### Cited Findings

**Communication and hierarchy (Riot / League of Legends)**
- Every effect should answer three questions: which ability this is, what it does, and how much impact it has. — [RealtimeVFX: Anatomy of a LoL missile pt 2](https://realtimevfx.com/t/anatomy-of-a-league-of-legends-missile-part-2-what-are-we-communicating-with-our-vfx/13062)
- Give each ability a unique visual signature that reads "at just a glance", and keep that signature when recolouring for skins. — [RealtimeVFX: Anatomy of a LoL missile pt 2](https://realtimevfx.com/t/anatomy-of-a-league-of-legends-missile-part-2-what-are-we-communicating-with-our-vfx/13062)
- Reuse a shared visual language for similar mechanics (e.g. roots = ring on the ground + rising cylinder). Use familiar conventions for status effects (stun, poison) instead of inventing new ones. — [RealtimeVFX: Anatomy of a LoL missile pt 2](https://realtimevfx.com/t/anatomy-of-a-league-of-legends-missile-part-2-what-are-we-communicating-with-our-vfx/13062)
- Shape language by function: heals are non-threatening in *form* as well as colour; knockups use strong vertical elements; shields use pulsing lines moving down the surface; damage-heavy spells use sharper shapes. — [RealtimeVFX: Anatomy of a LoL missile pt 2](https://realtimevfx.com/t/anatomy-of-a-league-of-legends-missile-part-2-what-are-we-communicating-with-our-vfx/13062)
- Riot designers rate each spell's importance 1 to 10, separately for the caster, allies and enemies. Crowd control (stuns, roots) deserves more visual weight than raw damage. "If everything is important, nothing is important." — [RealtimeVFX: Anatomy of a LoL missile pt 2](https://realtimevfx.com/t/anatomy-of-a-league-of-legends-missile-part-2-what-are-we-communicating-with-our-vfx/13062)
- Show info only to those who need it (Morgana's range circle is visible only to her and chained targets), which cuts team-fight clutter. — [RealtimeVFX: Anatomy of a LoL missile pt 2](https://realtimevfx.com/t/anatomy-of-a-league-of-legends-missile-part-2-what-are-we-communicating-with-our-vfx/13062)
- Riot's VFX update priorities: (1) fix gameplay issues, especially indicators that don't match the real hitbox; (2) readability and noise reduction, including removing very fine texture detail that makes effects look busy; (3) theme. Readability beats theme when they conflict. Spells also should not be too bright or too hard to see. — [League of Legends: Behind the scenes of VFX updates](https://www.leagueoflegends.com/en-us/news/dev/dev-behind-the-scenes-of-vfx-updates/)

**League VFX style guide, as summarised by VFX Apprentice**
- (1) One clear primary shape that shows the purpose at a glance; secondary elements support it through value and saturation. (2) Scale with importance: a basic hit must never look like an ultimate. (3) Avoid pure black and pure white; build mostly from mid values, and a wider value range on the effect draws focus. (4) Glow pushes contrast and can show power, direction and duration. (5) Higher saturation draws focus; avoid 0% and 100%. (6) Two complementary colours, one dominant and one secondary; follow conventions (heal green, frost blue, gunpowder orange-red). (7) Hand-painted shapes, mixing soft and hard, without stacking contradictory shapes. (8) Believable motion, with motion blur showing direction and power. (9) Anticipation, payoff on the expected beat, then time to process. (10) Keep effects short, because lingering effects clutter, signal false importance and hide other spells. — [VFX Apprentice: 10 LoL VFX design tips](https://www.vfxapprentice.com/blog/10-league-of-legends-vfx-design-tips)

**Timing (the "soul of effects")**
- Three-part structure: wind-up (anticipation), climax/spike, fall-off (dissipation). Instant effects skip anticipation but should still end gracefully by reducing intensity before vanishing. — [VFX Apprentice: What is timing in VFX](https://www.vfxapprentice.com/blog/the-soul-of-effects-what-is-timing-in-vfx)
- Tempo heuristic: rhythm faster than a heartbeat reads as aggressive; heals and positive effects should pulse slower, under 60 BPM. — [VFX Apprentice: What is timing in VFX](https://www.vfxapprentice.com/blog/the-soul-of-effects-what-is-timing-in-vfx)
- Effects are "impulse" (spikes) or "rhythm" (varying over time) and can mix: e.g. a fireball = rhythmic build-up, impulse cast, rhythmic travel, impulse hit. — [VFX Apprentice: What is timing in VFX](https://www.vfxapprentice.com/blog/the-soul-of-effects-what-is-timing-in-vfx)
- Workflow: sketch the *sounds* the effect would make, block in with simple shapes and tune timing until it feels good, only then add polish. Small curve-shape changes change perceived timing a lot. — [VFX Apprentice: What is timing in VFX](https://www.vfxapprentice.com/blog/the-soul-of-effects-what-is-timing-in-vfx)
- The article gives **no fixed phase ratios**; its example timing chart runs 0 to 48 frames. — [VFX Apprentice: What is timing in VFX](https://www.vfxapprentice.com/blog/the-soul-of-effects-what-is-timing-in-vfx)

**Shape / colour / motion staples (80.lv)**
- Shape, colour and motion are the three main levers; break each effect into elements and review each one separately. — [80.lv: VFX staples](https://80.lv/articles/vfx-staples-shape-color-and-motion/)
- At the climax use high saturation and max contrast; during dissipation drop to low contrast and low opacity. — [80.lv: VFX staples](https://80.lv/articles/vfx-staples-shape-color-and-motion/)
- Author grayscale textures and colour them through gradients so they can be reused; channel-pack (R = colour mask, G = emissive, B = alpha). — [80.lv: VFX staples](https://80.lv/articles/vfx-staples-shape-color-and-motion/)
- Phases: anticipation (fade-in, timed by design), climax (most elements visible), dissipation (kept brief). Drive transitions from gameplay events (HIT, END) so durations can change without breaking the effect. Make anticipation tunable (example: a meteor warning from 0.5 s to 2 s). — [80.lv: VFX staples](https://80.lv/articles/vfx-staples-shape-color-and-motion/)
- Per-element checklist: how important is it, how much attention should it draw, when does it appear and leave, how does it blend, does it add noise? Cut visuals when gameplay clarity needs it. — [80.lv: VFX staples](https://80.lv/articles/vfx-staples-shape-color-and-motion/)
- Prefer meshes with scrolling textures over particle systems where possible; add randomised events (e.g. lightning at irregular intervals). — [80.lv: VFX staples](https://80.lv/articles/vfx-staples-shape-color-and-motion/)

**VFX as game design (God of War Ragnarök / Halo Infinite)**
- Distinct muzzle-flash shapes identify a weapon from a distance; tracer trails show paths. — [Game Developer: VFX as game design tools](https://gamedeveloper.com/design/vfx-as-game-design-tools-the-ludology-of-vfx-in-god-of-war-ragnarok-and-halo-infinite)
- Each element type gets its own palette (Halo Kinetic = yellow-orange, Shock = pale to deep blue). When two categories share a hue (GoW Bifrost and Hex are both purple), separate them with hue shifts (indigo vs magenta) plus secondary accents. — [Game Developer: VFX as game design tools](https://gamedeveloper.com/design/vfx-as-game-design-tools-the-ludology-of-vfx-in-god-of-war-ragnarok-and-halo-infinite)
- Fast, snappy motion signals "volatile, about to go" (Fusion Coils leak fast before exploding). GoW's parry cue is a growing yellow circle, a consistent countdown for any enemy. — [Game Developer: VFX as game design tools](https://gamedeveloper.com/design/vfx-as-game-design-tools-the-ludology-of-vfx-in-god-of-war-ragnarok-and-halo-infinite)
- Explosions scale on a logarithmic curve (grow fast, then slow) so players have time to register the final size. Explosion particles approximate the real damage area. — [Game Developer: VFX as game design tools](https://gamedeveloper.com/design/vfx-as-game-design-tools-the-ludology-of-vfx-in-god-of-war-ragnarok-and-halo-infinite)
- Your own effects should rarely cover the crosshair or target. Core-mechanic VFX (e.g. Atreus's block shield) are tuned to stay visible in every lighting environment. Interactive objects get a tall glow and smoke to stand out from static geometry. — [Game Developer: VFX as game design tools](https://gamedeveloper.com/design/vfx-as-game-design-tools-the-ludology-of-vfx-in-god-of-war-ragnarok-and-halo-infinite)

**Hit-stop / impact freeze (Sakurai, Smash)**
- Hit-stop freezes attacker and defender for the same duration; stronger hits freeze longer; each attack can have its own modifier (sweet spots get more). Projectiles get less, electric attacks get more, and there is a hard cap regardless of damage. Multiplayer keeps it shorter because a third player can act during the freeze. — [Source Gaming: Sakurai on hitstop](https://sourcegaming.info/2015/11/11/thoughts-on-hitstop-sakurais-famitsu-column-vol-490-1/)
- During the freeze the victim vibrates (side to side on ground, up and down in air) and the attacker vibrates much less. Vibration starts large and shrinks, and scales with camera distance. Hurtboxes stay put. — [Source Gaming: Sakurai on hitstop](https://sourcegaming.info/2015/11/11/thoughts-on-hitstop-sakurais-famitsu-column-vol-490-1/)
- Smash Ultimate formula: hitlag frames = floor((damage x 0.65 + 6) x multipliers), with electric x1.5 and a 30-frame cap (Melee capped at 20). Example: a 15% hit gives 15 frames in Ultimate and 8 in Melee. — [SmashWiki: Hitlag](https://www.ssbwiki.com/Hitlag)

### Inferences
- **The 10-point "pro check"** for any effect in our game: (1) can a kid name it from a 1-second clip? (2) one primary shape? (3) one hero colour + white-hot core? (4) value contrast against the ocean background (dark blue water means bright, warm cores pop)? (5) anticipation, impact, dissipation all present? (6) dissipation shorter than it feels it should be? (7) size and brightness match gameplay importance? (8) no spot where 4+ transparent layers stack on screen? (9) does it still read on Low graphics on a phone? (10) does the sound land on the same frame as the impact?
- **Starting timing ratio** (industry rule of thumb, not from a fetched source): roughly 20-30% anticipation, a very fast impact (1-3 frames to peak at 60 fps), and 50-70% dissipation with an ease-out. Impact should be the fastest part. Applied in Roblox: a 0.6 s bite = ~0.15 s wind-up, ~0.03 s snap to full size, ~0.4 s fade.
- **Hit-stop for Roblox**, scaled from Smash's model: 0.03-0.05 s for light hits, 0.06-0.09 s for heavy hits, cap around 0.12-0.15 s, and smaller in crowded multiplayer servers (per Sakurai's free-for-all reasoning). Freeze the attacker's animation (AnimationTrack:AdjustSpeed(0)) and the victim's, and shake the victim model's visual offset rather than its hitbox. Only do it client-side for the local player's own hits, so other players' games never freeze.
- **"Amateur tells"** to avoid: rainbow or multi-hue effects with no dominant colour; constant-Rate emitters left on instead of `:Emit()` bursts; uniform size/transparency (no curves); effects with no fade-out (pop off); every hit using the same big explosion; pure-white or fully-saturated full-screen flashes; dense high-frequency noise textures that shimmer at distance.

### Gaps
- No fetched source gave exact frame ratios for anticipation:impact:dissipation; the ratios above are rule-of-thumb.
- The original 2017 League VFX style guide page now redirects to the LoL homepage; I used VFX Apprentice's summary.
- The GDC "Art Directing VFX for Stylized Games" (2017) page only lists the talk; content would have to be watched on GDC's YouTube.
- I did not reach a Genshin-specific VFX breakdown (searches only gave the GDC 2021 open-world art talk listing). Genshin's elemental colour coding (Pyro red-orange, Hydro blue, Electro purple, Cryo pale cyan, Anemo teal, Geo amber, Dendro green) is general knowledge, not sourced here.
- Gabriel Aguiar's tutorials are Unity/VFX Graph courses on Skillshare and itch.io (muzzle flash, portal, impact, meteor); I did not get their text content.

---

## Q2. Exact recipes: bite/chomp, shockwave/roar, dash/torpedo, ram, transformation/evolve, aura (rarity tiers), pickups, level-up, underwater ambience, plus camera work

### Takeaway
Every recipe follows the same skeleton: **anticipation (gather/charge) → impact (white-hot flash + primary shape + burst + camera punch + sound, all on the same frame) → dissipation (debris, rings and smoke fading out with low contrast)**. In Roblox each layer is a separate emitter or mesh, fired with `:Emit(n)` and driven by TweenService, so timing is controlled by script rather than by Rate. Underwater, bubbles replace sparks, and bright warm or white cores give contrast against blue water.

### Cited Findings
- A burst pattern on Roblox: call `Clear()` then `Emit(n)` with emitter `Enabled = false`; `Emit` defaults to 16 particles. — [Roblox ParticleEmitter API](https://create.roblox.com/docs/reference/engine/classes/ParticleEmitter)
- Layer order with ZOffset: higher ZOffset renders in front (explosion example: fire ZOffset 1 over smoke ZOffset 0). — [DevForum: Introduction to VFX: Particles](https://devforum.roblox.com/t/introduction-to-vfx-particles/2068650)
- `Squash` stretches particles over lifetime (positive = taller and thinner; e.g. 3 turns rain drops into streaks; use a negative value with Orientation `VelocityParallel`). Useful for speed lines and spark streaks. — [Roblox: Particle emitters](https://create.roblox.com/docs/effects/particle-emitters)
- Orientation options: FacingCamera, FacingCameraWorldUp, VelocityParallel, VelocityPerpendicular. VelocityPerpendicular lays a sprite flat across its travel direction (good for rings). — [Roblox: Particle emitters](https://create.roblox.com/docs/effects/particle-emitters)
- Shape options Box / Sphere / Cylinder / Disc, ShapeStyle Volume or Surface, ShapeInOut Inward / Outward / InAndOut. Sphere and Cylinder don't display correctly on an Attachment, so use a BasePart parent. — [Roblox: Particle emitters](https://create.roblox.com/docs/effects/particle-emitters)
- `ShapeInOut = Inward` gives particles that converge, which is the standard "gather/charge" anticipation. — [Roblox: Particle emitters](https://create.roblox.com/docs/effects/particle-emitters) (property behaviour); use as charge-up is my inference.
- Beams are cubic Bézier curves between two Attachments: CurveSize0/CurveSize1 place the control points along each attachment's X axis; Width0/Width1 taper (example 0.5 to 3); Transparency and Color accept sequences; FaceCamera keeps the beam facing the camera. — [Roblox: Beams](https://create.roblox.com/docs/effects/beams)
- Trails need two Attachments; their spacing sets width; lower Lifetime gives a shorter, snappier trail. FaceCamera prevents trails vanishing at some angles. Test at the lowest and highest Editor Quality Level. — [Roblox: Trails](https://create.roblox.com/docs/effects/trails)
- Core shader tricks used everywhere in stylised VFX: UV panning/scrolling, UV distortion, flow maps, radial distortion (ripples), dissolve/alpha erosion driven by noise, gradient mapping a grayscale texture, vertex offset, fresnel (edge glow, shields, foam), matcap (fake volume on mobile). — [RealtimeVFX: Bread and butter shader techniques](https://realtimevfx.com/t/most-common-bread-butter-shaders-and-materials-techniques/19127)
- Roblox auras: community practice is a mesh base animated through colour, size, rotation, transparency and Material, or cycling several Blender meshes by script; built-in Sparkles/Beams are seen as less unique. — [DevForum: How do y'all make auras](https://devforum.roblox.com/t/how-do-yall-make-auras/1383893)
- There is a commercial market for "RNG aura" VFX packs for Roblox (e.g. a 45+ aura pack, themed hero auras), showing auras are a recognised genre staple. — [BuiltByBit: 45+ Roblox RNG Aura VFX Pack](https://builtbybit.com/resources/45-rng-aura-vfx-pack-for-roblox-games.95527/)
- Water caustics in Roblox: make a black-and-white caustic texture transparent (Screen blend, example 800x800), put it on two perpendicular Beams widened into planes, and pan them. — [DevForum: Water caustics creation and tutorial](https://devforum.roblox.com/t/water-caustics-creation-and-tutorial/2842131)
- Beams don't render behind Glass or Water materials (and slightly transparent parts also fail behind water), so beam caustics vanish when viewed from inside Terrain water. Workaround: a tileable `Texture` on the floor with `OffsetStudsU/V` tweened. — [DevForum: Beams invisible under water](https://devforum.roblox.com/t/beams-invisible-under-water/3028094)
- Roblox changed underwater lighting so it matches lighting above the surface (previously Terrain WaterColor applied regardless). — [DevForum: Upcoming underwater lighting improvements](https://devforum.roblox.com/t/upcoming-underwater-lighting-improvements/865915/68)
- Camera shake should be tuned on amplitude, frequency and decay; "less shake can sometimes read stronger"; match intensity to damage tier. — [GamineAI: Combat feel resources 2026](https://gamineai.com/resources/20-free-combat-feel-and-juice-resources-hitstop-screenshake-vfx-timing-2026-edition)

### Inferences (recipes; values are starting points to tune in Studio)

**Universal layer stack (use for every hit)**
1. *Anticipation* (0.1-0.3 s): inward-gathering particles (ShapeInOut Inward), a small glow brightening, slight squash of the shark (scale 1 → 0.92 along length), a rising pitch sound.
2. *Impact frame* (same frame, under 50 ms): a white-hot core flash sprite (white centre, hero colour edge, LightEmission 1, size 0 → full in ~0.03 s), the primary shape (chomp / ring / streak), a spark or bubble burst via `:Emit(15-30)`, hit-stop, camera punch, and sound.
3. *Secondary* (0.05-0.3 s): an expanding ring, debris or bubbles with Drag 3-6 so they decelerate (fast start, slow finish = impact read), and a short Highlight flash on the victim.
4. *Dissipation* (0.3-0.8 s): soft smoke or bubble puffs at lower contrast, transparency curve to 1, size still slowly growing.

**Bite / chomp (kid-friendly)**
- Anticipation 0.12 s: jaw opens; 6-8 small white streaks converge on the mouth (Inward, Lifetime 0.12).
- Impact: two curved white "tooth arc" sprites (a flipbook or two crescent meshes) snapping together over 2-3 frames; core flash at mouth (white to hero colour, size 4 → 7 studs in 0.04 s, Transparency 0 → 1 over 0.15 s); `:Emit(20)` of round bubbles with Speed 10-20, Drag 5; a comic "CHOMP" or "+XP" BillboardGui pop (scale 0 → 1.2 → 1 with Back easing). Avoid placing a spiky ray-burst behind the text (owner rule); use a soft round glow or a solid outlined bubble shape instead.
- Victim (fish/prey): Highlight FillColor white, FillTransparency 0.2 → 1 over 0.12 s, tiny squash, then pop into bubbles + sparkle (no blood, no pieces).
- Camera: FOV punch −3 to −5 then back over 0.15 s; shake small, high-frequency, 0.1 s.
- Hit-stop 0.04 s small prey, 0.07 s big prey.

**Roar / shockwave**
- Anticipation 0.3-0.4 s: shark rears back; Inward particle gather; screen slightly darkens (ColorCorrection Brightness −0.05) to make the burst pop.
- Impact: a flat ring mesh (torus or plane with ring texture, Neon or a ParticleEmitter with VelocityPerpendicular) scaling 0 → 30 studs on a fast ease-out (Quint/Expo Out, ~0.35 s) while transparency goes 0 → 1; a second thinner, brighter ring 0.05 s later (double rings read as "power"); a spherical distortion-look shell (a slightly transparent ForceField-material sphere growing fast); a burst of radial streak particles (Squash, VelocityParallel); bubbles pushed outward.
- Camera: strong shake (lower frequency, larger amplitude) 0.3 s decaying; FOV push +6 then settle; optional chromatic-aberration look faked with a quick ColorCorrection Saturation/TintColor flash (Roblox has no built-in chromatic aberration post effect, to my knowledge).
- Logarithmic growth (fast then slow) per the GoW/Halo note, and ring final size = real gameplay radius.

**Dash / torpedo**
- Anticipation 0.15 s: body squash backward, small bubble gather behind tail.
- Launch: a cone-shaped "speed shell" mesh around the nose (panning streak texture, short life), Trail on fins/tail (Lifetime 0.2-0.35, Transparency 0 → 1, Width taper, FaceCamera on), VelocityParallel streak particles with Squash 2-4 behind the body, a bubble wake (`Rate` while dashing, Lifetime 0.6, Drag 2, slight upward Acceleration for buoyancy).
- Camera: FOV +8 to +12 during the dash (Tween Quad Out), back over 0.3 s; subtle speed lines as a ScreenGui overlay at the edges only, so the centre stays clear.
- End: a small puff ring where it stops.

**Ram (heavy body hit)**
- Same as the dash, plus a heavier impact: hit-stop 0.08-0.1 s, a large white flash at the contact point, a cracked "impact star" flipbook (4x4, ~16 frames at 30 fps), a double ring, bigger slower debris/bubbles, and a heavier, lower-frequency camera shake. Knockback starts on the frame the hit-stop ends.

**Transformation / evolve (the "wow" sequence, 2.0-3.5 s total)**
1. *Charge* (0.8-1.2 s): slow-mo feel (tween local animations to 0.5 speed), particles spiral inward (Inward emitters on a Sphere shell + an orbiting Beam pair), the shark brightens toward white (Highlight FillTransparency 1 → 0.3), a rising sound, vignette closes in, background desaturates (ColorCorrection Saturation −0.4).
2. *Peak* (0.1-0.2 s): full-screen white flash (a ScreenGui Frame, Transparency 1 → 0.1 → 1 over ~0.25 s; never pure full white for long), the model swap hidden under the flash, hit-stop, the biggest camera punch in the game.
3. *Reveal* (0.6-1.0 s): new form revealed with a pillar of light (cylinder mesh, Neon, scaling up and fading), 2-3 expanding rings, confetti-style bubbles and sparkles in the new form's hero colour, Bloom intensity briefly raised, saturation restored *above* normal for 0.5 s.
4. *Settle* (0.5 s): name card / stats UI, the aura of the new tier starts its idle loop.
- Kids can skip with a tap after the first time; keep it under 3.5 s so it doesn't become a chore.

**Aura rarity tiers (escalate on several axes at once, not just colour)**
- *Common*: 1 emitter, soft small motes, low Rate (5-8), no glow, white/grey.
- *Uncommon*: + slight LightEmission (0.3), green tint, slow rise.
- *Rare*: + Trail or orbiting particles, blue, LightEmission 0.6, gentle pulse slower than 60 BPM (calm).
- *Epic*: + a mesh shell (fresnel-like glow via a slightly larger ForceField/Neon shell), purple, rhythmic pulses, small sparks.
- *Legendary*: + Beams spiralling (CurveSize on attachments rotated each frame) and flipbook flames/energy, gold/orange with a white core, Highlight outline in tier colour.
- *Mythic/secret*: + ground or water-column effect, periodic "event" bursts at irregular intervals (per 80.lv's random events tip), a colour that animates through a gradient, a unique sound loop.
- Each step adds a *layer*, *motion complexity* and *brightness*, so tiers can be ranked at a glance even by colour-blind players. Keep the wearer's silhouette readable: auras sit behind and around, never covering the face.

**Pickups (food, coins, orbs)**
- Idle: bob up and down (sine via RunService, 0.5 studs, ~1.5 s period), slow spin, a soft round glow behind (BillboardGui ImageLabel or particle with LightEmission 1), occasional twinkle.
- Collect: scale up 1 → 1.3 in 0.06 s then fly to the player or UI counter on a curve (Quad In), small `:Emit(8)` sparkle, counter text bump (scale 1 → 1.15 → 1), short bright "tink" whose pitch climbs on rapid pickups (combo feel).

**Level-up**
- A ring that rises from below up through the shark, a column of light 0.5 s, sparkles in the level colour, a big but brief "LEVEL UP" text pop with a soft glow (not a ray burst), FOV punch +4, a chime. Total under 1.5 s so it doesn't interrupt play.

**Underwater ambience (the world bible layer)**
- *Marine snow / particulates*: a large Box emitter attached to the camera (or a part that follows it), tiny soft white dots, Rate 20-40, Lifetime 6-10 s, Speed 0.2-0.5, slight downward Acceleration, Transparency 0.4 → 1 at both ends, LightInfluence 1 so they dim in the deep.
- *Bubbles*: column emitters from vents and coral (Speed 3-6 up, slight random sideways via SpreadAngle, Size grows a little over life, pop at the end with a small `:Emit`).
- *God rays*: long, soft, wide Beams (or tall tapered mesh planes) from the surface downward, very low opacity (Transparency 0.85-0.95), LightEmission 1, slowly panning a soft-streak texture; Roblox's `SunRaysEffect` helps only when the sun is visible, so hand-placed beams are the controllable option. Beams don't render behind Terrain water, so this only works if the ocean is faked (no Terrain water between camera and beam) or the beams are part-based.
- *Caustics*: tileable caustic `Texture` on sea-floor parts with `OffsetStudsU/V` tweened (two layers moving in different directions read as real caustics); or caustic Beams if not behind Terrain water.
- *Water distortion/colour*: Atmosphere (Density, Color blue-green, Haze) or ColorCorrection tint plus BlurEffect Size 2-4 for depth; increase fog/darkness with depth by tweening Lighting values per zone.
- *Kelp/plant sway*: animated bones or CFrame sine offsets, phase-shifted so not everything moves together.
- Keep ambience low-contrast and slow, so action VFX (bright, fast, warm) stand out against it.

**Camera work (Roblox, client-side only)**
- Shake: a trauma value 0-1 added per hit, decaying ~1.5-2 per second, shake offset = maxOffset x trauma² x noise(t) (math.noise for smooth randomness); apply as a CFrame offset in `RenderStepped` after the camera updates (`BindToRenderStep` at Camera priority + 1). Separate rotation shake (small degrees) reads better than big position shake.
- Zoom punch: tween `Camera.FieldOfView` (e.g. 70 → 64 in 0.05 s, back in 0.2 s, Quad Out).
- Screen flash: ScreenGui full-screen Frame, Transparency 0.6 → 1 in 0.1-0.2 s for normal hits; reserve near-white flashes for evolutions. Keep flashes infrequent and not strobing for photosensitive players.
- Slow-mo: Roblox can't slow global physics time, so fake it by slowing animations (AdjustSpeed), particle `TimeScale` on the involved emitters, and tween speeds, client-side only.
- Bloom/HDR look: Lighting `Bloom` (Intensity, Size, Threshold) makes Neon and LightEmission-1 particles glow; briefly raise Intensity on big moments.

### Gaps
- I did not find a published, sourced frame-by-frame breakdown of a bite/chomp or a Hungry Shark VFX breakdown; the recipes above are synthesised from the principles in Q1.
- RNG/aura Roblox games (Sol's RNG etc.) do not publish their emitter settings; I found only commercial packs and a short DevForum thread.
- No source fetched on Roblox's Atmosphere/SunRays exact behaviour underwater; check in Studio.
- No sourced numbers for trauma-based screen shake (Squirrel Eiserloh's GDC "Math for Game Programmers: Juicing Your Cameras With Math" is the usual reference, not fetched here).

---

## Q3. Roblox-specific limits and tricks (particle count, LightEmission, ZOffset, Beam curves, mesh VFX, phone performance)

### Takeaway
Roblox gives you ParticleEmitter, Beam, Trail, Neon MeshParts, Highlights, Lighting post-effects, TweenService and flipbooks, but no custom shaders. So "shader" tricks (panning, erosion, fresnel) are faked with Beam/Trail texture scrolling, Texture offset animation, mesh scaling and transparency tweening, and flipbooks. On phones, Rate is capped much lower and the engine scales particles down with graphics quality, so important hit feedback should be fired with `:Emit()` and backed up by non-particle layers (meshes, Highlight, UI, camera).

### Cited Findings
- **Rate cap: up to 400 particles/s per emitter on desktop and 100/s on mobile.** Lifetime max is 20 s. Larger particles raise GPU fill-rate cost; many overlapping transparent layers raise overdraw cost. — [Roblox: Particle emitters](https://create.roblox.com/docs/effects/particle-emitters)
- Particle count on screen ≈ Rate x Lifetime. — [Roblox ParticleEmitter API](https://create.roblox.com/docs/reference/engine/classes/ParticleEmitter)
- **LightEmission 0 = normal blending, 1 = additive**; for grayscale textures with no alpha, set 1 to hide dark areas. LightInfluence sets how much world light tints the particle. **Brightness only works when LightInfluence is 0.** — [Roblox: Particle emitters](https://create.roblox.com/docs/effects/particle-emitters); the DevForum intro says Brightness appears when LightInfluence is below 1 — [DevForum: Intro to VFX: Particles](https://devforum.roblox.com/t/introduction-to-vfx-particles/2068650) (minor conflict; test in Studio).
- The API sample uses LightEmission 1 ("overlapping particles … brighter") with LightInfluence 0 ("not affected by world lighting") for glowing effects, and ZOffset −1 to render slightly behind. — [Roblox ParticleEmitter API](https://create.roblox.com/docs/reference/engine/classes/ParticleEmitter)
- **Flipbooks**: FlipbookLayout None / Grid2x2 (4 frames) / Grid4x4 (16) / Grid8x8 (64) / Custom (FlipbookSizeX/Y). Leave transparent spacing between frames (mip filtering may need more). Example sheet 1024x1024 with 8x8. **FlipbookFramerate max 30 fps** (min/max range allowed). Clients may automatically disable flipbooks when memory is low, likely on older phones; reuse textures and keep them small. — [Roblox: Particle emitters](https://create.roblox.com/docs/effects/particle-emitters)
- Other flipbook properties exist (FlipbookMode, FlipbookStartRandom, FlipbookBlendFrames, FlipbookIncompatible) but the docs pages fetched didn't describe their options. — [Roblox ParticleEmitter API](https://create.roblox.com/docs/reference/engine/classes/ParticleEmitter)
- **Graphics-quality scaling**: Roblox automatically scales particle emission down on low graphics. A dev reported a splash (Rate 30, 0.5 s on, Lifetime 0.5-0.7) showing ~15 particles normally but just 1 on low. Workaround: fire with `:Emit(x)` from script. Devs requested an opt-out; no staff reply on that page. — [DevForum: Allow us to disable VFX scaling](https://devforum.roblox.com/t/allow-us-to-disable-vfx-scaling-with-graphics-level/2301568)
- Mobile has much lower particle limits; if particles flicker, reduce Rate, shorten Lifetime or cover a smaller area. — [Roblox: Particle emitters](https://create.roblox.com/docs/effects/particle-emitters)
- Beam visuals vary with graphics settings, so check at lowest and highest Editor Quality Level. — [Roblox: Beams](https://create.roblox.com/docs/effects/beams); same advice for Trails — [Roblox: Trails](https://create.roblox.com/docs/effects/trails)
- Beam TextureMode: Wrap/Static repeat = length / TextureLength; Stretch repeats TextureLength times over the whole beam. — [Roblox: Beams](https://create.roblox.com/docs/effects/beams)
- Beams do not render behind Water or Glass material. — [DevForum: Beams invisible under water](https://devforum.roblox.com/t/beams-invisible-under-water/3028094)
- EditableMesh / EditableImage: improvements usable in published experiences as of 16 July 2025; Roblox said it was still working on replication, permissions, memory budget limits and ID-verification requirements. Users report ID verification gating, an ownership check, and EditableImage being limited to one update per frame. No numeric limits were published in that post. — [DevForum: EditableMesh and EditableImage improvements](https://devforum.roblox.com/t/editablemesh-and-editableimage-improvements/3818624)
- A later announcement says EditableMesh and EditableImage now support shared assets (title only seen in search results). — [DevForum: EditableMesh and EditableImage now support shared assets](https://devforum.roblox.com/t/editablemesh-and-editableimage-now-support-shared-assets/4578818)
- Highlight class properties: Adornee, DepthMode, Enabled, FillColor, FillTransparency, OutlineColor, OutlineTransparency. — [Roblox Highlight API](https://create.roblox.com/docs/reference/engine/classes/Highlight)

### Inferences (tricks; verify numbers in Studio)
- **Highlight limit**: from prior knowledge, Roblox renders at most **31 Highlights at once** (extra ones don't show). Use them only for short hit flashes on the local player's target and for the local player's own aura outline; create on demand and Destroy after, never one per fish.
- **Glow recipe without shaders**: LightEmission 1 + LightInfluence 0 + Brightness 2-5 particles, Neon MeshParts (Neon glows with Bloom), and Lighting.Bloom (Intensity ~0.5-1, Size ~24, Threshold ~0.9-1.5) to give an HDR feel. White-hot core = a smaller, whiter particle layer with higher ZOffset in front of the coloured layer.
- **ZOffset layering**: core flash +2, sparks +1, ring 0, smoke −1, so the bright parts are always on top regardless of distance sorting.
- **Mesh VFX with "panning textures"**: Roblox MeshParts can't scroll UVs, so: (a) use a `Texture` object on parts and tween `OffsetStudsU/V`; (b) use Beams with `TextureSpeed` as panning planes or wrapped around a cylinder (multiple beams around a ring of attachments); (c) use flipbook particles; (d) tween mesh size + transparency for rings, slashes and shells (slash/ring meshes from Blender with a gradient baked into the texture, Transparency tweened 0 → 1 while scaling). "Erosion" is faked with a 4x4/8x8 flipbook of a dissolving shape.
- **Beam tricks**: curve via CurveSize + rotating the attachments each frame for spirals and orbiting auras; Width0 ≠ Width1 for tapered slashes and god rays; Segments higher only for curved beams; widen beams into planes for caustics and shock planes.
- **Trail tricks**: put two attachments on fins/tail for swim streaks; enable only during dash (`Enabled` toggle) to save cost; WidthScale/MinLength exist but were not covered by the fetched page.
- **TweenService**: drive size, transparency, CFrame and FOV with Expo/Quint Out for impacts, Back Out for UI pops, Sine InOut for idle loops. NumberSequence properties can't be tweened directly; tween a NumberValue and rebuild the sequence, or just use Emit with pre-made curves.
- **Phone budget** (rule of thumb): keep live particles on screen in the low hundreds, avoid large screen-filling particles (fill-rate), keep 1-2 unique flipbook sheets per effect family at 512-1024 px, reuse one texture atlas across effects, and create all effects on the client (server only sends "bite happened at X") so effects never cause network lag. Pool effect parts instead of cloning every time.
- **Low-graphics safety net**: since particles get thinned on Low, make sure each important event also has a non-particle layer (mesh ring, Highlight flash, camera punch, UI pop, sound) so it still reads on a cheap phone.
- **EditableMesh**: not needed for core VFX; ID-verification and permission gates make it a poor fit for a kids' game's essential effects. Use regular MeshParts and flipbooks.
- **No custom shaders, no built-in chromatic aberration or screen distortion** in Roblox (to my knowledge as of this research): fake distortion with a quick ForceField-material shell or ColorCorrection tint pulse.

### Gaps
- Exact FlipbookMode options (Loop, OneShot, PingPong, Random are what I recall) and FlipbookStartRandom behaviour were not described on the fetched pages.
- No official numeric per-device particle budget beyond the 400/100 per-second Rate caps.
- No official statement on how much particle scaling each graphics level applies.
- The Highlight 31 limit is from prior knowledge; the fetched Highlight API page did not state it.
- Beam `TextureSpeed`, `LightEmission`, `ZOffset` and Trail `WidthScale`/`MinLength`/`MaxLength` exist but weren't described on the fetched guide pages.
- No top DevForum VFX showcase breakdown with exact settings was retrieved; the "VFX Tutorial | ROBLOX" thread (https://devforum.roblox.com/t/vfx-tutorial-roblox/872437) and the "VFX Forge" tool (https://zilibobi.itch.io/vfx-forge) were found but not read.
