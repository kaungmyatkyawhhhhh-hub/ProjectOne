---
name: "roblox-chatgpt-art-pipeline"
description: "Use when making Roblox game art (icons, UI frames, decals, textures, VFX, flipbooks): Claude writes one-try ChatGPT prompts, runs them in Chrome, then cuts, cleans and uploads."
---

# Roblox art via ChatGPT: the pipeline

ChatGPT (image generation, in the owner's Chrome) makes the RAW images from Claude's prompts. Claude does everything else: plan, prompts, cutting, cleaning, making textures seamless, QA, upload, wiring. Claude decides; it asks only about style direction, spending or publishing.

Vault references (read first if available): `Roblox Playbook\Prompt for a friend's Claude - ChatGPT art pipeline for Roblox.md`, game prompt notes such as `...ChatGPT UI art prompts...`, and `Assets\ui\hud` (the processed examples).

## 1. Plan + style lock
- List the needed assets and group them into SHEETS (one image = 4-16 related pieces).
- Write a STYLE BLOCK from the references the owner likes (e.g. "chunky glossy Roblox simulator UI like the hotbar: thick glossy bevelled coloured rims, very dark navy-violet glossy insides, thick dark outline, white top highlight, tiny sparkles"). Paste it into EVERY prompt. Save it in the game's notes.

## 2. One-try prompts (the owner's rule: they must work first time)
- "Create ONE image, 1536x1024" (2048x2048 for 4x4 icon grids). Exact layout: "TOP ROW: ... BOTTOM ROW: ..." or "an exact 4x4 grid", "each centred in its own cell with wide empty space, no overlap".
- "NO text, NO numbers, NO letters anywhere". Text is added in-game.
- Background rule:
  - UI frames, panels, buttons and decals with dark insides → flat solid MAGENTA #FF00FF, "no gradient, no shadow on it, no magenta in the art".
  - Icons and VFX (glow, sparks, smoke, auras, flipbooks) → pure BLACK #000000.
  - Tileable textures → "seamless tileable, edge to edge, no border, flat even lighting, top-down".
- Describe each piece concretely (shape, material, colour, what's inside), then the STYLE BLOCK, then "NOT a photo".
- Flipbooks: "an exact 4x4 grid of 16 frames of <effect>, left-to-right top-to-bottom, the same size and centre in every cell".
- Never "AI-looking": if a piece is off, rewrite THAT piece's description more precisely; no blind retries.
- Layout so cutting works: 6-9 pieces per sheet, well apart, NOT touching the frame edges, no drop shadows (touching or edge-touching pieces merge into one region).
- Key colour: magenta by default. If the art itself is pink/magenta, use pure green #00FF00 or cyan #00FFFF instead, and say "no <key colour> in the art".
- CONSISTENCY across batches: ChatGPT's current image model has no native transparent background ("transparent background" in a prompt usually gives a white box), so keep keying. For later batches, ATTACH the approved sheet as a reference image ("match this exact style") instead of only re-describing it. Paste the STYLE BLOCK unchanged.
- Flipbooks are ChatGPT's weak spot (frames drift). Treat them as key poses: re-centre/scale per frame, and prefer code-made VFX (particles, beams, tweened sprites) for smooth loops.

## 3. Run in ChatGPT (Claude in Chrome)
- Start a new chat per sheet, find the composer, type the prompt (one paragraph; Enter sends), and send. If the Enter didn't send, use the Send button.
- Poll with JS for `main img[alt^="Generated image"]` (screenshots may time out; use JS/get_page_text).
- Download: fetch the img src blob and click an `<a download="galaxy_<sheet>.png">`. It lands in the owner's Downloads folder (a connected folder), then stage it into the workspace.
- **No-download route (proven 11 Nov, MEGA BITE UI v5): do everything in the browser.** Fetch the generated image blob in the ChatGPT tab, key + cut it there with canvas JS (see 4b), then hand the pieces to a Roblox tab: chatgpt.com can't call apis.roblox.com (CORS) and `window.open` from script is popup-blocked, so inject a big button into the ChatGPT page whose onclick does `window.MB_child = window.open('https://create.roblox.com/dashboard/creations?activeTab=Image', '_blank')`, really click it (a user gesture), add a `message` listener in the new tab that stores blobs, then `MB_child.postMessage({name, blob}, 'https://create.roblox.com')` and upload from that tab (section 5).
- **Attaching references to ChatGPT:** the file input only accepts files this session may read: the vault (staged into `/mnt/user-data/uploads/...`) or attachments, NOT the outputs folder. Commit the reference into the vault first (e.g. `<Game>/UI/<version>/`), stage it, then `file_upload` it.
- **One chat per art set:** send the first prompt, then every follow-up in the SAME chat with "same exact style as the image you just made" = consistent pieces without re-describing the style.

## 4. Process (Python: Pillow, numpy, scipy)
- **MAGENTA key:** colour distance d to (255,0,255). Background = the connected component(s) of d<70 that TOUCH THE IMAGE BORDER (flood fill). Soft edge = a 3 px band, alpha = clip((d-45)/70). Un-mix the fringe: rgb = (src-(1-a)*M)/a in the band only. NEVER key every magenta-ish pixel: purple art inside the outline gets eaten (the purple gift box bug).
- **BLACK (VFX):** two files per piece:
  - `_add` (black kept; Roblox only with LightEmission = 1);
  - `_alpha` with a noise floor: alpha = clip((lum-16)/219)^0.85, colour un-premultiplied.
  - Icons: alpha from a black-border flood fill + fill small holes.
- **Cutting:** label components (size > ~400 px); if pieces touch, split at the minimum-coverage column/row. Trim to the bbox + 4 px.
- **Seamless textures:** ChatGPT never tiles. Fix with min-cut quilting or an offset + cross-fade + period crop, then CHECK a 2x2 tile at full size for seams. Derive normal (gradient), roughness and metalness maps. 1024².
- **Flipbooks:** cut on the empty gaps (not a blind grid), re-centre, keep equal frame sizes, rebuild an exact grid, and note rows x cols.
- **UI 9-slice:** write the SliceCenter Rect for stretchable pieces. Roblox stores images at most 1024 px wide, so give the SliceCenter in the stored size. Chips with an icon baked in → fixed aspect + a text area (fractions).
- **Defringe:** about 1% of edge pixels can still carry the key colour. Check on a DARK background; if a rim remains, erode the alpha by 1 px or re-run the un-mix with a wider band.
- **Busy or gradient backgrounds** (keying fails): use rembg with the Apache-licensed `isnet-general-use` model (`pip install "rembg[cpu]"`; its model downloads from GitHub). Do NOT use briaai/RMBG-1.4/2.0: non-commercial licence.
- **Upscale/sharpen art** before upload when a piece is small or soft: Real-ESRGAN x4 via `spandrel` (weights `ai-forever/Real-ESRGAN` RealESRGAN_x4.pth from Hugging Face; about 15 s per 300 px tile on CPU), then downscale to the target size. Good for UI and icons; NOT for space/star footage (it deletes faint stars as noise).
- **QA:** preview every piece on DARK and LIGHT backgrounds; look for black boxes or fringes. Show the owner a preview sheet.

## 5. Upload (Creator Hub in Chrome)
- Check the creator/group switcher BEFORE uploading (once a decal went to the wrong group). Assets belong to the game's owner group.
- Bulk: on create.roblox.com, put the files into a page `<input type=file multiple>` with the file_upload tool, then POST each to `https://apis.roblox.com/assets/user-auth/v1/assets` (multipart: `request` = {assetType:"Image", displayName, description, creationContext:{creator:{groupId}}}, `fileContent`). Get the x-csrf-token from the 403 response header and retry. Poll `/assets/user-auth/v1/operations/<id>` for the assetId + moderation.
- File inputs only accept session-readable paths (the uploads folder), not the outputs folder.
- Write an ASSET TABLE (piece | id | size | SliceCenter | use) into the game's vault note, and copy the PNGs to `<Game>\Assets\...`.

## 6. Wire in
Give the coding Claude: ImageLabel ScaleType Slice + SliceCenter; particles use `_alpha` (or `_add` only at LightEmission 1); FlipbookLayout grid; SurfaceAppearance/MaterialVariant maps; phone rules (no overlaps, text ≥14 px).

## 4b. In-browser processing (when the art never reaches the workspace)
- `MBkey(blob)`: magenta distance per pixel → border flood fill (d < 90) = background → a 2 px soft edge with alpha = clamp((d-45)/110) and the un-mix. Returns a canvas.
- **Then a soft GLOBAL magenta pass** for art with rings, swirls or gaps: enclosed magenta pockets (inside a star's swirl, a crown's ring) never touch the border, so the flood leaves them. alpha = min(alpha, clamp((d-40)/110)) for every pixel with d < 150, with the same un-mix.
- `MBruns(canvas, 'x'|'y', from, to)`: coverage runs to find the pieces (rows first, then columns per row); when pieces touch, split the widest run at its lowest-coverage column.
- `MBcut`: crop each box, trim to the alpha bbox, scale to ≤ 1024 px (Roblox stores max 1024 wide), and draw a preview strip on a dark navy background to check every piece for fringes before uploading.

## Lessons (11 Nov, MEGA BITE UI v5: owner "stone-age ui" → "modern, INSANE")
- **Objects that should break out of a frame: ask for the OBJECTS and the BACKGROUNDS as separate sheets.** One sheet of banners with the objects bursting out = the objects overlap the next banner and can't be cut. Separate = clean cuts AND the object can float, bob and tilt over its banner in-game (more alive).
- **Shop items are illustrated images, never a 3D ViewportFrame preview** (owner: "viewport frame is bad, use image instead with chatgpt"). For skins, render the real in-game model in each skin first (Studio lineup, fog/atmosphere off, side view), crop it into a labelled reference, attach it, and say "colours EXACTLY like the attached reference, in this order".
- Key reference for modern shop UI: the @.6ix13 "completely made by AI" Roblox shop TikTok (vault: `Research - Modern UI direction`): every product an illustrated card / banner with a saturated themed background, the product huge and breaking the frame, a patterned header band, themed corner ornaments, heavy cartoon titles (LuckiestGuy), lime price buttons, a swoosh on tab switch. Do NOT copy its fake struck-out prices.
- Window chrome sheet that works: one wide header band (rounded top, flat bottom, a faint themed pattern; 9-slice it with SliceCenter ~ (220,40,804,152) at 1024x192) + 4 different corner ornaments that match the game's world.
- In Roblox: preload every UI image at startup (a first-opened window showed blank pills), and give icons a self-heal retry: an image whose first fetch fails stays blank forever; re-request it once with a cache-busting suffix (`rbxassetid://ID&r=1`).
- After upload, check `moderationResult` with the assets API: thumbnails can say "Pending" for a while even when the asset is Approved and works in game.

## Tool setup notes (the workspace is temporary)
- The tools live in a Python venv (numpy, scipy, Pillow; optional torch + spandrel, rembg). Hugging Face needs huggingface.co + *.hf.co allowed; GitHub release downloads need github.com.
- Check every model's LICENCE before use (commercial game). Prefer MIT/Apache/CC0/CC-BY.

## Rules
No brands, logos, copyrighted characters or baked text. Never buy, type passwords, spend Robux or handle keys without an explicit OK. Save every prompt, the style block, the cut files and the asset table in the vault.