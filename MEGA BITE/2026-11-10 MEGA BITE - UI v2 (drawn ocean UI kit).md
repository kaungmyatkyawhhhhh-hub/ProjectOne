---
date: 2026-11-10
tags: [megabite, ui, ui-kit, chatgpt, build]
status: in the place (Studio); owner to look
---
# MEGA BITE: UI v2 (drawn ocean UI kit, 10 Nov)

Owner (18:14): "make a UI skill, search top 50 UIs, use the ChatGPT method, make the BEST UI ever" + (18:33) "if something fails, loop again and fix until it's great".
Research: [[2026-11-10 Research - Top 50 Roblox UIs]] → decision: bright kid-sim camp + an OCEAN THEMED frame (like Throw Food For Animals' themed frame), icon-first round buttons, ribbon titles, red round X, chunky pills, rarity cards.

## Art (ChatGPT, one-try sheets, all 4 worked first time; prompts in `UI/v2/ui_prompts.json` + the ribbons prompt below)
- Sheets in `UI/v2/MB_UI_<Frames|Buttons|Cards|Ribbons>_sheet.png`; processed PNGs + `final/manifest.json` (slices) + `final/asset_ids.json`.
- Pipeline scripts: `UI/v2/process_sheet.py` (border-flood magenta key, cut, previews) and `ui_finish.py` (defringe: partly transparent pixels → outline navy; erase edge studs so 9-slices don't stretch them; ribbon/coral lifted off the window; slice rects).
- 32 images uploaded to group 33151111 (all Approved): pills x6, round bases x4, close X, plus, capsule, panel, trough, arched ribbon (not used), coral ornament, rarity cards x8, straight banners x4, sunburst, badge, pearl.

## Kit (ReplicatedStorage.MegaBite.UIKit; v1 backed up in ServerStorage.UIKit_v1_backup)
- Same API, new look: `K.Plate` = capsule (short+wide) or sea-glass panel (9-slice); `K.Button` = icon-first sea bubble (square-ish) or chunky pill (wide), press bounce, SetColor swaps art by meaning; `K.Counter` capsule + icon breakout; `K.Tile` panel; NEW `K.Window` (panel + banner title + coral + red X), `K.Banner`, `K.Card` (rarity), `K.CloseButton`, `K.Art` table.
- HUD: NEXT bar re-laid inside the capsule; INDEX got a red count badge (new fish since last open); ESCAPED/DODGED/SO CLOSE pops get a turning sunburst.
- Fish Index = a Window with the green banner, rarity cards (Common sardine/damsel/shrimp, Uncommon puffer/mackerel, Rare squid, Epic tuna, Legendary golden), unknown = locked card + silhouette.

## Loop log (what failed → fix)
1. Duplicate prompt glued in ChatGPT (old draft) → clear the composer before inserting; verify typed length.
2. Pill/capsule END studs erased → notches → keep end studs (caps are fixed).
3. Purple halo → defringe to the outline colour.
4. Arched ribbon can't 9-slice (dome blob) → new straight-banner sheet.
5. Sliced banner squashed/clipped under UIScale → banners drawn at their own aspect (Fit).
6. HUD error `face.UIStroke` (v1 kit had a stroke) → removed.
7. New images "Reviewing" for ~1 min → invisible until approved; re-checked.
Checked: HUD + Index screenshots, overlap audit at 976x584 (none), console clean.
