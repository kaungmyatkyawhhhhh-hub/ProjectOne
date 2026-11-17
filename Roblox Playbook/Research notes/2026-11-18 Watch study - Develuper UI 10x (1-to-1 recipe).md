# Watch study - Develuper "Make Your Roblox UI Look 10x Better" (1:1 recipe)

- Video: https://www.youtube.com/watch?v=F6AtQKo3uIY. Develuper, posted 21 Aug 2026, 7:03 long, about 168k views and 4.9k likes when watched.
- Watched 18 Nov 2026 by downloading it, pulling frames and transcribing it with Whisper. The audio is English.
- Why: the owner said "we need to do 1:1 to the tutorial tips, i like those ui designs". This replaces the rejected v3 Figma kit and the ChatGPT sandstone art for EVOLVE.
- Files:
  - Frames are in `frames-develuper-ui/`: t_266 is the RETRY button with its panel values, t_310 the full store, t_348 the store close-up, t_376 the parts sheet, and t_252 the halftone source.
  - The full transcript is `frames-develuper-ui/transcript.txt`.
- Earlier, lighter note: [[2026-11-14 Watch study - Develuper tutorials (UI, lighting, VFX, animation) + Dodge or Die story]].

## The two rules (1:07)
Every piece needs two things.
- **Identity:** colour, shape, typography and texture.
- **Depth:** it should look like a 3D button.

## Button recipe, step by step (1:35-4:26)
1. **Rectangle with slightly rounded corners.** The radius is small, about 12-16 px on a 509x147 button. It is not a pill.
2. **Fill: a vertical gradient.** Use saturated colours with the brightest at the top. The example is yellow `#FFE600` at the top to orange `#FF9A00` at the bottom.
3. **Depth lip:**
   - Ctrl+D to duplicate, then Shift-drag it straight down. The lip is about 14% of the height (about 20 px on 147).
   - Keep the copy **behind** the face and make it darker. The example uses `#AA5000` under the yellow.
4. **Flatten** the face and lip into one shape. Give it a **black stroke, Outside**, with weight **4.5** on a 509 px button (the panel in t_266 shows this).
5. **Text:**
   - Font: **Fredoka One**, white.
   - Thick black stroke.
   - The **same depth trick**: a black copy offset straight down behind it.
6. **Icon:**
   - Get it from UI resource sites or Google. It must be an **SVG** so its colour can change; vectorize it with a plugin if it isn't.
   - Colour it white, with a black stroke and the same depth copy.
7. **Shine:**
   - Put an invisible frame the shape of the button to work as a **mask (clip content)**.
   - Inside it, draw **diagonal light stripes** (wide bands at about 60°).
   - Set them to a **blend mode** (Overlay or Soft light) so they read as a subtle sheen.
8. **Texture:**
   - Add a **halftone dot pattern** inside the same mask, also on a blend mode.
   - It comes from the "UI Resources" site (Effects, Halftones; frame t_252). The dots look like a diagonal diamond grid that fades.
9. **Edge highlight** ("makes a surprisingly big difference"):
   - Make a second invisible frame the same shape as the face.
   - Give it an **Inside stroke** of light colour (white, about 3 px) on a blend mode.
   - It shows as a thin bright inner rim just inside the black outline.
10. **Sparkles:** small stars from UI Resources, inside the mask, on a blend mode.
11. **Optional drop shadow:** X 0, Y 6, Blur 4, black at 25% (panel values in t_266).

## Store layout (4:46-6:00; frames t_310 and t_348)
- **Top bar that stands out:** a green gradient **"STORE!"** header bar sits at the top-left, overlapping the panel. It uses big Fredoka, the same depth trick, and a 3D icon (a basket).
- **Red "Close" text button** at the top-right, in the same button style. It is the word "Close", not an X.
- **Panel background:** white "with some details" (a light grey inner border and rounded corners), or a semi-transparent black. White gives more freedom with the card colours.
- **Main item bigger, more prominent and first:**
  - It is a tall yellow "BUNDLE!" hero card on the left, about 2 rows tall.
  - It has a big title, big art, a "+50% Gems" description, and a wide price button.
- **Smaller, less attractive items afterwards:** a 3x2 grid of small cards.
- **Every item card has:**
  - its own **saturated colour tile** with a gradient, a black outline, the depth lip, and the halftone texture;
  - a white title with a black stroke at the top;
  - a short description if it bundles several things;
  - a **large image** of the item, with "x2" style counts;
  - a **green price button** ("green is just the color of money");
  - a **currency icon** in the price (the Robux hexagon, or a coin for soft currency).
- **Card colours used:**

  | Card | Colour |
  |---|---|
  | Bundle hero | yellow → orange |
  | Epic | magenta → red |
  | Rare | purple → blue |
  | Common | green → cyan |
  | Cash | cyan → blue |

  The colour itself tells the player the tier.
- **The key idea is contrast:** colour cards and green buttons on a white panel.

## Figma to Roblox (6:06-6:50)
- **Export every image separately** at the biggest size **just under 1024 px**, because Roblox downscales larger images.
- **Upload in Studio's Asset Manager** (bulk import) to get ids.
- **Rebuild the structure in Studio** with ImageLabels and ImageButtons. Develuper calls this "the annoying part".
- Even he says the result "could look a little sharper". Use the 1024 exports, and 9-slice only the plain parts.

## How to apply this to EVOLVE
- Make one green STORE! style header per window: SHOP, DIET, INDEX.
- Use the red **Close** text button.
- Use a white panel.
- Shop:
  - Make **VIP** the big hero card (yellow) on the left.
  - Put the other passes and products in small colour cards: DoubleDNA magenta, FastLife purple, OfflinePlus blue, Skips/DNAPack cyan.
  - Every price goes on a green pill with the Robux hex icon.
- HUD buttons: the same recipe at a smaller size (yellow, green and blue variants).
- The halftone, shine and edge highlight go on every piece, not just the hero.
