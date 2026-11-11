# Fisch models: direct visual check (screenshots viewed in the built-in browser, 9 Nov 2026)

The text-only researcher could not view images. These observations come from looking at in-game screenshots of Fisch (YouTube thumbnails / gameplay frames found via Bing Images, queries "fisch roblox megalodon fish model" and "fisch roblox bestiary fish models great white shark").

## Takeaway
Fisch's sharks are **low-poly, flat-shaded (faceted) models with hard edges and 2-4 flat colour regions**, not smooth subdivided "Pixar" models and not painted textures. The quality comes from strong angular shapes, a clean two-tone colour split, a glowing eye and a big open toothy mouth, all of which read instantly in Roblox's lighting and on phones.

## What the Megalodon looks like (gameplay frame, "Catching the new Megalodon fish on roblox Fisch", YouTube, ~1 yr ago)
- **Geometry:** low-poly; every face is visible as a flat facet (no smooth shading); hard edges everywhere. Few polygons but well placed.
- **Head:** a wedge with a flat top plane and an angular brow ridge that hoods the eye; the snout is a blunt faceted cone.
- **Eye:** a glowing cyan/light-blue emissive eye (the brightest point on the model), under the brow.
- **Mouth:** wide open, dark maroon/brown interior, a row of white triangular teeth on the top AND bottom jaw (a zig-zag), reaching back under the eye.
- **Colour:** two flat colours: deep navy/steel blue on top, white belly. The boundary is a **zig-zag / jagged line** (looks like the low-poly edge between two vertex-colour regions), running from the mouth corner along the flank to the tail.
- **Details:** dark gill slits as cut-in lines behind the mouth; fins are thin angular plates (dorsal tall triangle, long pectorals, angular crescent tail with the upper lobe bigger).
- **Scale:** huge next to the player's boat (a hunt/boss fish); seen from 20-60 studs.

## What the Great White looks like (thumbnails "Fisch: How To Catch The Great White Shark", "GREAT WHITE SHARK (BEST ROD)")
- Same style: low-poly faceted, grey top / white belly in flat colours, long slender body, tall triangular dorsal, crescent tail, small mouth line; no texture detail at all.

## Other Fisch-style notes
- Variants are recolours / material swaps (the Phantom Megalodon is a translucent/neon version; a red "Ancient"-style one appears in thumbnails), matching the DevForum Creator Spotlight (fish recoloured per part by script).
- The look fits Roblox's own plastic, sunlit aesthetic: SmoothPlastic-like surfaces with flat colours, so models look "native" and clean.

## Implication for MEGA BITE (inference)
- Our smooth subdivided shark fights the Roblox look and still looks "inflated". The proven Roblox route is **low-poly + flat shading + per-region flat colours (or a tiny palette texture) + emissive eyes + a big toothy open mouth**, with angular planes on the head/brow/jaw.
- This is also much easier to do well by code: fewer vertices, deliberate facets, colour per face region instead of baked gradients.
