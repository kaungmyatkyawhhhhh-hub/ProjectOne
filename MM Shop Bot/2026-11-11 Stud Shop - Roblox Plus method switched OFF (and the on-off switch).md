---
tags: [stud-shop, robux, roblox-plus]
created: 2026-11-11
---
# Stud Shop - Roblox Plus method switched OFF (11 Nov 2026)

Owner (11 Nov, 17:42): "turn off the roblox plus method now, i ran out of roblox plus limit".

## What changed (repo `flashtopup`, commit a91b55a, live on studmm.shop)
- **Website:** the "⚡ Roblox Plus" method is hidden; in its place a greyed-out button says "Paused for now" / "ယာယီ ပိတ်ထားပါတယ်". The Group method (33 Ks) is unchanged and is selected automatically.
- **Server:** a Plus order is refused while the switch is off (`PLUS_OFF`), so an old open page can't still order it.
- **Telegram (admin):** `/plus` shows the state with one button; `/plus on` and `/plus off` change it. The website follows within about a minute.
- Setting: `plus_on` ("1"/"0"). It was set to "0" once by the code (`plus_off_set_2026_11_11`); after that only `/plus` changes it.

## To open it again
Send `/plus on` to the shop bot when the Roblox Plus send limit is back. Rate (`/plusrate`, 43 Ks) and the per-order cap (`/plusmax`) are kept.

## Checked
- `studmm.shop/api/config` -> `rbx_plus_on: false`.
- `studmm.shop/api/products` -> only the Group Robux product is listed.
- Orders already placed with Roblox Plus are not touched.
