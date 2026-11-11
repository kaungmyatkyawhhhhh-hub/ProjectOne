# How Fisch and other top Roblox fish/ocean games build their creature models (as of Nov 2026)

Research note for MEGA BITE (Roblox shark eat-and-evolve game, models built by Claude in Blender by code). Research limits: fandom.com, fischipedia.org and most guide sites could not be fetched or downloaded from this session (proxy 403/502, fischipedia client error), and the image search tool showed images to the user but not to the researcher. So **no model images could be inspected directly**. Visual claims below come from text sources; anything beyond that is marked as inference.

## What Fisch's fish models look like (style, build, colours, variants, big creatures)

### Takeaway
The best primary source (Roblox's own Creator Spotlight) shows Fisch's fish are **multi-part models whose parts are recoloured separately by script**. Hue and tint are changed procedurally, and about 25 mutations reuse each base model. So the quality comes from clean, readable shapes with flat colour blocks per part, plus strong recolour and VFX variants. It does not come from heavy painted textures. A detailed texture-level description (scales, normal maps, roughness) could not be verified.

### Cited Findings
- Fisch was made by a solo developer, WoozyNate, who "scripted, modeled, and built Fisch from scratch" in about four months. — [Roblox DevForum Creator Spotlight](https://devforum.roblox.com/t/creator-spotlight-woozynate-makes-a-splash-with-fisch/3269481)
- Fish variation is procedural: the fish's weight is used as a seed that "is procedurally ran through the fish model, changing the attributes of each part separately". Hue and tint are changed procedurally, fish can be shiny or sparkling, and each fish has about 25 mutations. — [DevForum Creator Spotlight](https://devforum.roblox.com/t/creator-spotlight-woozynate-makes-a-splash-with-fisch/3269481)
- WoozyNate used the Studio plugin **Color Adjust** (changes hue, saturation and luminance across many parts) to "easily recolor some of the fish", and **Moon Animator** for animation. — [DevForum Creator Spotlight](https://devforum.roblox.com/t/creator-spotlight-woozynate-makes-a-splash-with-fisch/3269481)
- The game is described as a "cozy fishing adventure game", and its designer's stated aim was a "simple and calm" fishing game. — [DevForum Creator Spotlight](https://devforum.roblox.com/t/creator-spotlight-woozynate-makes-a-splash-with-fisch/3269481); [Roblox Wiki (fandom), Fisch](https://roblox.fandom.com/wiki/Fisching/Fisch)
- Mutation visuals (one per mutation; these are mostly whole-model recolours or material swaps plus particle auras):
  - Plain colour swaps: Abyssal (blue), Albino (white), Darkened (black), Midas (gold), Silver, Nuclear ("bright, radioactive green"), Sleet (blue-grey), Festive (red and white), Lunar (purple and yellow).
  - Encasings: Amber ("encased in a block of amber") and Frozen (trapped in a block of ice).
  - Material changes: Translucent (see-through), Glossy ("pastel blue with a glossy shine"), Negative (inverted colours).
  - Colour plus particle aura: Electric (yellow sparks), Hexed (dark red with red sparks), Scorched (burnt black with flames), Solarblaze (orange with flames), Sunken (dark green with green smoke), Greedy (gold with a yellow aura), Fossilized (purple with an aura of ancient symbols), Aurora (pink with a blue, green and red aura).
  - Patterns: Mosaic (a pastel base with rectangles and triangles of other pastels), Jolly (Christmas-tree look with neon patches), Mythical (cycles through neon colours).
  - Size: Big and Giant (scaled up).
  - Shiny ("an alternative color combination to its Bestiary version") and Sparkling ("bright and sparkly").
  — [Dot Esports, All mutations in Fisch](https://dotesports.com/roblox/news/all-mutations-in-fisch-and-what-they-do)
- Megalodon in Fisch: the Bestiary calls it a "gigantic predatory shark" with a large mouth of serrated teeth that can "easily rip through anything in its way". It is a Hunt fish, weighs 50,000–140,700 kg, and lives at Ancient Isle. There are separate species variants (Ancient Megalodon, Phantom Megalodon, Shamrock Megalodon, Livyatan) and mutations such as Albino, Aether, Ascended, Darkheart, Hades' Curse and Hadal. — [rblxguide Fisch Megalodon](https://rblxguide.com/games/fisch/fish/megalodon)
- Fisch makes themed event species (for example Nessie, ghoulfish and zombiefish for the FischFright event). The Spotlight notes that the "majority of the fan art came from the event". — [DevForum Creator Spotlight](https://devforum.roblox.com/t/creator-spotlight-woozynate-makes-a-splash-with-fisch/3269481)

### Inferences
- "Each part separately" plus a hue/saturation plugin means **Fisch fish are assembled from several separately coloured pieces**: body, belly, fins, tail, eyes, and possibly stripes or markings as their own parts. Colour comes from per-part Color and Material rather than from one baked texture. This is the most copyable part of the craft for code-built Blender models. Build each fish as separate mesh pieces (or one mesh with separate material slots or vertex-colour regions) with flat, saturated colour blocks, so mutations and shinies can be made by recolouring per part in Luau.
- Mutations are mostly whole-model colour or material swaps (Neon, Glass, transparency, inverted colour) plus ParticleEmitter auras (sparks, flames, smoke). For MEGA BITE that suggests building one clean base shark per evolution and making rarity skins (golden, albino, neon, frozen, flame aura) as recolour and particle presets, not new models.
- The strong mutation names (Ascended, Hades' Curse, Aether) and the event species show that variety and "special look" matter more to players than texture detail.

### Gaps
- No direct image inspection was possible. These are **not verified**: poly density, whether fins are thin planes or thick, eye style, scales or normal maps, painted gradients, and roughness or shine settings. Fischipedia and Fandom pages with fish images were unreachable (403/502).
- No ArtStation, Sketchfab or Twitter portfolios of Fisch modellers were found. No poly counts, texture sizes, or use of Blender or Substance were found in public sources. The Spotlight does not name the modelling software.
- No first-hand source was found for Fisch's Great White, whales or Kraken event designs.

## Who makes Fisch's models, and the workflow

### Takeaway
The original fish were made by WoozyNate alone. Ownership and development later passed through Do Big Studios and a team led by animepunk. One secondary source claims a studio (Twin Atlas) brought in specialised modellers, but this is unverified and conflicts with the Roblox Wiki timeline.

### Cited Findings
- Solo creation by WoozyNate (scripting, modelling, building). — [DevForum Creator Spotlight](https://devforum.roblox.com/t/creator-spotlight-woozynate-makes-a-splash-with-fisch/3269481)
- Do Big Studios acquired Fisch on 2 Nov 2024 and took over primary development. On 7 Jul 2025 Do Big stepped down and a team led by animepunk took over updates. On 21 Aug 2025 ownership returned to WoozyNate. The game reached 1M concurrent players on 4 Oct 2025. — [Roblox Wiki (fandom), Fisch](https://roblox.fandom.com/wiki/Fisching/Fisch)
- One page claims Twin Atlas partnered with WoozyNate in late 2024 and "brought in a larger team of specialized modelers and animators", but names nobody. — [shapes.inc Fisch author page](https://shapes.inc/fandom/fisch/author). This is contradicted by the [Roblox Wiki](https://roblox.fandom.com/wiki/Fisching/Fisch), which names Do Big Studios, not Twin Atlas. Treat it as unreliable.
- Tools named publicly: Color Adjust (recolouring), Moon Animator (animation), Tag Editor (backend). — [DevForum Creator Spotlight](https://devforum.roblox.com/t/creator-spotlight-woozynate-makes-a-splash-with-fisch/3269481)

### Inferences
- A solo developer shipping hundreds of fish in about four months implies quick, simple-shaped models, with variety coming from recolour and procedural changes. This is good news for a code-built Blender pipeline: the quality bar is shape and colour design, not sculpted detail.

### Gaps
- No interviews, devlogs or portfolios describing modelling workflow, poly budgets or texture sizes were found.

## How fish are shown in-game and at what camera distance

### Takeaway
Only partly answered. Fish are catalogued in a per-island Bestiary and sold or carried as items. Exact in-hand presentation and camera distances could not be verified from fetchable text.

### Cited Findings
- Caught fish are catalogued in the player's Bestiary and can be sold to merchants for C$. — [Roblox Wiki (fandom), Fisch](https://roblox.fandom.com/wiki/Fisching/Fisch)
- Players note they can now "see rarities without hovering over them" (inventory readability). — [DevForum Creator Spotlight replies](https://devforum.roblox.com/t/creator-spotlight-woozynate-makes-a-splash-with-fisch/3269481)
- Bestiary guides exist per island (Isle of New Beginnings, Lushgrove, Waveborne, Boreal Pines). Image results titled "Megalodon - Official Fisch Wiki" and "How to Catch the Megalodon in Fisch Roblox | Beebom" exist but could not be viewed. — image search results (no fetchable URLs returned)

### Inferences
- In Fisch, fish are mostly seen close up (held by the avatar, or in the Bestiary and inventory viewports), so silhouette and colour blocks must read at about 1–5 studs. In MEGA BITE the player's own shark is seen from a third-person chase camera, usually from behind and above. That makes the **back and top silhouette** (dorsal fin, tail fork, head shape, back colour against belly colour) the most important view. Bosses and the Megalodon are seen from further away and need high-contrast teeth and eyes.

### Gaps
- Exact hold animation, Bestiary 3D viewport behaviour, and display or mounting features were not verified.

## Other games: Fish It!, Be Fish, SharkBite 2, Be a Shark, DEVOUR

### Takeaway
Little model-level detail was available. SharkBite 2 (Abracadabra) is credited with custom models, better textures and smoother, more realistic shark animation (especially the bite) than SharkBite 1. Its basic sharks look plain, and its event and skin sharks carry the visual interest. Be a Shark is an eat-to-grow predator simulator with tradable skins. Nothing reliable was found on Be Fish or DEVOUR, or on Fish It!'s model craft.

### Cited Findings
- SharkBite 2 (published by the Abracadabra group, launched Oct 2022):
  - Visuals improved over SharkBite 1, with custom models instead of default terrain and better texture quality.
  - Shark animations are "more realistic and smoother", and the biting motion is singled out as the biggest change.
  - The basic Great White is plain, and the Bull Shark looks similar to it.
  - Event sharks have distinct designs (a Christmas shark with blinking lights, a Chocolate shark with bunny ears).
  - Megalodon and Mosasaurus are large, with exposed bone-like details.
  - Rare crate skins include Golden and RGB.
  — [Namu wiki, SharkBite 2](https://namu.moe/w/%EC%83%BC%EB%B0%942)
- Be a Shark (Be a Shark Studios, released 12 Nov 2023):
  - Players start as a small, vulnerable shark, eat fish to grow, then hunt other sharks and players for Skulls.
  - It has rare tradable skins and 12-player servers.
  - It has about 125.6K upvotes and 17K downvotes, and was last updated 22 May 2026.
  — [AllRoblox, Be a Shark](https://allroblox.com/en/game/be-a-shark)
- Fish It! has a mutation system with shiny-type variants. — [bo3.gg Fish It mutations](https://bo3.gg/games/articles/fish-it-mutations) (page content could not be extracted; only the title and snippet were seen)

### Inferences
- SharkBite 2 shows that **animation, especially the bite (jaw opening plus head lunge), sells a shark more than mesh detail**. For MEGA BITE, a clear, fast bite animation with a wide jaw gape is worth as much as a better mesh.
- Both shark games put their visual "wow" into skins (golden, RGB, event themes). That matches Fisch's mutation approach: a clean base model plus colour, material and particle variants.

### Gaps
- Be Fish and DEVOUR: no reliable pages identified (searches returned unrelated Roblox game links). Model style and quality are unknown.
- Fish It!: no description of its model style was retrieved.
- No poly counts or artist credits were found for any of these games.

## What players praise or criticise about the models

### Takeaway
No direct player praise or criticism of Fisch's or SharkBite 2's fish models was found in fetchable sources. Reception evidence points to popularity, fan art around event creatures, and gameplay complaints, not model complaints.

### Cited Findings
- Fisch reached 1M concurrent players and was curated on Today's Picks. — [Roblox Wiki (fandom), Fisch](https://roblox.fandom.com/wiki/Fisching/Fisch)
- Most of Fisch's fan art came from the FischFright event, whose new creatures were Nessie, ghoulfish and zombiefish. — [DevForum Creator Spotlight](https://devforum.roblox.com/t/creator-spotlight-woozynate-makes-a-splash-with-fisch/3269481)
- SharkBite 2 complaints recorded on Namu are about gameplay (shark balance, AFK system, weapons), not visuals. — [Namu wiki, SharkBite 2](https://namu.moe/w/%EC%83%BC%EB%B0%942)

### Inferences
- Characterful special creatures (monsters, themed sharks) get fans excited enough to draw them, which ordinary fish do not. MEGA BITE's squid boss and Megalodon deserve the most design effort.

### Gaps
- Reddit (r/fischroblox) and YouTube comments could not be searched or fetched. Searches returned only asset-store listings.

## Practical craft checklist for MEGA BITE (inferred from the above, not cited)
1. **Build from separate colour regions:** belly (light), back (dark), fins and tail, eyes, teeth and gums, plus optional markings, each as its own material slot or part, so recolours and skins are trivial. This copies Fisch's per-part method.
2. **Flat, saturated colour blocks with a clear light-belly, dark-back split.** Use SmoothPlastic or plain materials. Don't rely on fine painted detail that disappears on phones.
3. **Exaggerate the silhouette for each evolution:** hammer head, Great White's tall dorsal fin and pointed snout, Megalodon's bulk and huge jaw. Read it from the chase camera behind and above.
4. **Make variety from presets instead of new meshes:** Golden, Albino, Neon or RGB, Frozen (ice block or glass), flame, spark and smoke aura ParticleEmitters, Giant scale.
5. **Invest in the bite animation** (wide jaw gape plus head lunge), as SharkBite 2's biggest visual upgrade shows.
6. **Put the most design effort into boss and event creatures**, because they drive fan attention.
