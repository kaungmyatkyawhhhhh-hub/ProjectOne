---
name: roblox-best-ui
description: Use when making or redoing a Roblox game's UI (HUD, buttons, windows, shop, collection book): study the top 50 games' UIs, pick a style, make the art with one-try ChatGPT sheets, cut + 9-slice it, wire one UI kit, test on phones and loop until great.
---

# Roblox best-UI method (research → ChatGPT art → one UI kit → phone QA → loop)

Owner rules: Claude is the artist (ChatGPT draws 2D, never AI model generators); Quality > Quantity; if something fails, loop and fix until it is great; never publish/spend; store everything in the vault (`<Game>\UI\vN\`, research in `Roblox Playbook\Research notes`). Read first: vault `Brain\Knowledge\K06 Art, UI, VFX, sound and lighting.md`, the game's art style guide, and the newest UI research note (MEGA BITE: `2026-11-10 Research - Top 50 Roblox UIs`).

## 1. Research the top 50 (30 min, every new game or once a quarter)
- Live list: `https://endgametools.com/en/roblox/charts` (top 50 by players, WebFetch it).
- Screenshots in Claude in Chrome without clicking 50 times: on bing.com run a JS loop that `fetch('/images/search?q=<game> gameplay UI screenshot')`, parses `a.iusc[m]` JSON (`murl`), stores them in `window.R`, then renders a 4-column grid of `<img referrerPolicy=no-referrer>` with an onerror fallback to the next URL; screenshot the page in 5 scrolls (12 games per screen). Returning URLs from JS gets blocked ("cookie/query string data"); render them instead. Re-render the most relevant 6-8 at 756 px wide to read details.
- Write the table: rank, game, UI family, what the HUD/windows/buttons do. Then the PATTERNS and a one-paragraph DECISION (which camp, which theme).
- Known patterns (Nov 2026): kid hits = icon-first side buttons (big glossy icon, short label under), themed frames that match the world (Throw Food's cookie frame), ribbon titles on the top edge, red round X overhanging the top-right corner, chunky pill buttons with a shine and colour = meaning, rarity-coloured cards, a big centre pop for big moments, currency pill with "+", round action buttons bottom-right on mobile. Dark sleek glass is the PvP/horror/anime camp.

## 2. Style block + one-try sheets (ChatGPT in the owner's Chrome)
- One STYLE paragraph pasted unchanged into every sheet: outline colour, rim material + colours, highlight, studs/details, lip, "smooth clean gradients, simple vector-like shapes, no noise/grain/realism, NOT a photo".
- Sheets (1536x1024, magenta #FF00FF, "NO text/letters/numbers/icons", every piece apart and off the edges):
  1. FRAMES: big window (with title ribbon + corner ornament), red round X, green round +, wide capsule (counters/toasts), square panel, progress trough.
  2. BUTTONS: 6 pills (green, gold, red, blue, purple, grey) + 4 round icon-button bases.
  3. CARDS: 8 rarity cards in a 4x2 grid (common, uncommon, rare, epic, legendary, mythic, secret, locked) with an empty name strip.
  4. RIBBONS: straight level banners ("PERFECTLY STRAIGHT, NOT arched": an arched ribbon can't be 9-sliced), a reward sunburst, a notification badge.
- ChatGPT composer (Nov 2026): `div[contenteditable=true]` + `button[aria-label=Send]`. ALWAYS `execCommand('selectAll')` + `delete` before `insertText` (an old draft got glued in front of the prompt) and check `typed N of N` before clicking Send. Several sheets in parallel tabs are fine.
- Download: fetch the `main img` src blob → `<a download>` → Downloads; copy into the vault with the Blender MCP python (Downloads isn't connected), then stage.

## 3. Process (Python: numpy/scipy/PIL) — scripts in the vault `<Game>\UI\vN\` (process_sheet.py, ui_finish.py)
- Key: magenta distance < 70 connected to the BORDER only; 3 px soft band, un-mix; then **defringe: every partly transparent pixel takes the outline colour** (no purple halo).
- Cut components ≥ 600 px, trim + 4 px pad, sort by row then x.
- **Studs/decorations on straight edges must be erased before 9-slicing** (they would stretch): copy the rim profile from beside the stud (top/bottom edges: from the left; side edges: from above). Keep corner studs. Don't erase pill/capsule END studs (caps are fixed; erasing leaves notches).
- Slice rects by hand per piece type (record in manifest.json): pill = fixed 150 px caps; capsule = fixed 120 px ends; panel = 86 px corners; cards = 80 px corners and a fixed bottom (name strip); rounds/X/+ fixed.
- Ornaments (ribbon, coral) are lifted off as their own images by colour masks, then rebuilt from per-column top/bottom (median filter) with a fresh outline. If it still looks jagged → generate a dedicated sheet (that's what the RIBBONS sheet is for).
- Preview every piece on dark AND light before upload.

## 4. Upload (Creator Dashboard tab, Claude in Chrome)
- Inject `<input type=file multiple>`, `find` its ref, `file_upload` from a session-readable path (stage from the vault into /mnt/user-data/uploads; outputs/ is refused).
- POST `https://apis.roblox.com/assets/user-auth/v1/assets` (multipart `request` = {assetType:"Image", displayName, description, creationContext:{creator:{groupId}}}, `fileContent`), retry with the 403's x-csrf-token. Run async loops that store results in `window.*`, then poll (long awaits time out the tool). Poll `/operations/<id>` for assetId + moderation. Write the id table into the manifest + the vault.

## 5. Wire ONE UI kit (keep the old API so the whole game switches at once)
- `K.Art = {name = {id, w, h, slice}}`, `K.Slice(parent, art, props, cornerPx)` (ScaleType Slice, SliceCenter, SliceScale = cornerPx / sliceX0; pills/capsules: SliceScale = height / image height so the round ends fill the height).
- Plate → capsule if short + wide (h ≤ 64, w ≥ 2.2h) else panel; a transparent Face inset for children. Keep a legacy path for callers that pass an explicit fill colour.
- Button → square-ish = icon-first round base (icon ~0.86 of the bubble, label under it overlapping the bottom, CanvasGroup face for a round cooldown veil); wide = pill with icon left + label. SetColor swaps the art by colour meaning. Press = UIScale 0.9 then Back-ease to 1.
- Window → big panel + ribbon title + corner ornament + red X overhanging the top-right.
- Cards → rarity art; locked/unknown = the locked card + a dark silhouette.
- Text stays code: one font (FredokaOne) with a thick ink stroke; ≥ 14 px at the smallest phone.
- Back up the old kit (ServerStorage `UIKit_v1_backup`) before swapping. Search all scripts for things the old kit had (e.g. `face.UIStroke`) and fix them.

## 6. QA loop (until it's great)
- Play in Studio: console must be clean; screenshot the HUD + every window; zoom the screenshot on details (ribbon edges, button labels, clipping).
- Phone sizes: UIAudit at 844x390, 640x360, 1024x768 (no overlaps, nothing off-screen, text ≥ 14 px) + the device emulator via computer use.
- Quality-nerd kid sim on the screenshots (cheap tells: stretched studs, halos, jagged ornaments, mismatched styles, default fonts).
- Anything failing → fix the asset or the kit and go again. Then show the owner before/after screenshots.

## 7. Save
Vault: research note, prompts note, sheets, processed PNGs + manifest (ids, slices), scripts, the kit diff, before/after screenshots, a line in the game's home note.
