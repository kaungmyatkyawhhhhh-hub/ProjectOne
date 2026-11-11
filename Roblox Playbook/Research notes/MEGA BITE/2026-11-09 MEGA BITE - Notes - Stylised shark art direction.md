# Art direction and modelling craft behind high-quality stylised sharks and fish (2026)

Scope note: This was a 2026-11-09 web research pass, about 25 tool calls. Primary written breakdowns of the named shark games (Hungry Shark, Feed and Grow, Maneater, Abzû, Subnautica, Sea of Thieves) are scarce. Most of them exist only as GDC or YouTube videos, with no text or transcript I could read. Sourced facts are therefore thinner than hoped. The transferable rules are labelled clearly as **inference** (my art-craft reasoning, built on the sourced principles and on real shark anatomy). Nothing here suggests copying any asset.

---

## 1. How top games and artists handle silhouette, form, fins, eyes, teeth and skin

### Takeaway
The pro studios I could verify all start from **silhouette and personality per shark, set at the sculpt stage**, before any texture work. Hungry Shark's sharks go through initial idea, then wireframe, then sculpt, then final concept, and each one is meant to have a "unique personality, silhouette and style". Stylised looks come from **simplifying real reference and then hand-painting it**, not from raw photo or PBR detail. Real shark anatomy (five gill slits, a heterocercal tail with the longer upper lobe, a keel on the tail stock, dark-top/light-belly countershading) is the skeleton that stylisation exaggerates.

### Cited Findings
**Hungry Shark (Future Games of London / Ubisoft London)**
- Art director Pete Kempton directed the high-poly shark sculpts for Future Games of London. The goal was to give each shark a "unique personality, silhouette and style" while exploring how to expand the franchise. Sharks sculpted: Bramble, Thresher, Carpet, Great White, Pacific Sleeper, Goblin, Whale, Leopard. — [Hungry Shark High Poly Conceptual Work, ArtStation](https://ichidan.artstation.com/projects/nY9WmE)
- Each sculpt was designed to work in two poses: a swimming pose for gameplay, and a standing pose that makes the sharks "more approachable and marketable". The high-poly sculpts set the mood. — [same](https://ichidan.artstation.com/projects/nY9WmE)
- The Hungry Shark World "Apex" sharks (Gaia, Mighty Matriarch, Apex Manta Ray) were made in this order: initial ideas, wireframe, sculpt, final concept, ability-preview VFX. In other words, the 3D form is solved before the final paint-over. — [Hungry Shark World – Apex Sharks, ArtStation](https://ichidan.artstation.com/projects/rJxnJE)
- The pages give no rules about teeth, eyes or texture. The images themselves have to be studied by eye. — [same](https://ichidan.artstation.com/projects/rJxnJE)

**Maneater (Tripwire)**
- Design goal: make "the shark in Maneater feel like a culmination of all the things everyone loves about sharks", with a strong focus on **mass and weight**: "We want players to feel more powerful when controlling a more powerful and evolved shark." Evolution stages run from Pup to Mega. — [80.lv: Sharks and Blood – How Maneater Was Developed](https://80.lv/articles/sharks-and-blood-how-maneater-was-developed)
- All shark animation was hand-keyframed. The team studied real shark footage and "academic studies on shark fins" to understand how sharks move. — [same](https://80.lv/articles/sharks-and-blood-how-maneater-was-developed)
- The article gives no detail on the shark's proportions, teeth, eyes or skin. — [same](https://80.lv/articles/sharks-and-blood-how-maneater-was-developed)

**Abzû (Giant Squid, art director Matt Nava)** and **Sea of Thieves (Rare)**
- The GDC 2017 talk "Creating the Art of ABZÛ" (Matt Nava) exists, but the 80.lv write-up has no text rules, only the embedded video. — [80.lv GDC 2017](https://80.lv/articles/gdc-2017-creating-the-art-of-abzu); [GDC Vault](https://gdcvault.com/play/1024409/Creating-the-Art-of-ABZ)
- In the Sea of Thieves GDC18 talk (Ryan Stevenson), "a few simple rules can permeate through all aspects of a game's visuals". The rules themselves are only in the video (youtube.com/watch?v=BzppoQTG3m0). — [80.lv GDC18](https://80.lv/articles/gdc18-visual-adventures-on-sea-of-thieves); [GDC Vault](https://gdcvault.com/play/1025015/Visual-Adventures-on-Sea-of)
- A summary of the Sea of Thieves and Fortnite talks gives these rules: "you have to simplify everything". Build complexity by combining simple shapes. Photos can't be used directly as textures, so references are simplified and painted by hand. Fortnite found that simplifying photos in Photoshop left textures "too noisy" and hand-painted them instead. Normal and specular maps are still used on top of stylised textures. Fortnite also "remove[s] all parallel lines". — [Habrador blog: stylized graphics of Fortnite & Sea of Thieves](https://blog.habrador.com/2018/08/stylized-graphics-fortnite-sea-of-thieves.html)

**Subnautica 2**
- Creature pipeline: visual development lead Cory Strader does the concept, then lead character artist Marcelo Figueredo builds the model, then animation, VFX and AI. The principles are only in the video. — [Unknown Worlds Dev Vlog 3](https://unknownworlds.com/news/subnautica-2-dev-vlog-3)

**Independent stylised shark artists**
- A stylised shark by Roman Topchiy (concept by Nicola Saviori) was made in Blender, Substance 3D Painter and Photoshop, working from a 2D concept first. — [80.lv](https://80.lv/articles/take-a-look-at-this-stylized-shark-created-with-blender-substance-3d)
- A stylised shark character by Marchuk follows these steps. Keep the concept's main **flow lines**, which carry the personality. Study how other artists draw sharks and combine those ideas. Analyse "the spacing between the outer lines of the form". Set proportions before details, using a reference distance as a ruler. Do a **grayscale value pass first**, then paint shadows by eye using AO as a guide. Control hue, saturation and lightness together: a darker-looking colour with a lighter shadow value "signals a mistake". Bake base maps in Marmoset, then **hand-paint over them** in 3DCoat. — [80.lv: Making Stylized Anthropomorphic Shark Adventurer](https://80.lv/articles/making-stylized-anthropomorphic-shark-adventurer)

**Real shark anatomy (what stylisation must keep)**
- Most sharks have **five gill slits** per side, near the head. Most have **eight fins**: two pectoral, two pelvic, two dorsal, one anal, one caudal. The tail is **heterocercal**: the backbone runs into the upper lobe, which is usually the longer one. Mackerel sharks (great white, mako) have **lateral keels on the caudal peduncle**. **Countershading**: darker upper body, lighter underside. Many sharks have about three rows of teeth embedded in the gums. — [Wikipedia: Shark anatomy](https://en.wikipedia.org/wiki/Shark_anatomy)

### Inferences (transferable rules, not sourced claims)
- **Silhouette.** The side view should read as one long, gently asymmetric S or C line. The back curve rises steeply from the snout to the first dorsal fin, then runs long and flat to the tail stock. The belly is fuller and lower under the pectorals, then tucks up to the pelvic and anal fins. The widest and tallest point sits about one-third back from the snout, not in the middle. A body whose fattest point is centred and that tapers equally both ways reads as a "tube" or a "sausage".
- **Straights against curves.** Each long contour should pair a fairly straight edge against a curved one. Examples: a straight-ish back line against a curved belly, a straight leading edge on each fin against a curved trailing edge, a straight jaw line against a curved snout. This follows the straights-and-curves drawing principle (see Q2) and Fortnite's "no parallel lines" rule.
- **Cross-section is not round.** A real shark's cross-section is a rounded diamond or teardrop, with a hint of a ridge along the spine and a flatter belly. At the head it is wider than tall (a flattened wedge). At the tail stock it is taller than wide, with a side keel on mackerel-type sharks. If every slice is a circle, the result looks inflated.
- **Secondary forms worth modelling:** the brow ridge over the eye, which also gives the "brow" the style guide wants; the lower jaw hinge or cheek bulge behind the mouth corner; a slight swelling at the gill area with five shallow, tapered gill slits that fade at both ends; the pectoral fin root blending into the body with a soft fillet; the dorsal fin base widening into the back; the caudal keel.
- **Fins.** Fins should be thick at the root and thin to a sharp trailing edge (a wedge profile, not a flat slab with constant thickness). Give them a swept-back leading edge, a curved or notched trailing edge, and a pointed or slightly rounded tip. The pectorals are the largest paired fins and sit low and forward, angled down and back. The first dorsal is tall and sits roughly mid-body over the pectoral rear edge. The second dorsal and anal fins are small. Tail: the upper lobe is clearly longer (heterocercal) for most species; great white and mako have a near-symmetric crescent but still have the keel.
- **Eyes.** On real sharks the eyes sit on the side of the head, forward and roughly level with the top of the mouth line (sourced only indirectly: the spiracle is "behind the eyes on top of the head", which implies the eyes are not on top). For a stylised kid-friendly look: keep them small, place them on the side just above the mouth corner line, sink them slightly under a brow overhang, and add one bright specular dot. The brow plane is what creates expression (angry tilt vs happy tilt), not eye size.
- **Teeth.** These are stylised triangle teeth. Use fewer, bigger teeth (for example 6–10 visible upper and fewer lower on the side view) of varied size: largest near the front-middle, smaller toward the corners. Seat them into a visible gum band rather than floating them on the lip. Each tooth tilts slightly and is not a perfect copy. A slightly off-white or ivory colour reads better than pure white.
- **Mouth interior.** Use a dark, saturated interior (deep red-pink or purple, not black and not bright red) with a lighter gum band and a tongue shape. The interior is the main value contrast that makes the grin read on small screens. Because the style guide bans blood, use a pink-purple hue rather than a blood red.
- **Skin.** Use hand-painted gradients: dark top, a light belly with a clean but wavy countershading border line, and a slightly lighter band along the flank. Freckles or spots should be species-specific (leopard, whale) and clustered, not evenly scattered. Avoid scars and blood per the style guide. A simple hand-painted surface plus a soft normal map beats realistic PBR skin for this style (consistent with the Habrador/Fortnite finding).

### Gaps
- No text breakdown was found from Future Games of London on Hungry Shark Evolution or World modelling rules (polycount, teeth, eye rules). The ArtStation images have to be studied visually.
- Feed and Grow: Fish, Ocean is Home, and the "Shark Simulator" mobile games returned no art-direction sources in searches.
- The Sea of Thieves megalodon and shark modelling rules, and Abzû's fish shape rules, are only in GDC videos and were not transcribed here. Watching [BzppoQTG3m0](https://80.lv/articles/gdc18-visual-adventures-on-sea-of-thieves) and the [Abzû talk](https://gdcvault.com/play/1024409/Creating-the-Art-of-ABZ) is recommended.
- No acclaimed Sketchfab stylised shark with a written breakdown was found. Search results were mainly CGTrader and RenderHub store listings, which give no craft notes.

---

## 2. Common amateur mistakes that make 3D sharks look cheap, and how pros fix them

### Takeaway
The verifiable principles are these. Avoid parallel or symmetric lines (straights against curves, S and C curves, no W or M curves). Simplify real reference rather than inventing blobs. Fix proportions and silhouette before detail. Use value, not just hue, to define form. The shark-specific mistake list is inference built on those principles and on anatomy.

### Cited Findings
- Only two line types exist, straights and curves. Curves should be S or C. Avoid "W" or "M" curves, which look awkward and break the flow. Ask of each line whether it can be "stronger, more interesting, or more exaggerated". Overlapping lines can taper to show dimension. — [Brian Lemay: Straights & Curves](https://brianlemay.com/Drawingcourse/StraightsandCurves.html)
- Fortnite's stylisation rule: "remove all parallel lines from a real-world object". Sea of Thieves: simplify everything and build complexity from simple shapes. — [Habrador](https://blog.habrador.com/2018/08/stylized-graphics-fortnite-sea-of-thieves.html)
- Set proportions before sculpting details, and keep the concept's flow lines. A darker colour with a lighter shadow value is a mistake. — [80.lv anthropomorphic shark](https://80.lv/articles/making-stylized-anthropomorphic-shark-adventurer)
- It is "easy to rush ahead and lose yourself in the details". Detail the whole body in passes so the shape language holds. When presenting, avoid neutral poses and faces and high-contrast matcaps, and use soft lighting, subtle AO and a character-appropriate expression. — [Blender Studio: Sprite Fright sculpting advice](https://studio.blender.org/blog/sprite-fright-sculpting-advice-for-production)
- Triangular shapes suggest danger or aggression and rounded shapes suggest friendliness. If a character "only reads correctly because of color, the shape system is too weak". Test in grayscale, at a distance and in motion, before adding detail. — [RocketBrush: Shape language in game character design](https://rocketbrush.com/blog/shape-language-in-game-character-design-how-to-make-characters-readable-and-consistent)

### Inferences (amateur mistake, then pro fix)
| Amateur tell | Why it looks cheap | Pro fix |
|---|---|---|
| Uniform tube or capsule body (round cross-section, fattest in the middle) | Parallel contours, no gesture | Put the mass forward (peak at about 1/3 length), flatten the belly, make the head a wedge and the tail stock tall and narrow, add a spine ridge |
| Symmetric top and bottom profile | Reads as a torpedo or blob, not an animal | Steep back curve against a flatter belly; straight against curve |
| Blobby, uniformly thick fins (extruded slabs or ellipsoids) | Fins look like rubber paddles | Wedge-section fins: thick root, knife-thin trailing edge, swept leading edge, filleted into the body |
| Tail with two equal lobes on a generic shark, or a fish-style fan tail | Breaks the "shark" read | Heterocercal tail (upper lobe longer), crescent for great white or mako, plus a caudal keel |
| Eyes on top of the head or big cartoon eyes | Reads as a frog, dolphin or plush toy | Small eyes on the side, just above the mouth line, under a brow ridge |
| No gill slits, or gills as deep straight cuts | Missing a key shark identifier, or looks scarred | Five shallow, slightly curved slits that taper at both ends and sit just in front of the pectorals |
| Teeth: many identical tiny cones in a perfect row, floating | Looks procedural and AI-made | Fewer, bigger, size-varied triangles set into a gum band, slight rotation variance |
| Flat single colour, or an exactly straight countershading line | Looks like a toy or placeholder | Top-to-belly gradient, a wavy countershading border, a value pass first, a lighter flank band |
| Over-subdivided smooth surface with no plane changes ("inflated") | Every form looks pumped with air | Keep crisp plane changes: brow, jaw line, fin edges, keel. Mix sharp and soft edges |
| Snout too round or too blunt | Reads as a dolphin or whale | A cone snout that comes to a soft point and overhangs the mouth (mouth sits underneath, behind the snout tip) |

### Gaps
- No Polycount critique thread on shark models could be retrieved (the fetch failed). The table above is reasoning, not a quoted source.

---

## 3. What makes models read well at small size and on phone screens

### Takeaway
Readability comes from **value contrast and silhouette first, colour second**. Characters should be the brightest, highest-contrast elements against the background. Fine detail should stay within a narrow value range so it does not compete. Test everything in grayscale at small size.

### Cited Findings
- Use value (light against dark, not hue) to separate characters from the scene. In DOTA 2 "the heroes and units are the brightest and highest areas of contrast". "Too much contrast in too many places is equally confusing." Keep detailed areas within a narrow light-to-dark range. Test readability by desaturating the scene. — [Icewyrm Games: Reducing Visual Confusion](https://icewyrmgames.github.io/research/reducing-visual-confusion-in-your-game) (also on [Game Developer](https://gamedeveloper.com/design/how-to-reduce-visual-confusion-in-your-game))
- Silhouette tests: grayscale, distance and low light, motion. Validate in-engine at the blockout stage. — [RocketBrush](https://rocketbrush.com/blog/shape-language-in-game-character-design-how-to-make-characters-readable-and-consistent)
- Fortnite's scale rule: don't add anything smaller than a mailbox as a gameplay object, because small things clutter. — [Habrador](https://blog.habrador.com/2018/08/stylized-graphics-fortnite-sea-of-thieves.html)

### Inferences
- For a phone-sized shark (often under 150 px long), only about five features survive: the silhouette (dorsal fin plus crescent tail), the light belly against the dark back, the open mouth (dark interior plus white teeth: the highest-contrast spot), the eye glint, and one species marking. Exaggerate those and drop the rest (fine scales, small wrinkles).
- In an ocean scene with blue-green mid-values, give the shark a darker top and a much lighter belly so it pops in both top-down and side views. A subtle Fresnel or rim light, or a light top edge, separates it from the water. In Roblox this can be approximated with a Highlight instance or a lighter painted edge.
- Keep teeth few and large so they read as one bright zigzag, not as grey noise.
- Use at most 3–4 main colour zones per shark (back, belly, accent marking, mouth). Use saturated hues, but keep their values clearly separate.

### Gaps
- No Hungry Shark mobile-specific readability statements, polycounts or texture sizes were found. The inkl article on mobile character fidelity could not be fetched.

---

## 4. Art-direction talks and breakdowns (GDC, 80.lv, ArtStation, Polycount)

### Takeaway
There are a few relevant, verifiable talks and breakdowns, but the most useful (Abzû and Sea of Thieves) are video-only. Hungry Shark's ArtStation pages are the closest look at the franchise's 3D shark process.

### Cited Findings
- GDC 2017 "Creating the Art of ABZÛ" by Matt Nava. — [GDC Vault](https://gdcvault.com/play/1024409/Creating-the-Art-of-ABZ); [80.lv summary](https://80.lv/articles/gdc-2017-creating-the-art-of-abzu); [80.lv interview with Abzû creative director](https://80.lv/articles/interview-with-the-creative-director-of-abzu/) (not fetched)
- GDC 2018 "Visual Adventures on Sea of Thieves" by Ryan Stevenson (Rare). — [GDC Vault](https://gdcvault.com/play/1025015/Visual-Adventures-on-Sea-of); [80.lv](https://80.lv/articles/gdc18-visual-adventures-on-sea-of-thieves); SIGGRAPH 2018 talk "The Technical Art of Sea of Thieves" — [PDF](https://history.siggraph.org/wp-content/uploads/2022/09/2018-Talks-Ang_The-Technical-Art-of-Sea-of-Thieves.pdf) (not fetched)
- Hungry Shark high-poly concept sculpts (art director Pete Kempton, FGOL) — [ArtStation](https://ichidan.artstation.com/projects/nY9WmE); Hungry Shark World Apex sharks — [ArtStation](https://ichidan.artstation.com/projects/rJxnJE)
- Maneater development breakdown — [80.lv](https://80.lv/articles/sharks-and-blood-how-maneater-was-developed)
- Subnautica 2 Collector Leviathan creature pipeline vlog — [Unknown Worlds](https://unknownworlds.com/news/subnautica-2-dev-vlog-3)
- Stylised shark character workflow (value pass, hand-paint over bakes) — [80.lv](https://80.lv/articles/making-stylized-anthropomorphic-shark-adventurer); stylised shark in Blender and Substance — [80.lv](https://80.lv/articles/take-a-look-at-this-stylized-shark-created-with-blender-substance-3d)

### Inferences
- The best next step for visual reference is to study (not copy) the Hungry Shark ArtStation sculpts at side, top and three-quarter views, noting snout length to body ratio, eye height against the mouth line, and fin root thickness. Then build MEGA BITE's own measured proportion sheet.
- Since the Reef Shark is "built by code" (parametric parts), the biggest quality jump probably comes from: (a) a non-circular, forward-weighted body loft profile, (b) wedge-profile fins blended into the body, (c) a brow ridge and a mouth set under the snout, and (d) a painted gradient texture instead of flat part colours. Primitive-assembled sharks usually fail on all four.

### Gaps
- No Polycount thread or GDC talk specifically on Hungry Shark art was found. No 2025–2026 talks on stylised sea creatures turned up in this pass.
