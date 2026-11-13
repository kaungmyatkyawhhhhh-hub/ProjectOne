---
date: 2026-11-14
tags: [research, watch-study, ui, lighting, vfx, animation, youtube, growth]
---
# Watch study: 5 Develuper tutorials + Zyonic's "Dodge or Die" story (6 YouTube videos)

Watched 14 Nov 2026. I downloaded the videos with yt-dlp on the owner's PC (720p) and pulled contact sheets and key frames with ffmpeg. For 3 of the transcripts I used YouTube's own captions. For the other 3, YouTube returned HTTP 429 on the captions, so I transcribed them with Whisper (small.en) locally. The audio was heard through the transcript only; I did not analyse the music.

| # | Video | Channel (subs) | Posted | Length | Views / likes / comments |
|---|---|---|---|---|---|
| 1 | [Make Your Roblox UI Look 10x Better](https://www.youtube.com/watch?v=F6AtQKo3uIY) | Develuper (24.3K) | 21 Aug 2026 | 7:03 | 164K / 4.9K / 334 |
| 2 | [Make Your UI Feel 10x Better With ANIMATIONS](https://www.youtube.com/watch?v=8pJGBz-J75w) | Develuper | 21 Sep 2026 | 6:59 | 55K / 1.9K / 187 |
| 3 | [Make Your Roblox Game Look 10x Better With Lighting](https://www.youtube.com/watch?v=vkEXLmRAQgs) | Develuper | 21 Apr 2026 | 4:37 | 254K / 11.3K / 289 |
| 4 | [How to ACTUALLY Use VFX in Roblox](https://www.youtube.com/watch?v=TkNZETIu0CM) | Develuper | 31 Mar 2026 | 9:24 | 238K / 9.0K / 253 |
| 5 | [Make Your Animations 10x Better with Animation Events](https://www.youtube.com/watch?v=d5GGIJJyMpg) | Develuper | 17 Mar 2026 | 8:04 | 183K / 9.6K / 302 |
| 6 | [I Made a Successful Roblox Game to Prove It's Not Luck](https://www.youtube.com/watch?v=RIWPfMJyVhQ) | Zyonic (38.5K) | 8 Sep 2026 | 8:00 | 415K / 6.2K / 331 |

## 1. UI that looks 10x better (Figma → images)

![[2026-11-14 Develuper UI video - key frames.jpg]]

His two goals for every element are **identity** (colours, shapes, font, texture) and **depth** (it should read as a 3D button).

The button recipe (the yellow "RETRY ↻" button), in Figma:
1. Draw a rounded rectangle with a **gradient fill**: saturated colours, brightest at the top (yellow → orange).
2. **Depth:** duplicate the shape, move it straight down, put it behind, and make it slightly darker. Flatten both into one shape, then add a **black stroke set to outside**.
3. **Text:** FredokaOne with a thick stroke and **the same depth trick** (a darker copy offset down behind it).
4. **Icon:** an SVG (vectorise it if needed), coloured white, with the same depth trick.
5. **Shine:** an invisible frame works as a mask; put a shine shape inside it and pick a blend mode.
6. **Edge highlight:** another invisible frame the same shape, with an **inside stroke** and a blend mode. He calls it "surprisingly big difference".
7. Little stars inside the mask, also blended. An optional drop shadow.

Shop structure (the STORE! panel):
- A **top bar that stands out**: a green "STORE!" title tab and a red **Close** button.
- Background: white with some details, or semi-transparent black. Either gives freedom for the rest of the colours.
- **The main item is bigger and first** (a BUNDLE tile in the left column). Smaller, less attractive items come after it.
- Each item has a title, a small description if it bundles several things, a large image, and **a green price button** ("green is just the colour of money"), with a small currency icon (Robux) on it.

Export: one PNG per element, as big as possible but **under 1024 px**, because Roblox downscales larger images. Upload them with the Asset Manager, then rebuild everything as ImageLabels and ImageButtons. Even he says the result came out a bit soft.

## 2. UI animations (relative scaling)

![[2026-11-14 Develuper UI animation video - key frames.jpg]]

The structure is a `UIAnimations` ModuleScript plus a `UIController` LocalScript.
- **Relative scaling:** store each element's base Size (and later its Position) in a table the first time you touch it. Then `ScaleTo(element, factor)` sets Size = base × factor, so 1.15 means 15% bigger on any screen. Pixel-based hovers break across phone and TV.
- Values read off the code on screen:
  - hover: `ScaleTo(button, 1.1, 0.2, Back, Out)`
  - leave: `ResetSize(button, 0.15, Back, Out)`
  - press (`MouseButton1Down`): `ScaleTo(button, 0.92, 0.1, Quad)`
  - release (`MouseButton1Up`): back to base with **Elastic**
  - The controller loops over `GetDescendants()` and wires every `GuiButton`.
- **States:** a second image per button for hover. He keeps the image IDs in a StringValue per button, and buttons without a hover image simply get no swap. `ImageButton.HoverImage` / `PressedImage` do this with no code.
- **Window open: "fade slide".** Start the window offset a little with full transparency, then tween to the stored base position, opaque. The easing is **Quint**, about 0.35 s, with In/Out directions.
- **Attributes map buttons to panels:** e.g. a string attribute on the green button tells the controller to open the Shop.
- **Text: bake it into Figma art or make it in Studio?**
  - Static text, or text with complex styling (depth, effects): Figma.
  - Changing numbers, interactive text, very large text, or a simple font with a stroke: Studio.

## 3. Lighting (the most-viewed video, and the shortest)

> **Turned into a skill (14 Nov):** [[Skills/roblox-game-lighting/SKILL|roblox-game-lighting]]. It has his exact panel values as the `stylized_day` preset, plus 7 more presets (incl. MEGA BITE's reef), backup-first apply/restore, the random-texture and retro-outline scripts, and a look check. Tested in MEGA BITE Play: his land preset makes the reef pale and milky, and random textures barely show on low-poly MeshParts.

![[2026-11-14 Develuper lighting video - contact sheet.jpg]]

The hook is the default grey baseplate against his styled scene, plus an "RTX ON" meme, in the first 5 seconds. His order of operations:
1. Lighting style **Realistic** (better shadows).
2. Brightness up a little; tweak both ambients (`Ambient` = shadow tone, `OutdoorAmbient` = outdoor light); set time of day and sun angle.
3. **Atmosphere:** Density **0.3–0.4**, Offset **0**, a small amount of light-coloured **Glare**, a little darker **Haze** (depth without fog).
4. **Bloom** up so bright things pop; a bit of **SunRays**, especially for late-afternoon or sunset looks.
5. A skybox from the toolbox ("don't overthink it").
6. **ColorCorrection (the most important step):** a soft tint (very light blue), saturation up to taste, and **contrast up** ("contrast is what makes your game look sharp and clean").
7. Optional: the baseplate material variant set to studs to match his style.

Extras:
- A **Highlight** on every player gives a retro/2D look ("people said it looked like Block Tales"). Configure it so it doesn't show through walls.
- **Random textures:** pick 3–4 similar textures, and a script applies a random one to every surface of each map part, plus a small random **tone variation** on each part's colour. This makes the world feel less flat and less copy-pasted.

## 4. VFX

- The types are glows, trails, beams and **particle emitters**. **Attachments** are what make an effect move and rotate with its part.
- The toolbox is fine for VFX ("some are used in popular games").
- The particle settings that matter: Rate, Lifetime (a range), Speed, SpreadAngle, Acceleration (−Y = gravity), Size and Squash as NumberSequences, Transparency over time, LightEmission. **Negative LightEmission gives a dark outline look.**
- Play effects with **`:Emit(n)` at the exact moment**, rather than leaving emitters on.
- Effects on your own character play on the client (responsive). **Impacts are done on the server** so everyone sees them: a RemoteEvent sends the aim position, the server **raycasts from the arm** to find the real hit point, clones the impact VFX there, plays a sound once, emits after a short delay, and cleans up after a couple of seconds.
- Remove the leg keyframes from an upper-body attack so Roblox blends it with walking.
- **Auras and transformations:** keep a **template rig** that holds all the attachments, particles, beams and sounds in the right body parts. One server script copies the template onto each character on spawn. A second script toggles them: looped auras, one-shot bursts, a ground effect on an invisible part that follows the player, a burst sound, then a looped aura sound.

## 5. Animation events

- **Don't guess impact timing with `task.wait`.** Put an **animation event** marker on the exact frame and listen with `AnimationTrack:GetMarkerReachedSignal("Impact")`.
- One event name, different **parameters** ("heavy") for different hits keeps the code clean.
- **Animation priority:** set attacks to Action so they override idle and walk.
- On the marker: play the sound (stored in the tool's handle) and `Emit` the smoke, sparks and rocks particles. The particles sit in an attachment on the blade, so they follow it.
- **Physical rock debris** ("The Strongest Battlegrounds" style): spawn small unanchored Parts with random size, rock material and colour, and `ApplyImpulse` + `ApplyAngularImpulse`. A collision group called `DebrisRocks` doesn't collide with a `Characters` group (every character part gets assigned on spawn). Fade the parts out, then remove them with `Debris:AddItem`.

## 6. Dodge or Die: "it's not luck" (Zyonic)

- **The idea came from a physics toy:** an AlignPosition part chasing him in Studio was fun to dodge. The game was built in about **1 month** while he was in college and running his other game.
- The build order: movement first (run, double jump, dodge) → a round system with chasing balls → hit detection (the hard part) → long-term goals (cash upgrades, **tool crates** for gambling, lots of tools) → a lobby (spinner wheel, leaderboard, a practice area) → passes and dev products.
- **He playtested with Discord fans at every stage**, even the ugly early ones.
- Launch: **280 ad credits for about 7 days**. That gave about 50 CCU, poor metrics and a bad dislike ratio. He kept a **daily list of fixes** and shipped updates every day. Two more ad campaigns did not trigger home recommendations.
- **He turned the ads off.** CCU dropped, then the metrics slowly climbed, recommendations followed, and it peaked at **900 CCU**.
- A studio offered **$24K for 70%**, and he refused. Then it dropped to 300 CCU for a week, until his changes landed. Then it took off again, and he fed it: a battle pass, clans, more tools, cosmetics.
- **After 2 months: 5K CCU on weekdays, a 7K peak, 20M visits.** His lesson: prove the idea by playtesting, improve every day, and don't quit at the "flop" stage (his first game, Manhunt, did the same thing).

## What makes these videos work (Develuper's format)

- **The hook is a before → after in the first 5 seconds** ("from making UIs like this to … like this"). Then he names the problem in one sentence ("Roblox's UI editor is limited, that's why your UIs look flat").
- Short (4.5–9.5 min) and practical, with code on screen and "script in the description" as the reason to stay.
- A recurring desk-and-avatar host scene, meme cutaways (monkey, dog, emoji) every 30–60 s, and section cards on a retro purple grid in a pixel font ("ATTACHMENTS", "ANIMATION PRIORITY").
- **The broadest topic got the most views:** the lighting video is the shortest and the most watched (254K). UI animation, a part 2, got the fewest (55K).
- Each video teases the next one in its last line (UI → "part 2 animations?", VFX → "movement or combat").

## For our games

**UI (feeds the `roblox-ui-pro` skill and the MEGA BITE UIKit):**
- Our kit already does "depth" on plates and buttons (the darker base under the face). **We don't do the depth trick on text and icons yet.** In Studio that means a darker copy of the label 2–3 px lower, behind the real one, plus the ink stroke. This is cheap and very "simulator".
- **Edge highlight:** an inside light stroke on plates. In Studio: a white `UIStroke` around 0.6–0.7 transparency on an inner frame, or `BorderOffset` to pull it inside. Try it on MEGA BITE's Plate before deciding.
- **Shop rules to adopt:**
  - the hero item (bundle or best deal) is first and biggest
  - every price is a green button with a currency icon
  - the title tab and a red Close sit in a top bar
  - the window background is white-with-details or semi-transparent black
- **Animation numbers:** his hover is 1.1, press 0.92 and release Elastic; ours are 1.05 / 0.95 / Back Out. **Store base sizes and scale relatively** so hover and press never stack or drift (this is the same reason our kit uses a `UIScale` per button). A fade-slide window open is a good alternative to our scale-pop for big panels.
- **Text rule vs our art pipeline:** we keep **"no baked text in ChatGPT art"** (ChatGPT garbles letters, and baked text can't change or localise). We get his "Figma depth text" look in Studio with the two-label trick instead.

**Lighting (GYM ARC, Galaxy, any land map; MEGA BITE is underwater, so only the ColorCorrection advice applies there):**
- Start from his preset: Atmosphere 0.3–0.4 density with no fog, light glare and a little dark haze, Bloom up, SunRays a bit, and **ColorCorrection contrast up with a soft tint**.
- Use the random-texture and tone-variation script on big flat map areas, which works against the "same prop again" tell from the quality-nerd kid sim.

**VFX and animation (MEGA BITE bites, rams and roars; GYM ARC lifts):**
- Put animation events on the bite/impact frame and drive the sound + `Emit` + camera shake from `GetMarkerReachedSignal`, never from timers.
- Ram or breach impacts: physical sand/rock debris in a collision group that ignores characters.
- Evolutions and abilities: a template rig of VFX copied onto the character on spawn, then toggled on and off.

**Growth (all games):** Dodge or Die matches our plan: playtest early, ads only to seed, a **daily fix list** during the first weeks, and don't panic at a 2-week flat line. Add depth (battle pass, clans, cosmetics) once the curve turns up.

## Video ideas for our own channel
"Make your Roblox UI look 10x better with ChatGPT" in the same before→after format, using our ChatGPT art pipeline + UI kit instead of Figma. It's the same promise with a method nobody else shows.
