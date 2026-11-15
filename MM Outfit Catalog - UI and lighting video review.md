---
project: MM Outfit Catalog
date: 2026-11-15
tags: [roblox, ui, lighting, research]
---
# MM Outfit Catalog — Modern UI and Studio lighting video review

Related: [[MM Outfit Catalog research]]

## Five UI videos

1. **[Develuper — Make Your Roblox UI Look 10x Better](https://www.youtube.com/watch?v=F6AtQKo3uIY&t=69s)** (7:02). At 1:09–2:24, the button gets a recognizable palette, a bright upper face, a darker base and an outline. At 3:20–4:19, it gains shine and an inner edge highlight. The shop example at 4:47–6:00 gives the product image and price visual priority. For MM, keep cobalt and cyan on the Outfit ID module, give primary buttons a clear top edge, and give each outfit thumbnail more room than its description.
2. **[Develuper — Make this clean and modern UI in Roblox Studio](https://www.youtube.com/watch?v=AFUpmQtmPr4&t=64s)** (7:47). At 1:04–2:16, a horizontal layout and aspect constraint organize a compact hotbar. At 3:46–6:45, hover, hold and release have separate states. For MM, preserve layout-driven cards, use a focus ring on pointer and gamepad, and use short press feedback on touch. Keep a minimum target size alongside proportional layout; scaling every control down would make it harder to tap.
3. **[Roblox Creators — UI/UX Essentials](https://www.youtube.com/watch?v=lOOvOIJoMi4&t=128s)** (16:44). At 2:08–3:18, prioritize the information and actions needed in the current context. At 7:31–9:22, button conventions and readable text get priority. The Berry Avenue example at 14:11–15:30 follows the full customization path and shows how reducing friction can require changes across screens. For MM, test browse → preview → identify shirt and price → return as one task. Restore browse context and use consistent close and back controls.
4. **[Rileybytes — How To Make Shiny UI Buttons That Pop](https://www.youtube.com/watch?v=8F3oW_Z6ffE&t=115s)** (7:32). At 1:55–3:05, the author positions the sheen beneath the label and clips its overflow. At 4:54–5:30, the corners expose a masking issue. For MM, use a brief sweep on the Outfit ID header, reserve the effect for focus or confirmation, and check clipping at both ends and at the corner. Keep the tap target stable while the sheen moves.
5. **[Code — How to Scale UI for All Devices in Roblox Studio](https://www.youtube.com/watch?v=y2Q9iF1LEfo&t=10s)** (1:45). At 0:10–0:49, the UI is shown at different emulated sizes. At 0:50–1:29, an aspect constraint preserves shape and changing the anchor point changes how resizing behaves. For MM, switch from side-by-side cards to a stacked list when width runs out. Keep the Preview and Close targets usable on small screens and retest rotation.

## Three lighting videos

1. **[Develuper — Make Your Roblox Game Look 10x Better With Lighting](https://www.youtube.com/watch?v=vkEXLmRAQgs&t=27s)** (4:36). At 0:27–1:36, lighting style, ambient colors, sun direction and atmosphere each change the scene in a different way. At 1:42–2:37, bloom, sky and grading are introduced after the base. For MM, block in the showroom's direction and warmth first and adjust atmosphere through the windows. Compare any lighting style changes on a lower graphics setting as well.
2. **[Harp Seal — How To Make Realistic Lighting](https://www.youtube.com/watch?v=8h8ene2Hd0c&t=62s)** (4:00). The on-screen settings cover bloom at 1:02, depth of field at 1:29, color correction at 1:51, and finish with a before-and-after at 3:27. The captions are mainly music markers, so rely on the visible demonstrations and the creator's chapter markers. For MM, evaluate the effects one at a time. Bloom belongs on practical lights or windows. Blur can hide stitching and fabric detail in an outfit preview. The example is from 2021, so use the current Lighting documentation for property names.
3. **[DatBoiEle — The Ultimate Lighting Tutorial](https://www.youtube.com/watch?v=aq0Fi0R2FAY&t=131s)** (21:16). At 2:11–3:38, choose the lighting situation and sun position before adjusting the ambience. The 7:37–9:32 section adjusts bloom, grading and window treatment, and 19:46–20:57 summarizes the workflow from scenario and sky through local shadows and finishing effects. For MM, use cool rainy windows with warmer practical lighting indoors. Put a neutral key and gentle fill on the display avatars so dark denim remains visible, and use a rim light for separation. Keep the menu readable when it overlaps bright scenery.

## MM Outfit Catalog decisions

- **Catalog:** Show the three outfits as the main content. Use a consistent image crop and one clear Preview action per card. Show item names and price or Preview only directly where players inspect a fit.
- **Outfit ID:** Keep the approved cobalt header, cyan edge and pale input well. Give the main button physical depth and keep the label clear when the sheen crosses nearby. Use still focus and status states when Reduce Motion is on.
- **Showroom:** Compare warm display lights with cooler windows before adding atmospheric effects. Preserve readable faces and silhouettes at spawn, on the walkway and at each pedestal.
- **Inspection:** Use a repeatable camera framing and neutral key light. Compare Midnight's black folds, Frost's light print, and Sakura's pink sheen from the front, side, and at zoom. Look for blown whites and lost shadow detail.
- **Checks:** Compare phone portrait, phone landscape and PC with UI over bright and dark backgrounds. Check avatar thumbnail, outfit name, action, price and return navigation. Test lighting on low and high graphics settings. Verify that the scene looks ready on the first visible frame of preview.

Official references: [Roblox UI implementation](https://create.roblox.com/docs/tutorials/curriculums/user-interface-design/implement-designs-in-studio) · [Global lighting](https://create.roblox.com/docs/environment/lighting) · [Indoor lighting](https://create.roblox.com/docs/tutorials/use-case-tutorials/lighting/enhance-indoor-environments) · [Post-processing](https://create.roblox.com/docs/environment/post-processing-effects)

## Review coverage

I reviewed timestamped captions and sampled visuals from all eight videos. The player reported continuous playback through the end for the clean UI tutorial, the UI scaling tutorial, and Harp Seal's lighting tutorial. The two Develuper “10x Better” videos advanced to the next video after playback. I verified the end screens for the Roblox Creators, Rileybytes, and DatBoiEle videos. The longer reviews used chapter sampling and captions, and I did not verify uninterrupted playback for those three.

