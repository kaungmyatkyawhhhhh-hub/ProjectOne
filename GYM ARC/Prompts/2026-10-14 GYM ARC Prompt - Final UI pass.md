---
date: 2026-10-14
tags: [gymarc, prompt]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-14 GYM ARC Prompt - Final UI pass

Saved exactly as sent:

```text
Read C:\Users\kaung\Downloads\GYM_ARC_UI_final.md and look at every image in Downloads\gym_arc_ui_final first. Do the Store first as the reference, then Quests, Coaches, Physique, HUD, Lifting, and the title screen last. Commit after each.
```

The brief it points to (Downloads/GYM_ARC_UI_final.md), saved exactly:

```text
FINAL UI KIT: "BLACK + GOLD". This replaces ALL earlier UI prompts (grit/concrete, Gym League, premium, etc.). Layouts stay the same as the current build; only the materials/look change.
Mockups (source of truth): C:\Users\kaung\Downloads\gym_arc_ui_final\ (00_title, 01_hud, 02_lifting, 04_store = the reference frame, 05_quests, 06_coaches, 07_physique). Look at all first. Save this prompt to Obsidian. Commit after each screen. Do the Store first, then the others, title screen last.

MATERIALS
- Panels: dark graphite, vertical gradient #252226 (top) -> #18161A -> #0D0C0E (bottom), very faint vertical brushed lines (tiled texture or UIGradient stripes, ~2% contrast), a 1px light hairline along the top edge (white ~78% transparent), corner 14, soft dark shadow underneath. No tape, no marker, no concrete, no stencil.
- Tiles/cards inside: #232023 -> #141215, 1px top highlight, darker bottom lip, corner 11.
- Font: one heavy italic athletic display font for titles, names, buttons and numbers: GothamBlack (italic look via the font or a slight skew) / Enum.Font.GothamBlack. Small body text: Gotham Medium, gray #8D8387-#A39A9D.
- Gold = gradient (#FFF3C4 highlight -> #F6C75A -> #C98A12 -> #F2C45A) with a glint. Used for active tab, hero names, rewards, big numbers, rank plates.
- Red only for the hype/CTA button on each screen. Teal only for progress/stamina.

BUTTONS (the premium moment)
- CTA (REP, CLAIM, PLAY, featured BUY, TAP TO GROW in gold): crisp bevel, glossy top lip (white gradient on the top 44%), darker bottom inner lip, hard-edged dark drop (4px, no blur) + soft colored glow, a diagonal shine streak. Hover/press: scale 1.04 / 0.96. On appear: shine sweeps across once.
- Everything else quieter: dark "quiet" buttons with a top highlight; inactive tabs FLAT (no bevel, no shadow, darker, gray text) so the gold active tab pops.
- Prices on normal items sit in a small dark pill (black, thin inner highlight), bigger and bolder than before.

SCREEN NOTES
- Store: hero Auto Rep tile with thick 2.5px gold border + soft gold outer glow, bigger art (no dead space under BEST SELLER), red R$ 249 CTA. Grid tiles dark glossy with price pills. OWNED = rotated gold stamp; dim that tile's icon and name so the stamp is the only bright thing. Hide the HUD coin counter while a full panel is open (the panel has its own).
- Quests: claimable row gets a gold border + glow and the red CLAIM; in-progress shows "1 / 2" pill; done is faded with teal DONE. Bonus card with a big gold number.
- Coaches: active coach tile is ~7% larger with a gold frame + glow and "COACHING" in gold; owned = EQUIP quiet button; locked = grayscale + lock icon + price pill.
- Physique: fat outlined bars with a metallic fill (gradient with a highlight), rank letter as a small gold plate, big gold 71%.
- HUD: dark glass menu tiles with colored line icons (Shop gold), red dot notifications, gold TAP TO GROW CTA with glow, teal stamina.
- Lifting: weight card panel, metallic gold pump bar, red REP CTA, quiet STOP.
- Title: graphite panel with the logo image, red PLAY CTA, gold SHOP, quiet UPDATES (red dot), player row (real avatar headshot) at the bottom, small NEW news tag bottom-right. No tape anywhere.

LET THE GYM SHOW
- Panels ~10-15% smaller than before, centered. Behind each panel a soft dark radial vignette + light blur only around the panel (not full screen), so the brick and racks stay visible at the edges.

MOTION (last 10% of premium)
- Panel open: scale 0.96 -> 1 + fade, 0.18 s. Hero tile: one shine sweep on open.
- Featured CTA (R$ 249, CLAIM, TAP TO GROW, PLAY): subtle pulse (scale 1 -> 1.03, glow brighter) every 1.6 s.
- Claim: coins fly to the counter + small gold sparkle burst. Reduce-motion toggle in Settings turns loops off.
Phone 844x390 first. Screenshots next to the mockups in screenshots/ui_compare_final/.
```
