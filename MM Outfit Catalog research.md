---
project: MM Outfit Catalog
date: 2026-11-15
tags: [roblox, ui, research, clothing]
---
# MM Outfit Catalog research

## Project decision

Make the three original outfits easy to browse and inspect. Use the approved cobalt and cyan reference for Outfit ID. Give players a clear response when they act and keep animation away from the garment while they inspect it. The library can stay small because the shop is curated. Research on choice overload found substantial variation and a near-zero average effect, so the catalog size is a product decision, independent of a claimed universal psychology benefit. [Choice overload meta-analysis](https://doi.org/10.1086/651235)

## Video research log

| Reference and timestamp | What to apply | Coverage |
|---|---|---|
| [Chrome for Developers, Motion design in UI](https://www.youtube.com/watch?v=jWur1VrxNUg&t=390s), 6:30–10:30 | Press feedback, selection state and a brief directional sheen each communicate a different event. | Exported captions reviewed, sampled visuals, and verified the player covered the full runtime. |
| [Ross Tregenza, UI sounds](https://www.youtube.com/watch?v=0Ljf3KKhi6g&t=250s), 4:10–8:30, 19:40–22:30 | Give UI audio a tactile onset and distinct meanings. Keep the accent small enough to sit with the showroom jazz. | Exported captions reviewed and playback sampled. |
| [Code, Roblox UI scaling](https://www.youtube.com/watch?v=y2Q9iF1LEfo), 0:10–1:30 | Centered anchors and responsive constraints. Keep hit targets at a minimum size while changing the panel geometry. | Exported captions reviewed and playback sampled. |
| [Rileybytes, Shiny UI Buttons](https://www.youtube.com/watch?v=8F3oW_Z6ffE&t=120s), 2:00–5:30 | Clip the sweep to the control and keep the label on a clear layer. Use a single pass triggered by interaction or a result. | Exported captions reviewed and playback sampled. |
| [Laumire, Seven shading techniques](https://www.youtube.com/watch?v=oAoL_U3y8nc) | Use edge shading for construction, larger fold shapes for volume, and restrained fabric detail. | Sampled visual demonstrations. Captions are mainly music markers. |
| [Contrastz, Shirt Shading](https://www.youtube.com/watch?v=HIMrOrctlw8&t=74s), 1:14–3:38 | Separate shadows and highlights, mask the folds to the correct panel, and vary their placement as the material wraps. Use original or licensed textures. | Exported captions reviewed, sampled visuals, and verified the player covered the full runtime. |

The log records reviewed evidence. Continuous observation of every video was not verified. No full audio files or frame sequences were extracted. YouTube's player did not provide exportable media in the tested download and its terms limit external copying. Use source playback and timestamped notes for these references. [YouTube terms](https://www.youtube.com/t/terms)

## Ten UI patterns ranked for this catalog

Rank is an implementation judgment based on how often the action occurs, what information the effect communicates, and its impact on the avatar view. Timings are starting values for this game.

| Rank | Pattern | Catalog behavior |
|---:|---|---|
| 1 | Press and release | Compress slightly on press, settle quickly on release. Keep the target position stable. |
| 2 | Active tab state | Keep the selected tab visually distinct even with motion off. |
| 3 | Keyboard and gamepad focus | Use a visible outline alongside pointer hover. |
| 4 | Immediate validation | Show a readable message and input border for a bad ID. Keep the input editable. |
| 5 | Loading state | Show status immediately once a valid ID is submitted. Keep the text static when Reduce Motion is enabled. |
| 6 | Preview reveal | Confirm a successful load with a brief accent at the result and a small sound if enabled. |
| 7 | Panel entrance | Fade the backdrop and settle the panel in about 180–200 ms. |
| 8 | Directional sheen | Clip a brief sweep to the Outfit ID header and keep text in front. |
| 9 | Tab content transition | Use a brief fade only if the state swap needs clarification. Avoid shifting the position of touch targets. |
| 10 | Card sequence | Consider a short nonblocking stagger on initial open only. Keep cards static during scroll. |

The current build already has press, focus and panel entrance. Next Studio pass should emphasize distinct success and failure feedback, a shared sound preference, and a single preview accent. Remove repeated purchase pulsing during inspection. Use Roblox Reduce Motion for cosmetic transitions and preserve readable state feedback for every action. [Roblox UI animation](https://create.roblox.com/docs/ui/animation) · [Roblox accessibility](https://create.roblox.com/docs/production/publishing/accessibility) · [Riot sound design](https://www.riotgames.com/en/artedu/sound-design)

## Mobile and PC layout comparison

Synthetic geometry model for three layouts and nine usable viewport sizes. Assume a side panel width of 20% clamped to 150–320 units, or a bottom sheet height of 36% clamped to 180–260. Reserve another 24 units on the affected axis for margins. A scenario passes when it leaves at least 60% of the available width and 55% of portrait height, 65% of non-PC landscape height, or 75% of desktop height for the avatar area. These are project thresholds chosen to screen layouts. The model does not include actual hand reach, render framing, Roblox controls, or player choices.

| Viewport | Profile | Always side | Always bottom | Adaptive |
|---|---|---:|---:|---:|
| 320×480 | phone portrait | 146 × 480 | 320 × 276 | 320 × 276 |
| 360×640 | phone portrait | 186 × 640 | 360 × 386 | 360 × 386 |
| 390×844 | phone portrait | 216 × 844 | 390 × 560 | 390 × 560 |
| 568×320 | phone landscape | 394 × 320 | 568 × 116 | 394 × 320 |
| 667×375 | phone landscape | 493 × 375 | 667 × 171 | 493 × 375 |
| 844×390 | phone landscape | 652 × 390 | 844 × 186 | 652 × 390 |
| 1024×768 | tablet | 796 × 768 | 1024 × 484 | 796 × 768 |
| 1366×768 | PC | 1069 × 768 | 1366 × 484 | 1069 × 768 |
| 1920×1080 | PC | 1576 × 1080 | 1920 × 796 | 1576 × 1080 |

| Layout | Phone | Tablet | PC | All |
|---|---:|---:|---:|---:|
| Always side | 3/6 | 1/1 | 2/2 | 6/9 (67%) |
| Always bottom | 3/6 | 0/1 | 0/2 | 3/9 (33%) |
| Adaptive | 6/6 | 1/1 | 2/2 | 9/9 (100%) |

The adaptive layout gives 360 instead of 186 horizontal units to the avatar at 360×640, while landscape and desktop keep the full vertical display area. Keep the key controls at 48 GUI units high, verify actual touch reach on phones, and watch for overlap with Roblox's inset and movement controls. Pixels on the Studio layout do not establish a physical hit target size. [Roblox adaptive design](https://create.roblox.com/docs/production/publishing/adaptive-design) · [Roblox thumb zones](https://create.roblox.com/docs/ui/position-and-size)

For a player test, counterbalance layout order and give each participant the same tasks. Open a featured outfit, identify its shirt, switch outfits, and close. Record completion, wrong taps, time, and whether they needed a grip change. Ask which layout they liked best and rate comfort independently from 1 to 5. Report preference as votes divided by participants, comfort as 4–5 ratings divided by ratings, and sample size by device. Real participant data is pending.

## Shirts, pants and visual perception

Roblox's 2025 report found Y2K searches rising and 47% of surveyed Gen Z Roblox users changing avatars to express creativity. That supports exploring several styles and offering a try-on. It supplies no estimate of demand for Moth Grunge or the preferences of younger players. Research across 30 nations found shared color associations with geographic and linguistic variation. Describe the intended mood, and measure actual garment preference in context. [Roblox Replay](https://about.roblox.com/newsroom/2025/12/roblox-replay-decoded-search-style) · [Jonauskaite et al.](https://doi.org/10.1177/0956797620948810)

- **Primary shirt concept:** washed charcoal, one light moth graphic as the dominant shape, striped undersleeves, seam wear and a few oxblood repairs. Dark values convey the intended grunge look. Contrast at the wings helps recognition at thumbnail size.
- **Test variants:** compare a brighter bone moth against muted ash while holding design, avatar, pose, pants, camera and lighting constant. Compare a washed olive colorway separately. For pants, test the same denim with and without the diagonal repair patch. Ask participants which they would wear and what detail they noticed first.
- **Texture construction:** mask fold shadows and highlights separately, then keep wear concentrated at the neckline, sleeve ends and hem. On pants, use larger creases at knees and hips, edge wear at pockets, and one patch with a consistent seam. Let the moth silhouette and sleeve bands speak at a distance and reserve grain and thread for zoom.
- **Release gate:** the approved Moth Grunge image is a concept and the generated artwork is a texture master. Fit each panel to the official classic atlas, verify all sleeve stripes and hem seams on rotating R6 and R15 rigs, and compare neutral and showroom lighting. Classic clothing paints the body surface. A sculpted silhouette requires 3D clothing. Keep the three curated looks as the shop inventory until new clothing passes the fit check. [Roblox classic clothing](https://create.roblox.com/docs/avatar/classic-clothing)

## Studio acceptance checks

1. Invalid ID shows a clear message and border. Valid ID shows a loading state, then the avatar. Sound off stays silent across both the wardrobe and the outfit viewer.
2. No repeated glow in the shopping pane while inspecting clothing. The success accent plays once and respects Reduce Motion.
3. Portrait retains the lower item panel and landscape/PC retain the side column. The wardrobe launcher is hidden during outfit preview. Verify both open and close through the ordinary buttons.
4. Clothing should be reviewed on a wrapped rig and at catalog thumbnail size before listing.

