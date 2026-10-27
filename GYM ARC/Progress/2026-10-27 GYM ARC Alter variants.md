---
date: 2026-10-27
tags: [gymarc, progress]
status: waiting on owner
---
# Alter variants (prompt 76)

Back to [[00 GYM ARC Home|GYM ARC Home]]. Prompt: [[2026-10-27 GYM ARC Prompt - 76 Alter variants]]. Feature: [[GYM ARC - Body Alters]] (Alter variants). Products: [[GYM ARC - Monetization]].

- Built the whole system (config, save data, Robux purchase, wear / take off, the Inventory swatch row, preview, the skin builder) and 6 variant colour maps (Halloween: Zombie on Vascular).
- Tested on LuigiRED with a temporary Inferno (Pumped's own map) and a fake product id: the swatch row and preview, SOON with no id, a test receipt granted it once (the same purchase id again: not granted), saved, worn over Granite and shown on the body meshes; take off / wear again; an unowned one refused; wearing another alter took it off. Then revoked (TestRevokeVariant) and all test values removed; the save loads with Granite and no variant.
- Fixed on the way: a preview always returns to what the save says you wear (a buy / wear during the 6 s preview is never undone on screen); the short Looks detail fits the extra row (smaller icon; the gains pill steps out when the STYLE row shows too).
- Waiting on the owner: the 6 colour maps imported to the group + 6 developer product ids.
- Sold in three places (owner chose all 3): a new Store SKINS tab (TRY ON + Robux), Inventory > Alters, Coach Dex > ALTERS. Tested with a temporary Inferno; test values removed.
- The owner imported the 6 colour maps; their ids are needed (Asset Manager > Copy Asset ID) - images imported that way leave nothing in the place to read.
